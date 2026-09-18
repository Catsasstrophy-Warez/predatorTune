import SwiftUI
import Charts

private struct ValidationOverlayPoint: Identifiable {
    let id = UUID()
    let time: TimeInterval
    let value: Double
    let series: String
}

private struct ValidationDistributionPoint: Identifiable {
    let id = UUID()
    let cohort: String
    let value: Double
}

struct ValidationLaboratoryView: View {
    let baselineDataset: ParsedLogData
    let baselineEvidence: DiagnosticEvidencePackage
    let validationDataset: ParsedLogData
    let validationEvidence: DiagnosticEvidencePackage
    let cohortReport: CohortValidationReport?

    private let channels: [(CanonicalChannel, String, String)] = [
        (.engineRPM, "Engine RPM", "rpm"),
        (.fuelPressureActual, "Fuel Pressure", "psi"),
        (.lambdaMeasured, "Measured Lambda", "λ"),
        (.throttleActual, "Throttle", "deg")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Validation Laboratory").font(.headline).accessibilityIdentifier("validation.laboratory")
                Text("Both traces are normalized to event onset (T = 0). Original samples are preserved; no interpolation is introduced.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            ForEach(channels, id: \.0.rawValue) { channel, title, unit in
                overlayChart(channel: channel, title: title, unit: unit)
                deltaChart(channel: channel, title: title, unit: unit)
            }

            if let cohortReport {
                Divider()
                Text("Cohort Distributions").font(.headline)
                Text("Distribution views use only events admitted by the comparability gate.")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(cohortReport.metrics) { metric in distributionCard(metric: metric, report: cohortReport) }
            }
        }
    }

    @ViewBuilder private func overlayChart(channel: CanonicalChannel, title: String, unit: String) -> some View {
        let baseline = NormalizedTraceEngine.make(log: baselineDataset, event: baselineEvidence.episode, buildStateID: baselineEvidence.buildStateID, channels: [channel])
        let validation = NormalizedTraceEngine.make(log: validationDataset, event: validationEvidence.episode, buildStateID: validationEvidence.buildStateID, channels: [channel])
        let points = baseline.points.map { ValidationOverlayPoint(time: $0.relativeTime, value: $0.value, series: "Baseline") }
            + validation.points.map { ValidationOverlayPoint(time: $0.relativeTime, value: $0.value, series: "Validation") }
        if !points.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack { Text(title).font(.subheadline.bold()); Spacer(); Text(unit).font(.caption).foregroundStyle(.secondary) }
                Chart(points) { point in
                    LineMark(x: .value("Relative Time", point.time), y: .value(title, point.value))
                        .foregroundStyle(by: .value("Cohort", point.series))
                        .interpolationMethod(.linear)
                    RuleMark(x: .value("Event", 0.0)).lineStyle(.init(lineWidth: 1, dash: [4,4]))
                }
                .chartXScale(domain: -2...2)
                .frame(height: 145)
                .accessibilityLabel("\(title) baseline and validation overlay centered on event onset")
            }
        }
    }

    @ViewBuilder private func deltaChart(channel: CanonicalChannel, title: String, unit: String) -> some View {
        let baseline = NormalizedTraceEngine.make(log: baselineDataset, event: baselineEvidence.episode, buildStateID: baselineEvidence.buildStateID, channels: [channel])
        let validation = NormalizedTraceEngine.make(log: validationDataset, event: validationEvidence.episode, buildStateID: validationEvidence.buildStateID, channels: [channel])
        let b = Dictionary(uniqueKeysWithValues: baseline.points.map { (Int(($0.relativeTime * 1000).rounded()), $0.value) })
        let v = Dictionary(uniqueKeysWithValues: validation.points.map { (Int(($0.relativeTime * 1000).rounded()), $0.value) })
        let keys = Set(b.keys).intersection(v.keys).sorted()
        let deltas = keys.compactMap { key -> NormalizedDeltaPoint? in
            guard let bv = b[key], let vv = v[key] else { return nil }
            return NormalizedDeltaEngine.compare(times: [Double(key) / 1000.0], baseline: [bv], validation: [vv]).first
        }
        if !deltas.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack { Text("Δ \(title)").font(.caption.bold()); Spacer(); Text("Validation − Baseline · \(unit)").font(.caption2).foregroundStyle(.secondary) }
                Chart(deltas) { point in
                    LineMark(x: .value("Relative Time", point.time), y: .value("Delta", point.delta))
                        .interpolationMethod(.linear)
                    RuleMark(y: .value("No change", 0.0)).lineStyle(.init(lineWidth: 1, dash: [3,3]))
                    RuleMark(x: .value("Event", 0.0)).lineStyle(.init(lineWidth: 1, dash: [4,4]))
                }
                .chartXScale(domain: -2...2)
                .frame(height: 95)
                .accessibilityLabel("\(title) validation minus baseline delta, using only matched recorded sample times")
                Text("Delta uses matched recorded timestamps only. Missing samples are omitted; PredatorLab does not interpolate forensic evidence here.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private func distributionCard(metric: CohortMetric, report: CohortValidationReport) -> some View {
        let baseline = values(metric.id, report.baselineEvents.map(\.evidence))
        let validation = values(metric.id, report.validationEvents.map(\.evidence))
        let b = DistributionAnalysisEngine.summarize(baseline)
        let v = DistributionAnalysisEngine.summarize(validation)
        if !baseline.isEmpty || !validation.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(metric.label).font(.subheadline.bold())
                Chart(baseline.map { ValidationDistributionPoint(cohort: "Baseline", value: $0) } + validation.map { ValidationDistributionPoint(cohort: "Validation", value: $0) }) { point in
                    PointMark(x: .value("Cohort", point.cohort), y: .value(metric.label, point.value))
                        .foregroundStyle(by: .value("Cohort", point.cohort))
                }.frame(height: 120)
                HStack {
                    distributionSummary("Baseline", b, unit: metric.unit)
                    Spacer()
                    distributionSummary("Validation", v, unit: metric.unit)
                }
            }
        }
    }

    private func distributionSummary(_ label: String, _ summary: DistributionSummary, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption.bold())
            Text("n=\(summary.count) • median \(fmt(summary.median)) \(unit)").font(.caption.monospaced())
            Text("Q1–Q3 \(fmt(summary.q1))–\(fmt(summary.q3))").font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func values(_ key: String, _ packages: [DiagnosticEvidencePackage]) -> [Double] {
        packages.compactMap { package in package.observations.first { $0.key == key }?.value }
    }
    private func fmt(_ value: Double?) -> String { value.map { String(format: "%.3f", $0) } ?? "—" }
}

import Foundation

struct CohortEvent: Identifiable {
    let id = UUID()
    let log: ImportedLog
    let evidence: DiagnosticEvidencePackage
    let comparability: ComparabilityReport
}

struct CohortMetric: Identifiable, Equatable {
    let id: String
    let label: String
    let unit: String
    let baselineMedian: Double?
    let validationMedian: Double?
    let favorableDirection: FavorableDirection
    var delta: Double? { guard let baselineMedian, let validationMedian else { return nil }; return validationMedian - baselineMedian }
    enum FavorableDirection { case higher, lower }
    var improved: Bool? {
        guard let delta else { return nil }
        switch favorableDirection { case .higher: return delta > 0; case .lower: return delta < 0 }
    }
}

struct CohortValidationReport {
    let baselineBuildStateID: UUID?
    let validationBuildStateID: UUID?
    let baselineEvents: [CohortEvent]
    let validationEvents: [CohortEvent]
    let rejectedEvents: Int
    let metrics: [CohortMetric]
    let outcome: ValidationOutcome
    let confidenceLabel: String
    let explanation: [String]

    var baselineCount: Int { baselineEvents.count }
    var validationCount: Int { validationEvents.count }
}

enum CohortValidationEngine {
    /// Builds cohorts around a reference event. Every admitted event must pass the same
    /// comparability gate used by pairwise validation. This prevents a large cohort from
    /// laundering poor operating-condition matches into a persuasive average.
    static func evaluate(reference: DiagnosticEvidencePackage, candidates: [(ImportedLog, DiagnosticEvidencePackage)], minimumPerCohort: Int = 2) -> CohortValidationReport {
        let baselineBuild = reference.buildStateID
        let otherBuilds = Dictionary(grouping: candidates.filter { $0.1.buildStateID != baselineBuild }, by: { $0.1.buildStateID })
        let validationBuild = otherBuilds.max { $0.value.count < $1.value.count }?.key ?? nil

        var baseline: [CohortEvent] = []
        var validation: [CohortEvent] = []
        var rejected = 0

        // The reference is always the anchor of the baseline cohort.
        let selfReport = ComparabilityEngine.compare(reference, reference)
        baseline.append(CohortEvent(log: syntheticLog(for: reference), evidence: reference, comparability: selfReport))

        for (log, evidence) in candidates {
            guard evidence.episode.eventType == reference.episode.eventType else { rejected += 1; continue }
            let report = ComparabilityEngine.compare(reference, evidence)
            guard report.isSuitableForValidation else { rejected += 1; continue }
            if evidence.buildStateID == baselineBuild { baseline.append(.init(log: log, evidence: evidence, comparability: report)) }
            else if evidence.buildStateID == validationBuild { validation.append(.init(log: log, evidence: evidence, comparability: report)) }
        }

        let metrics = makeMetrics(baseline: baseline.map(\.evidence), validation: validation.map(\.evidence))
        let usable = metrics.compactMap(\.improved)
        let improved = usable.filter { $0 }.count
        let regressed = usable.count - improved
        let enough = baseline.count >= minimumPerCohort && validation.count >= minimumPerCohort

        let outcome: ValidationOutcome
        if validationBuild == nil { outcome = .notTested }
        else if !enough { outcome = .insufficientEvidence }
        else if usable.isEmpty { outcome = .insufficientEvidence }
        else if improved >= 3 && regressed == 0 && baseline.count >= 3 && validation.count >= 3 { outcome = .stronglyImproved }
        else if improved > regressed { outcome = .improved }
        else if regressed > improved { outcome = .regression }
        else { outcome = .mixed }

        let confidence: String
        let smallest = min(baseline.count, validation.count)
        if !enough { confidence = "Insufficient" }
        else if smallest >= 8 { confidence = "High" }
        else if smallest >= 4 { confidence = "Moderate" }
        else { confidence = "Preliminary" }

        var explanation = ["\(baseline.count) baseline and \(validation.count) validation events passed the comparability gate."]
        if rejected > 0 { explanation.append("\(rejected) candidate events were excluded because they were not sufficiently comparable or were the wrong event type.") }
        if !enough { explanation.append("At least \(minimumPerCohort) comparable events per cohort are required before a cohort-level directional conclusion is issued.") }
        explanation.append("Cohort statistics are PredatorLab-derived evidence summaries. Association with a build change does not establish which individual change caused the result.")
        return .init(baselineBuildStateID: baselineBuild, validationBuildStateID: validationBuild, baselineEvents: baseline, validationEvents: validation, rejectedEvents: rejected, metrics: metrics, outcome: outcome, confidenceLabel: confidence, explanation: explanation)
    }

    private static func makeMetrics(baseline: [DiagnosticEvidencePackage], validation: [DiagnosticEvidencePackage]) -> [CohortMetric] {
        func values(_ key: String, _ packages: [DiagnosticEvidencePackage]) -> [Double] { packages.compactMap { p in p.observations.first { $0.key == key }?.value } }
        func metric(_ id: String, _ label: String, _ unit: String, _ direction: CohortMetric.FavorableDirection) -> CohortMetric {
            .init(id: id, label: label, unit: unit, baselineMedian: median(values(id, baseline)), validationMedian: median(values(id, validation)), favorableDirection: direction)
        }
        return [
            metric("pw_margin_min", "Minimum PW margin", "ms", .higher),
            metric("pressure_error_peak", "Peak pressure error", "psi", .lower),
            metric("lambda_error_peak", "Peak lambda error", "λ", .lower),
            metric("throttle_error_peak", "Peak throttle error", "deg", .lower),
            metric("episode_duration", "Event duration", "s", .lower)
        ]
    }

    private static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let s = values.sorted(); let m = s.count / 2
        return s.count.isMultiple(of: 2) ? (s[m-1] + s[m]) / 2 : s[m]
    }

    private static func syntheticLog(for evidence: DiagnosticEvidencePackage) -> ImportedLog {
        ImportedLog(filename: "Reference event", vehicleID: UUID(), buildStateID: evidence.buildStateID)
    }
}

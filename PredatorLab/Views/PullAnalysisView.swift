import SwiftUI
import Charts

/// Pull-by-pull analysis of one log, compared against the baseline log for the same build.
struct PullAnalysisView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var dataRepository: DataRepository
    let log: ImportedLog

    @State private var reports: [PullReport] = []
    @State private var selectedPullID: Double?
    @State private var baselineReport: PullReport?
    @State private var baselineLogName: String?
    @State private var baselineLogID: UUID?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var dataset: ParsedLogData?
    @State private var baselineDyno: DynoResult?

    private let store = PullBaselineStore()
    private var selected: PullReport? { reports.first { $0.id == selectedPullID } ?? PullAnalyzer.representativePull(in: reports) }
    private var isBaseline: Bool { baselineLogID == log.id }
    private let tileColumns = [GridItem(.adaptive(minimum: 104), spacing: 10)]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PLTrackHeader(eyebrow: "Pull Analysis", title: "WHAT THE ENGINE DID", subtitle: log.filename, icon: "speedometer", accent: .plIgnition)
                content
            }
            .padding(16)
        }
        .plHardBottomEdge()
        .plScreenBackground()
        .navigationTitle("Pull Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            PLLoadingCard(title: "Finding pulls", message: "Looking for runs above \(Int(PullAnalyzer.demandThreshold))% pedal")
        } else if let loadError {
            PLLoadErrorCard(title: "Couldn't analyze this log", message: loadError) { Task { await load() } }
        } else if reports.isEmpty {
            PLEmptyState(icon: "gauge.with.dots.needle.0percent", title: "No pulls in this log",
                         message: "A pull is at least \(String(format: "%.1f", PullAnalyzer.minimumDuration)) s above \(Int(PullAnalyzer.demandThreshold))% pedal. Log a full-throttle run to analyze it here.")
        } else if let pull = selected {
            pullPicker
            summary(pull)
            knockCard(pull)
            dynoCard(pull)
            lambdaCard(pull)
            if !pull.fuelTrims.isEmpty || !pull.controllerLimits.isEmpty { detailsCard(pull) }
            baselineCard(pull)
        }
    }

    // MARK: Pull picker

    private var pullPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(reports.enumerated()), id: \.element.id) { index, pull in
                    let isSelected = pull.id == selected?.id
                    Button { selectedPullID = pull.id } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pull \(index + 1)").font(.plHeadline)
                            Text("\(rpm(pull.rpmStart))→\(rpm(pull.rpmEnd)) rpm").font(.plCaption).foregroundStyle(.plTextSecondary)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(isSelected ? Color.plIgnition.opacity(0.18) : Color.plSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(isSelected ? Color.plIgnition : Color.plStroke))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    // MARK: Summary

    private func summary(_ pull: PullReport) -> some View {
        PLCard(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                PLSectionHeader(title: String(format: "%.1f–%.1f s", pull.start, pull.end), systemImage: "stopwatch", accent: .plIgnition)
                LazyVGrid(columns: tileColumns, alignment: .leading, spacing: 14) {
                    PLStatTile(label: "Peak RPM", value: rpm(pull.rpmEnd), accent: .plIgnition)
                    PLStatTile(label: "Peak boost", value: number(pull.peakBoost, "%.1f"), unit: pull.pressureUnit, accent: .plBoost)
                    PLStatTile(label: "IAT2 rise", value: number(pull.iat2Rise, "%+.1f"), unit: pull.temperatureUnit, accent: .plWarning)
                    PLStatTile(label: "Max knock", value: String(format: "%.2f", pull.maxKnockRetard), unit: "°", accent: pull.maxKnockRetard >= 1 ? .plCritical : .plSuccess)
                    PLStatTile(label: "Max λ error", value: number(pull.maxLambdaError, "%.3f"), accent: (pull.maxLambdaError ?? 0) > 0.05 ? .plWarning : .plSuccess)
                    PLStatTile(label: "Torque shortfall", value: number(pull.maxTorqueShortfall, "%.0f"), unit: pull.torqueUnit, accent: .plCritical)
                    PLStatTile(label: "Misfires", value: "\(pull.misfires)", accent: pull.misfires > 0 ? .plCritical : .plSuccess)
                    PLStatTile(label: "Bank split", value: number(pull.meanBankSplit, "%.3f"), unit: "λ", accent: (pull.meanBankSplit ?? 0) > 0.05 ? .plWarning : .plSuccess)
                }
            }
        }
    }

    // MARK: Knock by cylinder

    @ViewBuilder
    private func knockCard(_ pull: PullReport) -> some View {
        if !pull.knockByCylinder.isEmpty {
            PLCard(padding: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    PLSectionHeader(title: "Knock retard by cylinder", systemImage: "bolt.trianglebadge.exclamationmark", accent: .plCritical)
                    Chart(pull.knockByCylinder.sorted { $0.key < $1.key }, id: \.key) { item in
                        BarMark(x: .value("Cylinder", "\(item.key)"), y: .value("Retard (°)", item.value))
                            .foregroundStyle(item.value >= 1 ? Color.plCritical : Color.plSuccess)
                    }
                    .chartYAxisLabel("° retard")
                    .frame(height: 150)
                    Text(knockSummary(pull)).font(.plCaption).foregroundStyle(.plTextSecondary)
                }
            }
        }
    }

    private func knockSummary(_ pull: PullReport) -> String {
        let hits = pull.knockByCylinder.filter { $0.value > 0 }.sorted { $0.key < $1.key }
        guard !hits.isEmpty else { return "No cylinder pulled timing during this run." }
        let list = hits.map { "cyl \($0.key) \(String(format: "%.2f", $0.value))°" }.joined(separator: ", ")
        return hits.count == 1 ? "Retard isolated to one cylinder (\(list)): check that cylinder's plug, injector and fuel before blaming fuel quality." : "Retard on \(list)."
    }

    // MARK: Road dyno

    private struct DynoSeriesPoint: Identifiable {
        let id = UUID(); let rpm: Int; let value: Double; let series: String
    }

    @ViewBuilder
    private func dynoCard(_ pull: PullReport) -> some View {
        if let dataset, let result = VirtualDyno.run(log: dataset, pull: pull, assumptions: dynoAssumptions) {
            let series = result.points.flatMap { point in
                [DynoSeriesPoint(rpm: point.rpm, value: point.wheelHorsepower, series: "Wheel hp"),
                 DynoSeriesPoint(rpm: point.rpm, value: point.wheelTorque, series: "Wheel lb·ft")]
            }
            PLCard(padding: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        PLSectionHeader(title: "Road dyno (estimate)", systemImage: "gauge.with.dots.needle.67percent", accent: .plIgnition)
                        Spacer()
                        PLBadge(text: "ESTIMATE", color: .plWarning, filled: false)
                    }
                    HStack(spacing: 14) {
                        PLStatTile(label: "Peak wheel hp", value: String(format: "%.0f", result.peakHorsepower), unit: "@ \(result.peakHorsepowerRPM)", accent: .plIgnition)
                        PLStatTile(label: "Peak wheel tq", value: String(format: "%.0f", result.peakTorque), unit: "lb·ft", accent: .plBoost)
                        if let baselineDyno, !isBaseline {
                            PLStatTile(label: "vs baseline", value: String(format: "%+.0f", result.peakHorsepower - baselineDyno.peakHorsepower), unit: "whp",
                                       accent: result.peakHorsepower >= baselineDyno.peakHorsepower ? .plSuccess : .plWarning)
                        }
                    }
                    Chart(series) { point in
                        LineMark(x: .value("RPM", point.rpm), y: .value("Value", point.value))
                            .foregroundStyle(by: .value("Series", point.series))
                        PointMark(x: .value("RPM", point.rpm), y: .value("Value", point.value))
                            .foregroundStyle(by: .value("Series", point.series))
                    }
                    .chartForegroundStyleScale(["Wheel hp": Color.plIgnition, "Wheel lb·ft": Color.plBoost])
                    .frame(height: 180)
                    Text(DynoResult.caveat).font(.plCaption).foregroundStyle(.plTextSecondary)
                    Text("Assumes \(Int((result.assumptions.massKg / 0.453_592).rounded())) lb, CdA \(String(format: "%.2f", result.assumptions.dragArea)) m², rolling \(String(format: "%.3f", result.assumptions.rollingResistance)). \(result.excludedSamples) samples skipped (shifts, torque cuts). Set your test weight in Garage ▸ Vehicle & Builds.")
                        .font(.plCaption).foregroundStyle(.plTextSecondary)
                }
            }
            .accessibilityIdentifier("pull.dyno")
        }
    }

    // MARK: Lambda by RPM

    private struct LambdaPoint: Identifiable {
        let id = UUID(); let rpm: Int; let value: Double; let series: String
    }

    @ViewBuilder
    private func lambdaCard(_ pull: PullReport) -> some View {
        let points = pull.bins.flatMap { bin -> [LambdaPoint] in
            [("Commanded", bin.lambdaCommanded), ("Bank 1", bin.lambdaBank1), ("Bank 2", bin.lambdaBank2)]
                .compactMap { series, value in value.map { LambdaPoint(rpm: bin.rpmFloor, value: $0, series: series) } }
        }
        if !points.isEmpty {
            PLCard(padding: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    PLSectionHeader(title: "Lambda by RPM", systemImage: "drop.fill", accent: .plBoost)
                    Chart(points) { point in
                        LineMark(x: .value("RPM", point.rpm), y: .value("λ", point.value))
                            .foregroundStyle(by: .value("Series", point.series))
                        PointMark(x: .value("RPM", point.rpm), y: .value("λ", point.value))
                            .foregroundStyle(by: .value("Series", point.series))
                    }
                    .chartForegroundStyleScale(["Commanded": Color.plTextSecondary, "Bank 1": Color.plBoost, "Bank 2": Color.plIgnition])
                    .chartYScale(domain: .automatic(includesZero: false))
                    .frame(height: 180)
                    Text("Averaged in \(PullAnalyzer.binWidth) rpm bins. Readings at or above 1.5 λ (fuel cut) are excluded.")
                        .font(.plCaption).foregroundStyle(.plTextSecondary)
                }
            }
        }
    }

    // MARK: Trims and limits

    private func detailsCard(_ pull: PullReport) -> some View {
        PLCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                if !pull.fuelTrims.isEmpty {
                    PLSectionHeader(title: "Fuel trims during pull", systemImage: "slider.horizontal.3", accent: .plSuccess)
                    ForEach(pull.fuelTrims.sorted { $0.key < $1.key }, id: \.key) { item in
                        HStack {
                            Text(item.key).font(.plBody).foregroundStyle(.plTextPrimary)
                            Spacer()
                            Text(String(format: "%+.1f%%", item.value)).font(.plMono(14)).foregroundStyle(abs(item.value) > 10 ? Color.plWarning : Color.plTextPrimary)
                        }
                    }
                }
                if !pull.controllerLimits.isEmpty {
                    PLSectionHeader(title: "Controller limits seen", systemImage: "hand.raised.fill", accent: .plWarning)
                        .padding(.top, pull.fuelTrims.isEmpty ? 0 : 6)
                    ForEach(pull.controllerLimits, id: \.self) { limit in
                        Label(limit, systemImage: "exclamationmark.triangle.fill").font(.plBody).foregroundStyle(.plWarning)
                    }
                }
            }
        }
    }

    // MARK: Baseline

    private func baselineCard(_ pull: PullReport) -> some View {
        PLCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                PLSectionHeader(title: "Baseline comparison", systemImage: "arrow.left.arrow.right", accent: .plBoost)
                if isBaseline {
                    Label("This log is the baseline for its build. New logs on the same build compare against it.", systemImage: "star.fill")
                        .font(.plCaption).foregroundStyle(.plSuccess)
                    Button("Clear baseline") { setBaseline(nil) }
                        .buttonStyle(PLPrimaryButtonStyle(accent: .plSurfaceRaised, minHeight: 44))
                } else {
                    if let baselineReport, let baselineLogName {
                        comparisonRows(PullComparison(current: pull, baseline: baselineReport), baselineName: baselineLogName)
                    } else {
                        Text("No baseline set for this build yet. Make a known-good log the baseline, then every later log shows what changed.")
                            .font(.plCaption).foregroundStyle(.plTextSecondary)
                    }
                    Button(baselineReport == nil ? "Use this log as baseline" : "Make this the new baseline") { setBaseline(log.id) }
                        .buttonStyle(PLPrimaryButtonStyle(accent: .plBoost, minHeight: 44))
                        .accessibilityIdentifier("pull.setBaseline")
                }
            }
        }
    }

    private func comparisonRows(_ comparison: PullComparison, baselineName: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("vs \(baselineName)").font(.plCaption).foregroundStyle(.plTextSecondary)
            deltaRow("Peak boost", comparison.peakBoostDelta, "%+.1f", unit: comparison.current.pressureUnit, higherIsBetter: true)
            deltaRow("Max knock retard", comparison.maxKnockDelta, "%+.2f", unit: "°", higherIsBetter: false)
            deltaRow("IAT2 rise", comparison.iat2RiseDelta, "%+.1f", unit: comparison.current.temperatureUnit, higherIsBetter: false)
            deltaRow("Max λ error", comparison.maxLambdaErrorDelta, "%+.3f", unit: nil, higherIsBetter: false)
            if comparison.bins.isEmpty {
                Text("The two pulls don't cover the same RPM range, so lambda and torque can't be compared bin by bin.")
                    .font(.plCaption).foregroundStyle(.plTextSecondary)
            } else {
                ForEach(comparison.bins) { bin in
                    HStack {
                        Text("\(bin.rpmFloor) rpm").font(.plMono(12)).foregroundStyle(.plTextSecondary)
                        Spacer()
                        Text("λ " + number(bin.lambdaBank1Delta, "%+.3f")).font(.plMono(12))
                        Text("tq " + number(bin.torqueDeliveredDelta, "%+.0f")).font(.plMono(12))
                    }
                    .foregroundStyle(.plTextPrimary)
                }
            }
        }
    }

    private func deltaRow(_ label: String, _ value: Double?, _ format: String, unit: String?, higherIsBetter: Bool) -> some View {
        let tint: Color = {
            guard let value, abs(value) > 0.0001 else { return .plTextSecondary }
            return (value > 0) == higherIsBetter ? .plSuccess : .plWarning
        }()
        return HStack {
            Text(label).font(.plBody).foregroundStyle(.plTextPrimary)
            Spacer()
            Text(number(value, format) + (unit.map { " \($0)" } ?? "")).font(.plMono(14)).foregroundStyle(tint)
        }
    }

    // MARK: Loading

    private func load() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            let dataset = try await dataRepository.loadDataset(for: log)
            self.dataset = dataset
            reports = await Task.detached(priority: .userInitiated) { PullAnalyzer.analyze(dataset) }.value
            selectedPullID = PullAnalyzer.representativePull(in: reports)?.id
            await loadBaseline()
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func loadBaseline() async {
        baselineLogID = store.baselineLogID(vehicleID: log.vehicleID, buildStateID: log.buildStateID)
        baselineReport = nil
        baselineLogName = nil
        baselineDyno = nil
        guard let id = baselineLogID, id != log.id, let baselineLog = appState.allLogs.first(where: { $0.id == id }) else { return }
        guard let dataset = try? await dataRepository.loadDataset(for: baselineLog) else { return }
        let pulls = await Task.detached(priority: .userInitiated) { PullAnalyzer.analyze(dataset) }.value
        baselineReport = PullAnalyzer.representativePull(in: pulls)
        baselineLogName = baselineLog.filename
        if let pull = baselineReport {
            let assumptions = dynoAssumptions
            baselineDyno = await Task.detached(priority: .utility) { VirtualDyno.run(log: dataset, pull: pull, assumptions: assumptions) }.value
        }
    }

    private var dynoAssumptions: DynoAssumptions {
        DynoAssumptions(testWeightLb: appState.allVehicles.first { $0.id == log.vehicleID }?.testWeightLb)
    }

    private func setBaseline(_ id: UUID?) {
        store.setBaseline(id, vehicleID: log.vehicleID, buildStateID: log.buildStateID)
        Task { await loadBaseline() }
    }

    // MARK: Formatting

    private func rpm(_ value: Double?) -> String { value.map { String(format: "%.0f", $0) } ?? "—" }
    private func number(_ value: Double?, _ format: String) -> String { value.map { String(format: format, $0) } ?? "—" }
}

/// Picks a log, then opens its pull analysis.
struct PullLogPickerView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PLTrackHeader(eyebrow: "Tuning Loop", title: "PULL COMPARISON", subtitle: "Analyze a log's pulls and compare them with the baseline for its build.", icon: "arrow.left.arrow.right", accent: .plIgnition)
                if appState.allLogs.isEmpty {
                    PLEmptyState(icon: "square.and.arrow.down.on.square", title: "No logs yet",
                                 message: "Import an HP Tuners log with a full-throttle run to analyze pulls.", actionTitle: "Import a log") {
                        appState.openAnalyze(.logs)
                    }
                } else {
                    PLHubSection(title: "Logs", icon: "doc.text.magnifyingglass", accent: .plIgnition) {
                        ForEach(appState.allLogs.sorted { $0.importDate > $1.importDate }) { log in
                            NavigationLink { PullAnalysisView(log: log) } label: {
                                PLHubRow(title: log.filename, subtitle: "\(log.events.count) events • \(String(format: "%.0f", log.duration)) s", icon: "speedometer", accent: .plIgnition)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
        .plHardBottomEdge()
        .plScreenBackground()
        .navigationTitle("Pull Comparison")
    }
}

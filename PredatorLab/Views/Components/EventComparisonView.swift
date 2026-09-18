import SwiftUI

struct EventComparisonView: View {
    let baselineLog: ImportedLog
    let baselineDataset: ParsedLogData
    let baselineEvidence: DiagnosticEvidencePackage
    @EnvironmentObject var dataRepository: DataRepository
    @EnvironmentObject var appState: AppState
    @State private var candidates: [ComparisonCandidate] = []
    @State private var selectedID: UUID?
    @State private var errorMessage: String?
    @State private var cohortReport: CohortValidationReport?
    @State private var sessions: [Session] = []
    @State private var baselineOpportunity: OpportunitySummary?
    @State private var validationOpportunity: OpportunitySummary?
    @State private var saveStatus: String?

    private var selected: ComparisonCandidate? { candidates.first { $0.id == selectedID } ?? candidates.first }
    private var result: EventComparisonResult? { selected.map { ForensicComparisonEngine.compare(baseline: baselineEvidence, against: $0.evidence) } }
    private var comparability: ComparabilityReport? {
        guard let selected else { return nil }
        let telemetry = ComparabilityEngine.compare(baselineEvidence, selected.evidence)
        let context = TestContextComparabilityEngine.compare(session(for: baselineLog.id), session(for: selected.log.id))
        return ComparabilityEngine.incorporatingTestContext(telemetry, context)
    }
    private var validation: ValidationAssessment? { guard let result, let comparability else { return nil }; return RepairValidationEngine.assess(comparison: result, comparability: comparability) }
    private var selectedDataset: ParsedLogData? { selected?.dataset }

    var body: some View {
        List {
            Section("Baseline") {
                Text(baselineLog.filename).font(.headline)
                Text("Event @ \(baselineEvidence.episode.start, specifier: "%.3f") s • Build \(short(baselineEvidence.buildStateID))").font(.caption).foregroundStyle(.secondary)
            }
            Section("Comparison Event") {
                if candidates.isEmpty { Text(errorMessage ?? "No other comparable event has been loaded for this vehicle.").foregroundStyle(.secondary) }
                else {
                    Picker("Compare against", selection: Binding(get: { selectedID ?? candidates.first?.id }, set: { selectedID = $0 })) {
                        ForEach(candidates) { candidate in
                            Text("\(candidate.log.filename) • \(candidate.evidence.episode.start, specifier: "%.2f") s • \(candidate.buildName)").tag(Optional(candidate.id))
                        }
                    }
                }
            }
            if let cohortReport {
                Section("Multi-Run Validation") {
                    HStack { Text(cohortReport.outcome.rawValue.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression).capitalized).font(.headline); Spacer(); Text(cohortReport.confidenceLabel).font(.caption).foregroundStyle(.secondary) }
                    Text("Baseline: \(cohortReport.baselineCount) comparable events • Validation: \(cohortReport.validationCount) • Excluded: \(cohortReport.rejectedEvents)").font(.caption)
                    ForEach(cohortReport.metrics) { metric in
                        HStack {
                            VStack(alignment: .leading) { Text(metric.label); Text("Median \(formatted(metric.baselineMedian)) → \(formatted(metric.validationMedian)) \(metric.unit)").font(.caption).foregroundStyle(.secondary) }
                            Spacer(); Text(metric.delta.map { String(format: "%+.3f", $0) } ?? "—").font(.caption.monospaced())
                        }
                    }
                    if let b=baselineOpportunity, let v=validationOpportunity {
                        VStack(alignment:.leading,spacing:4) {
                            Text("Matched Opportunities").font(.subheadline.bold())
                            Text("Baseline: \(b.recurrences)/\(b.opportunities) recurrences\(rateText(b))")
                            Text("Validation: \(v.recurrences)/\(v.opportunities) recurrences\(rateText(v))")
                            Text("An opportunity is a qualifying operating-condition window, not an event. Zero recurrence is only reported when qualifying opportunities were actually observed.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    ForEach(cohortReport.explanation, id: \.self) { Text($0).font(.caption).foregroundStyle(.secondary) }
                    Button("Save Validation Record") { Task { await saveValidation(cohortReport) } }
                    if let saveStatus { Text(saveStatus).font(.caption).foregroundStyle(.secondary) }
                }
            }
            if let selected, let result {
                if let selectedDataset {
                    Section {
                        ValidationLaboratoryView(baselineDataset: baselineDataset, baselineEvidence: baselineEvidence, validationDataset: selectedDataset, validationEvidence: selected.evidence, cohortReport: cohortReport)
                    }
                }
                if let comparability {
                    Section("Comparability") {
                        HStack { Text(comparability.grade.rawValue.capitalized).font(.headline); Spacer(); Text(comparability.score.map { "\(Int($0 * 100))/100" } ?? "—").font(.system(.headline, design: .monospaced)) }
                        ForEach(comparability.dimensions) { dimension in
                            VStack(alignment: .leading, spacing: 3) { HStack { Text(dimension.label); Spacer(); Text(dimension.score.map { "\(Int($0 * 100))%" } ?? "Missing").font(.caption.monospaced()) }; Text(dimension.detail).font(.caption).foregroundStyle(.secondary) }
                        }
                        ForEach(comparability.blockers, id: \.self) { Label($0, systemImage: "exclamationmark.triangle") }
                    }
                }
                if let validation {
                    Section("Repair Validation") {
                        Text(validation.outcome.rawValue.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression).capitalized).font(.headline)
                        ForEach(validation.explanation, id: \.self) { Text($0).font(.callout) }
                        Text("This is a PredatorLab-derived evidence assessment, not proof of causation.").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("Evidence Deltas") {
                    ForEach(result.deltas) { delta in
                        HStack {
                            VStack(alignment: .leading) { Text(delta.label); Text("\(formatted(delta.baseline)) → \(formatted(delta.comparison)) \(delta.unit)").font(.caption).foregroundStyle(.secondary) }
                            Spacer()
                            Text(delta.delta.map { String(format: "%+.3f", $0) } ?? "—").font(.system(.caption, design: .monospaced))
                        }
                    }
                }
                Section("PredatorLab Comparison") {
                    if result.summary.isEmpty { Text("The available evidence does not support a directional comparison yet.").foregroundStyle(.secondary) }
                    ForEach(result.summary, id: \.self) { Label($0, systemImage: "arrow.left.arrow.right") }
                    Text("Comparison statements are derived from logged evidence, not OEM conclusions. Confirm similar operating conditions before treating changes as causal.").font(.caption).foregroundStyle(.secondary)
                }
                if let vehicle = appState.currentVehicle,
                   let baselineBuildID = baselineEvidence.buildStateID,
                   let validationBuildID = selected.evidence.buildStateID,
                   let baselineBuild = vehicle.buildStates.first(where: { $0.id == baselineBuildID }),
                   let validationBuild = vehicle.buildStates.first(where: { $0.id == validationBuildID }) {
                    let ledger = BuildChangeLedgerEngine.compare(baselineBuild, validationBuild)
                    Section("What Changed") {
                        if ledger.changes.isEmpty { Text("No recorded build-configuration differences.").foregroundStyle(.secondary) }
                        ForEach(ledger.changes) { change in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(change.field).font(.subheadline.bold())
                                Text("\(change.before) → \(change.after)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Text("Recorded configuration differences are context, not proof that any individual change caused the telemetry result.").font(.caption).foregroundStyle(.secondary)
                    }
                }
                let testContext = TestContextComparabilityEngine.compare(session(for: baselineLog.id), session(for: selected.log.id))
                Section("Test Setup Comparability") {
                    HStack { Text(testContext.grade.rawValue.capitalized).font(.headline); Spacer(); Text(testContext.score.map { "\(Int($0 * 100))/100" } ?? "—").font(.caption.monospaced()) }
                    ForEach(testContext.dimensions) { dimension in
                        VStack(alignment: .leading, spacing: 2) { HStack { Text(dimension.label); Spacer(); Text(dimension.score.map { "\(Int($0 * 100))%" } ?? "Unknown").font(.caption.monospaced()) }; Text(dimension.detail).font(.caption).foregroundStyle(.secondary) }
                    }
                    if testContext.differences.isEmpty { Text("No recorded test-setup differences were found, or comparable context is unavailable.").foregroundStyle(.secondary) }
                    ForEach(testContext.differences) { difference in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack { Text(difference.label).font(.subheadline.bold()); if difference.designatedTestVariable { Text("TEST VARIABLE").font(.caption2.bold()).foregroundStyle(.secondary) } }
                            Text("\(difference.baseline) → \(difference.validation)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    ForEach(testContext.missingCriticalContext, id: \.self) { Label($0, systemImage: "questionmark.circle").font(.caption) }
                }
                Section("Context") {
                    Text("Comparison build: \(selected.buildName)")
                    Text("Log: \(selected.log.filename)")
                    Text("Event: \(selected.evidence.episode.eventType) @ \(selected.evidence.episode.start, specifier: "%.3f") s")
                }
            }
        }
        .navigationTitle("Compare Event")
        .task { await loadCandidates() }
    }

    @MainActor private func loadCandidates() async {
        do {
            let logs = try await dataRepository.fetchAllImportedLogs(forVehicle: baselineLog.vehicleID)
            sessions = try await dataRepository.fetchAllSessions(forVehicle: baselineLog.vehicleID)
            var loaded: [ComparisonCandidate] = []
            var opportunityByBuild: [UUID?: [ValidationOpportunity]] = [:]
            for log in logs {
                let dataset: ParsedLogData
                do { dataset = try dataRepository.reloadDataset(for: log) }
                catch {
                    dataRepository.reportPersistenceFailure(domain: "comparisonDatasetReload", recordID: log.id.uuidString, error: error)
                    continue
                }
                let opportunities = ValidationOpportunityEngine.detect(in: dataset, reference: baselineEvidence)
                opportunityByBuild[log.buildStateID, default: []].append(contentsOf: opportunities)
                for episode in LogEventDetector.detectAllEpisodes(logData: dataset).filter({ $0.eventType == baselineEvidence.episode.eventType }) {
                    if log.id == baselineLog.id && abs(episode.start - baselineEvidence.episode.start) < 0.0001 { continue }
                    let evidence = EvidenceExtractionEngine.package(log: dataset, episode: episode, logID: log.id, buildStateID: log.buildStateID)
                    let buildName = buildName(for: log.buildStateID)
                    loaded.append(.init(log: log, dataset: dataset, evidence: evidence, buildName: buildName))
                }
            }
            candidates = loaded.sorted { $0.log.importDate > $1.log.importDate }
            selectedID = candidates.first?.id
            cohortReport = CohortValidationEngine.evaluate(reference: baselineEvidence, candidates: loaded.map { ($0.log, $0.evidence) })
            if let report=cohortReport {
                baselineOpportunity=ValidationOpportunityEngine.summarize(opportunityByBuild[report.baselineBuildStateID] ?? [])
                validationOpportunity=ValidationOpportunityEngine.summarize(opportunityByBuild[report.validationBuildStateID] ?? [])
            }
        } catch { errorMessage = error.localizedDescription }
    }

    @MainActor private func saveValidation(_ report:CohortValidationReport) async {
        let record=PersistedValidationReport(vehicleID:baselineLog.vehicleID, baselineLogID:baselineLog.id, baselineBuildStateID:report.baselineBuildStateID, validationBuildStateID:report.validationBuildStateID, outcome:report.outcome, confidenceLabel:report.confidenceLabel, baselineComparableEvents:report.baselineCount, validationComparableEvents:report.validationCount, rejectedEvents:report.rejectedEvents, baselineOpportunity:baselineOpportunity, validationOpportunity:validationOpportunity, baselineSourceSHA256:baselineLog.sourceSHA256, notes:report.explanation)
        do { try await dataRepository.save(validationReport:record); saveStatus="Validation record saved with analysis-engine provenance." }
        catch { saveStatus="Save failed: \(error.localizedDescription)" }
    }
    private func rateText(_ summary:OpportunitySummary)->String { summary.recurrenceRate.map { " (" + String(format:"%.0f",$0*100) + "%)" } ?? "" }

    private func session(for logID: UUID) -> Session? { sessions.first { $0.logFileID == logID } }
    private func buildName(for id: UUID?) -> String {
        guard let id else { return "Unknown build" }
        return "Build " + String(id.uuidString.prefix(8))
    }
    private func short(_ id: UUID?) -> String { id.map { String($0.uuidString.prefix(8)) } ?? "unknown" }
    private func formatted(_ value: Double?) -> String { value.map { String(format: "%.3f", $0) } ?? "—" }
}

private struct ComparisonCandidate: Identifiable {
    let id = UUID(); let log: ImportedLog; let dataset: ParsedLogData; let evidence: DiagnosticEvidencePackage; let buildName: String
}

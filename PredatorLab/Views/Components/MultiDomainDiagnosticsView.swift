import SwiftUI

/// User-facing entry point for the conservative multi-domain diagnostic execution layer.
/// Candidate episodes are authored analysis heuristics, never OEM monitor results or component diagnoses.
struct MultiDomainDiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataRepository: DataRepository
    let log: ImportedLog

    @State private var dataset: ParsedLogData?
    @State private var reports: [DomainDiagnosticExecutionReport] = []
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let loadError {
                    PlatformUnavailableView(title: "Diagnostics Unavailable", systemImage: "exclamationmark.triangle", description: loadError)
                } else if dataset == nil {
                    ProgressView("Loading evidence…")
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            PLTrackHeader(eyebrow: "Fault Isolation", title: "DIAGNOSTIC PIT BOARD", subtitle: "Start with evidence. Separate wiring, mechanical, software, calibration and acquisition causes before changing parts.", icon: "stethoscope", accent: .plIgnition)
                            PLCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    PLSectionHeader(title: "Evidence Boundary", systemImage: "checkmark.shield")
                                        .accessibilityIdentifier("diagnostics.evidenceBoundary")
                                    Text("These candidate episodes use PredatorLab-authored heuristics. They are not Ford/OEM monitor definitions, do not prove causation, and do not identify a failed component without discriminating evidence.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            ForEach(InvestigationCatalog.all.filter { $0.id != InvestigationCatalog.r04.id }) { definition in
                                let report = reports.first { $0.investigationID == definition.id }
                                PLCard {
                                    VStack(alignment: .leading, spacing: 10) {
                                        PLSectionHeader(title: definition.title, systemImage: report?.missingChannels.isEmpty == false ? "exclamationmark.triangle" : "waveform.path.ecg")
                                        if let report {
                                            HStack {
                                                PLBadge(text: "\(report.episodes.count) candidate episode\(report.episodes.count == 1 ? "" : "s")")
                                                if !report.missingChannels.isEmpty { PLBadge(text: "\(report.missingChannels.count) missing") }
                                            }
                                            if !report.missingChannels.isEmpty {
                                                Text("Missing: " + report.missingChannels.map(\.rawValue).joined(separator: ", "))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            ForEach(report.episodes.prefix(5)) { episode in
                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text(String(format: "%.3f–%.3f s • peak %.3f", episode.start, episode.end, episode.peakMagnitude))
                                                        .font(.system(.caption, design: .monospaced))
                                                    Text(episode.evidenceBoundary).font(.caption2).foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                        if let hypotheses = definition.authoredHypotheses, !hypotheses.isEmpty {
                                            Divider()
                                            Text("Competing hypotheses").font(.caption).fontWeight(.semibold)
                                            ForEach(hypotheses) { hypothesis in
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("\(hypothesis.id) • \(hypothesis.title)").font(.caption).fontWeight(.medium)
                                                    Text(hypothesis.mechanism).font(.caption2).foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .plScreenBackground()
            .navigationTitle("Diagnostics")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task { load() }
        }
    }

    private func load() {
        do {
            let parsed = try dataRepository.reloadDataset(for: log)
            dataset = parsed
            reports = DomainDiagnosticExecutionEngine.executeAll(log: parsed)
        } catch {
            loadError = error.localizedDescription
        }
    }
}

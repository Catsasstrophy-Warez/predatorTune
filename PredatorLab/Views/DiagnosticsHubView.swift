import SwiftUI

/// Entry point for fault isolation. Multi-domain diagnostics run against a specific
/// imported log, so this screen picks the log first, and offers the R04 framework,
/// which works with or without a loaded protection event.
struct DiagnosticsHubView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var dataRepository: DataRepository
    @Environment(\.dismiss) private var dismiss

    @State private var diagnosticLog: ImportedLog?
    @State private var showR04 = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PLTrackHeader(eyebrow: "Fault Isolation", title: "DIAGNOSE", subtitle: "Separate wiring, mechanical, software, calibration and acquisition causes before changing parts.", icon: "stethoscope", accent: .plCritical)

                if appState.allLogs.isEmpty {
                    PLEmptyState(
                        icon: "square.and.arrow.down.on.square",
                        title: "No logs to diagnose",
                        message: "Diagnostics run against an imported HP Tuners log. Import one in Analyze, then come back here.",
                        actionTitle: "Import a log"
                    ) {
                        // Pop first: when pushed from Analyze ▸ Labs, switching segments removes the pushing view.
                        dismiss()
                        appState.openAnalyze(.logs)
                    }
                } else {
                    PLHubSection(title: "Run Diagnostics On", icon: "doc.text.magnifyingglass", accent: .plCritical) {
                        ForEach(appState.allLogs.sorted { $0.importDate > $1.importDate }) { log in
                            Button { diagnosticLog = log } label: {
                                PLHubRow(
                                    title: log.filename,
                                    subtitle: "\(log.events.count) events • \(String(format: "%.0f", log.duration)) s",
                                    icon: "waveform.path.ecg",
                                    accent: .plCritical
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                PLHubSection(title: "Investigation Frameworks", icon: "magnifyingglass", accent: .plIgnition) {
                    Button { showR04 = true } label: {
                        PLHubRow(title: "R04 Insufficient Fuel Flow", subtitle: "Eight ranked hypotheses; scores automatically when a protection event is loaded", icon: "fuelpump.fill", accent: .plIgnition)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("diagnostics.r04")
                }

                PLCard(padding: 14) {
                    Text("Diagnostic episodes use PredatorLab-authored heuristics. They are not OEM monitor definitions and do not prove causation without discriminating evidence.")
                        .font(.plCaption)
                        .foregroundStyle(.plTextSecondary)
                }
            }
            .padding(16)
        }
        .plHardBottomEdge()
        .plScreenBackground()
        .navigationTitle("Diagnose")
        .sheet(item: $diagnosticLog) { log in
            MultiDomainDiagnosticsView(log: log)
                .environmentObject(dataRepository)
        }
        .sheet(isPresented: $showR04) {
            R04InvestigationView()
                .environmentObject(appState)
        }
    }
}

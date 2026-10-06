import SwiftUI

/// Analyze ▸ Labs: every analysis instrument in workflow order —
/// acquire, investigate, then deep telemetry benches.
struct AnalyzeLabsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PLHubSection(title: "Acquire", icon: "cable.connector", accent: .plBoost) {
                    NavigationLink { MPVI4DiagnosticAcquisitionLabRev74View() } label: {
                        PLHubRow(title: "MPVI4 Acquisition", subtitle: "Connection state, logging setup and acquisition quality", icon: "cable.connector", accent: .plBoost)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("analyze.acquisition")
                }

                PLHubSection(title: "Investigate", icon: "scope", accent: .plSuccess) {
                    NavigationLink { PredatorLabWorkstationRev85() } label: {
                        PLHubRow(title: "Forensic Workstation", subtitle: "Pull Lab, evidence, calibration, topology, execution, replay", icon: "scope", accent: .plBoost)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("analyze.workstation")
                    NavigationLink { DiagnosticsHubView() } label: {
                        PLHubRow(title: "Diagnostic Pit Board", subtitle: "Multi-domain fault isolation and the R04 framework", icon: "stethoscope", accent: .plCritical)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("analyze.diagnostics")
                    NavigationLink { GoldenCorpusSessionView() } label: {
                        PLHubRow(title: "Reference Forensic Session", subtitle: "Explore the unified session on the bundled GT500 log", icon: "rectangle.3.group.fill", accent: .plSuccess, badge: "DEMO")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("analyze.referenceSession")
                    NavigationLink { GoldenCorpusGuidedInvestigationViewRev160().plScreenBackground().navigationTitle("Guided Investigation") } label: {
                        PLHubRow(title: "Guided Investigation", subtitle: "Step-by-step walkthrough of the evidence workflow", icon: "graduationcap.fill", accent: .plSuccess)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("analyze.guidedInvestigation")
                }

                PLHubSection(title: "Telemetry Benches", icon: "waveform.path", accent: .plIgnition) {
                    NavigationLink { TelemetryRenderingView() } label: {
                        PLHubRow(title: "3D Telemetry Cockpit", subtitle: appState.currentLogData == nil ? "Demo data until a log is opened" : "Replaying the most recently opened log", icon: "cube.transparent", accent: .plIgnition)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("analyze.telemetryCockpit")
                    NavigationLink { HPLCorrelationTelemetryRev81View() } label: {
                        PLHubRow(title: "HPL + VCM Telemetry", subtitle: "Artifact-specific HPL research and correlation", icon: "waveform.path", accent: .plBoost)
                    }
                    .buttonStyle(.plain)
                    NavigationLink { GT500HighLoadPullLabRev68View() } label: {
                        PLHubRow(title: "High-Load Reconstruction", subtitle: "Reconstruct demand events without inventing causality", icon: "speedometer", accent: .plCritical)
                    }
                    .buttonStyle(.plain)
                    NavigationLink { GT500FlagshipForensicsRev77View() } label: {
                        PLHubRow(title: "GT500 Flagship Forensics", subtitle: "The reference September 2 forensic case", icon: "flag.checkered", accent: .plSuccess)
                    }
                    .buttonStyle(.plain)
                }

                PLEvidenceLaneLegend()
                    .padding(.vertical, 4)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .accessibilityIdentifier("analyze.labs")
    }
}

import SwiftUI

/// The Paddock is the organized home for specialist tools. Primary tabs stay task-focused;
/// deep capabilities are grouped by the job the user is trying to perform.
struct MoreHubView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    PLTrackHeader(eyebrow: "Paddock", title: "TOOLS + SYSTEMS", subtitle: "Specialist benches, vehicle systems, research, reference and app controls without the scavenger hunt.", icon: "square.grid.2x2.fill", accent: .plBoost)

                    NavigationLink { TrackWorkshopSystemsView() } label: {
                        PLTrackSection(title: "Systems Paddock", subtitle: "Wiring, controllers, sensors, fuel, engine, DCT, chassis, brakes and steering.", icon: "wrench.and.screwdriver.fill", accent: .plBoost) {
                            HStack { Text("Explore by vehicle system").font(.plBody).foregroundStyle(.plTextPrimary); Spacer(); Image(systemName: "chevron.right").foregroundStyle(.plBoost) }
                        }
                    }.buttonStyle(.plain).accessibilityIdentifier("more.systems")

                    MoreSection(title: "Diagnose & Test", accent: .plCritical) {
                        NavigationLink { MultiDomainDiagnosticsView() } label: { MoreRow("Diagnostic Pit Board", "stethoscope") }.accessibilityIdentifier("more.diagnostics")
                        NavigationLink { MPVI4DiagnosticAcquisitionLabRev74View() } label: { MoreRow("Acquisition Bench", "cable.connector") }.accessibilityIdentifier("more.acquisition")
                        NavigationLink { PredatorLabWorkstationRev85() } label: { MoreRow("Forensic Command Center", "scope") }.accessibilityIdentifier("more.forensics")
                    }
                    MoreSection(title: "Research & Reference", accent: .plBoost) {
                        NavigationLink { GT500ResearchCommandCenterView() } label: { MoreRow("Research Command", "books.vertical.fill") }.accessibilityIdentifier("more.research")
                        NavigationLink { ReferenceLibraryView() } label: { MoreRow("Workshop Manual", "book.closed.fill") }.accessibilityIdentifier("more.reference")
                        NavigationLink { TechnicalTruthReviewView() } label: { MoreRow("Evidence Authority Review", "checkmark.shield.fill") }
                    }
                    MoreSection(title: "Track & Data", accent: .plSuccess) {
                        NavigationLink { GT500FlagshipForensicsRev77View() } label: { MoreRow("GT500 Flagship Forensics", "flag.checkered") }
                        NavigationLink { HPLCorrelationTelemetryRev81View() } label: { MoreRow("HPL + VCM Telemetry", "waveform.path.ecg") }
                        NavigationLink { GT500HighLoadPullLabRev68View() } label: { MoreRow("High-Load Reconstruction", "speedometer") }
                    }
                    MoreSection(title: "App", accent: .plIgnition) {
                        NavigationLink { SettingsView() } label: { MoreRow("Settings", "gearshape.fill") }.accessibilityIdentifier("more.settings")
                        NavigationLink { ProductReviewRev84View() } label: { MoreRow("Readiness + Next Actions", "checklist") }
                    }
                    PLEvidenceLaneLegend().padding(.vertical, 4)
                }.padding(16)
            }.plHardBottomEdge().plScreenBackground().navigationTitle("Paddock")
        }.accessibilityIdentifier("more.hub")
    }
}

private struct MoreSection<Content: View>: View {
    let title: String; let accent: Color; @ViewBuilder let content: Content
    var body: some View { PLCard { VStack(alignment: .leading, spacing: 4) { PLSectionHeader(title: title, systemImage: "flag.checkered", accent: accent); content } } }
}
private struct MoreRow: View {
    let title: String; let icon: String
    init(_ title: String, _ icon: String) { self.title = title; self.icon = icon }
    var body: some View { HStack(spacing: 12) { Image(systemName: icon).foregroundStyle(.plBoost).frame(width: 26); Text(title).font(.plBody).foregroundStyle(.plTextPrimary); Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundStyle(.plTextSecondary) }.padding(.vertical, 10).contentShape(Rectangle()) }
}

import SwiftUI

/// Library tab: knowledge about the car (systems, manual, research, evidence authority)
/// and app controls. Identifiers keep their historical `more.*` names because UI tests
/// and automation address them.
struct LibraryHubView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    PLTrackHeader(eyebrow: "Library", title: "KNOW THE CAR", subtitle: "Systems, workshop manual, research and evidence authority in one shelf.", icon: "books.vertical.fill", accent: .plBoost)

                    PLHubSection(title: "The Car", icon: "car.side.fill", accent: .plBoost) {
                        NavigationLink { TrackWorkshopSystemsView() } label: {
                            PLHubRow(title: "Systems", subtitle: "Engine, fuel, controllers, DCT, chassis, brakes, wiring, sensors", icon: "wrench.and.screwdriver.fill", accent: .plBoost)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("more.systems")
                        NavigationLink { GT500DigitalTwinView() } label: {
                            PLHubRow(title: "Digital Twin", subtitle: "Interactive vehicle map with evidence per node", icon: "point.3.connected.trianglepath.dotted", accent: .plIgnition)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("more.digitalTwin")
                    }

                    PLHubSection(title: "Reference & Research", icon: "book.closed.fill", accent: .plSuccess) {
                        NavigationLink { ReferenceLibraryView() } label: {
                            PLHubRow(title: "Workshop Manual", subtitle: "Components, procedures, maintenance and specs", icon: "book.closed.fill", accent: .plSuccess)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("more.reference")
                        NavigationLink { GT500ResearchCommandCenterView() } label: {
                            PLHubRow(title: "Research Command", subtitle: "Highest-leverage missing evidence and coverage map", icon: "books.vertical.fill", accent: .plBoost)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("more.research")
                        NavigationLink { EvidenceAuthorityLedgerScreen() } label: {
                            PLHubRow(title: "Evidence Authority Review", subtitle: "Every technical assertion with its source and verification state", icon: "checkmark.shield.fill", accent: .plWarning)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("more.truthLedger")
                    }

                    PLHubSection(title: "App", icon: "gearshape.fill", accent: .plIgnition) {
                        NavigationLink { SettingsView() } label: {
                            PLHubRow(title: "Settings", subtitle: "Display, vehicle, storage and data management", icon: "gearshape.fill", accent: .plIgnition)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("more.settings")
                    }

                    PLHubSection(title: "Developer", icon: "hammer.fill", accent: .plTextSecondary,
                                 footnote: "Engineering status of PredatorLab itself. Not about your car.") {
                        NavigationLink { ProductReviewRev84View() } label: {
                            PLHubRow(title: "App Readiness", subtitle: "Open engineering work in this build", icon: "checklist", accent: .plTextSecondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("more.appReadiness")
                        NavigationLink { ProductionExecutionRev83View() } label: {
                            PLHubRow(title: "Production Gates", subtitle: "Release gates and what blocks them", icon: "flag.2.crossed.fill", accent: .plTextSecondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("more.productionGates")
                    }

                    PLEvidenceLaneLegend().padding(.vertical, 4)
                }
                .padding(16)
            }
            .plHardBottomEdge()
            .plScreenBackground()
            .navigationTitle("Library")
        }
        .accessibilityIdentifier("more.hub")
    }
}

/// Owns the query engine the ledger list observes.
private struct EvidenceAuthorityLedgerScreen: View {
    @StateObject private var engine = TechnicalQueryEngine()

    var body: some View {
        TechnicalTruthLedgerView(engine: engine)
            .navigationTitle("Evidence Authority")
    }
}

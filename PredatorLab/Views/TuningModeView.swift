import SwiftUI

/// Tune tab: readiness first, then the calibration workflow in the order it is used,
/// then the evidence labs that back each decision.
struct TuningModeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataRepository: DataRepository
    @State private var workspace: TuneWorkspaceSnapshot?

    private var readiness: TuneReadinessAssessment {
        workspace?.readiness ?? TuneReadinessEngine.assess(
            vehiclePresent: appState.currentVehicle != nil,
            calibrationIdentified: false,
            baselineAvailable: false,
            unresolvedDiagnosticBlockers: [],
            acquisitionQuality: nil
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    PLTrackHeader(eyebrow: "Calibration Pit Wall", title: "TUNE WITH EVIDENCE", subtitle: "Baseline first. Change one thing. Measure the result.", icon: "gauge.with.dots.needle.67percent", accent: .plIgnition)
                    readinessCard

                    PLHubSection(title: "Calibration Workflow", icon: "point.topleft.down.to.point.bottomright.curvepath", accent: .plIgnition) {
                        NavigationLink { TuneWorkflowRev70View() } label: {
                            PLHubRow(title: "Guided Tune Workflow", subtitle: "Move through the calibration process with gates", icon: "point.topleft.down.to.point.bottomright.curvepath", accent: .plIgnition)
                        }.buttonStyle(.plain)
                        NavigationLink { TuneEvidenceWorkspaceRev72View() } label: {
                            PLHubRow(title: "Evidence Workspace", subtitle: "Organize the evidence bundle behind each decision", icon: "checkmark.shield.fill", accent: .plSuccess)
                        }.buttonStyle(.plain)
                        NavigationLink { PredatorLabWorkstationRev85() } label: {
                            PLHubRow(title: "Forensic Workstation", subtitle: "Calibration deltas, timeline and synchronized investigation", icon: "scope", accent: .plBoost)
                        }.buttonStyle(.plain)
                        NavigationLink { ProductionExecutionRev83View() } label: {
                            PLHubRow(title: "Production Readiness", subtitle: "See what is proven, blocked or still required", icon: "checklist", accent: .plCritical)
                        }.buttonStyle(.plain)
                    }

                    PLHubSection(title: "Evidence Labs", icon: "star.square.on.square.fill", accent: .plBoost) {
                        NavigationLink { FlagshipIntegrationRev82View() } label: {
                            PLHubRow(title: "Flagship Evidence Lab", subtitle: "Deep integrated GT500 evidence workflow", icon: "star.square.on.square.fill", accent: .plBoost)
                        }.buttonStyle(.plain)
                        NavigationLink { GT500RealEvidenceRev76View() } label: {
                            PLHubRow(title: "Real GT500 Evidence", subtitle: "Vehicle-specific evidence bundle", icon: "car.side.fill", accent: .plSuccess)
                        }.buttonStyle(.plain)
                        NavigationLink { GT500ResearchCommandCenterView() } label: {
                            PLHubRow(title: "Calibration Research", subtitle: "Missing controller and calibration evidence, ranked", icon: "books.vertical.fill", accent: .plBoost)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("tune.research.open")
                    }

                    PLCard(padding: 14) {
                        Text(TuneEvidenceBundleContract.boundary).font(.plCaption).foregroundStyle(.plTextSecondary)
                    }
                }
                .padding(16)
            }
            .plHardBottomEdge()
            .plScreenBackground()
            .navigationTitle("Tune")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: appState.currentBuildStateID) { workspace = await dataRepository.resolveTuneWorkspace(appState: appState) }
        }
    }

    private var readinessAccent: Color { readiness.blockers.isEmpty ? .plSuccess : .plWarning }

    private var readinessCard: some View {
        PLCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    PLSectionHeader(title: "Tune Readiness", systemImage: "lightswitch.on", accent: readinessAccent)
                    Spacer()
                    PLBadge(text: readiness.state.rawValue.uppercased(), color: readinessAccent, filled: false)
                }
                if readiness.blockers.isEmpty {
                    Label("No current readiness blocker is reported by this assessment.", systemImage: "checkmark.circle.fill")
                        .font(.plCaption).foregroundStyle(.plSuccess)
                } else {
                    ForEach(readiness.blockers, id: \.self) {
                        Label($0, systemImage: "exclamationmark.triangle.fill").font(.plCaption).foregroundStyle(.plWarning)
                    }
                }
                ForEach(readiness.requirements, id: \.self) {
                    Label($0, systemImage: "circle").font(.plCaption).foregroundStyle(.plTextSecondary)
                }
                if let workspace {
                    ForEach(workspace.missing, id: \.self) {
                        Label($0, systemImage: "questionmark.diamond").font(.plCaption).foregroundStyle(.plTextSecondary)
                    }
                }
            }
        }
        .accessibilityIdentifier("tune.readiness")
    }
}

import SwiftUI

struct TuningModeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataRepository: DataRepository
    @State private var showResearch = false
    @State private var workspace: TuneWorkspaceSnapshot?
    private var readiness: TuneReadinessAssessment { workspace?.readiness ?? TuneReadinessEngine.assess(vehiclePresent: appState.currentVehicle != nil, calibrationIdentified: false, baselineAvailable: false, unresolvedDiagnosticBlockers: [], acquisitionQuality: nil) }
    private let cols = [GridItem(.adaptive(minimum: 250), spacing: 10)]
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    PLTrackHeader(eyebrow: "Calibration Pit Wall", title: "TUNE WITH EVIDENCE", subtitle: "Baseline first. Change one thing. Measure the result. Keep controller lineages separate.", icon: "gauge.with.dots.needle.67percent", accent: .plIgnition)
                    readinessCard
                    VStack(alignment: .leading, spacing: 10) {
                        PLSectionHeader(title: "Race Engineer Workflow", systemImage: "flag.checkered", accent: .plBoost)
                        LazyVGrid(columns: cols, spacing: 10) {
                            PLPitRoute(title:"Forensic Workstation", subtitle:"Timeline, Evidence/Why and synchronized investigation", icon:"scope", accent:.plBoost, destination: PredatorLabWorkstationRev85())
                            PLPitRoute(title:"Guided Tune Workflow", subtitle:"Move through the calibration process with gates", icon:"point.topleft.down.to.point.bottomright.curvepath", accent:.plIgnition, destination: TuneWorkflowRev70View())
                            PLPitRoute(title:"Evidence Workspace", subtitle:"Organize the evidence bundle behind each decision", icon:"checkmark.shield.fill", accent:.plSuccess, destination: TuneEvidenceWorkspaceRev72View())
                            PLPitRoute(title:"Production Readiness", subtitle:"See what is proven, blocked or still required", icon:"checklist", accent:.plCritical, destination: ProductionExecutionRev83View())
                            PLPitRoute(title:"Flagship Evidence Lab", subtitle:"Deep integrated GT500 evidence workflow", icon:"star.square.on.square.fill", accent:.plBoost, destination: FlagshipIntegrationRev82View())
                            PLPitRoute(title:"App Review + Next Actions", subtitle:"Product readiness and remaining work", icon:"list.bullet.clipboard.fill", accent:.plWarning, destination: ProductReviewRev84View())
                        }
                    }
                    PLCard { VStack(alignment:.leading,spacing:10) { PLSectionHeader(title:"Test Bench",systemImage:"wrench.adjustable.fill",accent:.plIgnition); PLPitRoute(title:"MPVI4 Acquisition",subtitle:"Connection-state, logging and acquisition tools",icon:"cable.connector",accent:.plBoost,destination:MPVI4DiagnosticAcquisitionLabRev74View()); PLPitRoute(title:"Real GT500 Evidence",subtitle:"Vehicle-specific evidence bundle",icon:"car.side.fill",accent:.plSuccess,destination:GT500RealEvidenceRev76View()); PLPitRoute(title:"High-Load Reconstruction",subtitle:"Reconstruct demand events without inventing causality",icon:"speedometer",accent:.plCritical,destination:GT500HighLoadPullLabRev68View()); PLPitRoute(title:"HPL + VCM Telemetry",subtitle:"Artifact-specific HPL research and correlation",icon:"waveform.path",accent:.plBoost,destination:HPLCorrelationTelemetryRev81View()) } }
                    Button { showResearch = true } label: { Label("Open Calibration Research Command", systemImage:"books.vertical.fill").frame(maxWidth:.infinity).padding(14).background(Color.plBoost.opacity(0.14)).clipShape(RoundedRectangle(cornerRadius:14)).overlay(RoundedRectangle(cornerRadius:14).stroke(Color.plBoost.opacity(0.5))) }.buttonStyle(.plain).foregroundStyle(.plTextPrimary).accessibilityIdentifier("tune.research.open")
                    PLCard { Text(TuneEvidenceBundleContract.boundary).font(.plCaption).foregroundStyle(.plTextSecondary) }
                }.padding(16)
            }.plHardBottomEdge().plScreenBackground().navigationTitle("Tune").navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented:$showResearch) { NavigationStack { GT500ResearchCommandCenterView() } }
                .task(id: appState.currentBuildStateID) { workspace = await dataRepository.resolveTuneWorkspace(appState: appState) }
        }
    }
    private var readinessCard: some View { PLCard { VStack(alignment:.leading,spacing:8) { HStack { PLSectionHeader(title:"Tune Readiness",systemImage:"lightswitch.on",accent: readiness.blockers.isEmpty ? .plSuccess : .plWarning); Spacer(); Text(readiness.state.rawValue.uppercased()).font(.plMono(11)).foregroundStyle(readiness.blockers.isEmpty ? .plSuccess : .plWarning) }; if readiness.blockers.isEmpty { Label("No current readiness blocker is reported by this assessment.",systemImage:"checkmark.circle.fill").font(.plCaption).foregroundStyle(.plSuccess) } else { ForEach(readiness.blockers,id:\.self){Label($0,systemImage:"exclamationmark.triangle.fill").font(.plCaption).foregroundStyle(.plWarning)} }; ForEach(readiness.requirements,id:\.self){Text($0).font(.plCaption).foregroundStyle(.plTextSecondary)}; if let workspace { ForEach(workspace.missing,id:\.self){Label($0,systemImage:"questionmark.diamond").font(.plCaption).foregroundStyle(.plTextSecondary)} } } } }
}

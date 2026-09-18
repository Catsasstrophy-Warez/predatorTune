import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct TuneEvidenceWorkspaceRev72View: View {
    @EnvironmentObject var appState:AppState
    @EnvironmentObject var dataRepository:DataRepository
    @State private var reviews:[VCMScannerSemanticReview]=[]
    @State private var result:TuneEvidenceWorkspaceRev72?
    @State private var loadError:String?

    var body: some View {
        List {
            Section("Evidence workflow") {
                if let loadError { PLLoadErrorCard(title: "Could not load reviewed semantics", message: loadError) { Task { await load() } } }
                LabeledContent("Vehicle",value:appState.currentVehicle == nil ? "Missing":"Selected")
                LabeledContent("Build Revision",value:appState.currentBuildStateID == nil ? "Missing":"Bound")
                LabeledContent("Current parsed log",value:appState.currentLogData?.filename ?? "Missing")
                LabeledContent("Reviewed Scanner semantics",value:"\(reviews.filter(\.admittedForAnalysis).count)")
                Button("Analyze current evidence") { rebuild() }.disabled(appState.currentLogData == nil)
            }
            if let result {
                Section("What changed / what is supported") { ForEach(result.summary.supportedObservations,id:\.self){Label($0,systemImage:"checkmark.circle")} }
                Section("What remains uncertain") { ForEach(result.summary.uncertainties,id:\.self){Label($0,systemImage:"questionmark.diamond")} }
                Section("Scanner Contract Builder") {
                    LabeledContent("Required admitted",value:"\(result.scannerPlan.admittedRequiredSemantics.count)")
                    LabeledContent("Required missing",value:"\(result.scannerPlan.missingRequiredSemantics.count)")
                    ForEach(result.scannerPlan.recommendations.prefix(12)) { r in
                        VStack(alignment:.leading,spacing:3){ Text("\(r.action.rawValue): \(r.semanticID)").font(.subheadline.weight(.semibold)); Text(r.reason).font(.caption).foregroundStyle(.secondary) }
                    }
                    Text(result.scannerPlan.boundary).font(.caption).foregroundStyle(.secondary)
                }
                Section("TR_C75") { LabeledContent("Shift windows",value:"\(result.shifts.count)"); Text("Gear/RPM chronology does not establish clutch pressure, torque handoff strategy, or durability.").font(.caption).foregroundStyle(.secondary) }
                Section("Next experiment") { ForEach(result.summary.nextActions,id:\.self){Text($0)} }
                Section("Evidence boundary") { Text(result.boundary).font(.caption).foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("Tune Evidence Workspace")
        .task(id:appState.currentBuildStateID) { await load() }
    }
    private func rebuild(){ result=TuneEvidenceWorkspaceEngineRev72.build(currentLog:appState.currentLogData,baselineLog:nil,reviews:reviews,experimentComparable:false,sameBuild:true,sameFuel:true) }
    @MainActor private func load() async { do { if let id=appState.currentVehicle?.id { reviews=try await dataRepository.fetchScannerSemanticReviews(vehicleID:id) }; loadError=nil } catch { loadError=error.localizedDescription }; rebuild() }
}

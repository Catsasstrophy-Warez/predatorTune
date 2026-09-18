import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct TuneWorkflowRev70View: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataRepository: DataRepository
    @State private var workspace:TuneWorkspaceSnapshot?
    @State private var reviews:[VCMScannerSemanticReview]=[]
    @State private var pipeline:TuneEvidencePipelineResult?
    @State private var loadError:String?

    var body: some View {
        List {
            Section("Workflow") {
                if let loadError { PLLoadErrorCard(title: "Could not load reviewed semantics", message: loadError) { Task { await load() } } }
                if let workspace {
                    let plan=TuneWorkflowCoordinatorRev69.plan(workspace,semanticReviewCount:reviews.filter{$0.admittedForAnalysis}.count,validationEnvelopePresent:false,reconstructionPresent:pipeline?.reconstruction != nil)
                    ForEach(plan.checkpoints) { row in
                        Label(row.stage,systemImage:row.complete ? "checkmark.circle.fill" : "circle")
                        ForEach(row.blockers,id:\.self) { Text($0).font(.caption).foregroundStyle(.secondary) }
                    }
                    LabeledContent("Next",value:plan.nextAction)
                } else { ProgressView() }
            }
            Section("Current parsed log") {
                if let log=appState.currentLogData {
                    LabeledContent("File",value:log.filename)
                    LabeledContent("Rows",value:"\(log.sampleCount)")
                    LabeledContent("Channels",value:"\(log.channels.count)")
                    Button("Run reviewed evidence pipeline") { pipeline=TuneEvidencePipelineRev70.run(log:log,reviews:reviews) }
                        .disabled(reviews.filter{$0.admittedForAnalysis}.isEmpty)
                } else { Text("Import/select a parsed VCM Scanner CSV log first.").foregroundStyle(.secondary) }
            }
            if let p=pipeline {
                Section("Evidence admission") {
                    LabeledContent("Bound reviewed signals",value:"\(p.admission.admittedSemanticIDs.count)")
                    LabeledContent("Unresolved reviewed bindings",value:"\(p.admission.unresolvedSemanticIDs.count)")
                    LabeledContent("Pull candidates",value:"\(p.segmentation.candidateWindows.count)")
                }
                Section("Next measurement / experiment") { Text(p.nextAction); Text(p.boundary).font(.caption).foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("Tune Workflow")
        .task(id:appState.currentBuildStateID) {
            await load()
        }
    }
    @MainActor private func load() async { workspace=await dataRepository.resolveTuneWorkspace(appState:appState); do { if let id=appState.currentVehicle?.id { reviews=try await dataRepository.fetchScannerSemanticReviews(vehicleID:id) }; loadError=nil } catch { loadError=error.localizedDescription } }
}

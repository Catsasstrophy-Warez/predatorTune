import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct TuneUnifiedEvidenceRev71View: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataRepository: DataRepository
    @State private var reviews:[VCMScannerSemanticReview]=[]
    @State private var pipeline:TuneEvidencePipelineResult?
    @State private var shifts:[TRC75ShiftWindowRev71]=[]
    @State private var loadError:String?

    var body: some View {
        List {
            Section("Unified Evidence") {
                if let loadError { PLLoadErrorCard(title: "Could not load reviewed semantics", message: loadError) { Task { await load() } } }
                if let log=appState.currentLogData {
                    LabeledContent("Log",value:log.filename)
                    LabeledContent("Rows",value:"\(log.sampleCount)")
                    Button("Reconstruct reviewed evidence") {
                        let p=TuneEvidencePipelineRev70.run(log:log,reviews:reviews)
                        pipeline=p
                        shifts=TRC75ShiftSegmenterRev71.extract(log:log,admission:p.admission)
                    }.disabled(reviews.filter(\.admittedForAnalysis).isEmpty)
                } else { Text("Select/import a parsed VCM Scanner CSV log.").foregroundStyle(.secondary) }
            }
            if let pipeline {
                let summary=UnifiedTuneEvidenceExplainerRev71.summarize(pipeline:pipeline,shifts:shifts)
                Section("What the evidence supports") { ForEach(summary.supportedObservations,id:\.self){Label($0,systemImage:"checkmark.circle")} }
                Section("What remains uncertain") { ForEach(summary.uncertainties,id:\.self){Label($0,systemImage:"questionmark.diamond")} }
                Section("What to measure next") { ForEach(summary.nextActions,id:\.self){Text($0)} }
                Section("TR_C75 shift evidence") { LabeledContent("Reconstructed transitions",value:"\(shifts.count)"); Text("Shift windows require reviewed gear and RPM bindings. RPM behavior alone does not reveal clutch pressure or durability.").font(.caption).foregroundStyle(.secondary) }
                Section("Evidence boundary") { Text(summary.boundary).font(.caption).foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("Unified Tune Evidence")
        .task(id:appState.currentBuildStateID) {
            await load()
        }
    }
    @MainActor private func load() async { do { if let id=appState.currentVehicle?.id { reviews=try await dataRepository.fetchScannerSemanticReviews(vehicleID:id) }; loadError=nil } catch { loadError=error.localizedDescription } }
}

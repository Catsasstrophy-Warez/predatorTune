import SwiftUI

/// Human review surface for non-circuit truth assertions. Reviews are durable and revisioned,
/// but cannot verify neighboring assertions because semantic IDs are isolated.
struct TechnicalTruthReviewView: View {
    @EnvironmentObject var dataRepository: DataRepository
    let entry: TechnicalTruthLedgerEntry
    @Environment(\.dismiss) private var dismiss
    @State private var state: ClaimVerificationState
    @State private var applicability: String
    @State private var sourceTitle: String
    @State private var sourceReference: String
    @State private var locator: String
    @State private var reason: String = ""
    @State private var revisions: [TechnicalTruthRevision] = []
    @State private var errorText: String?

    init(entry: TechnicalTruthLedgerEntry) {
        self.entry=entry
        _state=State(initialValue:entry.state); _applicability=State(initialValue:entry.applicability)
        _sourceTitle=State(initialValue:entry.sourceTitle ?? ""); _sourceReference=State(initialValue:"")
        _locator=State(initialValue:entry.locator ?? "")
    }

    var body: some View {
        Form {
            Section("Assertion") { Text(entry.statement); if let v=entry.authoredValue { LabeledContent("Authored",value:"\(v) \(entry.unit ?? "")") }; Text(entry.boundary).font(.caption).foregroundStyle(.secondary) }
            Section("Review") {
                Picker("State",selection:$state) { ForEach([ClaimVerificationState.predatorLabDerived,.communityObservation,.unverified,.disputed,.superseded],id:\.rawValue){Text($0.rawValue).tag($0)} }
                Text("Verified authority states are assigned only through the controlled Promotion Workbench.").font(.caption2).foregroundStyle(.secondary)
                TextField("Applicability",text:$applicability)
                TextField("Source title",text:$sourceTitle)
                TextField("Source reference",text:$sourceReference)
                TextField("Exact locator",text:$locator)
                TextField("Reason",text:$reason,axis:.vertical)
                Button("Save immutable revision") { Task { await save() } }.disabled(reason.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                Button("Dispute assertion",role:.destructive) { state = .disputed; reason = reason.isEmpty ? "Disputed during technical-truth review." : reason; Task { await save() } }
                Button("Supersede assertion") { state = .superseded; reason = reason.isEmpty ? "Superseded by a newer technical assertion." : reason; Task { await save() } }
            }
            if let errorText { Section("Persistence") { Text(errorText).foregroundStyle(.red) } }
            Section("Revision history") {
                if revisions.isEmpty { Text("No durable reviews yet.").foregroundStyle(.secondary) }
                ForEach(revisions) { r in VStack(alignment:.leading){ Text("Revision \(r.revisionNumber) • \(r.snapshot.state.rawValue)").font(.caption).fontWeight(.semibold); Text(r.reason).font(.caption2); Text(r.recordedAt.formatted()).font(.caption2).foregroundStyle(.secondary) } }
            }
        }
        .navigationTitle("Truth Review")
        .task { await load() }
        .accessibilityIdentifier("truthReview.\(entry.id)")
    }

    private func load() async {
        do { revisions = try await dataRepository.fetchTechnicalTruthRevisions(truthID:entry.id) }
        catch { errorText=error.localizedDescription }
    }
    private func save() async {
        let disposition: TechnicalTruthDisposition = state == .disputed ? .disputed : (state == .superseded ? .superseded : ([ClaimVerificationState.oemVerified,.manufacturerVerified,.professionalCorroboration,.empiricallyVerified].contains(state) ? .verified : .quarantined))
        let reviewed=TechnicalTruthLedgerEntry(id:entry.id,domain:entry.domain,ownerID:entry.ownerID,ownerTitle:entry.ownerTitle,statement:entry.statement,authoredValue:entry.authoredValue,unit:entry.unit,condition:entry.condition,applicability:applicability,state:state,disposition:disposition,sourceTitle:sourceTitle.isEmpty ? nil : sourceTitle,locator:locator.isEmpty ? nil : locator,criticality:entry.criticality,boundary:entry.boundary)
        let snapshot=PersistedTechnicalTruth(entry:reviewed,sourceReference:sourceReference.isEmpty ? nil : sourceReference,reviewReason:reason)
        do {
            let existing=try await dataRepository.fetchTechnicalTruthRevisions(truthID:entry.id)
            let revision=TechnicalTruthRevisionEngine.append(snapshot,reason:reason,existing:existing)
            try await dataRepository.save(technicalTruth:snapshot); try await dataRepository.save(technicalTruthRevision:revision)
            revisions=try await dataRepository.fetchTechnicalTruthRevisions(truthID:entry.id); errorText=nil
        } catch { errorText=error.localizedDescription }
    }
}

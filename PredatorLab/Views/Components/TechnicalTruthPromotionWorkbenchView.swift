import SwiftUI

struct TechnicalTruthPromotionWorkbenchView: View {
    @EnvironmentObject var dataRepository: DataRepository
    @ObservedObject var engine: TechnicalQueryEngine
    @State private var artifacts: [PersistedEvidenceArtifact] = []
    @State private var reviews: [EvidenceTruthReview] = []
    @State private var persisted: [PersistedTechnicalTruth] = []
    @State private var errorText: String?
    private var base: [TechnicalTruthLedgerEntry] { TechnicalTruthLedger.compile(engine: engine) }
    private var resolved: [TechnicalTruthLedgerEntry] { TechnicalTruthResolutionEngine.resolved(base: base, persisted: persisted) }

    var body: some View {
        List {
            Section("Controlled Promotion") { Text(TechnicalTruthPromotionGate.boundary).font(.caption).foregroundStyle(.secondary) }
            if let errorText { Section("Persistence") { Text(errorText).foregroundStyle(.red) } }
            ForEach(candidates, id: \.truth.id) { candidate in
                Section(candidate.truth.ownerTitle) {
                    Text(candidate.truth.statement)
                    LabeledContent("Current", value: candidate.truth.disposition.rawValue)
                    LabeledContent("Artifact", value: candidate.artifact.artifact.rawValue)
                    LabeledContent("Authority", value: TechnicalTruthPromotionGate.authorityGrade(candidate.artifact)?.rawValue ?? "Unclassified")
                    NavigationLink("Review promotion") { PromotionDetail(truth:candidate.truth, artifact:candidate.artifact, reviews:candidate.reviews).environmentObject(dataRepository) }
                }
            }
            if candidates.isEmpty { Section { Text("No claim-level supporting reviews are currently ready for promotion assessment.").foregroundStyle(.secondary) } }
        }.navigationTitle("Truth Promotion").task { await load() }
    }

    private var candidates: [(truth:TechnicalTruthLedgerEntry,artifact:PersistedEvidenceArtifact,reviews:[EvidenceTruthReview])] {
        artifacts.compactMap { artifact in
            let r = reviews.filter { $0.artifactID == artifact.id }
            guard let support = r.first(where: { $0.decision == .supports }), let truth = resolved.first(where: { $0.id == support.truthID }) else { return nil }
            return (truth,artifact,r.filter{$0.truthID == truth.id})
        }
    }
    private func load() async { do { artifacts=try await dataRepository.fetchEvidenceArtifacts(); reviews=try await dataRepository.fetchEvidenceTruthReviews(); persisted=try await dataRepository.fetchTechnicalTruth(); errorText=nil } catch { errorText=error.localizedDescription } }
}

private struct PromotionDetail: View {
    @EnvironmentObject var dataRepository: DataRepository
    let truth: TechnicalTruthLedgerEntry; let artifact: PersistedEvidenceArtifact; let reviews:[EvidenceTruthReview]
    @State private var target: ClaimVerificationState = .oemVerified
    @State private var reason = ""
    @State private var status: String?
    var assessment: TechnicalTruthPromotionAssessment { TechnicalTruthPromotionGate.assess(truth:truth,artifact:artifact,reviews:reviews,targetState:target) }
    var body: some View {
        Form {
            Section("Assertion") { Text(truth.statement); Text(truth.boundary).font(.caption).foregroundStyle(.secondary) }
            Section("Promotion gate") {
                Picker("Target",selection:$target) { ForEach([ClaimVerificationState.oemVerified,.manufacturerVerified,.professionalCorroboration],id:\.rawValue){Text($0.rawValue).tag($0)} }
                LabeledContent("Eligible", value: assessment.eligible ? "Yes" : "No")
                if assessment.requiresDisputeReview { Text("Conflicting evidence requires dispute review.").foregroundStyle(.red) }
                ForEach(assessment.blockers,id:\.self){Text($0).font(.caption).foregroundStyle(.secondary)}
                TextField("Promotion reason",text:$reason,axis:.vertical)
                Button("Promote exact assertion") { Task { await promote() } }.disabled(!assessment.eligible || reason.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                if let status { Text(status).font(.caption).foregroundStyle(.secondary) }
            }
        }.navigationTitle("Promotion Review")
    }
    private func promote() async {
        guard assessment.eligible else { status="Promotion remains blocked."; return }
        let disposition:TechnicalTruthDisposition = .verified
        let promoted=TechnicalTruthLedgerEntry(id:truth.id,domain:truth.domain,ownerID:truth.ownerID,ownerTitle:truth.ownerTitle,statement:truth.statement,authoredValue:truth.authoredValue,unit:truth.unit,condition:truth.condition,applicability:reviews.first(where:{$0.decision == .supports})?.applicabilityReviewed ?? truth.applicability,state:target,disposition:disposition,sourceTitle:artifact.description,locator:reviews.first(where:{$0.decision == .supports})?.exactPassageLocator,criticality:truth.criticality,boundary:truth.boundary + " Promoted through the controlled claim-level evidence review gate.")
        let snapshot=PersistedTechnicalTruth(entry:promoted,sourceReference:artifact.locator,reviewReason:reason)
        do { let existing=try await dataRepository.fetchTechnicalTruthRevisions(truthID:truth.id); let revision=TechnicalTruthRevisionEngine.append(snapshot,reason:reason,existing:existing); try await dataRepository.save(technicalTruth:snapshot); try await dataRepository.save(technicalTruthRevision:revision); status="Exact assertion promoted to \(target.rawValue). Neighboring assertions were not changed." } catch { status=error.localizedDescription }
    }
}

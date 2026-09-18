import SwiftUI

struct EvidenceReviewWorkbenchView: View {
    @EnvironmentObject var dataRepository: DataRepository
    @ObservedObject var engine: TechnicalQueryEngine
    @State private var artifacts: [PersistedEvidenceArtifact] = []
    @State private var errorText: String?
    private var truth: [TechnicalTruthLedgerEntry] { TechnicalTruthLedger.compile(engine: engine) }

    var body: some View {
        List {
            Section("Evidence Review Workbench") {
                Text("Acquired artifacts create exact claim-review queues. No artifact or review automatically changes a Technical Truth verification state.").font(.caption).foregroundStyle(.secondary)
                LabeledContent("Persisted artifacts", value: "\(artifacts.count)")
                LabeledContent("Accepted closure screens", value: "\(artifacts.filter(\.closureAccepted).count)")
            }
            if let errorText { Section("Persistence") { Text(errorText).foregroundStyle(.red) } }
            ForEach(artifacts) { artifact in
                Section(artifact.domain.rawValue) {
                    LabeledContent("Artifact", value: artifact.artifact.rawValue)
                    LabeledContent("Closure", value: artifact.closureAccepted ? "Accepted for review" : "Rejected")
                    Text(artifact.description).font(.caption)
                    Text("Locator: \(artifact.locator)").font(.caption2).foregroundStyle(.secondary)
                    if !artifact.forbiddenSubstitutionHits.isEmpty { Text("Forbidden substitution: \(artifact.forbiddenSubstitutionHits.joined(separator: ", "))").font(.caption).foregroundStyle(.red) }
                    ForEach(artifact.eligibleTruthIDs, id: \.self) { truthID in
                        if let entry = truth.first(where: { $0.id == truthID }) {
                            NavigationLink(entry.statement) { EvidenceTruthClaimReviewView(artifact: artifact, entry: entry).environmentObject(dataRepository) }
                        }
                    }
                }
            }
        }
        .navigationTitle("Evidence Review")
        .task { await load() }
    }
    private func load() async { do { artifacts = try await dataRepository.fetchEvidenceArtifacts(); errorText = nil } catch { errorText = error.localizedDescription } }
}

private struct EvidenceTruthClaimReviewView: View {
    @EnvironmentObject var dataRepository: DataRepository
    let artifact: PersistedEvidenceArtifact
    let entry: TechnicalTruthLedgerEntry
    @State private var decision: EvidenceTruthReviewDecision = .needsAnotherSource
    @State private var passage = ""
    @State private var applicability = ""
    @State private var notes = ""
    @State private var reviews: [EvidenceTruthReview] = []
    @State private var status: String?

    var body: some View {
        Form {
            Section("Exact assertion") { Text(entry.statement); Text(entry.boundary).font(.caption).foregroundStyle(.secondary) }
            Section("Artifact") { Text(artifact.description); LabeledContent("Locator", value: artifact.locator); LabeledContent("Applicability", value: artifact.applicability) }
            Section("Claim-level decision") {
                Picker("Decision", selection: $decision) { ForEach(EvidenceTruthReviewDecision.allCases, id: \.rawValue) { Text($0.rawValue).tag($0) } }
                TextField("Exact supporting passage locator", text: $passage)
                TextField("Applicability reviewed", text: $applicability)
                TextField("Notes", text: $notes, axis: .vertical)
                Button("Save immutable review") { Task { await save() } }.disabled(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if let status { Text(status).font(.caption).foregroundStyle(.secondary) }
                Text(EvidenceReviewPromotionGate.boundary).font(.caption2).foregroundStyle(.secondary)
            }
            Section("Review history") { if reviews.isEmpty { Text("No claim-level reviews yet.").foregroundStyle(.secondary) }; ForEach(reviews) { r in VStack(alignment:.leading){ Text(r.decision.rawValue).fontWeight(.semibold); Text(r.notes).font(.caption); Text(r.recordedAt.formatted()).font(.caption2).foregroundStyle(.secondary) } } }
        }.navigationTitle("Evidence Claim Review").task { await load() }
    }
    private func load() async { do { reviews = try await dataRepository.fetchEvidenceTruthReviews(artifactID: artifact.id, truthID: entry.id) } catch { status = error.localizedDescription } }
    private func save() async {
        let review = EvidenceTruthReview(id: UUID(), vehicleID: artifact.vehicleID, artifactID: artifact.id, requestID: artifact.requestID, truthID: entry.id, decision: decision, exactPassageLocator: passage, applicabilityReviewed: applicability, notes: notes, recordedAt: .now)
        do { try await dataRepository.save(evidenceTruthReview: review); reviews = try await dataRepository.fetchEvidenceTruthReviews(artifactID: artifact.id, truthID: entry.id); let gate = EvidenceReviewPromotionGate.assess(review, artifact: artifact, truth: entry); status = gate.eligibleForPromotion ? "Eligible for a separate trust-state promotion review. No promotion was performed." : "Promotion blocked: \(gate.blockers.joined(separator: " "))" } catch { status = error.localizedDescription }
    }
}

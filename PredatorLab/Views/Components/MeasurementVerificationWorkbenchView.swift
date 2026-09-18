import SwiftUI

/// Human-facing review surface for durable expected-measurement trust.
/// Saving a review creates an immutable revision and updates only the exact semantic claim ID.
struct MeasurementVerificationWorkbenchView: View {
    @EnvironmentObject var dataRepository: DataRepository
    @ObservedObject var engine: TechnicalQueryEngine
    @State private var persisted: [PersistedMeasurementClaim] = []
    @State private var revisions: [MeasurementClaimRevision] = []
    @State private var search = ""
    @State private var selected: MeasurementClaimContract?
    @State private var errorMessage: String?

    private var legacy: [MeasurementClaimContract] { engine.circuits.flatMap(MeasurementClaimLedger.fromLegacy) }
    private var resolved: [MeasurementClaimContract] { MeasurementClaimResolutionEngine.resolved(legacy: legacy, persisted: persisted) }
    private var filtered: [MeasurementClaimContract] {
        guard !search.isEmpty else { return resolved }
        return resolved.filter { $0.label.localizedCaseInsensitiveContains(search) || $0.authoredText.localizedCaseInsensitiveContains(search) || $0.id.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        List {
            Section("Trust boundary") {
                Text("A review changes PredatorLab's record of one expected measurement. It does not verify neighboring pins, conductors, procedures, scanner semantics, or causal conclusions.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let errorMessage { Section("Persistence") { Text(errorMessage).foregroundStyle(.secondary) } }
            Section("Claims") {
                ForEach(filtered) { claim in
                    Button { selected = claim } label: {
                        let presentation = MeasurementTrustPresentationEngine.presentation(for: claim)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(claim.label).font(.headline).foregroundStyle(.primary)
                            Text(claim.authoredText).font(.plMono(12)).foregroundStyle(.primary)
                            HStack { Text(presentation.title); Spacer(); Text(claim.state.rawValue) }.font(.caption).foregroundStyle(.secondary)
                        }
                    }.accessibilityIdentifier("measurement.claim.\(claim.id)")
                }
            }
        }
        .searchable(text: $search, prompt: "Measurement, connector, value…")
        .navigationTitle("Measurement Verification")
        .navigationBarTitleDisplayMode(.inline)
        .task { await reload() }
        .sheet(item: $selected) { claim in
            NavigationStack {
                MeasurementClaimReviewView(claim: claim, engine: engine, existingRevisions: revisions.filter { $0.claimID == claim.id }) { updated, reason in
                    await save(updated, reason: reason)
                }
            }
        }
    }

    @MainActor private func reload() async {
        do {
            persisted = try await dataRepository.fetchMeasurementClaims()
            revisions = try await dataRepository.fetchMeasurementClaimRevisions()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            dataRepository.reportPersistenceFailure(domain: "measurementVerificationLoad", error: error)
        }
    }

    @MainActor private func save(_ contract: MeasurementClaimContract, reason: String) async {
        do {
            let record = PersistedMeasurementClaim(contract: contract)
            try await dataRepository.save(measurementClaim: record)
            let revision = MeasurementClaimRevisionEngine.append(contract: contract, vehicleID: nil, reason: reason, existing: revisions)
            try await dataRepository.save(measurementClaimRevision: revision)
            PLStructuredLog.event("measurementClaim.review.saved", fields: ["claimID": contract.id, "state": contract.state.rawValue])
            await reload()
        } catch {
            errorMessage = error.localizedDescription
            dataRepository.reportPersistenceFailure(domain: "measurementVerificationSave", recordID: contract.id, error: error)
        }
    }
}

private struct MeasurementClaimReviewView: View {
    @Environment(\.dismiss) private var dismiss
    let claim: MeasurementClaimContract
    @ObservedObject var engine: TechnicalQueryEngine
    let existingRevisions: [MeasurementClaimRevision]
    let onSave: (MeasurementClaimContract, String) async -> Void

    @State private var applicability: String
    @State private var conditions: String
    @State private var dependencyText: String
    @State private var sourceTitle: String
    @State private var sourceReference: String
    @State private var locator: String
    @State private var state: ClaimVerificationState
    @State private var reason = "Reviewed measurement evidence"
    @State private var selectedAuthorityID = ""

    init(claim: MeasurementClaimContract, engine: TechnicalQueryEngine, existingRevisions: [MeasurementClaimRevision], onSave: @escaping (MeasurementClaimContract, String) async -> Void) {
        self.claim=claim; self.engine=engine; self.existingRevisions=existingRevisions; self.onSave=onSave
        _applicability=State(initialValue: claim.applicability); _conditions=State(initialValue: claim.conditions ?? "")
        _dependencyText=State(initialValue: claim.technicalClaimIDs.joined(separator: ", "))
        _sourceTitle=State(initialValue: claim.source?.title ?? ""); _sourceReference=State(initialValue: claim.source?.reference ?? "")
        _locator=State(initialValue: claim.locator ?? ""); _state=State(initialValue: claim.state)
    }

    private var dependencies: [String] { dependencyText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty } }
    private var source: TechnicalSource? {
        guard !sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return .init(title: sourceTitle, sourceType: "Claim-level verification source", reference: sourceReference, grade: state == .oemVerified ? .a_factory : .b_professional, confidence: state == .oemVerified || state == .manufacturerVerified ? .c4 : .c2, url: nil, accessMethod: nil, notes: "Attached in Measurement Verification Workbench")
    }
    private var updated: MeasurementClaimContract {
        .init(id: claim.id, ownerID: claim.ownerID, ownerKind: claim.ownerKind, label: claim.label, authoredText: claim.authoredText, typedValue: claim.typedValue, conditions: conditions.isEmpty ? nil : conditions, applicability: applicability, technicalClaimIDs: dependencies, state: state, source: source, locator: locator.isEmpty ? nil : locator, evidenceBoundary: claim.evidenceBoundary)
    }

    var body: some View {
        Form {
            Section("Claim") { Text(claim.label); Text(claim.authoredText).font(.plMono(12)); Text(claim.id).font(.caption2).textSelection(.enabled) }
            Section("Scope") { TextField("Applicability", text: $applicability, axis: .vertical); TextField("Measurement conditions", text: $conditions, axis: .vertical) }
            Section("Registry authority") {
                let options = MeasurementVerificationAuthority.options(engine: engine)
                Picker("Verified claim/source", selection: $selectedAuthorityID) {
                    Text("No registry selection").tag("")
                    ForEach(options) { option in Text(option.claim.statement).tag(option.id) }
                }
                Button("Apply Selected Authority") {
                    guard let option = options.first(where: { $0.id == selectedAuthorityID }) else { return }
                    let applied = MeasurementVerificationAuthority.applying(option, to: updated)
                    applicability = applied.applicability
                    dependencyText = applied.technicalClaimIDs.joined(separator: ", ")
                    sourceTitle = applied.source?.title ?? ""
                    sourceReference = applied.source?.reference ?? ""
                    locator = applied.locator ?? ""
                    state = applied.state
                    reason = "Applied central registry authority: \(option.id)"
                }.disabled(selectedAuthorityID.isEmpty)
                Text("Registry selection copies the exact claim, source, locator and applicability boundary. It does not verify adjacent circuit content.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Dependencies") { TextField("Technical claim IDs, comma separated", text: $dependencyText, axis: .vertical) }
            Section("Source") {
                LabeledContent("Title", value: sourceTitle.isEmpty ? "Not selected" : sourceTitle)
                LabeledContent("Reference", value: sourceReference.isEmpty ? "Not selected" : sourceReference)
                LabeledContent("Locator", value: locator.isEmpty ? "Not selected" : locator)
                Text("Source metadata is populated from the central registry. Add or correct authority in the Technical Claim/Source registry rather than typing an ad-hoc source here.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Verification state") { Picker("State", selection: $state) { ForEach(ClaimVerificationState.allCases, id: \.self) { Text($0.rawValue).tag($0) } } }
            Section("Admission") {
                let presentation = MeasurementTrustPresentationEngine.presentation(for: updated)
                LabeledContent("Strong-diagnosis admission", value: updated.isAdmittedForStrongDiagnosis ? "Admitted" : "Blocked")
                Text(presentation.detail).font(.caption).foregroundStyle(.secondary)
            }
            Section("Revision history") {
                if existingRevisions.isEmpty { Text("No durable revisions yet.").foregroundStyle(.secondary) }
                ForEach(existingRevisions.sorted { $0.revisionNumber > $1.revisionNumber }) { revision in
                    VStack(alignment: .leading) { Text("Revision \(revision.revisionNumber) · \(revision.contract.state.rawValue)"); Text(revision.reason).font(.caption).foregroundStyle(.secondary); Text(revision.recordedAt.formatted()).font(.caption2).foregroundStyle(.secondary) }
                }
            }
            Section("Lifecycle") {
                Button("Dispute This Claim", role: .destructive) {
                    let disputed = MeasurementClaimLifecycleEngine.applying(.dispute, to: updated, reason: reason)
                    Task { await onSave(disputed, reason.isEmpty ? "Claim disputed" : reason); dismiss() }
                }
                Button("Supersede This Claim") {
                    let superseded = MeasurementClaimLifecycleEngine.applying(.supersede, to: updated, reason: reason)
                    Task { await onSave(superseded, reason.isEmpty ? "Claim superseded" : reason); dismiss() }
                }
                Text("Disputed and superseded claims are blocked from strong diagnostic admission and retain their immutable revision history.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Review note") { TextField("Why this revision was made", text: $reason, axis: .vertical) }
        }
        .navigationTitle("Review Measurement")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save Revision") { Task { await onSave(updated, reason); dismiss() } }.accessibilityIdentifier("measurement.claim.saveRevision") } }
    }
}

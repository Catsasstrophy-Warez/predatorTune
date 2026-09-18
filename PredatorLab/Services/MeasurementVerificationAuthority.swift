import Foundation

/// Central authority for choosing a claim dependency and its source. The workbench never invents
/// a source from free-form text when a registry claim is selected.
struct MeasurementVerificationAuthorityOption: Identifiable {
    let id: String
    let claim: TechnicalClaim
    var display: String { claim.source.map { "\(claim.statement) — \($0.title)" } ?? claim.statement }
}

enum MeasurementVerificationAuthority {
    static func options(engine: TechnicalQueryEngine) -> [MeasurementVerificationAuthorityOption] {
        TechnicalClaimRegistry.build(from: engine).claims
            .filter { $0.source != nil && $0.locator?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
            .map { .init(id: $0.id, claim: $0) }
            .sorted { $0.claim.statement.localizedCaseInsensitiveCompare($1.claim.statement) == .orderedAscending }
    }

    static func applying(_ option: MeasurementVerificationAuthorityOption, to measurement: MeasurementClaimContract) -> MeasurementClaimContract {
        let claim = option.claim
        return .init(id: measurement.id, ownerID: measurement.ownerID, ownerKind: measurement.ownerKind,
                     label: measurement.label, authoredText: measurement.authoredText, typedValue: measurement.typedValue,
                     conditions: measurement.conditions, applicability: claim.applicability,
                     technicalClaimIDs: [claim.id], state: claim.state, source: claim.source,
                     locator: claim.locator,
                     evidenceBoundary: "Claim-level authority selected from the central Technical Claim Registry. This verifies only the exact selected claim and stated applicability; neighboring measurements/topology remain independent.")
    }
}

enum MeasurementClaimLifecycleAction: String, Codable, CaseIterable { case dispute, supersede }

enum MeasurementClaimLifecycleEngine {
    static func applying(_ action: MeasurementClaimLifecycleAction, to claim: MeasurementClaimContract, reason: String) -> MeasurementClaimContract {
        let state: ClaimVerificationState = action == .dispute ? .disputed : .superseded
        return .init(id: claim.id, ownerID: claim.ownerID, ownerKind: claim.ownerKind, label: claim.label,
                     authoredText: claim.authoredText, typedValue: claim.typedValue, conditions: claim.conditions,
                     applicability: claim.applicability, technicalClaimIDs: claim.technicalClaimIDs, state: state,
                     source: claim.source, locator: claim.locator,
                     evidenceBoundary: "\(claim.evidenceBoundary) Lifecycle action: \(action.rawValue). Reason: \(reason). A disputed or superseded claim is blocked from strong diagnosis.")
    }
}

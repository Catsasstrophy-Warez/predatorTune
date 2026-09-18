import Foundation

/// Durable override/verification record for one expected measurement claim.
/// `claimID` remains the stable semantic identity; the UUID is only the persistence identity.
struct PersistedMeasurementClaim: Identifiable, Codable, Equatable {
    let id: UUID
    let vehicleID: UUID?
    let claimID: String
    let ownerID: String
    let ownerKind: String
    let label: String
    let authoredText: String
    let typedValue: EngineeringValue?
    let conditions: String?
    let applicability: String
    let technicalClaimIDs: [String]
    let state: ClaimVerificationState
    let source: TechnicalSource?
    let locator: String?
    let evidenceBoundary: String
    let updatedAt: Date

    init(id: UUID = UUID(), vehicleID: UUID? = nil, contract: MeasurementClaimContract, updatedAt: Date = Date()) {
        self.id=id; self.vehicleID=vehicleID; self.claimID=contract.id; self.ownerID=contract.ownerID; self.ownerKind=contract.ownerKind
        self.label=contract.label; self.authoredText=contract.authoredText; self.typedValue=contract.typedValue; self.conditions=contract.conditions
        self.applicability=contract.applicability; self.technicalClaimIDs=contract.technicalClaimIDs; self.state=contract.state
        self.source=contract.source; self.locator=contract.locator; self.evidenceBoundary=contract.evidenceBoundary; self.updatedAt=updatedAt
    }

    var contract: MeasurementClaimContract { .init(id: claimID, ownerID: ownerID, ownerKind: ownerKind, label: label, authoredText: authoredText, typedValue: typedValue, conditions: conditions, applicability: applicability, technicalClaimIDs: technicalClaimIDs, state: state, source: source, locator: locator, evidenceBoundary: evidenceBoundary) }
}

enum MeasurementClaimResolutionEngine {
    /// Durable records override legacy-derived contracts only when semantic claim IDs match.
    static func resolved(legacy: [MeasurementClaimContract], persisted: [PersistedMeasurementClaim]) -> [MeasurementClaimContract] {
        let newest = Dictionary(grouping: persisted, by: \.claimID).compactMapValues { $0.max { $0.updatedAt < $1.updatedAt } }
        return legacy.map { newest[$0.id]?.contract ?? $0 }
    }
}

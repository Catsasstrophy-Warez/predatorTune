import Foundation

/// Immutable audit snapshot for one semantic expected-measurement claim.
/// A revision records what PredatorLab believed at a point in time; it does not itself upgrade trust.
struct MeasurementClaimRevision: Identifiable, Codable, Equatable {
    let id: UUID
    let vehicleID: UUID?
    let claimID: String
    let revisionNumber: Int
    let recordedAt: Date
    let contract: MeasurementClaimContract
    let reason: String

    init(id: UUID = UUID(), vehicleID: UUID? = nil, claimID: String, revisionNumber: Int, recordedAt: Date = .now, contract: MeasurementClaimContract, reason: String) {
        self.id = id; self.vehicleID = vehicleID; self.claimID = claimID; self.revisionNumber = revisionNumber
        self.recordedAt = recordedAt; self.contract = contract; self.reason = reason
    }
}

enum MeasurementClaimRevisionEngine {
    static func nextRevision(for claimID: String, existing: [MeasurementClaimRevision]) -> Int {
        (existing.filter { $0.claimID == claimID }.map(\.revisionNumber).max() ?? 0) + 1
    }

    static func append(contract: MeasurementClaimContract, vehicleID: UUID?, reason: String, existing: [MeasurementClaimRevision]) -> MeasurementClaimRevision {
        .init(vehicleID: vehicleID, claimID: contract.id, revisionNumber: nextRevision(for: contract.id, existing: existing), contract: contract, reason: reason)
    }

    static func audit(_ revisions: [MeasurementClaimRevision]) -> [String] {
        var issues: [String] = []
        for group in Dictionary(grouping: revisions, by: \.claimID).values {
            let numbers = group.map(\.revisionNumber)
            if Set(numbers).count != numbers.count { issues.append("Duplicate measurement-claim revision number detected.") }
            if numbers.contains(where: { $0 < 1 }) { issues.append("Measurement-claim revision numbers must begin at 1.") }
        }
        return issues
    }
}

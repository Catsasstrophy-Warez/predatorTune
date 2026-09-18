import Foundation

/// Durable review state for any individual assertion in the Technical Truth Ledger.
/// `truthID` is the stable semantic identity; `id` is persistence identity only.
struct PersistedTechnicalTruth: Identifiable, Codable, Equatable {
    let id: UUID
    let vehicleID: UUID?
    let truthID: String
    let domain: TechnicalTruthDomain
    let ownerID: String
    let statement: String
    let applicability: String
    let state: ClaimVerificationState
    let disposition: TechnicalTruthDisposition
    let sourceTitle: String?
    let sourceReference: String?
    let locator: String?
    let reviewReason: String
    let updatedAt: Date

    init(id: UUID = UUID(), vehicleID: UUID? = nil, entry: TechnicalTruthLedgerEntry, sourceReference: String? = nil, reviewReason: String, updatedAt: Date = .now) {
        self.id=id; self.vehicleID=vehicleID; self.truthID=entry.id; self.domain=entry.domain; self.ownerID=entry.ownerID
        self.statement=entry.statement; self.applicability=entry.applicability; self.state=entry.state; self.disposition=entry.disposition
        self.sourceTitle=entry.sourceTitle; self.sourceReference=sourceReference; self.locator=entry.locator
        self.reviewReason=reviewReason; self.updatedAt=updatedAt
    }
}

struct TechnicalTruthRevision: Identifiable, Codable, Equatable {
    let id: UUID
    let vehicleID: UUID?
    let truthID: String
    let revisionNumber: Int
    let recordedAt: Date
    let snapshot: PersistedTechnicalTruth
    let reason: String
}

enum TechnicalTruthRevisionEngine {
    static func nextRevision(for truthID: String, existing: [TechnicalTruthRevision]) -> Int {
        (existing.filter{$0.truthID == truthID}.map(\.revisionNumber).max() ?? 0) + 1
    }
    static func append(_ snapshot: PersistedTechnicalTruth, reason: String, existing: [TechnicalTruthRevision]) -> TechnicalTruthRevision {
        .init(id: UUID(), vehicleID: snapshot.vehicleID, truthID: snapshot.truthID,
              revisionNumber: nextRevision(for: snapshot.truthID, existing: existing), recordedAt: .now,
              snapshot: snapshot, reason: reason)
    }
    static func audit(_ revisions: [TechnicalTruthRevision]) -> [String] {
        Dictionary(grouping: revisions, by: \.truthID).values.flatMap { group -> [String] in
            let n=group.map(\.revisionNumber); var issues:[String]=[]
            if Set(n).count != n.count { issues.append("Duplicate technical-truth revision number detected.") }
            if n.contains(where:{$0 < 1}) { issues.append("Technical-truth revisions must begin at 1.") }
            return issues
        }
    }
}

enum TechnicalTruthResolutionEngine {
    /// Durable review state can alter only the exact semantic truth entry. It never propagates to siblings.
    static func resolved(base: [TechnicalTruthLedgerEntry], persisted: [PersistedTechnicalTruth]) -> [TechnicalTruthLedgerEntry] {
        let newest=Dictionary(grouping:persisted, by:\.truthID).compactMapValues{$0.max{$0.updatedAt < $1.updatedAt}}
        return base.map { entry in
            guard let p=newest[entry.id] else { return entry }
            return .init(id:entry.id, domain:entry.domain, ownerID:entry.ownerID, ownerTitle:entry.ownerTitle,
                         statement:entry.statement, authoredValue:entry.authoredValue, unit:entry.unit, condition:entry.condition,
                         applicability:p.applicability, state:p.state, disposition:p.disposition,
                         sourceTitle:p.sourceTitle, locator:p.locator, criticality:entry.criticality,
                         boundary:entry.boundary + " Durable review applies only to semantic truth ID \(entry.id).")
        }
    }
}

import Foundation

enum ArchiveConflictDisposition: String, Codable, Equatable {
    case newRecord
    case identicalEvidence
    case existingRecord
    case evidenceIdentityConflict
}

struct ArchiveConflictItem: Identifiable, Codable, Equatable {
    let id: String
    let kind: String
    let recordID: UUID
    let title: String
    let disposition: ArchiveConflictDisposition
    let detail: String
    let blocksReplacement: Bool
}

struct ArchiveImportPlan: Codable, Equatable {
    let vehicleID: UUID
    let policy: ArchiveMergePolicy
    let items: [ArchiveConflictItem]
    let evidenceBytes: UInt64
    let hashesVerified: Int
    let warnings: [String]
    var blockers: [ArchiveConflictItem] { items.filter(\.blocksReplacement) }
    var canCommit: Bool { blockers.isEmpty }
    var newRecords: Int { items.filter { $0.disposition == .newRecord }.count }
    var preservedRecords: Int { items.filter { $0.disposition == .existingRecord || $0.disposition == .identicalEvidence }.count }
}

enum ArchiveImportPlanner {
    static func logDisposition(incoming: StreamingEvidenceArchive.LogManifest, existing: ImportedLog?) -> ArchiveConflictDisposition {
        guard let existing else { return .newRecord }
        if let a = incoming.declaredSHA256, let b = existing.sourceSHA256 {
            return a == b ? .identicalEvidence : .evidenceIdentityConflict
        }
        return .existingRecord
    }

    static func item(kind: String, id: UUID, title: String, exists: Bool) -> ArchiveConflictItem {
        .init(id: "\(kind):\(id.uuidString)", kind: kind, recordID: id, title: title,
              disposition: exists ? .existingRecord : .newRecord,
              detail: exists ? "A record with this identity already exists locally." : "New record.",
              blocksReplacement: false)
    }

    static func logItem(_ incoming: StreamingEvidenceArchive.LogManifest, existing: ImportedLog?, policy: ArchiveMergePolicy) -> ArchiveConflictItem {
        let disposition = logDisposition(incoming: incoming, existing: existing)
        let conflict = disposition == .evidenceIdentityConflict
        let detail: String
        switch disposition {
        case .newRecord: detail = "New evidence member."
        case .identicalEvidence: detail = "Same evidence identity and SHA-256; source bytes are not a conflicting identity."
        case .existingRecord: detail = "Same evidence UUID exists, but one or both source hashes are unavailable. Preserve unless explicitly reconciled."
        case .evidenceIdentityConflict: detail = "Same evidence UUID has a different SHA-256. PredatorLab will not silently replace one immutable source identity with another."
        }
        return .init(id:"log:\(incoming.metadata.id.uuidString)",kind:"log",recordID:incoming.metadata.id,title:incoming.originalFilename,disposition:disposition,detail:detail,blocksReplacement: conflict && policy == .replaceMatching)
    }
}

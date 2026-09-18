import Foundation

struct ArchiveSafetyReport: Equatable {
    var accepted: Bool
    var declaredEvidenceBytes: UInt64
    var warnings: [String]
}

enum ArchiveSafetyValidator {
    static let maximumManifestBytes: UInt64 = 100 * 1024 * 1024
    static let maximumEvidenceMemberBytes: UInt64 = 20 * 1024 * 1024 * 1024
    static let maximumTotalEvidenceBytes: UInt64 = 100 * 1024 * 1024 * 1024
    static let maximumLogCount = 10_000

    static func validate(_ manifest: StreamingEvidenceArchive.Manifest) throws -> ArchiveSafetyReport {
        guard manifest.format == PredatorLabEvidenceArchive.formatIdentifier else { throw EvidenceArchiveError.unsupportedFormat }
        guard (2...9).contains(manifest.schemaVersion) else { throw EvidenceArchiveError.unsupportedSchema(manifest.schemaVersion) }
        guard manifest.logs.count <= maximumLogCount else { throw EvidenceArchiveError.unsupportedFormat }
        var seen=Set<UUID>(), total:UInt64=0, warnings:[String]=[]
        for item in manifest.logs {
            guard seen.insert(item.metadata.id).inserted else { throw EvidenceArchiveError.unsupportedFormat }
            guard item.byteCount <= maximumEvidenceMemberBytes else { throw EvidenceArchiveError.unsupportedFormat }
            let (sum, overflow)=total.addingReportingOverflow(item.byteCount); guard !overflow, sum <= maximumTotalEvidenceBytes else { throw EvidenceArchiveError.unsupportedFormat }; total=sum
            if item.byteCount > 0 && item.declaredSHA256 == nil { warnings.append("Evidence member \(item.originalFilename) has no declared SHA-256 and cannot receive hash-verified status.") }
        }
        for item in manifest.attachments ?? [] {
            guard seen.insert(item.metadata.id).inserted else { throw EvidenceArchiveError.unsupportedFormat }
            guard item.byteCount <= maximumEvidenceMemberBytes else { throw EvidenceArchiveError.unsupportedFormat }
            let (sum, overflow)=total.addingReportingOverflow(item.byteCount); guard !overflow, sum <= maximumTotalEvidenceBytes else { throw EvidenceArchiveError.unsupportedFormat }; total=sum
            if item.byteCount > 0 && item.declaredSHA256.isEmpty { warnings.append("Attachment \(item.metadata.filename) has no declared SHA-256.") }
        }
        return .init(accepted:true,declaredEvidenceBytes:total,warnings:warnings)
    }
}

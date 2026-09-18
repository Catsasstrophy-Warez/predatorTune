import Foundation

/// Single-file, portable PredatorLab evidence package. Original CSV bytes are embedded unchanged.
/// Derived caches are intentionally excluded because they can be regenerated from source evidence.
struct PredatorLabEvidenceArchive: Codable {
    let format: String
    let schemaVersion: Int
    let exportedAt: Date
    let appAnalysisVersion: AnalysisEngineVersion
    let vehicle: GT500Vehicle?
    let sessions: [Session]
    let investigations: [Investigation]
    let serviceRecords: [ServiceRecord]
    let validationReports: [PersistedValidationReport]
    let logs: [ArchivedLog]

    static let currentSchema = 1
    static let formatIdentifier = "com.predatorlab.evidence-archive"
}

struct ArchivedLog: Codable {
    var metadata: ImportedLog
    var originalFilename: String
    var originalBytes: Data?
    var declaredSHA256: String?
}

enum ArchiveMergePolicy: String, Codable, CaseIterable { case preserveExisting, replaceMatching }

struct ArchiveImportReport: Codable, Equatable {
    var vehicleID: UUID?
    var sessionsImported: Int
    var investigationsImported: Int
    var serviceRecordsImported: Int
    var logsImported: Int
    var validationReportsImported: Int
    var hashesVerified: Int
    var logsMissingSourceBytes: Int
    var analysesNeedingReanalysis: Int
    var recordsSkippedAsExisting: Int
    var warnings: [String]
}

enum EvidenceArchiveError: LocalizedError {
    case unsupportedFormat
    case unsupportedSchema(Int)
    case hashMismatch(String)
    case missingVehicle
    case identityConflict(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat: return "This file is not a PredatorLab evidence archive."
        case .unsupportedSchema(let version): return "PredatorLab archive schema \(version) is not supported by this build."
        case .hashMismatch(let filename): return "Evidence integrity verification failed for \(filename). The imported bytes do not match the archive manifest."
        case .missingVehicle: return "The archive does not contain a vehicle record."
        case .identityConflict(let name): return "Evidence identity conflict for \(name). The same evidence UUID refers to different source bytes; import was stopped before commit."
        }
    }
}

enum AnalysisVersionPolicy {
    static func needsReanalysis(_ old: AnalysisEngineVersion?) -> Bool {
        guard let old else { return true }
        return old != .current
    }
}

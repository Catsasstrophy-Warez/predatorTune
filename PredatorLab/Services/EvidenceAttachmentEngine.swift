import Foundation

struct EvidenceAttachment: Identifiable, Codable, Equatable {
    let id: UUID
    var vehicleID: UUID
    var logID: UUID?
    var sessionID: UUID?
    var filename: String
    var mediaType: String
    var sourceSHA256: String
    var byteCount: Int64
    var note: String?
    var createdAt: Date
    var evidenceBoundary: String
}

enum EvidenceAttachmentEngine {
    static func metadata(vehicleID: UUID, logID: UUID? = nil, sessionID: UUID? = nil, filename: String, mediaType: String, sha256: String, byteCount: Int64, note: String? = nil) -> EvidenceAttachment? {
        let clean = filename.trimmingCharacters(in: .whitespacesAndNewlines)
        let hash = sha256.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty, byteCount >= 0, hash.count == 64, hash.allSatisfy({ $0.isHexDigit }) else { return nil }
        return .init(id: UUID(), vehicleID: vehicleID, logID: logID, sessionID: sessionID, filename: clean, mediaType: mediaType, sourceSHA256: hash, byteCount: byteCount, note: note, createdAt: .now, evidenceBoundary: "Attachment is preserved supporting evidence. Its presence does not independently verify the technical interpretation attached to it.")
    }
}

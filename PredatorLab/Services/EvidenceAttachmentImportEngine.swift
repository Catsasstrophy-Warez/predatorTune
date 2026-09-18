import Foundation

/// Builds integrity-bound attachment metadata from a user-selected file before durable admission.
enum EvidenceAttachmentImportError: Error, LocalizedError {
    case unreadableSize
    case hashUnavailable
    case unsupportedFilename

    var errorDescription: String? {
        switch self {
        case .unreadableSize: return "The selected evidence file size could not be read."
        case .hashUnavailable: return "SHA-256 verification is unavailable for the selected evidence file."
        case .unsupportedFilename: return "The selected evidence file must have a safe file extension."
        }
    }
}

enum EvidenceAttachmentImportEngine {
    static func mediaType(for filename: String) -> String {
        switch URL(fileURLWithPath: filename).pathExtension.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "heic", "heif": return "image/heic"
        case "pdf": return "application/pdf"
        case "csv": return "text/csv"
        case "txt": return "text/plain"
        case "json": return "application/json"
        default: return "application/octet-stream"
        }
    }

    static func makeMetadata(sourceURL: URL, vehicleID: UUID, logID: UUID?, sessionID: UUID? = nil, note: String? = nil) throws -> EvidenceAttachment {
        guard EvidenceAttachmentStore.safeExtension(for: sourceURL.lastPathComponent) != nil else { throw EvidenceAttachmentImportError.unsupportedFilename }
        let attrs = try FileManager.default.attributesOfItem(atPath: sourceURL.path)
        guard let number = attrs[.size] as? NSNumber else { throw EvidenceAttachmentImportError.unreadableSize }
        guard let hash = try EvidenceIntegrity.sha256(of: sourceURL) else { throw EvidenceAttachmentImportError.hashUnavailable }
        guard let metadata = EvidenceAttachmentEngine.metadata(vehicleID: vehicleID, logID: logID, sessionID: sessionID, filename: sourceURL.lastPathComponent, mediaType: mediaType(for: sourceURL.lastPathComponent), sha256: hash, byteCount: number.int64Value, note: note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank) else {
            throw EvidenceAttachmentImportError.unreadableSize
        }
        return metadata
    }
}

private extension String { var nilIfBlank: String? { isEmpty ? nil : self } }

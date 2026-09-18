import Foundation

/// Durable byte store for supporting evidence. Metadata remains in the entity store while
/// original bytes live in Application Support and are verified before admission.
enum EvidenceAttachmentStoreError: Error, LocalizedError {
    case hashUnavailable
    case hashMismatch
    case byteCountMismatch
    case unsafeFilename

    var errorDescription: String? {
        switch self {
        case .hashUnavailable: return "SHA-256 verification is unavailable on this platform."
        case .hashMismatch: return "Attachment SHA-256 does not match the supplied evidence metadata."
        case .byteCountMismatch: return "Attachment byte count does not match the supplied evidence metadata."
        case .unsafeFilename: return "Attachment filename is not safe for durable storage."
        }
    }
}

enum EvidenceAttachmentStore {
    static func safeExtension(for filename: String) -> String? {
        let ext = URL(fileURLWithPath: filename).pathExtension.lowercased()
        guard !ext.isEmpty, ext.count <= 12, ext.allSatisfy({ $0.isLetter || $0.isNumber }) else { return nil }
        return ext
    }

    static func destination(for attachment: EvidenceAttachment, root: URL) throws -> URL {
        guard let ext = safeExtension(for: attachment.filename) else { throw EvidenceAttachmentStoreError.unsafeFilename }
        return root.appendingPathComponent(attachment.vehicleID.uuidString, isDirectory: true)
            .appendingPathComponent("\(attachment.id.uuidString).\(ext)")
    }

    static func verify(sourceURL: URL, metadata: EvidenceAttachment) throws {
        let attrs = try FileManager.default.attributesOfItem(atPath: sourceURL.path)
        let bytes = (attrs[.size] as? NSNumber)?.int64Value ?? -1
        guard bytes == metadata.byteCount else { throw EvidenceAttachmentStoreError.byteCountMismatch }
        guard let hash = try EvidenceIntegrity.sha256(of: sourceURL) else { throw EvidenceAttachmentStoreError.hashUnavailable }
        guard hash.lowercased() == metadata.sourceSHA256.lowercased() else { throw EvidenceAttachmentStoreError.hashMismatch }
    }

    static func remove(_ metadata: EvidenceAttachment, root: URL) throws {
        let url = try destination(for: metadata, root: root)
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }

    static func persist(sourceURL: URL, metadata: EvidenceAttachment, root: URL) throws -> URL {
        try verify(sourceURL: sourceURL, metadata: metadata)
        let destination = try destination(for: metadata, root: root)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        let temporary = destination.appendingPathExtension("incoming")
        if FileManager.default.fileExists(atPath: temporary.path) { try FileManager.default.removeItem(at: temporary) }
        try FileManager.default.copyItem(at: sourceURL, to: temporary)
        if FileManager.default.fileExists(atPath: destination.path) { try FileManager.default.removeItem(at: destination) }
        try FileManager.default.moveItem(at: temporary, to: destination)
        return destination
    }
}

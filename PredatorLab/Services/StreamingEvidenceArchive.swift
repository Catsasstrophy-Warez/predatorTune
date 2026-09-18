import Foundation

/// Rev17 multi-file binary container. Metadata is JSON, but source CSV evidence is streamed as raw bytes.
/// This avoids JSON/base64 amplification and preserves exact source bytes.
enum StreamingEvidenceArchive {
    static let magic = Data("PREDATORLAB17\n".utf8)

    struct LogManifest: Codable {
        var metadata: ImportedLog
        var originalFilename: String
        var declaredSHA256: String?
        var byteCount: UInt64
    }
    struct AttachmentManifest: Codable {
        var metadata: EvidenceAttachment
        var declaredSHA256: String
        var byteCount: UInt64
    }
    struct Manifest: Codable {
        var format: String
        var schemaVersion: Int
        var exportedAt: Date
        var appAnalysisVersion: AnalysisEngineVersion
        var vehicle: GT500Vehicle?
        var sessions: [Session]
        var investigations: [Investigation]
        var serviceRecords: [ServiceRecord]
        var validationReports: [PersistedValidationReport]
        var logs: [LogManifest]
        var attachments: [AttachmentManifest]? = nil
        var postJobRCAs: [PostJobRCA]? = nil
        var rcaAttachmentLinks: [RCAAttachmentLink]? = nil
        var measurementClaims: [PersistedMeasurementClaim]? = nil
        var measurementClaimRevisions: [MeasurementClaimRevision]? = nil
        var technicalTruth: [PersistedTechnicalTruth]? = nil
        var technicalTruthRevisions: [TechnicalTruthRevision]? = nil
        var evidenceArtifacts: [PersistedEvidenceArtifact]? = nil
        var evidenceTruthReviews: [EvidenceTruthReview]? = nil
        var tuneMetadataV8: TuneArchiveMetadataV8? = nil
        var tuneMetadataV9: TuneArchiveMetadataV9Rev83? = nil
    }

    static func isStreamingContainer(_ url: URL) -> Bool {
        guard let h = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? h.close() }
        return (try? h.read(upToCount: magic.count)) == magic
    }

    static func write(manifest: Manifest, sourceURLs: [UUID: URL], to url: URL) throws {
        _ = try ArchiveSafetyValidator.validate(manifest)
        FileManager.default.createFile(atPath: url.path, contents: nil)
        let out = try FileHandle(forWritingTo: url); defer { try? out.close() }
        try out.write(contentsOf: magic)
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601; encoder.outputFormatting = [.sortedKeys]
        let manifestData = try encoder.encode(manifest)
        try writeUInt64(UInt64(manifestData.count), to: out); try out.write(contentsOf: manifestData)
        for item in manifest.logs {
            let nameData = Data(item.metadata.id.uuidString.utf8)
            try writeUInt64(UInt64(nameData.count), to: out); try out.write(contentsOf: nameData)
            guard item.byteCount > 0, let source = sourceURLs[item.metadata.id] else { try writeUInt64(0, to: out); continue }
            try writeUInt64(item.byteCount, to: out)
            let input = try FileHandle(forReadingFrom: source); defer { try? input.close() }
            while let chunk = try input.read(upToCount: 1024 * 1024), !chunk.isEmpty { try out.write(contentsOf: chunk) }
        }
        if manifest.schemaVersion >= 3 {
            for item in manifest.attachments ?? [] {
                let nameData = Data(item.metadata.id.uuidString.utf8)
                try writeUInt64(UInt64(nameData.count), to: out); try out.write(contentsOf: nameData)
                guard item.byteCount > 0, let source = sourceURLs[item.metadata.id] else { try writeUInt64(0, to: out); continue }
                try writeUInt64(item.byteCount, to: out)
                let input = try FileHandle(forReadingFrom: source); defer { try? input.close() }
                while let chunk = try input.read(upToCount: 1024 * 1024), !chunk.isEmpty { try out.write(contentsOf: chunk) }
            }
        }
    }

    /// Reads metadata and streams each evidence member to a temporary file. No archive-wide base64/Data expansion occurs.
    static func read(_ url: URL) throws -> (Manifest, [UUID: URL]) {
        let input = try FileHandle(forReadingFrom: url); defer { try? input.close() }
        guard try input.read(upToCount: magic.count) == magic else { throw EvidenceArchiveError.unsupportedFormat }
        let manifestLength = try readUInt64(from: input)
        guard manifestLength < 100 * 1024 * 1024, let data = try input.read(upToCount: Int(manifestLength)), data.count == Int(manifestLength) else { throw EvidenceArchiveError.unsupportedFormat }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(Manifest.self, from: data)
        _ = try ArchiveSafetyValidator.validate(manifest)
        var files: [UUID: URL] = [:]
        for _ in manifest.logs {
            let nameLength = try readUInt64(from: input)
            guard nameLength < 4096, let nameData = try input.read(upToCount: Int(nameLength)), let id = UUID(uuidString: String(decoding: nameData, as: UTF8.self)) else { throw EvidenceArchiveError.unsupportedFormat }
            let byteCount = try readUInt64(from: input)
            guard byteCount > 0 else { continue }
            let temp = FileManager.default.temporaryDirectory.appendingPathComponent("PredatorLab-").appendingPathComponent(id.uuidString).appendingPathExtension("csv")
            try? FileManager.default.createDirectory(at: temp.deletingLastPathComponent(), withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: temp.path, contents: nil)
            let out = try FileHandle(forWritingTo: temp); defer { try? out.close() }
            var remaining = byteCount
            while remaining > 0 {
                let count = Int(min(remaining, 1024 * 1024))
                guard let chunk = try input.read(upToCount: count), !chunk.isEmpty else { throw EvidenceArchiveError.unsupportedFormat }
                try out.write(contentsOf: chunk); remaining -= UInt64(chunk.count)
            }
            files[id] = temp
        }
        if manifest.schemaVersion >= 3 {
            for item in manifest.attachments ?? [] {
                let nameLength = try readUInt64(from: input)
                guard nameLength < 4096, let nameData = try input.read(upToCount: Int(nameLength)), let id = UUID(uuidString: String(decoding: nameData, as: UTF8.self)), id == item.metadata.id else { throw EvidenceArchiveError.unsupportedFormat }
                let byteCount = try readUInt64(from: input)
                guard byteCount == item.byteCount, byteCount > 0 else { if byteCount == 0 { continue }; throw EvidenceArchiveError.unsupportedFormat }
                let ext = EvidenceAttachmentStore.safeExtension(for: item.metadata.filename) ?? "bin"
                let temp = FileManager.default.temporaryDirectory.appendingPathComponent("PredatorLab-Attachment-").appendingPathComponent(id.uuidString).appendingPathExtension(ext)
                try? FileManager.default.createDirectory(at: temp.deletingLastPathComponent(), withIntermediateDirectories: true)
                FileManager.default.createFile(atPath: temp.path, contents: nil)
                let out = try FileHandle(forWritingTo: temp); defer { try? out.close() }
                var remaining = byteCount
                while remaining > 0 {
                    let count = Int(min(remaining, 1024 * 1024))
                    guard let chunk = try input.read(upToCount: count), !chunk.isEmpty else { throw EvidenceArchiveError.unsupportedFormat }
                    try out.write(contentsOf: chunk); remaining -= UInt64(chunk.count)
                }
                files[id] = temp
            }
        }
        return (manifest, files)
    }

    private static func writeUInt64(_ value: UInt64, to handle: FileHandle) throws {
        var v = value.littleEndian; try withUnsafeBytes(of: &v) { try handle.write(contentsOf: Data($0)) }
    }
    private static func readUInt64(from handle: FileHandle) throws -> UInt64 {
        guard let data = try handle.read(upToCount: 8), data.count == 8 else { throw EvidenceArchiveError.unsupportedFormat }
        return data.withUnsafeBytes { $0.loadUnaligned(as: UInt64.self) }.littleEndian
    }
}

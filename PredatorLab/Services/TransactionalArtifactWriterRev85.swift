import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

/// Writes evidence/archive artifacts through a dedicated staging directory and atomically promotes them.
/// Source-tree scratch files are never used as persistence staging.
enum TransactionalArtifactWriterRev85 {
    enum WriterError: Error { case unsafeTarget, verificationFailed }

    static func write(_ data: Data, to targetURL: URL, verify: ((URL) throws -> Bool)? = nil) throws {
        guard targetURL.isFileURL else { throw WriterError.unsafeTarget }
        let fm = FileManager.default
        let directory = targetURL.deletingLastPathComponent()
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        let staging = directory.appendingPathComponent(".predatorlab-staging", isDirectory: true)
        try fm.createDirectory(at: staging, withIntermediateDirectories: true)
        let temporary = staging.appendingPathComponent(UUID().uuidString + ".tmp")
        defer { try? fm.removeItem(at: temporary) }
        try data.write(to: temporary, options: [.atomic])
        if let verify, try !verify(temporary) { throw WriterError.verificationFailed }
        if fm.fileExists(atPath: targetURL.path) {
            _ = try fm.replaceItemAt(targetURL, withItemAt: temporary, backupItemName: nil, options: [])
        } else {
            try fm.moveItem(at: temporary, to: targetURL)
        }
    }

    static func removeOrphanedStagingFiles(in directory: URL) throws -> Int {
        let staging = directory.appendingPathComponent(".predatorlab-staging", isDirectory: true)
        guard FileManager.default.fileExists(atPath: staging.path) else { return 0 }
        let files = try FileManager.default.contentsOfDirectory(at: staging, includingPropertiesForKeys: nil)
        var removed = 0
        for file in files where file.pathExtension == "tmp" { try FileManager.default.removeItem(at: file); removed += 1 }
        return removed
    }
}

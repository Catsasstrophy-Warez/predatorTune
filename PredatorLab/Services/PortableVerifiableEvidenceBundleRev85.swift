import Foundation
import CryptoKit

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct PortableEvidenceBundleManifestRev85: Codable, Sendable {
    let schemaVersion: Int
    let createdAt: Date
    let sourceFilename: String
    let sourceSHA256: String?
    let includedChannels: [String]
    let eventCount: Int
    let note: String
}

enum PortableVerifiableEvidenceBundleRev85 {
    static func manifest(for log: ImportedLog, includedChannels: [String]) -> PortableEvidenceBundleManifestRev85 {
        .init(schemaVersion: 1, createdAt: .now, sourceFilename: log.filename, sourceSHA256: log.sourceSHA256, includedChannels: includedChannels.sorted(), eventCount: log.events.count, note: "Hashes prove byte identity, not diagnostic truth. Authenticated authorship requires a separate signature contract.")
    }
    static func canonicalManifestData(_ manifest: PortableEvidenceBundleManifestRev85) throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(manifest)
    }
    static func sha256Hex(_ data: Data) -> String { SHA256.hash(data:data).map { String(format:"%02x", $0) }.joined() }
}

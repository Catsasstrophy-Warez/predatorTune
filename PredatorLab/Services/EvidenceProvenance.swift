import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

struct AnalysisEngineVersion: Codable, Equatable {
    var parser="2.1"; var channelResolver="2.1"; var eventDetector="2.1"; var evidenceEngine="2.1"; var reasoningEngine="2.1"; var technicalLibrary="1.1"
    static let current = AnalysisEngineVersion()
}
struct EvidenceProvenance: Codable, Equatable { let generatedAt:Date; let engine:AnalysisEngineVersion; let sourceSHA256:String? }

enum EvidenceIntegrity {
    static func sha256(of url:URL) throws -> String? {
        #if canImport(CryptoKit)
        let handle = try FileHandle(forReadingFrom: url); defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try handle.read(upToCount: 1024 * 1024), !chunk.isEmpty { hasher.update(data: chunk) }
        return hasher.finalize().map { String(format:"%02x", $0) }.joined()
        #else
        return nil
        #endif
    }
}

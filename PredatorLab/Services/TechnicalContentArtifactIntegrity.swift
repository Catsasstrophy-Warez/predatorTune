import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

struct TechnicalContentArtifactFingerprint: Codable, Equatable {
    let schemaVersion: Int
    let contentVersion: String
    let payloadSHA256: String
    let payloadByteCount: Int
    let semanticCounts: [String:Int]
}

enum TechnicalContentArtifactIntegrity {
    static func canonicalData(_ package: TechnicalContentCompiledPackage) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(package)
    }

    static func fingerprint(_ package: TechnicalContentCompiledPackage) throws -> TechnicalContentArtifactFingerprint {
        let data = try canonicalData(package)
        return .init(schemaVersion: package.content.manifest.schemaVersion,
                     contentVersion: package.content.manifest.contentVersion,
                     payloadSHA256: sha256(data), payloadByteCount: data.count,
                     semanticCounts: ["components": package.content.components.count,
                                      "circuits": package.content.circuits.count,
                                      "sensors": package.content.sensors.count,
                                      "dtcs": package.content.dtcs.count,
                                      "procedures": package.content.procedures.count,
                                      "calibration": package.content.calibration.count,
                                      "measurementClaims": package.measurementClaims.count])
    }

    static func roundTripIssues(_ package: TechnicalContentCompiledPackage) throws -> [String] {
        let data = try canonicalData(package)
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TechnicalContentCompiledPackage.self, from: data)
        var issues = VersionedTechnicalContentEngine.validate(decoded.content)
        if decoded.measurementClaims.count != package.measurementClaims.count { issues.append("Measurement-claim count changed during JSON round trip.") }
        if decoded.trustSummary != package.trustSummary { issues.append("Trust summary changed during JSON round trip.") }
        if decoded.generatedBoundary != package.generatedBoundary { issues.append("Evidence boundary changed during JSON round trip.") }
        return issues
    }

    private static func sha256(_ data: Data) -> String {
        #if canImport(CryptoKit)
        return SHA256.hash(data: data).map { String(format:"%02x", $0) }.joined()
        #else
        // Linux/static-analysis fallback: deterministic FNV-1a marker, explicitly not represented as SHA-256 truth.
        var hash: UInt64 = 1469598103934665603
        for byte in data { hash ^= UInt64(byte); hash &*= 1099511628211 }
        return "unavailable-sha256-fnv1a-" + String(hash, radix:16)
        #endif
    }
}

import Foundation

struct TechnicalContentReleaseGateResult: Codable, Equatable {
    let admitted: Bool
    let issues: [String]
    let expected: TechnicalContentArtifactFingerprint
    let candidate: TechnicalContentArtifactFingerprint?
    let boundary: String
}

enum TechnicalContentReleaseGate {
    static func evaluate(seed: TechnicalContentCompiledPackage, candidateData: Data) -> TechnicalContentReleaseGateResult {
        let expected: TechnicalContentArtifactFingerprint
        do { expected = try TechnicalContentArtifactIntegrity.fingerprint(seed) }
        catch {
            return .init(admitted: false, issues: ["Could not fingerprint authored seed baseline: \(error.localizedDescription)"], expected: .init(schemaVersion: -1, contentVersion: "unavailable", payloadSHA256: "unavailable", payloadByteCount: 0, semanticCounts: [:]), candidate: nil, boundary: boundary)
        }
        do {
            let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
            let candidatePackage = try decoder.decode(TechnicalContentCompiledPackage.self, from: candidateData)
            var issues = try TechnicalContentArtifactIntegrity.roundTripIssues(candidatePackage)
            let candidate = try TechnicalContentArtifactIntegrity.fingerprint(candidatePackage)
            for (key, value) in expected.semanticCounts where candidate.semanticCounts[key] != value {
                issues.append("Semantic inventory changed for \(key): expected \(value), candidate \(candidate.semanticCounts[key] ?? -1).")
            }
            if candidatePackage.trustSummary != seed.trustSummary { issues.append("Trust summary changed during externalization.") }
            if candidatePackage.measurementClaims != seed.measurementClaims { issues.append("Measurement claim identities or trust contracts changed during externalization.") }
            if candidatePackage.generatedBoundary != seed.generatedBoundary { issues.append("Evidence boundary changed during externalization.") }
            return .init(admitted: issues.isEmpty, issues: issues.sorted(), expected: expected, candidate: candidate, boundary: boundary)
        } catch {
            return .init(admitted: false, issues: ["Candidate technical-content artifact could not be decoded or audited: \(error.localizedDescription)"], expected: expected, candidate: nil, boundary: boundary)
        }
    }

    static let boundary = "Release admission proves semantic equivalence to the authored seed package. It does not verify the underlying automotive claims or upgrade their evidence state."
}

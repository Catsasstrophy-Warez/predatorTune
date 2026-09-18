import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

/// Rev85 fixture governance. A fixture is evidence, not truth: assertions are limited to what its provenance permits.
enum EvidenceFixtureKindRev85: String, Codable, CaseIterable { case hpl, csv, scannerXML, telemetryExport, other }
enum EvidenceFixtureCertificationRev85: String, Codable, CaseIterable { case rawObserved, hashVerified, crossArtifactCandidate, semanticallyCertified }

struct EvidenceFixtureRev85: Identifiable, Codable, Equatable {
    let id: String
    let kind: EvidenceFixtureKindRev85
    let relativePath: String
    let sha256: String
    let byteCount: Int
    let vehicleConfiguration: String?
    let acquisitionMethod: String?
    let capturedAt: Date?
    let certification: EvidenceFixtureCertificationRev85
    let expectedChannels: [String]
    let expectedEventWindowsSeconds: [ClosedRange<Double>]
    let permittedAssertions: [String]
    let notes: [String]
}

struct EvidenceFixtureManifestRev85: Codable, Equatable {
    let schemaVersion: Int
    let generatedAt: Date
    let fixtures: [EvidenceFixtureRev85]
}

enum EvidenceFixtureRegistryRev85 {
    static let schemaVersion = 1
    static func validate(_ fixture: EvidenceFixtureRev85) -> [String] {
        var issues: [String] = []
        if fixture.sha256.count != 64 || fixture.sha256.contains(where: { !$0.isHexDigit }) { issues.append("Fixture SHA-256 must contain exactly 64 hexadecimal characters") }
        if fixture.byteCount < 0 { issues.append("Fixture byte count cannot be negative") }
        if fixture.relativePath.hasPrefix("/") || fixture.relativePath.contains("..") { issues.append("Fixture path must be relative and traversal-free") }
        if fixture.permittedAssertions.isEmpty { issues.append("Fixture must explicitly state its permitted assertions") }
        if fixture.certification == .semanticallyCertified && fixture.expectedChannels.isEmpty { issues.append("Semantic certification requires expected channel identity") }
        return issues
    }

    static func validate(_ manifest: EvidenceFixtureManifestRev85) -> [String] {
        var issues = manifest.fixtures.flatMap { fixture in validate(fixture).map { "\(fixture.id): \($0)" } }
        let ids = manifest.fixtures.map(\.id)
        let paths = manifest.fixtures.map(\.relativePath)
        if Set(ids).count != ids.count { issues.append("Fixture IDs must be unique") }
        if Set(paths).count != paths.count { issues.append("Fixture paths must be unique") }
        if manifest.schemaVersion != schemaVersion { issues.append("Unsupported fixture manifest schema version") }
        return issues
    }
}

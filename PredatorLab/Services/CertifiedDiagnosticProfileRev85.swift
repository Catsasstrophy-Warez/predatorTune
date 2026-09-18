import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

/// Numeric diagnostic boundaries are data, never universal GT500 constants in detector code.
struct CertifiedDiagnosticBoundaryRev85: Identifiable, Codable, Sendable, Equatable {
    enum Certification: String, Codable, Sendable { case proposed, observed, sourceVerified, vehicleValidated }
    let id: String
    let channelSemanticID: String
    let comparator: String
    let value: Double
    let unit: String
    let certification: Certification
    let provenance: String
    let applicability: String
}

struct CertifiedDiagnosticProfileRev85: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let name: String
    let boundaries: [CertifiedDiagnosticBoundaryRev85]
    let sourceArtifactHashes: [String]

    var executableBoundaries: [CertifiedDiagnosticBoundaryRev85] {
        boundaries.filter { $0.certification == .sourceVerified || $0.certification == .vehicleValidated }
    }
}

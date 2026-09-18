import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

enum TelemetryTransportKindRev85: String, Codable, Sendable { case csvFile, hplArtifact, mpvi4LiveUnverified }
enum TelemetryTransportVerificationRev85: String, Codable, Sendable { case admitted, experimental, unverified }
struct TelemetryTransportCapabilityRev85: Codable, Sendable {
    let kind: TelemetryTransportKindRev85
    let verification: TelemetryTransportVerificationRev85
    let detail: String
}
protocol TelemetryTransportRev85: Sendable {
    var capability: TelemetryTransportCapabilityRev85 { get }
}
struct CSVFileTransportRev85: TelemetryTransportRev85 {
    let capability = TelemetryTransportCapabilityRev85(kind: .csvFile, verification: .admitted, detail: "Offline CSV source with file provenance.")
}
struct HPLArtifactTransportRev85: TelemetryTransportRev85 {
    let capability = TelemetryTransportCapabilityRev85(kind: .hplArtifact, verification: .experimental, detail: "Artifact-specific native probing; decoded semantics require admission.")
}
struct MPVI4LiveTransportRev85: TelemetryTransportRev85 {
    let capability = TelemetryTransportCapabilityRev85(kind: .mpvi4LiveUnverified, verification: .unverified, detail: "No iOS USB/Wi-Fi/Bluetooth transport is claimed until hardware/API testing proves one.")
}

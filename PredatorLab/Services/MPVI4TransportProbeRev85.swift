import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

/// Candidate transport facts are hypotheses until a physical MPVI4/API experiment records evidence.
struct TransportProbeCandidateRev85: Identifiable, Codable, Sendable, Equatable {
    enum Kind: String, Codable, Sendable { case bluetoothLE, bluetoothL2CAP, localNetworkTCP, localNetworkUDP, usbAccessory, usbSerial }
    enum State: String, Codable, Sendable { case proposed, observed, rejected, admitted }
    let id: String
    let kind: Kind
    let endpointDescription: String?
    let state: State
    let evidenceArtifactSHA256: String?
    let notes: String
}

struct MPVI4TransportProbeReportRev85: Codable, Sendable {
    let observedAt: Date
    let interfaceIdentity: String?
    let firmware: String?
    let scannerVersion: String?
    let candidates: [TransportProbeCandidateRev85]
    var admittedCandidates: [TransportProbeCandidateRev85] { candidates.filter { $0.state == .admitted } }
}

enum MPVI4TransportProbeRev85 {
    static let initialCandidates: [TransportProbeCandidateRev85] = [
        .init(id:"ble", kind:.bluetoothLE, endpointDescription:nil, state:.proposed, evidenceArtifactSHA256:nil, notes:"Do not assume advertised services, characteristics, throughput, or BLE version."),
        .init(id:"l2cap", kind:.bluetoothL2CAP, endpointDescription:nil, state:.proposed, evidenceArtifactSHA256:nil, notes:"PSM unknown until observed."),
        .init(id:"tcp", kind:.localNetworkTCP, endpointDescription:nil, state:.proposed, evidenceArtifactSHA256:nil, notes:"Host and port intentionally unspecified."),
        .init(id:"usb", kind:.usbAccessory, endpointDescription:nil, state:.proposed, evidenceArtifactSHA256:nil, notes:"iOS accessory/USB exposure must be proven on hardware.")
    ]
}

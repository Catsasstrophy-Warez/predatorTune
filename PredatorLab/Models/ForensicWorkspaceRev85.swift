import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

/// Stable synchronization primitive shared by Pull Lab, Evidence, Topology and Replay.
struct ForensicCursorRev85: Equatable, Sendable {
    var time: TimeInterval?
    var rpm: Double?
    var eventID: UUID?
    var evidenceID: String?
    var hypothesisID: String?
    var channelID: String?

    static let empty = ForensicCursorRev85()
}

struct ForensicChannelDescriptorRev85: Identifiable, Hashable, Sendable {
    enum SemanticState: String, Sendable { case unknown, observed, certified }
    let id: String
    let displayName: String
    let unit: String?
    let semanticState: SemanticState
}

struct ForensicEvidenceStatusRev85: Equatable, Sendable {
    enum Identity: String, Sendable { case unknown, matched, mismatch }
    enum Measurement: String, Sendable { case unknown, valid, questionable, invalid }
    enum Interpretation: String, Sendable { case unsupported, provisional, supported, contradicted }
    var identity: Identity = .unknown
    var semanticsCertified = false
    var measurement: Measurement = .unknown
    var interpretation: Interpretation = .unsupported
}

enum PredatorWorkspaceRev85: String, CaseIterable, Identifiable, Sendable {
    case pullLab = "Pull Lab"
    case evidence = "Evidence"
    case calibration = "Calibration"
    case topology = "Topology"
    case execution = "Execution"
    case replay = "Replay"
    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .pullLab: return "waveform.path.ecg"
        case .evidence: return "checkmark.shield"
        case .calibration: return "slider.horizontal.3"
        case .topology: return "point.3.connected.trianglepath.dotted"
        case .execution: return "checklist"
        case .replay: return "play.rectangle.on.rectangle"
        }
    }
}

struct WorkspaceCapabilityRev85: OptionSet, Sendable {
    let rawValue: Int
    static let synchronizedCursor = Self(rawValue: 1 << 0)
    static let provenanceInspector = Self(rawValue: 1 << 1)
    static let hypotheses = Self(rawValue: 1 << 2)
    static let calibrationComparison = Self(rawValue: 1 << 3)
    static let topologyLinking = Self(rawValue: 1 << 4)
    static let physicalExecution = Self(rawValue: 1 << 5)
}

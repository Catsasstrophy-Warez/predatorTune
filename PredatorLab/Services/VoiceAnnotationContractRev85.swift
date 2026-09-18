import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

/// Speech is an optional producer of human annotations. It never becomes a measured telemetry channel.
struct VoiceAnnotationCueRev85: Codable, Sendable, Equatable {
    enum Intent: String, Codable, Sendable { case pullStart, pullAbort, anomaly, note }
    let hostUptime: TimeInterval
    let transcript: String
    let intent: Intent
}

enum VoiceAnnotationContractRev85 {
    static func annotation(from cue: VoiceAnnotationCueRev85, clock: ForensicClockBridgeRev85) -> ForensicAnnotationRev85 {
        .init(time: clock.sessionTime(forHostUptime: cue.hostUptime), source: .speechTranscript, text: cue.transcript)
    }
}

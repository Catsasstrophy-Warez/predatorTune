import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

/// Maps a monotonic host clock into session-relative forensic time without using wall-clock time for alignment.
struct ForensicClockBridgeRev85: Codable, Sendable, Equatable {
    let hostUptimeAtSessionZero: TimeInterval
    let sessionZero: TimeInterval
    let establishedAt: Date
    let provenance: String

    func sessionTime(forHostUptime uptime: TimeInterval) -> TimeInterval {
        sessionZero + (uptime - hostUptimeAtSessionZero)
    }

    func hostUptime(forSessionTime time: TimeInterval) -> TimeInterval {
        hostUptimeAtSessionZero + (time - sessionZero)
    }
}

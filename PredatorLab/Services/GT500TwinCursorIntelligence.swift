import Foundation

/// Builds a conservative, cursor-scoped relevance picture for the GT500 Twin.
/// Relevance is navigation context only. It never asserts health, failure, or causation.
struct GT500TwinCursorSnapshot: Sendable {
    let time: TimeInterval?
    let channelID: String?
    let hypothesisID: String?
    let matches: [GT500TwinContextMatch]
    let boundary: String
}

enum GT500TwinCursorIntelligence {
    static func snapshot(cursor: ForensicCursorRev85, selection: ForensicSelectionContext) -> GT500TwinCursorSnapshot {
        let matches = GT500TwinBidirectionalResolver.matches(
            channelID: cursor.channelID ?? selection.channelID,
            hypothesisID: cursor.hypothesisID ?? selection.hypothesisID,
            topologyNodeID: selection.topologyNodeID
        )
        return .init(
            time: cursor.time ?? selection.time,
            channelID: cursor.channelID ?? selection.channelID,
            hypothesisID: cursor.hypothesisID ?? selection.hypothesisID,
            matches: matches,
            boundary: "Highlighted means relevant to the selected evidence context. It does not mean healthy, failed, causal, or vehicle-validated."
        )
    }

    static func preferredChannels(for nodeID: String) -> [String] {
        switch nodeID {
        case "production-pcm", "tr-c75", "clutches", "c105":
            return ["Torque Source", "Spark Source", "Torque Max Protection Source", "Engine RPM (SAE)"]
        case "fuel-pumps", "pump-1", "pump-2", "injectors", "production-fuel", "pressure":
            return ["Fuel Pressure (SAE)", "Torque Max Protection Source", "Engine RPM (SAE)"]
        case "supercharger-drive", "supercharger", "charge-cooling", "engine-mechanical":
            return ["Engine RPM (SAE)", "Intake Air Temp 2"]
        case "scanner-identity", "sensor-matrix":
            return GT500FlagshipForensicsRev77.sep2.observations.map(\.signal)
        default:
            return []
        }
    }
}

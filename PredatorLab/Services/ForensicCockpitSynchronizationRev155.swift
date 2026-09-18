import Foundation

/// A single read-only packet that lets every forensic surface follow the same cursor.
/// It intentionally synchronizes context, not conclusions.
struct ForensicCockpitPacketRev155: Sendable {
    let time: Double?
    let activeBandTitles: [String]
    let twinMatches: [GT500TwinContextMatch]
    let selectedHypothesisID: String?
    let calibrationRelationships: [GT500UnifiedForensicContext.CalibrationLink]
    let bestNextMeasurements: [String]
    let comparisonStatement: String?
    let authority: String
    let boundary: String
}

enum ForensicCockpitSynchronizationEngineRev155 {
    static func packet(cursor: ForensicCursorRev85, selection: ForensicSelectionContext) -> ForensicCockpitPacketRev155 {
        let unified = GT500TwinUnifiedForensicContextEngine.build(cursor: cursor, selection: selection)
        let missing = unified.missingMeasurements
        let prioritized = missing.enumerated().map { index, item in
            "\(index + 1). Acquire/verify \(item)"
        }
        return .init(
            time: unified.time,
            activeBandTitles: unified.activeBands.map(\.title),
            twinMatches: unified.twin.matches,
            selectedHypothesisID: cursor.hypothesisID ?? selection.hypothesisID,
            calibrationRelationships: unified.calibrationLinks,
            bestNextMeasurements: prioritized,
            comparisonStatement: unified.comparisonWindow,
            authority: "SYNCHRONIZED NAVIGATION / MIXED EVIDENCE AUTHORITY",
            boundary: "Cursor synchronization preserves chronology and investigative context only. Twin relevance, hypothesis selection, A/B comparison, calibration relationships, and measurement priority remain separate evidence claims and do not establish causality, failure, calibration truth, or vehicle validation."
        )
    }
}

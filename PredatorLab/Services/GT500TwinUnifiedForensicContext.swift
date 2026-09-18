import Foundation

/// Unifies cursor, Golden Corpus navigation windows, Twin relevance, baseline/A-B context,
/// and calibration investigation links without promoting any relationship to causation.
struct GT500UnifiedForensicContext: Sendable {
    struct EpisodeBand: Identifiable, Sendable {
        let id: String
        let title: String
        let range: ClosedRange<Double>
        let authority: String
        let boundary: String
        func contains(_ time: Double?) -> Bool { time.map(range.contains) ?? false }
    }
    struct CalibrationLink: Identifiable, Sendable {
        let id: String
        let title: String
        let reason: String
        let authority: String
    }
    let time: Double?
    let twin: GT500TwinCursorSnapshot
    let activeBands: [EpisodeBand]
    let comparisonWindow: String?
    let calibrationLinks: [CalibrationLink]
    let missingMeasurements: [String]
    let boundary: String
}

enum GT500TwinUnifiedForensicContextEngine {
    static let bands: [GT500UnifiedForensicContext.EpisodeBand] = [
        .init(id: "golden.a", title: "Golden Corpus • Window A", range: 5.578...6.418, authority: "OBSERVED WINDOW / DERIVED ANALYSIS", boundary: "High-demand is an analysis navigation label, not Ford-defined WOT or a fault threshold."),
        .init(id: "golden.b", title: "Golden Corpus • Window B", range: 970.854...971.134, authority: "OBSERVED WINDOW / DERIVED ANALYSIS", boundary: "A/B differences are derived and noncausal; operating-state equivalence is not assumed.")
    ]

    static func build(cursor: ForensicCursorRev85, selection: ForensicSelectionContext) -> GT500UnifiedForensicContext {
        let twin = GT500TwinCursorIntelligence.snapshot(cursor: cursor, selection: selection)
        let time = cursor.time ?? selection.time
        let active = bands.filter { $0.contains(time) }
        let nodeIDs = Set(twin.matches.map(\.nodeID) + [selection.topologyNodeID?.replacingOccurrences(of: "twin:", with: "")].compactMap { $0 })
        var links: [GT500UnifiedForensicContext.CalibrationLink] = []
        if !nodeIDs.isDisjoint(with: ["production-pcm", "tr-c75", "clutches", "c105"]) {
            links.append(.init(id: "cal.torque", title: "Torque coordination calibration family", reason: "Relevant for reviewing commanded/limited torque context around an event. Exact production GT500 table identity requires controller/OS-specific captured evidence.", authority: "RESEARCH RELATIONSHIP"))
        }
        if !nodeIDs.isDisjoint(with: ["fuel-pumps", "pump-1", "pump-2", "injectors", "production-fuel", "pressure"]) {
            links.append(.init(id: "cal.fuel", title: "Fuel delivery calibration family", reason: "Relevant to commanded pressure/injector-window investigation. Exported fuel-pressure behavior alone does not establish calibration causation.", authority: "RESEARCH RELATIONSHIP"))
        }
        if !nodeIDs.isDisjoint(with: ["supercharger", "supercharger-drive", "charge-cooling", "engine-mechanical"]) {
            links.append(.init(id: "cal.air", title: "Airflow / thermal calibration family", reason: "Relevant to airflow and thermal context. No inferred protection threshold is admitted as Ford truth.", authority: "RESEARCH RELATIONSHIP"))
        }
        var missing: [String] = []
        if nodeIDs.contains("tr-c75") || nodeIDs.contains("clutches") {
            missing += ["verified transmission input/shaft speed", "verified transmission output/shaft speed", "verified gear state", "verified clutch torque/state"]
        }
        if nodeIDs.contains("injectors") || nodeIDs.contains("pressure") || nodeIDs.contains("production-fuel") {
            missing += ["reviewed injector pulse-width/window evidence", "desired fuel-pressure context", "validated lambda evidence"]
        }
        return .init(time: time, twin: twin, activeBands: active,
                     comparisonWindow: active.first.map { $0.id == "golden.a" ? "A ↔ B comparison available as DERIVED evidence" : "B ↔ A comparison available as DERIVED evidence" },
                     calibrationLinks: links, missingMeasurements: Array(Set(missing)).sorted(),
                     boundary: "One cursor synchronizes navigation context only. Event overlap, Twin relevance, A/B deltas, calibration relationships, and hypotheses do not establish cause, health, failure, or vehicle validation.")
    }
}

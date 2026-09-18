import Foundation

struct ForensicAcquisitionChecklistItem: Identifiable, Hashable, Sendable {
    let id: String
    let measurement: String
    let rationale: String
    let status: String
}

struct ForensicInvestigationSnapshot: Sendable {
    let time: Double?
    let evidenceAuthority: String
    let activeBands: [GT500UnifiedForensicContext.EpisodeBand]
    let twinMatches: [GT500TwinContextMatch]
    let hypothesisID: String?
    let calibrationLinks: [GT500UnifiedForensicContext.CalibrationLink]
    let acquisitionChecklist: [ForensicAcquisitionChecklistItem]
    let comparison: String?
    let boundary: String
}

enum ForensicInvestigationInspectorEngine {
    static func snapshot(cursor: ForensicCursorRev85, selection: ForensicSelectionContext) -> ForensicInvestigationSnapshot {
        let context = GT500TwinUnifiedForensicContextEngine.build(cursor: cursor, selection: selection)
        let hypothesis = cursor.hypothesisID ?? selection.hypothesisID
        let checklist = context.missingMeasurements.enumerated().map { index, measurement in
            ForensicAcquisitionChecklistItem(
                id: "missing.\(index).\(measurement)", measurement: measurement,
                rationale: rationale(for: measurement, hypothesisID: hypothesis), status: "MISSING / VERIFY"
            )
        }
        return .init(time: context.time, evidenceAuthority: "MIXED AUTHORITY • CURSOR-SYNCHRONIZED",
                     activeBands: context.activeBands, twinMatches: context.twin.matches,
                     hypothesisID: hypothesis, calibrationLinks: context.calibrationLinks,
                     acquisitionChecklist: checklist, comparison: context.comparisonWindow,
                     boundary: "This inspector synchronizes navigation and investigative context. Relevance, temporal overlap, A/B differences, calibration relationships, and measurement priority do not establish causality, component failure, calibration truth, or vehicle validation.")
    }

    private static func rationale(for measurement: String, hypothesisID: String?) -> String {
        let lower = measurement.lowercased()
        if lower.contains("shaft") || lower.contains("gear") || lower.contains("clutch") {
            return "Needed to discriminate driveline/shift interpretations without treating engine/output RPM difference as clutch slip."
        }
        if lower.contains("fuel") || lower.contains("injector") || lower.contains("lambda") {
            return "Needed to separate delivery, command/window, and mixture-response explanations in the fuel investigation."
        }
        return hypothesisID.map { "Missing discriminator for hypothesis context \($0)." } ?? "Missing discriminator for the current investigation context."
    }
}

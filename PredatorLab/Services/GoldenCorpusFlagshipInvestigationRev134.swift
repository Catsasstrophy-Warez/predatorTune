import Foundation

struct FlagshipEvidenceFindingRev134: Identifiable, Equatable, Sendable {
    let id: String
    let channel: String
    let summary: String
    let authority: TraceEvidenceAuthorityRev127
    let boundary: String
}

struct GoldenCorpusFlagshipInvestigationRev134: Equatable, Sendable {
    let episodeA: GT500EpisodeRev122
    let episodeB: GT500EpisodeRev122
    let comparison: GhostPullComparisonRev133
    let findings: [FlagshipEvidenceFindingRev134]
    let missingDiscriminators: [String]
    let boundary: String
}

enum GoldenCorpusFlagshipInvestigationEngineRev134 {
    static let firstWindow = 5.578...6.418
    static let secondWindow = 970.854...971.134
    static let comparisonChannels = [
        "Engine RPM (SAE)", "Accelerator Position D (SAE)", "Throttle Desired Angle", "Throttle Angle",
        "Manifold Absolute Pressure (SAE)", "Commanded Equivalence Ratio", "Fuel Pressure (SAE)",
        "Knock Correction (+Adv/-Ret)", "Intake Air Temp 2", "Scheduled Torque", "Engine Brake Torque"
    ]
    static let dctDiscriminators = ["verified transmission input/shaft speed", "verified transmission output/shaft speed", "verified gear state", "verified clutch torque/state"]

    static func build(log: ParsedLogData) -> GoldenCorpusFlagshipInvestigationRev134? {
        let session = ParsedLogForensicBridgeRev125.build(log)
        guard let a = bestHighDemand(in: firstWindow, episodes: session.episodes),
              let b = bestHighDemand(in: secondWindow, episodes: session.episodes) else { return nil }
        let wanted = Set(comparisonChannels)
        let series = session.series.filter { wanted.contains($0.id) }
        let comparison = GhostPullComparisonEngineRev133.compare(a: series, windowA: firstWindow, b: series, windowB: secondWindow, method: .eventAnchors)
        let findings = comparison.summaries.map { s in
            FlagshipEvidenceFindingRev134(id: s.id, channel: s.id,
                summary: "A mean \(format(s.meanA)) → B mean \(format(s.meanB)); Δ \(signed(s.meanDelta)); peaks \(format(s.peakA)) → \(format(s.peakB))",
                authority: .derived,
                boundary: "Window statistics are derived from exported values. A/B difference does not establish cause, health, calibration correctness, or an OEM limit.")
        }
        return .init(episodeA: a, episodeB: b, comparison: comparison, findings: findings,
                     missingDiscriminators: dctDiscriminators,
                     boundary: "Flagship case compares two observed high-demand navigation windows in the bundled sep2 artifact. High demand is an analysis label, not Ford-defined WOT. The comparison is DERIVED and noncausal. DCT slip/shift-phase conclusions remain blocked without verified transmission discriminators.")
    }

    private static func bestHighDemand(in window: ClosedRange<Double>, episodes: [GT500EpisodeRev122]) -> GT500EpisodeRev122? {
        episodes.filter { $0.kind == .highDemand && overlaps($0.start...$0.end, window) }
            .max { overlap($0.start...$0.end, window) < overlap($1.start...$1.end, window) }
    }
    private static func overlaps(_ a: ClosedRange<Double>, _ b: ClosedRange<Double>) -> Bool { max(a.lowerBound,b.lowerBound) <= min(a.upperBound,b.upperBound) }
    private static func overlap(_ a: ClosedRange<Double>, _ b: ClosedRange<Double>) -> Double { max(0,min(a.upperBound,b.upperBound)-max(a.lowerBound,b.lowerBound)) }
    private static func format(_ x: Double) -> String { String(format: "%.3f", x) }
    private static func signed(_ x: Double) -> String { String(format: "%+.3f", x) }
}

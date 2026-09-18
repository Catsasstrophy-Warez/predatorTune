import Foundation

/// Generic investigation definition. R04 is the first authored package, but the engine is problem-agnostic.
struct DiagnosticInvestigationDefinition: Identifiable, Codable {
    let id: String
    var title: String
    var phase: TuningPhase
    var requiredChannels: [CanonicalChannel]
    var hypotheses: [DiagnosticHypothesis]
    var verificationCriteria: [String]
    var authoredHypotheses: [AuthoredDiagnosticHypothesis]? = nil
}

struct DiagnosticRecommendation: Identifiable, Codable {
    let id: UUID
    var hypothesisID: R04HypothesisID
    var measurement: String
    var informationGainScore: Double
    var reason: String

    init(id: UUID = UUID(), hypothesisID: R04HypothesisID, measurement: String, informationGainScore: Double, reason: String) {
        self.id = id; self.hypothesisID = hypothesisID; self.measurement = measurement
        self.informationGainScore = informationGainScore; self.reason = reason
    }
}

enum DiagnosticIntelligenceEngine {
    /// Ranks next measurements by how many still-plausible hypotheses they can discriminate.
    static func recommendNextMeasurements(hypotheses: [DiagnosticHypothesis]) -> [DiagnosticRecommendation] {
        let plausible = hypotheses.filter { $0.isPlausible && $0.confidence != .c5 }
        var uses: [String: [R04HypothesisID]] = [:]
        for hypothesis in plausible {
            for measurement in hypothesis.nextMeasurements where !measurement.isEmpty {
                uses[measurement, default: []].append(hypothesis.id)
            }
        }
        let denominator = Double(max(plausible.count, 1))
        return uses.map { measurement, ids in
            let score = Double(Set(ids).count) / denominator
            return DiagnosticRecommendation(
                hypothesisID: ids[0], measurement: measurement, informationGainScore: score,
                reason: "Discriminates evidence across \(Set(ids).count) active hypothesis path(s)."
            )
        }.sorted { $0.informationGainScore > $1.informationGainScore }
    }

    static func missingRequiredChannels(for definition: DiagnosticInvestigationDefinition, in log: ParsedLogData) -> [CanonicalChannel] {
        definition.requiredChannels.filter { ChannelResolver.resolve($0, in: log.channels) == nil }
    }
}

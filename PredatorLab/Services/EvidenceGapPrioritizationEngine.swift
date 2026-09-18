import Foundation

// Evidence Gap cluster: ranks the FULL request catalog (EvidenceGapAcquisitionPlanner) by
// diagnostic impact and substitution risk, producing a research priority order. Does not
// assess individual candidates (see EvidenceGapClosureEngine) or grant truth-review
// eligibility (see EvidenceGapTruthEligibilityEngine).

struct EvidenceGapPriority: Identifiable, Codable, Equatable {
    let id: String
    let rank: Int
    let request: EvidenceGapRequest
    let diagnosticImpact: Int
    let substitutionRisk: Int
    let score: Int
}

enum EvidenceGapPrioritizationEngine {
    static func prioritize(_ requests: [EvidenceGapRequest] = EvidenceGapAcquisitionPlanner.requests) -> [EvidenceGapPriority] {
        var ranked: [EvidenceGapPriority] = []
        for request in requests {
            let impact: Int
            switch request.domain {
            case .wiringTopology, .electricalPinpoint, .fuelControl: impact = 10
            case .magneRide, .abs, .epas, .sensors: impact = 9
            case .engineClearances, .calibrationInternals: impact = 8
            }
            let forbiddenCount = request.forbiddenSubstitutions.count
            let substitutionRisk = min(10, 4 + forbiddenCount * 2)
            let baseScore: Int = request.priority
            let impactScore: Int = impact * 3
            let riskScore: Int = 2 * substitutionRisk
            let score: Int = baseScore + impactScore + riskScore
            ranked.append(EvidenceGapPriority(id: request.id, rank: 0, request: request, diagnosticImpact: impact, substitutionRisk: substitutionRisk, score: score))
        }
        ranked.sort { lhs, rhs in
            if lhs.score == rhs.score { return lhs.request.id < rhs.request.id }
            return lhs.score > rhs.score
        }
        return ranked.enumerated().map { offset, item in
            EvidenceGapPriority(id: item.id, rank: offset + 1, request: item.request, diagnosticImpact: item.diagnosticImpact, substitutionRisk: item.substitutionRisk, score: item.score)
        }
    }

    static let boundary = "Priority ranks research consequence and substitution risk. It does not imply that a missing artifact can be replaced by adjacent-platform material."
}

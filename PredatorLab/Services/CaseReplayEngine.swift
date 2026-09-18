import Foundation

struct HistoricalCaseMatch: Identifiable, Codable, Equatable {
    let id: UUID
    var rcaID: UUID
    var score: Double
    var reasons: [String]
    var boundary: String
}

enum CaseReplayEngine {
    /// Ranks the owner's prior RCA records as context. Similarity is not a diagnosis and never promotes a prior cause into current truth.
    static func rank(currentSymptom: String, buildStateID: UUID?, hypothesisTitles: [String], history: [PostJobRCA]) -> [HistoricalCaseMatch] {
        let symptomTokens = tokens(currentSymptom)
        let hypotheses = Set(hypothesisTitles.flatMap(tokens))
        return history.compactMap { rca in
            var score = 0.0
            var reasons: [String] = []
            let oldTokens = tokens(rca.symptom)
            let overlap = symptomTokens.intersection(oldTokens)
            if !overlap.isEmpty {
                score += min(0.55, Double(overlap.count) * 0.11)
                reasons.append("Symptom wording shares \\(overlap.count) meaningful term(s).")
            }
            let oldHypotheses = Set(rca.hypothesesConsidered.flatMap(tokens))
            let hOverlap = hypotheses.intersection(oldHypotheses)
            if !hOverlap.isEmpty {
                score += min(0.30, Double(hOverlap.count) * 0.06)
                reasons.append("Prior case considered overlapping hypothesis language.")
            }
            if let buildStateID, rca.buildStateID == buildStateID {
                score += 0.15
                reasons.append("Same recorded build revision.")
            } else if buildStateID != nil && rca.buildStateID != nil {
                reasons.append("Different build revision reduces applicability.")
            }
            guard score > 0 else { return nil }
            return HistoricalCaseMatch(id: UUID(), rcaID: rca.id, score: min(score, 1), reasons: reasons, boundary: "Historical similarity is contextual evidence only. It does not establish that the current event has the same physical cause.")
        }.sorted { $0.score > $1.score }
    }

    private static func tokens(_ text: String) -> Set<String> {
        let stop: Set<String> = ["the","and","for","with","from","this","that","was","were","into","after","before","vehicle","event"]
        return Set(text.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count >= 3 && !stop.contains($0) })
    }
}

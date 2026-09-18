import Foundation

struct TechnicalTruthDebtItem: Identifiable, Codable, Equatable {
    let id: String
    let truthID: String
    let domain: TechnicalTruthDomain
    let ownerTitle: String
    let statement: String
    let disposition: TechnicalTruthDisposition
    let criticality: ClaimCriticality
    let score: Int
    let missingSource: Bool
    let missingLocator: Bool
    let weakApplicability: Bool
    let action: String
}

struct TechnicalTruthDebtSummary: Codable, Equatable {
    let totalDebt: Int
    let highConsequence: Int
    let missingSources: Int
    let missingLocators: Int
    let disputed: Int
}

enum TechnicalTruthDebtEngine {
    static let boundary = "Truth debt ranks unresolved assertions by consequence and provenance gaps. Rank is a research/verification priority, not evidence that an assertion is true or false."

    static func rank(_ entries: [TechnicalTruthLedgerEntry]) -> [TechnicalTruthDebtItem] {
        entries.compactMap { entry in
            guard entry.disposition != .verified && entry.disposition != .superseded else { return nil }
            let missingSource = entry.sourceTitle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
            let missingLocator = entry.locator?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
            let weakApplicability = entry.applicability.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || entry.applicability.localizedCaseInsensitiveContains("unless narrowed") || entry.applicability.localizedCaseInsensitiveContains("requires claim-level verification") || entry.applicability.localizedCaseInsensitiveContains("unverified")
            var score = entry.criticality.rawValue * 25
            if entry.disposition == .disputed { score += 20 }
            if missingSource { score += 12 }
            if missingLocator { score += 10 }
            if weakApplicability { score += 8 }
            let action: String
            if entry.disposition == .disputed { action = "Resolve conflicting evidence before diagnostic/service use." }
            else if missingSource { action = "Acquire an exact applicable authoritative source." }
            else if missingLocator { action = "Attach an exact retrievable source locator." }
            else if weakApplicability { action = "Narrow model-year/build/configuration applicability." }
            else { action = "Complete claim-level verification review." }
            return .init(id:"debt.\(entry.id)", truthID:entry.id, domain:entry.domain, ownerTitle:entry.ownerTitle,
                         statement:entry.statement, disposition:entry.disposition, criticality:entry.criticality, score:score,
                         missingSource:missingSource, missingLocator:missingLocator, weakApplicability:weakApplicability, action:action)
        }.sorted { ($0.score, $0.criticality.rawValue, $0.truthID) > ($1.score, $1.criticality.rawValue, $1.truthID) }
    }

    static func summary(_ items: [TechnicalTruthDebtItem]) -> TechnicalTruthDebtSummary {
        .init(totalDebt:items.count, highConsequence:items.filter{$0.criticality >= .diagnostic}.count,
              missingSources:items.filter(\.missingSource).count, missingLocators:items.filter(\.missingLocator).count,
              disputed:items.filter{$0.disposition == .disputed}.count)
    }
}

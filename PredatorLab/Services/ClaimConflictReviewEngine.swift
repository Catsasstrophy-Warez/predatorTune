import Foundation

struct ClaimConflictReviewItem: Identifiable, Equatable {
    let id: String
    var statement: String
    var applicability: String
    var claims: [TechnicalClaim]
    var severity: String
    var boundary: String
}

enum ClaimConflictReviewEngine {
    static func review(_ claims: [TechnicalClaim]) -> [ClaimConflictReviewItem] {
        ContentIntegrityCompiler.conflicts(claims).map { group in
            let first = group[0]
            let critical = group.map(\.criticality).max() ?? .descriptive
            return .init(id: group.map(\.id).sorted().joined(separator: "|"), statement: first.statement, applicability: first.applicability, claims: group.sorted { $0.id < $1.id }, severity: critical >= .diagnostic ? "High" : "Review", boundary: "Conflicting values are quarantined for review. PredatorLab must not silently choose a winner from source grade alone; applicability, locator, revision and source scope must be reconciled.")
        }.sorted { $0.severity > $1.severity }
    }
}

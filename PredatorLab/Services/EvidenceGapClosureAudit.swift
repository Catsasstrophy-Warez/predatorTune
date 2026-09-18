import Foundation

// Evidence Gap cluster: cross-cutting invariant audit over a BATCH of
// EvidenceGapTruthEligibilityEngine reports (e.g. flags any candidate that bypassed human
// review). Summarizes/verifies the pipeline's own safety invariants; it does not assess
// individual candidates or requests itself.

struct EvidenceClosureAuditSummary: Codable, Equatable {
    let totalRequests: Int
    let acceptedArtifacts: Int
    let reviewEligibleClaims: Int
    let verifiedByClosure: Int
    let issues: [String]
}

enum EvidenceGapClosureAudit {
    /// Static invariant audit: gap closure must never directly create verified Technical Truth.
    static func summarize(reports: [EvidenceGapTruthEligibilityReport]) -> EvidenceClosureAuditSummary {
        let eligible = reports.reduce(0) { $0 + $1.eligibleTruthIDs.count }
        var issues: [String] = []
        if reports.contains(where: { $0.candidates.contains(where: { !$0.reviewRequired }) }) {
            issues.append("Evidence closure produced a candidate that bypasses human review.")
        }
        return .init(totalRequests: reports.count, acceptedArtifacts: reports.filter(\.closureAccepted).count,
                     reviewEligibleClaims: eligible, verifiedByClosure: 0, issues: issues)
    }
}

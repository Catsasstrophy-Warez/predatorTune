import Foundation

// Evidence Gap cluster, stage 3: bridges an ACCEPTED EvidenceGapClosureEngine result to the
// Technical Truth Ledger, producing a human-review-required eligibility report. Never
// verifies/promotes truth entries itself — see EvidenceGapClosureAudit for the invariant
// check that enforces this.

/// Claim-level bridge between an accepted evidence artifact and the Technical Truth Ledger.
/// Acceptance of an artifact only creates a human-review queue. It never mutates verification state.
struct TruthEligibilityCandidate: Identifiable, Codable, Equatable {
    let id: String
    let truthID: String
    let requestID: String
    let artifactID: UUID
    let domain: TechnicalTruthDomain
    let statement: String
    let currentDisposition: TechnicalTruthDisposition
    let criticality: ClaimCriticality
    let applicability: String
    let sourceLocator: String
    let eligibilityReasons: [String]
    let reviewRequired: Bool
}

struct EvidenceGapTruthEligibilityReport: Codable, Equatable {
    let requestID: String
    let artifactID: UUID
    let closureAccepted: Bool
    let eligibleTruthIDs: [String]
    let ineligibleTruthIDs: [String]
    let candidates: [TruthEligibilityCandidate]
    let boundary: String
}

enum EvidenceGapTruthEligibilityEngine {
    static let boundary = "Passing an evidence-gap closure screen makes matching assertions eligible for human claim-level review only. It does not verify, promote, dispute, supersede, or rewrite any Technical Truth entry. Review must still confirm that the exact source passage supports the exact assertion and applicability."

    static func evaluate(candidate: EvidenceArtifactCandidate, request: EvidenceGapRequest, entries: [TechnicalTruthLedgerEntry]) -> EvidenceGapTruthEligibilityReport {
        let closure = EvidenceGapClosureEngine.assess(candidate, against: request)
        guard closure.accepted, let locator = candidate.locator, !locator.isEmpty else {
            return .init(requestID: request.id, artifactID: candidate.id, closureAccepted: false, eligibleTruthIDs: [], ineligibleTruthIDs: matching(entries, request: request).map(\.id), candidates: [], boundary: boundary)
        }

        let mapped = matching(entries, request: request)
        let eligible = mapped.filter { entry in
            entry.disposition != .superseded && entry.disposition != .verified && applicabilityCouldOverlap(entry.applicability, candidate.applicability)
        }
        let candidates = eligible.map { entry in
            TruthEligibilityCandidate(id: "\(candidate.id.uuidString).\(entry.id)", truthID: entry.id, requestID: request.id, artifactID: candidate.id,
                domain: entry.domain, statement: entry.statement, currentDisposition: entry.disposition, criticality: entry.criticality,
                applicability: entry.applicability, sourceLocator: locator,
                eligibilityReasons: ["Artifact passed the gap-level acceptance screen.", "Assertion maps to the requested evidence domain.", "Applicability is not demonstrably incompatible at this screening stage."],
                reviewRequired: true)
        }.sorted { ($0.criticality.rawValue, $0.truthID) > ($1.criticality.rawValue, $1.truthID) }
        let ids = Set(candidates.map(\.truthID))
        return .init(requestID: request.id, artifactID: candidate.id, closureAccepted: true, eligibleTruthIDs: candidates.map(\.truthID), ineligibleTruthIDs: mapped.filter { !ids.contains($0.id) }.map(\.id), candidates: candidates, boundary: boundary)
    }

    static func matching(_ entries: [TechnicalTruthLedgerEntry], request: EvidenceGapRequest) -> [TechnicalTruthLedgerEntry] {
        let impact = TruthDebtAcquisitionBridge.prioritize(entries: entries, requests: [request]).first
        let ids = Set(impact?.matchingTruthIDs ?? [])
        return entries.filter { ids.contains($0.id) }
    }

    private static func applicabilityCouldOverlap(_ truth: String, _ artifact: String) -> Bool {
        let t = truth.lowercased(), a = artifact.lowercased()
        if t.isEmpty || a.isEmpty { return false }
        // This is intentionally permissive screening, never verification. Exact applicability is a human review requirement.
        let tokens = ["2020", "2021", "2022", "gt500", "shelby"]
        let truthTokens = Set(tokens.filter { t.contains($0) })
        let artifactTokens = Set(tokens.filter { a.contains($0) })
        if truthTokens.isEmpty || artifactTokens.isEmpty { return true }
        return !truthTokens.isDisjoint(with: artifactTokens)
    }
}

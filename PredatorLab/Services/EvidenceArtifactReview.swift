import Foundation

/// Durable record of an acquired authoritative candidate. Persistence does not grant authority.
struct PersistedEvidenceArtifact: Identifiable, Codable, Equatable {
    let id: UUID
    let vehicleID: UUID?
    let requestID: String
    let domain: EvidenceGapDomain
    let artifact: EvidenceArtifactType
    let authorityGrade: SourceGrade?
    let applicability: String
    let locator: String
    let suppliedCriteria: [String]
    let description: String
    let closureAccepted: Bool
    let missingCriteria: [String]
    let forbiddenSubstitutionHits: [String]
    let eligibleTruthIDs: [String]
    let recordedAt: Date

    init(candidate: EvidenceArtifactCandidate, request: EvidenceGapRequest, entries: [TechnicalTruthLedgerEntry], vehicleID: UUID? = nil, authorityGrade: SourceGrade? = nil, recordedAt: Date = .now) {
        let closure = EvidenceGapClosureEngine.assess(candidate, against: request)
        let eligibility = EvidenceGapTruthEligibilityEngine.evaluate(candidate: candidate, request: request, entries: entries)
        self.id = candidate.id; self.vehicleID = vehicleID; self.requestID = request.id; self.domain = candidate.domain; self.artifact = candidate.artifact; self.authorityGrade = authorityGrade
        self.applicability = candidate.applicability; self.locator = candidate.locator ?? ""; self.suppliedCriteria = candidate.suppliedCriteria; self.description = candidate.description
        self.closureAccepted = closure.accepted; self.missingCriteria = closure.missingCriteria; self.forbiddenSubstitutionHits = closure.forbiddenSubstitutionHits
        self.eligibleTruthIDs = eligibility.eligibleTruthIDs; self.recordedAt = recordedAt
    }
}

enum EvidenceTruthReviewDecision: String, Codable, CaseIterable {
    case supports = "Supports assertion"
    case doesNotSupport = "Does not support"
    case applicabilityMismatch = "Applicability mismatch"
    case conflictingEvidence = "Conflicting evidence"
    case needsAnotherSource = "Needs another source"
}

/// Immutable claim-by-claim decision tying one artifact to one semantic truth ID.
struct EvidenceTruthReview: Identifiable, Codable, Equatable {
    let id: UUID
    let vehicleID: UUID?
    let artifactID: UUID
    let requestID: String
    let truthID: String
    let decision: EvidenceTruthReviewDecision
    let exactPassageLocator: String
    let applicabilityReviewed: String
    let notes: String
    let recordedAt: Date
}

struct EvidenceReviewPromotionAssessment: Codable, Equatable {
    let eligibleForPromotion: Bool
    let blockers: [String]
    let boundary: String
}

enum EvidenceReviewPromotionGate {
    static let boundary = "Only a claim-level Supports assertion decision with an exact passage locator and reviewed applicability may become eligible for a separate trust-state promotion. Review never promotes automatically."
    static func assess(_ review: EvidenceTruthReview, artifact: PersistedEvidenceArtifact, truth: TechnicalTruthLedgerEntry) -> EvidenceReviewPromotionAssessment {
        var blockers: [String] = []
        if !artifact.closureAccepted { blockers.append("Artifact did not pass the evidence-gap closure screen.") }
        if !artifact.eligibleTruthIDs.contains(truth.id) || review.truthID != truth.id { blockers.append("Artifact is not eligible for this exact semantic truth ID.") }
        if review.decision != .supports { blockers.append("Review decision does not support the assertion.") }
        if review.exactPassageLocator.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { blockers.append("Exact supporting passage locator is required.") }
        if review.applicabilityReviewed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { blockers.append("Applicability review is required.") }
        if truth.disposition == .superseded { blockers.append("Superseded truth cannot be promoted.") }
        return .init(eligibleForPromotion: blockers.isEmpty, blockers: blockers, boundary: boundary)
    }
}

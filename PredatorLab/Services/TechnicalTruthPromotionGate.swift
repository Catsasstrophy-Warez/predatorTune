import Foundation

struct TechnicalTruthPromotionAssessment: Codable, Equatable {
    let eligible: Bool
    let targetState: ClaimVerificationState
    let blockers: [String]
    let requiresDisputeReview: Bool
    let boundary: String
}

enum TechnicalTruthPromotionGate {
    static let boundary = "Promotion is a separate deliberate action. OEM/manufacturer verification requires a claim-level supporting review, exact passage locator, reviewed applicability, compatible authority grade, and no unresolved conflicting-evidence review. Promotion applies only to the exact semantic Truth ID."

    static func assess(truth: TechnicalTruthLedgerEntry, artifact: PersistedEvidenceArtifact, reviews: [EvidenceTruthReview], targetState: ClaimVerificationState) -> TechnicalTruthPromotionAssessment {
        let exact = reviews.filter { $0.artifactID == artifact.id && $0.truthID == truth.id }
        var blockers: [String] = []
        let conflicts = exact.filter { $0.decision == .conflictingEvidence }
        let requiresDispute = !conflicts.isEmpty
        if requiresDispute { blockers.append("Conflicting evidence exists; resolve the assertion through dispute review before promotion.") }
        guard let support = exact.filter({ $0.decision == .supports }).max(by: { $0.recordedAt < $1.recordedAt }) else {
            blockers.append("No claim-level Supports assertion review exists for this artifact.")
            return .init(eligible:false,targetState:targetState,blockers:blockers,requiresDisputeReview:requiresDispute,boundary:boundary)
        }
        let reviewGate = EvidenceReviewPromotionGate.assess(support, artifact: artifact, truth: truth)
        blockers += reviewGate.blockers
        let grade = authorityGrade(artifact)
        switch targetState {
        case .oemVerified:
            if grade != .a_factory { blockers.append("OEM verification requires an A-Factory authority artifact.") }
        case .manufacturerVerified:
            if grade != .a_factory && grade != .b_professional { blockers.append("Manufacturer verification requires A-Factory or B-Professional authority.") }
        case .professionalCorroboration:
            if grade == nil || grade == .c_owner || grade == .d_reference { blockers.append("Professional corroboration requires professional/manufacturer authority.") }
        case .empiricallyVerified:
            blockers.append("Empirical verification requires an empirical evidence workflow, not document promotion.")
        default:
            blockers.append("Selected state is not a promotion target.")
        }
        return .init(eligible: blockers.isEmpty, targetState: targetState, blockers: blockers, requiresDisputeReview: requiresDispute, boundary: boundary)
    }

    static func authorityGrade(_ artifact: PersistedEvidenceArtifact) -> SourceGrade? {
        artifact.authorityGrade
    }
}

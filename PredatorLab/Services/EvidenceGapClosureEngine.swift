import Foundation

// Evidence Gap cluster, stage 2: assesses whether ONE submitted artifact candidate
// satisfies ONE EvidenceGapAcquisitionPlanner request (domain/artifact match, acceptance
// criteria, forbidden-substitution screening). Per-candidate scoring only — see
// EvidenceGapTruthEligibilityEngine for what an accepted closure unlocks downstream, and
// EvidenceGapClosureAudit for the cross-cutting invariant check over many results.

struct EvidenceArtifactCandidate: Codable, Equatable {
    let id: UUID
    let domain: EvidenceGapDomain
    let artifact: EvidenceArtifactType
    let applicability: String
    let locator: String?
    let suppliedCriteria: [String]
    let description: String

    init(id: UUID = UUID(), domain: EvidenceGapDomain, artifact: EvidenceArtifactType, applicability: String, locator: String?, suppliedCriteria: [String], description: String) {
        self.id = id; self.domain = domain; self.artifact = artifact; self.applicability = applicability; self.locator = locator; self.suppliedCriteria = suppliedCriteria; self.description = description
    }
}

struct EvidenceGapClosureAssessment: Codable, Equatable {
    let requestID: String
    let accepted: Bool
    let missingCriteria: [String]
    let forbiddenSubstitutionHits: [String]
    let boundary: String
}

enum EvidenceGapClosureEngine {
    static func assess(_ candidate: EvidenceArtifactCandidate, against request: EvidenceGapRequest) -> EvidenceGapClosureAssessment {
        let supplied = Set(candidate.suppliedCriteria.map { $0.lowercased() })
        let missing = request.acceptanceCriteria.filter { !supplied.contains($0.lowercased()) }
        let haystack = ([candidate.description, candidate.applicability] + candidate.suppliedCriteria).joined(separator:" ").lowercased()
        let forbidden = request.forbiddenSubstitutions.filter { haystack.contains($0.lowercased()) }
        let accepted = candidate.domain == request.domain && candidate.artifact == request.artifact && candidate.locator?.isEmpty == false && missing.isEmpty && forbidden.isEmpty
        return .init(requestID: request.id, accepted: accepted, missingCriteria: missing, forbiddenSubstitutionHits: forbidden, boundary: "A research lead closes an evidence gap only when artifact type, applicability, locator, every acceptance criterion, and forbidden-substitution screening pass. Similar-platform material remains a lead, not verification.")
    }
}

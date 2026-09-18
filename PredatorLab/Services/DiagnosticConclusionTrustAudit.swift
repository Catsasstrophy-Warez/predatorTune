import Foundation

enum DiagnosticConclusionStrength: String, Codable, CaseIterable { case observation, suggestion, strong }

struct DiagnosticConclusionContract: Identifiable, Codable, Equatable {
    let id: String
    let statement: String
    let strength: DiagnosticConclusionStrength
    let applicability: String
    let dependencyClaimIDs: [String]
    let evidenceIDs: [String]
    let boundary: String
}

struct DiagnosticConclusionTrustIssue: Identifiable, Codable, Equatable {
    enum Severity: String, Codable { case warning, blocker }
    let id: String
    let conclusionID: String
    let severity: Severity
    let message: String
}

enum DiagnosticConclusionTrustAudit {
    static func audit(_ conclusions: [DiagnosticConclusionContract], claims: [TechnicalClaim]) -> [DiagnosticConclusionTrustIssue] {
        let byID = Dictionary(uniqueKeysWithValues: claims.map { ($0.id, $0) })
        var issues: [DiagnosticConclusionTrustIssue] = []
        for conclusion in conclusions {
            if conclusion.applicability.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append(.init(id: "\(conclusion.id).applicability", conclusionID: conclusion.id, severity: .blocker, message: "Conclusion has no applicability boundary."))
            }
            if conclusion.boundary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append(.init(id: "\(conclusion.id).boundary", conclusionID: conclusion.id, severity: .blocker, message: "Conclusion has no evidence/causality boundary."))
            }
            if conclusion.strength == .strong && conclusion.evidenceIDs.isEmpty {
                issues.append(.init(id: "\(conclusion.id).evidence", conclusionID: conclusion.id, severity: .blocker, message: "Strong conclusion has no explicit evidence dependency."))
            }
            for claimID in conclusion.dependencyClaimIDs {
                guard let claim = byID[claimID] else {
                    issues.append(.init(id: "\(conclusion.id).missing.\(claimID)", conclusionID: conclusion.id, severity: .blocker, message: "Dependency claim \(claimID) is missing from the registry.")); continue
                }
                if claim.state == .disputed || claim.state == .superseded {
                    issues.append(.init(id: "\(conclusion.id).unsafe.\(claimID)", conclusionID: conclusion.id, severity: .blocker, message: "Dependency \(claimID) is \(claim.state.rawValue) and cannot silently support a strong conclusion."))
                } else if conclusion.strength == .strong && [.unverified, .predatorLabDerived, .communityObservation].contains(claim.state) {
                    issues.append(.init(id: "\(conclusion.id).weak.\(claimID)", conclusionID: conclusion.id, severity: .warning, message: "Strong conclusion depends on \(claim.state.rawValue) claim \(claimID); downgrade or obtain stronger evidence."))
                }
            }
        }
        return issues.sorted { $0.id < $1.id }
    }

    static let boundary = "This audit checks provenance wiring and applicability, not physical truth. Passing the audit does not prove causation or vehicle condition."
}

import Foundation

struct DiagnosticClaimDependencyIssue: Identifiable, Codable, Equatable {
    var id: String { "\(claimID)|\(downstreamUse)|\(message)" }
    let claimID: String
    let downstreamUse: String
    let message: String
    let blocksStrongInference: Bool
}

enum ClaimDependencyValidator {
    static func validate(_ backlog: VerificationBacklog) -> [DiagnosticClaimDependencyIssue] {
        backlog.claims.flatMap { claim in
            claim.downstreamUses.compactMap { use in
                guard claim.criticality >= .diagnostic else { return nil }
                switch claim.state {
                case .unverified, .predatorLabDerived, .communityObservation, .disputed:
                    return .init(claimID: claim.id, downstreamUse: use,
                                 message: "Diagnostic-critical dependency is \(claim.state.rawValue.lowercased()).",
                                 blocksStrongInference: claim.state == .unverified || claim.state == .disputed)
                default: return nil
                }
            }
        }
    }
}

import Foundation

enum KnowledgeMapTrustLevel: String, Codable { case verified, authored, quarantined, missing }
struct KnowledgeMapTrustAnnotation: Identifiable, Equatable {
    let id: String
    let nodeID: String
    let level: KnowledgeMapTrustLevel
    let explanation: String
}

enum KnowledgeMapTrustOverlay {
    static func topologyLevel(hasAuthoredTopology: Bool, hasExactVerifiedClaim: Bool) -> KnowledgeMapTrustLevel {
        if hasExactVerifiedClaim { return .verified }
        if hasAuthoredTopology { return .quarantined }
        return .missing
    }
    static let boundary = "Graph connectivity and spatial placement are navigation aids. Only claim-level evidence can promote a physical topology element to verified."
}

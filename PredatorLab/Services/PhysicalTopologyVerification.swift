import Foundation

enum TopologyElementKind: String, Codable, CaseIterable { case source, protection, relay, splice, conductor, connector, pin, load, ground, controllerIO, scannerSignal }

struct VerifiedTopologyElement: Identifiable, Codable, Equatable {
    let id: String
    let kind: TopologyElementKind
    let label: String
    let expectedMeasurement: String?
    let claimID: String?
    let verificationState: ClaimVerificationState
    let applicability: String
}

struct VerifiedCircuitTopology: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let elements: [VerifiedTopologyElement]
    let evidenceBoundary: String
    var hasUnverifiedElements: Bool { elements.contains { ![.oemVerified,.manufacturerVerified,.professionalCorroboration,.empiricallyVerified].contains($0.verificationState) } }
}

enum PhysicalTopologyVerificationEngine {
    static func validate(_ topology: VerifiedCircuitTopology, claims: [TechnicalClaim]) -> [String] {
        let ids = Set(claims.map(\.id))
        var warnings:[String]=[]
        for element in topology.elements {
            if let claimID=element.claimID, !ids.contains(claimID) { warnings.append("\(element.label) references unknown claim \(claimID).") }
            if element.expectedMeasurement != nil && element.claimID == nil { warnings.append("\(element.label) has an expected measurement without a claim-level source dependency.") }
        }
        return warnings
    }
}

import Foundation

enum ClaimVerificationState: String, Codable, CaseIterable {
    case oemVerified = "OEM verified"
    case manufacturerVerified = "Manufacturer verified"
    case professionalCorroboration = "Professional corroboration"
    case empiricallyVerified = "Empirically verified"
    case predatorLabDerived = "PredatorLab derived"
    case communityObservation = "Community observation"
    case unverified = "Unverified"
    case disputed = "Disputed"
    case superseded = "Superseded"
}

enum ClaimCriticality: Int, Codable, CaseIterable, Comparable {
    case descriptive = 0, service = 1, calibration = 2, diagnostic = 3, safety = 4
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    var label: String { ["Descriptive","Service","Calibration","Diagnostic","Safety"][rawValue] }
}

struct TechnicalClaim: Identifiable, Codable, Equatable {
    let id: String
    var statement: String
    var value: String?
    var unit: String?
    var applicability: String
    var source: TechnicalSource?
    var locator: String?
    var state: ClaimVerificationState
    var criticality: ClaimCriticality
    var downstreamUses: [String]
    var notes: String?
}

struct VerificationBacklog: Codable, Equatable {
    var claims: [TechnicalClaim]
    var criticalUnverified: [TechnicalClaim] { claims.filter { ($0.state == .unverified || $0.state == .predatorLabDerived) && $0.criticality >= .diagnostic }.sorted { $0.criticality > $1.criticality } }
    var verifiedCount: Int { claims.filter { [.oemVerified,.manufacturerVerified,.professionalCorroboration,.empiricallyVerified].contains($0.state) }.count }
}

enum TechnicalClaimRegistry {
    /// Conservative registry. A record-level source becomes a provenance claim only; it does not verify every sentence in the record.
    static func build(from engine: TechnicalQueryEngine) -> VerificationBacklog {
        var claims: [TechnicalClaim] = OfficialSourceRegistry.verifiedClaims
        func provenance(_ domain: String, _ name: String, _ sources: [TechnicalSource], criticality: ClaimCriticality) {
            if sources.isEmpty {
                claims.append(.init(id:"\(domain).\(name).provenance", statement:"\(name) technical record has no attached source.", value:nil, unit:nil, applicability:"2020–2022 Shelby GT500 unless narrowed by the record", source:nil, locator:nil, state:.unverified, criticality:criticality, downstreamUses:[domain], notes:"Record-level inventory; individual claims require claim-level verification."))
            } else {
                for (i, source) in sources.enumerated() {
                    let state: ClaimVerificationState
                    switch source.grade { case .a_factory: state = .oemVerified; case .b_professional: state = .professionalCorroboration; case .c_owner: state = .communityObservation; case .d_reference: state = .unverified }
                    claims.append(.init(id:"\(domain).\(name).source.\(i)", statement:"\(name) has attached provenance: \(source.title).", value:nil, unit:nil, applicability:"Record-level provenance only", source:source, locator:source.reference, state:state, criticality:criticality, downstreamUses:[domain], notes:"This verifies source attachment, not every technical statement in the record."))
                }
            }
        }
        engine.components.forEach { provenance("component",$0.name,$0.sources,criticality:.descriptive) }
        engine.circuits.forEach { provenance("circuit",$0.name,$0.sources,criticality:.diagnostic) }
        engine.sensors.forEach { provenance("sensor",$0.name,$0.sources,criticality:.diagnostic) }
        engine.dtcs.forEach { provenance("dtc",$0.code,$0.sources,criticality:.diagnostic) }
        engine.calibration.forEach { provenance("calibration",$0.name,$0.sources,criticality:.calibration) }
        engine.procedures.forEach { provenance("procedure",$0.name,$0.sources,criticality:.service) }
        for definition in InvestigationCatalog.all {
            for h in definition.authoredHypotheses ?? [] {
                claims.append(.init(id:"hypothesis.\(definition.id).\(h.id)", statement:h.mechanism, value:nil, unit:nil, applicability:definition.title, source:nil, locator:nil, state:.predatorLabDerived, criticality:.diagnostic, downstreamUses:[definition.id,h.title], notes:h.evidenceBoundary))
            }
        }
        return .init(claims: claims)
    }
}

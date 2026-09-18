import Foundation

/// Authored contract describing when a log contains a meaningful opportunity for an
/// investigation event to recur. Thresholds are PredatorLab rules unless a provenance
/// record explicitly upgrades them to a verified source.
struct OpportunityContract: Codable, Equatable {
    let investigationID: String
    let rpmTolerance: Double
    let minimumRPM: Double
    let minimumThrottle: Double
    let minimumDuration: TimeInterval
    let requiredChannels: [CanonicalChannel]
    let provenance: String
}

enum OpportunityContractCatalog {
    static let r04 = OpportunityContract(
        investigationID: InvestigationCatalog.r04.id,
        rpmTolerance: 750,
        minimumRPM: 2500,
        minimumThrottle: 75,
        minimumDuration: 0.15,
        requiredChannels: [.engineRPM, .throttleActual],
        provenance: "PredatorLab-authored validation heuristic; not an OEM threshold."
    )

    static func contract(for eventType: String) -> OpportunityContract? {
        let normalized = eventType.lowercased()
        if normalized.contains("r04") || normalized.contains("fuel") || normalized.contains("protection") { return r04 }
        return nil
    }
}

struct OpportunityReadiness: Codable, Equatable {
    let ready: Bool
    let missingChannels: [CanonicalChannel]
    let notes: [String]
}

enum OpportunityReadinessEngine {
    static func evaluate(log: ParsedLogData, contract: OpportunityContract) -> OpportunityReadiness {
        let missing = contract.requiredChannels.filter { ChannelResolver.resolve($0, in: log.channels) == nil }
        var notes: [String] = [contract.provenance]
        if !missing.isEmpty { notes.append("Opportunity detection withheld because required context is missing.") }
        return .init(ready: missing.isEmpty, missingChannels: missing, notes: notes)
    }
}

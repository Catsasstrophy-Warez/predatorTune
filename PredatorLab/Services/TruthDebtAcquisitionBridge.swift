import Foundation

struct EvidenceAcquisitionImpact: Identifiable, Codable, Equatable {
    let id: String
    let request: EvidenceGapRequest
    let matchingTruthIDs: [String]
    let totalDebtScore: Int
    let highConsequenceCount: Int
    let disputedCount: Int
    let leverageScore: Int
    let rationale: String
}

enum TruthDebtAcquisitionBridge {
    static let boundary = "Acquisition leverage estimates how much currently identified truth debt an exact artifact could address. It never verifies a claim, guarantees closure, or permits a forbidden substitute. Every assertion still requires claim-level acceptance review."

    static func prioritize(entries: [TechnicalTruthLedgerEntry], requests: [EvidenceGapRequest] = EvidenceGapAcquisitionPlanner.requests) -> [EvidenceAcquisitionImpact] {
        let debt = TechnicalTruthDebtEngine.rank(entries)
        return requests.map { request in
            let matches = debt.filter { matches(domain: $0.domain, statement: $0.statement, request: request) }
            let debtScore = matches.reduce(0) { $0 + $1.score }
            let high = matches.filter { $0.criticality >= .diagnostic }.count
            let disputed = matches.filter { $0.disposition == .disputed }.count
            let leverage = request.priority + min(500, debtScore / 4) + high * 12 + disputed * 15
            return .init(id: request.id, request: request, matchingTruthIDs: matches.map(\.truthID), totalDebtScore: debtScore,
                         highConsequenceCount: high, disputedCount: disputed, leverageScore: leverage,
                         rationale: matches.isEmpty ? "Strategic evidence gap; no currently compiled assertion maps narrowly enough to count as closable debt." : "Could support review of \(matches.count) unresolved assertion(s) if the exact artifact satisfies every acceptance criterion.")
        }.sorted { ($0.leverageScore, $0.request.priority, $0.id) > ($1.leverageScore, $1.request.priority, $1.id) }
    }

    private static func matches(domain: TechnicalTruthDomain, statement: String, request: EvidenceGapRequest) -> Bool {
        let s = statement.lowercased()
        switch request.domain {
        case .wiringTopology:
            return domain == .topology || domain == .circuit
        case .electricalPinpoint:
            return domain == .dtc || (domain == .circuit && (s.contains("expected") || s.contains("test")))
        case .magneRide:
            return s.contains("magne") || s.contains("vehicle dynamics") || s.contains("damper")
        case .abs:
            return s.contains("abs") || s.contains("wheel-speed") || s.contains("wheel speed")
        case .epas:
            return s.contains("epas") || s.contains("steering")
        case .sensors:
            return domain == .sensor
        case .engineClearances:
            return domain == .procedure && (s.contains("clearance") || s.contains("gap") || s.contains("endplay") || s.contains("bearing"))
        case .fuelControl:
            return (domain == .sensor || domain == .dtc || domain == .circuit) && (s.contains("fuel") || s.contains("pressure"))
        case .calibrationInternals:
            return domain == .calibration || (domain == .dtc && (s.contains("threshold") || s.contains("monitor") || s.contains("rationality")))
        }
    }
}

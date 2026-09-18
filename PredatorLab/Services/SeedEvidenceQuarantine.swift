import Foundation

/// Prevents legacy authored seed records from being mistaken for verified workshop topology.
/// A factory-sounding title/reference is not verification without an exact retrievable source and locator.
struct SeedEvidenceQuarantineFinding: Identifiable, Equatable {
    enum Severity: String { case review, blocked }
    let id: String
    let severity: Severity
    let record: String
    let reason: String
}

enum SeedEvidenceQuarantine {
    static func inspect(circuits: [CircuitRecord]) -> [SeedEvidenceQuarantineFinding] {
        var findings: [SeedEvidenceQuarantineFinding] = []
        for circuit in circuits {
            let hasPhysicalTopology = !circuit.path.isEmpty || !circuit.connectors.isEmpty
            guard hasPhysicalTopology else { continue }
            // Physical connector/pin/wire claims require exact source evidence. Legacy authored topology is quarantined
            // until claim-level verification can identify a retrievable source and exact locator.
            findings.append(.init(
                id: "topology.\(circuit.id.uuidString)",
                severity: .blocked,
                record: circuit.name,
                reason: "Authored physical topology must not be presented as verified connector/pin/conductor truth until each material element has exact claim-level source and locator evidence. A record-level WSM-looking citation is provenance, not pinout verification."
            ))
        }
        return findings
    }

    static let boundary = "Quarantine preserves useful authored troubleshooting structure while preventing unverified connector, pin, conductor, voltage, current, duty-cycle, and threshold details from masquerading as Ford workshop truth."
}

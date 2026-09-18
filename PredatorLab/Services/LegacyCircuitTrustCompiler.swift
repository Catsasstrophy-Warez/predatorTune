import Foundation

struct LegacyCircuitTrustFinding: Identifiable, Codable, Equatable {
    enum Severity: String, Codable { case information, quarantine, missing }
    let id: String
    let circuitName: String
    let subject: String
    let severity: Severity
    let reason: String
}

enum LegacyCircuitTrustCompiler {
    static func kind(for node: CircuitNode) -> TopologyClaimElementKind {
        let t = node.type.lowercased()
        if t.contains("fuse") { return .fuse }
        if t.contains("connector") { return .connector }
        if t.contains("pin") || t.contains("module") { return .module }
        if t.contains("splice") { return .splice }
        if t.contains("ground") { return .ground }
        if t.contains("wire") || t.contains("conductor") { return .conductor }
        return .harness
    }

    static func matrix(for circuit: CircuitRecord, claims: [TopologyEvidenceClaim] = TopologyEvidenceLedger.claims) -> TopologyVerificationMatrix {
        var authored: [(TopologyClaimElementKind, String)] = circuit.path
            .sorted { $0.sequence < $1.sequence }
            .map { (kind(for: $0), $0.designation) }
        for connector in circuit.connectors {
            authored.append((.connector, connector.name))
            for pin in connector.pins { authored.append((.pin, "\(connector.name) pin \(pin.number)")) }
        }
        return TopologyVerificationMatrixEngine.matrix(circuitID: circuit.id.uuidString, title: circuit.name, authoredDesignations: authored, claims: claims)
    }

    static func findings(for circuit: CircuitRecord) -> [LegacyCircuitTrustFinding] {
        var result: [LegacyCircuitTrustFinding] = []
        for node in circuit.path {
            if let reading = node.expectedReading, !reading.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                result.append(.init(id: "\(circuit.id).node.\(node.sequence).reading", circuitName: circuit.name, subject: "\(node.designation): \(reading)", severity: .quarantine, reason: "Expected measurement is legacy authored content without a claim-level source dependency. Preserve as authored guidance only until exact measurement conditions and source locator are verified."))
            }
            if let voltage = node.voltage, !voltage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                result.append(.init(id: "\(circuit.id).node.\(node.sequence).voltage", circuitName: circuit.name, subject: "\(node.designation): \(voltage)", severity: .quarantine, reason: "Voltage text is not promoted by record-level provenance. It requires an element/measurement claim with applicability and locator."))
            }
        }
        for connector in circuit.connectors {
            for pin in connector.pins {
                result.append(.init(id: "\(circuit.id).\(connector.name).pin.\(pin.number)", circuitName: circuit.name, subject: "\(connector.name) pin \(pin.number): \(pin.function)", severity: .quarantine, reason: "Legacy connector-pin assignment remains quarantined unless a claim-level topology source verifies this exact terminal and function."))
            }
        }
        for point in circuit.testPoints {
            result.append(.init(id: "\(circuit.id).test.\(point.name)", circuitName: circuit.name, subject: "\(point.name): \(point.expectedResult)", severity: .quarantine, reason: "Legacy test-point expectation requires exact procedure/test conditions and a retrievable locator before it can drive a strong diagnostic conclusion."))
        }
        return result
    }

    static func findings(for circuits: [CircuitRecord]) -> [LegacyCircuitTrustFinding] { circuits.flatMap(findings(for:)) }
    static let boundary = "Legacy circuit structure remains useful for navigation and hypothesis generation, but record-level provenance never verifies individual pins, conductors, voltages, currents, or expected readings."
}

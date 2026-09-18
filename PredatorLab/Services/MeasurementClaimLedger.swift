import Foundation

/// Stable claim identity for an expected measurement. The legacy text remains available,
/// but it cannot drive a strong conclusion until its claim dependencies are explicit.
struct MeasurementClaimContract: Identifiable, Codable, Equatable {
    let id: String
    let ownerID: String
    let ownerKind: String
    let label: String
    let authoredText: String
    let typedValue: EngineeringValue?
    let conditions: String?
    let applicability: String
    let technicalClaimIDs: [String]
    let state: ClaimVerificationState
    let source: TechnicalSource?
    let locator: String?
    let evidenceBoundary: String

    var isAdmittedForStrongDiagnosis: Bool {
        guard !applicability.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !technicalClaimIDs.isEmpty,
              source != nil,
              let locator, !locator.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return state == .oemVerified || state == .manufacturerVerified || state == .empiricallyVerified
    }
}

struct MeasurementClaimIssue: Identifiable, Codable, Equatable {
    let id: String
    let claimID: String
    let severity: String
    let message: String
}

enum MeasurementClaimLedger {
    static func fromLegacy(circuit: CircuitRecord) -> [MeasurementClaimContract] {
        var result: [MeasurementClaimContract] = []
        for node in circuit.path.sorted(by: { $0.sequence < $1.sequence }) {
            if let text = node.expectedReading?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                result.append(contract(id: "measurement.\(circuit.id.uuidString).node.\(node.sequence).expected", ownerID: circuit.id.uuidString, ownerKind: "circuit-node", label: "\(node.designation) expected reading", text: text))
            }
            if let text = node.voltage?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                result.append(contract(id: "measurement.\(circuit.id.uuidString).node.\(node.sequence).voltage", ownerID: circuit.id.uuidString, ownerKind: "circuit-node", label: "\(node.designation) voltage", text: text))
            }
        }
        for connector in circuit.connectors {
            for pin in connector.pins {
                if let text = pin.expectedVoltage?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                    result.append(contract(id: "measurement.\(circuit.id.uuidString).connector.\(slug(connector.name)).pin.\(pin.number).voltage", ownerID: circuit.id.uuidString, ownerKind: "connector-pin", label: "\(connector.name) pin \(pin.number) voltage", text: text))
                }
                if let text = pin.currentDraw?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                    result.append(contract(id: "measurement.\(circuit.id.uuidString).connector.\(slug(connector.name)).pin.\(pin.number).current", ownerID: circuit.id.uuidString, ownerKind: "connector-pin", label: "\(connector.name) pin \(pin.number) current", text: text))
                }
            }
        }
        for (index, point) in circuit.testPoints.enumerated() {
            result.append(contract(id: "measurement.\(circuit.id.uuidString).test.\(index).expected", ownerID: circuit.id.uuidString, ownerKind: "test-point", label: point.name, text: point.expectedResult))
        }
        return result
    }

    static func audit(_ contracts: [MeasurementClaimContract], technicalClaims: [TechnicalClaim]) -> [MeasurementClaimIssue] {
        let known = Set(technicalClaims.map(\.id))
        var issues: [MeasurementClaimIssue] = []
        for item in contracts {
            if item.technicalClaimIDs.isEmpty { issues.append(.init(id: "\(item.id).dependency", claimID: item.id, severity: "blocker", message: "Expected measurement has no technical-claim dependency.")) }
            for dependency in item.technicalClaimIDs where !known.contains(dependency) {
                issues.append(.init(id: "\(item.id).missing.\(dependency)", claimID: item.id, severity: "blocker", message: "Missing technical claim dependency \(dependency)."))
            }
            if item.source == nil || item.locator?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                issues.append(.init(id: "\(item.id).source", claimID: item.id, severity: "quarantine", message: "Expected measurement lacks an exact retrievable source locator."))
            }
            if item.state == .disputed || item.state == .superseded {
                issues.append(.init(id: "\(item.id).state", claimID: item.id, severity: "blocker", message: "Disputed/superseded measurement cannot support a strong conclusion."))
            }
        }
        return issues
    }

    private static func contract(id: String, ownerID: String, ownerKind: String, label: String, text: String) -> MeasurementClaimContract {
        .init(id: id, ownerID: ownerID, ownerKind: ownerKind, label: label, authoredText: text, typedValue: LegacyEngineeringValueParser.parse(text), conditions: nil, applicability: "Legacy authored GT500 record; exact model-year/configuration applicability unverified", technicalClaimIDs: [], state: .unverified, source: nil, locator: nil, evidenceBoundary: "Legacy expected measurement is authored guidance. It is quarantined until exact conditions, applicability, claim dependency, source and locator are verified.")
    }

    private static func slug(_ value: String) -> String { value.lowercased().map { $0.isLetter || $0.isNumber ? String($0) : "-" }.joined() }
}

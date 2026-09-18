import Foundation

enum TechnicalRecordKind: String, Codable { case sensor, dtc, procedure }

struct TechnicalRecordProvenanceReport: Identifiable, Codable {
    let id: String
    let kind: TechnicalRecordKind
    let title: String
    let sourceCount: Int
    let exactLocatorCount: Int
    let factorySourceCount: Int
    let unresolvedBoundaries: [String]
    let sourceSummaries: [String]
    let boundary: String
}

enum TechnicalRecordProvenanceEngine {
    static func report(sensor: SensorRecord) -> TechnicalRecordProvenanceReport {
        make(id: sensor.id.uuidString, kind: .sensor, title: sensor.name, sources: sensor.sources,
             extra: [sensor.relatedCircuit == nil ? "No related circuit is linked; physical electrical topology must not be inferred." : nil,
                     sensor.connectorRef?.isEmpty == false ? nil : "No connector reference is established for this sensor record.",
                     sensor.pidName == nil ? "No canonical PID identity is established." : nil].compactMap{$0})
    }
    static func report(dtc: DTCRecord) -> TechnicalRecordProvenanceReport {
        make(id: dtc.id.uuidString, kind: .dtc, title: "\(dtc.code) · \(dtc.title)", sources: dtc.sources,
             extra: dtc.sources.isEmpty ? ["Monitor thresholds and pinpoint steps are authored content until exact source locators establish them."] : ["A source attached to the DTC record does not independently verify every monitor threshold or pinpoint step."])
    }
    static func report(procedure: ProcedureRecord) -> TechnicalRecordProvenanceReport {
        var sources = procedure.sources
        if let workshop = procedure.workshopManual {
            sources.append(.init(title: workshop.manual, sourceType: "Workshop reference", reference: workshop.section, grade: .a_factory, confidence: .c4, notes: "Imported from the procedure workshop-reference field; exact step-level applicability still requires review."))
        }
        return make(id: procedure.id.uuidString, kind: .procedure, title: procedure.name, sources: sources,
                    extra: ["Procedure-level provenance does not automatically verify every torque value, tool, warning, or expected result."])
    }
    private static func make(id: String, kind: TechnicalRecordKind, title: String, sources: [TechnicalSource], extra: [String]) -> TechnicalRecordProvenanceReport {
        let locators = sources.filter { !$0.reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let summaries = sources.map { "\($0.grade.rawValue) · \($0.title) · \($0.reference.isEmpty ? "locator missing" : $0.reference)" }
        var unresolved = extra
        if sources.isEmpty { unresolved.append("No source is attached to this record.") }
        if !sources.isEmpty && locators.count < sources.count { unresolved.append("One or more attached sources lack an exact locator/reference.") }
        return .init(id: "\(kind.rawValue).\(id)", kind: kind, title: title, sourceCount: sources.count, exactLocatorCount: locators.count, factorySourceCount: sources.filter{$0.grade == .a_factory}.count, unresolvedBoundaries: unresolved, sourceSummaries: summaries, boundary: "This view exposes record provenance and gaps. It does not promote record-level sourcing into claim-level verification.")
    }
}

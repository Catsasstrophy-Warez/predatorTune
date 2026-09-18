import Foundation

enum TechnicalTruthDomain: String, Codable, CaseIterable { case circuit, topology, sensor, dtc, procedure, calibration }

enum TechnicalTruthDisposition: String, Codable, CaseIterable {
    case verified = "Verified"
    case quarantined = "Quarantined"
    case disputed = "Disputed"
    case superseded = "Superseded"
}

struct TechnicalTruthLedgerEntry: Identifiable, Codable, Equatable {
    let id: String
    let domain: TechnicalTruthDomain
    let ownerID: String
    let ownerTitle: String
    let statement: String
    let authoredValue: String?
    let unit: String?
    let condition: String?
    let applicability: String
    let state: ClaimVerificationState
    let disposition: TechnicalTruthDisposition
    let sourceTitle: String?
    let locator: String?
    let criticality: ClaimCriticality
    let boundary: String
}

struct TechnicalTruthLedgerSummary: Codable, Equatable {
    let total: Int
    let verified: Int
    let quarantined: Int
    let disputed: Int
    let superseded: Int
    let byDomain: [String:Int]
}

enum TechnicalTruthLedger {
    static let boundary = "Truth-ledger entries are individual technical assertions. Record-level provenance, typed dimensions, nearby verified facts, and migration into JSON do not upgrade an entry. Strong diagnostic/service use requires claim-level authority, applicability, and an exact retrievable locator."

    static func compile(engine: TechnicalQueryEngine) -> [TechnicalTruthLedgerEntry] {
        var out: [TechnicalTruthLedgerEntry] = []
        for circuit in engine.circuits {
            out += MeasurementClaimLedger.fromLegacy(circuit: circuit).map { claim in
                .init(id: claim.id, domain: .circuit, ownerID: circuit.id.uuidString, ownerTitle: circuit.name,
                      statement: claim.authoredText, authoredValue: claim.typedValue.map { String(describing: $0) }, unit: claim.typedValue?.unit,
                      condition: claim.conditions, applicability: claim.applicability,
                      state: claim.state, disposition: disposition(claim.state), sourceTitle: claim.source?.title,
                      locator: claim.locator, criticality: .diagnostic, boundary: claim.evidenceBoundary)
            }
        }
        for claim in TopologyEvidenceLedger.claims {
            out.append(.init(id: claim.id, domain: .topology, ownerID: claim.designation, ownerTitle: claim.designation,
                statement: claim.statement, authoredValue: nil, unit: nil, condition: nil, applicability: claim.applicability,
                state: claim.state, disposition: disposition(claim.state), sourceTitle: claim.source?.title, locator: claim.locator, criticality: .diagnostic,
                boundary: claim.limitations + " " + TopologyEvidenceLedger.boundary))
        }
        for sensor in engine.sensors {
            out.append(.init(id:"sensor.\(sensor.id).range", domain:.sensor, ownerID:sensor.id.uuidString, ownerTitle:sensor.name,
                statement:"Authored measurement range for \(sensor.name)", authoredValue:"\(sensor.minValue)…\(sensor.maxValue)", unit:sensor.units, condition:"Resolution: \(String(describing: sensor.resolution))",
                applicability:"Exact sensor/PID/controller strategy applicability requires claim-level verification", state:.unverified, disposition:.quarantined, sourceTitle:nil, locator:nil, criticality:.diagnostic,
                boundary:"Authored min/max range does not establish physical sensor limits, scanner PID scaling, controller clamping, or service acceptance limits."))
            if let voltage = sensor.voltage {
                out.append(.init(id:"sensor.\(sensor.id).electrical.voltage", domain:.sensor, ownerID:sensor.id.uuidString, ownerTitle:sensor.name, statement:"Authored sensor electrical voltage", authoredValue:voltage, unit:nil, condition:nil, applicability:"Exact connector/circuit applicability unverified", state:.unverified, disposition:.quarantined, sourceTitle:nil, locator:nil, criticality:.diagnostic, boundary:"Electrical supply/reference/signal claims require exact circuit and terminal evidence; nearby sensor sourcing does not verify them."))
            }
            for (index, value) in sensor.typicalValues.enumerated() {
                out.append(.init(id:"sensor.\(sensor.id).typical.\(index)", domain:.sensor, ownerID:sensor.id.uuidString,
                    ownerTitle:sensor.name, statement:"Expected \(sensor.name) value under \(value.condition)",
                    authoredValue:String(value.expectedValue), unit:sensor.units, condition:value.condition,
                    applicability:"2020–2022 Shelby GT500 unless narrowed by an exact source",
                    state:.unverified, disposition:.quarantined, sourceTitle:nil, locator:nil, criticality:.diagnostic,
                    boundary:"Legacy sensor typical value is authored reference content. Sensor existence, physical dimension, or a record-level source does not verify this operating value or scanner PID semantics."))
            }
        }
        for dtc in engine.dtcs {
            for (index, condition) in dtc.monitorLogic.enableConditions.enumerated() {
                out.append(.init(id:"dtc.\(dtc.id).enable.\(index)", domain:.dtc, ownerID:dtc.id.uuidString, ownerTitle:dtc.code, statement:"Monitor enable condition", authoredValue:condition, unit:nil, condition:dtc.monitorLogic.name, applicability:"Exact module strategy/calibration applicability unverified", state:.unverified, disposition:.quarantined, sourceTitle:nil, locator:nil, criticality:.diagnostic, boundary:"Authored monitor enable logic is calibration-sensitive and requires exact applicable Ford diagnostic/calibration authority."))
            }
            out.append(.init(id:"dtc.\(dtc.id).monitor.failureCondition", domain:.dtc, ownerID:dtc.id.uuidString, ownerTitle:dtc.code, statement:"Monitor failure condition", authoredValue:dtc.monitorLogic.failureCondition, unit:nil, condition:dtc.monitorLogic.testMethod, applicability:"Exact module strategy/calibration applicability unverified", state:.unverified, disposition:.quarantined, sourceTitle:nil, locator:nil, criticality:.diagnostic, boundary:"Monitor behavior is strategy-specific; DTC existence does not verify the authored failure condition."))
            out.append(.init(id:"dtc.\(dtc.id).monitor.rationality", domain:.dtc, ownerID:dtc.id.uuidString, ownerTitle:dtc.code, statement:"Monitor rationality rule", authoredValue:dtc.monitorLogic.rationality, unit:nil, condition:dtc.monitorLogic.testMethod, applicability:"Exact module strategy/calibration applicability unverified", state:.unverified, disposition:.quarantined, sourceTitle:nil, locator:nil, criticality:.diagnostic, boundary:"Rationality logic requires exact strategy-level authority and cannot be inferred from generic OBD behavior."))
            for (index, rule) in dtc.rationalityTests.enumerated() {
                out.append(.init(id:"dtc.\(dtc.id).rationality.\(index)", domain:.dtc, ownerID:dtc.id.uuidString, ownerTitle:dtc.code, statement:"Authored rationality test", authoredValue:rule, unit:nil, condition:nil, applicability:"Exact module strategy/calibration applicability unverified", state:.unverified, disposition:.quarantined, sourceTitle:nil, locator:nil, criticality:.diagnostic, boundary:"Authored rationality tests are hypotheses until exact applicable diagnostic authority is attached."))
            }
            out.append(.init(id:"dtc.\(dtc.id).failureThreshold", domain:.dtc, ownerID:dtc.id.uuidString, ownerTitle:dtc.code,
                statement:"Failure threshold: \(dtc.failureThreshold)", authoredValue:dtc.failureThreshold, unit:nil,
                condition:dtc.monitorLogic.enableConditions.joined(separator:"; "), applicability:"DTC \(dtc.code); exact model-year/module strategy applicability requires claim-level verification",
                state:.unverified, disposition:.quarantined, sourceTitle:nil, locator:nil, criticality:.diagnostic,
                boundary:"A DTC record source does not independently verify monitor thresholds, enable logic, rationality rules, or calibration strategy."))
            for (index, step) in dtc.pinpointTest.steps.enumerated() {
                out.append(.init(id:"dtc.\(dtc.id).pinpoint.\(index).expected", domain:.dtc, ownerID:dtc.id.uuidString, ownerTitle:dtc.code,
                    statement:"Pinpoint step \(step.order) expected result", authoredValue:step.expectedResult, unit:nil,
                    condition:step.instruction, applicability:"DTC \(dtc.code); exact WSM pinpoint-test applicability unverified",
                    state:.unverified, disposition:.quarantined, sourceTitle:nil, locator:nil, criticality:.diagnostic,
                    boundary:"Authored pinpoint expected result cannot be treated as Ford workshop procedure until the exact applicable pinpoint-test artifact and locator are attached."))
            }
            for (index, warning) in dtc.pinpointTest.safetyWarnings.enumerated() {
                out.append(.init(id:"dtc.\(dtc.id).pinpoint.warning.\(index)", domain:.dtc, ownerID:dtc.id.uuidString, ownerTitle:dtc.code, statement:"Pinpoint safety warning", authoredValue:warning, unit:nil, condition:dtc.pinpointTest.title, applicability:"Exact WSM pinpoint-test applicability unverified", state:.unverified, disposition:.quarantined, sourceTitle:nil, locator:nil, criticality:.safety, boundary:"Safety instructions require exact applicable workshop authority; authored warnings must not be represented as Ford WSM text."))
            }
            for (index, expected) in dtc.pinpointTest.expectedResults.enumerated() {
                out.append(.init(id:"dtc.\(dtc.id).pinpoint.expectedResult.\(index)", domain:.dtc, ownerID:dtc.id.uuidString, ownerTitle:dtc.code, statement:"Pinpoint expected result", authoredValue:expected, unit:nil, condition:dtc.pinpointTest.title, applicability:"Exact WSM pinpoint-test applicability unverified", state:.unverified, disposition:.quarantined, sourceTitle:nil, locator:nil, criticality:.diagnostic, boundary:"Expected results require exact test conditions and workshop locator before diagnostic admission."))
            }
        }
        for procedure in engine.procedures {
            for (index, warning) in procedure.safetyWarnings.enumerated() {
                out.append(.init(id:"procedure.\(procedure.id).warning.\(index)", domain:.procedure, ownerID:procedure.id.uuidString, ownerTitle:procedure.name, statement:"Procedure safety warning", authoredValue:warning, unit:nil, condition:nil, applicability:procedure.applicability.modelYears.map(String.init).joined(separator:", "), state:.unverified, disposition:.quarantined, sourceTitle:nil, locator:nil, criticality:.safety, boundary:"Safety warnings are individual service assertions and require exact applicable authority before being labeled OEM procedure."))
            }
            for (index, step) in procedure.steps.enumerated() {
                guard let torque = step.torqueSpec else { continue }
                let source = torque.source
                let exactLocator = source?.reference.trimmingCharacters(in:.whitespacesAndNewlines)
                let hasLocator = !(exactLocator ?? "").isEmpty
                let state: ClaimVerificationState = (source?.grade == .a_factory && hasLocator) ? .oemVerified : .unverified
                out.append(.init(id:"procedure.\(procedure.id).step.\(index).torque", domain:.procedure, ownerID:procedure.id.uuidString,
                    ownerTitle:procedure.name, statement:"Torque \(torque.component)", authoredValue:String(torque.value), unit:torque.units,
                    condition:"Procedure step \(step.order): \(step.instruction)", applicability:procedure.applicability.modelYears.map(String.init).joined(separator:", "),
                    state:state, disposition:disposition(state), sourceTitle:source?.title, locator:hasLocator ? exactLocator : nil, criticality:.service,
                    boundary:"Torque is an individual service claim. Admission here requires an attached factory source and locator; nearby procedure sourcing does not verify it."))
            }
        }
        for calibration in engine.calibration {
            out.append(.init(id:"calibration.\(calibration.id).stockValues", domain:.calibration, ownerID:calibration.id.uuidString,
                ownerTitle:calibration.name, statement:"Authored stock calibration table/value set", authoredValue:"\(calibration.stockValues.count) row(s)", unit:calibration.units,
                condition:"\(calibration.axes.xAxis) × \(calibration.axes.yAxis)", applicability:"Exact PCM/TCM strategy, OS and calibration ID required",
                state:.unverified, disposition:.quarantined, sourceTitle:nil, locator:nil, criticality:.calibration,
                boundary:"Authored calibration values are not production calibration truth. Exact strategy/OS identity and authoritative table semantics are required before use."))
        }
        return out.sorted { ($0.domain.rawValue, $0.ownerTitle, $0.id) < ($1.domain.rawValue, $1.ownerTitle, $1.id) }
    }

    static func summary(_ entries: [TechnicalTruthLedgerEntry]) -> TechnicalTruthLedgerSummary {
        .init(total:entries.count, verified:entries.filter{$0.disposition == .verified}.count,
              quarantined:entries.filter{$0.disposition == .quarantined}.count,
              disputed:entries.filter{$0.disposition == .disputed}.count,
              superseded:entries.filter{$0.disposition == .superseded}.count,
              byDomain:Dictionary(grouping:entries, by:{$0.domain.rawValue}).mapValues(\.count))
    }

    private static func disposition(_ state: ClaimVerificationState) -> TechnicalTruthDisposition {
        switch state {
        case .oemVerified,.manufacturerVerified,.professionalCorroboration,.empiricallyVerified: return .verified
        case .disputed: return .disputed
        case .superseded: return .superseded
        default: return .quarantined
        }
    }
}

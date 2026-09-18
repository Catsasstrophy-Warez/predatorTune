import Foundation

// Evidence Gap cluster, stage 1: defines WHAT is needed. Static catalog of the specific,
// named evidence artifacts PredatorLab is missing (per domain), with acceptance criteria
// and forbidden substitutions. Downstream: EvidenceGapClosureEngine assesses a submitted
// candidate against one of these requests; EvidenceGapPrioritizationEngine ranks the full
// list; EvidenceGapTruthEligibilityEngine bridges an accepted closure to the Technical
// Truth Ledger review queue.

enum EvidenceGapDomain: String, Codable, CaseIterable { case wiringTopology, electricalPinpoint, magneRide, abs, epas, sensors, engineClearances, fuelControl, calibrationInternals }
enum EvidenceArtifactType: String, Codable { case workshopManual, wiringDiagram, pinpointTest, manufacturerBulletin, calibrationDefinition, engineeringSpecification }

struct EvidenceGapRequest: Identifiable, Codable, Equatable {
    let id: String
    let domain: EvidenceGapDomain
    let priority: Int
    let artifact: EvidenceArtifactType
    let exactNeed: String
    let acceptanceCriteria: [String]
    let forbiddenSubstitutions: [String]
}

enum EvidenceGapAcquisitionPlanner {
    static let requests: [EvidenceGapRequest] = [
        .init(id:"gap.wiring.production",domain:.wiringTopology,priority:100,artifact:.wiringDiagram,exactNeed:"Production 2020, 2021, and 2022 GT500 wiring diagrams with connector views and circuit identifiers.",acceptanceCriteria:["Exact model year/applicability","Connector designation and terminal locator","Circuit/conductor identity","Retrievable source locator"],forbiddenSubstitutions:["Ford Performance control-pack harness","forum pinout","adjacent Mustang trim wiring"]),
        .init(id:"gap.electrical.pinpoint",domain:.electricalPinpoint,priority:98,artifact:.pinpointTest,exactNeed:"Ford WSM pinpoint tests for GT500 powertrain/electrical faults represented in the app.",acceptanceCriteria:["WSM section/test identifier","step-by-step decision path","specified measurement conditions","model-year applicability"],forbiddenSubstitutions:["generic OBD advice","community troubleshooting tree"]),
        .init(id:"gap.magneride",domain:.magneRide,priority:96,artifact:.pinpointTest,exactNeed:"GT500 Vehicle Dynamics/MagneRide diagnostic procedures, wiring, sensor/damper tests, and DTC-specific pinpoint paths.",acceptanceCriteria:["Ford workshop source","exact DTC/test applicability","measurement conditions","connector/test-point locator"],forbiddenSubstitutions:["generic MagneRide articles","other Ford model procedures"]),
        .init(id:"gap.abs",domain:.abs,priority:94,artifact:.pinpointTest,exactNeed:"GT500 ABS diagnostic and electrical pinpoint procedures including wheel-speed and module/network diagnostics.",acceptanceCriteria:["GT500/model-year applicability","Ford workshop locator","test conditions","expected result"],forbiddenSubstitutions:["software-only SSM used as wiring proof"]),
        .init(id:"gap.epas",domain:.epas,priority:92,artifact:.pinpointTest,exactNeed:"GT500 EPAS diagnostic, power/ground/network and sensor pinpoint procedures.",acceptanceCriteria:["GT500/model-year applicability","Ford WSM locator","connector/test point","expected measurement"],forbiddenSubstitutions:["generic S550 procedure without applicability evidence"]),
        .init(id:"gap.sensors",domain:.sensors,priority:90,artifact:.workshopManual,exactNeed:"Sensor-by-sensor GT500 removal, connector, reference voltage/signal, test-condition and validation procedures.",acceptanceCriteria:["sensor identity","exact model-year applicability","test condition","expected measurement","source locator"],forbiddenSubstitutions:["scanner-label semantics treated as physical sensor proof"]),
        .init(id:"gap.engine.clearances",domain:.engineClearances,priority:88,artifact:.engineeringSpecification,exactNeed:"Predator factory rebuild specifications: bearing clearances, endplay, ring gaps, piston-to-wall, valve-guide and related service limits.",acceptanceCriteria:["Predator/GT500-specific source","nominal/service-limit distinction","units","measurement method/condition"],forbiddenSubstitutions:["Coyote/GT350 values","builder preference","aftermarket recommendation"]),
        .init(id:"gap.fuel.control",domain:.fuelControl,priority:86,artifact:.pinpointTest,exactNeed:"Production GT500 low/high-side fuel-control diagnostics, pressure command/feedback semantics and electrical tests.",acceptanceCriteria:["production GT500 applicability","Ford diagnostic source","PID/test semantics","specified conditions"],forbiddenSubstitutions:["M-6017-M52SC control-pack architecture","modified return-system assumptions"]),
        .init(id:"gap.calibration",domain:.calibrationInternals,priority:84,artifact:.calibrationDefinition,exactNeed:"Authoritative definitions/applicability for GT500 calibration tables, scanner channels, controller arbitration and protection logic represented in PredatorLab.",acceptanceCriteria:["exact controller/strategy applicability","definition source","units/axes","revision context"],forbiddenSubstitutions:["table name guessed from adjacent strategy","forum definition presented as OEM fact"])
    ]
    static var ordered: [EvidenceGapRequest] { requests.sorted { $0.priority > $1.priority } }
    static let boundary = "A gap is complete only when the requested artifact satisfies its acceptance criteria. Adjacent-platform material can guide research but cannot silently graduate a GT500 claim to verified."
}

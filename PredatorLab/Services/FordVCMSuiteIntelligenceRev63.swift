import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening" lineage
// this project ported from (see HANDOFF.md), NOT this app's own version history.
// Status: Current (foundational file of the Ford VCM Suite research cluster).
// Rev63: Ford/VCM Suite calibration intelligence. Public documentation establishes
// workflow/capability boundaries only. It does not establish GT500 strategy-specific
// parameter names, stock values, axes, limits, or safe calibration values.
// Establishes the core primitives (capability registry, Scanner Semantic Firewall, torque
// arbitration graph scaffold, tune validation, heat-soak comparison). Rev64 builds research
// atlas/channel-pack tooling on these primitives; Rev65 adds ingestion + truth-debt
// tracking on top of Rev63+64; Rev66 adds risk/blast-radius/explainer reasoning on all
// three. All four are additive layers, not duplicates of each other.

enum VCMSuiteEvidenceClass: String, Codable, CaseIterable {
    case hpTunersDocumented = "HP Tuners documented"
    case hpTunersExposed = "HP Tuners exposed; semantics incomplete"
    case fordDocumented = "Ford documented"
    case tremecDocumented = "TREMEC documented"
    case professionalInterpretation = "Professional tuner interpretation"
    case empiricalObservation = "Configuration-bound empirical observation"
    case predatorLabInference = "PredatorLab engineering inference"
    case userDefinedXDF = "User-defined/XDF definition"
    case unknown = "Unknown/proprietary"
}

enum FordCalibrationDomain: String, Codable, CaseIterable {
    case operatingSystem = "Operating System"
    case driverDemand = "Driver Demand"
    case torqueArbitration = "Torque Arbitration"
    case airflow = "Airflow"
    case electronicThrottle = "Electronic Throttle"
    case supercharger = "Supercharger / Boost"
    case fuel = "Fuel System"
    case spark = "Spark / Knock"
    case vct = "VCT"
    case thermalProtection = "Thermal / Protection"
    case rpmSpeed = "RPM / Speed"
    case engineDiagnostics = "Engine Diagnostics"
    case transmission = "Transmission"
    case transmissionDiagnostics = "Transmission Diagnostics"
    case system = "System"
    case speedometer = "Speedometer"
}

struct VCMSuiteCapabilityRecord: Identifiable, Codable, Equatable {
    let id: String
    let feature: String
    let productArea: String
    let documentedBehavior: String
    let evidenceClass: VCMSuiteEvidenceClass
    let sourceLocator: String
    let gt500Boundary: String
}

enum VCMSuitePublicCapabilityRegistry {
    static let records: [VCMSuiteCapabilityRecord] = [
        .init(id:"vcm.navigator", feature:"Parameter Navigator", productArea:"VCM Editor", documentedBehavior:"Search/filter available parameters by name, data type, parameter group, and Basic/Advanced classification.", evidenceClass:.hpTunersDocumented, sourceLocator:"HP Tuners Docs > VCM Editor > Parameter Navigator", gt500Boundary:"This documents Editor organization, not the exact parameter inventory exposed by a particular 2020–2022 GT500 strategy."),
        .init(id:"vcm.compare", feature:"Tune Compare", productArea:"VCM Editor", documentedBehavior:"Open a compare tune and identify/import parameters that differ through the Tune Template workflow.", evidenceClass:.hpTunersDocumented, sourceLocator:"HP Tuners Docs > Tune Template Editor > Importing Compare File Differences", gt500Boundary:"A difference proves represented calibration data differ; it does not prove physical meaning, safety, or causal effect."),
        .init(id:"vcm.scanner.config", feature:"Scanner XML Configuration", productArea:"VCM Scanner", documentedBehavior:"Saved channel configurations include Parameter ID, Parameter Source, Polling Interval, and applied Transform.", evidenceClass:.hpTunersDocumented, sourceLocator:"HP Tuners Docs > VCM Scanner > Channels", gt500Boundary:"Scanner metadata does not independently verify the physical semantics of a Ford manufacturer-specific parameter."),
        .init(id:"vcm.scanner.polling", feature:"Polling Budget", productArea:"VCM Scanner", documentedBehavior:"Additional polled parameters can reduce return rate; broadcast parameters avoid polling overhead and external inputs do not consume vehicle polling bandwidth.", evidenceClass:.hpTunersDocumented, sourceLocator:"HP Tuners Docs > VCM Scanner > Channels > Scanner Performance", gt500Boundary:"PredatorLab may optimize experiment design but must measure actual acquisition performance rather than invent a promised sample rate."),
        .init(id:"vcm.scanner.filters", feature:"Expression Filters", productArea:"VCM Scanner", documentedBehavior:"Layout filters can use Math-Parameter-style expressions and time-window functions such as avg() for playback/live filtering subject to documented limitations.", evidenceClass:.hpTunersDocumented, sourceLocator:"HP Tuners Docs > VCM Scanner > Layouts > Filters", gt500Boundary:"A filter selects evidence; it does not establish controller causality."),
        .init(id:"vcm.udp", feature:"User Defined Parameters", productArea:"VCM Editor", documentedBehavior:"Optional UDP support can import TunerPro XDF-defined switches, scalars, and tables within allowed addresses when the controller OS supports them.", evidenceClass:.hpTunersDocumented, sourceLocator:"HP Tuners Docs > User Defined Parameter Guide", gt500Boundary:"An imported XDF definition is not an HP Tuners native definition, Ford authority, or proof that the controller strategy uses the parameter as interpreted."),
        .init(id:"vcm.gt500.tcm", feature:"2020–2022 GT500 TR_C75 TCM support", productArea:"Vehicle Support", documentedBehavior:"HP Tuners public supported-vehicles list identifies the 2020–2022 Shelby GT500 TR_C75 TCM as separately supported/licensed.", evidenceClass:.hpTunersDocumented, sourceLocator:"HP Tuners Supported Vehicles > Ford", gt500Boundary:"Support/licensing does not disclose the exact TR_C75 calibration table inventory or safe values."),
        .init(id:"vcm.tc298b", feature:"5.2L Predator Control Pack PCM support", productArea:"Vehicle Support", documentedBehavior:"HP Tuners lists the 5.2L GT500 Predator Control Pack PCM TC-298B separately from the production GT500 controller lineage.", evidenceClass:.hpTunersDocumented, sourceLocator:"HP Tuners Supported Vehicles > Ford > FRPP", gt500Boundary:"TC-298B semantics and values must not be silently transferred to a production GT500 PCM.")
    ]
}

struct ScannerSemanticBinding: Identifiable, Codable, Equatable {
    let id: UUID
    let controller: TuningControllerFamily
    let strategyID: String?
    let parameterID: String
    let parameterSource: String
    let pollingInterval: String?
    let displayName: String?
    let canonicalSignalID: String?
    let units: String?
    let transformDescription: String?
    let authority: VCMSuiteEvidenceClass
    let semanticsReviewed: Bool
    let locator: String?
}

struct CanonicalSignalAdmission: Codable, Equatable {
    let admitted: Bool
    let blockers: [String]
    let boundary: String
}

enum FordScannerSemanticFirewall {
    static func assess(_ binding: ScannerSemanticBinding, expectedController: TuningControllerFamily, requiredStrategy: String? = nil) -> CanonicalSignalAdmission {
        var blockers:[String] = []
        if binding.controller != expectedController { blockers.append("Controller family mismatch") }
        if let requiredStrategy, binding.strategyID != requiredStrategy { blockers.append("Strategy mismatch") }
        if binding.parameterID.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty { blockers.append("Parameter ID missing") }
        if binding.canonicalSignalID?.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty != false { blockers.append("Canonical physical signal is not assigned") }
        if !binding.semanticsReviewed { blockers.append("Signal semantics have not completed review") }
        if binding.locator?.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty != false { blockers.append("Claim-level semantic locator missing") }
        if binding.authority == .unknown { blockers.append("Semantic authority is unknown") }
        return .init(admitted:blockers.isEmpty, blockers:blockers, boundary:"Admission means this exact controller/strategy Scanner parameter may represent the reviewed canonical signal. It does not prove sensor accuracy, calibration causality, or safe tuning limits.")
    }
}

enum TorqueArbitrationNodeKind: String, Codable { case demand, constraint, request, actuator, observation }
struct TorqueArbitrationNode: Identifiable, Codable, Equatable { let id:String; let title:String; let kind:TorqueArbitrationNodeKind; let evidenceClass:VCMSuiteEvidenceClass; let verifiedForStrategy:Bool }
struct TorqueArbitrationEdge: Identifiable, Codable, Equatable { let id:String; let from:String; let to:String; let relationship:String; let evidenceClass:VCMSuiteEvidenceClass; let verifiedForStrategy:Bool }
struct TorqueArbitrationGraph: Codable, Equatable { let controller:TuningControllerFamily; let strategyID:String?; let nodes:[TorqueArbitrationNode]; let edges:[TorqueArbitrationEdge]; let boundary:String }

enum FordTorqueArbitrationGraphBuilder {
    static func conceptual(controller:TuningControllerFamily, strategyID:String? = nil) -> TorqueArbitrationGraph {
        let n:[TorqueArbitrationNode] = [
            .init(id:"driver",title:"Driver demand",kind:.demand,evidenceClass:.predatorLabInference,verifiedForStrategy:false),
            .init(id:"engineConstraints",title:"Engine / protection constraints",kind:.constraint,evidenceClass:.predatorLabInference,verifiedForStrategy:false),
            .init(id:"transmission",title:"Transmission coordination/request",kind:.constraint,evidenceClass:.predatorLabInference,verifiedForStrategy:false),
            .init(id:"traction",title:"Traction / stability constraint",kind:.constraint,evidenceClass:.predatorLabInference,verifiedForStrategy:false),
            .init(id:"finalRequest",title:"Final torque request",kind:.request,evidenceClass:.predatorLabInference,verifiedForStrategy:false),
            .init(id:"actuation",title:"Air / throttle / spark / fuel / boost actuation",kind:.actuator,evidenceClass:.predatorLabInference,verifiedForStrategy:false),
            .init(id:"delivered",title:"Observed delivered response",kind:.observation,evidenceClass:.predatorLabInference,verifiedForStrategy:false)
        ]
        let e:[TorqueArbitrationEdge] = [
            .init(id:"driver-final",from:"driver",to:"finalRequest",relationship:"candidate influence",evidenceClass:.predatorLabInference,verifiedForStrategy:false),
            .init(id:"engine-final",from:"engineConstraints",to:"finalRequest",relationship:"candidate constraint",evidenceClass:.predatorLabInference,verifiedForStrategy:false),
            .init(id:"trans-final",from:"transmission",to:"finalRequest",relationship:"candidate coordination",evidenceClass:.predatorLabInference,verifiedForStrategy:false),
            .init(id:"traction-final",from:"traction",to:"finalRequest",relationship:"candidate constraint",evidenceClass:.predatorLabInference,verifiedForStrategy:false),
            .init(id:"final-actuation",from:"finalRequest",to:"actuation",relationship:"candidate realization path",evidenceClass:.predatorLabInference,verifiedForStrategy:false),
            .init(id:"actuation-delivered",from:"actuation",to:"delivered",relationship:"observed response path",evidenceClass:.predatorLabInference,verifiedForStrategy:false)
        ]
        return .init(controller:controller,strategyID:strategyID,nodes:n,edges:e,boundary:"This is a PredatorLab research scaffold, not a reverse-engineered Ford torque model. Edges become strategy-specific only after exact evidence review.")
    }
}

struct TuneValidationEnvelope: Identifiable, Codable, Equatable {
    let id: UUID
    let buildRevisionID: UUID?
    let pcmCalibrationID: UUID?
    let tcmCalibrationID: UUID?
    let fuelDescription: String?
    let ambientDescription: String?
    let testMode: String
    let startECT: Double?
    let startIAT2: Double?
    let startDCTTemperature: Double?
    let rpmRange: ClosedRange<Double>?
    let repeatedRuns: Int
    let dtcFree: Bool?
    let acquisitionQualityAccepted: Bool
    let comparabilityAccepted: Bool
}

enum TuneValidationVerdict: String, Codable { case promising, validatedWithinTestedEnvelope, regressionDetected, inconclusive, unsafeAbortObserved, insufficientData }
struct TuneValidationAssessment: Codable, Equatable { let verdict:TuneValidationVerdict; let blockers:[String]; let boundary:String }

enum FordTuneValidationEngine {
    static func assess(_ e:TuneValidationEnvelope, unsafeAbortObserved:Bool, regressionObserved:Bool) -> TuneValidationAssessment {
        var blockers:[String]=[]
        if unsafeAbortObserved { return .init(verdict:.unsafeAbortObserved,blockers:["Abort/safety event observed"],boundary:boundary) }
        if regressionObserved { return .init(verdict:.regressionDetected,blockers:["Regression observed in tested envelope"],boundary:boundary) }
        if !e.acquisitionQualityAccepted { blockers.append("Acquisition quality not accepted") }
        if !e.comparabilityAccepted { blockers.append("Comparability not accepted") }
        if e.repeatedRuns < 2 { blockers.append("Repeatability evidence insufficient") }
        if e.dtcFree != true { blockers.append("DTC-free state not established") }
        if !blockers.isEmpty { return .init(verdict:.insufficientData,blockers:blockers,boundary:boundary) }
        return .init(verdict:.validatedWithinTestedEnvelope,blockers:[],boundary:boundary)
    }
    private static let boundary="Validation applies only to the recorded hardware, calibration, fuel, environment and operating envelope. It is not universal tune approval and does not prove component safety outside that envelope."
}

struct ThermalRunFingerprint: Identifiable, Codable, Equatable {
    let id:UUID; let startedAt:Date; let startIAT2:Double?; let peakIAT2:Double?; let recoveryIAT2:Double?
    let startECT:Double?; let peakECT:Double?; let startDCT:Double?; let peakDCT:Double?; let elapsed:Double
}
struct HeatSoakComparison: Codable, Equatable { let runCount:Int; let iat2PeakTrend:[Double]; let dctPeakTrend:[Double]; let comparable:Bool; let boundary:String }
enum HeatSoakAnalysisEngine {
    static func compare(_ runs:[ThermalRunFingerprint]) -> HeatSoakComparison {
        .init(runCount:runs.count,iat2PeakTrend:runs.compactMap(\.peakIAT2),dctPeakTrend:runs.compactMap(\.peakDCT),comparable:runs.count >= 2,boundary:"Thermal trend describes observed repeated-run behavior. It does not by itself identify a calibration cause or safe thermal limit.")
    }
}

struct CalibrationResearchBlocker: Identifiable, Codable, Equatable { let id:String; let conclusion:String; let missingSemanticIDs:[String]; let candidateAcquisitionTargetIDs:[String]; let priority:Int; let boundary:String }
enum CalibrationResearchRouterRev63 {
    static func route(conclusion:String, missingSemanticIDs:[String], debt:[CalibrationTruthDebtItem]) -> CalibrationResearchBlocker {
        let matching=debt.filter{missingSemanticIDs.contains($0.semanticID)}
        let targets=Array(Set(matching.flatMap(\.acquisitionTargetIDs))).sorted()
        let priority=matching.map(\.score).max() ?? 0
        return .init(id:"research."+conclusion.lowercased().replacingOccurrences(of:" ",with:"."),conclusion:conclusion,missingSemanticIDs:missingSemanticIDs,candidateAcquisitionTargetIDs:targets,priority:priority,boundary:"Routing identifies evidence that could make blocked calibration semantics eligible for review. It does not verify the conclusion or promise that an artifact will resolve it.")
    }
}

import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening" lineage
// this project ported from (see HANDOFF.md), NOT this app's own version history.
// Status: Current. Builds on Rev63's primitives (capability registry, Scanner Semantic
// Firewall) to add the research question atlas, channel-pack requirements, experiment
// templates, and the VCM definition acquisition matrix. See Rev65 for ingestion/truth-debt
// tooling and Rev66 for risk/blast-radius reasoning built on top of this file.
// Rev64 deepens Ford/VCM Suite research without manufacturing strategy-specific tables,
// stock values, limits, or safe calibration values. Public HP Tuners capabilities define
// workflow contracts; exact GT500/TR_C75 semantics require applicable artifacts and review.

enum FordVCMResearchState: String, Codable, CaseIterable {
    case documentedCapability = "Documented VCM Suite capability"
    case observedInApplicableFile = "Observed in applicable file"
    case semanticsUnderReview = "Semantics under review"
    case reviewedSemantic = "Reviewed semantic"
    case configurationBoundEmpirical = "Configuration-bound empirical"
    case unresolved = "Unresolved / proprietary"
}

struct VCMParameterIdentity: Hashable, Codable {
    let controller: TuningControllerFamily
    let operatingSystemID: String?
    let strategyID: String?
    let parameterID: String?
    let navigatorPath: [String]
    let displayName: String
    let dataType: String
    let units: String?
    let axisSignatures: [String]
    let definitionOrigin: VCMSuiteEvidenceClass

    var semanticKey: String {
        ([controller.rawValue, operatingSystemID ?? "?", strategyID ?? "?", parameterID ?? "?", dataType, units ?? "?"] + navigatorPath + axisSignatures).joined(separator: "|")
    }
}

struct VCMParameterObservation: Identifiable, Codable {
    let id: UUID
    let identity: VCMParameterIdentity
    let sourceArtifactID: UUID?
    let locator: String
    let researchState: FordVCMResearchState
    let physicalInterpretation: String?
    let relatedScannerSemanticIDs: [String]
    let warnings: [String]
}

struct FordCalibrationResearchDomain: Identifiable, Codable {
    let id: String
    let title: String
    let controller: TuningControllerFamily
    let domain: FordCalibrationDomain
    let questions: [String]
    let requiredEvidence: [String]
    let forbiddenInference: [String]
}

enum FordGT500CalibrationResearchAtlas {
    static let domains: [FordCalibrationResearchDomain] = [
        .init(id:"gt500.demand", title:"Driver Demand & Requested Torque", controller:.gt500PCM, domain:.driverDemand,
              questions:["Which applicable parameters shape driver-requested torque?","Which Scanner signals expose request, arbitration, or intervention for this strategy?","How do drive mode and pedal state alter the observed request path?"],
              requiredEvidence:["Applicable production GT500 HPT/Editor inventory","Matching Scanner XML/HPL","Exact controller/OS/strategy identity"],
              forbiddenInference:["Do not transfer TC-298B names or values","Do not infer torque semantics from a display label alone"]),
        .init(id:"gt500.air", title:"Airflow, Load, Throttle & Supercharger", controller:.gt500PCM, domain:.airflow,
              questions:["Which exposed characteristics represent airflow/load estimation?","Which applicable channels distinguish commanded throttle closure from airflow limitation?","Which boost-related observations are measured, calculated, commanded, or inferred?"],
              requiredEvidence:["Applicable Editor inventory","Scanner parameter IDs/sources/transforms","Configuration-bound boost/airflow logs"],
              forbiddenInference:["Do not treat scanner boost labels as sensor truth without semantics","Do not publish universal pulley or airflow values"]),
        .init(id:"gt500.fuel", title:"Fuel, Lambda & Injector Control", controller:.gt500PCM, domain:.fuel,
              questions:["Which applicable parameters influence commanded mixture and fuel control?","Which Scanner channels can be reviewed as commanded versus measured lambda?","What evidence distinguishes calibration demand from fuel-system inability?"],
              requiredEvidence:["Applicable parameter inventory","Verified lambda/fuel-pressure channel semantics","Build/fuel/injector/pump configuration"],
              forbiddenInference:["Do not tune around unresolved fuel-pressure faults","Do not infer injector headroom from one unlabeled PID"]),
        .init(id:"gt500.spark", title:"Spark, Knock & Combustion Response", controller:.gt500PCM, domain:.spark,
              questions:["Which Scanner semantics distinguish commanded spark, corrections, and knock observations?","Which Editor characteristics are actually exposed on the applicable strategy?","How repeatable are corrections across comparable pulls?"],
              requiredEvidence:["Applicable HPT/Editor inventory","Reviewed Scanner semantics","Repeated comparable logs"],
              forbiddenInference:["Do not convert correlation into knock causality","Do not manufacture safe spark targets"]),
        .init(id:"gt500.thermal", title:"Thermal Protection & Repeatability", controller:.gt500PCM, domain:.thermalProtection,
              questions:["Which temperature signals and protection indicators are semantically verified?","Does intervention chronology repeat at comparable thermal state?","Which calibration regions are actually exposed for the applicable strategy?"],
              requiredEvidence:["IAT/ECT/oil semantics as available","Torque/throttle/spark intervention evidence","Heat-soak cohort"],
              forbiddenInference:["Do not invent Ford protection thresholds","Do not call a thermal association causal without supporting control evidence"]),
        .init(id:"trc75.shift", title:"TR_C75 Shift Scheduling & Handoff", controller:.trC75, domain:.transmission,
              questions:["Which shift characteristics are exposed in the applicable TCM file?","Which channels describe requested gear, actual gear, shift state, and handoff?","How do shift fingerprints change with thermal state and tune revision?"],
              requiredEvidence:["Applicable TR_C75 HPT/Editor inventory","TR_C75 Scanner XML/HPL","Repeated shift cohorts"],
              forbiddenInference:["Do not infer clutch pressure from acceleration alone","Do not transfer generic TREMEC capability into Ford calibration semantics"]),
        .init(id:"trc75.protection", title:"TR_C75 Thermal / Diagnostic Protection", controller:.trC75, domain:.transmissionDiagnostics,
              questions:["Which diagnostic/protection characteristics are exposed?","Which logged observations precede a shift or torque intervention?","What is Ford-documented service behavior versus tuner interpretation?"],
              requiredEvidence:["Applicable TCM inventory","Ford service evidence","Semantically reviewed TCM logs"],
              forbiddenInference:["Do not invent temperature or clutch protection limits","Do not treat temporal first-out as proof of root cause"])
    ]
}

enum VCMChannelPurpose: String, Codable, CaseIterable { case identity, driverDemand, airflowBoost, fuelLambda, sparkKnock, thermal, torqueIntervention, transmissionShift, tractionChassis, externalReference }
enum VCMTemporalPriority: String, Codable { case eventCritical, medium, slowState, contextOnly }

struct VCMChannelRequirement: Identifiable, Codable {
    let id: String
    let purpose: VCMChannelPurpose
    let canonicalSemanticID: String
    let temporalPriority: VCMTemporalPriority
    let required: Bool
    let semanticRequirement: String
}

struct VCMExperimentChannelPack: Identifiable, Codable {
    let id: String
    let title: String
    let controller: TuningControllerFamily
    let requirements: [VCMChannelRequirement]
    let boundary: String
}

enum GT500VCMChannelPackLibrary {
    static let highLoad = VCMExperimentChannelPack(id:"gt500.highload", title:"GT500 High-Load Evidence Pack", controller:.gt500PCM, requirements:[
        .init(id:"rpm",purpose:.identity,canonicalSemanticID:"engine.speed",temporalPriority:.eventCritical,required:true,semanticRequirement:"Reviewed engine-speed semantic"),
        .init(id:"pedal",purpose:.driverDemand,canonicalSemanticID:"driver.pedal",temporalPriority:.eventCritical,required:true,semanticRequirement:"Reviewed driver-demand/pedal semantic"),
        .init(id:"throttle",purpose:.airflowBoost,canonicalSemanticID:"throttle.command_or_angle",temporalPriority:.eventCritical,required:true,semanticRequirement:"Commanded vs measured identity must be explicit"),
        .init(id:"lambda",purpose:.fuelLambda,canonicalSemanticID:"lambda.commanded_and_or_measured",temporalPriority:.eventCritical,required:true,semanticRequirement:"Commanded/measured source and units must be explicit"),
        .init(id:"spark",purpose:.sparkKnock,canonicalSemanticID:"spark.command_or_delivered",temporalPriority:.eventCritical,required:true,semanticRequirement:"Exact applicable Scanner semantic"),
        .init(id:"knock",purpose:.sparkKnock,canonicalSemanticID:"knock.correction_or_observation",temporalPriority:.eventCritical,required:false,semanticRequirement:"Do not infer meaning from label"),
        .init(id:"iat2",purpose:.thermal,canonicalSemanticID:"charge.temperature",temporalPriority:.medium,required:true,semanticRequirement:"Sensor/source identity reviewed"),
        .init(id:"ect",purpose:.thermal,canonicalSemanticID:"coolant.temperature",temporalPriority:.slowState,required:true,semanticRequirement:"Reviewed coolant-temperature semantic"),
        .init(id:"torque",purpose:.torqueIntervention,canonicalSemanticID:"torque.request_or_limit",temporalPriority:.eventCritical,required:false,semanticRequirement:"Request/limit/delivered role must be proven for strategy")
    ], boundary:"This pack specifies measurement purposes, not HP Tuners display names or Ford PID identities. Exact channels are admitted only through the Scanner Semantic Firewall.")

    static let trc75Shift = VCMExperimentChannelPack(id:"trc75.shift", title:"TR_C75 Shift Evidence Pack", controller:.trC75, requirements:[
        .init(id:"rpm",purpose:.identity,canonicalSemanticID:"engine.speed",temporalPriority:.eventCritical,required:true,semanticRequirement:"Reviewed engine-speed semantic"),
        .init(id:"gear",purpose:.transmissionShift,canonicalSemanticID:"transmission.gear.actual",temporalPriority:.eventCritical,required:true,semanticRequirement:"Actual/requested distinction explicit"),
        .init(id:"gearRequest",purpose:.transmissionShift,canonicalSemanticID:"transmission.gear.requested",temporalPriority:.eventCritical,required:false,semanticRequirement:"Exact TCM semantic required"),
        .init(id:"shiftState",purpose:.transmissionShift,canonicalSemanticID:"transmission.shift.state",temporalPriority:.eventCritical,required:false,semanticRequirement:"Exact TCM semantic required"),
        .init(id:"dctTemp",purpose:.thermal,canonicalSemanticID:"transmission.temperature",temporalPriority:.medium,required:true,semanticRequirement:"Fluid/component identity must be explicit"),
        .init(id:"accel",purpose:.externalReference,canonicalSemanticID:"vehicle.longitudinal.acceleration",temporalPriority:.eventCritical,required:true,semanticRequirement:"Source and timebase documented")
    ], boundary:"This pack does not assert that every requested semantic is exposed by every TR_C75 strategy. Missing channels remain missing and constrain conclusions.")
}

struct VCMChannelPackAssessment: Codable {
    let complete: Bool
    let satisfied: [String]
    let missing: [String]
    let rejected: [String]
    let boundary: String
}

enum VCMChannelPackCompiler {
    static func assess(pack: VCMExperimentChannelPack, bindings: [ScannerSemanticBinding]) -> VCMChannelPackAssessment {
        var satisfied:[String]=[]; var missing:[String]=[]; var rejected:[String]=[]
        for req in pack.requirements where req.required {
            let candidates = bindings.filter { $0.controller == pack.controller && $0.canonicalSignalID == req.canonicalSemanticID }
            guard !candidates.isEmpty else { missing.append(req.canonicalSemanticID); continue }
            if candidates.contains(where:{ FordScannerSemanticFirewall.assess($0, expectedController:pack.controller).admitted }) { satisfied.append(req.canonicalSemanticID) }
            else { rejected.append(req.canonicalSemanticID) }
        }
        return .init(complete:missing.isEmpty && rejected.isEmpty,satisfied:satisfied,missing:missing,rejected:rejected,boundary:"Completeness means the required measurement purposes have admitted semantics. It does not establish sensor accuracy, adequate sample rate, safe calibration, or causal interpretation.")
    }
}

struct FordTuneExperimentTemplate: Identifiable, Codable {
    let id: String
    let title: String
    let goal: String
    let controller: TuningControllerFamily
    let channelPackID: String
    let constantsToHold: [String]
    let comparisonOutputs: [String]
    let abortCategories: [String]
    let calibrationChangeRule: String
    let conclusionBoundary: String
}

enum FordTuneExperimentTemplateLibrary {
    static let templates:[FordTuneExperimentTemplate] = [
        .init(id:"gt500.baseline.highload",title:"GT500 High-Load Baseline",goal:"Establish a repeatable evidence baseline before calibration changes.",controller:.gt500PCM,channelPackID:"gt500.highload",constantsToHold:["Build revision","Fuel","Test mode","Starting thermal envelope","Driver procedure","Scanner configuration"],comparisonOutputs:["Acceleration interval","Lambda behavior","Spark/knock observations","Throttle behavior","Thermal response","Intervention chronology"],abortCategories:["Fuel delivery anomaly","Unsafe/abnormal combustion evidence","Thermal abort","DTC onset","Unexpected throttle/torque intervention requiring diagnosis"],calibrationChangeRule:"No calibration change is part of the baseline experiment.",conclusionBoundary:"A baseline describes tested behavior only; it is not proof that the calibration is optimal or safe outside the tested envelope."),
        .init(id:"gt500.singlefamily",title:"Single-Family Calibration Experiment",goal:"Measure the response to a deliberately isolated reviewed calibration change.",controller:.gt500PCM,channelPackID:"gt500.highload",constantsToHold:["Hardware","Fuel","Scanner contract","Test procedure","Comparable thermal start"],comparisonOutputs:["Calibration diff manifest","High-load response","First-out events","Repeatability","Thermal recovery"],abortCategories:["Diagnostic fault","Fuel anomaly","Knock/combustion concern","Thermal concern","Acquisition-quality failure"],calibrationChangeRule:"Prefer one reviewed parameter family at a time; multi-family changes reduce attribution strength and must be labeled accordingly.",conclusionBoundary:"Observed improvement after a change is evidence within the experiment; it does not prove universal causality, mechanical safety, or transferability."),
        .init(id:"trc75.shift.cohort",title:"TR_C75 Shift Cohort",goal:"Compare repeated same-shift behavior across controlled TCM revisions.",controller:.trC75,channelPackID:"trc75.shift",constantsToHold:["PCM revision where possible","TCM strategy identity","Drive mode","Starting DCT thermal envelope","Road/dyno condition"],comparisonOutputs:["Shift duration distribution","RPM drop/flare behavior","Acceleration interruption","Recovery","Thermal dependence"],abortCategories:["DTC onset","Unexpected slip evidence","Thermal protection","Loss of comparability"],calibrationChangeRule:"TCM changes must remain revision-traceable; PCM changes during the same cohort are a confounder.",conclusionBoundary:"A faster shift fingerprint does not alone prove lower clutch stress, better durability, or safe pressure control.")
    ]
}

struct VCMDefinitionAcquisitionRecord: Identifiable, Codable {
    let id: String
    let controller: TuningControllerFamily
    let artifact: String
    let captures: [String]
    let reviewUnlocks: [String]
    let doesNotProve: [String]
    let priority: Int
}

enum FordVCMDefinitionAcquisitionMatrix {
    static let records:[VCMDefinitionAcquisitionRecord] = [
        .init(id:"acq.gt500.editor",controller:.gt500PCM,artifact:"Applicable stock GT500 HPT opened in current VCM Editor with complete Parameter Navigator inventory/capture",captures:["OS/strategy identity","Navigator paths","data types","descriptions exposed by VCM Editor","units/axes where displayed"],reviewUnlocks:["GT500 parameter-family mapping","stock-vs-modified semantic diff review","calibration Truth Debt reduction"],doesNotProve:["Ford internal algorithm","safe value ranges","causal effect"],priority:100),
        .init(id:"acq.gt500.scanner",controller:.gt500PCM,artifact:"Known-good GT500 Scanner XML + matching HPL from the same build/calibration",captures:["Parameter IDs","sources","polling intervals","transforms","observed channel availability"],reviewUnlocks:["Scanner Semantic Firewall review","channel packs","Limiter Detective evidence"],doesNotProve:["sensor accuracy","OEM physical meaning without semantic evidence"],priority:98),
        .init(id:"acq.trc75.editor",controller:.trC75,artifact:"Applicable stock TR_C75 HPT/VCM Editor inventory",captures:["TCM strategy identity","transmission parameter paths","data types","descriptions","units/axes where displayed"],reviewUnlocks:["TR_C75 semantic registry","shift experiment design","TCM calibration diff review"],doesNotProve:["hydraulic pressure targets unless explicitly represented and reviewed","durability limits"],priority:97),
        .init(id:"acq.trc75.scanner",controller:.trC75,artifact:"TR_C75-focused Scanner XML + HPL shift corpus",captures:["TCM channel IDs","source/transform","shift chronology","thermal context"],reviewUnlocks:["Shift-state reconstruction","shift cohorts","first-out analysis"],doesNotProve:["clutch pressure or torque handoff when not directly/semantically measured"],priority:96),
        .init(id:"acq.compare",controller:.gt500PCM,artifact:"Stock + modified HPT comparison exported/captured through VCM Editor",captures:["represented differences","parameter-family blast radius","DTC differences where represented"],reviewUnlocks:["Calibration Change Ledger","controlled experiment reconstruction"],doesNotProve:["why a value changed","whether it is safe","whether it caused the observed result"],priority:90)
    ]
}

struct VCMSuiteResearchImportAudit: Codable {
    let accepted: Bool
    let blockers:[String]
    let warnings:[String]
    let boundary:String
}

enum VCMSuiteResearchImportGate {
    static func assess(controller:TuningControllerFamily, strategyID:String?, artifactController:TuningControllerFamily, artifactStrategyID:String?, hasExactLocator:Bool, definitionOrigin:VCMSuiteEvidenceClass) -> VCMSuiteResearchImportAudit {
        var b:[String]=[]; var w:[String]=[]
        if controller != artifactController { b.append("Controller family mismatch") }
        if let strategyID, let artifactStrategyID, strategyID != artifactStrategyID { b.append("Strategy mismatch") }
        if strategyID == nil || artifactStrategyID == nil { w.append("Strategy identity is incomplete; semantic promotion must remain strategy-limited") }
        if !hasExactLocator { b.append("Exact parameter/artifact locator missing") }
        if definitionOrigin == .userDefinedXDF { w.append("User-defined/XDF origin must remain distinct from HP Tuners native definitions") }
        if definitionOrigin == .professionalInterpretation || definitionOrigin == .predatorLabInference { w.append("Interpretive evidence cannot be promoted as Ford or HP Tuners authority") }
        return .init(accepted:b.isEmpty,blockers:b,warnings:w,boundary:"Import admission preserves an observation in the applicable research corpus. It does not promote the observation to Ford truth, HP Tuners native semantics, or a safe calibration recommendation.")
    }
}

import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct ForensicObservationRev77: Identifiable, Codable, Hashable {
    let id: String; let time: Double; let signal: String; let value: String; let provenance: String; let interpretationBoundary: String
}
struct ForensicHypothesisRev77: Identifiable, Codable, Hashable {
    enum Status: String, Codable { case supported, contradicted, unresolved, instrumentationFirst }
    let id: String; let title: String; let status: Status; let supporting: [String]; let contradicting: [String]; let missing: [String]
}
struct ScannerContractItemRev77: Identifiable, Codable, Hashable {
    enum Tier: Int, Codable { case one = 1, two = 2, three = 3 }
    let id: String; let semantic: String; let tier: Tier; let requirement: String; let promotionRule: String
}
struct FlagshipForensicCaseRev77: Codable, Hashable {
    let title: String; let trigger: String; let window: ClosedRange<Double>; let observations: [ForensicObservationRev77]; let hypotheses: [ForensicHypothesisRev77]; let configB: [ScannerContractItemRev77]; let nextExperiment: [String]; let boundary: String
}

enum GT500FlagshipForensicsRev77 {
    static let sep2 = FlagshipForensicCaseRev77(
        title: "sep2 / Insufficient Fuel Flow forensic case",
        trigger: "First observed Torque Max Protection Source = Insufficient Fuel Flow",
        window: 4.838...7.958,
        observations: [
            .init(id:"p1",time:5.838,signal:"Torque Max Protection Source",value:"Insufficient Fuel Flow",provenance:"sep2.csv observed label",interpretationBoundary:"Controller/source label; not proof of physical fuel starvation."),
            .init(id:"p2",time:5.838,signal:"Fuel Pressure (SAE)",value:"106.21 psi",provenance:"sep2.csv",interpretationBoundary:"Signal identity/scaling remains independently reviewable."),
            .init(id:"p3",time:5.878,signal:"Fuel Pressure (SAE)",value:"107.89 psi",provenance:"sep2.csv",interpretationBoundary:"Rising observed value does not prove pressure adequacy without desired pressure/differential context."),
            .init(id:"p4",time:5.918,signal:"Fuel Pressure (SAE)",value:"110.95 psi",provenance:"sep2.csv",interpretationBoundary:"Observation only."),
            .init(id:"p5",time:5.838,signal:"Torque Source",value:"Trans Shift Mod",provenance:"sep2.csv",interpretationBoundary:"Temporal overlap supports shift-interaction hypothesis, not causation."),
            .init(id:"p6",time:5.918,signal:"Torque Source",value:"TQ+ from Trans",provenance:"sep2.csv",interpretationBoundary:"Observed source transition."),
            .init(id:"p7",time:5.838,signal:"Spark Source",value:"Cyl. Pressure Limit",provenance:"sep2.csv",interpretationBoundary:"Observed source label; exact Ford strategy semantics require promotion."),
            .init(id:"p8",time:5.918,signal:"Spark Source",value:"Torque Control",provenance:"sep2.csv",interpretationBoundary:"Observed source transition."),
            .init(id:"p9",time:5.838,signal:"Knock Retard",value:"0°",provenance:"sep2.csv",interpretationBoundary:"No positive KR in this sample is not proof of knock-free combustion."),
            .init(id:"p10",time:5.838,signal:"IAT2",value:"105.8°F",provenance:"sep2.csv",interpretationBoundary:"No Ford derate threshold inferred."),
            .init(id:"p11",time:5.838,signal:"Module Voltage",value:"14.60 V",provenance:"sep2.csv",interpretationBoundary:"Observed supply context only.")
        ],
        hypotheses: [
            .init(id:"H1A",title:"Physical injector-flow capacity",status:.unresolved,supporting:[],contradicting:["Observed fuel-pressure value rises through the protection samples."],missing:["reviewed injector PW","maximum available PW/injection window","desired pressure","validated lambda B1/B2"]),
            .init(id:"H1B",title:"Usable injector window / maximum PW",status:.unresolved,supporting:["High RPM/load event is compatible with reduced available injection time."],contradicting:[],missing:["requested/actual PW","maximum available PW or injection window"]),
            .init(id:"H2",title:"Pump / pressure command limitation",status:.unresolved,supporting:[],contradicting:["Observed pressure signal rises from 106.21 to about 110.95 psi during the label."],missing:["desired pressure","pump command/duty/voltage","validated differential-pressure semantics"]),
            .init(id:"H3",title:"Modeled fuel-flow / calculated-capacity limit",status:.unresolved,supporting:["Protection label can coexist with rising observed pressure."],contradicting:[],missing:["calculated/modelled fuel flow","injector demand/headroom","repeatable threshold cohort"]),
            .init(id:"H4",title:"DCT shift-transient interaction",status:.supported,supporting:["Torque Source is Trans Shift Mod at protection onset.","Torque Source transitions to TQ+ from Trans while label persists.","Spark Source changes from Cyl. Pressure Limit to Torque Control in the same interval."],contradicting:[],missing:["reviewed current/requested gear","shift state","transmission input speed"]),
            .init(id:"H5",title:"PID identity / scaling issue",status:.instrumentationFirst,supporting:["Supplied project analysis reports anomalous behavior from a second wideband-like channel."],contradicting:[],missing:["Scanner semantic certification","wideband transform/source verification"]),
            .init(id:"H6",title:"Other protection / hidden dependency",status:.unresolved,supporting:[],contradicting:[],missing:["additional reviewed source/limit PIDs","repeat events"]),
            .init(id:"H7",title:"Variable/differential-pressure strategy interaction",status:.unresolved,supporting:["Observed pressure rises with load during the event."],contradicting:[],missing:["desired pressure","differential-pressure context","pump command","injector effective-flow evidence"])
        ],
        configB: configBContract,
        nextExperiment: [
            "Preserve the original 68-entry Scanner XML and its fingerprint.",
            "Certify Parameter ID/source/units/transform for every Tier-1 Config B semantic before using it as evidence.",
            "Build a reduced Config B XML from reviewed supported channels only; do not invent Parameter IDs.",
            "Benchmark original XML versus Config B on the same GT500 + MPVI4 + firmware + VCM version.",
            "Repeat the event under a matched build/fuel/thermal condition and capture at least 1 s pre-trigger through 2 s recovery.",
            "Use the resulting event to update H1A-H7; evidence-gap closure makes a conclusion reviewable, not automatically true."
        ],
        boundary: "Rev77 reconstructs observations and experiment logic from the supplied sep2 CSV/framework. It does not decode HPT/HPL, invent Ford strategy semantics, prescribe calibration changes, or declare physical fuel starvation."
    )

    static let configBContract: [ScannerContractItemRev77] = [
        ("rpm","RPM",1,"required","review exact Scanner identity"),("pedal","Accelerator",1,"required","review exact Scanner identity"),("cmdLambda","Commanded lambda",1,"required","review units/source"),("lambda1","Actual lambda B1",1,"required","validate physical/source semantics"),("lambda2","Actual lambda B2",1,"required","validate physical/source semantics"),("fuelP","Fuel pressure actual",1,"required","verify physical meaning/scaling"),("fuelPdes","Fuel pressure desired",1,"required if exposed","must be observed in exact controller profile"),("pump","Pump command/duty/voltage",1,"required if exposed","must be observed in exact controller profile"),("pw","Injector pulse width",1,"required","review exact semantic"),("maxpw","Maximum available PW / injector window",1,"required if exposed","no substitute inferred"),("flow","Calculated/modelled fuel flow",1,"desired if exposed","no invented model"),("protect","Torque Max Protection Source",1,"required","observed label semantics retained"),("torqueSource","Torque Source",1,"required","observed label semantics retained"),("gear","Gear / shift state",1,"required","review exact transmission source"),
        ("maf","MAF",2,"context","review units"),("map","MAP",2,"context","review units"),("load","Absolute Load",2,"context","review definition"),("voltage","Module voltage",2,"context","review source"),("throttleD","Desired throttle",2,"context","review semantic"),("throttleA","Actual throttle",2,"context","review semantic"),("spark","Spark",2,"context","review semantic"),("kr","Knock Retard",2,"context","review semantic"),("sparkSource","Spark Source",2,"context","observed label semantics retained"),
        ("iat2","IAT2",3,"thermal context","review sensor semantic"),("ect","ECT",3,"thermal context","review sensor semantic"),("baro","BARO",3,"environment context","review source"),("fuelLevel","Fuel level",3,"context","review source")
    ].map { ScannerContractItemRev77(id:$0.0,semantic:$0.1,tier:ScannerContractItemRev77.Tier(rawValue:$0.2)!,requirement:$0.3,promotionRule:$0.4) }
}

struct SemanticCertificationRecordRev77: Identifiable, Codable, Hashable {
    enum State: String, Codable { case unresolved, candidate, reviewed, certified, disputed }
    let id: String; let parameterID: String?; let displayName: String; let source: String?; let pollingInterval: Double?; let units: String?; let transform: String?; let controller: String?; let strategy: String?; let state: State; let evidence: [String]
}

enum SemanticCertificationEngineRev77 {
    static func certify(_ record: SemanticCertificationRecordRev77) -> Bool {
        record.state == .certified && record.parameterID != nil && record.source != nil && record.units != nil && record.controller != nil
    }
}

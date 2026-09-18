import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct HPLWaveformCandidateRev81: Identifiable, Codable, Equatable {
    let id:String; let encoding:String; let byteOffset:Int; let sampleCount:Int; let valueCorrelation:Double; let timingCorrelation:Double; let xmlIdentityMatched:Bool; let unitsMatched:Bool; let admitted:Bool; let notes:[String]
}

enum HPLWaveformAdmissionRev81 {
    static func assess(encoding:String, offset:Int, samples:Int, valueCorrelation:Double, timingCorrelation:Double, xmlMatched:Bool, unitsMatched:Bool) -> HPLWaveformCandidateRev81 {
        let ok = samples >= 20 && valueCorrelation >= 0.995 && timingCorrelation >= 0.995 && xmlMatched && unitsMatched
        var notes:[String]=[]
        if samples < 20 { notes.append("Too few observations for waveform admission") }
        if valueCorrelation < 0.995 { notes.append("Value chronology is below artifact-specific admission threshold") }
        if timingCorrelation < 0.995 { notes.append("Timing chronology is below artifact-specific admission threshold") }
        if !xmlMatched { notes.append("Scanner XML identity/source is unresolved") }
        if !unitsMatched { notes.append("Engineering-unit interpretation is unresolved") }
        return .init(id:UUID().uuidString,encoding:encoding,byteOffset:offset,sampleCount:samples,valueCorrelation:valueCorrelation,timingCorrelation:timingCorrelation,xmlIdentityMatched:xmlMatched,unitsMatched:unitsMatched,admitted:ok,notes:notes)
    }
}

struct HPLRosettaSignalRev81: Identifiable, Codable, Equatable { let id:String; let name:String; let reason:String; let nextSignals:[String] }
enum HPLRosettaPlanRev81 {
    static let rpm = HPLRosettaSignalRev81(id:"rpm",name:"Engine RPM",reason:"RPM has a distinctive dynamic waveform, broad numeric range, known CSV chronology and a corresponding Scanner configuration identity, making it a strong first native-stream target.",nextSignals:["Fuel Pressure","Torque Max Protection Source","Torque Source","Spark Source","Gear / shift state"])
}

struct VCMTelemetryFactRev81: Identifiable, Codable, Equatable { let id:String; let area:String; let fact:String; let evidenceBoundary:String; let source:String }
enum VCMTelemetryAtlasRev81 {
    static let facts:[VCMTelemetryFactRev81] = [
        .init(id:"purpose",area:"Product role",fact:"VCM Telemetry is documented as connected standalone datalogging: configure a compatible interface, record without a laptop, upload completed sessions, then review/compare/share in a browser.",evidenceBoundary:"Telemetry is a transport/review workflow; it does not verify channel semantics or calibration conclusions.",source:"HP Tuners VCM Telemetry"),
        .init(id:"interfaces",area:"Compatible interfaces",fact:"Current public requirements identify MPVI4 or RTD4 as compatible interfaces.",evidenceBoundary:"Compatibility is version/date dependent and must be recorded with firmware/software state.",source:"HP Tuners VCM Telemetry > Requirements"),
        .init(id:"scanner",area:"Configuration",fact:"Initial setup is performed in the latest supported VCM Scanner; current public copy refers to VCM Scanner BETA for configuration.",evidenceBoundary:"Store Scanner version and XML fingerprint; do not assume a config has identical definitions across software/controller states.",source:"HP Tuners VCM Telemetry > Standalone Logging / How It Works"),
        .init(id:"record",area:"Recording",fact:"After setup, the interface records vehicle data without a laptop remaining connected during the drive.",evidenceBoundary:"Record trigger/deployment state and distinguish acquisition ending from vehicle behavior ending.",source:"HP Tuners VCM Telemetry > Connect and Record"),
        .init(id:"network",area:"Connectivity",fact:"Completed sessions upload when internet connectivity is available through Wi-Fi or a mobile hotspot.",evidenceBoundary:"Network/upload state is transport provenance, not measurement validity.",source:"HP Tuners VCM Telemetry > Completed Session Uploads"),
        .init(id:"browser",area:"Review",fact:"Uploaded sessions can be reviewed from a browser on computer, tablet, or mobile device.",evidenceBoundary:"Browser rendering is a view of evidence, not a semantic promotion event.",source:"HP Tuners VCM Telemetry > Browser-Based Review"),
        .init(id:"history",area:"History",fact:"The service organizes completed sessions by vehicle and date and supports comparison with previous sessions.",evidenceBoundary:"Vehicle/date grouping does not prove build-revision or calibration comparability; PredatorLab keeps those separately.",source:"HP Tuners VCM Telemetry > Organized Vehicle History"),
        .init(id:"sharing",area:"Sharing",fact:"Access can be granted to a tuner, dealer, or another trusted user without manually sending individual log files.",evidenceBoundary:"Track share/access lineage separately from authorship and engineering authority.",source:"HP Tuners VCM Telemetry > Controlled Sharing"),
        .init(id:"dealer",area:"Dealer/tuner workflow",fact:"HP Tuners describes browser review of uploaded customer logs without downloading/opening each file separately in VCM Scanner.",evidenceBoundary:"Remote reviewer identity is professional provenance, not OEM authority.",source:"HP Tuners VCM Telemetry > Simplified Dealer Access"),
        .init(id:"requirements",area:"Requirements",fact:"Public requirements list compatible MPVI4/RTD4, latest supported Scanner, current interface firmware, Wi-Fi/mobile hotspot, and a VCM Telemetry account.",evidenceBoundary:"PredatorLab records observed requirement state at experiment time because capabilities can evolve.",source:"HP Tuners VCM Telemetry > Requirements"),
        .init(id:"noapi",area:"Integration boundary",fact:"The reviewed public workflow documents browser/service usage; this atlas does not establish a public VCM Telemetry API for third-party automated ingestion.",evidenceBoundary:"Do not invent API endpoints, authentication flows, background downloads, or cloud automation.",source:"PredatorLab review of current public HP Tuners Telemetry material")
    ]
}

enum VCMTelemetryStateRev81: String, Codable, CaseIterable { case configured, deployed, recording, completedLocal, awaitingConnectivity, uploading, uploaded, browserReviewed, shared, exported, importedPredatorLab, failed }
struct VCMTelemetrySessionRev81: Identifiable, Codable, Equatable {
    let id:String; let interfaceID:String; let vehicleID:String?; let experimentID:String; let scannerVersion:String; let firmware:String; let scannerConfigSHA256:String; let recordedAt:Date?; let state:VCMTelemetryStateRev81; let remoteSessionID:String?; let exportSHA256:String?; let shareRecipients:[String]; let notes:[String]
}

enum VCMTelemetryTransitionRev81 {
    static func canMove(from:VCMTelemetryStateRev81, to:VCMTelemetryStateRev81) -> Bool {
        if to == .failed { return true }
        let order:VCMTelemetryStateRev81.AllCases = VCMTelemetryStateRev81.allCases
        guard let a=order.firstIndex(of:from), let b=order.firstIndex(of:to) else { return false }
        return b == a + 1 || (from == .completedLocal && to == .uploading) || (from == .uploaded && to == .shared)
    }
}

struct VCMTelemetryTruthGateRev81: Codable, Equatable { let transportVerified:Bool; let semanticsVerified:Bool; let acquisitionQualityVerified:Bool; let comparableBuildState:Bool; var conclusionEligible:Bool { transportVerified && semanticsVerified && acquisitionQualityVerified && comparableBuildState } }

struct VCMSuiteAssociatedCapabilityRev81: Identifiable, Codable, Equatable { let id:String; let name:String; let documentedBehavior:String; let predatorLabUse:String }
enum VCMSuiteAssociatedAtlasRev81 {
    static let items:[VCMSuiteAssociatedCapabilityRev81] = [
        .init(id:"newlog",name:"VCM Scanner 5.2 log format",documentedBehavior:"HP Tuners documents a new log-file format with improved performance/reduced size and MPVI4 support.",predatorLabUse:"Version-aware HPL probing; never universalize the legacy HPT-header parser."),
        .init(id:"poll",name:"Polling/broadcast/external",documentedBehavior:"More polled channels generally reduce return rate; broadcast channels avoid polling overhead; external sources do not reduce vehicle polling rate.",predatorLabUse:"Benchmark task-specific Config B rather than promising universal Hz."),
        .init(id:"xml",name:"Scanner XML",documentedBehavior:"Saved channel configs include Parameter ID, source, polling interval, and transform.",predatorLabUse:"Fingerprint XML and use it as one witness in HPL↔XML↔CSV certification."),
        .init(id:"transform",name:"External transforms",documentedBehavior:"External scalar inputs can be transformed into typed values such as lambda/AFR/temperature/pressure; user transforms persist with channel config.",predatorLabUse:"Retain raw volts, device/wiring/calibration points, transform and output semantics."),
        .init(id:"standalone",name:"Standalone logging",documentedBehavior:"Compatible interfaces can store logs without a PC; VCM Scanner provides retrieval of stored logs.",predatorLabUse:"Bind deployment/trigger/interface/software fingerprints to immutable HPL evidence."),
        .init(id:"editor",name:"VCM Editor workflow",documentedBehavior:"HP Tuners recommends DTC review, baseline Scanner data, preserving original read, editing/writing, then validating with Scanner.",predatorLabUse:"Diagnose → Baseline → Preserve → Experiment → Measure → Validate."),
        .init(id:"license",name:"Licensing separation",documentedBehavior:"Vehicle/controller licensing and interface support are separate from scanning/logging behavior.",predatorLabUse:"Keep interface, credits, write licenses, controller identity and evidence capability as separate states.")
    ]
}

import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct HPLCorrelationRunRev82: Identifiable, Codable, Equatable {
    let id: String
    let signal: String
    let sourceHPLSHA256: String
    let sourceCSVSHA256: String
    let scannerConfigSHA256: String
    let encoding: String
    let candidateOffset: Int?
    let samplesCompared: Int
    let valueCorrelation: Double?
    let timingCorrelation: Double?
    let unitsVerified: Bool
    let xmlIdentityVerified: Bool
    let admitted: Bool
    let boundary: String
}

enum HPLCorrelationHarnessRev82 {
    static let requiredSignals = ["Engine RPM", "Fuel Pressure", "Torque Max Protection Source", "Torque Source", "Spark Source", "Gear / shift state"]
    static func admit(signal:String, hpl:String, csv:String, xml:String, encoding:String, offset:Int?, samples:Int, value:Double?, timing:Double?, units:Bool, identity:Bool) -> HPLCorrelationRunRev82 {
        let ok = samples >= 20 && (value ?? 0) >= 0.995 && (timing ?? 0) >= 0.995 && units && identity
        return .init(id:UUID().uuidString,signal:signal,sourceHPLSHA256:hpl,sourceCSVSHA256:csv,scannerConfigSHA256:xml,encoding:encoding,candidateOffset:offset,samplesCompared:samples,valueCorrelation:value,timingCorrelation:timing,unitsVerified:units,xmlIdentityVerified:identity,admitted:ok,boundary:"Artifact-specific admission only. It does not establish a universal proprietary HPL specification or controller semantic authority.")
    }
}

struct TelemetrySessionInspectorRev82: Codable, Equatable {
    let session:VCMTelemetrySessionRev81
    let controllerIdentity:String?
    let calibrationFingerprint:String?
    let buildRevisionID:String?
    let acquisitionContractID:String?
    let rawArtifactSHA256:String?
    let semanticCertificationComplete:Bool
    let acquisitionQualityPassed:Bool
    let comparabilityPassed:Bool
    var conclusionEligible:Bool { semanticCertificationComplete && acquisitionQualityPassed && comparabilityPassed && rawArtifactSHA256 != nil }
    var transportOnly:Bool { session.state == .uploaded || session.state == .browserReviewed || session.state == .shared }
}

struct ConfigBRequirementRev82: Identifiable, Codable, Equatable {
    enum Tier:String,Codable { case mandatory, discriminator, context }
    let id:String; let role:String; let tier:Tier; let why:String; let certifiedParameterID:String?; let source:String?; let units:String?; let intervalSeconds:Double?
    var compilable:Bool { certifiedParameterID != nil && source != nil && units != nil }
}

struct ConfigBCompileResultRev82: Codable, Equatable {
    let requirements:[ConfigBRequirementRev82]
    let emittedParameterIDs:[String]
    let unresolvedRoles:[String]
    let candidateXML:String?
    let boundary:String
}

enum ConfigBCompilerRev82 {
    static func compile(_ requirements:[ConfigBRequirementRev82]) -> ConfigBCompileResultRev82 {
        let good = requirements.filter { $0.compilable }
        let unresolved = requirements.filter { !$0.compilable }.map(\.role)
        let xml:String? = unresolved.isEmpty ? "<channels>\n" + good.map { "  <channel ParameterID=\"\($0.certifiedParameterID!)\" Interval=\"\($0.intervalSeconds ?? 0.1)\" />" }.joined(separator:"\n") + "\n</channels>" : nil
        return .init(requirements:requirements,emittedParameterIDs:good.compactMap(\.certifiedParameterID),unresolvedRoles:unresolved,candidateXML:xml,boundary:"Never invent a Parameter ID. No XML is emitted until every mandatory role is semantically certified for the exact controller/definition environment.")
    }
}

enum ConfigBSeedRev82 {
    static let requirements:[ConfigBRequirementRev82] = [
        .init(id:"rpm",role:"Engine RPM",tier:.mandatory,why:"Event alignment and injector-window context",certifiedParameterID:nil,source:nil,units:"rpm",intervalSeconds:0.1),
        .init(id:"pedal",role:"Accelerator / driver demand",tier:.mandatory,why:"Establish requested load",certifiedParameterID:nil,source:nil,units:"percent",intervalSeconds:0.1),
        .init(id:"cmdlambda",role:"Commanded lambda",tier:.mandatory,why:"Fueling command",certifiedParameterID:nil,source:nil,units:"lambda",intervalSeconds:0.1),
        .init(id:"actlambda",role:"Validated actual lambda B1/B2",tier:.mandatory,why:"Combustion response",certifiedParameterID:nil,source:nil,units:"lambda",intervalSeconds:0.1),
        .init(id:"fp",role:"Actual fuel pressure",tier:.mandatory,why:"Observed pressure behavior",certifiedParameterID:nil,source:nil,units:"psi",intervalSeconds:0.1),
        .init(id:"fpcmd",role:"Desired fuel pressure",tier:.discriminator,why:"Separates pressure-control behavior from observed pressure alone",certifiedParameterID:nil,source:nil,units:"psi",intervalSeconds:0.1),
        .init(id:"pump",role:"Pump command / duty / voltage",tier:.discriminator,why:"Tests pump/control saturation",certifiedParameterID:nil,source:nil,units:nil,intervalSeconds:0.1),
        .init(id:"pw",role:"Injector pulse width",tier:.discriminator,why:"Tests injector utilization",certifiedParameterID:nil,source:nil,units:"ms",intervalSeconds:0.1),
        .init(id:"window",role:"Maximum available injector window",tier:.discriminator,why:"Tests H1B usable-window limitation",certifiedParameterID:nil,source:nil,units:"ms",intervalSeconds:0.1),
        .init(id:"prot",role:"Torque Max Protection Source",tier:.mandatory,why:"Flagship event label",certifiedParameterID:nil,source:nil,units:"state",intervalSeconds:0.1),
        .init(id:"tq",role:"Torque Source",tier:.mandatory,why:"Separates DCT/traction/driver-demand arbitration",certifiedParameterID:nil,source:nil,units:"state",intervalSeconds:0.1),
        .init(id:"spark",role:"Spark Source",tier:.mandatory,why:"Chronology of torque intervention",certifiedParameterID:nil,source:nil,units:"state",intervalSeconds:0.1),
        .init(id:"gear",role:"Gear / shift state",tier:.mandatory,why:"TR_C75 event phase",certifiedParameterID:nil,source:nil,units:"state",intervalSeconds:0.1)
    ]
}

struct MPVI4CommissioningChecklistRev82: Identifiable, Codable, Equatable { let id:String; let step:String; let evidence:String; let blocksExperiment:Bool }
enum MPVI4CommissioningRev82 {
    static let steps:[MPVI4CommissioningChecklistRev82] = [
        .init(id:"device",step:"Identify interface",evidence:"MPVI4 identity and physical device recorded",blocksExperiment:true),
        .init(id:"firmware",step:"Record firmware",evidence:"Firmware version captured at experiment time",blocksExperiment:true),
        .init(id:"scanner",step:"Record VCM Scanner version",evidence:"Exact supported/BETA build captured",blocksExperiment:true),
        .init(id:"controller",step:"Identify PCM/TR_C75",evidence:"Controller/OS/definition environment captured",blocksExperiment:true),
        .init(id:"xml",step:"Fingerprint Scanner XML",evidence:"SHA-256 plus fallback/override state",blocksExperiment:true),
        .init(id:"external",step:"Commission external inputs",evidence:"Device, wiring/reference, raw units, calibration points and transform",blocksExperiment:true),
        .init(id:"test",step:"Make test recording",evidence:"Short known-condition acquisition before high-load experiment",blocksExperiment:true),
        .init(id:"benchmark",step:"Benchmark acquisition",evidence:"Observed timestamps, missingness, jitter and effective delivery by channel",blocksExperiment:true),
        .init(id:"deploy",step:"Deploy standalone contract",evidence:"Trigger/config deployment fingerprint",blocksExperiment:true),
        .init(id:"telemetry",step:"Record Telemetry state",evidence:"Local completion/upload/review/share state kept separate from semantic truth",blocksExperiment:false)
    ]
}

enum PredatorLabTuneFlowRev82:String,CaseIterable,Codable { case acquire="Acquire", verify="Verify", investigate="Investigate", experiment="Experiment", validate="Validate" }

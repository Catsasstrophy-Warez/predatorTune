import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

// Rev74: executable MPVI4 diagnostic/acquisition contracts. Official facts are separated from authored workflow logic.
struct MPVI4LEDObservationRev74: Codable, Hashable { let indicator:String; let pattern:String; let colors:[String] }
struct MPVI4LEDMeaningRev74: Identifiable, Codable, Hashable { let id:String; let observation:MPVI4LEDObservationRev74; let meaning:String; let nextChecks:[String]; let authority:String }
enum MPVI4LEDDecoderRev74 {
    static let known:[MPVI4LEDMeaningRev74] = [
        .init(id:"overvoltage",observation:.init(indicator:"status",pattern:"solid",colors:["red"]),meaning:"May indicate a documented protection/failure state; supply above 15.5 V is one documented cause.",nextChecks:["Measure interface supply voltage","Inspect for persistent bus overcurrent","Power-cycle only after the electrical cause is addressed"],authority:"HP Tuners faceplate/protection documentation; red alone is not a unique root cause."),
        .init(id:"normal",observation:.init(indicator:"status",pattern:"steady",colors:["green"]),meaning:"Normal-ready indication when interpreted in the applicable documented state context.",nextChecks:["Confirm USB/OBD activity separately","Do not infer controller health from LED alone"],authority:"HP Tuners faceplate documentation")
    ]
    static func decode(_ o:MPVI4LEDObservationRev74)->[MPVI4LEDMeaningRev74] { known.filter{$0.observation.indicator==o.indicator && $0.observation.pattern==o.pattern && Set($0.observation.colors).isSubset(of:Set(o.colors))} }
}

enum MPVI4ConnectionModeRev74:String,Codable,CaseIterable { case usbVCMSuite, bluetoothTDN, standalone, telemetryUpload, prolinkAnalog, prolinkCAN }
struct MPVI4ConnectionStateRev74:Codable,Hashable { var obdPower=false; var usb=false; var bluetooth=false; var standaloneConfigured=false; var wifi=false; var firmwareCurrent=false; var scannerConfigured=false }
struct MPVI4WorkflowAssessmentRev74:Codable,Hashable { let mode:MPVI4ConnectionModeRev74; let ready:Bool; let blockers:[String]; let nextSteps:[String] }
enum MPVI4ConnectionStateMachineRev74 {
 static func assess(_ mode:MPVI4ConnectionModeRev74,_ s:MPVI4ConnectionStateRev74)->MPVI4WorkflowAssessmentRev74 { var b:[String]=[]
  if !s.obdPower { b.append("OBD/interface power not confirmed") }
  switch mode { case .usbVCMSuite: if !s.usb {b.append("USB connection not confirmed")}; case .bluetoothTDN: if !s.bluetooth {b.append("Bluetooth/TDN connection not confirmed")}; case .standalone: if !s.standaloneConfigured || !s.scannerConfigured {b.append("Standalone Scanner configuration not deployed")}; case .telemetryUpload: if !s.standaloneConfigured {b.append("Standalone logging not configured")}; if !s.wifi {b.append("Wi-Fi/mobile-hotspot upload path not confirmed")}; if !s.firmwareCurrent {b.append("Current supported interface firmware not confirmed")}; case .prolinkAnalog,.prolinkCAN: if !s.scannerConfigured {b.append("External-input Scanner configuration not confirmed")} }
  return .init(mode:mode,ready:b.isEmpty,blockers:b,nextSteps:b.isEmpty ? ["Proceed while preserving session provenance"] : b.map{"Resolve: \($0)"}) }
}

struct MPVI4FirmwareLedgerEntryRev74:Identifiable,Codable,Hashable { let id:UUID; let observedAt:Date; let firmware:String?; let vcmSuite:String?; let scanner:String?; let capabilityNotes:[String]; let source:String }
struct MPVI4LicenseInspectionRev74:Codable,Hashable { let credits:Int?; let pcmLicensed:Bool?; let tcmLicensed:Bool?; let vin:String?; let moduleSerial:String?; let controllerOS:String?; let notes:[String] }
enum MPVI4LicenseInspectorRev74 { static func findings(_ x:MPVI4LicenseInspectionRev74)->[String] { var r:[String]=[]; if x.credits==nil {r.append("Credit balance unknown")}; if x.pcmLicensed != true {r.append("PCM write-license not confirmed; scanning/logging does not itself require a vehicle write license")}; if x.controllerOS==nil {r.append("Controller OS identity missing")}; return r } }

struct PROLINKChannelRev74:Identifiable,Codable,Hashable { enum Kind:String,Codable{case analog0to5V,can500k}; let id:String; let kind:Kind; let sourceDevice:String; let rawUnits:String; let outputSemantic:String; let outputUnits:String; let transform:String?; let wiringNote:String? }
enum PROLINKChannelBuilderRev74 { static func validate(_ c:PROLINKChannelRev74)->[String] { var x:[String]=[]; if c.kind == .analog0to5V && c.transform==nil {x.append("Analog channel requires a reviewed voltage-to-quantity transform")}; if c.sourceDevice.trimmingCharacters(in:.whitespaces).isEmpty{x.append("Source device identity required")}; if c.outputSemantic.isEmpty{x.append("Output semantic required")}; return x } }
struct WidebandTransformCheckRev74:Codable,Hashable { let valid:Bool; let issues:[String] }
enum WidebandTransformVerifierRev74 { static func verify(channel:PROLINKChannelRev74, knownPoints:[(Double,Double)])->WidebandTransformCheckRev74 { var i=PROLINKChannelBuilderRev74.validate(channel); if knownPoints.count < 2 {i.append("At least two source-backed calibration points are required to verify a transform")}; return .init(valid:i.isEmpty,issues:i) } }

struct MPVI4PowerIncidentRev74:Identifiable,Codable,Hashable { let id:UUID; let time:Date; let measuredVoltage:Double?; let ledObservation:String; let communicationLost:Bool; let context:String; let notes:String }
struct StandaloneDeploymentChecklistRev74:Codable,Hashable { let ignitionReady:Bool; let interfacePowered:Bool; let scannerContractReviewed:Bool; let standaloneConfigDeployed:Bool; let storageReady:Bool; let experimentID:String?; var ready:Bool { ignitionReady && interfacePowered && scannerContractReviewed && standaloneConfigDeployed && storageReady && experimentID != nil } }

struct AcquisitionBenchmarkRunRev74:Identifiable,Codable,Hashable { let id:UUID; let channelContractID:String; let controllerIdentity:String; let duration:Double; let sampleCount:Int; let droppedOrMissing:Int; let connectionMode:MPVI4ConnectionModeRev74; var observedSamplesPerSecond:Double? { duration>0 ? Double(sampleCount)/duration:nil } }
struct AcquisitionBenchmarkSummaryRev74:Codable,Hashable { let runs:Int; let medianObservedRate:Double?; let warning:String }
enum AcquisitionRateBenchmarkRev74 { static func summarize(_ runs:[AcquisitionBenchmarkRunRev74])->AcquisitionBenchmarkSummaryRev74 { let v=runs.compactMap{$0.observedSamplesPerSecond}.sorted(); let m=v.isEmpty ? nil : v[v.count/2]; return .init(runs:runs.count,medianObservedRate:m,warning:"Observed rate is specific to this controller, channel contract, interface/software state and connection mode; do not generalize it as an MPVI4 or GT500 guarantee.") } }

struct VCMSXMLOptimizationRev74:Codable,Hashable { let keep:[String]; let add:[String]; let review:[String]; let slowOrRemove:[String]; let guarantee:String }
enum ScannerXMLOptimizerRev74 { static func optimize(required:[String], reviewed:Set<String>, polledOptional:[String])->VCMSXMLOptimizationRev74 { .init(keep:required.filter{reviewed.contains($0)},add:required.filter{!reviewed.contains($0)},review:[],slowOrRemove:polledOptional,guarantee:"No exact acquisition-rate improvement is promised; benchmark the resulting contract on the actual controller/interface.") } }

enum VCMTelemetrySessionStateRev74:String,Codable { case configured, recorded, awaitingConnectivity, uploading, uploaded, browserReviewable, shared, failed }
struct VCMTelemetryLineageRev74:Identifiable,Codable,Hashable { let id:UUID; let interfaceID:String; let experimentID:String; let recordedAt:Date; let state:VCMTelemetrySessionStateRev74; let firmware:String?; let scannerVersion:String?; let networkKind:String?; let remoteSessionID:String?; let shareState:String?; let notes:[String] }
struct VCMTelemetryReadinessRev74:Codable,Hashable { let ready:Bool; let blockers:[String] }
enum VCMTelemetryEngineRev74 { static func readiness(interfaceCompatible:Bool, scannerCurrent:Bool, firmwareCurrent:Bool, standaloneConfigured:Bool, internetPath:Bool, accountReady:Bool)->VCMTelemetryReadinessRev74 { let p=[(!interfaceCompatible,"Compatible MPVI4/RTD4 not confirmed"),(!scannerCurrent,"Latest supported VCM Scanner not confirmed"),(!firmwareCurrent,"Current interface firmware not confirmed"),(!standaloneConfigured,"Standalone logging not configured"),(!internetPath,"Wi-Fi/mobile-hotspot upload path unavailable"),(!accountReady,"VCM Telemetry account not confirmed")].filter{$0.0}.map{$0.1}; return .init(ready:p.isEmpty,blockers:p) } }

struct MPVI4EvidenceHealthMapRev74:Codable,Hashable { let interfaceReady:Bool; let controllerIdentified:Bool; let scannerSemanticsReviewed:Bool; let acquisitionBenchmarked:Bool; let experimentBound:Bool; let evidenceAdmissible:Bool; let blockers:[String] }
enum MPVI4EvidenceHealthEngineRev74 { static func build(interfaceReady:Bool,controller:String?,reviewedCount:Int,benchmarkRuns:Int,experimentID:String?)->MPVI4EvidenceHealthMapRev74 { var b:[String]=[]; if !interfaceReady{b.append("Interface workflow not ready")}; if controller==nil{b.append("GT500 controller identity missing")}; if reviewedCount==0{b.append("No reviewed Scanner semantics")}; if benchmarkRuns==0{b.append("Acquisition performance not benchmarked")}; if experimentID==nil{b.append("No experiment binding")}; return .init(interfaceReady:interfaceReady,controllerIdentified:controller != nil,scannerSemanticsReviewed:reviewedCount>0,acquisitionBenchmarked:benchmarkRuns>0,experimentBound:experimentID != nil,evidenceAdmissible:b.isEmpty,blockers:b) } }

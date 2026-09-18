import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

// Rev83 turns the Rev82 flagship contracts into durable, archiveable execution records.
struct PersistedMPVI4DeviceSnapshotRev83: Identifiable, Codable, Equatable { let id:UUID; let vehicleID:UUID?; let interfaceID:String; let firmware:String; let scannerVersion:String; let capturedAt:Date; let notes:[String] }
struct PersistedTelemetrySessionRev83: Identifiable, Codable, Equatable { let id:UUID; let vehicleID:UUID?; let session:VCMTelemetrySessionRev81; let controllerIdentity:String?; let calibrationFingerprint:String?; let buildRevisionID:String?; let acquisitionContractID:String?; let rawArtifactSHA256:String?; let semanticCertificationComplete:Bool; let acquisitionQualityPassed:Bool; let comparabilityPassed:Bool }
struct PersistedAcquisitionBenchmarkRev83: Identifiable, Codable, Equatable { let id:UUID; let vehicleID:UUID?; let interfaceID:String; let firmware:String; let scannerVersion:String; let scannerConfigSHA256:String; let mode:String; let observedAt:Date; let channelCount:Int; let durationSeconds:Double; let missingFraction:Double?; let medianIntervalSeconds:Double?; let jitterSeconds:Double?; let notes:[String] }
struct PersistedConfigBContractRev83: Identifiable, Codable, Equatable { let id:UUID; let vehicleID:UUID?; let controllerIdentity:String; let definitionEnvironment:String; let requirements:[ConfigBRequirementRev82]; let candidateXML:String?; let createdAt:Date; let sourceXMLSHA256:String?; let boundary:String }
struct PersistedHPLCorrelationRev83: Identifiable, Codable, Equatable { let id:UUID; let vehicleID:UUID?; let run:HPLCorrelationRunRev82; let observedAt:Date }
struct PersistedForensicCaseRev83: Identifiable, Codable, Equatable { let id:UUID; let vehicleID:UUID?; let caseID:String; let title:String; let sourceArtifactHashes:[String]; let hypothesisIDs:[String]; let status:String; let updatedAt:Date }

struct TuneProductionGateRev83: Codable, Equatable {
    let xcodeBuildVerified:Bool
    let persistenceVerified:Bool
    let hplRPMAdmitted:Bool
    let configBCompiled:Bool
    let mpvi4BenchmarkCompleted:Bool
    let controlledFuelExperimentCompleted:Bool
    var readyForStrongValidation:Bool { xcodeBuildVerified && persistenceVerified && hplRPMAdmitted && configBCompiled && mpvi4BenchmarkCompleted && controlledFuelExperimentCompleted }
    var blockers:[String] {
        var r:[String]=[]
        if !xcodeBuildVerified { r.append("Run a full diagnostic session on this vehicle and confirm PredatorLab reports no unresolved session errors.") }
        if !persistenceVerified { r.append("Confirm this vehicle's execution records (telemetry, benchmarks, Config B contracts) have been saved to the on-device archive and reload correctly.") }
        if !hplRPMAdmitted { r.append("Capture a paired native HP Tuners log, exported CSV, and Scanner XML for this session, and admit the RPM waveform as artifact-verified evidence.") }
        if !configBCompiled { r.append("Certify every required Config B Parameter ID, source, and unit for this vehicle's exact GT500 controller definition environment.") }
        if !mpvi4BenchmarkCompleted { r.append("Run the tethered vs. standalone MPVI4 acquisition benchmark on this vehicle to confirm capture timing is consistent between modes.") }
        if !controlledFuelExperimentCompleted { r.append("Run the no-tune-change fuel discriminator experiment on this vehicle after the checks above pass.") }
        return r
    }
}

enum Rev83ExperimentProtocol {
    static let fuelDiscriminatorSteps:[String] = [
        "Freeze vehicle Build Revision, calibration fingerprint, fuel, tire/gear state and thermal starting condition.",
        "Resolve DTC/diagnostic blockers before high-load testing.",
        "Commission MPVI4, controller identities, firmware, Scanner version, definition environment and external measurement chain.",
        "Compile Config B only from semantically certified Parameter IDs; do not substitute guessed IDs.",
        "Make a short known-condition recording and inspect missingness, timestamp delivery, units and transforms.",
        "Benchmark the exact Config B contract tethered and standalone before interpreting rate-sensitive chronology.",
        "Run the controlled fuel-discriminator pull without changing the tune first.",
        "Reconstruct first-out chronology and compare H1B injector-window, H2 pressure/pump, H3 modeled-flow, H4 DCT interaction, H5 semantic artifact, H6 hidden dependency and H7 differential-pressure interaction.",
        "Do not call the cause proven unless acquisition quality, semantic certification, comparability and contradictory evidence permit it.",
        "Only after diagnosis should a calibration change become a separately fingerprinted experiment."
    ]
}

struct WhyExplanationRev83: Codable, Equatable { let observation:String; let supporting:[String]; let contradicting:[String]; let alternatives:[String]; let missing:[String]; let nextMeasurement:String; let changesMyMind:[String] }
enum WhyEngineRev83 {
    static func insufficientFuelFlowShiftOverlap() -> WhyExplanationRev83 { .init(
        observation:"The supplied sep2 analysis reports a brief Torque Max Protection Source = Insufficient Fuel Flow state overlapping TR_C75 torque choreography near the high-load shift event.",
        supporting:["The label repeats across four supplied high-load samples.","The event occurs at high RPM/load where fuel-window and modeled-flow constraints are worth testing."],
        contradicting:["The supplied observed fuel-pressure channel rises rather than showing a simple pressure collapse.","The supplied central event reports no positive knock retard."],
        alternatives:["Injector-window limitation","Pressure/pump-control limitation","Modeled fuel-flow/capacity limitation","DCT torque-coordination interaction","Channel identity/scaling/timebase artifact","Hidden dependency","Differential-pressure interaction"],
        missing:["Certified desired fuel pressure","Certified pump command/duty/voltage","Injector pulse width","Maximum available injector window","Commissioned actual lambda","Certified shift-state semantics"],
        nextMeasurement:"Compile and run the semantically certified Config B fuel-discriminator acquisition contract.",
        changesMyMind:["A repeatable pressure deficit relative to desired pressure would strengthen the physical delivery branch.","Adequate pressure plus exhausted injector window would strengthen H1B.","Adequate measured delivery with repeatable model/protection activation outside shift choreography would strengthen H3.","Protection appearing only with shift-state transitions would strengthen H4 while still not proving causation."]
    ) }
}

struct TuneArchiveMetadataV9Rev83: Codable {
    var devices:[PersistedMPVI4DeviceSnapshotRev83]
    var telemetrySessions:[PersistedTelemetrySessionRev83]
    var acquisitionBenchmarks:[PersistedAcquisitionBenchmarkRev83]
    var configBContracts:[PersistedConfigBContractRev83]
    var hplCorrelations:[PersistedHPLCorrelationRev83]
    var forensicCases:[PersistedForensicCaseRev83]
    static let empty = TuneArchiveMetadataV9Rev83(devices:[],telemetrySessions:[],acquisitionBenchmarks:[],configBContracts:[],hplCorrelations:[],forensicCases:[])
    static let boundary = "Schema v9 preserves MPVI4/Telemetry/Config-B/HPL-correlation provenance metadata. It does not embed proprietary cloud state or claim universal HPL decoding."
}

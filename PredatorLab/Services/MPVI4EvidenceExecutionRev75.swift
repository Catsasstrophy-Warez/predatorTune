import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

// Rev75: MPVI4 evidence execution. This models user/exported evidence and official workflow boundaries;
// it does not communicate with MPVI4 hardware, HP Tuners cloud services, or proprietary HPL/HPT formats.
struct MPVI4DeviceSnapshotRev75: Identifiable, Codable, Hashable {
    let id: UUID; let capturedAt: Date; let interfaceSerialHash: String?; let firmware: String?; let vcmScannerVersion: String?
    let controllerFamily: String?; let controllerOS: String?; let connectionMode: MPVI4ConnectionModeRev74
    let creditsObserved: Int?; let pcmWriteLicensed: Bool?; let tcmWriteLicensed: Bool?; let notes: [String]
}

enum MPVI4ExperimentProfileKindRev75: String, Codable, CaseIterable { case baselinePull, fuelReserve, lambdaTracking, airflowBoost, sparkKnock, heatSoak, torqueIntervention, tractionSeparation, trc75Shift }
struct MPVI4ExperimentProfileRev75: Identifiable, Codable, Hashable {
    let id: String; let kind: MPVI4ExperimentProfileKindRev75; let title: String; let requiredSemantics: [String]
    let optionalSemantics: [String]; let deploymentChecks: [String]; let conclusionBoundary: String
}
enum MPVI4ExperimentProfileCatalogRev75 {
    static let profiles:[MPVI4ExperimentProfileRev75] = [
        .init(id:"baseline",kind:.baselinePull,title:"GT500 Baseline Pull",requiredSemantics:["engine.rpm","driver.pedal","throttle"],optionalSemantics:["lambda.commanded","lambda.measured","spark","knock","charge.temperature","boost.map"],deploymentChecks:["Bind exact Build Revision","Bind Calibration Genome","Review Scanner XML semantics","Benchmark acquisition contract"],conclusionBoundary:"A baseline is a comparison reference, not proof that vehicle state is healthy."),
        .init(id:"fuel",kind:.fuelReserve,title:"GT500 Fuel Reserve",requiredSemantics:GT500ExperimentDossierCatalogRev73.dossier(.fuelDelivery).requiredSemantics,optionalSemantics:GT500ExperimentDossierCatalogRev73.dossier(.fuelDelivery).optionalSemantics,deploymentChecks:["Verify lambda sources independently","Verify fuel-pressure semantic if used","Repeat matched pulls"],conclusionBoundary:"No pump-capacity or safe-power claim from lambda alone."),
        .init(id:"lambda",kind:.lambdaTracking,title:"GT500 Lambda Tracking",requiredSemantics:GT500ExperimentDossierCatalogRev73.dossier(.lambdaControl).requiredSemantics,optionalSemantics:GT500ExperimentDossierCatalogRev73.dossier(.lambdaControl).optionalSemantics,deploymentChecks:["Verify external-wideband transform when used","Retain raw voltage/source provenance"],conclusionBoundary:"Deviation is descriptive until an acceptance contract is supplied."),
        .init(id:"air",kind:.airflowBoost,title:"GT500 Airflow / Boost",requiredSemantics:GT500ExperimentDossierCatalogRev73.dossier(.airflowBoost).requiredSemantics,optionalSemantics:GT500ExperimentDossierCatalogRev73.dossier(.airflowBoost).optionalSemantics,deploymentChecks:["Verify pressure reference/units","Record charge-temperature context"],conclusionBoundary:"Observed boost is not an inferred Ford boost target."),
        .init(id:"spark",kind:.sparkKnock,title:"GT500 Spark / Knock",requiredSemantics:GT500ExperimentDossierCatalogRev73.dossier(.sparkKnock).requiredSemantics,optionalSemantics:GT500ExperimentDossierCatalogRev73.dossier(.sparkKnock).optionalSemantics,deploymentChecks:["Verify knock semantic","Preserve sample chronology"],conclusionBoundary:"First-out order is not causal proof."),
        .init(id:"thermal",kind:.heatSoak,title:"GT500 Heat Soak",requiredSemantics:GT500ExperimentDossierCatalogRev73.dossier(.thermal).requiredSemantics,optionalSemantics:GT500ExperimentDossierCatalogRev73.dossier(.thermal).optionalSemantics,deploymentChecks:["Define cold/warm/hot cohort contract","Repeat matched runs","Include recovery run"],conclusionBoundary:"No undocumented Ford thermal threshold is inferred."),
        .init(id:"torque",kind:.torqueIntervention,title:"GT500 Torque Intervention",requiredSemantics:GT500ExperimentDossierCatalogRev73.dossier(.torqueThrottle).requiredSemantics,optionalSemantics:GT500ExperimentDossierCatalogRev73.dossier(.torqueThrottle).optionalSemantics,deploymentChecks:["Review request/delivered semantics","Capture traction and shift context when available"],conclusionBoundary:"Throttle behavior alone cannot name a proprietary limiter."),
        .init(id:"traction",kind:.tractionSeparation,title:"GT500 Traction Separation",requiredSemantics:GT500ExperimentDossierCatalogRev73.dossier(.tractionSeparation).requiredSemantics,optionalSemantics:GT500ExperimentDossierCatalogRev73.dossier(.tractionSeparation).optionalSemantics,deploymentChecks:["Review chassis-state semantics","Capture wheel-speed context"],conclusionBoundary:"Missing chassis evidence remains unknown."),
        .init(id:"shift",kind:.trc75Shift,title:"TR_C75 Shift Cohort",requiredSemantics:GT500ExperimentDossierCatalogRev73.dossier(.trc75Shift).requiredSemantics,optionalSemantics:GT500ExperimentDossierCatalogRev73.dossier(.trc75Shift).optionalSemantics,deploymentChecks:["Bind exact TCM strategy","Choose gear pair/mode/thermal band","Repeat same cohort"],conclusionBoundary:"RPM behavior does not reveal clutch pressure or durability.")
    ]
}

struct MPVI4TelemetryImportDescriptorRev75: Identifiable, Codable, Hashable {
    let id: UUID; let interfaceID: String; let experimentID: String; let recordedAt: Date; let uploadedAt: Date?
    let remoteSessionID: String?; let networkKind: String?; let scannerVersion: String?; let firmware: String?
    let exportedFilename: String?; let exportedSHA256: String?; let notes: [String]
}
struct MPVI4TelemetryAuditRev75: Codable, Hashable { let admissible: Bool; let blockers:[String]; let warnings:[String]; let boundary:String }
enum MPVI4TelemetryAuditEngineRev75 {
    static func audit(_ d:MPVI4TelemetryImportDescriptorRev75, expectedExperimentID:String?) -> MPVI4TelemetryAuditRev75 {
        var b:[String]=[]; var w:[String]=[]
        if d.interfaceID.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty { b.append("Interface identity missing") }
        if d.experimentID.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty { b.append("Experiment identity missing") }
        if let e=expectedExperimentID, e != d.experimentID { b.append("Telemetry session experiment mismatch") }
        if d.scannerVersion == nil { w.append("VCM Scanner version not recorded") }
        if d.firmware == nil { w.append("MPVI4 firmware not recorded") }
        if d.exportedSHA256 == nil { w.append("Exported evidence fingerprint missing") }
        return .init(admissible:b.isEmpty,blockers:b,warnings:w,boundary:"Telemetry upload/review/share lineage proves transport history only. Channel semantics, vehicle state, comparability, and tune validity require separate evidence.")
    }
}

struct MPVI4AcquisitionContractRev75: Identifiable, Codable, Hashable {
    let id:UUID; let profileID:String; let controllerIdentity:String; let scannerConfigFingerprint:String?
    let reviewedSemanticIDs:[String]; let polledSemanticIDs:[String]; let broadcastSemanticIDs:[String]; let externalSemanticIDs:[String]
    let benchmarkRunIDs:[UUID]; let authoredAt:Date
}
struct MPVI4AcquisitionContractAuditRev75:Codable,Hashable { let ready:Bool; let missing:[String]; let warnings:[String] }
enum MPVI4AcquisitionContractEngineRev75 {
    static func audit(_ c:MPVI4AcquisitionContractRev75, profile:MPVI4ExperimentProfileRev75)->MPVI4AcquisitionContractAuditRev75 {
        let reviewed=Set(c.reviewedSemanticIDs); let missing=profile.requiredSemantics.filter{!reviewed.contains($0)}
        var w:[String]=[]; if c.scannerConfigFingerprint == nil {w.append("Scanner configuration fingerprint missing")}; if c.benchmarkRunIDs.isEmpty {w.append("Acquisition rate/quality has not been benchmarked for this exact contract")}
        return .init(ready:missing.isEmpty,missing:missing,warnings:w)
    }
}

struct MPVI4WidebandEvidenceRev75:Codable,Hashable {
    let sourceDevice:String; let inputID:String; let rawVoltageChannel:String; let outputSemantic:String; let outputUnits:String
    let transformDescription:String; let calibrationPointCount:Int; let sharedGroundReferenceDocumented:Bool; let sourceDocumentLocator:String?
}
struct MPVI4WidebandEvidenceAuditRev75:Codable,Hashable { let admitted:Bool; let blockers:[String] }
enum MPVI4WidebandEvidenceEngineRev75 {
    static func audit(_ w:MPVI4WidebandEvidenceRev75)->MPVI4WidebandEvidenceAuditRev75 { var b:[String]=[]
        if w.calibrationPointCount < 2 {b.append("Fewer than two source-backed transform points")}; if w.sourceDocumentLocator == nil {b.append("Wideband transfer-function source missing")}; if w.outputSemantic.isEmpty || w.outputUnits.isEmpty {b.append("Output semantic/units missing")}; if !w.sharedGroundReferenceDocumented {b.append("Ground/reference arrangement not documented")}; return .init(admitted:b.isEmpty,blockers:b)
    }
}

struct MPVI4EvidenceIngestionResultRev75:Codable {
    let profileID:String; let telemetryAudit:MPVI4TelemetryAuditRev75?; let contractAudit:MPVI4AcquisitionContractAuditRev75
    let parsedAdmission:VCMParsedLogAdmission; let pipeline:TuneEvidencePipelineResult; let health:MPVI4EvidenceHealthMapRev74; let nextActions:[String]
    let boundary:String
}
enum MPVI4EvidenceIngestionEngineRev75 {
    static func ingest(log:ParsedLogData, profile:MPVI4ExperimentProfileRev75, contract:MPVI4AcquisitionContractRev75, reviews:[VCMScannerSemanticReview], interfaceReady:Bool, telemetry:MPVI4TelemetryImportDescriptorRev75?=nil)->MPVI4EvidenceIngestionResultRev75 {
        let ca=MPVI4AcquisitionContractEngineRev75.audit(contract,profile:profile)
        let ta=telemetry.map{MPVI4TelemetryAuditEngineRev75.audit($0,expectedExperimentID:contract.profileID)}
        let p=TuneEvidencePipelineRev70.run(log:log,reviews:reviews,blockedConclusion:profile.title)
        let health=MPVI4EvidenceHealthEngineRev74.build(interfaceReady:interfaceReady,controller:contract.controllerIdentity.isEmpty ? nil:contract.controllerIdentity,reviewedCount:p.admission.admittedSemanticIDs.count,benchmarkRuns:contract.benchmarkRunIDs.count,experimentID:contract.profileID)
        var next=ca.missing.map{"Review/add required semantic: \($0)"}; next += ca.warnings; next += ta?.blockers.map{"Telemetry: \($0)"} ?? []; next += ta?.warnings.map{"Telemetry provenance: \($0)"} ?? []; if p.reconstruction == nil {next.append(p.nextAction)}
        return .init(profileID:profile.id,telemetryAudit:ta,contractAudit:ca,parsedAdmission:p.admission,pipeline:p,health:health,nextActions:Array(NSOrderedSet(array:next)) as? [String] ?? next,boundary:"Rev75 ingests exported/parsed evidence only. It does not connect to MPVI4, automate flashes, call VCM Telemetry APIs, or decode proprietary HPT/HPL binaries.")
    }
}

import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

// Rev69 integration layer: turns the accumulated Tune engines into one persisted workflow.
struct TuneWorkspaceSnapshot: Codable, Equatable {
    let vehicleID: UUID?
    let buildRevisionID: UUID?
    let calibration: CalibrationFingerprint?
    let baselineExperiment: PersistedTuneExperiment?
    let logContract: TuneLogContract?
    let unresolvedDiagnosticBlockers: [String]
    let acquisitionQuality: Double?
    let readiness: TuneReadinessAssessment
    let missing: [String]
    let boundary: String
}

enum TuneWorkspaceResolver {
    static func resolve(vehicleID: UUID?, buildRevisionID: UUID?, calibrations: [CalibrationFingerprint], experiments: [PersistedTuneExperiment], contracts: [TuneLogContract], unresolvedDiagnosticBlockers: [String], acquisitionQuality: Double?) -> TuneWorkspaceSnapshot {
        let candidates = calibrations.filter { c in
            (vehicleID == nil || c.vehicleID == vehicleID) && (buildRevisionID == nil || c.buildRevisionID == buildRevisionID)
        }
        let calibration = candidates.first
        let baseline = experiments.first { e in
            (vehicleID == nil || e.vehicleID == vehicleID) &&
            (buildRevisionID == nil || e.buildRevisionID == buildRevisionID) &&
            (calibration == nil || e.pcmCalibrationID == calibration?.id || e.tcmCalibrationID == calibration?.id)
        }
        let contract = contracts.first { $0.calibrationFingerprintID == calibration?.id && (buildRevisionID == nil || $0.buildRevisionID == buildRevisionID) }
        let readiness = TuneReadinessEngine.assess(vehiclePresent: vehicleID != nil, calibrationIdentified: calibration != nil, baselineAvailable: baseline != nil, unresolvedDiagnosticBlockers: unresolvedDiagnosticBlockers, acquisitionQuality: acquisitionQuality)
        var missing:[String] = []
        if vehicleID == nil { missing.append("Active vehicle") }
        if buildRevisionID == nil { missing.append("Exact Build Revision") }
        if calibration == nil { missing.append("Calibration Genome fingerprint bound to this build") }
        if baseline == nil { missing.append("Comparable baseline experiment bound to this calibration/build") }
        if contract == nil { missing.append("Scanner/log contract bound to this calibration/build") }
        return .init(vehicleID:vehicleID,buildRevisionID:buildRevisionID,calibration:calibration,baselineExperiment:baseline,logContract:contract,unresolvedDiagnosticBlockers:unresolvedDiagnosticBlockers,acquisitionQuality:acquisitionQuality,readiness:readiness,missing:missing,boundary:"Readiness is derived from persisted identity and experiment records. Presence of records does not establish semantic correctness, mechanical safety, emissions legality, or validation outside the tested envelope.")
    }
}

struct TuneWorkflowCheckpoint: Identifiable, Codable, Equatable {
    let id: UUID
    let stage: String
    let complete: Bool
    let evidenceIDs: [UUID]
    let blockers: [String]
}
struct TuneWorkflowPlan: Codable, Equatable { let checkpoints:[TuneWorkflowCheckpoint]; let nextAction:String; let boundary:String }

enum TuneWorkflowCoordinatorRev69 {
    static func plan(_ s:TuneWorkspaceSnapshot, semanticReviewCount:Int, validationEnvelopePresent:Bool, reconstructionPresent:Bool) -> TuneWorkflowPlan {
        let rows:[TuneWorkflowCheckpoint] = [
            .init(id:UUID(),stage:"Vehicle + Build identity",complete:s.vehicleID != nil && s.buildRevisionID != nil,evidenceIDs:[],blockers:s.buildRevisionID == nil ? ["Select exact Build Revision"] : []),
            .init(id:UUID(),stage:"Calibration Genome",complete:s.calibration != nil,evidenceIDs:s.calibration.map{[$0.id]} ?? [],blockers:s.calibration == nil ? ["Capture immutable original read/fingerprint"] : []),
            .init(id:UUID(),stage:"Scanner semantic review",complete:semanticReviewCount > 0,evidenceIDs:[],blockers:semanticReviewCount == 0 ? ["Review experiment-critical Scanner semantics"] : []),
            .init(id:UUID(),stage:"Baseline experiment",complete:s.baselineExperiment != nil,evidenceIDs:s.baselineExperiment.map{[$0.id]} ?? [],blockers:s.baselineExperiment == nil ? ["Acquire matched baseline"] : []),
            .init(id:UUID(),stage:"Pull reconstruction",complete:reconstructionPresent,evidenceIDs:[],blockers:reconstructionPresent ? [] : ["Reconstruct a semantically admissible experiment"]),
            .init(id:UUID(),stage:"Validation envelope",complete:validationEnvelopePresent,evidenceIDs:[],blockers:validationEnvelopePresent ? [] : ["Validate repeatability within declared envelope"])
        ]
        let next = rows.first(where:{!$0.complete})?.blockers.first ?? "Review evidence replay and preserve the validated envelope."
        return .init(checkpoints:rows,nextAction:next,boundary:"Workflow completion means required evidence stages are represented. It is not an automatic tune approval or causal proof.")
    }
}

struct TuneArchiveMetadataV8: Codable {
    var calibrationGenomes:[CalibrationFingerprint]
    var experiments:[PersistedTuneExperiment]
    var logContracts:[TuneLogContract]
    var semanticReviews:[VCMScannerSemanticReview]
    static let empty = TuneArchiveMetadataV8(calibrationGenomes:[],experiments:[],logContracts:[],semanticReviews:[])
    static let boundary = "Schema v8 archives Tune metadata and provenance, not proprietary HPT/HPL decoding. Large source evidence remains externalized/fingerprinted by the existing archive member model."
}

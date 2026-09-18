import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

// Rev62: calibration truth debt, strategy hypotheses, straight-line attribution,
// TDN evidence replay, and controller/strategy-safe semantic promotion.

enum CalibrationSemanticReviewState: String, Codable { case researchTarget, candidate, reviewed, disputed, rejected }
struct CalibrationSemanticEvidence: Identifiable, Codable, Equatable {
    let id: UUID; let semanticID: String; let controller: TuningControllerFamily; let strategyID: String?
    let parameterID: String?; let sourcePath: String?; let units: String?; let axes: [String]
    let authority: CalibrationEvidenceAuthority; let reviewState: CalibrationSemanticReviewState
    let artifactID: UUID?; let locator: String?; let notes: String
}
struct CalibrationSemanticAdmission: Codable, Equatable { let admitted: Bool; let blockers:[String]; let boundary:String }
enum CalibrationSemanticPromotionGate {
    static func assess(record: CalibrationSemanticRecord, evidence: CalibrationSemanticEvidence) -> CalibrationSemanticAdmission {
        var blockers:[String]=[]
        if record.controller != evidence.controller { blockers.append("Controller family mismatch") }
        if evidence.reviewState != .reviewed { blockers.append("Evidence has not completed semantic review") }
        if evidence.parameterID?.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty != false { blockers.append("Exact parameter identity is missing") }
        if evidence.locator?.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty != false { blockers.append("Exact evidence locator is missing") }
        if !record.applicableStrategies.isEmpty, let s=evidence.strategyID, !record.applicableStrategies.contains(s) { blockers.append("Strategy is outside the semantic record applicability") }
        return .init(admitted:blockers.isEmpty,blockers:blockers,boundary:"Admission means the evidence is eligible to support this exact controller/strategy semantic record. It does not establish mechanical safety, optimal values, or transferability to another controller.")
    }
}

struct CalibrationTruthDebtItem: Identifiable, Codable, Equatable {
    let id:String; let semanticID:String; let controller:TuningControllerFamily; let domain:String
    let status:CalibrationSemanticStatus; let score:Int; let blockers:[String]; let acquisitionTargetIDs:[String]
    let boundary:String
}
enum CalibrationTruthDebtEngine {
    static func rank(records:[CalibrationSemanticRecord], evidence:[CalibrationSemanticEvidence], targets:[ResearchAcquisitionTarget] = HPTunersAcquisitionMatrix.targets) -> [CalibrationTruthDebtItem] {
        records.map { r in
            let ev=evidence.filter{$0.semanticID == r.id && $0.controller == r.controller}
            var blockers:[String]=[]; var score=0
            switch r.status { case .unknown: score += 100; blockers.append("Exact parameter semantics absent"); case .inferred: score += 80; blockers.append("PredatorLab inference requires external evidence"); case .professional: score += 55; blockers.append("Professional interpretation lacks higher-authority semantic confirmation"); case .exposed: score += 65; blockers.append("Parameter exposure does not establish complete semantics"); case .empirical: score += 45; blockers.append("Empirical mapping remains configuration-bound"); case .documented: score += 15 }
            if ev.isEmpty { score += 45; blockers.append("No claim-level semantic evidence attached") }
            if !ev.contains(where:{$0.reviewState == .reviewed}) { score += 35; blockers.append("No reviewed evidence") }
            if r.applicableStrategies.isEmpty { score += 20; blockers.append("Strategy applicability not pinned") }
            let ids=targets.filter { t in let h=(t.title+" "+t.exactArtifact+" "+t.keywords.joined(separator:" ")).lowercased(); return h.contains(r.controller.rawValue.lowercased()) || r.engineeringDomain.lowercased().split(separator:" ").contains(where:{h.contains($0)}) }.map(\.id)
            return .init(id:"debt.\(r.id)",semanticID:r.id,controller:r.controller,domain:r.engineeringDomain,status:r.status,score:score,blockers:Array(Set(blockers)).sorted(),acquisitionTargetIDs:ids,boundary:"Calibration truth debt is a research-priority measure. It is not uncertainty probability, tune quality, or permission to edit a parameter.")
        }.sorted{$0.score > $1.score}
    }
}

enum TuneHypothesisDomain:String,Codable { case torque, fuel, spark, airflowBoost, thermal, transmission, traction, unknown }
struct TuneStrategyHypothesis:Identifiable,Codable,Equatable { let id:String; let title:String; let domain:TuneHypothesisDomain; let requiredSemanticIDs:[String]; let calibrationSemanticIDs:[String]; let evidenceFit:Double; let missingSemanticIDs:[String]; let nextMeasurement:String; let boundary:String }
enum TuneStrategyPlannerRev62 {
    static func plan(observations:[LimiterObservation], hypotheses:[TuneStrategyHypothesis]) -> [TuneStrategyHypothesis] {
        let verified=Set(observations.filter(\.semanticsVerified).map(\.channelSemanticID))
        return hypotheses.map { h in
            let required=Set(h.requiredSemanticIDs), matched=required.intersection(verified), missing=required.subtracting(verified).sorted()
            let fit=required.isEmpty ? 0 : Double(matched.count)/Double(required.count)
            return .init(id:h.id,title:h.title,domain:h.domain,requiredSemanticIDs:h.requiredSemanticIDs,calibrationSemanticIDs:h.calibrationSemanticIDs,evidenceFit:fit,missingSemanticIDs:missing,nextMeasurement:missing.first.map{"Acquire and verify \($0) before calibration review."} ?? "Repeat a controlled comparable experiment before attributing the behavior to calibration.",boundary:"Hypothesis evidence-fit ranks measurement coverage only. It is not calibrated probability, diagnosis, or a recommended calibration value.")
        }.sorted{($0.evidenceFit,-$0.missingSemanticIDs.count) > ($1.evidenceFit,-$1.missingSemanticIDs.count)}
    }
}

struct StraightLineWindow:Identifiable,Codable,Equatable { let id:UUID; let startTime:Double; let endTime:Double; let startSpeed:Double?; let endSpeed:Double?; let elapsed:Double; let rpmGain:Double?; let meanLongitudinalG:Double?; let sampleCount:Int }
struct DriverCalibrationAttribution:Codable,Equatable { let admitted:Bool; let driverDifferenceSignals:[String]; let calibrationEvidenceSignals:[String]; let blockers:[String]; let boundary:String }
enum StraightLineIsolationEngine {
    static func window(samples:[SynchronizedTrackSample], start:Double, end:Double) -> StraightLineWindow? {
        let rows=samples.filter{$0.referenceTime >= start && $0.referenceTime <= end}.sorted{$0.referenceTime<$1.referenceTime}; guard rows.count >= 2, end>start else{return nil}
        return .init(id:UUID(),startTime:start,endTime:end,startSpeed:rows.first?.speed,endSpeed:rows.last?.speed,elapsed:end-start,rpmGain:{ guard let a=rows.first?.rpm,let b=rows.last?.rpm else{return nil};return b-a }(),meanLongitudinalG:nil,sampleCount:rows.count)
    }
    static func attribute(comparability:TuneExperimentComparability, throttleComparable:Bool?, brakingComparable:Bool?, steeringComparable:Bool?, calibrationChanged:Bool, verifiedPowertrainResponseAvailable:Bool) -> DriverCalibrationAttribution {
        var driver:[String]=[], cal:[String]=[], blockers=comparability.hardBlockers
        if throttleComparable == false { driver.append("Throttle application differs") }; if brakingComparable == false { driver.append("Braking behavior differs") }; if steeringComparable == false { driver.append("Steering/path behavior differs") }
        if calibrationChanged { cal.append("Calibration revision differs") }; if verifiedPowertrainResponseAvailable { cal.append("Verified powertrain response evidence is available") }
        if !comparability.comparable { blockers.append("Experiments fail the comparability firewall") }; if !driver.isEmpty { blockers.append("Driver behavior is not sufficiently controlled") }; if !verifiedPowertrainResponseAvailable { blockers.append("No verified powertrain-response evidence for attribution") }
        return .init(admitted:blockers.isEmpty,driverDifferenceSignals:driver,calibrationEvidenceSignals:cal,blockers:Array(Set(blockers)).sorted(),boundary:"Admission permits a controlled attribution analysis. It never turns elapsed-time improvement into proof that calibration caused the improvement.")
    }
}

enum TuneReplayStage:String,Codable { case read, synchronized, calibration, flash, scannerContract, log, track, flightRecorder, analysis, validation, decision }
struct TuneReplayEvent:Identifiable,Codable,Equatable { let id:UUID; let occurredAt:Date; let stage:TuneReplayStage; let artifactID:UUID?; let calibrationID:UUID?; let title:String; let provenance:String }
struct TuneEvidenceReplay:Codable,Equatable { let events:[TuneReplayEvent]; let missingStages:[TuneReplayStage]; let completeForReview:Bool; let boundary:String }
enum TDNTuneEvidenceReplayEngine {
    static func reconstruct(lineage:[TDNLineageEvent], flashEvents:[CalibrationFlashEvent], experiment:PersistedTuneExperiment?, validationRecorded:Bool) -> TuneEvidenceReplay {
        var out:[TuneReplayEvent]=[]
        for e in lineage.sorted(by:{$0.occurredAt<$1.occurredAt}) {
            let stage:TuneReplayStage
            switch e.state { case .vehicleRead: stage = .read; case .synchronized: stage = .synchronized; case .tuneReceived,.revisionReceived: stage = .calibration; case .flashStarted,.flashCompleted: stage = .flash; case .logRecorded,.logDelivered: stage = .log; case .accepted,.rejected: stage = .decision }
            out.append(.init(id:e.id,occurredAt:e.occurredAt,stage:stage,artifactID:e.artifactID,calibrationID:e.calibrationID,title:e.state.rawValue,provenance:"TDN lineage observation"))
        }
        for f in flashEvents { out.append(.init(id:f.id,occurredAt:f.occurredAt,stage:.flash,artifactID:nil,calibrationID:f.toCalibrationID,title:"Calibration flash",provenance:"PredatorLab flash record")) }
        if let x=experiment { out.append(.init(id:x.id,occurredAt:x.createdAt,stage:.analysis,artifactID:nil,calibrationID:x.pcmCalibrationID,title:"Tune experiment reconstructed",provenance:"PredatorLab experiment record")) }
        if validationRecorded { out.append(.init(id:UUID(),occurredAt:.now,stage:.validation,artifactID:nil,calibrationID:experiment?.pcmCalibrationID,title:"Validation recorded",provenance:"PredatorLab validation record")) }
        out.sort{$0.occurredAt<$1.occurredAt}; let present=Set(out.map(\.stage)); let required:[TuneReplayStage]=[.read,.calibration,.flash,.log,.analysis,.validation]; let missing=required.filter{!present.contains($0)}
        return .init(events:out,missingStages:missing,completeForReview:missing.isEmpty,boundary:"Replay reconstructs recorded evidence lineage. Missing stages remain missing; event order does not prove causation or server-side state.")
    }
}

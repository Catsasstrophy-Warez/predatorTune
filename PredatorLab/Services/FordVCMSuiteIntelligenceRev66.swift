import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening" lineage
// this project ported from (see HANDOFF.md), NOT this app's own version history.
// Status: Current. Builds on Rev63/64/65 (ScannerSemanticBinding, VCMScannerSemanticReview)
// to add calibration dependency graphs, diff blast-radius estimation, the
// "why can't PredatorLab conclude X" explainer, first-out intervention ordering, Scanner
// polling-budget optimization, and TR_C75 shift-cohort comparison.
// Rev66: deeper Ford/VCM Suite evidence reasoning. No undocumented stock values or unsafe tuning prescriptions.

enum CalibrationChangeRiskDomain: String, Codable, CaseIterable { case combustion, fuel, airflow, thermal, supercharger, engineMechanical, transmission, driveline, emissions, traction, unknownInteraction }

struct CalibrationFamilyDependency: Identifiable, Codable, Hashable {
    let id:String; let controller:TuningControllerFamily; let fromFamily:String; let toFamily:String
    let evidenceClass:VCMSuiteEvidenceClass; let exactLocator:String?; let verified:Bool; let note:String
}
struct CalibrationDependencyGraph: Codable { let controller:TuningControllerFamily; let nodes:[String]; let edges:[CalibrationFamilyDependency]; let boundary:String }

enum FordCalibrationDependencyGraphEngine {
    static func build(controller:TuningControllerFamily, reviewedEdges:[CalibrationFamilyDependency]) -> CalibrationDependencyGraph {
        let applicable=reviewedEdges.filter{$0.controller == controller}
        let nodes=Array(Set(applicable.flatMap{[$0.fromFamily,$0.toFamily]})).sorted()
        return .init(controller:controller,nodes:nodes,edges:applicable,boundary:"A dependency edge is admitted only with explicit provenance for the exact controller/strategy. Similar names, chronology, or shared engine family do not establish Ford calibration dependency semantics.")
    }
}

struct CalibrationDiffItem: Identifiable, Codable, Hashable { let id:String; let parameterIdentity:String; let family:String; let changedCellCount:Int; let magnitudeNormalized:Double?; let evidenceClass:VCMSuiteEvidenceClass }
struct CalibrationBlastRadius: Codable { let familiesChanged:Int; let cellsChanged:Int; let riskDomains:[CalibrationChangeRiskDomain]; let attributionStrength:Double; let warnings:[String]; let boundary:String }
enum CalibrationDiffBlastRadiusEngine {
    static func assess(_ items:[CalibrationDiffItem], mappedRisks:[String:[CalibrationChangeRiskDomain]]) -> CalibrationBlastRadius {
        let families=Set(items.map(\.family)); let cells=items.reduce(0){$0 + max(0,$1.changedCellCount)}
        let risks=Array(Set(items.flatMap{mappedRisks[$0.family] ?? [.unknownInteraction]})).sorted{$0.rawValue < $1.rawValue}
        var strength = 1.0
        if families.count > 1 { strength -= min(0.55,Double(families.count-1)*0.12) }
        if cells > 100 { strength -= 0.15 }
        if risks.contains(.unknownInteraction) { strength -= 0.15 }
        let warnings=(families.count > 1 ? ["Multiple calibration families changed; causal attribution is weaker."]:[]) + (risks.contains(.unknownInteraction) ? ["At least one changed family has unresolved interaction risk."]:[])
        return .init(familiesChanged:families.count,cellsChanged:cells,riskDomains:risks,attributionStrength:max(0,strength),warnings:warnings,boundary:"Blast radius estimates experimental attribution difficulty, not tune quality, safety, or controller durability.")
    }
}

enum TuneBlockedConclusionReason: String, Codable { case missingChannel, semanticUnreviewed, wrongController, strategyUnknown, buildUnknown, calibrationUnknown, diagnosticBlocker, acquisitionQuality, comparability, repeatability, authoritativeArtifact, causalEdgeUnverified }
struct TuneConclusionRequirement: Identifiable, Codable, Hashable { let id:String; let reason:TuneBlockedConclusionReason; let requirement:String; let candidateArtifactIDs:[String]; let nextAction:String }
struct TuneConclusionExplanation: Codable { let conclusion:String; let admitted:Bool; let requirements:[TuneConclusionRequirement]; let boundary:String }
enum WhyCantPredatorLabConcludeEngine {
    static func explain(conclusion:String, requiredSignals:[String], reviews:[VCMScannerSemanticReview], controller:TuningControllerFamily, strategyKnown:Bool, buildKnown:Bool, calibrationKnown:Bool, diagnosticsClear:Bool, comparable:Bool, repeatCount:Int, causalEdgesVerified:Bool) -> TuneConclusionExplanation {
        let admitted=reviews.filter{$0.admittedForAnalysis && $0.binding.controller == controller}
        var r:[TuneConclusionRequirement]=[]
        for signal in requiredSignals where !admitted.contains(where:{$0.binding.canonicalSignalID == signal}) {
            r.append(.init(id:"signal.\(signal)",reason:.missingChannel,requirement:"Reviewed semantic for \(signal)",candidateArtifactIDs:["hpt.scanner.stock"],nextAction:"Acquire the exact Scanner XML/HPL evidence and review Parameter ID, source, transform, units, controller and strategy."))
        }
        if !strategyKnown { r.append(.init(id:"strategy",reason:.strategyUnknown,requirement:"Exact controller strategy identity",candidateArtifactIDs:["hpt.gt500.pcm.definitions","hpt.trc75.definitions"],nextAction:"Capture applicable VCM Editor/Scanner strategy identity without borrowing another controller lineage.")) }
        if !buildKnown { r.append(.init(id:"build",reason:.buildUnknown,requirement:"Exact Build Revision",candidateArtifactIDs:[],nextAction:"Bind the experiment to the immutable vehicle Build Revision.")) }
        if !calibrationKnown { r.append(.init(id:"calibration",reason:.calibrationUnknown,requirement:"Exact calibration fingerprint",candidateArtifactIDs:[],nextAction:"Fingerprint and bind the installed calibration artifact.")) }
        if !diagnosticsClear { r.append(.init(id:"diagnostics",reason:.diagnosticBlocker,requirement:"Resolve active diagnostic blockers",candidateArtifactIDs:[],nextAction:"Diagnose and disposition the mechanical/electrical fault before calibration attribution.")) }
        if !comparable { r.append(.init(id:"comparability",reason:.comparability,requirement:"Comparable baseline/candidate experiments",candidateArtifactIDs:[],nextAction:"Repeat under controlled fuel, build, thermal, scanner and calibration conditions.")) }
        if repeatCount < 2 { r.append(.init(id:"repeatability",reason:.repeatability,requirement:"Repeatability evidence",candidateArtifactIDs:[],nextAction:"Collect repeated comparable observations before promoting the conclusion.")) }
        if !causalEdgesVerified { r.append(.init(id:"causality",reason:.causalEdgeUnverified,requirement:"Evidence for the claimed causal edge",candidateArtifactIDs:[],nextAction:"Treat first-out chronology as evidence only; acquire independent evidence for the controller relationship.")) }
        return .init(conclusion:conclusion,admitted:r.isEmpty,requirements:r,boundary:"A blocked conclusion is a research and experiment routing result. It is not evidence that the opposite conclusion is true.")
    }
}

struct FirstOutObservation: Identifiable, Codable, Hashable { let id:String; let time:Double; let canonicalSignalID:String; let state:String; let locator:String }
struct TorqueInterventionFirstOut: Codable { let ordered:[FirstOutObservation]; let first:FirstOutObservation?; let candidateMechanisms:[String]; let boundary:String }
enum TorqueInterventionFirstOutEngine {
    static func analyze(_ observations:[FirstOutObservation], admittedSemanticIDs:Set<String>) -> TorqueInterventionFirstOut {
        let ordered=observations.filter{admittedSemanticIDs.contains($0.canonicalSignalID)}.sorted{$0.time < $1.time}
        let mechanisms=Array(Set(ordered.map{$0.canonicalSignalID.components(separatedBy:".").first ?? "unknown"})).sorted()
        return .init(ordered:ordered,first:ordered.first,candidateMechanisms:mechanisms,boundary:"First-out establishes observed temporal order among admitted signals. It does not by itself identify Ford software causation or the active limiter.")
    }
}

struct ScannerPollingBudgetItem: Identifiable, Codable, Hashable { let id:String; let canonicalSignalID:String; let sourceKind:String; let criticality:Int; let requestedIntervalMS:Int? }
struct ScannerPollingBudgetPlan: Codable { let keep:[ScannerPollingBudgetItem]; let slowCandidates:[ScannerPollingBudgetItem]; let removeCandidates:[ScannerPollingBudgetItem]; let warnings:[String]; let boundary:String }
enum ScannerPollingBudgetOptimizerRev66 {
    static func plan(_ items:[ScannerPollingBudgetItem]) -> ScannerPollingBudgetPlan {
        var keep:[ScannerPollingBudgetItem]=[], slow:[ScannerPollingBudgetItem]=[], remove:[ScannerPollingBudgetItem]=[]
        for i in items {
            let source=i.sourceKind.lowercased()
            if source.contains("broadcast") || source.contains("external") || i.criticality >= 8 { keep.append(i) }
            else if source.contains("polled") && i.criticality <= 2 { remove.append(i) }
            else if source.contains("polled") && i.criticality <= 5 { slow.append(i) }
            else { keep.append(i) }
        }
        return .init(keep:keep,slowCandidates:slow,removeCandidates:remove,warnings:["PredatorLab does not predict an exact sampling-rate gain; verify acquisition performance on the actual controller/interface."],boundary:"Optimization follows documented polling-cost categories and experiment criticality. It never removes a required safety/abort channel automatically.")
    }
}

struct TRC75ShiftCohortKey: Codable, Hashable { let fromGear:Int; let toGear:Int; let driveMode:String?; let tcmStrategy:String?; let thermalBand:String? }
struct TRC75ShiftCohortComparison: Codable { let key:TRC75ShiftCohortKey; let baselineCount:Int; let candidateCount:Int; let durationDeltaMedian:Double?; let rpmDropDeltaMedian:Double?; let admitted:Bool; let blockers:[String]; let boundary:String }
enum TRC75ShiftCohortComparisonEngineRev66 {
    static func compare(key:TRC75ShiftCohortKey, baseline:[TRC75ShiftFingerprint], candidate:[TRC75ShiftFingerprint], comparable:Bool) -> TRC75ShiftCohortComparison {
        func median(_ x:[Double])->Double? { let a=x.sorted(); guard !a.isEmpty else{return nil}; return a.count%2==1 ? a[a.count/2] : (a[a.count/2-1]+a[a.count/2])/2 }
        var blockers:[String]=[]; if !comparable { blockers.append("Experiment comparability firewall failed") }; if baseline.count < 2 || candidate.count < 2 { blockers.append("At least two shifts per cohort required") }
        let bd=median(baseline.map{$0.duration}); let cd=median(candidate.map{$0.duration}); let br=median(baseline.map{$0.rpmDrop}); let cr=median(candidate.map{$0.rpmDrop})
        return .init(key:key,baselineCount:baseline.count,candidateCount:candidate.count,durationDeltaMedian:(bd != nil && cd != nil) ? cd!-bd!:nil,rpmDropDeltaMedian:(br != nil && cr != nil) ? cr!-br!:nil,admitted:blockers.isEmpty,blockers:blockers,boundary:"A shift-cohort delta describes repeated observed behavior inside the tested envelope. It does not establish clutch pressure, durability, or calibration causality without the required semantics and evidence.")
    }
}

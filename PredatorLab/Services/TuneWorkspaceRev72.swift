import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

// Rev72: task-centered tuning workspace, Scanner contract builder, and evidence-complete comparison orchestration.
// Public VCM Suite documentation informs artifact structure only; no proprietary Ford calibration semantics are invented.

struct ScannerContractRecommendationRev72: Identifiable, Codable, Hashable {
    enum Action: String, Codable { case keep, add, review, slowCandidate, removeCandidate }
    let id: String
    let semanticID: String
    let action: Action
    let reason: String
    let source: String?
    let pollingInterval: String?
}

struct ScannerContractPlanRev72: Codable {
    let recommendations: [ScannerContractRecommendationRev72]
    let missingRequiredSemantics: [String]
    let admittedRequiredSemantics: [String]
    let boundary: String
}

enum ScannerContractBuilderRev72 {
    static func build(requiredSemanticIDs:[String], reviews:[VCMScannerSemanticReview], xmlCandidates:[VCMScannerXMLCandidate]=[]) -> ScannerContractPlanRev72 {
        let admitted = Dictionary(uniqueKeysWithValues: reviews.filter(\.admittedForAnalysis).compactMap { r in
            r.binding.canonicalSignalID.map { ($0,r) }
        })
        let required = Set(requiredSemanticIDs)
        var recs:[ScannerContractRecommendationRev72] = []
        for semantic in required.sorted() {
            if let review=admitted[semantic] {
                recs.append(.init(id:"keep-\(semantic)",semanticID:semantic,action:.keep,reason:"Required semantic is reviewed and admitted for analysis.",source:review.binding.parameterSource,pollingInterval:review.binding.pollingInterval))
            } else {
                let candidate=xmlCandidates.first { c in reviews.contains { $0.binding.canonicalSignalID == semantic && ($0.binding.parameterID == c.parameterID || $0.binding.displayName == c.displayName) } }
                recs.append(.init(id:"add-\(semantic)",semanticID:semantic,action:candidate == nil ? .add:.review,reason:candidate == nil ? "Required semantic is missing from admitted evidence; acquire and review an applicable Scanner channel.":"A Scanner XML candidate may satisfy this purpose but still requires controller/strategy/units/physical-semantic review.",source:candidate?.parameterSource,pollingInterval:candidate?.pollingInterval))
            }
        }
        for r in reviews where r.admittedForAnalysis {
            guard let semantic=r.binding.canonicalSignalID, !required.contains(semantic) else { continue }
            let source=r.binding.parameterSource.lowercased()
            let action:ScannerContractRecommendationRev72.Action = source.contains("broadcast") || source.contains("external") || source.contains("serial") || source.contains("mpvi") ? .keep:.slowCandidate
            recs.append(.init(id:"optional-\(semantic)",semanticID:semantic,action:action,reason:action == .keep ? "Optional admitted channel has no inferred vehicle polling penalty from its reviewed source classification; keep if context is useful.":"Optional polled channel is a candidate for a slower interval or task-specific removal after real acquisition-rate measurement.",source:r.binding.parameterSource,pollingInterval:r.binding.pollingInterval))
        }
        let admittedRequired=required.intersection(Set(admitted.keys)).sorted()
        return .init(recommendations:recs,missingRequiredSemantics:Array(required.subtracting(Set(admitted.keys))).sorted(),admittedRequiredSemantics:admittedRequired,boundary:"This plan optimizes evidence purpose, not a guaranteed sample rate. HP Tuners documents that more polled channels can slow vehicle collection, while broadcast and external sources behave differently. Actual acquisition performance must be measured on the connected vehicle/interface.")
    }
}

struct TuneEvidenceWorkspaceRev72: Codable {
    let current:TuneEvidencePipelineResult?
    let baseline:TuneEvidencePipelineResult?
    let comparison:MatchedPullComparisonRev71?
    let heatSoak:HeatSoakCohortRev71?
    let shifts:[TRC75ShiftWindowRev71]
    let validation:TuneValidationAssessment?
    let summary:UnifiedTuneEvidenceSummaryRev71
    let scannerPlan:ScannerContractPlanRev72
    let boundary:String
}

enum TuneEvidenceWorkspaceEngineRev72 {
    static func build(currentLog:ParsedLogData?, baselineLog:ParsedLogData?, reviews:[VCMScannerSemanticReview], experimentComparable:Bool, sameBuild:Bool, sameFuel:Bool, validationEnvelope:TuneValidationEnvelope?=nil, unsafeAbortObserved:Bool=false, regressionObserved:Bool=false) -> TuneEvidenceWorkspaceRev72 {
        let current=currentLog.map { TuneEvidencePipelineRev70.run(log:$0,reviews:reviews) }
        let baseline=baselineLog.map { TuneEvidencePipelineRev70.run(log:$0,reviews:reviews) }
        let comparison:(MatchedPullComparisonRev71?) = (baseline != nil && current != nil) ? MatchedPullComparisonEngineRev71.compare(baseline:baseline!,candidate:current!,experimentComparable:experimentComparable,sameBuild:sameBuild,sameFuel:sameFuel):nil
        let cohort=HeatSoakCohortEngineRev71.build([baseline,current].compactMap{$0})
        let shifts:( [TRC75ShiftWindowRev71] ) = (currentLog != nil && current != nil) ? TRC75ShiftSegmenterRev71.extract(log:currentLog!,admission:current!.admission):[]
        let validation=validationEnvelope.map { FordTuneValidationEngine.assess($0,unsafeAbortObserved:unsafeAbortObserved,regressionObserved:regressionObserved) }
        let summary=UnifiedTuneEvidenceExplainerRev71.summarize(pipeline:current,comparison:comparison,heatSoak:cohort.runCount >= 2 ? cohort:nil,shifts:shifts)
        let required=current?.closure?.missingSemantics.isEmpty == false ? Array(Set(GT500HighLoadPullReconstructorRev68.coreSignals).union(current!.closure!.missingSemantics)).sorted() : GT500HighLoadPullReconstructorRev68.coreSignals
        let scannerPlan=ScannerContractBuilderRev72.build(requiredSemanticIDs:required,reviews:reviews)
        return .init(current:current,baseline:baseline,comparison:comparison,heatSoak:cohort.runCount >= 2 ? cohort:nil,shifts:shifts,validation:validation,summary:summary,scannerPlan:scannerPlan,boundary:"Workspace orchestration preserves the distinction between calibration difference, flash lineage, observed response, comparability, and validation. A completed workflow is not universal tune approval or causal proof.")
    }
}

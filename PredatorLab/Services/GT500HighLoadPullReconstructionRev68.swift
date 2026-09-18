import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

// Rev68: end-to-end high-load pull reconstruction. This layer never supplies undocumented
// Ford thresholds or HP Tuners parameter semantics. All semantic admission is upstream.

enum PullPhaseKind: String, Codable, CaseIterable { case entry, ramp, sustainedLoad, shift, intervention, recovery }

struct PullPhase: Identifiable, Codable, Hashable {
    let id: String
    let kind: PullPhaseKind
    let startTime: Double
    let endTime: Double
    let evidence: [String]
}

struct PullChannelCoverage: Codable, Hashable {
    let required: [String]
    let admitted: [String]
    var missing: [String] { required.filter { !admitted.contains($0) } }
    var fraction: Double { required.isEmpty ? 1 : Double(admitted.count) / Double(required.count) }
}

struct HighLoadPullReconstruction: Codable {
    let startTime: Double?
    let endTime: Double?
    let phases: [PullPhase]
    let stableWindows: [StableWindow]
    let coverage: PullChannelCoverage
    let lambda: LambdaDeviationFingerprint
    let sparkKnock: SparkKnockChronology
    let thermal: ThermalDerateFingerprint
    let firstOut: InterventionSeparationResult
    let evidenceGaps: [String]
    let boundary: String
}

enum GT500HighLoadPullReconstructorRev68 {
    static let coreSignals = ["engine.rpm","driver.pedal","throttle","lambda.commanded","lambda.measured","spark","charge.temperature"]

    static func reconstruct(samples: [StableWindowSample], admittedSemantics: Set<String>, observations: [FirstOutObservation]) -> HighLoadPullReconstruction {
        let sorted = samples.sorted { $0.time < $1.time }
        let coverage = PullChannelCoverage(required: coreSignals, admitted: coreSignals.filter { admittedSemantics.contains($0) })
        let stable = StableWindowExtractorRev67.extract(sorted, minimumDuration: 0.5)
        var phases: [PullPhase] = []
        if let first = sorted.first, let last = sorted.last {
            phases.append(.init(id:"entry", kind:.entry, startTime:first.time, endTime:min(last.time, first.time + 0.25), evidence:["sample boundary"]))
            if let w = stable.max(by: { ($0.endTime-$0.startTime) < ($1.endTime-$1.startTime) }) {
                phases.append(.init(id:"sustained", kind:.sustainedLoad, startTime:w.startTime, endTime:w.endTime, evidence:["stable-input window"]))
            }
            let admittedObs = observations.filter { admittedSemantics.contains($0.canonicalSignalID) }.sorted { $0.time < $1.time }
            if let event = admittedObs.first {
                phases.append(.init(id:"intervention", kind:.intervention, startTime:event.time, endTime:event.time, evidence:[event.canonicalSignalID,event.locator]))
            }
            phases.append(.init(id:"recovery", kind:.recovery, startTime:max(first.time,last.time-0.25), endTime:last.time, evidence:["sample boundary"]))
        }
        let fullSemantics = coverage.missing.isEmpty
        let gaps = coverage.missing.map { "Missing reviewed semantic: \($0)" }
        return .init(startTime:sorted.first?.time,endTime:sorted.last?.time,phases:phases.sorted{$0.startTime<$1.startTime},stableWindows:stable,coverage:coverage,lambda:LambdaDeviationEngineRev67.analyze(sorted,semanticsAdmitted:fullSemantics),sparkKnock:SparkKnockChronologyEngineRev67.analyze(sorted,semanticsAdmitted:fullSemantics),thermal:ThermalDerateFingerprintEngineRev67.analyze(sorted,semanticsAdmitted:fullSemantics),firstOut:InterventionSeparationEngineRev67.analyze(observations,admitted:admittedSemantics),evidenceGaps:gaps,boundary:"Pull reconstruction is a derived evidence timeline. Phase labels, temporal order and correlations do not establish Ford control causation, safe calibration values, or durability limits.")
    }
}

struct CalibrationToLogCorrelation: Codable, Hashable {
    let changedFamilies: [String]
    let observedDomains: [String]
    let overlappingDomains: [String]
    let attributionLimited: Bool
    let boundary: String
}

enum CalibrationLogCorrelationEngineRev68 {
    static func correlate(changedFamilies:[String], observedDomains:[String]) -> CalibrationToLogCorrelation {
        let c=Set(changedFamilies.map{$0.lowercased()}), o=Set(observedDomains.map{$0.lowercased()})
        let overlap=Array(c.intersection(o)).sorted()
        return .init(changedFamilies:changedFamilies,observedDomains:observedDomains,overlappingDomains:overlap,attributionLimited:changedFamilies.count != 1 || overlap.isEmpty,boundary:"Domain overlap is a research correlation only. A calibration family changing alongside a logged response does not prove that edit caused the response.")
    }
}

struct PullRepeatabilityAssessment: Codable, Hashable {
    let runCount:Int
    let medianDuration:Double?
    let durationSpread:Double?
    let sufficientForComparison:Bool
    let boundary:String
}

enum PullRepeatabilityEngineRev68 {
    static func assess(durations:[Double]) -> PullRepeatabilityAssessment {
        let x=durations.filter{$0>0}.sorted(); guard !x.isEmpty else { return .init(runCount:0,medianDuration:nil,durationSpread:nil,sufficientForComparison:false,boundary:boundary) }
        let med = x.count % 2 == 1 ? x[x.count/2] : (x[x.count/2-1]+x[x.count/2])/2
        return .init(runCount:x.count,medianDuration:med,durationSpread:(x.last ?? med)-(x.first ?? med),sufficientForComparison:x.count>=2,boundary:boundary)
    }
    static let boundary="Repeatability describes the submitted cohort only. It is not a safety limit, performance guarantee, or proof that calibration caused a difference."
}

struct ExperimentClosurePlan: Codable, Hashable {
    let blockedConclusion:String
    let missingSemantics:[String]
    let recommendedArtifacts:[String]
    let nextExperiment:String
    let boundary:String
}

enum GT500ExperimentClosurePlannerRev68 {
    static func plan(blockedConclusion:String, reconstruction:HighLoadPullReconstruction) -> ExperimentClosurePlan {
        let missing=reconstruction.coverage.missing
        let artifacts = missing.map { "Matching VCM Scanner XML/HPL evidence with reviewed \($0) identity, source, units and transform" }
        let next = missing.isEmpty ? "Repeat the same controlled experiment to establish cohort repeatability and comparability." : "Acquire the highest-information missing semantic without changing the calibration, then repeat the matched experiment."
        return .init(blockedConclusion:blockedConclusion,missingSemantics:missing,recommendedArtifacts:artifacts,nextExperiment:next,boundary:"Closing an evidence gap makes a conclusion eligible for review; it does not make the conclusion true.")
    }
}

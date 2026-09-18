import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

// Rev67: GT500 experiment intelligence. Derived evidence only; no undocumented Ford/HP Tuners stock values.

struct StableWindowSample: Codable, Hashable {
    let time: Double
    let rpm: Double?
    let pedal: Double?
    let throttle: Double?
    let lambdaCommanded: Double?
    let lambdaMeasured: Double?
    let spark: Double?
    let knock: Double?
    let chargeTemperature: Double?
    let coolantTemperature: Double?
    let fuelPressure: Double?
    let boostOrMAP: Double?
    let longitudinalAcceleration: Double?
    let tractionIntervention: Double?
    let transmissionIntervention: Double?
}

struct StableWindow: Identifiable, Codable, Hashable {
    let id: String; let startTime: Double; let endTime: Double; let sampleCount: Int; let reason: String
}

enum StableWindowExtractorRev67 {
    static func extract(_ samples:[StableWindowSample], minimumDuration:Double = 0.5, minimumPedal:Double? = nil, maximumPedalSpread:Double = 5) -> [StableWindow] {
        guard samples.count > 1 else { return [] }
        let s=samples.sorted{$0.time < $1.time}; var out:[StableWindow]=[]; var start=0
        func qualifies(_ slice:ArraySlice<StableWindowSample>) -> Bool {
            let pedals=slice.compactMap(\.pedal); if let minimumPedal, pedals.contains(where:{$0 < minimumPedal}) { return false }
            if let lo=pedals.min(), let hi=pedals.max(), hi-lo > maximumPedalSpread { return false }
            return true
        }
        for i in 1...s.count {
            let boundary = i == s.count || (s[i].time-s[i-1].time > 0.35)
            if boundary {
                let end=i-1; let slice=s[start...end]
                if s[end].time-s[start].time >= minimumDuration && qualifies(slice) {
                    out.append(.init(id:"\(s[start].time)-\(s[end].time)",startTime:s[start].time,endTime:s[end].time,sampleCount:slice.count,reason:"Contiguous stable-input window; semantic and experiment admission remain separate."))
                }
                start=i
            }
        }
        return out
    }
}

struct LambdaDeviationFingerprint: Codable { let sampleCount:Int; let medianAbsoluteDeviation:Double?; let maximumAbsoluteDeviation:Double?; let signedMedianDeviation:Double?; let boundary:String }
enum LambdaDeviationEngineRev67 {
    static func analyze(_ samples:[StableWindowSample], semanticsAdmitted:Bool) -> LambdaDeviationFingerprint {
        guard semanticsAdmitted else { return .init(sampleCount:0,medianAbsoluteDeviation:nil,maximumAbsoluteDeviation:nil,signedMedianDeviation:nil,boundary:"Commanded/measured lambda comparison is blocked until both semantics and units are reviewed for the exact controller/strategy.") }
        let d=samples.compactMap { x -> Double? in guard let c=x.lambdaCommanded, let m=x.lambdaMeasured else{return nil}; return m-c }
        return .init(sampleCount:d.count,medianAbsoluteDeviation:median(d.map{abs($0)}),maximumAbsoluteDeviation:d.map{abs($0)}.max(),signedMedianDeviation:median(d),boundary:"Deviation describes observed commanded-versus-measured behavior. PredatorLab does not supply a universal safe threshold or infer the cause of deviation.")
    }
}

struct SparkKnockChronology: Codable { let firstKnockTime:Double?; let firstSparkChangeTime:Double?; let temporalOrder:String; let boundary:String }
enum SparkKnockChronologyEngineRev67 {
    static func analyze(_ samples:[StableWindowSample], semanticsAdmitted:Bool) -> SparkKnockChronology {
        guard semanticsAdmitted else{return .init(firstKnockTime:nil,firstSparkChangeTime:nil,temporalOrder:"blocked",boundary:"Spark/knock chronology requires reviewed exact semantics.")}
        guard let baseSpark=samples.first?.spark else{return .init(firstKnockTime:nil,firstSparkChangeTime:nil,temporalOrder:"insufficient",boundary:"No baseline spark observation available.")}
        let knock=samples.first(where:{abs($0.knock ?? 0) > 0})?.time
        let spark=samples.first(where:{ guard let v=$0.spark else{return false}; return abs(v-baseSpark) > 0.01 })?.time
        let order:String
        if let knock, let spark { order = knock < spark ? "knock observed before spark change" : spark < knock ? "spark change observed before knock" : "same sampled time" } else { order="one or both events not observed" }
        return .init(firstKnockTime:knock,firstSparkChangeTime:spark,temporalOrder:order,boundary:"Sampled temporal order is evidence, not proof of Ford knock-control causation. Sampling interval can hide the true first event.")
    }
}

struct ThermalDerateFingerprint: Codable { let startChargeTemp:Double?; let peakChargeTemp:Double?; let startCoolantTemp:Double?; let peakCoolantTemp:Double?; let firstThrottleReductionTime:Double?; let firstSparkReductionTime:Double?; let boundary:String }
enum ThermalDerateFingerprintEngineRev67 {
    static func analyze(_ samples:[StableWindowSample], semanticsAdmitted:Bool) -> ThermalDerateFingerprint {
        guard semanticsAdmitted else{return .init(startChargeTemp:nil,peakChargeTemp:nil,startCoolantTemp:nil,peakCoolantTemp:nil,firstThrottleReductionTime:nil,firstSparkReductionTime:nil,boundary:"Thermal fingerprint blocked until temperature, throttle and spark semantics are admitted.")}
        let baseThrottle=samples.first?.throttle; let baseSpark=samples.first?.spark
        return .init(startChargeTemp:samples.first?.chargeTemperature,peakChargeTemp:samples.compactMap(\.chargeTemperature).max(),startCoolantTemp:samples.first?.coolantTemperature,peakCoolantTemp:samples.compactMap(\.coolantTemperature).max(),firstThrottleReductionTime:samples.first(where:{guard let b=baseThrottle, let v=$0.throttle else{return false}; return v < b-0.01})?.time,firstSparkReductionTime:samples.first(where:{guard let b=baseSpark, let v=$0.spark else{return false}; return v < b-0.01})?.time,boundary:"This fingerprint describes co-occurring thermal and control observations. It does not establish a Ford derate threshold or causal strategy edge.")
    }
}

struct InterventionSeparationResult: Codable { let tractionEvidenceFirst:Bool?; let transmissionEvidenceFirst:Bool?; let powertrainEvidenceFirst:Bool?; let firstObserved:String?; let boundary:String }
enum InterventionSeparationEngineRev67 {
    static func analyze(_ observations:[FirstOutObservation], admitted:Set<String>) -> InterventionSeparationResult {
        let o=observations.filter{admitted.contains($0.canonicalSignalID)}.sorted{$0.time<$1.time}; guard let first=o.first else{return .init(tractionEvidenceFirst:nil,transmissionEvidenceFirst:nil,powertrainEvidenceFirst:nil,firstObserved:nil,boundary:"No admitted intervention evidence.")}
        let id=first.canonicalSignalID.lowercased(); let traction=id.contains("traction") || id.contains("stability"); let transmission=id.contains("transmission") || id.contains("dct") || id.contains("tcm")
        return .init(tractionEvidenceFirst:traction,transmissionEvidenceFirst:transmission,powertrainEvidenceFirst:!traction && !transmission,firstObserved:first.canonicalSignalID,boundary:"Classification identifies the first admitted evidence family, not the root cause. Controller coordination can precede the first observable signal.")
    }
}

struct HistogramBin: Codable, Hashable { let lower:Double; let upper:Double; let count:Int }
struct DistributionComparison: Codable { let baselineMedian:Double?; let candidateMedian:Double?; let deltaMedian:Double?; let baselineBins:[HistogramBin]; let candidateBins:[HistogramBin]; let boundary:String }
enum DistributionAnalysisEngineRev67 {
    static func compare(baseline:[Double], candidate:[Double], bins:Int=10) -> DistributionComparison {
        let all=baseline+candidate; guard let lo=all.min(), let hi=all.max(), hi>lo, bins>0 else{return .init(baselineMedian:median(baseline),candidateMedian:median(candidate),deltaMedian:delta(median(baseline),median(candidate)),baselineBins:[],candidateBins:[],boundary:boundary)}
        let w=(hi-lo)/Double(bins); func hist(_ x:[Double])->[HistogramBin] { (0..<bins).map { i in let l=lo+Double(i)*w, u=i==bins-1 ? hi : l+w; return .init(lower:l,upper:u,count:x.filter{i==bins-1 ? ($0>=l && $0<=u) : ($0>=l && $0<u)}.count) } }
        return .init(baselineMedian:median(baseline),candidateMedian:median(candidate),deltaMedian:delta(median(baseline),median(candidate)),baselineBins:hist(baseline),candidateBins:hist(candidate),boundary:boundary)
    }
    static let boundary="Distribution differences describe the tested samples only. They require experiment comparability and do not prove calibration causation, safety, or durability."
}

struct AdaptiveExperimentCandidate: Identifiable, Codable, Hashable { let id:String; let measurement:String; let resolvesHypothesisIDs:[String]; let cost:Int; let risk:Int; let exactSemanticRequired:String? }
struct AdaptiveExperimentRecommendation: Codable { let candidate:AdaptiveExperimentCandidate?; let score:Double; let unresolvedHypotheses:Int; let boundary:String }
enum AdaptiveFordExperimentPlannerRev67 {
    static func recommend(hypothesisIDs:Set<String>, candidates:[AdaptiveExperimentCandidate], admittedSemantics:Set<String>) -> AdaptiveExperimentRecommendation {
        let ranked=candidates.map { c -> (AdaptiveExperimentCandidate,Double) in
            let unresolved=Set(c.resolvesHypothesisIDs).intersection(hypothesisIDs).count
            let semanticPenalty=(c.exactSemanticRequired != nil && !admittedSemantics.contains(c.exactSemanticRequired!)) ? 0.35 : 1.0
            let score=Double(unresolved)*semanticPenalty/Double(max(1,c.cost+c.risk))
            return(c,score)
        }.sorted{$0.1>$1.1}
        return .init(candidate:ranked.first?.0,score:ranked.first?.1 ?? 0,unresolvedHypotheses:hypothesisIDs.count,boundary:"Recommendation ranks expected hypothesis reduction against effort/risk and semantic readiness. It is not permission to exceed safe operating limits or a probability of diagnosis.")
    }
}

private func median(_ x:[Double])->Double? { let a=x.sorted(); guard !a.isEmpty else{return nil}; return a.count%2==1 ? a[a.count/2] : (a[a.count/2-1]+a[a.count/2])/2 }
private func delta(_ a:Double?,_ b:Double?)->Double? { guard let a, let b else{return nil}; return b-a }

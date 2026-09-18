import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

// Rev70: bridge real parsed VCM Scanner CSV evidence into the Tune reasoning stack.
// Raw HPT/HPL binaries remain opaque; only parsed/exported evidence and reviewed semantics are admitted.

struct VCMParsedLogAdmission: Codable {
    let samples: [StableWindowSample]
    let admittedSemanticIDs: [String]
    let unresolvedSemanticIDs: [String]
    let rawChannelBindings: [String:String]
    let boundary: String
}

enum VCMParsedLogAdapterRev70 {
    static func adapt(log: ParsedLogData, reviews: [VCMScannerSemanticReview]) -> VCMParsedLogAdmission {
        let admitted = reviews.filter { $0.admittedForAnalysis }
        var raw:[String:String] = [:]
        var semanticToRaw:[String:String] = [:]
        for review in admitted {
            guard let semantic = review.binding.canonicalSignalID, !semantic.isEmpty else { continue }
            let candidates = [review.binding.displayName, review.binding.parameterID].compactMap{$0}
            if let name = candidates.first(where: { log.channels.contains($0) }) {
                semanticToRaw[semantic] = name; raw[semantic] = name
            } else if let canonical = canonical(for: semantic), let name = ChannelResolver.resolve(canonical, in: log.channels) {
                semanticToRaw[semantic] = name; raw[semantic] = name
            }
        }
        func value(_ semantic:String, _ row:Int) -> Double? {
            guard let name=semanticToRaw[semantic] else { return nil }
            return log.numericValue(channel:name,row:row)
        }
        let samples = log.timestamps.indices.compactMap { i -> StableWindowSample? in
            guard log.samples.indices.contains(i) else { return nil }
            return .init(time:log.timestamps[i],
                         rpm:value("engine.rpm",i), pedal:value("driver.pedal",i), throttle:value("throttle",i),
                         lambdaCommanded:value("lambda.commanded",i), lambdaMeasured:value("lambda.measured",i),
                         spark:value("spark",i), knock:value("knock",i), chargeTemperature:value("charge.temperature",i),
                         coolantTemperature:value("coolant.temperature",i), fuelPressure:value("fuel.pressure",i),
                         boostOrMAP:value("boost.map",i), longitudinalAcceleration:value("acceleration.longitudinal",i),
                         tractionIntervention:value("traction.intervention",i), transmissionIntervention:value("transmission.intervention",i))
        }
        let admittedIDs=Array(semanticToRaw.keys).sorted()
        let reviewedIDs=Set(admitted.compactMap{$0.binding.canonicalSignalID})
        return .init(samples:samples,admittedSemanticIDs:admittedIDs,unresolvedSemanticIDs:Array(reviewedIDs.subtracting(Set(admittedIDs))).sorted(),rawChannelBindings:raw,boundary:"Only reviewed Scanner semantics that can be bound to an actual parsed channel are admitted. Display-name fallback is never used across controller/strategy boundaries; unresolved bindings remain missing.")
    }

    private static func canonical(for semantic:String) -> CanonicalChannel? {
        switch semantic {
        case "engine.rpm": return .engineRPM
        case "throttle": return .throttleActual
        case "lambda.commanded": return .lambdaCommanded
        case "lambda.measured": return .lambdaMeasured
        case "knock": return .knockRetard
        case "charge.temperature": return .iat2
        case "coolant.temperature": return .coolantTemperature
        case "fuel.pressure": return .fuelPressureActual
        case "boost.map": return .boostPressure
        default: return nil
        }
    }
}

struct HighLoadPullSegmentation: Codable {
    let candidateWindows:[StableWindow]
    let selectedWindow:StableWindow?
    let reasons:[String]
    let boundary:String
}

enum HighLoadPullSegmenterRev70 {
    static func segment(_ samples:[StableWindowSample], minimumPedal:Double = 70, minimumDuration:Double = 1.0) -> HighLoadPullSegmentation {
        let windows=StableWindowExtractorRev67.extract(samples,minimumDuration:minimumDuration,minimumPedal:minimumPedal,maximumPedalSpread:12)
        let selected=windows.max { ($0.endTime-$0.startTime) < ($1.endTime-$1.startTime) }
        return .init(candidateWindows:windows,selectedWindow:selected,reasons:selected == nil ? ["No contiguous candidate satisfied the authored pedal/duration experiment contract."] : ["Selected longest contiguous candidate satisfying the authored experiment contract."],boundary:"Segmentation uses user/app-authored experiment criteria, not a Ford WOT definition or safety threshold. The source log remains unchanged.")
    }
}

struct TuneEvidencePipelineResult: Codable {
    let admission:VCMParsedLogAdmission
    let segmentation:HighLoadPullSegmentation
    let reconstruction:HighLoadPullReconstruction?
    let closure:ExperimentClosurePlan?
    let nextAction:String
    let boundary:String
}

enum TuneEvidencePipelineRev70 {
    static func run(log:ParsedLogData, reviews:[VCMScannerSemanticReview], observations:[FirstOutObservation]=[], blockedConclusion:String="Explain the observed high-load response") -> TuneEvidencePipelineResult {
        let admission=VCMParsedLogAdapterRev70.adapt(log:log,reviews:reviews)
        let segmentation=HighLoadPullSegmenterRev70.segment(admission.samples)
        guard let window=segmentation.selectedWindow else {
            return .init(admission:admission,segmentation:segmentation,reconstruction:nil,closure:nil,nextAction:"Acquire or select a controlled high-load interval that satisfies the declared experiment contract.",boundary:boundary)
        }
        let slice=admission.samples.filter{$0.time >= window.startTime && $0.time <= window.endTime}
        let reconstruction=GT500HighLoadPullReconstructorRev68.reconstruct(samples:slice,admittedSemantics:Set(admission.admittedSemanticIDs),observations:observations)
        let closure=GT500ExperimentClosurePlannerRev68.plan(blockedConclusion:blockedConclusion,reconstruction:reconstruction)
        let next = closure.missingSemantics.isEmpty ? "Repeat a matched run and evaluate comparability/validation envelope." : closure.nextExperiment
        return .init(admission:admission,segmentation:segmentation,reconstruction:reconstruction,closure:closure,nextAction:next,boundary:boundary)
    }
    static let boundary="Rev70 connects parsed exported log evidence to reviewed Scanner semantics and derived reconstruction. It does not decode proprietary HPT/HPL formats, infer undocumented Ford thresholds, or turn correlation into causation."
}

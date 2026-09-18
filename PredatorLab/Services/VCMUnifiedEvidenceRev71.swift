import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

// Rev71: assisted VCM Scanner XML review, matched baseline/candidate comparison,
// heat-soak cohorts, TR_C75 shift segmentation, and unified evidence explanation.
// No proprietary HPT/HPL binary decoding is performed here.

struct VCMScannerXMLCandidate: Identifiable, Codable, Hashable {
    let id: String
    let parameterID: String?
    let parameterSource: String?
    let pollingInterval: String?
    let displayName: String?
    let transform: String?
    let rawLocator: String
    let warnings: [String]
}

struct VCMScannerXMLExtraction: Codable {
    let candidates: [VCMScannerXMLCandidate]
    let fallbackOrOverrideHints: [String]
    let boundary: String
}

enum VCMScannerXMLAssistedExtractorRev71 {
    /// Conservative text-level extraction from a user-supplied Scanner XML export.
    /// Attribute names vary by VCM Suite version, so candidates require human semantic review.
    static func extract(_ xml: String) -> VCMScannerXMLExtraction {
        let lines = xml.components(separatedBy: .newlines)
        var candidates: [VCMScannerXMLCandidate] = []
        var hints: [String] = []
        for (index, line) in lines.enumerated() {
            let lower = line.lowercased()
            if lower.contains("fallback") || lower.contains("override") { hints.append("line:\(index + 1): definition fallback/override metadata present") }
            guard lower.contains("parameter") || lower.contains("channel") else { continue }
            let attrs = attributes(in: line)
            func first(_ keys: [String]) -> String? {
                for key in keys { if let v = attrs.first(where: { $0.key.lowercased() == key })?.value, !v.isEmpty { return v } }
                return nil
            }
            let pid = first(["parameterid","parameter_id","id","pid"])
            let source = first(["parametersource","source","src"])
            let interval = first(["pollinginterval","interval","pollinterval"])
            let name = first(["displayname","name","label"])
            let transform = first(["transform","transformname","conversion"])
            guard pid != nil || source != nil || name != nil else { continue }
            var warnings: [String] = []
            if pid == nil { warnings.append("Parameter ID not found in this candidate") }
            if source == nil { warnings.append("Parameter source not found in this candidate") }
            candidates.append(.init(id:"xml-line-\(index + 1)",parameterID:pid,parameterSource:source,pollingInterval:interval,displayName:name,transform:transform,rawLocator:"line:\(index + 1)",warnings:warnings))
        }
        return .init(candidates:candidates,fallbackOrOverrideHints:Array(Set(hints)).sorted(),boundary:"Extraction identifies candidate Scanner metadata only. HP Tuners documents that saved channel configs include Parameter ID, source, polling interval and transforms, but a candidate is not analysis-grade until controller/strategy/units/physical semantics are reviewed.")
    }

    private static func attributes(in line: String) -> [String:String] {
        let pattern = #"([A-Za-z_][A-Za-z0-9_.:-]*)\s*=\s*[\"']([^\"']*)[\"']"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [:] }
        let ns = line as NSString
        var out: [String:String] = [:]
        for m in regex.matches(in: line, range: NSRange(location:0,length:ns.length)) where m.numberOfRanges >= 3 {
            out[ns.substring(with:m.range(at:1))] = ns.substring(with:m.range(at:2))
        }
        return out
    }
}

struct MatchedPullComparisonRev71: Codable {
    let baselineDuration: Double?
    let candidateDuration: Double?
    let durationDelta: Double?
    let sharedSemanticCoverage: [String]
    let missingFromEither: [String]
    let comparable: Bool
    let blockers: [String]
    let boundary: String
}

enum MatchedPullComparisonEngineRev71 {
    static func compare(baseline: TuneEvidencePipelineResult, candidate: TuneEvidencePipelineResult, experimentComparable: Bool, sameBuild: Bool, sameFuel: Bool) -> MatchedPullComparisonRev71 {
        let b = Set(baseline.admission.admittedSemanticIDs), c = Set(candidate.admission.admittedSemanticIDs)
        let shared = Array(b.intersection(c)).sorted()
        let required = Set(GT500HighLoadPullReconstructorRev68.coreSignals)
        let missing = Array(required.subtracting(b.intersection(c))).sorted()
        var blockers: [String] = []
        if !sameBuild { blockers.append("Build Revision mismatch") }
        if !sameFuel { blockers.append("Fuel configuration mismatch") }
        if !experimentComparable { blockers.append("Experiment comparability gate not satisfied") }
        if baseline.reconstruction == nil || candidate.reconstruction == nil { blockers.append("Both runs require admitted pull reconstruction") }
        if !missing.isEmpty { blockers.append("Shared semantic coverage incomplete") }
        let bd = duration(baseline), cd = duration(candidate)
        return .init(baselineDuration:bd,candidateDuration:cd,durationDelta:(bd != nil && cd != nil) ? cd! - bd! : nil,sharedSemanticCoverage:shared,missingFromEither:missing,comparable:blockers.isEmpty,blockers:blockers,boundary:"Matched comparison is limited to the declared experiment envelope. A duration or logged-response difference does not by itself prove the calibration caused the change, nor establish safety or durability.")
    }
    private static func duration(_ r:TuneEvidencePipelineResult)->Double? { guard let a=r.reconstruction?.startTime, let b=r.reconstruction?.endTime else{return nil}; return b-a }
}

struct HeatSoakCohortRev71: Codable {
    let runCount: Int
    let startChargeTemperatures: [Double]
    let peakChargeTemperatures: [Double]
    let durationTrend: [Double]
    let repeatability: PullRepeatabilityAssessment
    let boundary: String
}

enum HeatSoakCohortEngineRev71 {
    static func build(_ runs:[TuneEvidencePipelineResult]) -> HeatSoakCohortRev71 {
        let recon = runs.compactMap(\.reconstruction)
        let starts = recon.compactMap(\.thermal.startChargeTemp)
        let peaks = recon.compactMap(\.thermal.peakChargeTemp)
        let durations = recon.compactMap { r -> Double? in guard let a=r.startTime, let b=r.endTime else{return nil}; return b-a }
        return .init(runCount:recon.count,startChargeTemperatures:starts,peakChargeTemperatures:peaks,durationTrend:durations,repeatability:PullRepeatabilityEngineRev68.assess(durations:durations),boundary:"Heat-soak cohorting describes repeated-run thermal and timing behavior. It does not identify a Ford protection threshold or prove calibration causation.")
    }
}

struct TRC75ShiftEvidenceSampleRev71: Codable { let time:Double; let gear:Double; let rpm:Double; let acceleration:Double? }
struct TRC75ShiftWindowRev71: Identifiable, Codable { let id:String; let fromGear:Int; let toGear:Int; let startTime:Double; let endTime:Double; let fingerprint:TRC75ShiftFingerprint }

enum TRC75ShiftSegmenterRev71 {
    static func extract(log:ParsedLogData, admission:VCMParsedLogAdmission) -> [TRC75ShiftWindowRev71] {
        guard let gearName=admission.rawChannelBindings["transmission.gear"], let rpmName=admission.rawChannelBindings["engine.rpm"] else{return []}
        let accelName=admission.rawChannelBindings["acceleration.longitudinal"]
        var rows:[TRC75ShiftEvidenceSampleRev71]=[]
        for i in log.timestamps.indices {
            guard let gear=log.numericValue(channel:gearName,row:i), let rpm=log.numericValue(channel:rpmName,row:i) else{continue}
            rows.append(.init(time:log.timestamps[i],gear:gear,rpm:rpm,acceleration:accelName.flatMap{log.numericValue(channel:$0,row:i)}))
        }
        guard rows.count > 2 else{return []}
        var out:[TRC75ShiftWindowRev71]=[]
        for i in 1..<rows.count {
            let from=Int(rows[i-1].gear.rounded()), to=Int(rows[i].gear.rounded())
            guard from != to, from > 0, to > 0 else{continue}
            let lo=max(0,i-2), hi=min(rows.count-1,i+2)
            let shiftSamples=rows[lo...hi].map{TRC75ShiftSample(time:$0.time,engineRPM:$0.rpm,longitudinalAcceleration:$0.acceleration)}
            if let fp=TRC75ShiftAnalysisEngine.fingerprint(samples:shiftSamples) {
                out.append(.init(id:"\(from)-\(to)-\(rows[i].time)",fromGear:from,toGear:to,startTime:rows[lo].time,endTime:rows[hi].time,fingerprint:fp))
            }
        }
        return out
    }
}

struct UnifiedTuneEvidenceSummaryRev71: Codable {
    let supportedObservations:[String]
    let uncertainties:[String]
    let nextActions:[String]
    let boundary:String
}

enum UnifiedTuneEvidenceExplainerRev71 {
    static func summarize(pipeline:TuneEvidencePipelineResult?, comparison:MatchedPullComparisonRev71?=nil, heatSoak:HeatSoakCohortRev71?=nil, shifts:[TRC75ShiftWindowRev71]=[]) -> UnifiedTuneEvidenceSummaryRev71 {
        var supported:[String]=[], uncertain:[String]=[], next:[String]=[]
        if let p=pipeline {
            supported.append("\(p.admission.admittedSemanticIDs.count) reviewed Scanner semantics bound to actual parsed channels")
            if let r=p.reconstruction { supported.append("High-load reconstruction spans \(r.phases.count) derived phases") }
            uncertain.append(contentsOf:p.admission.unresolvedSemanticIDs.map{"Unresolved channel binding: \($0)"})
            if let c=p.closure { uncertain.append(contentsOf:c.missingSemantics.map{"Missing reviewed semantic: \($0)"}) }
            next.append(p.nextAction)
        } else { uncertain.append("No current evidence pipeline result") }
        if let comparison { if comparison.comparable { supported.append("Baseline/candidate pair passed declared structural comparability gates") } else { uncertain.append(contentsOf:comparison.blockers) } }
        if let heatSoak, heatSoak.runCount >= 2 { supported.append("Heat-soak cohort contains \(heatSoak.runCount) reconstructed runs") }
        if !shifts.isEmpty { supported.append("\(shifts.count) gear-transition windows reconstructed from reviewed gear/RPM evidence") }
        if next.isEmpty { next.append("Acquire a controlled, provenance-complete VCM evidence bundle before strengthening conclusions.") }
        return .init(supportedObservations:Array(Set(supported)).sorted(),uncertainties:Array(Set(uncertain)).sorted(),nextActions:Array(Set(next)).sorted(),boundary:"This summary separates supported observations from uncertainty and next actions. It never converts temporal order, parameter differences, or performance improvement into automatic causal proof or tune approval.")
    }
}

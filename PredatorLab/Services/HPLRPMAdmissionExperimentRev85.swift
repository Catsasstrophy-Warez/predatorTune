import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct HPLRPMAdmissionReportRev85: Codable, Sendable {
    enum Decision: String, Codable, Sendable { case insufficientEvidence, candidateSequenceFound, admitted }
    let decision: Decision
    let referenceSampleCount: Int
    let matchedReferenceValues: Int
    let monotonicOffsetMatches: Int
    let requirementsRemaining: [String]
}

enum HPLRPMAdmissionExperimentRev85 {
    /// Uses admitted CSV RPM only as a differential reference. Direct byte hits never self-certify HPL semantics.
    static func compare(hpl: Data, referenceRPM: [Double]) -> HPLRPMAdmissionReportRev85 {
        let refs = Array(referenceRPM.prefix(64))
        let result = HPLNativeWaveformDecoderRev85.probe(data:hpl, referenceValues:refs)
        let grouped = Dictionary(grouping: result.directValueHits, by: { Int($0.sample.rounded()) })
        let matched = Set(refs.map { Int($0.rounded()) }).filter { grouped[$0] != nil }.count
        var last = -1; var monotonic = 0
        for ref in refs.map({Int($0.rounded())}) {
            if let offset = grouped[ref]?.map(\.offset).filter({$0 > last}).min() { monotonic += 1; last = offset }
        }
        let candidate = refs.count >= 4 && monotonic >= max(3, refs.count / 3)
        return .init(decision:candidate ? .candidateSequenceFound : .insufficientEvidence, referenceSampleCount:refs.count, matchedReferenceValues:matched, monotonicOffsetMatches:monotonic, requirementsRemaining:["Artifact-specific frame/record boundary proof","Timestamp or clock agreement with matched evidence","XML/controller identity agreement","RPM unit/scaling agreement","Repeatability on an independent artifact"])
    }
}

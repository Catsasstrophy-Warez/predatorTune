// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import Foundation

struct GT500ProfileChannelAudit:Identifiable,Equatable,Sendable {
    let id:String
    let parameterID:Int
    let name:String
    let unit:String?
    let requestedIntervalSeconds:Double?
    let evidenceState:GT500EvidenceMatchState
    let conceptualID:String?
    let recommendedCadence:String?
    let recommendation:String
}

struct GT500PresetAudit:Identifiable,Equatable,Sendable {
    let id:String
    let presetName:String
    let verifiedOrAliased:Int
    let candidate:Int
    let missing:[String]
    let coverage:Double
}

struct GT500LoggingOptimizationReport:Equatable,Sendable {
    let channels:[GT500ProfileChannelAudit]
    let presets:[GT500PresetAudit]
    let fastestRequestedInterval:Double?
    let slowestRequestedInterval:Double?
    let boundary:String
}

enum GT500LoggingProfileOptimizerRev109 {
    static func report()->GT500LoggingOptimizationReport {
        let evidence=GT500EvidenceConvergenceRev108.matches()
        let byPID=Dictionary(uniqueKeysWithValues:evidence.map{($0.parameterID,$0)})
        let catalog=Dictionary(uniqueKeysWithValues:ValuableLoggingChannelCatalog.gt500Testing.map{($0.id,$0)})
        let channels=HPTunerLoggingProfile.channels.compactMap { ch -> GT500ProfileChannelAudit? in
            guard let name=ch.name else{return nil}
            let match=byPID[ch.parameterID]
            let cadence=match?.conceptualID.flatMap{catalog[$0]?.cadence}
            let seconds=intervalSeconds(ch.interval)
            let recommendation:String
            if let cadence,let seconds {
                switch cadence {
                case "slow" where seconds < 1:
                    recommendation="Slow-changing context appears configured relatively fast; consider whether bandwidth is better spent on discriminating fast signals."
                case "fast" where seconds >= 1:
                    recommendation="High-value transient concept appears configured relatively slowly; measure observed acquisition quality before relying on event timing."
                default:
                    recommendation="No cadence mismatch flagged by the conceptual catalog."
                }
            } else {
                recommendation="No evidence-backed cadence recommendation; preserve as unknown/context until classified."
            }
            return .init(id:"pid-\(ch.parameterID)",parameterID:ch.parameterID,name:name,unit:ch.unit,
                         requestedIntervalSeconds:seconds,evidenceState:match?.state ?? .candidate,
                         conceptualID:match?.conceptualID,recommendedCadence:cadence,recommendation:recommendation)
        }
        let presets=GT500LoggingPresets.all.map { preset -> GT500PresetAudit in
            let d=GT500EvidenceConvergenceRev108.loggingDesign(for:preset)
            let strong=d.resolved.filter{$0.status == .verifiedAlias || $0.status == .exactMatch}.count
            let candidate=d.resolved.filter{$0.status == .candidateMatch}.count
            let missing=d.resolved.filter{$0.status == .missing}.map(\.conceptualID)
            return .init(id:preset.id,presetName:preset.name,verifiedOrAliased:strong,candidate:candidate,missing:missing,
                         coverage:preset.channelIDs.isEmpty ? 0:Double(preset.channelIDs.count-missing.count)/Double(preset.channelIDs.count))
        }
        let intervals=channels.compactMap(\.requestedIntervalSeconds)
        return .init(channels:channels,presets:presets,fastestRequestedInterval:intervals.min(),slowestRequestedInterval:intervals.max(),
                     boundary:"Intervals are requested/configured artifact metadata. They are not measured effective sample rates. Optimization recommendations are test-design guidance, not tuning or safety limits.")
    }

    static func intervalSeconds(_ raw:String?)->Double? {
        guard let raw else{return nil}
        let parts=raw.split(separator:":").compactMap{Double($0)}
        guard parts.count==3 else{return nil}
        return parts[0]*3600+parts[1]*60+parts[2]
    }
}

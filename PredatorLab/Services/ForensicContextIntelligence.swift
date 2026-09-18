// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import Foundation

struct ForensicContextValue: Identifiable, Equatable, Sendable {
    let id:String
    let label:String
    let value:Double
    let unit:String?
    let deltaFromPrevious:Double?
}

struct ForensicNearbyEvent: Identifiable, Equatable, Sendable {
    let id:UUID
    let time:TimeInterval
    let description:String
    let severity:String
    let distanceSeconds:Double
}

struct ForensicNextMeasurement: Identifiable, Equatable, Sendable {
    let id:String
    let title:String
    let rationale:String
    let evidenceClass:TelemetryEvidenceClass
}

struct ForensicContextSnapshot: Equatable, Sendable {
    let time:TimeInterval?
    let values:[ForensicContextValue]
    let nearbyEvents:[ForensicNearbyEvent]
    let nextMeasurements:[ForensicNextMeasurement]
    let provenance:[String]
    let boundary:String
}

enum ForensicContextIntelligence {
    static func snapshot(session:ForensicSessionDatasetRev85?, cursor:ForensicCursorRev85,
                         eventWindow:TimeInterval = 1.0, valueLimit:Int = 8) -> ForensicContextSnapshot {
        guard let session else {
            return .init(time:cursor.time,values:[],nearbyEvents:[],nextMeasurements:[],
                         provenance:[],boundary:"No active admitted session. Context intelligence does not synthesize telemetry.")
        }
        let t=cursor.time ?? session.series.compactMap{$0.samples.last?.time}.max()
        guard let t else {
            return .init(time:nil,values:[],nearbyEvents:[],nextMeasurements:[],
                         provenance:[session.log.filename],boundary:"No timestamp is available in the admitted session.")
        }
        let ordered = session.series.sorted {
            ($0.id == cursor.channelID ? 0:1) < ($1.id == cursor.channelID ? 0:1)
        }
        let values=ordered.prefix(valueLimit).compactMap { series -> ForensicContextValue? in
            guard let index=series.samples.indices.min(by:{abs(series.samples[$0].time-t)<abs(series.samples[$1].time-t)}) else{return nil}
            let sample=series.samples[index]
            let previous=index>series.samples.startIndex ? series.samples[series.samples.index(before:index)] : nil
            return .init(id:series.id,label:series.descriptor.displayName,value:sample.value,unit:series.descriptor.unit,
                         deltaFromPrevious:previous.map{sample.value-$0.value})
        }
        let events=session.events.filter{abs($0.timestamp-t)<=eventWindow}.sorted{abs($0.timestamp-t)<abs($1.timestamp-t)}.map {
            ForensicNearbyEvent(id:$0.id,time:$0.timestamp,description:$0.description,severity:$0.severity,distanceSeconds:abs($0.timestamp-t))
        }
        var next:[ForensicNextMeasurement]=[]
        if cursor.channelID == nil {
            next.append(.init(id:"select-channel",title:"Select a channel",rationale:"A selected channel lets the inspector prioritize its observed value and local change.",evidenceClass:.observed))
        }
        if events.isEmpty {
            next.append(.init(id:"inspect-window",title:"Inspect the surrounding window",rationale:"No authored event lies within ±\(String(format:"%.1f",eventWindow)) s. Review neighboring observed channels before forming a causal hypothesis.",evidenceClass:.derived))
        } else {
            next.append(.init(id:"compare-event",title:"Compare channels around the nearest event",rationale:"Check which observed changes precede, coincide with, and follow the event. Temporal order alone does not prove causation.",evidenceClass:.derived))
        }
        return .init(time:t,values:values,nearbyEvents:events,nextMeasurements:next,
                     provenance:[session.log.filename,session.log.sourceSHA256 ?? "SHA-256 unavailable"],
                     boundary:"Context is computed from admitted session samples and authored events. Suggested measurements are investigative aids, not diagnoses or tuning instructions.")
    }
}

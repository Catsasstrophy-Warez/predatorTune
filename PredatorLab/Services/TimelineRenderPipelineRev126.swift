import Foundation

struct TimelineRenderBandRev126:Identifiable,Equatable,Sendable {let id:String;let envelopes:[TelemetryEnvelopeRev116];let minimum:Double;let maximum:Double}
struct TimelineRenderFrameRev126:Equatable,Sendable {let start:Double;let end:Double;let cursor:Double;let bands:[TimelineRenderBandRev126];let sourcePointCount:Int;let renderedEnvelopeCount:Int}
enum TimelineRenderPipelineRev126 {
 static func frame(series:[TimelineSeriesRev117],start:Double,end:Double,cursor:Double,pixelWidth:Int)->TimelineRenderFrameRev126 {
  let w=ForensicTimelineEngineRev117.window(series:series,start:start,end:end,cursor:cursor,pixelWidth:max(1,pixelWidth))
  var source=0;var rendered=0
  let bands=series.compactMap{s->TimelineRenderBandRev126? in
   let times=s.points.map(\.time),lo=TelemetryHotPathRev116.lowerBound(times:times,target:start),hi=TelemetryHotPathRev116.lowerBound(times:times,target:end);source += max(0,hi-lo)
   guard let e=w.envelopes[s.id],!e.isEmpty else{return nil};rendered += e.count
   return .init(id:s.id,envelopes:e,minimum:e.map(\.minimum).min()!,maximum:e.map(\.maximum).max()!)
  }
  return .init(start:w.start,end:w.end,cursor:w.cursor,bands:bands,sourcePointCount:source,renderedEnvelopeCount:rendered)
 }
}

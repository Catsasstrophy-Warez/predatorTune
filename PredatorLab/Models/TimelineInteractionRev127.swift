import Foundation
struct TimelineViewportRev127:Equatable,Sendable {
 var start:Double;var end:Double;var cursor:Double
 var duration:Double{max(0,end-start)}
 func normalized(totalStart:Double,totalEnd:Double)->Self{
  let span=max(0.001,min(duration,totalEnd-totalStart));let s=min(max(start,totalStart),max(totalStart,totalEnd-span));let e=s+span
  return .init(start:s,end:e,cursor:min(max(cursor,s),e))
 }
}
enum TimelineInteractionRev127 {
 static func zoom(_ v:TimelineViewportRev127,factor:Double,anchor:Double,totalStart:Double,totalEnd:Double)->TimelineViewportRev127{
  let f=max(0.05,factor),newSpan=max(0.05,min((v.end-v.start)*f,totalEnd-totalStart));let ratio=(anchor-v.start)/max(v.end-v.start,0.001)
  return TimelineViewportRev127(start:anchor-ratio*newSpan,end:anchor+(1-ratio)*newSpan,cursor:v.cursor).normalized(totalStart:totalStart,totalEnd:totalEnd)
 }
 static func pan(_ v:TimelineViewportRev127,delta:Double,totalStart:Double,totalEnd:Double)->TimelineViewportRev127{
  .init(start:v.start+delta,end:v.end+delta,cursor:v.cursor+delta).normalized(totalStart:totalStart,totalEnd:totalEnd)
 }
 static func snapCursor(_ time:Double,episodes:[GT500EpisodeRev122],tolerance:Double)->Double{
  let candidates=episodes.flatMap{[$0.start,$0.peakTime,$0.end]};guard let best=candidates.min(by:{abs($0-time)<abs($1-time)}),abs(best-time)<=tolerance else{return time};return best
 }
}

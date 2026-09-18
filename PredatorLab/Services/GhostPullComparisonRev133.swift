import Foundation

struct GhostSignalSummaryRev133:Identifiable,Equatable,Sendable {let id:String;let countA:Int;let countB:Int;let peakA:Double;let peakB:Double;let peakDelta:Double;let meanA:Double;let meanB:Double;let meanDelta:Double;let integralA:Double;let integralB:Double;let integralDelta:Double;let authority:String}
struct GhostPullComparisonRev133:Equatable,Sendable {let method:GhostAlignmentMethodRev132;let quality:GhostAlignmentQuality;let summaries:[GhostSignalSummaryRev133];let boundary:String}
enum GhostPullComparisonEngineRev133 {
 static func compare(a:[TimelineSeriesRev117],windowA:ClosedRange<Double>,b:[TimelineSeriesRev117],windowB:ClosedRange<Double>,method:GhostAlignmentMethodRev132)->GhostPullComparisonRev133 {
  let bm=Dictionary(uniqueKeysWithValues:b.map{($0.id,$0)});var summaries:[GhostSignalSummaryRev133]=[]
  for x in a {guard let y=bm[x.id] else{continue};let ap=x.points.filter{windowA.contains($0.time)},bp=y.points.filter{windowB.contains($0.time)};guard !ap.isEmpty,!bp.isEmpty else{continue};let av=ap.map(\.value),bv=bp.map(\.value);let ma=av.reduce(0,+)/Double(av.count),mb=bv.reduce(0,+)/Double(bv.count);let pa=av.max()!,pb=bv.max()!;let ia=integral(ap),ib=integral(bp);summaries.append(.init(id:x.id,countA:ap.count,countB:bp.count,peakA:pa,peakB:pb,peakDelta:pb-pa,meanA:ma,meanB:mb,meanDelta:mb-ma,integralA:ia,integralB:ib,integralDelta:ib-ia,authority:"DERIVED"))}
  let residuals=[windowB.lowerBound-windowA.lowerBound,windowB.upperBound-windowA.upperBound];let q=GhostAlignmentQualityEvaluator.evaluate(residuals:residuals,ambiguousCrossings:0,excludedRegions:0,method:method.rawValue)
  return .init(method:method,quality:q,summaries:summaries,boundary:"Window summaries and A/B deltas are derived. Integral uses exported time/value coordinates. Alignment quality does not prove equivalent operating state or causation.")
 }
 private static func integral(_ p:[TelemetryPointRev116])->Double {guard p.count>1 else{return 0};var total=0.0;for i in 1..<p.count{total += (p[i].time-p[i-1].time)*(p[i].value+p[i-1].value)/2};return total}
}

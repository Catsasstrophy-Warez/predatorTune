import Foundation

enum GhostAlignmentMethodRev132:String,Codable,Sendable {case absoluteTime,rpm,eventAnchor,manualAnchor,crossCorrelationCandidate}
struct GhostAlignedMetricRev132:Identifiable,Equatable,Sendable {let id:String;let a:Double;let b:Double;let delta:Double;let authority:String}
struct GhostPullComparisonRev132:Equatable,Sendable {let method:GhostAlignmentMethodRev132;let quality:GhostAlignmentQuality;let metrics:[GhostAlignedMetricRev132];let boundary:String}
enum GhostPullComparisonEngineRev132 {
 static func compare(a:EpisodeCursorContextRev123,b:EpisodeCursorContextRev123,method:GhostAlignmentMethodRev132)->GhostPullComparisonRev132 {
  let common=Set(a.nearest.keys).intersection(b.nearest.keys).sorted();let metrics=common.compactMap{name->GhostAlignedMetricRev132? in guard let x=a.nearest[name]?.value,let y=b.nearest[name]?.value else{return nil};return .init(id:name,a:x,b:y,delta:y-x,authority:"DERIVED")}
  let residuals=common.compactMap{name->Double? in guard let x=a.nearest[name]?.time,let y=b.nearest[name]?.time else{return nil};return y-x}
  let q=GhostAlignmentQualityEvaluator.evaluate(residuals:residuals,ambiguousCrossings:0,excludedRegions:0,method:method.rawValue)
  return .init(method:method,quality:q,metrics:metrics,boundary:"A/B deltas are derived. Alignment quality describes correspondence only and cannot establish equivalent operating state or causation.")
 }
}

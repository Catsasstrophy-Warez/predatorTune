import Foundation

enum DetectionThresholdSourceRev131:String,Codable,Sendable {case analysisParameter,userSupplied,experimentDerived,sourceVerified,unknown}
struct DetectionThresholdRev131:Codable,Equatable,Sendable {
 let value:Double;let units:String;let source:DetectionThresholdSourceRev131;let rationale:String;let authorityBoundary:String
 var usable:Bool {source != .unknown && value.isFinite}
}
struct GT500EpisodeThresholdSetRev131:Codable,Equatable,Sendable {
 let highDemandPedal:DetectionThresholdRev131;let highDemandThrottle:DetectionThresholdRev131;let throttleDifference:DetectionThresholdRev131
 let accelerationRPMDelta:DetectionThresholdRev131;let episodeMergeGap:DetectionThresholdRev131;let thermalIAT2Context:DetectionThresholdRev131
 static let analysisDefaults = GT500EpisodeThresholdSetRev131(
  highDemandPedal:.init(value:60,units:"%",source:.analysisParameter,rationale:"Find high driver-demand windows.",authorityBoundary:"Analysis parameter; not a Ford WOT threshold."),
  highDemandThrottle:.init(value:50,units:"%",source:.analysisParameter,rationale:"Require substantial observed throttle with pedal demand.",authorityBoundary:"Analysis parameter; not an OEM throttle threshold."),
  throttleDifference:.init(value:5,units:"deg",source:.analysisParameter,rationale:"Surface desired/actual throttle disagreement windows.",authorityBoundary:"Analysis parameter; does not establish IPC, actuator fault, or protection intervention."),
  accelerationRPMDelta:.init(value:300,units:"rpm/row",source:.analysisParameter,rationale:"Surface rapid exported-row RPM changes.",authorityBoundary:"Analysis parameter; exported row delta is not a verified shift or per-channel sample-rate derivative."),
  episodeMergeGap:.init(value:0.30,units:"s",source:.analysisParameter,rationale:"Merge nearby marks into navigable investigation windows.",authorityBoundary:"Navigation parameter; not a controller timing constant."),
  thermalIAT2Context:.init(value:115,units:"degF",source:.analysisParameter,rationale:"Surface warmer IAT2 contexts for comparison.",authorityBoundary:"Analysis parameter; not a GT500 protection or safety threshold."))
 var usable:Bool {[highDemandPedal,highDemandThrottle,throttleDifference,accelerationRPMDelta,episodeMergeGap,thermalIAT2Context].allSatisfy(\.usable)}
}

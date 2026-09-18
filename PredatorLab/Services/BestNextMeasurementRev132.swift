import Foundation

struct MeasurementInformationGainRev132:Equatable,Sendable {let candidate:NextMeasurementCandidateRev120;let alreadyPresent:Bool;let utility:Double;let action:String;let boundary:String}
enum BestNextMeasurementEngineRev132 {
 static func rank(_ candidates:[NextMeasurementCandidateRev120],availableChannels:Set<String>)->[MeasurementInformationGainRev132] {
  candidates.map{c in
   let present=availableChannels.contains{c.measurement.localizedCaseInsensitiveContains($0) || $0.localizedCaseInsensitiveContains(c.measurement)}
   let utility=Double(c.hypothesesSeparated)*max(0,min(1,c.evidenceAuthority))/(1+max(0,c.acquisitionCost))
   return .init(candidate:c,alreadyPresent:present,utility:utility,action:present ? "Inspect the existing channel at the discriminating event before reacquiring it.":"Acquire or verify this measurement in a controlled repeatable test.",boundary:"Utility is a prioritization heuristic, not expected Bayesian information gain or diagnostic certainty.")
  }.sorted{$0.utility>$1.utility}
 }
}

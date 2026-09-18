import Foundation

struct StructuredHypothesisAssessmentRev132:Equatable,Sendable {let ranked:[RankedHypothesisRev120];let evidence:[StructuredForensicEvidenceRev131];let boundary:String}
enum StructuredHypothesisEvidenceEngineRev132 {
 static func assess(hypothesisNames:[String],evidence:[StructuredForensicEvidenceRev131])->StructuredHypothesisAssessmentRev132 {
  let ranked=hypothesisNames.map{name->HypothesisEvidenceRev120 in
   let linked=evidence.filter{$0.hypothesisID==name || $0.hypothesisID==nil}
   let support=Double(linked.filter{$0.relation == .supports}.count);let contradiction=Double(linked.filter{$0.relation == .contradicts}.count);let missing=linked.filter{$0.relation == .missing}.count
   let authority=linked.isEmpty ? 0 : Double(linked.filter{$0.authority == .measuredExported}.count)/Double(linked.count)
   return .init(name:name,support:support,contradiction:contradiction,missing:missing,authorityWeight:authority)
  }
  return .init(ranked:QuantitativeHypothesisEngineRev120.rank(ranked),evidence:evidence,boundary:"Scores summarize explicit evidence relationships. Context-only observations contribute no support. Scores are not probabilities or diagnostic proof.")
 }
}

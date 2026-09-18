import Foundation

enum EvidenceWeightPolicyRev133 {
 static func authority(_ a:TraceEvidenceAuthorityRev127)->Double {switch a{case .measuredExported:return 1;case .derived:return 0.7;case .candidate:return 0.35;case .unknown:return 0}}
 static func contribution(_ e:StructuredForensicEvidenceRev131)->Double {let w=authority(e.authority);switch e.relation{case .supports:return w;case .contradicts:return -1.25*w;case .missing:return -0.35;case .context:return 0}}
}
struct HypothesisEvidenceLedgerRev133:Identifiable,Equatable,Sendable {let id:String;let support:Double;let contradiction:Double;let missing:Int;let context:Int;let netEvidence:Double;let records:[StructuredForensicEvidenceRev131];let boundary:String}
enum StructuredHypothesisEvidenceEngineRev133 {
 static func assess(hypothesisNames:[String],evidence:[StructuredForensicEvidenceRev131])->[HypothesisEvidenceLedgerRev133] {
  hypothesisNames.map{name in let linked=evidence.filter{$0.hypothesisID==name};let sup=linked.filter{$0.relation == .supports}.reduce(0){$0+EvidenceWeightPolicyRev133.authority($1.authority)};let con=linked.filter{$0.relation == .contradicts}.reduce(0){$0+EvidenceWeightPolicyRev133.authority($1.authority)};let miss=linked.filter{$0.relation == .missing}.count;let ctx=linked.filter{$0.relation == .context}.count;return .init(id:name,support:sup,contradiction:con,missing:miss,context:ctx,netEvidence:linked.reduce(0){$0+EvidenceWeightPolicyRev133.contribution($1)},records:linked,boundary:"Weighted evidence is an ordering aid. Contradiction is penalized more strongly than support; context contributes zero. Net evidence is not probability or diagnosis.")}.sorted{$0.netEvidence>$1.netEvidence}
 }
}

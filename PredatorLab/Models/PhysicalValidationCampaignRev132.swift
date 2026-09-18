import Foundation

enum PhysicalValidationStageRev132:String,Codable,Sendable {case configurationInventory,knownGoodBaseline,repeatability,controlledExperiment,dctEvidence,canEvidence,promotionReview}
struct PhysicalValidationStepRev132:Identifiable,Codable,Equatable,Sendable {let id:String;let stage:PhysicalValidationStageRev132;let objective:String;let requiredEvidence:[String];let promotionRule:String}
enum GT500PhysicalValidationCampaignRev132 {
 static let steps:[PhysicalValidationStepRev132]=[
  .init(id:"inventory",stage:.configurationInventory,objective:"Record vehicle/build/calibration/logging configuration before testing.",requiredEvidence:["vehicle/build identity","calibration identity when available","channel configuration","source hashes"],promotionRule:"No threshold or channel semantic promotion from configuration inventory alone."),
  .init(id:"baseline",stage:.knownGoodBaseline,objective:"Acquire repeatable reference sessions for this exact vehicle/build.",requiredEvidence:["multiple comparable pulls","environment/context","source hashes"],promotionRule:"May become vehicle-specific baseline after explicit validation; never universal GT500 normal."),
  .init(id:"repeat",stage:.repeatability,objective:"Quantify run-to-run variation and measured channel timing.",requiredEvidence:["repeated acquisition","timestamp analysis","configuration unchanged"],promotionRule:"Measured rates apply only to the exact tested configuration."),
  .init(id:"experiment",stage:.controlledExperiment,objective:"Change one admitted factor and compare against baseline.",requiredEvidence:["hypothesis","one-change record","A/B evidence","rollback"],promotionRule:"Promote only the relationship actually supported by repeated controlled evidence."),
  .init(id:"dct",stage:.dctEvidence,objective:"Acquire verified DCT shaft/clutch/gear evidence.",requiredEvidence:["gear state","appropriate shaft speeds","clutch state/torque where available"],promotionRule:"Slip/phase calculations remain blocked until required relationships are verified."),
  .init(id:"can",stage:.canEvidence,objective:"Collect passive raw CAN alongside known telemetry.",requiredEvidence:["capture metadata","hash","known-state interventions","multiple logs"],promotionRule:"Candidate IDs/scales remain candidates until independently repeated/verified."),
  .init(id:"promote",stage:.promotionReview,objective:"Review evidence authority before changing product truth.",requiredEvidence:["provenance","repeatability","contradictions","source lineage"],promotionRule:"Candidate → experimentally verified → source verified → vehicle validated only when the corresponding evidence exists.")]
 }


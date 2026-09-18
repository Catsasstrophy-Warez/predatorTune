import Foundation

struct PhysicalValidationObservationRev133:Identifiable,Codable,Equatable,Sendable {let id:String;let stage:PhysicalValidationStageRev132;let sourceSHA256:String?;let configurationID:String;let observedAt:Date;let observation:String;let evidenceFiles:[String];let authority:String;let boundary:String}
struct PhysicalValidationLedgerRev133:Codable,Equatable,Sendable {private(set) var observations:[PhysicalValidationObservationRev133]=[]
 mutating func record(_ o:PhysicalValidationObservationRev133){observations.append(o)}
 func stageComplete(_ stage:PhysicalValidationStageRev132)->Bool{observations.contains{$0.stage==stage && $0.sourceSHA256?.isEmpty==false}}
 static let boundary="This ledger records completed physical work only when a source hash and configuration identity are supplied. An authored campaign step is not a completed validation result."
}

import Foundation

struct CalibrationEvidenceRelationshipRev132:Identifiable,Equatable,Sendable {let id:String;let observation:String;let lab:String;let relationship:String;let authority:EngineeringAuthority;let validation:String;let boundary:String}
enum CalibrationEvidenceBridgeRev132 {
 static func relationships(availableChannels:Set<String>)->[CalibrationEvidenceRelationshipRev132] {
  GT500EngineeringLabCatalog.all.flatMap{lab in
   lab.requiredSignals.filter{req in availableChannels.contains{ $0.localizedCaseInsensitiveContains(req) || req.localizedCaseInsensitiveContains($0) }}.map{signal in
    .init(id:"\(lab.id)|\(signal)",observation:signal,lab:lab.name,relationship:"available observation may inform this engineering laboratory",authority:.predatorLabInferred,validation:"Validate with the laboratory's controlled experiment and rollback contract before promoting a calibration conclusion.",boundary:lab.truthBoundary)
   }
  }
 }
}

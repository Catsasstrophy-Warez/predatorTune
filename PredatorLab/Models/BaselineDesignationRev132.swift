import Foundation

enum BaselineDesignationAuthorityRev132:String,Codable,Sendable {case userValidatedReference,experimentValidated,sourceVerified,unknown}
struct BaselineDesignationRev132:Identifiable,Codable,Equatable,Sendable {
 let id:String;let vehicleID:UUID;let buildStateID:UUID?;let sourceSHA256:String?;let sourceFilename:String;let designatedAt:Date;let authority:BaselineDesignationAuthorityRev132;let configurationNote:String;let validationNote:String
 let boundary:String
 var usable:Bool {authority != .unknown && sourceSHA256?.isEmpty == false}
}
enum BaselineDesignationEngineRev132 {
 static func designate(vehicleID:UUID,buildStateID:UUID?,log:ImportedLog,authority:BaselineDesignationAuthorityRev132,configurationNote:String,validationNote:String)->BaselineDesignationRev132 {
  .init(id:"baseline|\(log.id.uuidString)",vehicleID:vehicleID,buildStateID:buildStateID,sourceSHA256:log.sourceSHA256,sourceFilename:log.filename,designatedAt:.now,authority:authority,configurationNote:configurationNote,validationNote:validationNote,boundary:"Reference applies only to this vehicle/build/configuration context. It is not an OEM specification or universal healthy GT500 range.")
 }
}

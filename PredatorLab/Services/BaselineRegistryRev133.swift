import Foundation

enum BaselineRegistryErrorRev133:Error {case unusableDesignation,sourceMismatch}
struct BaselineRegistryRev133:Codable,Equatable,Sendable {private(set) var designations:[BaselineDesignationRev132]=[]
 mutating func add(_ value:BaselineDesignationRev132)throws{guard value.usable else{throw BaselineRegistryErrorRev133.unusableDesignation};designations.removeAll{$0.id==value.id};designations.append(value)}
 func applicable(vehicleID:UUID,buildStateID:UUID?,sourceSHA256:String?=nil)->[BaselineDesignationRev132]{designations.filter{$0.vehicleID==vehicleID && ($0.buildStateID==nil || buildStateID==nil || $0.buildStateID==buildStateID) && (sourceSHA256==nil || $0.sourceSHA256 != sourceSHA256)}}
 static let boundary="A baseline is an explicitly designated reference for a vehicle/build context. Registry membership does not make it an OEM specification or universally healthy reference."
}

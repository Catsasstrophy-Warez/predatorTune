import Foundation

enum ForensicCapabilityStateRev131:String,Codable,Sendable {case available,partial,blocked}
struct ForensicCapabilityRev131:Identifiable,Equatable,Sendable {let id:String;let title:String;let state:ForensicCapabilityStateRev131;let present:[String];let missing:[String];let boundary:String}
struct ForensicCapabilityMatrixRev131:Equatable,Sendable {let capabilities:[ForensicCapabilityRev131];let boundary:String}
enum ForensicCapabilityMapperRev131 {
 static func map(channels:[String])->ForensicCapabilityMatrixRev131 {
  let set=Set(channels)
  func capability(_ id:String,_ title:String,_ required:[String],boundary:String)->ForensicCapabilityRev131 {let p=required.filter{set.contains($0)},m=required.filter{!set.contains($0)};return .init(id:id,title:title,state:m.isEmpty ? .available:(p.isEmpty ? .blocked:.partial),present:p,missing:m,boundary:boundary)}
  let c=[
   capability("throttle","Throttle command/actual investigation",["Accelerator Position D (SAE)","Throttle Desired Angle","Throttle Angle"],boundary:"Availability means required exported channels exist; it is not a diagnosis."),
   capability("fuelPressure","Fuel-pressure response investigation",["Fuel Pressure (SAE)","Engine RPM (SAE)","Accelerator Position D (SAE)"],boundary:"Exported pressure can support response analysis; source/sensor authority remains separate."),
   capability("highDemand","High-demand episode comparison",["Engine RPM (SAE)","Accelerator Position D (SAE)","Throttle Angle","Intake Air Temp 2"],boundary:"High-demand is an analysis classification, not Ford WOT."),
   capability("dctSlip","DCT clutch slip energy",["DCT Input Shaft Speed","DCT Output Shaft Speed","DCT Clutch Torque","DCT Gear State"],boundary:"Blocked unless verified shaft relationship, gear state, and appropriate clutch torque are present."),
   capability("shiftPhase","Verified DCT shift-phase reconstruction",["DCT Input Shaft Speed","DCT Output Shaft Speed","DCT Gear State","DCT Clutch State"],boundary:"Engine RPM dynamics alone do not establish a TR-9070 shift phase."),
   capability("rawCAN","Raw CAN semantic decoding",["Raw CAN Frame ID","Raw CAN Payload"],boundary:"Frames enable candidate research only; exact GT500 IDs/scales require independent validation.")]
  return .init(capabilities:c,boundary:"Capability is computed from the imported artifact's channel inventory. Missing evidence stays blocked rather than inferred.")
 }
}

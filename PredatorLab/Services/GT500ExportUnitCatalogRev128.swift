import Foundation
enum GT500ExportUnitCatalogRev128 {
 static let observedSep2:[String:String] = [
  "Engine RPM (SAE)":"rpm","Knock Correction (+Adv/-Ret)":"°","Fuel Pressure (SAE)":"psi",
  "Scheduled Torque":"lb·ft","Engine Brake Torque":"lb·ft","Accelerator Position D (SAE)":"%",
  "Throttle Desired Angle":"°","Throttle Angle":"°","Intake Air Temp 2":"°F","Engine Coolant Temp":"°F"
 ]
 static func units(for channels:[String])->[String:String]{Dictionary(uniqueKeysWithValues:channels.compactMap{n in observedSep2[n].map{(n,$0)}})}
 static let boundary="Units are transcribed from the exact bundled sep2 export metadata for matching channel names. Other imports require their own metadata; no unit is inferred for unmatched channels."
}

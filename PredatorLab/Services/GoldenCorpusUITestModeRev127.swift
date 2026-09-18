import Foundation
enum GoldenCorpusUITestModeRev127 {
 static let argument="--predatorlab-golden-corpus"
 static var enabled:Bool{ProcessInfo.processInfo.arguments.contains(argument)}
 static func fixtureURL(bundle:Bundle = .main)->URL?{
  bundle.url(forResource:"sep2_full_real_hptuners_export",withExtension:"csv",subdirectory:"Fixtures") ??
  bundle.url(forResource:"sep2_full_real_hptuners_export",withExtension:"csv")
 }
 static let boundary="UI-test mode loads the exact bundled forensic fixture for deterministic navigation tests. It does not simulate MPVI4 hardware, a live vehicle, or source verification."
}

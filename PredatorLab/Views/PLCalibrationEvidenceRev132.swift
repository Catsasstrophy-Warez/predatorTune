import SwiftUI
struct PLCalibrationEvidenceRev132:View {
 let channels:Set<String>
 var body:some View{PLInstrumentChrome{VStack(alignment:.leading,spacing:4){Text("CALIBRATION RELATIONSHIPS · READ ONLY").font(.system(size:8,weight:.black,design:.monospaced)).foregroundStyle(.plBoost);ForEach(CalibrationEvidenceBridgeRev132.relationships(availableChannels:channels).prefix(10)){r in Text("\(r.observation) → \(r.lab)").font(.system(size:7,design:.monospaced));Text(r.validation).font(.system(size:6)).foregroundStyle(.plTextSecondary)};Text("Relationships are research/navigation aids and cannot outrank their source evidence.").font(.system(size:7)).foregroundStyle(.plTextSecondary)}}}
}

import SwiftUI
struct PLForensicCapabilityMatrixRev131:View {
 let matrix:ForensicCapabilityMatrixRev131
 var body:some View{PLInstrumentChrome{VStack(alignment:.leading,spacing:5){
  Text("CAPABILITY MATRIX").font(.plScaled(8,weight:.black,design:.monospaced)).foregroundStyle(.plBoost)
  ForEach(matrix.capabilities){c in HStack(alignment:.top,spacing:6){Text(c.state.rawValue.uppercased()).font(.plScaled(6,weight:.black,design:.monospaced));VStack(alignment:.leading,spacing:2){Text(c.title).font(.plScaled(7,weight:.bold));if !c.missing.isEmpty{Text("Missing: "+c.missing.joined(separator:", ")).font(.plScaled(6)).foregroundStyle(.plTextSecondary)};Text(c.boundary).font(.plScaled(6)).foregroundStyle(.plTextSecondary)}}}
  Text(matrix.boundary).font(.plScaled(7)).foregroundStyle(.plTextSecondary)
 }}.accessibilityIdentifier("forensic.capabilityMatrix")}
}

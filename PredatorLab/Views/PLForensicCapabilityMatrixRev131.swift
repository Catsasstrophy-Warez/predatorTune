import SwiftUI
struct PLForensicCapabilityMatrixRev131:View {
 let matrix:ForensicCapabilityMatrixRev131
 var body:some View{PLInstrumentChrome{VStack(alignment:.leading,spacing:5){
  Text("CAPABILITY MATRIX").font(.system(size:8,weight:.black,design:.monospaced)).foregroundStyle(.plBoost)
  ForEach(matrix.capabilities){c in HStack(alignment:.top,spacing:6){Text(c.state.rawValue.uppercased()).font(.system(size:6,weight:.black,design:.monospaced));VStack(alignment:.leading,spacing:2){Text(c.title).font(.system(size:7,weight:.bold));if !c.missing.isEmpty{Text("Missing: "+c.missing.joined(separator:", ")).font(.system(size:6)).foregroundStyle(.plTextSecondary)};Text(c.boundary).font(.system(size:6)).foregroundStyle(.plTextSecondary)}}}
  Text(matrix.boundary).font(.system(size:7)).foregroundStyle(.plTextSecondary)
 }}.accessibilityIdentifier("forensic.capabilityMatrix")}
}

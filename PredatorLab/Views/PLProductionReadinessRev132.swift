import SwiftUI
struct PLProductionReadinessRev132:View {
 var body:some View {
  PLInstrumentChrome {
   VStack(alignment:.leading,spacing:4) {
    Text("VALIDATION GATES").font(.system(size:8,weight:.black,design:.monospaced)).foregroundStyle(.plBoost)
    ForEach(ProductionReadinessMatrixRev132.gates) { g in
     HStack {Text(g.state.rawValue.uppercased()).font(.system(size:6,weight:.black,design:.monospaced));Text(g.name).font(.system(size:7));Spacer()}
    }
   }
  }
 }
}

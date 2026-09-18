import SwiftUI
struct PLEvidenceWhyInspectorRev128:View {
 let inspector:CursorEvidenceInspectorRev128
 var body:some View{PLInstrumentChrome{VStack(alignment:.leading,spacing:5){
  HStack{Text("EVIDENCE / WHY").font(.system(size:8,weight:.black,design:.monospaced)).foregroundStyle(.plBoost);Spacer();Text(String(format:"%.3f s",inspector.cursor)).font(.system(size:7,weight:.bold,design:.monospaced))}
  ForEach(inspector.measurements.prefix(12)){m in HStack(spacing:5){
   Text(m.authority.rawValue).font(.system(size:6,weight:.black,design:.monospaced))
   Text(m.id).font(.system(size:7)).lineLimit(1);Spacer()
   Text(String(format:"%.3f",m.value)+(m.unit.isEmpty ? "":" "+m.unit)).font(.system(size:7,weight:.bold,design:.monospaced))
   if let d=m.deltaFromEpisodePeak{Text(String(format:"Δ%+.3f",d)).font(.system(size:6,design:.monospaced)).foregroundStyle(.plTextSecondary)}
  }}
  Text(inspector.boundary).font(.system(size:7)).foregroundStyle(.plTextSecondary)
 }}.accessibilityIdentifier("forensic.evidenceWhy")}
}

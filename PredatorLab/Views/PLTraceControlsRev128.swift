import SwiftUI
struct PLTraceControlsRev128:View {
 let all:[TimelineSeriesRev117];@Binding var visible:Set<String>
 var body:some View{PLInstrumentChrome{VStack(alignment:.leading,spacing:4){
  HStack{Text("TRACES").font(.system(size:8,weight:.black,design:.monospaced)).foregroundStyle(.plBoost);Spacer();Button("All"){visible=Set(all.map(\.id))};Button("None"){visible=[]}}
  ForEach(all){s in Toggle(isOn:Binding(get:{visible.contains(s.id)},set:{on in if on{visible.insert(s.id)}else{visible.remove(s.id)}})){let b=EvidenceAuthorityPresentationRev127.badge(channel:s.id);Text("\(b.authority.rawValue) · \(s.id)").font(.system(size:7,design:.monospaced))}.accessibilityIdentifier("trace.\(s.id)")}
  Text(GT500ExportUnitCatalogRev128.boundary).font(.system(size:7)).foregroundStyle(.plTextSecondary)
 }}}
}

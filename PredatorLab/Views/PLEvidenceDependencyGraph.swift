// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import SwiftUI

struct PLEvidenceDependencyNode: Identifiable, Hashable {
    let id:String;let title:String;let status:PLInstrumentStatus
}
struct PLEvidenceDependencyEdge: Identifiable, Hashable {
    let id=UUID();let from:String;let to:String;let label:String
}

struct PLEvidenceDependencyGraph: View {
    let nodes:[PLEvidenceDependencyNode];let edges:[PLEvidenceDependencyEdge]
    @Binding var selectedID:String?
    var body: some View {
        PLInstrumentChrome(accent:.plWarning) {
            VStack(alignment:.leading,spacing:10) {
                HStack { Text("EVIDENCE DEPENDENCY GRAPH").font(.system(size:10,weight:.bold,design:.monospaced)).foregroundStyle(.plWarning);Spacer();PLInstrumentStatusChip(status:.candidate) }
                Canvas { context,size in
                    let count=max(nodes.count,1)
                    var points:[String:CGPoint]=[:]
                    for (i,n) in nodes.enumerated() {
                        let x=size.width * (0.12 + 0.76 * CGFloat(i % 3)/2)
                        let row=CGFloat(i/3);let rows=CGFloat(max((count-1)/3,1))
                        let y=size.height * (0.18 + 0.64 * row/rows);points[n.id]=CGPoint(x:x,y:y)
                    }
                    for e in edges { if let a=points[e.from],let b=points[e.to] { var p=Path();p.move(to:a);p.addLine(to:b);context.stroke(p,with:.color(Color.plStroke),lineWidth:1) } }
                    for n in nodes { if let pt=points[n.id] { context.fill(Path(ellipseIn:CGRect(x:pt.x-6,y:pt.y-6,width:12,height:12)),with:.color(n.status.color)) } }
                }.frame(height:145)
                LazyVGrid(columns:[GridItem(.adaptive(minimum:130))],spacing:6) {
                    ForEach(nodes) { n in
                        Button { selectedID=n.id } label: {
                            HStack { Circle().fill(n.status.color).frame(width:6,height:6);Text(n.title).font(.system(size:9,weight:.semibold)).lineLimit(1);Spacer() }
                                .foregroundStyle(.plTextPrimary).padding(7)
                                .background(selectedID == n.id ? n.status.color.opacity(0.16):Color.black.opacity(0.15),in:RoundedRectangle(cornerRadius:6))
                        }.buttonStyle(.plain)
                    }
                }
                Text("Graph geometry communicates authored dependency only. Proximity and edge direction do not prove causation.")
                    .font(.system(size:8,design:.monospaced)).foregroundStyle(.plTextSecondary)
            }
        }
    }
}

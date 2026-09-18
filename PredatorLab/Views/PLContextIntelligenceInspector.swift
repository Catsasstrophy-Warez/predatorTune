// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import SwiftUI

struct PLContextIntelligenceInspector: View {
    let snapshot:ForensicContextSnapshot
    let cursor:ForensicCursorRev85

    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:10) {
                HStack {
                    Text("CONTEXT INTELLIGENCE").font(.system(size:10,weight:.black,design:.monospaced)).foregroundStyle(.plBoost)
                    Spacer();PLInstrumentStatusChip(status:.derived)
                }
                if let t=snapshot.time {
                    PLMetricReadout(label:"Forensic Cursor",value:String(format:"%.3f",t),unit:"s",accent:.plBoost,status:.observed)
                }
                PLInstrumentChrome {
                    VStack(alignment:.leading,spacing:7) {
                        Text("CURRENT OBSERVATIONS").font(.system(size:9,weight:.black,design:.monospaced)).foregroundStyle(.plTextSecondary)
                        if snapshot.values.isEmpty { Text("No admitted numeric samples at this cursor.").font(.plCaption).foregroundStyle(.plTextSecondary) }
                        ForEach(snapshot.values) { v in
                            HStack {
                                VStack(alignment:.leading,spacing:1) {
                                    Text(v.label).font(.system(size:9,weight:.semibold)).lineLimit(1)
                                    if let d=v.deltaFromPrevious { Text(String(format:"Δ sample %+0.3f",d)).font(.plMono(7)).foregroundStyle(.plTextSecondary) }
                                }
                                Spacer()
                                Text(String(format:"%.3f",v.value)).font(.plMono(10)).foregroundStyle(v.id == cursor.channelID ? .plBoost:.plTextPrimary)
                                if let u=v.unit { Text(u).font(.plMono(7)).foregroundStyle(.plTextSecondary) }
                            }
                        }
                    }
                }
                PLInstrumentChrome(accent:.plWarning) {
                    VStack(alignment:.leading,spacing:7) {
                        Text("NEARBY EVENTS").font(.system(size:9,weight:.black,design:.monospaced)).foregroundStyle(.plWarning)
                        if snapshot.nearbyEvents.isEmpty { Text("No authored event in the current inspection window.").font(.plCaption).foregroundStyle(.plTextSecondary) }
                        ForEach(snapshot.nearbyEvents.prefix(5)) { e in
                            HStack {
                                Circle().fill(e.severity.lowercased()=="critical" ? Color.plCritical:Color.plWarning).frame(width:6,height:6)
                                Text(e.description).font(.system(size:8,weight:.semibold)).lineLimit(2)
                                Spacer();Text(String(format:"±%.3fs",e.distanceSeconds)).font(.plMono(7)).foregroundStyle(.plTextSecondary)
                            }
                        }
                    }
                }
                PLInstrumentChrome(accent:.plIgnition) {
                    VStack(alignment:.leading,spacing:7) {
                        Text("NEXT MEASUREMENTS").font(.system(size:9,weight:.black,design:.monospaced)).foregroundStyle(.plIgnition)
                        ForEach(snapshot.nextMeasurements) { m in
                            VStack(alignment:.leading,spacing:2) {
                                HStack { Text(m.title).font(.system(size:9,weight:.bold));Spacer();Text(m.evidenceClass.rawValue.uppercased()).font(.plMono(7)).foregroundStyle(.plTextSecondary) }
                                Text(m.rationale).font(.system(size:8)).foregroundStyle(.plTextSecondary)
                            }
                        }
                    }
                }
                PLInstrumentChrome(accent:.plInfo) {
                    VStack(alignment:.leading,spacing:5) {
                        Text("PROVENANCE").font(.system(size:9,weight:.black,design:.monospaced)).foregroundStyle(.plInfo)
                        ForEach(snapshot.provenance,id:\.self){Text($0).font(.plMono(7)).textSelection(.enabled)}
                        Text(snapshot.boundary).font(.system(size:8,design:.monospaced)).foregroundStyle(.plTextSecondary)
                    }
                }
            }.padding(10)
        }.background(Color.plSurface.opacity(0.72))
    }
}

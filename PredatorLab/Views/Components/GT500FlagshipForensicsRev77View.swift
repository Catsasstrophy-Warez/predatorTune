import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.
struct GT500FlagshipForensicsRev77View: View {
    let c = GT500FlagshipForensicsRev77.sep2
    var body: some View { List {
        Section("Flagship forensic case") { Text(c.title).font(.headline); Text(c.trigger); Text(c.boundary).font(.caption) }
        Section("Observed first-out evidence") { ForEach(c.observations) { o in VStack(alignment:.leading){ Text(String(format:"%.3f s · %@",o.time,o.signal)).bold(); Text(o.value); Text(o.interpretationBoundary).font(.caption).foregroundStyle(.secondary) } } }
        Section("Competing hypotheses") { ForEach(c.hypotheses) { h in VStack(alignment:.leading){ Text("\(h.id) · \(h.title)").bold(); Text(h.status.rawValue); if !h.supporting.isEmpty { Text("Supports: \(h.supporting.joined(separator:" • "))").font(.caption) }; if !h.contradicting.isEmpty { Text("Contradicts: \(h.contradicting.joined(separator:" • "))").font(.caption) }; Text("Missing: \(h.missing.joined(separator:", "))").font(.caption).foregroundStyle(.secondary) } } }
        Section("Config B · Fuel Investigation") { ForEach(c.configB) { x in VStack(alignment:.leading){ Text("Tier \(x.tier.rawValue) · \(x.semantic)").bold(); Text("\(x.requirement) · \(x.promotionRule)").font(.caption) } } }
        Section("Next MPVI4 experiment") { ForEach(c.nextExperiment,id:\.self){ Text($0) } }
    }.navigationTitle("sep2 Forensic Case") }
}

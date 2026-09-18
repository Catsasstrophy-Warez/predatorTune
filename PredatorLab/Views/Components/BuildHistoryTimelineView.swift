import SwiftUI

struct BuildHistoryTimelineView: View {
    let vehicle: GT500Vehicle
    var body: some View {
        List(BuildHistoryTimelineEngine.timeline(vehicle: vehicle)) { entry in
            HStack(alignment:.top, spacing:12) {
                Image(systemName: entry.isCurrent ? "record.circle.fill" : "circle")
                    .foregroundStyle(entry.isCurrent ? Color.plIgnition : .secondary)
                VStack(alignment:.leading,spacing:4) {
                    HStack { Text("Rev \(entry.revisionIndex) · \(entry.name)").font(.headline); if entry.isCurrent { Text("CURRENT").font(.caption2.bold()).foregroundStyle(Color.plIgnition) } }
                    Text(entry.date.formatted(date:.abbreviated,time:.shortened)).font(.caption).foregroundStyle(.secondary)
                    if entry.revisionIndex == 1 { Text("Historical starting configuration").font(.caption) }
                    else { Text("\(entry.changeCountFromPrevious) recorded field changes" ).font(.caption); if !entry.changedCategories.isEmpty { Text(entry.changedCategories.map(\.rawValue).joined(separator:" · ")).font(.caption2).foregroundStyle(.secondary) } }
                }
            }.accessibilityIdentifier("buildHistory.entry.\(entry.revisionIndex)")
        }
        .navigationTitle("Build History")
        .overlay(alignment:.bottom) { Text("Build history records authored configuration revisions. It does not verify that every recorded part or specification is physically present.").font(.caption2).foregroundStyle(.secondary).padding().background(.thinMaterial) }
    }
}

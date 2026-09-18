import SwiftUI

struct ForensicCockpitStatusRev155: View {
    let cursor: ForensicCursorRev85
    let selection: ForensicSelectionContext
    private var packet: ForensicCockpitPacketRev155 { ForensicCockpitSynchronizationEngineRev155.packet(cursor: cursor, selection: selection) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("FORENSIC COCKPIT", systemImage: "dot.scope")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                Spacer()
                if let t = packet.time { Text(String(format: "T+%.3fs", t)).font(.system(size: 9, design: .monospaced)) }
            }
            Text(packet.authority).font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(.plBoost)
            if !packet.activeBandTitles.isEmpty { Label(packet.activeBandTitles.joined(separator: " • "), systemImage: "flag.checkered").font(.caption2) }
            if let h = packet.selectedHypothesisID { Label("Hypothesis context: \(h)", systemImage: "point.3.connected.trianglepath.dotted").font(.caption2) }
            if let comparison = packet.comparisonStatement { Label(comparison, systemImage: "arrow.left.arrow.right").font(.caption2).foregroundStyle(.plBoost) }
            if let first = packet.bestNextMeasurements.first { Label("Best next: \(first)", systemImage: "scope").font(.caption2).foregroundStyle(.orange) }
            Text(packet.boundary).font(.caption2).foregroundStyle(.secondary)
        }
        .padding(10).background(Color.plSurface).clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("workstation.forensicCockpitStatus")
    }
}

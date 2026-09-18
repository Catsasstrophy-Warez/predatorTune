import SwiftUI

struct GT500TwinCursorInspector: View {
    let cursor: ForensicCursorRev85
    let selection: ForensicSelectionContext

    private var snapshot: GT500TwinCursorSnapshot { GT500TwinCursorIntelligence.snapshot(cursor: cursor, selection: selection) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "car.side.fill").foregroundStyle(.plBoost)
                Text("TWIN RELEVANCE").font(.system(size: 9, weight: .black, design: .monospaced))
                Spacer()
                if let t = snapshot.time { Text(String(format: "T+%.3fs", t)).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary) }
            }
            if let channel = snapshot.channelID { Label(channel, systemImage: "waveform.path.ecg").font(.caption) }
            if let h = snapshot.hypothesisID { Label(h, systemImage: "questionmark.diamond").font(.caption).foregroundStyle(.orange) }
            if snapshot.matches.isEmpty {
                Text("No admitted Twin relevance for the current cursor context.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(snapshot.matches) { match in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.hexagongrid.fill").foregroundStyle(match.authority == .structured ? .purple : .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(match.title).font(.caption.bold())
                            Text(match.reason).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Text(snapshot.boundary).font(.caption2).foregroundStyle(.orange)
        }
        .padding(11).background(Color.plSurface).clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("workstation.twinRelevance")
    }
}

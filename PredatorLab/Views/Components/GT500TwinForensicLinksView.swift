import SwiftUI

struct GT500TwinForensicLinksView: View {
    let node: GT500TwinNode
    private var links: [GT500TwinForensicLink] { GT500TwinForensicBridge.links(for: node.id) }

    var body: some View {
        if !links.isEmpty {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Image(systemName: "waveform.path.ecg.rectangle.fill").foregroundStyle(.blue)
                    Text("REAL SESSION LINKS").font(.system(size: 9, weight: .black, design: .monospaced))
                    Spacer()
                    Text("sep2").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.secondary)
                }
                Text("Observed export evidence and unresolved hypotheses attached to this engineering node.").font(.caption).foregroundStyle(.secondary)
                ForEach(links) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.authority.rawValue).font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(authorityColor(item.authority))
                            if let time = item.time { Text(String(format: "t=%.3fs", time)).font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary) }
                            Spacer()
                        }
                        Text(item.title).font(.caption.bold())
                        Text(item.detail).font(.caption2).foregroundStyle(.secondary)
                        Text(item.boundary).font(.caption2).foregroundStyle(.orange)
                        NavigationLink {
                            PredatorLabWorkstationRev85(initialTwinNodeID: node.id, initialTime: item.time, initialChannelID: item.channel, initialHypothesisID: hypothesisID(from: item.id))
                        } label: {
                            Label("Open synchronized forensic context", systemImage: "scope").font(.caption2.bold())
                        }.buttonStyle(.bordered)
                    }.padding(9).background(Color.plSurfaceRaised).clipShape(RoundedRectangle(cornerRadius: 9))
                }
                NavigationLink { PLGoldenCorpusFlagshipCaseRev134() } label: {
                    Label("Open Golden Corpus A/B Case", systemImage: "flag.checkered").font(.caption.bold()).frame(maxWidth: .infinity).padding(9)
                }.buttonStyle(.bordered)
            }.padding(11).background(Color.plSurface).clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func hypothesisID(from linkID: String) -> String? {
        let upper = linkID.uppercased()
        for id in ["H1A", "H1B", "H2", "H4", "H7"] where upper.contains(id) { return id }
        return nil
    }

    private func authorityColor(_ a: TwinEvidenceAuthority) -> Color {
        switch a { case .observed: .green; case .derived: .cyan; case .candidate: .orange; case .sourceVerified: .blue; case .structured: .purple; case .unknown: .secondary }
    }
}

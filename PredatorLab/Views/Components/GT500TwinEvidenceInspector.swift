import SwiftUI

struct GT500TwinEvidenceInspector: View {
    let node: GT500TwinNode
    private var evidence: [GT500TwinEvidenceObject] { GT500TwinEvidenceGraph.evidence(for: node.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(node.name).font(.title3.bold())
                    Text("Everything PredatorLab can currently support about this node")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(node.evidenceState).font(.caption2.bold()).padding(.horizontal, 8).padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            evidenceLane

            if evidence.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray").font(.title2).foregroundStyle(.secondary)
                    Text("No attached evidence yet").font(.headline)
                    Text("The node remains navigable, but source, telemetry, measurement, and research objects have not yet been attached.")
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity).padding(.vertical, 18)
            } else {
                ForEach(TwinEvidenceKind.allCases, id: \.self) { kind in
                    let items = evidence.filter { $0.kind == kind }
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(kind.rawValue, systemImage: icon(for: kind)).font(.headline)
                            ForEach(items) { item in evidenceCard(item) }
                        }
                    }
                }
            }

            Divider()
            Label("Truth boundary", systemImage: "shield.lefthalf.filled").font(.headline)
            Text("Selection is not health. Source verification is not vehicle validation. Derived telemetry is not a causal diagnosis. Unknown fields remain unknown until evidence closes them.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .padding()
        .accessibilityIdentifier("twin.evidence.\(node.id)")
    }

    private var evidenceLane: some View {
        let c = GT500TwinEvidenceGraph.coverage(for: node.id)
        return HStack(spacing: 10) {
            Label("\(c.verified) verified", systemImage: "checkmark.seal.fill")
            Label("\(c.open) open", systemImage: "questionmark.diamond.fill")
            Spacer()
            Text("MEASURED ≠ DERIVED ≠ CANDIDATE").font(.caption2.monospaced().bold())
        }.font(.caption)
    }

    private func evidenceCard(_ item: GT500TwinEvidenceObject) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Text(item.title).font(.subheadline.bold()); Spacer(); Text(item.authority.rawValue).font(.caption2.bold()) }
            Text(item.detail).font(.footnote)
            Text("Applies: \(item.applicability)").font(.caption).foregroundStyle(.secondary)
            if let locator = item.locator { Text("Source: \(locator)").font(.caption2.monospaced()).foregroundStyle(.secondary) }
            Text("Boundary: \(item.limitation)").font(.caption).foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func icon(for kind: TwinEvidenceKind) -> String {
        switch kind {
        case .factorySource: "doc.text.magnifyingglass"
        case .topology: "point.3.connected.trianglepath.dotted"
        case .telemetry: "waveform.path.ecg"
        case .dtc: "exclamationmark.triangle"
        case .measurement: "ruler"
        case .hypothesis: "brain.head.profile"
        case .calibration: "slider.horizontal.3"
        case .researchGap: "questionmark.diamond"
        }
    }
}

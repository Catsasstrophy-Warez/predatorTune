import SwiftUI

struct ForensicInvestigationInspector: View {
    let cursor: ForensicCursorRev85
    let selection: ForensicSelectionContext
    private var snapshot: ForensicInvestigationSnapshot { ForensicInvestigationInspectorEngine.snapshot(cursor: cursor, selection: selection) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PLCommandStrip(
                title: "Investigation Inspector",
                context: snapshot.time.map { String(format: "Synchronized at T+%.3f s", $0) } ?? "Waiting for a synchronized cursor",
                accent: .plBoost,
                chips: [(snapshot.evidenceAuthority, "checkmark.shield", .plBoost)]
            )

            inspectorPanel(1, "Evidence + Event", icon: "waveform.path.ecg", accent: .plSuccess) {
                if snapshot.activeBands.isEmpty {
                    muted("Outside admitted Golden Corpus A/B windows.")
                }
                ForEach(snapshot.activeBands) { band in
                    HStack(alignment: .top, spacing: 8) {
                        Capsule().fill(Color.plBoost).frame(width: 3, height: 34)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(band.title).font(.caption.bold())
                            Text(band.authority).font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(.plBoost)
                            Text(band.boundary).font(.caption2).foregroundStyle(.plTextSecondary)
                        }
                    }
                }
                if let comparison = snapshot.comparison { Label(comparison, systemImage: "arrow.left.arrow.right").font(.caption2).foregroundStyle(.plBoost) }
            }

            inspectorPanel(2, "Physical Context", icon: "car.side.fill", accent: .plBoost) {
                if snapshot.twinMatches.isEmpty { muted("No Digital Twin relevance selected at this cursor.") }
                ForEach(snapshot.twinMatches.prefix(5), id: \.nodeID) { match in
                    HStack(alignment: .top, spacing: 7) {
                        Circle().fill(Color.plBoost).frame(width: 5, height: 5).padding(.top, 5)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(match.nodeName).font(.caption.bold())
                            Text(match.reason).font(.caption2).foregroundStyle(.plTextSecondary)
                        }
                    }
                }
            }

            inspectorPanel(3, "Hypothesis", icon: "point.3.connected.trianglepath.dotted", accent: .plWarning) {
                Text(snapshot.hypothesisID.map { "Active context: \($0)" } ?? "No hypothesis selected.").font(.caption2)
                Text("Temporal relevance is not causation.").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(.plWarning)
            }

            if !snapshot.calibrationLinks.isEmpty {
                inspectorPanel(4, "Calibration Relationships", icon: "slider.horizontal.3", accent: .plIgnition) {
                    ForEach(snapshot.calibrationLinks) { link in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(link.title).font(.caption.bold())
                            Text(link.reason).font(.caption2).foregroundStyle(.plTextSecondary)
                            PLStatusChip(title: link.authority, icon: "lock.fill", accent: .plIgnition)
                        }
                    }
                }
            }

            inspectorPanel(5, "Best Next Measurement", icon: "scope", accent: .plWarning) {
                if snapshot.acquisitionChecklist.isEmpty { muted("No missing discriminator is registered for this context.") }
                ForEach(snapshot.acquisitionChecklist.prefix(6)) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.dashed.inset.filled").foregroundStyle(.plWarning)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.measurement).font(.caption.bold())
                            Text(item.rationale).font(.caption2).foregroundStyle(.plTextSecondary)
                            Text(item.status.uppercased()).font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(.plWarning)
                        }
                    }
                }
            }

            PLAuthorityBoundaryBanner(text: snapshot.boundary)
        }
        .accessibilityIdentifier("workstation.investigationInspector")
    }

    private func muted(_ text: String) -> some View { Text(text).font(.caption2).foregroundStyle(.plTextSecondary) }

    private func inspectorPanel<Content: View>(_ step: Int, _ title: String, icon: String, accent: Color, @ViewBuilder content: () -> Content) -> some View {
        PLVisualPanel(accent: accent, padding: 11) {
            VStack(alignment: .leading, spacing: 8) {
                PLInspectorSectionHeader(step: step, title: title, icon: icon, accent: accent)
                content()
            }
        }
    }
}

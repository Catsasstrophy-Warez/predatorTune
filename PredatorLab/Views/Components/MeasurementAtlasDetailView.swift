import SwiftUI

struct MeasurementAtlasDetailView: View {
    let entry: MeasurementAtlasEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                PLCard {
                    VStack(alignment: .leading, spacing: 8) {
                        PLSectionHeader(title: entry.title, systemImage: "waveform.path.ecg", accent: .plBoost)
                        Text(entry.channel.rawValue).font(.plMono(12)).foregroundStyle(.plTextSecondary)
                        Text(entry.purpose).font(.plBody)
                    }
                }
                atlasCard("Diagnostic use", icon: "scope", text: entry.diagnosticUse)
                atlasCard("Acquisition / interpretation", icon: "exclamationmark.triangle", text: entry.qualityNote)
                if let typing = MeasurementAtlasTyping.contract(for: entry.channel) {
                    PLCard {
                        VStack(alignment: .leading, spacing: 8) {
                            PLSectionHeader(title: "Typed Quantity & Trust", systemImage: "ruler", accent: .plIgnition)
                            LabeledContent("Dimension", value: typing.dimension.rawValue.capitalized)
                            LabeledContent("Preferred display", value: typing.preferredDisplayUnit)
                            LabeledContent("Semantic state", value: typing.semanticsState.rawValue)
                            LabeledContent("Automatic conversion", value: typing.conversionAllowed ? "Admitted" : "Blocked")
                            Text(typing.boundary).font(.plCaption).foregroundStyle(.plTextSecondary)
                        }
                    }
                    .accessibilityIdentifier("measurementAtlas.trust.\(entry.channel.rawValue)")
                }
                PLCard {
                    VStack(alignment: .leading, spacing: 8) {
                        PLSectionHeader(title: "Related Investigations", systemImage: "point.3.connected.trianglepath.dotted", accent: .plIgnition)
                        ForEach(entry.relatedInvestigations, id: \.self) { investigation in
                            Label(investigation, systemImage: "arrow.triangle.branch")
                                .font(.plBody)
                        }
                    }
                }
                PLCard {
                    VStack(alignment: .leading, spacing: 8) {
                        PLSectionHeader(title: "Evidence Boundary", systemImage: "checkmark.shield", accent: .plBoost)
                        Text("This Atlas entry describes PredatorLab's canonical signal identity and diagnostic role. Scanner parameter identity, units, controller ownership, transforms, and expected values must be verified against the source configuration before a logged value is treated as authoritative physical truth.")
                            .font(.plCaption)
                            .foregroundStyle(.plTextSecondary)
                    }
                }
            }
            .padding()
        }
        .plScreenBackground()
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func atlasCard(_ title: String, icon: String, text: String) -> some View {
        PLCard {
            VStack(alignment: .leading, spacing: 8) {
                PLSectionHeader(title: title, systemImage: icon)
                Text(text).font(.plBody)
            }
        }
    }
}

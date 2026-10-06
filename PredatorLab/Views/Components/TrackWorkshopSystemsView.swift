import SwiftUI

/// Visual workshop index. Each system opens the digital twin focused on that system,
/// which routes onward into reference, diagnostics and research evidence.
struct TrackWorkshopSystemsView: View {
    private let columns = [GridItem(.adaptive(minimum: 260), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PLTrackHeader(eyebrow: "Workshop", title: "SYSTEMS", subtitle: "Pick the physical system first, then follow its evidence.", icon: "wrench.and.screwdriver.fill", accent: .plBoost)
                PLTrackSection(title: "Vehicle Map", subtitle: "Map nodes are navigation, not live status.", icon: "car.side.fill", accent: .plIgnition) {
                    NavigationLink { GT500DigitalTwinView() } label: { PLVehicleSystemMap(selected: nil).allowsHitTesting(false) }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open the interactive vehicle map")
                }
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(GT500TwinSystem.allCases) { system in
                        NavigationLink { GT500DigitalTwinView(initialSystem: system) } label: {
                            PLHubRow(title: system.displayName, subtitle: system.subtitle, icon: system.icon, accent: system.accent)
                                .padding(.horizontal, 12)
                                .background(Color.plSurface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(system.accent.opacity(0.35)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                PLCard {
                    VStack(alignment: .leading, spacing: 8) {
                        PLSectionHeader(title: "Evidence Rule", systemImage: "checkmark.shield")
                        Text("A system card is a navigation surface, not a completeness claim. Source authority and missing evidence remain visible inside Reference and Research.")
                            .font(.plCaption).foregroundStyle(.plTextSecondary)
                    }
                }
            }
            .padding()
        }
        .plHardBottomEdge()
        .plScreenBackground()
        .navigationTitle("Systems")
    }
}

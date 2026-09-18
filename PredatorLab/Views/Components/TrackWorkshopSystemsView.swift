import SwiftUI

/// Visual workshop index. Routes into existing evidence-backed surfaces rather than duplicating technical truth.
struct TrackWorkshopSystemsView: View {
    private struct SystemCard: Identifiable {
        let id = UUID(); let title: String; let subtitle: String; let icon: String; let accent: Color
    }
    private let systems: [SystemCard] = [
        .init(title: "Wiring + Connectors", subtitle: "Power, grounds, harnesses, connector evidence", icon: "point.3.connected.trianglepath.dotted", accent: .plBoost),
        .init(title: "PCM / TCM", subtitle: "Controller lineage, calibration and definition evidence", icon: "cpu", accent: .plIgnition),
        .init(title: "Sensors", subtitle: "Location, signal path, testing and failure modes", icon: "sensor.tag.radiowaves.forward", accent: .plSuccess),
        .init(title: "Fuel", subtitle: "Production fuel-control evidence and measurements", icon: "fuelpump.fill", accent: .plWarning),
        .init(title: "Predator Engine", subtitle: "Mechanical systems, service evidence and failure mechanisms", icon: "engine.combustion.fill", accent: .plIgnition),
        .init(title: "TR-9070 DCT", subtitle: "Electrical, hydraulic, clutch, thermal and torque evidence", icon: "gearshape.2.fill", accent: .plBoost),
        .init(title: "MagneRide / VDM", subtitle: "Four-corner chassis evidence and research gaps", icon: "car.side.rear.and.collision.and.car.side.front", accent: .plSuccess),
        .init(title: "ABS / EPAS", subtitle: "Brake, stability and steering diagnostic evidence", icon: "steeringwheel", accent: .plWarning)
    ]
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PLTrackHeader(eyebrow: "Workshop", title: "SYSTEMS PADDOCK", subtitle: "Find the system first, then follow its evidence into reference, diagnostics and Research Command.", icon: "wrench.and.screwdriver.fill", accent: .plBoost)
                PLTrackSection(title: "Vehicle Map", subtitle: "Choose the physical system first, then follow its evidence.", icon: "car.side.fill", accent: .plIgnition) {
                    NavigationLink { GT500DigitalTwinView() } label: { PLVehicleSystemMap(selected: nil).allowsHitTesting(false) }.buttonStyle(.plain)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                    ForEach(systems) { item in
                        NavigationLink { GT500DigitalTwinView() } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.icon).font(.title2).foregroundStyle(item.accent).frame(width: 42)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title).font(.headline).foregroundStyle(.plTextPrimary)
                                    Text(item.subtitle).font(.caption).foregroundStyle(.plTextSecondary).multilineTextAlignment(.leading)
                                }
                                Spacer(); Image(systemName: "chevron.right").foregroundStyle(.plTextSecondary)
                            }.padding(14).background(Color.plSurface).clipShape(RoundedRectangle(cornerRadius: 15)).overlay(RoundedRectangle(cornerRadius: 15).stroke(item.accent.opacity(0.35)))
                        }.buttonStyle(.plain)
                    }
                }
                PLCard {
                    VStack(alignment: .leading, spacing: 8) {
                        PLSectionHeader(title: "Evidence Rule", systemImage: "checkmark.shield")
                        Text("A system card is a navigation surface, not a completeness claim. Source authority and missing evidence remain visible inside Reference and Research Command.").font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }.padding()
        }.plScreenBackground().navigationTitle("Systems")
    }
}

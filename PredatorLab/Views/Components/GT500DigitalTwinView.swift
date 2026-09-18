import SwiftUI

/// Navigation-first digital twin. It organizes existing evidence; it never claims live health.
enum GT500TwinSystem: String, CaseIterable, Identifiable {
    case engine = "ENGINE", fuel = "FUEL", pcm = "PCM / TCM", dct = "TR-9070 DCT"
    case chassis = "MAGNERIDE / VDM", brakes = "ABS / EPAS", wiring = "WIRING", sensors = "SENSORS"
    var id: String { rawValue }
    var icon: String { switch self {
    case .engine: "engine.combustion.fill"; case .fuel: "fuelpump.fill"; case .pcm: "cpu"; case .dct: "gearshape.2.fill"
    case .chassis: "car.side.rear.and.collision.and.car.side.front"; case .brakes: "steeringwheel"; case .wiring: "point.3.connected.trianglepath.dotted"; case .sensors: "sensor.tag.radiowaves.forward" } }
    var accent: Color { switch self { case .engine,.pcm: .plIgnition; case .fuel,.brakes: .plWarning; case .chassis,.sensors: .plSuccess; default: .plBoost } }
    var subtitle: String { switch self {
    case .engine: "Predator mechanical, induction, charge cooling, VCT and service evidence"
    case .fuel: "Production GT500 injection, pump power, measurements and control evidence"
    case .pcm: "Controller lineage, calibration, definitions, software and provenance"
    case .dct: "Electrical, hydraulic, clutch, thermal and torque-coordination evidence"
    case .chassis: "Four-corner damping, VDM, ride-height and chassis evidence"
    case .brakes: "ABS, AdvanceTrac, EPB, EPAS and steering/braking evidence"
    case .wiring: "Power distribution, grounds, connectors, harnesses and circuit evidence"
    case .sensors: "Physical location, signal path, Scanner identity, testing and DTC relationships" } }
    var lanes: [String] { switch self {
    case .engine: ["Air path + supercharger", "Charge cooling", "VCT + timing", "Ignition", "Lubrication", "Mechanical fault evidence"]
    case .fuel: ["Injector supply", "Pump #1 / #2", "Pressure evidence", "Command vs response", "Transient fueling", "Production vs control-pack firewall"]
    case .pcm: ["Production PCM lineage", "TR_C75 lineage", "Calibration provenance", "Parameter definitions", "Software / strategy", "Unsupported-definition quarantine"]
    case .dct: ["C105 + wiring", "Pressure evidence", "Hydraulic actuation", "Clutch state", "Shift phases", "Torque coordination", "Thermal"]
    case .chassis: ["LF corner", "RF corner", "LR corner", "RR corner", "VDM", "Ride-height acquisition", "Damper command"]
    case .brakes: ["Wheel-speed inputs", "ABS", "AdvanceTrac", "EPB", "PSCM / EPAS", "Network + software"]
    case .wiring: ["Battery + distribution", "Fuses + relays", "Grounds", "Inline connectors", "Module connectors", "Harness routing", "Load / sensor"]
    case .sensors: ["Physical location", "Connector", "Power / reference", "Ground", "Signal", "Module destination", "Scanner channel", "Electrical test", "Related DTCs"] } }
}

struct GT500DigitalTwinView: View {
    @State private var selected: GT500TwinSystem = .engine
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 10)]
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PLTrackHeader(eyebrow: "Digital Race Engineer", title: "GT500 SYSTEM TWIN", subtitle: "Start at the physical car. Follow each system into evidence, reference, diagnostics and unresolved research.", icon: "car.side.fill", accent: .plBoost)
                PLTrackBreadcrumb(items: ["Garage", "Systems", selected.rawValue])
                PLCard {
                    VStack(alignment: .leading, spacing: 10) {
                        PLSectionHeader(title: "Interactive Vehicle", systemImage: "point.3.connected.trianglepath.dotted", accent: selected.accent)
                        PLVehicleSystemMap(selected: mapKey(selected), onSelect: selectMap)
                        Text("Navigation model only • no node represents live health or a completed diagnosis")
                            .font(.plCaption).foregroundStyle(.plTextSecondary)
                    }
                }
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(GT500TwinSystem.allCases) { system in
                        Button { selected = system } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack { Image(systemName: system.icon).foregroundStyle(system.accent); Spacer(); if selected == system { Image(systemName: "flag.checkered").foregroundStyle(.plIgnition) } }
                                Text(system.rawValue).font(.system(size: 11, weight: .black, design: .monospaced)).foregroundStyle(.plTextPrimary)
                                Text(system.subtitle).font(.caption2).foregroundStyle(.plTextSecondary).lineLimit(3)
                            }.padding(12).frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
                                .background(selected == system ? system.accent.opacity(0.12) : Color.plSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(system.accent.opacity(selected == system ? 0.8 : 0.28)))
                        }.buttonStyle(.plain).accessibilityIdentifier("twin.system.\(system.id.lowercased().replacingOccurrences(of: " ", with: "-"))")
                    }
                }
                systemDetail(selected)
                GT500TwinNodeBrowser(system: selected)
                PLTrackSection(title: "Evidence Routes", subtitle: "Move between technical reference and the research authority without losing the system context.", icon: "arrow.triangle.branch", accent: .plBoost) {
                    HStack(spacing: 10) {
                        NavigationLink { ReferenceLibraryView() } label: { route("Workshop Manual", "books.vertical.fill", .plBoost) }
                        NavigationLink { GT500ResearchCommandCenterView() } label: { route("Research Command", "scope", .plIgnition) }
                    }
                }
                PLCard {
                    VStack(alignment: .leading, spacing: 7) {
                        PLSectionHeader(title: "Truth Firewall", systemImage: "checkmark.shield", accent: .plSuccess)
                        Text("MEASURED ≠ DERIVED ≠ CANDIDATE. A factory source can verify a specific claim without validating the whole subsystem on this vehicle. Control-pack and adjacent-platform evidence never silently becomes production GT500 truth.")
                            .font(.plCaption).foregroundStyle(.plTextSecondary)
                    }
                }
            }.padding(16)
        }.plScreenBackground().navigationTitle("GT500 Twin").navigationBarTitleDisplayMode(.inline)
    }
    private func systemDetail(_ system: GT500TwinSystem) -> some View {
        PLTrackSection(title: system.rawValue, subtitle: system.subtitle, icon: system.icon, accent: system.accent) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 8)], spacing: 8) {
                ForEach(system.lanes, id: \.self) { lane in
                    HStack(spacing: 8) { Image(systemName: "circle.hexagongrid.fill").foregroundStyle(system.accent); Text(lane).font(.plCaption).foregroundStyle(.plTextPrimary); Spacer() }
                        .padding(10).background(Color.plSurfaceRaised).clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
    private func route(_ title: String, _ icon: String, _ accent: Color) -> some View {
        HStack { Image(systemName: icon); Text(title).font(.plCaption).fontWeight(.bold); Spacer(); Image(systemName: "chevron.right") }
            .foregroundStyle(accent).padding(12).frame(maxWidth: .infinity).background(Color.plSurfaceRaised).clipShape(RoundedRectangle(cornerRadius: 11))
    }
    private func mapKey(_ s: GT500TwinSystem) -> String? { switch s { case .engine: "ENGINE"; case .fuel: "FUEL"; case .pcm: "PCM"; case .dct: "DCT"; case .chassis: "VDM"; case .brakes: "ABS"; default: nil } }
    private func selectMap(_ key: String) { switch key { case "ENGINE": selected = .engine; case "FUEL": selected = .fuel; case "PCM": selected = .pcm; case "DCT": selected = .dct; case "VDM": selected = .chassis; case "ABS": selected = .brakes; default: break } }
}

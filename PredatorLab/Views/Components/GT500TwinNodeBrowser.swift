import SwiftUI

/// Component-level navigation for the GT500 System Twin.
/// Entries describe investigation structure, not live vehicle state or OEM completeness.
struct GT500TwinNode: Identifiable, Hashable {
    let id: String
    let name: String
    let role: String
    let icon: String
    let evidenceState: String
    let location: String
    let connection: String
    let measurement: String
    let scanner: String
    let dtc: String
    let researchGap: String
}

enum GT500TwinNodeCatalog {
    static func nodes(for system: GT500TwinSystem) -> [GT500TwinNode] {
        switch system {
        case .engine:
            return [
                node("supercharger-drive", "Supercharger Drive", "Airflow / mechanical drive", "fanblades.fill", "SOURCE EVIDENCE", "Front/top of Predator engine", "Belt drive → one-way clutch → supercharger", "Inspect commanded/observed airflow evidence and physical drive condition", "Correlate RPM, airflow, MAP and throttle channels when present", "P1228 is represented only where its source applicability is preserved", "Complete production service connector and test corpus still required"),
                node("vct-timing", "VCT + Timing", "Cam timing control", "timelapse", "PARTIAL", "Cylinder-head timing system", "PCM command → VCT control → cam response", "Compare command and response only when verified channels exist", "VCT channels remain configuration-dependent", "Use source-linked DTC relationships only", "Complete PC/ED pinpoint and production definition corpus required"),
                node("charge-cooling", "Charge Cooling", "Thermal / induction", "thermometer.medium", "PARTIAL", "Supercharger charge-air cooling circuit", "Pump / coolant circuit → intercooler system", "Temperature trend and pump/circuit evidence", "IAT/charge-temperature identity must remain provenance-bound", "No universal fault inference from temperature alone", "Factory electrical and hydraulic detail incomplete")]
        case .fuel:
            return [
                node("pump-1", "Fuel Pump #1", "Production fuel delivery", "fuelpump.fill", "SOURCE EVIDENCE", "Production GT500 fuel system", "Power distribution → pump → delivery system", "Command/response and pressure evidence where available", "Scanner identity must be captured from supported GT500 configuration", "No DTC is assigned without source evidence", "Connector/pin and control-strategy corpus incomplete"),
                node("pump-2", "Fuel Pump #2", "Production fuel delivery", "fuelpump.circle.fill", "SOURCE EVIDENCE", "Production GT500 fuel system", "Separate verified power-distribution circuit → pump", "Electrical supply plus fuel-delivery response", "Do not infer per-channel cadence from CSV row cadence", "Source-linked only", "Complete production wiring and PCM control semantics required"),
                node("injectors", "Port Injectors", "Fuel metering", "drop.triangle.fill", "STRUCTURED", "Predator intake/fuel delivery", "Injector supply → injector → cylinder", "Pulse/window and lambda evidence when verified", "Parameter identity remains configuration-specific", "Source-linked only", "Complete production GT500 definition and workshop matrix required")]
        case .pcm:
            return [
                node("production-pcm", "Production PCM", "Engine / torque controller", "cpu.fill", "PARTIAL", "Vehicle controller network", "Sensors + networks → PCM → actuators / torque coordination", "Controller identity, calibration provenance and supported parameters", "Capture from actual supported production GT500 configuration", "DTC semantics require Ford/HP Tuners evidence", "Complete production definition corpus remains missing"),
                node("tr-c75", "TR_C75 TCM", "DCT controller", "memorychip.fill", "SOURCE VERIFIED", "TR-9070 control system", "PCM/network ↔ TCM ↔ electro-hydraulic transmission", "Pressure/shift/control evidence only when channels are verified", "HP Tuners support is verified; full definitions are not", "P175E/P0874 workflow evidence is procedure-specific", "Complete stock/definition corpus remains missing"),
                node("control-pack", "TC-298B Control Pack", "Comparative research lineage", "externaldrive.badge.exclamationmark", "QUARANTINED", "Ford Performance control-pack ecosystem", "Unique harness/calibration/fuel requirements", "Research comparison only", "Never substitute for production GT500 parameter truth", "Not a production GT500 PCM diagnostic shortcut", "Keep lineage firewall explicit")]
        case .dct:
            return [
                node("c105", "Inline Connector C105", "Harness / transmission diagnostic branch", "cable.connector", "SOURCE VERIFIED", "Beside right-side valve cover per applicable Ford service evidence", "Vehicle harness ↔ transmission/control path", "Inspect terminal seating, damage and harness condition under applicable complaint", "Not a Scanner channel", "Associated service evidence is complaint/DTC scoped", "Full pin/circuit map still requires factory wiring corpus"),
                node("pressure", "Transmission Pressure Evidence", "Hydraulic control", "gauge.with.dots.needle.50percent", "SOURCE VERIFIED", "TR-9070 electro-hydraulic system", "Sensor → TCM pressure interpretation", "Procedure-specific engine-off pressure discriminator", "DID/Scanner availability depends on diagnostic environment", "P175E/P0874 source evidence", "3.0 bar must never become a universal operating threshold"),
                node("clutches", "Wet Clutch System", "Torque transfer", "circle.grid.cross.fill", "PARTIAL", "TR-9070 internal clutch system", "Hydraulic actuation → clutch torque → driveline", "Requires verified shaft/gear relationship before slip calculation", "RPM difference alone is not clutch slip", "No automatic fault classification", "Need verified clutch/shaft channels and factory hydraulic detail")]
        case .chassis:
            return ["LF","RF","LR","RR"].map { corner in
                node("ride-\(corner.lowercased())", "\(corner) Ride-Height Path", "Four-corner chassis evidence", "arrow.up.and.down.circle.fill", "PARTIAL", "\(corner) suspension corner", "Physical linkage/sensor → wiring → VDM → damper control context", "Sweep/continuity and synchronized chassis evidence", "VDM PID identity must be verified on the target vehicle", "Do not classify a damper fault from sensor correlation alone", "GT500-specific pinout, voltage range and calibration procedure required")
            } + [node("vdm", "Vehicle Dynamics Module", "MagneRide/chassis controller", "square.stack.3d.up.fill", "SOURCE EVIDENCE", "Vehicle chassis network", "Corner inputs + network → VDM → damper commands", "Power/network/input/command evidence", "Verified VDM channels required", "Source-linked only", "Complete GT500 VDM workshop corpus required")]
        case .brakes:
            return [
                node("abs", "ABS / AdvanceTrac", "Brake and stability controller", "exclamationmark.octagon.fill", "SOURCE EVIDENCE", "Vehicle brake/control network", "Wheel inputs + network + software → brake/stability functions", "Power, wheel inputs, network and software state", "Verified ABS PIDs required", "EPB battery-drain evidence is software/applicability scoped", "Complete GT500 pinpoint and connector corpus required"),
                node("pscm", "PSCM / EPAS", "Electric steering controller", "steeringwheel", "SOURCE EVIDENCE", "Steering system", "Steering inputs/network → PSCM → assist motor", "Power, network, input and software/configuration evidence", "Verified PSCM PIDs required", "U3000:62 evidence is applicability scoped", "Complete GT500 connector/pinpoint corpus required")]
        case .wiring:
            return [
                node("power-distribution", "Power Distribution", "Electrical source tree", "bolt.fill", "SOURCE VERIFIED", "Battery / fuse / relay distribution", "Source → protection → module/load", "Voltage drop, supply and loaded-circuit evidence", "Not inherently a Scanner measurement", "Electrical DTCs remain module-specific", "Complete circuit and splice topology still requires factory diagrams"),
                node("grounds", "Ground Network", "Return path", "arrow.down.to.line.compact", "SOURCE LOCATED", "Vehicle ground points", "Load/module → ground path → battery negative", "Loaded voltage-drop testing", "Not inherently a Scanner measurement", "No generic DTC mapping", "Exact GT500 ground locations/circuits require factory corpus"),
                node("connectors", "Connector Atlas", "Physical circuit interfaces", "cable.connector.horizontal", "SOURCE LOCATED", "Throughout vehicle harness", "Circuit → terminal → connector → circuit", "Terminal inspection, continuity and voltage-drop evidence", "Cross-link only when parameter/module identity is verified", "Complaint-specific relationships", "Complete connector views/pinouts remain acquisition target")]
        case .sensors:
            return [
                node("sensor-matrix", "Sensor Workshop Matrix", "Measurement graph", "sensor.fill", "STRUCTURED TARGET", "Per-sensor physical location", "Reference/supply + ground + signal → destination module", "Electrical behavior + physical behavior + correlated telemetry", "Parameter ID/source/transform/cadence provenance", "Only verified related DTCs", "Populate sensor-by-sensor from Ford + actual Scanner evidence"),
                node("scanner-identity", "Scanner Identity", "Telemetry provenance", "waveform.path.ecg.rectangle", "STRUCTURED", "Digital acquisition path", "Controller parameter → interface → Scanner/export", "Parameter ID, source, transform, configured interval and observed cadence", "Configured interval ≠ observed cadence", "Not a DTC source", "Known-good multi-session GT500 corpus still required")]
        }
    }

    private static func node(_ id: String, _ name: String, _ role: String, _ icon: String, _ evidence: String, _ location: String, _ connection: String, _ measurement: String, _ scanner: String, _ dtc: String, _ gap: String) -> GT500TwinNode {
        .init(id: id, name: name, role: role, icon: icon, evidenceState: evidence, location: location, connection: connection, measurement: measurement, scanner: scanner, dtc: dtc, researchGap: gap)
    }
}

struct GT500TwinNodeBrowser: View {
    let system: GT500TwinSystem
    @State private var selectedID: String?

    private var nodes: [GT500TwinNode] { GT500TwinNodeCatalog.nodes(for: system) }
    private var selected: GT500TwinNode? { nodes.first(where: { $0.id == selectedID }) ?? nodes.first }

    var body: some View {
        PLTrackSection(title: "Component Nodes", subtitle: "Select a physical or logical node, then move laterally through location, connection, measurement, telemetry, DTC and research evidence.", icon: "point.3.filled.connected.trianglepath.dotted", accent: system.accent) {
            VStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(nodes) { node in
                            Button { selectedID = node.id } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Image(systemName: node.icon).foregroundStyle(system.accent)
                                    Text(node.name).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.plTextPrimary)
                                    Text(node.evidenceState).font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(.plTextSecondary)
                                }.padding(10).frame(width: 155, minHeight: 86, alignment: .leading)
                                    .background((selected?.id == node.id ? system.accent.opacity(0.14) : Color.plSurfaceRaised))
                                    .clipShape(RoundedRectangle(cornerRadius: 11))
                            }.buttonStyle(.plain).accessibilityIdentifier("twin.node.\(node.id)")
                        }
                    }
                }
                if let node = selected {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack { Image(systemName: node.icon).foregroundStyle(system.accent); VStack(alignment: .leading) { Text(node.name).font(.headline); Text(node.role).font(.plCaption).foregroundStyle(.plTextSecondary) }; Spacer(); Text(node.evidenceState).font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(system.accent) }
                        detail("WHERE IS IT?", node.location, "location.fill")
                        detail("WHAT CONNECTS TO IT?", node.connection, "point.3.connected.trianglepath.dotted")
                        detail("WHAT SHOULD I MEASURE?", node.measurement, "ruler.fill")
                        detail("WHAT DID THE LOG MEASURE?", node.scanner, "waveform.path.ecg")
                        detail("WHAT DTC EVIDENCE EXISTS?", node.dtc, "exclamationmark.triangle.fill")
                        detail("WHAT IS STILL MISSING?", node.researchGap, "scope")
                        GT500TwinEvidenceInspector(node: node)
                        GT500TwinForensicLinksView(node: node)
                        NavigationLink { PredatorLabWorkstationRev85(initialTwinNodeID: node.id) } label: {
                            Label("Open node in Forensic Command Center", systemImage: "scope").font(.caption.bold()).frame(maxWidth: .infinity).padding(9)
                        }.buttonStyle(.borderedProminent).tint(system.accent)
                        HStack(spacing: 8) {
                            NavigationLink { MultiDomainDiagnosticsView() } label: { route("Diagnose", "stethoscope") }
                            NavigationLink { ReferenceLibraryView() } label: { route("Reference", "books.vertical.fill") }
                            NavigationLink { GT500ResearchCommandCenterView() } label: { route("Research", "scope") }
                        }
                    }.padding(12).background(Color.plSurface).clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private func detail(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: 9) { Image(systemName: icon).foregroundStyle(system.accent).frame(width: 18); VStack(alignment: .leading, spacing: 2) { Text(title).font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(.plTextSecondary); Text(value).font(.plCaption).foregroundStyle(.plTextPrimary) } }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private func route(_ title: String, _ icon: String) -> some View {
        HStack(spacing: 5) { Image(systemName: icon); Text(title).font(.caption2).fontWeight(.bold) }.foregroundStyle(system.accent).padding(9).frame(maxWidth: .infinity).background(Color.plSurfaceRaised).clipShape(RoundedRectangle(cornerRadius: 9))
    }
}

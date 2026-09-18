import Foundation

enum TwinEvidenceKind: String, Codable, CaseIterable, Sendable {
    case factorySource = "Factory Source"
    case topology = "Topology"
    case telemetry = "Telemetry"
    case dtc = "DTC / Service"
    case measurement = "Measurement"
    case hypothesis = "Hypothesis"
    case calibration = "Calibration"
    case researchGap = "Research Gap"
}

enum TwinEvidenceAuthority: String, Codable, Sendable {
    case sourceVerified = "SOURCE VERIFIED"
    case structured = "STRUCTURED"
    case observed = "OBSERVED"
    case derived = "DERIVED"
    case candidate = "CANDIDATE"
    case unknown = "UNKNOWN"
}

struct GT500TwinEvidenceObject: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let nodeID: String
    let kind: TwinEvidenceKind
    let title: String
    let detail: String
    let authority: TwinEvidenceAuthority
    let applicability: String
    let locator: String?
    let limitation: String
}

enum GT500TwinEvidenceGraph {
    static let objects: [GT500TwinEvidenceObject] = [
        .init(id: "c105.ssm49581", nodeID: "c105", kind: .factorySource, title: "Ford SSM 49581", detail: "Ford identifies C105 as an inline connector next to the right-side valve cover and directs inspection for pushed-out terminals, terminal damage, or harness damage for specified 2020–2021 GT500 transmission concerns.", authority: .sourceVerified, applicability: "2020–2021 Mustang GT500; SSM 49581 complaint/DTC context", locator: "NHTSA MC-10187985-0001", limitation: "Does not establish pin count, cavity numbering, conductor colors, circuit assignment, CAN role, voltage, or 2022 applicability."),
        .init(id: "c105.pinout.gap", nodeID: "c105", kind: .researchGap, title: "Complete C105 pinout", detail: "Acquire the exact production GT500 Ford wiring/connector view before assigning cavities or circuits.", authority: .unknown, applicability: "Production GT500", locator: nil, limitation: "Do not infer from legacy seed data, forums, or control-pack wiring."),
        .init(id: "dct.pressure.21-2059", nodeID: "pressure", kind: .dtc, title: "P175E / P0874 procedure evidence", detail: "Ford TSB 21-2059 uses TCM DID 1E1A with the engine off and a less-than-3.0-bar decision point in its specified diagnostic branch.", authority: .sourceVerified, applicability: "2020 Mustang GT500 meeting TSB 21-2059 criteria", locator: "NHTSA MC-10189778-0001", limitation: "3.0 bar is a procedure-specific discriminator, not a universal TR-9070 operating-pressure limit."),
        .init(id: "scanner.config.schema", nodeID: "scanner-identity", kind: .telemetry, title: "VCM Scanner channel provenance", detail: "HP Tuners documents saved channel configurations containing Parameter ID, source, polling interval, and transforms, and distinguishes polled, broadcast, unsupported, and external channels.", authority: .sourceVerified, applicability: "VCM Scanner channel configuration", locator: "HP Tuners VCM Scanner > Channels", limitation: "Configured polling interval is not proof of actual observed per-channel sample cadence."),
        .init(id: "production.pcm.definitions.gap", nodeID: "production-pcm", kind: .researchGap, title: "Production GT500 PCM definition corpus", detail: "Capture strategy-specific production GT500 VCM Editor definitions and calibration provenance from an actually supported vehicle/file.", authority: .unknown, applicability: "2020–2022 production GT500", locator: nil, limitation: "TC-298B control-pack definitions must not fill this gap."),
        .init(id: "trc75.definitions.gap", nodeID: "tr-c75", kind: .researchGap, title: "TR_C75 stock/definition corpus", detail: "Acquire verified stock files and controller-specific parameter/table evidence.", authority: .unknown, applicability: "2020–2022 GT500 TR_C75", locator: nil, limitation: "Public support listings establish support, not the complete definition universe."),
        .init(id: "controlpack.firewall", nodeID: "control-pack", kind: .topology, title: "Control-pack lineage firewall", detail: "Ford Performance documents a unique control-pack harness/calibration and return-type fuel-system requirement; it is a comparative lineage, not production GT500 truth.", authority: .sourceVerified, applicability: "M-6017-M52SC control pack", locator: "Ford Performance M-6017-M52SC", limitation: "Never inherit control-pack wiring, fuel strategy, or calibration semantics into the production GT500."),
        .init(id: "vdm.corpus.gap", nodeID: "vdm", kind: .researchGap, title: "GT500 VDM workshop corpus", detail: "Acquire GT500-specific VDM connector views, ride-height sensor ranges, pinpoint diagnostics, and calibration procedure.", authority: .unknown, applicability: "Production GT500 MagneRide/VDM", locator: nil, limitation: "Adjacent GT350 procedures are research leads only."),
        .init(id: "sensor.matrix.gap", nodeID: "sensor-matrix", kind: .researchGap, title: "Sensor-by-sensor workshop matrix", detail: "Populate physical location, connector, supply/reference, ground, signal, destination module, Scanner identity, test behavior, DTC relationships, and provenance per verified sensor.", authority: .structured, applicability: "Production GT500", locator: nil, limitation: "A field remains unknown until its exact source or vehicle measurement is captured.")
    ]

    static func evidence(for nodeID: String) -> [GT500TwinEvidenceObject] {
        objects.filter { $0.nodeID == nodeID }
    }

    static func coverage(for nodeID: String) -> (verified: Int, open: Int) {
        let items = evidence(for: nodeID)
        return (items.filter { $0.authority == .sourceVerified }.count,
                items.filter { $0.kind == .researchGap || $0.authority == .unknown }.count)
    }
}

import Foundation

enum TopologyClaimElementKind: String, Codable, CaseIterable { case connector, pin, conductor, splice, fuse, module, ground, harness }

struct TopologyEvidenceClaim: Identifiable, Codable {
    let id: String
    let kind: TopologyClaimElementKind
    let designation: String
    let statement: String
    let applicability: String
    let source: TechnicalSource?
    let locator: String?
    let state: ClaimVerificationState
    let limitations: String
}

enum TopologyEvidenceLedger {
    /// Claim-level topology evidence. Verification is intentionally granular: verifying a connector's existence/location
    /// does not verify its pinout, conductor colors, terminal numbers, voltages, or complete circuit path.
    static let claims: [TopologyEvidenceClaim] = [
        .init(id: "topology.gt500.c105.transmission.inline", kind: .connector, designation: "C105", statement: "Ford SSM 49581 identifies C105 as an inline connector next to the right-side valve cover and directs inspection for pushed-out terminals, terminal damage, or harness damage when diagnosing certain 2020-2021 GT500 transmission concerns.", applicability: "2020-2021 Mustang GT500; transmission-related concern/DTC context in SSM 49581", source: OfficialSourceRegistry.fordSSM49581, locator: "SSM 49581 — service message body", state: .oemVerified, limitations: "Verifies connector designation, approximate location, and bulletin inspection context only. It does not verify pin count, terminal numbers, wire colors, circuit assignment, CAN role, voltage, or 2022 applicability."),
        .init(id: "topology.gt500.c105.pinout", kind: .pin, designation: "C105 pinout", statement: "Complete production GT500 C105 pinout.", applicability: "Production Shelby GT500", source: nil, locator: nil, state: .unverified, limitations: "Exact Ford wiring-diagram/WSM evidence is still required. Do not infer this pinout from legacy seed data or from the SSM connector mention."),
        .init(id: "topology.gt500.magneride.pinout", kind: .pin, designation: "Vehicle Dynamics Module / MagneRide pinout", statement: "Production GT500 MagneRide controller, damper, sensor, power, ground, and network pin topology.", applicability: "2020-2022 Shelby GT500, configuration-specific", source: nil, locator: nil, state: .unverified, limitations: "Owner-manual fuse information does not establish this topology. Requires exact Ford wiring diagrams and workshop locators."),
        .init(id: "topology.gt500.abs.pinout", kind: .pin, designation: "ABS module pinout", statement: "Production GT500 ABS module connector/pin/conductor topology.", applicability: "2020-2022 Shelby GT500, model-year specific", source: nil, locator: nil, state: .unverified, limitations: "SSM/TSB software references do not establish connector topology. Requires exact Ford wiring evidence."),
        .init(id: "topology.gt500.epas.pinout", kind: .pin, designation: "EPAS pinout", statement: "Production GT500 EPAS power, ground, network, and signal topology.", applicability: "2020-2022 Shelby GT500, model-year specific", source: nil, locator: nil, state: .unverified, limitations: "Requires exact Ford wiring/WSM evidence; no inferred pinout is admitted.")
    ]

    static func claim(_ id: String) -> TopologyEvidenceClaim? { claims.first { $0.id == id } }
    static var unresolved: [TopologyEvidenceClaim] { claims.filter { $0.state == .unverified || $0.state == .disputed } }
    static let boundary = "Topology verification is element-specific. A verified connector name or location never upgrades adjacent pins, conductors, colors, measurements, or circuit paths without their own evidence."
}

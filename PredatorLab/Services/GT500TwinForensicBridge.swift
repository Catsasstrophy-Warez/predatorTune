import Foundation

/// Connects the physical/system Twin to existing real-session evidence without promoting
/// correlation into diagnosis. All returned records retain their original authority.
struct GT500TwinForensicLink: Identifiable, Hashable, Sendable {
    let id: String
    let nodeID: String
    let title: String
    let detail: String
    let authority: TwinEvidenceAuthority
    let time: Double?
    let channel: String?
    let boundary: String
}

enum GT500TwinForensicBridge {
    static let flagship = GT500FlagshipForensicsRev77.sep2

    static func links(for nodeID: String) -> [GT500TwinForensicLink] {
        switch nodeID {
        case "pressure":
            return observations(named: ["Fuel Pressure (SAE)"], nodeID: nodeID) + [
                link("pressure.h2", nodeID, "H2 Pump / pressure command limitation", hypothesis("H2"), .candidate, nil, nil,
                     "Hypothesis remains unresolved. Rising exported pressure values do not prove pressure adequacy or identify a cause."),
                link("pressure.h7", nodeID, "H7 Differential-pressure strategy interaction", hypothesis("H7"), .candidate, nil, nil,
                     "Requires desired pressure, differential-pressure context, pump command and injector effective-flow evidence.")]
        case "clutches", "tr-c75", "c105":
            return observations(named: ["Torque Source", "Spark Source"], nodeID: nodeID) + [
                link("dct.h4", nodeID, "H4 DCT shift-transient interaction", hypothesis("H4"), .candidate, nil, nil,
                     "Temporal overlap supports investigation only. Verified gear/shift/input-shaft evidence is still missing; RPM difference is not clutch slip.")]
        case "production-pcm":
            return observations(named: ["Torque Max Protection Source", "Torque Source", "Spark Source"], nodeID: nodeID)
        case "sensor-matrix", "scanner-identity":
            return flagship.observations.map { observationLink($0, nodeID: nodeID) }
        case "engine-mechanical", "supercharger":
            return observations(named: ["Engine RPM (SAE)", "Intake Air Temp 2"], nodeID: nodeID)
        case "fuel-pumps", "injectors", "production-fuel":
            return observations(named: ["Fuel Pressure (SAE)", "Torque Max Protection Source"], nodeID: nodeID) + [
                link("fuel.h1a", nodeID, "H1A Physical injector-flow capacity", hypothesis("H1A"), .candidate, nil, nil,
                     "Unresolved. Requires reviewed injector pulse width/window, desired pressure and validated lambda evidence."),
                link("fuel.h1b", nodeID, "H1B Usable injector window", hypothesis("H1B"), .candidate, nil, nil,
                     "Unresolved. High RPM/load compatibility is not proof of saturation.")]
        default:
            return []
        }
    }

    static var flagshipWindows: [GT500TwinForensicLink] {
        [
            link("window.a", "scanner-identity", "Golden Corpus high-demand window A", "5.578–6.418 s in the bundled sep2 export", .observed, 5.578, nil, "Analysis navigation window, not Ford-defined WOT or a fault threshold."),
            link("window.b", "scanner-identity", "Golden Corpus high-demand window B", "970.854–971.134 s in the bundled sep2 export", .observed, 970.854, nil, "Analysis navigation window. A/B statistics are derived and noncausal.")
        ]
    }

    private static func observations(named names: [String], nodeID: String) -> [GT500TwinForensicLink] {
        flagship.observations.filter { o in names.contains { wanted in o.signal.localizedCaseInsensitiveContains(wanted) || wanted.localizedCaseInsensitiveContains(o.signal) } }
            .map { observationLink($0, nodeID: nodeID) }
    }
    private static func observationLink(_ o: ForensicObservationRev77, nodeID: String) -> GT500TwinForensicLink {
        link("\(nodeID).\(o.id)", nodeID, o.signal, o.value, .observed, o.time, o.signal, o.interpretationBoundary)
    }
    private static func hypothesis(_ id: String) -> String {
        guard let h = flagship.hypotheses.first(where: { $0.id == id }) else { return "Unresolved hypothesis" }
        let missing = h.missing.isEmpty ? "" : " Missing: \(h.missing.joined(separator: ", "))."
        return "\(h.title). Status: \(h.status.rawValue).\(missing)"
    }
    private static func link(_ id: String, _ nodeID: String, _ title: String, _ detail: String, _ authority: TwinEvidenceAuthority, _ time: Double?, _ channel: String?, _ boundary: String) -> GT500TwinForensicLink {
        .init(id: id, nodeID: nodeID, title: title, detail: detail, authority: authority, time: time, channel: channel, boundary: boundary)
    }
}

import Foundation

/// Conservative reverse index from admitted forensic context back to Twin nodes.
/// A match means "relevant investigation node", never "failed component" or causation.
struct GT500TwinContextMatch: Identifiable, Hashable, Sendable {
    let id: String
    let nodeID: String
    let title: String
    let reason: String
    let authority: TwinEvidenceAuthority
}

enum GT500TwinBidirectionalResolver {
    static func matches(channelID: String? = nil, hypothesisID: String? = nil, topologyNodeID: String? = nil) -> [GT500TwinContextMatch] {
        var out: [GT500TwinContextMatch] = []
        if let topologyNodeID, topologyNodeID.hasPrefix("twin:") {
            let node = String(topologyNodeID.dropFirst(5))
            out.append(.init(id: "selected.\(node)", nodeID: node, title: nodeTitle(node), reason: "Explicitly selected in the GT500 System Twin", authority: .structured))
        }
        if let channel = channelID?.lowercased() {
            if channel.contains("fuel pressure") { out += [m("pressure", "Transmission Pressure Evidence", "Fuel-pressure telemetry is relevant context for the pressure/fuel investigation, but does not identify transmission pressure or a failed component."), m("pump-1", "Fuel Pump #1", "Fuel-pressure response is relevant to the production fuel-delivery investigation."), m("pump-2", "Fuel Pump #2", "Fuel-pressure response is relevant to the production fuel-delivery investigation.")] }
            if channel.contains("torque source") || channel.contains("spark source") { out += [m("production-pcm", "Production PCM", "Controller-source transitions are observed context for torque arbitration."), m("tr-c75", "TR_C75 TCM", "Torque-source timing can be relevant to DCT coordination; temporal overlap is not causation."), m("clutches", "Wet Clutch System", "Torque-source timing can be relevant to clutch-transfer hypotheses; no slip state is inferred.")] }
            if channel.contains("engine rpm") { out += [m("supercharger-drive", "Supercharger Drive", "RPM is contextual evidence for engine/air-path analysis, not a supercharger diagnosis."), m("vct-timing", "VCT + Timing", "RPM is contextual evidence for timing response analysis.")] }
            if channel.contains("intake air temp") || channel.contains("iat") { out += [m("charge-cooling", "Charge Cooling", "Charge-temperature telemetry is relevant thermal context; temperature alone does not prove a cooling fault.")] }
        }
        if let h = hypothesisID?.uppercased() {
            if h.hasPrefix("H1") { out += [m("injectors", "Port Injectors", "H1 injector-capacity/window hypotheses are unresolved and require missing discriminator channels."), m("pump-1", "Fuel Pump #1", "Fuel-delivery context can discriminate injector versus supply limitations.")] }
            if h == "H2" || h == "H7" { out += [m("pressure", "Transmission Pressure Evidence", "Pressure-related hypothesis context only; source semantics remain scoped."), m("pump-1", "Fuel Pump #1", "Pump/pressure-command limitation remains a candidate hypothesis.")] }
            if h == "H4" { out += [m("tr-c75", "TR_C75 TCM", "H4 is the unresolved DCT shift-transient interaction hypothesis."), m("clutches", "Wet Clutch System", "Clutch relevance is investigative only; verified shaft/gear evidence is still required."), m("c105", "Inline Connector C105", "Harness evidence is a separate physical branch worth preserving during DCT complaints.")] }
        }
        var seen = Set<String>()
        return out.filter { seen.insert($0.nodeID).inserted }
    }

    private static func m(_ id: String, _ title: String, _ reason: String) -> GT500TwinContextMatch {
        .init(id: "context.\(id)", nodeID: id, title: title, reason: reason, authority: .candidate)
    }
    private static func nodeTitle(_ id: String) -> String {
        for system in GT500TwinSystem.allCases {
            if let node = GT500TwinNodeCatalog.nodes(for: system).first(where: { $0.id == id }) { return node.name }
        }
        return id
    }
}

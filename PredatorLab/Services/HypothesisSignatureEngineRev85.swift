import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct HypothesisSignatureResultRev85: Identifiable, Sendable {
    let id: String
    let hypothesis: String
    let supportingObservations: [String]
    let contradictions: [String]
    let missingEvidence: [String]
    let nextMeasurements: [String]
    var isDiagnosis: Bool { false }
}

enum HypothesisSignatureEngineRev85 {
    /// Produces candidates only. No GT500 thresholds are embedded here.
    static func evaluate(channelNames: Set<String>) -> [HypothesisSignatureResultRev85] {
        let lower = Set(channelNames.map { $0.lowercased() })
        func has(_ token: String) -> Bool { lower.contains { $0.contains(token) } }
        var out: [HypothesisSignatureResultRev85] = []
        if has("boost") || has("map") {
            out.append(.init(id:"belt-slip", hypothesis:"Supercharger drive / boost-delivery limitation", supportingObservations:[], contradictions:[], missingEvidence:["Certified boost/MAP semantics", "Engine RPM", "Pulley/drive evidence"], nextMeasurements:["Compare boost behavior against RPM and commanded load" ]))
        }
        if has("fuel pressure") || has("rail pressure") {
            out.append(.init(id:"fuel-delivery", hypothesis:"Fuel-pressure / delivery limitation", supportingObservations:[], contradictions:[], missingEvidence:["Pressure desired vs actual semantics", "Injector demand/window", "Pump command or differential-pressure evidence"], nextMeasurements:["Acquire matched desired/actual pressure and injector-demand channels"]))
        }
        if has("iat") || has("charge air") {
            out.append(.init(id:"thermal", hypothesis:"Charge-air thermal influence", supportingObservations:[], contradictions:[], missingEvidence:["Certified temperature channel", "Delivered spark/source state"], nextMeasurements:["Compare temperature trajectory with delivered spark and source states"]))
        }
        return out
    }
}

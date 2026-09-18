import Foundation

enum MeasurementRisk: Int, Codable, CaseIterable { case low=0, moderate=1, high=2 }
struct MeasurementDecision: Identifiable, Codable, Equatable {
    let id: String
    var measurement: String
    var discrimination: Double
    var minutes: Double
    var relativeCost: Double
    var risk: MeasurementRisk
    var utility: Double
    var boundary: String
}

enum MeasurementDecisionEngine {
    /// Transparent heuristic: discrimination divided by burden. It is not calibrated probability or safety authorization.
    static func rank(_ candidates:[(String,Double,Double,Double,MeasurementRisk)]) -> [MeasurementDecision] {
        candidates.map { name, discrimination, minutes, cost, risk in
            let d=max(0,min(1,discrimination)), burden=1 + max(0,minutes)/15 + max(0,cost) + Double(risk.rawValue)
            return .init(id:name,measurement:name,discrimination:d,minutes:max(0,minutes),relativeCost:max(0,cost),risk:risk,utility:d/burden,boundary:"PredatorLab decision heuristic. Utility ranks information value against time/cost/risk; it is not a calibrated probability or authorization to perform an unsafe test.")
        }.sorted { $0.utility > $1.utility }
    }
}

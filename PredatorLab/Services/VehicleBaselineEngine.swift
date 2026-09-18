import Foundation

/// Vehicle-specific learned behavior. This is historical observation, never an OEM limit.
struct VehicleBaselineMetric: Identifiable, Codable, Equatable {
    let id: String
    var label: String
    var unit: String
    var sampleCount: Int
    var median: Double?
    var q1: Double?
    var q3: Double?
    var minimum: Double?
    var maximum: Double?
    var evidenceBoundary: String
}

struct VehicleBaselineProfile: Codable, Equatable {
    var vehicleID: UUID
    var buildStateID: UUID?
    var generatedAt: Date
    var metrics: [VehicleBaselineMetric]
    var warning: String
}

enum VehicleBaselineEngine {
    static func metric(id: String, label: String, unit: String, values: [Double]) -> VehicleBaselineMetric {
        let finite = values.filter(\.isFinite).sorted()
        guard !finite.isEmpty else { return .init(id:id,label:label,unit:unit,sampleCount:0,median:nil,q1:nil,q3:nil,minimum:nil,maximum:nil,evidenceBoundary:"No historical observations available. Not an OEM specification.") }
        func percentile(_ p: Double) -> Double {
            guard finite.count > 1 else { return finite[0] }
            let x = p * Double(finite.count - 1), lo = Int(floor(x)), hi = Int(ceil(x))
            return finite[lo] + (finite[hi] - finite[lo]) * (x - Double(lo))
        }
        return .init(id:id,label:label,unit:unit,sampleCount:finite.count,median:percentile(0.5),q1:percentile(0.25),q3:percentile(0.75),minimum:finite.first,maximum:finite.last,evidenceBoundary:"PredatorLab vehicle-history baseline. Describes recorded behavior only; it is not an OEM limit or proof of health.")
    }

    static func profile(vehicleID: UUID, buildStateID: UUID?, metrics: [VehicleBaselineMetric]) -> VehicleBaselineProfile {
        .init(vehicleID:vehicleID,buildStateID:buildStateID,generatedAt:.now,metrics:metrics,warning:"Learned baseline applies only to the recorded vehicle/build context. Configuration changes can reduce historical applicability.")
    }

    static func applicabilityPenalty(profileBuildID: UUID?, currentBuildID: UUID?) -> Double {
        guard let a=profileBuildID, let b=currentBuildID else { return 0.5 }
        return a == b ? 0 : 1
    }
}

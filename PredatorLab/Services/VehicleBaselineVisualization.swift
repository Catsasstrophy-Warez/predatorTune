import Foundation

struct BaselineVisualizationPoint: Identifiable, Equatable {
    let id: String
    var label: String
    var unit: String
    var q1: Double?
    var median: Double?
    var q3: Double?
    var current: Double?
    var grade: BaselineDeviationGrade
    var boundary: String
}

enum VehicleBaselineVisualizationEngine {
    static func points(profile: VehicleBaselineProfile, current: [String: Double]) -> [BaselineVisualizationPoint] {
        profile.metrics.map { metric in
            let deviation = BaselineDeviationEngine.compare(current: current[metric.id], to: metric)
            return .init(id: metric.id, label: metric.label, unit: metric.unit, q1: metric.q1, median: metric.median, q3: metric.q3, current: current[metric.id], grade: deviation.grade, boundary: deviation.boundary)
        }
    }

    static func warning(profile: VehicleBaselineProfile, currentBuildStateID: UUID?) -> String? {
        VehicleBaselineEngine.applicabilityPenalty(profileBuildID: profile.buildStateID, currentBuildID: currentBuildStateID) >= 1
            ? "Historical baseline belongs to a different build revision. Treat deviation as context only until configuration comparability is established."
            : nil
    }
}

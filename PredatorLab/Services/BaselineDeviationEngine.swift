import Foundation

enum BaselineDeviationGrade: String, Codable { case unknown, withinHistoricalBand, outsideHistoricalBand, farOutsideHistoricalBand }
struct BaselineDeviation: Codable, Equatable {
    var metricID: String; var current: Double?; var median: Double?; var delta: Double?; var normalizedIQRDistance: Double?; var grade: BaselineDeviationGrade; var boundary: String
}
enum BaselineDeviationEngine {
    static func compare(current: Double?, to metric: VehicleBaselineMetric) -> BaselineDeviation {
        guard let current, current.isFinite, let median=metric.median, let q1=metric.q1, let q3=metric.q3 else { return .init(metricID:metric.id,current:current,median:metric.median,delta:nil,normalizedIQRDistance:nil,grade:.unknown,boundary:"Insufficient historical baseline. Not an OEM limit.") }
        let iqr=max(q3-q1, 0)
        let distance = iqr > 0 ? abs(current-median)/iqr : (current == median ? 0 : nil)
        let grade: BaselineDeviationGrade
        if current >= q1 && current <= q3 { grade = .withinHistoricalBand }
        else if let distance, distance >= 2 { grade = .farOutsideHistoricalBand }
        else { grade = .outsideHistoricalBand }
        return .init(metricID:metric.id,current:current,median:median,delta:current-median,normalizedIQRDistance:distance,grade:grade,boundary:"Comparison is against this vehicle/build's recorded historical distribution, not a factory specification, OEM limit, or diagnosis.")
    }
}

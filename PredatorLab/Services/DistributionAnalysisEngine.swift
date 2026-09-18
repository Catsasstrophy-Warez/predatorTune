import Foundation

struct DistributionSummary: Codable, Equatable {
    let count: Int
    let minimum: Double?
    let q1: Double?
    let median: Double?
    let q3: Double?
    let maximum: Double?
    let mean: Double?
}

enum DistributionAnalysisEngine {
    static func summarize(_ values: [Double]) -> DistributionSummary {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return .init(count: 0, minimum: nil, q1: nil, median: nil, q3: nil, maximum: nil, mean: nil) }
        func percentile(_ p: Double) -> Double {
            guard sorted.count > 1 else { return sorted[0] }
            let position = p * Double(sorted.count - 1)
            let lower = Int(floor(position)), upper = Int(ceil(position))
            if lower == upper { return sorted[lower] }
            let fraction = position - Double(lower)
            return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction
        }
        return .init(count: sorted.count, minimum: sorted.first, q1: percentile(0.25), median: percentile(0.5), q3: percentile(0.75), maximum: sorted.last, mean: sorted.reduce(0,+)/Double(sorted.count))
    }
}

import Foundation

struct RobustDistributionSummary: Codable, Equatable {
    var count: Int
    var mean: Double?
    var median: Double?
    var standardDeviation: Double?
    var medianAbsoluteDeviation: Double?
    var q1: Double?
    var q3: Double?
    var interquartileRange: Double?
    var lowerOutliers: [Double]
    var upperOutliers: [Double]
    var meanConfidence95: ClosedRange<Double>?
    var warnings: [String]
}

enum RobustStatisticsEngine {
    static func summarize(_ values: [Double]) -> RobustDistributionSummary {
        let clean = values.filter { $0.isFinite }.sorted()
        guard !clean.isEmpty else { return .init(count: 0, mean: nil, median: nil, standardDeviation: nil, medianAbsoluteDeviation: nil, q1: nil, q3: nil, interquartileRange: nil, lowerOutliers: [], upperOutliers: [], meanConfidence95: nil, warnings: ["No finite observations."]) }
        func percentile(_ p: Double) -> Double {
            guard clean.count > 1 else { return clean[0] }
            let x = p * Double(clean.count - 1), lo = Int(floor(x)), hi = Int(ceil(x))
            return lo == hi ? clean[lo] : clean[lo] + (clean[hi] - clean[lo]) * (x - Double(lo))
        }
        let mean = clean.reduce(0,+) / Double(clean.count)
        let median = percentile(0.5), q1 = percentile(0.25), q3 = percentile(0.75), iqr = q3-q1
        let variance = clean.count > 1 ? clean.reduce(0) { $0 + pow($1-mean,2) } / Double(clean.count-1) : 0
        let sd = sqrt(variance)
        let deviations = clean.map { abs($0-median) }.sorted()
        func medianOf(_ x:[Double]) -> Double { let n=x.count; return n % 2 == 1 ? x[n/2] : (x[n/2-1]+x[n/2])/2 }
        let mad = medianOf(deviations)
        let lowFence=q1-1.5*iqr, highFence=q3+1.5*iqr
        let ci: ClosedRange<Double>? = clean.count >= 2 ? (mean - 1.96*sd/sqrt(Double(clean.count)))...(mean + 1.96*sd/sqrt(Double(clean.count))) : nil
        var warnings:[String]=[]
        if clean.count < 5 { warnings.append("Very small sample; uncertainty estimates are descriptive only.") }
        else if clean.count < 20 { warnings.append("Small cohort; interpret confidence intervals cautiously.") }
        return .init(count: clean.count, mean: mean, median: median, standardDeviation: sd, medianAbsoluteDeviation: mad, q1: q1, q3: q3, interquartileRange: iqr, lowerOutliers: clean.filter{$0<lowFence}, upperOutliers: clean.filter{$0>highFence}, meanConfidence95: ci, warnings: warnings)
    }
}

import Foundation

struct ChannelQuality: Identifiable, Codable, Equatable {
    var id: String { canonical.rawValue }
    let canonical: CanonicalChannel
    let rawName: String?
    let presentSamples: Int
    let totalSamples: Int
    let coverage: Double
    let estimatedHz: Double?
    let longestGap: TimeInterval?

    var grade: String {
        if rawName == nil { return "Missing" }
        if coverage >= 0.98, (estimatedHz ?? 0) >= 10 { return "Good" }
        if coverage >= 0.90 { return "Usable" }
        return "Limited"
    }
}

struct AcquisitionQualityReport: Codable, Equatable {
    let sampleCount: Int
    let duration: TimeInterval
    let medianInterval: TimeInterval?
    let estimatedOverallHz: Double?
    let duplicateTimestampCount: Int
    let nonMonotonicTimestampCount: Int
    let channels: [ChannelQuality]

    var warnings: [String] {
        var output: [String] = []
        if duplicateTimestampCount > 0 { output.append("Duplicate timestamps detected: \(duplicateTimestampCount).") }
        if nonMonotonicTimestampCount > 0 { output.append("Non-monotonic timestamps detected: \(nonMonotonicTimestampCount).") }
        if let hz = estimatedOverallHz, hz < 5 { output.append("Overall sample rate is low (\(String(format: "%.1f", hz)) Hz); short transients may be unresolved.") }
        output += channels.filter { $0.rawName != nil && $0.coverage < 0.90 }.map { "\($0.canonical.rawValue) has only \(Int($0.coverage * 100))% sample coverage." }
        return output
    }
}

enum AcquisitionQualityEngine {
    static func analyze(_ log: ParsedLogData, channels requested: [CanonicalChannel] = CanonicalChannel.allCases) -> AcquisitionQualityReport {
        var intervals: [TimeInterval] = []
        var duplicate = 0
        var nonMonotonic = 0
        if log.timestamps.count > 1 {
            for index in 1..<log.timestamps.count {
                let delta = log.timestamps[index] - log.timestamps[index - 1]
                if delta == 0 { duplicate += 1 }
                if delta < 0 { nonMonotonic += 1 }
                if delta > 0 { intervals.append(delta) }
            }
        }
        let median = medianValue(intervals)
        let overallHz = median.flatMap { $0 > 0 ? 1 / $0 : nil }

        let qualities = requested.map { canonical -> ChannelQuality in
            guard let raw = ChannelResolver.resolve(canonical, in: log.channels) else {
                return ChannelQuality(canonical: canonical, rawName: nil, presentSamples: 0, totalSamples: log.sampleCount, coverage: 0, estimatedHz: nil, longestGap: nil)
            }
            var presentRows: [Int] = []
            for row in log.samples.indices where log.samples[row][raw] != nil && !(log.samples[row][raw] is NSNull) { presentRows.append(row) }
            let coverage = log.sampleCount == 0 ? 0 : Double(presentRows.count) / Double(log.sampleCount)
            var gaps: [TimeInterval] = []
            if presentRows.count > 1 {
                for i in 1..<presentRows.count {
                    let a = presentRows[i - 1], b = presentRows[i]
                    if log.timestamps.indices.contains(a), log.timestamps.indices.contains(b) { gaps.append(log.timestamps[b] - log.timestamps[a]) }
                }
            }
            let med = medianValue(gaps)
            return ChannelQuality(canonical: canonical, rawName: raw, presentSamples: presentRows.count, totalSamples: log.sampleCount, coverage: coverage, estimatedHz: med.flatMap { $0 > 0 ? 1 / $0 : nil }, longestGap: gaps.max())
        }
        return AcquisitionQualityReport(sampleCount: log.sampleCount, duration: log.duration, medianInterval: median, estimatedOverallHz: overallHz, duplicateTimestampCount: duplicate, nonMonotonicTimestampCount: nonMonotonic, channels: qualities)
    }

    private static func medianValue(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }
}

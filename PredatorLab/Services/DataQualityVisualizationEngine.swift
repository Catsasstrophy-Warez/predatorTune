import Foundation

struct DataQualitySummary: Codable, Equatable {
    let overallScore: Double
    let label: String
    let presentChannels: Int
    let requestedChannels: Int
    let limitedChannels: Int
    let missingChannels: Int
    let timestampPenalty: Double
    let boundary: String
}

enum DataQualityVisualizationEngine {
    static func summarize(_ report: AcquisitionQualityReport) -> DataQualitySummary {
        let requested = report.channels.count
        let present = report.channels.filter { $0.rawName != nil }.count
        let missing = requested - present
        let limited = report.channels.filter { $0.rawName != nil && $0.grade == "Limited" }.count
        let meanCoverage = report.channels.isEmpty ? 0 : report.channels.map(\.coverage).reduce(0, +) / Double(report.channels.count)
        let rateFactor: Double
        if let hz = report.estimatedOverallHz { rateFactor = min(1, max(0, hz / 10)) } else { rateFactor = 0 }
        let timestampIssues = report.duplicateTimestampCount + report.nonMonotonicTimestampCount
        let timestampPenalty = min(0.35, Double(timestampIssues) * 0.02)
        let score = max(0, min(1, (meanCoverage * 0.65) + (rateFactor * 0.35) - timestampPenalty))
        let label = score >= 0.9 ? "Strong" : score >= 0.72 ? "Usable" : score >= 0.5 ? "Limited" : "Insufficient"
        return .init(overallScore: score, label: label, presentChannels: present, requestedChannels: requested, limitedChannels: limited, missingChannels: missing, timestampPenalty: timestampPenalty, boundary: "Acquisition quality describes whether the recording can support analysis. It is not a vehicle-health score and does not prove or disprove a fault.")
    }
}

import Foundation

struct LogEventEpisode: Identifiable, Codable {
    let id: UUID
    var eventType: String
    var start: TimeInterval
    var peak: TimeInterval
    var end: TimeInterval
    var severity: String
    var description: String
    var sampleCount: Int
    var peakValues: [String: Double]
    var sourceStates: [String: String]

    init(id: UUID = UUID(), eventType: String, start: TimeInterval, peak: TimeInterval, end: TimeInterval,
         severity: String, description: String, sampleCount: Int, peakValues: [String: Double], sourceStates: [String: String]) {
        self.id = id; self.eventType = eventType; self.start = start; self.peak = peak; self.end = end
        self.severity = severity; self.description = description; self.sampleCount = sampleCount
        self.peakValues = peakValues; self.sourceStates = sourceStates
    }

    var duration: TimeInterval { max(0, end - start) }
}

enum LogEpisodeGrouper {
    /// Groups adjacent sample-level detections into one physical episode.
    static func group(_ events: [LogEvent], maximumGap: TimeInterval = 0.25) -> [LogEventEpisode] {
        let sorted = events.sorted { $0.timestamp < $1.timestamp }
        guard var first = sorted.first else { return [] }
        var bucket: [LogEvent] = [first]
        var output: [LogEventEpisode] = []

        func flush(_ values: [LogEvent]) -> LogEventEpisode {
            let peak = values.max { severityRank($0.severity) < severityRank($1.severity) } ?? values[0]
            return LogEventEpisode(eventType: values[0].eventType, start: values[0].timestamp,
                peak: peak.timestamp, end: values.last!.timestamp, severity: peak.severity,
                description: peak.description, sampleCount: values.count, peakValues: peak.channelValues,
                sourceStates: peak.sourceStates)
        }

        for event in sorted.dropFirst() {
            let previous = bucket.last!
            if event.eventType == first.eventType && event.timestamp - previous.timestamp <= maximumGap {
                bucket.append(event)
            } else {
                output.append(flush(bucket)); bucket = [event]; first = event
            }
        }
        output.append(flush(bucket))
        return output
    }

    private static func severityRank(_ value: String) -> Int {
        switch value.lowercased() { case "critical": return 3; case "warning": return 2; default: return 1 }
    }
}

enum FlightRecorderEngine {
    static func capture(logData: ParsedLogData, episode: LogEventEpisode, preRoll: TimeInterval = 5, postRoll: TimeInterval = 2) -> FlightRecord {
        let start = max(logData.timestamps.first ?? 0, episode.start - preRoll)
        let end = min(logData.timestamps.last ?? episode.end, episode.end + postRoll)
        var points: [[String: Double]] = []
        for row in logData.samples.indices where logData.timestamps[row] >= start && logData.timestamps[row] <= end {
            var point: [String: Double] = ["Time": logData.timestamps[row]]
            for (key, value) in logData.samples[row] {
                if let number = value as? Double { point[key] = number }
            }
            points.append(point)
        }
        return FlightRecord(timestamp: episode.peak, rule: .custom(episode.eventType), windowStart: start,
                            windowEnd: end, dataPoints: points,
                            notes: "Auto-captured \(String(format: "%.3f", episode.duration)) s episode; \(episode.sampleCount) qualifying samples.")
    }
}

// PredatorLab/Services/CSVLogParser.swift
// HP Tuners CSV log parser and event detector

import Foundation

class CSVLogParser {

    /// Parse an HP Tuners exported CSV file
    static func parseHPTunerCSV(fileURL: URL) throws -> ParsedLogData {
        try StreamingCSVIngestor.parse(fileURL: fileURL).dataset
    }

    /// Streaming variant exposing malformed-row/timestamp diagnostics and cancellation/progress hooks.
    static func parseHPTunerCSVStreaming(
        fileURL: URL,
        isCancelled: () -> Bool = { false },
        progress: ((Double) -> Void)? = nil
    ) throws -> CSVIngestionResult {
        try StreamingCSVIngestor.parse(fileURL: fileURL, isCancelled: isCancelled, progress: progress)
    }

    /// RFC-4180-style row parsing for the subset commonly produced by scanner exports.
    /// Preserves empty fields and commas/escaped quotes inside quoted cells.
    static func parseCSVRow(_ row: String) -> [String] {
        var fields: [String] = []
        var field = ""
        var insideQuotes = false
        var index = row.startIndex

        while index < row.endIndex {
            let character = row[index]
            if character == "\"" {
                let next = row.index(after: index)
                if insideQuotes, next < row.endIndex, row[next] == "\"" {
                    field.append("\"")
                    index = row.index(after: next)
                    continue
                }
                insideQuotes.toggle()
            } else if character == "," && !insideQuotes {
                fields.append(field)
                field = ""
            } else {
                field.append(character)
            }
            index = row.index(after: index)
        }
        fields.append(field)
        return fields
    }

    enum ParseError: LocalizedError {
        case emptyFile
        case noTimestampChannel
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .emptyFile: return "File is empty. Please check the export."
            case .noTimestampChannel: return "Could not find a timestamp column. Ensure the HP Tuners export includes Time or Timestamp."
            case .invalidFormat: return "File format is invalid. Please export from HP Tuners as CSV."
            }
        }
    }
}

// MARK: - Parsed Log Data

struct ParsedLogData {
    let filename: String
    let fileURL: URL?
    let channels: [String]
    let timestamps: [TimeInterval]
    let samples: [[String: Any]]
    let duration: TimeInterval
    let sampleCount: Int

    func getChannel(_ name: String) -> [Any] {
        samples.map { $0[name] ?? NSNull() }
    }

    /// Row-preserving numeric access. Prefer this for event detection and synchronized charts.
    func numericValue(channel name: String, row: Int) -> Double? {
        guard samples.indices.contains(row) else { return nil }
        if let numeric = samples[row][name] as? Double { return numeric }
        if let string = samples[row][name] as? String { return Double(string) }
        return nil
    }

    /// Row-preserving string access.
    func stringValue(channel name: String, row: Int) -> String? {
        guard samples.indices.contains(row) else { return nil }
        if let string = samples[row][name] as? String { return string }
        if let numeric = samples[row][name] as? Double { return String(format: "%.6g", numeric) }
        return nil
    }

    func getAlignedNumericChannel(_ name: String) -> [Double?] {
        samples.indices.map { numericValue(channel: name, row: $0) }
    }

    func getAlignedStringChannel(_ name: String) -> [String?] {
        samples.indices.map { stringValue(channel: name, row: $0) }
    }

    func getNumericChannel(_ name: String) -> [Double] {
        samples.compactMap { sample in
            if let numeric = sample[name] as? Double {
                return numeric
            } else if let string = sample[name] as? String, let numeric = Double(string) {
                return numeric
            }
            return nil
        }
    }

    func getStringChannel(_ name: String) -> [String] {
        samples.compactMap { sample in
            if let string = sample[name] as? String {
                return string
            } else if let numeric = sample[name] as? Double {
                return String(format: "%.1f", numeric)
            }
            return nil
        }
    }
}

// MARK: - Event Detector

class LogEventDetector {

    static func detectAllEpisodes(logData: ParsedLogData, maximumGap: TimeInterval = 0.25) -> [LogEventEpisode] {
        let events = detectAllEvents(logData: logData)
        return Dictionary(grouping: events, by: \.eventType)
            .values.flatMap { LogEpisodeGrouper.group($0, maximumGap: maximumGap) }
            .sorted { $0.start < $1.start }
    }

    static func flightRecords(logData: ParsedLogData, preRoll: TimeInterval = 5, postRoll: TimeInterval = 2) -> [FlightRecord] {
        detectAllEpisodes(logData: logData).map { FlightRecorderEngine.capture(logData: logData, episode: $0, preRoll: preRoll, postRoll: postRoll) }
    }

    static func detectAllEvents(logData: ParsedLogData) -> [LogEvent] {
        var events: [LogEvent] = []

        // Detect each event type
        events.append(contentsOf: detectInsufficientFuelFlow(logData: logData))
        events.append(contentsOf: detectKnockEvents(logData: logData))
        events.append(contentsOf: detectThrottleClosures(logData: logData))
        events.append(contentsOf: detectShifts(logData: logData))
        events.append(contentsOf: detectSourceStateChanges(logData: logData))
        events.append(contentsOf: detectLambdaDeviations(logData: logData))
        events.append(contentsOf: detectFuelPressureEvents(logData: logData))

        // Sort by timestamp
        return events.sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - R04 Critical: Insufficient Fuel Flow Detection

    static func detectInsufficientFuelFlow(logData: ParsedLogData) -> [LogEvent] {
        var events: [LogEvent] = []

        // Find the "Torque Max Protection Source" channel
        let sourceChannels = [
            "Torque Max Protection Source",
            "Torque Max Source",
            "Protection Source",
            "Fuel Cut Protection"
        ]

        let sourceChannel = sourceChannels.first { logData.channels.contains($0) }
        guard let channel = sourceChannel else { return events }

        let sourceValues = logData.getAlignedStringChannel(channel)

        for (index, value) in sourceValues.enumerated() {
            guard let value else { continue }
            if value.lowercased().contains("fuel") && value.lowercased().contains("flow") {
                let timestamp = logData.timestamps[index]
                let sample = logData.samples[index]

                events.append(LogEvent(
                    timestamp: timestamp,
                    eventType: "protection",
                    description: "Insufficient Fuel Flow protection triggered",
                    severity: "critical",
                    channelValues: extractNumericValues(sample),
                    sourceStates: ["Torque Max Protection Source": value]
                ))
            }
        }

        return events
    }

    // MARK: - Knock Event Detection

    static func detectKnockEvents(logData: ParsedLogData) -> [LogEvent] {
        var events: [LogEvent] = []

        let krChannels = [
            "Knock Retard",
            "KR",
            "Cyl Knock Retard"
        ]

        let krChannel = krChannels.first { logData.channels.contains($0) }
        guard let channel = krChannel else { return events }

        let krValues = logData.getAlignedNumericChannel(channel)

        for (index, kr) in krValues.enumerated() {
            guard let kr else { continue }
            if kr > 2.0 { // Significant knock retard
                let timestamp = logData.timestamps[index]
                let sample = logData.samples[index]

                let severity = kr > 5.0 ? "critical" : kr > 3.0 ? "warning" : "info"

                events.append(LogEvent(
                    timestamp: timestamp,
                    eventType: "knock",
                    description: "Knock retard activity: \(String(format: "%.1f", kr))°",
                    severity: severity,
                    channelValues: extractNumericValues(sample)
                ))
            }
        }

        return events
    }

    // MARK: - Throttle Closure Detection

    static func detectThrottleClosures(logData: ParsedLogData) -> [LogEvent] {
        var events: [LogEvent] = []

        let throttleChannels = [
            "Actual Throttle Angle",
            "Throttle Angle Actual",
            "ETC Actual",
            "Throttle Position"
        ]

        let throttleChannel = throttleChannels.first { logData.channels.contains($0) }
        guard let channel = throttleChannel else { return events }

        let throttleValues = logData.getAlignedNumericChannel(channel)

        // Detect rapid throttle closure (change >20° in one sample)
        for (index, _) in throttleValues.enumerated() {
            guard index > 0 else { continue }

            guard let current = throttleValues[index], let previous = throttleValues[index - 1] else { continue }
            let change = abs(current - previous)

            if change > 20 && current < 15 {
                let timestamp = logData.timestamps[index]
                let sample = logData.samples[index]

                events.append(LogEvent(
                    timestamp: timestamp,
                    eventType: "throttle_closure",
                    description: "Throttle closure: \(String(format: "%.1f", current))° (\(String(format: "%.1f", change))° drop)",
                    severity: "warning",
                    channelValues: extractNumericValues(sample)
                ))
            }
        }

        return events
    }

    // MARK: - DCT Shift Detection

    static func detectShifts(logData: ParsedLogData) -> [LogEvent] {
        var events: [LogEvent] = []

        let gearChannels = [
            "Gear Selected",
            "Current Gear",
            "Gear",
            "Trans Gear"
        ]

        let gearChannel = gearChannels.first { logData.channels.contains($0) }
        guard let channel = gearChannel else { return events }

        let gearValues = logData.getAlignedStringChannel(channel)

        var previousGear: String? = nil
        for (index, gearValue) in gearValues.enumerated() {
            guard let gear = gearValue else { continue }
            if let prev = previousGear, prev != gear {
                let timestamp = logData.timestamps[index]
                let sample = logData.samples[index]

                events.append(LogEvent(
                    timestamp: timestamp,
                    eventType: "shift",
                    description: "Gear change: \(prev) → \(gear)",
                    severity: "info",
                    channelValues: extractNumericValues(sample),
                    sourceStates: ["Gear": gear]
                ))
            }
            previousGear = gear
        }

        return events
    }

    // MARK: - Source State Transitions

    static func detectSourceStateChanges(logData: ParsedLogData) -> [LogEvent] {
        var events: [LogEvent] = []

        let sourceChannels = [
            "Torque Max Source",
            "Torque Source",
            "Spark Source",
            "Throttle Source",
            "Protection Source"
        ]

        for channelName in sourceChannels {
            guard logData.channels.contains(channelName) else { continue }

            let values = logData.getAlignedStringChannel(channelName)

            var previousValue: String? = nil
            for (index, valueOrNil) in values.enumerated() {
                guard let value = valueOrNil else { continue }
                if let prev = previousValue, prev != value {
                    let timestamp = logData.timestamps[index]
                    let sample = logData.samples[index]

                    events.append(LogEvent(
                        timestamp: timestamp,
                        eventType: "source_state_change",
                        description: "\(channelName): \(prev) → \(value)",
                        severity: "warning",
                        channelValues: extractNumericValues(sample),
                        sourceStates: [channelName: value]
                    ))
                }
                previousValue = value
            }
        }

        return events
    }

    // MARK: - Lambda Deviation Detection

    static func detectLambdaDeviations(logData: ParsedLogData) -> [LogEvent] {
        var events: [LogEvent] = []

        let commandedLambdaChannels = ["Commanded Lambda", "Lambda Command", "Target Lambda"]
        let measuredLambdaChannels = ["WB Lambda B1", "WB Lambda", "O2 Sensor"]

        let commandChannel = commandedLambdaChannels.first { logData.channels.contains($0) }
        let measureChannel = measuredLambdaChannels.first { logData.channels.contains($0) }

        guard let command = commandChannel, let measured = measureChannel else { return events }

        let commandValues = logData.getAlignedNumericChannel(command)
        let measuredValues = logData.getAlignedNumericChannel(measured)

        for (index, cmdOrNil) in commandValues.enumerated() {
            guard index < measuredValues.count, let cmdValue = cmdOrNil, let measValue = measuredValues[index] else { continue }
            let deviation = abs(measValue - cmdValue)

            if deviation > 0.05 { // Significant deviation
                let timestamp = logData.timestamps[index]
                let sample = logData.samples[index]

                let severity = deviation > 0.10 ? "critical" : "warning"

                events.append(LogEvent(
                    timestamp: timestamp,
                    eventType: "lambda_deviation",
                    description: "Lambda deviation: commanded \(String(format: "%.3f", cmdValue)), measured \(String(format: "%.3f", measValue))",
                    severity: severity,
                    channelValues: extractNumericValues(sample)
                ))
            }
        }

        return events
    }

    // MARK: - Fuel Pressure Event Detection

    static func detectFuelPressureEvents(logData: ParsedLogData) -> [LogEvent] {
        var events: [LogEvent] = []

        let pressureChannels = ["Fuel Pressure Actual", "Fuel Pressure", "Pressure"]
        let commandChannels = ["Fuel Pressure Command", "Pressure Command", "FP Command"]

        let actualChannel = pressureChannels.first { logData.channels.contains($0) }
        let commandChannel = commandChannels.first { logData.channels.contains($0) }

        guard let actual = actualChannel, let command = commandChannel else { return events }

        let actualValues = logData.getAlignedNumericChannel(actual)
        let commandValues = logData.getAlignedNumericChannel(command)

        for (index, cmdOrNil) in commandValues.enumerated() {
            guard index < actualValues.count, let cmdValue = cmdOrNil, let actValue = actualValues[index] else { continue }
            let deviation = abs(actValue - cmdValue)

            if deviation > 3.0 && cmdValue > 80 { // Command is meaningful and deviation is large
                let timestamp = logData.timestamps[index]
                let sample = logData.samples[index]

                events.append(LogEvent(
                    timestamp: timestamp,
                    eventType: "fuel_pressure",
                    description: "Fuel pressure tracking loss: command \(String(format: "%.1f", cmdValue)) psi, actual \(String(format: "%.1f", actValue)) psi",
                    severity: "warning",
                    channelValues: extractNumericValues(sample)
                ))
            }
        }

        return events
    }

    // MARK: - Helper Methods

    private static func extractNumericValues(_ sample: [String: Any]) -> [String: Double] {
        var result: [String: Double] = [:]
        for (key, value) in sample {
            if let numeric = value as? Double {
                result[key] = numeric
            } else if let string = value as? String, let numeric = Double(string) {
                result[key] = numeric
            }
        }
        return result
    }
}

// MARK: - Summary Statistics

class LogSummaryGenerator {

    static func generateSummary(logData: ParsedLogData, events: [LogEvent]) -> LogSummary {

        // Identify temperature condition
        let iat2Channels = ["IAT2", "Intake Air Temp 2", "IAT Secondary"]
        let iat2Channel = iat2Channels.first { logData.channels.contains($0) }
        let iat2Values = iat2Channel.map { logData.getNumericChannel($0) } ?? []

        let avgTemp = iat2Values.isEmpty ? 0 : iat2Values.reduce(0, +) / Double(iat2Values.count)
        let condition: String
        if avgTemp < 40 {
            condition = "cold"
        } else if avgTemp < 50 {
            condition = "intermediate"
        } else {
            condition = "heat-soak"
        }

        // Count critical events
        let criticalEvents = events.filter { $0.severity == "critical" }
        let warningEvents = events.filter { $0.severity == "warning" }

        return LogSummary(
            duration: logData.duration,
            sampleCount: logData.sampleCount,
            condition: condition,
            avgTemperature: String(format: "%.1f°F", avgTemp),
            channelCount: logData.channels.count,
            totalEvents: events.count,
            criticalEvents: criticalEvents.count,
            warningEvents: warningEvents.count,
            insufficientFuelFlowCount: events.filter { $0.eventType == "protection" }.count,
            knockEventsCount: events.filter { $0.eventType == "knock" }.count,
            shiftCount: events.filter { $0.eventType == "shift" }.count
        )
    }
}

struct LogSummary {
    let duration: TimeInterval
    let sampleCount: Int
    let condition: String
    let avgTemperature: String
    let channelCount: Int
    let totalEvents: Int
    let criticalEvents: Int
    let warningEvents: Int
    let insufficientFuelFlowCount: Int
    let knockEventsCount: Int
    let shiftCount: Int

    var durationString: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
}

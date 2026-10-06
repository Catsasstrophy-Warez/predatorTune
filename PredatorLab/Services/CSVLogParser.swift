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
    /// Channel name → unit string from the export's units row ("rpm", "°F", "λ"); empty when absent.
    var units: [String: String] = [:]

    func unit(for channel: String) -> String? { units[channel] }

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

// Sample values are only ever boxed `Double` or `String`, both immutable value types, and the
// struct exposes no mutation of `samples`, so sharing it across isolation domains is safe.
extension ParsedLogData: @unchecked Sendable {}

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

    /// Detected events, one per contiguous episode (reported at the episode's peak sample)
    /// rather than one per sample, so a 2-second condition is one event, not fifty.
    static func detectAllEvents(logData: ParsedLogData) -> [LogEvent] {
        var events: [LogEvent] = []
        events.append(contentsOf: detectInsufficientFuelFlow(logData: logData))
        events.append(contentsOf: detectKnockEvents(logData: logData))
        events.append(contentsOf: detectThrottleClosures(logData: logData))
        events.append(contentsOf: detectShifts(logData: logData))
        events.append(contentsOf: detectSourceStateChanges(logData: logData))
        events.append(contentsOf: detectLambdaDeviations(logData: logData))
        events.append(contentsOf: detectFuelPressureEvents(logData: logData))
        events.append(contentsOf: detectMisfires(logData: logData))
        return events.sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - R04 Critical: Insufficient Fuel Flow

    static func detectInsufficientFuelFlow(logData: ParsedLogData) -> [LogEvent] {
        // Several logged channels map to the protection-source role; check all of them.
        let sparkChannel = ChannelResolver.resolve(.sparkSource, in: logData.channels)
        return ChannelResolver.resolveAll(.torqueProtectionSource, in: logData.channels).flatMap { channel -> [LogEvent] in
            let values = logData.getAlignedStringChannel(channel)
            let active = values.map { value -> Bool in
                guard let value = value?.lowercased() else { return false }
                return value.contains("fuel") && value.contains("flow")
            }
            return episodes(in: active, timestamps: logData.timestamps).map { run in
                let label = values[run.first] ?? "Insufficient Fuel Flow"
                var states = [channel: label]
                // Spark-source state at onset is an R04 discriminator; it is a string, so it is not in channelValues.
                if let sparkChannel, let spark = logData.stringValue(channel: sparkChannel, row: run.first) { states[sparkChannel] = spark }
                return makeEvent(logData, row: run.first, type: "protection", severity: "critical",
                                 description: "\(label) protection active for \(durationText(run, logData))",
                                 sourceStates: states)
            }
        }
    }

    // MARK: - Knock

    static func detectKnockEvents(logData: ParsedLogData) -> [LogEvent] {
        var events: [LogEvent] = []
        if let channel = ChannelResolver.resolve(.knockRetard, in: logData.channels) {
            events += knockEpisodes(logData, channel: channel, label: "Knock retard")
        }
        for (cylinder, channel) in ChannelResolver.cylinderKnockChannels(in: logData.channels) {
            events += knockEpisodes(logData, channel: channel, label: "Cylinder \(cylinder) knock retard")
        }
        return events
    }

    private static func knockEpisodes(_ logData: ParsedLogData, channel: String, label: String) -> [LogEvent] {
        let retard = logData.getAlignedNumericChannel(channel).map { value in
            value.map { ChannelResolver.knockRetardDegrees($0, channelName: channel) }
        }
        let active = retard.map { ($0 ?? 0) >= 1.0 }
        return episodes(in: active, timestamps: logData.timestamps).map { run in
            let peakRow = peak(of: run, in: retard)
            let peakValue = retard[peakRow] ?? 0
            let severity = peakValue >= 5 ? "critical" : peakValue >= 3 ? "warning" : "info"
            return makeEvent(logData, row: peakRow, type: "knock", severity: severity,
                             description: "\(label): \(String(format: "%.1f", peakValue))° peak over \(durationText(run, logData))")
        }
    }

    // MARK: - Throttle Closure

    static func detectThrottleClosures(logData: ParsedLogData) -> [LogEvent] {
        guard let channel = ChannelResolver.resolve(.throttleActual, in: logData.channels) else { return [] }
        let values = logData.getAlignedNumericChannel(channel)
        var events: [LogEvent] = []
        var lastEventTime = -Double.infinity
        for index in values.indices.dropFirst() {
            guard let current = values[index], let previous = values[index - 1] else { continue }
            let drop = previous - current
            let time = logData.timestamps[index]
            // A >20° drop to near-closed in one sample; collapse repeats within half a second.
            guard drop > 20, current < 15, time - lastEventTime > 0.5 else { continue }
            lastEventTime = time
            events.append(makeEvent(logData, row: index, type: "throttle_closure", severity: "warning",
                                    description: "Throttle closed to \(String(format: "%.1f", current))° (\(String(format: "%.1f", drop))° drop)"))
        }
        return events
    }

    // MARK: - DCT Shifts

    static func detectShifts(logData: ParsedLogData) -> [LogEvent] {
        guard let channel = ChannelResolver.resolve(.gearActual, in: logData.channels)
                ?? ChannelResolver.resolve(.gearCommanded, in: logData.channels) else { return [] }
        let gears = logData.getAlignedStringChannel(channel)
        var events: [LogEvent] = []
        var previous: String?
        for (index, value) in gears.enumerated() {
            guard let gear = value else { continue }
            if let previous, previous != gear {
                events.append(makeEvent(logData, row: index, type: "shift", severity: "info",
                                        description: "Gear change: \(previous) → \(gear)", sourceStates: ["Gear": gear]))
            }
            previous = gear
        }
        return events
    }

    // MARK: - Controller Source States

    /// States that are routine operation for each source channel. Entering any other state is
    /// reported; routine flips (e.g. "Base / MBT" ↔ "Torque Control") are not.
    private static let routineSourceStates: [String: Set<String>] = [
        "spark source": ["base / mbt", "torque control", "base", "mbt"],
        "torque max source": ["alt full load", "full load", "no limit active"],
        "throttle angle source": ["torque control", "idle control", "driver demand"],
        "driver demand limit source": ["no limit active", "anticlunk tipin tq lmt."],
        "torque airlimit source": ["no limit active"],
    ]

    static func detectSourceStateChanges(logData: ParsedLogData) -> [LogEvent] {
        logData.channels.flatMap { channel -> [LogEvent] in
            guard let routine = routineSourceStates[ChannelResolver.normalize(channel)] else { return [] }
            let values = logData.getAlignedStringChannel(channel)
            let notable = values.map { value -> Bool in
                guard let value, !value.isEmpty else { return false }
                return !routine.contains(value.lowercased())
            }
            return episodes(in: notable, timestamps: logData.timestamps).map { run in
                let state = values[run.first] ?? "?"
                return makeEvent(logData, row: run.first, type: "source_state_change", severity: "warning",
                                 description: "\(channel): \(state) for \(durationText(run, logData))",
                                 sourceStates: [channel: state])
            }
        }
    }

    // MARK: - Lambda Deviation

    /// Measured vs commanded lambda while the driver is asking for power. Below that gate the
    /// wideband lags tip-in and reads lean on decel fuel cut, which would bury real deviations.
    static func detectLambdaDeviations(logData: ParsedLogData) -> [LogEvent] {
        guard let commandChannel = ChannelResolver.resolve(.lambdaCommanded, in: logData.channels),
              let measuredChannel = ChannelResolver.resolve(.lambdaMeasured, in: logData.channels) else { return [] }
        let command = logData.getAlignedNumericChannel(commandChannel)
        let measured = logData.getAlignedNumericChannel(measuredChannel)
        let pedal = ChannelResolver.resolve(.acceleratorPedal, in: logData.channels).map { logData.getAlignedNumericChannel($0) }

        let deviation: [Double?] = command.indices.map { index in
            guard let c = command[index], index < measured.count, let m = measured[index], m < 1.5 else { return nil }
            let underLoad: Bool
            if let pedal, index < pedal.count, let p = pedal[index] { underLoad = p > 40 } else { underLoad = c < 0.95 }
            return underLoad ? abs(m - c) : nil
        }
        let active = deviation.map { ($0 ?? 0) > 0.05 }
        return episodes(in: active, timestamps: logData.timestamps, minimumDuration: 0.3).map { run in
            let peakRow = peak(of: run, in: deviation)
            let peakValue = deviation[peakRow] ?? 0
            let c = command[peakRow] ?? 0, m = measured[peakRow] ?? 0
            return makeEvent(logData, row: peakRow, type: "lambda_deviation", severity: peakValue > 0.10 ? "critical" : "warning",
                             description: "Lambda off command under load: commanded \(String(format: "%.3f", c)), measured \(String(format: "%.3f", m)) for \(durationText(run, logData))")
        }
    }

    // MARK: - Fuel Pressure

    static func detectFuelPressureEvents(logData: ParsedLogData) -> [LogEvent] {
        guard let actualChannel = ChannelResolver.resolve(.fuelPressureActual, in: logData.channels),
              let commandChannel = ChannelResolver.resolve(.fuelPressureCommanded, in: logData.channels) else { return [] }
        let actual = logData.getAlignedNumericChannel(actualChannel)
        let command = logData.getAlignedNumericChannel(commandChannel)
        let error: [Double?] = command.indices.map { index in
            guard let c = command[index], c > 80, index < actual.count, let a = actual[index] else { return nil }
            return abs(a - c)
        }
        let active = error.map { ($0 ?? 0) > 3.0 }
        return episodes(in: active, timestamps: logData.timestamps, minimumDuration: 0.1).map { run in
            let peakRow = peak(of: run, in: error)
            return makeEvent(logData, row: peakRow, type: "fuel_pressure", severity: "warning",
                             description: "Fuel pressure tracking loss: command \(String(format: "%.1f", command[peakRow] ?? 0)) psi, actual \(String(format: "%.1f", actual[peakRow] ?? 0)) psi")
        }
    }

    // MARK: - Misfires

    /// HP Tuners interpolates the misfire counter between controller samples (9.0, 9.08, 9.16 … 10.0),
    /// so only whole-number crossings are misfires. Crossings within 2 s are reported as one event.
    static func detectMisfires(logData: ParsedLogData) -> [LogEvent] {
        guard let channel = ChannelResolver.resolve(.misfireCount, in: logData.channels) else { return [] }
        let counts = logData.getAlignedNumericChannel(channel)
        var crossings: [(row: Int, added: Int, total: Int)] = []
        var whole: Int?
        for (index, value) in counts.enumerated() {
            guard let count = value else { continue }
            let current = Int(count.rounded(.down))
            if let previous = whole, current > previous { crossings.append((index, current - previous, current)) }
            whole = max(whole ?? current, current)
        }
        var events: [LogEvent] = []
        var group: [(row: Int, added: Int, total: Int)] = []
        func flush() {
            guard let first = group.first, let last = group.last else { return }
            let added = group.reduce(0) { $0 + $1.added }
            events.append(makeEvent(logData, row: first.row, type: "misfire", severity: "warning",
                                    description: "\(added) misfire\(added == 1 ? "" : "s") counted (total \(last.total) since key-on)"))
            group.removeAll()
        }
        for crossing in crossings {
            if let first = group.first, logData.timestamps[crossing.row] - logData.timestamps[first.row] > 2 { flush() }
            group.append(crossing)
        }
        flush()
        return events
    }

    // MARK: - Helpers

    struct Run { let first: Int; let last: Int }

    /// Contiguous runs of `true`, dropping runs shorter than `minimumDuration`.
    static func episodes(in active: [Bool], timestamps: [TimeInterval], minimumDuration: TimeInterval = 0) -> [Run] {
        var runs: [Run] = []
        var start: Int?
        for index in 0...active.count {
            let on = index < active.count && active[index]
            if on, start == nil { start = index }
            if !on, let first = start {
                let last = index - 1
                if timestamps.indices.contains(last), timestamps[last] - timestamps[first] >= minimumDuration {
                    runs.append(Run(first: first, last: last))
                }
                start = nil
            }
        }
        return runs
    }

    private static func peak(of run: Run, in values: [Double?]) -> Int {
        (run.first...run.last).max { (values[$0] ?? -.infinity) < (values[$1] ?? -.infinity) } ?? run.first
    }

    private static func durationText(_ run: Run, _ logData: ParsedLogData) -> String {
        String(format: "%.2f s", logData.timestamps[run.last] - logData.timestamps[run.first])
    }

    private static func makeEvent(_ logData: ParsedLogData, row: Int, type: String, severity: String,
                                  description: String, sourceStates: [String: String] = [:]) -> LogEvent {
        LogEvent(timestamp: logData.timestamps[row], eventType: type, description: description, severity: severity,
                 channelValues: extractNumericValues(logData.samples[row]), sourceStates: sourceStates)
    }

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
        // Charge-air (IAT2) condition, classified in °C whatever unit the log uses.
        let iat2Channel = ChannelResolver.resolve(.iat2, in: logData.channels)
        let iat2Values = iat2Channel.map { logData.getNumericChannel($0) } ?? []
        let average = iat2Values.isEmpty ? 0 : iat2Values.reduce(0, +) / Double(iat2Values.count)
        let unit = iat2Channel.flatMap { logData.unit(for: $0) } ?? "°F"
        let averageCelsius = unit.contains("C") ? average : (average - 32) * 5 / 9
        let condition: String
        if iat2Values.isEmpty {
            condition = "unknown"
        } else if averageCelsius < 40 {
            condition = "cold"
        } else if averageCelsius < 50 {
            condition = "intermediate"
        } else {
            condition = "heat-soak"
        }

        let criticalEvents = events.filter { $0.severity == "critical" }
        let warningEvents = events.filter { $0.severity == "warning" }

        return LogSummary(
            duration: logData.duration,
            sampleCount: logData.sampleCount,
            condition: condition,
            avgTemperature: iat2Values.isEmpty ? "—" : String(format: "%.1f", average) + unit,
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

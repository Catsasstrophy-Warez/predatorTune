import Foundation

/// One plotted channel on the log timeline.
struct LogTimelineTrack: Identifiable, Sendable {
    let id: String
    let title: String
    let unit: String?
    /// Raw channel names drawn on this track (e.g. commanded and measured lambda share one).
    let channels: [String]
}

struct LogTimelinePoint: Identifiable, Sendable {
    let id: Int
    let time: TimeInterval
    let value: Double
    let series: String
}

/// A channel's value at the cursor, for the inspector.
struct LogTimelineReading: Identifiable, Sendable {
    var id: String { channel }
    let channel: String
    let value: String
    let unit: String?
}

/// Time-synchronized view of one log: which channels to draw, decimated points for any time
/// window, and every channel's value at a cursor time.
struct LogTimelineModel: Sendable {
    let log: ParsedLogData
    let events: [LogEvent]
    let pulls: [PullReport]
    let tracks: [LogTimelineTrack]

    var startTime: TimeInterval { log.timestamps.first ?? 0 }
    var endTime: TimeInterval { log.timestamps.last ?? 0 }

    init(log: ParsedLogData, events: [LogEvent], pulls: [PullReport]) {
        self.log = log
        self.events = events
        self.pulls = pulls
        self.tracks = Self.defaultTracks(for: log)
    }

    /// Default tracks, in the order a tuner reads a pull. Only channels present in the log appear.
    static func defaultTracks(for log: ParsedLogData) -> [LogTimelineTrack] {
        func resolve(_ role: CanonicalChannel) -> String? { ChannelResolver.resolve(role, in: log.channels) }
        let candidates: [(id: String, title: String, roles: [CanonicalChannel])] = [
            ("rpm", "Engine RPM", [.engineRPM]),
            ("demand", "Pedal / Throttle", [.acceleratorPedal, .throttleActual]),
            ("map", "Manifold Pressure", [.manifoldPressure, .boostPressure]),
            ("lambda", "Lambda", [.lambdaCommanded, .lambdaMeasured, .lambdaMeasuredBank2]),
            ("timing", "Timing Advance", [.timingAdvance]),
            ("knock", "Knock Retard", [.knockRetard]),
            ("iat2", "Charge Air (IAT2)", [.iat2]),
            ("speed", "Vehicle Speed", [.vehicleSpeed]),
        ]
        return candidates.compactMap { candidate in
            let channels = candidate.roles.compactMap(resolve)
            guard let first = channels.first else { return nil }
            return LogTimelineTrack(id: candidate.id, title: candidate.title, unit: log.unit(for: first), channels: channels)
        }
    }

    /// Points for `track` within `window`, decimated to at most `buckets` min/max pairs per
    /// channel so spikes survive downsampling.
    func points(for track: LogTimelineTrack, in window: ClosedRange<TimeInterval>, buckets: Int = 240) -> [LogTimelinePoint] {
        let rows = rowRange(for: window)
        guard !rows.isEmpty else { return [] }
        var points: [LogTimelinePoint] = []
        var nextID = 0
        for channel in track.channels {
            let label = track.channels.count > 1 ? Self.seriesLabel(for: channel) : track.title
            let bucketSize = max(1, rows.count / buckets)
            var bucketStart = rows.lowerBound
            while bucketStart < rows.upperBound {
                let bucketEnd = min(bucketStart + bucketSize, rows.upperBound)
                var minRow: Int?, maxRow: Int?
                for row in bucketStart..<bucketEnd {
                    guard let value = value(channel, row) else { continue }
                    if minRow.map({ value < self.value(channel, $0)! }) ?? true { minRow = row }
                    if maxRow.map({ value > self.value(channel, $0)! }) ?? true { maxRow = row }
                }
                for row in Set([minRow, maxRow].compactMap { $0 }).sorted() {
                    if let value = value(channel, row) {
                        points.append(LogTimelinePoint(id: nextID, time: log.timestamps[row], value: value, series: label))
                        nextID += 1
                    }
                }
                bucketStart = bucketEnd
            }
        }
        return points
    }

    /// Every channel's value at the sample nearest `time`, numeric and text alike.
    func readings(at time: TimeInterval) -> [LogTimelineReading] {
        guard let row = nearestRow(to: time) else { return [] }
        return log.channels.compactMap { channel in
            guard let text = log.stringValue(channel: channel, row: row), !text.isEmpty else { return nil }
            let display = log.numericValue(channel: channel, row: row).map { Self.format($0) } ?? text
            return LogTimelineReading(channel: channel, value: display, unit: log.unit(for: channel))
        }
    }

    func events(in window: ClosedRange<TimeInterval>) -> [LogEvent] {
        events.filter { window.contains($0.timestamp) }
    }

    /// The event closest to `time` within `tolerance` seconds.
    func nearestEvent(to time: TimeInterval, tolerance: TimeInterval = 0.5) -> LogEvent? {
        events.filter { abs($0.timestamp - time) <= tolerance }.min { abs($0.timestamp - time) < abs($1.timestamp - time) }
    }

    func nearestRow(to time: TimeInterval) -> Int? {
        let timestamps = log.timestamps
        guard !timestamps.isEmpty else { return nil }
        var low = 0, high = timestamps.count - 1
        while low < high {
            let mid = (low + high) / 2
            if timestamps[mid] < time { low = mid + 1 } else { high = mid }
        }
        if low > 0, abs(timestamps[low - 1] - time) < abs(timestamps[low] - time) { return low - 1 }
        return low
    }

    private func rowRange(for window: ClosedRange<TimeInterval>) -> Range<Int> {
        guard let first = nearestRow(to: window.lowerBound), let last = nearestRow(to: window.upperBound) else { return 0..<0 }
        return first..<(last + 1)
    }

    private func value(_ channel: String, _ row: Int) -> Double? { log.numericValue(channel: channel, row: row) }

    private static func seriesLabel(for channel: String) -> String {
        switch ChannelResolver.canonicalChannel(for: channel) {
        case .lambdaCommanded: "Commanded"
        case .lambdaMeasured: "Bank 1"
        case .lambdaMeasuredBank2: "Bank 2"
        case .acceleratorPedal: "Pedal"
        case .throttleActual: "Throttle"
        default: channel
        }
    }

    private static func format(_ value: Double) -> String {
        abs(value) >= 100 ? String(format: "%.0f", value) : String(format: "%.3g", value)
    }
}

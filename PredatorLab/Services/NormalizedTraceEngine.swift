import Foundation

struct NormalizedTracePoint: Identifiable, Equatable {
    var id: String { "\(channel.rawValue):\(relativeTime)" }
    let channel: CanonicalChannel
    let relativeTime: TimeInterval
    let value: Double
}

struct NormalizedEventTrace: Identifiable, Equatable {
    let id: UUID
    let eventID: UUID
    let buildStateID: UUID?
    let points: [NormalizedTracePoint]
}

enum NormalizedTraceEngine {
    /// Re-centers selected numeric channels around event onset (t = 0) without interpolation.
    static func make(log: ParsedLogData, event: LogEventEpisode, buildStateID: UUID?, channels: [CanonicalChannel], before: TimeInterval = 2, after: TimeInterval = 2) -> NormalizedEventTrace {
        let lower = event.start - before, upper = event.start + after
        var points: [NormalizedTracePoint] = []
        for channel in channels {
            guard let raw = ChannelResolver.resolve(channel, in: log.channels) else { continue }
            for row in log.samples.indices where log.timestamps.indices.contains(row) {
                let t = log.timestamps[row]
                guard t >= lower, t <= upper, let value = log.numericValue(channel: raw, row: row) else { continue }
                points.append(.init(channel: channel, relativeTime: t - event.start, value: value))
            }
        }
        return .init(id: UUID(), eventID: event.id, buildStateID: buildStateID, points: points)
    }
}

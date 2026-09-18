import Foundation

struct FirstOutItem: Identifiable, Codable, Equatable {
    let id: UUID
    var timestamp: TimeInterval
    var relativeTime: TimeInterval
    var label: String
    var category: String
    var isFirstObserved: Bool
}

enum FirstOutTimelineEngine {
    /// Orders observed episodes around an anchor. Temporal order is evidence, not proof of causation.
    static func build(episodes: [LogEventEpisode], anchor: TimeInterval, window: ClosedRange<TimeInterval>) -> [FirstOutItem] {
        let candidates = episodes.filter { window.contains($0.start) }.sorted { $0.start < $1.start }
        return candidates.enumerated().map { index, ep in
            .init(id:ep.id, timestamp:ep.start, relativeTime:ep.start-anchor, label:ep.eventType, category:ep.severity, isFirstObserved:index == 0)
        }
    }
}

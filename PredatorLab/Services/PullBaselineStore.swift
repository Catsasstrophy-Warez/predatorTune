import Foundation

/// Remembers which imported log is the reference ("baseline") pull for each vehicle build, so
/// new logs on the same build are compared against it automatically.
struct PullBaselineStore {
    private let defaults: UserDefaults
    private static let key = "pullBaselineLogIDs"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func baselineLogID(vehicleID: UUID, buildStateID: UUID?) -> UUID? {
        mapping()[Self.slot(vehicleID, buildStateID)].flatMap(UUID.init(uuidString:))
    }

    func setBaseline(_ logID: UUID?, vehicleID: UUID, buildStateID: UUID?) {
        var current = mapping()
        current[Self.slot(vehicleID, buildStateID)] = logID?.uuidString
        if let data = try? JSONEncoder().encode(current) { defaults.set(data, forKey: Self.key) }
    }

    private func mapping() -> [String: String] {
        guard let data = defaults.data(forKey: Self.key) else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }

    private static func slot(_ vehicleID: UUID, _ buildStateID: UUID?) -> String {
        "\(vehicleID.uuidString)|\(buildStateID?.uuidString ?? "any")"
    }
}

/// Attaches an imported log to the logging session it was recorded in, turning detected
/// events into the session's event cards.
enum SessionLogLinker {
    /// A session is linkable when it has finished, has no log yet, and belongs to the log's vehicle.
    static func canLink(_ session: Session, to log: ImportedLog) -> Bool {
        session.logFileID == nil && session.duration > 0 && session.vehicleID == log.vehicleID
    }

    static func link(_ session: Session, to log: ImportedLog) -> Session {
        var linked = session
        linked.logFileID = log.id
        let cards = log.events.map { event in
            EventCard(
                timestamp: event.timestamp,
                eventType: event.eventType,
                title: title(for: event.eventType),
                description: event.description,
                severity: event.severity,
                channelSnapshot: event.channelValues,
                sourceStates: event.sourceStates,
                tags: ["from-log"]
            )
        }
        // Keep cards the user added by hand during the session; add the log's detections.
        linked.eventCards = session.eventCards + cards
        linked.lastModified = .now
        return linked
    }

    static func title(for eventType: String) -> String {
        switch eventType {
        case "protection": "Fuel-flow protection"
        case "knock": "Knock retard"
        case "lambda_deviation": "Lambda off command"
        case "fuel_pressure": "Fuel pressure tracking"
        case "throttle_closure": "Throttle closure"
        case "shift": "Gear change"
        case "misfire": "Misfire"
        case "source_state_change": "Controller limit"
        default: eventType.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Starts, updates and ends the logging-session Live Activity. Activities are looked up and
/// mutated inside detached tasks so no ActivityKit object crosses an actor boundary.
enum LoggingActivityController {
    static func start(vehicleName: String, mode: String, startDate: Date) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else { return }
        Task.detached(priority: .userInitiated) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            for activity in Activity<LoggingActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            let attributes = LoggingActivityAttributes(vehicleName: vehicleName, mode: mode, startDate: startDate)
            let content = ActivityContent(state: LoggingActivityAttributes.ContentState(eventCount: 0, lastEvent: nil), staleDate: nil)
            _ = try? Activity.request(attributes: attributes, content: content, pushType: nil)
        }
        #endif
    }

    static func update(eventCount: Int, lastEvent: String?) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else { return }
        Task.detached(priority: .utility) {
            let content = ActivityContent(state: LoggingActivityAttributes.ContentState(eventCount: eventCount, lastEvent: lastEvent), staleDate: nil)
            for activity in Activity<LoggingActivityAttributes>.activities {
                await activity.update(content)
            }
        }
        #endif
    }

    static func end() {
        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else { return }
        Task.detached(priority: .userInitiated) {
            for activity in Activity<LoggingActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        #endif
    }
}

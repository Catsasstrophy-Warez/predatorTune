import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// Live Activity for a Garage logging session. Compiled into both the app (which starts and
/// updates it) and the PredatorLabWidgets extension (which renders it).
@available(iOS 16.1, *)
struct LoggingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var eventCount: Int
        var lastEvent: String?
    }

    var vehicleName: String
    var mode: String
    var startDate: Date
}
#endif

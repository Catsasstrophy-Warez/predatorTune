import ActivityKit
import SwiftUI
import WidgetKit

@main
struct PredatorLabWidgetBundle: WidgetBundle {
    var body: some Widget {
        LoggingLiveActivity()
    }
}

/// Lock Screen and Dynamic Island presentation of a running logging session.
struct LoggingLiveActivity: Widget {
    private let ignition = Color(red: 1.0, green: 0.42, blue: 0.05)
    private let critical = Color(red: 0.96, green: 0.26, blue: 0.30)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LoggingActivityAttributes.self) { context in
            HStack(spacing: 14) {
                Image(systemName: "record.circle.fill")
                    .font(.title2)
                    .foregroundStyle(critical)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.vehicleName).font(.headline)
                    Text(context.attributes.mode).font(.caption).foregroundStyle(.secondary)
                    if let last = context.state.lastEvent {
                        Text(last).font(.caption).foregroundStyle(ignition).lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.attributes.startDate, style: .timer)
                        .font(.system(.title2, design: .monospaced).weight(.bold))
                        .multilineTextAlignment(.trailing)
                    Text("\(context.state.eventCount) events").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(ignition)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.mode, systemImage: "record.circle.fill")
                        .foregroundStyle(critical)
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.startDate, style: .timer)
                        .font(.system(.body, design: .monospaced).weight(.bold))
                        .multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.lastEvent ?? "\(context.state.eventCount) events so far")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "record.circle.fill").foregroundStyle(critical)
            } compactTrailing: {
                Text(context.attributes.startDate, style: .timer)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "record.circle.fill").foregroundStyle(critical)
            }
        }
    }
}

// PredatorLab/Views/Components/EventTimeline.swift
// Reusable horizontal timeline strip with tappable severity-colored markers.
// Used by AnalysisModeView for both session EventCards and imported-log LogEvents.

import SwiftUI

struct TimelineMarker: Identifiable {
    let id: UUID
    let timestamp: TimeInterval
    let severity: String
    let label: String
}

struct TimelineEvidenceBand: Identifiable {
    let id: String
    let range: ClosedRange<TimeInterval>
    let label: String
    let authority: String
}

struct EventTimelineView: View {
    let markers: [TimelineMarker]
    let duration: TimeInterval
    var evidenceBands: [TimelineEvidenceBand] = []
    var cursorTime: TimeInterval? = nil
    let onSelect: (UUID) -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(evidenceBands) { band in
                    let start = duration > 0 ? min(max(band.range.lowerBound / duration, 0), 1) : 0
                    let end = duration > 0 ? min(max(band.range.upperBound / duration, 0), 1) : 0
                    Rectangle().fill(Color.plBoost.opacity(0.12)).frame(width: geo.size.width * CGFloat(max(0,end-start)), height: 34).offset(x: geo.size.width * CGFloat(start), y: 4).accessibilityLabel("\(band.label), \(band.authority)")
                }
                if let cursorTime {
                    let f = duration > 0 ? min(max(cursorTime / duration,0),1) : 0
                    Rectangle().fill(Color.primary.opacity(0.7)).frame(width:1,height:38).offset(x:geo.size.width * CGFloat(f),y:2)
                }
                Rectangle()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(height: 3)
                    .offset(y: 20)

                ForEach(markers) { marker in
                    let fraction = duration > 0 ? marker.timestamp / duration : 0
                    let x = geo.size.width * CGFloat(min(max(fraction, 0), 1))

                    Button {
                        onSelect(marker.id)
                    } label: {
                        Circle()
                            .fill(SeverityColor.color(for: marker.severity))
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(.white, lineWidth: 1.5))
                    }
                    .position(x: x, y: 21)
                    .accessibilityLabel(marker.label)
                }
            }
        }
        .frame(height: 44)
    }
}

struct SeverityDot: View {
    let severity: String

    var body: some View {
        Circle()
            .fill(SeverityColor.color(for: severity))
            .frame(width: 10, height: 10)
    }
}

enum SeverityColor {
    static func plColor(for severity: String) -> Color { color(for: severity) }
    static func badgeText(for severity: String) -> String { severity.uppercased() }
    static func color(for severity: String) -> Color {
        switch severity {
        case "critical": return .red
        case "warning": return .orange
        default: return .blue
        }
    }
}

/// mm:ss (or hh:mm:ss for long sessions) formatting shared by timeline-adjacent views.
func timelineTimeString(_ interval: TimeInterval) -> String {
    let total = Int(interval)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%d:%02d", minutes, seconds)
}

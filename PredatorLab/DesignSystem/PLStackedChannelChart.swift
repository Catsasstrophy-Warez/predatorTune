// PredatorLab/DesignSystem/PLStackedChannelChart.swift
// A stacked multi-channel strip chart: several time-series channels sharing one timeline
// axis, each in its own compact strip with a color-coded legend showing the channel name
// and its most recent value inline. Modeled on the real HP Tuners VCM telemetry web app's
// live-data view (stacked strips + inline current value beats one crowded overlaid chart
// for scanning several channels at once), adapted to PLTheme.

import SwiftUI
import Charts

struct PLChannelSeries: Identifiable {
    let id = UUID()
    let name: String
    let unit: String
    let color: Color
    let points: [(timestamp: TimeInterval, value: Double)]

    var latestValue: Double? { points.last?.value }
}

struct PLStackedChannelChart: View {
    let series: [PLChannelSeries]
    var stripHeight: CGFloat = 72

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(series) { channel in
                if !channel.points.isEmpty {
                    strip(for: channel)
                }
            }
        }
    }

    @ViewBuilder
    private func strip(for channel: PLChannelSeries) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle().fill(channel.color).frame(width: 8, height: 8)
                Text(channel.name)
                    .font(.plCaption)
                    .foregroundStyle(.plTextSecondary)
                Spacer()
                if let latest = channel.latestValue {
                    Text(formatted(latest) + (channel.unit.isEmpty ? "" : " \(channel.unit)"))
                        .font(.plMono(13))
                        .foregroundStyle(.plTextPrimary)
                }
            }

            Chart(channel.points, id: \.timestamp) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value(channel.name, point.value)
                )
                .foregroundStyle(channel.color)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 1.6))
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 2)) { _ in
                    AxisGridLine().foregroundStyle(Color.plStroke.opacity(0.5))
                    AxisValueLabel().font(.plMono(9)).foregroundStyle(.plTextSecondary)
                }
            }
            .frame(height: stripHeight)
        }
    }

    private func formatted(_ value: Double) -> String {
        abs(value) >= 100 ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }
}

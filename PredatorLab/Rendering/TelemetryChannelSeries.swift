// PredatorLab/Rendering/TelemetryChannelSeries.swift
// Shared numeric time-series type consumed by both the Metal waveform renderer
// and the RealityKit scenes. Bridges from ParsedLogData / ImportedLog without
// duplicating their storage.

import Foundation

struct TelemetryChannelSeries {
    let channelName: String
    let timestamps: [TimeInterval]
    let values: [Double]

    var isEmpty: Bool { values.isEmpty }

    var minValue: Double { values.min() ?? 0 }
    var maxValue: Double { values.max() ?? 0 }
    var duration: TimeInterval { (timestamps.last ?? 0) - (timestamps.first ?? 0) }

    /// Normalizes each sample to 0...1 using the series' own min/max.
    func normalized() -> [Double] {
        let lo = minValue
        let span = maxValue - lo
        guard span > .ulpOfOne else { return values.map { _ in 0.5 } }
        return values.map { ($0 - lo) / span }
    }

    /// Nearest-sample lookup by fractional progress (0...1) through the series.
    func value(atProgress progress: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let clamped = min(max(progress, 0), 1)
        let index = Int((Double(values.count - 1) * clamped).rounded())
        return values[min(max(index, 0), values.count - 1)]
    }
}

enum TelemetryChannelSeriesAdapter {
    /// Extracts a single channel as a dense Double series from a parsed CSV log,
    /// skipping rows where the channel has no numeric value.
    static func extract(channel: String, from log: ParsedLogData) -> TelemetryChannelSeries {
        var timestamps: [TimeInterval] = []
        var values: [Double] = []
        timestamps.reserveCapacity(log.sampleCount)
        values.reserveCapacity(log.sampleCount)

        for row in 0..<log.sampleCount {
            guard let value = log.numericValue(channel: channel, row: row) else { continue }
            let timestamp = log.timestamps.indices.contains(row) ? log.timestamps[row] : Double(row)
            timestamps.append(timestamp)
            values.append(value)
        }

        return TelemetryChannelSeries(channelName: channel, timestamps: timestamps, values: values)
    }

    /// Deterministic placeholder series for previews and the empty-state (no log imported yet).
    static func demoSeries(channelName: String, amplitude: Double, sampleCount: Int = 240) -> TelemetryChannelSeries {
        var timestamps: [TimeInterval] = []
        var values: [Double] = []
        timestamps.reserveCapacity(sampleCount)
        values.reserveCapacity(sampleCount)

        for i in 0..<sampleCount {
            let t = Double(i) * 0.05
            let value = amplitude * 0.5 * (1 + sin(t * 1.7) * 0.6 + sin(t * 0.31) * 0.4)
            timestamps.append(t)
            values.append(value)
        }

        return TelemetryChannelSeries(channelName: channelName, timestamps: timestamps, values: values)
    }
}

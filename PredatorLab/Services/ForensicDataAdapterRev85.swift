import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct ForensicSeriesRev85: Identifiable, Sendable {
    let id: String
    let descriptor: ForensicChannelDescriptorRev85
    let samples: [ForensicTimelineSampleRev85]
    let sourceLogID: UUID
    let sourceSHA256: String?
}

struct ForensicSessionDatasetRev85 {
    let log: ImportedLog
    let series: [ForensicSeriesRev85]
    let events: [LogEvent]
}

enum ForensicDataAdapterRev85 {
    /// CSV names are observations, not certified Parameter IDs. Unit extraction is syntactic only.
    static func adapt(log: ImportedLog, dataset: ParsedLogData) -> ForensicSessionDatasetRev85 {
        let count = min(dataset.timestamps.count, dataset.samples.count)
        let series = dataset.channels.compactMap { channel -> ForensicSeriesRev85? in
            let points = (0..<count).compactMap { row -> ForensicTimelineSampleRev85? in
                guard let value = dataset.numericValue(channel: channel, row: row) else { return nil }
                return .init(time: dataset.timestamps[row], value: value)
            }
            guard !points.isEmpty else { return nil }
            let parsed = splitDisplayNameAndUnit(channel)
            return .init(
                id: "\(log.id.uuidString):\(channel)",
                descriptor: .init(id: channel, displayName: parsed.name, unit: parsed.unit, semanticState: .observed),
                samples: points,
                sourceLogID: log.id,
                sourceSHA256: log.sourceSHA256
            )
        }
        return .init(log: log, series: series, events: log.events)
    }

    static func nearestSample(in series: ForensicSeriesRev85, time: TimeInterval) -> ForensicTimelineSampleRev85? {
        series.samples.min { abs($0.time - time) < abs($1.time - time) }
    }

    static func nearestRPM(in session: ForensicSessionDatasetRev85, time: TimeInterval) -> Double? {
        guard let rpm = session.series.first(where: { $0.descriptor.displayName.lowercased().contains("rpm") || $0.descriptor.id.lowercased().contains("engine speed") }) else { return nil }
        return nearestSample(in: rpm, time: time)?.value
    }

    private static func splitDisplayNameAndUnit(_ raw: String) -> (name: String, unit: String?) {
        guard let open = raw.lastIndex(of: "["), raw.hasSuffix("]"), open > raw.startIndex else { return (raw, nil) }
        let name = raw[..<open].trimmingCharacters(in: .whitespaces)
        let unitStart = raw.index(after: open); let unitEnd = raw.index(before: raw.endIndex)
        let unit = String(raw[unitStart..<unitEnd]).trimmingCharacters(in: .whitespaces)
        return (name.isEmpty ? raw : name, unit.isEmpty ? nil : unit)
    }
}

struct GhostPullPairRev85 {
    let active: ForensicSessionDatasetRev85
    let baseline: ForensicSessionDatasetRev85
    /// Time is the primary admitted synchronization axis. RPM matching is optional and only available when both datasets expose observed RPM.
    func synchronizedTimes(activeTime: TimeInterval) -> (active: TimeInterval, baseline: TimeInterval) {
        guard let activeRPM = ForensicDataAdapterRev85.nearestRPM(in: active, time: activeTime),
              let baselineRPMSeries = baseline.series.first(where: { $0.descriptor.displayName.lowercased().contains("rpm") || $0.descriptor.id.lowercased().contains("engine speed") }),
              let match = baselineRPMSeries.samples.min(by: { abs($0.value-activeRPM) < abs($1.value-activeRPM) }) else {
            return (activeTime, activeTime)
        }
        return (activeTime, match.time)
    }
}

import Foundation

struct CursorMeasurement: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let value: String
    let canonicalChannel: CanonicalChannel?
}

struct ForensicCursorSnapshot: Equatable {
    let requestedTime: TimeInterval
    let sampleTime: TimeInterval
    let measurements: [CursorMeasurement]
}

enum ForensicCursorEngine {
    static func snapshot(log: ParsedLogData, at time: TimeInterval, shiftEpisodes: [LogEventEpisode] = []) -> ForensicCursorSnapshot? {
        guard !log.timestamps.isEmpty,
              let row = log.timestamps.indices.min(by: { abs(log.timestamps[$0] - time) < abs(log.timestamps[$1] - time) }) else { return nil }
        let derived = log.derivedEngineeringSamples()
        func number(_ channel: CanonicalChannel, decimals: Int = 2, suffix: String = "") -> String? {
            guard let raw = ChannelResolver.resolve(channel, in: log.channels), let v = log.numericValue(channel: raw, row: row) else { return nil }
            return String(format: "%.*f%@", decimals, v, suffix)
        }
        func text(_ channel: CanonicalChannel) -> String? {
            guard let raw = ChannelResolver.resolve(channel, in: log.channels) else { return nil }
            return log.stringValue(channel: raw, row: row)
        }
        var m: [CursorMeasurement] = []
        if let v = number(.engineRPM, decimals: 0, suffix: " rpm") { m.append(.init(label: "RPM", value: v, canonicalChannel: .engineRPM)) }
        if let v = text(.gearActual) ?? number(.gearActual, decimals: 0) { m.append(.init(label: "Gear", value: v, canonicalChannel: .gearActual)) }
        if let v = number(.injectorPulseWidth, suffix: " ms") { m.append(.init(label: "Actual PW", value: v, canonicalChannel: .injectorPulseWidth)) }
        if let v = number(.maximumInjectorPulseWidth, suffix: " ms") { m.append(.init(label: "Maximum PW", value: v, canonicalChannel: .maximumInjectorPulseWidth)) }
        if derived.indices.contains(row), let v = derived[row].injectorPulseWidthMargin { m.append(.init(label: "PW Margin", value: String(format: "%.2f ms", v), canonicalChannel: .maximumInjectorPulseWidth)) }
        if let v = number(.fuelPressureCommanded, suffix: " psi") { m.append(.init(label: "Fuel P Cmd", value: v, canonicalChannel: .fuelPressureCommanded)) }
        if let v = number(.fuelPressureActual, suffix: " psi") { m.append(.init(label: "Fuel P Actual", value: v, canonicalChannel: .fuelPressureActual)) }
        if derived.indices.contains(row), let v = derived[row].fuelPressureError { m.append(.init(label: "Pressure Error", value: String(format: "%+.2f psi", v), canonicalChannel: .fuelPressureActual)) }
        if let v = number(.lambdaCommanded, decimals: 3) { m.append(.init(label: "Lambda Cmd", value: v, canonicalChannel: .lambdaCommanded)) }
        if let v = number(.lambdaMeasured, decimals: 3) { m.append(.init(label: "Lambda Actual", value: v, canonicalChannel: .lambdaMeasured)) }
        if derived.indices.contains(row), let v = derived[row].lambdaError { m.append(.init(label: "Lambda Error", value: String(format: "%+.3f", v), canonicalChannel: .lambdaMeasured)) }
        if let v = number(.throttleCommanded, suffix: "°") { m.append(.init(label: "Throttle Cmd", value: v, canonicalChannel: .throttleCommanded)) }
        if let v = number(.throttleActual, suffix: "°") { m.append(.init(label: "Throttle Actual", value: v, canonicalChannel: .throttleActual)) }
        if let v = text(.torqueProtectionSource) { m.append(.init(label: "Protection", value: v, canonicalChannel: .torqueProtectionSource)) }
        if let v = text(.sparkSource) { m.append(.init(label: "Spark Source", value: v, canonicalChannel: .sparkSource)) }
        if let shift = shiftEpisodes.min(by: { abs($0.start - log.timestamps[row]) < abs($1.start - log.timestamps[row]) }) {
            m.append(.init(label: "From Shift Onset", value: String(format: "%+.3f s", log.timestamps[row] - shift.start), canonicalChannel: .gearActual))
        }
        return .init(requestedTime: time, sampleTime: log.timestamps[row], measurements: m)
    }
}

struct EvidenceDelta: Identifiable, Equatable {
    let id = UUID(); let label: String; let baseline: Double?; let comparison: Double?; let unit: String
    var delta: Double? { guard let baseline, let comparison else { return nil }; return comparison - baseline }
}

struct EventComparisonResult: Equatable {
    let deltas: [EvidenceDelta]
    let summary: [String]
}

enum ForensicComparisonEngine {
    static func compare(baseline: DiagnosticEvidencePackage, against comparison: DiagnosticEvidencePackage) -> EventComparisonResult {
        func value(_ key: String, in package: DiagnosticEvidencePackage) -> Double? { package.observations.first { $0.key == key }?.value }
        let definitions = [("PW Margin", "pw_margin_min", "ms"), ("Peak Pressure Error", "pressure_error_peak", "psi"), ("Peak Lambda Error", "lambda_error_peak", "λ"), ("Peak Throttle Error", "throttle_error_peak", "deg"), ("Event Duration", "episode_duration", "s"), ("Shift Proximity", "nearest_shift_delta", "s")]
        let deltas = definitions.map { EvidenceDelta(label: $0.0, baseline: value($0.1, in: baseline), comparison: value($0.1, in: comparison), unit: $0.2) }
        var summary: [String] = []
        if let d = deltas.first(where: { $0.label == "PW Margin" })?.delta { summary.append(d > 0 ? "Injector PW margin improved by \(String(format: "%.2f", d)) ms." : "Injector PW margin decreased by \(String(format: "%.2f", abs(d))) ms.") }
        if let d = deltas.first(where: { $0.label == "Peak Pressure Error" })?.delta { summary.append(d < 0 ? "Peak fuel-pressure tracking error improved by \(String(format: "%.2f", abs(d))) psi." : "Peak fuel-pressure tracking error increased by \(String(format: "%.2f", d)) psi.") }
        if comparison.episode.eventType != baseline.episode.eventType { summary.append("Comparison event type differs from the baseline; interpret deltas cautiously.") }
        return .init(deltas: deltas, summary: summary)
    }
}

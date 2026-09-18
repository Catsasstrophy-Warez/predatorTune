import Foundation

struct DiagnosticObservation: Identifiable, Codable, Equatable {
    let id: UUID
    let key: String
    let statement: String
    let value: Double?
    let unit: String?
    let timestamp: TimeInterval?
    let level: EvidenceLevel

    init(id: UUID = UUID(), key: String, statement: String, value: Double? = nil, unit: String? = nil, timestamp: TimeInterval? = nil, level: EvidenceLevel = .observed) {
        self.id = id; self.key = key; self.statement = statement; self.value = value; self.unit = unit; self.timestamp = timestamp; self.level = level
    }
}

struct DiagnosticEvidencePackage: Identifiable, Codable {
    let id: UUID
    let logID: UUID?
    let buildStateID: UUID?
    let episode: LogEventEpisode
    let flightRecord: FlightRecord
    let observations: [DiagnosticObservation]
    let acquisitionWarnings: [String]

    init(id: UUID = UUID(), logID: UUID? = nil, buildStateID: UUID? = nil, episode: LogEventEpisode, flightRecord: FlightRecord, observations: [DiagnosticObservation], acquisitionWarnings: [String]) {
        self.id = id; self.logID = logID; self.buildStateID = buildStateID; self.episode = episode; self.flightRecord = flightRecord; self.observations = observations; self.acquisitionWarnings = acquisitionWarnings
    }
}

enum EvidenceExtractionEngine {
    static func package(log: ParsedLogData, episode: LogEventEpisode, logID: UUID? = nil, buildStateID: UUID? = nil) -> DiagnosticEvidencePackage {
        let record = FlightRecorderEngine.capture(logData: log, episode: episode)
        let quality = AcquisitionQualityEngine.analyze(log)
        let derived = log.derivedEngineeringSamples().filter { $0.timestamp >= record.windowStart && $0.timestamp <= record.windowEnd }
        var observations: [DiagnosticObservation] = []

        func extrema(_ values: [(TimeInterval, Double?)], key: String, label: String, unit: String, chooseMax: Bool) {
            let valid = values.compactMap { time, value in value.map { (time, $0) } }
            guard let selected = (chooseMax ? valid.max(by: { $0.1 < $1.1 }) : valid.min(by: { $0.1 < $1.1 })) else { return }
            observations.append(DiagnosticObservation(key: key, statement: "\(label): \(String(format: "%.3f", selected.1)) \(unit) at \(String(format: "%.3f", selected.0)) s.", value: selected.1, unit: unit, timestamp: selected.0))
        }

        extrema(derived.map { ($0.timestamp, $0.injectorPulseWidthMargin) }, key: "pw_margin_min", label: "Minimum injector PW margin", unit: "ms", chooseMax: false)
        extrema(derived.map { ($0.timestamp, $0.fuelPressureError.map(abs)) }, key: "pressure_error_peak", label: "Peak absolute fuel-pressure error", unit: "psi", chooseMax: true)
        extrema(derived.map { ($0.timestamp, $0.lambdaError.map(abs)) }, key: "lambda_error_peak", label: "Peak absolute lambda error", unit: "λ", chooseMax: true)
        extrema(derived.map { ($0.timestamp, $0.throttleError.map(abs)) }, key: "throttle_error_peak", label: "Peak absolute throttle error", unit: "deg", chooseMax: true)

        let allEpisodes = LogEventDetector.detectAllEpisodes(logData: log)
        if let nearestShift = allEpisodes.filter({ $0.eventType == "shift" }).min(by: { abs($0.start - episode.start) < abs($1.start - episode.start) }) {
            let delta = abs(nearestShift.start - episode.start)
            observations.append(DiagnosticObservation(key: "nearest_shift_delta", statement: "Nearest detected shift episode began \(String(format: "%.3f", delta)) s from event onset.", value: delta, unit: "s", timestamp: nearestShift.start))
        }
        if let rpmName = ChannelResolver.resolve(.engineRPM, in: log.channels), let row = log.timestamps.enumerated().min(by: { abs($0.element - episode.start) < abs($1.element - episode.start) })?.offset, let rpm = log.numericValue(channel: rpmName, row: row) {
            observations.append(DiagnosticObservation(key: "rpm_at_onset", statement: "Engine speed at event onset: \(Int(rpm.rounded())) rpm.", value: rpm, unit: "rpm", timestamp: episode.start))
        }
        if let iatName = ChannelResolver.resolve(.iat2, in: log.channels), let row = log.timestamps.enumerated().min(by: { abs($0.element - episode.peak) < abs($1.element - episode.peak) })?.offset, let iat = log.numericValue(channel: iatName, row: row) {
            observations.append(DiagnosticObservation(key: "iat2_at_peak", statement: "IAT2 at event peak: \(String(format: "%.1f", iat)).", value: iat, unit: nil, timestamp: episode.peak))
        }

        observations.append(DiagnosticObservation(key: "episode_duration", statement: "\(episode.description) lasted \(String(format: "%.3f", episode.duration)) s across \(episode.sampleCount) qualifying samples.", value: episode.duration, unit: "s", timestamp: episode.peak))
        return DiagnosticEvidencePackage(logID: logID, buildStateID: buildStateID, episode: episode, flightRecord: record, observations: observations, acquisitionWarnings: quality.warnings)
    }
}

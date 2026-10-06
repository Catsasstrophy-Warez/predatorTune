import Foundation

/// One high-demand run ("pull") and what the engine did during it. Every value is measured
/// from logged channels; anything the log doesn't carry is nil, never estimated.
struct PullReport: Identifiable, Equatable, Sendable {
    struct RPMBin: Identifiable, Equatable, Sendable {
        var id: Int { rpmFloor }
        let rpmFloor: Int
        let samples: Int
        let lambdaCommanded: Double?
        let lambdaBank1: Double?
        let lambdaBank2: Double?
        let torqueRequested: Double?
        let torqueDelivered: Double?
        let timingAdvance: Double?
    }

    var id: Double { start }
    let start: TimeInterval
    let end: TimeInterval
    let rpmStart: Double?
    let rpmEnd: Double?
    let peakPedal: Double?
    let peakManifoldPressure: Double?
    /// MAP minus barometric pressure, when both are logged.
    let peakBoost: Double?
    let pressureUnit: String?
    let maxKnockRetard: Double
    /// Peak retard per cylinder (positive degrees). Empty when per-cylinder knock isn't logged.
    let knockByCylinder: [Int: Double]
    let maxLambdaError: Double?
    let meanBankSplit: Double?
    let fuelTrims: [String: Double]
    let iat2Start: Double?
    let iat2End: Double?
    let temperatureUnit: String?
    let maxTorqueShortfall: Double?
    let torqueUnit: String?
    let minFuelPressure: Double?
    let misfires: Int
    let controllerLimits: [String]
    let bins: [RPMBin]

    var duration: TimeInterval { end - start }
    var iat2Rise: Double? { iat2Start.flatMap { start in iat2End.map { $0 - start } } }
}

enum PullAnalyzer {
    static let binWidth = 500
    /// Pedal (or throttle, if no pedal channel) percentage that counts as a demand run.
    static let demandThreshold = 60.0
    static let minimumDuration: TimeInterval = 0.5

    static func analyze(_ log: ParsedLogData) -> [PullReport] {
        let demandChannel = ChannelResolver.resolve(.acceleratorPedal, in: log.channels)
            ?? ChannelResolver.resolve(.throttleActual, in: log.channels)
        guard let demandChannel else { return [] }
        let demand = log.getAlignedNumericChannel(demandChannel)
        let active = demand.map { ($0 ?? 0) >= demandThreshold }
        return LogEventDetector.episodes(in: active, timestamps: log.timestamps, minimumDuration: minimumDuration)
            .map { report(for: $0.first...$0.last, in: log, demand: demand) }
    }

    /// The pull most comparable across logs: the one spanning the widest RPM range.
    static func representativePull(in reports: [PullReport]) -> PullReport? {
        reports.max { span($0) < span($1) }
    }

    private static func span(_ report: PullReport) -> Double {
        (report.rpmEnd ?? 0) - (report.rpmStart ?? 0)
    }

    private static func report(for rows: ClosedRange<Int>, in log: ParsedLogData, demand: [Double?]) -> PullReport {
        func channel(_ role: CanonicalChannel) -> String? { ChannelResolver.resolve(role, in: log.channels) }
        func values(_ role: CanonicalChannel) -> [Double?]? {
            channel(role).map { name in rows.map { log.numericValue(channel: name, row: $0) } }
        }
        func unit(_ role: CanonicalChannel) -> String? { channel(role).flatMap { log.unit(for: $0) } }

        let rpm = values(.engineRPM)
        let map = values(.manifoldPressure)
        let baro = values(.barometricPressure)
        let commanded = values(.lambdaCommanded)
        let bank1 = values(.lambdaMeasured)
        let bank2 = values(.lambdaMeasuredBank2)
        let requested = values(.torqueRequested)
        let delivered = values(.torqueDelivered)
        let timing = values(.timingAdvance)
        let iat2 = values(.iat2)
        let fuelPressure = values(.fuelPressureActual)

        // Knock: overall retard channel plus each cylinder, in positive degrees of retard.
        var knockByCylinder: [Int: Double] = [:]
        for (cylinder, name) in ChannelResolver.cylinderKnockChannels(in: log.channels) {
            let peak = rows.compactMap { log.numericValue(channel: name, row: $0) }
                .map { ChannelResolver.knockRetardDegrees($0, channelName: name) }.max() ?? 0
            knockByCylinder[cylinder] = peak
        }
        let overallKnock = channel(.knockRetard).map { name in
            rows.compactMap { log.numericValue(channel: name, row: $0) }
                .map { ChannelResolver.knockRetardDegrees($0, channelName: name) }.max() ?? 0
        } ?? 0

        let lambdaErrors: [Double] = zip(commanded ?? [], bank1 ?? []).compactMap { c, m in
            guard let c, let m, m < 1.5 else { return nil }
            return abs(m - c)
        }
        let bankSplits: [Double] = zip(bank1 ?? [], bank2 ?? []).compactMap { a, b in
            guard let a, let b, a < 1.5, b < 1.5 else { return nil }
            return abs(a - b)
        }
        let shortfalls: [Double] = zip(requested ?? [], delivered ?? []).compactMap { r, d in
            guard let r, let d else { return nil }
            return r - d
        }
        let boost: [Double] = zip(map ?? [], baro ?? []).compactMap { m, b in
            guard let m, let b else { return nil }
            return m - b
        }

        var trims: [String: Double] = [:]
        for (label, role) in [("STFT B1", CanonicalChannel.fuelTrimShortTerm1), ("LTFT B1", .fuelTrimLongTerm1),
                              ("STFT B2", .fuelTrimShortTerm2), ("LTFT B2", .fuelTrimLongTerm2)] {
            if let mean = mean(values(role)) { trims[label] = mean }
        }

        var limits: [String] = []
        for name in log.channels where ChannelResolver.normalize(name).hasSuffix("source") {
            for row in rows {
                if let state = log.stringValue(channel: name, row: row), isLimitingState(state), !limits.contains(state) {
                    limits.append(state)
                }
            }
        }

        let misfires: Int = channel(.misfireCount).map { name in
            let counts = rows.compactMap { log.numericValue(channel: name, row: $0) }
            guard let first = counts.first, let last = counts.last else { return 0 }
            return max(0, Int(last.rounded(.down)) - Int(first.rounded(.down)))
        } ?? 0

        return PullReport(
            start: log.timestamps[rows.lowerBound],
            end: log.timestamps[rows.upperBound],
            rpmStart: rpm?.first ?? nil,
            rpmEnd: rpm?.compactMap { $0 }.max(),
            peakPedal: rows.compactMap { demand[$0] }.max(),
            peakManifoldPressure: map?.compactMap { $0 }.max(),
            peakBoost: boost.max(),
            pressureUnit: unit(.manifoldPressure),
            maxKnockRetard: max(overallKnock, knockByCylinder.values.max() ?? 0),
            knockByCylinder: knockByCylinder,
            maxLambdaError: lambdaErrors.max(),
            meanBankSplit: bankSplits.isEmpty ? nil : bankSplits.reduce(0, +) / Double(bankSplits.count),
            fuelTrims: trims,
            iat2Start: iat2?.first ?? nil,
            iat2End: iat2?.last ?? nil,
            temperatureUnit: unit(.iat2),
            maxTorqueShortfall: shortfalls.max(),
            torqueUnit: unit(.torqueDelivered),
            minFuelPressure: fuelPressure?.compactMap { $0 }.min(),
            misfires: misfires,
            controllerLimits: limits,
            bins: bins(rows: rows, rpm: rpm, commanded: commanded, bank1: bank1, bank2: bank2,
                       requested: requested, delivered: delivered, timing: timing)
        )
    }

    private static func bins(rows: ClosedRange<Int>, rpm: [Double?]?, commanded: [Double?]?, bank1: [Double?]?, bank2: [Double?]?,
                             requested: [Double?]?, delivered: [Double?]?, timing: [Double?]?) -> [PullReport.RPMBin] {
        guard let rpm else { return [] }
        var grouped: [Int: [Int]] = [:]
        for (offset, value) in rpm.enumerated() {
            guard let value else { continue }
            grouped[Int(value) / binWidth * binWidth, default: []].append(offset)
        }
        func average(_ series: [Double?]?, _ offsets: [Int], lambda: Bool = false) -> Double? {
            guard let series else { return nil }
            let picked = offsets.compactMap { series[$0] }.filter { !lambda || $0 < 1.5 }
            return picked.isEmpty ? nil : picked.reduce(0, +) / Double(picked.count)
        }
        return grouped.keys.sorted().map { floor in
            let offsets = grouped[floor] ?? []
            return PullReport.RPMBin(
                rpmFloor: floor, samples: offsets.count,
                lambdaCommanded: average(commanded, offsets, lambda: true),
                lambdaBank1: average(bank1, offsets, lambda: true),
                lambdaBank2: average(bank2, offsets, lambda: true),
                torqueRequested: average(requested, offsets),
                torqueDelivered: average(delivered, offsets),
                timingAdvance: average(timing, offsets)
            )
        }
    }

    private static func mean(_ series: [Double?]?) -> Double? {
        guard let picked = series?.compactMap({ $0 }), !picked.isEmpty else { return nil }
        return picked.reduce(0, +) / Double(picked.count)
    }

    /// Controller states that mean torque, spark or airflow is being limited.
    private static func isLimitingState(_ state: String) -> Bool {
        let lowered = state.lowercased()
        let routine = ["no limit active", "base / mbt", "torque control", "driver demand", "idle control",
                       "alt full load", "full load", "in gear limit overspeed", "neutral limit", "anticlunk tipin tq lmt."]
        if routine.contains(lowered) || lowered.isEmpty { return false }
        return ["limit", "protection", "borderline", "detonation", "insufficient", "red."].contains { lowered.contains($0) }
    }
}

/// Side-by-side deltas between two pulls (current minus baseline), with lambda and torque
/// compared bin by bin over the RPM range both pulls cover.
struct PullComparison: Equatable, Sendable {
    struct BinDelta: Identifiable, Equatable, Sendable {
        var id: Int { rpmFloor }
        let rpmFloor: Int
        let lambdaBank1Delta: Double?
        let torqueDeliveredDelta: Double?
        let timingDelta: Double?
    }

    let current: PullReport
    let baseline: PullReport
    let peakBoostDelta: Double?
    let maxKnockDelta: Double
    let iat2RiseDelta: Double?
    let maxLambdaErrorDelta: Double?
    let bins: [BinDelta]

    init(current: PullReport, baseline: PullReport) {
        self.current = current
        self.baseline = baseline
        func delta(_ a: Double?, _ b: Double?) -> Double? { a.flatMap { a in b.map { a - $0 } } }
        peakBoostDelta = delta(current.peakBoost, baseline.peakBoost)
        maxKnockDelta = current.maxKnockRetard - baseline.maxKnockRetard
        iat2RiseDelta = delta(current.iat2Rise, baseline.iat2Rise)
        maxLambdaErrorDelta = delta(current.maxLambdaError, baseline.maxLambdaError)
        let baselineBins = Dictionary(uniqueKeysWithValues: baseline.bins.map { ($0.rpmFloor, $0) })
        bins = current.bins.compactMap { bin in
            guard let other = baselineBins[bin.rpmFloor] else { return nil }
            return BinDelta(rpmFloor: bin.rpmFloor,
                            lambdaBank1Delta: delta(bin.lambdaBank1, other.lambdaBank1),
                            torqueDeliveredDelta: delta(bin.torqueDelivered, other.torqueDelivered),
                            timingDelta: delta(bin.timingAdvance, other.timingAdvance))
        }
    }
}

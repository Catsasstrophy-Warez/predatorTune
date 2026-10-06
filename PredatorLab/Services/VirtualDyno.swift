import Foundation

/// Physical assumptions behind a road-dyno estimate. Every value is shown with the result.
struct DynoAssumptions: Equatable, Sendable {
    /// Car + driver + fuel, in kg.
    var massKg: Double
    /// Drag coefficient × frontal area, m². GT500 ≈ 0.39 × 2.2.
    var dragArea: Double = 0.86
    var rollingResistance: Double = 0.015
    /// kg/m³ at sea level, 15 °C.
    var airDensity: Double = 1.225

    static let gt500CurbWeightLb = 4_171
    static let defaultTestWeightLb = 4_350

    init(testWeightLb: Int?) {
        massKg = Double(testWeightLb ?? Self.defaultTestWeightLb) * 0.453_592
    }
}

struct DynoPoint: Identifiable, Equatable, Sendable {
    var id: Int { rpm }
    let rpm: Int
    let wheelHorsepower: Double
    /// Wheel power expressed as torque at engine speed (lb·ft), so it lines up with the RPM axis.
    let wheelTorque: Double
}

struct DynoResult: Equatable, Sendable {
    let points: [DynoPoint]
    let peakHorsepower: Double
    let peakHorsepowerRPM: Int
    let peakTorque: Double
    let peakTorqueRPM: Int
    let excludedSamples: Int
    let assumptions: DynoAssumptions

    static let caveat = "Road-dyno estimate from acceleration, weight, drag and rolling resistance. Wheel numbers, not crank. Wheelspin, grade, wind and shifts all distort it; compare pulls on the same road and gear."
}

/// Estimates wheel power during a pull from the change in vehicle speed:
/// P = (m·a + ½·ρ·CdA·v² + Crr·m·g) · v.
enum VirtualDyno {
    static let binWidth = 250
    /// Half-width of the regression window used to differentiate speed.
    static let slopeWindow: TimeInterval = 0.2

    static func run(log: ParsedLogData, pull: PullReport, assumptions: DynoAssumptions) -> DynoResult? {
        guard let speedChannel = ChannelResolver.resolve(.vehicleSpeed, in: log.channels),
              let rpmChannel = ChannelResolver.resolve(.engineRPM, in: log.channels) else { return nil }
        let toMetersPerSecond = speedFactor(unit: log.unit(for: speedChannel))
        let rows = log.timestamps.indices.filter { (pull.start...pull.end).contains(log.timestamps[$0]) }
        guard rows.count >= 5 else { return nil }

        var binned: [Int: (power: [Double], torque: [Double])] = [:]
        var excluded = 0
        var previousRPM: Double?
        for row in rows {
            guard let rpm = log.numericValue(channel: rpmChannel, row: row),
                  let speedRaw = log.numericValue(channel: speedChannel, row: row) else { excluded += 1; continue }
            defer { previousRPM = rpm }
            // Falling RPM inside a demand run is a shift or a torque cut, not acceleration in gear.
            if let previousRPM, rpm < previousRPM - 25 { excluded += 1; continue }
            guard let acceleration = slope(around: row, in: log, channel: speedChannel, factor: toMetersPerSecond), acceleration > 0, rpm > 500 else {
                excluded += 1; continue
            }
            let v = speedRaw * toMetersPerSecond
            let m = assumptions.massKg
            let force = m * acceleration + 0.5 * assumptions.airDensity * assumptions.dragArea * v * v + assumptions.rollingResistance * m * 9.806_65
            let watts = force * v
            let torqueNm = watts / (rpm * 2 * .pi / 60)
            let bin = Int(rpm) / binWidth * binWidth
            binned[bin, default: ([], [])].power.append(watts / 745.7)
            binned[bin, default: ([], [])].torque.append(torqueNm * 0.737_562)
        }

        let points = binned.keys.sorted().map { rpm -> DynoPoint in
            let entry = binned[rpm] ?? ([], [])
            return DynoPoint(rpm: rpm, wheelHorsepower: average(entry.power), wheelTorque: average(entry.torque))
        }
        guard let peakHP = points.max(by: { $0.wheelHorsepower < $1.wheelHorsepower }),
              let peakTQ = points.max(by: { $0.wheelTorque < $1.wheelTorque }) else { return nil }
        return DynoResult(points: points, peakHorsepower: peakHP.wheelHorsepower, peakHorsepowerRPM: peakHP.rpm,
                          peakTorque: peakTQ.wheelTorque, peakTorqueRPM: peakTQ.rpm, excludedSamples: excluded, assumptions: assumptions)
    }

    /// Least-squares slope of speed (m/s per s) over ±`slopeWindow` around `row`.
    static func slope(around row: Int, in log: ParsedLogData, channel: String, factor: Double) -> Double? {
        let center = log.timestamps[row]
        var lower = row, upper = row
        while lower > 0, center - log.timestamps[lower - 1] <= slopeWindow { lower -= 1 }
        while upper < log.timestamps.count - 1, log.timestamps[upper + 1] - center <= slopeWindow { upper += 1 }
        var xs: [Double] = [], ys: [Double] = []
        for index in lower...upper {
            guard let value = log.numericValue(channel: channel, row: index) else { continue }
            xs.append(log.timestamps[index] - center); ys.append(value * factor)
        }
        guard xs.count >= 3 else { return nil }
        let meanX = xs.reduce(0, +) / Double(xs.count), meanY = ys.reduce(0, +) / Double(ys.count)
        var numerator = 0.0, denominator = 0.0
        for (x, y) in zip(xs, ys) { numerator += (x - meanX) * (y - meanY); denominator += (x - meanX) * (x - meanX) }
        return denominator > 0 ? numerator / denominator : nil
    }

    static func speedFactor(unit: String?) -> Double {
        switch unit?.lowercased() {
        case "km/h", "kph", "kmh": 1 / 3.6
        case "m/s": 1
        default: 0.447_04 // mph, HP Tuners' default
        }
    }

    private static func average(_ values: [Double]) -> Double {
        values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }
}

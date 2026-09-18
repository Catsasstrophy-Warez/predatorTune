import Foundation

// MARK: - Canonical Channel Identity

enum CanonicalChannel: String, CaseIterable, Codable {
    case time, engineRPM, vehicleSpeed, gearCommanded, gearActual
    case injectorPulseWidth, maximumInjectorPulseWidth
    case fuelPressureCommanded, fuelPressureActual
    case lambdaCommanded, lambdaMeasured, knockRetard
    case throttleCommanded, throttleActual
    case torqueProtectionSource, sparkSource
    case manifoldPressure, boostPressure, iat1, iat2, coolantTemperature
    case timingAdvance, ambientAirTemp, barometricPressure
    case fuelTrimShortTerm1, fuelTrimLongTerm1
    case inferredOctane, borderlineKnock
}

enum ChannelResolver {
    private static let aliases: [CanonicalChannel: [String]] = [
        .time: ["time", "timestamp", "elapsed time", "offset"],
        .engineRPM: ["engine rpm", "rpm"],
        .vehicleSpeed: ["vehicle speed", "speed"],
        .gearCommanded: ["commanded gear", "gear commanded"],
        .gearActual: ["actual gear", "current gear", "gear"],
        .injectorPulseWidth: ["injector pulse width", "injector pw", "inj pw"],
        .maximumInjectorPulseWidth: ["maximum available pulse width", "max injector pulse width", "max injector pw", "maximum pw"],
        .fuelPressureCommanded: ["fuel rail pressure commanded", "fuel pressure commanded", "desired fuel pressure", "frp desired"],
        .fuelPressureActual: ["fuel rail pressure actual", "fuel pressure actual", "fuel rail pressure", "frp actual", "fuel pressure"],
        .lambdaCommanded: ["commanded lambda", "lambda commanded", "lambda cmd", "equivalence ratio commanded"],
        .lambdaMeasured: ["measured lambda", "lambda measured", "wideband lambda", "lambda actual", "wb eq ratio 1", "wb eq ratio 5"],
        .knockRetard: ["knock retard", "kr", "cyl knock retard"],
        .throttleCommanded: ["commanded throttle angle", "throttle commanded", "commanded throttle actuator", "throttle desired angle"],
        .throttleActual: ["actual throttle angle", "throttle position", "throttle actual", "throttle angle"],
        .torqueProtectionSource: ["torque max protection source", "torque max source", "protection source", "fuel cut protection", "torque airlimit source"],
        .sparkSource: ["spark source", "spark source state"],
        .manifoldPressure: ["manifold absolute pressure", "map", "intake manifold absolute pressure"],
        .boostPressure: ["boost pressure", "boost"],
        .iat1: ["intake air temperature", "iat1", "iat", "intake air temp"],
        .iat2: ["charge air temperature", "iat2", "act", "intake air temp 2"],
        .coolantTemperature: ["engine coolant temperature", "ect", "coolant temperature", "engine coolant temp"],
        .timingAdvance: ["timing advance"],
        .ambientAirTemp: ["ambient air temp", "ambient air temperature"],
        .barometricPressure: ["barometric pressure", "baro pressure"],
        .fuelTrimShortTerm1: ["short term fuel trim bank 1", "stft bank 1", "short term fuel trim 1"],
        .fuelTrimLongTerm1: ["long term fuel trim bank 1", "ltft bank 1", "long term fuel trim 1"],
        .inferredOctane: ["inferred octane"],
        .borderlineKnock: ["borderline knock"]
    ]

    static func aliases(for channel: CanonicalChannel) -> [String] { aliases[channel] ?? [] }

    static func canonicalChannel(for rawName: String) -> CanonicalChannel? {
        let normalized = normalize(rawName)
        for (channel, names) in aliases where names.contains(where: { normalize($0) == normalized }) {
            return channel
        }
        return nil
    }

    static func resolve(_ channel: CanonicalChannel, in available: [String]) -> String? {
        if let exact = available.first(where: { canonicalChannel(for: $0) == channel }) { return exact }
        return nil
    }

    private static func normalize(_ value: String) -> String {
        var result = value.lowercased()
        result = result.replacingOccurrences(of: #"\[[^\]]*\]|\([^\)]*\)"#, with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Derived Engineering Signals

struct DerivedEngineeringSample: Codable, Equatable {
    var timestamp: TimeInterval
    var fuelPressureError: Double?
    var lambdaError: Double?
    var injectorPulseWidthMargin: Double?
    var throttleError: Double?
}

extension ParsedLogData {
    func derivedEngineeringSamples() -> [DerivedEngineeringSample] {
        let pressureActual = ChannelResolver.resolve(.fuelPressureActual, in: channels)
        let pressureCommanded = ChannelResolver.resolve(.fuelPressureCommanded, in: channels)
        let lambdaActual = ChannelResolver.resolve(.lambdaMeasured, in: channels)
        let lambdaCommanded = ChannelResolver.resolve(.lambdaCommanded, in: channels)
        let pwActual = ChannelResolver.resolve(.injectorPulseWidth, in: channels)
        let pwMaximum = ChannelResolver.resolve(.maximumInjectorPulseWidth, in: channels)
        let throttleActual = ChannelResolver.resolve(.throttleActual, in: channels)
        let throttleCommanded = ChannelResolver.resolve(.throttleCommanded, in: channels)

        return samples.indices.map { row in
            func value(_ name: String?) -> Double? { name.flatMap { numericValue(channel: $0, row: row) } }
            func delta(_ lhs: String?, _ rhs: String?) -> Double? {
                guard let a = value(lhs), let b = value(rhs) else { return nil }
                return a - b
            }
            return DerivedEngineeringSample(
                timestamp: timestamps.indices.contains(row) ? timestamps[row] : 0,
                fuelPressureError: delta(pressureActual, pressureCommanded),
                lambdaError: delta(lambdaActual, lambdaCommanded),
                injectorPulseWidthMargin: delta(pwMaximum, pwActual),
                throttleError: delta(throttleActual, throttleCommanded)
            )
        }
    }
}

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
    case fuelTrimShortTerm2, fuelTrimLongTerm2
    case acceleratorPedal, torqueRequested, torqueDelivered
    case misfireCount, knockCorrection, lambdaMeasuredBank2
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
        .lambdaMeasured: ["measured lambda", "lambda measured", "wideband lambda", "lambda actual", "wb eq ratio 1", "wb lambda b1", "wb lambda"],
        .lambdaMeasuredBank2: ["wb eq ratio 5", "wb lambda b2", "wideband lambda bank 2"],
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
        .borderlineKnock: ["borderline knock"],
        .fuelTrimShortTerm2: ["short term fuel trim bank 2", "stft bank 2", "short term fuel trim 2"],
        .fuelTrimLongTerm2: ["long term fuel trim bank 2", "ltft bank 2", "long term fuel trim 2"],
        .acceleratorPedal: ["accelerator position d", "accelerator pedal position", "pedal position", "app"],
        .torqueRequested: ["desired brake torque", "driver demand torque", "requested torque"],
        .torqueDelivered: ["engine brake torque", "actual engine torque", "delivered torque"],
        .misfireCount: ["total misfires since key on", "misfire count", "total misfires"],
        .knockCorrection: ["knock correction"]
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

    /// Every raw channel mapping to `channel`; use when several logged channels share a role.
    static func resolveAll(_ channel: CanonicalChannel, in available: [String]) -> [String] {
        available.filter { canonicalChannel(for: $0) == channel }
    }

    /// Per-cylinder knock channels ("Knock Cyl 3 (+Adv/-Ret)", "KR Cyl 3"), sorted by cylinder.
    static func cylinderKnockChannels(in available: [String]) -> [(cylinder: Int, name: String)] {
        available.compactMap { name -> (Int, String)? in
            let normalized = normalize(name)
            for prefix in ["knock cyl ", "kr cyl ", "knock retard cyl ", "cylinder knock "] where normalized.hasPrefix(prefix) {
                if let cylinder = Int(normalized.dropFirst(prefix.count).prefix(while: \.isNumber)) { return (cylinder, name) }
            }
            return nil
        }
        .sorted { $0.0 < $1.0 }
        .map { (cylinder: $0.0, name: $0.1) }
    }

    /// Converts a logged knock value to degrees of retard (positive = retard). HP Tuners Ford
    /// channels marked "+Adv/-Ret" log retard as negative; Ford "Knock Retard" logs it as
    /// non-positive; GM-style KR logs positive retard. All map to a positive magnitude.
    static func knockRetardDegrees(_ value: Double, channelName: String) -> Double {
        if channelName.lowercased().contains("+adv/-ret") { return max(0, -value) }
        return abs(value)
    }

    static func normalize(_ value: String) -> String {
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

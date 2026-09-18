import Foundation

/// Canonical display/conversion vocabulary. Unknown or dimensionally incompatible units stay unknown.
enum EngineeringUnitCatalog {
    static let units: [EngineeringDimension: [String]] = [
        .pressure: ["psi", "kPa", "bar"],
        .temperature: ["°F", "°C"],
        .time: ["s", "ms"],
        .angle: ["deg", "rad"],
        .speed: ["mph", "km/h"],
        .lambda: ["λ"],
        .rpm: ["rpm"],
        .percent: ["%"],
        .voltage: ["V", "mV"],
        .current: ["A", "mA"],
        .resistance: ["Ω", "kΩ"],
        .torque: ["lb-ft", "N·m"],
        .power: ["hp", "kW"],
        .mass: ["lb", "kg"],
        .length: ["in", "mm", "cm", "m"],
        .other: []
    ]

    static func supports(_ unit: String, for dimension: EngineeringDimension) -> Bool {
        units[dimension, default: []].contains { $0.caseInsensitiveCompare(unit) == .orderedSame }
    }

    static func canonicalUnit(_ unit: String, for dimension: EngineeringDimension) -> String? {
        units[dimension, default: []].first { $0.caseInsensitiveCompare(unit) == .orderedSame }
    }
}

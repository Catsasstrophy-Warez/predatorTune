import Foundation

/// Conservative parser for migration only. It recognizes a single scalar plus a known unit.
/// Ranges, inequalities, duty-cycle prose, KOEO/KOER conditions and ambiguous text remain untyped.
enum LegacyEngineeringValueParser {
    static func parse(_ text: String) -> EngineeringValue? {
        let normalized = text.replacingOccurrences(of: "N-m", with: "N·m").replacingOccurrences(of: "Nm", with: "N·m")
        let pattern = #"(?i)^\s*(-?[0-9]+(?:\.[0-9]+)?)\s*(psi|kPa|bar|°F|°C|V|mV|A|mA|Ω|kΩ|ohm|kohm|lb-ft|N·m|hp|kW|lb|kg|in|mm|cm|m|rpm|%|s|ms|deg|rad)\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)),
              let valueRange = Range(match.range(at: 1), in: normalized),
              let unitRange = Range(match.range(at: 2), in: normalized),
              let value = Double(normalized[valueRange]) else { return nil }
        let rawUnit = String(normalized[unitRange])
        guard let pair = dimensionAndUnit(rawUnit) else { return nil }
        return .init(value: value, unit: pair.1, dimension: pair.0, provenance: "Conservatively parsed from legacy authored text; parsing does not verify semantics or applicability.")
    }

    private static func dimensionAndUnit(_ raw: String) -> (EngineeringDimension, String)? {
        let u = raw.lowercased()
        switch u {
        case "psi": return (.pressure,"psi"); case "kpa": return (.pressure,"kPa"); case "bar": return (.pressure,"bar")
        case "°f": return (.temperature,"°F"); case "°c": return (.temperature,"°C")
        case "v": return (.voltage,"V"); case "mv": return (.voltage,"mV")
        case "a": return (.current,"A"); case "ma": return (.current,"mA")
        case "ω","ohm": return (.resistance,"Ω"); case "kω","kohm": return (.resistance,"kΩ")
        case "lb-ft": return (.torque,"lb-ft"); case "n·m": return (.torque,"N·m")
        case "hp": return (.power,"hp"); case "kw": return (.power,"kW")
        case "lb": return (.mass,"lb"); case "kg": return (.mass,"kg")
        case "in": return (.length,"in"); case "mm": return (.length,"mm"); case "cm": return (.length,"cm"); case "m": return (.length,"m")
        case "rpm": return (.rpm,"rpm"); case "%": return (.percent,"%")
        case "s": return (.time,"s"); case "ms": return (.time,"ms"); case "deg": return (.angle,"deg"); case "rad": return (.angle,"rad")
        default: return nil
        }
    }
}

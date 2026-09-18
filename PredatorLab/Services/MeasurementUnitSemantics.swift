import Foundation

struct MeasurementUnitSemantic: Codable, Equatable {
    let channel: CanonicalChannel
    let dimension: EngineeringDimension?
    let canonicalUnit: String?
    let semanticsState: ClaimVerificationState
    let note: String
}

enum MeasurementUnitSemantics {
    static let entries: [MeasurementUnitSemantic] = [
        .init(channel:.engineRPM, dimension:.rpm, canonicalUnit:"rpm", semanticsState:.predatorLabDerived, note:"Canonical display dimension only; scanner PID identity remains source-dependent."),
        .init(channel:.fuelPressureCommanded, dimension:.pressure, canonicalUnit:"psi", semanticsState:.unverified, note:"Do not convert until source channel unit is known."),
        .init(channel:.fuelPressureActual, dimension:.pressure, canonicalUnit:"psi", semanticsState:.unverified, note:"Physical sensor/PID semantics and source unit require verification."),
        .init(channel:.lambdaCommanded, dimension:.lambda, canonicalUnit:"lambda", semanticsState:.predatorLabDerived, note:"Dimensionless canonical representation; source AFR/equivalence transforms must be explicit."),
        .init(channel:.lambdaMeasured, dimension:.lambda, canonicalUnit:"lambda", semanticsState:.predatorLabDerived, note:"Dimensionless canonical representation; source transform must be explicit."),
        .init(channel:.iat2, dimension:.temperature, canonicalUnit:"°F", semanticsState:.unverified, note:"Source unit and sensor/PID identity must be verified before conversion."),
        .init(channel:.throttleActual, dimension:.percent, canonicalUnit:"%", semanticsState:.unverified, note:"Blade angle versus normalized percentage semantics may differ by scanner."),
        .init(channel:.throttleCommanded, dimension:.percent, canonicalUnit:"%", semanticsState:.unverified, note:"Pedal, effective, and blade command must not be conflated.")
    ]
    static func semantic(for channel: CanonicalChannel) -> MeasurementUnitSemantic? { entries.first { $0.channel == channel } }
    static func mayConvert(_ channel: CanonicalChannel) -> Bool {
        guard let x = semantic(for: channel) else { return false }
        return x.canonicalUnit != nil && x.semanticsState != .unverified && x.semanticsState != .disputed
    }
    static let boundary = "Typed dimensions prevent category errors, but unit conversion is permitted only when the source channel semantics/unit are known. A canonical display preference cannot manufacture PID semantics."
}

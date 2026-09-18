import Foundation

struct MeasurementAtlasTypeContract: Codable, Equatable {
    let channel: CanonicalChannel
    let dimension: EngineeringDimension
    let preferredDisplayUnit: String
    let semanticsState: ClaimVerificationState
    let conversionAllowed: Bool
    let boundary: String
}

enum MeasurementAtlasTyping {
    static let contracts: [MeasurementAtlasTypeContract] = [
        .init(channel:.engineRPM, dimension:.rpm, preferredDisplayUnit:"rpm", semanticsState:.predatorLabDerived, conversionAllowed:true, boundary:"Canonical internal RPM representation; source scanner aliases still require semantic verification."),
        .init(channel:.fuelPressureCommanded, dimension:.pressure, preferredDisplayUnit:"psi", semanticsState:.unverified, conversionAllowed:false, boundary:"Pressure domain is known conceptually, but scanner PID identity/unit must be verified before automatic conversion."),
        .init(channel:.fuelPressureActual, dimension:.pressure, preferredDisplayUnit:"psi", semanticsState:.unverified, conversionAllowed:false, boundary:"Do not infer physical rail pressure units from a scanner label."),
        .init(channel:.lambdaCommanded, dimension:.lambda, preferredDisplayUnit:"λ", semanticsState:.unverified, conversionAllowed:false, boundary:"Lambda/equivalence-ratio/AFR semantics must not be silently conflated."),
        .init(channel:.lambdaMeasured, dimension:.lambda, preferredDisplayUnit:"λ", semanticsState:.unverified, conversionAllowed:false, boundary:"Sensor/scanner semantics and transforms require verification."),
        .init(channel:.knockRetard, dimension:.angle, preferredDisplayUnit:"deg", semanticsState:.unverified, conversionAllowed:false, boundary:"Aggregate/cylinder-specific spark-retard semantics require verification."),
        .init(channel:.iat2, dimension:.temperature, preferredDisplayUnit:"°F", semanticsState:.unverified, conversionAllowed:false, boundary:"Sensor location, PID identity and source units require verification."),
        .init(channel:.throttleActual, dimension:.percent, preferredDisplayUnit:"%", semanticsState:.unverified, conversionAllowed:false, boundary:"Blade angle, normalized percent and scanner scaling must not be assumed equivalent."),
        .init(channel:.throttleCommanded, dimension:.percent, preferredDisplayUnit:"%", semanticsState:.unverified, conversionAllowed:false, boundary:"Pedal request, effective command and blade command are distinct concepts until verified.")
    ]
    static func contract(for channel: CanonicalChannel) -> MeasurementAtlasTypeContract? { contracts.first { $0.channel == channel } }
}

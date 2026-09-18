import Foundation

enum EngineeringDimension: String, Codable { case pressure, temperature, time, angle, speed, lambda, rpm, percent, voltage, current, resistance, torque, power, mass, length, other }
struct EngineeringValue: Codable, Equatable {
    var value: Double
    var unit: String
    var dimension: EngineeringDimension
    var provenance: String?
}

import Foundation

enum GT500Subsystem: String, Codable, CaseIterable, Identifiable {
    case engine, supercharger, intake, fuel, exhaust, cooling, transmission, calibration, electrical
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

struct SubsystemApplicabilityAssessment: Codable, Equatable {
    var subsystem: GT500Subsystem
    var score: Double
    var label: String
    var reasons: [String]
    var boundary: String
}

enum SubsystemApplicabilityEngine {
    static func assess(claim: TechnicalClaim, build: VehicleBuildState, subsystem: GT500Subsystem) -> SubsystemApplicabilityAssessment {
        let fields: [GT500Subsystem: String] = [
            .engine: build.engineInternals, .supercharger: build.blower + " " + build.blowerPulley + " " + (build.blowerRatio ?? ""),
            .intake: build.intake + " " + build.throttleBody, .fuel: build.injectors + " " + (build.injectorRating ?? "") + " " + build.fuelPump + " " + build.fuelSystem,
            .exhaust: build.exhaust, .cooling: build.cooling + " " + build.intercooler, .transmission: build.transmissionMods,
            .calibration: build.notes, .electrical: build.notes
        ]
        let text = (fields[subsystem] ?? "").lowercased()
        let modificationTerms = ["aftermarket", "modified", "upgrade", "ported", "pulley", "return", "e85", "tune", "built", "headers"]
        let modified = modificationTerms.contains { text.contains($0) } || !build.name.lowercased().contains("stock")
        let factoryScoped = claim.applicability.lowercased().contains("stock") || claim.source?.grade == .a_factory
        if modified && factoryScoped {
            return .init(subsystem: subsystem, score: 0.35, label: "Review required", reasons: ["Recorded \(subsystem.label.lowercased()) configuration contains modification indicators while this claim is factory/stock scoped."], boundary: "Subsystem screening is an applicability warning, not a finding that the claim is false. Verify model year, strategy, hardware and modification interaction before using it diagnostically.")
        }
        return .init(subsystem: subsystem, score: modified ? 0.65 : 0.9, label: modified ? "Context dependent" : "No obvious conflict", reasons: [modified ? "This subsystem appears modified; applicability needs configuration-specific review." : "No obvious subsystem-level modification conflict was detected in the recorded build text."], boundary: "Text-based screening cannot prove technical applicability. Unknown or undocumented modifications remain unknown.")
    }
}

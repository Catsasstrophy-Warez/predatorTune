import Foundation

struct ApplicabilityAssessment: Codable, Equatable {
    var score: Double
    var label: String
    var reasons: [String]
    var boundary: String
}

enum ModificationApplicabilityEngine {
    static func assess(claim:TechnicalClaim, build:VehicleBuildState) -> ApplicabilityAssessment {
        let text=(build.blower+" "+build.blowerPulley+" "+build.intake+" "+build.throttleBody+" "+build.injectors+" "+build.fuelPump+" "+build.fuelSystem+" "+build.exhaust+" "+build.cooling+" "+build.intercooler+" "+build.engineInternals+" "+build.transmissionMods).lowercased()
        let modified = !text.components(separatedBy:" ").filter{$0.contains("aftermarket") || $0.contains("modified") || $0.contains("upgrade")}.isEmpty || !build.name.lowercased().contains("stock")
        let factoryScoped = claim.applicability.lowercased().contains("stock") || claim.source?.grade == .a_factory
        if modified && factoryScoped { return .init(score:0.45,label:"Limited",reasons:["Current build records modifications while the claim is factory/stock scoped."],boundary:"Applicability warning only. A modification does not automatically invalidate the claim; subsystem-specific verification is required.") }
        return .init(score:0.9,label:"High",reasons:["No obvious build-level conflict was detected from recorded configuration text."],boundary:"Build-text screening is not proof of applicability. Model year, strategy, VIN range and subsystem configuration can still matter.")
    }
}

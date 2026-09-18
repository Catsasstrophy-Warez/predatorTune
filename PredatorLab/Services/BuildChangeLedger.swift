import Foundation

enum BuildChangeCategory: String, Codable, CaseIterable {
    case induction, fuel, exhaust, cooling, engine, transmission, metadata
}

struct BuildChange: Identifiable, Codable, Equatable {
    let id: UUID
    var category: BuildChangeCategory
    var field: String
    var before: String
    var after: String

    init(category: BuildChangeCategory, field: String, before: String, after: String) {
        self.id = UUID(); self.category = category; self.field = field; self.before = before; self.after = after
    }
}

struct BuildChangeLedger: Codable {
    var baselineBuildID: UUID
    var validationBuildID: UUID
    var changes: [BuildChange]
    var generatedAt: Date
    var hasChanges: Bool { !changes.isEmpty }
}

enum BuildChangeLedgerEngine {
    static func compare(_ baseline: VehicleBuildState, _ validation: VehicleBuildState) -> BuildChangeLedger {
        var changes: [BuildChange] = []
        func add(_ category: BuildChangeCategory, _ field: String, _ a: String?, _ b: String?) {
            let lhs = (a ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let rhs = (b ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard lhs != rhs else { return }
            changes.append(BuildChange(category: category, field: field, before: lhs.isEmpty ? "Not recorded" : lhs, after: rhs.isEmpty ? "Not recorded" : rhs))
        }
        add(.metadata, "Build name", baseline.name, validation.name)
        add(.induction, "Supercharger", baseline.blower, validation.blower)
        add(.induction, "Supercharger pulley", baseline.blowerPulley, validation.blowerPulley)
        add(.induction, "Blower ratio", baseline.blowerRatio, validation.blowerRatio)
        add(.induction, "Intake", baseline.intake, validation.intake)
        add(.induction, "Throttle body", baseline.throttleBody, validation.throttleBody)
        add(.fuel, "Injectors", baseline.injectors, validation.injectors)
        add(.fuel, "Injector rating", baseline.injectorRating, validation.injectorRating)
        add(.fuel, "Fuel pump", baseline.fuelPump, validation.fuelPump)
        add(.fuel, "Fuel system", baseline.fuelSystem, validation.fuelSystem)
        add(.exhaust, "Exhaust", baseline.exhaust, validation.exhaust)
        add(.cooling, "Cooling", baseline.cooling, validation.cooling)
        add(.cooling, "Intercooler", baseline.intercooler, validation.intercooler)
        add(.engine, "Engine internals", baseline.engineInternals, validation.engineInternals)
        add(.transmission, "Transmission", baseline.transmissionMods, validation.transmissionMods)
        add(.metadata, "Notes", baseline.notes, validation.notes)
        return BuildChangeLedger(baselineBuildID: baseline.id, validationBuildID: validation.id, changes: changes, generatedAt: .now)
    }
}

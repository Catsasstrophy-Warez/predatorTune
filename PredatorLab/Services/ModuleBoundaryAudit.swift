import Foundation

enum PredatorLabModule: String, CaseIterable, Codable { case coreModels, evidence, diagnostics, validation, reference, persistence, presentation, utilities }

struct ModuleBoundaryFinding: Identifiable, Codable, Equatable {
    let id: String
    let module: PredatorLabModule
    let severity: String
    let message: String
}

enum ModuleBoundaryAudit {
    /// Architectural target map used while the single Xcode target is progressively decomposed.
    static let targetDependencies: [PredatorLabModule: Set<PredatorLabModule>] = [
        .coreModels: [], .utilities: [.coreModels], .evidence: [.coreModels, .utilities],
        .diagnostics: [.coreModels, .evidence, .utilities], .validation: [.coreModels, .evidence, .diagnostics, .utilities],
        .reference: [.coreModels, .utilities], .persistence: [.coreModels, .evidence, .utilities],
        .presentation: [.coreModels, .evidence, .diagnostics, .validation, .reference, .persistence, .utilities]
    ]
    static func validateDependency(from: PredatorLabModule, to: PredatorLabModule) -> ModuleBoundaryFinding? {
        guard from != to else { return nil }
        guard !(targetDependencies[from] ?? []).contains(to) else { return nil }
        return .init(id: "\(from.rawValue)>\(to.rawValue)", module: from, severity: "warning", message: "Target module \(from.rawValue) should not depend directly on \(to.rawValue). Route through an allowed lower-level contract.")
    }
}

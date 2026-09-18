import Foundation

/// Static contract for critical user journeys. Runtime VoiceOver focus order, Dynamic Type clipping,
/// switch control and hit-target behavior still require Xcode/device accessibility validation.
enum AccessibilityCriticalSurface: String, CaseIterable {
    case garage, analyze, forensic, reference, settings, recovery, validation, multiDomainDiagnostics
}
struct AccessibilityCoverageSnapshot: Equatable {
    let identifiers: Set<String>
    let coveredSurfaces: Set<AccessibilityCriticalSurface>
    var missingSurfaces: [AccessibilityCriticalSurface] { AccessibilityCriticalSurface.allCases.filter { !coveredSurfaces.contains($0) } }
    var isStructurallyComplete: Bool { missingSurfaces.isEmpty }
    let boundary = "Identifier coverage is a structural automation check only. It does not validate VoiceOver semantics, focus order, Dynamic Type, contrast, Switch Control, or physical hit targets."
}
enum AccessibilityCoverageAudit {
    static let requiredPrefixes: [AccessibilityCriticalSurface: [String]] = [
        .garage: ["garage."], .analyze: ["analysis."], .forensic: ["forensic."], .reference: ["reference."],
        .settings: ["settings."], .recovery: ["settings.recovery"], .validation: ["validation."], .multiDomainDiagnostics: ["diagnostics."]
    ]
    static func evaluate(identifiers: Set<String>) -> AccessibilityCoverageSnapshot {
        let covered = Set(requiredPrefixes.compactMap { surface, prefixes in prefixes.allSatisfy { prefix in identifiers.contains { $0.hasPrefix(prefix) } } ? surface : nil })
        return .init(identifiers: identifiers, coveredSurfaces: covered)
    }
}

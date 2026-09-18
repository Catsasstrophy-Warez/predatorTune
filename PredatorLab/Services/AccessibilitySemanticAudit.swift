import Foundation

struct AccessibilitySemanticRequirement: Identifiable, Equatable {
    let id: String
    let surface: String
    let requirement: String
    let runtimeGate: Bool
}

enum AccessibilitySemanticAudit {
    static let critical: [AccessibilitySemanticRequirement] = [
        .init(id:"a11y.chart.summary",surface:"Charts",requirement:"Provide a textual summary of trend, units, missingness, and evidence boundary.",runtimeGate:false),
        .init(id:"a11y.status.notColorOnly",surface:"Status",requirement:"Never encode evidence state, warning, pass/fail, or verification by color alone.",runtimeGate:false),
        .init(id:"a11y.controls.labels",surface:"Controls",requirement:"Interactive controls require stable labels/identifiers and meaningful roles.",runtimeGate:false),
        .init(id:"a11y.dynamicType",surface:"All",requirement:"Validate Dynamic Type without clipping or hidden critical evidence.",runtimeGate:true),
        .init(id:"a11y.voiceover.order",surface:"All",requirement:"Validate VoiceOver reading/focus order on device or simulator.",runtimeGate:true),
        .init(id:"a11y.hitTargets",surface:"Garage",requirement:"Validate glove-friendly physical hit targets on supported iPhone/iPad layouts.",runtimeGate:true)
    ]
    static var staticallyActionable: [AccessibilitySemanticRequirement] { critical.filter { !$0.runtimeGate } }
    static var appleRuntimeRequired: [AccessibilitySemanticRequirement] { critical.filter(\.runtimeGate) }
}

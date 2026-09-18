import Foundation

struct DiagnosticPresentationDecision: Codable, Equatable {
    let requestedStrength: DiagnosticConclusionStrength
    let effectiveStrength: DiagnosticConclusionStrength
    let mayUseStrongLanguage: Bool
    let title: String
    let reasons: [String]
    let boundary: String
}

enum DiagnosticPresentationGate {
    static func decide(requested: DiagnosticConclusionStrength, provenance: LiveDiagnosticProvenanceStatus) -> DiagnosticPresentationDecision {
        guard requested == .strong else {
            return .init(requestedStrength: requested, effectiveStrength: requested, mayUseStrongLanguage: false,
                         title: requested == .observation ? "Observation" : "Diagnostic suggestion", reasons: provenance.messages,
                         boundary: provenance.boundary)
        }
        if provenance.admittedForStrongPresentation {
            return .init(requestedStrength:.strong, effectiveStrength:.strong, mayUseStrongLanguage:true,
                         title:"Evidence-supported diagnostic conclusion", reasons:provenance.messages, boundary:provenance.boundary)
        }
        return .init(requestedStrength:.strong, effectiveStrength:.suggestion, mayUseStrongLanguage:false,
                     title:"Diagnostic suggestion — provenance incomplete",
                     reasons:provenance.messages.isEmpty ? ["Strong presentation was not admitted by the provenance gate."] : provenance.messages,
                     boundary:provenance.boundary)
    }
}

import Foundation

/// The only presentation model intended for conclusion-style diagnostic UI.
/// It forces every conclusion card through DiagnosticPresentationGate first.
struct DiagnosticResultPresentation: Identifiable, Codable, Equatable {
    let id: String
    let headline: String
    let requestedStrength: DiagnosticConclusionStrength
    let decision: DiagnosticPresentationDecision
    let evidenceSummary: [String]

    var displayTitle: String { decision.mayUseStrongLanguage ? headline : decision.title }
}

enum DiagnosticResultPresentationEngine {
    static func make(id: String, headline: String, requestedStrength: DiagnosticConclusionStrength,
                     provenance: LiveDiagnosticProvenanceStatus, evidenceSummary: [String]) -> DiagnosticResultPresentation {
        .init(id:id, headline:headline, requestedStrength:requestedStrength,
              decision:DiagnosticPresentationGate.decide(requested:requestedStrength, provenance:provenance),
              evidenceSummary:evidenceSummary)
    }
}

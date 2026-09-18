import Foundation

struct LiveDiagnosticProvenanceStatus: Codable, Equatable {
    let admittedForStrongPresentation: Bool
    let blockerCount: Int
    let warningCount: Int
    let messages: [String]
    let boundary: String
}

enum LiveDiagnosticProvenanceEngine {
    static func status(context: DiagnosticProvenanceContext, engine: TechnicalQueryEngine) -> LiveDiagnosticProvenanceStatus {
        let issues = EndToEndDiagnosticProvenanceAudit.audit(context, engine: engine)
        let blockers = issues.filter { $0.severity == .blocker }.count
        let warnings = issues.count - blockers
        return .init(admittedForStrongPresentation: blockers == 0, blockerCount: blockers, warningCount: warnings,
                     messages: issues.map(\.message), boundary: EndToEndDiagnosticProvenanceAudit.boundary)
    }
}

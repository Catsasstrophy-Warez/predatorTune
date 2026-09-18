import Foundation

struct DiagnosticProvenanceContext: Codable {
    let conclusion: DiagnosticConclusionContract
    let evidenceRecords: [EvidenceRecord]
    let measurementClaims: [MeasurementClaimContract]
    let buildRevisionID: UUID?
    let currentBuild: VehicleBuildState?
}

struct EndToEndDiagnosticProvenanceIssue: Identifiable, Codable, Equatable {
    enum Severity: String, Codable { case warning, blocker }
    let id: String
    let severity: Severity
    let message: String
}

enum EndToEndDiagnosticProvenanceAudit {
    static func audit(_ context: DiagnosticProvenanceContext, engine: TechnicalQueryEngine) -> [EndToEndDiagnosticProvenanceIssue] {
        var issues: [EndToEndDiagnosticProvenanceIssue] = []
        let conclusionIssues = DiagnosticConclusionTrustAudit.audit([context.conclusion], claims: TechnicalClaimRegistry.build(from: engine).claims)
        issues += conclusionIssues.map { .init(id:"conclusion.\($0.id)", severity:$0.severity == .blocker ? .blocker : .warning, message:$0.message) }
        let evidenceIDs = Set(context.evidenceRecords.map { $0.id.uuidString })
        for required in context.conclusion.evidenceIDs where !evidenceIDs.contains(required) {
            issues.append(.init(id:"evidence.\(required)", severity:.blocker, message:"Conclusion references evidence \(required) that is not present in the supplied evidence set."))
        }
        if context.conclusion.strength == .strong && context.measurementClaims.isEmpty {
            issues.append(.init(id:"measurement.none", severity:.warning, message:"Strong conclusion has no expected-measurement contract in this provenance context."))
        }
        let measurementIssues = DiagnosticProvenanceChainAudit.audit(engine: engine, measurements: context.measurementClaims)
        issues += measurementIssues.map { .init(id:"measurement.\($0.id)", severity:$0.severity == "blocker" ? .blocker : .warning, message:$0.message) }
        if context.buildRevisionID == nil {
            issues.append(.init(id:"build.missing", severity:.blocker, message:"Diagnostic provenance is not bound to an immutable build revision."))
        }
        if let build = context.currentBuild {
            let claimsByID = Dictionary(uniqueKeysWithValues: TechnicalClaimRegistry.build(from: engine).claims.map { ($0.id,$0) })
            for id in Set(context.conclusion.dependencyClaimIDs + context.measurementClaims.flatMap(\.technicalClaimIDs)) {
                if let claim = claimsByID[id] {
                    let assessment = ModificationApplicabilityEngine.assess(claim: claim, build: build)
                    if assessment.score < 0.5 { issues.append(.init(id:"modification.\(id)", severity:.warning, message:"Claim \(id) has limited compatibility with the recorded build: \(assessment.reasons.joined(separator:" "))")) }
                }
            }
        } else {
            issues.append(.init(id:"build.state.missing", severity:.warning, message:"No build-state snapshot was supplied for modification compatibility screening."))
        }
        return issues.sorted { $0.id < $1.id }
    }

    static let boundary = "This audit verifies provenance linkage, not causation. A complete chain does not prove that a repair caused an improvement or that a component is failed."
}

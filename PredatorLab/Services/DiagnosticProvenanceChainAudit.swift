import Foundation

struct DiagnosticProvenanceChainIssue: Identifiable, Codable, Equatable {
    let id: String
    let severity: String
    let message: String
}

enum DiagnosticProvenanceChainAudit {
    /// Static contract audit for the strongest path currently available in the technical library.
    /// It intentionally reports gaps rather than manufacturing evidence links.
    static func audit(engine: TechnicalQueryEngine, measurements: [MeasurementClaimContract]) -> [DiagnosticProvenanceChainIssue] {
        let claims = Dictionary(uniqueKeysWithValues: TechnicalClaimRegistry.build(from: engine).claims.map { ($0.id, $0) })
        var result: [DiagnosticProvenanceChainIssue] = []
        for measurement in measurements {
            if measurement.technicalClaimIDs.isEmpty {
                result.append(.init(id: "\(measurement.id).claim", severity: "blocker", message: "\(measurement.label): expected measurement has no technical-claim dependency."))
            }
            for id in measurement.technicalClaimIDs {
                guard let claim = claims[id] else { result.append(.init(id: "\(measurement.id).missing.\(id)", severity: "blocker", message: "\(measurement.label): dependency \(id) is absent from the registry.")); continue }
                if claim.source == nil { result.append(.init(id: "\(measurement.id).source.\(id)", severity: "blocker", message: "\(measurement.label): dependency \(id) has no source.")) }
                if claim.locator?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false { result.append(.init(id: "\(measurement.id).locator.\(id)", severity: "blocker", message: "\(measurement.label): dependency \(id) has no exact locator.")) }
                if claim.applicability.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { result.append(.init(id: "\(measurement.id).applicability.\(id)", severity: "blocker", message: "\(measurement.label): dependency \(id) has no applicability boundary.")) }
            }
        }
        return result
    }
}

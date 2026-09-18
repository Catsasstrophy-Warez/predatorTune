import Foundation

struct MeasurementTrustPresentation: Equatable {
    let title: String
    let detail: String
    let blocksStrongDiagnosis: Bool
}

enum MeasurementTrustPresentationEngine {
    static func presentation(for claim: MeasurementClaimContract) -> MeasurementTrustPresentation {
        if claim.isAdmittedForStrongDiagnosis { return .init(title: "Verified for stated scope", detail: sourceDetail(claim), blocksStrongDiagnosis: false) }
        if claim.state == .disputed || claim.state == .superseded { return .init(title: "Blocked", detail: "This measurement is disputed or superseded and cannot support a strong conclusion.", blocksStrongDiagnosis: true) }
        if claim.source == nil || claim.locator?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false { return .init(title: "Quarantined", detail: "Exact source/locator is missing. Treat the expected value as authored guidance only.", blocksStrongDiagnosis: true) }
        if claim.technicalClaimIDs.isEmpty { return .init(title: "Dependency missing", detail: "No technical-claim dependency establishes why this expected value should apply.", blocksStrongDiagnosis: true) }
        return .init(title: "Review required", detail: claim.evidenceBoundary, blocksStrongDiagnosis: true)
    }
    private static func sourceDetail(_ claim: MeasurementClaimContract) -> String {
        let source = claim.source?.title ?? "Source"
        return "\(source) • \(claim.locator ?? "locator missing") • \(claim.applicability)"
    }
}

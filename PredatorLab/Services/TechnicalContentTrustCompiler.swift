import Foundation

struct TechnicalContentTrustSummary: Codable, Equatable {
    let totalMeasurements: Int
    let verifiedMeasurements: Int
    let quarantinedMeasurements: Int
    let missingDependencies: Int
    let missingSourceLocators: Int
    let applicabilityConflicts: Int
    let disputedMeasurements: Int
    let categoryCounts: [String:Int]
}

struct TechnicalContentCompiledPackage: Codable {
    let content: VersionedTechnicalContentBundle
    let measurementClaims: [MeasurementClaimContract]
    let trustSummary: TechnicalContentTrustSummary
    let generatedBoundary: String
}

enum TechnicalContentTrustCompiler {
    static func compile(engine: TechnicalQueryEngine, contentVersion: String) -> TechnicalContentCompiledPackage {
        let measurements = engine.circuits.flatMap(MeasurementClaimLedger.fromLegacy)
        let technicalClaims = TechnicalClaimRegistry.build(from: engine).claims
        let issues = MeasurementClaimLedger.audit(measurements, technicalClaims: technicalClaims)
        let verified = measurements.filter(\.isAdmittedForStrongDiagnosis).count
        let disputed = measurements.filter { $0.state == .disputed || $0.state == .superseded }.count
        let missingDependencies = issues.filter { $0.message.localizedCaseInsensitiveContains("dependency") }.count
        let missingSource = issues.filter { $0.message.localizedCaseInsensitiveContains("source locator") }.count
        let applicability = measurements.filter { $0.applicability.localizedCaseInsensitiveContains("unverified") || $0.applicability.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        let categories = Dictionary(grouping: measurements, by: \.ownerKind).mapValues(\.count)
        return .init(content: VersionedTechnicalContentEngine.snapshot(engine: engine, contentVersion: contentVersion),
                     measurementClaims: measurements,
                     trustSummary: .init(totalMeasurements: measurements.count, verifiedMeasurements: verified,
                                         quarantinedMeasurements: measurements.count - verified,
                                         missingDependencies: missingDependencies, missingSourceLocators: missingSource,
                                         applicabilityConflicts: applicability, disputedMeasurements: disputed,
                                         categoryCounts: categories),
                     generatedBoundary: "Compilation externalizes authored content and trust metadata. It does not upgrade verification, infer missing Ford topology, or convert record-level provenance into claim-level truth.")
    }

    static func encoded(_ package: TechnicalContentCompiledPackage) throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(package)
    }
}

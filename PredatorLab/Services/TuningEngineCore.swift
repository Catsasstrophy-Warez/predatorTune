import Foundation

enum TuningControllerFamily: String, Codable, CaseIterable { case gt500PCM = "GT500 Production PCM", trC75 = "TR_C75 TCM", tc298b = "TC-298B Control Pack", mg1cs036 = "Raptor R MG1CS036" }
enum CalibrationEvidenceAuthority: String, Codable, CaseIterable { case ford = "Ford", hpTuners = "HP Tuners", tremec = "TREMEC", professional = "Professional tuner", empirical = "Empirical vehicle evidence", inference = "PredatorLab inference", unknown = "Unknown" }
enum TuneReadinessState: String, Codable { case ready = "Ready for controlled testing", limited = "Ready with limitations", baselineRequired = "Baseline required", diagnoseFirst = "Resolve diagnostic blocker first", identityUnknown = "Calibration identity uncertain", insufficientEvidence = "Insufficient evidence" }

struct CalibrationFingerprint: Identifiable, Codable, Equatable {
    let id: UUID
    let vehicleID: UUID?
    let controller: TuningControllerFamily
    let operatingSystem: String?
    let strategy: String?
    let calibrationID: String?
    let vcmSuiteVersion: String?
    let fileSHA256: String?
    let parentID: UUID?
    let buildRevisionID: UUID?
    let fuel: String?
    let notes: String
}

struct TuneLogContract: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let purpose: String
    let calibrationFingerprintID: UUID?
    let buildRevisionID: UUID?
    let scannerConfigurationName: String
    let requiredParameterIDs: [String]
    let requiredTrackMode: String?
    let minimumQuality: Double
    let operatingEnvelope: [String]
    let abortCriteria: [String]
}

struct TuneExperimentIntegrity: Codable, Equatable {
    let hasCalibrationIdentity: Bool
    let hasScannerContract: Bool
    let hasVehicleLog: Bool
    let hasSpatialEvidence: Bool
    let buildMatched: Bool
    let calibrationMatched: Bool
    let requiredChannelsPresent: Int
    let requiredChannelsTotal: Int
    var isComplete: Bool { hasCalibrationIdentity && hasScannerContract && hasVehicleLog && buildMatched && calibrationMatched && requiredChannelsPresent == requiredChannelsTotal }
}

struct TuneReadinessAssessment: Codable, Equatable {
    let state: TuneReadinessState
    let blockers: [String]
    let requirements: [String]
}

enum TuneReadinessEngine {
    static func assess(vehiclePresent: Bool, calibrationIdentified: Bool, baselineAvailable: Bool, unresolvedDiagnosticBlockers: [String], acquisitionQuality: Double?) -> TuneReadinessAssessment {
        guard vehiclePresent else { return .init(state:.insufficientEvidence,blockers:["No active vehicle/build revision."],requirements:["Select the exact vehicle and current build revision."]) }
        if !unresolvedDiagnosticBlockers.isEmpty { return .init(state:.diagnoseFirst,blockers:unresolvedDiagnosticBlockers,requirements:["Resolve or explicitly disposition diagnostic blockers before increasing demand."]) }
        guard calibrationIdentified else { return .init(state:.identityUnknown,blockers:["Controller/OS/strategy/calibration identity is not established."],requirements:["Capture an immutable original read and calibration fingerprint."]) }
        guard baselineAvailable else { return .init(state:.baselineRequired,blockers:["No comparable known-good baseline is attached to this build/calibration."],requirements:["Capture baseline log with a fingerprinted Scanner configuration."]) }
        if let q = acquisitionQuality, q < 0.75 { return .init(state:.limited,blockers:["Acquisition quality is below the strong-comparison threshold."],requirements:["Reduce polling burden or repair missing/unstable channels."]) }
        return .init(state:.ready,blockers:[],requirements:["Define one experiment goal, hold critical variables constant, record abort criteria, and validate against a comparable baseline."])
    }
}

enum TuneEvidenceBundleContract {
    static let requiredCoreRoles = ["HPT calibration/read", "HPL vehicle log", "VCM Scanner XML"]
    static let optionalContextRoles = ["TrackAddict CSV", "TrackAddict MOV/MP4", "TrackAddict TAD", "TrackAddict notes", "dyno export"]
    static let boundary = "Original tuning and telemetry artifacts remain immutable. PredatorLab fingerprints and analyzes them but does not infer calibration ancestry from filenames alone."
}

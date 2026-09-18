import Foundation

// Rev59: persistent calibration ancestry, flash events, semantic diff manifests and conservative limiter/shift analysis.
struct PersistedCalibrationGenome: Identifiable, Codable, Equatable {
    let id: UUID
    let vehicleID: UUID?
    let fingerprint: CalibrationFingerprint
    let createdAt: Date
    let immutableOriginal: Bool
    let sourceArtifactID: UUID?
    let notes: [String]
}

struct CalibrationDifferenceEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let semanticParameterID: String
    let displayName: String
    let engineeringDomain: String
    let oldValueDescription: String?
    let newValueDescription: String?
    let units: String?
    let authority: CalibrationEvidenceAuthority
    let semanticMeaningVerified: Bool
}

struct CalibrationDifferenceManifest: Identifiable, Codable, Equatable {
    let id: UUID
    let fromCalibrationID: UUID
    let toCalibrationID: UUID
    let createdAt: Date
    let entries: [CalibrationDifferenceEntry]
    let source: String
    let boundary: String
    static let evidenceBoundary = "A difference manifest proves that represented calibration values differ. It does not by itself prove parameter semantics, causal effect, safety, or improvement."
}

enum CalibrationDifferenceManifestEngine {
    static func make(from: UUID, to: UUID, entries: [CalibrationDifferenceEntry], source: String) -> CalibrationDifferenceManifest {
        .init(id:UUID(),fromCalibrationID:from,toCalibrationID:to,createdAt:.now,entries:entries,source:source,boundary:CalibrationDifferenceManifest.evidenceBoundary)
    }
}

enum FlashWriteMode: String, Codable { case normal, full, restoreStock, unknown }
struct CalibrationFlashEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let vehicleID: UUID?
    let fromCalibrationID: UUID?
    let toCalibrationID: UUID
    let occurredAt: Date
    let writeMode: FlashWriteMode
    let interfaceDevice: String?
    let softwareVersion: String?
    let completed: Bool
    let preFlashDTCArtifactID: UUID?
    let postFlashDTCArtifactID: UUID?
    let notes: [String]
}

enum CalibrationAncestryAudit {
    static func validate(genomes:[PersistedCalibrationGenome], flashEvents:[CalibrationFlashEvent]) -> [String] {
        let ids = Set(genomes.map(\.id)); var warnings:[String] = []
        for event in flashEvents {
            if !ids.contains(event.toCalibrationID) { warnings.append("Flash event \(event.id) points to an unknown destination calibration.") }
            if let from = event.fromCalibrationID, !ids.contains(from) { warnings.append("Flash event \(event.id) points to an unknown parent calibration.") }
            if event.fromCalibrationID == event.toCalibrationID { warnings.append("Flash event \(event.id) has identical source and destination calibration IDs.") }
        }
        return warnings
    }
}

struct LimiterObservation: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Double
    let channelSemanticID: String
    let direction: String
    let magnitudeDescription: String
    let semanticsVerified: Bool
}
struct LimiterHypothesisScore: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let evidenceFit: Double
    let supportingObservationIDs: [UUID]
    let missingSemanticIDs: [String]
    let boundary: String
}

enum GT500LimiterAnalysisEngine {
    static func rank(observations:[LimiterObservation], requiredByHypothesis:[String:[String]]) -> [LimiterHypothesisScore] {
        requiredByHypothesis.map { key, required in
            let verified = Set(observations.filter(\.semanticsVerified).map(\.channelSemanticID))
            let req = Set(required); let hit = req.intersection(verified); let missing = req.subtracting(verified).sorted()
            let fit = req.isEmpty ? 0 : Double(hit.count)/Double(req.count)
            return .init(id:key,title:key,evidenceFit:fit,supportingObservationIDs:observations.filter{hit.contains($0.channelSemanticID)}.map(\.id),missingSemanticIDs:missing,boundary:"Evidence-fit ranking is not calibrated probability and does not prove the active limiter.")
        }.sorted{$0.evidenceFit > $1.evidenceFit}
    }
}

struct TRC75ShiftSample: Codable, Equatable { let time: Double; let engineRPM: Double; let longitudinalAcceleration: Double? }
struct TRC75ShiftFingerprint: Codable, Equatable {
    let startTime: Double; let endTime: Double; let duration: Double; let peakRPM: Double; let endingRPM: Double; let rpmDrop: Double; let minimumAcceleration: Double?; let boundary: String
}
enum TRC75ShiftAnalysisEngine {
    static func fingerprint(samples:[TRC75ShiftSample]) -> TRC75ShiftFingerprint? {
        guard let first=samples.first, let last=samples.last, samples.count >= 2, last.time > first.time else{return nil}
        let peak=samples.map(\.engineRPM).max() ?? first.engineRPM
        return .init(startTime:first.time,endTime:last.time,duration:last.time-first.time,peakRPM:peak,endingRPM:last.engineRPM,rpmDrop:peak-last.engineRPM,minimumAcceleration:samples.compactMap(\.longitudinalAcceleration).min(),boundary:"Derived shift metrics describe the selected event window. They do not establish clutch pressure, torque handoff, or calibration cause without verified supporting channels.")
    }
}

import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

typealias TimebaseAlignmentResult = TimebaseAlignment

// Rev60: durable tune experiments, TrackAddict row ingestion, synchronization and cohort analysis.
struct PersistedTuneExperiment: Identifiable, Codable, Equatable {
    let id: UUID
    let vehicleID: UUID?
    let buildRevisionID: UUID?
    let pcmCalibrationID: UUID?
    let tcmCalibrationID: UUID?
    let createdAt: Date
    let artifactIDs: [UUID]
    let trackSessionID: String?
    let scannerConfigurationName: String?
    let contractID: UUID?
    let structuralConfidence: Double
    let warnings: [String]
    let boundary: String
}

enum TuneExperimentPersistenceEngine {
    static func make(vehicleID: UUID?, buildRevisionID: UUID?, pcmCalibrationID: UUID?, tcmCalibrationID: UUID?, artifacts: [TuneArtifactDescriptor], scannerConfigurationName: String?, contractID: UUID?) -> PersistedTuneExperiment {
        let r = TuneExperimentReconstructionEngine.reconstruct(artifacts)
        return .init(id: UUID(), vehicleID: vehicleID, buildRevisionID: buildRevisionID, pcmCalibrationID: pcmCalibrationID, tcmCalibrationID: tcmCalibrationID, createdAt: .now, artifactIDs: artifacts.map(\.id), trackSessionID: r.trackSessionID, scannerConfigurationName: scannerConfigurationName, contractID: contractID, structuralConfidence: r.confidence, warnings: r.warnings, boundary: r.boundary)
    }
}

struct TrackAddictSample: Identifiable, Codable, Equatable {
    let id: UUID
    let time: Double?
    let latitude: Double?
    let longitude: Double?
    let speed: Double?
    let rpm: Double?
    let throttle: Double?
    let lateralG: Double?
    let longitudinalG: Double?
    let raw: [String:String]
}
struct TrackAddictParsedSession: Codable, Equatable {
    let headers: [String]
    let columnMap: TrackAddictColumnMap
    let samples: [TrackAddictSample]
    let rejectedRowCount: Int
    let boundary: String
}

enum TrackAddictCSVParser {
    static func parse(_ text: String, maximumRows: Int = 200_000) -> TrackAddictParsedSession {
        let lines = text.split(whereSeparator: \.isNewline).map(String.init)
        guard let first = lines.first else { return .init(headers: [], columnMap: TrackAddictCSVSemanticDiscovery.discover(headers: []), samples: [], rejectedRowCount: 0, boundary: boundary) }
        let headers = csvFields(first)
        let map = TrackAddictCSVSemanticDiscovery.discover(headers: headers)
        var samples:[TrackAddictSample] = []; var rejected = 0
        for line in lines.dropFirst().prefix(maximumRows) {
            let values = csvFields(line)
            guard values.count == headers.count else { rejected += 1; continue }
            let raw = Dictionary(uniqueKeysWithValues: zip(headers, values))
            func d(_ key:String?) -> Double? { guard let key, let v=raw[key] else{return nil}; return Double(v.trimmingCharacters(in:.whitespacesAndNewlines)) }
            samples.append(.init(id:UUID(),time:d(map.timestamp),latitude:d(map.latitude),longitude:d(map.longitude),speed:d(map.speed),rpm:d(map.rpm),throttle:d(map.throttle),lateralG:d(map.lateralG),longitudinalG:d(map.longitudinalG),raw:raw))
        }
        return .init(headers:headers,columnMap:map,samples:samples,rejectedRowCount:rejected,boundary:boundary)
    }
    private static let boundary = "TrackAddict CSV parsing preserves raw fields. Header discovery is provisional and does not by itself verify channel semantics, units, sensor source, or timing accuracy."
    private static func csvFields(_ line:String) -> [String] {
        var out:[String]=[], current="", quoted=false; let chars=Array(line); var i=0
        while i < chars.count { let c=chars[i]; if c == "\"" { if quoted && i+1 < chars.count && chars[i+1] == "\"" { current.append("\""); i += 1 } else { quoted.toggle() } } else if c == "," && !quoted { out.append(current); current="" } else { current.append(c) }; i += 1 }
        out.append(current); return out
    }
}

struct SynchronizedTrackSample: Identifiable, Codable, Equatable {
    let id: UUID
    let sourceTime: Double
    let referenceTime: Double
    let latitude: Double?
    let longitude: Double?
    let speed: Double?
    let rpm: Double?
}
enum TrackAddictSynchronizationEngine {
    static func synchronize(_ session: TrackAddictParsedSession, alignment: TimebaseAlignmentResult) -> [SynchronizedTrackSample] {
        session.samples.compactMap { s in guard let t=s.time else{return nil}; return .init(id:s.id,sourceTime:t,referenceTime:alignment.offset + (1 + alignment.drift) * t,latitude:s.latitude,longitude:s.longitude,speed:s.speed,rpm:s.rpm) }
    }
}

struct ShiftCohortSummary: Codable, Equatable {
    let count: Int
    let medianDuration: Double?
    let medianRPMDrop: Double?
    let medianMinimumAcceleration: Double?
    let boundary: String
}
enum TRC75ShiftCohortEngine {
    static func summarize(_ shifts:[TRC75ShiftFingerprint]) -> ShiftCohortSummary {
        func median(_ x:[Double]) -> Double? { let a=x.sorted(); guard !a.isEmpty else{return nil}; let m=a.count/2; return a.count % 2 == 0 ? (a[m-1]+a[m])/2 : a[m] }
        return .init(count:shifts.count,medianDuration:median(shifts.map(\.duration)),medianRPMDrop:median(shifts.map(\.rpmDrop)),medianMinimumAcceleration:median(shifts.compactMap(\.minimumAcceleration)),boundary:"Cohort summaries describe selected shift-event distributions. They do not prove a calibration improvement or mechanical safety without comparable operating conditions and verified channel semantics.")
    }
}

struct CalibrationExperimentTimelineEntry: Identifiable, Codable, Equatable { let id:UUID; let occurredAt:Date; let kind:String; let title:String; let calibrationID:UUID?; let experimentID:UUID? }
enum CalibrationExperimentTimelineEngine {
    static func build(genomes:[PersistedCalibrationGenome], flashes:[CalibrationFlashEvent], experiments:[PersistedTuneExperiment]) -> [CalibrationExperimentTimelineEntry] {
        let g=genomes.map{CalibrationExperimentTimelineEntry(id:UUID(),occurredAt:$0.createdAt,kind:"Calibration",title:$0.immutableOriginal ? "Original calibration captured" : "Calibration revision captured",calibrationID:$0.id,experimentID:nil)}
        let f=flashes.map{CalibrationExperimentTimelineEntry(id:UUID(),occurredAt:$0.occurredAt,kind:"Flash",title:$0.completed ? "Calibration write completed" : "Calibration write incomplete",calibrationID:$0.toCalibrationID,experimentID:nil)}
        let e=experiments.map{CalibrationExperimentTimelineEntry(id:UUID(),occurredAt:$0.createdAt,kind:"Experiment",title:"Tune experiment reconstructed",calibrationID:$0.pcmCalibrationID,experimentID:$0.id)}
        return (g+f+e).sorted{$0.occurredAt < $1.occurredAt}
    }
}

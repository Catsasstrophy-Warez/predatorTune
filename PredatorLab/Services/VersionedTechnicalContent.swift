import Foundation

struct TechnicalContentManifest: Codable, Equatable {
    let schemaVersion: Int
    let contentVersion: String
    let generatedAt: Date
    let componentCount: Int
    let circuitCount: Int
    let sensorCount: Int
    let dtcCount: Int
    let procedureCount: Int
    let calibrationCount: Int
    let evidenceBoundary: String
}

struct VersionedTechnicalContentBundle: Codable {
    let manifest: TechnicalContentManifest
    let components: [ComponentRecord]
    let circuits: [CircuitRecord]
    let sensors: [SensorRecord]
    let dtcs: [DTCRecord]
    let procedures: [ProcedureRecord]
    let calibration: [CalibrationRecord]
}

enum VersionedTechnicalContentEngine {
    static let schemaVersion = 1
    static func snapshot(engine: TechnicalQueryEngine, contentVersion: String, now: Date = Date()) -> VersionedTechnicalContentBundle {
        let manifest = TechnicalContentManifest(schemaVersion: schemaVersion, contentVersion: contentVersion, generatedAt: now, componentCount: engine.components.count, circuitCount: engine.circuits.count, sensorCount: engine.sensors.count, dtcCount: engine.dtcs.count, procedureCount: engine.procedures.count, calibrationCount: engine.calibration.count, evidenceBoundary: "A versioned content bundle preserves authored technical records and provenance. Packaging a record does not upgrade its verification state or fill missing source evidence.")
        return .init(manifest: manifest, components: engine.components, circuits: engine.circuits, sensors: engine.sensors, dtcs: engine.dtcs, procedures: engine.procedures, calibration: engine.calibration)
    }
    static func validate(_ bundle: VersionedTechnicalContentBundle) -> [String] {
        var issues: [String] = []
        if bundle.manifest.schemaVersion != schemaVersion { issues.append("Unsupported technical-content schema version \(bundle.manifest.schemaVersion).") }
        if bundle.manifest.contentVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append("Content version is required.") }
        if bundle.manifest.componentCount != bundle.components.count { issues.append("Component manifest count does not match payload.") }
        if bundle.manifest.circuitCount != bundle.circuits.count { issues.append("Circuit manifest count does not match payload.") }
        if bundle.manifest.sensorCount != bundle.sensors.count { issues.append("Sensor manifest count does not match payload.") }
        if bundle.manifest.dtcCount != bundle.dtcs.count { issues.append("DTC manifest count does not match payload.") }
        if bundle.manifest.procedureCount != bundle.procedures.count { issues.append("Procedure manifest count does not match payload.") }
        if bundle.manifest.calibrationCount != bundle.calibration.count { issues.append("Calibration manifest count does not match payload.") }
        return issues
    }
}

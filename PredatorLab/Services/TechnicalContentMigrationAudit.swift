import Foundation

struct TechnicalContentMigrationSnapshot: Equatable {
    let componentCount: Int
    let circuitCount: Int
    let sensorCount: Int
    let dtcCount: Int
    let procedureCount: Int
    let calibrationCount: Int
    let contentVersion: String
    let boundary: String
}

enum TechnicalContentMigrationAudit {
    static func snapshot(_ bundle: VersionedTechnicalContentBundle) -> TechnicalContentMigrationSnapshot {
        .init(componentCount: bundle.components.count,
              circuitCount: bundle.circuits.count,
              sensorCount: bundle.sensors.count,
              dtcCount: bundle.dtcs.count,
              procedureCount: bundle.procedures.count,
              calibrationCount: bundle.calibration.count,
              contentVersion: bundle.manifest.contentVersion,
              boundary: "Externalization changes storage and release mechanics only. It does not verify technical content, expand applicability, or fill missing evidence.")
    }

    static func equivalent(_ lhs: VersionedTechnicalContentBundle, _ rhs: VersionedTechnicalContentBundle) -> Bool {
        let a = snapshot(lhs), b = snapshot(rhs)
        return a.componentCount == b.componentCount && a.circuitCount == b.circuitCount && a.sensorCount == b.sensorCount && a.dtcCount == b.dtcCount && a.procedureCount == b.procedureCount && a.calibrationCount == b.calibrationCount
    }
}

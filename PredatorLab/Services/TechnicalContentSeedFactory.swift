import Foundation

enum TechnicalContentSeedFactory {
    static func makeEngine() -> TechnicalQueryEngine {
        let engine = TechnicalQueryEngine()
        engine.components = ComponentLibrarySeedData.seedAll()
        engine.circuits = TechnicalLibrarySeedData.seedCircuits()
        engine.sensors = TechnicalLibrarySeedData.seedSensors()
        engine.dtcs = TechnicalLibrarySeedData.seedDTCs()
        engine.procedures = TechnicalLibrarySeedData.seedProcedures()
        engine.calibration = TechnicalLibrarySeedData.seedCalibration()
        return engine
    }
}

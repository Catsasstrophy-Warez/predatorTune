import Foundation

enum TechnicalContentLoadSource: String, Codable { case bundledJSON, authoredSeedFallback }
struct TechnicalContentLoadResult {
    let source: TechnicalContentLoadSource
    let bundle: VersionedTechnicalContentBundle
    let warnings: [String]
}
enum TechnicalContentLoader {
    static func load(url: URL, fallback engine: TechnicalQueryEngine, fallbackVersion: String = "swift-seed-fallback") throws -> TechnicalContentLoadResult {
        do {
            let data=try Data(contentsOf:url)
            let bundle=try JSONDecoder().decode(VersionedTechnicalContentBundle.self,from:data)
            let issues=VersionedTechnicalContentEngine.validate(bundle)
            guard issues.isEmpty else { PLStructuredLog.event("technicalContent.reject", level: .warning, fields: ["issueCount": String(issues.count)]); return .init(source:.authoredSeedFallback,bundle:VersionedTechnicalContentEngine.snapshot(engine:engine,contentVersion:fallbackVersion),warnings:["External content rejected: \(issues.joined(separator:"; "))"]) }
            PLStructuredLog.event("technicalContent.load", fields: ["schema": String(bundle.manifest.schemaVersion), "version": bundle.manifest.contentVersion]); return .init(source:.bundledJSON,bundle:bundle,warnings:[])
        } catch {
            PLStructuredLog.event("technicalContent.decodeFailure", level: .error, fields: ["errorType": String(describing: type(of: error))]); return .init(source:.authoredSeedFallback,bundle:VersionedTechnicalContentEngine.snapshot(engine:engine,contentVersion:fallbackVersion),warnings:["External content could not be decoded; authored Swift seed fallback retained. \(error.localizedDescription)"])
        }
    }
    static func apply(_ bundle: VersionedTechnicalContentBundle, to engine: TechnicalQueryEngine) throws {
        let issues=VersionedTechnicalContentEngine.validate(bundle); guard issues.isEmpty else { throw NSError(domain:"PredatorLab.TechnicalContent",code:1,userInfo:[NSLocalizedDescriptionKey:issues.joined(separator:"; ")]) }
        engine.components=bundle.components; engine.circuits=bundle.circuits; engine.sensors=bundle.sensors; engine.dtcs=bundle.dtcs; engine.procedures=bundle.procedures; engine.calibration=bundle.calibration
    }
}

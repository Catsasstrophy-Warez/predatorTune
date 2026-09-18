import Foundation

struct TechnicalContentExportResult: Codable, Equatable {
    let url: URL
    let fingerprint: TechnicalContentArtifactFingerprint
    let byteCount: Int
}

enum TechnicalContentArtifactExporter {
    static func exportCanonical(engine: TechnicalQueryEngine, contentVersion: String, to url: URL) throws -> TechnicalContentExportResult {
        let package = TechnicalContentTrustCompiler.compile(engine: engine, contentVersion: contentVersion)
        let data = try TechnicalContentArtifactIntegrity.canonicalData(package)
        let gate = TechnicalContentReleaseGate.evaluate(seed: package, candidateData: data)
        guard gate.admitted, let fingerprint = gate.candidate else {
            throw NSError(domain: "PredatorLab.TechnicalContentExport", code: 1, userInfo: [NSLocalizedDescriptionKey: gate.issues.joined(separator: "; ")])
        }
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let temporary = directory.appendingPathComponent(".\(url.lastPathComponent).tmp-\(UUID().uuidString)")
        do {
            try data.write(to: temporary, options: .atomic)
            if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
            try FileManager.default.moveItem(at: temporary, to: url)
            PLStructuredLog.event("technicalContent.export", fields: ["version": contentVersion, "bytes": String(data.count)])
            return .init(url: url, fingerprint: fingerprint, byteCount: data.count)
        } catch {
            try? FileManager.default.removeItem(at: temporary)
            PLStructuredLog.event("technicalContent.exportFailure", level: .error, fields: ["errorType": String(describing: type(of: error))])
            throw error
        }
    }
}

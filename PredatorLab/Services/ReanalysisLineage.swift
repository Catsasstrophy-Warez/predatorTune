import Foundation

/// Immutable audit entry describing one interpretation of a source log.
/// Source evidence is never rewritten; a new revision records which engine produced the interpretation.
struct AnalysisRevision: Identifiable, Codable, Equatable {
    let id: UUID
    let generatedAt: Date
    let engine: AnalysisEngineVersion
    let sourceSHA256: String?
    let reason: String

    init(id: UUID = UUID(), generatedAt: Date = .now, engine: AnalysisEngineVersion = .current,
         sourceSHA256: String?, reason: String) {
        self.id = id; self.generatedAt = generatedAt; self.engine = engine
        self.sourceSHA256 = sourceSHA256; self.reason = reason
    }
}

enum ReanalysisLineageEngine {
    static func appendCurrent(to revisions: [AnalysisRevision]?, sourceSHA256: String?, reason: String) -> [AnalysisRevision] {
        var result = revisions ?? []
        let entry = AnalysisRevision(sourceSHA256: sourceSHA256, reason: reason)
        if result.last?.engine != entry.engine || result.last?.sourceSHA256 != sourceSHA256 { result.append(entry) }
        return result
    }

    static func needsCurrentRevision(_ revisions: [AnalysisRevision]?, legacyVersion: AnalysisEngineVersion?) -> Bool {
        if revisions?.last?.engine == .current { return false }
        guard let legacyVersion else { return true }
        return legacyVersion != .current
    }
}

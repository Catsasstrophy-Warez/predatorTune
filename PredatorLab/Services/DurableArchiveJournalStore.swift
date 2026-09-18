import Foundation

/// Small crash-recovery journal stored separately from imported evidence. It records transaction
/// intent only; it never contains CSV evidence or substitutes for Core Data transaction testing.
struct DurableArchiveJournalStore {
    let url: URL
    init(url: URL? = nil) {
        if let url { self.url = url; return }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        self.url = base.appendingPathComponent("PredatorLab/archive-import-journal.json")
    }
    func save(_ journal: ArchiveCommitJournal) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(journal)
        try data.write(to: url, options: .atomic)
        PLStructuredLog.event("archive.journal.write", fields: ["phase": journal.phase.rawValue])
    }
    func load() throws -> ArchiveCommitJournal? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode(ArchiveCommitJournal.self, from: Data(contentsOf: url))
    }
    func clear() throws {
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }
}

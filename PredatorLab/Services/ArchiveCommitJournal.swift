import Foundation

enum ArchiveCommitPhase: String, Codable, CaseIterable { case staged, verified, conflictsReviewed, committing, committed, rolledBack, failed }
struct ArchiveCommitJournal: Identifiable, Codable, Equatable {
    let id: UUID; var archiveName: String; var phase: ArchiveCommitPhase; var startedAt: Date; var updatedAt: Date; var committedRecordIDs: [UUID]; var warnings: [String]; var failure: String?
    init(id:UUID=UUID(),archiveName:String,phase:ArchiveCommitPhase = .staged,startedAt:Date = .now,updatedAt:Date = .now,committedRecordIDs:[UUID]=[],warnings:[String]=[],failure:String?=nil){self.id=id;self.archiveName=archiveName;self.phase=phase;self.startedAt=startedAt;self.updatedAt=updatedAt;self.committedRecordIDs=committedRecordIDs;self.warnings=warnings;self.failure=failure}
}
enum ArchiveCommitJournalEngine {
    static func transition(_ journal: ArchiveCommitJournal, to next: ArchiveCommitPhase, recordID: UUID? = nil, failure: String? = nil) -> ArchiveCommitJournal? {
        let allowed:[ArchiveCommitPhase:Set<ArchiveCommitPhase>] = [.staged:[.verified,.failed],.verified:[.conflictsReviewed,.failed],.conflictsReviewed:[.committing,.failed],.committing:[.committed,.rolledBack,.failed],.failed:[.rolledBack],.committed:[],.rolledBack:[]]
        guard allowed[journal.phase, default: []].contains(next) else { return nil }
        var j=journal; j.phase=next; j.updatedAt = .now; if let recordID { j.committedRecordIDs.append(recordID) }; j.failure=failure; return j
    }
    static func requiresRecovery(_ journal: ArchiveCommitJournal) -> Bool { journal.phase == .committing || journal.phase == .failed }
}

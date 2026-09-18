import Foundation

enum RecoveryAction: String, Codable, Equatable { case none, resumeVerification, reviewConflicts, reviewCommit, rollbackInterruptedCommit, discardFailedJournal }
struct RecoveryCenterSnapshot: Codable, Equatable {
    var journal: ArchiveCommitJournal?
    var action: RecoveryAction
    var title: String
    var detail: String
    var isBlocking: Bool
}
enum RecoveryCenterEngine {
    static func snapshot(journal: ArchiveCommitJournal?) -> RecoveryCenterSnapshot {
        guard let journal else { return .init(journal:nil, action:.none, title:"No interrupted archive transaction", detail:"No archive recovery journal is present.", isBlocking:false) }
        switch journal.phase {
        case .staged: return .init(journal:journal,action:.resumeVerification,title:"Staged archive needs verification",detail:"The archive was staged but not yet verified. Re-run safety and hash verification before any commit.",isBlocking:true)
        case .verified: return .init(journal:journal,action:.reviewConflicts,title:"Verified archive needs conflict review",detail:"Evidence passed verification but identity conflicts have not been reviewed.",isBlocking:true)
        case .conflictsReviewed: return .init(journal:journal,action:.reviewCommit,title:"Archive is ready for commit review",detail:"Conflicts were reviewed. Require an explicit commit decision rather than silently continuing after relaunch.",isBlocking:true)
        case .committing: return .init(journal:journal,action:.rollbackInterruptedCommit,title:"Interrupted archive commit",detail:"The app stopped while committing records. Treat the transaction as incomplete and run compensating rollback/reconciliation before retrying.",isBlocking:true)
        case .failed: return .init(journal:journal,action:.discardFailedJournal,title:"Archive import failed",detail:journal.failure ?? "The prior import failed. Preserve existing evidence and clear staging only after review.",isBlocking:true)
        case .committed: return .init(journal:journal,action:.none,title:"Archive commit completed",detail:"The recorded transaction completed. The journal may be cleared.",isBlocking:false)
        case .rolledBack: return .init(journal:journal,action:.none,title:"Archive transaction rolled back",detail:"The recorded transaction was rolled back. The journal may be cleared.",isBlocking:false)
        }
    }
}

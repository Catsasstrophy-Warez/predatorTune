import Foundation

/// Pure recovery policy for durable archive-import journals. The actual Core Data transaction
/// remains an Apple-runtime concern, but restart behavior is deterministic and testable here.
enum ArchiveRecoveryAction: String, Codable, Equatable {
    case none, discardStaging, resumeVerification, requireConflictReview, rollbackInterruptedCommit
}

enum ArchiveRecoveryCoordinator {
    static func action(for journal: ArchiveCommitJournal) -> ArchiveRecoveryAction {
        switch journal.phase {
        case .staged: return .resumeVerification
        case .verified: return .requireConflictReview
        case .conflictsReviewed: return .requireConflictReview
        case .committing: return .rollbackInterruptedCommit
        case .committed, .rolledBack: return .none
        case .failed: return .discardStaging
        }
    }
}

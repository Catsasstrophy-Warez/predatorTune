import Foundation

enum AttachmentRetentionDisposition: String, Codable { case retain, review, eligibleForDeletion }

struct AttachmentRetentionAssessment: Identifiable, Codable, Equatable {
    let id: UUID
    var attachmentID: UUID
    var disposition: AttachmentRetentionDisposition
    var reasons: [String]
    var boundary: String
}

enum AttachmentRetentionEngine {
    static func assess(_ attachment: EvidenceAttachment, linkedRCAIDs: [UUID] = [], now: Date = .now, reviewAfterDays: Double = 365) -> AttachmentRetentionAssessment {
        var reasons: [String] = []
        if attachment.logID != nil { reasons.append("Linked to an immutable source-log context.") }
        if !linkedRCAIDs.isEmpty { reasons.append("Referenced by post-job RCA history.") }
        let age = now.timeIntervalSince(attachment.createdAt) / 86_400
        let disposition: AttachmentRetentionDisposition
        if attachment.logID != nil || !linkedRCAIDs.isEmpty { disposition = .retain }
        else if age >= reviewAfterDays { disposition = .eligibleForDeletion; reasons.append("Unlinked artifact exceeded the configured review age.") }
        else { disposition = .review; reasons.append("Unlinked artifact remains inside the review window.") }
        return .init(id: UUID(), attachmentID: attachment.id, disposition: disposition, reasons: reasons, boundary: "Retention status governs storage only. Deleting an artifact must not rewrite historical diagnostic conclusions or source-log evidence.")
    }
}

import Foundation

struct RCAAttachmentLink: Identifiable, Codable, Equatable {
    let id: UUID
    var rcaID: UUID
    var attachmentID: UUID
    var role: String
    var note: String?
    var boundary: String
    init(id: UUID = UUID(), rcaID: UUID, attachmentID: UUID, role: String, note: String? = nil) {
        self.id = id; self.rcaID = rcaID; self.attachmentID = attachmentID; self.role = role; self.note = note
        self.boundary = "Linked artifact is supporting evidence for this RCA. The link does not independently establish causation or verify the RCA conclusion."
    }
}

enum RCAEvidenceLinkEngine {
    static func links(rca: PostJobRCA, attachments: [EvidenceAttachment]) -> [RCAAttachmentLink] {
        let sourceIDs = Set(rca.firstOut.compactMap(\.sourceID))
        return attachments.filter { attachment in
            sourceIDs.contains(attachment.id.uuidString) || attachment.logID.map { sourceIDs.contains($0.uuidString) } == true
        }.map { RCAAttachmentLink(rcaID: rca.id, attachmentID: $0.id, role: "supporting-artifact", note: $0.note) }
    }

    static func explicitlyLink(rcaID: UUID, attachmentID: UUID, role: String = "supporting-artifact", note: String? = nil) -> RCAAttachmentLink {
        .init(rcaID: rcaID, attachmentID: attachmentID, role: role, note: note)
    }
}

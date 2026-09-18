import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

enum ForensicAnnotationSourceRev85: String, Codable, Sendable { case manualMark, typedNote, speechTranscript, audioReference }
struct ForensicAnnotationRev85: Identifiable, Codable, Sendable {
    let id: UUID
    let time: TimeInterval
    let source: ForensicAnnotationSourceRev85
    let text: String
    let createdAt: Date
    init(id:UUID=UUID(), time:TimeInterval, source:ForensicAnnotationSourceRev85, text:String, createdAt:Date = .now) { self.id=id; self.time=time; self.source=source; self.text=text; self.createdAt=createdAt }
}

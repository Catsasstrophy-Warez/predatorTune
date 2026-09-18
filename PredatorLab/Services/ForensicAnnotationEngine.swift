import Foundation

enum AnnotationKind: String, Codable, CaseIterable { case operatorObservation, audibleObservation, tactileObservation, testAction, serviceContext, note }

struct ForensicAnnotation: Identifiable, Codable, Equatable {
    let id: UUID
    var logID: UUID
    var timestamp: TimeInterval
    var kind: AnnotationKind
    var text: String
    var createdAt: Date
    var author: String
    var evidenceBoundary: String
    init(id: UUID = UUID(), logID: UUID, timestamp: TimeInterval, kind: AnnotationKind, text: String, createdAt: Date = .now, author: String = "owner") {
        self.id=id; self.logID=logID; self.timestamp=timestamp; self.kind=kind; self.text=text; self.createdAt=createdAt; self.author=author
        self.evidenceBoundary="Human annotation. It is contextual evidence and is not a measured scanner channel."
    }
}

enum ForensicAnnotationEngine {
    static func normalized(_ annotations: [ForensicAnnotation], duration: TimeInterval) -> [ForensicAnnotation] {
        annotations.filter { $0.timestamp.isFinite && $0.timestamp >= 0 && $0.timestamp <= duration && !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.sorted { $0.timestamp < $1.timestamp }
    }
    static func near(_ time: TimeInterval, annotations: [ForensicAnnotation], tolerance: TimeInterval = 0.25) -> [ForensicAnnotation] {
        annotations.filter { abs($0.timestamp - time) <= max(0, tolerance) }.sorted { abs($0.timestamp-time) < abs($1.timestamp-time) }
    }
}

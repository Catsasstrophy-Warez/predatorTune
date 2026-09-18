import Foundation

enum PersistenceHealthSeverity: String, Codable { case healthy, warning, error }

struct PersistenceIssue: Identifiable, Codable, Equatable {
    let id: UUID
    let severity: PersistenceHealthSeverity
    let domain: String
    let recordID: String?
    let message: String
    let occurredAt: Date
    init(severity: PersistenceHealthSeverity, domain: String, recordID: String? = nil, message: String) {
        self.id = UUID(); self.severity = severity; self.domain = domain; self.recordID = recordID; self.message = message; self.occurredAt = .now
    }
}

struct PersistenceHealthSnapshot: Codable, Equatable {
    let issues: [PersistenceIssue]
    var hasErrors: Bool { issues.contains { $0.severity == .error } }
    var summary: String { hasErrors ? "Persistence errors detected" : issues.isEmpty ? "Healthy" : "Persistence warnings detected" }
}

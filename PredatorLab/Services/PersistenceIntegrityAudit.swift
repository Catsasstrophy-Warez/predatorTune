import Foundation

struct PersistenceIntegrityFinding: Identifiable, Equatable {
    enum Severity: String { case warning, error }
    let id: String
    let severity: Severity
    let message: String
}

enum PersistenceIntegrityAudit {
    static func duplicateIDs<T>(_ values: [T], id: (T) -> UUID, kind: String) -> [PersistenceIntegrityFinding] {
        Dictionary(grouping: values, by: id).compactMap { key, group in
            guard group.count > 1 else { return nil }
            return .init(id: "duplicate.\(kind).\(key.uuidString)", severity: .error, message: "Duplicate durable identity in \(kind): \(key.uuidString)")
        }.sorted { $0.id < $1.id }
    }

    static func validateEnvelope(_ envelope: DurableEntityEnvelope) -> [PersistenceIntegrityFinding] {
        var result: [PersistenceIntegrityFinding] = []
        if DurableEntityKind(rawValue: envelope.kind) == nil {
            result.append(.init(id: "kind.\(envelope.id.uuidString)", severity: .error, message: "Unknown durable entity kind: \(envelope.kind)"))
        }
        if envelope.payload.isEmpty {
            result.append(.init(id: "payload.\(envelope.id.uuidString)", severity: .error, message: "Durable payload is empty."))
        }
        return result
    }

    static let boundary = "Static persistence integrity checks do not replace Core Data migration, interruption, disk-full, corruption, or crash-recovery tests on Apple runtime."
}

import Foundation

/// Platform-neutral migration fixture used to prove that archived Codable records preserve their
/// durable identity and vehicle ownership before Apple-runtime Core Data migration tests run.
struct MigrationFixture<T: Codable & Identifiable>: Codable where T.ID == UUID {
    let schema: Int
    let records: [T]
}

enum MigrationFixtureEngine {
    static let schema = 1
    static func encode<T: Codable & Identifiable>(_ records: [T]) throws -> Data where T.ID == UUID {
        try JSONEncoder().encode(MigrationFixture(schema: schema, records: records))
    }
    static func decode<T: Codable & Identifiable>(_ type: T.Type, data: Data) throws -> [T] where T.ID == UUID {
        let fixture = try JSONDecoder().decode(MigrationFixture<T>.self, from: data)
        guard fixture.schema == schema else { throw NSError(domain: "PredatorLab.MigrationFixture", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unsupported migration fixture schema \\(fixture.schema)."] ) }
        let ids = fixture.records.map(\.id)
        guard Set(ids).count == ids.count else { throw NSError(domain: "PredatorLab.MigrationFixture", code: 2, userInfo: [NSLocalizedDescriptionKey: "Duplicate durable IDs in migration fixture."]) }
        return fixture.records
    }
}

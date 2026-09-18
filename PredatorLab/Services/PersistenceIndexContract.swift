import Foundation

/// Documents the indexed lookup contract for the generic Core Data envelope while PredatorLab
/// migrates toward normalized domain entities. This is an optimization contract, not a claim that
/// payload fields inside JSON blobs are queryable by Core Data.
struct PersistenceIndexDescriptor: Identifiable, Equatable {
    let id: String
    let field: String
    let purpose: String
}

enum PersistenceIndexContract {
    static let envelopeIndexes: [PersistenceIndexDescriptor] = [
        .init(id: "kind", field: "kind", purpose: "Narrow fetches to one durable domain type."),
        .init(id: "vehicleID", field: "vehicleID", purpose: "Narrow vehicle-scoped history without decoding unrelated payloads."),
        .init(id: "updatedAt", field: "updatedAt", purpose: "Support newest-first history ordering."),
    ]
    static let payloadLimitation = "Fields inside the Codable payload remain opaque to Core Data. High-value query fields must become normalized attributes before server-scale or very large local datasets are considered production-ready."
    static func validatesRequiredIndexes(_ fields: Set<String>) -> Bool {
        Set(envelopeIndexes.map(\.field)).isSubset(of: fields)
    }
}

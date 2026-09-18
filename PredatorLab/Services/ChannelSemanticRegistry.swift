import Foundation

enum SemanticConfidence: String, Codable { case verified, provisional, unknown }
struct ChannelSemanticIdentity: Identifiable, Codable, Equatable {
    var id: String { canonical.rawValue }
    var canonical: CanonicalChannel
    var rawName: String?
    var unit: String?
    var confidence: SemanticConfidence
    var source: String?
    var warning: String?
}
enum ChannelSemanticRegistry {
    static func identity(for canonical: CanonicalChannel, in log: ParsedLogData) -> ChannelSemanticIdentity {
        let raw = ChannelResolver.resolve(canonical, in: log.channels)
        return .init(canonical:canonical, rawName:raw, unit:nil, confidence:.provisional, source:nil, warning:"Canonical mapping is a PredatorLab interpretation until the scanner parameter identity and units are independently verified.")
    }
}

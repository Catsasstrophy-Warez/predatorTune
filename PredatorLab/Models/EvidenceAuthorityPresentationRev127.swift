import Foundation
enum TraceEvidenceAuthorityRev127:String,Codable,Sendable {case measuredExported="MEASURED/EXPORTED",derived="DERIVED",candidate="CANDIDATE",unknown="UNKNOWN"}
struct TraceEvidenceBadgeRev127:Equatable,Sendable {let channel:String;let authority:TraceEvidenceAuthorityRev127;let boundary:String}
enum EvidenceAuthorityPresentationRev127 {
 static func badge(channel:String)->TraceEvidenceBadgeRev127{.init(channel:channel,authority:.measuredExported,boundary:"Value is present in the imported telemetry export. This does not prove sensor accuracy, source ECU semantics, or physical ground truth.")}
}

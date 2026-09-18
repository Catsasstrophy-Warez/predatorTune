import Foundation

enum EvidenceRelationRev131:String,Codable,Sendable {case supports,contradicts,missing,context}
struct StructuredForensicEvidenceRev131:Identifiable,Equatable,Sendable {
 let id:String;let sourceArtifactSHA256:String?;let episodeID:String;let hypothesisID:String?;let channel:String;let timestamp:Double;let numericValue:Double?;let stringValue:String?;let units:String;let authority:TraceEvidenceAuthorityRev127;let relation:EvidenceRelationRev131;let derivation:String?;let boundary:String
}
enum StructuredEvidenceBuilderRev131 {
 static func cursorRecords(log:ParsedLogData,sourceSHA256:String?,episode:GT500EpisodeRev122,cursor:Double,series:[TimelineSeriesRev117],units:[String:String])->[StructuredForensicEvidenceRev131] {
  let nearest=ForensicCursorCoordinatorRev118.update(cursor:cursor,series:series,events:[],workspace:.init()).nearest
  return nearest.keys.sorted().compactMap{name in guard let p=nearest[name] else{return nil};return .init(id:"\(episode.id)|\(name)|\(p.time)",sourceArtifactSHA256:sourceSHA256,episodeID:episode.id,hypothesisID:nil,channel:name,timestamp:p.time,numericValue:p.value,stringValue:nil,units:units[name] ?? "",authority:.measuredExported,relation:.context,derivation:nil,boundary:"Nearest exported observation at the forensic cursor; presence is context, not causal support.")}
 }
}

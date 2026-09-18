import Foundation

struct PersistedForensicCaseRev133:Codable,Equatable,Sendable {
 static let schemaVersion=3
 let schema:Int;let episodeID:String;let cursor:Double;let windowStart:Double;let windowEnd:Double;let selectedSignals:[String];let hypothesisNames:[String];let nextMeasurement:String?;let blockedCalculations:[String];let annotations:[String];let provenance:InvestigationProvenanceRev132;let evidence:[StructuredForensicEvidenceRev131];let createdAt:Date
}
enum ForensicCaseCodecRev133 {
 static func encode(_ value:PersistedForensicCaseRev133)throws->Data{let e=JSONEncoder();e.outputFormatting=[.sortedKeys];return try e.encode(value)}
 static func decode(_ data:Data)throws->PersistedForensicCaseRev133{try JSONDecoder().decode(PersistedForensicCaseRev133.self,from:data)}
 static func build(log:ParsedLogData,sourceSHA256:String?,context:EpisodeCursorContextRev123,signals:[String],thresholds:GT500EpisodeThresholdSetRev131,evidence:[StructuredForensicEvidenceRev131],baselineDesignationID:String?=nil,annotations:[String]=[])->PersistedForensicCaseRev133 {
  .init(schema:3,episodeID:context.episode.id,cursor:context.cursor,windowStart:context.windowStart,windowEnd:context.windowEnd,selectedSignals:signals,hypothesisNames:context.investigation.hypotheses.map(\.name),nextMeasurement:context.investigation.nextMeasurement?.measurement,blockedCalculations:context.investigation.blockedCalculations,annotations:annotations,provenance:.init(sourceSHA256:sourceSHA256,sourceFilename:log.filename,thresholds:thresholds,evidenceIDs:evidence.map(\.id),baselineDesignationID:baselineDesignationID,boundary:"Source hash establishes byte identity when present. Embedded evidence preserves the observations used by this case; neither establishes diagnosis truth."),evidence:evidence,createdAt:.now)
 }
}

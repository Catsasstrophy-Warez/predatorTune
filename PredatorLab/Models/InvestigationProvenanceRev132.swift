import Foundation

struct InvestigationProvenanceRev132:Codable,Equatable,Sendable {
 let sourceSHA256:String?;let sourceFilename:String;let thresholds:GT500EpisodeThresholdSetRev131;let evidenceIDs:[String];let baselineDesignationID:String?
 let boundary:String
}
struct PersistedForensicCaseRev132:Codable,Equatable,Sendable {
 let schema:Int;let episodeID:String;let cursor:Double;let windowStart:Double;let windowEnd:Double;let selectedSignals:[String]
 let hypothesisNames:[String];let nextMeasurement:String?;let blockedCalculations:[String];let annotations:[String];let provenance:InvestigationProvenanceRev132
 static let schemaVersion=2
}
enum ForensicCaseBuilderRev132 {
 static func build(log:ParsedLogData,sourceSHA256:String?,context:EpisodeCursorContextRev123,signals:[String],thresholds:GT500EpisodeThresholdSetRev131,evidence:[StructuredForensicEvidenceRev131],baselineDesignationID:String?=nil,annotations:[String]=[])->PersistedForensicCaseRev132 {
  .init(schema:2,episodeID:context.episode.id,cursor:context.cursor,windowStart:context.windowStart,windowEnd:context.windowEnd,selectedSignals:signals,hypothesisNames:context.investigation.hypotheses.map(\.name),nextMeasurement:context.investigation.nextMeasurement?.measurement,blockedCalculations:context.investigation.blockedCalculations,annotations:annotations,provenance:.init(sourceSHA256:sourceSHA256,sourceFilename:log.filename,thresholds:thresholds,evidenceIDs:evidence.map(\.id),baselineDesignationID:baselineDesignationID,boundary:"Source hash establishes byte identity when present; thresholds and evidence retain their own authority. A persisted case is an investigation record, not proof of diagnosis."))
 }
}

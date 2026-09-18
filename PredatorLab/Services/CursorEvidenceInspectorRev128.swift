import Foundation
struct CursorMeasurementRev128:Identifiable,Equatable,Sendable {
 let id:String;let value:Double;let unit:String;let authority:TraceEvidenceAuthorityRev127;let time:Double;let deltaFromEpisodePeak:Double?
}
struct CursorEvidenceInspectorRev128:Equatable,Sendable {
 let cursor:Double;let measurements:[CursorMeasurementRev128];let episodeID:String;let boundary:String
}
enum CursorEvidenceInspectorEngineRev128 {
 static func inspect(cursor:Double,episode:GT500EpisodeRev122,series:[TimelineSeriesRev117],units:[String:String])->CursorEvidenceInspectorRev128 {
  let nearest=ForensicCursorCoordinatorRev118.update(cursor:cursor,series:series,events:[],workspace:.init()).nearest
  let peak=ForensicCursorCoordinatorRev118.update(cursor:episode.peakTime,series:series,events:[],workspace:.init()).nearest
  let rows=nearest.keys.sorted().compactMap{name->CursorMeasurementRev128? in
   guard let p=nearest[name] else{return nil}
   return .init(id:name,value:p.value,unit:units[name] ?? "",authority:.measuredExported,time:p.time,deltaFromEpisodePeak:peak[name].map{p.value-$0.value})
  }
  return .init(cursor:cursor,measurements:rows,episodeID:episode.id,boundary:"Cursor measurements are nearest exported samples. Deltas are derived against the selected episode peak and are not causal attribution.")
 }
}

import Foundation
enum InvestigationAutosaveLocationRev128 {
 static func directory(fileManager:FileManager = .default)->URL {
  let base=fileManager.urls(for:.applicationSupportDirectory,in:.userDomainMask).first ?? fileManager.temporaryDirectory
  return base.appendingPathComponent("PredatorLab/Investigations",isDirectory:true)
 }
}
enum InvestigationLiveSaveRev128 {
 static func save(episode:GT500EpisodeRev122,viewport:TimelineViewportRev127,series:[TimelineSeriesRev117],selectedSignals:[String],annotations:[String]=[])throws {
  let base=ForensicEpisodeWorkspaceRev123.select(episode,series:series)
  let nearest=ForensicCursorCoordinatorRev118.update(cursor:viewport.cursor,series:series,events:[],workspace:.init()).nearest
  let context=EpisodeCursorContextRev123(episode:base.episode,investigation:base.investigation,cursor:viewport.cursor,windowStart:viewport.start,windowEnd:viewport.end,nearest:nearest,evidenceBoundary:base.evidenceBoundary)
  try InvestigationAutosaveRev126(directory:InvestigationAutosaveLocationRev128.directory()).save(context:context,signals:selectedSignals,annotations:annotations)
 }
}

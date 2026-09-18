import Foundation

struct InvestigationResumeStateRev126:Codable,Equatable,Sendable {let lastEpisodeID:String;let savedAt:Date}
final class InvestigationAutosaveRev126 {
 let store:InvestigationStoreRev124;let resumeURL:URL
 init(directory:URL){store = .init(directory:directory);resumeURL=directory.appendingPathComponent("resume.json")}
 func save(context:EpisodeCursorContextRev123,signals:[String],baselineID:String?=nil,annotations:[String]=[])throws {
  let snapshot=InvestigationSnapshotRev123(context:context,selectedSignals:signals,baselineID:baselineID,annotations:annotations);_ = try store.save(snapshot)
  let r=InvestigationResumeStateRev126(lastEpisodeID:context.episode.id,savedAt:.now);try JSONEncoder().encode(r).write(to:resumeURL,options:.atomic)
 }
 func resume()throws->InvestigationSnapshotRev123?{guard FileManager.default.fileExists(atPath:resumeURL.path) else{return nil};let r=try JSONDecoder().decode(InvestigationResumeStateRev126.self,from:Data(contentsOf:resumeURL));return try store.load(episodeID:r.lastEpisodeID)}
}

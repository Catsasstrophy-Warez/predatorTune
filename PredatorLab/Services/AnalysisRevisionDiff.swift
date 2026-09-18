import Foundation

struct AnalysisEngineChange: Identifiable, Equatable { let id:String; let field:String; let before:String; let after:String }
enum AnalysisRevisionDiffEngine {
    static func changes(from old:AnalysisRevision, to new:AnalysisRevision)->[AnalysisEngineChange] {
        let pairs:[(String,String,String)] = [
            ("Parser",old.engine.parser,new.engine.parser), ("Channel Resolver",old.engine.channelResolver,new.engine.channelResolver),
            ("Event Detector",old.engine.eventDetector,new.engine.eventDetector), ("Evidence Engine",old.engine.evidenceEngine,new.engine.evidenceEngine),
            ("Reasoning Engine",old.engine.reasoningEngine,new.engine.reasoningEngine), ("Technical Library",old.engine.technicalLibrary,new.engine.technicalLibrary)]
        return pairs.compactMap { $0.1 == $0.2 ? nil : .init(id:$0.0,field:$0.0,before:$0.1,after:$0.2) }
    }
}

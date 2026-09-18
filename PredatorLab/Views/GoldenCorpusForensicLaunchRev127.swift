import SwiftUI
struct GoldenCorpusForensicLaunchRev127:View {
 @State private var parsed:ParsedLogData?;@State private var error:String?
 var body:some View{NavigationStack{Group{
  if let parsed{PLIntegratedForensicSessionRev125(log:parsed)}
  else if let error{Text(error).padding()}
  else{ProgressView("Loading deterministic GT500 corpus…").task{do{guard let u=GoldenCorpusUITestModeRev127.fixtureURL() else{throw CocoaError(.fileNoSuchFile)};parsed=try CSVLogParser.parseHPTunerCSV(fileURL:u)}catch{self.error=error.localizedDescription}}}
 }.accessibilityIdentifier("goldenCorpus.root")}}
}

import SwiftUI
struct IntegratedForensicLogLoaderRev125:View {
 let log:ImportedLog
 @EnvironmentObject var dataRepository:DataRepository
 @State private var parsed:ParsedLogData?
 @State private var error:String?
 var body:some View{Group{
  if let parsed{PLIntegratedForensicSessionRev125(log:parsed)}
  else if let error{VStack(spacing:10){Image(systemName:"exclamationmark.triangle").font(.largeTitle).foregroundStyle(.plWarning);Text("Unable to open forensic session").font(.headline);Text(error).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)}.padding()}
  else{ProgressView("Loading forensic evidence…").task{do{parsed=try dataRepository.reloadDataset(for:log)}catch{self.error=error.localizedDescription}}}
 }}
}

import SwiftUI
struct PLRepositoryHealthRev129:View {
 let issueCount:Int
 var body:some View{HStack(spacing:5){Image(systemName:issueCount==0 ? "checkmark.shield":"exclamationmark.triangle");Text(issueCount==0 ? "PERSISTENCE HEALTHY":"PERSISTENCE ISSUES \(issueCount)").font(.system(size:7,weight:.bold,design:.monospaced))}.accessibilityIdentifier("repository.health")}
}

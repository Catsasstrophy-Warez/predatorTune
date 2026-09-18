import SwiftUI

struct ReanalysisHistoryView: View {
    let log: ImportedLog
    var body: some View {
        List {
            Section("Source Evidence") {
                LabeledContent("File", value: log.filename)
                LabeledContent("SHA-256", value: log.sourceSHA256 ?? "Not recorded")
            }
            Section("Analysis Lineage") {
                if let revisions=log.analysisRevisions, !revisions.isEmpty {
                    ForEach(revisions.sorted{$0.generatedAt > $1.generatedAt}) { revision in
                        VStack(alignment:.leading,spacing:5) {
                            Text(revision.reason).font(.headline)
                            Text(revision.generatedAt.formatted()).font(.caption).foregroundStyle(.secondary)
                            Text("Parser \(revision.engine.parser) • Resolver \(revision.engine.channelResolver) • Evidence \(revision.engine.evidenceEngine) • Reasoning \(revision.engine.reasoningEngine)").font(.caption2).foregroundStyle(.secondary)
                            if revision.engine != .current { Label("Historical interpretation", systemImage:"clock.arrow.circlepath").font(.caption).foregroundStyle(.orange) }
                            else { Label("Current engine", systemImage:"checkmark.seal").font(.caption).foregroundStyle(.green) }
                        }.padding(.vertical,4)
                    }
                } else { Text("No explicit analysis revision history is stored for this log.").foregroundStyle(.secondary) }
            }
            if let revisions=log.analysisRevisions?.sorted(by:{$0.generatedAt < $1.generatedAt}), revisions.count >= 2 {
                let old=revisions[revisions.count-2], new=revisions[revisions.count-1], changes=AnalysisRevisionDiffEngine.changes(from:old,to:new)
                Section("What Changed in the Analysis Engine") {
                    if changes.isEmpty { Text("The two latest revisions used the same recorded engine versions.").foregroundStyle(.secondary) }
                    else { ForEach(changes) { change in VStack(alignment:.leading){Text(change.field).font(.headline);Text("\(change.before) → \(change.after)").font(.caption).foregroundStyle(.secondary)} } }
                    Text("Engine-version changes explain which analysis machinery changed. They do not, by themselves, prove that a diagnostic conclusion changed.").font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Interpretation Boundary") { Text("Reanalysis creates a new interpretation lineage entry. It never rewrites the original CSV evidence or its source hash.") }
        }.navigationTitle("Analysis History")
    }
}

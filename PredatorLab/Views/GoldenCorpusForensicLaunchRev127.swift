import SwiftUI

/// App root when launched with `--predatorlab-golden-corpus` (deterministic UI tests).
struct GoldenCorpusForensicLaunchRev127: View {
    var body: some View {
        NavigationStack { GoldenCorpusSessionView() }
            .accessibilityIdentifier("goldenCorpus.root")
    }
}

/// Opens the bundled reference HP Tuners export in the log timeline, so the forensic workflow
/// can be explored without importing a log first.
struct GoldenCorpusSessionView: View {
    @State private var model: LogTimelineModel?
    @State private var error: String?

    var body: some View {
        Group {
            if let model {
                LogTimelineView(model: model)
            } else if let error {
                PLEmptyState(icon: "exclamationmark.triangle", title: "Reference log unavailable", message: error)
                    .padding()
            } else {
                PLLoadingCard(title: "Loading reference GT500 log", message: GoldenCorpusUITestModeRev127.boundary)
                    .padding()
                    .task { await load() }
            }
        }
        .navigationTitle("Reference Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func load() async {
        do {
            guard let url = GoldenCorpusUITestModeRev127.fixtureURL() else { throw CocoaError(.fileNoSuchFile) }
            model = try await Task.detached(priority: .userInitiated) {
                let log = try CSVLogParser.parseHPTunerCSV(fileURL: url)
                return LogTimelineModel(log: log, events: LogEventDetector.detectAllEvents(logData: log), pulls: PullAnalyzer.analyze(log))
            }.value
        } catch {
            self.error = error.localizedDescription
        }
    }
}

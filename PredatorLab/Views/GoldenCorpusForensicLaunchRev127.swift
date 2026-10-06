import SwiftUI

/// App root when launched with `--predatorlab-golden-corpus` (deterministic UI tests).
struct GoldenCorpusForensicLaunchRev127: View {
    var body: some View {
        NavigationStack { GoldenCorpusSessionView() }
            .accessibilityIdentifier("goldenCorpus.root")
    }
}

/// Opens the bundled reference HP Tuners export in the unified forensic session, so the
/// full forensic workflow can be explored without importing a log first.
struct GoldenCorpusSessionView: View {
    @State private var parsed: ParsedLogData?
    @State private var error: String?

    var body: some View {
        Group {
            if let parsed {
                PLIntegratedForensicSessionRev125(log: parsed)
            } else if let error {
                PLEmptyState(icon: "exclamationmark.triangle", title: "Reference log unavailable", message: error)
                    .padding()
            } else {
                PLLoadingCard(title: "Loading reference GT500 log", message: GoldenCorpusUITestModeRev127.boundary)
                    .padding()
                    .task { load() }
            }
        }
        .navigationTitle("Reference Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func load() {
        do {
            guard let url = GoldenCorpusUITestModeRev127.fixtureURL() else { throw CocoaError(.fileNoSuchFile) }
            parsed = try CSVLogParser.parseHPTunerCSV(fileURL: url)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

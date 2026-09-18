import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.
struct GT500RealEvidenceRev76View: View {
    private let bundle = GT500RealEvidenceFactoryRev76.bundle
    var body: some View {
        List {
            Section("Real Evidence Bundle") {
                ForEach(bundle.artifacts) { a in
                    VStack(alignment:.leading,spacing:4) {
                        Text(a.filename).font(.headline)
                        Text(a.role).font(.caption)
                        Text(a.boundary).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            Section("Observed Findings") { ForEach(bundle.observedLogFacts,id:\.self) { Text($0).font(.caption) } }
            Section("Claims Still Requiring Promotion") { ForEach(bundle.researchClaimsRequiringPromotion,id:\.self) { Label($0,systemImage:"exclamationmark.shield") } }
            Section("Next Evidence Actions") { ForEach(bundle.nextActions,id:\.self) { Label($0,systemImage:"arrow.right.circle") } }
            Section("Boundary") { Text(bundle.boundary).font(.caption).foregroundStyle(.secondary) }
        }.navigationTitle("GT500 Real Evidence")
    }
}

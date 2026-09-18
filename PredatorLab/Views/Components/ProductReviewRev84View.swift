import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct ProductReviewRev84View: View {
    private let status = EvidenceExecutionStatusRev84(xcodeBuildVerified:false,persistenceRoundTripVerified:false,hplRPMAdmitted:false,configBCompiled:false,mpvi4Commissioned:false,acquisitionBenchmarkCompleted:false,fuelExperimentCompleted:false,replayValidated:false)
    var body: some View {
        List {
            Section("Execution gates") {
                LabeledContent("Verified", value:"\(status.completedCount) / 8")
                Text(status.productionReady ? "Production evidence gates complete" : "Architecture is ahead of physical/runtime validation. Do not promote readiness until the gates are actually executed.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Total app review") {
                ForEach(ProductReviewRev84.findings) { item in
                    VStack(alignment:.leading, spacing:4) {
                        Text("\(item.severity.rawValue.uppercased()) · \(item.area)").font(.caption).foregroundStyle(item.severity == .blocker ? .red : .secondary)
                        Text(item.finding).font(.headline)
                        Text(item.recommendation).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section("Recommended order") {
                Text("1. Xcode build and Apple-runtime persistence\n2. Native HPL RPM admission\n3. Production-GT500 Scanner semantic capture\n4. MPVI4 commissioning\n5. Tethered vs standalone benchmark\n6. No-tune-change fuel experiment\n7. sep2 interactive Replay + Why engine\n8. Repository/domain refactor after behavior is proven")
            }
        }.navigationTitle("App Review & Next Actions")
    }
}

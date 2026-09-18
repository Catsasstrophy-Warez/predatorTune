import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone (SwiftUI presentation layer for FordVCMSuiteIntelligenceRev63.swift; see that file's header for how the Rev63-66 Ford VCM Suite cluster relates internally).

struct FordVCMSuiteLabRev63View: View {
    private let capabilities = VCMSuitePublicCapabilityRegistry.records
    private let graph = FordTorqueArbitrationGraphBuilder.conceptual(controller:.gt500PCM)
    var body: some View {
        List {
            Section("Ford + VCM Suite Intelligence") {
                Text("PredatorLab separates what VCM Suite publicly documents from what a specific GT500 PCM/TR_C75 strategy actually means. Parameter exposure is never promoted into Ford truth automatically.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Documented VCM Suite capabilities") {
                ForEach(capabilities) { c in
                    VStack(alignment:.leading,spacing:4) {
                        Text(c.feature).font(.headline)
                        Text(c.documentedBehavior).font(.caption)
                        Text(c.gt500Boundary).font(.caption2).foregroundStyle(.secondary)
                    }.accessibilityElement(children:.combine)
                }
            }
            Section("GT500 torque-arbitration research scaffold") {
                ForEach(graph.nodes) { node in
                    HStack { Text(node.title); Spacer(); Text(node.verifiedForStrategy ? "Reviewed" : "Research").font(.caption).foregroundStyle(.secondary) }
                }
                Text(graph.boundary).font(.caption2).foregroundStyle(.secondary)
            }
            Section("Validation doctrine") {
                Text("Baseline → controlled change → comparable test → synchronized evidence → repeated result → envelope-limited verdict. A faster pull or lap is not automatic proof of a better calibration.")
                    .font(.caption)
            }
        }.navigationTitle("Ford + VCM Suite")
    }
}

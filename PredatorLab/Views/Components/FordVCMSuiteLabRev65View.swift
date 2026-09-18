import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone (SwiftUI presentation layer for FordVCMSuiteIntelligenceRev65.swift; see that file's header for how the Rev63-66 Ford VCM Suite cluster relates internally).

struct FordVCMSuiteLabRev65View: View {
    private let debt = FordCalibrationTruthDebtHeatmapEngine.build(observations: [], scannerReviews: [])
    var body: some View {
        List {
            Section("Calibration Truth Debt Heatmap") {
                ForEach(debt.cells) { c in
                    VStack(alignment:.leading,spacing:4) {
                        HStack { Text(c.title).font(.headline); Spacer(); Text("P\(c.priority)").font(.caption.monospacedDigit()) }
                        Text("\(c.unresolvedQuestions) unresolved research questions")
                        if !c.missingArtifactIDs.isEmpty { Text("Evidence targets: \(c.missingArtifactIDs.joined(separator: ", "))").font(.caption).foregroundStyle(.secondary) }
                    }
                }
                Text(debt.boundary).font(.caption).foregroundStyle(.secondary)
            }
            Section("Strategy-Aware Navigator Capture") {
                Text("Imports a user-authored VCM Editor Parameter Navigator capture as path/name/type/units/axes/description/parameter-ID/locator records. It does not decode proprietary HPT binaries.")
                Text("Identity key: controller + OS + strategy + parameter ID + Navigator path + type + units + axes.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Scanner Semantic Resolver") {
                Text("A Scanner signal must retain Parameter ID, source, transform, controller, strategy and exact evidence locator before it can bind to a canonical PredatorLab signal.")
                Text("Fallback/override definition settings are provenance-sensitive and must not be treated as invisible metadata.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Torque Evidence Graph") {
                Text("Driver demand → torque request/limit → throttle/air → spark → fuel/lambda → thermal context")
                Text("Only reviewed observed nodes are lit. Edges remain hypotheses until independently supported for the exact Ford strategy.").font(.caption).foregroundStyle(.secondary)
            }
            Section("GT500 Experiment Contract") {
                Text("Build revision + calibration fingerprint + reviewed Scanner semantics + required channel purposes + diagnostic readiness are compiled before a high-load experiment is admitted.")
                Text("No stock values, safe limits, or universal tuning numbers are generated.").font(.caption).foregroundStyle(.secondary)
            }
        }.navigationTitle("VCM Evidence Lab")
    }
}

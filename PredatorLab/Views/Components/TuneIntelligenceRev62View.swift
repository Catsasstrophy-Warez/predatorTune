import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct TuneIntelligenceRev62View: View {
    private let debt = CalibrationTruthDebtEngine.rank(records: GT500CalibrationSemanticRegistry.seeds, evidence: [])
    var body: some View {
        List {
            Section("Calibration Truth Debt") {
                ForEach(debt.prefix(6)) { item in
                    VStack(alignment:.leading,spacing:4) {
                        Text(item.semanticID).font(.headline)
                        Text("\(item.controller.rawValue) • research priority \(item.score)").font(.caption)
                        Text(item.blockers.joined(separator:" • ")).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Text("Priority is not tune quality or truth probability.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Tune Strategy Planner") {
                Text("Verified Scanner semantics feed competing control hypotheses. Missing signals produce a next-measurement request before any calibration region is surfaced for review.")
            }
            Section("Straight-Line / Drag Isolation") {
                Text("Comparable acceleration windows can be isolated from synchronized TrackAddict evidence. Driver inputs, build, fuel, thermal state, PCM/TCM and Scanner semantics pass through the comparison firewall before attribution.")
                Text("A quicker interval never proves the calibration caused the gain.").font(.caption).foregroundStyle(.secondary)
            }
            Section("TDN Tune Evidence Replay") {
                Text("Read → sync → calibration → flash → Scanner contract → HPL → TrackAddict → Flight Recorder → analysis → validation → decision")
                Text("Missing stages stay visible instead of being inferred from filenames or timestamps.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Semantic Promotion Gate") {
                Text("Exact controller, parameter identity, strategy applicability, evidence locator and completed review are required before a calibration semantic can be admitted. GT500 PCM, TR_C75, TC-298B and MG1CS036 remain isolated lineages.")
            }
        }.navigationTitle("Tune Intelligence 2.0")
    }
}

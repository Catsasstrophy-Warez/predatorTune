import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.
struct MPVI4EvidenceExecutionRev75View: View {
    @State private var profile:MPVI4ExperimentProfileKindRev75 = .baselinePull
    private var selected:MPVI4ExperimentProfileRev75 { MPVI4ExperimentProfileCatalogRev75.profiles.first{$0.kind == profile}! }
    var body: some View { List {
        Section("Experiment Compiler") { Picker("GT500 experiment",selection:$profile){ForEach(MPVI4ExperimentProfileKindRev75.allCases,id:\.self){Text($0.rawValue).tag($0)}}; Text(selected.title).font(.headline); Text(selected.conclusionBoundary).font(.caption).foregroundStyle(.secondary) }
        Section("Required Scanner semantics") { ForEach(selected.requiredSemantics,id:\.self){Label($0,systemImage:"checklist")}; if !selected.optionalSemantics.isEmpty { Text("Optional/context: \(selected.optionalSemantics.joined(separator: ", "))").font(.caption) } }
        Section("Deployment") { ForEach(selected.deploymentChecks,id:\.self){Text("• \($0)")} }
        Section("Telemetry evidence chain") { Text("MPVI4 → standalone session → Wi-Fi/hotspot upload → VCM Telemetry session → exported/parsed evidence → semantic review → experiment reconstruction. Upload success never upgrades semantic authority.") }
        Section("Real-evidence boundary") { Text("PredatorLab can ingest user-exported Scanner CSV/XML and recorded provenance. Direct MPVI4 communications, private VCM Telemetry API access, universal/proprietary HPL decoding, and calibration flashing are not implemented in this build. Artifact-specific HPL research decoding remains experimental and evidence-bounded.").font(.caption).foregroundStyle(.secondary) }
    }.navigationTitle("MPVI4 Evidence Execution") }
}

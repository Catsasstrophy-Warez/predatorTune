import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.
struct FlagshipIntegrationRev82View: View {
    private let compiled = ConfigBCompilerRev82.compile(ConfigBSeedRev82.requirements)
    var body: some View {
        List {
            Section("Acquire → Verify → Investigate → Experiment → Validate") { ForEach(PredatorLabTuneFlowRev82.allCases,id:\.self){ Label($0.rawValue,systemImage:"chevron.right.circle") } }
            Section("Native HPL Correlation Harness") { ForEach(HPLCorrelationHarnessRev82.requiredSignals,id:\.self){ Label($0,systemImage:"waveform.path.ecg") }; Text("Admission requires waveform chronology, timing, XML identity and units. Coincidental binary values do not count.").font(.caption).foregroundStyle(.secondary) }
            Section("Config B Compiler") { ForEach(compiled.requirements){ r in VStack(alignment:.leading){ Text(r.role).font(.headline); Text(r.why); Text(r.compilable ? "Certified for compilation" : "Semantic certification required").font(.caption).foregroundStyle(r.compilable ? .green : .orange) } }; Text(compiled.boundary).font(.caption).foregroundStyle(.secondary) }
            Section("MPVI4 Commissioning") { ForEach(MPVI4CommissioningRev82.steps){ s in VStack(alignment:.leading){ Text(s.step).font(.headline); Text(s.evidence).font(.caption); if s.blocksExperiment { Text("Blocks experiment until resolved").font(.caption2).foregroundStyle(.orange) } } } }
            Section("VCM Telemetry Inspector") { Text("Tracks local recording, connectivity, upload, browser review, sharing/export and PredatorLab import independently from channel semantics, acquisition quality and experiment comparability.") }
            Section("Evidence boundary") { Text("Telemetry transport, an HPL parse, a clean graph, or a calibration change never independently proves a diagnosis. The flagship sep2 case remains hypothesis-driven until the discriminating evidence is actually acquired.").font(.caption) }
        }.navigationTitle("Flagship Evidence Lab")
    }
}

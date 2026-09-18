import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct TuneIntelligenceRev61View: View {
    var body: some View {
        List {
            Section("Calibration Experiment Reconstruction 2.0") {
                Label("Persistent Vehicle + Build + PCM + TCM experiment binding",systemImage:"point.3.connected.trianglepath.dotted")
                Label("HPT/HPL/Scanner XML/TrackAddict artifact lineage",systemImage:"doc.on.doc")
                Label("Measured multi-clock synchronization before spatial fusion",systemImage:"clock.arrow.2.circlepath")
            }
            Section("Track Session Intelligence") {
                Text("Circuit, Segment, Drag, Raw and Trail contexts remain distinct. Imported/reviewed lap and sector boundaries drive summaries; PredatorLab does not invent track geometry from a filename.")
                Text("Spatial Flight Recorder anchors can bind a synchronized event to the nearest GPS/speed/RPM sample within an explicit tolerance.").font(.caption).foregroundStyle(.secondary)
            }
            Section("TDN Engineering Timeline") {
                Text("Vehicle Read → Synchronized → Tune Received → Flash → Log → Revision → Accepted/Rejected")
                Text("Workflow lineage is evidence, not proof of server state or tuner authorship.").font(.caption).foregroundStyle(.secondary)
            }
            Section("GT500 / TR_C75 Semantic Registry") {
                ForEach(GT500CalibrationSemanticRegistry.seeds) { r in
                    VStack(alignment:.leading) { Text(r.displayName).font(.headline); Text("\(r.controller.rawValue) • \(r.status.rawValue)").font(.caption); Text(r.boundary).font(.caption2).foregroundStyle(.secondary) }
                }
            }
            Section("Comparison Firewall") {
                Text("Build, PCM, scanner semantics and fuel mismatches can hard-block experiment comparison. Thermal state, TCM and test-mode differences are surfaced separately. Comparability is never a tune-quality score.")
            }
        }.navigationTitle("Tune Intelligence")
    }
}

import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.
struct HPLCorrelationTelemetryRev81View: View {
    var body: some View {
        List {
            Section("Native HPL Rosetta Plan") { Text(HPLRosettaPlanRev81.rpm.reason); ForEach(HPLRosettaPlanRev81.rpm.nextSignals,id:\.self){ Label($0,systemImage:"waveform.path.ecg") } }
            Section("VCM Telemetry: documented workflow") { ForEach(VCMTelemetryAtlasRev81.facts) { f in VStack(alignment:.leading,spacing:5){ Text(f.area).font(.headline); Text(f.fact); Text(f.evidenceBoundary).font(.caption).foregroundStyle(.secondary); Text(f.source).font(.caption2).foregroundStyle(.secondary) } } }
            Section("PredatorLab Telemetry lifecycle") { ForEach(VCMTelemetryStateRev81.allCases,id:\.self){ Text($0.rawValue) } }
            Section("Associated VCM Suite capabilities") { ForEach(VCMSuiteAssociatedAtlasRev81.items){ i in VStack(alignment:.leading){ Text(i.name).font(.headline); Text(i.documentedBehavior); Text(i.predatorLabUse).font(.caption).foregroundStyle(.secondary) } } }
            Section("Truth boundary") { Text("Upload, browser review, sharing, a clean graph, or an HPL/CSV match never independently proves a physical diagnosis or calibration conclusion. Strong conclusions still require semantic verification, acquisition quality, build/calibration comparability and appropriate experiment evidence.").font(.caption) }
        }.navigationTitle("HPL + VCM Telemetry")
    }
}

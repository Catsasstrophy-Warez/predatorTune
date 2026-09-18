import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.
struct HPLDifferentialLabRev80View: View {
    var body: some View { List {
        Section("Native HPL Differential Laboratory") { Text("Use RPM as the Rosetta signal, then cross-certify fuel pressure and the sep2 protection/shift chronology against Scanner XML and CSV. No proprietary universal HPL format is claimed.") }
        Section("Binary experiment") { ForEach(Array(HPLBinaryExperimentProtocolRev80.native.phases.enumerated()),id:\.offset){ i,p in Text("\(i+1). \(p)") } }
        Section("Admission gate") { Text("A candidate native channel must agree on identity, XML provenance, interval, timing, numeric chronology and engineering units before strong admission.") }
        Section("VCM Suite evidence rules") { ForEach(VCMSuiteEvidenceAtlasRev80.rules){ r in VStack(alignment:.leading,spacing:4){ Text(r.topic).font(.headline); Text(r.documentedFact); Text("PredatorLab: \(r.predatorLabRule)").font(.caption) } } }
    }.navigationTitle("HPL Differential Lab") }
}

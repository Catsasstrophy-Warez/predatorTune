import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct EvidenceInspectorRev85: View {
    let cursor: ForensicCursorRev85
    let status: ForensicEvidenceStatusRev85
    var body: some View {
        List {
            Section("Cursor") {
                LabeledContent("Time", value: cursor.time.map { String(format: "T+%.3f s", $0) } ?? "Not selected")
                LabeledContent("Channel", value: cursor.channelID ?? "Not selected")
                LabeledContent("Evidence", value: cursor.evidenceID ?? "Not selected")
                LabeledContent("Hypothesis", value: cursor.hypothesisID ?? "Not selected")
            }
            Section("Evidence state") {
                LabeledContent("Byte identity", value: status.identity.rawValue.capitalized)
                LabeledContent("Semantics", value: status.semanticsCertified ? "Certified" : "Not certified")
                LabeledContent("Measurement", value: status.measurement.rawValue.capitalized)
                LabeledContent("Interpretation", value: status.interpretation.rawValue.capitalized)
            }
            Section("Why?") {
                Text("PredatorLab keeps byte identity, semantic certification, measurement validity, and interpretation support separate. A matching hash proves identity, not engineering truth.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Why? / Evidence")
    }
}

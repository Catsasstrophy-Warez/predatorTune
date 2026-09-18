import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone (SwiftUI presentation layer for FordVCMSuiteIntelligenceRev64.swift; see that file's header for how the Rev63-66 Ford VCM Suite cluster relates internally).

struct FordVCMSuiteLabRev64View: View {
    var body: some View {
        List {
            Section("GT500 / TR_C75 Research Atlas") {
                ForEach(FordGT500CalibrationResearchAtlas.domains) { d in
                    VStack(alignment:.leading,spacing:4) {
                        Text(d.title).font(.headline)
                        Text(d.controller.rawValue).font(.caption).foregroundStyle(.secondary)
                        Text(d.questions.first ?? "").font(.caption)
                    }
                }
            }
            Section("VCM Scanner Experiment Packs") {
                pack(GT500VCMChannelPackLibrary.highLoad)
                pack(GT500VCMChannelPackLibrary.trc75Shift)
            }
            Section("Controlled Experiments") {
                ForEach(FordTuneExperimentTemplateLibrary.templates) { t in
                    VStack(alignment:.leading,spacing:4) {
                        Text(t.title).font(.headline)
                        Text(t.goal)
                        Text(t.calibrationChangeRule).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section("Highest-Leverage VCM Evidence") {
                ForEach(FordVCMDefinitionAcquisitionMatrix.records.sorted{$0.priority > $1.priority}) { r in
                    VStack(alignment:.leading,spacing:3) {
                        Text("\(r.priority) · \(r.artifact)").font(.subheadline.weight(.semibold))
                        Text("Could unlock review: \(r.reviewUnlocks.joined(separator:", "))").font(.caption)
                        Text("Does not prove: \(r.doesNotProve.joined(separator:", "))").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section("Research Boundary") {
                Text("VCM Suite capability documentation tells PredatorLab what the tools can represent and preserve. Exact GT500/TR_C75 parameter identity, semantics, axes, stock values, and controller behavior remain strategy-specific evidence questions. No magic values are generated here.").font(.caption).foregroundStyle(.secondary)
            }
        }.navigationTitle("Ford VCM Research")
    }
    @ViewBuilder private func pack(_ p:VCMExperimentChannelPack) -> some View {
        VStack(alignment:.leading,spacing:4) {
            Text(p.title).font(.headline)
            Text("\(p.requirements.filter{$0.required}.count) required measurement purposes").font(.caption)
            Text(p.boundary).font(.caption).foregroundStyle(.secondary)
        }
    }
}

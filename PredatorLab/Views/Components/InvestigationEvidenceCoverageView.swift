import SwiftUI

struct InvestigationEvidenceCoverageView: View {
    let dataset: ParsedLogData
    var body: some View {
        List {
            Section("Investigation Evidence Readiness") {
                Text("PredatorLab checks whether each investigation has enough acquisition coverage before stronger reasoning is allowed. These acquisition thresholds are authored heuristics, not OEM diagnostic thresholds.").font(.caption).foregroundStyle(.secondary)
            }
            ForEach(InvestigationCatalog.all) { definition in
                let readiness=InvestigationEvidenceContracts.readiness(for:definition,log:dataset)
                Section(definition.title) {
                    LabeledContent("Readiness", value:"\(Int((readiness.score*100).rounded()))%")
                    LabeledContent("Strong inference", value:readiness.readyForStrongInference ? "Eligible" : "Blocked")
                    if let profile = ScannerAcquisitionProfiles.all.first(where: { $0.investigationID == definition.id }) {
                        NavigationLink("Scanner Acquisition Profile") { ScannerProfileDetailView(profile: profile) }
                    }
                    NavigationLink("Validation Experiment Plan") { ExperimentPlanDetailView(plan: ExperimentDesignEngine.plan(for: definition)) }
                    ForEach(readiness.criticalFailures,id:\.self){ Label($0,systemImage:"xmark.octagon").foregroundStyle(.red) }
                    ForEach(readiness.warnings,id:\.self){ Label($0,systemImage:"exclamationmark.triangle").foregroundStyle(.orange) }
                    if let hypotheses=definition.authoredHypotheses {
                        ForEach(hypotheses) { h in
                            VStack(alignment:.leading,spacing:4) { Text(h.title).font(.headline); Text(h.mechanism).font(.caption); Text("Next: \(h.nextMeasurements.first ?? "No authored next measurement")").font(.caption).foregroundStyle(.secondary); Text(h.evidenceBoundary).font(.caption2).foregroundStyle(.secondary) }.padding(.vertical,3)
                        }
                    }
                }
            }
        }.navigationTitle("Evidence Coverage")
    }
}


private struct ScannerProfileDetailView: View {
    let profile: ScannerAcquisitionProfile
    var body: some View { List {
        Section("Evidence Boundary") { ForEach(profile.notes,id: \.self) { Text($0).font(.caption) } }
        Section("Channels") { ForEach(profile.channels, id: \.channel) { item in
            VStack(alignment:.leading,spacing:4) {
                Text(MeasurementAtlas.entry(for:item.channel)?.title ?? item.channel.rawValue).font(.headline)
                Text("Target: \(item.desiredHz.map { String(format:"%.0f Hz",$0) } ?? "not specified") • \(item.critical ? "critical" : "recommended")").font(.caption)
                if item.semanticVerificationRequired { Label("Semantic verification required",systemImage:"exclamationmark.triangle").font(.caption).foregroundStyle(.orange) }
            }.padding(.vertical,3)
        } }
    } .navigationTitle(profile.title) }
}

private struct ExperimentPlanDetailView: View {
    let plan: ValidationPlan
    var body: some View { List {
        Section("Keep Constant") { ForEach(plan.keepConstant,id:\.self) { Text($0) } }
        Section("Designated Variables") { if plan.designatedVariables.isEmpty { Text("None selected yet. Record intended changes before the test.").foregroundStyle(.secondary) } else { ForEach(plan.designatedVariables,id:\.self) { Text($0) } } }
        Section("Required Evidence") { ForEach(plan.requiredChannels,id:\.self) { Text(MeasurementAtlas.entry(for:$0)?.title ?? $0.rawValue) } }
        Section("Success Criteria") { ForEach(plan.successCriteria,id:\.self) { Text($0) } }
        Section("Stop Criteria") { ForEach(plan.stopCriteria,id:\.self) { Label($0,systemImage:"stop.circle") } }
        Section("Interpretation Boundary") { Text(plan.evidenceBoundary).font(.caption) }
    }.navigationTitle("Experiment Plan") }
}

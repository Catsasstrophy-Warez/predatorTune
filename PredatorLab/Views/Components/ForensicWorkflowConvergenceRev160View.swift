import SwiftUI

struct ForensicAcquisitionPlanViewRev160: View {
    let plan: ForensicAcquisitionPlan
    var body: some View {
        PLVisualPanel(accent: .plWarning, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Label(plan.title, systemImage: "checklist.checked").font(.headline)
                Text(plan.authorityCeiling).font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(.plWarning)
                ForEach(Array(plan.items.enumerated()), id: \.element.id) { index, item in
                    HStack(alignment: .top, spacing: 9) {
                        Text(String(format: "%02d", index + 1)).font(.system(size: 10, weight: .black, design: .monospaced)).foregroundStyle(.plBoost)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.measurement).font(.caption.bold())
                            Text(item.rationale).font(.caption2).foregroundStyle(.plTextSecondary)
                            Text(item.requiredSemanticProof).font(.caption2).foregroundStyle(.plTextSecondary)
                            Text(item.state.rawValue.uppercased()).font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(.plWarning)
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("forensics.acquisitionPlan")
    }
}

struct HypothesisEvidenceLedgerViewRev160: View {
    let ledger: HypothesisEvidenceLedger
    var body: some View {
        PLVisualPanel(accent: .plWarning, padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(ledger.title).font(.headline)
                Text(ledger.evidenceSummary.uppercased()).font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(.plWarning)
                ledgerSection("SUPPORT", ledger.supporting, icon: "plus.circle")
                ledgerSection("CONTRADICT", ledger.contradicting, icon: "minus.circle")
                ledgerSection("MISSING", ledger.missing, icon: "questionmark.circle")
                ledgerSection("CONTEXT ONLY", ledger.contextOnly, icon: "info.circle")
                ledgerSection("WHAT WOULD FALSIFY IT?", ledger.falsificationTests, icon: "xmark.diamond")
                PLAuthorityBoundaryBanner(text: ledger.authorityCeiling)
            }
        }
    }
    @ViewBuilder private func ledgerSection(_ title: String, _ values: [String], icon: String) -> some View {
        if !values.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Label(title, systemImage: icon).font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(.plTextSecondary)
                ForEach(values, id: \.self) { Text("• \($0)").font(.caption2) }
            }
        }
    }
}

struct GoldenCorpusGuidedInvestigationViewRev160: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                PLCommandStrip(title: "Golden Corpus Guided Investigation", context: "Learn the evidence workflow using the frozen reference acquisition", accent: .plBoost, chips: [("GUIDED", "graduationcap", .plBoost)])
                ForEach(GoldenCorpusGuidedInvestigationRev160.steps) { step in
                    PLVisualPanel(accent: .plBoost, padding: 11) {
                        HStack(alignment: .top, spacing: 10) {
                            Text(String(format: "%02d", step.id)).font(.system(.headline, design: .monospaced).bold()).foregroundStyle(.plBoost)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.title).font(.headline)
                                Text(step.instruction).font(.caption)
                                Text(step.learningBoundary).font(.caption2).foregroundStyle(.plTextSecondary)
                            }
                        }
                    }
                }
            }.padding()
        }
        .accessibilityIdentifier("goldenCorpus.guidedInvestigation")
    }
}

import SwiftUI

struct TechnicalTruthDebtView: View {
    @ObservedObject var engine: TechnicalQueryEngine
    private var items: [TechnicalTruthDebtItem] { TechnicalTruthDebtEngine.rank(TechnicalTruthLedger.compile(engine: engine)) }
    private var summary: TechnicalTruthDebtSummary { TechnicalTruthDebtEngine.summary(items) }
    private var acquisition: [EvidenceAcquisitionImpact] { TruthDebtAcquisitionBridge.prioritize(entries: TechnicalTruthLedger.compile(engine: engine)) }
    var body: some View {
        List {
            Section("Verification debt") {
                Text(TechnicalTruthDebtEngine.boundary).font(.caption).foregroundStyle(.secondary)
                LabeledContent("Unresolved assertions", value:"\(summary.totalDebt)")
                LabeledContent("Diagnostic/safety priority", value:"\(summary.highConsequence)")
                LabeledContent("Missing sources", value:"\(summary.missingSources)")
                LabeledContent("Missing locators", value:"\(summary.missingLocators)")
                LabeledContent("Disputed", value:"\(summary.disputed)")
            }
            Section("Highest-leverage evidence") {
                Text(TruthDebtAcquisitionBridge.boundary).font(.caption).foregroundStyle(.secondary)
                ForEach(acquisition.prefix(9)) { impact in
                    VStack(alignment:.leading, spacing:4) {
                        HStack { Text(impact.request.domain.rawValue).font(.subheadline).fontWeight(.semibold); Spacer(); Text("\(impact.leverageScore)").monospacedDigit().font(.caption) }
                        Text(impact.request.exactNeed).font(.caption)
                        Text("Maps to \(impact.matchingTruthIDs.count) unresolved assertion(s) • debt \(impact.totalDebtScore)").font(.caption2).foregroundStyle(.secondary)
                        Text(impact.rationale).font(.caption2)
                    }.accessibilityIdentifier("truthDebt.acquisition.\(impact.id)")
                }
            }
            Section("Ranked queue") {
                ForEach(items.prefix(500)) { item in
                    VStack(alignment:.leading, spacing:4) {
                        HStack { Text(item.ownerTitle).font(.subheadline).fontWeight(.semibold); Spacer(); Text("\(item.score)").monospacedDigit().font(.caption) }
                        Text(item.statement).font(.caption)
                        Text("\(item.domain.rawValue.capitalized) • \(item.criticality.label) • \(item.disposition.rawValue)").font(.caption2).foregroundStyle(.secondary)
                        Text(item.action).font(.caption2)
                    }.accessibilityIdentifier("truthDebt.\(item.truthID)")
                }
            }
        }.navigationTitle("Truth Debt")
    }
}

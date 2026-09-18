import SwiftUI

struct TechnicalTruthLedgerView: View {
    @ObservedObject var engine: TechnicalQueryEngine
    @State private var query = ""
    @State private var domain: TechnicalTruthDomain?
    private var allEntries: [TechnicalTruthLedgerEntry] { TechnicalTruthLedger.compile(engine: engine) }
    private var entries: [TechnicalTruthLedgerEntry] {
        allEntries.filter { item in
            (domain == nil || item.domain == domain) && (query.isEmpty || item.ownerTitle.localizedCaseInsensitiveContains(query) || item.statement.localizedCaseInsensitiveContains(query) || (item.authoredValue?.localizedCaseInsensitiveContains(query) ?? false))
        }
    }
    private var summary: TechnicalTruthLedgerSummary { TechnicalTruthLedger.summary(allEntries) }

    var body: some View {
        List {
            Section("Truth inventory") {
                Text(TechnicalTruthLedger.boundary).font(.caption).foregroundStyle(.secondary)
                LabeledContent("Individual assertions", value:"\(summary.total)")
                LabeledContent("Verified", value:"\(summary.verified)")
                LabeledContent("Quarantined", value:"\(summary.quarantined)")
                LabeledContent("Disputed", value:"\(summary.disputed)")
                LabeledContent("Superseded", value:"\(summary.superseded)")
            }
            Section("Filter") {
                Picker("Domain", selection: Binding(get:{domain?.rawValue ?? "all"}, set:{domain = $0 == "all" ? nil : TechnicalTruthDomain(rawValue:$0)})) {
                    Text("All").tag("all")
                    ForEach(TechnicalTruthDomain.allCases, id:\.rawValue) { Text($0.rawValue.capitalized).tag($0.rawValue) }
                }
                TextField("Search assertions", text:$query).textInputAutocapitalization(.never)
            }
            Section("Assertions") {
                ForEach(entries.prefix(500)) { item in
                    NavigationLink { TechnicalTruthReviewView(entry: item) } label: {
                    VStack(alignment:.leading, spacing:4) {
                        HStack { Text(item.ownerTitle).font(.subheadline).fontWeight(.semibold); Spacer(); Text(item.disposition.rawValue).font(.caption) }
                        Text(item.statement).font(.caption)
                        if let value=item.authoredValue { Text("Authored: \(value) \(item.unit ?? "")").font(.caption2).monospacedDigit() }
                        Text("\(item.domain.rawValue.capitalized) • \(item.state.rawValue)").font(.caption2).foregroundStyle(.secondary)
                        if let locator=item.locator { Text("Locator: \(locator)").font(.caption2).foregroundStyle(.secondary) }
                        Text(item.boundary).font(.caption2).foregroundStyle(.secondary)
                    }.accessibilityIdentifier("truthLedger.\(item.id)")
                    }
                }
            }
        }.navigationTitle("Technical Truth Ledger").searchable(text:$query)
    }
}

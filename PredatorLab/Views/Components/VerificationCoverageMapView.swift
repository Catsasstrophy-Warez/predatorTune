import SwiftUI

struct VerificationCoverageMapView: View {
    @ObservedObject var engine: TechnicalQueryEngine
    private var cells: [VerificationCoverageCell] { VerificationCoverageMapEngine.build(entries: TechnicalTruthLedger.compile(engine: engine)) }
    var body: some View {
        List {
            Section("Verification Coverage Map") { Text(VerificationCoverageMapEngine.boundary).font(.caption).foregroundStyle(.secondary) }
            ForEach(cells) { cell in
                Section(cell.subsystem) {
                    LabeledContent("Coverage state", value: cell.state.rawValue)
                    LabeledContent("Assertions", value: "\(cell.total)")
                    LabeledContent("Verified", value: "\(cell.verified)")
                    LabeledContent("Quarantined", value: "\(cell.quarantined)")
                    LabeledContent("Disputed", value: "\(cell.disputed)")
                    LabeledContent("Evidence absent", value: "\(cell.evidenceAbsent)")
                    LabeledContent("Truth-debt load", value: "\(cell.debtScore)")
                }
            }
        }.navigationTitle("Coverage Map")
    }
}

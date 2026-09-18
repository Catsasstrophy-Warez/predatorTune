import SwiftUI

struct GT500ResearchCommandCenterView: View {
    @StateObject private var engine = TechnicalQueryEngine()
    private var entries:[TechnicalTruthLedgerEntry] { TechnicalTruthLedger.compile(engine:engine) }
    private var ranking:[ResearchLeverageResult] { GT500ResearchCommandCenterEngine.rank(entries:entries) }
    private var coverage:[VerificationCoverageCell] { VerificationCoverageMapEngine.build(entries:entries) }
    private let columns = [GridItem(.adaptive(minimum: 270), spacing: 10)]
    var body: some View {
        ScrollView {
            VStack(spacing:16) {
                PLTrackHeader(eyebrow:"Research Command", title:"FIND THE MISSING TRUTH", subtitle:"Factory information, controller evidence and vehicle validation stay separated by authority and applicability.", icon:"books.vertical.fill", accent:.plBoost)
                ladder
                VStack(alignment:.leading,spacing:10) {
                    PLSectionHeader(title:"Highest-Leverage Targets",systemImage:"scope",accent:.plIgnition)
                    LazyVGrid(columns:columns,spacing:10) { ForEach(ranking.prefix(12)) { item in NavigationLink { ResearchTargetDetailView(item:item,entries:entries) } label: { targetCard(item) }.buttonStyle(.plain) } }
                }
                PLCard { VStack(alignment:.leading,spacing:8) { PLSectionHeader(title:"Coverage Map",systemImage:"square.grid.3x3.fill",accent:.plSuccess); ForEach(coverage) { cell in NavigationLink { CoverageCellProvenanceView(drilldown:GT500ResearchCommandCenterEngine.drilldown(cell:cell,entries:entries)) } label: { HStack { VStack(alignment:.leading,spacing:2){Text(cell.subsystem).font(.plBody).foregroundStyle(.plTextPrimary);Text("\(cell.verified)/\(cell.total) verified • debt \(cell.debtScore)").font(.plCaption).foregroundStyle(.plTextSecondary)};Spacer();Text(cell.state.rawValue.uppercased()).font(.system(size:9,weight:.black)).foregroundStyle(.plBoost);Image(systemName:"chevron.right").font(.caption).foregroundStyle(.plTextSecondary) }.padding(.vertical,6) }.buttonStyle(.plain) } } }
                researchLane("Ford Workshop Lane", program:.workshop, accent:.plCritical)
                researchLane("HP Tuners / Data Lane", program:nil, accent:.plBoost)
            }.padding(16)
        }.plScreenBackground().navigationTitle("Research").navigationBarTitleDisplayMode(.inline)
    }
    private var ladder: some View { PLCard { VStack(alignment:.leading,spacing:7) { PLSectionHeader(title:"Evidence Ladder",systemImage:"chart.bar.fill",accent:.plBoost); Text("Missing → Source Located → Source Verified → Acquired → Structured → Cross-Verified → Vehicle Validated → Complete for Current Scope").font(.plCaption).foregroundStyle(.plTextPrimary); Text("A source-level upgrade never promotes neighboring claims or turns a public document into vehicle validation.").font(.plCaption).foregroundStyle(.plTextSecondary) } } }
    private func targetCard(_ item:ResearchLeverageResult)->some View { VStack(alignment:.leading,spacing:7) { HStack { Image(systemName:"target").foregroundStyle(.plIgnition);Spacer();Text(item.target.state.rawValue.uppercased()).font(.system(size:9,weight:.black)).foregroundStyle(.plBoost) };Text(item.target.title).font(.plHeadline).foregroundStyle(.plTextPrimary);Text(item.target.program.rawValue).font(.plCaption).foregroundStyle(.plTextSecondary);HStack { Label("\(item.eligibleTruthIDs.count)",systemImage:"doc.text.magnifyingglass");Label("\(item.highConsequenceClaims)",systemImage:"exclamationmark.shield") }.font(.plCaption).foregroundStyle(.plTextSecondary) }.padding(13).frame(maxWidth:.infinity,alignment:.leading).background(Color.plSurface).clipShape(RoundedRectangle(cornerRadius:14)).overlay(RoundedRectangle(cornerRadius:14).stroke(Color.plStroke)) }
    private func researchLane(_ title:String, program:ResearchProgram?, accent:Color)->some View { let rows = program == nil ? ranking.filter{$0.target.program != .workshop} : ranking.filter{$0.target.program == program}; return PLCard { VStack(alignment:.leading,spacing:7) { PLSectionHeader(title:title,systemImage:"flag.checkered",accent:accent); ForEach(rows.prefix(12)) { item in HStack { Text(item.target.title).font(.plCaption).foregroundStyle(.plTextPrimary);Spacer();Text(item.target.state.rawValue).font(.plCaption).foregroundStyle(.plTextSecondary) }.padding(.vertical,3) } } } }
}

private struct ResearchTargetDetailView: View {
    let item:ResearchLeverageResult; let entries:[TechnicalTruthLedgerEntry]
    var body: some View { List {
        Section("Artifact") { Text(item.target.exactArtifact); LabeledContent("Authority",value:item.target.authority); LabeledContent("Applicability",value:item.target.applicability); LabeledContent("State",value:item.target.state.rawValue); if let locator = item.target.sourceLocator { LabeledContent("Source locator", value: locator) } }
        Section("Verified research evidence") { let records = GT500ResearchEvidenceCatalog.records(for:item.target.id); if records.isEmpty { Text("No structured source record yet. The target remains bounded by its acquisition state.").foregroundStyle(.secondary) } else { ForEach(records) { record in VStack(alignment:.leading,spacing:4) { Text(record.title).font(.headline); Text("\(record.authority.rawValue) • \(record.applicability)").font(.caption).foregroundStyle(.secondary); ForEach(record.supportedFacts,id:\.self) { Label($0,systemImage:"checkmark.seal") }; Text("Boundary: \(record.boundary)").font(.caption2).foregroundStyle(.secondary) } } } }
        Section("Calculated leverage") { LabeledContent("Eligible for review",value:"\(item.eligibleTruthIDs.count)"); LabeledContent("High consequence",value:"\(item.highConsequenceClaims)"); LabeledContent("Truth-debt load",value:"\(item.debtRetirableForReview)"); LabeledContent("Leverage",value:"\(item.leverageScore)"); Text(item.boundary).font(.caption).foregroundStyle(.secondary) }
        Section("Acceptance criteria") { ForEach(item.target.acceptanceCriteria,id:\.self) { Label($0,systemImage:"checkmark.circle") } }
        Section("Forbidden substitutions") { ForEach(item.target.forbiddenSubstitutions,id:\.self) { Label($0,systemImage:"xmark.octagon") } }
        Section("Claim-level drill-down") { ForEach(entries.filter{item.eligibleTruthIDs.contains($0.id)}.prefix(100)) { e in VStack(alignment:.leading){Text(e.statement);Text("\(e.ownerTitle) • \(e.disposition.rawValue) • \(e.criticality.label)").font(.caption).foregroundStyle(.secondary);Text(e.sourceTitle ?? "No claim-level source").font(.caption2)} } }
    }.navigationTitle(item.target.title) }
}

private struct CoverageCellProvenanceView: View {
    let drilldown:CoverageProvenanceDrilldown
    var body: some View { List {
        Section("Coverage cell") { Text("Every row below is an individual assertion. Cell state never upgrades neighboring claims.").font(.caption).foregroundStyle(.secondary) }
        Section("Assertions") { ForEach(drilldown.entries.prefix(150)) { e in VStack(alignment:.leading){Text(e.statement);Text("\(e.disposition.rawValue) • \(e.applicability)").font(.caption).foregroundStyle(.secondary);Text("Source: \(e.sourceTitle ?? "absent") • Locator: \(e.locator ?? "absent")").font(.caption2)} } }
        Section("Highest-leverage acquisition targets") { ForEach(drilldown.acquisitionTargets.prefix(10)) { t in Text("\(t.target.title): \(t.eligibleTruthIDs.count) review-eligible claim(s)") } }
    }.navigationTitle(drilldown.subsystem) }
}

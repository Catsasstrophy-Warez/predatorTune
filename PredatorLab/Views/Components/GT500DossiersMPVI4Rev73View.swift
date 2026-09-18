import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct GT500DossiersMPVI4Rev73View: View {
    @EnvironmentObject var appState:AppState
    @EnvironmentObject var dataRepository:DataRepository
    @State private var reviews:[VCMScannerSemanticReview]=[]
    var body: some View {
        List {
            Section("GT500 Experimental Dossiers") {
                ForEach(GT500ExperimentDossierCatalogRev73.all) { d in
                    NavigationLink(d.title) { GT500DossierDetailRev73View(dossier:d,reviews:reviews) }
                }
            }
            Section("MPVI4 Deep Reference") {
                NavigationLink("MPVI4 Hardware + Workflow Atlas") { MPVI4DeepReferenceRev73View() }
                Text("Official device facts are kept separate from PredatorLab interpretation and from Ford controller semantics.").font(.caption).foregroundStyle(.secondary)
            }
        }.navigationTitle("GT500 + MPVI4 Lab").task { if let id=appState.currentVehicle?.id { reviews=(try? await dataRepository.fetchScannerSemanticReviews(vehicleID:id)) ?? [] } }
    }
}

private struct GT500DossierDetailRev73View:View {
    let dossier:GT500ExperimentDossierRev73; let reviews:[VCMScannerSemanticReview]
    var plan:ScannerContractPlanRev72 { GT500ExperimentDossierCatalogRev73.scannerPlan(for:dossier.domain,reviews:reviews) }
    var body:some View { List {
        Section("Engineering question"){Text(dossier.question)}
        Section("Required evidence"){ForEach(dossier.requiredSemantics,id:\.self){Label($0,systemImage:plan.missingRequiredSemantics.contains($0) ? "questionmark.diamond":"checkmark.circle")}}
        Section("Useful context"){ForEach(dossier.optionalSemantics,id:\.self){Text($0)}}
        Section("Permitted conclusions"){ForEach(dossier.permittedConclusions,id:\.self){Text($0)}}
        Section("Do not infer"){ForEach(dossier.forbiddenConclusions,id:\.self){Label($0,systemImage:"hand.raised")}}
        Section("Next measurements"){ForEach(dossier.nextMeasurements,id:\.self){Text($0)}}
        Section("Boundary"){Text(dossier.evidenceBoundary).font(.caption).foregroundStyle(.secondary)}
    }.navigationTitle(dossier.title) }
}

private struct MPVI4DeepReferenceRev73View:View {
    var grouped:[String:[MPVI4FactRev73]] { Dictionary(grouping:MPVI4KnowledgeBaseRev73.officialFacts,by:\.category) }
    var body:some View { List {
        ForEach(grouped.keys.sorted(),id:\.self){ category in Section(category){ForEach(grouped[category] ?? []){ f in VStack(alignment:.leading,spacing:4){Text(f.statement);Text(f.operationalMeaning).font(.caption).foregroundStyle(.secondary);Text("Source: \(f.sourceLocator)").font(.caption2).foregroundStyle(.secondary)}}}}
        Section("Evidence boundary"){Text(MPVI4KnowledgeBaseRev73.boundary).font(.caption).foregroundStyle(.secondary)}
    }.navigationTitle("MPVI4 Deep Reference") }
}

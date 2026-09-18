// PredatorLab/Views/ReferenceLibraryView.swift
// Searchable technical component library: specs, location, failure modes, evidence grade.
// Backed by TechnicalQueryEngine + ComponentLibrarySeedData (15 hand-authored components).

import SwiftUI

/// Which library the segmented control is showing.
private enum LibrarySection: String, CaseIterable, Identifiable {
    case components = "Components"
    case measurements = "Signals"
    case maintenance = "Maintenance"
    case search = "All"
    case topology = "Graph"
    case verification = "Verify"
    case logging = "Logging"
    case readiness = "Readiness"

    var id: String { rawValue }
}

/// Navigation payload for the shared Reference stack — disambiguates component vs.
/// maintenance procedure ids (both are plain UUIDs).
private enum ReferenceDestination: Hashable {
    case component(UUID)
    case maintenance(UUID)
}

struct ReferenceLibraryView: View {
    @EnvironmentObject var dataRepository: DataRepository
    @StateObject private var queryEngine = TechnicalQueryEngine()
    @State private var searchText = ""
    @State private var selectedSection: ComponentSection?
    @State private var librarySection: LibrarySection = .components
    @State private var maintenanceProcedures: [MaintenanceProcedure] = []

    private var filteredComponents: [ComponentRecord] {
        let base: [ComponentRecord]
        if searchText.isEmpty {
            base = queryEngine.components
        } else {
            base = queryEngine.crossDomainSearch(searchText).components
        }
        let sectioned = selectedSection.map { section in base.filter { $0.section == section } } ?? base
        return sectioned.sorted { $0.name < $1.name }
    }

    private var sectionsPresent: [ComponentSection] {
        let sections = Set(queryEngine.components.map(\.section))
        return ComponentSection.allCases.filter { sections.contains($0) }
    }

    private var filteredProcedures: [MaintenanceProcedure] {
        let base: [MaintenanceProcedure]
        if searchText.isEmpty {
            base = maintenanceProcedures
        } else {
            let needle = searchText.lowercased()
            base = maintenanceProcedures.filter {
                $0.title.lowercased().contains(needle)
                    || $0.system.rawValue.lowercased().contains(needle)
                    || $0.subsystem.lowercased().contains(needle)
            }
        }
        return base.sorted { $0.title < $1.title }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PLTrackHeader(eyebrow: "Workshop Manual", title: "REFERENCE", subtitle: "Components, signals, procedures, topology and evidence verification in one technical library.", icon: "books.vertical.fill", accent: .plBoost)
                    .padding(.horizontal).padding(.top, 12)
                LibrarySectionBar(selection: $librarySection)
                    .padding(.top, 8)

                if librarySection == .components {
                    SectionFilterBar(sections: sectionsPresent, selection: $selectedSection)

                    if filteredComponents.isEmpty {
                        Spacer()
                        EmptyStateView(systemImage: "magnifyingglass", text: "No components match")
                        Spacer()
                    } else {
                        List(filteredComponents) { component in
                            NavigationLink(value: ReferenceDestination.component(component.id)) {
                                ComponentRow(component: component)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                } else if librarySection == .measurements {
                    List(MeasurementAtlas.entries) { entry in
                        NavigationLink {
                            MeasurementAtlasDetailView(entry: entry)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(entry.title).font(.headline)
                                Text(entry.purpose).font(.subheadline).foregroundStyle(.secondary)
                                Label(entry.diagnosticUse, systemImage: "scope").font(.caption)
                                Text(entry.relatedInvestigations.joined(separator: " • ")).font(.caption2).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 5)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                } else if librarySection == .maintenance {
                    if filteredProcedures.isEmpty {
                        Spacer()
                        EmptyStateView(systemImage: "wrench.and.screwdriver", text: "No procedures match")
                        Spacer()
                    } else {
                        List(filteredProcedures) { procedure in
                            NavigationLink(value: ReferenceDestination.maintenance(procedure.id)) {
                                MaintenanceProcedureRow(procedure: procedure)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                } else if librarySection == .search {
                    List(UniversalTechnicalSearch.search(searchText, engine: queryEngine)) { hit in
                        VStack(alignment: .leading, spacing: 4) { Text(hit.title).font(.headline); Text("\(hit.subtitle) • index score \(hit.score)").font(.caption).foregroundStyle(.secondary) }
                    }.overlay { if searchText.isEmpty { PlatformUnavailableView(title: "Search the whole laboratory", systemImage: "magnifyingglass", description: "Components, circuits, sensors, DTCs, procedures, calibration and signals.") } }
                } else if librarySection == .topology {
                    KnowledgeGraphSummaryView(engine: queryEngine)
                } else if librarySection == .logging {
                    PLGT500LoggingOptimizerView()
                } else if librarySection == .readiness {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            PLProductionReadinessRev132()
                            PLThresholdAuthorityRev131(thresholds: .analysisDefaults)
                            PLForensicCapabilityMatrixRev131(matrix: ForensicCapabilityMapperRev131.map(channels: []))
                        }
                        .padding(12)
                    }
                } else {
                    VerificationDashboardView(engine: queryEngine)
                        .environmentObject(dataRepository)
                }
            }
            .plHardBottomEdge()
            .plScreenBackground()
            .navigationTitle("Reference")
            .accessibilityIdentifier("reference.library")
            .searchable(text: $searchText, prompt: librarySection == .search ? "Search all technical domains" : "Search current reference section")
            .navigationDestination(for: ReferenceDestination.self) { destination in
                switch destination {
                case .component(let id):
                    if let component = queryEngine.components.first(where: { $0.id == id }) {
                        ComponentDetailView(component: component)
                    }
                case .maintenance(let id):
                    if let procedure = maintenanceProcedures.first(where: { $0.id == id }) {
                        MaintenanceProcedureDetailView(procedure: procedure)
                    }
                }
            }
            .onAppear {
                if queryEngine.components.isEmpty {
                    queryEngine.components = ComponentLibrarySeedData.seedAll()
                }
                if maintenanceProcedures.isEmpty {
                    maintenanceProcedures = MaintenanceProcedureSeedData.seedAllProcedures()
                }
                if queryEngine.circuits.isEmpty {
                    queryEngine.circuits = TechnicalLibrarySeedData.seedCircuits()
                }
                if queryEngine.sensors.isEmpty {
                    queryEngine.sensors = TechnicalLibrarySeedData.seedSensors()
                }
                if queryEngine.dtcs.isEmpty {
                    queryEngine.dtcs = TechnicalLibrarySeedData.seedDTCs()
                }
                if queryEngine.procedures.isEmpty {
                    queryEngine.procedures = TechnicalLibrarySeedData.seedProcedures()
                }
                if queryEngine.calibration.isEmpty {
                    queryEngine.calibration = TechnicalLibrarySeedData.seedCalibration()
                }
            }
        }
    }
}

// MARK: - Library Section Bar

/// Horizontally-scrollable pill row for the top-level library section selector.
/// Replaces `.pickerStyle(.segmented)`, which truncates labels with ellipsis when
/// all 6 sections ("Components", "Signals", "Maintenance", "All", "Graph", "Verify")
/// must share a standard segmented control's width on an iPhone-width screen.
private struct LibrarySectionBar: View {
    @Binding var selection: LibrarySection

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LibrarySection.allCases) { section in
                    FilterChip(title: section.rawValue, isSelected: selection == section) {
                        selection = section
                    }
                    .accessibilityIdentifier("reference.librarySection.\(section.rawValue)")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Section Filter

private struct SectionFilterBar: View {
    let sections: [ComponentSection]
    @Binding var selection: ComponentSection?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selection == nil) { selection = nil }
                ForEach(sections, id: \.self) { section in
                    FilterChip(title: section.rawValue, isSelected: selection == section) {
                        selection = (selection == section) ? nil : section
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.plCaption)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? Color.black.opacity(0.85) : Color.plTextSecondary)
                .background(isSelected ? Color.plIgnition : Color.plSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(Color.plStroke, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State

private struct EmptyStateView: View {
    let systemImage: String
    let text: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 36))
                .foregroundStyle(.plTextSecondary)
            Text(text)
                .font(.plHeadline)
                .foregroundStyle(.plTextPrimary)
        }
    }
}

// MARK: - Row

private struct ComponentRow: View {
    let component: ComponentRecord

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(component.name)
                    .font(.plHeadline)
                    .foregroundStyle(.plTextPrimary)
                Text(component.section.rawValue)
                    .font(.plCaption)
                    .foregroundStyle(.plTextSecondary)
            }
            Spacer()
            if let grade = component.evidenceGrade {
                EvidenceBadge(grade: grade)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.plSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.plStroke, lineWidth: 1)
        )
    }
}

// MARK: - Maintenance Row

private struct MaintenanceProcedureRow: View {
    let procedure: MaintenanceProcedure

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(procedure.title)
                    .font(.plHeadline)
                    .foregroundStyle(.plTextPrimary)
                Text("\(procedure.system.rawValue) — \(procedure.subsystem)")
                    .font(.plCaption)
                    .foregroundStyle(.plTextSecondary)
            }
            Spacer()
            ConfidenceBadge(level: procedure.sourceConfidence)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.plSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.plStroke, lineWidth: 1)
        )
    }
}

// MARK: - Confidence Badge (parallel to EvidenceBadge, for ConfidenceLevel-graded content)

struct ConfidenceBadge: View {
    let level: ConfidenceLevel

    private var color: Color {
        switch level {
        case .c0: return .plTextSecondary
        case .c1: return .plCritical
        case .c2: return .plWarning
        case .c3: return .plWarning
        case .c4: return .plBoost
        case .c5: return .plSuccess
        }
    }

    var body: some View {
        Text("C\(level.rawValue)")
            .font(.plMono(11))
            .frame(width: 28, height: 22)
            .foregroundStyle(Color.black.opacity(0.85))
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - Evidence Badge (shared with ComponentDetailView)

struct EvidenceBadge: View {
    let grade: SourceGrade

    private var color: Color {
        switch grade {
        case .a_factory: return .plSuccess
        case .b_professional: return .plBoost
        case .c_owner: return .plWarning
        case .d_reference: return .plTextSecondary
        }
    }

    private var shortLabel: String {
        switch grade {
        case .a_factory: return "A"
        case .b_professional: return "B"
        case .c_owner: return "C"
        case .d_reference: return "D"
        }
    }

    var body: some View {
        Text(shortLabel)
            .font(.plMono(11))
            .frame(width: 22, height: 22)
            .foregroundStyle(Color.black.opacity(0.85))
            .background(color)
            .clipShape(Circle())
    }
}

private struct KnowledgeGraphSummaryView: View {
    @ObservedObject var engine: TechnicalQueryEngine
    private var graph: TechnicalKnowledgeGraph { TechnicalKnowledgeGraphBuilder.build(from: engine) }
    var body: some View {
        List {
            Section("Physical + Electrical Knowledge Graph") {
                Text("Bidirectional cross-links expose how components, circuits, sensors, DTCs, calibration and procedures connect. Missing links remain missing rather than being inferred.")
                LabeledContent("Nodes", value:"\(graph.nodes.count)")
                LabeledContent("Authored links", value:"\(graph.edges.count)")
                Text("Graph edges are authored relationships, not automatically source-verified facts.").font(.caption).foregroundStyle(.secondary)
                InteractiveKnowledgeMapView(engine: engine)
            }
            ForEach(KnowledgeNodeKind.allCases, id:\.self) { kind in
                let nodes=graph.nodes.filter{$0.kind==kind}
                if !nodes.isEmpty { Section(kind.rawValue.capitalized) { ForEach(nodes.prefix(20)) { node in
                    NavigationLink { KnowledgeNodeDetailView(node: node, engine: engine, graph: graph) } label: {
                        VStack(alignment:.leading){Text(node.title); Text("\(TechnicalKnowledgeGraphBuilder.neighbors(of: node.id, graph: graph).count) linked record(s)").font(.caption).foregroundStyle(.secondary)}
                    }
                } } }
            }
        }.listStyle(.insetGrouped)
    }
}


private struct KnowledgeNodeDetailView: View {
    let node:KnowledgeNode
    @ObservedObject var engine:TechnicalQueryEngine
    let graph:TechnicalKnowledgeGraph
    private var detail:KnowledgeNodeDetail { TechnicalKnowledgeGraphBuilder.detail(for: node, engine: engine) }
    private var provenanceReport: TechnicalRecordProvenanceReport? {
        guard let raw = node.id.split(separator: ":", maxSplits: 1).last, let uuid = UUID(uuidString: String(raw)) else { return nil }
        switch node.kind {
        case .sensor: return engine.sensors.first(where: {$0.id == uuid}).map(TechnicalRecordProvenanceEngine.report(sensor:))
        case .dtc: return engine.dtcs.first(where: {$0.id == uuid}).map(TechnicalRecordProvenanceEngine.report(dtc:))
        case .procedure: return engine.procedures.first(where: {$0.id == uuid}).map(TechnicalRecordProvenanceEngine.report(procedure:))
        default: return nil
        }
    }
    var body: some View {
        List {
            Section("Record") { Text(detail.summary); LabeledContent("Type", value: node.kind.rawValue.capitalized) }
            if !detail.path.isEmpty { Section("Electrical / Physical Path") { ForEach(detail.path,id:\.self){Text($0).font(.caption)} } }
            if !detail.connectors.isEmpty { Section("Connectors") { ForEach(detail.connectors,id:\.self){Text($0)} } }
            if !detail.pins.isEmpty { Section("Pins") { ForEach(detail.pins,id:\.self){Text($0).font(.caption)} } }
            if !detail.testPoints.isEmpty { Section("Test Points") { ForEach(detail.testPoints,id:\.self){Text($0).font(.caption)} } }
            if node.kind == .circuit, let uuid = node.id.split(separator: ":", maxSplits: 1).last.flatMap({ UUID(uuidString: String($0)) }), let circuit = engine.circuits.first(where: { $0.id == uuid }) {
                let claims = MeasurementClaimLedger.fromLegacy(circuit: circuit)
                if !claims.isEmpty { Section("Expected Measurement Trust") { CircuitMeasurementTrustView(circuit: circuit) } }
            }
            if let report = provenanceReport {
                Section("Evidence Chain") { TechnicalRecordProvenanceView(report: report) }
            }
            let neighbors=TechnicalKnowledgeGraphBuilder.neighbors(of:node.id,graph:graph)
            if !neighbors.isEmpty { Section("Linked Records") { ForEach(neighbors,id:\.0.id){ item in VStack(alignment:.leading){Text(item.0.title);Text(item.1).font(.caption).foregroundStyle(.secondary)} } } }
            Section("Evidence") { if detail.evidence.isEmpty { Text("No source attached to this record.").foregroundStyle(.secondary) } else { ForEach(Array(detail.evidence.enumerated()),id:\.offset){ _,source in VStack(alignment:.leading){Text(source.title);Text("\(source.grade.rawValue) • \(source.reference)").font(.caption).foregroundStyle(.secondary)} } } }
        }.navigationTitle(detail.title).navigationBarTitleDisplayMode(.inline)
    }
}

private struct VerificationDashboardView: View {
    @EnvironmentObject var dataRepository: DataRepository
    @ObservedObject var engine: TechnicalQueryEngine
    @State private var showMeasurementWorkbench = false
    @State private var showTruthLedger = false
    @State private var showTruthDebt = false
    @State private var showEvidenceReview = false
    @State private var showTruthPromotion = false
    @State private var showCoverageMap = false
    @State private var showResearchCommand = false
    private var summary:VerificationSummary { VerificationDashboardEngine.summarize(engine) }
    private var backlog: VerificationBacklog { TechnicalClaimRegistry.build(from: engine) }
    private var conflicts: [ClaimConflictReviewItem] { ClaimConflictReviewEngine.review(backlog.claims) }
    private var evidenceGaps: [EvidenceGapPriority] { EvidenceGapPrioritizationEngine.prioritize() }
    private var legacyTrustFindings: [LegacyCircuitTrustFinding] { LegacyCircuitTrustCompiler.findings(for: engine.circuits) }
    private var compiledTrust: TechnicalContentTrustSummary { TechnicalContentTrustCompiler.compile(engine: engine, contentVersion: "runtime-audit").trustSummary }
    private var provenanceIssues: [DiagnosticProvenanceChainIssue] { DiagnosticProvenanceChainAudit.audit(engine: engine, measurements: engine.circuits.flatMap(MeasurementClaimLedger.fromLegacy)) }
    var body: some View {
        List {
            Section("Verification Dashboard") {
                Text("Provenance inventory. A sourced record is not automatically proof that every statement inside it is verified.").font(.caption).foregroundStyle(.secondary)
                LabeledContent("Technical records / sources", value:"\(summary.totalClaims)")
                LabeledContent("Factory sources", value:"\(summary.factory)")
                LabeledContent("Professional sources", value:"\(summary.professional)")
                LabeledContent("Owner sources", value:"\(summary.owner)")
                LabeledContent("Reference / transfer sources", value:"\(summary.reference)")
                LabeledContent("Unsourced records", value:"\(summary.unsourced)")
                LabeledContent("Authored diagnostic hypotheses", value:"\(summary.authoredDiagnosticHypotheses)")
                LabeledContent("Source-verified diagnostic hypotheses", value:"\(summary.sourceVerifiedDiagnosticHypotheses)")
                ProgressView(value: summary.verifiedFraction) { Text("Factory + professional provenance") }
                LabeledContent("Claim-registry entries", value: "\(backlog.claims.count)")
                LabeledContent("Critical verification backlog", value: "\(backlog.criticalUnverified.count)")
            }
            Section("Critical verification backlog") {
                if backlog.criticalUnverified.isEmpty { Text("No critical unverified claims in the current registry.").foregroundStyle(.secondary) }
                ForEach(backlog.criticalUnverified.prefix(20)) { claim in
                    VStack(alignment:.leading, spacing:4) {
                        Text(claim.statement).font(.subheadline)
                        Text("\(claim.criticality.label) • \(claim.state.rawValue)").font(.caption).foregroundStyle(.secondary)
                        if let notes=claim.notes { Text(notes).font(.caption2).foregroundStyle(.secondary) }
                    }
                }
            }
            Section("Claim conflict review") {
                if conflicts.isEmpty { Text("No same-statement/value conflicts are currently compiled.").foregroundStyle(.secondary) }
                ForEach(conflicts.prefix(20)) { conflict in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack { Text(conflict.statement).font(.subheadline); Spacer(); Text(conflict.severity).font(.caption).fontWeight(.semibold) }
                        Text(conflict.applicability).font(.caption).foregroundStyle(.secondary)
                        ForEach(conflict.claims) { claim in
                            Text("\(claim.value ?? "—") \(claim.unit ?? "") · \(claim.state.rawValue) · \(claim.source?.title ?? "no source")").font(.caption2)
                        }
                        Text(conflict.boundary).font(.caption2).foregroundStyle(.secondary)
                    }.accessibilityIdentifier("verification.conflict.\(conflict.id.hashValue)")
                }
            }
            Section("Top evidence gaps") {
                Text(EvidenceGapPrioritizationEngine.boundary).font(.caption).foregroundStyle(.secondary)
                ForEach(evidenceGaps.prefix(9)) { gap in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack { Text("#\(gap.rank) \(gap.request.domain.rawValue)").font(.subheadline).fontWeight(.semibold); Spacer(); Text("\(gap.score)").font(.caption).monospacedDigit() }
                        Text(gap.request.exactNeed).font(.caption)
                        Text("Need: \(gap.request.artifact.rawValue) • impact \(gap.diagnosticImpact)/10 • substitution risk \(gap.substitutionRisk)/10").font(.caption2).foregroundStyle(.secondary)
                    }.accessibilityIdentifier("verification.gap.\(gap.request.id)")
                }
            }
            Section("Measurement verification") {
                Text("Review durable expected-measurement claims, source locators, applicability, and immutable revision history. Verification changes only the selected semantic claim.").font(.caption).foregroundStyle(.secondary)
                Button("Open Measurement Verification Workbench") { showMeasurementWorkbench = true }
                    .accessibilityIdentifier("verification.measurementWorkbench.open")
            }
            Section("Technical Truth Ledger") {
                let truthSummary = TechnicalTruthLedger.summary(TechnicalTruthLedger.compile(engine: engine))
                Text("Individual circuit, sensor, DTC, procedure-torque and calibration assertions with explicit trust state. Nearby sourcing never upgrades an assertion.").font(.caption).foregroundStyle(.secondary)
                LabeledContent("Assertions", value: "\(truthSummary.total)")
                LabeledContent("Verified", value: "\(truthSummary.verified)")
                LabeledContent("Quarantined", value: "\(truthSummary.quarantined)")
                Button("Open Technical Truth Ledger") { showTruthLedger = true }.accessibilityIdentifier("verification.truthLedger.open")
                Button("Open Truth Debt Dashboard") { showTruthDebt = true }.accessibilityIdentifier("verification.truthDebt.open")
                Button("Open Evidence Review Workbench") { showEvidenceReview = true }.accessibilityIdentifier("verification.evidenceReview.open")
                Button("Open Truth Promotion Workbench") { showTruthPromotion = true }.accessibilityIdentifier("verification.truthPromotion.open")
                Button("Open Verification Coverage Map") { showCoverageMap = true }.accessibilityIdentifier("verification.coverageMap.open")
                Button("Open GT500 Research Command Center") { showResearchCommand = true }.accessibilityIdentifier("verification.researchCommand.open")
            }
            Section("Compiled technical-content trust") {
                Text("Bulk audit across decomposed circuits and their expected measurements. Counts expose evidence debt; compilation does not upgrade trust.").font(.caption).foregroundStyle(.secondary)
                LabeledContent("Expected measurements", value: "\(compiledTrust.totalMeasurements)")
                LabeledContent("Admitted verified", value: "\(compiledTrust.verifiedMeasurements)")
                LabeledContent("Quarantined", value: "\(compiledTrust.quarantinedMeasurements)")
                LabeledContent("Missing dependencies", value: "\(compiledTrust.missingDependencies)")
                LabeledContent("Missing source locators", value: "\(compiledTrust.missingSourceLocators)")
                LabeledContent("Applicability conflicts", value: "\(compiledTrust.applicabilityConflicts)")
                LabeledContent("Provenance-chain blockers", value: "\(provenanceIssues.count)")
            }
            Section("Legacy measurement quarantine") {
                Text(LegacyCircuitTrustCompiler.boundary).font(.caption).foregroundStyle(.secondary)
                LabeledContent("Quarantined authored details", value: "\(legacyTrustFindings.count)")
                ForEach(legacyTrustFindings.prefix(12)) { finding in
                    VStack(alignment: .leading, spacing: 3) { Text(finding.subject).font(.caption); Text(finding.reason).font(.caption2).foregroundStyle(.secondary) }
                }
            }
            Section("Evidence boundary") {
                Text("PredatorLab separates logged observation, authored reasoning, source provenance, and verified technical claims. A sourced record is not automatically a verified threshold or repair instruction.")
            }
            Section("Priority") { Text("Verify safety-critical, diagnostic-critical, calibration-critical and service-critical claims before descriptive expansion.") }
        }.listStyle(.insetGrouped)
        .sheet(isPresented: $showMeasurementWorkbench) {
            NavigationStack { MeasurementVerificationWorkbenchView(engine: engine).environmentObject(dataRepository) }
        }
        .sheet(isPresented: $showTruthLedger) {
            NavigationStack { TechnicalTruthLedgerView(engine: engine) }
        }
        .sheet(isPresented: $showTruthDebt) {
            NavigationStack { TechnicalTruthDebtView(engine: engine) }
        }
        .sheet(isPresented: $showEvidenceReview) {
            NavigationStack { EvidenceReviewWorkbenchView(engine: engine).environmentObject(dataRepository) }
        }
        .sheet(isPresented: $showTruthPromotion) {
            NavigationStack { TechnicalTruthPromotionWorkbenchView(engine: engine).environmentObject(dataRepository) }
        }
        .sheet(isPresented: $showCoverageMap) {
            NavigationStack { VerificationCoverageMapView(engine: engine) }
        }
        .sheet(isPresented: $showResearchCommand) {
            NavigationStack { GT500ResearchCommandCenterView() }
        }
    }
}

private struct TechnicalRecordProvenanceView: View {
    let report: TechnicalRecordProvenanceReport
    var body: some View {
        LabeledContent("Attached sources", value: "\(report.sourceCount)")
        LabeledContent("Exact locators", value: "\(report.exactLocatorCount)")
        LabeledContent("Factory sources", value: "\(report.factorySourceCount)")
        ForEach(report.sourceSummaries, id: \.self) { Text($0).font(.caption) }
        ForEach(report.unresolvedBoundaries, id: \.self) { Label($0, systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.secondary) }
        Text(report.boundary).font(.caption2).foregroundStyle(.secondary)
    }
}

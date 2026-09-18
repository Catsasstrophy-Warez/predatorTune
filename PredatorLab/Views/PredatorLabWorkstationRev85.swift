import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct PredatorLabWorkstationRev85: View {
    @StateObject private var state: ForensicWorkspaceStateRev85

    init(initialTwinNodeID: String? = nil, initialTime: TimeInterval? = nil, initialChannelID: String? = nil, initialHypothesisID: String? = nil) {
        _state = StateObject(wrappedValue: ForensicWorkspaceStateRev85(initialTwinNodeID: initialTwinNodeID, initialTime: initialTime, initialChannelID: initialChannelID, initialHypothesisID: initialHypothesisID))
    }
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var repository: DataRepository
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group { if sizeClass == .compact { compactShell } else { workstationShell } }
            .plHardBottomEdge()
            .navigationTitle("Forensic Workstation")
    }

    private var compactShell: some View {
        VStack(spacing:0) {
            PLCommandStrip(title: "Forensic Cockpit", context: state.workspace.rawValue, accent: .plBoost, chips: [("Synchronized", "scope", .plSuccess), ("Read only", "lock.fill", .plWarning)])
                .padding(.horizontal, 10).padding(.top, 8)
            PLForensicContextBar(time: state.cursor.time, workspace: state.workspace.rawValue)
            Picker("Workspace",selection:$state.workspace) { ForEach(PredatorWorkspaceRev85.allCases) { Label($0.rawValue,systemImage:$0.systemImage).tag($0) } }.pickerStyle(.menu).padding(.horizontal).accessibilityIdentifier("workstation.workspacePicker")
            workspaceDetail
            VStack(spacing: 8) { ForensicInvestigationInspector(cursor: state.cursor, selection: state.selection) }.padding(.horizontal, 10).padding(.bottom, 8)
        }
    }
    private var workstationShell: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                PLCommandRail(title: "Race Engineer", items: [("Synchronized cursor", "scope"), ("Evidence authority", "checkmark.shield"), ("Read-only calibration", "lock.fill")]).padding(10)
                List { ForEach(PredatorWorkspaceRev85.allCases) { item in Button { state.workspace = item } label: { Label(item.rawValue, systemImage: item.systemImage) } } }
            }.navigationTitle("Pit Wall")
        } content: {
            VStack(spacing: 0) {
                PLCommandStrip(title: "Forensic Cockpit", context: state.workspace.rawValue, accent: .plBoost, chips: [("Cursor sync", "scope", .plSuccess), ("Evidence aware", "checkmark.shield", .plBoost), ("Calibration locked", "lock.fill", .plWarning)])
                    .padding(.horizontal).padding(.top, 8)
                PLTrackBreadcrumb(items: ["Forensics", state.workspace.rawValue]).padding(.horizontal)
                PLForensicContextBar(time: state.cursor.time, workspace: state.workspace.rawValue)
                workspaceDetail
            }
        }
        detail: { NavigationStack { ScrollView { VStack(spacing: 12) { EvidenceInspectorRev85(cursor:state.cursor,status:evidenceStatus); ForensicInvestigationInspector(cursor: state.cursor, selection: state.selection) }.padding(10) } } }
    }
    private var evidenceStatus: ForensicEvidenceStatusRev85 {
        guard let active=state.activeSession else { return .init() }
        return .init(identity: active.log.sourceSHA256 == nil ? .unknown : .matched, semanticsCertified:false, measurement:.valid, interpretation:.provisional)
    }
    @ViewBuilder private var workspaceDetail: some View {
        switch state.workspace {
        case .pullLab: PullLabRev85(state:state, logs:appState.allLogs, repository:repository)
        case .evidence: EvidenceWorkspaceRev85(state:state)
        case .calibration: CalibrationWorkspaceRev85(state:state)
        case .topology: TopologyWorkspaceRev85(state:state)
        case .execution: ProductionExecutionRev83View()
        case .replay: ReplayWorkspaceRev85(state:state)
        }
    }
}

private struct CalibrationWorkspaceRev85: View {
    @ObservedObject var state: ForensicWorkspaceStateRev85
    @StateObject private var engine = TechnicalContentSeedFactory.makeEngine()
    @State private var selectedID: UUID?

    private var selected: CalibrationRecord? {
        guard let selectedID else { return nil }
        return engine.calibration.first { $0.id == selectedID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                PLCard {
                    PLSectionHeader(title: "Calibration deltas", systemImage: "slider.horizontal.3", accent: .plIgnition)
                    Text("Review authored table relationships and stock reference values before proposing a change.")
                        .font(.plBody).foregroundStyle(.plTextSecondary)
                    HStack {
                        PLStatTile(label: "Tables", value: "\(engine.calibration.count)", accent: .plIgnition)
                        PLStatTile(label: "Mode", value: "READ", accent: .plBoost)
                        PLStatTile(label: "Write", value: "LOCKED", accent: .plCritical)
                    }
                }
                ForEach(engine.calibration) { record in
                    Button { selectedID = record.id; state.selection.calibrationID = record.id } label: {
                        PLCard(padding: 14) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "tablecells").foregroundStyle(.plIgnition).font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(record.name).font(.plHeadline).foregroundStyle(.plTextPrimary)
                                    Text("\(record.section) • \(record.tableType)").font(.plCaption).foregroundStyle(.plTextSecondary)
                                    Text(record.units).font(.plMono(12)).foregroundStyle(.plBoost)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.plTextSecondary)
                            }
                        }
                    }.buttonStyle(.plain)
                }
                PLCard {
                    PLSectionHeader(title: "Safety boundary", systemImage: "shield.lefthalf.filled", accent: .plWarning)
                    Text("These are authored reference records, not vehicle-specific calibration truth. Exact controller/OS identity and a captured baseline are required before any tune decision.")
                        .font(.plBody).foregroundStyle(.plTextSecondary)
                }
            }.padding()
        }
        .plScreenBackground()
        .sheet(isPresented: Binding(get: { selectedID != nil }, set: { if !$0 { selectedID = nil } })) {
            if let id = selectedID, let record = engine.calibration.first(where: { $0.id == id }) {
                CalibrationRecordDetailRev85(record: record)
            }
        }
        .accessibilityIdentifier("workstation.calibration")
    }
}

private struct CalibrationRecordDetailRev85: View {
    let record: CalibrationRecord

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    PLCard {
                        PLSectionHeader(title: record.section, systemImage: "tablecells", accent: .plIgnition)
                        Text(record.name).font(.plTitle).foregroundStyle(.plTextPrimary)
                        Text(record.function).font(.plBody).foregroundStyle(.plTextSecondary)
                        if let path = record.vcmPath { Text(path).font(.plMono(12)).foregroundStyle(.plBoost) }
                    }
                    PLCard {
                        PLSectionHeader(title: "Axes and role", systemImage: "chart.xyaxis.line", accent: .plBoost)
                        Text("X: \(record.axes.xAxis)  \(record.axes.xMin, specifier: "%.1f")–\(record.axes.xMax, specifier: "%.1f")")
                        Text("Y: \(record.axes.yAxis)  \(record.axes.yMin, specifier: "%.1f")–\(record.axes.yMax, specifier: "%.1f")")
                        Text("Role: \(record.role) • Units: \(record.units)").font(.plMono(12)).foregroundStyle(.plTextSecondary)
                    }
                    if !record.modificationPrerequisites.isEmpty {
                        PLCard {
                            PLSectionHeader(title: "Prerequisites", systemImage: "checklist", accent: .plWarning)
                            ForEach(record.modificationPrerequisites, id: \.self) { Text("• \($0)").font(.plBody) }
                        }
                    }
                    if let guidance = record.modificationGuidance {
                        PLCard {
                            PLSectionHeader(title: "Review guidance", systemImage: "exclamationmark.triangle", accent: .plWarning)
                            Text(guidance).font(.plBody).foregroundStyle(.plTextSecondary)
                        }
                    }
                    PLCard {
                        PLSectionHeader(title: "Stock reference map", systemImage: "square.grid.3x3.fill", accent: .plBoost)
                        Text("Represented stock values only • candidate calibration not attached")
                            .font(.plCaption).foregroundStyle(.plTextSecondary)
                        let values = record.stockValues.flatMap { $0 }
                        let minValue = values.min() ?? 0
                        let maxValue = values.max() ?? 1
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: min(10, max(1, record.stockValues.first?.count ?? 1))), spacing: 4) {
                            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                                Text(String(format: "%.1f", value))
                                    .font(.plMono(9)).foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, minHeight: 24)
                                    .background(Color.plBoost.opacity(0.25 + 0.65 * ((value - minValue) / max(0.001, maxValue - minValue))))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }.padding()
            }.plScreenBackground().navigationTitle("Calibration record").navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct TopologyWorkspaceRev85: View {
    @ObservedObject var state: ForensicWorkspaceStateRev85
    @StateObject private var engine = TechnicalContentSeedFactory.makeEngine()
    private var graph: TechnicalKnowledgeGraph { TechnicalKnowledgeGraphBuilder.build(from: engine) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                PLCard {
                    PLSectionHeader(title: "Component topology", systemImage: "point.3.connected.trianglepath.dotted", accent: .plBoost)
                    Text("Explore authored relationships between components, circuits, sensors, DTCs, procedures, and calibration records.")
                        .font(.plBody).foregroundStyle(.plTextSecondary)
                    HStack {
                        PLStatTile(label: "Nodes", value: "\(graph.nodes.count)", accent: .plBoost)
                        PLStatTile(label: "Links", value: "\(graph.edges.count)", accent: .plIgnition)
                        PLStatTile(label: "Domains", value: "\(Set(graph.nodes.map(\.kind)).count)", accent: .plSuccess)
                    }
                }
                PLCard {
                    InteractiveKnowledgeMapView(engine: engine) { id in state.selection.topologyNodeID = id }
                    if graph.nodes.count > 0, graph.edges.count < graph.nodes.count / 4 {
                        Text("Most components aren't yet linked in this build — connections shown here reflect authored relationships in the reference library, not a complete wiring or causality map.")
                            .font(.plCaption).foregroundStyle(.plTextSecondary)
                            .padding(.top, 6)
                    }
                }
                PLCard {
                    PLSectionHeader(title: "Evidence boundary", systemImage: "checkmark.shield", accent: .plWarning)
                    Text("Only authored links are drawn. Missing wiring, pinout, controller semantics, and first-out causality are not inferred from proximity in the graph.")
                        .font(.plBody).foregroundStyle(.plTextSecondary)
                }
                let nodeIDs = Set(graph.nodes.map(\.id))
                let danglingLinks = graph.edges.filter { !nodeIDs.contains($0.from) || !nodeIDs.contains($0.to) }.count
                PLCard {
                    PLSectionHeader(title: "Topology integrity", systemImage: "checkmark.seal", accent: danglingLinks == 0 ? .plSuccess : .plWarning)
                    LabeledContent("Resolved links", value: "\(graph.edges.count - danglingLinks)")
                    LabeledContent("Dangling references", value: "\(danglingLinks)")
                    Text(danglingLinks == 0 ? "Every rendered relationship resolves to a seeded record." : "Some authored relationships reference records not present in this content slice. Resolve them before treating the graph as complete.")
                        .font(.plCaption).foregroundStyle(.plTextSecondary)
                }
            }.padding()
        }
        .plScreenBackground()
        .accessibilityIdentifier("workstation.topology")
    }
}

private struct PullLabRev85: View {
    @ObservedObject var state: ForensicWorkspaceStateRev85
    let logs:[ImportedLog]
    let repository:DataRepository
    private var selectedSeries: ForensicSeriesRev85? { state.activeSession?.series.first { $0.id == state.selectedSeriesID } ?? state.activeSession?.series.first }
    var body: some View {
        ScrollView { VStack(alignment:.leading,spacing:14) {
            HStack { Text("Pull Lab").font(.title2.bold()); Spacer(); Button("MARK") { state.mark() }.buttonStyle(.borderedProminent) }
            Text("CSV channels are rendered as observed evidence. A CSV header is not promoted to a certified HP Tuners Parameter ID.").font(.caption).foregroundStyle(.secondary)
            if logs.isEmpty { PlatformUnavailableView(title:"No imported logs", systemImage:"waveform", description:"Import a CSV log to populate the admitted Pull Lab timeline.") }
            else {
                Picker("Active pull", selection: Binding(get:{state.activeSession?.log.id}, set:{ id in if let id, let log=logs.first(where:{$0.id==id}) { state.load(log:log,using:repository) } })) {
                    Text("Select a log").tag(Optional<UUID>.none); ForEach(logs) { Text($0.filename).tag(Optional($0.id)) }
                }
                if let active=state.activeSession {
                    Picker("Channel",selection:Binding(get:{state.selectedSeriesID ?? active.series.first?.id},set:{state.selectedSeriesID=$0})) { ForEach(active.series) { Text($0.descriptor.displayName).tag(Optional($0.id)) } }
                    if let series=selectedSeries {
                        ForensicTimelineRev85(title:series.descriptor.displayName,unit:series.descriptor.unit,samples:series.samples,cursor:$state.cursor)
                            .onChange(of:state.cursor.time) { t in if let t { state.cursor.rpm=ForensicDataAdapterRev85.nearestRPM(in:active,time:t); state.cursor.channelID=series.descriptor.id } }
                        Text("Semantic state: \(series.descriptor.semanticState.rawValue) • samples: \(series.samples.count)").font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                    Divider(); Text("Ghost Pull").font(.headline)
                    Picker("Baseline",selection:Binding(get:{state.baselineSession?.log.id},set:{ id in if let id, let log=logs.first(where:{$0.id==id}) { state.setBaseline(log:log,using:repository) } })) { Text("None").tag(Optional<UUID>.none); ForEach(logs.filter{$0.id != active.log.id}) { Text($0.filename).tag(Optional($0.id)) } }
                    if let baseline=state.baselineSession, let t=state.cursor.time {
                        let timeAlignment = TelemetryAlignmentEngine.time(activeTime:t)
                        let rpmAlignment = TelemetryAlignmentEngine.rpm(active:active,baseline:baseline,activeTime:t)
                        VStack(alignment:.leading,spacing:4) {
                            if let anchor=timeAlignment.anchors.first { Text(String(format:"Time-aligned  active %.3fs  ↔  baseline %.3fs  (confidence %.0f%%)",anchor.activeTime,anchor.baselineTime,timeAlignment.confidence*100)).font(.caption.monospacedDigit()) }
                            if let anchor=rpmAlignment.anchors.first { Text(String(format:"RPM-aligned  active %.3fs  ↔  baseline %.3fs  (confidence %.0f%%)",anchor.activeTime,anchor.baselineTime,rpmAlignment.confidence*100)).font(.caption.monospacedDigit()) }
                            else { Text(rpmAlignment.notes.first ?? "RPM alignment unavailable.").font(.caption).foregroundStyle(.secondary) }
                            ForEach(rpmAlignment.notes,id:\.self) { Text($0).font(.caption2).foregroundStyle(.secondary) }
                        }
                    }
                    let hypotheses=HypothesisSignatureEngineRev85.evaluate(channelNames:Set(active.series.map{$0.descriptor.id})); if !hypotheses.isEmpty { Divider(); Text("Candidate hypotheses").font(.headline); ForEach(hypotheses) { h in Button(h.hypothesis) { state.cursor.hypothesisID=h.id; state.selection.hypothesisID=h.id; state.inspectorPresented=true }.buttonStyle(.borderless) } }
                    Divider()
                    PLContextIntelligenceInspector(snapshot: ForensicContextIntelligence.snapshot(session: active, cursor: state.cursor), cursor: state.cursor)
                        .frame(minHeight: 260)
                }
            }
            if let error=state.loadError { Text(error).foregroundStyle(.red) }
        }.padding() }
        .sheet(isPresented:$state.inspectorPresented) { NavigationStack { EvidenceInspectorRev85(cursor:state.cursor,status:.init()) } }
    }
}

private struct EvidenceWorkspaceRev85: View {
    @ObservedObject var state: ForensicWorkspaceStateRev85

    /// Real dependency nodes derived from this session's admitted events and operator
    /// annotations — no fabricated fixture data. Edges link each annotation to the
    /// nearest event within a 1s window it was plausibly commenting on.
    private var dependencyNodes: [PLEvidenceDependencyNode] {
        guard let session = state.activeSession else { return [] }
        let eventNodes = session.events.map { PLEvidenceDependencyNode(id: $0.id.uuidString, title: $0.description, status: .observed) }
        let annotationNodes = state.annotations.map { PLEvidenceDependencyNode(id: $0.id.uuidString, title: $0.text, status: .derived) }
        return eventNodes + annotationNodes
    }
    private var dependencyEdges: [PLEvidenceDependencyEdge] {
        guard let session = state.activeSession, !session.events.isEmpty else { return [] }
        return state.annotations.compactMap { annotation in
            guard let nearest = session.events.min(by: { abs($0.timestamp - annotation.time) < abs($1.timestamp - annotation.time) }),
                  abs(nearest.timestamp - annotation.time) <= 1.0 else { return nil }
            return PLEvidenceDependencyEdge(from: annotation.id.uuidString, to: nearest.id.uuidString, label: "near")
        }
    }

    private var twinMatches: [GT500TwinContextMatch] {
        GT500TwinBidirectionalResolver.matches(channelID: state.selection.channelID ?? state.cursor.channelID, hypothesisID: state.selection.hypothesisID ?? state.cursor.hypothesisID, topologyNodeID: state.selection.topologyNodeID)
    }

    var body: some View {
        List {
            if !twinMatches.isEmpty {
                Section("Relevant GT500 Twin nodes") {
                    ForEach(twinMatches) { match in
                        Button { state.focusTwinNode(match.nodeID) } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack { Text(match.title).font(.headline); Spacer(); Text(match.authority.rawValue).font(.caption2.monospaced()).foregroundStyle(.orange) }
                                Text(match.reason).font(.caption).foregroundStyle(.secondary)
                                Text("Relevant ≠ causal • selected ≠ failed").font(.caption2).foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
            if !dependencyNodes.isEmpty {
                Section("Evidence dependency graph") {
                    PLEvidenceDependencyGraph(nodes: dependencyNodes, edges: dependencyEdges, selectedID: Binding(get: { state.selection.evidenceID }, set: { state.selection.evidenceID = $0 }))
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            if let session = state.activeSession {
                Section("Observed events") {
                    ForEach(session.events) { event in
                        Button {
                            state.cursor.time = event.timestamp
                            state.cursor.eventID = event.id
                            state.selectEvidence(event.id.uuidString)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(event.description)
                                Text(String(format: "T+%.3f s", event.timestamp)).font(.caption.monospacedDigit())
                            }
                        }
                    }
                }
            }
            Section("Operator annotations") {
                if state.annotations.isEmpty {
                    PlatformUnavailableView(
                        title: "No operator annotations",
                        systemImage: "note.text",
                        description: "Mark evidence in Pull Lab or add an annotation to build an admitted commentary trail for this pull."
                    )
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(state.annotations) { annotation in
                        Button(annotation.text) {
                            state.cursor.time = annotation.time
                            state.cursor.evidenceID = annotation.id.uuidString
                        }
                    }
                }
            }
        }
    }
}
private struct ReplayWorkspaceRev85: View {
    @ObservedObject var state:ForensicWorkspaceStateRev85
    var body:some View { ScrollView { VStack(alignment:.leading,spacing:12) { Text("Replay").font(.title2.bold()); if let session=state.activeSession { Text("Shared cursor is live against \(session.log.filename)."); ForEach(session.series.prefix(6)) { series in ForensicTimelineRev85(title:series.descriptor.displayName,unit:series.descriptor.unit,samples:series.samples,cursor:$state.cursor) } } else { Text("Select an admitted CSV pull in Pull Lab first.").foregroundStyle(.secondary) } }.padding() } }
}

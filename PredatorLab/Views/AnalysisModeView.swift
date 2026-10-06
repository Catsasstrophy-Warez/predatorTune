// PredatorLab/Views/AnalysisModeView.swift
// Analysis Mode: session review (EventCards from past sessions) and imported-log review
// (auto-detected LogEvents from HP Tuners CSVs), with a shared timeline + filterable list.
// Also owns presenting the R04 investigation sheet when Garage Mode requests it.

import SwiftUI
import Charts
import UniformTypeIdentifiers

enum AnalyzeSource: String, CaseIterable {
    case sessions = "Sessions"
    case logs = "Logs"
    case labs = "Labs"
}

struct AnalysisModeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataRepository: DataRepository

    @State private var source: AnalyzeSource = .logs
    @State private var showTelemetryCockpit = false

    @State private var sessions: [Session] = []
    @State private var selectedSessionID: UUID?

    @State private var selectedLogID: UUID?
    @State private var showImporter = false
    @State private var importError: String?
    @State private var isImporting = false

    @State private var severityFilter: String?
    @State private var selectedEventCard: EventCard?
    @State private var selectedLogEvent: LogEvent?
    @State private var forensicLog: ImportedLog?
    @State private var diagnosticLog: ImportedLog?

    private var displaySessions: [Session] {
        var all = sessions
        if let current = appState.currentSession, !all.contains(where: { $0.id == current.id }) {
            all.insert(current, at: 0)
        }
        return all.sorted { $0.date > $1.date }
    }

    private var selectedSession: Session? {
        displaySessions.first { $0.id == selectedSessionID }
    }

    private var selectedLog: ImportedLog? {
        appState.allLogs.first { $0.id == selectedLogID }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                analyzeHeader
                    .padding(.horizontal)
                    .padding(.top, 8)
                Picker("Source", selection: $source) {
                    ForEach(AnalyzeSource.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("analysis.sourcePicker")
                .padding(.horizontal)
                .padding(.vertical, 10)

                switch source {
                case .sessions:
                    sessionsContent
                case .logs:
                    logsContent
                case .labs:
                    AnalyzeLabsView()
                }
            }
            .plHardBottomEdge()
            .plScreenBackground()
            .overlay {
                if isImporting {
                    PLLoadingCard(title: "Importing log", message: "Parsing channels and detecting events")
                        .padding(32)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.35))
                }
            }
            .navigationTitle("Analyze")
            .toolbar {
                if source == .logs {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showImporter = true
                        } label: {
                            Label("Import Log", systemImage: "square.and.arrow.down")
                        }
                        .disabled(isImporting)
                        .accessibilityIdentifier("analysis.importLog")
                    }
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleImportResult(result)
            }
            .alert(
                "Can't Import This File",
                isPresented: Binding(
                    get: { importError != nil },
                    set: { isPresented in if !isPresented { importError = nil } }
                ),
                presenting: importError
            ) { _ in
                Button("OK") { importError = nil }
            } message: { message in
                Text(message)
            }
            .sheet(item: $selectedEventCard) { event in
                EventCardDetailSheet(event: event)
            }
            .sheet(item: $selectedLogEvent) { event in
                LogEventDetailSheet(event: event)
            }
            .sheet(item: $forensicLog) { log in
                ForensicLogView(log: log)
                    .environmentObject(dataRepository)
            }
            .sheet(item: $diagnosticLog) { log in
                MultiDomainDiagnosticsView(log: log)
                    .environmentObject(dataRepository)
            }
            .sheet(isPresented: $appState.showR04Dialog) {
                R04InvestigationView()
                    .environmentObject(appState)
            }
            .navigationDestination(isPresented: $showTelemetryCockpit) { TelemetryRenderingView() }
            .task {
                await loadSessions()
            }
            .onAppear(perform: consumeSourceRequest)
            .onAppear(perform: consumeExternalRequests)
            .onChange(of: appState.requestedAnalyzeSource) { _ in consumeSourceRequest() }
            .onChange(of: appState.pendingImportURL) { _ in consumeExternalRequests() }
            .onChange(of: appState.openFileNotice) { _ in consumeExternalRequests() }
            .onChange(of: appState.requestImportPicker) { _ in consumeExternalRequests() }
        }
    }

    private var analyzeHeader: some View {
        HStack(spacing: 10) {
            PLIconTile(icon: "waveform.path.ecg", accent: .plSuccess, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text("Follow the signal, not the guess.").font(.plHeadline).foregroundStyle(.plTextPrimary)
                Text("\(displaySessions.count) sessions • \(appState.allLogs.count) logs • events show what happened, not why")
                    .font(.plCaption).foregroundStyle(.plTextSecondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    /// A log imported after a Garage session ends belongs to that session: attach it and turn
    /// its detections into the session's event cards.
    private func linkToFinishedSession(_ log: ImportedLog) async {
        guard !appState.isLogging, let session = appState.currentSession, SessionLogLinker.canLink(session, to: log) else { return }
        let linked = SessionLogLinker.link(session, to: log)
        appState.currentSession = linked
        if let index = sessions.firstIndex(where: { $0.id == linked.id }) { sessions[index] = linked }
        do { try await dataRepository.save(session: linked) }
        catch { dataRepository.reportPersistenceFailure(domain: "sessionSave", recordID: linked.id.uuidString, error: error) }
    }

    /// Files opened from other apps, .hpl notices and keyboard/Shortcuts import requests.
    private func consumeExternalRequests() {
        if let url = appState.pendingImportURL {
            appState.pendingImportURL = nil
            source = .logs
            importLog(from: url)
        }
        if let notice = appState.openFileNotice {
            appState.openFileNotice = nil
            importError = notice
        }
        if appState.requestImportPicker {
            appState.requestImportPicker = false
            source = .logs
            showImporter = true
        }
    }

    private func consumeSourceRequest() {
        guard let requested = appState.requestedAnalyzeSource else { return }
        source = requested
        appState.requestedAnalyzeSource = nil
    }

    private func openTelemetryCockpit(for log: ImportedLog) {
        Task {
            do {
                appState.currentLogData = try await dataRepository.loadDataset(for: log)
                appState.activeEvents = log.events
                showTelemetryCockpit = true
            } catch {
                importError = error.localizedDescription
            }
        }
    }

    // MARK: - Sessions

    @ViewBuilder
    private var sessionsContent: some View {
        if displaySessions.isEmpty {
            emptyState(
                icon: "clock.arrow.circlepath",
                title: "No sessions yet",
                message: "Start a logging session from Garage mode to see it here."
            )
        } else {
            VStack(spacing: 0) {
                Picker("Session", selection: $selectedSessionID) {
                    ForEach(displaySessions) { session in
                        Text(session.displayTitle).tag(Optional(session.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(.plIgnition)
                .padding(.horizontal)

                if let session = selectedSession {
                    if let linkedLog = appState.allLogs.first(where: { $0.id == session.logFileID }) {
                        Button {
                            selectedLogID = linkedLog.id
                            source = .logs
                        } label: {
                            PLHubRow(title: "Open linked log", subtitle: linkedLog.filename, icon: "link", accent: .plBoost)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .accessibilityIdentifier("analysis.session.linkedLog")
                    }
                    let markers = session.eventCards.map {
                        TimelineMarker(id: $0.id, timestamp: $0.timestamp, severity: $0.severity, label: $0.title)
                    }

                    PLCard {
                        VStack(alignment: .leading, spacing: 10) {
                            PLSectionHeader(title: "Timeline", systemImage: "waveform.path.ecg")
                            EventTimelineView(markers: markers, duration: max(session.duration, 1)) { id in
                                selectedEventCard = session.eventCards.first { $0.id == id }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    SeverityFilterBar(selection: $severityFilter)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    List(filteredEventCards(for: session)) { event in
                        Button {
                            selectedEventCard = event
                        } label: {
                            EventCardRow(event: event)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.plBackground)
                        .listRowSeparatorTint(Color.plStroke)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                } else {
                    Spacer()
                    Text("Select a session above")
                        .font(.plBody)
                        .foregroundStyle(.plTextSecondary)
                    Spacer()
                }
            }
            .onAppear {
                if selectedSessionID == nil {
                    selectedSessionID = displaySessions.first?.id
                }
            }
        }
    }

    private func filteredEventCards(for session: Session) -> [EventCard] {
        let sorted = session.eventCards.sorted { $0.timestamp < $1.timestamp }
        guard let filter = severityFilter else { return sorted }
        return sorted.filter { $0.severity == filter }
    }

    private func loadSessions() async {
        guard let vehicleID = appState.currentVehicle?.id else { return }
        do { sessions = try await dataRepository.fetchAllSessions(forVehicle: vehicleID) }
        catch { sessions = []; dataRepository.reportPersistenceFailure(domain: "analysisSessionLoad", recordID: vehicleID.uuidString, error: error) }
    }

    // MARK: - Logs

    @ViewBuilder
    private var logsContent: some View {
        if appState.allLogs.isEmpty {
            ScrollView {
                PLEmptyState(
                    icon: "square.and.arrow.down.on.square",
                    title: "No logs imported",
                    message: "Import an HP Tuners CSV export. PredatorLab finds pulls and flags fuel-flow protection, knock by cylinder, lambda off command, misfires and controller limits.",
                    actionTitle: "Import HP Tuners Log"
                ) { showImporter = true }
                .padding()
            }
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    Picker("Log", selection: $selectedLogID) {
                        ForEach(appState.allLogs) { log in
                            Text(log.filename).tag(Optional(log.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.plIgnition)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let log = selectedLog {
                        let markers = log.events.map {
                            TimelineMarker(id: $0.id, timestamp: $0.timestamp, severity: $0.severity, label: $0.description)
                        }

                        PLCard {
                            VStack(alignment: .leading, spacing: 10) {
                                PLSectionHeader(title: "Timeline", systemImage: "waveform.path.ecg")
                                EventTimelineView(markers: markers, duration: max(log.duration, 1)) { id in
                                    selectedLogEvent = log.events.first { $0.id == id }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        if !log.events.isEmpty {
                            PLCard {
                                LogEventsChart(events: log.events, duration: max(log.duration, 1))
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }

                        PLHubSection(title: "Investigate This Log", icon: "scope", accent: .plSuccess) {
                            NavigationLink { PullAnalysisView(log: log) } label: {
                                PLHubRow(title: "Pull Analysis", subtitle: "Knock by cylinder, lambda by RPM, boost, IAT2 and baseline comparison", icon: "speedometer", accent: .plIgnition)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("analysis.pullAnalysis")
                            NavigationLink { LogTimelineLoaderView(log: log) } label: {
                                PLHubRow(title: "Log Timeline", subtitle: "Synced channels, pulls and events with a scrub cursor", icon: "rectangle.3.group.fill", accent: .plBoost)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("analysis.openUnifiedForensicSession")
                            Button { forensicLog = log } label: {
                                PLHubRow(title: "Forensic Workbench", subtitle: "Event-by-event forensic review", icon: "waveform.path.ecg.rectangle", accent: .plSuccess)
                            }
                            .buttonStyle(.plain)
                            Button { diagnosticLog = log } label: {
                                PLHubRow(title: "Multi-Domain Diagnostics", subtitle: "Run every diagnostic domain against this log", icon: "stethoscope", accent: .plCritical)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("analysis.multiDomainDiagnostics")
                            Button { openTelemetryCockpit(for: log) } label: {
                                PLHubRow(title: "3D Telemetry Cockpit", subtitle: "Replay this log through gauges, track path and waveforms", icon: "cube.transparent", accent: .plIgnition)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("analysis.telemetryCockpit")
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        if log.events.contains(where: { $0.eventType == "protection" }) {
                            Button {
                                Task {
                                    do {
                                        appState.currentLogData = try await dataRepository.loadDataset(for: log)
                                        appState.activeEvents = log.events
                                        appState.showR04Dialog = true
                                    } catch {
                                        importError = error.localizedDescription
                                    }
                                }
                            } label: {
                                Label("Investigate R04 (Insufficient Fuel Flow)", systemImage: "magnifyingglass.circle.fill")
                            }
                            .buttonStyle(.plPrimary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }

                        SeverityFilterBar(selection: $severityFilter)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        PLSectionHeader(title: "Events", systemImage: "list.bullet")
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVStack(spacing: 8) {
                            ForEach(filteredLogEvents(for: log)) { event in
                                Button {
                                    selectedLogEvent = event
                                } label: {
                                    LogEventRow(event: event)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 6)
                        .padding(.bottom, 24)
                    }
                }
            }
            .onAppear {
                if selectedLogID == nil {
                    selectedLogID = appState.allLogs.first?.id
                }
            }
        }
    }

    private func filteredLogEvents(for log: ImportedLog) -> [LogEvent] {
        let sorted = log.events.sorted { $0.timestamp < $1.timestamp }
        guard let filter = severityFilter else { return sorted }
        return sorted.filter { $0.severity == filter }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importLog(from: url)
        case .failure(let error):
            importError = error.localizedDescription
        }
    }

    /// Copies the picked file while its security scope is open, then parses and detects events
    /// off the main actor so a large export never freezes the UI.
    private func importLog(from url: URL) {
        let stagedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("csv")
        do {
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
            try FileManager.default.copyItem(at: url, to: stagedURL)
        } catch {
            importError = error.localizedDescription
            return
        }

        let originalName = url.lastPathComponent
        isImporting = true
        Task {
            defer {
                isImporting = false
                try? FileManager.default.removeItem(at: stagedURL)
            }
            do {
                let (parsed, events) = try await Task.detached(priority: .userInitiated) { () throws -> (ParsedLogData, [LogEvent]) in
                    let parsed = try CSVLogParser.parseHPTunerCSV(fileURL: stagedURL)
                    return (parsed, LogEventDetector.detectAllEvents(logData: parsed))
                }.value

                let importedLog = ImportedLog(
                    filename: originalName,
                    fileURL: url,
                    vehicleID: appState.currentVehicle?.id ?? appState.allVehicles.first?.id ?? UUID(),
                    buildStateID: appState.currentBuildStateID,
                    channels: parsed.channels,
                    sampleCount: parsed.sampleCount,
                    duration: parsed.duration,
                    timestamps: parsed.timestamps,
                    events: events
                )
                let durableLog = try await dataRepository.save(importedLog: importedLog, sourceURL: stagedURL)
                appState.allLogs.append(durableLog)
                await linkToFinishedSession(durableLog)
                appState.currentLogData = parsed
                appState.activeEvents = events
                selectedLogID = durableLog.id
            } catch {
                importError = error.localizedDescription
            }
        }
    }

    // MARK: - Shared

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.plTextSecondary)
            Text(title)
                .font(.plHeadline)
                .foregroundStyle(.plTextPrimary)
            Text(message)
                .font(.plBody)
                .foregroundStyle(.plTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
}

// MARK: - Severity Filter

private struct SeverityFilterBar: View {
    @Binding var selection: String?

    private let options: [(label: String, value: String?)] = [
        ("All", nil), ("Info", "info"), ("Warning", "warning"), ("Critical", "critical")
    ]

    var body: some View {
        Picker("Severity", selection: $selection) {
            ForEach(options, id: \.label) { option in
                Text(option.label).tag(option.value)
            }
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 8)
    }
}

// MARK: - Log channel/severity chart

/// A dyno-style strip chart plotting each imported log event's severity over the session
/// timeline, colored with the PL severity palette (critical/warning/info). When channel
/// data is present on the events, overlays a lightweight readout of a representative
/// numeric channel (fuel pressure or lambda when detected) so the review screen doubles
/// as a quick trend glance, not just an event list.
private struct LogEventsChart: View {
    let events: [LogEvent]
    let duration: TimeInterval

    private static let preferredChannels: [(name: String, color: Color, unit: String)] = [
        ("Fuel Pressure Actual", .plIgnition, "psi"),
        ("Fuel Pressure", .plIgnition, "psi"),
        ("WB Lambda B1", .plBoost, "λ"),
        ("WB Lambda", .plBoost, "λ"),
        ("Commanded Lambda", .plSuccess, "λ")
    ]

    /// Up to 3 of the preferred channels that actually appear in this event set, stacked
    /// together (matches the real HP Tuners VCM telemetry app's convention of showing
    /// several related channels as separate strips on one shared timeline, rather than one
    /// channel at a time).
    private var trendSeries: [PLChannelSeries] {
        Self.preferredChannels
            .filter { entry in events.contains { $0.channelValues[entry.name] != nil } }
            .prefix(3)
            .map { entry in
                let points = events
                    .compactMap { event -> (TimeInterval, Double)? in
                        guard let value = event.channelValues[entry.name] else { return nil }
                        return (event.timestamp, value)
                    }
                    .sorted { $0.0 < $1.0 }
                return PLChannelSeries(name: entry.name, unit: entry.unit, color: entry.color, points: points)
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PLSectionHeader(title: "Event Severity", systemImage: "chart.bar.fill", accent: .plBoost)

            Chart(events) { event in
                PointMark(
                    x: .value("Time", event.timestamp),
                    y: .value("Severity", severityRank(event.severity))
                )
                .foregroundStyle(SeverityColor.plColor(for: event.severity))
                .symbolSize(70)
            }
            .chartYScale(domain: 0...2)
            .chartYAxis {
                AxisMarks(values: [0, 1, 2]) { value in
                    AxisValueLabel {
                        if let rank = value.as(Int.self) {
                            Text(severityLabel(rank))
                                .font(.plCaption)
                                .foregroundStyle(.plTextSecondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Color.plStroke)
                    AxisValueLabel().font(.plCaption).foregroundStyle(.plTextSecondary)
                }
            }
            .frame(height: 110)

            let series = trendSeries
            if !series.isEmpty {
                Divider().background(Color.plStroke)

                PLSectionHeader(title: "Channel Trends", systemImage: "waveform", accent: .plIgnition)

                PLStackedChannelChart(series: series, stripHeight: 72)
            }
        }
    }

    private func severityRank(_ severity: String) -> Int {
        switch severity {
        case "critical": return 2
        case "warning": return 1
        default: return 0
        }
    }

    private func severityLabel(_ rank: Int) -> String {
        switch rank {
        case 2: return "CRIT"
        case 1: return "WARN"
        default: return "INFO"
        }
    }
}

// MARK: - Rows

private struct EventCardRow: View {
    let event: EventCard

    var body: some View {
        PLCard(padding: 12) {
            HStack(spacing: 12) {
                SeverityDot(severity: event.severity)
                VStack(alignment: .leading, spacing: 3) {
                    Text(event.title.isEmpty ? event.eventType : event.title)
                        .font(.plHeadline)
                        .foregroundStyle(.plTextPrimary)
                    Text(timelineTimeString(event.timestamp))
                        .font(.plMono(11))
                        .foregroundStyle(.plTextSecondary)
                }
                Spacer()
                if event.hypothesis != nil {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.plWarning)
                }
                PLBadge(text: SeverityColor.badgeText(for: event.severity), color: SeverityColor.plColor(for: event.severity))
            }
        }
    }
}

private struct LogEventRow: View {
    let event: LogEvent

    var body: some View {
        PLCard(padding: 12) {
            HStack(spacing: 12) {
                SeverityDot(severity: event.severity)
                VStack(alignment: .leading, spacing: 3) {
                    Text(event.description)
                        .font(.plHeadline)
                        .foregroundStyle(.plTextPrimary)
                        .lineLimit(1)
                    Text(timelineTimeString(event.timestamp))
                        .font(.plMono(11))
                        .foregroundStyle(.plTextSecondary)
                }
                Spacer()
                PLBadge(text: SeverityColor.badgeText(for: event.severity), color: SeverityColor.plColor(for: event.severity))
            }
        }
    }
}

// MARK: - Detail Sheets

private struct EventCardDetailSheet: View {
    let event: EventCard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Type", value: event.eventType)
                    LabeledContent("Severity", value: event.severity.capitalized)
                    LabeledContent("Time", value: timelineTimeString(event.timestamp))
                }

                if !event.description.isEmpty {
                    Section("Description") {
                        Text(event.description)
                    }
                }

                if let hypothesis = event.hypothesis {
                    Section("Hypothesis") {
                        Text(hypothesis)
                    }
                }

                if !event.evidence.isEmpty {
                    Section("Evidence") {
                        ForEach(event.evidence, id: \.self) { Text("• \($0)") }
                    }
                }

                if !event.channelSnapshot.isEmpty {
                    Section("Channel Snapshot") {
                        ForEach(event.channelSnapshot.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            LabeledContent(key, value: String(format: "%.2f", value))
                        }
                    }
                }

                if !event.notes.isEmpty {
                    Section("Notes") {
                        Text(event.notes)
                    }
                }
            }
            .navigationTitle("Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct LogEventDetailSheet: View {
    let event: LogEvent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Event", value: SessionLogLinker.title(for: event.eventType))
                    LabeledContent("Severity", value: event.severity.capitalized)
                    LabeledContent("Time in log", value: timelineTimeString(event.timestamp))
                }

                Section("What happened") {
                    Text(event.description)
                }

                if !event.sourceStates.isEmpty {
                    Section("Controller state") {
                        ForEach(event.sourceStates.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            LabeledContent(key, value: value)
                        }
                    }
                }

                if !event.channelValues.isEmpty {
                    Section("Every channel at this moment") {
                        ForEach(event.channelValues.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            LabeledContent(key, value: String(format: "%.2f", value))
                        }
                    }
                }
            }
            .plListStyle()
            .navigationTitle(SessionLogLinker.title(for: event.eventType))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

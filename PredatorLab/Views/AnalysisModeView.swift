// PredatorLab/Views/AnalysisModeView.swift
// Analysis Mode: session review (EventCards from past sessions) and imported-log review
// (auto-detected LogEvents from HP Tuners CSVs), with a shared timeline + filterable list.
// Also owns presenting the R04 investigation sheet when Garage Mode requests it.

import SwiftUI
import Charts
import UniformTypeIdentifiers

struct AnalysisModeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataRepository: DataRepository

    private enum Source: String, CaseIterable {
        case sessions = "Sessions"
        case logs = "Logs"
    }

    @State private var source: Source = .sessions

    @State private var sessions: [Session] = []
    @State private var selectedSessionID: UUID?

    @State private var selectedLogID: UUID?
    @State private var showImporter = false
    @State private var importError: String?

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
                PLTrackHeader(eyebrow: "Data Pit Wall", title: "ANALYZE", subtitle: "Sessions, imported logs, events and forensic evidence. Follow the signal, not the guess.", icon: "waveform.path.ecg", accent: .plSuccess)
                    .padding(.horizontal).padding(.top, 12)
                PLTrackBreadcrumb(items: ["Home", "Analyze", source.rawValue])
                    .padding(.horizontal)
                PLCommandStrip(title: "Data Pit Wall", context: source == .logs ? "Imported telemetry and forensic evidence" : "Recorded sessions and event history", accent: .plSuccess, chips: [("Evidence aware", "checkmark.shield", .plSuccess), ("Noncausal", "exclamationmark.triangle", .plWarning)])
                    .padding(.horizontal).padding(.bottom, 8)
                HStack(spacing: 10) {
                    PLStatTile(label: "Sessions", value: "\(displaySessions.count)", accent: .plSuccess, icon: "clock.arrow.circlepath")
                    PLStatTile(label: "Logs", value: "\(appState.allLogs.count)", accent: .plBoost, icon: "doc.text.magnifyingglass")
                    PLStatTile(label: "Mode", value: source.rawValue.uppercased(), accent: .plIgnition, icon: "flag.checkered")
                }.padding(.horizontal)
                Picker("Source", selection: $source) {
                    ForEach(Source.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("analysis.sourcePicker")
                .padding()

                switch source {
                case .sessions:
                    sessionsContent
                case .logs:
                    logsContent
                }
            }
            .plHardBottomEdge()
            .plScreenBackground()
            .navigationTitle("Analyze")
            .toolbar {
                if source == .logs {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showImporter = true
                        } label: {
                            Label("Import Log", systemImage: "square.and.arrow.down")
                        }
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
                "Import Failed",
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
            .task {
                await loadSessions()
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
            emptyState(
                icon: "square.and.arrow.down.on.square",
                title: "No logs imported",
                message: "Import an HP Tuners CSV export to auto-detect protection events, knock, shifts, and lambda deviations."
            )
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

                        Button {
                            forensicLog = log
                        } label: {
                            Label("Open Forensic Workbench", systemImage: "waveform.path.ecg.rectangle")
                        }
                        .buttonStyle(.plPrimary)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        Button {
                            diagnosticLog = log
                        } label: {
                            Label("Run Multi-Domain Diagnostics", systemImage: "stethoscope")
                        }
                        .buttonStyle(.plPrimary)
                        .accessibilityIdentifier("analysis.multiDomainDiagnostics")
                        .padding(.horizontal)
                        .padding(.top, 8)

                        if log.events.contains(where: { $0.eventType == "protection" }) {
                            Button {
                                do {
                                    appState.currentLogData = try dataRepository.reloadDataset(for: log)
                                    appState.activeEvents = log.events
                                    appState.showR04Dialog = true
                                } catch {
                                    importError = error.localizedDescription
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

    private func importLog(from url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let parsed = try CSVLogParser.parseHPTunerCSV(fileURL: url)
            let events = LogEventDetector.detectAllEvents(logData: parsed)
            let vehicleID = appState.currentVehicle?.id ?? UUID()

            let importedLog = ImportedLog(
                filename: parsed.filename,
                fileURL: url,
                vehicleID: vehicleID,
                buildStateID: appState.currentBuildStateID,
                channels: parsed.channels,
                sampleCount: parsed.sampleCount,
                duration: parsed.duration,
                timestamps: parsed.timestamps,
                events: events
            )

            let stagedURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("csv")
            try FileManager.default.copyItem(at: url, to: stagedURL)

            Task {
                defer { try? FileManager.default.removeItem(at: stagedURL) }
                do {
                    let durableLog = try await dataRepository.save(importedLog: importedLog, sourceURL: stagedURL)
                    appState.allLogs.append(durableLog)
                    appState.currentLogData = parsed
                    appState.activeEvents = events
                    selectedLogID = durableLog.id
                } catch {
                    importError = error.localizedDescription
                }
            }
        } catch {
            importError = error.localizedDescription
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
                    LabeledContent("Type", value: event.eventType)
                    LabeledContent("Severity", value: event.severity.capitalized)
                    LabeledContent("Time", value: timelineTimeString(event.timestamp))
                }

                Section("Description") {
                    Text(event.description)
                }

                if !event.sourceStates.isEmpty {
                    Section("Source States") {
                        ForEach(event.sourceStates.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            LabeledContent(key, value: value)
                        }
                    }
                }

                if !event.channelValues.isEmpty {
                    Section("Channel Values") {
                        ForEach(event.channelValues.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            LabeledContent(key, value: String(format: "%.2f", value))
                        }
                    }
                }
            }
            .navigationTitle("Log Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

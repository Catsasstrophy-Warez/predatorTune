import SwiftUI
import Charts

/// Synchronized multi-channel timeline for one log: drag on any chart to move the shared
/// cursor; pulls are shaded, events are marked, and the inspector lists every channel at the cursor.
struct LogTimelineView: View {
    let model: LogTimelineModel

    @State private var window: ClosedRange<TimeInterval>
    @State private var cursor: TimeInterval
    @State private var showAllChannels = false

    init(model: LogTimelineModel) {
        self.model = model
        let focus = PullAnalyzer.representativePull(in: model.pulls)
        let start = focus.map { max(model.startTime, $0.start - 2) } ?? model.startTime
        let end = focus.map { min(model.endTime, $0.end + 2) } ?? model.endTime
        _window = State(initialValue: start...max(end, start + 0.1))
        _cursor = State(initialValue: focus?.start ?? model.startTime)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                controls
                ForEach(model.tracks) { track in trackChart(track) }
                inspector
            }
            .padding(12)
        }
        .plHardBottomEdge()
        .plScreenBackground()
        .navigationTitle("Log Timeline")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("analysis.integratedForensicSession")
    }

    // MARK: Controls

    private var controls: some View {
        PLCard(padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Menu {
                        Button("Whole log") { focus(model.startTime...model.endTime, cursorAt: model.startTime) }
                        if !model.pulls.isEmpty {
                            Section("Pulls") {
                                ForEach(Array(model.pulls.enumerated()), id: \.element.id) { index, pull in
                                    Button("Pull \(index + 1) · \(time(pull.start))") {
                                        focus(max(model.startTime, pull.start - 2)...min(model.endTime, pull.end + 2), cursorAt: pull.start)
                                    }
                                }
                            }
                        }
                        if !model.events.isEmpty {
                            Section("Events") {
                                ForEach(model.events.filter { $0.severity != "info" }.prefix(40)) { event in
                                    Button("\(SessionLogLinker.title(for: event.eventType)) · \(time(event.timestamp))") {
                                        focus(max(model.startTime, event.timestamp - 3)...min(model.endTime, event.timestamp + 3), cursorAt: event.timestamp)
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Jump to", systemImage: "scope").font(.plHeadline)
                    }
                    .accessibilityIdentifier("timeline.jump")
                    Spacer()
                    Button { zoom(0.5) } label: { Image(systemName: "plus.magnifyingglass") }
                        .accessibilityLabel("Zoom in")
                    Button { zoom(2) } label: { Image(systemName: "minus.magnifyingglass") }
                        .accessibilityLabel("Zoom out")
                }
                Text("\(time(window.lowerBound)) – \(time(window.upperBound)) · drag a chart to move the cursor")
                    .font(.plCaption)
                    .foregroundStyle(.plTextSecondary)
            }
        }
    }

    // MARK: Charts

    private func trackChart(_ track: LogTimelineTrack) -> some View {
        let points = model.points(for: track, in: window)
        let pullsInView = model.pulls.filter { $0.end >= window.lowerBound && $0.start <= window.upperBound }
        let eventsInView = model.events(in: window).filter { $0.severity != "info" }
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(track.title).font(.plCaption).foregroundStyle(.plTextSecondary)
                Spacer()
                if let unit = track.unit { Text(unit).font(.plMono(11)).foregroundStyle(.plTextSecondary) }
            }
            Chart {
                ForEach(pullsInView) { pull in
                    RectangleMark(xStart: .value("Pull start", max(pull.start, window.lowerBound)),
                                  xEnd: .value("Pull end", min(pull.end, window.upperBound)))
                        .foregroundStyle(Color.plIgnition.opacity(0.12))
                }
                ForEach(points) { point in
                    LineMark(x: .value("Time", point.time), y: .value(track.title, point.value))
                        .foregroundStyle(by: .value("Series", point.series))
                        .interpolationMethod(.linear)
                }
                ForEach(eventsInView) { event in
                    RuleMark(x: .value("Event", event.timestamp))
                        .foregroundStyle(event.severity == "critical" ? Color.plCritical : Color.plWarning)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
                RuleMark(x: .value("Cursor", cursor))
                    .foregroundStyle(Color.plTextPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
            .chartXScale(domain: window)
            .chartYScale(domain: .automatic(includesZero: false))
            .chartLegend(track.channels.count > 1 ? .visible : .hidden)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                            let x = drag.location.x - geometry[proxy.plotAreaFrame].origin.x
                            if let time: Double = proxy.value(atX: x) {
                                cursor = min(max(time, window.lowerBound), window.upperBound)
                            }
                        })
                }
            }
            .frame(height: 96)
        }
        .padding(10)
        .background(Color.plSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(track.title)
        .accessibilityValue(readingSummary(for: track))
        .accessibilityIdentifier(track.id == model.tracks.first?.id ? "forensic.timeline.interactive" : "timeline.track.\(track.id)")
    }

    // MARK: Inspector

    private var inspector: some View {
        let readings = model.readings(at: cursor)
        let shown = showAllChannels ? readings : readings.filter { reading in model.tracks.contains { $0.channels.contains(reading.channel) } }
        return PLCard(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    PLSectionHeader(title: "At \(time(cursor))", systemImage: "scope", accent: .plBoost)
                    Spacer()
                    Button(showAllChannels ? "Plotted only" : "All \(readings.count) channels") { showAllChannels.toggle() }
                        .font(.plCaption)
                }
                if let event = model.nearestEvent(to: cursor) {
                    Label(event.description, systemImage: event.severity == "critical" ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                        .font(.plCaption)
                        .foregroundStyle(event.severity == "critical" ? Color.plCritical : Color.plWarning)
                }
                if let pull = model.pulls.first(where: { ($0.start...$0.end).contains(cursor) }) {
                    Label("Inside a pull: \(String(format: "%.0f", pull.rpmStart ?? 0))→\(String(format: "%.0f", pull.rpmEnd ?? 0)) rpm", systemImage: "speedometer")
                        .font(.plCaption)
                        .foregroundStyle(.plIgnition)
                }
                ForEach(shown) { reading in
                    HStack {
                        Text(reading.channel).font(.plCaption).foregroundStyle(.plTextPrimary).lineLimit(1)
                        Spacer()
                        Text(reading.value + (reading.unit.map { " \($0)" } ?? "")).font(.plMono(12)).foregroundStyle(.plTextPrimary)
                    }
                }
            }
        }
        .accessibilityIdentifier("timeline.inspector")
    }

    // MARK: Actions

    private func focus(_ range: ClosedRange<TimeInterval>, cursorAt time: TimeInterval) {
        window = range.lowerBound...max(range.upperBound, range.lowerBound + 0.1)
        cursor = time
    }

    private func zoom(_ factor: Double) {
        let half = (window.upperBound - window.lowerBound) * factor / 2
        let lower = max(model.startTime, cursor - half)
        let upper = min(model.endTime, cursor + half)
        window = lower...max(upper, lower + 0.1)
    }

    private func time(_ value: TimeInterval) -> String { String(format: "%.2f s", value) }

    private func readingSummary(for track: LogTimelineTrack) -> String {
        model.readings(at: cursor).filter { track.channels.contains($0.channel) }
            .map { "\($0.value) \($0.unit ?? "")" }.joined(separator: ", ")
    }
}

/// Loads an imported log off the main actor, then shows its timeline.
struct LogTimelineLoaderView: View {
    @EnvironmentObject private var dataRepository: DataRepository
    let log: ImportedLog
    @State private var model: LogTimelineModel?
    @State private var error: String?

    var body: some View {
        Group {
            if let model {
                LogTimelineView(model: model)
            } else if let error {
                PLLoadErrorCard(title: "Couldn't open the timeline", message: error) { Task { await load() } }.padding()
            } else {
                PLLoadingCard(title: "Building timeline", message: log.filename).padding()
            }
        }
        .plScreenBackground()
        .task { if model == nil { await load() } }
    }

    private func load() async {
        error = nil
        do {
            let dataset = try await dataRepository.loadDataset(for: log)
            let events = log.events
            model = await Task.detached(priority: .userInitiated) {
                LogTimelineModel(log: dataset, events: events, pulls: PullAnalyzer.analyze(dataset))
            }.value
        } catch {
            self.error = error.localizedDescription
        }
    }
}

import SwiftUI
import Charts

private struct RecorderPoint: Identifiable {
    let id = UUID()
    let time: TimeInterval
    let value: Double
    let series: String
}

struct EngineeringRecorderView: View {
    let dataset: ParsedLogData
    let evidence: DiagnosticEvidencePackage
    var serviceMarkers: [ServiceTimelineMarker] = []
    @State private var cursorTime: TimeInterval?
    private var effectiveCursorTime: TimeInterval { cursorTime ?? evidence.episode.start }
    private var diagnosticEpisodes: [ExecutedDiagnosticEpisode] { DomainDiagnosticExecutionEngine.executeAll(log: dataset).flatMap(\.episodes).filter { $0.end >= evidence.flightRecord.windowStart && $0.start <= evidence.flightRecord.windowEnd }.sorted { $0.start < $1.start } }
    private var cursorSnapshot: ForensicCursorSnapshot? { ForensicCursorEngine.snapshot(log: dataset, at: effectiveCursorTime, shiftEpisodes: LogEventDetector.detectAllEpisodes(logData: dataset).filter { $0.eventType == "shift" }) }

    private var rows: Range<Int> {
        let start = dataset.timestamps.firstIndex { $0 >= evidence.flightRecord.windowStart } ?? 0
        let end = dataset.timestamps.lastIndex { $0 <= evidence.flightRecord.windowEnd } ?? max(0, dataset.timestamps.count - 1)
        return start..<min(end + 1, dataset.samples.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Engineering Flight Recorder").font(.plHeadline)
                    Text("Shared cursor • −5 s to +2 s evidence window").font(.plCaption).foregroundStyle(.plTextSecondary)
                }
                Spacer()
                Text(String(format: "%.3f s", effectiveCursorTime)).font(.plMono(12))
            }

            track(title: "Engine RPM", channel: .engineRPM, points: rawPoints([(.engineRPM, "RPM")]), height: 105)
            track(title: "DCT Gear", channel: .gearActual, points: rawPoints([(.gearActual, "Gear")]), height: 80)
            track(title: "Injector Window", channel: .injectorPulseWidth,
                  points: rawPoints([(.injectorPulseWidth, "Actual PW"), (.maximumInjectorPulseWidth, "Maximum PW")]) + derivedPoints(\.injectorPulseWidthMargin, name: "PW Margin"), height: 125)
            track(title: "Fuel Pressure", channel: .fuelPressureActual,
                  points: rawPoints([(.fuelPressureCommanded, "Command"), (.fuelPressureActual, "Actual")]) + derivedPoints(\.fuelPressureError, name: "Error"), height: 125)
            track(title: "Lambda", channel: .lambdaMeasured,
                  points: rawPoints([(.lambdaCommanded, "Command"), (.lambdaMeasured, "Measured")]) + derivedPoints(\.lambdaError, name: "Error"), height: 120)
            track(title: "Throttle", channel: .throttleActual,
                  points: rawPoints([(.throttleCommanded, "Command"), (.throttleActual, "Actual")]) + derivedPoints(\.throttleError, name: "Error"), height: 120)
            sourceTrack
            diagnosticEpisodeTimeline
            serviceContextTimeline
            cursorInspector

            Text("Tracks use independent Y scales but one shared time cursor. Missing samples remain missing. Derived Error/Margin series are PredatorLab calculations, not OEM channels.")
                .font(.plCaption).foregroundStyle(.plTextSecondary)
        }
    }

    @ViewBuilder
    private func track(title: String, channel: CanonicalChannel, points: [RecorderPoint], height: CGFloat) -> some View {
        if !points.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title).font(.plCaption).fontWeight(.semibold)
                    Spacer()
                    if let entry = MeasurementAtlas.entry(for: channel) {
                        NavigationLink { MeasurementAtlasDetailView(entry: entry) } label: {
                            Label("Signal Atlas", systemImage: "book.pages").font(.plCaption)
                        }
                    }
                }
                Chart {
                    ForEach(points) { point in
                        LineMark(x: .value("Time", point.time), y: .value("Value", point.value), series: .value("Series", point.series))
                            .interpolationMethod(.linear)
                    }
                    RuleMark(x: .value("Event", evidence.episode.start)).lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                    if let cursorTime { RuleMark(x: .value("Cursor", cursorTime)).lineStyle(StrokeStyle(lineWidth: 1)) }
                }
                .chartXScale(domain: evidence.flightRecord.windowStart...evidence.flightRecord.windowEnd)
                .chartLegend(position: .bottom, spacing: 8)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0).onChanged { gesture in
                                let origin = geometry[proxy.plotAreaFrame].origin
                                let x = gesture.location.x - origin.x
                                if let time: Double = proxy.value(atX: x) { cursorTime = min(max(time, evidence.flightRecord.windowStart), evidence.flightRecord.windowEnd) }
                            })
                    }
                }
                .frame(height: height)
            }
        }
    }



    @ViewBuilder private var serviceContextTimeline: some View {
        if !serviceMarkers.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                Label("Service Context", systemImage: "wrench.and.screwdriver").font(.plCaption).fontWeight(.semibold)
                ForEach(serviceMarkers.prefix(8)) { marker in
                    HStack {
                        Text(String(format: "%+.1f d", -marker.relativeDays)).font(.plMono(10)).frame(width: 62, alignment: .trailing)
                        Text(marker.title).font(.plCaption)
                        Spacer()
                        Text(marker.detail).font(.plCaption).foregroundStyle(.plTextSecondary)
                    }
                }
                Text("Service markers are chronology overlays, not causal findings.").font(.plCaption).foregroundStyle(.plTextSecondary)
            }.padding(10).background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier("recorder.serviceContext")
        }
    }

    @ViewBuilder private var diagnosticEpisodeTimeline: some View {
        if !diagnosticEpisodes.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                HStack { Label("Candidate Episode Overlay", systemImage: "waveform.path.ecg.rectangle").font(.plCaption).fontWeight(.semibold); Spacer(); Text("observational").font(.plCaption).foregroundStyle(.plTextSecondary) }
                ForEach(diagnosticEpisodes.prefix(12)) { episode in
                    HStack(spacing: 8) {
                        Text(String(format: "%+.3f", episode.start - evidence.episode.start)).font(.plMono(10)).frame(width: 58, alignment: .trailing)
                        Text(episode.ruleID).font(.plCaption).lineLimit(1)
                        Spacer()
                        Text(String(format: "%.2fs", max(0, episode.end-episode.start))).font(.plMono(10)).foregroundStyle(.plTextSecondary)
                    }
                }
                Text("These markers are PredatorLab-authored candidate episodes. Their ordering can support First-Out review but does not establish causation or a failed component.").font(.plCaption).foregroundStyle(.plTextSecondary)
            }.padding(10).background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder private var cursorInspector: some View {
        if let snapshot = cursorSnapshot {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Cursor Inspection", systemImage: "scope").font(.plCaption).fontWeight(.semibold)
                    Spacer()
                    Text(String(format: "nearest sample %.3f s", snapshot.sampleTime)).font(.plMono(10)).foregroundStyle(.plTextSecondary)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 135), alignment: .leading)], spacing: 8) {
                    ForEach(snapshot.measurements) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.label).font(.plCaption).foregroundStyle(.plTextSecondary)
                            Text(item.value).font(.plMono(12)).lineLimit(2)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Text("Values are taken from the nearest original sample. Derived margins/errors are PredatorLab calculations; controller-source labels retain scanner text.").font(.plCaption).foregroundStyle(.plTextSecondary)
            }.padding(10).background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder private var sourceTrack: some View {
        let protection = sourceSamples(.torqueProtectionSource)
        let spark = sourceSamples(.sparkSource)
        if !protection.isEmpty || !spark.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                Text("Controller Sources").font(.plCaption).fontWeight(.semibold)
                if !protection.isEmpty { sourceRow("Protection", samples: protection) }
                if !spark.isEmpty { sourceRow("Spark", samples: spark) }
                Text("Source states are shown as sampled text because their enum semantics may be strategy-specific.").font(.plCaption).foregroundStyle(.plTextSecondary)
            }
        }
    }

    private func sourceRow(_ title: String, samples: [(TimeInterval, String)]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.plCaption).foregroundStyle(.plTextSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
                        Text(String(format: "%.2f  %@", sample.0, sample.1)).font(.plMono(10)).padding(.horizontal, 6).padding(.vertical, 4).background(.thinMaterial).clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func rawPoints(_ definitions: [(CanonicalChannel, String)]) -> [RecorderPoint] {
        var output: [RecorderPoint] = []
        for (channel, name) in definitions {
            guard let raw = ChannelResolver.resolve(channel, in: dataset.channels) else { continue }
            for row in rows where dataset.timestamps.indices.contains(row) {
                if let value = dataset.numericValue(channel: raw, row: row) { output.append(.init(time: dataset.timestamps[row], value: value, series: name)) }
            }
        }
        return output
    }

    private func derivedPoints(_ keyPath: KeyPath<DerivedEngineeringSample, Double?>, name: String) -> [RecorderPoint] {
        dataset.derivedEngineeringSamples().compactMap { sample in
            guard sample.timestamp >= evidence.flightRecord.windowStart, sample.timestamp <= evidence.flightRecord.windowEnd, let value = sample[keyPath: keyPath] else { return nil }
            return RecorderPoint(time: sample.timestamp, value: value, series: name)
        }
    }

    private func sourceSamples(_ channel: CanonicalChannel) -> [(TimeInterval, String)] {
        guard let raw = ChannelResolver.resolve(channel, in: dataset.channels) else { return [] }
        var result: [(TimeInterval, String)] = []
        var previous: String?
        for row in rows where dataset.timestamps.indices.contains(row) {
            guard let value = dataset.stringValue(channel: raw, row: row), value != previous else { continue }
            result.append((dataset.timestamps[row], value)); previous = value
        }
        return result
    }
}

// PredatorLab/Views/TelemetryRenderingView.swift
// Entry point for the RealityKit/Metal telemetry rendering surfaces:
// a Metal-driven waveform trace, a RealityKit 3D gauge cluster, and a
// RealityKit lap/run path colored by channel magnitude.
//
// Pulls from the currently loaded log (AppState.currentLogData) when one is
// available; otherwise falls back to a deterministic demo series so the
// screen is never blank before a log is imported.

import SwiftUI

@MainActor
struct TelemetryRenderingView: View {
    @EnvironmentObject private var appState: AppState

    @State private var scrubProgress: Double = 0
    @State private var playbackTimer: Timer?

    private let gaugeSpecs: [GaugeSpec] = [
        GaugeSpec(title: "RPM", minValue: 0, maxValue: 7500, color: .systemOrange, warningThreshold: 6500),
        GaugeSpec(title: "Boost", minValue: -5, maxValue: 25, color: .systemBlue, warningThreshold: 22),
        GaugeSpec(title: "AFR", minValue: 10, maxValue: 18, color: .systemGreen)
    ]

    private var waveformSeries: TelemetryChannelSeries {
        series(forChannel: "RPM", demoAmplitude: 7500)
    }

    private var boostSeries: TelemetryChannelSeries {
        series(forChannel: "Boost", demoAmplitude: 25)
    }

    private var afrSeries: TelemetryChannelSeries {
        series(forChannel: "AFR", demoAmplitude: 18)
    }

    private var pathSeries: TelemetryChannelSeries {
        series(forChannel: "Vehicle Speed", demoAmplitude: 160)
    }

    private var waveformChannels: [TelemetryWaveformSeries] {
        [
            TelemetryWaveformSeries(series: waveformSeries, color: .plIgnition),
            TelemetryWaveformSeries(series: boostSeries, color: .plBoost)
        ]
    }

    private var gaugeValues: [UUID: Double] {
        var result: [UUID: Double] = [:]
        result[gaugeSpecs[0].id] = waveformSeries.value(atProgress: scrubProgress)
        result[gaugeSpecs[1].id] = boostSeries.value(atProgress: scrubProgress)
        result[gaugeSpecs[2].id] = afrSeries.value(atProgress: scrubProgress)
        return result
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PLSectionHeader(title: "Telemetry Rendering", systemImage: "cube.transparent", accent: .plBoost)

                if appState.currentLogData == nil {
                    Text("No log imported yet — showing demo telemetry.")
                        .font(.plCaption)
                        .foregroundStyle(.plTextSecondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("RPM + Boost Waveform (Metal)")
                            .font(.plCaption)
                            .foregroundStyle(.plTextSecondary)
                        Spacer()
                        waveformLegend
                    }
                    TelemetryWaveformView(channels: waveformChannels, scrubProgress: scrubProgress)
                        .frame(height: 140)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Gauge Cluster (RealityKit)")
                        .font(.plCaption)
                        .foregroundStyle(.plTextSecondary)
                    GaugeClusterView(specs: gaugeSpecs, values: gaugeValues)
                        .frame(height: 180)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Speed Path (RealityKit)")
                        .font(.plCaption)
                        .foregroundStyle(.plTextSecondary)
                    TrackPathView(series: pathSeries, scrubProgress: $scrubProgress)
                        .frame(height: 200)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Playback Position")
                        .font(.plCaption)
                        .foregroundStyle(.plTextSecondary)
                    Slider(value: $scrubProgress, in: 0...1)
                }
            }
            .padding()
        }
        .navigationTitle("Telemetry Rendering")
        .onAppear(perform: startPlayback)
        .onDisappear(perform: stopPlayback)
    }

    private var waveformLegend: some View {
        HStack(spacing: 10) {
            ForEach(waveformChannels) { channel in
                HStack(spacing: 4) {
                    Circle().fill(channel.color).frame(width: 6, height: 6)
                    Text(channel.series.channelName)
                        .font(.plCaption)
                        .foregroundStyle(.plTextSecondary)
                }
            }
        }
    }

    private func series(forChannel channel: String, demoAmplitude: Double) -> TelemetryChannelSeries {
        guard let log = appState.currentLogData, log.channels.contains(channel) else {
            return TelemetryChannelSeriesAdapter.demoSeries(channelName: channel, amplitude: demoAmplitude)
        }
        return TelemetryChannelSeriesAdapter.extract(channel: channel, from: log)
    }

    private func startPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            Task { @MainActor in
                let next = scrubProgress + 0.0015
                scrubProgress = next > 1 ? 0 : next
            }
        }
    }

    private func stopPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
}

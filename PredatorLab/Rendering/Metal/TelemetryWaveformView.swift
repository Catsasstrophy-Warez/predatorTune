// PredatorLab/Rendering/Metal/TelemetryWaveformView.swift
// SwiftUI wrapper around the Metal telemetry waveform renderer.

import SwiftUI
import MetalKit

struct TelemetryWaveformSeries: Identifiable {
    let id = UUID()
    let series: TelemetryChannelSeries
    let color: Color
}

@MainActor
struct TelemetryWaveformView: UIViewRepresentable {
    let channels: [TelemetryWaveformSeries]
    var scrubProgress: Double = 0

    /// Single-channel convenience initializer.
    init(series: TelemetryChannelSeries, scrubProgress: Double = 0, lineColor: Color = .plBoost) {
        self.channels = [TelemetryWaveformSeries(series: series, color: lineColor)]
        self.scrubProgress = scrubProgress
    }

    init(channels: [TelemetryWaveformSeries], scrubProgress: Double = 0) {
        self.channels = channels
        self.scrubProgress = scrubProgress
    }

    func makeCoordinator() -> TelemetryWaveformRenderer? {
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        return TelemetryWaveformRenderer(device: device)
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.delegate = context.coordinator
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        view.isOpaque = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 30
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        guard let renderer = context.coordinator else { return }
        let rendererChannels = channels.map {
            TelemetryWaveformChannel(series: $0.series, color: $0.color.waveformComponents)
        }
        renderer.update(channels: rendererChannels)
        renderer.updateMarker(progress: scrubProgress)
    }
}

extension Color {
    /// Best-effort RGBA extraction for feeding the Metal uniform buffer.
    var waveformComponents: SIMD4<Float> {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SIMD4(Float(r), Float(g), Float(b), Float(a))
    }
}

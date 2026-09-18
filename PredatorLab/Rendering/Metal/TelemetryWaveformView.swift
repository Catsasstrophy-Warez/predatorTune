// PredatorLab/Rendering/Metal/TelemetryWaveformView.swift
// SwiftUI wrapper around the Metal telemetry waveform renderer.

import SwiftUI
import MetalKit

@MainActor
struct TelemetryWaveformView: UIViewRepresentable {
    let series: TelemetryChannelSeries
    var scrubProgress: Double = 0
    var lineColor: Color = .plBoost

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
        renderer.lineColor = SIMD4(Float(lineColor.components.red),
                                    Float(lineColor.components.green),
                                    Float(lineColor.components.blue),
                                    1.0)
        renderer.update(series: series)
        renderer.updateMarker(progress: scrubProgress)
    }
}

private extension Color {
    /// Best-effort RGB extraction for feeding the Metal uniform buffer.
    var components: (red: Double, green: Double, blue: Double) {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }
}

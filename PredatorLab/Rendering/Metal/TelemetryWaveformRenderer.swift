// PredatorLab/Rendering/Metal/TelemetryWaveformRenderer.swift
// MTKView-backed GPU line renderer for one or more overlaid telemetry
// channels. Used for high-frequency signal traces (CAN bus channels, knock
// retard, boost, RPM, etc.) where a SwiftUI Path redraw per frame is too
// costly. Each channel is normalized independently against its own
// min/max, so unrelated units (RPM vs. boost PSI) still overlay legibly.

import MetalKit

private struct WaveformUniforms {
    var lineColor: SIMD4<Float>
    var viewportSize: SIMD2<Float>
}

struct TelemetryWaveformChannel {
    let series: TelemetryChannelSeries
    let color: SIMD4<Float>
}

private struct ChannelDrawState {
    let buffer: MTLBuffer
    let vertexCount: Int
    let color: SIMD4<Float>
    let normalized: [Double]
}

@MainActor
final class TelemetryWaveformRenderer: NSObject, MTKViewDelegate {
    private static let gridLineFractions: [Float] = [0.0, 0.25, 0.5, 0.75, 1.0]

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?

    private var fillBuffer: MTLBuffer?
    private var fillVertexCount = 0
    private var fillColor: SIMD4<Float> = .zero
    private var gridBuffer: MTLBuffer?
    private var gridVertexCount = 0
    private var channelStates: [ChannelDrawState] = []
    private var markerBuffer: MTLBuffer?
    private var markerVertexCount = 0

    private let gridColor = SIMD4<Float>(1.0, 1.0, 1.0, 0.12)
    private let markerColor = SIMD4<Float>(1.0, 1.0, 1.0, 0.9)

    init?(device: MTLDevice) {
        guard let queue = device.makeCommandQueue() else { return nil }
        self.device = device
        self.commandQueue = queue
        super.init()
        buildPipeline()
        buildGrid()
    }

    private func buildGrid() {
        var vertices = [SIMD2<Float>]()
        vertices.reserveCapacity(Self.gridLineFractions.count * 2)
        for fraction in Self.gridLineFractions {
            let y = fraction * 2.0 - 1.0
            vertices.append(SIMD2(-1.0, y))
            vertices.append(SIMD2(1.0, y))
        }
        gridBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<SIMD2<Float>>.stride,
            options: .storageModeShared
        )
        gridVertexCount = vertices.count
    }

    private func buildPipeline() {
        guard let library = try? device.makeDefaultLibrary(bundle: .main),
              let vertexFunction = library.makeFunction(name: "telemetry_waveform_vertex"),
              let fragmentFunction = library.makeFunction(name: "telemetry_waveform_fragment") else {
            return
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

        pipelineState = try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    /// Backward-compatible single-channel convenience.
    func update(series: TelemetryChannelSeries, color: SIMD4<Float> = SIMD4(0.98, 0.55, 0.15, 1.0)) {
        update(channels: [TelemetryWaveformChannel(series: series, color: color)])
    }

    /// Uploads each channel as its own independently-normalized line-strip
    /// vertex buffer, overlaid in the same -1...1 clip space. The first
    /// channel also gets a translucent "fill under the curve" pass, since
    /// filling every overlaid channel would just muddy the overlap.
    func update(channels: [TelemetryWaveformChannel]) {
        channelStates.removeAll(keepingCapacity: true)
        fillBuffer = nil
        fillVertexCount = 0

        for (index, channel) in channels.enumerated() {
            guard !channel.series.isEmpty else { continue }

            let normalized = channel.series.normalized()
            let count = normalized.count
            var lineVertices = [SIMD2<Float>]()
            lineVertices.reserveCapacity(count)

            for (sampleIndex, value) in normalized.enumerated() {
                let x = count > 1 ? (Float(sampleIndex) / Float(count - 1)) * 2.0 - 1.0 : 0.0
                let y = Float(value) * 2.0 - 1.0
                lineVertices.append(SIMD2(x, y))
            }

            guard let buffer = device.makeBuffer(
                bytes: lineVertices,
                length: lineVertices.count * MemoryLayout<SIMD2<Float>>.stride,
                options: .storageModeShared
            ) else { continue }

            channelStates.append(ChannelDrawState(
                buffer: buffer,
                vertexCount: lineVertices.count,
                color: channel.color,
                normalized: normalized
            ))

            if index == 0 {
                var fillVertices = [SIMD2<Float>]()
                fillVertices.reserveCapacity(count * 2)
                for vertex in lineVertices {
                    fillVertices.append(vertex)
                    fillVertices.append(SIMD2(vertex.x, -1.0))
                }
                fillBuffer = device.makeBuffer(
                    bytes: fillVertices,
                    length: fillVertices.count * MemoryLayout<SIMD2<Float>>.stride,
                    options: .storageModeShared
                )
                fillVertexCount = fillVertices.count
                fillColor = channel.color * SIMD4(1, 1, 1, 0.22)
            }
        }
    }

    /// Moves a vertical scrub marker to `progress` (0...1) through the
    /// primary (first) channel currently loaded.
    func updateMarker(progress: Double) {
        guard let primary = channelStates.first, !primary.normalized.isEmpty else {
            markerBuffer = nil
            markerVertexCount = 0
            return
        }

        let clamped = min(max(progress, 0), 1)
        let index = Int((Double(primary.normalized.count - 1) * clamped).rounded())
        let value = primary.normalized[min(max(index, 0), primary.normalized.count - 1)]

        let x = Float(clamped) * 2.0 - 1.0
        let y = Float(value) * 2.0 - 1.0

        // A vertical line from the baseline up to the sample, plus a short
        // horizontal tick at the sample itself so it reads as a marker dot.
        let vertices: [SIMD2<Float>] = [
            SIMD2(x, -1.0), SIMD2(x, y),
            SIMD2(x - 0.015, y), SIMD2(x + 0.015, y)
        ]

        markerBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<SIMD2<Float>>.stride,
            options: .storageModeShared
        )
        markerVertexCount = vertices.count
    }

    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    nonisolated func draw(in view: MTKView) {
        MainActor.assumeIsolated {
            self.render(in: view)
        }
    }

    private func render(in view: MTKView) {
        guard let pipelineState,
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        encoder.setRenderPipelineState(pipelineState)
        let viewportSize = SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height))

        if let fillBuffer, fillVertexCount > 2 {
            var fillUniforms = WaveformUniforms(lineColor: fillColor, viewportSize: viewportSize)
            encoder.setVertexBuffer(fillBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&fillUniforms, length: MemoryLayout<WaveformUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&fillUniforms, length: MemoryLayout<WaveformUniforms>.stride, index: 1)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: fillVertexCount)
        }

        if let gridBuffer, gridVertexCount > 1 {
            var gridUniforms = WaveformUniforms(lineColor: gridColor, viewportSize: viewportSize)
            encoder.setVertexBuffer(gridBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&gridUniforms, length: MemoryLayout<WaveformUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&gridUniforms, length: MemoryLayout<WaveformUniforms>.stride, index: 1)
            encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: gridVertexCount)
        }

        for state in channelStates where state.vertexCount > 1 {
            var lineUniforms = WaveformUniforms(lineColor: state.color, viewportSize: viewportSize)
            encoder.setVertexBuffer(state.buffer, offset: 0, index: 0)
            encoder.setVertexBytes(&lineUniforms, length: MemoryLayout<WaveformUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&lineUniforms, length: MemoryLayout<WaveformUniforms>.stride, index: 1)
            encoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: state.vertexCount)
        }

        if let markerBuffer, markerVertexCount > 1 {
            var markerUniforms = WaveformUniforms(lineColor: markerColor, viewportSize: viewportSize)
            encoder.setVertexBuffer(markerBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&markerUniforms, length: MemoryLayout<WaveformUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&markerUniforms, length: MemoryLayout<WaveformUniforms>.stride, index: 1)
            encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: markerVertexCount)
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

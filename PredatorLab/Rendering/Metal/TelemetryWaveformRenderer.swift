// PredatorLab/Rendering/Metal/TelemetryWaveformRenderer.swift
// MTKView-backed GPU line renderer for a raw telemetry channel. Used for
// high-frequency signal traces (CAN bus channels, knock retard, boost, etc.)
// where a SwiftUI Path redraw per frame is too costly.

import MetalKit

private struct WaveformUniforms {
    var lineColor: SIMD4<Float>
    var viewportSize: SIMD2<Float>
}

@MainActor
final class TelemetryWaveformRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var vertexCount = 0

    var lineColor: SIMD4<Float> = SIMD4(0.98, 0.55, 0.15, 1.0)

    init?(device: MTLDevice) {
        guard let queue = device.makeCommandQueue() else { return nil }
        self.device = device
        self.commandQueue = queue
        super.init()
        buildPipeline()
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

    /// Uploads a normalized telemetry series as a line-strip vertex buffer.
    /// `series` values are mapped into clip space (-1...1) on both axes.
    func update(series: TelemetryChannelSeries) {
        guard !series.isEmpty else {
            vertexBuffer = nil
            vertexCount = 0
            return
        }

        let normalized = series.normalized()
        let count = normalized.count
        var vertices = [SIMD2<Float>]()
        vertices.reserveCapacity(count)

        for (index, value) in normalized.enumerated() {
            let x = count > 1 ? (Float(index) / Float(count - 1)) * 2.0 - 1.0 : 0.0
            let y = Float(value) * 2.0 - 1.0
            vertices.append(SIMD2(x, y))
        }

        vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<SIMD2<Float>>.stride,
            options: .storageModeShared
        )
        vertexCount = vertices.count
    }

    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    nonisolated func draw(in view: MTKView) {
        MainActor.assumeIsolated {
            self.render(in: view)
        }
    }

    private func render(in view: MTKView) {
        guard let pipelineState,
              let vertexBuffer,
              vertexCount > 1,
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        var uniforms = WaveformUniforms(
            lineColor: lineColor,
            viewportSize: SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height))
        )

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<WaveformUniforms>.stride, index: 1)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<WaveformUniforms>.stride, index: 1)
        encoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: vertexCount)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

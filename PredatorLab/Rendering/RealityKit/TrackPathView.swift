// PredatorLab/Rendering/RealityKit/TrackPathView.swift
// SwiftUI wrapper for the RealityKit track/lap path visualization.

import SwiftUI
import RealityKit

@MainActor
struct TrackPathView: UIViewRepresentable {
    let series: TelemetryChannelSeries
    var scrubProgress: Double = 0

    func makeCoordinator() -> TrackPathScene { TrackPathScene() }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        context.coordinator.build(in: arView, series: series)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.scrub(toProgress: scrubProgress)
    }
}

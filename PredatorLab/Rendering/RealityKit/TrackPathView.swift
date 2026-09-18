// PredatorLab/Rendering/RealityKit/TrackPathView.swift
// SwiftUI wrapper for the RealityKit track/lap path visualization.
// Supports tap-to-scrub: tapping anywhere on the path maps the tap's
// horizontal position to playback progress and writes it back through
// the scrubProgress binding.

import SwiftUI
import RealityKit

@MainActor
struct TrackPathView: UIViewRepresentable {
    let series: TelemetryChannelSeries
    @Binding var scrubProgress: Double

    final class Coordinator: NSObject {
        let scene = TrackPathScene()
        var onScrub: (Double) -> Void = { _ in }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view, view.bounds.width > 0 else { return }
            let x = gesture.location(in: view).x
            let progress = Double(x / view.bounds.width)
            onScrub(min(max(progress, 0), 1))
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        context.coordinator.scene.build(in: arView, series: series)

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.onScrub = { progress in
            scrubProgress = progress
        }
        context.coordinator.scene.scrub(toProgress: scrubProgress)
    }
}

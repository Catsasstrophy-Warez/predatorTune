// PredatorLab/Rendering/RealityKit/GaugeClusterView.swift
// SwiftUI wrapper for the RealityKit 3D gauge cluster.

import SwiftUI
import RealityKit

@MainActor
struct GaugeClusterView: UIViewRepresentable {
    let specs: [GaugeSpec]
    let values: [UUID: Double]

    func makeCoordinator() -> GaugeClusterScene { GaugeClusterScene() }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        context.coordinator.build(in: arView, specs: specs)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        for spec in specs {
            let value = values[spec.id] ?? spec.minValue
            context.coordinator.update(spec: spec, value: value)
        }
    }
}

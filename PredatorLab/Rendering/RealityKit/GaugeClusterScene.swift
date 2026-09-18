// PredatorLab/Rendering/RealityKit/GaugeClusterScene.swift
// Builds a small cluster of 3D RealityKit gauges (dial + needle) driven by
// live telemetry values. Runs the ARView in non-AR (windowed) mode so it
// renders a plain 3D scene without requesting camera access.

import RealityKit
import UIKit

struct GaugeSpec: Identifiable {
    let id = UUID()
    let title: String
    let minValue: Double
    let maxValue: Double
    let color: UIColor
}

@MainActor
final class GaugeClusterScene {
    private var needleEntities: [UUID: Entity] = [:]
    private var valueLabelEntities: [UUID: ModelEntity] = [:]
    private var lastDisplayedValues: [UUID: Int] = [:]
    private let anchor = AnchorEntity(world: .zero)
    private let labelFont = MeshResource.Font.systemFont(ofSize: 0.014, weight: .semibold)

    func build(in arView: ARView, specs: [GaugeSpec]) {
        arView.scene.anchors.removeAll()
        needleEntities.removeAll()
        valueLabelEntities.removeAll()
        lastDisplayedValues.removeAll()
        anchor.children.removeAll()

        let spacing: Float = 0.14
        let startX = -Float(specs.count - 1) * spacing / 2

        for (index, spec) in specs.enumerated() {
            let x = startX + Float(index) * spacing
            let dialEntity = makeDial(color: spec.color)
            dialEntity.position = SIMD3(x, 0, 0)
            anchor.addChild(dialEntity)

            let needle = makeNeedle(color: .white)
            needle.position = SIMD3(x, 0, 0.003)
            anchor.addChild(needle)
            needleEntities[spec.id] = needle

            let titleLabel = makeTextEntity(spec.title, color: .lightGray)
            titleLabel.position = SIMD3(x - 0.03, -0.075, 0.003)
            anchor.addChild(titleLabel)

            let valueLabel = makeTextEntity("--", color: .white)
            valueLabel.position = SIMD3(x - 0.02, -0.095, 0.003)
            anchor.addChild(valueLabel)
            valueLabelEntities[spec.id] = valueLabel
        }

        arView.scene.addAnchor(anchor)
        arView.cameraMode = .nonAR
        arView.environment.background = .color(.black)

        let cameraEntity = PerspectiveCamera()
        cameraEntity.position = SIMD3(0, 0, 0.4)
        let cameraAnchor = AnchorEntity(world: .zero)
        cameraAnchor.addChild(cameraEntity)
        arView.scene.addAnchor(cameraAnchor)

        let light = PointLight()
        light.light.intensity = 4000
        light.position = SIMD3(0, 0.2, 0.3)
        let lightAnchor = AnchorEntity(world: .zero)
        lightAnchor.addChild(light)
        arView.scene.addAnchor(lightAnchor)
    }

    /// Rotates a gauge's needle to reflect `value` within its spec range.
    /// Sweeps -120deg...+120deg, matching a conventional automotive dial.
    func update(spec: GaugeSpec, value: Double) {
        guard let needle = needleEntities[spec.id] else { return }
        let span = spec.maxValue - spec.minValue
        let fraction = span > .ulpOfOne ? (value - spec.minValue) / span : 0
        let clamped = min(max(fraction, 0), 1)
        let angleDegrees = -120 + clamped * 240
        let angleRadians = Float(angleDegrees * .pi / 180)
        needle.transform.rotation = simd_quatf(angle: angleRadians, axis: SIMD3(0, 0, 1))

        let rounded = Int(value.rounded())
        guard lastDisplayedValues[spec.id] != rounded, let label = valueLabelEntities[spec.id] else { return }
        lastDisplayedValues[spec.id] = rounded
        label.model?.mesh = MeshResource.generateText(
            "\(rounded)",
            extrusionDepth: 0.0005,
            font: labelFont
        )
    }

    private func makeDial(color: UIColor) -> ModelEntity {
        let mesh = MeshResource.generateCylinder(height: 0.002, radius: 0.06)
        var material = SimpleMaterial(color: color.withAlphaComponent(0.85), isMetallic: true)
        material.roughness = .float(0.3)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.transform.rotation = simd_quatf(angle: .pi / 2, axis: SIMD3(1, 0, 0))
        return entity
    }

    private func makeTextEntity(_ text: String, color: UIColor) -> ModelEntity {
        let mesh = MeshResource.generateText(text, extrusionDepth: 0.0005, font: labelFont)
        var material = UnlitMaterial(color: color)
        material.blending = .transparent(opacity: .init(floatLiteral: 1.0))
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.scale = SIMD3(repeating: 1)
        return entity
    }

    private func makeNeedle(color: UIColor) -> ModelEntity {
        let mesh = MeshResource.generateBox(size: SIMD3(0.05, 0.004, 0.001), cornerRadius: 0.001)
        let material = SimpleMaterial(color: color, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position.x += 0.02
        let pivot = ModelEntity()
        pivot.addChild(entity)
        return pivot
    }
}

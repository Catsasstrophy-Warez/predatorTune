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
    /// Values at or above this enter the redline zone; nil disables it.
    var warningThreshold: Double? = nil
}

@MainActor
final class GaugeClusterScene {
    private var needleEntities: [UUID: Entity] = [:]
    private var needleModelEntities: [UUID: ModelEntity] = [:]
    private var needleIsRedlined: [UUID: Bool] = [:]
    private var valueLabelEntities: [UUID: ModelEntity] = [:]
    private var lastDisplayedValues: [UUID: Int] = [:]
    private let anchor = AnchorEntity(world: .zero)
    private let labelFont = MeshResource.Font.systemFont(ofSize: 0.014, weight: .semibold)

    func build(in arView: ARView, specs: [GaugeSpec]) {
        arView.scene.anchors.removeAll()
        needleEntities.removeAll()
        needleModelEntities.removeAll()
        needleIsRedlined.removeAll()
        valueLabelEntities.removeAll()
        lastDisplayedValues.removeAll()
        anchor.children.removeAll()

        let spacing: Float = 0.14
        let startX = -Float(specs.count - 1) * spacing / 2

        let chassisWidth = max(Float(specs.count - 1) * spacing + 0.16, 0.3)
        let chassis = makeChassisSilhouette(width: chassisWidth)
        chassis.position = SIMD3(0, -0.13, -0.02)
        anchor.addChild(chassis)

        for (index, spec) in specs.enumerated() {
            let x = startX + Float(index) * spacing
            let dialEntity = makeDial(color: spec.color)
            dialEntity.position = SIMD3(x, 0, 0)
            anchor.addChild(dialEntity)

            if let warningThreshold = spec.warningThreshold {
                let redlineGroup = makeRedlineArc(spec: spec, warningThreshold: warningThreshold)
                redlineGroup.position = SIMD3(x, 0, 0.0021)
                anchor.addChild(redlineGroup)
            }

            let (pivot, needleModel) = makeNeedle(color: .white)
            pivot.position = SIMD3(x, 0, 0.003)
            anchor.addChild(pivot)
            needleEntities[spec.id] = pivot
            needleModelEntities[spec.id] = needleModel
            needleIsRedlined[spec.id] = false

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

        if let warningThreshold = spec.warningThreshold {
            let isRedlined = value >= warningThreshold
            if needleIsRedlined[spec.id] != isRedlined {
                needleIsRedlined[spec.id] = isRedlined
                needleModelEntities[spec.id]?.model?.materials = [
                    SimpleMaterial(color: isRedlined ? .systemRed : .white, isMetallic: false)
                ]
            }
        }

        let rounded = Int(value.rounded())
        guard lastDisplayedValues[spec.id] != rounded, let label = valueLabelEntities[spec.id] else { return }
        lastDisplayedValues[spec.id] = rounded
        label.model?.mesh = MeshResource.generateText(
            "\(rounded)",
            extrusionDepth: 0.0005,
            font: labelFont
        )
    }

    /// A simple low-poly side-profile car silhouette (body + cabin + two
    /// wheels), rendered dark and matte behind the gauge cluster to ground
    /// it visually as a dashboard rather than floating dials.
    private func makeChassisSilhouette(width: Float) -> Entity {
        let group = Entity()
        let bodyMaterial = SimpleMaterial(color: UIColor(white: 0.08, alpha: 1.0), isMetallic: false)
        let wheelMaterial = SimpleMaterial(color: UIColor(white: 0.03, alpha: 1.0), isMetallic: false)

        let bodyHeight: Float = 0.05
        let cabinHeight: Float = 0.045
        let cabinWidth = width * 0.45

        let body = ModelEntity(
            mesh: .generateBox(size: SIMD3(width, bodyHeight, 0.01), cornerRadius: 0.012),
            materials: [bodyMaterial]
        )
        group.addChild(body)

        let cabin = ModelEntity(
            mesh: .generateBox(size: SIMD3(cabinWidth, cabinHeight, 0.01), cornerRadius: 0.01),
            materials: [bodyMaterial]
        )
        cabin.position = SIMD3(0, bodyHeight / 2 + cabinHeight / 2 - 0.004, 0)
        group.addChild(cabin)

        for wheelX in [-width * 0.32, width * 0.32] {
            let wheel = ModelEntity(
                mesh: .generateCylinder(height: 0.012, radius: 0.02),
                materials: [wheelMaterial]
            )
            wheel.transform.rotation = simd_quatf(angle: .pi / 2, axis: SIMD3(1, 0, 0))
            wheel.position = SIMD3(wheelX, -bodyHeight / 2, 0.006)
            group.addChild(wheel)
        }

        return group
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

    /// Returns (pivot, needleMesh): rotate the pivot to sweep the needle;
    /// swap the mesh entity's material to reflect redline state.
    private func makeNeedle(color: UIColor) -> (pivot: ModelEntity, mesh: ModelEntity) {
        let mesh = MeshResource.generateBox(size: SIMD3(0.05, 0.004, 0.001), cornerRadius: 0.001)
        let material = SimpleMaterial(color: color, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position.x += 0.02
        let pivot = ModelEntity()
        pivot.addChild(entity)
        return (pivot, entity)
    }

    /// A ring of small red tick marks spanning the dial's warning zone,
    /// from `warningThreshold` up to `spec.maxValue`.
    private func makeRedlineArc(spec: GaugeSpec, warningThreshold: Double) -> Entity {
        let group = Entity()
        let span = spec.maxValue - spec.minValue
        guard span > .ulpOfOne else { return group }

        let startFraction = min(max((warningThreshold - spec.minValue) / span, 0), 1)
        let tickCount = max(Int((1 - startFraction) * 24), 1)
        let mesh = MeshResource.generateBox(size: SIMD3(0.012, 0.002, 0.0008), cornerRadius: 0.0004)
        let material = SimpleMaterial(color: .systemRed, isMetallic: false)

        for i in 0...tickCount {
            let fraction = startFraction + (1 - startFraction) * (Double(i) / Double(tickCount))
            let angleDegrees = -120 + fraction * 240
            let angleRadians = Float(angleDegrees * .pi / 180)

            let tick = ModelEntity(mesh: mesh, materials: [material])
            tick.position.x = 0.058
            let pivot = ModelEntity()
            pivot.addChild(tick)
            pivot.transform.rotation = simd_quatf(angle: angleRadians, axis: SIMD3(0, 0, 1))
            group.addChild(pivot)
        }
        return group
    }
}

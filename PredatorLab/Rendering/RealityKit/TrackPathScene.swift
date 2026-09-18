// PredatorLab/Rendering/RealityKit/TrackPathScene.swift
// Renders a 3D path built from a telemetry series: distance runs along X,
// the channel's magnitude runs along Y, producing a ribbon colored by value.
// A marker entity can be scrubbed along the path by playback progress.

import RealityKit
import UIKit

@MainActor
final class TrackPathScene {
    private let anchor = AnchorEntity(world: .zero)
    private var markerEntity: ModelEntity?
    private var pathPositions: [SIMD3<Float>] = []

    func build(in arView: ARView, series: TelemetryChannelSeries) {
        arView.scene.anchors.removeAll()
        anchor.children.removeAll()
        pathPositions.removeAll()

        guard !series.isEmpty else { return }

        let normalized = series.normalized()
        let count = normalized.count
        let width: Float = 0.4
        let height: Float = 0.12

        pathPositions.reserveCapacity(count)
        for (index, value) in normalized.enumerated() {
            let x = count > 1 ? (Float(index) / Float(count - 1)) * width - width / 2 : 0
            let y = Float(value) * height - height / 2
            pathPositions.append(SIMD3(x, y, 0))
        }

        for index in 0..<(pathPositions.count - 1) {
            let segment = makeSegment(from: pathPositions[index], to: pathPositions[index + 1], magnitude: normalized[index])
            anchor.addChild(segment)
        }

        let marker = ModelEntity(
            mesh: .generateSphere(radius: 0.006),
            materials: [SimpleMaterial(color: .white, isMetallic: true)]
        )
        marker.position = pathPositions.first ?? .zero
        anchor.addChild(marker)
        markerEntity = marker

        arView.scene.addAnchor(anchor)
        arView.cameraMode = .nonAR
        arView.environment.background = .color(.black)

        let camera = PerspectiveCamera()
        camera.position = SIMD3(0, 0.05, 0.55)
        let cameraAnchor = AnchorEntity(world: .zero)
        cameraAnchor.addChild(camera)
        arView.scene.addAnchor(cameraAnchor)

        let light = PointLight()
        light.light.intensity = 5000
        light.position = SIMD3(0, 0.3, 0.4)
        let lightAnchor = AnchorEntity(world: .zero)
        lightAnchor.addChild(light)
        arView.scene.addAnchor(lightAnchor)
    }

    /// Moves the marker to `progress` (0...1) along the recorded path.
    func scrub(toProgress progress: Double) {
        guard !pathPositions.isEmpty else { return }
        let clamped = min(max(progress, 0), 1)
        let index = Int((Double(pathPositions.count - 1) * clamped).rounded())
        markerEntity?.position = pathPositions[min(max(index, 0), pathPositions.count - 1)]
    }

    private func makeSegment(from start: SIMD3<Float>, to end: SIMD3<Float>, magnitude: Double) -> ModelEntity {
        let delta = end - start
        let length = simd_length(delta)
        let mesh = MeshResource.generateBox(size: SIMD3(max(length, 0.0001), 0.003, 0.003), cornerRadius: 0.0015)

        let color = colorForMagnitude(magnitude)
        let material = SimpleMaterial(color: color, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])

        entity.position = (start + end) / 2
        if length > .ulpOfOne {
            let direction = simd_normalize(delta)
            entity.transform.rotation = simd_quatf(from: SIMD3(1, 0, 0), to: direction)
        }
        return entity
    }

    private func colorForMagnitude(_ magnitude: Double) -> UIColor {
        // Cool blue at low magnitude, hot red at high magnitude.
        UIColor(hue: CGFloat(0.6 - 0.6 * magnitude), saturation: 0.85, brightness: 0.95, alpha: 1.0)
    }
}

// PredatorLab/Rendering/RealityKit/TrackPathScene.swift
// Renders a 3D path colored by magnitude, with a marker that can be scrubbed by playback
// progress. Two sources: a telemetry series (time along X, value along Y), or a GPS route
// recorded during a session (top-down map, colored by speed).

import RealityKit
import UIKit

@MainActor
final class TrackPathScene {
    /// Each segment is its own entity, so long logs are downsampled to keep rendering smooth.
    private static let maximumSegments = 500

    private let anchor = AnchorEntity(world: .zero)
    private var markerEntity: ModelEntity?
    private var pathPositions: [SIMD3<Float>] = []

    func build(in arView: ARView, series: TelemetryChannelSeries) {
        let normalized = series.normalized()
        let count = normalized.count
        let width: Float = 0.4
        let height: Float = 0.12
        let positions: [SIMD3<Float>] = normalized.enumerated().map { index, value in
            let x = count > 1 ? (Float(index) / Float(count - 1)) * width - width / 2 : 0
            return SIMD3(x, Float(value) * height - height / 2, 0)
        }
        build(in: arView, positions: positions, magnitudes: normalized)
    }

    /// Top-down map of a recorded route: east along X, north along Y, colored by GPS speed.
    func build(in arView: ARView, track: [TrackSample]) {
        guard let origin = track.first else { build(in: arView, positions: [], magnitudes: []); return }
        let metersPerDegreeLatitude = 110_540.0
        let metersPerDegreeLongitude = 111_320.0 * cos(origin.latitude * .pi / 180)
        let meters = track.map { sample in
            SIMD2((sample.longitude - origin.longitude) * metersPerDegreeLongitude,
                  (sample.latitude - origin.latitude) * metersPerDegreeLatitude)
        }
        let xs = meters.map(\.x), ys = meters.map(\.y)
        let minX = xs.min() ?? 0, maxX = xs.max() ?? 0, minY = ys.min() ?? 0, maxY = ys.max() ?? 0
        // Fit the larger dimension into the view while keeping the map's aspect ratio.
        let scale = 0.4 / max(maxX - minX, (maxY - minY) * 1.6, 1)
        let positions = meters.map { point in
            SIMD3(Float((point.x - (minX + maxX) / 2) * scale), Float((point.y - (minY + maxY) / 2) * scale), 0)
        }
        let speeds = track.map { $0.speed ?? 0 }
        let fastest = max(speeds.max() ?? 0, 0.1)
        build(in: arView, positions: positions, magnitudes: speeds.map { $0 / fastest })
    }

    private func build(in arView: ARView, positions allPositions: [SIMD3<Float>], magnitudes allMagnitudes: [Double]) {
        arView.scene.anchors.removeAll()
        anchor.children.removeAll()
        let stride = max(1, allPositions.count / Self.maximumSegments)
        let picked = Swift.stride(from: 0, to: allPositions.count, by: stride).map { $0 }
        pathPositions = picked.map { allPositions[$0] }
        let magnitudes = picked.map { allMagnitudes.indices.contains($0) ? allMagnitudes[$0] : 0 }

        if pathPositions.count > 1 {
            for index in 0..<(pathPositions.count - 1) {
                anchor.addChild(makeSegment(from: pathPositions[index], to: pathPositions[index + 1], magnitude: magnitudes[index]))
            }
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

        let material = SimpleMaterial(color: colorForMagnitude(magnitude), isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])

        entity.position = (start + end) / 2
        if length > .ulpOfOne {
            entity.transform.rotation = simd_quatf(from: SIMD3(1, 0, 0), to: simd_normalize(delta))
        }
        return entity
    }

    private func colorForMagnitude(_ magnitude: Double) -> UIColor {
        // Cool blue at low magnitude, hot red at high magnitude.
        UIColor(hue: CGFloat(0.6 - 0.6 * min(max(magnitude, 0), 1)), saturation: 0.85, brightness: 0.95, alpha: 1.0)
    }
}

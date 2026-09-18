// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import Foundation

enum TelemetryAlignmentMethod: String, Codable, CaseIterable, Sendable {
    case time, rpm, eventMarkers, crossCorrelation, piecewise, userAnchors
}

struct TelemetryAlignmentAnchor: Equatable, Sendable {
    let activeTime: TimeInterval
    let baselineTime: TimeInterval
}

struct TelemetryAlignmentResult: Equatable, Sendable {
    let method: TelemetryAlignmentMethod
    let anchors: [TelemetryAlignmentAnchor]
    let medianResidualSeconds: Double?
    let confidence: Double
    let evidenceClass: TelemetryEvidenceClass
    let notes: [String]
}

enum TelemetryAlignmentEngine {
    static func time(activeTime: TimeInterval) -> TelemetryAlignmentResult {
        .init(method: .time,
              anchors: [.init(activeTime: activeTime, baselineTime: activeTime)],
              medianResidualSeconds: 0, confidence: 1,
              evidenceClass: .observed,
              notes: ["Identity time alignment; does not prove equivalent operating state."])
    }

    static func rpm(active: ForensicSessionDatasetRev85,
                    baseline: ForensicSessionDatasetRev85,
                    activeTime: TimeInterval) -> TelemetryAlignmentResult {
        guard let activeRPM = ForensicDataAdapterRev85.nearestRPM(in: active, time: activeTime),
              let series = baseline.series.first(where: {
                  $0.descriptor.displayName.lowercased().contains("rpm") ||
                  $0.descriptor.id.lowercased().contains("engine speed")
              }),
              let match = series.samples.min(by: { abs($0.value-activeRPM) < abs($1.value-activeRPM) })
        else {
            return .init(method: .rpm, anchors: [], medianResidualSeconds: nil, confidence: 0,
                         evidenceClass: .unknown,
                         notes: ["Observed RPM was not available in both sessions."])
        }
        return .init(method: .rpm,
                     anchors: [.init(activeTime: activeTime, baselineTime: match.time)],
                     medianResidualSeconds: nil, confidence: 0.5,
                     evidenceClass: .derived,
                     notes: ["Nearest-RPM alignment is a comparison aid, not proof of equivalent load or vehicle state."])
    }
}

import Foundation

/// Reusable hysteretic state machine for noisy diagnostic signals.
/// Thresholds are authored analysis rules unless a claim/source explicitly verifies them.
enum DiagnosticEpisodeState: String, Codable { case normal, suspect, confirmed, recovering }

struct DiagnosticStateMachineRule: Codable, Equatable {
    let id: String
    let enterThreshold: Double
    let confirmDuration: TimeInterval
    let exitThreshold: Double
    let recoveryDuration: TimeInterval
    let directionAbove: Bool
    let provenance: String
}

struct DiagnosticStateTransition: Codable, Equatable {
    let timestamp: TimeInterval
    let from: DiagnosticEpisodeState
    let to: DiagnosticEpisodeState
    let value: Double
}

struct DiagnosticStateMachineResult: Codable, Equatable {
    let ruleID: String
    let finalState: DiagnosticEpisodeState
    let transitions: [DiagnosticStateTransition]
    let confirmedIntervals: [ClosedRange<TimeInterval>]
}

enum DiagnosticStateMachine {
    static func evaluate(samples: [(TimeInterval, Double)], rule: DiagnosticStateMachineRule) -> DiagnosticStateMachineResult {
        var state: DiagnosticEpisodeState = .normal
        var transitions: [DiagnosticStateTransition] = []
        var candidateStart: TimeInterval?
        var recoveryStart: TimeInterval?
        var confirmedStart: TimeInterval?
        var intervals: [ClosedRange<TimeInterval>] = []

        func abnormal(_ value: Double) -> Bool { rule.directionAbove ? value >= rule.enterThreshold : value <= rule.enterThreshold }
        func recovered(_ value: Double) -> Bool { rule.directionAbove ? value <= rule.exitThreshold : value >= rule.exitThreshold }
        func move(_ next: DiagnosticEpisodeState, at t: TimeInterval, value: Double) {
            transitions.append(.init(timestamp: t, from: state, to: next, value: value)); state = next
        }

        for (t, value) in samples.sorted(by: { $0.0 < $1.0 }) {
            switch state {
            case .normal:
                if abnormal(value) { candidateStart = t; move(.suspect, at: t, value: value) }
            case .suspect:
                if !abnormal(value) { candidateStart = nil; move(.normal, at: t, value: value) }
                else if let start = candidateStart, t - start >= rule.confirmDuration - 1e-9 {
                    confirmedStart = start; move(.confirmed, at: t, value: value)
                }
            case .confirmed:
                if recovered(value) { recoveryStart = t; move(.recovering, at: t, value: value) }
            case .recovering:
                if abnormal(value) { recoveryStart = nil; move(.confirmed, at: t, value: value) }
                else if let start = recoveryStart, t - start >= rule.recoveryDuration - 1e-9 {
                    if let confirmedStart { intervals.append(confirmedStart...t) }
                    confirmedStart = nil; recoveryStart = nil; candidateStart = nil
                    move(.normal, at: t, value: value)
                }
            }
        }
        if let confirmedStart, let last = samples.max(by: { $0.0 < $1.0 })?.0 { intervals.append(confirmedStart...last) }
        return .init(ruleID: rule.id, finalState: state, transitions: transitions, confirmedIntervals: intervals)
    }
}

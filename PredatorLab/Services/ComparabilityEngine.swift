import Foundation

enum ComparabilityGrade: String, Codable { case excellent, good, limited, poor, insufficient }
struct ComparabilityDimension: Identifiable, Codable, Equatable { let id: String; let label: String; let score: Double?; let detail: String; let weight: Double }
struct ComparabilityReport: Codable, Equatable {
    let score: Double?; let grade: ComparabilityGrade; let dimensions: [ComparabilityDimension]; let blockers: [String]
    var isSuitableForValidation: Bool { (score ?? 0) >= 0.70 && blockers.isEmpty }
}

enum ComparabilityEngine {
    static func compare(_ a: DiagnosticEvidencePackage, _ b: DiagnosticEvidencePackage) -> ComparabilityReport {
        func value(_ key: String, _ p: DiagnosticEvidencePackage) -> Double? { p.observations.first { $0.key == key }?.value }
        func closeness(_ x: Double?, _ y: Double?, tolerance: Double) -> Double? {
            guard let x, let y else { return nil }; return max(0, 1 - abs(x-y)/tolerance)
        }
        var d: [ComparabilityDimension] = []
        let sameType = a.episode.eventType == b.episode.eventType
        d.append(.init(id:"event", label:"Event type", score:sameType ? 1:0, detail:sameType ? "Same event type." : "Different event types.", weight:3))
        let rpm = closeness(value("rpm_at_onset",a), value("rpm_at_onset",b), tolerance:1000)
        d.append(.init(id:"rpm", label:"RPM at onset", score:rpm, detail:pair(value("rpm_at_onset",a),value("rpm_at_onset",b),unit:"rpm"), weight:2))
        let iat = closeness(value("iat2_at_peak",a), value("iat2_at_peak",b), tolerance:30)
        d.append(.init(id:"iat2", label:"IAT2", score:iat, detail:pair(value("iat2_at_peak",a),value("iat2_at_peak",b),unit:""), weight:1))
        let shift = closeness(value("nearest_shift_delta",a), value("nearest_shift_delta",b), tolerance:0.5)
        d.append(.init(id:"shift", label:"Shift-relative timing", score:shift, detail:pair(value("nearest_shift_delta",a),value("nearest_shift_delta",b),unit:"s"), weight:2))
        let duration = closeness(value("episode_duration",a), value("episode_duration",b), tolerance:max(max(a.episode.duration,b.episode.duration),0.25))
        d.append(.init(id:"duration", label:"Event duration", score:duration, detail:pair(value("episode_duration",a),value("episode_duration",b),unit:"s"), weight:1))
        let known = d.compactMap { item -> (Double,Double)? in item.score.map { ($0,item.weight) } }
        let totalWeight = known.reduce(0) { $0+$1.1 }; let score = totalWeight > 0 ? known.reduce(0){$0+$1.0*$1.1}/totalWeight : nil
        var blockers:[String]=[]
        if !sameType { blockers.append("Event types differ.") }
        if rpm == nil {
            blockers.append("RPM-at-onset evidence is missing from one or both events.")
        } else if let aRPM = value("rpm_at_onset", a), let bRPM = value("rpm_at_onset", b), abs(aRPM - bRPM) > 1000 {
            blockers.append("RPM-at-onset differs by more than 1,000 rpm; validation comparison is not sufficiently load-matched.")
        }
        let grade: ComparabilityGrade = score.map { $0 >= 0.90 ? .excellent : $0 >= 0.75 ? .good : $0 >= 0.55 ? .limited : .poor } ?? .insufficient
        return .init(score:score, grade:grade, dimensions:d, blockers:blockers)
    }
    private static func pair(_ a:Double?,_ b:Double?,unit:String)->String { guard let a,let b else{return "Missing evidence."}; return String(format:"%.2f → %.2f %@",a,b,unit) }
}

enum ValidationOutcome: String, Codable { case notTested, insufficientEvidence, notComparable, noImprovement, mixed, improved, stronglyImproved, regression }
struct ValidationAssessment: Codable, Equatable { let outcome: ValidationOutcome; let explanation:[String] }
enum RepairValidationEngine {
    static func assess(comparison: EventComparisonResult, comparability: ComparabilityReport) -> ValidationAssessment {
        guard comparability.isSuitableForValidation else { return .init(outcome:.notComparable, explanation:["Operating conditions are not sufficiently comparable for a repair-effectiveness conclusion."] + comparability.blockers) }
        let pw = comparison.deltas.first{$0.label=="PW Margin"}?.delta
        let pressure = comparison.deltas.first{$0.label=="Peak Pressure Error"}?.delta
        let lambda = comparison.deltas.first{$0.label=="Peak Lambda Error"}?.delta
        var plus=0, minus=0; if let pw { pw > 0 ? (plus += 1):(minus += 1) }; if let pressure { pressure < 0 ? (plus += 1):(minus += 1) }; if let lambda { lambda < 0 ? (plus += 1):(minus += 1) }
        if plus == 0 && minus == 0 { return .init(outcome:.insufficientEvidence, explanation:["No comparable directional evidence dimensions were available."]) }
        if plus >= 3 && minus == 0 { return .init(outcome:.stronglyImproved, explanation:["All available primary evidence dimensions moved in the favorable direction."]) }
        if plus > minus { return .init(outcome:.improved, explanation:["More comparable evidence dimensions improved than regressed."]) }
        if minus > plus { return .init(outcome:.regression, explanation:["More comparable evidence dimensions regressed than improved."]) }
        return .init(outcome:.mixed, explanation:["Comparable evidence moved in mixed directions."])
    }
}

extension ComparabilityEngine {
    /// Combines telemetry-event comparability with recorded test setup. Missing setup context does
    /// not invent a penalty; known contradictory context can lower the score. Calibration is treated
    /// as a designated experimental variable by TestContextComparabilityEngine.
    static func incorporatingTestContext(_ telemetry: ComparabilityReport, _ context: TestContextReport) -> ComparabilityReport {
        guard let telemetryScore = telemetry.score else { return telemetry }
        guard let contextScore = context.score else {
            return .init(score: telemetryScore, grade: telemetry.grade, dimensions: telemetry.dimensions,
                         blockers: telemetry.blockers + context.missingCriticalContext)
        }
        let combined = telemetryScore * 0.75 + contextScore * 0.25
        let grade: ComparabilityGrade = combined >= 0.90 ? .excellent : combined >= 0.75 ? .good : combined >= 0.55 ? .limited : .poor
        let contextDimension = ComparabilityDimension(id:"test_context", label:"Recorded test setup", score:contextScore,
            detail:"Test-setup comparability \(Int(contextScore * 100))%. See Test Setup section for dimensions.", weight:3)
        return .init(score:combined, grade:grade, dimensions:telemetry.dimensions + [contextDimension], blockers:telemetry.blockers)
    }
}

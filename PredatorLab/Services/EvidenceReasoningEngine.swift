import Foundation

/// A transparent heuristic fit score, not a probability or OEM diagnosis.
struct HypothesisAssessment: Identifiable, Codable, Equatable {
    var id: R04HypothesisID { hypothesisID }
    let hypothesisID: R04HypothesisID
    let title: String
    let fitScore: Double
    let confidence: ConfidenceLevel
    let supports: [String]
    let contradicts: [String]
    let missing: [String]

    var fitPercent: Int { Int((max(0, min(1, fitScore)) * 100).rounded()) }
}

struct InvestigationAssessment: Codable {
    let definitionID: String
    let assessments: [HypothesisAssessment]
    let recommendations: [DiagnosticRecommendation]
    let missingRequiredChannels: [CanonicalChannel]
    let caveats: [String]
}

enum EvidenceReasoningEngine {
    static func assessR04(log: ParsedLogData, evidence: DiagnosticEvidencePackage) -> InvestigationAssessment {
        let definition = InvestigationCatalog.r04
        let values = Dictionary(uniqueKeysWithValues: evidence.observations.compactMap { obs in obs.value.map { (obs.key, $0) } })
        let margin = values["pw_margin_min"]
        let pressureError = values["pressure_error_peak"]
        let lambdaError = values["lambda_error_peak"]
        let shiftDelta = values["nearest_shift_delta"]

        func assessment(_ hypothesis: DiagnosticHypothesis, score: Double, supports: [String], contradicts: [String], missing: [String]) -> HypothesisAssessment {
            let bounded = max(0, min(1, score))
            let confidence: ConfidenceLevel
            switch bounded {
            case 0.80...: confidence = .c3
            case 0.60..<0.80: confidence = .c2
            case 0.35..<0.60: confidence = .c1
            default: confidence = .c0
            }
            return HypothesisAssessment(hypothesisID: hypothesis.id, title: hypothesis.title, fitScore: bounded, confidence: confidence, supports: supports, contradicts: contradicts, missing: missing)
        }

        var results: [HypothesisAssessment] = []
        for h in definition.hypotheses {
            var score = 0.35
            var supports: [String] = []
            var contradicts: [String] = []
            var missing: [String] = []
            switch h.id {
            case .h1bInjectionWindow:
                if let margin {
                    if margin <= 0.25 { score += 0.50; supports.append("Minimum injector PW margin was ≤0.25 ms in the Flight Recorder window.") }
                    else if margin <= 0.75 { score += 0.30; supports.append("Injector PW margin became small (≤0.75 ms).") }
                    else if margin > 1.5 { score -= 0.25; contradicts.append("Injector PW retained >1.5 ms margin in the captured window.") }
                } else { missing.append("Actual and maximum available injector PW") }
                if let pressureError, pressureError < 3 { score += 0.10; supports.append("Fuel-pressure tracking stayed comparatively close (<3 psi peak absolute error).") }
            case .h2PumpPressure:
                if let pressureError {
                    if pressureError >= 5 { score += 0.45; supports.append("Peak absolute fuel-pressure error was ≥5 psi.") }
                    else if pressureError < 3 { score -= 0.20; contradicts.append("Fuel-pressure error stayed below 3 psi in the captured window.") }
                } else { missing.append("Commanded and actual fuel pressure") }
                if let lambdaError, lambdaError >= 0.05 { score += 0.15; supports.append("Lambda tracking error was material (≥0.05 λ).") }
            case .h4DCTTransient:
                if let shiftDelta {
                    if shiftDelta <= 0.10 { score += 0.45; supports.append("Event onset was within 100 ms of a detected shift episode.") }
                    else if shiftDelta <= 0.25 { score += 0.25; supports.append("Event onset was within 250 ms of a detected shift episode.") }
                    else if shiftDelta > 1.0 { score -= 0.15; contradicts.append("No detected shift was within 1 s of event onset.") }
                } else { missing.append("A detectable gear/shift episode near the event") }
            case .h1aInjectorCapacity:
                if let margin, margin <= 0.5 { score += 0.15; supports.append("Injector demand approached the available pulse-width envelope.") }
                missing.append("Injector characterization / mass-flow demand needed to distinguish physical flow capacity from injection-window limitation")
            case .h3ModeledFlowLimit:
                if let pressureError, pressureError < 3 { score += 0.10; supports.append("Protection occurred without a large fuel-pressure tracking error.") }
                missing.append("Strategy-specific modeled fuel-flow limit and controller ownership evidence")
            case .h5PIDIdentity:
                missing.append("Verified parameter identity/source metadata and strategy definition")
            case .h6SecondaryProtection:
                missing.append("Correlated torque/spark/protection source-state timeline")
            case .h7PressureStrategy:
                if pressureError != nil { supports.append("Fuel-pressure command/actual data are present for pressure-strategy review.") }
                missing.append("Pressure-command strategy behavior across comparable events")
            }
            results.append(assessment(h, score: score, supports: supports, contradicts: contradicts, missing: missing))
        }
        results.sort { $0.fitScore > $1.fitScore }

        let plausibleIDs = Set(results.filter { $0.fitScore >= 0.35 }.map(\.hypothesisID))
        let hypotheses = definition.hypotheses.map { h -> DiagnosticHypothesis in
            var copy = h
            copy.isPlausible = plausibleIDs.contains(h.id)
            if let match = results.first(where: { $0.hypothesisID == h.id }) { copy.confidence = match.confidence }
            return copy
        }
        let recs = DiagnosticIntelligenceEngine.recommendNextMeasurements(hypotheses: hypotheses)
        let missingChannels = DiagnosticIntelligenceEngine.missingRequiredChannels(for: definition, in: log)
        var caveats = ["Fit scores are transparent PredatorLab heuristics, not probabilities, OEM conclusions, or proof of causation."]
        if !evidence.acquisitionWarnings.isEmpty { caveats.append("Acquisition-quality warnings reduce how strongly this event should be interpreted.") }
        if !missingChannels.isEmpty { caveats.append("Critical R04 channels are missing; unresolved hypotheses should remain open.") }
        return InvestigationAssessment(definitionID: definition.id, assessments: results, recommendations: recs, missingRequiredChannels: missingChannels, caveats: caveats)
    }
}

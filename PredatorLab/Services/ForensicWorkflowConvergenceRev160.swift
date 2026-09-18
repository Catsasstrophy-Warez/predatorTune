import Foundation

// Rev160: workflow-level convergence. These models coordinate admitted evidence; they do not
// promote derived relationships into causal, source-verified, or vehicle-validated truth.

struct ForensicMeasurementPlanItem: Identifiable, Hashable, Sendable, Codable {
    enum State: String, Codable, Sendable { case missing, requested, captured, semanticsVerified, satisfied }
    let id: String
    let measurement: String
    let rationale: String
    let requiredSemanticProof: String
    let expectedDiscriminator: String
    var state: State
}

struct ForensicAcquisitionPlan: Identifiable, Hashable, Sendable, Codable {
    let id: String
    let title: String
    let hypothesisID: String?
    let createdAtCursorSeconds: Double?
    let authorityCeiling: String
    var items: [ForensicMeasurementPlanItem]

    var isSatisfied: Bool { !items.isEmpty && items.allSatisfy { $0.state == .satisfied } }
}

enum ForensicAcquisitionPlanEngine {
    static func makePlan(from snapshot: ForensicInvestigationSnapshot) -> ForensicAcquisitionPlan {
        let items = snapshot.acquisitionChecklist.map { item in
            ForensicMeasurementPlanItem(
                id: item.id,
                measurement: item.measurement,
                rationale: item.rationale,
                requiredSemanticProof: semanticProof(for: item.measurement),
                expectedDiscriminator: discriminator(for: item.measurement, hypothesisID: snapshot.hypothesisID),
                state: .missing
            )
        }
        return .init(
            id: "plan.\(snapshot.hypothesisID ?? "investigation").\(snapshot.time.map(String.init) ?? "no-time")",
            title: "Acquire Missing Discriminators",
            hypothesisID: snapshot.hypothesisID,
            createdAtCursorSeconds: snapshot.time,
            authorityCeiling: "CAPTURED DATA MUST STILL PASS SEMANTIC VERIFICATION",
            items: items
        )
    }

    static func evaluate(_ plan: ForensicAcquisitionPlan, availableVerifiedMeasurements: Set<String>) -> ForensicAcquisitionPlan {
        var updated = plan
        updated.items = plan.items.map { item in
            var copy = item
            if availableVerifiedMeasurements.contains(normalize(item.measurement)) { copy.state = .satisfied }
            return copy
        }
        return updated
    }

    static func normalize(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private static func semanticProof(for measurement: String) -> String {
        let m = measurement.lowercased()
        if m.contains("shaft") { return "Verify controller/source identity, shaft identity, unit, scaling, and time alignment." }
        if m.contains("gear") { return "Verify commanded/actual semantic identity and valid state encoding." }
        if m.contains("clutch") { return "Verify clutch identity, quantity meaning, unit/scaling, and controller provenance." }
        if m.contains("lambda") { return "Verify sensor/source identity, equivalence-ratio vs lambda semantics, unit/scaling, and latency." }
        return "Verify source, parameter identity, unit, scaling, cadence, and timestamp alignment."
    }

    private static func discriminator(for measurement: String, hypothesisID: String?) -> String {
        "Tests whether \(measurement) reduces ambiguity in \(hypothesisID ?? "the current investigation") without assuming causality."
    }
}

struct HypothesisEvidenceLedger: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let supporting: [String]
    let contradicting: [String]
    let missing: [String]
    let contextOnly: [String]
    let falsificationTests: [String]
    let authorityCeiling: String

    var evidenceSummary: String {
        "\(supporting.count) support • \(contradicting.count) contradict • \(missing.count) missing • \(contextOnly.count) context"
    }
}

enum HypothesisEvidenceLedgerEngine {
    static func make(snapshot: ForensicInvestigationSnapshot) -> HypothesisEvidenceLedger? {
        guard let id = snapshot.hypothesisID else { return nil }
        let support = snapshot.activeBands.map { "Temporal overlap with admitted event: \($0.title)" }
        let context = snapshot.twinMatches.prefix(4).map { "Relevant Twin node: \($0.nodeName)" }
        let missing = snapshot.acquisitionChecklist.map(\.measurement)
        return .init(
            id: id,
            title: "Working hypothesis \(id)",
            supporting: support,
            contradicting: [],
            missing: missing,
            contextOnly: context,
            falsificationTests: missing.map { "Acquire and semantically verify \($0); reject or weaken \(id) if the verified observation conflicts with the required mechanism." },
            authorityCeiling: missing.isEmpty ? "CANDIDATE • REQUIRES CONTROLLED VALIDATION" : "INSUFFICIENT EVIDENCE • REQUIRED DISCRIMINATORS MISSING"
        )
    }
}

struct ForensicComparisonContract: Hashable, Sendable {
    enum Alignment: String, CaseIterable, Sendable { case time, rpm, event, crossCorrelation, manualAnchors, piecewise }
    let baselineLabel: String
    let candidateLabel: String
    let alignment: Alignment
    let authority: String
    let boundary: String
}

enum ForensicComparisonEngineRev160 {
    static func goldenCorpusAB(alignment: ForensicComparisonContract.Alignment = .event) -> ForensicComparisonContract {
        .init(
            baselineLabel: "Window A • 5.578–6.418 s",
            candidateLabel: "Window B • 970.854–971.134 s",
            alignment: alignment,
            authority: "DERIVED COMPARISON",
            boundary: "Alignment and observed differences do not establish cause, calibration responsibility, fault state, or Ford-defined operating thresholds."
        )
    }
}

struct GoldenCorpusGuidedStep: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let instruction: String
    let learningBoundary: String
}

enum GoldenCorpusGuidedInvestigationRev160 {
    static let steps: [GoldenCorpusGuidedStep] = [
        .init(id: 1, title: "Open Window A", instruction: "Navigate to 5.578–6.418 s and place the shared forensic cursor inside the admitted analysis window.", learningBoundary: "The window is an analysis/navigation region, not a Ford-defined WOT or fault threshold."),
        .init(id: 2, title: "Inspect Observations", instruction: "Review synchronized channel values and event context before selecting an explanation.", learningBoundary: "Telemetry is evidence, not proof of mechanism."),
        .init(id: 3, title: "Open the Digital Twin", instruction: "Use current telemetry/hypothesis context to inspect relevant production PCM, TR_C75, fuel, cooling, wiring, or sensor nodes.", learningBoundary: "Twin relevance is navigation, not component health."),
        .init(id: 4, title: "Compare Hypotheses", instruction: "Review support, contradiction, context-only evidence, missing discriminators, and falsification tests.", learningBoundary: "Do not convert temporal overlap into causality."),
        .init(id: 5, title: "Compare Window B", instruction: "Use the Compare contract to align Window A with Window B and inspect derived differences.", learningBoundary: "A/B deltas are derived and noncausal unless separately validated."),
        .init(id: 6, title: "Build an Acquisition Plan", instruction: "Turn missing discriminators into semantically verified measurement requirements for a follow-up acquisition.", learningBoundary: "Capturing a similarly named channel is insufficient until its semantics are verified."),
        .init(id: 7, title: "Validate or Reject", instruction: "Use follow-up evidence to strengthen, weaken, or reject the working hypothesis and preserve the investigation history.", learningBoundary: "Only controlled, reproducible evidence may advance authority."
        )
    ]
}

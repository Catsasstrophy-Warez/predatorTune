import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct ProductReviewFindingRev84: Identifiable, Codable, Equatable {
    enum Severity: String, Codable { case blocker, high, medium, low }
    let id: String
    let severity: Severity
    let area: String
    let finding: String
    let recommendation: String
}

enum ProductReviewRev84 {
    static let findings: [ProductReviewFindingRev84] = [
        .init(id:"xcode", severity:.blocker, area:"Apple execution", finding:"Linux parsing is green but SwiftUI, Core Data, iOS API availability, signing, simulator and device runtime remain unverified.", recommendation:"Run xcodegen/Xcode build and tests on macOS before feature expansion."),
        .init(id:"hpl", severity:.high, area:"Native HPL", finding:"The architecture can admit artifact-specific HPL signals, but the original paired HPL/CSV/XML evidence is not bundled with the project.", recommendation:"Place paired evidence beside the harness and recover Engine RPM waveform first."),
        .init(id:"configb", severity:.high, area:"Scanner semantics", finding:"Config B correctly refuses XML because exact production-GT500 parameter identities remain uncertified.", recommendation:"Capture Parameter ID, source, units, interval, transform, controller/OS and definition environment from the real GT500."),
        .init(id:"mpvi", severity:.high, area:"Acquisition", finding:"MPVI4 commissioning and tethered-vs-standalone benchmarking are modeled but not physically executed.", recommendation:"Commission the measurement chain, then benchmark identical contracts empirically."),
        .init(id:"fuel", severity:.high, area:"Flagship experiment", finding:"The sep2 fuel-protection event remains hypothesis-driven.", recommendation:"Run the no-tune-change discriminator experiment before calibration changes."),
        .init(id:"replay", severity:.medium, area:"Product UX", finding:"The product has strong evidence engines but lacks the signature synchronized event replay that unifies them.", recommendation:"Build sep2 Replay after timing and semantics are trustworthy."),
        .init(id:"repository", severity:.medium, area:"Persistence", finding:"DataRepository is a growing hotspot with multiple domains in one file.", recommendation:"Split persistence into domain extensions after the first green Xcode build."),
        .init(id:"navigation", severity:.medium, area:"Navigation", finding:"Revision-number laboratories compete with the primary workflow.", recommendation:"Keep Acquire → Verify → Investigate → Experiment → Validate primary and move historical labs behind Advanced Research."),
        .init(id:"docs", severity:.low, area:"Repository hygiene", finding:"Historical revision reports crowded the repository root.", recommendation:"Keep historical reports under Docs/History while current release docs remain at root.")
    ]
}

struct EvidenceExecutionStatusRev84: Codable, Equatable {
    let xcodeBuildVerified: Bool
    let persistenceRoundTripVerified: Bool
    let hplRPMAdmitted: Bool
    let configBCompiled: Bool
    let mpvi4Commissioned: Bool
    let acquisitionBenchmarkCompleted: Bool
    let fuelExperimentCompleted: Bool
    let replayValidated: Bool
    var completedCount: Int { [xcodeBuildVerified,persistenceRoundTripVerified,hplRPMAdmitted,configBCompiled,mpvi4Commissioned,acquisitionBenchmarkCompleted,fuelExperimentCompleted,replayValidated].filter{$0}.count }
    var productionReady: Bool { completedCount == 8 }
}

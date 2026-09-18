import Foundation

struct VerificationSummary: Codable, Equatable {
    var totalClaims:Int; var factory:Int; var professional:Int; var owner:Int; var reference:Int; var unsourced:Int
    var authoredDiagnosticHypotheses:Int = 0
    var sourceVerifiedDiagnosticHypotheses:Int = 0
    var verifiedFraction:Double { totalClaims == 0 ? 0 : Double(factory + professional) / Double(totalClaims) }
}

enum VerificationDashboardEngine {
    /// Counts source-bearing technical records. This is a provenance inventory, not a claim that every sentence in a record is verified.
    static func summarize(_ engine: TechnicalQueryEngine) -> VerificationSummary {
        let sourceLists:[[TechnicalSource]] = engine.components.map(\.sources) + engine.circuits.map(\.sources) + engine.sensors.map(\.sources) + engine.dtcs.map(\.sources) + engine.calibration.map(\.sources) + engine.procedures.map(\.sources)
        let sources=sourceLists.flatMap{$0}; let recordCount=sourceLists.count; let unsourced=sourceLists.filter{$0.isEmpty}.count
        let authored=InvestigationCatalog.all.compactMap(\.authoredHypotheses).flatMap{$0}.count
        return .init(totalClaims:max(recordCount,sources.count), factory:sources.filter{$0.grade == .a_factory}.count, professional:sources.filter{$0.grade == .b_professional}.count, owner:sources.filter{$0.grade == .c_owner}.count, reference:sources.filter{$0.grade == .d_reference}.count, unsourced:unsourced, authoredDiagnosticHypotheses:authored, sourceVerifiedDiagnosticHypotheses:0)
    }
}

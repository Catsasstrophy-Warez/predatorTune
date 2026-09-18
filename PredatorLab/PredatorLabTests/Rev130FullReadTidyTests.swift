import XCTest
@testable import PredatorLab

final class Rev130FullReadTidyTests: XCTestCase {
    func testR04NoEvidenceDoesNotInventPIDIdentityScore() {
        let scores = R04InvestigationEngine().scoreHypotheses(actualPW:nil, maximumPW:nil, pressureCommand:nil, pressureActual:nil, pumpDuty:nil, commandedLambda:nil, measuredLambda:nil, torqueSource:nil, sparkSource:nil, rpm:nil, load:nil, gearAtEvent:nil, shiftTimestamp:nil, eventTimestamp:nil)
        XCTAssertTrue(scores.isEmpty)
    }

    func testR04NoEvidenceRecommendationIsInsufficientEvidence() {
        let text = R04RecommendationEngine().recommendNextSteps(investigationState: Investigation(vehicleID: UUID(), phase: .r04FuelCapability, problem: "test"), hypothesisScores: [:])
        XCTAssertTrue(text.contains("insufficient"))
        XCTAssertFalse(text.contains("appears most likely"))
    }

    @MainActor func testTelemetryRepositoryCompatibilitySeam() {
        let repository = DataRepository()
        let telemetry: any TelemetryRepositoryRev129 = repository
        telemetry.clearDatasetCache()
        XCTAssertTrue(PredatorLabRepositoryDomainsRev129.boundary.contains("not a persistence migration"))
    }
}

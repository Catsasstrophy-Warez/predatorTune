import XCTest
@testable import PredatorLab

final class Rev160ForensicWorkflowConvergenceTests: XCTestCase {
    func testGoldenCorpusGuidedCasePreservesWindowAuthorityBoundary() {
        XCTAssertEqual(GoldenCorpusGuidedInvestigationRev160.steps.count, 7)
        XCTAssertTrue(GoldenCorpusGuidedInvestigationRev160.steps[0].instruction.contains("5.578–6.418"))
        XCTAssertTrue(GoldenCorpusGuidedInvestigationRev160.steps[0].learningBoundary.contains("not a Ford-defined"))
    }

    func testCompareContractRemainsDerivedAndNoncausal() {
        let contract = ForensicComparisonEngineRev160.goldenCorpusAB()
        XCTAssertEqual(contract.authority, "DERIVED COMPARISON")
        XCTAssertTrue(contract.boundary.lowercased().contains("do not establish cause"))
    }

    func testAcquisitionPlanDoesNotTreatCaptureAsSemanticVerification() {
        let item = ForensicMeasurementPlanItem(id: "x", measurement: "Input shaft speed", rationale: "r", requiredSemanticProof: "verify", expectedDiscriminator: "d", state: .captured)
        let plan = ForensicAcquisitionPlan(id: "p", title: "p", hypothesisID: "H4", createdAtCursorSeconds: 5.8, authorityCeiling: "semantic verification required", items: [item])
        XCTAssertFalse(plan.isSatisfied)
    }
}

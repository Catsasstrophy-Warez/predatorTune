import XCTest
@testable import PredatorLab

final class ForensicConvergenceRev157Tests: XCTestCase {
    func testGoldenBandsRemainNavigationNotCausation() {
        let a = GT500TwinUnifiedForensicContextEngine.bands.first { $0.id == "golden.a" }
        XCTAssertEqual(a?.range, 5.578...6.418)
        XCTAssertTrue(a?.boundary.localizedCaseInsensitiveContains("not Ford-defined WOT") == true)
    }
    func testDCTChecklistRequiresVerifiedDiscriminators() {
        var selection = ForensicSelectionContext(); selection.topologyNodeID = "twin:tr-c75"
        let snapshot = ForensicInvestigationInspectorEngine.snapshot(cursor: .empty, selection: selection)
        let text = snapshot.acquisitionChecklist.map(\.measurement).joined(separator:" ").lowercased()
        XCTAssertTrue(text.contains("input/shaft")); XCTAssertTrue(text.contains("output/shaft")); XCTAssertTrue(text.contains("gear")); XCTAssertTrue(text.contains("clutch"))
        XCTAssertFalse(snapshot.boundary.lowercased().contains("proves clutch slip"))
    }
    func testCalibrationLinksRemainResearchRelationships() {
        var selection = ForensicSelectionContext(); selection.topologyNodeID = "twin:production-pcm"
        let snapshot = ForensicInvestigationInspectorEngine.snapshot(cursor: .empty, selection: selection)
        XCTAssertTrue(snapshot.calibrationLinks.allSatisfy { $0.authority == "RESEARCH RELATIONSHIP" })
    }
}

import XCTest
@testable import PredatorLab

final class GT500UnifiedForensicContextTests: XCTestCase {
    func testWindowAIsNavigationContextNotFaultTruth() {
        var cursor = ForensicCursorRev85.empty; cursor.time = 5.700
        let context = GT500TwinUnifiedForensicContextEngine.build(cursor: cursor, selection: .init())
        XCTAssertEqual(context.activeBands.first?.id, "golden.a")
        XCTAssertTrue(context.activeBands.first?.boundary.contains("not Ford-defined WOT") == true)
    }
    func testDCTContextKeepsMissingPhysicalDiscriminators() {
        var selection = ForensicSelectionContext(); selection.topologyNodeID = "twin:tr-c75"
        let context = GT500TwinUnifiedForensicContextEngine.build(cursor: .empty, selection: selection)
        XCTAssertTrue(context.missingMeasurements.contains("verified clutch torque/state"))
        XCTAssertTrue(context.calibrationLinks.allSatisfy { $0.authority == "RESEARCH RELATIONSHIP" })
    }
    func testFuelContextDoesNotPromoteCalibrationCausation() {
        var selection = ForensicSelectionContext(); selection.topologyNodeID = "twin:pressure"
        let context = GT500TwinUnifiedForensicContextEngine.build(cursor: .empty, selection: selection)
        XCTAssertTrue(context.calibrationLinks.contains { $0.id == "cal.fuel" && $0.reason.contains("does not establish calibration causation") })
    }
}

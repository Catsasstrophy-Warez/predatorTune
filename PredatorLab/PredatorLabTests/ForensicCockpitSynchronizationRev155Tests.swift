import XCTest
@testable import PredatorLab

final class ForensicCockpitSynchronizationRev155Tests: XCTestCase {
    func testGoldenWindowAIsNavigationNotCausality() {
        var cursor = ForensicCursorRev85(); cursor.time = 5.8
        let packet = ForensicCockpitSynchronizationEngineRev155.packet(cursor: cursor, selection: .init())
        XCTAssertTrue(packet.activeBandTitles.contains { $0.contains("Window A") })
        XCTAssertTrue(packet.boundary.localizedCaseInsensitiveContains("do not establish causality"))
    }
    func testDCTContextRequestsMissingDiscriminatorsWithoutCallingSlip() {
        var selection = ForensicSelectionContext(); selection.topologyNodeID = "twin:tr-c75"
        let packet = ForensicCockpitSynchronizationEngineRev155.packet(cursor: .init(), selection: selection)
        XCTAssertTrue(packet.bestNextMeasurements.contains { $0.localizedCaseInsensitiveContains("input/shaft speed") })
        XCTAssertFalse(packet.bestNextMeasurements.contains { $0.localizedCaseInsensitiveContains("clutch slip") })
    }
    func testCalibrationLinksRemainResearchRelationships() {
        var selection = ForensicSelectionContext(); selection.topologyNodeID = "twin:production-pcm"
        let packet = ForensicCockpitSynchronizationEngineRev155.packet(cursor: .init(), selection: selection)
        XCTAssertTrue(packet.calibrationRelationships.allSatisfy { $0.authority == "RESEARCH RELATIONSHIP" })
    }
}

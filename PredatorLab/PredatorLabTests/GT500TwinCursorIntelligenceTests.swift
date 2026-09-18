import XCTest
@testable import PredatorLab

final class GT500TwinCursorIntelligenceTests: XCTestCase {
    func testH4HighlightsDCTInvestigationNodesWithoutFailureClaim() {
        var cursor = ForensicCursorRev85.empty
        cursor.hypothesisID = "H4"
        let snapshot = GT500TwinCursorIntelligence.snapshot(cursor: cursor, selection: .init())
        XCTAssertTrue(snapshot.matches.contains { $0.nodeID == "tr-c75" })
        XCTAssertTrue(snapshot.matches.contains { $0.nodeID == "clutches" })
        XCTAssertTrue(snapshot.boundary.contains("does not mean"))
    }

    func testFuelPressureDoesNotBecomeTransmissionPressureSemantics() {
        var cursor = ForensicCursorRev85.empty
        cursor.channelID = "Fuel Pressure (SAE)"
        let snapshot = GT500TwinCursorIntelligence.snapshot(cursor: cursor, selection: .init())
        let pressure = snapshot.matches.first { $0.nodeID == "pressure" }
        XCTAssertNotNil(pressure)
        XCTAssertTrue(pressure?.reason.contains("does not identify transmission pressure") == true)
    }

    func testComponentChannelGroupsRemainConservative() {
        XCTAssertTrue(GT500TwinCursorIntelligence.preferredChannels(for: "clutches").contains("Torque Source"))
        XCTAssertFalse(GT500TwinCursorIntelligence.preferredChannels(for: "clutches").contains { $0.localizedCaseInsensitiveContains("clutch slip") })
    }
}

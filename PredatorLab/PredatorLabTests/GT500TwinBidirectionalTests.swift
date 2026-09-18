import XCTest
@testable import PredatorLab

final class GT500TwinBidirectionalTests: XCTestCase {
    func testExplicitTwinSelectionSurvivesReverseResolution() {
        let matches = GT500TwinBidirectionalResolver.matches(topologyNodeID: "twin:c105")
        XCTAssertEqual(matches.first?.nodeID, "c105")
        XCTAssertTrue(matches.first?.reason.contains("Explicitly selected") == true)
    }

    func testH4MapsToDCTInvestigationWithoutCausalClaim() {
        let matches = GT500TwinBidirectionalResolver.matches(hypothesisID: "H4")
        XCTAssertTrue(matches.contains { $0.nodeID == "tr-c75" })
        XCTAssertTrue(matches.contains { $0.nodeID == "clutches" })
        XCTAssertFalse(matches.map(\.reason).joined(separator: " ").lowercased().contains("failed clutch"))
    }

    func testFuelPressureContextDoesNotBecomeTransmissionPressureIdentity() {
        let matches = GT500TwinBidirectionalResolver.matches(channelID: "Fuel Pressure (SAE)")
        XCTAssertTrue(matches.contains { $0.nodeID == "pump-1" })
        XCTAssertTrue(matches.first(where: { $0.nodeID == "pressure" })?.reason.contains("does not identify transmission pressure") == true)
    }

    @MainActor func testWorkstationInitialContextPersistsTwinNodeAndCursor() {
        let state = ForensicWorkspaceStateRev85(initialTwinNodeID: "c105", initialTime: 5.578, initialChannelID: "Torque Source", initialHypothesisID: "H4")
        XCTAssertEqual(state.selection.topologyNodeID, "twin:c105")
        XCTAssertEqual(state.cursor.time, 5.578)
        XCTAssertEqual(state.cursor.channelID, "Torque Source")
        XCTAssertEqual(state.cursor.hypothesisID, "H4")
    }
}

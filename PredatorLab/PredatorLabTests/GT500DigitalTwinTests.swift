import XCTest
@testable import PredatorLab

final class GT500DigitalTwinTests: XCTestCase {
    func testTwinCoversEightPrimarySystemFamilies() {
        XCTAssertEqual(GT500TwinSystem.allCases.count, 8)
        XCTAssertEqual(Set(GT500TwinSystem.allCases.map(\.id)).count, 8)
    }
    func testEveryTwinSystemHasNavigableEvidenceLanes() {
        for system in GT500TwinSystem.allCases {
            XCTAssertFalse(system.subtitle.isEmpty, system.rawValue)
            XCTAssertGreaterThanOrEqual(system.lanes.count, 6, system.rawValue)
            XCTAssertTrue(system.lanes.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        }
    }
    func testProductionVsControlPackBoundaryIsVisibleInFuelLane() {
        XCTAssertTrue(GT500TwinSystem.fuel.lanes.contains { $0.lowercased().contains("control-pack") })
    }
    func testDCTTwinKeepsElectricalAndHydraulicDomainsSeparate() {
        let lanes = GT500TwinSystem.dct.lanes.joined(separator: " ").lowercased()
        XCTAssertTrue(lanes.contains("wiring"))
        XCTAssertTrue(lanes.contains("hydraulic"))
        XCTAssertTrue(lanes.contains("clutch"))
        XCTAssertTrue(lanes.contains("torque"))
    }
}

extension GT500DigitalTwinTests {
    func testComponentNodeCatalogCoversEverySystem() {
        for system in GT500TwinSystem.allCases {
            XCTAssertFalse(GT500TwinNodeCatalog.nodes(for: system).isEmpty, "Missing component nodes for \(system.rawValue)")
        }
    }

    func testDCTNodesPreserveSlipAndPressureTruthBoundaries() {
        let joined = GT500TwinNodeCatalog.nodes(for: .dct).map { [$0.measurement, $0.scanner, $0.researchGap].joined(separator: " ") }.joined(separator: " ")
        XCTAssertTrue(joined.contains("not clutch slip"))
        XCTAssertTrue(joined.contains("universal operating threshold"))
    }

    func testControlPackRemainsQuarantined() {
        let node = GT500TwinNodeCatalog.nodes(for: .pcm).first { $0.id == "control-pack" }
        XCTAssertEqual(node?.evidenceState, "QUARANTINED")
        XCTAssertTrue(node?.scanner.contains("Never substitute") == true)
    }
}

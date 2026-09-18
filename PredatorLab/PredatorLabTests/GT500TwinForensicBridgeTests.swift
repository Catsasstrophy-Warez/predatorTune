import XCTest
@testable import PredatorLab

final class GT500TwinForensicBridgeTests: XCTestCase {
    func testPressureNodeCarriesObservedPressureAndUnresolvedHypotheses() {
        let links = GT500TwinForensicBridge.links(for: "pressure")
        XCTAssertTrue(links.contains { $0.authority == .observed && $0.title.contains("Fuel Pressure") })
        XCTAssertTrue(links.contains { $0.authority == .candidate && $0.id.contains("h2") })
        XCTAssertFalse(links.contains { $0.authority == .sourceVerified && $0.title.contains("H2") })
    }
    func testDCTLinkDoesNotPromoteRPMDifferenceToSlip() {
        let text = GT500TwinForensicBridge.links(for: "clutches").map(\.boundary).joined(separator: " ").lowercased()
        XCTAssertTrue(text.contains("not clutch slip"))
    }
    func testFlagshipWindowsRemainObservedNavigationWindows() {
        XCTAssertEqual(GT500TwinForensicBridge.flagshipWindows.count, 2)
        XCTAssertTrue(GT500TwinForensicBridge.flagshipWindows.allSatisfy { $0.authority == .observed })
        XCTAssertTrue(GT500TwinForensicBridge.flagshipWindows.allSatisfy { $0.boundary.lowercased().contains("window") || $0.boundary.lowercased().contains("noncausal") })
    }
}

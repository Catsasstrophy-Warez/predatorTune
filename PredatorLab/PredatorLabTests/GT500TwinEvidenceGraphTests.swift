import XCTest
@testable import PredatorLab

final class GT500TwinEvidenceGraphTests: XCTestCase {
    func testC105EvidencePreservesPinoutBoundary() {
        let evidence = GT500TwinEvidenceGraph.evidence(for: "c105")
        XCTAssertTrue(evidence.contains { $0.id == "c105.ssm49581" && $0.authority == .sourceVerified })
        XCTAssertTrue(evidence.contains { $0.id == "c105.pinout.gap" && $0.authority == .unknown })
        XCTAssertFalse(evidence.contains { $0.detail.localizedCaseInsensitiveContains("3-pin") })
    }

    func testProcedurePressureDoesNotBecomeUniversalLimit() {
        let evidence = GT500TwinEvidenceGraph.evidence(for: "pressure")
        XCTAssertTrue(evidence.contains { $0.limitation.contains("not a universal") })
    }

    func testProductionPCMGapRejectsControlPackSubstitution() {
        let evidence = GT500TwinEvidenceGraph.evidence(for: "production-pcm")
        XCTAssertTrue(evidence.contains { $0.limitation.contains("TC-298B") })
    }

    func testScannerCadenceBoundaryIsExplicit() {
        let evidence = GT500TwinEvidenceGraph.evidence(for: "scanner-identity")
        XCTAssertTrue(evidence.contains { $0.limitation.contains("not proof") })
    }
}

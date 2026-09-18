import XCTest
@testable import PredatorLab

final class GT500ResearchEvidenceCatalogTests: XCTestCase {
    func testEvidenceCatalogKeepsControlPackSeparateFromProductionGT500() {
        let controlPack = GT500ResearchEvidenceCatalog.records(for: "hpt.tc298b")
        XCTAssertTrue(controlPack.contains { $0.boundary.lowercased().contains("production") })
    }

    func testTRC75PressureTSBPreservesProcedureSpecificBoundary() {
        let records = GT500ResearchEvidenceCatalog.records(for: "hpt.trc75.definitions")
        XCTAssertTrue(records.contains { $0.supportedFacts.contains { $0.contains("3.0 bar") } })
        XCTAssertTrue(records.contains { $0.boundary.contains("not a universal") })
    }

    func testScannerEvidenceDoesNotEquateConfiguredIntervalWithObservedCadence() {
        let records = GT500ResearchEvidenceCatalog.records(for: "hpt.scanner.stock")
        XCTAssertTrue(records.contains { $0.boundary.contains("not proof") })
    }

    func testResearchLadderHasVehicleValidationBeforeScopeComplete() {
        let states = ArtifactAcquisitionState.allCases
        XCTAssertLessThan(states.firstIndex(of: .vehicleValidated)!, states.firstIndex(of: .scopeComplete)!)
    }
}

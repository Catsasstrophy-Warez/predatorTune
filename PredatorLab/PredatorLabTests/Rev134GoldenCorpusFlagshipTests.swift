import XCTest
@testable import PredatorLab

final class Rev134GoldenCorpusFlagshipTests: XCTestCase {
    private func fixture() throws -> ParsedLogData {
        let here = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let url = here.appendingPathComponent("Fixtures/sep2_full_real_hptuners_export.csv")
        return try CSVLogParser.parseHPTunerCSV(fileURL: url)
    }
    func testFlagshipUsesObservedHighDemandWindows() throws {
        let x = try XCTUnwrap(GoldenCorpusFlagshipInvestigationEngineRev134.build(log: fixture()))
        XCTAssertEqual(x.episodeA.kind, .highDemand)
        XCTAssertEqual(x.episodeB.kind, .highDemand)
        XCTAssertLessThanOrEqual(x.episodeA.start, 6.418)
        XCTAssertGreaterThanOrEqual(x.episodeA.end, 5.578)
        XCTAssertLessThanOrEqual(x.episodeB.start, 971.134)
        XCTAssertGreaterThanOrEqual(x.episodeB.end, 970.854)
    }
    func testComparisonRemainsDerivedAndDCTBlocked() throws {
        let x = try XCTUnwrap(GoldenCorpusFlagshipInvestigationEngineRev134.build(log: fixture()))
        XCTAssertFalse(x.comparison.summaries.isEmpty)
        XCTAssertTrue(x.comparison.summaries.allSatisfy { $0.authority == "DERIVED" })
        XCTAssertTrue(x.boundary.contains("noncausal"))
        XCTAssertTrue(x.boundary.contains("DCT"))
        XCTAssertFalse(x.missingDiscriminators.isEmpty)
    }
}

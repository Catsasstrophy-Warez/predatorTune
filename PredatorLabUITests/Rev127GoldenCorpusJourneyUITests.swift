import XCTest
final class Rev127GoldenCorpusJourneyUITests:XCTestCase {
 func testGoldenCorpusForensicJourney(){let app=XCUIApplication();app.launchArguments.append("--predatorlab-golden-corpus");app.launch();XCTAssertTrue(app.otherElements["goldenCorpus.root"].waitForExistence(timeout:8));XCTAssertTrue(app.otherElements["analysis.integratedForensicSession"].waitForExistence(timeout:12));XCTAssertTrue(app.otherElements["forensic.timeline.interactive"].exists)}
}

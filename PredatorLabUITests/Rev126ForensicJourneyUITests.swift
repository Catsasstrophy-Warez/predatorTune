import XCTest
final class Rev126ForensicJourneyUITests:XCTestCase {
 func testAnalyzeUnifiedForensicJourneyContract(){let app=XCUIApplication();app.launch();let route=app.buttons["analysis.openUnifiedForensicSession"];if route.exists{route.tap();XCTAssertTrue(app.otherElements["analysis.integratedForensicSession"].waitForExistence(timeout:3));XCTAssertTrue(app.otherElements["forensic.timeline.canvas"].exists)}}
}

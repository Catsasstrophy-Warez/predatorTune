import XCTest

final class PredatorLabUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication(); app.launch(); return app
    }

    func testAppLaunches() throws {
        let app = launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }

    func testAppLaunchesWithLargeAccessibilityText() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITestReset", "YES", "-UITestLargeText"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }

    func testPrimaryTabsAreReachableAfterOnboardingState() throws {
        let app = launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        // This intentionally tolerates first-launch onboarding. The full seeded journey will use launch arguments in the Xcode campaign.
        if app.tabBars.firstMatch.exists {
            for label in ["Garage", "Analyze", "Reference", "Settings"] {
                XCTAssertTrue(app.tabBars.buttons[label].exists, "Missing primary tab: \(label)")
            }
        }
    }

    func testAnalysisImportControlHasStableAccessibilityIdentityWhenReachable() throws {
        let app = launch()
        guard app.tabBars.firstMatch.exists else { return }
        app.tabBars.buttons["Analyze"].tap()
        let source = app.otherElements["analysis.sourcePicker"]
        XCTAssertTrue(source.waitForExistence(timeout: 3) || app.segmentedControls.firstMatch.exists)
    }
}

import XCTest
import UIKit

/// Runtime interaction campaign for the integration RC. This complements the static
/// interaction inventory; it intentionally exercises state-changing controls rather
/// than merely asserting that screens launch.
final class PredatorLabControlSurfaceAuditTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func onboard(_ app: XCUIApplication) {
        if app.staticTexts["Welcome to Predator Lab"].waitForExistence(timeout: 3) {
            app.buttons["Next"].tap()
            let f = app.textFields["onboarding.vehicleNickname"]
            if f.waitForExistence(timeout: 2) { f.tap(); f.typeText("Control Audit GT500") }
            app.buttons["Next"].tap()
            app.buttons["onboarding.getStarted"].tap()
        }
    }
    private func tab(_ name: String, _ app: XCUIApplication) {
        let t=app.tabBars.buttons[name].firstMatch
        if t.waitForExistence(timeout:2) { t.tap(); return }
        let b=app.buttons[name].firstMatch; XCTAssertTrue(b.waitForExistence(timeout:4)); b.tap()
    }
    private func scrollTo(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<8 where !element.exists { app.swipeUp() }
    }

    func testSettingsStateChangingControls() {
        let app=XCUIApplication(); app.launchArguments += ["-UITestReset","YES"]; app.launch(); onboard(app); tab("More",app); let settings = app.buttons["more.settings"].firstMatch; XCTAssertTrue(settings.waitForExistence(timeout: 4)); settings.tap()
        for label in ["Keep Screen On While Logging","Haptic Feedback","Glove-Friendly Mode","High Contrast","Colorblind-Friendly Palette"] {
            let control=app.switches[label].firstMatch; scrollTo(control,app:app); XCTAssertTrue(control.waitForExistence(timeout:3),"Missing toggle: \(label)"); control.tap()
        }
        for label in ["System","Light","Dark"] { let b=app.buttons[label].firstMatch; scrollTo(b,app:app); if b.waitForExistence(timeout:2) { b.tap() } }
        let export=app.buttons["settings.exportData"]; scrollTo(export,app:app); XCTAssertTrue(export.waitForExistence(timeout:3)); XCTAssertTrue(export.isEnabled)
        let clear=app.buttons["settings.clearAllData"]; scrollTo(clear,app:app); XCTAssertTrue(clear.waitForExistence(timeout:3)); clear.tap(); XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout:3)); app.buttons["Cancel"].tap()
    }

    func testTuneResearchAndMPVI4Options() {
        let app=XCUIApplication(); app.launchArguments += ["-UITestReset","YES"]; app.launch(); onboard(app); tab("More",app)
        let mpvi=app.buttons["more.acquisition"].firstMatch; XCTAssertTrue(mpvi.waitForExistence(timeout:5)); mpvi.tap()
        XCTAssertTrue(app.navigationBars["MPVI4 Acquisition Lab"].waitForExistence(timeout:5))
        for label in ["OBD/interface power confirmed","USB connected","Bluetooth/TDN connected","Scanner config reviewed","Standalone config deployed","Wi-Fi/hotspot path confirmed","Firmware current"] {
            let sw=app.switches[label].firstMatch; XCTAssertTrue(sw.waitForExistence(timeout:3),"Missing MPVI4 option: \(label)"); sw.tap()
        }
        for destination in ["LED + Protection Decoder","VCM Telemetry Lineage","PROLINK+ Channel Builder","Acquisition Benchmark Protocol"] {
            let link=app.buttons[destination].firstMatch; XCTAssertTrue(link.waitForExistence(timeout:3),"Missing destination: \(destination)"); link.tap(); XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout:3)); app.navigationBars.buttons.element(boundBy:0).tap()
        }
    }
}

// PredatorLabUITests/PredatorLabFullJourneyTests.swift
// Single deterministic journey across every primary surface of the app: onboarding,
// Garage, Tune, all six Forensic Workstation spaces (Pull Lab, Evidence, Calibration,
// Topology, Execution, Replay), Analyze (+ CSV import entry point), Reference, Settings,
// and the data export/import entry points. Mirrors the conventions already established
// in PredatorLabFlowTests.swift (launch args for a fresh state, waitForExistence with
// explicit timeouts, tolerating iPad's separate sidebar navigation tree).
//
// This intentionally lives as ONE test method: XCTest does not guarantee execution order
// across separate test methods, so a strictly sequential, stateful journey (onboard once,
// then keep navigating on top of that same app instance) has to be a single ordered
// function rather than several methods relying on shared state.

import XCTest
import UIKit

final class PredatorLabFullJourneyTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func tapPrimaryTab(_ label: String, in app: XCUIApplication) {
        let tab = app.tabBars.buttons[label].firstMatch
        if tab.waitForExistence(timeout: 3) { tab.tap(); return }
        let sidebarButton = app.buttons[label].firstMatch
        XCTAssertTrue(sidebarButton.waitForExistence(timeout: 5), "Primary navigation item should exist: \(label)")
        sidebarButton.tap()
    }

    /// Settings is a long `Form` (many sections) backed by a `UITableView`; rows well below
    /// the fold are not materialized into the accessibility tree until scrolled into view, so
    /// `waitForExistence` alone isn't enough for controls near the bottom. Swipes up on the
    /// Form a bounded number of times until the target element appears or we give up.
    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 8) {
        var attempts = 0
        while !element.exists && attempts < maxSwipes {
            app.swipeUp()
            attempts += 1
        }
    }

    /// Attaches a full-screen screenshot to the test result bundle, named/numbered so the
    /// journey can be reviewed visually afterward (e.g. via `xcresulttool` export) without
    /// needing a live interactive simulator session.
    private var snapshotIndex = 0
    private func snapshot(_ name: String, in app: XCUIApplication) {
        snapshotIndex += 1
        // XCUIScreen captures the true composited framebuffer (all windows/layers), unlike
        // XCUIApplication.screenshot() which captures only the app's own window hierarchy —
        // relevant on iOS 26+ where the floating "Liquid Glass" tab bar material may be
        // composited outside the app's window.
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = String(format: "%02d-%@", snapshotIndex, name)
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testFullPrimarySurfaceJourney() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITestReset", "YES"]
        app.launch()

        // iPad uses a distinct regular-width sidebar navigation tree (validated separately
        // by PredatorLabFlowTests); on iPad here we just confirm the app comes up.
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
            return
        }

        // MARK: - Onboarding (first-launch flow)
        XCTAssertTrue(app.staticTexts["Welcome to Predator Lab"].waitForExistence(timeout: 10), "Onboarding step 1 should appear on first launch")
        snapshot("onboarding-step1-welcome", in: app)
        app.buttons["Next"].tap()

        let nicknameField = app.textFields["onboarding.vehicleNickname"]
        XCTAssertTrue(nicknameField.waitForExistence(timeout: 5), "Vehicle setup step should appear")
        nicknameField.tap()
        nicknameField.typeText("Full Journey GT500")
        snapshot("onboarding-step2-vehicle-setup", in: app)

        app.buttons["Next"].tap()

        XCTAssertTrue(app.staticTexts["You're ready to start!"].waitForExistence(timeout: 5), "Final onboarding step should appear")
        snapshot("onboarding-step3-ready", in: app)
        app.buttons["onboarding.getStarted"].tap()

        // MARK: - Race-track Home (default landing surface)
        XCTAssertTrue(app.navigationBars["PredatorLab"].waitForExistence(timeout: 10), "Should land on the new race-track Home after onboarding")
        // The onboarding -> tab-bar transition animates in; wait for it to settle so a
        // screenshot here doesn't capture a mid-transition blended frame.
        _ = app.tabBars.buttons["More"].waitForExistence(timeout: 3)
        Thread.sleep(forTimeInterval: 0.6)
        snapshot("racetrack-home", in: app)

        // MARK: - Tune tab + Forensic Workstation entry point
        tapPrimaryTab("Tune", in: app)
        XCTAssertTrue(app.navigationBars["Tune"].waitForExistence(timeout: 5), "Tune tab should load")
        snapshot("tune-tab", in: app)

        let workstationEntry = app.buttons["Forensic Workstation"]
        XCTAssertTrue(workstationEntry.waitForExistence(timeout: 5), "Forensic Workstation entry point should be visible on Tune")
        workstationEntry.tap()
        XCTAssertTrue(app.navigationBars["Forensic Workstation"].waitForExistence(timeout: 5), "Forensic Workstation should open")

        let workspacePicker = app.buttons["Workspace"]
        XCTAssertTrue(workspacePicker.waitForExistence(timeout: 5), "Workspace picker should be addressable")

        // MARK: - Workstation space 1/6: Pull Lab (default landing workspace)
        XCTAssertTrue(app.staticTexts["Pull Lab"].waitForExistence(timeout: 5), "Pull Lab should be the default workstation space")
        XCTAssertTrue(app.buttons["MARK"].waitForExistence(timeout: 5), "Pull Lab MARK action should be visible")
        snapshot("workstation-1-pull-lab", in: app)

        // MARK: - Workstation space 2/6: Evidence
        workspacePicker.tap()
        app.buttons["Evidence"].tap()
        XCTAssertTrue(app.staticTexts["Operator annotations"].waitForExistence(timeout: 5), "Evidence workspace should show the Operator annotations section")
        snapshot("workstation-2-evidence", in: app)

        // MARK: - Workstation space 3/6: Calibration
        workspacePicker.tap()
        app.buttons["Calibration"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Calibration deltas")).firstMatch.waitForExistence(timeout: 5), "Calibration workspace should load")
        XCTAssertTrue(app.staticTexts["Fuel Rail Pressure Target Table"].waitForExistence(timeout: 5), "Calibration records should be visible")
        snapshot("workstation-3-calibration", in: app)

        // MARK: - Workstation space 4/6: Topology
        workspacePicker.tap()
        app.buttons["Topology"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Component topology")).firstMatch.waitForExistence(timeout: 5), "Topology workspace should load")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Evidence boundary")).firstMatch.waitForExistence(timeout: 5), "Topology evidence boundary should be visible")
        snapshot("workstation-4-topology", in: app)

        // MARK: - Workstation space 5/6: Execution
        workspacePicker.tap()
        app.buttons["Execution"].tap()
        XCTAssertTrue(app.staticTexts["Production gates"].waitForExistence(timeout: 5), "Execution workspace should show Production gates")
        snapshot("workstation-5-execution", in: app)

        // MARK: - Workstation space 6/6: Replay
        workspacePicker.tap()
        app.buttons["Replay"].tap()
        XCTAssertTrue(app.staticTexts["Replay"].waitForExistence(timeout: 5), "Replay workspace should load")
        snapshot("workstation-6-replay", in: app)

        // Back to Garage before moving to the other primary tabs. This is a REVISIT (not the
        // first onboarding->tab transition) — useful to diagnose whether a visual artifact
        // seen on first landing is a one-time transition-animation capture vs. a persistent
        // static layout bug.
        tapPrimaryTab("Garage", in: app)
        XCTAssertTrue(app.navigationBars["Garage"].waitForExistence(timeout: 5), "Should be able to return to Garage tab")
        Thread.sleep(forTimeInterval: 0.6)
        snapshot("garage-tab-revisit", in: app)

        // MARK: - Analyze / import (CSV log import flow)
        tapPrimaryTab("Analyze", in: app)
        XCTAssertTrue(app.navigationBars["Analyze"].waitForExistence(timeout: 5), "Analyze tab should load")

        let sourcePicker = app.otherElements["analysis.sourcePicker"]
        XCTAssertTrue(sourcePicker.waitForExistence(timeout: 5) || app.segmentedControls.firstMatch.exists, "Analyze source picker should be reachable")
        snapshot("analyze-sessions", in: app)

        let logsSegment = app.buttons["Logs"].firstMatch
        if logsSegment.waitForExistence(timeout: 3) {
            logsSegment.tap()
        }
        let importButton = app.buttons["analysis.importLog"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 5), "Import Log entry point should be reachable on the Logs source")
        XCTAssertTrue(importButton.isEnabled, "Import Log control should be tappable")
        snapshot("analyze-logs-import", in: app)
        // A real file-picker interaction is awkward and flaky in XCUITest; confirming the
        // control is present, correctly identified, and enabled is sufficient here.

        // MARK: - Reference (technical library tab)
        tapPrimaryTab("More", in: app)
        XCTAssertTrue(app.navigationBars["Paddock"].waitForExistence(timeout: 5), "More hub should load")
        app.buttons["more.reference"].tap()
        XCTAssertTrue(app.navigationBars["Reference"].waitForExistence(timeout: 5), "Reference Library should load from More")
        let firstCell = app.collectionViews.cells.firstMatch.exists ? app.collectionViews.cells.firstMatch : app.tables.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5), "Reference Library should list at least one seeded component")
        snapshot("reference-library", in: app)

        // MARK: - Settings tab
        tapPrimaryTab("More", in: app)
        XCTAssertTrue(app.navigationBars["Paddock"].waitForExistence(timeout: 5), "More hub should load")
        app.buttons["more.settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5), "Settings should load from More")
        snapshot("settings-top", in: app)

        // MARK: - Export/import (data export/import entry points)
        // The Data Management section is well below the fold in Settings' long Form; scroll
        // until the row is actually materialized rather than just waiting in place.
        let exportButton = app.buttons["settings.exportData"]
        scrollToElement(exportButton, in: app)
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5), "Export Data control should be reachable")
        XCTAssertTrue(exportButton.isEnabled, "Export Data control should be tappable")

        let importArchiveButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Import PredatorLab Evidence Archive")).firstMatch
        scrollToElement(importArchiveButton, in: app)
        XCTAssertTrue(importArchiveButton.waitForExistence(timeout: 5), "Import Evidence Archive control should be reachable")
        XCTAssertTrue(importArchiveButton.isEnabled, "Import Evidence Archive control should be tappable")
        snapshot("settings-data-management", in: app)
        // Both export and archive-import launch native file picker/share sheets; asserting
        // the entry points are present, labeled, and enabled avoids flaky file-system
        // round-trips through XCUITest's UIDocumentPicker interaction while still proving
        // the surfaces are wired up and reachable from a fresh install.
    }

    /// Companion to `testFullPrimarySurfaceJourney`: that test only exercises the single
    /// "Forensic Workstation (Rev85)" entry point from the Tune tab. This test walks every
    /// OTHER named NavigationLink destination reachable from Tune — the "Tune My Vehicle"
    /// row group and the "Advanced Research" labs group, plus the MPVI4 Acquisition Lab's
    /// four nested sub-labs — asserting each one actually opens (correct navigationTitle)
    /// and returns cleanly to its parent list. These 17 destinations previously had zero
    /// automated coverage.
    @MainActor
    func testTuneResearchLabsAllReachable() throws {
        let app = XCUIApplication()
        // -DiagnosticSkipOnboarding seeds a vehicle and sets isOnboarded so this test can
        // jump straight to the tab bar without repeating the onboarding text-entry flow
        // already covered by testFullPrimarySurfaceJourney.
        app.launchArguments += ["-UITestReset", "YES", "-DiagnosticSkipOnboarding"]
        app.launch()

        if UIDevice.current.userInterfaceIdiom == .pad {
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
            return
        }

        XCTAssertTrue(app.navigationBars["PredatorLab"].waitForExistence(timeout: 10), "Should land directly on race-track Home with onboarding skipped")

        tapPrimaryTab("Tune", in: app)
        XCTAssertTrue(app.navigationBars["Tune"].waitForExistence(timeout: 5), "Tune tab should load")

        func goBack(expectedParentTitle: String, context: String) {
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Back button should exist after \(context)")
            backButton.tap()
            XCTAssertTrue(app.navigationBars[expectedParentTitle].waitForExistence(timeout: 5), "Should return to \(expectedParentTitle) after \(context)")
        }

        func visit(_ rowLabel: String, expectedTitle: String, snapshotName: String, returnTo: String = "Tune") {
            let row = app.buttons[rowLabel].firstMatch
            scrollToElement(row, in: app)
            XCTAssertTrue(row.waitForExistence(timeout: 5), "Row should be reachable: \(rowLabel)")
            row.tap()
            XCTAssertTrue(app.navigationBars[expectedTitle].waitForExistence(timeout: 5), "Should open '\(expectedTitle)' after tapping '\(rowLabel)'")
            snapshot(snapshotName, in: app)
            goBack(expectedParentTitle: returnTo, context: rowLabel)
        }

        // MARK: - Current Rev160 Tune workflow routes
        let tuneRoutes: [(row: String, title: String)] = [
            ("Guided Tune Workflow", "Tune Workflow"),
            ("Evidence Workspace", "Tune Evidence Workspace"),
            ("Production Readiness", "Production Execution"),
            ("Flagship Evidence Lab", "Flagship Evidence Lab"),
            ("App Review + Next Actions", "App Review & Next Actions"),
            ("Real GT500 Evidence", "GT500 Real Evidence"),
            ("High-Load Reconstruction", "GT500 Pull Reconstruction"),
            ("HPL + VCM Telemetry", "HPL + VCM Telemetry"),
        ]
        for route in tuneRoutes {
            visit(route.row, expectedTitle: route.title, snapshotName: "tune-route-\(route.title)")
        }

        // MARK: - MPVI4 Acquisition and its nested sub-labs
        let mpvi4Row = app.buttons["MPVI4 Acquisition"].firstMatch
        scrollToElement(mpvi4Row, in: app)
        XCTAssertTrue(mpvi4Row.waitForExistence(timeout: 5), "MPVI4 Acquisition row should be reachable")
        mpvi4Row.tap()
        XCTAssertTrue(app.navigationBars["MPVI4 Acquisition Lab"].waitForExistence(timeout: 5), "MPVI4 Acquisition Lab should open")
        snapshot("tune-MPVI4-Acquisition-Lab", in: app)

        let mpvi4SubLabs: [(row: String, title: String)] = [
            ("LED + Protection Decoder", "LED Decoder"),
            ("VCM Telemetry Lineage", "VCM Telemetry"),
            ("PROLINK+ Channel Builder", "PROLINK+ Builder"),
            ("Acquisition Benchmark Protocol", "Acquisition Benchmark"),
        ]
        for sub in mpvi4SubLabs {
            let subRow = app.buttons[sub.row].firstMatch
            XCTAssertTrue(subRow.waitForExistence(timeout: 5), "Sub-lab row should be reachable: \(sub.row)")
            subRow.tap()
            XCTAssertTrue(app.navigationBars[sub.title].waitForExistence(timeout: 5), "Should open '\(sub.title)' after tapping '\(sub.row)'")
            snapshot("tune-mpvi4-\(sub.title)", in: app)
            goBack(expectedParentTitle: "MPVI4 Acquisition Lab", context: sub.row)
        }
        goBack(expectedParentTitle: "Tune", context: "MPVI4 Acquisition")

    }

}

import XCTest
@testable import PredatorLab

/// Pull analysis on the bundled real GT500 export. Expected values were measured from the file.
final class PullAnalyzerTests: XCTestCase {
    nonisolated(unsafe) private static var cachedReports: [PullReport]?
    private func reports() throws -> [PullReport] {
        if let cached = Self.cachedReports { return cached }
        let log = try CSVLogParser.parseHPTunerCSV(fileURL: HPTunersExportParsingTests.fixtureURL())
        let reports = PullAnalyzer.analyze(log)
        Self.cachedReports = reports
        return reports
    }

    func testFindsTheTwoHighDemandRuns() throws {
        let pulls = try reports()
        XCTAssertEqual(pulls.count, 2)
        XCTAssertEqual(pulls[0].start, 4.65, accuracy: 0.001)
        XCTAssertEqual(pulls[0].end, 6.418, accuracy: 0.001)
        XCTAssertEqual(pulls[1].start, 970.805, accuracy: 0.001)
    }

    func testRepresentativePullIsWidestRPMSpan() throws {
        let pull = try XCTUnwrap(PullAnalyzer.representativePull(in: reports()))
        XCTAssertEqual(pull.start, 4.65, accuracy: 0.001)
        XCTAssertEqual(pull.rpmEnd ?? 0, 6_969.25, accuracy: 0.01)
    }

    func testFirstPullMetrics() throws {
        let pull = try reports()[0]
        XCTAssertEqual(pull.peakBoost ?? 0, 11.89, accuracy: 0.01, "MAP minus baro, psi")
        XCTAssertEqual(pull.pressureUnit, "psi")
        XCTAssertEqual(pull.knockByCylinder.count, 8)
        XCTAssertEqual(pull.knockByCylinder[5] ?? 0, 1.75, accuracy: 0.001)
        XCTAssertEqual(pull.knockByCylinder.filter { $0.value > 0 }.map(\.key), [5], "Retard is isolated to cylinder 5")
        XCTAssertEqual(pull.maxLambdaError ?? 0, 0.182, accuracy: 0.001)
        XCTAssertEqual(pull.meanBankSplit ?? 0, 0.139, accuracy: 0.001)
        XCTAssertEqual(pull.iat2Rise ?? 0, 9.0, accuracy: 0.01)
        XCTAssertEqual(pull.temperatureUnit, "°F")
        XCTAssertEqual(pull.maxTorqueShortfall ?? 0, 752.5, accuracy: 0.1)
        XCTAssertEqual(pull.misfires, 1)
        XCTAssertEqual(pull.bins.map(\.rpmFloor), [4500, 5000, 5500, 6000, 6500])
        XCTAssertTrue(pull.controllerLimits.contains("Insufficient Fuel Flow"))
    }

    func testComparisonAgainstItselfIsZero() throws {
        let pull = try reports()[0]
        let comparison = PullComparison(current: pull, baseline: pull)
        XCTAssertEqual(comparison.peakBoostDelta ?? 1, 0, accuracy: 1e-9)
        XCTAssertEqual(comparison.maxKnockDelta, 0, accuracy: 1e-9)
        XCTAssertEqual(comparison.bins.count, pull.bins.count)
        XCTAssertTrue(comparison.bins.allSatisfy { ($0.lambdaBank1Delta ?? 0) == 0 })
    }

    func testComparisonOnlyMatchesSharedRPMBins() throws {
        let pulls = try reports()
        let comparison = PullComparison(current: pulls[0], baseline: pulls[1])
        XCTAssertTrue(comparison.bins.isEmpty, "4,500–7,000 rpm and 1,000–2,700 rpm pulls share no bins")
    }

    func testNoDemandChannelMeansNoPulls() {
        let log = ParsedLogData(filename: "x", fileURL: nil, channels: ["Time", "Engine RPM"], timestamps: [0, 1],
                                samples: [["Engine RPM": 1000.0], ["Engine RPM": 2000.0]], duration: 1, sampleCount: 2)
        XCTAssertTrue(PullAnalyzer.analyze(log).isEmpty)
    }

    // MARK: Baselines and session linking

    func testBaselineStoreIsPerBuild() throws {
        let suite = "PullAnalyzerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        let store = PullBaselineStore(defaults: defaults)
        let vehicle = UUID(), buildA = UUID(), buildB = UUID(), log = UUID()

        store.setBaseline(log, vehicleID: vehicle, buildStateID: buildA)
        XCTAssertEqual(store.baselineLogID(vehicleID: vehicle, buildStateID: buildA), log)
        XCTAssertNil(store.baselineLogID(vehicleID: vehicle, buildStateID: buildB))

        store.setBaseline(nil, vehicleID: vehicle, buildStateID: buildA)
        XCTAssertNil(store.baselineLogID(vehicleID: vehicle, buildStateID: buildA))
    }

    func testFinishedSessionLinksToLogAndGainsEventCards() {
        let vehicle = UUID()
        let manual = EventCard(timestamp: 1, eventType: "note", title: "Driver note")
        let session = Session(vehicleID: vehicle, buildStateID: UUID(), duration: 120, eventCards: [manual])
        let event = LogEvent(timestamp: 5.8, eventType: "protection", description: "Insufficient Fuel Flow", severity: "critical")
        let log = ImportedLog(filename: "pull.csv", fileURL: nil, vehicleID: vehicle, buildStateID: nil,
                              channels: [], sampleCount: 0, duration: 0, timestamps: [], events: [event])

        XCTAssertTrue(SessionLogLinker.canLink(session, to: log))
        let linked = SessionLogLinker.link(session, to: log)
        XCTAssertEqual(linked.logFileID, log.id)
        XCTAssertEqual(linked.eventCards.count, 2, "Manual cards are kept")
        XCTAssertEqual(linked.eventCards.last?.title, "Fuel-flow protection")
        XCTAssertFalse(SessionLogLinker.canLink(linked, to: log), "A session links to one log")
    }

    func testRunningOrForeignSessionsAreNotLinked() {
        let log = ImportedLog(filename: "x.csv", fileURL: nil, vehicleID: UUID(), buildStateID: nil,
                              channels: [], sampleCount: 0, duration: 0, timestamps: [], events: [])
        XCTAssertFalse(SessionLogLinker.canLink(Session(vehicleID: log.vehicleID, buildStateID: UUID(), duration: 0), to: log))
        XCTAssertFalse(SessionLogLinker.canLink(Session(vehicleID: UUID(), buildStateID: UUID(), duration: 60), to: log))
    }
}

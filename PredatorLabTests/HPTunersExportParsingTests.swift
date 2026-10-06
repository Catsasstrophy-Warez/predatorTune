import XCTest
@testable import PredatorLab

/// Parses the bundled real HP Tuners export (2020+ GT500, 25 Hz, 61 channels) end to end.
/// Expected values were measured directly from the fixture file.
final class HPTunersExportParsingTests: XCTestCase {
    static func fixtureURL() throws -> URL {
        if let bundled = GoldenCorpusUITestModeRev127.fixtureURL() { return bundled }
        let repoCopy = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("PredatorLab/Resources/Fixtures/sep2_full_real_hptuners_export.csv")
        guard FileManager.default.fileExists(atPath: repoCopy.path) else { throw XCTSkip("Golden corpus fixture unavailable") }
        return repoCopy
    }

    private static var cached: ParsedLogData?
    private func fixture() throws -> ParsedLogData {
        if let cached = Self.cached { return cached }
        let parsed = try CSVLogParser.parseHPTunerCSV(fileURL: Self.fixtureURL())
        Self.cached = parsed
        return parsed
    }

    // MARK: Parsing

    func testParsesHPTunersSectionFormat() throws {
        let log = try fixture()
        XCTAssertEqual(log.sampleCount, 26_943)
        XCTAssertEqual(log.channels.count, 61)
        XCTAssertEqual(log.timestamps.first ?? 0, 2.268, accuracy: 0.0001)
        XCTAssertEqual(log.duration, 1_120.46, accuracy: 0.001, "Duration is last minus first timestamp")
        XCTAssertTrue(log.channels.contains("Engine RPM (SAE)"))
        XCTAssertFalse(log.channels.contains("HP Tuners CSV Log File"), "Preamble must not become a channel")
    }

    func testKeepsUnitsRow() throws {
        let log = try fixture()
        XCTAssertEqual(log.unit(for: "Engine RPM (SAE)"), "rpm")
        XCTAssertEqual(log.unit(for: "Intake Air Temp 2"), "°F")
        XCTAssertEqual(log.unit(for: "WB EQ Ratio 1 (SAE) (2)"), "λ")
        XCTAssertEqual(log.numericValue(channel: "Engine RPM (SAE)", row: 0) ?? 0, 2_739, accuracy: 0.5, "Units row must not be parsed as data")
    }

    func testPlainCSVWithHeaderOnFirstLineStillParses() throws {
        let url = try temporaryCSV("Time,Engine RPM\n0.0,1000\n0.1,1100\n0.2,1200\n")
        let log = try CSVLogParser.parseHPTunerCSV(fileURL: url)
        XCTAssertEqual(log.sampleCount, 3)
        XCTAssertEqual(log.duration, 0.2, accuracy: 0.0001)
        XCTAssertTrue(log.units.isEmpty)
    }

    func testDuplicateColumnNamesStayDistinct() throws {
        let url = try temporaryCSV("Offset,IAT,IAT\n0,90,95\n")
        let log = try CSVLogParser.parseHPTunerCSV(fileURL: url)
        XCTAssertEqual(log.numericValue(channel: "IAT", row: 0), 90)
        XCTAssertEqual(log.numericValue(channel: "IAT #2", row: 0), 95)
    }

    func testFileWithoutTimestampColumnIsRejected() throws {
        let url = try temporaryCSV("Engine RPM,Throttle\n1000,10\n")
        XCTAssertThrowsError(try CSVLogParser.parseHPTunerCSV(fileURL: url))
    }

    // MARK: Event detection on real channel names

    func testInsufficientFuelFlowIsOneEpisode() throws {
        let protection = LogEventDetector.detectAllEvents(logData: try fixture()).filter { $0.eventType == "protection" }
        XCTAssertEqual(protection.count, 1, "Four consecutive protection samples are one event")
        XCTAssertEqual(protection.first?.timestamp ?? 0, 5.838, accuracy: 0.001)
    }

    func testLambdaDeviationOnlyUnderDriverDemand() throws {
        let lambda = LogEventDetector.detectAllEvents(logData: try fixture()).filter { $0.eventType == "lambda_deviation" }
        XCTAssertEqual(lambda.count, 1, "Decel fuel cut and tip-in lag must not be reported")
        XCTAssertTrue((5.4...6.0).contains(lambda.first?.timestamp ?? 0))
    }

    func testKnockUsesFordSignConvention() throws {
        XCTAssertEqual(ChannelResolver.knockRetardDegrees(-1.0, channelName: "Knock Retard"), 1.0)
        XCTAssertEqual(ChannelResolver.knockRetardDegrees(-0.5, channelName: "Knock Cyl 1 (+Adv/-Ret)"), 0.5)
        XCTAssertEqual(ChannelResolver.knockRetardDegrees(0.75, channelName: "Knock Cyl 1 (+Adv/-Ret)"), 0, "Positive is advance")
        XCTAssertEqual(ChannelResolver.cylinderKnockChannels(in: try fixture().channels).map(\.cylinder), Array(1...8))

        let knock = LogEventDetector.detectAllEvents(logData: try fixture()).filter { $0.eventType == "knock" }
        XCTAssertEqual(knock.count, 2)
        XCTAssertTrue(knock.contains { (5.4...6.5).contains($0.timestamp) }, "Cylinder 5 retard during the high-demand window")
    }

    func testRoutineControllerStatesAreNotReported() throws {
        let sources = LogEventDetector.detectAllEvents(logData: try fixture()).filter { $0.eventType == "source_state_change" }
        XCTAssertEqual(sources.count, 18)
        let states = Set(sources.flatMap { $0.sourceStates.values })
        XCTAssertFalse(states.contains("Base / MBT"))
        XCTAssertFalse(states.contains("Anticlunk Tipin TQ Lmt."))
        XCTAssertTrue(states.contains("Cyl. Pressure Limit"))
        XCTAssertTrue(states.contains("Exh. Temp. Protection"))
    }

    func testMisfiresCountWholeCounterCrossings() throws {
        let misfires = LogEventDetector.detectAllEvents(logData: try fixture()).filter { $0.eventType == "misfire" }
        XCTAssertEqual(misfires.count, 28, "Interpolated counter values between samples are not misfires")
    }

    func testChargeAirConditionUsesLoggedUnits() throws {
        let log = try fixture()
        let summary = LogSummaryGenerator.generateSummary(logData: log, events: [])
        XCTAssertEqual(summary.condition, "intermediate", "104.8°F average IAT2 is 40.4°C, not heat soak")
        XCTAssertTrue(summary.avgTemperature.hasSuffix("°F"))
    }

    func testBoostRuleFallsBackToManifoldPressure() throws {
        let report = DomainDiagnosticExecutionEngine.execute(InvestigationCatalog.boostControl, log: try fixture())
        XCTAssertFalse(report.missingChannels.contains(.boostPressure))
        XCTAssertTrue(report.warnings.contains { $0.contains("manifold absolute pressure") })
    }

    func testInstantGearChangeIsNotASlowShift() throws {
        let gears = [3.0, 3, 3, 4, 4, 4, 4]
        let log = ParsedLogData(filename: "g", fileURL: nil, channels: ["Time", "Current Gear"],
                                timestamps: gears.indices.map { Double($0) * 0.04 },
                                samples: gears.map { ["Current Gear": $0] }, duration: 0.24, sampleCount: gears.count)
        let report = DomainDiagnosticExecutionEngine.execute(InvestigationCatalog.dctTransient, log: log)
        XCTAssertTrue(report.episodes.isEmpty)
    }

    func testShiftThroughNeutralIsMeasured() throws {
        let gears = [3.0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 4, 4]
        let log = ParsedLogData(filename: "g", fileURL: nil, channels: ["Time", "Current Gear"],
                                timestamps: gears.indices.map { Double($0) * 0.04 },
                                samples: gears.map { ["Current Gear": $0] }, duration: 0.6, sampleCount: gears.count)
        let report = DomainDiagnosticExecutionEngine.execute(InvestigationCatalog.dctTransient, log: log)
        XCTAssertEqual(report.episodes.count, 1)
        XCTAssertEqual(report.episodes.first?.peakMagnitude ?? 0, 0.40, accuracy: 0.001)
    }

    private func temporaryCSV(_ contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("csv")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }
}

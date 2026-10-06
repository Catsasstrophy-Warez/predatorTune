import XCTest
@testable import PredatorLab

final class LogTimelineModelTests: XCTestCase {
    private func fixtureModel() throws -> LogTimelineModel {
        let log = try CSVLogParser.parseHPTunerCSV(fileURL: HPTunersExportParsingTests.fixtureURL())
        return LogTimelineModel(log: log, events: LogEventDetector.detectAllEvents(logData: log), pulls: PullAnalyzer.analyze(log))
    }

    func testTracksResolveRealChannelNames() throws {
        let model = try fixtureModel()
        XCTAssertEqual(model.tracks.map(\.id), ["rpm", "demand", "map", "lambda", "timing", "knock", "iat2", "speed"])
        let lambda = try XCTUnwrap(model.tracks.first { $0.id == "lambda" })
        XCTAssertEqual(lambda.channels.count, 3, "Commanded plus both wideband banks")
        XCTAssertEqual(model.tracks.first?.unit, "rpm")
    }

    func testReadingsAtProtectionOnsetIncludeTextChannels() throws {
        let readings = try fixtureModel().readings(at: 5.838)
        XCTAssertEqual(readings.first { $0.channel == "Torque Max Protection Source" }?.value, "Insufficient Fuel Flow")
        XCTAssertEqual(readings.first { $0.channel == "Engine RPM (SAE)" }?.unit, "rpm")
    }

    func testNearestEventAndRow() throws {
        let model = try fixtureModel()
        XCTAssertEqual(model.nearestRow(to: 0), 0)
        XCTAssertEqual(model.nearestRow(to: 10_000), model.log.sampleCount - 1)
        XCTAssertEqual(model.nearestEvent(to: 5.84)?.timestamp ?? 0, 5.838, accuracy: 0.001)
        XCTAssertTrue(model.events(in: 5.8...5.9).contains { $0.eventType == "protection" })
    }

    func testDecimationKeepsSpikes() throws {
        let count = 10_000
        var samples: [[String: Any]] = (0..<count).map { _ in ["Engine RPM": 3000.0] }
        samples[7_777] = ["Engine RPM": 7000.0]
        let log = ParsedLogData(filename: "spike", fileURL: nil, channels: ["Engine RPM", "Time"],
                                timestamps: (0..<count).map { Double($0) * 0.01 }, samples: samples,
                                duration: Double(count - 1) * 0.01, sampleCount: count)
        let model = LogTimelineModel(log: log, events: [], pulls: [])
        let track = try XCTUnwrap(model.tracks.first)
        let points = model.points(for: track, in: model.startTime...model.endTime, buckets: 100)
        XCTAssertLessThanOrEqual(points.count, 200, "At most a min and max per bucket")
        XCTAssertEqual(points.map(\.value).max(), 7000, "The one-sample spike survives downsampling")
    }
}

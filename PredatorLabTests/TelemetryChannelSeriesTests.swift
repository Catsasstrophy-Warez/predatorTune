import XCTest
@testable import PredatorLab

final class TelemetryChannelSeriesTests: XCTestCase {
    func testNormalizedMapsMinAndMaxToZeroAndOne() {
        let series = TelemetryChannelSeries(channelName: "RPM", timestamps: [0, 1, 2, 3], values: [1000, 3000, 7000, 4000])
        let normalized = series.normalized()
        XCTAssertEqual(normalized.count, 4)
        XCTAssertEqual(normalized[0], 0, accuracy: 1e-9)
        XCTAssertEqual(normalized[2], 1, accuracy: 1e-9)
        XCTAssertEqual(normalized[3], 0.5, accuracy: 1e-9)
    }

    func testNormalizedHandlesConstantSeriesWithoutDivideByZero() {
        let series = TelemetryChannelSeries(channelName: "Boost", timestamps: [0, 1], values: [12, 12])
        let normalized = series.normalized()
        XCTAssertEqual(normalized, [0.5, 0.5])
    }

    func testValueAtProgressClampsAndRounds() {
        let series = TelemetryChannelSeries(channelName: "AFR", timestamps: [0, 1, 2, 3, 4], values: [10, 12, 14, 16, 18])
        XCTAssertEqual(series.value(atProgress: -1), 10)
        XCTAssertEqual(series.value(atProgress: 0), 10)
        XCTAssertEqual(series.value(atProgress: 0.5), 14)
        XCTAssertEqual(series.value(atProgress: 1), 18)
        XCTAssertEqual(series.value(atProgress: 2), 18)
    }

    func testValueAtProgressOnEmptySeriesReturnsZero() {
        let series = TelemetryChannelSeries(channelName: "Empty", timestamps: [], values: [])
        XCTAssertEqual(series.value(atProgress: 0.5), 0)
        XCTAssertTrue(series.isEmpty)
    }

    func testExtractSkipsRowsMissingTheRequestedChannel() {
        let log = ParsedLogData(
            filename: "test.csv",
            fileURL: nil,
            channels: ["RPM", "Boost"],
            timestamps: [0, 1, 2],
            samples: [
                ["RPM": 1000.0, "Boost": 5.0],
                ["Boost": 6.0],
                ["RPM": 2000.0, "Boost": 7.0]
            ],
            duration: 2,
            sampleCount: 3
        )

        let series = TelemetryChannelSeriesAdapter.extract(channel: "RPM", from: log)
        XCTAssertEqual(series.values, [1000.0, 2000.0])
        XCTAssertEqual(series.timestamps, [0, 2])
    }

    func testDemoSeriesIsDeterministicAndNonEmpty() {
        let first = TelemetryChannelSeriesAdapter.demoSeries(channelName: "RPM", amplitude: 7500)
        let second = TelemetryChannelSeriesAdapter.demoSeries(channelName: "RPM", amplitude: 7500)
        XCTAssertEqual(first.values, second.values)
        XCTAssertFalse(first.isEmpty)
        XCTAssertTrue(first.values.allSatisfy { $0 >= 0 && $0 <= 7500 })
    }
}

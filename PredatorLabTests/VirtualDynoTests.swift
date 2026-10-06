import XCTest
@testable import PredatorLab

final class VirtualDynoTests: XCTestCase {
    func testConstantAccelerationMatchesClosedForm() throws {
        // 1,000 kg accelerating at 5 m/s² with drag and rolling resistance switched off:
        // P = m·a·v, so at v = 10 m/s the wheels make 50 kW (67.05 hp).
        let times = (0...100).map { Double($0) * 0.04 }
        let samples: [[String: Any]] = times.map { t in ["Vehicle Speed": 5 * t, "Engine RPM": 1_000 + 1_000 * t] }
        let log = ParsedLogData(filename: "synthetic", fileURL: nil, channels: ["Time", "Vehicle Speed", "Engine RPM"],
                                timestamps: times, samples: samples, duration: 4, sampleCount: times.count,
                                units: ["Vehicle Speed": "m/s", "Engine RPM": "rpm"])
        var assumptions = DynoAssumptions(testWeightLb: nil)
        assumptions.massKg = 1_000; assumptions.dragArea = 0; assumptions.rollingResistance = 0
        let pull = PullReport(start: 0, end: 4, rpmStart: 1_000, rpmEnd: 5_000, peakPedal: 100, peakManifoldPressure: nil,
                              peakBoost: nil, pressureUnit: nil, maxKnockRetard: 0, knockByCylinder: [:], maxLambdaError: nil,
                              meanBankSplit: nil, fuelTrims: [:], iat2Start: nil, iat2End: nil, temperatureUnit: nil,
                              maxTorqueShortfall: nil, torqueUnit: nil, minFuelPressure: nil, misfires: 0, controllerLimits: [], bins: [])

        let result = try XCTUnwrap(VirtualDyno.run(log: log, pull: pull, assumptions: assumptions))
        // v = 10 m/s at t = 2 s, where RPM = 3,000.
        let bin = try XCTUnwrap(result.points.first { $0.rpm == 3_000 })
        let expectedHP = 1_000.0 * 5 * (5 * (3_000.0 + 125 - 1_000) / 1_000) / 745.7
        XCTAssertEqual(bin.wheelHorsepower, expectedHP, accuracy: expectedHP * 0.05, "Bin averages around its center")
        XCTAssertEqual(result.peakHorsepowerRPM, result.points.last?.rpm, "Power rises with speed at constant force")
    }

    func testSpeedUnits() {
        XCTAssertEqual(VirtualDyno.speedFactor(unit: "mph"), 0.44704, accuracy: 1e-6)
        XCTAssertEqual(VirtualDyno.speedFactor(unit: "km/h"), 1 / 3.6, accuracy: 1e-9)
        XCTAssertEqual(VirtualDyno.speedFactor(unit: nil), 0.44704, accuracy: 1e-6)
    }

    func testRealPullEstimateAndShiftExclusion() throws {
        let log = try CSVLogParser.parseHPTunerCSV(fileURL: HPTunersExportParsingTests.fixtureURL())
        let pull = try XCTUnwrap(PullAnalyzer.analyze(log).first)
        let result = try XCTUnwrap(VirtualDyno.run(log: log, pull: pull, assumptions: DynoAssumptions(testWeightLb: nil)))
        XCTAssertEqual(result.peakHorsepower, 336, accuracy: 10, "Low-gear part-throttle pull at 4,350 lb")
        XCTAssertEqual(result.peakHorsepowerRPM, 6_750)
        XCTAssertEqual(result.peakTorqueRPM, 5_250)
        XCTAssertGreaterThan(result.excludedSamples, 0, "The upshift's falling RPM is excluded")
    }

    func testHeavierCarNeedsMorePower() throws {
        let log = try CSVLogParser.parseHPTunerCSV(fileURL: HPTunersExportParsingTests.fixtureURL())
        let pull = try XCTUnwrap(PullAnalyzer.analyze(log).first)
        let light = try XCTUnwrap(VirtualDyno.run(log: log, pull: pull, assumptions: DynoAssumptions(testWeightLb: 4_000)))
        let heavy = try XCTUnwrap(VirtualDyno.run(log: log, pull: pull, assumptions: DynoAssumptions(testWeightLb: 4_600)))
        XCTAssertGreaterThan(heavy.peakHorsepower, light.peakHorsepower)
    }
}

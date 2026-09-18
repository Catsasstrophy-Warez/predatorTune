import XCTest
@testable import PredatorLab
final class Rev125PrimaryRouteTests:XCTestCase {
 func testBridgeUsesOnlyPresentPreferredChannels(){let x=ParsedLogData(filename:"x",fileURL:nil,channels:["Engine RPM (SAE)"],timestamps:[0,1],samples:[["Engine RPM (SAE)":1000.0],["Engine RPM (SAE)":2000.0]],duration:1,sampleCount:2);let s=ParsedLogForensicBridgeRev125.build(x);XCTAssertEqual(s.series.map(\.id),["Engine RPM (SAE)"])}
 func testBridgeDoesNotInventEpisodesWithoutEvidence(){let x=ParsedLogData(filename:"x",fileURL:nil,channels:["Engine RPM (SAE)"],timestamps:[0,1],samples:[["Engine RPM (SAE)":1000.0],["Engine RPM (SAE)":1100.0]],duration:1,sampleCount:2);XCTAssertTrue(ParsedLogForensicBridgeRev125.build(x).episodes.isEmpty)}
 func testRapidRPMIsNotCalledShift(){let x=ParsedLogData(filename:"x",fileURL:nil,channels:["Engine RPM (SAE)"],timestamps:[0,0.04],samples:[["Engine RPM (SAE)":1000.0],["Engine RPM (SAE)":1400.0]],duration:0.04,sampleCount:2);let e=ParsedLogForensicBridgeRev125.build(x).episodes.first;XCTAssertEqual(e?.kind,.acceleration);XCTAssertTrue(e?.boundary.contains("not a shift") == true)}
}

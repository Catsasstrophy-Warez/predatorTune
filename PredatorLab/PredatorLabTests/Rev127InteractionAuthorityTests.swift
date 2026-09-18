import XCTest
@testable import PredatorLab
final class Rev127InteractionAuthorityTests:XCTestCase {
 func testZoomKeepsCursorInWindow(){let v=TimelineInteractionRev127.zoom(.init(start:0,end:10,cursor:5),factor:0.5,anchor:5,totalStart:0,totalEnd:100);XCTAssertTrue(v.cursor>=v.start && v.cursor<=v.end)}
 func testPanClampsToCorpus(){let v=TimelineInteractionRev127.pan(.init(start:0,end:10,cursor:5),delta:-99,totalStart:0,totalEnd:100);XCTAssertEqual(v.start,0)}
 func testCursorSnapsToEpisode(){let e=GT500EpisodeRev122(id:"e",kind:.highDemand,start:10,end:11,peakTime:10.5,observations:1,evidence:[],boundary:"");XCTAssertEqual(TimelineInteractionRev127.snapCursor(10.48,episodes:[e],tolerance:0.1),10.5)}
 func testCursorDoesNotSnapOutsideTolerance(){let e=GT500EpisodeRev122(id:"e",kind:.highDemand,start:10,end:11,peakTime:10.5,observations:1,evidence:[],boundary:"");XCTAssertEqual(TimelineInteractionRev127.snapCursor(9,episodes:[e],tolerance:0.1),9)}
 func testImportedTraceBadgeDoesNotClaimGroundTruth(){let b=EvidenceAuthorityPresentationRev127.badge(channel:"RPM");XCTAssertEqual(b.authority,.measuredExported);XCTAssertTrue(b.boundary.contains("does not prove"))}
 func testGoldenCorpusModeBoundaryDoesNotClaimHardware(){XCTAssertTrue(GoldenCorpusUITestModeRev127.boundary.contains("does not simulate MPVI4"))}
}

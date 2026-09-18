import XCTest
@testable import PredatorLab
final class Rev129CursorRepositoryTests:XCTestCase {
 func testCoverageDropsWhenExpectedChannelsMissing(){let e=GT500EpisodeRev122(id:"x",kind:.highDemand,start:0,end:1,peakTime:0,observations:1,evidence:[],boundary:"");let s=TimelineSeriesRev117(id:"Engine RPM (SAE)",points:[.init(time:0,value:1000)]);let x=CursorHypothesisContextEngineRev129.evaluate(episode:e,cursor:0,series:[s]);XCTAssertLessThan(x.coverage.ratio,0.5);XCTAssertTrue(x.hypotheses.allSatisfy{$0.confidence=="insufficient"})}
 func testCoverageDoesNotBecomeProbability(){let e=GT500EpisodeRev122(id:"x",kind:.sourceActivity,start:0,end:1,peakTime:0,observations:1,evidence:[],boundary:"");let x=CursorHypothesisContextEngineRev129.evaluate(episode:e,cursor:0,series:[]);XCTAssertTrue(x.boundary.contains("not the underlying episode"));XCTAssertTrue(x.coverage.boundary.contains("does not establish"))}
 func testMissingChannelBecomesNextMeasurement(){let e=GT500EpisodeRev122(id:"x",kind:.throttleDisagreement,start:0,end:1,peakTime:0,observations:1,evidence:[],boundary:"");let x=CursorHypothesisContextEngineRev129.evaluate(episode:e,cursor:0,series:[]);XCTAssertTrue(x.nextMeasurement?.measurement.contains("Acquire/verify") == true)}
 @MainActor func testRepositoryDomainCompositionUsesCompatibilityRepository(){let r=DataRepository();let d=PredatorLabRepositoryDomainsRev129(repository:r);XCTAssertTrue(type(of:d.telemetry) == DataRepository.self);XCTAssertTrue(PredatorLabRepositoryDomainsRev129.boundary.contains("not a persistence migration"))}
}

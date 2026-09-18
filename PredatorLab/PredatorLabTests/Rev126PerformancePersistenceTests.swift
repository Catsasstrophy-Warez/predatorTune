import XCTest
@testable import PredatorLab
final class Rev126PerformancePersistenceTests:XCTestCase {
 func testRenderPipelineBoundsEnvelopeCount(){let p=(0..<100_000).map{TelemetryPointRev116(time:Double($0)*0.01,value:sin(Double($0)*0.01))};let f=TimelineRenderPipelineRev126.frame(series:[.init(id:"x",points:p)],start:0,end:999.99,cursor:500,pixelWidth:500);XCTAssertLessThanOrEqual(f.renderedEnvelopeCount,501)}
 func testRenderPipelinePreservesExtrema(){let p=(0..<1000).map{TelemetryPointRev116(time:Double($0),value:$0==500 ? 999:0)};let f=TimelineRenderPipelineRev126.frame(series:[.init(id:"x",points:p)],start:0,end:1000,cursor:500,pixelWidth:100);XCTAssertEqual(f.bands.first?.maximum,999)}
 func testCursorClampsToWindow(){let f=TimelineRenderPipelineRev126.frame(series:[],start:10,end:20,cursor:99,pixelWidth:100);XCTAssertEqual(f.cursor,20)}
 func testAutosaveResumeRoundTrip()throws{let e=GT500EpisodeRev122(id:"resume",kind:.highDemand,start:1,end:2,peakTime:1.5,observations:1,evidence:[],boundary:"x");let c=ForensicEpisodeWorkspaceRev123.select(e,series:[]);let dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);let a=InvestigationAutosaveRev126(directory:dir);try a.save(context:c,signals:["RPM"],annotations:["note"]);let r=try a.resume();XCTAssertEqual(r?.episodeID,"resume");XCTAssertEqual(r?.selectedSignals,["RPM"])}
 func testLargeSeriesBenchmarkContract(){let p=(0..<1_000_000).map{TelemetryPointRev116(time:Double($0)*0.001,value:Double($0%1000))};measure{_ = TimelineRenderPipelineRev126.frame(series:[.init(id:"million",points:p)],start:200,end:300,cursor:250,pixelWidth:800)}}
}

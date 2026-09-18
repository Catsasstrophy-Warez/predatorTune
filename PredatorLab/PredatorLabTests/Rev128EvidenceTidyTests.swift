import XCTest
@testable import PredatorLab
final class Rev128EvidenceTidyTests:XCTestCase {
 func testCursorInspectorMovesWithCursor(){let e=GT500EpisodeRev122(id:"e",kind:.highDemand,start:0,end:2,peakTime:0,observations:1,evidence:[],boundary:"");let s=TimelineSeriesRev117(id:"Engine RPM (SAE)",points:[.init(time:0,value:1000),.init(time:1,value:2000)]);let x=CursorEvidenceInspectorEngineRev128.inspect(cursor:1,episode:e,series:[s],units:["Engine RPM (SAE)":"rpm"]);XCTAssertEqual(x.measurements.first?.value,2000);XCTAssertEqual(x.measurements.first?.deltaFromEpisodePeak,1000)}
 func testObservedSep2UnitCatalogIsExplicit(){XCTAssertEqual(GT500ExportUnitCatalogRev128.observedSep2["Fuel Pressure (SAE)"],"psi");XCTAssertTrue(GT500ExportUnitCatalogRev128.boundary.contains("exact bundled sep2 export metadata"))}
 func testUnknownChannelGetsNoInventedUnit(){XCTAssertNil(GT500ExportUnitCatalogRev128.units(for:["Mystery"])["Mystery"])}
 func testCursorInspectorDoesNotClaimCausality(){let e=GT500EpisodeRev122(id:"e",kind:.sourceActivity,start:0,end:1,peakTime:0,observations:1,evidence:[],boundary:"");let x=CursorEvidenceInspectorEngineRev128.inspect(cursor:0,episode:e,series:[],units:[:]);XCTAssertTrue(x.boundary.contains("not causal attribution"))}
 func testAutosaveLocationIsAppSupportScoped(){XCTAssertTrue(InvestigationAutosaveLocationRev128.directory().path.contains("PredatorLab/Investigations"))}
}

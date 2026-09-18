import XCTest
@testable import PredatorLab
final class Rev132ConvergenceTests:XCTestCase {
 func testUnknownBaselineIsNotUsable(){let log=ImportedLog(filename:"x",vehicleID:UUID(),sourceSHA256:"abc");let b=BaselineDesignationEngineRev132.designate(vehicleID:log.vehicleID,buildStateID:nil,log:log,authority:.unknown,configurationNote:"",validationNote:"");XCTAssertFalse(b.usable)}
 func testBaselineRequiresHash(){let log=ImportedLog(filename:"x",vehicleID:UUID());let b=BaselineDesignationEngineRev132.designate(vehicleID:log.vehicleID,buildStateID:nil,log:log,authority:.userValidatedReference,configurationNote:"",validationNote:"");XCTAssertFalse(b.usable)}
 func testContextEvidenceDoesNotBecomeSupport(){let e=StructuredForensicEvidenceRev131(id:"e",sourceArtifactSHA256:nil,episodeID:"x",hypothesisID:nil,channel:"RPM",timestamp:0,numericValue:1,stringValue:nil,units:"rpm",authority:.measuredExported,relation:.context,derivation:nil,boundary:"");let x=StructuredHypothesisEvidenceEngineRev132.assess(hypothesisNames:["h"],evidence:[e]);XCTAssertEqual(x.ranked.first?.score,0)}
 func testNextMeasurementPrefersDiscriminationUtility(){let a=NextMeasurementCandidateRev120(measurement:"A",hypothesesSeparated:3,acquisitionCost:1,evidenceAuthority:1);let b=NextMeasurementCandidateRev120(measurement:"B",hypothesesSeparated:1,acquisitionCost:4,evidenceAuthority:1);XCTAssertEqual(BestNextMeasurementEngineRev132.rank([b,a],availableChannels:[]).first?.candidate.measurement,"A")}
 func testGhostDeltasRemainDerived(){let q=GhostAlignmentQualityEvaluator.evaluate(residuals:[0],ambiguousCrossings:0,excludedRegions:0,method:"test");XCTAssertEqual(q.anchorCount,1);XCTAssertTrue(GhostPullComparisonRev132(method:.absoluteTime,quality:q,metrics:[],boundary:"derived").boundary.contains("derived"))}
 func testCalibrationBridgeAuthorityIsInferred(){let r=CalibrationEvidenceBridgeRev132.relationships(availableChannels:["RPM","load"]);XCTAssertTrue(r.allSatisfy{$0.authority == .predatorLabInferred})}
 func testPhysicalCampaignKeepsDCTBlockedUntilEvidence(){XCTAssertTrue(GT500PhysicalValidationCampaignRev132.steps.first{$0.id=="dct"}!.promotionRule.contains("blocked"))}
 func testReadinessDoesNotClaimRuntimeValidation(){XCTAssertTrue(ProductionReadinessMatrixRev132.gates.first{$0.id=="xcode"}!.state == .runtimeRequired)}
}

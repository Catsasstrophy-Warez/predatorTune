import Foundation
struct CursorEvidenceCoverageRev129:Equatable,Sendable {let available:Int;let expected:Int;let ratio:Double;let missing:[String];let boundary:String}
struct CursorHypothesisContextRev129:Equatable,Sendable {let hypotheses:[RankedHypothesisRev120];let coverage:CursorEvidenceCoverageRev129;let nextMeasurement:NextMeasurementCandidateRev120?;let boundary:String}
enum CursorHypothesisContextEngineRev129 {
 static func evaluate(episode:GT500EpisodeRev122,cursor:Double,series:[TimelineSeriesRev117])->CursorHypothesisContextRev129 {
  let nearest=ForensicCursorCoordinatorRev118.update(cursor:cursor,series:series,events:[],workspace:.init()).nearest
  let expected:[String]
  switch episode.kind {
  case .throttleDisagreement: expected=["Accelerator Position D (SAE)","Throttle Desired Angle","Throttle Angle","Scheduled Torque","Engine Brake Torque"]
  case .highDemand: expected=["Engine RPM (SAE)","Accelerator Position D (SAE)","Throttle Angle","Fuel Pressure (SAE)","Knock Correction (+Adv/-Ret)","Scheduled Torque","Intake Air Temp 2"]
  case .thermalHighContext: expected=["Intake Air Temp 2","Engine Coolant Temp","Engine RPM (SAE)","Throttle Angle"]
  case .acceleration: expected=["Engine RPM (SAE)","Vehicle Speed (SAE)","Scheduled Torque"]
  default: expected=["Engine RPM (SAE)","Throttle Angle","Scheduled Torque"]
  }
  let missing=expected.filter{nearest[$0] == nil},available=expected.count-missing.count
  let ratio=expected.isEmpty ? 0 : Double(available)/Double(expected.count)
  let base=GT500EpisodeHypothesisCompilerRev122.compile(episode)
  let adjusted=base.hypotheses.map{h in RankedHypothesisRev120(name:h.name,score:h.score*ratio,confidence:ratio<0.5 ? "insufficient":h.confidence,boundary:"Cursor-context score is the episode candidate score scaled by evidence coverage. It is not probability, proof, or causal attribution.")}
  let candidates=missing.map{NextMeasurementCandidateRev120(measurement:"Acquire/verify \($0) for this operating window",hypothesesSeparated:2,acquisitionCost:1,evidenceAuthority:1)}
  return .init(hypotheses:adjusted,coverage:.init(available:available,expected:expected.count,ratio:ratio,missing:missing,boundary:"Coverage measures presence of expected discriminating channels only. Presence does not establish correctness or cause."),nextMeasurement:BestNextMeasurementRev120.choose(candidates) ?? base.nextMeasurement,boundary:"Cursor movement changes evidence context and coverage, not the underlying episode's historical observations.")
 }
}

import SwiftUI
struct PLIntegratedForensicSessionRev125:View {
 let log:ParsedLogData
 @State private var selectedID:String?
 @State private var compareID:String?
 @State private var viewport:TimelineViewportRev127?
 @State private var visibleIDs:Set<String>=[]
 @State private var tracesInitialized=false
 @State private var saveStatus:String?
 private var session:ParsedLogForensicSessionRev125{ParsedLogForensicBridgeRev125.build(log)}
 private var selected:GT500EpisodeRev122?{session.episodes.first{$0.id==selectedID} ?? session.episodes.first}
 private var comparisonEpisode:GT500EpisodeRev122?{session.episodes.first{$0.id==compareID}}
 private var displayedSeries:[TimelineSeriesRev117]{session.series.filter{visibleIDs.contains($0.id)}}
 var body:some View {
  GeometryReader{geo in
   HStack(alignment:.top,spacing:8){
    ScrollView{PLSessionTOCRev123(episodes:session.episodes){e in
     selectedID=e.id
     viewport = .init(start:max(log.timestamps.first ?? 0,e.start-2),end:min(log.timestamps.last ?? e.end,e.end+2),cursor:e.peakTime)
    }.padding(8)}.frame(width:geo.size.width>850 ? 220:190)
    if let e=selected {
     let base=ForensicEpisodeWorkspaceRev123.select(e,series:session.series)
     let v=viewport ?? .init(start:base.windowStart,end:base.windowEnd,cursor:base.cursor)
     let nearest=ForensicCursorCoordinatorRev118.update(cursor:v.cursor,series:session.series,events:[],workspace:.init()).nearest
     let live=EpisodeCursorContextRev123(episode:base.episode,investigation:base.investigation,cursor:v.cursor,windowStart:v.start,windowEnd:v.end,nearest:nearest,evidenceBoundary:base.evidenceBoundary)
     let units=GT500ExportUnitCatalogRev128.units(for:session.series.map(\.id))
     let inspector=CursorEvidenceInspectorEngineRev128.inspect(cursor:v.cursor,episode:e,series:session.series,units:units)
     let cursorContext=CursorHypothesisContextEngineRev129.evaluate(episode:e,cursor:v.cursor,series:session.series)
     let capabilityMatrix=ForensicCapabilityMapperRev131.map(channels:log.channels)
     let structuredEvidence=StructuredEvidenceBuilderRev131.cursorRecords(log:log,sourceSHA256:nil,episode:e,cursor:v.cursor,series:session.series,units:units)
     ScrollView{VStack(spacing:8){
      PLInteractiveTimelineRev127(series:displayedSeries,episodes:session.episodes,totalStart:log.timestamps.first ?? v.start,totalEnd:log.timestamps.last ?? v.end,viewport:Binding(get:{viewport ?? v},set:{viewport=$0}))
      PLEvidenceWhyInspectorRev128(inspector:inspector)
      Text("STRUCTURED CURSOR EVIDENCE \(structuredEvidence.count) records").font(.system(size:6,weight:.bold,design:.monospaced)).foregroundStyle(.plTextSecondary)
      PLForensicCapabilityMatrixRev131(matrix:capabilityMatrix)
      PLThresholdAuthorityRev131(thresholds:.analysisDefaults)
      PLTraceControlsRev128(all:session.series,visible:$visibleIDs)
      PLInstrumentChrome{VStack(alignment:.leading,spacing:4){
       Text("HYPOTHESES / NEXT MEASUREMENT").font(.system(size:8,weight:.black,design:.monospaced)).foregroundStyle(.plBoost)
       Text("EVIDENCE COVERAGE \(cursorContext.coverage.available)/\(cursorContext.coverage.expected) · \(cursorContext.coverage.ratio*100,specifier:"%.0f")%").font(.system(size:7,weight:.bold,design:.monospaced))
       ForEach(cursorContext.hypotheses,id:\.name){h in Text("\(h.confidence.uppercased())  \(h.name)  \(h.score,specifier:"%.2f")").font(.system(size:7,design:.monospaced))}
       let ledger=EpisodeEvidenceLedgerBridgeRev124.build(context:live)
       ForEach(ledger.supporting,id:\.self){Text("＋ "+$0).font(.system(size:7))}
       ForEach(ledger.missing,id:\.self){Text("？ "+$0).font(.system(size:7)).foregroundStyle(.plWarning)}
       Text(cursorContext.nextMeasurement?.measurement ?? "No next measurement ranked.").font(.system(size:8,weight:.bold)).foregroundStyle(.plBoost)
       if let saveStatus{Text(saveStatus).font(.system(size:6,design:.monospaced)).foregroundStyle(.plTextSecondary)}
      }}
      PLBaselineBandInspectorRev127(context:live,profile:nil)
      PLCalibrationEvidenceRev132(channels:Set(session.series.map(\.id)))
      if let flagship=GoldenCorpusFlagshipInvestigationEngineRev134.build(log:log){PLGoldenCorpusFlagshipCaseRev134(investigation:flagship)}
      Picker("Compare",selection:$compareID){Text("No comparison").tag(String?.none);ForEach(session.episodes){x in Text("\(x.kind.rawValue) @ \(x.start,specifier:"%.2f")").tag(Optional(x.id))}}.pickerStyle(.menu)
      if let b=comparisonEpisode{PLEpisodeComparisonRev123(comparison:EpisodeComparisonEngineRev123.compare(live,ForensicEpisodeWorkspaceRev123.select(b,series:session.series)))}
     }.padding(8)}
    } else {Text("No forensic episodes detected with the current analysis parameters.").padding()}
   }
  }
  .navigationTitle("Forensic Session").navigationBarTitleDisplayMode(.inline)
  .accessibilityIdentifier("analysis.integratedForensicSession")
  .onAppear{if !tracesInitialized{visibleIDs=Set(session.series.map(\.id));tracesInitialized=true}}
  .onChange(of:viewport){_ in autosave()}
  .onChange(of:selectedID){_ in autosave()}
  .onChange(of:visibleIDs){_ in autosave()}
 }
 private func autosave(){
  guard let e=selected,let v=viewport else{return}
  do{try InvestigationLiveSaveRev128.save(episode:e,viewport:v,series:session.series,selectedSignals:Array(visibleIDs).sorted());saveStatus="AUTOSAVED"}
  catch{saveStatus="AUTOSAVE FAILED: \(error.localizedDescription)"}
 }
}

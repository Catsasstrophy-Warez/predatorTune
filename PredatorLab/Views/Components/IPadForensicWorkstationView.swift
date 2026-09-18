import SwiftUI

/// Dense three-pane forensic surface intended for iPad/large windows. It reuses the same immutable evidence package and reasoning engines as the phone workflow.
struct IPadForensicWorkstationView: View {
    let log: ImportedLog
    let dataset: ParsedLogData
    let evidence: DiagnosticEvidencePackage
    private var assessment: InvestigationAssessment? { evidence.episode.eventType == "protection" ? EvidenceReasoningEngine.assessR04(log: dataset, evidence: evidence) : nil }
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 10) {
                PLTrackHeader(eyebrow: "Race Engineer", title: "FORENSIC COMMAND CENTER", subtitle: "Evidence tree, synchronized recorder and reasoning inspector share one timestamp and one chain of custody.", icon: "waveform.path.ecg.rectangle", accent: .plBoost)
                    .frame(height: 132)
                HStack(spacing: 12) {
                ScrollView { VStack(alignment:.leading,spacing:12) {
                    Text("Evidence").font(.title2.bold())
                    LabeledContent("Source", value:log.filename)
                    LabeledContent("Event", value: String(format: "%@ @ %.3f s", evidence.episode.eventType, evidence.episode.start))
                    ForEach(evidence.observations) { o in VStack(alignment:.leading){Text(o.statement); Text(o.level.rawValue).font(.caption).foregroundStyle(.secondary)}; Divider() }
                }.padding() }.frame(width:proxy.size.width * 0.27).background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius:16))
                ScrollView { VStack(alignment:.leading,spacing:12) {
                    Text("Engineering Recorder").font(.title2.bold())
                    EngineeringRecorderView(dataset:dataset,evidence:evidence)
                }.padding() }.frame(width:proxy.size.width * 0.45).background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius:16))
                ScrollView { VStack(alignment:.leading,spacing:12) {
                    Text("Reasoning").font(.title2.bold())
                    if let assessment { ForEach(assessment.assessments.prefix(7)) { a in VStack(alignment:.leading){Text("\(a.hypothesisID.rawValue) · \(a.title)").font(.headline); ProgressView(value:a.fitScore); Text("\(a.fitPercent)% evidence fit").font(.caption)}; Divider() }; if let next=assessment.recommendations.first { Text("Next measurement").font(.headline); Text(next.measurement); Text(next.reason).font(.caption).foregroundStyle(.secondary) } }
                    else { Text("This event does not yet have a domain-specific reasoning package.").foregroundStyle(.secondary) }
                    NavigationLink { ReanalysisHistoryView(log:log) } label:{Label("Analysis lineage",systemImage:"clock.arrow.circlepath")}
                }.padding() }.frame(maxWidth:.infinity).background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius:16))
                }.padding(.horizontal)
            }.padding(.vertical, 10).plScreenBackground().navigationTitle("Forensic Workstation")
        }
    }
}

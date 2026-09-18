import SwiftUI
import Charts
import UniformTypeIdentifiers

struct ForensicLogView: View {
    let log: ImportedLog
    @EnvironmentObject var dataRepository: DataRepository
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var dataset: ParsedLogData?
    @State private var loadError: String?
    @State private var selectedEpisodeID: UUID?
    @State private var annotations: [ForensicAnnotation] = []
    @State private var rcas: [PostJobRCA] = []
    @State private var attachments: [EvidenceAttachment] = []
    @State private var serviceRecords: [ServiceRecord] = []
    @State private var rcaAttachmentLinks: [RCAAttachmentLink] = []
    @State private var showingAttachmentImporter = false
    @State private var attachmentNote = ""
    @State private var annotationText = ""
    @State private var annotationTime: Double = 0
    @State private var annotationKind: AnnotationKind = .operatorObservation
    @State private var evidenceRecordError: String?
    @State private var rcaSymptom = ""
    @State private var rcaChange = ""
    @State private var rcaUnknowns = ""
    @State private var rcaAttachmentRole = "supporting-artifact"

    private var episodes: [LogEventEpisode] { dataset.map { LogEventDetector.detectAllEpisodes(logData: $0) } ?? [] }
    private var quality: AcquisitionQualityReport? { dataset.map { AcquisitionQualityEngine.analyze($0) } }
    private var selectedEpisode: LogEventEpisode? { episodes.first { $0.id == selectedEpisodeID } ?? episodes.first }
    private var evidence: DiagnosticEvidencePackage? {
        guard let dataset, let selectedEpisode else { return nil }
        return EvidenceExtractionEngine.package(log: dataset, episode: selectedEpisode, logID: log.id, buildStateID: log.buildStateID)
    }
    private var r04Assessment: InvestigationAssessment? {
        guard let dataset, let evidence, selectedEpisode?.eventType == "protection" else { return nil }
        return EvidenceReasoningEngine.assessR04(log: dataset, evidence: evidence)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let loadError {
                    PlatformUnavailableView(title: "Dataset unavailable", systemImage: "exclamationmark.triangle", description: loadError)
                } else if dataset == nil {
                    ProgressView("Loading forensic dataset…")
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            acquisitionCard
                            episodeCard
                            evidenceCard
                            derivedSignalCard
                            hypothesisCard
                            nextTestCard
                            compareCard
                            analysisHistoryCard
                            annotationsCard
                            attachmentsCard
                            serviceHistoryCard
                            rcaCard
                            historicalCaseCard
                            evidenceCoverageCard
                            iPadWorkstationCard
                        }.padding()
                    }.plScreenBackground()
                }
            }
            .navigationTitle("Forensic Workbench")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task { load(); await loadDurableEvidenceRecords() }
            .fileImporter(isPresented: $showingAttachmentImporter, allowedContentTypes: [.image, .pdf, .commaSeparatedText, .plainText, .json, .data], allowsMultipleSelection: false) { result in
                Task { await importAttachment(result) }
            }
        }
    }

    @ViewBuilder private var acquisitionCard: some View {
        if let quality {
            PLCard {
                VStack(alignment: .leading, spacing: 10) {
                    PLSectionHeader(title: "Acquisition Quality", systemImage: "antenna.radiowaves.left.and.right", accent: .plBoost)
                    HStack {
                        stat("Samples", "\(quality.sampleCount)")
                        stat("Rate", quality.estimatedOverallHz.map { String(format: "%.1f Hz", $0) } ?? "Unknown")
                        stat("Channels", "\(log.channels.count)")
                    }
                    AcquisitionQualityVisualizationView(report: quality)
                    if quality.warnings.isEmpty { Label("No acquisition-quality warnings detected", systemImage: "checkmark.circle.fill").foregroundStyle(.green) }
                    else { ForEach(quality.warnings, id: \.self) { Label($0, systemImage: "exclamationmark.triangle.fill").font(.plCaption).foregroundStyle(.orange) } }
                }
            }
        }
    }

    @ViewBuilder private var evidenceCoverageCard: some View {
        if let dataset {
            PLCard { NavigationLink { InvestigationEvidenceCoverageView(dataset: dataset) } label: { Label("Investigation Evidence Coverage", systemImage:"checklist.checked") } }
        }
    }

    @ViewBuilder private var episodeCard: some View {
        PLCard {
            VStack(alignment: .leading, spacing: 10) {
                PLSectionHeader(title: "Event Episodes", systemImage: "waveform.path.ecg")
                if episodes.isEmpty { Text("No grouped diagnostic episodes were detected.").foregroundStyle(.plTextSecondary) }
                else {
                    Picker("Episode", selection: Binding(get: { selectedEpisodeID ?? episodes.first?.id }, set: { selectedEpisodeID = $0 })) {
                        ForEach(episodes) { ep in Text("\(ep.eventType) @ \(ep.start, specifier: "%.2f") s").tag(Optional(ep.id)) }
                    }.pickerStyle(.menu)
                    if let ep = selectedEpisode {
                        HStack { stat("Start", String(format: "%.3f s", ep.start)); stat("Duration", String(format: "%.3f s", ep.duration)); stat("Samples", "\(ep.sampleCount)") }
                        Text(ep.description).font(.plBody)
                        Text("Flight Recorder: \(String(format: "%.2f", max(0, ep.start - 5))) s → \(String(format: "%.2f", ep.end + 2)) s").font(.plCaption).foregroundStyle(.plTextSecondary)
                    }
                }
            }
        }
    }

    @ViewBuilder private var evidenceCard: some View {
        if let evidence {
            PLCard {
                VStack(alignment: .leading, spacing: 10) {
                    PLSectionHeader(title: "Extracted Evidence", systemImage: "magnifyingglass.circle.fill", accent: .plIgnition)
                    if evidence.observations.isEmpty { Text("No derived evidence could be calculated from the available channels.").foregroundStyle(.plTextSecondary) }
                    ForEach(evidence.observations) { observation in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(observation.statement).font(.plBody)
                            Text("Observed / PredatorLab derived analysis").font(.plCaption).foregroundStyle(.plTextSecondary)
                        }
                        if observation.id != evidence.observations.last?.id { Divider() }
                    }
                }
            }
        }
    }


    @ViewBuilder private var derivedSignalCard: some View {
        if let dataset, let evidence {
            PLCard {
                EngineeringRecorderView(dataset: dataset, evidence: evidence, serviceMarkers: ServiceTimelineOverlayEngine.markers(serviceRecords: serviceRecords, log: log))
            }
        }
    }

    @ViewBuilder private var hypothesisCard: some View {
        if let assessment = r04Assessment {
            PLCard {
                VStack(alignment: .leading, spacing: 12) {
                    PLSectionHeader(title: "R04 Competing Hypotheses", systemImage: "point.3.connected.trianglepath.dotted", accent: .plIgnition)
                    Text("Evidence-fit scores are transparent PredatorLab heuristics, not probabilities or OEM conclusions.").font(.plCaption).foregroundStyle(.plTextSecondary)
                    ForEach(assessment.assessments.prefix(7)) { item in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("\(item.hypothesisID.rawValue) · \(item.title)").font(.plBody).fontWeight(.semibold)
                                Spacer()
                                Text("\(item.fitPercent)% fit").font(.plMono(12))
                            }
                            ProgressView(value: item.fitScore)
                            if let support = item.supports.first { Label(support, systemImage: "plus.circle").font(.plCaption).foregroundStyle(.plTextSecondary) }
                            if let contradiction = item.contradicts.first { Label(contradiction, systemImage: "minus.circle").font(.plCaption).foregroundStyle(.plTextSecondary) }
                            if let missing = item.missing.first { Label("Missing: \(missing)", systemImage: "questionmark.circle").font(.plCaption).foregroundStyle(.plTextSecondary) }
                            if let channel = atlasChannel(for: item.hypothesisID), let entry = MeasurementAtlas.entry(for: channel) {
                                NavigationLink { MeasurementAtlasDetailView(entry: entry) } label: {
                                    Label("Open related signal: \(entry.title)", systemImage: "waveform.path.ecg")
                                        .font(.plCaption)
                                }
                            }
                        }
                        Divider()
                    }
                    if !assessment.missingRequiredChannels.isEmpty {
                        Label("Missing critical channels: " + assessment.missingRequiredChannels.map(\.rawValue).joined(separator: ", "), systemImage: "exclamationmark.triangle").font(.plCaption).foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    @ViewBuilder private var nextTestCard: some View {
        if let assessment = r04Assessment, let recommendation = assessment.recommendations.first {
            PLCard {
                VStack(alignment: .leading, spacing: 8) {
                    PLSectionHeader(title: "Best Next Measurement", systemImage: "scope", accent: .plBoost)
                    Text(recommendation.measurement).font(.plBody).fontWeight(.semibold)
                    Text(recommendation.reason).font(.plCaption).foregroundStyle(.plTextSecondary)
                    Text("Information-gain rank: \(Int((recommendation.informationGainScore * 100).rounded()))/100").font(.plMono(12)).foregroundStyle(.plTextSecondary)
                    ForEach(assessment.caveats, id: \.self) { caveat in
                        Label(caveat, systemImage: "info.circle").font(.plCaption).foregroundStyle(.plTextSecondary)
                    }
                }
            }
        }
    }


    @ViewBuilder private var compareCard: some View {
        if let dataset, let evidence {
            PLCard {
                VStack(alignment: .leading, spacing: 8) {
                    PLSectionHeader(title: "Validation Comparison", systemImage: "arrow.left.arrow.right", accent: .plBoost)
                    Text("Compare this episode with another event from the same vehicle, including logs captured on a different build revision.").font(.plCaption).foregroundStyle(.plTextSecondary)
                    NavigationLink {
                        EventComparisonView(baselineLog: log, baselineDataset: dataset, baselineEvidence: evidence)
                            .environmentObject(dataRepository)
                    } label: { Label("Compare Event", systemImage: "chart.xyaxis.line") }
                }
            }
        }
    }


    @ViewBuilder private var annotationsCard: some View {
        PLCard {
            VStack(alignment: .leading, spacing: 10) {
                PLSectionHeader(title: "Forensic Annotations", systemImage: "text.bubble", accent: .plBoost)
                Text("Human observations remain contextual evidence and are never converted into scanner measurements.").font(.plCaption).foregroundStyle(.plTextSecondary)
                Picker("Kind", selection: $annotationKind) { ForEach(AnnotationKind.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu)
                HStack { Text("Time"); TextField("seconds", value: $annotationTime, format: .number).textFieldStyle(.roundedBorder).keyboardType(.decimalPad) }
                TextField("Observation or test action", text: $annotationText, axis: .vertical).textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("forensic.annotation.text")
                Button { Task { await saveAnnotation() } } label: { Label("Save Annotation", systemImage: "plus.bubble") }
                    .disabled(annotationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("forensic.annotation.save")
                if let evidenceRecordError { Text(evidenceRecordError).font(.plCaption).foregroundStyle(.red) }
                ForEach(annotations.prefix(8)) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "T+%.3f s · %@", item.timestamp, item.kind.rawValue)).font(.plMono(11))
                        Text(item.text).font(.plBody)
                        Text(item.evidenceBoundary).font(.plCaption).foregroundStyle(.plTextSecondary)
                    }
                    Divider()
                }
            }
        }
    }

    @ViewBuilder private var attachmentsCard: some View {
        PLCard {
            VStack(alignment: .leading, spacing: 10) {
                PLSectionHeader(title: "Evidence Attachments", systemImage: "paperclip", accent: .plIgnition)
                Text("Preserve photos, dyno sheets, scan captures, invoices, CSVs, and other supporting files with SHA-256 integrity. An attachment supports the case but does not prove its interpretation.")
                    .font(.plCaption).foregroundStyle(.plTextSecondary)
                TextField("Optional evidence note", text: $attachmentNote, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("forensic.attachment.note")
                Button { showingAttachmentImporter = true } label: { Label("Attach Evidence File", systemImage: "paperclip.badge.ellipsis") }
                    .accessibilityIdentifier("forensic.attachment.import")
                if attachments.isEmpty {
                    Text("No durable attachments are linked to this log.").foregroundStyle(.plTextSecondary)
                }
                ForEach(attachments.prefix(10)) { item in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack { Text(item.filename).font(.plBody).fontWeight(.semibold); Spacer(); Text(ByteCountFormatter.string(fromByteCount: item.byteCount, countStyle: .file)).font(.plCaption) }
                        Text(item.mediaType).font(.plMono(11)).foregroundStyle(.plTextSecondary)
                        if let note = item.note, !note.isEmpty { Text(note).font(.plCaption) }
                        Text("SHA-256 " + String(item.sourceSHA256.prefix(12)) + "…").font(.plMono(10)).foregroundStyle(.plTextSecondary)
                        Text(item.evidenceBoundary).font(.plCaption).foregroundStyle(.plTextSecondary)
                        HStack {
                            if let url = try? dataRepository.evidenceAttachmentURL(item) {
                                NavigationLink { EvidenceAttachmentPreview(url: url).ignoresSafeArea() } label: { Label("Preview", systemImage: "eye") }
                                    .accessibilityIdentifier("forensic.attachment.preview.\(item.id.uuidString)")
                            }
                            Spacer()
                            Button(role: .destructive) { Task { await deleteAttachment(item) } } label: { Label("Delete", systemImage: "trash") }
                                .accessibilityIdentifier("forensic.attachment.delete.\(item.id.uuidString)")
                        }.font(.plCaption)
                    }
                    Divider()
                }
            }
        }
    }

    @ViewBuilder private var serviceHistoryCard: some View {
        let associations = ServiceHistoryCorrelationEngine.associations(serviceRecords: serviceRecords, logs: [log], withinDays: 90)
        if !serviceRecords.isEmpty {
            PLCard {
                VStack(alignment: .leading, spacing: 8) {
                    PLSectionHeader(title: "Service History Context", systemImage: "wrench.and.screwdriver", accent: .plBoost)
                    Text("Service timing is contextual evidence. Temporal proximity does not prove a repair caused, fixed, or created a diagnostic event.").font(.plCaption).foregroundStyle(.plTextSecondary)
                    ForEach(serviceRecords.prefix(5)) { service in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(service.procedure.isEmpty ? "Service record" : service.procedure).font(.plBody).fontWeight(.semibold)
                            Text("\(service.date.formatted(date: .abbreviated, time: .omitted)) · \(service.mileage) mi").font(.plCaption)
                            if let match = associations.first(where: { $0.serviceRecordID == service.id }) { Text(match.summary).font(.plCaption); Text(match.boundary).font(.plCaption).foregroundStyle(.plTextSecondary) }
                        }
                        Divider()
                    }
                }
            }
        }
    }

    @ViewBuilder private var rcaCard: some View {
        PLCard {
            VStack(alignment: .leading, spacing: 8) {
                PLSectionHeader(title: "Post-Job RCA History", systemImage: "doc.text.magnifyingglass", accent: .plIgnition)
                TextField("Symptom / concern", text: $rcaSymptom, axis: .vertical).textFieldStyle(.roundedBorder).accessibilityIdentifier("forensic.rca.symptom")
                TextField("Change or repair performed (optional)", text: $rcaChange, axis: .vertical).textFieldStyle(.roundedBorder).accessibilityIdentifier("forensic.rca.change")
                TextField("Unresolved unknowns, comma separated", text: $rcaUnknowns, axis: .vertical).textFieldStyle(.roundedBorder).accessibilityIdentifier("forensic.rca.unknowns")
                Picker("Attachment role", selection: $rcaAttachmentRole) {
                    Text("Supporting artifact").tag("supporting-artifact")
                    Text("Pre-repair evidence").tag("pre-repair-evidence")
                    Text("Post-repair evidence").tag("post-repair-evidence")
                    Text("Validation evidence").tag("validation-evidence")
                    Text("Service documentation").tag("service-documentation")
                }.accessibilityIdentifier("forensic.rca.attachmentRole")
                Text("The selected role describes how current log attachments relate to this RCA; it does not increase causal confidence by itself.").font(.plCaption).foregroundStyle(.plTextSecondary)
                Button { Task { await saveRCA() } } label: { Label("Save Evidence-Bounded RCA", systemImage: "checklist") }
                    .disabled(rcaSymptom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("forensic.rca.save")
                Text("Without a saved validation assessment this RCA remains insufficient-confidence by design.").font(.plCaption).foregroundStyle(.plTextSecondary)
                if rcas.isEmpty { Text("No durable RCA records for this vehicle yet.").foregroundStyle(.plTextSecondary) }
                ForEach(rcas.prefix(5)) { rca in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(rca.symptom).font(.plBody).fontWeight(.semibold)
                        Text("Confidence: \(rca.confidence.rawValue) · \(rca.createdAt.formatted(date: .abbreviated, time: .shortened))").font(.plCaption)
                        Text(rca.boundary).font(.plCaption).foregroundStyle(.plTextSecondary)
                        let linked = linkedAttachments(for: rca.id)
                        if !linked.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(linked) { attachment in
                                        if let url = try? dataRepository.evidenceAttachmentURL(attachment) {
                                            NavigationLink { EvidenceAttachmentPreview(url: url).ignoresSafeArea() } label: {
                                                Label(attachment.filename, systemImage: "paperclip").font(.plCaption).lineLimit(1)
                                            }.accessibilityIdentifier("forensic.rca.attachment.\(attachment.id.uuidString)")
                                        }
                                    }
                                }
                            }
                            Text("Linked artifacts support the historical record but do not independently verify the RCA conclusion.").font(.plCaption).foregroundStyle(.plTextSecondary)
                        }
                    }
                    Divider()
                }
            }
        }
    }

    @ViewBuilder private var historicalCaseCard: some View {
        let titles = r04Assessment?.assessments.map(\.title) ?? []
        let symptom = rcaSymptom.isEmpty ? (evidence?.episode.description ?? "") : rcaSymptom
        let matches = CaseReplayEngine.rank(currentSymptom: symptom, buildStateID: log.buildStateID, hypothesisTitles: titles, history: rcas)
        if !matches.isEmpty {
            PLCard {
                VStack(alignment: .leading, spacing: 8) {
                    PLSectionHeader(title: "Historical Case Replay", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90", accent: .plBoost)
                    ForEach(matches.prefix(3)) { match in
                        if let rca = rcas.first(where: { $0.id == match.rcaID }) {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack { Text(rca.symptom).font(.plBody).fontWeight(.semibold); Spacer(); Text("\(Int(match.score * 100))% context match").font(.plCaption) }
                                ForEach(match.reasons, id: \.self) { Text($0).font(.plCaption).foregroundStyle(.plTextSecondary) }
                                let linked = linkedAttachments(for: rca.id)
                                if !linked.isEmpty {
                                    Text("Supporting artifacts: \(linked.count)").font(.plCaption).fontWeight(.semibold)
                                    ForEach(linked.prefix(3)) { attachment in
                                        if let url = try? dataRepository.evidenceAttachmentURL(attachment) {
                                            NavigationLink { EvidenceAttachmentPreview(url: url).ignoresSafeArea() } label: { Label(attachment.filename, systemImage: "doc.viewfinder") }.font(.plCaption)
                                        }
                                    }
                                }
                                Text(match.boundary).font(.plCaption).foregroundStyle(.plTextSecondary)
                            }
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func linkedAttachments(for rcaID: UUID) -> [EvidenceAttachment] {
        let ids = Set(rcaAttachmentLinks.filter { $0.rcaID == rcaID }.map(\.attachmentID))
        return attachments.filter { ids.contains($0.id) }
    }

    private func saveRCA() async {
        let firstOut = evidence?.observations.compactMap { observation in
            RCAEvidenceStep(timestamp: observation.timestamp, kind: observation.key, statement: observation.statement, sourceID: log.id.uuidString)
        } ?? []
        let hypotheses = r04Assessment?.assessments.map { "\($0.hypothesisID.rawValue): \($0.title)" } ?? []
        let tests = annotations.filter { $0.kind == .testAction }.map(\.text)
        let unknowns = rcaUnknowns.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let rca = PostJobRCAEngine.build(vehicleID: log.vehicleID, buildStateID: log.buildStateID, symptom: rcaSymptom.trimmingCharacters(in: .whitespacesAndNewlines), firstOut: firstOut, hypotheses: hypotheses, tests: tests, change: rcaChange.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty, validation: nil, unknowns: unknowns)
        do {
            try await dataRepository.save(postJobRCA: rca)
            for attachment in attachments {
                let link = RCAEvidenceLinkEngine.explicitlyLink(rcaID: rca.id, attachmentID: attachment.id, role: rcaAttachmentRole, note: attachment.note)
                try await dataRepository.save(rcaAttachmentLink: link, vehicleID: log.vehicleID)
            }
            rcas = try await dataRepository.fetchPostJobRCAs(forVehicle: log.vehicleID)
            rcaAttachmentLinks = try await dataRepository.fetchRCAAttachmentLinks(forVehicle: log.vehicleID)
            attachments = try await dataRepository.fetchEvidenceAttachments(forVehicle: log.vehicleID, logID: log.id)
            rcaSymptom = ""; rcaChange = ""; rcaUnknowns = ""
        } catch {
            evidenceRecordError = error.localizedDescription
            dataRepository.reportPersistenceFailure(domain: "postJobRCA", recordID: rca.id.uuidString, error: error)
        }
    }

    private func loadDurableEvidenceRecords() async {
        do {
            annotations = try await dataRepository.fetchForensicAnnotations(logID: log.id, vehicleID: log.vehicleID)
            rcas = try await dataRepository.fetchPostJobRCAs(forVehicle: log.vehicleID)
            attachments = try await dataRepository.fetchEvidenceAttachments(forVehicle: log.vehicleID, logID: log.id)
            serviceRecords = try await dataRepository.fetchAllServiceRecords(forVehicle: log.vehicleID)
            rcaAttachmentLinks = try await dataRepository.fetchRCAAttachmentLinks(forVehicle: log.vehicleID)
        } catch { evidenceRecordError = error.localizedDescription }
    }

    private func deleteAttachment(_ attachment: EvidenceAttachment) async {
        do {
            try await dataRepository.delete(evidenceAttachment: attachment)
            attachments = try await dataRepository.fetchEvidenceAttachments(forVehicle: log.vehicleID, logID: log.id)
        } catch {
            evidenceRecordError = error.localizedDescription
            dataRepository.reportPersistenceFailure(domain: "evidenceAttachmentDelete", recordID: attachment.id.uuidString, error: error)
        }
    }

    private func importAttachment(_ result: Result<[URL], Error>) async {
        do {
            guard let url = try result.get().first else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let metadata = try EvidenceAttachmentImportEngine.makeMetadata(sourceURL: url, vehicleID: log.vehicleID, logID: log.id, note: attachmentNote)
            _ = try await dataRepository.save(evidenceAttachment: metadata, sourceURL: url)
            attachments = try await dataRepository.fetchEvidenceAttachments(forVehicle: log.vehicleID, logID: log.id)
            attachmentNote = ""
        } catch {
            evidenceRecordError = error.localizedDescription
            dataRepository.reportPersistenceFailure(domain: "evidenceAttachment", recordID: log.id.uuidString, error: error)
        }
    }

    private func saveAnnotation() async {
        let value = ForensicAnnotation(logID: log.id, timestamp: max(0, min(annotationTime, log.duration)), kind: annotationKind, text: annotationText)
        do {
            try await dataRepository.save(forensicAnnotation: value, vehicleID: log.vehicleID)
            annotationText = ""
            annotations = try await dataRepository.fetchForensicAnnotations(logID: log.id, vehicleID: log.vehicleID)
        } catch {
            evidenceRecordError = error.localizedDescription
            dataRepository.reportPersistenceFailure(domain: "forensicAnnotation", recordID: value.id.uuidString, error: error)
        }
    }

    @ViewBuilder private var analysisHistoryCard: some View {
        PLCard {
            VStack(alignment: .leading, spacing: 8) {
                PLSectionHeader(title: "Analysis Provenance", systemImage: "clock.arrow.circlepath", accent: .plBoost)
                Text("Historical interpretations are retained separately from immutable source evidence.").font(.plCaption).foregroundStyle(.plTextSecondary)
                NavigationLink { ReanalysisHistoryView(log: log) } label: { Label("Open Analysis History", systemImage: "list.bullet.rectangle") }
            }
        }
    }

    @ViewBuilder private var iPadWorkstationCard: some View {
        if horizontalSizeClass == .regular, let dataset, let evidence {
            PLCard { VStack(alignment:.leading,spacing:8) {
                PLSectionHeader(title:"iPad Forensic Workstation",systemImage:"ipad.landscape",accent:.plBoost)
                Text("Three-pane evidence, recorder and reasoning workspace for large displays.").font(.plCaption).foregroundStyle(.plTextSecondary)
                NavigationLink { IPadForensicWorkstationView(log:log,dataset:dataset,evidence:evidence) } label:{Label("Open Workstation",systemImage:"rectangle.split.3x1")}
            }}
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) { Text(title).font(.plCaption).foregroundStyle(.plTextSecondary); Text(value).font(.plMono(13)).foregroundStyle(.plTextPrimary) }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func load() {
        do { dataset = try dataRepository.reloadDataset(for: log); selectedEpisodeID = LogEventDetector.detectAllEpisodes(logData: dataset!).first?.id }
        catch { loadError = error.localizedDescription }
    }
    private func atlasChannel(for hypothesis: R04HypothesisID) -> CanonicalChannel? {
        switch hypothesis {
        case .h1aInjectorCapacity, .h1bInjectionWindow: return .injectorPulseWidth
        case .h2PumpPressure, .h7PressureStrategy: return .fuelPressureActual
        case .h3ModeledFlowLimit, .h6SecondaryProtection: return .torqueProtectionSource
        case .h4DCTTransient: return .gearActual
        case .h5PIDIdentity: return .maximumInjectorPulseWidth
        }
    }

}

private extension String { var nilIfEmpty: String? { isEmpty ? nil : self } }

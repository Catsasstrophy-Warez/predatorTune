// PredatorLab/Services/DataRepository.swift
// Rev14 persistence facade: Core Data entities + Application Support evidence/cache + UserDefaults preferences.

import Foundation
import Combine

@MainActor
class DataRepository: NSObject, ObservableObject {

    @Published private(set) var persistenceIssues: [PersistenceIssue] = []
    private var datasetCache: [String: ParsedLogData] = [:]
    private let persistentDatasetCache = PersistentDatasetCache()
    let entityStore = DurableEntityStore()
    var persistenceHealth: PersistenceHealthSnapshot { .init(issues: persistenceIssues) }

    func recordPersistenceIssue(domain: String, recordID: String? = nil, error: Error) {
        persistenceIssues.append(.init(severity: .error, domain: domain, recordID: recordID, message: error.localizedDescription))
        PLStructuredLog.event("persistence.failure", level: .error, fields: ["domain": domain, "recordID": recordID ?? "none", "errorType": String(describing: type(of: error))])
    }

    func reportPersistenceFailure(domain: String, recordID: String? = nil, error: Error) {
        recordPersistenceIssue(domain: domain, recordID: recordID, error: error)
    }

    func clearPersistenceHealth() { persistenceIssues.removeAll() }

    // MARK: - Forensic Annotation Operations

    func save(forensicAnnotation: ForensicAnnotation, vehicleID: UUID) async throws {
        try entityStore.save(forensicAnnotation, id: forensicAnnotation.id, vehicleID: vehicleID, kind: .forensicAnnotation)
    }

    func fetchForensicAnnotations(logID: UUID, vehicleID: UUID) async throws -> [ForensicAnnotation] {
        let values = try entityStore.fetchAll(ForensicAnnotation.self, kind: .forensicAnnotation, vehicleID: vehicleID)
        return values.filter { $0.logID == logID }.sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - Post-Job RCA Operations

    func save(postJobRCA: PostJobRCA) async throws {
        try entityStore.save(postJobRCA, id: postJobRCA.id, vehicleID: postJobRCA.vehicleID, kind: .postJobRCA)
    }

    func fetchPostJobRCAs(forVehicle vehicleID: UUID) async throws -> [PostJobRCA] {
        try entityStore.fetchAll(PostJobRCA.self, kind: .postJobRCA, vehicleID: vehicleID)
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - RCA Evidence Relationship Operations

    func save(rcaAttachmentLink: RCAAttachmentLink, vehicleID: UUID) async throws {
        try entityStore.save(rcaAttachmentLink, id: rcaAttachmentLink.id, vehicleID: vehicleID, kind: .rcaAttachmentLink)
    }

    func fetchRCAAttachmentLinks(forVehicle vehicleID: UUID, rcaID: UUID? = nil) async throws -> [RCAAttachmentLink] {
        let values = try entityStore.fetchAll(RCAAttachmentLink.self, kind: .rcaAttachmentLink, vehicleID: vehicleID)
        return values.filter { rcaID == nil || $0.rcaID == rcaID }
    }

    func deleteRCAAttachmentLinks(attachmentID: UUID, vehicleID: UUID) async throws {
        let values = try await fetchRCAAttachmentLinks(forVehicle: vehicleID)
        for link in values where link.attachmentID == attachmentID { try entityStore.delete(id: link.id, kind: .rcaAttachmentLink) }
    }

    // MARK: - Measurement Claim Operations

    func save(measurementClaim: PersistedMeasurementClaim) async throws {
        try entityStore.save(measurementClaim, id: measurementClaim.id, vehicleID: measurementClaim.vehicleID, kind: .measurementClaim)
    }

    func fetchMeasurementClaims(vehicleID: UUID? = nil) async throws -> [PersistedMeasurementClaim] {
        try entityStore.fetchAll(PersistedMeasurementClaim.self, kind: .measurementClaim, vehicleID: vehicleID)
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func save(measurementClaimRevision: MeasurementClaimRevision) async throws {
        try entityStore.save(measurementClaimRevision, id: measurementClaimRevision.id, vehicleID: measurementClaimRevision.vehicleID, kind: .measurementClaimRevision)
    }

    func fetchMeasurementClaimRevisions(vehicleID: UUID? = nil, claimID: String? = nil) async throws -> [MeasurementClaimRevision] {
        let values = try entityStore.fetchAll(MeasurementClaimRevision.self, kind: .measurementClaimRevision, vehicleID: vehicleID)
        return values.filter { claimID == nil || $0.claimID == claimID }.sorted { $0.recordedAt > $1.recordedAt }
    }

    // MARK: - Technical Truth Operations

    func save(technicalTruth: PersistedTechnicalTruth) async throws {
        try entityStore.save(technicalTruth, id: technicalTruth.id, vehicleID: technicalTruth.vehicleID, kind: .technicalTruth)
    }

    func fetchTechnicalTruth(vehicleID: UUID? = nil) async throws -> [PersistedTechnicalTruth] {
        try entityStore.fetchAll(PersistedTechnicalTruth.self, kind: .technicalTruth, vehicleID: vehicleID).sorted { $0.updatedAt > $1.updatedAt }
    }

    func save(technicalTruthRevision: TechnicalTruthRevision) async throws {
        try entityStore.save(technicalTruthRevision, id: technicalTruthRevision.id, vehicleID: technicalTruthRevision.vehicleID, kind: .technicalTruthRevision)
    }

    func fetchTechnicalTruthRevisions(vehicleID: UUID? = nil, truthID: String? = nil) async throws -> [TechnicalTruthRevision] {
        let values = try entityStore.fetchAll(TechnicalTruthRevision.self, kind: .technicalTruthRevision, vehicleID: vehicleID)
        return values.filter { truthID == nil || $0.truthID == truthID }.sorted { $0.recordedAt > $1.recordedAt }
    }

    // MARK: - Evidence Acquisition / Claim Review Operations

    func save(evidenceArtifact: PersistedEvidenceArtifact) async throws {
        try entityStore.save(evidenceArtifact, id: evidenceArtifact.id, vehicleID: evidenceArtifact.vehicleID, kind: .evidenceArtifact)
    }

    func fetchEvidenceArtifacts(vehicleID: UUID? = nil) async throws -> [PersistedEvidenceArtifact] {
        try entityStore.fetchAll(PersistedEvidenceArtifact.self, kind: .evidenceArtifact, vehicleID: vehicleID).sorted { $0.recordedAt > $1.recordedAt }
    }

    func save(evidenceTruthReview: EvidenceTruthReview) async throws {
        try entityStore.save(evidenceTruthReview, id: evidenceTruthReview.id, vehicleID: evidenceTruthReview.vehicleID, kind: .evidenceTruthReview)
    }

    func fetchEvidenceTruthReviews(vehicleID: UUID? = nil, artifactID: UUID? = nil, truthID: String? = nil) async throws -> [EvidenceTruthReview] {
        let values = try entityStore.fetchAll(EvidenceTruthReview.self, kind: .evidenceTruthReview, vehicleID: vehicleID)
        return values.filter { (artifactID == nil || $0.artifactID == artifactID) && (truthID == nil || $0.truthID == truthID) }.sorted { $0.recordedAt > $1.recordedAt }
    }

    // MARK: - Evidence Attachment Operations

    func save(evidenceAttachment: EvidenceAttachment, sourceURL: URL) async throws -> EvidenceAttachment {
        let root = try attachmentDirectory()
        _ = try EvidenceAttachmentStore.persist(sourceURL: sourceURL, metadata: evidenceAttachment, root: root)
        try entityStore.save(evidenceAttachment, id: evidenceAttachment.id, vehicleID: evidenceAttachment.vehicleID, kind: .evidenceAttachment)
        return evidenceAttachment
    }

    func fetchEvidenceAttachments(forVehicle vehicleID: UUID, logID: UUID? = nil) async throws -> [EvidenceAttachment] {
        let values = try entityStore.fetchAll(EvidenceAttachment.self, kind: .evidenceAttachment, vehicleID: vehicleID)
        return values.filter { logID == nil || $0.logID == logID }.sorted { $0.createdAt > $1.createdAt }
    }

    func evidenceAttachmentURL(_ attachment: EvidenceAttachment) throws -> URL {
        try EvidenceAttachmentStore.destination(for: attachment, root: attachmentDirectory())
    }

    func delete(evidenceAttachment: EvidenceAttachment) async throws {
        try await deleteRCAAttachmentLinks(attachmentID: evidenceAttachment.id, vehicleID: evidenceAttachment.vehicleID)
        try EvidenceAttachmentStore.remove(evidenceAttachment, root: attachmentDirectory())
        try entityStore.delete(id: evidenceAttachment.id, kind: .evidenceAttachment)
    }

    private func attachmentDirectory() throws -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("PredatorLab/EvidenceAttachments", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    // MARK: - Imported Log Operations

    /// Persists log metadata and copies the source CSV into Application Support so it can be
    /// reopened after the security-scoped import URL is no longer available.
    func save(importedLog: ImportedLog, sourceURL: URL? = nil, markAnalyzedWithCurrentEngine: Bool = true) async throws -> ImportedLog {
        var durableLog = importedLog
        if let sourceURL {
            let directory = try logDirectory()
            let destination = directory.appendingPathComponent("\(importedLog.id.uuidString).csv")
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destination)
            durableLog.fileURL = destination
            durableLog.sourceSHA256 = try EvidenceIntegrity.sha256(of: destination)
            if markAnalyzedWithCurrentEngine {
                durableLog.analysisEngineVersion = .current
                durableLog.analysisRevisions = ReanalysisLineageEngine.appendCurrent(to: durableLog.analysisRevisions, sourceSHA256: durableLog.sourceSHA256, reason: "Source imported and interpreted with current engine")
            }
        }

        try entityStore.save(durableLog, id: durableLog.id, vehicleID: durableLog.vehicleID, kind: .importedLog)
        return durableLog
    }

    /// Records a new analysis interpretation without altering the original source evidence.
    func markReanalyzed(_ log: ImportedLog, reason: String = "Reanalyzed with current engine") async throws -> ImportedLog {
        var updated = log
        updated.analysisEngineVersion = .current
        updated.analyzedDate = .now
        updated.analysisRevisions = ReanalysisLineageEngine.appendCurrent(to: updated.analysisRevisions, sourceSHA256: updated.sourceSHA256, reason: reason)
        try entityStore.save(updated, id: updated.id, vehicleID: updated.vehicleID, kind: .importedLog)
        return updated
    }

    func fetchAllImportedLogs(forVehicle vehicleID: UUID) async throws -> [ImportedLog] {
        let stored = try entityStore.fetchAll(ImportedLog.self, kind: .importedLog, vehicleID: vehicleID)
        if !stored.isEmpty { return stored.sorted { $0.importDate > $1.importDate } }
        let decoder = JSONDecoder()
        let ids = UserDefaults.standard.stringArray(forKey: "importedlog_ids") ?? []
        return ids.compactMap { id in
            guard let data = UserDefaults.standard.data(forKey: "importedlog_\(id)") else { return nil }
            do { return try decoder.decode(ImportedLog.self, from: data) } catch { recordPersistenceIssue(domain: "importedLog", recordID: id, error: error); return nil }
        }.filter { $0.vehicleID == vehicleID }.sorted { $0.importDate > $1.importDate }
    }

    func reloadDataset(for log: ImportedLog) throws -> ParsedLogData {
        guard let url = log.fileURL else { throw RepositoryError.missingLogDataset }
        let key = datasetCacheKey(for: log, url: url)
        if let cached = datasetCache[key] { return cached }
        do {
            if let cached = try persistentDatasetCache.load(key: key, sourceURL: url) {
                datasetCache[key] = cached
                return cached
            }
            let result = try CSVLogParser.parseHPTunerCSVStreaming(fileURL: url)
            let parsed = result.dataset
            datasetCache[key] = parsed
            let sourceIdentity = log.sourceSHA256 ?? url.path
            try persistentDatasetCache.save(parsed, key: key, sourceIdentity: sourceIdentity)
            if result.diagnostics.malformedRows > 0 || result.diagnostics.invalidTimestampRows > 0 {
                persistenceIssues.append(.init(severity: .warning, domain: "csvIngestion", recordID: log.id.uuidString, message: "Imported with \(result.diagnostics.malformedRows) malformed and \(result.diagnostics.invalidTimestampRows) invalid-timestamp rows skipped."))
            }
            return parsed
        } catch {
            recordPersistenceIssue(domain: "datasetParse", recordID: log.id.uuidString, error: error)
            throw error
        }
    }

    /// Session-local cache keyed by immutable source identity plus parser/channel versions.
    /// This avoids reparsing the same large CSV repeatedly while ensuring a new engine version
    /// or changed source file cannot silently reuse stale derived data.
    private func datasetCacheKey(for log: ImportedLog, url: URL) -> String {
        let sourceIdentity = log.sourceSHA256 ?? ((try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date)?.timeIntervalSince1970.description ?? url.path)
        return [sourceIdentity, AnalysisEngineVersion.current.parser, AnalysisEngineVersion.current.channelResolver].joined(separator: "|")
    }

    func clearDatasetCache() { datasetCache.removeAll() }
    func clearPersistentDatasetCache() { try? persistentDatasetCache.removeAll() }

    private func logDirectory() throws -> URL {
        let root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let directory = root.appendingPathComponent("PredatorLab/Logs", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    enum RepositoryError: LocalizedError {
        case missingLogDataset
        var errorDescription: String? { "The original imported log dataset is no longer available." }
    }

    // MARK: - Preferences

    func savePreferences(from appState: AppState) throws {
        let preferences = AppPreferences(
            lastVehicleID: appState.currentVehicle?.id, lastBuildStateID: appState.currentBuildStateID,
            selectedTab: appState.selectedTab, currentPhase: appState.currentPhase, darkMode: appState.darkMode,
            textScale: Double(appState.textScale), colorblindMode: appState.colorblindMode,
            highContrastMode: appState.highContrastMode, gloveFriendlyMode: appState.gloveFriendlyMode,
            hapticFeedback: appState.hapticFeedback, screenLockWhileLogging: appState.screenLockWhileLogging
        )
        UserDefaults.standard.set(try JSONEncoder().encode(preferences), forKey: "app_preferences")
    }

    func loadPreferences() -> AppPreferences? {
        guard let data = UserDefaults.standard.data(forKey: "app_preferences") else { return nil }
        return try? JSONDecoder().decode(AppPreferences.self, from: data)
    }

    // MARK: - Validation Report Operations

    func save(validationReport: PersistedValidationReport) async throws {
        try entityStore.save(validationReport, id: validationReport.id, vehicleID: validationReport.vehicleID, kind: .validationReport)
    }

    func fetchValidationReports(forVehicle vehicleID: UUID) async throws -> [PersistedValidationReport] {
        let stored = try entityStore.fetchAll(PersistedValidationReport.self, kind: .validationReport, vehicleID: vehicleID)
        if !stored.isEmpty { return stored.sorted { $0.createdAt > $1.createdAt } }
        let decoder=JSONDecoder(); let ids=UserDefaults.standard.stringArray(forKey:"validationreport_ids") ?? []
        return ids.compactMap { id in
            guard let data=UserDefaults.standard.data(forKey:"validationreport_\(id)") else { return nil }
            do { return try decoder.decode(PersistedValidationReport.self,from:data) } catch { recordPersistenceIssue(domain: "validationReport", recordID: id, error: error); return nil }
        }.filter{$0.vehicleID==vehicleID}.sorted{$0.createdAt > $1.createdAt}
    }

    /// One-time migration of Rev13-and-earlier JSON records from UserDefaults into Core Data.
    /// Legacy keys are retained during the Rev14 compatibility window so rollback remains possible.
    func migrateLegacyEntityStorageIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "rev14_coredata_migration_complete") else { return }
        let decoder = JSONDecoder()
        func migrate<T: Codable>(_ type: T.Type, prefix: String, kind: DurableEntityKind, identity: (T) -> (UUID, UUID?)) {
            for rawID in defaults.stringArray(forKey: "\(prefix)_ids") ?? [] {
                guard let data = defaults.data(forKey: "\(prefix)_\(rawID)") else { continue }
                do {
                    let value = try decoder.decode(type, from: data); let ids = identity(value)
                    try entityStore.save(value, id: ids.0, vehicleID: ids.1, kind: kind)
                } catch { recordPersistenceIssue(domain: "legacyMigration.\(prefix)", recordID: rawID, error: error) }
            }
        }
        migrate(GT500Vehicle.self, prefix: "vehicle", kind: .vehicle) { ($0.id, $0.id) }
        migrate(Session.self, prefix: "session", kind: .session) { ($0.id, $0.vehicleID) }
        migrate(Investigation.self, prefix: "investigation", kind: .investigation) { ($0.id, $0.vehicleID) }
        migrate(ServiceRecord.self, prefix: "servicerecord", kind: .serviceRecord) { ($0.id, $0.vehicleID) }
        migrate(ImportedLog.self, prefix: "importedlog", kind: .importedLog) { ($0.id, $0.vehicleID) }
        migrate(PersistedValidationReport.self, prefix: "validationreport", kind: .validationReport) { ($0.id, $0.vehicleID) }
        if !persistenceIssues.contains(where: { $0.domain.hasPrefix("legacyMigration.") }) {
            defaults.set(true, forKey: "rev14_coredata_migration_complete")
        }
    }

    // MARK: - App State Operations

    func saveAppState(_ appState: AppState) async throws {
        try savePreferences(from: appState)
        if let vehicle = appState.currentVehicle {
            try await save(vehicle: vehicle)
        }
        if let investigation = appState.currentInvestigation {
            try await save(investigation: investigation)
        }
        for log in appState.allLogs {
            _ = try await save(importedLog: log)
        }
    }

    /// Reloads persisted vehicles at app launch. Restores `isOnboarded` so a returning user
    /// with a saved vehicle doesn't see onboarding again.
    func loadPersistedState(into appState: AppState) async {
        migrateLegacyEntityStorageIfNeeded()
        let vehicles: [GT500Vehicle]
        do { vehicles = try await fetchAllVehicles() }
        catch { recordPersistenceIssue(domain: "startup.vehicleLoad", error: error); vehicles = [] }
        let preferences = loadPreferences()
        appState.allVehicles = vehicles
        let selected = preferences?.lastVehicleID.flatMap { id in vehicles.first { $0.id == id } } ?? vehicles.first
        if let selected {
            appState.currentVehicle = selected
            appState.currentBuildStateID = preferences?.lastBuildStateID ?? selected.currentBuildStateID
            do { appState.allInvestigations = try await fetchAllInvestigations(forVehicle: selected.id) }
            catch { recordPersistenceIssue(domain: "startup.investigationLoad", recordID: selected.id.uuidString, error: error); appState.allInvestigations = [] }
            do { appState.allLogs = try await fetchAllImportedLogs(forVehicle: selected.id) }
            catch { recordPersistenceIssue(domain: "startup.logLoad", recordID: selected.id.uuidString, error: error); appState.allLogs = [] }
            appState.isOnboarded = true
        }
        if let preferences {
            appState.selectedTab = preferences.selectedTab
            appState.currentPhase = preferences.currentPhase
            appState.darkMode = preferences.darkMode
            appState.textScale = CGFloat(preferences.textScale)
            appState.colorblindMode = preferences.colorblindMode
            appState.highContrastMode = preferences.highContrastMode
            appState.gloveFriendlyMode = preferences.gloveFriendlyMode
            appState.hapticFeedback = preferences.hapticFeedback
            appState.screenLockWhileLogging = preferences.screenLockWhileLogging
        }
    }

    // MARK: - Data Management

    /// Permanently deletes every locally-stored vehicle, session, investigation, and service
    /// record. Does not touch in-memory AppState — callers should reset that themselves.
    func clearAllData() {
        let defaults = UserDefaults.standard
        for prefix in ["vehicle", "session", "investigation", "servicerecord", "importedlog", "validationreport"] {
            let ids = defaults.stringArray(forKey: "\(prefix)_ids") ?? []
            for id in ids {
                defaults.removeObject(forKey: "\(prefix)_\(id)")
            }
            defaults.removeObject(forKey: "\(prefix)_ids")
        }
        defaults.removeObject(forKey: "app_preferences")
        do { try entityStore.deleteAll() } catch { recordPersistenceIssue(domain: "coreDataClear", error: error) }
        if let directory = try? logDirectory() { try? FileManager.default.removeItem(at: directory) }
        if let directory = try? attachmentDirectory() { try? FileManager.default.removeItem(at: directory) }
        datasetCache.removeAll()
        try? persistentDatasetCache.removeAll()
    }

    /// Bundles the current vehicle plus its sessions/investigations into one JSON file for export.
    // MARK: - Portable Evidence Archive

    /// Creates a self-contained PredatorLab archive containing structured records plus the exact
    /// original CSV bytes. Derived caches are excluded and regenerated after import.
    func exportEvidenceArchive(appState: AppState) async throws -> URL {
        guard let vehicle = appState.currentVehicle else { throw EvidenceArchiveError.missingVehicle }
        let sessions = try await fetchAllSessions(forVehicle: vehicle.id)
        let investigations = try await fetchAllInvestigations(forVehicle: vehicle.id)
        let serviceRecords = try await fetchAllServiceRecords(forVehicle: vehicle.id)
        let logs = try await fetchAllImportedLogs(forVehicle: vehicle.id)
        let validationReports = try await fetchValidationReports(forVehicle: vehicle.id)
        let attachments = try await fetchEvidenceAttachments(forVehicle: vehicle.id)
        let postJobRCAs = try await fetchPostJobRCAs(forVehicle: vehicle.id)
        let rcaAttachmentLinks = try await fetchRCAAttachmentLinks(forVehicle: vehicle.id)
        let measurementClaims = try await fetchMeasurementClaims(vehicleID: vehicle.id)
        let measurementClaimRevisions = try await fetchMeasurementClaimRevisions(vehicleID: vehicle.id)
        let technicalTruth = try await fetchTechnicalTruth(vehicleID: vehicle.id)
        let technicalTruthRevisions = try await fetchTechnicalTruthRevisions(vehicleID: vehicle.id)
        let evidenceArtifacts = try await fetchEvidenceArtifacts(vehicleID: vehicle.id)
        let evidenceTruthReviews = try await fetchEvidenceTruthReviews(vehicleID: vehicle.id)
        let tuneMetadataV8 = TuneArchiveMetadataV8(calibrationGenomes: (try? await fetchCalibrationGenomes(vehicleID: vehicle.id)) ?? [], experiments: (try? await fetchTuneExperiments(vehicleID: vehicle.id)) ?? [], logContracts: (try? await fetchTuneLogContracts(vehicleID: vehicle.id)) ?? [], semanticReviews: (try? await fetchScannerSemanticReviews(vehicleID: vehicle.id)) ?? [])
        let tuneMetadataV9 = TuneArchiveMetadataV9Rev83(devices:(try? await fetchMPVI4DevicesRev83(vehicleID:vehicle.id)) ?? [], telemetrySessions:(try? await fetchTelemetrySessionsRev83(vehicleID:vehicle.id)) ?? [], acquisitionBenchmarks:(try? await fetchAcquisitionBenchmarksRev83(vehicleID:vehicle.id)) ?? [], configBContracts:(try? await fetchConfigBRev83(vehicleID:vehicle.id)) ?? [], hplCorrelations:(try? await fetchHPLCorrelationsRev83(vehicleID:vehicle.id)) ?? [], forensicCases:(try? await fetchForensicCasesRev83(vehicleID:vehicle.id)) ?? [])
        var sourceURLs: [UUID: URL] = [:]
        var logManifests: [StreamingEvidenceArchive.LogManifest] = []
        for log in logs {
            var metadata = log; metadata.fileURL = nil
            var byteCount: UInt64 = 0; var verifiedHash = log.sourceSHA256
            if let source = log.fileURL {
                sourceURLs[log.id] = source
                let attrs = try FileManager.default.attributesOfItem(atPath: source.path)
                byteCount = (attrs[.size] as? NSNumber)?.uint64Value ?? 0
                let actual = try EvidenceIntegrity.sha256(of: source)
                if let declared = log.sourceSHA256, let actual, declared != actual { throw EvidenceArchiveError.hashMismatch(log.filename) }
                verifiedHash = verifiedHash ?? actual
            }
            logManifests.append(.init(metadata: metadata, originalFilename: log.filename, declaredSHA256: verifiedHash, byteCount: byteCount))
        }
        var attachmentManifests: [StreamingEvidenceArchive.AttachmentManifest] = []
        for attachment in attachments {
            let source = try evidenceAttachmentURL(attachment)
            try EvidenceAttachmentStore.verify(sourceURL: source, metadata: attachment)
            sourceURLs[attachment.id] = source
            attachmentManifests.append(.init(metadata: attachment, declaredSHA256: attachment.sourceSHA256, byteCount: UInt64(attachment.byteCount)))
        }
        let manifest = StreamingEvidenceArchive.Manifest(format: PredatorLabEvidenceArchive.formatIdentifier, schemaVersion: 9, exportedAt: .now, appAnalysisVersion: .current, vehicle: vehicle, sessions: sessions, investigations: investigations, serviceRecords: serviceRecords, validationReports: validationReports, logs: logManifests, attachments: attachmentManifests, postJobRCAs: postJobRCAs, rcaAttachmentLinks: rcaAttachmentLinks, measurementClaims: measurementClaims, measurementClaimRevisions: measurementClaimRevisions, technicalTruth: technicalTruth, technicalTruthRevisions: technicalTruthRevisions, evidenceArtifacts: evidenceArtifacts, evidenceTruthReviews: evidenceTruthReviews, tuneMetadataV8: tuneMetadataV8, tuneMetadataV9: tuneMetadataV9)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PredatorLab-Evidence-\(vehicle.nickname.replacingOccurrences(of: " ", with: "-"))-\(Int(Date.now.timeIntervalSince1970))").appendingPathExtension("predatorlab")
        try StreamingEvidenceArchive.write(manifest: manifest, sourceURLs: sourceURLs, to: url)
        return url
    }

    /// Preflights a streaming archive without mutating durable state. This is the conflict-preview stage
    /// of stage → verify → preview → commit. Immutable evidence identity conflicts block replacement.
    func previewEvidenceArchiveImport(from url: URL, mergePolicy: ArchiveMergePolicy = .preserveExisting) async throws -> ArchiveImportPlan {
        guard StreamingEvidenceArchive.isStreamingContainer(url) else { throw EvidenceArchiveError.unsupportedFormat }
        let (manifest,tempFiles)=try StreamingEvidenceArchive.read(url)
        defer { for file in tempFiles.values { try? FileManager.default.removeItem(at:file) } }
        guard let vehicle=manifest.vehicle else { throw EvidenceArchiveError.missingVehicle }
        let safety=try ArchiveSafetyValidator.validate(manifest)
        var verified=0, warnings=safety.warnings
        for item in manifest.logs {
            guard let file=tempFiles[item.metadata.id] else { continue }
            if let declared=item.declaredSHA256, let actual=try EvidenceIntegrity.sha256(of:file) {
                guard actual==declared else { throw EvidenceArchiveError.hashMismatch(item.originalFilename) }
                verified += 1
            }
        }
        for item in manifest.attachments ?? [] {
            guard let file=tempFiles[item.metadata.id] else { warnings.append("Attachment bytes missing for \(item.metadata.filename)."); continue }
            guard let actual=try EvidenceIntegrity.sha256(of:file), actual == item.declaredSHA256 else { throw EvidenceArchiveError.hashMismatch(item.metadata.filename) }
            verified += 1
        }
        let existingVehicle=try await fetchVehicle(id:vehicle.id)
        let sessions=Set((try? await fetchAllSessions(forVehicle:vehicle.id))?.map(\.id) ?? [])
        let investigations=Set((try? await fetchAllInvestigations(forVehicle:vehicle.id))?.map(\.id) ?? [])
        let service=Set((try? await fetchAllServiceRecords(forVehicle:vehicle.id))?.map(\.id) ?? [])
        let validation=Set((try? await fetchValidationReports(forVehicle:vehicle.id))?.map(\.id) ?? [])
        let existingLogs=(try? await fetchAllImportedLogs(forVehicle:vehicle.id)) ?? []
        let byLog=Dictionary(uniqueKeysWithValues:existingLogs.map{($0.id,$0)})
        var items:[ArchiveConflictItem]=[]
        items.append(ArchiveImportPlanner.item(kind:"vehicle",id:vehicle.id,title:vehicle.nickname,exists:existingVehicle != nil))
        items += manifest.sessions.map { ArchiveImportPlanner.item(kind:"session",id:$0.id,title:"Session",exists:sessions.contains($0.id)) }
        items += manifest.investigations.map { ArchiveImportPlanner.item(kind:"investigation",id:$0.id,title:"Investigation",exists:investigations.contains($0.id)) }
        items += manifest.serviceRecords.map { ArchiveImportPlanner.item(kind:"service",id:$0.id,title:"Service record",exists:service.contains($0.id)) }
        items += manifest.validationReports.map { ArchiveImportPlanner.item(kind:"validation",id:$0.id,title:"Validation report",exists:validation.contains($0.id)) }
        let existingAttachments=Set((try? await fetchEvidenceAttachments(forVehicle:vehicle.id))?.map(\.id) ?? [])
        let existingRCAs=Set((try? await fetchPostJobRCAs(forVehicle:vehicle.id))?.map(\.id) ?? [])
        let existingRCALinks=Set((try? await fetchRCAAttachmentLinks(forVehicle:vehicle.id))?.map(\.id) ?? [])
        let existingMeasurementClaims=Set((try? await fetchMeasurementClaims(vehicleID:vehicle.id))?.map(\.id) ?? [])
        let existingMeasurementRevisions=Set((try? await fetchMeasurementClaimRevisions(vehicleID:vehicle.id))?.map(\.id) ?? [])
        let existingTechnicalTruth=Set((try? await fetchTechnicalTruth(vehicleID:vehicle.id))?.map(\.id) ?? [])
        let existingTechnicalTruthRevisions=Set((try? await fetchTechnicalTruthRevisions(vehicleID:vehicle.id))?.map(\.id) ?? [])
        let existingEvidenceArtifacts=Set((try? await fetchEvidenceArtifacts(vehicleID:vehicle.id))?.map(\.id) ?? [])
        let existingEvidenceReviews=Set((try? await fetchEvidenceTruthReviews(vehicleID:vehicle.id))?.map(\.id) ?? [])
        items += (manifest.attachments ?? []).map { ArchiveImportPlanner.item(kind:"attachment",id:$0.metadata.id,title:$0.metadata.filename,exists:existingAttachments.contains($0.metadata.id)) }
        items += (manifest.postJobRCAs ?? []).map { ArchiveImportPlanner.item(kind:"postJobRCA",id:$0.id,title:$0.symptom,exists:existingRCAs.contains($0.id)) }
        items += (manifest.rcaAttachmentLinks ?? []).map { ArchiveImportPlanner.item(kind:"rcaAttachmentLink",id:$0.id,title:$0.role,exists:existingRCALinks.contains($0.id)) }
        items += (manifest.measurementClaims ?? []).map { ArchiveImportPlanner.item(kind:"measurementClaim",id:$0.id,title:$0.label,exists:existingMeasurementClaims.contains($0.id)) }
        items += (manifest.measurementClaimRevisions ?? []).map { ArchiveImportPlanner.item(kind:"measurementClaimRevision",id:$0.id,title:$0.claimID,exists:existingMeasurementRevisions.contains($0.id)) }
        items += (manifest.technicalTruth ?? []).map { ArchiveImportPlanner.item(kind:"technicalTruth",id:$0.id,title:$0.truthID,exists:existingTechnicalTruth.contains($0.id)) }
        items += (manifest.technicalTruthRevisions ?? []).map { ArchiveImportPlanner.item(kind:"technicalTruthRevision",id:$0.id,title:$0.truthID,exists:existingTechnicalTruthRevisions.contains($0.id)) }
        items += (manifest.evidenceArtifacts ?? []).map { ArchiveImportPlanner.item(kind:"evidenceArtifact",id:$0.id,title:$0.requestID,exists:existingEvidenceArtifacts.contains($0.id)) }
        items += (manifest.evidenceTruthReviews ?? []).map { ArchiveImportPlanner.item(kind:"evidenceTruthReview",id:$0.id,title:$0.truthID,exists:existingEvidenceReviews.contains($0.id)) }
        items += manifest.logs.map { ArchiveImportPlanner.logItem($0,existing:byLog[$0.metadata.id],policy:mergePolicy) }
        if items.contains(where:{ $0.disposition == .evidenceIdentityConflict }) { warnings.append("At least one evidence UUID maps to different source bytes. PredatorLab preserves immutable source identity and will not silently reconcile that conflict.") }
        return .init(vehicleID:vehicle.id,policy:mergePolicy,items:items,evidenceBytes:safety.declaredEvidenceBytes,hashesVerified:verified,warnings:warnings)
    }

    /// Restores a portable archive into durable storage. Original source hashes are verified before
    /// any log is admitted. Derived caches are deliberately rebuilt later from the restored source.
    func importEvidenceArchive(from url: URL, mergePolicy: ArchiveMergePolicy = .preserveExisting) async throws -> ArchiveImportReport {
        if StreamingEvidenceArchive.isStreamingContainer(url) {
            let plan = try await previewEvidenceArchiveImport(from:url,mergePolicy:mergePolicy)
            guard plan.canCommit else { throw EvidenceArchiveError.identityConflict(plan.blockers.first?.title ?? "evidence") }
            let (manifest, tempFiles) = try StreamingEvidenceArchive.read(url)
            defer { for file in tempFiles.values { try? FileManager.default.removeItem(at: file) } }
            return try await importStreamingManifest(manifest, tempFiles: tempFiles, mergePolicy: mergePolicy)
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let archive = try decoder.decode(PredatorLabEvidenceArchive.self, from: data)
        guard archive.format == PredatorLabEvidenceArchive.formatIdentifier else { throw EvidenceArchiveError.unsupportedFormat }
        guard archive.schemaVersion <= PredatorLabEvidenceArchive.currentSchema else { throw EvidenceArchiveError.unsupportedSchema(archive.schemaVersion) }
        guard let vehicle = archive.vehicle else { throw EvidenceArchiveError.missingVehicle }

        // Verify all available evidence before mutating durable state.
        var verified = 0; var missing = 0; var warnings: [String] = []
        for archived in archive.logs {
            guard let bytes = archived.originalBytes else { missing += 1; warnings.append("Original CSV bytes missing for \(archived.originalFilename)."); continue }
            if let declared = archived.declaredSHA256 {
                let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("csv")
                try bytes.write(to: temp, options: .atomic); defer { try? FileManager.default.removeItem(at: temp) }
                if let actual = try EvidenceIntegrity.sha256(of: temp), actual != declared { throw EvidenceArchiveError.hashMismatch(archived.originalFilename) }
                verified += 1
            }
        }

        let existingVehicle = try await fetchVehicle(id: vehicle.id)
        let existingSessions = Set((try? await fetchAllSessions(forVehicle: vehicle.id))?.map(\.id) ?? [])
        let existingInvestigations = Set((try? await fetchAllInvestigations(forVehicle: vehicle.id))?.map(\.id) ?? [])
        let existingService = Set((try? await fetchAllServiceRecords(forVehicle: vehicle.id))?.map(\.id) ?? [])
        let existingValidation = Set((try? await fetchValidationReports(forVehicle: vehicle.id))?.map(\.id) ?? [])
        let existingLogs = Set((try? await fetchAllImportedLogs(forVehicle: vehicle.id))?.map(\.id) ?? [])
        var skipped = 0
        if existingVehicle == nil || mergePolicy == .replaceMatching { try await save(vehicle: vehicle) } else { skipped += 1; warnings.append("Vehicle already exists; existing vehicle record preserved.") }
        for value in archive.sessions { if mergePolicy == .preserveExisting && existingSessions.contains(value.id) { skipped += 1 } else { try await save(session: value) } }
        for value in archive.investigations { if mergePolicy == .preserveExisting && existingInvestigations.contains(value.id) { skipped += 1 } else { try await save(investigation: value) } }
        for value in archive.serviceRecords { if mergePolicy == .preserveExisting && existingService.contains(value.id) { skipped += 1 } else { try await save(serviceRecord: value) } }
        for value in archive.validationReports { if mergePolicy == .preserveExisting && existingValidation.contains(value.id) { skipped += 1 } else { try await save(validationReport: value) } }

        var importedLogs = 0; var reanalysis = 0
        for archived in archive.logs {
            if mergePolicy == .preserveExisting && existingLogs.contains(archived.metadata.id) { skipped += 1; continue }
            var metadata = archived.metadata
            if ReanalysisLineageEngine.needsCurrentRevision(metadata.analysisRevisions, legacyVersion: metadata.analysisEngineVersion) { reanalysis += 1 }
            if let bytes = archived.originalBytes {
                let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("csv")
                try bytes.write(to: temp, options: .atomic); defer { try? FileManager.default.removeItem(at: temp) }
                metadata = try await save(importedLog: metadata, sourceURL: temp, markAnalyzedWithCurrentEngine: false)
            } else {
                metadata.fileURL = nil
                _ = try await save(importedLog: metadata)
            }
            importedLogs += 1
        }
        datasetCache.removeAll(); try? persistentDatasetCache.removeAll()
        return ArchiveImportReport(vehicleID: vehicle.id, sessionsImported: archive.sessions.count, investigationsImported: archive.investigations.count, serviceRecordsImported: archive.serviceRecords.count, logsImported: importedLogs, validationReportsImported: archive.validationReports.count, hashesVerified: verified, logsMissingSourceBytes: missing, analysesNeedingReanalysis: reanalysis, recordsSkippedAsExisting: skipped, warnings: warnings)
    }

    private func importStreamingManifest(_ manifest: StreamingEvidenceArchive.Manifest, tempFiles: [UUID: URL], mergePolicy: ArchiveMergePolicy) async throws -> ArchiveImportReport {
        guard manifest.format == PredatorLabEvidenceArchive.formatIdentifier, let vehicle = manifest.vehicle else { throw EvidenceArchiveError.unsupportedFormat }
        var verified=0, missing=0, skipped=0, importedLogs=0, reanalysis=0; var warnings:[String]=[]
        // Verify every available source member before mutating structured records.
        for item in manifest.logs {
            guard let file=tempFiles[item.metadata.id] else { missing += 1; warnings.append("Original CSV bytes missing for \(item.originalFilename)."); continue }
            if let declared=item.declaredSHA256, let actual=try EvidenceIntegrity.sha256(of:file) { guard actual==declared else { throw EvidenceArchiveError.hashMismatch(item.originalFilename) }; verified += 1 }
        }
        for item in manifest.attachments ?? [] {
            guard let file=tempFiles[item.metadata.id] else { missing += 1; warnings.append("Attachment bytes missing for \(item.metadata.filename)."); continue }
            guard let actual=try EvidenceIntegrity.sha256(of:file), actual == item.declaredSHA256 else { throw EvidenceArchiveError.hashMismatch(item.metadata.filename) }
            verified += 1
        }
        let existingVehicle=try await fetchVehicle(id:vehicle.id)
        let existingSessions=Set((try? await fetchAllSessions(forVehicle:vehicle.id))?.map(\.id) ?? [])
        let existingInvestigations=Set((try? await fetchAllInvestigations(forVehicle:vehicle.id))?.map(\.id) ?? [])
        let existingService=Set((try? await fetchAllServiceRecords(forVehicle:vehicle.id))?.map(\.id) ?? [])
        let existingValidation=Set((try? await fetchValidationReports(forVehicle:vehicle.id))?.map(\.id) ?? [])
        let existingAttachments=Set((try? await fetchEvidenceAttachments(forVehicle:vehicle.id))?.map(\.id) ?? [])
        let existingRCAs=Set((try? await fetchPostJobRCAs(forVehicle:vehicle.id))?.map(\.id) ?? [])
        let existingRCALinks=Set((try? await fetchRCAAttachmentLinks(forVehicle:vehicle.id))?.map(\.id) ?? [])
        let existingMeasurementClaims=Set((try? await fetchMeasurementClaims(vehicleID:vehicle.id))?.map(\.id) ?? [])
        let existingMeasurementRevisions=Set((try? await fetchMeasurementClaimRevisions(vehicleID:vehicle.id))?.map(\.id) ?? [])
        let existingTechnicalTruth=Set((try? await fetchTechnicalTruth(vehicleID:vehicle.id))?.map(\.id) ?? [])
        let existingTechnicalTruthRevisions=Set((try? await fetchTechnicalTruthRevisions(vehicleID:vehicle.id))?.map(\.id) ?? [])
        let existingEvidenceArtifacts=Set((try? await fetchEvidenceArtifacts(vehicleID:vehicle.id))?.map(\.id) ?? [])
        let existingEvidenceReviews=Set((try? await fetchEvidenceTruthReviews(vehicleID:vehicle.id))?.map(\.id) ?? [])
        let existingLogs=Set((try? await fetchAllImportedLogs(forVehicle:vehicle.id))?.map(\.id) ?? [])
        if existingVehicle == nil || mergePolicy == .replaceMatching { try await save(vehicle:vehicle) } else { skipped += 1; warnings.append("Vehicle already exists; existing vehicle record preserved.") }
        for value in manifest.sessions { if mergePolicy == .preserveExisting && existingSessions.contains(value.id) { skipped += 1 } else { try await save(session:value) } }
        for value in manifest.investigations { if mergePolicy == .preserveExisting && existingInvestigations.contains(value.id) { skipped += 1 } else { try await save(investigation:value) } }
        for value in manifest.serviceRecords { if mergePolicy == .preserveExisting && existingService.contains(value.id) { skipped += 1 } else { try await save(serviceRecord:value) } }
        for value in manifest.validationReports { if mergePolicy == .preserveExisting && existingValidation.contains(value.id) { skipped += 1 } else { try await save(validationReport:value) } }
        for item in manifest.attachments ?? [] {
            if mergePolicy == .preserveExisting && existingAttachments.contains(item.metadata.id) { skipped += 1; continue }
            guard let source=tempFiles[item.metadata.id] else { continue }
            _ = try await save(evidenceAttachment:item.metadata, sourceURL:source)
        }
        for value in manifest.postJobRCAs ?? [] { if mergePolicy == .preserveExisting && existingRCAs.contains(value.id) { skipped += 1 } else { try await save(postJobRCA:value) } }
        for value in manifest.rcaAttachmentLinks ?? [] { if mergePolicy == .preserveExisting && existingRCALinks.contains(value.id) { skipped += 1 } else { try await save(rcaAttachmentLink:value, vehicleID:vehicle.id) } }
        for value in manifest.measurementClaims ?? [] { if mergePolicy == .preserveExisting && existingMeasurementClaims.contains(value.id) { skipped += 1 } else { try await save(measurementClaim:value) } }
        for value in manifest.measurementClaimRevisions ?? [] { if mergePolicy == .preserveExisting && existingMeasurementRevisions.contains(value.id) { skipped += 1 } else { try await save(measurementClaimRevision:value) } }
        for value in manifest.technicalTruth ?? [] { if mergePolicy == .preserveExisting && existingTechnicalTruth.contains(value.id) { skipped += 1 } else { try await save(technicalTruth:value) } }
        for value in manifest.technicalTruthRevisions ?? [] { if mergePolicy == .preserveExisting && existingTechnicalTruthRevisions.contains(value.id) { skipped += 1 } else { try await save(technicalTruthRevision:value) } }
        for value in manifest.evidenceArtifacts ?? [] { if mergePolicy == .preserveExisting && existingEvidenceArtifacts.contains(value.id) { skipped += 1 } else { try await save(evidenceArtifact:value) } }
        for value in manifest.evidenceTruthReviews ?? [] { if mergePolicy == .preserveExisting && existingEvidenceReviews.contains(value.id) { skipped += 1 } else { try await save(evidenceTruthReview:value) } }
        if let tune = manifest.tuneMetadataV8 {
            for value in tune.calibrationGenomes { try await save(calibrationGenome:value) }
            for value in tune.experiments { try await save(tuneExperiment:value) }
            for value in tune.logContracts { try await save(tuneLogContract:value, vehicleID:vehicle.id) }
            for value in tune.semanticReviews { try await save(scannerSemanticReview:value, vehicleID:vehicle.id) }
        }
        if let tune = manifest.tuneMetadataV9 {
            for value in tune.devices { try await save(mpvi4Device:value) }
            for value in tune.telemetrySessions { try await save(telemetrySession:value) }
            for value in tune.acquisitionBenchmarks { try await save(acquisitionBenchmark:value) }
            for value in tune.configBContracts { try await save(configB:value) }
            for value in tune.hplCorrelations { try await save(hplCorrelation:value) }
            for value in tune.forensicCases { try await save(forensicCase:value) }
        }
        for item in manifest.logs {
            if mergePolicy == .preserveExisting && existingLogs.contains(item.metadata.id) { skipped += 1; continue }
            var metadata=item.metadata
            if ReanalysisLineageEngine.needsCurrentRevision(metadata.analysisRevisions, legacyVersion:metadata.analysisEngineVersion) { reanalysis += 1 }
            if let source=tempFiles[metadata.id] { metadata=try await save(importedLog:metadata,sourceURL:source,markAnalyzedWithCurrentEngine:false) }
            else { metadata.fileURL=nil; _=try await save(importedLog:metadata) }
            importedLogs += 1
        }
        datasetCache.removeAll(); try? persistentDatasetCache.removeAll()
        return ArchiveImportReport(vehicleID:vehicle.id,sessionsImported:manifest.sessions.count,investigationsImported:manifest.investigations.count,serviceRecordsImported:manifest.serviceRecords.count,logsImported:importedLogs,validationReportsImported:manifest.validationReports.count,hashesVerified:verified,logsMissingSourceBytes:missing,analysesNeedingReanalysis:reanalysis,recordsSkippedAsExisting:skipped,warnings:warnings)
    }

    func exportData(appState: AppState) async throws -> URL {
        var sessions: [Session] = []
        var investigations: [Investigation] = []
        var serviceRecords: [ServiceRecord] = []
        var logs: [ImportedLog] = []
        var validationReports: [PersistedValidationReport] = []
        if let vehicleID = appState.currentVehicle?.id {
            sessions = try await fetchAllSessions(forVehicle: vehicleID)
            investigations = try await fetchAllInvestigations(forVehicle: vehicleID)
            serviceRecords = try await fetchAllServiceRecords(forVehicle: vehicleID)
            logs = try await fetchAllImportedLogs(forVehicle: vehicleID)
            validationReports = try await fetchValidationReports(forVehicle: vehicleID)
        }

        let manifest = logs.map { ExportLogIntegrity(logID: $0.id, filename: $0.filename, sourceSHA256: $0.sourceSHA256, analysisEngineVersion: $0.analysisEngineVersion) }
        let export = DataExport(
            schemaVersion: 3, exportedAt: .now, vehicle: appState.currentVehicle,
            sessions: sessions, investigations: investigations, serviceRecords: serviceRecords, logs: logs,
            validationReports: validationReports, logIntegrity: manifest
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(export)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PredatorLab-Export-\(Int(Date.now.timeIntervalSince1970))")
            .appendingPathExtension("json")
        try data.write(to: url, options: .atomic)
        return url
    }
}

private struct DataExport: Codable {
    var schemaVersion: Int
    var exportedAt: Date
    var vehicle: GT500Vehicle?
    var sessions: [Session]
    var investigations: [Investigation]
    var serviceRecords: [ServiceRecord]
    var logs: [ImportedLog]
    var validationReports: [PersistedValidationReport]
    var logIntegrity: [ExportLogIntegrity]
}

private struct ExportLogIntegrity: Codable {
    var logID: UUID
    var filename: String
    var sourceSHA256: String?
    var analysisEngineVersion: AnalysisEngineVersion?
}

// MARK: - Rev69 Tune-domain persistence
extension DataRepository {
    func save(calibrationGenome value: CalibrationFingerprint) async throws { try entityStore.save(value,id:value.id,vehicleID:value.vehicleID,kind:.calibrationGenome) }
    func fetchCalibrationGenomes(vehicleID:UUID) async throws -> [CalibrationFingerprint] { try entityStore.fetchAll(CalibrationFingerprint.self,kind:.calibrationGenome,vehicleID:vehicleID) }
    func save(tuneExperiment value:PersistedTuneExperiment) async throws { try entityStore.save(value,id:value.id,vehicleID:value.vehicleID,kind:.tuneExperiment) }
    func fetchTuneExperiments(vehicleID:UUID) async throws -> [PersistedTuneExperiment] { try entityStore.fetchAll(PersistedTuneExperiment.self,kind:.tuneExperiment,vehicleID:vehicleID) }
    func save(tuneLogContract value:TuneLogContract, vehicleID:UUID?) async throws { try entityStore.save(value,id:value.id,vehicleID:vehicleID,kind:.tuneLogContract) }
    func fetchTuneLogContracts(vehicleID:UUID) async throws -> [TuneLogContract] { try entityStore.fetchAll(TuneLogContract.self,kind:.tuneLogContract,vehicleID:vehicleID) }
    func save(scannerSemanticReview value:VCMScannerSemanticReview, vehicleID:UUID?) async throws { try entityStore.save(value,id:value.id,vehicleID:vehicleID,kind:.vcmScannerSemanticReview) }
    func fetchScannerSemanticReviews(vehicleID:UUID) async throws -> [VCMScannerSemanticReview] { try entityStore.fetchAll(VCMScannerSemanticReview.self,kind:.vcmScannerSemanticReview,vehicleID:vehicleID) }
    func save(highLoadReconstruction value:HighLoadPullReconstruction, id:UUID, vehicleID:UUID?) async throws { try entityStore.save(value,id:id,vehicleID:vehicleID,kind:.highLoadPullReconstruction) }
    func fetchHighLoadReconstructions(vehicleID:UUID) async throws -> [HighLoadPullReconstruction] { try entityStore.fetchAll(HighLoadPullReconstruction.self,kind:.highLoadPullReconstruction,vehicleID:vehicleID) }
    func save(experimentClosurePlan value:ExperimentClosurePlan, id:UUID, vehicleID:UUID?) async throws { try entityStore.save(value,id:id,vehicleID:vehicleID,kind:.experimentClosurePlan) }
    func fetchExperimentClosurePlans(vehicleID:UUID) async throws -> [ExperimentClosurePlan] { try entityStore.fetchAll(ExperimentClosurePlan.self,kind:.experimentClosurePlan,vehicleID:vehicleID) }

    func resolveTuneWorkspace(appState:AppState) async -> TuneWorkspaceSnapshot {
        guard let vehicleID=appState.currentVehicle?.id else { return TuneWorkspaceResolver.resolve(vehicleID:nil,buildRevisionID:appState.currentBuildStateID,calibrations:[],experiments:[],contracts:[],unresolvedDiagnosticBlockers:appState.currentInvestigation == nil ? [] : ["Active diagnostic investigation requires disposition"],acquisitionQuality:nil) }
        let c=(try? await fetchCalibrationGenomes(vehicleID:vehicleID)) ?? []
        let e=(try? await fetchTuneExperiments(vehicleID:vehicleID)) ?? []
        let l=(try? await fetchTuneLogContracts(vehicleID:vehicleID)) ?? []
        return TuneWorkspaceResolver.resolve(vehicleID:vehicleID,buildRevisionID:appState.currentBuildStateID,calibrations:c,experiments:e,contracts:l,unresolvedDiagnosticBlockers:appState.currentInvestigation == nil ? [] : ["Active diagnostic investigation requires disposition"],acquisitionQuality:nil)
    }
}

// MARK: - Rev83 production execution persistence
extension DataRepository {
    func save(mpvi4Device value:PersistedMPVI4DeviceSnapshotRev83) async throws { try entityStore.save(value,id:value.id,vehicleID:value.vehicleID,kind:.mpvi4DeviceSnapshot) }
    func fetchMPVI4DevicesRev83(vehicleID:UUID) async throws -> [PersistedMPVI4DeviceSnapshotRev83] { try entityStore.fetchAll(PersistedMPVI4DeviceSnapshotRev83.self,kind:.mpvi4DeviceSnapshot,vehicleID:vehicleID) }
    func save(telemetrySession value:PersistedTelemetrySessionRev83) async throws { try entityStore.save(value,id:value.id,vehicleID:value.vehicleID,kind:.mpvi4TelemetrySession) }
    func fetchTelemetrySessionsRev83(vehicleID:UUID) async throws -> [PersistedTelemetrySessionRev83] { try entityStore.fetchAll(PersistedTelemetrySessionRev83.self,kind:.mpvi4TelemetrySession,vehicleID:vehicleID) }
    func save(acquisitionBenchmark value:PersistedAcquisitionBenchmarkRev83) async throws { try entityStore.save(value,id:value.id,vehicleID:value.vehicleID,kind:.mpvi4AcquisitionBenchmark) }
    func fetchAcquisitionBenchmarksRev83(vehicleID:UUID) async throws -> [PersistedAcquisitionBenchmarkRev83] { try entityStore.fetchAll(PersistedAcquisitionBenchmarkRev83.self,kind:.mpvi4AcquisitionBenchmark,vehicleID:vehicleID) }
    func save(configB value:PersistedConfigBContractRev83) async throws { try entityStore.save(value,id:value.id,vehicleID:value.vehicleID,kind:.rev83ConfigBContract) }
    func fetchConfigBRev83(vehicleID:UUID) async throws -> [PersistedConfigBContractRev83] { try entityStore.fetchAll(PersistedConfigBContractRev83.self,kind:.rev83ConfigBContract,vehicleID:vehicleID) }
    func save(hplCorrelation value:PersistedHPLCorrelationRev83) async throws { try entityStore.save(value,id:value.id,vehicleID:value.vehicleID,kind:.rev83HPLCorrelation) }
    func fetchHPLCorrelationsRev83(vehicleID:UUID) async throws -> [PersistedHPLCorrelationRev83] { try entityStore.fetchAll(PersistedHPLCorrelationRev83.self,kind:.rev83HPLCorrelation,vehicleID:vehicleID) }
    func save(forensicCase value:PersistedForensicCaseRev83) async throws { try entityStore.save(value,id:value.id,vehicleID:value.vehicleID,kind:.rev83ForensicCase) }
    func fetchForensicCasesRev83(vehicleID:UUID) async throws -> [PersistedForensicCaseRev83] { try entityStore.fetchAll(PersistedForensicCaseRev83.self,kind:.rev83ForensicCase,vehicleID:vehicleID) }
}

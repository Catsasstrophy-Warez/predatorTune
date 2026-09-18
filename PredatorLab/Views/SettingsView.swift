// PredatorLab/Views/SettingsView.swift
// Vehicle management, session preferences, display/accessibility settings, and data
// export/clear. Display settings here are wired to real app-wide behavior in
// PredatorLabApp.swift (preferredColorScheme, dynamicTypeSize) — not just switches for show.

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataRepository: DataRepository

    @State private var showAddVehicle = false
    @State private var showClearConfirmation = false
    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var archiveImportPresented = false
    @State private var archiveImportStatus: String?
    @State private var recoverySnapshot = RecoveryCenterEngine.snapshot(journal: nil)

    var body: some View {
        NavigationStack {
            Form {
                vehicleSection
                sessionPreferencesSection
                displaySection
                persistenceHealthSection
                recoveryCenterSection
                buildHistorySection
                evidenceBoundarySection
                dataManagementSection
            }
            .plHardBottomEdge()
            .accessibilityIdentifier("settings.workspace")
            .navigationTitle("Settings")
            .tint(.plIgnition)
            .sheet(isPresented: $showAddVehicle) {
                AddVehicleSheet()
                    .environmentObject(appState)
                    .environmentObject(dataRepository)
            }
        }
    }


    private var persistenceHealthSection: some View {
        Section("Storage Health") {
            let health = dataRepository.persistenceHealth
            Label(health.summary, systemImage: health.hasErrors ? "exclamationmark.triangle.fill" : (health.issues.isEmpty ? "checkmark.circle.fill" : "exclamationmark.circle"))
            if !health.issues.isEmpty {
                ForEach(health.issues.suffix(5)) { issue in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(issue.domain).font(.caption.bold())
                        Text(issue.message).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Button("Clear Health Messages") { dataRepository.clearPersistenceHealth() }
            } else {
                Text("No persistence decode errors have been observed in this app session.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }



    private var recoveryCenterSection: some View {
        Section("Recovery Center") {
            Label(recoverySnapshot.title, systemImage: recoverySnapshot.isBlocking ? "exclamationmark.arrow.triangle.2.circlepath" : "checkmark.shield")
            Text(recoverySnapshot.detail).font(.caption).foregroundStyle(.secondary)
            if let journal = recoverySnapshot.journal {
                LabeledContent("Archive", value: journal.archiveName)
                LabeledContent("Phase", value: journal.phase.rawValue)
                LabeledContent("Recorded writes", value: "\(journal.committedRecordIDs.count)")
                if recoverySnapshot.action != .none {
                    Text("Recommended action: \(recoverySnapshot.action.rawValue)").font(.caption.bold())
                }
                if journal.phase == .committed || journal.phase == .rolledBack {
                    Button("Clear Completed Recovery Journal") { clearRecoveryJournal() }
                }
            }
        }
        .accessibilityIdentifier("settings.recoveryCenter")
        .task { loadRecoveryJournal() }
    }

    private var buildHistorySection: some View {
        Section("Vehicle Configuration History") {
            if let vehicle = appState.currentVehicle {
                NavigationLink { BuildHistoryTimelineView(vehicle: vehicle) } label: {
                    Label("Build Revision Timeline", systemImage: "clock.arrow.circlepath")
                }
                .accessibilityIdentifier("settings.buildHistory")
                Text("Historical logs remain bound to the build revision under which they were recorded.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func loadRecoveryJournal() {
        do { recoverySnapshot = RecoveryCenterEngine.snapshot(journal: try DurableArchiveJournalStore().load()) }
        catch { recoverySnapshot = .init(journal:nil,action:.none,title:"Recovery journal unreadable",detail:error.localizedDescription,isBlocking:true) }
    }
    private func clearRecoveryJournal() {
        do { try DurableArchiveJournalStore().clear(); loadRecoveryJournal() }
        catch { dataRepository.reportPersistenceFailure(domain:"archiveRecoveryJournal", error:error) }
    }

    private var evidenceBoundarySection: some View {
        Section("Safety & Evidence Boundary") {
            Text("PredatorLab organizes technical evidence, analyzes telemetry, ranks authored hypotheses, and recommends discriminating measurements.")
            Text("It does not certify a vehicle safe, prove causation from correlation, invent missing measurements, or convert unverified observations into OEM specifications.")
                .font(.caption).foregroundStyle(.secondary)
            Label("Logged measurement", systemImage:"waveform.path.ecg")
            Label("PredatorLab-derived interpretation", systemImage:"function")
            Label("Source-verified technical claim", systemImage:"checkmark.seal")
        }
        .accessibilityIdentifier("settings.evidenceBoundary")
    }

    // MARK: - Vehicle Management

    private var vehicleSection: some View {
        Section("Vehicle") {
            ForEach(appState.allVehicles) { vehicle in
                Button {
                    switchVehicle(to: vehicle)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vehicle.displayName)
                                .foregroundStyle(.primary)
                            if let build = vehicle.currentBuildState {
                                Text(build.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if vehicle.id == appState.currentVehicle?.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.plIgnition)
                        }
                    }
                }
            }

            Button {
                showAddVehicle = true
            } label: {
                Label("Add Vehicle", systemImage: "plus.circle")
            }

            if appState.currentVehicle != nil {
                TextField("Nickname", text: nicknameBinding)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.plSurfaceRaised)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.plStroke, lineWidth: 1)
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))

                TextField("Mileage", text: mileageBinding)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.plSurfaceRaised)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.plStroke, lineWidth: 1)
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
        }
    }

    private func switchVehicle(to vehicle: GT500Vehicle) {
        appState.currentVehicle = vehicle
        appState.currentBuildStateID = vehicle.currentBuildStateID
    }

    private func updateCurrentVehicle(_ transform: (inout GT500Vehicle) -> Void) {
        guard var vehicle = appState.currentVehicle else { return }
        transform(&vehicle)
        appState.currentVehicle = vehicle
        if let index = appState.allVehicles.firstIndex(where: { $0.id == vehicle.id }) {
            appState.allVehicles[index] = vehicle
        }
        Task { do { try await dataRepository.save(vehicle: vehicle) } catch { dataRepository.reportPersistenceFailure(domain: "vehicleSave", recordID: vehicle.id.uuidString, error: error) } }
    }

    private var nicknameBinding: Binding<String> {
        Binding(
            get: { appState.currentVehicle?.nickname ?? "" },
            set: { newValue in updateCurrentVehicle { $0.nickname = newValue } }
        )
    }

    private var mileageBinding: Binding<String> {
        Binding(
            get: { appState.currentVehicle?.mileage.map(String.init) ?? "" },
            set: { newValue in updateCurrentVehicle { $0.mileage = Int(newValue) } }
        )
    }

    // MARK: - Session Preferences

    private var sessionPreferencesSection: some View {
        Section("Session Preferences") {
            Toggle("Keep Screen On While Logging", isOn: $appState.screenLockWhileLogging)
                .tint(.plIgnition)
            Toggle("Haptic Feedback", isOn: $appState.hapticFeedback)
                .tint(.plIgnition)
        }
    }

    // MARK: - Display & Accessibility

    private var displaySection: some View {
        Section("Display & Accessibility") {
            Picker("Appearance", selection: darkModeBinding) {
                Text("System").tag(Optional<Bool>.none)
                Text("Light").tag(Optional(false))
                Text("Dark").tag(Optional(true))
            }
            .pickerStyle(.segmented)
            .tint(.plIgnition)

            VStack(alignment: .leading, spacing: 6) {
                Text("Text Size")
                Slider(value: $appState.textScale, in: 0.8...1.6, step: 0.1)
                    .tint(.plIgnition)
            }
            .padding(.vertical, 4)

            Toggle("Glove-Friendly Mode", isOn: $appState.gloveFriendlyMode)
                .tint(.plIgnition)
            Toggle("High Contrast", isOn: $appState.highContrastMode)
                .tint(.plIgnition)
            Toggle("Colorblind-Friendly Palette", isOn: $appState.colorblindMode)
                .tint(.plIgnition)
        }
    }

    private var darkModeBinding: Binding<Bool?> {
        Binding(
            get: { appState.darkMode },
            set: { appState.darkMode = $0 }
        )
    }

    // MARK: - Data Management

    private var dataManagementSection: some View {
        Section("Data Management") {
            Button {
                exportData()
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
            .accessibilityIdentifier("settings.exportData")

            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Share Exported File", systemImage: "square.and.arrow.up.circle")
                }
            }

            if let exportError {
                Text(exportError)
                    .font(.caption)
                    .foregroundStyle(Color.plCritical)
            }

            Button { archiveImportPresented = true } label: {
                Label("Import PredatorLab Evidence Archive", systemImage: "square.and.arrow.down")
            }
            .fileImporter(isPresented: $archiveImportPresented, allowedContentTypes: [.data], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    Task {
                        let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
                        do {
                            let report = try await dataRepository.importEvidenceArchive(from: url)
                            await dataRepository.loadPersistedState(into: appState)
                            archiveImportStatus = "Imported \(report.logsImported) logs, \(report.sessionsImported) sessions, and \(report.validationReportsImported) validation records. Verified \(report.hashesVerified) source hashes. \(report.analysesNeedingReanalysis) analyses should be reanalyzed with the current engine. \(report.recordsSkippedAsExisting) existing records were preserved."
                        } catch { archiveImportStatus = "Import failed: \(error.localizedDescription)" }
                    }
                case .failure(let error): archiveImportStatus = "Import failed: \(error.localizedDescription)"
                }
            }
            if let archiveImportStatus { Text(archiveImportStatus).font(.caption).foregroundStyle(.secondary) }

            Button(role: .destructive) {
                showClearConfirmation = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
                    .foregroundStyle(Color.plCritical)
            }
            .accessibilityIdentifier("settings.clearAllData")
            .confirmationDialog(
                "Clear all vehicles, sessions, and investigations? This cannot be undone.",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear Everything", role: .destructive) { clearAllData() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func exportData() {
        Task {
            do {
                exportURL = try await dataRepository.exportEvidenceArchive(appState: appState)
                exportError = nil
            } catch {
                exportError = error.localizedDescription
            }
        }
    }

    private func clearAllData() {
        dataRepository.clearAllData()
        appState.allVehicles = []
        appState.currentVehicle = nil
        appState.currentBuildStateID = nil
        appState.currentSession = nil
        appState.allInvestigations = []
        appState.currentInvestigation = nil
        appState.allLogs = []
        appState.isOnboarded = false
    }
}

// MARK: - Add Vehicle

private struct AddVehicleSheet: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataRepository: DataRepository
    @Environment(\.dismiss) private var dismiss

    @State private var nickname = ""
    @State private var year = 2020
    @State private var vin = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle") {
                    TextField("Nickname", text: $nickname)
                    Picker("Model Year", selection: $year) {
                        ForEach(GT500ModelYear.allCases) { modelYear in
                            Text("\(modelYear.rawValue)").tag(modelYear.rawValue)
                        }
                    }
                    TextField("VIN (optional)", text: $vin)
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.plIgnition)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(nickname.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        let vehicle = GT500Vehicle(
            nickname: nickname,
            modelYear: GT500ModelYear(rawValue: year) ?? .y2020,
            vin: vin.isEmpty ? nil : vin,
            fuelType: "93 AKI",
            buildStates: [VehicleBuildState(name: "Stock")]
        )
        Task {
            do { try await dataRepository.save(vehicle: vehicle) } catch { dataRepository.reportPersistenceFailure(domain: "vehicleSave", recordID: vehicle.id.uuidString, error: error) }
            appState.allVehicles.append(vehicle)
            appState.currentVehicle = vehicle
            appState.currentBuildStateID = vehicle.currentBuildStateID
            isSaving = false
            dismiss()
        }
    }
}

// PredatorLab/Views/GarageModeView.swift
// Garage Mode: the primary in-garage / on-dyno screen. Large touch targets (60pt+), high
// contrast, glove-friendly.

import SwiftUI
import Combine
import UIKit

struct GarageModeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataRepository: DataRepository

    @State private var showSessionForm = false
    @State private var showServiceLog = false
    @State private var elapsedTime: TimeInterval = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PLTrackHeader(eyebrow: "Garage Bay", title: "BUILD. SERVICE. VERIFY.", subtitle: "Your vehicle, active session, service work and evidence gates in one bay.", icon: "car.side.fill", accent: .plBoost)
                    if let vehicle = appState.currentVehicle {
                        VehicleStatusCardView(vehicle: vehicle, phase: appState.currentPhase)
                        PhaseProgressCard(phase: appState.currentPhase, gate: appState.gateFor(appState.currentPhase))
                    } else {
                        NoVehicleCard()
                    }

                    PLTrackSection(title: "Vehicle Systems", subtitle: "A visual gateway into the car. Map nodes are navigation, not live status.", icon: "point.3.connected.trianglepath.dotted", accent: .plBoost) {
                        NavigationLink { GT500DigitalTwinView() } label: { PLVehicleSystemMap(selected: nil).allowsHitTesting(false) }.buttonStyle(.plain)
                        NavigationLink { TrackWorkshopSystemsView() } label: {
                            Label("Open Systems Paddock", systemImage: "arrow.right.circle.fill")
                                .font(.plHeadline).foregroundStyle(.plBoost)
                        }.buttonStyle(.plain)
                    }

                    if appState.isLogging {
                        ActiveSessionCard(
                            session: appState.currentSession,
                            elapsed: elapsedTime,
                            eventCount: appState.sessionEvents.count
                        )
                    }

                    QuickActionsGrid(
                        isLogging: appState.isLogging,
                        vehiclePresent: appState.currentVehicle != nil,
                        onStartStop: handleStartStopTapped,
                        onDiagnoseR04: { openR04Investigation() },
                        onBrowseReference: { appState.selectedTab = MainTabView.AppTab.reference.rawValue },
                        onTrackService: { showServiceLog = true }
                    )
                }
                .padding(20)
            }
            .plHardBottomEdge()
            .plScreenBackground()
            .accessibilityIdentifier("garage.workspace")
            .navigationTitle("Garage")
            .sheet(isPresented: $showSessionForm) {
                SessionFormView { mode, location, notes, context in
                    appState.startSession(mode: mode, location: location, notes: notes, experimentContext: context)
                    showSessionForm = false
                }
            }
            .sheet(isPresented: $showServiceLog) {
                if let vehicle = appState.currentVehicle {
                    QuickServiceLogSheet(vehicleID: vehicle.id)
                        .environmentObject(dataRepository)
                }
            }
            .onReceive(timer) { _ in
                if appState.isLogging, let start = appState.sessionStartTime {
                    elapsedTime = Date.now.timeIntervalSince(start)
                }
            }
        }
    }

    private func handleStartStopTapped() {
        if appState.isLogging {
            appState.stopSession()
            elapsedTime = 0
            if let session = appState.currentSession {
                Task {
                    do { try await dataRepository.save(session: session) } catch { dataRepository.reportPersistenceFailure(domain: "sessionSave", recordID: session.id.uuidString, error: error) }
                }
            }
        } else {
            showSessionForm = true
        }
    }

    private func openR04Investigation() {
        // AnalysisModeView owns the actual investigation UI; Garage just hands off the request.
        appState.showR04Dialog = true
        appState.selectedTab = MainTabView.AppTab.analyze.rawValue
    }
}

// MARK: - Vehicle Status Card

private struct VehicleStatusCardView: View {
    let vehicle: GT500Vehicle
    let phase: TuningPhase

    var body: some View {
        PLCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vehicle.displayName)
                            .font(.plTitle)
                            .foregroundStyle(.plTextPrimary)
                        if let mileage = vehicle.mileage {
                            Text("\(mileage.formatted()) miles")
                                .font(.plBody)
                                .foregroundStyle(.plTextSecondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "car.rear")
                        .font(.system(size: 34))
                        .foregroundStyle(.plBoost)
                }

                Rectangle()
                    .fill(Color.plStroke)
                    .frame(height: 1)

                if let build = vehicle.currentBuildState {
                    HStack(spacing: 16) {
                        PLStatTile(label: "Build", value: build.name, accent: .plIgnition, icon: "gearshape.fill")
                        PLStatTile(label: "Blower", value: build.blower, accent: .plBoost, icon: "wind")
                        PLStatTile(label: "Injectors", value: build.injectors, accent: .plWarning, icon: "drop.fill")
                    }
                }

                PLSectionHeader(title: "Phase", systemImage: "flag.checkered", accent: .plIgnition)
                Text("\(phase.shortName) — \(phase.title)")
                    .font(.plHeadline)
                    .foregroundStyle(.plTextPrimary)
            }
        }
    }
}

private struct NoVehicleCard: View {
    var body: some View {
        PLCard(padding: 24) {
            VStack(spacing: 12) {
                Image(systemName: "car.badge.exclamationmark")
                    .font(.system(size: 40))
                    .foregroundStyle(.plWarning)
                Text("No vehicle set up yet")
                    .font(.plHeadline)
                    .foregroundStyle(.plTextPrimary)
                Text("Complete onboarding to add your GT500.")
                    .font(.plBody)
                    .foregroundStyle(.plTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Phase Progress Card

private struct PhaseProgressCard: View {
    let phase: TuningPhase
    let gate: CalibrationGate?

    private var progress: Double {
        Double(phase.rawValue + 1) / Double(TuningPhase.allCases.count)
    }

    var body: some View {
        PLCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                PLSectionHeader(title: "Tuning Progress", systemImage: "gauge.with.dots.needle.50percent", accent: .plBoost)

                HStack(alignment: .top, spacing: 20) {
                    PLGaugeRing(
                        progress: progress,
                        lineWidth: 10,
                        accent: .plIgnition,
                        label: phase.shortName,
                        value: "\(Int((progress * 100).rounded()))%"
                    )
                    .frame(width: 92, height: 92)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(phase.description)
                            .font(.plBody)
                            .foregroundStyle(.plTextSecondary)

                        if let gate {
                            HStack {
                                Image(systemName: gate.isSatisfied ? "checkmark.seal.fill" : "lock.fill")
                                    .foregroundStyle(gate.isSatisfied ? .plSuccess : .plWarning)
                                Text(gate.title)
                                    .font(.plHeadline)
                                    .foregroundStyle(.plTextPrimary)
                            }
                        }
                    }
                }

                if let gate {
                    Rectangle()
                        .fill(Color.plStroke)
                        .frame(height: 1)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(gate.requirements, id: \.self) { requirement in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 5))
                                    .foregroundStyle(.plTextSecondary)
                                    .padding(.top, 6)
                                Text(requirement)
                                    .font(.plBody)
                                    .foregroundStyle(.plTextPrimary)
                            }
                        }
                    }

                    if !gate.isSatisfied, let reason = gate.blockingReason {
                        Text(reason)
                            .font(.plCaption)
                            .foregroundStyle(.plWarning)
                            .padding(.top, 2)
                    }
                }
            }
        }
    }
}

// MARK: - Active Session Card

private struct ActiveSessionCard: View {
    let session: Session?
    let elapsed: TimeInterval
    let eventCount: Int

    private var elapsedString: String {
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        PLCard(padding: 20) {
            VStack(spacing: 10) {
                HStack {
                    Circle()
                        .fill(Color.plCritical)
                        .frame(width: 10, height: 10)
                    Text(session?.mode.rawValue ?? "Logging")
                        .font(.plHeadline)
                        .foregroundStyle(.plTextPrimary)
                    Spacer()
                    Text("\(eventCount) event\(eventCount == 1 ? "" : "s")")
                        .font(.plBody)
                        .foregroundStyle(.plTextSecondary)
                }

                Text(elapsedString)
                    .font(.plGauge(48))
                    .foregroundStyle(.plCritical)
                    .monospacedDigit()
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.plCritical.opacity(0.5), lineWidth: 1.5)
        )
    }
}

// MARK: - Quick Actions

private struct QuickActionsGrid: View {
    let isLogging: Bool
    let vehiclePresent: Bool
    let onStartStop: () -> Void
    let onDiagnoseR04: () -> Void
    let onBrowseReference: () -> Void
    let onTrackService: () -> Void

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            GarageActionButton(
                title: isLogging ? "STOP\nLOGGING" : "START\nLOGGING",
                systemImage: isLogging ? "stop.circle.fill" : "record.circle.fill",
                tint: isLogging ? .plCritical : .plSuccess,
                isDisabled: !vehiclePresent,
                action: onStartStop
            )
            GarageActionButton(
                title: "Diagnose\nR04",
                systemImage: "magnifyingglass.circle.fill",
                tint: .plIgnition,
                action: onDiagnoseR04
            )
            GarageActionButton(
                title: "Browse\nReference",
                systemImage: "books.vertical.fill",
                tint: .plBoost,
                action: onBrowseReference
            )
            GarageActionButton(
                title: "Track\nService",
                systemImage: "wrench.and.screwdriver.fill",
                tint: Color(red: 0.62, green: 0.42, blue: 0.98),
                isDisabled: !vehiclePresent,
                action: onTrackService
            )
        }
    }
}

/// Reusable glove-friendly button: 60pt+ minimum height, high-contrast fill, haptic on tap.
private struct GarageActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 30))
                Text(title)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(minHeight: 100)
        }
        .buttonStyle(.plPrimary(accent: isDisabled ? Color.gray : tint))
        .disabled(isDisabled)
    }
}

// MARK: - Quick Service Log

private struct QuickServiceLogSheet: View {
    let vehicleID: UUID

    @EnvironmentObject var dataRepository: DataRepository
    @Environment(\.dismiss) private var dismiss

    @State private var procedure = ""
    @State private var mileage = ""
    @State private var notes = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Procedure (e.g. Oil Change)", text: $procedure)
                    TextField("Mileage", text: $mileage)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Service Performed")
                }
                Section {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }
            }
            .tint(.plIgnition)
            .navigationTitle("Log Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .disabled(procedure.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        let record = ServiceRecord(
            vehicleID: vehicleID,
            mileage: Int(mileage) ?? 0,
            procedure: procedure,
            notes: notes
        )
        Task {
            do { try await dataRepository.save(serviceRecord: record) } catch { dataRepository.reportPersistenceFailure(domain: "serviceSave", recordID: record.id.uuidString, error: error) }
            isSaving = false
            dismiss()
        }
    }
}

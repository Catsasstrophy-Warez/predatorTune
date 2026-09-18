// PredatorLab/PredatorLabApp.swift
// Main app entry point for Predator Lab v1.0 MVP

import SwiftUI
import UIKit

@main
struct PredatorLabApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var dataRepository = DataRepository()
    @Environment(\.scenePhase) var scenePhase
    @State private var isLoadingPersistedState = true

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoadingPersistedState {
                    PLLoadingCard(title: "Loading Predator Lab", message: "Restoring your vehicle and evidence workspace")
                        .padding()
                        .plScreenBackground()
                } else if appState.isOnboarded {
                    MainTabView()
                        .environmentObject(appState)
                        .environmentObject(dataRepository)
                } else {
                    OnboardingView()
                        .environmentObject(appState)
                        .environmentObject(dataRepository)
                }
            }
            .task {
                if ProcessInfo.processInfo.arguments.contains("-UITestReset") {
                    // Keep UI tests deterministic without affecting a user's device unless
                    // the explicit test-only launch argument is present.
                    dataRepository.clearAllData()
                }
                await dataRepository.loadPersistedState(into: appState)
                if ProcessInfo.processInfo.arguments.contains("-DiagnosticSkipOnboarding") {
                    // Diagnostic-only bypass to reach Garage via a plain `simctl launch`
                    // (no XCUITest/accessibility automation attached), to isolate whether a
                    // visual artifact is real app rendering or specific to automated driving.
                    let vehicle = GT500Vehicle(nickname: "Diagnostic GT500", modelYear: .y2020, buildStates: [VehicleBuildState(name: "Stock")])
                    appState.allVehicles = [vehicle]
                    appState.currentVehicle = vehicle
                    appState.currentBuildStateID = vehicle.currentBuildStateID
                    appState.isOnboarded = true
                }
                isLoadingPersistedState = false
            }
            .preferredColorScheme(preferredColorScheme(for: appState.darkMode))
            .dynamicTypeSize(ProcessInfo.processInfo.arguments.contains("-UITestLargeText") ? .xxxLarge : dynamicTypeSize(for: appState.textScale))
            .onChange(of: appState.isLogging) { logging in
                UIApplication.shared.isIdleTimerDisabled = logging && appState.screenLockWhileLogging
            }
            .onChange(of: appState.screenLockWhileLogging) { enabled in
                UIApplication.shared.isIdleTimerDisabled = appState.isLogging && enabled
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                Task {
                    do { try await dataRepository.saveAppState(appState) }
                    catch { dataRepository.reportPersistenceFailure(domain: "appStateBackgroundSave", error: error) }
                }
            }
        }
    }

    private func preferredColorScheme(for darkMode: Bool?) -> ColorScheme? {
        switch darkMode {
        case .some(true): return .dark
        case .some(false): return .light
        case .none: return nil
        }
    }

    private func dynamicTypeSize(for scale: CGFloat) -> DynamicTypeSize {
        switch scale {
        case ..<0.9: return .small
        case 0.9..<1.05: return .medium
        case 1.05..<1.2: return .large
        case 1.2..<1.35: return .xLarge
        case 1.35..<1.5: return .xxLarge
        default: return .xxxLarge
        }
    }
}

// MARK: - Main Tab Navigation

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    enum AppTab: Int {
        // Existing raw values stay stable for persisted preferences and cross-view handoffs.
        case garage = 0
        case tune = 1
        case analyze = 2
        case reference = 3
        case settings = 4
        case home = 5
        case more = 6
    }

    private var selectedTab: Binding<AppTab> {
        Binding(
            get: {
                let requested = AppTab(rawValue: appState.selectedTab) ?? .home
                // Reference and Settings are now reached through More, but legacy persisted
                // selections remain valid and land users in the new navigation hub.
                return (requested == .reference || requested == .settings) ? .more : requested
            },
            set: { appState.selectedTab = $0.rawValue }
        )
    }

    var body: some View {
        ZStack {
            TabView(selection: selectedTab) {
                RaceTrackHomeView()
                    .tag(AppTab.home)
                    .tabItem { Label("Home", systemImage: "flag.checkered") }

                GarageModeView()
                    .tag(AppTab.garage)
                    .tabItem { Label("Garage", systemImage: "car.side.fill") }

                AnalysisModeView()
                    .tag(AppTab.analyze)
                    .tabItem { Label("Analyze", systemImage: "waveform.path.ecg") }

                TuningModeView()
                    .tag(AppTab.tune)
                    .tabItem { Label("Tune", systemImage: "gauge.with.dots.needle.67percent") }

                MoreHubView()
                    .tag(AppTab.more)
                    .tabItem { Label("More", systemImage: "square.grid.2x2.fill") }
            }
            .tint(.plBoost)
            .toolbarBackground(Color.plSurface.opacity(0.98), for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)

            VStack(spacing: 0) {
                Rectangle().fill(LinearGradient(colors: [.clear, .plBoost, .clear], startPoint: .leading, endPoint: .trailing)).frame(height: 1).opacity(0.55)
                HStack { Spacer(); SyncStatusIndicator(syncStatus: appState.syncStatus).padding(.top, 6).padding(.trailing, 8) }
                Spacer()
            }
        }
    }
}

// MARK: - Sync Status Indicator

struct SyncStatusIndicator: View {
    @State private var showSyncStatus = false
    let syncStatus: AppState.SyncStatus

    var body: some View {
        Menu {
            Text("Sync Status")
            Divider()
            switch syncStatus {
            case .localSaved:
                Text("✓ Saved locally")
            case .saving:
                Text("Saving...")
            case .error(let message):
                Text("⚠ Save Error: \(message)")
            case .unavailable:
                Text("Local storage unavailable")
            }
        } label: {
            Image(systemName: syncStatusIcon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(syncStatusColor)
                .padding(8)
                .background(Color.plSurface)
                .clipShape(Circle())
                .overlay(
                    Circle().strokeBorder(Color.plStroke, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
        }
    }

    var syncStatusIcon: String {
        switch syncStatus {
        case .localSaved: return "internaldrive.fill"
        case .saving: return "internaldrive"
        case .error: return "exclamationmark.triangle.fill"
        case .unavailable: return "internaldrive.fill.badge.xmark"
        }
    }

    var syncStatusColor: Color {
        switch syncStatus {
        case .localSaved: return .plSuccess
        case .saving: return .plBoost
        case .error: return .plCritical
        case .unavailable: return .plWarning
        }
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataRepository: DataRepository
    @State private var step = 0
    @State private var vehicleNickname = ""
    @State private var vehicleYear = 2020
    @State private var vehicleVIN = ""

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Welcome to Predator Lab")
                        .font(.plTitle)
                        .foregroundStyle(.plTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("GT500-Specific Engineering Environment")
                        .font(.plBody)
                        .foregroundStyle(.plTextSecondary)
                }
                .padding(.top, 12)

                VStack(spacing: 16) {
                    if step == 0 {
                        OnboardingStep1()
                    } else if step == 1 {
                        OnboardingVehicleSetup(
                            nickname: $vehicleNickname,
                            year: $vehicleYear,
                            vin: $vehicleVIN
                        )
                    } else {
                        OnboardingStep3()
                    }
                }

                Spacer()

                HStack {
                    if step > 0 {
                        Button("Back") {
                            step -= 1
                        }
                        .buttonStyle(.plPrimary(accent: .plSurfaceRaised))
                        .frame(maxWidth: 110)
                    }

                    Spacer()

                    Button(step < 2 ? "Next" : "Get Started") {
                        if step < 2 {
                            step += 1
                        } else {
                            Task {
                                do { try await completeOnboarding() }
                                catch { dataRepository.reportPersistenceFailure(domain: "onboardingSave", error: error) }
                            }
                        }
                    }
                    .buttonStyle(.plPrimary)
                    .frame(maxWidth: step > 0 ? 180 : .infinity)
                    .disabled(step == 1 && vehicleNickname.isEmpty)
                    .opacity(step == 1 && vehicleNickname.isEmpty ? 0.5 : 1)
                    .accessibilityIdentifier(step < 2 ? "onboarding.next" : "onboarding.getStarted")
                }
                .padding()
            }
            .padding()
        }
        .plScreenBackground()
    }

    private func completeOnboarding() async throws {
        let vehicle = GT500Vehicle(
            nickname: vehicleNickname,
            modelYear: GT500ModelYear(rawValue: vehicleYear) ?? .y2020,
            vin: vehicleVIN.isEmpty ? nil : vehicleVIN,
            fuelType: "93 AKI",
            buildStates: [VehicleBuildState(name: "Stock")]
        )

        try await dataRepository.save(vehicle: vehicle)
        appState.allVehicles.append(vehicle)
        appState.currentVehicle = vehicle
        appState.currentBuildStateID = vehicle.currentBuildStateID
        appState.isOnboarded = true
    }
}

struct OnboardingStep1: View {
    private let features: [(String, String, Color)] = [
        ("Evidence-Based Diagnostics", "checkmark.seal.fill", .plIgnition),
        ("GT500-Specific Reference", "books.vertical.fill", .plBoost),
        ("Complete Session Logging", "record.circle.fill", .plIgnition),
        ("R04 Investigation Engine", "magnifyingglass", .plBoost),
        ("Offline-First Design", "wifi.slash", .plIgnition)
    ]

    var body: some View {
        PLCard {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(features, id: \.0) { feature in
                    Label {
                        Text(feature.0)
                            .font(.plBody)
                            .foregroundStyle(.plTextPrimary)
                    } icon: {
                        Image(systemName: feature.1)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(feature.2)
                            .frame(width: 22)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct OnboardingVehicleSetup: View {
    @Binding var nickname: String
    @Binding var year: Int
    @Binding var vin: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Let's set up your GT500")
                .font(.plHeadline)
                .foregroundStyle(.plTextPrimary)

            PLCard {
                VStack(spacing: 14) {
                    TextField("Vehicle Nickname", text: $nickname)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 4)
                        .accessibilityIdentifier("onboarding.vehicleNickname")

                    Picker("Model Year", selection: $year) {
                        ForEach(2020...2022, id: \.self) { y in
                            Text("\(y)").tag(y)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(.plIgnition)

                    TextField("VIN (optional)", text: $vin)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 4)
                        .accessibilityIdentifier("onboarding.vin")
                }
            }
        }
    }
}

struct OnboardingStep3: View {
    var body: some View {
        PLCard {
            VStack(spacing: 12) {
                Image(systemName: "checkered.flag")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.plIgnition)

                Text("You're ready to start!")
                    .font(.plHeadline)
                    .foregroundStyle(.plTextPrimary)

                Text("Import HP Tuners logs, run investigations, track maintenance, and reference technical specs.")
                    .font(.plBody)
                    .foregroundStyle(.plTextSecondary)
                    .multilineTextAlignment(.center)
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Label("Start with a baseline log", systemImage: "1.circle.fill")
                    Label("Review acquisition quality before conclusions", systemImage: "2.circle.fill")
                    Label("Treat recommendations as evidence plans, not safety certification", systemImage: "3.circle.fill")
                }
                .font(.plCaption)
                .foregroundStyle(.plTextSecondary)
            }
        }
    }
}

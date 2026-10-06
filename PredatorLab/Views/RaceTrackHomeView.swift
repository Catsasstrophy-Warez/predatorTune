import SwiftUI

/// Home cockpit: who the car is, where the build stands, the next useful action, and
/// one-tap routes into every workflow. Every destination here is also owned by a tab;
/// Home only shortcuts to it.
struct RaceTrackHomeView: View {
    @EnvironmentObject private var appState: AppState

    private let routeColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private let systemColumns = [GridItem(.adaptive(minimum: 150), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    hero
                    statusStrip
                    nextStep
                    routes
                    pitLane
                    exploreTheCar
                    evidenceBoundary
                }
                .padding(16)
            }
            .plHardBottomEdge()
            .plScreenBackground()
            .navigationTitle("PredatorLab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SyncStatusIndicator(syncStatus: appState.syncStatus)
                }
            }
        }
        .accessibilityIdentifier("home.racetrack")
    }

    // MARK: Hero

    private var phaseProgress: Double {
        Double(appState.currentPhase.rawValue + 1) / Double(TuningPhase.allCases.count)
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("KNOW THE CAR.\nMASTER THE DATA.")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .italic()
                    .foregroundStyle(.plTextPrimary)
                if let vehicle = appState.currentVehicle {
                    Label(vehicle.displayName, systemImage: "car.side.fill")
                        .font(.plHeadline)
                        .foregroundStyle(.plTextPrimary)
                    if let build = vehicle.currentBuildState {
                        Text("Build: \(build.name)")
                            .font(.plCaption)
                            .foregroundStyle(.plTextSecondary)
                    }
                } else {
                    Button { appState.open(.garage) } label: {
                        Label("Set up your GT500", systemImage: "car.badge.plus")
                            .font(.plBody)
                            .foregroundStyle(.plWarning)
                    }
                    .buttonStyle(.plain)
                }
                Text("Acquire → Verify → Investigate → Experiment → Validate")
                    .font(.plCaption)
                    .foregroundStyle(.plBoost)
            }
            Spacer(minLength: 0)
            PLGaugeRing(
                progress: phaseProgress,
                lineWidth: 9,
                accent: .plIgnition,
                label: appState.currentPhase.shortName,
                value: "\(Int((phaseProgress * 100).rounded()))%"
            )
            .frame(width: 92, height: 92)
            .accessibilityLabel("Tuning phase \(appState.currentPhase.shortName), \(Int((phaseProgress * 100).rounded())) percent")
        }
        .padding(18)
        .background(
            LinearGradient(colors: [.plSurfaceRaised, .plSurface], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "flag.checkered.2.crossed")
                .font(.system(size: 64, weight: .black))
                .foregroundStyle(.plBoost.opacity(0.08))
                .padding(10)
                .accessibilityHidden(true)
        }
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.plBoost.opacity(0.45)))
    }

    // MARK: Status

    private var statusStrip: some View {
        HStack(spacing: 8) {
            HomeStatusPill(icon: "car.side.fill", title: "Vehicle", value: appState.currentVehicle == nil ? "SETUP" : "READY", accent: appState.currentVehicle == nil ? .plWarning : .plSuccess)
            HomeStatusPill(icon: "record.circle", title: "Session", value: appState.isLogging ? "LOGGING" : "IDLE", accent: appState.isLogging ? .plCritical : .plBoost)
            HomeStatusPill(icon: "doc.text.magnifyingglass", title: "Logs", value: "\(appState.allLogs.count)", accent: .plSuccess)
            HomeStatusPill(icon: "flag.checkered", title: "Phase", value: appState.currentPhase.shortName, accent: .plIgnition)
        }
    }

    // MARK: Next step

    @ViewBuilder
    private var nextStep: some View {
        if appState.isLogging {
            nextStepCard(icon: "record.circle.fill", accent: .plCritical, title: "Session recording", detail: "A logging session is running. Stop it in Garage when the run is done.", action: "Go to Garage") { appState.open(.garage) }
        } else if appState.currentVehicle == nil {
            nextStepCard(icon: "car.badge.plus", accent: .plWarning, title: "Add your vehicle", detail: "Evidence, gates and baselines are tracked per vehicle and build.", action: "Open Garage") { appState.open(.garage) }
        } else if appState.allLogs.isEmpty {
            nextStepCard(icon: "square.and.arrow.down", accent: .plBoost, title: "Import a baseline log", detail: "Start with an HP Tuners CSV of a known-good run so later changes have something to compare against.", action: "Import log") { appState.openAnalyze(.logs) }
        } else if let gate = appState.gateFor(appState.currentPhase), !gate.isSatisfied {
            nextStepCard(icon: "lock.fill", accent: .plWarning, title: gate.title, detail: gate.blockingReason ?? "Satisfy this gate before advancing the tuning phase.", action: "Review in Tune") { appState.open(.tune) }
        } else {
            nextStepCard(icon: "scope", accent: .plSuccess, title: "Investigate your latest log", detail: "Open the timeline, follow events and check acquisition quality before drawing conclusions.", action: "Open logs") { appState.openAnalyze(.logs) }
        }
    }

    private func nextStepCard(icon: String, accent: Color, title: String, detail: String, action: String, perform: @escaping () -> Void) -> some View {
        PLCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                PLSectionHeader(title: "Next Step", systemImage: "arrow.forward.circle.fill", accent: accent)
                HStack(alignment: .top, spacing: 12) {
                    PLIconTile(icon: icon, accent: accent, size: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title).font(.plHeadline).foregroundStyle(.plTextPrimary)
                        Text(detail).font(.plCaption).foregroundStyle(.plTextSecondary)
                    }
                }
                Button(action: perform) { Text(action) }
                    .buttonStyle(PLPrimaryButtonStyle(accent: accent, minHeight: 44))
                    .accessibilityIdentifier("home.nextStep")
            }
        }
    }

    // MARK: Routes

    private var routes: some View {
        LazyVGrid(columns: routeColumns, spacing: 12) {
            Button { appState.open(.garage) } label: {
                PLRouteTile(title: "GARAGE", subtitle: "Vehicle, build, sessions, service", icon: "car.side.fill", accent: .plBoost)
            }.buttonStyle(.plain)
            Button { appState.openAnalyze(.logs) } label: {
                PLRouteTile(title: "ANALYZE", subtitle: "Logs, timelines, forensics", icon: "waveform.path.ecg", accent: .plSuccess)
            }.buttonStyle(.plain)
            NavigationLink { DiagnosticsHubView() } label: {
                PLRouteTile(title: "DIAGNOSE", subtitle: "Find it. Prove it. Fix it.", icon: "stethoscope", accent: .plCritical)
            }.buttonStyle(.plain)
            Button { appState.open(.tune) } label: {
                PLRouteTile(title: "TUNE", subtitle: "Calibrate with evidence", icon: "gauge.with.dots.needle.67percent", accent: .plIgnition)
            }.buttonStyle(.plain)
        }
    }

    // MARK: Pit lane

    private var pitLane: some View {
        PLHubSection(title: "Pit Lane", icon: "bolt.fill", accent: .plIgnition) {
            NavigationLink { PredatorLabWorkstationRev85() } label: {
                PLHubRow(title: "Forensic Workstation", subtitle: "Pull Lab, evidence, calibration, topology, replay", icon: "scope", accent: .plBoost)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.workstation")
            NavigationLink { TelemetryRenderingView() } label: {
                PLHubRow(title: "3D Telemetry Cockpit", subtitle: "RealityKit gauges and track path, Metal waveforms", icon: "cube.transparent", accent: .plIgnition)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.telemetryCockpit")
            NavigationLink { GoldenCorpusGuidedInvestigationViewRev160().navigationTitle("Guided Investigation") } label: {
                PLHubRow(title: "Guided Investigation", subtitle: "Learn the evidence workflow on the bundled reference log", icon: "graduationcap.fill", accent: .plSuccess)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.guidedInvestigation")
        }
    }

    // MARK: Explore

    private var exploreTheCar: some View {
        VStack(alignment: .leading, spacing: 10) {
            PLSectionHeader(title: "Explore the Car", systemImage: "point.3.connected.trianglepath.dotted", accent: .plBoost)
            LazyVGrid(columns: systemColumns, spacing: 10) {
                ForEach(GT500TwinSystem.allCases) { system in
                    NavigationLink { GT500DigitalTwinView(initialSystem: system) } label: {
                        HStack(spacing: 10) {
                            Image(systemName: system.icon).foregroundStyle(system.accent).frame(width: 22)
                            Text(system.displayName)
                                .font(.plCaption)
                                .foregroundStyle(.plTextPrimary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.plSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(system.accent.opacity(0.3)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.system.\(system.id.lowercased().replacingOccurrences(of: " ", with: "-"))")
                }
            }
        }
    }

    private var evidenceBoundary: some View {
        PLCard(padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.shield.fill").foregroundStyle(.plSuccess)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Evidence before certainty").font(.plHeadline).foregroundStyle(.plTextPrimary)
                    Text("Measured, derived, candidate and unknown claims stay visibly distinct everywhere in the app.")
                        .font(.plCaption).foregroundStyle(.plTextSecondary)
                    PLEvidenceLaneLegend().padding(.top, 2)
                }
            }
        }
    }
}

private struct HomeStatusPill: View {
    let icon: String; let title: String; let value: String; let accent: Color
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(accent)
            Text(value).font(.plMono(11)).foregroundStyle(.plTextPrimary).lineLimit(1).minimumScaleFactor(0.7)
            Text(title).font(.system(size: 9, weight: .semibold)).foregroundStyle(.plTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.plSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(accent.opacity(0.35)))
        .accessibilityElement(children: .combine)
    }
}

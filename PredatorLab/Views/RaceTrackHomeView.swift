import SwiftUI

/// Rev138 primary cockpit. A visual, task-first launch surface that keeps the technical
/// depth of PredatorLab while making the next useful action obvious on iPhone and iPad.
struct RaceTrackHomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var dataRepository: DataRepository
    @State private var showResearch = false

    private let columns = [GridItem(.adaptive(minimum: 155), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    hero
                    statusStrip
                    primaryActions
                    quickActions
                    explore
                    systemsGateway
                    evidenceBoundary
                }
                .padding(16)
            }
            .plHardBottomEdge()
            .plScreenBackground()
            .navigationTitle("PredatorLab")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showResearch) { NavigationStack { GT500ResearchCommandCenterView() } }
        }
        .accessibilityIdentifier("home.racetrack")
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [.plSurfaceRaised, .plBackground], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(minHeight: 190)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 92, weight: .black))
                        .foregroundStyle(.plBoost.opacity(0.16))
                        .padding(18)
                }
                .overlay {
                    VStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { _ in
                            Rectangle().fill(Color.plStroke.opacity(0.28)).frame(height: 1)
                        }
                    }.rotationEffect(.degrees(-8)).padding(.horizontal, -20)
                }
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Text("KNOW THE CAR.\nMASTER THE DATA.")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .italic()
                    .foregroundStyle(.plTextPrimary)
                Text("Acquire → Verify → Investigate → Experiment → Validate")
                    .font(.plCaption).foregroundStyle(.plBoost)
                if let vehicle = appState.currentVehicle {
                    Label(vehicle.displayName, systemImage: "car.side.fill")
                        .font(.plHeadline).foregroundStyle(.plTextPrimary)
                } else {
                    Label("Set up your GT500 in Garage", systemImage: "car.badge.plus")
                        .font(.plBody).foregroundStyle(.plWarning)
                }
            }.padding(20)
        }
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.plBoost.opacity(0.55), lineWidth: 1))
    }

    private var statusStrip: some View {
        HStack(spacing: 8) {
            HomeStatusPill(icon: "car.side.fill", title: "Vehicle", value: appState.currentVehicle == nil ? "SETUP" : "READY", accent: appState.currentVehicle == nil ? .plWarning : .plSuccess)
            HomeStatusPill(icon: "waveform.path.ecg", title: "Session", value: appState.isLogging ? "LOGGING" : "IDLE", accent: appState.isLogging ? .plCritical : .plBoost)
            HomeStatusPill(icon: "flag.checkered", title: "Phase", value: appState.currentPhase.shortName, accent: .plIgnition)
        }
    }

    private var primaryActions: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            HomeRouteCard(title: "GARAGE", subtitle: "Vehicle, build, service", icon: "car.side.fill", accent: .plBoost) { appState.selectedTab = MainTabView.AppTab.garage.rawValue }
            NavigationLink { MultiDomainDiagnosticsView() } label: { HomeRouteCardLabel(title: "DIAGNOSE", subtitle: "Find it. Prove it. Fix it.", icon: "stethoscope", accent: .plCritical) }
            HomeRouteCard(title: "ANALYZE", subtitle: "Logs, pulls, evidence", icon: "waveform.path.ecg", accent: .plSuccess) { appState.selectedTab = MainTabView.AppTab.analyze.rawValue }
            HomeRouteCard(title: "TUNE", subtitle: "Calibrate with evidence", icon: "gauge.with.dots.needle.67percent", accent: .plIgnition) { appState.selectedTab = MainTabView.AppTab.tune.rawValue }
        }
    }

    private var quickActions: some View {
        PLCard {
            VStack(alignment: .leading, spacing: 10) {
                PLSectionHeader(title: "Pit Lane", systemImage: "bolt.fill", accent: .plIgnition)
                Button { appState.selectedTab = MainTabView.AppTab.analyze.rawValue } label: { HomeActionRow(title: "Import or review a log", icon: "square.and.arrow.down") }
                NavigationLink { PredatorLabWorkstationRev85() } label: { HomeActionRow(title: "Open Forensic Workstation", icon: "scope") }
                NavigationLink { MPVI4DiagnosticAcquisitionLabRev74View() } label: { HomeActionRow(title: "MPVI4 acquisition", icon: "cable.connector") }
                Button { showResearch = true } label: { HomeActionRow(title: "Research Command", icon: "books.vertical.fill") }
            }
        }
    }

    private var explore: some View {
        VStack(alignment: .leading, spacing: 10) {
            PLSectionHeader(title: "Explore the Car", systemImage: "point.3.connected.trianglepath.dotted", accent: .plBoost)
            LazyVGrid(columns: columns, spacing: 10) {
                NavigationLink { GT500ResearchCommandCenterView() } label: { ExploreTile("Wiring + Connectors", "cable.connector.horizontal") }
                NavigationLink { GT500ResearchCommandCenterView() } label: { ExploreTile("PCM / TCM", "cpu") }
                NavigationLink { GT500ResearchCommandCenterView() } label: { ExploreTile("Sensor Matrix", "dot.radiowaves.left.and.right") }
                NavigationLink { GT500ResearchCommandCenterView() } label: { ExploreTile("Fuel System", "fuelpump.fill") }
                NavigationLink { GT500ResearchCommandCenterView() } label: { ExploreTile("Predator Engine", "engine.combustion.fill") }
                NavigationLink { GT500ResearchCommandCenterView() } label: { ExploreTile("TR-9070 DCT", "gearshape.2.fill") }
                NavigationLink { GT500ResearchCommandCenterView() } label: { ExploreTile("MagneRide / VDM", "arrow.up.and.down.and.arrow.left.and.right") }
                NavigationLink { GT500ResearchCommandCenterView() } label: { ExploreTile("ABS / EPAS", "steeringwheel") }
            }
        }
    }


    private var systemsGateway: some View {
        PLTrackSection(title: "Systems Paddock", subtitle: "Enter by subsystem instead of hunting through feature names.", icon: "wrench.and.screwdriver.fill", accent: .plBoost) {
            NavigationLink { TrackWorkshopSystemsView() } label: {
                HStack {
                    Image(systemName: "point.3.connected.trianglepath.dotted").foregroundStyle(.plBoost)
                    Text("Open the complete vehicle systems map").font(.plBody).foregroundStyle(.plTextPrimary)
                    Spacer(); Image(systemName: "chevron.right").foregroundStyle(.plTextSecondary)
                }.padding(.vertical, 5)
            }.buttonStyle(.plain)
        }
    }

    private var evidenceBoundary: some View {
        PLCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.shield.fill").foregroundStyle(.plSuccess)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Evidence before certainty").font(.plHeadline).foregroundStyle(.plTextPrimary)
                    Text("Measured, derived, candidate, source-verified and vehicle-validated claims stay visibly distinct.")
                        .font(.plCaption).foregroundStyle(.plTextSecondary)
                    PLEvidenceLaneLegend().padding(.top, 4)
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
            Text(value).font(.plMono(11)).foregroundStyle(.plTextPrimary).lineLimit(1)
            Text(title).font(.system(size: 9, weight: .semibold)).foregroundStyle(.plTextSecondary)
        }.frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(Color.plSurface).clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.35)))
    }
}

private struct HomeRouteCard: View {
    let title: String; let subtitle: String; let icon: String; let accent: Color; let action: () -> Void
    var body: some View { Button(action: action) { HomeRouteCardLabel(title: title, subtitle: subtitle, icon: icon, accent: accent) }.buttonStyle(.plain) }
}

private struct HomeRouteCardLabel: View {
    let title: String; let subtitle: String; let icon: String; let accent: Color
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [accent.opacity(0.22), Color.plSurface], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: icon).font(.system(size: 52, weight: .bold)).foregroundStyle(accent.opacity(0.20)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(12)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 19, weight: .black, design: .rounded)).italic().foregroundStyle(.plTextPrimary)
                Text(subtitle).font(.plCaption).foregroundStyle(.plTextSecondary).lineLimit(2)
            }.padding(14)
        }.frame(minHeight: 112).clipShape(RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.55)))
    }
}

private struct HomeActionRow: View {
    let title: String; let icon: String
    var body: some View { HStack { Image(systemName: icon).frame(width: 28).foregroundStyle(.plBoost); Text(title).font(.plBody).foregroundStyle(.plTextPrimary); Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundStyle(.plTextSecondary) }.padding(.vertical, 7).contentShape(Rectangle()) }
}

private struct ExploreTile: View {
    let title: String; let icon: String
    init(_ title: String, _ icon: String) { self.title = title; self.icon = icon }
    var body: some View { HStack(spacing: 10) { Image(systemName: icon).foregroundStyle(.plBoost).frame(width: 24); Text(title).font(.plCaption).foregroundStyle(.plTextPrimary); Spacer() }.padding(12).frame(maxWidth: .infinity, minHeight: 52).background(Color.plSurface).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.plStroke)) }
}

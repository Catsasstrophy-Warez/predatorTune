import SwiftUI

/// Edit the current vehicle and manage its build revisions. Build revisions are append-only:
/// logs and baselines reference the build they were recorded on, so a hardware change creates
/// a new revision instead of rewriting an old one.
struct VehicleEditorView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var dataRepository: DataRepository

    @State private var draft: GT500Vehicle
    @State private var mileageText: String
    @State private var weightText: String
    @State private var showNewBuild = false

    init(vehicle: GT500Vehicle) {
        _draft = State(initialValue: vehicle)
        _mileageText = State(initialValue: vehicle.mileage.map(String.init) ?? "")
        _weightText = State(initialValue: vehicle.testWeightLb.map(String.init) ?? "")
    }

    var body: some View {
        Form {
            Section("Vehicle") {
                TextField("Nickname", text: $draft.nickname)
                    .accessibilityIdentifier("vehicle.nickname")
                Picker("Model year", selection: $draft.modelYear) {
                    ForEach(GT500ModelYear.allCases) { Text(String($0.rawValue)).tag($0) }
                }
                TextField("VIN", text: Binding(get: { draft.vin ?? "" }, set: { draft.vin = $0.isEmpty ? nil : $0.uppercased() }))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                TextField("Mileage", text: $mileageText)
                    .keyboardType(.numberPad)
                TextField("Fuel", text: $draft.fuelType)
            }

            Section {
                TextField("Test weight, lb (default \(DynoAssumptions.defaultTestWeightLb))", text: $weightText)
                    .keyboardType(.numberPad)
                    .accessibilityIdentifier("vehicle.testWeight")
            } header: {
                Text("Road dyno")
            } footer: {
                Text("Car plus driver and fuel as you log it. Curb weight is about \(DynoAssumptions.gt500CurbWeightLb) lb; every 100 lb shifts estimates by roughly 2%.")
            }

            Section {
                ForEach(draft.buildStates.sorted { $0.date > $1.date }) { build in
                    Button { draft.switchBuildState(to: build.id) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(build.name).font(.plBody).foregroundStyle(.plTextPrimary)
                                Text("\(build.blower) • \(build.injectors)").font(.plCaption).foregroundStyle(.plTextSecondary).lineLimit(2)
                                Text(build.date.formatted(date: .abbreviated, time: .omitted)).font(.plCaption).foregroundStyle(.plTextSecondary)
                            }
                            Spacer()
                            if build.id == draft.currentBuildStateID {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.plIgnition)
                                    .accessibilityLabel("Current build")
                            }
                        }
                    }
                }
                Button { showNewBuild = true } label: { Label("New build revision", systemImage: "plus.circle.fill") }
                    .accessibilityIdentifier("vehicle.newBuild")
            } header: {
                Text("Builds")
            } footer: {
                Text("Tap a build to make it current. Logs keep the build they were recorded on, so changing hardware means adding a revision rather than editing an old one.")
            }

            Section("Controllers") {
                LabeledContent("PCM", value: "\(draft.pcmController) \(draft.pcmStrategy) \(draft.pcmOS)")
                LabeledContent("TCM", value: "\(draft.tcmController) \(draft.tcmStrategy) \(draft.tcmOS)")
            }
        }
        .scrollContentBackground(.hidden)
        .plScreenBackground()
        .tint(.plIgnition)
        .navigationTitle("Vehicle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(draft.nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityIdentifier("vehicle.save")
            }
        }
        .sheet(isPresented: $showNewBuild) {
            BuildRevisionSheet(base: draft.currentBuildState ?? VehicleBuildState()) { name, apply in
                draft.createBuildRevision(named: name, mutate: apply)
            }
        }
    }

    private func save() {
        draft.mileage = Int(mileageText.filter(\.isNumber))
        draft.testWeightLb = Int(weightText.filter(\.isNumber)).flatMap { (2_500...7_000).contains($0) ? $0 : nil }
        let vehicle = draft
        appState.currentVehicle = vehicle
        appState.currentBuildStateID = vehicle.currentBuildStateID
        if let index = appState.allVehicles.firstIndex(where: { $0.id == vehicle.id }) {
            appState.allVehicles[index] = vehicle
        } else {
            appState.allVehicles.append(vehicle)
        }
        Task {
            do { try await dataRepository.save(vehicle: vehicle) }
            catch { dataRepository.reportPersistenceFailure(domain: "vehicleSave", recordID: vehicle.id.uuidString, error: error) }
        }
    }
}

/// Collects the hardware for a new build revision, prefilled from the current build.
private struct BuildRevisionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onCreate: (String, @escaping (inout VehicleBuildState) -> Void) -> Void

    @State private var name = ""
    @State private var blower: String
    @State private var blowerPulley: String
    @State private var injectors: String
    @State private var fuelPump: String
    @State private var intercooler: String
    @State private var intake: String
    @State private var exhaust: String
    @State private var transmissionMods: String
    @State private var notes = ""

    init(base: VehicleBuildState, onCreate: @escaping (String, @escaping (inout VehicleBuildState) -> Void) -> Void) {
        self.onCreate = onCreate
        _blower = State(initialValue: base.blower)
        _blowerPulley = State(initialValue: base.blowerPulley)
        _injectors = State(initialValue: base.injectors)
        _fuelPump = State(initialValue: base.fuelPump)
        _intercooler = State(initialValue: base.intercooler)
        _intake = State(initialValue: base.intake)
        _exhaust = State(initialValue: base.exhaust)
        _transmissionMods = State(initialValue: base.transmissionMods)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Revision") {
                    TextField("Name (e.g. 2.6\" pulley + E30)", text: $name)
                }
                Section("Air") {
                    TextField("Blower", text: $blower)
                    TextField("Pulley", text: $blowerPulley)
                    TextField("Intake", text: $intake)
                    TextField("Intercooler", text: $intercooler)
                }
                Section("Fuel") {
                    TextField("Injectors", text: $injectors)
                    TextField("Fuel pump", text: $fuelPump)
                }
                Section("Driveline") {
                    TextField("Exhaust", text: $exhaust)
                    TextField("Transmission", text: $transmissionMods)
                }
                Section("Notes") {
                    TextField("What changed and why", text: $notes, axis: .vertical).lineLimit(2...5)
                }
            }
            .tint(.plIgnition)
            .navigationTitle("New Build Revision")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let values = (blower, blowerPulley, injectors, fuelPump, intercooler, intake, exhaust, transmissionMods, notes)
                        onCreate(name.trimmingCharacters(in: .whitespaces)) { build in
                            build.blower = values.0; build.blowerPulley = values.1; build.injectors = values.2
                            build.fuelPump = values.3; build.intercooler = values.4; build.intake = values.5
                            build.exhaust = values.6; build.transmissionMods = values.7; build.notes = values.8
                        }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// PredatorLab/Views/Components/SessionForm.swift
// Modal sheet for starting a new logging session. Large controls — this can be filled out
// standing at the car with gloves on, before handing the phone off to mount it.

import SwiftUI

struct SessionFormView: View {
    let onStart: (SessionMode, String?, String?, SessionExperimentContext?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var mode: SessionMode = .diagnose
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var purpose: String = ""
    @State private var calibrationIdentifier: String = ""
    @State private var fuelDescription: String = ""
    @State private var fuelLevel: Double = 50
    @State private var includeFuelLevel = false
    @State private var tireConfiguration: String = ""
    @State private var testProtocol: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Session Type") {
                    Picker("Mode", selection: $mode) {
                        ForEach(SessionMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Recommended: \(mode.recommendedConfig.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Section("Details") {
                    TextField("Location (optional)", text: $location)
                    TextField("Notes (optional)", text: $notes, axis: .vertical).lineLimit(3...6)
                }

                Section {
                    TextField("Purpose, e.g. R04 validation", text: $purpose)
                    TextField("Calibration ID / revision", text: $calibrationIdentifier)
                    TextField("Fuel description", text: $fuelDescription)
                    Toggle("Record fuel level", isOn: $includeFuelLevel)
                    if includeFuelLevel {
                        HStack { Text("Fuel Level"); Slider(value: $fuelLevel, in: 0...100, step: 1); Text("\(Int(fuelLevel))%").monospacedDigit() }
                    }
                    TextField("Tire configuration", text: $tireConfiguration)
                    TextField("Test protocol", text: $testProtocol, axis: .vertical).lineLimit(2...5)
                } header: {
                    Text("Test Setup")
                } footer: {
                    Text("Optional experiment metadata improves repeatability and future event comparability. Leave unknown values blank rather than guessing.")
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    let context = SessionExperimentContext(
                        purpose: purpose.nilIfBlank, calibrationIdentifier: calibrationIdentifier.nilIfBlank,
                        fuelDescription: fuelDescription.nilIfBlank, fuelLevelPercent: includeFuelLevel ? fuelLevel : nil,
                        tireConfiguration: tireConfiguration.nilIfBlank, testProtocol: testProtocol.nilIfBlank
                    )
                    let hasContext = [context.purpose, context.calibrationIdentifier, context.fuelDescription, context.tireConfiguration, context.testProtocol].contains { $0 != nil } || context.fuelLevelPercent != nil
                    onStart(mode, location.nilIfBlank, notes.nilIfBlank, hasContext ? context : nil)
                } label: {
                    Text("Start Logging")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 60)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding()
                .background(.bar)
            }
        }
    }
}

private extension String {
    var nilIfBlank: String? { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self }
}

// PredatorLab/Views/Components/R04InvestigationView.swift
// Presents the 8-hypothesis Insufficient Fuel Flow investigation framework, and — when a
// "protection" LogEvent from an imported CSV is available — auto-scores the hypotheses
// against that event's channel data.

import SwiftUI

struct R04InvestigationView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var hypotheses: [DiagnosticHypothesis] = R04InvestigationEngine.seedAllHypotheses()
    @State private var scores: [R04HypothesisID: Int] = [:]
    @State private var recommendation: String?
    @State private var selectedEventID: UUID?

    private let engine = R04InvestigationEngine()
    private let recommendationEngine = R04RecommendationEngine()

    private var protectionEvents: [LogEvent] {
        appState.activeEvents.filter { $0.eventType == "protection" }
    }

    private var rankedHypotheses: [DiagnosticHypothesis] {
        hypotheses.sorted {
            (scores[$0.id] ?? $0.confidence.rawValue * 10) > (scores[$1.id] ?? $1.confidence.rawValue * 10)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if protectionEvents.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("No Insufficient Fuel Flow event loaded")
                                .font(.headline)
                            Text("Import a CSV log with a protection event from the Logs tab to auto-score these hypotheses against real channel data. Until then, this is the reference framework — confidence shown is the baseline from prior investigations.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Section("Protection Event") {
                        Picker("Event", selection: $selectedEventID) {
                            ForEach(protectionEvents) { event in
                                Text("\(timelineTimeString(event.timestamp)) — \(event.description)")
                                    .tag(Optional(event.id))
                            }
                        }
                        Button {
                            runScoring()
                        } label: {
                            Label("Score Hypotheses Against This Event", systemImage: "wand.and.stars")
                        }
                    }
                }

                Section("Hypotheses (ranked)") {
                    ForEach(rankedHypotheses) { hypothesis in
                        HypothesisRow(hypothesis: hypothesis, score: scores[hypothesis.id])
                    }
                }

                if let recommendation {
                    Section("Recommendation") {
                        Text(recommendation)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("R04 Investigation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                if selectedEventID == nil {
                    selectedEventID = protectionEvents.first?.id
                }
            }
        }
    }

    private func runScoring() {
        guard let id = selectedEventID,
              let event = protectionEvents.first(where: { $0.id == id }) else { return }

        let shiftTimestamp = appState.activeEvents.first { $0.eventType == "shift" }?.timestamp

        scores = engine.scoreHypotheses(
            actualPW: event.numericValue(["Injector Actual Pulse Width", "Actual Injector PW", "Injector PW"]),
            maximumPW: event.numericValue(["Maximum Available Injector Pulse Width", "Max Injector PW", "Injection Window"]),
            pressureCommand: event.numericValue(["Fuel Pressure Command", "Pressure Command", "FP Command"]),
            pressureActual: event.numericValue(["Fuel Pressure Actual", "Fuel Pressure", "Pressure"]),
            pumpDuty: event.numericValue(["Pump Duty Actual", "Fuel Pump Duty"]),
            commandedLambda: event.numericValue(["Commanded Lambda", "Lambda Command", "Target Lambda"]),
            measuredLambda: event.numericValue(["WB Lambda B1", "WB Lambda", "O2 Sensor"]),
            torqueSource: event.sourceStates["Torque Max Protection Source"] ?? event.sourceStates["Torque Max Source"],
            sparkSource: event.sourceStates["Spark Source"],
            rpm: event.numericValue(["RPM", "Engine RPM"]),
            load: event.numericValue(["Load", "Calculated Load"]),
            gearAtEvent: event.numericValue(["Gear Selected", "Current Gear"]).map { Int($0) },
            shiftTimestamp: shiftTimestamp,
            eventTimestamp: event.timestamp
        )

        let investigation = appState.currentInvestigation ?? Investigation(
            vehicleID: appState.currentVehicle?.id ?? UUID(),
            phase: .r04FuelCapability,
            problem: "Insufficient Fuel Flow protection event at \(timelineTimeString(event.timestamp))"
        )
        recommendation = recommendationEngine.recommendNextSteps(investigationState: investigation, hypothesisScores: scores)
    }
}

private extension LogEvent {
    func numericValue(_ candidates: [String]) -> Double? {
        for name in candidates {
            if let value = channelValues[name] { return value }
        }
        return nil
    }
}

private struct HypothesisRow: View {
    let hypothesis: DiagnosticHypothesis
    let score: Int?

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                Text(hypothesis.description)
                    .font(.subheadline)

                if !hypothesis.supportingEvidence.isEmpty {
                    EvidenceGroup(title: "Supporting", items: hypothesis.supportingEvidence, color: .green)
                }
                if !hypothesis.contradictingEvidence.isEmpty {
                    EvidenceGroup(title: "Contradicting", items: hypothesis.contradictingEvidence, color: .red)
                }
                if !hypothesis.nextMeasurements.isEmpty {
                    EvidenceGroup(title: "Next Measurements", items: hypothesis.nextMeasurements, color: .blue)
                }
            }
            .padding(.top, 4)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(hypothesis.id.rawValue) — \(hypothesis.title)")
                        .font(.headline)
                    Text(hypothesis.confidence.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let score {
                    Text("\(score)")
                        .font(.title3.bold())
                        .foregroundStyle(scoreColor(score))
                }
            }
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 70...: return .red
        case 40..<70: return .orange
        default: return .secondary
        }
    }
}

private struct EvidenceGroup: View {
    let title: String
    let items: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(color)
            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

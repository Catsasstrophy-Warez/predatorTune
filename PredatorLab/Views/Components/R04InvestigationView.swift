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
            .plListStyle().navigationTitle("R04 Investigation")
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

        // The shift that matters is the latest one at or before the event, not the log's first.
        let shiftTimestamp = appState.activeEvents
            .filter { $0.eventType == "shift" && $0.timestamp <= event.timestamp }
            .map(\.timestamp).max()

        scores = engine.scoreHypotheses(
            actualPW: event.numericValue(.injectorPulseWidth),
            maximumPW: event.numericValue(.maximumInjectorPulseWidth),
            pressureCommand: event.numericValue(.fuelPressureCommanded),
            pressureActual: event.numericValue(.fuelPressureActual),
            pumpDuty: event.numericValue(fallback: ["Pump Duty Actual", "Fuel Pump Duty"]),
            commandedLambda: event.numericValue(.lambdaCommanded),
            measuredLambda: event.numericValue(.lambdaMeasured),
            torqueSource: event.state(.torqueProtectionSource),
            sparkSource: event.state(.sparkSource),
            rpm: event.numericValue(.engineRPM),
            load: event.numericValue(fallback: ["Absolute Load (SAE)", "Absolute Load", "Load", "Calculated Load"]),
            gearAtEvent: (event.numericValue(.gearActual) ?? event.numericValue(.gearCommanded)).map { Int($0) },
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
    /// Resolves a logged channel by role, so real export names like "Engine RPM (SAE)" match.
    func numericValue(_ channel: CanonicalChannel) -> Double? {
        ChannelResolver.resolve(channel, in: Array(channelValues.keys).sorted()).flatMap { channelValues[$0] }
    }

    func numericValue(fallback candidates: [String]) -> Double? {
        candidates.lazy.compactMap { channelValues[$0] }.first
    }

    func state(_ channel: CanonicalChannel) -> String? {
        ChannelResolver.resolveAll(channel, in: Array(sourceStates.keys).sorted()).lazy.compactMap { sourceStates[$0] }.first
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

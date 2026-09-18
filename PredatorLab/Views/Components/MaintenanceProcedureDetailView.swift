// PredatorLab/Views/Components/MaintenanceProcedureDetailView.swift
// Full detail for one MaintenanceProcedure: ordered steps, parts, tools, fluids,
// torque specs, and sourced evidence — the destination pushed from ReferenceLibraryView's
// Maintenance segment.

import SwiftUI

struct MaintenanceProcedureDetailView: View {
    let procedure: MaintenanceProcedure

    private var orderedSteps: [MaintenanceProcedureStep] {
        procedure.steps.sorted { $0.order < $1.order }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                PLCard {
                    VStack(alignment: .leading, spacing: 10) {
                        DetailRow(label: "System", value: "\(procedure.system.rawValue) — \(procedure.subsystem)")
                        DetailRow(label: "Estimated Time", value: timeString(procedure.estimatedTime))
                        HStack {
                            Text("Difficulty")
                                .font(.plCaption)
                                .foregroundStyle(.plTextSecondary)
                            Spacer()
                            DifficultyBadge(level: procedure.difficulty)
                        }
                        if let workshopRef = procedure.workshopManualReference {
                            DetailRow(label: "Workshop Manual", value: workshopRef)
                        }
                        if !procedure.applicableIntensities.isEmpty {
                            DetailRow(label: "Applies To", value: procedure.applicableIntensities.map(\.rawValue).joined(separator: ", "))
                        }
                    }
                }

                if !procedure.safetyWarnings.isEmpty {
                    PLCard {
                        VStack(alignment: .leading, spacing: 10) {
                            PLSectionHeader(title: "Safety Warnings", systemImage: "exclamationmark.triangle.fill", accent: .plCritical)
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(procedure.safetyWarnings.enumerated()), id: \.offset) { _, warning in
                                    WarningRow(text: warning)
                                }
                            }
                        }
                    }
                }

                if !orderedSteps.isEmpty {
                    PLCard {
                        VStack(alignment: .leading, spacing: 12) {
                            PLSectionHeader(title: "Steps", systemImage: "list.number")
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(orderedSteps) { step in
                                    MaintenanceStepRow(step: step)
                                    if step.id != orderedSteps.last?.id {
                                        Divider().background(Color.plStroke)
                                    }
                                }
                            }
                        }
                    }
                }

                if !procedure.parts.isEmpty {
                    PLCard {
                        VStack(alignment: .leading, spacing: 12) {
                            PLSectionHeader(title: "Parts", systemImage: "shippingbox", accent: .plBoost)
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(procedure.parts) { part in
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack {
                                            Text(part.name)
                                                .font(.plBody)
                                                .foregroundStyle(.plTextPrimary)
                                            Spacer()
                                            if part.quantity > 1 {
                                                Text("×\(part.quantity)")
                                                    .font(.plMono(12))
                                                    .foregroundStyle(.plIgnition)
                                            }
                                        }
                                        Text(part.partNumber + (part.vendorReference.map { " — \($0)" } ?? ""))
                                            .font(.plMono(11))
                                            .foregroundStyle(.plTextSecondary)
                                        if let notes = part.notes {
                                            Text(notes)
                                                .font(.plCaption)
                                                .foregroundStyle(.plTextSecondary)
                                        }
                                    }
                                    if part.id != procedure.parts.last?.id {
                                        Divider().background(Color.plStroke)
                                    }
                                }
                            }
                        }
                    }
                }

                if !procedure.tools.isEmpty {
                    PLCard {
                        VStack(alignment: .leading, spacing: 10) {
                            PLSectionHeader(title: "Tools", systemImage: "wrench.and.screwdriver")
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(procedure.tools) { tool in
                                    HStack {
                                        Text(tool.name)
                                            .font(.plBody)
                                            .foregroundStyle(.plTextPrimary)
                                        if tool.optional {
                                            PLBadge(text: "Optional", color: .plTextSecondary, filled: false)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                if !procedure.fluids.isEmpty {
                    PLCard {
                        VStack(alignment: .leading, spacing: 12) {
                            PLSectionHeader(title: "Fluids", systemImage: "drop", accent: .plBoost)
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(procedure.fluids) { fluid in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(fluid.name)
                                            .font(.plBody)
                                            .foregroundStyle(.plTextPrimary)
                                        Text("\(fluid.specification) — \(formattedQuantity(fluid.quantity)) \(fluid.unit)")
                                            .font(.plMono(11))
                                            .foregroundStyle(.plTextSecondary)
                                    }
                                    if fluid.id != procedure.fluids.last?.id {
                                        Divider().background(Color.plStroke)
                                    }
                                }
                            }
                        }
                    }
                }

                if !procedure.torqueSpecifications.isEmpty {
                    PLCard {
                        VStack(alignment: .leading, spacing: 12) {
                            PLSectionHeader(title: "Torque Specifications", systemImage: "gauge.with.dots.needle.67percent", accent: .plIgnition)
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(procedure.torqueSpecifications) { spec in
                                    TorqueSpecRow(spec: spec)
                                    if spec.id != procedure.torqueSpecifications.last?.id {
                                        Divider().background(Color.plStroke)
                                    }
                                }
                            }
                        }
                    }
                }

                PLCard {
                    VStack(alignment: .leading, spacing: 10) {
                        PLSectionHeader(title: "Source", systemImage: "checkmark.seal", accent: .plBoost)
                        HStack(alignment: .top, spacing: 10) {
                            ConfidenceBadge(level: procedure.sourceConfidence)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(procedure.sourceChannel.isEmpty ? "Unattributed" : procedure.sourceChannel)
                                    .font(.plBody)
                                    .foregroundStyle(.plTextPrimary)
                                Text(procedure.sourceConfidence.title)
                                    .font(.plCaption)
                                    .foregroundStyle(.plTextSecondary)
                                if let alignment = procedure.workshopAlignment {
                                    Text("Workshop alignment: \(alignment)")
                                        .font(.plCaption)
                                        .foregroundStyle(.plTextSecondary)
                                }
                                if let channel = procedure.youTubeChannelName, let videoID = procedure.youTubeVideoID,
                                   let url = youTubeURL(videoID: videoID, timestamp: procedure.youTubeTimestamp) {
                                    Link("Watch on \(channel)", destination: url)
                                        .font(.plCaption)
                                        .foregroundStyle(.plBoost)
                                }
                            }
                        }

                        if !procedure.notes.isEmpty {
                            Text(procedure.notes)
                                .font(.plCaption)
                                .foregroundStyle(.plTextSecondary)
                        }
                    }
                }
            }
            .padding(16)
        }
        .plScreenBackground()
        .navigationTitle(procedure.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func timeString(_ minutes: TimeInterval) -> String {
        let total = Int(minutes)
        if total < 60 { return "\(total) min" }
        let hours = total / 60
        let mins = total % 60
        return mins == 0 ? "\(hours) hr" : "\(hours) hr \(mins) min"
    }

    private func formattedQuantity(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.2f", value)
    }

    private func youTubeURL(videoID: String, timestamp: TimeInterval?) -> URL? {
        if let timestamp, timestamp > 0 {
            return URL(string: "https://www.youtube.com/watch?v=\(videoID)&t=\(Int(timestamp))s")
        }
        return URL(string: "https://www.youtube.com/watch?v=\(videoID)")
    }
}

// MARK: - Detail Row

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.plCaption)
                .foregroundStyle(.plTextSecondary)
            Spacer()
            Text(value)
                .font(.plBody)
                .foregroundStyle(.plTextPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Step Row

private struct MaintenanceStepRow: View {
    let step: MaintenanceProcedureStep

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Text("\(step.order)")
                    .font(.plMono(12))
                    .frame(width: 22, height: 22)
                    .foregroundStyle(Color.black.opacity(0.85))
                    .background(Color.plIgnition)
                    .clipShape(Circle())
                Text(step.instruction)
                    .font(.plBody)
                    .foregroundStyle(.plTextPrimary)
            }

            if let warning = step.warning {
                WarningRow(text: warning)
                    .padding(.leading, 32)
            }

            if let torqueSpec = step.torqueSpec {
                TorqueSpecRow(spec: torqueSpec)
                    .padding(.leading, 32)
            }
        }
    }
}

// MARK: - Warning Row

private struct WarningRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.plCaption)
                .foregroundStyle(.plWarning)
            Text(text)
                .font(.plCaption)
                .foregroundStyle(.plWarning)
        }
    }
}

// MARK: - Torque Spec Row

private struct TorqueSpecRow: View {
    let spec: MaintenanceTorqueSpec

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.plCaption)
                .foregroundStyle(.plIgnition)
            VStack(alignment: .leading, spacing: 2) {
                Text(spec.component)
                    .font(.plCaption)
                    .foregroundStyle(.plTextSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(formattedValue(spec.value))
                        .font(.plGauge(22))
                        .foregroundStyle(.plIgnition)
                    Text("lb-ft")
                        .font(.plMono(11))
                        .foregroundStyle(.plTextSecondary)
                }
                if let sequence = spec.sequence {
                    Text(sequence)
                        .font(.plCaption)
                        .foregroundStyle(.plTextSecondary)
                }
                if let note = spec.note {
                    Text(note)
                        .font(.plCaption)
                        .foregroundStyle(.plTextSecondary)
                }
            }
        }
    }

    private func formattedValue(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }
}

// MARK: - Difficulty Badge

private struct DifficultyBadge: View {
    let level: DifficultyLevel

    private var color: Color {
        switch level {
        case .beginner: return .plSuccess
        case .intermediate: return .plBoost
        case .advanced: return .plWarning
        case .expert: return .plCritical
        }
    }

    var body: some View {
        PLBadge(text: level.rawValue, color: color, filled: false)
    }
}

// PredatorLab/Views/Components/ComponentDetailView.swift
// Full detail for one ComponentRecord: specs, location, failure modes, maintenance
// intervals, and sourced evidence — the destination pushed from ReferenceLibraryView.

import SwiftUI

struct ComponentDetailView: View {
    let component: ComponentRecord

    var body: some View {
        List {
            Section {
                if let oem = component.oem {
                    LabeledContent("OEM / Part", value: oem)
                }
                if let manufacturer = component.manufacturer {
                    LabeledContent("Manufacturer", value: manufacturer)
                }
                LabeledContent("System", value: component.section.rawValue)
            }

            if !component.specifications.isEmpty {
                Section("Specifications") {
                    ForEach(Array(component.specifications.enumerated()), id: \.offset) { _, spec in
                        SpecRow(spec: spec)
                    }
                }
            }

            if let location = component.physicalLocation {
                Section("Location") {
                    LabeledContent("Where", value: location.subsection)
                    LabeledContent("Access", value: location.access)
                    if !location.connectors.isEmpty {
                        LabeledContent("Connectors", value: location.connectors.joined(separator: ", "))
                    }
                    if !location.references.isEmpty {
                        LabeledContent("References", value: location.references.joined(separator: ", "))
                    }
                }
            }

            if !component.failureModes.isEmpty {
                Section("Known Failure Modes") {
                    ForEach(Array(component.failureModes.enumerated()), id: \.offset) { _, mode in
                        FailureModeRow(mode: mode)
                    }
                }
            }

            if !component.maintenanceIntervals.isEmpty {
                Section("Maintenance Intervals") {
                    ForEach(Array(component.maintenanceIntervals.enumerated()), id: \.offset) { _, interval in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(interval.procedure)
                                .font(.subheadline.bold())
                            Text("\(interval.interval) — \(interval.intensity)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(interval.reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            if !component.sources.isEmpty {
                Section("Sources") {
                    ForEach(Array(component.sources.enumerated()), id: \.offset) { _, source in
                        SourceRow(source: source)
                    }
                }
            }
        }
        .navigationTitle(component.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SpecRow: View {
    let spec: ComponentSpec

    var body: some View {
        HStack(alignment: .top) {
            Text(spec.parameter)
                .font(.subheadline)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(spec.value + (spec.units.map { " \($0)" } ?? ""))
                    .font(.subheadline.bold())
                if let tolerance = spec.tolerance {
                    Text(tolerance)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

private struct FailureModeRow: View {
    let mode: FailureMode

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                LabeledSection(title: "Root Cause", text: mode.rootCause)
                LabeledSection(title: "Diagnostic Method", text: mode.diagnosticMethod)
                LabeledSection(title: "Remedy", text: mode.remedy)
                if let preventive = mode.preventiveCare {
                    LabeledSection(title: "Prevention", text: preventive)
                }
            }
            .padding(.top, 4)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.name)
                        .font(.headline)
                    Text(mode.symptoms.joined(separator: " • "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                RiskBadge(level: mode.riskLevel)
            }
        }
    }
}

private struct LabeledSection: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
        }
    }
}

private struct RiskBadge: View {
    let level: String

    private var color: Color {
        switch level.lowercased() {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        default: return .green
        }
    }

    var body: some View {
        Text(level)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

private struct SourceRow: View {
    let source: TechnicalSource

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            EvidenceBadge(grade: source.grade)
            VStack(alignment: .leading, spacing: 2) {
                Text(source.title)
                    .font(.subheadline.bold())
                Text("\(source.sourceType) — \(source.reference)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let url = source.url, let link = URL(string: url) {
                    Link("View Source", destination: link)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

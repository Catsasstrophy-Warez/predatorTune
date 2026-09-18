import SwiftUI

/// Reusable conclusion card. Strong language is never rendered directly from an engine request;
/// the effective title/strength comes from DiagnosticPresentationGate.
struct DiagnosticResultCard: View {
    let result: DiagnosticResultPresentation
    var body: some View {
        PLCard {
            VStack(alignment:.leading, spacing:8) {
                HStack {
                    Image(systemName: result.decision.mayUseStrongLanguage ? "checkmark.shield.fill" : "exclamationmark.shield")
                    Text(result.displayTitle).font(.headline)
                }
                Text("Presentation: \(String(describing: result.decision.effectiveStrength))")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(result.evidenceSummary, id:\.self) { Text($0).font(.caption) }
                if !result.decision.reasons.isEmpty {
                    Divider()
                    ForEach(result.decision.reasons, id:\.self) { Text($0).font(.caption2).foregroundStyle(.secondary) }
                }
                Text(result.decision.boundary).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("diagnostic.result.\(result.id)")
    }
}

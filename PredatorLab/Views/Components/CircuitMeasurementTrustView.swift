import SwiftUI

/// Inline durable trust rendering for every expected circuit measurement. Persistence overrides are
/// resolved by exact semantic claim ID; neighboring pins/test points never inherit state.
struct CircuitMeasurementTrustView: View {
    @EnvironmentObject var dataRepository: DataRepository
    let circuit: CircuitRecord
    @State private var persisted: [PersistedMeasurementClaim] = []
    @State private var loadError: String?

    private var claims: [MeasurementClaimContract] {
        MeasurementClaimResolutionEngine.resolved(legacy: MeasurementClaimLedger.fromLegacy(circuit: circuit), persisted: persisted)
    }

    var body: some View {
        Group {
            ForEach(claims.prefix(60)) { claim in
                let trust = MeasurementTrustPresentationEngine.presentation(for: claim)
                VStack(alignment: .leading, spacing: 4) {
                    Text(claim.label).font(.headline)
                    Text(claim.authoredText).font(.plMono(12))
                    HStack {
                        Label(trust.title, systemImage: trust.blocksStrongDiagnosis ? "exclamationmark.shield" : "checkmark.shield")
                        Spacer()
                        Text(claim.ownerKind).font(.caption2)
                    }.font(.caption)
                    Text(trust.detail).font(.caption2).foregroundStyle(.secondary)
                    if !claim.technicalClaimIDs.isEmpty { Text("Claim: \(claim.technicalClaimIDs.joined(separator: ", "))").font(.caption2).textSelection(.enabled) }
                    if let source = claim.source { Text("Source: \(source.title) · \(claim.locator ?? "locator missing")").font(.caption2).foregroundStyle(.secondary) }
                }.accessibilityElement(children: .combine)
            }
            if let loadError { Text("Durable trust unavailable: \(loadError)").font(.caption).foregroundStyle(.secondary) }
        }
        .task {
            do { persisted = try await dataRepository.fetchMeasurementClaims(); loadError = nil }
            catch { loadError = error.localizedDescription; dataRepository.reportPersistenceFailure(domain: "circuitMeasurementTrustLoad", recordID: circuit.id.uuidString, error: error) }
        }
    }
}

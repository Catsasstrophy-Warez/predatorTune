import Foundation

/// Immutable user-supplied HPL artifacts included for repeatable forensic review.
/// The catalog records identity and observed structure only; it does not assign
/// proprietary channel semantics or certify a waveform decode.
struct ImportedHPLArtifact: Identifiable, Hashable, Sendable {
    let id: String
    let fileName: String
    let resourceName: String
    let sha256: String
    let byteCount: Int
    let observedDescriptorCount: Int
    let boundary: String
}

enum ImportedHPLArtifactCatalog {
    static let artifacts: [ImportedHPLArtifact] = [
        .init(id: "hpl-000000", fileName: "log-000000-20260911-225621-redacted.hpl", resourceName: "log-000000-20260911-225621-redacted", sha256: "6e8d3ea856569a822fba97c1b2ac2701d81bed21719f7a43f8c28afdb718fc3c", byteCount: 1476221, observedDescriptorCount: 0, boundary: "Original binary artifact; structure observed, semantics unverified."),
        .init(id: "hpl-000002", fileName: "log-000002-20260911-235344-redacted.hpl", resourceName: "log-000002-20260911-235344-redacted", sha256: "6d4ee3386dd7eb4f2c827204a49aab2f047f8c3f2024e925812996f41d12112a", byteCount: 1634097, observedDescriptorCount: 0, boundary: "Original binary artifact; structure observed, semantics unverified.")
    ]

    static func data(for artifact: ImportedHPLArtifact, bundle: Bundle = .main) -> Data? {
        guard let url = bundle.url(forResource: artifact.resourceName, withExtension: "hpl", subdirectory: "ImportedHPL") else { return nil }
        return try? Data(contentsOf: url)
    }

    static func probe(_ artifact: ImportedHPLArtifact, bundle: Bundle = .main) -> HPLNativeProbeResultRev85? {
        guard let bytes = data(for: artifact, bundle: bundle) else { return nil }
        return HPLNativeWaveformDecoderRev85.probe(data: bytes, referenceValues: [])
    }
}

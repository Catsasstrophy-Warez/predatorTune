import SwiftUI
import UniformTypeIdentifiers

struct TuneExperimentLabView: View {
    @State private var imported:[TuneImportedArtifact] = []
    @State private var showImporter = false
    @State private var scannerFingerprint: ScannerConfigurationFingerprint?
    @State private var trackMap: TrackAddictColumnMap?
    @State private var importWarnings:[String] = []

    private var reconstruction: ReconstructedTuneExperiment { TuneExperimentReconstructionEngine.reconstruct(imported.map(\.descriptor)) }

    var body: some View {
        List {
            Section("Real Evidence Import") {
                Button("Import HPT / HPL / XML / TrackAddict Evidence") { showImporter = true }.accessibilityIdentifier("tune.experiment.import")
                if imported.isEmpty { Text("No evidence imported. Originals are inspected and fingerprinted; PredatorLab does not modify them.").font(.caption).foregroundStyle(.secondary) }
                ForEach(imported) { item in
                    VStack(alignment:.leading,spacing:4) {
                        LabeledContent(item.descriptor.fileName,value:item.descriptor.kind.rawValue)
                        if let hash=item.descriptor.sha256 { Text("SHA-256  \(hash)").font(.caption2).textSelection(.enabled) }
                    }
                }
            }
            Section("Bundled HPL artifact review") {
                Text("These supplied originals are available as immutable comparison fixtures. The probe reports byte-level observations only; it does not decode proprietary HPL semantics.").font(.caption).foregroundStyle(.secondary)
                ForEach(ImportedHPLArtifactCatalog.artifacts) { artifact in
                    let probe = ImportedHPLArtifactCatalog.probe(artifact)
                    VStack(alignment: .leading, spacing: 4) {
                        Label(artifact.fileName, systemImage: "waveform.path.ecg")
                        LabeledContent("Bytes", value: ByteCountFormatter.string(fromByteCount: Int64(artifact.byteCount), countStyle: .file))
                        LabeledContent("Printable descriptors", value: "(probe?.descriptors.count ?? 0)")
                        Text("SHA-256 (artifact.sha256)").font(.caption2).textSelection(.enabled)
                    }
                    .accessibilityIdentifier("tune.hplArtifact.\(artifact.id)")
                }
            }
            Section("Automatic Experiment Reconstruction") {
                LabeledContent("Core HPT/HPL/XML triangle", value: reconstruction.hasCoreTriangle ? "Complete" : "Incomplete")
                LabeledContent("TrackAddict session", value: reconstruction.trackSessionID ?? "Not paired")
                LabeledContent("Structural confidence", value: reconstruction.confidence.formatted(.percent.precision(.fractionLength(0))))
                Text(reconstruction.boundary).font(.caption).foregroundStyle(.secondary)
            }
            if let scannerFingerprint {
                Section("Scanner Semantic Firewall") {
                    LabeledContent("Recognized channels",value:"\(scannerFingerprint.channels.count)")
                    LabeledContent("Fallback definitions",value:scannerFingerprint.fallbackDefinitionPresent ? "Present" : "Not detected")
                    LabeledContent("Override definitions",value:scannerFingerprint.overrideDefinitionPresent ? "Present — portability caution" : "Not detected")
                    ForEach(scannerFingerprint.warnings,id:\.self){Text($0).font(.caption).foregroundStyle(.orange)}
                }
            }
            if let trackMap {
                Section("TrackAddict CSV Semantic Discovery") {
                    LabeledContent("Time",value:trackMap.timestamp ?? "Unresolved")
                    LabeledContent("GPS",value:(trackMap.latitude != nil && trackMap.longitude != nil) ? "Mapped" : "Incomplete")
                    LabeledContent("Speed",value:trackMap.speed ?? "Unresolved")
                    LabeledContent("RPM",value:trackMap.rpm ?? "Unresolved")
                    Text("Header matching is discovery only. A plausible column name does not receive strong semantic authority without source/schema validation.").font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Integrity") {
                ForEach(reconstruction.warnings + importWarnings,id:\.self) { Label($0,systemImage:"exclamationmark.triangle.fill").foregroundStyle(.orange) }
                if reconstruction.warnings.isEmpty && importWarnings.isEmpty && !imported.isEmpty { Label("No structural bundle warnings",systemImage:"checkmark.seal.fill") }
            }
            Section("Rev59 gates now enforced") {
                Text("Bind the imported evidence to immutable Vehicle + Build + PCM + TCM identities, evaluate its Tune Log Contract, align independent clocks from measured anchors, then admit it to Limiter/Shift analysis. Calibration differences remain non-causal observations until validated by comparable evidence.")
            }
        }
        .navigationTitle("Tune Experiment Lab")
        .fileImporter(isPresented:$showImporter,allowedContentTypes:[.data,.xml,.commaSeparatedText,.movie,.plainText],allowsMultipleSelection:true) { result in
            guard case .success(let urls)=result else { importWarnings.append("The selected files could not be opened."); return }
            for url in urls {
                let scoped=url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                do {
                    let artifact=try TuneArtifactImportService.inspect(url:url); imported.append(artifact)
                    if artifact.descriptor.kind == .scannerXML, let data=try? Data(contentsOf:url) { scannerFingerprint=ScannerXMLParser.parse(data:data) }
                    if artifact.descriptor.kind == .trackCSV, let text=try? String(contentsOf:url), let first=text.split(whereSeparator:\.isNewline).first { trackMap=TrackAddictCSVSemanticDiscovery.discover(headers:first.split(separator:",").map{String($0).trimmingCharacters(in:.whitespacesAndNewlines)}) }
                } catch { importWarnings.append("Could not fingerprint \(url.lastPathComponent); it was not admitted as immutable evidence.") }
            }
        }
    }
}

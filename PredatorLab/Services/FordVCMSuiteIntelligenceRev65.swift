import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening" lineage
// this project ported from (see HANDOFF.md), NOT this app's own version history.
// Status: Current. Builds on Rev63/Rev64's types (ScannerSemanticBinding,
// FordGT500CalibrationResearchAtlas, VCMExperimentChannelPack) to add Navigator TSV
// capture ingestion, semantic review, the calibration truth-debt heatmap, and experiment
// contract compilation. See Rev66 for risk/blast-radius reasoning built on top of this.
// Rev65: executable research ingestion and truth-debt routing for Ford/VCM Suite.
// This file never supplies stock values, safe values, or undocumented GT500/TR_C75 semantics.

enum VCMNavigatorDataType: String, Codable, CaseIterable { case switchValue="Switch", scalar="Scalar", table="Table", dtcList="DTC List", codeMod="Code Mod", unknown="Unknown" }

struct VCMNavigatorCapture: Identifiable, Codable {
    let id: UUID
    let controller: TuningControllerFamily
    let operatingSystemID: String?
    let strategyID: String?
    let sourceArtifactID: UUID?
    let capturedAt: Date
    let parameters: [VCMNavigatorCapturedParameter]
    let rawCaptureSHA256: String?
    let boundary: String
}

struct VCMNavigatorCapturedParameter: Identifiable, Codable, Hashable {
    let id: String
    let navigatorPath: [String]
    let displayName: String
    let dataType: VCMNavigatorDataType
    let units: String?
    let axisLabels: [String]
    let description: String?
    let parameterID: String?
    let locator: String
    let origin: VCMSuiteEvidenceClass
}

struct VCMNavigatorImportResult: Codable { let accepted:[VCMNavigatorCapturedParameter]; let rejected:[String]; let warnings:[String]; let boundary:String }

enum VCMNavigatorCaptureImporter {
    /// Imports a user-authored tab-separated capture. Expected columns:
    /// path, name, type, units, axes, description, parameterID, locator.
    /// It intentionally does not scrape proprietary HPT binaries.
    static func parseTSV(_ text:String, origin:VCMSuiteEvidenceClass = .hpTunersDocumented) -> VCMNavigatorImportResult {
        let lines=text.split(whereSeparator: \.isNewline).map(String.init)
        guard lines.count > 1 else { return .init(accepted:[],rejected:["Capture has no data rows"],warnings:[],boundary:boundary) }
        var out:[VCMNavigatorCapturedParameter]=[]; var rejected:[String]=[]; var warnings:[String]=[]
        for (offset,line) in lines.dropFirst().enumerated() {
            let c=line.split(separator:"\t",omittingEmptySubsequences:false).map(String.init)
            guard c.count >= 2, !c[1].trimmingCharacters(in:.whitespaces).isEmpty else { rejected.append("Row \(offset+2): missing parameter name"); continue }
            let path=c[0].split(separator:">").map{String($0).trimmingCharacters(in:.whitespaces)}.filter{!$0.isEmpty}
            let type:VCMNavigatorDataType = c.count>2 ? (VCMNavigatorDataType(rawValue:c[2]) ?? .unknown) : .unknown
            let units=c.count>3 && !c[3].isEmpty ? c[3] : nil
            let axes=c.count>4 ? c[4].split(separator:"|").map(String.init) : []
            let desc=c.count>5 && !c[5].isEmpty ? c[5] : nil
            let pid=c.count>6 && !c[6].isEmpty ? c[6] : nil
            let locator=c.count>7 && !c[7].isEmpty ? c[7] : "row:\(offset+2)"
            if type == .unknown { warnings.append("Row \(offset+2): unknown data type preserved") }
            out.append(.init(id:"\(locator)|\(c[1])",navigatorPath:path,displayName:c[1],dataType:type,units:units,axisLabels:axes,description:desc,parameterID:pid,locator:locator,origin:origin))
        }
        return .init(accepted:out,rejected:rejected,warnings:warnings,boundary:boundary)
    }
    static let boundary="A Navigator capture records what a reviewed VCM Editor session displayed. It does not establish Ford internal strategy, safe values, or causal effect."
}

struct VCMScannerSemanticReview: Identifiable, Codable {
    let id: UUID
    let binding: ScannerSemanticBinding
    let sourceArtifactID: UUID?
    let exactLocator: String
    let reviewerNote: String
    let reviewedAt: Date
    let admittedForAnalysis: Bool
    let blockers: [String]
}

enum VCMScannerSemanticResolver {
    static func review(_ binding:ScannerSemanticBinding, expectedController:TuningControllerFamily, expectedStrategy:String?, artifactStrategy:String?, locator:String) -> VCMScannerSemanticReview {
        let firewall=FordScannerSemanticFirewall.assess(binding, expectedController:expectedController, requiredStrategy:expectedStrategy)
        var blockers=firewall.blockers
        if let expectedStrategy, let artifactStrategy, expectedStrategy != artifactStrategy { blockers.append("Scanner artifact strategy mismatch") }
        if locator.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty { blockers.append("Exact Scanner XML/HPL locator missing") }
        return .init(id:UUID(),binding:binding,sourceArtifactID:nil,exactLocator:locator,reviewerNote:"Semantic review preserves Parameter ID/source/transform/controller/strategy provenance.",reviewedAt:Date(),admittedForAnalysis:blockers.isEmpty,blockers:blockers)
    }
}

struct CalibrationTruthDebtCell: Identifiable, Codable {
    let id:String; let controller:TuningControllerFamily; let domain:FordCalibrationDomain; let title:String
    let unresolvedQuestions:Int; let missingArtifactIDs:[String]; let blockedCapabilities:[String]; let priority:Int
}

struct CalibrationTruthDebtSnapshot: Identifiable, Codable {
    let id:UUID; let createdAt:Date; let cells:[CalibrationTruthDebtCell]; let boundary:String
}

enum FordCalibrationTruthDebtHeatmapEngine {
    static func build(observations:[VCMParameterObservation], scannerReviews:[VCMScannerSemanticReview]) -> CalibrationTruthDebtSnapshot {
        let admittedScanner = scannerReviews.filter{$0.admittedForAnalysis}
        let cells=FordGT500CalibrationResearchAtlas.domains.map { domain -> CalibrationTruthDebtCell in
            let reviewed=observations.filter{$0.identity.controller == domain.controller && $0.researchState == .reviewedSemantic}.count
            let scanner=admittedScanner.filter{$0.binding.controller == domain.controller}.count
            let unresolved=max(0, domain.questions.count - min(domain.questions.count, reviewed + (scanner > 0 ? 1:0)))
            let targets=FordVCMDefinitionAcquisitionMatrix.records.filter{$0.controller == domain.controller}.map(\.id)
            return .init(id:domain.id,controller:domain.controller,domain:domain.domain,title:domain.title,unresolvedQuestions:unresolved,missingArtifactIDs:unresolved > 0 ? targets:[],blockedCapabilities:unresolved > 0 ? domain.questions:[],priority:min(100, unresolved*25 + domain.requiredEvidence.count*5))
        }.sorted{$0.priority > $1.priority}
        return .init(id:UUID(),createdAt:Date(),cells:cells,boundary:"Truth Debt is a research-priority map. It is not calibration quality, vehicle health, or probability that an undocumented interpretation is correct.")
    }
}

struct VCMExperimentContractReport: Codable { let ready:Bool; let missing:[String]; let blockers:[String]; let warnings:[String]; let boundary:String }

enum GT500VCMExperimentContractCompiler {
    static func compile(pack:VCMExperimentChannelPack, semanticReviews:[VCMScannerSemanticReview], calibrationIdentified:Bool, buildRevisionIdentified:Bool, unresolvedDiagnosticBlockers:[String]) -> VCMExperimentContractReport {
        let admitted=semanticReviews.filter{$0.admittedForAnalysis}.map(\.binding)
        let packResult=VCMChannelPackCompiler.assess(pack:pack,bindings:admitted)
        var blockers=packResult.rejected + unresolvedDiagnosticBlockers
        var missing=packResult.missing
        if !calibrationIdentified { missing.append("Exact calibration fingerprint") }
        if !buildRevisionIdentified { missing.append("Exact build revision") }
        if !unresolvedDiagnosticBlockers.isEmpty { blockers.append("Resolve diagnostic blockers before calibration experiment") }
        return .init(ready:missing.isEmpty && blockers.isEmpty,missing:missing,blockers:Array(Set(blockers)).sorted(),warnings:[],boundary:"Contract readiness means the planned evidence is structurally adequate for the stated experiment. It is not permission to use unsafe values or bypass mechanical diagnosis.")
    }
}

struct FordTorqueEvidenceNode: Identifiable, Codable { let id:String; let label:String; let semanticIDs:[String]; let observed:Bool; let evidenceLocators:[String] }
struct FordTorqueEvidenceGraph: Codable { let controller:TuningControllerFamily; let nodes:[FordTorqueEvidenceNode]; let missingSemantics:[String]; let boundary:String }
enum FordTorqueEvidenceGraphEngine {
    static func build(controller:TuningControllerFamily, reviews:[VCMScannerSemanticReview]) -> FordTorqueEvidenceGraph {
        let admitted=reviews.filter{$0.admittedForAnalysis && $0.binding.controller == controller}
        let stages:[(String,String,[String])] = [
            ("driver","Driver Demand",["driver.pedal"]),("request","Torque Request / Limit",["torque.request_or_limit"]),("throttle","Throttle / Air Realization",["throttle.command_or_angle"]),("spark","Spark Response",["spark.command_or_delivered"]),("lambda","Fuel / Lambda Response",["lambda.commanded_and_or_measured"]),("thermal","Thermal Context",["charge.temperature","coolant.temperature"])]
        var missing:[String]=[]
        let nodes=stages.map { s -> FordTorqueEvidenceNode in
            let matches = admitted.filter { review in
                guard let signalID = review.binding.canonicalSignalID else { return false }
                return s.2.contains(signalID)
            }
            if matches.isEmpty { missing.append(contentsOf:s.2) }
            return .init(id:s.0,label:s.1,semanticIDs:s.2,observed:!matches.isEmpty,evidenceLocators:matches.compactMap { $0.exactLocator })
        }
        return .init(controller:controller,nodes:nodes,missingSemantics:Array(Set(missing)).sorted(),boundary:"Observed nodes show available reviewed evidence only. Edges between nodes remain hypotheses unless separately supported; chronology does not prove Ford arbitration logic or causation.")
    }
}

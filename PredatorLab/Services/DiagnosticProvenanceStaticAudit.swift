import Foundation

struct DiagnosticProvenanceFinding: Identifiable, Codable, Equatable {
    let id: String
    let severity: String
    let location: String
    let message: String
}

enum DiagnosticProvenanceStaticAudit {
    /// Platform-neutral source-text audit. It deliberately reports candidates for human review;
    /// it does not infer that UI wording is a diagnostic conclusion merely from keywords.
    static func scanSwiftSource(_ text: String, location: String) -> [DiagnosticProvenanceFinding] {
        let lower=text.lowercased()
        let conclusionWords=["root cause","confirmed fault","proves","definitely failed","repair validated"]
        guard conclusionWords.contains(where: lower.contains) else { return [] }
        let hasBoundary = lower.contains("evidence boundary") || lower.contains("does not prove") || lower.contains("causation") || lower.contains("causal boundary") || lower.contains("provenance")
        if hasBoundary { return [] }
        return [.init(id:"provenance.\(location)",severity:"review",location:location,message:"Conclusion-like language appears without an adjacent provenance/causality boundary marker; review before release.")]
    }
}

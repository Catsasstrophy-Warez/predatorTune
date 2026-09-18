import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct GT500EvidenceArtifactRev76: Identifiable, Codable, Hashable {
    enum Kind: String, Codable { case scannerXML, scannerCSV, hpl, hpt, markdown, archive }
    let id: String
    let kind: Kind
    let filename: String
    let role: String
    let directlyParseable: Bool
    let authority: String
    let boundary: String
}

struct ScannerIntervalBucketRev76: Codable, Hashable {
    let intervalSeconds: Double?
    let parameterIDs: [String]
}

struct ScannerConfigInventoryRev76: Codable, Hashable {
    let channelCount: Int
    let placeholderParameterZeroCount: Int
    let intervalBuckets: [ScannerIntervalBucketRev76]
    let warnings: [String]
    let boundary: String
}

enum ScannerConfigInventoryEngineRev76 {
    static func inspect(xml: String) -> ScannerConfigInventoryRev76 {
        let pattern = #"<channel\s+ParameterID=\"([^\"]+)\"(?:\s+Interval=\"([^\"]+)\")?\s*/>"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let ns = xml as NSString
        let matches = regex?.matches(in: xml, range: NSRange(location: 0, length: ns.length)) ?? []
        var grouped: [Double?: [String]] = [:]
        var zeros = 0
        for match in matches {
            let pid = ns.substring(with: match.range(at: 1))
            if pid == "0" { zeros += 1 }
            var seconds: Double? = nil
            if match.range(at: 2).location != NSNotFound {
                let raw = ns.substring(with: match.range(at: 2))
                seconds = parseInterval(raw)
            }
            grouped[seconds, default: []].append(pid)
        }
        let buckets = grouped.map { ScannerIntervalBucketRev76(intervalSeconds: $0.key, parameterIDs: $0.value) }
            .sorted { ($0.intervalSeconds ?? .greatestFiniteMagnitude) < ($1.intervalSeconds ?? .greatestFiniteMagnitude) }
        var warnings: [String] = []
        if zeros > 0 { warnings.append("ParameterID 0 entries are preserved as unresolved/placeholders; PredatorLab does not assign semantics to them.") }
        if matches.isEmpty { warnings.append("No channel elements matched the supported Scanner XML subset.") }
        return .init(channelCount: matches.count, placeholderParameterZeroCount: zeros, intervalBuckets: buckets, warnings: warnings, boundary: "Parameter IDs and polling intervals are observations from the supplied XML. They do not establish Ford physical meaning, HP Tuners display labels, controller strategy, units, source type, or safety thresholds.")
    }
    private static func parseInterval(_ raw: String) -> Double? {
        let parts = raw.split(separator: ":")
        guard parts.count == 3 else { return nil }
        let h = Double(parts[0]) ?? 0, m = Double(parts[1]) ?? 0, s = Double(parts[2]) ?? 0
        return h * 3600 + m * 60 + s
    }
}

struct GT500RealEvidenceBundleRev76: Codable, Hashable {
    let artifacts: [GT500EvidenceArtifactRev76]
    let researchClaimsRequiringPromotion: [String]
    let observedLogFacts: [String]
    let nextActions: [String]
    let boundary: String
}

enum GT500RealEvidenceFactoryRev76 {
    static let bundle = GT500RealEvidenceBundleRev76(
        artifacts: [
            .init(id:"scanner-xml",kind:.scannerXML,filename:"shelbygt500.1.Channels.xml",role:"Observed Scanner channel/polling contract",directlyParseable:true,authority:"user-supplied artifact",boundary:"IDs/intervals only until semantic review"),
            .init(id:"sep1",kind:.scannerCSV,filename:"sep1.csv",role:"Low/moderate-load and heat-soak evidence",directlyParseable:true,authority:"vehicle observation",boundary:"Not sufficient for high-load torque validation"),
            .init(id:"sep2",kind:.scannerCSV,filename:"sep2.csv",role:"High-load/shift event evidence",directlyParseable:true,authority:"vehicle observation",boundary:"Channel semantics remain independently reviewable"),
            .init(id:"hpl1",kind:.hpl,filename:"log-000000-20260911-225621-*.hpl",role:"Original HP Tuners log artifact",directlyParseable:false,authority:"original evidence",boundary:"No proprietary HPL decoding claimed"),
            .init(id:"hpl2",kind:.hpl,filename:"log-000002-20260911-235344-*.hpl",role:"Original HP Tuners log artifact",directlyParseable:false,authority:"original evidence",boundary:"No proprietary HPL decoding claimed"),
            .init(id:"stock-hpt",kind:.hpt,filename:"stockgt500.hpt",role:"Original calibration artifact",directlyParseable:false,authority:"original evidence",boundary:"No proprietary HPT decoding claimed")
        ],
        researchClaimsRequiringPromotion: [
            "Specific PID-to-physical-semantic mappings beyond independently verified HP Tuners/Ford documentation",
            "Fixed GT500-safe polling rates or guaranteed MPVI4 acquisition frequency",
            "Specific PCM torque-model causal edges, IPC thresholds, and table semantics",
            "TR_C75 clutch-pressure values, pressure-change percentages, slip thresholds, and durability limits",
            "Universal lambda, spark, fuel-pressure, or torque acceptance thresholds"
        ],
        observedLogFacts: [
            "sep1 and sep2 are reported as 61-column HP Tuners CSV exports in the supplied project analysis.",
            "sep2 contains a short high-load event with an observed 'Insufficient Fuel Flow' source label overlapping transmission shift choreography.",
            "The supplied analysis reports no positive knock-retard observation in the central sep2 event and rising logged fuel-pressure values during the labeled protection interval.",
            "A second wideband-like channel is reported to behave anomalously during the shift and remains a semantic/scaling verification target."
        ],
        nextActions: [
            "Import the supplied Scanner XML and fingerprint it byte-for-byte.",
            "Bind only independently reviewed Parameter IDs to canonical semantics.",
            "Run sep1/sep2 through the existing CSV parser and preserve row/time alignment and missing values.",
            "Create matched event episodes around the sep2 high-load/shift interval and first-out chronology.",
            "Treat the 'Insufficient Fuel Flow' label as an observed controller/source label, not proof of physical fuel starvation.",
            "Use the stock HPT and HPL files as immutable hashed originals until supported export/metadata paths provide interpretable content.",
            "Benchmark the exact XML on the real MPVI4/GT500 before changing polling intervals based on theory."
        ],
        boundary: "Rev76 promotes the supplied Drive bundle into PredatorLab's evidence architecture without treating authored tuning notes as OEM truth. Observations, user-authored guidance, HP Tuners documentation, Ford documentation, and PredatorLab inference remain separate."
    )
}

import SwiftUI

struct PLGoldenCorpusFlagshipCaseRev134: View {
    let investigation: GoldenCorpusFlagshipInvestigationRev134
    var body: some View {
        PLInstrumentChrome {
            VStack(alignment: .leading, spacing: 6) {
                Text("FLAGSHIP A/B FORENSIC CASE").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(.plBoost)
                Text("A  \(investigation.episodeA.start, specifier: "%.3f")–\(investigation.episodeA.end, specifier: "%.3f") s   •   B  \(investigation.episodeB.start, specifier: "%.3f")–\(investigation.episodeB.end, specifier: "%.3f") s").font(.system(size: 7, weight: .bold, design: .monospaced))
                Text("ALIGNMENT  \(investigation.comparison.method.rawValue.uppercased())").font(.system(size: 7, design: .monospaced)).foregroundStyle(.plTextSecondary)
                ForEach(investigation.findings.prefix(8)) { finding in
                    VStack(alignment: .leading, spacing: 1) {
                        Text("DERIVED  \(finding.channel)").font(.system(size: 7, weight: .bold, design: .monospaced))
                        Text(finding.summary).font(.system(size: 7, design: .monospaced)).foregroundStyle(.plTextSecondary)
                    }
                }
                Text("BLOCKED: DCT slip/verified shift-phase reconstruction").font(.system(size: 7, weight: .bold, design: .monospaced)).foregroundStyle(.plWarning)
                Text(investigation.boundary).font(.system(size: 6, design: .monospaced)).foregroundStyle(.plTextSecondary)
            }
        }.accessibilityIdentifier("analysis.flagshipABCase")
    }
}

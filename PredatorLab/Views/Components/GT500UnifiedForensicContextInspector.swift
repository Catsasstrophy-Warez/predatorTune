import SwiftUI

struct GT500UnifiedForensicContextInspector: View {
    let cursor: ForensicCursorRev85
    let selection: ForensicSelectionContext
    private var context: GT500UnifiedForensicContext { GT500TwinUnifiedForensicContextEngine.build(cursor: cursor, selection: selection) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "scope").foregroundStyle(.plBoost)
                Text("SYNCHRONIZED CONTEXT").font(.system(size: 9, weight: .black, design: .monospaced))
                Spacer()
                if let t = context.time { Text(String(format: "T+%.3fs", t)).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary) }
            }
            if context.activeBands.isEmpty {
                Text("Cursor is outside the admitted Golden Corpus A/B navigation windows.").font(.caption2).foregroundStyle(.secondary)
            } else {
                ForEach(context.activeBands) { band in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(band.title).font(.caption.bold())
                        Text(band.authority).font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(.purple)
                        Text(band.boundary).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                if let comparison = context.comparisonWindow { Label(comparison, systemImage: "arrow.left.arrow.right").font(.caption2).foregroundStyle(.plBoost) }
            }
            if !context.calibrationLinks.isEmpty {
                Divider(); Text("CALIBRATION RELATIONSHIPS").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(.plIgnition)
                ForEach(context.calibrationLinks) { link in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(link.title).font(.caption.bold())
                        Text(link.reason).font(.caption2).foregroundStyle(.secondary)
                        Text(link.authority).font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(.orange)
                    }
                }
            }
            if !context.missingMeasurements.isEmpty {
                Divider(); Text("BEST MISSING DISCRIMINATORS").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(.orange)
                ForEach(context.missingMeasurements.prefix(6), id: \.self) { Text("• \($0)").font(.caption2).foregroundStyle(.secondary) }
            }
            Text(context.boundary).font(.caption2).foregroundStyle(.orange)
        }
        .padding(11).background(Color.plSurface).clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("workstation.synchronizedContext")
    }
}

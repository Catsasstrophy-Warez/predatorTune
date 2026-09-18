import SwiftUI

/// Rev158 visual primitives. These components are presentation-only and never elevate
/// telemetry, hypotheses, Twin relevance, or calibration relationships to a higher authority.
struct PLVisualPanel<Content: View>: View {
    var accent: Color = .plBoost
    var padding: CGFloat = 14
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.plSurface.opacity(0.96))
                    LinearGradient(
                        colors: [accent.opacity(0.10), .clear, Color.black.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .overlay(alignment: .top) {
                Rectangle().fill(accent.opacity(0.55)).frame(height: 1)
                    .clipShape(Capsule()).padding(.horizontal, 18)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.plStroke.opacity(0.9), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.22), radius: 12, y: 7)
    }
}

struct PLStatusChip: View {
    let title: String
    var icon: String? = nil
    var accent: Color = .plBoost
    var filled = false
    var body: some View {
        HStack(spacing: 5) {
            if let icon { Image(systemName: icon).font(.system(size: 9, weight: .black)) }
            Text(title.uppercased()).font(.system(size: 9, weight: .black, design: .monospaced)).lineLimit(1)
        }
        .foregroundStyle(filled ? Color.plBackground : accent)
        .padding(.horizontal, 9).padding(.vertical, 6)
        .background(filled ? accent : accent.opacity(0.10))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(accent.opacity(0.42), lineWidth: 1))
    }
}

struct PLCommandStrip: View {
    let title: String
    let context: String
    var accent: Color = .plBoost
    var chips: [(String, String, Color)] = []
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(accent.opacity(0.14))
                Image(systemName: "scope").foregroundStyle(accent)
            }.frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 1) {
                Text(title.uppercased()).font(.system(size: 10, weight: .black, design: .monospaced)).foregroundStyle(accent)
                Text(context).font(.plCaption).foregroundStyle(.plTextPrimary).lineLimit(1)
            }
            Spacer(minLength: 6)
            ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                PLStatusChip(title: chip.0, icon: chip.1, accent: chip.2)
            }
        }
        .padding(10)
        .background(Color.plSurface.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.plStroke.opacity(0.9)))
    }
}

struct PLAuthorityBoundaryBanner: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "checkmark.shield.fill").foregroundStyle(.plWarning)
            VStack(alignment: .leading, spacing: 2) {
                Text("AUTHORITY BOUNDARY").font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(.plWarning)
                Text(text).font(.caption2).foregroundStyle(.plTextSecondary)
            }
            Spacer()
        }
        .padding(10).background(Color.plWarning.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.plWarning.opacity(0.25)))
    }
}

struct PLTelemetryLegend: View {
    let items: [(String, Color)]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 5) {
                        Capsule().fill(item.1).frame(width: 14, height: 3)
                        Text(item.0).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.plTextSecondary)
                    }
                }
            }
        }
    }
}


/// Compact persistent context bar for the current forensic moment.
struct PLForensicContextBar: View {
    let time: TimeInterval?
    let workspace: String
    var event: String? = nil
    var body: some View {
        HStack(spacing: 8) {
            PLStatusChip(title: time.map { String(format:"T+%.3F S",$0) } ?? "NO CURSOR", icon:"scope", accent:.plBoost, filled: time != nil)
            Text(workspace.uppercased()).font(.system(size:9,weight:.black,design:.monospaced)).foregroundStyle(.plTextPrimary).lineLimit(1)
            if let event { Text("• \(event)").font(.caption2).foregroundStyle(.plTextSecondary).lineLimit(1) }
            Spacer()
            Text("CONTEXT ≠ CAUSALITY").font(.system(size:8,weight:.black,design:.monospaced)).foregroundStyle(.plWarning)
        }
        .padding(.horizontal,10).padding(.vertical,7)
        .background(Color.plSurface.opacity(0.94))
        .overlay(alignment:.bottom){ Rectangle().fill(Color.plStroke).frame(height:1) }
    }
}

struct PLInspectorSectionHeader: View {
    let step: Int; let title: String; let icon: String; var accent: Color = .plBoost
    var body: some View {
        HStack(spacing:8) {
            Text(String(format:"%02d",step)).font(.system(size:9,weight:.black,design:.monospaced)).foregroundStyle(accent)
                .frame(width:24,height:24).background(accent.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius:7))
            Label(title.uppercased(),systemImage:icon).font(.system(size:9,weight:.black,design:.monospaced)).foregroundStyle(accent)
            Spacer()
        }
    }
}

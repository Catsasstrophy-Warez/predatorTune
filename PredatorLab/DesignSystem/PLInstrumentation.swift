// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import SwiftUI

// Dense forensic instrumentation inspired by the supplied PredatorLab atlas and
// telemetry reference. No third-party branding or unsupported transport claims.

enum PLInstrumentStatus: String, CaseIterable, Sendable {
    case observed = "OBSERVED", derived = "DERIVED", candidate = "CANDIDATE"
    case verified = "VERIFIED", experimental = "EXPERIMENTAL", unknown = "UNKNOWN"
    var color: Color {
        switch self {
        case .observed: return .plBoost
        case .derived: return .plIgnition
        case .candidate, .experimental: return .plWarning
        case .verified: return .plSuccess
        case .unknown: return .plTextSecondary
        }
    }
}

struct PLInstrumentChrome<Content: View>: View {
    var accent: Color = .plBoost
    var padding: CGFloat = 12
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(padding)
            .background(LinearGradient(colors:[Color.plSurfaceRaised.opacity(0.78),Color.plSurface.opacity(0.96)],
                                       startPoint:.topLeading,endPoint:.bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius:10,style:.continuous))
            .overlay(RoundedRectangle(cornerRadius:10).stroke(Color.plStroke.opacity(0.9),lineWidth:1))
            .overlay(alignment:.top){Rectangle().fill(accent.opacity(0.55)).frame(height:1)}
    }
}

struct PLInstrumentStatusChip: View {
    let status: PLInstrumentStatus
    var body: some View {
        Text(status.rawValue).font(.system(size:9,weight:.black,design:.monospaced)).tracking(0.6)
            .foregroundStyle(status.color).padding(.horizontal,7).padding(.vertical,4)
            .background(status.color.opacity(0.10),in:Capsule())
            .overlay(Capsule().stroke(status.color.opacity(0.35),lineWidth:1))
    }
}

struct PLMetricReadout: View {
    let label:String; let value:String
    var unit:String?=nil; var accent:Color = .plBoost
    var status:PLInstrumentStatus = .observed
    var body: some View {
        VStack(alignment:.leading,spacing:4) {
            HStack {
                Text(label.uppercased()).font(.system(size:9,weight:.bold,design:.monospaced))
                    .foregroundStyle(accent).lineLimit(1)
                Spacer(); Circle().fill(status.color).frame(width:5,height:5)
            }
            HStack(alignment:.firstTextBaseline,spacing:3) {
                Text(value).font(.plGauge(22)).foregroundStyle(.plTextPrimary).minimumScaleFactor(0.6)
                if let unit { Text(unit).font(.plMono(9)).foregroundStyle(.plTextSecondary) }
            }
        }.padding(9).background(Color.black.opacity(0.18),in:RoundedRectangle(cornerRadius:8))
         .overlay(RoundedRectangle(cornerRadius:8).stroke(Color.plStroke.opacity(0.8),lineWidth:1))
    }
}


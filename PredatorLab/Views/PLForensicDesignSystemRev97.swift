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

struct PLWorkstationHeader: View {
    let title: String
    var subtitle = "Acquire → Verify → Investigate → Experiment → Validate"
    var status: PLInstrumentStatus = .observed
    var body: some View {
        HStack(spacing:12) {
            VStack(alignment:.leading,spacing:2) {
                Text("PREDATORLAB").font(.system(size:17,weight:.black,design:.rounded)).italic()
                    .foregroundStyle(.plBoost).tracking(0.7)
                Text("TRUTH IN PERFORMANCE").font(.system(size:8,weight:.bold,design:.monospaced))
                    .foregroundStyle(.plTextSecondary).tracking(1.4)
            }
            Rectangle().fill(Color.plStroke).frame(width:1,height:32)
            VStack(alignment:.leading,spacing:2) {
                Text(title).font(.system(size:16,weight:.bold,design:.rounded)).foregroundStyle(.plTextPrimary)
                Text(subtitle).font(.system(size:9,weight:.medium,design:.monospaced)).foregroundStyle(.plTextSecondary)
            }
            Spacer()
            PLInstrumentStatusChip(status:status)
        }.padding(.horizontal,12).padding(.vertical,9)
         .background(Color.plBackground.opacity(0.98))
         .overlay(alignment:.bottom){Rectangle().fill(Color.plStroke).frame(height:1)}
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

struct PLWorkspaceRail: View {
    @Binding var selection: PredatorWorkspaceRev85
    var body: some View {
        VStack(spacing:6) {
            ForEach(PredatorWorkspaceRev85.allCases) { item in
                Button { selection=item } label: {
                    HStack(spacing:9) {
                        Image(systemName:item.systemImage).frame(width:18)
                        Text(item.rawValue).font(.system(size:12,weight:.semibold,design:.rounded)); Spacer()
                    }.foregroundStyle(selection == item ? Color.white : Color.plTextSecondary)
                     .padding(.horizontal,10).frame(minHeight:40)
                     .background(selection == item ? Color.plBoost.opacity(0.20) : Color.clear,in:RoundedRectangle(cornerRadius:8))
                     .overlay(RoundedRectangle(cornerRadius:8).stroke(selection == item ? Color.plBoost.opacity(0.65) : Color.clear,lineWidth:1))
                }.buttonStyle(.plain)
            }
            Spacer()
            VStack(alignment:.leading,spacing:2) {
                Text("GT500").font(.plMono(12)).foregroundStyle(.plBoost)
                Text("FORENSIC WORKSPACE").font(.system(size:8,weight:.bold,design:.monospaced)).foregroundStyle(.plTextSecondary)
            }.frame(maxWidth:.infinity,alignment:.leading).padding(10)
        }.padding(8).background(Color.plSurface.opacity(0.82))
    }
}

struct PLCompactWorkspaceBar: View {
    @Binding var selection: PredatorWorkspaceRev85
    var body: some View {
        ScrollView(.horizontal,showsIndicators:false) {
            HStack(spacing:6) {
                ForEach(PredatorWorkspaceRev85.allCases) { item in
                    Button { selection=item } label: {
                        Label(item.rawValue,systemImage:item.systemImage).font(.system(size:11,weight:.semibold))
                            .padding(.horizontal,10).frame(height:34)
                            .foregroundStyle(selection == item ? Color.white : Color.plTextSecondary)
                            .background(selection == item ? Color.plBoost.opacity(0.22) : Color.plSurface,in:RoundedRectangle(cornerRadius:7))
                            .overlay(RoundedRectangle(cornerRadius:7).stroke(selection == item ? Color.plBoost.opacity(0.7) : Color.plStroke,lineWidth:1))
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal,10)
        }.padding(.vertical,6).background(Color.plBackground)
    }
}

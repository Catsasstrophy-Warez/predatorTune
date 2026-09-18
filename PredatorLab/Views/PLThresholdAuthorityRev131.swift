import SwiftUI
struct PLThresholdAuthorityRev131:View {
 let thresholds:GT500EpisodeThresholdSetRev131
 var body:some View{PLInstrumentChrome{VStack(alignment:.leading,spacing:4){
  Text("DETECTION PARAMETERS").font(.system(size:8,weight:.black,design:.monospaced)).foregroundStyle(.plBoost)
  row("High-demand pedal",thresholds.highDemandPedal);row("High-demand throttle",thresholds.highDemandThrottle);row("Throttle disagreement",thresholds.throttleDifference);row("Rapid RPM exported-row delta",thresholds.accelerationRPMDelta);row("Episode merge gap",thresholds.episodeMergeGap);row("IAT2 comparison context",thresholds.thermalIAT2Context)
 }}.accessibilityIdentifier("forensic.thresholdAuthority")}
 @ViewBuilder private func row(_ name:String,_ t:DetectionThresholdRev131)->some View{VStack(alignment:.leading,spacing:1){HStack{Text(name).font(.system(size:7));Spacer();Text("\(t.value,specifier:"%.2f") \(t.units) · \(t.source.rawValue.uppercased())").font(.system(size:6,weight:.bold,design:.monospaced))};Text(t.authorityBoundary).font(.system(size:6)).foregroundStyle(.plTextSecondary)}}
}

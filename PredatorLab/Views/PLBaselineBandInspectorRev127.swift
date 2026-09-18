import SwiftUI
struct PLBaselineBandInspectorRev127:View {
 let context:EpisodeCursorContextRev123
 let profile:VehicleBaselineProfile?
 var body:some View {
  PLInstrumentChrome {
   VStack(alignment:.leading,spacing:4) {
    Text("VEHICLE HISTORY BASELINE").font(.system(size:8,weight:.black,design:.monospaced)).foregroundStyle(.plBoost)
    if let profile {
     let result=EpisodeBaselineEvidenceEngineRev124.compare(context:context,profile:profile)
     ForEach(result.deviations.prefix(10),id:\.metricID) { d in
      HStack {
       Text(d.metricID).font(.system(size:7));Spacer()
       Text(d.grade.rawValue).font(.system(size:7,weight:.bold,design:.monospaced))
       if let x=d.delta {Text(String(format:"%+.2f",x)).font(.system(size:7,design:.monospaced))}
      }
     }
     Text(result.boundary).font(.system(size:7)).foregroundStyle(.plTextSecondary)
    } else {
     Text("No applicable vehicle/build baseline attached. No population or OEM band substituted.").font(.system(size:7)).foregroundStyle(.plTextSecondary)
    }
   }
  }
 }
}

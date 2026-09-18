import Foundation

struct ParsedLogForensicSessionRev125:Sendable {
 let series:[TimelineSeriesRev117];let episodes:[GT500EpisodeRev122];let channelUnits:[String:String]
}
enum ParsedLogForensicBridgeRev125 {
 static let preferredChannels=["Engine RPM (SAE)","Accelerator Position D (SAE)","Throttle Desired Angle","Throttle Angle","Fuel Pressure (SAE)","Knock Correction (+Adv/-Ret)","Scheduled Torque","Engine Brake Torque","Intake Air Temp 2","Engine Coolant Temp"]
 static func build(_ log:ParsedLogData)->ParsedLogForensicSessionRev125 {
  let names=preferredChannels.filter{log.channels.contains($0)}
  let series=names.map{name in TimelineSeriesRev117(id:name,points:log.timestamps.indices.compactMap{i in
   guard i<log.timestamps.count,let v=log.numericValue(channel:name,row:i),v.isFinite else{return nil};return TelemetryPointRev116(time:log.timestamps[i],value:v)
  })}
  return .init(series:series,episodes:segment(log),channelUnits:[:])
 }
 static func segment(_ log:ParsedLogData,thresholds:GT500EpisodeThresholdSetRev131 = .analysisDefaults)->[GT500EpisodeRev122] {
  guard thresholds.usable else{return []}
  var marks:[(Double,GT500EpisodeKindRev122,String)]=[];var previous:[String:String]=[:]
  let sourceNames=["Torque Source","Torque Max Source","Torque Max Protection Source","Throttle Angle Source","Spark Source","RPM Limit Source"]
  for i in log.timestamps.indices {
   let t=log.timestamps[i]
   if let pedal=log.numericValue(channel:"Accelerator Position D (SAE)",row:i),let throttle=log.numericValue(channel:"Throttle Angle",row:i),pedal>=thresholds.highDemandPedal.value,throttle>=thresholds.highDemandThrottle.value{marks.append((t,.highDemand,"high pedal + high throttle"))}
   if let d=log.numericValue(channel:"Throttle Desired Angle",row:i),let a=log.numericValue(channel:"Throttle Angle",row:i),abs(d-a)>=thresholds.throttleDifference.value{marks.append((t,.throttleDisagreement,"desired/actual throttle disagreement"))}
   if let temp=log.numericValue(channel:"Intake Air Temp 2",row:i),temp>=thresholds.thermalIAT2Context.value{marks.append((t,.thermalHighContext,"elevated IAT2 analysis context"))}
   if i>0,let rpm=log.numericValue(channel:"Engine RPM (SAE)",row:i),let prior=log.numericValue(channel:"Engine RPM (SAE)",row:i-1),rpm-prior>=thresholds.accelerationRPMDelta.value{marks.append((t,.acceleration,"rapid RPM exported-row step"))}
   for n in sourceNames {if let v=log.stringValue(channel:n,row:i),!v.isEmpty{if let old=previous[n],old != v{marks.append((t,.sourceActivity,"\(n): \(old) → \(v)"))};previous[n]=v}}
  }
  var out:[GT500EpisodeRev122]=[];for (kind,items) in Dictionary(grouping:marks,by:{$0.1}){let sorted=items.sorted{$0.0<$1.0};var cluster:[(Double,GT500EpisodeKindRev122,String)]=[]
   func emit(){guard let a=cluster.first,let z=cluster.last else{return};out.append(.init(id:"\(kind.rawValue)-\(a.0)",kind:kind,start:a.0,end:z.0,peakTime:a.0,observations:cluster.count,evidence:Array(Set(cluster.map{$0.2})).sorted(),boundary:GT500EpisodeSegmenterRev122.boundary(kind,.init())));cluster=[]}
   for x in sorted{if let last=cluster.last,x.0-last.0>thresholds.episodeMergeGap.value{emit()};cluster.append(x)};emit()}
  return out.sorted{$0.start<$1.start}
 }
 }

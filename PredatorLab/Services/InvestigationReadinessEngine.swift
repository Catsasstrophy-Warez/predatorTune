import Foundation
struct ChannelRequirement: Codable, Equatable { let channel:CanonicalChannel; let minimumCoverage:Double; let minimumHz:Double?; let maximumGap:TimeInterval?; let critical:Bool }
struct InvestigationReadinessReport: Codable, Equatable { let score:Double; let criticalFailures:[String]; let warnings:[String]; var readyForStrongInference:Bool { criticalFailures.isEmpty && score >= 0.80 } }
enum InvestigationReadinessEngine {
 static func evaluate(_ report:AcquisitionQualityReport, requirements:[ChannelRequirement])->InvestigationReadinessReport {
   var earned=0.0, possible=0.0; var failures:[String]=[], warnings:[String]=[]
   for r in requirements { let weight=r.critical ? 2.0:1.0; possible += weight; guard let q=report.channels.first(where:{$0.canonical==r.channel}), q.rawName != nil else { let s="Missing \(r.channel.rawValue)."; r.critical ? failures.append(s):warnings.append(s); continue }
     var ok=q.coverage >= r.minimumCoverage; if let hz=r.minimumHz { ok = ok && (q.estimatedHz ?? 0) >= hz }; if let gap=r.maximumGap, let actual=q.longestGap { ok = ok && actual <= gap }
     if ok { earned += weight } else { let s="\(r.channel.rawValue) does not meet acquisition requirements."; r.critical ? failures.append(s):warnings.append(s) }
   }
   return .init(score:possible > 0 ? earned/possible:0, criticalFailures:failures, warnings:warnings)
 }
 static let r04:[ChannelRequirement] = [
  .init(channel:.engineRPM,minimumCoverage:0.98,minimumHz:10,maximumGap:0.20,critical:true), .init(channel:.gearActual,minimumCoverage:0.95,minimumHz:10,maximumGap:0.20,critical:true),
  .init(channel:.injectorPulseWidth,minimumCoverage:0.98,minimumHz:20,maximumGap:0.10,critical:true), .init(channel:.maximumInjectorPulseWidth,minimumCoverage:0.95,minimumHz:20,maximumGap:0.10,critical:true),
  .init(channel:.fuelPressureCommanded,minimumCoverage:0.95,minimumHz:20,maximumGap:0.10,critical:true), .init(channel:.fuelPressureActual,minimumCoverage:0.95,minimumHz:20,maximumGap:0.10,critical:true),
  .init(channel:.lambdaCommanded,minimumCoverage:0.90,minimumHz:10,maximumGap:0.20,critical:false), .init(channel:.lambdaMeasured,minimumCoverage:0.90,minimumHz:10,maximumGap:0.20,critical:false),
  .init(channel:.torqueProtectionSource,minimumCoverage:0.90,minimumHz:nil,maximumGap:0.25,critical:true)]
}

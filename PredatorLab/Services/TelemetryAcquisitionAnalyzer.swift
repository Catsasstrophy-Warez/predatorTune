// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import Foundation

struct ObservedSampleRate:Identifiable,Equatable,Sendable {
    let id:String;let channelName:String;let sampleCount:Int;let medianInterval:Double?
    let observedHz:Double?;let p95Interval:Double?;let maximumGap:Double?
}

enum TelemetryAcquisitionAnalyzer {
    static func analyze(_ session:ForensicSessionDatasetRev85)->[ObservedSampleRate] {
        session.series.map { series in
            let deltas=zip(series.samples.dropFirst(),series.samples).map{$0.0.time-$0.1.time}.filter{$0>0}.sorted()
            let median=percentile(deltas,0.5),p95=percentile(deltas,0.95)
            return .init(id:series.id,channelName:series.descriptor.displayName,sampleCount:series.samples.count,
                         medianInterval:median,observedHz:median.flatMap{$0>0 ? 1/$0:nil},p95Interval:p95,maximumGap:deltas.last)
        }
    }
    private static func percentile(_ x:[Double],_ p:Double)->Double? {
        guard !x.isEmpty else{return nil};let i=min(x.count-1,max(0,Int((Double(x.count-1)*p).rounded())));return x[i]
    }
}

struct ChannelBudgetAssessment:Equatable,Sendable {
    let fast:Int;let medium:Int;let slow:Int;let unknown:Int;let pressure:String;let recommendations:[String]
}
enum ChannelBudgetAnalyzer {
    static func assess(configured:[ScannerConfiguredChannel],catalog:[ValuableLoggingChannel]=ValuableLoggingChannelCatalog.gt500Testing)->ChannelBudgetAssessment {
        var fast=0,medium=0,slow=0,unknown=0
        for c in configured {
            let text=c.displayName.lowercased()
            let match=catalog.first{item in item.searchTerms.contains{term in text.contains(term.lowercased()) || term.lowercased().contains(text)}}
            switch match?.cadence {
            case "fast":fast+=1
            case "medium":medium+=1
            case "slow":slow+=1
            default:unknown+=1
            }
        }
        var rec:[String]=[]
        if fast>18 { rec.append("Large fast-channel set: verify observed sample intervals and remove non-discriminating polled channels before assuming adequate temporal resolution.") }
        if unknown>0 { rec.append("\(unknown) configured channel(s) have no cadence classification; inspect them manually.") }
        if slow>0 { rec.append("Slow-changing context channels may tolerate longer polling intervals when the exact Scanner source supports polling control.") }
        let pressure = fast>24 ? "VERY HIGH" : fast>18 ? "HIGH" : fast>12 ? "MODERATE" : "LEAN"
        return .init(fast:fast,medium:medium,slow:slow,unknown:unknown,pressure:pressure,recommendations:rec)
    }
}

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import Foundation

struct FixtureAcquisitionSummary:Equatable,Sendable {
    let channelCount:Int;let rowCount:Int;let duration:Double?
    let medianRowInterval:Double?;let observedRowHz:Double?;let maximumRowGap:Double?
    let boundary:String
}
enum RealFixtureAcquisitionAuditRev109 {
    static func summarize(_ dataset:ParsedLogData)->FixtureAcquisitionSummary {
        let ts=dataset.timestamps
        let d=zip(ts.dropFirst(),ts).map{$0.0-$0.1}.filter{$0>0}.sorted()
        let median=d.isEmpty ? nil:d[d.count/2]
        return .init(channelCount:dataset.channels.count,rowCount:ts.count,
                     duration:ts.count>1 ? ts.last!-ts.first!:nil,
                     medianRowInterval:median,observedRowHz:median.flatMap{$0>0 ? 1/$0:nil},
                     maximumRowGap:d.last,
                     boundary:"Observed row timing comes from the imported fixture timestamps and does not establish per-channel device polling rate.")
    }
}

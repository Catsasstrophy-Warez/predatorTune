import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct TimelineRenderBenchmarkRev85: Codable, Sendable {
    let inputPoints: Int
    let outputPoints: Int
    let elapsedMilliseconds: Double
}
enum ForensicTimelineLODRev85 {
    /// Preserves extrema per bucket so transient spikes survive display downsampling.
    static func minMaxDownsample(_ samples:[ForensicTimelineSampleRev85], targetPoints:Int) -> [ForensicTimelineSampleRev85] {
        guard targetPoints >= 4, samples.count > targetPoints else { return samples }
        let buckets=max(1,targetPoints/2); let width=Double(samples.count)/Double(buckets); var out:[ForensicTimelineSampleRev85]=[]; out.reserveCapacity(targetPoints)
        for b in 0..<buckets { let lo=Int(Double(b)*width), hi=min(samples.count,Int(Double(b+1)*width)); guard lo<hi else{continue}; let slice=samples[lo..<hi]; if let mn=slice.min(by:{$0.value<$1.value}), let mx=slice.max(by:{$0.value<$1.value}) { if mn.time <= mx.time { out.append(mn); if mn.id != mx.id { out.append(mx) } } else { out.append(mx); if mn.id != mx.id { out.append(mn) } } } }
        return out.sorted{$0.time<$1.time}
    }
    static func benchmark(_ samples:[ForensicTimelineSampleRev85], targetPoints:Int=4000) -> TimelineRenderBenchmarkRev85 {
        let start=DispatchTime.now().uptimeNanoseconds; let reduced=minMaxDownsample(samples,targetPoints:targetPoints); let end=DispatchTime.now().uptimeNanoseconds
        return .init(inputPoints:samples.count,outputPoints:reduced.count,elapsedMilliseconds:Double(end-start)/1_000_000)
    }
}

import Foundation

struct EffectSizeSummary: Codable, Equatable {
    let baselineCount: Int
    let validationCount: Int
    let medianDelta: Double?
    let cliffsDelta: Double?
    let magnitude: String
    let warnings: [String]
}

enum EffectSizeEngine {
    /// Distribution-free Cliff's delta. It describes separation between two observed cohorts;
    /// it does not establish causation or statistical significance.
    static func compare(baseline: [Double], validation: [Double]) -> EffectSizeSummary {
        let a=baseline.filter(\.isFinite), b=validation.filter(\.isFinite)
        guard !a.isEmpty, !b.isEmpty else { return .init(baselineCount:a.count,validationCount:b.count,medianDelta:nil,cliffsDelta:nil,magnitude:"Unavailable",warnings:["Both cohorts require finite observations."]) }
        func median(_ x:[Double])->Double { let s=x.sorted(), n=s.count; return n % 2 == 1 ? s[n/2] : (s[n/2-1]+s[n/2])/2 }
        var greater:Int64=0, less:Int64=0
        for x in b { for y in a { if x > y { greater += 1 } else if x < y { less += 1 } } }
        let pairs=Double(a.count*b.count), delta=Double(greater-less)/pairs, absD=abs(delta)
        let magnitude = absD < 0.147 ? "Negligible" : absD < 0.33 ? "Small" : absD < 0.474 ? "Medium" : "Large"
        var warnings:[String]=["Effect size describes observed cohort separation; it does not prove the tested change caused the difference."]
        if min(a.count,b.count) < 5 { warnings.append("Very small cohort; effect-size stability is limited.") }
        return .init(baselineCount:a.count,validationCount:b.count,medianDelta:median(b)-median(a),cliffsDelta:delta,magnitude:magnitude,warnings:warnings)
    }
}

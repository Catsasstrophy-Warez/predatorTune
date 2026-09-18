import Foundation

struct NormalizedDeltaPoint: Identifiable, Codable, Equatable { var id: Double { time }; var time:Double; var baseline:Double; var validation:Double; var delta:Double }
enum NormalizedDeltaEngine {
    /// Compares already-normalized traces at shared timestamps. Missing/non-finite pairs remain absent rather than fabricated.
    static func compare(times:[Double], baseline:[Double?], validation:[Double?]) -> [NormalizedDeltaPoint] {
        let n=min(times.count,min(baseline.count,validation.count)); guard n > 0 else { return [] }
        return (0..<n).compactMap { i in
            guard let b=baseline[i], let v=validation[i], b.isFinite, v.isFinite, times[i].isFinite else { return nil }
            return .init(time:times[i],baseline:b,validation:v,delta:v-b)
        }
    }
}

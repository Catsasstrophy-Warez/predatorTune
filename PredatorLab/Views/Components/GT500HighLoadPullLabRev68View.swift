import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct GT500HighLoadPullLabRev68View: View {
    private let demo: HighLoadPullReconstruction = {
        let samples = [
            StableWindowSample(time:0,rpm:3000,pedal:100,throttle:100,lambdaCommanded:0.82,lambdaMeasured:0.83,spark:18,knock:0,chargeTemperature:45,coolantTemperature:92,fuelPressure:nil,boostOrMAP:nil,longitudinalAcceleration:nil,tractionIntervention:nil,transmissionIntervention:nil),
            StableWindowSample(time:0.6,rpm:4200,pedal:100,throttle:100,lambdaCommanded:0.82,lambdaMeasured:0.84,spark:18,knock:0,chargeTemperature:48,coolantTemperature:93,fuelPressure:nil,boostOrMAP:nil,longitudinalAcceleration:nil,tractionIntervention:nil,transmissionIntervention:nil),
            StableWindowSample(time:1.2,rpm:5400,pedal:100,throttle:98,lambdaCommanded:0.82,lambdaMeasured:0.84,spark:17,knock:1,chargeTemperature:52,coolantTemperature:94,fuelPressure:nil,boostOrMAP:nil,longitudinalAcceleration:nil,tractionIntervention:nil,transmissionIntervention:nil)
        ]
        return GT500HighLoadPullReconstructorRev68.reconstruct(samples:samples,admittedSemantics:["engine.rpm","driver.pedal","throttle"],observations:[])
    }()
    var body: some View {
        List {
            Section("High-Load Pull Reconstruction") {
                Text("Segment the pull, preserve stable windows, align admitted powertrain/thermal/transmission evidence, and expose every missing semantic before a stronger conclusion is allowed.")
                LabeledContent("Semantic coverage", value:"\(demo.coverage.admitted.count)/\(demo.coverage.required.count)")
            }
            Section("Evidence Gaps") {
                ForEach(demo.evidenceGaps,id:\.self) { Label($0,systemImage:"questionmark.diamond") }
            }
            Section("Calibration → Log Correlation") { Text("Only calibration families actually changed are compared with observed response domains. Overlap is correlation, never automatic causation.") }
            Section("Repeatability + Heat Soak") { Text("Matched pull cohorts retain duration spread, starting thermal state, distributions and recovery. One fast pull cannot validate a tune.") }
            Section("Experiment Closure Planner") { Text("Works backward from a blocked conclusion to the exact missing Scanner semantic/evidence artifact and recommends a matched next experiment without changing calibration unnecessarily.") }
            Section("Boundary") { Text(demo.boundary).font(.caption).foregroundStyle(.secondary) }
        }.navigationTitle("GT500 Pull Reconstruction")
    }
}

import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct FordGT500ExperimentLabRev67View: View {
    private let recommendation = AdaptiveFordExperimentPlannerRev67.recommend(hypothesisIDs:["thermal","traction","transmission"],candidates:[
        .init(id:"torque",measurement:"Reviewed torque-request / limiter evidence",resolvesHypothesisIDs:["thermal","traction","transmission"],cost:2,risk:1,exactSemanticRequired:"torque.request_or_limit"),
        .init(id:"traction",measurement:"Reviewed traction/stability intervention evidence",resolvesHypothesisIDs:["traction"],cost:1,risk:1,exactSemanticRequired:"traction.intervention")],admittedSemantics:[])
    var body: some View {
        List {
            Section("Stable Window Extraction") { Text("Find contiguous, repeatable input windows before comparing boost/airflow, lambda, spark/knock, thermal and acceleration behavior. Raw evidence remains untouched.") }
            Section("Lambda + Fuel Evidence") { Text("Commanded-versus-measured lambda deviation is calculated only after both signal semantics and units are reviewed. No universal safe deviation threshold is invented.") }
            Section("Spark / Knock Chronology") { Text("PredatorLab records which admitted event appears first while preserving sample-rate uncertainty. Temporal order remains evidence, not Ford strategy causation.") }
            Section("Thermal Derate Fingerprint") { Text("Charge temperature, coolant, throttle and spark can be aligned into a thermal/control fingerprint without inventing Ford derate thresholds.") }
            Section("Traction vs Powertrain vs TR_C75") { Text("First-out evidence is classified by intervention family so a traction event is not automatically blamed on PCM torque control or the DCT.") }
            Section("Distribution + Histogram Analysis") { Text("Baseline/candidate medians and histograms expose repeatability and tails that a single peak value can hide. Comparability remains mandatory.") }
            Section("Adaptive Next Experiment") {
                Text(recommendation.candidate?.measurement ?? "No admissible next measurement").font(.headline)
                Text(recommendation.boundary).font(.caption).foregroundStyle(.secondary)
            }
            Section("VCM Suite alignment") { Text("PredatorLab treats VCM Scanner channel configurations, polling intervals, transforms and expression filters as experiment provenance. Filters create analysis windows; they never replace the original log.") }
        }.navigationTitle("GT500 Experiment Intelligence")
    }
}

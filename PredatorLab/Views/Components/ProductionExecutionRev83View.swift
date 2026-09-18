import SwiftUI

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.
struct ProductionExecutionRev83View:View {
    private let gate=TuneProductionGateRev83(xcodeBuildVerified:false,persistenceVerified:false,hplRPMAdmitted:false,configBCompiled:false,mpvi4BenchmarkCompleted:false,controlledFuelExperimentCompleted:false)
    private let why=WhyEngineRev83.insufficientFuelFlowShiftOverlap()
    var body:some View { List {
        Section("Production gates") { ForEach(gate.blockers,id:\.self){ Label($0,systemImage:"exclamationmark.triangle") } }
        Section("Controlled fuel-discriminator protocol") { ForEach(Array(Rev83ExperimentProtocol.fuelDiscriminatorSteps.enumerated()),id:\.offset){ i,s in VStack(alignment:.leading){ Text("\(i+1). \(s)") } } }
        Section("Why does PredatorLab think this?") { Text(why.observation); DisclosureGroup("Supporting evidence"){ ForEach(why.supporting,id:\.self){Text($0)} }; DisclosureGroup("Contradicting evidence"){ForEach(why.contradicting,id:\.self){Text($0)}}; DisclosureGroup("Alternatives"){ForEach(why.alternatives,id:\.self){Text($0)}}; DisclosureGroup("Missing evidence"){ForEach(why.missing,id:\.self){Text($0)}}; Text("Next measurement: \(why.nextMeasurement)").font(.headline) }
        Section("Vehicle archive") { Text("MPVI4 device snapshots, telemetry sessions, acquisition benchmarks, Config B contracts, HPL correlation results, and forensic-case metadata for this vehicle are saved to PredatorLab's on-device archive and persist across app launches.") }
    }.navigationTitle("Production Execution") }
}

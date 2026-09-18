// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import SwiftUI

struct PLGT500LoggingOptimizerView:View {
    private let report=GT500LoggingProfileOptimizerRev109.report()
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:10) {
                HStack {
                    Text("GT500 LOGGING PROFILE OPTIMIZER").font(.system(size:12,weight:.black,design:.monospaced)).foregroundStyle(.plBoost)
                    Spacer();PLInstrumentStatusChip(status:.verified)
                }
                PLInstrumentChrome(accent:.plBoost) {
                    VStack(alignment:.leading,spacing:5) {
                        Text("SUPPLIED VEHICLE-SPECIFIC PROFILE").font(.system(size:9,weight:.black,design:.monospaced))
                        Text("\(report.channels.count) named active channel slots audited").font(.plMono(8))
                        if let fast=report.fastestRequestedInterval,let slow=report.slowestRequestedInterval {
                            Text(String(format:"REQUESTED INTERVAL RANGE %.3fs → %.1fs",fast,slow)).font(.plMono(8)).foregroundStyle(.plTextSecondary)
                        }
                        Text(report.boundary).font(.system(size:7,design:.monospaced)).foregroundStyle(.plTextSecondary)
                    }
                }
                Text("PRESET COVERAGE").font(.system(size:9,weight:.black,design:.monospaced)).foregroundStyle(.plTextSecondary)
                ForEach(report.presets){p in
                    PLInstrumentChrome {
                        VStack(alignment:.leading,spacing:4) {
                            HStack{Text(p.presetName.uppercased()).font(.system(size:9,weight:.black,design:.monospaced));Spacer();Text(String(format:"%.0f%%",p.coverage*100)).font(.plMono(9)).foregroundStyle(.plBoost)}
                            Text("MATCHED \(p.verifiedOrAliased)  •  CANDIDATE \(p.candidate)  •  MISSING \(p.missing.count)").font(.plMono(7))
                            if !p.missing.isEmpty {Text("Missing: "+p.missing.joined(separator:", ")).font(.system(size:7)).foregroundStyle(.plWarning)}
                        }
                    }
                }
                Text("REAL PROFILE CHANNELS").font(.system(size:9,weight:.black,design:.monospaced)).foregroundStyle(.plTextSecondary)
                ForEach(report.channels){c in
                    PLInstrumentChrome(accent:c.recommendation.hasPrefix("No cadence mismatch") ? .plSuccess:.plWarning) {
                        VStack(alignment:.leading,spacing:3) {
                            HStack {
                                Text("PID \(c.parameterID)").font(.plMono(8)).foregroundStyle(.plBoost)
                                Text(c.name).font(.system(size:8,weight:.semibold))
                                Spacer()
                                Text(c.requestedIntervalSeconds.map{String(format:"%.3fs",$0)} ?? "—").font(.plMono(8))
                            }
                            HStack {
                                Text(c.conceptualID ?? "UNCLASSIFIED").font(.plMono(7)).foregroundStyle(.plTextSecondary)
                                if let unit=c.unit,!unit.isEmpty {Text(unit).font(.plMono(7)).foregroundStyle(.plTextSecondary)}
                            }
                            Text(c.recommendation).font(.system(size:7)).foregroundStyle(.plTextSecondary)
                        }
                    }
                }
            }.padding(10)
        }
    }
}

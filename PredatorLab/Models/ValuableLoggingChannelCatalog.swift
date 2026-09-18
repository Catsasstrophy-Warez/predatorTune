// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import Foundation

enum LoggingChannelPriority:String,Codable,Sendable { case essential,high,taskSpecific,slowContext }
enum LoggingChannelPurpose:String,Codable,Sendable { case engineState,airLoad,throttle,boost,fueling,spark,knock,torque,thermal,dct,traction,diagnostic }

struct ValuableLoggingChannel:Identifiable,Codable,Equatable,Sendable {
    let id:String
    let searchTerms:[String]
    let purpose:LoggingChannelPurpose
    let priority:LoggingChannelPriority
    let rationale:String
    let cadence:String
    let authorityNote:String
}

enum ValuableLoggingChannelCatalog {
    static let gt500Testing:[ValuableLoggingChannel] = [
        .init(id:"engine-speed",searchTerms:["Engine RPM","Engine Speed"],purpose:.engineState,priority:.essential,rationale:"Primary x-axis/state reference for pulls, shifts and transient analysis.",cadence:"fast",authorityNote:"Use the supported vehicle-profile parameter; exact HP Tuners name/ID can vary."),
        .init(id:"accelerator",searchTerms:["Accelerator Pedal Position","APP"],purpose:.engineState,priority:.essential,rationale:"Separates driver request from throttle/torque intervention.",cadence:"fast",authorityNote:"Confirm supported channel in the exact vehicle profile."),
        .init(id:"throttle",searchTerms:["Throttle Position","Throttle Angle","ETC"],purpose:.throttle,priority:.essential,rationale:"Shows delivered throttle behavior and closures.",cadence:"fast",authorityNote:"Prefer the vehicle-supported actual/commanded channels when both exist."),
        .init(id:"load-airmass",searchTerms:["Load","Air Mass","Cylinder Air Mass"],purpose:.airLoad,priority:.essential,rationale:"Critical operating-state context for spark, torque and fueling analysis.",cadence:"fast",authorityNote:"Ford definitions are strategy/profile dependent; do not assume cross-vehicle equivalence."),
        .init(id:"map",searchTerms:["MAP","Manifold Absolute Pressure"],purpose:.boost,priority:.essential,rationale:"Core pressure/load reference for supercharged operation.",cadence:"fast",authorityNote:"Log absolute pressure with known units; derive boost only with valid barometric reference."),
        .init(id:"baro",searchTerms:["Barometric Pressure","BARO"],purpose:.boost,priority:.high,rationale:"Provides ambient reference for pressure-ratio/boost interpretation.",cadence:"slow",authorityNote:"Slow-changing context can use a longer polling interval."),
        .init(id:"lambda-commanded",searchTerms:["Commanded Lambda","Desired Lambda","Fuel EQ Ratio Commanded"],purpose:.fueling,priority:.essential,rationale:"Fueling target needed to judge measured mixture.",cadence:"fast",authorityNote:"Use lambda when possible to avoid fuel-specific AFR ambiguity."),
        .init(id:"lambda-measured",searchTerms:["Lambda","Wideband","Equivalence Ratio","O2"],purpose:.fueling,priority:.essential,rationale:"Measured mixture response for error and transient analysis.",cadence:"fast",authorityNote:"Prefer trustworthy wideband/controller channels supported by the exact configuration."),
        .init(id:"fuel-pressure-low",searchTerms:["Low Side Fuel Pressure","Fuel Pump Pressure"],purpose:.fueling,priority:.high,rationale:"Separates supply-side pressure behavior from high-pressure system behavior.",cadence:"fast",authorityNote:"Availability/name must be confirmed in the vehicle profile."),
        .init(id:"fuel-pressure-rail",searchTerms:["Fuel Rail Pressure","High Pressure Fuel","FRP"],purpose:.fueling,priority:.essential,rationale:"Key DI fueling-capacity and pressure-control observation.",cadence:"fast",authorityNote:"Where available, log desired and actual together."),
        .init(id:"injector",searchTerms:["Injector Pulse Width","Injector Duty Cycle","Injection Time"],purpose:.fueling,priority:.high,rationale:"Useful for injector utilization and fuel-delivery context.",cadence:"fast",authorityNote:"Interpretation depends on strategy and injection events; do not equate pulse width directly with universal duty cycle."),
        .init(id:"spark",searchTerms:["Spark Advance","Ignition Timing"],purpose:.spark,priority:.essential,rationale:"Primary delivered ignition observation.",cadence:"fast",authorityNote:"Log delivered spark plus relevant modifiers if the profile exposes them."),
        .init(id:"knock",searchTerms:["Knock Retard","Knock","Octane Adjust","Borderline Knock"],purpose:.knock,priority:.essential,rationale:"Required context for knock-control activity and spark movement.",cadence:"fast",authorityNote:"Exact Ford knock channels/semantics require profile/source verification."),
        .init(id:"iat",searchTerms:["Intake Air Temperature","IAT"],purpose:.thermal,priority:.high,rationale:"Ambient/inlet thermal context.",cadence:"medium",authorityNote:"Identify sensor location/definition before comparing channels."),
        .init(id:"charge-temp",searchTerms:["Charge Air Temperature","IAT2","Manifold Charge Temperature"],purpose:.thermal,priority:.essential,rationale:"High-value supercharged-air thermal context.",cadence:"fast",authorityNote:"Do not assume the label IAT2 maps identically across strategies; verify definition."),
        .init(id:"ect",searchTerms:["Engine Coolant Temperature","ECT"],purpose:.thermal,priority:.high,rationale:"Engine thermal state and protection context.",cadence:"slow",authorityNote:"Slow-changing parameter; lower polling demand when appropriate."),
        .init(id:"oil-temp",searchTerms:["Engine Oil Temperature","EOT"],purpose:.thermal,priority:.high,rationale:"Useful for repeatability, warm-up and thermal protection context.",cadence:"slow",authorityNote:"Availability is profile dependent."),
        .init(id:"torque-source",searchTerms:["Torque Source","Torque Intervention","Torque Reduction"],purpose:.torque,priority:.essential,rationale:"Helps explain closures/spark changes caused by torque management rather than airflow/fuel faults.",cadence:"fast",authorityNote:"Ford torque-strategy semantics require exact-source verification."),
        .init(id:"torque-request",searchTerms:["Driver Demand Torque","Requested Torque","Desired Torque"],purpose:.torque,priority:.high,rationale:"Separates requested torque from delivered/limited behavior.",cadence:"fast",authorityNote:"Exact parameter naming varies."),
        .init(id:"torque-actual",searchTerms:["Actual Torque","Indicated Torque","Engine Torque"],purpose:.torque,priority:.high,rationale:"Useful for torque-path comparison when supported.",cadence:"fast",authorityNote:"Treat modeled torque as controller-reported/model-derived unless independently measured."),
        .init(id:"gear",searchTerms:["Current Gear","Commanded Gear"],purpose:.dct,priority:.essential,rationale:"Essential for aligning pulls and interpreting shift events.",cadence:"fast",authorityNote:"Log actual and commanded if both are supported."),
        .init(id:"dct-temp",searchTerms:["Transmission Fluid Temperature","Clutch Temperature","DCT Temperature"],purpose:.dct,priority:.high,rationale:"Thermal/repeatability context for the dual-clutch transmission.",cadence:"medium",authorityNote:"Only use channels actually exposed by the GT500 profile."),
        .init(id:"vehicle-speed",searchTerms:["Vehicle Speed","VSS"],purpose:.engineState,priority:.high,rationale:"Correlates gear, acceleration and dyno/road event timing.",cadence:"fast",authorityNote:"Wheel/tire configuration affects interpretation."),
        .init(id:"wheel-speed",searchTerms:["Wheel Speed"],purpose:.traction,priority:.taskSpecific,rationale:"Useful for slip, traction intervention and dyno consistency.",cadence:"fast",authorityNote:"Add only required wheel channels to preserve scan bandwidth."),
        .init(id:"traction",searchTerms:["Traction Control","Stability Control","Wheel Slip"],purpose:.traction,priority:.taskSpecific,rationale:"Explains interventions that can masquerade as engine/tune behavior.",cadence:"fast",authorityNote:"Switch/flag channels can be highly valuable with low interpretive ambiguity when definitions are verified."),
        .init(id:"battery",searchTerms:["Battery Voltage","Control Module Voltage"],purpose:.diagnostic,priority:.slowContext,rationale:"Basic electrical/context sanity channel.",cadence:"slow",authorityNote:"Useful context, not a high-rate tuning channel.")
    ]
}

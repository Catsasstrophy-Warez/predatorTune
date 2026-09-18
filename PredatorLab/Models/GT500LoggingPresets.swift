// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import Foundation

struct LoggingPreset:Identifiable,Equatable,Sendable {
    let id:String;let name:String;let purpose:String;let channelIDs:[String]
    let boundary:String
}

enum GT500LoggingPresets {
    static let all:[LoggingPreset] = [
        .init(id:"core-pull",name:"GT500 Core Pull",purpose:"High-value pull and transient context.",
              channelIDs:["engine-speed","accelerator","throttle","load-airmass","map","lambda-commanded","lambda-measured","fuel-pressure-rail","spark","knock","charge-temp","torque-source","gear","vehicle-speed"],
              boundary:"Conceptual channel families only. Resolve against the exact supported vehicle/profile before acquisition."),
        .init(id:"fuel-deep",name:"Fuel System Deep Dive",purpose:"Separate low-side supply, DI rail control, injector utilization and mixture response.",
              channelIDs:["engine-speed","load-airmass","map","lambda-commanded","lambda-measured","fuel-pressure-low","fuel-pressure-rail","injector","charge-temp"],
              boundary:"Desired/actual pressure pairing requires compatible, verified definitions and units."),
        .init(id:"spark-knock-torque",name:"Spark / Knock / Torque",purpose:"Explain delivered spark and torque-management interventions.",
              channelIDs:["engine-speed","accelerator","throttle","load-airmass","spark","knock","charge-temp","ect","torque-source","torque-request","torque-actual","gear"],
              boundary:"Controller-reported torque and knock semantics are strategy/profile dependent."),
        .init(id:"thermal",name:"Predator Thermal / Repeatability",purpose:"Compare heat state and repeatability across pulls.",
              channelIDs:["engine-speed","map","lambda-commanded","lambda-measured","spark","iat","charge-temp","ect","oil-temp","dct-temp","gear"],
              boundary:"Thermal channels are context; no hard protection threshold is implied."),
        .init(id:"dct-traction",name:"DCT / Traction / Shift",purpose:"Resolve shift, wheel-slip and torque-intervention behavior.",
              channelIDs:["engine-speed","accelerator","throttle","torque-source","torque-request","torque-actual","gear","dct-temp","vehicle-speed","wheel-speed","traction"],
              boundary:"Only channels actually exposed and understood in the exact GT500 profile should be admitted.")
    ]
}

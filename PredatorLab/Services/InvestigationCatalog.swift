import Foundation

enum InvestigationCatalog {
    static let r04 = DiagnosticInvestigationDefinition(
        id: "R04_FUEL_CAPABILITY", title: "R04 Fuel Capability / Insufficient Fuel Flow", phase: .r04FuelCapability,
        requiredChannels: [.engineRPM, .gearActual, .injectorPulseWidth, .maximumInjectorPulseWidth, .fuelPressureCommanded, .fuelPressureActual, .lambdaCommanded, .lambdaMeasured, .torqueProtectionSource],
        hypotheses: R04InvestigationEngine.seedAllHypotheses(),
        verificationCriteria: ["Protection event reproduced or ruled out under a comparable condition", "Fuel-pressure tracking characterized", "Injector PW margin characterized", "Lambda tracking characterized", "Primary hypothesis supported by discriminating evidence"]
    )

    static let knock = DiagnosticInvestigationDefinition(
        id: "KNOCK", title: "Knock / Spark Retard", phase: .r06Spark,
        requiredChannels: [.engineRPM, .knockRetard, .sparkSource, .iat2, .coolantTemperature], hypotheses: [],
        verificationCriteria: ["Knock episode bounded in time", "Thermal condition documented", "Spark-source ownership documented", "Repeatability assessed"], authoredHypotheses: AuthoredInvestigationLibrary.knock
    )

    static let pressureTracking = DiagnosticInvestigationDefinition(
        id: "FUEL_PRESSURE_TRACKING", title: "Fuel Pressure Tracking", phase: .r04FuelCapability,
        requiredChannels: [.engineRPM, .fuelPressureCommanded, .fuelPressureActual, .injectorPulseWidth], hypotheses: [],
        verificationCriteria: ["Command/actual error quantified", "Onset and recovery characterized", "Load/RPM context captured"], authoredHypotheses: AuthoredInvestigationLibrary.pressure
    )

    static let lambdaDeviation = DiagnosticInvestigationDefinition(
        id: "LAMBDA_DEVIATION", title: "Lambda Deviation", phase: .r05FuelCommand,
        requiredChannels: [.engineRPM, .lambdaCommanded, .lambdaMeasured, .fuelPressureActual], hypotheses: [],
        verificationCriteria: ["Command/measured error quantified", "Fuel-pressure context reviewed", "Transient versus sustained deviation classified"], authoredHypotheses: AuthoredInvestigationLibrary.lambda
    )

    static let throttleClosure = DiagnosticInvestigationDefinition(
        id: "THROTTLE_CLOSURE", title: "Unexpected Throttle Closure", phase: .r07TorqueModel,
        requiredChannels: [.engineRPM, .throttleCommanded, .throttleActual, .gearActual, .torqueProtectionSource], hypotheses: [],
        verificationCriteria: ["Command/actual relationship quantified", "Controller ownership/source state reviewed", "Shift relationship assessed"], authoredHypotheses: AuthoredInvestigationLibrary.throttle
    )


    static let dctTransient = DiagnosticInvestigationDefinition(
        id: "DCT_TRANSIENT", title: "DCT Shift Transient", phase: .r09DCT,
        requiredChannels: [.engineRPM, .gearCommanded, .gearActual, .throttleCommanded, .throttleActual, .torqueProtectionSource], hypotheses: [],
        verificationCriteria: ["Shift onset/end bounded", "Commanded versus actual gear relationship reviewed", "Throttle/protection ownership reviewed", "Repeatability under comparable shift conditions assessed"], authoredHypotheses: AuthoredInvestigationLibrary.dct
    )

    static let boostControl = DiagnosticInvestigationDefinition(
        id: "BOOST_CONTROL", title: "Boost / Manifold Pressure Behavior", phase: .r03Airflow,
        requiredChannels: [.engineRPM, .manifoldPressure, .boostPressure, .throttleActual, .iat2], hypotheses: [],
        verificationCriteria: ["Pressure behavior bounded in time", "Throttle context reviewed", "Thermal context documented", "Repeatability assessed"], authoredHypotheses: AuthoredInvestigationLibrary.boost
    )

    static let thermal = DiagnosticInvestigationDefinition(
        id: "THERMAL", title: "Thermal / Heat-Soak Behavior", phase: .r10Validation,
        requiredChannels: [.engineRPM, .iat1, .iat2, .coolantTemperature, .vehicleSpeed], hypotheses: [],
        verificationCriteria: ["Warm-up and heat-soak interval documented", "IAT1/IAT2/coolant trends characterized", "Vehicle-speed/load context reviewed", "Recovery behavior assessed"], authoredHypotheses: AuthoredInvestigationLibrary.thermal
    )

    static let all: [DiagnosticInvestigationDefinition] = [r04, knock, pressureTracking, lambdaDeviation, throttleClosure, dctTransient, boostControl, thermal]
}

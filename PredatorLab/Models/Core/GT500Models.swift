// PredatorLab/Models/Core/GT500Models.swift
// Vehicle, build state, tuning phases & calibration gates
// (Split from PredatorLab_CoreModels.swift — AppState class extracted into State/AppState.swift)

import Foundation

// MARK: - Vehicle & Build State

enum GT500ModelYear: Int, Codable, CaseIterable, Identifiable {
    case y2020 = 2020
    case y2021 = 2021
    case y2022 = 2022

    var id: Int { rawValue }
}

struct GT500Vehicle: Identifiable, Codable {
    let id: UUID

    var nickname: String
    var modelYear: GT500ModelYear
    var vin: String?

    var pcmController: String
    var pcmStrategy: String
    var pcmOS: String

    var tcmController: String
    var tcmStrategy: String
    var tcmOS: String

    var fuelType: String
    var mileage: Int?

    var buildStates: [VehicleBuildState]
    var currentBuildStateID: UUID?

    init(
        id: UUID = UUID(),
        nickname: String,
        modelYear: GT500ModelYear,
        vin: String? = nil,
        pcmController: String = "TC-298B",
        pcmStrategy: String = "TPWR",
        pcmOS: String = "T87",
        tcmController: String = "TR-C75",
        tcmStrategy: String = "TTRN",
        tcmOS: String = "T87",
        fuelType: String = "93 AKI",
        mileage: Int? = nil,
        buildStates: [VehicleBuildState] = []
    ) {
        self.id = id
        self.nickname = nickname
        self.modelYear = modelYear
        self.vin = vin
        self.pcmController = pcmController
        self.pcmStrategy = pcmStrategy
        self.pcmOS = pcmOS
        self.tcmController = tcmController
        self.tcmStrategy = tcmStrategy
        self.tcmOS = tcmOS
        self.fuelType = fuelType
        self.mileage = mileage
        self.buildStates = buildStates.isEmpty ? [VehicleBuildState(name: "Stock")] : buildStates
        self.currentBuildStateID = self.buildStates.first?.id
    }

    var displayName: String {
        "\(modelYear.rawValue) GT500 — \(nickname)"
    }

    var currentBuildState: VehicleBuildState? {
        guard let currentID = currentBuildStateID else { return nil }
        return buildStates.first { $0.id == currentID }
    }

    mutating func switchBuildState(to stateID: UUID) {
        if buildStates.contains(where: { $0.id == stateID }) {
            currentBuildStateID = stateID
        }
    }

    /// Creates an immutable-in-history successor rather than overwriting the configuration that old evidence references.
    @discardableResult
    mutating func createBuildRevision(named name: String, mutate: (inout VehicleBuildState) -> Void = { _ in }) -> UUID {
        var next = currentBuildState ?? VehicleBuildState(name: name)
        next = VehicleBuildState(
            name: name, date: .now, blower: next.blower, blowerPulley: next.blowerPulley,
            blowerRatio: next.blowerRatio, intake: next.intake, throttleBody: next.throttleBody,
            injectors: next.injectors, injectorRating: next.injectorRating, fuelPump: next.fuelPump,
            fuelSystem: next.fuelSystem, exhaust: next.exhaust, cooling: next.cooling,
            intercooler: next.intercooler, engineInternals: next.engineInternals,
            transmissionMods: next.transmissionMods, notes: next.notes
        )
        mutate(&next)
        buildStates.append(next)
        currentBuildStateID = next.id
        return next.id
    }
}

struct VehicleBuildState: Identifiable, Codable {
    let id: UUID
    var name: String
    var date: Date

    var blower: String
    var blowerPulley: String
    var blowerRatio: String?

    var intake: String
    var throttleBody: String

    var injectors: String
    var injectorRating: String?
    var fuelPump: String
    var fuelSystem: String

    var exhaust: String

    var cooling: String
    var intercooler: String

    var engineInternals: String
    var transmissionMods: String

    var notes: String

    init(
        id: UUID = UUID(),
        name: String = "Stock",
        date: Date = .now,
        blower: String = "Eaton TVS R2650 (stock)",
        blowerPulley: String = "2.4\" stock",
        blowerRatio: String? = nil,
        intake: String = "Stock OEM",
        throttleBody: String = "Stock 87mm",
        injectors: String = "Ford Performance EV14 55 lb/hr @ 40 psi",
        injectorRating: String? = nil,
        fuelPump: String = "Stock Predator",
        fuelSystem: String = "Stock port-injection",
        exhaust: String = "Stock",
        cooling: String = "Stock",
        intercooler: String = "Stock aluminum",
        engineInternals: String = "Stock",
        transmissionMods: String = "Stock TR-9070",
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.blower = blower
        self.blowerPulley = blowerPulley
        self.blowerRatio = blowerRatio
        self.intake = intake
        self.throttleBody = throttleBody
        self.injectors = injectors
        self.injectorRating = injectorRating
        self.fuelPump = fuelPump
        self.fuelSystem = fuelSystem
        self.exhaust = exhaust
        self.cooling = cooling
        self.intercooler = intercooler
        self.engineInternals = engineInternals
        self.transmissionMods = transmissionMods
        self.notes = notes
    }
}

// MARK: - Tuning Phases & Gates

enum TuningPhase: Int, Codable, CaseIterable, Identifiable {
    case r00StockTruth = 0
    case r01Instrumentation
    case r02Baseline
    case r03Airflow
    case r04FuelCapability
    case r05FuelCommand
    case r06Spark
    case r07TorqueModel
    case r08DriverDemand
    case r09DCT
    case r10Validation

    var id: Int { rawValue }

    var shortName: String {
        "R\(String(format: "%02d", rawValue))"
    }

    var title: String {
        switch self {
        case .r00StockTruth: return "Stock Truth"
        case .r01Instrumentation: return "Instrumentation"
        case .r02Baseline: return "Repeatable Baseline"
        case .r03Airflow: return "Airflow Model"
        case .r04FuelCapability: return "Fuel Capability"
        case .r05FuelCommand: return "Commanded Fueling"
        case .r06Spark: return "Spark"
        case .r07TorqueModel: return "Torque Model"
        case .r08DriverDemand: return "Driver Demand & ETC"
        case .r09DCT: return "DCT"
        case .r10Validation: return "System Validation"
        }
    }

    var description: String {
        switch self {
        case .r00StockTruth:
            return "Archive untouched PCM/TCM, hardware state, baseline"
        case .r01Instrumentation:
            return "Validate PID identity, units, cross-checks before tuning"
        case .r02Baseline:
            return "Characterize stock behavior across idle, cruise, accel, thermal"
        case .r03Airflow:
            return "Validate MAF transfer, load estimation, bypass behavior"
        case .r04FuelCapability:
            return "Root cause Insufficient Fuel Flow: injector, pump, model, or sensor issue"
        case .r05FuelCommand:
            return "Optimize lambda strategy within proven fuel capacity"
        case .r06Spark:
            return "Tune spark advance and knock control"
        case .r07TorqueModel:
            return "Validate torque model ±10% vs dyno or IPC error <15%"
        case .r08DriverDemand:
            return "Tune pedal map and throttle response"
        case .r09DCT:
            return "Characterize and optimize shift behavior"
        case .r10Validation:
            return "Validate tuning repeatability across thermal envelope"
        }
    }
}

struct CalibrationGate: Identifiable, Codable {
    let id: UUID
    var phase: TuningPhase
    var title: String
    var requirements: [String]
    var isSatisfied: Bool
    var blockingReason: String?

    init(
        id: UUID = UUID(),
        phase: TuningPhase,
        title: String,
        requirements: [String],
        isSatisfied: Bool = false,
        blockingReason: String? = nil
    ) {
        self.id = id
        self.phase = phase
        self.title = title
        self.requirements = requirements
        self.isSatisfied = isSatisfied
        self.blockingReason = blockingReason
    }
}

// MARK: - Stock Truth

struct GT500StockTruth {
    static let modelYear2020_2022 = [
        "Engine Type": "5.2L Predator V8",
        "Supercharger": "Eaton TVS R2650 positive displacement",
        "Compression Ratio": "9.5:1",
        "Factory Horsepower": "760 hp",
        "Factory Torque": "625 lb-ft",
        "Fuel System": "Port injection (EV14 55 lb/hr)",
        "Fuel Type": "93 AKI minimum",
        "PCM": "TC-298B",
        "TCM": "TR-9070 dual-clutch",
        "Boost Pressure": "12 psi gauge (27 psia absolute)",
        "Injection Type": "Port-fuel (NOT direct injection)",
        "Normal Fuel Pressure": "90-100 psi",
        "Redline": "6,800 RPM mechanical"
    ]
}

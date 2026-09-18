import Foundation

struct ScannerChannelRequirement: Codable, Equatable {
    let channel: CanonicalChannel
    let critical: Bool
    let desiredHz: Double?
    let semanticVerificationRequired: Bool
}

struct ScannerAcquisitionProfile: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let investigationID: String
    let channels: [ScannerChannelRequirement]
    let notes: [String]
}

enum ScannerAcquisitionProfiles {
    static let r04 = ScannerAcquisitionProfile(
        id: "scanner.r04", title: "R04 Fuel Capability", investigationID: InvestigationCatalog.r04.id,
        channels: InvestigationCatalog.r04.requiredChannels.map {
            .init(channel: $0, critical: true, desiredHz: 20, semanticVerificationRequired: [.maximumInjectorPulseWidth, .torqueProtectionSource].contains($0))
        },
        notes: ["20 Hz is a PredatorLab acquisition target, not a Ford or HP Tuners requirement.", "Verify strategy-specific PID semantics before treating modeled/source-state channels as physical truth."]
    )

    private static func profile(_ definition: DiagnosticInvestigationDefinition, hz: Double, semantic: Set<CanonicalChannel> = []) -> ScannerAcquisitionProfile {
        ScannerAcquisitionProfile(id: "scanner.\(definition.id.lowercased())", title: definition.title, investigationID: definition.id,
            channels: definition.requiredChannels.map { .init(channel:$0, critical:true, desiredHz:hz, semanticVerificationRequired:semantic.contains($0)) },
            notes:["Sampling targets are PredatorLab-authored acquisition targets, not Ford/OEM or scanner-vendor requirements.", "Verify source units and PID semantics before strong physical interpretation."])
    }

    static let pressure = profile(InvestigationCatalog.pressureTracking, hz: 20, semantic:[.fuelPressureCommanded,.fuelPressureActual])
    static let lambda = profile(InvestigationCatalog.lambdaDeviation, hz: 20, semantic:[.lambdaCommanded,.lambdaMeasured])
    static let knock = profile(InvestigationCatalog.knock, hz: 25, semantic:[.knockRetard,.sparkSource])
    static let throttle = profile(InvestigationCatalog.throttleClosure, hz: 25, semantic:[.throttleCommanded,.throttleActual,.torqueProtectionSource])
    static let dct = profile(InvestigationCatalog.dctTransient, hz: 25, semantic:[.gearCommanded,.gearActual,.torqueProtectionSource])
    static let boost = profile(InvestigationCatalog.boostControl, hz: 25, semantic:[.manifoldPressure,.boostPressure])
    static let thermal = profile(InvestigationCatalog.thermal, hz: 10, semantic:[.iat1,.iat2,.coolantTemperature])

    static let all: [ScannerAcquisitionProfile] = [r04, pressure, lambda, knock, throttle, dct, boost, thermal]

    static func missingCritical(profile: ScannerAcquisitionProfile, in log: ParsedLogData) -> [CanonicalChannel] {
        profile.channels.filter { $0.critical && ChannelResolver.resolve($0.channel, in: log.channels) == nil }.map(\.channel)
    }
}

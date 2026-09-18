import Foundation

/// Evidence sufficiency contracts for every authored investigation family.
/// Thresholds are PredatorLab acquisition heuristics, not Ford/OEM diagnostic thresholds.
enum InvestigationEvidenceContracts {
    static func requirements(for definition: DiagnosticInvestigationDefinition) -> [ChannelRequirement] {
        if definition.id == InvestigationCatalog.r04.id { return InvestigationReadinessEngine.r04 }
        return definition.requiredChannels.map { channel in
            let highRate: Set<CanonicalChannel> = [.fuelPressureCommanded,.fuelPressureActual,.lambdaCommanded,.lambdaMeasured,.throttleCommanded,.throttleActual,.knockRetard,.boostPressure,.manifoldPressure]
            let critical = channel == .engineRPM || channel == .gearActual || channel == .fuelPressureActual || channel == .lambdaMeasured || channel == .throttleActual || channel == .knockRetard || channel == .iat2
            return ChannelRequirement(channel: channel, minimumCoverage: critical ? 0.95 : 0.85, minimumHz: highRate.contains(channel) ? 20 : 10, maximumGap: highRate.contains(channel) ? 0.10 : 0.25, critical: critical)
        }
    }

    static func readiness(for definition: DiagnosticInvestigationDefinition, log: ParsedLogData) -> InvestigationReadinessReport {
        InvestigationReadinessEngine.evaluate(AcquisitionQualityEngine.analyze(log), requirements: requirements(for: definition))
    }
}

struct AuthoredHypothesisEvidenceStatus: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let evidenceCoverage: Double
    let presentEvidence: [String]
    let missingEvidence: [String]
    let nextMeasurements: [String]
    let boundary: String
}

/// Conservative evidence-coverage assessment for non-R04 authored hypotheses.
/// This deliberately does not manufacture a fit/probability score before domain-specific rules are validated.
enum AuthoredHypothesisEvidenceEngine {
    static func assess(definition: DiagnosticInvestigationDefinition, log: ParsedLogData) -> [AuthoredHypothesisEvidenceStatus] {
        let presentChannels = Set(definition.requiredChannels.filter { ChannelResolver.resolve($0, in: log.channels) != nil }.map(\.rawValue))
        let channelCoverage = definition.requiredChannels.isEmpty ? 0 : Double(presentChannels.count) / Double(definition.requiredChannels.count)
        return (definition.authoredHypotheses ?? []).map { h in
            let present = channelCoverage >= 0.999 ? h.requiredEvidence : []
            let missing = channelCoverage >= 0.999 ? [] : h.requiredEvidence
            return .init(id:h.id, title:h.title, evidenceCoverage:channelCoverage, presentEvidence:present, missingEvidence:missing, nextMeasurements:h.nextMeasurements, boundary:h.evidenceBoundary)
        }
    }
}

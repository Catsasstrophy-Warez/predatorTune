import Foundation

/// A region of a log where operating conditions were sufficient for a target failure/event
/// to have had a meaningful chance to recur. Opportunities are not failures.
struct ValidationOpportunity: Identifiable, Codable, Equatable {
    let id: UUID
    let start: TimeInterval
    let end: TimeInterval
    let peakRPM: Double?
    let gear: Int?
    let eventOccurred: Bool
    let eventType: String
    var duration: TimeInterval { max(0, end - start) }

    init(id: UUID = UUID(), start: TimeInterval, end: TimeInterval, peakRPM: Double?, gear: Int?, eventOccurred: Bool, eventType: String) {
        self.id=id; self.start=start; self.end=end; self.peakRPM=peakRPM; self.gear=gear; self.eventOccurred=eventOccurred; self.eventType=eventType
    }
}

struct OpportunitySummary: Codable, Equatable {
    let opportunities: Int
    let recurrences: Int
    var recurrenceRate: Double? { opportunities > 0 ? Double(recurrences) / Double(opportunities) : nil }
}

enum ValidationOpportunityEngine {
    /// Finds high-load/high-RPM opportunities around the reference event's RPM envelope.
    /// This is intentionally conservative: if RPM or throttle is absent, no opportunity is claimed.
    static func detect(in log: ParsedLogData, reference: DiagnosticEvidencePackage, contract: OpportunityContract? = nil) -> [ValidationOpportunity] {
        let rule = contract ?? OpportunityContractCatalog.contract(for: reference.episode.eventType) ?? OpportunityContractCatalog.r04
        guard OpportunityReadinessEngine.evaluate(log: log, contract: rule).ready,
              let rpmName=ChannelResolver.resolve(.engineRPM,in:log.channels),
              let throttleName=ChannelResolver.resolve(.throttleActual,in:log.channels),
              let targetRPM=reference.observations.first(where:{$0.key=="rpm_at_onset"})?.value else { return [] }
        let gearName=ChannelResolver.resolve(.gearActual,in:log.channels)
        let lower=max(rule.minimumRPM,targetRPM-rule.rpmTolerance), upper=targetRPM+rule.rpmTolerance
        let events=LogEventDetector.detectAllEpisodes(logData:log).filter{$0.eventType==reference.episode.eventType}
        var ranges:[ClosedRange<Int>]=[]; var start:Int?
        for row in log.samples.indices {
            let rpm=log.numericValue(channel:rpmName,row:row), throttle=log.numericValue(channel:throttleName,row:row)
            let qualifies = rpm.map{$0 >= lower && $0 <= upper} == true && throttle.map{$0 >= rule.minimumThrottle} == true
            if qualifies && start == nil { start=row }
            if (!qualifies || row == log.samples.indices.last), let s=start {
                let e = qualifies && row == log.samples.indices.last ? row : max(s,row-1)
                if log.timestamps.indices.contains(s), log.timestamps.indices.contains(e), log.timestamps[e]-log.timestamps[s] >= rule.minimumDuration { ranges.append(s...e) }
                start=nil
            }
        }
        return ranges.map { range in
            let s=log.timestamps[range.lowerBound], e=log.timestamps[range.upperBound]
            let rpms=range.compactMap{log.numericValue(channel:rpmName,row:$0)}
            let gears=gearName.flatMap { name in range.compactMap{log.numericValue(channel:name,row:$0)}.map{Int($0.rounded())} }
            let gear=gears.flatMap { vals in Dictionary(grouping:vals,by:{$0}).max(by:{$0.value.count < $1.value.count})?.key }
            let occurred=events.contains{$0.start <= e && $0.end >= s}
            return ValidationOpportunity(start:s,end:e,peakRPM:rpms.max(),gear:gear,eventOccurred:occurred,eventType:reference.episode.eventType)
        }
    }

    static func summarize(_ opportunities:[ValidationOpportunity]) -> OpportunitySummary {
        .init(opportunities:opportunities.count, recurrences:opportunities.filter(\.eventOccurred).count)
    }
}

struct PersistedValidationReport: Identifiable, Codable {
    let id: UUID
    let vehicleID: UUID
    let baselineLogID: UUID
    let baselineBuildStateID: UUID?
    let validationBuildStateID: UUID?
    let createdAt: Date
    let outcome: ValidationOutcome
    let confidenceLabel: String
    let baselineComparableEvents: Int
    let validationComparableEvents: Int
    let rejectedEvents: Int
    let baselineOpportunity: OpportunitySummary?
    let validationOpportunity: OpportunitySummary?
    let engineVersion: AnalysisEngineVersion
    let baselineSourceSHA256: String?
    let notes: [String]

    init(id:UUID=UUID(), vehicleID:UUID, baselineLogID:UUID, baselineBuildStateID:UUID?, validationBuildStateID:UUID?, outcome:ValidationOutcome, confidenceLabel:String, baselineComparableEvents:Int, validationComparableEvents:Int, rejectedEvents:Int, baselineOpportunity:OpportunitySummary?=nil, validationOpportunity:OpportunitySummary?=nil, baselineSourceSHA256:String?=nil, notes:[String]=[]) {
        self.id=id; self.vehicleID=vehicleID; self.baselineLogID=baselineLogID; self.baselineBuildStateID=baselineBuildStateID; self.validationBuildStateID=validationBuildStateID; self.createdAt = .now; self.outcome=outcome; self.confidenceLabel=confidenceLabel; self.baselineComparableEvents=baselineComparableEvents; self.validationComparableEvents=validationComparableEvents; self.rejectedEvents=rejectedEvents; self.baselineOpportunity=baselineOpportunity; self.validationOpportunity=validationOpportunity; self.engineVersion = .current; self.baselineSourceSHA256=baselineSourceSHA256; self.notes=notes
    }
}

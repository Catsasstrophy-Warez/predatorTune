import Foundation

/// Executes conservative, authored episode rules across the non-R04 investigation families.
/// These rules are *candidate detectors*, not OEM monitor definitions or component diagnoses.
/// Every output carries its authored provenance so downstream UI cannot silently promote it to factory truth.
struct ExecutedDiagnosticEpisode: Identifiable, Codable, Equatable {
    let id: UUID
    let investigationID: String
    let ruleID: String
    let start: TimeInterval
    let end: TimeInterval
    let peakMagnitude: Double
    let provenance: String
    let evidenceBoundary: String
}

struct DomainDiagnosticExecutionReport: Codable, Equatable {
    let investigationID: String
    let episodes: [ExecutedDiagnosticEpisode]
    let missingChannels: [CanonicalChannel]
    let warnings: [String]
}

enum DomainDiagnosticExecutionEngine {
    static func execute(_ definition: DiagnosticInvestigationDefinition, log: ParsedLogData) -> DomainDiagnosticExecutionReport {
        // MAP is an equivalent source for boost-rate analysis: boost = MAP − baro, so their rates match.
        let boostSource: CanonicalChannel = ChannelResolver.resolve(.boostPressure, in: log.channels) == nil
            && ChannelResolver.resolve(.manifoldPressure, in: log.channels) != nil ? .manifoldPressure : .boostPressure
        let missing = definition.requiredChannels.filter { channel in
            let effective = channel == .boostPressure ? boostSource : channel
            return ChannelResolver.resolve(effective, in: log.channels) == nil
        }
        var warnings: [String] = []
        if !missing.isEmpty { warnings.append("Required channels are missing; candidate detection may be incomplete.") }
        warnings.append("Episode thresholds are PredatorLab-authored analysis heuristics, not Ford/OEM diagnostic thresholds.")

        let episodes: [ExecutedDiagnosticEpisode]
        switch definition.id {
        case InvestigationCatalog.pressureTracking.id:
            episodes = pairedErrorEpisodes(log: log, command: .fuelPressureCommanded, actual: .fuelPressureActual,
                rule: .init(id:"pressure.relative-error", enterThreshold:0.08, confirmDuration:0.20, exitThreshold:0.04, recoveryDuration:0.20, directionAbove:true, provenance:"PredatorLab authored relative-error heuristic"),
                investigationID: definition.id, boundary:"Pressure tracking error does not isolate pump, restriction, wiring, sensor, or control cause.", relative:true)
        case InvestigationCatalog.lambdaDeviation.id:
            episodes = pairedErrorEpisodes(log: log, command: .lambdaCommanded, actual: .lambdaMeasured,
                rule: .init(id:"lambda.absolute-error", enterThreshold:0.05, confirmDuration:0.15, exitThreshold:0.025, recoveryDuration:0.15, directionAbove:true, provenance:"PredatorLab authored lambda-error heuristic"),
                investigationID: definition.id, boundary:"Lambda deviation alone does not identify fuel delivery, sensor, exhaust, or calibration cause.", relative:false)
        case InvestigationCatalog.throttleClosure.id:
            episodes = pairedErrorEpisodes(log: log, command: .throttleCommanded, actual: .throttleActual,
                rule: .init(id:"throttle.command-actual-error", enterThreshold:10.0, confirmDuration:0.10, exitThreshold:5.0, recoveryDuration:0.10, directionAbove:true, provenance:"PredatorLab authored throttle-tracking heuristic"),
                investigationID: definition.id, boundary:"Command/actual separation does not prove throttle-body hardware failure.", relative:false)
        case InvestigationCatalog.knock.id:
            episodes = singleChannelEpisodes(log: log, channel:.knockRetard,
                rule:.init(id:"knock.retard-candidate", enterThreshold:2.0, confirmDuration:0.10, exitThreshold:1.0, recoveryDuration:0.15, directionAbove:true, provenance:"PredatorLab authored knock-retard candidate heuristic"),
                investigationID:definition.id, boundary:"Logged knock retard is controller response and is not direct proof of combustion knock.")
        case InvestigationCatalog.boostControl.id:
            if boostSource == .manifoldPressure { warnings.append("No boost channel logged; boost-rate analysis uses manifold absolute pressure.") }
            episodes = rateOfChangeEpisodes(log: log, channel:boostSource,
                rule:.init(id:"boost.rapid-loss", enterThreshold:8.0, confirmDuration:0.10, exitThreshold:3.0, recoveryDuration:0.15, directionAbove:true, provenance:"PredatorLab authored pressure-rate candidate heuristic"),
                investigationID:definition.id, boundary:"Rapid boost change does not isolate airflow hardware from intentional control intervention.")
        case InvestigationCatalog.thermal.id:
            episodes = thermalDeltaEpisodes(log: log, investigationID:definition.id)
        case InvestigationCatalog.dctTransient.id:
            episodes = shiftDurationEpisodes(log: log, investigationID:definition.id)
        default:
            episodes = []
        }
        return .init(investigationID: definition.id, episodes: episodes, missingChannels: missing, warnings: warnings)
    }

    static func executeAll(log: ParsedLogData) -> [DomainDiagnosticExecutionReport] {
        InvestigationCatalog.all.filter { $0.id != InvestigationCatalog.r04.id }.map { execute($0, log: log) }
    }

    private static func aligned(_ channel: CanonicalChannel, log: ParsedLogData) -> [Double?]? {
        guard let raw = ChannelResolver.resolve(channel, in: log.channels) else { return nil }
        return log.getAlignedNumericChannel(raw)
    }

    private static func pairedErrorEpisodes(log: ParsedLogData, command: CanonicalChannel, actual: CanonicalChannel, rule: DiagnosticStateMachineRule, investigationID: String, boundary: String, relative: Bool) -> [ExecutedDiagnosticEpisode] {
        guard let c = aligned(command, log:log), let a = aligned(actual, log:log) else { return [] }
        let samples: [(TimeInterval,Double)] = log.timestamps.indices.compactMap { i in
            guard i < c.count, i < a.count, let cv=c[i], let av=a[i] else { return nil }
            let error = relative ? (abs(cv) > 0.000001 ? abs(av-cv)/abs(cv) : nil) : abs(av-cv)
            guard let error else { return nil }; return (log.timestamps[i], error)
        }
        return convert(DiagnosticStateMachine.evaluate(samples:samples, rule:rule), samples:samples, investigationID:investigationID, boundary:boundary, provenance:rule.provenance)
    }

    private static func singleChannelEpisodes(log: ParsedLogData, channel: CanonicalChannel, rule: DiagnosticStateMachineRule, investigationID:String, boundary:String) -> [ExecutedDiagnosticEpisode] {
        guard let values=aligned(channel,log:log) else { return [] }
        let samples = log.timestamps.indices.compactMap { i -> (TimeInterval,Double)? in guard i < values.count, let v=values[i] else{return nil}; return (log.timestamps[i],abs(v)) }
        return convert(DiagnosticStateMachine.evaluate(samples:samples,rule:rule),samples:samples,investigationID:investigationID,boundary:boundary,provenance:rule.provenance)
    }

    private static func rateOfChangeEpisodes(log: ParsedLogData, channel:CanonicalChannel, rule:DiagnosticStateMachineRule, investigationID:String, boundary:String) -> [ExecutedDiagnosticEpisode] {
        guard let values=aligned(channel,log:log) else{return []}; var samples:[(TimeInterval,Double)]=[]
        for i in 1..<min(values.count,log.timestamps.count) { guard let p=values[i-1],let v=values[i] else{continue}; let dt=log.timestamps[i]-log.timestamps[i-1]; guard dt>0 else{continue}; samples.append((log.timestamps[i],abs(v-p)/dt)) }
        return convert(DiagnosticStateMachine.evaluate(samples:samples,rule:rule),samples:samples,investigationID:investigationID,boundary:boundary,provenance:rule.provenance)
    }

    private static func thermalDeltaEpisodes(log:ParsedLogData, investigationID:String)->[ExecutedDiagnosticEpisode] {
        guard let i1=aligned(.iat1,log:log),let i2=aligned(.iat2,log:log) else{return []}
        let rule=DiagnosticStateMachineRule(id:"thermal.iat2-minus-iat1",enterThreshold:35,confirmDuration:5,exitThreshold:25,recoveryDuration:5,directionAbove:true,provenance:"PredatorLab authored temperature-delta candidate heuristic; source units must be verified")
        let samples=log.timestamps.indices.compactMap { i -> (TimeInterval,Double)? in guard i<i1.count,i<i2.count,let a=i1[i],let b=i2[i] else{return nil}; return(log.timestamps[i],b-a) }
        return convert(DiagnosticStateMachine.evaluate(samples:samples,rule:rule),samples:samples,investigationID:investigationID,boundary:"Temperature delta is a thermal observation, not a cooling-component diagnosis.",provenance:rule.provenance)
    }

    /// Time from leaving one gear to settling in the next. A DCT gear channel that switches in a
    /// single sample has zero measurable duration; only transitions that pass through intermediate
    /// or neutral values for longer than 0.35 s are flagged.
    private static func shiftDurationEpisodes(log:ParsedLogData, investigationID:String)->[ExecutedDiagnosticEpisode] {
        guard let gear=aligned(.gearActual,log:log) ?? aligned(.gearCommanded,log:log), gear.count==log.timestamps.count else{return []}
        let settleSamples=3
        var out:[ExecutedDiagnosticEpisode]=[]
        var stableGear:Double?; var leftAt:TimeInterval?; var candidate:Double?; var candidateCount=0
        for i in gear.indices {
            guard let g=gear[i] else{continue}
            guard let stable=stableGear else { stableGear=g; continue }
            if g==stable { leftAt=nil; candidate=nil; candidateCount=0; continue }
            if leftAt==nil { leftAt=log.timestamps[i] }
            if g==candidate { candidateCount+=1 } else { candidate=g; candidateCount=1 }
            let isDriveGear = g >= 1 && g.rounded()==g
            guard isDriveGear, candidateCount>=settleSamples, let start=leftAt else{continue}
            let settledAt=log.timestamps[i-settleSamples+1]
            let duration=settledAt-start
            if duration>=0.35 {
                out.append(.init(id:UUID(),investigationID:investigationID,ruleID:"dct.shift-duration-candidate",start:start,end:settledAt,peakMagnitude:duration,provenance:"PredatorLab authored shift-duration candidate heuristic",evidenceBoundary:"Gear-state timing alone cannot identify clutch or transmission hardware failure."))
            }
            stableGear=g; leftAt=nil; candidate=nil; candidateCount=0
        }
        return out
    }

    private static func convert(_ result:DiagnosticStateMachineResult,samples:[(TimeInterval,Double)],investigationID:String,boundary:String,provenance:String)->[ExecutedDiagnosticEpisode] {
        result.confirmedIntervals.map { interval in
            let peak=samples.filter{interval.contains($0.0)}.map{$0.1}.max() ?? 0
            return .init(id:UUID(),investigationID:investigationID,ruleID:result.ruleID,start:interval.lowerBound,end:interval.upperBound,peakMagnitude:peak,provenance:provenance,evidenceBoundary:boundary)
        }
    }
}

extension DomainDiagnosticExecutionEngine {
    /// Builds a cross-domain temporal sequence from executed candidate episodes.
    /// Ordering is observational only and must not be presented as proof of causation.
    static func firstOutSequence(reports:[DomainDiagnosticExecutionReport], anchor:TimeInterval, window:ClosedRange<TimeInterval>) -> [FirstOutItem] {
        let episodes = reports.flatMap(\.episodes).map { e in
            LogEventEpisode(eventType:e.ruleID,start:e.start,peak:e.start,end:e.end,severity:"candidate",description:e.evidenceBoundary,sampleCount:0,peakValues:["magnitude":e.peakMagnitude],sourceStates:["provenance":e.provenance])
        }
        return FirstOutTimelineEngine.build(episodes:episodes,anchor:anchor,window:window)
    }
}

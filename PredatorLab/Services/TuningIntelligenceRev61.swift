import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

// Rev61: track-session intelligence, spatial Flight Recorder anchoring, TDN lineage,
// experiment comparability, and a provenance-first GT500/TR_C75 parameter semantic registry.

enum TrackSessionMode: String, Codable, CaseIterable { case circuit, segment, drag, raw, trail, unknown }
struct TrackSectorDefinition: Identifiable, Codable, Equatable { let id:UUID; let name:String; let startTime:Double; let endTime:Double }
struct TrackLapSummary: Identifiable, Codable, Equatable {
    let id:UUID; let index:Int; let startTime:Double; let endTime:Double; let duration:Double
    let maximumSpeed:Double?; let maximumRPM:Double?; let peakLateralG:Double?; let peakLongitudinalG:Double?
    let sampleCount:Int; let sectors:[TrackSectorDefinition]
}
struct TrackSessionIntelligence: Codable, Equatable {
    let mode:TrackSessionMode; let laps:[TrackLapSummary]; let gpsSampleCount:Int; let rejectedRows:Int
    let distanceProxy:Double?; let boundary:String
}

enum TrackSessionIntelligenceEngine {
    // Uses explicit lap/sector markers supplied by an imported source or human review. It does not invent track geometry.
    static func summarize(session:TrackAddictParsedSession, mode:TrackSessionMode, lapWindows:[ClosedRange<Double>] = []) -> TrackSessionIntelligence {
        let timed=session.samples.compactMap { s -> (TrackAddictSample,Double)? in guard let t=s.time else{return nil}; return (s,t) }
        let windows = lapWindows.isEmpty ? inferredSingleWindow(timed) : lapWindows
        let laps = windows.enumerated().map { index,w in
            let rows=timed.filter{w.contains($0.1)}.map(\.0)
            func absMax(_ values:[Double]) -> Double? { values.map(abs).max() }
            return TrackLapSummary(id:UUID(),index:index+1,startTime:w.lowerBound,endTime:w.upperBound,duration:w.upperBound-w.lowerBound,maximumSpeed:rows.compactMap(\.speed).max(),maximumRPM:rows.compactMap(\.rpm).max(),peakLateralG:absMax(rows.compactMap(\.lateralG)),peakLongitudinalG:absMax(rows.compactMap(\.longitudinalG)),sampleCount:rows.count,sectors:[])
        }
        let gps=timed.filter{$0.0.latitude != nil && $0.0.longitude != nil}.count
        return .init(mode:mode,laps:laps,gpsSampleCount:gps,rejectedRows:session.rejectedRowCount,distanceProxy:nil,boundary:"Lap and sector summaries require explicit imported or reviewed boundaries. A faster lap or sector does not establish calibration causation, and GPS-derived geometry remains acquisition-quality dependent.")
    }
    private static func inferredSingleWindow(_ timed:[(TrackAddictSample,Double)]) -> [ClosedRange<Double>] { guard let a=timed.first?.1, let b=timed.last?.1, b>a else{return []}; return [a...b] }
}

struct SpatialFlightRecorderAnchor: Identifiable, Codable, Equatable {
    let id:UUID; let eventID:UUID; let referenceTime:Double; let latitude:Double?; let longitude:Double?; let speed:Double?; let rpm:Double?; let nearestSampleDelta:Double; let quality:String; let boundary:String
}
enum SpatialFlightRecorderEngine {
    static func anchor(eventID:UUID, referenceTime:Double, samples:[SynchronizedTrackSample], maximumDelta:Double=0.25) -> SpatialFlightRecorderAnchor? {
        guard let nearest=samples.min(by:{abs($0.referenceTime-referenceTime)<abs($1.referenceTime-referenceTime)}) else{return nil}
        let delta=abs(nearest.referenceTime-referenceTime); guard delta <= maximumDelta else{return nil}
        return .init(id:UUID(),eventID:eventID,referenceTime:referenceTime,latitude:nearest.latitude,longitude:nearest.longitude,speed:nearest.speed,rpm:nearest.rpm,nearestSampleDelta:delta,quality:delta <= 0.05 ? "strong temporal match" : "bounded temporal match",boundary:"Spatial anchoring identifies the nearest synchronized sample within the admitted tolerance. It does not prove the source clocks were correctly aligned or that the event was caused by track position.")
    }
}

struct TuneExperimentComparability: Codable, Equatable { let score:Double; let hardBlockers:[String]; let differences:[String]; let comparable:Bool; let boundary:String }
enum TuneExperimentComparabilityEngine {
    static func compare(buildMatched:Bool, pcmMatched:Bool, tcmMatched:Bool, scannerSemanticsMatched:Bool, modeMatched:Bool, thermalStartDifferenceC:Double?, fuelMatched:Bool) -> TuneExperimentComparability {
        var blockers:[String]=[], differences:[String]=[]; var score=1.0
        if !buildMatched { blockers.append("Build revision differs") }
        if !pcmMatched { blockers.append("PCM calibration differs outside the intended experiment") }
        if !tcmMatched { differences.append("TCM calibration differs"); score -= 0.15 }
        if !scannerSemanticsMatched { blockers.append("Scanner semantics/configuration are not comparable") }
        if !modeMatched { differences.append("Track/test mode differs"); score -= 0.15 }
        if !fuelMatched { blockers.append("Fuel configuration differs") }
        if let d=thermalStartDifferenceC { if d > 20 { blockers.append("Starting thermal state differs by more than 20 C") } else if d > 10 { differences.append("Starting thermal state differs by more than 10 C"); score -= 0.15 } }
        score=max(0,min(1,score-Double(blockers.count)*0.25))
        return .init(score:score,hardBlockers:blockers,differences:differences,comparable:blockers.isEmpty && score >= 0.70,boundary:"Comparability measures whether two experiments can support a controlled comparison. It is not a tune-quality, safety, or causality score.")
    }
}

enum TDNLineageState:String,Codable { case vehicleRead="Vehicle read", synchronized="Read synchronized", tuneReceived="Tune received", flashStarted="Flash started", flashCompleted="Flash completed", logRecorded="Log recorded", logDelivered="Log delivered", revisionReceived="Revision received", accepted="Accepted", rejected="Rejected" }
struct TDNLineageEvent:Identifiable,Codable,Equatable { let id:UUID; let occurredAt:Date; let state:TDNLineageState; let vehicleID:UUID?; let calibrationID:UUID?; let artifactID:UUID?; let note:String }
struct TDNLineageAudit:Codable,Equatable { let ordered:[TDNLineageEvent]; let warnings:[String]; let boundary:String }
enum TDNLineageEngine {
    static func audit(_ events:[TDNLineageEvent]) -> TDNLineageAudit {
        let ordered=events.sorted{$0.occurredAt<$1.occurredAt}; var warnings:[String]=[]
        if ordered.contains(where:{$0.state == .flashCompleted}) && !ordered.contains(where:{$0.state == .tuneReceived}) { warnings.append("A completed flash has no recorded tune-received event.") }
        if ordered.contains(where:{$0.state == .logDelivered}) && !ordered.contains(where:{$0.state == .logRecorded}) { warnings.append("A delivered log has no recorded log-acquisition event.") }
        return .init(ordered:ordered,warnings:warnings,boundary:"TDN lineage records workflow evidence. It does not claim server-side state, tuner authorship, or controller support unless those facts are independently captured.")
    }
}

enum CalibrationSemanticStatus:String,Codable { case documented="Documented", exposed="Exposed; semantics incomplete", professional="Professional interpretation", empirical="Empirical mapping", inferred="PredatorLab inference", unknown="Unknown" }
struct CalibrationSemanticRecord:Identifiable,Codable,Equatable {
    let id:String; let controller:TuningControllerFamily; let displayName:String; let engineeringDomain:String
    let sourcePath:String?; let units:String?; let status:CalibrationSemanticStatus; let authority:CalibrationEvidenceAuthority
    let applicableStrategies:[String]; let relatedScannerSemanticIDs:[String]; let notes:String; let boundary:String
}
enum GT500CalibrationSemanticRegistry {
    // Seed only controller-level concepts that public documentation supports. Exact GT500 table names/values remain acquisition targets.
    static let seeds:[CalibrationSemanticRecord] = [
        .init(id:"trc75.shift.control.research",controller:.trC75,displayName:"Shift control parameter family",engineeringDomain:"Transmission / shift",sourcePath:nil,units:nil,status:.unknown,authority:.unknown,applicableStrategies:[],relatedScannerSemanticIDs:[],notes:"TR_C75 is a separately supported tuning controller; exact parameter inventory must be acquired from applicable definitions.",boundary:"Controller support does not verify any specific table name, axis, value, pressure target, or strategy semantic."),
        .init(id:"gt500.torque.arbitration.research",controller:.gt500PCM,displayName:"Torque arbitration concept",engineeringDomain:"Engine / torque",sourcePath:nil,units:nil,status:.inferred,authority:.inference,applicableStrategies:[],relatedScannerSemanticIDs:[],notes:"Research target for driver, engine, protection and transmission torque interactions.",boundary:"This is an engineering research concept, not an OEM parameter definition."),
        .init(id:"tc298b.controlpack.boundary",controller:.tc298b,displayName:"Predator Control Pack calibration family",engineeringDomain:"Control Pack",sourcePath:nil,units:nil,status:.documented,authority:.ford,applicableStrategies:[],relatedScannerSemanticIDs:[],notes:"Keep Control Pack calibration/harness evidence separate from production GT500 PCM wiring and calibration truth.",boundary:"Control Pack evidence cannot be promoted into production GT500 calibration semantics without exact applicable evidence."),
        .init(id:"mg1cs036.crossplatform.boundary",controller:.mg1cs036,displayName:"Raptor R comparative calibration family",engineeringDomain:"Cross-platform research",sourcePath:nil,units:nil,status:.documented,authority:.hpTuners,applicableStrategies:[],relatedScannerSemanticIDs:[],notes:"Use for concept comparison only until exact parameter definitions and applicability are acquired.",boundary:"Shared 5.2L supercharged architecture does not authorize GT500/Raptor R raw-value transfer.")
    ]
}

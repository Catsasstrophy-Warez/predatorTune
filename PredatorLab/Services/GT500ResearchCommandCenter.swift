import Foundation

enum ResearchProgram: String, Codable, CaseIterable { case workshop = "Ford Workshop", calibration = "Calibration / HP Tuners", track = "TrackAddict", remote = "TDN Remote Tuning" }

enum ArtifactAcquisitionState: String, Codable, CaseIterable {
    case missing = "Missing"
    case sourceLocated = "Source Located"
    case sourceVerified = "Source Verified"
    case acquired = "Acquired"
    case structured = "Structured"
    case crossVerified = "Cross-Verified"
    case vehicleValidated = "Vehicle Validated"
    case scopeComplete = "Complete for Current Scope"
    case partial = "Partial"
    case restricted = "Restricted / unknown"
}

struct ResearchAcquisitionTarget: Identifiable, Codable, Equatable {
    let id: String
    let program: ResearchProgram
    let title: String
    let exactArtifact: String
    let applicability: String
    let authority: String
    let state: ArtifactAcquisitionState
    let truthDomains: [TechnicalTruthDomain]
    let keywords: [String]
    let consequenceWeight: Int
    let strategicWeight: Int
    let sourceLocator: String?
    let acceptanceCriteria: [String]
    let forbiddenSubstitutions: [String]
}

struct ResearchLeverageResult: Identifiable, Codable, Equatable {
    let id: String
    let target: ResearchAcquisitionTarget
    let eligibleTruthIDs: [String]
    let debtRetirableForReview: Int
    let highConsequenceClaims: Int
    let disputedClaims: Int
    let leverageScore: Int
    let boundary: String
}

struct CoverageProvenanceDrilldown: Identifiable, Codable, Equatable {
    let id: String
    let subsystem: String
    let entries: [TechnicalTruthLedgerEntry]
    let acquisitionTargets: [ResearchLeverageResult]
}

enum GT500WorkshopAcquisitionMatrix {
    static let targets: [ResearchAcquisitionTarget] = [
        .init(id:"ford.wiring.production",program:.workshop,title:"Production Wiring + Connector Views",exactArtifact:"2020, 2021 and 2022 Shelby GT500 Wiring Diagrams and Connector Views",applicability:"Production GT500; exact model year and build configuration",authority:"Ford",state:.sourceVerified,truthDomains:[.circuit,.topology,.sensor],keywords:["connector","pin","circuit","wire","ground","power","can","fuel"],consequenceWeight:100,strategicWeight:100,sourceLocator:"FordServiceContent 2020–2022 Mustang owner/service information + NHTSA-hosted Ford SSM 49581 (C105)",acceptanceCriteria:["exact model-year applicability","connector/cavity locator","circuit identity","retrievable Ford locator"],forbiddenSubstitutions:["Ford Performance control-pack harness","forum pinout","adjacent Mustang trim"]),
        .init(id:"ford.pced",program:.workshop,title:"GT500 PC/ED + Pinpoint Diagnostics",exactArtifact:"Applicable Ford Powertrain Control/Emissions Diagnosis and WSM pinpoint tests",applicability:"2020–2022 GT500 by controller/strategy",authority:"Ford",state:.sourceLocated,truthDomains:[.dtc,.sensor,.circuit,.calibration],keywords:["expected","test","monitor","threshold","sensor","fuel","voltage","rationality"],consequenceWeight:98,strategicWeight:99,sourceLocator:nil,acceptanceCriteria:["exact test identifier","specified conditions","expected result","model-year/controller applicability"],forbiddenSubstitutions:["generic OBD tree","community diagnostic procedure"]),
        .init(id:"ford.predator.30301f",program:.workshop,title:"Predator Engine Internals",exactArtifact:"Ford WSM 303-01F 5.2L supercharged engine mechanical specifications and overhaul procedures",applicability:"5.2L Predator / GT500",authority:"Ford",state:.partial,truthDomains:[.procedure],keywords:["clearance","bearing","endplay","ring","piston","valve","torque","timing"],consequenceWeight:95,strategicWeight:92,sourceLocator:"WSM 303-01F",acceptanceCriteria:["nominal vs service limit","measurement method","units","exact Predator applicability"],forbiddenSubstitutions:["Coyote values","GT350 values","builder preference"]),
        .init(id:"ford.magneride.vdm",program:.workshop,title:"MagneRide / VDM",exactArtifact:"GT500 VDM/MagneRide wiring, damper control, sensors, DTCs and pinpoint tests",applicability:"2020–2022 GT500; base/CFTP where different",authority:"Ford",state:.sourceVerified,truthDomains:[.circuit,.topology,.sensor,.dtc],keywords:["magne","damper","vehicle dynamics","vdm","ride"],consequenceWeight:93,strategicWeight:91,sourceLocator:nil,acceptanceCriteria:["VDM identity","damper/test-point locator","measurement conditions","DTC pinpoint path"],forbiddenSubstitutions:["generic MagneRide article","other Ford platform without applicability"]),
        .init(id:"ford.abs.epb",program:.workshop,title:"ABS / AdvanceTrac / EPB",exactArtifact:"GT500 ABS, wheel-speed, stability and electronic parking brake WSM + wiring",applicability:"2020–2022 GT500",authority:"Ford",state:.sourceVerified,truthDomains:[.circuit,.topology,.sensor,.dtc],keywords:["abs","wheel speed","parking brake","stability","brake"],consequenceWeight:96,strategicWeight:90,sourceLocator:nil,acceptanceCriteria:["module connector topology","wheel-speed test semantics","hydraulic/electrical pinpoint paths"],forbiddenSubstitutions:["SSM software note used as complete wiring proof"]),
        .init(id:"ford.epas",program:.workshop,title:"EPAS / PSCM",exactArtifact:"GT500 EPAS/PSCM steering gear wiring, torque sensing, network and pinpoint diagnostics",applicability:"2020–2022 GT500",authority:"Ford",state:.sourceVerified,truthDomains:[.circuit,.topology,.sensor,.dtc],keywords:["epas","steering","pscm","torque sensor"],consequenceWeight:96,strategicWeight:88,sourceLocator:nil,acceptanceCriteria:["production steering gear applicability","power/ground/CAN","sensor/test conditions"],forbiddenSubstitutions:["replacement-part recall generalized to all production racks"]),
        .init(id:"ford.fuel.production",program:.workshop,title:"Production Fuel Control",exactArtifact:"GT500 production fuel delivery/control wiring, pressure feedback, PCM strategy diagnostics and pinpoint tests",applicability:"2020–2022 production GT500",authority:"Ford",state:.sourceVerified,truthDomains:[.circuit,.topology,.sensor,.dtc,.calibration],keywords:["fuel","pressure","pump","injector","lambda"],consequenceWeight:99,strategicWeight:94,sourceLocator:nil,acceptanceCriteria:["production architecture","command/feedback semantics","specified test conditions"],forbiddenSubstitutions:["M-6017-M52SC return-style control pack"]),
        .init(id:"ford.sensors.pced",program:.workshop,title:"Sensor-by-Sensor Workshop Matrix",exactArtifact:"GT500 sensor locations, connectors, reference/signal tests, waveforms and removal procedures",applicability:"2020–2022 by sensor/controller",authority:"Ford",state:.sourceLocated,truthDomains:[.sensor,.circuit,.dtc],keywords:["sensor","expected","signal","reference","waveform"],consequenceWeight:90,strategicWeight:93,sourceLocator:nil,acceptanceCriteria:["exact sensor identity","terminal/test condition","expected measurement","source locator"],forbiddenSubstitutions:["scanner label treated as physical sensor proof"])
    ]
}

enum HPTunersAcquisitionMatrix {
    static let targets: [ResearchAcquisitionTarget] = [
        .init(id:"hpt.gt500.pcm.definitions",program:.calibration,title:"GT500 PCM Definition Corpus",exactArtifact:"Complete stock 2020–2022 GT500 VCM Editor parameter/help inventory by controller OS/strategy",applicability:"Production GT500 only; strategy-specific",authority:"HP Tuners + vehicle read provenance",state:.missing,truthDomains:[.calibration,.dtc],keywords:["calibration","stock","torque","spark","fuel","airflow","boost","thermal","threshold"],consequenceWeight:98,strategicWeight:100,sourceLocator:"HP Tuners VCM Editor",acceptanceCriteria:["controller identity","OS/strategy","VCM Suite version","parameter path/type/units/axes"],forbiddenSubstitutions:["TC-298B values presented as production GT500","adjacent Ford strategy"]),
        .init(id:"hpt.trc75.definitions",program:.calibration,title:"TR_C75 Definition + Stock Corpus",exactArtifact:"2020–2022 GT500 TR_C75 VCM Editor definitions, stock calibrations and matching Scanner channels",applicability:"TR-9070 GT500 TCM by strategy",authority:"HP Tuners / TREMEC / Ford integration evidence",state:.missing,truthDomains:[.calibration,.dtc],keywords:["transmission","shift","clutch","torque","thermal","launch","gear"],consequenceWeight:96,strategicWeight:99,sourceLocator:"HP Tuners supported Ford TR C75",acceptanceCriteria:["TCM strategy identity","parameter semantics","units/axes","matching observed channels"],forbiddenSubstitutions:["generic DCT calibration","TREMEC architecture used as Ford table semantics"]),
        .init(id:"hpt.tc298b",program:.calibration,title:"TC-298B Predator Control Pack Atlas",exactArtifact:"Complete TC-298B VCM Editor definition inventory + stock control-pack calibration",applicability:"Ford Performance 5.2L GT500 Predator Control Pack only",authority:"HP Tuners / Ford Performance",state:.sourceVerified,truthDomains:[.calibration],keywords:["calibration","spark","fuel","airflow","torque","boost"],consequenceWeight:75,strategicWeight:86,sourceLocator:"HP Tuners Ford vehicle support",acceptanceCriteria:["TC-298B identity","control-pack applicability","definition version"],forbiddenSubstitutions:["production GT500 calibration truth"]),
        .init(id:"hpt.raptorr.mg1",program:.calibration,title:"Raptor R MG1CS036 Comparative Atlas",exactArtifact:"2023+ Raptor R MG1CS036 stock definitions/calibrations/logs by model year",applicability:"Raptor R only; model-year/strategy specific",authority:"HP Tuners",state:.partial,truthDomains:[.calibration],keywords:["calibration","torque","spark","fuel","airflow","thermal"],consequenceWeight:68,strategicWeight:82,sourceLocator:"HP Tuners MG1CS036 Raptor R support",acceptanceCriteria:["MG1CS036 strategy identity","model year","definition version","stock provenance"],forbiddenSubstitutions:["raw Raptor R values transferred to GT500"]),
        .init(id:"hpt.scanner.stock",program:.calibration,title:"Known-Good Scanner Corpus",exactArtifact:"Stock GT500 HPL logs + XML Scanner configurations with parameter IDs, source, polling interval and transforms",applicability:"Exact GT500/controller/build/tune",authority:"HP Tuners acquisition + empirical vehicle evidence",state:.partial,truthDomains:[.sensor,.calibration],keywords:["sensor","expected","calibration","fuel","spark","pressure"],consequenceWeight:94,strategicWeight:98,sourceLocator:"VCM Scanner / TDN",acceptanceCriteria:["matching calibration hash","scanner XML","observed sample quality","build revision"],forbiddenSubstitutions:["unidentified internet log"]),
        .init(id:"trackaddict.session.schema",program:.track,title:"TrackAddict Session Evidence Corpus",exactArtifact:"Native TrackAddict CSV/video/TAD/note session examples with GPS/OBD source and timing metadata",applicability:"iOS/iPadOS PredatorLab track/drag validation",authority:"HP Tuners TrackAddict documentation + empirical sessions",state:.partial,truthDomains:[.sensor],keywords:["sensor","speed","temperature"],consequenceWeight:70,strategicWeight:88,sourceLocator:"HP Tuners TrackAddict User Guide",acceptanceCriteria:["native session identity","CSV/video pairing","GPS source/rate","OBD source","timebase"],forbiddenSubstitutions:["lap time treated as calibration causality"]),
        .init(id:"tdn.remote.bundle",program:.remote,title:"TDN Remote Tune Evidence Bundle",exactArtifact:"Matched HPT + HPL + assigned Scanner XML + TDN lineage for GT500 remote tuning sessions",applicability:"Exact vehicle/controller/tuner session",authority:"HP Tuners TDN + user/tuner artifacts",state:.sourceVerified,truthDomains:[.calibration,.sensor],keywords:["calibration","sensor","expected"],consequenceWeight:84,strategicWeight:96,sourceLocator:"TDN vehicle files",acceptanceCriteria:["vehicle identity","read/tune lineage","assigned scanner config","matching log","flash event"],forbiddenSubstitutions:["filename-only tune ancestry"])
    ]
}

enum GT500ResearchCommandCenterEngine {
    static let boundary = "Leverage estimates which exact artifact could make the largest amount of high-consequence truth debt eligible for human claim review. It is not truth confidence, vehicle health, tune quality, or automatic verification."
    static var targets: [ResearchAcquisitionTarget] { GT500WorkshopAcquisitionMatrix.targets + HPTunersAcquisitionMatrix.targets }

    static func rank(entries: [TechnicalTruthLedgerEntry]) -> [ResearchLeverageResult] {
        let debtByID = Dictionary(uniqueKeysWithValues: TechnicalTruthDebtEngine.rank(entries).map { ($0.truthID, $0) })
        return targets.map { target in
            let matches = entries.filter { entry in
                guard target.truthDomains.contains(entry.domain), entry.disposition != .verified, entry.disposition != .superseded else { return false }
                let haystack = ([entry.statement, entry.ownerTitle, entry.authoredValue ?? "", entry.condition ?? ""]).joined(separator:" ").lowercased()
                if target.keywords.isEmpty { return true }
                return target.keywords.contains { haystack.contains($0.lowercased()) } || target.truthDomains.count == 1
            }
            let debt = matches.reduce(0) { $0 + (debtByID[$1.id]?.score ?? 0) }
            let high = matches.filter { $0.criticality >= .diagnostic }.count
            let disputed = matches.filter { $0.disposition == .disputed }.count
            let score = target.strategicWeight + target.consequenceWeight + min(1000, debt / 2) + high * 18 + disputed * 25
            return .init(id:target.id,target:target,eligibleTruthIDs:matches.map(\.id),debtRetirableForReview:debt,highConsequenceClaims:high,disputedClaims:disputed,leverageScore:score,boundary:boundary)
        }.sorted { ($0.leverageScore, $0.highConsequenceClaims, $0.id) > ($1.leverageScore, $1.highConsequenceClaims, $1.id) }
    }

    static func drilldown(cell: VerificationCoverageCell, entries: [TechnicalTruthLedgerEntry]) -> CoverageProvenanceDrilldown {
        let group = entries.filter { subsystem($0) == cell.subsystem }
        let ids = Set(group.map(\.id))
        let targets = rank(entries: entries).filter { !ids.isDisjoint(with: Set($0.eligibleTruthIDs)) }
        return .init(id:cell.id,subsystem:cell.subsystem,entries:group,acquisitionTargets:targets)
    }

    static func subsystem(_ entry: TechnicalTruthLedgerEntry) -> String {
        switch entry.domain { case .circuit,.topology: return "Electrical / Wiring"; case .sensor: return "Sensors / Measurements"; case .dtc: return "Diagnostics / DTC Logic"; case .procedure: return "Service Procedures"; case .calibration: return "Calibration" }
    }
}

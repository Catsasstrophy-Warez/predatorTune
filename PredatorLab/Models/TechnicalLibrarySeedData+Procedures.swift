// Rev39 decomposed technical seed category. Evidence status preserved from authored source.
import Foundation

extension TechnicalLibrarySeedData {
    // MARK: - Procedures

    static func seedProcedures() -> [ProcedureRecord] {
        [superchargerPulleyReplacement(), sparkPlugReplacement(), fuelInjectorService(), dctClutchService()]
    }

    static func superchargerPulleyReplacement() -> ProcedureRecord {
        let manual = WorkshopReference(manual: "2020 Mustang Workshop Manual", section: "303-05A Accessory Drive", partNumber: nil, publisher: "Ford Motor Company", url: nil)
        let source = TechnicalSource(title: "GT500 Supercharger Pulley Service", sourceType: "Ford WSM", reference: "303-05A", grade: .a_factory, confidence: .c3)
        return ProcedureRecord(
            id: UUID(),
            name: "Supercharger Pulley Replacement (TVS R2650)",
            system: .supercharger,
            subsystem: "Supercharger drive",
            purpose: "Swap the supercharger drive pulley to change boost level, or replace a worn/damaged stock pulley — requires a corresponding calibration change to remain safe",
            applicability: ProcedureApplicability(modelYears: [2020, 2021, 2022], variants: ["Base", "Carbon Fiber Track Pack"], buildStates: nil, notes: "Applies to all 2020-2022 GT500 with the TVS R2650 supercharger"),
            difficulty: .advanced,
            estimatedTime: 3600 * 3,
            skillRequired: "Experienced DIY / professional shop; requires precise pulley puller/installer tools and belt routing knowledge",
            lifting: true,
            tools: [
                Tool(name: "Supercharger pulley puller kit", description: "Purpose-built puller for the press-fit pulley hub", partNumber: nil, critical: true, rental: true, alternativeMethods: nil, cost: 150),
                Tool(name: "Pulley installer/press tool", description: "Installs new pulley to correct seating depth without damaging the hub", partNumber: nil, critical: true, rental: true, alternativeMethods: nil, cost: 120),
                Tool(name: "Torque wrench, 3/8\" drive, 10-100 lb-ft", description: nil, partNumber: nil, critical: true, rental: false, alternativeMethods: nil, cost: nil),
                Tool(name: "Serpentine belt routing tool/diagram", description: nil, partNumber: nil, critical: false, rental: false, alternativeMethods: ["Photograph existing routing before removal"], cost: nil)
            ],
            parts: [
                Part(name: "Supercharger drive pulley (desired size)", motorcraft: nil, oem: nil, quantity: 1, critical: true, onceOnly: false, cost: 250, vendor: "Aftermarket supercharger pulley supplier", notes: "Smaller pulley increases boost; must be paired with a matching calibration"),
                Part(name: "Pulley retaining bolt", motorcraft: nil, oem: nil, quantity: 1, critical: true, onceOnly: true, cost: 8, vendor: "Ford dealer parts", notes: "One-time-use torque-to-yield style fastener, always replace")
            ],
            consumables: [
                Consumable(name: "Threadlocker, medium strength", specification: "Loctite 243", quantity: 1, units: "application", cost: 8, vendor: nil)
            ],
            safetyWarnings: [
                "Engine must be completely cool before starting",
                "Disconnect the battery negative terminal before working near the accessory drive",
                "Do not exceed the pulley manufacturer's boost rating without a corresponding fuel system/calibration review"
            ],
            steps: [
                ProcedureStep(order: 1, instruction: "Disconnect battery negative terminal and allow engine to fully cool", duration: 600, tools: ["10mm wrench"], parts: nil, consumables: nil, warnings: ["Never work on a hot supercharger/engine"], inspectionPoints: nil, torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 2, instruction: "Photograph the accessory belt routing, then release tensioner and remove the serpentine belt", duration: 900, tools: ["3/8\" breaker bar for tensioner"], parts: nil, consumables: nil, warnings: nil, inspectionPoints: ["Inspect belt for glazing/cracking while removed"], torqueSpec: nil, youTubeChapter: nil, diagramReference: "Ford WSM 303-05A belt routing diagram", notes: nil),
                ProcedureStep(order: 3, instruction: "Remove the supercharger pulley retaining bolt and use the puller kit to remove the stock pulley from the rotor shaft", duration: 2400, tools: ["Pulley puller kit", "impact wrench for bolt removal"], parts: nil, consumables: nil, warnings: ["Do not strike the rotor shaft directly; use the puller as designed to avoid bearing damage"], inspectionPoints: ["Inspect rotor shaft snout for damage or corrosion"], torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 4, instruction: "Press the new pulley onto the rotor shaft to the specified seating depth using the installer tool", duration: 1800, tools: ["Pulley installer/press tool"], parts: ["Supercharger drive pulley"], consumables: nil, warnings: ["Uneven pressing force can damage the internal rotor bearing"], inspectionPoints: nil, torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 5, instruction: "Apply threadlocker and torque the new pulley retaining bolt to spec", duration: 300, tools: ["Torque wrench"], parts: ["Pulley retaining bolt"], consumables: ["Loctite 243"], warnings: nil, inspectionPoints: nil, torqueSpec: TorqueSpec(component: "Supercharger pulley retaining bolt", value: 18, units: "lb-ft", pattern: nil, preload: nil, notes: "Follow Ford WSM spec; verify against the specific pulley manufacturer's instructions", source: source), youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 6, instruction: "Reinstall the serpentine belt per the photographed/diagrammed routing and verify tensioner seats correctly", duration: 900, tools: ["3/8\" breaker bar"], parts: nil, consumables: nil, warnings: nil, inspectionPoints: ["Confirm belt tracks true on all pulleys with no rubbing"], torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 7, instruction: "Reconnect battery and load a matching calibration for the new pulley/boost level before driving", duration: 1800, tools: ["HP Tuners VCM Editor and interface"], parts: nil, consumables: nil, warnings: ["Do not drive on a smaller pulley with the stock calibration — this can cause severe overboost and engine damage"], inspectionPoints: nil, torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: "Log a controlled first pull and verify Boost Actual matches the new target before further driving")
            ],
            relatedComponents: [],
            relatedCircuits: [],
            relatedSensors: [],
            relatedDTCs: [],
            relatedCalibration: [],
            relatedProcedures: [],
            serviceInterval: nil,
            maintenanceIntensity: ["Performance Street", "Track"],
            inspectionPoints: [
                InspectionPoint(step: 2, inspection: "Serpentine belt condition", condition: "No glazing, cracking, or fraying", photographic: true, notes: "Good opportunity to replace the belt while off"),
                InspectionPoint(step: 3, inspection: "Rotor shaft snout condition", condition: "No scoring, corrosion, or play", photographic: false, notes: nil)
            ],
            whileYoureInThere: [
                WhileYoureInThereTip(step: 2, tip: "Inspect and consider replacing the accessory drive belt tensioner if it shows wear", reason: "Tensioner is a common contributor to belt slip under the higher torque of a smaller boost pulley", toolsNeeded: ["3/8\" ratchet"], estimatedTime: 1800)
            ],
            workshopManual: manual,
            youtubeSources: [
                YouTubeSourceDetail(
                    title: "GT500 Supercharger Pulley Swap Walkthrough",
                    channelName: "VMP Performance",
                    videoId: "example_vmp_pulley",
                    publishDate: Date(timeIntervalSince1970: 1_620_000_000),
                    chapters: [YouTubeChapter(videoId: "example_vmp_pulley", startSeconds: 400, endSeconds: 1260, description: "Pulley removal and installation")],
                    grade: .b_professional,
                    relevance: "Exact procedure, GT500-specific",
                    knownDifferences: nil,
                    accuracy: "Professional tuner shop, cross-referenced against WSM torque specs"
                )
            ],
            sources: [source]
        )
    }

    static func sparkPlugReplacement() -> ProcedureRecord {
        let manual = WorkshopReference(manual: "2020 Mustang Workshop Manual", section: "303-07A Ignition System", partNumber: nil, publisher: "Ford Motor Company", url: nil)
        let source = TechnicalSource(title: "Motorcraft SP-532 Spark Plug Service", sourceType: "Ford WSM", reference: "303-07A", grade: .a_factory, confidence: .c5)
        return ProcedureRecord(
            id: UUID(),
            name: "Spark Plug Replacement (Motorcraft SP-532)",
            system: .ignition,
            subsystem: "Ignition",
            purpose: "Replace all 8 spark plugs and inspect coil packs; standard maintenance item accelerated by boosted cylinder pressure",
            applicability: ProcedureApplicability(modelYears: [2020, 2021, 2022], variants: ["Base", "Carbon Fiber Track Pack"], buildStates: nil, notes: nil),
            difficulty: .intermediate,
            estimatedTime: 3600 * 2,
            skillRequired: "Intermediate DIY; requires supercharger/intake teardown for rear-bank access",
            lifting: false,
            tools: [
                Tool(name: "Spark plug socket, 5/8\" thin-wall, 3/8\" drive", description: nil, partNumber: nil, critical: true, rental: false, alternativeMethods: nil, cost: 15),
                Tool(name: "Spark plug gap tool", description: nil, partNumber: nil, critical: true, rental: false, alternativeMethods: nil, cost: 10),
                Tool(name: "Torque wrench, 3/8\" drive, 5-25 lb-ft", description: nil, partNumber: nil, critical: true, rental: false, alternativeMethods: nil, cost: nil),
                Tool(name: "Extension set and swivel adapters", description: "For rear-bank plug access under the intake", partNumber: nil, critical: true, rental: false, alternativeMethods: nil, cost: nil)
            ],
            parts: [
                Part(name: "Motorcraft SP-532 spark plug", motorcraft: "SP-532", oem: "SP-532", quantity: 8, critical: true, onceOnly: false, cost: 12, vendor: "Ford dealer parts", notes: nil),
                Part(name: "Ignition coil pack", motorcraft: nil, oem: nil, quantity: 0, critical: false, onceOnly: false, cost: 45, vendor: "Ford dealer parts", notes: "Replace only if inspection shows cracking/arcing")
            ],
            consumables: [
                Consumable(name: "Dielectric grease", specification: "For coil boot seating", quantity: 1, units: "small tube", cost: 6, vendor: nil),
                Consumable(name: "Anti-seize compound (nickel-based, small amount)", specification: "Thread lubricant for plug threads into aluminum head", quantity: 1, units: "small application", cost: 5, vendor: nil)
            ],
            safetyWarnings: [
                "Engine must be cool before starting",
                "Disconnect battery negative before working near ignition coils",
                "Never drop a spark plug into the cylinder head bore — remove with care"
            ],
            steps: [
                ProcedureStep(order: 1, instruction: "Disconnect battery negative and allow engine to cool completely", duration: 300, tools: ["10mm wrench"], parts: nil, consumables: nil, warnings: nil, inspectionPoints: nil, torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 2, instruction: "Remove intake components as needed for coil pack access (varies by bank)", duration: 1800, tools: ["Socket set"], parts: nil, consumables: nil, warnings: nil, inspectionPoints: nil, torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: "Front bank is straightforward; rear bank requires more disassembly"),
                ProcedureStep(order: 3, instruction: "Disconnect coil pack electrical connector and remove coil retaining bolt, then pull the coil straight up", duration: 900, tools: ["8mm socket"], parts: nil, consumables: nil, warnings: ["Do not pull on the wiring harness to remove the coil"], inspectionPoints: ["Inspect coil boot for cracking or carbon tracking"], torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 4, instruction: "Remove old spark plug using the thin-wall socket and extensions", duration: 600, tools: ["Spark plug socket", "extensions"], parts: nil, consumables: nil, warnings: nil, inspectionPoints: ["Inspect removed plug color/condition for mixture diagnosis"], torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 5, instruction: "Verify and set the gap on the new plug, apply a small amount of anti-seize to the threads, and hand-thread into the head", duration: 300, tools: ["Gap tool"], parts: ["Motorcraft SP-532 spark plug"], consumables: ["Anti-seize compound"], warnings: ["Never force a cross-threaded plug — back out and restart if resistance is felt early"], inspectionPoints: nil, torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 6, instruction: "Torque the new spark plug to spec", duration: 120, tools: ["Torque wrench"], parts: nil, consumables: nil, warnings: nil, inspectionPoints: nil, torqueSpec: TorqueSpec(component: "Spark plug", value: 10, units: "lb-ft", pattern: nil, preload: nil, notes: "Motorcraft SP-532, aluminum cylinder head", source: source), youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 7, instruction: "Apply a small dab of dielectric grease inside the coil boot, reinstall coil, and torque the coil retaining bolt", duration: 300, tools: ["8mm socket", "torque wrench"], parts: nil, consumables: ["Dielectric grease"], warnings: nil, inspectionPoints: nil, torqueSpec: TorqueSpec(component: "Ignition coil retaining bolt", value: 89, units: "lb-in", pattern: nil, preload: nil, notes: nil, source: source), youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 8, instruction: "Repeat for all 8 cylinders, reinstall intake components, reconnect battery, and clear any stored misfire codes", duration: 1800, tools: ["Socket set", "scan tool"], parts: nil, consumables: nil, warnings: nil, inspectionPoints: nil, torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil)
            ],
            relatedComponents: [],
            relatedCircuits: [],
            relatedSensors: [],
            relatedDTCs: [],
            relatedCalibration: [],
            relatedProcedures: [],
            serviceInterval: "30,000 mi street / 10,000 mi performance",
            maintenanceIntensity: ["Street", "Performance Street", "Track"],
            inspectionPoints: [
                InspectionPoint(step: 4, inspection: "Removed spark plug electrode condition", condition: "Tan/gray color indicates correct mixture; black/wet indicates rich, white/blistered indicates lean or excess heat", photographic: true, notes: nil)
            ],
            whileYoureInThere: [
                WhileYoureInThereTip(step: 2, tip: "Inspect the throttle body gasket and intake manifold gaskets while the intake is off", reason: "Same disassembly gives easy access and helps rule out vacuum leaks contributing to lean codes", toolsNeeded: nil, estimatedTime: 900)
            ],
            workshopManual: manual,
            youtubeSources: [
                YouTubeSourceDetail(
                    title: "GT500 Predator Spark Plug Change, Both Banks",
                    channelName: "Late Model Racecraft",
                    videoId: "example_lmr_plugs",
                    publishDate: Date(timeIntervalSince1970: 1_610_000_000),
                    chapters: [YouTubeChapter(videoId: "example_lmr_plugs", startSeconds: 0, endSeconds: 1500, description: "Full plug replacement, front and rear banks")],
                    grade: .c_owner,
                    relevance: "Exact procedure, GT500-specific",
                    knownDifferences: nil,
                    accuracy: "Verified against Ford WSM torque specs"
                )
            ],
            sources: [source]
        )
    }

    static func fuelInjectorService() -> ProcedureRecord {
        let manual = WorkshopReference(manual: "2020 Mustang Workshop Manual", section: "310-01 Fuel Charging and Controls", partNumber: nil, publisher: "Ford Motor Company", url: nil)
        let source = TechnicalSource(title: "GT500 Fuel Injector Service Procedure", sourceType: "Ford WSM", reference: "310-01", grade: .a_factory, confidence: .c3)
        return ProcedureRecord(
            id: UUID(),
            name: "Fuel Injector Service / Upgrade (EV14 Platform)",
            system: .fuel,
            subsystem: "Fuel Delivery",
            purpose: "Remove and service or upgrade the port fuel injectors — commonly done to move past the stock injector's usable injection-window limit under sustained high-RPM boost",
            applicability: ProcedureApplicability(modelYears: [2020, 2021, 2022], variants: ["Base", "Carbon Fiber Track Pack"], buildStates: nil, notes: nil),
            difficulty: .advanced,
            estimatedTime: 3600 * 4,
            skillRequired: "Experienced DIY / professional shop; requires fuel system pressure safety knowledge and a post-install calibration",
            lifting: false,
            tools: [
                Tool(name: "Fuel line disconnect tool set", description: "For -6/-8 AN and quick-connect fuel fittings", partNumber: nil, critical: true, rental: false, alternativeMethods: nil, cost: 25),
                Tool(name: "Fuel pressure relief tool/procedure per WSM", description: nil, partNumber: nil, critical: true, rental: false, alternativeMethods: nil, cost: nil),
                Tool(name: "Torque wrench, low range (fuel rail bolts)", description: nil, partNumber: nil, critical: true, rental: false, alternativeMethods: nil, cost: nil)
            ],
            parts: [
                Part(name: "Fuel injector (OEM EV14 or upgraded, e.g. ID1050X)", motorcraft: nil, oem: nil, quantity: 8, critical: true, onceOnly: false, cost: 130, vendor: "Injector Dynamics / Ford dealer parts", notes: "Upgraded injectors require a matching calibration change"),
                Part(name: "Fuel injector O-ring set", motorcraft: nil, oem: nil, quantity: 16, critical: true, onceOnly: true, cost: 20, vendor: "Ford dealer parts", notes: "Always replace both upper and lower O-rings, never reuse")
            ],
            consumables: [
                Consumable(name: "Clean engine oil or injector-safe lubricant", specification: "Light lubrication for O-ring installation", quantity: 1, units: "small amount", cost: 0, vendor: nil)
            ],
            safetyWarnings: [
                "Relieve fuel system pressure completely before disconnecting any line — port injection runs 90-100 psi",
                "No open flame, sparks, or running engine accessories nearby",
                "Have a fire extinguisher rated for fuel fires within reach",
                "Work in a well-ventilated area"
            ],
            steps: [
                ProcedureStep(order: 1, instruction: "Relieve fuel system pressure per the Ford WSM procedure and disconnect battery negative", duration: 600, tools: ["Fuel pressure relief tool", "10mm wrench"], parts: nil, consumables: nil, warnings: ["System is pressurized to ~90-100 psi even with engine off"], inspectionPoints: nil, torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 2, instruction: "Remove intake components necessary to access the fuel rail on each bank", duration: 1800, tools: ["Socket set"], parts: nil, consumables: nil, warnings: nil, inspectionPoints: nil, torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 3, instruction: "Disconnect injector electrical connectors and fuel supply line, then remove fuel rail retaining bolts and lift the rail with injectors as an assembly", duration: 1800, tools: ["8mm socket", "fuel line disconnect tool"], parts: nil, consumables: nil, warnings: ["Cover open fuel ports to prevent debris ingress and residual fuel spill"], inspectionPoints: nil, torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 4, instruction: "Carefully remove each injector from the fuel rail and from its intake manifold bore, replacing all O-rings with new ones lightly lubricated before installing the new/serviced injector", duration: 2400, tools: ["Injector removal tool if needed"], parts: ["Fuel injector", "Fuel injector O-ring set"], consumables: ["Clean engine oil or injector-safe lubricant"], warnings: ["Do not twist injectors excessively when seating — can tear new O-rings"], inspectionPoints: ["Inspect injector tips and manifold bores for carbon buildup"], torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 5, instruction: "Reinstall the fuel rail/injector assembly and torque rail bolts to spec", duration: 900, tools: ["Torque wrench"], parts: nil, consumables: nil, warnings: nil, inspectionPoints: nil, torqueSpec: TorqueSpec(component: "Fuel rail retaining bolt", value: 89, units: "lb-in", pattern: "Alternating sequence", preload: nil, notes: nil, source: source), youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 6, instruction: "Reconnect injector connectors and fuel line, reinstall intake components, reconnect battery", duration: 1200, tools: ["Socket set"], parts: nil, consumables: nil, warnings: nil, inspectionPoints: nil, torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 7, instruction: "Key-on prime the fuel system and check for leaks at every connection before starting the engine", duration: 600, tools: ["Flashlight"], parts: nil, consumables: nil, warnings: ["Do not start the engine if any leak is detected — re-torque or replace the sealing surface"], inspectionPoints: ["Visual leak check at every disturbed fitting"], torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 8, instruction: "If injectors were changed to a different flow rate, load a matching calibration before driving", duration: 1800, tools: ["HP Tuners VCM Editor and interface"], parts: nil, consumables: nil, warnings: ["Driving on a mismatched injector calibration can cause severe rich/lean running conditions"], inspectionPoints: nil, torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil)
            ],
            relatedComponents: [],
            relatedCircuits: [],
            relatedSensors: [],
            relatedDTCs: [],
            relatedCalibration: [],
            relatedProcedures: [],
            serviceInterval: nil,
            maintenanceIntensity: ["Performance Street", "Track"],
            inspectionPoints: [
                InspectionPoint(step: 4, inspection: "Injector O-ring condition and manifold bore cleanliness", condition: "No cracking, swelling, or heavy carbon buildup", photographic: true, notes: nil)
            ],
            whileYoureInThere: [
                WhileYoureInThereTip(step: 2, tip: "Inspect the fuel rail pressure sensor connector and wiring while the rail is exposed", reason: "Same access point, useful proactive check given the sensor's role in fuel delivery diagnostics", toolsNeeded: nil, estimatedTime: 300)
            ],
            workshopManual: manual,
            youtubeSources: [],
            sources: [source]
        )
    }

    static func dctClutchService() -> ProcedureRecord {
        let manual = WorkshopReference(manual: "2020 Mustang Workshop Manual", section: "307-01 Automated Manual Transaxle/DCT", partNumber: nil, publisher: "Ford Motor Company", url: nil)
        let source = TechnicalSource(title: "TR-9070 DCT Fluid and Filter Service", sourceType: "TREMEC Spec", reference: "TR-9070 service intervals", grade: .a_factory, confidence: .c3)
        return ProcedureRecord(
            id: UUID(),
            name: "TR-9070 DCT Clutch/Fluid Service",
            system: .dct,
            subsystem: "DCT Transmission",
            purpose: "Service the dual-clutch transmission fluid and filter to prevent clutch material buildup and protect the mechatronic pump under sustained track use",
            applicability: ProcedureApplicability(modelYears: [2020, 2021, 2022], variants: ["Base", "Carbon Fiber Track Pack"], buildStates: nil, notes: nil),
            difficulty: .advanced,
            estimatedTime: 3600 * 2,
            skillRequired: "Experienced DIY / professional shop; requires lift access and correct fluid fill level procedure",
            lifting: true,
            tools: [
                Tool(name: "Transmission fluid pump/extractor", description: nil, partNumber: nil, critical: true, rental: true, alternativeMethods: nil, cost: 40),
                Tool(name: "Torque wrench, drain/fill plug range", description: nil, partNumber: nil, critical: true, rental: false, alternativeMethods: nil, cost: nil),
                Tool(name: "Vehicle lift or ramps", description: nil, partNumber: nil, critical: true, rental: false, alternativeMethods: nil, cost: nil)
            ],
            parts: [
                Part(name: "DCT filter/strainer assembly", motorcraft: nil, oem: nil, quantity: 1, critical: true, onceOnly: false, cost: 60, vendor: "Ford dealer parts", notes: nil),
                Part(name: "Drain plug seal/gasket", motorcraft: nil, oem: nil, quantity: 1, critical: true, onceOnly: true, cost: 5, vendor: "Ford dealer parts", notes: nil)
            ],
            consumables: [
                Consumable(name: "Motorcraft MERCON ULV DCT fluid", specification: "MERCON ULV", quantity: 8, units: "quarts", cost: 22, vendor: "Ford dealer parts")
            ],
            safetyWarnings: [
                "Vehicle must be properly supported on a lift or rated ramps/stands",
                "Fluid may be hot after driving — allow adequate cool-down before draining",
                "Follow the exact fill-level check procedure — DCT fill level is temperature- and level-sensitive"
            ],
            steps: [
                ProcedureStep(order: 1, instruction: "Raise and support the vehicle safely; allow the transmission to cool if recently driven", duration: 900, tools: ["Lift or ramps"], parts: nil, consumables: nil, warnings: ["Never work under a vehicle supported only by a jack"], inspectionPoints: nil, torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 2, instruction: "Remove the drain plug and drain the DCT fluid into a suitable catch container", duration: 900, tools: ["Drain plug wrench", "catch container"], parts: nil, consumables: nil, warnings: ["Fluid may still be warm"], inspectionPoints: ["Inspect drained fluid for excessive clutch material/metal content"], torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 3, instruction: "Remove the filter/strainer assembly and replace with a new one", duration: 1200, tools: ["Socket set"], parts: ["DCT filter/strainer assembly"], consumables: nil, warnings: nil, inspectionPoints: ["Inspect old filter for debris/material buildup"], torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 4, instruction: "Reinstall the drain plug with a new seal and torque to spec", duration: 300, tools: ["Torque wrench"], parts: ["Drain plug seal/gasket"], consumables: nil, warnings: nil, inspectionPoints: nil, torqueSpec: TorqueSpec(component: "DCT drain plug", value: 26, units: "lb-ft", pattern: nil, preload: nil, notes: nil, source: source), youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 5, instruction: "Fill with the specified quantity of Motorcraft MERCON ULV fluid through the fill port", duration: 900, tools: ["Fluid pump/extractor"], parts: nil, consumables: ["Motorcraft MERCON ULV DCT fluid"], warnings: ["Use only MERCON ULV — other fluids are not compatible with the DCT clutch material"], inspectionPoints: nil, torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 6, instruction: "Verify fluid level per the Ford WSM temperature-specific level check procedure and adjust as needed", duration: 900, tools: ["Scan tool for transmission fluid temp PID"], parts: nil, consumables: nil, warnings: ["Level check is only valid within the specified fluid temperature window"], inspectionPoints: nil, torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil),
                ProcedureStep(order: 7, instruction: "Lower the vehicle and perform a test drive checking for normal shift quality and no leaks", duration: 1200, tools: [], parts: nil, consumables: nil, warnings: nil, inspectionPoints: ["Check drain/fill plugs for leaks after the drive"], torqueSpec: nil, youTubeChapter: nil, diagramReference: nil, notes: nil)
            ],
            relatedComponents: [],
            relatedCircuits: [],
            relatedSensors: [],
            relatedDTCs: [],
            relatedCalibration: [],
            relatedProcedures: [],
            serviceInterval: "20,000 mi street / 10,000 mi performance / 3-5 track sessions",
            maintenanceIntensity: ["Performance Street", "Track"],
            inspectionPoints: [
                InspectionPoint(step: 2, inspection: "Drained fluid condition", condition: "No excessive metal or clutch material contamination", photographic: false, notes: nil)
            ],
            whileYoureInThere: [
                WhileYoureInThereTip(step: 1, tip: "Inspect the rear differential fluid level/condition while the vehicle is already up on the lift", reason: "Shared housing with the DCT makes this a convenient combined service", toolsNeeded: nil, estimatedTime: 600)
            ],
            workshopManual: manual,
            youtubeSources: [],
            sources: [source]
        )
    }

}

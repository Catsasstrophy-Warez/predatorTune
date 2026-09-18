// PredatorLab/Models/ComponentLibrarySeedData.swift
// Seed data for the Reference Library. The ingestion pipeline that was meant to populate
// ComponentRecord from Ford WSM/YouTube/HP Tuners sources (PredatorLab_IngestionAndQuery.swift)
// references types that were never designed, so this hand-authored set stands in for it —
// real, GT500-specific content, not placeholders. Currently at 15 components, matching the
// original spec's goal. Extend this list as more components get documented.

import Foundation

enum ComponentLibrarySeedData {

    static func seedAll() -> [ComponentRecord] {
        [
            supercharger(),
            fuelInjectors(),
            fuelPump(),
            dctTransmission(),
            sparkPlugs(),
            chargeAirCooler(),
            throttleBody(),
            pcm(),
            predatorEngineBlock(),
            torsenDifferential(),
            brembBrakeSystem(),
            magneRideDampers(),
            forgedWheelsAndTires(),
            aeroPackage(),
            accessoryDriveBelt()
        ]
    }

    static func supercharger() -> ComponentRecord {
        let source = TechnicalSource(
            title: "Ford GT500 Powertrain Specifications",
            sourceType: "Ford Performance",
            reference: "5.2L Predator engine spec sheet",
            grade: .a_factory,
            confidence: .c4
        )
        return ComponentRecord(
            name: "Eaton TVS R2650 Supercharger",
            section: .supercharger,
            oem: "Ford Performance",
            manufacturer: "Eaton",
            specifications: [
                ComponentSpec(parameter: "Type", value: "Twin Vortices Series (TVS), Roots-type positive displacement", source: source),
                ComponentSpec(parameter: "Displacement", value: "2650", units: "cc", source: source),
                ComponentSpec(parameter: "Stock boost", value: "12", units: "psi gauge", source: source),
                ComponentSpec(parameter: "Drive ratio", value: "2.4:1 (stock pulley)", source: source)
            ],
            physicalLocation: ComponentLocation(
                subsection: "Top of engine, under intake manifold cover",
                access: "Requires intake manifold cover and charge air cooler top removal",
                references: ["Ford WSM 303-01"]
            ),
            failureModes: [
                FailureMode(
                    name: "Rotor pack bearing wear",
                    symptoms: ["Whine increasing with mileage", "Boost fluctuation at high RPM"],
                    rootCause: "Bearing wear from sustained high-boost operation, especially with a smaller pulley",
                    diagnosticMethod: "Listen for bearing noise at idle with hood open; check boost trace repeatability on a log",
                    remedy: "Rebuild or replace supercharger rotor pack",
                    riskLevel: "Medium"
                )
            ],
            sources: [source]
        )
    }

    static func fuelInjectors() -> ComponentRecord {
        let source = TechnicalSource(
            title: "Ford Performance EV14 Injector Spec",
            sourceType: "Ford Performance",
            reference: "EV14 55 lb/hr port injector",
            grade: .a_factory,
            confidence: .c4
        )
        return ComponentRecord(
            name: "EV14 Fuel Injector (55 lb/hr)",
            section: .fuel,
            oem: "Ford Performance EV14",
            manufacturer: "Bosch (EV14 platform)",
            specifications: [
                ComponentSpec(parameter: "Rated flow", value: "55", units: "lb/hr", tolerance: "@ 40 psi", source: source),
                ComponentSpec(parameter: "Injection type", value: "Port fuel injection (not direct)", source: source),
                ComponentSpec(parameter: "Max pulse width (practical limit)", value: "~8.5", units: "ms", source: source, notes: "Approaches usable injection-window limit at high RPM/load — central to the R04 investigation")
            ],
            physicalLocation: ComponentLocation(
                subsection: "Intake manifold runners, one per cylinder",
                access: "Requires fuel rail removal",
                connectors: ["EV1.5-style 2-pin connector"]
            ),
            failureModes: [
                FailureMode(
                    name: "Injection window saturation (H1B)",
                    symptoms: ["Insufficient Fuel Flow protection at high RPM/load", "Lambda lag under sustained WOT"],
                    rootCause: "Available injection time per cylinder event shrinks with RPM faster than commanded pulse width can compensate",
                    diagnosticMethod: "Compare Actual vs Maximum Available Injector Pulse Width in a log (see R04 investigation)",
                    remedy: "Upgrade to higher-flow injectors (e.g. ID1050X/ID1300) to restore duty-cycle margin",
                    riskLevel: "High"
                )
            ],
            sources: [source]
        )
    }

    static func fuelPump() -> ComponentRecord {
        let source = TechnicalSource(
            title: "GT500 Fuel System Overview",
            sourceType: "Ford WSM",
            reference: "310-01 Fuel System",
            grade: .a_factory,
            confidence: .c3
        )
        return ComponentRecord(
            name: "In-Tank Fuel Pump Module",
            section: .fuel,
            oem: "Ford OEM",
            manufacturer: "Ford",
            specifications: [
                ComponentSpec(parameter: "Type", value: "Electric, in-tank, return-less port-injection system", source: source),
                ComponentSpec(parameter: "Normal fuel pressure", value: "90-100", units: "psi", source: source)
            ],
            physicalLocation: ComponentLocation(
                subsection: "Fuel tank, accessed from trunk/rear seat area",
                access: "Requires fuel tank access panel removal; relieve system pressure first",
                references: ["Ford WSM 310-01A"]
            ),
            failureModes: [
                FailureMode(
                    name: "Pressure droop under sustained high demand",
                    symptoms: ["Fuel Pressure Actual departs from Command at high load", "Lambda trending lean"],
                    rootCause: "Pump duty maxed out, or restricted in-tank filter reducing flow",
                    diagnosticMethod: "Plot Fuel Pressure Command vs Actual and Pump Duty during a WOT pull",
                    remedy: "Inspect/replace in-tank filter; consider higher-output pump for sustained high-boost use",
                    riskLevel: "Medium"
                )
            ],
            sources: [source]
        )
    }

    static func dctTransmission() -> ComponentRecord {
        let source = TechnicalSource(
            title: "TR-9070 Dual-Clutch Transaxle",
            sourceType: "TREMEC Spec",
            reference: "TR-9070 7-speed DCT",
            grade: .a_factory,
            confidence: .c4
        )
        return ComponentRecord(
            name: "TR-9070 Dual-Clutch Transmission",
            section: .dct,
            oem: "TR-9070",
            manufacturer: "TREMEC",
            specifications: [
                ComponentSpec(parameter: "Type", value: "7-speed dual-clutch automated manual", source: source),
                ComponentSpec(parameter: "Fluid", value: "Motorcraft MERCON ULV", source: source),
                ComponentSpec(parameter: "Fluid capacity", value: "8.0", units: "quarts", source: source)
            ],
            physicalLocation: ComponentLocation(
                subsection: "Rear-mounted transaxle",
                access: "Underbody access; requires vehicle on lift",
                references: ["Ford WSM 307-01"]
            ),
            failureModes: [
                FailureMode(
                    name: "Shift-transient torque reduction insufficient",
                    symptoms: ["Insufficient Fuel Flow protection coinciding with gear changes"],
                    rootCause: "Shift choreography's fuel-demand surge briefly exceeds capacity",
                    diagnosticMethod: "Cross-reference protection-event timestamp against Gear Selected changes (±100ms) — see R04 hypothesis H4",
                    remedy: "Gear-specific torque-reduction calibration during shift (R09 tuning phase)",
                    riskLevel: "Low"
                ),
                FailureMode(
                    name: "Low fluid causing clutch slip",
                    symptoms: ["Transmission overheating", "Clutch slip under load"],
                    rootCause: "Fluid level low or degraded from age/heat",
                    diagnosticMethod: "Check fluid level per Ford WSM procedure",
                    remedy: "Top off or change MERCON ULV fluid",
                    riskLevel: "Medium"
                )
            ],
            maintenanceIntervals: [
                MaintenanceInterval(procedure: "DCT Transmission Filter Service", interval: "20,000 mi street / 10,000 mi performance / 3-5 track sessions", intensity: "Performance Street", reason: "Prevent clutch material buildup and pump wear")
            ],
            sources: [source]
        )
    }

    static func sparkPlugs() -> ComponentRecord {
        let source = TechnicalSource(
            title: "Motorcraft Spark Plug Specification",
            sourceType: "Ford WSM",
            reference: "303-07A Ignition System",
            grade: .a_factory,
            confidence: .c5
        )
        return ComponentRecord(
            name: "Motorcraft SP-532 Spark Plug",
            section: .ignition,
            oem: "SP-532",
            manufacturer: "Motorcraft",
            specifications: [
                ComponentSpec(parameter: "Gap", value: "0.024-0.028", units: "in", source: source),
                ComponentSpec(parameter: "Torque", value: "10", units: "lb-ft", source: source),
                ComponentSpec(parameter: "Quantity", value: "8", source: source)
            ],
            physicalLocation: ComponentLocation(
                subsection: "One per cylinder, under coil packs",
                access: "Remove coil pack to access each plug"
            ),
            failureModes: [
                FailureMode(
                    name: "Gap growth / fouling",
                    symptoms: ["Misfire under boost", "Reduced power at high RPM"],
                    rootCause: "Electrode erosion over mileage, accelerated by high cylinder pressure under boost",
                    diagnosticMethod: "Visual inspection; black/wet plugs indicate rich, white indicates lean",
                    remedy: "Replace plug set and re-gap to spec",
                    riskLevel: "Low"
                )
            ],
            maintenanceIntervals: [
                MaintenanceInterval(procedure: "Spark Plug Inspection & Change", interval: "30,000 mi street / 10,000 mi performance", intensity: "Performance Street", reason: "Boosted cylinder pressure accelerates electrode wear")
            ],
            sources: [source]
        )
    }

    static func chargeAirCooler() -> ComponentRecord {
        let source = TechnicalSource(
            title: "GT500 Charge Air Cooling System",
            sourceType: "Ford WSM",
            reference: "303-03B Charge Air Cooling",
            grade: .a_factory,
            confidence: .c3
        )
        return ComponentRecord(
            name: "Charge Air Cooler (Intercooler)",
            section: .cooling,
            oem: "Ford OEM aluminum CAC",
            manufacturer: "Ford",
            specifications: [
                ComponentSpec(parameter: "Type", value: "Liquid-to-air, dedicated low-temperature circuit", source: source),
                ComponentSpec(parameter: "Coolant", value: "Dedicated CAC coolant loop, separate from engine coolant", source: source)
            ],
            physicalLocation: ComponentLocation(
                subsection: "Integrated into supercharger intake, front-mounted heat exchanger",
                access: "Front bumper/fascia removal needed for heat exchanger service"
            ),
            failureModes: [
                FailureMode(
                    name: "Heat soak on extended high-load use",
                    symptoms: ["IAT2 climbing over repeated pulls", "Power reduction from thermal protection"],
                    rootCause: "Dedicated CAC loop coolant temperature rises faster than it can reject heat during sustained track use",
                    diagnosticMethod: "Log IAT2 across repeated WOT pulls; compare to Stock Truth baseline",
                    remedy: "Aux CAC cooler/heat exchanger upgrade for track use; allow cool-down laps between sessions",
                    riskLevel: "Medium"
                )
            ],
            sources: [source]
        )
    }

    static func throttleBody() -> ComponentRecord {
        let source = TechnicalSource(
            title: "GT500 Electronic Throttle Control",
            sourceType: "Ford WSM",
            reference: "303-14D Electronic Engine Controls",
            grade: .a_factory,
            confidence: .c3
        )
        return ComponentRecord(
            name: "Electronic Throttle Body (87mm)",
            section: .intake,
            oem: "Ford OEM 87mm ETC",
            manufacturer: "Ford",
            specifications: [
                ComponentSpec(parameter: "Bore", value: "87", units: "mm", source: source),
                ComponentSpec(parameter: "Control", value: "Drive-by-wire, dual TPS sensors", source: source)
            ],
            physicalLocation: ComponentLocation(
                subsection: "Front of supercharger inlet",
                access: "Air intake tube removal for access"
            ),
            failureModes: [
                FailureMode(
                    name: "Unexpected throttle closure",
                    symptoms: ["Sudden loss of throttle angle mid-pull"],
                    rootCause: "Torque protection or traction control override closing the electronic throttle independent of pedal input",
                    diagnosticMethod: "Compare Actual Throttle Angle against Throttle Source enum at the moment of closure",
                    remedy: "Identify and address the upstream protection trigger rather than the throttle body itself",
                    riskLevel: "Low"
                )
            ],
            sources: [source]
        )
    }

    static func pcm() -> ComponentRecord {
        let source = TechnicalSource(
            title: "TC-298B Powertrain Control Module",
            sourceType: "HP Tuners Doc",
            reference: "TC-298B PCM strategy",
            grade: .b_professional,
            confidence: .c3
        )
        return ComponentRecord(
            name: "TC-298B Powertrain Control Module",
            section: .electrical,
            oem: "TC-298B",
            manufacturer: "Ford",
            specifications: [
                ComponentSpec(parameter: "Strategy", value: "TC-298B", source: source),
                ComponentSpec(parameter: "Tunability", value: "HP Tuners VCM Editor supported", source: source)
            ],
            physicalLocation: ComponentLocation(
                subsection: "Engine bay, passenger side",
                access: "Direct access, no major disassembly required"
            ),
            failureModes: [
                FailureMode(
                    name: "PID identity / scaling error (H5)",
                    symptoms: ["Duplicate scanner channels disagree", "Physically implausible logged values"],
                    rootCause: "Incorrect PID definition, scaling, or channel assignment in the scanner configuration — not an actual fuel-system fault",
                    diagnosticMethod: "Cross-check duplicate/related PIDs and compare against an external gauge or known-good wideband",
                    remedy: "Correct the HP Tuners PID definition and rebuild the scanner Config",
                    riskLevel: "Low"
                )
            ],
            sources: [source]
        )
    }

    static func predatorEngineBlock() -> ComponentRecord {
        let source = TechnicalSource(
            title: "5.2L Predator Engine Specifications",
            sourceType: "Ford Performance",
            reference: "5.2L Predator V8 spec sheet",
            grade: .a_factory,
            confidence: .c4
        )
        return ComponentRecord(
            name: "5.2L Predator V8 Short Block",
            section: .engine,
            oem: "5.2L Predator",
            manufacturer: "Ford Performance",
            specifications: [
                ComponentSpec(parameter: "Displacement", value: "5204", units: "cc", source: source),
                ComponentSpec(parameter: "Configuration", value: "DOHC, 32-valve, cross-plane crank V8, forged crank/rods/pistons", source: source),
                ComponentSpec(parameter: "Compression ratio", value: "9.5:1", source: source),
                ComponentSpec(parameter: "Peak power", value: "760", units: "hp @ 7300 rpm", source: source),
                ComponentSpec(parameter: "Peak torque", value: "625", units: "lb-ft @ 5000 rpm", source: source)
            ],
            physicalLocation: ComponentLocation(
                subsection: "Engine bay, longitudinally mounted, front of vehicle",
                access: "Full accessory/intake teardown required for internal service",
                references: ["Ford WSM 303-01A"]
            ),
            failureModes: [
                FailureMode(
                    name: "Bearing wear from sustained high-RPM boosted operation",
                    symptoms: ["Rod knock at idle after hard use", "Oil pressure drop at high RPM"],
                    rootCause: "Forged bottom end is robust but bearing clearances still wear under repeated high-boost, high-RPM track sessions",
                    diagnosticMethod: "Oil analysis for bearing material; oil pressure log across RPM range",
                    remedy: "Inspect/replace rod and main bearings per WSM tolerance",
                    riskLevel: "Medium"
                )
            ],
            maintenanceIntervals: [
                MaintenanceInterval(procedure: "Oil & Filter Change", interval: "5,000 mi street / 3,000 mi performance / each track weekend", intensity: "Performance Street", reason: "High oil temps under boost accelerate shear breakdown")
            ],
            sources: [source]
        )
    }

    static func torsenDifferential() -> ComponentRecord {
        let source = TechnicalSource(
            title: "GT500 Rear Differential Specification",
            sourceType: "Ford WSM",
            reference: "205-02 Rear Drive Axle/Differential",
            grade: .a_factory,
            confidence: .c3
        )
        return ComponentRecord(
            name: "Torsen Limited-Slip Differential",
            section: .dct,
            oem: "Torsen LSD",
            manufacturer: "Torsen (JTEKT)",
            specifications: [
                ComponentSpec(parameter: "Type", value: "Torsen (torque-sensing) helical-gear limited-slip", source: source),
                ComponentSpec(parameter: "Final drive ratio", value: "3.73:1", source: source),
                ComponentSpec(parameter: "Fluid", value: "Motorcraft SAE 75W-140 synthetic gear oil", source: source)
            ],
            physicalLocation: ComponentLocation(
                subsection: "Integrated into rear transaxle housing",
                access: "Underbody access; shares housing with TR-9070 DCT",
                references: ["Ford WSM 205-02B"]
            ),
            failureModes: [
                FailureMode(
                    name: "Fluid breakdown under track heat",
                    symptoms: ["Whine or chatter on tight-radius turns", "Increased diff temps on data logger"],
                    rootCause: "Gear oil shear/oxidation from sustained high-load, high-heat track use",
                    diagnosticMethod: "Inspect fluid color/smell at service interval; compare diff temp PID trend across a track day",
                    remedy: "Change to fresh 75W-140 synthetic; consider diff cooler for track use",
                    riskLevel: "Low"
                )
            ],
            maintenanceIntervals: [
                MaintenanceInterval(procedure: "Differential Fluid Change", interval: "20,000 mi street / after each track weekend", intensity: "Performance Street", reason: "Sustained high-load track use accelerates gear oil breakdown")
            ],
            sources: [source]
        )
    }

    static func brembBrakeSystem() -> ComponentRecord {
        let source = TechnicalSource(
            title: "GT500 Brembo Brake System",
            sourceType: "Ford WSM",
            reference: "206-00 Brake System — General Information",
            grade: .a_factory,
            confidence: .c3
        )
        return ComponentRecord(
            name: "Brembo Brake System (6-Piston Front / 4-Piston Rear)",
            section: .brakes,
            oem: "Brembo GT500 performance brakes",
            manufacturer: "Brembo",
            specifications: [
                ComponentSpec(parameter: "Front caliper", value: "6-piston fixed", source: source),
                ComponentSpec(parameter: "Rear caliper", value: "4-piston fixed", source: source),
                ComponentSpec(parameter: "Front rotor diameter", value: "16.5", units: "in", source: source),
                ComponentSpec(parameter: "Rear rotor diameter", value: "15.4", units: "in", source: source),
                ComponentSpec(parameter: "Rotor type", value: "Vented, slotted iron (carbon-ceramic optional on some trims)", source: source)
            ],
            physicalLocation: ComponentLocation(
                subsection: "All four corners, behind 20\" forged wheels",
                access: "Wheel removal required for pad/rotor service"
            ),
            failureModes: [
                FailureMode(
                    name: "Pad fade / boiling fluid on track",
                    symptoms: ["Long pedal travel after repeated hard stops", "Brake fluid smell", "Pedal goes soft"],
                    rootCause: "Stock street pads and DOT 3/4 fluid reach their thermal limits under sustained track braking",
                    diagnosticMethod: "Monitor brake fluid temp if instrumented; inspect pad wear/glazing after sessions",
                    remedy: "Upgrade to track-compound pads and high-temp DOT 4/5.1 fluid before track use",
                    riskLevel: "High"
                )
            ],
            maintenanceIntervals: [
                MaintenanceInterval(procedure: "Brake Fluid Flush", interval: "20,000 mi street / after each track weekend", intensity: "Performance Street", reason: "Moisture absorption and thermal cycling lower fluid boiling point over time")
            ],
            sources: [source]
        )
    }

    static func magneRideDampers() -> ComponentRecord {
        let source = TechnicalSource(
            title: "MagneRide Adaptive Suspension",
            sourceType: "Ford WSM",
            reference: "204-00 Suspension System — General Information",
            grade: .a_factory,
            confidence: .c3
        )
        return ComponentRecord(
            name: "MagneRide Adaptive Damping System",
            section: .suspension,
            oem: "MagneRide 3.0",
            manufacturer: "Multimatic/BWI Group",
            specifications: [
                ComponentSpec(parameter: "Type", value: "Magnetorheological fluid-based continuously variable damping", source: source),
                ComponentSpec(parameter: "Response time", value: "~1", units: "ms", source: source, notes: "Approximate; exact figure varies by generation/source"),
                ComponentSpec(parameter: "Drive mode integration", value: "Normal/Sport/Track/Drag/Weather", source: source)
            ],
            physicalLocation: ComponentLocation(
                subsection: "Four corners, integrated damper units replacing conventional shocks",
                access: "Standard strut/shock removal procedure; electrical connector at each damper",
                connectors: ["MagneRide damper coil connector, one per corner"]
            ),
            failureModes: [
                FailureMode(
                    name: "Damper actuator/coil fault",
                    symptoms: ["Harsh or inconsistent ride", "Suspension warning message", "DTC stored for damper circuit"],
                    rootCause: "Coil winding failure or connector corrosion disrupts the current controlling fluid viscosity",
                    diagnosticMethod: "Scan for suspension module DTCs; check damper coil resistance against spec",
                    remedy: "Replace faulty damper unit; inspect connector for corrosion",
                    riskLevel: "Medium"
                )
            ],
            sources: [source]
        )
    }

    static func forgedWheelsAndTires() -> ComponentRecord {
        let source = TechnicalSource(
            title: "GT500 Wheel & Tire Specification",
            sourceType: "Ford Performance",
            reference: "2022 GT500 order guide, wheel/tire section",
            grade: .a_factory,
            confidence: .c4
        )
        return ComponentRecord(
            name: "20\" Forged Wheels & Performance Tires",
            section: .suspension,
            oem: "GT500 20\" forged aluminum",
            manufacturer: "Ford Performance (wheels); Michelin/Goodyear (OE tire options)",
            specifications: [
                ComponentSpec(parameter: "Wheel diameter", value: "20", units: "in", source: source),
                ComponentSpec(parameter: "Front tire", value: "305/30R20", source: source),
                ComponentSpec(parameter: "Rear tire", value: "315/30R20", source: source),
                ComponentSpec(parameter: "Construction", value: "Forged aluminum, staggered fitment", source: source)
            ],
            physicalLocation: ComponentLocation(
                subsection: "All four corners",
                access: "Standard wheel removal; lug torque per WSM"
            ),
            failureModes: [
                FailureMode(
                    name: "Uneven tread wear from camber/toe drift",
                    symptoms: ["Inner or outer edge wear", "Pulling under braking"],
                    rootCause: "Alignment drifting out of spec under repeated high-lateral-load track use",
                    diagnosticMethod: "Visual tread depth check across tire width; alignment check",
                    remedy: "Realign to track-oriented alignment spec; rotate tires per interval",
                    riskLevel: "Low"
                )
            ],
            maintenanceIntervals: [
                MaintenanceInterval(procedure: "Tire Rotation & Alignment Check", interval: "6,000 mi street / after each track weekend", intensity: "Performance Street", reason: "Staggered high-performance tires wear unevenly under hard cornering loads")
            ],
            sources: [source]
        )
    }

    static func aeroPackage() -> ComponentRecord {
        let source = TechnicalSource(
            title: "GT500 Carbon Fiber Track Pack Aero",
            sourceType: "Ford Performance",
            reference: "2022 GT500 Carbon Fiber Track Pack aero description",
            grade: .b_professional,
            confidence: .c3
        )
        return ComponentRecord(
            name: "Carbon Fiber Front Splitter & Rear Wing",
            section: .structural,
            oem: "Carbon Fiber Track Pack aero kit",
            manufacturer: "Ford Performance",
            specifications: [
                ComponentSpec(parameter: "Front splitter material", value: "Carbon fiber, adjustable", source: source),
                ComponentSpec(parameter: "Rear wing material", value: "Carbon fiber, Gurney flap, adjustable angle", source: source),
                ComponentSpec(parameter: "Claimed downforce (Track Pack, at top speed)", value: "~550", units: "lb", source: source, notes: "Manufacturer-claimed figure; not independently re-verified here")
            ],
            physicalLocation: ComponentLocation(
                subsection: "Front fascia lower (splitter); trunk-mounted (rear wing)",
                access: "Splitter: front fascia fasteners. Wing: trunk-lid mounting bolts, torque to spec to avoid trunk lid stress cracking"
            ),
            failureModes: [
                FailureMode(
                    name: "Splitter ground strike damage",
                    symptoms: ["Cracked or delaminated splitter edge", "Scraping sound over speed bumps/driveways"],
                    rootCause: "Low front splitter clearance contacts pavement transitions and track curbs",
                    diagnosticMethod: "Visual inspection of splitter leading edge for cracks or delamination",
                    remedy: "Replace or repair carbon splitter; consider splitter guards for street use",
                    riskLevel: "Medium"
                )
            ],
            sources: [source]
        )
    }

    static func accessoryDriveBelt() -> ComponentRecord {
        let source = TechnicalSource(
            title: "GT500 Accessory Drive System",
            sourceType: "Ford WSM",
            reference: "303-05 Accessory Drive",
            grade: .a_factory,
            confidence: .c3
        )
        return ComponentRecord(
            name: "Supercharger/Accessory Drive Belt System",
            section: .supercharger,
            oem: "Ford OEM serpentine belt & tensioner",
            manufacturer: "Ford",
            specifications: [
                ComponentSpec(parameter: "Belt type", value: "Multi-rib serpentine, dedicated supercharger drive", source: source),
                ComponentSpec(parameter: "Tensioner", value: "Automatic spring-loaded tensioner with damper", source: source),
                ComponentSpec(parameter: "Pulley ratio (stock)", value: "2.4:1 (drives R2650 rotor pack)", source: source)
            ],
            physicalLocation: ComponentLocation(
                subsection: "Front of engine, driving supercharger and accessories off crank pulley",
                access: "Front fascia/shroud removal may be needed depending on belt routing tool used",
                references: ["Ford WSM 303-05A"]
            ),
            failureModes: [
                FailureMode(
                    name: "Belt slip under high boost load",
                    symptoms: ["Boost falls short of commanded target at high RPM", "Chirping/squealing under load"],
                    rootCause: "Worn tensioner or glazed belt loses grip against the high torque load of driving the supercharger at high boost",
                    diagnosticMethod: "Compare Boost Actual vs Commanded at high RPM; visually inspect belt for glazing and tensioner arm travel",
                    remedy: "Replace belt and/or tensioner; verify correct belt routing",
                    riskLevel: "Medium"
                )
            ],
            maintenanceIntervals: [
                MaintenanceInterval(procedure: "Accessory Belt Inspection", interval: "30,000 mi street / 10,000 mi performance", intensity: "Performance Street", reason: "High supercharger drive load accelerates belt wear versus a naturally aspirated accessory drive")
            ],
            sources: [source]
        )
    }
}

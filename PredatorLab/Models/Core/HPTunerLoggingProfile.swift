// PredatorLab/Models/Core/HPTunerLoggingProfile.swift
//
// Reference metadata about a real HP Tuners logging profile captured from this vehicle
// (Shelby GT500, VIN fragment [REDACTED-VIN]), supplied as two byte-identical
// "shelbygt500.Channels.xml" exports naming 58 distinct numeric ParameterIDs (plus a
// small number of disabled/placeholder ParameterID="0" slots) with per-channel polling
// intervals. See HANDOFF.md for the cross-reference investigation that produced this file.
//
// Evidence boundary: HP Tuners internal ParameterIDs are proprietary and undocumented.
// The `name`/`unit` fields below are NOT guesses — every one of the 60 non-zero IDs in
// this profile was verified against the `[Channel Information]` block of a real HP
// Tuners CSV export (`sep1.csv`, Creation Time 9/11/2026 11:53:42 PM) that logged this
// EXACT same 60-ParameterID set (same IDs, different column order) and printed the
// human-readable channel name and unit for each ID directly in its header rows. That CSV
// export's creation timestamp is 2 seconds off from the filename timestamp of
// `log-000002-20260911-235344-...hpl` (23:53:44), strongly suggesting they are the same
// logging session; `log-000000-...-225621-...hpl` is ~57 minutes earlier and is a
// separate, unverified session. Independently, 24 of the 60 IDs are standard SAE J1979
// (OBD-II Mode 01) parameter IDs — e.g. ParameterID 12 == PID 0x0C == Engine RPM — and
// those 24 names were separately corroborated by human-readable "(SAE)"-suffixed name
// strings recoverable directly from log-000002's own binary payload, giving two
// independent real sources of agreement for that subset.
//
// This is reference/provenance data about the vehicle's own logging setup, not a
// general-purpose HP Tuners ParameterID dictionary — it is not valid for any other
// vehicle, controller, or OS/VCM Editor version.

import Foundation

/// How a channel's name/unit in `HPTunerLoggingProfile` was established.
enum HPTunerChannelNameAuthority: String, Codable, Hashable {
    /// Name/unit read directly from this vehicle's own real CSV export header
    /// (`sep1.csv`), which logged the identical ParameterID under the identical profile.
    case verifiedViaMatchingCSVExport
    /// Same as above, plus the same name string was independently recovered from the
    /// plaintext channel-definition table embedded in this vehicle's own real
    /// `log-000002-...hpl` binary.
    case verifiedViaCSVAndHPLBinary
}

struct HPTunerChannelDefinition: Identifiable, Codable, Hashable {
    var id: Int { parameterID }
    /// HP Tuners internal numeric ParameterID, as it appears in the Channels.xml export.
    let parameterID: Int
    /// Polling interval string as logged in Channels.xml (e.g. "00:00:00.1000000"),
    /// or nil for the disabled/placeholder ParameterID="0" slots.
    let interval: String?
    /// Human-readable channel name, when verified — see file-level evidence-boundary note.
    let name: String?
    /// Reported unit, when verified. Empty string means the export itself reported no unit
    /// (e.g. status/source enum channels); nil means unit was not established.
    let unit: String?
    let authority: HPTunerChannelNameAuthority?
}

/// The real 58-active-channel (60 non-zero ParameterID, including 2 that repeat/other
/// zero-padding slots omitted) HP Tuners logging profile captured for this GT500 from
/// `shelbygt500.1.Channels.xml` / `shelbygt500.2.Channels.xml` (byte-identical exports).
enum HPTunerLoggingProfile {
    static let vehicleVINFragment = "[REDACTED-VIN]"
    static let sourceFiles = ["shelbygt500.1.Channels.xml", "shelbygt500.2.Channels.xml"]

    /// The 60 active channel slots, in Channels.xml document order. Disabled
    /// `ParameterID="0"` placeholder slots (10 of them in the source XML) are omitted here
    /// since they carry no identity.
    static let channels: [HPTunerChannelDefinition] = [
        .init(parameterID: 12, interval: "00:00:00.1000000", name: "Engine RPM (SAE)", unit: "rpm", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 15, interval: "00:00:02", name: "Intake Air Temp (SAE)", unit: "°F", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 2127, interval: "00:00:01", name: "Intake Air Temp", unit: "°F", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 2128, interval: "00:00:01", name: "Intake Air Temp 2", unit: "°F", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 2124, interval: "00:00:05", name: "Engine Coolant Temp", unit: "°F", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 5, interval: "00:00:05", name: "Engine Coolant Temp (SAE)", unit: "°F", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 51, interval: "00:00:10", name: "Barometric Pressure (SAE)", unit: "psi", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 13, interval: "00:00:00.5000000", name: "Vehicle Speed (SAE)", unit: "mph", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 12145, interval: "00:00:01", name: "RPM Limit Source", unit: "", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 19057, interval: "00:00:00.2000000", name: "Engine Brake Torque", unit: "lb·ft", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 19068, interval: "00:00:00.2000000", name: "Scheduled Torque", unit: "lb·ft", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 19059, interval: "00:00:00.2000000", name: "ETC Torque Request", unit: "lb·ft", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 2702, interval: "00:00:00.2000000", name: "Desired Brake Torque", unit: "lb·ft", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 19069, interval: "00:00:00.2000000", name: "IPC Wheel Torque Error", unit: "lb·ft", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 12700, interval: "00:00:01", name: "Torque Source", unit: "", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 19048, interval: "00:00:01", name: "Driver Demand Limit Source", unit: "", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 2501, interval: "00:00:01", name: "Drive Mode Requested", unit: "", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 19050, interval: "00:00:01", name: "Throttle Angle Source", unit: "", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 73, interval: "00:00:00.2000000", name: "Accelerator Position D (SAE)", unit: "%", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 69, interval: "00:00:00.2000000", name: "Relative Throttle Position (SAE)", unit: "%", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 17, interval: "00:00:00.2000000", name: "Throttle Position (SAE)", unit: "%", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 76, interval: "00:00:00.2000000", name: "Commanded Throttle Actuator (SAE)", unit: "%", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 2161, interval: "00:00:00.2000000", name: "Throttle Desired Angle", unit: "°", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 2162, interval: "00:00:00.2000000", name: "Throttle Angle", unit: "°", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 19075, interval: "00:00:00.2000000", name: "ETC Throttle Angle Error", unit: "°", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 19079, interval: "00:00:00.1000000", name: "Effective Throttle Area (ETC Model)", unit: "in²", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 9309, interval: "00:00:01", name: "Torque Max Source", unit: "", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 9310, interval: "00:00:01", name: "Torque Max Protection Source", unit: "", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 11, interval: "00:00:00.1000000", name: "Intake Manifold Absolute Pressure (SAE)", unit: "psi", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 14, interval: "00:00:00.1000000", name: "Timing Advance (SAE)", unit: "°", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 17006, interval: "00:00:00.2000000", name: "Knock Cyl 1 (+Adv/-Ret)", unit: "°", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 17007, interval: "00:00:00.2000000", name: "Knock Cyl 2 (+Adv/-Ret)", unit: "°", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 17008, interval: "00:00:00.2000000", name: "Knock Cyl 3 (+Adv/-Ret)", unit: "°", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 17009, interval: "00:00:00.2000000", name: "Knock Cyl 4 (+Adv/-Ret)", unit: "°", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 17010, interval: "00:00:00.2000000", name: "Knock Cyl 5 (+Adv/-Ret)", unit: "°", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 17011, interval: "00:00:00.2000000", name: "Knock Cyl 6 (+Adv/-Ret)", unit: "°", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 17012, interval: "00:00:00.2000000", name: "Knock Cyl 7 (+Adv/-Ret)", unit: "°", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 17013, interval: "00:00:00.2000000", name: "Knock Cyl 8 (+Adv/-Ret)", unit: "°", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 19074, interval: "00:00:00.2000000", name: "Borderline Knock", unit: "°", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 19061, interval: "00:00:00.2000000", name: "MBT Advance", unit: "°", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 19046, interval: "00:00:01", name: "Spark Source", unit: "", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 2630, interval: "00:00:00.2000000", name: "Knock Retard", unit: "°", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 2649, interval: "00:00:00.2000000", name: "Knock Correction (+Adv/-Ret)", unit: "°", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 12533, interval: "00:00:00.2000000", name: "Knock Octane Modifier", unit: "", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 12536, interval: "00:00:00.2000000", name: "Inferred Octane", unit: "", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 3136, interval: "00:00:00.5000000", name: "Total Misfires Since Key-on", unit: "", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 68, interval: "00:00:00.1000000", name: "Equivalence Ratio Commanded (SAE)", unit: "λ", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 52, interval: "00:00:00.1000000", name: "WB EQ Ratio 1 (SAE) (2)", unit: "λ", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 56, interval: "00:00:00.1000000", name: "WB EQ Ratio 5 (SAE) (2)", unit: "λ", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 10, interval: "00:00:00.2000000", name: "Fuel Pressure (SAE)", unit: "psi", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 3, interval: "00:00:00.1000000", name: "Fuel System #1 Status (SAE)", unit: "", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 6, interval: "00:00:00.1000000", name: "Short Term Fuel Trim Bank 1 (SAE)", unit: "%", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 7, interval: "00:00:00.1000000", name: "Long Term Fuel Trim Bank 1 (SAE)", unit: "%", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 8, interval: "00:00:00.1000000", name: "Short Term Fuel Trim Bank 2 (SAE)", unit: "%", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 9, interval: "00:00:00.1000000", name: "Long Term Fuel Trim Bank 2 (SAE)", unit: "%", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 67, interval: "00:00:00.2000000", name: "Absolute Load (SAE)", unit: "%", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 8022, interval: "00:00:01", name: "Torque Airlimit Source", unit: "", authority: .verifiedViaMatchingCSVExport),
        .init(parameterID: 47, interval: "00:00:05", name: "Fuel Level Input (SAE)", unit: "%", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 66, interval: "00:00:01", name: "Control Module Voltage (SAE)", unit: "V", authority: .verifiedViaCSVAndHPLBinary),
        .init(parameterID: 70, interval: "00:00:10", name: "Ambient Air Temp (SAE)", unit: "°F", authority: .verifiedViaCSVAndHPLBinary),
    ]

    static func channel(forParameterID id: Int) -> HPTunerChannelDefinition? {
        channels.first { $0.parameterID == id }
    }
}

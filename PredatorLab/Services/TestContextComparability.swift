import Foundation

struct TestContextDifference: Identifiable, Codable, Equatable {
    let id: String
    let label: String
    let baseline: String
    let validation: String
    let designatedTestVariable: Bool
}

struct TestContextDimension: Identifiable, Codable, Equatable {
    let id: String
    let label: String
    let score: Double?
    let detail: String
    let weight: Double
}

struct TestContextReport: Codable, Equatable {
    let differences: [TestContextDifference]
    let missingCriticalContext: [String]
    let dimensions: [TestContextDimension]
    let score: Double?
    var grade: ComparabilityGrade {
        guard let score else { return .insufficient }
        return score >= 0.90 ? .excellent : score >= 0.75 ? .good : score >= 0.55 ? .limited : .poor
    }
}

enum TestContextComparabilityEngine {
    static func compare(_ baseline: Session?, _ validation: Session?) -> TestContextReport {
        guard let baseline, let validation else {
            return .init(differences: [], missingCriticalContext: ["A session record is not linked to one or both logs; fuel/calibration/test-setup comparability cannot be fully assessed."], dimensions: [], score: nil)
        }
        func clean(_ value: String?) -> String? { let v=(value ?? "").trimmingCharacters(in:.whitespacesAndNewlines); return v.isEmpty ? nil : v }
        func display(_ value: String?) -> String { clean(value) ?? "Unknown" }
        func categorical(_ id:String,_ label:String,_ a:String?,_ b:String?, weight:Double, testVariable:Bool=false) -> TestContextDimension {
            let x=clean(a), y=clean(b)
            let score:Double? = (x == nil || y == nil) ? nil : (x!.caseInsensitiveCompare(y!) == .orderedSame ? 1 : (testVariable ? 1 : 0))
            let detail = "\(display(a)) → \(display(b))" + (testVariable && x != y ? " (designated test variable)" : "")
            return .init(id:id,label:label,score:score,detail:detail,weight:weight)
        }
        func numeric(_ id:String,_ label:String,_ a:Double?,_ b:Double?, tolerance:Double, unit:String, weight:Double) -> TestContextDimension {
            let score:Double? = (a != nil && b != nil) ? max(0,1-abs(a!-b!)/tolerance) : nil
            let detail = (a != nil && b != nil) ? String(format:"%.1f → %.1f %@",a!,b!,unit) : "Unknown in one or both sessions."
            return .init(id:id,label:label,score:score,detail:detail,weight:weight)
        }
        let dims:[TestContextDimension] = [
            categorical("calibration","Calibration",baseline.experimentContext?.calibrationIdentifier,validation.experimentContext?.calibrationIdentifier,weight:0.5,testVariable:true),
            categorical("fuel","Fuel",baseline.experimentContext?.fuelDescription,validation.experimentContext?.fuelDescription,weight:2),
            categorical("tires","Tires",baseline.experimentContext?.tireConfiguration,validation.experimentContext?.tireConfiguration,weight:1),
            categorical("protocol","Test protocol",baseline.experimentContext?.testProtocol,validation.experimentContext?.testProtocol,weight:1.5),
            categorical("weather","Weather",baseline.weather,validation.weather,weight:0.5),
            numeric("ambientTemp","Ambient temperature",baseline.ambient.temperature,validation.ambient.temperature,tolerance:25,unit:"°F",weight:1),
            numeric("humidity","Humidity",baseline.ambient.humidity,validation.ambient.humidity,tolerance:40,unit:"%",weight:0.5),
            numeric("fuelLevel","Fuel level",baseline.experimentContext?.fuelLevelPercent,validation.experimentContext?.fuelLevelPercent,tolerance:50,unit:"%",weight:0.5)
        ]
        var differences:[TestContextDifference]=[]
        for d in dims where d.score != 1 || d.id == "calibration" {
            let parts=d.detail.components(separatedBy:" → ")
            differences.append(.init(id:d.id,label:d.label,baseline:parts.first ?? "Unknown",validation:parts.dropFirst().joined(separator:" → "),designatedTestVariable:d.id=="calibration"))
        }
        var missing:[String]=[]
        if clean(baseline.experimentContext?.fuelDescription) == nil || clean(validation.experimentContext?.fuelDescription) == nil { missing.append("Fuel description is unknown in one or both sessions.") }
        if clean(baseline.experimentContext?.calibrationIdentifier) == nil || clean(validation.experimentContext?.calibrationIdentifier) == nil { missing.append("Calibration identifier is unknown in one or both sessions.") }
        let weighted=dims.compactMap { d -> (Double,Double)? in d.score.map { ($0,d.weight) } }
        let total=weighted.reduce(0){$0+$1.1}
        let score=total > 0 ? weighted.reduce(0){$0+$1.0*$1.1}/total : nil
        return .init(differences:differences, missingCriticalContext:missing, dimensions:dims, score:score)
    }
}

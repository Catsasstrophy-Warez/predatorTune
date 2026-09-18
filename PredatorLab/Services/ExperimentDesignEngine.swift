import Foundation

struct ValidationPlan: Codable, Equatable {
    var investigationID: String
    var keepConstant: [String]
    var designatedVariables: [String]
    var requiredChannels: [CanonicalChannel]
    var successCriteria: [String]
    var stopCriteria: [String]
    var evidenceBoundary: String
}

enum ExperimentDesignEngine {
    static func plan(for definition: DiagnosticInvestigationDefinition, designatedVariables: [String] = []) -> ValidationPlan {
        .init(investigationID: definition.id,
              keepConstant:["Fuel and fuel level","Gear and RPM window","Test protocol","Tire configuration","Thermal starting condition where relevant"],
              designatedVariables: designatedVariables,
              requiredChannels: definition.requiredChannels,
              successCriteria:["Acquire sufficient evidence under the investigation evidence contract","Repeat enough comparable opportunities to assess recurrence","Compare distributions, not only one favorable event"],
              stopCriteria:["Unsafe vehicle behavior","Acquisition loses critical channels","Operating conditions leave the planned comparison envelope"],
              evidenceBoundary:"A successful validation can support improvement associated with the tested configuration; it does not isolate causation when multiple variables changed.")
    }
}

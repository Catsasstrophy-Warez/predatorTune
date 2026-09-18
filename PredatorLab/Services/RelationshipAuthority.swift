// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import Foundation
enum RelationshipAuthority:Int,Comparable,Sendable {
    case discoveryCandidate=0,verifiedAlias=1,explicitAuthored=2,sourceVerified=3,vehicleValidated=4
    static func <(l:Self,r:Self)->Bool{l.rawValue<r.rawValue}
    var executable:Bool { self == .sourceVerified || self == .vehicleValidated }
}
struct VerifiedChannelAlias:Equatable,Sendable {
    let scannerName:String;let technicalObjectID:String;let provenance:String;let authority:RelationshipAuthority
}

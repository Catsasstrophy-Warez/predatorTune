// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import Foundation

struct ForensicSelectionContext: Equatable, Sendable {
    var channelID:String?
    var eventID:UUID?
    var evidenceID:String?
    var hypothesisID:String?
    var calibrationID:UUID?
    var topologyNodeID:String?
    var time:TimeInterval?
    var isEmpty:Bool {
        channelID == nil && eventID == nil && evidenceID == nil && hypothesisID == nil &&
        calibrationID == nil && topologyNodeID == nil && time == nil
    }
}

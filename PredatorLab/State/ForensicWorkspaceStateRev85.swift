import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

@MainActor
final class ForensicWorkspaceStateRev85: ObservableObject {
    @Published var workspace: PredatorWorkspaceRev85 = .pullLab
    @Published var cursor: ForensicCursorRev85 = .empty
    /// Shared cross-workspace selection. Cursor already synchronizes time/rpm/eventID/
    /// evidenceID/hypothesisID/channelID across Pull Lab, Evidence, Topology and Replay;
    /// this adds the two fields cursor lacks (calibrationID, topologyNodeID) so Calibration
    /// and Topology selections are also visible to sibling workspaces.
    @Published var selection: ForensicSelectionContext = .init()
    @Published var selectedChannelID: String?
    @Published var inspectorPresented = false
    @Published var activeSession: ForensicSessionDatasetRev85?
    @Published var baselineSession: ForensicSessionDatasetRev85?
    @Published var selectedSeriesID: String?
    @Published var loadError: String?
    @Published var annotations: [ForensicAnnotationRev85] = []

    init(initialTwinNodeID: String? = nil, initialTime: TimeInterval? = nil, initialChannelID: String? = nil, initialHypothesisID: String? = nil) {
        if let node = initialTwinNodeID { selection.topologyNodeID = "twin:\(node)" }
        if let time = initialTime { cursor.time = time; selection.time = time }
        if let channel = initialChannelID { cursor.channelID = channel; selectedChannelID = channel; selection.channelID = channel }
        if let hypothesis = initialHypothesisID { cursor.hypothesisID = hypothesis; selection.hypothesisID = hypothesis }
    }

    func focusTwinNode(_ nodeID: String) {
        selection.topologyNodeID = "twin:\(nodeID)"
        inspectorPresented = true
    }

    func scrub(time: TimeInterval, rpm: Double? = nil, channelID: String? = nil) {
        cursor.time = time
        cursor.rpm = rpm
        cursor.channelID = channelID
        selectedChannelID = channelID
        selection.time = time
        selection.channelID = channelID
    }

    func load(log: ImportedLog, using repository: DataRepository) {
        do {
            activeSession = ForensicDataAdapterRev85.adapt(log: log, dataset: try repository.reloadDataset(for: log))
            selectedSeriesID = activeSession?.series.first?.id
            loadError = nil
        } catch { loadError = error.localizedDescription }
    }

    func setBaseline(log: ImportedLog, using repository: DataRepository) {
        do { baselineSession = ForensicDataAdapterRev85.adapt(log: log, dataset: try repository.reloadDataset(for: log)); loadError=nil }
        catch { loadError = error.localizedDescription }
    }

    func mark(_ text: String = "Operator mark") {
        annotations.append(.init(time: cursor.time ?? 0, source: .manualMark, text: text))
    }

    func selectEvidence(_ id: String) {
        cursor.evidenceID = id
        selection.evidenceID = id
        inspectorPresented = true
    }
}

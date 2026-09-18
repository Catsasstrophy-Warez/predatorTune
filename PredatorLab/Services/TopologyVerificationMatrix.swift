import Foundation

enum TopologyMatrixState: String, Codable, CaseIterable { case verified, authored, quarantined, missing, disputed }

struct TopologyMatrixCell: Identifiable, Codable, Equatable {
    let id: String
    let circuitID: String
    let sequence: Int
    let kind: TopologyClaimElementKind
    let designation: String
    let state: TopologyMatrixState
    let claimID: String?
    let sourceLocator: String?
    let applicability: String
    let note: String
}

struct TopologyVerificationMatrix: Codable, Equatable {
    let circuitID: String
    let title: String
    let cells: [TopologyMatrixCell]
    let boundary: String
    var verifiedCount: Int { cells.filter { $0.state == .verified }.count }
    var unresolvedCount: Int { cells.filter { [.authored, .quarantined, .missing, .disputed].contains($0.state) }.count }
}

enum TopologyVerificationMatrixEngine {
    static func matrix(circuitID: String, title: String, authoredDesignations: [(TopologyClaimElementKind,String)], claims: [TopologyEvidenceClaim] = TopologyEvidenceLedger.claims) -> TopologyVerificationMatrix {
        let cells = authoredDesignations.enumerated().map { index, item in
            let matching = claims.filter { $0.kind == item.0 && $0.designation.caseInsensitiveCompare(item.1) == .orderedSame }
            let best = matching.first { [.oemVerified,.manufacturerVerified,.professionalCorroboration,.empiricallyVerified].contains($0.state) } ?? matching.first
            let state: TopologyMatrixState
            if let best {
                switch best.state {
                case .oemVerified, .manufacturerVerified, .professionalCorroboration, .empiricallyVerified: state = .verified
                case .disputed: state = .disputed
                case .unverified, .predatorLabDerived, .communityObservation, .superseded: state = .quarantined
                }
            } else { state = .authored }
            return TopologyMatrixCell(id: "\(circuitID).\(index)", circuitID: circuitID, sequence: index, kind: item.0, designation: item.1, state: state, claimID: best?.id, sourceLocator: best?.locator, applicability: best?.applicability ?? "Authored circuit context only", note: best?.limitations ?? "No claim-level source dependency. Keep authored/quarantined until exact evidence is attached.")
        }
        return .init(circuitID: circuitID, title: title, cells: cells, boundary: "Verification is element-by-element. A verified source, fuse, connector, or module does not verify neighboring pins, conductors, splices, loads, grounds, measurements, or scanner semantics.")
    }

    static func missingElements(required: [(TopologyClaimElementKind,String)], matrix: TopologyVerificationMatrix) -> [(TopologyClaimElementKind,String)] {
        required.filter { req in !matrix.cells.contains { $0.kind == req.0 && $0.designation.caseInsensitiveCompare(req.1) == .orderedSame } }
    }
}

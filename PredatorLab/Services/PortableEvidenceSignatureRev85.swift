import Foundation
import CryptoKit

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

struct PortableEvidenceSignedEnvelopeRev85: Codable, Sendable {
    let schemaVersion: Int
    let payload: Data
    let payloadSHA256: String
    let signatureDER: Data
    let publicKeyX963: Data
    let keyFingerprintSHA256: String
    let algorithm: String
}

enum PortableEvidenceSignatureRev85 {
    static func sign(payload: Data, using privateKey: P256.Signing.PrivateKey) throws -> PortableEvidenceSignedEnvelopeRev85 {
        let payloadHash = SHA256.hash(data: payload)
        let signature = try privateKey.signature(for: payload)
        let publicKey = privateKey.publicKey.x963Representation
        return .init(
            schemaVersion: 1,
            payload: payload,
            payloadSHA256: payloadHash.map { String(format:"%02x",$0) }.joined(),
            signatureDER: signature.derRepresentation,
            publicKeyX963: publicKey,
            keyFingerprintSHA256: SHA256.hash(data:publicKey).map { String(format:"%02x",$0) }.joined(),
            algorithm: "P-256 ECDSA / SHA-256 identity metadata"
        )
    }

    static func verify(_ envelope: PortableEvidenceSignedEnvelopeRev85) -> Bool {
        guard envelope.schemaVersion == 1,
              PortableVerifiableEvidenceBundleRev85.sha256Hex(envelope.payload) == envelope.payloadSHA256,
              SHA256.hash(data:envelope.publicKeyX963).map({String(format:"%02x",$0)}).joined() == envelope.keyFingerprintSHA256,
              let publicKey = try? P256.Signing.PublicKey(x963Representation: envelope.publicKeyX963),
              let signature = try? P256.Signing.ECDSASignature(derRepresentation: envelope.signatureDER)
        else { return false }
        return publicKey.isValidSignature(signature, for: envelope.payload)
    }
}

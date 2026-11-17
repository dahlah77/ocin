//! POC demonstration of Ed25519 possession + BLAKE3 digest.
//! Keys are ephemeral, discarded after signing. Never rely on this proof for a
//! trusted paired device or persistent identity in production.

use ed25519_dalek::{Signature, Signer, SigningKey, VerifyingKey};
use rand::rngs::OsRng;

const DOMAIN: &[u8] = b"OCIN-POC01-IDENTITY-PROOF-V1\0";
const MAX_CHALLENGE_BYTES: usize = 1024;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IdentityProof {
    pub public_key_hex: String,
    pub signature_hex: String,
    pub challenge_hash_hex: String,
    pub algorithm: String,
}

fn identity_message(challenge: &str) -> Vec<u8> {
    let mut payload = Vec::with_capacity(DOMAIN.len() + challenge.len());
    payload.extend_from_slice(DOMAIN);
    payload.extend_from_slice(challenge.as_bytes());
    payload
}

pub fn create_ephemeral_identity_proof(challenge: &str) -> Result<IdentityProof, String> {
    if challenge.is_empty() || challenge.len() > MAX_CHALLENGE_BYTES {
        return Err("Challenge must contain 1..=1024 UTF-8 bytes".to_string());
    }
    let signing_key = SigningKey::generate(&mut OsRng);
    let signature = signing_key.sign(&identity_message(challenge));
    Ok(IdentityProof {
        public_key_hex: hex::encode(signing_key.verifying_key().to_bytes()),
        signature_hex: hex::encode(signature.to_bytes()),
        challenge_hash_hex: blake3::hash(challenge.as_bytes()).to_hex().to_string(),
        algorithm: "Ed25519 / BLAKE3 (ephemeral demo)".to_string(),
    })
}

pub fn verify_identity_proof(
    challenge: &str,
    public_key_hex: &str,
    signature_hex: &str,
) -> bool {
    if challenge.is_empty() || challenge.len() > MAX_CHALLENGE_BYTES {
        return false;
    }
    let Ok(key_vec) = hex::decode(public_key_hex) else {
        return false;
    };
    let Ok(sig_vec) = hex::decode(signature_hex) else {
        return false;
    };
    let Ok(key_bytes) = <[u8; 32]>::try_from(key_vec.as_slice()) else {
        return false;
    };
    let Ok(sig_bytes) = <[u8; 64]>::try_from(sig_vec.as_slice()) else {
        return false;
    };
    let Ok(verifying_key) = VerifyingKey::from_bytes(&key_bytes) else {
        return false;
    };
    verifying_key
        .verify_strict(&identity_message(challenge), &Signature::from_bytes(&sig_bytes))
        .is_ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sign_and_verify_roundtrip() {
        let proof = create_ephemeral_identity_proof("ocin-demo-challenge").unwrap();
        assert!(verify_identity_proof(
            "ocin-demo-challenge", &proof.public_key_hex, &proof.signature_hex
        ));
        assert_eq!(
            proof.challenge_hash_hex,
            blake3::hash(b"ocin-demo-challenge").to_hex().to_string()
        );
    }

    #[test]
    fn altered_challenge_is_rejected() {
        let proof = create_ephemeral_identity_proof("original").unwrap();
        assert!(!verify_identity_proof(
            "altered",
            &proof.public_key_hex,
            &proof.signature_hex
        ));
    }

    #[test]
    fn invalid_hex_is_rejected() {
        assert!(!verify_identity_proof("challenge", "not-hex", "not-hex"));
    }

    #[test]
    fn invalid_signature_is_rejected() {
        let proof = create_ephemeral_identity_proof("challenge").unwrap();
        assert!(!verify_identity_proof(
            "challenge",
            &proof.public_key_hex,
            &"00".repeat(64)
        ));
    }

    #[test]
    fn rejects_empty_or_oversized_challenge() {
        assert!(create_ephemeral_identity_proof("").is_err());
        assert!(create_ephemeral_identity_proof(&"x".repeat(1025)).is_err());
    }

    #[test]
    fn fresh_public_keys_differ() {
        let a = create_ephemeral_identity_proof("challenge").unwrap();
        let b = create_ephemeral_identity_proof("challenge").unwrap();
        assert_ne!(a.public_key_hex, b.public_key_hex);
    }
}

//! flutter_rust_bridge v2 API surface: keep types local to this crate for codegen.
//! This file is preserved by scripts/bootstrap.py and included by api/mod.rs.

pub struct CoreStatus {
    pub app_name: String,
    pub core_version: String,
    pub protocol_version: u32,
    pub platform: String,
    pub architecture: String,
    pub initialized: bool,
}

pub struct RuntimeCapabilities {
    pub platform: String,
    pub architecture: String,
    pub local_network_candidate: bool,
    pub ble_api_candidate: bool,
    pub screen_capture_api_candidate: bool,
    pub remote_input_api_candidate: bool,
    pub native_apple_glass_candidate: bool,
    pub experimental: bool,
    pub note: String,
}

pub struct IdentityProof {
    pub public_key_hex: String,
    pub signature_hex: String,
    pub challenge_hash_hex: String,
    pub algorithm: String,
}

pub fn get_core_status() -> CoreStatus {
    let s = ocin_core::get_core_status();
    CoreStatus {
        app_name: s.app_name,
        core_version: s.core_version,
        protocol_version: s.protocol_version,
        platform: s.platform,
        architecture: s.architecture,
        initialized: s.initialized,
    }
}

pub fn detect_runtime_capabilities() -> RuntimeCapabilities {
    let c = ocin_core::detect_runtime_capabilities();
    RuntimeCapabilities {
        platform: c.platform,
        architecture: c.architecture,
        local_network_candidate: c.local_network_candidate,
        ble_api_candidate: c.ble_api_candidate,
        screen_capture_api_candidate: c.screen_capture_api_candidate,
        remote_input_api_candidate: c.remote_input_api_candidate,
        native_apple_glass_candidate: c.native_apple_glass_candidate,
        experimental: c.experimental,
        note: c.note,
    }
}

pub fn create_ephemeral_identity_proof(challenge: String) -> Result<IdentityProof, String> {
    let p = ocin_core::create_ephemeral_identity_proof(&challenge)?;
    Ok(IdentityProof {
        public_key_hex: p.public_key_hex,
        signature_hex: p.signature_hex,
        challenge_hash_hex: p.challenge_hash_hex,
        algorithm: p.algorithm,
    })
}

pub fn verify_identity_proof(
    challenge: String,
    public_key_hex: String,
    signature_hex: String,
) -> bool {
    ocin_core::verify_identity_proof(&challenge, &public_key_hex, &signature_hex)
}

//! OCIN POC-01: core status, conservative capability hints, ephemeral identity proof.
//! No remote control, no persistent identity, no transport or production trust model.

pub mod identity;
pub mod runtime;

pub use identity::{create_ephemeral_identity_proof, verify_identity_proof, IdentityProof};
pub use runtime::{detect_runtime_capabilities, get_core_status, CoreStatus, RuntimeCapabilities};

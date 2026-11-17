use ocin_core::{
    create_ephemeral_identity_proof, detect_runtime_capabilities, get_core_status,
    verify_identity_proof,
};

fn main() {
    let s = get_core_status();
    let c = detect_runtime_capabilities();
    let challenge = "OCIN-POC01-healthcheck";
    let proof = create_ephemeral_identity_proof(challenge).expect("ephemeral proof should work");
    let verified = verify_identity_proof(challenge, &proof.public_key_hex, &proof.signature_hex);
    println!(
        "OCIN: {} {} ({}/{})",
        s.app_name, s.core_version, s.platform, s.architecture
    );
    println!(
        "Runtime capability status: EXPERIMENTAL/NOT TESTED ({}).",
        c.platform
    );
    println!("Ed25519 ephemeral proof validated: {verified}");
    assert!(verified, "signature verification should pass");
}

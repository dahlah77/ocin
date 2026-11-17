# POC-01 security and limitations

- Uses Ed25519 for a random **ephemeral** challenge proof, and BLAKE3 for challenge hashing.
- No private key leaves Rust; key is discarded as soon as the proof is generated.
- Does **not** establish permanent identity, trusted-device pairing, shared-secret key exchange, session encryption, or authenticated transport.
- The demonstration accepts a caller-provided public key. The app must pin a prior *trusted* key before using it as a real authentication mechanism.
- No BLE/remote commands are exposed. Screen capture, remote control and background services are absent.
- Production pairing requires validated QR/SAS key exchange with anti-MITM protections, secure platform key storage, retry rate limiting and revocation.
- Never implement custom cryptographic primitives; approved libraries must be used.

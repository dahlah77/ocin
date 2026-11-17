# OCIN PoC testing gates

## PoC-01

- Verify actual Rust core and bridge cargo tests after generating native-assets FRB scaffold.
- Verify Flutter generated bindings call `getCoreStatus`, `detectRuntimeCapabilities`, and Ed25519 sign/verify.
- Verify Apple Intel/arm64, Windows, Android and iOS builds on proper environments; Linux GitHub Actions does not establish cross-platform runtime success.
- Verify bridge error handling when native library unavailable.

## PoC-02

See `docs/POC02_TEST_PLAN.md`. Validate shader compilation and Apple native plugin in device builds before making any visual-fidelity or performance claims.

## Overall exit criteria

Only label each platform PASS after an actual build and runtime test. Mark NOT TESTED otherwise. Strict zero-cost GitHub billing controls must be configured in account settings, never assumed from workflow YAML.

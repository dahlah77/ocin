# OCIN — verification evidence

Baseline: v2.2. Repository: https://github.com/dahlah77/ocin (PUBLIC, by owner request).

## Verified on GitHub Actions

- Source archive SHA-256 matched the expected digest before import.
- All 35 source files were extracted and committed as individual files.
- Python source presence validation: **PASS** (18 required paths).
- Bootstrap Python unit tests: **PASS 5/5**.
- `flutter_rust_bridge_codegen create` and `generate` successfully produced the official Flutter and Rust scaffolds on Linux.
- Both Cargo workspaces passed `cargo metadata --no-deps`.
- The initial CI run caught real `cargo fmt --check` mismatches; these were corrected in source, not hidden by changing test gates.

## Verification pending

- Latest Rust formatting, Clippy and unit tests.
- Rust bridge crate compilation/test.
- `flutter analyze` and `flutter test`.
- Flutter shader GPU compilation and rendering on each target.
- Xcode SwiftUI native plugin and physical Apple device benchmark.
- Android/Windows platform builds.

GitHub Actions is authoritative for completion and failures:
https://github.com/dahlah77/ocin/actions

**Status:** SOURCE IMPORTED; LINUX CI IN PROGRESS. Do not claim OCIN built or production-ready until the corresponding tests pass.

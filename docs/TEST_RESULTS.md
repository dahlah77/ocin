# OCIN test evidence — local assembly

Date: 2026-11-18

- Python static presence: PASS (18 files)
- Python bootstrap tests: PASS (5/5)
- Cargo manifest path static inspection: PASS (`rust/../../../packages/ocin_core` resolves)
- Root Cargo manifest and nested-workspace design: SOURCE REVIEWED / NOT CARGO-VALIDATED
- FRB codegen: NOT RUN (missing toolchain)
- `cargo test`: NOT RUN (missing Rust/Cargo)
- `flutter analyze`: NOT RUN (missing Flutter SDK)
- `flutter test`: NOT RUN (missing Flutter SDK)
- Shader GPU compilation: NOT RUN (missing Flutter SDK)
- Native Swift compilation: NOT RUN (no Xcode)
- Physical frame benchmark: NOT RUN

Do not label the project built, verified, or release-ready until pipeline and device logs are available.

## 2026-11-18 — Autonomous publication readiness

- Private GitHub publish script: syntax test `bash -n` PASS.
- Project static validation: PASS.
- Bootstrap Python unit tests: PASS (5/5).
- Cloud repository created: NO (connected GitHub integration lacks create-repo action).
- Browser fallback: NOT AVAILABLE WITHOUT PAYMENT (not used; Rp0 policy).
- Remote GitHub Actions run: NOT RUN.
- Local `cargo` / `flutter` / Xcode: NOT AVAILABLE here; full build remains NOT TESTED.
- Locally committed git history + portable `git bundle` created for later zero-cost upload.

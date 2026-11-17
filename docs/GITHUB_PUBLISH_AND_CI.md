# OCIN — GitHub publication and CI

- Repository: https://github.com/dahlah77/ocin
- Owner: `dahlah77`
- Visibility: **PUBLIC**, explicitly authorized by the owner
- Default branch: `main`
- Workflow: `.github/workflows/ci.yml`

The OCIN v2.2 source was imported via a SHA-256-verified archive on GitHub Actions, then committed as individual source files. The one-time source importer was removed after the import. The two primary PoC modules are `packages/ocin_core` and `apps/ocin_app`; the Apple SwiftUI plugin is in `packages/ocin_native_glass`.

## Verification boundaries

The Linux CI installs Rust and Flutter, runs the official FRB generator, tests the Rust core and bridge, and runs Flutter analysis and widget tests. The GitHub workflow cannot prove macOS/iOS native Swift compilation, Windows hardware rendering, BLE interoperability, or real device performance. For those platforms keep the status **NOT TESTED** until device evidence exists.

GitHub standard hosted runners on public repos generally do not consume included private-repo runner minutes; verify current GitHub policies for future changes. No GitHub Actions workflow can force an account billing budget.

See [GitHub Actions](https://github.com/dahlah77/ocin/actions) for authoritative workflow outcomes. Do not use statements about hypothetical build success as test evidence.

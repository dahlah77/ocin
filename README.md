# OCIN — POC-01 + POC-02 / Architecture v2.2

**Type:** actual prototype source tree, NOT a tested shipping remote-desktop product.  **Purpose:** validate free Flutter + independent Rust core via `flutter_rust_bridge` v2, native Apple glass view/plugin, Impeller shader, and UI benchmark.

## Delivered

**POC-01 (Core):**
- `packages/ocin_core` Rust crate: status/capability *candidates*, Ed25519 ephemeral challenge-response, BLAKE3 checksum, tests.
- `apps/ocin_app/rust/src/api/ocin.rs`: FRB v2 API bridge.
- `scripts/bootstrap.py`: generates official FRB scaffold if missing, preserves OCIN source; injects the correct `ocin_core = { path = "../../../packages/ocin_core" }` dependency and an explicit independent `[workspace]` in bridge crate; checks the parent root workspace excludes it; links local native plugin and shader; regenerates Dart bindings.
- `.github/workflows/ci.yml`: Linux runner now installs Flutter/Rust/codegen and performs bootstrap, core tests, bridge crate tests, Flutter analysis and widget tests.

**POC-02 (Glass):**
- `lib/glass/adaptive_liquid_glass.dart`: single reusable widget with Apple-native bridge for *static navigation surfaces only*, Impeller `ImageFilter.shader()` for repeated cards, safe fallback when not supported, input-reactive highlights and spring press animation.
- `shaders/liquid_glass.frag`: sampled backdrop optical refraction, subtle chromatic separation, rim highlights, GLes Y-flip handling. Shader is registered in generated `pubspec.yaml`.
- `packages/ocin_native_glass`: Flutter plugin with SwiftUI `.glassEffect()` implementation for iOS 26+ / macOS 26+ and `MethodChannel` runtime support probe, avoiding editing template Runner files.
- `pages/glass_benchmark_page.dart`: 40 scrollable cards, tap counter, p95 frame and raster durations, fallback switch.
- Flutter widget tests for safe-fallback hit testing and isolation from native views.

## Known engineering limitations

- **Rust/Flutter SDK missing in this assembly environment.** `cargo build`, `flutter analyze`, `flutter test`, FRB codegen, GLSL compilation and Xcode tests have **not been executed here**. The source is a candidate for CI, **not a build-verified result**.
- Native SwiftUI glass requires **Xcode with iOS/macOS 26 SDK** and actual Apple OS ≥26. Platform view compositing of SwiftUI translucent material above a Flutter scene is a risk; physically test in PoC-02 before claiming visual correctness.
- Flutter documentation warns that macOS native platform views currently have compositing/gesture limitations; restrict native plugin to static navigation panels and keep interactive children as Flutter overlay. Do not instantiate in every list row.
- Impeller image filters require `ImageFilter.isShaderFilterSupported`. It is not guaranteed on Windows; safe tier falls back to standard blur (which does **not** provide equivalent refraction).
- The fallback is deliberately simpler and **not optical 1:1** with Apple Liquid Glass. POC-02 only demonstrates architecture and shader math, not pixel-accurate Apple cloning.
- The screen benchmark `FrameTiming` measures animation/build/raster frame costs but **cannot claim real FPS** until profile builds on target devices; frame samples can exclude/display different pipeline effects.
- Native screen capture, QUIC, BLE, file transfer, remote desktop, Xcode signing, and P2P are **not yet implemented**. The Rust identity demo is deliberately ephemeral and must not be used as persistent authentication.

## Free tooling required

- Flutter stable SDK with a version supporting `ImageFilter.shader` and build hooks.
- Rust stable + Cargo.
- `flutter_rust_bridge_codegen` v2.13.0.
- For Apple builds: Xcode (matching SDK), CocoaPods, and physical device for final verification.
- Android SDK for Android, Windows C++ tools for Windows.

## Bootstrap (once)

From repository root:

```bash
cargo install flutter_rust_bridge_codegen --version 2.13.0 --locked
python3 scripts/bootstrap.py
```

`bootstrap.py` downloads/builds the upstream FRB template only after tools are available; it runs `flutter pub get`, FRB generate, and Cargo metadata checks. Re-running is intended to be idempotent. It does not overwrite OCIN source.

## Test commands

```bash
python3 scripts/validate_structure.py
python3 -m unittest discover -s scripts -p 'test_*.py' -v
cargo test --workspace --all-targets
cargo test --manifest-path apps/ocin_app/rust/Cargo.toml
cd apps/ocin_app
flutter analyze
flutter test
flutter run
```

On the app dashboard choose **Buka POC-02 · Liquid Glass Benchmark**. Use `flutter run --profile` with a real GPU-capable device and record screenshots/timing. The SwiftUI native plugin is automatically registered by the Flutter plugin system on iOS/macOS after scaffold generation and pod installation.


## GitHub publishing — private OCIN repository

The project includes `scripts/publish_github.sh` for a one-command, fail-closed publishing workflow using GitHub CLI. It creates `dahlah77/ocin` as **private** when the signed-in account is `dahlah77`, refuses accidental changes to other or existing nonempty repositories, and pushes the project to trigger CI. See `docs/GITHUB_PUBLISH_AND_CI.md`.

This **has not been executed** in the assembly environment because the linked GitHub connector lacks repository-creation authority and the browser automation service requires paid credit. **No new remote repository and no remote CI run have been created.**

## Continuous integration

Push this tree to a GitHub repository to run `.github/workflows/ci.yml` using GitHub Actions. No repository or workflow has been created remotely by the assistant. Linux CI can validate Rust/FRB/Dart but **cannot certify Apple native Swift or actual GPU rendering**. CI minutes are subject to GitHub's free budget; **workflow YAML cannot force US$0 billing**. Set billing safeguards at account level and do not enable paid overage.

### To review with Gemini

Send the entire ZIP. Ask Gemini to inspect the **contents** of `bootstrap.py`, `Cargo.toml`, Flutter plugin Swift/podspec, shader uniform order and plugin registration, then validate CI run logs. The package contains actual files; a filename-only inspection cannot establish build correctness.

## References

- FRB create/integrate: https://cjycode.com/flutter_rust_bridge/manual/integrate/builtin
- Flutter shader filters: https://docs.flutter.dev/ui/design/graphics/fragment-shaders
- Flutter macOS PlatformViews: https://docs.flutter.dev/platform-integration/macos/platform-views
- Flutter iOS PlatformViews: https://docs.flutter.dev/platform-integration/ios/platform-views
- Apple native glass: https://developer.apple.com/documentation/SwiftUI/GlassEffectContainer

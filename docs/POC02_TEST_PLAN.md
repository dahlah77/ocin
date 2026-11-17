# PoC-02 measurable test protocol

## Local static validations

- Verify shader declared under `flutter: shaders:` in generated app `pubspec.yaml`.
- Verify Swift plugin registered in generated Flutter plugin registrant (`ocin_native_glass`) on iOS and macOS.
- Run `flutter analyze`, `flutter test` and widget tap test.
- Run all Python idempotence tests; verify two Cargo workspace metadata commands.

## GPU benchmark per physical device

Collect: OS version, CPU/GPU, screen resolution, refresh rate, Flutter version, engine backend, profile/release mode, and Xcode version for Apple.

1. Baseline: force safe fallback, perform 5 identical scroll traversals (top → bottom → top) across 40 cards; record p50/p95 frame and raster durations, frame count and >16.7-ms samples.
2. Shader: disable forced fallback on Impeller-compatible devices; record same metrics and screenshot comparators.
3. Native static navigation: use iOS 26+/macOS 26+; record 5 traversals, tap all visible cards, inspect clipping and overlay blend. Count native views (target 1).
4. On unsupported Windows renderers: assert safe fallback without crash or black screen.
5. Test High Contrast and Apple Reduce Transparency; verify shader fallback is disabled for those settings.
6. Repeated input: mouse hover, touch down/up; verify spring animation terminates and tap counter increments exactly once.

**Exit criteria:** codegen/build executes, no hit-testing regressions, no crashes, benchmark logs from physical devices. Numeric thresholds may be set only after baseline measurement; target 60 FPS is an aspiration, not a measured result.

## Known risks

- Native UIHostingController rendering in hybrid Flutter composition may not refract underlying Flutter content exactly like a native SwiftUI scene; if so, mark PARTIAL and retain shader navigation fallback.
- Flutter may not expose OS Reduce Transparency uniformly; Apple plugin probes via MethodChannel. Non-Apple high contrast is a conservative approximation.
- iOS/macOS Swift code requires current SDK. Linux CI will never compile those Swift files.

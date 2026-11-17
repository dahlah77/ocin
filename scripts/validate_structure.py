#!/usr/bin/env python3
"""Static file presence checks; does not prove a Flutter or Rust build works."""
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    'Cargo.toml',
    'packages/ocin_core/Cargo.toml',
    'packages/ocin_core/src/lib.rs',
    'packages/ocin_core/src/identity.rs',
    'packages/ocin_core/src/runtime.rs',
    'apps/ocin_app/rust/src/api/ocin.rs',
    'apps/ocin_app/lib/main.dart',
    'apps/ocin_app/lib/glass/adaptive_liquid_glass.dart',
    'apps/ocin_app/lib/pages/glass_benchmark_page.dart',
    'apps/ocin_app/test/adaptive_liquid_glass_test.dart',
    'apps/ocin_app/shaders/liquid_glass.frag',
    'packages/ocin_native_glass/pubspec.yaml',
    'packages/ocin_native_glass/ios/Classes/OcinNativeGlassPlugin.swift',
    'packages/ocin_native_glass/macos/Classes/OcinNativeGlassPlugin.swift',
    'packages/ocin_native_glass/ios/ocin_native_glass.podspec',
    'packages/ocin_native_glass/macos/ocin_native_glass.podspec',
    '.github/workflows/ci.yml',
    'scripts/bootstrap.py',
]
missing = [path for path in REQUIRED if not (ROOT / path).is_file()]
if missing:
    raise SystemExit(f'STATIC CHECK FAIL: {missing}')
print(f'STATIC CHECK PASS: {len(REQUIRED)} source/config files present.')

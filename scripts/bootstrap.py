#!/usr/bin/env python3
"""Bootstrap OCIN from the official flutter_rust_bridge v2 native-assets template.

This script never overwrites OCIN-authored files.  It is safe to run again.
It creates Flutter and Rust generated boilerplate only when absent, validates
both Cargo workspaces, links the native glass plugin, and runs FRB codegen.
"""
from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / 'apps' / 'ocin_app'
CORE = ROOT / 'packages' / 'ocin_core'
NATIVE_GLASS = ROOT / 'packages' / 'ocin_native_glass'
ROOT_MANIFEST = ROOT / 'Cargo.toml'
CORE_DEP = 'ocin_core = { path = "../../../packages/ocin_core" }'
DART_DEP = '  ocin_native_glass:\n    path: ../../packages/ocin_native_glass'


def run(args: list[str], *, cwd: Path) -> None:
    print('+', ' '.join(args), flush=True)
    subprocess.run(args, cwd=cwd, check=True)


def must_have(binary: str) -> None:
    if not shutil.which(binary):
        raise RuntimeError(f'{binary!r} not found in PATH; install free SDKs according to README.')


def copy_missing(source: Path, dest: Path) -> None:
    for folder, dirs, files in os.walk(source):
        dirs[:] = [n for n in dirs if n not in {'.git', '.dart_tool', 'build', 'target', '.idea'}]
        rel = Path(folder).relative_to(source)
        dst = dest / rel
        dst.mkdir(parents=True, exist_ok=True)
        for name in files:
            if name.startswith('.flutter-plugins'):
                continue
            a, b = Path(folder) / name, dst / name
            if not b.exists():
                shutil.copy2(a, b)


def patch_rust_manifest() -> None:
    """Keep generated Rust crate isolated from root workspace, add core dependency."""
    path = APP / 'rust' / 'Cargo.toml'
    if not path.exists():
        raise RuntimeError('Missing generated rust/Cargo.toml; FRB create may have failed')
    body = path.read_text(encoding='utf-8')
    if '[dependencies]' not in body:
        raise RuntimeError('Generated manifest has no [dependencies]; inspect FRB template')
    if not re.search(r'^ocin_core\s*=', body, re.M):
        body = body.replace('[dependencies]', '[dependencies]\n' + CORE_DEP, 1)
    # Explicitly opt out of the parent Cargo workspace. This is necessary if
    # Cargo workspace membership changes or the generator is run in a monorepo.
    if not re.search(r'^\[workspace\]\s*$', body, re.M):
        body = body.rstrip() + '\n\n[workspace]\nresolver = "2"\n'
    path.write_text(body, encoding='utf-8')


def validate_workspace() -> None:
    root = ROOT_MANIFEST.read_text(encoding='utf-8')
    if 'exclude = ["apps/ocin_app/rust"]' not in root:
        raise RuntimeError('Root Cargo workspace must exclude apps/ocin_app/rust')
    body = (APP / 'rust' / 'Cargo.toml').read_text(encoding='utf-8')
    if CORE_DEP not in body:
        raise RuntimeError('Generated bridge crate has incorrect ocin_core relative path')
    relative_core = (APP / 'rust' / '../../../packages/ocin_core/Cargo.toml').resolve()
    if relative_core != (CORE / 'Cargo.toml').resolve() or not relative_core.exists():
        raise RuntimeError('Generated Rust dependency relative path does not resolve')
    if '[workspace]' not in body:
        raise RuntimeError('Bridge crate needs explicit nested Cargo workspace')


def patch_flutter_pubspec() -> None:
    path = APP / 'pubspec.yaml'
    if not path.exists():
        raise RuntimeError('Missing pubspec.yaml after FRB create')
    body = path.read_text(encoding='utf-8')
    if not re.search(r'^dependencies:\s*$', body, re.M):
        raise RuntimeError('Missing dependencies in generated pubspec')
    if not re.search(r'^  ocin_native_glass:\s*$', body, re.M):
        body = body.replace('dependencies:', 'dependencies:\n' + DART_DEP, 1)
    # Flutter shader compiler only processes entries under `flutter: shaders:`.
    # Insert before the next top-level key rather than replacing template flags.
    if 'shaders/liquid_glass.frag' not in body:
        match = re.search(r'^flutter:\s*$', body, re.M)
        if not match:
            body = body.rstrip() + '\n\nflutter:\n  shaders:\n    - shaders/liquid_glass.frag\n'
        else:
            start = match.end()
            body = body[:start] + '\n  shaders:\n    - shaders/liquid_glass.frag' + body[start:]
    path.write_text(body, encoding='utf-8')


def ensure_ocin_module() -> None:
    path = APP / 'rust' / 'src' / 'api' / 'mod.rs'
    path.parent.mkdir(parents=True, exist_ok=True)
    body = path.read_text(encoding='utf-8') if path.exists() else ''
    if not re.search(r'^\s*pub\s+mod\s+ocin\s*;', body, re.M):
        path.write_text(body.rstrip() + '\npub mod ocin;\n', encoding='utf-8')


def main() -> None:
    for binary in ('flutter', 'cargo', 'flutter_rust_bridge_codegen'):
        must_have(binary)
    if not (CORE / 'Cargo.toml').exists():
        raise RuntimeError('Missing packages/ocin_core')
    if not (NATIVE_GLASS / 'pubspec.yaml').exists():
        raise RuntimeError('Missing packages/ocin_native_glass Flutter plugin')
    if not (APP / 'pubspec.yaml').exists():
        print('[OCIN] Generating official Flutter/FRB scaffold…')
        with tempfile.TemporaryDirectory(prefix='ocin-frb-scaffold-') as temp:
            tmp = Path(temp)
            run(['flutter_rust_bridge_codegen', 'create', 'ocin_app',
                 '--integration-backend', 'native-assets'], cwd=tmp)
            generated = tmp / 'ocin_app'
            if not (generated / 'pubspec.yaml').exists():
                raise RuntimeError('FRB did not create pubspec.yaml')
            copy_missing(generated, APP)
    else:
        print('[OCIN] Reusing existing scaffold')
    patch_rust_manifest()
    validate_workspace()
    patch_flutter_pubspec()
    ensure_ocin_module()
    template_test = APP / 'test' / 'widget_test.dart'
    if template_test.exists():
        template_test.unlink()
    run(['flutter', 'pub', 'get'], cwd=APP)
    run(['flutter_rust_bridge_codegen', 'generate'], cwd=APP)
    # Verify both Cargo manifests are independently parseable.
    run(['cargo', 'metadata', '--no-deps', '--format-version', '1'], cwd=ROOT)
    run(['cargo', 'metadata', '--no-deps', '--format-version', '1'], cwd=APP / 'rust')
    print('OCIN BOOTSTRAP COMPLETE. Run core + bridge cargo tests, flutter analyze/test.')


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, subprocess.CalledProcessError) as error:
        print(f'OCIN BOOTSTRAP FAILED: {error}', file=sys.stderr)
        sys.exit(1)

#!/usr/bin/env python3
"""Pure-Python regression suite (Flutter/Rust compilation is a separate gate)."""
from __future__ import annotations
import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('ocin_bootstrap', Path(__file__).with_name('bootstrap.py'))
bootstrap = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(bootstrap)

class BootstrapTests(unittest.TestCase):
    def test_copy_missing_preserves_authored_files(self):
        with tempfile.TemporaryDirectory() as td:
            a, b = Path(td) / 'generated', Path(td) / 'ocin'
            (a / 'lib').mkdir(parents=True)
            (b / 'lib').mkdir(parents=True)
            (a / 'lib' / 'main.dart').write_text('template')
            (a / 'lib' / 'new.dart').write_text('new')
            (b / 'lib' / 'main.dart').write_text('ocin')
            bootstrap.copy_missing(a, b)
            self.assertEqual((b / 'lib' / 'main.dart').read_text(), 'ocin')
            self.assertEqual((b / 'lib' / 'new.dart').read_text(), 'new')

    def test_cargo_manifest_patch_is_idempotent(self):
        with tempfile.TemporaryDirectory() as td:
            old = bootstrap.APP
            try:
                bootstrap.APP = Path(td)
                p = bootstrap.APP / 'rust' / 'Cargo.toml'
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text('[package]\nname = "rust_lib_ocin_app"\nversion = "0.1.0"\n[dependencies]\nflutter_rust_bridge = "2.13.0"\n')
                bootstrap.patch_rust_manifest()
                bootstrap.patch_rust_manifest()
                content = p.read_text()
                self.assertEqual(content.count(bootstrap.CORE_DEP), 1)
                self.assertEqual(content.count('[workspace]'), 1)
            finally:
                bootstrap.APP = old

    def test_flutter_pubspec_patch_is_idempotent(self):
        with tempfile.TemporaryDirectory() as td:
            old = bootstrap.APP
            try:
                bootstrap.APP = Path(td)
                p = bootstrap.APP / 'pubspec.yaml'
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text('name: ocin_app\ndependencies:\n  flutter:\n    sdk: flutter\nflutter:\n  uses-material-design: true\n')
                bootstrap.patch_flutter_pubspec()
                bootstrap.patch_flutter_pubspec()
                self.assertEqual(p.read_text().count('ocin_native_glass:'), 1)
                self.assertEqual(p.read_text().count('shaders/liquid_glass.frag'), 1)
            finally:
                bootstrap.APP = old

    def test_ocin_module_is_idempotent(self):
        with tempfile.TemporaryDirectory() as td:
            old = bootstrap.APP
            try:
                bootstrap.APP = Path(td)
                bootstrap.ensure_ocin_module()
                bootstrap.ensure_ocin_module()
                self.assertEqual((bootstrap.APP / 'rust/src/api/mod.rs').read_text().count('pub mod ocin;'), 1)
            finally:
                bootstrap.APP = old

    def test_repo_has_compatible_core_path(self):
        self.assertTrue((bootstrap.APP / 'rust/../../../packages/ocin_core/Cargo.toml').exists())

if __name__ == '__main__':
    unittest.main()

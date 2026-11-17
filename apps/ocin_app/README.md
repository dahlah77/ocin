# OCIN Flutter Host (POC-01)

Dart UI and Rust bridge API wrapper are already authored here. The platform-specific boilerplate,
`pubspec.yaml`, `rust/Cargo.toml`, and generated FRB bindings are intentionally produced using the
official `flutter_rust_bridge_codegen create` command.

**Do not run `flutter run` until you have run `python3 scripts/bootstrap.py` from the monorepo root.**

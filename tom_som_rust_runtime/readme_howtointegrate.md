# Integrating tom_som_rust_runtime

`tom_som_rust_runtime` is the generic, value-free TomSpecs object-model runtime
for Rust. It has **zero external dependencies** (Rust standard library only) and
is versioned to the TomSpecs **model version** — the same version the typed
facade `tom_som_rust_v0` reports. Pin both to that version so your document reads
and writes match the model the facade was generated from.

Most projects depend on the typed facade `tom_som_rust_v0` (which depends on this
runtime by a relative `path`) rather than on the runtime directly. Depend on the
runtime alone only when you drive the generic API by section path.

Both crates are `publish = false` (proprietary), so `cargo package --no-verify`
is the packaging check rather than `cargo publish`.

## Quick start

```toml
[dependencies]
tom_som_rust_runtime = { path = "../tom_som_rust_runtime", version = "1.0.0" }
```

```rust
use tom_som_rust_runtime as som;

let mut doc = som::SpecDocument::new();
doc.set_content("SBP/content", "A unifying order platform.");
println!("{}", doc.content_or("SBP/content"));
```

## Dependency routes

### From crates.io

The runtime is proprietary (`publish = false`) and is not on the public
crates.io. When mirrored to a private registry, add it as a dependency:

```toml
[dependencies]
tom_som_rust_runtime = "1.0.0"
```

### Git dependency

Depend on the runtime directly from source control (it lives in a sub-directory
of the mono-repo — Cargo discovers the crate by name):

```toml
[dependencies]
tom_som_rust_runtime = { git = "https://github.com/al-the-bear/tom_ai_build.git", branch = "main" }
```

### Path dependency (monorepo / vendored)

When the SOM crates sit alongside your crate, resolve the runtime from a local
checkout with a `path` dependency. Because `cargo package` requires every
dependency to carry a version, pin the version alongside the path (the packaged
manifest keeps the version and drops the path):

```toml
[dependencies]
tom_som_rust_runtime = { path = "../tom_som_rust_runtime", version = "1.0.0" }
```

This is exactly how `tom_som_rust_v0` consumes the runtime — the generator writes
a versioned relative `path` dependency into the facade `Cargo.toml`, so the
generated source stays path-free and golden-stable while still building in-repo.

## Pinning the version

`tom_som_rust_runtime` and `tom_som_rust_v0` both carry the TomSpecs model
version in their `Cargo.toml`. When you upgrade the model, regenerate the facade
and move both crates to the new matching version so the runtime, the facade, and
your stored documents stay in step. The runtime is hand-authored (never
regenerated); only its version is realigned to the model version by
`generate_som.dart`.

## Building from source

The runtime builds with the Cargo toolchain and has no external dependencies:

```bash
cargo build                     # compile the runtime
cargo test                      # → "OK: N checks passed"
cargo package --no-verify       # produce the .crate packaging artifact
```

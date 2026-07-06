# tom_som_conformance

Cross-language conformance assets for the SOM (Spec Object Model) runtimes and
generated `tom_som_<lang>_v0` facades. Everything here is **language-agnostic**:
one shared sample, one shared corpus, and one golden harness that proves all
nine language APIs agree.

## Layout

| Path | Purpose |
| ---- | ------- |
| `samples/` | The shared specification sample (`meridian_order_management.docspecs.yaml` + `.md`), authored once through the Dart typed facade and loaded by every language. See `samples/README.md`. |
| `corpus/` | Language-agnostic case tables (section-id, operations, validation, reflection, serialization-order) plus their expected outputs, consumed by each runtime's conformance runner. |
| `golden/` | Per-language golden logs (`<lang>.log`) written by the nine golden generators. **Git-ignored** — regenerated on demand (see below). |
| `tool/` | The golden harness: `regenerate_golden.sh` (driver) and `compare_golden.dart` (byte-identical assertion). |

## Cross-language golden harness (roadmap item 7b)

Each `tom_som_<lang>_v0` project ships a golden generator that loads the shared
sample and emits a canonical, deterministic reading of *essentially every
section* through **both** the generic string-path API and the typed facade:

| Language | Generator |
| -------- | --------- |
| Dart (reference) | `tom_som_dart_v0/tool/golden_log.dart` |
| Python | `tom_som_python_v0/tool/golden_log.py` |
| JavaScript | `tom_som_javascript_v0/tool/golden_log.js` |
| TypeScript | `tom_som_typescript_v0/tool/golden_log.ts` |
| Go | `tom_som_go_v0/tool/golden_log.go` |
| Java | `tom_som_java_v0/tool/GoldenLog.java` |
| Rust | `tom_som_rust_v0/examples/golden_log.rs` |
| C | `tom_som_c_v0/tool/golden_log.c` |
| C++ | `tom_som_cpp_v0/tool/golden_log.cpp` |

The log format is defined once in the Dart generator (the reference) and
mirrored verbatim by the other eight. It is intentionally line-oriented,
LF-terminated, ASCII-path, and value-escaped so it compares byte-for-byte across
languages regardless of their native string/collection types. Each generator is
itself a test: it asserts the typed reads equal the generic reads before writing,
so a facade/runtime divergence aborts with a non-zero exit instead of emitting a
silently-wrong log.

### Running

```bash
# Regenerate all nine logs and assert byte-identity (needs the nine toolchains):
./tool/regenerate_golden.sh

# Or, if the logs already exist, just re-run the comparison:
dart run tool/compare_golden.dart
```

`compare_golden.dart` compares raw bytes (not decoded text), so a stray CR, BOM,
or trailing-newline difference is caught. On a mismatch it reports the first
differing line against the Dart reference and exits non-zero. A green run proves
all nine language APIs yield exactly the same reading of the same specification.

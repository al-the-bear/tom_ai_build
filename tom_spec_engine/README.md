# tom_spec_engine

The **TomSpecs scripting/engine plane** — the pure-Dart host behind the TomSpecs
editor's D4rt scripting & LLM tooling. It is factored as its own project so it
stays usable headless (CLI, tests) and is linked **in-process** by the Flutter
editor.

> **Status: Phase-A scaffold.** Only package metadata ships today. The
> capabilities below are the target surface; they land step by step per
> [`llm_and_d4rt_tools.md`](../tom_specs_model/doc/llm_and_d4rt_tools.md).

## What it will own

| Area | Role | Spec § |
| --- | --- | --- |
| **Scope registry** | Named, immutable sets of bridged D4rt libraries + globals + permission grants; the three base scopes `spec` / `files` / `memory`. | §4 |
| **`spec` scope** | The `tom_som` document API (generic / reflection / typed `tom_som_dart_v0`) bound to the live `SpecDocumentController`, plus search. | §5 |
| **`files` scope** | A restricted `dcli` facade — read anywhere, write only under `agent/scratchpad`. | §7 |
| **Search index** | Structural/lexical (BM25/FTS + facets) over the object model, zero-LLM, incremental refresh; backs grep-like cursor search. | §6 |
| **RAG memory** | Section-level nodes in **Tom Brain named memory**; tier-1 lexical + tier-2 incremental vectors (Tom Brain embedding API); fused recall. | §9 |
| **Agent substrate** | Pluggable `AgentSubstrate` — direct Agent SDK (mode a) and Agent-SDK-through-Tom-Brain (mode b) — over profiles / named sessions / named memory. | §10 |

## Dependencies

- [`tom_d4rt`](../../d4rt/tom_d4rt) `^1.10.1` — the sandboxed interpreter (now on
  `analyzer ^10`, so it co-resolves with the editor's `tom_dart_editor`).
- [`tom_d4rt_dcli`](../../d4rt/tom_d4rt_dcli) `^1.1.3` — dcli bridged into D4rt;
  wrapped (never exposed raw) by the `files` scope facade.
- [`tom_som_dart_runtime`](../tom_som_dart_runtime),
  [`tom_som_dart_v0`](../tom_som_dart_v0) — the document model the `spec` scope
  exposes.

The **embeddable Tom Brain** packages (substrate / memory / procedure) back the
in-process substrate façade — see
[`llm_and_d4rt_tools.md`](../tom_specs_model/doc/llm_and_d4rt_tools.md) §9.3.

## Develop

```bash
dart pub get
dart analyze
dart test     # or: testkit :test
```

### Vector runtime precondition

The memory plane boots on `SqliteTomBrainMemory`, which **refuses to open**
unless the bundled sqlite-vec (`vec0`) extension registers — vector recall is
mandatory and there is no BM25-only fallback. Two things must hold for that:

1. a packaged `vec0` binary for the running platform exists under
   `tom_binaries/sqlite_vec/<platform>/`, **and**
2. the `libsqlite3` the **host process** resolves supports extension loading.

Condition 2 is a property of the process, not of this package, and it is not
universally true:

| Host | Resolved SQLite | Vector runtime |
| --- | --- | --- |
| Flutter desktop (the editor) | bundled via `sqlite3_flutter_libs` | **yes** |
| bare `dart test` on Linux | distro `libsqlite3.so` | **yes** |
| bare `dart test` on macOS | Apple's `/usr/lib/libsqlite3.dylib` | **no** |
| bare `dart test` on Windows | `sqlite3.dll` if one is on the search path, else `winsqlite3.dll` | depends |

Apple's system SQLite is compiled with `SQLITE_OMIT_LOAD_EXTENSION`: it exports
neither `sqlite3_load_extension` nor `sqlite3_enable_load_extension`, and
`sqlite3_auto_extension` answers `SQLITE_MISUSE` (21). The `vec0` dylib itself
is fine — it opens and its `sqlite3_vec_init` symbol resolves — but nothing can
register it. So a bare `dart test` on macOS has **no** vector runtime, and that
is expected rather than a defect. A distro `libsqlite3.so` does export the
extension-loading API, so the same suites run for real on Linux; Windows
depends on which DLL resolves, since `winsqlite3.dll` omits it too.

The four store-touching suites (`spec_memory`, `spec_rag_store`,
`spec_recall_store`, `spec_brain_envelope`) therefore gate on
`test/support/vector_runtime.dart`, which **probes the actual load** once per
test isolate rather than inferring availability from the binary's presence.
Where the runtime is missing those tests are reported as **skipped, with the
reason**, so the precondition is stated rather than hidden behind a red suite.
Run them on Linux, or from the Flutter editor host, to exercise the vector
tier for real.

# tom_spec_engine

The **TomSpecs scripting/engine plane** — the pure-Dart host behind the TomSpecs
editor's D4rt scripting & LLM tooling. It is factored as its own project so it
stays usable headless (CLI, tests) and is linked **in-process** by the Flutter
editor.

> **Specification:**
> [`llm_and_d4rt_tools.md`](../tom_specs_model/doc/llm_and_d4rt_tools.md) is the
> authority for this plane. The `Spec §` column below cites it section by
> section.

## What it owns

| Area | Role | Spec § |
| --- | --- | --- |
| **Scope registry** | Named, immutable sets of bridged D4rt libraries + globals + permission grants; the three base scopes `spec` / `files` / `memory`. | §4 |
| **`spec` scope** | The `tom_som` document API (generic / reflection / typed `tom_som_dart_v0`) bound to the live `SpecDocumentController`, plus search. | §5 |
| **Search index** | Structural/lexical (BM25/FTS + facets) over the object model, zero-LLM, incremental refresh; backs grep-like cursor search. | §6 |
| **`files` scope** | A restricted `dcli` facade — read anywhere, write only under `agent/scratchpad`. | §7 |
| **Tool surface** | The engine logic behind the MCP tools: `script_*` (author / validate / run a named D4rt script under granted scopes) and the in-memory `doc_*` / `mem_*` / `file_*` tools, each returning a typed result with a compact `toJson`. | §8 |
| **RAG memory** | Section-level nodes in **Tom Brain named memory**; tier-1 lexical + tier-2 incremental vectors (Tom Brain embedding API); fused recall. | §9 |
| **`memory` scope** | A read-only recall facade over the fused recall — one injected `memory` global, no permission grant, so a sandboxed script can recall but has no mutation path. | §4 · §9 |
| **Agent substrate** | Pluggable `AgentSubstrate` — direct (mode a) and Agent-SDK-through-Tom-Brain (mode b, the default) — over profiles / named sessions / named memory, plus the multi-turn conversational layer that composes on either mode through an injected driver port. | §10 |
| **Agent context** | The per-application `{guidelines, toolset, scope profile}` triple as a Tom Brain profile, with the *toolset ⊆ scopes* invariant enforced at construction, and the registry that swaps all three together. | §11 |

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

Condition 2 is a property of the process, not of this package, and the
platform default does not always satisfy it:

| Host | Default SQLite | Extension loading |
| --- | --- | --- |
| Flutter desktop (the editor) | bundled via `sqlite3_flutter_libs` | **yes** |
| bare `dart test` on Linux | distro `libsqlite3.so` | **yes** |
| bare `dart test` on macOS | Apple's `/usr/lib/libsqlite3.dylib` | **no** |
| bare `dart test` on Windows | `sqlite3.dll` if one is on the search path, else `winsqlite3.dll` | depends |

Apple's system SQLite is compiled with `SQLITE_OMIT_LOAD_EXTENSION`: it exports
neither `sqlite3_load_extension` nor `sqlite3_enable_load_extension`, and
`sqlite3_auto_extension` answers `SQLITE_MISUSE` (21). The `vec0` dylib itself
is fine — it opens and its `sqlite3_vec_init` symbol resolves — but nothing can
register it. Windows is in the same position when `winsqlite3.dll` is what
resolves, since it omits the API too.

**The tests do not depend on the default.** `test/support/vector_runtime.dart`
looks for a `libsqlite3` that *does* support extension loading and points
`package:sqlite3` at it through the public `open.overrideFor` seam before the
first SQLite access. Search order:

1. `$TOM_SQLITE3_LIB` — an explicit path, honoured on every platform.
2. Homebrew's `sqlite` formula, on macOS: `/opt/homebrew/opt/sqlite/lib/…`
   then `/usr/local/opt/sqlite/lib/…`.

A candidate is accepted only if it opens **and** exports
`sqlite3_enable_load_extension`; otherwise the platform default stands
untouched. On a macOS box with `brew install sqlite` the four store-touching
suites (`spec_memory`, `spec_rag_store`, `spec_recall_store`,
`spec_brain_envelope`) therefore run the vector tier **for real** under a bare
`dart test`. Without it they skip, as before.

This is **test support only**. Production is deliberately untouched: the
Flutter desktop host already bundles a working SQLite, and overriding there
would trade correct behaviour for machine-dependent behaviour.

The gate itself stays a **probe, not a proxy** — after any override,
`VectorRuntime.probe()` still runs the real load once per test isolate and
reports the outcome, so a host that still cannot register `vec0` yields
**skipped tests with the reason stated** rather than a red suite.

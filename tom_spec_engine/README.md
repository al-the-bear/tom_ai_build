# tom_spec_engine — the TomSpecs scripting and agent plane

> **Cross-references.**
> [`tom_specs_model/doc/llm_and_d4rt_tools.md`](../tom_specs_model/doc/llm_and_d4rt_tools.md)
> is the authority for everything this package implements — the scope model
> (`llm_and_d4rt_tools.md` §4), the document API (`llm_and_d4rt_tools.md` §5),
> search (`llm_and_d4rt_tools.md` §6), the file facade
> (`llm_and_d4rt_tools.md` §7), the tool surface (`llm_and_d4rt_tools.md` §8),
> memory (`llm_and_d4rt_tools.md` §9) and the agent system
> (`llm_and_d4rt_tools.md` §10 / `llm_and_d4rt_tools.md` §11).
> [`tom_specs_model/doc/llm_guidelines_specification.md`](../tom_specs_model/doc/llm_guidelines_specification.md)
> owns the prompt an agent is given for authoring scripts against this surface.
> This README is the catalogue of *what the package ships and how to link it*;
> those documents own *what the surface must be* and *why*.

TomSpecs scripting/engine plane — the pure-Dart D4rt scope host, search index,
tool surface, RAG memory and agent substrate behind the TomSpecs editor.

## Where this fits

**TomSpecs** is a method for building software from structured specification
documents: a project is written up as a set of typed documents — the
Specification Object Model, or SOM — and the code skeleton is generated from
them. Editing those documents is agent work as much as human work, so the
editor needs an agent that can *run code against the live document* rather than
only describe changes in prose. `tom_spec_engine` is that execution surface: a
sandboxed [D4rt](../../d4rt/tom_d4rt) host whose scripts see the open document,
a restricted slice of the file system, and a recall-only view of memory — and
nothing else.

It exists as its own package because the alternative is putting an interpreter,
a search index, a vector store and an agent substrate inside a Flutter app,
where none of them can be exercised headless. Factored out, the whole plane runs
under `dart test` and behind a CLI, and the editor links it **in-process**
rather than talking to a server. So it sits between the generated Dart SOM
runtime below it ([`tom_som_dart_runtime`](../tom_som_dart_runtime),
[`tom_som_dart_v0`](../tom_som_dart_v0)) and the editor above it
([`tom_forge/tom_specs_editor`](../../../tom_forge/tom_specs_editor)), with the
embeddable Tom Brain packages supplying profiles, sessions and named memory.

## Overview

The engine is built around one idea: **a script never gets ambient authority.**
Everything a script can reach is a *scope* — a named, immutable set of bridged
D4rt libraries, injected globals and permission grants — and a run is
parameterised by the scopes it was given. There are three base scopes:

- **`spec`** binds the live document. Its `SpecApi` reads and edits through the
  same `SpecController` port the editor's own tools use, so a script edit shares
  the change log and the undo stack with a button press. It also carries the
  search facade.
- **`files`** bridges a *facade*, never raw `dcli` or `dart:io`: read anywhere,
  write only under `agent/scratchpad`. Because the raw libraries are not
  bridged, a write outside the whitelist is not a rejected call — it is an
  unresolvable one.
- **`memory`** injects a single read-only `memory` global over fused recall. It
  grants no permission, so a sandboxed script can recall but has no mutation
  path into the store at all.

Above the scopes sit two consumers. The **tool surface** (`script_*`, `doc_*`,
`file_*`, `mem_*`) is what an LLM actually calls; each tool returns a typed
result with a compact `toJson`, so a tool answer costs a bounded number of
tokens whatever the document's size. The **agent substrate** is the pluggable
model port — direct, or through Tom Brain — with a per-application
`AgentContext` binding guidelines, toolset and scope profile together under the
invariant *toolset ⊆ scopes*, enforced at construction.

Retrieval is two-tier and deliberately cheap to refresh. The structural/lexical
index (BM25/FTS plus facets) is rebuilt incrementally on every edit with **no
LLM call**; the vector tier over Tom Brain named memory catches up behind it,
and recall fuses both.

## Installation

`tom_spec_engine` is `publish_to: none` — it is consumed by path from within
this workspace, not from pub.dev:

```yaml
dependencies:
  tom_spec_engine:
    path: ../tom_spec_engine
```

Then pick the door you need. There are two, and the choice is load-bearing:

```dart
// Flutter hosts (the editor): scripting only — no sqlite3 FFI in the compile.
import 'package:tom_spec_engine/scripting.dart';

// Headless hosts (CLI, tests): the full surface, memory plane included.
import 'package:tom_spec_engine/tom_spec_engine.dart';
```

`scripting.dart` re-exports the scope registry, the `spec` and `files` scopes,
and the memory-free tools (`DocTools`, `FileTools`, `ScriptTools`). Everything
reachable from it depends only on `tom_d4rt` and `tom_som_dart_runtime`, both
already on the editor's resolved graph. The full barrel adds the memory plane,
which pulls `tom_brain_memory` — sqlite3 FFI and `vec0`, a server-only surface.

## Features

### The three base scopes

| Scope | Grants | Withholds |
| --- | --- | --- |
| `spec` | The document API bound to the live controller, plus structural/lexical search over it. | Nothing about the file system or memory. |
| `files` | A `SpecFileFacade` — read anywhere, write under `agent/scratchpad`. | Raw `dcli` and `dart:io` are not bridged at all. |
| `memory` | One injected `memory` global over fused recall. | No permission grant, therefore no mutation path. |

### The tool surface

| Family | Tools | Backed by |
| --- | --- | --- |
| `script_*` | Author, validate and run a named D4rt script under granted scopes. | `ScriptTools` + `FileScriptStore` |
| `doc_*` | Search, reflect and add nodes over the live document. | `DocTools` over a `SpecController` |
| `file_*` | The audited read/write/find surface. | `FileTools` over `SpecFileFacade` |
| `mem_*` | Remember, recall, refresh. | `MemoryTools` (full barrel only) |

### The agent substrate

| Mode | Class | What it is |
| --- | --- | --- |
| a — direct | `DirectAgentSubstrate` | A model call with no session plane behind it. |
| b — Tom Brain (default) | `BrainAgentSubstrate` | Profiles, named sessions and named memory through the embeddable Tom Brain. |
| multi-turn | `ConversationalAgentSubstrate` | Composes on either mode through an injected driver port. |

## Quick start

Run a D4rt script against an open document, with nothing but the `spec` scope:

```dart
import 'package:tom_spec_engine/scripting.dart';

Future<void> main() async {
  final registry = ScopeRegistry()..register(specScope(controller));
  final tools = ScriptTools(registry: registry, store: FileScriptStore(root));

  final run = await tools.run(
    scopes: const ['spec'],
    source: '''
      String main() => spec.content('D00.OV') ?? '(empty)';
    ''',
  );

  print(run.ok);      // true
  print(run.result);  // the section's content, read from the live document
}
```

Adding `'files'` to `scopes` would let the same script write a report under
`agent/scratchpad`; leaving it out means `File` is not a name the script can
resolve.

## Usage

### Registering a scope

```dart
final registry = ScopeRegistry()
  ..register(specScope(controller))
  ..register(filesScope(SpecFileFacade(root: projectRoot)));
```

A `ScriptScope` is immutable once registered. Changing what a script may reach
means registering a different scope, not mutating one — which is why a scope
name is enough to describe a run's authority.

### Searching without an LLM

```dart
final index = StructuralLexicalIndex()..rebuild(projections);

for (final hit in index.search(const IndexQuery(text: 'retention', limit: 20))) {
  print('${hit.path}  ${hit.score.toStringAsFixed(3)}');
}
```

`IndexQuery` mixes free text with structural facets — node kind, model class,
`@SectionId` prefix, `@MapsTo`, `@DetailedIn`, value-presence state — so "every
unfilled requirement section" is a query, not a scan. `IndexUpdateStats` reports
what an incremental refresh touched, so a caller can tell a cheap edit from an
expensive one.

### Recalling from memory

```dart
final recall = SpecRecall(index: index, vectorRecall: vectors, graph: graph);
final result = await recall.recall(
  SpecRecallQuery(text: 'how are order lines amended?', k: 8),
);
```

Recall runs each tier separately and fuses the ranked lists by weighted RRF,
optionally reordering by MMR for diversity. A hit carries the section path, so
it is addressable in the document rather than being a loose snippet — and an
empty vector result degrades to tier 1 instead of failing.

## Architecture

```
tom_spec_engine
├── lib/scripting.dart          the Flutter-safe door — no memory plane
├── lib/tom_spec_engine.dart    the full door — memory plane included
└── lib/src/
    ├── scope/     ScriptScope · ScopeRegistry · SpecController · SpecApi
    │              SpecFileFacade · SpecSearchApi · MemoryApi
    ├── index/     StructuralLexicalIndex — BM25/FTS + facets, incremental
    ├── tools/     ScriptTools · DocTools · FileTools · MemoryTools
    ├── memory/    SpecMemory · SpecRagGraph · SpecRecall · embedder + indexer
    ├── agent/     AgentSubstrate (direct | brain | conversational) · AgentContext
    └── bridges/   generated D4rt bridges over the two SOM packages

   editor ──links in-process──▶ scripting.dart ──▶ SpecController (port)
                                     │                      ▲
                                     ▼                      │ implemented by the editor
                              tom_d4rt sandbox
```

| Type | Responsibility |
| --- | --- |
| `ScriptScope` / `ScopeRegistry` | A named, immutable bundle of bridged libraries, globals and permission grants; the registry is the only place a run's authority is assembled. |
| `SpecController` | The abstract port onto the live document. The engine never owns the document — the host does, which is what makes a script edit and a UI edit share one undo stack. |
| `SpecApi` / `SpecModelApi` / `SpecSearchApi` | The script-facing document surface: values, model reflection, and search. |
| `SpecFileFacade` | Read-anywhere / write-whitelist file access, audited. The `files` scope bridges this and nothing lower. |
| `StructuralLexicalIndex` | Zero-LLM structural and lexical retrieval, refreshed incrementally per edit. |
| `DocTools` / `FileTools` / `ScriptTools` / `MemoryTools` | The engine logic behind the MCP tools; each returns a typed result with a compact `toJson`. |
| `SpecMemory` / `SpecRagGraph` / `SpecRecall` | Section-level RAG nodes in Tom Brain named memory, and the fused two-tier recall over them. |
| `AgentSubstrate` (+ three implementations) | The pluggable model port — direct, Tom Brain, or multi-turn conversational over either. |
| `AgentContext` / `AgentContextRegistry` | The per-application `{guidelines, toolset, scope profile}` triple, with *toolset ⊆ scopes* enforced at construction, swapped as one unit. |

### The D4rt bridges live here

The SOM bridges are generated in **this** package rather than in the lean
pure-data `tom_som_dart_runtime` / `tom_som_dart_v0`: the scripting plane
already depends on `tom_d4rt`, so it owns the binding surface and those two stay
free of it. `tool/regenerate_bridges.dart` drives `tom_d4rt_generator` from the
`d4rtgen:` block in `buildkit.yaml`.

Staleness is caught mechanically rather than remembered. `tool/som_surface.dart`
fingerprints the two SOM packages' **public surface**, a successful regeneration
writes `tool/som_surface.stamp.json`, and `test/som_bridge_freshness_test.dart`
recomputes the fingerprint in the default `dart test` run. That catches
*additive* staleness too — SOM gaining a class or member while the existing
bridge still compiles — which a build error never would.
[`_copilot_guidelines/bridge_regeneration.md`](_copilot_guidelines/bridge_regeneration.md)
states when to re-run it.

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

**The engine does not depend on the default, and does not own the fix.** Both
the repair (`SqliteHostLibrary`, which points `package:sqlite3` at a capable
`libsqlite3` through the public `open.overrideFor` seam, honouring
`$TOM_SQLITE3_LIB` first and Homebrew's prefixes on macOS) and the gate
(`VectorRuntimeProbe`, which runs the real load once rather than checking that
a file exists) live in
[`tom_brain_memory`](../../../tom_assistant/tom_brain_memory) — the package that
owns the store and therefore the precondition. Its README section **"Vector
runtime precondition"** carries the search order, the rule that keeps the repair
conditional, and the ordering hazard.

`test/support/vector_runtime.dart` is nothing but the engine-side name for that
probe. On a macOS box with `brew install sqlite` the four store-touching suites
(`spec_memory`, `spec_rag_store`, `spec_recall_store`, `spec_brain_envelope`)
run the vector tier **for real** under a bare `dart test`; on a host that still
cannot register `vec0` they report as **skipped with the reason stated** rather
than as a red suite.

## Ecosystem

```
   tom_specs_model  ──generated by──▶  tom_specs_clitool
          │                                   │ emits
          ▼                                   ▼
   tom_som_dart_runtime  +  tom_som_dart_v0   (the SOM this plane exposes)
          │                        │
          └──────────┬─────────────┘
                     ▼
              tom_spec_engine   ◀── tom_d4rt · tom_d4rt_dcli   (the sandbox)
                     │          ◀── tom_brain_{shared,memory,substrate}
                     │
        ┌────────────┴─────────────┐
        ▼                          ▼
  scripting.dart              tom_spec_engine.dart
  linked in-process by        headless hosts: CLI, tests,
  tom_forge/tom_specs_editor  the full memory + agent plane
```

## Further documentation

**TomSpecs subject matter** — the authorities this package implements:

| Document | Authority for |
|----------|---------------|
| [index.md](../tom_specs_model/doc/index.md) | The catalogue of the whole TomSpecs document set, and the `§` citation convention used throughout it |
| [llm_and_d4rt_tools.md](../tom_specs_model/doc/llm_and_d4rt_tools.md) | Every surface in this package: the scope model, the document API, search, the file facade, the tool surface, memory, the agent substrate and the agent context |
| [llm_guidelines_specification.md](../tom_specs_model/doc/llm_guidelines_specification.md) | The context prompt the in-editor agent is given for authoring D4rt scripts against this surface |
| [som_multiplatform_spec_model.md](../tom_specs_model/doc/som_multiplatform_spec_model.md) | The document model the `spec` scope exposes — its generated/runtime classes, serialization and validator |
| [tom_specs_editor_specification.md](../tom_specs_model/doc/tom_specs_editor_specification.md) | The app that links this engine in-process, and where the `SpecController` port is implemented |

**This package** — its own guides:

| Guide | Covers |
|-------|--------|
| [_copilot_guidelines/bridge_regeneration.md](_copilot_guidelines/bridge_regeneration.md) | When and how to re-run `tool/regenerate_bridges.dart`, and what the freshness stamp holds |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_som_dart_runtime](../tom_som_dart_runtime) | The generic SOM runtime — document memory model, reflection, validator |
| [tom_som_dart_v0](../tom_som_dart_v0) | The generated typed Dart facade over it |
| [tom_specs_clitool](../tom_specs_clitool) | The generator that produces both, plus the model validator and citation gates |
| [tom_d4rt](../../d4rt/tom_d4rt) | The sandboxed Dart interpreter every script runs on |
| [tom_brain_memory](../../../tom_assistant/tom_brain_memory) | The store behind the memory plane — and the owner of the vector-runtime precondition |

## Status

Version **0.0.1**, `publish_to: none` — consumed by path within this workspace.

**221 tests passing**, plus 16 vector-store tests that skip — with the reason
stated — on a host where `vec0` cannot register (see "Vector runtime
precondition" above). Run them with `dart test` or `testkit :test`.

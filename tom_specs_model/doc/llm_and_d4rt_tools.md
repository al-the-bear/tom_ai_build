# D4rt Scripting & LLM Tooling for the TomSpecs Editor

**Quest:** tom_specs
**Status:** The `tom_spec_engine` plane — a D4rt host with `spec` / `files` /
`memory` scopes plus an embeddable Tom Brain memory — links **in-process** into the
Flutter editor (`tom_forge/tom_specs_editor`); both sit on `analyzer ^10`. The
`spec` scope exposes the controller-bound editing facade (`SpecApi`) alongside
read-only `model` (reflection) and `search` (query/grep) globals; `files` and
`memory` expose the audited file facade and the fused two-tier recall.
**Scope:** Give the in-editor LLM agent a complete, safe, scriptable surface over
a TomSpecs document: D4rt authoring/execution tools, a fine-grained document +
object-model scripting API (routed through the same controller as the MCP tools,
so every change lands in the one change log), grep-like search with iteration, a
restricted `dcli` file facade, an in-memory read/write/search tool set, and a
fast RAG memory that re-indexes after every prompt without extra LLM calls.

**Related specs:**
[`tom_specs_editor_specification.md`](tom_specs_editor_specification.md) (the
editor; §8 tool surface, §7 agent integration),
[`som_multiplatform_spec_model.md`](som_multiplatform_spec_model.md) (the
`tom_som` document access API this scripting layer exposes),
[`llm_guidelines_specification.md`](llm_guidelines_specification.md) (the agent
guidelines this layer briefs the model with, §11).

---

## 1. Goals — the eleven requirements

| # | Requirement | Where addressed |
| --- | --- | --- |
| a | LLM tools to **author** D4rt scripts | §8.1 |
| b | LLM tools to **run** D4rt scripts and capture their output | §8.1 |
| c | Scripting API = **complete document access** via the same methods the tools use (one change log), fine-grained traversal of the **document and the object model**, node creation **limited to what the object model allows** — i.e. the full `tom_som` Dart document API (`som_multiplatform_spec_model.md`) made available to D4rt | §5 |
| d | **grep-like** access — find sections by text / type / id and **iterate** over the results | §6 |
| e | An **`llm_guidelines_specification.md`** for the agent: scripting + the situation of being a TomSpecs editor agent; per-application context selects guidelines, tools, and scripting APIs | §11 |
| f | **File access via `dcli`** through a **facade** that limits it: read-only anywhere, write only to a few whitelisted directories in the spec workspace | §7 |
| g | A **complete tool set** for reading, writing, and searching the specification in memory | §8.2 |
| h | A **memory system** that parses the spec into **vector + semantic** form — reuse `tom_brain_memory` if reasonable | §9, §10 |
| i | A **complete agent system** — support **both** a **direct Agent SDK** path (augmented with memory + a complex agent procedure) **and** an **Agent-SDK-through-`tom_brain`** path; free-time procedures excluded (configurable) | §10 |
| j | **Multiple D4rt scripting scopes** within a single application | §4 |
| k | A detailed spec of **how the document is stored for RAG** (on top of the §6 pattern/text search), refreshed after **every** prompt to stay current, **without** extra LLM calls (frequent → must be fast) | §9 |

---

## 2. Starting point — what already exists (and the reuse verdict)

| Asset | What it gives us | Reuse verdict |
| --- | --- | --- |
| `tom_specs_editor` `SpecDocument` + `SpecDocumentController` (`tom_forge/tom_specs_editor/lib/src/document/`) | The path-keyed in-memory document and the **single mutation authority** that the 13 MCP tools already route through; emits the change log + undo snapshots. | **Authority for all mutation.** D4rt and every new tool mutate *only* through this controller (req c). |
| `SpecModel` / `spec_model.json` (`…/structure/spec_model.dart`) | The resolved object-model graph (classes, fields, kinds, `@SectionId`, `@MapsTo`/`@DetailedIn`). | The **meta-model** for object-model traversal and for constraining node creation (req c). |
| `tom_som` plan (`som_multiplatform_spec_model*.md`) | A pure-Dart **generic runtime** (`tom_som_dart_runtime`: memory representation + reflection classes) + typed **`tom_som_dart_v0`** facade. The "complete Dart document access API" req c names. | **The API D4rt exposes.** This spec adds three obligations to the `tom_som` spec (§13.1): D4rt-bridgeability, a query/grep facility, and constrained node creation. |
| `tom_d4rt` (`tom_ai/d4rt/tom_d4rt`) | `D4rt.execute(source)` (auto-awaits `main()`), per-instance bridged-library registry, a filesystem/process **permission system**, `tom_d4rt_generator` auto-bridging from annotations. | **The interpreter + scoping mechanism.** Scopes = distinct bridged-library sets + grants (req j). |
| `tom_d4rt_dcli` (`tom_ai/d4rt/tom_d4rt_dcli`) | `dcli` bridged into D4rt (read/write/find/copy/move/delete). | **Wrapped, never exposed raw.** A facade gates it to read-anywhere / write-whitelist (req f). |
| `tom_brain_memory` (`tom_assistant/tom_brain_memory`) | Property-graph + vector store; `recall()` over **BM25 / Vector / Symbolic / GraphWalk** with RRF fusion + MMR; per-model vector tables; `Scope` namespaces; SQLite persistence. **Now embeddable** — bundles the `vec0` binary automatically, exposes an embedding API, and provides **profiles / named sessions / named memory**. | **Design *and* package reused.** Tom Brain is now Flutter-embeddable: no server-only packaging and no separate `vec0` provisioning. The engine plane runs `SqliteTomBrainMemory` **in-process** with the bundled `vec0` (profile = document), behind the engine's thin `MemoryScope`/`SpecMemory` façade (§9, §10). Embedding stays injectable (a `SpecEmbedder`) so the per-prompt path pays no chat-model cost. |
| `tom_brain_procedure` (`tom_assistant/tom_brain_procedure`) | `ProcedureEngine` running sandboxed D4rt over `BridgeLibraries`; `FreeTimeScheduler` (optional). | **Host/bridge/scope pattern reused** for the multi-scope engine and the complex agent procedure (mode a); free-time **off** (req i). |
| `tom_specs_editor` agent integration (§7 of the editor spec) | Claude Code via the **Agent SDK over the VS Code bridge**, provider abstraction in `tom_core_agentic`, MCP tools via reverse-RPC. | **Conversational substrate for both agent modes.** Mode (a) drives it directly (+ memory + procedure); mode (b) routes it through `tom_brain` (§10). |

**Analyzer alignment.** `tom_d4rt` (`^1.10.1`) and `tom_dart_editor` (the embedded
code editor the document fields use) both pin **`analyzer: ^10.0.0`**, so a single
Flutter app resolves both. In-process D4rt is therefore the path (§3, §12): the
engine plane links directly into the Flutter app.

---

## 3. Architecture overview

Three planes, one mutation authority:

1. **Editor plane (Flutter, `tom_specs_editor`).** Owns the live document
   (`SpecDocumentController` over the `tom_som` memory representation), the UI,
   the change log + undo, and the Agent-SDK chat loop. **All document mutation
   is final here** — this is the one change log (req c).
2. **Scripting/engine plane (pure Dart, `tom_spec_engine`).** The D4rt host, the
   scope/bridge registry, the `dcli` facade, the search index, and the RAG
   memory. Factored as its **own pure-Dart project** so it stays reusable
   headless, but — now that `tom_d4rt` is on `analyzer ^10` (§2) — it links
   **in-process** into the Flutter editor with no version conflict.
3. **Agent plane.** Claude Code over the VS Code bridge. New MCP tools (§8) let
   the agent author/run scripts, search, query memory, and read files. Because
   the engine is in-process, mutating tools and mutating script calls reach the
   editor plane's `SpecDocumentController` **directly** (no reverse-RPC hop), so
   every change lands in the one change log.

### 3.1 Where D4rt runs — in-process

- **In-process.** With `tom_d4rt` on `analyzer ^10` (matching `tom_dart_editor`),
  the engine plane links directly into the Flutter app; D4rt calls the controller
  in-process and shares the change log, undo, and live `tom_som` objects with
  **zero IPC**. This also enables live d4rt-flutter rendering (editor §13).
- **Engine factoring.** `tom_spec_engine` is a separate pure-Dart project (the
  `tom_brain_procedure` host pattern) so the host, scopes, file facade, and memory
  are usable headless (CLI, tests, server). The editor **consumes it in-process**.
  The contract below is the seam should a future plane ever require an
  out-of-process transport.

The **contract is identical** regardless of how the engine is hosted (same
scripting API, same tool surface, same change log); code is written against the
contract, with in-process as the binding.

---

## 4. D4rt scripting scopes (req j)

A **scope** is a *named, immutable set of bridged D4rt libraries plus injected
globals plus permission grants*. The interpreter is given exactly the scope's
libraries; a script may import only what the scope exposes. This is the
`tom_d4rt` per-instance registry + permission model (§2), packaged as named
presets in a **`ScopeRegistry`**.

Scopes are composable: a run is granted **one or more** scopes, and the union of
their libraries/globals/grants forms the run environment. The three base scopes:

| Scope | Bridged libraries / globals | Permissions | Purpose |
| --- | --- | --- | --- |
| **`spec`** | the `tom_som` document API — generic runtime + reflection + typed `tom_som_dart_v0` (§5), plus the search facility (§6), bound to the live controller | document read+write (mediated) | Traverse/query/edit the spec (req c, d). |
| **`files`** | the **restricted `dcli` facade** (§7) | filesystem **read = any**, **write = whitelist** | Read arbitrary files; write only to whitelisted dirs (req f). |
| **`memory`** | the RAG recall API (§9), **read-only** | none beyond memory | Semantic/lexical recall over the indexed spec (req g, h). |

**Two-dimensional context (req e + j).**

- **Per application** (DocSpecs / CodeSpecs / Implementation): the active Forge
  application selects a **scope profile** — which scopes exist, which tools are
  registered, and which `llm_guidelines_specification.md` is loaded (§11). The
  DocSpecs app enables all three base scopes; the other apps will define their
  own profiles later.
- **Within an application**: distinct scopes coexist (the three above). A given
  script run names the scopes it needs; the agent's *author/run* tools (§8.1)
  default to `spec` and may opt into `files` / `memory`.

`ScopeRegistry` lives in the engine plane; scope definitions are declarative so a
new application profile is data, not code.

---

## 5. The document scripting API (req c)

The `spec` scope exposes the **complete `tom_som` Dart document API** — the same
one `som_multiplatform_spec_model.md` specifies — bridged into D4rt via
`tom_d4rt_generator` (annotation-driven, §13.1). It has three layers, all bound
to the **live `SpecDocumentController`**, so a script mutation is identical to an
MCP-tool mutation and produces the **same change-log entry + undo snapshot**.

1. **Generic / memory-representation layer** — read/write any section by its
   globally-unique path; list add/remove; form-field get/set. (The factored
   `SpecDocument` API: `content(path)`, `setContent`, `formField`,
   `setFormField`, `listItems`, `addListItem`, `removeListItem`.)
2. **Reflection / meta-model layer** — enumerate classes, fields, kinds,
   `@SectionId`/`@SectionIdPattern`, `@MapsTo`/`@DetailedIn`, doc-comments, and
   **all annotation arguments** (the lossless meta-model `tom_som` §3.1
   guarantees). Lets a script discover *what may exist where* before editing.
3. **Typed layer** — the generated `tom_som_dart_v0` editing facade (typed
   fields/lists/forms/enums) for ergonomic, completion-friendly scripts; it
   mutates the same memory representation.

**Fine-grained traversal of document *and* object model (req c).** A script can
walk the live instance tree (what *is* set) and, in parallel, the object-model
graph (what *could* be set) — the reflection layer answers "which child
sections, of which types, are legal under this node".

**Constrained node creation (req c).** All node creation goes through a
**meta-model-validated** add API: a script may add only children/list-items/forms
the object model permits for the parent (kind, allowed section-id pattern,
cardinality). Illegal additions raise a clear scripting error rather than
corrupting the tree. The check reuses the §8.6 validator's structural rules
(exported by `tom_som`, see §13.1).

**One change log (req c).** Because every layer ends at the controller, scripts,
MCP tools, and direct UI edits are indistinguishable to the change log and undo
stack — the requirement that "changes go into the same change log" is satisfied
by construction, not by a parallel path.

---

## 6. Search & iteration (req d, g)

A **grep-like query facility** over the live document, available both as a D4rt
API (in the `spec` scope) and as MCP tools (§8.2). It is **lexical/structural**
— no embeddings, no model calls — so it is exact, fast, and always current.

**Query dimensions** (composable, AND-combined):

- **text** — substring or **regex** over content + form-field values (+ optional
  case-insensitivity); also over section headlines/doc-comments.
- **type / kind** — section kind (`content`/`form`/`list`/`section`/`complex`/
  `scalar`/`enum`) or model class name.
- **id / path** — exact section id, `@SectionId` prefix, or path glob; also
  `@MapsTo`/`@DetailedIn` target.
- **state** — empty / non-empty, reviewed / unreviewed, review scope.

**Result + iteration.** A query returns a **cursor** of matches (`{path, kind,
classId, headline, snippet, matchSpans}`), iterable lazily so the agent can step
through large result sets (`next()`, `take(n)`, `count`) and act on each — e.g.
read, then mutate via §5. Cursors are stable against concurrent edits by
re-validating each path on `next()`.

This facility is backed by the **structural/lexical index** of §9 (tier 1), which
is rebuilt cheaply after each edit/prompt with zero LLM cost.

The facility lives in `tom_som_dart_runtime` as `SpecQuery` +
`SpecQueryEngine` + `SpecQueryCursor` (the cursor carries the `next()` / `take(n)`
/ `count` surface above, returning `SpecQueryMatch` whose JSON is exactly the
shape named here). It is reached two ways: the **`spec` D4rt scope** exposes it
through the in-script `search` facade (queries built by the shared
`specQueryFromArgs` coercer), and the **`doc_search` / `doc_search_iterate`** MCP
tools (§8.2) page over the same cursor — `doc_search` opens a cursor and returns
the first page, `doc_search_iterate(cursorId, {pageSize})` advances it.

---

## 7. File access facade (req f)

The `files` scope exposes a **`SpecFileFacade`** — a thin, audited wrapper over
`tom_d4rt_dcli`, never the raw `dcli` surface. Policy:

- **Read = anywhere.** `readText`, `readLines`, `head`/`tail`, `exists`, `stat`,
  and **`find`/glob** are permitted on **any** path (the agent may explore
  arbitrary files read-only).
- **Write = whitelist only.** `writeText`, `append`, `createDir`, `copy`,
  `move`, `delete` are permitted **only** under a small set of **whitelisted
  directories inside the spec workspace**. The **default writable directory is
  `agent/scratchpad`** (plus the spec's own asset dirs where an application opts
  in; configurable). All other agent artefacts — authored scripts, guidelines,
  the memory index, logs — live under **other `agent/` subdirectories**
  (`agent/scripts/`, `agent/memory/`, `agent/guidelines/`, …) so the agent never
  pollutes the project directory and free-form scratch space is separated from
  curated, reviewable artefacts. Any write outside the whitelist raises a
  `FilePermissionError` *before* touching disk.
- **Enforcement is two-layered**: (1) the facade validates and canonicalises
  every path (resolving symlinks / `..` to block escapes) and (2) the D4rt
  **permission system** is granted `read=any` + `write=<whitelist>` as a
  defence-in-depth backstop. Raw `dcli` write/delete functions are simply **not
  bridged** into the scope.
- The whitelist is part of the **application scope profile** (§4), so different
  applications can widen/narrow writable roots.

---

## 8. LLM tool surface (req a, b, g)

New in-process `SdkMcpTool`s, registered by the editor's `AgentToolsModule`
(extending the existing §8 set in the editor spec). All mutating tools route
through the one controller (req c); all results are compact JSON.

**Four MCP servers.** `AgentToolsModule.servers` folds **four**
in-process servers into the agent send config, namespaced so the surfaces stay
clean:

- **`tomspecs`** (`SpecAgentTools`) — the editor's bespoke **13** Layer-A/B/C
  navigation + mutation tools (the §8.2 "existing" set, listed below).
- **`tomspecs-engine`** (`SpecEngineTools`) — the reusable engine toolsets
  (`DocTools` / `FileTools` / `ScriptTools` / `MemoryTools`) from
  `tom_spec_engine`: the §8.1 script tools and the §8.2 `doc_search` / `doc_reflect`
  / `doc_add_node` / `file_*` / `mem_*` tools (the `mem_*` pair is registered
  **only** when the memory plane is wired).
- **`tomspecs-brain`** (`SpecBrainTools`, mode b) — the live agent runtime
  (`agent_run` / `agent_trail`; §10).
- **`tomspecs-converse`** (`SpecConversationalTools`, mode a) — the multi-turn
  conversational runtime (`converse_run` / `converse_trail`; §10).

The §8.1 / §8.2 tool lists below name the tools; the server each belongs to is
called out inline.

### 8.1 Script authoring & execution (req a, b)

All five live in the **`tomspecs-engine`** server (over `ScriptTools`); the
targeted-scopes argument is `scopes`, defaulting to `['spec']`:

- **`script_author(name, source, {scopes})`** — store/replace a named D4rt
  script in the workspace `agent/scripts/` dir as a `*.d4rt.dart` file; records
  the scopes it targets. Returns the stored header.
- **`script_validate({source|name, scopes, args})`** — parse / declaration-resolve
  the script against the granted scope's bridged surface **without** running it;
  also type-checks the entrypoint (confirms a `main()` is declared and returns its
  argument contract, and checks any supplied `args` against it). Returns
  `{ok, diagnostics, entrypoint}` so the agent can iterate before execution.
- **`script_run({source|name, scopes, args})`** — execute via the engine plane
  under the named scopes; **captures stdout, the `main()` return value
  (auto-awaited, with `args` forwarded), and any error/stack**, returning them to
  the agent. Mutations performed during the run appear in the change log exactly
  as tool mutations do.
- **`script_list()` / `script_get(name)`** — enumerate / fetch stored scripts.

Authored scripts are first-class workspace files under the curated
**`agent/scripts/`** directory (an `agent/` subdir written by the `script_author`
tool, distinct from the `files`-scope facade's `agent/scratchpad` write
whitelist), so they are reviewable, re-runnable, and diffable without cluttering
the project root.

### 8.2 Read / write / search the spec in memory (req g)

The **`tomspecs`** server carries the editor's existing Layer-A/B/C + mutation
tools (the 13); the **`tomspecs-engine`** server adds the search / reflect /
add-node / memory / file tools. Named as shipped, grouped by server:

- **`tomspecs` — Layer A (model schema):** `model_list_documents`,
  `model_get_section`, `model_children`, `model_search`.
- **`tomspecs` — Layer B (live structure):** `doc_outline`, `doc_section_meta`.
- **`tomspecs` — Layer C reads:** `doc_get_content`, `doc_get_form_field`.
- **`tomspecs` — mutations:** `doc_set_content`, `doc_set_form_field`,
  `doc_add_list_item`, `doc_remove_list_item`, `doc_set_review`.
- **`tomspecs-engine` — Search:** `doc_search(query)` and
  `doc_search_iterate(cursorId, {pageSize})` exposing the §6 facility
  (text/regex/type/id/state, paged edit-stable cursor).
- **`tomspecs-engine` — Reflect:** `doc_reflect(path)` returning the meta-model
  facts (allowed children/types/annotations) for a node.
- **`tomspecs-engine` — Add:** `doc_add_node(parentPath, childSegment, {itemId,
  content, fields})` performing the **meta-model-validated** creation of §5,
  optionally populating the new node in the same call.
- **`tomspecs-engine` — Memory recall:** `mem_recall(query, {mode, k})` and
  `mem_refresh()` exposing §9 (semantic/lexical recall; manual re-index) —
  registered **only** when the memory plane is wired.
- **`tomspecs-engine` — Files:** `file_read(path)`, `file_find(glob, {dir,
  includeAssets})`, `file_write(path, content)` (whitelist-checked, §7).

### 8.3 Tool vs script — when to use which

The **MCP tools** are the *coarse, always-available* surface (single reads,
single edits, one search). **D4rt scripting** is the *fine-grained, composable*
surface for multi-step traversals, bulk edits gated by the object model, and
custom queries — authored, validated, then run, with full output captured. Both
end at the same controller; scripting is strictly more expressive, never a
second source of truth.

---

## 9. Memory & RAG storage (req h, k)

The memory makes the spec searchable two ways: the exact **lexical/structural**
search of §6 **and** **semantic RAG**. The design reuses `tom_brain_memory`'s
*model* (nodes + edges + multi-mode recall) **and** its now-embeddable package
(bundled `vec0`), with storage running **in-process** in the engine plane
(§9.3, §10).

### 9.1 How the document is stored for RAG (req k)

- **Chunk = section.** The natural retrieval unit is the **section** (one
  globally-unique section-id path = one node). Section-level chunking matches the
  object model exactly and keeps chunks semantically coherent and bounded.
- **Node payload per section**: the rendered text (content or concatenated form
  fields), plus **structural metadata** — section id, path, class/kind,
  headline/doc-comment, parent path, and `@MapsTo`/`@DetailedIn` targets.
- **Edges** mirror the tree (parent↔child) and the projection links
  (`@MapsTo`/`@DetailedIn`), so GraphWalk recall can expand from a hit to its
  context (parent section, mapped targets).
- **Scope = the document** (a `tom_brain_memory` `Scope`), so multiple open
  specs index independently and never cross-contaminate.

### 9.2 Two-tier index — fast refresh without LLM calls (req k)

The hard constraint: re-index after **every** prompt, frequently, **without**
extra LLM calls. The index is split into two tiers:

- **Tier 1 — structural / lexical (the per-prompt refresh).** An inverted text
  index (BM25/FTS) + structural facets (id, kind, mapsTo, state) built **directly
  from the object model with zero model calls**. This is what §6 search uses and
  what is rebuilt — incrementally, only over changed sections — **after every
  prompt**. It is the "always current" guarantee and is cheap.
- **Tier 2 — vector / semantic (incremental, out of band).** Embeddings are
  computed **only for changed sections**, **debounced/async**, by a **local
  embedding model** (e.g. a local Ollama embedder via `tom_brain_memory`'s
  `EmbeddingService`), **never** the conversational chat model and **never** a
  full re-embed. So the frequent per-prompt path pays **no** LLM cost; semantic
  vectors catch up shortly after, incrementally. (Decision D-k records that
  "no extra LLM calls" binds the *per-prompt* path; local incremental embedding
  is permitted and is not a chat-model call.)

**Recall** then fuses tiers: `mem_recall` runs BM25 (tier 1) + Vector (tier 2,
when warm) + Symbolic (facets) + optional GraphWalk, combined by RRF and
diversified by MMR — exactly `tom_brain_memory`'s `recall()` contract. When tier
2 is still warming, recall degrades gracefully to tier 1 + symbolic (still
useful, still exact).

### 9.3 Reuse of `tom_brain_memory` (req h)

- **Reused — interfaces, recall model, *and* package.** `recall()` with the four
  modes + RRF/MMR and the per-model vector-table discipline, plus the embeddable
  `SqliteTomBrainMemory` itself. Tom Brain **bundles the `vec0` binary** and
  exposes an embedding API + **profiles / named sessions / named memory**, so the
  store runs in-process with no server-only packaging and no separate `vec0`
  provisioning.
- **Engine plane (`tom_spec_engine`, §10):** `lib/src/memory/` (`MemoryScope` +
  `SpecMemory` / `SpecDocumentMemory`) wraps the embeddable, **profile-isolated**
  `SqliteTomBrainMemory` with the bundled `vec0`. The memory partition is the
  **document** (→ a Tom Brain profile); `application` / `session` are carried as
  agent-plane addressing. Embedding is an injected `SpecEmbedder` — the
  provider-backed `SpecProviderEmbedder` (Ollama `nomic-embed-text`, 768 dims,
  L2-normalised) is the tier-2 warm path; the engine owns the `tom_brain_substrate`
  dependency and re-exports its embedding value types.
- **Storage and recall** both use `tom_brain_memory` in the engine plane. Tier-1
  (BM25/symbolic, the §6 structural/lexical index) satisfies the per-prompt refresh
  with **zero** model calls; tier-2 (`vec0` vectors) warms incrementally behind the
  injected embedder.
- **Editor consumption.** The editor binds the memory plane through the memory-only
  `package:tom_spec_engine/memory.dart` façade via a `SpecMemoryPlane` over the live
  `SpecDocumentController`: **tier 1** (lexical/structural) is always live; **tier
  2** (vectors) opens the embeddable store under `<workspaceRoot>/agent/memory` with
  the `vec0` binary from `tom_binaries/sqlite_vec`, **degrading to tier-1-only** when
  the binary is absent or the store cannot boot. The fused `SpecRecall` is exposed
  both as the read-only `memory` script scope and behind the `mem_recall` /
  `mem_refresh` MCP tools. The memory-free `scripting.dart` façade remains available
  for hosts that link only the editing/file/script surface.

---

## 10. Agent system (req i)

The engine supports **both** agent substrates behind one abstraction — a *direct
Agent SDK* mode and an *Agent-SDK-through-`tom_brain`* mode — both fed by the
shared `tom_brain` procedure + memory. The application selects the mode;
**mode (b) is the default** because it gives the per-application profile / named
session / named memory isolation (§11) for free, and **mode (a) is opt-in** for
the lightest single-application use.

The engine exposes a pluggable **`AgentSubstrate`** interface with two
implementations:

- **Mode (a) — direct Agent SDK.** The Agent SDK is used directly (Claude Code
  over the VS Code bridge, the editor's existing agent loop, provider abstraction
  in `tom_core_agentic`), **augmented with the RAG memory (§9)** for per-prompt
  recall and **driven by a complex agent procedure** — a `tom_brain_procedure`
  D4rt procedure that orchestrates the multi-step search → recall → edit → verify
  loop over the §8 tools. The conversational substrate is the Agent SDK; only the
  procedure host and memory are borrowed from `tom_brain`.
- **Mode (b) — Agent SDK through `tom_brain`.** The Agent SDK is consumed *via*
  `tom_brain` as the surrounding agent framework, so `tom_brain`'s procedure +
  memory + provider orchestration wrap the Agent-SDK call path. This is the
  fuller `tom_brain` adoption, offered alongside mode (a).

Common to both modes:

- **Shared substrate from `tom_brain`:** **(1)** the `tom_brain_procedure`
  **D4rt-host + bridge + scope engine** (basis for §4's `ScopeRegistry` and the
  complex agent procedure) and **(2)** `tom_brain_memory` (§9). Both are reached
  from the engine plane (`tom_spec_engine`).
- **Free-time / dream procedures are disabled** in both modes (already optional
  in `tom_brain` — `DreamConfig` absent / `FreeTimeScheduler` omitted) (req i).
- The `tom_brain` substrate runs **in-process**: Tom Brain is embeddable and
  bundles its own `vec0` binary (§9.3), so the engine plane (`tom_spec_engine`)
  hosts memory + procedure with no server-only packaging and no external `vec0`
  provisioning. The editor links the engine in-process (§2, §3); per-application /
  per-phase isolation uses Tom Brain's **profiles + named sessions + named memory**
  (the native AgentContext mechanism, §11).

The selectable `AgentSubstrate` (`buildAgentSubstrate` /
`defaultAgentSubstrateMode = AgentSubstrateMode.tomBrain`) is instantiated **inside
`tom_specs_editor`**, which holds the direct (in-process) database access needed to
keep the document data — specification, CodeSpecs, and Implementation — updated as
the agent edits. A `ConversationalAgentSubstrate` composes either base mode into a
`maxTurns`-bounded multi-turn loop for the live conversational (mode a) path.

---

## 11. Agent guidelines specification (req e)

The agent is briefed at runtime by an **`llm_guidelines_specification.md`** — the
source for the system/context prompt that tells the model *it is a TomSpecs
editor agent* and, above all, *how to create D4rt scripts for processing the
document*. This spec defines its **required structure**.

The `llm_guidelines_specification.md` beside this spec matches the shipped scripting
surface: it briefs the model that it is a TomSpecs editor agent and documents how
to author D4rt scripts against the object model. Its §6 worked examples run as
tests against the real `spec` / `files` / `memory` scope bindings, so the
guidelines and the implementation stay in agreement.

Required contents:

1. **Role & situation** — "you are editing a TomSpecs document through the
   object model; you never need the whole document in context; every change is
   logged and reviewable."
2. **Tool catalogue** — the §8 tools, when to prefer a tool vs a script.
3. **Scripting guide** — the D4rt dialect, the `spec`/`files`/`memory` scopes
   and what each exposes, the document API layers (§5), the search facility
   (§6), worked examples (find→iterate→edit; meta-model-validated add), and the
   `main()`-returns-result convention.
4. **Constraints** — node creation limited by the object model; file writes
   limited to the whitelist; no `${{…}}`-style JS placeholders; the change-log /
   undo semantics.
5. **Memory guide** — how to recall (§9), and that the index self-refreshes.

**Per-application context (req e).** Each Forge application owns its own
`llm_guidelines_specification.md` and scope profile (§4). **Selecting the
application** swaps the guidelines, the registered tools, and the available
scripting scopes — so the CodeSpecs and Implementation apps brief the agent
differently from the same shell. The mechanism is a per-application
**AgentContext** = `{guidelines doc, tool set, scope profile}`.

**Tom Brain mapping.** The three TomSpecs concepts map onto Tom Brain's native
isolation primitives one-to-one:

| TomSpecs concept | Tom Brain primitive | Engine carrier |
| --- | --- | --- |
| **Application** (DocSpecs / CodeSpecs / Implementation) | **profile** (prompt + tools + MCP surface + scope profile) | `AgentContext.application` → `profileName` |
| **Phase / task run** | **named session** | `MemoryScope.session` |
| **Open document** | **named memory** | `MemoryScope.document` |

So there is **one profile per application**, **one named session per
phase/task**, and **one named memory per open document** — switching application
swaps guidelines + tools + scopes + memory in one move. The three canonical
application profile names are fixed in the engine (`tomSpecsApplications`), and
`tomSpecsContextRegistry()` registers all three contexts —
`docSpecsAgentContext()`, `codeSpecsAgentContext()`, `implementationAgentContext()`.
Each carries the full four-group toolset and three base scopes, differentiated by
guidelines prompt and isolated profile/memory rather than by capability (the
`toolset ⊆ scopes` invariant bounds capability). The editor's `SpecAgentProfiles`
resolves an application's `AgentContext` into the live send config — guidelines
prompt, MCP surface, and scope profile bound to the running Tom Brain instance.

---

## 12. Project & dependency layout

| Project | Plane | Role |
| --- | --- | --- |
| `tom_specs_editor` (Flutter) | Editor (Flutter) | Owns the document/controller/change-log/undo + UI + Agent-SDK loop; registers the §8 tools; hosts the **in-process** engine. |
| **`tom_spec_engine`** (new, pure Dart, `tom_ai/ai_build`) | Engine | D4rt host + `ScopeRegistry` (§4) + `SpecFileFacade` (§7) + search index (§6) + RAG memory (§9, on `tom_brain_memory`) + the `AgentSubstrate` abstraction (§10). Built on the `tom_brain_procedure` host pattern; a standalone pure-Dart project (reusable headless) linked **in-process** by the editor. |
| `tom_som_dart_runtime` / `tom_som_dart_v0` | Shared (pure Dart) | The document API exposed to D4rt (§5); generated D4rt bridges (§13.1). |
| `tom_d4rt`, `tom_d4rt_dcli`, `tom_d4rt_generator` | Engine | Interpreter (`analyzer ^10`, `^1.10.1`), dcli source for the facade, bridge generation. |
| `tom_brain_memory`, `tom_brain_procedure` | Engine | Memory + procedure-host reuse (§9, §10), free-time off. |

The Flutter editor links `tom_spec_engine` **in-process** (§3); D4rt and the §8
tools call the `SpecDocumentController` directly, so the change log stays
authoritative in the editor plane with no IPC.

---

## 13. Cross-document relationships

### 13.1 What `som_multiplatform_spec_model.md` provides

The `tom_som` API satisfies three obligations this scripting layer depends on:

1. **D4rt-bridgeability.** The generic runtime, the reflection classes, and the
   typed `tom_som_<lang>_v0` (Dart first) are exposed as **D4rt bridged
   libraries**, generated via `tom_d4rt_generator`. The generated bridges live in
   the engine plane (`tom_spec_engine/lib/src/bridges/`), keeping the runtime/v0
   packages free of any `tom_d4rt` dependency.
2. **Query / grep facility.** The generic runtime provides the §6
   **lexical/structural query + cursor iteration** (find by text/regex, type,
   id/path, state) as part of its public API (`SpecQuery` / `SpecQueryEngine` /
   `SpecQueryCursor`), reused by both the editor's search tools and any consumer.
3. **Meta-model-constrained node creation.** The generic add-node API
   **validates against the meta-model** (allowed child kinds / section-id patterns
   / cardinality) using the §8.6 structural rules and rejects illegal additions.

### 13.2 Relationship to `tom_specs_editor_specification.md`

- The editor spec carries a "D4rt Scripting & In-Editor Agent Tooling" section
  pointing here, and its §8 tool surface covers the §8.1/§8.2 tools across the
  `tomspecs-engine` server (`script_author`/`script_validate`/`script_run`/
  `script_list`/`script_get`; `doc_search`/`doc_search_iterate`; `doc_reflect`;
  `doc_add_node`; `mem_recall`/`mem_refresh` when memory is wired;
  `file_read`/`file_find`/`file_write`), alongside the editor's `tomspecs` server
  (the 13 `model_*`/`doc_*` Layer-A/B/C + mutation tools) and the live-runtime
  `tomspecs-brain` (`agent_run`/`agent_trail`) and `tomspecs-converse`
  (`converse_run`/`converse_trail`) servers (§10).
- The editor spec's §7 carries the per-application **AgentContext** (guidelines +
  tools + scope profile) and the in-process engine-plane note.

---

## 14. Settled decisions

- **Hosting — in-process.** `tom_d4rt` (`^1.10.1`) and `tom_dart_editor` both sit
  on `analyzer ^10`, so the engine links directly into the Flutter editor; D4rt
  calls the controller in-process and shares the change log, undo, and live
  `tom_som` objects with zero IPC (§3).
- **Agent substrate — both modes, mode (b) default.** The engine exposes a
  selectable `AgentSubstrate`: mode (a) drives the Agent SDK directly (augmented
  with memory + a complex procedure); mode (b) wraps the Agent SDK through
  `tom_brain` for profile / session / memory isolation. `defaultAgentSubstrateMode
  = AgentSubstrateMode.tomBrain` (mode b); mode (a) is opt-in. The substrate is
  instantiated inside `tom_specs_editor`, which holds the direct DB access needed
  to keep the specification, CodeSpecs, and Implementation document data updated as
  the agent edits. A `ConversationalAgentSubstrate` composes either base mode into
  a bounded multi-turn loop (§10).
- **Tom Brain mapping.** Application → Tom Brain profile, phase/task → named
  session, open document → named memory (§11). Three canonical application
  profiles exist — DocSpecs, CodeSpecs, Implementation — each with its own
  guidelines prompt and isolated profile/memory; all three carry the full
  four-group toolset and the three base scopes, differentiated by prompt and
  isolation rather than by capability (the `toolset ⊆ scopes` invariant bounds
  capability).
- **Memory — embeddable, two-tier.** `tom_brain_memory` runs in-process with the
  bundled `vec0`. Tier 1 (BM25/structural) refreshes per-prompt with zero model
  calls; tier 2 (vectors) warms incrementally through a provider-backed embedder
  (Ollama `nomic-embed-text`, opt-in), falling back to a deterministic embedder for
  headless/test hosts. A `SpecIncrementalIndexer` drives both tiers off the edit
  path from the change log, and `mem_refresh` runs the same serialized reconcile
  (§9).
- **Scopes — read-only by construction.** `files` writes only under the whitelist
  (default `agent/scratchpad`); the `model`, `search`, and `memory` globals bridge
  no mutation path, so the `SpecDocumentController` stays the one change log
  (§4–§7).
- **Versions.** The engine pins `tom_d4rt: ^1.10.1` and `tom_d4rt_dcli: ^1.1.6`;
  the embeddable Tom Brain packages (`tom_brain_memory`, `tom_brain_shared`,
  `tom_brain_substrate`) are `publish_to: none` siblings consumed by path. The
  canonical editor carries no direct D4rt / Tom Brain pins — all transitive via the
  path-linked engine.
- **Projects.** The canonical editor is `tom_forge/tom_specs_editor`;
  `tom_ai/ai_build/tom_specs_reviewer` is a separate read-only structure reviewer
  over the object model. `tom_spec_engine` lives in `tom_ai/ai_build` and is registered in
  `.tom_metadata` (§12).
- **Bridge generator — consumed by path (stale-cache avoidance).**
  `tom_spec_engine` dev-depends on `tom_d4rt_generator` by
  `path: ../../d4rt/tom_d4rt_generator`, not from pub.dev. The SOM bridges are
  generated against the *live source* of the unpublished path siblings
  `tom_som_dart_v0` / `tom_som_dart_runtime`; a hosted generator dep forced a
  `publish → bump → pub upgrade` loop for every generator fix, and `pub upgrade`
  rewrites `pubspec.lock` without refreshing `.dart_tool/package_config.json`, so
  `dart run` kept resolving the *previous* generator and emitted stale bridges.
  The path dep removes the version indirection: the regenerator always runs the
  current generator source. Safe because it is a build-only DEV dependency (never
  in the engine's runtime API) and the engine is `publish_to: none`. This is
  distinct from the analyzer summary cache (`tom_analyzer_shared`), which already
  never caches `path` sources — so the SOM model is analyzed fresh every run
  regardless. See `_copilot_guidelines/bridge_regeneration.md` in the engine.

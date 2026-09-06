# TomSpecs Engine API Reference: Tools Module

The four tool families an agent calls — `script_*`, `doc_*`, `file_*` and
`mem_*` — and their typed result values. Every result carries `toJson()`, so one
class serves an in-process caller and an MCP transport alike.

For task-oriented guidance see [tools.md](../tools.md). For what the tools are
*for*, see
[`llm_and_d4rt_tools.md`](../../../tom_specs_model/doc/llm_and_d4rt_tools.md) §8.

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [AuthoredScript](#authoredscript)
  - [StoredScript](#storedscript)
  - [ScriptEntrypoint](#scriptentrypoint)
  - [ScriptValidation](#scriptvalidation)
  - [ScriptRunResult](#scriptrunresult)
  - [ScriptTools](#scripttools)
  - [FileScriptStore](#filescriptstore)
  - [DocSearchMatch](#docsearchmatch)
  - [DocSearchPage](#docsearchpage)
  - [DocAnnotation](#docannotation)
  - [DocAllowedChild](#docallowedchild)
  - [DocReflection](#docreflection)
  - [DocAddNodeResult](#docaddnoderesult)
  - [DocTools](#doctools)
  - [FileReadResult](#filereadresult)
  - [FileFindResult](#filefindresult)
  - [FileWriteResult](#filewriteresult)
  - [FileTools](#filetools)
  - [MemRecallHit](#memrecallhit)
  - [MemRecallResult](#memrecallresult)
  - [MemRefreshResult](#memrefreshresult)
  - [MemoryTools](#memorytools)
- [Enums](#enums)
  - [MemRecallMode](#memrecallmode)
- [Global Functions and Constants](#global-functions-and-constants)

## Overview

The module declares **22 classes** and **1 enums** across 5 source file(s).

| Source file | Holds |
|-------------|-------|
| `script_tools.dart` | `script_*` — author, list, validate, run — `AuthoredScript`, `StoredScript`, `ScriptEntrypoint`, `ScriptValidation`, `ScriptRunResult`, `ScriptTools` |
| `script_store.dart` | The `agent/scripts/` persistence — `FileScriptStore` |
| `doc_tools.dart` | `doc_*` — search, reflect, add node — `DocSearchMatch`, `DocSearchPage`, `DocAnnotation`, `DocAllowedChild`, `DocReflection`, `DocAddNodeResult`, `DocTools` |
| `file_tools.dart` | `file_*` — read, find, write — `FileReadResult`, `FileFindResult`, `FileWriteResult`, `FileTools` |
| `memory_tools.dart` | `mem_*` — recall and refresh — `MemRecallHit`, `MemRecallResult`, `MemRefreshResult`, `MemoryTools`, `MemRecallMode` |

## Class Hierarchy

```
Object
├── AuthoredScript
├── StoredScript
├── ScriptEntrypoint
├── ScriptValidation
├── ScriptRunResult
├── ScriptTools
├── FileScriptStore  implements ScriptStore
├── DocSearchMatch
├── DocSearchPage
├── DocAnnotation
├── DocAllowedChild
├── DocReflection
├── DocAddNodeResult
├── DocTools
├── FileReadResult
├── FileFindResult
├── FileWriteResult
├── FileTools
├── MemRecallHit
├── MemRecallResult
├── MemRefreshResult
└── MemoryTools
```

## Classes

### AuthoredScript

The result of `script_author`: the stored script's identity and location.

#### Constructors
```dart
const AuthoredScript({
  required this.name,
  required this.path,
  required this.scopes,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The script name. |
| `path` | `String` | The stored file path. |
| `scopes` | `List<String>` | The scopes the script targets (recorded in its header). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the MCP tool result. |

### StoredScript

A stored script as returned by `script_get` / `script_list`.

#### Constructors
```dart
const StoredScript({
  required this.name,
  required this.path,
  required this.source,
  required this.scopes,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The script name. |
| `path` | `String` | The stored file path. |
| `source` | `String` | The full stored contents (header + source). |
| `scopes` | `List<String>` | The scopes recorded in the header. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the MCP tool result. |

### ScriptEntrypoint

The declared `main()` entrypoint contract a [ScriptValidation] surfaces.

#### Constructors
```dart
ScriptEntrypoint({
  required this.exists,
  required this.isAsync,
  required this.requiredPositional,
  required this.maxPositional,
  required List<String> namedParameters,
}) : namedParameters = List.unmodifiable(namedParameters);
const ScriptEntrypoint.absent()
    : exists = false,
      isAsync = false,
      requiredPositional = 0,
      maxPositional = 0,
      namedParameters = const [];
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `exists` | `bool` | Whether a top-level `main` function is declared. |
| `isAsync` | `bool` | Whether `main()` is declared `async` (the run auto-awaits either way). |
| `requiredPositional` | `int` | The number of **required** positional parameters `main()` declares. |
| `maxPositional` | `int` | The number of **total** positional parameters (required + optional). |
| `namedParameters` | `List<String>` | The names of `main()`'s named parameters, in declaration order. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the MCP tool result. |

### ScriptValidation

The result of `script_validate`: whether the script is acceptable, the diagnostics the agent can iterate on, and the introspected entrypoint contract (when analysis got far enough to read it).

#### Constructors
```dart
const ScriptValidation({
  required this.ok,
  required this.diagnostics,
  this.entrypoint,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `ok` | `bool` | Whether the script parsed, resolved against the granted scope, declared a `main()` entrypoint, and (when `args` were supplied) satisfied its argument contract. |
| `diagnostics` | `List<String>` | Human-readable diagnostics (empty when [ok]). |
| `entrypoint` | `ScriptEntrypoint?` | The declared `main()` contract, or `null` when the source failed to parse / resolve before it could be introspected. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the MCP tool result. |

### ScriptRunResult

The result of `script_run`: the three captured output channels.

#### Constructors
```dart
const ScriptRunResult({
  required this.stdout,
  required this.result,
  required this.error,
  required this.stack,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `stdout` | `String` | Everything the script `print`ed, in order (newline-separated). |
| `result` | `Object?` | The auto-awaited `main()` return value, or `null` on error / void. |
| `error` | `String?` | The error message when the run threw, else `null`. |
| `stack` | `String?` | The stack trace when the run threw, else `null`. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the MCP tool result. |

### ScriptTools

Authors, validates, runs, and enumerates D4rt scripts under named scopes (`llm_and_d4rt_tools.md` §8.1).

#### Constructors
```dart
ScriptTools({
  required this.registry,
  required this.store,
  List<String> defaultScopes = const ['spec'],
}) : defaultScopes = List.unmodifiable(defaultScopes);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `registry` | `ScopeRegistry` | The named scope presets a run is built from. |
| `store` | `ScriptStore` | The `agent/scripts/` persistence. |
| `defaultScopes` | `List<String>` | The scopes used when none are specified or recorded. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `list()` | `List<StoredScript>` | `script_list` — every stored script, with its recorded scopes. |
| `get(String name)` | `StoredScript` | `script_get` — the stored script named [name]. |

### FileScriptStore

A [ScriptStore] backed by real files under `<workspaceRoot>/agent/scripts/`.

**implements ScriptStore**

#### Constructors
```dart
FileScriptStore(this.workspaceRoot);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `workspaceRoot` | `String` | The workspace root the `agent/scripts/` directory lives under. |
| `scriptsDir` | `String get` | The directory authored scripts are written to. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `pathOf(String name)` | `String` | The path a script named `name` maps to, whether or not it exists. |
| `store(String name, String contents)` | `String` | Persists `contents` under `name`, replacing any existing script; returns the stored path. |
| `exists(String name)` | `bool` | Whether a script named `name` exists. |
| `read(String name)` | `String?` | The full stored contents of `name`, or `null` when absent. |
| `names()` | `List<String>` | The names of all stored scripts, sorted. |

### DocSearchMatch

One match in a [DocSearchPage] — a `llm_and_d4rt_tools.md` §6 cursor record projected to JSON.

#### Constructors
```dart
const DocSearchMatch({
  required this.path,
  required this.kind,
  this.classId,
  this.headline,
  this.snippet,
  this.matchSpans = const [],
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | `String` | The globally-unique section-id path the node lives at. |
| `kind` | `SpecNodeKind` | What kind of node the path lands on. |
| `classId` | `String?` | The model class the node *is* (`null` for value leaves / list containers). |
| `headline` | `String?` | The node's doc-comment / label headline (`null` when none). |
| `snippet` | `String?` | The matched text when the query carried a `text` dimension (`null` otherwise). |
| `matchSpans` | `List<SpecMatchSpan>` | The `[start, end)` spans within [snippet] the `text` pattern hit. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the MCP tool result. |

### DocSearchPage

One page of `doc_search` / `doc_search_iterate` results plus the cursor id to continue iterating with.

#### Constructors
```dart
const DocSearchPage({
  required this.cursorId,
  required this.matches,
  required this.done,
  required this.remaining,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `cursorId` | `String` | The cursor id to pass to `doc_search_iterate` for the next page. |
| `matches` | `List<DocSearchMatch>` | This page's matches (at most the page size). |
| `done` | `bool` | Whether the cursor is exhausted (no further pages). |
| `remaining` | `int` | How many further matches remain after this page (re-validated live). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the MCP tool result. |

### DocAnnotation

A single annotation captured on a class or field (`doc_reflect`).

#### Constructors
```dart
const DocAnnotation({required this.name, this.arguments = const {}});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The annotation name (e.g. |
| `arguments` | `Map<String, Object?>` | The resolved argument map. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view. |

### DocAllowedChild

One model-permitted child of a reflected container node (`doc_reflect`): the segment a `doc_add_node` would use plus the field's structural facts.

#### Constructors
```dart
const DocAllowedChild({
  required this.segment,
  required this.field,
  required this.kind,
  this.type,
  this.elementType,
  this.elementIsComplex = false,
  this.sectionIdPattern,
  this.enumValues = const [],
  this.annotations = const [],
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `segment` | `String` | The section segment the child is added under (`@SectionId` ?? |
| `field` | `String` | The declared field name. |
| `kind` | `SpecFieldKind` | The field's render kind. |
| `type` | `String?` | The single-valued field's target/scalar type (`null` for lists/leaves). |
| `elementType` | `String?` | A list field's element type (`null` for non-lists). |
| `elementIsComplex` | `bool` | Whether a list field's element is a complex (class) type. |
| `sectionIdPattern` | `String?` | The `@SectionIdPattern` a list item's id must match (`null` when none). |
| `enumValues` | `List<String>` | The enum values for an `enum` field (empty otherwise). |
| `annotations` | `List<DocAnnotation>` | The field's annotations. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view. |

### DocReflection

The `doc_reflect` result: the meta-model facts a node addresses.

#### Constructors
```dart
const DocReflection({
  required this.path,
  required this.resolved,
  this.kind,
  this.classId,
  this.sectionId,
  this.mapsTo,
  this.detailedIn,
  this.headline,
  this.annotations = const [],
  this.allowedChildren = const [],
});
const DocReflection.unresolved(this.path)
    : resolved = false,
      kind = null,
      classId = null,
      sectionId = null,
      mapsTo = null,
      detailedIn = null,
      headline = null,
      annotations = const [],
      allowedChildren = const [];
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | `String` | The path that was reflected. |
| `resolved` | `bool` | Whether [path] resolves to a model node. |
| `kind` | `SpecNodeKind?` | What kind of node the path lands on (`null` when unresolved). |
| `classId` | `String?` | The model class the node *is* (`null` for leaves / unresolved). |
| `sectionId` | `String?` | The node's `@SectionId`. |
| `mapsTo` | `String?` | The `@MapsTo` target on the node's class. |
| `detailedIn` | `String?` | The `@DetailedIn` target on the node's class. |
| `headline` | `String?` | The node's doc-comment / label headline. |
| `annotations` | `List<DocAnnotation>` | The class-level annotations (empty for leaves / unresolved). |
| `allowedChildren` | `List<DocAllowedChild>` | The model-permitted children (empty for leaves / unresolved). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the MCP tool result. |

### DocAddNodeResult

The `doc_add_node` result: the new node's path, or the coded reason the meta-model rejected the add.

#### Constructors
```dart
const DocAddNodeResult({
  required this.ok,
  this.path,
  this.error,
  this.code,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `ok` | `bool` | Whether the add was legal and performed. |
| `path` | `String?` | The new node's path (when [ok]). |
| `error` | `String?` | The human-readable rejection message (when not [ok]). |
| `code` | `String?` | The [SpecCreationCode] name when the add violated a `llm_and_d4rt_tools.md` §5 rule (`null` for other failures). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the MCP tool result. |

### DocTools

Searches, reflects, and grows a live document under the `llm_and_d4rt_tools.md` §8.2 `doc_*` tools.

#### Constructors
```dart
DocTools({
  required this.engine,
  required this.controller,
  this.pageSize = 20,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `engine` | `SpecQueryEngine` | The `llm_and_d4rt_tools.md` §6 query facility over the live (model, document) pair. |
| `controller` | `SpecController` | The live-document mutation port (the one change log). |
| `pageSize` | `int` | The default page size for `doc_search` / `doc_search_iterate`. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `search(SpecQuery query, {int? pageSize})` | `DocSearchPage` | `doc_search` — runs [query] (the `llm_and_d4rt_tools.md` §6 grep facility), opens a cursor under a fresh id, and returns the first page. |
| `iterate(String cursorId, {int? pageSize})` | `DocSearchPage` | `doc_search_iterate` — advances the cursor named [cursorId] by one page. |
| `reflect(String path)` | `DocReflection` | `doc_reflect` — the meta-model facts the node at [path] addresses: its kind/class, structural facets (`@SectionId` / `@MapsTo` / `@DetailedIn`), the class annotations, and the model-permitted children (allowed `doc_add_node` segments + their types). |

### FileReadResult

The `file_read` result.

#### Constructors
```dart
const FileReadResult({
  required this.path,
  required this.exists,
  this.content,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | `String` | The path that was read. |
| `exists` | `bool` | Whether anything exists at [path]. |
| `content` | `String?` | The file's full text (`null` when it does not exist). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the MCP tool result. |

### FileFindResult

The `file_find` result.

#### Constructors
```dart
const FileFindResult({required this.glob, required this.matches});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `glob` | `String` | The basename glob that was searched. |
| `matches` | `List<String>` | The matching paths. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the MCP tool result. |

### FileWriteResult

The `file_write` result.

#### Constructors
```dart
const FileWriteResult({required this.ok, required this.path, this.error});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `ok` | `bool` | Whether the write succeeded (the path was inside the whitelist). |
| `path` | `String` | The path that was written. |
| `error` | `String?` | The permission-violation message when the write was rejected. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the MCP tool result. |

### FileTools

Reads, finds, and writes files under the `llm_and_d4rt_tools.md` §8.2 `file_*` tools, mediated by the audited [SpecFileFacade] (`llm_and_d4rt_tools.md` §7).

#### Constructors
```dart
FileTools(this.facade);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `facade` | `SpecFileFacade` | The read-anywhere / write-whitelist file facade. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `read(String path)` | `FileReadResult` | `file_read` — the full text of the file at [path] (read is permitted anywhere). |
| `find(String glob, {String dir = '.', bool includeAssets = false})` | `FileFindResult` | `file_find` — the paths under [dir] matching [glob] (read-only exploration; `dir` defaults to the workspace root). |
| `write(String path, String content)` | `FileWriteResult` | `file_write` — writes [content] to [path] (whitelist-checked). |

### MemRecallHit

One `mem_recall` hit projected to JSON.

#### Constructors
```dart
const MemRecallHit({
  required this.path,
  required this.score,
  required this.modes,
  this.kind,
  this.headline,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | `String` | The recalled section's path. |
| `score` | `double` | The fused Reciprocal-Rank-Fusion score (higher = more relevant). |
| `modes` | `List<String>` | The retrieval modes that surfaced this section. |
| `kind` | `String?` | The node kind (`null` when known only from the vector tier). |
| `headline` | `String?` | The doc-comment / label headline (`null` when unknown). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the MCP tool result. |

### MemRecallResult

The `mem_recall` result: the ranked hits and whether the recall degraded to tier 1 (the vector tier was cold).

#### Constructors
```dart
const MemRecallResult({required this.hits, required this.degraded});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `hits` | `List<MemRecallHit>` | The ranked hits, best first. |
| `degraded` | `bool` | Whether the recall ran in degraded (tier-1-only) mode. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the MCP tool result. |

### MemRefreshResult

The `mem_refresh` result: what the manual re-index did.

#### Constructors
```dart
const MemRefreshResult({
  required this.refreshed,
  this.embedded = 0,
  this.unchanged = 0,
  this.edges = 0,
  this.removed = 0,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `refreshed` | `bool` | Whether a refresh actually ran (a callback was bound). |
| `embedded` | `int` | Sections re-embedded (content actually changed). |
| `unchanged` | `int` | Sections skipped because their content hash was unchanged. |
| `edges` | `int` | Edges (re-)linked for the touched sections. |
| `removed` | `int` | Sections forgotten (removed from memory). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toJson()` | `Map<String, Object?>` | A compact JSON view for the MCP tool result. |

### MemoryTools

Recalls from, and refreshes, a document's memory under the `llm_and_d4rt_tools.md` §8.2 `mem_*` tools.

#### Constructors
```dart
MemoryTools({required this.recall, this.onRefresh});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `recall` | `SpecRecall` | The fused two-tier recall (`llm_and_d4rt_tools.md` §9). |
| `onRefresh` | `MemRefreshFn?` | The manual re-index callback, or `null` when none is bound. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `refresh()` | `Future<MemRefreshResult>` | `mem_refresh` — runs the bound re-index callback, or reports `refreshed: false` when none is bound. |

## Enums

### MemRecallMode

Which retrieval mode `mem_recall` restricts its hits to.

| Value | Meaning |
|-------|---------|
| `fused` | The full fused recall (lexical + symbolic + vector + GraphWalk). |
| `lexical` | Only hits the tier-1 BM25 lexical mode surfaced. |
| `symbolic` | Only hits the tier-1 structural facet ("symbolic") mode surfaced. |
| `vector` | Only hits the tier-2 vector mode surfaced. |

## Global Functions and Constants

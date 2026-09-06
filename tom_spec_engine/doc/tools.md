# TomSpecs Engine — The Tool Surface

The engine's tool classes are what an agent actually calls. Each is a plain Dart
class whose results are typed values with a `toJson()` — so the same surface
serves an in-process caller and an MCP transport without a second adapter. This
guide covers the four families, what each returns, and how a failure is
represented. What the tools *are* for is
[`llm_and_d4rt_tools.md`](../../tom_specs_model/doc/llm_and_d4rt_tools.md) §8;
this guide states the API and cites that.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
  - [ScriptTools — `script_*`](#scripttools--script_)
  - [DocTools — `doc_*`](#doctools--doc_)
  - [FileTools — `file_*`](#filetools--file_)
  - [MemoryTools — `mem_*`](#memorytools--mem_)
- [Results are values, not exceptions](#results-are-values-not-exceptions)
- [What each barrel exposes](#what-each-barrel-exposes)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

Four families, one shape:

| Family | Class | Over | Answers |
|--------|-------|------|---------|
| `script_*` | `ScriptTools` | A `ScopeRegistry` + a `ScriptStore` | Author, list, validate and run D4rt scripts |
| `doc_*` | `DocTools` | A `SpecController` | Search, reflect on and grow the document |
| `file_*` | `FileTools` | A `SpecFileFacade` | Read, find and write files, audited |
| `mem_*` | `MemoryTools` | A `SpecRecall` | Semantic recall and index refresh |

Every result type carries `toJson()`. That is the design decision the whole
surface rests on: an agent transport needs JSON, an in-process caller needs the
typed value, and having one class produce both means the two can never disagree
about what a result is.

## Quick Start

```dart
import 'dart:io';

import 'package:tom_spec_engine/scripting.dart';

Future<void> main() async {
  final ws = Directory.systemTemp.createTempSync('tse_');
  Directory('${ws.path}/agent/scratchpad').createSync(recursive: true);

  final tools = FileTools(SpecFileFacade(workspaceRoot: ws.path));

  final written = tools.write('agent/scratchpad/report.md', '# Findings\n');
  print('${written.ok} ${written.path.endsWith('report.md')}');

  final read = tools.read('agent/scratchpad/report.md');
  print(read.toJson()['content']);

  // Write outside the whitelist: refused, and reported as a value.
  final refused = tools.write('outside.md', 'nope');
  print(refused.ok);
  print(refused.error != null);
}
```

Output:

```
true true
# Findings

false
true
```

The refused write returned a `FileWriteResult` with `ok: false` and an `error`
— it did not throw. That is the contract the whole surface follows.

## Core Components

### `ScriptTools` — `script_*`

| Method | Returns | Does |
|--------|---------|------|
| `author(name, source, {scopes})` | `AuthoredScript` | Stores a script as `*.d4rt.dart`, recording its scopes in a header |
| `list()` | `List<StoredScript>` | Every stored script with its recorded scopes |
| `get(name)` | `StoredScript` | One stored script |
| `validate({source, name, scopes})` | `ScriptValidation` | Parses and checks without running |
| `run({source, name, scopes, args})` | `Future<ScriptRunResult>` | Runs raw source or a stored script |

`validate` before `run` is worth doing when an agent authored the source: it
reports an entrypoint-arity mismatch with the same diagnostics `run` would, but
without executing anything.

See [scripting.md](scripting.md) for the scope model these operate under.

### `DocTools` — `doc_*`

| Method | Returns | Does |
|--------|---------|------|
| `search(query, {pageSize})` | `DocSearchPage` | Runs a `SpecQuery` over the live document |
| `iterate(cursorId, {pageSize})` | `DocSearchPage` | The next page of a previous search |

Search is **paged by cursor**, not by offset. A document is being edited while
an agent reads it, so an offset would silently skip or repeat sections as
content shifts; a cursor stays valid.

`DocReflection` answers "what may go here?" — the model's allowed children at a
path, with their annotations — which is what makes constrained creation
possible: an agent asks before it adds, rather than adding and being rejected.

### `FileTools` — `file_*`

| Method | Returns | Does |
|--------|---------|------|
| `read(path)` | `FileReadResult` | Reads any path in the workspace |
| `find(glob, {dir, includeAssets})` | `FileFindResult` | Globs for matching paths |
| `write(path, content)` | `FileWriteResult` | Writes, whitelist-enforced |

The policy is **read anywhere, write whitelist-only** — by default
`agent/scratchpad`. Enforcement is path canonicalisation: symlinks and `..` are
resolved *before* any I/O, so an escape is refused rather than attempted.

### `MemoryTools` — `mem_*`

| Method | Returns | Does |
|--------|---------|------|
| `recallQuery(...)` | `Future<MemRecallResult>` | Fused recall over the configured tiers |
| `refresh()` | `Future<MemRefreshResult>` | Re-indexes changed sections |

`MemRecallResult` carries a **`degraded`** flag, which is the tool-surface
counterpart of `SpecRecallResult.tier2Warm`: an agent needs to know that its
"semantic" search was answered lexically, because it changes how much the answer
is worth. See [memory.md](memory.md).

## Results are values, not exceptions

Every tool returns an outcome rather than throwing on a foreseeable failure, and
the reason is the caller: an agent has to *read* a failure and decide what to do
next, which a thrown exception across a transport boundary makes harder.

| Family | Failure carrier |
|--------|-----------------|
| `script_*` | `ScriptRunResult.ok` + `.error`; `ScriptValidation` |
| `file_*` | `FileWriteResult.ok` + `.error` |
| `mem_*` | `MemRecallResult.degraded`, and an empty hit list |
| `doc_*` | An empty `DocSearchPage` |

What *does* throw is caller error rather than subject error: an unsafe script
name, a `get(name)` for a script that does not exist. The line is whether the
tool was asked something malformed (throw) or asked something reasonable that
did not work out (value).

## What each barrel exposes

| Tool | `scripting.dart` (Flutter) | `tom_spec_engine.dart` (full) |
|------|---------------------------|-------------------------------|
| `ScriptTools` | yes | yes |
| `DocTools` | yes | yes |
| `FileTools` | yes | yes |
| `MemoryTools` | **no** | yes |

`MemoryTools` is out of the Flutter door because it depends on the memory plane,
which is sqlite3 FFI. Everything else a host needs to give an agent a working
tool surface is available behind `scripting.dart`.

## Error Handling

| Situation | Result |
|-----------|--------|
| A script that fails at run time | `ScriptRunResult.ok == false`, `.error` set |
| A write outside the writable whitelist | `FileWriteResult.ok == false`; **nothing touched on disk** |
| A read of a path that does not exist | `FileReadResult` reporting the miss |
| A glob that matches nothing | `FileFindResult` with an empty `matches` |
| `mem_recall` with no vector tier | `MemRecallResult.degraded == true` |
| An unsafe stored-script name | `ArgumentError` from `author` |
| `get(name)` for a script the store lacks | Throws — the caller named something that is not there |

The write case is worth being precise about: the refusal happens **before** the
filesystem is touched, because the path is canonicalised first. A caller that
sees `ok: false` can be sure nothing partial was written.

## Best Practices

- **Check the `ok` / `degraded` flag before using a result.** These surfaces do
  not throw on foreseeable failures, so an unchecked result reads as success.
- **Page with the cursor, not an offset.** The document changes under a reader;
  that is what the cursor exists for.
- **Ask `DocReflection` before adding a node.** Constrained creation is a
  question-then-act surface; guessing and being rejected wastes a turn.
- **Validate agent-authored source before running it.** `validate` gives the
  same diagnostics without executing.
- **Give `FileTools` the narrowest workspace root that works.** The whitelist is
  the second line; the root is the first.
- **Serialize with `toJson()` rather than reformatting.** It is the same shape
  the transport already expects, and reformatting is how the two views drift.

---

Back to the [documentation index](index.md).

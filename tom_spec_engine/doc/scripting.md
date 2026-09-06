# TomSpecs Engine — Running Scripts

The engine gives an agent a D4rt scripting surface over a live specification.
This guide is the operator's view: building a scope registry, running a script,
what a script may reach and why it fails when it may not, and storing scripts
for reuse. What each scope *is* — the authority model behind it — is
[`llm_and_d4rt_tools.md`](../../tom_specs_model/doc/llm_and_d4rt_tools.md), and
what an agent is told about writing one is
[`llm_guidelines_specification.md`](../../tom_specs_model/doc/llm_guidelines_specification.md).
Both are cited here, never restated.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
  - [SpecController — the port you supply](#speccontroller--the-port-you-supply)
  - [ScopeRegistry and ScriptScope](#scoperegistry-and-scriptscope)
  - [ScriptTools](#scripttools)
- [The import a script needs](#the-import-a-script-needs)
- [Choosing which barrel to import](#choosing-which-barrel-to-import)
- [Storing and re-running a script](#storing-and-re-running-a-script)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

A run is three things assembled: a **controller** (the live document), a
**registry** of named scopes (what a script may reach), and **`ScriptTools`**
(the surface that authors, validates and runs).

The design point worth internalising is that authority is named, not
configured. A `ScriptScope` is immutable once registered, so changing what a
script may touch means running under a *different scope name* rather than
mutating a scope — which is why a run's scope list is a complete description of
its authority.

The engine is pure Dart and headless. The Flutter editor links it in-process;
tests and CLI drivers use the same API.

## Quick Start

The engine defines `SpecController` as a **port**: the editor's real document
controller satisfies it, and anything else can too. Here is a self-contained
run against an in-memory one.

```dart
import 'dart:io';

import 'package:tom_spec_engine/scripting.dart';

/// A minimal in-memory controller — the port the editor's real one satisfies.
class MemoryController implements SpecController {
  final _content = <String, String>{};
  final _fields = <String, String>{};
  final _lists = <String, List<String>>{};

  @override
  String? content(String path) => _content[path];

  @override
  String? formField(String path, String field) => _fields['$path/$field'];

  @override
  List<String> listItems(String listPath) => _lists[listPath] ?? const [];

  @override
  void setContent(String path, String value) =>
      value.isEmpty ? _content.remove(path) : _content[path] = value;

  @override
  void setFormField(String path, String field, String value) =>
      _fields['$path/$field'] = value;

  @override
  String addListItem(String listPath) {
    final items = _lists.putIfAbsent(listPath, () => []);
    final path = '$listPath/item-${items.length + 1}';
    items.add(path);
    return path;
  }

  @override
  bool removeListItem(String itemPath) => false;

  @override
  String addChild(String parentPath, String childSegment, {String? itemId}) =>
      '$parentPath/$childSegment';
}

Future<void> main() async {
  final controller = MemoryController()
    ..setContent('SBP/content', 'A unifying order platform.');

  final registry = ScopeRegistry()..register(specScope(controller));
  final tools = ScriptTools(
    registry: registry,
    store: FileScriptStore(Directory.systemTemp.createTempSync('tse_').path),
  );

  final run = await tools.run(
    scopes: const ['spec'],
    source: '''
      import 'package:tom_spec_engine/spec_api.dart';
      String main() => spec.content('SBP/content') ?? '(empty)';
    ''',
  );

  print(registry.names);
  print(run.ok);
  print(run.result);
}
```

Output:

```
(spec)
true
A unifying order platform.
```

## Core Components

### `SpecController` — the port you supply

An `abstract interface class` with eight members. The engine never constructs a
document of its own; it drives whatever satisfies this contract.

| Member | Does |
|--------|------|
| `content(path)` | The content value at `path`, or `null` when unset |
| `formField(path, field)` | The form field value, or `null` |
| `listItems(listPath)` | The ordered item paths of a list (empty when none) |
| `setContent(path, value)` | Sets content; an empty value clears it |
| `setFormField(path, field, value)` | Sets a form field; an empty value clears it |
| `addListItem(listPath)` | Appends an item, returning its new path |
| `removeListItem(itemPath)` | Removes an item; returns whether one went |
| `addChild(parentPath, childSegment, {itemId})` | Model-validated constrained creation |

The real implementation records a change-log entry and pushes an undo snapshot
per non-no-op mutation. An implementation that skips that is legal — the engine
does not require it — but it gives up undo, so a stub is for tests, not for an
editor.

### `ScopeRegistry` and `ScriptScope`

A `ScriptScope` bundles the D4rt bridged libraries one authority grants.
`ScopeRegistry` maps names to scopes and builds a run environment from a list of
names.

```dart
import 'dart:io';

import 'package:tom_spec_engine/scripting.dart';

Future<void> main() async {
  final facade =
      SpecFileFacade(workspaceRoot: Directory.systemTemp.createTempSync('ws_').path);

  final registry = ScopeRegistry()..register(filesScope(facade));

  print(registry.names);
  print(facade.writableRoots.single.endsWith('agent/scratchpad'));
}
```

Output:

```
(files)
true
```

`SpecFileFacade`'s named argument is **`workspaceRoot`**, and its default
writable root is `<workspace>/agent/scratchpad` — read is any path, write is
whitelist-only.

### `ScriptTools`

| Member | Does |
|--------|------|
| `registry` | The named scope presets a run is built from |
| `store` | The `agent/scripts/` persistence |
| `defaultScopes` | Applied when a run names none — defaults to `['spec']` |
| `author(name, source, {scopes})` | Stores a script as `*.d4rt.dart`, recording its scopes in a header |
| `run({source, name, scopes, args})` | Runs raw source or a stored script |

Scope resolution for a run is: the explicit `scopes` argument, else the scopes
recorded in the stored script's header, else `defaultScopes`. A raw `source` run
with no `scopes` therefore gets the `spec` scope and nothing else.

## The import a script needs

**A D4rt script must import the library its scope binds.** Each base scope
registers its API global into exactly one bridged library, and a script that
does not import that library cannot see the global:

| Scope | The script's import | The global it surfaces |
|-------|--------------------|------------------------|
| `spec` | `package:tom_spec_engine/spec_api.dart` | `spec` |
| `spec` (model access) | `package:tom_spec_engine/spec_model_api.dart` | `model` |
| `spec` (search access) | `package:tom_spec_engine/spec_search_api.dart` | `search` |
| `files` | `package:tom_spec_engine/spec_files.dart` | the file surface |
| `memory` | `package:tom_spec_engine/memory.dart` | the recall surface |

Omitting it does not read a null — it fails the run:

```dart
import 'dart:io';

import 'package:tom_spec_engine/scripting.dart';

class Stub implements SpecController {
  @override
  String? content(String path) => 'value';
  @override
  String? formField(String path, String field) => null;
  @override
  List<String> listItems(String listPath) => const [];
  @override
  void setContent(String path, String value) {}
  @override
  void setFormField(String path, String field, String value) {}
  @override
  String addListItem(String listPath) => '$listPath/item-1';
  @override
  bool removeListItem(String itemPath) => false;
  @override
  String addChild(String parentPath, String childSegment, {String? itemId}) =>
      '$parentPath/$childSegment';
}

Future<void> main() async {
  final tools = ScriptTools(
    registry: ScopeRegistry()..register(specScope(Stub())),
    store: FileScriptStore(Directory.systemTemp.createTempSync('tse_').path),
  );

  // No import — the `spec` global is not a name the script can resolve.
  final bad = await tools.run(
    scopes: const ['spec'],
    source: "String main() => spec.content('SBP/content') ?? '(empty)';",
  );

  print(bad.ok);
  print(bad.error);
}
```

Output:

```
false
Runtime Error: Undefined variable: spec
```

The scope grants the authority; the import is what brings the granted names into
the script's lexical scope. Both are needed, and they fail differently: a
missing scope means the library is not registered at all, a missing import means
it is registered but not looked at.

## Choosing which barrel to import

The engine has **two public doors**, and picking the wrong one is the most
common integration mistake:

| Barrel | Carries | Use when |
|--------|---------|----------|
| `package:tom_spec_engine/scripting.dart` | The scopes, the registry, the script tools, `DocTools`, `FileTools` | Linking into **Flutter** — it keeps the memory plane out of the compile |
| `package:tom_spec_engine/tom_spec_engine.dart` | All of the above **plus** the RAG memory plane | Headless: CLI, tests, server |

The memory plane depends on `tom_brain_memory`, which is sqlite3 FFI with a
`vec0` extension — a server-only surface. `scripting.dart` exists so a Flutter
host can link the engine in-process without pulling it in.

## Storing and re-running a script

`author` writes the script under `agent/scripts/` with its scopes recorded in a
header, so a later `run(name: ...)` reproduces the same authority without the
caller having to remember it.

```dart
import 'dart:io';

import 'package:tom_spec_engine/scripting.dart';

class Stub implements SpecController {
  @override
  String? content(String path) => 'A unifying order platform.';
  @override
  String? formField(String path, String field) => null;
  @override
  List<String> listItems(String listPath) => const [];
  @override
  void setContent(String path, String value) {}
  @override
  void setFormField(String path, String field, String value) {}
  @override
  String addListItem(String listPath) => '$listPath/item-1';
  @override
  bool removeListItem(String itemPath) => false;
  @override
  String addChild(String parentPath, String childSegment, {String? itemId}) =>
      '$parentPath/$childSegment';
}

Future<void> main() async {
  final root = Directory.systemTemp.createTempSync('tse_').path;
  final tools = ScriptTools(
    registry: ScopeRegistry()..register(specScope(Stub())),
    store: FileScriptStore(root),
  );

  final stored = tools.author(
    'read_vision',
    "import 'package:tom_spec_engine/spec_api.dart';\n"
    "String main() => spec.content('SBP/content') ?? '(empty)';",
    scopes: const ['spec'],
  );

  print(stored.name);
  print(stored.path.endsWith('read_vision.d4rt.dart'));

  // Re-run by name: the recorded scopes are used, none passed here.
  final run = await tools.run(name: 'read_vision');
  print(run.ok);
  print(run.result);
}
```

Output:

```
read_vision
true
true
A unifying order platform.
```

`author` throws `ArgumentError` on an unsafe name — a name is a filename, so a
path separator or a traversal segment in one is rejected before anything
touches disk.

## Error Handling

A run **does not throw on script failure**. `ScriptRunResult` carries the
outcome, which is the right shape for a tool surface an agent drives: an agent
needs to read the error and try again, not catch an exception.

| Situation | Result |
|-----------|--------|
| A script that completes | `run.ok == true`, `run.result` holds the return value |
| A script referencing a name no imported library binds | `run.ok == false`, `run.error` is `Undefined variable: <name>` |
| A script importing a library no registered scope provides | `run.ok == false`, `run.error` names the un-preloaded package URI |
| A write outside the writable whitelist | `FilePermissionError`, raised **before** touching disk |
| An unsafe stored-script name | `ArgumentError` from `author` |
| `run(name:)` for a script the store does not hold | Throws — a missing script is a caller defect, not a script outcome |

The file policy is worth stating precisely because it is enforced twice: paths
are canonicalised (resolving symlinks and `..`) so an escape is refused before
any I/O, and the `files` scope additionally grants D4rt `read=any` +
`write=<whitelist>` as a defence-in-depth backstop.

## Best Practices

- **Pass `scopes` explicitly on a raw-source run.** The `spec`-only default is
  safe, but an explicit list makes the run's authority legible at the call site.
- **Import the scope's library in every script.** A missing import fails at run
  time with `Undefined variable`, which reads like a document problem and is not.
- **Link `scripting.dart` from Flutter, `tom_spec_engine.dart` elsewhere.** The
  split exists to keep sqlite3 FFI out of the Flutter compile.
- **Register a new scope rather than mutating one.** Scopes are immutable so
  that a scope name fully describes an authority; mutating one would make the
  name a lie.
- **Store a script you will run twice.** The recorded scope header is what stops
  a re-run from silently getting different authority.
- **Read `run.ok` before `run.result`.** A failed run has a null result and a
  populated `error`; treating the null as an empty document hides the failure.

---

Back to the [documentation index](index.md).

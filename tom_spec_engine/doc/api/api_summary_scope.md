# TomSpecs Engine API Reference: Scope Module

The scope model: the `SpecController` port a host supplies, the named scopes a
script runs under, and the registry that assembles them.

For task-oriented guidance see [scripting.md](../scripting.md). For what each
scope *is*, see
[`llm_and_d4rt_tools.md`](../../../tom_specs_model/doc/llm_and_d4rt_tools.md)
§4–§7.

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [BridgedLibrary](#bridgedlibrary)
  - [ScopeGlobal](#scopeglobal)
  - [ScriptScope](#scriptscope)
  - [ScopeError](#scopeerror)
  - [ScopeProfile](#scopeprofile)
  - [RunEnvironment](#runenvironment)
  - [ScopeRegistry](#scoperegistry)
  - [FilePermissionError](#filepermissionerror)
  - [SpecFileFacade](#specfilefacade)
  - [SpecApi](#specapi)
  - [SpecModelApi](#specmodelapi)
  - [SpecSearchApi](#specsearchapi)
  - [SpecSearchCursor](#specsearchcursor)
  - [MemoryApi](#memoryapi)
- [Global Functions and Constants](#global-functions-and-constants)

## Overview

The module declares **14 classes** across 12 source file(s).

| Source file | Holds |
|-------------|-------|
| `scope.dart` | The scope value types — `BridgedLibrary`, `ScopeGlobal`, `ScriptScope`, `ScopeError` |
| `scope_registry.dart` | The named-scope registry — `ScopeProfile`, `RunEnvironment`, `ScopeRegistry` |
| `spec_controller.dart` | The document port — *(no public types)* |
| `spec_scope.dart` | The `spec` base scope — *(no public types)* |
| `files_scope.dart` | The `files` base scope — *(no public types)* |
| `memory_scope.dart` | The `memory` base scope — *(no public types)* |
| `spec_file_facade.dart` | The audited file facade — `FilePermissionError`, `SpecFileFacade` |
| `spec_api.dart` | The `spec` global — `SpecApi` |
| `spec_model_api.dart` | The `model` global — `SpecModelApi` |
| `spec_search_api.dart` | The `search` global — `SpecSearchApi`, `SpecSearchCursor` |
| `memory_api.dart` | The memory global — `MemoryApi` |
| `som_library.dart` | The SOM bridged library — *(no public types)* |

## Class Hierarchy

```
Object
├── BridgedLibrary
├── ScopeGlobal
├── ScriptScope
├── ScopeError  implements Exception
├── ScopeProfile
├── RunEnvironment
├── ScopeRegistry
├── FilePermissionError  implements Exception
├── SpecFileFacade
├── SpecApi
├── SpecModelApi
├── SpecSearchApi
├── SpecSearchCursor
└── MemoryApi
```

## Classes

### BridgedLibrary

A named, reusable bridged-library building block.

#### Constructors
```dart
const BridgedLibrary(this.name, LibraryRegistrar registrar)
    : _registrar = registrar;
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Identity / label of this library (conventionally the import path exposed). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `register(D4rt interpreter)` | `void` | Registers this library's bridged surface with [interpreter]. |
| `toString()` | `String` | A compact diagnostic rendering. |

### ScopeGlobal

An injected global variable: [value] bound to [name], visible to a script that imports [library] (the registration-key URI).

#### Constructors
```dart
const ScopeGlobal({
  required this.name,
  required this.value,
  required this.library,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The variable name a script references. |
| `value` | `Object?` | The value captured at registration time. |
| `library` | `String` | The library URI a script imports to bring [name] into scope. |
| `key` | `String get` | The composite identity used to detect cross-scope conflicts: two globals collide only when both [library] and [name] match. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### ScriptScope

A named, immutable D4rt scripting scope (`llm_and_d4rt_tools.md` §4).

#### Constructors
```dart
ScriptScope({
  required this.name,
  List<BridgedLibrary>? libraries,
  List<ScopeGlobal>? globals,
  List<Permission>? grants,
})  : libraries = List.unmodifiable(libraries ?? const []),
      globals = List.unmodifiable(globals ?? const []),
      grants = List.unmodifiable(grants ?? const []);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The scope's unique name (e.g. |
| `libraries` | `List<BridgedLibrary>` | The bridged D4rt libraries this scope exposes. |
| `globals` | `List<ScopeGlobal>` | The globals this scope injects. |
| `grants` | `List<Permission>` | The permission grants this scope confers. |
| `operator ==(Object other)` | `bool` | Value equality — two scopes with the same name and bindings are the same scope. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### ScopeError

Raised for scope-configuration faults: an unknown scope name, a duplicate registration, or a conflicting injected global across unioned scopes.

**implements Exception**

#### Constructors
```dart
ScopeError(this.message);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `message` | `String` | Human-readable description of the fault. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### ScopeProfile

A declarative application profile: the named set of scopes an application (DocSpecs / CodeSpecs / Implementation …) enables (`llm_and_d4rt_tools.md` §4).

#### Constructors
```dart
ScopeProfile({
  required this.name,
  required List<String> scopeNames,
  List<String> assetDirs = const [],
})  : scopeNames = List.unmodifiable(scopeNames),
      assetDirs = List.unmodifiable(assetDirs);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The application/profile name. |
| `scopeNames` | `List<String>` | The names of the scopes this profile enables, in priority order. |
| `assetDirs` | `List<String>` | Opt-in **asset directories** this profile declares as extra read-only search roots (template / schema / example dirs), relative to the spec workspace root or absolute (`llm_and_d4rt_tools.md` §7). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### RunEnvironment

The computed union of one or more scopes: the libraries, globals, and grants a single script run receives.

#### Constructors
```dart
RunEnvironment._({
  required List<String> scopeNames,
  required List<BridgedLibrary> libraries,
  required List<ScopeGlobal> globals,
  required List<Permission> grants,
})  : scopeNames = List.unmodifiable(scopeNames),
      libraries = List.unmodifiable(libraries),
      globals = List.unmodifiable(globals),
      grants = List.unmodifiable(grants);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `scopeNames` | `List<String>` | The scope names this environment was built from, in request order. |
| `libraries` | `List<BridgedLibrary>` | The de-duplicated union of bridged libraries. |
| `globals` | `List<ScopeGlobal>` | The de-duplicated union of injected globals. |
| `grants` | `List<Permission>` | The accumulated union of permission grants. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `applyTo(D4rt interpreter)` | `void` | Applies this environment to [interpreter]: registers each bridged library, injects each global, and grants each permission. |

### ScopeRegistry

Holds named scope presets and unions them into [RunEnvironment]s (`llm_and_d4rt_tools.md` §4).

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `names` | `Iterable<String> get` | The names of all registered scopes. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `register(ScriptScope scope)` | `void` | Registers a scope preset. |
| `has(String name)` | `bool` | Whether a scope named [name] is registered. |
| `scope(String name)` | `ScriptScope` | The registered scope named [name]. |
| `build(Iterable<String> scopeNames)` | `RunEnvironment` | Builds a [RunEnvironment] from the union of the named scopes, in the order given. |
| `buildProfile(ScopeProfile profile)` | `RunEnvironment` | Builds a [RunEnvironment] from a declarative [profile] — sugar for `build(profile.scopeNames)`. |

### FilePermissionError

Raised when a write/mutate operation targets a path outside the facade's writable whitelist.

**implements Exception**

#### Constructors
```dart
FilePermissionError(this.path, this.message);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | `String` | The (canonicalised) path the operation tried to write. |
| `message` | `String` | Human-readable description of the violation. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### SpecFileFacade

A thin, audited file wrapper: read-anywhere, write-only-under-whitelist.

#### Constructors
```dart
SpecFileFacade._(this.workspaceRoot, this.writableRoots, this.assetDirs);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `workspaceRoot` | `String` | The canonicalised spec workspace root that relative paths resolve against. |
| `writableRoots` | `List<String>` | The canonicalised directories writes are permitted under. |
| `assetDirs` | `List<String>` | The canonicalised opt-in **asset directories** a profile declares as extra read-only search roots (`llm_and_d4rt_tools.md` §7). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `readText(String path)` | `String` | The full text of the file at [path]. |
| `readLines(String path)` | `List<String>` | The lines of the file at [path]. |
| `head(String path, {int lines = 10})` | `String` | The first [lines] lines of the file at [path]. |
| `tail(String path, {int lines = 10})` | `String` | The last [lines] lines of the file at [path]. |
| `exists(String path)` | `bool` | Whether anything exists at [path]. |
| `stat(String path)` | `Map<String, Object?>` | File metadata at [path]: `type`, `size`, and ISO `modified`. |
| `find(String dir, {String? glob, bool includeAssets = false})` | `List<String>` | The paths of entries under directory [dir] (recursively), optionally filtered by [glob]. |
| `writeText(String path, String content)` | `void` | Writes [content] to [path] (creating parents), replacing any existing file. |
| `append(String path, String content)` | `void` | Appends [content] to the file at [path] (creating parents). |
| `createDir(String path)` | `void` | Creates the directory at [path] (and parents). |
| `copy(String from, String to)` | `void` | Copies the file at [from] (any path, read) to [to] (must be writable). |
| `move(String from, String to)` | `void` | Moves the file at [from] to [to]. |
| `delete(String path)` | `void` | Deletes the file or directory at [path] (must be writable). |

### SpecApi

The script-facing document API: every call delegates to the bound [SpecController], so a script mutation is mediated identically to a tool mutation (same change log + undo).

#### Constructors
```dart
const SpecApi(this.controller);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `controller` | `SpecController` | The live controller every read/mutation routes through. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `content(String path)` | `String?` | The content value at [path], or `null`. |
| `formField(String path, String field)` | `String?` | The form [field] value at [path], or `null`. |
| `listItems(String listPath)` | `List<String>` | The ordered item paths of the list at [listPath]. |
| `setContent(String path, String value)` | `void` | Sets the content at [path] (empty clears). |
| `setFormField(String path, String field, String value)` | `void` | Sets the form [field] at [path] (empty clears). |
| `addListItem(String listPath)` | `String` | Appends an item to the list at [listPath]; returns its new path. |
| `removeListItem(String itemPath)` | `bool` | Removes the list item at [itemPath]; returns whether one was removed. |
| `addChild(String parentPath, String childSegment, {String? itemId})` | `String` | Adds the model-permitted child [childSegment] under [parentPath]; returns the new node's path (throws on an illegal add). |

### SpecModelApi

The script-facing read-only reflection facade over a live [SpecModel]: every accessor reflects a section-id path against the meta-model.

#### Constructors
```dart
const SpecModelApi(this.model);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `model` | `SpecModel` | The read-only meta-model every reflection routes through. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `reflect(String path)` | `Map<String, Object?>` | The full reflection of the node at [path] as a JSON-friendly map: `path`, `resolved`, and (when resolved) `kind`, `classId`, `sectionId`, `mapsTo`, `detailedIn`, `headline`, `annotations`, and `allowedChildren`. |
| `resolves(String path)` | `bool` | Whether [path] resolves to a model node. |
| `kindOf(String path)` | `String?` | The node's render kind name (`root`/`complex`/`section`/`list`/`form`/ `content`/`scalar`/…), or `null` when [path] does not resolve. |
| `classOf(String path)` | `String?` | The model class the node *is* (`null` for value leaves / list containers / unresolved paths). |
| `sectionId(String path)` | `String?` | The node's `@SectionId` (field, class, or root), or `null`. |
| `mapsTo(String path)` | `String?` | The `@MapsTo` target on the node's class, or `null`. |
| `detailedIn(String path)` | `String?` | The `@DetailedIn` target on the node's class, or `null`. |
| `headline(String path)` | `String?` | The node's doc-comment / label headline, or `null`. |
| `allowedChildren(String path)` | `List<Map<String, Object?>>` | The model-permitted children of the node at [path] — the segments a `spec.addChild` / `doc_add_node` accepts, each a JSON-friendly map (`segment`, `field`, `kind`, `type`/`elementType`, `sectionIdPattern`, `enumValues`, `annotations`). |
| `annotations(String path)` | `List<Map<String, Object?>>` | The class-level annotations on the node at [path], each a JSON-friendly map (`name`, `arguments`). |

### SpecSearchApi

The script-facing `llm_and_d4rt_tools.md` §6 grep facility over a live [SpecQueryEngine]: open a cursor with [query] (full dimensions) or [grep] (text shorthand), then page it through the returned [SpecSearchCursor].

#### Constructors
```dart
const SpecSearchApi(this.engine);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `engine` | `SpecQueryEngine` | The `llm_and_d4rt_tools.md` §6 query facility over the live (model, document) pair. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `query(Map<Object?, Object?> args)` | `SpecSearchCursor` | Opens a cursor over the nodes matching the `llm_and_d4rt_tools.md` §6 query described by [args] (see [specQueryFromArgs] for the recognised dimensions). |

### SpecSearchCursor

A script-facing paging view over a `llm_and_d4rt_tools.md` §6 [SpecQueryCursor]: each match is projected to the same compact JSON map the `doc_search` MCP tool returns (`path`, `kind`, `classId`, `headline`, `snippet`, `spans`).

#### Constructors
```dart
const SpecSearchCursor(this.cursor);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `cursor` | `SpecQueryCursor` | The underlying edit-stable `llm_and_d4rt_tools.md` §6 cursor. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `next()` | `Map<String, Object?>?` | The next matching node as a JSON map, or `null` when exhausted. |
| `take(int n)` | `List<Map<String, Object?>>` | Up to [n] further matches (fewer when the cursor exhausts first). |
| `toList()` | `List<Map<String, Object?>>` | Every remaining match, draining the cursor. |
| `count()` | `int` | How many matches remain from the current position, re-validated against the live document, without consuming any. |

### MemoryApi

The script-facing recall facade: every call delegates to the bound [SpecRecall].

#### Constructors
```dart
const MemoryApi(this.recall);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `recall` | `SpecRecall` | The fused two-tier recall every query routes through. |

## Global Functions and Constants

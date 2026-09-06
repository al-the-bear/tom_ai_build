# TomSpecs CLI Tool API Reference: Gates

The four gates with a fixed subject: the three citation gates and the
release-set dependency-closure walker. Each resolves references that decay in
silence, and each is wired into the default `dart test` run.

For task-oriented guidance see [gates.md](../gates.md).

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [SectionHeading](#sectionheading)
  - [DocumentSections](#documentsections)
  - [SectionCorpus](#sectioncorpus)
  - [StaleSectionExemption](#stalesectionexemption)
  - [SectionCitation](#sectioncitation)
  - [SectionCitationReport](#sectioncitationreport)
  - [TodoRecord](#todorecord)
  - [TodoCorpus](#todocorpus)
  - [TodoCitation](#todocitation)
  - [TodoCitationVocabulary](#todocitationvocabulary)
  - [TodoCitationReport](#todocitationreport)
  - [OeRegister](#oeregister)
  - [OeCitation](#oecitation)
  - [OeCitationReport](#oecitationreport)
  - [ReleaseAllowEntry](#releaseallowentry)
  - [ReleaseManifest](#releasemanifest)
  - [ClosureViolation](#closureviolation)
  - [ClosureReport](#closurereport)
- [Enums](#enums)
  - [SectionQualifierSource](#sectionqualifiersource)
  - [SectionCitationVerdict](#sectioncitationverdict)
  - [SectionCitationExemption](#sectioncitationexemption)
  - [CitationVerdict](#citationverdict)
  - [CitationExemption](#citationexemption)
  - [ClosureEdgeKind](#closureedgekind)
  - [ClosureViolationKind](#closureviolationkind)
- [Global Functions and Constants](#global-functions-and-constants)

## Overview

The module declares **18 classes** and **7 enums** across 4 source file(s).

| Source file | Holds |
|-------------|-------|
| `section_citations.dart` | The `§` citation gate — `SectionHeading`, `DocumentSections`, `SectionCorpus`, `StaleSectionExemption`, `SectionCitation`, `SectionCitationReport`, `SectionQualifierSource`, `SectionCitationVerdict`, `SectionCitationExemption` |
| `todo_citations.dart` | The quest-todo citation gate — `TodoRecord`, `TodoCorpus`, `TodoCitation`, `TodoCitationVocabulary`, `TodoCitationReport`, `CitationVerdict`, `CitationExemption` |
| `oe_citations.dart` | The open-ends citation gate — `OeRegister`, `OeCitation`, `OeCitationReport` |
| `release_closure.dart` | The release-set closure walker — `ReleaseAllowEntry`, `ReleaseManifest`, `ClosureViolation`, `ClosureReport`, `ClosureEdgeKind`, `ClosureViolationKind` |

## Class Hierarchy

```
Object
├── SectionHeading
├── DocumentSections
├── SectionCorpus
├── StaleSectionExemption
├── SectionCitation
├── SectionCitationReport
├── TodoRecord
├── TodoCorpus
├── TodoCitation
├── TodoCitationVocabulary
├── TodoCitationReport
├── OeRegister
├── OeCitation
├── OeCitationReport
├── ReleaseAllowEntry
├── ReleaseManifest
├── ClosureViolation
└── ClosureReport
```

## Classes

### SectionHeading

One heading that carries a section id.

#### Constructors
```dart
const SectionHeading({
  required this.id,
  required this.level,
  required this.title,
  required this.line,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The id as written, `4.1.2` or `PF-FLW-OVE`. |
| `level` | `int` | Number of leading `#`. |
| `title` | `String` | The heading text after the id, or `''`. |
| `line` | `int` | 1-based line number. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### DocumentSections

The section ids one document declares.

#### Constructors
```dart
const DocumentSections({
  required this.path,
  required this.name,
  required this.byId,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | `String` | Absolute path of the document. |
| `name` | `String` | File name, which is what citations name. |
| `byId` | `Map<String, SectionHeading>` | Every id-carrying heading, keyed by id, in file order. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `declares(String id)` | `bool` | Whether a heading of this document declares [id]. |
| `parse(String markdown, {required String path})` | `DocumentSections` | Parses the id-carrying headings of [markdown]. |
| `read(String path)` | `DocumentSections` | Reads and parses [path]. |

### SectionCorpus

Every document a citation may resolve against.

#### Constructors
```dart
SectionCorpus(Iterable<DocumentSections> documents)
    : _byName = {for (final d in documents) d.name: d};
```

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `loadFolder(String docDir)` | `SectionCorpus` | Reads every `*.md` directly inside [docDir]. |

### StaleSectionExemption

An exhibit marker that suppressed nothing.

#### Constructors
```dart
const StaleSectionExemption({
  required this.file,
  required this.line,
  required this.id,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `file` | `String` | Path of the file the marker is in. |
| `line` | `int` | 1-based line number of the marker. |
| `id` | `String` | The id the marker named and nothing on the line needed. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `describe({String? relativeTo})` | `String` | A one-line, `file:line`-prefixed description suitable for a build log. |

### SectionCitation

One `§` citation.

#### Constructors
```dart
const SectionCitation({
  required this.id,
  required this.document,
  required this.source,
  required this.viaShortForm,
  required this.file,
  required this.line,
  required this.context,
  required this.verdict,
  this.exemption,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The section id as written, without the `§`. |
| `document` | `String?` | The document the citation resolves against, or `null` when bare. |
| `source` | `SectionQualifierSource` | How [document] was acquired. |
| `viaShortForm` | `bool` | True when the qualifier was written as the `SOM` short form. |
| `file` | `String` | Path of the file the citation is in. |
| `line` | `int` | 1-based line number. |
| `context` | `String` | The line's text, for the failure message. |
| `verdict` | `SectionCitationVerdict` | The verdict. |
| `exemption` | `SectionCitationExemption?` | The marker that excuses an unresolved verdict, or `null`. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `describe({String? relativeTo})` | `String` | A one-line, `file:line`-prefixed description suitable for a build log. |

### SectionCitationReport

The result of resolving a set of files.

#### Constructors
```dart
const SectionCitationReport({
  required this.citations,
  required this.files,
  required this.corpus,
  this.staleExemptions = const [],
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `citations` | `List<SectionCitation>` | Every citation found, in file then line order. |
| `files` | `List<String>` | The files scanned. |
| `corpus` | `SectionCorpus` | The corpus citations resolved against. |
| `staleExemptions` | `List<StaleSectionExemption>` | Exhibit markers that excused nothing. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `countOf(SectionCitationVerdict verdict)` | `int` | How many citations carry [verdict]. |

### TodoRecord

One todo as found in the corpus.

#### Constructors
```dart
const TodoRecord({
  required this.id,
  required this.stem,
  required this.status,
  required this.sourcePath,
  required this.closed,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The full id, e.g. |
| `stem` | `String` | The part before the first underscore — what documents cite. |
| `status` | `String` | The todo's `status:` field, or `''` when it has none. |
| `sourcePath` | `String` | Path of the todo file this record came from. |
| `closed` | `bool` | True when the todo is archived, deleted, completed or cancelled. |

### TodoCorpus

Every todo id reachable from a set of `*.todo.yaml` files.

#### Constructors
```dart
TodoCorpus._(this._byStem, this.seriesPrefixes, this.sourceFiles);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `seriesPrefixes` | `Set<String>` | The letter part of every stem in the corpus — `csrb`, `qr`, `tcca`, … Used only to phrase a failure: an unresolved `csrb99` is a wrong number in a series that exists, while an unresolved `csex7` is a series that never did. |
| `sourceFiles` | `List<String>` | The files that were read, in the order given. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `load(List<String> todoFiles)` | `TodoCorpus` | Reads every todo in [todoFiles]. |
| `questTodoFiles(String questDir)` | `List<String>` | The three todo files of a quest folder: active, archived, deleted. |

### TodoCitation

One todo-id citation found in one document line.

#### Constructors
```dart
const TodoCitation({
  required this.token,
  required this.stem,
  required this.file,
  required this.line,
  required this.verdict,
  this.matchedIds = const [],
  this.exemption,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `token` | `String` | The inline-code token exactly as written, e.g. |
| `stem` | `String` | The stem the token resolves through — equal to [token] unless a full id was cited. |
| `file` | `String` | Path of the document the citation is in. |
| `line` | `int` | 1-based line number. |
| `verdict` | `CitationVerdict` | The outcome of this check. |
| `matchedIds` | `List<String>` | The full on-disk ids [token] resolved to, in corpus order. |
| `exemption` | `CitationExemption?` | Set only when [verdict] is [CitationVerdict.closed] and the citation is marked. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `describe({String? relativeTo})` | `String` | A one-line, `file:line`-prefixed description suitable for a build log. |

### TodoCitationVocabulary

Tokens that share the todo-id shape but are not todo ids.

#### Constructors
```dart
const TodoCitationVocabulary(this.tokens);
const TodoCitationVocabulary.empty() : tokens = const {};

final Set<String> tokens;

bool contains(String token) => tokens.contains(token);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `tokens` | `Set<String>` | The tokens this entry declares. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `contains(String token)` | `bool` | Whether the allowlist holds `token`. |
| `load(String path)` | `TodoCitationVocabulary` | Reads a newline-separated token list. |

### TodoCitationReport

The result of checking a whole documentation folder.

#### Constructors
```dart
const TodoCitationReport({
  required this.citations,
  required this.documentCount,
  required this.corpus,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `citations` | `List<TodoCitation>` | Every citation found, in document then line order. |
| `documentCount` | `int` | Markdown files scanned. |
| `corpus` | `TodoCorpus` | The todo corpus every citation is resolved against. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `countOf(CitationVerdict verdict)` | `int` | How many citations reached `verdict`. |

### OeRegister

The ids the register defines, in the order the table declares them.

#### Constructors
```dart
const OeRegister._(this.ids, this.sourcePath, this.duplicates);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `ids` | `Set<String>` | Every defined id, e.g. |
| `sourcePath` | `String` | The document the register was read from. |
| `duplicates` | `List<String>` | Ids that appeared as a definition more than once. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `defines(String id)` | `bool` | Whether the register holds a row for `id`. |
| `parse(String markdown, {required String path})` | `OeRegister` | Reads the register out of [markdown]. |
| `read(String path)` | `OeRegister` | Reads the register from the document that owns it. |

### OeCitation

One `OE-` citation found in one line of one file.

#### Constructors
```dart
const OeCitation({
  required this.id,
  required this.file,
  required this.line,
  required this.defined,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The id exactly as written, e.g. |
| `file` | `String` | Path of the file the citation is in. |
| `line` | `int` | 1-based line number. |
| `defined` | `bool` | True when the register carries a row for [id]. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `describe({String? relativeTo})` | `String` | A one-line, `file:line`-prefixed description suitable for a build log. |

### OeCitationReport

The result of checking a whole corpus.

#### Constructors
```dart
const OeCitationReport({
  required this.citations,
  required this.fileCount,
  required this.register,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `citations` | `List<OeCitation>` | Every citation found, in file then line order. |
| `fileCount` | `int` | Files scanned. |
| `register` | `OeRegister` | The Open-Ends Register every citation is resolved against. |
| `citedIds` | `Set<String> get` | The distinct ids cited anywhere in the corpus. |

### ReleaseAllowEntry

One approved boundary crossing: a workspace-authored package already published to pub.dev.

#### Constructors
```dart
const ReleaseAllowEntry({required this.name, this.path, required this.reason});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Package name. |
| `path` | `String?` | Container-root-relative directory of the local source, when present in the workspace — the walk continues through it. |
| `reason` | `String` | Why the crossing is approved. |

### ReleaseManifest

The committed release-set manifest (`tool/release_set.yaml`).

#### Constructors
```dart
const ReleaseManifest({
  required this.releaseSet,
  required this.sourceOnly,
  required this.allow,
  required this.forbid,
  required this.workspacePrefixes,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `releaseSet` | `Map<String, String>` | Dart members: package name → container-root-relative directory. |
| `sourceOnly` | `List<String>` | Non-Dart members: container-root-relative directories, existence-checked. |
| `allow` | `Map<String, ReleaseAllowEntry>` | Approved published crossings, keyed by package name. |
| `forbid` | `List<String>` | Never-reachable names: exact, or `prefix*` for a prefix match. |
| `workspacePrefixes` | `List<String>` | Name prefixes treated as workspace-authored (everything else is third-party and permitted). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `isForbidden(String name)` | `bool` | Whether [name] matches a forbid pattern. |
| `isWorkspaceLocal(String name)` | `bool` | Whether [name] looks workspace-authored. |
| `load(String path)` | `ReleaseManifest` | Loads and shape-checks the manifest at [path]. |
| `stringMap(String key)` | `Map<String, String>` | The argument read as a `Map<String, String>`. |
| `stringList(String key)` | `List<String>` | The argument read as a `List<String>`. |

### ClosureViolation

One violation, naming the offending edge.

#### Constructors
```dart
const ClosureViolation({
  required this.kind,
  required this.from,
  required this.to,
  this.edgeKind,
  required this.detail,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `kind` | `ClosureViolationKind` | The declared kind. |
| `from` | `String` | The package (or `manifest`) the edge leaves from. |
| `to` | `String` | The dependency name (or path) the edge lands on. |
| `edgeKind` | `ClosureEdgeKind?` | How the offending edge was classified, or `null` when the problem is the manifest itself. |
| `detail` | `String` | The offending edge, or the manifest problem, in one line. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `describe()` | `String` | A one-line rendering naming the package, the edge and why it is not allowed. |

### ClosureReport

The result of one closure walk.

#### Constructors
```dart
const ClosureReport({
  required this.violations,
  required this.packagesWalked,
  required this.approvedCrossings,
  required this.edgesChecked,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `violations` | `List<ClosureViolation>` | Every violation the pass found. |
| `packagesWalked` | `int` | Release-set members whose pubspec was walked. |
| `approvedCrossings` | `int` | Distinct allowed packages actually reached. |
| `edgesChecked` | `int` | Dependency edges classified (all kinds). |

## Enums

### SectionQualifierSource

How a citation acquired its document name.

| Value | Meaning |
|-------|---------|
| `bare` | No document name governs it — it means the file it is written in. |
| `leading` | A document name stands immediately before it, possibly across a soft wrap. |
| `externalStandard` | A public-standard designator stands immediately before it — the citation is of a standard's clause, not of a document in this set. |
| `trailing` | The name follows it: `§11 of `llm_and_d4rt_tools.md``. |
| `run` | Inherited from the citation it follows in a run. |
| `tableRow` | Taken from the first cell of a document-map table row. |
| `tableColumn` | Taken from the header cell of the column the citation sits in. |

### SectionCitationVerdict

What the resolver concluded about one citation.

| Value | Meaning |
|-------|---------|
| `self` | Bare, and the id resolves in the document it is written in — the self-reference `index.md` carves out. |
| `crossDocument` | Qualified, and the id resolves in the document it names. |
| `dangling` | Bare, and no heading of its own document declares the id. |
| `wrongSection` | Qualified, but the named document declares no such section — a number that moved, or one carried across from a third document. |
| `unverifiable` | Qualified with a document the corpus does not hold, so nothing can be concluded. |

### SectionCitationExemption

Why a `§` that resolves to no heading is nonetheless not a defect.

| Value | Meaning |
|-------|---------|
| `exhibit` | `<!-- section-cite: exhibit … -->` — the ids the marker names on this line are specimens of the citation syntax, written by a file that documents the convention. |

### CitationVerdict

What the checker concluded about one citation.

| Value | Meaning |
|-------|---------|
| `open` | Resolves to exactly one todo, and it is still open. |
| `closed` | Resolves to exactly one todo, and it is archived, deleted, completed or cancelled — the document points a reader at finished work. |
| `ambiguous` | Resolves to **several** todos, because the campaign that produced them restarted its numbering and the citation dropped the date code that tells them apart. |
| `unresolved` | The series exists in the corpus but this number does not: a typo, or an id that was renamed. |
| `unknownSeries` | Nothing in the corpus uses this series at all — an invented id, or a corpus that is missing the quest it belongs to. |

### CitationExemption

Why a [CitationVerdict.closed] citation is allowed to stand.

| Value | Meaning |
|-------|---------|
| `provenance` | `<!-- todo-cite: provenance -->` — the id names who raised an item, or the prerequisite that unblocked it, not what is open. |
| `history` | `<!-- todo-cite: history -->` — the whole document is a history record. |

### ClosureEdgeKind

What kind of edge carried the violation.

| Value | Meaning |
|-------|---------|
| `forbidden` | The edge lands on a name a forbid pattern names. |
| `unapprovedWorkspace` | The edge leaves the set for a workspace-local package that is neither a member nor an approved crossing. |
| `pathMismatch` | A `path:` dependency resolves somewhere other than the manifest's directory for that name. |
| `manifest` | The manifest contradicts itself or the tree: an allow/member entry matching a forbid pattern, a missing pubspec, a pubspec whose `name:` disagrees with its manifest key, or a missing source-only directory. |

### ClosureViolationKind

The distinct ways the closure can fail.

| Value | Meaning |
|-------|---------|
| `forbidden` | The edge lands on a name a forbid pattern names. |
| `unapprovedWorkspace` | The edge leaves the set for a workspace-local package that is neither a member nor an approved crossing. |
| `pathMismatch` | A `path:` dependency resolves somewhere other than the manifest's directory for that name. |
| `manifest` | The manifest contradicts itself or the tree: an allow/member entry matching a forbid pattern, a missing pubspec, a pubspec whose `name:` disagrees with its manifest key, or a missing source-only directory. |

## Global Functions and Constants

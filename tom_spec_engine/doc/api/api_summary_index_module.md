# TomSpecs Engine API Reference: Index Module

The tier-1 structural / lexical index: an inverted BM25 text index plus
structural facets, built directly from the object model with **zero model
calls**.

For task-oriented guidance see [searching.md](../searching.md). For what the
tier *is*, see
[`llm_and_d4rt_tools.md`](../../../tom_specs_model/doc/llm_and_d4rt_tools.md) §6.

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [IndexQuery](#indexquery)
  - [IndexHit](#indexhit)
  - [IndexUpdateStats](#indexupdatestats)
  - [StructuralLexicalIndex](#structurallexicalindex)
- [Enums](#enums)
  - [IndexStateFilter](#indexstatefilter)
- [Global Functions and Constants](#global-functions-and-constants)

## Overview

The module declares **4 classes** and **1 enums** across 1 source file(s).

| Source file | Holds |
|-------------|-------|
| `structural_lexical_index.dart` | The index, its query and its hits — `IndexQuery`, `IndexHit`, `IndexUpdateStats`, `StructuralLexicalIndex`, `IndexStateFilter` |

## Class Hierarchy

```
Object
├── IndexQuery
├── IndexHit
├── IndexUpdateStats
└── StructuralLexicalIndex
```

## Classes

### IndexQuery

An AND-combined query over the tier-1 index: an optional BM25 [text] match plus structural facet filters.

#### Constructors
```dart
const IndexQuery({
  this.text,
  this.kinds,
  this.className,
  this.sectionIdExact,
  this.sectionIdPrefix,
  this.mapsTo,
  this.detailedIn,
  this.state,
  this.limit,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `text` | `String?` | Free text; tokenised and scored by BM25 over the indexed section text. |
| `kinds` | `Set<SpecNodeKind>?` | The node kinds to include (any-of); `null` admits every kind. |
| `className` | `String?` | The model class a node must *be*. |
| `sectionIdExact` | `String?` | The node's `@SectionId` must equal this exactly. |
| `sectionIdPrefix` | `String?` | The node's `@SectionId` must start with this prefix. |
| `mapsTo` | `String?` | The node's class must carry `@MapsTo(<this>)`. |
| `detailedIn` | `String?` | The node's class must carry `@DetailedIn(<this>)`. |
| `state` | `IndexStateFilter?` | The node's value-presence state must match this. |

### IndexHit

One ranked match from [StructuralLexicalIndex.search].

#### Constructors
```dart
const IndexHit({
  required this.path,
  required this.kind,
  this.classId,
  this.headline,
  required this.score,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | `String` | The section-id path of the matched node. |
| `kind` | `SpecNodeKind` | The node kind. |
| `classId` | `String?` | The model class the node *is* (`null` for leaves / containers). |
| `headline` | `String?` | The node's doc-comment / label headline (`null` when none). |
| `score` | `double` | The BM25 relevance score (`0.0` for facet-only matches). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### IndexUpdateStats

What an [StructuralLexicalIndex.update] changed, so callers (and tests) can verify the refresh was incremental.

#### Constructors
```dart
const IndexUpdateStats({this.added = 0, this.updated = 0, this.removed = 0});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `added` | `int` | Sections newly indexed (a path not previously present). |
| `updated` | `int` | Sections re-indexed in place (a path already present). |
| `removed` | `int` | Sections dropped from the index. |

### StructuralLexicalIndex

The tier-1 inverted index + structural facet store.

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `termsOf(String path)` | `Set<String>` | The distinct lexical terms indexed for the section at [path] (empty when the path is not indexed). |
| `lookup(String path)` | `IndexHit?` | The indexed hit (kind / class / headline, zero score) for the section at [path], or `null` when the path is not indexed. |
| `rebuild(Iterable<SpecNodeProjection> nodes)` | `void` | Replaces the entire index with [nodes] (a full rebuild). |
| `search(IndexQuery query)` | `List<IndexHit>` | Searches the index, returning hits ranked by BM25 (text queries) or in path order (facet-only queries), after AND-combining all facet filters. |

## Enums

### IndexStateFilter

The value-presence facet of an [IndexQuery].

| Value | Meaning |
|-------|---------|
| `empty` | The node currently holds no value. |
| `nonEmpty` | The node currently holds at least one value. |

## Global Functions and Constants

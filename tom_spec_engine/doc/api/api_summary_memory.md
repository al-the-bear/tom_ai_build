# TomSpecs Engine API Reference: Memory Module

The two-tier RAG memory plane — vector recall and the structural graph — and
the fusing front door that degrades rather than failing when a tier is absent.

For task-oriented guidance see [memory.md](../memory.md), including the
**vector-runtime precondition**. For what the plane *is*, see
[`llm_and_d4rt_tools.md`](../../../tom_specs_model/doc/llm_and_d4rt_tools.md)
§9 and §10.

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [SpecRecallHit](#specrecallhit)
  - [SpecRecallResult](#specrecallresult)
  - [SpecRecallQuery](#specrecallquery)
  - [SpecRecall](#specrecall)
  - [RememberedItem](#remembereditem)
  - [SpecRagIndexResult](#specragindexresult)
  - [SpecRagRefreshResult](#specragrefreshresult)
  - [SpecRagHit](#specraghit)
  - [SpecRagStoredEdge](#specragstorededge)
  - [SpecMemory](#specmemory)
  - [SpecDocumentMemory](#specdocumentmemory)
  - [SpecRagNode](#specragnode)
  - [SpecRagEdge](#specragedge)
  - [SpecRagGraph](#specraggraph)
  - [SpecReindexResult](#specreindexresult)
  - [SpecIncrementalIndexer](#specincrementalindexer)
  - [SpecProviderEmbedder](#specproviderembedder)
  - [MemoryScope](#memoryscope)
- [Enums](#enums)
  - [SpecRecallMode](#specrecallmode)
  - [SpecRagEdgeKind](#specragedgekind)
- [Global Functions and Constants](#global-functions-and-constants)

## Overview

The module declares **18 classes** and **2 enums** across 6 source file(s).

| Source file | Holds |
|-------------|-------|
| `spec_recall.dart` | The fusing front door — `SpecRecallHit`, `SpecRecallResult`, `SpecRecallQuery`, `SpecRecall`, `SpecRecallMode` |
| `spec_memory.dart` | The store-backed memory surface — `RememberedItem`, `SpecRagIndexResult`, `SpecRagRefreshResult`, `SpecRagHit`, `SpecRagStoredEdge`, `SpecMemory`, `SpecDocumentMemory` |
| `spec_rag_graph.dart` | The structural graph tier — `SpecRagNode`, `SpecRagEdge`, `SpecRagGraph`, `SpecRagEdgeKind` |
| `incremental_indexer.dart` | Incremental re-indexing — `SpecReindexResult`, `SpecIncrementalIndexer` |
| `provider_embedder.dart` | The embedder adapter — `SpecProviderEmbedder` |
| `memory_scope.dart` | The memory scope binding — `MemoryScope` |

## Class Hierarchy

```
Object
├── SpecRecallHit
├── SpecRecallResult
├── SpecRecallQuery
├── SpecRecall
├── RememberedItem
├── SpecRagIndexResult
├── SpecRagRefreshResult
├── SpecRagHit
├── SpecRagStoredEdge
├── SpecMemory
├── SpecDocumentMemory
├── SpecRagNode
├── SpecRagEdge
├── SpecRagGraph
├── SpecReindexResult
├── SpecIncrementalIndexer
├── SpecProviderEmbedder
└── MemoryScope
```

## Classes

### SpecRecallHit

One fused-recall hit: a section path, its fused (RRF) score, and which modes surfaced it.

#### Constructors
```dart
const SpecRecallHit({
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
| `path` | `String` | The section-id path of the recalled section. |
| `score` | `double` | The fused Reciprocal-Rank-Fusion score (higher = more relevant). |
| `modes` | `Set<SpecRecallMode>` | The modes that surfaced this section. |
| `kind` | `SpecNodeKind?` | The node kind (from the tier-1 index), `null` when the section is known only from the vector tier. |
| `headline` | `String?` | The doc-comment / label headline (from the tier-1 index), `null` when unknown. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### SpecRecallResult

The fused-recall result: the ranked hits plus whether the vector tier contributed.

#### Constructors
```dart
const SpecRecallResult({required this.hits, required this.tier2Warm});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `hits` | `List<SpecRecallHit>` | The fused, optionally MMR-diversified hits, best first, at most `k`. |
| `tier2Warm` | `bool` | Whether tier 2 (vector) surfaced at least one candidate. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### SpecRecallQuery

A fused-recall request: the query text, optional structural facets, the result cap, and the RRF / MMR / GraphWalk knobs.

#### Constructors
```dart
const SpecRecallQuery({
  required this.text,
  this.facets = const IndexQuery(),
  this.k = 10,
  this.perModeK = 64,
  this.rrfK = 60,
  this.weights = const <SpecRecallMode, double>{},
  this.graphWalk = false,
  this.graphWalkDepth = 1,
  this.diversify = true,
  this.mmrLambda = 0.7,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `text` | `String` | Free text scored by tier-1 BM25 and (when bound) the tier-2 vector model. |
| `facets` | `IndexQuery` | Structural constraints shared by the lexical and symbolic modes. |
| `k` | `int` | Post-fusion cap on the returned hits. |
| `perModeK` | `int` | Per-mode candidate cap, before fusion. |
| `rrfK` | `int` | RRF smoothing constant (the `tom_brain_memory` default is 60). |
| `weights` | `Map<SpecRecallMode, double>` | Per-mode fusion weight. |
| `graphWalk` | `bool` | Whether to run the optional GraphWalk mode (needs a graph on [SpecRecall]). |
| `graphWalkDepth` | `int` | Maximum hop count for the GraphWalk mode. |
| `diversify` | `bool` | Whether to apply the MMR diversity pass over the fused list. |
| `mmrLambda` | `double` | MMR's lambda: 1.0 favours pure relevance, 0.0 favours pure diversity. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `weightOf(SpecRecallMode mode)` | `double` | The fusion weight for `mode`, from `weights` or the mode's default. |

### SpecRecall

Fuses the tier-1 index, the tier-2 vector store, and the section graph into one ranked recall.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | `String` | The section-id path of the recalled section. |
| `score` | `double` | The fused Reciprocal-Rank-Fusion score (higher = more relevant). |
| `modes` | `Set<SpecRecallMode>` | The modes that surfaced this section. |
| `kind` | `SpecNodeKind?` | The node kind (from the tier-1 index), `null` when the section is known only from the vector tier. |
| `headline` | `String?` | The doc-comment / label headline (from the tier-1 index), `null` when unknown. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### RememberedItem

One item recalled from a document's memory.

#### Constructors
```dart
const RememberedItem({required this.text});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `text` | `String` | The remembered text (the carrier node's `summary`). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### SpecRagIndexResult

What [SpecDocumentMemory.indexDocument] wrote: the section nodes persisted and the tree/projection edges linked.

#### Constructors
```dart
const SpecRagIndexResult({required this.nodeCount, required this.edgeCount});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `nodeCount` | `int` | Section nodes persisted (one per [SpecRagNode]). |
| `edgeCount` | `int` | Edges linked (tree + resolved projections). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### SpecRagRefreshResult

What [SpecDocumentMemory.indexChangedSections] did: how many sections were re-embedded, how many edges were re-linked, and how many sections were dropped.

#### Constructors
```dart
const SpecRagRefreshResult({
  required this.embedded,
  required this.unchanged,
  required this.edgeCount,
  required this.removed,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `embedded` | `int` | Sections re-embedded and re-persisted (content actually changed). |
| `unchanged` | `int` | Sections skipped because their content hash was unchanged. |
| `edgeCount` | `int` | Edges (re-)linked for the touched sections. |
| `removed` | `int` | Sections forgotten (removed from memory). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### SpecRagHit

One section recalled from a document's RAG memory.

#### Constructors
```dart
const SpecRagHit({required this.path, required this.text});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | `String` | The section-id path of the recalled section. |
| `text` | `String` | The rendered section text (metadata header + content). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### SpecRagStoredEdge

One persisted RAG edge, read back with its endpoints mapped to section paths.

#### Constructors
```dart
const SpecRagStoredEdge({required this.toPath, required this.partOf});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `toPath` | `String` | The destination section's path. |
| `partOf` | `bool` | Whether the edge is a `part_of` tree edge (`false` = a `mentions` projection edge). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### SpecMemory

In-process, profile-isolated Tom Brain memory for the TomSpecs engine.

#### Constructors
```dart
SpecMemory({
  required this.memoryRoot,
  required this.sqliteVecBinariesRoot,
  required SpecEmbedder embedder,
  SpecBatchEmbedder? batchEmbedder,
})  : _embedder = embedder,
      _batchEmbedder = batchEmbedder;
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `memoryRoot` | `String` | Root directory of the Tom Brain memory store (`<memory-root>`). |
| `sqliteVecBinariesRoot` | `String` | Directory holding the platform-tupled sqlite-vec (vec0) binaries (`<…>/tom_binaries/sqlite_vec`). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `embed(String text)` | `Future<Vec>` | The façade's embedding surface. |
| `openDocument(MemoryScope scope)` | `Future<SpecDocumentMemory>` | Opens (materialising on first use) the profile-isolated memory for [scope]'s document and returns a handle bound to it. |
| `close()` | `Future<void>` | Closes every open document handle. |

### SpecDocumentMemory

A handle bound to one document's profile-isolated Tom Brain memory.

#### Constructors
```dart
SpecDocumentMemory._({
  required this.scope,
  required SqliteTomBrainMemory store,
  required SpecEmbedder embedder,
  SpecBatchEmbedder? batchEmbedder,
})  : _store = store,
      _embedder = embedder,
      _batchEmbedder = batchEmbedder;
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `scope` | `MemoryScope` | The scope this handle is bound to. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `embed(String text)` | `Future<Vec>` | Embeds [text] through the same embedder the store recalls with. |
| `recall(String query, {int k = 10})` | `Future<List<RememberedItem>>` | Recalls items matching [query] from this document's memory via the vector index (the store embeds [query] through the shared embedder). |
| `indexDocument(SpecRagGraph graph)` | `Future<SpecRagIndexResult>` | Indexes a document's section-level RAG [graph] into this document's named memory (`llm_and_d4rt_tools.md` §9.1): each [SpecRagNode] is persisted as a [_sectionType] node (`name` = section path, `description` = rendered text), embedded so it is recoverable by vector recall, then each [SpecRagEdge] is linked (`part_of` for the tree, `mentions` for projections). |
| `recallSections(String query, {int k = 10})` | `Future<List<SpecRagHit>>` | Recalls the sections most relevant to [query] from this document's RAG memory via the vector index (the store embeds [query] through the shared embedder). |
| `edgesFrom(String path)` | `Future<List<SpecRagStoredEdge>>` | Returns the outgoing RAG edges of the section at [path] (the edges this section *emits*), with endpoints mapped back to section paths. |

### SpecRagNode

One section node in the RAG graph: a section-id path plus the rendered text and structural metadata a retriever indexes.

#### Constructors
```dart
const SpecRagNode({
  required this.path,
  required this.sectionId,
  required this.kind,
  required this.classId,
  required this.headline,
  required this.parentPath,
  required this.mapsTo,
  required this.detailedIn,
  required this.text,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | `String` | The section-id path that uniquely identifies the section (and the node). |
| `sectionId` | `String?` | The section's `@SectionId` (`null` for synthetic / unlabelled nodes). |
| `kind` | `SpecNodeKind` | The node kind from the object-model projection. |
| `classId` | `String?` | The model class the node *is* (`null` for leaves / containers). |
| `headline` | `String?` | The doc-comment / label headline (`null` when none). |
| `parentPath` | `String?` | The structural parent's path (`null` for the document root). |
| `mapsTo` | `String?` | The `@MapsTo` target section id declared on the node's class (`null` when none). |
| `detailedIn` | `String?` | The `@DetailedIn` target section id declared on the node's class (`null` when none). |
| `text` | `String` | The rendered text a retriever embeds: a metadata header (path, section id, kind, class, headline) followed by the section's searchable content. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### SpecRagEdge

One directed edge between two section nodes.

#### Constructors
```dart
const SpecRagEdge({
  required this.fromPath,
  required this.toPath,
  required this.kind,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `fromPath` | `String` | The source section's path. |
| `toPath` | `String` | The destination section's path. |
| `kind` | `SpecRagEdgeKind` | What the edge represents. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### SpecRagGraph

The assembled section-level RAG graph for one document: a node per section and the tree + projection edges between them.

#### Constructors
```dart
const SpecRagGraph({required this.nodes, required this.edges});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `nodes` | `List<SpecRagNode>` | The section nodes, in projection (document) order. |
| `edges` | `List<SpecRagEdge>` | The directed edges: tree membership plus resolved projections. |

### SpecReindexResult

What one [SpecIncrementalIndexer.flush] did, so callers (and tests) can confirm the refresh was incremental and which paths it touched.

#### Constructors
```dart
const SpecReindexResult({
  required this.tier1,
  required this.tier2,
  required this.changedPaths,
  required this.removedPaths,
});
const SpecReindexResult.empty()
    : tier1 = const IndexUpdateStats(),
      tier2 = null,
      changedPaths = const <String>{},
      removedPaths = const <String>{};
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `tier1` | `IndexUpdateStats` | The tier-1 [StructuralLexicalIndex.update] outcome. |
| `tier2` | `SpecRagRefreshResult?` | The tier-2 [SpecDocumentMemory.indexChangedSections] outcome, or `null` when no tier-2 callback is bound (tier-1-only / degraded). |
| `changedPaths` | `Set<String>` | Dirty paths that resolved to a live section (re-indexed, not removed). |
| `removedPaths` | `Set<String>` | Dirty paths absent from the current projection (dropped from both tiers). |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### SpecIncrementalIndexer

Accumulates dirty section paths and, after a debounce, drives the tier-1 + tier-2 incremental re-index off the edit path.

#### Constructors
```dart
SpecIncrementalIndexer({
  required this.index,
  required this.projections,
  this.tier2,
  this.debounce = const Duration(milliseconds: 150),
  this.onReindexed,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `index` | `StructuralLexicalIndex` | The tier-1 inverted index this refreshes in place. |
| `projections` | `SpecProjectionsProvider` | Supplies the document's current projection on each [flush]. |
| `tier2` | `SpecTier2Reindex?` | The tier-2 re-embed callback, or `null` for tier-1-only mode. |
| `debounce` | `Duration` | How long a quiet window must pass after the last [touch] before the debounced [flush] fires. |
| `pendingPaths` | `Set<String> get` | The paths awaiting the next flush (read-only snapshot). |
| `tier2Result` | `SpecRagRefreshResult?` | The vector tier's refresh outcome, or `null` when that tier was not run. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `touch(Iterable<String> paths)` | `void` | Marks [paths] dirty and (re-)arms the debounce timer. |
| `flush()` | `Future<SpecReindexResult>` | Flushes the pending set **now** (cancelling the debounce), returning what the re-index did. |
| `reindexAll(Iterable<String> paths)` | `Future<SpecReindexResult>` | Forces a **full current-state reconcile** of [paths] (a manual `mem_refresh`, `llm_and_d4rt_tools.md` §9.2) through the **same serialized chain** as the debounced [flush], so a manual refresh can never race an in-flight incremental flush. |
| `dispose()` | `void` | Cancels any pending debounce and stops accepting touches. |

### SpecProviderEmbedder

Adapts a Tom Brain [EmbeddingService] to the engine's embedding surfaces.

#### Constructors
```dart
SpecProviderEmbedder(this.service) : _onClose = null;

SpecProviderEmbedder._({
  required this.service,
  required Future<void> Function()? onClose,
}) : _onClose = onClose;
SpecProviderEmbedder._({
  required this.service,
  required Future<void> Function()? onClose,
}) : _onClose = onClose;
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `service` | `EmbeddingService` | The wrapped substrate embedding service. |
| `identity` | `EmbeddingModelIdentity get` | The identity every vector this embedder produces is stamped with. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `close()` | `Future<void>` | Closes the wrapped service and any collaborator the factory built. |

### MemoryScope

Addresses a unit of agent work across the three isolation levels the TomSpecs engine establishes over Tom Brain (`llm_and_d4rt_tools.md` §9 / §11): * [application] → a Tom Brain **profile** (the prompt / tool / MCP bundle an agent runs under).

#### Constructors
```dart
MemoryScope({
  required this.application,
  required this.session,
  required this.document,
}) {
  _validateSegment('application', application);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `application` | `String` | The agent application this work belongs to (→ Tom Brain profile). |
| `session` | `String` | The phase/task run within the application (→ Tom Brain named session). |
| `document` | `String` | The document under work — the memory partition (→ Tom Brain named memory). |
| `profileName` | `String get` | The Tom Brain memory profile this scope binds to. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

## Enums

### SpecRecallMode

Which retrieval mode surfaced a section in a fused recall.

| Value | Meaning |
|-------|---------|
| `lexical` | Tier-1 BM25 full-text match over the indexed section text. |
| `symbolic` | Tier-1 structural facet match (kind / class / section-id / `@MapsTo` / `@DetailedIn` / state) — the "symbolic" mode of the recall contract. |
| `vector` | Tier-2 vector / semantic match from the Tom Brain named-memory store. |
| `graphWalk` | Bounded-depth walk over the section graph's tree + projection edges, expanding from the seeds the other modes surfaced. |

### SpecRagEdgeKind

How one section relates to another in the RAG graph.

| Value | Meaning |
|-------|---------|
| `tree` | Structural membership — a child section is `part_of` its parent (`llm_and_d4rt_tools.md` §9.1 "edges mirror the tree"). |
| `mapsTo` | A `@MapsTo` projection — the source class declares it maps to the target section (a `mentions` reference). |
| `detailedIn` | A `@DetailedIn` projection — the source class declares it is detailed in the target section (a `mentions` reference). |

## Global Functions and Constants

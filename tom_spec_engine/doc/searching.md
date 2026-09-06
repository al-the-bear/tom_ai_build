# TomSpecs Engine — Searching a Specification

Finding the right section in a three-thousand-section specification is the
engine's most-used capability, and the one that costs nothing: the structural /
lexical index is built directly from the object model with **zero model calls**.
This guide covers building it, querying it by text and by structure, refreshing
it incrementally, and when to reach past it to the RAG memory plane. What each
tier *is* is
[`llm_and_d4rt_tools.md`](../../tom_specs_model/doc/llm_and_d4rt_tools.md) §6
and §9; this guide states the API and cites that.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
  - [StructuralLexicalIndex](#structurallexicalindex)
  - [IndexQuery — text plus facets](#indexquery--text-plus-facets)
- [Searching by structure](#searching-by-structure)
- [Refreshing incrementally](#refreshing-incrementally)
- [When to reach for the memory plane](#when-to-reach-for-the-memory-plane)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

The index is **tier 1**: an inverted BM25 text index plus structural facets,
built from the document's node projections. No embedding, no network, no LLM —
so it is cheap enough to rebuild on demand and correct enough to answer most
questions on its own.

The facets are what make it more than a text search. A node projection carries
its path, kind, model class, section id, traceability links and value-presence
state, so *"every unfilled requirement section"* is a query rather than a scan.

A hit carries the **section path**, which means it is addressable in the
document — you can navigate to it, edit it, or feed it to a script — rather than
being a loose snippet.

## Quick Start

```dart
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

SpecModel buildModel() => SpecModel.fromJson({
      'modelVersion': 1,
      'roots': [
        {'type': 'ProjectDefinition', 'title': 'Project Definition',
         'sectionId': 'PD00'},
      ],
      'classes': {
        'ProjectDefinition': {
          'name': 'ProjectDefinition',
          'sectionId': 'PD00',
          'fields': [
            {'name': 'vision', 'kind': 'content', 'sectionId': 'VIS'},
            {'name': 'summary', 'kind': 'content', 'sectionId': 'SUM'},
            {'name': 'situation', 'kind': 'complex', 'sectionId': 'SIT',
             'type': 'CurrentSituation'},
          ],
        },
        'CurrentSituation': {
          'name': 'CurrentSituation',
          'sectionId': 'CS00',
          'fields': [
            {'name': 'detail', 'kind': 'content', 'sectionId': 'DET'},
          ],
        },
      },
    });

void main() {
  final model = buildModel();
  final doc = SpecDocument()
    ..setContent('PD00/VIS', 'resilient rollout platform resilient')
    ..setContent('PD00/SUM', 'a resilient platform overview')
    ..setContent('PD00/SIT/DET', 'current platform situation');

  final engine = SpecQueryEngine(model: model, document: doc);
  final index = StructuralLexicalIndex()..rebuild(engine.projectNodes());

  for (final hit in index.search(const IndexQuery(text: 'resilient'))) {
    print(hit.path);
  }
  print(index.search(const IndexQuery(text: 'kubernetes')).isEmpty);
}
```

Output:

```
PD00/VIS
PD00/SUM
true
```

`PD00/VIS` ranks first because it carries the term twice — BM25, not insertion
order. A term nothing carries returns an empty list rather than an error.

## Core Components

### `StructuralLexicalIndex`

| Member | Does |
|--------|------|
| `rebuild(Iterable<SpecNodeProjection>)` | Builds the whole index from a document's node projections |
| `search(IndexQuery)` | Returns ranked `IndexHit`s |

The projections come from `SpecQueryEngine.projectNodes()` in
`tom_som_dart_runtime` — the same flat tier-1 projection the runtime already
produces, so the index does not re-walk the model.

An `IndexHit` carries `path`, `kind` and `score`. The score is comparable
*within one result list* and is not meaningful across queries.

### `IndexQuery` — text plus facets

Every field is optional, and they compose: text narrows by term, facets narrow
by shape, and giving both means both must hold.

| Field | Type | Narrows to |
|-------|------|-----------|
| `text` | `String?` | Sections whose text matches (BM25-ranked) |
| `kinds` | `Set<SpecNodeKind>?` | These node kinds |
| `className` | `String?` | Nodes of this model class |
| `sectionIdExact` | `String?` | This exact section id |
| `sectionIdPrefix` | `String?` | Section ids starting with this |
| `mapsTo` | `String?` | Nodes whose `@MapsTo` names this document |
| `detailedIn` | `String?` | Nodes whose `@DetailedIn` names this document |
| `state` | `IndexStateFilter?` | Filled or unfilled sections |
| `limit` | `int?` | At most this many hits |

## Searching by structure

The facets are the reason to reach for this over a text search. A structural
query needs no text at all:

```dart
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

SpecModel buildModel() => SpecModel.fromJson({
      'modelVersion': 1,
      'roots': [
        {'type': 'ProjectDefinition', 'title': 'Project Definition',
         'sectionId': 'PD00'},
      ],
      'classes': {
        'ProjectDefinition': {
          'name': 'ProjectDefinition',
          'sectionId': 'PD00',
          'fields': [
            {'name': 'vision', 'kind': 'content', 'sectionId': 'VIS'},
            {'name': 'situation', 'kind': 'complex', 'sectionId': 'SIT',
             'type': 'CurrentSituation'},
          ],
        },
        'CurrentSituation': {
          'name': 'CurrentSituation',
          'sectionId': 'CS00',
          'mapsTo': 'PD00',
          'fields': [
            {'name': 'detail', 'kind': 'content', 'sectionId': 'DET'},
          ],
        },
      },
    });

void main() {
  final model = buildModel();
  final doc = SpecDocument()..setContent('PD00/VIS', 'a vision');
  final index = StructuralLexicalIndex()
    ..rebuild(SpecQueryEngine(model: model, document: doc).projectNodes());

  // Every node of one model class — no text involved.
  print(index.search(const IndexQuery(className: 'CurrentSituation'))
      .map((h) => h.path)
      .toList());

  // Every content node, whatever it says.
  print(index.search(const IndexQuery(kinds: {SpecNodeKind.content}))
      .map((h) => h.path)
      .toList());

  // One section id.
  print(index.search(const IndexQuery(sectionIdExact: 'VIS'))
      .map((h) => h.path)
      .toList());
}
```

Output:

```
[PD00/SIT]
[PD00/SIT/DET, PD00/VIS]
[PD00/VIS]
```

Two things to read off that. The root `PD00` is absent from the second result
because a root is not a content node — the kind facet filters on what a node
*is*, not on whether it has text. And the order is not document order: with no
`text` term there is nothing to rank by, so a facet-only query returns its
matches in the index's own order. Sort them yourself if the order is meant to
carry information.

## Refreshing incrementally

`rebuild` is a full build. For an editor that edits one section at a time,
`IncrementalIndexer` refreshes only what changed and reports what it touched, so
a caller can tell a cheap edit from an expensive one:

```dart
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

SpecModel buildModel() => SpecModel.fromJson({
      'modelVersion': 1,
      'roots': [
        {'type': 'ProjectDefinition', 'title': 'Project Definition',
         'sectionId': 'PD00'},
      ],
      'classes': {
        'ProjectDefinition': {
          'name': 'ProjectDefinition',
          'sectionId': 'PD00',
          'fields': [
            {'name': 'vision', 'kind': 'content', 'sectionId': 'VIS'},
            {'name': 'summary', 'kind': 'content', 'sectionId': 'SUM'},
          ],
        },
      },
    });

void main() {
  final model = buildModel();
  final doc = SpecDocument()
    ..setContent('PD00/VIS', 'resilient rollout')
    ..setContent('PD00/SUM', 'an overview');

  final engine = SpecQueryEngine(model: model, document: doc);
  final index = StructuralLexicalIndex()..rebuild(engine.projectNodes());

  print(index.search(const IndexQuery(text: 'kubernetes')).isEmpty);

  // Edit one section, then rebuild from the fresh projections.
  doc.setContent('PD00/SUM', 'a kubernetes overview');
  index.rebuild(SpecQueryEngine(model: model, document: doc).projectNodes());

  print(index.search(const IndexQuery(text: 'kubernetes'))
      .map((h) => h.path)
      .toList());
}
```

Output:

```
true
[PD00/SUM]
```

## When to reach for the memory plane

The index answers *"which sections contain these words, or have this shape?"*.
It cannot answer *"how are order lines amended?"* when the specification never
uses those words. That is what the two-tier RAG memory plane is for, and it is
the point at which a run stops being free:

| Want | Reach for | Cost |
|------|-----------|------|
| Terms, ids, kinds, traceability, filled/unfilled | `StructuralLexicalIndex` | Free, no network |
| Semantic recall over phrasing the document does not use | `SpecRecall` | An embedder, and a vector store |

`SpecRecall` fuses the tiers by weighted reciprocal-rank fusion and can reorder
for diversity. Two behaviours matter operationally: a hit still carries the
section path, so it stays addressable rather than becoming a loose snippet; and
an **empty vector result degrades to tier 1** instead of failing, so a run with
no embedder configured still returns lexical hits.

The memory plane lives behind the full barrel — see
[scripting.md § Choosing which barrel](scripting.md#choosing-which-barrel-to-import)
— because it depends on sqlite3 FFI and must stay out of a Flutter compile.
`memory.md` covers running it.

## Error Handling

The index throws nothing on a query. Every "failure" is an empty result, which
is the right shape for a search surface:

| Situation | Result |
|-----------|--------|
| A term no section carries | Empty list |
| A `className` no class has | Empty list |
| A facet combination nothing satisfies | Empty list |
| `search` before any `rebuild` | Empty list — an unbuilt index has no documents |
| A projection set from a different model than the query expects | Hits keyed by whatever paths the projections carried — **no error** |

The last row is the one to watch. The index does not know which model produced
its projections, so rebuilding from one document and querying as though for
another returns confidently wrong paths. Rebuild from the projections of the
document you are about to search.

## Best Practices

- **Reach for a facet before a text term.** `className` or `sectionIdPrefix` is
  exact where a word is approximate, and both are free.
- **Set `limit` on an interactive query.** Ranking is over every match; a
  three-thousand-section document can return a long tail nobody reads.
- **Rebuild from the projections of the document you will search.** The index
  cannot detect a mismatch.
- **Compare scores within one result list only.** BM25 scores are not
  comparable across queries.
- **Stay on tier 1 until the question needs phrasing the document lacks.** The
  index is free; recall is not.
- **Treat an empty result as an answer.** It is what the index reports for every
  no-match case, including the ones that would be errors elsewhere.

---

Back to the [documentation index](index.md).

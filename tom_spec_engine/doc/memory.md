# TomSpecs Engine — The Memory Plane

Beyond the free lexical index sits a two-tier RAG memory plane: a vector tier
for semantic recall and a graph tier for structural neighbourhood. This guide
covers running it — the degradation path when a tier is absent, and the
**vector-runtime precondition** that is the single most common reason a memory
run fails to start. What the plane *is* is
[`llm_and_d4rt_tools.md`](../../tom_specs_model/doc/llm_and_d4rt_tools.md) §9
and §10; this guide states how to operate it and cites that.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
  - [SpecRecall — the fusing front door](#specrecall--the-fusing-front-door)
  - [SpecRecallQuery](#specrecallquery)
  - [The graph tier](#the-graph-tier)
- [The vector-runtime precondition](#the-vector-runtime-precondition)
- [Degradation, and how to tell](#degradation-and-how-to-tell)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

Three tiers, fused:

| Tier | Answers | Needs |
|------|---------|-------|
| Lexical | Which sections carry these terms or this shape | Nothing |
| Vector | Which sections *mean* this, whatever words they use | An embedder and a vector store |
| Graph | Which sections neighbour a hit structurally | The document's projections |

`SpecRecall` runs each tier separately and fuses the ranked lists by **weighted
reciprocal-rank fusion**, optionally reordering for diversity with MMR. Only the
lexical tier is required; the other two are optional constructor arguments, and
their absence degrades the result rather than failing the call.

The plane lives behind the **full barrel** (`package:tom_spec_engine/tom_spec_engine.dart`)
because it depends on `tom_brain_memory` — sqlite3 FFI with a `vec0` extension,
a server-only surface. See
[scripting.md § Choosing which barrel](scripting.md#choosing-which-barrel-to-import).

## Quick Start

A recall with only the lexical tier wired. This is a legitimate configuration,
not a broken one — it is what a host with no embedder gets.

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

Future<void> main() async {
  final model = buildModel();
  final doc = SpecDocument()
    ..setContent('PD00/VIS', 'amend an order line after dispatch')
    ..setContent('PD00/SUM', 'unrelated overview text');

  final index = StructuralLexicalIndex()
    ..rebuild(SpecQueryEngine(model: model, document: doc).projectNodes());

  // No vectorRecall, no graph: tier 1 only.
  final recall = SpecRecall(index: index);
  final result = await recall.recall(const SpecRecallQuery(text: 'amend', k: 8));

  print(result.tier2Warm);
  for (final hit in result.hits) {
    print('${hit.path}  modes=${hit.modes.map((m) => m.name).toList()}');
  }
}
```

Output:

```
false
PD00/VIS  modes=[lexical]
```

`tier2Warm` is `false` because no vector tier was supplied — the result is
honest about which tiers contributed rather than presenting a lexical answer as
a semantic one.

## Core Components

### `SpecRecall` — the fusing front door

```dart
SpecRecall({
  required StructuralLexicalIndex index,
  SpecVectorRecall? vectorRecall,
  SpecRagGraph? graph,
});
```

| Member | Role |
|--------|------|
| `index` | The lexical tier. **Required** — recall without it has nothing to fall back to |
| `vectorRecall` | The vector tier. `null` means semantic recall is simply not run |
| `graph` | The graph tier. `null` means no structural neighbourhood walk |
| `recall(SpecRecallQuery)` | Runs every configured tier and fuses the results |

### `SpecRecallQuery`

| Field | Default meaning | Controls |
|-------|-----------------|----------|
| `text` | *(required)* | The query text, given to every tier |
| `facets` | An empty `IndexQuery` | Structural narrowing applied to the lexical tier |
| `k` | | How many fused hits to return |
| `perModeK` | | How many each tier contributes before fusion |
| `rrfK` | | The reciprocal-rank-fusion constant |
| `weights` | | Per-tier weight in the fusion |
| `graphWalk` / `graphWalkDepth` | | Whether to expand hits through the graph, and how far |
| `diversify` / `mmrLambda` | | Whether to reorder for diversity, and how hard |

A `SpecRecallHit` carries `path`, `score`, the set of `modes` that produced it,
and optionally `kind` and `headline`. **The path is the point**: a hit is
addressable in the document, so it can be navigated to or edited, rather than
being a loose snippet a caller has to locate again.

### The graph tier

`SpecRagGraph.fromProjections(...)` builds the structural neighbourhood from the
same node projections the lexical index uses, so wiring it costs no extra walk
of the model:

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
          'fields': [
            {'name': 'detail', 'kind': 'content', 'sectionId': 'DET'},
          ],
        },
      },
    });

Future<void> main() async {
  final model = buildModel();
  final doc = SpecDocument()
    ..setContent('PD00/VIS', 'amend an order line')
    ..setContent('PD00/SIT/DET', 'orders are captured in three systems');

  final projections =
      SpecQueryEngine(model: model, document: doc).projectNodes().toList();

  final index = StructuralLexicalIndex()..rebuild(projections);
  final graph = SpecRagGraph.fromProjections(projections);

  final recall = SpecRecall(index: index, graph: graph);
  final result = await recall.recall(
    const SpecRecallQuery(text: 'amend', k: 8, graphWalk: true),
  );

  print(result.hits.isNotEmpty);
  print(result.hits.first.path);
}
```

Output:

```
true
PD00/VIS
```

## The vector-runtime precondition

This is the failure worth knowing about before it happens.

`SpecMemory` boots on `SqliteTomBrainMemory`, which **refuses to open unless the
bundled sqlite-vec `vec0` extension registers**. Vector recall is mandatory for
that store — there is no BM25-only fallback inside it. And whether registration
can succeed is a property of the **host process**, not of the engine: it needs
the process's `libsqlite3` to support extension loading, which the macOS system
library does not.

Both the probe and the repair belong to `package:tom_brain_memory`, the package
that owns the store:

| Thing | What it does |
|-------|--------------|
| `SqliteHostLibrary` | The **repair** — points `package:sqlite3` at a capable library. Conditional: it acts only where the platform default is known to lack extension loading, so a Flutter or Linux host keeps the SQLite it already has |
| `VectorRuntimeProbe.probe()` | The **gate** — runs the real load pipeline once and reports whether it worked |

Two properties are easy to get wrong:

- **The repair is production behaviour, not test support.** Reaching
  `SqliteTomBrainMemory` at all installs it, because the package ships a
  plain-Dart-VM MCP server host that hits the same wall.
- **The probe is a probe, not a proxy.** It runs the real load. Testing for the
  packaged binary's *presence* would pass on macOS — where the file is there and
  the load still fails — and put a green gate in front of a red test.

The probe answers two different questions, and they are not interchangeable:

| Ask | Question |
|-----|----------|
| `binariesSkipReason` | Is a `vec0` binary published for this ABI? Enough for a test that only needs the path |
| `skipReason` | Can it actually register? Strictly stronger, and what anything opening the store needs |

On a host where it cannot register, the honest move is to skip with the reason
stated — which is what the engine's four store-touching suites do, rather than
reporting a pass they did not earn.

## Degradation, and how to tell

The plane degrades rather than failing, and every degradation is reportable:

| Configuration | What happens | How you can tell |
|---------------|--------------|------------------|
| No `vectorRecall` | The vector tier is not run | `result.tier2Warm == false` |
| A vector tier that returns nothing | Fusion proceeds on the remaining tiers | Hits carry `modes` without `vector` |
| No `graph`, or `graphWalk: false` | No neighbourhood expansion | Hits carry no graph mode |
| No tier returns anything | An empty hit list | `result.hits.isEmpty` |

`SpecRecallHit.modes` is the mechanism: every hit says which tiers produced it,
so a caller can distinguish "the vector tier agreed" from "only lexical ran".
Presenting a degraded result as a full one is the failure this exists to
prevent.

## Error Handling

| Situation | Result |
|-----------|--------|
| A query no tier matches | Empty `hits`; **no throw** |
| `vectorRecall` absent | Tier skipped; `tier2Warm == false` |
| `graph` absent with `graphWalk: true` | No walk; no throw |
| Opening `SqliteTomBrainMemory` where `vec0` cannot register | **Throws** — the store refuses to open rather than running without vectors |
| An embedder that fails mid-run | Surfaces from the vector tier; the lexical tier's hits are unaffected |

The asymmetry is deliberate. A *missing* tier is a configuration, so it
degrades; a store that cannot do what it exists to do is a defect, so it
refuses. Silently running a "vector" store with no vectors would make every
result unexplainable.

## Best Practices

- **Check `tier2Warm` before trusting a semantic answer.** A `false` there means
  the question was answered lexically, whatever it looked like.
- **Read `hit.modes`, not just `hit.score`.** The score is fused; the modes say
  what fused into it.
- **Build the graph from the same projections as the index.** They come from one
  walk; building each from its own risks two views of one document.
- **Probe before opening the store, on any host you do not control.**
  `skipReason`, not `binariesSkipReason` — the weaker question passes on macOS
  where the load still fails.
- **Never substitute a presence check for the probe.** The file being there is
  not the same as it registering, and that difference is exactly where the bug
  lives.
- **Keep the memory plane out of Flutter.** Link `scripting.dart` there; the
  store's FFI has no place in that compile.

---

Back to the [documentation index](index.md).

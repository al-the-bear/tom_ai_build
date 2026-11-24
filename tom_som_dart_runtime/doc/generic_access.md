# Generic access — `tom_som_dart_runtime`

The reflective, untyped half of the Dart SOM plane: the document as a
sparse path-keyed store, the model as data, and the question of when to prefer
this over the generated typed facade.

The object model, the two wire formats and the validator contract are the
**subject matter** and are owned by
[`som_multiplatform_spec_model.md`](../../tom_specs_model/doc/som_multiplatform_spec_model.md);
this guide cites it and never restates it. The typed half is
[`tom_som_dart_v0/doc/tutorial.md`](../../tom_som_dart_v0/doc/tutorial.md).

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
- [Driving a document by path](#driving-a-document-by-path)
- [The model as data](#the-model-as-data)
- [The links of the model](#the-links-of-the-model)
- [A project's documents side by side](#a-projects-documents-side-by-side)
- [When to prefer the generic path](#when-to-prefer-the-generic-path)
- [Building and testing](#building-and-testing)
- [The API reference](#the-api-reference)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

A TomSpecs document is **sparse and path-keyed**: a value lives under the
globally-unique section-id path it belongs to, and an absent key means "no
value" rather than an empty one. This package is that store, plus everything
that is the same in every language — the codecs, the validator, the reflection
surface and the editing tiers.

It holds **no document values of its own** and contains **no generated typed
classes**. Those belong to `tom_som_dart_v0`, which is a view over exactly the
store this package provides. Both halves address the same document; the
difference is only whether a member is named at compile time or resolved from a
string at run time.

Dart is the reference plane: the model, the generator and the conformance goldens are authored here, and the other eight ports are transcribed from it.

## Quick Start

```bash
dart pub add tom_som_dart_runtime
```

Most consumers depend on the typed facade, which pulls this in. Depend on it
directly when you drive documents by path — tooling, migration, bulk edits, or
anything that computes the path rather than knowing it.

## Core Components

| Type | Role |
|------|------|
| `SpecDocument` | The sparse, path-keyed store of content, form and list values |
| `SpecModel` | The exported class graph — roots, classes, fields, annotations |
| `SpecReflection` | Resolves and enumerates paths against the model **without reading values** |
| `SpecPlace` / `SpecPlaceFilter` | Parse and resolve the places and filters the link annotations name |
| `SpecValidator` / `validateDocument` | The instance tier: a filled document's values checked against the model |
| `validateLinks` | The link checks of one document: derived values, summaries, both ends of a link, link rows, `@SameAs` copies |
| `SpecDocumentSet` / `syncReport` / `renameId` | A project's documents side by side: what each Phase 3 document shares with the Blueprint, and one id renamed everywhere |
| the YAML and Markdown codecs | `*.tomspecs.yaml` and DocSpecs markdown, byte-stable across all nine languages |
| the editing-facade bases | What the generated `tom_som_dart_v0` types extend |

The full catalogue is the [README](../README.md); this guide is about using
them.

## Driving a document by path

A facade is a view; the document is the value. Reach past the typed types whenever a path is computed rather than known — both sides address exactly the same store.

```dart
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

final doc = SpecDocument();
doc.setContent(
    'SBP/content', 'A platform that unifies our fragmented order systems.');

// A repeated section: append an item, then fill a content leaf under it.
final item = doc.addListItem('SBP/currentLandscape/CUOPME-OPER-LST');
doc.setContent('\$item/content', 'Average order turnaround: 4.2 days.');

// The whole document serializes to the canonical wire format.
print(SpecDocumentYaml.encode(
    document: doc,
    tree: d00SolutionBlueprintMetaTree,
    modelVersion: '1.0'));
```

The path grammar is the model's: a root segment, then a member per level, with
list items addressed by the path the store hands back when you append. Nothing
here needs a generated class, which is why this half of the plane is what
tooling reaches for.

## The model as data

The exported class graph answers "what *can* the model hold?" with no document values involved — enumerate roots and fields, or resolve a concrete path to the model node it lands on (`SOM §7`).

```dart
import 'dart:convert';
import 'dart:io';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

final model = SpecModel.fromJson(
    jsonDecode(File('meta/spec_model.meta.json').readAsStringSync())
        as Map<String, dynamic>);
final reflection = SpecReflection(model);

for (final root in reflection.roots) {
  print('\${reflection.rootSegment(root)}  \${root.title}');
}

final res = reflection.resolve('SBP/currentLandscape/content')!;
print('kind=\${res.kind.name}  valueLeaf=\${res.isValueLeaf}');
```

This is the surface that makes generic editing safe rather than blind: before
writing to a path you can ask whether the model has one, what kind of node it
is, and whether it is a value leaf.

## The links of the model

The link annotations (`tom_specs_model_rules.md` §9.7) are read as typed values
on every class and field — `syncedWith`, `summaryOf`, `derivedFrom`,
`extractsLinks` (a list, in source order) and `sameAs` — and on every form
field as the qualifiers `derivedFrom`, `inverseOf` and `summaryOf`. Each is
`null` (or empty) when the model states none, so a meta written before the
links existed reads the same. Enum constants come bare (`subset`, `rows`).

The places they name resolve under an anchor, the section the annotation
stands on, to the document path the value is stored at; list items below the
anchor read `<list>-*`:

```dart
final sync = model.classes['FunctionalRequirements']!.syncedWith;
print(sync?.document); // D04RequirementsSpecification

const fr = 'SBP/introductionAndScope/requirements/functionalRequirements';
final place = SpecPlace.parse('FRED.description').resolve(reflection, fr);
print('${place.kind.name} ${place.path} ${place.field}');
// formField SBP/…/functionalRequirements/FRE-REQU-LST-*/FRED description

final filter = SpecPlaceFilter.parse('RQDEP.dependencyType=conflict|bidirectional');
print(filter.matches(['conflict'])); // true
```

A place that does not resolve throws a `SpecPlaceException` whose `problem`
says why (`ambiguous`, `unresolved`, `noSuchField`, …). `specSameAsBindings`
lists every `@SameAs` copy of a document root with the position that holds
its values.

`validateLinks(model, doc)` holds a document's values to those links and
answers `SpecValidationError`s like `validateDocument`, sorted by path: a
derived value its sources do not give (`derivedValueMismatch`), a lookup
without exactly one row (`derivedLookupMiss`), a link not named back
(`inverseMissing`), an id named in a text without its row
(`extractedLinkMissing`) or a generated row the text no longer names
(`extractedLinkStale`), a summary out of step with its detail list, and a
`@SameAs` copy edited apart from its holder (`sameAsMismatch`). A value with
pending change marks is read with every mark rejected and listed as
`linkValuePending`.

`deriveFields(model, doc)` writes what those checks find derivable, in three
steps, each reading the one before: the missing link ends and generated rows
(stale generated rows removed), then the derived values, repeats and
`@SameAs` copies, then the counts, products and ranks. By default it writes
inline marks for review (`marked: true`, with `author` and `at`); `marked:
false` writes plain values, `dryRun: true` works on a copy. A second run
right after the first writes nothing. Its `SpecDeriveResult` lists every
change and what it left unresolved: a change it cannot mark exactly
(`unmarkable`) and a lookup without exactly one row (`derivedLookupMiss`).

```dart
final result = deriveFields(model, doc, author: 'agent_spec_author');
for (final c in result.changes) {
  print('step ${c.step} ${c.kind} ${c.path} ${c.field ?? ''}');
}
```

## A project's documents side by side

`SpecDocumentSet(model, {name: document})` reads a project's documents one
per root, never assembled into one: each keeps its own registry, and every
finding names the document a place is in. `SpecDocumentSet.load(model, files)`
reads YAML and SOM Markdown files, assembling the fragments of one root. A set
is refused (`SpecDocumentSetError`) for two documents of one root, a document
with no root or two, the CodeSpecs projection, overlapping fragments, and a
model whose synced positions cannot be paired.

Its `pairs` are the classes kept in sync between the Blueprint and a Phase 3
document (`@SyncedWith`, `@DetailedIn`), each with its anchor in both roots.
`syncReport(set)` compares every shared place of every pair and answers a
`SpecSyncReport`: the findings (each with both places, the side holding the
value and its resolution — `backfill`, `agent` or `info`), each document's own
findings, the roots with no document yet, and the counts. `clean` is true when
nothing but `info` is left.

```dart
final set = SpecDocumentSet.load(model, [
  'tom_uam.sbp.tomspecs.yaml',
  'tom_uam.rsp.tomspecs.yaml',
]);
final report = syncReport(set);
print(report.countsByCode()); // e.g. {sharedValueDiffers: 3, pendingReview: 1}
```

`backfill(set)` then carries what each Phase 3 document holds into the
Blueprint, as plain values: every finding whose resolution is `backfill`
(a differing, missing or emptied value; an element only in the Phase 3
document, added after its neighbour with its section id; an element only in
the Blueprint, removed). It refuses a set holding any inline mark or comment
block (`SpecBackfillError`, `setHasMarks`, the places named), leaves the rest
in `SpecBackfillResult.left` with the reason, writes only the Blueprint, and
adds one entry to its revision history when it changed anything. `dryRun`
writes a copy; `pairs` and `path` scope it; a second run writes nothing.

`prefill(set, 'RSP')` starts a Phase 3 document from the Blueprint, once:
it creates the document when the set has none, copies each pair's values,
elements (with their section ids) and headlines outside `detailOnly` as
plain values, skips a pair whose anchor already holds anything, and derives
the document's derived places. Its `SpecPrefillResult` lists the pairs filled
and skipped and the document's findings after it, the agent's work list. A
pair a document has not written yet is reported by `syncReport` in
`notStartedPairs`, never as findings.

`renameId(set, from, to)` renames a section id in every document at once —
the element and every value naming it — and is refused (`SpecRenameError`)
when an element of any document already carries `to`.

## When to prefer the generic path

| Prefer the **typed facade** when | Prefer the **generic store** when |
|----------------------------------|-----------------------------------|
| The section is known at authoring time | The path is computed, or comes from data |
| You want the compiler to catch a typo | You are walking every section of a document |
| You are writing application code | You are writing tooling, a migration or a bulk edit |
| The document root is fixed | The root varies, or several are handled uniformly |

The two are not alternatives at run time — the facade *is* a view over this
store, so a program can use both on one document and see one set of values. The
choice is per call site, not per program.

## Building and testing

```bash
./run_tests.sh
```

Every SOM package carries that same script, whatever the ecosystem underneath,
and [`tom_som_conformance`](../../tom_som_conformance) aggregates all eighteen —
which is also what proves this port reads a document identically to the other
eight. The per-language toolchain is
[`som_toolchains.md`](../../tom_specs_model/doc/som_toolchains.md).

## The API reference

The full generated reference lives in `build/api_doc/` and is **not
committed** — it is output, and it regenerates:

```bash
cd ../tom_specs_clitool
./tool/regenerate_api_references.sh dart_runtime
```

That renders it with `dart doc`. The reasoning behind not committing it, and
the per-language generator notes, are in
[`som_toolchains.md`](../../tom_specs_model/doc/som_toolchains.md),
"Documentation generation".

## Error Handling

Everything that can fail throws. `SpecYamlFormatException` names the path it failed at; `validateDocument` **returns** a list instead, because a document with problems is a normal state for an editor to be in, not an exception.

The generic path has one failure mode the typed path does not:

| Symptom | Cause |
|---------|-------|
| A read returns nothing | The path is absent from the document — **or** it names a section the model does not have. The store cannot tell you which |
| The encoder reports a value it cannot place | The document holds a path the metadata tree does not describe |
| Validation reports an error the typed path would not have allowed | The generic store accepts any path; validation is where that is caught |

That first row is the price of the generic path, and the reason to resolve a
path against `SpecReflection` before writing to it: a typo and a genuinely empty
section are indistinguishable afterwards.

## Best Practices

- **Resolve before you write.** `SpecReflection` turns "did I spell it right?"
  into a question with an answer.
- **Treat an absent value and an absent path as different questions.** The store
  answers the first; only the model answers the second.
- **Pin the runtime and the facade together.** They carry the same version
  because they are generated from one model.
- **Use the generic path for tooling, the typed path for application code.** The
  choice is per call site.
- **Validate after a bulk edit.** The generic store accepts paths the model does
  not have; validation is the check that catches it.
- **Regenerate the API reference rather than looking for it in the repo.** It is
  deliberately not committed.

---

Back to the [documentation index](index.md).

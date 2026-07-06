# SOM convenience-feature suggestions

This document evaluates how convenient the SOM access APIs are **in practice**
and proposes concrete convenience features. The evaluation is evidence-based:
it comes from authoring a broad, real-shaped sample Solution Blueprint
(`tom_som_conformance/samples/meridian_order_management.docspecs.yaml`) and two
access examples that read the same key sections two ways —

- **concrete / typed:** `tom_som_dart_v0/example/d_sample_typed_access.dart`
  (generated `D00SolutionBlueprint` facade), and
- **generic / string-path:** `tom_som_dart_v0/example/e_sample_generic_access.dart`
  (`SpecDocument` only).

Both examples print byte-identical output, so the two paths are genuinely
interchangeable. The friction points below are the ones the exercise actually
surfaced, ranked by how much they cost a first-time consumer. Each is written so
it can be implemented in the generic `tom_som_<lang>_runtime` (and reflected in
every generated facade) without further clarification.

## What already works well

- **Typed nested navigation reads like the domain**:
  `sbp.introductionAndScope.goals.content` and
  `sbp.currentLandscape.operationalMetrics[i].content` need no lookups or casts.
- **Typed ↔ generic parity is real**: every typed getter resolves to the same
  section path the generic example hard-codes, and the outputs match exactly.
- **List authoring is clean**: `metrics.add().content = '…'` returns a typed
  element facade; read-back via `metrics[i]` / `metrics.length` is obvious.

## Suggestions

### 1. One-call document loading (highest impact)

Loading a document today is a three-step incantation that every consumer
re-derives:

```dart
final decoded = SpecDocumentYaml.decode(file.readAsStringSync());
final doc = SpecDocument()..loadJson(decoded.document);
final sbp = D00SolutionBlueprint(doc, documentVersion: decoded.modelVersion);
```

The `documentVersion` must be threaded from `decoded.modelVersion` by hand — a
consumer who forgets it silently loses the version check. Propose:

- `SpecDocument.fromYaml(String yaml)` — decode + `loadJson` in one call,
  retaining the parsed `modelVersion` on the document so it need not be passed
  around separately.
- A generated static `D00SolutionBlueprint.loadYaml(String yaml)` /
  `.loadFile(String path)` that returns the typed root with the document's
  stamp already applied.

This collapses the three lines to one and removes the "forgot the stamp" class
of bug entirely.

### 2. Non-throwing editability check

`D00SolutionBlueprint(doc, documentVersion: '1.0')` **throws**
`SomVersionException` on a cross-major mismatch. A read-only viewer that just
wants to display an older/newer document cannot construct the facade at all
without a `try/catch`. Propose a companion query that mirrors the constructor's
logic without throwing:

```dart
static SomEditability D00SolutionBlueprint.editabilityFor(String? documentVersion);
// → editable | readOnlyCrossMajor | rejectedNewerMinor
```

so a consumer can branch (open read-only vs open for edit) instead of catching.

### 3. Fix the facade model-version stamp (correctness, not just convenience)

The generated `D00SolutionBlueprint.modelVersion` is `'0.0'`, but the model
meta-data (`meta/spec_model.meta.json`) reports `modelVersion: 1`. Stamping the
sample with its *true* version (`'1.0'`) made the typed facade reject it as
cross-major read-only; the sample had to be stamped `'0.0'` to match the facade.
That is the generator emitting a placeholder version rather than the real one.
Regenerate the `_v0` facades with the actual model `major.minor` so authored
documents can carry their genuine version. Until then, any "real" document is
unreadable through the typed facade.

### 4. Distinguish container-only classes from content classes at the type level

`SystemsToReplace` has no `content` setter (it is container-only), while `Goals`
does. There is no way to tell from a getter's return type whether `.content`
exists — the only signal is a compile error. Propose one of:

- give container-only classes a distinct marker (e.g. they extend a
  `SomContainer` base without a `content` member), or
- expose `content` uniformly as nullable and return `null` for container-only
  classes, paired with a `bool get hasContent`.

Either makes "can this section hold text?" answerable without a compile-error
probe.

### 5. Content-only list convenience

Several lists (e.g. operational metrics) have elements whose only field is
`content`. Authoring them is four near-identical `add().content = …` lines, and
reading them is a manual index loop. Propose, on `SomList<T>`:

- `T addContent(String content, {String? sectionId})` — add + set the content
  leaf in one call, and
- for content-only element types, an `Iterable<String> get contents` view.

### 6. Align absence semantics across the two paths

Typed `sbp.requirements.content` coalesces a missing value to `''`; generic
`doc.content('SBP/requirements/content')` returns `null`. A consumer asking "is
this section filled?" gets different answers depending on the path. Propose a
shared `bool hasContent(String path)` on `SpecDocument` (and a matching
`bool get isEmpty` on the typed section) so emptiness is defined once.

### 7. Expose the typed→path bridge for hybrid access

The generic example hard-codes undiscoverable, typo-prone strings like
`'SBP/currentLandscape/CUOPME-OPER-LST'`. The typed facades already carry the
answer — every `SomNode` has `.path` and every `SomList` its `listPath`. Two
low-cost wins:

- **Document** the hybrid pattern (navigate with the typed facade to obtain a
  `.path`, then read/write generically) — it is the safest way to build dynamic
  path strings.
- **Generate** path constants (e.g. `SbpPaths.currentLandscapeOperationalMetrics`)
  so generic consumers are not writing raw string literals.

### 8. `SpecModel.rootByType` + one-line markdown export

Rendering the sample to markdown required loading the meta model, calling
`SpecModel.fromJson`, finding the root with `model.roots.firstWhere((r) => r.type == …)`,
then `SpecDocumentMarkdown(model, doc).exportRoot(root)`. Propose:

- `SpecModel.rootByType(String type)` (replacing the `firstWhere` boilerplate),
  and
- `String SpecDocument.toMarkdown(SpecModel model, {String? rootType})` for a
  one-line export, defaulting to the document's single populated root.

## Priority

| # | Suggestion | Impact | Effort |
| --- | --- | --- | --- |
| 3 | Fix facade model-version stamp | **Correctness** — real docs currently unreadable | Generator change |
| 1 | One-call document loading | High — every consumer hits it | Low |
| 2 | Non-throwing editability check | High — read-only viewers | Low |
| 6 | Align absence semantics | Medium | Low |
| 4 | Container vs content typing | Medium | Medium |
| 7 | Typed→path bridge + path constants | Medium | Medium (generator) |
| 5 | Content-only list convenience | Low–Medium | Low |
| 8 | `rootByType` + markdown one-liner | Low | Low |

Items 1, 2, 5, 6, 8 are pure runtime additions (implement in
`tom_som_<lang>_runtime`, port across languages); items 3, 4, 7 involve the
generator and should be scoped together.

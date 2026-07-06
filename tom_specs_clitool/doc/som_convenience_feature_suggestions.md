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

The **[TODO roadmap](#todo-roadmap-dependency-order)** at the end turns this
review — plus the follow-up decisions from it — into a single, consecutively
numbered work list sorted in **dependency order**, so it can be iterated
top-to-bottom. The first six items are the critical path to a genuinely
implementable shared specification with a cross-language conformance test; the
rest are independent API conveniences ordered by impact.

## What already works well

- **Typed nested navigation reads like the domain**:
  `sbp.introductionAndScope.goals.content` and
  `sbp.currentLandscape.operationalMetrics[i].content` need no lookups or casts.
- **Typed ↔ generic parity is real**: every typed getter resolves to the same
  section path the generic example hard-codes, and the outputs match exactly.
- **List authoring is clean**: `metrics.add().content = '…'` returns a typed
  element facade; read-back via `metrics[i]` / `metrics.length` is obvious.

## Suggestion catalogue (detail)

The subsections below keep the original per-suggestion detail and code snippets.
They are cross-referenced from the numbered [TODO roadmap](#todo-roadmap-dependency-order),
which is the authoritative, dependency-ordered work list.

### One-call document loading (highest impact)

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

### Non-throwing editability check

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

### Derive the facade model version from the `tom_specs_model` project version (correctness bug)

The generated `D00SolutionBlueprint.modelVersion` is `'0.0'`, but the model
meta-data (`meta/spec_model.meta.json`) reports `modelVersion: 1`. Stamping the
sample with its *true* version (`'1.0'`) made the typed facade reject it as
cross-major read-only; the sample had to be stamped `'0.0'` to match the facade.
That is the generator emitting a placeholder version rather than the real one —
**a bug**. The facade version must be **derived from the `tom_specs_model`
project version** (`TomSpecsModelVersionInfo` in
`tom_specs_model/lib/src/version.versioner.dart`), which is currently around
`0.5`, not a hard-coded `0.0`. Wire the generator to read that version, then
regenerate all nine `_v0` facades so authored documents can carry — and be read
back at — their genuine `major.minor`. Until then, any "real" document is
unreadable through the typed facade.

### Distinguish container-only classes from content classes at the type level

`SystemsToReplace` has no `content` setter (it is container-only), while `Goals`
does. There is no way to tell from a getter's return type whether `.content`
exists — the only signal is a compile error. Propose one of:

- give container-only classes a distinct marker (e.g. they extend a
  `SomContainer` base without a `content` member), or
- expose `content` uniformly as nullable and return `null` for container-only
  classes, paired with a `bool get hasContent`.

Either makes "can this section hold text?" answerable without a compile-error
probe.

### Content-only list convenience

Several lists (e.g. operational metrics) have elements whose only field is
`content`. Authoring them is four near-identical `add().content = …` lines, and
reading them is a manual index loop. Propose, on `SomList<T>`:

- `T addContent(String content, {String? sectionId})` — add + set the content
  leaf in one call, and
- for content-only element types, an `Iterable<String> get contents` view.

### Align absence semantics across the two paths

Typed `sbp.requirements.content` coalesces a missing value to `''`; generic
`doc.content('SBP/requirements/content')` returns `null`. A consumer asking "is
this section filled?" gets different answers depending on the path. Propose a
shared `bool hasContent(String path)` on `SpecDocument` (and a matching
`bool get isEmpty` on the typed section) so emptiness is defined once.

### Expose the typed→path bridge for hybrid access

The generic example hard-codes undiscoverable, typo-prone strings like
`'SBP/currentLandscape/CUOPME-OPER-LST'`. The typed facades already carry the
answer — every `SomNode` has `.path` and every `SomList` its `listPath`. Two
low-cost wins:

- **Document** the hybrid pattern (navigate with the typed facade to obtain a
  `.path`, then read/write generically) — it is the safest way to build dynamic
  path strings.
- **Generate** path constants (e.g. `SbpPaths.currentLandscapeOperationalMetrics`)
  so generic consumers are not writing raw string literals.

### `SpecModel.rootByType` + one-line markdown export

Rendering the sample to markdown required loading the meta model, calling
`SpecModel.fromJson`, finding the root with `model.roots.firstWhere((r) => r.type == …)`,
then `SpecDocumentMarkdown(model, doc).exportRoot(root)`. Propose:

- `SpecModel.rootByType(String type)` (replacing the `firstWhere` boilerplate),
  and
- `String SpecDocument.toMarkdown(SpecModel model, {String? rootType})` for a
  one-line export, defaulting to the document's single populated root.

## TODO roadmap (dependency order)

The authoritative work list, sorted so each item's prerequisites appear above
it. Iterate top-to-bottom. **Items 1–6 are the critical path** to an
implementable shared specification with a cross-language conformance test;
**items 7–11** are independent API conveniences ordered by impact. Each item
tags its *scope* (which layer changes) and *depends on* (earlier item numbers).

### Critical path

**1. Purge the retired object model everywhere.**
The current model root scheme is `D00SolutionBlueprint` (`SBP`) … `D12` (13
`@Document` roots) over the `DocSpecsProject` container. Remove **all** remaining
references to the retired naming — `ProjectDefinition`, `CsCurrentSituation`,
the old `PD00`/`PD` prefix — from docs, config examples
(`spec_object_model_config.md`, `spec_model_meta_schema.md`), READMEs,
`second_wave_documents.md`, annotation doc-comment examples in `tom_specs_core`,
and any stale baselines. Nothing may reference an older model state; the current
specs model is the only reality.
*Scope:* docs + code comments. *Depends on:* — (foundation).

**2. Derive the facade model version from the `tom_specs_model` project version.**
Fix the model-version bug: the generator hard-codes `modelVersion '0.0'` while
the model meta reports `1`, which forced the shared sample to be mis-stamped
`0.0`. Wire the generator to read `TomSpecsModelVersionInfo` (currently ~`0.5`)
and emit the real `major.minor` into every `_v0` facade and the meta file, then
regenerate all nine `_v0` projects. See
*[Derive the facade model version …](#derive-the-facade-model-version-from-the-tom_specs_model-project-version-correctness-bug)*.
*Scope:* generator. *Depends on:* 1.

**3. One-call document loading.**
Add `SpecDocument.fromYaml` and generated `D00SolutionBlueprint.loadYaml` /
`loadFile` so loading is one call with the version stamp applied automatically.
Landed before the cross-language tests so the 3-step load is not re-derived in
nine languages. See *[One-call document loading](#one-call-document-loading-highest-impact)*.
*Scope:* runtime (all languages). *Depends on:* 2.

**4. Align absence semantics across the two paths.**
Make "is this section filled?" answer identically through the typed facade
(`''`) and the generic API (`null`) — e.g. a shared `hasContent(path)`. This is
a **hard prerequisite** for item 6: without it, the typed and generic logs would
differ on empty sections and the golden comparison would never match. See
*[Align absence semantics …](#align-absence-semantics-across-the-two-paths)*.
*Scope:* runtime (all languages). *Depends on:* — (but must precede 6).

**5. Grow the shared sample into a true, implementable specification.**
Replace the current single-paragraph-per-section sample with a real (if small)
system spec: **several use cases** with full flows, **several fully-detailed
screens**, **multiple requirement-list types** (functional, non-functional,
data, interface…), a coherent data model, etc. — enough that the system could
actually be **implemented from the sample**. Author it through the typed facade
(`tool/build_shared_sample.dart`) so the wire format stays valid, and re-emit
YAML + markdown into `tom_som_conformance/samples/`.
*Scope:* sample + builder tool. *Depends on:* 1, 2 (correct model + version);
eased by 3, 8, 10.

**6. Comprehensive per-language tests + cross-language golden-output harness.**
Two parts:
- **6a — Parity of the per-language suites.** Bring every `tom_som_<lang>_v0`
  test suite up to genuinely comprehensive coverage (typed↔generic parity,
  `SomList`, section-id generation/override/collision/delete-renumber, version
  checks, load/round-trip). Even C's ~30 checks are **not enough** for an API
  this large. Every suite must be **actually executed**, not just present.
- **6b — Cross-language conformance golden.** A test that, in each language,
  loads the shared sample (item 5) and extracts **essentially all sections**
  through **both** the typed and the generic API, writing a canonical log file
  per language. A comparison script then asserts every language's log is
  **byte-identical** — proving all nine language APIs yield exactly the same
  reading of the same specification. House it alongside `tom_som_conformance`.

*Scope:* tests (all languages) + a comparison script. *Depends on:* 5 (rich
sample), 4 (identical empties), 3 (uniform load), 2 (version accepted).

### Independent conveniences (ordered by impact)

**7. Non-throwing editability check.**
`editabilityFor(documentVersion)` so read-only viewers branch instead of
catching `SomVersionException`. See
*[Non-throwing editability check](#non-throwing-editability-check)*.
*Scope:* runtime (all languages). *Depends on:* 2.

**8. Content-only list convenience.**
`SomList<T>.addContent(String)` and an `Iterable<String> get contents` view for
content-only element lists. Reduces authoring friction in item 5. See
*[Content-only list convenience](#content-only-list-convenience)*.
*Scope:* runtime (all languages). *Depends on:* —.

**9. Distinguish container-only classes from content classes at the type level.**
Make "can this section hold text?" answerable without a compile-error probe
(marker base type, or a uniform nullable `content` + `hasContent`). See
*[Distinguish container-only classes …](#distinguish-container-only-classes-from-content-classes-at-the-type-level)*.
*Scope:* generator. *Depends on:* —.

**10. Expose the typed→path bridge + generate path constants.**
Document the navigate-then-read hybrid pattern and generate path constants (e.g.
`SbpPaths.currentLandscapeOperationalMetrics`) so generic consumers — including
the item-6 harness across nine languages — stop hard-coding raw path strings.
See *[Expose the typed→path bridge …](#expose-the-typedpath-bridge-for-hybrid-access)*.
*Scope:* generator + docs. *Depends on:* —. *Recommended before 6b* to cut
cross-language string churn.

**11. `SpecModel.rootByType` + one-line markdown export.**
`SpecModel.rootByType(String)` and `SpecDocument.toMarkdown(model, …)` to remove
the meta-load / `firstWhere` / `exportRoot` boilerplate. See
*[`SpecModel.rootByType` …](#specmodelrootbytype--one-line-markdown-export)*.
*Scope:* runtime. *Depends on:* —.

### Scope summary

- **Pure runtime additions** (implement in `tom_som_<lang>_runtime`, port across
  all nine languages): 3, 4, 7, 8, 11.
- **Generator changes** (best scoped together): 2, 9, 10.
- **Content / tests / cleanup**: 1 (docs), 5 (sample), 6 (tests + script).

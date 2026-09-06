# Sample — author a Solution Blueprint

**Teaches:** authoring a TomSpecs specification end to end through the typed
Dart facade — write, serialise both renditions, round-trip, validate, and read
a real diagnostic.
**Phase:** 2 (Solution Blueprint) of `tom_specs_project_flow.md`.
**Language:** Dart.

This is the entry sample. Every other sample assumes you have run it.

## Prerequisites

* A Dart SDK matching `^3.11.4` (`dart --version`).
* Network access on first run, to fetch the published packages. Nothing else —
  no workspace checkout, no local build. The sample depends on
  `tom_som_dart_v0` and `tom_som_dart_runtime` **from pub.dev**, which is what
  makes it a proof that a user can do this and not only that we can.

## Run it

```bash
dart pub get
dart run
```

## What you should see

Six numbered steps, ending in `Done.` and leaving two files in `build/`. The
full text is in [`expected_output.txt`](expected_output.txt) — the samples
driver compares against it, so if the sample stops behaving the way this README
describes, that is a failure rather than a surprise.

## What each step is for

**1 — a typed root over an empty document.** `SpecDocument()` is the generic,
path-keyed store; `D00SolutionBlueprint(doc)` is the typed editing facade over
it. Constructing the root also runs the instantiation-time model-version check
(`som_multiplatform_spec_model.md` §4.2), which is why a document written by a
newer model is refused here rather than misread later.

**2 — authoring.** Every write goes through a named accessor, never a string
path. The sample prints the **section id** each write lands under, because the
ids are the document's addressing system: the same tokens appear as yaml keys
and as the `<!--[ID]-->` comments in the markdown. Watching
`SBP/currentLandscape/CUOPME-OPER-LST` appear teaches the id system in a way
that reading about it does not.

**3 — both renditions.** The same document serialises to the hierarchical
`*.docspecs.yaml` wire format (`som_multiplatform_spec_model.md` §12) and to
DocSpecs markdown (`som_multiplatform_spec_model.md` §11). They are two
encodings of one store, not two documents.

**4 — the round trip.** `D00SolutionBlueprint.loadFile` decodes, applies the
document's own authoring stamp and hands back a typed root in one call. The
sample re-encodes the reload and compares the two strings, rather than
comparing field by field — a field-by-field check only proves the fields
somebody thought to compare.

**5 — validation.** `validateDocument` is the instance tier: it checks a
*filled document* against the model, as opposed to the static tier that checks
the model itself.

**6 — a real diagnostic.** The sample writes to a path the model does not
declare. The store accepts it — it is a plain path-keyed map — and the
validator is what notices, reporting `danglingPath`. Seeing the failure is the
point: a sample that only shows success teaches you nothing about the day it
does not work.

## One wrinkle, and why it is here

`toMarkdown` and `validateDocument` both take a `SpecModel`, and the generated
facade exposes only a `SomMetaTree` per document root. The model ships as a
data file inside the package, so `_loadShippedModel()` resolves the package URI
and reads it. That is five lines a consumer should not have to write, and it is
tracked as a defect rather than hidden here — a sample that quietly worked
around it would leave the next reader to rediscover it.

## Where to go next

The individual access styles each have a focused example in the facade package
rather than being re-explained here — typed, generic, reflective and hybrid:
<https://pub.dev/packages/tom_som_dart_v0/example>.

The methodology behind what this sample writes:

| Document | Authority for |
|----------|---------------|
| [`tom_specs_project_flow.md`](../../tom_specs_model/doc/tom_specs_project_flow.md) | The phases — what a Solution Blueprint is *for* |
| [`tom_specs_model_rules.md`](../../tom_specs_model/doc/tom_specs_model_rules.md) | Section ids, headlines, the model's shapes |
| [`som_multiplatform_spec_model.md`](../../tom_specs_model/doc/som_multiplatform_spec_model.md) | The two wire formats, the metadata tree, the validators |

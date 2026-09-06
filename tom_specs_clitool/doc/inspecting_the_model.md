# TomSpecs CLI Tool — Inspecting the Model

Three entry points read the Dart model without generating anything from it: the
outliner renders a class tree a person can read, the JSON exporter produces the
class graph the two Flutter apps browse, and the summary builder makes an
analyzer summary. This guide covers running them and reading what they produce.
The outliner's *rendering rules* are
[`tom_specs_model_rules.md`](../../tom_specs_model/doc/tom_specs_model_rules.md)
§11 and the exported graph's *schema* is
[`tom_specs_model_meta_schema.md`](../../tom_specs_model/doc/tom_specs_model_meta_schema.md);
both are cited here, never restated.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
  - [The outliner](#the-outliner)
  - [The JSON exporter](#the-json-exporter)
  - [The summary builder](#the-summary-builder)
- [Reading an outline](#reading-an-outline)
- [Refreshing the committed assets](#refreshing-the-committed-assets)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

All three run the analyzer over `tom_specs_model/lib` and resolve the class
graph. That is the expensive part, and it is why each prints how much it found
before it writes anything — `1254 classes and 25 enums` is the sanity check that
the run saw the whole model rather than a fragment.

| Entry point | Produces | For |
|-------------|----------|-----|
| `outliner.dart` | A markdown class-tree outline | A human reading the model's shape |
| `model_json.dart` | The resolved class graph as JSON | The editor and reviewer apps |
| `summaries.dart` | An analyzer `sdk_summary.sum` | Faster analyzer startup in a consumer |

## Quick Start

```bash
cd tom_ai/ai_build/tom_specs_clitool

# One outline, written to the default generated-doc location.
dart run bin/outliner.dart --package ../tom_specs_model --root-type D03InformationModel

# All sixteen committed outlines, then all three citation gates.
./tool/regenerate_outlines.sh
```

A single-root run prints three lines:

```
Outliner: analyzing <…>/tom_specs_model ...
Found 1254 classes and 25 enums.
Outline written to <…>/tom_specs_model/generated-doc/outlines/InformationModel_outline.md
```

The output path is derived from the root type with its `D<nn>` prefix stripped,
so even an ad-hoc run lands in the right place under the right name.

## Core Components

### The outliner

| Option | Does |
|--------|------|
| `--package` *(required)* | The model package to scan |
| `--root-type` | Which document root to start from. Defaults to `D00SolutionBlueprint` |
| `--output` | Override the derived output path |
| `--max-line-length` | Where to wrap. Default `120` |
| `--show-schema-annotations` | Render schema-only annotations inline |
| `--stop-at-detailed-in` | Stop at `@DetailedIn` sections, showing `→ DocId` instead of expanding — the compact high-level view |

`--stop-at-detailed-in` is the one worth knowing: the Solution Blueprint expands
to thousands of lines, and the compact form shows where each subtree *goes*
rather than what is in it.

**`tool/regenerate_outlines.sh` is the entry point to use** for anything but a
one-off. It renders all sixteen committed outlines — the container root, D00–D13
and the compact Solution Blueprint — and then runs all three citation gates as
blocking steps. So it is simultaneously the outline refresher and the cheapest
way to discover you broke a citation.

### The JSON exporter

`model_json.dart` has two modes, and mixing them is rejected rather than
silently resolved:

| Mode | Invocation | Writes |
|------|-----------|--------|
| Committed asset | `--target editor` \| `--target reviewer` | The target's own path, with the target's own version stamp |
| Ad-hoc | `--package <path> --output <file.json>` | Wherever you say |

The `--target` form owns both the path *and* the stamp, because the two
committed assets pin their versions differently. It therefore cannot be combined
with `--output`, `--model-version` or `--model-label`.

An ad-hoc export prints what it found and what it wrote:

```
model_json: analyzing <…>/tom_specs_model ...
Found 1254 classes, 25 enums.
Wrote 14 roots, 1254 classes to <…>/model.json (model version 0)
```

The resulting file is around ten megabytes — it is the lossless class graph, not
a summary — so an ad-hoc export belongs in a scratch directory, not in a package.

### The summary builder

`summaries.dart --sdk-only` builds an analyzer `sdk_summary.sum` into
`--out-dir`. Pair it with `tool/split_sdk_summary.dart`, which turns that `.sum`
into the committed chunk set the analyzer bootstrap loads.

It is **not** the producer of the editor's scoped summary asset set — that set
has one generator, in `tom_forge/tom_dart_editor_bundler`, which also emits the
helper naming its asset keys. Two producers for one asset set is how the assets
and the paths an app asks for come to disagree.

## Reading an outline

An outline is one line per member, indented by nesting. The notation is terse
because the whole point is fitting a document's shape on a screen:

```
# Information Model Outline

  - content, erDiagram @mermaid-er, objectDiagram @mermaid
  - header: `DocumentHeader`
    - content @Form(documentId, project, version, date, author, status)
  - [1,] entities: `DataEntityEntry`[]
    - content, identity, classification, lifecyclePolicy, relationshipSummary
    - attributes: `DataAttributeEntry`[]
      - content, identity, dataTypeSpec, textTypeOptions, numericTypeOptions, …
      - constraints: `DataAttributeConstraintEntry`[]
        - content @Form(mandatory, nullable, unique, defaultValue, …)
```

| Notation | Means |
|----------|-------|
| `content, erDiagram, objectDiagram` | Content-bearing members, listed together on one line |
| `@mermaid-er` | The member's content type, from its declared section leaf |
| `name: `Type`` | A subsection member and the class it is |
| `` `Type`[] `` | A list member |
| `[1,]` | Cardinality — at least one, no upper bound (`@Min(1)`) |
| `@Form(a, b, c)` | The section is a form; these are its field names |
| `→ DocId` | Under `--stop-at-detailed-in`: this subtree is detailed in that document |

Content-bearing members are collapsed onto one line on purpose: a document with
forty leaf sections is unreadable as forty lines, and their names are the
information, not their arrangement.

## Refreshing the committed assets

Two `spec_model.json` assets are committed, one per app, and each pins its own
version stamp:

```bash
dart run bin/model_json.dart --target editor
dart run bin/model_json.dart --target reviewer
```

Use `--target`. The ad-hoc form would write the file but stamp it with the
wrong version, and a mis-stamped asset is worse than a stale one — the app's
staleness warning is driven by the stamp, so a wrong stamp disables the very
signal that would have reported the problem.

## Error Handling

| Situation | Result |
|-----------|--------|
| `--package` omitted from `outliner.dart` | The `mandatory` option is reported and usage printed |
| `--root-type` naming no `@Document` root | Reported; nothing written |
| `--target` combined with `--output` / `--model-version` / `--model-label` | Rejected — the target owns both |
| A model that fails to resolve | The analyzer's diagnostics, before anything is written |
| `regenerate_outlines.sh` with a broken citation | Non-zero exit from the gate step; the outlines are still written first |

`regenerate_outlines.sh` runs under `set -e` with the gates as blocking steps, so
a gate failure fails the script — but the outlines it wrote before the gate ran
are still on disk. Review the diff before assuming the run did nothing.

## Best Practices

- **Use `regenerate_outlines.sh`, not the outliner directly**, for anything but
  a one-off look. It refreshes all sixteen and runs the gates.
- **Read the `Found N classes` line.** A number well below 1254 means the run
  saw a fragment of the model, and everything after it is wrong.
- **Reach for `--stop-at-detailed-in` on the Solution Blueprint.** The full
  expansion is thousands of lines; the compact form answers "where does this
  go?".
- **Refresh a committed asset with `--target`, never `--package --output`.** The
  stamp is what the staleness warning reads.
- **Keep ad-hoc exports out of packages.** The graph is ~10 MB and is not a
  documentation artefact.
- **Never hand-edit an outline.** They are generated; re-run and commit the diff.

---

Back to the [documentation index](index.md).

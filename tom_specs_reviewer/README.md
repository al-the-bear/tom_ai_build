# tom_specs_reviewer — reviewing the TomSpecs object model

> **Cross-references.**
> [`tom_specs_model/doc/tom_specs_reviewer_specification.md`](../tom_specs_model/doc/tom_specs_reviewer_specification.md)
> is the authority for **what this app must be** — its purpose
> (`tom_specs_reviewer_specification.md` §1), its inputs
> (`tom_specs_reviewer_specification.md` §2), the review vocabulary
> (`tom_specs_reviewer_specification.md` §6) and the persistence contract
> (`tom_specs_reviewer_specification.md` §7).
> [`tom_specs_model/doc/tom_specs_model_meta_schema.md`](../tom_specs_model/doc/tom_specs_model_meta_schema.md)
> owns the snapshot's on-disk schema and its two version stamps. This README is
> the *user's path through the tool* — run it, refresh the snapshot, walk a
> document, record a finding, find the file afterwards; those documents own
> *what the app must be* and *what the snapshot must contain*.

Tree browser and structure-review tool for the TomSpecs object model, used to
gather observations for further development of tom_specs_model.

## Where this fits

**TomSpecs** is a method for building software from structured specification
documents, and the shape of those documents is fixed by a single Dart source
model — the **Specification Object Model (SOM)**, in
[`tom_specs_model`](../tom_specs_model). That model is over a thousand classes
across fourteen document roots, and it is developed by *reading* it, one
subtree at a time. This app is how that reading is done and how it produces
something durable.

It exists because reading a thousand-class model in an editor produces
judgements that evaporate. Without it, "this subtree should not be routed to
CodeSpecs at all" is a sentence in a chat log; with it, that judgement is a
record keyed to the exact structural position that provoked it, in a YAML file
that maps cleanly back onto the model. The findings then drive the next round
of model work.

So it sits *beside* the TomSpecs pipeline rather than in it: it consumes the
class graph that [`tom_specs_clitool`](../tom_specs_clitool) exports from the
model, and nothing consumes the reviewer in turn — its output is read by people
changing `tom_specs_model`. It is **explicitly not a specification editor**: the
app that authors actual DocSpecs / CodeSpecs / Implementation specifications is
`tom_forge/tom_specs_editor`. And it is **outside the release-1 published set**
— it is a `publish_to: 'none'` workspace tool, excluded by name in
`tom_specs_clitool/tool/release_set.yaml`, so nothing in the released chain may
depend on it.

## Overview

The app loads two files at startup and mounts a tree over the first, keyed by
the second:

1. **`assets/spec_model.json`** — the exported class graph, a *committed
   snapshot* rather than a build artifact. Startup is synchronous and total:
   the snapshot is decoded and the review file loaded before the first frame,
   so no screen ever renders against a partially loaded model.
2. **the review file** — `structure_review.yaml`, holding one entry per
   structural path that carries a judgement.

A **structural path** is the chain of member names from a document root, with
all elements of a list sharing one `§item` segment. Keying on structure rather
than on a rendered instance is what makes a decision about a list element a
decision about the element *type* — it survives the list growing or shrinking.

The third property that shapes everything is negative: **nothing the model
states may be invisible.** A reviewer cannot flag what the tree does not draw,
so every annotation the export emits is rendered, and that coverage is held by a
test rather than by discipline.

## Features

### Documents

The model has 14 document roots (`@Document`), listed in the left rail:

| Id | Document |
| --- | --- |
| SBP | Solution Blueprint |
| CLA | Current Landscape Assessment |
| TOM | Target Operating Model |
| IFM | Information Model |
| RSP | Requirements Specification |
| ISC | Interaction Scenarios |
| ATS | Architecture & Technology Specification |
| IIS | Integration & Interface Specification |
| SAS | Security & Access Specification |
| XDS | Experience Design Specification |
| QAP | Quality & Acceptance Plan |
| DRM | Delivery Roadmap |
| TRP | Transition & Rollout Plan |
| CGP | CodeSpecs Generation Projection |

**CGP is a projection, not a fourteenth authored document** — it is marked as
such in the rail. It re-reaches the `@CodeSpecKind`-tagged subtrees that already
live under the other roots, regrouped by the shared / client / server locus they
generate into. So a class seen under CGP is the *same* class seen elsewhere, and
a review recorded against it is recorded against that one class. Because its
content is borrowed, the model validator exempts it from the per-document
detail-count check.

The toolbar carries three view toggles, held above the tree so they survive a
document switch: cut at detail hand-offs, cut at maps hand-offs, and show
serialization order. The two cuts stop the tree where a section hands its detail
to another document, which is what makes a single root readable on its own.

### What the tree renders

Every annotation the exported model emits is accounted for — a
`kRenderedAnnotations` set names them and a test diffs it against the shipped
asset, so an annotation the model *starts* emitting fails the suite rather than
passing unseen.

| Group | Annotations and how they draw |
| --- | --- |
| Identity and headline | `@Document` (the root rail), `@SectionId` and `@SectionIdPattern` (badges on the row), `@Headline` (quoted secondary label) |
| Shape | `@Form` (the form panel under the row), `@ContentType` and `@Min` (the row's type label), `@ContentHelp` (the row's doc line) |
| Hand-offs and taxonomies | `@MapsTo` and `@DetailedIn` (`maps→` / `detail→` chips, and the anchors the two cut toggles act on); the three routing verdicts `@CodeSpecKind`, `@FollowUpKind` and `@NoArtifact` (part / process / `na:<reason>` chips); `@CodeSpecsProjection` (the projection badge) |
| Closed choices | `@OneOf` (the choice group node) and `@Case` (`case:` chips on its alternatives) |
| Markers, notes and provenance | `@Unused` (struck-through label plus an `unused` chip), `@Comment` (inline `←` note), `@Reference` and `@StandardReferences` (behind a `refs` chip — thousands of fields carry standards, and inlining them would bury the structure), `@SerializationOrder` (a `#n` badge, behind the toolbar toggle) |

What each marker *says* is not this app's own decision: the chip labels,
tooltips and suppression rules live in
[`tom_som_dart_runtime`](../tom_som_dart_runtime), shared with
`tom_forge/tom_specs_editor`, which renders the same class graph in the Forge
shell. The two apps paint them differently — opposite backgrounds — but may not
disagree about their meaning. A showcase fixture in that package exercises every
annotation, and both apps run a widget test asserting each marker reaches their
screen, so a rendering dropped from one tree fails a test instead of drifting
apart quietly (`tom_specs_reviewer_specification.md` §3.1).

### What you can record

Per node:

| Group | Judgements |
| --- | --- |
| Destination | Where the subtree belongs: CodeSpecs, follow-up, both or neither. One choice rather than competing booleans, with an explicit undecided state so "no judgement yet" is distinct from "neither" |
| Scope and progress | Scope, `stop here` / `add details` markers, a reviewed checkmark, plus a free-text comment. Always visible |
| Structure | List-vs-single, content-vs-form, and the closed-choice judgements (these siblings are really alternatives; the closed set is missing a case) |
| Annotations | The section id / pattern is wrong or collides; the `@MapsTo` / `@DetailedIn` hand-off points at the wrong target; the `@ContentType` is wrong; standard references are wrong or missing; and the keep-or-drop verdict on an `@Unused` marking (one verdict, so confirming and rejecting are mutually exclusive) |
| CodeSpecs mapping | Whether the node should carry a `@CodeSpecKind` and does not, whether the kinds it declares are wrong or incomplete, which `CodeSpecPart` kinds are proposed instead, and whether the node should not be realised as code at all. Proposed kinds are validated against the `CodeSpecPart` vocabulary at entry, so a recorded suggestion always maps back onto the model |
| Follow-up mapping | Whether the node should carry a `@FollowUpKind` and does not, whether the declared processes are wrong or incomplete, and which `FollowUpProcess` codes are proposed instead. That taxonomy is explicitly extensible, so a code outside it is *warned about, not rejected* — proposing a process nobody has named yet is a legitimate finding |
| No-artifact verdict | The third routing verdict, with its own group rather than a corner of the CodeSpecs one: whether the node feeds nothing and should carry `@NoArtifact` but is routed anyway, whether it carries `@NoArtifact` but does feed something downstream, whether the declared reason is the wrong one of the three, and which `NoArtifactReason` is proposed instead. That last is a single choice, not a set — a section becomes several parts or feeds several processes, but it is unrouted for one reason |

The axis-specific groups are collapsible. A group that already holds a judgement
opens expanded, so recorded feedback is never hidden behind a collapsed header.
The full vocabulary, field by field, is set out in
`tom_specs_reviewer_specification.md` §6.

## Quick start

The app is not published; it is run from this checkout. Its **only run
prerequisite is a current `assets/spec_model.json`** — the snapshot is committed,
so a fresh clone runs immediately, and refreshing it is a separate step (see
Usage below).

```bash
flutter pub get
flutter analyze
flutter test
flutter run        # or: flutter build bundle | web | linux | macos
```

`flutter run` opens on the start page: the model stamp bar across the top, the
14 document roots in the left rail, and the tree for whichever root is selected.

## Usage

### Refreshing the model snapshot

`assets/spec_model.json` is a **committed snapshot, not a build artifact**. The
stamp bar shows the export time, the class and root counts and the container
root; it turns into a **warning** when the snapshot is older than two weeks or
when its declared counts disagree with its own payload. Both conditions mean the
same thing to a reviewer — *you may be recording judgements against a model that
has moved* — and the cure is one command, run from
[`tom_specs_clitool`](../tom_specs_clitool):

```bash
cd ../tom_specs_clitool
dart run bin/model_json.dart --target reviewer
```

Naming the target is what keeps the stamp right: the target owns the output
path, and the stamp is derived from the model's own `version.versioner.dart`, so
neither can be supplied wrongly. Refreshing this snapshot is a **re-export of
the current model, never a renumbering of it** — which the derived stamp
expresses exactly, since `modelVersion` stays put while `modelVersionLabel`
records the build the snapshot was taken from. The editor's copy of the same
export carries the same stamp, because the two assets are one export of one
model. The full procedure for both targets lives in one place:
[`tom_specs_model_meta_schema.md`](../tom_specs_model/doc/tom_specs_model_meta_schema.md),
"Refreshing the committed assets".

Expected stamp after a clean refresh:

| Key | Value |
| --- | --- |
| `modelVersion` / `modelVersionLabel` | `1` / `1.1.0+5.a15517b3` |
| `metaSchemaVersion` | `1` |
| `classCount` | 1254 |
| `rootCount` | 14 |
| `containerRoot` | `DocSpecsProject` |

`modelVersion` is the **major** of `modelVersionLabel` — the two are one fact in
two forms, so a snapshot whose counter does not match its own label's major
describes no model that ever existed.

Only `generatedAt` and the build component of `modelVersionLabel` should differ
when the model itself has not moved. A change in `classCount` or `rootCount`
means the model *has* moved — expected after model work, and worth a glance at
the diff before committing. Note that a doc-comment edit in `tom_specs_model`
also changes the export, because doc comments travel with the model as
`@ContentHelp` text.

This table is a **maintained baseline**, not decoration: four tests in
`test/widget_test.dart` pin it to the shipped asset, so a refresh against a
differently sized model fails the suite until the table is updated with it.

### Walking a document and recording a finding

1. Pick a root in the left rail. Leave the two cut toggles on — they stop the
   tree at `@MapsTo` / `@DetailedIn` hand-offs, which is what makes one root
   readable without the other thirteen.
2. Expand to the node the judgement is about. Chips on the row carry what the
   model already declares: its routing verdicts, its hand-offs, its closed
   choices.
3. Open the node's review controls and record the judgement. Destination, scope
   and comment are always visible; the axis-specific groups (structure,
   annotations, CodeSpecs mapping, follow-up mapping, no-artifact) collapse
   until they hold something.
4. The finding is written through immediately — there is no explicit save.

### The review file

Findings are written to `structure_review.yaml`, keyed by structural path. The
file holds the **review payload only**. It is a clean reverse mapping onto the
object model, so view state (toggles, expansion) is deliberately kept out of it
— the file never carries anything that is not a statement about the model.

Its location can be overridden with the `TOM_SPECS_REVIEW_FILE` environment
variable; the default is `<cwd>/review/structure_review.yaml`:

```bash
TOM_SPECS_REVIEW_FILE=/path/to/review/my_pass.yaml flutter run
```

## Architecture

Five source files, split by responsibility, over the two shared layers in
`tom_som_dart_runtime`:

```
                    assets/spec_model.json          structure_review.yaml
                             │                                │
                             ▼                                ▼
                        lib/main.dart  ──── loads both before the first frame
                             │
                             ▼
                    lib/src/ui/start_page.dart
                    root rail · stamp bar · view toggles
                             │
                             ▼
                    lib/src/ui/spec_tree.dart ───► lib/src/ui/review_controls.dart
                    the tree and all rendering     the per-node review dialog
                             │                                │
                             └────────────┬───────────────────┘
                                          ▼
                            lib/src/model/review_store.dart
                                          │
                                          ▼
              tom_som_dart_runtime : readers + display semantics (shared)
```

| Type | Responsibility |
| --- | --- |
| `SpecsReviewerApp` | The `MaterialApp` root; mounts the start page over the loaded snapshot and store |
| `StartPage` | Root rail, model stamp bar, view toggles — the state held above the tree so it survives a document switch |
| `ModelStampBar` | Renders the snapshot stamp and raises the staleness warning |
| `SpecTree` / `SpecTreeScope` | The structure tree and every annotation rendering; the scope carries the toggles and the store down the tree |
| `ReviewControls` | The per-node review dialog and the one-line summary shown on the row |
| `ReviewEntry` | One node's recorded judgement — the full review vocabulary as fields |
| `ReviewStore` | The keyed collection of entries, its YAML persistence, and change notification |
| `ReviewDestination` / `ReviewScope` | The two closed choices with an explicit undecided state |

The **readers** (`SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`,
`FormFieldSpec`, `SpecFieldKind`) and the **display semantics** (`SpecChip`,
`SpecRowExtras`, `kRenderedAnnotations`) are not app-local — they live in
`tom_som_dart_runtime` and are shared with the editor. Only the paint is here.

## Ecosystem

```
            tom_specs_model              ← the SOM source model
                    │
                    │  exported by tom_specs_clitool/bin/model_json.dart
                    ▼
          assets/spec_model.json  (committed snapshot, one export, two targets)
                    │
        ┌───────────┴────────────┐
        ▼                        ▼
  tom_specs_reviewer      tom_forge/tom_specs_editor
  ← this package             the authoring app
        │                        │
        └──── both read ─────────┘
                    ▼
          tom_som_dart_runtime + tom_specs_core
          readers · display semantics · CodeSpecPart vocabulary
```

Nothing depends on `tom_specs_reviewer`. It is a leaf, deliberately outside the
release-1 set, and its output is a YAML file read by people changing
`tom_specs_model`.

It does **not** depend on `tom_som_dart_v0`, the typed facade, and that is a
decision rather than an omission: the facade earns its keep by making document
*edits* correctness-checked by the generated model, and this app loads the class
graph, never a document (`tom_specs_reviewer_specification.md` §2.4).

## Further documentation

**TomSpecs subject matter** — the authorities this package serves:

| Document | Authority for |
|----------|---------------|
| [index.md](../tom_specs_model/doc/index.md) | The catalogue of the whole TomSpecs document set, and the `§` citation convention used throughout it |
| [tom_specs_reviewer_specification.md](../tom_specs_model/doc/tom_specs_reviewer_specification.md) | What this app must be — purpose, inputs, the start page, the tree, the review vocabulary, persistence |
| [tom_specs_model_meta_schema.md](../tom_specs_model/doc/tom_specs_model_meta_schema.md) | The snapshot's on-disk schema, its two version stamps, and the refresh procedure for both committed assets |
| [tom_specs_model_rules.md](../tom_specs_model/doc/tom_specs_model_rules.md) | What each annotation the tree draws means, and the structural invariants a finding may be about |
| [codespecs_mapping.md](../tom_specs_model/doc/codespecs_mapping.md) | The `CodeSpecPart` catalogue and the three routing verdicts `@CodeSpecKind` / `@FollowUpKind` / `@NoArtifact` that this app records judgements against |
| [tom_specs_editor_specification.md](../tom_specs_model/doc/tom_specs_editor_specification.md) | The *other* app — what a specification editor is, and why this one is not it |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_specs_model](../tom_specs_model) | The SOM source model this app reviews |
| [tom_specs_clitool](../tom_specs_clitool) | The exporter that produces `assets/spec_model.json` |
| [tom_som_dart_runtime](../tom_som_dart_runtime) | The shared readers and annotation display semantics |
| [tom_specs_core](../tom_specs_core) | The annotation vocabulary, including the `CodeSpecPart` enum a proposed mapping is validated against |

## Status

Version **1.0.0+1**, `publish_to: 'none'` — a workspace tool, outside the
release-1 published set and excluded by name in
`tom_specs_clitool/tool/release_set.yaml`.

Functional. Two test files — `test/widget_test.dart` and
`test/structure_annotation_rendering_test.dart` — carrying **126 tests**, all
green. Several of them render the **shipped asset** rather than a fixture,
deriving every expectation from it, because the risk they guard is precisely
that the renderer handles a hand-made shape and not the real one.

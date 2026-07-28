# TomSpecs Reviewer — Specification

**Quest:** tom_specs
**Project:** `tom_ai/ai_build/tom_specs_reviewer`
**Status:** Implemented — this document specifies the application as it stands.
**Scope:** A Flutter app for **reviewing the TomSpecs object model**. It browses
the exported class graph as a tree and records structural observations keyed by
structural path. Those observations feed further development of
`tom_specs_model` itself.

> The reviewer is **not** a specification editor. The app that authors actual
> specifications (DocSpecs / CodeSpecs / Implementation) is
> `tom_forge/tom_specs_editor` — see `tom_specs_editor_specification.md`. The
> two apps share their model *readers* **and the display semantics of the
> annotations** (both in `tom_som_dart_runtime`); the tree *rendering* is
> app-local in each, and a shared fixture keeps the two renderings from
> drifting apart (§3).

---

## 1. Purpose

The object model is large — over a thousand classes across fourteen document
roots — and is developed by reading it, not by reading about it. The reviewer
exists so that reading it produces something durable: a judgement recorded
against the exact structural position that provoked it, in a file that maps
cleanly back onto the model.

Three properties follow from that purpose and constrain every design decision
below:

1. **The review file is a reverse mapping onto the model, nothing else.** It
   holds review payload only. View state — which nodes are expanded, which
   toolbar toggles are on — is deliberately excluded, so the file never carries
   anything that is not a statement about the model.
2. **A judgement targets structure, not a rendered instance.** All elements of a
   list share one path segment, so a decision about a list element is a decision
   about the element *type*.
3. **Nothing the model states may be invisible.** A reviewer cannot flag what
   the tree does not draw, so every annotation the export emits is rendered, and
   that coverage is enforced by a test rather than by discipline.

---

## 2. Inputs

### 2.1 The model snapshot

`assets/spec_model.json` is the exported class graph — a **committed snapshot,
not a build artifact**. It is produced by
`tom_specs_clitool/bin/model_json.dart` from the `tom_specs_model` package
sources via the Dart analyzer.

Refreshing is a re-export of the current model, never a renumbering of it:

```bash
cd ../tom_specs_clitool
dart run bin/model_json.dart \
  --package ../tom_specs_model \
  --output ../tom_specs_reviewer/assets/spec_model.json \
  --model-version 9 \
  --model-label "1.0.0+9"
```

`tom_specs_clitool/bin/build.dart` is **not** the reviewer's refresh path: it
writes the editor's copy of the asset, and it derives the model version from
the model package's pubspec major rather than from the fixed model-version
counter.

The snapshot stamp — model version and label, meta-schema version, class and
root counts, container root — is recorded in the project README, so a refresh
can be diffed against a baseline. Three tests pin that recorded baseline to the
shipped asset, so it cannot drift into fiction unnoticed.

### 2.2 The `CodeSpecPart` vocabulary

The reviewer depends on `tom_specs_core` for the `CodeSpecPart` and
`FollowUpProcess` enums directly, rather than harvesting the codes that appear
in the snapshot. Sourcing them from the enum keeps every *declared* kind
proposable — including a kind no section maps to yet, which is precisely the
case a reviewer needs to be able to record.

### 2.3 The review file

Findings are written to `structure_review.yaml`. Its location is
`$TOM_SPECS_REVIEW_FILE` when set, otherwise `<cwd>/review/structure_review.yaml`.

### 2.4 What is deliberately not an input: the typed `_v0` facade

The reviewer reads the **class graph** and writes its **review file**. It never
loads a specification *document*, and that is the whole of the read-only
property — not a restraint applied to an editing capability, but the absence of
a document plane.

That is why the reviewer depends on the generic runtime
(`tom_som_dart_runtime`) and **not** on the typed `tom_som_dart_v0` facade. The
typed model (`D00SolutionBlueprint` over a `SpecDocument`) earns its keep by
making document *edits* correctness-checked by the generated model rather than
by convention. With no document and no edits, it would check nothing here;
adopting it would first require giving the reviewer the document plane it
deliberately does not have — at which point the app would be
`tom_forge/tom_specs_editor`, which already exists and already embeds this
tree's structure browser (§3.1).

So the dependency set is the reviewer's settled shape rather than a stage on
the way to a richer one. The place this decision is most likely to be
undone — the `dependencies:` block of `pubspec.yaml` — carries a comment saying
so.

---

## 3. Architecture

Five source files, split by responsibility:

| File | Responsibility |
| --- | --- |
| `lib/main.dart` | Loads the snapshot and the review file, then mounts the app |
| `lib/src/ui/start_page.dart` | Root rail, model stamp bar, view toggles |
| `lib/src/ui/spec_tree.dart` | The structure tree and all annotation rendering |
| `lib/src/ui/review_controls.dart` | The per-node review dialog and its summary line |
| `lib/src/model/review_store.dart` | `ReviewEntry`, `ReviewStore`, YAML persistence |

Startup is synchronous and total: the snapshot is decoded and the review file
loaded before the first frame, so no screen ever renders against a partially
loaded model.

### 3.1 What the reviewer shares with the editor

Two Flutter surfaces render the same class graph — this reviewer on a light
standalone canvas, `tom_forge/tom_specs_editor` inside the dark Forge shell.
The boundary between them is drawn at **meaning versus paint**:

| Layer | Home | Shared? |
| --- | --- | --- |
| Readers — `SpecModel`, `SpecRoot`, `SpecClass`, `SpecField`, `FormFieldSpec`, `SpecFieldKind` | `tom_som_dart_runtime/src/spec_model.dart` | yes |
| Display semantics — `SpecChip`, `SpecChipRole`, `SpecRowExtras`, the chip descriptor functions, `kRenderedAnnotations`, the structural-path segments | `tom_som_dart_runtime/src/spec_annotation_display.dart` | yes |
| Rendering — the widgets, the palette, the per-row affordances | each app's own tree | no |

**The two surfaces may not disagree about what a marker *means*; they may
disagree about what it *looks like*.** Whether `cs?` is suppressed on a
follow-up-tagged node, whether a closed choice reports coverage, whether a
`@SectionIdPattern` is a fallback for a section id — these are statements about
the model, and one app answering them differently would make the same tree say
two different things. Colour is the opposite: a value that reads as "attention"
on a light canvas is illegible on a dark one. So chips name a `SpecChipRole` and
each app maps roles to its own palette.

The two renderings stay **separate** rather than being merged into a shared
widget package. They sit in different hosts (a standalone `MaterialApp` versus a
four-region Forge layout) and carry different per-row affordances (this app's
`ReviewControls` versus the editor's authoring actions), so a common widget would
be a parameter list of differences rather than shared behaviour. What is genuinely
common is the semantics, and that is what has been extracted.

**The divergence guard.** Separate renderings would otherwise drift silently, so
`tom_som_dart_runtime/spec_display_fixture.dart` carries a class graph that
exercises **every** annotation in `kRenderedAnnotations`, plus
`expectedShowcaseChipLabels`, which computes the labels the shared descriptors
produce for it. Both apps render that fixture in a widget test and assert every
label reaches the screen (`test/structure_annotation_rendering_test.dart` in
each). A new annotation therefore has to pass three gates: it must join
`kRenderedAnnotations`, then the fixture, then **both** trees — and a rendering
added to one tree alone fails the other app's test rather than accumulating
unnoticed.

---

## 4. The start page

### 4.1 Root rail

The left rail lists the fourteen `@Document` roots by title, with their section
id and class name beneath. A root whose class carries `@CodeSpecsProjection`
shows a projection badge.

**CGP is a projection, not a fourteenth authored document.** It re-reaches the
`@CodeSpecKind`-tagged subtrees that already live under the other roots,
regrouped by the shared / client / server locus they generate into. A class
seen under CGP is therefore the *same* class seen under its authoring root, and
a review recorded against it is recorded against that one class. The badge
exists so a reviewer reads it that way rather than recording duplicates.

### 4.2 Model stamp bar

A single line above the tree states which snapshot is loaded: model version and
label, when it was generated and how long ago, the class and root counts the
payload actually carries, and the container root.

It turns from neutral to a warning, with the finding spelled out, when either
of two independent things holds:

- **Aged** — generated more than fourteen days ago. The threshold is the
  observed cadence of model change: a snapshot that has survived a fortnight
  has most likely been overtaken, and structural feedback recorded against it
  would be keyed to paths the model has moved past.
- **Counts disagree** — the declared class or root count differs from what the
  payload holds. Only this one is a defect *in the file*: the exporter derives
  both counts from the payload it writes, so a disagreement means the file was
  edited or truncated after export.

Every part of the line degrades independently. A snapshot that declares no
counts contributes no count segment rather than rendering a null, and an
unknown age is never reported as a stale one.

### 4.3 View toggles

Three switches, held on the start page above the tree so they survive a
document switch:

| Toggle | Effect |
| --- | --- |
| Cut at detail hand-offs | Stop descending where a class carries `@DetailedIn` pointing out of the current root |
| Cut at maps hand-offs | Stop descending where a class carries `@MapsTo` pointing out of the current root |
| Show serialization order | Reveal the `@SerializationOrder` ordinal badges |

The two cuts show the handing-off section but suppress its descendants. This is
what makes a single root readable on its own: without them, every root drags in
the subtrees that other documents are responsible for.

---

## 5. The structure tree

### 5.1 Structural paths

A node's identity is the chain of member names from the document root, joined
with `/`, plus three synthetic segments:

| Segment | Stands for |
| --- | --- |
| `§item` | Any element of a list — all rendered elements share it |
| `§content` | A list section's own introductory content paragraph, distinct from the list and from its items |
| `§oneof` | The closed-choice group a class declares, distinct from the alternatives |

`§item` is what makes property 2 of §1 true. `§content` exists because in
TomSpecs every list *is* a document section, so besides its repeated items it
always carries an intro paragraph that is reviewable in its own right. `§oneof`
gives the *closure decision* — is this case set complete, and is closing it
here right? — its own entry, instead of hijacking one alternative's.

### 5.2 Rendered annotations

Every annotation the export emits reaches the screen:

| Group | Annotations | Rendering |
| --- | --- | --- |
| Identity and headline | `@Document`, `@SectionId`, `@SectionIdPattern`, `@Headline` | Root rail; grey badges on the row; quoted secondary label |
| Shape | `@Form`, `@ContentType`, `@Min`, `@ContentHelp` | Form panel under the row; the row's type label; the row's doc line |
| Hand-offs and taxonomies | `@MapsTo`, `@DetailedIn`, `@CodeSpecKind`, `@FollowUpKind`, `@CodeSpecsProjection` | `maps→` / `detail→` chips (also the cut anchors); part and process chips; projection badge |
| Closed choices | `@OneOf`, `@Case` | The choice group node with discriminator coverage; `case:` chips on the alternatives |
| Markers, notes, provenance | `@Unused`, `@Comment`, `@Reference`, `@StandardReferences`, `@SerializationOrder` | Struck-through label plus `unused` chip; inline `←` note; a collapsed `refs` panel; `#n` badge behind the toolbar toggle |

A `kRenderedAnnotations` set names them, and a test diffs it against the shipped
asset. An annotation the model *starts* emitting therefore fails the suite
rather than passing unseen — property 3 of §1, enforced rather than intended.
The set lives in `tom_som_dart_runtime` alongside the chip descriptors that
produce the renderings, so the reviewer and the editor cannot answer "is this
annotation accounted for?" differently (§3.1).

References sit behind a `refs` chip rather than inline because thousands of
fields carry standards; inlining them would bury the structure the reviewer came
to read.

### 5.3 The destination chip row

`@CodeSpecKind` and `@FollowUpKind` are rendered together, because they
interact. A node tagged for a follow-up process **has** been classified, so it
must not also carry the `cs?` "not yet mapped" marker — that would state the
opposite and send a reviewer chasing a CodeSpecs mapping that by construction
cannot exist.

The two are deliberately asymmetric:

- `@CodeSpecKind` renders **three states** — mapped, explicitly mapped to
  nothing, and undeclared. The third is exactly the open question a structural
  reviewer is hunting for; leaving it blank would hide it among the mapped ones.
- `@FollowUpKind` has **no "not declared" chip**. The overwhelming majority of
  the model is CodeSpecs-bound, so a `fu?` on every node would be noise.

Both links are list-valued — one section can become several parts, or feed
several processes — so every code gets its own chip rather than a joined string.
Case chips come first on a field row, because they say *whether the row applies
at all*, which is a stronger statement than where its subtree is headed.

### 5.4 Navigation

Hand-off chips are clickable. Following one switches to the target document and
walks the class graph to the target class, expanding the chain and scrolling the
endpoint into view. The path is the shortest chain of class names found by
breadth-first search over the graph; an unreachable target simply selects the
document root.

---

## 6. The review vocabulary

Six axes, recorded per structural path. The dialog shows destination, scope,
the stop-here / add-details markers, the reviewed checkmark and the free-text
comment unconditionally; the four axis-specific groups are collapsible.

| Axis | Records |
| --- | --- |
| **Destination** | Where the subtree belongs: CodeSpecs, follow-up, both, neither — or undecided |
| **Scope and progress** | Scope, "stop here" / "add details" markers, reviewed checkmark, free-text comment |
| **Structure** | List-vs-single, content-vs-form, and the closed-choice judgements (these siblings are really alternatives; the closed set is missing a case) |
| **Annotations** | Section id / pattern wrong or colliding, handoff pointing at the wrong target, wrong `@ContentType`, standard references wrong or missing, and the keep-or-drop verdict on an `@Unused` marking |
| **CodeSpecs mapping** | Should carry a `@CodeSpecKind` and does not; declared kinds wrong or incomplete; the `CodeSpecPart` kinds proposed instead; should not be realised as code at all |
| **Follow-up mapping** | Should carry a `@FollowUpKind` and does not; declared processes wrong or incomplete; the `FollowUpProcess` codes proposed instead |

Four decisions shape this vocabulary.

**Destination is one enum, not two booleans.** The CodeSpecs / follow-up split
is a choice, and paired flags would admit the meaningless "neither and both".
`unset` is deliberately distinct from `neither`, so "no judgement yet" never
reads as "drives no downstream work".

**The `@Unused` verdict is one decision, not two independent flags.**
Confirming and rejecting are mutually exclusive, enforced by counterpart-clearing
setters so exclusivity survives a load as well as a click. A file that asserts
both drops the *confirmation*: confirming authorises a deletion, and an
ambiguous source must never authorise one.

**Proposed kinds are validated asymmetrically — warn where the vocabulary is
open, reject where it is closed.** `CodeSpecPart` is a closed catalogue, so an
unrecognised token there is a typo and is rejected at entry. `FollowUpProcess`
declares itself extensible, so an unrecognised code is a *proposal to extend
it* — one of the most valuable findings available, and one a strict validator
would make unsayable. Unknown follow-up codes are kept, flagged with an amber
chip and an explanatory line, and a free-text field sits beside the dropdown so
a process nobody has named yet can actually be entered.

**A group holding a judgement opens expanded.** Expansion is computed from the
entry when the dialog opens and held in the dialog's own state, rather than by
an `ExpansionTile` reading remembered `PageStorage` state — which could override
the initial value and hide recorded feedback behind a collapsed header, the one
failure mode a collapsible review dialog must not have.

Each node's row carries a one-line summary of its entry, so recorded judgements
are legible while scanning the tree without opening anything.

---

## 7. Persistence

`ReviewStore` owns a single YAML file: a `version` stamp and an `entries` map
keyed by structural path. It writes on every mutation, and drops entries that
have become empty so an abandoned judgement leaves no residue.

Reading is deliberately more lenient than writing. An entry rejects a blank
follow-up code but keeps an unrecognised one; an absent key reads as unset
rather than as a defect; and a file written by an earlier version loads with
every later axis unset. The file version therefore only advances when a change
is *not* purely additive — a bump signals an incompatibility, so bumping for
additions would cry wolf.

---

## 8. Quality

- `flutter analyze` clean; the full widget suite green.
- The coverage test diffs `kRenderedAnnotations` against the shipped asset.
- `structure_annotation_rendering_test.dart` renders the shared annotation
  showcase fixture and asserts every label the shared descriptors produce for it
  reaches the screen — the reviewer's half of the §3.1 divergence guard. Its
  expectations are *derived* from the descriptor functions, never written out,
  so a chip the display layer starts producing fails here until this tree
  renders it.
- Several tests render the **shipped asset** rather than a fixture, deriving
  every expectation from it — because the risk they guard is precisely that the
  renderer handles a hand-made shape and not the real one. A snapshot refresh
  therefore cannot make them wrong; only a renderer that stops covering the
  model can.
- Three tests pin the README's recorded snapshot stamp to the asset, so a
  refresh against a differently-sized model fails until the baseline is updated
  with it.

## 9. Running

```bash
flutter pub get
flutter analyze
flutter test
flutter run        # or: flutter build bundle | web | linux | macos
```

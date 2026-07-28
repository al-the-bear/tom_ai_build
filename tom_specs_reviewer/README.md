# tom_specs_reviewer

A Flutter tool for **reviewing the TomSpecs object model** (`tom_specs_model`).

It browses the exported spec model graph (`assets/spec_model.json`) as a tree
and lets a reviewer record observations keyed by structural path. Those
observations feed **further development of the object model itself**.

It is *not* a specification editor. The editor that authors actual
specifications (DocSpecs / CodeSpecs / Implementation specs) is a separate app,
`tom_specs_editor`, in the `tom_forge` repo.

## Refreshing the snapshot

`assets/spec_model.json` is a **committed snapshot, not a build artifact**. The
app shows a stamp bar with the export time, the class and root counts and the
container root; it turns into a warning when the snapshot is older than two
weeks or when its declared counts disagree with its own payload. The cure is
one command, run from `tom_specs_clitool`:

```bash
cd ../tom_specs_clitool
dart run bin/model_json.dart \
  --package ../tom_specs_model \
  --output ../tom_specs_reviewer/assets/spec_model.json \
  --model-version 9 \
  --model-label "1.0.0+9"
```

`--model-version` is **fixed at 9** and must never be bumped here: refreshing
is a re-export of the current model, not a change to it. (Do not refresh via
`tom_specs_clitool/bin/build.dart` — it writes the editor's copy of the asset
and derives the model version from the model package's pubspec major.)

Expected stamp after a clean refresh:

| Key | Value |
| --- | --- |
| `modelVersion` / `modelVersionLabel` | `9` / `1.0.0+9` |
| `metaSchemaVersion` | `1` |
| `classCount` | 1243 |
| `rootCount` | 14 |
| `containerRoot` | `DocSpecsProject` |

Only `generatedAt` should differ when the model itself has not moved. A change
in `classCount` or `rootCount` means the model *has* moved — expected after
model work, and worth a glance at the diff before committing. Note that a
doc-comment edit in `tom_specs_model` also changes the export, because doc
comments travel with the model as `@ContentHelp` text.

## Documents

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
such in the rail. It re-reaches the `@CodeSpecKind`-tagged subtrees that
already live under the other roots, regrouped by the shared / client / server
locus they generate into. So a class seen under CGP is the *same* class seen
elsewhere, and a review recorded against it is recorded against that one class.
Because its content is borrowed, the model validator exempts it from the
per-document detail-count check.

The toolbar carries three view toggles, held above the tree so they survive a
document switch: cut at detail hand-offs, cut at maps hand-offs, and show
serialization order. The two cuts stop the tree where a section hands its
detail to another document, which is what makes a single root readable on its
own.

## What the tree renders

Every annotation the exported model emits is accounted for — a
`kRenderedAnnotations` set names them and a test diffs it against the shipped
asset, so an annotation the model *starts* emitting fails the suite rather than
passing unseen.

- **Identity and headline** — `@Document` (the root rail), `@SectionId` and
  `@SectionIdPattern` (badges on the row), `@Headline` (quoted secondary label).
- **Shape** — `@Form` (the form panel under the row), `@ContentType` and `@Min`
  (the row's type label), `@ContentHelp` (the row's doc line).
- **Hand-offs and taxonomies** — `@MapsTo` and `@DetailedIn` (`maps→` /
  `detail→` chips, and the anchors the two cut toggles act on), `@CodeSpecKind`
  and `@FollowUpKind` (part / process chips), `@CodeSpecsProjection` (the
  projection badge).
- **Closed choices** — `@OneOf` (the choice group node) and `@Case` (`case:`
  chips on its alternatives).
- **Markers, notes and provenance** — `@Unused` (struck-through label plus an
  `unused` chip), `@Comment` (inline `←` note), `@Reference` and
  `@StandardReferences` (behind a `refs` chip — thousands of fields carry
  standards, and inlining them would bury the structure),
  `@SerializationOrder` (a `#n` badge, behind the toolbar toggle).

What each marker *says* is not the reviewer's own decision: the chip labels,
tooltips and suppression rules live in `tom_som_dart_runtime`, shared with
`tom_forge/tom_specs_editor`, which renders the same class graph in the Forge
shell. The two apps paint them differently — opposite backgrounds — but may not
disagree about their meaning. A showcase fixture in that package exercises every
annotation, and both apps run a widget test asserting each marker reaches their
screen, so a rendering dropped from one tree fails a test instead of drifting
apart quietly.

## What you can record

Per node:

- **Destination** — where the subtree belongs: CodeSpecs, follow-up, both or
  neither. One choice rather than competing booleans, with an explicit
  undecided state so "no judgement yet" is distinct from "neither".
- **Scope and progress** — scope, "stop here" / "add details" markers, a
  reviewed checkmark, plus a free-text comment. Always visible.
- **Structure** — list-vs-single, content-vs-form, and the closed-choice
  judgements (these siblings are really alternatives; the closed set is missing
  a case).
- **Annotations** — the section id / pattern is wrong or collides, the
  `@MapsTo` / `@DetailedIn` handoff points at the wrong target, the
  `@ContentType` is wrong, standard references are wrong or missing, and the
  keep-or-drop verdict on an `@Unused` marking (one verdict, so confirming and
  rejecting are mutually exclusive).
- **CodeSpecs mapping** — whether the node should carry a `@CodeSpecKind` and
  does not, whether the kinds it declares are wrong or incomplete, which
  `CodeSpecPart` kinds the reviewer proposes instead, and whether the node
  should not be realised as code at all. Proposed kinds are validated against
  the `CodeSpecPart` vocabulary at entry, so a recorded suggestion always maps
  back onto the model.
- **Follow-up mapping** — whether the node should carry a `@FollowUpKind` and
  does not, whether the declared processes are wrong or incomplete, and which
  `FollowUpProcess` codes the reviewer proposes instead. That taxonomy is
  explicitly extensible, so a code outside it is *warned about, not rejected* —
  proposing a process nobody has named yet is a legitimate finding.

The axis-specific groups are collapsible. A group that already holds a
judgement opens expanded, so recorded feedback is never hidden behind a
collapsed header.

## The review file

Findings are written to `structure_review.yaml`, keyed by structural path — the
chain of member names from the document root, with all elements of a list
sharing one `§item` segment. Keying on structure rather than on a rendered
instance means a decision about a list element is a decision about the element
*type*, and survives the list growing or shrinking.

The file holds the review payload only. It is a clean reverse mapping onto the
object model, so view state (toggles, expansion) is deliberately kept out of
it. Its location can be overridden with the `TOM_SPECS_REVIEW_FILE` environment
variable; the default is `<cwd>/review/structure_review.yaml`.

## Run

```bash
flutter pub get
flutter analyze
flutter test
flutter run        # or: flutter build bundle | web | linux | macos
```

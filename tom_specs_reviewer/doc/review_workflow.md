# Reviewing the TomSpecs object model

`tom_specs_reviewer` exists to answer one question, one node at a time: **is
this part of the object model right?** It browses the exported class graph as a
tree and records what a reviewer concludes, keyed by structural path, into a
file the model's authors then work from.

This guide is the reviewer's path through the tool: refresh the snapshot, open a
root, walk the tree, record a finding, find the file afterwards. What the
application *must be* — its screens, its review vocabulary field by field, its
rendering contract with the editor — is
[`tom_specs_reviewer_specification.md`](../../tom_specs_model/doc/tom_specs_reviewer_specification.md),
which this guide cites and never restates. The catalogue of what the tree draws
and what can be recorded is the [README](../README.md).

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
- [Step 1 — refresh the model snapshot](#step-1--refresh-the-model-snapshot)
- [Step 2 — open a document root](#step-2--open-a-document-root)
- [Step 3 — walk the tree](#step-3--walk-the-tree)
- [Step 4 — record a finding](#step-4--record-a-finding)
- [Step 5 — find the review file](#step-5--find-the-review-file)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

The reviewer is **not a specification editor.** It never changes a document; it
changes nothing at all except the review file. The thing it browses is the
*model* — the ~1250 classes and 14 document roots that decide what a
specification may contain — and the thing it produces is a list of judgements
about that model.

That makes the workflow short and the same every time:

| Step | You do | The tool does |
|------|--------|---------------|
| 1 | Refresh `assets/spec_model.json` if the stamp bar warns | Loads the exported class graph |
| 2 | Pick a document root in the left rail | Renders that root's tree |
| 3 | Expand to the node in question | Draws what the model already declares, as chips |
| 4 | Record the judgement | Writes it through immediately — there is no save |
| 5 | Read the review file | Keeps it keyed by structural path |

Everything else the app shows is in service of step 3: the chips on a row are
the model's own declarations, so a reviewer can see what is claimed before
deciding whether it is right.

## Quick Start

```bash
flutter pub get
flutter run
```

The snapshot is **committed**, so a fresh clone runs immediately — refreshing it
is a separate step and only needed when the stamp bar says so.

`flutter run` opens on the start page: the model stamp bar across the top, the
fourteen document roots in the left rail, and the tree for whichever root is
selected.

## Core Components

| What you see | What it is |
|--------------|------------|
| The **stamp bar** | The snapshot's export time, class and root counts, and container root. Turns into a warning when the snapshot is stale |
| The **root rail** | The fourteen `@Document` roots. `D00SolutionBlueprint` is the master; the other thirteen are projections over the same sections |
| The **tree** | One row per model member, with the model's own annotations rendered as chips |
| The **two cut toggles** | Stop the tree at `@MapsTo` / `@DetailedIn` hand-offs — what makes one root readable without the other thirteen |
| The **review controls** | The judgement form for the selected node |

## Step 1 — refresh the model snapshot

`assets/spec_model.json` is a **committed snapshot, not a build artifact**. The
stamp bar turns into a warning when it is older than two weeks, or when its
declared counts disagree with its own payload. Both mean the same thing to a
reviewer — *you may be recording judgements against a model that has moved* —
and the cure is one command:

```bash
cd ../tom_specs_clitool
dart run bin/model_json.dart --target reviewer
```

**Name the target.** `--target reviewer` owns both the output path and the
version stamp; the ad-hoc `--package … --output …` form would write the file but
stamp it wrongly, and the stamp is exactly what drives the staleness warning. A
mis-stamped snapshot is worse than a stale one, because it disables the signal
that would have reported the problem.

Refreshing is a **re-export of the current model, never a renumbering of it**.
The full procedure for both committed assets is
[`tom_specs_model_meta_schema.md`](../../tom_specs_model/doc/tom_specs_model_meta_schema.md),
"Refreshing the committed assets"; the baseline the shipped asset is expected to
match is the table in the [README](../README.md#refreshing-the-model-snapshot),
which four tests pin.

If the class or root counts changed, the model itself moved. That is expected
after model work and worth a glance at the diff — including after a *doc-comment*
edit in `tom_specs_model`, because doc comments travel with the model as
`@ContentHelp` text.

## Step 2 — open a document root

Pick a root in the left rail. Which one depends on the question:

- Reviewing the model as a whole → **`D00SolutionBlueprint`**, the master that
  owns every section.
- Reviewing one Phase 3 document's shape → its own root, which shows only the
  sections that flow into it.
- Reviewing what Phase 4 consumes → **`D13CodeSpecsProjection`**.

**Leave the two cut toggles on.** They stop the tree at `@MapsTo` /
`@DetailedIn` hand-offs, which is what makes one root readable without dragging
in the other thirteen. Turning them off is for the rare case where the question
is about the hand-off itself.

## Step 3 — walk the tree

Expand to the node the judgement is about. Before deciding anything, read what
the row already claims — the chips are the model's own declarations, not the
app's opinion:

| Chip | Says |
|------|------|
| A section-id badge | The node's `@SectionId`, or the `@SectionIdPattern` its list items are numbered from |
| `maps→` / `detail→` | Where this subtree hands off, and to which document |
| A part / process / `na:<reason>` chip | The node's routing verdict — `@CodeSpecKind`, `@FollowUpKind` or `@NoArtifact` |
| `case:` | The `@OneOf` alternative this subsection is bound to |
| `unused`, a struck-through label | `@Unused` — text here is not expected |
| `refs` | Standard references, folded away because thousands of fields carry them |
| `#n` | The `@SerializationOrder` stamp, behind the toolbar toggle |

What each marker *means* is not this app's decision — the labels, tooltips and
suppression rules live in `tom_som_dart_runtime` and are shared with the Forge
editor, so the two apps cannot disagree about a marker's meaning even though
they paint it differently.

## Step 4 — record a finding

Open the node's review controls and record the judgement. Three fields are
always visible; the rest collapse until they hold something.

| Always visible | For |
|----------------|-----|
| **Destination** | Where the subtree belongs — CodeSpecs, follow-up, both, or neither. One choice with an explicit undecided state, so "no judgement yet" is distinct from "neither" |
| **Scope**, `stop here`, `add details`, reviewed | How far the model should go here, and how far *you* got |
| **Comment** | Free text — the thing a checkbox cannot say |

The axis-specific groups — structure, annotations, CodeSpecs mapping, follow-up
mapping, no-artifact — are collapsible, and a group that already holds a
judgement opens expanded, so recorded feedback is never hidden behind a
collapsed header. Their full vocabulary is
[`tom_specs_reviewer_specification.md`](../../tom_specs_model/doc/tom_specs_reviewer_specification.md)
§6.

**There is no save.** The finding is written through immediately, which is why
closing the app never loses one.

Two entry behaviours are worth knowing because they differ, and deliberately:

- A proposed **`CodeSpecPart`** kind is *validated at entry* — a recorded
  suggestion always maps back onto the model.
- A proposed **`FollowUpProcess`** code is *warned about, not rejected*. That
  taxonomy is explicitly extensible, so proposing a process nobody has named yet
  is a legitimate finding rather than a typo.

## Step 5 — find the review file

Findings land in `structure_review.yaml`, keyed by structural path:

```yaml
# TomSpecs structure review.
# Keyed by structural path into the specification object model.
# Generated by tom_specs_reviewer — edit via the app.
version: 2
entries:
  "D00SolutionBlueprint/currentLandscape":
    scope: "global"
    reviewed: true
    destination: "code_specs"
    comment: "Operational metrics belong under the entity, not here."
  "D00SolutionBlueprint/currentLandscape/CUOPME-OPER-LST":
    scope: "only_pd"
    must_be_list: true
    add_details: true
```

Three properties of that file matter to a reader:

1. **The key is the structural path**, so a finding points at a node in the
   model rather than at a screen position.
2. **Only recorded judgements appear.** A field absent from an entry was not
   judged — the file never asserts a default.
3. **It holds the review payload only.** View state — toggles, expansion — is
   deliberately kept out, so the file is a clean reverse mapping onto the object
   model and nothing in it is a statement about the app.

Its location is `<cwd>/review/structure_review.yaml` by default, overridable per
run:

```bash
TOM_SPECS_REVIEW_FILE=/path/to/review/my_pass.yaml flutter run
```

Give a separate pass its own file. The store is keyed by path, so two reviewers
writing one file overwrite each other's judgement on any node they both visit.

## Error Handling

| Symptom | What it means | What to do |
|---------|---------------|-----------|
| The stamp bar is a **warning** | The snapshot is over two weeks old, or its counts disagree with its payload | Refresh it — step 1 |
| Class or root counts changed after a refresh | The model moved | Expected after model work; check the diff, and update the README baseline table |
| The suite fails after a refresh | The README's baseline table no longer matches the shipped asset | Update the table — it is a maintained baseline, and four tests pin it |
| A proposed CodeSpecs kind is rejected at entry | It is not a `CodeSpecPart` | Use a real kind; the vocabulary is closed |
| A proposed follow-up code is **warned about** | It is outside `FollowUpProcess` | Keep it if you mean it — that taxonomy is extensible |
| A finding you recorded is not in the file | The app writes through immediately, so it is almost certainly a different file | Check `TOM_SPECS_REVIEW_FILE` and the working directory |

The app throws nothing at a reviewer. Its failure modes are all "you are looking
at the wrong model" or "you are looking at the wrong file", which is why the
stamp bar and the review-file path are both surfaced rather than buried.

## Best Practices

- **Refresh before a pass, not during one.** A snapshot that changes mid-review
  makes judgements recorded against two different models indistinguishable.
- **Always use `--target reviewer`.** The ad-hoc export writes the file with the
  wrong stamp, which disables the staleness warning.
- **Leave the cut toggles on.** Without them one root drags in the other
  thirteen and the tree stops being readable.
- **Read the chips before judging.** Half of what looks like a finding is the
  model already declaring the thing you were about to propose.
- **Write a comment whenever a checkbox is not the whole story.** The structured
  axes are for aggregation; the comment is what the model's author actually
  acts on.
- **Give each pass its own review file.** The store is keyed by path, so two
  people sharing one file overwrite each other silently.

---

Back to the [README](../README.md).

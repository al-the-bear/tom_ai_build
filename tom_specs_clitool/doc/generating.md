# TomSpecs CLI Tool — Generating

Everything downstream of the Dart model is generated from it: nine typed
language facades, their metadata trees, the DocSpecs schemas, the ops registry
and the CodeSpecs area catalogue. This guide is the operator's view — what to
run, in what order, what each run prints, and what the freshness stamp catches
when a step is skipped. The *config block* is
[`som_generator_config.md`](../../tom_specs_model/doc/som_generator_config.md)
and what gets emitted per language is
[`som_multiplatform_spec_model.md`](../../tom_specs_model/doc/som_multiplatform_spec_model.md)
§5; both are cited here, never restated.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
  - [The canonical regeneration](#the-canonical-regeneration)
  - [Reading the output](#reading-the-output)
- [Stamping serialization order](#stamping-serialization-order)
- [The ad-hoc entry points](#the-ad-hoc-entry-points)
- [The freshness stamp](#the-freshness-stamp)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

One command does the whole job. `generate_som.dart` is the **canonical**
regeneration: it stamps, emits the ops registry, generates all nine language
projects with their metadata and schemas, writes each package's packaging docs,
and finally records the model fingerprint the freshness test checks against.

The other generator entry points exist for the cases the canonical run does not
cover — writing one artefact somewhere else, or refreshing one thing without a
nine-language run. Reaching for them by default is the mistake to avoid: they
produce a *subset*, and a subset is what a stale package looks like.

Every one of these is idempotent. Running the canonical generation twice over an
unchanged model produces byte-identical output, which is what makes "re-run it
and commit the diff" a safe instruction.

## Quick Start

```bash
cd tom_ai/ai_build/tom_specs_clitool

# 1. After any model edit: re-stamp, regenerate, re-outline.
dart run bin/stamp_serialization_order.dart --package ../tom_specs_model
dart run bin/generate_som.dart
./tool/regenerate_outlines.sh
```

Step 1 is optional in practice — `generate_som.dart` re-stamps as its first act
— but running it alone is how you check what a model edit did before committing
to a full generation.

## Core Components

### The canonical regeneration

`generate_som.dart` runs five phases in order:

| Phase | Produces |
|-------|----------|
| Re-stamp | `@SerializationOrder` renumbered from source order |
| Spec-ops | `tom_specs_model/lib/src/generated/spec_ops.g.dart` |
| Per-language emit | Nine `tom_som_<lang>_v0` projects: typed facade, metadata module, `meta/spec_model.meta.json`, `schemas/`, manifest |
| Packaging | Each facade's `README.md`, `readme_howtointegrate.md`, `LICENSE`, `CHANGELOG.md`; each runtime's manifest version |
| Stamp | `tool/model_surface.stamp.json` — the model fingerprint |

The order is not arbitrary. Stamping first means the emitters never see an
unstamped member; the fingerprint is written last, so it records the model the
packages were actually generated from.

Options let you point it elsewhere — `--config`, `--model`, `--runtime` and a
`--<lang>-runtime` per language — but the defaults resolve the whole workspace,
so a normal run takes none.

### Reading the output

A clean run prints a header, then one block per language:

```
generate_som: restamped @SerializationOrder — files changed: 0, members stamped: 5153, restamped: 5153
generate_som: spec-ops registry — 1254 classes, unchanged → lib/src/generated/spec_ops.g.dart
generate_som: config <…>/tom_specs_clitool/tom_som.yaml
  model:   <…>/tom_specs_model
  runtime: <…>/tom_som_dart_runtime
  version: 1  (label: 1.1.0+5.a15517b3)
  roots:   all

── generating dart → <…>/tom_som_dart_v0
  classes: 1254  roots: 14  schemas: 14
  meta:    <…>/tom_som_dart_v0/meta/spec_model.meta.json
  lib:     <…>/tom_som_dart_v0/lib/tom_som_dart_v0.dart
  pubspec: <…>/tom_som_dart_v0/pubspec.yaml
  packaging: README + readme_howtointegrate.md @ v1.1.0
```

Three numbers are worth reading every time:

- **`files changed: 0`** on the re-stamp line means the model was already
  stamped — the expected state on a regeneration that follows no model edit. A
  non-zero count after you did *not* edit the model means someone else did.
- **`unchanged`** on the spec-ops line means the registry did not move. A
  `rewritten` there after a model edit is expected; after no edit, look again.
- **`classes` / `roots` / `schemas`** should be identical across all nine
  blocks. They are all derived from one model, so a language that disagrees is
  an emitter defect, not a model one.

The run closes with the fingerprint and, when the Dart facade moved, a note that
`tom_spec_engine`'s D4rt bridges are now stale.

## Stamping serialization order

`@SerializationOrder(n)` is the member's 0-based source-declaration position. It
is **stamped, never hand-written** — the generator refuses to run past an
unstamped member, so a forgotten stamp is a hard error rather than a silent
misordering.

```bash
dart run bin/stamp_serialization_order.dart --package ../tom_specs_model --dry-run
```

```
stamp_serialization_order: [dry-run] files changed: 0, members stamped: 5153, restamped (removed old): 5153
```

Read those three numbers precisely, because two of them do not mean what they
look like:

| Number | Means |
|--------|-------|
| `files changed` | Files whose content actually **differs** after stamping. `0` is the idempotent case |
| `members stamped` | Every member that carries a stamp — the model's size, not the diff |
| `restamped (removed old)` | Every member whose existing stamp was replaced. Equal to `members stamped` on a fully-stamped model, because stamping is remove-and-rewrite |

So `files changed: 0` with five thousand "stamped" members is the normal,
already-correct state. Only the first number describes a change.

Drop `--dry-run` to write. The workflow after adding a member is: insert it
where it belongs in the source, then re-stamp — never renumber the neighbours by
hand.

## The ad-hoc entry points

Each of these produces a *subset* of what the canonical run produces. Reach for
one only when you know why the canonical run is not what you want.

| Entry point | Produces | Reach for it when |
|-------------|----------|-------------------|
| `spec_ops.dart` | The `SpecClassOps` registry alone | Writing it somewhere else (`--output`), or refreshing it against a given model without a nine-language run |
| `docspecs_schema.dart` | The DocSpecs schema tree for one model package | Emitting a schema into a non-default `--out-dir`, stamped with a specific `--version` / `--label` |
| `docspecs_yaml_schema.dart` | The YAML schemas | Same, for the other artefact — it is a separate entry point because the two emit different things from different inputs |
| `codespecs_areas.dart` | The 27-area CodeSpecs catalogue JSON | Re-transcribing it after a mapping edit, or verifying the committed file |

`codespecs_areas.dart --check` verifies without writing, which is what the test
suite runs:

```
OK — up to date ../tom_specs_model/generated-doc/codespecs/codespecs_areas.json
  27 area(s), 7 slice(s), 15473 byte(s).
```

## The freshness stamp

`generate_som.dart` writes `tool/model_surface.stamp.json` from a fingerprint of
the model **source**, and `test/model_freshness_test.dart` recomputes it in the
default `dart test` run. So a model edit that never reached the nine language
packages fails a test rather than shipping.

The fingerprint covers the *input*, never the output. Fingerprinting the
generated `spec_model.meta.json` would let a stale package match a stamp taken
over its own stale self — the check would agree with itself and prove nothing.

One stamp covers all nine because the meta tree is generated first and every
language derives from it.

**Commit the stamp with the regenerated packages.** A stamp committed alone says
the model was generated when it was not; packages committed without it leave the
next test run red for the wrong reason.

## Error Handling

| Situation | Result |
|-----------|--------|
| A model member with no `@SerializationOrder` | Hard error before any emission; the generator refuses to run |
| A model edit with no regeneration | `model_freshness_test.dart` fails in the default suite |
| A `@SectionId` collision or other `tom_specs_model_rules.md` §10.2 invariant breach | The static validator reports it at generation time |
| A missing `--package` on `docspecs_schema.dart` | The `mandatory` option is reported and usage printed |
| The Dart facade regenerated | A note that `tom_spec_engine`'s bridges are stale — regenerate them |
| `codespecs_areas.dart --check` against a stale file | Non-zero exit naming the difference |

The generator is deliberately loud about the first two. A silent partial
generation is the failure mode every stamp and gate here exists to make
impossible.

## Best Practices

- **Run the canonical `generate_som.dart`, not a subset.** The ad-hoc entry
  points produce exactly what a stale package looks like.
- **Insert, then stamp.** Never renumber `@SerializationOrder` by hand.
- **Read `files changed`, ignore `members stamped`.** Only the first describes a
  change; the second is the model's size.
- **Commit the stamp with the packages.** They are one change.
- **Regenerate the bridges when the note appears.** The generator tells you; the
  engine's own freshness test will otherwise tell you later and less kindly.
- **Re-run the outliner after any model-shape change.** `regenerate_outlines.sh`
  also runs all three citation gates, so it is the cheapest way to find out you
  broke one.

---

Back to the [documentation index](index.md).

# Regenerating the nine `tom_som_<slug>_v0` packages

The TomSpecs object model is authored once, in `tom_specs_model`, and shipped in
nine languages. Each `tom_som_<slug>_v0` package under `tom_ai/ai_build` is
**generator output that is committed**: the typed facade sources, the lossless
`meta/spec_model.meta.json`, the 14 DocSpecs schemas, and the packaging files.
Consumers never run the generator — the committed artefacts are the product.

They are produced by `bin/generate_som.dart` from the `tom-spec-object-model`
block in [`tom_som.yaml`](../tom_som.yaml).

## Generated trees (do not hand-edit)

| Path | Contents |
|------|----------|
| `../tom_som_<slug>_v0/lib/` (or `src/`, `include/`, …) | The typed editing facade + its metadata module |
| `../tom_som_<slug>_v0/meta/spec_model.meta.json` | The lossless resolved class graph |
| `../tom_som_<slug>_v0/schemas/` | One DocSpecs schema folder per `@Document` root |
| `../tom_som_<slug>_v0/README.md`, `readme_howtointegrate.md`, manifest | Packaging, stamped with the model version |

Never edit them by hand. Change `tom_specs_model` and regenerate.

Hand-authored `test/`, `example/` and `examples/` directories are safe: the
generator only *writes* the module, `meta/`, `schemas/` and the manifest — it
never deletes.

## When to regenerate

**After every change to `tom_specs_model`.** Not only a structural one: the meta
is lossless, so all nine packages carry the model's *doc comments* and *every
annotation argument* — including an annotation's `note`. Rewording a doc comment
is a real change to all nine packages.

That is broader than it sounds, and broader than people remember, which is why
the rule is enforced rather than merely stated.

## How staleness is caught

`dart test` in this package fails when `tom_specs_model` has moved since the
committed packages were generated:

| Piece | Role |
|-------|------|
| [`lib/src/model_freshness.dart`](../lib/src/model_freshness.dart) | Fingerprints the model source the generator reads |
| `tool/model_surface.stamp.json` | The fingerprint the committed packages were generated from — written by `generate_som.dart`, committed alongside them |
| [`test/model_freshness_test.dart`](../test/model_freshness_test.dart) | Recomputes the fingerprint and fails when it no longer matches the stamp |

The failure names the delta (files, declarations) and tells you to regenerate.
The check is part of the **default** suite — it costs about a second, so it needs
no tag and cannot be skipped by habit.

A second test guards the guard: `somPackageCoverageMismatch` diffs the languages
configured in `tom_som.yaml` against the packages the stamp certifies and against
what is on disk, so adding a tenth language cannot leave the gate passing while
the thing it guards has grown.

### Why this is needed at all

The packages are generated **here** but their source is edited **elsewhere**, and
nothing in `tom_specs_model`'s own workflow prompts a regeneration. Two things
then go wrong, and neither is self-announcing — the committed packages are data,
so there is no compiler to notice:

- **The model gains something.** A new section, field, annotation or doc comment
  simply does not appear in any of the nine packages. Nothing goes red, ever.
- **The model changes something.** The nine packages go on describing the
  previous model, and every consumer reading the meta or validating against the
  schemas is working from it.

This is not hypothetical. The packages were stale from the commit that routed
CE-MG into Phase 3 until the next unrelated regeneration, which silently absorbed
the catch-up — and in doing so made *that* change's commit diff overstate what it
had actually changed. Both failure modes at once, plus a corrupted history.

### Why the model rather than the nine outputs

The meta tree is generated first and every language derives from it, so one
fingerprint over the model covers all nine — the nine committed metas do in fact
carry one identical substantive payload.

Fingerprinting the *outputs* would not work at all. `spec_model.meta.json` is
generated **from** the model, so a stale package would happily match a stamp
taken over its own stale self. Only the input can certify the output.

### Why a fingerprint rather than a regenerate-and-diff

Generation is idempotent, so a freshness check could regenerate into a temp
directory and diff. That was rejected: a full run costs about a minute, which
forces the check behind a tag, and a tagged check is exactly the one nobody runs.
Fingerprinting the *input* gets the same answer for the same reason — if the
input has not moved, the output cannot have.

Resolving the model (what `ModelReader` does) costs ~10 s and was rejected for
the same reason. The fingerprint parses **syntactically** instead, which brings
the whole model in under a second.

### What the fingerprint deliberately ignores

Taken over each file's token stream, so these are free and will not raise a false
alarm: **formatting** (`dart format` never moves it), **function bodies** (the
reader reads declarations, types and annotations — a body reaches nothing), and
**ordinary `//` comments**.

**Doc comments are *not* ignored** — they are exported into every language's meta
as `docComment`. This is the one place the gate differs from the equivalent guard
over the D4rt bridges in `tom_spec_engine`, which skips comments entirely.

What it does *not* ignore is private declarations: renaming a private helper in
the model moves the fingerprint even though the emitted packages are unaffected.
Take the regeneration; if it produces no diff in the nine packages, commit the
refreshed stamp alone.

### The gap this does not close

The check runs in **this** package's suite, so a model edit committed without
anyone running these tests is still not caught at the moment it happens — the
guard turns a silent breakage into a loud one, it does not move detection earlier
in wall-clock time.

It also does not fingerprint the **emitters**. Changing `SomDartEmitter` and
friends makes the committed packages stale in a way the model fingerprint cannot
see. That case is self-announcing in practice: every emitter has a golden test in
`test/`, so an emitter change already arrives with a visible "output moved"
signal — but the regeneration still has to be run by hand.

## How to regenerate

From the `tom_specs_clitool` package root:

```bash
dart run bin/generate_som.dart
```

It runs the `@SerializationOrder` restamp against `tom_specs_model` as its
mandatory first step, emits every configured language, and — on success only —
rewrites `tool/model_surface.stamp.json` with the model surface it generated
from. **Commit the stamp together with the regenerated packages**; it is what the
freshness check compares against, and a regeneration committed without it leaves
the check failing.

The stamp is written **only for a canonical run**. Passing `--config`, `--model`
or `--model-version` produces a tree a default re-run would not reproduce, so
those runs print a note and leave the stamp alone rather than certifying the
committed packages from a one-off.

Regenerating the Dart target also moves `tom_som_dart_v0`'s public surface, which
the D4rt bridges in `tom_spec_engine` are generated from. `generate_som.dart`
prints that reminder; see
[`tom_spec_engine/_copilot_guidelines/bridge_regeneration.md`](../../tom_spec_engine/_copilot_guidelines/bridge_regeneration.md).

After regenerating, run the quality gates:

```bash
dart analyze
dart test          # or: testkit :test
```

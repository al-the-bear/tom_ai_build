# Working on the TomSpecs stack

Rules for changes that cross the TomSpecs packages — the model, the nine SOM
languages, the engine and the two apps. What to regenerate after a model change,
and why, is [som_regeneration.md](som_regeneration.md); this document holds the
rules around it.

## A model change runs the whole cascade

A change to `tom_specs_model` — a member, a doc comment, an annotation argument
or an annotation's `note` — is followed, in this order, by:

1. `dart run bin/tomspecs.dart :som-generate` (the `@SerializationOrder` restamp, the
   `spec_ops.g.dart` registry, the nine `tom_som_*_v0` packages and the stamp,
   [som_regeneration.md](som_regeneration.md));
2. the SOM D4rt bridges in `tom_spec_engine`, about 20 minutes
   ([bridge_regeneration.md](../../tom_spec_engine/_agent_guidelines/bridge_regeneration.md));
   a regeneration whose diff is only the `// Generated:` header lines keeps the
   stamp and drops the bridge diff;
3. the outlines: `tool/regenerate_outlines.sh`;
4. the two model-graph assets: `dart run bin/tomspecs.dart :model-json --target reviewer`
   and `--target editor` (the editor's asset is in the `tom_forge` repository);
5. the conformance driver, `tom_som_conformance/tool/run_all_suites.sh`, and the
   clitool's own `dart test`.

Batch model edits so the cascade runs once per session, not once per edit.

## A structural accessor goes into all nine runtimes

An accessor added to one runtime is added to the other eight in the same change,
with a conformance case all nine pass. Its **name follows the target language's
convention**, not Dart's: the `$` prefix only where the language allows it
(Dart, JavaScript, TypeScript, Java), `spec_*` in Python, PascalCase in Go,
plain snake or camel case in Rust, C and C++. Symmetry with the sibling
accessors inside one language beats symmetry across languages.

## Generated text is changed in its emitter

Text that appears in generated source is changed in the emitter literal
(`lib/src/som_<lang>_meta_emitter.dart`, `som_<lang>_emitter.dart`) and
regenerated, never in the output. Fixed-width comment banners are re-padded
after any text change inside them, measured in characters, not bytes. A hand
edit to a generated file is defensible only when the result is byte for byte
what the current generator writes, i.e. a cheap regeneration, never a
divergence the next real run would undo.

## A failing gate may not be yours

Before treating a failing `dart analyze` or test as caused by the change, check
with `git status` which files it names. A gate naming files the change did not
touch failed before it, and is fixed on its own terms rather than folded into
the change. Where the change did rewrite the generated file in question, compare
distinctive token counts between `git show HEAD:<file>` and the worktree copy
before calling a finding pre-existing.

## Commits stay scoped to their repository

Each repository commits separately: `tom_ai/ai_build` (the model, runtimes,
clitool, engine, reviewer, CodeSpecs packages), `tom_forge` (the editor) and
`_ai` (quest files, with `git commit --only`). A push that reports "Everything
up-to-date" while you hold unpushed commits usually means a concurrent session
pushed on top of them: confirm with `git branch -r --contains <sha>` before
pushing again.

## The dart_style pin moves with the SDK

Everything in the clitool that formats Dart uses `dart_style`, linked into the
package through one helper, `DartFormat` in `lib/src/dart_format.dart`:
- the formatting gate (`tomspecs :gate-format`);
- the spec-ops registry generator and `:codespecs-areas`' accessor;
- the registry tests generator;
- the dart-tom mapper.

None of them runs `dart format` as a process, so a compiled `tomspecs` or
`tomspecs` needs no Dart SDK to format. Each file is formatted in its package's
language version, found the way `dart format` finds it: the nearest
`.dart_tool/package_config.json`, else the nearest `pubspec.yaml`'s SDK lower
bound, else the latest.

`dart_style` is pinned in `pubspec.yaml` to exactly the version of the SDK's
own formatter (`dart format --version`), and `kDartStyleVersion` in
`lib/src/dart_format.dart` names the same version. So the gate and a developer
running `dart format` by hand agree; `test/dart_format_test.dart` holds the
helper's output to the SDK's for the same input at the same place.

After an SDK upgrade `test/dart_style_pin_test.dart` fails with the version to
move to:
1. change both the pin and the constant, and run `dart pub get`;
2. run the formatting gate, the dart-tom round trip
   (`test/irspecs_dart_tom_test.dart`) and the phase4 sample's
   `tool/validate.sh`.

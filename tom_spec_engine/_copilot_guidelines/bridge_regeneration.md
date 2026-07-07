# Regenerating the SOM D4rt bridges

The engine exposes the SOM (Specs Outline Model) API to D4rt scripts through
generated bridge files (`*.b.dart`). These are produced by the
`tom_d4rt_generator` from the `d4rtgen:` block in [`buildkit.yaml`](../buildkit.yaml).

The bridges are generated **here**, in the engine plane — *not* in the lean
pure-data `tom_som_dart_runtime` / `tom_som_dart_v0` packages. Those keep a
minimal footprint (the runtime stays `yaml`-only) while the scripting plane,
which already depends on `tom_d4rt`, owns the D4rt binding surface.

## Generated files (do not hand-edit)

| File | Source module |
|------|---------------|
| `lib/d4rt_bridges.b.dart` | barrel — registers all modules (`TomSomBridge`) |
| `lib/dartscript.b.dart` | dartscript registration entry point |
| `lib/src/bridges/som_runtime_bridges.b.dart` | `tom_som_dart_runtime` public surface |
| `lib/src/bridges/som_v0_bridges.b.dart` | `tom_som_dart_v0` public surface |
| `lib/src/bridges/relaxers.b.dart` | generated relaxer support |

All `*.b.dart` files are generated artifacts. Never edit them by hand; change
the source SOM packages (or `buildkit.yaml`) and regenerate.

## When to regenerate

Regenerate whenever the **public surface** of either SOM package changes:

- `tom_som_dart_runtime` — the meta-model / document / query / validator classes
  exported from `package:tom_som_dart_runtime/tom_som_dart_runtime.dart`.
- `tom_som_dart_v0` — the generated typed editing facade exported from
  `package:tom_som_dart_v0/tom_som_dart_v0.dart`.

Adding, removing, or changing the signature of any class, method, or field that
is reachable from those barrels means the bridges are stale until regenerated.

## How to regenerate

From the `tom_spec_engine` project root:

```bash
dart pub get            # once, to resolve the tom_d4rt_generator dev_dependency
dart run tool/regenerate_bridges.dart
```

The script ([`tool/regenerate_bridges.dart`](../tool/regenerate_bridges.dart))
calls `generateBridges(configPath: 'buildkit.yaml', projectPath: '.')` from
`package:tom_d4rt_generator/tom_d4rt_generator.dart` and prints a summary
(class/module counts, output files, errors, success). It exits non-zero on
failure so it is CI/script-safe.

The equivalent CLI form (from the generator package) is:

```bash
dart run bin/d4rtgen.dart --project=<path-to>/tom_spec_engine
```

After regenerating, run the quality gates:

```bash
dart analyze
dart test          # or: testkit :test
```

Regeneration is **content-deterministic**: running it on an unchanged source
surface produces identical bridge *content*. The only thing that varies between
runs is the `// Generated: <timestamp>` header line each `*.b.dart` file carries,
so a no-op regen shows up in `git diff` as a one-line header change per file.
Review the diff before committing — if the only change is the timestamp header,
the bridges were already up to date and the regen can be discarded
(`git checkout -- lib`).

## Why the generator is a path dependency (stale-cache avoidance)

`tom_d4rt_generator` is consumed as a **path** dev-dependency
(`path: ../../d4rt/tom_d4rt_generator` in [`pubspec.yaml`](../pubspec.yaml)), not
from pub.dev. This is deliberate.

The bridges are generated *against the current source* of the unpublished path
siblings `tom_som_dart_v0` / `tom_som_dart_runtime`. When a generator bug only
shows up against that live SOM source — e.g. the `$`-prefixed `$sectionId`
accessor `D00SolutionBlueprint` inherits from `SomNode`, whose name must be
escaped in the emitted bridge maps — the fix has to be iterated **and consumed**
locally. With a hosted dev-dep that meant `publish → bump → dart pub upgrade`
for every iteration, and `pub upgrade` rewrites `pubspec.lock` **without**
refreshing `.dart_tool/package_config.json`. Because `dart run` resolves imports
through `package_config.json`, the regenerator kept running the *previous*
generator and emitted stale bridges — the "stale cache" symptom.

A path dep removes the version indirection entirely: `dart run
tool/regenerate_bridges.dart` always executes the current generator source, so
the SOM bridges can never go stale against a not-yet-published generator. This
is safe and consistent with the engine's shape — it is a **build-only DEV**
dependency (it never reaches the engine's runtime API), and the engine is itself
`publish_to: none`, already depending on its SOM siblings by path. (The
workspace "no path deps" rule targets *runtime* missing-API errors on
*published* artifacts; neither applies to a build-tool dev-dep here.)

Note this is orthogonal to the analyzer **summary cache**
(`tom_analyzer_shared`), which already never caches path dependencies: it only
stores summaries for `hosted`/`sdk` sources (see `PackageDependency.isCacheable`),
so the SOM packages are always analyzed fresh from source. The staleness above
was purely the pub `package_config.json` lag, not a summary-cache entry.

## Why a manual script rather than build_runner

`tom_d4rt_generator` is a standalone generator driven by `buildkit.yaml`, not a
`build_runner` builder, so there is no `build.yaml` wiring. The regen is a
deliberate, infrequent step gated on SOM API changes; a one-line script keeps it
explicit and avoids pulling `build_runner` into an otherwise lean engine package.
See decision **F21** in
`_ai/quests/tom_specs/d4rt_and_llm_tools_decisions.md`.

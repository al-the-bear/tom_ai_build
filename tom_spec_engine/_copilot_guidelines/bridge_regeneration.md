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

## How staleness is caught

The rule above is enforced, not merely stated. `dart test` fails when the SOM
public surface has moved since the bridges were last generated:

| Piece | Role |
|-------|------|
| [`tool/som_surface.dart`](../tool/som_surface.dart) | Fingerprints the two SOM packages' public surface |
| `tool/som_surface.stamp.json` | The fingerprint the committed bridges were generated from — written by the regenerator, committed alongside the bridges |
| [`test/som_bridge_freshness_test.dart`](../test/som_bridge_freshness_test.dart) | Recomputes the fingerprint and fails when it no longer matches the stamp |

The failure names which package moved and by how many declarations, and tells
you to regenerate. The check is part of the **default** suite — it costs about a
second, so it needs no tag and cannot be skipped by habit.

### Why a fingerprint rather than a re-generate-and-diff

Regeneration is content-deterministic (see below), so a freshness check could
regenerate into a temp directory and diff. That was rejected: it costs a full
regen on every test run, which forces the check behind a tag, and a tagged check
is exactly the one nobody runs. Fingerprinting the *input* instead gets the same
answer for the same reason — if the input has not moved, the output cannot have.

### Why this is needed at all

The bridges are generated **here** but their sources are edited **elsewhere**,
and nothing in the SOM packages' own workflow prompts a regen. Two things then
go wrong, and only one of them is self-announcing:

- **Breaking staleness** — SOM removes or renames a member the bridge still
  references. The bridge stops compiling, so `dart analyze` catches it. Loud,
  but only for whoever next runs the engine's gates, which may be days later.
- **Silent staleness** — SOM *adds* a class or member. The bridge simply does
  not expose it. Nothing goes red, ever; the D4rt scripting surface is just
  quietly incomplete.

The fingerprint catches both, and it catches the first one *earlier* — as a
message saying what to do, rather than as a wall of undefined-getter errors.

### What the fingerprint deliberately ignores

Taken over each library's token stream, so these are free and will not raise a
false alarm: **comments** (including doc-comment rewording), **formatting**,
and **function bodies** — the generator binds signatures, not implementations.

What it does *not* ignore is private declarations: renaming a private helper in
a SOM package moves the fingerprint even though the bridges are unaffected. Take
the regen; if the only resulting bridge diff is the `// Generated:` header lines,
discard it with `git checkout -- lib` and commit the refreshed stamp alone.

### The gap this does not close

The check runs in **this** package's suite. An edit made in a SOM package and
committed without anyone running the engine's tests is still not caught at the
moment it happens — the guard turns a silent breakage into a loud one, it does
not move detection earlier in wall-clock time. `tom_som_dart_runtime` and
`tom_som_dart_v0` therefore carry a pointer back to this document, so a surface
edit there prompts the regen at the point of editing.

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

On success — and only on success, since stamping a failed run would certify
bridges that were never produced — it also rewrites
`tool/som_surface.stamp.json` with the SOM surface it generated from. **Commit
the stamp together with the bridges**; it is what the freshness check compares
against, and a regen committed without it leaves the check failing.

The equivalent CLI form (from the generator package) is:

```bash
dart run bin/d4rtgen.dart --scan=<path-to>/tom_spec_engine --not-recursive
```

Note the `--scan`. `--project` takes project **names/ids**, not paths, and a
selector that matches nothing is not an error — the generator exits 0 having
generated nothing. Passing a path to `--project` therefore looks like a
successful regeneration while leaving the bridges untouched.

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

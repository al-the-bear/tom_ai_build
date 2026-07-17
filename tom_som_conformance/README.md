# tom_som_conformance

Cross-language conformance assets for the SOM (Spec Object Model) runtimes and
generated `tom_som_<lang>_v0` facades. Everything here is **language-agnostic**:
one shared sample, one shared corpus, and one golden harness that proves all
nine language APIs agree.

## Layout

| Path | Purpose |
| ---- | ------- |
| `samples/` | The shared specification sample (`meridian_order_management.docspecs.yaml` + `.md`), authored once through the Dart typed facade and loaded by every language. See `samples/README.md`. |
| `corpus/` | Language-agnostic case tables (section-id, operations, validation, reflection, serialization-order) plus their expected outputs, consumed by each runtime's conformance runner. |
| `golden/` | Per-language golden logs (`<lang>.log`) written by the nine golden generators. **Git-ignored** — regenerated on demand (see below). |
| `tool/` | The golden harness: `regenerate_golden.sh` (driver) and `compare_golden.dart` (byte-identical assertion). |

## Cross-language golden harness (roadmap item 7b)

Each `tom_som_<lang>_v0` project ships a golden generator that loads the shared
sample and emits a canonical, deterministic reading of *essentially every
section* through the generic string-path API, the typed facade, **and** the
generated metadata tree — then validates the sample's markdown against the
facade's generated DocSpecs schema:

| Language | Generator |
| -------- | --------- |
| Dart (reference) | `tom_som_dart_v0/tool/golden_log.dart` |
| Python | `tom_som_python_v0/tool/golden_log.py` |
| JavaScript | `tom_som_javascript_v0/tool/golden_log.js` |
| TypeScript | `tom_som_typescript_v0/tool/golden_log.ts` |
| Go | `tom_som_go_v0/tool/golden_log.go` |
| Java | `tom_som_java_v0/tool/GoldenLog.java` |
| Rust | `tom_som_rust_v0/examples/golden_log.rs` |
| C | `tom_som_c_v0/tool/golden_log.c` |
| C++ | `tom_som_cpp_v0/tool/golden_log.cpp` |

The log format is defined once in the Dart generator (the reference) and
mirrored verbatim by the other eight. It is intentionally line-oriented,
LF-terminated, ASCII-path, and value-escaped so it compares byte-for-byte
across languages regardless of their native string/collection types. The format
is versioned by a `FORMAT <n>` marker and has grown additively — `FORMAT 3`
added stored headlines (YRD3), `FORMAT 5` typed role fields (YRD6), `FORMAT 6`
typed non-String form fields + the meta-form `enumValues` column (YRD7). The
Dart reference is currently at **FORMAT 6**; the eight non-Dart generators are
one revision behind at **FORMAT 5**, so the harness is expected to fail today —
see [Known format lag](#known-format-lag-dart-format-6-vs-non-dart-format-5-tracked-yre4)
below. Each log carries these sections, all model-derived so the lines are
byte-identical across languages even though the accessor *names* differ:

| Section | Content |
| ------- | ------- |
| `generic-content` / `generic-forms` / `generic-lists` | Every content leaf, form field, and list container read through the generic string-path API (`SpecDocument`). |
| `typed` | A curated facade traversal (`.path` / `.content`), each read asserted equal to the generic read. |
| `meta` | The generated metadata tree resolved by path (`metaTree.byPath`), emitting each node's `kind` / `sectionId` / `contentHelp` / `comment` / `docComment`. |
| `meta-nav` | Dot-notation navigation accessors (`d00SolutionBlueprint.introductionAndScope.goals`), asserted to resolve to the same node instance `byPath` finds. |
| `meta-id` | Hoisted-id accessors (`SBP`, `SBP.RVHST_REVS_LST.item(0)`), asserted to agree with the dot-notation position. |
| `docspecs` | The sample's markdown validated against the facade's generated DocSpecs schema — root id, warning count, violation count. |

Each generator is itself a test: it asserts the typed reads equal the generic
reads, the metadata-tree nav/id accessors resolve to the same nodes `byPath`
finds, and the schema validates — so a facade/runtime divergence aborts with a
non-zero exit instead of emitting a silently-wrong log.

### Running

```bash
# Regenerate all nine logs and assert byte-identity (needs the nine toolchains):
./tool/regenerate_golden.sh

# Or, if the logs already exist, just re-run the comparison:
dart run tool/compare_golden.dart
```

`compare_golden.dart` compares raw bytes (not decoded text), so a stray CR, BOM,
or trailing-newline difference is caught. On a mismatch it reports the first
differing line against the Dart reference and exits non-zero. A green run proves
all nine language APIs yield exactly the same reading of the same specification.

#### Known format lag: Dart FORMAT 6 vs non-Dart FORMAT 5 (tracked: YRE4)

The harness is **expected to fail today**, and the failure is understood — it is
not silent drift. The Dart reference generator emits **FORMAT 6** (YRD7: typed
non-String form fields plus the meta-form `enumValues` column), while the eight
non-Dart generators still emit **FORMAT 5** (YRD6). So `compare_golden.dart`
reports 8 of 9 languages mismatching against the Dart reference.

| Aspect | Detail |
| ------ | ------ |
| **Symptom** | `compare_golden.dart` fails for all eight non-Dart logs. Each diverges from the Dart reference on the `FORMAT` header line (line 3), where the Dart log reads `FORMAT 6` and every non-Dart log reads `FORMAT 5`; the total byte count differs accordingly (~152 KB Dart vs ~149 KB non-Dart). |
| **Root cause** | The FORMAT 6 delta is the meta-form `enumValues` column, which is sourced from `SomFormFieldMeta.enumValues`. That field currently exists **only in `tom_som_dart_runtime`** — the other eight `tom_som_<lang>_runtime` packages do not yet carry the enum-values meta capability. Re-running `regenerate_golden.sh` therefore re-emits FORMAT 5 for the eight non-Dart languages: **regeneration alone does not close the gap** — the eight runtimes must first gain the FORMAT 6 capability. |
| **Tracked fix** | Adding the `enumValues` meta capability to the eight non-Dart runtimes and lifting their generators to FORMAT 6 is tracked as **YRE4**. When that lands, the eight generators emit FORMAT 6 and the harness returns to byte-identity green. |

Until YRE4 lands, treat an 8/9 failure with a line-3 `FORMAT 5` vs `FORMAT 6`
mismatch as the *known* state — not a regression. A regression is any *other*
differing line, or a Dart-vs-Dart mismatch.

#### TypeScript step — build the runtime `dist/` first (CS4-D6)

The TypeScript golden generator (and the `tom_som_typescript_v0` facade in
general) imports `SpecDocument` from `tom_som_typescript_runtime` by bare
package name, which resolves to the runtime's git-ignored
`dist/src/index.d.ts`. On a clean checkout that file does not exist yet, so the
runtime must be built before the facade. `regenerate_golden.sh` already does
this explicitly for the TypeScript step, and the facade's `npm run build` has a
`prebuild` script that builds the runtime first — so both paths work without a
manual pre-step. See `tom_som_typescript_v0/README.md`.

## Packaging (PGK series)

Every SOM target ships as a pair of installable packages — the hand-authored
generic `tom_som_<lang>_runtime` and the generator-emitted typed
`tom_som_<lang>_v0` facade — each versioned to the **TomSpecs model version**
(currently `1.0.0`; the model's `1.0` label maps to a semver patch). Both halves
of every pair carry a README short how-to block and a separate
`readme_howtointegrate.md`, plus a `LICENSE` and `CHANGELOG.md`. The facade's
packaging files are regenerated in place by `generate_som.dart` (via the generic
packaging hook, `tom_specs_clitool/lib/src/packaging.dart`), so they never drift
from the model version.

Each language uses its ecosystem's idiomatic build/pack command; the packaging
descriptor for every language records the canonical command in its
`buildFromSource` block:

| Language | Documented build/pack command | Artifact |
| -------- | ----------------------------- | -------- |
| Dart | `dart pub get && dart pub publish --dry-run` | validated package |
| Python | `python3 -m build` | sdist + wheel |
| Java | `mvn install` (runtime) → `mvn package` (facade) | JAR |
| JavaScript | `npm pack --dry-run` | npm tgz |
| TypeScript | `npm install && npm pack --dry-run` | npm tgz (compiled `dist/`) |
| Go | `go build ./... && go vet ./...` | module (no separate pack) |
| Rust | `cargo package --no-verify` (runtime) → `cargo build` (facade) | `.crate` |
| C | `make && make dist` | static + shared lib, pkg-config `.pc`, source tarball |
| C++ | `make && make dist` | static + shared lib, pkg-config `.pc`, source tarball |

### Sign-off sweep (roadmap item PGK11)

The cross-cutting packaging sign-off re-runs `generate_som.dart` (confirming
every facade regenerates to the current model version with zero committed
churn), builds/packs all nine languages with the commands above, and re-asserts
the done-criteria: `dart analyze` clean, the `tom_specs_clitool` suite green, the
nine language APIs green, and cross-language golden byte-identity unaffected (the
`regenerate_golden.sh` run above). A green sweep proves the 18 packages are
internally consistent, versioned to the model, and independently buildable.

## Discoverable path access — metadata tree, nav, and ID-tree (DR8)

The former per-root `<Root>Paths` flat constant holders are **retired** (DR1 §4,
DR8). In their place every generated `tom_som_<lang>_v0` facade emits a
**metadata library** carrying, per document root, three discoverable surfaces
over the same section paths — so generic consumers (and the golden generators
above) reference a compiler-checked symbol instead of a raw path literal:

| Surface | Entry point | What it gives |
| ------- | ----------- | ------------- |
| Metadata tree | `<camelRoot>MetaTree` (a `SomMetaTree`) | Resolve any node by path — `metaTree.byPath('SBP/currentLandscape/CUOPME-OPER-LST')` — then read `kind` / `sectionId` / `contentHelp` / `comment` / `docComment`. |
| Dot-notation nav (DR1 §4.1) | `d00SolutionBlueprint` (a `<Root>$Nav`) | Member-named accessors — `d00SolutionBlueprint.currentLandscape.operationalMetrics` — resolving to a `SomMetaRef`. |
| ID-tree (DR1 §4.2) | `SBP` (a `<Root>$Id`) | Section-id-named accessors that hoist through id-less members — `SBP.RVHST_REVS_LST.item(0)` — resolving to the *same* `SomMetaRef` instance the nav position finds. |

Each nav / id accessor is a `SomMetaRef` exposing `.path` (the absolute generic
path string) and `.meta` (its metadata node), so navigating to a symbol and
reading `.path` yields the exact path literal the old holder constant used to
carry — now discoverable by navigation. **The tree, nav, and ID-tree data are
identical across all nine languages**; only the accessor *names* differ per
language convention (dot-notation members, id members with `-` → `_`).

Fixed navigable positions are reachable through nav; dynamic list *items*
(`…-<seq>`) are reached with `.item(n)` off a list node, and form-field sub-keys
are read off the form node — neither is a navigable member. See the Dart hybrid
sample (`tom_som_dart_v0/example/f_sample_hybrid_access.dart`) for reaching a
path without a literal by navigate-then-read off a node's `.path`.

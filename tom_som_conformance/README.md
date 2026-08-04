# tom_som_conformance

Cross-language conformance assets for the SOM (Spec Object Model) runtimes and
generated `tom_som_<lang>_v0` facades. Everything here is **language-agnostic**:
one shared sample, one shared corpus, and one golden harness that proves all
nine language APIs agree.

## Layout

| Path | Purpose |
| ---- | ------- |
| `samples/` | The shared specification sample (`meridian_order_management.docspecs.yaml` + `.md`), authored once through the Dart typed facade and loaded by every language. See `samples/README.md`. |
| `corpus/` | Language-agnostic case tables (section-id, operations, validation, reflection, serialization-order, generation stamp) plus their expected outputs, consumed by each runtime's conformance runner. |
| `golden/` | Per-language golden logs (`<lang>.log`) written by the nine golden generators. **Git-ignored** — regenerated on demand (see below). |
| `tool/` | The two cross-language drivers: `regenerate_golden.sh` + `compare_golden.dart` (the golden harness) and `run_all_suites.sh` (the eighteen test suites). |

## Cross-language golden harness (SOM §19)

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
typed non-String form fields, `FORMAT 7` the meta-form `enumValues` column
(YRD7), `FORMAT 8` the stored `codeSpec` member, and `FORMAT 9` the meta-form
`refersTo` column (csrb3). **All nine generators are at FORMAT 9** and the
harness is byte-identity green. Each log carries these sections, all
model-derived so the lines are byte-identical across languages even though the
accessor *names* differ:

| Section | Content |
| ------- | ------- |
| `generic-content` / `generic-forms` / `generic-lists` | Every content leaf, form field, and list container read through the generic string-path API (`SpecDocument`). |
| `typed` | A curated facade traversal (`.path` / `.content`), each read asserted equal to the generic read. |
| `typed-form` | Typed non-String form members (int / bool / enum, FORMAT 6) read through the facade and asserted against the generic form store after boundary canonicalisation (int → decimal, bool → `true`/`false`, enum → constant name). |
| `meta` | The generated metadata tree resolved by path (`metaTree.byPath`), emitting each node's `kind` / `sectionId` / `contentHelp` / `comment` / `docComment`. |
| `meta-nav` | Dot-notation navigation accessors (`d00SolutionBlueprint.introductionAndScope.goals`), asserted to resolve to the same node instance `byPath` finds. |
| `meta-id` | Hoisted-id accessors (`SBP`, `SBP.RVENT_REVS_LST.item(0)`), asserted to agree with the dot-notation position. |
| `docspecs` | The sample's markdown validated against the facade's generated DocSpecs schema — root id, warning count, violation count. |

Each generator is itself a test: it asserts the typed reads equal the generic
reads, the metadata-tree nav/id accessors resolve to the same nodes `byPath`
finds, and the schema validates — so a facade/runtime divergence aborts with a
non-zero exit instead of emitting a silently-wrong log.

**Live-document durability guard (YRD8).** The shared Meridian sample *is* the
live-document conformance case: the Dart reference golden reads it end to end —
`generic-*` (round-trip bytes), `docspecs` (validation), and `meta-*` (node
operations). Because `golden/` is git-ignored (regenerated on demand), a
committed Dart test group — `shared sample: live-document case durability
(YRD8 / dsa7)` in `tom_som_dart_v0/test/generated_v0_test.dart` — pins those
three guarantees (decode→encode→decode stability, clean schema validation,
byPath/nav/id node identity) so a regression fails `dart test` without needing a
full nine-toolchain golden run. **Every runtime now carries the same guard**
(dsa8–dsa15): a `testLiveDocumentCase` (or language idiom, e.g. Go
`TestLiveDocumentCase`, Rust `live_document_case`, C/C++/Python
`test_live_document_case`) in each `tom_som_<lang>_v0` test suite pins the same
three guarantees, so a per-language regression fails that language's own test
suite — not only the aggregate golden comparison.

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

#### The nine generators move together

The nine generators are always at the **same** `FORMAT` revision — there is no
tolerated lag. Raising the format is therefore one indivisible change: add the
capability to all nine `tom_som_<lang>_runtime` packages, teach the nine
meta-emitters to emit it, lift the nine golden generators, and re-run
`regenerate_golden.sh` until the comparison is green again. Because all nine
logs are byte-identical, any mismatch is a genuine regression rather than a
known lag.

The Dart generator is the reference: write the new column there first, verify
its output, then mirror it verbatim into the other eight. A column that is empty
for every field proves nothing, so a format bump also adds (or re-targets) a
sample call that exercises the new column with real values — `FORMAT 9`
introduced its third `metaForm` call on `SCTREN-TRAN-LST` for exactly that
reason: four reference fields, one of them naming two registries.

#### The nine validators move together too — and the corpus is what enforces it

Same rule, different mechanism. Every instance-tier validation check is
nine-language (`som_multiplatform_spec_model.md` §9), and what *forces* a
runtime to implement one is a case in `corpus/validation_cases.json`: a case
expecting a code a runtime does not emit fails that runtime's own conformance
runner.

The converse is the trap, and it is not obvious. A code with **no** case is not
weakly covered — it is **invisible**, and nine runners then agree byte-for-byte
about a question none of them was ever asked. That is not hypothetical: two
codes stayed Dart-only for two rounds while this harness reported nine-way
parity, because the corpus carried no `refersTo` declaration and no `@OneOf`
group to exercise them with.

So the corpus must exercise **every** `SpecValidationCode`. The Dart conformance
test derives the covered set from the committed `validation_cases.json` and
diffs it against `SpecValidationCode.values`, which makes adding an enum
constant the very act that demands its corpus case. Adding a check is therefore
one indivisible change, exactly like a format bump: implement it in all nine
runtimes in the same phase with the same message text, and add the case that
proves it.

#### TypeScript step — build the runtime `dist/` first (CS4-D6)

The TypeScript golden generator (and the `tom_som_typescript_v0` facade in
general) imports `SpecDocument` from `tom_som_typescript_runtime` by bare
package name, which resolves to the runtime's git-ignored
`dist/src/index.d.ts`. On a clean checkout that file does not exist yet, so the
runtime must be built before the facade. `regenerate_golden.sh` already does
this explicitly for the TypeScript step, and the facade's `npm run build` has a
`prebuild` script that builds the runtime first — so both paths work without a
manual pre-step. See `tom_som_typescript_v0/README.md`.

## Packaging (SOM §17)

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

### Packaging sign-off sweep (SOM §17)

The cross-cutting packaging sign-off re-runs `generate_som.dart` (confirming
every facade regenerates to the current model version with zero committed
churn), builds/packs all nine languages with the commands above, and re-asserts
the done-criteria: `dart analyze` clean, the `tom_specs_clitool` suite green, the
nine language APIs green, and cross-language golden byte-identity unaffected (the
`regenerate_golden.sh` run above). A green sweep proves the 18 packages are
internally consistent, versioned to the model, and independently buildable.

## The eighteen test suites — `run_all_suites.sh`

The golden harness proves the nine APIs *read* the sample identically. It says
nothing about the eighteen hand-authored test suites that sit in the nine
runtime and nine `v0` packages — and for a long time nothing ran them together,
so a suite could stay red without anyone noticing.

`tool/run_all_suites.sh` closes that: every SOM package now carries a uniform
`run_tests.sh` that runs everything hand-authored in it, whatever the ecosystem
underneath, and this driver is the aggregate over all eighteen.

```bash
./tool/run_all_suites.sh                    # everything, skipping absent toolchains
./tool/run_all_suites.sh --strict           # a skipped suite is a failure
./tool/run_all_suites.sh rust_v0 c_runtime  # just these
./tool/run_all_suites.sh --log-dir <dir>    # place the per-suite logs
```

Per-suite output goes to one log file each (default: a timestamped folder under
the workspace `ztmp/`), with a PASS / FAIL / SKIP summary table at the end and a
non-zero exit on any failure. A suite whose toolchain is absent is **skipped
with the reason stated**, never reported as a pass — and `--strict` turns that
skip into a failure for hosts that claim full coverage.

The driver adds `~/.cargo/bin` to `PATH` when `cargo` is not already resolvable:
rustup wires cargo up in the *interactive* shell profile only, so a
non-interactive run would otherwise skip the two Rust suites on a host that can
perfectly well run them. A skip that reflects a `PATH` quirk is nearly as bad as
no gate at all. `regenerate_golden.sh` carries the same prepend.

### The suites read their root set from the generated registry

Each `tom_som_<lang>_v0` package's meta-agreement suite checks the generated
metadata module against the tree the runtime bridge derives from
`meta/spec_model.meta.json`. Those suites used to **hand-list** the document
roots, so adding a fourteenth root left nine suites listing thirteen.

They now read the root set from the generated module's own
`SOM_META_ROOTS` registry (SOM §8) instead, which is emitted from the same root
list that produced the trees — so a new document root reaches every suite by
regeneration rather than by recollection.

That does not make the coverage check circular. `meta/spec_model.meta.json` is
written by the **model JSON exporter**, a different code path from the meta
emitters, so a suite still fails loudly when an emitter drops a root — verified
by seeding exactly that and watching the Dart and Rust suites go red with a
root-count mismatch.

## Discoverable path access — metadata tree, nav, and ID-tree (SOM §8)

The former per-root `<Root>Paths` flat constant holders are **retired** (SOM §8,
SOM §8). In their place every generated `tom_som_<lang>_v0` facade emits a
**metadata library** carrying, per document root, three discoverable surfaces
over the same section paths — so generic consumers (and the golden generators
above) reference a compiler-checked symbol instead of a raw path literal:

| Surface | Entry point | What it gives |
| ------- | ----------- | ------------- |
| Metadata tree | `<camelRoot>MetaTree` (a `SomMetaTree`) | Resolve any node by path — `metaTree.byPath('SBP/currentLandscape/CUOPME-OPER-LST')` — then read `kind` / `sectionId` / `contentHelp` / `comment` / `docComment`. |
| Dot-notation nav (SOM §8) | `d00SolutionBlueprint` (a `<Root>$Nav`) | Member-named accessors — `d00SolutionBlueprint.currentLandscape.operationalMetrics` — resolving to a `SomMetaRef`. |
| ID-tree (SOM §8) | `SBP` (a `<Root>$Id`) | Section-id-named accessors that hoist through id-less members — `SBP.RVENT_REVS_LST.item(0)` — resolving to the *same* `SomMetaRef` instance the nav position finds. |

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

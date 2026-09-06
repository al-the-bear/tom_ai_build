# tom_som_conformance — the nine-language SOM parity harness

> **Cross-references.**
> [`tom_specs_model/doc/som_multiplatform_spec_model.md`](../tom_specs_model/doc/som_multiplatform_spec_model.md)
> is the authority for the Spec Object Model these assets hold to account — the
> validation, editing and scripting tiers the corpus enforces (SOM §9, SOM §14,
> SOM §15), the discoverable metadata surfaces (SOM §8), the golden-harness
> contract (SOM §19) and packaging (SOM §17).
> [`tom_specs_model/doc/som_toolchains.md`](../tom_specs_model/doc/som_toolchains.md)
> owns the per-language toolchains a full run needs, and
> [`tom_specs_model/doc/codespecs_mapping.md`](../tom_specs_model/doc/codespecs_mapping.md) §1.1.1
> the Phase-4 extract contract the newest corpus tier pins. This README is the
> catalogue of *what these assets are and how to run them*; those documents own
> *what the nine implementations must do* and *why*.

Cross-language conformance assets for the nine SOM runtimes and the generated
`tom_som_<lang>_v0` facades — one shared sample set, one shared corpus, and one
golden harness.

## Where this fits

The TomSpecs Spec Object Model is a single Dart-authored model of what a
specification document may contain, generated out into **nine languages** —
Dart, Python, Java, JavaScript, TypeScript, Go, Rust, C and C++ — as a pair of
packages each: a hand-authored generic `tom_som_<lang>_runtime` and a
generator-emitted typed `tom_som_<lang>_v0` facade. Eighteen packages written by
nine different sets of hands, all claiming to implement the same contract, is a
claim nobody can hold in their head. This repository is where that claim is
*tested* rather than asserted. Everything in it is deliberately
**language-agnostic** — no Dart types, no Python idioms, just documents, JSON
case tables and shell drivers — because an asset that favoured one language
would quietly grade that language's port more gently than the other eight. It is
not a package: nothing depends on it, nothing imports it, and it ships nowhere.
It is the evidence that the eighteen packages that *do* ship agree.

## Overview

The harness answers one question — *do the nine language APIs behave
identically?* — with two independent mechanisms, because neither alone is
sufficient.

The **golden harness** proves agreement by *byte comparison*. Each
`tom_som_<lang>_v0` package ships a golden generator that loads the same shared
Meridian sample and writes a canonical, line-oriented reading of it through
every access path the facade offers. The nine logs are then compared as raw
bytes. This is a very strong proof over a bounded slice: within what the Meridian
sample carries, a single differing character anywhere in nine independent
implementations fails the run.

The **corpus** proves agreement by *demand*. A committed case table stating an
expected result is what forces a runtime to implement the behaviour at all — a
case expecting a code a runtime does not emit fails that runtime's own
conformance runner. The trap this exists to close is the one the golden harness
cannot see: a construct that no table asks about is not weakly covered, it is
**invisible**, and nine runners then agree byte-for-byte about a question none of
them was ever asked. That failure is not hypothetical — it has cost several
rounds, and each recovery added a tier. So the corpus itself is guarded: an
enum-coverage test diffs every contract enumeration against its table, which
makes adding a constant the act that demands its case.

Around those two sit the sample gates (every reachable model structure must be
instantiated by some sample, and every sample must still decode), the aggregate
suite driver (all eighteen hand-authored test suites, run together, so none can
sit red unnoticed), and `parity_gate.sh`, which settles the one question the
other gates cannot: whether a table is actually *read* by all nine runners.

## Features

### Gates

| Gate | Entry point | Goes red when |
| ---- | ----------- | ------------- |
| Instantiation coverage | [`tool/check_sample_coverage.dart`](tool/check_sample_coverage.dart) | a model structure exists that no sample instantiates |
| Sample decode | [`tom_som_dart_v0/tool/verify_samples.dart`](../tom_som_dart_v0/tool/verify_samples.dart) | a committed sample no longer decodes through the typed loader |
| Golden byte-identity | [`tool/regenerate_golden.sh`](tool/regenerate_golden.sh) → [`tool/compare_golden.dart`](tool/compare_golden.dart) | any of the nine logs differs from the Dart reference by one byte |
| Corpus load-bearing | [`tool/parity_gate.sh`](tool/parity_gate.sh) | a deliberately broken expectation leaves any suite green |
| Enum coverage | [`tom_som_dart_runtime/test/enum_coverage_test.dart`](../tom_som_dart_runtime/test/enum_coverage_test.dart) | a contract enum carries a constant no corpus table exercises |
| Aggregate suites | [`tool/run_all_suites.sh`](tool/run_all_suites.sh) | any of the twenty reported results is a failure |
| Packaging sweep | the nine `buildFromSource` commands (SOM §17) | a facade regenerates with churn, or a language fails to build or pack |

Every gate is *ratcheted* rather than advisory: each has a committed expectation
file or a byte-exact reference, so closing a gap is what makes the gap
un-reopenable.

## Quick start

```bash
# Everything hand-authored, plus the two sample gates. Absent toolchains skip
# with the reason stated; --strict turns a skip into a failure.
./tool/run_all_suites.sh
# → a PASS / FAIL / SKIP table over twenty results, non-zero exit on any failure

# The nine-way byte-identity proof (needs all nine toolchains installed).
./tool/regenerate_golden.sh
# → golden/<lang>.log for all nine, then compare_golden.dart asserts byte equality

# If the logs already exist, just re-run the comparison.
dart run tool/compare_golden.dart
# → one "OK <lang>.log (<n> bytes) == dart.log" line per compared language —
#   eight of them, because dart.log is the reference and is not compared to
#   itself — then "PASSED: all 8 language logs are byte-identical to dart.log."
#   and exit 0; on a mismatch, the first differing line and exit 1
```

## Usage

### Cross-language golden harness (SOM §19)

Each `tom_som_<lang>_v0` project ships a golden generator that loads the shared
Meridian sample and emits a canonical, deterministic reading of *essentially
every section* through the generic string-path API, the typed facade, **and** the
generated metadata tree — then validates the sample's markdown against the
facade's generated DocSpecs schema:

| Language | Generator |
| -------- | --------- |
| Dart (reference) | [`tom_som_dart_v0/tool/golden_log.dart`](../tom_som_dart_v0/tool/golden_log.dart) |
| Python | [`tom_som_python_v0/tool/golden_log.py`](../tom_som_python_v0/tool/golden_log.py) |
| JavaScript | [`tom_som_javascript_v0/tool/golden_log.js`](../tom_som_javascript_v0/tool/golden_log.js) |
| TypeScript | [`tom_som_typescript_v0/tool/golden_log.ts`](../tom_som_typescript_v0/tool/golden_log.ts) |
| Go | [`tom_som_go_v0/tool/golden_log.go`](../tom_som_go_v0/tool/golden_log.go) |
| Java | [`tom_som_java_v0/tool/GoldenLog.java`](../tom_som_java_v0/tool/GoldenLog.java) |
| Rust | [`tom_som_rust_v0/examples/golden_log.rs`](../tom_som_rust_v0/examples/golden_log.rs) |
| C | [`tom_som_c_v0/tool/golden_log.c`](../tom_som_c_v0/tool/golden_log.c) |
| C++ | [`tom_som_cpp_v0/tool/golden_log.cpp`](../tom_som_cpp_v0/tool/golden_log.cpp) |

The log format is defined once in the Dart generator (the reference) and
mirrored verbatim by the other eight. It is intentionally line-oriented,
LF-terminated, ASCII-path, and value-escaped so it compares byte-for-byte
across languages regardless of their native string/collection types. The format
is versioned by a `FORMAT <n>` marker and has grown additively — `FORMAT 3`
added stored headlines (YRD3), `FORMAT 5` typed role fields (YRD6), `FORMAT 6`
typed non-String form fields, `FORMAT 7` the meta-form `enumValues` column
(YRD7), `FORMAT 8` the stored `codeSpec` member, `FORMAT 9` the meta-form
`refersTo` column (csrb3), and `FORMAT 10` the `docspecs-invalid` section.
**All nine generators are at FORMAT 10** and the
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
| `docspecs-invalid` | [`samples/invalid_demo_document.md`](samples/invalid_demo_document.md) validated against [`corpus/docspecs_schema.yaml`](corpus/docspecs_schema.yaml) (FORMAT 10) — the same three counters plus the rule-vocabulary size and the number of distinct rules reached, then **one `DV` line per violation**. This is the only section that puts the per-violation emission under byte comparison; see "The invalid companion fixture" in [`samples/README.md`](samples/README.md). |

Each generator is itself a test: it asserts the typed reads equal the generic
reads, the metadata-tree nav/id accessors resolve to the same nodes `byPath`
finds, and the schema validates — so a facade/runtime divergence aborts with a
non-zero exit instead of emitting a silently-wrong log.

**Live-document durability guard (YRD8).** The shared Meridian sample *is* the
live-document conformance case: the Dart reference golden reads it end to end —
`generic-*` (round-trip bytes), `docspecs` (validation), and `meta-*` (node
operations). Because `golden/` is git-ignored (regenerated on demand), a
committed Dart test group — `shared sample: live-document case durability
(YRD8 / dsa7)` in
[`tom_som_dart_v0/test/generated_v0_test.dart`](../tom_som_dart_v0/test/generated_v0_test.dart) —
pins those three guarantees (decode→encode→decode stability, clean schema
validation, byPath/nav/id node identity) so a regression fails `dart test`
without needing a full nine-toolchain golden run. **Every runtime carries the
same guard** (dsa8–dsa15): a `testLiveDocumentCase` (or language idiom, e.g. Go
`TestLiveDocumentCase`, Rust `live_document_case`, C/C++/Python
`test_live_document_case`) in each `tom_som_<lang>_v0` test suite pins the same
guarantees, so a per-language regression fails that language's own test
suite — not only the aggregate golden comparison.

Each guard carries a **fourth** assertion, and it is the one guarantee in the
group that has no golden section behind it: the sample also validates cleanly on
the **instance tier** (`validateDocument`, SOM §9). A golden section could not
carry it — over a valid sample it would only ever report zero, which is the same
reason the `docspecs` golden needed the separate `invalid_demo_document.md`
companion. The two validation tiers are disjoint questions — the `docspecs`
golden section asks whether every *required section* is present,
`validateDocument` asks whether the *values* are well-formed (field kinds, form
keys, list minima, `refersTo` resolution) — and neither implies the other, which
is why the sample was schema-clean for a long time while carrying twelve
instance-tier violations. The sample's builder
([`tom_som_dart_v0/tool/build_shared_sample.dart`](../tom_som_dart_v0/tool/build_shared_sample.dart))
gates on both tiers, and the committed tests repeat the second gate because the
sample is *committed*: a hand-edit or a merge can reach it without anyone
re-running the builder.

#### Running

```bash
# Regenerate all nine logs and assert byte-identity (needs the nine toolchains):
./tool/regenerate_golden.sh

# Or, if the logs already exist, just re-run the comparison:
dart run tool/compare_golden.dart
```

[`tool/compare_golden.dart`](tool/compare_golden.dart) compares raw bytes (not
decoded text), so a stray CR, BOM, or trailing-newline difference is caught. On a
mismatch it reports the first differing line against the Dart reference and exits
non-zero. A green run proves all nine language APIs yield exactly the same
reading of the same specification — within the bound stated next.

##### The parity claim's bound

The nine-way byte-identity proof extends exactly as far as what the golden
generators load — **the Meridian sample** — plus the shared corpus, and no
further. Within that slice the proof is exact: every value the Meridian sample
carries is read identically nine ways, byte for byte. Outside it, a construct
is proven to a **weaker, tiered** degree, because the sample set is wider than
the harness's diet:

* **Instantiated somewhere in the sample set, Dart-decoded.** The samples
  under [`samples/`](samples/) together instantiate the *full* SBP-reachable
  model — the `sample_coverage` gate
  ([`tool/check_sample_coverage.dart`](tool/check_sample_coverage.dart), run
  first by [`tool/run_all_suites.sh`](tool/run_all_suites.sh)) walks the model
  meta
  ([`tom_som_dart_v0/meta/spec_model.meta.json`](../tom_som_dart_v0/meta/spec_model.meta.json))
  from the `D00SolutionBlueprint` root and holds both metrics (instantiated list
  structures, instantiated section ids, where *instantiated* means the id
  appears as a mapping key in some `samples/*.docspecs.yaml`, never in prose)
  against the committed remaining set in
  [`tool/sample_coverage_manifest.yaml`](tool/sample_coverage_manifest.yaml),
  which is **empty**: full instantiation coverage, ratcheted — a structure
  added to the model without a sample instantiating it goes red. Every sample
  also decodes through the typed Dart loader (the `sample_decode` gate,
  [`tom_som_dart_v0/tool/verify_samples.dart`](../tom_som_dart_v0/tool/verify_samples.dart)).
  That is a *single-language* guarantee: the structure round-trips in Dart, and
  exists in all nine ports — the generators compile against it — but is not
  proven to behave identically in the other eight.
* **Loaded by the golden harness, byte-compared nine ways.** Only what the
  Meridian sample (and the corpus tables) exercise gets this. Joining the
  harness is a per-sample opt-in: widening the parity bound means pointing the
  nine golden generators at a further sample and regenerating, not growing
  `samples/` — the coverage gate counts a new sample the moment it lands, the
  harness never does on its own.

Coverage and parity are therefore different quantities and only the second is
the parity bound. Full instantiation coverage (the empty manifest) closes the
worst gap the old bound statement named — no reachable structure is
uninstantiated and undecoded — but a structure instantiated only outside the
Meridian sample can still be wrong in one non-Dart language while the golden
logs stay green, because the logs never mention it. SOM §19 states the
coverage rule from the model's side.

**This subsection is the canonical statement of the bound.** Release-facing
wording that claims nine-way parity must cite it rather than restating the
numbers — one sentence, one place, not nine copies that drift apart.

##### The nine generators move together

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

##### The nine validators move together too — and the corpus is what enforces it

Same rule, different mechanism. Every instance-tier validation check is
nine-language (SOM §9), and what *forces* a runtime to implement one is a case
in [`corpus/validation_cases.json`](corpus/validation_cases.json): a case
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

##### …and so does the DocSpecs tier (SOM §14)

The SOM §14 DocSpecs tier is a **second, separate** rule vocabulary — the eleven
`DocSpecsViolationRule` constants, not the instance tier's
`SpecValidationCode` — and it is nine-language for the same reason. Its corpus
is a pair:

| File | Role |
| ---- | ---- |
| [`corpus/docspecs_schema.yaml`](corpus/docspecs_schema.yaml) | The shared schema **input** — one schema whose features exist to provoke all eleven rules (a `max-text-length`, a `min-count: 2` container, a required form field with a pattern check, …). |
| [`corpus/docspecs_cases.json`](corpus/docspecs_cases.json) | One case per rule: the invalid markdown plus the `rule` / `sectionId` / `line` triples the reference produces. |
| [`samples/invalid_demo_document.md`](samples/invalid_demo_document.md) | The golden tier's counterpart to the cases file — one document violating all eleven rules at once, against the *same* schema. Read only by the nine golden generators, not by the runtime runners. |

Three things about the table are deliberate:

- **The expectations are computed, not transcribed.** SOM §14 names the Dart
  triples as the golden reference, so `UPDATE_CORPUS=1` runs the reference
  validator to produce them. A hand-typed line number would be a second,
  drift-prone source of truth.
- **`message` is not carried.** It is prose; pinning it across nine languages
  would make a reword a nine-package change for no contractual gain.
- **Each runtime's coverage gate reads its own vocabulary**, never a hand-kept
  list — Dart and Python from their enum, JavaScript and TypeScript from the
  frozen rule object, and the constant-based ports from an enumerable
  declaration in the runtime itself (`DocSpecsAllRules`, `ALL_RULES`,
  `DOCSPECS_ALL_RULES`, `kDocSpecsAllRules`). Adding a rule is then the very act
  that demands its case.

The golden's `docspecs` section reads a **valid** sample, so it could not cover
this: before the table existed, all eleven rules were unexercised and the nine
logs agreed byte-for-byte about a question none of them had been asked. Wiring
the table immediately found three ports (JavaScript, TypeScript, Go) reporting
the schema *type name* instead of the containing section's id on the three
cardinality rules.

The `docspecs-invalid` golden section (FORMAT 10) is the **third** row above and
does **not** make the cases table redundant — the two tiers exercise different
code. The cases table drives each *runtime's* conformance runner; the golden
section drives each *v0 generator's* hand-ported `DV` emit line, which is a
separate file reading the violation through a separate accessor. That gap was
not hypothetical: the JavaScript generator read `v.rule.name` against a runtime
that models the vocabulary as frozen string constants, and emitted `DV
undefined` — a defect the passing cases table could not see, because the valid
sample meant the line had never once executed.

##### …and so does the editor tier (SOM §9)

`SpecEditor` and the `spec_typed_values` helpers are nine-language for the third
time over, and [`corpus/editor_cases.json`](corpus/editor_cases.json) is what
forces it. Unlike the two tables above it is **not** a set of independent cases:
it is a single stateful, ordered script. Each step mutates one shared document
built from [`corpus/model.meta.json`](corpus/model.meta.json), and later steps
read what earlier steps wrote — so a runner must execute it start to finish
against one document, and a case may not be reordered or run in isolation.

The script's twenty-three ops divide into three groups: assertions
(`value`, `rawContent`, `formValue`, `rawFormField`, `formFieldNames`,
`headline`, `itemSectionId`, `hasValuesUnder`), mutations (`setValue`,
`setContent`, `setFormValue`, `setHeadline`, `addListItem`, `removeListItem`,
`clearSection`), and the `…Throws` variants that pin **which** inputs a runtime
must reject rather than silently coerce. The distinction between the two write
modes is the contract's core: reads are forgiving, writes are strict — but
"forgiving" is about *values*, not about *paths*, which is why the `…Throws`
group covers both sides (`valueThrows` / `formValueThrows` /
`formFieldNamesThrows` / `headlineThrows` as well as the four write variants).

Every one of the five conversion families in `spec_typed_values` — `int`,
`double`, `num`, `bool` and enum names — is exercised through **both** dispatches,
the content leaf (`value` / `setValue`) and the form field (`formValue` /
`setFormValue`), because a port wires those two separately and a single-sided
table lets it wire one and forget the other.

Four properties of the script exist to catch a specific class of port bug, and
all four were written deliberately rather than discovered:

- **The integral double.** `setFormValue weight 2` must leave the raw text
  `"2.0"`, never `"2"`. Languages with a single numeric type (JavaScript,
  TypeScript, Go's `interface{}` decode) will store `"2"` unless the port
  handles it, and every downstream serialization then diverges from Dart by one
  character in a place no golden reads.
- **The `num` family is the integral double's opposite, on purpose.** The same
  `num` field writes `7` for an integral value and `7.5` for a fractional one —
  so a port that implements one "format any number" routine fails exactly one of
  the two blocks, whichever way it chose. The pair is what makes the choice
  visible; either block alone can be satisfied by the wrong rule.
- **Verbatim string passthrough.** Writing the *string* `"12"` into an `int`
  field stores `"12"` and reads back `12`; writing `"not-a-bool"` into a `bool`
  field stores it verbatim and reads back nothing. A port that eagerly
  canonicalises on write passes every other case and fails these.
- **A dangling path throws on read, too.** A port that answered `null` for a
  path that does not exist would satisfy every non-throwing case in the file,
  because a null read is indistinguishable from an unset leaf. Only asking for
  the error separates "no value here" from "no such place".

The `num` family arrived last, and paid for itself on the first run: it caught
the Java port's `somParseNum` returning `Integer : Double` from a **conditional
expression**, where Java's binary numeric promotion unboxes both arms to
`double`. That threw on an unparsable string and silently widened an integral
`7` to `7.0` — a defect that had shipped through every prior nine-way green run,
because no case had ever declared a `num`.

The trap has a second form here, worth stating because the enum-coverage guard
cannot catch it: a table that exists but is **loaded by one runner** is no better
than a table that does not exist. The editor surface shipped Dart-only for two
rounds while a doc-comment, the golden harness and `run_all_suites.sh` all
reported nine-way parity, because `editor_cases.json` resolved at exactly one
site in the repo. A corpus binds only the runners that read it — so wiring a new
table into all nine runners is part of adding it, not a follow-up.

##### …and so does the scripting tier (SOM §15)

The query facility and the constrained-creation gate are nine-language for the
fourth time over, and they came with **six** tables at once — because the same
trap that hid the editor surface had hidden these: both were Dart-only while the
spec listed them unqualified in the mirrored surface, and neither absence had
ever failed a run, because neither had a table.

| File | What it pins |
| ---- | ------------ |
| [`pattern_cases.json`](corpus/pattern_cases.json) | The portable matcher (`SomTextPattern`) on its own: spans per pattern/text pair, plus the patterns that must be **rejected at compile**. |
| [`query_cases.json`](corpus/query_cases.json) | Every query dimension and their AND-composition — matched paths in order, with each hit's snippet and spans. |
| [`projection_cases.json`](corpus/projection_cases.json) | What one node projects to: kind, class, section id, headline, and the searchable strings **in order**. |
| [`cursor_cases.json`](corpus/cursor_cases.json) | Cursor laziness and stability — the `next`/`take`/`count` interleaving, and re-validation against an edit made mid-iteration. |
| [`node_creation_cases.json`](corpus/node_creation_cases.json) | Independent `checkAddNode` verdicts: the accepted additions and the four `SpecCreationCode` rejections. |
| [`node_creation_script.json`](corpus/node_creation_script.json) | An ordered, stateful `SpecNodeCreator.add` script, so cardinality and id-sequencing are exercised against a document that is actually growing. |

Four properties of these tables are deliberate:

- **The pattern table is separate from the query table.** A span disagreement
  that surfaces only through `query_cases.json` arrives wrapped in projection and
  filtering; `pattern_cases.json` puts the matcher on trial by itself, so the
  failure names the matcher.
- **Rejection is an expectation, not an omission.** A pattern outside the subset
  must raise, and the table says so. A port that reads `\w` as a literal `w`
  otherwise passes every positive case and quietly matches nothing.
- **Non-ASCII text is what discriminates the offsets.** UTF-16 code units, UTF-8
  bytes, code points and graphemes all agree across ASCII, so an ASCII-only table
  says nothing about how a port indexes text. The three cases that put a match
  *after* non-ASCII text — and the one that matches `.` against a lone surrogate
  pair — are what caught the Python port indexing by code point.
- **Every annotation filter has a positive case.** `mapsTo`/`detailedIn` were
  first written as "matches nothing" cases only, which a runtime that never
  implemented the filter satisfies exactly as well as one that did. The fixture's
  `Card` class now carries both annotations so the filters can be pinned by what
  they *select*.

`node_creation_cases.json` deliberately drops the rejection `message` and keeps
only the `code`, for the same reason SOM §14 drops it: it is prose, and pinning it
would make a reword a nine-package change.

##### …and so does the version check (SOM §4.2 / §21)

[`corpus/editability_cases.json`](corpus/editability_cases.json) pins the verdict
on whether an object model may edit a document **at all**. It is the fifth tier to
arrive after the same trap: `SomEditability` was declared in all nine runtimes and
asked about by no corpus file at all —
[`stamp_cases.json`](corpus/stamp_cases.json) is adjacent but pins *decoding*
(`generatedAt`, `metaSchemaVersion`, the counts), never the version *comparison*.

Each case gives `generated` + `documentVersion` and expects an `editability`
token, a `rejects` flag and the refusal `message`. Three properties are
deliberate:

- **Both halves of one rule are asserted.** `somEditabilityFor` is the single
  definition and the throwing check switches on it, so `rejects` is merely "the
  classification is not `editable`". Asserting both is what fails a port that
  classifies correctly and *refuses* wrongly — which is exactly what the table
  found in Rust on its first run.
- **The `message` is pinned here, unlike SOM §14 and `node_creation_cases.json`.**
  Those drop it because the code already identifies the fault. Here it does not:
  `invalidVersion` is **one outcome with two causes** — an unparseable document
  stamp or an unparseable object-model constant — and the message is the only
  place they separate. Dropping it would leave a port free to blame the document
  for its own broken constant.
- **The expectations are hand-written from the rules, not read back from the
  runtime.** A table generated by calling the implementation agrees with the
  reference by construction and can never catch the reference being wrong. So
  the table carries the boundary pairs a rule statement implies rather than a
  transcript: equal versions, minor below and above, major above **and below**
  (cross-major is an identity, not an ordering), the absent stamp in both its
  spellings (`null` and `""` — CS4-D2), the malformed shapes (`"1"`, `"1.x"`,
  `"1.2.3"`), the two lexicographic traps (`2.10` vs `2.9` both ways round), and
  an unparseable *generated* version.

Wiring the table settled a genuine six-to-three divergence on that last input:
Dart, Python, JavaScript, TypeScript, Java and C++ **threw** out of the
classifier, while Go, Rust and C returned `invalidVersion`. The three are right
and the six were changed to match — a classifier whose entire purpose is not to
throw cannot throw, and the throwing form is not expressible in all nine ports
anyway (C has no exceptions, Go returns errors, Rust returns a plain enum), so
only the total form can be a nine-language contract. SOM §4.2/§21 now states the
totality outright.

##### …and so does the Markdown import-rejection protocol (SOM §11.7)

[`corpus/markdown_import_cases.json`](corpus/markdown_import_cases.json) pins what
a Markdown import does with a block it **cannot** place. It arrived after the same
trap as the tier above: `SpecMarkdownRejectReason` was declared in all nine
runtimes and asked about by nothing, because [`expected.md`](corpus/expected.md)
is a byte-golden of a *successful* export and the three markdown tiers all assert
`isClean()`. The failure that hid behind that is the worst one SOM §11.7 exists to
prevent — a port that silently **drops** an unplaceable block is
indistinguishable from one that never met it.

Each case is a Markdown source plus two expectations that have to hold
*together*:

- **`rejections`** — every block the importer could not place, in report order,
  pinned on the full `(line, reason, anchor, message)`.
- **`document`** — what *did* land, as the `toJson()` document map, compared the
  way each port already compares the memory-landing tier: stage → `loadJson` →
  `toJson` → canonical JSON.

Three properties are deliberate:

- **Neither half alone says what SOM §11.7 requires.** A port that drops a block
  fails `rejections`; a port that reports it and then abandons the rest of the
  parse fails `document`. Only the pair states "reported, **not** dropped, and
  the rest still landed", which is why every case carries both.
- **The `message` is pinned**, for the same reason as the version tier: a reason
  is one classification with several causes. `unknownSection` has three (no match
  at this position, an unresolvable parent, no such document root); a table
  pinning only the reason would let a port collapse them. `orphanContent` now has
  exactly one — text before the document root. Text before a form's first field
  label used to be its second, and the case that pinned it is still in the table,
  now asserting the opposite: that prose is the form's preamble (SOM §11.4 rule
  7), it lands in the form's content, and nothing is rejected. A case kept
  because its verdict flipped is worth more than one deleted.
- **Cases are parsed against a fresh document.** Headline staging compares
  against the *schema* default, never against the target document, so a parse is
  document-independent and each case is reproducible in isolation.

The ten cases cover each reason at least once, `unknownSection` in each of its
three causes, a rejected block coexisting with imported ones in every case but
the one where the root itself is unknown, and one document exercising all five
reasons at once — which also pins the **report order**, not the same as ascending
source order (a `missingValue` is raised once the parser has moved past the empty
section's heading). All nine ports agreed on their first run; unlike the version
tier, this one found no divergence.

##### …and so does the Phase-4 CodeSpecs extract tier

[`corpus/codespecs_extract_cases.json`](corpus/codespecs_extract_cases.json) pins
`spec_codespecs_extract`, the machine half of TomSpecs Phase 4
([codespecs_mapping.md](../tom_specs_model/doc/codespecs_mapping.md) §1.1.1): it
routes a filled document by `@CodeSpecKind` into one bounded, cited **extract**
per CodeSpecs area, which an authoring agent then writes Dart against. The
surface is a *runtime* surface in all nine languages rather than a Dart tool,
because Phase 4 is not a Dart-only phase — a project whose specification lives
outside a Dart toolchain must still be able to produce its extracts.

The table has four parts, and each pins something the others cannot:

- **`catalog`** — the area catalogue of
  [codespecs_mapping.md](../tom_specs_model/doc/codespecs_mapping.md) §4.1/§4.4.3/§4.4.6,
  supplied as an *input* rather than baked into nine runtimes. The real one is
  generated by
  [`tom_specs_clitool/bin/codespecs_areas.dart`](../tom_specs_clitool/bin/codespecs_areas.dart);
  the corpus carries a six-area cut of it, sized to exercise the shapes (a
  locus-split area with two slices, an area whose extract comes out empty) rather
  than to be complete.
- **`routings`** — the per-class verdict diagnostic. All three verdicts of
  [codespecs_mapping.md](../tom_specs_model/doc/codespecs_mapping.md) §8.3 have to
  be reachable, plus the two the walk itself produces: `documentRoot` (a
  `@Document` root is structurally exempt from `ROUTE-TOTAL`) and `unrouted`.
- **`extracts`** — the emitted artifact, byte for byte, in **both** renderings:
  the `.extract.yaml` of record and the `.extract.md` view. Two goldens, because
  they are two emitters and a port can transcribe one and paraphrase the other.
- **`errorCases`** — the `ROUTE-TOTAL` failure, carrying its **own** inline model
  and state. The shared `model.meta.json` is a valid model by construction, so a
  port in a language without cheap structural editing would otherwise have to
  break the fixture to reach this case.

The tier's load-bearing assertion is the **verbatim guard**: every scalar in
every extract must occur character-for-character among the document's stored
values. That is
[codespecs_derivation_contract.md](../tom_specs_model/doc/codespecs_derivation_contract.md) §2.8 **C1** —
"no summarising, no rephrasing, no sentence assembled from field values" —
made checkable rather than trusted, and it is the one property that keeps the
generator on its side of the line between the two Phase-4 roles. A port that
helpfully trims, joins or title-cases a value fails it, and a port that quietly
drops a `@FollowUpKind` subtree *into* an extract fails the exclusion assertion
beside it.

The committed output of a real run over the Meridian sample lives under
[`generated-doc/codespecs_extracts/`](generated-doc/codespecs_extracts/) — 27
areas as `.extract.yaml` / `.extract.md` pairs plus the gate's verdict file — and
the CodeSpecs trio authored from those extracts is
[`samples/meridian_codespecs/`](samples/meridian_codespecs/).

##### Proving a table is load-bearing: `tool/parity_gate.sh`

Nine green suites do not show that nine runners read a table, and check counts
cannot settle it either — each runner's base count differs (Dart/Python/JS/Rust
509, C++ 511, TS 516, C 534 at the time of writing), so two matching numbers are
a coincidence, not evidence. The only decisive test is to **break the corpus and
require every suite to notice**:

```sh
tool/parity_gate.sh --corpus editor_cases.json \
  --from '"expect": "2\.0"' --to '"expect": "2"'
```

It mutates one expectation, runs the named suites (default: the nine
`*_runtime`), and passes only when **all** of them go red; any suite that stays
green is not reading the table. The corpus is restored unconditionally on exit,
and the mutation must match exactly once — a pattern that hits twice, or not at
all, is not a controlled experiment, so the script refuses to run rather than
report a result it cannot justify.

Pick a mutation the reference genuinely produces and a plausible port genuinely
gets wrong. The integral double above is the model case: it is the default wrong
answer for every single-numeric-type language. Run this when a new corpus table
is added, and again after wiring it into the last runner.

**Mutate an expectation, never an input.** A table's inputs and its expected
results sit in the same file, and it is easy to reach for the nearest unique
string. But corrupting an input just asks the nine runners a *different* question
— they compute the new answer, agree on it, and stay green, which is the correct
outcome and proves nothing about whether they read the table. The gate reporting
"all suites stayed green" on such a mutation is the script working, not the
corpus failing.

##### TypeScript step — build the runtime `dist/` first (CS4-D6)

The TypeScript golden generator (and the `tom_som_typescript_v0` facade in
general) imports `SpecDocument` from `tom_som_typescript_runtime` by bare
package name, which resolves to the runtime's git-ignored
`dist/src/index.d.ts`. On a clean checkout that file does not exist yet, so the
runtime must be built before the facade. `regenerate_golden.sh` already does
this explicitly for the TypeScript step, and the facade's `npm run build` has a
`prebuild` script that builds the runtime first — so both paths work without a
manual pre-step. See
[`tom_som_typescript_v0/README.md`](../tom_som_typescript_v0/README.md).

### Corpus completeness — the enum-coverage guard

**Read this before adding a check, a rule, or a code to any runtime.**

A corpus table is what makes the eight ports *prove* they implement something: a
committed case expecting a result a runtime does not produce fails that
runtime's own conformance runner. The corollary is the trap — a constant with
**no** case is not weakly covered, it is **invisible**. The suites stay green and
the goldens stay byte-identical because all nine agree about a question none of
them was asked.

This has cost two rounds. `danglingReference` and `oneOfCaseMismatch` shipped
Dart-only; later, all eleven `DocSpecsViolationRule` rules were unexercised while
the SOM §14 golden read three lines off a *valid* sample — and once a table existed,
two of the five ports that had the rules turned out to be wrong.

So the rule is:

> **Every enumeration that is part of the nine-language contract must be diffed
> against a corpus table, and adding a constant must be the act that demands its
> case.**

The mechanism is
[`tom_som_dart_runtime/test/enum_coverage_test.dart`](../tom_som_dart_runtime/test/enum_coverage_test.dart),
in the reference runtime's default `dart test` run. It has two halves:

- **Realisation** — every registered enum's constants must appear in its corpus
  table (ECG2), and every token a table exercises must name a real constant
  (ECG5, which catches an extractor reading the wrong key — otherwise that
  misreads as missing coverage and points at the enum instead of the extractor).
- **Totality** — *every* enum declared in `tom_som_dart_runtime/lib/` must be
  either registered or explicitly exempt (ECG1), found by parsing the source
  rather than by reflection, so an enum nobody remembered to register fails the
  run. This is the half that makes registration mechanical instead of a
  convention.

#### Adding a guarded enumeration

One entry in the `_guarded` list:

```dart
CorpusGuardedEnum(
  enumName: 'DocSpecsViolationRule',
  declared: _wire(DocSpecsViolationRule.values),
  corpusFile: 'docspecs_cases.json',
  exercised: (c) => { /* pull the tokens out of the decoded table */ },
  why: 'a §14 DocSpecs rule that eight runtimes need not implement',
),
```

`exercised` is a function, not a `listKey`/`memberKey` pair, because the tables
genuinely differ in shape — a list of cases each holding a list of errors, a list
of cases each holding one scalar kind, a map of classes each holding a list of
fields. It is always **per-enum-per-file** and never a global token scan:
`malformedHeading` is a constant of both `DocSpecsViolationRule` and
`SpecMarkdownRejectReason`, in different tiers, so a bare-token scan would credit
one enum with the other's coverage.

`_wire` maps constant names to the tokens the corpus writes. Pass an alias only
where they differ — `SpecFieldKind.enumValue` serializes as `enum`.

#### Waivers and exemptions

Two escape hatches, both narrow and both self-expiring:

| | Scope | Requirement |
| --- | --- | --- |
| **Waiver** | One constant of a registered enum | Names the todo that closes the gap. ECG3 fails the moment the corpus starts exercising it, so it cannot outlive its cause. |
| **Exemption** | A whole enum, absent from the registry | Names an `ExemptionReason`. If that reason `isTemporary` (`noCorpusYet`, `dartOnly`) the note must name the todo that ends it — ECG6 enforces this. |

The two permanent reasons are `mirrors` (the enum is a second spelling of a
registered one; ECG4 pins them constant-for-constant, which is stronger than a
corpus diff) and `presentation` (app display semantics, deliberately outside the
nine-language contract).

A waiver is a **tracked exception, not a suppression**. Prefer registering an
enum with one waived constant over exempting the whole enum: the rest of its
constants stay guarded, so a *new* constant still fails the run.

### Packaging (SOM §17)

Every SOM target ships as a pair of installable packages — the hand-authored
generic `tom_som_<lang>_runtime` and the generator-emitted typed
`tom_som_<lang>_v0` facade — each versioned to the **TomSpecs model version**
(currently `1.0.0`; the model's `1.0` label maps to a semver patch). Both halves
of every pair carry a README short how-to block and a separate
`readme_howtointegrate.md`, plus a `LICENSE` and `CHANGELOG.md`. The facade's
packaging files are regenerated in place by `generate_som.dart` (via the generic
packaging hook,
[`tom_specs_clitool/lib/src/packaging.dart`](../tom_specs_clitool/lib/src/packaging.dart)),
so they never drift from the model version.

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

#### Packaging sign-off sweep (SOM §17)

The cross-cutting packaging sign-off re-runs `generate_som.dart` (confirming
every facade regenerates to the current model version with zero committed
churn), builds/packs all nine languages with the commands above, and re-asserts
the done-criteria: `dart analyze` clean, the `tom_specs_clitool` suite green, the
nine language APIs green, and cross-language golden byte-identity unaffected (the
`regenerate_golden.sh` run above). A green sweep proves the 18 packages are
internally consistent, versioned to the model, and independently buildable.

### The eighteen test suites — `run_all_suites.sh`

The golden harness proves the nine APIs *read* the sample identically (see
"The parity claim's bound" above for how far the sample reaches). It says
nothing about the eighteen hand-authored test suites that sit in the nine
runtime and nine `v0` packages — and for a long time nothing ran them together,
so a suite could stay red without anyone noticing.

[`tool/run_all_suites.sh`](tool/run_all_suites.sh) closes that: every SOM package
now carries a uniform `run_tests.sh` that runs everything hand-authored in it,
whatever the ecosystem underneath, and this driver is the aggregate over all
eighteen. Before the suites it runs the two sample gates — `sample_coverage`
([`tool/check_sample_coverage.dart`](tool/check_sample_coverage.dart)) and
`sample_decode`
([`tom_som_dart_v0/tool/verify_samples.dart`](../tom_som_dart_v0/tool/verify_samples.dart))
— so a run reports twenty results in total.

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

#### The suites read their root set from the generated registry

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

### Discoverable path access — metadata tree, nav, and ID-tree (SOM §8)

The former per-root `<Root>Paths` flat constant holders are **retired** (SOM §8).
In their place every generated `tom_som_<lang>_v0` facade emits a
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
sample
([`tom_som_dart_v0/example/f_sample_hybrid_access.dart`](../tom_som_dart_v0/example/f_sample_hybrid_access.dart))
for reaching a path without a literal by navigate-then-read off a node's `.path`.

## Architecture

```text
tom_som_conformance/
├── samples/                 the shared specification documents
│   ├── meridian_order_management.docspecs.yaml   the golden harness's diet
│   ├── meridian_order_management.md              …and its markdown rendition
│   ├── uam_access_hub.docspecs.yaml              reaches what Meridian does not
│   ├── exercise_full_model.docspecs.yaml         generated; drives coverage to empty
│   ├── invalid_demo_document.md                  invalid on purpose
│   └── meridian_codespecs/                       the Phase-4 CodeSpecs trio
├── corpus/                  language-agnostic case tables + expected outputs
├── golden/                  per-language logs — git-ignored, regenerated on demand
├── generated-doc/           generator output, never hand-edited
│   └── codespecs_extracts/  27 area extracts (.yaml of record + .md view)
└── tool/                    the cross-language drivers and gates
```

| Path | Purpose |
| ---- | ------- |
| [`samples/`](samples/) | The shared specification samples: the Meridian pair (`meridian_order_management.docspecs.yaml` + `.md`, authored through the Dart typed facade and loaded by every language's golden generator), the hand-authored UAM access-hub sample, the generated full-model exercise sample, and the deliberately invalid companion fixture. Together the `*.docspecs.yaml` samples instantiate the **full** SBP-reachable model (the coverage manifest is empty); only the Meridian pair feeds the golden harness. See [`samples/README.md`](samples/README.md). |
| [`samples/meridian_codespecs/`](samples/meridian_codespecs/) | The Phase-4 CodeSpecs trio authored from the Meridian sample's extracts — `meridian_codespec_shared` / `_client` / `_server`, the three-project split. Skeletal `Cs*`-annotated Dart depending only on [`tom_code_specs`](../tom_code_specs/), kept as a worked reference for what Phase 4 produces; outside the golden harness and outside the coverage gate, which read `*.docspecs.yaml` only. |
| [`corpus/`](corpus/) | Language-agnostic case tables plus their expected outputs, consumed by each runtime's conformance runner. **Every tier has a `##### …and so does the <tier>` subsection above, and each one names its own tables** — the tiers are not listed here, because a list in two places is a list that goes stale in one of them (it did: the scripting tier and the version check were both added without this row noticing). What keeps the tables *complete* is the enum-coverage guard — see "Corpus completeness" above before adding a check to any runtime. |
| `golden/` | Per-language golden logs (`<lang>.log`) written by the nine golden generators. **Git-ignored** — regenerated on demand by [`tool/regenerate_golden.sh`](tool/regenerate_golden.sh). |
| [`generated-doc/`](generated-doc/) | Generator output, kept out of the hand-written tree so a stray ad-hoc run cannot leave a stale copy among authored files. One type so far: `codespecs_extracts/`, the 27 per-area Phase-4 extracts emitted by `spec_codespecs_extract` over the Meridian sample, as `.extract.yaml` (the artifact of record) / `.extract.md` (the rendered view) pairs plus `gate.verdicts.yaml`. |
| [`tool/`](tool/) | Seven files, four concerns. The golden harness — [`regenerate_golden.sh`](tool/regenerate_golden.sh) + [`compare_golden.dart`](tool/compare_golden.dart). The aggregate driver — [`run_all_suites.sh`](tool/run_all_suites.sh), the two sample gates plus eighteen test suites. The `sample_coverage` gate — [`check_sample_coverage.dart`](tool/check_sample_coverage.dart) with its committed remaining set [`sample_coverage_manifest.yaml`](tool/sample_coverage_manifest.yaml) (now empty — see "The parity claim's bound") and the exercise-sample generator [`build_exercise_sample.dart`](tool/build_exercise_sample.dart). And the corpus load-bearing gate — [`parity_gate.sh`](tool/parity_gate.sh). The `sample_decode` gate's tool lives with the Dart facade ([`tom_som_dart_v0/tool/verify_samples.dart`](../tom_som_dart_v0/tool/verify_samples.dart)). |

## Ecosystem

```text
        tom_specs_model            the annotated Dart model — the single source
              │
              ▼
        tom_specs_clitool          generates the nine language packages
              │
      ┌───────┴───────────────────────────────┐
      ▼                                       ▼
 tom_som_<lang>_runtime  ×9            tom_som_<lang>_v0  ×9
 (hand-authored, generic)              (generated, typed facade)
      │                                       │
      │   each ships run_tests.sh             │   each ships a golden generator
      └───────────────┬───────────────────────┘
                      ▼
             tom_som_conformance          ← you are here
             one sample set · one corpus · one golden harness
```

Nothing depends on this directory; it depends on the eighteen packages it tests
and on [`tom_code_specs`](../tom_code_specs/) for the CodeSpecs sample trio. It
is a test fixture at repository scale, not a library.

## Further documentation

**TomSpecs subject matter** — the documents that *decide* the rules this
harness enforces:

| Document | Decides |
| -------- | ------- |
| [index.md](../tom_specs_model/doc/index.md) | The catalogue of all fifteen subject-matter documents, and the `§` citation convention this README uses |
| [som_multiplatform_spec_model.md](../tom_specs_model/doc/som_multiplatform_spec_model.md) | The Spec Object Model itself — the nine-language generation, the validator tiers (SOM §9, SOM §14), the editing and scripting surfaces (SOM §15), the discoverable metadata (SOM §8), the golden-harness contract (SOM §19) and packaging (SOM §17) |
| [som_toolchains.md](../tom_specs_model/doc/som_toolchains.md) | Which toolchain each language's suite needs, and how to run the Dart host without an installed SDK |
| [som_generator_config.md](../tom_specs_model/doc/som_generator_config.md) | The `tom-spec-object-model` config block the nine packages are generated from |
| [tom_specs_model_meta_schema.md](../tom_specs_model/doc/tom_specs_model_meta_schema.md) | The on-disk shape of `spec_model.meta.json`, which the coverage gate walks |
| [codespecs_mapping.md](../tom_specs_model/doc/codespecs_mapping.md) | The Phase-4 area catalogue and routing verdicts the extract tier pins |
| [codespecs_derivation_contract.md](../tom_specs_model/doc/codespecs_derivation_contract.md) | The verbatim guard **C1** — no summarising, no rephrasing — that the extract tier makes checkable |

**This directory:**

| Document | Covers |
| -------- | ------ |
| [samples/README.md](samples/README.md) | Each shared sample, the two wire formats, the gates over them, and how to regenerate |

**Siblings:**

| Package | Role |
| ------- | ---- |
| [tom_specs_model](../tom_specs_model/) | The annotated Dart model everything here is generated from |
| [tom_specs_clitool](../tom_specs_clitool/) | The generator that emits the nine language packages and their metadata |
| [tom_som_dart_v0](../tom_som_dart_v0/) | The reference facade — its golden generator defines the log format |
| [tom_som_dart_runtime](../tom_som_dart_runtime/) | The reference runtime — hosts the enum-coverage guard |
| [tom_code_specs](../tom_code_specs/) | The `Cs*` annotation framework the CodeSpecs sample trio depends on |

## Status

**No manifest and no version.** This is not a package: the assets are consumed in
place by the eighteen SOM packages' own test runners and by the drivers in
[`tool/`](tool/), so there is nothing to publish and nothing to pin.

**Twenty results** from `./tool/run_all_suites.sh` — the two sample gates plus
the eighteen hand-authored suites — all passing on a host with the nine
toolchains present, and skipped with the reason stated where a toolchain is
absent. The **nine golden logs are at `FORMAT 10` and byte-identical**, and the
instantiation-coverage manifest is **empty**.

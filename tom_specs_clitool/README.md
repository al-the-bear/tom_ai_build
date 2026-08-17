# TomSpecs Spec Object Model (`tom_som`) — generator + generated component

`tom_specs_clitool` is the **generation host** for the multi-platform TomSpecs
Spec Object Model (`tom_som`). From the single source of truth — the annotated
Dart model in [`tom_specs_model`](../tom_specs_model) — it emits, **per
language**, a lossless meta-data file, DocSpecs/YAML schemas, and a typed
document-editing facade layered over a hand-written generic runtime.

This README lets a reader **configure, generate, and consume** the component in
any supported language from this file alone. It covers the config structure,
how to run the generators, what is produced, how the generated code is used, and
the versioning rules. Deeper references are linked inline.

- Architecture & rationale: [`som_multiplatform_spec_model.md`](../tom_specs_model/doc/som_multiplatform_spec_model.md)
  (the quest spec; section numbers below, e.g. *SOM §4.2*, refer to it).
- Config grammar in full: [`../tom_specs_model/doc/som_generator_config.md`](../tom_specs_model/doc/som_generator_config.md).
- Toolchain inventory per language: [`../tom_specs_model/doc/som_toolchains.md`](../tom_specs_model/doc/som_toolchains.md).

---

## 1. The two layers

The component is split into a **fixed, hand-written runtime** and a
**generated, typed facade** — one project each, per language:

| Layer | Project | Authored | Role |
| --- | --- | --- | --- |
| **Generic runtime** | `tom_som_<lang>_runtime` | by hand | Memory representation (`SpecDocument`), the meta-model "reflection" classes (`SpecModel` & friends), validation, and YAML/Markdown load-save. No version suffix. |
| **Typed facade** | `tom_som_<lang>_v0` | generated | Typed, code-completed document-editing API (`D00SolutionBlueprint` etc.) **over** the runtime's memory representation. Carries the version suffix (`_v0`, `_v1`, …). |

Both expose the **same document** through two parallel access paths (SOM §6): the
**type-safe** path (the generated classes) and the **generic / meta-model** path
(the runtime + the meta-data file). The typed path is optional ergonomics; the
generic path alone can read, write, validate, load, and save any document.

**All nine languages are shipped.** Every target — Dart, Python, Java,
JavaScript, TypeScript, Go, Rust, C, and C++ — has a hand-written generic
runtime (`tom_som_<lang>_runtime`) and a generated typed facade
(`tom_som_<lang>_v0`). `generate_som` has a typed emitter + generator for each;
none is skipped. All nine build and run their generated `v0` projects against
3989 classes and 14 document roots (see
[`../tom_specs_model/doc/som_toolchains.md`](../tom_specs_model/doc/som_toolchains.md) for the per-language toolchain
matrix). Dart and Python are the reference ports; the other seven were ported
from them (quest decisions D32–D38).

---

## 2. Configuration (`tom_som.yaml`)

The generator reads one top-level `tom-spec-object-model` block. The default
config lives at [`tom_som.yaml`](tom_som.yaml) beside this README. Full grammar:
[`../tom_specs_model/doc/som_generator_config.md`](../tom_specs_model/doc/som_generator_config.md); parser:
[`lib/src/spec_object_model_config.dart`](lib/src/spec_object_model_config.dart).

```yaml
tom-spec-object-model:
  version-label: v0            # optional, default "v0" — suffix on tom_som_<slug>_<label>
  output-base: ..              # optional, default "." — base for default output roots,
                               #   resolved RELATIVE TO THE CONFIG FILE'S DIRECTORY.
  document-roots:              # optional — absent/empty ⇒ generate ALL 14 document roots
    - D00SolutionBlueprint
    - D01CurrentLandscapeAssessment
  languages:                   # required, non-empty
    - dart                     # short form ⇒ default output root
    - python
    - language: java           # map form ⇒ explicit output override
      output: custom/java/tom_som_java
    - c++                      # alias-aware; resolves to slug "cpp"
```

| Key | Type | Default | Meaning |
| --- | --- | --- | --- |
| `version-label` | String | `v0` | Version suffix on generated project names (`_v0`, `_v1`, …). |
| `output-base` | String | `.` | Base dir for **default** per-language output roots, resolved relative to the config file. The shipped `..` places generated projects as siblings of `tom_specs_clitool` under `tom_ai/ai_build/`. |
| `document-roots` | List\<String\> | *all 14 roots* | Document root type names to generate; empty/absent means every root. |
| `languages` | List | *(required)* | Generation targets, in order. Each entry is a token string or a `{language, output}` map. |

**Language tokens** are case-insensitive and alias-aware (`js`→`javascript`,
`ts`→`typescript`, `golang`→`go`, `rs`→`rust`, `c++`/`cxx`→`cpp`, `py`→`python`).
Each resolves to a package-safe **slug** used in the project name
`tom_som_<slug>_<version-label>`. The parser rejects an empty/unknown/duplicate
language, a wrong-typed value, a non-string `document-roots` entry, or a
document lacking the `tom-spec-object-model` block.

---

## 3. Running the generator

From the `tom_specs_clitool` package root:

```bash
# Generate every configured language target from the default config:
dart run bin/generate_som.dart

# Use a specific config and override key paths:
dart run bin/generate_som.dart \
  --config tom_som.yaml \
  --model   ../tom_specs_model \
  --runtime ../tom_som_dart_runtime \
  --py-runtime ../tom_som_python_runtime
```

| Option | Default | Purpose |
| --- | --- | --- |
| `-c, --config` | `<clitool>/tom_som.yaml` | The `tom-spec-object-model` config YAML. |
| `--model` | `<ai_build>/tom_specs_model` | The source model package to read. |
| `--runtime` | `<ai_build>/tom_som_dart_runtime` | Dart runtime package the generated pubspec depends on. |
| `--py-runtime` | `<ai_build>/tom_som_python_runtime` | Python runtime the generated manifest depends on. |
| `--java-runtime` | `<ai_build>/tom_som_java_runtime` | Java runtime the generated manifest depends on. |
| `--js-runtime` | `<ai_build>/tom_som_javascript_runtime` | JavaScript runtime the generated manifest depends on. |
| `--ts-runtime` | `<ai_build>/tom_som_typescript_runtime` | TypeScript runtime the generated `file:` dep points at. |
| `--go-runtime` | `<ai_build>/tom_som_go_runtime` | Go runtime the generated `go.mod replace` targets. |
| `--rust-runtime` | `<ai_build>/tom_som_rust_runtime` | Rust runtime the generated `Cargo.toml` path dep targets. |
| `--c-runtime` | `<ai_build>/tom_som_c_runtime` | C runtime the generated `Makefile` `RUNTIME_DIR` targets. |
| `--cpp-runtime` | `<ai_build>/tom_som_cpp_runtime` | C++ runtime the generated `Makefile` `RUNTIME_DIR` targets. |
| `--model-version` | major component of the model version | Override the integer model-version stamp. |
| `-h, --help` | — | Usage. |

Only the runtime options for languages actually listed in the config's
`languages` block matter; the rest keep their defaults and are unused.

**Version stamp.** The integer model-version and the human label are read from
the model's `lib/src/version.versioner.dart` (`version`, `buildNumber`,
`gitCommit`, `buildTime`). The `buildTime` is reused as the meta-data's
`generatedAt`, so re-running the generator without rebuilding the model produces
a **byte-identical** tree (idempotent; SOM §4.3). The committed artefacts are the
authoritative output — consumers never run the generator (SOM §4.3).

> The generator only **writes** the module/`lib`, `meta/`, `schemas/`, and the
> manifest; it **never deletes** files. Hand-authored `test/`, `example/`, and
> `examples/` directories survive regeneration.

**Freshness gate.** Regenerate after **every** change to `tom_specs_model` — the
meta is lossless, so even a reworded doc comment or an added annotation argument
changes all nine packages. This is enforced, not remembered: a canonical run
writes `tool/model_surface.stamp.json` with a fingerprint of the model it read,
and `test/model_freshness_test.dart` fails in the **default** suite when the
model has moved since. See
[`_copilot_guidelines/som_regeneration.md`](_copilot_guidelines/som_regeneration.md)
for what the fingerprint covers and what it deliberately ignores. Commit the
stamp together with the regenerated artefacts.

The same run also regenerates `tom_specs_model`'s own
`lib/src/generated/spec_ops.g.dart`, the `SpecClassOps` registry — it is
generated from the same model by the same reader, so it goes stale at the same
moment, and one stamp certifies both.

Related entrypoints in `bin/`:

| Entrypoint | Purpose |
| --- | --- |
| `generate_som.dart` | Generate the per-language `tom_som_<slug>_<label>` projects (this section). |
| `model_json.dart` | Export the resolved meta-data class graph alone. Refresh either **committed** asset with `--target editor` / `--target reviewer` — the target owns both the path and the version stamp, which the two assets pin differently (`tom_specs_model/doc/tom_specs_model_meta_schema.md`, "Refreshing the committed assets"). `--package` + `--output` is for ad-hoc exports elsewhere. |
| `outliner.dart` | Render a class-tree outline of the model from any document root. |
| `check_todo_citations.dart` | Check that every quest-todo id cited inline in `tom_specs_model/doc` still resolves to an **open** todo. Exits `1` on a citation of closed or non-existent work. Run by `tool/regenerate_outlines.sh` and by `test/todo_citations_test.dart` (see below). |
| `check_section_citations.dart` | Resolve every `§` citation in `tom_specs_model/doc` against `index.md`'s citation convention — a bare `§N` means *this* document. Exits `1` on a citation that resolves to no heading. The gate is **closed**: its default corpus is the doc folder plus the project READMEs that cite it (`defaultCitedReadmes`) and the CodeSpecs packages' Dart doc comments (`defaultCitedSourceRoots`, whose files are discovered beneath enumerated roots, so a new annotation file is gated the day it is written). `--extra <file>` adds one more file to that corpus. |
| `check_oe_citations.dart` | Resolve every `OE-` id cited in the editor project, the doc folder and the quest's bookkeeping against the Open-Ends Register (`tom_specs_editor_specification.md` §22). Exits `1` on a citation with no register row, and on a register that defines one id twice. `--root` / `--register` retarget it. |
| `stamp_serialization_order.dart` | Re-stamp `@SerializationOrder(n)` on every model member in source declaration order (SOM §5.2). Run this on `tom_specs_model` after editing the model, before regenerating. |
| `validate_codespecs.dart` | Run the `codespecs_derivation_contract.md` §6 checks over a generated CodeSpecs project trio. Takes `--shared` / `--client` / `--server`; exits `0` clean, `1` on any violation, `2` on bad usage. The trio is the pass's *subject*, not its only input: four checks cannot be answered from emitted code alone, and each takes its own **corroborating** input — `--migrations` (13), `--cs-vocabulary` + `--core-source` (9), the three `--regenerated-*` paths (31), and `--extracts` (32–36), the run's `generated-doc/codespecs_extracts` tree. The extracts answer two different questions: the specification *text* the comment checks (32, 33, 34) hold the emitted doc comments against, and the *routing* the self-sufficiency checks (35, 36) compare against the trio's back-links, per §9.6 of `codespecs_mapping.md`. Give the whole extract tree or none — a partial one understates what the trio was supposed to carry, and check 35 would pass a gap it could not see. Each corroborating input is optional, and an absent one names on stdout the checks it left unrun, so a skipped check never reads as a passed one. |
| `codespecs_areas.dart` | Transcribe `codespecs_mapping.md` §4.1 + §4.4.3 + §4.4.6 into `tom_specs_model/generated-doc/codespecs/codespecs_areas.json` — the 26-area catalogue the nine-runtime `spec_codespecs_extract` surface reads as its input. `--check` verifies the committed file without writing, and `test/areas_catalog_test.dart` runs the same comparison. |
| `docspecs_schema.dart` / `docspecs_yaml_schema.dart` | Emit the DocSpecs / YAML schemas. |
| `spec_ops.dart` | Regenerate `tom_specs_model/lib/src/generated/spec_ops.g.dart` — the `SpecClassOps` registry giving every model class its child slots, shallow clone and yaml scalar, plus each projection root's `connect:` binding. The **ad-hoc** entry point: `generate_som.dart` produces the registry as part of the canonical regeneration, so reach for this only to write it elsewhere (`--output`) or to refresh it alone without a nine-language run. |
| `summaries.dart` | Build an analyzer `sdk_summary.sum` (and, with `--package`, a one-off grouped `packages.sum`) for a single consumer. This is **not** the producer of `tom_specs_editor`'s scoped summary asset set — that set has one generator, `tom_forge/tom_dart_editor_bundler`, which also emits the `summary_scopes.g.dart` helper naming its asset keys. Here it serves `--sdk-only` (see `split_sdk_summary.dart` below). |
| `build.dart` | Build orchestration for the editor app. Its `--generate-summaries` step *invokes* the bundler against `tom_specs_editor/buildkit.yaml` rather than generating the asset set itself, so the assets and the paths the app asks for cannot disagree. |

And in `tool/` — four entries: two scripts, both still run, and two data files a
gate reads. A script here is a maintained entry point, not a scratch file:
one-shot census and codemod tooling is deleted once its campaign closes, because
a script that reads a shape the model no longer has is worse than absent — it
still looks runnable.

| Entry | Purpose | Re-run when |
| --- | --- | --- |
| `regenerate_outlines.sh` | The drift-proof batch entry point: renders all 16 committed outlines (`DocSpecsProject` + D00–D13, plus the compact `SolutionBlueprint`) into `tom_specs_model/generated-doc/outlines/`, then runs **all three** citation gates — `check_todo_citations.dart`, `check_section_citations.dart` and `check_oe_citations.dart` — as blocking steps under `set -e`. | Any model-shape change, and any documentation pass. Commit the diff. |
| `split_sdk_summary.dart` | Turns `assets/sdk_summary.sum` into the committed `lib/src/sdk_summary/` chunk set that `analyzer_bootstrap.dart` loads — the only producer of it. Pairs with `bin/summaries.dart --sdk-only`, which builds the `.sum`. | The Dart SDK version moves (`tom_specs_model/doc/som_toolchains.md`, "Regenerating after an SDK change"). |
| `model_surface.stamp.json` | Data, not a script: the model fingerprint a canonical `generate_som.dart` run writes, against which `test/model_freshness_test.dart` checks in the default suite. | Written by the generator; commit it with the regenerated packages. |
| `todo_citation_vocabulary.txt` | Data, not a script: the token allowlist that keeps ordinary technical terms from colliding with the discovered todo-id shapes. A **token** list, never a path list. | A false positive appears — add the one token. |

**Member serialization order.** `stamp_serialization_order.dart --package
../tom_specs_model` rewrites the model source to pin each member's on-disk
emission order (0-based, per class, source-declaration order). The ordinal flows
through `ModelReader` → `ModelJsonExporter` into the meta-data, so every language
serialises members in the authored order. Re-run it after any model edit that
adds, removes, or reorders fields; it is idempotent (old annotations are stripped
and renumbered).

**Doc-folder todo citations.** The TomSpecs documents cite quest-todo ids inline,
as a backticked id, to say who owns an open question. Such a citation decays
silently: the todo completes, is archived, and the document goes on pointing a
reader at finished work. `check_todo_citations.dart` closes that by resolving every
backticked id-shaped token in `tom_specs_model/doc` against the active, archived
and deleted todo files of the quests those documents cite
(`defaultCitedQuests` — `tom_specs` and `tom_core`).

Three things about it are deliberate:

- **Id shapes are discovered, not enumerated.** The stems come from the todo
  files themselves, so a citation of *another* quest's corpus resolves rather
  than going invisible — and a series nobody remembered to add to a list is
  still checked. The price of a shape rule is that ordinary technical terms
  collide with it; `tool/todo_citation_vocabulary.txt` is that price, paid one
  token at a time. It is a **token** list, never a path list.
- **Two exemptions, both inline**, so an exemption travels with the line rather
  than blanket-exempting a file. `<!-- todo-cite: provenance -->` allows a
  closed citation *only when the same line also cites an open todo* — the
  legitimate case is a provenance note ("`<landed prerequisite>` landed —
  restated by `<open todo>`"), where the raiser is history and what it raised is
  open. The example is written schematically on purpose: an earlier version
  named a real pair, and each todo that closed had to re-point it at the next
  one, which then closed in its turn. A
  `<!-- todo-cite: history -->` standing alone on its own line exempts the whole
  document, for a changelog.
- **It checks citations, not claims.** That a cited id still *exists and is
  open* is mechanical; that what the document says *about* it is still true is a
  semantic judgement and stays with a human reading pass.

The check runs from two places, because a citation goes stale from two sides: a
documentation pass trips it through `tool/regenerate_outlines.sh`, and a todo
archive trips it through `test/todo_citations_test.dart`, which runs in the
default `dart test`.

**Doc-folder section citations.** The same documents cite each other's *sections*
far more often than they cite todos, and `check_section_citations.dart` resolves
those. `index.md` owns the convention; this is its decision procedure. A bare
`§N` means **this** document — that carve-out is what makes the rule decidable at
all, since intra-document self-reference is how the documents overwhelmingly
cite. A document name overrides it in exactly five ways: standing in front of the
citation (across a soft line wrap, and as the tail of a markdown link), standing
behind it (`§N of <file>.md`), inherited within a run (`§N / §M / §K`),
document-map **table-row scope**, and its transpose **table-column scope** — a
column headed `` `<file>.md` § `` governs the numbers beneath it. Every
illustration here is written with metavariables: a real section number in an
unqualified example would be read by the checker as a citation of a section of
*this* README, which has none.

Three things about it are deliberate:

- **Resolution is exact.** `§N.M.K` resolves only against a heading `N.M.K`,
  never through its parent. The relaxation was tried and hides real defects: it
  excuses a hundred citations belonging to another document, and nothing a parser
  can see separates those from the genuine case of a citation naming a numbered
  *rule* inside a section. So such a citation says so in words — "rule 6 of
  §N.M" — and a citation written as a section number has to be one.
- **What counts as a citation is decided by the id's shape**, a dotted number or
  an upper-case symbolic id (`PF-FLW-OVE`), not by an exception list. `§oneof`,
  `§item` and the convention's own metavariable `§N` fall out for free, and a
  document that coins a new section-type name is covered on the day it is
  written.
- **The three narrow clauses are narrow on purpose.** The run joiner admits only
  separators and joining words, so a name mentioned two clauses back cannot vouch
  for an unrelated citation; table-row scope fires only when the row's first cell
  holds a document reference *and nothing else*, because a table that cites
  another document in column one and its own sections in column two is not a
  document map; and a table-*column* header must carry a trailing `§`, which is
  what makes it say the column holds sections rather than merely mention a file.

Five verdicts come out — `self`, `crossDocument`, `dangling`, `wrongSection`,
`unverifiable` — of which only `dangling` and `wrongSection` fail the run. A
citation naming a document outside the scanned corpus is `unverifiable`, not a
defect: the checker cannot see the file, which is not the same as the citation
being wrong.

`test/section_citations_test.dart` fixes the rule against hand-written fixtures
**and closes the gate**: its last test holds the live corpus at *zero*
violations. The corpus is the doc folder plus the project READMEs that cite it
(`defaultCitedReadmes`), which is also what `check_section_citations.dart` scans
by default — so the command and the gate cover the same files, and neither list
can drift from the other. Pass `--no-default-readmes` to scan the folder alone.

**`OE-` citations.** The third gate differs from the other two in where the
*citing* side lives: `OE-` ids are cited from **shipped source** — comments in
`tom_specs_editor`'s `lib/` and `test/`, notes in its `pubspec.yaml` and
`buildkit.yaml` — as durable handles on seams and drop-in points, and they
resolve against the Open-Ends Register in `tom_specs_editor_specification.md`
§22. That register was once a pair of quest documents, and consolidating the
editor specification deleted them without folding them in; 71 citations across
16 ids went on resolving to nothing until someone tried one, and three
`deferred.tom_specs.md` entries paid for it by restating in prose what an id
meant. `check_oe_citations.dart` makes the next such deletion fail a build step.

Two things about it are deliberate:

- **A row *defines* its id by carrying it in the row's first inline-code span**,
  and nowhere else. One place to read, and no id can be defined by accident in
  running prose. In the register's own document that first token is therefore
  suppressed as a citation — but every other mention in the file, including the
  `OE-` a row's own prose cross-references, is checked normally.
- **It runs in one direction only: cited → defined.** An id is allocated once
  and never reused, so the register deliberately keeps rows nothing cites any
  more — a retired row is what reserves its number. Checking the reverse
  direction would turn that invariant into a failure.

`test/oe_citations_test.dart` fixes the parse and match rules against fixtures
**and closes the gate**: its last test holds the live corpus at zero violations
over the same roots the command scans by default (`defaultCitingRoots`).

---

## 4. What is generated (per language)

Each target lands at `<output-base>/tom_som_<slug>_<version-label>`. For Dart:

```
tom_som_dart_v0/
├── pubspec.yaml              # depends on tom_som_dart_runtime
├── lib/tom_som_dart_v0.dart  # the typed facade (D00SolutionBlueprint + 3988 classes)
├── meta/spec_model.meta.json # lossless meta-data: every class, member, annotation
├── schemas/                  # 14 DocSpecs schema folders (one per document root)
│   ├── solution-blueprint/ … └── transition-rollout-plan/
├── example/                  # hand-authored samples (a/b/c) — survives regen
└── test/                     # hand-authored generated-tree suite — survives regen
```

Every other language mirrors this shape — the same `meta/`, `schemas/`,
hand-authored samples, and tests — differing only in the facade file and the
language-native manifest that declares the runtime dependency:

| Language | Facade | Manifest | Runtime dependency mechanism |
| --- | --- | --- | --- |
| Dart | `lib/tom_som_dart_v0.dart` | `pubspec.yaml` | path/hosted dep on `tom_som_dart_runtime` |
| Python | `tom_som_python_v0.py` | `pyproject.toml` | dep on `tom_som_python_runtime` |
| Java | `src/…` | `pom.xml` | dep on `tom_som_java_runtime` |
| JavaScript | `index.js` (module) | `package.json` | dep on `tom_som_javascript_runtime` |
| TypeScript | `index.ts` (module) | `package.json` + `tsconfig.json` | `file:` dep on `tom_som_typescript_runtime` |
| Go | package source | `go.mod` | `replace` → `tom_som_go_runtime` |
| Rust | `src/lib.rs` | `Cargo.toml` | path dep on `tom_som_rust_runtime` |
| C | header + source | `Makefile` | `RUNTIME_DIR` → `tom_som_c_runtime` |
| C++ | header + source | `Makefile` | `RUNTIME_DIR` → `tom_som_cpp_runtime` |

- **Meta-data file** (`meta/spec_model.meta.json`) — the resolved model graph
  the generic runtime loads. Lossless per SOM §5.3: it carries `modelVersion`
  (integer major), `modelVersionLabel` (build stamp), `containerRoot`, and for
  every reachable class its name, doc-comment, identity annotations, and for
  every field its type, nullability, list/enum-ness, render classification, and
  **all** annotation arguments.
- **Typed facade** — typed document-editing classes (see this README's §5).
  The
  `D00SolutionBlueprint` root plus every reachable section/form/list/enum class.
- **Schemas** — the DocSpecs schema and the `*.docspecs.yaml` YAML schema, per
  document root.

---

## 5. Consuming the generated code

The same document is reachable three ways. (Dart shown; Python is the literal
mirror — `field.element_type`, `kind.value`, `SpecModel.from_json`, etc.)

### 5a. Typed path — `tom_som_<lang>_v0`

The typed classes are an **editing facade** over the runtime's `SpecDocument`.
They are instantiated **with the memory root** and perform a version check at
construction time (SOM §4.2). Loading/saving is always done through the document,
never through the facade.

```dart
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

final doc = SpecDocument();
final sbp = D00SolutionBlueprint(doc);       // instantiation-time SOM §4.2 check
sbp.content = 'The system vision …';          // typed setter → writes the store
final csa = sbp.currentLandscape;            // nested section navigation
final metrics = csa.operationalMetrics;      // typed SomList: add()/length/[i]/items
metrics.add().content = 'Order turnaround: 4.2 days.';
sbp.objectModelVersion;                      // '0.0' — which _vN surface this is
```

Every typed root exposes `static const String modelVersion` and an
`objectModelVersion` getter returning its own `major.minor` (`'0.0'` for the
`_v0` pre-release surface). The instantiation check compares this against the
document's recorded stamp and throws `SomVersionException` (Dart) /
`SomVersionError` (Python) when an older facade is asked to edit a newer
document.

### 5b. Generic path — `tom_som_<lang>_runtime`

No typed classes required — address sections by string path:

```dart
final doc = SpecDocument();
doc.setContent('SBP/content', 'The system vision …');
// List paths use the field's section-id (the meta-data names it):
final item = doc.addListItem('SBP/currentLandscape/CUOPME-OPER-LST');
doc.setContent('$item/content', 'Order turnaround: 4.2 days.');
doc.content('SBP/content');                  // read back
final yaml = SpecDocumentYaml.encode(document: doc, modelVersion: '0.0');
final json = doc.toJson();
```

Load/save: `SpecDocumentYaml.decode` / `.encode` for `*.docspecs.yaml`, and
`SpecDocumentMarkdown` for the Markdown route (also the self-contained scanner —
no external DocScanner binding required).

### 5c. Reflection path — meta-model introspection

Load the package's own `meta/spec_model.meta.json` and traverse the schema
value-free:

```dart
final meta = File('meta/spec_model.meta.json').readAsStringSync();
final model = SpecModel.fromJson(json.decode(meta));
final reflection = SpecReflection(model);
for (final root in model.roots) { /* 14 roots: type, title, sectionId, doc */ }
reflection.fieldsOf('D00SolutionBlueprint'); // each SpecField: kind, type, …
reflection.resolve('SBP/currentLandscape');  // path → model node
```

This is what lets a consumer modify a document **generically and correctly** —
discover sections, field types, validation, form decomposition, and mapping
targets — without compiling against the typed classes.

---

## 6. Versioning rules (SOM §4.2)

- The generated typed projects carry a **version-label suffix**
  (`tom_som_<slug>_v0`). Projects are generated **per major version** of the
  model; multiple majors (`_v1`, `_v2`, …) can coexist in one codebase.
- The **generic runtime carries no suffix** — one runtime per language, shared
  across majors.
- A document records the **model version it was authored with**; the facade's
  instantiation check enforces:
  - a newer facade **may edit older documents of the same major**, upgrading the
    stamp on edit;
  - an older facade **rejects editing newer documents** of the same major;
  - **different majors are never editable across each other** — cross-major is
    read/convert only.
- **`_vN` trigger.** While a major is pre-release the suffix stays `v0` and the
  typed surface may change freely between regenerations. Backward-compatibility
  observation — and the move to `_v1` — begins when a `release.md` is added to
  the model major. (Quest decisions D3/D10.)

---

## 7. Samples

Each language's runnable samples live in the generated `v0` package (they
survive regeneration) and are tabled in that package's own example README:

| Language | Location | Run |
| --- | --- | --- |
| Dart | [`tom_som_dart_v0/example/`](../tom_som_dart_v0/example/) | `dart run example/<file>.dart` |
| Python | [`tom_som_python_v0/examples/`](../tom_som_python_v0/examples/) | `python3 examples/<file>.py` |
| Java | `tom_som_java_v0/` | see the package's example README |
| JavaScript | `tom_som_javascript_v0/` | `node examples/<file>.js` |
| TypeScript | `tom_som_typescript_v0/` | `tsc && node examples/<file>.js` |
| Go | `tom_som_go_v0/` | `go run ./examples/<file>` |
| Rust | `tom_som_rust_v0/` | `cargo run --example <file>` |
| C | `tom_som_c_v0/` | `make && ./examples/<file>` |
| C++ | `tom_som_cpp_v0/` | `make && ./examples/<file>` |

Each provides the same triplet — `a_typed_access`, `b_generic_document`,
`c_reflection_metadata` (this README's §5) — building the same document shape so
the
three access paths visibly converge across every language.

---

## 8. Status

| Concern | State |
| --- | --- |
| Generator + config | Complete; `dart run bin/generate_som.dart`, idempotent. |
| Dart runtime + `v0` | Complete (reference); 3989 classes, 14 roots. |
| Python runtime + `v0` | Complete (reference port); camelCase accessors preserved. |
| Java / JS / TS / Go / Rust / C / C++ runtime + `v0` | Complete — typed emitter + generic runtime for each; each builds and runs its `v0` project (3989 classes; see [`../tom_specs_model/doc/som_toolchains.md`](../tom_specs_model/doc/som_toolchains.md)). |

The per-language project layout and emitter conventions this table reports on
are specified in
[`som_multiplatform_spec_model.md`](../tom_specs_model/doc/som_multiplatform_spec_model.md)
SOM §6 and SOM §8.

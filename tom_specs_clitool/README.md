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
3079 classes and 13 document roots (see
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

Related entrypoints in `bin/`:

| Entrypoint | Purpose |
| --- | --- |
| `generate_som.dart` | Generate the per-language `tom_som_<slug>_<label>` projects (this section). |
| `model_json.dart` | Export the resolved meta-data class graph (`spec_model.meta.json`) alone. |
| `outliner.dart` | Render a class-tree outline of the model from any document root. |
| `stamp_serialization_order.dart` | Re-stamp `@SerializationOrder(n)` on every model member in source declaration order (SOM §5.2). Run this on `tom_specs_model` after editing the model, before regenerating. |
| `docspecs_schema.dart` / `docspecs_yaml_schema.dart` | Emit the DocSpecs / YAML schemas. |
| `spec_ops.dart` / `summaries.dart` / `build.dart` | Model tooling (spec operations, API summaries, build orchestration). |

**Member serialization order.** `stamp_serialization_order.dart --package
../tom_specs_model` rewrites the model source to pin each member's on-disk
emission order (0-based, per class, source-declaration order). The ordinal flows
through `ModelReader` → `ModelJsonExporter` into the meta-data, so every language
serialises members in the authored order. Re-run it after any model edit that
adds, removes, or reorders fields; it is idempotent (old annotations are stripped
and renumbered).

---

## 4. What is generated (per language)

Each target lands at `<output-base>/tom_som_<slug>_<version-label>`. For Dart:

```
tom_som_dart_v0/
├── pubspec.yaml              # depends on tom_som_dart_runtime
├── lib/tom_som_dart_v0.dart  # the typed facade (D00SolutionBlueprint + 3078 classes)
├── meta/spec_model.meta.json # lossless meta-data: every class, member, annotation
├── schemas/                  # 13 DocSpecs schema folders (one per document root)
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
| Dart runtime + `v0` | Complete (reference); 3079 classes, 13 roots. |
| Python runtime + `v0` | Complete (reference port); camelCase accessors preserved. |
| Java / JS / TS / Go / Rust / C / C++ runtime + `v0` | Complete — typed emitter + generic runtime for each; each builds and runs its `v0` project (3079 classes; see [`../tom_specs_model/doc/som_toolchains.md`](../tom_specs_model/doc/som_toolchains.md)). |

The per-language project layout and emitter conventions this table reports on
are specified in
[`som_multiplatform_spec_model.md`](../tom_specs_model/doc/som_multiplatform_spec_model.md)
SOM §6 and SOM §8.

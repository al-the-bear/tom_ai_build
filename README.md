# tom_ai_build — the TomSpecs release repository

**Start here.** This repository ships release 1 of **TomSpecs**: a structured,
AI-assistable process for creating software systems, carried by a typed
**Specification Object Model (SOM)** that is generated into **nine languages**
(Dart, Python, Java, JavaScript, TypeScript, Go, Rust, C, C++) from a single
Dart source model. With it you can author a specification document (a
*Solution Blueprint* and its detail documents), validate it mechanically, and
run the Phase-4 *CodeSpecs extract* pass that turns a validated specification
into bounded, cited inputs for code generation.

What release 1 contains — and what it deliberately leaves out — is stated in
[RELEASE_NOTES.md](RELEASE_NOTES.md).

## Quickstart: author → validate → extract

The fastest way to see the whole loop is to reproduce the run this repository
already carries: the **Meridian Order Management** sample Solution Blueprint
and the 26 CodeSpecs extracts generated from it, both committed under
[`tom_som_conformance/`](tom_som_conformance/README.md). The commands below
re-run that loop from a clean checkout; because the run is deterministic, your
output reproduces the committed record byte for byte.

You need a **Dart SDK** (3.11 or later). Toolchains for the other eight
languages are only needed for their runtimes — see
[`tom_specs_model/doc/som_toolchains.md`](tom_specs_model/doc/som_toolchains.md).

```bash
git clone https://github.com/al-the-bear/tom_ai_build.git
cd tom_ai_build/tom_som_dart_v0
dart pub get
```

**1. Author a Solution Blueprint** through the typed facade. This builds the
Meridian sample in code and serializes it to both normative renditions —
DocSpecs YAML and markdown:

```bash
dart run tool/build_shared_sample.dart
```

writes `tom_som_conformance/samples/meridian_order_management.docspecs.yaml`
and `.md`. Open either file to see what an authored Solution Blueprint looks
like on disk; open `tool/build_shared_sample.dart` to see the same document
authored through the typed API.

**2. Validate it, then generate the CodeSpecs extracts:**

```bash
dart run tool/build_meridian_extracts.dart
```

This runs the gate tiers in order — DocSpecs **schema completeness**, the
**instance-tier document validator** (`validateDocument`), **routing
totality**, and **DOMEN closed-choice completeness** (every enumeration-kind
attribute's `domainEnum` must resolve to an authored `DMENE` entry) — and only
then runs the `spec_codespecs_extract` surface, writing
one extract pair (`.extract.yaml` of record + rendered `.extract.md`) per
CodeSpecs area to `tom_som_conformance/generated-doc/codespecs_extracts/`
(52 files). Those extracts are the bounded, cited input the Phase-4 authoring
agent works from.

**3. Confirm the reproduction:**

```bash
git diff --stat   # clean = your run reproduced the committed record
```

**Authoring your own document:** start from the committed sample — copy the
YAML and edit it, or copy `tool/build_shared_sample.dart` and author through
the typed facade — then run the same validate-and-extract tool over it. The
markdown and YAML renditions are equivalent and loss-free in both directions.

## The other eight languages

Every language ships a `tom_som_<lang>_runtime` (generic document runtime +
DocSpecs schema validator + instance-tier `validateDocument` + the
`spec_codespecs_extract` surface) and a generated `tom_som_<lang>_v0` typed
facade. So a specification authored in the quickstart above can be **read and
validated in the reader's language of choice**.

Per pair:

- `README.md` — what the package is; `readme_howtointegrate.md` — every
  dependency route and how to pin the version.
- `examples/` — runnable examples, executed by the test suites.
- `run_tests.sh` — builds and runs the package's full suite.

The cross-language proof lives in
[`tom_som_conformance/`](tom_som_conformance/README.md): a shared corpus and
golden logs that all nine runtimes must reproduce byte-identically.
`tool/run_tests.sh` per package, `tom_som_conformance/tool/run_all_suites.sh
--strict` for everything at once.

## Documentation map

All hand-written TomSpecs documentation lives in
[`tom_specs_model/doc/`](tom_specs_model/doc/index.md) — thirteen documents,
each the single authority for its subject, catalogued by `index.md`. In
reading order for a newcomer:

| Document | Read it for |
| --- | --- |
| [tom_specs_project_flow.md](tom_specs_model/doc/tom_specs_project_flow.md) | The process itself — the eight phases from project idea to production, quality gates, roles, iteration rules. |
| [som_multiplatform_spec_model.md](tom_specs_model/doc/som_multiplatform_spec_model.md) | The SOM: the nine-language generation, the runtime/facade split, the normative markdown and YAML serializations, the validator, packaging. |
| [tom_specs_model_rules.md](tom_specs_model/doc/tom_specs_model_rules.md) | How the Dart source model is authored — layout, annotations, structural invariants. |
| [tom_specs_model_meta_schema.md](tom_specs_model/doc/tom_specs_model_meta_schema.md) | The on-disk shape of `spec_model.meta.json`, the class graph every runtime loads. |
| [som_generator_config.md](tom_specs_model/doc/som_generator_config.md) | The generator's config block — languages, output roots, document roots. |
| [som_toolchains.md](tom_specs_model/doc/som_toolchains.md) | Per-language toolchains needed to build and run the generated artefacts. |
| [codespecs_mapping.md](tom_specs_model/doc/codespecs_mapping.md) | CodeSpecs: which specification section feeds which code part — the parts catalogue, attribute surfaces, generation slices. |
| [codespecs_derivation_contract.md](tom_specs_model/doc/codespecs_derivation_contract.md) | CodeSpecs: exactly what code comes out — per-marker derivation, naming rules, validator checks. |
| [codespecs_prompt.md](tom_specs_model/doc/codespecs_prompt.md) | How a Phase-4 run starts, and the quality gate that lets it refuse to. |
| [tom_specs_editor_specification.md](tom_specs_model/doc/tom_specs_editor_specification.md) | The spec-authoring desktop app (not part of release 1). |
| [tom_specs_reviewer_specification.md](tom_specs_model/doc/tom_specs_reviewer_specification.md) | The object-model review app (not part of release 1). |
| [llm_and_d4rt_tools.md](tom_specs_model/doc/llm_and_d4rt_tools.md) | The scripting/agent engine plane (not part of release 1). |
| [llm_guidelines_specification.md](tom_specs_model/doc/llm_guidelines_specification.md) | The in-editor agent's context prompt (not part of release 1). |

## What is in this repository

**Release members** (the record is
[`tom_specs_clitool/tool/release_set.yaml`](tom_specs_clitool/tool/release_set.yaml),
held closed by a shipped dependency-closure gate):

- The **Dart chain**, published on pub.dev: `tom_specs_core`,
  `tom_specs_model`, `tom_specs_clitool`, `tom_som_dart_runtime`,
  `tom_som_dart_v0`, `tom_code_specs`, `tom_doc_scanner`, `tom_doc_specs`
  (plus `tom_core_codespecs`, the one chain member housed outside this
  repository, in the `tom_core` tree).
- The **sixteen non-Dart packages**: the eight `tom_som_<lang>_runtime` /
  `tom_som_<lang>_v0` pairs, shipped source-only in release 1.
- The **conformance harness**: `tom_som_conformance`.

**Also in this tree, but not part of release 1:** `tom_spec_engine`,
`tom_specs_reviewer`, `tom_ai`, `tom_ai_build`, `tom_flow_cli`,
`tom_flow_engine`. See [RELEASE_NOTES.md](RELEASE_NOTES.md) for why.

## License

BSD 3-Clause (see [LICENSE](LICENSE)); every release package also carries its
own copy.

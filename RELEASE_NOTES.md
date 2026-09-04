# TomSpecs — Release 1

**Date:** 2026-09-04 · **Model version:** 1.0.0 · **License:** BSD 3-Clause

Release 1 is the first public cut of TomSpecs: the Specification Object Model
in nine languages, the Dart toolchain that generates and validates it, the
conformance harness that proves the languages agree, and the thirteen
authority documents. Start with [README.md](README.md) for the quickstart.

## What release 1 contains

**The nine-package Dart chain**, versioned in step and **published on
pub.dev** (alternatively consumable from this repository — clone + path or
git dependency — per each package's `readme_howtointegrate.md`):

| Package | Version | What it is |
| --- | --- | --- |
| `tom_specs_core` | 0.1.0 | The annotation vocabulary the source model is written in. |
| `tom_specs_model` | 1.0.0 | The Dart source model — the single source of truth all nine languages are generated from — plus the thirteen authority documents under `doc/`. |
| `tom_specs_clitool` | 0.1.0 | The generator and gate suite: SOM generation, outlines, the model validator, the citation gates, the release-closure gate. |
| `tom_som_dart_runtime` | 1.0.0 | The generic Dart document runtime: path-keyed documents, the meta-model, the DocSpecs schema validator and the instance-tier `validateDocument`, the `spec_codespecs_extract` surface. |
| `tom_som_dart_v0` | 1.0.0 | The generated typed Dart facade over the runtime. |
| `tom_code_specs` | 0.12.0 | The CodeSpecs annotation framework (`Cs*` markers, cross-part references, back-trace annotations). |
| `tom_core_codespecs` | 0.11.2 | CodeSpecs-only gap classes for the `tom_core` family (the one chain member housed outside this repository, in the `tom_core` tree). |
| `tom_doc_scanner` | 0.1.0 | The markdown structure parser the DocSpecs tooling reads with. |
| `tom_doc_specs` | 0.1.0 | The DocSpecs schema assets and validator. |

**The sixteen non-Dart packages** — `tom_som_<lang>_runtime` +
`tom_som_<lang>_v0` for Python, Java, JavaScript, TypeScript, Go, Rust, C and
C++ — shipped **source-only** in this release: each builds and passes its full
suite from a clean checkout (`run_tests.sh`), each carries `README.md`,
`readme_howtointegrate.md`, `examples/` and its own LICENSE, but none is
published to a language registry yet. Two packaging caveats follow from that
and are documented in
[`tom_specs_model/doc/som_toolchains.md`](tom_specs_model/doc/som_toolchains.md):
the Java facade's `mvn package` needs `mvn install` run in the Java runtime
first, and the Rust facade's `cargo package` is runnable only once the Rust
runtime is on crates.io — until then its pack verification is its build and
test suite.

**The conformance harness** `tom_som_conformance`: the shared corpus, the
golden logs all nine runtimes reproduce byte-identically
(`tool/run_all_suites.sh --strict`, `tool/regenerate_golden.sh`), and the
committed worked example — the Meridian Order Management Solution Blueprint
and the 26 CodeSpecs extracts generated from it.

**The thirteen authority documents** under
[`tom_specs_model/doc/`](tom_specs_model/doc/index.md), each the single
authority for its subject.

The authoritative record of the release scope is
[`tom_specs_clitool/tool/release_set.yaml`](tom_specs_clitool/tool/release_set.yaml);
a shipped dependency-closure gate walks the real dependency tree against it in
the default test run, so the boundary cannot drift silently.

## What release 1 deliberately excludes

- **`tom_specs_editor`** — the Forge desktop app for authoring specifications.
- **`tom_spec_engine`** — the scripting/agent engine plane behind the editor's
  D4rt scripting and LLM tooling.
- **`tom_specs_reviewer`** — the object-model review app.

Excluding the engine also removes everything that hangs off it: the Tom
Assistant, Tom Brain memory, and D4rt interpreter integrations. None of these
is needed to author, validate, or extract from a specification — the released
runtimes and the Dart toolchain carry that whole loop. The excluded plane is
enforced, not just declared: the release-closure gate refuses any dependency
edge from a release member into it.

Also in this repository but outside the release: `tom_ai`, `tom_ai_build`,
`tom_flow_cli`, `tom_flow_engine` (workspace tooling that happens to share the
tree).

## The cross-language parity claim

The nine runtimes' agreement is proven by the conformance harness, and the
proof extends exactly as far as the corpus reaches — the canonical statement
of that bound is the **"The parity claim's bound"** subsection of
[`tom_som_conformance/README.md`](tom_som_conformance/README.md), which this
release cites rather than restates.

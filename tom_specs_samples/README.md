# TomSpecs samples

Runnable **sample projects** — each a self-contained directory you can copy,
run, and read end to end. A sample walks a *task*: authoring a specification,
running a Phase-4 CodeSpecs pass, reading a document generically. It is not an
API tour.

> **Not a replacement for a package's `example/`.** A package's `example/`
> demonstrates *that package*; a sample demonstrates *TomSpecs*, which spans
> several. Both exist, and neither is the other's index
> (`tom_specs_documentation_standard.md` §7).

## The samples

*The set is being filled in; this table is the index and gains a row per
sample.* Read top to bottom — the ordering is a learning path, not an
alphabet.

| # | Sample | Teaches | Phase | Language | Run |
|---|--------|---------|-------|----------|-----|
| 1 | [`author_solution_blueprint`](author_solution_blueprint/README.md) | Author a specification end to end: write through the typed facade, serialise both renditions, round-trip, validate, and read a real diagnostic | 2 — Solution Blueprint | Dart, [Python](author_solution_blueprint/python/README.md), [JavaScript](author_solution_blueprint/javascript/README.md), [TypeScript](author_solution_blueprint/typescript/README.md), [Go](author_solution_blueprint/go/README.md), [Rust](author_solution_blueprint/rust/README.md), [Java](author_solution_blueprint/java/README.md), [C](author_solution_blueprint/c/README.md), [C++](author_solution_blueprint/cpp/README.md) | `cd author_solution_blueprint && dart pub get && dart run` |
| 2 | [`phase4_codespecs_run`](phase4_codespecs_run/README.md) | Run Phase 4 end to end: the starting prompt's quality gate (passing and rejecting), the extract generator, the authoring agent, and validation of the emitted trio — with every step marked mechanical or judgment | 4 — CodeSpecs | Dart, [Python](phase4_codespecs_run/python/README.md), [JavaScript](phase4_codespecs_run/javascript/README.md), [TypeScript](phase4_codespecs_run/typescript/README.md), [Go](phase4_codespecs_run/go/README.md), [Rust](phase4_codespecs_run/rust/README.md), [Java](phase4_codespecs_run/java/README.md) (stages 1–2) | `cd phase4_codespecs_run && dart pub get && dart run` |
| 3 | [`build_a_specification_tool`](build_a_specification_tool/README.md) | Build tooling *on* TomSpecs: reflective access to the model, generic access to a document, the generated schema, the three validation tiers and which two are reachable at runtime, and a completeness report built on all of it | any — tooling | Dart, [Python](build_a_specification_tool/python/README.md), [JavaScript](build_a_specification_tool/javascript/README.md), [TypeScript](build_a_specification_tool/typescript/README.md), [Go](build_a_specification_tool/go/README.md), [Rust](build_a_specification_tool/rust/README.md), [Java](build_a_specification_tool/java/README.md), [C](build_a_specification_tool/c/README.md), [C++](build_a_specification_tool/cpp/README.md) | `cd build_a_specification_tool && dart pub get && dart run` |
| 4 | [`full_lifecycle_walkthrough`](full_lifecycle_walkthrough/README.md) | **Start here to understand TomSpecs.** One small project from idea to code — the free-form idea, the Blueprint, two detailed specifications, the CodeSpecs trio, the derived tests and the implementation — with all six quality gates actually run, and a failing gate stopping the walk | 1–6 — the process | Dart only | `cd full_lifecycle_walkthrough && dart pub get && dart run` |

**Read sample 4 first if you want to understand TomSpecs at all** — it is the
only one that shows the methodology rather than an API, and it needs nothing
before it. Samples 1–3 are then the depth behind three of its phases: 1 is the
entry point for authoring, 2 expands its Phase 4, and 3 is for a different
reader again — someone writing programs that read specifications rather than
writing them.

Each row's **Phase** is a `tom_specs_project_flow.md` phase, so a reader
looking for "how do I do Phase 4" can find the sample that shows it rather
than inferring it from a package name.

## Running them

```bash
./tool/run_all_samples.sh                           # every sample and port
./tool/run_all_samples.sh author_solution_blueprint # one, by directory name
./tool/run_all_samples.sh author_solution_blueprint/python  # one port
./tool/run_all_samples.sh --strict   # a missing toolchain is a failure
```

The driver runs each sample and compares what it prints against the
`expected_output.txt` beside it. It does not stop at the first failure — one
invocation reports the whole picture — and a skipped sample is never silent.
It is the shape of `tom_som_conformance/tool/run_all_suites.sh`, and for the
same reasons, which that script's header states.

## The convention

`tom_specs_documentation_standard.md` §7 is the authority; this is the
operational summary of it.

**One directory per sample**, named for the *task* in `snake_case` —
`author_solution_blueprint`, not `sample_01` or `dart_typed_access`. The name
is what appears in the index and on the driver's command line, so it should
read as the thing being taught.

**Published dependencies only.** No `pubspec_overrides.yaml`, no `path:`
dependencies. A sample that resolves against the workspace copy proves nothing
about what a user gets from pub.dev — and proving exactly that is the point of
being a sample. This is the same discipline the release-closure gate applies to
the shipped set (`tom_specs_clitool/tool/release_set.yaml`), turned outward.

**Samples are not members of the release set**, and deliberately. The release
set is the dependency-closed unit that ships; a sample is a *consumer* of that
unit, resolving from the published packages rather than from the workspace. Put
another way: adding one would make every edge in it an approved crossing, which
would say nothing and weaken the walk. A sample is verified by
`tool/run_all_samples.sh` instead.

**Each sample carries** a `README.md` (what it teaches, prerequisites, the run
command, and what you should see), the runnable source, and an
`expected_output.txt` the driver compares against. The expected output is what
makes a sample a test rather than a demo — a sample nobody would notice
breaking is documentation that will quietly stop being true.

**A sample whose output records a workspace tool's result also carries a
`tool/validate.sh`.** The output diff proves the sample still *prints* its
record; it says nothing about whether the record is still *true*. A workspace
tool can never be a sample's dependency — shelling out to one would make the
sample's stdout depend on whether the workspace happens to sit beside it — so
the tool's output is a committed artifact and `tool/validate.sh` re-derives it
and fails when it has gone stale. `--record` overwrites it after a deliberate
change; `run_all_samples.sh` runs it for any sample that has one.

**A sample authors its own specification, and keeps it minimal.** The shared
documents in `tom_som_conformance/samples/` would be the better source and are
gated by the decode and instantiation-coverage checks — but `tom_som_conformance`
is **not published**, so depending on it would break the published-only rule
above. Until that is resolved, write the smallest document that shows the point:
small enough that every number the sample prints can be checked against the code
that produced it. Say so in the sample's README.

**Per language, mirroring the runtimes.** The Dart set is authored first and is
the reference; each other language plane gets the same scenarios, so a Go
reader and a Dart reader learn the same TomSpecs from equivalent code
(`tom_specs_documentation_standard.md` §7).

## Per language

A sample's port to another language sits **beside its Dart source, one folder
per language**: `<sample>/python/`, `<sample>/javascript/`, `<sample>/go/`, and
so on. Each port folder has its own `README.md` (which the driver discovers it
by), its entry point (`main.py`, `index.js`, `src/index.ts` with a
`tsconfig.json`, `go.mod`, `Cargo.toml`, `pom.xml`, a `Makefile` for C and C++, …) and, when its output
differs from the Dart sample's, its own `expected_output.txt` with the reason
in its README. A port without one is compared against the Dart sample's
`expected_output.txt`: it must print the same text. The driver runs a port as
the sample `<sample>/<language>`.

**The non-Dart runtimes are not published to registries** (decided
2026-11-18), so a port cannot take published dependencies: it runs on the
checkout's packages, through a source install its README gives (Python:
`pip install -e` of the runtime and the facade, or `PYTHONPATH`; JavaScript:
`file:` dependencies and `npm install`; TypeScript: the same, then
`npm run build`, which builds both packages — their `dist/` is not committed —
and compiles the port with `tsc`; Go: `replace` directives onto the checkout's
modules and `go run`; Rust: `path` dependencies on the checkout's crates and
`cargo run`; Java: `mvn install` of the checkout's runtime and facade into the
local Maven repository, then `mvn compile exec:java`; C and C++: a vendored-source build — the sample
compiles the checkout's runtime and facade sources itself, which is the
intended integration path, since those planes ship as source only). That is
the
one exception to "published dependencies only" above, and it holds until those
runtimes are published.

A port covers what its runtime covers. `phase4_codespecs_run` is ported as far
as the gate and the extract generator, which every runtime has; the IR, its
mapping and its validation are Dart tools, and the port says so where they
would be. `full_lifecycle_walkthrough` stays Dart-only. The C and C++ ports
cover `author_solution_blueprint` and `build_a_specification_tool`; their
Phase-4 port is not written yet.

| Sample | Python | JavaScript | TypeScript | Go | Rust | Java | C | C++ |
|--------|--------|------------|------------|----|------|------|---|-----|
| `author_solution_blueprint` | [`python/`](author_solution_blueprint/python/README.md) — the Dart output | [`javascript/`](author_solution_blueprint/javascript/README.md) — the Dart output | [`typescript/`](author_solution_blueprint/typescript/README.md) — the Dart output; a mis-typed section fails to compile (`tool/validate.sh`) | [`go/`](author_solution_blueprint/go/README.md) — the Dart output | [`rust/`](author_solution_blueprint/rust/README.md) — the Dart output | [`java/`](author_solution_blueprint/java/README.md) — the Dart output | [`c/`](author_solution_blueprint/c/README.md) — the Dart output; leak-checked | [`cpp/`](author_solution_blueprint/cpp/README.md) — the Dart output; leak-checked |
| `phase4_codespecs_run` | [`python/`](phase4_codespecs_run/python/README.md) — stages 1–2 | [`javascript/`](phase4_codespecs_run/javascript/README.md) — stages 1–2 | [`typescript/`](phase4_codespecs_run/typescript/README.md) — stages 1–2 | [`go/`](phase4_codespecs_run/go/README.md) — stages 1–2 | [`rust/`](phase4_codespecs_run/rust/README.md) — stages 1–2 | [`java/`](phase4_codespecs_run/java/README.md) — stages 1–2 | — | — |
| `build_a_specification_tool` | [`python/`](build_a_specification_tool/python/README.md) — own output (Dart-only names) | [`javascript/`](build_a_specification_tool/javascript/README.md) — own output (Dart-only names) | [`typescript/`](build_a_specification_tool/typescript/README.md) — own output (Dart-only names) | [`go/`](build_a_specification_tool/go/README.md) — own output (Dart-only and Go names) | [`rust/`](build_a_specification_tool/rust/README.md) — own output (Dart-only and Rust names) | [`java/`](build_a_specification_tool/java/README.md) — own output (Dart-only and Java names) | [`c/`](build_a_specification_tool/c/README.md) — own output (Dart-only and C names); leak-checked | [`cpp/`](build_a_specification_tool/cpp/README.md) — own output (Dart-only and C++ names); leak-checked |
| `full_lifecycle_walkthrough` | — | — | — | — | — | — | — | — |

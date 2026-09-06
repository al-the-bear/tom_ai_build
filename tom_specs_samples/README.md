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
| 1 | [`author_solution_blueprint`](author_solution_blueprint/README.md) | Author a specification end to end: write through the typed facade, serialise both renditions, round-trip, validate, and read a real diagnostic | 2 — Solution Blueprint | Dart | `cd author_solution_blueprint && dart pub get && dart run` |
| 2 | [`phase4_codespecs_run`](phase4_codespecs_run/README.md) | Run Phase 4 end to end: the starting prompt's quality gate (passing and rejecting), the extract generator, the authoring agent, and validation of the emitted trio — with every step marked mechanical or judgment | 4 — CodeSpecs | Dart | `cd phase4_codespecs_run && dart pub get && dart run` |

Sample 1 is the entry point; the others assume you have run it.

Each row's **Phase** is a `tom_specs_project_flow.md` phase, so a reader
looking for "how do I do Phase 4" can find the sample that shows it rather
than inferring it from a package name.

## Running them

```bash
./tool/run_all_samples.sh            # every sample
./tool/run_all_samples.sh sbp_author # one, by directory name
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

# Sample — a complete Phase 4 CodeSpecs run

Runs TomSpecs **Phase 4** end to end against a small specification the sample
authors for itself: the starting prompt's quality gate, the extract generator,
the authoring agent, and validation of the emitted shared / client / server
trio.

```bash
dart pub get
dart run
```

Everything the sample needs comes from published packages
(`tom_som_dart_v0`, `tom_som_dart_runtime`, `tom_specs_model`). The recorded
output is `expected_output.txt`; `../tool/run_all_samples.sh` diffs the two, so
this sample is a gate and not a demo.

## What Phase 4 is

Phase 4 turns a specification into a **compiling code skeleton** — code that
analyzes clean and does not execute. Phase 6 fills the skeleton in.

It runs in **two passes**, and the boundary between them is the single thing
readers get wrong. So every step the sample prints is marked:

| Stage | | What runs |
|-------|--|-----------|
| 1 | **[MECHANICAL]** | The starting prompt's quality gate (`codespecs_prompt.md` §4) |
| 2 | **[MECHANICAL]** | The extract generator — one bounded, cited extract per area |
| 3 | **[JUDGMENT]** | The authoring agent — one prompt pass per area, writing the Dart |
| 4 | **[MECHANICAL]** | `validate_codespecs.dart` over the emitted trio |

**Stages 1, 2 and 4 are programs.** Given the same document they produce the
same answer every time, and none of them writes a line of Dart.

**Stage 3 is a prompt pass.** The extract generator may copy and index; it may
not summarise, rephrase, compose a sentence from field values, or choose a name.
Every judgment that natural-language input requires is therefore the agent's,
which is why Phase 4 is neither a compiler pass nor free authoring
(`codespecs_mapping.md` §1.1.1).

The distinction is checkable rather than aspirational: every scalar in every
extract must occur character-for-character in the source document, and checks 32
to 34 hold every emitted doc comment against the extract it came from — which is
why stage 4 is run twice below.

## What the sample shows, stage by stage

**Stage 1** runs A1 (the document's Markdown against its generated DocSpecs
schema — *completeness*) and A2 (`validateDocument` over the document's own
values — the *instance tier*), then A3 (routing totality, which is the strict
extraction walk itself). It runs them for two documents:

* **Variant A** passes all three, so the run may begin.
* **Variant B** is the same document with `DAENT-CLAS.aggregateRoot` cleared on
  both entities. A1 reports two `missingRequiredField` violations and **A2 does
  not move** — clearing a required field removes a value, and a validator that
  checks values has nothing left to object to. That is why the gate is two
  checks and not one (`codespecs_prompt.md` §4.1/§4.2, and the fixture in
  `codespecs_prompt.md` §10.2 that measures the same effect on a full-size
  document).

A4 and A5 are not run here, and the sample says so rather than passing over
them: they read the per-marker required-argument table, which the generator owns
and the SOM runtimes do not ship.

**Stage 2** walks the 27-area catalogue and writes 54 files to
`build/codespecs_extracts/` — a `.yaml` of record and a rendered `.md` view per
area. Three areas are populated; 24 are empty, because the document says nothing
about screens, jobs, reports or migrations. **An empty extract is a candidate for
"not applicable", never the verdict** — the verdict is stage B of the gate, and
stage B is judgment.

**Stage 3** prints one area's extract and the file the agent wrote from it, in
full, and then names which parts of that file were fixed for the agent and which
it chose. It also shows the mirror-image case: CE-API's extract is **not** empty
and still yields no code, because its shared wire DTO is derived from server
operations this document never specifies. Emptiness and non-emptiness are both
inputs to a verdict, not verdicts.

**Stage 4** shows `validate_codespecs.dart` run over the trio twice — once
without `--extracts` and once with it. Four questions cannot be answered from
emitted code alone, and each brings its own corroborating input; when one is
absent the tool **names on stdout the checks it left unrun**, so a skipped check
never reads as a passed one. Supplying the extracts moves six checks from "not
run" to "ran".

## Why stage 4 is a recorded report

`tom_specs_clitool` is a **development tool**, not a dependency of the emitted
code — so it is deliberately absent from this sample's `pubspec.yaml`. Shelling
out to it from the sample would make the sample's own stdout depend on whether
the workspace happens to sit beside it, and `run_all_samples.sh` diffs that
stdout.

So stage 4's output is recorded in `codespec/validation_report.txt`, and
`tool/validate.sh` is what keeps the record honest: it re-runs both invocations
and fails if the file has gone stale. Like `run_all_samples.sh`, it **skips with
the reason stated** when the toolchain is absent, and `--strict` turns a skip
into a failure.

```bash
./tool/validate.sh            # compare against the recorded report
./tool/validate.sh --record   # overwrite it after a deliberate change
```

## Why the sample authors its own specification

The Phase-4 fixtures in the TomSpecs documents are measured against the
`meridian_order_management` Solution Blueprint. That document is **not reachable
from published packages**: it lives in `tom_som_conformance`, which is not
published, and the shipped `tom_som_dart_v0/tool/` scripts that build and consume
it resolve their paths into that same unpublished package. A sample that depends
only on hosted versions therefore cannot load it.

So this sample writes its own: two entities and three stored attributes, which
is the smallest document that populates an area, leaves most areas empty, and
still produces a trio a validator will accept. Being small is the point — the
whole run fits on two screens, and every number the sample prints can be checked
against the code that produced it.

## Files

| Path | |
|------|--|
| `bin/phase4_codespecs_run.dart` | The run: the specification, the four stages |
| `tool/validate.sh` | Records and re-checks stage 4 |
| `codespec/` | The emitted trio — Phase 4's output, with its own README |
| `codespec/validation_report.txt` | Stage 4's recorded output |
| `expected_output.txt` | What `dart run` prints; the samples driver diffs it |
| `build/codespecs_extracts/` | Stage 2's output (gitignored — regenerate by running) |

## Reading on

| Document | For |
|----------|-----|
| `tom_specs_model/doc/codespecs_prompt.md` | The gate stage 1 runs, and when a run may begin |
| `tom_specs_model/doc/codespecs_mapping.md` | Which SOM section feeds which part; the areas, slices and projects |
| `tom_specs_model/doc/codespecs_derivation_contract.md` | What code comes out, and the 37 checks stage 4 runs |
| `tom_specs_model/doc/tom_specs_project_flow.md` | Phase 4's place in the process, and gate G4 |

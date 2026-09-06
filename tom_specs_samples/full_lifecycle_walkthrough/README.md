# Sample — the full lifecycle, idea to code

One small project carried through the TomSpecs phases **in order**, with every
quality gate actually run. Everything else in this folder teaches a tool; this
teaches the **process**, and it is the sample that answers *"why would I use
TomSpecs at all?"*

```bash
dart pub get
dart run
```

The project is a room-booking service for a single office: six meeting rooms,
two entities, one business rule that matters. Small on purpose — every artifact
from idea to code fits in one reading.

> `tom_specs_project_flow.md` is the single process authority. Every phase and
> gate below is its, cited by id (`PF-PHA-P2`, `PF-GAT-G2`). This sample **runs**
> them; it does not restate them.

## The walk

| Phase | Artifact | Where | Gate |
|-------|----------|-------|------|
| 1 Project Idea | free-form document | `spec/01_project_idea.md` | **G1** idea captured |
| 2 Solution Blueprint | one schema-bound DocSpecs document | `build/` (generated) | **G2** blueprint complete — *business* |
| 3 Detailed Specifications | `IFM` + `RSP` at specification depth | `build/` (generated) | **G3** specifications complete — *business* |
| 4 CodeSpecs | the shared / client / server trio | `codespec/` | **G4** skeleton complete — *engineering* |
| 5 Test Derivation | 12 tests, all RED, plus a baseline | `test/`, `spec/05_phase5_baseline.txt` | **G5** suite derived |
| 6 Implementation | the one business rule | `lib/booking_rules.dart` | **G6** implementation complete |

Phases 7 (Application Candidate) and 8 (Release Candidate) are deployment,
test-environment execution and business sign-off. They have no artifact a sample
can carry, and G7 requires a human signature by definition — so the walkthrough
stops at G6 and says so rather than simulating them.

**A failing gate stops the run.** `PF-FLW-OVE`'s *"every gate can fail"* only
means something if failing one halts the work, so `_gate` exits non-zero. That
is not decoration: G3 failed on the first attempt here, because the Information
Model's schema requires a business-object catalogue and a business-rule list
that the first draft did not write.

## What each phase actually does

**Phase 1** records the idea *including its contradictions* — who may add a
room, who may cancel a booking — because filtering is the Blueprint's job, not
the idea's (`PF-PHA-P1`). Both are carried into Phase 2 as clarifications, and
Phase 2 records the answers rather than the questions.

**Phase 2** produces one document covering the whole system at overview depth.
G2 is the heaviest business gate in the process, and `PF-GAT-G2` says why:
twelve documents are derived from this one, so every defect that survives it is
multiplied by the Phase-3 expansion.

**Phase 3** is *not* "write twelve documents from scratch". It is "expand each
mapped SBP region to specification depth" (`PF-FLW-SBP`), and the mapping is not
editorial — it is `@MapsTo` and `@DetailedIn` on the model classes, enforced
structurally by the model validator. The run **reads the mapping off the model**
rather than asserting it, so a model change moves that output.

G3's cross-document consistency check is likewise real: the entity names the
Blueprint wrote are compared against the ones the Information Model expanded.

**Phase 4** emits a skeleton that compiles but does not execute.
`phase4_codespecs_run` beside this sample walks the two-pass production model in
full; this one carries the output and measures **the property the methodology
stakes itself on** — see below.

**Phase 5** derives the tests **before** any implementation exists. Twelve tests
from one requirement, in three groups, because `PF-PHA-P5` derives boundary
tests and error paths as separate activities rather than as an afterthought to
the happy case:

- **the rule** — overlapping, enclosing, enclosed, and that the refusal names
  *which* booking clashed
- **boundaries** — touching intervals do **not** conflict. 10:00–11:00 beside
  11:00–12:00 is two bookings, not a clash. *Only the specification says so; the
  CodeSpecs surface cannot* — which is exactly why `PF-PHA-P5` requires both
  inputs and says neither alone is sufficient.
- **error paths** — a zero-length or inverted interval is *rejected*, not
  reported conflict-free

`spec/05_phase5_baseline.txt` is a **real recorded run**, not a claim: the
implementation was stripped back to the bodies Phase 4 emits — form 3a,
`throw UnsupportedError(<the specification's own words>)` — and `dart test` was
run. Result: `+0 -12`.

**Phase 6** implements until the tests pass. What Phase 6 actually writes is
small, and that is the methodology's claim rather than an accident of this
example: the framework owns authentication, authorization, transport,
serialization, persistence and input handling, and Phase 4 emitted the entities
and the service units. What is left for a person to write is a rule about
intervals — which is why `lib/booking_rules.dart` has **no framework dependency
at all** and runs under plain `dart test`. It is also why `PF-GAT-G6` calls its
security criterion tractable.

## Self-sufficiency — the promise, and how it is checked

After Phase 4 the trio carries every fact its parts were routed from, so Phases
5 and 6 read **code** rather than reopening the Phase-3 documents
(`codespecs_mapping.md` §9.6). That is the methodology's main promise to a
reader, and nobody has to take it on trust — two checks decide it mechanically,
in both directions:

- **check 35** — every token the extracts hold a value for is cited by a
  back-link in the trio. An uncited token is a specification fact that reached
  no code.
- **check 36** — every token a back-link names exists in the extracts. A trace
  to a token no area routed is stale or invented.

Both need the extracts, so both run only when `validate_codespecs` is given
`--extracts`. `tool/validate.sh` therefore runs the validator **twice**, and the
difference between the two recorded invocations is the demonstration: without
the extracts those checks announce themselves unrun; with them, they run and
pass.

## The traceability chain

`PF-GAT-G6` checks it as unbroken, and here it is, end to end:

| Link | Artifact |
|------|----------|
| Requirement | `FR-001` — a booking must not overlap another booking of the same room |
| Idea | `spec/01_project_idea.md` — "The problem" |
| Blueprint | `SBP.9`, at overview depth |
| Specification | `RSP` `FRE-REQU-…`, with the half-open rule stated; `IFM` `BIRU-BUSI-…` states it in data terms |
| CodeSpec | `codespec/server/lib/src/services/booking_service.dart` |
| Test | `test/booking_rules_test.dart` (Phase 5) |
| Code | `lib/booking_rules.dart` (Phase 6) |

The chain is written into the implementation's own doc comment, so it travels
with the code rather than living in a document that can drift from it.

## The two recorded reports

Two things this sample prints, it cannot produce itself: `validate_codespecs`
needs `tom_specs_clitool`, a **development tool** rather than a dependency of
the emitted code, and shelling out to `dart test` would make the sample's stdout
depend on the host's test runner — which `../tool/run_all_samples.sh` diffs.

So both are recorded — `codespec/validation_report.txt` and
`spec/06_implementation_report.txt` — and `tool/validate.sh` keeps the records
honest by re-deriving them and failing when either has gone stale.

```bash
./tool/validate.sh            # compare against the recorded reports
./tool/validate.sh --record   # overwrite them after a deliberate change
```

Under `--record` the walkthrough's own exit status is ignored, and that is
deliberate: gate G4 reads the very report the invocation is about to write, so a
first record legitimately fails at G4 while still producing the extracts G4
needs. When *comparing*, the records exist and the run must succeed.

## Why the specification is authored in code

The shared specification documents live in `tom_som_conformance`, which is not
published, so a hosted-dependencies-only sample cannot reach them
(`tsdocb14_aiga-shipped-tool-scripts-resolve-into-an-unpublished-package`). This
walkthrough writes its own through the typed facade, which has a second benefit:
the entities are written by **one function** used by both the Blueprint and the
Information Model. Writing them twice by hand is precisely how terminology drift
gets in, and a sample demonstrating a consistency check against two hand-kept
copies would be demonstrating luck.

## Files

| Path | |
|------|--|
| `bin/full_lifecycle_walkthrough.dart` | The run: the specifications, the six gates |
| `spec/01_project_idea.md` | Phase 1 |
| `spec/05_phase5_baseline.txt` | The recorded RED baseline |
| `spec/06_implementation_report.txt` | Phase 6's recorded test / analyze / format run |
| `codespec/` | Phase 4's trio, with its own README |
| `lib/`, `test/` | Phase 6 and Phase 5 |
| `tool/validate.sh` | Records and re-checks the two external reports |
| `expected_output.txt` | What `dart run` prints; the samples driver diffs it |

## Reading on

| Document | For |
|----------|-----|
| `tom_specs_model/doc/tom_specs_project_flow.md` | The process authority: phases, gates, iteration, roles, tooling |
| `tom_specs_model/doc/codespecs_prompt.md` | Phase 4's starting prompt and its gate |
| `tom_specs_model/doc/codespecs_mapping.md` | Which specification section feeds which CodeSpecs part |
| `tom_specs_model/doc/codespecs_derivation_contract.md` | What code Phase 4 emits, and the 37 checks G4 runs |

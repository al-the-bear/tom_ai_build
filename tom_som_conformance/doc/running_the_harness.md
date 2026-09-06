# TomSpecs Conformance — Running the Harness

This package is a corpus and a set of drivers, not a library. This guide is the
operator's view: what to run, in what order, and — the part that matters when
something goes wrong — how to read a failure. What the corpus *proves*, and how
far the parity claim reaches, is
[`som_multiplatform_spec_model.md`](../../tom_specs_model/doc/som_multiplatform_spec_model.md)
§19; the per-language toolchains are
[`som_toolchains.md`](../../tom_specs_model/doc/som_toolchains.md). Both are
cited here, never restated.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
  - [The four drivers](#the-four-drivers)
  - [The corpus](#the-corpus)
- [Reading a golden mismatch](#reading-a-golden-mismatch)
- [Reading a suite failure](#reading-a-suite-failure)
- [Skips are not passes](#skips-are-not-passes)
- [Proving a corpus table is load-bearing](#proving-a-corpus-table-is-load-bearing)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

Two different claims, proved by two different drivers:

| Claim | Driver | Shape of the proof |
|-------|--------|--------------------|
| All nine languages *read* the same specification identically | `regenerate_golden.sh` → `compare_golden.dart` | Nine logs, byte-identical |
| Every hand-authored suite in all eighteen SOM packages passes | `run_all_suites.sh` | A PASS/FAIL/SKIP table over twenty results |

The distinction is worth holding on to. A green golden run says the nine *APIs
agree*; it says nothing about whether each port's own tests pass. A green suite
run says each port is internally correct; it says nothing about whether they
agree with each other. Both are needed, and neither substitutes.

Everything here runs from the package root. The drivers `cd` to the workspace
themselves, so they can be invoked from anywhere.

## Quick Start

```bash
# 1. Every hand-authored suite, plus the two sample gates (20 results).
./tool/run_all_suites.sh

# 2. The nine-way byte-identity proof. Needs all nine toolchains.
./tool/regenerate_golden.sh

# 3. If the logs already exist, just re-run the comparison.
dart run tool/compare_golden.dart
```

A clean comparison looks like this — eight lines, because `dart.log` is the
reference and is not compared with itself:

```
OK       python.log  (165553 bytes) == dart.log
OK       java.log  (165553 bytes) == dart.log
OK       javascript.log  (165553 bytes) == dart.log
OK       typescript.log  (165553 bytes) == dart.log
OK       go.log  (165553 bytes) == dart.log
OK       rust.log  (165553 bytes) == dart.log
OK       c.log  (165553 bytes) == dart.log
OK       cpp.log  (165553 bytes) == dart.log

PASSED: all 8 language logs are byte-identical to dart.log.
```

Exit `0`. A mismatch exits `1`.

## Core Components

### The four drivers

| Driver | Runs | Exit |
|--------|------|------|
| `tool/run_all_suites.sh` | The eighteen suites plus the two sample gates | Non-zero on any failure |
| `tool/regenerate_golden.sh` | Every `tom_som_<lang>_v0` golden generator, then the comparison | Non-zero on any mismatch |
| `tool/compare_golden.dart` | The comparison alone, over existing logs | `0` identical, `1` on a mismatch |
| `tool/check_sample_coverage.dart` | The instantiation-coverage gate over the shared samples | `0` when the manifest is exactly the remaining set |
| `tool/parity_gate.sh` | A controlled mutation proving a corpus table is read | Non-zero if any named suite stays green |

`run_all_suites.sh` takes suite names — the package name without the
`tom_som_` prefix — so a targeted run is cheap:

```bash
./tool/run_all_suites.sh                    # everything
./tool/run_all_suites.sh --strict           # a skipped suite is a failure
./tool/run_all_suites.sh rust_v0 c_runtime  # just these two
./tool/run_all_suites.sh --log-dir <dir>    # place the per-suite logs
```

A targeted run of two suites reports exactly them:

```
== dart_runtime ==
== dart_v0 ==

== suite summary ==
  PASS dart_runtime
  PASS dart_v0
  logs: <workspace>/ztmp/som_suites_<timestamp>

All 2 suites passed.
```

Per-suite output goes to one log file each — a timestamped folder under the
workspace `ztmp/` by default — so the summary table stays readable and the
detail is one file away.

### The corpus

`corpus/` holds the language-agnostic expectation tables every port replays: the
document cases, the schema, the reflection, validation, query, cursor,
node-creation, editability, operations, pattern, projection, section-id,
serialization-order and CodeSpecs-extract tables, plus the two expected
renderings (`expected.md`, `expected.docspecs.yaml`) and the shared
`model.meta.json`.

`samples/` holds the shared documents the golden generators read, and `golden/`
holds the nine per-language logs they write. **`golden/` is generated output** —
it is not committed, and regenerating it is how it comes back.

`check_sample_coverage.dart` is the gate that keeps the samples honest:

```
samples: exercise_full_model.docspecs.yaml, meridian_order_management.docspecs.yaml, uam_access_hub.docspecs.yaml
list structures instantiated: 569/569 (0 remaining)
section ids instantiated:     3854/3854 (0 remaining)
OK — the manifest is exactly the remaining set.
```

Every list structure and every section id the model declares is instantiated by
at least one sample. A model that grows without the samples growing fails here,
which is what stops the golden proof from quietly narrowing.

## Reading a golden mismatch

This is the failure the harness exists to produce, so it is worth knowing what
it looks like. Flipping one character in `go.log` gives:

```
OK       java.log  (165553 bytes) == dart.log
OK       javascript.log  (165553 bytes) == dart.log
OK       typescript.log  (165553 bytes) == dart.log
MISMATCH go.log differs from dart.log (165553 vs 165553 bytes)
  first diff at line 6:
    dart : C	SBP/assumptionsConstraintsDependencies/content	- **Assumption** …
    go   : C	SBP/assumptionsConstraintsDependencies/content	- **Assumption** …
OK       rust.log  (165553 bytes) == dart.log
OK       c.log  (165553 bytes) == dart.log
OK       cpp.log  (165553 bytes) == dart.log

FAILED: 1 language log(s) differ from the Dart reference.
```

Exit `1`. Four things to read off it:

1. **Which language.** Only `go` differs; the other seven agree with the
   reference, so the defect is in the Go port, not in the sample or the model.
2. **The byte counts.** Equal here (`165553 vs 165553`), which says the
   divergence is a *value* difference rather than a missing or extra section. A
   size difference points at structure instead.
3. **The line number and the section path.** `line 6` and
   `SBP/assumptionsConstraintsDependencies/content` locate it exactly — the log
   is one section per line, keyed by path, which is what makes the first
   difference diagnostic rather than just a diff.
4. **The two renderings, side by side.** The reference first, the port second.
   Comparing them character by character is the last step, and usually the
   shortest.

The comparison stops reporting after the **first** differing line per language,
deliberately: one root cause typically shifts every subsequent line, and a
thousand-line diff hides the one that matters.

When several languages mismatch identically, suspect the *reference* or the
sample rather than the ports — nine independent implementations rarely make the
same mistake.

## Reading a suite failure

`run_all_suites.sh` reports one row per suite and leaves the detail in a log
file:

```
== suite summary ==
  PASS dart_runtime
  FAIL rust_v0
  SKIP java_runtime (javac not found)
  logs: <workspace>/ztmp/som_suites_<timestamp>
```

The row tells you *which* suite; the log file in the named folder tells you
*why*. Start there rather than re-running the suite by hand — the driver
captures the whole ecosystem-specific output, which a manual re-run may not
reproduce identically.

## Skips are not passes

A suite whose toolchain is absent is **skipped with the reason stated**, never
counted as a pass. `--strict` turns a skip into a failure, which is what a host
claiming full coverage should use.

One `PATH` quirk is handled for you and worth knowing about: rustup wires
`cargo` into the *interactive* shell profile only, so a non-interactive run
would otherwise skip both Rust suites on a host that can perfectly well build
them. `run_all_suites.sh` and `regenerate_golden.sh` both prepend
`~/.cargo/bin` when `cargo` is not already resolvable. A skip that reflects a
`PATH` quirk is nearly as bad as no gate at all.

## Proving a corpus table is load-bearing

A green suite in nine languages proves nothing about a corpus table unless every
runner genuinely *reads* it: a runner that never reaches the table passes
exactly as loudly as one that replays it correctly. Check counts do not settle
it either — each runner's base count differs, so two matching numbers are a
coincidence.

`tool/parity_gate.sh` settles it by experiment. It flips one expectation the
reference genuinely produces and requires the named suites to **all** go red;
any suite that stays green is not reading the table.

```bash
tool/parity_gate.sh --corpus editor_cases.json \
  --from '"expect": "2\.0"' --to '"expect": "2"'
```

Two properties make it a controlled experiment rather than a poke: `--from` must
match **exactly once** — a mutation that hits two places, or none, makes the
script refuse to run — and the corpus is restored unconditionally on exit,
including on failure.

## Error Handling

| Situation | Result |
|-----------|--------|
| A golden log differs from the reference | `MISMATCH` line, first differing line shown, exit `1` |
| A golden log is missing | Reported for that language; the rest still compare |
| A suite's toolchain is absent | `SKIP` with the reason; exit unaffected unless `--strict` |
| A suite fails | `FAIL` row, detail in the per-suite log, non-zero exit |
| A sample no longer instantiates every structure | `check_sample_coverage.dart` reports the remainder and exits non-zero |
| `parity_gate.sh --from` matching zero or several places | The script refuses to run — an uncontrolled mutation is not evidence |
| `parity_gate.sh` interrupted | The corpus is restored anyway; restoration is unconditional |

Nothing here throws a stack trace at an operator: every driver reports a
diagnosis and an exit code, because these run in CI as often as by hand.

## Best Practices

- **Run the suites before the golden proof.** A port whose own tests fail will
  usually produce a mismatched log too, and the suite failure is the more
  specific diagnosis.
- **Read the byte counts before the diff.** Equal sizes mean a value differs;
  different sizes mean structure does, and that is a different search.
- **Suspect the reference when several ports agree with each other.** Nine
  implementations rarely share one mistake.
- **Use `--strict` in CI.** A skip is honest locally and misleading in a
  pipeline that reports "all green".
- **Never hand-edit a file under `golden/`.** It is generated; regenerate it.
- **Prove a new corpus table with `parity_gate.sh` before trusting it.** A table
  nothing reads is worse than no table, because it looks like coverage.

---

Back to the [documentation index](index.md).

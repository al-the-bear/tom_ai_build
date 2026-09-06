# TomSpecs CLI Tool — The Gates

Six checks in `bin/` guard properties that decay silently: citations that stop
resolving, a release set that acquires a dependency, a generated CodeSpecs trio
that drifts from its contract. This guide covers running each, reading its
report, and what a failure actually means. What each gate *enforces* is decided
elsewhere — `index.md`'s citation convention, the release-set manifest,
[`codespecs_derivation_contract.md`](../../tom_specs_model/doc/codespecs_derivation_contract.md)
§6 — and is cited here, never restated.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
  - [The three citation gates](#the-three-citation-gates)
  - [The release-closure gate](#the-release-closure-gate)
  - [The CodeSpecs validator](#the-codespecs-validator)
- [Reading a citation failure](#reading-a-citation-failure)
- [Scan sets are closed](#scan-sets-are-closed)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

Each gate answers one question, exits `0` when the answer is yes, and names
every offender when it is not.

| Gate | Asks | Runs in the default `dart test`? |
|------|------|----------------------------------|
| `check_section_citations.dart` | Does every `§` citation resolve to a real heading? | yes |
| `check_todo_citations.dart` | Does every cited quest-todo id name exactly one open todo? | yes |
| `check_oe_citations.dart` | Does every cited `OE-` id have a register row? | yes |
| `check_release_closure.dart` | Is the release-1 package set dependency-closed? | yes |
| `validate_codespecs.dart` | Does a generated CodeSpecs trio satisfy the `codespecs_derivation_contract.md` §6 checks? | no — needs a trio |

The four that run in the suite are the ones with a fixed subject. The CodeSpecs
validator needs a generated trio to point at, so it is invoked per Phase-4 run.

All of these check that a claim's *machinery* still holds — that a citation
resolves, that an edge stays inside the set. None checks that the claim is still
*true*. That is deliberate: the mechanical half is the half that decays in
silence.

## Quick Start

```bash
cd tom_ai/ai_build/tom_specs_clitool

dart run bin/check_section_citations.dart
dart run bin/check_todo_citations.dart
dart run bin/check_oe_citations.dart
dart run bin/check_release_closure.dart
```

Or all three citation gates as blocking steps after an outline refresh:

```bash
./tool/regenerate_outlines.sh
```

## Core Components

### The three citation gates

Each reports counts, then a verdict.

**`check_section_citations.dart`** resolves every `§` against `index.md`'s
convention — a bare `§N` means *this* document:

```
Scanned 320 file(s) against 15 document(s) in tom_ai/ai_build/tom_specs_model/doc; 3744 citation(s).
  self          1952
  cross-document 1766
  unverifiable  11
  dangling      15
  no such section 0
  exhibit       15
OK — every § citation resolves to a heading, and every exhibit marker covers one that cannot.
```

Read `no such section` first — it is the failure count. `dangling` and
`unverifiable` are *not* defects: a dangling citation is one whose document name
cannot be determined mechanically, and an `exhibit` marker covers a citation a
document has to *show* rather than make (a file documenting the convention must
exhibit its syntax).

**`check_todo_citations.dart`** resolves every cited quest-todo id:

```
Scanned 24 document(s) from tom_ai/ai_build/tom_specs_model/doc and the cited READMEs against 2514 todo stem(s) from 6 file(s).
  open       0
  closed     0
  ambiguous  0
  unresolved 0
OK — every cited todo id resolves to one open todo.
```

All four counters are failure counters here. `ambiguous` is the subtle one: ids
are `<stem>_<datecode>-<slug>`, so a bare stem can name several todos, and that
is a violation whatever their statuses — the fix is to write the date code.

**`check_oe_citations.dart`** resolves every `OE-` id against the register:

```
Scanned 96 file(s) against 35 registered id(s) from tom_ai/ai_build/tom_specs_model/doc/tom_specs_editor_specification.md.
  citations  89 (23 distinct id(s))
  undefined  0
OK — every cited OE id resolves to a register row.
```

This one runs **cited → defined only**. An id is allocated once and a retired row
is what reserves its number, so an unused row is not an error.

### The release-closure gate

`check_release_closure.dart` walks the committed manifest (`tool/release_set.yaml`)
and holds the release-1 set closed:

```
Walked 9 release package(s) and 2 approved crossing(s); 58 dependency edge(s) classified, 17 source-only member(s) checked.
  forbidden            0
  unapprovedWorkspace  0
  pathMismatch         0
  manifest             0
OK — the release set is closed: every edge stays inside the set, crosses at an approved published package, or lands on third-party pub.
```

Every edge must stay inside the set, cross at an approved published package, or
land on third-party pub — and must **never** reach the excluded plane, which is
red even when allowlisted. Approving a crossing does not approve what sits
behind it: the walk continues through the crossing's own manifest.

### The CodeSpecs validator

`validate_codespecs.dart` runs the thirty-seven contract checks over a generated
trio. It takes `--shared`, `--client` and `--server`; **all three are required**,
and omitting one exits `2` with usage rather than crashing:

```
Error: the CodeSpecs trio is the pass's subject; missing required option(s): --shared, --client, --server.
```

Exit codes: `0` clean, `1` on any violation, `2` on bad usage.

The trio is the pass's *subject*, not its only input. Four checks cannot be
answered from emitted code alone, and each takes its own corroborating input:

| Input | Unlocks |
|-------|---------|
| `--migrations` | Check 13 — migration convergence |
| `--cs-vocabulary` + `--core-source` | Check 9 — the catalogue mirrors |
| `--regenerated-shared` / `-client` / `-server` | Check 31 — determinism across a second generation |
| `--extracts` | Checks 32–36 — the comment text and the routing self-sufficiency |

**Each is optional, and an absent one names on stdout the checks it left unrun**,
so a skipped check never reads as a passed one. Give `--extracts` the whole tree
or none: a partial one understates what the trio was supposed to carry, and
check 35 would pass a gap it could not see.

## Reading a citation failure

A broken `§` citation reports the file, the line, the citation and the fix:

```
1 citation(s) resolve to no heading:
  tom_ai/ai_build/tom_specs_model/doc/index.md:187: §99.4 — DANGLING — bare, and index.md declares no §99.4. A bare citation means this document, so name the one it belongs to: `<file>.md §99.4`
```

Exit `1`. The message states the rule it applied, which is usually the whole
diagnosis: **a bare `§N` resolves against the citing document's own headings**.
Nearly every failure is a cross-document citation that lost its document name,
and the fix is to write the name — `` `<file>.md` §99.4 `` — not to add a <!-- section-cite: exhibit 99.4 -->
heading.

Note where the qualifier has to sit. A document name governs a citation in five
ways, and the one that bites is a line break: in a blockquote the `>` marker
stops a leading name from reaching the next line's `§N`. Keep the file name on
the same line as the `§` it qualifies.

## Scan sets are closed

Every gate's default corpus is **enumerated in source**, not discovered by
sweeping the workspace:

| Gate | Default corpus | Where |
|------|---------------|-------|
| Section citations | The doc folder + the project READMEs that cite it + the Dart doc comments of the TomSpecs source trees | `defaultCitedReadmes`, `defaultCitedSourceRoots` |
| Todo citations | The doc folder + the same READMEs | `defaultCitedReadmes` |
| OE citations | The editor project + the doc folder + the quest bookkeeping | `defaultCitingRoots` |

The consequence to know: **a newly documented package that cites `§` sections is
not held by any gate until it is added to those lists.** Until then, run it
through explicitly:

```bash
dart run bin/check_section_citations.dart --extra ../tom_specs_core/doc/annotations.md
```

`--extra` resolves against the **current working directory**, not the container
root, so paths are relative to `tom_specs_clitool`. A container-relative path
silently scans nothing — compare the `Scanned N file(s)` line against a baseline
run to be sure the extras landed.

Within an enumerated *root*, files are discovered, so a new file under a listed
source root is gated the day it is written.

## Error Handling

| Situation | Result |
|-----------|--------|
| A `§` citation resolving to no heading | `no such section` non-zero; exit `1` naming file, line and rule |
| A cited todo id that is closed, missing, or ambiguous | The matching counter non-zero; exit `1` |
| A cited `OE-` id with no register row | `undefined` non-zero; exit `1` |
| A register defining one id twice | Exit `1` — an id is allocated once |
| A release edge leaving the set | The offending edge named; exit `1` |
| `validate_codespecs.dart` missing a trio option | Usage printed; exit `2` |
| `validate_codespecs.dart` with a corroborating input absent | The unrun checks named on stdout; the rest still run |
| An `--extra` path that resolves to nothing | **Silently scans nothing** — check the file count |

The last row is the one operational trap in this set, and the reason the file
count is printed at all.

## Best Practices

- **Run `regenerate_outlines.sh` after any documentation pass.** It runs all
  three citation gates as blocking steps, which is cheaper than finding out from
  a failed suite.
- **Read `no such section`, not `dangling`.** Only the first is a defect;
  `dangling` and `unverifiable` are classifications, not failures.
- **Write the date code in a todo citation.** A bare stem is `ambiguous`
  whenever a campaign renumbered per prompt, and that is a violation regardless
  of the statuses behind it.
- **Keep a file name on the same line as the `§` it qualifies.** Especially
  inside a blockquote, where the `>` marker breaks the qualifier's reach.
- **Give `validate_codespecs.dart` the whole extract tree or none.** A partial
  one makes check 35 pass a gap it cannot see.
- **Compare `Scanned N file(s)` when using `--extra`.** A path that resolves to
  nothing reports success just as loudly as one that passed.

---

Back to the [documentation index](index.md).

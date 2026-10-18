# TomSpecs Gate Checklists

**Authority for:** the generic gate checklists, where they live and how they are
versioned; the format of a project checklist derived from one; and the format
and location of a gate report.

What a gate *is*, its criteria and the rules for adapting a checklist are
`tom_specs_project_flow.md` §PF-GAT-MOD, §PF-GAT-G1 to §PF-GAT-G8 and
§PF-GAT-CHK. This document does not restate them; it gives them a concrete
form.

## Contents

1. [The three levels](#1-the-three-levels)
2. [Where the generic checklists live](#2-where-the-generic-checklists-live)
3. [The checklist format](#3-the-checklist-format)
4. [The project checklist](#4-the-project-checklist)
5. [The gate report](#5-the-gate-report)
6. [Why a gate report is not a SOM document](#6-why-a-gate-report-is-not-a-som-document)
7. [Which gates have a generic checklist](#7-which-gates-have-a-generic-checklist)

## 1. The three levels

| Level | Where | Who changes it |
|-------|-------|----------------|
| Gate criteria | The gate's criteria table in `tom_specs_project_flow.md` | The TomSpecs process |
| Generic checklist | `gate_checklists/G<N>.checklist.yaml`, beside this document | The TomSpecs process; every project starts from it |
| Project checklist | `<spec-root>/gates/G<N>.checklist.yaml` in the project | The project, under the adaptation rules of `tom_specs_project_flow.md` §PF-GAT-CHK |

A criterion says *what must be true*. An **item** is one concrete inspection
that contributes to it: what to look at, how, what evidence that leaves, and
what counts as passing. A criterion has one or more items, and it passes when
all of its items pass.

## 2. Where the generic checklists live

The generic checklists are the files in [`gate_checklists/`](gate_checklists/),
one per gate: `G1.checklist.yaml`, `G2.checklist.yaml`, …. They sit beside
`codespecs_prompt.md`, the prompt template that runs a Phase-4 gate, and ship in
the `tom_specs_model` package with it. That is what `tom_specs_project_flow.md` §PF-GAT-CHK means by
checklists being versioned *alongside the prompt templates that execute them*.

**Versioning.** Each file carries a `checklistVersion` (semantic version):
- **major** when an item is removed, or its pass condition is made stricter, so
  that a project at the old version could now fail;
- **minor** when an item is added;
- **patch** when wording changes and no result can.

The package version (`tom_specs_model`) identifies the published set. A gate
report records both versions, so a gate result can be replayed against the
checklist that was in force: check out that package version and read the file.

**Checked by.** `tom_specs_clitool/test/gate_checklist_test.dart` holds every
file to this document:
- the file parses and has the format below, and every gate G1 to G8 has one;
- item ids are unique and well-formed;
- every criterion of the gate's criteria table in `tom_specs_project_flow.md`
  has at least one item, and
  every item names a criterion of that table.

## 3. The checklist format

```yaml
formatVersion: 1                 # this format; bumped only on a breaking change
gate: G2                         # G1 … G8
title: Solution Blueprint Complete
checklistVersion: 1.0.0
criteria: tom_specs_project_flow.md §PF-GAT-G2
document: SBP                    # the document the gate inspects (PI for G1)
items:
  - id: G2-STAKE-1               # G<N>-<CRITERION KEY>-<n>, never reused
    criterion: Stakeholders identified   # exactly a criterion of the G2 table
    inspect: Each stakeholder has a role and an interest.
    method: query                # tool | query | reading | sign-off
    how: SBP/STKG/STKRE-STAK-LST[] — the role and interest fields of each entry.
    evidence: The entry count and every entry with an empty role or interest.
    pass: At least one entry; every entry has both.
    parameters: []               # optional: project parameters the item reads
```

**Methods.**

| `method` | Means | Evidence it leaves |
|----------|-------|--------------------|
| `tool` | A command whose output decides the item | The command line and its output, stored with the report |
| `query` | A structural query over the SOM document — paths, section ids, field values. Any SOM runtime's query engine, the `tom_spec_engine` `spec` scope or the VS Code `tomAi_spec*` tools can run it | The query and the matches it found |
| `reading` | A judgement no query can make | A reader's note naming every section inspected and what was found |
| `sign-off` | A recorded human decision | Where the decision is recorded, and its values |

**Paths** in `how` are SOM document paths of section ids (`SBP/INSC/RO/FR/…`);
`[]` marks a list whose items are inspected one by one.

**Parameters** are the names of project parameters an item reads — thresholds
and switches `tom_specs_project_flow.md` §PF-GAT-CHK rule 5 says belong to the project, set from its `QAP`
and `ATS`. The generic checklist names them and states their default in `pass`;
the project checklist sets them.

## 4. The project checklist

A project checklist is the generic file, copied into the project and adapted.
It lives at `<spec-root>/gates/G<N>.checklist.yaml`, where `<spec-root>` is the
project's specification folder, the same root the CodeSpecs extracts use. It is
committed with the specification.

It carries everything the generic file does, plus:

```yaml
derivedFrom:
  checklist: tom_specs_model/doc/gate_checklists/G2.checklist.yaml
  checklistVersion: 1.0.0
  modelPackage: tom_specs_model 1.5.0
parameters:
  requirementSourceCoverage: 0     # uncovered Project Idea items allowed
  roadmapDatesRequired: false
items:
  - id: G2-SCHEMA-2
    origin: narrowed               # generic | narrowed | added
    how: dart run tool/check_required_fields.dart   # the project's own check
    # … the remaining fields as in the generic item
  - id: G2-UAM-AUTHZ-1             # an added item: G<N>-<PROJECT>-<KEY>-<n>
    origin: added
    criterion: Requirements traceable
    # …
removed:
  - id: G2-RMP-2
    justification: The roadmap is a single stage; its gate is G2 itself.
    approvedBy: <the gate's human approver>
    date: 2026-10-20
```

- **`origin: generic`** — copied unchanged. It is the default and may be left
  out.
- **`origin: narrowed`** — made more specific: a stricter pass, a concrete tool,
  a narrower path. Allowed freely.
- **`origin: added`** — the project's own item, with a project key in its id.
  Allowed freely; it must still name a criterion of the gate.
- **`removed`** — an item of the generic checklist the project does not run. It
  needs a justification, the gate's human approver and a date, and every report
  of the gate lists it.

When the generic checklist gains a version, the project decides when to take
it. Taking it means re-copying the new items, keeping its own narrowings and
additions, and bumping `derivedFrom.checklistVersion`.

## 5. The gate report

A gate evaluation writes one **report of record** and a **summary** into the
project's evidence store (`tom_specs_project_flow.md` §PF-GAT-EVD), under
`<spec-root>/quality/evidence/gates/`:

```text
<spec-root>/quality/evidence/gates/
├── G2_20261020-1430.gate.yaml     # the report of record
├── G2_20261020-1430.gate.md       # the summary for the human review
└── G2_20261020-1430/              # the evidence the items left
    ├── G2-SCHEMA-1.validate_spec.json
    └── G2-STAKE-1.query.txt
```

All three are committed. A report is never edited after it is written. A
re-evaluation writes a new report that names the one it re-evaluates and
re-checks only the failed items (`tom_specs_project_flow.md` §PF-GAT-MOD).

```yaml
formatVersion: 1
gate: G2
takenAt: 2026-10-20T14:30:00Z
document:
  path: tom_uam/tom_specs/phase2_solution_blueprint/tom_uam.sbp.docspecs.yaml
  commit: 3f2a9c1e                # the revision the gate inspected
checklist:
  path: tom_uam/tom_specs/gates/G2.checklist.yaml
  checklistVersion: 1.0.0         # derivedFrom.checklistVersion
  modelPackage: tom_specs_model 1.5.0
reevaluates: null                 # or the report this one re-checks
result: fail                      # pass | fail
items:
  - id: G2-SCHEMA-1
    status: pass                  # pass | fail | not-run
    evidence: [G2_20261020-1430/G2-SCHEMA-1.validate_spec.json]
  - id: G2-REV-1
    status: fail
    evidence: []
    finding: No approval entry with the business approver's role.
removed: [G2-RMP-2]               # echoed from the project checklist
criteria:                         # derived from the items
  - criterion: Business review recorded
    status: fail
remediation:
  - Record the product owner's approval in SBP/DOCTL/APREC-APRV-LST[].
approval:                         # the human approval the gate requires
  by: null
  role: null
  date: null
  decision: null                  # approved | rejected
```

- An item is **`not-run`** only when an earlier item it depends on failed, so its
  result could not mean anything. It counts as a failure.
- A **criterion** passes when every item naming it passes.
- The gate **passes** when every criterion passes and, where the gate requires
  one, the human approval is recorded as `approved`.

The **summary** (`.gate.md`) is generated from the report: the result, a table
of criteria and items with their status, every finding with its remediation,
the removed items, and the approval. It is for the review; the YAML is the
record.

## 6. Why a gate report is not a SOM document

The model does have a class for gate checklists, `QualityGateChecklist`
(`QUGACH`, in the Blueprint's quality model). But it describes the quality gates
of the **system being specified** — the checks *its* product will pass at *its*
acceptance. It is part of the specification, not a record of the process that
produces it.

A TomSpecs gate report is a process record about a document. Writing it into the
document it judges would change the document after the gate inspected it.
Its readers are the orchestrator and the reviewer, not the specification's own
consumers. So it is a plain YAML record with a markdown summary, like the
CodeSpecs gate record (`gate.verdicts.yaml`, `codespecs_prompt.md` §6.3).

## 7. Which gates have a generic checklist

| Gate | Generic checklist |
|------|-------------------|
| G1 | [`gate_checklists/G1.checklist.yaml`](gate_checklists/G1.checklist.yaml) |
| G2 | [`gate_checklists/G2.checklist.yaml`](gate_checklists/G2.checklist.yaml) |
| G3 | [`gate_checklists/G3.checklist.yaml`](gate_checklists/G3.checklist.yaml) |
| G4 | [`gate_checklists/G4.checklist.yaml`](gate_checklists/G4.checklist.yaml) |
| G5 | [`gate_checklists/G5.checklist.yaml`](gate_checklists/G5.checklist.yaml) |
| G6 | [`gate_checklists/G6.checklist.yaml`](gate_checklists/G6.checklist.yaml) |
| G7 | [`gate_checklists/G7.checklist.yaml`](gate_checklists/G7.checklist.yaml) |
| G8 | [`gate_checklists/G8.checklist.yaml`](gate_checklists/G8.checklist.yaml) |

Every gate has one. Where an item's method is `tool` and the workspace has no
tool for it — an acceptance suite, a security scanner, a deployment pipeline —
its `how` names it as the project's own, and the project checklist narrows the
item to the concrete command (§4).

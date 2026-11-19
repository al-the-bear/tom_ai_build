# Gate G1, run 1 — phase todos, completeness of the run, traceability

The closing check of the item todos (`p1gr1-4`), 2026-11-19. Inspected: the
Project Idea `tom_ai/ai_build/specification/phase1_project_idea/project_idea.ai_runtime.md`
as it is in the working tree (2,473 lines), the evidence folder
`tom_ai/ai_build/specification/quality/evidence/gates/G1_20261119-1317/` and
the quest's todo file. No document was changed and nothing was committed.

**Summary**

| Part | Result |
| --- | --- |
| 1 Phase todos | **Two are open. The gate cannot pass.** |
| 2 Completeness of the run | Complete: nine of nine items have a result with a status; every evidence file named exists. Seven pass, two fail. |
| 3 Traceability | Holds for the decisions, the cited sources and the section-id chains. Exceptions in how single statements name their source (35 of 394) and in one contradiction; none keeps the Blueprint from citing the Project Idea. No new todo. |

## 1. Phase todos

Todos of the quest `ai_runtime` whose id starts with `phasetodosone`
(live file `todos.ai_runtime.todo.yaml`; the archived file holds none):

| Id | Status | Created by | For |
| --- | --- | --- | --- |
| `phasetodosone1_aksr-ids-for-units-screens-problems` | not-started | `p1gr1-1_aksr-doc-sources-ids` (this run) | G1-ID-1 failed: ids for the generation units, the screen inventory and the problem statements |
| `phasetodosone2_aksr-second-question-round-answers-taken-in` | not-started | `p1gr1-3_aksr-clarifications-change` (this run) | G1-CLAR-1 failed: a second question round takes the 19 answers into the text and settles what is open |

Both were created by this run's item todos; `p1gr1-2` created none. No
`phasetodosone` todo existed before the run.

**The gate cannot pass while these two are open:**
`phasetodosone1_aksr-ids-for-units-screens-problems` and
`phasetodosone2_aksr-second-question-round-answers-taken-in`.

## 2. Completeness of the run

The checklist `tom_ai/ai_build/specification/gates/G1.checklist.yaml` has
nine items. Each has its `<item id>.result.yaml` with a status, and every
evidence file a result names is in the folder.

| Item | Status | Evidence named | All present | Phase todo |
| --- | --- | --- | --- | --- |
| G1-DOC-1 | pass | `G1-DOC-1.size.txt` | yes | — |
| G1-PROB-1 | pass | `G1-PROB-1.reading.md` | yes | — |
| G1-USER-1 | pass | `G1-USER-1.reading.md` | yes | — |
| G1-SCOPE-1 | pass | `G1-SCOPE-1.reading.md` | yes | — |
| G1-SRC-1 | pass | `G1-SRC-1.resolve.txt` | yes | — |
| G1-ID-1 | **fail** | `G1-ID-1.counts.md`, `G1-ID-1.sections.txt`, `G1-ID-1.reading.md` | yes | `phasetodosone1_aksr-ids-for-units-screens-problems` |
| G1-CLAR-1 | **fail** | `G1-CLAR-1.reading.md` | yes | `phasetodosone2_aksr-second-question-round-answers-taken-in` |
| G1-RISK-1 | pass | `G1-RISK-1.reading.md` | yes | — |
| G1-CHANGE-1 | pass (not applicable: initial development) | `G1-CHANGE-1.chatvariable.txt` | yes | — |

**Missing:** nothing. Both failed items carry `finding`, `remediation` and
`phasetodo`, and both named todos exist in the quest. No item is `not-run`.

Three passes are recorded as borderline by their own findings: G1-USER-1 (the
owner is named only in the answer to PQ-1, not yet in the section's text),
G1-RISK-1 (the answers to PQ-16 and PQ-19 are not yet in the text) and
G1-SRC-1 (S10 is cited nowhere outside its own row). The second question round
(`phasetodosone2`) covers the first two.

## 3. Traceability

**Method.** A script read the document: it took every item whose id stands in
bold at the start of a table row, a list item or a paragraph (469 items, the
same as G1-ID-1's 475 less the six `WR-` rows of source S3), and for each the
text up to the next item, heading or question block. It looked for a source id
`S<n>` and a place in it (a `§`, a note, or a decision or requirement id of the
source). The decisions were compared with the decisions tables of the two
snapshots, the chains with the document's 69 heading ids.

### 3.1 Statements name a source

394 statements carry an id and are expected to name a source (all kinds but
the sources `S`, the decisions `D` and the contradictions `X`, which 3.2 and
3.3 cover).

| Kind | Items | Name `S<n>` and a place | Exceptions |
| --- | --- | --- | --- |
| `V-` vision | 8 | 8 | — |
| `U-` users and stakeholders | 13 | 13 | — |
| `O-` out of scope | 8 | 7 | O-2: sources without a place |
| `L-` deferred | 11 | 1 | L-2 … L-11: a decision id, no `S<n>` in the row |
| `E-` what exists | 18 | 15 | E-6, E-7, E-13: source without a place |
| `C<area>.` capabilities | 261 | 260 | CS.17: source without a place |
| `N-` expectations | 34 | 34 | — |
| `T` topologies | 8 | 0 | T1 … T8: no source in the row |
| `F` flows | 12 | 0 | F1 … F12: no source in the row |
| `R-` risks and dependencies | 21 | 21 | — |
| **Total** | **394** | **359** | **35** |

Every `S<n>` the document cites is in the table of `SRC` (S1 … S20).

**The exceptions:**

1. **The source stands once, above the table, not in the row** (30 items).
   - `SCO > SCO-LATER`, L-2 … L-11: the section opens with "Decided as not
     part of the first version (S1 § 11.1)". Each row names the decision that
     defers it (DQ-8, DQ-3, DQ-2, CQ-4, CQ-10, DQ-4, WQ-1, FO-16, FO-20, CQ-9),
     which is its place in S1 § 14.1 or S2 § 5; only the `S<n>` is missing in
     the row. L-1 names both.
   - `NFR > NFR-TOPO`, T1 … T8: "The topologies the architecture document
     describes (S1 § 8)"; the rows name nothing.
   - `NFR > NFR-TOPO > NFR-TOPO-FLOWS`, F1 … F12: "The flows the architecture
     document draws as sequences (S1 § 9)"; the rows name nothing.

   The source of each of these is unambiguous from the line above its table
   (the topologies and flows have the same numbers in S1 § 8 and § 9). Strictly
   read, "every statement with an id names a source" does not hold for them.
2. **A source without a place in it** (5 items): O-2 "(S3; S14)", E-6 "(S15)",
   E-7 "(S16)", E-13 "(S8)", CS.17 "(S7)". Each names a whole document. S16,
   S8 and S7 are short; for S3, S14 and S15 a reader has to search.

**Does any of them keep the Blueprint from citing the Project Idea?** No. The
Blueprint cites the ids, and all 35 have one; what is thinner is the step from
the Project Idea back to its source. No `phasetodosone` todo is created for
them. They are cheap to correct in the second question round
(`phasetodosone2`), which rewrites these sections anyway: an `(S1 § 8)`,
`(S1 § 9)` or `(S1 § 11.1)` in each row, and a place for the five.

### 3.2 Decisions (`DEC`)

| Check | Result |
| --- | --- |
| Rows in the table | 43 (D-1 … D-43) |
| Rows that name the id the decision has in its source | 43 of 43 |
| Source ids named | 66 uses: 22 `FO-`, 20 `CQ-`, 14 `DQ-`, 4 `WQ-`, 4 `RT-`, 2 `RS-` |
| `CQ-`, `DQ-`, `WQ-` ids that exist in `sources/ai_runtime_concept.md` § 14.1 | all (the table there has 37: CQ-1 … CQ-20, DQ-1 … DQ-13, WQ-1 … WQ-4) |
| `FO-` ids that exist in `sources/ai_runtime_feature_overview.md` § 5 | all (the table there has 21: FO-1 … FO-22 without FO-14) |
| `RT-` and `RS-` ids | exist in S19 (`quest_runtime_design.ai_runtime.md`) and S18 (`runtime_split_plan.ai_runtime.md`); those two are not snapshots, checked against the originals |
| Decisions of the two source tables that no row of `DEC` names | none: all 58 are named as a source id |
| Decision ids cited anywhere in the text that are in neither source table | none |

No exception.

### 3.3 Contradictions (`CON`)

12 contradictions (X-1 … X-12). Sources named before the resolution:

| Id | Sources that disagree | Note |
| --- | --- | --- |
| X-1 | S19, S2 § 3.1, S3 (WR-7), S14 | — |
| X-2 | S2 § 5 (FO-15), S15 | — |
| X-3 | S3 (WR-2, WR-6), S1 | — |
| X-4 | S3 (WR-1), S5, S6 | — |
| X-5 | S5, S13 | — |
| X-6 | S5 § 8, and "the earlier plan" | **one side has no source id** |
| X-7 | S1 § 13.1 and § 14.1, against this document being Phase 1 of a TomSpecs run | one source and the project's own process; marked `___check here___`, **unresolved** |
| X-8 | S5, S6, S16 | — |
| X-9 | S6, S19 | — |
| X-10 | S6, S19 | — |
| X-11 | S2, S6 | — |
| X-12 | S1 § 8 (T6), against D-15 | both sides are in S1 (§ 8 and the decision CQ-4); marked `___check here___`, **not resolved** |

**Exceptions:**

1. **X-6** names only one of its two sides by a source: "the earlier plan"
   that added to the protocol in minor versions is not tied to a source (it is
   the plan of the todos `tac_webwork-1` … `-4`, described in S1 § 7.10 and
   WQ-2). A one-line correction; it does not affect citing.
2. **X-7 and X-12 are unresolved**, as the document says itself. That is not a
   traceability fault: both name what disagrees. They are open clarifications,
   and G1-CLAR-1 already failed on X-7's subject (the answers to PQ-19 and
   PQ-17); `phasetodosone2` carries them. No further todo.

### 3.4 Section-id chains

| Check | Result |
| --- | --- |
| Headings with an id | 69, no id twice |
| Chains in the document (`A > B`) | 109 uses of 37 distinct chains |
| Chains naming a heading id that does not exist | none |
| Chains whose parts are not parent and child | none |
| Chains broken over a line | none |
| Chains written outside code marks | none |
| References by a single section id (`TAC`, `DEL`, `CON`, …) | 17, each an existing heading |

Two of the single-id references name a subsection without its parent:
`TAC-PEOPLE` (line 1251, in an author's note) and `PAR-APPROACH` (line 1747).
Both headings exist and their ids are unique, so the reference resolves; the
document's own rule ("a section is referred to by its id chain, outer first")
would have `TAC > TAC-PEOPLE` and `PAR > PAR-APPROACH`. Not a blocker.

### 3.5 New findings

None becomes a `phasetodosone` todo: no exception found here keeps the
Blueprint from citing the Project Idea. The corrections noted in 3.1, 3.3 and
3.4 (a source in each row of three tables, a place for five sources, the
source of X-6's earlier plan, two chains) fit into the second question round
that `phasetodosone2` asks for.

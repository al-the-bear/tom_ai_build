# Gate G1, run 2 — phase todos, completeness of the run, traceability

The closing check of the item todos (`p1gr2-3`), 2026-11-19. Inspected: the
Project Idea `tom_ai/ai_build/specification/phase1_project_idea/project_idea.ai_runtime.md`
as committed in ai_build `07412a22` (2,401 lines, 174,683 bytes, unchanged in
the working tree), the evidence folder
`tom_ai/ai_build/specification/quality/evidence/gates/G1_20261119-2045/` and
the quest's todo files. No document was changed and nothing was committed.

**Summary**

| Part | Result |
| --- | --- |
| 1 Phase todos | **None is open.** Both of run 1 are completed; run 2 created none. |
| 2 Completeness of the run | Complete: nine of nine items have a result with a status and `run1`; every evidence file named exists. Nine pass. |
| 3 Traceability | Run 1's 35 statements are all corrected. Over the whole document it holds for the decisions, the section-id chains and the ids. 39 of 465 statements, all of two tables that got their ids after run 1, name their source above the table and not in the row; three contradictions name one side without its id. None keeps the Blueprint from citing the Project Idea. No new todo. |

## 1. Phase todos

Todos of the quest `ai_runtime` whose id starts with `phasetodosone`. The
live file `todos.ai_runtime.todo.yaml` holds none; both are in the archived
file `todos-archived.ai_runtime.todo.yaml`.

| Id | Status | Created by | For |
| --- | --- | --- | --- |
| `phasetodosone1_aksr-ids-for-units-screens-problems` | completed 2026-11-19, archived | `p1gr1-1_aksr-doc-sources-ids` (run 1) | G1-ID-1 failed in run 1: ids for the generation units, the screen inventory and the problem statements |
| `phasetodosone2_aksr-second-question-round-answers-taken-in` | completed 2026-11-19, archived | `p1gr1-3_aksr-clarifications-change` (run 1) | G1-CLAR-1 failed in run 1: a second question round takes the answers into the text |

Created by this run's item todos: **none.** `p1gr2-1_aksu-failed-items-ids-clarifications`
(G1-ID-1, G1-CLAR-1) and `p1gr2-2_aksu-passed-items-on-changed-document` (the
other seven items) are both completed, and no result of this run names a
`phasetodo`.

**No `phasetodosone` todo is open.** Nothing of Phase 1's phase todos stands
in the way of the gate.

## 2. Completeness of the run

The checklist `tom_ai/ai_build/specification/gates/G1.checklist.yaml` has
nine items. Each has its `<item id>.result.yaml` with `status` and `run1`,
and every evidence file a result names is in the folder. No file in the
folder is left unnamed by a result (beside `README.md` and this file).

| Item | Status | Run 1 | Evidence named | All present | Phase todo |
| --- | --- | --- | --- | --- | --- |
| G1-DOC-1 | pass | pass | `G1-DOC-1.size.txt` | yes | — |
| G1-PROB-1 | pass | pass | `G1-PROB-1.reading.md` | yes | — |
| G1-USER-1 | pass | pass | `G1-USER-1.reading.md` | yes | — |
| G1-SCOPE-1 | pass | pass | `G1-SCOPE-1.reading.md` | yes | — |
| G1-SRC-1 | pass | pass | `G1-SRC-1.resolve.txt`, `G1-SRC-1.reading.md` | yes | — |
| G1-ID-1 | pass | **fail** | `G1-ID-1.counts.md`, `G1-ID-1.reading.md` | yes | — |
| G1-CLAR-1 | pass | **fail** | `G1-CLAR-1.questions.txt`, `G1-CLAR-1.reading.md` | yes | — |
| G1-RISK-1 | pass | pass | `G1-RISK-1.reading.md` | yes | — |
| G1-CHANGE-1 | pass (not applicable: initial development) | pass | `G1-CHANGE-1.chatvariable.txt` | yes | — |

**Missing:** nothing. No item is `fail` or `not-run`, so no result needs
`remediation` or `phasetodo`, and none carries one.

Five passes are recorded as borderline in one point by their own findings:
G1-CLAR-1 (one sentence without an id in `NFR > NFR-TOPO` against the answers
to PQ-16 and PQ-9; CI.19 left to the security model), G1-ID-1 (the table of
mappers in `NFR > NFR-GEN` and two sentences citable by their section only),
G1-RISK-1 (the dependency on the extension's todo `vscimpb179` named in `DEL`
and not in `RISK > RISK-DEPS`), G1-SCOPE-1 (two wordings) and G1-SRC-1 (S9's
links noted). None was judged a failure by its item.

## 3. Traceability

**Method.** A script read the document: it took every item whose id stands in
bold at the start of a table row, a list item or a paragraph (559 items; the
565 of G1-ID-1 less the six `WR-` rows of source S3), and for each the text up
to the next item, heading or table end. It looked for a source — `S<n>` with a
place in it (a `§`, a part or section name, or a decision or requirement id of
that source), or a question `PQ-<n>` — in the statement's brackets or, in a
table, its source column. The decisions were compared with the decisions
tables of the two snapshots and with `01_02_Questions Round/answers.md`, the
chains with the document's 70 heading ids. The 22 statements that name only a
`PQ-<n>` were read against the answers.

### 3.1 Run 1's 35 statements

All corrected.

| Run 1's exception | Now |
| --- | --- |
| `SCO > SCO-LATER`, L-2 … L-11: a decision id, no `S<n>` in the row | each row ends with `(S1 § 11.1)`, most with its decision id too, e.g. L-11 `(S1 § 11.1; CQ-9)` |
| `NFR > NFR-TOPO`, T1 … T8: no source in the row | a source column: `S1 § 8`, with the question where an answer changed the row (T5 `S1 § 8; PQ-9, PQ-13`) |
| `NFR > NFR-TOPO > NFR-TOPO-FLOWS`, F1 … F12: no source in the row | a source column: `S1 § 9`, F1 and F12 with `PQ-6` |
| O-2 `(S3; S14)` | `(S3, "Why Webwork needs it, and when" and WR-7; S14, part two, § 5)` |
| E-6 `(S15)` | `(S15: the protocol document, § 5 "The client endpoint"; the idea document, part-clients)` |
| E-7 `(S16)` | `(S16, § 1 … § 6 and "What enforces what")` |
| E-13 `(S8)` | `(S8, section input: the idea only)` |
| CS.17 `(S7)` | `(S7, "How the runtime reaches a model today")` |

Run 1's other notes are corrected too: X-6 names the source of "the earlier
plan" (the todos S1 § 7.10 describes); the two references by a subsection id
alone (`TAC-PEOPLE`, `PAR-APPROACH`) are gone (3.5); X-7 and X-12 are resolved
(3.4).

### 3.2 Statements name a source

465 statements carry an id and are expected to name a source (all kinds but
the sources `S`, the decisions `D` and the contradictions `X`).

| Kind | Items | Name a source with a place, or a `PQ` | Exceptions |
| --- | --- | --- | --- |
| `V-` vision | 8 | 8 | — |
| `P-` problems | 14 | 4 | P-5 … P-14: no source in the row |
| `U-` users and stakeholders | 13 | 13 | — |
| `O-` out of scope | 9 | 9 | — |
| `L-` deferred | 11 | 11 | — |
| `E-` what exists | 18 | 18 | — |
| `C<area>.` capabilities (13 areas) | 278 | 278 | — |
| `SC-` screen inventory | 29 | 0 | SC-1 … SC-29: no source in the row |
| `N-` expectations | 34 | 34 | — |
| `T` topologies | 8 | 8 | — |
| `F` flows | 12 | 12 | — |
| `G-` generation units | 7 | 7 | — |
| `R-` risks and dependencies | 24 | 24 | — |
| **Total** | **465** | **426** | **39** |

Every `S<n>` cited is in the table of `SRC` (S1 … S20). 22 statements name
only a question (PQ-4, -6, -7, -9, -13, -16, -17, -19, -20, -21, -23),
each with a section or statement it belongs with; read against `answers.md`,
each states what the answer says. Every question of PQ-1 … PQ-23 is cited
except PQ-5 and PQ-11: their answers were questions back, asked again as PQ-21
and PQ-20 (`01_02_Questions Round/changes.md`), and no statement rests on
them.

**The exceptions — the source stands once, above the table, not in the row**
(39 items, the same form run 1 found for the deferred features, the
topologies and the flows):

- `PAR > PAR-PROBLEM`, P-5 … P-14: the table is introduced by "The problems
  this part solves (S1 § 10.1; S16)"; the rows name nothing. P-1 … P-4 in
  `VIS > VIS-PROBLEM` each name their source.
- `CLI > CLI-SCREENS`, SC-1 … SC-29: the inventory is introduced by "The
  inventory as it stands. … (S1 § 12.3; S17)"; the rows name nothing. The same
  line marks the outcomes as a first pass (`___check here___`), which G1-RISK-1
  noted for the Blueprint's register.

Both tables got their ids after run 1 (`phasetodosone1`), which is why run 1
did not count them. The source of each row is unambiguous from the line above
its table: the rows of both tables are the rows of S1 § 10.1 and of the
inventory in S1 § 12.3. Strictly read, "every statement with an id names a
source" does not hold for them.

**A second source named as a whole document** (62 statements, not counted as
exceptions): beside a source with a place they name another by its id alone,
e.g. O-6 `(S1 § 10.4; S16)`, CS.9 `(S1 § 5.8, CQ-16; S15)`, R-1
`S19; S1 § 13.3; S18`. The sources named so are S3, S4, S5, S6, S7, S8, S9,
S11 … S19. Each statement can be followed to a place through its first
source; for the second a reader searches the document. Run 1 counted such
statements as naming a source, and so does this run.

**Does any of them keep the Blueprint from citing the Project Idea?** No. The
Blueprint cites the ids, and every one of the 465 statements has one; what is
thinner for 39 rows is the step back from the Project Idea to its source, and
that step is one line up. No `phasetodosone` todo is created. The correction
is two columns: `S1 § 10.1` in the rows of P-5 … P-14 and `S1 § 12.3` in the
rows of SC-1 … SC-29; it fits the first change the Blueprint work makes to the
Project Idea.

### 3.3 Decisions (`DEC`)

| Check | Result |
| --- | --- |
| Rows in the tables | 59 (D-1 … D-59), in six tables |
| Rows that name the id the decision has in its source | 59 of 59 |
| Source ids named in the "Source id" column | 87 uses: 22 `FO-`, 18 `CQ-`, 12 `DQ-`, 4 `WQ-`, 4 `RT-`, 2 `RS-`, 25 `PQ-` |
| `CQ-`, `DQ-`, `WQ-` ids exist in `sources/ai_runtime_concept.md` § 14.1 | all (the table there has 37: CQ-1 … CQ-20, DQ-1 … DQ-13, WQ-1 … WQ-4) |
| `FO-` ids exist in `sources/ai_runtime_feature_overview.md` § 5 | all (the table there has 21: FO-1 … FO-22 without FO-14) |
| `PQ-` ids exist in `01_02_Questions Round/answers.md` | all (23 questions there, PQ-1 … PQ-23, each with an answer) |
| `RT-` and `RS-` ids | exist in S19 (`quest_runtime_design.ai_runtime.md`) and S18 (`runtime_split_plan.ai_runtime.md`); those two are not snapshots, checked against the originals |
| Decisions of the two source tables named by a row of `DEC` | all 58: 54 as a source id, and CQ-1, CQ-17, DQ-10, DQ-13 under "Replaces or completes" of D-36 and D-37, the decisions that replaced them |
| Answers named by a row of `DEC` | 21 of 23; PQ-5 and PQ-11 decided nothing (3.2) |
| Decision ids cited anywhere in the text that exist in no source | none |

**A decision that replaced an earlier one says which.** 20 rows have an entry
under "Replaces or completes". Every id named there exists in its source
(RT-1, RT-2, RT-6, RT-9, RT-10, RS-1, RS-4, RS-5, CQ-1, CQ-10, CQ-17, DQ-1,
DQ-9, DQ-10, DQ-13, WQ-1, FO-15, FO-19, FO-21, and D-25 of this document).
The decisions that question round 2 changed all say what they replace: D-36
(CQ-17, DQ-10, RS-5), D-37 (CQ-1, DQ-13), D-49 (DQ-9 in part), D-51 (CQ-10 and
WQ-1 in part), D-54 (D-25 in part), D-59 (S5's declared units).

Four of the 20 name what they replace in words, without an id: D-7 ("S19's
host transports"), D-21 ("the minor versions in the earlier todos"), D-22
("the smaller team server"), D-27 ("the earlier answer that such a client
registers in tac, and the concept's earlier text"). For each, the contradiction
that records the change names the sources (X-1, X-6, X-4, X-3). Not an
exception to the rule, which asks that the row says which.

No exception.

### 3.4 Contradictions (`CON`)

15 contradictions (X-1 … X-15). Each names what disagrees and is resolved;
none is left open, and the section holds no `___check here___`.

| Id | What disagrees | Resolved by |
| --- | --- | --- |
| X-1 | S19; S2 § 3.1; S3 (WR-7); S14 | D-7; S1 § 6.3; `RT > RT-TOOLS` |
| X-2 | S2 § 5 (FO-15); S15 | D-19 |
| X-3 | S3 (WR-2, WR-6); "an earlier answer of the product owner"; S1's earlier text | D-27 |
| X-4 | S6, S5; S3 (WR-1) | D-22 |
| X-5 | S13; S5; S1 § 7.3 (DQ-1) | D-24 |
| X-6 | the earlier plan (the todos S1 § 7.10 describes); S5 § 8 | D-21 |
| X-7 | S1 § 13.1 and § 14.1; this document being Phase 1 of a TomSpecs run | D-37, D-36 |
| X-8 | S5, S6, S16; the quest that exists | S1 § 2.4 |
| X-9 | S19, S6; where the service is today | D-1, D-2 |
| X-10 | S19; S6 | D-6 |
| X-11 | S6; S2 § 3.4 | D-47; `TAC > TAC-BACKENDS`, CA.26 |
| X-12 | S1 § 8 (T6); D-15 | D-52 |
| X-13 | S1 § 5.7 (DQ-9); "the answer of the first question round" | D-49 |
| X-14 | S1 § 11.1 (CQ-10, WQ-1); "the answer of the first question round" | D-51 |
| X-15 | S5, S6; the answer to PQ-23 | D-59 |

Run 1's two unresolved contradictions (X-7, X-12) are resolved, and X-6 names
both sides. X-13 … X-15 are new from question round 2.

**Exceptions** (three, each one side named without its id):

1. **X-3:** "an earlier answer of the product owner" is the answer in the
   todo `tac_webwork-1`, which S1 § 7.10 quotes; the text names neither.
2. **X-13:** "the answer of the first question round" is the answer to PQ-6;
   the id stands only in the decision it points to (D-49).
3. **X-14:** the same, for the answer to PQ-9 (D-51).

Each resolves in one step through the decision named in its resolution. None
affects citing; no todo.

### 3.5 Section-id chains

| Check | Result |
| --- | --- |
| Headings with an id | 70, no id twice |
| Chains in the document (`A > B`) | 159 uses of 39 distinct chains |
| Chains naming a heading id that does not exist | none |
| Chains whose parts are not parent and child, or that leave a level out | none (the one three-part chain, `TAC > TAC-PEOPLE > TAC-GROUPS`, is complete) |
| Chains broken over a line | none |
| Chains written outside code marks | none |
| References by a single section id | 20, each a top-level heading (`DEL` 8, `TAC` 4, `NFR` 2, `SRC`, `PAR`, `RT`, `CLI`, `GLO`, `CON` 1 each) |
| References to a subsection without its parent | none (run 1: two) |

No exception.

### 3.6 Ids

| Check | Result |
| --- | --- |
| Kinds | 28 of the document's own: `S`, `V-`, `P-`, `U-`, `O-`, `L-`, `E-`, the 13 capability areas, `SC-`, `N-`, `T`, `F`, `G-`, `D-`, `X-`, `R-` |
| Items | 559: S 20, V 8, P 14, U 13, O 9, L 11, E 18, CR 46, CP 35, CT 16, CA 43, CI 20, CM 14, CV 15, CW 25, CL 11, CU 15, CK 12, CQ 8, CS 18, SC 29, N 34, T 8, F 12, G 7, D 59, X 15, R 24 |
| An id twice | none |
| A gap in a kind's numbering | none: every kind runs from 1 to its count |

The capability area `CQ` (`CQ.1` … `CQ.8`, with a point) and the decision ids
`CQ-1` … `CQ-20` of S1 (with a hyphen) share their letters; the forms differ
and no reference is ambiguous.

### 3.7 New findings

None becomes a `phasetodosone` todo: no exception found here keeps the
Blueprint from citing the Project Idea. What could be corrected at the next
change to the document:

- a source in each row of two tables: `S1 § 10.1` for P-5 … P-14, `S1 § 12.3`
  for SC-1 … SC-29 (3.2);
- the id of the side named in words in X-3 (S1 § 7.10), X-13 (PQ-6) and X-14
  (PQ-9) (3.4).

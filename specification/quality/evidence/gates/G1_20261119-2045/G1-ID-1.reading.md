# G1-ID-1, run 2 — reader's note

Item: "The Project Idea's items carry ids, so the Blueprint can trace to
them." Pass: "Every item the Blueprint will need to cite has an id."
The counts are in `G1-ID-1.counts.md`.

## 1. What run 1 found, checked

| Group (run 1: no ids) | Now | Kind in `ABOUT > ABOUT-READ` |
| --- | --- | --- |
| the 7 generation units, `NFR > NFR-GEN` | every row of the table carries an id, G-1 … G-7 | "**`G-<n>`** A generation unit: a package or application the project builds (section 11.2)." |
| the 29 rows of the screen inventory, `CLI > CLI-SCREENS` | every row carries an id, SC-1 … SC-29 | "**`SC-<n>`** A row of the screen inventory: a screen of the extension, or a new screen, with what it becomes (section 8.3)." |
| the 4 problem statements, `VIS > VIS-PROBLEM` | each list item starts with its id, P-1 … P-4 | "**`P-<n>`** A problem the product solves: of the vision (section 2.1, `P-1` to `P-4`) and of parallel work today (section 10.1, `P-5` to `P-14`)." |
| the 10 problems, `PAR > PAR-PROBLEM` | every row of the table carries an id, P-5 … P-14 | the same row |

All four are fixed. The numbering is without gaps and without duplicates in
each of the three new kinds.

## 2. The whole document

29 kinds, 565 id-carrying items, 539 of the document's own kinds; no gap and
no duplicate in any kind; no id cited that is not defined; every section-id
chain named resolves. Four places hold ids out of numeric order (CP.35,
CA.39 … CA.43, CI.20, R-22 … R-24); each id is still unique and defined once,
so a citation finds it.

## 3. Statements without an id of their own

Read for statements the Blueprint will need to cite. None was found that
cannot be cited. Where a statement has no id of its own, this is how it is
cited:

**What question round 2 added**

| Place | What has no id of its own | Cited through |
| --- | --- | --- |
| `TAC > TAC-PEOPLE`, the table of what a member and an owner may do | its 9 rows | CI.5, which the table is the body of, and D-53. The Blueprint's security model lists operations one by one; it cites "CI.5" with the row's operation. Relied on. |
| `USR > USR-TEAM` | the paragraph and the one row of the team table | D-44 ("The product owner (member id `alexis`, display name Alexis) is the only reviewer …"), and the section chain. Relied on. |
| `DEL` | its seven paragraphs | each names its decision: D-40, D-39, D-41, D-36 and D-37, D-45, D-42; "What is delivered" points to the G- ids and N-30. Relied on. |
| `NFR > NFR-GEN`, "How the units are produced" and "Which standard descriptions the project publishes" | two paragraphs | D-57 and D-36. Relied on. |
| `NFR > NFR-GEN`, "What the tooling offers" and the sentence "No source names a unit of the kind "shared"" | a table of the tool's mappers and emitters, dated 2026-11-19, and one sentence | the section chain only. Borderline: they are facts about the tooling and about the sources, not statements about the product; the Blueprint's register of generation units cites G-1 … G-7 and D-57. |
| `TAC > TAC-PEOPLE > TAC-GROUPS` | its introduction (two sentences) | every statement of the subsection has an id, CA.39 … CA.43; the introduction says nothing beyond CA.39. |

**Elsewhere**

| Place | What has no id of its own | Cited through |
| --- | --- | --- |
| `VIS > VIS-PROBLEM`, "Why now" | one paragraph | the section chain; its three reasons are E-15 … E-18, E-3 and E-11. |
| `VIS > VIS-SYSTEM` | the five rows of the component table and the paragraph on the hosts of the first version | D-1 … D-5 for the components; the glossary's "host", CR.46, U-8 … U-10 and CK.10 for the hosts. |
| `GLO` | the terms | the term itself; the Blueprint has its own glossary. |
| `SCO > SCO-IN` | the 14 rows | the area code of each row (`CR`, `CP`, …), which is the key of its capability statements; the last row names D-40, D-41, N-32, N-33, R-1. |
| `RT > RT-CONFIG`, `RT > RT-INSTALL`, `RT > RT-SECRETS`, `RT > RT-TOOLS`, `RT > RT-PROVIDERS`, `CLI > CLI-UI`, `CLI > CLI-SCREENS`, `TAC > TAC-BACKENDS`, `TAC > TAC-KINDS` | rows of tables that are the body of one statement (CS.3, CR.40, CS.7, CT.1, CS.12, CU.6, CU.11, CA.26, CM.2) and the numbered steps of CI.6 and CV.12 | the id of that statement. |
| `TAC > TAC-JOBS` | the two rows of the table of jobs | CA.1 and the area codes the rows name. |
| `TAC > TAC-WEBWORK` | the sentence "Webwork does not need leases, endpoints, the GitHub backend or messages between runtimes for its messaging." | the section chain and its source (S3). Borderline: a statement about another product's needs, not a requirement on this one. |
| `NFR > NFR-TOPO` | "T1 to T5 and T8 belong to the first version; T6 and T7 are later" and the paragraph on T6 after the table | D-51 (T8), D-52 and L-5 (T6), L-1 and D-35 (T7). |
| `PAR > PAR-APPROACH` | the introduction ("All of the approach is decided …") | D-55. |

## 4. Result

**Pass.** Every item the Blueprint will need to cite has an id, or is the
body of a statement that has one. Borderline, recorded and not a failure: the
table of the tooling's mappers and emitters in `NFR > NFR-GEN` and one
sentence each in `NFR > NFR-GEN` and `TAC > TAC-WEBWORK` can be cited by
their section only; none of them states something about the product.

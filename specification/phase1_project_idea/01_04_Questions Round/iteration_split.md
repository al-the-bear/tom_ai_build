# Iteration split — Phase 1, question round 4

The Project Idea has 2,737 lines after the marks of round 3 were accepted. The round takes in ten
answers (PQ-24 … PQ-33, `answers.md`), the input of four other quests and an independent
consistency read (the four input files below, 276 findings). The earlier split by section is
kept, with two changes: `RT` and `TAC` are each cut in two (they grew, and most findings land
there), and a triage todo runs first, because several answers and inputs cut across every part
and must be decided once, not per part.

| Input file | From | Findings |
| --- | --- | --- |
| `inputs_vscode_extension.md` | open and recently archived todos, documents of `vscode_extension` | VX-1 … VX-57, and "Specifically for PQ-24" |
| `inputs_al_the_bear.md` | `al_the_bear`: `ai_format_migration.md` (the `_ai` restructuring, three quest types), fleet todos | A-1 … A-15, Q-1 … Q-14, AB-1 … AB-27 |
| `inputs_webwork_tom_forge.md` | `webwork`, `tom_forge` | WW-1 … WW-22, TF-1 … TF-15, the web runtime service |
| `consistency_read.md` | a full read of the Project Idea | IC-1 … IC-34, AN-1 … AN-46, GA-1 … GA-30, ST-1 … ST-18, ID-1 … ID-10 |

| Todo | Part (section ids) | Lines (at planning) |
| --- | --- | --- |
| `p1s1r4-1` | triage: every finding and answer assigned to a part, with what is done with it → `triage.md` | — |
| `p1s1r4-2` | `ABOUT`, `SRC`, `VIS`, `USR`, `SCO`, `LAND` | 1–205, 328–473 |
| `p1s1r4-3` | `RT-HOLDS` … `RT-INSTALL` | 474–759 |
| `p1s1r4-4` | `RT-SECRETS` … `RT-PROVIDERS` | 760–1087 |
| `p1s1r4-5` | `CLI` | 1088–1331 |
| `p1s1r4-6` | `TAC-JOBS`, `TAC-COORD`, `TAC-BACKENDS` | 1332–1580 |
| `p1s1r4-7` | `TAC-PEOPLE` … `TAC-WEBWORK` | 1581–1978 |
| `p1s1r4-8` | `PAR` | 1979–2189 |
| `p1s1r4-9` | `NFR` (with `NFR-TOPO`, `NFR-GEN`) | 2190–2432 |
| `p1s1r4-10` | `DEC`, `CON`, `RISK`, `DEL` | 2433–2737 |
| `p1s1r4-11` | `GLO` and the whole document: the cross-check, the settled questions removed, the new ones inserted, the terminology document | 206–327, all |

`p1s1r4-10` runs after the parts it summarises; `p1s1r4-11` last. The parts 2–9 depend only on
the triage.

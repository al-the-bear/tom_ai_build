# Iteration split — Phase 1, question round 5

The Project Idea has 3,277 lines after round 4's marks were accepted. The round has no answers to
take in; it reworks the document and its 26 open questions (PQ-34 … PQ-59) on the product owner's
two instructions (`answers.md`): (a) the feature baseline of the first version from the extension,
Webwork and this quest's own todos and documents; (b) a second extension in `ai_build` in place of
the in-place split. The input is three inventories:

| Input file | From | Findings |
| --- | --- | --- |
| `inventory_vscode_extension.md` | the extension's docs, `package.json`, open and archived todos, progress, design documents (state 2026-11-25) | 321 features (63 not covered), "distributed and with a team" per area, gaps, the v2 section |
| `inventory_webwork.md` | Webwork's todos, decisions of 2026-11-25, its review and messaging parts | team review and review bundles (24 comparison rows), 22 further needs, 6 questions (PQ-W1 … PQ-W6) |
| `inventory_ai_runtime_quest.md` | this quest's todos and documents; the second extension | AR-1 … AR-84, V2-1 … V2-29 |

The previous round's input files in `../01_04_Questions Round/` stay valid where these do not say
otherwise.

The cut of round 4 is kept: a triage first, the parts, then decisions and the cross-check.

| Todo | Part (section ids) | Lines (at planning) |
| --- | --- | --- |
| `p1s1r5-1` | triage: every finding and every open question ruled once, per part → `triage.md` | — |
| `p1s1r5-2` | `ABOUT`, `SRC`, `VIS`, `USR`, `SCO`, `LAND` | 1–258, 447–633 |
| `p1s1r5-3` | `RT-HOLDS` … `RT-INSTALL` | 634–1074 |
| `p1s1r5-4` | `RT-SECRETS` … `RT-PROVIDERS` | 1075–1410 |
| `p1s1r5-5` | `CLI` | 1411–1729 |
| `p1s1r5-6` | `TAC-JOBS`, `TAC-COORD`, `TAC-BACKENDS` | 1730–1993 |
| `p1s1r5-7` | `TAC-PEOPLE` … `TAC-WEBWORK` | 1994–2389 |
| `p1s1r5-8` | `PAR` | 2390–2651 |
| `p1s1r5-9` | `NFR` (with `NFR-TOPO`, `NFR-GEN`) | 2652–2921 |
| `p1s1r5-10` | `DEC`, `CON`, `RISK`, `DEL` | 2922–3277 |
| `p1s1r5-11` | `GLO` and the whole document: cross-check, the final question set in place, the terminology document | 259–446, all |

`p1s1r5-10` runs after the parts it summarises; `p1s1r5-11` last. The parts 2–9 depend only on
the triage.

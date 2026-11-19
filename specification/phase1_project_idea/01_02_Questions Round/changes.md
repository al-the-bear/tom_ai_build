# Changes — Phase 1, question round 2

The round took the product owner's 19 answers of 2026-11-19 (in `answers.md`)
into the Project Idea, after gate G1's run 1 had failed on them (G1-CLAR-1;
todo `phasetodosone2_aksr-second-question-round-answers-taken-in`). The
snapshot sources were not changed. The changes are written directly, not as
inline marks: the Project Idea is free-form Markdown, and its diff against the
previous commit shows them.

## Each answer and what it did

| Question | Answer in short | In the text |
| --- | --- | --- |
| PQ-1 | the owner and only reviewer is alexis | `USR > USR-TEAM` (table of the team); `ABOUT`; D-44. The display name is asked in PQ-22. |
| PQ-2 | (a), taking over is the usual case | `RT > RT-RUNS`, CR.12; D-46 |
| PQ-3 | (a) | `RT > RT-RUNS`, CR.13; D-46 |
| PQ-4 | not this product's; a proposal in tom_specs | CR.14 rewritten (the engine carries any process); `SCO > SCO-OUT`, O-9; D-48. **Filed:** `tom_specs`, todo `smallchange1_akss-short-change-process-proposal` (decision-needed, three decisions). |
| PQ-5 | asked back (read as the ways of asking) | asked again in plain terms as **PQ-21**; CP.7, CP.8 and CR.45 stay proposals until it is answered; CP.8 says the ways of asking stay |
| PQ-6 | five rules on installing, updating, too new, too old, migration and downgrade | `RT > RT-INSTALL`, CR.42; `RT > RT-VERSIONS`, CP.28, CP.31 to CP.34; D-49; contradiction X-13 (which runtime a host starts) |
| PQ-7 | (b) all nine languages | `CLI > CLI-PACK`, CL.1; D-50; risk R-24 |
| PQ-8 | no fixed order; two runs in parallel; check the extension's todos | `DEL` (the order of building); D-45. **Checked** in `vscode_extension` (below). **Filed:** `vscimpb179_akss-blocked-item-resumes-by-itself`. |
| PQ-9 | (b) the phone in the first version, the internet case, pairing | `CLI > CLI-TRC`, CK.10 to CK.12; `RT > RT-INSTALL`, CR.46; `NFR > NFR-TOPO`, T8; `SCO > SCO-LATER`, L-6 and L-8 narrowed; `TAC > TAC-CRYPT`, CI.18; N-21; D-51; X-14; risk R-22 |
| PQ-10 | (a) the GitHub backend stays | `TAC > TAC-BACKENDS`, CA.26; D-47; X-11 resolved |
| PQ-11 | asked for an explanation | `TAC > TAC-PEOPLE > TAC-GROUPS` explains the agent group; asked again as **PQ-20**; the glossary entry rewritten |
| PQ-12 | (a), last row depends on PQ-11 | `TAC > TAC-PEOPLE`, CI.5 (the table of rights; the row on agent groups open with PQ-20); D-53 |
| PQ-13 | a setting of the server; strict from the internet | `TAC > TAC-PEOPLE`, CI.10; D-54; D-25 points to it. The owner's own question (is HTTPS with the token enough) is `TAC > TAC-CRYPT`, CI.19: reasoned and handed to the Blueprint's security model as an open point. |
| PQ-14 | (a), with a strict mode | `PAR > PAR-APPROACH` (the introduction; CW.5); D-55 |
| PQ-15 | (a), pub.dev and the binaries repository for now | `NFR`, N-29; D-56 |
| PQ-16 | (a); a server hosting one runtime per client is in the model | `NFR > NFR-TOPO` (T6 later, the paragraph after the table); CR.46; D-52; X-12 resolved |
| PQ-17 | decided at the start of Phase 4 | `NFR > NFR-GEN` (how the units are produced); D-57, D-36; risk R-23 |
| PQ-18 | decided in Phase 4; API documentation and guides | `NFR > NFR-GEN`; N-30; D-57 |
| PQ-19 | (c) the TomSpecs process with all its phases | D-36 and D-37 rewritten; X-7 resolved; `DEL` (the documents of the specification) |

## Questions asked in this round

| Id | Asks | Blocks the Blueprint? |
| --- | --- | --- |
| PQ-20 | who creates an agent group and which runtimes may join it (after the explanation of what an agent group is) | yes, for its information model and security model, until answered |
| PQ-21 | the three shapes of the runtime's protocol, in plain terms | no: detail of the interface specification |
| PQ-22 | the display name in the review team | no: a default is proposed |

## The check in the vscode_extension quest (PQ-8)

Asked: is "waiting when a todo is blocked and continuing once it is
unblocked" covered by the todos queued, open or done on 2026-11-19?

- **Waiting: covered, and built.** Before a todo's prompt goes out the queue
  reads its blockers; an open blocker holds the item, pauses its run and
  tells the user (user guide of the extension, § The prompt queue, *A blocked
  todo holds the item*; guideline `quest_todos.md`, *The queue holds at a
  blocked todo*). Blocked todos follow their blockers across quests.
- **Continuing: by hand only.** "Complete the blocker and resume the run": a
  held item stays held, and its run paused, until the user resumes it. No
  open todo, no todo completed on 2026-11-19 and no queued item covers a run
  that goes on by itself. The owner's prompt of 2026-11-19 18:16 to that
  quest asks for stopping a held item and for a "continue" that skips it,
  which is a different thing.
- **Filed:** `vscimpb179_akss-blocked-item-resumes-by-itself` in
  `vscode_extension`: a held item goes back to pending, and its run goes on,
  when its blocker is completed anywhere; a run the user paused stays paused.

## Also changed

- Ids `G-`, `SC-` and `P-` for the generation units, the screen inventory
  and the problems (todo `phasetodosone1`, before this round).
- New ids: CR.46; CP.31 to CP.34; CK.10 to CK.12; CI.19; O-9; D-44 to D-57;
  X-13, X-14; R-22 to R-24. No id was removed or renumbered.

## After the review of this round

| Question | Answer in short | In the text |
| --- | --- | --- |
| PQ-22 | (a) | `USR > USR-TEAM`: member id `alexis`, display name Alexis, role Product owner; D-44 |
| PQ-21 | an API with callbacks over a JSON wire protocol; object models from the existing schemas; unloading reasonable but perhaps not worth it | CP.35 (new); CP.7 and CP.8 stay proposals for the interface specification; CR.45 an option, not first version; D-58. Not a blocker: detail of the interface specification. |
| PQ-20 | "I don't see any groups of agent here" — the term was read as groups of agents calling models | the explanation in `TAC > TAC-PEOPLE > TAC-GROUPS` rewritten around what the term names (one shared list of leases); asked again as **PQ-23**, with the team as the recommended answer; the glossary entry rewritten |
| PQ-23 | (a) the team is what its runtimes coordinate in; resources are named (a repository, or a part by a pattern), tac knows only what it granted; a runtime works with what its user can reach; a todo for another quest is filed where that quest can be reached | `TAC > TAC-PEOPLE > TAC-GROUPS` (CA.39 to CA.43); "agent group" replaced by the team throughout (CA.2, CA.3, CA.6, CA.9, CA.11, CA.16, CA.18, CA.30, CA.32 to CA.34, CI.1, CI.2, CI.5, CW.13, N-12, T3, F11, the glossary); D-24, D-53, D-59; X-5, X-15; a new capability on filing todos in other quests in `PAR > PAR-CROSS` |

No question is open after this.

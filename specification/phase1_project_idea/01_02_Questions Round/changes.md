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

## The consistency read

An independent read of the whole Project Idea against the 23 answers in
`answers.md`, after the scripted taking-in (todo
`p1s1r2-1_akst-consistency-read-after-answers`), together with the
borderline findings of gate G1's run 1
(`quality/evidence/gates/G1_20261119-1317/`).

### Corrected against an answer

| Statement | It said | It says now | Answer |
| --- | --- | --- | --- |
| `VIS > VIS-SYSTEM`, the row of trc | a Webforge application that also runs standalone | also on the phone and the tablet in the first version | PQ-9 |
| `VIS > VIS-SYSTEM`, the hosts | the extension, Webforge and Webwork | also the supervision application; for a phone or tablet the host is a server running one runtime per client | PQ-9, PQ-16 |
| V-7 | supervision from one place | also from a phone or a tablet while away | PQ-9 |
| U-3 | creates a team | creates a team on a server they have joined | PQ-20 |
| U-5 | from one place | at the desk, and from a phone or a tablet | PQ-9 |
| U-7 | sets the server up, creates the first team | sets whether the server is open or strict; creates the first customer and its access key | PQ-13, PQ-20 |
| `GLO`, host | three applications | also the supervision application and a server that runs one runtime per client | PQ-9, PQ-16 |
| `GLO`, unit | "a declared part of a repository that can be claimed on its own" | replaced by **resource**: a whole repository or a part by a pattern, named when asked for, registered nowhere | PQ-23 |
| `SCO > SCO-IN`, `CA` | leases and units | leases on named resources | PQ-23 |
| `SCO > SCO-IN`, `CI` | — | the open or strict server and the pairing of devices named | PQ-13, PQ-9 |
| `SCO > SCO-IN`, `CK` | trc | trc on the desktop, the phone and the tablet | PQ-9 |
| L-5 | CQ-4 | CQ-4 and PQ-16 | PQ-16 |
| `TAC > TAC-JOBS`, the table; the sub-heading in `TAC > TAC-COORD` | leases, units | leases on named resources; "Leases, resources and fencing tokens" | PQ-23 |
| CA.3 | a runtime registers the repositories it coordinates | the same, with the sentence that this is what the runtime says about itself and not a list tac grants from | PQ-23 |
| CA.23 | "the others of the agent group" | "the others of the team" | PQ-23 |
| CA.26, the GitHub row; X-11 | leases, sessions, units and endpoints | leases, sessions and endpoints | PQ-23 |
| CA.30 | a key per runtime that an owner issues | the same, and: what comes through the relay is strict and from a paired device; how the two keys relate is part of the open point CI.19 | PQ-9, PQ-13 |
| `TAC > TAC-WEBWORK`, WR-2 | identification is one of the two levels | on a server set to open | PQ-13 |
| `TAC > TAC-WEBWORK`, WR-6 | the server-side runtime as later ("until that exists") | the server-side runtime is in the first version; Webwork's own server side is later | PQ-9 |
| `TAC > TAC-WEBWORK`, last sentence | leases, units, endpoints | leases, endpoints | PQ-23 |
| CL.4 | the convenience layer is written by hand | the same, and: which generator writes what is named at the start of Phase 4 | PQ-17 |
| N-19 | "the VPN is the boundary today: inside it, identification … is accepted" | a setting of the server; strict as soon as others use it; always strict from the internet | PQ-13 |
| T5 | the server's public address over TLS | with strict identity and from a paired device | PQ-9, PQ-13 |
| F1 | the host finds the installed runtime and starts it | it installs the one it carries only when none is installed; a host that finds the runtime too new switches the features off or does not start | PQ-6 |
| F12 | a host installs a new version; a migration runs | after the user asked for it; the migration only when the user confirmed; an older format: migrate or go back | PQ-6 |
| D-14 | "every host installs the version it was built with" | removed; points to D-49 | PQ-6 |
| D-59 | — | also: a person joins a server and then creates a team (PQ-20) | PQ-20 |
| R-12 | seven client packages tested only through the suite | six | PQ-7 |
| R-13 | a host with an older runtime stops when the files are migrated | one shared runtime per machine; a host too old switches off; across machines and people the files are shared through git (the gate's remark on the team case) | PQ-6 |
| `DEL`, first heading | "The order." | "What comes before the building." (the three preconditions of D-40; no order of building) | PQ-8 |
| `DEL`, the runtime track | "… then the tac client inside the runtime" | without "then"; a sentence that no order is fixed inside and between the tracks | PQ-8 |
| `DEC`, the heading of the last table | decisions of the first question round, `PQ-1` … `PQ-19` | decisions from the answers to `PQ-1` … `PQ-23` | — |
| X-15 | "the answer to the question on what runtimes share" | "the answer to PQ-23" | — |

**New statements:** CI.20 (a team belongs to a customer; whoever installs
the server creates the first customer and its access key; with it a person
joins the server, creates a team and is its first owner: PQ-20, DQ-2); the
glossary entries **resource**, **strict mode**, **open server, strict
server** and **pairing**; an opening sentence of
`TAC > TAC-PEOPLE > TAC-GROUPS`, so the subsection reads as part of its
section.

**Found consistent, not changed:** `LAND` (E-3 names units as what is built
in `tac/1.0`, which is a fact about today), `RT > RT-RUNS`, `RT > RT-INSTALL`,
`RT > RT-VERSIONS`, `TAC > TAC-PEOPLE` (CI.5, CI.10, CI.18),
`PAR > PAR-APPROACH`, `NFR > NFR-GEN`, the rest of `DEL`.

### Sources added (the gate's borderline findings)

- **L-2 … L-11:** `S1 § 11.1` in each row, beside the decision.
- **T1 … T8:** a column Source, `S1 § 8` (T5 also PQ-9, PQ-13).
- **F1 … F12:** a column Source, `S1 § 9` (F1 and F12 also PQ-6).
- **A place for the five that named a whole document:** O-2 (S3, "Why
  Webwork needs it, and when" and WR-7; S14, part two, § 5), E-6 (S15: the
  protocol document § 5; the idea document, part-clients), E-7 (S16, § 1 …
  § 6 and "What enforces what"), E-13 (S8, section `input`), CS.17 (S7, "How
  the runtime reaches a model today").
- **S10** is now cited: `CON` opens by saying that S10 § 6 lists four of the
  contradictions (X-1, X-8, X-9, X-10).
- **The in-scope row "The split"** names what covers it: D-40, D-41; N-32,
  N-33; R-1; `DEL`.
- **X-6:** "the earlier plan" is tied to its source (the todos S1 § 7.10
  describes).

### Moved

- **CP.35** from `RT > RT-VERSIONS` into `RT > RT-PROTO`, after CP.10; the
  note "(belongs to …)" removed.
- **CR.46** behind CR.45.
- **D-57** before D-58; **X-14** before X-15.
- **R-22 … R-24** stay after the table of R-1 … R-14 and before the
  dependencies, with their note: moving them into number order would put
  risks into the table of dependencies.

### Checked

- 70 headings with an id, none twice; every section-id chain names headings
  that exist, as parent and child, on one line.
- Ids unique and without gaps in every kind. Three kinds have statements
  outside number order by their place, on purpose: CA.39 … CA.43 stand in
  `TAC > TAC-PEOPLE > TAC-GROUPS`, CI.20 in `TAC > TAC-PEOPLE` before
  CI.16 … CI.19 of `TAC > TAC-CRYPT`, CP.35 in `RT > RT-PROTO`.
- The head's status line: round 2 closed, every answer in the text, the text
  read as a whole; no question open.

### Questions

None. One point the read met is not a question to the product owner: how the
relay's key per runtime (FO-9) and the paired device's key (PQ-9) relate. It
is named in CA.30 and belongs to the open point CI.19, which the security
model of the Solution Blueprint decides.

# Changes — Phase 1, question round 4

One section per part todo: what it applied, asked and dropped, and what it leaves for the other
parts. Form: `round_instructions.md` § At the end of your todo.

## The round as a whole

Written by `p1s1r4-11` on 2026-11-25, after the part todos `p1s1r4-2` … `p1s1r4-10`. The
sections below this one are the parts' own records; this summary says what the round did.

**State of the Project Idea after the round:** every answer of `PQ-1` … `PQ-33` is in the text;
the question blocks `PQ-24` … `PQ-33` are removed; 26 questions are open, `PQ-34` … `PQ-59`,
each standing directly after the item it concerns. The glossary (`GLO`) and the terminology
document (S21, § 2) carry the round's terms and are equal in content. All marks of the round
are well-formed (1,155 marks in the document, none nested, none broken).

### What each answer changed

| Answer | Decision | What it changed |
| --- | --- | --- |
| PQ-24 (b) | D-61 | One waiting rule: while an ask of a run is open, the run waits; nothing further is sent from its queue until the ask is settled; a walk does not go on with another todo; the words "waits", "is held", "paused" kept apart. CP.21, CP.9, CP.22, CR.17, CR.20, CR.23, CR.67, CS.10, CW.4, N-15, D-20, F4, F5, `GLO` ask, run, execution and the further terms. Its second part made S22 the standard for the `_ai` state and for quests (D-71). |
| PQ-25 (a) | D-62 | A session is started over, not replaced: CR.18, CP.3, CP.7, the session lifetimes CR.75 … CR.78, `GLO` session. |
| PQ-26 (a) | D-63 | The tac client SDK is for runtimes and command-line programs of ours, for no application and no server: CL.11, CL.12, CR.110, `GLO` client SDK. |
| PQ-27 (a) | D-64 | tac keeps no holder record; a lease names its holder (runtime, quest, run, item, machine, workspace): CA.5, CA.8, CA.20, CA.26, CA.29, CA.36, X-11, `GLO` holder. |
| PQ-28 | D-65 | The names web runtime service and web runtime client SDK (Dart, JavaScript / TypeScript): CR.108 … CR.110, CL.11, CL.12, CI.4, T8, F13, G-8 … G-10, `GLO` host, server, client SDK and the further terms. What it is, is asked: PQ-38, PQ-41, PQ-49. |
| PQ-29 | D-66 | The GitHub backend also serves simple teams of several members; the personal team is the local backend's and the single-member case of the GitHub backend: CA.26, CA.39, CI.1, T3, T4, X-11, D-47, `GLO` team, personal team, backend. What such a team has and who belongs to it is asked: PQ-47. |
| PQ-30 (a) | D-67 | No review application in this product; every application through its runtime: O-10, L-12, CI.4, CA.28, CV.5, CV.15, P-3, U-2, `GLO` application, host, user. Where the review component is built is asked: PQ-43. |
| PQ-31 (a) | D-68 | Resource names carry a prefix, `git:` for now: CA.9, CA.10, CA.11, CA.17, CA.41, CA.42, CW.7, X-15, D-59, `GLO` resource, resource name, overlap. The details of the grammar are asked: PQ-45. |
| PQ-32 (a) | D-69 | "Pairing" for devices only; programs are approved by Tom Secrets Manager: CS.9, U-7, D-19, N-30, `GLO` device / pairing, approved by. |
| PQ-33 (a) | D-70 | The table "Further terms of this document" in `GLO` (39 entries, with "profile" and "coordinator") and the same in S21 § 2.6. |

### What came in from each input

As the triage ruled them (`triage.md` § 5); where a part did otherwise, its section says so under
"Done otherwise than the row says".

| Input file | Findings | Applied | Asked | Dropped |
| --- | --- | --- | --- | --- |
| `consistency_read.md` (the consistency findings IC, AN, GA, ST, ID) | 138 | 77 | 57 | 4 |
| `inputs_vscode_extension.md` (VX, and the section on PQ-24) | 57 + 1 | 48 + 1 | 7 | 2 |
| `inputs_al_the_bear.md` (A, Q, AB) | 56 | 39 | 11 | 6 |
| `inputs_webwork_tom_forge.md` (WW, TF, and the section on the web runtime service) | 37 + 1 | 21 | 14 + 1 | 2 |
| **Total** | 290 | 186 | 90 | 14 |

The 90 findings ruled "ask" are settled by the 26 questions below (several findings per
question). The consistency findings settled in the text: 77 applied by the parts, among them
the glossary findings of `p1s1r4-11`; the answer consequences AN-1 … AN-46 were checked against
the text by `p1s1r4-11` (one partly applied, AN-10, is recorded in its section).

### The questions asked

| Id | Place | Topic |
| --- | --- | --- |
| PQ-34 | `RT > RT-HOLDS`, after CR.1 | who writes and commits `_ai` files besides the runtime |
| PQ-35 | `RT > RT-HOLDS`, after CR.5 | features of the extension: the runtime's or the VS Code host's own |
| PQ-36 | `RT > RT-HOLDS`, after CR.6 | two hosts on one quest (and forwarding a host tool to another host) |
| PQ-37 | `RT > RT-INSTALL`, after CR.40 | Node for a host that is not VS Code, and the Agent-SDK-only mode |
| PQ-38 | `RT > RT-INSTALL`, after CR.46 | what the web runtime service is |
| PQ-39 | `RT > RT-ASKS`, after CP.21 | leases and chat sends while a run waits for an ask |
| PQ-40 | `RT > RT-VERSIONS`, after CP.29 | when a migration of the workspace files runs |
| PQ-41 | `CLI > CLI-PACK`, after CL.12 | what the web runtime client SDK is beside the runtime client SDK |
| PQ-42 | `CLI > CLI-PACK`, after CL.1 | TypeScript and JavaScript: one client SDK or two |
| PQ-43 | `CLI > CLI-UI`, after CU.9 | where the review component is built, and in which form |
| PQ-44 | `CLI > CLI-UI`, after CU.5 | the Flutter view packages that exist beside the new UI components |
| PQ-45 | `TAC > TAC-COORD`, after CA.10 | how resources and the other addressed things are written |
| PQ-46 | `TAC > TAC-COORD`, after CA.11 | the lease rules: integration lease, fencing at the push |
| PQ-47 | `TAC > TAC-BACKENDS`, after CA.26 | a team on the GitHub backend: what it has, and who is a member and a team owner |
| PQ-48 | `TAC > TAC-BACKENDS`, after CA.31 | what "coordination off" switches off, and what the local tac service is |
| PQ-49 | `TAC > TAC-CRYPT`, after CI.18 | phones and tablets: which program faces the internet, pairing, and how a person away is reached |
| PQ-50 | `TAC > TAC-PEOPLE`, after CI.13 | one model for remote control and for tac's credentials |
| PQ-51 | `TAC > TAC-PEOPLE`, after CI.2 | a runtime that serves no quest, and its team |
| PQ-52 | `TAC > TAC-CONV`, after CM.7 | where the cache and the outbox of a user's messaging live |
| PQ-53 | `PAR > PAR-QUESTS`, after CQ.2 | where a person's own files of a quest lie |
| PQ-54 | `PAR > PAR-QUESTS`, after CQ.6 | what remains of member branches, the internal repository, the secret scan and member access |
| PQ-55 | `PAR > PAR-QUESTS`, after CQ.7 | who carries the quest operations, a quest inside a project's repository, quests worked on from a server |
| PQ-56 | end of `NFR` | numbers the Solution Blueprint needs and no source gives |
| PQ-57 | `DEL`, after the line that names it | delivery: what "finished" is checked against, and a first usable state |
| PQ-58 | end of `GLO` | words the document uses in several senses |
| PQ-59 | end of `ABOUT > ABOUT-READ` | the structure of the Project Idea in the next round |

### The improvement ideas proposed as questions

| Idea | Proposed in | As |
| --- | --- | --- |
| ID-1 one register "what the first version contains" | PQ-59 | part of the recommended option |
| ID-2 the lease rules as one matrix | PQ-46 | the recommended option |
| ID-3 a table of credentials | PQ-50 | part of the recommended option |
| ID-4 one grammar for everything that is addressed | PQ-45 | the recommended option |
| ID-5 one capability table per backend | PQ-47 | the recommended option |
| ID-7 a first usable state inside "one go" | PQ-57 | the recommended option |
| ID-8 a record of what people did to others' runs | PQ-50 | part of the recommended option |
| ID-9 TypeScript and JavaScript as one client SDK | PQ-42 | the recommended option |
| ID-10 trace every capability to whom it serves | PQ-59 | part of the recommended option |

ID-6 (a held or waiting run says so everywhere) was applied, not asked.

## `p1s1r4-2` — `ABOUT`, `SRC`, `VIS`, `USR`, `SCO`, `LAND`

Marks written: 134 additions, 26 substitutions, 2 deletions. No question was written by this
part (its two rows ruled **ask** are written by `p1s1r4-7` and `p1s1r4-3`).

### Rows of the work list

| Finding | Ruling | Done | Items changed or added |
| --- | --- | --- | --- |
| AN-34 | apply | applied | new **O-10** (`SCO > SCO-OUT`): no review application of its own; new **L-12** (`SCO > SCO-LATER`): services that use tac directly, not planned |
| AN-37 | apply | applied | U-8, U-10, O-1: messaging is in Webwork in the first version; the extension gets it once the runtime is built, its views are its own |
| IC-3 | apply | applied | O-6: the second exception (the fast-forward of CW.16), and pull / push of the `_ai` state and a quest's repository as steps the user starts. F11 is `p1s1r4-9`'s |
| IC-13 | apply | applied | `VIS > VIS-SYSTEM`, the paragraph on hosts: hosts listed as programs; a host may start several runtimes |
| IC-14 | apply | applied | U-9: "from the start" |
| IC-22 | apply | applied | L-11: what is later (billing, one tac server for several organisations) and what the first version has |
| IC-25 | ask QT-4 (`p1s1r4-7`) | text until answered written | L-6 and the lead-in of `SCO > SCO-LATER`: not decided as deferred, an open point |
| IC-32 | apply | applied | E-1 (`tom_vscode_scripting_api` 6.0.0), E-2 (`tom_todo_model` 4.2.0), E-3 (0.1.0, 40 tests: checked, stands), E-6 (`tsm` 0.2.7, six further client libraries), new **E-21** (`tomspecs` 0.17.0) |
| IC-33 | apply | applied | `ABOUT` status and the `PQ` row of `ABOUT > ABOUT-READ`: no round is counted; the answers are named by their folder |
| GA-22 | apply | applied | new **U-14** (a developer of an application for a phone, a tablet or a browser), **U-15** (the coordinator of a review round), **U-16** (a quest member); U-2 (which application a reviewer uses); U-6 points to U-14 |
| GA-25 | apply | applied in `SRC` | the sentence on which source wins: a `PQ` answer over every source; S22 the standard. CQ.5 and the screen inventory are other parts' (below) |
| GA-30 | ask QT-18 (`p1s1r4-3`) | nothing changed | the row on the split in `SCO > SCO-IN` keeps "no area of its own" |
| ST-1 | apply | applied | `ABOUT` status; the `PQ` row. The decisions D-61 … are `p1s1r4-10`'s |
| ST-11 | apply | applied | a paragraph in `ABOUT > ABOUT-READ`; the rows S4, S6, S13, S18, S19, S21 explain their ids |
| ST-18 | apply | applied | `VIS > VIS-SYSTEM`: the lead-in counts nothing; the row tac names its two programs; a new row "Web runtime service"; the row of the client SDKs names the web runtime client SDK |
| VX-54 | drop | dropped | nothing to change: L-9 stands |
| A-1 | apply | applied | new source **S22**; the standing of S2 and S12 |
| A-11 | apply | applied | O-4: the "VS Code LM" transport stays in the extension until the Copilot SDK route works |
| Q-13 | apply | applied | E-14: no `_ai/quests.yaml`, nothing of format version 10 built, no list of a workspace's quests |
| AB-12 | apply | applied | E-5: the merge drivers' source is the fleet's; built into the binaries repository |
| WW-17 | apply | applied | L-8: wave 3 of Webwork, AI and messaging, the web runtime service; U-10 |
| WW-20 | apply | applied | E-2. R-18 is `p1s1r4-10`'s |
| TF-7 | apply | applied | U-9: every application composed from Tom Forge's composition library is such a host |

### Findings that also reach this part

| Finding | Done here |
| --- | --- |
| AN-8, A-2 | `SRC` (S22), `SCO > SCO-IN` rows `CR` and `CQ`, E-14 |
| AN-17, ST-3 | new **E-19** (`LAND > LAND-BUILT`): what `tac/1.0` has that the product does not use; E-3 keeps its parenthesis; O-4 loses "are removed" |
| AN-19, AN-26 | `ABOUT` status, the row trc of `VIS > VIS-SYSTEM`, the row `CK` of `SCO > SCO-IN`, V-7: phones and tablets through the web runtime service, named as open |
| AN-20, AN-25, WRS | "web runtime service" everywhere in the part; L-5, L-8 |
| AN-21 | V-3 ("the tac server's relay"), the row `CA` of `SCO > SCO-IN` |
| AN-22, IC-34 | the row of the client SDKs in `VIS > VIS-SYSTEM` (with PQ-7), the row `CL` of `SCO > SCO-IN` |
| AN-27 | U-14 (instead of a change of U-6), E-9, E-10 |
| AN-32 | U-3, U-11, E-17, the row `CA` of `SCO > SCO-IN` |
| AN-36, WW-18 | U-2, V-5 |
| AN-43 | U-7: "approved by" |
| AN-45 | the row S21 of `SRC` (the ids `C-n`) |
| IC-30 | `SCO > SCO-IN`: the Agent Client Protocol in the row `CR`; the row `CI` cites PQ-12, PQ-20, PQ-23 |
| GA-11, AB-9, Q-10 | O-6 |
| GA-18 | `USR > USR-TEAM`: the sentence on e-mail addresses |
| VX-33, VX-36, VX-38, VX-39, VX-40, VX-41, A-10 | E-1 (the todo's fields, the two kinds of group, reminders after a wait as leaving), E-2 (the done notification has no default) |
| VX-45 | E-1 (format version 9 today), E-5 |
| AB-3 | E-4: guidelines on three levels |
| AB-11 | E-17 |
| WW-19 | new **E-20** (`LAND > LAND-BUILT`): `tom_agentic_ui`, `tom_ai_trail_ui`, `tom_todo_ui`; E-10 |
| WW-22, TF-1, TF-10 | E-15, E-16 (`LAND > LAND-WAIT`) |
| AN-41, IC-12, GA-1, GA-6, GA-17, GA-23, GA-24, ST-5, ST-7, ID-1, ID-10, VX-55, Q-1, Q-3, AB-10, AB-14, WW-11, TF-2, TF-9, TF-14 | nothing to write in this part (asked by the owning part, or the text of this part stands) |

### Done otherwise than the row says

- **AN-36, P-3.** P-3 is not changed. It states the problem as it is today (a reviewer without a
  repository gets documents by hand); which application such a reviewer uses is the answer, and
  stands in V-5 and U-2.
- **GA-22, U-6.** The developer who uses the web runtime client SDK is a group of its own (U-14),
  so U-6 keeps its text and points to it.
- **`LAND > LAND-WAIT`, new E-22.** The inputs show a fifth quest that waits: `vscode_extension`
  (the split; messaging once the runtime is built, PQ-30). Added as a row.
- **`VIS > VIS-PROBLEM`, "Why now".** "three future hosts and three other quests" did not match
  `LAND > LAND-WAIT`; it reads "the hosts that are to use it and the quests of `LAND > LAND-WAIT`".

### Obligations changed

| Item | Change | Source |
| --- | --- | --- |
| O-10 (new) | a review application is out of scope, not deferred | PQ-30 |
| L-12 (new) | services using tac directly: possible later, not planned | PQ-30 |
| L-6 | from a decided deferral to an open point | IC-25; CI.19, N-21 |
| L-11 | the first version has accounts, access keys, quotas and the administration interface, used with one account; later are billing and several organisations | D-22 (CQ-9), CA.27 |
| O-6 | a second exception: the fast-forward of CW.16 where a workspace switched it on | CW.16 (S6, BP-12, BP-18) |
| O-4 | the runtime carries neither host transport; in the extension one of them stays for a time | S22 § 2.3, AC-19 |
| `SCO > SCO-IN`, row `CR` | the web runtime service is in scope, with its design open; format version 10 | PQ-28; S22 |
| `SCO > SCO-IN`, row `CL` | a web runtime client SDK in Dart and in JavaScript / TypeScript | PQ-28 |
| `SCO > SCO-IN`, row `CQ` | three quest types with their register, the quest operations | S22 |
| U-9 | trc is a Webforge application from the start | D-5 (FO-12) |

### Sources needed

None beyond the six added. Sources as written in `SRC`: **S22** (the standard for the `_ai`
format and quests in repositories), **S23** (vscode_extension's todos and progress), **S24** (roles
and guideline choices), **S25** (webwork's todos and wave plan), **S26** (tom_forge's todos and
decisions), **S27** (al_the_bear's todos and the workspace layout as built). A todo id is cited
after its source, e.g. `(S23: vscimpb146)`.

### For other parts

- **`p1s1r4-11`**
  - `ABOUT` status and the `PQ` row say "the questions from `PQ-34` on are open": set the final
    ids and the count.
  - `ABOUT > ABOUT-READ`, row `R-<n>`, names the ranges of risks and dependencies
    ("`R-1` to `R-14` and `R-22` to `R-24` are risks"); it needs the new risk of `p1s1r4-10`.
  - `ABOUT > ABOUT-READ`, row `E-<n>` and `U-<n>`: new ids E-19 … E-22, U-14 … U-16, O-10, L-12
    exist; the glossary's entries for "host", "coordinator" and "quest member" should match
    U-15, U-16 and the hosts paragraph of `VIS > VIS-SYSTEM`.
  - The `ABOUT` row "Product" now names the web runtime service with its client SDK; if QT-2 or
    QT-4 take phones and tablets out of the first version, it changes back.
- **`p1s1r4-9`**: the dated `tomspecs` version in `NFR > NFR-GEN` can refer to E-21; F11 follows
  O-6 (IC-3); T-items and flows can cite E-19 for the record names of `tac/1.0`.
- **`p1s1r4-10`**: R-18 gets `tom_todo_model` 4.2.0 (E-2); R-21 can refer to E-21; `DEL` carries
  the messages E-15 and E-16 name (WW-22, TF-1).
- **`p1s1r4-6`**, **`p1s1r4-7`**: the sentences on what `tac/1.0` has and the product does not use
  are in E-19 (session record, units, infrastructure resources, the `_ai` folder as a kind, "agent
  group", "customer"); CA.8, CA.9, CA.16, CA.27 and CA.39 can drop theirs and refer to it.
- **`p1s1r4-8`**: CQ.5's source S22 § 3.1 and the loss of its check mark (GA-25); E-14 names the
  register and the quest operations as not built.
- **`p1s1r4-5`**: the screen inventory's standing (GA-25, ST-2) is not stated in `SRC`; E-20 names
  the three Flutter packages QT-7 asks about, with their versions.
- **`p1s1r4-3`**: E-1 says "format version 9 today; version 10 is decided and not built" and
  "reminders after a wait (they leave with format version 10)"; CR.3 and CR.19 should agree.

## `p1s1r4-3` — `RT-HOLDS` … `RT-INSTALL`

Marks written: 110 additions, 18 substitutions, 1 deletion. New items: **CR.47 … CR.110**,
**CS.19**, **CS.20**. Questions written: **PQ-34 … PQ-38**.

### Rows of the work list

| Finding | Ruling | Done | Items changed or added |
| --- | --- | --- | --- |
| AN-4 | apply | applied | CR.13 (a refusal, not a wait), CR.17 ("the run waits, as for an ask"), CR.20 (waits and interrupts told apart). CS.10 and CW.4 are other parts' |
| AN-6 | apply | applied | CR.23: the seven states, "waits" / "is held" / "paused", published with the registration |
| AN-9 | apply | applied | CR.18 ("start a session over"). `GLO` session is `p1s1r4-11`'s |
| AN-14 | apply | applied | new **CR.110**, marked as assumed until PQ-38 |
| AN-20, AN-25, GA-1, GA-2, WRS | ask QT-2 | **PQ-38** | CR.46 ("web runtime service", its statements marked as assumed), new **CR.108** (what PQ-28 settles), new **CR.109** (what is open) |
| AN-24 | ask QT-2 | **PQ-38** | CR.7, CR.40, new CS.20: "stated for a host on the user's machine" |
| IC-9 | apply | applied | CR.6, CR.7 ("runtime"), CR.40, CR.42 ("runtime installation"; each host starts its own runtime) |
| IC-12, GA-6, TF-6 | ask QT-16 | **PQ-36** | nothing changed (CR.44 keeps its text) |
| GA-4 | apply | applied | new **CR.67**; CR.15's chat sentence unchanged |
| GA-15 | apply | applied | CS.5: what the Solution Blueprint settles |
| GA-28 | apply | applied | CR.22 (the team's allowed providers limit both choices), CR.12 and CS.3 (lines for the Solution Blueprint) |
| VX-6 | apply | applied | new **CR.74** |
| VX-9 | apply | applied | new **CR.85**; CR.20, CR.23 |
| VX-10 | apply | applied | new **CR.72** |
| VX-11 | apply | applied | new **CR.86** (aliveness, limit, the user's choices), **CR.87** (detaching command refused), **CR.88** (the one reminder) |
| VX-12 | apply | applied | new **CR.82** |
| VX-15 | apply | applied | CR.23 |
| VX-16 | apply | applied | new **CR.69** |
| VX-17 | ask QT-1 (`p1s1r4-4`) | text until answered | CR.15 unchanged; the lane rule in CR.67 |
| VX-18 | apply | applied | new **CR.70**, **CR.71**; CR.8, CR.36 |
| VX-19 | apply | applied | new **CR.62** |
| VX-20 | apply | applied | new **CR.75** … **CR.78**; CR.18 |
| VX-21 | drop | dropped | confirms CR.9 |
| VX-22 | apply | applied | new **CR.63** |
| VX-23, VX-37 (the window level), VX-57 | ask QT-18 | **PQ-35** | nothing on the quest refresh and the stored prompt; new **CR.61** without the window level |
| VX-24 | apply | applied | CR.10 (three modes of a decision step), CR.11 |
| VX-25 | apply | applied | new **CR.58** |
| VX-26 | apply | applied | new **CR.64**, **CR.65**, **CR.66**; CR.15 |
| VX-27 | apply | applied | new **CR.80**, **CR.81** |
| VX-28 | apply | applied (planned) | new **CR.83** |
| VX-30 | apply | applied | new **CR.73**; CR.16 (an item being edited is not sent) |
| VX-31 | apply | applied | CR.20, new **CR.89**, **CR.90**, **CR.91**; CR.28 |
| VX-32 | apply | applied | new **CR.92** |
| VX-33 | apply | applied | CR.21, new **CR.93**, **CR.94** |
| VX-35 | apply | applied | new **CR.68** |
| VX-36 | apply | applied | CR.22 (planned), new **CR.95** (built), **CR.96**, **CR.97** (planned) |
| VX-38 | apply | applied | new **CR.49**; CR.66 |
| VX-39 | apply | applied | new **CR.50**; CR.44 |
| VX-40 | apply | applied | new **CR.48** |
| VX-41, A-10 | apply | applied | CR.19 loses the queue's reminders and names those that remain |
| VX-42, A-8 | apply | applied (planned) | new **CR.53** |
| VX-44, A-6 | apply | applied (planned) | new **CR.55** |
| VX-47 | apply | applied | new **CR.56**, **CR.102** |
| VX-52 | apply | applied | new **CR.98**, **CR.105**; CR.36 |
| VX-53 | apply | applied | new **CR.84** |
| VX-55 | apply | applied | CR.4: planned |
| A-2 | apply | applied | CR.3: format version 10 |
| A-3 | apply | applied | new **CR.47** |
| A-5 | apply | applied (planned) | new **CR.79** |
| A-9 | apply | applied | new **CR.54**; CS.3 |
| A-12, AB-25, AB-26 | drop | dropped | as the triage says |
| A-13 | apply | applied | new **CR.106** |
| Q-9 | apply | applied | new **CR.100**; CR.33 |
| AB-1 | apply | applied | new **CR.99**; CR.32 |
| AB-2 | ask QT-15 (`p1s1r4-7`) | text until answered | new **CR.101** (the nested cases); CR.6 keeps "without a quest" |
| AB-3 | apply | applied | CR.33: a project's own guidelines |
| AB-4 | apply | applied | CS.1, new **CS.19**, **CS.20** |
| AB-5 | apply | applied | new **CR.103**, **CR.104** |
| AB-6 | apply | applied | CR.35: the place is for the Solution Blueprint |
| AB-7 | apply | applied | new **CR.59**. The line under CW.3 is `p1s1r4-8`'s (below) |
| AB-23 | apply | applied | new **CR.57** |
| AB-24 | apply | applied | new **CR.51**, **CR.52** |
| WW-9 | apply | applied | new **CR.60** |
| WW-10 | apply | applied | CR.17 |
| WW-11, TF-4 | ask QT-22 | **PQ-37** | CR.29, CR.41, CR.42 keep their text; CR.40 says the source of Node is open |
| TF-9 | ask QT-23 | **PQ-34** | CR.1 keeps its text |

### Findings that also reach this part

| Finding | Done here |
| --- | --- |
| VX-PQ24, VX-2 | CR.17, CR.20, CR.23, CR.67 say "the run waits" and refer to CP.21 |
| VX-3, GA-29, TF-5 | CR.23: a waiting run stays waiting across a restart of its host; CR.74 (resend, skip, stop) |
| VX-4, VX-13, VX-14, IC-4, VX-34 | CR.36 (the open asks of the machine's runtimes, the inbox with CW.19), new **CR.107** (one notification log for the machine, the two classes of CP.4, the answers) |
| VX-5 | CR.74: resend, skip and stop close an open ask unanswered |
| VX-8 | CR.10: a gate's button acts on the run of the prompt that asked |
| VX-29 | CR.48: blockers in other quests and release conditions |
| VX-45, A-1, AN-8, Q-1, VX-46 | CR.3 (format version 10), CR.100 (the three quest types, with CQ.1) |
| VX-50 | CR.40: where the binaries per platform are kept is for the Solution Blueprint |
| AN-10 | CR.21 stands |
| AN-11, AN-23, AN-31, AN-41, IC-16, GA-5, GA-7, GA-9, GA-19, GA-20, ST-3, ST-5, ST-7, ST-9, ST-16, ID-1, ID-6, ID-8, VX-1, VX-43, VX-49, A-4, Q-3, AB-12, AB-20, WW-2, WW-5, WW-7, TF-10, TF-15 | nothing to write in this part (asked or written by the owning part; CR.24, CR.38, CR.45 keep their text) |

### Done otherwise than the row says

- **VX-15, "held" in the order of states.** The row lists six states of which the first that
  applies wins, "and held". The extension shows a run held on a todo's open decisions as waiting
  for the user and a soft interrupt with a mark of its own; no source places "held" in the order.
  CR.23 lists it last and leaves its place to the Solution Blueprint.
- **Q-9, "else those recorded for the folder".** CR.33 loses this middle case: S22 has only "a
  list, else every quest of the register". Listed under Obligations changed.
- **VX-26, the word "claimed".** A todo that an item is bound to is "set to in progress", not
  "claimed": a claim is the attempt to get leases (`GLO`).
- **Lines "what the Solution Blueprint must settle"** are written as a last sentence of their
  item, not as a paragraph under it, so that each stays one mark.
- **CR.108** (a runtime does not run on a phone, tablet or browser; the two names; HTTP-based) is
  not a row of the list. It is what PQ-28 settles (triage § 1.2, points 1 to 4), and CR.46 is the
  only item of `RT` that describes the service.

### Obligations changed

| Item | Change | Source |
| --- | --- | --- |
| CR.17 | the run waits, not "the queue" | PQ-24 (b) |
| CR.18 | a session is started over; no new session is made | PQ-25 (a) |
| CR.19 | the queue sends no reminders | S22 § 2.3 AC-22 |
| CR.20, CR.28 | waits and interrupts are separate; a soft interrupt holds at a tool result and is resumed without resending | S23: vscimpb112, vscimpb82 |
| CR.21, CR.94 | a todo's done notification has no default | S23: vscimpb146 |
| CR.22 | a todo naming its profile is planned; the team's allowed providers limit the choice | S23: vscimpb174; CS.6 |
| CR.23 | seven states instead of three | S23: vscimpb123; PQ-24 (b) |
| CR.33 | the quests of a workspace: its list, else every quest of the register | S22 § 3.4 |
| CR.3, CR.100 | built on format version 10, with the register of quests | S22 |
| CR.53 | memory has one scope, the quest's | S22 AC-17 |
| CR.67, CR.80, CR.81 | a run executes one item at a time; a walk holds at the first todo it cannot run and never skips by itself | S23: vscimpb46, vscimpb37; PQ-24 (b) |
| CR.42 | hosts share the runtime installation, not a running runtime | CR.44; `GLO` runtime |
| CR.46, CR.108 … CR.110 | "web runtime service"; how it works is assumed, not decided | PQ-28, PQ-26 (a) |
| CR.104 | the integration step lands on the branch the record names, never on a read-only or binaries repository | S27 |
| CS.19, CS.20 | where a write goes; one user file per machine and user | S27 |

### Sources needed

None beyond S22 … S27. Cited as: S22 § n / S22 AC-n, CQ-n, QM-n, QJ-1; `(S23: <todo id>)`; S24
(R-n, A-n, L-n); `(S25: <todo id>)`; S27 with the document (`workspace_layout.md` § n,
`workspace_layout_multi.md` § 3, `repos.yaml`, `workspace_agents.md`); S17 for the extension's
user guide ("the user guide § …") and its usage ledger.

### For other parts

- **`p1s1r4-4`**
  - CP.21 is cited by CR.17, CR.20, CR.23, CR.67 as the one waiting rule; CP.4 by CR.107 for the
    two classes of notification; `RT > RT-ASKS` by CR.36 and CR.74 (an ask answered from another
    runtime of the machine; an ask closed unanswered by resend, skip, stop).
  - CS.10: the wording of triage § 1.1 (AN-4).
  - CS.19 and CS.20 are taken in `RT > RT-CONFIG`; new `CS` items of `RT > RT-SECRETS` and
    `RT > RT-PROVIDERS` start at **CS.21**.
  - QT-1 (a chat send while the run waits): CR.15's chat sentence is unchanged and CR.67 states
    the lane rule beside it.
- **`p1s1r4-5`**: CL.5 and F1 follow "runtime installation" (IC-9); CU.6, CU.15, CK.1, CK.9 read
  the states of CR.23 and the item states of CR.69; a component for the journal of asks and
  answers (CR.55) and for the answers (CR.107) is not named in `CLI-UI`.
- **`p1s1r4-6`**: CA.5 carries the state of each run as CR.23 defines it; CA.19 and CR.36 use
  CW.19's words for the inbox.
- **`p1s1r4-8`**
  - CW.7: the list is what the runs use so that only todos whose resources do not overlap are
    executed at the same time (GA-4; a run itself executes one item at a time, CR.67).
  - CW.4: "its run sends nothing else meanwhile" (AN-4).
  - CW.3: a line that the Solution Blueprint settles that an execution in a working tree of its
    own still gets the instruction files of its workspace folder (AB-7; CR.59).
  - CW.5 and `GLO` integration step: "the branch the record names for the repository" (CR.104).
  - CR.55, CR.53 and CR.79 say "per host" and leave the place to QT-9.
- **`p1s1r4-9`**: T8, D-52 and the flows use "web runtime service" and CR.108 … CR.110; T2 and
  N-10 wait for PQ-36; N-24 for PQ-37.
- **`p1s1r4-10`**: D-16 waits for PQ-37; D-17 can name the register of quests (CR.100); R-13
  follows "runtime installation".
- **`p1s1r4-11`**
  - Insert PQ-34 at CR.1, PQ-35 at CR.5, PQ-36 at CR.6, PQ-37 at CR.40, PQ-38 at CR.46.
  - `GLO`: session (PQ-25 (a), with CR.75 … CR.78), runtime / runtime installation, the words
    "waits", "is held", "paused" (CR.23), "staged" (CR.69), "walk continuation" (CR.82), "done
    notification" (CR.93), "journal of asks and answers" (CR.55), "aspect guidelines" (CR.61),
    "register of quests" (CR.100).
  - `ABOUT > ABOUT-READ`: the ranges of `CR` (to CR.110) and `CS` (CS.19, CS.20).
  - The new items stand where they belong by content, so `RT` is no longer in the order of its
    numbers; a renumbering belongs to QT-21.

## `p1s1r4-4` — `RT-SECRETS` … `RT-PROVIDERS`

Marks written: 56 additions, 9 substitutions, no deletion. New items: **CP.36 … CP.44**,
**CT.17**. No new `CS` item. Questions written: **PQ-39** (QT-1), **PQ-40** (QT-12).

### Rows of the work list

| Finding | Ruling | Done | Items changed or added |
| --- | --- | --- | --- |
| AN-1, VX-2 | apply | applied | CP.21: the one rule, in the triage's words; "the rest of the queue" and the walk clause are gone |
| AN-2 | apply | applied | the lead-in of `RT > RT-ASKS`. N-15 is `p1s1r4-9`'s |
| AN-5 | ask QT-1 | **PQ-39** | CP.21 names the point as open; leases stay "for as long as the todo is executed" (CW.5) |
| AN-10 | apply | applied | CP.3 (starting a session over among the session commands), CP.7 (it ends the thread and begins a new one), CS.17 (a new session id of the outside program). CW.11 and CQ.3 are `p1s1r4-8`'s |
| AN-23 | ask QT-3 (`p1s1r4-5`) | text until answered | CP.1 (HTTP-based for the web runtime service; events and reverse requests open), CP.11 (the schema), a paragraph after CP.34 (CP.24 … CP.27 for an application that installs no runtime) |
| AN-43 | apply | applied | CS.9: "approved by". U-7 is done (`p1s1r4-2`); D-19 and N-30 below |
| IC-29 | ask QT-19 (`p1s1r4-11`) | nothing changed | CP.7 keeps "item", "thread", "turn" and its standing as a proposal |
| GA-8 | apply | applied | CP.20 (what "settled" means; how a waiting run is given up), CP.16 and CP.18 (what the Solution Blueprint settles) |
| GA-12 | ask QT-14 (`p1s1r4-7`) | text until answered | CT.12 names the point as open; CT.13 keeps its text |
| GA-29 | apply | applied | CP.2 (an item cut off is reported as interrupted; what the Solution Blueprint settles), CP.9 |
| VX-PQ24 | apply | applied | the lead-in of `RT > RT-ASKS`; CP.21 (the item stays in execution; nothing else of its run is sent; the run's settings are untouched and it goes on by itself); CP.9; CP.20 |
| VX-1 | apply | applied | new **CP.41** |
| VX-3 | apply | applied | CP.9: stored with its queue item, shown again, answered by the next prompt in the same session |
| VX-4 | apply | applied | new **CP.40** |
| VX-5 | apply | applied | new **CP.42** |
| VX-7 | apply | applied | CP.8: a deadline only with a safe default; without them an ask waits without a limit |
| VX-8 | apply | applied | CP.8: a response can be an action the runtime carries out |
| VX-13 | apply | applied | new **CT.17**; CT.1 (the row "Runtime tools on `_ai`"); new **CP.44** |
| VX-14 | apply | applied | new **CP.39** |
| VX-45 | apply | applied | CP.29: the other runtimes pause until restarted; a runtime does not work on files in another format; the migration comes with the runtime installation |
| VX-50 | apply | applied | CT.10: configured, then bundled binary; the project list |
| A-14 | ask QT-12 | **PQ-40** | CP.29 names the point as open; CP.32 and CP.33 keep their text |
| WW-4 | apply | applied | new **CP.36**; CP.4 (an arriving message, a changed read state) |
| WW-14 | apply | applied | CS.11; CP.13 (a host supplies no credential) |
| TF-2 | ask QT-16 (`p1s1r4-3`) | text until answered | CP.15 names the point as open, with PQ-36; CT.1 keeps its text |
| TF-3 | apply | applied | CT.11 (host tools are not reachable through the MCP server), CT.12 (what the Solution Blueprint settles) |
| TF-15 | apply | applied | new **CP.38**; CP.4 (the progress of a subagent) |

### Findings that also reach this part

| Finding | Done here |
| --- | --- |
| AN-4 | CS.10: the user is asked to unlock, and the run waits as for any ask (CP.21) |
| AN-6 | CP.9 and CP.22 stand; CP.23 adds which run waits for an ask; CP.4 names the state of a run |
| AN-24, GA-2, AN-44 | CS.9 (once for a runtime installation); a paragraph after CS.11: CS.7 … CS.11 are stated for a runtime on the user's machine (PQ-38) |
| AN-27, WW-13, AN-30 | a paragraph at the end of `RT > RT-ASKS`: what a team on the GitHub backend has of the chain, and how a phone learns of an ask, are open |
| VX-6 | CP.3 (the commands on an item that is being executed); the lead-in of `RT > RT-ASKS` |
| VX-9 | CT.1 (declaring a wait); new **CP.43** (a declared wait is not an ask) |
| VX-15, Q-9 | CP.4: the state of a run; the state of a quest whose checkout is missing |
| VX-32, VX-52 | CS.14: the profile an item is continued on; usage per round and prompt, the usage ledger |
| VX-36 | CT.9: a todo can name its role |
| VX-44, A-6 | CP.23 and CT.17: the journal of asks and answers, planned |
| TF-5 | new **CP.37** (what is being executed or scheduled); CP.2 |
| WW-5 | CP.36 names the cache and the outbox as open (QT-24, `p1s1r4-7`) |
| AN-11, AN-42, IC-12, IC-13, IC-17, IC-18, GA-6, GA-13, GA-18, GA-19, GA-27, GA-30, ST-3, ST-5, ST-7, ST-9, ID-1, ID-3, ID-4, ID-8, VX-17, VX-25, VX-27, VX-37, VX-41, VX-42, VX-51, A-5, A-11, AB-15, WW-8 | nothing to write in this part: asked or written by the owning part, or the items keep their text (CS.7, CS.12, CS.13, CS.16, CS.18, CP.5, CP.6, CP.14, CT.13) |

### Done otherwise than the row says

- **Lines "what the Solution Blueprint must settle"** are the last sentence of their item (CP.2,
  CP.16, CP.18, CT.12), as `p1s1r4-3` wrote them.
- **GA-8, split over two items.** The quest owner's record goes to CP.16, the chain, the working
  hours and how a person is named to CP.18.
- **Questions of other parts are cited by their place**, since they have no id yet: "the question
  at `CLI > CLI-PACK`, CL.1" (QT-3), "at `TAC > TAC-PEOPLE`, CI.13" (QT-14), "at
  `TAC > TAC-BACKENDS`, CA.26" (QT-5), "at `TAC > TAC-CRYPT`, CI.18" (QT-4), "at
  `TAC > TAC-CONV`, CM.7" (QT-24).
- **CP.43 and CP.44** are not rows of the list. The todo's description asks that `RT > RT-ASKS`
  says what is not an ask: a wait for time or an outside event, and an answer handed to the user
  without waiting.
- **TF-2 and PQ-36.** CP.15 points to PQ-36, but PQ-36 as written asks only whether a host's tools
  "would be called for a prompt another host queued"; it does not ask whether a host may forward a
  host tool to another host's window (Tom Forge to VS Code). See "For other parts".
- **VX-1's question** ("keep the rule?") is not asked: the triage rules that it is kept.
- **ST-9, CP.2.** "A process of its own" reads "an operating-system process of its own".

### Obligations changed

| Item | Change | Source |
| --- | --- | --- |
| CP.21 | the run that asked waits as a whole; no walk goes on with another todo | PQ-24 (b) |
| the lead-in of `RT > RT-ASKS` | no promise that an ask does not hold a process up for long | PQ-24 (b) |
| CP.8 | no deadline unless declared with a safe default; a response can be an action of the runtime | S23: vscimpb120, vscimpb85, vscimpb104, vscimpb89 |
| CP.9 | the answer comes as the next prompt in the same session | S23: vscimpb166 |
| CP.20 | "settled" has three meanings | S23: vscimpb55, vscimpb78 |
| CP.41 | at most one open ask per run; a second is refused | S23: vscimpb81 |
| CP.42 | an ask ends with the execution that asked | S23: vscimpb78, vscimpb33 |
| CP.40 | an ask is answerable from every attached runtime client and runtime of the machine | S23: vscimpb173, vscimpb170 |
| CP.36, CP.37, CP.38 | messaging and documents, "what is running", and the second host's commands are part of the protocol | PQ-30, PQ-26; S25; S26 |
| CP.39 | two classes of notification, each event with who caused it | S23: vscimpb124, vscimpb170 |
| CP.29 | the other runtimes pause until restarted; no work on files in another format | S23: vscimpb142 … vscimpb142d |
| CS.9 | "approved by", once for a runtime installation | PQ-32 (a) |
| CS.10 | unlocking is an ask; the run waits | PQ-24 (b) |
| CS.11, CP.13 | team tokens are the runtime's; a host supplies no credential | S1 § 5.8; N-17 |
| CT.10 | the project list comes from the build tool's listing | S23: vscimpb84 |
| CT.11 | host tools are not reachable through the runtime's MCP server | N-18 |
| CT.17 | a tool that hands the user an answer without waiting | S23: vscimpb171 |

### Sources needed

None beyond S22 … S27. Cited as `p1s1r4-3` cites them: `(S23: <todo id>)`, `(S25: <todo id>)`,
`(S26: <todo id>)`, S22 § n with its own ids, S17 for the extension's user guide. S14 § 3 is cited
at CP.37.

### For other parts

- **`p1s1r4-5`**
  - CL.5: messaging and documents for a host go through the runtime client SDK (CP.36), and the
    convenience layer supervises a runtime it started (CP.2, CP.37).
  - `CLI > CLI-UI`: the asks group shows which run waits for an ask (CP.23) and that an ask can be
    answered from several places (CP.40); a component for the answers (CT.17) and for the two
    classes of notification (CP.39) is not named there.
  - QT-3's question should cover CP.1, CP.11 and CP.24 … CP.27, which point to it.
- **`p1s1r4-6`**: CA.26 is pointed to from the end of `RT > RT-ASKS` (QT-5); CA.5 carries which
  ask a run waits for (CP.23).
- **`p1s1r4-7`**: QT-14's question should cover CT.12 (who issues the bearer token); QT-24's
  CP.36 (cache and outbox); QT-4's the end of `RT > RT-ASKS` (how a phone learns of an ask).
  WR-4 and WR-5 in `TAC > TAC-WEBWORK` can cite CP.36.
- **`p1s1r4-8`**: CW.4, CW.5 and CA.13 are quoted in PQ-39 (leases while a run waits); CW.11 and
  CQ.3 for AN-10 (the place in the trail after a start-over; the history before it stays in the
  trail).
- **`p1s1r4-9`**: N-15 (AN-2: no "does not block a process for long"); N-17 is cited at CS.11;
  N-18 at CT.11; N-30: "having the runtime and the tac server approved by Tom Secrets Manager"
  (PQ-32); F4, F5 and F12 follow CP.21 and wait for PQ-40.
- **`p1s1r4-10`**
  - D-19: "the runtime and the tac service are approved by Tom Secrets Manager once" (PQ-32).
  - D-20 loses the walk clause (PQ-24).
  - `CON`: Webwork plans to keep the team token in its settings container, CS.11 keeps it in the
    runtime (WW-14); the webwork quest is to be told before its D40 is written.
  - R-10 gets a second trigger (a lease held by a run that waits for a person, PQ-39); R-13 waits
    for PQ-40.
- **`p1s1r4-11`**
  - Insert PQ-39 after CP.21 (after the block of PQ-24) and PQ-40 after CP.29.
  - Replace "the question at …" in CP.1, CP.11, CP.36, CT.12, the end of `RT > RT-ASKS` and the
    paragraph after CP.34 by the question's id once it exists.
  - PQ-36 does not ask what CP.15 points to it for (a host forwarding a host tool to another
    host, TF-2): add it to PQ-36 or to a merged question.
  - `GLO`: "settled" (of an ask, CP.20), "approved by" (Tom Secrets Manager, CS.9); pairing for
    devices only.
  - `ABOUT > ABOUT-READ`: the ranges of `CP` (to CP.44) and `CT` (to CT.17). CP.36 … CP.44 and
    CT.17 stand where they belong by content, not in the order of their numbers.

## `p1s1r4-5` — `CLI`

Marks written: 67 additions, 19 substitutions, 1 deletion. New items: **CL.12**, **CU.16**,
**CU.17**, **SC-30**, **SC-31**. No new `CK` item. Questions written: **PQ-41**, **PQ-42** (QT-3),
**PQ-43**, **PQ-44** (QT-7).

### Rows of the work list

| Finding | Ruling | Done | Items changed or added |
| --- | --- | --- | --- |
| AN-11 | ask QT-19 (`p1s1r4-11`) | nothing changed | CU.6 and CU.15 keep "conversation" for both senses |
| AN-12 | apply | applied | CL.11: "runtimes and command-line programs of ours; no server uses it" |
| AN-13 | drop | dropped | covered by AN-12 (triage § 1.7) |
| AN-15 | apply | applied | CL.6 (each tac client SDK is driven by a test program of its own, without a runtime); CL.2 (what the Solution Blueprint settles about the dependency); CL.12 (who the tac client SDK is for). `GLO`, CA.28, N-26, WR-6, G-1 belong to other parts |
| AN-22 | ask QT-3 | **PQ-41** | new **CL.12** (three client SDKs, each with its languages and what is open); CL.1, CL.2 (stated for the two SDKs in nine languages); CL.3 (a row for the web runtime client SDK, without a name or place) |
| AN-26 | ask QT-4 (`p1s1r4-7`) | text until answered | CK.10 (D-51 stands; named as an open point, with the place of the question); CK.11 |
| IC-28 | ask QT-7 | **PQ-43** | CU.9 names the point as open; CU.6's Review group and SC-18 keep their text |
| GA-13 | ask QT-14 (`p1s1r4-7`) | text until answered | CK.2 keeps its text and names the point as open |
| ST-2 | apply | applied | the paragraph before SC-1: the mark is gone, the standing is a plain statement |
| ST-14 | apply | applied | SC-21, SC-24, SC-27, SC-28, SC-29 |
| ID-6 | apply | applied | new **CU.17**; CU.6 (rows Runs and processes, Supervision, Asks); CU.15; CK.1; CK.9. A deadline and default per process step is not written |
| ID-9 | ask QT-3 | **PQ-42** | CL.1 names the point as open; CL.7 keeps its text |
| VX-48 | ask QT-7 | **PQ-43** | CU.9 names the two forms and the page protocol as an input |
| VX-51 | ask QT-18 (`p1s1r4-3`, PQ-35) | nothing changed | SC-25 keeps "host's own" |
| AB-18 | apply | applied | CK.12 (the quest `al_the_bear` checks it; no todo there yet). R-20 is `p1s1r4-10`'s |
| WW-1 | ask QT-7 | **PQ-43** | CU.9; CK.2 (whether trc contains the review component is open) |
| WW-12 | apply | applied | new **CU.16** |
| WW-19 | ask QT-7 | **PQ-44** | CU.5 names the point as open |
| WW-21 | apply | applied | CU.7 |
| TF-5 | apply | applied | CL.5 (what Tom Forge needs for a runtime it started; CP.37, written by `p1s1r4-4`) |
| TF-8 | ask QT-7 | **PQ-44** | CU.5; CU.3 and CU.6's Todos row keep their text |
| TF-11 | apply | applied | CK.7, CK.10 |

### Findings that also reach this part

| Finding | Done | Items |
| --- | --- | --- |
| AN-6, VX-PQ24, VX-15 | applied | CU.17, CU.6, CU.15, CK.1, CK.9: the state of a run as CR.23 has it, what it waits for or is held by, since when |
| AN-17 | applied | CU.6 (Supervision) and SC-28: leases with the executions that hold them |
| AN-20, WRS | applied | CL.11, CK.10: "web runtime service"; how it works is not restated here (CR.46, CR.108 … CR.110, PQ-38) |
| AN-21, GA-16, GA-17, WW-13 | text until answered | CK.11: which program a device reaches, which holds the device keys and how a phone learns of an ask are open (QT-4) |
| AN-23 | asked | PQ-41 covers CP.1, CP.11 and CP.24 … CP.27 |
| AN-27 | applied | CU.1, CK.6 (the web runtime client SDK beside the Dart runtime client SDK). CU.4 and CK.12 need no change |
| AN-34 | applied | CU.9 points to O-10; "review application" is not written |
| AN-37 | applied | CU.16: the messaging components are Flutter components; the extension's messaging views are its own |
| IC-9 | applied | CL.5: "the runtime installation" |
| IC-11, WW-7 | text until answered | CK.10 names the team of a runtime without a quest as open (QT-15); CK.1 keeps its text |
| IC-34 | applied | CL.2; CK.4 |
| ST-8 | applied | CL.1: "first version" |
| GA-25 | applied | with ST-2 |
| VX-4, VX-13, VX-14, VX-44, A-6 | applied | CU.6 (Asks: the answers, the journal, an ask closes in every place; Supervision: both classes of notification); SC-3 (the answers page); new SC-31 |
| VX-6, VX-16, VX-26, VX-53 | applied | CU.6 (Queue: the item states of CR.69, the commands of CR.74, the kinds of CR.64, the switches of CR.84) |
| VX-20 | applied | CU.6 (Sessions and memory) |
| VX-40 | applied | CU.6 (Todos: todos that are the user's to do) |
| VX-45 | applied | SC-26 |
| VX-47 | applied | CK.1 (a quest with its short description) |
| WW-4 | applied | CL.5 (messaging and documents for the host's user, CP.36) |
| TF-15 | applied | CU.6 (Conversation: the completion of slash commands and skills); CU.10 (Tom Forge's todos as the check of the inventory) |
| Q-7, Q-11, TF-10 | text until answered | no screen row and no component for the management of quests or for repository quests; a paragraph under the inventory says so and points to the question at CQ.7 (QT-11) |
| AN-30 | nothing changed | CK.8 keeps its text; nothing is extended to the GitHub backend (QT-5) |
| AN-41 | nothing changed | SC-28 and CU.6 name no resource notation |
| IC-17, GA-12, ID-8 | nothing changed | CK.5 keeps its text (QT-14) |
| GA-18 | nothing changed | CU.7 names no number |
| GA-19, ST-7 | nothing changed | nothing is moved; the copies in `CLI` agree with triage § 1 |
| VX-49 | not applied here | CU.6's Review group keeps its text until PQ-43 (triage § 1.4); the review round's additions are in `TAC > TAC-REVIEW` |
| A-9 | nothing changed | SC-16 names the quest notes and the workspace notes, SC-17 the per-machine notes as the host's own; SC-22 stands |
| TF-2 | nothing changed | CL.10 keeps its text (PQ-36) |
| TF-4 | nothing changed | CL.5 says nothing of Node (PQ-37) |
| TF-9 | nothing changed | CL.6 says nothing of fixtures for other writers (PQ-34) |
| TF-12, TF-13 | nothing changed | N-25 and N-29 carry them (`p1s1r4-9`) |

### The points of the todo's description

- **PQ-26 (a):** CL.11, with CL.12 and CL.6.
- **PQ-28:** CL.12 says which SDKs exist and in which languages; CL.1 … CL.3 are stated for the
  two SDKs in nine languages; CU.1 says which SDK the components work over and that this is open
  where no runtime runs; whether the two Dart SDKs share one programming interface is PQ-41. In
  `CLI-TRC`: CK.6, CK.10, CK.11.
- **PQ-30 and the review component:** PQ-43; CU.9, CK.2. No application for reviewing is written
  as part of the product.
- **The existing Flutter packages:** PQ-44; CU.5.
- **`CLI-SCREENS`:** the states of a run (CU.15, CU.17), the open ask of a run (CU.6 Asks, CK.9),
  todo offers (SC-30, CU.6 Todos), the answers page and the planned view of questions and
  decisions (SC-3, SC-31). The register of quests and the management of quests get no row: the
  triage rules that none is added until QT-11 is answered; the paragraph under the inventory
  records it.

### Done otherwise than the row says

- **QT-3 is two questions.** PQ-41 asks what the web runtime client SDK is (with what crosses
  HTTP, the convenience layer, the UI components over either SDK, the suite and the version
  checks); PQ-42 asks whether TypeScript and JavaScript are one client SDK. The second is
  independent of the first, and one question with one recommended option could not carry both.
- **QT-7 is two questions.** PQ-43 asks where the review component is built and whether trc
  contains it; PQ-44 asks what becomes of `tom_agentic_ui`, `tom_ai_trail_ui` and `tom_todo_ui`
  and whether the Todos group is built on `tom_todo_ui`. Same reason. `p1s1r4-11` may merge.
- **SC-24.** "Partly host's own" moved to the outcome column as the row says; the group column
  then needs a group of CU.6, and of the panel's three parts only the logs have one (trail). The
  outcome reads "starting point for the logs; the rest host's own". It is a first pass like the
  other outcomes.
- **SC-21.** "Diagnostics" is written as the host's own (the diagnostics of the extension's own
  parts); the state of the machine's runtimes, which the Supervision group has, is named beside it.
- **SC-30 (todo offers)** has no row in the work list. The todo's description names it, and
  `PAR > PAR-CROSS`, CW.26 (S21, TQ-11) says a person accepts an offer, so a component has to show
  it.
- **CU.17** states ID-6 once as an item, so that CU.6, CU.15, CK.1 and CK.9 refer to it.
- **Questions of other parts are cited by their place** where they have no id yet: "the question
  at `TAC > TAC-CRYPT`, CI.18" (QT-4), "at `TAC > TAC-PEOPLE`, CI.13" (QT-14), "at
  `TAC > TAC-PEOPLE`, CI.2" (QT-15), "at `PAR > PAR-QUESTS`, CQ.7" (QT-11).

### Obligations changed

| Item | Change | Source |
| --- | --- | --- |
| CL.1, CL.2 | the nine languages hold for the runtime client SDK and the tac client SDK | PQ-28 |
| CL.12 | a third client SDK, the web runtime client SDK, in Dart and in JavaScript / TypeScript | PQ-28 |
| CL.11 | no server uses the tac client SDK; an application on a phone, on a tablet or in a browser uses the web runtime client SDK | PQ-26 (a); PQ-28 |
| CL.5 | the runtime client SDK's convenience layer carries messaging and documents; what Tom Forge needs for a runtime it started | PQ-30; S25; S26 |
| CL.6 | the conformance suite drives each tac client SDK without a runtime | PQ-26 (a) |
| CU.6 | components for the item states and the commands on an item, the answers, the journal (planned), todos that are the user's, todo offers, sessions with base and lifetime, both classes of notification | S23; S22; CW.26 |
| CU.7 | the bounded Markdown view works without a runtime and takes its bound from the host | S25: 06_woneb8, 13_woneb4 |
| CU.16 | what the messaging components take from a host | S25: 13_woneb7 … 13_woneb9 |
| CU.17 | a waiting or held run is shown as such, with its cause and since when | PQ-24 (b); S23 |
| SC-30, SC-31 | two screens added to the inventory | CW.26; S23: 01_aifmt-4 |
| CK.1, CK.9 | trc shows the state of each run, what it waits for, and the run behind each open ask | PQ-24 (b) |
| CK.6, CK.10 | trc on a phone or tablet uses the web runtime client SDK; its phone layout is built without Tom Forge's shell | PQ-28; S26: wwkit3 |
| CK.11 | no program is named that a device reaches from the internet | PQ-28 |
| CK.12 | the quest `al_the_bear` checks the VPN on phones | S27 |

### Sources needed

None beyond S22 … S27. Cited as the other parts cite them: `(S23: <todo id>)`, `(S25: <todo id>)`,
`(S26: <todo id>)`, S22 § n, S27.

### For other parts

- **`p1s1r4-2`**: the `VIS > VIS-SYSTEM` row "Client SDKs" points to "CL.1" for
  the open question on the web runtime client SDK: it is PQ-41, at CL.12. E-20 points to "CU.9"
  for what becomes of the three Flutter packages: it is PQ-44, at CU.5. O-10's pointer to CU.9
  holds (PQ-43).
- **`p1s1r4-4`**: CP.1, CP.11 and the paragraph after CP.34 say "the question at
  `CLI > CLI-PACK`, CL.1": it is PQ-41.
- **`p1s1r4-6`**: CK.1 cites CA.5 for the state a runtime reports with its registration; CK.8
  says trc finds team runtimes "by the endpoints they publish" and is not extended to the GitHub
  backend (QT-5).
- **`p1s1r4-7`**
  - QT-4's question should cover CK.10 and CK.11, which point to it at CI.18: whether phones and
    tablets stay in the first version, which program a device reaches from the internet, and how
    a phone whose application is not running learns of an ask.
  - QT-14's question should cover CK.2 ("more or less everything a runtime can do") and CK.5.
  - QT-15's question should cover trc's runtime on the desktop, which serves no quest (CK.10).
- **`p1s1r4-8`**: QT-11's question should cover the screens: the paragraph under the screen
  inventory says that no row and no component exists for the management of quests and for
  repository quests until it is answered. SC-30 and CU.6 (Todos) now show todo offers (CW.26).
- **`p1s1r4-9`**: no generation unit is named for the web runtime client SDK (PQ-41); G-5 and
  N-26 keep nine languages until PQ-42; G-6 keeps the review group until PQ-43; N-25 could say
  that the phone build of trc does not use Tom Forge's shell (CK.7, CK.10).
- **`p1s1r4-10`**
  - R-20, or a row beside it, lists the check of the VPN on an iPhone and an Android device by
    the quest `al_the_bear` (AB-18; CK.12 points to R-20).
  - R-19 waits for PQ-43; D-3 ("client SDKs for nine languages") holds for the two SDKs and
    waits for PQ-41 and PQ-42; D-51 is cited by CK.10 as unchanged.
  - `DEL`, the message to the quest `tom_forge`: its `qavs_ccparity_*` todos embed the components
    (CU.3) and are the check of the screen inventory (CU.10); what its view packages become
    follows PQ-44.
- **`p1s1r4-11`**
  - Insert PQ-42 after CL.1, PQ-41 after CL.12, PQ-44 after CU.5, PQ-43 after CU.9.
  - Replace "the question at …" in CU-, SC- and CK-items by the questions' ids once they exist.
  - `GLO`: client SDK (three of them; the tac client SDK is for runtimes and command-line
    programs of ours), web runtime client SDK, web runtime service; "conversation" in two senses
    stays until QT-19.
  - `ABOUT > ABOUT-READ`: the ranges of `CL` (to CL.12), `CU` (to CU.17) and `SC` (to SC-31).
    CL.12, CU.16 and CU.17 stand where they belong by content.

## `p1s1r4-6` — `TAC-JOBS`, `TAC-COORD`, `TAC-BACKENDS`

Marks written: 34 additions, 15 substitutions, 5 deletions. No new item; every change is in
CA.3 … CA.32. Questions written: **PQ-45** (QT-8, at CA.10), **PQ-46** (QT-13, at CA.11),
**PQ-47** (QT-5, at CA.26), **PQ-48** (QT-17, at CA.31). PQ-24 … PQ-33 are left in place.

### Rows of the work list

| Finding | Ruling | Done | Items changed or added |
| --- | --- | --- | --- |
| AN-16 | apply | applied | CA.20 ("an execution started or ended"), CA.26 GitHub row ("leases and endpoints"), CA.29 ("closing a session" removed) |
| AN-17 | apply | applied | CA.8 (the list of what a lease names, no record of the holder, a restarted runtime finds its leases by the names on them; the sentence about the word "session" removed); CA.5 (the executions under way). X-11, CA.36, SC-28, CU.6, `GLO` holder: other parts |
| AN-21 | ask QT-4 (`p1s1r4-7`) | text until answered | CA.30 and CA.23 unchanged; "relay" names the tac server's relay only |
| AN-29 | apply | applied | CA.26 GitHub row "one user's machines, or a simple team of several members"; the paragraph under the table |
| AN-30 | ask QT-5 | **PQ-47** | CA.26: the list of what does not travel without a tac server, with the pointer |
| AN-35 | apply | applied | CA.28 ("can answer" tac clients in a browser: a capability kept for L-12, used by no application of the first version, CI.4) |
| AN-39 | apply | applied | CA.17 as PQ-31 (a) words it, with the prefix; CA.9 (one prefix, `git:`, further prefixes added as needed; the `tac/1.0` kinds moved to E-19) |
| AN-40 | apply | applied | CA.10 (the three forms with `git:` and both examples), CA.11 ("`git:` resources"; resources with different prefixes never overlap). CA.41, CA.42, `GLO`, D-59, D-60, X-15: other parts |
| AN-42 | ask QT-8 | **PQ-45** | — |
| IC-1 | ask QT-13 | **PQ-46** | CA.11: a sentence that by its rule the integration step's exclusive lease can never be given while shared leases are held, and that the lease rules are open |
| IC-7 | ask QT-13 | **PQ-46** | CA.14: who checks the token at the push is open |
| IC-8 | ask QT-5 | **PQ-47** | CA.4 and CA.15: stated for the local backend and the tac server |
| IC-10 | apply | applied | CA.3 ("the quest it serves"), CA.5 ("per run") |
| IC-15 | apply | applied | CA.8 (one list: the runtime, the quest, the run, the item, the machine, the workspace — the triage's list, without the person IC-15 also proposed) |
| IC-16 | ask QT-17 | **PQ-48** | CA.31: the pointer |
| GA-3 | apply | applied | CA.14: the line of what the Solution Blueprint settles about renewal, waiting claims, starvation, a lease freed under a runtime, and a runtime that ends mid-execution |
| GA-5 | ask QT-17 | **PQ-48** | — (the question covers installation, crash, version check and the hand-over between files and service) |
| GA-7 | apply | applied | CA.3: the line of what the Solution Blueprint settles about a runtime's identity |
| ST-3 | apply | applied | CA.8, CA.9, CA.16, CA.27 lose their sentences on what `tac/1.0` has and refer to E-19 (written by `p1s1r4-2`); "first delivery" in CA.26 reads "first version" (ST-8's wording). The `TAC` lead-in has no history sentence left in this part |
| ID-2 | ask QT-13 | **PQ-46** | the matrix is the recommended option |
| ID-4 | ask QT-8 | **PQ-45** | the one written form is the recommended option |
| ID-5 | ask QT-5 | **PQ-47** | the capability table is the recommended option |
| A-7 | apply | applied | CA.17: never claimed are the todo files, the process state and the progress file (many writers) and the per-host files (sessions, trail, journal of asks and answers); "the files of questions, decisions" goes |
| Q-14 | ask QT-8 | **PQ-45** | CA.17: the example stays a classic quest in the `_ai` state's repository; a repository quest's files are named by its own repository; the multi-quest case is open |
| AB-15 | apply | applied | CA.26: the credential is a secret reference (CS.7) with rights on the coordination repository only; the fleet's plan (`al-the-bear/tom_coordination`, a fine-grained token per machine in an environment variable, the `env:` form) |
| WW-6 | ask QT-17 | **PQ-48** | CA.31 and CA.32: pointers. Webwork's need (cached history, outbox) is recorded in `TAC > TAC-WEBWORK` by `p1s1r4-7` |
| WW-8 | ask QT-14 (`p1s1r4-7`) | text until answered | CA.23 keeps "the endpoints it serves" |

### Findings that also reach this part

| Finding | Done here |
| --- | --- |
| AN-5 (QT-1, PQ-39) | CA.13 unchanged: leases are held for as long as the item is executed |
| AN-6, VX-15, ID-6, VX-PQ24 | CA.5: the run's state as CR.23 names it, which run waits or is held, for what and since when (CP.23) |
| AN-8 | CA.17's example stays a classic quest (Q-14's ruling) |
| AN-15 | CA.25 stands; CA.28 as AN-35 |
| AN-32 | CA.4, CA.15 (IC-8); CA.26 (AN-29); CA.32 unchanged except the wording below; CA.33, CA.34 unchanged (members and identities in a migration are part of QT-6, `p1s1r4-7`) |
| AN-41 (QT-8) | covered by PQ-45 (point 1, names without a prefix); CA.3's repositories keep their wording |
| IC-2 | CA.26 does not describe the integration queue per backend; PQ-47's table has a row for it (QT-13 / QT-5) |
| IC-4, GA-14 | CA.19: the waiting at the sender in CW.19's words, and the line for a command nobody took in 7 days |
| IC-12, GA-6, TF-6 (QT-16) | CA.6 keeps "One quest may have several runtimes" |
| IC-18, IC-19, ID-3, GA-12, ID-8 (QT-4, QT-14) | CA.23, CA.24, CA.27, CA.28, CA.30 keep their text beyond the changes above |
| IC-22 | CA.27 unchanged (L-11 says what is later) |
| GA-9, AB-14 (QT-13) | covered by PQ-46: a failed integration step, and a fleet reconcile known to tac |
| GA-18 | nothing in this part |
| GA-19, ST-7, ST-15, ST-16 (QT-21) | nothing changed; the structure is `p1s1r4-11`'s |
| ST-8 | CA.26 "first version" |
| ST-9, AN-18 (QT-19) | nothing changed |
| VX-14 | nothing in CA.20 (the notification classes are CP.4's) |
| A-3, A-6 | CA.17 names the per-host files and the journal of asks and answers |
| Q-12 | CA.26: a coordination repository is created private, with GitHub Actions switched off |
| AB-16 | CA.28: the fleet's plan for its tac server where it differs (VPN only, from a clone, own system user, keys in an environment file), rewritten against CA.27 … CA.30; R-20 is `p1s1r4-10`'s |
| AB-17 | nothing in this part beyond CA.32's wording; the risk is `p1s1r4-10`'s |
| WW-7 (QT-15) | CA.5 unchanged beyond the run state |
| TF-3 | nothing in this part |

### Done otherwise than the row says

- **CA.32** was not in the work list: on the read-through its subject "the queues … stop" broke
  triage § 1.1 (the subject of a waiting rule is the run; a run whose next item is not executed
  "is held"). It reads "the runs of the team runtimes are held after their current item".
- **IC-15:** the triage's list of what a lease names is used, without the person that IC-15 also
  proposed; CA.3 registers the person with the runtime, so the lease reaches it through the
  runtime.
- **PQ-46** includes GA-9 and AB-14 (QT-13's other findings, both from `p1s1r4-8`'s rows), so that
  the lease rules are settled by one answer.

### Obligations changed

- CA.3: a runtime registers one quest (or none), not several (IC-10; CR.6).
- CA.5: the state is reported per run, as CR.23's states, with what a run waits for and since
  when (PQ-24 (b)).
- CA.8: tac keeps no record of the holder beside the lease; a restarted runtime finds its leases by
  the names on them (PQ-27 (a)).
- CA.9, CA.10, CA.11: resource names carry the prefix `git:`; resources with different prefixes
  never overlap (PQ-31).
- CA.17: what is never claimed is the todo files, the process state, the progress file and the
  per-host files; a part of the `_ai` state's repository is claimed only when the todo names it
  (PQ-31 (a); S22 § 2.2).
- CA.20: the notification is "an execution started or ended" (PQ-27 (a)).
- CA.26: the GitHub backend serves simple teams of several members besides the personal team; the
  local backend works on one machine only; the GitHub backend's credential is a secret reference
  with rights on the coordination repository only; a coordination repository is created private
  with Actions off (PQ-29; AB-15; Q-12).
- CA.28: answering tac clients in a browser is a capability no application of the first version
  uses (PQ-30).
- CA.29: "closing a session" is no longer among what a quota never blocks (PQ-27 (a)).
- CA.32: the runs are held, not the queues stopped (PQ-24 (b), triage § 1.1).

### Sources needed

None new. Cited: S22 (§ 2.2, § 3.2), S23 (`vscimpb123`), S27 (al_the_bear
`14_loose_wslayout-4_akto-coordination-repo-and-tokens`, `14_loose_wslayout-6_akto-coordination-server-on-bigbeast`;
`tsmfleet3`, `tsmfleet9`), all in `SRC`.

### For other parts

- **`p1s1r4-2`**: E-3 keeps its parenthesis (it describes what is built, AN-17); CA.8, CA.9,
  CA.16 and CA.27 now refer to E-19.
- **`p1s1r4-3`**: CR.35 (a quest's list of resources) writes names with `git:` (AN-40, PQ-31);
  CR.38 is quoted in PQ-48 (what "coordination off" means).
- **`p1s1r4-7`**
  - CA.36: `tac/2.0` has no record for the holder of leases (AN-17, PQ-27 (a)).
  - CA.39: the personal team is the local backend's and the single-member case of the GitHub
    backend, which also serves simple teams of several members (AN-32).
  - CA.41 and CA.42: the names and examples with `git:` (`git:al-the-bear/tom_ai_build`,
    `git:al-the-bear/tom_ai_build#tom_ai_runtime/**`); overlap among `git:` names only (AN-40).
  - QT-6 (members and owners on the GitHub backend) can refer to PQ-47 for what such a team has.
- **`p1s1r4-8`**: CW.5, CW.6 and F8's lease are quoted in PQ-46; CW.7 and CW.24 write resource
  names with `git:`; PQ-46 includes GA-9 and AB-14.
- **`p1s1r4-9`**: T1 is quoted in PQ-48; T4 gets the variant "a team on the GitHub backend" with
  what PQ-47 leaves open; N-12 follows CA.32's wording ("the runs are held"); N-26 follows CA.28
  (a capability no application of the first version uses).
- **`p1s1r4-10`**: X-11 reads "for leases and endpoints" and follows AN-29 (the GitHub backend
  serves teams of several members); D-47 follows AN-29; X-15 says "one prefix for now"; D-59 and
  D-60 write resource names with `git:`; R-20 can cite CA.28 for the fleet's tac server plan.
- **`p1s1r4-11`**: `GLO` holder adds the quest, the machine and the workspace (IC-15); `GLO`
  resource, resource name and overlap carry the `git:` prefix and "resources with different
  prefixes never overlap"; the terminology document (S21) the same.

## `p1s1r4-7` — `TAC-PEOPLE` … `TAC-WEBWORK`

Done 2026-11-25. The sections `TAC-PEOPLE` (with `TAC-GROUPS`), `TAC-KINDS`, `TAC-CONV`,
`TAC-DOCS`, `TAC-REVIEW`, `TAC-CRYPT`, `TAC-SPEC` and `TAC-WEBWORK`; the question blocks PQ-28,
PQ-29 and PQ-30 stay in place. 95 marks (substitutions, additions, one deletion), all well-formed;
no line starts with `>` outside a question block. One new item: **CV.16**. Five questions:
**PQ-49 … PQ-53**.

### Rows of the work list

| Finding | Ruling | Done | Items |
| --- | --- | --- | --- |
| AN-19 | ask QT-4 | **PQ-49** | CI.18 ("a server a device reaches from the internet", no program named; the open points listed); CI.19 points to PQ-49 |
| AN-31 | ask QT-6 | **PQ-50** | a paragraph under CI.5's table: CI.5 … CI.10, CI.14, CI.20 and CS.4 are stated for a tac server; what holds on the GitHub backend is open |
| AN-32 | apply | applied | CA.39 (which team a user's runtimes belong to with each backend; the personal team is the local backend's and the single-member case of the GitHub backend, which also serves simple teams of several members); CI.1 (a team exists with each backend); WR-1 row and the closing paragraph of `TAC-WEBWORK` (a team on the GitHub backend has no messaging, so a Webwork team uses a tac server) |
| AN-36 | apply | applied | CV.5 and CV.15 ("reaches tac through its runtime") |
| AN-38 | apply | applied, see below | CV.12 step 3 names one actor; CM.2 row "review return" follows; X-3 and R-3: `p1s1r4-10` |
| IC-11 | ask QT-15 | **PQ-52** | CI.2 and CA.39: a runtime that serves no quest has no home team; where it registers is open |
| IC-17 | ask QT-14 | **PQ-51** | CI.13 names the point as open (the MCP server, an endpoint a host serves) |
| IC-18 | ask QT-14 | **PQ-51** | CI.8 names the credentials and points to PQ-51; no new credential written |
| IC-19 | ask QT-4 | **PQ-49** | CI.18 names whether the relay is on a device's path as open; CA.30 keeps its text (`p1s1r4-6`) |
| IC-20 | apply | applied | WR-2 "met differently" (a team's tac server is strict; identification only on an open server, for one user); CI.10 (the administrator sets it; strict for a server other users use) |
| IC-21 | apply | applied | CA.38 (older runtimes keep working from `tac/2.0` on, nothing uses `tac/1.0`, E-11; a tac client that states no user works on the local backend, a strict server refuses it) |
| IC-26 | apply | applied, see below | CM.1 (eight kinds between users or from a run to a person; notification and command are the two kinds between runtimes, CA.19, CM.14); CM.2 gets a column "From → to" |
| IC-27 | apply | applied | CV.14 (pinned blobs as long as the process runs, CV.4; 30 days for blobs not pinned) |
| GA-14 | apply | applied | a line under CA.44 (todo offers, the visibility switch); a line under CI.6 (an invitation not redeemed in 7 days); CA.19 has its line already (`p1s1r4-6`) |
| GA-16 | ask QT-4 | **PQ-49** | CI.18 lists pairing as a procedure among the open points |
| GA-17 | ask QT-4 | **PQ-49** | CM.6 names the channels for a phone as open; no push service named |
| GA-26 | drop | dropped | Phase 2 detail, as the triage says |
| GA-27 | apply | applied, see below | CV.12: every reviewer who receives a round through tac is a member of the team (L-3); a line with what the Solution Blueprint settles |
| ID-3 | ask QT-14 | **PQ-51** (point 3: the table of credentials as recommended option) | CI.8 |
| ID-8 | ask QT-14 | **PQ-51** (point 4: one journal per quest as recommended option) | CI.13 |
| VX-49 | apply | applied | new **CV.16** (individual answers, conflicts with decisions, guests, proposed answers, change times, the next round) |
| WW-2 | apply | applied | CV.12 steps 1, 3, 5 (the coordinator's runtime, or for document kinds it does not know the coordinator's application, creates, writes and merges); CV.13 (the documents' storage, for Webwork a local folder or a GitHub repository); CM.2 row "review return" |
| WW-3 | apply | applied | CV.5 (tac's review set is the pinned blobs of one round; what is under review is the application's) |
| WW-5 | ask QT-24 | **PQ-53** | a paragraph under CM.7 (the tac client of CM.9 and CM.13 is the runtime's; where cache and outbox live is open); WR-4 row |
| WW-7 | ask QT-15 | **PQ-52** | CI.2; no name written |
| WW-13 | ask QT-4 | **PQ-49** | CM.6 |
| WW-15 | apply | applied | CI.10 (two entries with one e-mail address, or one person with two ids, are returned with their ids and not merged) |
| WW-16 | drop | dropped | nothing to change (confirms), as the triage says |
| WW-18 | apply | applied | CV.15 (which applications those are: built outside this project; the VS Code extension once it hosts the runtime, Webwork and Webforge on the desktop, a web version later; until then a reviewer without a repository works on a desktop) |

### Findings that also reach this part

| Finding | Done here |
| --- | --- |
| AN-15, AN-35 | WR-6 row: the Dart tac client SDK is used by runtimes and command-line programs of ours (CL.11) |
| AN-17 | CA.36: `tac/2.0` has no record for whoever holds leases (PQ-27) |
| AN-20, WRS | CI.4: the web runtime service, reaching tac through the runtime on the server (CR.108, CR.110) |
| AN-24, GA-2 | CI.2 and CA.40: stated for a runtime on the user's machine; behind the web runtime service open (PQ-38) |
| AN-26 | WR-6 row and CI.18: whether phones and tablets stay in the first version is part of PQ-49 |
| AN-40 | CA.41 and CA.42: names with `git:`, the prefix, overlap among `git:` names only |
| IC-25 | CI.19 points to PQ-49 for end-to-end encryption |
| GA-22 | CV.12 step 1 names the coordinator (U-15) |
| ST-3 | CA.39's sentence on `tac/1.0`'s "agent group" refers to E-19; CI.19 states S1's rule instead of "the earlier decision" |
| VX-39, A-10 | CM.4: tac's reminders are kept apart from the todo's (CR.50) and the agent's background reminder |
| WW-4 | WR-4 and WR-5 rows cite CP.36 |
| WW-6 | `TAC-WEBWORK`: a paragraph recording Webwork's need (cached history, outbox while the tac server cannot be reached), pointing to PQ-48 and PQ-53 |
| WW-17 | WR-6 row: Webwork's web and phone builds with its wave 3 (L-8) |
| AN-11, AN-30, AN-41, AN-42, IC-1, GA-8, GA-11, GA-13, GA-15, GA-18, GA-19, ST-5, ST-7, ST-9, ST-16, ID-4, ID-5, VX-32, VX-40, A-8, WW-1, WW-8, WW-12 | nothing to write in this part beyond the pointers above: asked or written by the owning part, or the items keep their text (CM.12, CI.11, CI.15, CV.2, CI.3, CI.14 unchanged) |

### The points of the todo's description

- **PQ-29:** CA.39 states which team a user's runtimes belong to with each backend; CI.1 says a
  team exists with each backend. Members, team owners, tokens, invitations and owner-only
  configuration are stated for a tac server (the paragraph under CI.5); how a team on the GitHub
  backend gets them is PQ-50 (no source says). What else such a team has is PQ-47 (`p1s1r4-6`).
- **PQ-30:** CI.4 holds without exception (no application of the first version is a tac client;
  services through the tac client SDK are possible later, L-12). CA.28's "tac clients in a
  browser" was handled by `p1s1r4-6` (a capability no application uses). CV.15 and CV.12 say who
  reviews with what and who writes the copies; messaging in Webwork through its runtime is in the
  WR-4 row and CP.36; the VS Code extension gets it once it hosts the runtime (CV.15).
- **PQ-28:** CI.18 and CI.19 name no program; "relay" names only the tac server's relay; the web
  runtime service is named as the way a device reaches a runtime. PQ-49 asks the rest.
- **A runtime without a quest:** CI.2 and CA.39 say it has no home team; PQ-52.
- **`TAC-DOCS`, `TAC-REVIEW`:** WW-2 and WW-3 as in the rows above.
- **`TAC-WEBWORK`:** every row says where it is met as the text now stands; a row for **WR-7**
  added (CR.6, CR.15 … CR.18, CT.4, CU.6, CU.7), so the table covers all seven requirements.

### Done otherwise than the row says

- **IC-26.** The triage says notification and command are "listed apart" from the eight kinds.
  They stay in CM.2's table, because a host shows them to its user too and CM.14 already keeps
  them as the messages between runtimes; the new column "From → to" and CM.1's sentence name
  them as the two kinds between runtimes. Moving the rows out of the table would leave empty
  rows after the marks are accepted.
- **AN-38 with WW-2.** The triage's AN-38 row names "the coordinator's runtime, which the
  coordinator's application drives" as the one actor, and WW-2 lets the coordinator's
  application create and merge rounds for document kinds the runtime does not know. Step 3 now
  says "whoever created the round folder (step 1)", which is the coordinator's runtime driven by
  its application, or the application for those document kinds. "Commits there" became "records
  it in the documents' storage (a commit where that is version control)", since Webwork's storage
  can be a local folder.
- **GA-27 with VX-49.** GA-27 says every reviewer is a member of the team; the extension builds
  guests (a reviewer not on the round's review team returns a copy). Both hold: CV.12 says every
  reviewer *who receives the round through tac* is a member of the team (CV.6 lets only members
  download); a guest of CV.16 returns a copy by another way. How the review round's member id
  relates to the tac user id is in the Blueprint line.

### Obligations changed

- **CI.4:** holds without exception; no application of the first version is a tac client
  (PQ-30).
- **CI.10:** strict is set by the tac server's administrator for a server other users use (it no
  longer says the server "is" strict as soon as other users use it); duplicates are returned, not
  merged (IC-20, WW-15).
- **CA.38:** the promise to older runtimes holds from `tac/2.0` on; a tac client that states no
  user works on the local backend only (IC-21).
- **CA.39, CI.1:** teams exist on every backend; the GitHub backend serves simple teams of several
  members (PQ-29).
- **CV.12, CV.13:** the round folder may be created, written and merged by the coordinator's
  application, in a storage that is not version control; every reviewer through tac is a team
  member (WW-2, AN-38, GA-27).
- **CV.14:** pinned blobs outlive 30 days while their process runs (IC-27, D-29).
- **CV.16:** new: guests, conflicts with decisions, individual and proposed answers, change times,
  the next round (VX-49).
- **WR-2:** met differently (a team's server is strict); **WR-6:** the web runtime client SDK, not
  the runtime client SDK, in a browser or on a phone.

### Sources needed

None new. S23 and S25 (added by `p1s1r4-2`) are cited for VX-49 and for Webwork's planned todos
(`09_woneb2`, `09_woneb3`, `13_woneb6`, `13_woneb10`); E-11 and E-19 in `LAND > LAND-BUILT`.

### For other parts

- **`p1s1r4-8`**: CW.5 is quoted in the Blueprint line under CV.12 (which repository and lease
  the recording of a copy uses, GA-27); CW.6 follows AN-32 (the integration queue on the GitHub
  backend is open, PQ-47); CW.26 gets GA-14's line or points to the one under CA.44.
- **`p1s1r4-9`**: T3 stands; T4 gets the variant "a team on the GitHub backend" (no messaging,
  CA.26; PQ-47, PQ-50); T5 and T8 name the program a device reaches as open (PQ-49); N-4 follows
  CA.38 ("from `tac/2.0` on"; IC-21); N-12 and F11 follow AN-32.
- **`p1s1r4-10`**: D-18 waits for PQ-50 (AN-31); D-23 states neither side of the relay's key
  (IC-19, PQ-49); R-22 and `ABOUT`'s status carry PQ-49 as open (AN-19); X-3 adds that no
  application of the first version is a tac client and R-3's trigger that the reviewer's
  application is built outside this project (AN-38); R-3, R-20, D-24, D-25, D-47, D-53, D-54
  follow AN-32 (teams on the GitHub backend).
- **`p1s1r4-11`**
  - Insert PQ-52 after CI.2, PQ-50 after CI.5, PQ-51 after CI.13, PQ-53 after CM.7 and PQ-49
    after CI.18 (after the block of PQ-28).
  - Replace "the question at `TAC > TAC-PEOPLE`, CI.13" (CT.12, CK.2) by PQ-51, "the question at
    `TAC > TAC-PEOPLE`, CI.2" (CK.10) by PQ-52, "the question at `TAC > TAC-CRYPT`, CI.18" (CK.10,
    CK.11, L-6, the end of `RT > RT-ASKS`) by PQ-49, and "the question at `TAC > TAC-CONV`, CM.7"
    (CP.36) by PQ-53.
  - Merge candidates: PQ-49 with PQ-38 and PQ-41 (all from PQ-28); PQ-50 with PQ-47 (both from
    PQ-29).
  - `GLO`: message kind (IC-26: eight kinds between users or from a run to a person, notification
    and command between runtimes); round folder and review round ("in the documents' storage,
    usually version control", WW-2); review set (WW-3: tac's is the pinned blobs of one round;
    check only); personal team (PQ-29: the local backend's, and the single-member case of the
    GitHub backend); team (not bound to a tac server).
  - `ABOUT > ABOUT-READ`: the range of `CV` (to CV.16).

## `p1s1r4-8` — `PAR`

Written 2026-11-25. `PAR`, `PAR-PROBLEM`, `PAR-APPROACH`, `PAR-CROSS`, `PAR-QUESTS` revised with
marks (17 substitutions, 54 additions, 1 removal after the first pass; a few more in the read
through). New items: **CW.27**, **CQ.9**, **CQ.10**, **CQ.11**, **CQ.12**, **CQ.13**. Questions
written: **PQ-54** (QT-9), **PQ-55** (QT-10), **PQ-56** (QT-11).

### Rows of the work list

| Finding | Ruling | Done | Where |
| --- | --- | --- | --- |
| AN-8 | apply | applied | CQ.1 (three types), CQ.5 (one resolver, S22 § 3.1), CQ.7 (the operations), new CQ.9 … CQ.13; CQ.2, CQ.3, CQ.6, D-34 keep their text with a line pointing to PQ-54 / PQ-55 |
| AN-18 | ask QT-19 (`p1s1r4-11`) | items keep their words | P-5, P-9, CW.11, CW.18 unchanged on "session" |
| AN-41 | ask QT-8 (PQ-45) | resource names written with `git:` | CW.7 (the two forms, CA.10), CW.8, CW.24 |
| IC-2 | apply | applied | CW.6: tac keeps the order; the runtime of the first execution carries out the step on its machine; tac runs no checks and lands no commits; the queue on the local and GitHub backend points to PQ-46, PQ-47 |
| IC-4 | apply | applied | CW.19: tac keeps the record (on one machine the machine-wide state, CR.36), the sender's run shows it, not shown as taken at the receiver before a run took it; the 7 days point to CA.19 |
| IC-5 | apply | applied | CW.25: only handing a todo to another quest's runtime is later; CW.20 says the sending of an item or walk is in the first version |
| IC-6 | ask QT-10 | **PQ-55** | CW.14 gets a sentence: for a quest in a repository of its own, its main branch is the branch the register names; member branches are open |
| GA-9 | ask QT-13 (PQ-46) | pointer | CW.5's line names PQ-46 (the integration lease, the fencing token, a failing step); CW.6's line the queue per backend; CW.10 keeps its text |
| GA-10 | apply | applied | CW.11: the line of what the Solution Blueprint settles about the discard |
| GA-11 | apply | applied | new **CW.27** (a pull and a push the user starts carry the files; tac only the live notice); CW.21 refers to it |
| VX-29 | apply | applied | CW.21 (both directions, the release condition, "what a todo blocks is derived"); P-14 reworded to what still hurts |
| VX-34 | apply | applied | CW.20: never creates a run, `default` when no run is named, the receiver's defaults unless the sender names a profile or session, walks and todo or group items over the receiver's todos |
| VX-43 | ask QT-9 | **PQ-54** | CQ.3 keeps its text; CQ.11 says "per host" and leaves the place open |
| VX-46 | apply | applied | CQ.1, CQ.7, CQ.9 (with CR.33, CR.100) |
| A-4 | ask QT-9 | **PQ-54** | CQ.11 names the classes (derived: history and compacted form; machine-local: the live trail) and leaves the place open |
| Q-1 | apply | applied | CQ.1 (three types; the words "classic quest", "repository quest", "single-quest repository", "multi-quest repository") |
| Q-2 | ask QT-11 | **PQ-56** | CQ.1 names three types only |
| Q-3 | ask QT-9 | **PQ-54** | CQ.2's line; no new text writes "personal repository" |
| Q-4 | ask QT-9 | **PQ-54** | CQ.3's personal notes keep their text; CQ.4 stands |
| Q-5 | apply | applied | CQ.5 (source S22 § 3.1, § 3.2; "type"); the `___check here___` paragraph after CQ.8 marked as removed |
| Q-6 | ask QT-10 | **PQ-55** | CQ.6 keeps its text with a line |
| Q-7 | apply | applied | CQ.7: add, pick and unpick, remove, migrate several at once into either form and one way, pull / push / status, set up this machine, check and fix; join and the trial migration keep their text |
| Q-8 | drop | dropped | as the triage (confirms CQ.8) |
| Q-10 | apply | applied | CW.25 (written directly only where the quest is checked out here; otherwise through a runtime of it, later, or after the user checked it out). O-6's sentence is `p1s1r4-2`'s, already in |
| Q-11 | ask QT-11 | **PQ-56** | CQ.7 names the operations without the program; PQ-56 covers the screen row and the component (`p1s1r4-5`'s note) |
| Q-12 | apply | applied | CQ.7 create: an existing repository, or a new one only after a confirmation, private, Actions off |
| AB-8 | apply | applied | CW.3: `.worktrees/` under the root, the tree per execution, the names for the Blueprint, the fleet's skills follow |
| AB-9 | apply | applied | CW.16: off unless switched on, when a claim is taken or the user asks, never on a schedule (O-6 is `p1s1r4-2`'s, already in) |
| AB-10 | ask QT-23 (PQ-34) | pointer | CW.14: the runtime writes the files, never stashes or discards what it did not make; who commits and pushes is PQ-34 |
| AB-11 | apply | applied | CW.13: a runtime reads an `_ai` file again before it writes (a sync may merge in place). E-17's half is `p1s1r4-2`'s, already in |
| AB-13 | apply | applied | CW.6: the checks run on the execution's machine, as part of an item a person queued; no scheduled or hosted check |
| AB-14 | ask QT-13 (PQ-46) | text kept | CW.13 says nothing of a reconcile as a lease |
| AB-21 | drop | dropped | as the triage (covered by Q-12) |
| AB-22 | drop | dropped | as the triage (covered by Q-7; retiring a quest is the workspace's rule) |
| TF-10 | ask QT-11 | **PQ-56** | no component and no server working copy written |

### Findings that also reach this part

| Finding | Done here |
| --- | --- |
| AN-4 | CW.4: "its run sends nothing else meanwhile" (CR.67) |
| AN-5, VX-17 | CW.5's line: whether a lease is kept while its run waits for an ask is open (PQ-39); until then held for as long as the todo is executed |
| AN-10 | CW.11: the place in the trail, since a session can be started over (CR.18, PQ-25). CQ.3's history keeps its text (PQ-54) |
| AN-30 | nothing: CW.20, CW.21, CW.23, CW.26 keep what PQ-47 decides; CW.27 states only pull and push |
| AN-32 | CW.6's line points to PQ-47 for the queue on the GitHub backend |
| AN-42, ID-4 | CW.18 unchanged (PQ-45) |
| IC-1, IC-7, ID-2 | CW.5's line (PQ-46) |
| GA-4 | CW.7: the runs execute only non-overlapping todos at the same time; a run executes one item at a time (CR.67) |
| GA-6, TF-6 | nothing: CQ.3, CQ.6, CQ.7 keep their text (PQ-36) |
| GA-14 | CW.26: a line pointing to the one under CA.44 |
| GA-19, GA-23, ST-5, ST-7, ST-16, ID-1, ID-10 | nothing (QT-21, `p1s1r4-11`) |
| GA-25, ST-2 | CQ.5's source and the removed check paragraph |
| GA-27 | nothing to change; CV.12's line quotes CW.5 |
| ST-3 | the lead-in of `PAR-APPROACH` states the approach without "the concept only proposed … are confirmed" |
| ST-9 | nothing (QT-19) |
| ST-10 | CW.2's "(also called change-branch mode)" left for `p1s1r4-11` with the glossary entry |
| VX-28 | CW.21 points to CR.83 for a held item whose blocker is done |
| VX-33 | CW.23: the done notification the item or todo asks for (CR.93, CR.94), to the run and session that queued it, nothing when none is asked for |
| VX-42 | CQ.4: in the quest's folder of notes, agents never write them (S22 AC-13) |
| VX-44 | CQ.11 names the journal of asks and answers among the per-host files (place: PQ-54) |
| A-1 | S22 cited in CQ.1, CQ.5, CQ.9 … CQ.13 |
| A-3 | CQ.11 refers to CR.47 for the four classes and lists what falls into each |
| A-7 | nothing (CA.17, `p1s1r4-6`) |
| Q-9 | CQ.9 refers to CR.33 and CR.100 |
| AB-5 | CW.5: the branch the record names for the repository (CR.104) |
| AB-6 | nothing: where a quest's list is recorded stays with CR.35 |
| AB-7 | CW.3's line: an execution in a working tree still gets its workspace folder's instruction files (CR.59) |
| AB-12 | CQ.6: the registration of the drivers on the machine; the drivers are the fleet's (E-5) |
| AB-19 | CW.3's line: the Blueprint keeps the place and names of the trees short or settable per machine (path length on Windows). The risk itself is `p1s1r4-10`'s |
| AB-24 | nothing (CR.51, CR.52) |

### The points of the todo's description

- **`PAR-QUESTS` states the standard** (S22): the three types (CQ.1); the register and the
  workspace's list (CQ.9); the binding of a quest to a workspace (CQ.10); the four classes and
  what falls into each (CQ.11, on CR.47); the operations (CQ.7); merge rules, guards and syncing
  (CQ.12); what stays in `_ai` (CQ.13). Written as what the runtime does; nothing on how the fleet
  migrates. The format version is not named here (CR.3 is `p1s1r4-3`'s; see below).
- **What the standard leaves open against decisions** is asked: the personal repository against
  per-host files in the quest, with the privacy of a shared quest (PQ-54; CQ.2, CQ.3, D-34);
  member branches, the second repository, the secret scan, member access and the trial migration
  (PQ-55; CQ.6, CQ.7, D-34); a quest inside a project's code repository (PQ-56).
- **`PAR-APPROACH`:** the integration step and its lease (IC-1) — PQ-46, pointed to at CW.5; where
  the queue runs and who runs the checks (IC-2) — CW.6 applied; where the working tree lives and
  how its branch is named — CW.3 (`.worktrees/`, per execution, names for the Blueprint); CQ.6's
  branch per member against CW.14 / CW.2 — PQ-55, and CW.2 now says the `_ai` state gets no working
  tree per execution, since a quest of a multi-quest repository is itself a working tree of its
  branch; a run waiting on an ask while it holds an exclusive lease in strict mode — PQ-39, pointed
  to at CW.5.
- **`PAR-CROSS`:** sent items (CW.19, CW.20), done notifications (CW.23) and todo offers (CW.26)
  stated against what the extension does today; today the waiting is in the receiver's inbox with
  a mark at the sender, which CW.19 changes on purpose (VX-34) — stated as the runtime's behaviour.

### Done otherwise than the row says

- **CW.14** (IC-6 says "keeps its text"): its text is kept, and one sentence is added from the
  standard (the branch of a quest in a repository of its own) with member branches named as open.
  Without it CW.14 would contradict CQ.1 for the multi-quest form.
- **CW.2**: "never gets working trees of its own" became "never gets working trees per
  execution", with the reason; the standard checks out each quest of a multi-quest repository as a
  working tree, which the old wording forbade.

### Obligations changed

| Item | Change | Source |
| --- | --- | --- |
| CQ.1 | three types instead of two | S22 § 3.1; PQ-24 |
| CQ.7 | six further operations; create with confirmation, private, Actions off; migrate several quests into either form, one way | S22 § 4, § 2.4 |
| CQ.9 … CQ.13 | new: register, binding, four classes per quest, merge rules and guards, what stays in `_ai` | S22 |
| CW.6 | the runtime carries out the integration step; tac only orders; checks on the execution's machine | IC-2; N-34, N-28; CW.1 |
| CW.16 | when the fast-forward happens (claim taken or user asks; never on a schedule) | S27: `14_loose_wslayout-5` |
| CW.20 | never creates a run; `default`; receiver's defaults | S23: ww_a_collab-4 |
| CW.21 | both directions; release condition from the registry | S23: vscimpb121, ideatests2 |
| CW.23 | only the done notification asked for; none by default | S23: vscimpb146 |
| CW.25 | written directly only where the quest is checked out here | S22 § 4 |
| CW.27 | new: files travel by the user's pull and push; tac carries only the notice | S22 § 4, QM-10; O-6 |
| CW.13 | a runtime reads an `_ai` file again before writing | S27, `repo_skills_new.md` § 4 |
| CW.3 | the trees under `.worktrees/` | S27, `repo_skills_new.md` § 5.12, § 5.13 |

### Sources needed

None new. Cited: S22 (§ 1, § 2.2, § 2.4, § 3.1 … § 3.6, § 4), S23 (`ww_a_collab-4`, `vscimpb121`,
`ideatests2`, `vscimpb146`), S27 (`repo_skills_new.md` § 4, § 5.12, § 5.13;
`workspace_layout.md` § 4; `14_loose_wslayout-5`; `legws1`). The completed fixture todo
`11a_wslayout-1` (archived, not in S27) is not cited; `repo_skills_new.md` carries the same facts.

### For other parts

- **`p1s1r4-3`**: CR.3 and E-1 say "format version 10"; S22 now names **version 11** (§ 3.6,
  "`aiFormatMigration`, version 11"; its § 5 phase 1 "format version 11"). `PAR` names no number.
  CR.53, CR.55, CR.79 already say "per host" and point to the place as open — the question is
  PQ-54 (at CQ.2).
- **`p1s1r4-5`**: PQ-56 covers the screen row and the component for managing quests; the
  paragraph under the screen inventory can name PQ-56.
- **`p1s1r4-10`**: D-34 waits for PQ-54 and PQ-55; the new risk of AB-19 can cite CW.3's line;
  R-15 / R-16 can name the quest operations (CQ.7) as not built (E-14 says so).
- **`p1s1r4-11`**
  - Insert PQ-54 after CQ.2, PQ-55 after CQ.6, PQ-56 after CQ.7.
  - Merge candidates: PQ-54 and PQ-55 both follow from S22 against D-34; PQ-56 relates to PQ-38
    (the web runtime service) for the server working copies.
  - `GLO`: quest (three types; "folder quest" and "repo-based quest" as S22's words for classic
    and repository quest), single-quest repository, multi-quest repository, register of quests;
    "personal repository" waits for PQ-54; worktree mode loses "change-branch mode" with CW.2
    (ST-10).
  - `ABOUT > ABOUT-READ`: the range of `CW` (to CW.27) and `CQ` (to CQ.13); the new CQ items stand
    by content, not in the order of their numbers.

## `p1s1r4-9` — `NFR`, `NFR-TOPO`, `NFR-GEN`

Marks written: 87 additions, 40 substitutions, no deletion. New items: **N-35 … N-43**, **F13**,
**G-8 … G-10**. Question written: **PQ-57** (at the end of `new_questions.md`, section `NFR`).

### Rows of the work list

| Finding | Ruling | Done | Items changed or added |
| --- | --- | --- | --- |
| AN-27 | apply | applied | N-21 (a browser is not a paired device: which program faces the internet and how a browser is identified, PQ-49), N-26 (the web runtime client SDK beside the two), N-29 (where the JS/TS web SDK is published, PQ-41), N-30 (a guide for the service follows once it is described, CR.109); T5, T8 and the paragraph under the table ("web runtime service", the web runtime client SDK, HTTP, assumed until PQ-38); F1, F10, new **F13** (an application on a phone, a tablet or in a browser attaches); new **G-8 … G-10**. N-19 needed no new wording beyond PQ-51 (every access from the internet is strict already). The new decision, CON, RISK and DEL places are `p1s1r4-10`'s |
| IC-31 | apply | applied | F3 (lowest number first, CR.19), F6 (the copies written into the round folder, the round's blobs released, CV.12), F1 (registration with tac and the local service, CA.3, CA.34), F10 (trc reads through its runtime, CI.4), F11 (invitation CI.6, pairing CI.18, registration CA.3) |
| IC-34 | apply | applied | N-6 (the runtime names the revision, CT.15), N-23 (the prompt leaves no trail; a line for CP.6 and CW.11), the `NFR-GEN` lead-in ("the register above"). The `VIS`, `SCO-IN`, CL.2, CK.4 and D-2 places: see "For other parts" |
| GA-18 | apply | applied, and asked | the `NFR` lead-in; new closing list "Not stated by the sources; the Solution Blueprint settles", **N-35 … N-43**; the numbers among them asked once with a proposed value each (**PQ-57**), as the todo's description asks. The audit record is left to PQ-51 (QT-14), said under the list. `USR > USR-TEAM` was done by `p1s1r4-2` |
| GA-20 | apply | applied | a paragraph under the unit register naming what is delivered and has no unit (CL.6, D-41, CI.20 / CA.27, CA.33, E-5 / CQ.6, CL.10); N-30 adds the security model. The program for phones and browsers is G-10 (with PQ-38). `DEL` and R-23 are `p1s1r4-10`'s |
| AB-20 | apply | applied | N-29: the public binaries repository and copyleft, the payload built per platform by a build the user starts, how a machine without the workspace gets it (CR.42). D-56 is `p1s1r4-10`'s |
| TF-12 | apply | applied | N-25: written for the Flutter version and widget libraries of the hosts, the version in `RISK > RISK-DEPS`. The new risk is `p1s1r4-10`'s |
| TF-13 | apply | applied | N-29: the Dart client SDKs and `tom_ai_runtime_ui` take no copyleft dependency; what the runtime installs is for the Blueprint |

### Findings that also reach this part

| Finding | Done here |
| --- | --- |
| AN-1, AN-6, VX-PQ24, VX-2 | F4 and F5 say "the run waits" (CP.21); F5 loses nothing else, it had no walk clause |
| AN-2, VX-PQ24 | N-15 no longer says "does not block a process for long": an ask is never lost, is escalated, is visible; the run that asked waits, the other runs go on; the user can answer, skip or resend |
| VX-27 | F3: the walk holds at the first todo it cannot run, its run is held; going on is the user's action |
| AN-14 | T8 and F13: the service reaches tac through the runtime on the server (CR.110) |
| AN-15, AN-35 | N-26: the Dart tac client SDK without `dart:io` as a capability no application of the first version uses; G-1: which tac client SDK the runtime contains is for the Blueprint |
| AN-32, IC-3 | N-12 (the repository server as the backend that cannot be reached), T3 (the personal team on the GitHub backend; the local backend on one machine), T4 (a team on the GitHub backend, PQ-47, PQ-50), F11 (CW.16) |
| AN-43 | N-30: "having the runtime and the tac server approved by Tom Secrets Manager" (PQ-32) |
| IC-9 | F1 and F12: "runtime installation" |
| IC-21 | N-4 follows CA.38 ("from `tac/2.0` on") |
| GA-3 | N-13 refers to CA.13 only; the numbers around leases are under CA.14 (`p1s1r4-6`) |
| ST-3 | the dated `tomspecs` version in `NFR-GEN` is replaced by a reference to E-21; N-13 loses "no longer" |
| ST-6 | applied here, because the todo's description says so: N-1 … N-7, N-11 … N-14, N-16 … N-20, N-22, N-23, N-25, N-26, N-31 are cut down to the expectation with a reference to the item. QT-21 (`p1s1r4-11`) need not ask about the repetition in `NFR` any more; whether topologies and units move out of `NFR` (ST-13) stays with QT-21 |
| ST-18, WW-17 | T8: the web runtime service, wave 3 of Webwork (L-8) |
| WW-9 | T2 stands (Webforge starts a quest's runtime); nothing to add |
| WW-14, TF-3 | N-17 and N-18 checked: they stand, now as references to CS.11 and CT.11 |
| AB-17, AB-19 | N-27: Windows paths at the length limit, lengthened by an execution's working tree (S27 `legws1`). The risks are `p1s1r4-10`'s |
| WW-20 | no compatibility item of `NFR` needed a change; TF-9's question is PQ-34 |
| Asked elsewhere (AN-20 … AN-26, AN-30, IC-1, IC-11, IC-12, IC-16, IC-19, IC-25, IC-28, GA-1, GA-2, GA-5, GA-6, GA-9, GA-13, GA-16, GA-30, ST-7, ST-9, ST-13, ST-15, ID-1, ID-2, ID-7, ID-9, VX-48, A-14, WW-1, WW-6, WW-7, WW-19, TF-4, TF-6, TF-8, TF-9, WRS) | the text points to the question that settles it, where a statement of this part depends on it: N-3 and F12 (PQ-40), N-10 and T2 (PQ-36), N-11 and T1 (PQ-48), N-19 (PQ-51), N-21, T5, T8, F5, F13 (PQ-49), N-24 (PQ-37), N-26 (PQ-41, PQ-42), T2 (PQ-52), T4 and F11 (PQ-47, PQ-50), F8 (PQ-46), G-6 (PQ-43), T8, F13 and G-8 … G-10 (PQ-38, PQ-41). The rest leaves this part's text as it stands |

### The points of the todo's description

- **N-15 against PQ-24 (b):** done (see above).
- **N-30 for PQ-32:** done.
- **T3:** the GitHub backend serves the user's personal team across the user's machines, and simple teams of several members (T4); the local backend serves one machine only (T1, T3).
- **T5 and T8:** what runs on the always-on machine (the tac server and the web runtime service, assumed until PQ-38) and what a phone, tablet or browser reaches (the web runtime service with the web runtime client SDK; the program facing the internet is open, PQ-49).
- **F7 and F8:** F7 follows CW.19, CW.20 and CW.23 as `p1s1r4-8` left them; F8 fast-forwards the branch the record names (CR.104) and names PQ-46 for the lease rules.
- **F12:** the line stands, with S22's other rule and PQ-40 named.
- **`NFR-GEN`:** G-8 (Dart), G-9 (JavaScript / TypeScript), G-10 (the service), one line each with kind and what it builds; technology only as the answer says it ("not stated" for the service), no mapper or emitter. The mappers and emitters were read from the tooling on 2026-11-25 (`tomspecs :ir-map --mapper`, `:ir-emit --standard`, `tomspecs` 0.18.0): the same eight mappers and five emitters as listed.
- **ST-6:** done (see above).
- **GA-18 numbers:** asked once, PQ-57, with a proposed value for each.

### Done otherwise than the row says

- **GA-18:** the row asks only for a list; the todo's description asks for the numbers as one question with proposed values. Both are done: the list N-35 … N-43 in the text, the numbers in PQ-57. N-39 … N-43 are not numbers and are not in PQ-57.
- **G-8 … G-10** against CR.109 ("No generation unit, deliverable or user group is named for the service until then") and `p1s1r4-5`'s note ("no generation unit is named for the web runtime client SDK"): the todo's description asks for one line per unit the answers add. The rows are named from PQ-28 only, and the paragraph under them says that whether they are units of their own is open (PQ-38, PQ-41).
- **N-27:** AB-19 asked for a line under CW.3 (`p1s1r4-8`'s item); CW.3 does not carry it, so N-27 states the fact with its source.

### Obligations changed

- **N-3:** no longer says that a migration runs once per machine while the other runtimes pause; that is open (PQ-40, S22 § 5).
- **N-12:** the runs are held after their current item (CA.32), not the queues stopped after the current todo; "the backend" includes the repository server of the GitHub backend (PQ-29).
- **N-15:** no promise that an ask does not block a process for long; the run that asked waits (PQ-24 (b)).
- **N-21:** no longer "reached only by paired devices": a phone or tablet is paired; how a browser is identified is open (PQ-28, PQ-49).
- **N-25:** adds that the components follow their hosts' Flutter version and widget libraries (TF-12).
- **N-29:** adds the copyleft rule for what is bundled into the public binaries repository and for the Dart client SDKs and `tom_ai_runtime_ui` (AB-20, TF-13).
- **N-30:** adds the security model as a document.
- **F3, F4, F5:** the walk holds and its run is held; the run waits while an ask or a gate decision is open (PQ-24 (b); vscimpb37).
- **F8:** the integration step lands on the branch the repository record names (CR.104).
- **F11:** names invitation, pairing off the VPN and registration; the fast-forward of CW.16 as the exception.
- **New N-35 … N-43, F13, G-8 … G-10:** see above.

### Sources needed

None new. Cited: S22 § 5 (N-3, F12), S23 (`vscimpb37`, `vscimpb46`, `vscimpb55`), S25 (`05a_flutterm1`, `06b_flutterm1`, `13_woneb6`), S26 (`06a_flutterm1`), S27 (`binlic1`, `binpriv1`, `legws1`, `repo_structure_new.md` § 4), S14 § 4.

### For other parts

- **`p1s1r4-2`**: E-21 names `tomspecs` 0.17.0; the tooling answered 0.18.0 on 2026-11-25 (`tom_binaries/tom/darwin-arm64/tomspecs`). `SCO > SCO-IN`, the last row (the split) can cite N-24 beside N-32 and N-33 (IC-34).
- **`p1s1r4-3`**: CR.109's last sentence ("No generation unit, deliverable or user group is named for the service until then") now meets G-10, which names the service as a unit from PQ-28 only and points to PQ-38; the sentence could read "… is described for the service until then; `NFR > NFR-GEN`, G-10 names it as a unit".
- **`p1s1r4-5`**: G-8 and G-9 name the web runtime client SDK as units from PQ-28 only, pointing to PQ-41; CL.12 can refer to them.
- **`p1s1r4-8`**: AB-19's line under CW.3 (Windows path length; keep the trees' place and names short or settable per machine) is not in CW.3; N-27 states the fact.
- **`p1s1r4-10`**: AN-27's places in `DEC`, `CON`, `RISK`, `DEL`; IC-34's D-2; GA-20's `DEL` and R-23; AB-20's D-56; TF-12's new risk in `RISK > RISK-DEPS` (the hosts move to Flutter 3.50 and Dart 3.14 with `material_ui` and `cupertino_ui`; N-25 points there); AB-17 and AB-19's risks (N-27 points to the Windows path length).
- **`p1s1r4-11`**
  - Insert PQ-57 at the end of `NFR` (after N-43). Merge candidate: none.
  - PQ-41 should name where the JavaScript / TypeScript web runtime client SDK is published (the binaries repository only, or also npm); N-29 points to PQ-41 for it (AN-27, the publishing of N-29).
  - QT-21: the repetition of capabilities in `NFR` (ST-6) is done; topologies and units out of `NFR` (ST-13) remain for it.
  - `ABOUT > ABOUT-READ`: the ranges of `N` (to N-43), `F` (to F13) and `G` (to G-10).

## `p1s1r4-10` — `DEC`, `CON`, `RISK`, `DEL`

Marks written in `DEC` … `DEL`: 37 substitutions, 6 deletions, 164 additions (counted from the
section heading `DEC` to the end of the document after the work). New items: **D-61 … D-72**,
**X-16 … X-21**, **R-25 … R-29**. Question written: **PQ-58** (section `DEL` of
`new_questions.md`).

### Rows of the work list

| Finding | Ruling | Done | Items changed or added |
| --- | --- | --- | --- |
| AN-7 | apply | applied | new **R-25** (one unanswered ask holds a whole run; in strict mode a repository leased); R-10 second trigger; `DEL` "The order of building": the held todo and its run (CR.23), a run waiting for an ask sends nothing (D-61, R-25) |
| IC-23 | apply | applied | D-22, X-4: built as the full tac server, no smaller one before it; "built first" gone |
| IC-24 | apply | applied | D-20: routed by presence and along a chain of persons (named person, quest owner, owner of the triggering quest, team owners); "by role" gone |
| IC-30 | apply | applied | D-8 shaped `RT > RT-TRANSPORTS` only; D-16 shaped `RT > RT-TRANSPORTS`; PQ-20's sentence moved out of D-59 into new **D-72** (shaped `TAC-PEOPLE`, `TAC-GROUPS`). The `SCO > SCO-IN` rows are `p1s1r4-2`'s (see "For other parts") |
| GA-21 | ask QT-20 | **PQ-58** | `DEL` "The order of building": one line saying everything is delivered in one go and that the acceptance and a first usable state are asked; D-45, D-21, D-32 unchanged |
| GA-24 | apply | applied | the heading over D-44 …: PQ-5 and PQ-11 carry no decision of their own (asked again as PQ-21 and PQ-20) |
| ST-8 | apply | applied | "first version" in D-47, D-50, R-24, X-11; "first delivery" is no longer written in this part |
| ID-7 | ask QT-20 | **PQ-58** | the thin path is the recommended option (b) |
| VX-56 | apply | applied | R-16: the layering of the engine (services importing handlers and tools, nothing checks it) as work the extraction depends on; source `vscimpb176` |
| A-15 | apply | applied | R-16: the new format and the quest management among the remaining features, after the cutover; R-15: what they wait for; D-40 and `DEL` step 1 name them |
| AB-16 | apply | applied | R-20's state: the fleet's VPN-only plan run from a clone, rewritten against CA.27 … CA.30, N-28, N-29; the reverse proxy exists; deployment beyond that for the Blueprint; new **X-21** |
| AB-17 | apply | applied | new **R-26** (one machine's VPN fails for hours unnoticed; runs held, CA.32); R-13's trigger adds a machine offline for weeks meeting newer formats |
| AB-19 | apply | applied | new **R-27** (Windows path length with working trees), citing CW.3 and N-27 (the line under CW.3 is in, by `p1s1r4-8`) |
| AB-27 | apply | applied | R-15's state (resolver and layered configuration built; migration tool and new fleet skills written and tested; cutover and what follows open) and the order: cutover, new format, quest management, coordination repository and tac server |
| WW-22 | apply | applied | `DEL`, new paragraph "What the other quests are told when the todos are filed": the `webwork` line (two messages; wave 1b2 without a date; D13 and D40 need the two specifications first; WW-10, WW-14, WW-16 and the new names in the first message) |
| TF-1 | apply | applied | the same paragraph, the `tom_forge` line (CL.3, L-9, CT.12, CT.11, CU.3, CU.10, PQ-44, its waiting entries re-pointed) |
| TF-14 | drop | dropped | covered by TF-1's line ("its entries that wait on todos of this quest are moved to the new ones"); the list of entries is input of the filing |

### Findings that also reach this part

| Finding | Done here |
| --- | --- |
| AN-1, VX-PQ24, VX-2, AN-6, VX-27 | new **D-61**; D-20 names it and loses nothing else (it had no walk clause; its "Replaces" column names DQ-3's) |
| AN-2 | R-25 |
| AN-5 | D-55, D-61 and R-10 name PQ-39 |
| AN-8, Q-3, Q-6, VX-43 | D-34: first part replaced by D-71; the personal repository open again (PQ-54), CQ.6's rest asked (PQ-55); new **X-17**; R-16, `DEL` step 1 |
| AN-15, IC-34 | D-2: who uses the tac client SDK (D-63); what the runtime client SDK takes from it is for the Blueprint (CL.2) |
| AN-17, AN-29, AN-30 | X-11: "leases and endpoints", D-64, D-66, "first version", PQ-47; D-47 |
| AN-19, AN-20, AN-25, AN-26, AN-27, WRS, GA-1 | new **D-65** (the answer to PQ-28 as a direction, not a design); D-3, D-10, D-27, D-50, D-51, D-52; X-3, X-12, X-14; R-8, R-12, R-22, R-24; `DEL` (the runtime track builds the service and the web SDK; the delivered list) |
| AN-21, IC-19 | D-23: whether the relay is on a phone's path and which program a device reaches is asked (PQ-49); the web runtime service is not a relay |
| AN-22, ID-9 | D-3, D-50, R-12: PQ-41, PQ-42 |
| AN-23 | D-10 |
| AN-31 | D-18, D-25, D-53: PQ-50 |
| AN-32 | D-24, D-25, D-47, D-53; R-3, R-20 (D-54 is the tac server's setting only and stands) |
| AN-34, IC-28, VX-48, WW-1, TF-8 | R-19's state (planned outside; PQ-43); new **X-19**; `DEL` delivered list |
| AN-37 | `DEL`: the extension's messaging views come once the runtime is built (O-1; D-67) |
| AN-38 | X-3 (no application is a tac client; L-12; D-67); R-3's trigger (the reviewer's application built outside this product) |
| AN-40 | D-59 (`git:`; D-68), D-60, X-15; new **D-68** |
| AN-41, TF-9, IC-32, WW-20 | R-18: `tom_todo_model` 4.2.0 (E-2); PQ-45, PQ-34 |
| AN-43 | D-19 "approved by" (D-69); new **D-69** |
| AN-45 | D-60 points to D-70 for the further terms; the glossary itself is `p1s1r4-11`'s |
| IC-1, ID-2 | D-55: PQ-46 |
| IC-9 | R-13: "runtime installation" |
| IC-16 | D-13: PQ-48; new **X-20** |
| IC-33 | X-13, X-14 cite PQ-6 and PQ-9; the heading over R-22 … no longer counts a round |
| GA-20 | `DEL` delivered list names what has no unit yet; R-23's trigger |
| GA-30 | nothing changed (PQ-35 asks what of the split stays in the extension; D-40, D-41, R-1 keep their text) |
| ST-1 | the decisions from PQ-24 … PQ-33 under their own heading, D-61 … D-70 |
| ST-3 | the heading over the further risks; X-3 states the current resolution |
| ST-7, ST-13, ST-15 | nothing changed (QT-21, `p1s1r4-11`); R-12 and R-24 stay two rows |
| AB-8, AB-11 | R-15 names the new fleet skills as written and tested |
| AB-15, AB-18 | R-20 cites CA.28; its "For" adds the check of the VPN on phones (CK.12), with no todo yet |
| AB-20 | D-56: the public binaries repository, nothing copyleft bundled (N-29) |
| WW-10, WW-14, WW-16, TF-3 | in the two messages of `DEL`; WW-14 also as new **X-16** (resolved toward CS.11, D-19) |
| WW-11 | D-16 open again (PQ-37) |
| TF-12 | new **R-29** in `RISK > RISK-DEPS` (the hosts' move to Flutter 3.50, Dart 3.14, `material_ui`, `cupertino_ui`; N-25 points there) |
| VX-28 | `DEL` names the todo and CR.83 (planned) |
| VX-41 | D-7: "the runtime does not carry" instead of "are removed" |

### The points of the todo's description

- **DEC:** D-61 … D-70, one for each answer PQ-24 … PQ-33, under a heading of their own; **D-71**
  takes al_the_bear's `_ai` format and its three quest types as the standard (with the four
  questions that keep what decisions back: PQ-54, PQ-55, PQ-56, PQ-40); **D-72** carries PQ-20's
  sentence out of D-59. Brought to the current state and naming the later decision: D-34 (D-71;
  open again, PQ-54, PQ-55), D-51 (D-65; open, PQ-49), D-52 (D-65; assumed until PQ-38), D-3 and
  D-50 (D-65; PQ-41, PQ-42), D-10 (D-65; PQ-41), D-19 (D-69), D-20 (D-61), D-27 (D-65, D-67),
  D-59 (D-68, D-72), D-60 (D-68, D-70). Open again because their question is asked again: D-13
  (PQ-48), D-16 (PQ-37), D-34 (PQ-54, PQ-55), D-51 (PQ-49).
- **CON:** settled by this round: X-3 (D-65, D-67), X-11 (D-64, D-66; PQ-47 for the rest), X-12
  (D-65; PQ-38), X-15 (D-68); X-14 open again (PQ-49). New: X-16 (resolved, D-19), X-17 (PQ-54),
  X-18 (PQ-40), X-19 (PQ-43), X-20 (PQ-48), X-21 (resolved, D-22, D-23).
- **RISK — whether the state changed** (for the closing item):

| Id | State |
| --- | --- |
| R-1, R-2, R-4, R-5, R-6, R-7, R-9, R-11, R-14, R-17 | unchanged |
| R-3 | changed: trigger adds teams on the GitHub backend (D-66) and the reviewer's application built outside this product (D-67) |
| R-8 | changed: wave 3 of Webwork with the web runtime service; open points PQ-38, PQ-49 |
| R-10 | changed: second trigger, a lease held while its run waits for a person (PQ-39) |
| R-12 | changed: the web runtime client SDK; PQ-42 |
| R-13 | changed: "runtime installation"; when a migration runs is asked (PQ-40); a machine offline for weeks |
| R-15 | changed: state and the order of what the fleet builds first |
| R-16 | changed: the new format, quest management and the engine's layering named |
| R-18 | changed: 4.2.0; PQ-45, PQ-34 |
| R-19 | changed: planned outside this product in two forms; asked (PQ-43) |
| R-20 | changed: the fleet's plan to rewrite, the order after R-15, the VPN check on phones |
| R-21 | changed: refers to E-21 |
| R-22 | changed: an undesigned architecture for phones and browsers; PQ-38, PQ-49 |
| R-23 | changed: a deliverable without a unit as a trigger |
| R-24 | changed: "first version" |
| R-25 … R-28 | new risks |
| R-29 | new dependency |

- **DEL:** the deliverables follow the items: the three client SDKs and their languages (CL.12,
  G-3 … G-5, G-8, G-9; PQ-41, PQ-42), the web runtime service (G-10; PQ-38), the review component
  (PQ-43), the Flutter components against the three existing packages (E-20; PQ-44), what has no
  unit yet, what is not delivered here (O-10, O-1). What the first version contains and in which
  order: "in one go" (D-21, D-32, D-45) with the acceptance and a first usable state asked
  (PQ-58); one register of the first version is QT-21's (`p1s1r4-11`).

### Done otherwise than the row says

- **R-15's format version.** AB-27 and the todo's description name "format version 10"; S22
  § 3.6 now names **version 11**, while CR.3 and E-1 say 10. R-15, R-16, D-40, D-71 and `DEL`
  write "the new format of the `_ai` files (CR.3)" without a number, so this part does not
  contradict CR.3; see "For other parts".
- **The new decisions' "Replaces or completes" column** names what a decision replaces; the
  older decisions that a new one overtakes name the new one in their decision text, not in that
  column.
- **R-12 and R-24** stay two rows (ST-7 is QT-21's).

### Obligations changed

- **D-20, D-61:** the run that asked waits as a whole; no walk goes on (PQ-24 (b)).
- **D-22, X-4:** no order of building implied; the tac server is the full one, no smaller one before it.
- **D-27, D-52, D-65:** phones, tablets and browsers through the web runtime service and the web runtime client SDK (Dart, JavaScript / TypeScript); one runtime per connection only assumed (PQ-28).
- **D-3, D-50:** three client SDKs; the web runtime client SDK in two languages beside the two in nine.
- **D-34, D-71:** repository quests in the two forms of the standard; the personal repository open again.
- **D-47, D-66, X-11:** the GitHub backend serves simple teams of several members.
- **D-59, D-68:** resource names carry the prefix `git:`; a part of the `_ai` state's repository is claimed when a todo names it.
- **D-64:** tac keeps no record of the holder of leases (PQ-27 (a)).
- **D-67:** no review application; no application is a tac client (PQ-30 (a)).
- **D-69:** "approved by" Tom Secrets Manager; pairing only for devices (PQ-32 (a)).
- **`DEL`:** the delivered list, the runtime track builds the web runtime service and the web runtime client SDK, the two messages to `webwork` and `tom_forge`.
- **New R-25 … R-29.**

### Sources needed

None new. Cited: S22 § 5, § 7; S23 (`01_aifmt-1` … `-5`, `02_aifmt-1`, `vscimpb176`, `vscimpb179`); S25 (`webwork_wave1_plan.md`, `09_woneb5`, `13_woneb6`, `05a_flutterm1`, `06b_flutterm1`, the notes on `12a_woneb1` … `14_woneb2`); S26 (`qavs_wwworkbench-1`, `05b_woneb1` … `-5`, `06a_flutterm1`); S27 (`workspace_layout_plan.md`, `12a_wslayout-2`, `14_loose_wslayout-6`, `tsmfleet3`, `tsmfleet9`, `vpnhang1`, `legws1`, `repo_structure_new.md` § 2); S14 part two.

### For other parts

- **`p1s1r4-3`** (or `p1s1r4-11`): CR.3 and E-1 say "format version 10"; S22 § 3.6 and § 5 say
  **version 11**. This part writes no number; CR.3, E-1, E-14, E-22 and CQ items should follow S22.
- **`p1s1r4-2`** (or `p1s1r4-11`): IC-30's `SCO > SCO-IN` rows: the Agent Client Protocol belongs
  to the `CR` row, not `CP`; the `CI` row adds PQ-12, PQ-20 and PQ-23 to its sources.
- **`p1s1r4-11`**
  - Insert PQ-58 into `DEL` after "The order of building" (after the line that names it).
  - `ABOUT > ABOUT-READ`: the ranges of `D` (to D-72; the decisions from PQ-24 … PQ-33 are
    D-61 … D-70, D-71 is the standard, D-72 is PQ-20's), `X` (to X-21) and `R` ("R-1 to R-14 and
    R-22 to R-28 are risks; R-15 to R-21 and R-29 are dependencies").
  - The `DEC` lead-in can name `PQ-n` among its source ids; the new heading names the answers'
    folder.
  - `GLO`: the entries D-62 (session started over), D-64 (holder), D-66 (personal team, team),
    D-68 (resource name), D-69 (pairing, approved by) and D-70 (the further terms) shape.
  - Merge candidates for PQ-58: none (QT-21's register of the first version is related).

## `p1s1r4-11` — `GLO` and the whole document

Marks written: 130 additions, 16 substitutions, 9 deletions. The ten question blocks
`PQ-24` … `PQ-33` removed (unmarked, as answered blocks are). 26 question blocks inserted.
The terminology document (S21) edited as plain text.

### Rows of the work list

- **AN-3** → `GLO` ask (the run waits until the ask is settled, with the three ways it is
  settled), run (waits while an ask of it is open), execution (one waiting for an answer is the
  same execution); the words "waits", "is held", "paused", "settled" in the further terms.
- **AN-28** → `GLO` team (not bound to a tac server; a team with each backend), personal team
  (local backend: one machine; GitHub backend: the user's machines sharing the coordination
  repository), backend (with what each serves), member / owner and invitation / team token (stated
  for a tac server; the GitHub backend open: PQ-47).
- **AN-33** → `GLO` application (without the review application), host (the last sentence gone;
  the web runtime service in place of the runtime host server, assumed until PQ-38), user (a
  person using an application).
- **AN-44** → `GLO` device / pairing ("a server"; pairing for devices only, D-69; the program a
  device reaches is open, PQ-49); "approved by" in the further terms; the words-not-used table.
- **AN-45** → `GLO` table "Further terms of this document" with every term PQ-33 lists, each in
  the wording of its item: walk, gate, role and role type, quest owner, done notification, relay
  (the tac server's only), notification and command (between runtimes, their further senses to
  PQ-58), capability block, repository server, standalone runtime, classic quest and repository
  quest with the single-quest and multi-quest forms, personal repository (CQ.2's wording; PQ-53),
  root and workspace folder; "profile" and "coordinator" with the definitions PQ-33 proposed
  (the coordinator's wording follows U-15 and CV.12). S21 § 2.6 the same; the SRC row of S21
  says the two are kept equal; D-60 already points to D-70.
- **AN-46** → the further terms also hold: walk continuation, step boundary, subject, aspect
  guidelines, pre-prompt and follow-up, timed request, staged, journal of asks and answers, ask
  envelope, reverse request, quest member, review copy and base, access key, coordination
  repository, web runtime service, web runtime client SDK, always-on machine, the `_ai` state,
  register of quests, the four classes of files. Not entered: the words with several senses
  (PQ-58), "integration lease" (PQ-46), "first version" against "first delivery" (PQ-57).
- **ST-10** → `GLO` run (without "as the term is used in the VS Code extension"; with CR.8,
  CR.9, CR.67), quest (without the comparison; the three types), host (without the review
  application). "Change-branch mode" stays as the second name of worktree mode until PQ-58.
- **ST-17** → the ten blocks removed and their lists closed up; the blank lines inside lists
  before CR.13, CR.14, CP.9, CP.30, CI.11, CK.9, CK.10, CW.25, CW.26, X-8 and X-13 removed.
- **ST-9** → asked: PQ-58 (with AN-11, AN-18, IC-29 and the second name of ST-10).
- **GA-19, GA-23, ST-5, ST-6, ST-7, ST-13, ST-15, ST-16, ID-1, ID-10** → asked: PQ-59.
- **ST-4, ST-12** → dropped as the triage says; checked: 709 ids are defined exactly once, every
  id referred to is defined, and no number of an area is missing or used twice.

### Findings that also reach this part

Taken into `GLO`: AN-9, VX-19, VX-20 (session: started over, base, lifetime, profile, the default
session `default@<run>`); AN-15 (client SDK: three, and who uses the tac client SDK); AN-17,
IC-15 (holder: the full list, no holder record); AN-40 (resource, resource name, overlap with
`git:`); IC-26 (message kind: eight kinds plus the two between runtimes); WW-2 (round folder in
the documents' storage); GA-4 (run executes one item at a time); GA-22 (coordinator); IC-13
(host); ST-3 (team runtimes: "replaces" gone); AN-8, Q-1, VX-46 (quest types, register, S22's
words named once); AB-5 (integration step lands on the branch the record names). Checked without
a change: WW-3 (review set "pinned in tac" stands), GA-14 (CA.44 carries the Blueprint line).
Kept as they are until answered: AN-5 (strict mode, PQ-39), AN-11 and IC-29 (conversation,
queue item, PQ-58), AN-20, AN-24, WRS (host and server, PQ-38), IC-1, IC-7, ID-2 (exclusive lease,
fencing token, PQ-46), IC-11 (runtime, PQ-51), A-4 (trail, PQ-53), Q-3 (personal repository,
PQ-53).

### The cross-check

Corrected as marked changes (or inside this round's own additions):

- **Pointers to questions by place** ("the question at …", "an open question (`…`, CI.18)")
  replaced by the question's id in 28 places: the S22 row; the trc, web runtime service and
  client SDK rows and the hosts paragraph of `VIS > VIS-SYSTEM`; U-3; the `CR`, `CK` and `CQ` rows
  of `SCO > SCO-IN`; O-10; L-5, L-6, L-8; E-16, E-20; CR.55; CP.1, CP.11, CP.36; CT.12; the end of
  `RT > RT-ASKS` (twice); the paragraph after CP.34; the line under the screen inventory; CK.2;
  CK.10 (twice); CK.11.
- **Names:** CP.31 "a runtime installation" (IC-9); no "review application", "runtime host
  server", "remote runtime service", "pairing with Tom Secrets Manager" or "folder of the `_ai`
  state" outside `GLO`'s words-not-used table, `DEC`, `CON`, E-19 and O-10.
- **The format version:** the extension writes format version 10 since 2026-11-23
  (`_ai/format-version.yaml`), and S22 § 3.6 now names the next one **version 11**. CR.3, CR.100,
  E-1, E-14, the S22 row, the `CR` row of `SCO > SCO-IN`, the line on reminders in E-1 and the
  line on the extension's migration say version 11, and E-1 says version 10 today. PQ-40 says
  the same.
- **History wording:** "the earlier agent_container and project_coordination work" (the line
  "Not a source" and O-8) reads "the agent_container and project_coordination work, archived in
  `tom_archived`"; CA.28's line on the fleet's plan says what the plan does not yet know instead
  of when it was written. "Earlier" stays where it is not history ("the earlier context" of a
  conversation, CR.18; "never earlier", CR.80) and in `DEC` and `CON`.
- **AN-36:** P-3 says that with the product such a reviewer uses an application that carries the
  review component, reaching tac through its runtime.
- **Version:** E-21 names `tomspecs` 0.18.0 (the package's version on 2026-11-25).
- **Leftovers of the parts:** CR.109's last sentence names G-10 (from `p1s1r4-9`); CL.12 names
  G-8 and G-9 (from `p1s1r4-9`); the split row of `SCO > SCO-IN` cites N-24 (IC-34, from
  `p1s1r4-9`). Already done by their parts: the `SCO > SCO-IN` rows of IC-30 (Agent Client
  Protocol in the `CR` row, PQ-12, PQ-20, PQ-23 in the `CI` row), AB-19's line under CW.3.
- **Marks:** every `{~~` has one `~>` and its `~~}`; every `{++`, `{--`, `{>>` its closing mark;
  none nested; no blank line inside a mark (1,155 marks checked).
- **References:** every section-id chain resolves to a heading and its parents (one in the new
  PQ-59 was corrected to `NFR > NFR-TOPO > NFR-TOPO-FLOWS`); none is broken across lines; no line
  outside a question block starts with `>`.
- **Status:** the status line, the `PQ` row and the `R` row of `ABOUT > ABOUT-READ` say the round
  and its open questions; a new paragraph under the capability areas says that ids are never
  renumbered and names the highest id of every area.

### Done otherwise than the row says

- **AN-10** (from `p1s1r4-4`, addressed to `p1s1r4-8`): CQ.3 does not get the sentence that the
  history before a start-over stays in the trail. Triage § 1.6 keeps CQ.2 and CQ.3 unchanged until
  PQ-53 is answered; the start-over is stated in CR.18, CP.7 and `GLO` session.
- **Merging questions:** PQ-50 (members and team owners on the GitHub backend, from `p1s1r4-7`)
  is merged into PQ-47 (what a team has on the GitHub backend, from `p1s1r4-6`): both follow from
  the answer to PQ-29, and PQ-47's recommended table already had a row for members and owners. Not
  merged, with the reason: PQ-38, PQ-41 and PQ-49 (all from PQ-28) each settle a different group of
  items — what the service is, what its client SDK is, what faces the internet — and one question
  would ask three decisions at once; PQ-53, PQ-54 and PQ-55 (all from S22 against D-34) likewise
  — the personal files, the extras of repository quests, the quest operations. No question was
  dropped: none is settled by an answer, the terminology or a decided source.
- **Renumbered** after the merge, in the document and in `new_questions.md` (the sections of the
  other parts above keep the ids they wrote): PQ-50 → PQ-47, PQ-51 → PQ-50, PQ-52 → PQ-51,
  PQ-53 → PQ-52, PQ-54 → PQ-53, PQ-55 → PQ-54, PQ-56 → PQ-55, PQ-57 → PQ-56, PQ-58 → PQ-57.
  The two questions of this part are PQ-58 and PQ-59.
- **Questions completed** with points the parts left: PQ-36 also asks about forwarding a host
  tool to another host (CP.15, TF-2; from `p1s1r4-4`); PQ-41 also asks where the JavaScript /
  TypeScript web runtime client SDK is published (N-29; from `p1s1r4-9`); PQ-45 also asks how the
  repositories a runtime registers are written (CA.3; AN-41); PQ-38 and PQ-41 name the units
  G-8 … G-10; PQ-40 follows S22's version 11.

### Questions settled

| Id | Answer | Decision | Items changed |
| --- | --- | --- | --- |
| PQ-24 | (b), and S22 as the standard | D-61, D-71 | CP.21, CP.9, CP.22, CR.17, CR.20, CR.23, CR.67, CS.10, CW.4, N-15, D-20, F4, F5, `GLO`; for the standard: CR.2, CR.3, CR.47, CR.100, CQ.1, CQ.5, CQ.7, CQ.9 … CQ.13, E-14 |
| PQ-25 | (a) | D-62 | CR.18, CR.75 … CR.78, CP.3, CP.7, `GLO` session |
| PQ-26 | (a) | D-63 | CL.11, CL.12, CR.110, `GLO` client SDK |
| PQ-27 | (a) | D-64 | CA.5, CA.8, CA.20, CA.26, CA.29, CA.36, X-11, `GLO` holder |
| PQ-28 | free text: the names, no design | D-65 | CR.108 … CR.110, CL.11, CL.12, CI.4, T8, F13, G-8 … G-10, `GLO`; open points asked in PQ-38, PQ-41, PQ-49, each quoting the answer |
| PQ-29 | free text: teams of several members on the git-based backend | D-66 | CA.26, CA.39, CI.1, T3, T4, X-11, D-47, `GLO` team, personal team, backend; open points asked in PQ-47, quoting the answer |
| PQ-30 | (a), with free text | D-67 | O-10, L-12, CI.4, CA.28, CV.5, CV.15, P-3, U-2, `GLO` application, host, user; the review component asked in PQ-43 |
| PQ-31 | (a), with free text | D-68 | CA.9, CA.10, CA.11, CA.17, CA.41, CA.42, CW.7, X-15, D-59, `GLO` resource, resource name, overlap; the grammar asked in PQ-45 |
| PQ-32 | (a) | D-69 | CS.9, U-7, D-19, N-30, `GLO` device / pairing, approved by |
| PQ-33 | (a) | D-70 | `GLO` (the further terms), S21 § 2.6 and § 4 |

### Obligations changed

- `GLO` session, team, personal team, backend, client SDK, holder, resource name, overlap,
  integration step and host now define what the items demand in the terms of D-61 … D-69 (each
  term follows its decision).
- CR.3: the runtime is built on format version 11 of the `_ai` files, not 10 (S22 § 3.6); CR.100
  is planned with version 11.

### Sources needed

None. E-1 cites `_ai/format-version.yaml` by its path; E-21's version is that of
`tom_ai/ai_build/tom_specs_clitool/pubspec.yaml`.

### For the next round

- The 26 open questions; PQ-58 and PQ-59 change the glossary and the document's structure if
  their recommended options are taken.
- `CI.19` still carries a `___check here___` remark of `p1s1r4-7`.

## Closing check

Done by the round's closing item on 2026-11-25, after all eleven todos were completed (none
blocked, none left open).

- **Marks:** 1,155 in the document (218 substitutions, 910 additions, 27 deletions); each closed,
  none nested, no blank line inside one. Nothing was corrected.
- **Ids:** the 569 items defined before the round (the document as round 3's review left it,
  `project_idea.before_marks.md`, its marks accepted) are all still defined; 140 are new; none is
  defined twice. The 70 section ids resolve every section-id chain; no line outside a question
  block starts with `>`.
- **Questions:** none of PQ-24 … PQ-33 is left. PQ-34 … PQ-59 (26) each have Context, Why I ask,
  two or more options with exactly one bold, a recommendation naming that option, an assumption
  and an empty answer.
- **Glossary:** `GLO` and terminology § 2 have the same 99 rows with the same text.
- **Numbering in the part records:** the sections of `p1s1r4-2` … `p1s1r4-10` below cite the
  question ids they wrote before `p1s1r4-11` renumbered them (for example `p1s1r4-10`'s PQ-58 is
  PQ-57 in the document); the table "The questions asked" above has the final ids.

## G1 reading

A reading against gate run 2 (`../../quality/evidence/gates/G1_20261119-2045.gate.md`), not a
gate run. Run 2 read the document before rounds 3 and 4.

| Item | Run 2 | After this round |
| --- | --- | --- |
| G1-DOC-1 | pass | unchanged |
| G1-PROB-1 | pass | unchanged |
| G1-USER-1 | pass | unchanged; `USR` adds the hosts of the first version after PQ-28 and PQ-30 |
| G1-SCOPE-1 | pass | unchanged in kind; `SCO` follows PQ-28 and PQ-30 (the review application out of scope, O-10) |
| G1-SRC-1 | pass | unchanged; S22 … S27 added, every new item cites one |
| G1-ID-1 | pass | unchanged: 140 new ids, none reused, none lost |
| G1-CLAR-1 | pass (no open question) | **fails as it stands.** 26 questions are open (PQ-34 … PQ-59). Each has a working assumption, but in eight of them the assumption is "the text says this is open", and the Blueprint's architecture builds on the answer: **PQ-38** and **PQ-49** (what the web runtime service is, and what faces the internet for phones and tablets), **PQ-41** (the web runtime client SDK beside the runtime client SDK), **PQ-46** (the lease rules: the integration step cannot start as written), **PQ-47** (what a team on the GitHub backend has), **PQ-51** (the team of a runtime that serves no quest — Webwork's and trc's), **PQ-53** and **PQ-54** (where a person's own files of a quest lie; what remains of member branches, the internal repository and the secret scan). These block the Blueprint. The other eighteen can be carried into Phase 2 under their assumptions. |
| G1-RISK-1 | pass | changed: R-3, R-8, R-10, R-12, R-13, R-15, R-16, R-18 … R-24 re-assessed, R-25 … R-28 new risks, R-29 a new dependency (below) |
| G1-CHANGE-1 | not applicable (initial development) | unchanged |

G1 has to be run again once the eight blocking questions are answered and taken in.

## Risk review

Taken from `p1s1r4-10`'s record (section below, "RISK — whether the state changed").

- **Changed:** R-3 (teams on the GitHub backend, the reviewer's application built outside this
  product), R-8 (Webwork's wave 3 with the web runtime service), R-10 (a lease held while its run
  waits for a person), R-12 (the web runtime client SDK), R-13 (when a migration runs; a machine
  offline for weeks), R-15 (state, and the order: workspace layout cutover, format version 10,
  quest management, coordination repository and tac server), R-16 (new format, quest management,
  the engine's layering), R-18 (`tom_todo_model` 4.2.0), R-19 (review component planned outside
  this product), R-20 (the fleet's plan for the tac server, the VPN check on phones), R-21, R-22
  (an undesigned architecture for phones and browsers), R-23, R-24.
- **New:** R-25 (one unanswered ask holds a whole run), R-26 (a machine's VPN failing unnoticed),
  R-27 (Windows path length with working trees), R-28 (Webwork and Tom Forge wait for the whole product without a date); R-29 a new dependency (the hosts' move to
  Flutter 3.50 and Dart 3.14).
- **Unchanged:** R-1, R-2, R-4 … R-7, R-9, R-11, R-14, R-17.

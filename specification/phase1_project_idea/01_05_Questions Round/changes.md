# Changes — Phase 1, question round 5

One section per part todo, as `round_instructions.md` § At the end of your todo asks.

## The round in summary

Question round 5 reworked the Project Idea on the product owner's two instructions of 2026-11-25
(`answers.md`, S31): **(a)** the feature baseline of the first version (**D-74**) and **(b)** the
new VS Code extension, a copy of the old one in `tom_ai/ai_build` that takes its place (**D-73**,
replacing D-41). Every change in the Project Idea is a marked change; nothing is approved yet
(G1 has not passed). The sections below this summary say part by part what was done.

### What the baseline added, per area

New items (none removed; ids are never reused):

| Area | New ids | What they carry |
| --- | --- | --- |
| `CR` runtime core | CR.111 … CR.142 (32) | the extension's built and planned engine features not yet in the text: todos archived and deleted into sibling files, moving and renumbering todos, generated ids, repairing dependencies, a todo's walk answer, the planned dependency closure (CR.113 … CR.118); assists and the expression language (CR.119, CR.120); night mode, the run's lane, the marker of a process step, chat sends and their response time, commands on a run's queue, moving items, run defaults (CR.121 … CR.128); reviewing an agent's changes per change, stored tool results, sessions without a conversation, the queue's control items (CR.129 … CR.138); approval modes, usage per provider (CR.139 … CR.141); the old extension's own engine during the parallel period (CR.112) and the new extension as the VS Code host (CR.142) |
| `CP` protocol and hosts | CP.45 | the protocol carries every feature of the old extension's views |
| `CT` tools and MCP | CT.18 … CT.21 | a tool of another runtime keeps its name; stored tool results with replay keys; writing tools guarded against changed and unsaved files; the core tool set |
| `CA` coordination | CA.45 | the tac client keeps within the repository server's limits on the GitHub backend |
| `CM` messaging | CM.15 | the service's time on every message |
| `CV` documents and review | CV.17 … CV.19 | the layout of a review (`reviews/<name>/`, `review.yaml`, `round-<n>/`), the state of a round read from its folder, where the review exchange works |
| `CW` parallel work | CW.28, CW.29 | only an item executing a todo claims; orphans |
| `CL` client SDKs | CL.13 … CL.15 | `tom_vscode_scripting_api` 7.0.0 keeps the VS Code namespace; the new extension as a TypeScript host |
| `CU` UI components | CU.18 | the coordination page: team runtimes, leases, endpoints, commands not taken, skipped repositories, working trees not integrated |
| `CS` secrets, configuration, providers | CS.21 … CS.26 | a provider reached through adapters, presets, the providers of this quest's `xx*` todos |
| Screens | SC-32 … SC-38 | the extension's screens the inventory lacked (among them DEPENDENCIES / WORK ORDER, SC-37; the review of an agent's changes, SC-38) |
| Non-functional | N-44, N-45 | the queue's watchdog (60 s, as built); the spec tools on documents of every size |
| Sources, users, scope, landscape | S28 … S31, U-17, O-11, L-13 … L-15, E-23 | the extension's collaboration plan (S28), Webwork's review and placement decisions (S29), this quest's todos (S30), the instructions (S31); the guest reviewer; what is retired and not carried; deferred items; the old extension today |
| Decisions, contradictions, risks | D-73, D-74, X-22 … X-26, R-30 … R-32 | the two instructions; the extension's collaboration plan against tac, the Dart client's place, Telegram, the in-place split against the copy; a second language runtime for an agent, two engines on one `_ai`, the swap |

Besides the new items, the parts rewrote existing items to the baseline as marked changes: citations
in the shapes of § Secondary prose, the built features cited by todo id, the planned ones marked
planned.

### What the second extension changed

D-73 replaces the in-place split of the extension (S18's stages, S19 § 7, this quest's
`ww_b_workbench-2` … `7`) by a copy:

- `DEC`: **D-73** written, **D-41** marked replaced; S18 and S19 carry "replaced by D-73" in
  their standing.
- `SCO-IN`'s row "The split" became "The new VS Code extension"; O-1, E-22, E-23, U-8 and
  `VIS-SYSTEM` name the old and the new extension.
- The runtime: **CR.112** (the old extension keeps its own engine during the parallel period),
  **CR.142** (the new extension as the VS Code host, in process until PQ-37 is answered); CP.1,
  CP.14, CT.8 name the new extension; **CP.45** checks the protocol against the old extension's
  views; CU.10 says per screen what the new extension does with it; CL.3, **CL.13**, **CL.15**.
- `NFR`: **N-33** rewritten (the work on the new extension changes nothing of the old one; the new
  one is installable at every step); T1 and G-1 follow PQ-37.
- `RISK`: **R-1** rewritten (two copies of one code base), new **R-31** (two engines on one
  `_ai`), **R-32** (the swap). `CON`: **X-26** (the in-place split against the copy).
- `DEL`: "The stable extension during the split" became "The new VS Code extension" (the copy
  point, the old extension left alone, both installed, the acceptance, the swap); the track table
  depends on the copy; `ww_b_workbench-2` … `7` are replanned against the copy.
- `GLO`: old extension, new extension, copy point, swap, parallel period; "the split", "v1, the
  stable extension" and "the second extension, v2" in the table of words not used.
- Open: the new extension's identity and the swap (PQ-60), the copy point and what the old
  extension gets meanwhile (PQ-61), what "every feature as before" leaves out or adds (PQ-62),
  in process or as a process (PQ-37), the format during the parallel period (PQ-40).

### What came from each inventory

| Inventory | Findings | Applied | Asked | Settled | Dropped |
| --- | --- | --- | --- | --- | --- |
| `inventory_vscode_extension.md` (`F-*`, `vx:G-*`) | 339 (200 covered already, B1; 5 retiring) | 76 + 200 B1 checked + 5 retiring (O-11) | 50 | 1 | 7 |
| `inventory_webwork.md` (`ww:R*`, `ww:N-*`, `ww:PQ-W*`) | 55 | 15 | 18 (`ww:PQ-W*` merged into PQ-37, PQ-43, PQ-57, PQ-66) | 0 | 22 |
| `inventory_ai_runtime_quest.md` (`AR-*`, `V2-*`) | 113 | 56 | 31 | 4 | 22 |
| **Total** | **507** | **147 + 205** | **99** | **5** | **51** |

The counts are those of `triage.md` § 2 (by finding prefix). Every row was checked against the
document by `p1s1r5-11` (the baseline check, in its section below); the two rows that were left,
AR-83 and V2-11, are this todo's own and are done.

### The questions

33 open questions, each after the item it asks about; none is merged away and none settled whole.
`new_questions.md` lists them with their place and the findings behind them.

- **Settled:** none whole. **PQ-39** in part: its chat half is settled by D-74 (a chat send in
  another session of a waiting run still goes out, CP.21); it asks only about the leases of an
  execution that waits for an ask.
- **Merged:** none of round 4's questions; Webwork's own questions `ww:PQ-W1` … `W6` were merged
  into PQ-37, PQ-43, PQ-57 and PQ-66.
- **Kept (6):** PQ-38 (`RT > RT-INSTALL`, the web runtime service), PQ-41 (`CLI > CLI-PACK`, the
  web runtime client SDK), PQ-42 (`CLI > CLI-PACK`, TypeScript and JavaScript), PQ-49
  (`TAC > TAC-CRYPT`, phones and tablets), PQ-51 (`TAC > TAC-PEOPLE`, a runtime that serves no
  quest; one context sentence added), PQ-52 (`TAC > TAC-CONV`, cache and outbox of messaging).
- **Rewritten (20):** PQ-34 (`RT > RT-HOLDS`, who writes `_ai` files besides the runtime), PQ-35
  (`RT > RT-HOLDS`, quest refresh, stored prompt, aspect level, night mode, `prerequisites.yaml`),
  PQ-36 (`RT > RT-HOLDS`, two engines on one quest, timed requests, queue entries), PQ-37
  (`RT > RT-INSTALL`, how every host gets and starts the runtime), PQ-39 (`RT > RT-ASKS`, leases of
  an execution waiting for an ask), PQ-40 (`RT > RT-VERSIONS`, the format during the parallel
  period and when a migration runs), PQ-43 (`CLI > CLI-UI`, the review and messaging components),
  PQ-44 (`CLI > CLI-UI`, the Flutter view packages), PQ-45 (`TAC > TAC-COORD`, how resources are
  written), PQ-46 (`TAC > TAC-COORD`, the lease rules), PQ-47 (`TAC > TAC-BACKENDS`, a team on the
  GitHub backend), PQ-48 (`TAC > TAC-BACKENDS`, coordination off and the local tac service), PQ-50
  (`TAC > TAC-PEOPLE`, remote control, the MCP server's reach, credentials), PQ-53
  (`PAR > PAR-QUESTS`, a personal place and personal notes), PQ-54 (`PAR > PAR-QUESTS`, member
  branches, internal repository, secret scan, member access), PQ-55 (`PAR > PAR-QUESTS`, quest
  operations and workspace setup), PQ-56 (`NFR`, numbers no source gives), PQ-57 (`DEL`, what
  "finished" is checked against and the new extension's acceptance), PQ-58 (`GLO`, the words for
  the new extension and words in several senses), PQ-59 (`ABOUT > ABOUT-READ`, the structure of
  the Project Idea).
- **New (7):** PQ-60 (`DEL`, the new extension beside the old one, the swap, retiring,
  ownership), PQ-61 (`DEL`, the copy point, what the old extension gets meanwhile, the scripting
  API split), PQ-62 (`SCO > SCO-OUT`, what "every feature as before" means for the new
  extension), PQ-63 (`TAC > TAC-COORD`, the extension's own collaboration plan against tac),
  PQ-64 (`RT > RT-QUEUE`, control items and wait / notify items across machines and people),
  PQ-65 (`RT > RT-ASKS`, the store of asks and answers; question blocks and prompts in them),
  PQ-66 (`TAC > TAC-REVIEW`, the review exchange over tac).

## `p1s1r5-2` — `ABOUT`, `SRC`, `VIS`, `USR`, `SCO`, `LAND`

Done 2026-11-25. Every change is a marked change in `../project_idea.ai_runtime.md`; every source
note in these sections (outside `GLO`) is rewritten into the citation shapes. Table columns of
ids ("Source" in `USR` and `SCO-IN`) are content and keep their form; ids were added there where
a row changed.

### Rows applied (finding → item)

| Finding | Item(s) changed or added |
| --- | --- |
| F-QST-12, F-QST-13 (B1) | E-5: citation `S17 user guide § 2 *Merge drivers*; S23: vscimpb142c; vscimpb152aaa, planned` |
| F-TRN-9 (B1) | O-4: citation `S23: ccparity_c_transports-4` |
| F-PRM-22, F-OTH-3, F-OTH-9, F-OTH-11, F-OTH-13 (B1) | O-1: citation `S17 package.json, quick_reference.md, marktext_integration.md` (all VS Code-only, kept by the VS Code host) |
| F-OTH-14 (B1) | E-3 and E-11: `S17` added to the citation |
| F-QUE-42, F-TIM-6, F-TRN-10 (retiring) | new **O-11** (what the old extension removes and the runtime does not carry: the Copilot panel, transport, answer wrapper and files, the VS Code LM tools and the Copilot queue items; the answer-wrapper and reminder fields of timed requests; queue reminders after a wait; shared memory), citing O-4, CR.19, CR.53, `S23: 01_aifmt-1, 00_aifmt-3`; O-4 names the Copilot removal; E-1's queue bullet says the reminders are being removed |
| ww:N-22 | E-2: `tom_todo_model` 6.0.0, citing the pubspec |
| AR-12 | S19's standing: "its § 7 stages are replaced by D-73" |
| AR-26 | new **L-13**: a gateway for outside agents that speak A2A (`S9; S30: a2a1, planned`) |
| AR-28 | L-12's reason: "possible; to be investigated for messaging and other light parts (X-3), not planned for the first version" (`S30: tac_webwork-1`) |
| AR-49 (row of p1s1r5-4, "For p1s1r5-2") | new **L-14**: the OpenAI Agents SDK as a transport (`S30: xxlater1`) |
| AR-51 | new **L-15**: tools a provider runs on its own servers (`S30: xxxai1`) |
| AR-58 | S7's standing: "predates the provider decisions in this quest's `xx*` todos (S30), which win" |
| AR-80 | S2's row and `ABOUT-READ`: FO-1 … FO-22 without FO-14, which was not assigned |
| AR-11 (row of p1s1r5-10, "For p1s1r5-2") | S18's standing: "RS-1 is replaced by D-73"; its "Holds" no longer says "the split" |
| V2-4 | `SCO-IN` row "The split" → "The new VS Code extension" (D-73; open points PQ-60, PQ-61, PQ-62); O-1: the views stay VS Code views, the new extension carries them over unchanged |
| V2-7 | E-22 rewritten (vscode_extension keeps the old extension, left as it is once the copy is taken; format 11 done there; PQ-61, PQ-60; messaging with the new extension, PQ-30); E-1 says "the old VS Code extension"; new **E-23**: no new extension exists yet |
| vx:G-17 (row of p1s1r5-3, "For p1s1r5-2") | E-1: new bullet on the preparation of format version 11 since 2026-11-25 (`00_aifmt-1` … `-4` done, `01_aifmt-1` in progress, `01_aifmt-3` … `-5`, `02_aifmt-1` planned) |

### Besides the rows

- **D-74** stated in `SCO-IN` (a paragraph before the table, citing `-> D-74` and `<- S31; S23; S25; S29; S30`); **D-73** in the `SCO-IN` row, O-1, E-22, E-23, U-8, the `VIS-SYSTEM` table (new row "New VS Code extension") and the hosts paragraph; `ABOUT` names the new extension in the product and round 5 in the status.
- **Sources** S28, S29, S30, S31 added (§ 4 of the triage); S17, S23, S25 at the state of 2026-11-25 (S17 also lists `mcp_server.md`, `telegram_integration.md`, `reading_notation_sample.md`); the path check sentence dated 2026-11-25 (every new path checked on disk).
- **`ABOUT-READ`**: the rule for source notes rewritten as the citation shapes; S29's id families (`OR-n`, `FQ-n`, `C<n>`, `Q-n`, always with the source); todo ids after S28 and S30; the highest ids: `S31`, `U-17`, `O-11`, `L-15`, `E-23` (the other areas are left to the parts that add to them and to `p1s1r5-11`).
- **`USR`**: U-2 receives review requests and returns copies through tac or the other channels (S29: FQ-9); U-15 rewritten for a review with rounds, the review set and the channels (S29: FQ-9, FQ-11; S25: 09_woneb3); new **U-17** the guest reviewer (CV.16); U-8 rewritten for D-73 and D-74.
- **`SCO-IN`**: the CV row adds the review folder with its rounds and the channels besides tac.
- **`SCO-LATER`**: L-9 says the old extension keeps its per-quest Telegram and that the new extension's is PQ-62.
- **`LAND`**: E-1 `tom_vscode_scripting_api` 7.0.0, the transports as they are (VS Code LM not carried, Copilot being removed); E-6 `tom_secrets_client` 0.2.24 and `tsm` 0.2.15 (from the pubspecs on disk); E-10 `tom_messaging_ui` not built (S29: C21, Q-8 (a)); E-20 Webwork's AI on `tom_ai_trail_ui` in wave 1b1 (S25: 06_woneb9, 13_woneb4); E-15 Webwork on hold until tom_forge's restructuring and the runtime specification (S25: 03a_woneb1), wave 1b1 / 1b2, the decided review folder and channels, `tom_messaging_ui`.
- **`VIS-PROBLEM`** "why now": "complete enough to be carried into a runtime of its own" instead of "extracted".
- Two typos fixed: "theagent_container" in `SRC` and O-8.

### Questions written

- **PQ-62** (new) — what "every feature as before" means for the new extension: the VS Code LM transport (D-7, O-4), today's per-quest Telegram (D-6, L-9, CP.18), the script server (CL.10), and team views beside the messaging views PQ-30 already gives it. Findings behind it: V2-9, V2-24, V2-27, V2-29, AR-5, AR-21, vx:G-4, F-ASK-21, F-ASK-22, F-ASK-23. Recommendation (b). Its assumption is written into O-4 (VS Code LM in the old extension only) and L-9.

### Open questions settled

- V2-26 (not a PQ): settled by D-73 as the triage rules — the new extension is in scope as the VS Code host, its views carried over (`SCO-IN` row, O-1); ownership after the swap goes to PQ-60 (p1s1r5-10).

### Rows dropped

- **AR-15** — a todo matter (cancelling `ww_a_collab-2b`); the todo model's version is applied through ww:N-22.

### Done otherwise than the triage says

- The triage's PQ-62 (b) put messaging and review "in the Flutter applications (O-3)". That contradicts the answer to PQ-30 (the VS Code extension gets messaging once the runtime is built, in views of its own; U-8, O-1). PQ-62 therefore asks only about the coordination page, the team-runtimes view and the asks of other runtimes, beside the messaging views PQ-30 decided.

### Obligations changed

- **O-1**: the extension's views stay VS Code views carried over by the new extension (was: they stay in the extension, which becomes a host).
- **O-4**: the VS Code LM transport stays in the old extension; for the new extension PQ-62 decides.
- **O-11** (new): the runtime does not carry the retiring features listed there.
- **SCO-IN**: the first version holds the feature baseline of D-74; the row "The split" is replaced by "The new VS Code extension".
- **L-12, L-13, L-14, L-15**: L-12's reason; three features deferred.
- **U-15, U-17, U-8**: who coordinates and reviews, and what the VS Code extension's stake is.

### Sources needed

- None beyond S28 … S31. D-73 and D-74 are cited before `p1s1r5-10` writes them into `DEC`.

### For other parts

- **p1s1r5-10**: R-18 names `tom_todo_model` 4.2.0 — 6.0.0 (ww:N-22); D-73 and D-74 are cited in `ABOUT`, `VIS`, `USR`, `SCO`, `LAND` and need their `DEC` rows; `SCO-IN` names PQ-60 and PQ-61 as open, so their wording should match.
- **p1s1r5-11**: the highest-ids line in `ABOUT-READ` is updated only for `S`, `U`, `O`, `L`, `E`; the other areas and the question range (`PQ-1` … `PQ-59`) need the final values. `GLO` has no entry for "old extension", "new extension", "copy point" or "swap", which `ABOUT`, `VIS`, `USR`, `SCO` and `LAND` now use (PQ-58). The rule for source notes in `ABOUT-READ` now describes the citation shapes; sections still in the old form contradict it until their parts are done.
- **p1s1r5-7**: U-15 and U-17 cite CV.16 and the review folder layout (CV.17, CV.18 to come); `SCO-IN`'s CV row names the review folder and the channels.

## `p1s1r5-3` — `RT-HOLDS` … `RT-INSTALL`

Done 2026-11-25. Every change is a marked change in `../project_idea.ai_runtime.md`, from the
`<!--[RT]-->` heading to the heading `RT-SECRETS` (167 marks: 135 substitutions, 32 additions).
Every source note of these eight sections and of the section's opening paragraph is rewritten into
the citation shapes (`(<- …)` for sources, `(-> …)` for decisions, answered questions and items);
"open (PQ-n)" and "(D-73)" where the sentence is about them stay as content. The question blocks
PQ-34 … PQ-38 stay where they are; their rewritten forms are in `new_questions.md`.

### Rows applied (finding → item)

| Finding | Item(s) changed or added |
| --- | --- |
| B1 rows of 2.1 … 2.18 (110 rows) | citations added or rewritten in CR.1 … CR.110, CS.1 … CS.6, CS.19, CS.20 from each row's source column; planned rows read "planned" with their todo (CR.4, CR.22, CR.53, CR.54, CR.63, CR.97, CR.100, CS.19, CR.33's old guidelines name) |
| F-QUE-43, F-MEM-5 (retiring) | CR.19: the old extension's queue reminders after a wait are not carried; CR.53: its memory shared across sessions is removed and not carried |
| F-QST-8, vx:G-11 | CR.55: the decisions document also carries every process move that is not a plain step |
| F-WSL-8 | CR.102 rewritten: what the runtime answers about a workspace (build running and installed, Dart binaries, repositories with kind, branch or pin, address, description, cloned, projects); "planned" kept only for the quests' repositories (`vscimpb154`) |
| F-TOD-9, F-TOD-12, F-TOD-20, F-TOD-21, F-TOD-24, F-OTH-15, vx:G-10 | new **CR.113** (archive and delete), **CR.114** (moving todos), **CR.115** (ids from a date code), **CR.116** (repairing dependencies), **CR.117** (the completing answer kept; response values read from the trail; Copilot answer files not carried) |
| F-TOD-16 | CR.50: a reminder rings once across a person's hosts and machines; planned: the next occurrence keeps due date and reminders, snooze |
| F-TOD-22 | CR.2: `workspace.todo.yaml` as a store |
| F-TOD-33 | new **CR.118** (planned: dependency closure across quests with the queued items of every runtime) |
| F-PRC-5, vx:G-11 | new **CR.123** (the marker of a process step) |
| F-PRC-13, F-PRM-3, F-PRM-6, vx:G-15 | new **CR.124** (the Proceed template); CR.2 "templates of every category (CS.3)"; CS.3's repository part lists every template category (reminder templates not carried, CR.19) |
| F-PRC-14 | CR.5: prompt assembly includes the process context, the process's values also as chat variables |
| F-PRC-19 | CR.10: planned, a review step's documents from a chat variable with several paths |
| F-QUE-4, vx:G-8 | CR.69: states "waiting for a rate limit or a quota until a time" and "retrying (n of m)"; retry now / retry all errors in CR.126 |
| F-QUE-14, F-QUE-16, vx:G-8 | new **CR.127** (moving items between runs, sessions and places; status by hand), **CR.128** (run defaults as start values, applied to waiting items, followed by an item) |
| F-QUE-15 | new **CR.126** (the commands on a run's queue) |
| F-QUE-33, vx:G-16 | new **CR.125** (a chat send stopped after the response time, 60 minutes by default) |
| F-QUE-34 (row of p1s1r5-4, settled half of PQ-39) | CR.15 and CR.67: chat sends stand outside the lanes with one busy slot per session; a chat send in another session of a waiting run goes out (-> D-74) |
| F-TIM-2, vx:G-16 | new **CR.133** (global schedule slots) |
| F-SES-6 | new **CR.130** (a session named by an item created at its first dispatch) |
| F-SES-7, vx:G-12 | new **CR.132** (a new conversation once when an agent transport lost the session's) |
| F-SES-12, F-SES-14, F-SES-18, F-SES-21, vx:G-12 | new **CR.135** (prompt as typed, as sent, system prompt), **CR.136** (prompt and answer pairs across sessions), **CR.137** (rebuild history and memory; compaction dry run), **CR.138** (planned: tool calls attributed to their execution) |
| F-SES-16 | new **CR.131** (planned in the old extension: per-host session storage, compact trail and journal; where the runtime keeps them is PQ-53) |
| F-TRN-3, F-TRN-4, F-TRN-5, F-TRN-14, vx:G-6 | CR.27 extended (deferred tools behind tool search, tools named by a prompt, server-side clearing, images and PDFs, busy-backend retry) |
| F-TRN-6 | new **CR.139** (approval modes); CR.25 points to it |
| F-TRN-18, vx:G-16 | new **CR.140** (the real cause of an agent transport's failure) |
| F-PRM-4, ww:R22 | new **CR.119** (the assists with their prompts, sent by every host into a run of its own) |
| F-PRM-11 … F-PRM-14, F-PRM-18 (row of p1s1r5-5), vx:G-3, vx:G-17 | CR.61 rewritten: aspects with several choices, texts or guideline files, the levels as built with the workspace level and "the host's choice for this runtime", replace / add / remove, conditions, renaming carries the choices; "choosing per level is planned" removed |
| F-PRM-16 | new **CR.121** (night mode) |
| F-REV-17 | new **CR.129** (an agent's changes reviewed per change in a document view) |
| F-USG-3 | new **CR.141** (planned: tool definitions per role type measured) |
| vx:G-17 | "planned" removed from CR.83 (rewritten as built, `vscimpb179`; "until it is built" removed; also on answered decisions), CR.96, CR.61, CR.70 |
| AR-14 (row of p1s1r5-8) | CR.35's last sentence names `quest-resources.<quest>.yaml` as S1 and S6 do, the Blueprint settling it |
| AR-34 | new **CR.122** (host runs in a runtime without a quest) |
| AR-40 | new **CR.111** (the provider page) |
| AR-43 (row of p1s1r5-4) | CR.105: per day, provider and model |
| AR-47 | new **CR.134** (the hold point of a soft interrupt on an agent transport) |
| AR-48 (row of p1s1r5-4) | CR.75: a transport that cannot fork offers only *continue*; CR.43: command lines and native runtimes too |
| AR-81 | new **CR.120** (one expression language, the common system taken over when it exists); CR.10: a button's move accepted at a sub-step |
| D-73 (description, V2-8, V2-16, V2-17) | new **CR.112** (the old extension keeps its own engine during the parallel period; same quest open, PQ-36; format version open, PQ-40); new **CR.142** (the new extension is the VS Code host; in its own process or as a process open, PQ-37; assumption: its own process, as G-1 and CP.14 say) |

### Questions written

- **PQ-34** (rewritten) — who writes `_ai` files besides the runtime: adds the old extension's engine during the parallel period (CR.112) and `tom_todo_model` 6.0.0 (`vscimpb180`); options and recommendation (b) kept, (b) now also names the old engine. Findings: F-TOD-1, F-TOD-35, D-73.
- **PQ-35** (rewritten) — five built features (quest refresh, stored prompt, the host's level of aspect choices, night mode, `prerequisites.yaml`): all in the first version by D-74; asked is where they act and their owner across hosts, machines and people. Recommendation (b): all the runtime's, the refresh counted by the runtime holding `default`, night mode per machine, prerequisites checked on each runtime's machine. Findings: F-QST-7, F-QUE-29, F-QUE-30, F-PRE-1, F-PRM-16, vx:G-3, vx:G-5.
- **PQ-36** (rewritten) — two engines on one quest: adds the old extension beside a runtime (V2-17), a timed request firing once, and where queue entries live (`_ai/queue/` against CR.106). Recommendation (b). Findings: AR-9, V2-17, F-QUE-31, vx:G-16.
- **PQ-37** (rewritten) — Node, the installer (`tom_tool_installer`, FQ-3), the Agent-SDK-only mode, and the new extension in process or as a process. Recommendation (b). Findings: AR-8, V2-8, V2-16, ww:PQ-W6, ww:N-23.
- **PQ-64** (new) — control, wait, notify and barrier items, and whether they reach runs of other machines and people. Recommendation (b): one `RT-QUEUE` item, the person's own machines through tac, other people only through asks and messages. Findings: vx:G-2, F-QUE-35, F-QUE-36, F-QUE-37.
- **PQ-65** (new) — the store of asks and answers (per host `01_aifmt-4` against one file per entry `vscimpb183`) and question blocks and prompts in asks and answers (`vscimpb184`, `vscimpb185`). Recommendation (b). Findings: vx:G-7, F-ASK-11, F-ASK-12, F-ASK-13.

### Open questions settled

- **PQ-39, its chat half** (by D-74, as the triage rules): written into CR.15 and CR.67. The rewrite of PQ-39 itself (leases only) is `p1s1r5-4`'s.

### Rows dropped

- **F-PRM-15, F-PRM-17** — the content of the workspace's aspects, not a capability; CR.61's choices being texts or files covers them.
- **F-PRM-20** — deferred in the extension's quest (`later2`), not planned for the baseline.
- **ww:N-2** — covered by CR.122 (AR-34); the area names are Webwork's.
- **ww:N-4** (CR.15, CR.16, CR.18), **ww:N-6** (CU.8; Undo is the host's), **ww:N-9** (CR.24, N-23), **ww:N-19** (CR.108, L-8, T8; PQ-38, PQ-41, PQ-49 stand) — covered.
- **ww:N-10** — the same need as ww:R22 (CR.119).
- **AR-2, AR-4** — they confirm N-24, N-32 and CR.1.

### Done otherwise than the triage says

- To keep each item one obligation, several rows that the triage put into an existing item are new items instead: F-TRN-6 (CR.139, not CR.25), F-REV-17 (CR.129, not CR.17), F-SES-6 (CR.130, not CR.75), F-SES-16 (CR.131, not CR.47 / CR.79), F-USG-3 (CR.141, not CR.105), AR-47 (CR.134, not CR.89), F-TOD-9 / -12 / -20 / -21 / -24 (CR.113 … CR.117, not CR.48), F-QUE-14 and F-QUE-16 split into CR.127 and CR.128. F-TOD-12 and F-OTH-15 share CR.117 (both are the answer that reports a todo).
- **The stored tool results** (F-SES-13), which this todo's description lists among CR.27's lacks, are left to `p1s1r5-4` as the triage rules (vx:G-6 "For p1s1r5-4"), together with the core tool set (F-TOL-2).
- **The watchdog** (F-QUE-32) is not written here: the triage puts it into `NFR` (`p1s1r5-9`).
- **F-PRC-20** (Grill me and Explain at a decision) is written into CR.119 with the other assists.

### Obligations changed

CR.2 (more stores: every template category, `workspace.todo.yaml`), CR.5 (process context in prompt assembly), CR.10 (a button's move accepted at a sub-step; planned documents from a variable), CR.15 and CR.67 (chat sends outside the lanes; a chat send of a waiting run goes out), CR.19 and CR.53 (retiring features not carried), CR.27 (deferred tools, clearing of tool results, images and PDFs, busy retry), CR.33 (the old guidelines name read until removed), CR.35 (the quest's resource file named), CR.43 (command lines and native runtimes), CR.50 (once per person; planned next occurrence and snooze), CR.55 (process moves in the decisions document), CR.61 (the aspect model as built), CR.69 (two more states), CR.70 and CR.96 (role and guideline defaults built), CR.75 (no fork, only continue), CR.83 (built; also on answered decisions), CR.102 (what is answered about a workspace), CR.105 (per provider), CS.3 (every template category in the repository's part); new CR.111 … CR.142.

### Sources needed

- **S23's range.** S23 names the archived todos "completed 2026-11-10 … 2026-11-25", but the B1 rows cite completed todos of the extension older than that (`tra1`, `qri1`, `vas1` … `vas3`, `chat2`, `trb4`, `vbs4`, `vscimpa11`, `sdkerr`, `ccparity_*`, `cc_parity_*`, `dapieff*`). For `p1s1r5-2` / `p1s1r5-11`: S23 should cover the whole archive (from 2026-06-17), or these be cited by S17's documents.
- Otherwise none beyond S28 … S31.

### For other parts

- **p1s1r5-4:** CP.3 names the queue commands of CR.126; CP.8 refers to the approval modes of CR.139, and its envelope follows PQ-65; CP.21 says a chat send in another session of a waiting run goes out (CR.67); G-1 / CP.14 / CT.8 carry PQ-37's assumption (CR.142); the stored tool results (F-SES-13) and the core tool set (F-TOL-2) are yours; CR.111 is taken (the provider page), so your new CR items start at CR.143.
- **p1s1r5-5:** the views DEPENDENCIES and WORK ORDER (F-TOD-33, CR.118) as screen rows; the aspect editor and guideline picker as host components (SC-23); the review of an agent's changes per change (CR.129) as a host view.
- **p1s1r5-8:** CR.35 cites CW.8 and names `quest-resources.<quest>.yaml`; the draft pull request on request (AR-81, CW.15).
- **p1s1r5-9:** the watchdog (F-QUE-32) as an `NFR` item; PQ-56 drops the chat-send time-out (now CR.125, 60 minutes by default); G-1 and T1 follow PQ-37 (CR.142 carries the assumption).
- **p1s1r5-10:** CR.112 and CR.142 cite D-73, which needs its `DEC` row; CR.112 matches R-31 (two engines on one `_ai`); `DEL`'s "that the queue does this without a person is asked of the extension" is answered by CR.83 (built, `vscimpb179`).
- **p1s1r5-11:** `GLO` uses "section" and "option" for the aspect guidelines; CR.61 now says "aspect" and "choice" (the extension's terms); new terms "marker of a process step" (CR.123) and "night mode" (CR.121) have no entry; the highest CR item is CR.142.

## `p1s1r5-4` — `RT-SECRETS` … `RT-PROVIDERS`

Done 2026-11-25. Every change is a marked change in `../project_idea.ai_runtime.md`, from the
heading `RT-SECRETS` to the heading `CLI` (107 marks: 88 substitutions, 19 additions; the new
table row of CT.1 is marked cell by cell). Every source note of these eight sections and their
opening paragraphs is rewritten into the citation shapes (`(<- …)` for sources, `(-> …)` for
decisions, answered questions and items, `(<~ …)` once for an extrapolation); "open (PQ-n)" where
the sentence is about the question stays as content. The question blocks PQ-39 and PQ-40 stay
where they are; their rewritten forms are in `new_questions.md`.

### Rows applied (finding → item)

| Finding | Item(s) changed or added |
| --- | --- |
| B1 rows (48: F-WSL-6, -7; F-QUE-44; F-TIM-4; F-TRN-11, -12, -17; F-PRM-8, -10; F-TOL-1, -4, -5, -7, -8; F-ASK-1 … -8, -10, -15, -17; F-REV-12, -16; F-SPC-1 … -5, -7 … -9, -11 … -13; F-USG-2; F-PRE-3, -5; F-OTH-2) | citations added or rewritten from each row's source column: CP.3 (`llm_tools` § 4.20, § 10), CP.8 (the ask kinds as built, `llm_tools` § 4.18, § 10, *The user-input panel*, `ccparity_i_assist-1`), CP.9, CP.39, CP.40, CP.41, CP.42, CP.12 (`agent_sdk_scripting_mirror.md`, `llm_tools` § 9, user guide § 6, `00_aifmt-5`, `-6`), CP.13 (`ccparity_f_teamreview-1`), CP.27 (*Which build a window runs*), CP.38 (`ccparity_i_assist-6`), CT.1, CT.9, CT.10, CT.16 (`ccparity_d_claudecode-7`), CT.17, CS.13 (`later1`, planned), CS.14 (`dapieff16`, progress 2026-11-24), CS.18; planned rows read "planned" (CT.9: `tooloptimize10` … `15`; CT.10: `vscimpb169`, `vscimpb189`, `vscimpb178`, `specfrem1`) |
| F-TOD-26 | CP.4: per todo whether and where it is queued, so a host marks it live (`<~ S17 user guide *Quest TODO Panel*`) |
| F-PRC-20 | CP.38: the assists at a process decision, in a temporary session, with the decision's choices as buttons (the assist prompts themselves are CR.119, by p1s1r5-3) |
| F-QUE-34 (settle) | CP.21: a chat send in another session of the waiting run goes out (CR.15, CR.67; -> D-74); PQ-39 keeps only the leases |
| F-SES-13, vx:G-6 | new **CT.19** (stored tool results with replay keys, retention, the past-tool tools) |
| F-SES-21 | CT.7: each tool call names the execution that made it, pointing to CR.138 (written by p1s1r5-3) |
| F-PRM-23, vx:G-18 | CP.38: completion data include the quest's files after `@`; the queued todos with their items; the models a profile can use |
| F-PRM-24, F-PRM-25, F-TOL-12, vx:G-14 | CT.1: new row **Runtime tools on the workspace** (guidelines and pattern prompts, project and repository lists, issue and test trackers over a provider; through the MCP server only those that read); "three sets" → "four sets" |
| F-TOL-2 | new **CT.21** (the core tool set, long descriptions behind a tool, a length test) |
| F-TOL-3 | CT.9: tools enabled per profile as well; the MCP server's own selection |
| F-TOL-9 | CT.10: planned specialised tools (`tooloptimize2` … `9`, `16`) |
| F-REV-11 | new **CT.20** (a writing tool refuses on a changed file or one open with unsaved changes) |
| F-REV-24 | CT.1, row on `_ai`: the question tools on plain Markdown |
| F-SPC-10 | CT.1, row on `_ai`: the specification tools include those of code generation and their guides |
| ww:R10, ww:R11 | CP.36: the review requests addressed to the user, open or returned, across conversations; per member whether tac accepted a request for delivery ("opened" not added) |
| AR-3 | CP.13: new bullet, the places of what the host carries for the runtime; "The host supplies no transport through it (-> D-7)" |
| AR-39 | new **CS.21** (adapters per provider) |
| AR-42 | new **CS.22** (base address, key reference and model-slot mapping per configuration); CS.12: Claude on Bedrock / Vertex as an Anthropic configuration with cloud credentials |
| AR-43 | CS.14: prices from the provider or a published list, never by hand; premium requests and quota where reported |
| AR-45 | CS.15 rewritten as proposed (recorded or simulated server, the six checks, an opt-in live check) |
| AR-48 | new **CS.23** (sign-in per configuration, the provider page shows its state, CR.111), **CS.24** (an agent program's own tools and instruction files off by default) |
| AR-49 | CS.12 row 3: OpenAI (the Responses API) |
| AR-50 | CS.12 row 3: Google (the Gemini API); row 1: the Gemini command line run without a window |
| AR-52 | CS.12 row 3: Llama through routers, providers and local models; the sentence after the table: Meta's own Llama API is not used |
| AR-54 | new **CS.25** (a provider API that keeps the conversation); CS.12 row 1: Mistral's coding agent named Vibe |
| AR-55 | CS.14: a router's routing preferences |
| AR-56 | CS.12: the presets of `xxotherproviders1` (Kimi, GLM, Qwen, Groq, Azure OpenAI, LiteLLM in; MiniMax, Together, Fireworks, Cerebras out) and a sentence that any compatible endpoint can be configured without a preset |
| AR-57 | CS.16 rewritten with `pi-ai`, `pi-coding-agent`, `pi-agent-core` not used |
| AR-63 | new **CS.26** (secret references named by a command a tool runs, resolved into that command only, masked in results) |
| AR-82 | new **CT.18** (a remote tool keeps its name; the target quest is an argument) |
| V2-18 | PQ-40 (rewritten); CP.29 names the format during the parallel period as open (D-73, CR.112) |

### Besides the rows

- **RT-PROTO, RT-HOST (the second extension):** CP.1 and CP.14 say "the new extension (D-73)" and carry PQ-37's assumption (the runtime in the new extension's own process, CR.142); new **CP.45** lists what the protocol carries beyond CP.3 … CP.12 and CP.35 … CP.39 so that the new extension feeds every view of the old one from its runtime (the further queue-editor commands, the restored and stand-in asks with every ask kind's buttons, the migration flow, the host's settings layer), checked against the screen inventory CU.10 (`-> D-73, D-74`; inventory § 5). CP.3 adds the run commands (CR.126 … CR.128) and the configuration layers; CP.4 the runtimes of the machine and a dismissed user notification; CP.38 finishing a review round, the gate decision, and the state of the provider SDKs and binaries.
- **Team review for Webwork:** CP.36 adds the round's state read from the review folder (`TAC > TAC-REVIEW`, CV.18) and names PQ-66 for how a round's set travels; sending and receiving the bundles are the blob and review-request commands already listed.
- **RT-TOOLS, RT-MCP:** CT.1's host-tool cell lists the VS Code host tools as built; CT.8 says "the new extension"; CT.12 gets the read-only floor ("Without a valid token it serves only the tools that read, and only to the local machine and the VPN", vx:G-13) and names, as part of PQ-50, whether a local-only second endpoint keeps the file and host tools the old extension's MCP server serves today.
- **RT-ASKS:** CP.8 names the ask kinds as built and the approval modes (CR.139) and points to PQ-65 for question blocks and prompt buttons; CT.17 and CP.23 point to PQ-65 for the store (one file per host or per ask and answer); a new paragraph states Telegram's standing: not a channel of the runtime (L-9, D-6), the old extension keeps its bot per quest, the new extension's is PQ-62.
- **RT-VERSIONS:** CP.29 names the format both engines use during the parallel period beside the time of a migration (PQ-40).
- **RT-PROVIDERS:** CS.18 no longer says the transports "have moved into" the runtime: "once it carries today's transports; none is built in the old extension first".

### Questions written

- **PQ-39** (rewritten) — the leases of an execution waiting for an ask only; the chat half is stated as settled in the context; the extension's planned *Proceed anyway* (`caf_04b`) and PQ-63 in the context; options (a) kept as is, **(b)** kept with the ask's age shown, (c) released after a time, (d) downgraded. Findings: F-QUE-34 (settled half).
- **PQ-40** (rewritten) — the format version while the old extension and the runtime both work on one `_ai` (D-73), together with when a migration runs; options (a) old extension reaches 11 first, plan's rule for 11, **(b)** as (a) for the parallel period and the confirmation rule from now on with per-machine steps by themselves, (c) two formats in the runtime, (d) a separate `_ai`. Findings: V2-18, F-QST-11.

### Open questions settled

- **PQ-39, its chat half** (by D-74, as the triage rules): CP.21 (CR.15 and CR.67 by p1s1r5-3).

### Rows dropped

- **ww:N-7** (covered by CT.1, CT.4, N-18), **AR-6** (follows CT.1, CT.8, CT.11; the todo is replanned), **AR-36** (confirms CT.4 … CT.6), **AR-38** (confirms CS.18), **AR-41** (CS.7 covers it; decided, CQ-16), **AR-44** (confirms CS.14), **AR-53** (confirms).

### Done otherwise than the triage says

- **New items instead of growing one**, to keep each item one obligation (as p1s1r5-3 did): F-TOL-2 is **CT.21**, not a sentence of CT.10; F-REV-11 **CT.20**; F-SES-13 **CT.19**.
- **F-SES-21** is not written as a second planned item: CR.138 (p1s1r5-3) states it; CT.7 points to it.
- **AR-63's item is CS.26**, not the next free number at the time of the triage, because CS.21 … CS.25 are taken by the provider rows of the same table.
- **F-REV-24** goes into CT.1's row on `_ai` only; CP.38 does not list single tools.
- **The questions inside AR-39** (all three adapter layers in the first version; where a local-model configuration lives), **AR-43** (recurring provider checks), **AR-48** (CS.13 "direct calls" or "only its SDK") are not asked: the triage rules these rows *apply* and asks nothing; CS.13 keeps "through direct calls and its SDK", which AR-48 calls vague (no todo plans direct calls).

### Obligations changed

CP.1 and CP.14 (the new extension; the runtime in its process as long as PQ-37 is open), CP.3 (run commands, configuration layers), CP.4 (queued marker per todo, runtimes of the machine, dismissed notifications), CP.8 (the ask kinds as built), CP.13 (the places of what a host carries; no transport), CP.21 (a chat send of a waiting run goes out), CP.36 (the review requests of a user, delivery per member, the round's state), CP.38 (completion files, queued todos, models, assists at decisions, finishing a review round, the gate decision, provider SDKs and binaries), CT.1 (four sets; the workspace row; Phase 4 and Markdown question tools; the host tools as built), CT.7 (each tool call names its execution), CT.9 (per profile; the MCP server's selection; planned role types), CT.10 (planned specialised and TomSpecs tools, the wider project listing), CT.12 (the read-only floor without a token), CT.16 (MCP servers on every transport, approval of a project's servers), CS.12 (the presets), CS.14 (prices never by hand, quota, routing preferences), CS.15 (the conformance table), CS.16 (the two libraries named, `pi-agent-core` out), CS.18 (wording); new CP.45, CT.18 … CT.21, CS.21 … CS.26.

### Sources needed

- None beyond S28 … S31. S17's `mcp_server.md` and `telegram_integration.md` are cited (p1s1r5-2 added them to S17's list); S20 is cited for CT.18 as the triage gives it.

### For other parts

- **p1s1r5-7:** CP.36 cites CV.18 (the round's state read from the review folder) and PQ-66; CT.12 now names the local-only second endpoint as part of PQ-50 — the rewritten PQ-50 should carry the same point (vx:G-13, F-TOL-6).
- **p1s1r5-10:** R-30 (an agent transport that needs another language runtime on every host: Mistral Vibe with Python and uv; AR-54) is yours; PQ-40's options touch R-13 and R-31 (two engines on one `_ai`), and option (b) changes the plan for format version 11 (`01_aifmt-5`) to ask.
- **p1s1r5-9:** F12 keeps its text under PQ-40's assumption.
- **p1s1r5-5:** CP.45 names the screen inventory (CU.10) as the list the protocol is checked against.
- **p1s1r5-11:** the highest ids of these sections are **CP.45**, **CT.21**, **CS.26**; terms without a `GLO` entry: "parallel period" (PQ-40, D-73), "replay key" (CT.19), "adapter" of a provider (CS.21), "preset" (CS.12).

## `p1s1r5-5` — `CLI`

Done 2026-11-25. Every change is a marked change in `../project_idea.ai_runtime.md`, from the
heading `CLI` to the heading `TAC` (67 substitutions, 36 additions). Every source note in
`CLI-PACK`, `CLI-UI`, `CLI-SCREENS` and `CLI-TRC` is rewritten into the citation shapes; ids an
item is about, section references and table columns of ids are left as content. The question
blocks PQ-41 … PQ-44 stay where they are.

### Rows applied (finding → item)

| Finding | Item(s) changed or added |
| --- | --- |
| B1: F-QUE-39, F-QUE-40 | SC-4: content and citation `S17 user guide § 4 *Queue Editor*, package.json` |
| B1: F-TIM-5 | SC-5: `S17 package.json` |
| B1: F-PRC-4 | SC-6: content and `S17 user guide *Processes*` |
| B1: F-PRC-2 | SC-7: `S17 user guide *Processes*` |
| B1: F-TOD-25, F-TOD-32 | SC-9: the panel's scopes, filters, sort, group headers; planned *Do next* and sorting groups by stem; `S17 user guide *Quest TODO Panel*; S23: vscimpb137, vscimpb138; vscimpb159, vscimpb175, vscimpb177, planned` |
| B1: F-TOD-31 | SC-11: `S17 package.json` |
| B1: F-SES-17 | SC-12: `S17 user guide *Logs Panel*`; SC-24 (logs) |
| B1: F-OTH-8 | SC-13: `S17 user guide § 8` |
| B1: F-SES-20 | SC-14: `S23: vas5` |
| B1: F-MEM-4 | SC-15: `S17 package.json` |
| B1: F-REV-1, F-REV-3, F-REV-5, F-REV-6, F-REV-15, F-REV-18, F-REV-19, F-REV-20 | SC-18: citation of the page's built and planned features; CU.9: the page protocol version 1 as built, the navigation (reveal, reading position, changes) and the published bundle with a host conformance suite as planned (`S23: 01b_woneb1, 01b_woneb2; 04c_woneb3, 04c_woneb2, 04c_woneb1, planned`) |
| B1: F-PRE-6, F-OTH-10 | SC-21: the tools overlay added; `S17 user guide § 3, § 7`; SC-22: `S17 user guide § 3` |
| B1: F-QST-16, F-OTH-5 | SC-24: the quest documents shown read-only; `S17 user guide § 2 *Documentation Panel*, *Logs Panel*` |
| B1: F-PRE-2, F-OTH-6, F-OTH-7 | SC-25: planned editor of `prerequisites.yaml`; `S17 user guide *@TOM VSC*, *Issues Panel*; S23: vscimpb152b, vscimpb152c, planned` |
| B1: F-ASK-14 | CU.6 *Asks*: the journal shown in one editor of questions and answers (`S23: vscimpb186, planned`); SC-31 rewritten accordingly |
| B1: F-COL-7 | SC-28: the extension's planned view of resource leases with a clean-up (`S28: caf_04d, planned`) — as a screen of the extension only; no `caf_*` feature is written as a runtime item (triage § 1.4) |
| F-QST-6 | new **SC-32** (host's own; needs only opening a document, CP.10) |
| F-TOD-27 | new **SC-33** (reused, todos) |
| F-TOD-30 | new **SC-34** (reused, todos) |
| F-QUE-11 | new **SC-35** (reused, queue): every host that queues a group needs the confirmation, so not host's own |
| F-QUE-41 | new **SC-36** (host's own, planned) |
| F-PRM-18 | SC-23: the guideline picker and the aspect guidelines editor (`S17 user guide; S23: gsel5, gsel5b, gsel7, gsel7b`); the engine half is p1s1r5-3's CR.61 |
| F-ASK-9 | CU.6 *Asks*: planned inline answers from the notifications list of any host (`S23: vscimpb182, planned`) |
| F-TOD-33 (row of p1s1r5-3, "For p1s1r5-5") | CU.6 *Todos*: planned dependency closure and order of work (CR.118); new **SC-37** (starting point, todos) |
| CR.129 (p1s1r5-3, "For other parts") | new **SC-38** (host's own) |
| AR-18 | new **CU.18** (the coordination page, as proposed; `S6 part-coordination-page-and-tools; S30: ww_f_collab-3, planned` `-> CA.13, CA.19, CW.16`); CU.6 *Supervision* and SC-28 refer to it |
| AR-70 | new **CL.13** (`tom_vscode_scripting_api` 7.0.0 keeps the VS Code namespace, depends on and re-exports the Dart runtime client SDK; `S30: ww_e_runtimeapi-1, planned`); the place stays D-1 (CL.3) |
| AR-71, AR-73 | CL.10: the exchangeable transport (a window's script server, a runtime) and the same answers through either (`S30: ww_e_runtimeapi-2, ww_e_runtimeapi-4, planned`) |
| AR-72 | CL.9: "nor on the VS Code scripting API" (`S30: ww_e_runtimeapi-3, planned`) |
| AR-74 | new **CL.14** (the users of today's Dart script client move to the Dart runtime client SDK, each released by its own quest; `S30: ww_e_runtimeapi-5, planned`) |
| V2-10 | CU.10: per screen, whether the new extension keeps it over the runtime, changes it or drops it; not listed means kept; the inventory is the list CP.45 checks the protocol against (`-> D-73, CP.45`) |

### Besides the rows

- **`CLI-PACK`, the second extension's client SDK:** new **CL.15** — the new extension is a TypeScript host; as a process host it uses the TypeScript runtime client SDK, in process it calls the runtime directly (CR.142); which is PQ-37, one package for TypeScript and JavaScript is PQ-42 (`-> D-73, CR.142`).
- **`CLI-PACK`, the place:** CL.3 adds that the runtime is in `tom_ai/ai_build/tom_ai_runtime`, repository `tom_ai_build`, and the new extension in the same repository (`-> D-1, D-73`). The superseded answer of `ww_e_runtimeapi-1` is not written here (current state only); S30's standing already says it, and the `CON` entry is p1s1r5-10's.
- **`CLI-UI`:** CU.16 names Webwork's planned module `tom_messaging_ui` in `tom_modules` and that the place is PQ-43 (`S29: C21, Q-8`). Webwork's areas Review (with Send back) and Team Review (sending, tracking, consolidation) are Webwork's own (triage § 1.2 point 6): no item; they are named in PQ-43's context.
- **`CLI-SCREENS`:** a missing space fixed ("as it stands. The outcomes"). The inventory gets no column for the new extension: CU.10 says a screen not listed as changed or dropped is kept, and what is dropped is PQ-62's.
- **`CLI-TRC`:** CK.1 adds the notifications of every team runtime (as the extension shows those of one machine) and the team's reviews with each round's state per member (CV.18), from which a returned copy or the consolidation is opened (`<~ S8; S29: FQ-8` — extrapolated). `rca1` against a second specification of trc: as the triage rules (AR-78 dropped), a todo matter for `DEL`.

### Questions written

- **PQ-43** (rewritten) — which UI components this product builds for review and messaging; merges ww:PQ-W3, ww:R20, ww:R21, ww:N-14 and the page features F-REV-2, F-REV-4, F-REV-8, F-REV-9, F-REV-22, F-REV-23 (as what a component replacing the page must carry); Webwork's two areas in its context. Recommendation (b).
- **PQ-44** (rewritten) — the Flutter view packages beside the new components; adds Webwork's C22 against `13_woneb2` and that Webwork keeps `tom_ai_trail_ui` until wave 1b2 (ww:N-11). Recommendation (b).
- PQ-41 and PQ-42 stand as written (triage: keep).

### Open questions settled

- None.

### Rows dropped

- F-TOL-13 (VS Code-only output channel; CT.7 attributes tool calls), F-ASK-20 (VS Code-only), F-PRE-4 (the old extension's packaging, O-1), F-OTH-1 (VS Code-only, O-1), ww:N-8 (covered by CU.7), AR-32, AR-35, AR-75, AR-76 (confirm), AR-78 (trc specified in `CLI-TRC`; `rca1` for `DEL`) — as the triage rules.

### Done otherwise than the triage says

- F-QUE-11: the triage names the confirmation "a host dialog" without an outcome; SC-35 lists it as `reused`, since every host that queues a group needs it.
- AR-74's open point (whether `tom_core_agentic` may depend on the client SDK, which depends on `tom_tac_client`) is not asked: it is a dependency choice for the Solution Blueprint and Tom Core's quest.

### Obligations changed

CL.9 (no dependency on the VS Code scripting API), CL.10 (an exchangeable transport, the same answers through a script server and a runtime), new CL.13, CL.14, CL.15, new CU.18 (the coordination page's views and confirmed, announced actions), CU.6 *Asks* and *Todos* (planned additions), CU.10 (the inventory states the new extension's fate per screen and is the protocol's checklist), CK.1 (notifications of every team runtime; the team's reviews with their state).

### Sources needed

- None beyond S28 … S31.

### For other parts

- **p1s1r5-7:** CK.1 cites CV.18 (the round's state read from the review folder), which you add.
- **p1s1r5-10:** `rca1` (a second specification of trc, with a Telegram premise against D-6) belongs in `DEL`'s list of replaced todos (AR-78); the `CON` entry on `ww_e_runtimeapi-1`'s superseded place (AR-70) stays yours; R-19 follows PQ-43's assumption.
- **p1s1r5-9:** G-6 (`tom_ai_runtime_ui`) follows PQ-43's assumption unchanged.
- **p1s1r5-11:** the highest ids of `CLI` are **CL.15**, **CU.18**, **CK.12**, **SC-38**; "coordination page" has no `GLO` entry.

## `p1s1r5-6` — `TAC-JOBS`, `TAC-COORD`, `TAC-BACKENDS`

Done 2026-11-25. Every change is a marked change in `../project_idea.ai_runtime.md`, from the
`<!--[TAC]-->` heading to the heading `TAC-PEOPLE` (44 marks: 41 substitutions, 3 additions).
Every source note of the three sections is rewritten into the citation shapes (`(<- …)` for
sources, `(-> …)` for decisions, answered questions and items); "open (PQ-n)" where the sentence is
about the question stays as content. The question blocks PQ-45 … PQ-48 stay where they are; their
rewritten forms and the new PQ-63 are in `new_questions.md`.

### Rows applied (finding → item)

| Finding | Item(s) changed or added |
| --- | --- |
| AR-13 | CA.26: the workspace's configuration for coordination is the versioned file `agent.workspace.yaml` at the workspace root with a JSON schema (backend, team, the repositories coordinated and those brought up to date, CW.16), read by every kind of runtime `(<- S6: part-client-and-backends, BP-21, BP-22; S30: ww_c_collab-3, planned)`; PQ-48's context gets `ensureLocalService()` |
| AR-16 | CA.18: a notification goes to all quests of the team or to named quests; a command names its target quests, never all, and may prefer a machine; a notification is not delivered back to its sender, a command is `(<- S5 § 3.9, § 11 items 6 and 16; S6: part-messages; S30: ww_f_collab-1, planned)`. CA.20: the notifications "a repository could not be brought up to date (CW.16)" and "the team's configuration or a backend's limits need attention" |
| AR-19 | new **CA.45** (the GitHub backend keeps within the repository server's limits; history shortened by a maintenance step the user starts) `(<- S5 § 6.3, § 10; S30: ww_f_collab-4, planned)`; PQ-47's context gets S5's presence and time (committer dates, 60 minutes, renewal at least hourly) |
| AR-23 | CA.27: quotas count at least the resources leased and the calls per hour; the tac server listens on the VPN only unless its administrator opens it; what it serves from the internet is strict (CI.10) `(<- S6: IDEA-16, BP-5; S30: ww_g_collab-2, planned)` |
| AR-24 | CA.33: while a migration runs, one runtime holds every repository of the team exclusively and the others wait `(<- S6: BP-9; S30: ww_g_collab-3, planned)` |
| F-TOD-34 | CA.10: one added sentence — the extension plans a notation of its own (`<type>://<server>[:<port>]/<path>`, types `git`, `git-release`, `named`); which the runtime takes is open (PQ-45, PQ-63) `(<- S28: part-leases; S23: caf_01a, planned)`; asked in PQ-45 and PQ-63 |
| F-COL-4 | CA.11: one added sentence — the extension plans leases of its own (a table per repository in its remote, stale after 30 minutes); open (PQ-63) `(<- S28: part-leases; S23: caf_04a, planned)`; asked in PQ-46 and PQ-63 |
| F-PRC-22, F-QUE-38, F-PRM-19, F-COL-1 … F-COL-3, F-COL-5, F-COL-6, F-COL-8 … F-COL-16, vx:G-1, AR-27 | asked in **PQ-63**; no item written (the triage's assumption: no `caf_*` feature as a runtime item until answered) |
| — (all sections) | citations rewritten in CA.1 … CA.35 (including CA.26's two paragraphs under the table and CA.28's fleet paragraph); CA.29's typo "deregistering,acknowledging" corrected |

### Besides the rows

- **The extension's collaboration plan** (`caf_*`, S28): one question, PQ-63, with the triage's
  three options (carry over as it is; take the run and feature concepts and keep tac for leases,
  branches and integration — recommended; none in the first version). Pointers in CA.10 and
  CA.11. The notation is PQ-45, the lease store PQ-46 and PQ-47.
- **This quest's coordination todos:**
  - GitHub rate-limit guard (`ww_f_collab-4`): new CA.45.
  - Orphan worktrees (`ww_g_collab-1`): CW.29 is `p1s1r5-8`'s (triage AR-22); the `Tac-Fence`
    trailer is in PQ-46's option (b).
  - `agent.workspace.yaml` (`ww_c_collab-3`): CA.26.
  - `quest-resources.<quest>.yaml` (`ww_c_collab-4`): CR.35 names it as S1 and S6 do (written by
    `p1s1r5-3`); CW.8 is `p1s1r5-8`'s. Nothing in my part claims from it, so nothing added here.
  - A2A (`a2a1`): its standing is L-13 in `SCO > SCO-LATER` (written by `p1s1r5-2`): between the
    product's runtimes TAC's commands and messages do this; A2A is a gateway for outside agents,
    later. CA.7 ("Runtimes find each other through tac and nowhere else") agrees; nothing added.
  - Further coordination todos: `ww_f_collab-1` (CA.18, CA.20), `ww_g_collab-2` (CA.27),
    `ww_g_collab-3` (CA.33) are cited as planned; `ww_f_collab-2` (endpoints) and `ww_f_collab-3`
    (the Coordination page) are confirmed by CA.23, CA.24 and by `CLI`'s / `PAR`'s items (AR-17,
    AR-18 are not my rows).

### Questions written

- **PQ-63** (new) — the extension's collaboration plan against tac, D-24 and D-68: which of leases
  in the repository's remote, the `<type>://` notation, feature branches and the merge tool, agent
  groups, features and feature runs, standard runs `planning` / `quest-keeper`, review todos, the
  issue flow and their views the runtime takes. Recommendation (b). Findings: AR-27, vx:G-1,
  F-TOD-34, F-PRC-22, F-QUE-38, F-PRM-19, F-COL-1 … F-COL-6, F-COL-8 … F-COL-16.
- **PQ-45** (rewritten) — adds the extension's notation `<type>://<server>[:<port>]/<path>[@<branch>][#<path>]`
  as option (c); option (b) keeps D-68's prefix form and maps the extension's `git-release` and
  `named` onto further schemes. Recommendation (b). Finding: F-TOD-34.
- **PQ-46** (rewritten) — adds the extension's lease table as option (d) and the `Tac-Fence`
  trailer to option (b). Recommendation (b). Findings: F-COL-4, AR-22.
- **PQ-47** (rewritten) — adds S5's presence and time on GitHub (committer dates, 60 minutes) into
  option (b) and the context, CA.45's budget guard, and the extension's per-repository lease
  tables as option (d). Recommendation (b). Finding: AR-19.
- **PQ-48** (rewritten) — adds D-13 to the context, `ensureLocalService()` as the start mechanism
  that exists, and `agent.workspace.yaml` as the place of the setting. Recommendation (b).
  Finding: AR-13.

### Open questions settled

None.

### Rows dropped

- **ww:N-21** — covered by CA.26 … CA.28.
- **ww:N-24** — nothing new for this product: Webwork's messaging needs no leases (S3).
- **AR-29** — superseded by AR-23; its answers match CA.27, CA.28.

### Done otherwise than the triage says

- **AR-16:** besides items 6 of S5 § 11, item 16 (a notification is not delivered back to its
  sender; a command is) is written into CA.18 as well, since the triage cites it and it is part of
  the protocol as specified.
- **F-TOD-34, F-COL-4:** besides the questions, one sentence each in CA.10 and CA.11 says that the
  extension plans a notation and leases of its own and that this is open, so that a reader of the
  item does not miss the baseline conflict. No `caf_*` feature is written as a runtime item.

### Obligations changed

CA.18 (commands never to all quests; a preferred machine; notifications not delivered back to the
sender), CA.20 (two more notifications), CA.26 (the configuration is `agent.workspace.yaml` with a
JSON schema, read by every kind of runtime), CA.27 (the quota kinds; the tac server listens on the
VPN only by default; strict from the internet), CA.33 (exclusive access to every repository of the
team while a migration runs), new CA.45 (the GitHub backend's budget guard and history
shortening).

### Sources needed

None beyond S28 … S31 (added by `p1s1r5-2`).

### For other parts

- **p1s1r5-8:** CW.2 … CW.6 and CW.15 meet the extension's branch, merge and review plan: their
  open sentences may name PQ-63 beside PQ-46; CW.8's quest list is what the extension's
  `quest-keeper` would hold as `defaultResources` (PQ-63).
- **p1s1r5-9:** T1 and the topology table follow PQ-48 (the local tac service always running in
  option (b)).
- **p1s1r5-10:** `CON` gets **X-22** (the extension's collaboration plan, S28, against tac's
  leases, notation and D-24), as the triage rules; D-24 and D-68 stay unchanged until PQ-63 and
  PQ-45 are answered.
- **p1s1r5-11:** `GLO` has no entries yet for "integration lease" (PQ-46 (b)) or "standard run"
  (PQ-63 (b)); add them only if the answers take those options. The highest CA item is CA.45.

## `p1s1r5-7` — `TAC-PEOPLE` … `TAC-WEBWORK`

Written by `p1s1r5-7` on 2026-11-25. Sections: `TAC-PEOPLE` (with `TAC-GROUPS`), `TAC-KINDS`,
`TAC-CONV`, `TAC-DOCS`, `TAC-REVIEW`, `TAC-CRYPT`, `TAC-SPEC`, `TAC-WEBWORK`. Every source note
in these sections that was not yet in the citation shapes is rewritten as a marked change (57
notes; ids that back a statement after `->`, sources after `<-`; the ids of a section chain
kept, the chain dropped from the note; "done" dropped from S23 notes, as the shapes write a
completed todo without it). References to an open question ("is open (PQ-51)") and section
chains inside sentences are content and stay. The question blocks stay where they are.

### Rows applied (finding → item)

| Finding | Item | What |
| --- | --- | --- |
| F-REV-7, F-REV-10, F-REV-13 (B1) | CV.16 | citation rewritten: `(<- S23: ccparity_f_teamreview-1 … ccparity_f_teamreview-3, vscimpb107, vscimpb115, qrfix10, vscimpb66b, vscimpb23, vscannot3)`; `vscannot3` added for the marks (F-REV-7) |
| F-REV-21, ww:R1 | **CV.17** (new) | the layout of a review (`reviews/<review-name>/review.yaml`, `round-<n>/outbound/base/`, `outbound/<member>/`, `returned/<member>/`, `consolidated/` with `merge-report.json`), written by the runtime's round operations (CR.5), the extension and Webwork; the extension's current round folder read and converted on first use `(<- S29: FQ-11; S23: 04c_woneb4, planned; S25: 09_woneb3, planned)` |
| ww:R2 | CV.5 | its last two sentences rewritten: what is under review, with members, coordinator and rounds, is named in the review's `review.yaml` (CV.17), the same for every application and the runtime's round operations; the files of a round sent through tac are its pinned blobs (so D-29's "a review set is a named set of pinned files" still holds for tac) |
| ww:R3 | **CV.18** (new) | the round's state read from the folder (prepared, sent, returned, valid, consolidated); a file put in by hand counts like one through tac; the reviewer's list of review requests named (CP.36) `(<- S29: FQ-11; S25: 09_woneb2, 09_woneb3, planned)` |
| ww:R4 | CV.11 | rewritten: tac carries the round out and the copies back for the members who reach the round only through tac; a copy that arrives another way (export and import, mail through the system's mail client, by hand into the folder) counts the same once it is in `returned/<member>/` `(<- S29: FQ-9; …)` |
| ww:R5 | CV.12 step 1; CM.2 *review request* | "… the document set to every member — the base, or the member's own files where the round has them"; CM.2's *review request* row says the same with CV.17 |
| ww:R24 | `TAC-WEBWORK`, row WR-5 | met by CV.10 … CV.19; names CV.17, CV.18, CV.11 and PQ-66 |
| AR-30 | **CM.15** (new); CM.9 | a message's time is set by the service's clock when it accepts the message, never by the sending tac client; history, read state and retention are ordered by it `(<- S1 § 7.10)`. CM.9's sentence "The time of a message is the service's." is removed, since CM.15 now states it (one item, one statement) |
| F-TOL-6, vx:G-13, AR-17 | CI.13 | names the second, local-only MCP endpoint with file and host tools (CT.12) among the points open in PQ-50 |

Besides the rows (the todo's description):

- **The review exchange complete for Webwork:** CV.12 steps 1, 3 and 5 now name the round's
  folders (`round-<n>/`, `returned/<member>/`, `consolidated/`); its list of points for the
  Blueprint moves the three open ones (how a set travels, member id against tac user, how long a
  round's blobs stay) to PQ-66 and keeps the others; CV.13 is the **review folder** as the
  record of a review and its rounds, in any of Webwork's storage tiers `(<- S29: FQ-1, FQ-11)`;
  CV.14 names its bound as open (PQ-66); new **CV.19** (where the exchange works: members with
  storage access work in the shared folder and nothing travels; offline the folder holds
  everything and the merge runs against its base even when tac's blobs expired, while sending
  and returning wait for tac; the size limit per file with a reference or rendered form
  instead; encryption in transit only) `(<- S25: 09_woneb3, 13_woneb9, 13_woneb10, planned; the
  idea's part-review and part-messaging, Edge cases)`; CM.2's *review return* row writes into
  `returned/<member>/`; CV.9 cites Webwork's plan.
- **Messaging as Webwork planned it:** CM.7, CM.8, CM.10, CM.12 cite Webwork's `13_woneb7` …
  `13_woneb9` beside S1; the anchor `msg:tac/<team>/<messageId>` (CM.12) is unchanged; where the
  messaging components are built is PQ-43 (`p1s1r5-5`); notifications on phones stay PQ-49.
- **`TAC-WEBWORK`:** rows WR-2 (the team tokens kept by the runtime, CP.13, CS.11), WR-4
  (CM.1 … CM.15, the anchor, the service's time, Webwork's todos), WR-5 (above), WR-7 (the review
  option kept by the runtime, CR.17) rewritten; WR-1, WR-3, WR-6 keep their text with the
  citation rewritten. New paragraph: what D-74 adds beyond WR-1 … WR-7 (team review and review
  bundles) and where it is met (CV.11, CV.12, CV.17 … CV.19, CP.36, CR.119; open PQ-66). New
  paragraph: the three points Webwork is to be told (team tokens kept by the runtime against
  `13_woneb6`; the anchor `<team>` against `<server-group>` in `12a_woneb2`, `13_woneb9`; the
  review option kept by the runtime against `13_woneb2`'s device state).

### Questions written

- **PQ-50** rewritten (keeps its id): adds what the built MCP server serves (every enabled tool,
  file and host tools included, behind a key; a read-only floor from loopback or the VPN without
  it; F-TOL-6, vx:G-13) and S6's planned endpoint scopes (`remote-control` on loopback only, `mcp`
  per scope; AR-17); the recommended option gets a point (3), a second MCP endpoint reachable only
  from the local machine with the file and host tools, never published through tac; a new
  option (c) is (b) without that endpoint.
- **PQ-66** new: how a round's set travels through tac (one archive per member, one blob per
  file listed in the request, or the applications' convention), how a review member id is
  matched to a tac user (`review.yaml` names both), how long a round's blobs stay (until merged,
  at most 30 days, extendable) — merging Webwork's PQ-W1, PQ-W2, PQ-W4 (ww:R8, ww:R9, ww:R15,
  AR-31).
- **PQ-51** kept; one sentence added to its context (note d of S4 and Webwork's own MCP
  endpoint, AR-79, as § 2.9's row allows), options unchanged; written out in `new_questions.md`
  because the block in the Project Idea stays as it is.
- **PQ-49**, **PQ-52** kept as they stand (ww:N-18; ww:N-13).

### Open questions settled

None.

### Rows dropped

ww:R6 (CV.12 steps 1, 3, 5), ww:R7 (CV.1 … CV.4, CV.14), ww:R12 (CV.9), ww:R14 (CV.12,
CV.16), ww:R16 (CV.15), ww:R17 (CP.36; WR-4, WR-5), ww:R19 (CI.16, CI.17), ww:R23 (CP.13),
ww:N-15 (CV.8, CV.9, CM.3, CU.16): covered, as the triage says. ww:R13: CM.2, CM.4 and CV.12 step 4
stay (backed by S1). ww:N-17: Webwork's own. AR-37: confirms.

### Done otherwise than the triage says

- **AR-30:** the triage asks for a new CM.15; CM.9 already said "The time of a message is the
  service's". To keep one statement per item, CM.15 is added with the fuller text and the
  sentence is removed from CM.9, rather than stating it twice.
- **CV.5 and D-29:** § 1.6 writes "review set (what `review.yaml` names)", while D-29 and the
  glossary say "a named set of pinned files". CV.5 now says both: the set is named in
  `review.yaml`, and the files of a round sent through tac are its pinned blobs. No decision
  changed.
- **CV.19** is added beyond the rows, for the description's "what works offline, across
  machines and between users who share no version control; size limits and encryption"; it
  states Webwork's planned edge cases and cites them as planned.

### Obligations changed

- **CV.11:** tac is no longer the only way copies travel; "Nobody carries files by hand" is
  gone. The exchange collects the copies only for members who reach the round through tac; a copy
  arriving another way counts the same once it is in the round's folder.
- **CV.12:** the round's files are written into `round-<n>/` of the review, returned copies into
  `returned/<member>/`, the merge into `consolidated/`; a member may get files of their own.
- **CV.13:** the record is the review folder (`reviews/<name>/`), not a round folder per round.
- **CV.5:** what is under review is named in `review.yaml`, the same for every application and
  for the runtime's round operations (an obligation on the runtime's round operations: they
  read and write it).
- **CV.17** (new): one review layout, written and read by the runtime's round operations, the
  extension and Webwork; the extension's current round folder converted on first use.
- **CV.18** (new): the round's state is read from the folder; a file put in by hand counts.
- **CV.19** (new): the merge runs against the base in the folder without tac; the size limit
  applies per file of a round.
- **CM.15** (new; the sentence taken from CM.9): message times by the service's clock, never
  the client's; history, read state and retention ordered by it.
- **CV.14:** whether a round's blobs are bounded by a longest lifetime is now open (PQ-66) —
  the item no longer reads as keeping them without bound.
- **CM.2:** *review request* carries the member's own files where the round has them; *review
  return* is written into `returned/<member>/`.

### Sources needed

None new. S29, S31 and D-74 are cited as the triage names them (added by `p1s1r5-2`; D-74 is
written into `DEC` by `p1s1r5-10`).

### For other parts

- **p1s1r5-11 (`GLO`):** **review folder** (`reviews/<review-name>/`, CV.17) is a new entry;
  **round folder** becomes `round-<n>/` of a review (CV.13 now names the review folder as the
  record); **review set** should read "the set of documents a review covers, named in its
  `review.yaml`; sent through tac, its files are pinned blobs" (CV.5), so it agrees with D-29 and
  § 1.6.
- **p1s1r5-10 (`DEL`, D-74):** the messages owed to Webwork once the round is through: the three
  points of `TAC-WEBWORK`'s last paragraph (team tokens kept by the runtime — `13_woneb6`; the
  anchor `msg:tac/<team>/<messageId>` — `12a_woneb2`, `13_woneb9`; the review option kept by the
  runtime — `13_woneb2`), and the covering todos for WR-1 … WR-7 replacing the `12b_woneb*`,
  `tac_webwork-*` and `ww_*` entries in Webwork's `blocked_by`. D-74 is cited in `TAC-WEBWORK`.
- **p1s1r5-3 (`RT-HOLDS`, CR.5):** the runtime's team review round operations write and read the
  review layout of CV.17 (and convert the old round folder); CR.5 could point to CV.17.
- **p1s1r5-4 (`RT-MCP`, CT.11, CT.12):** PQ-50's recommended option now has a point (3), a
  second MCP endpoint reachable only from the local machine with the file and host tools; CT.11
  and CT.12 name it as open in PQ-50 (CT.12 already does).
- **p1s1r5-5 (`CLI-UI`):** the Review group's components read the round's state from the folder
  (CV.18) and show the reviewer's list of review requests (CP.36).
- **p1s1r5-9 (PQ-56):** the per-file size limit now applies to every file of a review round
  (CV.19); the number a review bundle with images needs stays PQ-56's.

## `p1s1r5-8` — `PAR`

Done 2026-11-25. Every change is a marked change in `../project_idea.ai_runtime.md`, from the
`<!--[PAR]-->` heading to the heading `NFR` (63 marks: 46 substitutions, 16 additions, 1
deletion). Every source note of `PAR-PROBLEM`, `PAR-APPROACH`, `PAR-CROSS` and `PAR-QUESTS` is
rewritten into the citation shapes (`(<- …)` for sources, `(-> …)` for decisions, answered
questions and items); "open (PQ-n)" where the sentence is about the question stays as content.
The question blocks PQ-53 … PQ-55 stay where they are; their rewritten forms are in
`new_questions.md`. Nothing outside `PAR` was changed (checked against a copy taken before).

### Rows applied (finding → item)

| Finding | Item(s) changed or added |
| --- | --- |
| F-TOD-8 (B1) | CW.12: citation `(<- S1 § 10.4, item 7; S17 user guide *Todos that block others*; S23: finishvsc2)` |
| F-TOD-23 (B1) | CQ.3, the bullet "the session todos": `(<- S17 user guide *Session todos*)`; the built behaviour (one file per session, on its machine) is put into PQ-53's context, since CQ.3 waits for PQ-53 |
| F-QUE-28 (B1) | CW.19: `S23: ww_a_collab-4` added to the citation; CW.20: citation rewritten |
| AR-14 | new **CW.28** (only an item that executes a todo claims; an agent's claim tool is refused outside such an item) `(<- S6: DPR-1, DP-part-claims-2; S30: ww_c_collab-4, planned)`; CW.8 points to CR.35 for where the quest's list is recorded (`quest-resources.<quest>.yaml`), as `p1s1r5-3` asked |
| AR-22 | new **CW.29** (orphaned working trees and branches shown on the coordination page, CU.18; never removed on their own) `(<- S6: part-branches-and-worktrees; S30: ww_g_collab-1, planned)` |
| AR-60 | CQ.12: the dated journals (progress, deferred work, documentation updates) are merged as the union of their dated sections, sorted by date and time — "the progress" moved out of the "by section" group `(<- S30: ww_e_gitruntime-2, planned)`; CQ.6: the fleet's drivers cited `(<- S23: vscimpb152aaa, planned)`; no question (the runtime uses the fleet's drivers, E-5) |
| AR-62 | CQ.6: "for each run one shared file of its process position, moved only on the main branch, a move refused when that file changed on the main branch since it was read" `(<- S30: ww_e_gitruntime-4, planned)` |
| AR-81 (for p1s1r5-8) | CW.15: "A draft pull request is opened only for a todo that carries risk, and only when a person asks for one" `(<- S1 § 10.4, item 10)` |
| F-QST-3, F-WSL-3, F-WSL-4, vx:G-9 | asked in **PQ-55** (rewritten); CQ.7's open paragraph names the setting up of a workspace folder from the template and the creation of a quest with its setup todo and short description beside the operations |
| AR-59 | asked in **PQ-53** (option (b): `_ai/personal/<id>/`); CQ.2's open paragraph names the extension's plan and this quest's plan |
| AR-61, AR-64, AR-65, AR-69 | asked in **PQ-54** (rewritten); CQ.6's open paragraph says these features are this quest's queued todos and therefore in the first version unless a decision puts them later (D-74) |
| — (all sections) | citations rewritten in the intro of `PAR-PROBLEM`, CW.1 … CW.27, CQ.1 … CQ.13 and the intro of `PAR-APPROACH` (PQ-14) |

### Besides the rows

- **`PAR-APPROACH` and the extension's collaboration plan (`caf_*`, S28).** The triage rules all of
  it into PQ-63 (`p1s1r5-6`). Written as pointers only, no `caf_*` feature as an item: a paragraph
  after the section's intro naming the plan (git-ref leases, `todo/<id>` / `group-todo/<id>` /
  `feature/<id>` branches in `<folder>@<branch>` working trees, the merge tool, review todos,
  feature runs, the standard runs `planning` and `quest-keeper`) and that PQ-63 decides it; CW.3
  (the extension's branch and tree names, open with PQ-63); CW.5's open sentence (the merge tool,
  PQ-63); CW.8 (`defaultResources` of `quest-keeper`, PQ-63); CW.15 (review todos with rework,
  PQ-63). *Proceed anyway* (`caf_04b`) is in PQ-39 (`p1s1r5-4`) and named in the paragraph only.
- **`PAR-CROSS`.** Items sent to another quest (CW.19, CW.20: built, `ww_a_collab-4`), the done
  notification (CW.23: built, `vscimpb146`), todo offers (CW.26: no extension or Webwork source;
  kept on S21 TQ-11) and the following of blockers (CW.21) already state the baseline carried
  across machines and to a team. Added: under CW.20, the extension's planned items that wait for a
  todo or a run of another quest, barriers and control items, open with PQ-64 (`p1s1r5-3`)
  `(<- S23: vscimpb187, vscimpb188, caf_07c, planned)`; in CW.13 one sentence that the further
  control items are PQ-64; in CW.25 that a todo already written can be moved into another quest
  (`RT > RT-HOLDS`, CR.114, written by `p1s1r5-3`).
- **`PAR-QUESTS`.** The quest management the extension plans (`02_aifmt-1`) is cited in CQ.1, CQ.9
  and CQ.7; the per-host files (`01_aifmt-4`) in CQ.2's open paragraph and CQ.11; this quest's
  `ww_e_gitruntime-*` todos in CQ.2, CQ.5, CQ.6 and CQ.12. **`tom_kdbx` is named nowhere in the
  Project Idea:** PQ-54 says the todo `ww_e_gitruntime-5` names it, that it was retired over its
  licence and is not to be depended on, and that the KDBX layer is `tom_kdbx_store` over
  `tom_kpasslib`.

### Questions written

| Id | Kind | What changed |
| --- | --- | --- |
| PQ-53 | rewritten | the per-host files in the quest are the baseline (S22, D-71, the extension's `01_aifmt-4`, D-74); asked is only whether any personal place remains and where the personal notes go; options: none (recommended), `_ai/personal/<id>/` (this quest's `ww_e_gitruntime-1`), a personal repository for notes only, a personal repository for shared quests (D-34) |
| PQ-54 | rewritten | the four features as this quest's queued todos (`ww_e_gitruntime-3`, `-5`, `-6`, `-7`) with their content; the publish offer and setting and the ahead / behind display; KDBX through `tom_kdbx_store` / `tom_kpasslib` (never `tom_kdbx`); member accounts at the repository server and access through its teams; the pilot `checks11` as a flow for two members in option (b); recommendation unchanged (later) |
| PQ-55 | rewritten | merged with vx:G-9: the setting up of a workspace folder from the template (three forms), the template every build packs, creating a quest with its short description and setup todo (built), QUEST MANAGEMENT (`02_aifmt-1`, planned); a new option (d): quest operations in the runtime, workspace template and setup with each host's installer |

### Open questions settled

None.

### Rows dropped

| Finding | Why |
| --- | --- |
| AR-20 | confirms CW.16, O-6 |
| AR-66 | confirms CQ.7 (migrate), CQ.8 |
| AR-68 | confirms CQ.7 (create, join) |

### Done otherwise than the triage says

- **AR-14's question** (is a todo's `scope` read as resources when it names none) and **AR-22's
  question** (is an execution's branch pushed after every commit) are not asked: the triage rules
  both rows **apply** with one new item each and names no question. Recorded here so `p1s1r5-11`
  can pick them up if wanted.
- **AR-63** is not mine (the triage gives it to `RT-SECRETS`); only its "never name `tom_kdbx`"
  is carried into PQ-54's context.

### Obligations changed

- **CW.8** names where the quest's list is recorded (with CR.35) — no change of what is demanded.
- **CW.15** adds a draft pull request on request for a todo that carries risk.
- **CQ.6** demands one process-position file per run, a move refused after a concurrent change
  (before: "one shared process position").
- **CQ.12** merges the dated journals as a union of dated sections (before: the progress by section).
- New **CW.28** (only an item that executes a todo claims) and **CW.29** (orphans shown, never
  removed on their own).

### Sources needed

None beyond S28 … S31 (added by `p1s1r5-2`); this part cites S23, S28 and S30.

### For other parts

- **p1s1r5-2:** S23's range must cover `finishvsc2`, `vsc_setup-*` and `vscimpb152aaa` (the
  extension's older completed todos), as `p1s1r5-3` noted for its own citations.
- **p1s1r5-10:** `DEL`'s al_the_bear line (AR-67) waits for PQ-53 and PQ-54; if PQ-54 is answered
  (c), `SCO > SCO-LATER` gets the line for member branches, the internal repository, the secret
  scan and member access.
- **p1s1r5-11:** new terms without a `GLO` entry: **orphan** (CW.29); "dated journal" (CQ.12). The
  highest items of the part are CW.29 and CQ.13.
- **The quest (not a part):** the todo `ww_e_gitruntime-5` still names `tom_kdbx`; it is replaced
  with the specification's todos (D-42), so it was not edited here.

## `p1s1r5-9` — `NFR`

Done 2026-11-25. Every change is a marked change in `../project_idea.ai_runtime.md`, from the
`<!--[NFR]-->` heading to the heading `DEC` (68 marks: 56 substitutions, 12 additions). Every
source note of `NFR`, `NFR-TOPO`, `NFR-TOPO-FLOWS` and the prose of `NFR-GEN` is rewritten into
the citation shapes (`(<- …)` for sources, `(-> …)` for decisions, answered questions and items);
"open (PQ-n)" where the sentence is about the question stays as content, and so do the tables'
Source columns (a column of ids is content). The question block PQ-56 stays where it is; its
rewritten form is in `new_questions.md`. Nothing outside `NFR` was changed (checked against a copy
taken before).

### Rows applied (finding → item)

| Finding | Item(s) changed or added |
| --- | --- |
| F-QUE-32 | new **N-44** under a new group "The queue keeps going": every 60 seconds the runtime takes items other quests sent that it missed, puts items that waited out a usage limit or a retry countdown back to pending, and sends stalled pending items on `(<- S17 user guide *Watchdog and Health Check*)` |
| ww:N-3 | T2: "A host whose run is bound to a quest folder uses that quest's runtime" `(<- S25: 12a_woneb1, planned)` |
| V2-6 | N-33 rewritten: "The work on the new VS Code extension changes nothing of the old one; the new extension is installable at every step, in a window or a profile where the old one is not active" `(<- S1 § 13.3) (-> D-73)` |
| AR-81 (for p1s1r5-9) | new **N-45** in "Testing": the runtime's tools on specification documents work on documents of the size the specification process produces (this Project Idea, about 480 KB) without failing or running out of time; the Solution Blueprint names the size tested `(<- S1 § 3.5)` |
| — (whole part) | citations rewritten in N-1 … N-34, the lead-ins of `NFR-TOPO` and `NFR-TOPO-FLOWS`, the paragraph after the topology table, the notes in the cells of T6, T7 and T8, and the prose of `NFR-GEN` |

### Besides the rows

- **N-33 and the second extension (§ 1.3).** Written as above. N-24 and N-32 stay (they bind the
  runtime); their citations rewritten.
- **The topologies and flows after D-73:**
  - **T1:** one runtime per window inside the **new** VS Code extension, in its own process until
    PQ-37 is answered (`RT > RT-HOLDS`, CR.142, which carries PQ-37's assumption); during the
    parallel period the old extension's windows run its own engine, which is not a runtime, on the
    same `_ai` folder (CR.112). Source column adds D-73.
  - **F1:** the new VS Code extension runs the runtime in its own process until PQ-37 is answered
    (CR.142).
  - **N-10:** a paragraph — while both extensions are in use, the old extension's engine may work
    on the same machine and `_ai` folder as the runtimes; same quest open (PQ-36), format version
    open (PQ-40) `(-> D-73)`.
  - **G-1:** "also a library inside the new VS Code extension, as long as PQ-37 leaves that
    standing" (CR.142).
- **Team review through tac:** the triage rules no new flow, but it rules the review exchange
  (§ 1.2: CV.11 rewritten, CV.17, CV.18; CV.19 by `p1s1r5-7`), so **F6 is rewritten** to agree
  with it: the round `round-<n>/` in the review folder; the request through tac only to members who
  reach the round only through tac; members with access to the storage work in the folder and
  nothing travels; a copy returned through tac or another way lands in `returned/<member>/`; the
  state read from the folder; merged into `consolidated/`; blobs released; how the set travels, the
  member-to-user match and the blobs' lifetime open (PQ-66). Source column adds S29: FQ-9, FQ-11 and
  S25: 09_woneb3, 13_woneb10.
- **`NFR-GEN`:** the new extension is **not** made a generation unit: the triage puts it into the
  product's scope as the VS Code host (§ 1.3) but rules no unit, kind or technology, and no source
  states them. The list "Delivered and not yet assigned to a unit" now names "the new VS Code
  extension, the copy of the extension in `tom_ai/ai_build` rewired to the runtime as the VS Code
  host (`DEC`, D-73; its folder and name: PQ-60)" instead of "the VS Code extension as a host on the
  new line (D-41)".
- **N-36 and N-37** (topics only, no numbers): N-36 adds machines per user and the members and
  files of a review round (CV.17); N-37 adds that every file of a review round meets the size limit
  (CV.19), as `p1s1r5-7` asked.

### Questions written

- **PQ-56** (rewritten) — the built and decided numbers are listed in its context and not asked
  (the watchdog's 60 seconds, N-44; the chat send's response time, 60 minutes, CR.125; the lease,
  ask, invitation, blob, message and payload numbers); a round's blob lifetime is pointed to PQ-66;
  new rows: machines per user (6), members and files of a review round (25; 200); the size limit
  per file now argued from Webwork's `.webwork.zip` bundles with images and CV.19's fallback to a
  reference or rendered form; the quota row names a round's blobs. Options and recommendation (b)
  unchanged.

### Open questions settled

None.

### Rows dropped

None.

### Done otherwise than the triage says

- **F-QUE-32's "polling every 30 s"** is not written: the cited source (the extension's user
  guide, *Watchdog and Health Check*) describes only the 60-second watchdog and its three tasks; no
  30-second queue polling is documented there or in the extension's `doc/` (the 30-second figures
  in the user guide are the window heartbeat, the build check and the timer tick). N-44 says what
  the source says.
- **A flow for the old and the new extension on one machine** is not added: the triage rules none;
  the case is stated in N-10, T1 and CR.112 and asked in PQ-36 and PQ-40.
- **A new flow for team review** is not added; F6 is rewritten instead (above), since it is the
  team review flow and contradicted CV.11.
- **N-44 / N-45 numbering:** N-44 is the watchdog (it stands first in the section); the tools item
  that AR-81 proposed as "N-44" is **N-45**.

### Obligations changed

- **N-33** demands that the work on the new extension leaves the old one unchanged and that the new
  one is installable at every step in a window or profile without the old one (before: every stage
  of the split leaves the extension working and installable).
- New **N-44** (the queue's watchdog, as built) and **N-45** (the spec tools work on documents of
  the specification's size).
- **T1** (the runtime inside the new extension; the old engine beside it), **T2** (a run bound to
  a quest folder uses that quest's runtime), **F1** (in-process for the new extension until PQ-37),
  **F6** (the review exchange as CV.11, CV.17 … CV.19 state it).

### Sources needed

None beyond S28 … S31 (added by `p1s1r5-2`); this part cites S17, S25, S29 and D-73.

### For other parts

- **p1s1r5-10:** R-31 (two engines on one `_ai`) can refer to N-10's new paragraph; `DEL`'s
  acceptance of the new extension (PQ-57) can name N-33.
- **p1s1r5-11:** the highest `NFR` items are N-45, T8, F13, G-10. "The queue keeps going" is a new
  group heading of `NFR`. No new glossary term.

## `p1s1r5-10` — `DEC`, `CON`, `RISK`, `DEL`

Written by `p1s1r5-10` on 2026-11-25, after `p1s1r5-2` … `p1s1r5-9`; every part's "Obligations changed" and "For other parts" were read first. Every change is a review mark; no other part was edited.

### Rows applied (finding → item)

| Finding | Ruling | Item changed or added |
| --- | --- | --- |
| ww:R18 | apply | `DEL` "What the other quests are told", webwork: the team token is the runtime's, not in the device's settings container as `13_woneb6` has it (CS.11, X-16) |
| ww:N-5 | apply | same bullet: the review option of a run is the runtime's, not device state as `13_woneb2` has it (CR.17) |
| ww:N-16 | apply | same bullet: the anchor is `msg:tac/<team>/<messageId>`; `12a_woneb2` and `13_woneb9` still write `<server-group>` (CM.12) |
| ww:N-25 | apply | same bullet rewritten: Webwork is on hold until this specification exists (`03a_woneb1`, E-15); told when it is finished, then the WR map with its `blocked_by` entries moved (`12b_woneb*`, `tac_webwork-*`, `ww_…`), then "runtime complete" |
| AR-11 | settle | D-73's "Replaces" names RS-1's recommended option (a) and that RS-1 (b) was taken, in `tom_ai/ai_build`; D-41 marked replaced |
| AR-25 | apply | `DEL` paragraph after the track table: the coordination idea's hand-off (`ww_g_collab-999`) is the swap; the todo list names `ww_g_collab-999` |
| AR-67 | apply | `DEL`: new bullet **`al_the_bear`**, told once PQ-53 / PQ-54 are answered what differs from its standard, if anything |
| AR-79 | apply | D-3's "Replaces or completes" names S4 note k (generated from the Dart code; FO-10 generates from the schema) |
| V2-1 | settle | **D-73** written (row after D-43, table "The specification and the delivery"); **D-41** marked replaced ("Replaced by D-73: a copy of the extension in `tom_ai/ai_build`, not a branch.") |
| V2-2 | apply | `DEL` "The stable extension during the split" → "The new VS Code extension": the copy at the copy point (PQ-61), the old extension left alone (PQ-61), both installed (N-33, PQ-60), finished against PQ-57 / PQ-62, the swap and the retirement per `retiring_and_archiving.md` (PQ-60) |
| V2-3 | apply | `DEL` step 3 (the copy after steps 1 and 2, PQ-61); D-40 (the copy, not the split; when: PQ-61); R-16 "For": the engine complete before it is copied, and the state names PQ-61; "which the extraction depends on" → "which the rewiring of the copy depends on" |
| V2-5 | apply | R-1 rewritten "Two copies of one large code base" (risk, trigger, source cells); new **R-31** "Two engines on one `_ai` during the parallel period"; new **R-32** "The swap" (V2-5's third proposal, numbered after R-30 and R-31) |
| V2-12 | apply | `DEL` "What replaces which of this quest's todo groups": `ww_b_workbench-2 … 7` replanned against the copy |
| V2-13 | apply | same list: `ww_d_workbench-9 … 12` (conformance against the old extension's files, packaging, the old engine and the runtime on one `_ai`, documents) and the new todos (team views, acceptance run, swap, retirement, script server) |
| V2-14 | apply | track table: the third column "Depends on the copy of the extension"; the runtime row "The runtime and the new VS Code extension (D-73), the protocol, …"; hand-off as AR-25 |
| V2-21 | settle | D-1 stands unchanged; new **X-23** (`ww_e_runtimeapi-1`'s place against D-1 and CL.3, resolved by D-1, D-73, CL.13) |
| ww:PQ-W5, AR-7, AR-33, AR-46, V2-23 | ask | merged into **PQ-57** (rewritten) |
| V2-15, V2-20, V2-22, V2-28 (and V2-26's ownership) | ask | **PQ-60** (new) |
| V2-19, V2-25, AR-77 | ask | **PQ-61** (new) |

### Besides the rows

- **D-73** and **D-74**, from instructions (b) and (a), with the shaped sections other parts cite (SCO, LAND, RT-HOLDS CR.112, RT-INSTALL CR.142, NFR N-10 / N-33, RISK, DEL). The `DEC` lead-in names S31 as the source of round 5's decisions.
- **Decisions the round settled for open questions:** the chat half of PQ-39 (D-61 now says a chat send in another session of a waiting run goes out, as built; the leases stay asked); RS-1 (D-73); V2-26's scope (D-73: the new extension is in scope as the VS Code host, views carried over).
- **Other decisions that D-73 overtakes**, each now naming it: D-9 (VS Code's tools stay in the VS Code extension — the new extension), D-40, D-41, D-67 (messaging comes to VS Code with the new extension).
- **`CON`:** new **X-22** (the extension's collaboration plan S28 against tac, D-24, D-68 — not settled, PQ-63 / PQ-45 / PQ-46), **X-23** (`ww_e_runtimeapi-1`, resolved), **X-24** (`ww_f_collab-6` against D-6, resolved: deferred; the new extension's Telegram is PQ-62), **X-25** (Webwork's review channels against CV.11, resolved by S29 FQ-9 as `p1s1r5-7` rewrote CV.11), **X-26** (the in-place split against the second extension, resolved by D-73); X-18 adds the format version of the parallel period to PQ-40. Source notes in `CON` rewritten into the citation shapes (X-1 … X-21).
- **`RISK`:** R-1, R-31, R-32 (the second extension); **R-30** (an agent transport that needs another language runtime, from `p1s1r5-4`'s AR-54); R-28 (Webwork on hold until the specification exists, `03a_woneb1`, as trigger and source); R-18 `tom_todo_model` 6.0.0 with the consumers moving (`vscimpb180`); R-19 names Webwork's messaging components (`tom_messaging_ui`, S29 C21) beside the review component. **State unchanged:** R-15, R-17, R-20, R-21, R-29 (no source of this round changes them); the risks R-2 … R-14, R-22 … R-27 stand as written.
- **`DEL`:** "What the first version contains" (D-74) before "What is delivered"; the delivered list names the new extension (PQ-60 for folder and name); "Not delivered here" follows O-1 as `p1s1r5-2` rewrote it; "The order of building" cites CR.83 as built (`vscimpb179`), as `p1s1r5-3` asked; new bullets for `vscode_extension` (the copy point once PQ-61 is answered) and `al_the_bear`; tom_forge is told that the VS Code host is the new extension. Source notes in the touched paragraphs rewritten into the citation shapes.

### Questions written

- **PQ-57** rewritten (acceptance of the product and of the new extension; two thin paths, the second a team review between two desktops for Webwork).
- **PQ-60** new (identity beside the old extension, the swap, retiring, ownership).
- **PQ-61** new (the copy point, the backlog list, fixes only, the scripting API split on the copy).
- The block of PQ-57 in `DEL` is left where it is, unchanged (round instructions: `p1s1r5-11` puts the final set in).

### Open questions settled

- **PQ-39**, the chat half: settled by D-74 (built: `vscimpb132`, `vscimpb135`), written into D-61; the lease half stays asked (rewritten by `p1s1r5-4`).

### Rows dropped

- **AR-1** — the stale todo; D-1 holds and the todo is replanned under V2-12.
- **AR-10** — confirms N-30; replanned under V2-13.
- **AR-84** — quest documents, not the Project Idea; for the closing item.
- **ww:N-12** — covered: the token's place is told to Webwork under ww:R18.

### Done otherwise than the triage says

- **D-73 and D-74 placed** as two rows of the table "The specification and the delivery" (after D-43) rather than in a table of their own: a new table needs an unmarked header line; the `DEC` lead-in names S31.
- **R-32 "The swap"** added (V2-5's third proposal); the triage named only R-31, and the todo's description asks for the swap as a risk.
- **X-24 … X-26** added beside the triage's X-22 and the `ww_e_runtimeapi-1` entry (X-23), because the todo's description names `ww_f_collab-6`, the review channels and the v2 plan as contradictions to record.
- **AR-33** (Webwork's end-to-end check) went into PQ-57 option (b)'s path 2, not into a separate `DEL` sentence (the inventory offered either).

### Obligations changed

- **D-40**: the copy of the old extension, not the split, comes after the features and the workspace layout; when is asked (PQ-61).
- **D-41**: replaced by D-73; no branch, no rule that the new extension refuses to start beside the old one (now PQ-60).
- **D-73** (new): the new extension in `tom_ai/ai_build`, rewired to the runtime until every feature works as before, distributed and with a team; the old one left alone; the swap; in scope as the VS Code host.
- **D-74** (new): the feature baseline is the first version.
- **D-61**: a chat send of a waiting run goes out.
- **D-9, D-67**: VS Code's tools and messaging belong to the new extension.
- **`DEL`**: the delivery is the new extension accepted against the old one (as PQ-57 decides), the swap and the retirement; the old `ww_b` / `ww_d` stages are replanned against the copy.

### Sources needed

- None new. Cited: S23 (`vscimpb179`, `vscimpb180`), S25 (`03a_woneb1`, `13_woneb2`, `13_woneb6`, `12a_woneb2`, `13_woneb9`), S28, S29 (FQ-9, FQ-11, C21), S30 (`ww_b_workbench-*`, `ww_e_runtimeapi-1`, `ww_f_collab-6`, `ww_g_collab-999`, `ww_e_gitruntime-9`, `xxmistral1`, `rca1`), S31. The workspace guideline `retiring_and_archiving.md` is named as a document (R-32, `DEL`), not as a source row; `p1s1r5-11` may add it to `SRC` if wanted.

### For other parts

- **p1s1r5-11 (`GLO`, the whole document):** the highest ids of these sections are **D-74**, **X-26**, **R-32** (dependencies up to R-29), and the questions now run to **PQ-66**; `ABOUT-READ`'s highest-ids line needs them. `GLO` needs "copy point", "swap", "old extension", "new extension", "parallel period" (used in D-73, R-31, R-32, `DEL`, PQ-60, PQ-61). The PQ-57 block in `DEL` is to be replaced by the rewritten one in `new_questions.md`; PQ-60 and PQ-61 go after `DEL`'s "The new VS Code extension".
- **p1s1r5-2 (`SRC`):** S18's standing "RS-1 is replaced by D-73" (AR-11) — check it is in; D-73's "Replaces" says RS-1 (b) was taken.
- **The quest (not a part):** this quest's todos `rca1` and `ww_g_collab-999` are named as replaced in `DEL`; `ww_f_collab-6` stays deferred (X-24). They are replaced with the specification's todos (D-42) and were not edited here.

## `p1s1r5-11` — `GLO`, the whole document, the final question set

Read: `round_instructions.md`, `answers.md`, `triage.md` (§ 1.6, § 2.10, § 3), every part's
section above, `new_questions.md`. Done in two turns of the todo; the first did steps 1, 3 and 5,
the second steps 2, 4, 6 and 7.

### Rows applied (finding → item)

| Finding | Applied as |
| --- | --- |
| AR-83 | S21 kept equal to `GLO`: the terminology document `_ai/quests/ai_runtime/ai_runtime_terminology.md` § 2 carries the same 142 rows as `GLO`, term for term and meaning for meaning (compared mechanically after the edit); its § 4 has the round's decisions D-73 and D-74 (plain edit, no marks) |
| V2-11 | `GLO`: **old extension**, **new extension**, **copy point**, **swap** (and **parallel period**), in the words of triage § 1.6 and D-73; PQ-58 rewritten (it asks only whether the words are right, with Webwork's "group") |

### Besides the rows

- **`GLO`** (marked changes; the terminology document § 2 the same as a plain edit). New entries:
  replay key, adapter and preset (of a provider), night mode, assist, lane (of a run), chat send,
  marker (of a process step), control item, review and review folder, review document bundle,
  guest (of a review round), coordination page, orphan, dated journal, old extension, new
  extension, copy point, swap, parallel period, feature baseline. Changed: server, review set
  (the set a review covers, named in its `review.yaml`; through tac its files are pinned blobs),
  review round and round folder (`round-<n>/` of a review), review copy and base, aspect
  guidelines (with "aspect" and "choice", the extension's terms). Table of words not used: "the
  split", "v1, the stable extension", "the second extension, v2", "round folder (for a whole
  review)". "integration lease" and "standard run" (`p1s1r5-6`) have no entry: they would come
  only with PQ-46 (b) and PQ-63 (b).
- **The final question set** (step 5): the 33 questions stand in the document after the items
  they ask about, in the form of `round_instructions.md` § Questions; checked mechanically for
  each block: a context, a "why I ask", at least two options, exactly one bold option and the
  recommendation naming it, an assumption until answered and an empty `> **Answer:**` — all 33
  pass. `new_questions.md` § The final set lists what is where.
- **Status** (step 6): the `Status` row names question round 5 and the 33 open questions
  (`PQ-34` … `PQ-59` of round 4 reworked, `PQ-60` … `PQ-66` new); `ABOUT-READ`'s question row
  names `PQ-60` to `PQ-66`, its risk row adds `R-30` to `R-32` as risks, and its highest-ids line
  has every area's final value (`CR.142`, `CP.45`, `CT.21`, `CA.45`, `CI.20`, `CM.15`, `CV.19`,
  `CW.29`, `CL.15`, `CU.18`, `CK.12`, `CQ.13`, `CS.26`; `S31`, `V-8`, `U-17`, `O-11`, `L-15`,
  `E-23`, `P-14`, `SC-38`, `N-45`, `T8`, `F13`, `G-10`, `D-74`, `X-26`, `R-32`; `PQ-1` … `PQ-66`).

### "For other parts" no part took (step 2)

Every "For other parts" entry above was checked against the document. Taken by their parts, or
by this todo's steps 1 and 6 where addressed to `p1s1r5-11`: all but these four, now done here as
marked changes:

| Entry (from → to) | Done |
| --- | --- |
| `p1s1r5-7` → `p1s1r5-3`: CR.5 could point to the layout of a review | CR.5: "A team review round is kept in the layout of a review (`TAC > TAC-REVIEW`, CV.17)." |
| `p1s1r5-7` → `p1s1r5-4`: CT.11 and CT.12 name PQ-50's local second endpoint | CT.12 had it; CT.11 now ends "Whether a second endpoint for the local machine only offers the file and host tools beside it is open (CT.12; PQ-50)." |
| `p1s1r5-8` → `p1s1r5-2`: S23's range must cover `finishvsc2`, `vsc_setup-*` and `vscimpb152aaa` | S23: "the todos completed through 2026-11-25, among them `finishvsc2` of 2026-10-27 and `vsc_setup-…` of 2026-11-08" (`vscimpb152aaa` is open, in the todo file S23 names already) |
| `p1s1r5-9` → `p1s1r5-10`: PQ-57 can name N-33 | PQ-57 option (b), point (2): the new extension "having been installable at every step without changing the old one (`NFR`, N-33)"; the same in `new_questions.md` |

The quest-level notes ("The quest (not a part)" of `p1s1r5-8` and `p1s1r5-10`: `ww_e_gitruntime-5`
names `tom_kdbx`; `rca1`, `ww_g_collab-999`, `ww_f_collab-6`) are left to the todos of the
specification (D-42), as those parts say.

### The cross-check (step 4)

Checked mechanically on the document (a script in `ztmp/`, deleted) and by reading what it
reported; old text inside `{~~ … ~>` and `{-- … --}` is not current content and was checked only
for well-formed marks.

- **Marks:** every `{~~` has one `~>` and its `~~}`; every `{++`, `{--`, `{>>` is closed; none is
  nested; no blank line inside a mark. No finding.
- **Lines starting with `>`** outside a question block: none. **Section-id chains:** every part
  resolves to a section id; none is broken across lines.
- **Item ids:** each id written in bold at the start of an item or row is defined once. Ids
  referred to without a definition in this document: only `CQ-1` … `CQ-20`, the product owner's
  answers in S1 § 14.1 (defined there, `ABOUT-READ` says so) — kept.
- **Names** (triage § 1.6): `tom_quest_runtime` stands only in `DEC` (D-1's "Replaces") and `CON`
  (the contradiction it resolved); `tom_todo_model` is 6.0.0 everywhere; "v1", "the stable
  extension", "the second extension" stand only in `GLO`'s table of words not used, in PQ-58, in
  the quotation of the product owner in D-73, and in `CON` X-26; "round folder" stands only in its
  new sense (`round-<n>/` of a review: `GLO`, CV.17) and in PQ-66 — kept.
- **The split:** current text names it only as what it is not: S4 (the split of the MCP server, a
  different thing), S18 (its plan, replaced by D-73), S30 (the todo ids), `GLO`'s table of words
  not used, `RT-HOST` (citing `ww_b_workbench-4` as a source), `CON` X-26 and `DEL`'s list of
  replaced todos — kept. Nothing describes the in-place split as the plan.
- **History wording** outside `DEC` and `CON`: six hits in `RT > RT-QUEUE`, all describing a state,
  not a change of the text ("without the earlier context", a session the agent program "no longer
  has" — the title of the user guide's section —, "never earlier", "a blocker that runs earlier in
  the same walk") — kept.
- **Source notes:** 57 parenthesised source ids in current text outside question blocks were read
  one by one. Four were source notes in the old form and are rewritten as marked changes: `GLO`'s
  lead-in `(<- S21)`; `CON` X-13 `(<- S1 § 5.7) (-> DQ-9)`; R-18 `(<- S23: vscimpb180, planned)`;
  `DEL`'s line on `webwork` `(<- S25: 03a_woneb1)`. The other 20 outside question blocks name the
  source the sentence is about ("the standard for quests (S22) has …", "Webwork states six
  requirements on tac (S3, WR-1 … WR-6)", the id prefixes in `ABOUT-READ`, "S1 and S6 name a file
  …"): content, not citations (`round_instructions.md` § Secondary prose) — kept. Question blocks
  name their sources in their own words and are left as written. No `::: {.provenance}`,
  `{.editorial}` or `{.aside}` div or span is in the document, so no content sentence is marked
  secondary.
- **Agreement of scope, decisions, delivery, topologies and flows with the items:** read for the
  round's two decisions: `SCO-IN`, `DEC` D-73 / D-74, `DEL`, T1, G-1, G-6, F12 and the items they
  cite agree with CR.112, CR.142, CP.14, N-33, R-31 and the assumptions of PQ-37, PQ-40, PQ-43 and
  PQ-48.
- **O-11** (the baseline check's one wording point): "memory shared across quests" is right — the
  extension's `00_aifmt-3` removed the `_ai/memory/shared/` scope, which spans quests (CR.53 says
  the same); the inventory's F-MEM-5 wrote "across sessions". Unchanged.

### The baseline check (step 3)

Checked 2026-11-25 against `project_idea.ai_runtime.md`, `new_questions.md`, `changes.md` and
`triage.md` § 2. Method: the 302 table rows of triage § 2 (every finding not ruled B1 or retiring)
were parsed; each was looked up in `changes.md` (all parts). For **apply / settle** the named item
(or the new item `changes.md` names) was found in the document and checked to carry a mark with
the ruling's content (item present and marked, distinctive words and cited todo ids found; every
row with a low word overlap was read by hand). For **ask** the question block was found and its
text checked for the finding's subject. **Drop**: the triage's reason. B1 and retiring: spot
check.

#### (a) Counts

| Inventory — findings | Checked | Covered in text | Asked | Ruled out (dropped / done otherwise with reason) | Not handled |
| --- | --- | --- | --- | --- | --- |
| vscode extension § 2 — `F-*` not covered / partly / differs (114, plus F-SES-16, F-PRE-1 in tables) | 116 | 66 | 43 | 7 dropped | 0 |
| vscode extension § 4 — `vx:G-*` (extra, in the tables) | 18 | 11 | 7 | 0 | 0 |
| webwork § 2 — `ww:R1 … R24` | 24 | 10 | 5 | 9 dropped | 0 |
| webwork § 3 — `ww:N-1 … N-25` | 25 | 5 | 7 | 13 dropped | 0 |
| webwork § 4 — `ww:PQ-W1 … W6` (extra) | 6 | 0 | 6 (merged into PQ-37, PQ-43, PQ-57, PQ-66) | 0 | 0 |
| ai_runtime quest — `AR-*` | 84 | 45 | 16 | 22 dropped | 1 (AR-83, pending) |
| ai_runtime quest — `V2-*` | 29 | 13 | 15 | 0 | 1 (V2-11, pending) |
| **Total** | **302** | **150** | **99** | **51** | **2** |

"Covered in text" includes the rows a part placed otherwise than the triage said, recorded under
"Done otherwise than the triage says" (all verified in the document): new items instead of growing
one (F-TRN-6 → CR.139, F-REV-17 → CR.129, F-SES-6 → CR.130, F-SES-16 → CR.131, F-USG-3 → CR.141,
AR-47 → CR.134, F-TOD-9/-12/-20/-21/-24 → CR.113 … CR.117, F-QUE-14/-16 → CR.127, CR.128,
F-TOL-2 → CT.21, F-REV-11 → CT.20, F-SES-13 → CT.19); F-PRC-20 in CR.119; F-REV-24 in CT.1 only;
F-SES-21 by CR.138 (CT.7 points to it); F-QUE-11 as SC-35 `reused`; AR-63 as CS.26; AR-81's item
is N-45; V2-5 adds R-32. Parts of rows not written, with their reason in `changes.md`: AR-30 (no
CM.15: CM.9 already says it), F-QUE-32's "polling every 30 s" (not in the cited source), the
sub-questions of AR-39, AR-43, AR-48, AR-74 (ruled not asked), AR-14's and AR-22's questions
(`p1s1r5-8`). Asks confirmed in the question text: PQ-34 … PQ-37, PQ-39, PQ-40, PQ-43 … PQ-48,
PQ-50, PQ-51, PQ-53 … PQ-57, PQ-60 … PQ-66 exist in `new_questions.md`; PQ-38, PQ-49, PQ-52
stand in the Project Idea (kept). Every apply / settle row of the tables appears under a part's
"Rows applied" or "Open questions settled".

#### (b) Not handled

Both are rows of this todo (triage § 2.10), with no entry in `changes.md` yet and depending on the
`GLO` step running now; nothing else is missing.

| Id | What it is | Ruling | Where it belongs | What is missing | Proposed fix |
| --- | --- | --- | --- | --- | --- |
| AR-83 | S21 (the terminology document) kept equal to `GLO` | apply | `SRC` S21 / `_ai/quests/ai_runtime/ai_runtime_terminology.md` § 2 | Not verifiable while `GLO` is edited; no `changes.md` entry | After the `GLO` step: compare terminology § 2 with `GLO` term by term (incl. old extension, new extension, copy point, swap, review / round / review set / review folder, team runtimes, marker of a process step, night mode, aspect / choice), plain edit of the terminology document; record in `changes.md` under `p1s1r5-11` "Rows applied": "AR-83 → S21 equal to `GLO` (§ 1.6, D-73)" |
| V2-11 | Glossary entries old extension, new extension, copy point, swap; PQ-58 asks only whether the words are right | apply | `GLO`; PQ-58 (rewritten, by p1s1r5-11) | `GLO` entries: being written by the other step; **PQ-58 rewritten is in neither `new_questions.md` nor the document** | Check the four `GLO` entries once the step ends; write PQ-58 (rewritten) in `DEC` / its current place with the words of § 1.6 and Webwork's "group" (triage § 3), then record "V2-11 → `GLO` four entries; PQ-58 rewritten" in `changes.md` |

#### (c) B1 and retiring spot check

**B1** (10 random of 200): F-REV-7 (CV.16 cites `vscannot3`), F-TIM-4 (CT.1: S17 llm_tools § 4.20),
F-WSL-9 (CS.1: S17 user guide § 7), F-SES-15 (CR.27, CR.70: llm_configuration), F-SPC-11 (CT.10:
`vsc_nodart`, `vscimpb147`), F-TOD-14 (CR.50: `vscimpb152aa`), F-PRC-7 and F-PRC-6 (CR.10: S17
*Processes*, `vscimpb95`), F-SPC-12 (CT.10: `vscimpb189`, planned), F-SES-19 (CR.15: S17
*Two prompts never share a session*) — all 10 carry their citation as a marked change. Pass.

**Retiring** (all 5): F-QUE-42, F-QUE-43, F-TIM-6, F-TRN-10, F-MEM-5 are stated as not carried in
the new **O-11** (cites O-4, CR.19, CR.53, `01_aifmt-1`, `00_aifmt-3`), plus CR.19 (queue reminders)
and CR.53 (memory). Pass, with one wording discrepancy:

- O-11 says "and memory shared across **quests**"; the finding F-MEM-5 and CR.53 say the old
  extension's memory shared across **sessions** is removed (CR.53 separately: "no scope shared
  across quests"). Proposed fix, inside O-11's addition (`SCO > SCO-OUT`, anchor "queue reminders
  after a wait; and memory shared across quests."): replace "memory shared across quests" with
  "memory shared across sessions" — or, if both were removed by `00_aifmt-3`, "memory shared
  across sessions and across quests". Check `00_aifmt-3` before changing.

**After the check:** AR-83 and V2-11 are done (Rows applied above); nothing is left not handled.

### Questions written

- **PQ-58** rewritten (`GLO`): the words for the new extension and the words the document uses in
  several senses.
- **PQ-59** rewritten in the form check (round references brought to round 4 and five rounds).
- Corrected in the form check (quotes brought to the items' current text, a wording, a reference
  named by what it is): PQ-35, PQ-36, PQ-37, PQ-40, PQ-43, PQ-44, PQ-48, PQ-62, PQ-66; PQ-57
  (option (b) names N-33).

### Open questions settled

None.

### Rows dropped

None.

### Obligations changed

- **CT.11** names the open local second endpoint (PQ-50); it demands nothing new until PQ-50 is
  answered.
- **CR.5** ties the runtime's team review rounds to the layout of a review (CV.17); it adds no
  demand beyond CV.17.

### Sources needed

None.

### For other parts

None. For the next round: PQ-59 (structure) and the open questions decide what is rewritten;
`integration lease` and `standard run` get `GLO` entries only if PQ-46 (b) and PQ-63 (b) are
answered so.

## Closing check

Done by the round's second closing item on 2026-11-25, after all eleven todos were completed (the
first closing item had found `p1s1r5-11` unfinished and queued its continuation).

- **Marks:** 963 in the document (710 substitutions, 252 additions, 1 deletion); each closed, none
  nested, no blank line inside one. No reading-notation div is open or stray.
- **Ids:** the 709 items defined before the round (`project_idea.before_marks.md`, its marks
  accepted) are all still defined; 83 are new; none is defined twice. Every section-id chain
  resolves; no line outside a question block starts with `>`.
- **Questions:** 33 open, PQ-34 … PQ-66, each once; each has Context, Why I ask, two or more
  options with exactly one bold, a recommendation naming that option, an assumption and an empty
  answer. No settled or merged question is left.
- **Glossary:** `GLO` and terminology § 2 have the same 120 rows with the same text.
- **The in-place split:** named only as what D-73 replaced (S18's and S19's standing, the words
  not used, X-26, D-73 itself, PQ-60); nowhere as the plan.

Nothing was corrected.

## G1 reading

A reading, not a gate run: against gate run 2 (`../../quality/evidence/gates/G1_20261119-2045.gate.md`,
which read the document before rounds 3 to 5) and against round 4's reading
(`../01_04_Questions Round/changes.md` § G1 reading).

| Item | Run 2 | Round 4's reading | After this round |
| --- | --- | --- | --- |
| G1-DOC-1 | pass | unchanged | unchanged |
| G1-PROB-1 | pass | unchanged | unchanged |
| G1-USER-1 | pass | unchanged | unchanged; U-17 (the guest reviewer), U-8 and `USR` name the old and the new extension |
| G1-SCOPE-1 | pass | unchanged in kind | changed in content, still bounded: D-74 makes the extension's and Webwork's features the first version's scope; O-11 says what is not carried, L-13 … L-15 what is deferred; the new extension is in scope as the VS Code host (D-73) |
| G1-SRC-1 | pass | unchanged | unchanged; S28 … S31 added, every new item cites one |
| G1-ID-1 | pass | unchanged | unchanged: 83 new ids, none reused, none lost |
| G1-CLAR-1 | pass | fails (8 blocking) | **fails.** 33 questions are open. Ten block the Blueprint, because their working assumption is only "this is open" and the architecture builds on the answer: the eight of round 4 — **PQ-38**, **PQ-49** (the web runtime service, what faces the internet), **PQ-41** (the web runtime client SDK), **PQ-46** (the lease rules), **PQ-47** (a team on the GitHub backend), **PQ-51** (the team of a runtime that serves no quest), **PQ-53**, **PQ-54** (personal files; member branches, the internal repository, the secret scan) — and two new ones: **PQ-63** (the extension's own collaboration plan against tac) and **PQ-66** (how a review round travels over tac, member ids, blob lifetime — Webwork's core need). The other 23 have a working assumption the Blueprint can start from. |
| G1-RISK-1 | pass | changed | changed (below) |
| G1-CHANGE-1 | not applicable | unchanged | unchanged |

G1 has to be run again once the ten blocking questions are answered and taken in.

## Risk review

From `p1s1r5-10`'s record.

- **Changed:** R-1 (rewritten: two copies of one large code base), R-16 (the engine complete
  before it is copied; the rewiring of the copy), R-18 (`tom_todo_model` 6.0.0 and its consumers),
  R-19 (Webwork's messaging components beside the review component), R-28 (Webwork on hold until
  the specification exists).
- **New:** R-30 (an agent transport that needs another language runtime), R-31 (two engines on
  one `_ai` during the parallel period), R-32 (the swap).
- **Unchanged:** R-15, R-17, R-20, R-21, R-29, and R-2 … R-14, R-22 … R-27.

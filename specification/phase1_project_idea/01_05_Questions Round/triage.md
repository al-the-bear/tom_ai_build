# Triage — Phase 1, question round 5

Written by `p1s1r5-1` on 2026-11-25. It rules once, for the whole Project Idea
(`../project_idea.ai_runtime.md`), what is done with every finding of the three inventories of
this round and with every one of the 26 open questions PQ-34 … PQ-59, so that the parts
`p1s1r5-2` … `p1s1r5-11` apply the same words and do not decide the same thing twice. It changes
nothing in the Project Idea.

**How to use it.** Read § 1 (the cross-cutting rulings) completely, then your table in § 2. A row
names the finding (read it in its file), the items it concerns, and the ruling:

- **apply** — write it as a marked change; the sentence says what the text is to say and the
  source to cite in the shapes of `round_instructions.md` § Secondary prose;
- **ask** — the finding goes into a question; the row names the question and the part that writes
  it (a question appears in § 3 with every finding behind it);
- **settle** — an open question or choice that instruction (a) or (b) decides; the decision and
  the items it changes;
- **drop** — nothing is written, with the reason.

A citation in a row is shown in backticks only so it stands out here; in the Project Idea it is
written as plain text at the end of the clause, in the shapes of `round_instructions.md`.

**Finding ids.** The extension inventory's rows are `F-<area>-<n>`, its gaps are written
**`vx:G-<n>`** here (to keep them apart from the generation units `G-<n>` of `NFR-GEN`); the
quest inventory's are `AR-<n>` and `V2-<n>`; Webwork's comparison rows are written **`ww:R<n>`**
(apart from the risks `R-<n>`), its further needs (§ 3 of `inventory_webwork.md`, no ids there)
**`ww:N-<n>`** in the order of that table (25 rows; the round's iteration split counted 22), and
its questions **`ww:PQ-W<n>`**. The table rows of § 3 of the extension inventory ("distributed and
with a team") and its § 5 carry no ids; they are ruled as a whole in § 1.1 and § 1.3.

**A finding that touches two parts** stands once, in the part of its main item; the row ends with
**For p1s1r5-<n>:** and what that part adds. Each part therefore also searches the other tables
for its own todo id. Those mentions are not findings and are not counted.

## 1. Cross-cutting rulings

### 1.1 The baseline rule (instruction (a)) — D-74

**The decision.** Instruction (a) is written into `DEC` as **D-74** (product owner, 2026-11-25):
"The first version of the runtime has the features of the VS Code extension, built and planned,
of Webwork's plans for the runtime and tac (team review and review document bundles first), and
of this quest's queued todos and documents, carried across machines, between the members of a
team and over the internet. A feature of that baseline is in the first version unless a decision
puts it out of scope or later." It changes no earlier decision; `SCO > SCO-IN` gets a sentence
naming it, written by `p1s1r5-2`. Source for the citation: `(-> D-74)`; the instruction's words
are in `answers.md` (S31).

**How a baseline feature is written** (every part):

| State in the inventory | How the item reads | Citation |
| --- | --- | --- |
| **built** | what the runtime does, in the present tense ("The runtime keeps …") | `(<- S17 <doc> § <n>)` for documented behaviour, `(<- S23: <todo id>)` for behaviour a completed todo describes |
| **partly built** | what the runtime does, the planned rest named with its todo | `(<- S23: <done todo>; <open todo>, planned)` |
| **planned** | "is planned" or "planned:" with what it will do; never written as built | `(<- S23: <todo id>, planned)`; for a Webwork plan `(<- S25: <todo id>, planned)`; for this quest's own todos `(<- S30: <todo id>, planned)` |
| **retiring** (Copilot, queue reminders, the answer wrapper of timed requests, shared memory) | not carried: the item says the runtime does not have it, and why, in one clause; no description of the retiring feature beyond what O-4, CR.19, CR.53 already say | `(-> O-4)`, `(-> CR.19)`, `(-> CR.53)` with `(<- S23: 01_aifmt-1)` or `(<- S23: 00_aifmt-3)` |

- **A covered row** (the item already says it) needs no new content. Where the item has no source
  note, or an old-style one, the part adds or rewrites the citation in the shapes above. That is
  the ruling "apply B1" in the tables.
- **The "distributed and with a team" rows** (§ 3 of the extension inventory, no ids): a feature
  carried across machines or to a team is written as the items the inventory names there already
  state it (CW.19 … CW.23, CA.8 … CA.21, CP.17 … CP.23, CR.47, CR.79, CK.*). What § 3 marks
  *open* or *not covered* is ruled by a row below (timed request once: PQ-36; control items across
  machines: PQ-64; journals from other devices: CR.55's Blueprint note stands; continuing a session
  on another machine: F-SES-7; night mode per person: PQ-35; reminders once per person: F-TOD-16).
  Nothing else is added from § 3.
- **What instruction (a) does not decide:** where a feature acts (runtime or host), and what
  carrying it across machines needs, where the source gives no rule. Those are asked; the rows
  name the question.

### 1.2 Team review and review bundles for Webwork

Decided in the webwork quest on 2026-11-25 and therefore **applied**, not asked (S29):

1. **One review folder layout** (FQ-11 (a); vscode_extension `04c_woneb4`, planned; tom_specs
   `05c_woneb1`): `reviews/<review-name>/review.yaml` (documents, members, coordinator, rounds,
   what was sent), `round-<n>/outbound/base/`, `round-<n>/outbound/<member>/` (only where a member
   gets something different), `round-<n>/returned/<member>/`, `round-<n>/consolidated/` (merged
   documents and `merge-report.json`); the earlier round folder (`round.yaml`, base, one copy per
   member, `merged/`) is read and converted on first use. New item **CV.17** (`p1s1r5-7`), text as
   in `inventory_webwork.md` § 2.7, citations `(<- S29: FQ-11)` and `(<- S23: 04c_woneb4,
   planned)`. CV.5's last sentence and CV.13 follow it. The glossary's **round folder** (p1s1r5-11)
   becomes `round-<n>/` of a review, and a new entry **review folder** is `reviews/<name>/`.
2. **The round's state is read from the folder**: prepared, sent, returned, valid, consolidated;
   a file put in by hand counts like one that came through tac. New item **CV.18**
   (`p1s1r5-7`), `(<- S29: FQ-11; S25: 09_woneb3)`.
3. **tac is one of several channels** (FQ-9 (a)): besides tac, copies travel by export and import,
   by mail through the system's mail client, and by hand into the folder. **CV.11 is rewritten**
   (it says "Nobody carries files by hand"): "tac carries the documents of a review round out to
   the members and their copies back, for members who reach the round only through tac. A copy that
   arrives another way counts the same once it is in the round folder (CV.18)." CV.12's step "the
   copies are collected by the exchange" follows. This is an obligation change (`changes.md`).
4. **What a reviewer sees:** the review requests addressed to the user, open or returned, across
   conversations, and per member whether tac accepted the request for delivery: added to CP.36
   (`p1s1r5-4`), `(<- S25: 09_woneb2, 09_woneb3)`. "Whether the member has opened it" is **not**
   added: no Webwork source asks for it.
5. **Assists on documents under review** (Grill me, Explain in detail, proposed answers) are
   runtime features with their prompts: one new item beside CR.5 in `RT-HOLDS` (`p1s1r5-3`),
   `(<- S17 user guide *Assist prompts*; S25: 13_woneb5)`.
6. **Webwork's areas Review and Team Review** (FQ-5, FQ-8) are Webwork's own; nothing in the
   Project Idea.

**Asked** — one question, **PQ-66** (new, written by `p1s1r5-7`), merging Webwork's PQ-W1, PQ-W2
and PQ-W4: how a round's set of documents travels through tac (one archive per member, or one
blob per file listed in the request), how a review member id maps to a tac user, and how long a
round's blobs stay on the server (until merged, or at most 30 days with extension). The
recommendations are those of `inventory_webwork.md` § 4. **PQ-W3** (where the review and the
messaging components are built) is merged into **PQ-43** (rewritten by `p1s1r5-5`); **PQ-W5**
into **PQ-57** (rewritten by `p1s1r5-10`); **PQ-W6** into **PQ-37** (rewritten by `p1s1r5-3`).

**Not changed:** deadlines and reminders of a round (CM.2, CM.4, CV.12 step 4) stay; they are
backed by S1 although Webwork plans none (ww:R13).

### 1.3 The second extension (instruction (b)) — D-73

**The decision.** Instruction (b) is written into `DEC` as **D-73** by `p1s1r5-10` (text as
proposed in `inventory_ai_runtime_quest.md` V2-1, with "the new extension" and "the old extension"
as the words, § 1.6). D-73 **replaces D-41** (D-41 is marked replaced, one sentence: "Replaced by
D-73: a copy of the extension in `tom_ai/ai_build`, not a branch"). It also replaces RS-1's
recommended option: RS-1 (b) "a copied source folder as a second extension" is what the product
owner took, in `ai_build`. D-73 settles the scope of the new extension (V2-26): **the new
extension is in this product's scope as the VS Code host** — its host-interface implementation,
its rewiring to the runtime, its team views as far as PQ-62 decides — with its views carried over,
not redesigned. Which quest owns it after the swap is asked (PQ-60).

**What D-73 changes, item by item** (each in the part named):

| Item | Change | Part |
| --- | --- | --- |
| `SCO > SCO-IN`, row "The split" | becomes the row "The new VS Code extension": a copy of the extension in `tom_ai/ai_build`, rewired to the runtime as the VS Code host until every feature works as before, distributed and with a team; its taking the old one's place (-> D-73) | p1s1r5-2 |
| `SCO-OUT` O-1 | the extension's own views stay VS Code views; the new extension carries them over unchanged as the VS Code host's own (-> D-73) | p1s1r5-2 |
| `LAND` E-22 (and E-1 where it says the engine "becomes the runtime") | `vscode_extension` keeps the old extension, left as it is once the copy is taken; until then its engine keeps changing and format version 11 is done there | p1s1r5-2 |
| `RISK` R-1 | rewritten as "two copies of one large code base" (V2-5); new risk **R-31** "two engines on one `_ai` during the parallel period" (V2-5; R-30 is AR-54's) | p1s1r5-10 |
| `NFR` N-33 | "The work on the new extension changes nothing of the old one; the new extension is installable at every step, in a window or profile where the old one is not active" (V2-6); N-24, N-32 stay | p1s1r5-9 |
| `DEC` D-40 | the step that comes before the building is "the copy of the extension is taken after its features and the workspace layout are finished" — **when** is asked (PQ-61) | p1s1r5-10 |
| `DEL` "The stable extension during the split", "What comes before the building", the track table | rewritten as in V2-2, V2-3, V2-14; the open points name PQ-60 / PQ-61 | p1s1r5-10 |
| G-1, CP.14, T1, CT.8 | follow PQ-37 (merged: how the new extension reaches the runtime, V2-16); until answered they stay and carry the assumption of PQ-37 | p1s1r5-9, p1s1r5-4 |
| CU.10, CU.11 and the SC inventory | CU.10 adds: per screen, whether the new extension keeps it over the runtime, changes it or drops it; a screen not listed as changed or dropped is kept (V2-10) | p1s1r5-5 |
| The `ww_b_workbench-*` and `ww_d_workbench-*` plan | not in the Project Idea; `DEL`'s list "what replaces which todo" names them as replanned against the copy (V2-12, V2-13) | p1s1r5-10 |
| D-1, CL.3 (place of the runtime and the Dart runtime client SDK) | **settled, unchanged**: `tom_ai/ai_build` (D-1); D-73 puts the new extension there too. The answer in this quest's todo `ww_e_runtimeapi-1` ("the runtime shall go into the vscode repository, too") is superseded; `CON` gets one entry (V2-21, AR-70) | p1s1r5-10 |

**What becomes a question** (V2-15 … V2-29, merged):

| Question | Topic | Findings | Part |
| --- | --- | --- | --- |
| **PQ-60** (new) | identity while both are installed (own id, same contribution ids, never active in one window), the swap (place, name, version 2.0.0), what retiring archives and when, which quest owns the new extension after the swap | V2-15, V2-20, V2-22, V2-26 (ownership), V2-28 | p1s1r5-10 |
| **PQ-61** (new) | the copy point (after format 11, quest management and the Copilot removal, from a tag, without history), what the old extension still gets meanwhile (fixes only, repeated in the copy), which of the open extension todos land before the copy, and when the Dart scripting API is split | V2-19, V2-25, AR-77; the D-40 backlog question of `inventory_vscode_extension.md` § 5 | p1s1r5-10 |
| **PQ-62** (new) | what "every feature as before" leaves out or adds: the VS Code LM and Copilot transports against D-7 and O-4, today's per-quest Telegram, the script server and its ports, the team views the new extension gets | V2-9, V2-24, V2-27, V2-29, AR-5, AR-21, vx:G-4, F-ASK-21 … F-ASK-23 | p1s1r5-2 |
| **PQ-37** (rewritten) | how every host gets and starts the runtime: Node, the Agent-SDK-only mode, who installs (Webwork's installer), and whether the new extension runs the runtime in its own process or starts it as a process | V2-8, V2-16, AR-8, ww:PQ-W6, ww:N-23 | p1s1r5-3 |
| **PQ-40** (rewritten) | the `_ai` format while the old engine and the runtime both work on one machine, together with when a migration runs | V2-18 | p1s1r5-4 |
| **PQ-36** (rewritten) | two hosts on one quest, now including the old extension's engine and a runtime on one quest during the parallel period, and where queue entries live | V2-17, AR-9, F-QUE-31, vx:G-16 (queue storage) | p1s1r5-3 |
| **PQ-57** (rewritten) | what "finished" is checked against, now including the acceptance of the new extension against the old one | V2-23, AR-7, AR-46, AR-33, ww:PQ-W5 | p1s1r5-10 |
| **PQ-58** (rewritten) | the words: old / new extension, copy point, swap | V2-11 | p1s1r5-11 |

### 1.4 The extension's own collaboration plan against tac — one question

The extension's quest planned on 2026-11-24 its own collaboration model (`collab_and_features`,
76 `caf_*` todos, S28): lease tables as git refs per repository (stale after 30 minutes), the
notation `<type>://<server>/<path>`, branches `todo/<id>` and worktrees `<folder>@<branch>`, a
merge tool, agent groups with a supervisor run, features (group todos in phases) with feature runs
and Wait / Notify items, standard runs `planning` and `quest-keeper`, review todos, an issue flow.
The Project Idea has tac leases (60 minutes, fencing tokens, `git:` names, D-68), worktree mode and
an integration step (D-55), and no agent groups (D-24). Instruction (a) makes planned extension
features part of the baseline, so the conflict must be decided. **One question, PQ-63** (new,
written by `p1s1r5-6`), with the options of `inventory_vscode_extension.md` vx:G-1 and
`inventory_ai_runtime_quest.md` AR-27 combined:

- (a) carry the plan into the runtime as it is (git-ref lease tables as one more tac backend, its
  notation replacing D-68's, agent groups as runtime items, which reopens D-24);
- **(b)** take over its run and feature concepts (features, standard runs, review todos, the issue
  flow, Wait / Notify) as runtime capabilities, and keep tac for leases, branches and the
  integration step (CA, CW); no agent groups (D-24): a supervisor and collaborators become asks
  and messages routed between runs; one resource notation, settled in PQ-45;
- (c) none in the first version: the plan stays the extension's, recorded as input (S28).

Recommendation (b). The notation itself is asked in **PQ-45** (rewritten by `p1s1r5-6`, adding
the extension's `<type>://` notation as an option); the issue flow question of vx:G-14 is part of
PQ-63; the system aspects of `caf_05e` / `caf_06d` follow PQ-63. Until answered, no `caf_*`
feature is written as a runtime item, and `CON` gets one entry **X-22** "the extension's
collaboration plan (S28) against tac's leases, notation and D-24" (`p1s1r5-10`).

### 1.5 The 26 open questions

| Question | Ruling | What changes | Writes it |
| --- | --- | --- | --- |
| **PQ-34** who writes `_ai` files besides the runtime | **rewrite** | add as named writers the old extension's own engine during the parallel period (D-73) and `tom_todo_model` 6.0.0 (its consumers moving, `vscimpb180`); the options stay; stand on its own | p1s1r5-3 |
| **PQ-35** four extension features: runtime's or host's | **rewrite** | add what instruction (a) changes: every one of the four is a baseline feature (built); carried across machines the quest refresh must run once per quest (who counts, vx:G-5), the stored prompt and the process-item mark, the "window" level of aspect choices and night mode switched for a person's runtimes (vx:G-3), `prerequisites.yaml` checked on each member's machine | p1s1r5-3 |
| **PQ-36** two hosts on one quest | **rewrite** | add the old extension's engine and a runtime on one quest during the parallel period (V2-17, AR-9), a timed request firing once, where queue entries live (`_ai/queue/` today, against CR.106; F-QUE-31, vx:G-16) | p1s1r5-3 |
| **PQ-37** Node, Agent-SDK-only mode | **rewrite** | merge Webwork's installer (ww:PQ-W6, `tom_tool_installer`, FQ-3) and the new extension's in-process or process choice (V2-16, V2-8: G-1, CP.14, T1) | p1s1r5-3 |
| **PQ-38** the web runtime service | **keep** | Webwork adds nothing (phone and web later, `13_woneb10`) | — |
| **PQ-39** leases and chat sends while a run waits | **settle in part, rewrite** | the chat-send half is settled by D-74: a chat send in another session of the waiting run goes out, as built (F-QUE-34; `(<- S23: vscimpb132, vscimpb135)`); CP.21 and CR.67 say so (p1s1r5-4 and p1s1r5-3). The question keeps only the leases (options (a), (c), (d) and "kept, with the ask's age shown"), with the extension's planned "Proceed anyway" (`caf_04b`) in the context | p1s1r5-4 |
| **PQ-40** when a migration runs | **rewrite** | merge V2-18: while the old engine and the runtime both work on one machine, which format version they use and when it may change; the extension's plan for version 11 (`01_aifmt-5`, planned: runs by itself) is the baseline fact the question weighs against CP.33 | p1s1r5-4 |
| **PQ-41** the web runtime client SDK | **keep** | — | — |
| **PQ-42** TypeScript and JavaScript | **keep** | — | — |
| **PQ-43** where the review component is built | **rewrite** | merge ww:PQ-W3: the messaging components too (`tom_messaging_ui` in `tom_modules`, C21, Q-8 (a)), the navigation contract (OR-19, OR-20), and the extension's page features that a component must carry (reading notation, rejected blocks, track changes, guarded editing; F-REV-2 … F-REV-23) | p1s1r5-5 |
| **PQ-44** the Flutter view packages beside the new components | **rewrite** | add Webwork's inconsistency (component placement C22 lists the AI run tabs as `tom_agentic_ui` / `tom_ai_trail_ui`, while `13_woneb2` takes them from `tom_ai_runtime_ui`) and that Webwork's 1b1 keeps them until 1b2 | p1s1r5-5 |
| **PQ-45** how resources are written | **rewrite** | add the extension's planned notation `<type>://<server>[:<port>]/<path>` (`caf_01a`, F-TOD-34) as an option; PQ-63 decides the rest of that plan | p1s1r5-6 |
| **PQ-46** lease rules, fencing at the push | **rewrite** | add the extension's lease table as git refs with compare-and-swap and 30 minutes (`caf_04a`, F-COL-4) as the competing model, and S6's `Tac-Fence` commit trailer as an option for the token check (AR-22) | p1s1r5-6 |
| **PQ-47** a team on the GitHub backend | **rewrite** | add that S5 already fixes presence and time on GitHub (committer time, 60 minutes; AR-19) and the extension's per-repository git-ref tables (S28) as an alternative to one coordination repository | p1s1r5-6 |
| **PQ-48** "coordination off" and the local tac service | **rewrite** | add that machine-wide state is the runtime's and routed through the local tac service (D-13; CR.36 … CR.39), and that the built service is started by the extension as a detached child (`ensureLocalService()`, AR-13) | p1s1r5-6 |
| **PQ-49** phones and tablets | **keep** | Webwork plans no push service and phones in a later wave (DPPHONE-4, DPPHONE-5); the options already cover it | — |
| **PQ-50** remote control and tac's credentials | **rewrite** | merge vx:G-13: today's MCP server serves file and host tools behind a key, with a read-only floor and a loopback / VPN peer rule (F-TOL-6) — does a local-only second endpoint remain; and S6's restriction of the remote-control endpoint to the machine (AR-17) | p1s1r5-7 |
| **PQ-51** a runtime that serves no quest | **keep** | add nothing; Webwork's endpoint of its own (WW-8, `qavs_collab_b-1`) and note d of S4 (AR-79) are already inside "may claim leases … publish"; p1s1r5-7 may add one context sentence without changing the options | — |
| **PQ-52** cache and outbox of messaging | **keep** | — | — |
| **PQ-53** where a person's own files of a quest lie | **rewrite** | state as baseline fact that the extension plans the host's files per host in the quest (`01_aifmt-4`, planned; F-SES-16), which is option (a) and S22; add AR-59's option (d) `_ai/personal/<id>/` from this quest's `ww_e_gitruntime-1`; ask only what remains (any personal place at all, the personal notes) | p1s1r5-8 |
| **PQ-54** member branches, internal repository, secret scan, member access | **rewrite** | add that these are this quest's queued todos (`ww_e_gitruntime-3` … `-7`, S30) and what instruction (a) says of them; add the publish offer and ahead / behind display (AR-61), the KDBX credentials over `tom_kdbx_store` / `tom_kpasslib` (never `tom_kdbx`, AR-63), member identity at the repository server (AR-65), the two-member pilot (AR-69) | p1s1r5-8 |
| **PQ-55** who carries the quest operations | **rewrite** | merge vx:G-9: setting up a workspace from the template the VSIX carries (three forms), creating a quest with its setup todo and short description; the extension plans the QUEST MANAGEMENT panel (`02_aifmt-1`, planned) — the baseline names the operations, the question is where they live | p1s1r5-8 |
| **PQ-56** numbers no source gives | **rewrite** | drop from the list what the baseline fixes as built (watchdog 60 s and polling 30 s, F-QUE-32; a chat send stopped after the response timeout, 60 min by default, F-QUE-33): written as built by p1s1r5-9 / p1s1r5-3; add what Webwork needs and no source gives: the blob size a review bundle with images needs (`inventory_webwork.md` § 2.5) | p1s1r5-9 |
| **PQ-57** what "finished" is checked against | **rewrite** | merge ww:PQ-W5 (a second thin path: a team review between two desktops through a tac server), V2-23 (the new extension accepted against the old one: its suites, the conformance test against files the old one wrote, the feature inventory checked off), AR-46 (one queue item on each way in), AR-33 (Webwork's end-to-end check) | p1s1r5-10 |
| **PQ-58** words used in several senses | **rewrite** | add the words of D-73 (old extension, new extension, copy point, swap; V2-11) and Webwork's "group" for a team (DPAREAS-7) | p1s1r5-11 |
| **PQ-59** the structure of the Project Idea | **keep** | — (it stays where it is; p1s1r5-11 puts the final set in) | — |

No open question is merged away or settled whole: 7 are kept, 18 rewritten, 1 settled in part and
rewritten (PQ-39).

### 1.6 Names used by several parts

| Thing | Write it as | Not |
| --- | --- | --- |
| the extension as it is today | **the old extension** (`tom_ai/vscode/tom_vscode_extension`), "the VS Code extension" where nothing of D-73 is meant | "v1", "the stable extension" |
| the copy in `ai_build` | **the new extension** (D-73); its folder `tom_ai/ai_build/<folder>` is not named yet (PQ-60) | "the second extension" except when quoting, "v2" except in the product owner's words and in PQ-60's version option |
| the moment of copying / of taking the old one's place | **the copy point** / **the swap** | "the split" (that word now names nothing; where an item says "the split" it is rewritten) |
| the runtime | `tom_ai/ai_build/tom_ai_runtime` (D-1), in the repository **`tom_ai_build`** | `tom_quest_runtime`, `@tom/quest-runtime`, "in tom_vscode" |
| the todo model | `tom_todo_model` **6.0.0** (`tom_ai/modules/tom_todo_model/pubspec.yaml`, 2026-11-25); E-2 and R-18 say 4.2.0 and are corrected (p1s1r5-2, p1s1r5-10) | 4.2.0, ^2.2.0 |
| the Dart scripting API | `tom_vscode_scripting_api` **7.0.0** | 5.0.0 |
| Telegram | **deferred** for the runtime (D-6, L-9); the old extension keeps its per-quest Telegram; whether the new extension does is PQ-62 | "Telegram routing for every runtime" |
| a Webwork review | **review** (folder `reviews/<name>/`), **round** (`round-<n>/`), **review set** (what `review.yaml` names), **coordinator**, **reviewer**, **guest** | "round folder" for the whole review |
| Webwork's "group" in DPAREAS-7 | **team**; its members' runtimes are the **team runtimes** | "group" for people, "agent group" (D-24: no agent group of its own) |
| sources | S28 … S31 as § 4 proposes, cited only after p1s1r5-2 has added them; until then a part writes the citation with the proposed id | — |

## 2. The work list per part


### 2.1 `p1s1r5-2` — `ABOUT`, `SRC`, `VIS`, `USR`, `SCO`, `LAND`

Besides the rows: D-74 and D-73 in `SCO > SCO-IN` (§ 1.1, § 1.3); the sources of § 4 into `SRC`; S17, S23, S25 dated 2026-11-25; S7, S18, S19 standings; writes **PQ-62** (new).


**Covered extension rows — apply B1** (§ 1.1: no new content; add or rewrite the citation from the row's source column; a planned row reads "planned" with its todo):

- 2.1 quests: F-QST-12, F-QST-13
- 2.8 transports: F-TRN-9
- 2.9 prompt assembly: F-PRM-22
- 2.18 other: F-OTH-3, F-OTH-9, F-OTH-11, F-OTH-13, F-OTH-14

**Retiring extension rows — apply the retiring rule** (§ 1.1: not carried, one clause, cite O-4 / CR.19 / CR.53 and the removing todo): F-QUE-42, F-TIM-6, F-TRN-10

| Finding | Concerns | Ruling | What |
| --- | --- | --- | --- |
| F-ASK-21 | differs: L-9, D-6 (deferred) | **ask** | PQ-62 (today's per-quest Telegram in the new extension) |
| F-ASK-22 | differs: L-9 | **ask** | PQ-62 |
| F-ASK-23 | differs: L-9 (an ask leaves the host only through tac, CP.18) | **ask** | PQ-62 |
| vx:G-4 | `DEC` PQ-62, D-6 | **ask** | PQ-62 (Telegram in the new extension; D-6 stands for the runtime) |
| ww:N-22 | `LAND-BUILT` E-2, R-18 | **apply** | E-2: `tom_todo_model` 6.0.0 (§ 1.6). **For p1s1r5-10:** R-18 the same |
| AR-5 | `SCO-OUT` PQ-62, O-4 | **ask** | PQ-62 (which extension keeps the VS Code LM transport, O-4) |
| AR-12 | D-73 | **apply** | S19's standing: "its § 7 stages are replaced by D-73" |
| AR-15 |  | **drop** | a todo matter (cancel `ww_a_collab-2b`); the version is § 1.6 |
| AR-21 | `DEC` PQ-62, D-6 | **ask** | PQ-62 (D-6 stands for the runtime; the old extension's per-quest Telegram in the new one is asked) |
| AR-26 | L-13 | **apply** | new `SCO-LATER` row **L-13**: a gateway for outside agents that speak A2A `(<- S9; S30: a2a1)` |
| AR-28 | `SCO-LATER` L-12, X-3 | **apply** | L-12's reason: "possible; to be investigated for messaging and other light parts (X-3), not planned for the first version" `(<- S30: tac_webwork-1)` |
| AR-51 |  | **apply** | `SCO-LATER` row: tools a provider runs on its own servers `(<- S30: xxxai1)` |
| AR-58 |  | **apply** | S7's standing: "predates the provider decisions of this quest's `xx*` todos (S30), which win" |
| AR-80 |  | **apply** | S2's row and `ABOUT-READ`: "FO-1 … FO-22, without FO-14 (not assigned)" |
| V2-4 | `SCO-OUT` O-1 | **apply** | `SCO-IN` row and O-1 as § 1.3 |
| V2-7 | `LAND-WAIT` E-22, E-1 | **apply** | E-22 (and E-1) as § 1.3 |
| V2-9 | PQ-62 | **ask** | PQ-62 |
| V2-24 | PQ-62 | **ask** | PQ-62 (new) |
| V2-26 | `SCO-OUT` D-73, O-1, PQ-60 | **settle** | by D-73: in scope as the VS Code host, views carried over (O-1); ownership after the swap goes into PQ-60 |
| V2-27 | PQ-62 | **ask** | PQ-62 |
| V2-29 | PQ-62 | **ask** | PQ-62 |


### 2.2 `p1s1r5-3` — `RT-HOLDS` … `RT-INSTALL`

Besides the rows: writes PQ-34, PQ-35, PQ-36, PQ-37 (rewritten) and **PQ-64**, **PQ-65** (new); aligns CR.15 and CR.67 with PQ-39's settled chat half (F-QUE-34).


**Covered extension rows — apply B1** (§ 1.1: no new content; add or rewrite the citation from the row's source column; a planned row reads "planned" with its todo):

- 2.1 quests: F-QST-1, F-QST-2, F-QST-4, F-QST-5, F-QST-9, F-QST-10, F-QST-11, F-QST-14, F-QST-15
- 2.2 workspace: F-WSL-1, F-WSL-2, F-WSL-5, F-WSL-9, F-WSL-10, F-WSL-11, F-WSL-12, F-WSL-13
- 2.3 todos: F-TOD-1, F-TOD-2, F-TOD-3, F-TOD-4, F-TOD-5, F-TOD-6, F-TOD-7, F-TOD-10, F-TOD-11, F-TOD-13, F-TOD-14, F-TOD-15, F-TOD-17, F-TOD-18, F-TOD-19, F-TOD-28, F-TOD-29, F-TOD-35
- 2.4 processes: F-PRC-1, F-PRC-3, F-PRC-6, F-PRC-7, F-PRC-8, F-PRC-9, F-PRC-10, F-PRC-11, F-PRC-12, F-PRC-15, F-PRC-16, F-PRC-17, F-PRC-18, F-PRC-21, F-PRC-23
- 2.5 queue: F-QUE-1, F-QUE-2, F-QUE-3, F-QUE-5, F-QUE-6, F-QUE-7, F-QUE-8, F-QUE-9, F-QUE-10, F-QUE-12, F-QUE-13, F-QUE-17, F-QUE-18, F-QUE-19, F-QUE-20, F-QUE-21, F-QUE-22, F-QUE-23, F-QUE-24, F-QUE-25, F-QUE-26, F-QUE-27
- 2.6 timed requests: F-TIM-1, F-TIM-3, F-TIM-7
- 2.7 sessions: F-SES-1, F-SES-2, F-SES-3, F-SES-4, F-SES-5, F-SES-8, F-SES-9, F-SES-10, F-SES-11, F-SES-15, F-SES-19
- 2.8 transports: F-TRN-1, F-TRN-2, F-TRN-7, F-TRN-8, F-TRN-13, F-TRN-14, F-TRN-15, F-TRN-16
- 2.9 prompt assembly: F-PRM-1, F-PRM-2, F-PRM-5, F-PRM-7, F-PRM-9, F-PRM-21
- 2.10 tools: F-TOL-10, F-TOL-11
- 2.11 asks: F-ASK-16, F-ASK-18, F-ASK-19
- 2.12 reviews: F-REV-14
- 2.13 TomSpecs: F-SPC-6
- 2.14 memory: F-MEM-1, F-MEM-2, F-MEM-3, F-MEM-6
- 2.15 usage: F-USG-1
- 2.18 other: F-OTH-4, F-OTH-12

**Retiring extension rows — apply the retiring rule** (§ 1.1: not carried, one clause, cite O-4 / CR.19 / CR.53 and the removing todo): F-QUE-43, F-MEM-5

| Finding | Concerns | Ruling | What |
| --- | --- | --- | --- |
| F-QST-7 | not covered (open question PQ-35) | **ask** | PQ-35 (rewritten: who counts the prompts of a quest refresh across hosts and machines) |
| F-QST-8 | partly: CR.55 (only "a rendering of the decisions of its archived todos"; the process-move | **apply** | CR.55: the decisions journal also records every process move that is not a plain step (jumps, resets, follow-up switches, aborted levels, left-out steps). `(<- S17 user guide *Processes*)` |
| F-WSL-8 | partly: CR.102, CP.27 | **apply** | CR.102: the workspace query names the build running and installed (reload needed) and the Dart binaries beside projects, layout, workspace folders, quests and repositories. `(<- S17 llm_tools § 10)`. **For p1s1r5-4:** CP.27 unchanged |
| F-TOD-9 | partly: CW.21 (the rule, not the repair command) | **apply** | CR.48 (vx:G-10): a command repairs the dependencies of a set of todos in one pass (done and vanished blockers removed, unblocked, `blocking` set). `(<- S17 user guide *Todos that block others*)` |
| F-TOD-12 | partly: CR.48 (the answer of the execution; reading the trails for `TODO=<ref>` is not nam | **apply** | CR.48: the answer of the walk that completed a todo is kept with it, and the newest answer in the quest's trails that reported it (`TODO=<ref>`) can be read. `(<- S17 user guide *Todo iteration*)` |
| F-TOD-16 | not covered (CR.50 names neither) | **apply** | CR.50: planned: a repeated todo's next occurrence takes its due date and reminders with it; a reminder can be snoozed; reminders ring once per person (§ 3 of the extension inventory). `(<- S23: wwremind2, planned)` |
| F-TOD-20 | partly: CR.55 (the journal); the archive and delete rules are not stated | **apply** | CR.48 / CR.55 (vx:G-10): a completed todo is archived into a sibling file, one that was not completed is deleted into another, both recoverable; archiving copies its decisions into the journal. `(<- S17 user guide *Quest TODO Panel*)` |
| F-TOD-21 | not covered (CW.25 covers creating a todo in another quest only) | **apply** | CR.48 (vx:G-10): todos move between files, groups, quests and the workspace's todo file, renumbered into the target group. `(<- S17 llm_tools § 4.11)` |
| F-TOD-22 | partly: SC-9 (the view); the store is not in CR.2 | **apply** | CR.2: the workspace's own todo file `workspace.todo.yaml` is one of the stores. `(<- S17 user guide)` |
| F-TOD-24 | not covered | **apply** | CR.48 (vx:G-10): todo ids are made from a date code by a tool and checked against the schema's id pattern; a reused stem is warned about. `(<- S17 llm_tools)` |
| F-TOD-33 | not covered | **apply** | new item in `RT-HOLDS` beside CR.48: planned: a query returns a set of todos' dependency closure across quests and the queued items of every runtime that work on them. `(<- S23: todoanalyzer1 … todoanalyzer4, planned)`. **For p1s1r5-5:** the views DEPENDENCIES and WORK ORDER as screen rows |
| F-PRC-5 | partly: CP.3 (proceed); the marker as a queue pseudo-item is not named | **apply** | CR.10 / `RT-QUEUE` (vx:G-11): a process step is executed by queueing its prompt and a marker; the process moves when its lane reaches the marker with the step's items done; a failed item holds the marker. `(<- S17 user guide *Proceed*)` |
| F-PRC-13 | partly: SC-7 (the editor); the template is not an engine item | **apply** | CS.3 / CR.2 (vx:G-15): the prompt that executes a position is built from a template the workspace can edit. `(<- S17 user guide *Process template editor*)` |
| F-PRC-14 | partly: CR.5 (prompt assembly), CR.63 | **apply** | CR.5 / CR.63: the process context goes into the system prompt and the process's values are chat variables. `(<- S17 placeholder_engine.md)` |
| F-PRC-19 | not covered | **apply** | CR.10 or the step item it belongs to: planned: a step's documents can come from a chat variable holding several paths. `(<- S23: vscimpb163, planned)` |
| F-QUE-4 | partly: CR.27 (one retry layer); CR.69 lists none of these states | **apply** | CR.69 (vx:G-8): add the states "waiting for a rate limit or a quota until a time" and "retrying (n of m)", with Retry now and Retry all errors. `(<- S17 user guide *Queue*)` |
| F-QUE-14 | not covered | **apply** | new item in `RT-QUEUE` (vx:G-8): a run's settings can become the start values of new runs; a run's defaults can be applied to its waiting items; an item can follow its run's defaults, taken when it is sent. `(<- S23: the queue todos completed 2026-11-23 … 24)` |
| F-QUE-15 | partly: CP.3, CR.74 | **apply** | CR.74: the commands on items include Send now (also again for a sent item), Send all staged, Clear sent / all, Delete errors, Restart, Stop. `(<- S17 user guide *Queue*)`. **For p1s1r5-4:** CP.3 names them as commands |
| F-QUE-16 | partly: CR.74 (commands on an executing item); moving between runs is not covered | **apply** | same item as F-QUE-14: any item not sent can be moved to another run, session and place; an executing one is stopped first; its status can be set by hand. `(<- S23: 2026-11-25)` |
| F-QUE-29 | not covered (PQ-35) | **ask** | PQ-35 (the process-item mark, with the quest refresh) |
| F-QUE-30 | not covered (PQ-35) | **ask** | PQ-35 (the stored prompt after a restart) |
| F-QUE-31 | partly: CR.36 (settings); where queue entries live is not stated (CR.106 keeps machine-wid | **ask** | PQ-36 (rewritten: where queue entries live, against CR.106) |
| F-QUE-33 | not covered | **apply** | `RT-QUEUE` item: a chat send that gets no result within the queue's response time (60 minutes by default) is stopped. `(<- S17 user guide)` |
| F-QUE-35 | partly: CW.13 ("a runtime can be asked to pause its queue after its current item") | **ask** | PQ-64 (control items across machines and people) |
| F-QUE-36 | not covered | **ask** | PQ-64 |
| F-QUE-37 | not covered | **ask** | PQ-64 (wait and notify items) |
| F-TIM-2 | not covered | **apply** | `RT-QUEUE` item on timed requests: global schedule slots (weekdays, a time-of-day window, months). `(<- S17 user guide *Timed requests*)` |
| F-SES-6 | partly: CR.75 | **apply** | CR.75: a session named by an item is created at its first dispatch from the item's spec (name, base, lifetime, profile). `(<- S17 user guide *Sessions*)` |
| F-SES-7 | not covered | **apply** | new item (vx:G-12): when an agent transport no longer has a session's conversation (another machine, a cleared store), the runtime starts a new conversation in the same session once and says so in the trail. `(<- S17 user guide)` |
| F-SES-12 | not covered (CT.7 names only the tool set of a prompt) | **apply** | CR.24 (vx:G-12): the trail records each prompt as typed, as sent, and its system prompt. `(<- S17 user guide)` |
| F-SES-14 | not covered | **apply** | new item (vx:G-12): history and memory can be rebuilt from a session's trail; a compaction can be tried without writing. `(<- S17 user guide)` |
| F-SES-16 | CR.79, CR.47; differs: CQ.3 (personal repository); open: PQ-53 | **apply** | CR.47 / CR.79: planned: sessions, the compact trail and the questions journal per host in the quest (`history/<host>/…`), written as planned `(<- S23: 01_aifmt-4, planned)`; this is the baseline fact PQ-53 is rewritten around (p1s1r5-8) |
| F-SES-18 | partly: CR.24 ("every prompt can be addressed in the trail") | **apply** | CR.24: prompt and answer pairs can be listed and read across sessions. `(<- S17 llm_tools)` |
| F-TRN-3 | not covered | **apply** | CR.27 (vx:G-6): a core set of tools sent in full and the others deferred behind the provider's tool search; tools named by a prompt or its template. `(<- S17 anthropic_handler)` |
| F-TRN-4 | not covered | **apply** | CR.27: server-side clearing of old tool results on the direct transport. `(<- S17 anthropic_handler)` |
| F-TRN-5 | not covered | **apply** | CR.27: images and documents as content to the model. `(<- S17 llm_tools)` |
| F-TRN-6 | partly: CR.25 ("approvals"), CP.8 (tool approval as an ask) | **apply** | CR.25: the approval modes (always, accept edits, allow a tool for the session; readers never ask; queued prompts never ask). `(<- S17 user guide)`. **For p1s1r5-4:** CP.8 refers to them |
| F-TRN-18 | not covered | **apply** | `RT-TRANSPORTS`: the real cause of an agent transport's failure (an expired sign-in and the like) is reported. `(<- S23)` |
| F-PRM-3 | partly: CS.3 | **apply** | CS.3 (vx:G-15): templates of every category: profile system prompts, compaction, memory extraction, transport retry, interactive questions, assist prompts; reminder templates leave (-> CR.19). `(<- S17 anthropic_handler § 5)` |
| F-PRM-4 | partly: CP.38, CR.88, CR.92 | **apply** | CR.88 / CR.92 and the new review-assist item of § 1.2 point 5: the assist prompts are a template category chosen per use (grill me, explain in detail, explain a decision, finish review round, gate decision, out of budget, background-work reminder). `(<- S17 user guide *Assist prompts*)`. **For p1s1r5-4:** CP.38 |
| F-PRM-6 | not covered | **apply** | CS.3 / CR.2 (vx:G-15): group prompts (a global default and additions, a quest's own) are a template store the queue reads. `(<- S17 user guide *Group prompt editor*)` |
| F-PRM-11 | partly: CR.61 (calls them sections with options) | **apply** | CR.61 (vx:G-3): the aspect guidelines (aspects with choices, each its own text or a guideline file looked up over the root and the workspace folders). `(<- S24; S23: gsel4 … gsel10)` |
| F-PRM-12 | differs: CR.61 (one option per section; no workspace level; window open in PQ-35) | **apply** | CR.61 (vx:G-3): the levels as built, several choices per aspect, each level replacing, adding or removing; "choosing per level is planned" goes (vx:G-17). The "window" level is written "the host's choice for this runtime" with PQ-35's assumption |
| F-PRM-13 | not covered | **apply** | CR.61 (vx:G-3): a choice or an aspect can carry a condition over chat variables and facts of the prompt. `(<- S23: gsel…)` |
| F-PRM-14 | not covered | **apply** | CR.61 (vx:G-3): the workspace level as files with `@<path>` imports. `(<- S23: gsel…)` |
| F-PRM-15 | not covered | **drop** | content of the workspace (which texts the aspects hold), not a capability; CR.61's choices being texts or files covers it |
| F-PRM-16 | not covered | **apply** | new item beside CR.61 (vx:G-3): night mode is an aspect sent while a variable is on; the agent then asks nobody and records each decision as an answered question. Who switches it, for which runtimes, is in PQ-35. `(<- S23: 2026-11-25)` |
| F-PRM-17 | not covered | **drop** | content (an aspect's text), not a capability |
| F-PRM-20 | not covered | **drop** | deferred in the extension's quest (`later2`), not planned for the baseline |
| F-ASK-11 | differs: CR.55 (`qa.<host>.<q>.md` per host, `01_aifmt-4`) | **ask** | PQ-65 (the store of questions and answers: per host or one file per entry) |
| F-ASK-12 | not covered | **ask** | PQ-65 |
| F-ASK-13 | partly: CP.8 (allowed responses) | **ask** | PQ-65 |
| F-REV-17 | partly: CR.17 (review each result) | **apply** | CR.17: an agent's changes to a document can be reviewed in a document view, accepted or rejected per change. `(<- S17 user guide)` |
| F-USG-3 | not covered | **apply** | CR.105: planned: the tool definitions each role type sends per turn are measured. `(<- S23: tooloptimize15, planned)` |
| F-PRE-1 | open: PQ-35; SC-25 | **ask** | PQ-35 (`prerequisites.yaml` on each member's machine) |
| F-OTH-15 | not covered | **apply** | CR.48 / CR.24: response values (`TODO=<ref>` and the like) an answer reports are read from the trail. `(<- S17 user guide)`; the Copilot answer-file part leaves (-> O-4) |
| vx:G-2 | PQ-64 | **ask** | PQ-64 (new): control items and wait / notify items across machines and people; the proposed `RT-QUEUE` item is its recommended option |
| vx:G-3 | `RT-HOLDS` CR.61, PQ-35 | **apply** | CR.61 rewritten with the proposed text (aspects, several choices, replace / add / remove, conditions, workspace level); the "window" level with PQ-35's assumption; night mode as F-PRM-16 |
| vx:G-5 | PQ-35 | **ask** | PQ-35 (rewritten) |
| vx:G-6 | `RT-TRANSPORTS` CR.27 | **apply** | CR.27 extended as proposed (F-TRN-3 … F-TRN-6). **For p1s1r5-4:** the stored tool results item (F-SES-13) and the core tool set (F-TOL-2) |
| vx:G-7 | PQ-65 | **ask** | PQ-65 (new): the store of asks and answers (per host `01_aifmt-4` or one file per entry `vscimpb183`) and whether answers and asks carry question blocks and prompts in the ask envelope |
| vx:G-8 | `RT-QUEUE` CR.69 | **apply** | the proposed `RT-QUEUE` item (F-QUE-14, F-QUE-16) and CR.69's states (F-QUE-4) |
| vx:G-10 | `RT-HOLDS` CR.48, CR.51 | **apply** | the proposed additions to CR.48 … CR.51 (F-TOD-9, -16, -20, -21, -24, -33) |
| vx:G-11 | `RT-HOLDS` CR.55 | **apply** | the proposed process items (F-PRC-5, -13, -19, -20) and CR.55's process-move records (F-QST-8) |
| vx:G-12 |  | **apply** | the proposed session and trail items (F-SES-7, -12, -14, -21) |
| vx:G-15 | `RT-CONFIG` CS.3, CR.2 | **apply** | CS.3 and CR.2: "templates of every category: user-message templates, group prompts, assist prompts, the templates of the todo buttons and of the Proceed prompt, and the queue templates" `(<- S17 user guide)` |
| vx:G-16 | PQ-36 | **apply** | one `RT-QUEUE` item for global schedule slots (F-TIM-2) and the chat-send time-out (F-QUE-33), one `NFR` item for the watchdog (F-QUE-32, p1s1r5-9), the failure cause (F-TRN-18); the question of where queue entries live goes into PQ-36 |
| vx:G-17 | `RT-QUEUE` CR.83, CR.96, CR.61, CR.70, E-1 | **apply** | drop "planned" in CR.83 (`vscimpb179`), CR.96 (gsel3, gsel11), CR.61 (gsel4 … gsel10), CR.70; cite the todos. **For p1s1r5-2:** E-1 names the `aifmt` work since 2026-11-25. **For p1s1r5-10:** `DEL`'s "that the queue does this without a person is asked of the extension" is answered |
| ww:R22 | `RT-HOLDS` CR.5 | **apply** | new item beside CR.5: the review assists (Grill me, Explain in detail, proposed answers) with their prompts, sent by every host into a run of its own `(<- S17 user guide *Assist prompts*; S25: 13_woneb5)` |
| ww:PQ-W6 | PQ-37 | **ask** | merged into PQ-37 (rewritten) |
| ww:N-2 |  | **drop** | covered by the item of AR-34 (runs of a host in a runtime without a quest); the area names are Webwork's |
| ww:N-4 | `RT-QUEUE` CR.15, CR.16, CR.18 | **drop** | covered (CR.15, CR.16, CR.18) |
| ww:N-6 | `CLI-UI` CU.8 | **drop** | covered (CU.8; the runtime records what a tool wrote); Undo is the host's |
| ww:N-9 | `RT-QUEUE` CR.24, N-23 | **drop** | covered (CR.24, N-23) |
| ww:N-10 |  | **drop** | the same need as ww:R22, written there |
| ww:N-19 | `RT-INSTALL` CR.108, L-8, T8, PQ-38, PQ-41 | **drop** | covered as later (CR.108, L-8, T8); PQ-38, PQ-41, PQ-49 stand |
| ww:N-23 | PQ-37 | **ask** | PQ-37 (rewritten with ww:PQ-W6) |
| AR-2 | `NFR` N-24, N-32, CR.1 | **drop** | confirms (N-24, N-32, CR.1) |
| AR-4 | `RT-HOLDS` CR.1, N-32 | **drop** | confirms (CR.1, N-32) |
| AR-8 | PQ-37 | **ask** | PQ-37 (rewritten) |
| AR-9 | PQ-36 | **ask** | PQ-36 (rewritten) |
| AR-34 | `RT-HOLDS` CR.6, WR-7 | **apply** | new item beside CR.6: a host may create runs of its own in a runtime without a quest, one per part of its application, following no process, each starting in its default session `(<- S3, WR-7; S25: 12a_woneb1)` |
| AR-40 | CR.111 | **apply** | new **CR.111** (a provider page in every host) `(<- S30: xxproviders1, xxbaidu1, xxdeepseek1)` |
| AR-47 | `RT-QUEUE` CR.89 | **apply** | CR.89: the hold point on an agent transport `(<- S30: xxproviders8)` |
| AR-81 | `RT-HOLDS` CR.5, CR.10, CP.2, N-44, CW.15 | **apply** | new item after CR.5: one expression language for prompts, templates and process definitions; the runtime takes over Tom Forge's planned common system, earlier expressions keep working `(<- S26: qavs_wwworkbench-1, planned; S1 § 3.3)`; CR.10: a process move offered by a button is accepted at a sub-step `(<- S1 § 3.5)`. **For p1s1r5-4:** CP.2 crash notice, no restart by itself. **For p1s1r5-9:** N-44 (spec tools on documents of this size). **For p1s1r5-8:** CW.15 "a draft pull request on request" `(<- S1 § 10.4)`. **For p1s1r5-10:** `DEL` tells tom_specs its two wishes `(<- S1 § 13.1)` |
| V2-8 | PQ-37 | **ask** | PQ-37 (rewritten) |
| V2-16 | PQ-37 | **ask** | PQ-37 (rewritten) |
| V2-17 | PQ-36 | **ask** | PQ-36 (rewritten) |


### 2.3 `p1s1r5-4` — `RT-SECRETS` … `RT-PROVIDERS`

Besides the rows: writes PQ-39 (leases only) and PQ-40 (rewritten); CP.21 states the settled chat half (F-QUE-34).


**Covered extension rows — apply B1** (§ 1.1: no new content; add or rewrite the citation from the row's source column; a planned row reads "planned" with its todo):

- 2.2 workspace: F-WSL-6, F-WSL-7
- 2.5 queue: F-QUE-44
- 2.6 timed requests: F-TIM-4
- 2.8 transports: F-TRN-11, F-TRN-12, F-TRN-17
- 2.9 prompt assembly: F-PRM-8, F-PRM-10
- 2.10 tools: F-TOL-1, F-TOL-4, F-TOL-5, F-TOL-7, F-TOL-8
- 2.11 asks: F-ASK-1, F-ASK-2, F-ASK-3, F-ASK-4, F-ASK-5, F-ASK-6, F-ASK-7, F-ASK-8, F-ASK-10, F-ASK-15, F-ASK-17
- 2.12 reviews: F-REV-12, F-REV-16
- 2.13 TomSpecs: F-SPC-1, F-SPC-2, F-SPC-3, F-SPC-4, F-SPC-5, F-SPC-7, F-SPC-8, F-SPC-9, F-SPC-11, F-SPC-12, F-SPC-13
- 2.15 usage: F-USG-2
- 2.16 prerequisites: F-PRE-3, F-PRE-5
- 2.18 other: F-OTH-2

| Finding | Concerns | Ruling | What |
| --- | --- | --- | --- |
| F-TOD-26 | not covered (needs the queue events of CP.4) | **apply** | CP.4: the events include, per todo, whether and where it is queued (the run and the place), so a host can mark it live. `(<~ S17 user guide *Quest TODO Panel*)` |
| F-PRC-20 | partly: CP.38 (assist actions on document questions; decisions not named) | **apply** | CP.38: Grill me and Explain at a process decision run as assist prompts in a temporary session based on the position's session, with the decision's choices as buttons. `(<- S17 user guide *Processes*)` |
| F-QUE-34 | differs: CR.15, CR.67 (chat is a queue item in the run's order); open: PQ-39 | **settle** | PQ-39's chat half, by D-74: chat sends are shown as queue items outside the lanes, one busy slot per session; a send into a busy session offers update, run next, after the current item or a free session; CP.21 says a chat send in another session of a waiting run goes out. `(<- S23: vscimpb132, vscimpb135)`. **For p1s1r5-3:** CR.15 and CR.67 follow |
| F-SES-13 | not covered | **apply** | new item in `RT-TOOLS` (vx:G-6): every tool result of a session is stored under a replay key, kept for a set time and number, and agents read past results through tools. `(<- S17 llm_tools)` |
| F-SES-21 | not covered | **apply** | CT.7: planned: every tool call is attributed to the execution that made it, also when several executions of one runtime run at once (claims and `filed_by` depend on it). `(<- S23: qr5, planned)` |
| F-PRM-23 | partly: CP.38 (slash commands and skills; `@` quest files not named) | **apply** | CP.38 (vx:G-18): completion data include the files of the quest after `@`. `(<- S17 user guide *Keyboard productivity*)` |
| F-PRM-24 | partly: CR.33 (where guidelines are); the tools are in no set of CT.1 | **apply** | CT.1 (vx:G-14): a row "runtime tools on the workspace: guidelines and pattern prompts, the project and repository lists, the issue and test trackers"; read-only through the MCP server. `(<- S17 llm_tools)` |
| F-PRM-25 | not covered | **apply** | CT.1 (same row as F-PRM-24): pattern prompts and their tools. `(<- S17)` |
| F-TOL-2 | not covered | **apply** | CT.10: a core tool set sent in full, the long descriptions behind `tomAi_describeTool`. `(<- S17 llm_tools § 10)` |
| F-TOL-3 | partly: CT.9 (by role) | **apply** | CT.9: tools are enabled per profile as well as per role; the MCP server has its own selection. `(<- S17 user guide *Tools by role*)` |
| F-TOL-9 | partly: CT.10 (the tool set grows) | **apply** | CT.10: planned: specialised tools (code search, file outline and sections, replace in files, find todos, commit paths, run checks, git overview). `(<- S23: tooloptimize2 … tooloptimize9, planned)` |
| F-TOL-12 | not covered (the panels are host's own, SC-25) | **apply** | CT.1 (same row as F-PRM-24): issue and test tools over a provider. `(<- S17 llm_tools)`. The issue **flow** is PQ-63 |
| F-REV-11 | not covered | **apply** | `RT-TOOLS`: a tool that writes a document refuses when the file changed since it was read or is being edited in a host. `(<- S17 user guide *MD Browser*)`. The page's bar is PQ-43 |
| F-REV-24 | partly: CP.38 | **apply** | CT.1 / CP.38: question tools on plain Markdown (list, answer, propose, insert). `(<- S17 llm_tools)` |
| F-SPC-10 | partly: CT.1 ("the specification tools"); CodeSpecs is not named | **apply** | CT.1: the specification tools include those of code generation (Phase 4 of TomSpecs) and their guides. `(<- S17 llm_tools)` |
| vx:G-14 | `RT-TOOLS` CT.1, PQ-63 | **apply** | the proposed CT.1 row (F-PRM-24, F-PRM-25, F-TOL-12); the issue-flow question goes into PQ-63 |
| vx:G-18 | `RT-PROTO` CP.38 | **apply** | CP.38: "… the queued todos with their items, the files of the quest for completion, the models a profile can use" `(<- S17 user guide)` |
| ww:R10 | `RT-PROTO` CP.36 | **apply** | CP.36: the review requests addressed to the user, open or returned, across conversations `(<- S25: 09_woneb2)` |
| ww:R11 | `RT-PROTO` CP.36 | **apply** | CP.36: for a review request, per member whether tac accepted it for delivery `(<- S25: 09_woneb3)`; "opened" is not added (no source) |
| ww:N-7 | `RT-TOOLS` CT.1, CT.4, N-18 | **drop** | covered (CT.1, CT.4, N-18) |
| AR-3 | `RT-HOST` CP.13, D-7 | **apply** | CP.13: "the places of what the host carries for the runtime (provider SDKs it installed, the Dart binaries), where the host and not the runtime installation provides them" `(<- S30: ww_b_workbench-4)`; host transports stay out (D-7) |
| AR-6 | `RT-TOOLS` CT.1, CT.8, CT.11 | **drop** | follows CT.1, CT.8, CT.11 (the product owner's note); the todo is replanned under V2-12 |
| AR-36 | `RT-TOOLS` CT.4, CT.6 | **drop** | confirms (CT.4 … CT.6) |
| AR-38 | `RT-PROVIDERS` CS.18 | **drop** | confirms (CS.18) |
| AR-39 | CS.21 | **apply** | new **CS.21** (adapters per provider: the runtime's own clients, the Vercel AI SDK, official SDKs) `(<- S30: xxproviders1, xxproviders3)` |
| AR-41 | `RT-SECRETS` CS.7 | **drop** | CS.7 covers it (decided, CQ-16); nothing to ask |
| AR-42 | `RT-PROVIDERS` CS.22, CS.12 | **apply** | new **CS.22** (base address, key reference and model-slot mapping per configuration, never process-wide); CS.12: Claude on Bedrock / Vertex with cloud credentials `(<- S30: xxproviders2, xxdeepseek1, xxotherproviders4)` |
| AR-43 | `RT-PROVIDERS` CS.14, CR.105 | **apply** | CS.14's price clause (from the provider or a published list, never by hand; premium requests and quota where reported) `(<- S30: xxproviders4)`. **For p1s1r5-3:** CR.105 "per day, provider and model" |
| AR-44 | `RT-PROVIDERS` CS.14 | **drop** | confirms (CS.14) |
| AR-45 | `RT-PROVIDERS` CS.15 | **apply** | CS.15: the conformance table as proposed `(<- S30: xxproviders6)` |
| AR-48 | `RT-QUEUE` CS.23, CS.24, CR.75, CR.43 | **apply** | new **CS.23** (sign-in per configuration), **CS.24** (an agent program's own tools off by default) `(<- S30: xxcopilotsdk1, xxopenai1, xxgoogle1)`. **For p1s1r5-3:** CR.75 "a transport that cannot fork offers only continue"; CR.43 "a provider SDK, command line or native runtime" |
| AR-49 | `RT-PROVIDERS` CS.12 | **apply** | CS.12 row 3 adds OpenAI (Responses API) `(<- S30: xxopenai2 … xxopenai4)`. **For p1s1r5-2:** `SCO-LATER` row: the OpenAI Agents SDK as a transport `(<- S30: xxlater1)` |
| AR-50 | `RT-PROVIDERS` CS.12 | **apply** | CS.12 adds the Gemini API `(<- S30: xxgoogle1)` |
| AR-52 | `RT-PROVIDERS` CS.12 | **apply** | CS.12: Llama through routers, providers and local models; Meta's own API not used `(<- S30: xxmeta1)` |
| AR-53 |  | **drop** | confirms |
| AR-54 | CS.25, R-30 | **apply** | new **CS.25** (a provider API that keeps the conversation) `(<- S30: xxmistral1)`. **For p1s1r5-10:** new **R-30** (an agent transport that needs another language runtime on every host) |
| AR-55 | `RT-PROVIDERS` CS.12, CS.14 | **apply** | CS.12 / CS.14: a router's configuration carries its routing preferences `(<- S30: xxopenrouter1)` |
| AR-56 | `RT-PROVIDERS` CS.12 | **apply** | CS.12 lists the presets chosen in `xxotherproviders1` (LiteLLM in, Cerebras out) and one sentence that any compatible endpoint can be configured without a preset `(<- S30: xxotherproviders1)`; no question (decided there) |
| AR-57 | `RT-PROVIDERS` CS.16 | **apply** | CS.16 names `pi-ai` and `pi-coding-agent` with the proposed text `(<- S1 § 5.4; S2 § 3.8; S30: ccparity_h_pi-1 … -3)` |
| AR-63 | PQ-54 | **apply** | new item in `RT-SECRETS`: a command a tool runs may name secret references; only those are resolved, into that command's environment, never into a prompt, result, trail or log; tool results are masked `(<- S30: ww_e_gitruntime-5)`. The internal repository is PQ-54; never name `tom_kdbx` |
| AR-82 | CT.18 | **apply** | new **CT.18** (a remote tool keeps its name; the target quest is an argument) `(<- S20 § 12; S4 note e)` |
| V2-18 | PQ-40 | **ask** | PQ-40 (rewritten) |


### 2.4 `p1s1r5-5` — `CLI`

Besides the rows: writes PQ-43, PQ-44 (rewritten); adds the screen rows the host-UI findings name (host's own, reused).


**Covered extension rows — apply B1** (§ 1.1: no new content; add or rewrite the citation from the row's source column; a planned row reads "planned" with its todo):

- 2.1 quests: F-QST-16
- 2.3 todos: F-TOD-25, F-TOD-31, F-TOD-32
- 2.4 processes: F-PRC-2, F-PRC-4
- 2.5 queue: F-QUE-39, F-QUE-40
- 2.6 timed requests: F-TIM-5
- 2.7 sessions: F-SES-17, F-SES-20
- 2.11 asks: F-ASK-14
- 2.12 reviews: F-REV-1, F-REV-3, F-REV-5, F-REV-6, F-REV-15, F-REV-18, F-REV-19, F-REV-20
- 2.14 memory: F-MEM-4
- 2.16 prerequisites: F-PRE-2, F-PRE-6
- 2.17 collaboration: F-COL-7
- 2.18 other: F-OTH-5, F-OTH-6, F-OTH-7, F-OTH-8, F-OTH-10

| Finding | Concerns | Ruling | What |
| --- | --- | --- | --- |
| F-QST-6 | not covered (host's own; needs only "open a document", CP.10) | **apply** | screen inventory (`CLI-SCREENS`): the overview opened once per machine is the VS Code host's own; it needs only "open a document" (CP.10). `(<- S23: vsc_setup-6)` |
| F-TOD-27 | not covered | **apply** | screen inventory: the todo stack (one item each, or one combined prompt) is a host component over the queue commands; listed as `reused`. `(<- S17 user guide)` |
| F-TOD-30 | not covered | **apply** | screen inventory: the question after *Guide me* is a host dialog over the todo commands; listed as `reused`. `(<- S17 user guide)` |
| F-QUE-11 | not covered | **apply** | screen inventory: "Queue anyway" when a group waits for todos that do not run first is a host dialog; the tools do not ask. `(<- S17 user guide)` |
| F-QUE-41 | not covered | **apply** | screen inventory: one icon set for the queue place (end, top, next) everywhere; host's own. `(<- S23: vscimpb181, planned)` |
| F-PRM-18 | partly: SC-23 | **apply** | screen inventory SC-23: the guideline picker on every level and the aspect editor are host components; renaming an aspect carries the stored choices over (an engine step: **For p1s1r5-3:** CR.61 one clause). `(<- S17 user guide)` |
| F-TOL-13 | partly: CT.7 | **drop** | VS Code-only output channel; CT.7 already attributes tool calls |
| F-ASK-9 | partly: CP.40 | **apply** | CU.6 *Asks* / SC-31: planned: an ask or a todo's decisions answered inline from the notifications list of any host. `(<- S23: vscimpb182, planned)`. **For p1s1r5-4:** CP.40 unchanged |
| F-ASK-20 | not covered | **drop** | VS Code-only (bringing a window to the front) |
| F-REV-2 | not covered (CU.9 open, PQ-43) | **ask** | PQ-43 (rewritten: what the review component carries) |
| F-REV-4 | not covered | **ask** | PQ-43 |
| F-REV-8 | not covered | **ask** | PQ-43 |
| F-REV-9 | partly: CU.6 *Review* | **ask** | PQ-43 |
| F-REV-22 | not covered | **ask** | PQ-43 |
| F-REV-23 | not covered | **ask** | PQ-43 |
| F-PRE-4 | partly: CR.42, N-29 | **drop** | the old extension's own packaging (O-1); the runtime's packaging is CR.40 … CR.43 and N-29 |
| F-OTH-1 | not covered (O-1) | **drop** | VS Code-only (O-1); the new extension carries it unchanged (D-73), PQ-62 names it only if it were dropped |
| ww:R20 | PQ-43 | **ask** | PQ-43 (rewritten with ww:PQ-W3) |
| ww:R21 | PQ-43 | **ask** | PQ-43 (the navigation contract follows where the component is built) |
| ww:PQ-W3 | PQ-43 | **ask** | merged into PQ-43 (rewritten) |
| ww:N-8 | `CLI-UI` CU.7 | **drop** | covered (CU.7) |
| ww:N-11 | PQ-44 | **ask** | PQ-44 (rewritten: Webwork's C22 inconsistency) |
| ww:N-14 | PQ-43 | **ask** | PQ-43 (the messaging components, `tom_messaging_ui`) |
| AR-18 | `CLI-SCREENS` CU.18, SC-28 | **apply** | new **CU.18** (the coordination page) with the proposed text; SC-28 extended `(<- S6, part-coordination-page-and-tools)` |
| AR-32 | `CLI-PACK` CL.3, CL.11, X-3 | **drop** | resolved (CL.3, CL.11, X-3) |
| AR-35 | `CLI-UI` CU.1, CU.8 | **drop** | confirms (CU.1 … CU.8) |
| AR-70 | `DEC` CL.13, D-1 | **apply** | new **CL.13** (`tom_vscode_scripting_api` keeps the VS Code namespace, depends on and re-exports the Dart runtime client SDK) `(<- S30: ww_e_runtimeapi-1)`; the place is **settled** by D-1 (§ 1.3). **For p1s1r5-10:** `CON` entry on `ww_e_runtimeapi-1`'s superseded answer |
| AR-71 | `CLI-PACK` CL.10 | **apply** | CL.10: its connection is an exchangeable transport (a VS Code window's script server, a runtime) `(<- S30: ww_e_runtimeapi-2)` |
| AR-72 | `CLI-PACK` CL.9 | **apply** | CL.9: "nor on the VS Code scripting API" `(<- S30: ww_e_runtimeapi-3)` |
| AR-73 | `CLI-PACK` CL.10 | **apply** | CL.10: the same answers through a window's script server as through a runtime, for the commands both serve `(<- S30: ww_e_runtimeapi-4)` |
| AR-74 |  | **apply** | new item in `CLI-PACK`: the users of today's Dart script client (d4rt command line and bridges, the VS Code bridge, Tom Core's agent code) move to the Dart runtime client SDK, each released by its own quest `(<- S30: ww_e_runtimeapi-5)` |
| AR-75 | `NFR` N-30 | **drop** | confirms (N-30, `DEL`) |
| AR-76 | `CLI-PACK` CL.10, PQ-36 | **drop** | confirms (CL.10; PQ-36) |
| AR-78 |  | **drop** | trc is specified in `CLI-TRC`; `rca1` is a todo matter for `DEL`'s list of replaced todos |
| V2-10 | `CLI-SCREENS` CU.10 | **apply** | CU.10 as § 1.3 |


### 2.5 `p1s1r5-6` — `TAC-JOBS`, `TAC-COORD`, `TAC-BACKENDS`

Besides the rows: writes PQ-45, PQ-46, PQ-47, PQ-48 (rewritten) and **PQ-63** (new).

| Finding | Concerns | Ruling | What |
| --- | --- | --- | --- |
| F-TOD-34 | differs: CW.7, CA.9, CA.10 (resource names `git:<owner>/<repository>#<pattern>`, one prefi | **ask** | PQ-63 (the feature fields) and PQ-45 (rewritten: the `<type>://` notation) |
| F-PRC-22 | not covered | **ask** | PQ-63 (standard runs `planning` and `quest-keeper`) |
| F-QUE-38 | not covered | **ask** | PQ-63 (queue position of items queued by a running item, warnings for `planning` and feature runs) |
| F-PRM-19 | not covered | **ask** | PQ-63 (the system aspects `agent_role`, `feature_branches` follow the collaboration plan) |
| F-COL-1 | not covered | **ask** | PQ-63 |
| F-COL-2 | not covered (CP.22 forwards an ask to a member, not to an agent) | **ask** | PQ-63 |
| F-COL-3 | not covered | **ask** | PQ-63 |
| F-COL-4 | differs: CA.8 … CA.16 (tac leases with fencing tokens, stale after 60 minutes), CA.26 (the | **ask** | PQ-63 and PQ-46 (rewritten) |
| F-COL-5 | partly: CW.4, CW.9 | **ask** | PQ-63 |
| F-COL-6 | not covered | **ask** | PQ-63 |
| F-COL-8 | differs: CW.2, CW.3 (worktree mode per repository, an execution's own working tree) | **ask** | PQ-63 |
| F-COL-9 | differs: CW.5, CW.6 (the integration step and queue) | **ask** | PQ-63 |
| F-COL-10 | partly: SC-28 | **ask** | PQ-63 |
| F-COL-11 | not covered | **ask** | PQ-63 |
| F-COL-12 | not covered | **ask** | PQ-63 |
| F-COL-13 | partly: CW.15 (review without pull requests) | **ask** | PQ-63 |
| F-COL-14 | not covered | **ask** | PQ-63 |
| F-COL-15 | not covered | **ask** | PQ-63 (the issue flow, vx:G-14) |
| F-COL-16 | partly: CR.35 (a quest's list of repositories) | **ask** | PQ-63 (`quest-keeper`, `defaultResources`) |
| vx:G-1 | PQ-63 | **ask** | PQ-63 (§ 1.4) |
| ww:N-21 | `TAC-BACKENDS` CA.26, CA.28 | **drop** | covered (CA.26 … CA.28) |
| ww:N-24 |  | **drop** | nothing new for this product (Webwork does not need leases for messaging, S3) |
| AR-13 | `TAC-BACKENDS` CA.26, PQ-48 | **apply** | CA.26: the workspace's coordination configuration is the versioned file `agent.workspace.yaml` at the workspace root with a JSON schema (backend, team, repositories coordinated and brought up to date) `(<- S6, BP-21, BP-22)`; PQ-48's context gets `ensureLocalService()` |
| AR-16 | `TAC-COORD` CA.20, CA.18 | **apply** | CA.20 adds the notifications "a repository could not be brought up to date", "the team's configuration or a backend's limits need attention"; CA.18 adds "a command names its target quests, never all, and may prefer a machine" `(<- S5 § 11 items 6, 16; S6)` |
| AR-19 | CA.45, PQ-47 | **apply** | new **CA.45** (GitHub rate limits, history shortened by a step the user starts) `(<- S5 § 6.3, § 10; S6)`; PQ-47's context gets S5's presence and time |
| AR-23 | `TAC-BACKENDS` CA.27 | **apply** | CA.27: "its quotas count at least the resources leased and the calls per hour; it listens on the VPN only unless its administrator opens it" `(<- S6, IDEA-16, BP-5)` |
| AR-24 | `TAC-BACKENDS` CA.33 | **apply** | CA.33: "while it runs, one runtime holds every repository of the team exclusively and the others wait" `(<- S6, BP-9)` |
| AR-27 | PQ-63 | **ask** | PQ-63 (new, § 1.4) |
| AR-29 | `TAC-BACKENDS` CA.27, CA.28 | **drop** | superseded by AR-23; its answers match CA.27, CA.28 |


### 2.6 `p1s1r5-7` — `TAC-PEOPLE` … `TAC-WEBWORK`

Besides the rows: writes PQ-50 (rewritten) and **PQ-66** (new); CV.17, CV.18, CV.11 per § 1.2.


**Covered extension rows — apply B1** (§ 1.1: no new content; add or rewrite the citation from the row's source column; a planned row reads "planned" with its todo):

- 2.12 reviews: F-REV-7, F-REV-10, F-REV-13

| Finding | Concerns | Ruling | What |
| --- | --- | --- | --- |
| F-TOL-6 | differs: CT.11, CT.12 (only `_ai` tools; today file and host tools are served behind the k | **ask** | PQ-50 (rewritten: a local-only second MCP endpoint with file and host tools, vx:G-13) |
| F-REV-21 | differs: CV.13 (the round folder as built) | **apply** | CV.17 (§ 1.2 point 1), written once with ww:R1 |
| vx:G-13 | `RT-MCP` PQ-50, CT.12 | **ask** | PQ-50 (rewritten). **For p1s1r5-4:** CT.12 gets whatever the answer: "Without a valid token the server serves only read-only tools, and only to the local machine and the VPN." `(<- S17 mcp_server.md § 3)` |
| ww:R1 | CV.17 | **apply** | new **CV.17**, text of `inventory_webwork.md` § 2.7 `(<- S29: FQ-11; S23: 04c_woneb4, planned)` |
| ww:R2 | `TAC-DOCS` CV.5, CV.17 | **apply** | CV.5 last sentence: what is under review, its members, coordinator and rounds is the review's `review.yaml` (CV.17). `(<- S29: FQ-11)` |
| ww:R3 | CV.18 | **apply** | new **CV.18** (the round's state read from the folder) `(<- S29: FQ-11; S25: 09_woneb3)` |
| ww:R4 | `TAC-REVIEW` CV.11 | **apply** | CV.11 rewritten (§ 1.2 point 3) `(<- S29: FQ-9)`; obligation change |
| ww:R5 | `TAC-REVIEW` CV.12, CV.17 | **apply** | CV.12 step 1: "… the base, or the member's own files where the round has them (CV.17)" `(<- S29: FQ-11)` |
| ww:R6 | `TAC-REVIEW` CV.12 | **drop** | covered (CV.12 steps 1, 3, 5) |
| ww:R7 | `TAC-DOCS` CV.1, CV.4, CV.14 | **drop** | covered (CV.1 … CV.4, CV.14) |
| ww:R8 | PQ-66 | **ask** | PQ-66 (the blob lifetime of a round) |
| ww:R9 | PQ-66 | **ask** | PQ-66 (how a set travels) |
| ww:R12 | `TAC-DOCS` CV.9 | **drop** | covered (CV.9) |
| ww:R13 | `TAC-KINDS` CM.2, CM.4, CV.12 | **drop** | beyond Webwork's need but backed by S1; CM.2, CM.4, CV.12 step 4 stay |
| ww:R14 | `TAC-REVIEW` CV.12, CV.16 | **drop** | covered (CV.12, CV.16) |
| ww:R15 | PQ-66 | **ask** | PQ-66 (the member id and the tac user) |
| ww:R16 | `TAC-REVIEW` CV.15 | **drop** | covered (CV.15) |
| ww:R17 | `RT-PROTO` CP.36, WR-4, WR-5 | **drop** | covered (CP.36; WR-4, WR-5) |
| ww:R19 | `TAC-CRYPT` CI.16, CI.17 | **drop** | covered (CI.16, CI.17) |
| ww:R23 | `RT-HOST` CP.13 | **drop** | covered (CP.13) |
| ww:R24 | `TAC-WEBWORK` WR-5, CV.17 | **apply** | `TAC-WEBWORK`, row WR-5: add "the review folder layout of CV.17" |
| ww:PQ-W1 | PQ-66 | **ask** | merged into PQ-66 (new) |
| ww:PQ-W2 | PQ-66 | **ask** | merged into PQ-66 |
| ww:PQ-W4 | PQ-66 | **ask** | merged into PQ-66 |
| ww:N-1 | PQ-51 | **ask** | PQ-51 (kept) |
| ww:N-13 | PQ-52 | **ask** | PQ-52 (kept) |
| ww:N-15 | `TAC-DOCS` CV.8, CV.9, CM.3, CU.16 | **drop** | covered (CV.8, CV.9, CM.3, CU.16) |
| ww:N-17 |  | **drop** | Webwork's own (D1 § 8.3), not this product's |
| ww:N-18 | PQ-49 | **ask** | PQ-49 (kept) |
| ww:N-20 | PQ-51 | **ask** | PQ-51 (kept; Webwork's own MCP endpoint is within its options) |
| AR-17 | PQ-50 | **ask** | PQ-50 (rewritten: S6 restricts the remote-control endpoint to the machine) |
| AR-30 | CM.15 | **apply** | new **CM.15**: a message's time is set by the service's clock when it accepts it `(<- S1 § 7.10)` |
| AR-31 | PQ-66 | **ask** | PQ-66 (the blob lifetime of a round) |
| AR-37 |  | **drop** | confirms; its gaps are AR-31 and AR-34 |


### 2.7 `p1s1r5-8` — `PAR`

Besides the rows: writes PQ-53, PQ-54, PQ-55 (rewritten).


**Covered extension rows — apply B1** (§ 1.1: no new content; add or rewrite the citation from the row's source column; a planned row reads "planned" with its todo):

- 2.3 todos: F-TOD-8, F-TOD-23
- 2.5 queue: F-QUE-28

| Finding | Concerns | Ruling | What |
| --- | --- | --- | --- |
| F-QST-3 | partly: CQ.7 *create* (written for the three quest types; the setup todo and the question  | **ask** | PQ-55 (rewritten: creating a quest with its setup todo, vx:G-9) |
| F-WSL-3 | not covered | **ask** | PQ-55 (rewritten: setting up a workspace from the template, three forms) |
| F-WSL-4 | not covered | **ask** | PQ-55 (rewritten: who carries the workspace template) |
| vx:G-9 | PQ-55 | **ask** | PQ-55 (rewritten) |
| AR-14 | `RT-LOCATIONS` CW.28, CR.35 | **apply** | new **CW.28**: only an item that executes a todo claims; an agent's claim tool is refused outside such an item `(<- S6, DPR-1)`. **For p1s1r5-3:** CR.35's last sentence names `quest-resources.<quest>.yaml` as S1 and S6 do, the Blueprint settling it |
| AR-20 | `PAR-APPROACH` CW.16, O-6 | **drop** | confirms (CW.16, O-6, F11) |
| AR-22 | CW.29, PQ-46 | **apply** | new **CW.29** (orphaned working trees and branches shown, never removed on their own) `(<- S6, part-branches-and-worktrees)`. **For p1s1r5-6:** PQ-46 gets the `Tac-Fence` trailer option |
| AR-59 | PQ-53 | **ask** | PQ-53 (rewritten: option (d) `_ai/personal/<id>/`) |
| AR-60 | `LAND-BUILT` E-5, CQ.12 | **apply** | no question: the runtime uses the fleet's drivers (E-5; the extension plans to take them from `tom_binaries`, F-QST-13, S23: vscimpb152aaa). CQ.12 adds: dated journals are merged as a union of their dated sections `(<- S30: ww_e_gitruntime-2)` |
| AR-61 | PQ-54 | **ask** | PQ-54 (rewritten) |
| AR-62 | `PAR-QUESTS` CQ.6 | **apply** | CQ.6: each run's process position is one shared file, moved only on the main branch, refused when it changed there since read `(<- S30: ww_e_gitruntime-4)` |
| AR-64 | PQ-54 | **ask** | PQ-54 |
| AR-65 | PQ-54 | **ask** | PQ-54 |
| AR-66 | `PAR-QUESTS` CQ.7, CQ.8 | **drop** | confirms (CQ.7, CQ.8) |
| AR-68 | `PAR-QUESTS` CQ.7 | **drop** | confirms (CQ.7) |
| AR-69 | PQ-54 | **ask** | PQ-54 (a flow for two members if the features stay) |


### 2.8 `p1s1r5-9` — `NFR`

Besides the rows: writes PQ-56 (rewritten); N-33 per § 1.3; G-1, T1 carry PQ-37's assumption.

| Finding | Concerns | Ruling | What |
| --- | --- | --- | --- |
| F-QUE-32 | not covered | **apply** | new `NFR` item: the runtime checks its own queue (a watchdog every 60 s for stalled pending items) and falls back to polling every 30 s where events are missed; written as built. `(<- S17 user guide *Queue*)`. Not asked in PQ-56 |
| ww:N-3 | `NFR-TOPO` T2 | **apply** | T2: a host whose run is bound to a quest folder uses that quest's runtime `(<- S25: 12a_woneb1)` |
| V2-6 | `NFR` N-33 | **apply** | N-33 as § 1.3 |


### 2.9 `p1s1r5-10` — `DEC`, `CON`, `RISK`, `DEL`

Besides the rows: D-73, D-74 rows; D-41 replaced; `CON` X-22 (§ 1.4) and the entry on `ww_e_runtimeapi-1`; writes PQ-57 (rewritten) and **PQ-60**, **PQ-61** (new); runs after p1s1r5-2 … -9.

| Finding | Concerns | Ruling | What |
| --- | --- | --- | --- |
| ww:R18 | `RT-HOST` CP.13, CS.11 | **apply** | `DEL` "What the other quests are told": Webwork is told that the team token is the runtime's (CP.13, CS.11) — its `13_woneb6` still has it in the device's settings |
| ww:PQ-W5 | PQ-57 | **ask** | merged into PQ-57 (rewritten) |
| ww:N-5 | `RT-QUEUE` CR.17 | **apply** | `DEL` "What the other quests are told": the review option of a run is the runtime's (CR.17) — Webwork's `13_woneb2` has it as device state |
| ww:N-12 |  | **drop** | covered; the token's place is told to Webwork under ww:R18 |
| ww:N-16 |  | **apply** | `DEL` "What the other quests are told": the anchor is `msg:tac/<team>/<messageId>` — Webwork's `12a_woneb2`, `13_woneb9` still write `<server-group>` |
| ww:N-25 |  | **apply** | `DEL` "What the other quests are told": Webwork waits for this specification as a document (`03a_woneb1`), then for the covering todos and "runtime complete"; its `blocked_by` entries move to the new todos |
| AR-1 | `DEC` D-1 | **drop** | stale todo; D-1 holds; the todo is replanned under V2-12 |
| AR-7 | PQ-57 | **ask** | PQ-57 (the conformance test against files the old extension wrote, as acceptance) |
| AR-10 | `NFR` N-30 | **drop** | confirms (N-30); replanned under V2-13 |
| AR-11 | `DEC` D-73, D-41 | **settle** | by D-73: RS-1 (b) in `ai_build`; D-41 replaced. **For p1s1r5-2:** S18's standing "RS-1 replaced by D-73" |
| AR-25 |  | **apply** | `DEL`: the hand-off of the coordination work is the swap (V2-14) |
| AR-33 | PQ-57 | **ask** | PQ-57 (Webwork's end-to-end check in the thin path) |
| AR-46 | PQ-57 | **ask** | PQ-57 (one queue item with a tool call on each way in) |
| AR-67 | PQ-53, PQ-54 | **apply** | `DEL`: al_the_bear is told what of PQ-53 / PQ-54's answers differs from its standard (only if anything does) |
| AR-77 | PQ-61 | **ask** | PQ-61 (when the Dart scripting API is split) |
| AR-79 | `DEC` D-3, PQ-51 | **apply** | D-3's "Replaces" column names note k; note d (an MCP server of a Webwork or Webforge instance) goes into PQ-51's context (p1s1r5-7, one sentence) |
| AR-84 |  | **drop** | quest documents, not the Project Idea; listed for the closing item |
| V2-1 | `DEC` D-73, D-41 | **settle** | D-73 written, D-41 marked replaced (§ 1.3) |
| V2-2 | PQ-60, PQ-61 | **apply** | `DEL` "The stable extension during the split" rewritten as proposed, naming PQ-60 / PQ-61 for the open points |
| V2-3 | `DEC` D-40, R-16 | **apply** | `DEL` step 3 and D-40 as proposed; R-16 "the engine being complete before it is copied" |
| V2-5 | `RISK-RISKS` R-1, R-31 | **apply** | R-1 rewritten; new **R-31** (§ 1.3) |
| V2-12 |  | **apply** | `DEL` "what replaces which todo": the `ww_b_workbench-*` stages against the copy |
| V2-13 |  | **apply** | `DEL`: the `ww_d_workbench-*` stages and the new todos named (team views, acceptance run, swap, retirement, script server) |
| V2-14 |  | **apply** | `DEL` track row; the hand-off is the swap |
| V2-15 | PQ-60 | **ask** | PQ-60 (new) |
| V2-19 | PQ-61 | **ask** | PQ-61 (new) |
| V2-20 | PQ-60 | **ask** | PQ-60 |
| V2-21 | `DEC` D-1 | **settle** | D-1 stands: runtime, new extension and Dart runtime client SDK in `tom_ai/ai_build`; `CON` entry on `ww_e_runtimeapi-1` |
| V2-22 | PQ-60 | **ask** | PQ-60 |
| V2-23 | PQ-57 | **ask** | PQ-57 (rewritten) |
| V2-25 | PQ-61 | **ask** | PQ-61 |
| V2-28 | PQ-60 | **ask** | PQ-60 |


### 2.10 `p1s1r5-11` — `GLO` and the whole document

Besides the rows: writes PQ-58 (rewritten); the glossary entries of § 1.2 and § 1.6; puts the question set of § 3 in place; S21 kept equal.

| Finding | Concerns | Ruling | What |
| --- | --- | --- | --- |
| AR-83 | D-73 | **apply** | S21 kept equal to `GLO`, with the words of § 1.6 and D-73 |
| V2-11 | PQ-58 | **apply** | glossary entries old extension, new extension, copy point, swap (§ 1.6); PQ-58 asks only whether the words are right |

## 3. The question set after the round

33 questions: 7 kept, 19 rewritten (PQ-39 also settled in part), 7 new. None of the 26 is merged
away. **The new ids PQ-60 … PQ-66 are reserved here** for the parts named, so parts that run at
the same time do not take the same number; a part that needs a further new question takes the
next free number after PQ-66 (re-read `new_questions.md` first).

| Question | Kind | Topic | Writes it | Findings behind it |
| --- | --- | --- | --- | --- |
| PQ-34 | rewritten | who writes `_ai` files besides the runtime (with the old extension's engine and `tom_todo_model` 6.0.0) | p1s1r5-3 | F-TOD-1, F-TOD-35 (via B1), D-73 |
| PQ-35 | rewritten | the quest refresh, the stored prompt, the "window" level and night mode, `prerequisites.yaml`: runtime's or host's, and once per quest and per person | p1s1r5-3 | F-QST-7, F-QUE-29, F-QUE-30, F-PRE-1, vx:G-5 |
| PQ-36 | rewritten | two hosts on one quest, the old engine beside a runtime, a timed request firing once, where queue entries live | p1s1r5-3 | AR-9, V2-17, F-QUE-31, vx:G-16 |
| PQ-37 | rewritten | Node, the Agent-SDK-only mode, who installs (Webwork's installer), the new extension's runtime in process or as a process | p1s1r5-3 | AR-8, V2-8, V2-16, ww:PQ-W6, ww:N-23 |
| PQ-38 | kept | the web runtime service | — | ww:N-19 |
| PQ-39 | settled in part, rewritten | the leases of an execution waiting for an ask (the chat half settled by D-74) | p1s1r5-4 | F-QUE-34 |
| PQ-40 | rewritten | when a migration runs, and the format while the old engine and the runtime both work | p1s1r5-4 | V2-18, F-QST-11 |
| PQ-41 | kept | the web runtime client SDK | — | — |
| PQ-42 | kept | TypeScript and JavaScript | — | — |
| PQ-43 | rewritten | where the review and the messaging components are built, and what the review component carries | p1s1r5-5 | ww:PQ-W3, ww:R20, ww:R21, ww:N-14, F-REV-2, F-REV-4, F-REV-8, F-REV-9, F-REV-22, F-REV-23 |
| PQ-44 | rewritten | the Flutter view packages beside the new components (with Webwork's C22) | p1s1r5-5 | ww:N-11 |
| PQ-45 | rewritten | how resources and other addressed things are written (with the extension's `<type>://`) | p1s1r5-6 | F-TOD-34 |
| PQ-46 | rewritten | the lease rules and the fencing check (with git-ref tables and the `Tac-Fence` trailer) | p1s1r5-6 | F-COL-4, AR-22 |
| PQ-47 | rewritten | a team on the GitHub backend (with S5's presence and time) | p1s1r5-6 | AR-19 |
| PQ-48 | rewritten | "coordination off" and the local tac service (with D-13 and `ensureLocalService()`) | p1s1r5-6 | AR-13 |
| PQ-49 | kept | phones and tablets | — | ww:N-18 |
| PQ-50 | rewritten | remote control, the MCP server's reach (a local second endpoint), tac's credentials | p1s1r5-7 | F-TOL-6, vx:G-13, AR-17 |
| PQ-51 | kept | a runtime that serves no quest (one context sentence on note d may be added) | — | ww:N-1, ww:N-20, AR-79 |
| PQ-52 | kept | cache and outbox of messaging | — | ww:N-13 |
| PQ-53 | rewritten | anything personal beside the per-host files in the quest (personal notes, `_ai/personal/<id>/`) | p1s1r5-8 | AR-59, F-SES-16 |
| PQ-54 | rewritten | member branches, internal repository, secret scan, member access — this quest's own queued todos | p1s1r5-8 | AR-61, AR-64, AR-65, AR-69 |
| PQ-55 | rewritten | who carries the quest operations and the workspace setup | p1s1r5-8 | F-QST-3, F-WSL-3, F-WSL-4, vx:G-9 |
| PQ-56 | rewritten | numbers no source gives (without the built ones; with the size of a review bundle) | p1s1r5-9 | F-QUE-32 (removed from the list) |
| PQ-57 | rewritten | what "finished" is checked against: thin paths (local, and a team review between two desktops), the new extension's acceptance | p1s1r5-10 | ww:PQ-W5, V2-23, AR-7, AR-33, AR-46 |
| PQ-58 | rewritten | words in several senses, with old / new extension, copy point, swap, and Webwork's "group" | p1s1r5-11 | V2-11 |
| PQ-59 | kept | the structure of the Project Idea | — | — |
| **PQ-60** | new | the new extension's identity beside the old one, the swap (place, name, version), retiring and archiving, ownership after the swap | p1s1r5-10 | V2-15, V2-20, V2-22, V2-26, V2-28 |
| **PQ-61** | new | the copy point, what the old extension gets meanwhile, which open extension todos land before the copy, when the Dart scripting API is split | p1s1r5-10 | V2-19, V2-25, AR-77 |
| **PQ-62** | new | what "every feature as before" leaves out or adds in the new extension: VS Code LM and Copilot (D-7, O-4), per-quest Telegram, the script server and its ports, the team views | p1s1r5-2 | V2-9, V2-24, V2-27, V2-29, AR-5, AR-21, vx:G-4, F-ASK-21, F-ASK-22, F-ASK-23 |
| **PQ-63** | new | the extension's collaboration plan against tac, D-24 and D-68 (§ 1.4) | p1s1r5-6 | AR-27, vx:G-1, F-TOD-34, F-PRC-22, F-QUE-38, F-PRM-19, F-COL-1 … F-COL-6, F-COL-8 … F-COL-16, F-TOL-12 (the flow) |
| **PQ-64** | new | control items and wait / notify items in the queue, and whether they reach runs on other machines and of other people in the first version | p1s1r5-3 | vx:G-2, F-QUE-35, F-QUE-36, F-QUE-37 |
| **PQ-65** | new | the store of asks and answers (per host or one file per entry) and whether asks and answers carry question blocks and prompts in the ask envelope | p1s1r5-3 | vx:G-7, F-ASK-11, F-ASK-12, F-ASK-13 |
| **PQ-66** | new | the review exchange over tac: how a round's set travels, review member id and tac user, how long a round's blobs stay | p1s1r5-7 | ww:PQ-W1, ww:PQ-W2, ww:PQ-W4, ww:R8, ww:R9, ww:R15, AR-31 |

**Decisions the round writes** (by `p1s1r5-10`): **D-73** the new extension (replaces D-41;
RS-1 (b)); **D-74** the feature baseline. No other open question is settled whole.

## 4. Sources to add to `SRC` (by `p1s1r5-2`)

| Proposed id | Path | Date | What it is | Standing |
| --- | --- | --- | --- | --- |
| **S28** | `_ai/quests/vscode_extension/ideas/collab_and_features/collab_and_features.docspecs.md` and `collab_and_features_input.md` | 2026-11-24 | The extension quest's plan for leases as git refs, resource notation, feature branches and worktrees, agent groups with a supervisor, features and feature runs, standard runs, review todos, the issue flow; its 76 `caf_*` todos | planned, not built; differs from `TAC-COORD` and D-24 / D-68 (PQ-63, X-22) |
| **S29** | `_ai/quests/webwork/webwork_office_and_review.webwork.md` and `_ai/quests/webwork/webwork_component_placement.webwork.md` | 2026-11-25 | Webwork's decisions: OR-n and FQ-n (the review folder layout FQ-11, the channels FQ-9, the areas Review and Team Review FQ-5 / FQ-8, the installer FQ-3), the component placement C-n and Q-n (`tom_messaging_ui`, C21, Q-8) | current; decided in the webwork quest |
| **S30** | `_ai/quests/ai_runtime/todos.ai_runtime.todo.yaml` | 2026-11-25 | This quest's own todo groups and the product owner's answers in their decisions: `ww_b_workbench-*`, `ww_d_workbench-*`, `ww_*_collab-*`, `tac_webwork-*`, `12b_woneb*`, `xx*`, `ccparity_h_pi-*`, `ww_e_gitruntime-*`, `ww_e_runtimeapi-*`, `a2a1`, `rca1`, `checks*` | current as input; replaced by the todos of the specification (D-42); `ww_e_runtimeapi-1`'s answer on the place is superseded by D-1 |
| **S31** | `tom_ai/ai_build/specification/phase1_project_idea/01_05_Questions Round/answers.md` | 2026-11-25 | The product owner's instructions (a) and (b) of round 5, verbatim | current; the words behind D-73 and D-74 |

**Existing rows that move to the state of 2026-11-25** (same id, the row's path, range and date
updated; no new id):

| Id | Change |
| --- | --- |
| S17 | the extension's documentation as of 2026-11-25 (`user_guide.md`, `llm_tools.md`, `mcp_server.md`, `md_browser_page_protocol.md`, `reading_notation_sample.md` and the others listed in `inventory_vscode_extension.md` § 1) |
| S23 | the extension's todo files (open, and archived through 2026-11-25) and `progress.vscode_extension.md` through 2026-11-25 |
| S25 | Webwork's todo file of 2026-11-25 with the groups `09_woneb…`, `03a_woneb…`, `12a_woneb…`, `13_woneb…`, `qavs_…`, `caf_17…` |
| S7 | standing: "predates the provider decisions in this quest's `xx*` todos (S30), which win" |
| S18 | standing: "RS-1 is replaced by D-73" |
| S19 | standing: "its § 7 stages are replaced by D-73" |
| S2 | the decisions FO-1 … FO-22 without FO-14, which was not assigned |

## 5. The count check

Run mechanically over § 2 of this file (`ztmp/ai_runtime_261125_p1s1r5-1_check.py`, deleted after the run): every finding id of the three inventories, collected from them by their own patterns, against the ids in the "Finding" column of the tables and in the B1 and retiring lists of § 2.

| Inventory — ids | In the inventory | Ruled exactly once | Not ruled | Ruled twice |
| --- | --- | --- | --- | --- |
| `inventory_vscode_extension.md` — features `F-*` | 321 | 321 | 0 | 0 |
| `inventory_vscode_extension.md` — gaps `vx:G-*` | 18 | 18 | 0 | 0 |
| `inventory_webwork.md` — comparison `ww:R*` | 24 | 24 | 0 | 0 |
| `inventory_webwork.md` — further needs `ww:N-*` | 25 | 25 | 0 | 0 |
| `inventory_webwork.md` — questions `ww:PQ-W*` | 6 | 6 | 0 | 0 |
| `inventory_ai_runtime_quest.md` — `AR-*` | 84 | 84 | 0 | 0 |
| `inventory_ai_runtime_quest.md` — `V2-*` | 29 | 29 | 0 | 0 |
| **Total** | **507** | **507** | **0** | **0** |

Ids in § 2 that are no finding of an inventory: none.

**Rulings:** apply B1 (covered extension rows) 200; retiring rule 5; in the tables apply 147, ask 99, settle 5, drop 51 — 507 in all.

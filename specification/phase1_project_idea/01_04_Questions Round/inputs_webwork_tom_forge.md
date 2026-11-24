# Inputs from the quests `webwork` and `tom_forge` — Phase 1, question round 4

Further input for `../project_idea.ai_runtime.md` (called "the Project Idea" below), collected on
2026-11-20 for the product owner's instruction of this round ("check what todos and planning
documents are in … webwork, tom forge … and look for further input").

## What was read

- **The Project Idea:** the headings; `USR`, `SCO`, `LAND`, `RT-HOLDS` … `RT-TRANSPORTS`,
  `RT-INSTALL`, `RT-PROTO`, `RT-HOST`, `RT-TOOLS`, `RT-MCP`, `CLI` (all four parts), `TAC-PEOPLE`
  (start, PQ-30), `TAC-KINDS` … `TAC-WEBWORK`, `NFR`, `NFR-GEN`, `DEL`; the rest by search. The
  answers of this round (`answers.md`), and the snapshot `sources/webwork_requirements.md` (S3).
- **`_ai/quests/webwork/`:** the open todos of `todos.webwork.todo.yaml` (191; read in full: the
  groups `12a_woneb*`, `13_woneb*`, `14_woneb*`, `06_woneb5/6/8/9/11`, `09_woneb2…5`,
  `10_woneb1/4/5`, `03_woneb6`, `qavs_*`, `wwremind1`, `wwaspect1`, `qr47`); the archived todos
  completed 2026-11-10 … 2026-11-20 (43, listed; none adds a requirement beyond the documents
  below); the idea `ideas/webwork_redesign/webwork_redesign.docspecs.md` (changed 2026-11-20:
  part-bottom-panel, part-review, part-messaging, part-forge-investigation, part-wave-plan, the
  decisions DPPHONE-*, DPMESSAGING-*); `webwork_wave1_plan.md`,
  `study_webwork_shell_on_forge.webwork.md`, `webwork_on_forge_kit.webwork.md` (all 2026-11-20);
  `md_browser_probe.webwork.md` (*Result*, 2026-11-19); `overview`, `deferred`, `quest_refresh`
  by search. The specifications D13 amended, D39 and D40 are **not written yet** (todos
  `12a_woneb1`, `03_woneb13/14`, `12a_woneb2`); what they will say is taken from those todos.
- **`_ai/quests/tom_forge/`:** `overview.tom_forge.md`, `spec_quest_workbench.tom_forge.md`
  (part two is a placeholder), `tom_forge_componentization.md` (2026-11-20, by search),
  `reusable_ui_scan.tom_forge.md`, `decisions.tom_forge.md` (2026-11-19); the open todos (63; read
  in full: `qavs_*`, `later23`, `later25`, `05b_woneb1/2/5/6/7/8`, `wwkit3`, `wwkit4`,
  `06a_flutterm1`); the archived todos completed 2026-11-10 … 2026-11-20 (75, listed; read in
  full: `02b_woneb8`, `tdmgroups7`).
- **Checked on disk:** `tom_ai/modules/` (the packages `tom_agentic_ui` 0.1.0, `tom_ai_trail_ui`
  0.1.0, `tom_todo_ui` 0.2.0, `tom_todo_model` 4.2.0), `tom_forge/` (package list).

Each finding was checked against the Project Idea by search before it was listed. Kinds:
**missing** (the Project Idea says nothing), **differs** (it says something else), **vague** (it
touches the point without settling it), **confirms** (same statement; listed only where the
source adds a detail or an obligation). Nothing below is inferred beyond what the cited source
says; where a check was not possible it says *unverified*.

**General result.** Both quests were already aligned with the concept on 2026-11-19 (their todos
carry notes "from ai_runtime, concept § 7.10"). No source in either quest gives a date for the
runtime; the only ordering is in WW-22. The findings are mostly about (1) the review component,
which both quests now plan outside this product, (2) Flutter packages that already exist and the
Project Idea does not mention, (3) what a host gets for messaging through the runtime, and
(4) the server side for the web and phones, where both quests have plans that the product owner's
answer to PQ-28 changes.

---

## Webwork

### WW-1 — the review component is built in the `tom_forge` quest, in two forms, not in `tom_ai_runtime_ui`

- **Source:** `md_browser_probe.webwork.md`, *The user's decision* (2026-11-19): both routes are
  built — route 1, the extension's MD Browser page hosted in a webview (`app_webwork/tom_md_browser`,
  todo `09_woneb5`, page bundle published by vscode_extension `04c_woneb2`), and route 2, a new
  Dart MD Browser component (tom_forge `05b_woneb1` … `05b_woneb5`, working name
  `tom_md_browser_editor`, in the `tom_forge` repository, depending on `tom_som_dart_runtime` and
  `tom_forge_shared_ui`). TomSpecs YAML is reviewed in a third thing, the TomSpecs editor taken
  out of Forge (tom_forge `05b_woneb6`, `05b_woneb7`). The idea's part-review names the users of
  route 2: "Webwork, Tom Forge's quest applications and the runtime remote-control application".
- **Project Idea:** CU.6 lists a group **Review** in `tom_ai_runtime_ui`; CU.9 "one Flutter
  component, shared by Webwork, Tom Forge's quest application and trc"; SC-18; CK.2; CU.3 and
  N-25 (no dependency on Tom Forge); the answer to PQ-30 ("the review application will never be
  part of the ai_runtime project").
- **Kind:** differs.
- **Proposal:** Take the review component out of `tom_ai_runtime_ui` (CU.6, CU.9, SC-18 →
  "host's own / supplied by the tom_forge quest") and state in CK.2 that trc embeds the component
  the tom_forge quest builds. **Question for the product owner:** does trc depend on that
  component although it uses `tom_forge_shared_ui` (CK.7 allows Forge packages for trc), or does
  trc open review documents in another application?

### WW-2 — a review round of Webwork documents is created, stored and merged by Webwork, not by the runtime

- **Source:** todo `09_woneb3` and the idea's part-review: the round folder (`round.yaml`, base,
  one copy per member, `merged/`) lies "in the documents' own storage (a local folder or a GitHub
  repository)"; Webwork creates it and merges through `tom_som_dart_runtime`'s merge API; copies
  of Webwork items travel as `.webwork.zip` part bundles and are merged by UUID (D1 § 8.3).
- **Project Idea:** CV.12 step 1 "The coordinator's **runtime** creates the round folder"; CV.13
  "It lies beside the documents, in version control"; CR.5 (team review rounds are in the
  runtime).
- **Kind:** differs.
- **Proposal:** CV.12/CV.13: the round folder is created and merged by the coordinator's runtime
  *or by the coordinator's application* (for document kinds the runtime does not know); it lies
  in the documents' storage, which is usually but not always version control. tac stays the
  transport in both cases.

### WW-3 — "review set" means two things

- **Source:** todo `09_woneb2`: a review set is "a small YAML file in the documents' storage"
  naming files, Webwork documents and sections and TomSpecs documents, with rounds under it.
- **Project Idea:** CV.5: a review set is "a named set of files, pinned for a review" in tac.
- **Kind:** vague (one word, a stored definition in one place and a set of pinned blobs in the
  other).
- **Proposal:** Say in CV.5 that tac's review set is the pinned blobs of one round of an
  application's review set, and that the definition of what is under review is the
  application's; or give tac's record another name.

### WW-4 — what a host gets for messaging through the runtime is not stated

- **Source:** todos `13_woneb6` … `13_woneb10` (notes of 2026-11-19: "Only through a runtime:
  Webwork has no direct tac connection. On the desktop the messaging client talks to tac through
  Webwork's local runtime"). Webwork needs: conversations by newest activity with unread counts,
  history in pages, live arrival, read state, mute, threads attached to a document or round,
  blob upload and download with the size limit known before sending, extending and releasing a
  round's blobs, the team's members.
- **Project Idea:** CP.3 lists the protocol's commands without messaging ("… review rounds;
  coordination; calling a tool"); CP.4 lists no message event; CL.5 gives messaging only to the
  tac client SDK's convenience layer; CT.1 has messaging as runtime tools for agents; CL.11 and
  CI.4 say an application reaches tac through its runtime.
- **Kind:** missing.
- **Proposal:** Add to CP.3/CP.4 and CL.5 the messaging and document commands and events a host
  uses through the runtime client SDK (conversations, history, send with request id, read state,
  mute, members, blobs with limits, review request and return), so WR-4 and WR-5 are met for an
  application that has no tac client of its own.

### WW-5 — where the conversation cache and the outbox live

- **Source:** todo `13_woneb6`: "The conversation cache on the device; the outbox kept
  device-local like the D3 § 4 journal, each send with its request id, retried when the server
  answers; the cached history read-only while the server is unreachable"; `13_woneb7`: "search
  across the cached conversations".
- **Project Idea:** CM.9 and CM.13 speak of "a tac client that was offline" catching up and
  resending "what waited in its outbox"; with CL.11 the tac client is inside the runtime, and
  nothing says whether the runtime keeps a cache and an outbox for its host or the host does.
- **Kind:** vague.
- **Proposal:** Decide and state it in `TAC-CONV` or `RT-MACHINE`: either the runtime keeps the
  cache and outbox of its user (one per machine and user, shared by the hosts) and offers search
  over it, or each host keeps its own and the runtime only passes through. **Question for the
  product owner** (it decides whether Webwork's `13_woneb6` builds a cache at all).

### WW-6 — what an unreachable tac server means for a runtime that only uses messaging

- **Source:** idea part-messaging, *Edge cases*: "The server unreachable: the area keeps the
  cached history read-only, says why, and keeps outgoing messages in the outbox." S3, "What
  Webwork does not need": leases and claims.
- **Project Idea:** CA.32 / N-12: "When the backend cannot be reached … the queues of the team
  runtimes stop after their current todo"; CA.31: coordination `mode: off` is the default.
- **Kind:** vague.
- **Proposal:** State that CA.32 concerns runtimes that take claims; a runtime without a quest
  (Webwork's own AI) keeps its queues running when the tac server is unreachable, and messaging
  then works from cache and outbox. Say also whether messaging can be on while coordination
  (`mode`) is off.

### WW-7 — the instance name `webwork-app` and how a quest-less runtime appears in tac

- **Source:** todo `qavs_collab_b-1_akmt` (webwork): the runtime registers "as quest
  `webwork-app` with `hasQuest: false`; it may take part in the claims"; S3, WR-2 and WR-7; todo
  `13_woneb1`.
- **Project Idea:** CR.6, CR.29, T2 ("one without a quest for Webwork's own AI"); no name, and
  `TAC-COORD` does not say how a runtime without a quest registers, what its home team is
  (CI.2: "each coordinates in the home team of its quest") or whether it shows among the team
  runtimes in trc.
- **Kind:** vague.
- **Proposal:** Add an item to `TAC-COORD`/`TAC-GROUPS`: a runtime without a quest registers
  under its application's name, belongs to the team its user chose for that application, and is
  listed as such in the supervision.

### WW-8 — an application publishing an endpoint of its own

- **Source:** todo `qavs_collab_b-1_akmt` (webwork): Webforge's webwork runtime "does not publish
  the runtime's MCP server but may publish a Webwork MCP endpoint of its own for remote control
  of and interaction with Webwork".
- **Project Idea:** CA.23: "A runtime publishes the endpoints it serves — its MCP server, its
  remote control"; CT.13.
- **Kind:** vague (an endpoint served by the host, not by the runtime, is not covered).
- **Proposal:** Extend CA.23: a runtime can also publish an endpoint its host serves, declared
  through the host interface, with the same record. Or state that this is not offered.

### WW-9 — Webwork prompts that belong to a quest folder

- **Source:** todo `12a_woneb1` and idea part-bottom-panel: "Webwork's own AI is the runtime
  instance that serves no quest (`webwork-app`); a run bound to a quest folder (D13 § 12.8's
  quest sessions) runs in that quest's instance."
- **Project Idea:** T2 names only Webforge with "one runtime process per open quest plus one
  without a quest"; nothing says that standalone Webwork starts or attaches to a quest's
  runtime.
- **Kind:** missing.
- **Proposal:** Add to T2 / CR.6 that one host may hold the quest-less instance and quest
  instances at the same time, and that a host other than a workbench may start a quest's
  runtime. **Question for the product owner:** is this wanted for standalone Webwork, which
  otherwise has no quest-folder integration (webwork `qavs_wwworkbench-2`)?

### WW-10 — the review option of a run: kept by whom

- **Source:** idea part-bottom-panel, *Review per run*: "**Review each prompt** or **Work
  silently**, kept per run as device state"; "Every run starts with Review each prompt"; todo
  `13_woneb2` ("device state, starting in Review").
- **Project Idea:** CR.17: "A run has an option, kept by the runtime".
- **Kind:** differs (small).
- **Proposal:** Keep CR.17 (the runtime needs the option to hold the queue) and add the default:
  a new run of an application's own AI starts in *review each result*; tell webwork that the
  option is the runtime's, not device state.

### WW-11 — the Agent SDK mode has no user left in Webwork's plan

- **Source:** todos `06_woneb9` (wave 1b1 keeps today's AI: `tom_ai_trail_ui` over the D13
  sessions of `tom_llm` / `tom_core_agentic`) and `13_woneb4` (wave 1b2: "the D13 sessions' own
  transports removed from the desktop roots where the runtime replaces them"); `13_woneb1`
  (Webwork uses the full instance `webwork-app` with runs and queues).
- **Project Idea:** CR.29 and D-16: a mode "that offers only the agent transport of the Claude
  Agent SDK to a host, without a quest, so an application ships one Node payload".
- **Kind:** vague.
- **Proposal:** **Question for the product owner:** with Webwork on the full quest-less instance
  in wave 1b2, is the Agent-SDK-only mode still a requirement (for whom), or does CR.29 reduce to
  "the quest-less instance offers every transport, and the Agent SDK server of today is retired"?

### WW-12 — the messaging components must take a host's own attachments and card actions

- **Source:** todos `13_woneb7` … `13_woneb9`: the composer's Attach (a file, an item, a section,
  a document) and Paste; the three forms; the received copy's card with **Open**, **Save into…**,
  **Merge**, **Remind me** / **Make todo**; a narrow form in the right panel and the full area;
  the phone's two screens; a conversation attached to a document or round "shows it at the top
  with Open"; states for expired blobs and unreachable references.
- **Project Idea:** CU.6 Messaging: "conversation list, conversation, composer, document card,
  review request card, reminder, people"; CM.3 (free payload "for what an application shows as a
  card"); CV.9 (states an application shows); CU.15 (three widths).
- **Kind:** vague. No webwork todo says whether the Messaging area is built from
  `tom_ai_runtime_ui` or by Webwork itself (*unverified*: D40 is not written).
- **Proposal:** Add an item to `CLI-UI`: the messaging components take attachment kinds, card
  kinds and card actions from the host, and offer the list, the conversation and the composer as
  separate components so that a host can lay them out narrow, full or as two screens.

### WW-13 — arrivals without an outside push service; what "pushed to a device" means

- **Source:** decision DPPHONE-4 and idea part-messaging: on the phone "a new message arrives
  while the app runs or when it syncs on start and resume (no outside push service, as for
  reminders)"; "a push service is filed for later"; todos `06_woneb6`, `10_woneb4` (local
  notifications only).
- **Project Idea:** CM.6 "A notification is not pushed to a device while its user is active on
  another one; after a time without a reaction it goes on to the next channel"; CK.11 (trc on a
  phone is for "answering questions while away"); no mention of the operating systems' push
  services.
- **Kind:** vague.
- **Proposal:** **Question for the product owner:** does the first version use the platforms'
  push services (APNs, FCM) for asks and messages on a phone, or does a phone learn of them only
  while the application runs and on start and resume, as Webwork decided for itself? Name the
  channels of CM.6 accordingly.

### WW-14 — where the team token and the messaging account are kept

- **Source:** todo `13_woneb6` (note of 2026-11-19): "redeeming it gives a team token per person
  and team, kept in the settings container"; the account (user id, e-mail, server address) shown
  and signed out in Webwork's Account area.
- **Project Idea:** CS.11 and N-17: team tokens "are kept as secrets in the same way" (as secret
  references, resolved through Tom Secrets Manager); CP.13 lists what the host interface
  supplies, without credentials.
- **Kind:** differs.
- **Proposal:** State which holds: the runtime keeps the user's team tokens (one place per
  machine and user for every host, and Webwork's Account area shows them through runtime
  commands), or a host may supply a secret to its runtime through the host interface. Tell
  webwork the result before D40 is written.

### WW-15 — two people with one e-mail address

- **Source:** idea part-messaging, *Edge cases*: "Two people with the same email, or one person
  with two ids: without authentication tac cannot tell; the members list shows both entries with
  their ids"; todo `13_woneb6` ("duplicates shown with their ids").
- **Project Idea:** CI.10 / N-19 (open server: stated identity is believed); N-22 (ids generated
  on redeeming an invitation); nothing on duplicates.
- **Kind:** missing (small).
- **Proposal:** Add to `TAC-PEOPLE`: on an open server the member list can hold two entries with
  one e-mail address; tac returns both with their ids and does not merge them.

### WW-16 — the anchor of a message is written two ways in Webwork

- **Source:** todo `13_woneb9` and `12a_woneb2`: `msg:tac/<server-group>/<messageId>`; the idea's
  part-messaging (updated): `msg:tac/<team>/<messageId>`.
- **Project Idea:** CM.12: `msg:tac/<team>/<messageId>`.
- **Kind:** confirms (the idea), differs (the two todos, which are older).
- **Proposal:** No change here; tell webwork with the message of WW-22 that `<team>` is the
  form. The anchor is stored in items from wave 1b1 on, so it must not change later (N-7).

### WW-17 — web and phone builds of Webwork have no AI and no messaging until the server side exists

- **Source:** decision DPPHONE-5; todos `06_woneb9`, `13_woneb1`, `13_woneb5` ("Absent where
  Webwork has no AI (web, phone)"), `10_woneb1` (the mobile root leaves out the AI transports);
  idea part-wave-plan, *Later todos*: "AI on the web and on the phone through a server-side AI
  runtime, with the ai_runtime quest's runtime server (wave 3, where Webwork first depends on
  running services)".
- **Project Idea:** L-8 and T8: "in a later wave of Webwork"; WR-6 row of `TAC-WEBWORK`.
- **Kind:** confirms, with a detail the Project Idea lacks: Webwork names **wave 3** and expects
  the same server side to carry AI *and* messaging.
- **Proposal:** Name wave 3 in L-8; see the section on the web runtime service below.

### WW-18 — a business reviewer needs desktop Webwork in the first version

- **Source:** todo `13_woneb10` (note): "Reviewers on the web, the phone or the tablet join with
  the server-side runtime of a later wave; in wave 1b2 messaging review is desktop to desktop."
- **Project Idea:** CV.15: "A reviewer who has access to no repository needs only an application
  with the review component and an identity in tac"; CV.5 (a reviewer outside the VPN); U-2.
- **Kind:** vague.
- **Proposal:** Add to CV.15 what that application is in the first version (per the answer to
  PQ-30: the VS Code extension today, then Webwork and Webforge on the desktop; a web version
  later), so U-2's reach is stated honestly.

### WW-19 — existing Flutter AI views in `tom_ai/modules` are not mentioned

- **Source:** tom_forge `02b_woneb8` (completed 2026-11-20): `tom_ai/modules/tom_agentic_ui`
  0.1.0 holds the chat composer, placeholder preview, prompt trail and queue views with their
  controllers, the agent connection picker, send panel, reconnect banner, change log and change
  review panels, over `tom_core_agentic`. Webwork todo `06_woneb9` (note): `tom_ai_trail_ui`
  (`TomAiTrailView` over `tom_llm`) is today's trail panel; "When the AI tab takes
  `tom_core_agentic` sessions … these views are the ones to take". `13_woneb4` retires
  `TomAiTrailView` from the desktop roots.
- **Project Idea:** E-10: "no Flutter component of the runtime's user interface exists"; CU.5:
  the basis of each component is what the extension shows; neither package is named anywhere.
- **Kind:** missing.
- **Proposal:** Add to `LAND-BUILT` that two Flutter packages with agent views exist over other
  backends (`tom_agentic_ui` over `tom_core_agentic`, `tom_ai_trail_ui` over `tom_llm`), and say
  in `CLI-UI` what becomes of them: input for the components, replaced by `tom_ai_runtime_ui`,
  or kept for applications without a runtime. **Question for the product owner** which.

### WW-20 — the todo fields the two hosts must share have moved on

- **Source:** todos `wwremind1` (reminder fields `remind`, `next_remind`, `remind_count`,
  `tom_todo_model` 4.1.0) and `wwaspect1` (fields `role` and `guidelines`, `tom_todo_model`
  4.2.0, "uniformity rule: what one supports, the other supports"); `tom_todo_model` is 4.2.0 on
  disk, with `TomItem` since 4.0.0.
- **Project Idea:** E-2 and R-18: "`tom_todo_model` 3.1.0 … a further major release planned";
  CR.1 (one implementation of the formats).
- **Kind:** differs (the version), missing (the rule).
- **Proposal:** Correct E-2 and R-18 to 4.2.0. Add to `NFR` (compatibility): a todo field the
  runtime writes exists with the same meaning in `tom_todo_model`, which Dart applications use
  to write the same files (see TF-9).

### WW-21 — Output channels of the application on the bounded Markdown view

- **Source:** todos `06_woneb8` (wave 1b1: a bounded text view of Webwork's own) and `13_woneb4`
  (wave 1b2: every Output channel — Scripts, Webwork, Sync, AI transport — on the runtime's
  component, "the per-channel bounds kept").
- **Project Idea:** CU.7: "It serves a run's log and an application's own log channels."
- **Kind:** confirms, with one detail: the bound is set per use by the host, and the view takes
  text that does not come from a runtime.
- **Proposal:** Add to CU.7 that the component works without a runtime connection and that the
  host sets its bound.

### WW-22 — what the ai_runtime quest owes webwork, and the only ordering there is

- **Source:** `webwork_wave1_plan.md` (2026-11-20): "Wave 1b2 starts after the wave-1b1 release
  (`11_woneb3`) and assumes the ai_runtime quest has finished the runtime by then"; "No
  ai_runtime todo is in this plan"; the notes on `12a_woneb1` … `14_woneb2`: "ai_runtime tells
  webwork which todos cover each requirement once they are filed, and again when the runtime is
  fully built. Do not start this todo before that first message." `14_woneb2`: wave 1b2 is
  released once, with the AI run tabs and messaging together. Several `blocked_by` entries still
  name `ai_runtime/12b_woneb1…3` and `ai_runtime/tac_webwork-6`.
- **Project Idea:** `DEL`: "the entries of other quests that wait on them follow"; E-15.
- **Kind:** vague. No date is given anywhere in the webwork quest.
- **Proposal:** Add to `DEL` the two messages as deliverables of the todo filing: the map
  WR-1 … WR-7 → covering todos sent to webwork when the todos are filed, and a second message
  when the runtime is complete; and that D13 (amended) and D40 are written against the runtime
  protocol specification and `tac/2.0`, so those two documents are needed by webwork before the
  code.

---

## Tom Forge

### TF-1 — part two of the quest workbench specification waits for this specification and holds outdated choices

- **Source:** `spec_quest_workbench.tom_forge.md`, part two (placeholder chapters 5 … 10), and
  todo `qavs_wwworkbench-1` (decision-needed): the runtime client "in `tom_forge_quests`" /
  "a BSD-3 package beside the quest views in the Forge repository"; a Telegram decision still
  open; `serve --workspace <root> --quest <id>`; the MCP server "port 19920 upward … the
  read-only set without the key, all tools with it".
- **Project Idea:** S14 is marked "outdated in the runtime's name and the quest it belongs to";
  CL.3 (the client is `tom_ai/ai_build/tom_ai_runtime_client`); L-9 (Telegram later); CT.12 (the
  MCP server asks for a bearer token); CT.11 (only tools on `_ai`).
- **Kind:** differs (in the source, not here).
- **Proposal:** No change of content. Add to `DEL`, beside WW-22, a message to tom_forge when the
  todos are filed: the client's package and place, Telegram deferred (its open decision falls
  away), the MCP server's token rule, and the `blocked_by` entries to re-point (TF-14).

### TF-2 — Copilot and the VS Code-bound tools through a running VS Code window

- **Source:** todos `qavs_ccparity_d_claudecode-2` ("Copilot through the CLI bridge to a running
  VS Code window … absent when none runs") and `qavs_wwworkbench-5` (the user's decision (a):
  Forge answers editor tools itself where it has the concept and forwards the rest — commands,
  tasks, debug, notebooks, Copilot, VS Code LM — "to a running VS Code window through the CLI
  bridge (`tom_vscode_scripting_api`)"; "The same choice covers the two transports only VS Code
  has").
- **Project Idea:** O-4 and CR.26: host transports are removed, Copilot only through direct
  calls and its SDK; CT.1 (host tools are carried out by the host that registered them); CL.10
  (scripts keep working against a VS Code window); CP.15 (a host refuses what it has no concept
  for).
- **Kind:** differs for the transports (settled: there are none to forward); vague for the
  tools.
- **Proposal:** State in `RT-TOOLS` whether a host may answer a host tool by forwarding it to
  another host's window (Forge → VS Code over the script server), or whether such a tool is
  simply absent in a host without the concept. **Question for the product owner**; the Forge
  decision (a) predates O-4.

### TF-3 — host tools through the runtime's MCP server

- **Source:** todo `qavs_none-3`: enable the runtime's MCP server for Forge's runtimes "with Tom
  Forge's host-provided tools and Webwork's D35 tools reachable through it", and "coordinate
  ports and the server card when a VS Code window and Tom Forge serve the same workspace".
- **Project Idea:** CT.11 and N-18: the MCP server "offers the runtime tools on `_ai` … and
  offers no access to files or an editor"; CT.1: host tools are offered to "the transports of
  the run or prompt they are registered for".
- **Kind:** differs.
- **Proposal:** Keep N-18 and tell tom_forge that host tools are not reachable through the
  runtime's MCP server (an application that wants its tools reachable publishes an endpoint of
  its own, WW-8). Add to `RT-MCP` how several runtimes on one machine get their MCP ports (the
  Project Idea names no port rule).

### TF-4 — Node for a host that is not VS Code

- **Source:** todo `qavs_wwworkbench-3`: Forge starts the runtime "with the Node the packaging
  names (D13 § 2.3's Node discovery and floor, the same install the standalone AI transport
  uses)"; "a missing or too-old Node is reported with the remedy rather than a hang".
- **Project Idea:** N-24 (the runtime is a Node program); CR.40 … CR.42 (the installation, with
  the provider SDKs beside it); CP.2. Nothing says where Node comes from outside VS Code, which
  version is the floor, or what a host is told when it is missing.
- **Kind:** missing.
- **Proposal:** Add an item to `RT-INSTALL`: whether the shared installation brings its own Node
  or uses the machine's, the lowest version, and that "find or start the installed runtime"
  (CL.5) reports a missing or too-old Node as such. **Question for the product owner:** bundled
  or discovered.

### TF-5 — supervising a runtime process: death, restart, background work

- **Source:** todo `qavs_wwworkbench-3`: a process that dies "is reported in the quest
  application with its last stderr lines and restarted on request, with the event stream
  resubscribed and the views refreshed from the runtime's state"; "No runtime process outlives
  Tom Forge" (checked by pid). `spec_quest_workbench.tom_forge.md` § 3: an application "reports
  background work while its queue or a timer runs", and closing it or quitting is then "a
  question with the reason".
- **Project Idea:** CP.2 (ready line, ends when standard input closes, log on standard error);
  CR.44; CP.5/CP.6 (reading on after number N); CR.23 (a run's states). Not stated: what the
  runtime client SDK does when the process dies, and a way to ask a runtime whether closing it
  now would stop work (a running item, a waiting timed request or reminder).
- **Kind:** vague.
- **Proposal:** Add to CL.5 "supervise the runtime it started: report its exit with the last log
  lines, restart, resubscribe", and to CP.3 a command that answers what is running or scheduled
  in the instance, for a host's quit question.

### TF-6 — at most one runtime per quest inside one host

- **Source:** `spec_quest_workbench.tom_forge.md` § 3: "At most one quest application per quest
  … (two applications over one quest would run two runtimes over one `_ai` folder, which the
  runtime's claim rules refuse)"; todo `qavs_none-1` (the end-to-end scenario with VS Code and
  Forge on the same quests: a process advanced from both, a session continued from the other
  side, timed requests and inbox items crossing over).
- **Project Idea:** N-10 and T2: "Two hosts can work on the same quest at the same time";
  `TAC-COORD` line "One quest may have several runtimes".
- **Kind:** vague (Forge reads the claim rules as refusing a second runtime on a quest; the
  Project Idea allows several).
- **Proposal:** State in `PAR` or `RT-MACHINE` what two runtimes on one quest share and what the
  second is refused (each run is driven by one runtime at a time; the other attaches as a
  reader, or takes it over), and take the scenario of `qavs_none-1` as the acceptance case of
  N-10.

### TF-7 — a third application built on Forge hosts runtimes: the TomSpecs editor

- **Source:** `spec_quest_workbench.tom_forge.md`, introduction: "Every app built on Forge's
  composition library (`composeForgeSuite`) has the quest applications: Tom Forge's own app, the
  TomSpecs editor and Webforge."
- **Project Idea:** U-9 and `VIS-SYSTEM` name Webforge / Tom Forge; U-12 names TomSpecs as a
  user of processes and tools, not as a host application.
- **Kind:** missing (small).
- **Proposal:** Name in U-9 that every application composed from Forge is such a host, the
  TomSpecs editor among them.

### TF-8 — Forge's own view packages and the todo editor against the component groups

- **Source:** todo `qavs_ccparity_d_claudecode-1`: "Build those views [chat composer, prompt
  queue, prompt trail, agent settings, tool surface, change log and three-way review] over the
  shared quest runtime through its Dart client" in `tom_forge_agentic`, used by the quest
  applications and the TomSpecs editor; todos `qavs_ccparity_e_process-4` and
  `qavs_wwworkbench-8`: the Quest TODO views are "Webwork's todo-file editor" (`tom_todo_ui`,
  `tom_ai/modules`), which offers Send and Queue "through a host capability of
  `TomTodoFileEditorHost`".
- **Project Idea:** CU.3: "Tom Forge's own view package is built on top of it and keeps only
  what binds the components into the Forge shell"; CU.6 group **Todos** ("todo list and tree,
  todo editor, decisions, session todos, todo log, the panel across quests", starting from the
  extension's panels); CU.1.
- **Kind:** differs (Forge's todos still build the views themselves; they predate CU.3) and
  vague (two todo editors: the existing `tom_todo_ui` over `tom_todo_model`, and the Todos group
  over the runtime client).
- **Proposal:** Say in `CLI-UI` whether the Todos group is built on `tom_todo_ui` (and
  `tom_ai_runtime_ui` may depend on packages of `tom_ai/modules`), or beside it; and tell
  tom_forge that `qavs_ccparity_*` embed the components instead of building views (the message
  of TF-1).

### TF-9 — Dart code keeps writing three `_ai` formats

- **Source:** todo `qavs_wwworkbench-6`: the Dart side keeps "(1) `*.todo.yaml` files —
  `tom_todo_model`'s `TomTodoFile` …; (2) the decisions journal `decisions.<quest>.md` …;
  (3) `live-trail.<session>.md` — `tom_llm`'s `LlmTrailFileWriter`"; it asks for "the runtime's
  own conformance fixtures … the files the runtime writes for a given operation" and for the
  runtime's concurrency rules ("the lost-write re-read and the `<prefix>*` walk claim") to be
  stated so that a Dart write cannot lose a runtime's.
- **Project Idea:** CR.1: "The runtime is the one implementation of the `_ai` formats"; CL.6 (a
  conformance suite for the client SDKs against a running runtime); N-8 (state of the machine).
  Nothing on format fixtures for other writers.
- **Kind:** differs.
- **Proposal:** Qualify CR.1 (the runtime is the reference; `tom_todo_model` writes todo files
  and the decisions journal for applications without a runtime) and add to `NFR` (testing): the
  runtime publishes format fixtures per operation, and the rule a writer outside the runtime
  follows to write a todo file a runtime may be walking.

### TF-10 — repository quests need commands and components; a web workbench needs working copies on the server

- **Source:** todo `qavs_wwwgitruntime-1`: the workbench's UI for repository quests — member
  branch state, Publish and Update, the publish dialog, conflict review, creating and joining a
  repository quest, the migration with its dry run, the key prompt for `<quest>_internal`'s
  credentials. Todo `later23` (decided 2026-11-12, option (a)): for a later web build of the
  quest workbench "the server side of the shared quest runtime … keeps a working copy per member
  branch for its users and runs publish / update / review, the merge drivers, the secret scan
  and the KDBX unlock through the same runtime API … It commits and pushes through a GitHub App
  installed on the quest repositories, with the member as author."
- **Project Idea:** `PAR-QUESTS` (`CQ`); CU.6 has no component for repository quests; CR.46 and
  T8 say a runtime host server "starts one runtime per connected application" and nothing about
  where that runtime's workspace and working copies are.
- **Kind:** missing (the components; the working copy on a server). The approach to repository
  quests itself is being revised in the al_the_bear quest per the answer to PQ-24 — not checked
  here.
- **Proposal:** Add a component (or a "host's own" line) for repository quests to CU.6/CU.11,
  and an item to CR.46: a runtime on a server that serves a quest needs a working copy there;
  who creates it, per user, and with which git identity is to be decided (`SCO-LATER` if not in
  the first version).

### TF-11 — trc on Forge packages: what builds where

- **Source:** idea part-forge-investigation (webwork): "There is no phone build of Tom Forge.
  Forge is a desktop application"; "Webforge is desktop-only (decision D-D37-2, because the
  quest runtimes are local Node processes)". `study_webwork_shell_on_forge.webwork.md`, the
  product owner's answer of 2026-11-20: Webforge holds "one application per quest, the remote
  control app as an application + the normal forge shell". tom_forge `wwkit3`: `tom_forge_shell`
  "builds for iPad and Android tablets"; "Phones stay out of scope: below 600 lp a host shows
  its own phone layout". `decisions.tom_forge.md`, `forgeinv9` (2026-11-19): the dart:io and
  file-picker parts leave the shell core (`tom_forge_desktop_host`) "so the core builds for the
  web".
- **Project Idea:** CK.7 (trc is a Webforge application and runs standalone; "it may depend on
  packages of Tom Forge"); CK.10 (phone and tablet in the first version); CU.15 (three widths).
- **Kind:** confirms CK.7; vague on what the phone build of trc may take.
- **Proposal:** Add to CK.7/CK.10: the phone layout of trc is built from `tom_ai_runtime_ui`'s
  phone-width screens without Forge's panel shell; the tablet and desktop builds may use
  `tom_forge_shell`.

### TF-12 — Flutter 3.50 and `material_ui`

- **Source:** todo `06a_flutterm1` (tom_forge, filed 2026-11-18) and webwork `05a_flutterm1`,
  `06b_flutterm1`: every Flutter project moves to Flutter 3.50 / Dart 3.14 and to
  `package:material_ui` / `package:cupertino_ui` ("we go all in on 3.50"); the todo warns that
  in-SDK and standalone types may be distinct, so a library and every package passing Material
  types to it move together.
- **Project Idea:** N-25 and CU.1 … CU.4 name no Flutter version or widget library.
- **Kind:** missing.
- **Proposal:** Add to N-25: the components are written for the Flutter version and the widget
  libraries (`material_ui`, `cupertino_ui`) the hosts are on, since a component and its host
  must share those types.

### TF-13 — the licence rule the hosts enforce reaches the dependencies

- **Source:** `spec_quest_workbench.tom_forge.md` § 4: "no package in its resolved graph may
  carry a licence that binds the app (`qim_none-1` keeps it so with a test)"; webwork idea
  part-messaging: "Only BSD-3- or MIT-licensed components enter it; nothing with a copyleft
  licence is integrated"; todo `13_woneb6`: "the client's licence checked".
- **Project Idea:** N-29: "The packages are BSD-3"; nothing on what they may depend on.
- **Kind:** missing.
- **Proposal:** Add to N-29: the Dart client SDKs and `tom_ai_runtime_ui` take only
  dependencies without a copyleft licence, because Forge and Webwork test their resolved graph;
  say whether the same holds for what the runtime installs (npm packages, provider SDKs) —
  *unverified* whether the hosts' tests look at those.

### TF-14 — the entries of tom_forge that wait on ai_runtime todos

- **Source:** `blocked_by` of the open tom_forge todos: `ai_runtime/ww_d_workbench-9`
  (runtime server and protocol), `-10` (packaging), `-11` (two hosts, one quest),
  `ww_b_workbench-7` (tools and MCP server in the runtime), `ww_e_gitruntime-3/-10/-11`,
  `ww_f_collab-1/-3`; in webwork also `ww_c_collab-3`, `ww_f_collab-2`. The plan
  (`webwork_wave1_plan.md`, phase 1b2.1 … 1b2.4) places the whole quest workbench in wave 1b2,
  "the runtime assumed complete".
- **Project Idea:** E-16; `DEL`, last paragraph (the new set replaces the todos; waiting entries
  follow).
- **Kind:** confirms, with the list.
- **Proposal:** Carry the list into the todo filing as the entries to re-point; no change to the
  Project Idea beyond TF-1's message.

### TF-15 — what the quest applications mirror is wider than the component groups name

- **Source:** todos `qavs_ccparity_b_panels-3` (Send to LLM: an editor's selection into the
  chat's composer with the panel's profile and session), `qavs_ccparity_d_claudecode-4` (the `/`
  completion of commands and skills with argument prompts and expansion "run in the runtime; the
  workbench asks it"; subagent progress in the status line), `qavs_dapieff-1` (usage per send
  and per queue item; an item stopped for lack of credit continued on another profile; "No API
  key" marks), `qavs_ccparity_i_assist-1/-2` (asking through a document; Grill me, Explain,
  proposed answers; choices as buttons that move a process), `qavs_ccparity_h_pi-1` (the profile
  and template editors, the status page's sections).
- **Project Idea:** CR.5 (skills, subagents, slash commands, plan mode); CU.6 Conversation
  ("prompt input with the three send choices, attachments, reasoning, tool card, context and
  usage, model and profile selector"), Asks, Settings; CP.3. Not named: the completion of
  commands and skills as a command of the protocol, subagent progress as an event, the assist
  actions on a document's questions, continuing an item on another profile.
- **Kind:** vague. These come from the extension, which another input of this round covers;
  listed here because tom_forge's todos are the checklist of what a second host needs.
- **Proposal:** Use the `qavs_ccparity_*` and `qavs_dapieff-*` todos as the check of CU.10's
  inventory (each names the extension feature and the data it needs from the runtime), and add
  the four named points to CP.3/CP.4 and CU.6 where the extension's input does not already.

---

## What the "web runtime client SDK" and the "web runtime service" mean for these two quests

The product owner's answer to PQ-28 (2026-11-20T15:46): a runtime cannot run on a mobile device;
a **web runtime service** on a server connects to a runtime there on behalf of the device and
reaches tac from the server as usual; it is HTTP-based and may be one and the same for mobile
applications and for web applications (Flutter or not); a **web runtime client SDK** in Dart and
in JavaScript/TypeScript talks to it. The Project Idea today says "runtime host server" and "the
runtime client SDK against a runtime on a runtime host server" over WebSocket (CR.46, CL.11,
CI.4, T8, L-8, D-27, `TAC-WEBWORK` WR-6).

What the two quests planned, and what changes:

- **Webwork, web and phone (wave 3).** Planned: "a server-side runtime that also hosts the web
  version" (idea part-messaging; notes on `12a_woneb1`, `12a_woneb2`, `13_woneb6`), bringing
  both AI and messaging to the browser root and the mobile app `tom_webwork_mobile`; until then
  these builds have neither (WW-17). With the answer, the browser root and the mobile app use
  the **web runtime client SDK (Dart)**, not `tom_ai_runtime_client`, and the server is the web
  runtime service. Open for webwork, and not answered by the Project Idea: whether the web
  runtime service also serves the web application's files ("also hosts the web version"), or
  only the API — **question for the product owner**.
- **One Dart API or two.** Webwork's plain-Dart messaging service in `tom_webwork_core`
  (`13_woneb6`) and its AI code are meant for "desktop, web and mobile roots". If the desktop
  uses the runtime client SDK and the web and phone use the web runtime client SDK, Webwork
  needs the two to offer the same convenience layer (CL.4 says the convenience layer "is the
  same in every language" — it should also be the same across the two Dart SDKs), and
  `tom_ai_runtime_ui` (CU.1 "over the Dart runtime client SDK", CU.4 "build for … web, iOS and
  Android") must work over either. The Project Idea should state this; otherwise the components
  cannot be used in exactly the builds they are said to build for.
- **Host tools over HTTP.** Webwork's document tools run in the application, inside its undo
  groups (WR-7, CT.4 … CT.6), called back by the runtime as reverse requests. For a browser or a
  phone this callback has to cross the web runtime service. Whether host tools, asks and the
  numbered events are offered through the web runtime service (which needs a stream beside
  plain HTTP requests) is not said by the answer — **to be stated**; without it AI on the web
  could not edit Webwork documents.
- **Arrivals on a phone.** Webwork decided: no outside push service; a message arrives while the
  application runs or on start and resume (DPPHONE-4). The web runtime service is the natural
  place for the opposite choice (WW-13). The runtime behind it "ends with that application's
  connection" (CR.46), so nothing on the server watches for the user while the phone
  application is closed; tac's delivery (CM.6) is the only part that could.
- **Identity and tokens.** Webwork keeps the team token in its settings container (WW-14). On a
  phone the token, or the paired device's key (CI.18), has to reach the web runtime service,
  which starts the runtime that presents the token to tac (PQ-26, answer (a)). Which of the two
  the device holds is part of the still-open security model (CI.19).
- **Tom Forge.** Webforge and Tom Forge are desktop-only and start local runtimes; nothing
  changes for the quest workbench. Its one server-side plan, `later23` ("the web runtime server
  for repository quests", for a later web build of the quest workbench), already uses nearly the
  product owner's name and adds the requirement the Project Idea lacks: a working copy per
  member on the server, with commits through a GitHub App (TF-10). trc, which Forge hosts on the
  desktop, uses the web runtime client SDK on phones (CK.10 would name it instead of "a runtime
  on a runtime host server").
- **Terms to settle in the Project Idea.** Whether "web runtime service" replaces "runtime host
  server" or is the HTTP front of it; whether the web runtime client SDK is a third SDK beside
  the runtime client SDK and the tac client SDK (CL.1/CL.2 count two per language, in nine
  languages; the answer names Dart and JS/TS only); the generation units (a service, two client
  SDKs) in `NFR-GEN`; and L-8, T8, CL.11, CI.4, D-27 and the WR-6 row reworded. Both quests'
  documents say "server-side runtime"; they need the new names with the messages of WW-22 and
  TF-1.

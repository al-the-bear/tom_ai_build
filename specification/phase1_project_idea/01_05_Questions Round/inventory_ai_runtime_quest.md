# Inventory: the ai_runtime quest's todos and documents against the Project Idea, and the second extension (v2)

Input for question round 5 of the Project Idea
`tom_ai/ai_build/specification/phase1_project_idea/project_idea.ai_runtime.md` (called **PI** below).
Written 2026-11-25. Read-only research: nothing else was changed.

- **Section A** maps every open todo group of the quest `ai_runtime` (`_ai/quests/ai_runtime/todos.ai_runtime.todo.yaml`, without the process todos `p1s1r*` and `phaseoq*`) and every quest document to the PI items that cover it. Findings `AR-<n>`.
- **Section B** says what the product owner's decision on a second VS Code extension (v2) changes in the PI and in the `ww_b_workbench-*` / `ww_d_workbench-*` plan, and what is left to decide. Findings `V2-<n>`.

Each finding: **Source**, **PI** (item id with its section chain, quoted where it matters), **Kind** (`missing`, `differs`, `vague`, `confirms`), **Proposal** (item text) or **Question** (options, recommendation). PI quotes were checked with `grep` / `sed` against the file at commit `43eccf23` of `tom_ai/ai_build` (round 4). Anything not checked is marked *unverified*.

## How to read the item proposals

PI items are written `- **CR.5** statement. (sources)`. The highest ids in use: `CR.110, CP.44, CT.17, CA.44, CI.20, CM.14, CV.16, CW.27, CL.12, CU.17, CK.12, CQ.13, CS.20, N-43, L-12, R-29, D-72, X-21, PQ-59`. The proposals below use the next free numbers per group; where two findings propose the same new number, the later is marked "next free".

---

## A. The quest's todos and documents

### A.0 Facts that apply to every finding

1. **The todos are no source of the PI.** S23 is the vscode_extension todo file of 2026-11-20. The PI cites only `ww_a_collab-2/-4/-5` by id; no `ww_b/c/d/e/f/g_*`, `tac_webwork-*`, `12b_woneb*`, `a2a1_*`, `caf_12*`, `xx*`, `ccparity_h_pi-*`, `checks*` or `rca1` id appears in it.
2. **The PI's rule for older todos**, `DEL`: "The todos filed before the concept are input; the new set replaces them, and the entries of other quests that wait on them follow (S1 § 13.4, CQ-20; D-42)". So the todos are not binding, but the features they stand for must be in the PI, or out of scope / later with a reason.
3. **Decisions the product owner answered in todos after the concept are mostly not in the PI** (the `xx*` provider decisions, `ww_e_runtimeapi-1`, `tac_webwork-1/-2`). Each is listed below.
4. **Todo hygiene seen on the way** (no PI matter): several todos still carry old ids in their text (`wwwgitruntimeN`, `wwruntimeapiN`, `collab_c-1/-2`, `collab_d-2`); `ww_g_collab-1` says it is blocked "until that cutover" but its `blocked_by` is empty; `ww_e_runtimeapi-1` has every decision answered but is still `not-started`; `xxmistral3`'s title still says "(if chosen)" although it was chosen.

### A.1 The split and the runtime server: `ww_b_workbench-2 … 7`, `ww_d_workbench-9 … 12`, and their documents

State: `ww_b_workbench-2` not-started; `-3 … -7` blocked in a chain behind it; `ww_d_workbench-9 … 12` not-started, `-9` depends on `ww_b_workbench-7`. Every `ww_b` todo carries the note of 2026-11-04 "blocked until the ccparity groups a to g are done"; `runtime_split_plan.ai_runtime.md` § 1 says those prerequisites are done. Section B rewrites their plan; here only their coverage.

#### AR-1 — The runtime package (`ww_b_workbench-2`)

- **Source:** `ww_b_workbench-2_ajäm-runtime-package-skeleton`: "Create the runtime package `tom_quest_runtime` … in tom_ai/vscode (npm name `@tom/quest-runtime`, RT-1)"; BSD-3; esbuild bundle; a guard test that fails on any `vscode` import; the extension bundles the runtime into its VSIX.
- **PI:** `RT`: "one TypeScript package, `tom_ai/ai_build/tom_ai_runtime`, with no dependency on VS Code"; `DEC` D-1 "The runtime is the package `tom_ai/ai_build/tom_ai_runtime`." (replaces RT-1); `NFR` N-24, N-29 (BSD-3), N-32 (guards); `NFR > NFR-GEN` G-1 "server (also a library inside the VS Code extension)".
- **Kind:** differs (name and place; resolved in the PI by D-1, the todo is stale). The guard and the licence confirm.
- **Proposal:** none in the PI; the todo is rewritten under section B (V2-12).

#### AR-2 — Moving the vscode-free modules (`ww_b_workbench-3`)

- **Source:** `ww_b_workbench-3`: move 367 of 515 production files (measured 2026-11-15) that import nothing from `vscode`, with their tests; "no copy of a moved file remains in the extension (no re-export shims)".
- **PI:** N-24, N-32; CR.1 "The runtime is the one implementation of the `_ai` formats and of" (their stores).
- **Kind:** confirms (what moves). The way it moves changes under section B (V2-12).

#### AR-3 — The host interface and locations (`ww_b_workbench-4`)

- **Source:** `ww_b_workbench-4`: `QuestRuntimeHost` with workspace root, configuration, identity, events, file watching, UI callbacks; `VscodeHost` in the extension; locations from `tomAi.workspaceRepo` (RT-6, RT-10); also "the provider-SDK folder, the Dart binary locations, … host tools and host transports".
- **PI:** `RT > RT-HOST` CP.13 (locations, identity incl. member id, configuration, asks, notification, opening a file / document, the host's tools); CP.14 "In VS Code the interface is implemented in the extension's process; in every other host it is carried by the protocol's reverse requests"; D-17 "The runtime finds its places through the workspace layout resolver" (replaces RT-6, RT-10); D-7 no host transports.
- **Kind:** differs (locations: the todo still has RT-6/RT-10, the PI has the layout resolver; host transports: the todo has them, D-7 excludes them). The provider-SDK folder and the Dart binary locations are not named in CP.13: vague (they may fall under "locations" or the runtime installation, `RT > RT-INSTALL`).
- **Proposal:** add to CP.13's list: "the places of what the host carries for the runtime (provider SDKs it installed, the Dart binaries), where the host and not the runtime installation provides them". Question to the Blueprint, not to the product owner. CP.14 changes under section B (V2-8).

#### AR-4 — Stores and managers on the host interface (`ww_b_workbench-5`)

- **Source:** `ww_b_workbench-5`: every `_ai` file kind written by runtime code only; `QuestRuntime.create(host)` owns the stores; zero module-level mutable state.
- **PI:** CR.1; N-32 "no mutable state at module level".
- **Kind:** confirms.

#### AR-5 — Engines and transports (`ww_b_workbench-6`)

- **Source:** `ww_b_workbench-6`: queue manager, timers and reminders, process engine (nested processes, branching, decisions, review round), compaction and memory extraction, prompt assembly, the direct / Agent SDK / Local LLM leaves; "STAYS in the extension … the VS Code LM leaf … split out of the handler into a host-provided transport the runtime calls; the Copilot transport … a host-provided transport".
- **PI:** CR.5 (team review, expression language, prompt assembly, Claude Code features on every transport); `RT > RT-TRANSPORTS` CR.25 … CR.31; D-7 "No transports implemented by a host: the runtime does not carry the VS Code language-model and Copilot chat transports"; `SCO > SCO-OUT` O-4 "In the VS Code extension the 'VS Code LM' transport inside its Anthropic panel stays until the route through the Copilot SDK works". `LAND > LAND-BUILT` E-1 lists "reminders after a wait (they leave with format version 11 …)".
- **Kind:** differs (host transports). Also: the old extension is removing Copilot right now (tom_vscode commit `33267489` "Queue reminders removed (01_aifmt-1, stage 1 of the Copilot removal)"; vscode_extension todo `01_aifmt-1_aktn-copilot-removal`, in-progress, title "Remove the Copilot panel, transport, answer wrapper, reminders and the VS Code LM tools"). Whether the VS Code LM *transport* goes too is *unverified*.
- **Proposal:** none for D-7; O-4's sentence "stays until the route through the Copilot SDK works" must say in which extension (V2-9).

#### AR-6 — Tools and the MCP server in the runtime (`ww_b_workbench-7`)

- **Source:** `ww_b_workbench-7`: all `tomAi_*` tools (226 registered on 2026-11-15) execute in the runtime; host-provided tools keep names and schemas; "Move mcpServer-handler.ts' server (Streamable HTTP, port 19920 upward, access key, read-only floor) into the runtime, so any host can enable it."
- **PI:** `RT > RT-TOOLS` CT.1 (three sets), CT.2 (names kept), CT.4 … CT.6 (host tools), CT.8 "Inside VS Code the extension may offer its tools to the runtime as one MCP server instead of single registered tools"; `RT > RT-MCP` CT.11 "It reads and writes only `_ai` state and offers no access to files or an editor … Host tools are not reachable through it".
- **Kind:** differs. The todo moves today's one MCP server, which serves every tool, into the runtime; the PI's runtime MCP server serves only the `_ai` tools (the product owner's first quest note), and host tools reach the runtime by registration or through the extension's own MCP server (CT.8).
- **Proposal:** none in the PI (it follows the product owner's note); the todo is rewritten to CT.1, CT.8, CT.11 (V2-12).

#### AR-7 — The runtime server and its protocol (`ww_d_workbench-9`)

- **Source:** `ww_d_workbench-9`: `serve --workspace-repo <dir> --quest <id>`, one quest per process, ready line, exit on stdin close, structured stderr, length-prefixed JSON-RPC 2.0 over loopback TCP, `hello` with protocol / runtime / `_ai` format versions; commands for team review rounds, the round-start team question, the member id, nested processes, subprocess suggestions, the process-move marker and Proceed / Skip / Back / Decide, plan-mode approval, question choices, resend on another profile, the duplicate-submit guard; a schema both sides test against; conformance tests asserting "the files it writes match what the extension writes for the same operations".
- **PI:** `RT > RT-PROTO` CP.1 (wire, D-10), CP.2 (ready line, stdin, stderr), CP.3, CP.12 "The commands are a superset of the methods scripts use today", CP.24 (three versions on connect); CR.10, CR.11, CR.58 (plan mode per run), CP.13 asks incl. "accepting a plan, a decision"; CU.6 Asks group "plan approval, decision, gate result with its buttons".
- **Kind:** confirms. The conformance test against "what the extension writes" is not in the PI; under v2 it becomes the main acceptance tool (V2-23).

#### AR-8 — Packaging and the Agent-SDK-only mode (`ww_d_workbench-10`)

- **Source:** `ww_d_workbench-10`: one esbuild bundle installed with `npm ci --omit=dev`, the Agent SDK not redistributed, a verify command, `serve --agent-sdk-only` with `agent_sdk_server.js`' wire; "The SOM packages, the CodeSpecs resources and the Dart binaries are part of the runtime's distribution".
- **PI:** `RT > RT-INSTALL` (CR.40 ff., CR.43 "Provider SDKs are installed on request"); CR.29 and D-16 "The Agent SDK server of today becomes a mode of the runtime … Open again: whether the mode is still needed … (PQ-37)"; CT.10; R-21.
- **Kind:** confirms; the Agent-SDK-only mode is open in PQ-37.

#### AR-9 — Two hosts on one quest (`ww_d_workbench-11`)

- **Source:** `ww_d_workbench-11`: the extension and a runtime server on the same quest; each loads only its own queue entries, a timed request fires once, todo claims both ways, `sendItemToQuest` / `getQuestWindowStatus` see both; depends on `ww_c_collab-3/-4`.
- **PI:** `NFR` N-10 "Two hosts can work on the same quest at the same time; whether that is one runtime with two runtime clients or two runtimes is open (… PQ-36)"; T2; PQ-36 (recommendation (b): two runtimes, a run executed by one at a time).
- **Kind:** vague (open in PQ-36). Under v2 the case becomes "the old extension's in-process engine and a runtime on one `_ai`" (V2-17, V2-18), which PQ-36 does not name.
- **Proposal:** add to PQ-36's context the v2 case (old engine plus runtime on one quest, during the parallel period).

#### AR-10 — The runtime's documents (`ww_d_workbench-12`)

- **Source:** `ww_d_workbench-12`: README and guidelines of the runtime; the extension's documents keep only their VS Code UI; four feature areas documented as runtime features (one chat for every model, Claude Code features per transport, nested processes, team review); tom_forge told.
- **PI:** N-30 (documents); `DEL` "What the other quests are told: `tom_forge` …".
- **Kind:** confirms. Under v2 "the extension's documents" means the new extension's (V2-13).

#### AR-11 — `runtime_split_plan.ai_runtime.md` (S18)

- **Source:** RS-1 … RS-6; § 3 "The stable copy: evaluation" argues "A source copy in the tree is not needed … every fix would then have to be made twice", and recommends RS-1 (a) one source line plus a pinned stable build under its own id in VS Code profiles *Work* / *Dev*; RS-1 option (b) was "A copied source folder as a second extension, developed separately". § 3 also gives three rules for both builds on one `_ai` ("The dev build must not raise the `_ai` format …", "Test windows of the dev build work on a sandbox workspace …", "The window that develops the split runs the stable build").
- **PI:** SRC row S18 "its questions are settled in S1 § 14.1"; D-41 (from CQ-19) "Replaces RS-1".
- **Kind:** differs from the product owner's new decision, which is RS-1's option (b) in a new form (V2-1). The three coexistence rules of § 3 are not in the PI (V2-18).
- **Proposal:** carried in section B.

#### AR-12 — `quest_runtime_design.ai_runtime.md` (S19)

- **Source:** decisions RT-1 … RT-10; § 7 migration stages 2 … 12 "Each stage leaves the extension green … No re-export shims stay behind"; § 4 two hosts on one quest; RT-9 Telegram claim.
- **PI:** D-1 replaces RT-1; D-17 replaces RT-6/RT-10; D-16 (RT-3); D-11 (RT-7); N-33 "Every stage of the split leaves the extension working and installable"; D-6 / L-9 Telegram deferred.
- **Kind:** confirms where the PI cites it; § 7's in-place stages differ from the v2 decision (V2-12).

### A.2 Coordination: `ww_c_collab-*`, `ww_f_collab-*`, `ww_g_collab-*`, `ww_a_collab-2b`, `a2a1`, `caf_12*`

All not-started, except `caf_12a` (blocked by vscode_extension `caf_11*`) and the group `caf_12`. Sources in the PI: S5 `tac_specification.md`, S6 `agent_collaboration.docspecs.md`.

#### AR-13 — Client and local backend (`ww_c_collab-3`)

- **Source:** the coordination client with off and service backends; `agent.workspace.yaml` at the workspace root with a JSON schema; starting the local service; registration with presence (`hasQuest`); the misconfiguration check; outage behaviour (BP-7).
- **PI:** `TAC > TAC-BACKENDS` CA.35 "The runtime has one tac client for all of this"; CA.31 `mode: off`, PQ-48; CA.26 local row; `TAC > TAC-COORD` CA.3, CA.4; CA.34; CA.32 "nothing falls back on its own". CA.26 says only "in its workspace configuration for coordination".
- **Kind:** confirms; vague on the file.
- **Proposal (CA.26):** "The workspace configuration for coordination is a versioned file at the workspace root, `agent.workspace.yaml`, with a JSON schema: the backend, the team, and the repositories the workspace coordinates and those it brings up to date (CW.16). Every kind of runtime reads it. (S6, BP-21, BP-22)" Also add to PQ-48's context that the built service is started by the extension as a detached child (`ensureLocalService()`, per the todo's notes).

#### AR-14 — Claims in the queue (`ww_c_collab-4`)

- **Source:** leases all or none before a todo item; fallback todo `resources` → its `scope` mapped to repositories → `quest-resources.<quest>.yaml`; "waiting for resources"; `claim_hold` / `claim_free`; lease tools `tomAi_listLeases`, `tomAi_acquireResources` (refused `noTodo` outside a todo item), `tomAi_releaseResources`.
- **PI:** `PAR > PAR-APPROACH` CW.4 "claims the todo's resources, all or none"; CA.12 … CA.14; CW.9 (group holds); CW.8 (todo's resources, else the quest's list); CR.35 "No source fixes where a quest's list is recorded (the register of CR.100 has no field for it)"; D-64 (no session record), D-59 / D-68 (named `git:` resources).
- **Kind:** confirms (core); differs (the scope step is missing; CR.35 misstates its sources: S6 BP-8, `original_request.md` and S1 § 5.5 name `quest-resources.<quest>.yaml`); vague (only a todo item claims; the agent's lease tools).
- **Proposal:** CR.35's last sentence: "S1 and S6 name a quest file `quest-resources.<quest>.yaml` (`default_resources`); the format standard S22 has no such file and the register of CR.100 no field for it; the Solution Blueprint settles which it is. (S1 § 5.5; S6, BP-8)". New **CW.28**: "Only an item that executes a todo claims. A prompt item claims nothing, and an agent's claim tool is refused outside an item that executes a todo. (S6, DPR-1)".
- **Question:** Is a todo's `scope` read as resources when it names none? (a) **yes, between the todo's resources and the quest's list (S6, BP-8)**; (b) no. *Recommendation:* (a), many existing todos carry only a scope.

#### AR-15 — d4rt packages on `tom_todo_model` ^2.2.0 (`ww_a_collab-2b`)

- **Source:** dependency maintenance.
- **Verified:** `tom_d4rt_dcli` and `tom_dcli_exec` already depend on `tom_todo_model: ^4.1.0`; the model's pubspec says `version: 6.0.0` (published? *unverified*). PI `LAND-BUILT` E-2 and `RISK-DEPS` R-18 say "4.2.0 today".
- **Kind:** confirms (no feature). E-2 / R-18 may be stale.
- **Proposal:** cancel the todo; check E-2 and R-18's version.

#### AR-16 — Messages between runtimes (`ww_f_collab-1`)

- **Source:** message types of IDEA-27 plus `update_needs_attention`; toasts, PROCESS view, WINDOW STATUS as the view of every running runtime; `on_done` / `unblock` as commands; `tomAi_sendItemToQuest` via messages, optional `host`.
- **PI:** CA.18 … CA.22, CW.20, SC-19 "Window status | starting point (the list of team runtimes)". CA.20 has no `update_needs_attention`, `config_needs_attention`, `budget_needs_attention` (S6). S5 § 11 item 6 "Commands name quests, never `all`" and `preferHost` are not in CA.18.
- **Kind:** confirms; missing (three notification types; commands never to all; preferred host).
- **Proposal:** CA.20 add "a repository could not be brought up to date (CW.16); the team's configuration or a backend's limits need attention". CA.18 add "A notification goes to all quests of the team or to named quests; a command names its target quests, never all of them, and may prefer a machine while a runtime of the target quest is present there. (S5 § 11, items 6 and 16)".

#### AR-17 — Published endpoints (`ww_f_collab-2`)

- **Source:** an `mcp` endpoint per reachable scope (`loopback`, `vpn`); a `remote-control` endpoint on `loopback` only.
- **PI:** CA.23, CA.24, CT.13; remote control open (CI.13, PQ-50).
- **Kind:** confirms; vague on remote control's scope.
- **Proposal:** add to PQ-50's options that S6 restricts the remote-control endpoint to the machine and publishes the MCP endpoint on loopback and VPN.

#### AR-18 — The Coordination page (`ww_f_collab-3`)

- **Source:** views (runtimes and sessions, leases and stale leases, waiting items, endpoints, undelivered commands, auto-update skips, unmerged branches and worktrees) and confirmed actions (free, free everything of a host, resend, drop, retry update), each announced to the team; S6 adds a header band with backend state, GitHub budget and warnings.
- **PI:** SC-28 "none in the extension: the coordination page: claims, leases with the executions that hold them, the integration queue | new | supervision"; CU.6 Supervision row; CA.43; CW.13.
- **Kind:** vague (three contents against about ten views and five actions).
- **Proposal:** new **CU.18** (`CLI > CLI-UI`): "The coordination page shows the team's runtimes with their runs, the leases (stale ones marked) with what holds them and what waits for them, the endpoints, the commands not yet taken, the repositories the fast-forward skipped (CW.16), and the working trees and branches of executions that were not integrated. Its actions — free a lease, free every lease of one machine, resend or drop a command, retry a skipped update — each ask for confirmation, are announced to the team runtimes, and are kept with the lease or command they acted on. (S6, part-coordination-page-and-tools; CA.13, CA.19, CW.16)" Extend SC-28 to match.

#### AR-19 — The GitHub backend (`ww_f_collab-4`)

- **Source:** leases and endpoints as refs in `al-the-bear/tom_coordination`; presence renewed with leases; messages only through each machine's local service; a budget guard on `403` / `429`. Blocked by al_the_bear `14_loose_wslayout-4`.
- **PI:** CA.26 GitHub row; X-11; D-47; D-66. CA.4 / CA.15: presence and clock on GitHub "open (PQ-47)", while S5 § 6.1, § 10 and § 11 item 11 fix them (committer dates; 60 minutes). No rate-limit guard; no history shortening (S5 § 10).
- **Kind:** confirms; missing (budget guard, history); vague (PI behind its source on presence and clock).
- **Proposal:** new **CA.45**: "On the GitHub backend each runtime's tac client keeps within the repository server's limits: it counts its calls, lets renewals and releases always through, holds claims back when its share is spent, and stops every call of its machine after a `403` or `429` until the time the server names. The coordination repository's history is shortened by a maintenance step the user starts. (S5 § 6.3, § 10; S6)". Add to PQ-47's context that S5 already uses GitHub's committer time and a 60-minute presence.

#### AR-20 — Auto-update of unclaimed repositories (`ww_f_collab-5`)

- **PI:** CW.16 "fast-forward only and only with a clean working tree and nothing unpushed … off unless switched on … never on a schedule"; O-6; F11.
- **Kind:** confirms.

#### AR-21 — Telegram, one bot token (`ww_f_collab-6`)

- **Source:** one token per workspace or host, one chat per host, reply-to routing, runtime tags, migration of per-quest settings. Not-started, no blocker. `deferred.ai_runtime.md` keeps it "deferred, kept in this quest (FO-16)".
- **PI:** `SCO > SCO-LATER` L-9; D-6 "Telegram is deferred."; X-10.
- **Kind:** confirms as deferred; an open, unblocked todo contradicts the deferral.
- **Question:** (a) **keep Telegram deferred and park `ww_f_collab-6` with a blocker on the first version (D-6)**; (b) bring Telegram into the first version (new item, D-6 changed). *Recommendation:* (a). Under v2, the old extension keeps today's per-quest Telegram; whether v2 must have Telegram "as before" belongs to V2-24.

#### AR-22 — Branches and worktrees (`ww_g_collab-1`)

- **Source:** a `branches` setting (none, item, todo, group, run) in `agent.workspace.yaml`; run trees `.worktrees/<run>/`; branches pushed after every commit; merge in the main checkout with a merge prompt on failure; `Tac-Fence: <token>` trailer; orphan detection.
- **PI:** CW.2 (strict / worktree mode per repository, decided by the team), CW.3, CW.5 (rebase, checks, fast-forward, push; token checked at the push), CW.6, D-55, PQ-46, PQ-39. S5 § 3.2 has `none / item / group`: three different models.
- **Kind:** differs (granularity, merge direction; decided in the PI); missing (orphans, push after every commit, merge prompt).
- **Proposal:** new **CW.29**: "A working tree or branch of an execution that no lease names any more is an **orphan**: the coordination page shows it, and the user integrates, keeps or removes it; nothing removes it on its own. (S6, part-branches-and-worktrees)". Add the `Tac-Fence` trailer to PQ-46's options.
- **Question:** Is an execution's branch pushed after every commit? (a) **yes (S6)**; (b) only at the integration step. *Recommendation:* (a), a machine that goes away loses nothing.

#### AR-23 — The coordination server (`ww_g_collab-2`)

- **Source:** several groups per service, API keys and quotas per customer (resources, calls per hour), VPN by default, safe for the internet.
- **PI:** CA.27 "the full tac server from the start: accounts, access keys kept as salted hashes, quotas per account, the administration interface"; CA.28 … CA.30; D-22; X-4.
- **Kind:** confirms; vague (kinds of quota; VPN by default). The todo lacks the relay (CA.30) and invitations (CI.6 … CI.10).
- **Proposal (CA.27):** "Its quotas count at least the resources leased and the calls per hour. It listens on the VPN only unless its administrator opens it; whatever it serves to the internet is strict (CI.10). (S6, IDEA-16, BP-5)"

#### AR-24 — The server backend and migration (`ww_g_collab-3`)

- **PI:** CA.26 server row; CA.33 "A team's coordination moves from one backend to another by a migration that carries its token counters and undelivered commands."
- **Kind:** confirms; vague (BP-9: one runtime with exclusive access while the migration runs).
- **Proposal (CA.33):** "While it runs, one runtime holds every repository of the team exclusively and the others wait. (S6, BP-9)"

#### AR-25 — Finishing and hand-off (`ww_g_collab-999`)

- **PI:** X-8 (ai_runtime owns it), V-6, U-11, `DEL` guides.
- **Kind:** confirms. The split plan § 5 proposed to replace it by the package hand-off; under v2 the hand-off is the swap (V2-14).

#### AR-26 — A2A (`a2a1`)

- **Source:** compare A2A 1.0 with TAC; record what to adopt, what an A2A gateway for outside agents needs, what not to take; concept: A2A "not taken between runtimes for now … an option for outside agents".
- **PI:** only R-4 "The runtime protocol covers ground the Agent Client Protocol, A2A, MCP … cover". Nothing in SCO.
- **Kind:** missing.
- **Proposal:** new `SCO > SCO-LATER` row **L-13**: "A gateway for outside agents that speak A2A (Agent2Agent): agent cards for a runtime's published capabilities, tasks with their states | Between our runtimes TAC's commands and messages do this; A2A is an option for agents outside the product (S1 § 15); what to take over follows from the comparison (`a2a1`)".

#### AR-27 — The extension's collaboration and feature idea (`caf_12`, `caf_12a`)

- **Source:** `caf_12a` (blocked) asks ai_runtime to update its todos for vscode_extension's idea `collab_and_features` (`_ai/quests/vscode_extension/ideas/collab_and_features/collab_and_features.docspecs.md`): features as groups of groups with phases; a development model per feature (main-only / feature branches, strict `leasesAlways` / free); a review setting ending in a review todo by `code_reviewer`; the resource notation `<type>://<server>[:<port>]/<path>[@<branch>][#<path>]`; leases on or off per quest; standard runs `default`, `planning`, `quest-keeper`; feature runs across quests with Wait / Notify items; agent groups with supervisor / collaborator (`sendToAgent`); the issue flow INCOMING → ACCEPTED → features. The vscode_extension `caf_*` todos: none completed (45 not-started, 5 blocked, 11 groups); the user guide it cites does not exist yet.
- **PI:** 0 hits for `collab_and_features`, `featureId`, `leasesAlways`, `quest-keeper`, `issue2feature`, `sendToAgent`. CW.2 (mode per repository), CW.15 (review without pull requests), CA.10 / D-68 (`git:<owner>/<repository>#<pattern>`), CA.31 (on/off per workspace), CR.9 (run `default` only), D-24 "there is no 'agent group' as a thing of its own".
- **Kind:** missing (features, standard runs, feature runs, issue flow); differs (notation, development model, on/off level); contradicts D-24 (agent groups).
- **Question (proposed PQ-60):** Which of collab_and_features' concepts does the runtime take over? (a) all, as a new capability group, its notation replacing D-68's; (b) **the run and feature concepts (features, standard runs, review todos, issue flow) as runtime capabilities; tac's terms kept (no agent groups, D-24; supervisor / collaborator become asks routed between runs); one resource notation, chosen with PQ-45**; (c) none now: they stay in the extension, recorded as input (a source S28). *Recommendation:* (b). Under v2 this matters doubly: whatever the old extension builds of it before the copy point is a feature v2 must have "as before" (V2-24). Add the docspec as source S28 and the notation conflict as `CON` X-22 (or next free).

### A.3 Webwork's needs: `tac_webwork-1 … 6`, `12b_woneb1 … 3`, `webwork_requirements.md`

#### AR-28 — Identification and clients without a runtime (`tac_webwork-1`)

- **Source:** `user {userId, email}` on connect; clients without a runtime; as `tac/1.1`. Answer recorded: "It must connect through a server part that runs the runtime for them. We may investigate partial tac connection for messaging and maybe some other areas that are lightweight, too."
- **PI:** CI.10, CI.14, CI.3; CI.4 / D-27 / X-3 (everything through a runtime); D-21 / X-6 / CA.36 one `tac/2.0`; L-12 "possible, not planned".
- **Kind:** confirms (identification); differs, resolved (client without runtime, version).
- **Proposal:** L-12's reason: "possible; to be investigated for messaging and other light parts (X-3), not planned for the first version".

#### AR-29 — Team server mode (`tac_webwork-2`)

- **PI:** CA.27, CA.28, D-22, N-28, X-4. Its decisions ((b) full server first, (a) reverse proxy) match.
- **Kind:** confirms; the todo is superseded by `ww_g_collab-2` (AR-23).

#### AR-30 — User messages (`tac_webwork-3`)

- **PI:** CM.7 … CM.14, CM.3, CP.36.
- **Kind:** confirms. The service clock for message times is in S1 § 7.10 ("`createdAt` from the service's clock") but not in CM.*: missing.
- **Proposal:** new **CM.15** (`TAC > TAC-CONV`): "A message's time is set by the service's clock when it accepts the message, never by the sending client; history, read state and retention are ordered by it. (S1 § 7.10)".

#### AR-31 — Documents as blobs (`tac_webwork-4`)

- **PI:** CV.1 … CV.6; CV.14 "A round's blobs are kept until the round is merged; blobs a process pinned are kept for as long as that process runs (CV.4), and the longest lifetime of 30 days (CV.3) holds for blobs that are not pinned".
- **Kind:** confirms; vague (whether a round's blobs are capped at 30 days, as WR-5 and the todo say). D-29 not read.
- **Proposal (CV.14):** "A round's blobs are kept until the round is merged, at most 30 days unless a process pins them."

#### AR-32 — A Dart tac client without a runtime (`tac_webwork-5`)

- **PI:** CL.3 / G-3 `tom_ai/ai_build/tom_tac_client`; CL.11 "no server uses it"; WR-6 "an application does not connect to tac directly"; X-3, D-27.
- **Kind:** confirms (the package); differs, resolved (its use). Replace by the runtime client SDK / web runtime client SDK work (CL.12, G-8).

#### AR-33 — Webwork messaging checked end to end (`tac_webwork-6`)

- **Source:** "a server with TLS, two machines and a browser exchange messages and a `.webwork.zip`-sized blob in a thread attached to a review round" (S1 § 7.10); then the webwork quest is told.
- **PI:** no end-to-end check; `DEL` (D-42) tells Webwork when the todos are filed and when the runtime is complete; L-8 (web and phone in Webwork's wave 3); CI.4.
- **Kind:** differs (a browser cannot take part in the first version); vague (the check itself).
- **Proposal:** in `DEL` under "What the other quests are told": "Webwork is also told when messaging has been checked end to end: a tac server behind TLS, two machines each through its runtime, a thread attached to a review round, and a blob of the size of a Webwork copy (S1 § 7.10). A browser takes part only through the web runtime service (CI.4, PQ-38)." Or fold into PQ-57 (b).

#### AR-34 — Runtime operations for Webwork's AI tab (`12b_woneb1`)

- **PI:** CR.16 (three send choices), CR.17 (review each result / work silently), CR.18, CR.6; PQ-51 (no name such as `webwork-app`). WR-7's "one run per Webwork area … all in the `default` session" is not stated.
- **Kind:** confirms; vague (host runs without a process).
- **Proposal (CR.6):** "A host may create runs of its own in such a runtime, one per part of its application, that follow no process; each starts in its default session (CR.62). (S3, WR-7)".

#### AR-35 — `tom_ai_runtime_ui` chat, queue, trail, appending Markdown view (`12b_woneb2`)

- **PI:** CU.1 … CU.3, CU.6, CU.7, CU.8, N-25, G-6; PQ-44.
- **Kind:** confirms.

#### AR-36 — Host tools from a Flutter host (`12b_woneb3`)

- **PI:** CT.4 "A host registers its tools with its runtime … for a run or for a single prompt", CT.5, CT.6 (prompt boundaries), CP.13, CP.14, PQ-36.
- **Kind:** confirms.

#### AR-37 — `webwork_requirements.md` (S3)

- **PI:** `TAC > TAC-WEBWORK` maps WR-1 … WR-7; WR-2 and WR-6 "met differently"; S3 itself says "Where the specification decides differently, the specification wins".
- **Kind:** confirms; remaining gaps AR-31 and AR-34.

### A.4 Model providers: `xx*`, `ccparity_h_pi-*`, `checks7`, `llm_providers_runtime_integration.ai_runtime.md`

All not-started or blocked. `xxproviders1`'s placement answer: "(b), we'll run these todos only after we've finished the ww* groups". PI: `RT > RT-PROVIDERS` CS.12 … CS.18; S7 is the providers document. `xxopenai1` is completed and archived in vscode_extension (decisions read there).

#### AR-38 — Placement (`xxproviders1`)

- **PI:** CS.18 "The providers beyond today's transports are built in the runtime, after the transports have moved into it; none is built in the extension first."
- **Kind:** confirms. Under v2: "in the runtime" holds; whether the old extension gets any of them is answered no by CS.18 (V2-24).

#### AR-39 — Three adapter layers per provider (`xxproviders1`, `xxproviders3`)

- **Source:** answer "all three [own clients, Vercel AI SDK, official SDKs] … a provider can be through multiple 'adapters'"; a new `providers.configurations` section with Local LLM configurations migrated into it.
- **PI:** CS.12 row 3 "the client for local models grown into a provider client"; CS.14. The Vercel AI SDK is named nowhere.
- **Kind:** differs.
- **Proposal:** new **CS.21**: "A provider is reached through an adapter, and one provider can have several adapters: the runtime's own clients (the direct client with a base address, the provider client grown from the client for local models), the Vercel AI SDK as one adapter for many APIs, and a provider's official SDK. A profile names the adapter it uses. Local-model configurations are provider configurations like the others. (xxproviders1, xxproviders3)".
- **Question:** all three layers in the first version, or own clients first and the other two in `SCO-LATER`? *Recommendation:* own clients first; each further layer multiplies the conformance work.
- **Question:** where a local-model configuration lives, against CS.3 ("the providers and their configurations" are the team's): (a) the team's, with a per-machine endpoint value; (b) **hosted provider configurations the team's, local-model configurations the runtime's**; (c) both, limited by CS.6. *Recommendation:* (b).

#### AR-40 — The provider page (`xxproviders1`, `xxbaidu1`, `xxdeepseek1`)

- **Source:** "the installation page must offer to install what is needed for each and have the input field to configure keys/env variable names and accounts"; Baidu "should still show in the provider installation page"; DeepSeek's processing location explained there.
- **PI:** CR.43 "Provider SDKs are installed on request, when a profile first needs one"; SC-21 status page split. No provider page.
- **Kind:** missing.
- **Proposal:** new **CR.111** (`RT > RT-INSTALL`): "A host offers a provider page: per provider its ways in with a short explanation (where it processes data, what account it needs), installing what a way in needs (an SDK, a command line, a native runtime), and fields for the secret references, environment-variable names and accounts of its configurations. Providers that need no new transport are listed with how they are configured. (xxproviders1; xxbaidu1; xxdeepseek1)".

#### AR-41 — Key source (`xxproviders1`)

- **Source:** keys in a KDBX file whose password is entered once per system start and shared between runtime processes, never persisted.
- **PI:** CS.7 (`tsm:`, `os:`, `env:`, `file:`), CS.10 (unlock asked), Tom Secrets Manager (S15, KDBX-based, unlocked once per machine).
- **Kind:** covered differently.
- **Proposal:** confirm with the product owner that Tom Secrets Manager realises the answer; no item.

#### AR-42 — Anthropic-compatible base URL (`xxproviders2`)

- **PI:** CS.12 row 2 (DeepSeek, OpenRouter, Moonshot, Zhipu, MiniMax; Claude on Bedrock and Vertex).
- **Kind:** confirms; vague (per configuration, never process-wide; model-slot mapping). Bedrock / Vertex use cloud credentials, not a base address (`xxotherproviders4`).
- **Proposal:** new **CS.22**: "A configuration on an Anthropic-compatible endpoint carries its base address, its key reference and a mapping of the Claude Agent SDK's model slots to the provider's models; the runtime gives them to that configuration's sends only, never to the whole process, so profiles on Anthropic and on a compatible provider run side by side. (xxproviders2; xxdeepseek1)". CS.12: Claude on Bedrock / Vertex as "an Anthropic configuration with a cloud provider (credentials from the cloud's command line)".

#### AR-43 — Prices and usage per provider (`xxproviders4`)

- **Source:** "No manually maintained price tables, but if you can get the prices from the internet tables are ok"; Copilot: no price unless the SDK returns one; recurring checks of providers and prices.
- **PI:** CS.14 "… and its prices, so usage and cost are shown per provider"; CR.98; CR.105 "per day and model"; N-43.
- **Kind:** differs; missing (recurring checks).
- **Proposal:** CS.14's price clause: "… and its prices, taken from the provider (its model list, or the cost it reports per generation) or from a published price list, never maintained by hand; where no price is available, usage is shown without a cost. Premium requests and a remaining quota are shown where the provider reports them." CR.105: "per day, provider and model".
- **Question:** recurring provider re-checks as a product capability or a quest process? *Recommendation:* a quest process (manually started, no schedule, N-34).

#### AR-44 — Model catalogue (`xxproviders5`)

- **PI:** CS.14 "the models it offers (read from the provider where it lists them)". **Kind:** confirms.

#### AR-45 — Conformance (`xxproviders6`)

- **PI:** CS.15 "a prompt, a tool call, streaming, usage". **Kind:** vague.
- **Proposal (CS.15):** "One conformance table checks every provider configuration against a recorded or simulated server: a prompt, a streamed answer, a tool call and its result, a refused key, a rate limit with its retry time, usage; and, opt-in, a short live check per provider with a real key."

#### AR-46 — Checkpoints (`xxproviders7`, `xx*4/3/5` checkpoints, `xxcopilotsdk7`, `checks7`)

- **PI:** none, correctly (acceptance steps); `DEL` PQ-57.
- **Kind:** confirms (no item). **Proposal:** PQ-57's acceptance includes "one queue item with a tool call on a profile of each way in (CS.12)".

#### AR-47 — Soft-interrupt hold points (`xxproviders8`, `deferred.ai_runtime.md`)

- **Source:** answer "pretty much the same for direct API/LLM providers and other SDKs. Soft interrupt on the next tool call … For other local SDKs we can also soft interrupt during tool calls." `deferred.ai_runtime.md` still says it is decided "when the first provider transport is built" (stale). S7 has no soft-interrupt section, which `xxproviders8`'s DONE WHEN asks for.
- **PI:** CR.28, CR.89 (15 s, then hard), CR.91.
- **Kind:** confirms; vague for agent transports with built-in tools.
- **Proposal (CR.28):** "On an agent transport the hold point is the result of a runtime tool called through MCP, or the outside program's tool hook where it has one; where neither comes within the time of CR.89, the soft interrupt becomes a hard one." Quest documents: close the deferred entry, add the rule to S7.

#### AR-48 — GitHub Copilot SDK (`xxcopilotsdk1 … 7`)

- **Source:** answers: only `continue` sessions; native runtime downloaded on first use; login via the VS Code GitHub account and a token variable; Copilot's own tools and instruction files per profile, default off; tokens and premium requests, no price.
- **PI:** CS.12 row 1 "GitHub Copilot (its SDK)"; CS.13 "GitHub Copilot is reached only through direct calls and its SDK"; O-4; CS.17; CR.43; CR.75; CR.5.
- **Kind:** confirms (transport); vague (CS.13 "direct calls": no todo plans one; whether a public direct API exists is *unverified*); missing (login, lifetimes, own tools, quota).
- **Proposal:** new **CS.23** (next free): "A transport that signs in to a vendor account offers per configuration the account the host is signed in with (where the host has one), a token or key named by a secret reference, or cloud credentials; the provider page shows the sign-in state. (xxcopilotsdk1; xxopenai1; xxgoogle1)". CR.75 add: "A transport whose outside program cannot fork a conversation (the Copilot SDK) offers only *continue*." New **CS.24**: "On an agent transport whose program has built-in tools and instruction files of its own, a profile chooses whether they are used; by default they are off." CR.43: "a provider SDK, command line or native runtime".
- **Question:** CS.13: (a) **"only through its SDK"**; (b) keep "direct calls" and name the API. *Recommendation:* (a).
- **v2 link:** the Copilot SDK is the condition in O-4 for dropping the VS Code LM transport (V2-9).

#### AR-49 — OpenAI (`xxopenai2 … 4`, `xxlater1`)

- **Source:** "All three, but leave (c) [Agents SDK] as a xxlater* todo"; Codex login both ways.
- **PI:** CS.12 row 1 "OpenAI (the Codex SDK)"; row 3 lists no OpenAI API; nothing on the Agents SDK.
- **Kind:** confirms (Codex); missing (OpenAI API; Agents SDK later).
- **Proposal:** add "OpenAI" to CS.12 row 3 (with the Responses API where reasoning items need it). New `SCO-LATER` row: "The OpenAI Agents SDK as a transport (handoffs, guardrails, tracing) | a second tool loop beside the runtime's own; decided after the OpenAI transports run (xxlater1)".

#### AR-50 — Google (`xxgoogle1 … 4`)

- **Source:** Gemini API as a provider and Gemini CLI headless; AI Studio key and Vertex AI with application default credentials; ADK not chosen.
- **PI:** CS.12 row 1 "Google (the Gemini command line)"; the Gemini API is in no row.
- **Kind:** confirms (CLI); missing (API, Vertex credentials via CS.23).
- **Proposal:** CS.12 add "Google (the Gemini API: its own client or its OpenAI-compatible endpoint)".

#### AR-51 — xAI (`xxxai1 … 3`)

- **PI:** CS.12 row 3 "xAI". **Kind:** confirms; missing (hosted tools later).
- **Proposal:** `SCO-LATER` row: "Tools a provider runs on its own servers (xAI's search and code execution through its SDK) | when it brings an advantage over the runtime's tools; the SDK is experimental (xxxai1)".

#### AR-52 — Meta / Llama (`xxmeta1 … 3`)

- **Source:** "(b) and (c)": Llama through OpenRouter, Groq, Together and locally, not Meta's Llama API.
- **PI:** CS.12 row 3 "Meta's Llama API". **Kind:** differs.
- **Proposal:** replace by "Llama models through the routers and providers that serve them (OpenRouter, Groq, Together) and through local models; Meta's own Llama API is not used."

#### AR-53 — DeepSeek, Baidu (`xxdeepseek*`, `xxbaidu*`)

- **PI:** CS.12; L-2; CS.6. **Kind:** confirms (parallel use via CS.22; page via CR.111).

#### AR-54 — Mistral (`xxmistral1 … 4`)

- **Source:** "All three": chat preset, Conversations transport, Vibe CLI ("needs Python and uv on every host").
- **PI:** CS.12 row 1 "Mistral (its coding agent)", row 3 "Mistral". **Kind:** confirms; missing (Conversations; the Python dependency).
- **Proposal:** new **CS.25**: "A provider API that keeps the conversation on the provider's side (Mistral Conversations) is a model transport whose session id is the provider's conversation id (CS.17)." New **R-30**: "An agent transport that needs another language runtime on every host (Mistral Vibe: Python and uv)."

#### AR-55 — OpenRouter (`xxopenrouter1 … 3`)

- **Source:** both endpoints; routing preferences per configuration (provider order, fallbacks, data collection off).
- **PI:** CS.12 rows 2 and 3. **Kind:** confirms; missing (routing).
- **Proposal (CS.14):** "A router's configuration carries its routing preferences (upstream providers preferred or excluded, fallbacks allowed, data collection off by default)."

#### AR-56 — Other providers (`xxotherproviders1 … 5`)

- **Source:** presets "As recommended": Kimi, GLM, Qwen, Groq, Azure OpenAI, LiteLLM; the rest when a quest needs them; Claude on Bedrock / Vertex "(a)".
- **PI:** CS.12 lists MiniMax, Together, Fireworks, Cerebras (not chosen), not LiteLLM (chosen). **Kind:** differs slightly.
- **Question:** does CS.12 list every reachable provider or the first version's presets? (a) **the presets, plus one sentence that any compatible endpoint can be configured without a preset**; (b) everything reachable. *Recommendation:* (a).

#### AR-57 — pi (`ccparity_h_pi-1 … 3`, `checks7`)

- **Source:** evaluate `pi-ai` as a model transport and `pi-coding-agent` over RPC as an agent transport; `pi-agent-core` out. `ccparity_h_pi-1` depends on `ww_b_workbench-6`.
- **PI:** CS.16 "Two agent libraries are evaluated behind the transport interface, one as a model transport and one as an agent transport" (names neither; S1 and S2 name them).
- **Kind:** vague.
- **Proposal (CS.16):** "`pi-ai` (one interface to Anthropic, OpenAI, Google and OpenAI-compatible endpoints) is evaluated as a model transport, and `pi-coding-agent` (a coding agent driven over RPC as a child process, reaching the runtime's tools through MCP) as an agent transport, both behind the transport interface; `pi-agent-core` is not used, as it duplicates the runtime's tool loop. The evaluation compares answers, tool use, cost and failure handling with the runtime's own transports; a library that is taken keeps what CR.27 requires. (S1 § 5.4; S2 § 3.8; ccparity_h_pi-1 … -3)". *Unverified:* the package scope `@earendil-works/*` beyond the todo's statement.

#### AR-58 — `llm_providers_runtime_integration.ai_runtime.md` (S7)

- **Source:** research of 2026-11-06; the PI calls it "current".
- **Kind:** differs (stale): it predates the `xx*` answers (placement, adapter layers, the configuration section, per-vendor choices, the soft-interrupt rule; ADK not chosen, Agents SDK later).
- **Proposal:** update S7 to the decided state, then re-read CS.12 … CS.18 against it.

### A.5 Repository quests, the runtime scripting API, the remote-control app: `ww_e_gitruntime-*`, `checks11`, `ww_e_runtimeapi-*`, `checks10`, `rca1`

`ww_e_gitruntime-1 … 8, 10, 11` and `ww_e_runtimeapi-1` depend on `ww_b_workbench-7` (blocked). The PI's `PAR > PAR-QUESTS` (CQ.*) is rebased on al_the_bear's standard (S22, D-71); the git-runtime todos are on the older design (S2 § 3.7). The PI keeps the older features open in PQ-53, PQ-54, PQ-55.

#### AR-59 — Two quest types and the personal tree (`ww_e_gitruntime-1`)

- **Source:** classic vs repository quest; personal files in `_ai/personal/<id>/`, tracked by tom_agent_state; one resolver.
- **PI:** CQ.1 "There are three types of quest, side by side in one `_ai` state"; CQ.2 "one **personal repository**"; CQ.11 / PQ-53; CQ.5; CQ.9 / CR.100 register.
- **Kind:** differs (two vs three types; the personal tree is none of PQ-53's options); confirms (resolver).
- **Proposal:** add PQ-53 option "(d) A per-quest personal folder `_ai/personal/<id>/` in the shared `_ai` state (tracked, reaching the user's own machines) … no personal repository, and nothing personal in the quest's repository."

#### AR-60 — Merge drivers in TypeScript (`ww_e_gitruntime-2`)

- **Source:** the runtime ships its own drivers (todos by id; a new `ai-journal` driver for dated journals); "Nothing depends on al_the_bear".
- **PI:** E-5 "**Merge drivers for the `_ai` files** in TypeScript. Their source is the fleet's"; CQ.6; CQ.12 ("Markdown files by section"); CQ.11 (decisions rendered from archived todos).
- **Kind:** differs (ownership, journal rule). Whether today's drivers are Python or TypeScript: the todo and E-5 disagree, *unverified*.
- **Question:** (a) **the runtime uses the fleet's drivers from the binaries repository (E-5, CQ.6)**; (b) the runtime owns them, the fleet consumes them; (c) both. *Recommendation:* (a). Add to CQ.12: "Dated journals (progress, deferred, documentation updates) are merged as a union of their dated sections, sorted by date and time."

#### AR-61 — Member branches, publish, update, conflict review (`ww_e_gitruntime-3`)

- **PI:** CQ.6 ("a branch per member … what of them remains is open (PQ-54)"), CW.14, CW.27; PQ-54 recommends Later.
- **Kind:** vague / open (publish offer on todo completion, auto-publish setting, ahead / behind display).
- **Proposal:** none before PQ-54; then CQ.6 or `SCO-LATER`: "Publishing a member branch is started by the member (a command, and an offer when a todo is completed or a review round finished, with a per-quest personal setting to publish automatically); it merges into the quest's main branch when the merge drivers resolve everything, and opens a review of the conflicts otherwise. A host shows each quest's member branch as ahead, behind or in conflict."

#### AR-62 — Process state moved only on main (`ww_e_gitruntime-4`)

- **PI:** CQ.6 "one shared process position, moved only on the main branch"; CR.8 (several runs).
- **Kind:** vague (CQ.6 speaks of one position; runs have one each).
- **Proposal (if member branches survive PQ-54):** "each run's process position is one shared file; a move of a run (and creating or deleting a run) is written to the quest's main branch alone, and refused when that file changed on the main branch since it was read".

#### AR-63 — `<quest>_internal` and KDBX credentials (`ww_e_gitruntime-5`)

- **Source:** a second repository for technical members with a KDBX file (via **tom_kdbx** / tom_kdbx_store); `tomAi_runCommand {secrets: [...]}`; values masked in results.
- **PI:** CQ.6 (open, PQ-54); CS.7 (no KDBX form; `grep -i kdbx` finds nothing); CS.8 (files only).
- **Kind:** missing in detail. **Flag:** tom_kdbx was retired over its licence (GPL-3) in favour of tom_kpasslib; `repos.yaml` lists `tom_kdbx_store` and `tom_ai/xternal/tom_kpasslib`, no tom_kdbx. The todo must not name tom_kdbx.
- **Proposal:** independent of PQ-54, new item in `RT > RT-SECRETS`: "A command a tool runs may name secret references; only those are resolved, into that command's environment; the values never enter a prompt, a tool result, a trail or a log, and tool results are scanned for them and masked." If PQ-54 keeps `_internal`: a CS.7 form for a KeePass file.

#### AR-64 — Secret scan (`ww_e_gitruntime-6`)

- **PI:** CQ.6 "a scan for secrets when committing and publishing" (open, PQ-54). **Kind:** confirms (open).

#### AR-65 — Member identity and repository access (`ww_e_gitruntime-7`)

- **PI:** CQ.6 (open); `USR-TEAM` member id; CI.1 … CI.20 have no mapping to a repository-server account and no server teams per quest.
- **Kind:** missing.
- **Proposal (if PQ-54 keeps it), `TAC > TAC-PEOPLE`:** "A member of a quest's team has a member id, used in branch names, session names and review attribution, and is mapped to an account at the repository server; the account suggests the id when a member is added and stands in when none is set. Access to a quest's repository, and to its internal repository, is granted through a team of that server per repository." Ask whether it duplicates CI.10.

#### AR-66 — Migrating a classic quest (`ww_e_gitruntime-8`)

- **PI:** CQ.7 migrate ("a migration goes one way only, and a trial migration shows the result"), CQ.8; PQ-53 … PQ-55. **Kind:** confirms.

#### AR-67 — Telling al_the_bear (`ww_e_gitruntime-9`)

- **PI:** D-71 (al_the_bear's approach is the standard); CQ.13; `DEL` lists only webwork and tom_forge. **Kind:** covered differently (direction reversed).
- **Proposal:** after PQ-53 / PQ-54, if anything differs from the standard, add to `DEL`: "**`al_the_bear`** is told what of the personal files (PQ-53) and of member branches (PQ-54) differs from its standard".

#### AR-68 — Create and join a repository quest (`ww_e_gitruntime-10`, `-11`)

- **PI:** CQ.7 create ("only after a confirmation, private and with GitHub Actions switched off; the quest is registered, picked for the workspace and checked out") and join; PQ-54, PQ-55. **Kind:** confirms (core); differs in detail (the todos lack confirmation, privacy, register; add `_internal`, team grants, member branch). No PI change.

#### AR-69 — Pilot repository quest with two members (`checks11`)

- **PI:** CQ.8 (a migration pilot, not a new two-member quest); PQ-57. **Kind:** missing as stated.
- **Proposal:** if PQ-54 keeps the features, add a flow to `NFR-TOPO-FLOWS`: "two members on one repository quest: join, publish, update, conflict review, process move".

#### AR-70 — The runtime scripting API split (`ww_e_runtimeapi-1`)

- **Source:** split `tom_vscode_scripting_api` into wire / Tom APIs / Agent SDK mirror (runtime API) and the VS Code namespace; answers: protocol a superset of the Vce methods; package `tom_runtime_scripting_api` in the tom_vscode repository, "the runtime shall go into the vscode repository, too"; re-export; it is Tom Forge's client.
- **PI:** CP.12, D-11, CL.10 "The Dart runtime client SDK grows out of today's Dart client of the extension's script server"; CL.3 "`tom_ai/ai_build/tom_ai_runtime_client`"; G-1 / D-1 runtime in `tom_ai/ai_build`; DEL promises tom_forge CL.3.
- **Kind:** confirms (split, protocol); differs (name and place of client **and runtime**); missing (the VS Code scripting API keeps the VS Code namespace and re-exports the client).
- **Question:** (a) **follow the PI: `tom_ai_runtime_client` and the runtime in `tom_ai/ai_build`; rewrite the todos**; (b) follow the todo's answer: CL.3, G-1, G-4, D-1 move to the tom_vscode repository and the name `tom_runtime_scripting_api`; (c) client in `ai_build`, split done there first. *Recommendation:* (a); the v2 decision ("a copy of the extension in the ai_build repo") points the same way (V2-21). Record as decision and `CON` entry. New **CL.13**: "`tom_vscode_scripting_api` keeps only what a VS Code window can serve (the VS Code namespace), depends on the Dart runtime client SDK and re-exports it, so existing scripts keep their import." Note: `tom_vscode_scripting_api` is at 7.0.0 (pubspec); PI E-1 says 6.0.0 and the todos 3.0.0 → 4.0.0: both stale.

#### AR-71 — Transport abstraction (`ww_e_runtimeapi-2`)

- **PI:** CL.10 (two targets implied), CP.1, CP.10. **Kind:** vague.
- **Proposal (CL.10):** "Its connection is an exchangeable transport: one to a VS Code window's script server, one to a runtime (CP.1), each carrying the commands and the reverse requests (CP.10)."

#### AR-72 — Tom APIs and Agent SDK mirror move in (`ww_e_runtimeapi-3`)

- **PI:** CL.10, CL.9 (no Flutter). **Kind:** confirms; missing (no dependency on the VS Code API) → CL.9 add "nor on the VS Code scripting API"; CL.13 above.

#### AR-73 — Transport to the runtime server (`ww_e_runtimeapi-4`)

- **PI:** CP.2, CP.24 (three versions; the todo checks two), CL.6, CP.4/CP.5, CP.35. **Kind:** confirms.
- **Proposal (CL.6, optional):** "… and the Dart runtime client SDK answers the same through a VS Code window's script server as through a runtime, for the commands both serve."

#### AR-74 — Publishing both packages and moving the consumers (`ww_e_runtimeapi-5`)

- **PI:** N-29; no item on moving existing consumers (d4rt command line and bridges, the VS Code bridge, `tom_core_agentic`). **Kind:** missing.
- **Proposal:** new item in `CLI-PACK`: "The existing users of today's Dart script client — the d4rt command line and its script bridges, the VS Code bridge, and Tom Core's agent code — move onto the Dart runtime client SDK when it is published; each is released by its own quest." Ask whether `tom_core_agentic` should depend on the client SDK, which depends on `tom_tac_client` (CL.2).

#### AR-75 — Documents and Tom Forge (`ww_e_runtimeapi-6`)

- **PI:** N-30, `DEL`. **Kind:** confirms; content depends on AR-70.

#### AR-76 — One script against a window and a runtime (`checks10`)

- **PI:** CL.10 "Scripts that use that client keep working against a VS Code window and against a runtime"; "runs once" rests on PQ-36. **Kind:** confirms; open (PQ-36). Under v2 "a VS Code window" can be the old or the new extension (V2-13).

#### AR-77 — Sequencing of the scripting API split

- **Source:** the `ww_e_runtimeapi` todos split the client inside the vscode_extension wave; `DEL` puts "The split, the protocol, the runtime client SDK" in the runtime track.
- **Kind:** vague.
- **Question:** (a) **the split is done on the old line before, CL.10 starts from its result**; (b) it waits for the runtime track. *Recommendation:* (a) — mechanical, lowers later risk; but under v2 the old line is "left alone" (V2-25), which argues for (b) or for doing it on the copy. *Unverified intent.*

#### AR-78 — The remote-control app document (S8) and `rca1`

- **Source:** S8 (one view of questions, decision-needed, queue state, errors for all runtimes on all hosts; the MD Browser editor for document asks; a phone app; the Telegram redesign); `rca1`: take the idea through `idea_to_todos`.
- **PI:** `CLI > CLI-TRC` CK.1 … CK.12 (S8 absorbed: CK.1, CK.2, CK.4, CK.9, CK.10; open PQ-43, PQ-49, PQ-50); Telegram L-9 / D-6; trc has no overview screen description of its own (no SC row for trc found; CU inventory not read in full).
- **Kind:** confirms (S8); covered differently (rca1 would produce a second specification of trc; its Telegram premise contradicts D-6); vague (trc's overview screen).
- **Question on rca1:** (a) **cancel: trc is specified in the PI**; (b) keep it with the PI's CLI-TRC as input, for the prototype only; (c) as written. *Recommendation:* (a).
- **Proposal (optional) CK.13:** "trc's overview is one screen, grouped by host and runtime, listing per run its state, the open asks with their age, the todos that wait for a decision, the queue and the errors; selecting an entry opens the ask, the document or the run."

### A.6 The quest's documents

#### AR-79 — Quest notes (S4), product owner's notes, read only

| Note | PI | Kind |
| --- | --- | --- |
| MCP relay service for machines off the VPN | CA.30 "The **relay** is part of the tac server. It carries TAC and MCP for machines that are not on the VPN"; D-23 | covered differently (part of the tac server, not "an additional service"; decided) |
| Split of the MCP server into a coordination MCP and a VS Code MCP | CT.11; CT.8; CT.1; D-9 | confirms |
| a, b, c, d, e, f, g, h, i, j, k (first), l (first), l (second), m, n, names | CR.1; CT.1, CT.8, O-1; CT.13; CT.4/CT.5; CT.2, CT.14; CP.1 / D-10; CP.3, CP.12; TAC-SPEC; CLI-TRC; S6 / D-42; VIS; O-3; O-8; CQ.1, CQ.8; GLO | confirms |
| k (second): other languages "mechanically … generated based on the Dart code" | CL.4, CP.11, D-3 (FO-10): generated from the JSON schema | differs, settled by FO-10 |
| b vs the first note (file access through the runtime's MCP server) | CT.11 follows the first note | differs, resolved silently |
| d: the MCP server of "the webwork instance or the webforge instance" | CT.8 allows an MCP server only "Inside VS Code"; Flutter hosts register tools (CT.4) | differs |

- **Proposals:** `D-3`'s "Replaces" column names note k; optional `CON` entry "S4 note b against S4's first note — resolved: the first note holds (CT.11, D-9, N-18)".
- **Question:** may Webwork and Webforge also offer their tools as one MCP server? (a) yes, CT.8 for every host; (b) **no, registered host tools only**. *Recommendation:* (b).
- Note k (first): "Now the main idea is get a comprehensive collaboration system by using the ai runtime … just be attaching to the runtime and adding a hopefully relatively thin UI on top of it" — the v2 extension is exactly such a host (V2-4).

#### AR-80 — `ai_runtime_feature_overview.md` (S2)

- FO-1 … FO-13, FO-15 … FO-22 all map to decisions (D-1, D-7, D-14, D-10, D-9, D-28, D-29, D-23, D-3, D-4, D-5, D-34, D-19, D-6, D-2, D-31) and items: **confirms**. **FO-14 does not exist**; the PI's "FO-1 … FO-22" (SRC S2, ABOUT-READ) counts one too many: cosmetic.
- § 3.1 `TomLayout` with `_copilot_guidelines/` is outdated in the live document (CR.33 has `_agent_guidelines/`): quest document to fix.
- § 3.4 claims on `infra:` / `ai:` keys: covered differently (D-68, `git:` for now).
- § 3.7 `tom_git` (pure Dart git) for repository quests in Webwork and on phones: **missing**, low priority; mention as an option in PQ-55 or leave to the Blueprint.
- § 4.1 … 4.3 execution order, stages, RS-1/4/5: confirms D-40 … D-42 — and are changed by the v2 decision (V2-1, V2-3).

#### AR-81 — `ai_runtime_concept.md` (S1)

Section by section the PI covers it (the research agent's table: § 1 … § 16 all confirm). Gaps:

- **§ 3.3 expression system** ("An expression system common to JavaScript and Dart is to replace `${{js}}` (tom_forge `qavs_wwworkbench-1`)"): CR.5 says only "the expression language". **Missing.** Proposal, new item in `RT > RT-HOLDS` after CR.5: "The expression language of prompts, templates and process definitions is one language, evaluated the same way by the runtime and by Dart applications. Tom Forge plans an expression system common to JavaScript and Dart to replace `${{ … }}` (S26: `qavs_wwworkbench-1`, planned); the runtime takes it over when it exists, and expressions already written keep working. (S1 § 3.3; S2 § 3.1)", plus an `RISK-DEPS` row. **Question:** (a) runtime keeps `${{js}}`, Tom Forge adapts; (b) **the runtime adopts the common system, `${{js}}` still accepted**; (c) Blueprint. *Recommendation:* (b).
- **§ 3.3 crash restart** ("a crash is reported and restarted on request"): CP.2 leaves it to the Blueprint. **Vague.** Proposal (CP.2): "A host is told when its runtime process ends without having been asked to, and can start it again; the runtime does not restart by itself. (S1 § 3.3; S14)".
- **§ 3.5 lessons from tom_uam:** edit tools failed on large documents; "Finish review round" refused at a sub-step; a gate needed two runs. **Missing.** Proposals: new **N-44**: "The runtime's tools on specification documents work on documents of the size the specification process produces (this Project Idea is about 460 KB); an edit on a large document neither fails nor times out where the same edit on a small one succeeds. The Solution Blueprint names the size the tools are tested at. (S1 § 3.5)"; CR.10 add: "A process move offered by a button (finishing a review round, a decision) is accepted at a sub-step of the step it belongs to. (S1 § 3.5)" (whether CR.10 already covers it: *unverified*).
- **§ 7.10 service clock** → AR-30; **end-to-end check** → AR-33.
- **§ 10.4 item 10, draft pull request for a risky todo:** CW.15 / CW.17 do not have it. **Missing.** Proposal (CW.15): "For a todo whose paths carry weight, a draft pull request can be opened on request, as a place to review it; it never takes the place of the integration step (CW.5), and the system never merges through it." Or ask: (a) dropped; (b) **an option a person asks for**; (c) later.
- **§ 5.5 `quest-resources.<quest>.yaml`** → AR-14.
- **§ 13.1 two wishes for tom_specs** (generating detailed documents and code-generation inputs from a Blueprint): not in the PI; outside this product. Proposal: a `DEL` line "What the other quests are told: `tom_specs` …" if they should not get lost.
- **§ 13.3 "The split and the stable extension"** (CQ-19: branched, own extension id, separate worktree, old changes merged forward): source of D-41, changed by the v2 decision (V2-1, V2-2).

#### AR-82 — `ai_runtime_project_idea.md` (S20)

- The first collection (2026-11-16), superseded by S1 (PI: "superseded by S1; background only"). Carried over in substance; the open question "how remote tools are named when two runtimes offer the same one; how a call is routed and authorized across runtimes" is not settled: **vague**.
- **Proposal:** new **CT.18** (`RT > RT-MCP`): "A tool of another runtime keeps its name; the agent chooses the runtime by an argument naming the target quest (and, where a quest has several runtimes, the user), not by a different tool name. A call to another runtime is checked there by the bearer token of CT.12 and the rules of PQ-50. (S20 § 12; S4, note e)".
- S20's "The dev build must not raise the `_ai` format while the stable build uses the same `_ai`. Test windows work on a sandbox `_ai`" is not in the PI → V2-18.

#### AR-83 — `ai_runtime_terminology.md` (S21) against `GLO`

- Term sets and meanings equal; one typo in GLO's **server** row: "the **tac server**,an **MCP server**" (missing space). **Kind:** confirms, cosmetic fix. Section B adds terms (V2-11), which S21 must take too ("the two are kept equal in content").

#### AR-84 — overview, short description, progress, questions log, decisions, deferred, open topics

| Document | Finding | Kind |
| --- | --- | --- |
| `short_description.ai_runtime.md` | names `tom_quest_runtime`, "Telegram routing for every runtime", runtime "being built in the `vscode_extension` quest"; the PI has `tom_ai/ai_build/tom_ai_runtime` (D-1), Telegram deferred | differs (quest document outdated) |
| `overview.ai_runtime.md` | names `tom_quest_runtime` and the tom_vscode repository; calls `ai_runtime_project_idea.md` "the input to the tom_specs process"; does not name the PI or the spec root | differs |
| `progress.ai_runtime.md` | last entry 2026-11-16; nothing on the concept, terminology, PI rounds 1 … 4 | differs |
| `questions.ai_runtime.md` | every round answered; PQ-34 … PQ-59 have empty Answer lines in the PI although round 4 was finished with "Finish review round" (whether answers are kept elsewhere: *unverified*) | vague |
| `decisions.ai_runtime.md` | one entry (tom_specs decision step "Initial development") | confirms |
| `deferred.ai_runtime.md` | Telegram → L-9 / D-6 (confirms); soft-interrupt entry stale → AR-47 | confirms / differs |
| `open_topics.ai_runtime.md` | empty | — |

- **Proposal:** quest documents to update (no PI change). All of them also need the v2 decision recorded (overview scope row; the split plan marked superseded in its RS-1 part).

### A.7 Section A counts

84 findings (`AR-1` … `AR-84`). Counted from their **Kind** lines (for AR-79 … AR-84 from their tables), a finding can carry several kinds: 23 with a missing part, 25 that differ (including "covered differently" and "contradicts"), 24 vague, 24 that only confirm.

---

## B. The second extension (v2)

### B.0 The decision and what it replaces

The product owner, 2026-11-25: "I want to create a second extension for this and leave the existing extension alone until we have really finished the new extension. For this we'll make a copy of the extension in the ai_build repo and work on this until it works with the AI runtime and all features working as before (only distributed and with a team). Once the new extension is working fine and stable I will retire the old extension and move the new one in its place, so it looks as if it is just a new (v2!) version of the extension. Maybe I will maintain both vs code extension for longer."

What stands today:

- **S18 / RS-1:** recommended (a) one source line with a pinned stable build; option (b) was "A copied source folder as a second extension, developed separately" — the product owner now takes (b), in the ai_build repository.
- **S1 § 13.3 / CQ-19 → PI D-41 and `DEL` "The stable extension during the split":** a *branch* of the extension, its own extension id, a separate working tree, refusing to start beside the old one, old changes merged forward.
- **S19 § 7 and the `ww_b_workbench-*` todos:** an in-place extraction in stages, the extension green after each, no copies left behind.

Facts used below (verified): the extension is `tom_ai/vscode/tom_vscode_extension`, `package.json` name `tom-ai-extension`, display name `@Tom`, version `0.1.0`, 85 commands, 21 views (activity bar and panel), 16 settings all under `tomAi.*`, two custom editors (`tomAi.todoEditor`, `tomAi.trailViewer`). The runtime's place is already `tom_ai/ai_build/tom_ai_runtime` (D-1). The vscode_extension quest has 210 not-started todos, among them `01_aifmt-1` (Copilot removal, in-progress), `01_aifmt-5` (format version 11), `02_aifmt-1` (quest management).

### B.1 What changes in the Project Idea

#### V2-1 — `DEC` D-41 is replaced

- **PI:** D-41 (`DEC`, source CQ-19): "During the split the extension is branched, the new line has its own extension id and working tree, and it refuses to start beside the old one in the same window." Replaces RS-1. Section `DEL`.
- **Kind:** differs.
- **Proposal (new decision, next free D-73, replacing D-41):** "| **D-73** | product owner, 2026-11-25 | The runtime is not extracted from the VS Code extension in place. The extension is copied into the repository `tom_ai/ai_build` as a second extension with its own extension id, and the copy is rewired to the runtime until every feature of the old extension works as before, distributed and with a team. The old extension is left as it is meanwhile. When the new extension is stable it takes the old one's place as its next major version, with the old one's identity, and the old one is retired; both may be maintained side by side for a while. | D-41 (CQ-19); RS-1 (a) | `DEL`, `SCO > SCO-IN` |" The open points V2-15 … V2-29 refine it.

#### V2-2 — `DEL` "The stable extension during the split" is rewritten

- **PI (`DEL`, S1 § 13.3, CQ-19; D-41):** "The extension is branched; the new line gets its own extension id and is worked on in a separate working tree." / "The new extension refuses to start while the old one is active in the same window." / "The new one is installed everywhere and activated only in the window used for testing, where the current one is deactivated." / "The old extension keeps being changed as needed; its changes are merged forward into the new line, or their work is repeated there."
- **Kind:** differs (bullets 1 and 4); bullets 2 and 3 depend on V2-15.
- **Proposal (heading "The second extension (v2)"):**
  - "The extension is copied, at a point the product owner names (V2-19), into the repository `tom_ai/ai_build` as a second extension with its own extension id; the copy is rewired to the runtime there."
  - "The old extension is left as it is: no work of the new one is done in it; what it still gets is said in V2-25."
  - (bullets 2 and 3 as answered in V2-15 / V2-28)
  - "The new extension is finished when every feature of the old one works in it as before, through the runtime, and the team features work across machines (V2-23)."
  - "Then it takes the old one's place as its next major version, with the old one's identity (V2-20); the old one is retired and archived (V2-22), unless both are kept side by side for a while."

#### V2-3 — `DEL` "What comes before the building" and D-40

- **PI:** `DEL` step 1 "The VS Code extension's features are finished. They include the new format of the `_ai` files and the quest management of the standard (D-71) …"; step 3 "This specification is written, and the product is built from it. The split of the extension starts here."; D-40 "The split of the extension starts after the extension's features and the workspace layout are finished." (RS-3, RT-5); R-16 "The engine being complete before it is extracted".
- **Kind:** differs. With a copy, "the split starts" becomes "the copy is taken"; RT-5's reason (move each line once, in its final form) becomes "copy once, from the final form". The open choice is when (V2-19).
- **Proposal:** step 3: "… The second extension is copied from the old one here (D-73)." D-40: "The copy of the extension is taken after the extension's features and the workspace layout are finished (V2-19)." R-16 "For": "The engine being complete before it is copied".

#### V2-4 — `SCO > SCO-IN`, row "The split", and `SCO-OUT` O-1

- **PI:** SCO-IN: "The split (no area of its own: D-40, D-41; N-24, N-32, N-33; R-1; `DEL`) | Extracting the engine from the VS Code extension, with a stable extension beside it while that runs | S1 § 13.3". O-1: "The VS Code extension's own features: its views, panels and editors, and the tools that need VS Code. They stay in the extension, which becomes a host. Its messaging views, which it gets once the runtime is built, are among them: messaging is built here as Flutter components only (O-3)."
- **Kind:** differs. The engine is no longer *extracted* from the extension; the runtime is built (from code of the extension) and a *copy* becomes the VS Code host. O-1's "the extension, which becomes a host" now means the new extension, and since the new extension is built in `tom_ai/ai_build` by this quest, whether its views are in or out of this product's scope is a real question (V2-26).
- **Proposal:** SCO-IN row "The second VS Code extension (v2) | A copy of the extension in `tom_ai/ai_build`, rewired to the runtime as the VS Code host, until every feature works as before, distributed and with a team; its taking the old one's place | D-73". O-1: "… They stay in the VS Code extension; the second extension (D-73) carries them over unchanged as the VS Code host's own …" — wording follows V2-26.

#### V2-5 — `RISK > RISK-RISKS` R-1 and R-13; a new risk

- **PI:** R-1 "**The split of a large extension while it keeps changing.** … Changes to the old line during the split have to be carried into the new one." Trigger: "A feature or fix lands in the extension after the split has begun; a stage of the split leaves the extension not working." R-13: several hosts and runtime versions on one set of workspace files.
- **Kind:** differs (R-1's second trigger falls away: the old extension is not touched); R-13 gains a case.
- **Proposal:** R-1: "**Two copies of one large code base.** The old extension and its copy diverge from the copy point; every fix the old one still gets has to be repeated in the copy, and a feature added to the old one after the copy point is a feature the copy lacks." Trigger: "A fix or feature lands in the old extension after the copy point." New **R-31**: "**Two engines on one `_ai` during the parallel period.** The old extension's own engine and the runtime read and write the same quest files on one machine; a format or behaviour difference between them corrupts or misreads a file. | The new extension is used on a quest the old one also works on; the runtime writes a format version the old extension does not know (CP.28)." New **R-32**: "**The swap.** The new extension takes the old one's identity: its users' settings, key bindings and the documents and prompts that name its commands and views must keep working. | The new extension is published under the old id (V2-20)."

#### V2-6 — `NFR` N-33 (and N-32, N-24)

- **PI:** N-33 "Every stage of the split leaves the extension working and installable. (S19; S1 § 13.3)". N-32 guards; N-24 runtime without VS Code.
- **Kind:** differs (N-33); confirms (N-24, N-32: they bind the runtime and stay).
- **Proposal (N-33):** "The work on the second extension changes nothing of the old one; the second extension is installable at every step, in a window or profile where the old one is not active (V2-15)."

#### V2-7 — `LAND` E-1, E-22 and the owning quest

- **PI:** E-22 (`LAND > LAND-WAIT`): "`vscode_extension` | The split: its engine becomes the runtime and the extension a host. Messaging, which the extension gets once the runtime is built. Until the split its engine keeps changing, and the migration to format version 11 is done there."
- **Kind:** differs. The old extension's engine does not become the runtime in place; vscode_extension does not wait for the split.
- **Proposal (E-22):** "`vscode_extension` | Keeps the old extension, which is left as it is once the copy is taken (D-73); until then its engine keeps changing and the migration to format version 11 is done there. After the swap it owns the extension again, then the new one (V2-26)."

#### V2-8 — In process or a runtime process: G-1, CP.14, T1, CT.8

- **PI:** G-1 "server (also a library inside the VS Code extension)"; CP.14 "In VS Code the interface is implemented in the extension's process; in every other host it is carried by the protocol's reverse requests."; T1 "One runtime per window, inside the extension"; CT.8 "Inside VS Code the extension may offer its tools to the runtime as one MCP server".
- **Kind:** vague under v2. "Until it works with the AI runtime" can mean the runtime as a library in the new extension's process (as G-1 / CP.14 say) or a runtime process the new extension starts like every other host.
- **Question → V2-16.** The items follow the answer.

#### V2-9 — VS Code LM and Copilot: D-7, O-4, CS.13

- **PI:** D-7 "the runtime does not carry the VS Code language-model and Copilot chat transports; Copilot only through direct calls and its SDK"; O-4 "In the VS Code extension the 'VS Code LM' transport inside its Anthropic panel stays until the route through the Copilot SDK works."
- **Kind:** vague / differs. "All features working as before" includes these transports where the old extension still has them at the copy point; D-7 says the runtime will not carry them; O-4 does not say which extension keeps VS Code LM. The old extension is removing Copilot now (`01_aifmt-1`).
- **Proposal (O-4):** "… The VS Code LM transport is not carried into the second extension unless V2-24 decides otherwise; until the Copilot SDK route works (CS.13) it is available only in the old extension." Depends on V2-24.

#### V2-10 — `CLI > CLI-SCREENS` CU.10, CU.11 and the SC inventory

- **PI:** CU.10 "There is a complete inventory of the extension's screens: every view, panel and editor, and for each one what it becomes here." CU.11 outcomes `reused`, `starting point`, `split`, `host's own`, `not needed` — they say what a screen becomes *as a Flutter component*.
- **Kind:** vague. With v2 every screen also has a fate *in the new extension*: kept unchanged over the runtime (the default), changed, or dropped (V2-24). The inventory is the natural checklist for "all features working as before".
- **Proposal:** CU.10 add: "The same inventory lists, per screen, whether the second extension keeps it as it is over the runtime, changes it, or drops it (D-73); a screen that is not listed as changed or dropped is kept."

#### V2-11 — `GLO` (and S21)

- **PI:** GLO **application** "VS Code with the extension, Webforge, Webwork, the supervision application"; **host** "The program that starts a runtime …"; no entry for the old or new extension, the copy point or the swap.
- **Kind:** missing.
- **Proposal (new rows, copied into S21):** "| **old extension** | The VS Code extension as it is today (`tom_ai/vscode/tom_vscode_extension`), with its engine inside; left as it is while the new one is built, retired after the swap (D-73). |" / "| **new extension** (v2) | The copy of the old extension in `tom_ai/ai_build`, rewired to the runtime; the VS Code host. After the swap it is "the extension". |" / "| **swap** | The step in which the new extension takes the old one's identity and the old one is retired (D-73). |" Wording choice: "old / new extension" or "v1 / v2" (PQ-58 is the place for words used in several senses).

#### V2-12 — The `ww_b_workbench-2 … 7` plan

- **Source:** todos quoted in A.1; S19 § 7.
- **Kind:** differs. The stages assume one code base moved out step by step ("the extension builds on it", "no copy of a moved file remains in the extension", "one installed VSIX works in a reloaded window").
- **Proposal (the same stages, against the copy):**
  - `ww_b_workbench-2` → **"the runtime package and the copy"**: create `tom_ai/ai_build/tom_ai_runtime` (D-1; not `tom_quest_runtime` in tom_vscode) with build, test runner, lint, BSD-3, the vscode-import guard; copy the extension into `tom_ai/ai_build/<name>` (V2-19, V2-15) with its own id, building, packaging and passing the old suites unchanged; record the source commit. DONE WHEN adds: the old extension's folder and repository are unchanged.
  - `-3 … -7` keep their content (vscode-free modules, host interface with `VscodeHost` in the **new** extension, stores, engines and transports, tools and the MCP server), but each move is **from the copy into the runtime**; "no copy remains in the extension" applies to the copy; "the VSIX works in a reloaded window" becomes "the new extension's VSIX works in a test window / profile (V2-15) on a sandbox quest (V2-18)". `-4`'s locations follow D-17 (the layout resolver), not RT-6. `-6`'s host transports follow V2-9 / V2-24. `-7`'s MCP server follows CT.11 / CT.8 (AR-6).
  - The 2026-11-04 notes ("blocked until the ccparity groups a to g are done") are replaced by the copy point (V2-19).
  - If V2-16 answers "a runtime process", `-4 … -7` are re-cut: the host interface is reverse requests from the start, and `ww_d_workbench-9` (server and protocol) moves before the rewiring of the engines rather than after `-7`.

#### V2-13 — The `ww_d_workbench-9 … 12` plan, and new todos

- **Kind:** differs in part.
- **Proposal:**
  - `-9` (server and protocol): unchanged in content; its conformance test "the files it writes match what the extension writes for the same operations" names **the old extension** as the reference — the old extension becomes the oracle of "as before" (V2-23).
  - `-10` (packaging): unchanged; the new extension installs the runtime installation (CR.40 ff.) rather than bundling an engine.
  - `-11` (two hosts on one quest): becomes "**the old extension and the runtime on one `_ai`**" (R-31): queue ownership, a timed request firing once, todo claims, lost writes, between the old in-process engine and a runtime; plus two runtimes (PQ-36). Depends on V2-17 / V2-18.
  - `-12` (documents): "the split extension" → the new extension's documents; tom_forge told as before.
  - **New todos needed:** the team features in the new extension (V2-29); the acceptance run against the feature inventory (V2-23); the swap (identity, settings migration, version, V2-20); the retirement and archive of the old extension (V2-22); the scripting server / bridge ports in the new extension (V2-27).
  - `ww_e_runtimeapi-*` and `checks10`: "a VS Code window" may be the old or the new extension; the VS Code namespace of `tom_vscode_scripting_api` must work against the new one (AR-70, V2-27).

#### V2-14 — Hand-off and delivery wording elsewhere

- **PI:** `DEL` track table "**the runtime** | The split, the protocol, …"; S18 § 5 hand-off after `ww_b_workbench-7` / `ww_d_workbench-12`; `ww_g_collab-999`.
- **Kind:** differs (wording).
- **Proposal:** DEL track row: "The runtime, the second VS Code extension (D-73), the protocol, …"; the hand-off is the swap.

### B.2 Open choices for the product owner

#### V2-15 — Identity while both are installed

- **Context:** VS Code identifies an extension by `publisher.name`; contribution ids (commands, views, view containers, custom editors, settings) are global in a window. Today: name `tom-ai-extension`, display name `@Tom`, every contribution under `tomAi.*` (85 commands, 21 views, 16 settings, 2 custom editors). D-41 required "refuses to start while the old one is active in the same window".
- **Options:**
  - **(a)** New extension id (e.g. `tom-ai-extension-v2`, display name "@Tom v2"), **same contribution ids and the same `tomAi.*` settings**; the two are never active in one window — VS Code profiles (*Work* with the old, *Dev* with the new) or per-workspace enable / disable; the new one refuses to start while the old is active (D-41's rule kept). At the swap nothing is renamed: settings, key bindings, documents and prompts naming `tomAi.*` stay valid.
  - (b) New id **and** a new prefix (`tomAi2.*` commands, views, settings), so both run in one window; at the swap everything is renamed back and users' settings migrated.
  - (c) Same id as the old (installed from a VSIX over it, per profile); no side-by-side install in one profile at all.
- *Recommendation:* (a) — the swap stays a re-publish under the old id with nothing renamed; (b) doubles the swap's work and every prompt naming a command; (c) cannot be installed beside the old in one profile.
- *Unverified:* whether the extension's script-bridge ports (19900 – 19909) and MCP port (19920 upward) let two extensions on one machine coexist (both scan upward; which one a script finds first is not known) → V2-27.

#### V2-16 — The runtime in the new extension: library in process, or a process

- **Context:** G-1, CP.14, T1 say "a library inside the VS Code extension"; every other host uses a runtime process over the protocol.
- **Options:**
  - (a) In process, as G-1 / CP.14 say: the new extension loads the runtime package; the host interface is direct calls.
  - **(b)** A runtime process started from the runtime installation, like every other host; the new extension is a runtime client over the protocol; G-1's "also a library inside the VS Code extension", CP.14's first half and T1's "inside the extension" are removed.
  - (c) Both: in process first, a process later.
- *Recommendation:* (b) — one path for every host, so the new extension tests the protocol every other host depends on; it matches "only distributed and with a team"; the cost is stream latency and the work of `ww_d_workbench-9` coming earlier (V2-12). If (a), the conformance suites must run a second host anyway.

#### V2-17 — The old extension during the parallel period: own engine, or attached to the runtime

- **Context:** "leave the existing extension alone" keeps its in-process engine. Then a machine has two engines on one `_ai`: the old one's and the runtime's (R-31). Today two VS Code windows on one quest are already two engines on the same files, with heartbeats and queue-file ownership (PQ-36's context).
- **Options:**
  - **(a)** The old extension keeps its own engine; the two must not run on the same quest at the same time during development (the new one on sandbox quests), and later may, under the rules of `ww_d_workbench-11`.
  - (b) The old extension keeps its engine and they may share a quest from the start: `ww_d_workbench-11` comes first.
  - (c) The old extension is changed to attach to the runtime — contradicts "leave alone".
- *Recommendation:* (a).

#### V2-18 — `_ai` format compatibility between the old engine and the runtime (CP.28, CP.29)

- **Context:** the `_ai` format is version 10 today (E-1); version 11 is decided and not built (S22 § 3.6), its migration is vscode_extension `01_aifmt-5`; SCO-IN says the runtime's core is "The `_ai` formats and stores in format version 11". CP.28: a runtime that finds a newer format stops working on it; CP.29: migration once per machine under a lock, open in PQ-40. S18 § 3 rule 1: "The dev build must not raise the `_ai` format while the stable build is used on the same `_ai`." Rule 2: test windows on a sandbox `_ai`.
- **Options:**
  - **(a)** The old extension reaches format 11 before the copy (D-40's order, V2-19); the runtime writes format 11; no format change until the swap; a needed change waits for the swap or is made in the old extension first. The new extension's test windows work on sandbox quests until both agree file by file (`ww_d_workbench-9`'s conformance test).
  - (b) The runtime reads and writes two format versions during the parallel period.
  - (c) The new extension works only on a separate `_ai` (a second clone) until the swap.
- *Recommendation:* (a) — one format, the old extension as the reference; (b) adds a format the PI rules out (CR.1); (c) cannot test "distributed and with a team" on real quests.
- **Proposal (PI):** add to CP.29: "While the old extension and the runtime both work on one machine (D-73), the format version changes only when both know it."

#### V2-19 — The copy point

- **Options:**
  - **(a)** After the old extension's open features that change the engine and the format are done (D-40's step 1: format 11 `01_aifmt-5`, quest management `02_aifmt-1`, the Copilot removal `01_aifmt-1`), from a tag in the tom_vscode repository (e.g. `tom_vscode_extension-v1-final`, name to choose); a plain copy without history, the tag recorded in the new extension's README; the old extension frozen for features from then on.
  - (b) Now, from `main`: the copy starts at once; every later feature of the old one is repeated in the copy.
  - (c) Now, with history (`git subtree` / `filter-repo` of the folder into `tom_ai/ai_build`).
- *Recommendation:* (a) — copy once, from the final form (RT-5's reason); with history only if V2-20 answers that the new extension moves back into tom_vscode, where the old history is anyway.
- **Also open:** which of the 210 not-started vscode_extension todos still land in the old extension before the copy, and which are carried to the new extension (a list for the product owner, one line per todo group). *Not done here.*

#### V2-20 — The swap: identity, place, version

- **Options for the place after the swap:**
  - **(a)** The new extension's folder moves into `tom_ai/vscode`, in place of `tom_vscode_extension` (the old one archived first, V2-22); its history from `tom_ai/ai_build` is carried along or summarised.
  - (b) It stays in `tom_ai/ai_build`; `tom_ai/vscode` keeps the scripting API and the bridge only.
- **Identity and version:** the new extension is published under the old name `tom-ai-extension` and publisher, as version 2.0.0 (the old one is 0.1.0; whether to mark the old one 1.0.0 first is a choice).
- *Recommendation:* (a), matching "move the new one in its place, so it looks as if it is just a new (v2!) version"; version 2.0.0.

#### V2-21 — Where the runtime lives

- **Context:** D-1 and G-1: `tom_ai/ai_build/tom_ai_runtime`; the copy goes into `tom_ai/ai_build` too. The answer in `ww_e_runtimeapi-1`: "the runtime shall go into the vscode repository, too" (AR-70).
- **Options:** **(a)** `tom_ai/ai_build` (D-1) for the runtime, the new extension and the Dart runtime client SDK (CL.3); (b) the tom_vscode repository; (c) the runtime in `ai_build`, the new extension moving to tom_vscode only at the swap (= V2-20 (a)).
- *Recommendation:* (a), with V2-20 (a) at the swap; record that `ww_e_runtimeapi-1`'s answer is replaced.

#### V2-22 — Retiring the old extension

- **Context:** `retiring_and_archiving.md`: before removal, the last committed state is copied into `tom_archived` under `code/<yymmdd>_<description>/<repo-name>/<path>` with `RETIRED.md` and an `INDEX.md` entry; "retiring is a user decision".
- **Options for what is retired:** (a) **only the old extension's folder** (`tom_vscode/tom_ai/vscode/tom_vscode_extension`, or the repository's own path), at the swap; (b) also what only it uses (its install scripts; the `tom_vscode_bridge` if the new extension no longer serves the JSON-RPC script server — V2-27); (c) nothing removed while both are maintained; archive when the old one's maintenance ends.
- *Recommendation:* (c) then (a): retire when maintenance of the old one ends, not at the swap, since "Maybe I will maintain both … for longer"; decide (b) per item then. Under V2-20 (a) the old folder must be archived before the new one takes its path.

#### V2-23 — Tests and acceptance: "all features working as before"

- **Options:**
  - **(a)** The new extension passes the old extension's test suites (copied with it, then pointed at the runtime); the runtime passes `ww_d_workbench-9`'s conformance test against files the old extension wrote for the same operations; a feature inventory (CU.10, V2-10, plus the 226 tools) is checked off in a live run per feature; the team features are checked on two machines (T3) and with a second member (T4).
  - (b) Only the runtime's and protocol's own suites and a live check.
- *Recommendation:* (a). Put it into PQ-57's options as the acceptance of the new extension.

#### V2-24 — Features the new extension may drop

- **Candidates (verified to exist or be planned):** the VS Code LM transport and the Copilot chat transport (D-7, O-4; Copilot already being removed in the old one, `01_aifmt-1`); queue reminders after a wait (already leaving with format 11, E-1); today's per-quest Telegram (D-6 defers the redesign); the four features PQ-35 asks about (quest refresh, the "window" level of guideline choices, `prerequisites.yaml`, stored prompt after restart); the JSON-RPC script server (V2-27); features of `collab_and_features` not built by the copy point (AR-27).
- **Options:** **(a)** the new extension is the old one minus D-7's transports; every other drop is listed by name and decided one by one; (b) the new extension takes only what the SC inventory marks `reused` / `starting point` / `host's own`, the rest dropped.
- *Recommendation:* (a) — "all features working as before" is the product owner's bar.

#### V2-25 — What the old extension still gets during the parallel period

- **Options:** **(a)** fixes only, each repeated in the new extension by a todo; no features after the copy point; (b) nothing at all; (c) features as needed, each repeated in the new one (= R-1 as it stands).
- *Recommendation:* (a) — "leave the existing extension alone" with the agents still running on it.

#### V2-26 — Scope and owning quest of the new extension

- **Context:** O-1 puts "The VS Code extension's own features: its views, panels and editors" out of this product's scope; the new extension is built by ai_runtime in `tom_ai/ai_build`.
- **Options:** **(a)** In scope as the VS Code host (its host-interface implementation, the rewiring, its team features), its views carried over, not redesigned; ai_runtime owns it until the swap, vscode_extension after; (b) out of scope: vscode_extension builds the new extension against the specification; (c) in scope as a full capability group with its own items.
- *Recommendation:* (a); O-1 and E-22 reworded accordingly (V2-4, V2-7).

#### V2-27 — The script server, the bridge and ports

- **Context:** `tom_vscode_scripting_api` 7.0.0 and `tom_vscode_bridge` reach the extension's JSON-RPC server on ports 19900 – 19909; the MCP server on 19920 upward (`ww_b_workbench-7`); CL.10 makes the runtime protocol the scripts' target.
- **Options:** **(a)** the new extension keeps a script server for the VS Code namespace only (CL.13 proposal, AR-70) and the rest goes to the runtime; ports scan upward, and a script names which extension it wants when both run; (b) the new extension drops the script server; scripts use the runtime only, the VS Code namespace is lost until re-added.
- *Recommendation:* (a). *Unverified:* how discovery behaves with two servers on one machine today.

#### V2-28 — Running both in one window

- **Context:** D-41's "refuses to start while the old one is active in the same window"; V2-15.
- **Options:** **(a)** keep the refusal (follows from V2-15 (a)); (b) allow both (needs V2-15 (b)).
- *Recommendation:* (a).

#### V2-29 — "Distributed and with a team": what the new extension shows that the old one never had

- **Context:** O-1 / O-3 build messaging only as Flutter components; SC-28 "none in the extension: the coordination page"; SC-19 window status becomes the list of team runtimes; asks from other runtimes, leases, claims and the integration queue have no view in the old extension.
- **Options:** (a) the new extension gets VS Code views for the team features (coordination page, team runtimes, asks from elsewhere, messaging); (b) **the new extension gets the coordination page and the team-runtimes view (SC-19, SC-28) as VS Code views; messaging and review stay in Flutter applications (O-3)**; (c) none: team features are seen only in trc.
- *Recommendation:* (b) — what a VS Code user needs to work in a team is who holds what and which runtimes are there; messaging stays where O-3 put it.

### B.3 Section B counts

29 findings (`V2-1` … `V2-29`): 14 changes to the PI and the todo plan (`V2-1` … `V2-14`), 15 open choices (`V2-15` … `V2-29`), each with options and a recommendation.

<!-- snapshot of _ai/quests/ai_runtime/ai_runtime_concept.md, 2026-11-19 -->
# AI Runtime — concept

The concept for the ai_runtime quest: everything that belongs to it, brought
together from this quest, from the other active quests and from research on
what other teams do. It is the **input document for an `idea_to_todos` run**
(idea `ai_runtime_concept`): the run's question rounds, blueprint and deepening
turn it into the core of the specification and into the todos.

What is decided is stated as fact, with its decision id (`FO-n` from the
feature overview, `CQ-n`, `DQ-n` and `WQ-n` from this document's question rounds, listed in
[§ 14.1](#141-decisions)). What this document proposes is marked **Proposal**.
No question is open in this document ([§ 14.2](#142-open-questions)).

## Contents

1. [The documents of this quest](#1-the-documents-of-this-quest)
2. [Where things stand](#2-where-things-stand)
3. [What the other quests bring](#3-what-the-other-quests-bring)
4. [The system](#4-the-system)
5. [The runtime (tar)](#5-the-runtime-tar)
6. [The protocol and the hosts](#6-the-protocol-and-the-hosts)
7. [Coordination and messaging (tac)](#7-coordination-and-messaging-tac)
8. [Network topologies](#8-network-topologies)
9. [Key flows](#9-key-flows)
10. [Parallel work and the git model](#10-parallel-work-and-the-git-model)
11. [Later](#11-later)
12. [Clients, UI components and the supervision app](#12-clients-ui-components-and-the-supervision-app)
13. [What the quest delivers](#13-what-the-quest-delivers)
14. [Decisions and questions](#14-decisions-and-questions)
15. [Research: what other teams do](#15-research-what-other-teams-do)
16. [Proposed parts for the blueprint](#16-proposed-parts-for-the-blueprint)

## 1. The documents of this quest

| Document | What it is | Standing |
| --- | --- | --- |
| **ai_runtime_concept.md** (this) | everything together; the input of the idea run | current |
| [ai_runtime_feature_overview.md](ai_runtime_feature_overview.md) | components, features, the decisions FO-1 … FO-22 | current; its decisions hold. § 3.1 TomLayout and the version numbers are outdated ([§ 2.4](#24-what-is-outdated)) |
| [webwork_requirements.md](webwork_requirements.md) | what Webwork needs from tar and tac, WR-1 … WR-7 | current; a requirement statement |
| [ai_runtime_project_idea.md](ai_runtime_project_idea.md) | **the document the collection started in** (2026-11-16): notes, design, split plan, coordination, scenarios | superseded by this document as the collection; it becomes the tom_specs Phase 1 Project Idea once it is rewritten from the result of the idea run |
| [quest_runtime_design.ai_runtime.md](quest_runtime_design.ai_runtime.md) | the first runtime design, RT-1 … RT-10 | **outdated** in place, package, locations, host transports, Telegram, measurements; its host interface, process model and stage plan still carry |
| [runtime_split_plan.ai_runtime.md](runtime_split_plan.ai_runtime.md) | what comes before the split, RS-1 … RS-6 | all settled: RS-1 by CQ-19, RS-4 by CQ-20, RS-5 by CQ-17 ([§ 14.1](#141-decisions)) |
| [ideas/agent_collaboration/](ideas/agent_collaboration/agent_collaboration.md) | the coordination idea, all gates passed, todos filed | its design holds for leases, messages between runtimes, endpoints, branches; it does not know users, user messages, blobs, the relay or ai_runtime as its owner |
| [tac_specification.md](../../../tom_ai/vscode/tom_tac_service/doc/tac_specification.md) | the protocol `tac/1.0` as built | current for what is built |
| [ideas/remote_control_app/](ideas/remote_control_app/remote_control_app.md) | the supervision app, input only | not started |
| [llm_providers_runtime_integration.ai_runtime.md](llm_providers_runtime_integration.ai_runtime.md) | model providers | current |
| [quest-notes.ai_runtime.md](quest-notes.ai_runtime.md) | your notes a … n | yours |

Outside the quest, addressed to it: tom_specs'
[notes_ai_runtime.md](../tom_specs/tooling/notes_ai_runtime.md) and
[tom_specs_tooling_suggestions.md](../tom_specs/tooling/tom_specs_tooling_suggestions.md)
(S8, S9, S16, S23 are marked for this quest), al_the_bear's
[workspace_layout.md](../al_the_bear/ideas/workspace_layout/workspace_layout.md),
webwork's [webwork_redesign.md](../webwork/ideas/webwork_redesign/webwork_redesign.md)
and tom_forge's `spec_quest_workbench.tom_forge.md`.

## 2. Where things stand

### 2.1 Built

- **The engine**, inside the VS Code extension: quests, todos, processes with
  runs, the queue, sessions, transports, the `tomAi_*` tools, the MCP server,
  team review, the MD Browser. Nothing of it is a runtime yet: there is no
  runtime package, no runtime server, no Dart runtime client.
- **Coordination, stage 0:** todo follow-ups (`on_done`, `filed_by`), the done
  notification delivered to the run and session that queued a todo,
  `tomAi_sendItemToQuest` into a named run, the quest inbox, the parallel-work
  guideline. `claim_hold`, `claim_free` and `resources` are in the todo schema
  and `tom_todo_model`, unused.
- **Coordination, stage 1 in part:** the TAC specification `tac/1.0` (759
  lines, § 1 … § 11) and `tom_tac_service` 0.1.0 in local mode
  (`tom_ai/vscode/tom_tac_service/`, about 3,200 lines, 40 tests): presence,
  sessions, leases with fencing tokens, units, messages between runtimes,
  endpoints, migration, admin; HTTP and WebSocket on `127.0.0.1:19890`; the
  typed `TacClient`. **Nothing uses it yet**: the extension holds no reference
  to it.
- **Workspace layout:** the `TomLayout` resolver, its call sites, the layered
  configuration and the two-level guidelines are built in the extension
  (vscode_extension `02_wslayout-1` … `-7`, `-11`).
- **Merge drivers for `_ai` in TypeScript** (vscode_extension `vscimpb142c`).
- **Tom Secrets Manager clients:** Dart on pub.dev; TypeScript built, not yet
  on npm.

### 2.2 The agent_collaboration idea

All four gates passed on 2026-11-13; its todos were filed in four quests.

| Stage | Contains | State |
| --- | --- | --- |
| 0 — before the split | todo follow-ups, done notification, guideline | built (`ww_a_collab-1` … `7`, `-999`); open: `ww_a_collab-2b` |
| 1 — local service | TAC specification, service package | built (`ww_c_collab-1`, `-2`) |
| 1 — the rest | client and local backend, claims in the queue, messages, endpoints, Coordination page | open: `ww_c_collab-3`, `-4`, `ww_f_collab-1`, `-2`, `-3`; they wait for the split (`ww_b_workbench-7`) |
| 2 — GitHub | coordination repository, GitHub backend, auto-update | open: al_the_bear `collab_c-1`, `-2`; `ww_f_collab-4`, `-5` |
| 3 — branches and server | branches and worktrees, the server, running it on bigbeast | open: `ww_g_collab-1`, `-2`, `-3`; al_the_bear `collab_d-1` (to be absorbed by `04_wslayout-12`), `collab_d-2` (blocked) |

**Counts:** 11 collab todos completed (none in an ai_runtime file); 23 open in
ai_runtime (20 not started, 3 decision-needed); al_the_bear 3 open, 1 blocked,
1 cancelled; tom_forge and webwork 1 blocked each.

**The extension to user messaging** is not in the idea and not in
`tac/1.0`. It exists as decisions FO-7, FO-8, FO-20, FO-21, as Webwork's
requirements WR-1 … WR-6 and as proposal todos `tac_webwork-1` … `-6`
(identification, team server, user messages, blobs, Dart client, end-to-end
check), three of them waiting for a decision.

### 2.3 The todos of this quest

103 todos. Groups: the split `ww_b_workbench-2` … `7`; server, packaging, two
hosts, documents `ww_d_workbench-9` … `12`; the Dart client
`ww_e_runtimeapi-1` … `6`; repository quests `ww_e_gitruntime-1` … `11`;
coordination `ww_c/f/g_collab-*`; Webwork's `webworkreq1`, `tac_webwork-1` …
`6`, `12b_woneb1` … `3`; providers `xx*`, `ccparity_h_pi-*`; `rca1`; the
checks.

Other quests wait on them: tom_forge's whole `qavs_*` workbench group
(through `ww_b_workbench-7`, `ww_d_workbench-9` … `11`,
`ww_e_gitruntime-3`, `ww_f_collab-1`, `-3`), webwork's wave 1b2 (`13_woneb1`,
`-2`, `-6` and what follows them), al_the_bear's `collab_d-2`.

### 2.4 What is outdated

To be corrected by the idea run's result, not one by one now:

- **Names and places in todos and documents:** `tom_quest_runtime` in
  `tom_ai/vscode/` (now `tom_ai/ai_build/tom_ai_runtime`, FO-1); "Tom Agent
  Collaboration" in the TAC specification (now Tom Agent Coordination); the
  quest `agent_coordination` as owner (it is ai_runtime) in the idea, the
  specification header and `parallel_work.md`; `tom_ai/vscode/tom_tac_service`
  (to move, FO-19); host transports (removed, FO-2); Telegram in the runtime
  and in `ww_g_collab-999` (deferred, FO-16).
- **Versions:** `tom_todo_model` is 3.1.0 with 4.0.0 planned, not 2.2.0
  (`ww_a_collab-2b`, feature overview).
- **TomLayout** in the feature overview § 3.1: the resolver is built;
  guidelines are `_agent_guidelines/` first; `aiRoot` falls back to the
  root; the configuration has more layers ([§ 5.5](#55-locations-and-configuration)).
- **Binaries:** only `tomspecs` and `tom_bs` remain; `validate_codespecs`,
  `spec_checks` and `irspecs` are retired.
- **Submodules:** `ww_f_collab-5` still describes pointer handling; the fleet
  moves to independent clones (its rewrite is vscode_extension
  `06a_wslayout-5`).
- **Host tools:** the feature overview says a host provides no tools; Webwork
  and Tom Forge need host tools from a Flutter host (`12b_woneb3`, tom_forge
  `qavs_wwworkbench-4`, `-5`). [§ 6.3](#63-tools) resolves it.
- **The server:** `ww_g_collab-2` (customers, quotas) and `tac_webwork-2` (a
  minimal team server) overlap; the full server is built first (CQ-9).

## 3. What the other quests bring

### 3.1 vscode_extension — the engine as it is now

Features of the last two weeks the runtime inherits and the earlier documents
do not name:

- **Runs:** the `default` run runs no process; every process runs in a run of
  its own with its own position, chat variables, queue lane, queue settings and
  sessions `<session>@<run>`; `process-subject` and declared `runParameters`;
  Reset Run and Reset Process.
- **Process shapes:** nested processes with inputs and outputs, branches,
  conditional phases and steps (`when:`), decision steps, non-linear moves,
  follow-up processes, gate results with decision buttons, a review step's
  `documents:`; `tomAi_writeProcess` and `tomAi_validateProcess`.
- **Queue:** TODO and GROUP items, chat sends as queue items with one busy
  slot per session, background-work wait, walk continuation, `tomAi_waitFor`,
  soft interrupt, one open ask per run, asks that survive a reload.
- **Todos:** groups (`status: group`, `comprised_of`), `due` with reminders,
  cross-quest `blocked_by` (`<quest>/<id>`), renames; planned: a todo names
  its profile (`vscimpb174`).
- **Roles:** role types and `role-config.yaml` decide a prompt's tools.
- **Quests:** AI workspaces (`_ai/workspaces/<workspace>.yaml`),
  `short_description.<quest>.md`.
- **Formats:** the `_ai` format migration with a machine-local stamp, a
  per-machine lock and an emergency mode.
- **Machine-wide views:** RUNS and NOTIFICATIONS across every window; the
  cross-quest todo panel.
- **Planned and relevant:** user notifications and non-blocking
  `tomAi_answerUser` (`vscimpb170` … `172`), a message into a waiting turn
  (`vscimpb173`), a cleanup-task registry "that moves with the runtime"
  (`aaa_cleanup1`, `-2`), the MD Browser page behind a host object with a
  versioned page protocol and a conformance suite (`01b_woneb1`, `-2`,
  `04c_woneb1`, `-2`).

Weak points recorded there are in [§ 10.1](#101-what-hurts-today).

### 3.2 webwork — messaging, the review exchange, the AI tab

- **Requirements WR-1 … WR-7** ([webwork_requirements.md](webwork_requirements.md)).
- **Beyond them** (webwork_redesign, parts messaging, review, bottom panel):
  - conversations: direct, group, attached to a document or review round;
    replies and threads, mentions, per-conversation mute, unread counts;
  - a stable message anchor `msg:tac/<server-group>/<messageId>`;
  - three ways to send a document: a reference, a Webwork copy
    (`.webwork.zip`, base version recorded), a rendered form (Markdown, HTML,
    PDF);
  - the review exchange: the base goes out in a thread attached to the round,
    the reviewer returns a copy in the same thread, the coordinator's client
    writes it into the round folder (`round.yaml`, base, member copies,
    `merged/`), and tells the server when the round is merged. The round
    folder is the record, tac is the transport;
  - a review is over a **set** of documents;
  - edge cases a client must detect: an expired blob, a copy over the limit, a
    return from an unknown sender, a copy returned twice;
  - offline: a device-local outbox with request ids, a cache, read-only
    history;
  - the AI tab: one run per Webwork area, three send choices (queue at the
    end, queue next, update to the running prompt), a per-run option *Review
    each prompt* (the result waits for Apply or Discard) or *Work silently*,
    "new conversation" per run, run-state events, prompts addressable in the
    trail, a trail kept in memory only for encrypted documents;
  - host tools registered per run or per prompt, called back over the
    protocol, with prompt boundaries signalled (for undo groups);
  - later: a server-side runtime for web and phone (wave 3).
- **Reminders** are local in Webwork today; a reminder between users is this
  quest's new aspect ([§ 7.4](#74-message-kinds)).

### 3.3 tom_forge — the quest application and the review component

- **Hosting:** one Node process per open quest, started
  `serve --workspace <root> --quest <id>`, a ready line, stop by closing
  stdin; a crash is reported and restarted on request; no runtime outlives
  Forge (confirmed, CQ-4).
- **The Dart client:** typed commands and an event stream, reverse requests,
  a protocol and `_ai` format version check on connect, bindings generated
  from the schema, no Flutter dependency.
- **The views it expects:** PROCESS, the todo panels, notes, sessions, the
  todo log, window status, the trail viewers, @CHAT, asks and approvals, the
  editors (queue, templates, timed requests, chat variables, memory, process),
  usage and budget.
- **Two component sets are planned for the same thing:** `tom_forge_agentic`
  (tom_forge `qavs_ccparity_d_claudecode-1`) and `tom_ai_runtime_ui`
  (`12b_woneb2`) (CQ-14).
- **One MD review component in Flutter** (`tom_md_browser_editor`, in the
  tom_forge repository, over `tom_som_dart_runtime`), shared by Webwork, the
  quest application and trc; the alternative is the extension's page in a
  webview, decided by a probe.
- **An expression system** common to JavaScript and Dart is to replace
  `${{js}}` (tom_forge `qavs_wwworkbench-1`); it touches the placeholder
  engine.

### 3.4 al_the_bear and build_tom — layout, fleet, installation

- **The layout the runtime resolves** ([§ 5.5](#55-locations-and-configuration)).
- **Independent clones:** after the cutover every repository follows `main`,
  reconciles run per repository without a pointer phase, and
  `repos.yaml` at the fleet root is the one repository record;
  `agent.workspace.yaml` is to refer to it.
- **The fleet lock** `refs/fleet-locks/reconcile` goes away with the new
  skills; "one driver at a time" stays as a rule only.
- **Coordination infrastructure:** the repository `tom_coordination` and its
  tokens, the reconcile-rule exception for auto-update, the server on
  bigbeast (`collab_c-1`, `-2`, `collab_d-2`).
- **Installed services** have a precedent (build_tom `build_cleanup1004`):
  built into the binaries layer, then copied to the OS application location
  (macOS `~/Library/Application Support/Tom/bin`), because a running service
  needs a stable copy outside a git tree. `~/.tom/bin` is removed on every
  host.

### 3.5 tom_specs, tom_uam — the process the runtime runs, and its own

- **The `tom_specs` process** uses every engine feature of § 3.1 and adds the
  change mode (Phase 0 and 8C), three waves in Phase 3 and the subprocess
  `team_document_review`, in which **the user is still the courier** of the
  review copies. tac's document exchange replaces the courier (tom_specs S9).
- **New tools the tool surface gets:** four section-automation tools
  (`tomAi_specSyncReport`, `Backfill`, `Prefill`, `DeriveFields`), the render
  switches of the reading view, the rename of SOM documents to
  `*.tomspecs.*`, one `tomspecs` binary.
- **Phase 4 for TypeScript:** the IR and the mappers `ts-shared`,
  `ts-react-client`, `ts-hono-server` exist, for business applications. There
  is no mapper for a library, a runtime or a command line. This quest takes
  the model's document structure, not the process (CQ-17).
- **Lessons from running it (tom_uam):** a step started although no question
  was answered; a running quest changed a shared process mid-run; a gate
  needed two runs; "Finish review round" was refused at a sub-step; edit tools
  failed on large documents. The runtime specification covers run versioning
  against a process definition and the preconditions of a step
  ([§ 5.2](#52-processes-and-runs)).

### 3.6 tom_secrets_manager, tom_core, d4rt

- **Tom Secrets Manager:** a local protocol (`client.sock`; `hello`, `get`,
  `getMany`), clients only read. A client is identified by its measured
  executable; an interpreted client (`node script.js`) is approved by
  interpreter and script, or holds a client token. The reference grammar is
  `[env:prod]store/path#field`, **not** `tsm:<vault>/<entry>` (CQ-16). On a
  locked vault the answer is `needs_unlock`.
- **tom_core_agentic** holds the MCP bearer constants (`tomBearerToken`) and
  the Dart Agent SDK provider; it depends on `tom_vscode_scripting_api`
  5.0.0.
- **d4rt:** `dcli` runs on `tom_vscode_scripting_api` 5.0.0; the bridges are
  regenerated with each `tom_todo_model` release.

## 4. The system

```text
                    ┌───────────── trc: supervision ─────────────┐
                    │ every runtime of a group in one view        │
                    └──────▲───────────────────────────▲──────────┘
     people                │ runtime protocol          │ TAC
  ┌───────────┐            │                           │
  │ Webwork,  │   TAC      │                           │
  │ phone,    ├────────────┼───────────────────────────┤
  │ browser   │ (no runtime needed)                    │
  └───────────┘            │                           │
┌── host ──────┐  ┌────────┴──── tar ───────────┐  ┌───┴────── tac ─────────────┐
│ VS Code ext. │◄►│ quests · todos · processes  │◄►│ presence · discovery       │
│ Webforge     │  │ runs · queue · sessions     │  │ leases · integration queue │
│ Webwork      │  │ transports · tools · MCP    │  │ messages: runtimes, people │
│ (own tools)  │  │ dispatch · integration      │  │ documents · reminders      │
└──────────────┘  └───────┬──────────▲──────────┘  │ local │ GitHub │ server    │
                          │          │ MCP between └────────────────────────────┘
                          ▼          │ runtimes
                 cloud agents and remote runtimes
                 (a todo goes out, a branch comes back)
```

Three components and what joins them:

- **tar, the Tom AI Runtime** (`tom_ai/ai_build/tom_ai_runtime`, TypeScript):
  the engine. A host attaches and adds as thin a UI as it needs.
- **tac, Tom Agent Coordination** (`tom_tac_service`): how runtimes find each
  other and keep out of each other's way, and **the messaging server between
  the people** who use applications linked with a runtime: documents for
  review, messages, reminders, decisions.
- **trc, Tom Runtime Control:** supervision of a group, a Webforge application
  that also runs standalone.
- **The client packages** (nine languages) and **the Flutter components**
  (`tom_ai_runtime_ui`), so that putting the runtime into a Flutter
  application takes a few lines.

## 5. The runtime (tar)

### 5.1 What it holds

One implementation of the `_ai` formats and the engines, used by every host:
quests, todos (groups, due dates, follow-ups), memory, sessions, trails, chat
variables, roles and role types, templates, profiles, the format-version stamp
and its migration, the cleanup registry.

### 5.2 Processes and runs

- **A run** is the unit of work: a process position, chat variables, a queue
  lane with its settings, sessions `<session>@<run>`, a subject. `default`
  runs no process.
- **Process shapes** as in § 3.1.
- **Proposal — a run pins its process version.** A run records the revision
  of the process definition it started on; a changed definition is taken at a
  step boundary the user confirms, never mid-step (the tom_uam lesson).
- **Proposal — step preconditions.** A step declares what must hold before it
  starts (answered questions, a passed gate, documents present); the runtime
  checks it and refuses with the reason instead of starting.
- **Proposal — a fast path.** A small change gets a short process (intent,
  change, check), so the full phases are not the only shape
  ([§ 15.3](#153-spec-driven-work)).

### 5.3 The queue

Items (prompt, TODO, GROUP), pre-prompts and follow-ups, walks, repeats,
timed requests, reminders, soft interrupt, the three send choices (end, next,
update to the running prompt), the per-run *review each result* option, done
notifications, `on_done`. A queue item names its **transport**; with
[§ 11](#11-later) a transport may be a cloud agent or a remote
runtime.

### 5.4 Transports

`ModelTransport` with `kind: model | agent`; no host transports (FO-2).

- **Model transports** (direct API, Local LLM, providers, `pi-ai`): the
  runtime runs the tool loop.
- **Agent transports** (Claude Agent SDK, Copilot SDK, Codex, Gemini CLI,
  `pi-coding-agent`): their own loop, the tools through MCP.
- **One adapter for agents that speak the Agent Client Protocol** (CQ-5):
  ACP is JSON-RPC between a client and a coding agent; Claude, Codex,
  OpenCode, Copilot and Gemini are reachable through it. The runtime as an
  ACP client gets them through one adapter and keeps the native SDKs where
  ACP loses features. It comes after the native transports.

### 5.5 Locations and configuration

`TomLayout`, as built in the extension, is what the runtime resolves; outside
VS Code the host passes the workspace folder and the quest.

- **Root:** the nearest folder at or above the workspace folder with
  `.tom/tom_root.yaml`; none: the folder is standalone and its own root.
- **`aiRoot`:** `<workspaceFolder>/_ai` as opened (a symlink onto the one
  clone), else the root's; comparisons use the real path.
- **Configuration layers:** defaults < user-global < root `.tom` < workspace
  `.tom` < quest layer (`extension_config[.<host>].<quest>.yaml`) < host
  settings. Objects merge deep, arrays replace. A write changes one key in one
  file, checks the stamp and writes atomically.
- **Guidelines:** the root's `_agent_guidelines/`, then the workspace
  folder's; the same relative path in the workspace wins.
- **Quests of a workspace:** `_ai/workspaces/<workspace>.yaml`, else the
  recorded workspace folders, else all.
- **Repositories** (CQ-3): the workspace's repositories are those of the
  file the workspace is set up from (`repos.yaml`, defined by the workspace
  restructuring in al_the_bear).
- **A quest's default resources** (CQ-3): a quest lists the repositories and
  subtrees it usually works on (`quest-resources.<quest>.yaml`). A todo is
  written with its own `resources:`; one that names none claims the quest's
  whole list while it runs (DQ-5). The quest default is the fallback, mainly
  for older todos.
- **Two kinds of configuration** (DQ-8): what is **administered centrally**
  and is the same for everyone in a team (the providers and their
  configurations, and with them which providers may be used at all), and
  what is **configured per runtime**. Today's extension configuration is one
  file holding both; it is split (DQ-11):
  - **in the repository**, under version control as today: what belongs to
    working on code — role types, process definitions, prompt templates;
  - **in tac**, as a team's configuration: what belongs to the team as an
    organisation — the providers, which of them may be used, the standard
    profiles. tac stores it in whichever backend the team uses (local: on
    the machine; GitHub: in the coordination repository; server: on the
    server). Only the team's owners change it. A runtime fetches it when it
    connects, keeps a copy for offline starts, and is told of changes. In the
    layering it stands above the user's own file for the keys the team owns
    and below it for the keys the team only suggests;
  - **per runtime**: queue settings, timeouts, compaction, retries; paths,
    executables and preferences per machine or host.

### 5.6 Machine-wide state

Several runtimes on a machine share state: queue settings, the user
configuration, window status, the inbox, notifications. The incidents
([§ 10.1](#101-what-hurts-today)) all come from one process writing a shared
file whole.

**The runtime owns machine-wide state** (CQ-2). A host or a tool never reads
or writes these files; it asks its runtime. Inside the runtime there is one
interface for it with two implementations:

- **through tac:** the local tac service, which runs once per machine and
  user, holds the state; every runtime's access is routed through it, so
  concurrent access is handled in one place;
- **files** for `mode: off`: one key at a time, under a lock.

A runtime ends with its host (CQ-4); the local tac service is what outlives a
single runtime and carries the state between them.

### 5.7 Installation and lifetime

- **One installation per machine** in the per-user application data folder,
  the provider SDKs beside it, versions side by side with a `current` pointer
  (FO-3, FO-4).
- **A runtime is started by its host and ends with it** (CQ-4). A long walk
  needs its host open. Standalone runtimes, to which a client attaches to
  supervise and detaches again, are a later investigation; the protocol does
  not prevent them.
- **Every host installs the runtime it was built with** into the shared
  location when that version is not there yet, and starts that version
  (DQ-9). Hosts on one machine thereby share installations.
- **Versions and the workspace files:** [§ 6.7](#67-versions-and-compatibility).

### 5.8 Secrets

A configuration names a secret, never holds one (FO-15, CQ-16):

- `secret: tsm:<TSM reference>` — Tom Secrets Manager's own grammar after
  the prefix, e.g. `tsm:[env:prod]providers/anthropic#apiKey`;
- `secret: os:<service>/<account>` — the OS secret store;
- `env:<variable>`, `file:<path>` — allowed, marked not secure.

The runtime and the tac service are each paired with the Tom Secrets Manager
service once (approved as their own Node process); a setup guide describes
it. On a locked vault (`needs_unlock`) the queue item waits and the user is
asked. Besides provider keys, the team tokens of a user
([§ 7.3](#73-participants-teams-and-identity)) are kept this way.

## 6. The protocol and the hosts

### 6.1 The runtime protocol

Decided (FO-5): length-prefixed JSON-RPC 2.0 over loopback TCP for local
hosts, WebSocket for remote clients; commands, one event stream with
subscriptions, reverse requests; the protocol as a JSON schema in the package.

Proposals from what others built ([§ 15.1](#151-protocols)):

- **A numbered event log per run** (CQ-6). An event is one thing the runtime
  tells its clients: a piece of streamed answer text or reasoning, a tool
  call and its result, a queue item changing state, the process position
  moving, an ask opened or answered, a todo changing status, usage of a
  round, a trail entry. Every event has a sequence number; a client reads
  "after N, then follow". That gives reconnect, a second client on the same
  run, and a supervision client attaching late, with one mechanism. The log
  is kept in memory with a bound; a client further behind reloads the run
  from the trail files, which stay the durable record.
- **Thread, turn, item.** The chat model follows the lifecycle others
  converged on: a session holds turns, a turn holds items (text, reasoning,
  tool call, ask, result) with started, delta and completed events; a turn
  can be steered and interrupted.
- **One ask envelope** for every question the runtime puts to a person: a
  stable id, a kind (question, pick, document, tool approval, plan, decision,
  gate), the allowed responses, an optional response schema, a declared
  default, a deadline. It maps onto what agents and protocols use (ACP
  permission requests, MCP elicitation, an agent's ask-user tool, A2A's
  `input-required`).
- **Asks outlive the process.** A pending ask is a record; the turn can end
  and resume when the answer arrives. The extension's open-ask record is the
  start of it. This is also what lets an ask travel to another device or
  person through tac ([§ 6.6](#66-routing-and-escalation-of-asks)).
- **Subscriptions per connection**, and a run unloads when its last
  subscriber has gone and nothing is queued.

### 6.2 The host interface

`QuestRuntimeHost`: locations, identity (host kind, user, review member id),
configuration, the asks, `notify`, `openFile`, `openDocument`, **host tools**.
In VS Code it is implemented in-process; elsewhere over reverse requests. A
host refuses what it has no concept for.

### 6.3 Tools

Three sets, by where they can live:

| Set | Lives in | Examples | Exposed |
| --- | --- | --- | --- |
| Runtime tools, `_ai` | the runtime | todos, queue, process, sessions, memory, chat variables, review, coordination, messaging, the `tomspecs` runner | runtime MCP server, also to other machines |
| Runtime tools, files | the runtime | read, edit, find, run command, web, git | to the model transports only; never over the runtime MCP server (FO-17) |
| Host tools | the host | VS Code: editor, LSP, commands, MD Browser, notebooks. Webwork: its document tools. Tom Forge: its equivalents | registered by the host per run or per prompt; called back over the protocol |

- **Same names as today** for the `tomAi_*` tools.
- **Host tools** are how the feature overview's "VS Code tools stay in the
  extension" and Webwork's "document tools executed in Webwork" are the same
  thing: a host registers tools (name, schema, description) with its runtime;
  the runtime offers them to the transports and calls the host back; prompt
  boundaries are signalled to the host. Inside VS Code the extension may
  register them as an MCP server instead of single tools (FO-6).
- **The role** decides which tools a prompt gets (role types).

### 6.4 The MCP servers

- **The runtime MCP server:** the `_ai` tools; bearer authentication
  (`tomBearerToken`); safe to publish as a tac endpoint.
- **MCP is pinned per revision.** The 2025-11 and 2026-07 revisions differ
  (tasks, sessions, sampling); the runtime names the revision it speaks and
  keeps tasks behind an adapter.
- **The runtime as MCP client** of external servers stays as built.

### 6.5 Attaching editors

The runtime also answers as an ACP **agent** on stdio, so an editor that
speaks ACP (Zed, JetBrains) can open a session of a quest (CQ-5). It covers
chat, updates and permission requests only; queue, todos and processes stay
in the runtime protocol. It comes late in the order.

### 6.6 Routing and escalation of asks

An ask must not get lost and must not block a process for long (CQ-7, DQ-3).

- **Every quest has an owner.**
- **The chain of an ask:** the person the process or todo names (if any) →
  the owner of the quest the ask belongs to → the owner of the quest whose
  todo triggered it (a todo filed from another quest carries `filed_by`) →
  the team's owners.
- **For each person in the chain:** the ask is shown on the asking host;
  after 10 minutes without an active client there it goes through tac to
  that person's other devices; after a set time unanswered (4 working hours
  by default, configurable per team and per ask) it moves on to the next in
  the chain, and the previous person keeps seeing it.
- **At the end of the chain** the ask stays open, marked unanswered in the
  team's ask inbox. Nothing is decided automatically unless the ask declared
  a default; then the default is taken and recorded as such.
- **Meanwhile:** the run that asked waits; other runs and the rest of the
  queue go on. A walk goes on with the next todo that does not depend on the
  waiting one.
- **Forwarding:** whoever has the ask can forward it to any team member,
  with a note; the chain continues from there, and the answer returns to the
  run.
- **Monitoring:** every open ask of a team is visible with its age, who has
  it and where it is in its chain (the ask inbox, the supervision app).

### 6.7 Versions and compatibility

A runtime update often comes with an update of the workspace and quest
files, and an older runtime does not run on newer files. The extension
already has this: a format-version stamp, a migration under a per-machine
lock, and a rule that keeps older instances from working on a newer
workspace. With hosts as separate programs and clients in nine languages it
becomes part of the protocol and of every client library (DQ-9):

- **Three versions are checked on connect:** the protocol, the runtime, the
  format of the workspace files.
- **An old client keeps working with a newer runtime.** It does not get the
  new features, but nothing it does breaks. The protocol only grows:
  commands and fields are added, not changed or removed, within a major
  version.
- **Unknown fields pass through.** A client that reads a record, changes a
  field and writes it back returns every field it did not know unchanged, so
  nothing a newer runtime added gets lost. Every client library implements
  this, and the conformance suite tests it.
- **Callbacks for upgrades.** A client library tells its host through
  callbacks when the runtime was updated, when the workspace files were
  migrated to a format the host's runtime cannot work on (the runtime then
  stops working on them), and when the host itself is too old for the
  runtime it found. The host decides what to show and do.
- **The aim** is that after a while the protocol and the formats are very
  stable.

## 7. Coordination and messaging (tac)

### 7.1 Two jobs, one service

| Job | For | Built |
| --- | --- | --- |
| **Coordination** | runtimes: presence, discovery, sessions, leases, units, messages between runtimes, endpoints | local mode |
| **Messaging** | people, and runtimes acting for them: conversations, documents, reminders, asks | nothing |

They share the group, the identities, the transport, the store and the
server. A team is one agent group.

### 7.2 Backends and modes

tac is designed as **a reusable component of its own** (CQ-15): the service
and its clients are usable without the runtime.

- **local:** one machine and user; started by the first client.
- **GitHub:** one user's machines; leases and endpoints as refs in the
  coordination repository; no messages across machines (IDEA-21).
- **server:** a team or several; independent of git. **The full server is
  built first** (CQ-9): customers, access keys, quotas, the admin API, TLS,
  CORS for browser clients. A small team's server is the same server with one
  customer.
- **relay:** part of the server; carries TAC and MCP for machines off the
  VPN; forwards only (FO-9).
- `mode: off`: everything works as today.

### 7.3 Participants, teams and identity

`tac/1.0` knows runtimes. Messaging and supervision need people, their
devices and teams.

**Two words, two things** (DQ-1):

| Term | Is | Has |
| --- | --- | --- |
| **team** | a group of **people** | members, owners, invitations, conversations, review sets, the right to control each other's runtimes |
| **agent group** | a group of **runtimes** that coordinate | presence, leases on repositories, messages between runtimes, endpoints |

A person is a member of one or several teams. A person runs several
runtimes, and those runtimes may be in several agent groups. One runtime
instance always belongs to exactly one person. Webwork's documents use
"group" where they mean a team (DPAREAS-7: "a Webwork team is one tac
group"); the specification uses the two words as in this table, and Webwork
is told.

- **A participant** is a person (`userId`, email, display name) or a
  runtime. A person has devices (clients), each with its own stream and read
  position. A runtime names the person it belongs to, so a message from an
  agent is attributed to the runtime and to its user.
- **Every client reaches tac through a runtime** (WQ-1). On the desktop that
  is the host's local runtime. A browser or phone client (Webwork on the web,
  on a phone or a tablet) connects to a runtime on the server side that also
  hosts the web version, and that runtime connects to tac for it. tac's
  participants are therefore people and runtimes, never a bare device.
- **Joining a team** (CQ-10, DQ-2):
  1. A team has owners; the first is whoever created the team with the
     server's admin API. An owner creates an invitation for an email
     address.
  2. Creating it returns a one-time password (as text and as a link or QR
     code). The owner passes it on by a channel they trust. It is valid once
     and for 7 days. The server does not send email itself.
  3. The invited person's client presents the password with the email it was
     issued for. The server creates the participant with a user id it
     generates itself, so no client can choose an id, and returns the **team
     token**.
  4. The team token is per person and team. Each device registers itself
     under it, so a single device can be removed. It is kept in Tom Secrets
     Manager or the OS secret store, never in a file.
  5. An owner removes a member, and the server then refuses that member's
     token; a member can leave; tokens can be rotated.
- **A client sends a team token with every request.** A member of several
  teams holds several.
- **A quest has a home team** (DQ-12). A quest records the team it belongs
  to and its owner. Its runtime acts as a member of that team by default:
  asks are routed in it, remote control is allowed from it. When an action
  addresses another team (a review request to that team's members, a message
  into one of its conversations), the runtime uses the user's token for that
  team for exactly that action. A person's devices show all their teams side
  by side.
- **Remote control is possible only inside a team**, and only where the
  runtime's host setting allows it. As long as runtimes start and stop with
  their host applications, that is the protection.
- **Two levels of identity, both built** (CQ-10): identification by user id
  and email (WR-2), so work can start without setup; and invitation with
  team tokens. The first is used while the second is tested and fixed.

### 7.4 Message kinds

Beyond what a messaging application does, a message can be something the
recipient's application acts on. The service stores and delivers; the kinds
are the clients' convention, versioned with the protocol.

| Kind | Carries | What the recipient's application does |
| --- | --- | --- |
| text | Markdown, mentions, a reply reference | shows it |
| document | one or more blobs or references, the form (reference, copy, rendered) | opens, saves into a place, makes a todo |
| review request | a round id, the set of documents, the deadline, the base versions | opens the review editor; "Return copy" answers in the same thread |
| review return | the round id, the returned copies | the coordinator's client writes them into the round folder and offers the merge |
| ask | the ask envelope of § 6.1: a question, options, a default, a deadline | shows buttons or a form; the answer goes back to the run that asked |
| decision request | a todo's open decisions, or a gate result with its choices | the recipient decides; the todo or the process moves |
| todo | a todo to take over, or a todo's state change | files it, or shows the change |
| reminder | a time, a subject (a message, a document, a round, a todo), who is reminded | delivered at the time; repeats and escalates as declared |
| notification | from a runtime: needs attention, finished, failed, out of budget | the notifications view; presence-aware delivery |
| command | to a quest's runtime: queue, pause, proceed | as today's commands between runtimes |

**Reminders are a service feature, not only a kind:** a message may carry
`deliverAt` (it is held until then) and `remindAfter` (the service reminds the
recipient when it is unanswered or unread after that time, and the sender when
it stays so). A review round's deadline uses it. Once-across-devices delivery
is the service's job (today solved per todo with `due_reminded`).

**Presence-aware delivery:** a notification is not pushed to a phone while its
user is active on another attached client; after a time without a reaction it
goes to the next channel.

### 7.5 Conversations

Direct, group, and attached to an anchor: a document, a review round, a todo,
a run, a quest. History in pages and since a point; read state per person;
mute; mentions; retention per group (1 year by default, a team may set any
value or keep messages; WQ-3); a `requestId` makes a send safe to
repeat; a stable message anchor `msg:tac/<group>/<messageId>`.

### 7.6 Documents

Content-addressed blobs (SHA-256), uploaded once, a size limit and a group
quota a client can ask for before it sends, a lifetime (default 7 days, at
most 30, set per message; FO-21); expiry removes them. tac is not a file
server.

**A process may pin its blobs** for as long as it runs (CQ-11). Pinned blobs
count against the group's quota and are released when the process ends.
That makes a **review set** a thing of its own: a named set of files, pinned
for a review, that every reviewer of it can open — also a reviewer outside
the VPN or without access to the version control system or file servers, as
long as their client reaches tac (for example through the server side of a
web review client).

**Where the documents themselves live** (DQ-4). Blobs carry copies for
reading and for returning review copies; the versioned documents and the
record of a review are in version control:

- usually the specification folder of the project, in the project's
  repository;
- in a larger organisation a specification repository of its own (or another
  versioned file storage; what exists today is plain file storage where the
  tac server runs, git repositories, and git repositories on the tac
  server's machine);
- usually **not** the quest: over time a quest spans many projects and
  products.

The coordinator's client writes the returned copies into the round folder
beside the documents and commits there.

### 7.7 The review exchange

The process `team_document_review` keeps its shape; its `collect` step stops
being the user's errand. The round folder stays the record
(`round.yaml`, base, member copies, `merged/`); the merge stays in the SOM
runtime. tac carries the base out and the copies back (flow F6). A reviewer
without access to any repository needs only an application with the review
component and a tac identity.

### 7.8 Encryption

In transit: TLS to the server (WR-3). At rest: not encrypted by default; an
option, its key in Tom Secrets Manager (FO-20). Pairing of devices and
end-to-end encryption between a device and a runtime become mandatory as
soon as anything is reachable from outside the VPN, that is, with the relay
(CQ-10).

### 7.9 One specification: `tac/2.0`

tac's new capabilities are specified together as `tac/2.0` (CQ-8), not as a
series of minor versions: participants, teams and identity; the server;
conversations, message kinds and reminders; documents, pinning and review
sets; integration leases and the integration queue
([§ 10.4](#104-keep-the-trunk-add-an-integration-step)); authentication. One
document to review as a whole, **built in one go** to the full `tac/2.0`
(WQ-2).

**Capabilities are announced.** A service names in `hello` the capability
blocks it implements (`participants`, `teams`, `messaging`, `documents`,
`integration`, …), and a client uses what is announced. New capabilities are
added over time within `tac/2.0`, and runtimes of older versions still
running somewhere keep working with a newer service.

### 7.10 Webwork's requirements and the `tac_webwork` todos

Webwork's requirements ([webwork_requirements.md](webwork_requirements.md),
WR-1 … WR-7) and the todos made from them (`webworkreq1`, `tac_webwork-1` …
`-6`, `12b_woneb1` … `-3`) were written before this concept, as proposals "to
be replanned from the specification". Their decisions have since been
answered in the todos themselves. This section takes them in.

**Where each requirement lands:**

| Requirement | In this concept | Todo | State |
| --- | --- | --- | --- |
| WR-1 tac reachable as a server by a small team | § 7.2: the full server first (CQ-9); a small team is the server with one customer | `tac_webwork-2`: (b) the full server first; TLS at a reverse proxy | covered |
| WR-2 identification by user id and email | § 7.3: identification and invitation with team tokens, both built (CQ-10, DQ-2); every client through a runtime (WQ-1) | `tac_webwork-1` | covered, differently: a client without a runtime does not register in tac |
| WR-3 encryption on the wire only | § 7.8: TLS in transit, at rest optional (FO-20) | `tac_webwork-2`: TLS at a reverse proxy | covered |
| WR-4 user messages | § 7.4, § 7.5; retention 1 year by default (WQ-3) | `tac_webwork-3` | covered |
| WR-5 documents as blobs | § 7.6: blobs, lifetimes, pinning, review sets (CQ-11) | `tac_webwork-4` | covered |
| WR-6 a Dart client without an AI runtime | § 12.1: `tom_tac_client`, its own package (CQ-15); applications reach tac through a runtime, on the web and the phone a server-side one (WQ-1, T8) | `tac_webwork-5`: (c) left to the specification | taken differently: no direct tac connection from a browser or phone |
| WR-7 the runtime's runs, queues, trail for Webwork's bottom panel | § 3.2, § 5.3, § 6.3, § 12.2 | `12b_woneb1` … `-3` | covered |

**Details from the todos the concept did not have**, now part of it:

- **Additive, compatible changes:** an older client that sends no user still
  works; a message's `origin` carries the sender's `userId`; a group lists its
  people, known and present, with ids and emails.
- **TLS ends at a reverse proxy** (Caddy or nginx in front of the server); the
  service stays without dependencies and certificates are handled by a
  standard tool (`tac_webwork-2`, decided).
- **CORS** for browser clients; in the browser the access key travels as the
  WebSocket subprotocol (`tac.key.<key>`, `tac/1.0` § 11 point 18).
- **The server for a team runs long** (no idle stop) with the same store and
  configuration as the local mode; a setup note describes running it on
  bigbeast, together with al_the_bear's `collab_d-2`.
- **Messages:** `createdAt` from the service's clock; history in pages and
  since a message id or a time; read state as "read up to a message" plus
  unread counts per conversation; an optional free payload beside the
  Markdown text (for blob references and Webwork's cards); the `requestId`
  of a send is remembered for 24 hours, so an offline outbox can resend.
- **Blobs:** the hash is checked on upload; a blob is stored once however
  often it is referenced; a reference carries hash, name, media type and
  size; a client reads the size limit and the quota before it uploads; only
  members of the conversation (or reviewers of the review set) may download;
  operations to extend a review round's blobs to the maximum and to release
  them; the local service keeps blobs in its store folder.
- **The Dart tac client** runs on `dart:io` and in the browser (conditional
  imports), reconnects and catches up, and is tested against a running
  service with testkit.
- **The end-to-end check** (`tac_webwork-6`): a server with TLS, two
  machines and a browser exchange messages and a `.webwork.zip`-sized blob in
  a thread attached to a review round; the result is recorded and the webwork
  quest is told that its wave 1b2 messaging can start.
- **Webwork's AI tab** (`12b_woneb1` … `-3`): the three send choices, the
  per-run *Review each prompt* / *Work silently* option, the quest-less
  `webwork-app` with one run per area, *New conversation* per run, host tools
  per run or prompt with prompt boundaries signalled — in § 3.2, § 5.3 and
  § 6.3.

**How a client without a runtime takes part** (WQ-1): through a runtime on
the server side, which also hosts the web version; tac sees the runtime and
the person it acts for. Webwork's messaging on the web, the phone and the
tablet therefore comes with the server-side runtime (T8), in a later wave;
on the desktop it comes with the local runtime.

**Webwork was told** (WQ-4): all of tar and tac are built in one go; webwork
is told which todos cover its requirements once they are filed, and again
when the runtime is built; until then it works on what does not need the
runtime.

## 8. Network topologies

The topologies the architecture document describes, each with what runs where
and what must be reachable.

**T1 — one machine, VS Code only.** Runtimes in-process, one per window; the
local tac service on loopback; nothing leaves the machine. Today's setup with
coordination between windows.

```text
[VS Code window + runtime] ─┐
[VS Code window + runtime] ─┼─ loopback ─ [tac local]
[VS Code window + runtime] ─┘
```

**T2 — one machine, several hosts.** VS Code windows, Webforge with one
runtime process per open quest and `webwork-app`; possibly two hosts on one
quest. All use the shared installation and the local tac.

**T3 — one user, several machines on the VPN.** Each machine as T1 or T2. The
machines share a group through the GitHub backend or the server on bigbeast;
runtimes publish their MCP endpoints and reach each other directly over the
VPN.

```text
mbp [runtimes]─[tac local] ──┐                 ┌── bomber [runtimes]─[tac local]
                             ├── VPN ── [tac server, bigbeast] ──┤
legiondary01 [runtimes] ─────┘                 └── bigbeast [runtime servers]
```

**T4 — a team on the VPN.** As T3 with several people; the team server
carries messaging; Webwork on the desktop connects through its local
runtime, on the web and the phone through a server-side runtime (T8).

**T5 — a member off the VPN.** A machine or a phone outside reaches the
server's public address over TLS; the relay forwards TAC and MCP to runtimes
inside. Runtimes inside keep an outbound connection to the relay; nothing
inside accepts inbound connections from outside.

```text
phone / laptop ── TLS ── [tac server + relay] ── outbound ── runtimes on the VPN
```

**T6 — a runtime server.** A machine that is always on (bigbeast) runs
runtime servers without a window: quests worked from the queue, supervised
through trc. This is also the target of "a todo to our own cloud"
([§ 11](#11-later)).

**T7 — a cloud agent (later).** A vendor's sandbox clones a repository from GitHub,
works, pushes a branch. It reaches neither tac nor a runtime; the dispatching
runtime polls the vendor and GitHub.

```text
runtime ── dispatch ──► vendor API ──► sandbox ── push branch ──► GitHub
   ▲                                                                 │
   └───────────── fetch branch, integrate (§ 10) ◄──────────────────┘
```

**T8 — server-side runtime for web, phone and tablet:** a browser or phone
client with no local runtime uses a runtime on a server over WebSocket; the
same server side hosts the web version. It is the only way such a client
reaches tac (WQ-1). It comes in a later wave of the plan.

## 9. Key flows

The flows the architecture document draws as sequences. Here: who takes
part, the steps, what is new.

**F1 — a host attaches.** The host finds the installed runtime (`current`),
starts or reaches it, `hello` with protocol and format versions, registers
its host tools, subscribes to events from sequence N. In VS Code the same
calls are direct.

**F2 — a prompt.** The host queues an item (end, next, or update); the queue
dispatches when the session's slot is free; the transport streams items; tool
calls go to runtime tools or back to the host; the result is recorded in the
trail; with *review each result* the queue waits for Apply or Discard.

**F3 — a todo walk.** A walk takes the next ready todo (not blocked, its
dependencies done), takes its claims through tac, all or none; a held claim
makes the item wait and names the holder; the todo runs; completion carries
out `on_done` and delivers the done notification; the claims are released
unless held for the group.

**F4 — a process step with a gate.** Proceed queues the step's prompt and a
process-move marker; the step's walks run; the gate writes its report and
asks with the decision buttons; the decision moves the process.

**F5 — an ask reaches a person elsewhere.** A run asks; no client of the
user is attached to the host, or the user is away; the runtime sends the ask
through tac to the user's participant; the phone (trc or Webwork) shows it;
the answer returns through tac to the run. New: asks as records, routed by
presence.

**F6 — a team review.** The coordinator's process reaches the review step;
the runtime creates the round folder and sends a *review request* with the
document set to each member through tac; each member's application opens the
review component, the member annotates and presses *Return copy*; the
coordinator's client writes each copy into the round folder; reminders go out
before the deadline; when all are back (or the coordinator decides), the
merge runs and the consolidation view opens; the round is marked merged and
the blobs go. New: no courier.

**F7 — a todo to another quest.** A todo's `on_done` or a tool queues an item
or a walk in a named run of another quest; on the same machine through the
machine service, on another machine as a tac command; the done notification
returns to the run and session that asked. New: one path for both, and an
item that cannot be delivered (no such run, a paused queue) is reported to
the sender instead of waiting unseen.

**F8 — two runs on one repository.** Each run works in its own worktree on a
run branch; when its todo is done the run asks for the repository's
integration lease, rebases onto `main`, runs the checks, fast-forwards `main`
and pushes; the next run in the queue rebases first ([§ 10](#10-parallel-work-and-the-git-model)).

**F9 — a todo to the cloud (later).** [§ 11](#11-later).

**F10 — supervising a group.** trc connects to tac, reads the group's
runtimes and their endpoints, attaches to each runtime's event log (through
the relay off the VPN), shows what waits; the supervisor answers an ask,
pauses a queue, proceeds a process.

**F11 — a machine joins.** Install the runtime, give it the group's access,
`register`; it sees the group; nothing is converged for it (reconciles stay
the user's).

**F12 — a version update.** A host installs a new runtime version beside the
old one and moves `current`; running runtimes go on; a format migration runs
once under the machine lock, the others pause.

## 10. Parallel work and the git model

### 10.1 What hurts today

- **Everything commits on `main` in shared clones.** One writer per
  repository is an agreement. A hot repository (a base package, `_ai`) is a
  queue of one.
- **No gate before `main`.** A broken commit is at once every other session's
  base, and published downstream.
- **No discard path.** A run that went wrong is undone by hand.
- **Long runs hold a repository for hours**, with half-finished states on
  `main`.
- **Other sessions' uncommitted work** is in the way of installs, builds and
  reconciles (2026-11-11: a reconcile committed another session's patch;
  2026-11-13: one command destroyed five sessions' uncommitted work).
- **Quiescence is by hand.** Before a reconcile nobody can ask "is anything
  writing here"; agents cannot pause a queue.
- **Machines drift silently** (2026-09: one host 2,322 `_ai` commits behind).
- **Shared files written whole** from one window: queue settings, the shared
  configuration.
- **Cross-quest requests get stuck:** an item sent to a paused or missing
  run, walks reaching todos that depend on a staged walk, a duplicate
  dispatch, a release note that filed nothing.
- **Releases ripple:** one `tom_todo_model` release moves 45 to 54 consumer
  locks; "published version X" is not something a todo can wait for.

### 10.2 What other teams do

Detail and sources in [§ 15.2](#152-parallel-work).

| Model | Good for | Costs |
| --- | --- | --- |
| Shared tree on `main` (ours) | serial work, small edits, state files; no integration step | one writer; no gate; no discard |
| Worktree per task | several writers in one repository | dependencies per worktree, ports, cleanup, drift, late conflicts |
| Branch and pull request per task | teams of people, regulated code | the review queue; needs CI |
| Container or cloud sandbox per task | long autonomous runs | cold start, secrets, cost, no local state |

What the evidence says: worktree per task is the default everywhere; shared
lock files held by agents failed at scale (held too long, never released)
unless a service enforces lifetime; the teams with the highest throughput
moved review after the merge and rely on tests; pull requests moved the
bottleneck to the reviewer (one study: review time up 91 % with AI); a
"commit queue" — a robot as the only committer to `main` that rebases, checks
and lands or rejects — is how trunk-based work is kept with many agents.

### 10.3 Our approach, weighed

**It fits us:** about 40 small repositories make the repository a natural
unit, and most parallel work is across repositories; one person reviews, so a
pull request per task would queue everything on that person; there is no CI
for a pull-request gate to run; published packages need a linear history per
repository; leases with fencing tokens are stronger than what the tools
surveyed have.

**Its real gaps** are not the missing pull requests: the missing gate before
`main`, the missing discard path, the lock on a whole repository for a whole
run, and that integration between machines happens late and unreviewed.

### 10.4 Keep the trunk, add an integration step

1. **A run's result is a branch.** For a repository more than one run may
   want, a run works in a worktree on a run branch (planned in
   `ww_g_collab-1`). For a repository only one run touches, it works on the
   tree as today. Which applies is **a setting per repository that the team
   decides** and can change (CQ-12): a repository one person works on needs
   none; when a group starts working on it in parallel, it gets worktrees.
   `_ai` never gets them.
2. **The lease covers the integration, not the run.** The run holds a long,
   advisory claim on what it touches (a unit, paths) and takes the short,
   exclusive repository lease only to integrate: rebase onto `main`, run the
   checks, fast-forward, push. The fencing token is checked at the push.
   (Items 2 to 10 are proposals of this document.)
3. **An integration queue per repository**, in tac: serial, mechanical. It
   runs the repository's declared checks (analyze, the affected tests) and
   lands or rejects back to the run. No central integrator over repositories.
4. **A touch set per todo:** repositories, packages, path globs (`resources:`
   and `scope` exist in the todo model). The queue starts only todos whose
   sets do not overlap, and says up front which wait on which.
5. **Waiting runs rebase** after each integration and re-run their checks
   before they land.
6. **A run log per todo:** the commits before and after, per repository. It
   gives the review unit (the diff of a todo), the discard path (revert the
   range) and the trace from a commit to its session.
7. **"Published" as a dependency:** `blocked_until: <package> >= <version>`
   exists in the todo model; the runtime checks the registry and unblocks.
8. **Quiescence as a question:** tac answers "who holds what here" for a
   repository, a workspace or the fleet; a reconcile or a cutover asks instead
   of assuming; a runtime can be asked to pause its queue after the current
   item.
9. **`_ai` stays on `main`** without worktrees: todo and state files are not
   code, merge by their drivers, and are written by path.
10. **Review without pull requests:** the diff of a todo as a review document
    in the MD Browser, a review agent with fresh context given only the diff
    and the todo's DONE WHEN, a person only for load-bearing paths
    (migrations, formats, publishing, credentials), the verdict recorded with
    the todo. A draft pull request only for a risky todo, when wanted.

What this does not take over from the others: a pull request per task, a
merge queue on GitHub, agents working on `main` of a repository several runs
want.

### 10.5 Cross-quest linkage

- **One addressing scheme:** `<quest>/<todo>`, `<quest>@<run>`, a session, a
  participant; valid on one machine and across machines.
- **Delivery is acknowledged:** a sent item is accepted by a run, refused
  with a reason, or waits visibly at the sender with what it waits for.
- **A todo names what it waits for**, of any quest; the runtime follows
  blockers across quests (built) and across machines (through tac).
- **A request to another quest is a todo there**, with `filed_by`, not a
  prompt that may end without filing anything.
- **Quest to repositories:** which repositories a quest works on is recorded
  (vscode_extension `vscimpb154`), so claims and touch sets can be checked.

## 11. Later

### 11.1 Deferred features

Decided as not part of the first version; kept here so they can be checked
on later.

| Feature | Deferred by | Note |
| --- | --- | --- |
| Todos to the cloud: dispatch to vendor agents and to an own runtime server | CQ-13 | § 11.2 … § 11.5; the data question comes first |
| A data policy per quest or repository (which provider may see what) | DQ-8 | the centrally administered configuration decides for now |
| Asking people outside the team by email, answered on a web page of the tac server | DQ-3 | needs the server to send email and a small web client |
| The server sending invitation emails itself | DQ-2 | the protocol does not change |
| Standalone runtimes that outlive their host, to which a client attaches to supervise | CQ-4 | the protocol does not prevent it |
| Pairing of devices and end-to-end encryption between device and runtime | CQ-10 | mandatory with the relay, when anything is reachable from outside the VPN |
| A review's own git repository on the tac server, for reviewers without repository access | DQ-4 | pinned blobs cover reading and returning for now |
| A server-side runtime for web, phone and tablet clients (T8) | WQ-1 | in the plan, in a later wave; until then Webwork's messaging works on the desktop only |
| Telegram: one bot token for every runtime | FO-16 | todo `ww_f_collab-6` |
| Encryption at rest of messages and blobs | FO-20 | an option, key in Tom Secrets Manager |
| Billing and customers of several organisations on one server | — | the full server has the records (CQ-9) |

### 11.2 Todos to the cloud

**Not part of the first specification** (CQ-13). The topic is kept here as
researched, for a later round. The open point beneath it is larger than the
adapters: sending a todo to a vendor's sandbox sends source code there, and
already the use of a model provider sends the content of local files to that
provider's servers. A data policy (which provider may see which repository or
quest) would have to come first (DQ-8).

### 11.3 What exists

Detail and sources in [§ 15.4](#154-cloud-agents).

| Service | Submit by program | Runs | Returns |
| --- | --- | --- | --- |
| GitHub Copilot cloud agent | REST tasks API (preview), issue assignment, `/delegate` in its CLI | GitHub sandbox, GitHub Actions, or a registered machine | a branch and a pull request |
| Claude Code cloud | `claude --cloud "<task>"`; an API-triggered scheduled task | an Anthropic VM, or a self-hosted runner | a `claude/` branch; `--teleport` brings the session local |
| Claude Managed Agents | a full REST API with events | Anthropic's or an own sandbox | events and files |
| Codex cloud | `codex cloud exec` (experimental) | an OpenAI container | a diff; `codex apply <id>` applies it locally |
| Cursor cloud agents | REST API (beta) | a Cursor VM | a branch and a pull request |
| An own runtime server | our protocol and tac | a machine we control | a branch |

Common to all: a task is a repository, a base ref, a prompt and a prepared
environment; the result is a branch; status is a small state machine with
"waiting for the user"; follow-up messages steer a running task; the base
must be pushed first; the agent sees nothing local — no `_ai`, no runtime
tools, no local MCP servers.

### 11.4 Dispatch as a transport (sketch)

- **A dispatch transport** takes a todo and returns a branch. The queue item
  stays `sending` while the task runs elsewhere; its status events and
  "waiting for the user" arrive as the item's events and asks.
- **The prompt is self-contained:** the todo's record, its DONE WHEN, the
  guidelines it needs, the rule not to edit todo state. Todo state stays
  local; the runtime marks the todo when the result is integrated.
- **The result goes through the integration step of § 10.4**: fetch the
  branch, rebase, run the checks locally, fast-forward `main`, delete the
  branch. No pull request is needed and no CI.
- **The first target is our own runtime server (T6):** the same runtime, the
  full tool set, `_ai` at hand, no vendor preview, reachable through tac; the
  todo travels as a tac command and the run works in a worktree.
- **Vendor targets after it,** one adapter each, starting with the ones that
  need no GitHub Actions: Codex cloud (`codex apply` needs no pull request),
  Claude cloud, the Copilot tasks API.
- **Environment per repository:** a setup script and a network policy kept in
  the repository, so a sandbox can build it (Dart and Flutter are not
  preinstalled anywhere, as far as could be verified).

### 11.5 What stands in the way

- **GitHub Actions is off by policy** on every repository; `@claude`, the
  Gemini action and Copilot's Actions-based sessions need it. Whether
  Copilot's sandbox works with Actions off is not documented (CQ-13).
- **A tree of nested clones:** every service assumes one repository per task;
  a todo that touches three repositories is three tasks or stays local.
- **Preview interfaces:** the Copilot tasks API, Claude's trigger API, `codex
  cloud` and Cursor's API are preview or beta; Google's Jules was shut down
  with two months' notice.
- **Source and transcripts** stay with the vendor; a ruleset must keep agent
  pushes off `main`; no secrets in a sandbox's environment.
- **Quota:** cloud sessions draw on the same subscription limits as local
  work.

## 12. Clients, UI components and the supervision app

### 12.1 Client packages

Decided (FO-10, FO-11): `tom_ai_runtime_client` (Dart),
`tom_ai_runtime_nondart/<language>/` for the eight others, the protocol layer
generated from the schema, a convenience layer by hand, one conformance
suite; thoroughly tested in Dart and TypeScript.

There are two clients, in packages of their own (CQ-15): **the runtime
client** (the protocol of § 6; `tom_ai_runtime_client` in Dart) and **the tac
client** (coordination and messaging; `tom_tac_client` in Dart). The runtime
client depends on the tac client. The tac client is used by runtimes, servers
and tools; an application reaches tac through its runtime (WQ-1), so a
browser or phone application uses the runtime client against a server-side
runtime. The same split holds in the other eight languages.

Convenience layer, the same in every language: find or start the installed
runtime, connect, subscribe, queue a prompt, walk a todo group, answer an
ask, register host tools; connect to tac, send a message, send documents for
review, receive.

### 12.2 Flutter components (`tom_ai_runtime_ui`)

Themeable by the host, no Forge dependency, desktop, web, iOS, Android.
Every reusable component lives here; `tom_forge_agentic` is built on top of
it and keeps only what binds the components into the Forge shell (CQ-14). The
basis is what the extension shows today; the names follow what the web kits
standardised ([§ 15.5](#155-ui-kits)), since no Flutter kit covers agent
work.

| Group | Components | From |
| --- | --- | --- |
| Conversation | conversation, message, prompt input with the three send choices, attachments, reasoning, tool card, context and usage, model and profile selector | @CHAT |
| Asks | question, pick, confirmation (tool approval), plan approval, decision, gate result with buttons, document ask | the ask panels, plan mode, `askInMdBrowser` |
| Queue | queue list (waiting, running, done; reorder, edit, remove), item editor, timed requests, templates | queue editor |
| Runs and processes | run tabs with state marks, process view (phases, steps, Proceed, Decide, Skip, Back), branching, runs overview | PROCESS, RUNS |
| Todos | todo list and tree, todo editor, decisions, session todos, todo log, cross-quest panel | the todo panels |
| Trail | live trail, summary trail, the bounded appending Markdown view | trail viewers, Output |
| Sessions and memory | sessions, memory, chat variables, notes, personal notes | SESSIONS, the editors |
| Messaging | conversation list, conversation, composer, document card, review request card, reminder, people | new (tac) |
| Review | the MD review component: questions and answers, comments, marks, team chips, votes, conflicts, consolidation | MD Browser |
| Supervision | runtime list, what waits, notifications, coordination page (claims, leases, integration queue), window status | WINDOW STATUS, NOTIFICATIONS, new |
| Settings | profiles, providers and keys, coordination, the status page's sections | Status Page |

### 12.3 Screen and component descriptions

The design is delivered as descriptions and running code, not as drawings
(CQ-18, DQ-7):

1. **A complete inventory of the extension's screens**: every view, panel
   and editor, and for each one what it becomes here.
2. **A description per screen and component**, extracted from the
   extension: its webview code (the agents that built it placed and shaped
   the elements well), screenshots, and the todos that defined it. Each
   description names the elements, their layout, the states (loading, empty,
   error, waiting for an answer), the actions and the data each needs from
   the client.
3. **A gallery application** in `tom_ai_runtime_ui` that shows every
   component with fake data: the living design and the test bed.

Everything that can be specified now is specified completely. The extension
keeps changing; the descriptions are amended as it does.

**What a screen of the extension becomes** is one of:

| Outcome | Meaning |
| --- | --- |
| reused | the component follows the extension's layout |
| starting point | the function is needed, the layout is designed anew |
| split | one screen becomes several components (the Status Page: providers, profiles, coordination, diagnostics each on their own) |
| host's own | stays specific to VS Code; no component |
| not needed | no counterpart in the runtime's components |

**The inventory, first pass** (to be completed and decided in the deepening):

| Extension screen | Outcome (proposed) | Component group |
| --- | --- | --- |
| @CHAT panel | reused | conversation |
| ask, pick, tool-approval and plan-approval bars | reused | asks |
| user-interaction panel, USER NOTIFICATIONS | starting point (the ask inbox) | asks |
| queue editor, queue entry, queue templates | reused | queue |
| timed requests editor | reused | queue |
| PROCESS view, process branching | reused | runs and processes |
| process editor, process template editor | starting point | runs and processes |
| RUNS overview | reused | runs and processes |
| QUEST TODOS, SESSION TODOS, WORKSPACE TODOS, the TODO panel | reused | todos |
| quest todo editor | reused | todos |
| TODO LOG | reused | todos |
| trail viewer, trail editor, quest logs | reused | trail |
| output channels | starting point (the bounded appending Markdown view) | trail |
| SESSIONS, session pickers | reused | sessions and memory |
| memory panel, chat variables editor | reused | sessions and memory |
| QUEST NOTES, WORKSPACE NOTES, VS CODE NOTES | reused (notes), the last host's own | sessions and memory |
| MD Browser, with questions, marks, team review, consolidation | starting point (`tom_md_browser_editor`) | review |
| WINDOW STATUS | starting point (the runtime list of a group) | supervision |
| NOTIFICATIONS | reused | supervision |
| Status Page | split | settings; supervision |
| prompt, reusable-prompt and global template editors | reused | settings |
| roles editor | reused | settings |
| @WS panel (guidelines, documents, logs) | starting point | host's own in part |
| RESOURCES, PREREQUISITES, issues panel, test panels | host's own | — |
| reload overlay, migration screens | starting point (version callbacks, § 6.7) | settings |
| — (new) messaging: conversations, composer, document and review cards | new, from Webwork's design and § 7 | messaging |
| — (new) coordination page: claims, leases, integration queue | new | supervision |
| — (new) team administration: members, invitations, devices | new | settings |

The screens built from the components, each for a desktop panel, a narrow
side panel and a phone: the AI panel (conversation, queue and trail,
switchable or side by side); process and runs; todos; the ask inbox with its
escalation; messaging; the review editor and the consolidation view;
supervision (the group overview, a runtime's detail); the coordination page;
settings and team administration.

### 12.4 Tom Runtime Control (trc)

Full remote control with the focus on supervising a group (FO-12): a Webforge
application from the start that also runs standalone; built from the client
and the components; what it adds is the overview.

What others ship ([§ 15.6](#156-supervision)): an outbound connection from
the machine to a relay, no inbound ports; pairing a device by account or QR
code; per-device enrolment and revocation; push only for "needs input" and
"done", suppressed while the user is active elsewhere; one product encrypts
end to end with device-held keys, the others rely on TLS to the relay.

### 12.5 Repository quests and personal files

As decided in the feature overview (§ 3.7, FO-13, FO-18, FO-22): classic
quests, repository quests, one personal repository per person at
`_ai/personal/` with `quests/<quest>/` folders and `personal-notes`. The fleet
side has no prior decision on it ("exactly one `_ai`" is the layout's rule);
al_the_bear is told with `ww_e_gitruntime-9`.

## 13. What the quest delivers

### 13.1 How the specification is made

The specification is made **in the `idea_to_todos` run on this concept, not
in the tom_specs process** (CQ-1). The run discusses what is needed and how
it is split up, and files very detailed todos, among them the todos that
create the detailed documents. Then each component's document is worked
through on its own, one by one, in a guided session (questions in the MD
Browser), document by document.

**The documents take their structure from the TomSpecs model** (CQ-17,
DQ-10): the section structure of its document types is walked, the sections
this project needs are collected, and the result is a skeletal specification
that is then filled in.

- **The Solution Blueprint comes first, and the work goes deeper inside
  it.** One blueprint for the whole system: scope, glossary, the people
  involved, assumptions and constraints, the information model, the
  requirements, architecture and technology, security and access, experience
  and interface design, quality, delivery and rollout.
- **A detailed document only where a component needs one**, never all
  twelve: for example the interface document for the runtime protocol and
  for TAC, the experience design document for the UI components.
- **They are real TomSpecs documents**, so the spec tools (outline,
  validation, review rounds) work on them.

The model's document types and what this project would take from each:

| Model document | Takes from it |
| --- | --- |
| Solution Blueprint (SBP) | the frame and, deepened, most of the specification |
| Information Model (IFM) | the records: quest, todo, run, queue item, session, ask, event; participant, team, conversation, message, blob, lease |
| Requirements Specification (RSP) | functional and non-functional requirements per component |
| Interaction Scenarios (ISC) | the key flows F1 … F12 |
| Architecture & Technology (ATS) | system architecture, components and dependencies, communication, operation and monitoring: the topologies T1 … T8 |
| Integration & Interface (IIS) | the runtime protocol, the TAC protocol, the MCP servers, the client APIs |
| Security & Access (SAS) | identity, teams, tokens, remote control, encryption, secrets |
| Experience Design (XDS) | screens, screen flow, UI components, responsive design |
| Quality & Acceptance (QAP) | conformance suites, the test strategy |
| Delivery Roadmap (DRM), Transition & Rollout (TRP) | the split, the order, the rollout |

**Wishes for tom_specs that come out of this** (input for that quest, not
decided here): generating the twelve detailed documents from a Solution
Blueprint, and generating the code-generation inputs directly from a
blueprint.

**The order of building** (DQ-6): two tracks in parallel.

- **Track tac:** the server, participants and teams, messaging, documents,
  the tac clients. It does not depend on the split of the extension.
- **Track runtime:** the split, the protocol, the runtime client, the
  components, then the tac client inside the runtime with claims and the
  integration step.

Webwork and tom_forge wait for their parts of it; both can progress on
their own meanwhile.

### 13.2 The deliverables

| Deliverable | Content |
| --- | --- |
| **Specification** | requirements and behaviour of tar, tac, trc, the clients and the components, in the structure of § 13.1 |
| **Architecture document** | components, process model, the topologies, the flows as sequences, state ownership, security |
| **Runtime protocol specification** | commands, events, reverse requests, the ask envelope, the event log, versioning; the JSON schema |
| **TAC specification `tac/2.0`** | participants, teams, the server, messaging, documents, reminders, integration, the bindings |
| **API documentation of the clients** | per language: the runtime client and the tac client, with examples; `doc/api/` of each package |
| **Screen and component descriptions** | § 12.3 |
| **Guides** | integrating the runtime into a Flutter application; setting up a tac server and a team; pairing with Tom Secrets Manager; the parallel-work guideline with what is enforced |
| **The code** | runtime, service, clients, components, trc |

### 13.3 The split and the stable extension

Once the split starts (CQ-19):

- the extension is **branched** and the new line gets **its own extension
  id**; it is worked on in a separate worktree;
- the new extension **refuses to start while the old one is active in the
  same window**;
- the new one is installed everywhere but activated only in the window used
  for testing, where the current one is deactivated;
- the old extension keeps being changed as needed; its changes are merged
  forward into the new line, or their todos are repeated there.

### 13.4 The existing todos

The todos filed before this concept (`ww_*`, `tac_webwork-*`, `12b_woneb*`,
`xx*`) are input on what was discussed (CQ-20). The idea run ends with a new
set of todos in one grouping and order; the old ones are deleted or moved
into their place in it, and the `blocked_by` entries of other quests follow.

## 14. Decisions and questions

### 14.1 Decisions

The question rounds, with your answers as taken into the text.

| Id | Topic | Decision | In § |
| --- | --- | --- | --- |
| CQ-1 | How the specification is made | in the idea run, not the tom_specs process: very detailed todos, todos that create the documents, then each component's document in a guided session | 13.1 |
| CQ-2 | Machine-wide state | the runtime owns it; its implementation routes through the local tac service | 5.6 |
| CQ-3 | Repositories | from the workspace's setup file (`repos.yaml`); a quest lists its default repositories and subtrees, claimed when a todo names none | 5.5 |
| CQ-4 | Lifetime of a runtime | started by its host, ends with it; standalone runtimes later | 5.7 |
| CQ-5 | Agent Client Protocol | both directions, late in the order | 5.4, 6.5 |
| CQ-6 | Event log | in memory with a bound; the trail files are the durable record | 6.1 |
| CQ-7 | Asks to people elsewhere | by presence and role; quest owners, fallback to the owner of the triggering quest, forwarding, escalation, monitoring, email to outsiders | 6.6 |
| CQ-8 | tac's specification | one `tac/2.0` with everything | 7.9 |
| CQ-9 | The server | the full server first | 7.2 |
| CQ-10 | Identity and remote control | identification to start with and invitation with team tokens, both built; remote control only inside a team and only where the runtime's host allows it | 7.3 |
| CQ-11 | Files of longer processes | a process may pin its blobs in tac; review sets; versioned changes go through a git repository | 7.6 |
| CQ-12 | Worktrees | a setting per repository, decided by the team, changeable | 10.4 |
| CQ-13 | Todos to the cloud | moved to "later"; the data question comes first | 11 |
| CQ-14 | Flutter components | all in `tom_ai_runtime_ui`; `tom_forge_agentic` builds on it | 12.2 |
| CQ-15 | The tac client | its own package; tac is a reusable component of its own | 7.2, 12.1 |
| CQ-16 | Secrets | `tsm:` with TSM's grammar, `os:`, `env:`, `file:`; runtime and tac paired with TSM once; a setup guide | 5.8 |
| CQ-17 | Structure of the specification | a skeleton from the TomSpecs model's sections, filled in | 13.1 |
| CQ-18 | Screen designs | descriptions extracted from the extension (code, screenshots, todos), and a gallery application | 12.3 |
| CQ-19 | The stable extension | branch, own extension id, separate worktree; the new one refuses to start beside the old in one window | 13.3 |
| CQ-20 | The existing todos | input; replaced by the idea run's todos | 13.4 |
| DQ-1 | Teams and agent groups | two things: a team is people, an agent group is runtimes; one runtime belongs to one person; Webwork's "group" means team | 7.3 |
| DQ-2 | The invitation | owners invite; a one-time password passed on by the owner, valid once for 7 days; the server generates the user id and returns a team token per person and team; devices register under it; email by the server later | 7.3 |
| DQ-3 | Escalation of asks | the chain, the times, the end of the chain, forwarding and monitoring as in § 6.6; email to outsiders deferred | 6.6, 11.1 |
| DQ-4 | Versioned documents | in the project's specification folder or a specification repository; usually not the quest | 7.6 |
| DQ-5 | A quest's default resources | every todo is written with its own `resources:`; the quest's list is the fallback | 5.5 |
| DQ-6 | Order of building | two tracks in parallel: tac, and the runtime | 13.1 |
| DQ-7 | Screen descriptions | a complete inventory of the extension's screens, each decided: reused, starting point, split, host's own, not needed | 12.3 |
| DQ-8 | Data policy | later; the configuration decides, and it is split into a centrally administered part and a per-runtime part | 5.5, 11.1 |
| DQ-9 | Installing the runtime | every host installs its version into the shared location; version checks, pass-through of unknown fields and upgrade callbacks in every client library | 5.7, 6.7 |
| DQ-10 | Form of the specification | TomSpecs documents; the Solution Blueprint first and deepened; detailed documents only where needed | 13.1 |
| DQ-11 | The centrally administered configuration | by content: role types, processes and templates in the repository; providers, the allowed list and standard profiles as a team's configuration in tac, stored in whichever backend the team uses | 5.5 |
| DQ-12 | Which team a runtime acts for | a quest has a home team; another team only by explicit address, with the user's token for that team | 7.3 |
| DQ-13 | The next step | an `idea_to_todos` run with this document as its input document | 13.1 |
| WQ-1 | Clients without a runtime | browser, phone and tablet clients reach tac through a server-side runtime, which also hosts the web version; tac's participants are people and runtimes | 7.3, 7.10, 8 (T8) |
| WQ-2 | Protocol versions | `tac/2.0` built in one go; capability blocks announced in `hello`; new capabilities added within `tac/2.0`, backwards compatible | 7.9 |
| WQ-3 | Retention of user messages | 1 year by default; a team may set any value or keep | 7.5 |
| WQ-4 | The `tac_webwork` todo group | webwork told now; `webworkreq1` completed; the group replaced by the idea run's todos | 7.10 |

### 14.2 Open questions

None.

## 15. Research: what other teams do

Read on 2026-11-18. Where only a secondary source was reached, it says so.
What could not be verified is left out or marked.

### 15.1 Protocols

- **Agent Client Protocol** (Zed): JSON-RPC over stdio between an editor and
  an agent; `session/new`, `session/prompt`, `session/update`,
  `session/request_permission`; a registry since 2026-01; a remote transport
  is still a draft.
  [overview](https://agentclientprotocol.com/protocol/overview),
  [registry](https://zed.dev/blog/acp-registry)
- **Codex app-server:** thread, turn, item with started, delta and completed
  events; `turn/steer`, `turn/interrupt`; approvals as server requests;
  several clients by subscription, a thread unloads after its last subscriber.
  [docs](https://learn.chatgpt.com/docs/app-server)
- **OpenCode server:** HTTP with an event stream, built for several clients;
  an experimental durable per-session log read "after sequence N".
  [docs](https://opencode.ai/docs/server/)
- **Claude Agent SDK:** `canUseTool`, an ask-user tool with one to four
  questions, a hook can defer so the process exits and resumes later.
  [docs](https://code.claude.com/docs/en/agent-sdk/user-input)
- **A2A 1.0** (Linux Foundation): agent cards, durable tasks, the state
  `input-required`; it absorbed IBM's ACP.
  [announcement](https://lfaidata.foundation/?p=7689)
- **MCP:** the 2025-11-25 revision added experimental tasks and URL
  elicitation; the 2026-07-28 revision made the protocol stateless and moved
  tasks to an extension.
  [2025-11 elicitation](https://modelcontextprotocol.io/specification/2025-11-25/client/elicitation),
  [2026-07 release](https://blog.modelcontextprotocol.io/posts/2026-07-28/)
- **AG-UI:** typed events over HTTP for web front ends; interrupts carry a
  response schema.
  [guide](https://www.copilotkit.ai/blog/developers-guide-to-the-ag-ui-protocol)

**Taken:** the durable numbered log, thread/turn/item, one ask envelope, asks
that outlive the process, ACP as an option on both sides, MCP pinned per
revision. **Not taken:** A2A between runtimes for now (TAC commands do it;
A2A is an option for outside agents), AG-UI.

### 15.2 Parallel work

- **Worktree per task** is the default: Claude Code (`--worktree`, subagent
  `isolation: worktree`; a fresh checkout that needs its own dependency
  install, no integration step), the Codex app, Conductor, Crystal, Claude
  Squad. [Claude Code](https://code.claude.com/docs/en/worktrees),
  [Codex](https://developers.openai.com/codex/app/worktrees)
- **Cursor's swarm experiments:** a shared claim file with locks failed
  ("20 agents would slow to the throughput of 1-3"; locks held too long or
  never released); the result was planners and isolated workers on their own
  copies; a central integrator became a bottleneck.
  [post, 2026-02-05](https://cursor.com/blog/self-driving-codebases)
- **Anthropic's C compiler:** 16 agents, each with its own clone; claims as
  files, the push decides the race; tests steer.
  [post, 2026-02-05](https://www.anthropic.com/engineering/building-c-compiler)
- **Trunk with agents:** a commit queue — a robot as the only committer to
  trunk that rebases, builds, lands or rejects; "two changes can auto-merge
  with zero conflict and still break each other in meaning".
  [trunkbaseddevelopment.com](https://trunkbaseddevelopment.com/committing-straight-to-the-trunk/)
- **Pull requests with AI:** teams with high AI use merged 98 % more pull
  requests, with review time up 91 % and no delivery gain at organisation
  level (vendor telemetry, correlational).
  [Faros, 2025](https://www.faros.ai/blog/ai-productivity-paradox-report-2025)
- **Claims and mail:** `mcp_agent_mail` gives advisory leases on paths with a
  lifetime and an optional pre-commit guard.
  [README](https://raw.githubusercontent.com/Dicklesworthstone/mcp_agent_mail/main/README.md)
- **Task graphs:** Beads (`bd ready`: no open blockers; claim), Kiro (waves
  of independent tasks), spec-kit (`[P]` for tasks on different files).
  [Beads](https://cdn.jsdelivr.net/gh/gastownhall/beads@main/README.md),
  [Kiro](https://kiro.dev/docs/specs/index)
- **Claude Code agent teams:** a shared task list with dependencies, file
  ownership per teammate, single machine.
  [docs](https://code.claude.com/docs/en/agent-teams)
- **jj and virtual branches:** jj has no hooks, submodules or
  `.gitattributes` support, which rules it out with our merge drivers;
  GitButler's agent integration is experimental.
  [comparison, 2026-11-11](https://wavect.io/blog/git-worktrees-vs-jujutsu-ai-coding-agents/)

No tool surveyed models "package X is published at version N" as a
dependency, and none has leases with fencing tokens across machines.

### 15.3 Spec-driven work

- **Spec Kit** (constitution, specify, plan, tasks, implement), **Kiro**
  (requirements with acceptance criteria, design, tasks), **OpenSpec**
  (change proposals against a living specification), **BMAD** (role
  personas). Criticisms: drift between specification and code once coding
  starts, too much Markdown to review, too heavy for small changes
  (secondary sources).
- **Anthropic's guidance for long-running agents:** a feature list with test
  steps and a `passes` flag that is the only field a coding session may
  change; a progress file; each session orients itself, does one feature,
  tests it end to end, commits; the failure modes are declaring victory early
  and marking done on unit tests alone.
  [post, 2025-11-26](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)

**Taken as proposals:** acceptance evidence per todo that the working agent
cannot edit (the DONE WHEN as checks with a recorded result); a fixed start
and end of a session (orient, and a progress note); a fast path for small
changes; a drift check between specification and code at a gate.

### 15.4 Cloud agents

- **GitHub Copilot cloud agent:** a REST tasks API in public preview
  (`POST /agents/repos/{owner}/{repo}/tasks`), issue assignment to
  `copilot-swe-agent[bot]`, `/delegate` in the Copilot CLI; a sandbox, an
  Actions session, or a registered machine; one branch and pull request per
  task; Claude and Codex selectable as agents.
  [API](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/use-cloud-agent-via-the-api),
  [about](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent)
- **Claude Code cloud:** `claude --cloud`, one repository per session, the
  remote cloned at the pushed branch, a `claude/` branch back,
  `--teleport` to continue locally; environments with a network policy and a
  setup script; API-triggered scheduled tasks; self-hosted runners; Remote
  Control of a local session; Managed Agents with a full API.
  [cloud](https://code.claude.com/docs/en/claude-code-on-the-web),
  [environments](https://code.claude.com/docs/en/cloud-environments),
  [remote control](https://code.claude.com/docs/en/remote-control),
  [managed agents](https://platform.claude.com/docs/en/managed-agents/overview)
- **Codex cloud:** `codex cloud exec --env <id>`, `codex apply <task>`.
  [CLI](https://learn.chatgpt.com/docs/developer-commands?surface=cli)
- **Cursor cloud agents:** `POST https://api.cursor.com/v1/agents` (beta).
  [docs](https://cursor.com/docs/cloud-agent/api/endpoints)
- **Google Jules:** read-only since 2026-11-11, gone on 2026-12-31.
  [changelog](https://jules.google/docs/changelog/)
- **Others with an API:** Devin, OpenHands Cloud, Factory's headless mode.

### 15.5 UI kits

- **AI Elements** is the broadest list of agent components: conversation,
  message, prompt input, attachments, reasoning, tool, confirmation,
  question, plan, task, queue, checkpoint, context, sources.
  [site](https://elements.ai-sdk.dev/)
- **assistant-ui:** thread, composer, a tool UI registry with an approval
  fallback. [docs](https://www.assistant-ui.com/docs/ui/tool-fallback)
- **Flutter:** the Flutter AI Toolkit is a chat view; the GenUI package is
  deprecated in favour of A2UI packages still before 1.0.
  [toolkit](https://docs.flutter.dev/ai/ai-toolkit),
  [genui](https://github.com/flutter/genui)

No Flutter kit covers tool cards, approvals, plans, queues and usage.

### 15.6 Supervision

- **Claude Code Remote Control:** the local process connects outbound and
  polls; devices are enrolled and revocable; push is suppressed while the
  user is at the terminal; a server mode runs up to 32 sessions, optionally a
  worktree each. [docs](https://code.claude.com/docs/en/remote-control)
- **Happy:** an open-source wrapper, relay and mobile app; end-to-end
  encrypted with device keys paired by QR code; the relay is self-hostable.
  [how it works](https://happy.engineering/docs/how-it-works/)
- **Inboxes for agent questions:** LangGraph's Agent Inbox models an
  interrupt with allowed responses accept, edit, respond, ignore.
  [reference](https://reference.langchain.com/python/langgraph.prebuilt/prebuilt/interrupt/HumanResponse)

### 15.7 Secrets

References resolved just in time into one subprocess (1Password's `op run`),
a helper command that returns a key (Claude Code's `apiKeyHelper`), and
proxies that swap a placeholder for the real secret at the network edge for
sandboxed agents ([example](https://nono.sh/credential-injection)).

## 16. Proposed parts for the blueprint

The parts the idea run's blueprint could have; each becomes a section to
deepen and a todo group.

| Part | Content | § |
| --- | --- | --- |
| part-runtime-core | formats, runs, processes, queue, transports, locations, configuration | 5 |
| part-machine-state-and-install | the machine service, the shared installation, versions, format migration | 5.6, 5.7 |
| part-protocol | commands, events, the log, the ask envelope, reverse requests, the schema | 6.1 |
| part-hosts-and-tools | the host interface, the three tool sets, MCP servers, ACP | 6.2 … 6.5 |
| part-tac-participants-and-server | participants, devices, identification, the team server, the relay | 7.2, 7.3, 7.8 |
| part-tac-messaging | conversations, message kinds, reminders, presence-aware delivery | 7.4, 7.5 |
| part-tac-documents-and-review | blobs, lifetimes, the review exchange | 7.6, 7.7 |
| part-parallel-work | claims, worktrees, the integration lease and queue, touch sets, the run log, review without pull requests, quiescence | 10 |
| part-cross-quest | addressing, acknowledged delivery, blockers across machines | 10.5 |
| part-teams-and-identity | teams, invitation, team tokens, remote-control permission | 7.3 |
| part-ask-routing | quest owners, routing by presence and role, escalation, the ask inbox | 6.6 |
| part-data-policy | which provider may see which quest or repository (DQ-8) | 14.2 |
| later: part-dispatch | dispatch transports, the own runtime server, vendor adapters | 11 |
| part-clients | the nine client packages, the two clients in each, the conformance suite | 12.1 |
| part-ui-components | the component groups and the screen designs | 12.2, 12.3 |
| part-supervision | trc | 12.4 |
| part-repository-quests | quest types, the personal repository | 12.5 |
| part-secrets-and-providers | key resolution, the providers | 5.8 |
| part-topologies-and-flows | T1 … T8, F1 … F12 for the architecture document | 8, 9 |
| part-specification-skeleton | the documents per component in the TomSpecs model's structure | 13.1 |
| part-split-and-rollout | the split stages, the stable extension, the order, what replaces which todo | 2.3, 13 |

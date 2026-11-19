<!-- snapshot of _ai/quests/ai_runtime/ai_runtime_feature_overview.md, 2026-11-19 -->
# AI Runtime — feature overview

Which components the ai_runtime quest has and plans, what each one's main
features are, and the order they are built in. Details are in
[ai_runtime_project_idea.md](ai_runtime_project_idea.md), the input for the
specification. The § references below point to it.

Questions are numbered FO-n; the **bold** option is the recommendation, the
answer goes on the **Answer:** line. The decisions taken so far are listed in
[§ 5](#5-decisions).

## 1. The system at a glance

```text
     ┌──────────── trc: Tom Runtime Control (supervision app) ────────────┐
     │ remote control of a group: queue, runs, processes, asks, reviews   │
     └──────────▲──────────────────────────────────────▲──────────────────┘
                │ runtime protocol                     │ group state, messages,
                │ (streaming)                          │ documents (TAC)
┌── host ─────┐ │  ┌──── tar: Tom AI Runtime ───────┐   │   ┌── tac ─────────────────┐
│ VS Code ext.│◄┴─►│ quests · todos · processes     │◄──┴──►│ Tom Agent Coordination │
│ Webforge    │    │ queue · sessions · transports  │       │ discovery · leases     │
│ Webwork     │    │ runtime tools + MCP server     │       │ messages · documents   │
└──────┬──────┘    │ coordination client            │       │ local │ GitHub │ server│
       │           └──────────────▲─────────────────┘       └────────────────────────┘
       │ VS Code tools            │ MCP between runtimes (found through tac)
       └─ (extension's MCP server, registered with the runtime inside VS Code)
```

A host attaches to a runtime and adds as thin a UI as it needs. Runtimes find
each other through tac and call each other's runtime tools over MCP, so agents
work across runtimes as they work across VS Code windows today. Every process
on a machine uses the same installed runtime.

## 2. Components

**State:** ✅ built · 🟡 begun · ⬜ planned · 🔁 exists in the extension, to be
extracted.

| Component | Short | Package / place | State |
| --- | --- | --- | --- |
| Tom AI Runtime | tar | `tom_ai/ai_build/tom_ai_runtime` (TypeScript) | 🔁 engine in the extension; ⬜ package |
| Runtime server and protocol | tar | `serve` mode of `tom_ai_runtime` | ⬜ |
| Runtime tools and runtime MCP server | tar | inside `tom_ai_runtime` | 🔁 one tool set and MCP server in the extension, to be split |
| VS Code tools and the extension's MCP server | — | stay in the extension | 🔁 |
| Shared runtime installation | tar | per-user application data folder, versions side by side | ⬜ |
| TAC protocol | tac | `tom_tac_service/doc/tac_specification.md` (`tac/1.0`) | ✅ draft of the API |
| Coordination service | tac | `tom_ai/ai_build/tom_tac_service` (moved from `tom_ai/vscode/`) | 🟡 local mode built; GitHub and server backends, user messages and documents planned |
| Coordination client in the runtime | tac | `tom_ai_runtime` | ⬜ |
| MCP and TAC relay | tac | tac server mode | ⬜ |
| Dart API package | — | `tom_ai/ai_build/tom_ai_runtime_client` | 🟡 grows out of `tom_vscode_scripting_api` |
| Other API packages (8 languages) | — | `tom_ai/ai_build/tom_ai_runtime_nondart/<language>/` | ⬜ |
| Flutter UI components | — | `tom_ai/ai_build/tom_ai_runtime_ui` | ⬜ |
| Tom Runtime Control | trc | a Webforge application that also runs standalone | ⬜ idea set up |
| Repository quests and personal repository | — | runtime, fleet tooling | ⬜ planned (`quest_repositories.md`, `ww_e_gitruntime-*`) |
| Provider keys | — | Tom Secrets Manager, OS secret store, `file:` / `env:` | ⬜ |
| Model providers | — | transports in the runtime | ⬜ |
| Todo follow-ups | — | `tom_todo_model` 2.2.0, todo schema, extension | ✅ |

**Deferred:** Telegram. Its todo `ww_f_collab-6` stays in this quest,
deferred.

## 3. The components and their main features

### 3.1 Tom AI Runtime (tar) — `tom_ai_runtime`

The engine of today's VS Code extension as a runtime of its own (§ 4).

- **One implementation of the `_ai` formats and engines** for every host:
  quests, todos, memory, sessions, trails, chat variables, the format-version
  stamp and its migration.
- **Processes:** nested processes and branches, decisions and gates, the
  process-move marker, process runs with their own queue lanes,
  `process-subject`.
- **The queue:** pre-prompts and follow-ups, todo walks, repeated todos,
  session todos, timed requests, reminders, soft interrupts, done
  notifications, `on_done` carried out at completion.
- **Chat and transports** behind one `ModelTransport` interface. All
  transports are the runtime's; there are no host transports:
  - model transports (direct API, Local LLM, later `pi-ai` and the providers):
    the runtime runs the tool loop;
  - agent transports (Agent SDK, Copilot SDK, later Codex, Gemini CLI,
    `pi-coding-agent`): they run their own loop and reach the tools through
    MCP;
  - **Copilot** only through direct calls and the Copilot SDK. The extension's
    VS Code LM and Copilot chat transports are removed.
- **Direct-API parity:** caching, retries, usage and cost, continuation,
  compaction, effort and thinking; the Claude Code features and plan mode on
  every transport.
- **Team review** and the expression language `${{ … }}`.
- **Runtime tools** (§ 3.3).
- **Host interface `QuestRuntimeHost`:** locations, identity, configuration,
  the asks (`ask`, `pick`, `askInDocument`, `approveTool`, `acceptPlan`,
  `decide`), `notify`, `openFile`, `openMdBrowser`. A host refuses what it has
  no concept for. It provides no transports.
- **Process model:** one runtime instance per quest; in VS Code one per
  window, in Tom Forge one per open quest, plus one without a quest for
  Webwork's own AI (`webwork-app`).
- **Locations** through `TomLayout`, built after the workspace layout
  restructuring. `TomLayout` is the resolver the workspace_layout idea
  defines (al_the_bear, `ideas/workspace_layout`): one object, computed per
  window, that answers every place the code needs —
  - `workspaceFile`, `questId`;
  - `workspaceFolder`: the folder the window works in;
  - `root`: the nearest folder above with `.tom/tom_root.yaml`;
  - `aiRoot`: the `_ai` of the workspace folder;
  - `configLayers`: root `.tom/`, then workspace `.tom/`;
  - `guidelineDirs`: root and workspace `_copilot_guidelines/`.

  It replaces today's scattered `getWorkspaceRoot()` / `WsPaths` rules. The
  code keeps its location in the tree.
- **Guards:** no `vscode` import, no host state except through the host, no
  module-level mutable state, snapshots of the tool schemas.

### 3.2 Installation, server and protocol

- **One shared installation per machine**, in the per-user application data
  folder, beside the provider SDKs:
  - macOS `~/Library/Application Support/Tom/runtime/`;
  - Linux `~/.local/share/tom/runtime/`;
  - Windows `%LOCALAPPDATA%\Tom\runtime\`;
  - the SDKs in `…/Tom/providers/`.

  The extension, Tom Forge, Webwork and trc find the preinstalled runtime
  there instead of carrying their own.
- **Versions side by side** (`runtime/<version>/`) with a `current` pointer
  the installer moves. Running processes keep their version until they
  restart; new ones take `current`, so everything started after an update runs
  the same version. A host that needs a newer protocol than a running peer
  says so.
- **`serve --agent-sdk-only`** replaces `agent_sdk_server.js`.
- **Streaming connection:** length-prefixed JSON-RPC 2.0 over loopback TCP
  (the wire of `agent_sdk_server.js` and the CLI integration server), a ready
  line on stdout, exit on stdin close, log on stderr; WebSocket for remote
  clients such as trc.
- **Commands:** `queue.*`, `timed.*`, `process.*` (Proceed, Skip, Back,
  Decide, subprocesses, runs), `session.*`, `todo.*`, `memory.*`,
  `templates.*`, `profiles.*`, `chatVariables.*`, `review.*`,
  `coordination.*`, `tools.call` — a superset of today's bridge methods.
- **Events:** one stream with subscriptions per topic: queue and timers,
  process state, sessions, chat streaming (text, tool calls, usage), trail
  entries, todo changes, review rounds, window status and inbox, plan mode,
  coordination state.
- **Host callbacks** as reverse requests.
- **The protocol as a JSON schema** in the package; the API packages are
  generated from it and checked against it.

### 3.3 Tools and MCP

§ 5 and your notes b … e.

- **Two tool sets, split by where they can live:**
  - **runtime tools**, in the runtime: everything that needs only the
    runtime — quests, todos, queue, processes, sessions, memory, chat
    variables, review, coordination, the Dart binary runners;
  - **VS Code tools**, in the extension: everything that needs VS Code.
- **The runtime MCP server** exposes the runtime tools. It reads and writes
  only `_ai` state, so it is safe to expose between machines.
- **The extension's MCP server** exposes the VS Code tools. Inside VS Code
  the extension registers it with the runtime, so agent transports see both;
  a runtime outside VS Code sees only the runtime tools.
- **Same tool names as today**, so existing prompts keep working.
- **Discovery** of other runtimes and their MCP endpoints through tac.

**What an agent sees today** (checked in `handlers/agent-sdk-transport.ts`
and `handlers/anthropic-handler.ts`):
- The Agent SDK gets **only the `tomAi_*` tools**, through the extension's
  in-process MCP server (`mcp__<server>__tomAi_*`). VS Code's own tools (the
  language-model tools other extensions register) are never passed on.
- **Without `useBuiltInTools`,** Claude Code's built-ins are switched off
  (`tools: []`): the agent works with `tomAi_*` only.
- **With `useBuiltInTools`,** the Claude Code preset is on and 13 `tomAi_*`
  tools that duplicate it are hidden (`DUPLICATES_OF_CLAUDE_CODE_BUILTINS`):
  `loadSkill`, `readFile`, `createFile`, `editFile`, `multiEditFile`,
  `deleteFile`, `moveFile`, `listDirectory`, `findFiles`, `findTextInFiles`,
  `runCommand`, `fetchWebpage`, `webSearch`.
- **A queue run** also drops `tomAi_runCommandStream` and Claude Code's
  `Monitor`.

So the split is about the `tomAi_*` tools. Three groups:

| Group | Examples | Goes to |
| --- | --- | --- |
| `_ai` and coordination | todos, queue, process, sessions, memory, chat variables, review, spec* on `_ai` documents, asks | runtime tools |
| VS Code-bound | `getActiveEditor`, `getOpenEditors`, `closeEditor`, `openFile`, `getErrors`, `getProblems`, `findSymbol`, `gotoDefinition`, `findReferences`, `rename`, code actions, `applyEdit`, `notebookEdit` / `Run`, `runTask`, `runDebugConfig`, `listCommands`, `runVscodeCommand*`, the MD Browser tools | VS Code tools |
| Files, commands, web, git | `readFile`, `editFile`, `findFiles`, `runCommand`, `runCommandStream`, `fetchWebpage`, `webSearch`, `gitRead` / `gitWrite` | runtime tools for the model transports (direct API, Local LLM, providers); never exposed over the runtime MCP server; hidden from agent transports that bring their own |

### 3.4 Tom Agent Coordination (tac)

§ 8 and the agent_collaboration idea.

- **Discovery:** runtimes register with tac and find each other through it —
  on one machine, across the VPN, and through the relay beyond it.
- **TAC protocol `tac/1.0`** (built): customers, agent groups, runtimes,
  sessions, resource keys, units, leases with fencing tokens, messages
  (notifications and commands), endpoints, quotas; HTTP / WebSocket binding
  and GitHub refs binding.
- **`tom_tac_service`, local mode** (built): journal and snapshot per group,
  every TAC operation on `127.0.0.1:19890` behind `local.key`, idle stop,
  `serve` / `admin` CLI, `ensureLocalService()`, the typed `TacClient`.
- **Three backends**, one per workspace in `agent.workspace.yaml`: local (one
  machine), GitHub (one user's machines, refs in `tom_coordination`, no
  messages across machines), server (independent of git, quotas, on bigbeast
  first). With no backend everything works as today; an unreachable backend
  stops the group's queues after the current todo.
- **Claims:** a lease per session on repositories, units, `infra:` and `ai:`
  keys; the queue takes a todo's claims all-or-none, waits on a held claim and
  names the holder; stale after 60 minutes, freed only by the user;
  `claim_hold` / `claim_free` across a todo group.
- **Branches and worktrees:** optional branch per todo or run, merged with the
  fencing-token check; opt-in fast-forward of unclaimed repositories.
- **Messages between runtimes:** process state, questions, items needing
  attention, todo events, online / offline, lease events, `on_done` as a
  command.
- **User messages:** direct and group messages, and threads attached to a
  todo, a document or a review; Markdown text; read / unread per user;
  delivered live and on reconnect; stored by the service with a retention per
  group. **Encrypted between client and server** (not end to end). At rest
  the store is **not encrypted by default**; encryption at rest is an option,
  its key possibly held in Tom Secrets Manager.
- **Documents and attachments:** content-addressed blobs (SHA-256) stored by
  the service and referenced from messages, with a size limit per file, a
  quota per group and a **maximum lifetime**: tac is not a file server, a blob
  is gone after its TTL: default 7 days, maximum 30 days, set per message; a
  review round keeps its blobs until it is merged or its maximum is reached.
  **Longer processes** get a separate concept: their files stay available as
  long as the process prescribes (open: where they live, and how the process
  declares it). The GitHub backend keeps them as blobs in the
  coordination repository, the local backend in its folder. A review sends a
  document once and each returned copy as a new blob.
- **The Coordination page**, the agents' coordination tools, and the
  parallel-work guideline, its rules moving from "by agreement" to
  "enforced".
- **Relay:** TAC and MCP through the tac server mode, for machines off the
  VPN. A machine authenticates with a per-runtime key the group admin issues;
  the relay only forwards.

### 3.5 API packages and Flutter UI components

§ 7 and your notes k, l.

- **One API package per platform** for applications to use, built like the
  SOM runtimes in `tom_ai/ai_build` (`tom_som_<language>_runtime`):
  - **Dart:** `tom_ai/ai_build/tom_ai_runtime_client`, grown out of
    `tom_vscode_scripting_api` (the wire, the Tom feature APIs, the Agent SDK
    mirror);
  - **the other eight** (TypeScript, JavaScript, Python, Java, Go, Rust, C,
    C++): `tom_ai/ai_build/tom_ai_runtime_nondart/<language>/`; TypeScript
    starts from the runtime's own types and `TacClient`.
- **Made the same way in every language:** the protocol layer generated from
  the JSON schema, a convenience layer written by hand (start or find the
  installed runtime, connect, subscribe, walk a todo group, answer an ask),
  all checked by one conformance suite.
- **Tested thoroughly:** Dart and JS/TS; the others through the conformance
  suite.
- **Flutter UI components:** `tom_ai/ai_build/tom_ai_runtime_ui`, Dart only —
  chat, queue, todos, process, asks, MD documents — used by Webforge, Webwork
  and trc.

### 3.6 Tom Runtime Control (trc)

The supervision app ([ideas/remote_control_app](ideas/remote_control_app/remote_control_app.md)).

- **Full remote control** — more or less everything a runtime can do:
  queueing todos and walks, starting and pausing runs and queues, continuing
  processes (Proceed, Decide, gates), answering asks, reviewing documents in
  the MD Browser editor, the result going back to the process that sent it.
- **Focus on supervising a group**, not on local development work: one view
  of every runtime on every host — questions, decision-needed todos, queue
  state, runs, errors, claims, user messages.
- **Several users:** a user supervises their own runtimes, or a subset of a
  group's.
- **Built from the reusable components:** `tom_ai_runtime_client` and
  `tom_ai_runtime_ui`. What it adds is the overview.
- **A Webforge application from the start**, the "supervision" application
  beside Webwork, the quest application and the core forge application. It is
  planned for Webforge from the beginning, and **also runs standalone**
  outside Tom Forge, first and for testing; it may depend on `tom_forge`
  packages.
- **Reaches runtimes** through tac: the endpoints it publishes, and the relay
  off the VPN.

### 3.7 Repository quests and personal files

§ 10 and your note n.

- **Three kinds of folder in `_ai`:**
  - a **classic quest**: a folder in `tom_agent_state`, shared with everyone
    who shares that repository;
  - a **repository quest**: the quest folder is a clone of the quest's own
    repository, gitignored in `tom_agent_state`; it is personal or shared
    depending on who has access to its repository;
  - the **personal repository**: one per person, cloned at `_ai/personal/`,
    for the files that are only that person's, in a folder per quest,
    `_ai/personal/quests/<quest>/`. There are no personal quests for now.
- **Personal files**, all one person's or one machine's:
  - the session storage `history/sessions/<session>/`: live trail, history
    snapshot, compacted history;
  - session todos;
  - machine settings `extension_config.<host>.<quest>.yaml`;
  - the per-machine trail and compaction files (already untracked today);
  - **`personal-notes.<quest>.md`** (new): notes only for the current user.
    The VS Code extension gets a panel to view and edit them.
- **`quest-notes.<quest>.md` stays in the quest**: it is the user's, read by
  the agents of every member.
- **What a repository quest needs from the runtime:** merge drivers in
  TypeScript, member branches with conflict review, one shared process
  position moved only on `main`, a `<quest>_internal` repository for
  development credentials, a secret scan at commit and publish, member
  identity and access.
- **Three operations around a quest's repository:**
  - **create** — set up a new quest with its own repository from the start
    (and its `<quest>_internal`);
  - **join** — a second person, or the same person on another machine, starts
    working on an existing repository quest: clone it into
    `_ai/quests/<id>/`, set up their personal repository, register as a
    member;
  - **migrate** — turn an existing classic quest (its files in
    `tom_agent_state`) into a repository quest, keeping its history:
    `git filter-repo` copies the quest's folder with its commits into the new
    repository, and a dry run shows the result before anything is changed.

**What exists already:** none of it is built; the plan is.
- No quest folder under `_ai/quests/` is a repository, and `_ai/.gitignore`
  ignores no quest folder.
- No code in the extension or in `tom_ai/basics` / `modules` handles a quest
  repository. `tom_git` (`tom_ai/basics/tom_git`) is git in pure Dart (clone,
  commit, push without a git binary); it could carry repository quests in
  Webwork and on mobile, but has nothing quest-specific.
- The fleet's nested-repository pattern (`sibling_repos:` in
  `repo_structure.md`) is empty since `sysadm` was folded into al_the_bear.
- What exists is the plan:
  [vscode_extension/quest_repositories.md](../vscode_extension/quest_repositories.md)
  (QR-1 … QR-19, all answered) and the todos `ww_e_gitruntime-1` … `11`,
  which stay as they are and are updated for the personal repository.

### 3.8 Provider keys and model providers

§ 11.

- **Provider keys:** a configuration names a secret, never holds a key. The
  runtime resolves it, in this order of safety:
  - `tsm:<vault>/<entry>` — **Tom Secrets Manager** (`tom_secrets_clients`:
    the client libraries and `tsm`);
  - `os:<service>/<account>` — the OS secret store: macOS Keychain, Windows
    Credential Manager, Linux Secret Service;
  - `env:<variable>` and `file:<path>` — allowed, but not secure; meant for
    scripts and the Agent SDK's environment.
- **Providers**, built after the transports have moved into the runtime:

| Way in | Providers |
| --- | --- |
| Provider agent harness (agent transports) | Copilot SDK, Codex SDK, Gemini CLI, Mistral |
| Anthropic-compatible endpoint (base URL on `direct` / `agentSdk`) | DeepSeek, OpenRouter, other Anthropic-compatible providers |
| OpenAI-compatible endpoint (the Local LLM client grown) | Copilot direct calls, xAI, Meta / Llama, DeepSeek, Baidu, Mistral, OpenRouter, others |
| Evaluated behind the transport interface | `pi-ai`, `pi-coding-agent` |

Plus per-provider usage and cost, model catalogues and one conformance table
for every provider configuration.

## 4. Planning

### 4.1 Execution order

| Step | What | Where |
| --- | --- | --- |
| 1 | Finish the VS Code extension's features; create the new tom_specs process in parallel | vscode_extension |
| 2 | Workspace layout restructuring (`02_wslayout-*`, the al_the_bear restructuring) | vscode_extension, al_the_bear |
| 3 | Update [ai_runtime_project_idea.md](ai_runtime_project_idea.md) with steps 1 and 2 and this overview | ai_runtime |
| 4 | Run the specification through tom_specs, then implement it | ai_runtime |

### 4.2 Implementation stages and todo groups

| Order | Stage | Component | Todos |
| --- | --- | --- | --- |
| 1 | Runtime package, vscode-free modules, host interface, stores and managers, engines and transports, runtime tools and MCP server | tar | `ww_b_workbench-2` … `7` |
| 2 | Runtime server and protocol, the shared installation, two hosts on one quest, documents | tar | `ww_d_workbench-9` … `12` |
| 3 | Dart API package (`tom_ai_runtime_client`) | API packages | `ww_e_runtimeapi-1` … `6` |
| 4 | Coordination client and claims; messages, endpoints, Coordination page, GitHub backend, auto-update; branches, server, server backend; finish | tac | `ww_c_collab-3/4`, `ww_f_collab-1` … `5`, `ww_g_collab-1` … `3`, `-999` (to be replanned from the specification, RS-4) |
| 5 | `tom_d4rt_dcli` on `tom_todo_model` 2.2.0 | todo follow-ups | `ww_a_collab-2b` |
| 6 | Repository quests and the personal repository | repository quests | `ww_e_gitruntime-1` … `11` |
| 7 | Model providers and pi (after `ww_b_workbench-6`) | providers | `xx*`, `ccparity_h_pi-*` |
| 8 | trc through `idea_to_todos` | trc | `rca1` |
| — | Telegram, deferred | — | `ww_f_collab-6` |
| — | Live checks (yours) | — | `checks7`, `checks10`, `checks11` |

**Not yet in a todo group:** the tool split, the shared installation, user
messages and documents in tac, files for longer processes, the relay, the
eight other API packages, the Flutter UI components, provider keys, the
personal repository with `personal-notes` and its panel, moving
`tom_tac_service`. They come out of the specification.

**The existing todos still name the old places** (`tom_quest_runtime` in
`tom_ai/vscode/`, host transports, host tools, Telegram in the runtime). They
are rewritten when the specification replans them.

### 4.3 Other open decisions

From § 12 of the project idea, not covered above:

- **RS-1** stable build during the split (Work / Dev profiles recommended);
  **RS-4** replan the coordination todos from the specification
  (recommended); **RS-5** Phase 4 for a TypeScript runtime.
- The TAC service API in detail and the server mode (customers, keys, quotas,
  admin API).
- The first quest to migrate to a repository quest.
- `on_done` and the done notification across runtimes.

## 5. Decisions

| Id | Topic | Decision |
| --- | --- | --- |
| FO-1 | The runtime's place | `tom_ai/ai_build/tom_ai_runtime` |
| FO-2 | VS Code LM and Copilot chat transports | removed; Copilot only through direct calls and the Copilot SDK |
| FO-3 | Shared installation | per-user application data folder per OS, SDKs beside it |
| FO-4 | Updating it | versions side by side with a `current` pointer; running processes keep theirs |
| FO-5 | Streaming connection | length-prefixed JSON-RPC 2.0 over loopback TCP; WebSocket for remote clients |
| FO-6 | VS Code tools for agents in VS Code | yes, through the extension's MCP server registered with the runtime; the split concerns the `tomAi_*` tools (§ 3.3) |
| FO-7 | User messages in tac | direct, group and attached threads, stored with retention, encrypted client-to-server (not end to end) |
| FO-8 | Documents in tac | content-addressed blobs with size limit, quota and a maximum TTL; tac is not a file server |
| FO-9 | Relay | TAC and MCP through the tac server mode; per-runtime key; forwards only |
| FO-10 | Other API packages | protocol layer generated from the schema, convenience layer by hand, one conformance suite |
| FO-11 | Package places | `tom_ai_runtime_client` (Dart), `tom_ai_runtime_nondart/<language>/`, `tom_ai_runtime_ui`, all in `tom_ai/ai_build/` |
| FO-12 | trc | a Webforge application from the start that also runs standalone; may depend on `tom_forge` packages |
| FO-13 | Personal files | one personal repository per person at `_ai/personal/`; no personal quests for now |
| FO-15 | Provider keys | `tsm:`, then `os:`; `env:` and `file:` allowed as not-secure options |
| FO-16 | Telegram todo | stays here, deferred |
| FO-17 | File, command, web and git tools | runtime tools for the model transports, never over the runtime MCP server; hidden from agent transports with their own |
| FO-18 | Repository-quest support | the plan in `quest_repositories.md` and `ww_e_gitruntime-*`; the todos stay, updated for the personal repository |
| FO-19 | Where tac lives | `tom_ai/ai_build/tom_tac_service`; TAC clients for other languages in the API packages |
| FO-20 | User messages at rest | not encrypted by default; encryption at rest an option, key possibly from TSM |
| FO-21 | Document lifetime | default 7 days, maximum 30; a separate concept for files of longer processes |
| FO-22 | Personal files | the list in § 3.7, under `_ai/personal/quests/<quest>/`, plus `personal-notes.<quest>.md` with a panel in the extension; quest notes stay in the quest |

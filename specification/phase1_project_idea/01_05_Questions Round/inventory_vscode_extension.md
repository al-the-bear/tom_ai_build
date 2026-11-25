# Feature inventory of the VS Code extension: the v1 baseline of the Tom AI Runtime

Collected on 2026-11-25 for the questions round 01_05, after the product owner's request: "Please go
through the vscode_extension … quest to see their 'current state of todos, done and planned'. This
should be the basis of what to cover in a v1 version of the AI runtime, featurewise, but of course
in the AI runtime we have to do it across machines and potentially over the internet." He also
said he will copy the extension into the `ai_build` repository as a second (v2) extension that
works with the runtime, "with all features working as before (only distributed and with a team)",
and retire the old one later.

This document builds on `01_04_Questions Round/inputs_vscode_extension.md` (57 findings VX-1 …
VX-57, state of 2026-11-20). It does not repeat those findings; where one of them is the source of
a row, the row names it. Most of VX-1 … VX-57 are written into the Project Idea since (CR.47 …
CR.110, CP.36 … CP.44, CT.17, CV.16, CU.17); the mapping below cites the item, not the finding.

## 1. What was read, and the state

**State of the extension:** 2026-11-25 (the quest's files and the extension's documentation as of
that day; build line of `tom_vscode` around commit `4cc0f2d3`).

Read:

- The extension's user documentation, `tom_ai/vscode/tom_vscode_extension/doc/`: `user_guide.md`
  (all of it), `llm_tools.md` (§ 1 … § 9 and the tool list), `mcp_server.md` (§ 1 … § 4),
  `telegram_integration.md` (§ 2, § 6); headings and the parts needed of `README.md`,
  `anthropic_handler.md`, `anthropic_sdk_integration.md`, `llm_configuration.md`,
  `chat_enhancements.md`, `agent_sdk_scripting_mirror.md`, `workspace_setup.md`,
  `placeholder_engine.md`, `file_and_prompt_placeholders.md`, `chat_log_custom_editor.md`,
  `marktext_integration.md`, `copilot_chat_tools.md`, `extension_analysis.md`,
  `tomspecs_agent_workflow.md`, `md_browser_page_protocol.md`,
  `multi_transport_prompt_queue_revised.md`, `quick_reference.md`, `docspecs_linter_design.md`,
  `reading_notation_sample.md`, `information/vs_code_extension.md` (23 documents).
- `package.json` `contributes`: 85 commands, 7 view containers (5 activity-bar sidebars, 2 bottom
  panels), 21 views, 2 custom editors, 5 chat variables, 16 settings, 20 keybindings,
  JSON/YAML schema validation (summarised by area below, not command by command).
- The quest `_ai/quests/vscode_extension/`: `todos.vscode_extension.todo.yaml` (233 entries: 210
  not started, 11 groups, 8 blocked, 1 in progress, 1 decision-needed, 2 completed),
  `todos-archived.vscode_extension.todo.yaml` (622 completed, 2026-06-17 … 2026-11-25; listed with
  python, grouped by prefix; 102 completed since 2026-11-20), `todos-deleted…` (308; counted only),
  `overview.vscode_extension.md`, `short_description.vscode_extension.md`,
  `progress.vscode_extension.md` (entries 2026-11-19 … 2026-11-25), and the design documents
  `ideas/collab_and_features/collab_and_features_input.md` and the parts *Intent*, *Scope*,
  *Context*, *Resource leases* and *Documentation* of `collab_and_features.docspecs.md` (the 76
  `caf_*` todos filed on 2026-11-24), `deferred.vscode_extension.md` (headings),
  `tool_optimisation.vscode_extension.md` and `quest_repositories.md` (headings).
- The quest `al_the_bear`: its open todos whose title or description names the extension or the
  runtime (seven; the engine-relevant ones are the coordination repository and server and
  `caf_13a`).
- The Project Idea `project_idea.ai_runtime.md` (state 2026-11-25): `SCO`, `LAND`, `RT` (all of
  7.1 … 7.16), `CLI-UI` with the screen table, `DEL`, `D-40`, `D-41`, `N-24` … `N-34`, `R-1` …
  `R-5`, and the items of `TAC` and `PAR` named below; every "not covered" was checked by a
  case-insensitive search of the whole file (the search terms are in section 4).

Not read: the extension's source code (nothing was run, no behaviour was checked live; many of the
features have open live checks, `checks*` and `qr*` todos). The remaining parts of
`collab_and_features.docspecs.md` (supervisor, feature branches, coordination, reviews, issue flow)
were read through their todos only. Where a row rests on a todo's text alone, it says so.

Legend:

- **State:** *built* (in the installed extension), *partly built* (some of it built, the rest a
  named todo), *planned* (a todo exists, not started or blocked; the todo is named), *retiring*
  (being removed, with the todo).
- **Kind:** *engine* (belongs in the runtime; every host gets it), *host UI* (a view, editor or
  dialog that stays in a host, over the runtime's commands and events), *VS Code-only* (needs VS
  Code itself and stays in the extension).
- **Project Idea:** the items that cover the feature; *partly* where an item names it without the
  behaviour; *not covered* where nothing does (checked by search); *differs* where the item says
  something else.

## 2. The feature inventory

**Counts** (321 rows): built 251, partly built 4, planned 61, retiring 5. Engine 254 (rows that
are engine with a host dialog or view counted here), host UI 49, VS Code-only 18. Against the
Project Idea: covered 206, partly 39, differs 12, open (only in a question) 1, not covered 63.
By area: queue 44, todos 35, prompt assembly 25, review 24, processes 23, asks 23, sessions 21,
transports 18, quests 16, collaboration 16, other 15, workspace 13, tools 13, TomSpecs 13, timed
requests 7, memory 6, prerequisites 6, usage 3.

### 2.1 Quests and the `_ai` state

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-QST-1 | A quest is a folder `_ai/quests/<id>/` with fixed file types: overview, progress, quest notes, quest refresh notes, documentation update, deferred, questions, decisions, short description, todo files, process states, extension configs. | built | user guide § 2 *Documentation Panel*; overview | engine | CR.2, CR.47, CQ.11 |
| F-QST-2 | `short_description.<quest>.md` (title, 2–4 sentences, a state line) is required at setup, kept current by the quest refresh and served by `tomAi_listQuests`. | built | vscimpb145, questsetup1 | engine | CR.56 |
| F-QST-3 | Create a quest: id, name, purpose; the quest's files with headings; one setup todo that defines the quest in question rounds; offer to open the quest's workspace; agents run it with `{id, name, purpose, offerOpen}`. | built | user guide § 2 *Setting up*; vsc_setup-5 | engine (host dialog) | partly: CQ.7 *create* (written for the three quest types; the setup todo and the question rounds are not named) |
| F-QST-4 | A quest records the workspace folder it was opened through (`workspaceFolder` in its config); without a workspace list, a workspace's quests are those recorded for its folder. | built | user guide § 2 | engine | CR.33, CQ.10 |
| F-QST-5 | The active quest is the `.code-workspace` file name; `default` means no quest, and every quest view shows a "no quest is open" banner with Create quest and Setup workspace. | built | user guide § 2 | VS Code-only | CR.32 (the host passes the quest), CR.6 |
| F-QST-6 | The quest's overview opens once per machine in the MD Browser the first time a quest window opens. | built | vsc_setup-6 | host UI | not covered (host's own; needs only "open a document", CP.10) |
| F-QST-7 | The quest refresh: every N counted prompts the queue sends a refresh prompt (progress, overview, short description, refresh notes and decisions todo); process items do not count; *Run Quest Refresh* by hand. | built | vscimpb97, vscimpb145; user guide § 4 *Proceed* | engine | not covered (open question PQ-35) |
| F-QST-8 | The decisions journal `decisions.<quest>.md`: the decisions of a todo archived as completed are copied in; process moves (jumps, resets, follow-up switches, aborted levels, left-out steps) are recorded there too. | built | user guide § 2, *Processes* | engine | partly: CR.55 (only "a rendering of the decisions of its archived todos"; the process-move records are not named) |
| F-QST-9 | The questions journal `questions.<quest>.md`: every ask with its run and answer, and every message written to a waiting turn. | built | user guide § 2; vscimpb81, vscimpb173 | engine | CR.55 (planned per-host form), CR.72 |
| F-QST-10 | Format-version stamps of the `_ai` files (shared `_ai/format-version.yaml`, per-machine `_ai/local/format-version.<host>.yaml`); Tom AI does not start on older or newer files; the migration page with dry run and report, one migration at a time, the other windows pause every run and list what still runs with an interrupt. | built (version 10) | user guide § 2 *Upgrading the workspace*; vscimpb142, 142a … 142d | engine (host pages) | CR.3, CP.28, CP.29, SC-26 |
| F-QST-11 | Format version 11: one migration step moves every quest folder into the new layout (config/, notes/, memory/, journal, sessions per host). | planned (`01_aifmt-5_aktn-format-version-11`) | todo | engine | CR.3, CR.47, PQ-40 |
| F-QST-12 | The `_ai` merge drivers (`ai-trail`, `ai-history-json`, `ai-history-md`, `ai-block-history`, `ai-yaml-smart`) ship with the extension, run by VS Code's Node; registered per repository or globally with the rules in `_ai/.gitattributes`; an outdated registration is offered for update; a migration merges without git. | built | user guide § 2 *Merge drivers*; vscimpb142c | engine | E-5, CP.29, CQ.6 |
| F-QST-13 | The merge drivers are taken from `tom_binaries/merge_drivers/` instead of the extension's own source. | planned (`vscimpb152aaa_akqp-…`) | todo | engine | E-5 |
| F-QST-14 | The quest register `_ai/quests.yaml` with three quest types (folder, single-quest repository, multi-quest repository with a bare clone and a worktree per quest), the QUEST MANAGEMENT panel: new, add existing, pick and unpick, remove from the workspace or the machine, migrate folder quests, pull / push / status started by the user, set up this machine, check and fix. | planned (`02_aifmt-1_aktn-quest-management`) | todo | engine (host panel) | CR.100, CQ.1, CQ.7, CQ.9, CQ.12, CQ.13 |
| F-QST-15 | Saved prompts only per quest; quest notes as several files in `notes/` with a picker; workspace notes `_ai/workspaces/<workspace>.notes.md`. The readers of `_ai/notes`, the clarification folders and shared memory are removed already. | partly built (removal `00_aifmt-3`, done 2026-11-25; the rest `01_aifmt-3_aktn-quest-prompts-notes-memory`) | todos | engine | CR.53, CR.54, CQ.4 |
| F-QST-16 | The quest views follow a quest switch; quest documents (progress, overview, notes, refresh, doc update, deferred, questions, decisions) are shown read-only with a 7 s refresh and a 256 KB window. | built | user guide § 2 *Documentation Panel* | host UI | SC-24 (starting point for the logs; the rest host's own) |

### 2.2 Workspace layout, setup and AI workspaces

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-WSL-1 | The workspace layout resolver: the root (`.tom/tom_root.yaml`), the workspace folder, the `_ai` folder (by real path), the configuration layers, the guidelines on three levels, the `tomAi.layout.*` overrides, the nested cases. | built | E-4; user guide § 7 settings | engine | CR.32, CR.33, CR.99, CR.101 |
| F-WSL-2 | AI workspaces: `_ai/workspaces/<workspace>.yaml` lists a workspace's quests; the AI Workspace Quests editor; the workspace's quests come first in every quest picker; the workspace is named after the root folder the window opened. | built | vscimpb144; user guide § 2 | engine (host editor) | CR.33, CR.102 |
| F-WSL-3 | Setup New Workspace Folder: unpacks the workspace template the VSIX carries as a new root with a first workspace folder, a workspace folder in a root, or a standalone folder; per file Overwrite / Skip / All / Cancel; says what to adapt in the configuration; offers to register the merge drivers; opens the introduction quest. | built | vsc_setup-2 … -13; user guide § 2; `workspace_setup.md` | engine (host dialog) | not covered |
| F-WSL-4 | Every build packs the workspace template (root part with configuration, root guidelines, CLAUDE.md, AGENTS.md, `_ai` roles, processes, schemas, aspect guidelines and the `tomai_introduction` quest; workspace part). | built | vsc_setup-2, -7, -8 | engine (packaging) | not covered |
| F-WSL-5 | The repositories of `repos.yaml` (`tomAi_listRepositories`; `tomAi_getWorkspaceInfo` `include: ["repos"]`): path, kind, branch or pin, url, description, cloned on this machine, projects inside. | built | gsel12, 00_aifmt-2 | engine | CR.34, CR.102, CR.103 |
| F-WSL-6 | The project list from `buildkit :projects --all --json`, with a JavaScript port of the same rules as fallback; filters (under, language, type, name) and a compact form; used by todo scopes, prompt scopes, pickers and `tomAi_listProjects`. | built | vscimpb84, gsel13, gsel14 | engine | CT.10 |
| F-WSL-7 | The project listing also knows Scala and C / C++ with Meson, Bazel or Ceedling. | planned (`vscimpb169_akrl-project-listing-scala`) | todo | engine | CT.10 |
| F-WSL-8 | `tomAi_getWorkspaceInfo`: workspace name and file, folders, quest, git state, the build running and installed (reload needed), the Dart binaries, and on request projects, layout, workspace folders, quests, repos. | built | llm_tools § 10 | engine (host parts) | partly: CR.102, CP.27 |
| F-WSL-9 | Configuration in layers: built-in defaults, the root's `.tom/tom_vscode_extension.json`, the workspace folder's `.tom`, the quest's machine-independent and per-host `extension_config` files, VS Code settings; one key per write, owned by one store; schema checks and configuration errors on the Status Page. | built | user guide § 7; overview | engine | CS.1, CS.2 |
| F-WSL-10 | A layer-aware configuration editor: values per layer, writes into a chosen layer, the quest layer as a general overlay, the Status Page's configuration sections replaced by it. | planned (`13d_wslayout-1` … `-4`) | todos | engine (host editor) | CS.19 |
| F-WSL-11 | The old guidelines folder name `_copilot_guidelines` is dropped (both names are read today). | planned (`15a_wslayout-1_aksp-…`, blocked) | todo | engine | CR.33 (names only `_agent_guidelines`) |
| F-WSL-12 | Instruction files loaded as Claude Code loads them (every CLAUDE.md, imports) for the transports that are not the Agent SDK; `@<path>` lines import files in prompt resolution. | built | ccparity_d_claudecode-4, gsel18 | engine | CR.5, CR.59 |
| F-WSL-13 | Short descriptions and `tomAi_listQuests` name the repositories a quest works on. | planned (`vscimpb154_akqj-…`) | todo | engine | CR.102, CR.35 |

### 2.3 Todos

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-TOD-1 | Quest todo files `*.todo.yaml` (the quest's own file and topic files), checked against the todo schema, read and written through `tom_todo_model`. | built | user guide § 2 *Quest TODO Panel*; llm_tools § 4.11 | engine | CR.2, CR.48, PQ-34 |
| F-TOD-2 | The todo record: status (not-started, in-progress, blocked, decision-needed, waiting-for-repeat, group, completed, cancelled), priority, tags, scope, references as objects, dependencies, blocked_by, notes, dates. | built | llm_tools § 4.11 | engine | CR.48 |
| F-TOD-3 | Decisions on a todo (summary, decision needed, decision) with the status decision-needed; a todo whose decisions all have an answer is set to not-started. | built | user guide *Decisions* | engine | CR.48, CR.80 |
| F-TOD-4 | `user_action: true`: a todo only the user can do; a walk passes it; it is shown in purple, filterable, with *Guide me* buttons. | built | user guide *Your own todos* | engine | CR.48 |
| F-TOD-5 | Prefix groups: all todos of an id prefix, in natural order of the prefix, a finalizer numbered 999 or higher stays last, an *Unprefixed* group. | built | user guide *Prefix groups* | engine | CR.49 |
| F-TOD-6 | Group todos: status `group`, members in `comprised_of` (also of other quests), `part_of` derived, completed by itself when every member is done, back to `group` when one reopens. | built | vscimpb125, vscimpb126 | engine | CR.49 |
| F-TOD-7 | Blocked todos follow their blockers: on every status change by any writer, every todo of every quest naming it is released or blocked again, with a line in its notes; a done blocker leaves the `blocked_by` lists; `blocking` is derived. | built | vscimpb121 | engine | CR.48, CW.21 |
| F-TOD-8 | `blocked_until`: a release condition `<package> >= <x.y.z>` read from pub.dev. | built | finishvsc2; user guide *Todos that block others* | engine | CW.12, CW.21 |
| F-TOD-9 | *Clean up the todo dependencies*: one pass over the shown todos, the open windows' quests or all quests; removes done and vanished blockers, unblocks, sets `blocking` right, reports counts. | built | user guide *Todos that block others* | engine (host command) | partly: CW.21 (the rule, not the repair command) |
| F-TOD-10 | After done (`on_done`): unblock targets, notify filed-by, instructions to a quest and run, a notify prompt, *report to*; carried out on completion (in a walk once the answer is written, for a group with its last member, for a repeated todo every time); `filed_by` written from the caller's context. | built | ww_a_collab-2, -5; user guide *After done and Filed by* | engine | CR.21, CR.48, CA.21 |
| F-TOD-11 | The todo done notification: the todo's notify prompt, else a template only when the panel that queued it had its box on; sent to the run and session that queued the todo, else nothing; placeholders filled from the completed todo. | built | vscimpb146 | engine | CR.93, CR.94, CW.23 |
| F-TOD-12 | `last_answer` (the answer of the walk that completed the todo) and *Agent answer* (the newest answer in the quest's session trails that reported the todo with `TODO=<ref>`). | built | user guide *Todo iteration* | engine | partly: CR.48 (the answer of the execution; reading the trails for `TODO=<ref>` is not named) |
| F-TOD-13 | Repeated todos: repeat rules (by hand, after N, daily, weekly, monthly, yearly, nth weekday, working days, until, count), status waiting-for-repeat, *Repeat now*. | built | vscimpb34 | engine | CR.50 |
| F-TOD-14 | Due date with an overdue state and one reminder (09:00 or `todoPanel.dueReminderTime`), through the quest's Telegram else a VS Code message; recorded so it rings once across windows and hosts. | built | vscimpb152aa | engine | CR.50 |
| F-TOD-15 | Remind schedules and one-shot reminders (at a time, or before the due date); one message per todo and check; missed moments ring once; recorded before sending. | built | vscimpb152ab | engine | CR.50 |
| F-TOD-16 | A repeated todo's next occurrence gets its due date and reminders back; Snooze on a reminder notification. | planned (`wwremind2_akwq-…`, `wwremind3_akwq-…`) | todos | engine | not covered (CR.50 names neither) |
| F-TOD-17 | A todo names its role and guideline choices. | built | gsel1, gsel3 | engine | CR.95 |
| F-TOD-18 | A todo names its profile and chat variables set while it runs (with a flag to unset them), and the standard todo chat variable holds the todo's quest and id while it runs. | planned (`vscimpb174_akrr-todo-profile`, decisions open) | todo | engine | CR.22, CR.97 |
| F-TOD-19 | Rename a todo or a whole prefix: references follow in every quest; a committed old id keeps a cancelled stub; renumbering into another group keeps the finalizer rule. | built | user guide *Moving todos*; `tomAi_renameQuestTodo`, `tomAi_renameTodoPrefix` | engine | CR.51 |
| F-TOD-20 | Archive (completed only, into the `-archived` sibling) and delete (into the `-deleted` sibling, recoverable); terminal sibling files; *Restore*; archiving copies the decisions into the journal. | built | tra1 … tra3; user guide *Moving todos* | engine | partly: CR.55 (the journal); the archive and delete rules are not stated |
| F-TOD-21 | Move todos between files, groups, quests and the workspace file, with renumbering into another quest's group (`tomAi_moveQuestTodo`, `tomAi_transferTodos`). | built | user guide *Moving todos* | engine | not covered (CW.25 covers creating a todo in another quest only) |
| F-TOD-22 | Workspace todos in `workspace.todo.yaml` (view and tools). | built | user guide § 2; settings `tomAi.todo.workspaceTodoFile` | engine | partly: SC-9 (the view); the store is not in CR.2 |
| F-TOD-23 | Session todos: per session, machine-local, deleted with the session; the agent's steps inside one quest todo. | built | user guide *Session todos* | engine | CQ.3, SC-9 |
| F-TOD-24 | Ids from a date code (`tomAi_generateIdPrefix`), checked against the schema's id pattern; a reused id stem is warned about. | built | llm_tools § 4.11a | engine | not covered |
| F-TOD-25 | The todo panel in three places plus the `*.todo.yaml` custom editor: quest scopes (workspace quests, open windows' quests, all, one), live / archived / deleted toggles, order, quest prefix, search, filters (status, user action, blocking, overdue, date ranges), sort, expand and collapse, group headers with progress and open-decision counts. | built | user guide *Quest TODO Panel*; vscimpb137, vscimpb138 | host UI | SC-9, SC-10, CU.6 *Todos* |
| F-TOD-26 | The queued marker ⏵#N on a todo (with the run's name), following the queue live. | built | user guide *Queued todos* | host UI | not covered (needs the queue events of CP.4) |
| F-TOD-27 | The todo stack: pick todos, *Save to Queue* one item each, or *Send* one combined prompt with numbered `REQUIRED: Add responseValue #TODO_<n>=…` lines. | built | trb3; user guide *Todo stack* | host UI | not covered |
| F-TOD-28 | Every send of a todo carries its complete YAML record. | built | dapieff8, dapieff9 | engine | CR.65 |
| F-TOD-29 | Send, Queue, Queue as todo item, Queue as group, Guide me; *Next* and *Fresh* toggles; the target picker (quest with an open window, run with its state, a free session, *Last: …*); items for another quest through its inbox; repeats within 3 s ignored. | built | user guide *Where a todo is queued and sent* | host UI (engine target rules) | CR.16, CR.68, CR.77, CW.20, CU.6 *Todos* |
| F-TOD-30 | After *Guide me* ends with the todo open, a question offers Mark completed, Mark in progress, Queue it, Leave it; the user's words go into the todo's notes. | built | user guide *Guide me* | host UI | not covered |
| F-TOD-31 | TODO LOG view (the log of todo changes). | built | package.json views | host UI | SC-11 |
| F-TOD-32 | Todo panel: *Do next* inside a group, *Sort groups by stem*, selection keyed by quest and id. | planned (`vscimpb159_akqk-…`, `vscimpb175_akru-…`, `vscimpb177_aksm-…`) | todos | host UI | SC-9 |
| F-TOD-33 | Todo analyzer: the selection's dependency closure across quests and the queued items of every window; views DEPENDENCIES (graph) and WORK ORDER (lanes with dependency lines and an unqueued lane). | planned (`todoanalyzer1` … `4`) | todos | engine (model) and host UI | not covered |
| F-TOD-34 | Todo model fields for features and leases: `featureId`, `featurePhases`, `partOfFeature`, `useFeatureBranch`, `leasesAlways`, `review`, `workAnalysis`, and resources in the notation `<type>://<server>[:<port>]/<path>` (`git://…`, `git-release://…`, `named://…`). | planned (`caf_01a` … `caf_01d`) | todos; collab_and_features *part-todo-model* | engine | differs: CW.7, CA.9, CA.10 (resource names `git:<owner>/<repository>#<pattern>`, one prefix `git:`); the feature fields are not covered |
| F-TOD-35 | The consumers of `tom_todo_model` move to 6.0.0. | planned (`vscimpb180_akwt-…`) | todo | engine | PQ-34 |

### 2.4 Processes and runs

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-PRC-1 | Process definitions in `_ai/processes/<id>/` (`<id>.process.yaml`, `<id>.md`): phases, steps, sub-steps, a gate ending every phase, post-gate todos with a prefix, roles, repeatable levels with a maximum, prompts, sessions, documents. | built | user guide *Processes* | engine | CR.10 |
| F-PRC-2 | The process editor: every field, descriptions, sessions through the session picker, documents, subprocess and branch lists with inputs, inputs and outputs, decision steps, *Followed by*, run parameters, live validation; Up / Down ordering. | built | user guide *Processes* | host UI | SC-7 |
| F-PRC-3 | `tomAi_validateProcess` and `tomAi_writeProcess` (an existing process only with `replace`, keeping the file's formatting). | built | ccparity_j_ideaprocess-1, vscimpb92 | engine | CR.11 |
| F-PRC-4 | The PROCESS view: position as dropdowns with iterations, the action bar (Proceed, Decide…, Skip, Back, back to the start of the current or previous phase, Leave out, Confirm done, Start subprocess or branch, Abort), the Runs list, the Flow box, Jumps, Left out. | built | user guide *Processes* | host UI | SC-6, CU.6 *Runs and processes*, CP.3 |
| F-PRC-5 | Proceed: the action page (session, custom instructions, preview) queues the position's prompt and a **process-move marker**; the state moves when the queue reaches the marker with the step's items done; a failed item holds the marker (Repeat the step, Move on). | built | cc_parity_a_start-15; user guide *Processes* | engine | partly: CP.3 (proceed); the marker as a queue pseudo-item is not named |
| F-PRC-6 | Decision points after gates, phase ends and repeatable levels; the Decide dialog (go on, repeat, gate passed / failed with `onFail`, finish, reopen). | built | user guide *Processes* | engine | CR.10 |
| F-PRC-7 | Decision steps (auto, user, judge with `tomAi_setProcessState {decide, reason}`), jumps recorded (at most 50). | built | vscimpb95 | engine | CR.10 |
| F-PRC-8 | Non-linear processes: `next:` with conditions, joins, ends of their own, goto steps; the path taken. | built | vscimpb96 | engine | CR.10 |
| F-PRC-9 | Optional and conditional phases and steps (`when: {var…}` decided by the engine, `when: {judge…}` by the agent with `leaveOut`, `optional: true` by the user), recorded with the reason. | built | vscimpb36 | engine | CR.10 |
| F-PRC-10 | Follow-up processes with `carry` and a call context (`${origin.<name>}`), the chain shown. | built | vscimpb47 | engine | CR.10 |
| F-PRC-11 | Nested processes: subprocesses (hand outputs back) and branches on a process stack, inputs and outputs, a depth limit (default 5) that asks, Abort; the agent suggests subprocesses (`tomAi_suggestSubprocess`), shown after the step's items are done in the process branching editor. | built | ccparity_e_process-5 … -8 | engine (host editor) | CR.10, CR.11 |
| F-PRC-12 | User-action steps confirmed by the user; review steps name their documents (placeholders); *Finish review round* from the document; a gate's result shown with the decision's buttons. | built | vscimpb64, vscimpb85, vscimpb89, ccparity_i_assist-5 | engine | CR.10, CP.8 |
| F-PRC-13 | The Proceed prompt template (process template editor) with action variables and the *Work you queue* section (role and guidelines for queued work). | built | gsel8; user guide *Process template editor* | engine (template store) | partly: SC-7 (the editor); the template is not an engine item |
| F-PRC-14 | The process context in the system prompt (`${process-context}`) and the process chat variables. | built | user guide *In the system prompt* | engine | partly: CR.5 (prompt assembly), CR.63 |
| F-PRC-15 | Process state per quest and run in `process-state.<quest>.<run>.yaml` (stack of levels, jumps, skipped, `phasePath`, `phaseIterations`), the same on every machine. | built | user guide *State per quest* | engine | CR.8, CR.47 |
| F-PRC-16 | Runs: create, select, delete (tools and the Runs list), the run's subject (`process-subject`), `default` runs no process, run parameters as the run's chat variables, the run's sessions `<session>@<run>`, a deleted run's queue tab kept until removed. | built | user guide *Runs*; vscimpb118, vscimpb122 | engine | CR.8, CR.9, CR.62, CR.63 |
| F-PRC-17 | Reset Run and Reset Process (`tomAi_resetProcess`), written to the decisions journal. | built | vscimpb91 | engine | CR.9 |
| F-PRC-18 | A new run's subject is preset with the run's name. | planned (`vscimpb156_akqk-…`) | todo | engine | CR.63 |
| F-PRC-19 | A step's `documents:` taken from a chat variable that holds several paths. | planned (`vscimpb163_akqn-…`) | todo | engine | not covered |
| F-PRC-20 | Grill me and Explain a decision at a process decision: an assist prompt in a temporary session based on the process's session, a note in the quest's process folder, the decision's choices as buttons in the MD Browser. | built | ccparity_i_assist-7 | engine (host dialog) | partly: CP.38 (assist actions on document questions; decisions not named) |
| F-PRC-21 | The processes shipped in the workspace template (`tom_specs`, `idea_to_todos`, `process_design`). | built | ccparity_j_ideaprocess-2, -3 | engine (content) | CR.14 (which processes exist is not the runtime's matter) |
| F-PRC-22 | Standard runs `planning` and `quest-keeper` in every quest (reserved names, never deleted), hidden runs with show / hide buttons. | planned (`caf_03b`, `caf_03c`) | todos | engine | not covered |
| F-PRC-23 | Every run is its own lane: the "Queue per run" setting is removed. | planned (`caf_03a`) | todo | engine | CR.67 (already the rule) |

### 2.5 The prompt queue and its item kinds

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-QUE-1 | One lane per run: one item per lane at a time, lanes in parallel, a lane whose next item cannot start waits and its later items do not jump ahead; a held item keeps its run waiting. | built | vscimpb46; progress 2026-11-25 | engine | CR.67 |
| F-QUE-2 | Item kinds: todo, group, prefix, iteration, chat, prompt (written into the entry, shown as one label with the status). | built | vscimpb127 … 129 | engine | CR.64 |
| F-QUE-3 | Item states: staged, pending, sending, sent, error, decision-needed, todo-blocked, interrupted, and the marks of a sending item. | built | user guide § 4 *Queue Editor* | engine | CR.69 |
| F-QUE-4 | Rate-limit and quota handling in the queue: a rate-limited item parked in a timed waiting state (`WAITING … FOR`), retries counted (`RETRYING 2/7 — NEXT …`), *Retry now*, *Retry all errors* (switching the runs' auto-send on for the cascade), the health check resumes an item whose window elapsed. | built | trb4, ccparity_a_directapi-2, vbs4 | engine | partly: CR.27 (one retry layer); CR.69 lists none of these states |
| F-QUE-5 | Pre-prompts and follow-ups, each with its own template, transport, repeat count and wait. | built | user guide § 4 *Queue Entry Fields* | engine | CR.15 |
| F-QUE-6 | Repeat count as a number, a chat-variable name resolved at dispatch, or `prefix*`; repeat prefix and suffix with `${repeatNumber}`, `${repeatIndex}`, `${repeatCount}`; template repeat count. | built | user guide *Repeat and Affix Support* | engine | CR.19 |
| F-QUE-7 | The todo walk (`prefix*`): lowest number first, claiming, passes completed, cancelled and the user's todos, holds at an open decision or a blocked todo (never earlier), runs stale in-progress todos, appends the record, `${repeatTodoId}` placeholders; a walk with nothing to do goes to error at once. | built | user guide *Todo iteration* | engine | CR.19, CR.65, CR.80, CR.81 |
| F-QUE-8 | The walk checks each todo and continues up to `walkContinuations` times (default 2), then *needs attention*. | built | vscimpb58 | engine | CR.82 |
| F-QUE-9 | TODO and GROUP items; a GROUP item's member list with checkboxes (`group-selection`), set by agents with `groupSelection`; a `prefix*` walk lists its todos the same way. | built | vscimpb127 … 129; progress 2026-11-24 | engine | CR.65, CR.66 |
| F-QUE-10 | A held item goes on by itself when its blocker is completed or its decisions are answered (todo files watched); the run its hold paused resumes; `auto-resume-held` per run. | built (2026-11-25) | vscimpb179 | engine | CR.83 (still says "planned"), D-45 |
| F-QUE-11 | Queueing a group whose members wait for todos that do not run first asks *Queue anyway* (the panel; the tools do not ask). | built | user guide *Todo iteration* | host UI | not covered |
| F-QUE-12 | A todo is queued once (`allowDuplicateTodo`, *Queue again*). | built | vscimpb77 | engine | CR.68 |
| F-QUE-13 | Queue settings per quest and run (auto-send, auto-start, auto-pause, auto-continue, the defaults transport, profile, session, template, default role, guideline choices; walk continuations) in one machine-wide file; a writer writes only the runs it changed. | built | vscimpb60a, gsel3 | engine | CR.70, CR.36 |
| F-QUE-14 | *Make default* (a run's settings become the start values of new runs), *Apply run defaults to all items*, *Move items to another run*, and *Run default* as an item's choice (taken when it is sent). | built (2026-11-23 … 24) | progress 2026-11-23, 2026-11-24 | engine | not covered |
| F-QUE-15 | Send now (also re-runs a sent item from its first prompt), Send all staged, Clear sent, Clear all, Delete errors, Restart Queue, Stop. | built | user guide § 4 *Queue Editor* | engine | partly: CP.3, CR.74 |
| F-QUE-16 | The status of any item set by hand (pending, staged, sent), and moving any item that is not sent (run → session → place: end, top, next between iterations), a running one stopped first. | built (2026-11-25) | progress 2026-11-24/25 | engine | partly: CR.74 (commands on an executing item); moving between runs is not covered |
| F-QUE-17 | Three ways in: at the end, next, as an update to the running prompt; *Send between iterations*; *Let the next item go first*; *Pause after this* (moved to the done notification when there is one). | built | user guide § 4 | engine | CR.16, CR.73 |
| F-QUE-18 | A pending item being edited is not sent until saved. | built | user guide *Editing a pending item* | engine | CR.16 |
| F-QUE-19 | Waiting for a session: a pending item waits while a chat send runs in its session. | built | vscimpb135 | engine | CR.15, PQ-39 |
| F-QUE-20 | The declared wait `tomAi_waitFor` (at most 48 h, survives a reload, *Interrupt the wait and move on*). | built | vscimpb82 | engine | CR.85, CP.43 |
| F-QUE-21 | Waiting for the item's own background work (alive by process, limit per item / profile / 6 h, three choices), detaching commands refused on the Agent SDK, one reminder prompt. | built | vscimpb56, 57, 143 | engine | CR.86, CR.87, CR.88 |
| F-QUE-22 | Messages into a waiting or running turn (Message box; the Agent SDK's streaming input; each kept with what became of it and journaled). | built | vscimpb173 | engine | CR.72 |
| F-QUE-23 | Continue on a running item always asks (Answer now, Type an answer, Resend this stage, Skip, Keep waiting); ↻ resends the stage. | built | vscimpb55 | engine (host dialog) | CR.74 |
| F-QUE-24 | Interrupt for continuation: soft first, no-limit wait, hard interrupt, Cancel interruption, held across a reload; the run tab shows it. | built | vscimpb112 | engine | CR.89, CR.90, CR.91 |
| F-QUE-25 | Out of budget: the item stops with its run, *Continue on profile* (the out-of-budget assist prompt), automatic switch per profile, Resend; `tomAi_resendQueueItem {profileId}`. | built | ccparity_e_process-10 | engine | CR.92, CS.14 |
| F-QUE-26 | The done notification of an item: queued ahead, once per run of the item, on finish or final error, posted to another run or quest, placeholders with outcome, answer, title, todos, sender. | built | vscimpb71, 72 | engine | CR.93 |
| F-QUE-27 | Every item records who queued it (`queuedBy`: quest, run, session). | built | vscimpb146 | engine | CR.94 |
| F-QUE-28 | Items from other quests (`tomAi_sendItemToQuest`, also over MCP): the target's inbox, its own defaults unless named, temporary sessions, a done notification back to the sender, a walk in a named run, never creates a run, waits in the inbox without a window. | built | ww_a_collab-4 | engine | CW.19, CW.20 |
| F-QUE-29 | Process items (`processItem: true`) do not count towards the quest refresh. | built | vscimpb97 | engine | not covered (PQ-35) |
| F-QUE-30 | The prompt after a reload: stored on the Status Page per quest, queued at the front of the window's run when a window starts and sent like Continue, also while paused. | built | vscimpb109 | engine | not covered (PQ-35) |
| F-QUE-31 | Queue storage: one YAML file per entry in `_ai/queue/`, named `<host>_<workspace>_<time>-<token>_<quest>.<type>.entry.queue.yaml`, synchronised between windows by watchers; settings in `queue-settings.yaml`. | built | user guide *Queue Storage* | engine | partly: CR.36 (settings); where queue entries live is not stated (CR.106 keeps machine-wide state out of `_ai`) |
| F-QUE-32 | The watchdog (every 60 s: watcher, stalled pending items) and 30 s polling. | built | user guide *Watchdog and Health Check* | engine | not covered |
| F-QUE-33 | A chat send that gets no result within the queue's response timeout (default 60 min) is stopped. | built | user guide *Chat sends* | engine | not covered |
| F-QUE-34 | Chat sends shown as queue items (SENDING CHAT, SENT CHAT) outside the lanes, one busy slot per session; a send into a busy session offers update, run next, after the current item, or a free session. | built | vscimpb132, vscimpb135 | engine | differs: CR.15, CR.67 (chat is a queue item in the run's order); open: PQ-39 |
| F-QUE-35 | Control queue items: start, pause, interrupt, resume runs in this or other windows, interrupt all and silence the workspace for a reconcile, notify the user (also by Telegram). | planned (`vscimpb187_akyb-…`, decisions open) | todo | engine | partly: CW.13 ("a runtime can be asked to pause its queue after its current item") |
| F-QUE-36 | Further control items: wait for a todo, wait for a run, a barrier between runs, set a variable and more. | planned (`vscimpb188_akyb-…`, decision open) | todo | engine | not covered |
| F-QUE-37 | Wait for notifications and Notify pseudo-items with a notification store (a wait finds notifications sent before it). | planned (`caf_07c`) | todo | engine | not covered |
| F-QUE-38 | The queue-position rule (an item queued by a running item goes right after it, before the process-move marker); warnings on manual queuing into a `planning` or feature run, `confirm: true` on the queue tools. | planned (`caf_03d`, `caf_03e`) | todos | engine | not covered |
| F-QUE-39 | Queue templates (the queue-template editor). | built | package.json `tomAi.editor.queueTemplates` | engine (template store) | SC-4 |
| F-QUE-40 | The Prompt Queue editor: run tabs with state and counts, two context bars, icon toolbar, item cards with status-and-kind label, chips (run, session, role with its origin, profile, todos), live-trail button, the *From the chat panel only* filter, collapse, per-tab scroll. | built | user guide § 4 *Queue Editor* | host UI | SC-4, CU.6 *Queue*, CU.17 |
| F-QUE-41 | Queue place end / top / next as one icon set everywhere; the todo panel's toggle as a three-state switch. | planned (`vscimpb181_akwu-…`) | todo | host UI | not covered |
| F-QUE-42 | Copilot items: answer-file detection with request ids, answer-wait minutes, the Copilot Queue Wrapper. | retiring (`01_aifmt-1_aktn-copilot-removal`, in progress) | todo; user guide *Answer Detection* | VS Code-only | O-4, CS.13 |
| F-QUE-43 | Queue reminders: the alive check, reminder templates, reminder fields and tools. | retiring (`01_aifmt-1`) | todo | engine | CR.19 (the queue sends no reminders) |
| F-QUE-44 | The queue tools (`tomAi_addQueueItem` with todo, group, session spec, role, guidelines, done notification, run, position; update, remove, pre-prompts, follow-ups, send, resend, set status, list with members and run settings). | built | llm_tools § 4.20, § 10 | engine | CT.1, CP.3 |

### 2.6 Timed requests and reminders

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-TIM-1 | Timed requests: interval or scheduled (daily times, one-shot dates), engine switch and entry switch, send maximum with auto-pause, repeat and affixes, a template, skipped while the entry has a pending item, enqueued through the queue. | built | user guide § 5; vscimpb24 | engine | CR.84 |
| F-TIM-2 | Global schedule slots: weekdays, a time-of-day window, months. | built | user guide *Global Schedule Slots* | engine | not covered |
| F-TIM-3 | The tick (30 s, `tomAi.timedRequests.tickInterval`) is the clock of repeated todos and todo reminders (the *Repeated todos* entry). | built | user guide § 5, *Repeated todos* | engine | CR.84, CR.50 |
| F-TIM-4 | Timed-request tools (add, update, remove, list, engine state). | built | llm_tools § 4.20 | engine | CT.1 |
| F-TIM-5 | The Timed Requests editor. | built | package.json | host UI | SC-5 |
| F-TIM-6 | The answer-wrapper and reminder fields of a timed request. | retiring (`01_aifmt-1`) | todo | VS Code-only | O-4, CR.19 |
| F-TIM-7 | Reminders of a todo (due, remind, reminders) ring through the user notification on the timed-request tick. | built | vscimpb152aa, 152ab | engine | CR.50 |

### 2.7 Sessions, history and trails

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-SES-1 | Named sessions (`<name>.session.json`): `chat` for the panel, `default@<run>` per run, `default@default`, any number of named sessions. | built | user guide *Named sessions*; qrun1, vscimpb151 | engine | CR.62, CR.75 |
| F-SES-2 | A session's base, lifetime (continue, per prompt, per iteration), profile and model. | built | vas1 … vas3 | engine | CR.75 |
| F-SES-3 | Temporary sessions (a sent item's unnamed new session, the *Fresh* toggle, the assist prompts' `tmp-…`), removed when done. | built | user guide *Fresh*, *Items from other quests* | engine | CR.77 |
| F-SES-4 | Reset (conversation forgotten, definition kept), Delete with its storage and memory, *Remove unused sessions* by stated rules. | built | qri1; user guide *SESSIONS view* | engine | CR.18, CR.78 |
| F-SES-5 | An item whose profile cannot continue its session's conversation is refused when queued; changing an item's profile asks to use the default session. | built | user guide *Named sessions*, *Profile* | engine | CR.76 |
| F-SES-6 | A session named by an item is created at its first dispatch from the item's spec (name, base, lifetime, profile). | built | user guide *Named sessions* | engine | partly: CR.75 |
| F-SES-7 | A session whose Agent SDK conversation is not on this machine ("No conversation found") forgets the id and is sent again in a new conversation, once, with a note in the live trail. | built | user guide *A session Claude Code no longer has* | engine | not covered |
| F-SES-8 | Direct-API history per session (compacted history, raw turns, compaction rounds), copied from the base once, reset per prompt or per iteration by lifetime. | built | user guide *direct API transport* | engine | CR.27, CR.75 |
| F-SES-9 | The live trail per session (last 5 prompt blocks, streamed thinking, tool calls and results, the role in each prompt header). | built | user guide § 9; gsel11 | engine | CR.24, CU.8 |
| F-SES-10 | The summary trail pair per session, trimmed to `trail.compact.maxEntries` (2000) by every writer. | built | 00_aifmt-1 | engine | CR.24, CR.47 |
| F-SES-11 | The raw trail (prompt, payload, answer, tool request and answer files; compaction and memory passes) with a maximum per folder. | built | user guide § 9; 00_aifmt-4 | engine | CR.24 |
| F-SES-12 | The current-prompt record per session (literal, user and system prompt, for chat and queue), not versioned. | built | user guide *Current Prompt sub-tab* | engine | not covered (CT.7 names only the tool set of a prompt) |
| F-SES-13 | Stored tool results (`tool_results/t<n>.json`, replay keys) with retention (keep days, at most per session) and the past-tool tools (`tomAi_listPastToolCalls`, `tomAi_searchPastToolResults`, `tomAi_readPastToolResult` with paging). | built | dapieff1; user guide § 9 *Retention* | engine | not covered |
| F-SES-14 | Recreate history and memory from a session's trail; compaction dry run; migrate the compaction format. | built | user guide § 9 | engine | not covered |
| F-SES-15 | History compaction `trim_and_summary` (template, model, budget). | built | llm_configuration § 3, § 7 | engine | CR.27, CR.70 |
| F-SES-16 | Sessions and the compact trail per host in the quest (`history/<host>/…`, `history/trail.<host>.md`), the session setting "contributes to trail and memory", history derived and untracked, rebuild and promote buttons. | planned (`01_aifmt-4_aktn-per-host-trail-qa-history`) | todo | engine | CR.79, CR.47; differs: CQ.3 (personal repository); open: PQ-53 |
| F-SES-17 | The Logs section (session switch, MD trail, trail source, prompts, answers, current prompt) and the trail viewers (raw trail viewer, summary trail custom editor). | built | user guide *Logs Panel* | host UI | SC-12, SC-24 |
| F-SES-18 | Prompt and answer pairs across sessions and subsystems (`tomAi_listPromptPairs`, `tomAi_getPromptPair`). | built | llm_tools § 10 | engine | partly: CR.24 ("every prompt can be addressed in the trail") |
| F-SES-19 | Two prompts never share a session, in this window or another of the quest. | built | user guide *Two prompts never share a session* | engine | CR.15 |
| F-SES-20 | The SESSIONS view (base, lifetime, profile, model, conversation, last used, session todo counts). | built | vas5 | host UI | SC-14 |
| F-SES-21 | Tool calls are attributed to the calling session when several Agent SDK sessions of one window run at once (today they can take another session's context: `filed_by`, claims). | planned (`qr5_akxd-tool-call-context-other-session`) | todo | engine | not covered |

### 2.8 Transports and model providers

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-TRN-1 | Profiles: model, transport, history mode, user-message template, tools, tool approval, effort, thinking, core tools, out-of-budget continuation; edited in the template editor. | built | user guide *Anthropic*; anthropic_handler § 3 | engine | GLO *profile*, CS.3, CS.14 |
| F-TRN-2 | Direct API transport: prompt caching, one retry layer, continuation after a dropped connection, effort and adaptive thinking. | built | ccparity_a_directapi-1, -2; ccparity_c_transports-5, -8; cc_parity_a_start-5 | engine | CR.27 |
| F-TRN-3 | Tool search on the direct transport: a core set sent in full, the rest deferred (server-side BM25 tool search), tools named by a prompt's `<!-- tools: … -->` line; on Local LLM and VS Code LM the directive sets the list. | built | dapieff7; llm_tools § 5.0 | engine | not covered |
| F-TRN-4 | Server-side clearing of old tool results on the direct transport. | built | dapieff5 | engine | not covered |
| F-TRN-5 | Images and PDFs returned by `tomAi_readFile` as content blocks to the direct API. | built | ccparity_c_transports-10 | engine | not covered |
| F-TRN-6 | Tool approval modes: *Always* (writers ask), *Accept edits*, *Allow all (session)* per tool; readers never ask; queued prompts never ask; the approval bar. | built | ccparity_c_transports-2, -6; llm_tools § 5.1 | engine (host bar) | partly: CR.25 ("approvals"), CP.8 (tool approval as an ask) |
| F-TRN-7 | Agent SDK transport: history in the extension (T&S) or SDK-managed (SDK-MM), Claude Code's built-ins optional with duplicates suppressed, writers through approval, the SDK's plan mode, thinking budget, system prompt appended or replaced, the in-process MCP server, its question tool, streaming input for updates. | built | ccparity_c_transports-1, -2; ccparity_d_claudecode-5; anthropic_handler § 2b | engine | CR.25, CT.3, CR.58, CR.72 |
| F-TRN-8 | Local LLM (Ollama, OpenAI-compatible) through an Anthropic profile; read-only tools by default; honours retry-after. | built | ccparity_c_transports-9; llm_configuration § 5 | engine | CR.25, CS.12 |
| F-TRN-9 | VS Code LM transport (`vscode.lm`), with retry and tool-result trimming. | built | ccparity_c_transports-4 | VS Code-only | O-4 |
| F-TRN-10 | The Copilot chat panel and transport, Send to Copilot, the answer wrapper and answer files, the VS Code language-model tools. | retiring (`01_aifmt-1`, in progress) | todo | VS Code-only | O-4, CS.13 |
| F-TRN-11 | The GitHub Copilot SDK inside the Anthropic transport (measure first), then the VS Code LM transport retires. | planned (`later1_aktn-copilot-sdk`, decision open) | todo | engine | CS.12, CS.13, O-4 |
| F-TRN-12 | Further providers: the way in for OpenAI decided, nothing built. | planned (decided in `xxopenai1`) | archived todo | engine | CS.12, CS.16, CS.18 |
| F-TRN-13 | Provider SDKs installed on request into the extension's storage (npm registry, no npm or Node needed, integrity checked, tested versions, updates only on request, the Claude CLI for glibc or musl). | built | chat2; user guide *Provider SDKs* | engine (host page) | CR.40, CR.43 (partly: tested versions and the update check are not named) |
| F-TRN-14 | Backend-busy retry with the transport retry template on every transport. | built | anthropic_handler § 7 | engine | CR.27 |
| F-TRN-15 | Claude Code features on every transport: skills (`tomAi_loadSkill`, the skills list), subagent definitions, slash commands, hooks (PreToolUse, PostToolUse, UserPromptSubmit, Stop, SessionStart), CLAUDE.md. | built | ccparity_d_claudecode-1 … -6 | engine | CR.5, CR.59 |
| F-TRN-16 | Sub-agents (`tomAi_spawnSubagent`, also as a Claude Code subagent definition). | built | llm_tools § 6 | engine | CR.5, CP.4 |
| F-TRN-17 | The models the API and VS Code LM offer (Available models overlay, red when the API answers none). | built | progress 2026-11-24 | engine (host overlay) | CS.14 |
| F-TRN-18 | The real cause of an Agent SDK failure is reported (an expired login and the like). | built | sdkerr | engine | not covered |

### 2.9 Prompt assembly, roles, guidelines, templates, chat variables

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-PRM-1 | The placeholder and expression engine: chat variables, `${file-<path>}`, `${guidelines-<name>}`, `${memory}`, `${claudeMd}`, process and action variables, one expression system `${{ … }}`. | built | placeholder_engine.md; cc_parity_a_start-26 | engine | CR.5 |
| F-PRM-2 | User-message templates in one store for every transport, a default template, seeded templates (With asking, Execute TODO, Explain TODO, Guide me through a user action, Specify TODO) brought up to date while unedited. | built | user guide *Copilot*; vscimpb120 | engine | CS.3 (prompt templates in the repository's part) |
| F-PRM-3 | Template categories: profile system prompts, compaction, memory extraction, transport retry, interactive questions, assist prompts, (reminders, retiring). | built | anthropic_handler § 5 | engine | partly: CS.3 |
| F-PRM-4 | Assist prompts as a category chosen per use on the Status Page: grill me, explain in detail, explain a decision, grill me at a decision, finish review round, gate decision, out of budget, background-work reminder. | built | ccparity_i_assist-3; user guide *Assist prompts* | engine | partly: CP.38, CR.88, CR.92 |
| F-PRM-5 | Reusable (saved) prompts with an editor, per scope; planned only per quest. | partly built (`01_aifmt-3`) | user guide § 3; todo | engine | CR.54 |
| F-PRM-6 | Group prompts: a global default and additions, a quest's own default, additions and prompts; the group prompt editor with preview. | built | user guide *Group prompt editor* | engine (template store) | not covered |
| F-PRM-7 | Roles (`_ai/roles/<role>/role.md`, `role-config.yaml` naming the role type) and the Role Editor with two tabs. | built | gsel7; user guide *Tools by role* | engine (host editor) | CR.2, CT.9, SC-23 |
| F-PRM-8 | Role types with a tool selection (the profile's default or a selection per tool group) and always-on tools. | built | user guide *Tools by role* | engine | CT.9 |
| F-PRM-9 | The role of a prompt: todo > item > process step > run default > chat variable `role`; shown on the item with its origin and in the trail header; the run's variable shows it while the item sends. | built | gsel3, gsel11 | engine | CR.96 (still says "planned"), CT.9 |
| F-PRM-10 | Task-optimised roles (guidelines_author, dart_developer, ts_developer) built; role types reviewer, planner, coordinator, spec-author, every role naming a type, the tool payload measured per role type. | partly built (`gsel28` done; `tooloptimize10` … `15` planned) | todos | engine | CT.9 |
| F-PRM-11 | The aspect guidelines store: `_ai/aspect_guidelines/<aspect>/aspect.yaml` with choices, each its own text or a guideline file `_agent_guidelines/aspects/<aspect>/<choice>.md` found by a layered lookup. | built | gsel2, gsel16, gsel17 | engine | partly: CR.61 (calls them sections with options) |
| F-PRM-12 | The levels aspect default, workspace, quest default, window, run, role type, role, item, todo; several choices per aspect; each level replaces, adds or removes. | built | gsel19, gsel20 | engine | differs: CR.61 (one option per section; no workspace level; window open in PQ-35) |
| F-PRM-13 | Conditional choices (`when:`) and `remove_when` on an aspect, over chat variables, placeholders and prompt facts (`prompt.transport`, `prompt.kind`, `prompt.role`, `prompt.night` …). | built | gsel20 | engine | not covered |
| F-PRM-14 | The workspace level as files (`workspace_aspects.md` with `@<path>` lines, `workspace_aspects.yaml` with `remove:`), *Set / Clear workspace default*, the `CLAUDE-aspects-template.md` beside each CLAUDE.md. | built | gsel19, gsel27 | engine | not covered |
| F-PRM-15 | The skills list, the four guideline indexes and the fleet rules as aspects. | built | gsel21, gsel24, gsel26 | engine (content) | not covered |
| F-PRM-16 | Night mode: the aspect `night_mode`, sent while the window-wide chat variable `night-mode` is on, switched in this window or every window of the machine; the agent then decides by itself and records each decision as a question block with its answer, stopping only before what cannot be undone. | built (2026-11-25) | progress 2026-11-24/25 | engine | not covered |
| F-PRM-17 | The Question style aspect (`extra_explanations`: full, concise) and `asking_questions.md`. | built | progress 2026-11-24/25 | engine (content) | not covered |
| F-PRM-18 | The guideline picker on every level, the all-windows switch, the Aspect Guidelines editor; renaming an aspect or a choice carries the stored choices over in every store on the machine. | built | gsel5, gsel5b, gsel7, gsel7b | host UI (engine carry-over) | partly: SC-23 |
| F-PRM-19 | System aspects (`agent_role`, `feature_branches`) and their tab in the editor. | planned (`caf_05e`, `caf_06d`, `caf_09d`) | todos | engine | not covered |
| F-PRM-20 | Aspects that push a guideline in for some roles. | planned (`later2_akur-…`, deferred decision) | todo | engine | not covered |
| F-PRM-21 | Chat variables: built-ins of the window (quest, role, activeProjects, todo, workspaceName), custom variables per run, the editor, `tomAi_readChatVariable` / `tomAi_writeChatVariable`. | built | user guide § 3; llm_tools § 4.16 | engine | CR.2, CR.8 |
| F-PRM-22 | The chat variables contributed to VS Code's own chat (`tomAi.quest` …). | built | package.json `chatVariables` | VS Code-only | O-1 |
| F-PRM-23 | Completion in prompt fields: slash commands with their arguments, skills, the quest folder's files after `@`. | built | user guide § 10 | host UI (engine expansion) | partly: CP.38 (slash commands and skills; `@` quest files not named) |
| F-PRM-24 | Guideline tools: list, read, search the global and project guidelines; a rule heading's file read by its bare name on every level, with `§` sections. | built | guidelinename1; llm_tools § 4.10 | engine | partly: CR.33 (where guidelines are); the tools are in no set of CT.1 |
| F-PRM-25 | Pattern prompts (`!prompt`, `$prompt`) and their tools. | built | llm_tools § 4.10 | engine | not covered |

### 2.10 Tools, host tools, the MCP server, scripting

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-TOL-1 | About 237 `tomAi_*` tools in 30 families: files, shell, web, VS Code commands, editor, diagnostics, language server, git, notebook, guidelines, todos, ids, skills, external MCP, session todos, workspace, issues, tests, chat variables, memory, user interaction, planning, queue and timed requests and templates, past tools, TomSpecs, DocSpecs, CodeSpecs, processes, tool help. | built | llm_tools § 4 | engine and host | CT.1, CT.2 |
| F-TOL-2 | The core tool set, the long forms in `llm_tools.md` § 10 and `tomAi_describeTool`; descriptions capped by a test. | built | dapieff6; llm_tools § 10 | engine | not covered |
| F-TOL-3 | Tool enablement per profile; the MCP server's own picker; the scripting API gated by the active profile. | built | llm_tools § 9 | engine | partly: CT.9 (by role) |
| F-TOL-4 | Host tools: editor, language server, code actions, rename, VS Code commands, tasks, debug configurations, notebooks, open editors, problems, output channels, MD Browser panels. | built | llm_tools § 4.4 … § 4.9 | VS Code-only | CT.1, CT.4, CT.5 |
| F-TOL-5 | File, shell, web and git tools (`tomAi_runCommandStream` / `readCommandOutput` / `killCommand`, text search honouring `.gitignore`, git read / show / write with `cwd`). | built | llm_tools § 4.1 … § 4.3, § 4.8 | engine | CT.1 |
| F-TOL-6 | The standalone MCP server: Streamable HTTP, settings in the quest's config, autostart per host, port probing, a fresh server per request, its own tool picker, a bearer from an environment variable, a read-only floor without it, requests without the key only from loopback or the VPN, audit lines, the CodeSpecs guides as resources and prompts. | built | mcp_server.md § 1 … § 4 | engine | differs: CT.11, CT.12 (only `_ai` tools; today file and host tools are served behind the key); PQ-50 |
| F-TOL-7 | External MCP servers on the direct and Local LLM transports (`.mcp.json`, `claude mcp add`, project servers approved first, read-only tools do not ask). | built | ccparity_d_claudecode-7 | engine | CT.16 |
| F-TOL-8 | The scripting API: the JSON-RPC CLI integration server and the Dart client `tom_vscode_scripting_api` 7.0.0; `TomToolsApi` (tools invoked by scripts, gated in the extension); the Agent SDK mirror (`AgentSdkClient`, Dart-defined tools, reverse RPC, `canUseTool`). | built | agent_sdk_scripting_mirror.md; llm_tools § 9; 00_aifmt-5, -6 | engine | CP.12, CL.10 |
| F-TOL-9 | Specialised tools: `tomAi_searchCode`, `tomAi_fileOutline` / `readSection`, `tomAi_replaceInFiles`, `tomAi_findTodos`, `tomAi_commitPaths`, `tomAi_runChecks`, `tomAi_gitOverview`; guidelines prefer them over the shell. | planned (`tooloptimize2` … `9`, `16`) | todos; tool_optimisation.vscode_extension.md | engine | partly: CT.10 (the tool set grows) |
| F-TOL-10 | Plan mode tools (`tomAi_enterPlanMode`, `tomAi_exitPlanMode`), plan mode per run. | built | ccparity_c_transports-3 | engine | CR.58 |
| F-TOL-11 | A registry of cleanup tasks run by an agent through a tool (first task: temporary session folders). | planned (`aaa_cleanup1`, `aaa_cleanup2`) | todos | engine | CR.4 |
| F-TOL-12 | Issue and test tools (list, get, create, comment, status, labels) over a provider (GitHub, local). | built | llm_tools § 4.14, § 4.15 | engine | not covered (the panels are host's own, SC-25) |
| F-TOL-13 | The Tom Tool Log and tool timings. | built | user guide § 8 | VS Code-only | partly: CT.7 |

### 2.11 Asks, pickers, notifications, Telegram

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-ASK-1 | `tomAi_askUser`: up to 15 questions, choices (answer, move, branch, subprocess) at markers, *Send answers*, no deadline unless given. | built | llm_tools § 4.18, § 10 | engine | CP.8 |
| F-ASK-2 | `tomAi_askUserPicker`: a QuickPick with *Other…*; one picker per run; another run's picker answered in the panel. | built | llm_tools § 10 | engine (host picker) | CP.8 |
| F-ASK-3 | `tomAi_askInMdBrowser`: a document with buttons and *Keep this file*; process buttons (finish review round, reopen decision, gate decision). | built | ccparity_i_assist-1 | engine (host document) | CP.8 |
| F-ASK-4 | The Agent SDK's question tool, tool approvals and plan proposals in the same user-input panel. | built | user guide *The user-input panel* | engine | CP.8, CP.41 |
| F-ASK-5 | One open ask per run; the panel "Tom AI — Waiting for you" with a tab per run; *Show Pending Question*; the status-bar item. | built | vscimpb81 | engine (host panel) | CP.41, SC-2, SC-3 |
| F-ASK-6 | An ask ends with its execution (stop, resend, skip, hard interrupt); an answer typed after that is not sent. | built | vscimpb78, vscimpb33 | engine | CP.42 |
| F-ASK-7 | An ask survives a reload: stored on the item, shown again, answered by a continuation prompt in the same session. | built | vscimpb166 | engine | CP.9 |
| F-ASK-8 | Answered in the item's ask panel, from another window of the machine (a stand-in ask), or on Telegram; it closes everywhere. | built | vscimpb170, vscimpb173 | engine | CP.40 |
| F-ASK-9 | Answer an ask or a todo's decisions inline in a USER NOTIFICATIONS row from any window; an MD Browser ask brings its window and tab to the front. | planned (`vscimpb182_akya-…`) | todo | host UI | partly: CP.40 |
| F-ASK-10 | `tomAi_answerUser` and the Answers page: read state, suggested todos added on a click (filed by the agent), suggested prompts copied only, stored per machine and `_ai` folder outside git, an offer to delete past 500. | built | vscimpb171 | engine (host page) | CT.17, CP.44, SC-3 |
| F-ASK-11 | A Q&A trail: one file per ask and per answer in the quest's `question_and_answers/` folder. | planned (`vscimpb183_akya-…`, decisions open) | todo | engine | differs: CR.55 (`qa.<host>.<q>.md` per host, `01_aifmt-4`) |
| F-ASK-12 | Answers with question blocks: choice buttons, a text field, *Send prompt* through an answer-tool template, *Give me more details*. | planned (`vscimpb184_akya-…`) | todo | engine (host page) | not covered |
| F-ASK-13 | Asks with extra prompt buttons beside *Send answers* and *Give me more details*. | planned (`vscimpb185_akya-…`) | todo | engine | partly: CP.8 (allowed responses) |
| F-ASK-14 | One Q&A editor: Questions and Answers tabs, across quests and windows, filters, open first, correction prompts queued from it. | planned (`vscimpb186_akya-…`) | todo | host UI | SC-31, CU.6 *Asks* |
| F-ASK-15 | `tomAi_notifyUser`: urgency, channel auto / vscode / statusbar / telegram, modal. | built | llm_tools § 4.18 | engine | CP.10, CP.39 |
| F-ASK-16 | NOTIFICATIONS: one event log for the machine (last 1000), kinds with toggles, merged lines, who did it (agent with its execution, user, extension), window filter, Clear per window. | built | vscimpb124 | engine (host view) | CR.107, CP.39, SC-20 |
| F-ASK-17 | USER NOTIFICATIONS: open and answered asks, messages, answers, suggested processes, decisions, todos for the user, the queue holding; *Continue queue*; dismissed rows shared by all windows. | built | vscimpb170 | engine (host view) | CP.39, SC-3 |
| F-ASK-18 | RUNS: every run of every window of the machine with its state (waiting for user, interrupted, waiting for event, waiting on task, running, paused, idle) and detail; folding window tiles. | built | vscimpb123; progress 2026-11-24/25 | engine (host view) | CR.23, CU.17, SC-8 |
| F-ASK-19 | WINDOW STATUS and `tomAi_getQuestWindowStatus`: heartbeat every 30 s (gone after 90 s), servers and ports, what each window does (role, position, profile, session, queue summary, runs), build and Dart binaries. | built | user guide *Window Status Panel* | engine (host view) | CR.36, CA.5, CA.6, SC-19 |
| F-ASK-20 | A click on an entry's icon brings its VS Code window to the front. | planned (`vscimpb172_akrm-…`) | todo | VS Code-only | not covered |
| F-ASK-21 | Telegram: a bot per quest, one receiver per token, commands for status, notifications, the queue (queue_prompt, queue_list, queue_delete, queue_pause / halt / continue per run), the chat (send_prompt, cancel_chat, cancel_queue) and the workspace (ls, project, dart analyze, problems, bk, tk, bridge). | built | telegram_integration.md § 2, § 7 | engine | differs: L-9, D-6 (deferred) |
| F-ASK-22 | Telegram live forwarding of every session's trail (master switch, listen or silent). | built | telegram_integration.md § 6 | engine | differs: L-9 |
| F-ASK-23 | Telegram as an ask and reminder channel: questions answered with `<run>: answer`, `notifyUser` channel auto, todo reminders. | built | vscimpb25, vscimpb26; user guide *Target dates* | engine | differs: L-9 (an ask leaves the host only through tac, CP.18) |

### 2.12 Reviews, the MD Browser, team review rounds, annotations

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-REV-1 | The MD Browser: document picker, link resolver (`quest:`, `todo:`, `issue:`, `test:`, files found by name), section references, deep headings, search, folding with level buttons, indent, line links, history, live follow-tail mode, tab titles, panel tools (open, close, list, dormant tabs). | built | user guide *Markdown Browser* | host UI | SC-18, CU.9 |
| F-REV-2 | The reading notation (provenance, editorial, aside, refs, records, citations) with reading modes. | built | 03b_rdv1 | host UI | not covered (CU.9 open, PQ-43) |
| F-REV-3 | Form, section and record tables; heading divs; anchors and links by section id. | built | 05b_rdv1 | host UI | CU.9 |
| F-REV-4 | Rejected blocks with their resolution buttons; *Errors* in navigation and search. | built | 05b_rdv2 | host UI | not covered |
| F-REV-5 | Answering review questions: the answer button, options on hover, the recommended option from the TomSpecs runtime, Save and next. | built | vscannot4 | host UI (engine rules) | CU.6 *Review* |
| F-REV-6 | Edit mode (edit, insert), review comments with ids and authors, comment blocks. | built | vscannot2 | host UI | CU.6 *Review* |
| F-REV-7 | Inline marks drawn and decided (accept, reject, change comments, edit and remove comments, accept or reject all with undo), written by the runtime's rules. | built | vscannot3 | engine and host UI | CV.16, CU.6 *Review* |
| F-REV-8 | Marks from a selection and Track changes (edits written as signed marks, word by word). | built | progress 2026-11-20 | host UI (engine diff) | not covered |
| F-REV-9 | Stepping through a review: kinds, Whose (authors), Changed since, check-here markers, agents' annotations signed `agent_<role>`. | built | user guide *Stepping through a review* | host UI | partly: CU.6 *Review* |
| F-REV-10 | Change times on comments, questions, answers and marks. | built | vscimpb23 | engine | CV.16 |
| F-REV-11 | Editing guarded: refused when the file changed or is dirty; a bar *Show the new version* / *Keep my text* when an agent wrote meanwhile. | built | user guide *Editing is guarded* | host UI | not covered |
| F-REV-12 | Grill me and Explain in detail on every open question (temporary session based on the position's session, the overlay while the agent thinks, the closing question with the proposal). | built | ccparity_i_assist-6 | engine (host overlay) | CP.38 |
| F-REV-13 | Proposed answers (Accept, Edit, Discard; `tomAi_mdProposeAnswer`). | built | vscimpb66b | engine | CV.16 |
| F-REV-14 | Team review rounds: round folder with a copy per member, the team from the document or the solution blueprint, guests named with role, merge with authors, votes and conflicts, decisions, `round.yaml` with `nextRound`. | built | ccparity_f_teamreview-1 … -3, vscimpb107, vscimpb115 | engine | CR.5, CV.12, CV.13, CV.16 |
| F-REV-15 | Consolidation in the MD Browser: member chips, the Team legend with *Only …*, accept or reject a member's changes, conflict blocks (Decide, Rewrite, Keep open), the counter and *Next unresolved*. | built | ccparity_f_teamreview-3 | host UI | CU.6 *Review*, CV.16 |
| F-REV-16 | The review member id (Status Page) signs comments, marks and answers. | built | ccparity_f_teamreview-1 | engine | CP.13 (identity: member id) |
| F-REV-17 | An agent's changes reviewed in the MD Browser (accept, reject). | built | vscimpa11 | host UI | partly: CR.17 (review each result) |
| F-REV-18 | The MD Browser page behind a host object, with the page protocol version 1 (25 page-to-host and 15 host-to-page messages, six capabilities). | built | 01b_woneb1, 01b_woneb2 | host UI | CU.9 |
| F-REV-19 | Page protocol: reveal an item, report the reading position, report changes. | planned (`04c_woneb3_akym-…`) | todo | host UI | CU.9 |
| F-REV-20 | The page bundle published in `tom_binaries`; a host conformance suite for the page. | planned (`04c_woneb2`; `04c_woneb1`, blocked) | todos | host UI | CU.9, PQ-43 |
| F-REV-21 | One review folder layout: `reviews/<name>/review.yaml`, `round-<n>/outbound`, `returned`, `consolidated`. | planned (`04c_woneb4_akym-…`) | todo | engine | differs: CV.13 (the round folder as built) |
| F-REV-22 | MD Browser: export and import buttons; a section copy shown read-only; headings past level 10. | planned (`06b_rdv1`, `sauvoc2`, `vscimpb162`) | todos | host UI | not covered |
| F-REV-23 | Panel settings across reloads and *Save as default*; large documents rendered in steps. | built | 02c_rdv1, mdbwebkit1 | host UI | not covered |
| F-REV-24 | Question tools for plain Markdown (`tomAi_mdQuestions`, `mdSetAnswer`, `mdProposeAnswer`, `mdInsertQuestion`). | built | ccparity_i_assist-2 | engine | partly: CP.38 |

### 2.13 TomSpecs and DocSpecs tooling

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-SPC-1 | The TomSpecs (SOM) runtime bundled from `tom_ai/ai_build`, documents read and written as YAML or Markdown. | built | vsctsa1, vsctsa2 | engine | CT.1, CT.10, E-21 |
| F-SPC-2 | Read tools: list documents, outline, get section, reflect, search with a paged cursor. | built | vsctsa3, vsctsa4 | engine | CT.1 |
| F-SPC-3 | Edit tools: content, typed form fields, headline, codeSpec, units, list items, section ids, clear, batch edits, create, convert, marked edits. | built | vsctsa5, vsctsa6 | engine | CT.1 |
| F-SPC-4 | Validate, render (with the switches of `tomspecs :spec-render`), convert. | built | vsctsa7, 05b_rdv3 | engine | CT.10 |
| F-SPC-5 | Review annotation tools: comments, questions, answers, marks, change comments, resolve, remove all, extract and write answers, assign comment ids. | built | vscannot1 … 3 | engine | CT.1, CV.16 |
| F-SPC-6 | Team review tools: create a round, its status, merge the copies, decide conflicts. | built | ccparity_f_teamreview-2 | engine | CR.5, CV.12 |
| F-SPC-7 | Process check tools (authorization, coverage, feature register, idea coverage, question register, required fields, import answers). | built | llm_tools § 4.23a | engine | CT.10 |
| F-SPC-8 | Document-set tools with staged writes: sync report, backfill, prefill, derive fields, rename id. | built (2026-11-25) | 05b_sau1, 05b_sau2 | engine | CT.10 |
| F-SPC-9 | DocSpecs Markdown tools (validate, outline, get and replace a section). | built | vsctsa8 | engine | CT.1 |
| F-SPC-10 | CodeSpecs (Phase 4) tools: areas, routing, extract, write extracts, gate, verdicts, plan todos, query, trace, validate (also IR), step context, map, status, guide; the guides as MCP resources and prompts. | built | vsctsa10 … 22, qre1 | engine | partly: CT.1 ("the specification tools"); CodeSpecs is not named |
| F-SPC-11 | `tomspecs` bundled per platform; `binaryMissing` with help when there is none. | built | vsc_nodart, vscimpb147 | engine | CT.10 |
| F-SPC-12 | Marked edits for typed values and headlines (the `notText` refusal lifted). | planned (`vscimpb189`, blocked by tom_specs) | todo | engine | CT.10 |
| F-SPC-13 | The impact walk tool and the `:spec-fill-frem` tool. | planned (`vscimpb178_aksp-…`, `specfrem1_aksw-…`) | todos | engine | CT.10 |

### 2.14 Memory

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-MEM-1 | Memory per quest and session (`_ai/memory/<quest>/<session>/`), files of `##` sections; tools save, update, read, list, forget, with `sessions`. | built | llm_tools § 4.17 | engine | CR.2; differs from the planned CR.53 |
| F-MEM-2 | `${memory}` and `${memory-quest}` placeholders; a per-profile bucket `facts-<suffix>.md` injected for that profile. | built | anthropic_handler § 4 | engine | CR.5 |
| F-MEM-3 | The memory extraction pass with a model of its own. | built | ccparity_a_directapi-4 | engine | CR.70 |
| F-MEM-4 | The memory panel (whose memory it shows and edits). | built | package.json `tomAi.panel.memory` | host UI | SC-15 |
| F-MEM-5 | Shared memory across sessions removed. | retiring (done, `00_aifmt-3`) | todo | engine | CR.53 |
| F-MEM-6 | Quest memory: curated facts shared, candidates per host naming their session, a *Promote memory* prompt. | planned (`01_aifmt-3`) | todo | engine | CR.53 |

### 2.15 Usage and cost

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-USG-1 | Usage and cost per round into a ledger per day and model (62 days); a failed send shows its cost; a resumed Agent SDK prompt reports its own rounds. | built | ccparity_a_directapi-3, dapieff2, qrfix3 | engine | CR.98, CR.105 |
| F-USG-2 | Usage shown in the live trail, the panel and the queue editor (tokens, cache reads and writes) and in the Status Page's Usage section. | built | dapieff16 | host UI | CS.14, CU.6 *Conversation* |
| F-USG-3 | The tool definitions each role type sends per turn measured. | planned (`tooloptimize15`) | todo | engine | not covered |

### 2.16 Prerequisites, binaries, build and installation

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-PRE-1 | `prerequisites.yaml` (secrets with type, purpose, how to get and provide; software on the PATH; never a value) and the PREREQUISITES view with presence checks in VS Code's environment and a login shell. | built | vscimpb152 | engine (host view) | open: PQ-35; SC-25 |
| F-PRE-2 | A custom editor for `prerequisites.yaml`; the file for every project that needs one. | planned (`vscimpb152b`, `vscimpb152c`) | todos | host UI | SC-25 |
| F-PRE-3 | Missing Dart binaries (`tom_bs`, `tomspecs`) detected per platform: a page, a status-bar item, a Status Page section; configured or bundled binaries. | built | vsc_nodart*, vscimpb83, vscimpb103 | engine (host page) | CT.10 |
| F-PRE-4 | One VSIX per platform, the build scripts, the build lock, the release in `tom_binaries`. | built | vscimpb103, vscimpb155 (cleanup planned) | VS Code-only | partly: CR.42, N-29 |
| F-PRE-5 | *Reload: newer Tom AI build*: every window compares its build with the installed one; agents read `build.reloadNeeded`. | built | user guide *Which build a window runs* | engine (host notice) | CP.27 |
| F-PRE-6 | The Status Page: the editors overview, queue and timer, after reload, Telegram, MCP server, usage, compaction, LLM configurations, todo buttons, assist prompts, Dart binaries, extension build, team review. | built | user guide § 7 | host UI | SC-21 |

### 2.17 Collaboration and features (planned in `collab_and_features`)

All of this is planned in the extension, independent of tac ("TAC may later replace parts of it":
collab_and_features *Intent*), to start after the workspace-layout change and the `aifmt` todos.

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-COL-1 | Agent groups of runs (chat variables `agent-group`, `agent-role`), a supervisor claimed with the user's confirmation, six exchange tools between supervisor and collaborators, run cards, `getCollaborators`. | planned (`caf_05a`, `caf_05b`) | todos; input (a) | engine | not covered |
| F-COL-2 | The supervisor's loop: pings every 2 minutes for unanswered exchanges, revoking the supervisor, answering for the user. | planned (`caf_05c`) | todo | engine | not covered (CP.22 forwards an ask to a member, not to an agent) |
| F-COL-3 | The AGENT COLLABORATION view in a new @TOM COLLAB side panel; a switchable super-supervisor. | planned (`caf_05d`, `caf_05e`) | todos | host UI | not covered |
| F-COL-4 | Lease tables in the git remotes: one ref `refs/tom-leases/table` per repository (a commit whose message is the table), compare-and-swap, path overlap, renewal, stale after 30 minutes, release. | planned (`caf_04a`) | todo; *part-leases* | engine | differs: CA.8 … CA.16 (tac leases with fencing tokens, stale after 60 minutes), CA.26 (the GitHub backend keeps leases in one coordination repository) |
| F-COL-5 | Leases in the queue: claimed before an item is sent and released after, a hold over a group, the waiting display with the holder, *Proceed anyway*, quests with leases off only check. | planned (`caf_04b`) | todo | engine | partly: CW.4, CW.9 |
| F-COL-6 | Agents claim more during a turn in one call (waiting at most 15 minutes) and free; a resource log. | planned (`caf_04c`) | todo | engine | not covered |
| F-COL-7 | The RESOURCE LEASES view with *Clean up* of dead leases. | planned (`caf_04d`) | todo | host UI | SC-28 |
| F-COL-8 | Branch and worktree tools: `todo/<id>`, `group-todo/<id>`, `feature/<id>` branches, worktrees `<folder>@<branch>` beside the main clones. | planned (`caf_06a`, blocked) | todo | engine | differs: CW.2, CW.3 (worktree mode per repository, an execution's own working tree) |
| F-COL-9 | The merge tool: a review gate, fast-forward of the main clone, a `quest-keeper` follow-up, publishing order. | planned (`caf_06b`) | todo | engine | differs: CW.5, CW.6 (the integration step and queue) |
| F-COL-10 | FEATURE BRANCHES and BRANCH LOG views; the `feature_branches` aspect. | planned (`caf_06c`, `caf_06d`) | todos | host UI | partly: SC-28 |
| F-COL-11 | Features: group todos of group todos in phases; feature tools (create, update, validate phases); the `agent_coordination` quest and its template. | planned (`caf_07a`, `caf_07b`) | todos | engine | not covered |
| F-COL-12 | Feature runs per quest built by the extension (lanes, sessions, one machine per feature), the coordinator role with `tomAi_getFeatureState`, Replan, failed groups and Retry, the end of a feature. | planned (`caf_07d` … `caf_07f`) | todos | engine | not covered |
| F-COL-13 | Reviews: a review setting on four levels; a review todo at the end of a group, run in a fresh session by a reviewer, `tomAi_recordReview`, rework todos, the user asked after three failed rounds. | planned (`caf_08a`, `caf_08b`) | todos | engine | partly: CW.15 (review without pull requests) |
| F-COL-14 | Features in the todo panel (a third line, read-only foreign todos, filters), the FEATURE EXPLORER, WORKSPACE REPOS (the tree root → workspaces → repositories with clones, branches, revision, dirty state). | planned (`caf_09a` … `caf_09c`) | todos | host UI | not covered |
| F-COL-15 | The issue flow: issuekit bundled, one issue panel engine, INCOMING / ACCEPTED ISSUES / ISSUE VERIFICATION views, the `issue2feature` process, closing and confirmation todos, the 14-day close. | planned (`caf_10a` … `caf_10g`) | todos | engine and host UI | not covered |
| F-COL-16 | The informed session `default@quest-keeper` (reads the quest in once), the quest's `defaultResources`, a what-changed prompt after merges, the @TOM QUEST side panel. | planned (`caf_03f` … `caf_03h`) | todos | engine | partly: CR.35 (a quest's list of repositories) |

### 2.18 Anything else

| Id | Feature | State | Source | Kind | Project Idea |
| --- | --- | --- | --- | --- | --- |
| F-OTH-1 | DartScript (the `tom_bs` bridge): Execute File, Execute as Script, Run Tests, bridge profiles, restart, debug logging, print configuration. | built | user guide § 6 | VS Code-only | not covered (O-1) |
| F-OTH-2 | The CLI integration server (start, stop, custom port) for scripts. | built | user guide § 6 | engine | CP.12 |
| F-OTH-3 | The process monitor and user-defined command lines (add, delete, execute). | built | package.json | VS Code-only | O-1 |
| F-OTH-4 | Notes views: VS CODE NOTES (global), WORKSPACE NOTES (a picked file), QUEST NOTES in @TOM and in @TOM INFO with Edit and View tabs. | built | user guide *Notes views*, *@TOM INFO* | host UI | CR.54, SC-16, SC-17 |
| F-OTH-5 | The Guidelines panel and the Documentation panel's document editor. | built | user guide § 2 | host UI | SC-24 |
| F-OTH-6 | The Issues and Tests panels (repositories from git remotes and config, *My Repos*, attachments). | built | user guide *Issues Panel*; chat_enhancements § 6 | host UI | SC-25 |
| F-OTH-7 | RESOURCES: the extension host's helper processes grouped by extension, pause, resume, kill, lean VS Code profiles, workspace toggles. | built | user guide *@TOM VSC* | VS Code-only | SC-25 |
| F-OTH-8 | Output channels (11) and the debug log file with start-up timings. | built | user guide § 8 | VS Code-only | SC-13 |
| F-OTH-9 | Layout commands, chord menus, keybindings, maximize and panel state flows. | built | package.json; quick_reference.md | VS Code-only | O-1 |
| F-OTH-10 | The Extension Tools overlay; Up / Down ordering in every editor's list (`editorListOrder`). | built | user guide § 3 | host UI | SC-21, SC-22 |
| F-OTH-11 | An external Markdown viewer (MarkText) through `externalApplications.mappings`. | built | marktext_integration.md | VS Code-only | O-1 |
| F-OTH-12 | Send to Anthropic/LLM from the editor (selection or file, default or picked template). | built | user guide *Send to Anthropic/LLM* | VS Code-only | CR.16 (the send itself) |
| F-OTH-13 | JSON and YAML schema validation for the extension's files in the editor. | built | package.json `jsonValidation`, `yamlValidation` | VS Code-only | O-1 |
| F-OTH-14 | `tom_tac_service` 0.1.0 in local mode in the same repository, used by nothing. | built (unused) | overview; E-3 | engine | E-3, E-11 |
| F-OTH-15 | Response values (`REQUIRED: Add responseValue …`, Show / Clear Chat Answer Values); the Copilot answer-file part leaves with Copilot. | partly built (Copilot part retiring with `01_aifmt-1`; not verified in code) | user guide *Todo stack*; package.json | engine | not covered |

## 3. What "distributed and with a team" adds, per area

| Area | What it needs beyond the baseline | Project Idea |
| --- | --- | --- |
| Quests and `_ai` | Files reach other machines only by a pull and push the user starts; two runtimes (two hosts, two machines, two users) write the same todo and state files; a format migration on one machine must not strand the others. | CW.27, CW.13 (re-read before write), CP.29 … CP.34, PQ-34, PQ-40, PQ-36 |
| Quests and `_ai` | The quest refresh run once per quest, not once per host or machine. | not covered (PQ-35 asks only runtime or host) |
| Quests and `_ai` | The questions journal and the decisions journal written by several machines without merging into each other. | CR.47 (per-host files), CR.55, PQ-53 |
| Workspace | Repository quests and their register; a member joining a quest; a repository absent on a machine by design. | CQ.1, CQ.7 (join), CR.100, CR.103 |
| Todos | A blocker in another quest on another machine releases the waiting todo; a todo offered by another team is accepted by a person or a rule. | CW.21, CW.26, CA.44 |
| Todos | Todo reminders and repeats ring once per person, not once per machine or host. | partly: CR.50 ("rings once" is stated for one machine; `due_reminded` makes it once across hosts today) |
| Todos | The todo panel across quests on other machines (offers, the queued marker of a remote run). | partly: SC-30, CA.5 |
| Processes and runs | A run executed by exactly one runtime when two hosts or two users work on a quest; the process position moved only on the main branch for a repository quest. | open: PQ-36; CQ.6 |
| Processes and runs | A process move offered in an ask answered on another device acts on the asking run. | CP.8 |
| Queue | Items, walks and done notifications sent into a run of a quest on another machine, acknowledged, waiting at the sender. | CW.19, CW.20, CW.23, CA.19, CA.21 |
| Queue | Claims before an item is sent; an item waiting for a lease another runtime holds says who holds it. | CW.4, CW.5, CA.8 … CA.16 |
| Queue | Control items that pause, interrupt or silence runs on other machines (a reconcile's quiet phase); wait and notify across machines. | partly: CW.13; not covered for wait / notify and silence (F-QUE-35 … 37) |
| Queue | Commands from trc or another runtime (remote control): queue, pause, continue, answer. | CK.2, CI.13, PQ-50 |
| Timed requests | A timed request of a quest fires once, not once per host. | open: PQ-36 option (b) assigns them to the runtime holding `default` |
| Sessions and trails | A session's conversation lives on one machine (Agent SDK): continuing it elsewhere starts a new conversation (built today as a recovery, F-SES-7); trails per host so machines never merge. | CR.47, CR.79; not covered for "continue a session on another machine" |
| Sessions and trails | A runtime client attaching late, reconnecting, or from a phone reads the run's numbered events. | CP.5, CP.6 |
| Transports | The team decides the allowed providers and standard profiles; usage per person and provider. | CS.3, CS.4, CS.6, CS.14 |
| Prompt assembly | The "window" level of the aspect guidelines and window-wide chat variables (`night-mode`, `role`) need an owner when there is no window; night mode switched "in every window" becomes every runtime of the person. | open: PQ-35; not covered for night mode |
| Tools and MCP | A runtime's MCP server published to the team runtimes, authenticated; host tools never through it. | CT.11, CT.12, CT.13, CA.23, PQ-50 |
| Asks | An ask reaches the person's other devices after 10 minutes, then the chain of people; forwarded to a member; seen by the team with age and chain. | CP.17, CP.18, CP.22, CP.23 |
| Asks | An ask answered on another device or by another person is recorded in the asking host's journal. | open (CR.55: the Solution Blueprint settles it) |
| Asks | Notifications of another person's runtime, and an answer handed to the user (`tomAi_answerUser`) seen on the person's other devices. | partly: CA.20, CM.6; not covered for answers |
| Asks | Telegram (today the only channel off the host). | deferred: L-9 |
| Reviews | Review rounds whose copies travel through tac (requests, returns, reminders, blobs pinned), reviewers without a repository, guests. | CV.11 … CV.16, CM.2, CM.4 |
| TomSpecs | Specification documents edited by several members' runtimes (staged writes, revision checks). | partly: CS.2 (one key per write; not for documents) |
| Memory | Curated facts shared by the quest's members, candidates per host. | CR.53 |
| Usage | A ledger per machine; a team's quota and usage. | CR.105; CA.27 (quotas per account on a tac server) |
| Prerequisites | What a project needs, checked on each member's machine. | open: PQ-35 |
| Collaboration and features | Supervisor and collaborators across machines and people; leases and feature branches across machines (the extension's plan has git-ref leases across machines and everything else on one machine). | not covered (agent-to-agent exchange); differs for leases (CA.26) |
| Supervision | The team runtimes in one view, what waits, from the desk or a phone. | CK.1 … CK.12, CU.17, F10 |

## 4. Gaps

Each gap names the baseline rows it comes from. The search terms used to establish "not covered"
were, among others: quest refresh, night, control item, worktree, workspace template, Grill,
Explain, tool search, past tool, tool trail, approval mode, accept edits, context editing,
group prompt, Guide me, todo stack, date code, generateIdPrefix, workspace todo, reading notation,
rejected, track changes, CodeSpecs, plain Markdown, supervisor, feature branch, featureId, Notify,
planning run, quest-keeper, question_and_answers, window, pattern prompt, global schedule.

**G-1 — The extension's own plan for leases, branches and agent collaboration
(`collab_and_features`, 76 todos) is not in the Project Idea and differs from it.** Rows F-COL-1 …
F-COL-16, F-TOD-34, F-QUE-37, F-QUE-38, F-PRC-22. The extension plans git-ref lease tables per
repository (stale after 30 minutes), a resource notation `git://server/…`, feature branches in
worktrees `<folder>@<branch>`, a merge tool, agent groups with a supervisor, feature runs with
Wait / Notify items, standard runs `planning` and `quest-keeper`, review todos and an issue flow;
the Project Idea has tac leases (60 minutes, fencing tokens, `git:` names), worktree mode and an
integration step, and no agent-to-agent exchange. With D-40 the extension's features are finished
before the split, so these would be part of the v1 baseline. **Question for the product owner:**
(a) build `collab_and_features` in the extension first and carry it into the runtime as it is
(the git-ref lease table becomes one more tac backend, the feature model and agent groups become
runtime items); (b) build it in the extension now, and let the runtime replace leases and branches
by tac (CA, CW) and carry over only features, standard runs, reviews and the issue flow; (c) stop
the parts that tac covers (leases, branches, merge) in the extension and build them only in the
runtime. Proposed items whichever way: "A todo can be a feature: a group of group todos in phases;
the runtime runs a feature as a run per quest it touches, phase by phase, coordinated by
notifications." "Runs of one person can form an agent group with one supervisor run; an exchange
between them is delivered into the waiting turn like a message (CR.72)." "One resource notation
serves todos, claims and leases" (reconciling CW.7 with `caf_01a`).

**G-2 — Control items and coordination items in the queue are not covered.** Rows F-QUE-35 …
F-QUE-38, F-PRC-5. The process-move marker exists; the extension plans control items (start,
pause, interrupt, resume runs in this or other windows, silence for a reconcile, notify),
wait-for-todo / wait-for-run / barrier items, and Wait / Notify for features. Proposed item for
`RT-QUEUE`: "Besides items sent to a model, a queue holds items the runtime carries out itself when
its lane reaches them: the move of a process (the marker), a notification sent, a wait for named
notifications, a todo or a run, and commands to other runs (start, pause, interrupt, resume). They
act across machines through tac (CA.19) as on one machine." **Question:** do control items reach
runs of other machines and other people in v1 (`vscimpb187`'s open decision "this machine's
windows only")?

**G-3 — Prompt assembly from aspect guidelines is written in the older model.** Rows F-PRM-11 …
F-PRM-17. CR.61 says "one option per section" over seven levels; the extension has aspects with
several choices, replace / add / remove per level, conditional choices (`when:`, `remove_when`
over prompt facts), a workspace level as files with `@<path>` imports, guideline files layered
over root and workspace folders, and night mode. Proposed text for CR.61: "Prompt assembly takes,
for each aspect of the aspect guidelines, the texts of the choices in effect, placed in the system
prompt or before the user prompt on every transport. A choice is its own text or a guideline file
looked up over the root and the workspace folders. The levels, the later winning, are: the
aspect's default, the workspace (its `workspace_aspects` files), the quest's default, the host's
choice for this runtime (PQ-35), the run, the role type, the role, the item, the todo; a level
replaces, adds to or removes the choices below. A choice or an aspect can carry a condition over
chat variables and facts of the prompt." Add: "Night mode is an aspect switched by a variable
of the person's runtimes; while it is on the agent asks nobody and records each decision it takes
as an answered question."

**G-4 — Telegram is the only channel that reaches the user away from the host today; v1 defers
it.** Rows F-ASK-21 … F-ASK-23, F-TOD-14. With L-9 the first runtime loses remote queue control,
live trail forwarding, asks answered by `<run>: answer` and todo reminders on the phone, until tac
and trc on the phone exist. **Question:** keep the deferral (trc and tac replace it), or carry the
extension's per-quest Telegram into v1 as a channel of the runtime ("the runtime can forward asks,
notifications and reminders to a configured Telegram chat and take commands from it"), with
L-9's one-token-for-all design later?

**G-5 — The quest refresh, the prompt after a reload and the process-item mark** (PQ-35, open).
Rows F-QST-7, F-QUE-29, F-QUE-30. In the distributed setting the refresh must run once per quest:
**question** added to PQ-35: who counts the prompts when two hosts or two machines work on the
quest? Proposed item if (b): "The runtime queues a quest refresh by itself after a set number of
counted prompts of the quest; items of a process step do not count. With several runtimes on a
quest, the runtime that holds the run `default` counts (PQ-36)."

**G-6 — The model-transport features beyond CR.27 are not named.** Rows F-TRN-3 … F-TRN-6,
F-TOL-2, F-SES-13. Tool search with deferred tools and the `<!-- tools: … -->` directive,
server-side clearing of old tool results, images and PDFs to the model, the approval modes, the
core tool set with `tomAi_describeTool`, and the stored tool results with replay keys and
retention. Proposed text added to CR.27: "… a core set of tools sent in full and the others
deferred behind the provider's tool search, tools named by a prompt or its template, the clearing
of old tool results, images and documents as content, and the approval modes (always, accept
edits, allow a tool for the session; queued prompts never ask)." New item: "Every tool result of
a session is stored under a replay key, kept for a set time and number, and an agent reads past
results through tools."

**G-7 — The Q&A store differs between two plans of the extension, and from CR.55.** Rows
F-ASK-11 … F-ASK-14, F-QST-9. `01_aifmt-4` plans `qa.<host>.<q>.md` per host (CR.55); `vscimpb183`
(2026-11-25) plans one file per ask and per answer in `question_and_answers/`; `vscimpb184` /
`vscimpb185` give answers question blocks and asks extra prompts and *Give me more details*.
**Question:** which store is the runtime's (one file per entry also avoids merges between members
of a team), and are answers with question blocks and extra prompt buttons part of the ask envelope
(CP.8) in v1? Proposed addition to CP.8: "An ask and an answer handed to the user can both carry
question blocks and prompts; the user's choice queues the prompt into the run that asked."

**G-8 — Moving and re-targeting items, and run defaults that items follow, are not covered.**
Rows F-QUE-14, F-QUE-16, F-QUE-4. Proposed item for `RT-QUEUE`: "An item that is not done can be
moved to another run, another session and another place in its lane; an executing item is stopped
first. A run's defaults can be applied to its waiting items, and an item can follow its run's
defaults, taken when it is sent. A run's settings can become the start values of new runs." And
add to CR.69 the states "waiting for a rate limit or a quota until a time" and "retrying (n of m)".

**G-9 — The workspace template and the setup of a workspace are nobody's.** Rows F-WSL-3,
F-WSL-4, F-QST-3. Today the VSIX carries the template and unpacks it (new root, workspace in a
root, standalone), registers the merge drivers and creates quests with a setup todo. **Question:**
is setting up a workspace and creating a quest (with its setup todo and short description) a
runtime command that every host offers (proposed item: "The runtime installation carries the
workspace template; a command sets up a workspace folder in one of three forms and creates a quest
with its setup todo"), or the VS Code host's own?

**G-10 — Several todo operations are not stated.** Rows F-TOD-9, F-TOD-16, F-TOD-20 … F-TOD-24,
F-TOD-12, F-TOD-33. Proposed additions to CR.48 … CR.51: "A completed todo is archived into a
sibling file and a todo that was not completed is deleted into another, both recoverable and
restorable; archiving copies its decisions into the decisions journal." "Todos move between files,
groups, quests and the workspace's own todo file, renumbered into the target group." "Ids are made
from a date code by a tool and checked against the schema's id pattern." "The dependencies of a
set of todos can be repaired in one pass." "A repeated todo's next occurrence takes its due date
and reminders with it; a reminder can be snoozed." The todo analyzer (dependency closure and the
queued items of every runtime) is a runtime query once queues are distributed.

**G-11 — Process details that the runtime needs are not named.** Rows F-PRC-5, F-PRC-13,
F-PRC-19, F-PRC-20, F-QST-8. Proposed: "A process step is executed by queueing its prompt and a
marker; the process moves when its lane reaches the marker with the step's items done; a failed
item holds the marker." "The prompt that executes a position is built from a template the
workspace can edit." "A step's documents may come from a variable holding several paths."
"Grill me and Explain at a decision run as assist prompts in a temporary session based on the
position's session." And CR.55: "the decisions journal also records every move of a process that
is not a plain step: jumps, resets, follow-up switches, aborted levels, left-out steps".

**G-12 — Session and trail details.** Rows F-SES-7, F-SES-12, F-SES-14, F-SES-21. Proposed:
"When an agent transport no longer has a session's conversation (another machine, a cleared
store), the runtime starts a new conversation in the same session once and says so in the
trail." "The trail records each prompt as typed, as sent, and its system prompt." "History and
memory can be rebuilt from a session's trail." "Every tool call is attributed to the execution
that made it, also when several executions of one runtime run at once."

**G-13 — The MCP server serves more today than CT.11 allows.** Row F-TOL-6. The extension's
server serves every enabled tool, file and host tools included, behind a key, with a read-only
floor and a peer rule (loopback or the VPN without the key). **Question:** does v1 keep a second,
local-only MCP endpoint with file and host tools for an outside agent on the same machine or VPN
(Claude Code in a terminal working with the quest's tools), or is CT.11 strict? Proposed addition
to CT.12 whatever the answer: "Without a valid token the server serves only read-only tools, and
only to the local machine and the VPN."

**G-14 — Issue and test tools, guideline tools and pattern prompts are in no tool set.** Rows
F-TOL-12, F-PRM-24, F-PRM-25, F-COL-15. Proposed addition to CT.1: a row "Runtime tools on the
workspace: guidelines and pattern prompts, the project and repository lists, the issue and test
trackers of the configured providers; model transports and agent transports; through the MCP
server read-only." **Question:** is the issue flow (`caf_10*`) a runtime feature or the VS Code
host's own (SC-25 says host's own for the panels)?

**G-15 — Template stores beyond prompt templates.** Rows F-PRM-3, F-PRM-4, F-PRM-6, F-TOD-29,
F-PRC-13. Group prompts (global and per quest), the todo buttons templates, the assist prompts and
the Proceed template are stores the queue and the processes read. Proposed addition to CS.3 (the
repository's part) and CR.2: "templates of every category: user-message templates, group prompts,
assist prompts, the templates of the todo buttons and of the Proceed prompt, and the queue
templates".

**G-16 — Smaller engine behaviours with no item.** Rows F-TIM-2, F-QUE-31 … F-QUE-33,
F-TRN-18, F-QUE-11. Global schedule slots for timed requests; where queue entries live (in `_ai`
today, against CR.106's closed list); the watchdog; the timeout of a chat send; the real failure
cause of an agent transport. Proposed: one item each in `RT-QUEUE` and `NFR`. **Question:** do
queue entries stay files in `_ai/queue/` (shared, host-prefixed names) or become machine-wide
state outside `_ai`?

**G-17 — Built items still marked planned in the Project Idea.** CR.83 (held item goes on by
itself: built 2026-11-25, `vscimpb179`), CR.96 (role order: built, gsel3, gsel11), CR.61 ("choosing
per level is planned": built, gsel4 … gsel10), CR.70 ("planned: role and guideline choices":
built), E-1 (the `aifmt` work since 2026-11-25). Proposed: drop "Planned" in these items; DEL's
"that the queue does this without a person is asked of the extension" is answered.

**G-18 — Feature parity rows a second host needs commands for.** Rows F-TOD-26, F-TOD-27,
F-TOD-30, F-QUE-11, F-PRM-23 (`@` quest files), F-TRN-17. Proposed addition to CP.38: "… the
queued todos with their items, the files of the quest for completion, the models a profile can
use."

## 5. For the second extension (v2)

What the inventory says about copying the extension into `ai_build` and rewiring it to the
runtime, "with all features working as before (only distributed and with a team)".

**How the inventory splits.** Of the 321 rows, 254 are engine (counting rows that are engine with
a host dialog or view), 49 host UI and 18 VS Code-only. In the v2 extension:

- **Becomes runtime calls (the engine rows):** every store and engine of sections 2.1 … 2.17
  marked *engine*: quests and their journals, todos and their rules, processes and runs, the queue
  with all item kinds and states, timed requests and todo reminders, sessions and trails,
  transports and providers, prompt assembly (templates, roles, aspect guidelines, chat variables,
  placeholders), the runtime tools on `_ai` and on files, the MCP server, asks and their envelope,
  notifications, the review rounds and annotation writing, the TomSpecs tools, memory, the usage
  ledger, the migration and merge drivers. In the extension these live in `managers/`,
  `services/`, `tools/` and parts of `handlers/` (the transports); the guard on the boundary is
  N-32, and `vscimpb176` (services that import handlers and tools, not started) is work the copy
  depends on.
- **Stays in the extension (host UI and VS Code-only rows):** the panels, sidebars, editors and
  pages (SC-1 … SC-26 as host's own or over components), the MD Browser webview, the host tools
  (editor, language services, commands, tasks, debug, notebooks), the VS Code LM transport (O-4),
  DartScript, the resources view, output channels, chords and layout, the schema validation.
  With O-1 they stay VS Code views; the v2 extension feeds them from runtime commands and events
  instead of from in-process managers.

**What the protocol has to carry so that every feature works as before.** From the rows, beyond
what CP.3, CP.4, CP.36 … CP.39 list:

1. Every queue command of section 2.5, including Send now on a sent item, set status by hand, move
   an item between runs / sessions / places, apply run defaults, Make default, Let the next item go
   first, Send between iterations, pause after this, Retry all errors, and the group member
   selection (G-8, F-QUE-9, F-QUE-14 … F-QUE-17).
2. The events behind the views that update live today through file watchers and the machine-wide
   files: the queue item states and marks, the queued marker per todo, run states, the window /
   runtime registry (WINDOW STATUS, RUNS), the notification log, the user notifications and
   their dismissal, the Answers store, the live trail stream, todo file changes (F-TOD-26,
   F-ASK-16 … F-ASK-19). Today two windows learn of each other's work by watching `_ai/queue/`,
   `_ai/local/*.window-state.json` and the todo files; in v2 that is the runtime's events and the
   machine-wide state (CR.36 … CR.39).
3. The reverse requests for every ask kind with its process buttons (F-ASK-1 … F-ASK-5), the
   restored ask after a restart (CP.9), the stand-in ask from another runtime of the machine
   (CP.40), opening a document in the MD Browser with buttons (`tomAi_askInMdBrowser`), and the
   host tools (CT.4, CT.5).
4. The assist actions as commands: Grill me / Explain on a question and at a decision, Finish
   review round, gate decision (CP.38; G-11), with the temporary-session rule.
5. Completion data (slash commands, skills, quest files), the model list, the provider SDK
   installation and the binaries' state (G-18; F-TRN-13; F-PRE-3).
6. The migration flow: format stamps, the dry run and report, the pause of the other runtimes
   with the list of running prompts and their interrupt (CP.27 … CP.29; SC-26).
7. The configuration layers read and written through the runtime (CS.1, CS.2, CS.19) and the
   host's settings layer (CP.13).

**Project Idea items affected, checked by search:**

- **RT-HOST (CP.13 … CP.15) and CP.1, CP.14:** CP.1 says "inside VS Code the extension calls the
  runtime directly, with the same commands"; CP.14 that in VS Code the host interface "is
  implemented in the extension's process". CR.40 and CR.42 say the runtime is installed once per
  machine and user and each host starts its runtime from that installation; CR.44 that it ends
  with its host. Not stated: whether the v2 extension loads the runtime into VS Code's extension
  host (in-process, VS Code's Node) or starts it as a process of its own from the installation
  (PQ-37 asks about Node only for hosts that are not VS Code). With "distributed and with a team"
  the runtime has to stay up while a window reloads (today a reload ends a running send:
  user guide *Which build a window runs*), which speaks for a process of its own. **Question for
  the product owner (not in the Project Idea):** in-process or separate process for the v2
  extension?
- **RT-PROTO (CP.1 … CP.12, CP.35 … CP.39):** the list above; CP.12 (a superset of the scripting
  API's methods) and CL.10 (the Dart client grows into the runtime client SDK) cover the scripting
  API (F-TOL-8, F-OTH-2).
- **CR.5 and PQ-35:** what of the quest refresh, the reload prompt, the window level and the
  prerequisites goes into the runtime decides what v2 still does itself.
- **PQ-36 (two hosts on one quest):** today two VS Code windows on one quest are two engines on the
  same files, with a queue item taken over only when the first window's heartbeat is gone; v2 must
  pick one rule, and the inventory rows F-QUE-1, F-QUE-31, F-ASK-8, F-ASK-19 depend on it.
- **The split plan (SCO-IN row "The split", D-40, D-41, DEL, N-32, N-33, R-1, R-2):** D-41 and
  DEL say "the extension is branched; the new line gets its own extension id and is worked on in a
  separate working tree … refuses to start while the old one is active in the same window …
  changes merged forward or repeated". The product owner's plan is a **copy in the `ai_build`
  repository**, not a branch of `tom_vscode`; then merging forward is not possible, only repeating
  the work (R-1's trigger becomes certain for every change during the split). **Proposed text for
  D-41 / DEL:** "The new extension is a copy of the extension in `tom_ai/ai_build`, with its own
  extension id; it refuses to start beside the old one in the same window; changes to the old
  extension during the split are repeated in the copy; the old extension is retired once the new
  one carries every feature of the inventory." Not stated anywhere today: **the retirement of the
  old extension** (search for "retire" finds only Flutter packages and `tom_todo_model`'s writes)
  and **what "all features working" is checked against** (PQ-57 asks the acceptance in general;
  this inventory, with CU.10's screen inventory, is a candidate checklist).
- **D-40 and DEL step 1 ("the VS Code extension's features are finished"):** the open backlog is
  233 todos (210 not started), among them the 76 `caf_*` todos (G-1), the Q&A work
  (`vscimpb182` … `186`), the control items (`vscimpb187`, `188`), the todo analyzer, the tool
  optimisation and `01_aifmt-3` … `-5`, `02_aifmt-1`. **Question for the product owner:** which of
  these belong to "finished" before the copy is made, and which are built only in the runtime?
- **CU.10 … CU.13 (the screen inventory):** the host UI rows here are the input for it; Tom Forge's
  `qavs_ccparity_*` todos are named as its check (CU.10).
- **N-33 ("every stage of the split leaves the extension working"):** with a copy, this holds for
  the copy; the old extension is untouched by the split.

**Could not verify:** whether the engine code is separable along these rows (no code was read);
the live behaviour of the rows marked built (their live checks are open todos); the exact state
of the `caf_*` parts beyond their todos; the usage ledger's prices (F-USG-2) and response values
(F-OTH-15) in code.

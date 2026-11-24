# Inputs from the quest `al_the_bear` for the Project Idea "Tom AI Runtime"

Written 2026-11-20 by a research agent, read-only on everything but this file. It compares the
Project Idea (`../project_idea.ai_runtime.md`, called **PI** below) with what the quest
`al_the_bear` plans and has decided.

**Paths:** `<root>` is the fleet root `al_the_bear` (the folder above the workspace folder that
holds `repos.yaml` and `_ai/`). `_ai/…` is the shared `_ai` clone.

**What was read**

| Read | What it is |
| --- | --- |
| `_ai/quests/al_the_bear/overview.al_the_bear.md`, `short_description…` | the quest's charter |
| `_ai/quests/al_the_bear/ai_format_migration.md` (2026-11-20, "Round 2: everything is decided") | **the plan for the `_ai` folder, the quest folder and quests in repositories**; the main input of sections 1 and 2 |
| `quest-cleanup.md` and `ai_folder_cleanup.md` (removed; read from `_ai`'s history at `41f27d809^`), and round 1 of `ai_format_migration.md` (`41f27d809`) | the reasoning and the options behind the decisions |
| `_ai/quests/al_the_bear/questions.al_the_bear.md` (the entries of 2026-11-20) | the product owner's own words on the quest management tool |
| `todos.al_the_bear.todo.yaml` (67 todos; all open ones outside `bbhc*` / `bomber*` listed, the `*_aifmt-*`, `14_loose_wslayout-4/-5/-6`, `14_loose_maybe_wslayout-1`, `legws1`, `13e`, `12a_wslayout-2` read in full) | open todos |
| `todos-archived.al_the_bear.todo.yaml` (160 todos; the 113 closed since 2026-11-08 listed, about 20 read) | recently archived todos |
| `vscode_extension/todos…`: `00_aifmt-1…3`, `01_aifmt-1…5`, `02_aifmt-1`, `13d_wslayout-1…4` | the extension's half of the same plan (filed by al_the_bear) |
| `workspace_layout_plan.md`, `todo_consolidation.md`, `workspace_layout_and_independent_repos.md` | the plan to the end of the workspace layout migration; the consolidation of loose todos (CG-1 … CG-9, answered 2026-11-20) |
| `<root>/_agent_guidelines/workspace_layout.md`, `quests_and_processes.md`, `retiring_and_archiving.md`; `<root>/workspace_layout_multi.md`, `repos.yaml`, `repo_structure_new.md`, `repo_skills_new.md` (§ 4, § 5.12 … 5.14), `repo_skills_userguide_new.md` § 5, `repo_conciliation_strategy_new.md` § 1 … 2, `root_instructions_reconcile_new.md`, `AGENTS.md` | the layout convention and the fleet's rules, as they are and as they will be after the cutover |
| `ideas/workspace_layout/workspace_layout.docspecs.md` | grep only: it is already the PI's source S12 |

**Three warnings for the reader**

1. **Id collision.** `ai_format_migration.md` has decisions named `CQ-1 … CQ-23`, `AC-n`, `QM-n`,
   `QJ-1`, `MG-1`, `C-1`, `C-2`. They are not the PI's capability ids `CQ.n` and not the `CQ-n`
   answers of the PI's source S1. Below they are written **`ATB CQ-n`**, `ATB AC-n`, `ATB QM-n`.
2. **The PI's section `PAR-QUESTS` rests on an older plan.** Its sources (S2 § 3.7, FO-13, FO-18,
   FO-22; behind them `_ai/quests/vscode_extension/quest_repositories.md`, QR-1 … QR-19, and the
   todos `ai_runtime/ww_e_gitruntime-1 … 11`, all not-started, last changed 2026-11-13) describe
   two quest kinds, a personal repository at `_ai/personal/`, member branches and a
   `<quest>_internal` repository. `ai_format_migration.md` is a week newer, decided on 2026-11-20,
   and is **not among the PI's sources**. It does not mention the older plan and does not say that
   it replaces it. Where the two disagree, the product owner's statement ("the updated and for now
   definite approach … the standard from now on") points at the new document; what is not
   mentioned in the new one (member branches, the internal repository, the secret scan, the
   personal repository, personal notes) is **neither confirmed nor cancelled** by it. These are
   put as questions below.
3. **Decided is not built.** Everything in sections 1 and 2 is decided and filed as todos; none of
   it is built. Phase 0 is not-started; phases 1 and 2 are blocked on the workspace layout cutover
   (`12a_wslayout-2_aksp-cutover-guided`, not-started; the plan stands at stage 11 of 15 today).

---

## 1 The `_ai` restructuring

Source: `_ai/quests/al_the_bear/ai_format_migration.md` § 1 … § 3, § 5, § 7. Status: **decided**
(round 2, "Open questions: None", todos filed 2026-11-20). Not built.

### 1.1 The target layout of `_ai`

`_ai` stays one git repository (`tom_agent_state`), cloned once per machine at the root and
reached from every workspace folder through a relative symlink (unchanged, `repo_structure.md`
§ 5.0). Its top level becomes a closed list:

```text
_ai/
├── .gitignore  .gitattributes  format-version.yaml
├── .githooks/pre-commit          todo-schema guard + allow-list guard
├── processes/  roles/  role-types/  schemas/
├── quests.yaml                   every quest of this _ai: type and setup (new, phase 2)
├── workspaces/
│   ├── <workspace>.yaml          the quest ids a workspace picks (exists; name kept)
│   └── <workspace>.notes.md      the workspace notes (new place)
├── .quest-repos/<repo>.git       bare clones of multi-quest repositories (ignored)
└── quests/
    ├── <folder-quest>/           tracked in _ai, as today
    ├── <single-repo-quest>/      a clone of its own repository (ignored in _ai)
    └── <multi-repo-quest>/       a worktree of branch quest/<id> (ignored in _ai)
```

**What goes from the top level** (phase 0, `al_the_bear/00_aifmt-1`; deleted, nothing archived,
ATB AC-23 (c)): `prompt/`, `clarifications/`, `clarifications_processed/`, `bot_conversations/`,
`trail/`, `tom_brain_trail/`, `copilot/`, `memory/` (first `memory/shared/`, in version 10 all of
it), `notes/`, the overview files under `quests/`, the quests `qw5` and `test_quest`,
`tom_skip.yaml` (once every tool binary skips `_ai` by name, `00_aifmt-4`).

**Consequences for the engine** (ATB § 2.3; `vscode_extension/00_aifmt-3`, `01_aifmt-1`,
`01_aifmt-3`):

- **Memory has one scope, the quest's.** The `shared` scope goes (ATB AC-17).
- **Saved prompts exist only in the active quest's `prompt/`**; the global, project and scan scopes
  go. Message templates, pattern prompts and group prompts stay (ATB AC-4, AC-5).
- **Notes:** quest notes in the quest; workspace notes in `_ai/workspaces/<workspace>.notes.md`;
  the per-machine notes file `~/.tom/notes/global_notes.md` stays; `_ai/notes` goes (ATB AC-11,
  AC-12).
- **Clarification files and `copilot_todos.<quest>.md` go** (ATB AC-18, AC-24): the agent asks with
  the blocking ask tools or puts the question into a todo's decisions; a `TODO:` in a prompt
  becomes a quest todo.
- **Reminders go entirely**: item fields, reminder templates, the reminder tools (ATB AC-22).
- **The Copilot panel, the queue transport `copilot`, the answer wrapper, `tomAi_askCopilot`,
  `tomAi_askBigBrother`, the tools registered as VS Code language-model tools and the `vscode.lm`
  model lists go** (ATB AC-1, AC-3, AC-19; list A). Stored `transport: copilot` becomes
  `anthropic`. The "VS Code LM" transport inside the Anthropic panel is kept until the Copilot SDK
  route works.

### 1.2 The quest folder (the same inside for every quest type)

**Four classes of file** (ATB "CQ classes"):

| Class | What | Tracked in git | Merged between machines |
| --- | --- | --- | --- |
| **A, shared** | the quest's knowledge and plan | yes | yes, with a driver per kind |
| **B, per host** | what one host did; one file per host, written only by that host | yes | never |
| **C, derived on the spot** | built from A and B when needed | no | never |
| **D, machine-local** | raw results, rolling tails, the window's live trail | no | never |

The premise behind it (removed `quest-cleanup.md`): "only a quest's documents and its todo files
need to be shared and merged. Everything else is either a record of what one host did, or derived
from those records when it is needed."

```text
quests/<q>/
  <q>.code-workspace                                            (stays at this depth)
  overview, short_description, references, open_topics, deferred,
  progress, quest_documentation_update, the quest's documents   (A)
  ideas/, designs/, …                                           (A)
  todos.<q>.todo.yaml, todos-archived…, todos-deleted…          (A)
  config/   process-state.<q>[.<run>].yaml, extension_config.<q>.yaml (A),
            extension_config.<host>.<q>.yaml                    (B)
  notes/    quest-notes.md, more notes                          (A, the user's)
  memory/   facts.md … (A), candidates.<host>.md                (B)
  prompt/   saved prompts                                       (A)
  qa.<host>.<q>.md                                              (B)
  history/  trail.<host>.md                                     (B)
            <host>/<session>.session.json                       (B)
            <host>/sessions/<s>/…                               (D)
            compacted_history.md, history.json/md               (C)
  quest_refresh.<q>.md, live trails                             (D)
```

Kind by kind:

- **Todos** (A): `ai-yaml-smart`. The archive is also a source of the history: an archived todo
  gives id, title, status and completed date, description, notes, decisions, references, last
  answer (ATB CQ-22, CQ-23).
- **Process state** (A): `config/process-state.<q>[.<run>].yaml`, shared, merged with
  `ai-yaml-smart` (today plain git) (ATB CQ-1).
- **Quest configuration:** `config/extension_config.<q>.yaml` (A, the same on every machine) and
  `config/extension_config.<host>.<q>.yaml` (B).
- **Sessions are per host** (B): `history/<host>/<session>.session.json` holds definition, state
  and the trail setting. A **required picker "contributes to trail and memory"** when a session is
  created; existing sessions count as on. Off: the session's turns go neither into the host trail
  nor into memory or history (ATB CQ-7, CQ-14, CQ-18).
- **The host's compact trail** (B): `history/trail.<host>.md`, one file per host and quest across
  all of that host's sessions; one block per prompt/answer turn (header: id, time, host, session,
  profile, model; then the prompt and the final answer, no inner steps); the last
  `trail.compact.maxEntries` (2000) turns; a turn is trimmed only once a history covers it. A
  session's trail is a view of it (ATB CQ-3, CQ-4, CQ-13, CQ-16, CQ-21).
- **The Q&A journal** (B): `qa.<host>.<q>.md`: the questions asked of the user (askUser,
  askUserPicker, askInMdBrowser) with the answers, and the answers given with answerUser, one
  block each in time order. Every host's journal is read by the Answers page and the Q&A tool, so
  after a reconcile every host sees every host's questions and answers (ATB CQ-2, CQ-15, QJ-1).
  Today the answers of answerUser are only in VS Code's global storage on one machine.
- **`decisions.<q>.md` is no file any more** (C): rendered from the archived todos' decisions.
- **History is derived** (C): the consolidated trail (all hosts' trails, each turn once),
  `compacted_history.md`, `history.json/md` are built per host from the consolidated trail and the
  todo archive, with a watermark per host and per archived todo; one button "Rebuild history and
  memory"; a notice after a reconcile brought newer turns (ATB CQ-5, CQ-6, CQ-19).
- **Live trail and `quest_refresh.<q>.md`** (D): untracked.
- **Quest memory** moves into the quest: `memory/` with curated facts (A) and
  `candidates.<host>.md` (B, each candidate naming its session), promoted deliberately ("Promote
  memory", a setting, off by default). No session level (ATB CQ-8, CQ-18, AC-15).
- **Notes** (A, the user's): `notes/quest-notes.md` the default, more files beside it. Agents read
  them and never write them.

**Merge drivers** (ATB CQ-17, § 3.5; `al_the_bear/01_aifmt-1`): `ai-yaml-smart` for todos, process
state and the shared configuration; a new **`ai-md-sections`** (merge by `##` heading; a section
changed on one side is taken, one changed on both sides gets a 3-way merge of that section) for
overview, deferred, open_topics, references, short_description, quest_documentation_update,
progress and curated memory; plain git for notes and documents in subfolders; nothing for class B
(one writer). `ai-trail`, `ai-block-history`, `ai-history-json`, `ai-history-md` stay registered
while old files exist, then go. The drivers' source is in the al_the_bear repository
(`.claude/skills/_lib/merge_drivers/ts/`), built into `tom_binaries/merge_drivers/` (AB-12).

**Guards** (ATB § 3.6; `al_the_bear/01_aifmt-2`): `_ai/.githooks/pre-commit` refuses a new
top-level entry of `_ai` outside the list of 1.1, and a new folder or file kind at a quest's top
level outside the layout above (documents and document folders may be added freely).

### 1.3 What is per machine, per workspace, per quest

| Scope | Holds | Versioned |
| --- | --- | --- |
| `_ai` as a whole | processes, roles, role types, schemas, `quests.yaml`, the hooks | yes (`tom_agent_state`) |
| per workspace | `_ai/workspaces/<workspace>.yaml` (the picked quest ids; no file = every quest), `<workspace>.notes.md` | yes, in `_ai` |
| per quest, shared (A) | documents, todos, process state, shared configuration, curated memory, notes, saved prompts | yes: in `_ai`, or in the quest's repository / branch |
| per quest and host (B) | sessions, the compact trail, the Q&A journal, the host configuration, memory candidates | yes, one file per host, never merged |
| per quest, derived (C) | consolidated trail, compacted history, history snapshot, the decisions view | no |
| per machine (D) | raw trail, tool results, rolling tails, live trail, refresh notes, the checkouts of repo-based quests, `.quest-repos/` | no |
| per machine, outside `_ai` | `~/.tom/notes/global_notes.md`; VS Code's global storage | no |

### 1.4 The migration and its status

| Phase | When | What | Todos | Status |
| --- | --- | --- | --- | --- |
| **0 — cleanup** | now | the deletions and ignore lines, the clarification and `copilot_todos` rules, `tom_skip.yaml`, `repos.yaml` descriptions, the compact-trail limit, `tomAi_getWorkspaceInfo include: ["repos"]`, the removed readers | al_the_bear `00_aifmt-1 … 5`; vscode_extension `00_aifmt-1 … 3`; tom_brain `00_aifmt-1` | all not-started |
| **1 — format version 10** | after the workspace layout cutover | the quest folder of 1.2, per-host files, the Q&A journal, derived history, memory, notes, the new driver, the allow-list guard, the Copilot removal, quest-only prompts, the Q&A tool, CHAT LOGS, Recent prompts | vscode_extension `01_aifmt-1 … 5`; al_the_bear `01_aifmt-1`, `-2` | not-started, blocked on `12a_wslayout-2` |
| **2 — quest management** | after phase 1 | `quests.yaml`, the QUEST MANAGEMENT panel, repo-based quests, migrating folder quests, the AI skills on repo-based quests | vscode_extension `02_aifmt-1`; al_the_bear `02_aifmt-1` | not-started, blocked on phase 1 |

**Format version 10** is one step of the extension's `aiFormatMigration`
(`vscode_extension/01_aifmt-5`): it runs "on each host's first window after the update" and is
recorded in `_ai/format-version.yaml`. Per quest folder it moves the process states and
configurations into `config/`, the notes into `notes/`, `_ai/memory/<q>/<session>/*.md` into
`memory/`, renames `questions.<q>.md` to `qa.<host>.<q>.md`, moves sessions into
`history/<host>/`, drops the D files from git, rewrites stored `transport: copilot` and removes
the reminder fields. It is idempotent, has a dry run that lists the moves, and "every reader keeps
finding the old place until the step ran". The current version is 9 (it moved a process a quest
followed on `default` into a run of its own, `quests_and_processes.md` § Runs).

### 1.5 Comparison with the Project Idea

| # | Topic | The PI today | Verdict | Proposed change |
| --- | --- | --- | --- | --- |
| A-1 | The source | `SRC` lists no document of this plan; S12 is the workspace layout only | **missing** | Add `_ai/quests/al_the_bear/ai_format_migration.md` as a source ("the `_ai` and quest-folder format, version 10; quest types; quest management; decided 2026-11-20, not built"), and mark S2 § 3.7 as outdated where the two differ. |
| A-2 | The runtime owns the formats and the migration | CR.1, CR.3, CP.28, CP.29, E-1 ("the format-version stamp … and its migration") | **matches** | CR.3 can name the starting point: the runtime is built on format version 10, the layout of 1.2. |
| A-3 | The four classes A … D | nothing; CW.14 and CA.17 only say that `_ai` state stays on the main branch and is merged by drivers | **missing** | State the classes in `RT > RT-HOLDS` (after CR.2) or `PAR-QUESTS`: shared and merged, per host and never merged, derived, machine-local. It is the rule that decides for every store whether it travels. |
| A-4 | Sessions, trail and history | CR.2 "sessions, trails"; GLO **trail**: "the durable record of what a run did: prompts, answers, tool calls, as files"; CQ.3 puts the session storage, "the live trail, the history and its compacted form" into the personal repository | **differs** | Sessions belong to a host (B, in the quest); the compact trail is one file per host and quest holding prompt/answer turns only; history and its compacted form are derived and untracked; the live trail is machine-local. See Q-3. |
| A-5 | "Contributes to trail and memory", a required choice when a session is created | nothing | **missing** | Add to `RT > RT-QUEUE` / sessions: a session carries this setting; the protocol's create-session command needs it. Relevant for CR.6 (a runtime without a quest) and for sessions on a document marked encrypted (the PI keeps that trail in memory only, line 621). |
| A-6 | The Q&A journal per host, read from every host | nothing on a journal; asks are routed (`RT > RT-ASKS`) | **missing** | Add: every ask with its answer and every answer given to the user is recorded per host and quest (`qa.<host>.<q>.md`); the asks and answers views read all hosts' journals. Question for Phase 2: with tac carrying asks, is the journal the record of asks answered elsewhere too? |
| A-7 | Decisions as a view rendered from archived todos | CA.17 names "the files of questions, decisions and progress" as files written by many sessions | **differs** | CA.17: the decisions file no longer exists; the questions file is per host. Only todos, process state, progress and documents remain "written by many". |
| A-8 | Memory: one scope (the quest), curated facts shared, candidates per host, promotion deliberate | CR.2, CR.5 name memory; no scopes | **vague** | Say it in CR.2: memory is the quest's; candidates are per host and promoted by the user's decision. No shared scope. A runtime without a quest (CR.6) then has no memory: confirm. |
| A-9 | Saved prompts only per quest; notes places | CS.3 puts "prompt templates" into the repository's configuration; SC-16 "Quest notes, workspace notes" | **vague** | Keep CS.3 for templates (they stay); add that saved prompts live in the quest's `prompt/`; name the three notes (quest, workspace, per machine). |
| A-10 | Reminders removed from the queue | E-1 lists "reminders" among the queue's features; CR.19: "it sends timed requests on a schedule and reminders after a wait" | **differs** | Remove queue reminders from E-1 and CR.19 (ATB AC-22: "Reminders go entirely"). The message kind "reminder" of tac (`TAC-KINDS`) is another thing and is not touched by this decision. **Question:** does the runtime carry any reminder after a wait (for an ask nobody answers, `RT-ASKS`)? |
| A-11 | Copilot | O-4, D-7, CS.13: the Copilot chat transport and the VS Code language-model transport are removed; Copilot through direct calls and its SDK | **matches**; one detail differs | ATB AC-19 keeps the "VS Code LM" transport inside the Anthropic panel until the Copilot SDK route works; O-4 removes it outright. A sentence in O-4 ("in the extension it stays until the SDK route works") settles it. |
| A-12 | Clarification files and `copilot_todos` gone; asks block without a timeout | not mentioned (grep: no "clarification") | **confirms** by absence | Nothing to change; S19 / S20 background may still describe them. |
| A-13 | The closed top level of `_ai` and the commit guard | CR.36 … CR.39 do not say where the machine-wide state's files lie | **vague** | State that nothing of the runtime's machine-wide state, the local tac service's store or the inbox lies in `_ai` (the guard would refuse a new top-level entry), or name the entry that is added to the allow-list. See AB-25. |
| A-14 | When the migration runs | CP.29: once per machine, under a file lock, the other runtimes pause; CP.32 / F12: "only when the user confirmed it" | **differs** | `01_aifmt-5` runs it on each host's first window after the update, without a confirmation, and records it in the versioned `_ai/format-version.yaml`. **Question:** is version 10 the last migration run the old way, or does the PI's rule (confirmed, under the machine's lock) already apply to it? Also say how a per-host step (renaming this host's files) is recorded when the stamp is one shared file. |
| A-15 | Timing | D-40: the split starts after the extension's features and the workspace layout are finished; R-15, R-16 | **vague** | R-15 / R-16 should name format version 10 and quest management (phases 1 and 2) as part of "the extension's remaining features": they come after the cutover, which itself is four stages away. |

---

## 2 Quests in repositories

Source: `ai_format_migration.md` § 3.1, § 3.3, § 3.4, § 4, the decisions ATB QM-1 … QM-11, C-1,
C-2; the product owner's request in `questions.al_the_bear.md` (2026-11-20T11:09). Status:
**decided**, phase 2 (after format version 10). Not built: no quest is a repository today, and
`_ai/quests.yaml` does not exist.

### 2.1 Three quest types in one `_ai`

| Type | The folder `_ai/quests/<id>/` is | Tracked in |
| --- | --- | --- |
| **folder** | a folder of `_ai` | `_ai` (`tom_agent_state`) |
| **single-quest repo** (`type: repo`) | a clone of the quest's own repository, at a named branch | that repository; the folder is ignored in `_ai` |
| **multi-quest repo** (`type: multi`) | a worktree of the branch `quest/<id>` of a repository that holds one quest per **orphan branch**; the branches are never merged; `main` holds only a README | that branch; the folder is ignored in `_ai` |

- The three coexist in one `_ai`. Every quest folder has the same inside (1.2), whatever its type.
- A multi-quest repository is cloned **bare** once per machine at `_ai/.quest-repos/<repo>.git`
  (ignored): one object store for all its quests, no checkout of its own (ATB QM-3, QM-4).
- "Every workspace folder reaches the same `_ai` through its link, so a repo-based quest is
  checked out once per machine and every workspace sees the same checkout."
- The 50 existing quests stay folder quests until the user migrates them (ATB QM-11).
- **Not found:** a quest living inside a project's code repository (a folder of it). The single
  type takes "the repository (and branch)", so a branch of any repository can hold a quest, but
  no source says a quest is a subfolder of a project's repository. *Unverified; a question (Q-2).*

### 2.2 How a quest is found: `quests.yaml` and the workspace's list

`_ai/quests.yaml` (schema `.tom/json-schema/ai/quests.schema.json`) holds **every** quest of this
`_ai`, folder quests included, with its type and setup, once (ATB QM-1 (b): "one fact in one
place"):

```yaml
quests:
  - {id: al_the_bear, type: folder}
  - {id: tom_secrets_manager, type: repo, url: git@github.com:al-the-bear/quest_tsm.git, branch: main}
  - {id: webwork, type: multi, repo: quests}
repos:                       # multi-quest repositories; a quest's branch is quest/<id>
  quests: {url: git@github.com:al-the-bear/tom_quests.git}
```

- `_ai/workspaces/<workspace>.yaml` keeps its name and its form (`quests: [<id>, …]`): the ids a
  workspace **picks**, a subset, for an `_ai` shared by several workspaces; no file means every
  quest (ATB QM-2, C-2). `<workspace>` is the name of the window's root folder.
- The resolver order of today stays (`workspace_layout.md` § 4): the workspace's list, else the
  quests recorded for the workspace folder (`workspaceFolder` in the quest layer, written when a
  window opens the quest), else every quest.
- `_ai/.gitignore` gets a **generated block** with the folder of every repo-based quest.
- The complete setup is in versioned files, "so the workspace can be setup identically on some
  other machine" (the product owner's words).

### 2.3 How a quest is bound to a workspace

Unchanged (`workspace_layout.md` § 4): a quest belongs to the workspace folder it is opened
through. Its `<quest>.code-workspace` stays at the top of the quest folder and names `../../..`,
which is the workspace folder because `_ai` is reached through that folder's symlink. The quest id
is the file's name. This holds for a clone and for a worktree alike, since both sit at
`_ai/quests/<id>/`.

### 2.4 The operations (QUEST MANAGEMENT, a view in the extension's @TOM INFO side bar)

The list shows every quest of `quests.yaml`: whether the workspace picks it, its type, and for
repo types the repository, branch and state (missing on this machine, clean, uncommitted, ahead /
behind). A details pane shows the setup, the state and the folder's top-level files.

| # | Action | What it does |
| --- | --- | --- |
| 1 | **New quest** | asks the type. *Folder:* the scaffold. *Single-quest repo:* an existing URL, or a new repository created on GitHub after a confirmation (private, Actions off); clone into `_ai/quests/<id>/`, scaffold an empty branch, commit, push. *Multi-quest repo:* a repository of `quests.yaml`, a URL or a new one; ensure the bare clone, create the orphan branch `quest/<id>` with the scaffold, push, add the worktree. Every time: the `quests.yaml` entry, the pick in `<workspace>.yaml`, the ignore block, the quest's `.gitattributes`, the hooks path; then offer to open the quest's window |
| 2 | **Add an existing quest** | from a single-quest repository (URL, branch) or a multi-quest repository (its `quest/*` branches are listed) |
| 3 | **Pick / unpick** | for this workspace (`<workspace>.yaml`) |
| 4 | **Remove** | "from workspace" (only the pick); for repo-based quests "from this machine" (deletes the checkout; refused with uncommitted or unpushed work). Nothing in git is deleted; a folder quest is only unlisted (ATB QM-8) |
| 5 | **Migrate to a repository** | the selected folder quests, several at once, into a single-quest repository each or into a multi-quest repository as one branch each; history split out with `git filter-repo --subdirectory-filter quests/<id>`; "the folder leaves `_ai` in the same commit that registers it" (ATB QM-5, QM-6) |
| 6 | **Pull / Push / Status** | of the selected repo-based quests; "started by you, never automatic" (ATB QM-10) |
| 7 | **Set up this machine** | clones and adds every repo-based quest of `quests.yaml` that the workspace picks and this machine lacks |
| 8 | **Check and fix** (ATB C-1) | compares the quest folders with `quests.yaml`, `<workspace>.yaml`, the ignore block and the git state and offers a fix per finding: a stray folder (register or delete after confirmation), an entry without a folder (clone or remove the entry), a wrong ignore block (rewrite), a clone on another branch or URL (switch or update the entry), a picked id that is no quest (drop), a folder not in the format of 1.2 (migrate) |

The AI Workspace Quests editor of today merges into this panel.

### 2.5 Merge rules, guards and syncing between machines

- A repo-based quest carries the quest rules of `_ai/.gitattributes` in **its own
  `.gitattributes`**; the panel sets the clone's local `core.hooksPath` to `_ai/.githooks`, so the
  todo-schema guard and the allow-list guard run there too (a local setting, never versioned). The
  merge drivers are registered globally on each machine (ATB QM-7).
- **Between machines** (ATB QM-9, `al_the_bear/02_aifmt-1`): the AI skills (`tom_pull_ai`,
  `tom_push_ai`, `tom_reconcile_ai`, `tom_full_reconcile_ai` / `tom_full_reconcile`,
  `tom_dirty_work`, `tom_fleet_status`, `tom_stash_triage`, `tom_clone`) also walk the repo-based
  quests of `quests.yaml` that the host has: one fetch per multi-quest repository, then a merge
  with the merge drivers per worktree; a single-quest repository like a code repository.
  `tom_clone` and the fleet setup clone the picked ones that are missing. "Snapshot commits in
  repo-based quests follow the `_ai` snapshot rule" (the snapshot skills commit every change;
  a session that wants its own message commits its paths first).
- Everything of 1.2 holds inside a repo-based quest: the per-host files (B) are tracked in the
  quest's repository, one file per host; C and D are ignored there.
- A reconcile stays a step the user starts; the panel's Pull and Push too.

### 2.6 What stays in `_ai`

For a repo-based quest: its entry in `quests.yaml`, its pick in `<workspace>.yaml`, its line in
the generated ignore block, the bare clone under `.quest-repos/` (ignored), and everything that is
not a quest (processes, roles, role types, schemas, hooks). Nothing of the quest's content.

### 2.7 Comparison with the Project Idea (`PAR > PAR-QUESTS`, CQ.1 … CQ.8, D-34, E-14)

| # | Topic | The PI today | Verdict | Proposed change or question |
| --- | --- | --- | --- | --- |
| Q-1 | The kinds of quest | CQ.1: two kinds, **classic quest** and **repository quest** (a clone of the quest's own repository, ignored by the shared repository) | **differs** | Three types: **folder**, **single-quest repo**, **multi-quest repo** (a worktree of an orphan branch `quest/<id>`; bare clone under `_ai/.quest-repos/`). CQ.1's repository quest is the single type. Terms: the new plan says "folder quest" and "repo-based quest"; the glossary has "classic quest" and "repository quest". **Question:** which words does the PI use? |
| Q-2 | A quest inside a project's repository | nothing | **unverified** | No source in al_the_bear describes it; the single type's `branch:` would allow a quest on a branch of a project's repository. **Question for the product owner:** is "a quest in a project's repository" a fourth form (a folder there), the single type with a branch, or not wanted? |
| Q-3 | Personal files | CQ.2, CQ.3, D-34: one personal repository per user, cloned into `_ai`, a folder per quest; in it the session storage (live trail, history, compacted form), session todos, the machine's settings for a quest, the per-machine trail and compaction files, personal notes; "never in a quest's" | **differs** | The new plan has no personal repository. Sessions, the compact trail, the Q&A journal, the host configuration and the memory candidates are class B: **tracked in the quest**, one file per host. History is derived; live trail, raw trail and session todos are machine-local and untracked. **Question (a real choice):** in a quest shared by several people, the per-host files put each member's prompts and answers into the shared repository, which the older decision (QR-1, FO-22: "trails are the one place secrets and personal material land unfiltered") kept out. (a) the new plan holds for every quest and the personal repository is dropped; (b) class B goes into a personal repository for quests shared with others, into the quest for one person's quests; (c) the personal repository stays for personal notes only. The file names are per host, not per user: say also how a host shared by two users, or one user with five hosts, appears. |
| Q-4 | Personal notes | CQ.3: "the personal notes of a quest: notes for the current user only"; CQ.4: quest notes stay in the quest | **partly matches** | Quest notes: matches (`notes/quest-notes.md`, class A, the user's, agents never write). Personal notes per quest: not in the new plan; the per-machine notes file `~/.tom/notes/global_notes.md` is the only private one. Follows from Q-3. |
| Q-5 | One resolver | CQ.5 (flagged `___check here___`: stated only in the superseded S20) | **confirms** | The new plan needs it more: the same path `_ai/quests/<id>/…` for all three types, and "every reader keeps finding the old place until the step ran". Keep CQ.5; its source can be `ai_format_migration.md` § 3.1 ("Every quest folder, whatever its type, has the same inside"). |
| Q-6 | What the runtime provides for a repo-based quest | CQ.6: merge drivers; a branch per member with a review of conflicts; one shared process position moved only on the main branch; a second repository for technical members with encrypted development credentials; a secret scan at commit and publish; member identity and access | **differs / open** | New plan: the quest's own `.gitattributes` with the quest rules, the hooks path to `_ai/.githooks`, drivers registered per machine; **one branch per quest**, merged between machines by the drivers; the process state is class A, merged with `ai-yaml-smart`. It says nothing on member branches, the internal repository, the secret scan or member access. **Question:** are these four dropped, later, or still part of the first version on top of the new types? (A multi-quest repository's "never merged" orphan branches leave no room for a branch per member inside it.) |
| Q-7 | Create, join, migrate | CQ.7 | **matches**, with more | Create = action 1; join = actions 2 and 7 (no "registered as a member" and no personal repository in the new plan); migrate = action 5 (`git filter-repo`, several quests at once, into either repo type). Add: remove from workspace / from this machine (4), pick / unpick (3), pull / push / status started by the user (6), check and fix (8). CQ.7's "a trial migration shows the result before anything is changed" is not in the new plan (*unverified whether dropped*). The direction is one way: folder → repository. |
| Q-8 | Order of migration | CQ.8: the first quest alone, then the quests worked in most | **compatible** | ATB QM-11: the folder quests stay until the user migrates them with the panel. Keep CQ.8. |
| Q-9 | The register | nothing: CR.33 finds "the quests of a workspace: those its list `_ai/workspaces/<workspace>.yaml` names, else those recorded for the folder, else all" | **missing** | Add `_ai/quests.yaml` to CR.33: every quest with type and setup; the workspace's list picks from it; a quest's checkout may be **missing on this machine** (a state the runtime must report, not an error of the store). |
| Q-10 | Who syncs | O-6: reconciles stay a step the user starts; CW.25: a todo reaches another quest "by writing into the quest's repository, or into the shared state repository" | **matches**; vague | Add to CW.25 that a repo-based quest not checked out on this machine cannot be written into here (the todo then goes through tac or waits), and to O-6 that pull and push of a quest's repository are the user's step too. |
| Q-11 | Where it is operated | CQ.7 names operations of the runtime; nothing on a view | **missing** | The plan specifies a view in the VS Code extension. For the PI: the operations 1 … 8 are runtime commands (so Tom Forge's quest application and trc get them), and the view is one of the inventory's screens (`CLI-SCREENS`, a new SC row). **Question:** runtime or host? Creating a GitHub repository and running `git filter-repo` from a runtime on a phone-facing host server (T8) is probably not wanted. |
| Q-12 | New repositories | nothing | **missing** | A repository the product creates (a quest's, a multi-quest one, the coordination repository) is private with GitHub Actions switched off, after a confirmation (ATB QM-5, QM-6; root `AGENTS.md` "No CI on GitHub"). |
| Q-13 | State today | E-14: "No quest is a repository of its own, and there is no personal repository." | **matches** | Still true. Add: `quests.yaml` does not exist; this fleet keeps no `_ai/workspaces/<workspace>.yaml` (`workspace_layout_multi.md` § 2). |
| Q-14 | Claims on a quest's files | CA.17 and the open question after it name parts of the `_ai` state's repository as resources (`al-the-bear/tom_agent_state#quests/ai_runtime/specification/**`) | **vague** | A repo-based quest's files are not in `tom_agent_state`: their resource name is the quest's own repository (and for a multi-quest repository the same repository for every quest, told apart only by branch). The resource name `<owner>/<repository>[#<pattern>]` has no branch. Say how a document of a multi-quest quest is named. |

---

## 3 Further findings

Kinds: **missing** (the PI says nothing), **differs**, **vague**, **confirms**.

**Workspace layout and locations**

- **AB-1 — The default places can be changed, and the PI's resolver does not say so.**
  *Source:* `workspace_layout.md` § 2, § 3, § 5: `.tom/tom_root.yaml` and the optional
  `<workspace>/.tom/tom_workspace.yaml` carry `defaults: {ai, guidelines, config}`; a quest's
  `.code-workspace` may override with `tomAi.layout.root`, `.aiFolder`, `.configFolder`,
  `.guidelinesFolder`; configuration values use `${workspaceFolder}` and `${tomRoot}`.
  *PI:* CR.33 gives fixed names only. *Kind:* missing. *Proposal:* add to CR.33 that the places
  are defaults the two marker files can change, and that a host passes the overrides which a
  `.code-workspace` carries in VS Code (CR.32).
- **AB-2 — Nested cases.** *Source:* `workspace_layout.md` § 7: the nearest root marker wins and
  an inner root inherits nothing; a workspace folder inside another has only its own `.tom` and
  the root's as layers; a window on a plain folder works on the **default quest**; in a
  multi-folder workspace the first folder is the workspace folder; paths keep the form they were
  opened by and are compared by real path. *PI:* CR.33 has the real-path rule only; CR.6 knows an
  instance "without a quest", not a default quest. *Kind:* missing / vague. *Proposal:* one
  sentence per case in CR.33; **question:** is the default quest of a plain folder the same thing
  as CR.6's runtime without a quest?
- **AB-3 — Guidelines have three levels, and may become repositories of their own.** *Source:*
  `workspace_agents.md` § Guidelines (root, workspace, `<project>/_agent_guidelines/`);
  `workspace_layout.md` § 2 (the old name `_copilot_guidelines` is read until
  `vscode_extension/15a_wslayout-1`); `14_loose_maybe_wslayout-1` with the recorded decision "One
  repo for root guidelines, one repo for workspace guidelines, separate per type, aligned manually
  from time to time" (a "maybe", after the cutover). *PI:* CR.33 and E-4: two levels. *Kind:*
  missing. *Proposal:* name the project level in CR.33; note that a guidelines folder may be a
  clone of its own, like `_ai`, so the resolver must not assume it belongs to the workspace
  folder's repository.
- **AB-4 — Configuration layers: the order is confirmed, three details are open.** *Source:*
  `workspace_layout.md` § 5; `vscode_extension/13d_wslayout-1 … 4` (blocked on the cutover): order
  defaults < user-global < root < workspace < quest < quest-host < settings overrides; only the
  root's and the workspace folder's `.tom` are layers; writes go to the root's file until a
  layer-aware editor lets the user pick the layer; the user-global file is
  `~/.tom/vscode/tom_vscode_extension.user.yaml`; the quest layer becomes a general overlay only
  with `13d_wslayout-1`. *PI:* CS.1 matches the order; CS.2 matches the safe write. *Kind:*
  confirms / vague. *Proposal:* say in CS.1 which layer a write goes to by default, and where
  "the user's own file" lies for a runtime that several hosts share (CR.40 puts the installation
  into the operating system's application data folder; the file of today is under
  `~/.tom/vscode/`). **Question:** one user file for all hosts, and where?
- **AB-5 — The record of repositories has kinds the claims and the integration step must
  respect.** *Source:* `repos.yaml`, `workspace_layout_multi.md` § 3, `repo_structure_new.md` § 1:
  kinds `code` (follows its branch), `fork` (its own branch such as `tom/1.1.2-patches`, only
  fast-forwarded), `ai`, `binaries` (latest build wins: `reset --hard` on pull), `upstream`
  (read-only, detached at a pinned SHA, cloned only on the hosts it names); `links:` (the `_ai`
  symlinks); `unmanaged:` (clones a tool owns); an entry's parent is computed; no repository
  records another's commit. `al_the_bear/00_aifmt-5` adds a `description:` per entry;
  `vscode_extension/00_aifmt-2` answers the entries through `tomAi_getWorkspaceInfo`. *PI:* CR.34
  and CW.24 name the file only; CW.5 and the glossary say the integration step fast-forwards "the
  main branch". *Kind:* vague. *Proposal:* CR.34 names the kinds; CW.5 says "the branch the record
  names for the repository"; upstream and binaries entries are never the target of an integration
  step; a repository may be absent on a machine by design (`hosts:`).
- **AB-6 — Where a quest's repositories are recorded is open on both sides.** *Source:*
  `workspace_layout_plan.md`, last table: `vscode_extension/vscimpb154_akqj-short-description-repositories`
  "needs the record of which quest works on which repositories"; `quests.yaml` (2.2) has no such
  field. *PI:* CR.35, CW.8, CW.24: "A quest lists the repositories and subtrees it usually works
  on". *Kind:* vague. *Proposal / question:* name the place: a field of the quest's entry in
  `quests.yaml`, or the quest's shared configuration.
- **AB-7 — Instruction files depend on the working directory.** *Source:* `workspace_layout.md`
  § 6: Claude Code reads `CLAUDE.md` from the working directory and every directory above it,
  `.claude/settings.json` only from the working directory, `.claude/skills/` up to the repository
  root; an `@` import from outside the working directory needs a one-time approval per machine
  (`_ai/quests/al_the_bear/tools/approve_claude_imports.py`,
  `02_bomber_open-349_akri-approve-claude-imports-bomber`); other agents read only `AGENTS.md`;
  the fleet skills load only in a window on the root. *PI:* CR.5 carries "the features of Claude
  Code (skills, subagent definitions, slash commands, instruction files, hooks, plan mode) on
  every transport". *Kind:* vague. *Proposal:* state that an agent transport is started with the
  workspace folder as its working directory, and that for a model transport the runtime collects
  the instruction files by the same rules (root, then workspace folder, imports followed). In a
  working tree of an execution (CW.3) the working directory changes: say that the instruction
  files of the real workspace folder still apply.

**Parallel work, the fleet skills and reconciles**

- **AB-8 — The place and names of execution working trees are already fixed by the fleet
  skills.** *Source:* `11a_wslayout-1_aksp-collab-d1-worktree-fixture` (completed 2026-11-20;
  fixture `.claude/skills/_lib/fixtures/test_worktrees_new.sh`, 34 checks), `repo_skills_new.md`
  § 5.12, § 5.13: run worktrees lie under `<root>/.worktrees/<run>/`, on branches `run/<id>`; the
  new skills skip `.worktrees/`, never take a worktree's `.git` file for a repository,
  `tom_dirty_work` reports uncommitted work in them (so a reconcile holds it), and
  `tom_fleet_status` names an unmerged run branch. *PI:* CW.2, CW.3: a working tree per
  **execution** that "keeps the relative layout of the repositories"; no place, no branch name.
  *Kind:* differs (run against execution) / missing. *Proposal:* name `.worktrees/` in CW.3.
  **Question:** one tree per run (as the skills' fixture has it) or per execution (the term
  agreed in S21, TQ-4)? The skills' fixture should follow whatever the PI says.
- **AB-9 — The automatic update needs its trigger and the rule's wording.** *Source:*
  `14_loose_wslayout-5_akto-reconcile-rule-auto-update-exception` (not-started; a blocker of
  `ai_runtime/ww_f_collab-5`): "a workspace may opt in to fast-forwarding its unclaimed
  repositories (fast-forward only, clean trees without unpushed commits, when a claim is taken or
  the user asks); nothing else changes, no schedule." *PI:* CW.16 has the conditions and the
  opt-in per workspace, but not when it happens. *Kind:* vague. *Proposal:* add "when a claim is
  taken or the user asks; never on a schedule" to CW.16; O-6 gets this as its second exception.
- **AB-10 — "A skill commits only what it made"; `_ai` is the exception.** *Source:* root
  `AGENTS.md`; `repo_skills_new.md` § 5.12; `reconcilework1`, `reconcilework2` (completed
  2026-11-13): a reconcile or push that meets uncommitted work stops with exit 3 and one decision
  document that the agent shows the user; the `_ai` snapshot skills commit **every** change in
  `_ai`, so a session commits its own paths first (`git commit --only -- <paths>`); no
  `git stash`, no tree-wide discard in a shared clone. *PI:* P-9 names the problem; CW.14 says
  the `_ai` state is "written file by file"; nothing says who commits and pushes `_ai` or a
  quest's repository. *Kind:* missing. *Proposal / question:* does the runtime commit the `_ai`
  files it writes (by path, with a message), or does it only write and leave committing to the
  snapshot and the user? For repo-based quests the plan says snapshots as in `_ai` and push by the
  user.
- **AB-11 — The skills must be able to ask a runtime process, not a VS Code window.** *Source:*
  `repo_skills_new.md` § 4: the `_ai` skills merge in place while agents run; before a merge they
  look for file handles "the VS Code extension host holds"; `12a_wslayout-2` step 1 quiets the
  work by checking for VS Code processes. *PI:* CW.13: a sync asks tac who holds what and can ask
  a runtime to pause its queue; E-17 names al_the_bear as waiting for this. *Kind:* confirms, with
  a gap. *Proposal:* note in R-15 or E-17 that the fleet skills have no todo yet for asking tac
  and for recognising a runtime process (no such todo in `todos.al_the_bear.todo.yaml`); and that
  a runtime must cope with `_ai` files changing under it after a merge (no file is moved; the
  next write trims).
- **AB-12 — The merge drivers belong to al_the_bear and come from the binaries layer.** *Source:*
  `tsmergedrivers1_akqh` (completed 2026-11-18), the product owner's decision: "The merge drivers
  should actually be under al_the_bear control and reused in the extension … place them in a
  folder merge_drivers in tom_binaries and both the vscode extension build and al_the_bear
  skills/script take them from there." Source `.claude/skills/_lib/merge_drivers/ts/`, bundle
  `tom_binaries/merge_drivers/ai_merge_drivers.cjs`; Node is required on every host, no fallback;
  `vscode_extension/vscimpb152aaa_akqp-extension-takes-merge-drivers-from-tom-binaries` is open.
  *PI:* E-5 lists "Merge drivers for the `_ai` files in TypeScript" as built in the extension;
  CQ.6: "the runtime provides: the merge drivers". *Kind:* differs. *Proposal:* E-5 and CQ.6: the
  drivers are built from the fleet's source into the binaries repository; the runtime registers
  them on a machine and does not own them. **Question:** does their source move into the
  runtime's package when the engine is extracted, or stay with the fleet?
- **AB-13 — Checks at the integration step against "checks are started by a person".** *Source:*
  `workspace_agents.md` § General Rules: "Build, test and check steps are started by a person
  and run straight from the cloned repository. Never schedule one"; a long-running product service
  is exempt ("the service is product runtime, no build or check timer", `14_loose_wslayout-6`).
  *PI:* CW.6: the integration queue "runs the checks the repository declares" mechanically; CW.1:
  no build server. *Kind:* vague. *Proposal:* a sentence in CW.6 that these checks run on the
  machine of the execution, as part of an item a person queued, and are no scheduled or hosted
  check; the fleet rule then needs its exception written (an al_the_bear todo, like
  `14_loose_wslayout-5`).
- **AB-14 — Fleet rules a runtime must not break (confirms O-6).** *Source:* root `AGENTS.md`,
  `repo_skills_userguide_new.md` § 5, `root_instructions_reconcile_new.md` § 1.3: an agent never
  converges a host (no reconcile, no `git pull`, no fast-forward of a peer); one driver at a time,
  mbp, else bigbeast, and after the cutover "there is no lock to stop a second driver"; no push
  while a reconcile runs; a clone under the root that is no entry of `repos.yaml` stops a
  reconcile; generated files and application lock files are never line-merged; never
  `git clean -ff` or `-x` in a parent of nested clones. *PI:* O-6 confirms the first; nothing on
  the others. *Kind:* confirms / missing. *Proposal:* CW.13 can say that a fleet reconcile itself
  is something tac shows ("a reconcile runs, driven from mbp"), which replaces the lock the new
  skills no longer have; the integration step's push (CW.5) must wait while one runs.
  **Question:** is "a reconcile is running" a lease, or only shown?

**Coordination repository, tac server, fleet, phones**

- **AB-15 — The coordination repository: its name and its token rule.** *Source:*
  `14_loose_wslayout-4_akto-coordination-repo-and-tokens` (not-started, blocked on the cutover; a
  blocker of `ai_runtime/ww_f_collab-4`; parked by `todo_consolidation.md` CG-6):
  `al-the-bear/tom_coordination`, private, Actions off; on every fleet host a **fine-grained token
  scoped to that one repository** (contents read/write), "never an account-wide key or classic
  token", kept in an environment file readable by the user only or in the host's secret store,
  "in the environment variable the backend reads"; the group name `al-the-bear-fleet`. Checked
  2026-11-13: the repository does not exist. *PI:* CA.26, U-11, R-20, E-17 name the repository;
  nothing on how the GitHub backend authenticates. *Kind:* missing. *Proposal:* add to CA.26 that
  the GitHub backend's credential is a secret reference like every other (CS.7) and has rights on
  the coordination repository only. This differs from the todo's environment variable:
  **question** which holds.
- **AB-16 — The tac server on the always-on machine: the fleet's todo and the PI disagree in
  three points.** *Source:* `14_loose_wslayout-6_akto-coordination-server-on-bigbeast` (blocked on
  `ai_runtime/ww_g_collab-2` and the cutover; written 2026-11-13, before the relay and accounts
  were decided): a systemd unit running the package's `serve` **from bigbeast's clone**,
  reachable **on the VPN only** by binding to `10.8.0.1`, under a system user of its own without
  login shell or SSH keys, keys from an environment file (mode 600) outside the repository,
  updated by hand, no timer; firewall rules change only on the user's explicit instruction.
  *PI:* CA.27 … CA.30, T4, T5, T8: the tac server with accounts, a public address for the relay
  and paired devices, TLS at a reverse proxy; N-29: what a tac server installs comes from the
  binaries repository; CS.9, D-19: it is approved by Tom Secrets Manager. *Kind:* differs.
  *Proposal:* the PI should state the deployment expectations (installed from the binaries
  repository or run from a clone; its own system user; secrets by reference or an environment
  file; a VPN-only listener plus a public one behind the reverse proxy for the relay), so that
  the fleet's todo can be rewritten against it. bigbeast's Apache already has a `ProxySite
  <domain> <port>` macro for HTTP and WebSocket with certbot certificates and DNS / certificate
  checks, built for the Tom Secrets Manager relay at `tsmrelay.tomspecs.dev` (`tsmfleet3`,
  `tsmfleet9`, `tsmdns1`, completed 2026-11-12): that is the reverse proxy of CA.28, existing.
- **AB-17 — The fleet as it is (confirms T3, N-27).** *Source:* `repo_structure_new.md` § 2,
  § 2.2: four hosts — mbp (macOS, `darwin-arm64`), bomber (Linux, often offline, not part of the
  cutover), bigbeast (Linux, always online, also serves the websites and the VPN), legiondary01
  (Windows, PowerShell as default shell, commands wrapped in Git Bash); one OpenVPN network
  `10.8.0.0/24`, hosts addressed by VPN address; every fleet skill refuses to start when the VPN
  is down on its machine; an unreachable host fails the run. `vpnhang1` (2026-11-14): mbp's VPN
  was down for about 7.5 hours unnoticed. *PI:* T3, T4, N-27, CA.32. *Kind:* confirms.
  *Proposal:* a risk row or a trigger for CA.32: the VPN of one machine fails for hours, so the
  tac client's recovery and what the user is shown meanwhile matter in daily use; a machine that
  is offline for weeks (bomber) meets newer formats when it returns (CP.28).
- **AB-18 — Phones and the VPN: nothing exists in al_the_bear.** *Source:* grep over the quest's
  documents and todos for phone, tablet, iPhone, Android: no todo, no document (only a private
  note on a "nagging app"). *PI:* CK.12: "Whether the VPN can be used from an iPhone and from an
  Android device is checked"; T8; CI.18 pairing. *Kind:* missing on the fleet's side. *Proposal:*
  CK.12 names who checks it (the quest `al_the_bear`, its system administration pillar) and R-20
  or a new dependency row lists it; a todo there would be filed when the PI is accepted.
- **AB-19 — Windows: path length and symlinks.** *Source:* `legws1_aktp-legiondary01-root-to-c-ws`
  (not-started; the product owner's decision of 2026-11-20): the root on legiondary01 moves from
  `C:\Code\al_the_bear` to `C:\ws`, because MSVC's compiler is not long-path aware and a Flutter
  Windows build failed at 261 and 272 characters; `repo_structure_new.md` § 5.0: on Windows the
  `_ai` links are native directory symlinks with backslash targets. *PI:* CW.3: a working tree of
  an execution keeps the relative layout of the repositories; N-27; CR.33's real-path comparison.
  *Kind:* missing. *Proposal:* a risk: a working tree under `.worktrees/<run>/` lengthens every
  path by the tree's prefix, and Windows builds are already at the limit; the place and the names
  of the trees must be short, or configurable per machine.
- **AB-20 — The binaries layer (confirms N-29, D-56; three details).** *Source:*
  `repo_structure_new.md` § 4, § 2.2; `binlic1`, `binpriv1`, `binclone1` (completed 2026-11-09 …
  12); the container's `tool_dependencies.md`: `tom_binaries` is **public** since 2026-11-09; it
  takes only binaries whose licence is not copyleft, each mapped in its `LICENSE` to package,
  source repository and licence; platform folders `darwin-arm64`, `linux-x64`, `win32-x64`; one
  elected builder per platform, builds started by the user (`tom_create_all_binaries`); "latest
  build wins"; `$TOM_BINARY_PATH` is `tom_binaries/tom`; nothing is installed under `~/.tom/bin`.
  *PI:* N-29, D-56: the runtime, the tac service and the client SDKs of other languages are
  published "to the workspace's binaries repository"; CR.40 … CR.42: a host carries a runtime and
  installs it. *Kind:* confirms / vague. *Proposal:* say (1) that every third-party package bundled
  into the runtime's payload must be non-copyleft, since the repository is public; (2) how a
  machine without the workspace (a team member's, the always-on machine) gets the payload: from
  the public repository directly, or only inside a host's installer; (3) that the runtime's
  payload is built per platform on the fleet's builders by the same user-started build.
- **AB-21 — No continuous integration, and new repositories are created with it switched off.**
  *Source:* root `AGENTS.md` "No CI on GitHub" (`repo_structure.md` § 11); the one exception is
  the Tom Secrets Manager's vault repositories (history compaction only, `tsmfleet1`). *PI:* CW.1
  "without a build server"; CW.17. *Kind:* confirms. *Proposal:* none beyond Q-12.

**Rules of the workspace the runtime touches**

- **AB-22 — Retiring a quest.** *Source:* `retiring_and_archiving.md`: before a quest folder, a
  role or a process is removed, its last state is copied into the private repository
  `tom_archived` (cloned beside the root, on mbp only, not synced by the fleet skills); a retired
  quest says `**Status:** RETIRED` in its overview; todos have their own `-archived` / `-deleted`
  files. ATB QM-8: removing a quest deletes nothing in git. *PI:* nothing on the end of a quest
  (grep: no "retire", no "archive"). *Kind:* missing. *Proposal:* one capability in `PAR-QUESTS`
  or `RT-HOLDS`: a quest is retired by a marked state, never by deleting it from a tool; removing
  it from a machine or a workspace is separate (2.4, action 4).
- **AB-23 — Scratch files.** *Source:* `workspace_agents.md` § Scratch folders: never `/tmp`;
  every workspace root has a gitignored `ztmp/`, entries named `<quest>_<yymmdd>_<todo-id>[_<what>]`,
  nothing there outlives one todo. *PI:* CR.4: a registry of cleanup tasks for "temporary files,
  stale records". *Kind:* vague. *Proposal:* CR.4 names the scratch place of a workspace and that
  the runtime's own temporary files and its tools' follow the naming, so the registry can remove
  an entry when its todo is done.
- **AB-24 — Todo ids, renames and the commit guard.** *Source:* `workspace_layout_plan.md`
  ("The todo ids are the plan": a number per stage, a letter per lane, `blocked_by` inside a
  group, `[you]` for a step only the user starts); `todo_consolidation.md` CG-9; the rename tools
  keep a cancelled stub of the old id in the `-deleted` file "for the `_ai` commit guard (an id
  may not vanish)"; `_ai/.githooks/pre-commit` runs the todo-schema guard. *PI:* CR.19 walks a
  group lowest number first; CR.2 todos with groups and blockers. *Kind:* confirms / missing.
  *Proposal:* add to CR.2 that a todo id never disappears (a rename leaves a stub) and that what
  the runtime writes must pass the repository's commit guards, in `_ai` and in a repo-based quest
  alike (2.5).
- **AB-25 — Where the runtime's machine-wide state lies.** *Source:* 1.1 and the allow-list guard
  (`01_aifmt-2`); today's places outside `_ai`: `~/.tom/vscode/…user.yaml`, `~/.tom/notes/`, VS
  Code's global storage (the answers of answerUser, `…/answers/<workspace key>/<id>.json`); the
  process monitor's installer uses `~/Library/Application Support/Tom/bin/`
  (`quests_and_processes.md`), the same family as CR.40. *PI:* CR.36 … CR.39 name the state and
  its two implementations, not its place. *Kind:* vague. *Proposal:* name the place (the
  application data folder of CR.40, beside the runtime), and say that the answers store moves out
  of VS Code's storage into the per-host Q&A journal (A-6).
- **AB-26 — Git settings of a quest's window for a tree of independent clones.** *Source:*
  `09a_wslayout-4_aksp-code-workspace-git-settings` (completed 2026-11-20),
  `ws_migration/code_workspace_git_settings.md`: the decided settings (`openEditors`, scan depth 0)
  do not show a nested clone's repository, because the parent's generated ignore block makes VS
  Code treat the file as ignored; a decision between scan depths was put to the user (its outcome
  was not read: *unverified*). *PI:* nothing; the extension as a host is out of scope (O-1).
  *Kind:* confirms the scope. *Proposal:* none for the PI; for the runtime it means "which
  repository does this file belong to" is answered from `repos.yaml` (CR.34), never by asking the
  parent repository.
- **AB-27 — What the PI's dependency row R-15 should say today.** *Source:*
  `workspace_layout_plan.md` (as of 2026-11-19, todos moved on 2026-11-20): done are the migration
  tool, the rename to `_agent_guidelines`, the new skill library and most `_new` skills (stages 07
  … 10 and `11a-1`, `-2`); in progress `11a_wslayout-3` (Windows test rounds); open are the
  cutover (`12a-1`, `12a-2`, guided, started by the user, mbp, bigbeast and legiondary01 in one
  sitting, bomber later), the retirement of the wrapper repositories (`13a`), documents and checks
  (`13b`, `13c`), the layer-aware configuration editor (`vscode_extension/13d-1 … 4`), the later
  cleanup "some weeks after" (`14a`), and the extension dropping the old guidelines name (`15a`).
  After the cutover follow `_ai` phases 1 and 2 (A-15) and the parked coordination todos
  (`14_loose_wslayout-4 … 6`). *PI:* R-15: "the migration of the workspace, the new fleet skills
  and the cutover are open"; R-20. *Kind:* differs in state. *Proposal:* update R-15 (the new
  skills are written and tested on two hosts; the cutover and what follows are open) and add the
  order: cutover → format version 10 → quest management → coordination repository and tac server.

---

## Summary of counts

- Section 1: 15 comparison rows (A-1 … A-15).
- Section 2: 14 comparison rows (Q-1 … Q-14).
- Section 3: 27 further findings (AB-1 … AB-27).

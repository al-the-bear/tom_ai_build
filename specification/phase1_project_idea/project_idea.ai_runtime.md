# Project Idea — Tom AI Runtime

## <!--[ABOUT]--> 0 About this document

| | |
| --- | --- |
| **Artifact** | Phase 1 Project Idea (PI) of the TomSpecs project flow (`tom_specs_project_flow.md`, `PF-PHA-P1`) |
| **Product** | Tom AI Runtime (tar), Tom Agent Coordination (tac), Tom Runtime Control (trc), {~~the client SDKs and the Flutter UI components~>the client SDKs, the web runtime service with its client SDK, and the Flutter UI components~~} |
| **Spec root** | `tom_ai/ai_build/specification/` |
| **Product owner and review team** | alexis, product owner and only reviewer (`USR > USR-TEAM`) |
| **Sources** | section 1 (`SRC`); the three main ones are kept as snapshots in `sources/` |
| **Written by** | `agent_spec_author` |
| **Status** | Terminology agreed and taken in (2026-11-20, S21). {~~Question round 2 closed: every answer of `PQ-1` … `PQ-23` is in the text, and the text was read as a whole against the answers. Question round 3 (the terminology pass) brought the whole text to the agreed terms; its questions `PQ-24` … `PQ-33` are open~>Every answer of `PQ-1` … `PQ-33` is in the text. The text is completed from the quests `vscode_extension`, `webwork`, `tom_forge` and `al_the_bear` (S22 … S27) and read as a whole for consistency. Open are the questions from `PQ-34` on, each standing after the item it asks about; among them what serves applications on phones, on tablets and in browsers: PQ-28 gave its names, not its design~~} |
| **Next phase** | Phase 2 Solution Blueprint |

The document states the idea as it stands. It is free-form Markdown; the
Solution Blueprint cites it by the ids below. Paths are relative to the
workspace folder (the folder that holds `tom_ai/` and the `_ai` entry) unless
they start with `sources/`, which is beside this document.

### <!--[ABOUT-READ]--> 0.1 How to read it

| Marker | Meaning |
| --- | --- |
| **`S<n>`** | A source the idea was drawn from (section 1). |
| **`V-<n>`** | A statement of the vision: what the system is to give (section 2). |
| **`U-<n>`** | A user group or stakeholder (section 3). |
| **`C<area>.<n>`** | A capability statement, stated or confirmed by the product owner. Phase 2 turns these into requirements with sources. |
| **`N-<n>`** | A non-functional expectation. |
| **`D-<n>`** | A decision of the product owner (section 12), with the id it had in its source. |
| **`X-<n>`** | A contradiction found between sources, and how it was resolved (section 13). |
| **`R-<n>`** | A risk, with what would trigger it, or a dependency (section 14). `R-1` to `R-14` and `R-22` to `R-24` are risks, `R-15` to `R-21` dependencies. |
| **`O-<n>`** | Something out of scope (section 5). |
| **`L-<n>`** | A feature deferred to later (section 5). |
| **`E-<n>`** | A fact about what exists today (section 6). |
| **`P-<n>`** | A problem the product solves: of the vision (section 2.1, `P-1` to `P-4`) and of parallel work today (section 10.1, `P-5` to `P-14`). |
| **`SC-<n>`** | A row of the screen inventory: a screen of the extension, or a new screen, with what it becomes (section 8.3). |
| **`G-<n>`** | A generation unit: a package or application the project builds (section 11.2). |
| **`T<n>`** | A network topology (section 11.1). |
| **`F<n>`** | A key flow (section 11.1.1). |
| **`PQ-<n>`** | A question to the product owner, standing after the statement it asks about. {~~`PQ-1` to `PQ-23` are answered and taken into the text; their answers are cited as sources (`PQ-7`) and kept in `01_02_Questions Round/answers.md`. `PQ-24` to `PQ-33` are the open questions of round 3.~>`PQ-1` to `PQ-33` are answered and taken into the text; their answers are cited as sources (`PQ-7`) and kept in `01_02_Questions Round/answers.md` (`PQ-1` to `PQ-23`) and `01_04_Questions Round/answers.md` (`PQ-24` to `PQ-33`). The questions from `PQ-34` on are open.~~} |

After a statement, its source stands in brackets: the source id and the place
in it, e.g. `(S1 § 7.3, DQ-2)`. `CQ-n`, `DQ-n` and `WQ-n` are the product
owner's answers in S1 § 14.1, `FO-n` those in S2 § 5, `WR-n` the requirements
of S3. A section is referred to by its id chain, outer first
(`TAC > TAC-PEOPLE`).

{++Further ids from inside a source are explained in the row of that source in
section 1: `TQ-n` and `C-n` (S21), `IDEA-n`, `BP-n` and `part-…` (S6),
`DPMESSAGING-n` and `DPPHONE-n` (S13, S25), the notes a … n (S4), `RT-n` (S19)
and `RS-n` (S18), which stand only in the lead-in of `DEC`. The standard for
the `_ai` format is cited as `S22 § n` or `S22 AC-n`: its own ids (`CQ-n`
among them) collide with ids of this document and are never written without
`S22`. A todo id after one of the sources S23, S25, S26 or S27
(`vscimpb146`, `13_woneb5`) names a todo of the quest that source belongs to:
a completed todo is built behaviour, an open one a plan.++}

Capability areas: `CR` runtime core · `CP` protocol and hosts · `CT` tools and
MCP · `CA` coordination between runtimes · `CI` people, teams and identity ·
`CM` messaging · `CV` documents and review · `CW` parallel work and
integration · `CL` client SDKs · `CU` UI components · `CK` supervision ·
`CQ` repository quests and personal files · `CS` secrets, configuration and
providers.

## <!--[SRC]--> 1 Sources

The idea is drawn from the sources below. {~~Where two of them disagree, S1 wins;~>An answer of the product owner to a question of this document (a `PQ` id) wins over every source, S1 included; S1 does not hold those answers. For the `_ai` folder and for quests in repositories S22 is the standard: S2 § 3.7 and S12 hold only where S22 says nothing. Otherwise, where two sources disagree, S1 wins;~~}
S1 § 2.4 lists what is outdated in the older ones.

| Id | Source | Holds | Standing |
| --- | --- | --- | --- |
| **S1** | `_ai/quests/ai_runtime/ai_runtime_concept.md`; snapshot `sources/ai_runtime_concept.md` | The concept: status, what the other quests bring, the system, runtime, protocol and hosts, coordination and messaging, topologies, flows, parallel work, the client SDKs and UI, the deliverables, and the product owner's decisions CQ-1 … CQ-20, DQ-1 … DQ-13, WQ-1 … WQ-4 (§ 14.1) | current; the main source |
| **S2** | `_ai/quests/ai_runtime/ai_runtime_feature_overview.md`; snapshot `sources/ai_runtime_feature_overview.md` | Components and their main features; the decisions FO-1 … FO-22 (§ 5) | current in its decisions; outdated in § 3.1 (the layout resolver is built, the guidelines folder and the configuration layers differ), in the todo model's version, and where it says a host provides no tools{++; § 3.7 (quests in repositories, personal files) is outdated where S22 differs++} |
| **S3** | `_ai/quests/ai_runtime/webwork_requirements.md`; snapshot `sources/webwork_requirements.md` | What Webwork needs from tar and tac, WR-1 … WR-7, each with what exists and what is missing | current as a requirement statement; WR-2 and WR-6 are met differently (S1 § 7.10) |
| **S4** | `_ai/quests/ai_runtime/quest-notes.ai_runtime.md` | The product owner's notes: the names tar, tac, trc, the goals a … n{++ (cited as "note a" … "note n")++}, the split of the MCP server, the relay | current; the product owner's words |
| **S5** | `tom_ai/vscode/tom_tac_service/doc/tac_specification.md` | The protocol `tac/1.0` as built: records, lease lifecycle, operations, backends, errors, the HTTP / WebSocket and GitHub refs bindings | current for what is built; it knows no users, teams, user messages or documents, and names a quest `agent_coordination` as the quest it belongs to |
| **S6** | `_ai/quests/ai_runtime/ideas/agent_collaboration/agent_collaboration.docspecs.md` | The coordination idea: todo follow-ups, protocol, service, tac client and backends, claims, branches and worktrees, messages between runtimes, endpoints, the Coordination page, the guideline, the rollout{++. Its ids: `IDEA-n` and `BP-n` are the decisions of its idea and blueprint rounds; `part-claims`, `part-messages` and the other `part-…` names are its sections++} | current for leases, messages between runtimes, endpoints and branches; outdated in the quest it names as the one it belongs to, its package places and where it describes submodule pointers |
| **S7** | `_ai/quests/ai_runtime/llm_providers_runtime_integration.ai_runtime.md` | Model providers and the three ways into them | current |
| **S8** | `_ai/quests/ai_runtime/ideas/remote_control_app/remote_control_app.docspecs.md` | The supervision application in the product owner's words | current; input only |
| **S9** | S1 § 15 "Research: what other teams do" | External research read on 2026-11-18, with its links: client and agent protocols, parallel work and git models, spec-driven work, cloud agents, UI kits, supervision, secrets | current; some claims rest on secondary sources, marked there |
| **S10** | `_ai/quests/tom_specs/tooling/notes_ai_runtime.md` | The components and interfaces of this quest as the TomSpecs tooling sees them, and the contradictions it found | outdated in package names and places; useful as a cross-check |
| **S11** | `_ai/quests/tom_specs/tooling/tom_specs_tooling_suggestions.md` | Suggestions addressed to this product: one review component for every host, review copies that travel without the user, the process engine as a runtime service, the remote control | current |
| **S12** | `_ai/quests/al_the_bear/ideas/workspace_layout/workspace_layout.docspecs.md` | The workspace layout: root, workspace folders, the layout resolver, the configuration layers, independent repositories, the repository record | current{++ for the layout; outdated for the `_ai` folder and the quest folder where S22 differs; the layout as it is being built is in S27++} |
| **S13** | `_ai/quests/webwork/ideas/webwork_redesign/webwork_redesign.docspecs.md` | Webwork's redesign: messaging, the review exchange, the bottom panel with the AI tab, the wave plan{++. Its decisions are cited by their ids there: `DPMESSAGING-n` on messaging, `DPPHONE-n` on the builds for the phone and the web++} | current |
| **S14** | `_ai/quests/tom_forge/spec_quest_workbench.tom_forge.md` | Tom Forge's quest application: the views it expects, hosting a runtime per open quest | outdated in the runtime's name and the quest it belongs to; {~~its second part waits for this specification~>its second part (chapters 5 … 10) is a placeholder that waits for this specification~~} |
| **S15** | `tom_ai/secrets_clients/protocol/protocol.md` and `_ai/quests/tom_core/ideas/tom_secrets_manager/tom_secrets_manager.docspecs.md` | Tom Secrets Manager: its client protocol, the reference grammar, how one of its clients is identified and approved | current |
| **S16** | `_agent_guidelines/parallel_work.md` | The rules for working in parallel today, and what enforces each | current; names a quest `agent_coordination` as the quest they will belong to |
| **S17** | `tom_ai/vscode/tom_vscode_extension/`: its code, `tom_ai/vscode/tom_vscode_extension/_agent_guidelines/architecture.md` and `tom_ai/vscode/tom_vscode_extension/doc/`{++ (among it `user_guide.md`, `llm_tools.md`, `multi_transport_prompt_queue_revised.md`, `md_browser_page_protocol.md`)++} | The engine as built: the starting point of the runtime and of the UI components | current; it keeps changing |
| **S18** | `_ai/quests/ai_runtime/runtime_split_plan.ai_runtime.md` | What comes before the split of the extension; the stable build during it{++; its questions are `RS-n`++} | its questions are settled in S1 § 14.1 |
| **S19** | `_ai/quests/ai_runtime/quest_runtime_design.ai_runtime.md` | The first runtime design: host interface, process model, stages{++; its decisions are `RT-n`++} | outdated in package place and name, locations, host transports, Telegram and its measurements; background only |
| **S20** | `_ai/quests/ai_runtime/ai_runtime_project_idea.md` | The first collection of the idea | superseded by S1; background only |
| **S21** | `_ai/quests/ai_runtime/ai_runtime_terminology.md` | The agreed terminology: every term with its meaning, the words not used, and the product owner's answers TQ-1 … TQ-11 on them (its § 4){++, with the further changes agreed beside them, `C-n` in the same table++} | current; the glossary (`GLO`) is taken from it |
| {++**S22**++} | {++`_ai/quests/al_the_bear/ai_format_migration.md`++} | {++The `_ai` folder and the quest folder in format version 10; the four classes of files; the three quest types with the register `_ai/quests.yaml`; the quest operations; the migration in three phases. Decided 2026-11-20, not built. Its own decision ids (`CQ-n`, `AC-n`, `QM-n`, `QJ-1`, `MG-1`) are cited with the source, as `S22 § n` or `S22 AC-n`++} | {++current; the standard for the `_ai` folder and for quests in repositories, named so by the product owner (answer to PQ-24). Where it differs from S2 § 3.7 and S12 it wins, except for what a decision of this document backs and an open question names (`PAR > PAR-QUESTS`, CQ.2, CQ.6)++} |
| {++**S23**++} | {++`_ai/quests/vscode_extension/todos.vscode_extension.todo.yaml`, `todos-archived.vscode_extension.todo.yaml` (the todos completed 2026-11-10 … 2026-11-20) and `progress.vscode_extension.md` (the entries of 2026-11-19 and 2026-11-20)++} | {++What the extension's engine does today and what is planned for it, cited by todo id (`vscimpb…`, `qrun…`, `gsel…`, `…_aifmt-…`, `ccparity_…`)++} | {++state of 2026-11-20; a completed todo is built behaviour, one not started is a plan++} |
| {++**S24**++} | {++`_ai/quests/vscode_extension/role_and_guideline_selector.vscode_extension.md`++} | {++The design of roles and aspect guidelines per todo, item, run and window (its ids R-1 … R-4, A-1 … A-5, L-1 … L-8, cited with the source)++} | {++current (2026-11-20); built in part++} |
| {++**S25**++} | {++`_ai/quests/webwork/todos.webwork.todo.yaml` (the groups `12a_woneb…`, `13_woneb…`, `14_woneb…`, `qavs_…`), `_ai/quests/webwork/webwork_wave1_plan.md`, `_ai/quests/webwork/md_browser_probe.webwork.md`++} | {++What Webwork plans on the runtime and tac beyond S3 and S13, cited by todo id and by Webwork's decision ids (`DPPHONE-n`, `DPMESSAGING-n`)++} | {++state of 2026-11-20; plans of another quest++} |
| {++**S26**++} | {++`_ai/quests/tom_forge/todos.tom_forge.todo.yaml` (the groups `qavs_…`, `later23`, `later25`, `05b_woneb…`, `wwkit…`), `_ai/quests/tom_forge/decisions.tom_forge.md`, `_ai/quests/tom_forge/tom_forge_componentization.md`++} | {++What Tom Forge plans on the runtime beyond S14: hosting runtime processes, its view packages, the review component, a server side for repository quests in a web build++} | {++state of 2026-11-20; plans of another quest++} |
| {++**S27**++} | {++`_ai/quests/al_the_bear/todos.al_the_bear.todo.yaml` (the `…_aifmt-…` and `…_wslayout-…` todos), `_ai/quests/al_the_bear/workspace_layout_plan.md`; at the fleet root (the folder above the workspace folder that holds `.tom/tom_root.yaml`): `_agent_guidelines/workspace_layout.md`, `workspace_layout_multi.md`, `repos.yaml`, `repo_structure_new.md`, `repo_skills_new.md`++} | {++The workspace layout as it is being built: the root and workspace markers, the places that can be changed, independent clones, the fleet's skills after the cutover; beyond S12++} | {++state of 2026-11-20; partly built++} |

{~~Every path above resolves in the workspace on 2026-11-19.~>Every path above resolves on 2026-11-20, in the workspace or, for the files of S27 named so, at the fleet root.~~} The snapshots in
`sources/` carry the original's path and the date in their first line; S1 was
taken at the state of 2026-11-19.

**Not a source:** the earlier agent_container and project_coordination work.
It may supply aspects to consider, nothing more (S4, note m).

## <!--[VIS]--> 2 Vision

### <!--[VIS-PROBLEM]--> 2.1 The problem

Work with AI agents is organised today around the coding session: one task,
one execution by an agent, one branch or pull request to review. A larger undertaking
does not fit that unit. It runs for weeks or months, spans many repositories
and several machines, follows a process with phases and gates, and depends on
people who answer questions, review documents and decide (S9; S1 § 15.2,
§ 15.3).

The Tom workspace has an engine for such work: quests, todos, processes with
runs, a prompt queue, sessions, transports to the models, tools, team review.
It lives inside one application, the VS Code extension, and is entangled with it
(S1 § 2.1). Four things follow:

- **P-1** **Other applications cannot use it.** Webforge (Tom Forge) and Webwork need
  the same engine and would have to build it again (S4, notes a, k).
- **P-2** **Agents and people work side by side without anything keeping them
  apart.** Everything is committed on one branch in shared clones; "one writer
  per repository" is an agreement; machines drift apart unnoticed; shared
  files are overwritten by another window (S1 § 10.1).
- **P-3** **People outside the editor cannot take part.** A reviewer or a decider
  without access to a repository gets documents by hand, and a question from
  an agent waits in the window that asked it (S1 § 3.5, § 6.6).
- **P-4** **Nobody sees the whole.** What waits, where, on which machine, is spread
  over windows (S8).

Why now: the engine's features are complete enough to be extracted; {~~three
future hosts and three other quests wait for it (`LAND > LAND-WAIT`)~>the hosts
that are to use it and the quests of `LAND > LAND-WAIT` wait for it~~}; and the
coordination service's first part exists and is used by nothing yet
(S1 § 2.1, § 2.3).

### <!--[VIS-SYSTEM]--> 2.2 What the system becomes

The unit of work is the **project**: a quest with processes, gates, todos and
people, not a coding session (S1 § 4, § 15). {~~The system has three components
and two sets of libraries:~>The system is the programs and
the libraries of this table:~~}

| Component | Short | Is |
| --- | --- | --- |
| **Tom AI Runtime** | tar | The engine as a runtime of its own (`tom_ai/ai_build/tom_ai_runtime`, TypeScript): quests, todos, processes and runs, the queue, sessions, transports, tools and an MCP server, without a VS Code window. A host attaches to it and adds as thin a user interface as it needs. (S1 § 4, § 5; FO-1) |
| **Tom Agent Coordination** | tac | The service through which runtimes find each other and keep out of each other's way (presence, leases, messages, endpoints), and the messaging service between the users of applications linked with a runtime: documents for review, messages, reminders, decisions. A reusable component of its own.{++ It runs as the local tac service on a user's machine and as the tac server with its relay for a team; with the GitHub backend a coordination repository takes the service's place (`TAC > TAC-BACKENDS`).++} (S1 § 4, § 7.1, § 7.2; CQ-15) |
| **Tom Runtime Control** | trc | The supervision application: every runtime of a team in one view, with full remote control. A Webforge application that also runs standalone, on the desktop and, in the first version, on the phone and the tablet.{++ On a phone or a tablet it uses a runtime through the web runtime service; what that takes, and whether it stays in the first version, is an open question (`TAC > TAC-CRYPT`, CI.18).++} (S1 § 12.4; FO-12; PQ-9{++, PQ-28++}) |
| {++**Web runtime service**++} | {++—++} | {++The program on a server through which an application on a phone, on a tablet or in a browser uses a runtime, since a runtime does not run there. It is HTTP-based, connects to a runtime on the server on behalf of the application, and reaches tac through that runtime. What it is beyond that is open; assumed until the question at CR.46 is answered: it starts one runtime per connected application (`RT > RT-INSTALL`, CR.46). (PQ-28; PQ-9, PQ-16)++} |
| **Client SDKs** | — | One runtime client SDK and one tac client SDK per language, for nine languages (Dart, TypeScript, JavaScript, Python, Java, Go, Rust, C, C++).{++ Beside them a web runtime client SDK, in Dart and in JavaScript / TypeScript, for applications on phones, on tablets and in browsers, built with Flutter or not; how it relates to the runtime client SDK is an open question (`CLI > CLI-PACK`, CL.1).++} (S1 § 12.1; FO-10, FO-11, CQ-15{++; PQ-7, PQ-28++}) |
| **Flutter UI components** | — | `tom_ai_runtime_ui`: the reusable user interface of the runtime for Flutter applications. No user interface components for other platforms. (S1 § 12.2; S4, note l) |

{~~The hosts of the first version are the VS Code extension, Webforge, Webwork
and the supervision application; for the supervision application on a phone
or a tablet the host is a runtime host server that runs one runtime per connected application (S1 § 4;
PQ-9, PQ-16; `RT > RT-INSTALL`, CR.46).~>The hosts of the first version are programs: the VS Code extension; Webforge
with its applications (the quest application, Webwork and the supervision
application); the supervision application standalone; and, for applications
on phones, on tablets and in browsers, the web runtime service (assumed until
the question at CR.46 is answered: it runs one runtime per connected
application). A host may start several runtimes: one per open quest, and one
without a quest for each of its applications that needs one (S1 § 4;
PQ-9, PQ-16, PQ-28; `NFR > NFR-TOPO`, T2; `CLI > CLI-TRC`, CK.7; `RT > RT-INSTALL`, CR.46).~~}

### <!--[VIS-GIVES]--> 2.3 What it is to give

- **V-1** One implementation of the `_ai` formats and the engines, used by
  every host, so a quest behaves the same in VS Code, in Webforge and in
  Webwork. (S1 § 5.1; S4, note a)
- **V-2** A comprehensive collaboration system: quests, todos, processes,
  queues and agents run in runtimes that find each other and work together; a
  host only attaches to a runtime and adds a thin user interface, as much of
  it as that host needs. (S4, note k)
- **V-3** Runtimes that work with each other, so that an agent's tools reach other
  runtimes as they reach other VS Code windows today: on one machine, across the VPN, {~~and through a relay beyond
  it.~>and through the tac server's relay beyond
  it.~~} (S4, notes b … e; S1 § 7.2)
- **V-4** A protocol with a streaming connection and an API over it, so any
  host can attach, and client SDKs that make attaching a matter of a few
  lines. (S4, notes f, g, k; S1 § 6.1, § 12.1)
- **V-5** Users as participants: messages, documents for review, reminders,
  questions and decisions travel between the users of a team and the runs
  that need them, also to users without access to a repository.{++ Such a user
  takes part through an application that carries the review component and
  reaches tac through its runtime: the VS Code extension today, Webwork and
  Webforge later; none of them is built here.++} (S1 § 7.1,
  § 7.4, § 7.7{++; PQ-30++})
- **V-6** Parallel work that is enforced, not agreed: claims on the resources an
  execution works on, an integration step before the main branch, a record of what each
  todo changed. (S1 § 10.4)
- **V-7** Supervision of a whole team's runtimes from one place, also from
  a phone or a tablet while away{++, through the web runtime service++}. (S8; S1 § 12.4; PQ-9{++, PQ-28++})
- **V-8** Putting the runtime's user interface into a Flutter application is
  simple. (S4, note l; S1 § 12.2)

## <!--[USR]--> 3 Users and stakeholders

### <!--[USR-GROUPS]--> 3.0 User groups

| Id | Who | Uses the system to | Source |
| --- | --- | --- | --- |
| **U-1** | **A developer working with agents in an editor.** One person with one or several machines, many quests, many windows. | Queue prompts and todo walks, run processes, answer the agents' questions, review results, and work in parallel without runs disturbing each other. | S1 § 3.1, § 10.1 |
| **U-2** | **A team member who reviews or decides**, often without access to any repository (a business reviewer). | Receive documents for review, annotate and return them; answer questions and take decisions that a run or a colleague addresses to them; exchange messages.{++ They do it in an application that carries the review component and reaches tac through its runtime: the VS Code extension today, Webwork and Webforge on the desktop later, a web version after that; none of them is built here. Until a web version exists, such a reviewer needs one of them on a desktop.++} | S1 § 3.2, § 7.7; S3{++; PQ-30; S25 (`13_woneb10`)++} |
| **U-3** | **A team owner.** | Create a team on a tac server they have joined{++ (a team on the GitHub backend has several members too; who owns it and what an owner does there is an open question: `TAC > TAC-PEOPLE`, CI.5)++}, invite members, remove them, administer the team's configuration (the providers that may be used, standard profiles); is the last in the chain when a question stays unanswered. | S1 § 7.3, § 5.5, § 6.6; DQ-2, DQ-11; PQ-20{++, PQ-29++} |
| **U-4** | **A quest owner.** Every quest has one. | Answer the questions that concern the quest's topics, or forward them. | S1 § 6.6; CQ-7 |
| **U-5** | **A supervisor of several runtimes.** Usually a user supervising their own runtimes, or some of the team runtimes. | See what every runtime does and what waits; queue todos, start and pause runs, continue processes, answer questions, review documents, from one place: at the desk, and from a phone or a tablet while away. | S8; S1 § 12.4; FO-12; PQ-9 |
| **U-6** | **An application developer** who embeds the runtime in a Flutter application, or uses it from another language. | Attach an application to a runtime through the runtime client SDK, offer the application's own tools to it, and build the user interface from ready components.{++ For an application on a phone, on a tablet or in a browser: U-14.++} | S1 § 12.1, § 12.2, § 6.3; S4, notes k, l |
| **U-7** | **An administrator of a tac server.** | Run the tac server for one or several teams, set it up with TLS, set whether it is open or strict, create the first account and its access key, {~~pair the tac server with~>have the tac server approved by~~} Tom Secrets Manager. | S1 § 7.2, § 5.8; CQ-9, CQ-16; PQ-13, PQ-20{++, PQ-32++} |
| {++**U-14**++} | {++**A developer of an application for a phone, a tablet or a browser**, built with Flutter or not.++} | {++Attach the application to a runtime on a server through the web runtime client SDK (Dart; JavaScript / TypeScript) and the web runtime service. A Flutter application also gets the UI components; an application that is not built with Flutter gets the SDK only (`SCO > SCO-OUT`, O-3).++} | {++PQ-28++} |
| {++**U-15**++} | {++**The coordinator of a review round:** the user whose runtime started the round.++} | {++Send a set of documents to the members for review, receive the returned copies, and decide when the round is merged.++} | {++`TAC > TAC-REVIEW`, CV.12; PQ-33++} |
| {++**U-16**++} | {++**A quest member:** a user registered as a member of a repository quest, also the same user on a further machine.++} | {++Join the quest on a machine, work in its repository beside the other members, and take in their work.++} | {++`PAR > PAR-QUESTS`, CQ.7; S22 § 4++} |

### <!--[USR-HOSTS]--> 3.0.1 Hosts and waiting quests

| Id | Stakeholder | Interest | Source |
| --- | --- | --- | --- |
| **U-8** | **The VS Code extension** (quest `vscode_extension`) | Becomes a host: it keeps its views and its VS Code tools and runs the runtime in its window. Its features are finished before the engine is extracted.{++ It gets messaging once the runtime is built; its messaging views are its own and are not built here (`SCO > SCO-OUT`, O-1).++} | S1 § 5, § 13.3; S2 § 3.3{++; PQ-30++} |
| **U-9** | **Webforge / Tom Forge** (quest `tom_forge`) | Hosts one runtime per open quest in its quest application; builds its views on the Flutter components; {~~later hosts trc as an application~>hosts trc as an application from the start~~}.{++ Every application composed from Tom Forge's composition library holds the quest applications and is such a host: Tom Forge's own application, the TomSpecs editor and Webforge.++} | S1 § 3.3; S14{++; D-5 (FO-12); `CLI > CLI-TRC`, CK.7++} |
| **U-10** | **Webwork** (quest `webwork`) | Its AI tab runs on a runtime without a quest; its team messaging and review exchange run over tac{++, through its runtime; in the first version messaging is in Webwork. Its builds for the web, the phone and the tablet have neither AI nor messaging until its wave 3 (`SCO > SCO-LATER`, L-8)++}. | S3; S13; S1 § 7.10{++; PQ-30; S25++} |
| **U-11** | **The fleet** (quest `al_the_bear`) | Runs the coordination repository and the tac server; its workspace layout is what the runtime resolves; its rules for parallel work become enforced{++; its format of the `_ai` folder and of quests in repositories is what the runtime is built on++}. | S1 § 3.4; S12; S16{++; S22; S27++} |
| **U-12** | **TomSpecs** (quest `tom_specs`) | Its processes and tools run in the runtime; its team review loses the user as courier of the review copies. | S1 § 3.5; S11 |
| **U-13** | **Tom Secrets Manager** (quest `tom_secrets_manager`) | The runtime and the tac service are its clients. | S15; S1 § 5.8 |

### <!--[USR-TEAM]--> 3.1 Product owner and review team

The product owner is the only reviewer. Every document type uses this team;
no document type has a team of its own. {~~No e-mail address is stored.~>This document's review team records no e-mail address; that says nothing about what tac keeps for a user.~~}
(PQ-1, PQ-22)

| Member id | Display name | Role | Owner of the review team |
| --- | --- | --- | --- |
| `alexis` | Alexis | Product owner | yes |

## <!--[GLO]--> 4 Glossary

The terms as agreed with the product owner (S21). A word in the last table is
not used, or only in the sense named there.

**Components and programs**

| Term | Meaning |
| --- | --- |
| **tar** (Tom AI Runtime) | The product: the engine as a runtime of its own. |
| **runtime** | One running instance of tar. It serves one quest (or none, for an application's own AI), belongs to exactly one person, and is started by its host and ends with it. |
| **application** | A program a person uses: VS Code with the extension, Webforge, Webwork, the supervision application, the review application; on any device. |
| **host** | The program that starts a runtime and through which the runtime reaches a user. On a desktop the application itself is the host. For an application on a phone, on a tablet or in a browser the host is a **runtime host server**, which starts one runtime per connected application. An application that will only later connect to a runtime (the review application) is a host from then on. |
| **client** | A program in its role of speaking a protocol to another, always with its kind: a **runtime client** connects to a runtime, a **tac client** connects to tac. |
| **client SDK** | The library we build for a client: the **runtime client SDK** (for applications, to reach a runtime) and the **tac client SDK** (which the runtime uses to reach tac), in each supported language. |
| **server** | Always with its kind: the **tac server**, a **runtime host server**, an **MCP server**. A runtime running as a process of its own is a **runtime process**, not a server. |
| **tac** (Tom Agent Coordination) | The service for coordination between runtimes and messaging between people. `TAC` is its protocol. |
| **backend** | Where tac's data lives for a workspace: local (one machine), GitHub, or a tac server. |
| **trc** (Tom Runtime Control) | The supervision application. |

**Work in a runtime**

| Term | Meaning |
| --- | --- |
| **quest** | An area of work, like a team's area in a department: its documents, todos and process state. It is small enough to hold one project at a time, and holds more projects over time. It has an owner and a home team. |
| **process** | A defined way of working: phases, steps, the roles doing them, gates, decisions, subprocesses. |
| **run** | A queue that executes todos and prompts, as the term is used in the VS Code extension. A quest has several runs, working in parallel; a run has its process position, its variables, its settings and its sessions. A run lives as long as its line of work, often for weeks. |
| **queue item** (item) | One entry of a run's queue: a prompt, a todo or a group of todos, with the session it is executed in and the transport it is sent with. |
| **todo** | A unit of planned work in a quest: an id, a description, a status, what it depends on, and the resources it needs. |
| **execution** | The work on one item: it starts when the run sends the item and ends when the item is done or given up. An execution claims the item's resources at its start and releases them at its end; where a repository has working trees, it works in one, and its result is a branch that the integration step lands. |
| **session** | One conversation with a model, with its history; named, and belonging to a run. An item is always executed in a session. *The word is not used for anything in coordination.* |
| **agent** | The model acting in a session, or a sub-agent it started. It receives a prompt, reasons, calls tools and answers. An agent has no identity outside its session: it is not a member of anything, holds nothing and is never addressed by tac. What acts towards the outside is the runtime, for its person. |
| **sub-agent** | An agent started by an agent for a part of its work. |
| **transport** | The way a prompt reaches a model. With a **model transport** the runtime calls the model's API and runs the tool loop itself. With an **agent transport** an outside program (an agent SDK or command line) runs the loop and reaches the tools through MCP. In both, what works in the session is an agent. |
| **tool** | A function an agent can call. A **runtime tool** is carried out by the runtime, a **host tool** is registered by the host and carried out there. |
| **ask** | A question the runtime puts to a person: a question, a pick, a document to work on, a tool approval, a plan, a decision, a gate. A stored record. |
| **trail** | The durable record of what a run did: prompts, answers, tool calls, as files. |
| **event** | One thing a runtime tells its clients while it works; numbered per run. |

**People**

| Term | Meaning |
| --- | --- |
| **person** | Any human being. |
| **user** | A person using an application: the application that is a runtime's host, or another application such as the review application. A user has an identity (user id, e-mail address, display name) and devices. |
| **a runtime's person** | The person a runtime belongs to: the user of its host. |
| **participant** | tac's technical word for whoever can send or receive: a user or a runtime. Used only where both are meant. |
| **account** (= customer) | Whoever a tac server serves: an organisation, or a single person. An account has several teams and many users; quotas attach to it. Installing a server creates the first account. "Customer" is the same thing and is not used beside it. |
| **team** | A group of users on a tac server, within an account: members, owners, invitations, conversations, review sets, and the right to control each other's runtimes. |
| **member**, **owner** (of a team) | A user in a team; an owner may also invite, remove, make owners, change the team's settings, free anyone's stale lease, and delete the team. "Owner" alone is never used: it is the owner *of a team*, *of a quest*, or the *product owner*. |
| **team runtimes** | All the runtimes started by the members of a team (through their hosts). This replaces "agent group", which is not used. |
| **visible** (a runtime in a team) | A runtime is always visible in the home team of its quest: there it is seen, can be sent items, can be remote-controlled by the team's members where its host allows it, and claims its leases. In its user's other teams it is not visible by default; the user can switch it visible at the host. In such a team it is only seen, with its quest, and can be **offered todos**: no remote control from there, and no leases there. A user in two teams can so act as a liaison and link two groups of quests, or not show the other membership. |
| **todo offer** | A todo that a member or a runtime of another team sends to a quest. It is not in the quest until it is **accepted**: by a person of the quest's team, or automatically by a rule a person has set for that quest (from whom, of what kind). Accepting is always under a person's control. Adding todos is the case this exists for; other kinds of item may follow. |
| **home team** | The team a quest belongs to. Its runtime is always visible in that team and acts as a member of it. |
| **personal team** | The implicit team of a user who works without a tac server (the local backend): the user is its only member, and the user's runtimes on the machine are its team runtimes. |
| **invitation**, **team token** | How a user joins a team (an owner creates it for an e-mail address; a one-time password); the proof of membership, sent with every request. |
| **device**, **pairing** | A machine, phone or tablet of a user; enrolling it once so that it gets a key of its own and may reach the server from the internet. |
| **open server**, **strict server** | A tac server's setting for identity: stated identity is believed, or everyone needs an invitation and a team token. From the internet always strict. |

**Coordination: who may write where**

| Term | Meaning |
| --- | --- |
| **resource** | What can be leased: a whole repository, or a part of one described by a pattern of paths. A resource is named when it is claimed and registered nowhere; tac knows only the leases it has given. "Unit" and "touch set" are not used: a todo names its **resources**. |
| **resource name** | Globally unique, the same on every machine, whatever folder the clone lies in: the repository's identity at its repository server, and for a part a `#` and a path pattern relative to the repository's root. `<owner>/<repository>` when the team has one repository server, in full (`github.com/<owner>/<repository>`) when it has several. Example: `al-the-bear/tom_ai_build` and `al-the-bear/tom_ai_build#tom_ai_runtime/**`. A runtime derives the name from the clone's remote, never from its path. |
| **claim** | The attempt to get leases: before an item is executed, its runtime claims the item's resources from tac, all or none. A claim is answered with the leases, or refused with who holds what. "Request" means the same. |
| **lease** | The right on a resource for a limited time, given by tac in answer to a claim. It is **exclusive** or **shared** (below). "Grant" (as a noun) and "lock" mean the same and are not used; tac **grants** a lease (the verb). "Lock" is only a file lock on one machine. |
| **exclusive lease** | A lease that keeps every other claim on an overlapping resource out while it is held. |
| **shared lease** | A lease that records that an execution works on the resource. Others can take shared leases on it too; it is refused only while someone holds an exclusive lease there. It is what shows who is working where. |
| **strict mode** (of a repository) | The repository has no working tree per execution. An execution holds an exclusive lease for as long as the item is executed. |
| **worktree mode** (of a repository; also **change-branch mode**) | The repository has a working tree per execution. An execution holds a shared lease while it works in its tree, on its branch, and takes an exclusive lease only for the integration step. |
| **holder** | The runtime holds a lease, for the item it executes in one of its runs. A lease names the runtime, the run and the item it is for. It can be said to belong to the item, or to the run that executes it; it does not belong to a session. |
| **renew**, **release** | The runtime renews a lease while the execution works, and releases it when the execution ends. |
| **stale**, **free** | A lease not renewed for 60 minutes is stale. It is only shown; a person frees it. |
| **fencing token** | A number that grows each time a lease on a resource is given; a write carries it, so a write by a holder whose lease has passed to someone else is refused. |
| **overlap** | Two resources overlap when they name the same repository and one is the whole repository, or when their patterns can match the same path. tac gives no exclusive lease on a resource that overlaps a leased one, and no lease at all on one that overlaps an exclusively leased one. |
| **working tree** (per execution) | A second checkout of a repository on its own branch, in which one execution works. Whether a repository has them (worktree mode) or not (strict mode) is a setting the team decides. |
| **integration step**, **integration queue** | Bringing an execution's commits onto the main branch (rebase, the repository's checks, fast-forward, push); the serial order in which a repository's executions do that. |
| **endpoint** | An address a runtime publishes through tac for the other team runtimes to reach it; it exists only while the runtime is present. |


**Messaging, documents, review**

| Term | Meaning |
| --- | --- |
| **conversation** | A sequence of messages between users of a team: direct, among several members, or attached to a document, a review round, a todo, a run or a quest. |
| **message kind** | What a message is beyond text: document, review request, review return, ask, decision request, todo, reminder, notification, command. |
| **blob** | A file carried by tac, addressed by the hash of its content, with a lifetime. |
| **review set** | A named set of files pinned in tac for a review. |
| **review round**, **round folder** | One round of a team review; its record in version control beside the documents. |

**Words that are not used, or only in a fixed sense**

| Word | Instead |
| --- | --- |
| agent group | **team runtimes** |
| customer | **account** |
| grant (noun), lock, request (noun) | **lease**; **claim** for the attempt |
| session (in coordination) | the **runtime** holds a lease for an **item** of a **run** |
| unit, touch set | **resources** (of a todo) |
| run (for the work on one todo) | **execution** |
| group | only in *group of todos*, *component group* and "several members" of a conversation; never a thing of its own |
| server (alone) | **tac server**, **runtime host server**, **MCP server** |
| client (alone) | **runtime client**, **tac client**; the libraries are the **client SDKs** |
| owner (alone) | owner of a team, owner of a quest, product owner |

> **❓ PQ-33 (2026-11-20T15:15+01:00) — terms the document uses that the glossary does not list:** Should the glossary get entries for the further words the document uses in a fixed sense, and are the two definitions proposed here for "profile" and "coordinator" right?
>
> **Context:** The glossary (`GLO`) holds the terminology agreed with the product owner (source S21), term for term. Checking the whole document against it found words that are used in one fixed sense throughout but have no glossary entry. Most are explained by one item: **walk** — a queue item that goes through a group of todos, lowest number first, one todo per iteration (`RT > RT-QUEUE`, CR.19); **gate** — what ends each phase of a process (`RT > RT-RUNS`, CR.10); **role**, **role type** — what a prompt is executed as; a role type names the tools the prompt gets (`RT > RT-TOOLS`, CT.9); **quest owner** — the user who answers the asks that concern a quest (`RT > RT-ASKS`, CP.16, CP.17; the glossary says only that a quest "has an owner"); **done notification** — the message that a todo is done, delivered to the run and session that queued it (`RT > RT-QUEUE`, CR.21); **relay** — the part of the tac server that forwards TAC and MCP for machines that are not on the VPN (`TAC > TAC-BACKENDS`, CA.30); **notification** and **command** — the two kinds of message between runtimes: live only and not stored, or stored and taken by the first runtime of the target quest (`TAC > TAC-COORD`, CA.19); **capability block** — a part of `tac/2.0` a service announces that it implements (`TAC > TAC-SPEC`, CA.37); **repository server** — where a repository is kept and from which its name is taken, for example GitHub (`TAC > TAC-COORD`, CA.10; the glossary's entry for resource name uses the word); **standalone runtime** — a runtime that outlives its host (`SCO > SCO-LATER`, L-5); **classic quest**, **repository quest**, **personal repository** (`PAR > PAR-QUESTS`, CQ.1, CQ.2); **root**, **workspace folder** (`RT > RT-LOCATIONS`, CR.33). Two are used without being explained anywhere in the document: **profile** (CR.22 "A todo can name the profile it is executed with", CR.43 "when a profile first needs one", CS.3 "the standard profiles") and **coordinator** (`TAC > TAC-REVIEW`, CV.12: "The coordinator's runtime creates the round folder and sends a review request …").
>
> **Why I ask:** The Solution Blueprint will cite the glossary for every term, and a term that is only explained in one item is easy to use differently elsewhere. Two terms have no definition at all. The glossary is declared to be the agreed terminology, so adding entries means adding to what was agreed, and for "profile" and "coordinator" I would have to write a definition no source of this document states. Proposed for those two: **profile** — "a named configuration for sending a prompt: the provider and model, the transport, effort and thinking settings, the tools and how tool calls are approved"; **coordinator** (of a review round) — "the user whose runtime started the round; the copies return to them, and they decide when the round is merged".
>
> - **(a)** All of them get a glossary entry, in a further table "Further terms of this document", each with the wording of the item named above, and "profile" and "coordinator" with the two definitions proposed here (or as corrected in the answer). The terminology document (S21) gets the same entries, so glossary and terminology stay equal.
> - (b) Only "profile" and "coordinator" get an entry, because they are defined nowhere; the others stay defined by their items.
> - (c) The glossary stays the agreed terminology and nothing is added; "profile" and "coordinator" are explained in the items that use them first (CR.22 and CV.12).
>
> *Recommendation:* (a) — the Blueprint then has one place to cite, and the list is short.
>
> *Assumption until answered:* The glossary is unchanged; the words are used as the items named above explain them.
>
> **Answer (2026-11-20T15:22+01:00):** (a)

## <!--[SCO]--> 5 Scope

The specification's root is `tom_ai/ai_build/specification/`.

### <!--[SCO-IN]--> 5.1 In scope

| Area | In scope | Source |
| --- | --- | --- |
| Runtime core (`CR`) | The `_ai` formats and stores{++ in format version 10++}; processes and runs; the queue; sessions; model and agent transports{++, among them the Agent Client Protocol in both directions++}; locations and configuration; machine-wide state; installation, lifetime and versions{++; the web runtime service for applications on phones, on tablets and in browsers (what it is beyond its name is an open question: `RT > RT-INSTALL`, CR.46)++} | S1 § 5{++; S22; PQ-28++} |
| Protocol and hosts (`CP`) | The runtime protocol (commands, numbered events, reverse requests, asks); the host interface; routing and escalation of asks; versions and compatibility{--; the Agent Client Protocol in both directions--} | S1 § 6 |
| Tools and MCP (`CT`) | Runtime tools, host tools, the runtime's MCP server, the runtime as MCP client of external MCP servers | S1 § 6.3, § 6.4 |
| Coordination between runtimes (`CA`) | Presence and discovery, leases on named resources{++ (a name starts with the prefix of its notation, `git:` for now)++}, held by a runtime for an item of a run, messages between runtimes, endpoints; the backends local{++ (one machine)++}, GitHub{++ (one user's machines, or a simple team of several members)++} and tac server; the {++tac server's ++}relay | S1 § 7.1, § 7.2; S5; S6; PQ-10, PQ-23{++, PQ-29, PQ-31++} |
| People, teams and identity (`CI`) | Participants, teams, invitations and team tokens, identification, the open or strict tac server, the pairing of devices, permission for remote control, a quest's home team and quest owner | S1 § 7.3; PQ-9, {++PQ-12, ++}PQ-13{++, PQ-20, PQ-23++} |
| Messaging (`CM`) | Conversations, message kinds, reminders, presence-aware delivery, history and read state | S1 § 7.4, § 7.5 |
| Documents and review (`CV`) | Blobs with lifetimes and pinning, review sets, the review exchange | S1 § 7.6, § 7.7 |
| Parallel work and integration (`CW`) | Claims in the queue, a repository's strict or worktree mode, the integration step and queue, the resources a todo names, the record of a todo's commits, quiescence, cross-quest addressing and delivery | S1 § 10.4, § 10.5 |
| Client SDKs (`CL`) | The runtime client SDK and the tac client SDK in nine languages, with one conformance suite{++; the web runtime client SDK in Dart and in JavaScript / TypeScript++} | S1 § 12.1{++; PQ-28++} |
| UI components (`CU`) | `tom_ai_runtime_ui`, the descriptions of its screens and components, a gallery application | S1 § 12.2, § 12.3 |
| Supervision (`CK`) | trc, on the desktop, the phone and the tablet{++ (on the phone and the tablet through the web runtime service; an open point: `TAC > TAC-CRYPT`, CI.18)++} | S1 § 12.4; PQ-9{++, PQ-28++} |
| Repository quests and personal files (`CQ`) | {~~Quest types~>The three quest types and their register, the quest operations~~}, the personal repository, personal notes{++ (where personal files are kept is an open question: `PAR > PAR-QUESTS`, CQ.2)++} | S1 § 12.5; S2 § 3.7{++; S22++} |
| Secrets, configuration and providers (`CS`) | Secret references and their resolution; the configuration split into the repository's, the team's and the runtime's part; the model providers | S1 § 5.5, § 5.8; S7 |
| The split (no area of its own: D-40, D-41; N-32, N-33; R-1; `DEL`) | Extracting the engine from the VS Code extension, with a stable extension beside it while that runs | S1 § 13.3 |

### <!--[SCO-OUT]--> 5.2 Out of scope

- **O-1** The VS Code extension's own features: its views, panels and editors,
  and the tools that need VS Code. They stay in the extension, which becomes
  a host.{++ Its messaging views, which it gets once the runtime is built, are
  among them: messaging is built here as Flutter components only (O-3).++} (S1 § 6.3; S2 § 3.3{++; PQ-30++})
- **O-2** The applications that host a runtime — Webforge, Webwork and their
  own tools and screens — apart from what they need from this product. (S3,
  "Why Webwork needs it, and when" and WR-7; S14, part two, § 5)
- **O-3** User interface components for platforms other than Flutter. (S4,
  note l)
- **O-4** Transports implemented by a host: the VS Code language-model
  transport and the Copilot chat transport {~~are removed~>are not carried by the runtime~~}; Copilot is reached
  only through direct calls and its SDK.{++ In the VS Code extension the
  "VS Code LM" transport inside its Anthropic panel stays until the route
  through the Copilot SDK works.++} (S2 § 5, FO-2{++; S22 § 2.3, AC-19++})
- **O-5** A port of the engine to another language. The runtime is
  TypeScript; other languages get client SDKs. (S1 § 4, § 12.1)
- **O-6** Converging machines: reconciles of the fleet stay a step the user
  starts. The system answers who holds what; it does not pull or merge clones
  on its own, except {~~where the integration step lands an execution's own commits.~>in two cases: where the integration step lands an execution's own commits, and where a workspace switched on the fast-forward of repositories on which no lease is held (CW.16: off unless switched on; done when a claim is taken or when the user asks, never on a schedule).~~}{++ Pull and push of the `_ai` state and of a quest's
  repository are steps the user starts too (CQ.7).++}
  (S1 § 10.4; S16{++; S6, BP-12, BP-18; S22 § 2.4, QM-10; S27 (`14_loose_wslayout-5`)++})
- **O-7** A file server: tac carries documents while they travel or while a
  process pins them; the record of documents is version control. (S1 § 7.6;
  FO-8)
- **O-8** The earlier agent_container and project_coordination work as input.
  (S4, note m)
- **O-9** A short process for small changes. The engine carries any
  process; which processes exist is decided where they are written. It is
  proposed in the quest `tom_specs`. (PQ-4)
{++- **O-10** A review application of its own. Reviewing is part of the
  applications that carry the review component: the VS Code extension today,
  Webwork and Webforge later; none of them is built here. An application that
  needs tac reaches it through its runtime, with the runtime client SDK.
  Where the review component itself is built is an open question
  (`CLI > CLI-UI`, CU.9). (PQ-30)++}

### <!--[SCO-LATER]--> 5.3 Deferred to later

Decided as not part of the first version (S1 § 11.1){++; L-6 alone is not decided and stands here as an open point++}.

| Id | Feature | What defers it |
| --- | --- | --- |
| **L-1** | Todos to the cloud: handing a todo to a vendor's hosted agent, or to a runtime on a machine of our own, and integrating the branch that comes back | CQ-13: sending work out sends source code out; a data policy comes first (S1 § 11.2 … § 11.5) |
| **L-2** | A data policy per quest or repository: which provider may see what | DQ-8: the centrally administered configuration decides for now (S1 § 11.1) |
| **L-3** | Asking people outside the team by e-mail, answered on a web page of the tac server | DQ-3: needs the tac server to send e-mail and a small web application (S1 § 11.1) |
| **L-4** | The tac server sending invitation e-mails itself | DQ-2: the team owner passes the one-time password on; the protocol does not change (S1 § 11.1) |
| **L-5** | Standalone runtimes that outlive their host, to which a runtime client attaches to supervise and detaches again | CQ-4, PQ-16: a runtime ends with its host; the protocol does not prevent the other{++; how long the runtime behind the web runtime service lives is an open question (`RT > RT-INSTALL`, CR.46)++} (S1 § 11.1) |
| **L-6** | End-to-end encryption between a device and a runtime, on top of encryption in transit and the paired device's key | {~~CQ-10, PQ-9: the pairing of devices is in the first version; whether end-to-end encryption has to be is an open point for the security model~>Not decided as deferred. The pairing of devices is in the first version (CQ-10, PQ-9); whether end-to-end encryption has to be in it too is open, and is asked with the question on phones and tablets at CI.18~~} (S1 § 11.1; `TAC > TAC-CRYPT`, CI.19{++; `NFR`, N-21++}) |
| **L-7** | A review's own git repository on the tac server, for reviewers without repository access | DQ-4: pinned blobs cover reading and returning (S1 § 11.1) |
| **L-8** | Webwork in a browser, on a phone and on a tablet, with its {++AI and its ++}messaging there{--: Webwork's own server side--} | WQ-1: in {~~a later wave of Webwork; the runtime host server it will use is in the first version, for the supervision application~>wave 3 of Webwork (its decision DPPHONE-5); until then these builds have neither. Webwork expects one server side to carry both: that is the web runtime service, which the first version has for the supervision application as far as the open question on it leaves that standing (`RT > RT-INSTALL`, CR.46)~~} (S1 § 11.1; `NFR > NFR-TOPO`, T8; PQ-9{++, PQ-28; S25 (`06_woneb9`, `13_woneb5`, `10_woneb1`)++}) |
| **L-9** | Telegram: one bot token for every runtime, one chat per machine | FO-16 (S1 § 11.1) |
| **L-10** | Encryption at rest of messages and blobs | FO-20: an option, its key in Tom Secrets Manager (S1 § 11.1) |
| **L-11** | Billing, and {~~accounts of several organisations on one tac server~>running one tac server for several organisations~~} | {~~the tac server has the records for it~>the first version has the account record, access keys, quotas per account and the administration interface, and is used with one account~~} (S1 § 11.1; CQ-9{++; `TAC > TAC-BACKENDS`, CA.27++}) |
| {++**L-12**++} | {++Services that use tac directly, through the tac client SDK and without a runtime, for a part of tac such as messaging++} | {++PQ-30: possible, not planned. Every application of the first version reaches tac through its runtime. The tac server keeps what such a service would need (it answers tac clients in a browser: `TAC > TAC-BACKENDS`, CA.28); no application of the first version uses it++} |

## <!--[LAND]--> 6 What exists today

### <!--[LAND-BUILT]--> 6.1 Built

- **E-1** **The engine, inside the VS Code extension**
  (`tom_ai/vscode/tom_vscode_extension`, version 0.1.0). Its feature areas
  (S1 § 2.1, § 3.1; S17{++; S23++}):
  - quests, todos (groups{++ of two kinds: all todos of an id prefix, and a group todo that names its members++}, due dates{++ with reminders and repetition++}, follow-ups, cross-quest blockers{++, a mark that only the user can do a todo, its open decisions, the role and the guideline choices it is executed with++}),
    memory, chat variables, roles and role types, templates, profiles;
  - processes with runs: every process runs in a run of its own, with its
    position, variables, queue lane, settings and sessions; nested
    processes, branches, conditions, decision steps, gates with decision
    buttons;
  - the queue: prompt, todo and group items, pre-prompts and follow-ups,
    walks, timed requests, reminders{++ after a wait (they leave with format version 10: S22 § 2.3, AC-22)++}, soft interrupt, done notifications,
    questions that survive a reload;
  - sessions and trails;
  - transports: the direct API, the Claude Agent SDK, a local model, and the
    {~~two host transports that are removed (`SCO > SCO-OUT`, O-4);~>two host transports the runtime does not carry (`SCO > SCO-OUT`, O-4);~~}
  - the `tomAi_*` tools and one MCP server for all of them;
  - team review and the document browser with questions, marks and
    consolidation;
  - the format-version stamp of the `_ai` files{++ (version 9 today; version 10 is decided and not built: S22)++} and its migration;
  - a JSON-RPC server for scripts, and the Dart client of it,
    {~~`tom_vscode_scripting_api` 5.0.0.~>`tom_vscode_scripting_api` 6.0.0.~~}
- **E-2** **Todo follow-ups** (the first stage of coordination): a todo names
  what happens when it is done and who filed it; the done notification
  returns to the run and session that queued it{++ (it has no default: without one, nothing is sent)++}; an item or a walk can be
  sent into a named run of another quest on the same machine. The fields for
  claims are in the todo model (`tom_todo_model` {~~3.1.0~>4.2.0, with the item model `TomItem`, the reminder fields and the fields for a todo's role and guideline choices~~}) and unused. (S1 § 2.1,
  § 2.2{++; S23; S25 (`wwremind1`, `wwaspect1`)++})
- **E-3** **The protocol `tac/1.0`** and **`tom_tac_service` 0.1.0 in local
  mode** (`tom_ai/vscode/tom_tac_service`, a TypeScript package without
  runtime dependencies, 40 tests): presence, sessions, leases with fencing
  tokens, units, messages between runtimes, endpoints, migration and
  administration ("session" and "unit" are record names of `tac/1.0`), over HTTP and WebSocket on the local machine, with a typed
  tac client. (S5; S1 § 2.1)
{++- **E-19** **What `tac/1.0` has that the product does not use:** its session
  record (the product keeps no record for the holder of leases: a lease names
  its holder; PQ-27); declared units and infrastructure resources (a resource
  exists for tac from the moment it is claimed; PQ-23); a resource kind of
  its own for a folder of the `_ai` state (such a folder is claimed as a part
  of a repository; PQ-31); the name "agent group" with its group id (in the
  product: the team; S21, C-4); and the name "customer" (in the product: the
  account). (S5 § 3.1, § 3.4 … § 3.7)++}
- **E-4** **The workspace layout resolver** in the extension
  (`src/utils/workspaceLayout.ts`): root, workspace folder, the `_ai` folder,
  the configuration layers, the guidelines on {~~two levels~>three levels (the root's, the workspace folder's and a project's own)~~}. (S12; S1 § 2.1,
  § 5.5{++; S27++})
- **E-5** **Merge drivers for the `_ai` files** in TypeScript.{++ Their source is the
  fleet's (the repository `al_the_bear`); they are built from it into the
  binaries repository. The extension carries a built copy and checks it when
  it is upgraded; it is to take the bundle from the binaries repository
  (planned: vscode_extension `vscimpb152aaa`).++} (S1 § 2.1{++; S22 § 3.5; S23; S27 (`tsmergedrivers1`)++})
- **E-6** **Tom Secrets Manager clients:** Dart (`tom_secrets_client` 0.2.11)
  and TypeScript (`@al-the-bear/tom-secrets-client` 0.1.0), {++client libraries in Python, Go, Rust, Java, C and C++ (each 0.1.0), ++}and the command
  line `tsm` {~~0.2.6~>0.2.7~~}. (S15: the protocol document, § 5 "The client endpoint";
  the idea document, part-clients)
- **E-7** **The rules for parallel work** as a guideline, most of them by
  agreement. (S16, § 1 … § 6 and "What enforces what")
{++- **E-20** **Flutter packages with agent and todo views, over other backends**
  (`tom_ai/modules`): `tom_agentic_ui` 0.1.0 (the chat composer, the prompt
  queue and the prompt trail, the connection picker, the review of changes)
  over `tom_core_agentic`; `tom_ai_trail_ui` 0.1.0 (the live trails of AI
  sessions) over `tom_llm`; `tom_todo_ui` 0.2.0 (the todo row, the details
  editor, the editor of a todo file) over `tom_todo_model`. None of them
  works over the runtime. What becomes of them beside `tom_ai_runtime_ui` is
  an open question (`CLI > CLI-UI`, CU.9). (S26: tom_forge `02b_woneb8`; S25:
  webwork `06_woneb9`)++}
{++- **E-21** **The specification tooling:** the binary `tomspecs` 0.17.0
  (`tom_ai/ai_build/tom_specs_clitool`) and the SOM packages, which the
  extension bundles today. (S1 § 3.5; `RISK > RISK-DEPS`, R-21)++}

### <!--[LAND-MISSING]--> 6.2 Not built

- **E-8** There is no runtime package: nothing of the engine runs outside the
  VS Code extension. (S1 § 2.1)
- **E-9** There is no runtime process of its own and no runtime protocol; no host other
  than the extension can attach.{++ There is no web runtime service.++} (S1 § 2.1)
- **E-10** There is no Dart runtime client SDK and no client SDK in any other
  language{++, and no web runtime client SDK++}; no Flutter component {~~of the runtime's user interface~>over the runtime~~} exists{++ (the
  Flutter packages of E-20 work over other backends)++}.
  (S1 § 2.1, § 12)
- **E-11** Nothing uses the tac service: the extension holds no reference to
  it, and claims are not taken anywhere. (S1 § 2.1)
- **E-12** tac has no tac server, no GitHub backend, no users, teams, user
  messages or documents; they exist as specification text or decisions only.
  (S5; S1 § 2.2, § 7)
- **E-13** No supervision application exists. (S8, section `input`: the idea
  only)
- **E-14** No quest is a repository of its own, and there is no personal
  repository.{++ The register of quests `_ai/quests.yaml` does not exist, and
  nothing of format version 10, of the three quest types or of the quest
  operations is built: every todo of the migration is not started. This
  fleet keeps no list of a workspace's quests
  (`_ai/workspaces/<workspace>.yaml`).++} (S2 § 3.7{++; S22 § 5, § 7; S27++})

### <!--[LAND-WAIT]--> 6.3 Who waits for this

| Id | Quest | Waits for |
| --- | --- | --- |
| **E-15** | `webwork` | Team messaging and the review exchange over tac; the AI tab of its bottom panel over a runtime without a quest, with the Dart runtime client SDK and the Flutter components. It works on what needs neither until the runtime is built.{++ Its wave 1b2 carries the AI tab and messaging together, starts after its wave-1b1 release and assumes the runtime finished; no date is set. Its specifications D13 (amended) and D40 are written against the runtime protocol specification and `tac/2.0`, so it needs those two documents before the code. It waits for two messages: which todos cover WR-1 … WR-7, and that the runtime is complete. Its builds for the web, the phone and the tablet wait for the web runtime service (`SCO > SCO-LATER`, L-8).++} (S3; S1 § 7.10; WQ-4{++; S25++}) |
| **E-16** | `tom_forge` | Its quest application: the runtime process and its protocol, the Dart runtime client SDK, the host interface and host tools, two hosts on one quest, the Flutter components, the view of the coordination.{++ The second part of its quest workbench specification is written from this specification. For repository quests it needs their operations as commands of the runtime (an open question: `PAR > PAR-QUESTS`, CQ.7).++} (S14; S1 § 2.3, § 3.3{++; S26++}) |
| **E-17** | `al_the_bear` | Running the tac server on its always-on machine, which needs the tac server; the coordination repository for the GitHub backend; its parallel-work rules becoming enforced.{++ The coordination repository does not exist yet; its todo waits for the fleet's cutover to independent clones. The fleet's skills recognise only VS Code processes when they quiet the work before a merge, and no todo exists yet for asking tac or a runtime process. In the other direction the runtime waits for the fleet: the format of the `_ai` folder it is built on (S22) is decided and not built.++} (S1 § 2.2, § 3.4; S16{++; S22; S27 (`14_loose_wslayout-4`, `14_loose_wslayout-6`, `12a_wslayout-2`)++}) |
| **E-18** | `tom_specs` | Review copies that travel without the user; its tools and processes running in every host. (S11; S1 § 3.5) |
| {++**E-22**++} | {++`vscode_extension`++} | {++The split: its engine becomes the runtime and the extension a host. Messaging, which the extension gets once the runtime is built. Until the split its engine keeps changing, and the migration to format version 10 is done there. (PQ-30; S22 § 7; S23)++} |

## <!--[RT]--> 7 The runtime (tar)

The runtime is the engine as a program of its own: one TypeScript package,
`tom_ai/ai_build/tom_ai_runtime`, with no dependency on VS Code. A host starts
it, attaches to it and shows what it does. (S1 § 4, § 5; FO-1)

### <!--[RT-HOLDS]--> 7.1 What the runtime holds

- **CR.1** The runtime is the one implementation of the `_ai` formats and of
  the engines that work on them. Every host uses it, so a quest behaves the
  same in each. (S1 § 5.1; S4, note a)
- **CR.2** It reads and writes the stores of a quest and a workspace: quests,
  todos (with groups, due dates, follow-ups and blockers in other quests),
  memory, sessions, trails, chat variables, roles and role types, templates
  and profiles{++, the quest's short description, saved prompts and notes, the journal of asks and answers and the aspect guidelines. CR.47 to CR.56 and CR.61 say what each holds++}. (S1 § 5.1, § 3.1)
- {++**CR.47** Every file of a quest belongs to one of four classes, and the class decides whether it travels between machines: **shared** files are tracked and merged between machines (the quest's documents, its todos, the process state, the shared configuration, curated memory, notes, saved prompts); **per-host** files are tracked, one file per host, written only by that host and never merged; **derived** files are built when needed and not tracked; **machine-local** files are not tracked. Every store of CR.2 names its class. (S22 § 2.2, § 3.2)++}
- {++**CR.48** A todo carries, besides its id, description, status and resources: its blockers, also in other quests, and release conditions; a mark that only the user can do it (a walk passes such a todo, and it is shown among what is directed at the user); the block of its open decisions, with the status "decision needed" until they are answered; what happens when it is done, and who filed it (written from the caller's context, never by the agent); the answer of the execution that completed it. The views of what waits for a person are built from these. (S23: ww_a_collab-2, ww_a_collab-5, vscimpb121; S17, the user guide § Your own todos, § Decisions)++}
- {++**CR.49** There are two kinds of todo group: all todos of an id prefix, and a group todo that names its members, also of other quests. A group todo is completed by itself when all its members are done; what a todo is a part of is derived, never stored. (S23: vscimpb125, vscimpb126)++}
- {++**CR.50** A todo's dates: a due date with a derived overdue state and one reminder; a reminder schedule that rings while the todo is open; one-shot reminders; and repetition (the todo comes back after it is done). They are checked on the runtime's one clock (CR.84) and ring through the notification for the user. They ring only while a host has the runtime running (CR.44); a missed moment rings once at the next start. (S23: vscimpb152aa, vscimpb152ab, vscimpb34)++}
- {++**CR.51** A todo id never disappears: a rename leaves a cancelled stub under the old id. (S27; built in the extension's rename tools, E-1)++}
- {++**CR.52** What the runtime writes passes the commit guards of the repository it writes into, in the `_ai` state and in a repository quest alike. (S22 § 3.6, § 2.4 QM-7)++}
- {++**CR.53** Planned: memory is the quest's. Curated facts are shared by the quest's members; candidates are kept per host, each naming its session, and the user promotes them with a prompt. There is no scope shared across quests and no level per session. (S22 § 2.2 CQ-8, CQ-18, § 2.3 AC-17; S23: 01_aifmt-3, 00_aifmt-3)++}
- {++**CR.54** Planned: saved prompts are a store of the quest (shared); quest notes are several files of the quest, the user's, which agents read and never write; a workspace has notes of its own in the `_ai` state. A notes file per machine is the VS Code host's own (`CLI > CLI-SCREENS`, SC-17). (S22 § 2.3 AC-4, AC-5, AC-11, AC-12, § 3.2; S23: 01_aifmt-3)++}
- {++**CR.55** Planned: the journal of asks and answers is a store of the runtime, per host and quest, in time order: every ask put to the user with its answer and the run it came from, every answer handed to the user without an ask, and every message written to a waiting turn (CR.72). The views of asks and answers read every host's journal, and the decisions document of a quest is a rendering of the decisions of its archived todos. Where the per-host files lie is open (`PAR > PAR-QUESTS`, CQ.2). The Solution Blueprint settles whether an ask answered on another machine through tac is recorded in the asking host's journal. (S22 § 2.2 CQ-2, CQ-15, QJ-1; S23: 01_aifmt-4)++}
- {++**CR.56** A quest has a short description as one of its files: a title, two to four sentences and a line on its state. It is required when a quest is set up and is served with the list of quests. (S23: vscimpb145, questsetup1)++}
- **CR.3** It carries the format-version stamp of the `_ai` files and the
  migration from one format to the next. {++The runtime is built on format version 10 of the `_ai` files, with the layout of the quest folder that S22 § 3 defines; that version is decided and not built (`LAND > LAND-BUILT`, E-1).++} (S1 § 5.1; `RT > RT-VERSIONS`{++; S22 § 3.2, § 3.6++})
- **CR.4** It keeps a registry of cleanup tasks, so what a feature leaves
  behind (temporary files, stale records) is removed by one mechanism.
  {++Each task finds what is left and applies its removal, and an agent runs the tasks through a tool. Planned: the registry is decided and not built (S23: aaa_cleanup1, aaa_cleanup2).++}
  (S1 § 5.1, § 3.1)
- {++**CR.57** The runtime's own temporary files for a workspace, and its tools', lie in the workspace root's ignored scratch folder `ztmp/`, never in the system's temporary folder, and carry the quest, the date and the todo in their name, so that the registry of CR.4 removes them when the todo is done. (S27, `workspace_agents.md` § Scratch folders)++}
- **CR.5** It carries what the engine has today beyond the stores: team review
  rounds on documents, the expression language used in prompts and process
  definitions, prompt assembly from role, quest, memory and guidelines, and
  the features of Claude Code (skills, subagent definitions, slash commands,
  instruction files, hooks, plan mode) on every transport. (S2 § 3.1;
  S1 § 3.1)
- {++**CR.58** Plan mode is per run: while it is on for a run, every writing tool is refused on every transport, and reading and asking work. Only the user ends it; a prompt that ends while its plan is proposed leaves plan mode on. (S23: vscimpb81)++}
- {++**CR.59** Instruction files are found from the workspace folder: an agent transport is started with the workspace folder as its working directory, and for a model transport the runtime collects the instruction files by the same rules (the root's, then the workspace folder's, imports followed). (S12; S27, `workspace_layout.md` § 6)++}
- {++**CR.61** Prompt assembly takes, for each section of the aspect guidelines, the text of one option from a store that every quest and machine shares, and places it in the system prompt or before the user prompt, on every transport. Which option is taken is resolved over levels, the last winning: the section's default, the quest's default, the run, the role type, the role, the item, the todo. The store and the resolver are built; choosing per level is planned. Whether a level for the host stands between quest and run is open (PQ-35). (S24, A-1 … A-5, L-1 … L-8; S23: gsel2, gsel4 … gsel10)++}
- **CR.6** One {~~runtime instance~>runtime~~} serves one quest. An application's own AI
  that belongs to no quest runs in {~~an instance~>a runtime~~} without a quest. Inside {~~an
  instance~>a runtime~~}, runs and sessions work in parallel. (S1 § 3.2; S3, WR-7;
  S2 § 3.1)
- {++**CR.60** One host can have a runtime without a quest and runtimes that serve quests at the same time; a run that is bound to a quest's folder runs in that quest's runtime. Any host can start a quest's runtime, not only a workbench. (S25: 12a_woneb1; `NFR > NFR-TOPO`, T2; CR.42)++}
- **CR.7** A {~~runtime instance~>runtime~~} belongs to exactly one person. {++This is stated for a host on the user's machine; whose runtime runs behind the web runtime service is open (PQ-38).++}
  (S1 § 7.3, DQ-1)

### <!--[RT-RUNS]--> 7.2 Processes and runs

- **CR.8** A **run** is a queue in a quest that executes todos and prompts, one line of work: a process position, its
  variables, its own queue settings{++ (CR.70)++}, its sessions (named
  `<session>@<run>`) and a subject that says what the run works on. A quest
  has several runs, and they work in parallel{++: each run sends its items beside the others (CR.67)++}. (S1 § 5.2, § 3.1)
- {++**CR.62** A run is created with its default session `default@<run>`, based on the default run's session `default@default`. An item that names no session is executed in its run's default session. (S23: qrun1, vscimpb151; PQ-25)++}
- {++**CR.63** The subject of a run is a run parameter that its process declares. The process's first step sets it; it is shown wherever the run is shown, and in the process context of a prompt. Planned: it is preset with the run's name. (S23: vscimpb118; vscimpb156, planned)++}
- **CR.9** The run `default` follows no process. Every process runs in a run
  of its own. A run can be reset as a whole, or only put back to the start of
  its process. A process declares the parameters a run of it takes.
  (S1 § 5.2, § 3.1)
- **CR.10** A process is defined by phases, steps and sub-steps, the role
  that does each, and a gate that ends each phase. The engine carries these
  shapes (S1 § 3.1, § 3.5):
  - nested processes with inputs and outputs, and branches that hand nothing
    back;
  - conditional phases and steps;
  - decision steps{++, decided by a condition, by the user, or by the agent's judgement with a recorded reason,++} and moves that are not linear (back to a step, back to
    the start of a phase);
  - follow-up processes;
  - gates whose result is shown with the buttons of the decision that
    follows{++; the move a button makes acts on the run of the prompt that asked++};
  - review steps that name the documents under review;
  - steps the user does himself, which the process only asks him to confirm;
  - steps that queue walks over todo groups, with a closing item.
- **CR.11** A process definition can be written and checked through tools,
  and an agent can suggest a subprocess for the running step. {++A suggested subprocess is shown only after the step's items are done, and the step's move waits for the user.++}
  (S1 § 3.1{++; S23: vscimpb95, ccparity_e_process-8++})
- **CR.12** A run pins the version of its process: it records the revision of
  the process definition it started on. When the definition changes, the run
  goes on as it was; at its next step boundary the user is shown what changed
  and confirms that the run takes the new definition over. Taking it over is
  the usual case, since a change to a process is normally meant to be used at
  once; a run never changes in the middle of a step. {++The Solution Blueprint settles what "the revision of the process definition" is.++} (S1 § 5.2; PQ-2)

- **CR.13** A step declares what must hold before it starts (answered
  questions, a passed gate, documents that exist). The runtime checks this
  and refuses to start the step with the reason, instead of starting it. {++This is a refusal, not a wait: nothing of the step is queued, and the process stays at its position.++}
  The preconditions come from a fixed set: every question of a named
  document answered, a named gate passed, named documents exist, a named
  group of todos done. The user can override a refusal, and the override is
  recorded. (S1 § 5.2; PQ-3)

- **CR.14** Which processes exist is not the runtime's matter: the engine
  carries any process definition. A short process for small changes is not
  part of this product; it is proposed where the specification process is
  defined. (PQ-4; `SCO > SCO-OUT`)

### <!--[RT-QUEUE]--> 7.3 The queue

- **CR.15** Every run has a queue. Its items are prompts, todos and groups of
  todos{++ (the kinds: CR.64)++}; an item has pre-prompts and follow-ups, a session it is executed in and a
  transport it is sent with. Chat is not a separate path: a chat send is a
  queue item, and a session carries one item at a time. (S1 § 5.3, § 3.1;
  S3, WR-7)
- {++**CR.64** An item has a kind: a todo, a group, a prefix (a walk over the todos of an id prefix), an iteration (a repeated prompt), a chat send, or a prompt. (S23: vscimpb127, vscimpb128, vscimpb129)++}
- {++**CR.65** An item bound to a todo does more than a prompt: the todo's record is appended to the prompt; the todo is set to in progress when the item is sent and put back when the send fails; and its completion is checked (CR.82). (S23: vscimpb127)++}
- {++**CR.66** A group item walks the members of a group todo in their order, and the user or an agent can choose which of the members still to come are sent; members of another quest are not walked. One walk engine serves prefix, todo and group items. (S23: vscimpb127, vscimpb125)++}
- {++**CR.67** A run executes one item at a time, and the runs execute in parallel. A run whose next item cannot start waits, and its later items do not jump ahead. So while a run waits (`RT > RT-ASKS`, CP.21), nothing else of its queue is executed. (S23: vscimpb46; PQ-24)++}
- {++**CR.68** A todo is queued once: an item whose todos are already staged, pending or being executed in the quest is refused, unless the caller says the repeat is meant. (S23: vscimpb77, ccparity_e_process-2)++}
- {++**CR.69** The states of a queue item: staged (queued but not released; the state of a new item), pending, being executed, done, error, held on a todo's open decisions, held on a blocked todo, interrupted. Staged is distinct from pending. An item that is being executed carries marks: waiting for the user, waiting for an event, waiting for its background work, held, needs attention, yields after this iteration. (S23: vscimpb55, vscimpb37, vscimpb112; S17, the user guide § 4)++}
- {++**CR.70** A run's queue settings are: automatic sending; automatic start; automatic pause when all its items are done (on by default); automatic continuing after a restart; the defaults of new items (transport, profile, prompt template, session; planned: role and guideline choices); and the number of walk continuations (CR.82). Shared by all runs are only the models for compaction and for memory extraction. (S23: vscimpb60a; gsel3, planned)++}
- {++**CR.71** Whatever stops sending by itself stops one run only: an error, an interrupt, a walk that needs attention or is held, out of budget, the automatic pause, a pause after this item. Switching automatic sending off never interrupts the item that is being executed. (S23: vscimpb60a, vscimpb168)++}
- **CR.16** A host sends a prompt into a run's queue in one of three ways:
  at the end, next (before the waiting items), or as an update to the prompt
  that is being executed. An update that arrives after that prompt's execution has
  finished is queued next, and the answer says so. {++A pending item that is being edited is not sent until it is saved.++} (S1 § 5.3, § 3.2; S3,
  WR-7)
- {++**CR.72** An update to the prompt being executed also reaches a turn that waits (a declared wait, the item's own background work), and the wait goes on afterwards. Where an update is taken depends on the kind of transport: an agent transport takes it as a further user message of the running query, a model transport as the next user message of its tool loop; a declared wait returns with the message and is entered again with the same end. Each message is kept with the item, together with what became of it, and recorded in the journal of asks and answers (CR.55). (S23: vscimpb173)++}
- {++**CR.73** A repeating item holds its run until its last iteration. "Next" (CR.16) under a repeating item means between two of its iterations. A repeating item can let the next pending item go first and resumes after it, its position kept. An item can be marked to pause its run when its last stage is done. (S23: vscimpb60e; S17, the user guide § 4)++}
- {++**CR.74** The commands a user has on an item that is being executed: answer its open ask; resend the stage (the turn is cancelled and the same stage is sent again, with a note that it was interrupted); skip to the next stage or todo; stop (the item goes back to staged). Resend, skip and stop close an open ask unanswered (`RT > RT-ASKS`). Continuing an item that waits always offers these choices and never acts by itself, and a question that waits long has no time limit of its own. (S23: vscimpb55, vscimpb78)++}
- **CR.17** A run has an option, kept by the runtime, for how results are
  taken: *review each result*, where a prompt's changes come back as a
  preview and the {~~queue~>run~~} waits{++, as for an ask (`RT > RT-ASKS`, CP.21),++} until the host reports that the user applied
  or discarded them; or *work silently*. Changing the option while a result
  waits leaves that result waiting. {++Webwork needs every run of its own AI to start in *review each result* (S25: 13_woneb2, planned); which value a new run starts with is for the Solution Blueprint to settle.++} (S1 § 5.3, § 3.2; S3, WR-7)
- **CR.18** A run can start a {~~new conversation with the model~>session over~~}: the next prompt starts
  without the earlier context{~~, and the earlier conversation~>; the session keeps its name and its definition, and what was said before~~} stays readable
  in the trail. (S1 § 3.2; S3, WR-7{++; PQ-25++})
- {++**CR.75** A session has a base, a lifetime and optionally a profile. The lifetimes are: *continue* (one conversation; with a base, its first prompt starts from the base's conversation), *per prompt* (every prompt starts again from the base, or fresh, and changes nothing), and *per iteration* (one conversation per repetition or per todo of a walk, which its pre-prompts and follow-ups continue). (S17, the user guide § Named sessions; S23: qrun1)++}
- {++**CR.76** An item whose profile cannot continue the existing conversation of its session is refused when it is queued. (S17, the user guide § Named sessions)++}
- {++**CR.77** A temporary session is created for one item and removed when the item and its done notification are done. (S17, the user guide § Named sessions)++}
- {++**CR.78** A session can be deleted, with its storage. (S17, the user guide § Named sessions)++}
- {++**CR.79** Planned: a session carries a choice that is required when it is created, "contributes to trail and memory". With it off, the session's turns go neither into the host's trail nor into memory or history. Sessions that exist count as on. (S22 § 2.2 CQ-7, CQ-14, CQ-18)++}

> **❓ PQ-25 (2026-11-20T15:00+01:00) — "new conversation" and the session:** When a run starts a new conversation with the model, is that a new session, or the same session starting over?
>
> **Context:** `RT > RT-QUEUE`, CR.18: "A run can start a new conversation: the next prompt
> starts without the earlier context, and the earlier conversation stays readable in the trail."
> The agreed terms define a **session** as "one conversation with a model, with its history;
> named, and belonging to a run", and CR.8 names a run's sessions `<session>@<run>`. Webwork's
> requirement behind CR.18 (S3, WR-7) keeps every run of its AI panel in the one session
> `default@<run>` and offers *New conversation* per run. The word **conversation** is also an
> agreed term of its own for something else: a sequence of messages between users of a team
> (messaging through tac). The **trail** is the durable record of what a run did.
>
> **Why I ask:** If a session is exactly one conversation with a model, then starting a new
> conversation must create a new session, with a new name; but the requirement keeps the name
> `default@<run>` across it. If the session stays and only its history starts over, then a session
> is not "one conversation" but a named place that holds one conversation at a time. The glossary
> entry for session, CR.18 and the interface (is there a command "new session" or "restart
> session"?) depend on it. I only added "with the model" to CR.18 so that the word is not read as
> a conversation between users.
>
> - **(a)** The session stays and starts over: the same named session begins a new conversation with the model, with empty history; what was said before stays in the trail. CR.18 would read "A run can start a session over: the next prompt starts without the earlier context …", and the glossary would define a session as a named line of conversation with a model that can be started over.
> - (b) A new session is created: "new conversation" makes a new named session in the run and the run's next prompt is executed in it; the old session stays, with its history. CR.18 would say so, and a host would have to show and name the sessions of a run.
> - (c) Both exist as separate commands: starting a session over, and creating a new session.
>
> *Recommendation:* (a) — it is what the extension does today and what WR-7 asks for (one session per run, started over on request), and it keeps session names stable for queue items that name their session.
>
> *Assumption until answered:* CR.18 says "a new conversation with the model" and does not say whether the session is the same.
>
> **Answer (2026-11-20T15:22+01:00):** (a)

- **CR.19** The queue walks a group of todos, lowest number first, one
  iteration per todo; it repeats items; {++and ++}it sends timed requests on a schedule{--
  and reminders after a wait--}. {++The queue itself sends no reminders: the reminders there are, are a todo's (CR.50), the one reminder to an agent about its background work (CR.88) and tac's message kind (`TAC > TAC-KINDS`, CM.4).++} (S1 § 5.3, § 3.1{++; S22 § 2.3 AC-22++})
- {++**CR.80** A walk takes the open todo with the lowest number. It passes completed and cancelled todos and the user's own (CR.48). It holds at the first todo it cannot run, never earlier: a todo with open decisions, or one blocked by a todo that is not done (a blocker that runs earlier in the same walk, or in an item ahead of it, does not hold). The item is then held, its run is held (its automatic sending is switched off), and the user is notified. (S23: vscimpb37; PQ-24)++}
- {++**CR.81** On a held item the user can stop it, continue (the todo is skipped and the walk goes on) or run the todo anyway. Skipping a todo is the user's action, never the runtime's choice. A walk with nothing to do ends as an error at once. (S23: vscimpb37)++}
- {++**CR.82** After each todo of a walk the runtime reads the todo. When it is not completed and names no blocker, decision or open question, the runtime sends a continuation into the same session, at most a set number of times (2 by default, set per item and per run); then the item stops as "needs attention" and its run is held. The answer kept for the todo is that of the last turn. (S23: vscimpb58)++}
- {++**CR.83** Planned: when the blocker of a held item is completed or cancelled anywhere (in the same run, another run or another quest), the item goes back to pending, and its run's automatic sending is switched on again if the hold switched it off; a run the user paused stays paused. This is a setting per run, on by default, and holds for a release condition on a package version too. Until it is built, a held run goes on when the user resumes it. (S23: vscimpb179, planned; PQ-8; `DEC`, D-45)++}
- {++**CR.84** Timed requests have two modes (every so many minutes; at times of day, daily or once on a date), a switch for all of them and a switch per entry (both must be on), and a largest number of sends after which the entry pauses. Their tick is the runtime's one clock: the checks of repeated todos and of todo reminders (CR.50) run on it. (S23: vscimpb24, vscimpb152ab; S17, the user guide § 5)++}
- **CR.20** An item that is being executed can {~~be interrupted softly: the update is read at
  the next point where the transport can take it. An item can wait for its
  own background work and for something outside that only time resolves.~>wait, and it can be interrupted; the two are different things. It waits for something outside that only time resolves (a wait the agent declares, CR.85) or for its own background work (CR.86); the item stays in execution and its run waits, as for an ask (`RT > RT-ASKS`, CP.21). An interrupt is the user's: soft (CR.89) or hard (CR.90). An update (CR.16) is neither: it is text the running prompt reads.~~}
  (S1 § 5.3, § 3.1)
- {++**CR.85** The declared wait: an agent declares a wait for something only time resolves, with a reason and an end, at most 48 hours. Its run reports "waiting for an event" with the reason and the time left, and the wait survives a restart. The user can interrupt it: the agent then ends its turn with a note of what is still to do, the item steps back behind the next pending item of its run (to staged when none follows), and its stage is sent again later with a note to resume. (S23: vscimpb82)++}
- {++**CR.86** Waiting for the item's own background work: the work counts as alive while its process is alive, not while it prints. The wait has a limit, set per item, else per profile, else 6 hours (0 means no wait). The user can wait without a limit, start the limit again, or stop waiting. (S23: vscimpb56, vscimpb57)++}
- {++**CR.87** A command that detaches itself from the execution is refused in a queue execution on an agent transport. (S23: vscimpb56)++}
- {++**CR.88** When a turn ends its answer while its background work still runs, the runtime sends the agent one reminder prompt into the same turn; the prompt is a template that can be edited. (S23: vscimpb143)++}
- {++**CR.89** A soft interrupt holds the execution at the result of its next tool call: the turn stays open, and the run's automatic sending goes off. Without a point to hold at within 15 seconds it becomes a hard interrupt, unless the user asked to wait. A turn that waits in an ask, in a declared wait or for background work counts as held at once, and an answer given meanwhile is kept until the resume. Resuming hands the held result back and sends nothing again. (S23: vscimpb112)++}
- {++**CR.90** A hard interrupt cancels the prompt: the item is interrupted, and on resume its current repetition is sent again, with a note, in the same conversation. (S23: vscimpb112)++}
- {++**CR.91** After a restart while an execution was held, a model transport continues where it stopped, and an agent transport is sent the prompt again with the note and the held result. (S23: vscimpb112)++}
- {++**CR.92** An item stopped for lack of credit is marked out of budget, and its run is held. It can be continued on another profile: by the user, by an agent, or automatically through a configured fallback. The stopped stage is then sent as a hand-over prompt (what stopped where, the session's live trail, the original prompt), in the item's session unless that profile cannot continue the conversation, and the later stages follow on that profile. (S23: ccparity_e_process-10)++}
- **CR.21** When an item is done, the queue carries out what its todo names
  for completion (unblocking other todos, notifying, queueing) and delivers
  {~~a done notification~>the done notification that the item or its todo asks for (CR.93, CR.94)~~} to the run and session that queued it. (S1 § 5.3,
  § 2.1)
- {++**CR.93** The done notification is a prompt that is queued ahead of every other pending item when the item is finished, or has ended in an error that will not recover (not for a wait on a quota or a rate limit); once per run of the item. It carries the outcome, the item's answer (per todo for a walk, shortened with a pointer), its title, its todos with their status, and the sending quest and run. It can be aimed at a named quest and run. (S23: vscimpb71, vscimpb72)++}
- {++**CR.94** Every item records who queued it: the quest, the run and the session. A todo's done notification has no default: it goes to the run and session that queued the todo, and without one nothing is sent, which is logged. (S23: vscimpb146)++}
- **CR.22** A todo can name the profile it is executed with; the todo's choice wins
  over the item's. {++The team's allowed providers (CS.6) limit both choices. Planned (S23: vscimpb174).++} (S1 § 3.1)
- {++**CR.95** A todo can name the role and the guideline choices (CR.61) it is executed with. (S23: gsel1; S24)++}
- {++**CR.96** Planned: the role of a queued prompt is the todo's, else the item's, else the role of the step that queued it, else the run's; a run's queue defaults (CR.70) may name a role. (S24, R-1 … R-4; S23: gsel3)++}
- {++**CR.97** Planned: a todo can name chat variables that are set while it runs, with a flag to unset them when it is finished. A todo's profile that does not exist, or that cannot continue the session of its walk, is an error when the item is queued, never a fallback. (S23: vscimpb174)++}
- **CR.23** A run reports its state as events{~~: working, waiting for a
  decision, failed with a retry possible.~>. It is one of the following, the first that applies (S23: vscimpb123, vscimpb112; PQ-24):~~}
  - {++**waiting for the user**: an ask, an approval, a plan, a pick or a document ask of the run is open;++}
  - {++**waiting for an event**: a declared wait (CR.85), with its reason and until when;++}
  - {++**waiting for its own background work** (CR.86);++}
  - {++**running**;++}
  - {++**paused**: by the user, with the count of its pending items;++}
  - {++**idle**;++}
  - {++and **held**: its next item is not executed (open decisions, a blocked todo, needs attention, an error, out of budget), or a soft interrupt holds its execution.++}

  {++A run **waits** while its item is still being executed and blocked in something; its settings are untouched and it goes on by itself when the cause ends. A run **is held** when its next item is not executed at all; its automatic sending is off, and it goes on when the user resumes it (CR.83). **Paused** is what the user did to a run. Each state carries its detail and is published with the runtime's registration (`TAC > TAC-COORD`, CA.5); a waiting run stays waiting across a restart of its host. The Solution Blueprint settles where "held" stands in the order.++}
  Every prompt can be addressed in
  the trail, so a host can show "this prompt" in a run's log. (S1 § 3.2)
- **CR.24** The trail is the durable record of a run. For a prompt that draws
  on a document the host marks as encrypted, the trail is kept in memory
  only. (S1 § 3.2)

### <!--[RT-TRANSPORTS]--> 7.4 Transports

- **CR.25** A prompt reaches a model through a transport, and there are two
  kinds. A **model transport** calls a model's API, and the runtime runs the
  tool loop, the approvals and the retries. An **agent transport** hands the
  prompt to an outside program (an agent SDK or a command line) that runs the loop itself and reaches the runtime's tools
  through MCP. (S1 § 5.4; S7)
- **CR.26** All transports are the runtime's own. A host implements no
  transport. (S2 § 5, FO-2; `SCO > SCO-OUT`, O-4)
- **CR.27** The model transports carry what the direct transport has today:
  prompt caching, one retry layer, usage and cost per round, continuation of
  a cut-off answer, compaction of history, effort and thinking settings.
  (S2 § 3.1; S1 § 3.1)
- {++**CR.98** Usage and cost are reported per round and per prompt on every transport, also in a resumed conversation of an agent transport: the prompt's own rounds, tokens and cost, not the whole session's. (S23: qrfix3)++}
- **CR.28** A soft interrupt {~~is held at the points each transport allows.~>(CR.89) holds an execution at the result of a tool call on every transport; what differs by the kind of transport is where an update is taken (CR.72) and how a held execution continues after a restart (CR.91).~~}
  (S1 § 3.1)
- **CR.29** The runtime can run in a mode that offers only the agent
  transport of the Claude Agent SDK to a host, without a quest, so an
  application ships one Node payload. (S2 § 3.2)
- **CR.30** The runtime speaks the Agent Client Protocol in that protocol's role of the client ("client" and "agent" are the protocol's names for its two sides): one
  adapter reaches every outside program that speaks it in the role of the agent, and the native transport of such a program
  is kept where the protocol loses features. This comes after the
  native transports. (S1 § 5.4, CQ-5)
- **CR.31** The runtime also answers the Agent Client Protocol in the protocol's role of the agent on
  standard input and output, so an editor that speaks it can open a session
  of a quest. It covers chat, updates and permission requests; the queue,
  todos and processes stay in the runtime's own protocol. This comes late.
  (S1 § 6.5, CQ-5)

### <!--[RT-LOCATIONS]--> 7.5 Locations

- **CR.32** The runtime finds every place it needs through one resolver, the
  workspace layout, as it is built in the extension. Outside VS Code the host
  passes the workspace folder and the quest. {++Every host passes the overrides it holds; in VS Code those are the ones of the quest's `.code-workspace` file.++} (S1 § 5.5; S12)
- **CR.33** The resolver answers:
  - the **root**: the nearest folder at or above the workspace folder that
    holds `.tom/tom_root.yaml`; a workspace folder with none above it is
    standalone and its own root;
  - the **`_ai` folder**: the workspace folder's `_ai` as it is opened, else
    the root's; paths are compared by their real path, because the entry is
    a link onto one clone;
  - the **guidelines**: the root's `_agent_guidelines/`, then the workspace
    folder's; a file of the same relative path in the workspace wins{++; a project's own `_agent_guidelines/` is read before both when the work touches that project++};
  - the **quests of a workspace**: those its list
    `_ai/workspaces/<workspace>.yaml` names{~~, else those recorded for the
    folder, else all.~>; without a list, every quest of the register (CR.100).~~}

  (S1 § 5.5; S12)
- {++**CR.99** The places CR.33 names are defaults: the root's `.tom/tom_root.yaml` and a workspace folder's optional `.tom/tom_workspace.yaml` can name other places for the `_ai` folder, the guidelines and the configuration. (S12; S27, `workspace_layout.md` § 2, § 3, § 5)++}
- {++**CR.100** The register `_ai/quests.yaml` lists every quest of the `_ai` state with its type (a classic quest, or a repository quest as a single-quest repository or a multi-quest repository; `PAR > PAR-QUESTS`, CQ.1) and its setup. A workspace's list picks from it. The checkout of a repository quest may be missing on a machine: the runtime reports that as a state of the quest, not as an error of the store. Planned with format version 10 (CR.3). (S22 § 3.4, § 2.4 QM-1, QM-2, § 4)++}
- {++**CR.101** The nested cases, as the resolver has them: the nearest root marker wins, and an inner root inherits nothing from an outer one; a workspace folder inside another has its own `.tom` and the root's as layers; a plain folder without a quest file works on the default quest; in a workspace of several folders the first is the workspace folder. (S12; S27, `workspace_layout.md` § 7)++}
- {++**CR.102** A workspace is named after the root folder its host opened. Planned: what the runtime answers about a workspace includes the repositories of the record (CR.34), each with a description and whether it is cloned on this machine. (S23: vscimpb144; vscimpb154, 00_aifmt-2, planned)++}
- **CR.34** The repositories of a workspace are those of the file the
  workspace is set up from (`repos.yaml`). (S1 § 5.5, CQ-3)
- {++**CR.103** The record gives each repository a kind and a branch, and a repository may be absent on a machine by design. (S27, `repos.yaml`, `workspace_layout_multi.md` § 3)++}
- {++**CR.104** The claims and the integration step respect the record: the integration step lands on the branch the record names for the repository, and a repository the record marks as read-only, or a binaries repository, is never its target. (S27, `repos.yaml`, `workspace_layout_multi.md` § 3; `PAR > PAR-APPROACH`)++}
- **CR.35** A quest lists the repositories and subtrees it usually works on.
  A todo is written with the resources it needs; for a todo that names none, the runtime claims the quest's whole list for as long as the todo is executed. {++No source fixes where a quest's list is recorded (the register of CR.100 has no field for it); the Solution Blueprint settles the place.++} (S1 § 5.5, CQ-3, DQ-5;
  `PAR`)

### <!--[RT-CONFIG]--> 7.6 Configuration

- **CS.1** The configuration is layered, later layers winning: built-in
  defaults, the user's own file, the root's `.tom`, the workspace folder's
  `.tom`, the quest's layer (the same on every machine, and one per machine), the
  host's settings. Objects merge deep; arrays and single values replace.
  {++Of the `.tom` folders only the root's and the workspace folder's are layers.++}
  (S1 § 5.5; S12)
- {++**CS.19** A write goes to the root's file, until the user picks a layer; picking a layer is planned. (S27, `workspace_layout.md` § 5; S23: 13d_wslayout-1 … 13d_wslayout-4, planned)++}
- {++**CS.20** The user's own file is part of the machine-wide state (CR.36): one file for all hosts of a machine and user, at the place of that state (CR.106). This is stated for a host on the user's machine; what a runtime behind the web runtime service has in its place is open (PQ-38). (S12; S27, `workspace_layout.md` § 5)++}
- **CS.2** A write changes one key in one file: it checks that the file has
  not changed since it was read and writes it atomically, so two runtimes
  changing different keys never lose each other's change. (S1 § 5.5; S12)
- **CS.3** The configuration is split by who decides it (S1 § 5.5, DQ-8,
  DQ-11):

  | Part | Holds | Lives |
  | --- | --- | --- |
  | **The repository's** | what belongs to working on code: role types, process definitions, prompt templates{++ (saved prompts are not part of it: they are a store of the quest, CR.54)++} | in the repository, under version control |
  | **The team's** | what belongs to the team as an organisation: the providers and their configurations, which providers may be used, the standard profiles | in tac, as the team's configuration, in whichever backend the team uses |
  | **The runtime's** | queue settings, timeouts, compaction, retries; paths, executables and preferences of a machine or host | per runtime, machine or host, in the layers of CS.1 |

  {++The Solution Blueprint settles in which repository role types, process definitions and prompt templates lie when a quest works on several.++}

- **CS.4** Only a team's owners change the team's configuration. A runtime
  fetches it when it connects, keeps a copy so it starts when it is offline,
  and is told of changes. (S1 § 5.5, DQ-11; `TAC`)
- **CS.5** In the layering, the team's configuration stands above the user's
  own file for the keys the team owns (a user cannot override them) and
  below it for the keys the team only suggests. {++The Solution Blueprint settles: which keys the team owns and which it only suggests; where the copy for offline starts (CS.4) is kept; and that a runtime uses the configuration of the home team of its quest when its person belongs to several teams, the allowed providers of CS.6 included.++} (S1 § 5.5, DQ-11)
- **CS.6** Which providers a runtime may use is decided by the team's
  configuration. (S1 § 5.5, DQ-8; `SCO > SCO-LATER`, L-2)

### <!--[RT-MACHINE]--> 7.7 Machine-wide state

- **CR.36** Some state belongs to all runtimes of a machine together: queue
  settings per quest and run{++ (a writer writes only the runs it changed, CS.2)++}, the user's configuration, which runtimes and
  runs exist and what they do, the inbox for items sent from one quest to
  another{++ (`PAR > PAR-CROSS`, CW.19)++}, notifications for the user{++, the open asks of the machine's runtimes, so that an ask can be answered from another runtime of the machine (`RT > RT-ASKS`), and the usage ledger (CR.105)++}. (S1 § 5.6{++; S23: vscimpb60a, vscimpb168++})
- {++**CR.105** The usage ledger holds usage and cost per day and model for the last 62 days, added as each round's response arrives. (S23: qrfix3; S17, the extension's usage ledger)++}
- {++**CR.106** Nothing of the machine-wide state, of the local tac service's store or of the inbox lies in the `_ai` folder: its top level is a closed list that a commit guard keeps. The Solution Blueprint settles the place outside `_ai`. (S22 § 1, § 3.6)++}
- {++**CR.107** The notifications are one log for the machine, of the two classes `RT > RT-PROTO`, CP.4 names: events on queues and todos, and events directed at the user, among them the answers handed to the user. (S23: vscimpb124, vscimpb170, vscimpb171)++}
- **CR.37** The runtime owns this state. A host or a tool never reads or
  writes its files; it asks its runtime. (S1 § 5.6, CQ-2)
- **CR.38** Inside the runtime there is one interface to this state with two
  implementations: through the local tac service, which runs once per machine
  and user and through which every runtime's access is routed, so concurrent
  access is handled in one place; and through files, one key at a time under
  a file lock, when coordination is switched off. (S1 § 5.6, CQ-2)
- **CR.39** The local tac service outlives a single runtime and carries the
  state from one to the next. (S1 § 5.6)

### <!--[RT-INSTALL]--> 7.8 Installation and lifetime

- **CR.40** There is one {~~installation of the runtime~>runtime installation~~} per machine and user, in
  the application data folder of the operating system, with the provider
  SDKs beside it{++. This is stated for a host on the user's machine (the web runtime service: PQ-38). Which Node runs a runtime outside VS Code is open (PQ-37), and the Solution Blueprint settles where the runtime installation keeps the binaries per platform++} (S1 § 5.7; S2 § 5, FO-3):

  | System | Runtime | Provider SDKs |
  | --- | --- | --- |
  | macOS | `~/Library/Application Support/Tom/runtime/` | `~/Library/Application Support/Tom/providers/` |
  | Linux | `~/.local/share/tom/runtime/` | `~/.local/share/tom/providers/` |
  | Windows | `%LOCALAPPDATA%\Tom\runtime\` | `%LOCALAPPDATA%\Tom\providers\` |

- **CR.41** Versions are installed side by side, each in a folder of its
  own, with a pointer `current` to the newest. A running runtime keeps its
  version until it is restarted. (S1 § 5.7; S2 § 5, FO-4)
- **CR.42** Every host carries a {~~runtime~>runtime installation~~} and installs it into the shared
  location when {~~no runtime~>none~~} is installed there. When one is installed, the
  host uses it. Hosts on one machine thereby share one {~~runtime~>runtime installation, and each starts its own runtime from it~~}. A host
  offers updating the runtime in the part of its settings where it offers
  what can be installed and removed; nothing is updated without the user
  having asked for it. (S1 § 5.7, DQ-9; PQ-6)
- **CR.43** Provider SDKs are installed on request, when a profile first
  needs one. (S2 § 3.2; S1 § 3.1)
- **CR.44** A runtime is started by its host and ends with it. A long walk
  needs its host open{++, and so do timed requests and a todo's reminders (CR.50): they are sent and ring only while a host has the runtime running++}. (S1 § 5.7, CQ-4; `SCO > SCO-LATER`, L-5)
- **CR.45** Inside a running runtime, a run is unloaded when its last
  subscriber has gone and nothing is queued in it. This is an option, not
  part of the first version unless measurement shows the memory is worth the
  added complexity: a runtime ends with its host and loads its runs again
  when the host starts, so a run is not held for long anyway. (S1 § 6.1;
  PQ-21)
- {++**CR.108** A runtime does not run on a phone, on a tablet or in a browser. An application there uses the web runtime client SDK and talks to a web runtime service on a server, which connects to a runtime on the application's behalf. The service is HTTP-based, and one service may serve applications on phones and tablets and web applications. How the events of a run, asks and a host's tools cross it is open. (PQ-28)++}
- **CR.46** A {~~runtime host server~>web runtime service~~} can host runtimes for applications that have none of their
  own: the server side of a web application or of an application on a phone
  or a tablet runs permanently and starts one runtime per connected application, which ends
  with that application's connection. The rule of CR.44 holds: the {~~runtime host server~>web runtime service~~} is the
  host. A runtime that runs for a long time without any runtime client, on an
  always-on machine, is later (`SCO > SCO-LATER`, L-5). {++How the service works (one runtime per connected application, ending with the connection, the service as the host) is assumed until PQ-38 is answered.++} (PQ-16, PQ-9;
  `NFR > NFR-TOPO`, T8)
- {++**CR.110** The web runtime service reaches tac only through the runtimes it starts. It checks a connecting application against its own configuration, or by starting the runtime, which then presents the user's team token. Assumed until PQ-38 is answered. (PQ-26)++}
- {++**CR.109** Open for a runtime behind the web runtime service (PQ-38): whose it is, where its settings, its secrets, its runtime installation and its clones are, how long it lives, and who operates the service. No generation unit, deliverable or user group is named for the service until then.++}

### <!--[RT-SECRETS]--> 7.9 Secrets

- **CS.7** A configuration names a secret and never holds one. The forms of a
  reference (S1 § 5.8, CQ-16; S2 § 5, FO-15):

  | Form | Resolved from |
  | --- | --- |
  | `tsm:<reference>` | Tom Secrets Manager; the reference is in its own grammar, for example `tsm:[env:prod]providers/anthropic#apiKey` |
  | `os:<service>/<account>` | the secret store of the operating system: macOS Keychain, Windows Credential Manager, Linux Secret Service |
  | `env:<variable>` | an environment variable; allowed, marked as not secure |
  | `file:<path>` | a file; allowed, marked as not secure |

- **CS.8** The runtime resolves a reference at the moment the secret is
  needed; the secret is not written to any file of the workspace.
  (S1 § 5.8)
- **CS.9** The runtime is {~~paired with the Tom Secrets Manager service once: it is approved there as a program of its own. A setup guide describes the pairing.~>approved by the Tom Secrets Manager service once, as a program of its own. A setup guide describes the approval.~~} {++The approval is given once for a runtime installation (`RT > RT-INSTALL`, CR.40).++} (S1 § 5.8, CQ-16; S15{++; PQ-32++})

> **❓ PQ-32 (2026-11-20T15:15+01:00) — "pairing" used for two things:** Should "pairing" be kept for devices only, with another word for the one-time approval of the runtime and of tac by Tom Secrets Manager?
>
> **Context:** The glossary (`GLO`) defines **device**, **pairing** as "A machine, phone or tablet of a user; enrolling it once so that it gets a key of its own and may reach the server from the internet." `TAC > TAC-CRYPT`, CI.18 uses it so: "A device that reaches the server from the internet is **paired** first: it is enrolled once, from inside, by its user, and gets a key of its own." Four other places use the word for something else. `RT > RT-SECRETS`, CS.9: "The runtime is paired with the Tom Secrets Manager service once: it is approved there as a program of its own. A setup guide describes the pairing." `USR > USR-GROUPS`, U-7 (the administrator of a tac server): "… pair the tac server with Tom Secrets Manager." `DEC`, D-19: "… the runtime and the tac service are paired with Tom Secrets Manager once." `NFR`, N-30, the list of guides: "… pairing with Tom Secrets Manager". Tom Secrets Manager is the separate product that keeps secrets (provider keys, team tokens); a program that wants to read a secret has to be approved there once, by its user.
>
> **Why I ask:** One word names two different acts with different keys: enrolling a user's device for access from the internet, and approving a program as a reader of secrets. The security model of the Solution Blueprint will cite both, and a reader can take a "paired" runtime for one that holds a device key. The second use is the wording of the product owner's earlier answer (CQ-16), so changing it is not mine to decide.
>
> - **(a)** "Pairing" is used for devices only. For Tom Secrets Manager the text says "approved by": CS.9 would read "The runtime is approved by the Tom Secrets Manager service once, as a program of its own. A setup guide describes the approval."; U-7 "have the tac server approved by Tom Secrets Manager"; D-19 and N-30 likewise.
> - (b) Both uses stay, and the glossary gets a second entry: "pairing (with Tom Secrets Manager): the one-time approval of a program as a reader of secrets".
> - (c) Both uses stay and the glossary is not changed: the context makes clear which is meant.
>
> *Recommendation:* (a) — CS.9 already explains its "paired" with "approved", and one word then has one meaning.
>
> *Assumption until answered:* CS.9, U-7, D-19 and N-30 keep "paired" / "pairing" for Tom Secrets Manager.
>
> **Answer (2026-11-20T15:23+01:00):** (a)

- **CS.10** When the vault is locked, {~~the queue item that needs the secret waits and the user is asked to unlock.~>the user is asked to unlock, and the run of the item that needs the secret waits as for any ask (`RT > RT-ASKS`, CP.21).~~} (S1 § 5.8, CQ-16; S15{++; PQ-24++})
- **CS.11** Besides provider keys, the team tokens of a user are kept {~~as secrets in the same way.~>by the runtime as secrets in the same way, named by secret references: one place per machine and user, for every host.~~} {++A host shows the account (user id, e-mail address, server address) and signs out through the runtime; it supplies no credential through the host interface (`RT > RT-HOST`, CP.13). Webwork plans to keep the team token in its own settings container (S25: 13_woneb6), which differs from this.++} (S1 § 5.8; `TAC`{++; `NFR`, N-17++})

{++CS.7 … CS.11 are stated for a runtime on the user's machine. Where the secrets of a runtime behind the web runtime service are kept, and how such a runtime is approved by Tom Secrets Manager, is open (`RT > RT-INSTALL`, CR.109; PQ-38).++}

### <!--[RT-PROTO]--> 7.10 The protocol

- **CP.1** A host outside the runtime's own process attaches over the runtime
  protocol: JSON-RPC 2.0 with length-prefixed messages over a TCP connection
  on the local machine; a remote runtime client attaches over WebSocket. Inside VS
  Code the extension calls the runtime directly, with the same commands.
  {++For an application behind the web runtime service the wire is HTTP-based (`RT > RT-INSTALL`, CR.108); how the events (CP.4, CP.5) and the reverse requests (CP.10: the asks, opening a document, the host's tools) cross it is open (the question at `CLI > CLI-PACK`, CL.1).++}
  (S1 § 6.1; S2 § 5, FO-5{++; PQ-28++})
- **CP.2** A runtime started as {~~a process~>an operating-system process~~} of its own prints a ready line
  when it accepts connections, ends when its standard input is closed, and
  writes its log to standard error. {++An item whose execution was cut off, for example because that operating-system process died, is reported as interrupted (`RT > RT-QUEUE`, CR.69), and the user resends or skips it (CR.74). The Solution Blueprint settles what a host shows and can do when the runtime's operating-system process dies, and what of a half-done execution is kept.++} (S2 § 3.2; S14{++; S17, the user guide § 4; S26: qavs_wwworkbench-3++})
- **CP.3** The protocol has **commands** from the host to the runtime. They
  cover everything the engine does: the queue and timed requests{++, with the commands on an item that is being executed (`RT > RT-QUEUE`, CR.74)++}; processes
  (proceed, skip, back, decide, subprocesses, runs); sessions{++, with starting a session over (CR.18)++}; todos;
  memory; templates; profiles; chat variables; review rounds; coordination;
  calling a tool. (S1 § 6.1; S2 § 3.2{++; PQ-25++})
- {++**CP.36** Messaging and documents are among the commands, because an application has no connection to tac of its own (`TAC > TAC-PEOPLE`, CI.4) and reaches both through its runtime: the conversations by newest activity with their unread counts, the history of a conversation in pages, sending with a request id, the read state, muting, threads attached to a document or a review round, the members of the team, uploading and downloading a blob with the size limit known before sending, extending and releasing the blobs of a review round, and the review request and its return. The list is what Webwork needs. Where the cache of conversations and the outbox of a user's messaging are kept, in the runtime or in the host, is open (the question at `TAC > TAC-CONV`, CM.7). (PQ-30; PQ-26; S25: 13_woneb6 … 13_woneb10, planned)++}
- {++**CP.37** One command answers what is being executed or is scheduled in a runtime: an item that is being executed, a timed request that waits. A host asks it before it ends, so it can tell the user what ending would stop. Tom Forge needs it. (S26: qavs_wwworkbench-3, planned; S14 § 3)++}
- {++**CP.38** The commands also cover what a second host needs for features the extension has: the completion of slash commands and skills, with the prompts for their arguments and their expansion; the assist actions on the questions of a document (asking through a document, proposing an answer, choices that move a process: CP.8); and continuing an item that stopped for lack of credit on another profile (`RT > RT-QUEUE`, CR.92). (S17; S26: qavs_ccparity_d_claudecode-4, qavs_ccparity_i_assist-1, qavs_ccparity_i_assist-2, qavs_dapieff-1)++}
- **CP.4** The protocol has **events** from the runtime to its runtime clients, one
  stream with subscriptions per connection. An event is one thing the
  runtime tells: a piece of streamed answer text or reasoning, a tool call
  and its result, a queue item changing state, the process position moving,
  an ask opened or {~~answered~>settled (CP.20)~~}, a todo changing status, the usage of a round, a
  trail entry{++, the state of a run (`RT > RT-QUEUE`, CR.23), the progress of a subagent, an arriving message and a changed read state (CP.36), the state of a quest whose checkout is missing on the machine (`RT > RT-LOCATIONS`, CR.100)++}. (S1 § 6.1, CQ-6{++; S26: qavs_ccparity_d_claudecode-4++})
- {++**CP.39** The notifications are of two classes. Events on queues and todos: an item queued or deleted; a todo created, edited or changed in status. Events directed at the user: an ask opened, or closed with its answer or the reason; a message an agent sends the user, with its urgency; an answer handed to the user (`RT > RT-TOOLS`, CT.17); suggested processes; a process decision that waits; a todo that waits for decisions; a todo that is the user's to do; a run that is held, with the cause (a decision needed, an error, an item that needs attention, a blocked todo). Each event records the quest, the run and who caused it: an agent (with its transport, profile and session, and the item and todo it worked on), the user, or the runtime by itself. The log is kept for the machine (`RT > RT-MACHINE`, CR.107). (S23: vscimpb124, vscimpb170)++}
- **CP.5** The events of a run are numbered. A runtime client reads "after number N,
  then follow". That serves a runtime client that reconnects, a second one on the same run, and one that attaches late. (S1 § 6.1, CQ-6)
- **CP.6** The numbered events are kept in memory with a bound. A runtime client
  further behind than the bound reloads the run from the trail files, which
  stay the durable record. (S1 § 6.1, CQ-6)
- **CP.7** A conversation with a model is modelled as thread, turn and item: a session
  holds turns, a turn holds items (text, reasoning, tool call, ask, result),
  and an item has started, delta and completed events. A turn can be steered
  and interrupted. This shape is a proposal, not a decision: the product
  owner's direction is that the wire follows what the tools and the hosts
  need, and that the records it carries are worked out as object models
  from the schemas the workspace already has for the extension (CP.35). The
  interface specification settles the shape of a conversation on the wire.
  {++Starting a session over (`RT > RT-QUEUE`, CR.18) ends the thread and begins a new one in the same session.++}
  (S1 § 6.1; PQ-21{++; PQ-25++})
- **CP.8** Every question the runtime puts to a person has one form, the
  **ask envelope**: a stable id, a kind (question, pick, document, tool
  approval, plan, decision, gate), the allowed responses, an optional schema
  of the response, {~~a declared default and a deadline~>and a deadline together with a safe default, both only when the one who asks declares them: an ask without them waits without a limit~~}. {++An allowed response can be an action the runtime carries out itself when it is chosen: a process move, the start of a branch or of a subprocess, finishing a review round, the choices of a decision or of a gate. The runtime makes the move, not the agent; it acts on the run of the prompt that asked, not on the run a host shows; and every such response is checked when the ask is opened.++} The ways an agent asks
  today stay as they are: a review outside a turn, the tool that asks single
  questions, and questions inside a document; the envelope is the one record
  the runtime sends a host for any of them. Like CP.7 it is a proposal that
  the interface specification settles, from the object models of CP.35.
  (S1 § 6.1; PQ-21{++; S23: vscimpb120, vscimpb85, vscimpb104, vscimpb89++})

- **CP.9** An ask outlives the operating-system process that asked: a pending ask is a stored
  record, the turn can end, and the run resumes when the answer arrives.
  That is what lets an ask travel to another device or person.
  {++The open ask is stored with its queue item. When the turn that asked has ended, for example by a restart of the host, the item stays in execution, the ask is shown again with the same content, and the answer is delivered as the next prompt in the same session, quoting the question and the answer. Resend, skip or stop meanwhile close the restored ask (CP.42).++}
  (S1 § 6.1, CQ-7{++; S23: vscimpb166++})
- **CP.10** The protocol has **reverse requests** from the runtime to the
  host: the asks, notifications, opening a file or a document, and the
  host's tools. (S1 § 6.1, § 6.2)
- **CP.35** The link between a host and its runtime is an API with callbacks in both directions: the host calls the
  runtime, and a tool an agent calls in the runtime can call straight into
  the host to trigger what the host has to show or do, in the way the
  extension's script server lets Dart code call VS Code today. Under it is a
  wire protocol of JSON structures whose details follow what the tools need.
  The records it carries (quest, todo, run, queue item, session, question,
  trail entry and the others) get object models, worked out from the schemas
  the workspace already has for the extension's files. (PQ-21; CP.10)
- **CP.11** The protocol is published as a JSON schema in the runtime's
  package. The runtime client SDKs generate their protocol layer from it and are
  checked against it. {++Whether the web runtime client SDK is generated from the same schema is open (the question at `CLI > CLI-PACK`, CL.1).++} (S1 § 6.1; S2 § 5, FO-10)
- **CP.12** The commands are a superset of the methods scripts use today
  through the extension's JSON-RPC server, so what a script does there it can
  do against a runtime. (S2 § 3.2; S1 § 2.1)

### <!--[RT-HOST]--> 7.11 The host interface

- **CP.13** The runtime reaches its host's world through one interface and
  nothing else. It supplies (S1 § 6.2):
  - locations (the workspace folder and the quest);
  - identity: the kind of host, the user, and the member id the user has in
    review rounds;
  - configuration (the host's settings layer);
  - the asks: a question, a pick, a document to work on, a tool approval,
    accepting a plan, a decision;
  - a notification to the user;
  - opening a file, and opening a document for reading or review;
  - the host's tools.

  {++The host supplies no credential through it: the team tokens of a user are the runtime's (`RT > RT-SECRETS`, CS.11).++}
- **CP.14** In VS Code the interface is implemented in the extension's
  process; in every other host it is carried by the protocol's reverse
  requests. (S1 § 6.2)
- **CP.15** A host refuses a call it has no concept for, with a reason, and
  the runtime leaves out what depends on it. {++Whether a host may instead answer a host tool by forwarding it to another host, as Tom Forge plans towards a running VS Code window (S26: qavs_wwworkbench-5), is open (PQ-36).++} (S1 § 6.2; S2 § 3.1)

### <!--[RT-TOOLS]--> 7.12 Tools

- **CT.1** There are three sets of tools, by where they can live (S1 § 6.3;
  S2 § 5, FO-17):

  | Set | Carried out by | Holds | Offered to |
  | --- | --- | --- | --- |
  | **Runtime tools on `_ai`** | the runtime | todos, queue, processes, sessions, memory, chat variables, review, coordination, messaging, {++asking the user (CP.8), handing the user an answer without waiting (CT.17), declaring a wait (`RT > RT-QUEUE`, CR.85), ++}the specification tools and the runner of the TomSpecs binary | every transport, and through the runtime's MCP server also other runtimes |
  | **Runtime tools on files** | the runtime | reading, editing and finding files, running commands, the web, git | the model transports only; never through the runtime's MCP server |
  | **Host tools** | the host | what only that host can do: in VS Code the editor, language services, commands, the document browser, notebooks; in Webwork its document tools; in Tom Forge its equivalents | the transports of the run or prompt they are registered for |

- **CT.2** The tools keep the names they have today, so every prompt that
  names a tool keeps working. (S1 § 6.3; S4, note e)
- **CT.3** An agent transport that brings file, command and web tools of its
  own uses its own; the runtime's tools of the same purpose are hidden from
  it. (S2 § 3.3, FO-17)
- **CT.4** A host registers its tools with its runtime: for each a name, a
  schema and a description, for a run or for a single prompt (the tools of
  the part of the application a prompt is sent from). (S1 § 6.3, § 3.2; S3,
  WR-7)
- **CT.5** The runtime offers a registered host tool to the transport and
  calls the host back over the protocol when the agent calls it. The host
  carries it out and returns the result; an error or a refusal comes back as
  a tool error. (S1 § 6.3, § 3.2)
- **CT.6** The runtime signals the boundaries of a prompt to the host: when a
  prompt starts and when it ends. A host uses them to group what a prompt
  wrote (for undo) and to offer the preview of CR.17. (S1 § 6.3, § 3.2)
- **CT.7** The trail shows, for each prompt, the set of tools it was given.
  (S1 § 3.2)
- **CT.8** Inside VS Code the extension may offer its tools to the runtime as
  one MCP server instead of single registered tools. (S1 § 6.3; S2 § 5,
  FO-6)
- **CT.9** The role a prompt is executed in decides which tools it gets: a role type
  names its tools. {++A todo can name the role it is executed with (`RT > RT-QUEUE`, CR.95).++} (S1 § 6.3, § 3.1)
- **CT.10** The tool set grows with the products that run in the runtime.
  TomSpecs adds tools for keeping linked sections of specification documents
  in step and switches for rendering a document for reading; its documents
  are worked on through one bundled binary, and a missing binary is reported
  as such. {++A tool that needs a binary (the build tool, the TomSpecs binary) looks for a configured one, then for a bundled one, and answers that the binary is missing for this platform, with help, when there is none. The runtime's list of the projects of a workspace, which the scopes of todos and prompts and the project-list tool use, comes from the build tool's listing, with a built-in port of the same rules as the fallback.++} (S1 § 3.5{++; S23: vscimpb83, vscimpb84, vscimpb147, vscimpb103++})
- {++**CT.17** A tool hands the user an answer without waiting for anything: a title, the answer as Markdown and the user's question quoted, with suggested todos (complete records, written when the user clicks, filed as by the agent) and suggested prompts (only copied, never queued). The call returns at once, and the turn goes on. The answers are kept out of the trail and shown with their read state across quests. Planned: they are kept in the journal of asks and answers, per host and quest (`RT > RT-HOLDS`, CR.55). (S23: vscimpb171; 01_aifmt-4, planned; S22 § 2.2)++}

### <!--[RT-MCP]--> 7.13 The MCP servers

- **CT.11** The runtime has an MCP server that offers the runtime tools on
  `_ai`. It reads and writes only `_ai` state and offers no access to files
  or an editor, so it is safe to offer to other machines. {++Host tools are not reachable through it (CT.1; `NFR`, N-18).++} (S1 § 6.4; S4,
  first notes)
- **CT.12** The MCP server asks for a bearer token. {++Who issues the token, how a team runtime obtains it and what the server checks is open (the question at `TAC > TAC-PEOPLE`, CI.13). The Solution Blueprint settles how several runtimes on one machine get the ports of their MCP servers, and what the server's card says when two hosts serve one workspace, which Tom Forge needs (S26: qavs_none-3).++} (S1 § 6.4, § 3.6)
- **CT.13** A runtime can publish its MCP server as an endpoint through tac,
  so the other team runtimes find it and call its tools.
  (S1 § 6.4; `TAC`)
- **CT.14** Inside a runtime, the tools of the local runtime, of the host and
  of a remote runtime are all presented to the agent as tools; routing a
  call to the right place is part of carrying the tool out. (S4, note e;
  S2 § 3.3)
- **CT.15** The runtime names the revision of MCP it speaks, and keeps what
  differs between revisions (long-running tasks) behind an adapter.
  (S1 § 6.4, § 15.1)
- **CT.16** The runtime is also an MCP client of external MCP servers, as the
  engine is today. (S1 § 6.4, § 3.1)

### <!--[RT-ASKS]--> 7.14 Routing and escalation of asks

An ask must not get lost{~~, and it must not hold a process up for long~>: it is escalated, and it can be seen for as long as it is open. While it is open, its run waits (CP.21) and the other runs go on; the user can answer it, or skip or resend the item that waits (`RT > RT-QUEUE`, CR.74)~~}
(S1 § 6.6, CQ-7{++; PQ-24++}).

- **CP.16** Every quest has a quest owner. {++The Solution Blueprint settles where the quest owner is recorded and who may change it.++} (S1 § 6.6, CQ-7)
- **CP.17** An ask has a chain of people: the person the process or the todo
  names, if any; then the owner of the quest the ask belongs to; then the
  owner of the quest whose todo triggered it; then the owners of the team.
  (S1 § 6.6, CQ-7, DQ-3)
- **CP.18** For each person in the chain: the ask is shown on the host that
  asked; after 10 minutes without an active runtime client there it goes through tac
  to that person's other devices; after a set time without an answer it
  moves on to the next person, and the previous one keeps seeing it. The set
  time is 4 working hours unless the team or the ask says otherwise.
  {++The Solution Blueprint settles what working hours are, by what a process or a todo names a person, and what the chain is when the quest owner leaves the team or the quest's team is a personal team.++}
  (S1 § 6.6, DQ-3)
- {++**CP.40** An open ask is offered to every runtime client attached to the runtime, and to the other runtimes of the machine through the machine-wide state (`RT > RT-MACHINE`, CR.36). The first answer settles it; the answer is the same wherever it was given, and the ask closes everywhere it is shown. (S23: vscimpb173, vscimpb170)++}
- **CP.19** An ask goes to another person only when the process or the todo
  names that person, or by the chain. (S1 § 6.6, CQ-7)
- **CP.20** At the end of the chain the ask stays open and is marked
  unanswered. Nothing is decided automatically, unless the ask declared a
  default; then the default is taken and recorded as taken by default.
  {++An ask is **settled** when it is answered, when it is closed unanswered because the execution that asked was ended (CP.42), or when its declared default is taken. A run that waits for an ask nobody answers can so be given up: the user skips or resends the item that waits, or stops it (`RT > RT-QUEUE`, CR.74).++}
  (S1 § 6.6, DQ-3{++; S23: vscimpb55, vscimpb78++})
- **CP.21** {~~While an ask waits, the run that asked waits; the other runs and the rest of the queue go on, and a walk goes on with the next todo that does not depend on the waiting one.~>While an ask of a run is open, the run that asked waits: nothing further is sent from its queue until the ask is settled (CP.20). The other runs go on.~~} {++The item that asked stays in execution and is not moved to another state. Nothing else of its run is sent meanwhile: not the next item, not the next todo of a walk, not its follow-ups. The settings of the run are untouched, and the run goes on by itself when the ask is settled, unlike a run that is held (`RT > RT-QUEUE`, CR.23). Whether the execution keeps its leases while its run waits, and whether a chat send in another session of that run still goes out, is open (PQ-39).++} (S1 § 6.6, DQ-3{++; PQ-24; S23: vscimpb46, vscimpb55, vscimpb82, vscimpb123++})

> **❓ PQ-24 (2026-11-20T15:00+01:00) — what waits while an ask is open:** When an item's execution asks a person something, does only that execution wait, or the whole run (the queue) it belongs to?
>
> **Context:** Three items of `RT` say "the run" where the agreed terms now leave two readings.
> `RT > RT-ASKS`, CP.21: "While an ask waits, the run that asked waits; the other runs and the
> rest of the queue go on, and a walk goes on with the next todo that does not depend on the
> waiting one." `RT > RT-PROTO`, CP.9: "An ask outlives the process that asked: a pending ask is a
> stored record, the turn can end, and the run resumes when the answer arrives." `RT > RT-ASKS`,
> CP.22: "… the answer returns to the run that asked."
> The terms: a **run** is a queue that executes todos and prompts and lives for weeks; a quest has
> several runs working in parallel. An **execution** is the work on one item of that queue, from
> the moment the run sends the item until it is done or given up. A **session** is one
> conversation with a model; an item is executed in a session, and a session carries one item at a
> time (CR.15), but a run has several sessions. A **walk** is one item that goes through a group of
> todos, one todo per iteration (CR.19). An **ask** is a question the runtime puts to a person.
> When these items were written, "run" was also used for the work on one item.
>
> **Why I ask:** CP.21 contradicts itself under the agreed terms: if the run, which is the queue,
> waits, then "the rest of the queue" and the walk in it cannot go on. Replacing "run" by
> "execution" removes the contradiction but decides something: that a run keeps executing its
> other items (in its other sessions, and the next todos of a walk) while one of its executions
> waits for an answer. The other reading is that the run holds everything behind the waiting item
> and only *other* runs go on. Which one holds changes what a user sees while a question is open,
> what CP.9 means by "resumes", and how long a process step can be held up by one unanswered ask.
>
> - **(a)** Only the execution that asked waits. The run goes on with its other items that do not depend on the waiting one (a walk with its next independent todo), and the other runs go on. CP.21 would read "the execution that asked waits; its run goes on with the items that do not depend on it, and the other runs go on"; CP.9 "the execution resumes when the answer arrives"; CP.22 "the answer returns to the execution that asked". One open question then never stops a run.
> - (b) The run that asked waits as a whole: nothing further is sent from its queue until the answer arrives; only the other runs go on. CP.21 would lose "the rest of the queue" and the walk clause. Simpler to follow, but one unanswered ask holds a run for as long as the escalation chain takes.
> - (c) The session waits: the run goes on only with items that are executed in another session; items queued for the same session wait behind the ask. CP.21 would say so. This follows from CR.15 (a session carries one item at a time) and is between (a) and (b).
>
> *Recommendation:* (a) — CP.21 already says the walk goes on with the next todo that does not depend on the waiting one, and its purpose (the lead-in of `RT-ASKS`: an ask "must not hold a process up for long") is met only if the run keeps working.
>
> *Assumption until answered:* CP.21, CP.9 and CP.22 keep "the run that asked" unchanged and unmarked.
>
> **Answer (2026-11-20T15:26+01:00):** (b), please review the recently done todo and currently existing todos in vscode extension for more details, there have been some important additions and also look at al_the_bear for a planned restructuring of the _ai folder and an updated and for now definite approach to quests in repos (which I'd consider the standard from now on).

- {++**CP.41** A run has at most one open ask at a time, whatever its kind: a question, a pick, an ask in a document, the proposal of a plan. A second ask from the same run while the first is open is refused, not queued. Asks of different runs are open at the same time and are answered in any order. A tool approval belongs to the execution whose tool call waits. (S23: vscimpb81; PQ-24)++}
- {++**CP.42** An ask belongs to the execution of its item. When that execution is ended (stop, resend, skip, a hard interrupt), every wait it is blocked in ends at once, on every transport: a question and a pick close unanswered, an approval counts as denied, a plan as not accepted, and the tool answers that the prompt was ended. An answer given after that is not delivered, and the ask closes for everyone it was shown to or escalated to. (S23: vscimpb78, vscimpb33)++}
- {++**CP.43** Waiting for time or for an event outside is not an ask. An agent declares such a wait (`RT > RT-QUEUE`, CR.85); nobody is asked and nothing is escalated. Its run waits by the rule of CP.21 and reports a state of its own, "waiting for an event" (CR.23). (S23: vscimpb82)++}
- {++**CP.44** An answer handed to the user without waiting (`RT > RT-TOOLS`, CT.17) is not an ask either: nothing is open afterwards, and no run waits for it. (S23: vscimpb171)++}
- **CP.22** Whoever has an ask can forward it to any member of the team, with
  a note. The chain continues from that person, and the answer returns to
  the run that asked. (S1 § 6.6, CQ-7, DQ-3)
- **CP.23** Every open ask of a team can be seen with its age, who has it{~~ and~>,~~}
  where it is in its chain{++ and which run waits for it. Planned: every ask and its answer is recorded in the journal of asks and answers (`RT > RT-HOLDS`, CR.55)++}. (S1 § 6.6, CQ-7{++; S22 § 2.2 QJ-1++})

Asking a person outside the team is deferred (`SCO > SCO-LATER`, L-3).

{++What of CP.17 … CP.23 a team on the GitHub backend has is open (the question at `TAC > TAC-BACKENDS`, CA.26), and so is how a phone or tablet whose application is not running learns of an ask (the question at `TAC > TAC-CRYPT`, CI.18).++}

### <!--[RT-VERSIONS]--> 7.15 Versions and compatibility

A runtime update often comes with a new format of the workspace and quest
files, and an older runtime does not work on newer files (S1 § 6.7, DQ-9).

- **CP.24** On connect, three versions are checked: the protocol's, the
  runtime's, and the format of the workspace files. (S1 § 6.7, DQ-9)
- **CP.25** An older runtime client keeps working with a newer runtime. It does not
  get the new features, and nothing it does breaks. Within a major version
  the protocol only grows: commands and fields are added, none changed or
  removed. (S1 § 6.7, DQ-9)
- **CP.26** Unknown fields pass through. A runtime client that reads a record,
  changes a field and writes the record back returns every field it did not
  know unchanged. Every runtime client SDK does this. (S1 § 6.7, DQ-9)
- **CP.27** A runtime client SDK tells its host through callbacks when the
  runtime was updated, when the workspace files were migrated to a format
  the host's runtime cannot work on, and when the host is too old for the
  runtime it found. The host decides what to show and do. (S1 § 6.7, DQ-9)
- **CP.28** A runtime that finds workspace files in a newer format than it
  knows stops working on them, says that they were upgraded from somewhere
  else, and offers the update of the runtime. (S1 § 6.7, DQ-9; PQ-6)
- **CP.29** A migration of the workspace files runs once per machine, under
  a file lock on that machine; the other runtimes on the machine pause while it runs. {++Once one runtime of a machine has migrated, the other runtimes of that machine pause every run, refuse new sends and list what is still being executed, each with an interrupt, until they are restarted. A runtime that finds files in an older or a newer format does not start its normal parts and says why, instead of working on them (CP.28, CP.33). The migration runs from the runtime installation, and the merge drivers of the `_ai` files come with it and are checked on an upgrade. When a migration runs, and whether the user confirms it first, is open (PQ-40).++} (S1 § 6.7,
  § 3.1{++; S23: vscimpb142, vscimpb142a … vscimpb142d; 01_aifmt-5, planned++})

- **CP.30** The aim is that the protocol and the formats become very stable
  after a while. (S1 § 6.7, DQ-9)
- **CP.31** A host that finds an installed runtime too new for it switches
  off every feature that would use the runtime, or refuses to start, and asks
  the user to update the application. (PQ-6)
- **CP.32** A runtime is updated only after the user was asked. The question
  is put actively when the runtime meets workspace files it cannot work on
  because they were upgraded elsewhere. (PQ-6)
- **CP.33** A runtime that finds workspace files in an older format than it
  works on offers two ways: to migrate the files to its format, or to go back
  to an older version of the runtime that works on the old format, if there
  is one the application is compatible with. When there is none, it says so
  and offers only the migration. Files are never migrated without the user
  having confirmed it. (PQ-6)
- **CP.34** The usual course is that the runtime and the workspace files are
  updated together, when the first host has been updated. The other hosts
  keep working because a host is compatible with several versions of the
  runtime, through the runtime client SDK and the protocol's backward
  compatibility (CP.25). (PQ-6)

{++CP.24 … CP.27 are stated for a host that carries a runtime. What of them holds for an application behind the web runtime service, which installs no runtime, is open (the question at `CLI > CLI-PACK`, CL.1).++}

### <!--[RT-PROVIDERS]--> 7.16 Model providers

- **CS.12** A provider is reached in one of three ways (S7; S1 § 5.4):

  | Way in | How | Providers |
  | --- | --- | --- |
  | **The provider's agent SDK or command line** | an agent transport of its own | GitHub Copilot (its SDK), OpenAI (the Codex SDK), Google (the Gemini command line), Mistral (its coding agent) |
  | **An endpoint compatible with Anthropic's API** | the direct transport and the Claude Agent SDK transport with a base address | DeepSeek, OpenRouter, Moonshot, Zhipu, MiniMax; Claude on Amazon Bedrock and Google Vertex AI |
  | **An endpoint compatible with OpenAI's API** | the client for local models grown into a provider client | xAI, Meta's Llama API, DeepSeek, Baidu, Mistral, OpenRouter, Alibaba, Groq, Together, Fireworks, Cerebras, Azure OpenAI |

- **CS.13** GitHub Copilot is reached only through direct calls and its SDK.
  (S2 § 5, FO-2)
- **CS.14** A provider configuration carries its endpoint, the models it
  offers (read from the provider where it lists them), and its prices, so
  usage and cost are shown per provider. {++Usage and cost are reported per round and per prompt (`RT > RT-TRANSPORTS`, CR.98) and kept in the usage ledger (`RT > RT-MACHINE`, CR.105). The configuration can name the profile on which an item that ran out of budget is continued (`RT > RT-QUEUE`, CR.92).++} (S7; S2 § 3.8)
- **CS.15** One conformance table checks every provider configuration: a
  prompt, a tool call, streaming, usage. (S2 § 3.8; S7)
- **CS.16** Two agent libraries are evaluated behind the transport
  interface, one as a model transport and one as an agent transport, before
  it is decided whether the runtime takes them. (S1 § 5.4; S2 § 3.8)
- **CS.17** A new transport maps its stream onto the runtime's events (text,
  reasoning, tool call, tool result, retry, notice, usage), bridges the
  runtime's tools, routes approvals, and returns the answer, with a session
  id where the outside program of an agent transport owns the conversation. {++Starting a session over (`RT > RT-QUEUE`, CR.18) then means a new session id of the outside program under the same session name.++} (S7, "How the runtime
  reaches a model today"{++; PQ-25++})
- **CS.18** The providers beyond today's transports are built in the
  runtime, after the transports have moved into it; none is built in the
  extension first. (S2 § 3.8; S7)

## <!--[CLI]--> 8 Client SDKs, UI components and supervision

### <!--[CLI-PACK]--> 8.1 The client SDKs

- **CL.1** {~~There are client SDKs for~>The runtime client SDK and the tac client SDK exist in~~} nine languages: Dart, TypeScript,
  JavaScript, Python, Java, Go, Rust, C and C++. All nine are part of the
  first {~~delivery~>version~~}: Dart, TypeScript and JavaScript tested thoroughly (CL.7),
  the other six with the generated protocol layer and their convenience
  layer, checked by the conformance suite. {++Whether TypeScript and JavaScript are one client SDK, which would make it eight languages, is open (PQ-42).++} (S1 § 12.1; S4, note k; PQ-7)

- **CL.2** In {~~every language~>each of the nine languages~~} there are two client SDKs, each in a package of its
  own: the **runtime client SDK**, which speaks the runtime protocol, and the
  **tac client SDK**, which speaks TAC. The runtime client SDK depends on the
  tac client SDK. {++The Solution Blueprint settles what the runtime client SDK takes from the tac client SDK, since an application never speaks to tac itself (CL.11).++} (S1 § 12.1, CQ-15)
- {++**CL.12** Three client SDKs exist (PQ-28; PQ-26; PQ-30):++}
  - {++the **runtime client SDK**, with which a host speaks the runtime protocol to its runtime (`RT > RT-PROTO`, CP.1): for an application on a machine where a runtime runs. In nine languages (CL.1);++}
  - {++the **tac client SDK**, which speaks TAC to tac: for runtimes and command-line programs of ours, for no application and no server (CL.11). In nine languages (CL.1);++}
  - {++the **web runtime client SDK**, which talks over HTTP to a web runtime service on a server (`RT > RT-INSTALL`, CR.108): for an application on a phone, on a tablet or in a browser, built with Flutter or not, where no runtime runs. In Dart and in JavaScript / TypeScript.++}

  {++Open for the web runtime client SDK (PQ-41): whether it is a client SDK of its own or the runtime client SDK with a second way to connect; whether it has the two layers of CL.4 and the convenience layer of CL.5, as far as that applies where no runtime can be found or started; whether the two Dart SDKs offer one programming interface, so that an application and the Flutter components (`CLI > CLI-UI`, CU.1) work over either; how events, asks and the host's tools cross HTTP (CP.1); and whether CL.6, CL.8 and CL.9 hold for it. CL.4 to CL.10 are stated for the runtime client SDK and the tac client SDK.++}
- **CL.3** The places (S1 § 12.1; S2 § 5, FO-11):

  | Package | Place |
  | --- | --- |
  | The Dart runtime client SDK | `tom_ai/ai_build/tom_ai_runtime_client` |
  | The Dart tac client SDK | `tom_ai/ai_build/tom_tac_client` |
  | The client SDKs of the other eight languages | `tom_ai/ai_build/tom_ai_runtime_nondart/<language>/` |
  | {++The web runtime client SDK, in Dart and in JavaScript / TypeScript++} | {++not named until PQ-41 is answered++} |

- **CL.4** A client SDK has two layers. The **protocol layer** is generated from
  the protocol's JSON schema. The **convenience layer** is written by hand
  in each language and is the same in every language. Which generator
  writes what, and what more can be generated, is named at the start of
  Phase 4 (`NFR > NFR-GEN`). (S1 § 12.1; S2 § 5, FO-10; PQ-17)
- **CL.5** The convenience layer of the runtime client SDK: find {~~or start the
  installed runtime~>the runtime installation and start a runtime from it~~}, connect, subscribe to events, queue a prompt, walk a
  group of todos, answer an ask, register the host's tools{++, and messaging and documents for the host's user (`RT > RT-PROTO`, CP.36)++}. That of the
  tac client SDK: connect, send a message, send documents for review, receive.
  {++Tom Forge needs more of it for a runtime it started: to report the runtime's exit with its last log lines, to start it again, and to subscribe again from the numbered events (CP.5); and to ask what is being executed or scheduled before it ends (CP.37).++}
  (S1 § 12.1{++; PQ-30; S25: 13_woneb6, planned; S26: qavs_wwworkbench-3, planned++})
- **CL.6** One conformance suite checks every client SDK in every language
  against a running runtime and a running tac service. It includes the
  pass-through of unknown fields (CP.26). {++It drives each tac client SDK by a test program of its own, without a runtime, since no application uses that SDK (CL.11).++} (S1 § 12.1, § 6.7{++; PQ-26++})
- **CL.7** The Dart and the TypeScript and JavaScript client SDKs are tested
  thoroughly, beyond the conformance suite; they are the client SDKs of the
  platforms the product itself is built on. (S1 § 12.1; S4, note k)
- **CL.8** A client SDK carries the version checks and the upgrade callbacks of
  `RT > RT-VERSIONS`. (S1 § 6.7, DQ-9)
- **CL.9** The Dart runtime client SDK has no dependency on Flutter. (S1 § 3.3)
- **CL.10** The Dart runtime client SDK grows out of today's Dart client of the
  extension's script server: its wire layer, its feature APIs and its mirror
  of the Claude Agent SDK. Scripts that use that client keep working against
  a VS Code window and against a runtime. (S2 § 3.5; S1 § 2.1)
- **CL.11** An application reaches tac through its runtime. The tac client SDK is
  used by runtimes{~~, servers and tools~> and command-line programs of ours; no server uses it~~}. An application in a browser, on a
  phone or on a tablet uses the {~~runtime client SDK against a runtime on a runtime host server~>web runtime client SDK against a web runtime service, which reaches tac through the runtime on the server~~}
  (`RT > RT-INSTALL`, {~~CR.46~>CR.108, CR.110~~}). (S1 § 12.1, § 7.3, WQ-1{++; PQ-26; PQ-28; PQ-30++}; `NFR > NFR-TOPO`, T8)

> **❓ PQ-26 (2026-11-20T15:40+01:00) — who uses the tac client SDK besides runtimes:** Which "servers" use the tac client SDK: the runtime host server itself, or none besides the runtimes it starts?
>
> **Context:** `CLI > CLI-PACK`, CL.11: "An application reaches tac through its runtime. The tac
> client SDK is used by runtimes, servers and tools. An application in a browser, on a phone or on
> a tablet uses the runtime client SDK against a runtime on a runtime host server." The **tac
> client SDK** is the library a program uses to speak the protocol TAC to tac (the service for
> coordination between runtimes and messaging between users). The agreed terms define it as the
> SDK "which the runtime uses to reach tac". A **server** is always named with its kind; there are
> three: the **tac server** (tac running for a team; it is what a tac client connects to), a
> **runtime host server** (the program that runs permanently for applications on phones, tablets
> or in a browser and starts one runtime per connected application; `RT > RT-INSTALL`, CR.46) and
> an **MCP server** (a runtime's tool interface). The sentence comes from the concept document
> (S1 § 12.1), written before these kinds were named.
>
> **Why I ask:** "servers" has no kind, and no kind fits without saying something new. A runtime
> host server starts runtimes, and each of those reaches tac with the tac client SDK; whether the
> runtime host server also talks to tac itself (to register, to check a user's team token before
> it starts a runtime, to be found by an application) is stated nowhere. Naming it in CL.11 would
> add that requirement; dropping "servers" would exclude it. What the first version's runtime host
> server has to implement depends on it, and so does who is a participant in tac (today: users and
> runtimes only).
>
> - **(a)** No server uses it: CL.11 reads "The tac client SDK is used by runtimes and tools." A runtime host server reaches tac only through the runtimes it starts; it checks a connecting application against its own configuration or by starting the runtime, which then presents the user's team token. tac's participants stay users and runtimes.
> - (b) The runtime host server uses it too: CL.11 reads "… by runtimes, runtime host servers and tools." The runtime host server connects to tac itself (for example to check a team token before it starts a runtime, or to publish its address as an endpoint). tac then knows a third kind of program, and `TAC` needs an item saying what a runtime host server may do there.
> - (c) Leave the word open in Phase 1: CL.11 reads "… by runtimes and tools, and by other programs of ours where they need tac", and the Solution Blueprint decides for the runtime host server.
>
> *Recommendation:* (a) — it matches the agreed definition of the tac client SDK and the rule that every application reaches tac through a runtime, and it keeps tac's participants to users and runtimes.
>
> *Assumption until answered:* CL.11 keeps the word "servers" unchanged, with a remark pointing to this question; nothing is added or removed.
>
> **Answer (2026-11-20T15:28+01:00):** (a)

### <!--[CLI-UI]--> 8.2 The Flutter UI components

- **CU.1** `tom_ai/ai_build/tom_ai_runtime_ui` holds every reusable
  component of the runtime's user interface, for Flutter, over the Dart
  runtime client SDK. {++On the web, on iOS and on Android no runtime runs, and an application there has the web runtime client SDK (`CLI > CLI-PACK`, CL.12); over which SDK the components work there is open (PQ-41).++} (S1 § 12.2; S2 § 5, FO-11; CQ-14{++; PQ-28++})
- **CU.2** The components take their look from the application through theme
  parameters. (S1 § 12.2, § 3.2)
- **CU.3** The package depends on nothing of Tom Forge. Tom Forge's own view
  package is built on top of it and keeps only what binds the components
  into the Forge shell. (S1 § 12.2, CQ-14)
- **CU.4** The components build for desktop, web, iOS and Android.
  (S1 § 12.2)
- **CU.5** The basis of each component is what the extension shows today.
  The components' names follow the ones the web component kits for agent
  work have settled on, since no Flutter kit covers agent work. {++What becomes of the Flutter packages with agent and todo views that exist over other backends (`LAND > LAND-BUILT`, E-20), and whether the Todos group is built on one of them, is open (PQ-44).++} (S1 § 12.2,
  § 15.5)
- **CU.6** The component groups (S1 § 12.2):

  | Group | Components | Starts from |
  | --- | --- | --- |
  | **Conversation** | conversation, message, prompt input with the three send choices{++ and the completion of slash commands and skills (`RT > RT-PROTO`, CP.38)++}, attachments, reasoning, tool card, context and usage, model and profile selector | the chat panel |
  | **Asks** | question, pick, confirmation of a tool call, plan approval, decision, gate result with its buttons, document ask; the ask inbox{++, which shows for each open ask the run that waits for it and since when (`RT > RT-ASKS`, CP.23) and closes an ask in every place once it is settled (CP.40); the answers handed to the user (`RT > RT-TOOLS`, CT.17); planned: the journal of asks and answers, with the questions and decisions across quests (`RT > RT-HOLDS`, CR.55)++} | the ask panels, plan mode, the document asks{++, the answers page++} |
  | **Queue** | queue list ({~~waiting, running, done~>the states of an item and the marks of an item that is being executed: `RT > RT-QUEUE`, CR.69~~}; reorder, edit, remove){++, the commands on an item that is being executed (answer, resend, skip, stop: CR.74)++}, item editor{++ for the kinds of an item (CR.64)++}, timed requests{++ with their switches (CR.84)++}, templates | the queue editor |
  | **Runs and processes** | run tabs with {~~state marks~>the state of the run and what it waits for or is held by (CU.17)~~}, process view (phases, steps, proceed, decide, skip, back), branching, runs overview | the process view, the runs overview |
  | **Todos** | todo list and tree, todo editor, decisions, {++todos that are the user's to do, todo offers to accept or refuse (`PAR > PAR-CROSS`, CW.26), ++}session todos, todo log, the panel across quests | the todo panels |
  | **Trail** | live trail, summary trail, a bounded Markdown view that only appends | the trail viewers, the output channels |
  | **Sessions and memory** | sessions{++ with their base, lifetime and profile, started over or deleted (`RT > RT-QUEUE`, CR.75)++}, memory, chat variables, notes, personal notes | the sessions view, the editors |
  | **Messaging** | conversation list, conversation, composer, document card, review request card, reminder, people | new; from tac |
  | **Review** | the review component for Markdown documents: questions and answers, comments, marks, team chips, votes, conflicts, consolidation | the document browser |
  | **Supervision** | runtime list, what waits{++ or is held, per run (CU.17)++}, notifications{++ of both classes (`RT > RT-PROTO`, CP.39)++}, the coordination page (claims, leases{++ with the executions that hold them++}, the integration queue), status of the machine's runtimes | the window status and notifications views; new |
  | **Settings** | profiles, providers and keys, coordination, team administration, what the extension's status page holds | the status page |

- **CU.7** The bounded Markdown view keeps the last so-many lines or
  kilobytes and forgets the rest; it follows its end. It serves a run's log
  and an application's own log channels. {++It works without a connection to a runtime, on text its host gives it, and the host sets its bound per use.++} (S1 § 3.2; S3, WR-7{++; S25: 06_woneb8, 13_woneb4, planned++})
- **CU.8** The trail components show streamed text, reasoning, tool cards,
  the summary of a prompt, and the marks of a prompt that waits for the
  user to apply or discard its result. (S1 § 3.2)
- **CU.9** The review component for Markdown documents is one Flutter
  component, shared by Webwork, Tom Forge's quest application and trc.
  {++Where it is built, and in which form, is open (PQ-43): the quests `webwork` and `tom_forge` plan it outside this product, as the extension's document browser page shown in a web view and as a Dart component in the `tom_forge` repository (S25: 09_woneb5; S26: 05b_woneb1 … 05b_woneb5, planned). The protocol between the extension's document browser page and its host (S23: 01b_woneb1, 01b_woneb2) is an input for the component's interface. An application of its own for reviewing is not part of this product (`SCO > SCO-OUT`, O-10).++}
  (S1 § 3.3; S11)
- {++**CU.16** What Webwork needs of the messaging components: the kinds of attachment, the kinds of card and the actions on a card come from the host (attaching a file, an item, a section or a document; on the card of a received copy: open, save into, merge, remind me, make a todo); the conversation list, the conversation and the composer are separate components, so that a host lays them out narrow, full or as two screens (CU.15); and they show the states of `TAC > TAC-DOCS`, CV.9. How the components take what the host supplies is for the Solution Blueprint. The components are Flutter components; the messaging views of the VS Code extension are the extension's own (`SCO > SCO-OUT`, O-1). (S25: 13_woneb7 … 13_woneb9, planned; `TAC > TAC-KINDS`, CM.3; PQ-30)++}
- {++**CU.17** A run that waits or is held says so wherever it is shown. The run tab, the runs overview, the queue and the supervision components show the state of the run (`RT > RT-QUEUE`, CR.23), what it waits for or is held by (an ask, a lease another execution has, a secret to unlock, a time or an event, its own background work, a result to apply or discard, a blocked todo, open decisions, an error) and since when. (PQ-24; S23: vscimpb123, vscimpb124)++}

### <!--[CLI-SCREENS]--> 8.3 Screen and component descriptions

The design is delivered as descriptions and running code, not as drawings
(S1 § 12.3, CQ-18, DQ-7).

- **CU.10** There is a complete inventory of the extension's screens: every
  view, panel and editor, and for each one what it becomes here.
  {++Tom Forge's todos for its quest application each name a feature of the extension and what it needs from the runtime; they are the check of the inventory (S26: qavs_ccparity_…, qavs_dapieff-…).++}
  (S1 § 12.3, DQ-7)
- **CU.11** What a screen of the extension becomes is one of (S1 § 12.3,
  DQ-7):

  | Outcome | Meaning |
  | --- | --- |
  | **reused** | the component follows the extension's layout |
  | **starting point** | the function is needed; the layout is designed anew |
  | **split** | one screen becomes several components |
  | **host's own** | it stays specific to VS Code; there is no component |
  | **not needed** | it has no counterpart among the runtime's components |

- **CU.12** There is a description per screen and component, drawn from the
  extension: the code of its views, screenshots, and what defined them. A
  description names the elements, their layout, the states (loading, empty,
  error, waiting for an answer), the actions, and the data each needs from
  the runtime client. (S1 § 12.3, CQ-18)
- **CU.13** Everything that can be described now is described completely.
  The extension keeps changing, and the descriptions are amended as it does.
  (S1 § 12.3, DQ-7)
- **CU.14** `tom_ai_runtime_ui` contains a gallery application that shows
  every component with made-up data. It is the living design and the place
  the components are tried. (S1 § 12.3, CQ-18)
- **CU.15** The screens built from the components exist in three widths: a
  desktop panel, a narrow side panel, a phone. They are: the AI panel
  (conversation, queue and trail, switchable or side by side); process and
  runs{++, with the state of each run and what it waits for (CU.17)++}; todos; the ask inbox with its escalation; messaging; the review
  editor and the consolidation view; supervision (the overview of
  team runtimes, the detail of a runtime); the coordination page; settings and team
  administration. (S1 § 12.3)

The inventory as it stands. {--___check here___ --}The outcomes are a first pass
from the names of the extension's views and handlers, not yet from their code;
{~~each is decided when the screen is described.~>the Solution Blueprint confirms each from the code when the screen is described.~~} (S1 § 12.3; S17)

| Id | Extension screen | Outcome (first pass) | Component group |
| --- | --- | --- | --- |
| **SC-1** | The chat panel | reused | conversation |
| **SC-2** | The bars for a question, a pick, a tool approval and a plan approval | reused | asks |
| **SC-3** | The panel of open interactions, user notifications{++, the answers page++} | starting point (the ask inbox) | asks |
| **SC-4** | Queue editor, queue entry, queue templates | reused | queue |
| **SC-5** | Timed requests editor | reused | queue |
| **SC-6** | Process view, process branching | reused | runs and processes |
| **SC-7** | Process editor, process template editor | starting point | runs and processes |
| **SC-8** | Runs overview | reused | runs and processes |
| **SC-9** | Quest todos, session todos, workspace todos, the todo panel | reused | todos |
| **SC-10** | Quest todo editor | reused | todos |
| **SC-11** | Todo log | reused | todos |
| **SC-12** | Trail viewer, trail editor, quest logs | reused | trail |
| **SC-13** | Output channels | starting point (the bounded Markdown view) | trail |
| **SC-14** | Sessions view, session pickers | reused | sessions and memory |
| **SC-15** | Memory panel, chat variables editor | reused | sessions and memory |
| **SC-16** | Quest notes, workspace notes | reused | sessions and memory |
| **SC-17** | VS Code notes | host's own | — |
| **SC-18** | The document browser, with questions, marks, team review, consolidation | starting point (the review component) | review |
| **SC-19** | Window status | starting point (the list of team runtimes) | supervision |
| **SC-20** | Notifications | reused | supervision |
| **SC-21** | Status page | split (providers, profiles{~~, coordination, diagnostics each on their own~> and coordination each on their own; the state of the machine's runtimes; the diagnostics of the extension's own parts stay the host's own~~}) | settings; supervision |
| **SC-22** | Editors for prompt templates and reusable prompts | reused | settings |
| **SC-23** | Roles editor | reused | settings |
| **SC-24** | The workspace panel (guidelines, documents, logs) | starting point{++ for the logs; the rest host's own++} | {~~partly host's own~>trail~~} |
| **SC-25** | Resources, prerequisites, the issues panel, the test panels | host's own | — |
| **SC-26** | Reload overlay, migration screens{++, the screen of a runtime that does not start on files in another format (`RT > RT-VERSIONS`, CP.29)++} | starting point (the version callbacks) | settings |
| **SC-27** | {~~—~>none in the extension:~~} messaging: conversations, composer, document and review cards | new | messaging |
| **SC-28** | {~~—~>none in the extension:~~} the coordination page: claims, leases{++ with the executions that hold them++}, the integration queue | new | supervision |
| **SC-29** | {~~—~>none in the extension:~~} team administration: members, invitations, devices | new | settings |
| {++**SC-30**++} | {++none in the extension: todo offers, to accept or refuse (`PAR > PAR-CROSS`, CW.26)++} | {++new++} | {++todos++} |
| {++**SC-31**++} | {++planned in the extension: the view of questions and decisions across quests, over the journal of asks and answers (S23: 01_aifmt-4; `RT > RT-HOLDS`, CR.55)++} | {++starting point++} | {++asks++} |

{++The inventory has no row for the management of quests (the register of quests, `RT > RT-LOCATIONS`, CR.100, and the operations of `PAR > PAR-QUESTS`, CQ.7), which the extension plans as a view of its own (S22 § 4; S23: 02_aifmt-1, planned), and `CLI > CLI-UI`, CU.6 has no component for it nor for repository quests, which Tom Forge needs (S26: qavs_wwwgitruntime-1). Whether those operations are commands of the runtime, so that every host gets screens for them, is open (the question at `PAR > PAR-QUESTS`, CQ.7).++}

### <!--[CLI-TRC]--> 8.4 The supervision application (trc)

- **CK.1** trc shows a team's team runtimes in one view: what each runtime
  does, and what waits — questions, todos that need a decision, the state of
  the queues, runs, errors, claims, messages. {++For each run it shows the state the runtime reports with its registration (`RT > RT-QUEUE`, CR.23; `TAC > TAC-COORD`, CA.5) and what the run waits for or is held by, since when (`CLI > CLI-UI`, CU.17); a quest is listed with its short description (`RT > RT-HOLDS`, CR.56).++} (S8; S1 § 12.4; S2 § 3.6{++; PQ-24++})
- **CK.2** trc is a full remote control: more or less everything a runtime
  can do can be done through it. It queues todos and walks, starts and
  pauses runs and queues, continues processes (proceed, decide, gates),
  answers asks, and lets the user review documents with the review
  component; the result goes back to the run that asked. {++What remote control covers and what it excludes is open (the question at `TAC > TAC-PEOPLE`, CI.13), and so is whether trc contains the review component (PQ-43).++} (S2 § 3.6,
  FO-12; S8)
- **CK.3** Its focus is supervising team runtimes, not development work
  on one machine. What it adds to the components it is built from is the overview.
  (S2 § 3.6, FO-12; S1 § 12.4)
- **CK.4** A user supervises their own runtimes, or some of the team runtimes.
  {++The Solution Blueprint settles whether trc shows one team at a time or all of the user's teams side by side (`TAC > TAC-PEOPLE`, CI.12).++}
  (S8; S2 § 3.6)
- **CK.5** Remote control is possible only inside a team, and only for a
  runtime whose host allows it by a setting. (S1 § 7.3, CQ-10)
- **CK.6** trc is built from the Dart runtime client SDK and the Flutter
  components{++; on a phone or a tablet from the Dart web runtime client SDK (CK.10)++}. (S1 § 12.4; S2 § 3.6{++; PQ-28++})
- **CK.7** trc is a Webforge application from the start, beside Webwork, the
  quest application and the core Forge application. It also runs standalone,
  outside Tom Forge, first and for testing; it may depend on packages of Tom
  Forge. {++Tom Forge's shell builds for the desktop and for tablets and not for phones (planned), so the desktop and the tablet build of trc may use it, and the phone build does not (CK.10).++} (S2 § 5, FO-12{++; S26: wwkit3, `decisions.tom_forge.md` forgeinv9++})
- **CK.8** trc finds a team's team runtimes through tac, by the endpoints
  they publish, and attaches to each runtime's numbered events.
  (S1 § 9, flow F10; S2 § 3.6)

- **CK.9** The open asks of a team, with their age{~~ and~>,~~} their place in the
  chain{++ and the run that waits for each++} (CP.23), are part of trc's view. (S1 § 6.6{++; PQ-24++})

- **CK.10** trc runs on the phone and the tablet in the first version, beside
  the desktop. On the desktop it has a runtime of its own that serves no
  quest{++ (in which team such a runtime registers is open: the question at `TAC > TAC-PEOPLE`, CI.2)++}; on a phone or a tablet {~~it uses a runtime on a runtime host server~>no runtime runs: it uses the web runtime client SDK and talks to a web runtime service on a server, which connects to a runtime on its behalf~~}
  (`RT > RT-INSTALL`, {~~CR.46~>CR.108~~}). The architecture for applications on phones
  and tablets is part of the first version{++ (`DEC`, D-51); no solution is given for it yet, and whether phones and tablets stay in the first version is one of the open points (the question at `TAC > TAC-CRYPT`, CI.18). Which runtime the service connects trc to, and so which runs a phone shows and steers, is open (PQ-38). The phone layout of trc is built from the phone-width screens of `tom_ai_runtime_ui` (`CLI > CLI-SCREENS`, CU.15), without Tom Forge's shell (CK.7)++}. (PQ-9{++; PQ-28; S26: wwkit3++})
- **CK.11** A phone or tablet {~~reaches the tac server and the runtimes~>is used~~} from
  the internet as well as from the local network or the VPN: looking at what
  is going on and answering questions while away is what the application is
  for. Every access from the internet is strict (`TAC > TAC-PEOPLE`, CI.10),
  and a device is paired first and gets a key of its own
  (`TAC > TAC-CRYPT`, CI.18). {++Which program a device reaches from the internet and which holds the device keys is open, and so is how a phone whose application is not running learns of an ask (the question at `TAC > TAC-CRYPT`, CI.18).++} (PQ-9{++; PQ-28++})
- **CK.12** Whether the VPN can be used from an iPhone and from an Android
  device is checked{++ by the quest `al_the_bear`, which runs the VPN++}, so that the application can be tried on the VPN before
  the access from the internet is opened. {++No todo for the check exists there yet (`RISK > RISK-DEPS`, R-20).++} (PQ-9{++; S27++})

## <!--[TAC]--> 9 Coordination and messaging (tac)

tac is one service with two jobs: it lets runtimes find each other and keep
out of each other's way, and it carries what users who work with those
runtimes send each other. Its protocol is TAC. What is built is `tac/1.0` in
local mode (`LAND > LAND-BUILT`, E-3); this section states what tac is to be.

### <!--[TAC-JOBS]--> 9.1 Two jobs, one service

| Job | For | Area |
| --- | --- | --- |
| **Coordination** | runtimes: presence, discovery, leases on named resources, held by a runtime for an item of a run, messages between runtimes, endpoints | `CA` |
| **Messaging** | users, and runtimes acting for them: conversations, messages of several kinds, documents, reminders | `CM`, `CV` |

- **CA.1** Both jobs are done by one service. They share the identities, the
  transport, the store and the tac server. (S1 § 7.1)
- **CA.2** Coordination and messaging both happen in a **team**
  (`TAC > TAC-PEOPLE`): its members message each other, and its members'
  runtimes, the **team runtimes**, coordinate
  (`TAC > TAC-PEOPLE > TAC-GROUPS`, CA.39). (S5 § 3.2; PQ-23; S21, C-4)

### <!--[TAC-COORD]--> 9.2 Coordination between runtimes

**Presence and discovery**

- **CA.3** A runtime registers with its team: its id, its kind, its
  machine, its workspace, the quests it serves (none for a runtime without a
  quest), the repositories it coordinates with the state of their clones,
  and the person it belongs to. The repositories are what the runtime says
  about itself, for the answer to who works where (`PAR > PAR-APPROACH`,
  CW.13, CW.16); they are not a list tac gives leases from (CA.42).
  (S5 § 3.3; S1 § 7.3; PQ-23)
- **CA.4** A runtime is present while it holds its connection to the
  service. The service computes presence; no tac client writes it. (S5 § 3.3,
  § 5.2)
- **CA.5** A runtime keeps its current state with its registration — per
  quest and run the process position, the number of open asks, of queue
  items needing attention and of reviews waiting, and the state of its queue
  — so a tac client that connects late shows the right picture at once.
  (S5 § 3.3)
- **CA.6** Any team runtime can list the team runtimes with their
  presence and state. One quest may have several runtimes. (S5 § 3.3, § 5.2)
- **CA.7** Runtimes find each other through tac and nowhere else: on one
  machine, across the VPN, and through the relay beyond it. (S2 § 3.4;
  S4, note c)

**Who holds a lease**

- **CA.8** The runtime holds a lease, for the item it executes in one of its
  runs; the lease names the runtime's quest, the run, the item, the machine
  and the workspace. That identity outlives the runtime process: after a
  restart or a window reload the new process finds its leases unchanged. The
  word "session" is not used for this; a session is a conversation.
  (S5 § 3.4, § 4.3; S21, TQ-3)

**Leases, resources and fencing tokens**

- **CA.9** A lease is held on resources of two kinds, for now: a whole
  repository, and a part of a repository described by a pattern of paths
  (CA.41). The protocol as built has two more kinds, a declared
  infrastructure resource (something that is not a set of files in one
  repository, such as publishing a package) and a folder of the `_ai` state;
  they are not used for now. (S5 § 3.5 … § 3.7; S6, part-claims; PQ-23)
- **CA.10** A repository is named by its identity at its repository server,
  never by a path on a machine, so the same repository is the same resource
  on every machine, whatever folder its clone lies in. The name is
  `<owner>/<repository>` when the team has one repository server, and in
  full (`github.com/<owner>/<repository>`) when it has several; a runtime
  derives it from the clone's remote. (S5 § 3.5; S21, TQ-8)
- **CA.11** Two resources **overlap** when they name the same repository and
  one is the whole repository, or when they name parts of one repository
  whose patterns can match the same path. A lease is **exclusive** or
  **shared**: tac gives no exclusive lease on a resource that overlaps a
  leased one, and no lease at all on one that overlaps an exclusively leased
  one. Resources overlap only within one team.
  (S5 § 3.5, § 3.7; PQ-23; CA.42)
- **CA.12** A **claim** is the attempt to get leases: it is answered with
  leases on all the resources it names, or with none. When one is held, the
  answer names the holders. (S5 § 4.1, § 6.2; S6,
  part-claims)
- **CA.13** A lease is renewed while its execution works. Not renewed for 60
  minutes, it is **stale**. A stale lease is only shown: no service and no
  tac client takes it over, and only a person frees it. Its resources stay leased
  until then. (S5 § 4.1, § 4.2; S6, BP-11)
- **CA.14** Every lease given on a resource carries a **fencing token**, a number
  that only grows per resource. Freeing a lease raises the tokens of its
  resources. A holder whose lease was freed finds out at its next check, and
  a write it still attempts with its old token is refused. (S5 § 3.8, § 4.2)
- **CA.15** Times that decide about leases and presence are the service's
  clock, never a tac client's, so a machine with a wrong clock can neither keep
  a lease fresh nor make one go stale. (S5 § 4.4)
- **CA.16** Resources are not declared anywhere beforehand: a part of a
  repository exists for tac from the moment it is claimed until its lease is
  released (CA.42). The declared units and infrastructure resources of
  the protocol as built (record names of `tac/1.0`) are not needed for that. (PQ-23)
- **CA.17** Todo state and journals are not claimed: todo files, the files
  of questions, decisions and progress, the session history and the process
  state are written by many sessions at once, by design. A runtime claims an
  `_ai` folder for a todo only when the todo names one. (S6, part-claims)

> **❓ PQ-31 (2026-11-20T15:15+01:00) — claiming a folder of the `_ai` state:** When a todo names a folder of the `_ai` state, what does its runtime claim: a part of a repository like any other, or nothing?
>
> **Context:** Two items of `TAC > TAC-COORD` disagree. CA.9: "A lease is held on resources of two kinds, for now: a whole repository, and a part of a repository described by a pattern of paths (CA.41). The protocol as built has two more kinds, a declared infrastructure resource (something that is not a set of files in one repository, such as publishing a package) and a folder of the `_ai` state; they are not used for now." CA.17: "Todo state and journals are not claimed: todo files, the files of questions, decisions and progress, the session history and the process state are written by many sessions at once, by design. A runtime claims an `_ai` folder for a todo only when the todo names one." The terms: the `_ai` state is the shared repository that holds the quests with their todos, documents and process state. A **resource** is what can be leased: a whole repository, or a part of one described by a pattern of paths, named `<owner>/<repository>[#<pattern>]`. A **claim** is the attempt to get leases; a **lease** is the right on a resource for a limited time. `PAR > PAR-APPROACH`, CW.14 adds: "The `_ai` state stays on the main branch: todo and state files are not code, are merged by their own merge drivers and are written file by file."
>
> **Why I ask:** CA.17's last sentence uses a kind of resource that CA.9 says is not used. Under the agreed term a folder of the `_ai` state needs no kind of its own: it is a part of the `_ai` state's repository and can be named with a pattern. Whether that is what CA.17 means, or whether the sentence is a leftover of the protocol as built, decides whether a specification document in a quest folder can be protected by a lease while a todo rewrites it, and whether `tac/2.0` still carries the old kind.
>
> - **(a)** It is a part of a repository like any other. CA.17 would read "A runtime claims a part of the `_ai` state's repository for a todo only when the todo names it among its resources (for example `al-the-bear/tom_agent_state#quests/ai_runtime/specification/**`); todo state and journals are never named." CA.9 stays: two kinds, and the old kind "folder of the `_ai` state" is not used.
> - (b) Nothing of the `_ai` state is claimed in the first version. CA.17 loses its last sentence; two todos that rewrite the same document in a quest are kept apart by agreement, as today.
> - (c) The old kind is used after all: CA.9 would name three kinds in use (a whole repository, a part of one, a folder of the `_ai` state), and CA.17 stays as it is.
>
> *Recommendation:* (a) — it keeps CA.17's protection for documents in a quest and needs nothing beyond the agreed definition of a resource.
>
> *Assumption until answered:* CA.9 and CA.17 stand as they are.
>
> **Answer (2026-11-20T15:30+01:00):** (a), we may run into other types of resources in the future, but for now that is what we need. Using a prefix git:... we can have as many notations as needed and introduce them as they come.

**Messages between runtimes**

- **CA.18** A runtime sends a message to all quests of its team or to named
  quests. The service routes by the target and never reads the type or the
  payload; the meaning of a type is the tac clients' convention. (S5 § 3.9;
  S6, part-messages)
- **CA.19** A **notification** is live only: it reaches the runtimes
  connected at the time and is not stored. A **command** is stored for 7
  days with a delivery state per target quest; the first runtime of that
  quest that acknowledges it takes it, with the outcome taken, refused (with
  a reason) or filed. (S5 § 3.9, § 5.6)
- **CA.20** The notifications runtimes send each other: the process position
  moved; something worth telling the user; an ask started or stopped
  waiting; a queue item needs attention; a review waits; a todo was created,
  started, completed, blocked or unblocked; a runtime came online or went
  offline; a session started or ended; a lease is waited for or was
  released. A released lease wakes the runtimes that wait for it. (S6,
  part-messages)

> **❓ PQ-27 (2026-11-20T15:05+01:00) — what becomes of the "session" record of `tac/1.0`:** Does tac keep a record of its own for whoever holds leases, and what replaces the three places where the Project Idea still says "session" for it?
>
> **Context:** The coordination protocol as built, `tac/1.0`, has a record called `session`: a
> runtime opens a session before it claims, the leases belong to that session, and it closes the
> session afterwards. The agreed terms drop the word for coordination: "the **runtime** holds a
> lease, for the item it executes in one of its runs. A lease names the runtime, the run and the
> item it is for"; a **session** is only a conversation with a model inside a runtime. A **claim**
> is the attempt to get leases, a **lease** the right on a resource for a limited time, an
> **execution** the work on one item of a run's queue. `TAC > TAC-COORD`, CA.8 already says so
> ("The word 'session' is not used for this"). Three items in `TAC` still use the old record:
> CA.20, the list of notifications runtimes send each other: "… a runtime came online or went
> offline; a session started or ended; a lease is waited for or was released."
> CA.26, the GitHub backend: "leases, sessions and endpoints as refs in a coordination repository".
> CA.29: "A quota never blocks giving something back: releasing a lease, deregistering, closing a
> session, acknowledging a command, withdrawing an endpoint, or renewing a lease already held."
>
> **Why I ask:** Replacing the word decides what tac stores and announces. If the holder is fully
> named on each lease, there is nothing left to open, close, store as a ref or announce, and the
> three places lose an entry. If tac still keeps one record per execution that holds leases (so
> that a restarted runtime finds "its" leases under one key, as CA.8 requires), the record needs a
> new name and the three places keep an entry under it. And "a session started or ended" in CA.20
> can also be read as the runtime telling the others that a conversation with a model started,
> which is something else again. The protocol specification `tac/2.0` and the supervision
> application's views (what is listed under a runtime) depend on it.
>
> - **(a)** tac keeps no such record: a lease carries its holder (the runtime, the quest, the run, the item, the machine, the workspace), and that is all. CA.20 would announce "an execution started or ended"; CA.26 would read "leases and endpoints as refs"; CA.29 would drop "closing a session". Simplest; the notification about executions stays, because the others want to know what a runtime works on.
> - (b) tac keeps one record per execution that holds leases, under a new name ("holder record"): opened with the first claim of an execution, closed when the execution ends. The three places keep their entry with that name. Nearest to what is built, one more thing to specify.
> - (c) As (a), and CA.20 loses the notification altogether: what an execution works on is visible from its leases, and nothing separate is announced.
>
> *Recommendation:* (a) — it is what the agreed definition of the holder says (the lease names the runtime, the run and the item), and it removes a record nobody would administer.
>
> *Assumption until answered:* CA.20, CA.26 and CA.29 keep the word "session" as the name of the `tac/1.0` record, each with a remark pointing here; the table of `TAC > TAC-JOBS` already says "leases on named resources, held by a runtime for an item of a run".
>
> **Answer (2026-11-20T15:30+01:00):** (a)

- **CA.21** What a todo names for its completion in another quest, or in
  another run, travels as a command to that quest's runtime. (S6,
  part-messages; S1 § 7.4)
- **CA.22** A tac client shows a type it does not know by the one-line summary
  every payload carries, so a new type never breaks an older tac client. (S6,
  part-messages)

**Endpoints**

- **CA.23** A runtime publishes the endpoints it serves — its MCP server,
  its remote control — with the address, where the address can be reached
  from (the machine, the VPN, the public network), the protocol with its
  version, and how to authenticate, never a secret. The other team runtimes
  list them. (S5 § 3.10; S1 § 6.4)
- **CA.24** An endpoint exists only while its runtime is present. The
  registry says where an endpoint is; the endpoint itself checks who may use
  it. (S5 § 3.10)

### <!--[TAC-BACKENDS]--> 9.3 Backends and modes

- **CA.25** tac is a reusable component of its own: the service and its
  tac client SDKs can be used without the runtime. (S1 § 7.2, CQ-15)
- **CA.26** A workspace names its backend, one of three, in its workspace
  configuration for coordination (S1 § 7.2; S5 § 6.1; S6,
  part-client-and-backends):

  | Backend | For | What it offers |
  | --- | --- | --- |
  | **local** | one machine and one user | everything except accounts and quotas; the service is started by the first tac client that needs it and runs once per machine and user |
  | **GitHub** | one user's machines | leases, sessions and endpoints as refs in a coordination repository; no messages across machines — messages go through each machine's local service |
  | **tac server** | a team, or several | everything, independent of git: accounts, access keys, quotas, an administration interface |

  All three are part of the first delivery. On the GitHub backend a user
  without a tac server coordinates leases across machines; messaging, documents
  and reviews across machines need the tac server. (PQ-10)

- **CA.27** The tac server is the full tac server from the start: accounts, access
  keys kept as salted hashes, quotas per account, the administration
  interface. An **account** is whoever the tac server serves, an organisation or
  a single person (the protocol as built says "customer"); it has several
  teams and many users. A small team's tac server is the same tac server with one
  account.
  (S1 § 7.2, CQ-9; S5 § 3.1, § 3.12)
- **CA.28** The tac server runs long, without the idle stop of the local
  service, with the same store and configuration. Encryption in transit ends
  at a reverse proxy in front of it; the service itself stays without
  dependencies. It answers tac clients in a browser (cross-origin requests; in a
  browser the access key travels as the WebSocket subprotocol). (S1 § 7.10;
  S5 § 9)
- **CA.29** A quota never blocks giving something back: releasing a lease,
  deregistering, closing a session, acknowledging a command, withdrawing an
  endpoint, or renewing a lease already held. (S5 § 3.12)
- **CA.30** The **relay** is part of the tac server. It carries TAC and MCP for
  machines that are not on the VPN and only forwards. A machine
  authenticates to it with a key per runtime that an owner of the team
  issues. What comes through the relay comes from the internet: it is strict
  and from a paired device (`TAC > TAC-PEOPLE`, CI.10; `TAC > TAC-CRYPT`,
  CI.18). How the key per runtime and the paired device's key relate is part
  of the open point for the security model (CI.19).
  (S1 § 7.2; S2 § 5, FO-9; S4; PQ-9, PQ-13)
- **CA.31** With coordination switched off (`mode: off`, the default)
  nothing is coordinated and everything works as it does without tac.
  (S1 § 7.2; S6, IDEA-6)
- **CA.32** When the backend cannot be reached, nothing falls back on its
  own: the queues of the team runtimes stop after their current todo, and the tac client
  recovers by itself when the backend is back. Working locally meanwhile is
  an emergency step a user confirms twice. (S6, BP-7)
- **CA.33** A team's coordination moves from one backend to another by a
  migration that carries its token counters and undelivered commands.
  (S5 § 3.11, § 5.8)
- **CA.34** Every runtime also registers with the local service of its
  machine, whatever its backend. The local service reports, as warnings that
  block nothing: one repository under two different backends, two workspaces
  naming one team with different backends, a listed repository whose clone
  is missing or has another origin. (S5 § 6.4)
- **CA.35** The runtime has one tac client for all of this. The queue, the
  tools, the views and the hosts ask that tac client and never a backend.
  (S6, part-client-and-backends)

### <!--[TAC-PEOPLE]--> 9.4 People, teams and identity

`tac/1.0` knows runtimes only. Messaging and supervision need users and
teams.

- **CI.1** A **team** is a group of users. It has members, team owners,
  invitations, conversations, review sets and the right to control each
  other's runtimes; and its members' runtimes coordinate in it: presence,
  leases, messages between runtimes, endpoints
  (`TAC > TAC-PEOPLE > TAC-GROUPS`, CA.39). (S1 § 7.3, DQ-1; PQ-23)

- **CI.2** A user is a member of one team or of several. A user runs
  several runtimes; each coordinates in the home team of its quest. One
  runtime belongs to exactly one person. (S1 § 7.3, DQ-1)
- **CI.3** A **participant** is a user (a user id, an e-mail address, a
  display name) or a runtime. A runtime names the person it belongs to, so
  what the runtime sends for an agent is attributed to the runtime and to its person. A
  user has several devices, each with its own connection and its own read
  position. (S1 § 7.3)
- **CI.4** Every application reaches tac through a runtime: on the desktop the
  runtime it hosts, in a browser, on a phone or on a tablet a runtime on a
  runtime host server (`CLI > CLI-PACK`, CL.11; `NFR > NFR-TOPO`, T8). tac's
  participants are users and runtimes, never a device on its own.
  (S1 § 7.3, WQ-1)

> **❓ PQ-30 (2026-11-20T15:15+01:00) — what the review application is, and how it reaches tac:** Is the "review application" the glossary names a product of this project, and how does it reach tac while it is not connected to a runtime?
>
> **Context:** The glossary (`GLO`) names a review application three times and nothing else in the document describes it. **application:** "A program a person uses: VS Code with the extension, Webforge, Webwork, the supervision application, the review application; on any device." **host:** "… An application that will only later connect to a runtime (the review application) is a host from then on." **user:** "A person using an application: the application that is a runtime's host, or another application such as the review application." So the glossary knows an application that a user works with before it is connected to any runtime. Against that stands `TAC > TAC-PEOPLE`, CI.4: "Every application reaches tac through a runtime: on the desktop the runtime it hosts, in a browser, on a phone or on a tablet a runtime on a runtime host server. tac's participants are users and runtimes, never a device on its own." (tac is the service for coordination and messaging; a **runtime** is one running instance of the engine; a **runtime host server** is the program that runs permanently and starts one runtime per connected application on a phone, on a tablet or in a browser.) Three items speak of an application that reaches tac: `TAC > TAC-REVIEW`, CV.15: "A reviewer who has access to no repository needs only an application with the review component (`CLI > CLI-UI`) and an identity in tac." `TAC > TAC-DOCS`, CV.5: a review set can be opened by a reviewer outside the VPN "as long as their application reaches tac". `TAC > TAC-BACKENDS`, CA.28: the tac server "answers tac clients in a browser (cross-origin requests; in a browser the access key travels as the WebSocket subprotocol)" — a **tac client** is a program that speaks tac's protocol to tac directly. The hosts of the first version named in `VIS > VIS-SYSTEM` are the VS Code extension, Webforge, Webwork and the supervision application; the generation units (`NFR > NFR-GEN`, G-1 … G-7) contain no review application.
>
> **Why I ask:** The glossary uses a term the document defines nowhere, and what it says about it (an application used without a runtime) contradicts CI.4 unless that application reaches tac directly, which only CA.28 provides for. Three things depend on the answer: whether a review application is in scope and gets a generation unit; whether CI.4 has an exception; and whether CA.28's "tac clients in a browser" stays (nothing else in the first version would be a tac client in a browser).
>
> - **(a)** There is no review application of its own in the first version. Reviewers use an application that contains the review component — Webwork on the desktop, Tom Forge's quest application, or the supervision application, also on a phone or a tablet — and each reaches tac through its runtime, as CI.4 says. The glossary's "review application" stays as the name of a possible later application. CA.28 would lose "tac clients in a browser" for the first version (kept as what the tac server can answer later), and `SCO > SCO-LATER` would get a line for a review application of its own.
> - (b) The review application is a product of this project in the first version: a small application for reviewers (in a browser and on a phone) with the review component and messaging. It reaches tac through a runtime on a runtime host server like every such application, so CI.4 holds without exception and the glossary's "will only later connect to a runtime" is dropped. It is added to the scope, to the hosts of the first version and to the generation units; CA.28 loses "tac clients in a browser".
> - (c) The review application is a product of this project and, until it is connected to a runtime, it speaks to tac directly as a tac client in a browser. CI.4 gets this one exception (messaging and the review exchange only), CA.28 stays, and tac's participants then include a user's application without a runtime. This reopens what was decided for Webwork (every application through a runtime).
>
> *Recommendation:* (a) — the product owner decided that every application reaches tac through a runtime (D-27), no source specifies a review application, and the three applications of the first version already carry the review component.
>
> *Assumption until answered:* The glossary keeps its three mentions; CI.4, CV.5, CV.15 and CA.28 stand as they are; no review application is in the scope or among the generation units.
>
> **Answer (2026-11-20T15:35+01:00):** (a), the review application will never be part of the ai_runtime project. It is currently integrated into the VS Code Extension and will later completed with Webwork and WebForge, first just on desktop, later with a web version. However, this is none of our concern here. An application that needs to connect to tac will go through a runtime and use the runtime client SDK. This can be either webwork directly or the documents reach webwork indirectly. I'm not excluding that there may come additional services that use tac directly (through the tac client SDK), this could be useful to use only some aspects of tac, like messaging. This isn't planned for the moment. For the moment messaging will be in Webwork through the runtime and we'll add messaging into the VS Code extension once the ai runtime is build.

- **CI.5** A team has team owners and members. What each may do (S1 § 7.3, DQ-2;
  PQ-12):

  | Operation | Member | Team owner |
  | --- | --- | --- |
  | send messages, send and return documents, answer and forward questions | yes | yes |
  | see the team's members, runtimes, leases and open questions | yes | yes |
  | control another member's runtime remotely (where its host allows it) | yes | yes |
  | free a stale lease | their own | anyone's |
  | remove a device | their own | anyone's |
  | invite a person, remove a member | no | yes |
  | make a member a team owner, or take that away (never from the last team owner) | no | yes |
  | change the team's configuration and settings (providers, retention of messages, strict or worktree mode per repository, escalation times) | no | yes |
  | delete the team | no | yes |

- **CI.6** A person joins a team by **invitation** (S1 § 7.3, CQ-10, DQ-2):
  1. A team owner creates an invitation for an e-mail address.
  2. Creating it returns a one-time password, as text and as a link or QR
     code. The team owner passes it on by a channel they trust. It is valid once,
     for 7 days. The tac server sends no e-mail (`SCO > SCO-LATER`, L-4).
  3. The invited person's runtime presents the password together with the
     e-mail address it was issued for.
  4. The tac server creates the participant with a user id it generates itself,
     so that no tac client can choose an id, and returns the **team token**.
- **CI.7** A team token is per user and team. Every device registers
  itself under it, so one device can be removed without the others. The
  token is kept as a secret (`RT > RT-SECRETS`, CS.11), never in a file.
  (S1 § 7.3, DQ-2)
- **CI.8** A tac client sends a team token with every request. A member of
  several teams holds several tokens. (S1 § 7.3, CQ-10)
- **CI.9** A team owner removes a member, and the tac server then refuses that
  member's token. A member can leave. Tokens can be rotated. (S1 § 7.3,
  DQ-2)
- **CI.10** There are two levels of identity, and both are built:
  **identification**, where a tac client states a user id and an e-mail address
  and is believed, so that work can start without any setup; and
  **invitation with team tokens**. Which of them a tac server works with is a
  setting of the **tac server**, in its configuration, not of a team: a tac server
  is either **open** (identification for everyone on it) or **strict**
  (invitation and team tokens for everyone on it). An open server is right
  for one user alone on the VPN. As soon as other users use the tac server it
  is strict. Every access from the internet is strict, whatever the setting;
  that cannot be configured. (S1 § 7.3, CQ-10; S3, WR-2; PQ-13)

- **CI.11** A quest has a **home team** and a quest owner (`RT > RT-ASKS`,
  CP.16); it records both. Its runtime acts as a member of the home team:
  asks are routed in it, and remote control is allowed from it. (S1 § 7.3,
  DQ-12)
- **CI.12** When an action addresses another team — a review request to that
  team's members, a message into one of its conversations — the runtime uses
  its person's token for that team, for exactly that action. A user's
  devices show all their teams side by side. (S1 § 7.3, DQ-12)
- **CI.13** A runtime can be controlled remotely only by members of the home team of its quest
 and only when its host's setting allows it. (S1 § 7.3,
  CQ-10; `CLI > CLI-TRC`, CK.5)
- **CI.14** A team lists its members, the known and the present ones, with
  their ids and e-mail addresses. A message names the user who sent it.
  (S1 § 7.10; S3, WR-2)
- **CI.15** A team has a configuration that tac keeps and delivers to its
  members' runtimes (`RT > RT-CONFIG`, CS.3 … CS.6). (S1 § 5.5, DQ-11)
- **CI.20** On a tac server a team belongs to an account. Whoever installs the
  tac server creates the first account and its first access key from the
  tac server's command line. With that key a person joins the tac server, creates a
  team and is its first team owner; the others join the team by invitation
  (CI.6). (PQ-20; S1 § 7.3, DQ-2; `TAC > TAC-BACKENDS`, CA.27)

#### <!--[TAC-GROUPS]--> 9.4.1 The team runtimes

The team of CI.1 is also where its members' runtimes coordinate. This
subsection says what that means for the runtimes, and for the resources they
hold leases on. (PQ-23)

- **CA.39** The runtimes started by a team's members are the **team
  runtimes**. They coordinate with each other: they see each other as
  present, they claim their leases from the same service, and they can send
  each other items. A runtime does this in the home team of its quest
  (CI.11), where it is always visible. There is no separate record for it
  beside the team and nothing to create or administer; a user who works
  without a tac server has a **personal team** with themselves as its only
  member. What the coordination protocol as built (`tac/1.0`) calls an
  "agent group", and its group id, is the team; the term is not used in the
  product. It has nothing to do with how a runtime works with its models:
  an **agent** is the model acting in a session, or a sub-agent it started,
  and is never something tac deals with. Every
  runtime calls the model APIs and the agent SDKs directly, serves one
  quest, and reads and writes the quest's files and the other AI state on
  the machine of its host. (PQ-23, PQ-20; S21, TQ-1, TQ-2, C-4)

> **❓ PQ-29 (2026-11-20T15:15+01:00) — the personal team with the GitHub backend:** Which team do a user's runtimes on several machines belong to when the user coordinates through the GitHub backend, without a tac server?
>
> **Context:** The glossary (`GLO`) defines the **personal team** as "The implicit team of a user who works without a tac server (the local backend): the user is its only member, and the user's runtimes on the machine are its team runtimes." `TAC > TAC-PEOPLE > TAC-GROUPS`, CA.39 says "a user who works without a tac server has a **personal team** with themselves as its only member". The terms: a **team** is a group of users on a tac server; the **team runtimes** are all the runtimes its members start; a **backend** is where tac's data lives for a workspace. There are three backends (`TAC > TAC-BACKENDS`, CA.26): **local** ("one machine and one user"), **GitHub** ("one user's machines": leases and endpoints are kept as refs in a coordination repository, so the user's machines coordinate without a tac server) and the **tac server** (a team, or several). The topology T3 in `NFR > NFR-TOPO` ("One user, several machines on the VPN") says: "The runtimes on them are the team runtimes of one team and coordinate through the GitHub backend or the tac server."
>
> **Why I ask:** With the GitHub backend a user works without a tac server on several machines. The glossary ties the personal team to the local backend and to "the machine", so it does not say which team the runtimes of T3 are the team runtimes of, while CA.39 gives every user without a tac server a personal team. Which one holds decides what the glossary entry says, whether a lease taken on one machine keeps a runtime on another machine out (leases only overlap within one team, CA.11), and what the supervision application lists as "the team runtimes" for a user with two machines and no tac server.
>
> - **(a)** The personal team covers both backends that work without a tac server. Its team runtimes are the user's runtimes on one machine (local backend) or on all machines that use the same coordination repository (GitHub backend). The glossary entry would read "… without a tac server (the local or the GitHub backend): the user is its only member, and the user's runtimes, on the machine or on all machines that share the coordination repository, are its team runtimes." T3 stays as it is.
> - (b) The personal team is per machine, as the glossary says. With the GitHub backend the user's machines share leases and endpoints without being one team; T3 would say "the runtimes on them coordinate their leases through the GitHub backend", and "team runtimes" would not be used for it. The supervision application then shows one personal team per machine.
> - (c) The GitHub backend gets a named team of its own kind: the coordination repository names the team, and the user is its only member. The personal team stays the local backend's. One more record to describe in `TAC`.
>
> *Recommendation:* (a) — CA.39 already gives every user without a tac server a personal team, CA.11 lets resources overlap only within one team (so the machines must be one team for leases to work across them), and it needs no new record.
>
> *Assumption until answered:* T3 keeps "the team runtimes of one team"; the glossary entry is unchanged and names the local backend only.
>
> **Answer (2026-11-20T15:38+01:00):** The git-based tac service must support simple teams of multiple members, too, besides a single-member personal team, the local implementation works only on a single machine.

- **CA.40** A runtime works with what its user can reach: the repositories
  the person it belongs to has access to at the repository server, cloned on its
  machine. A user who works on a quest normally has access to all of the
  quest's repositories. An agent uses only resources it can reach; when work
  needs something it cannot reach, it says that the work cannot be done here
  and has to be done elsewhere. (PQ-23)
- **CA.41** A **resource** is, for now, a whole repository or a part of one
  described by a pattern of paths. It is named, not registered: the
  repository by its identity, the part by the repository and the pattern,
  for example `al-the-bear/tom_ai_build` and
  `al-the-bear/tom_ai_build#tom_ai_runtime/**`. The pattern is relative to
  the repository's root. (PQ-23; CA.9, CA.10; S21, TQ-8)
- **CA.42** tac knows the leases it has given, and nothing else. A runtime
  that is about to execute a todo claims the resources the todo names. tac
  understands the names: while the whole repository is exclusively leased,
  no part of it can be leased, and while a part is, neither the whole
  repository nor a part that overlaps it. Whether a claim can be answered
  with leases follows from the leases that exist; tac does not need to know
  which
  repositories or paths exist, keeps no list of resources, and does not have
  to store a resource that nobody holds. (PQ-23)
- **CA.43** A lease that is stuck is known to tac, because tac gave it: it
  is listed and can be freed (CA.13). (PQ-23)
- **CA.44** A runtime is **visible** in the home team of its quest, always:
  there it is seen, can be sent items, can be remote-controlled by the
  team's members where its host allows it, and claims its leases. In its
  user's other teams it is not visible unless the user switches it visible
  at the host. In such a team it is only seen, with its quest, and can be
  offered todos: no remote control from there, and no leases there. A user
  in two teams can so act as a liaison and link two groups of quests, or
  not show the other membership. (S21, TQ-10, TQ-11)

### <!--[TAC-KINDS]--> 9.5 Message kinds

- **CM.1** A message between users has a kind. Beyond text, a kind is
  something the recipient's application can act on. The service stores and
  delivers; the kinds are the tac clients' convention and are versioned with the
  protocol. (S1 § 7.4)
- **CM.2** The kinds (S1 § 7.4):

  | Kind | Carries | What the recipient's application does |
  | --- | --- | --- |
  | **text** | Markdown, mentions, a reference to the message it replies to | shows it |
  | **document** | one or several files or references, and the form (`TAC > TAC-DOCS`, CV.8) | opens it, saves it into a place, makes a todo of it |
  | **review request** | the round, the set of documents, the deadline, the versions the review starts from | opens the review; the reviewer returns a copy in the same thread |
  | **review return** | the round and the returned copies | the coordinator's application writes them into the round folder and offers the merge |
  | **ask** | an ask (`RT > RT-PROTO`): a question, the allowed answers, a default, a deadline | shows buttons or a form; the answer returns to the run that asked |
  | **decision request** | the open decisions of a todo, or the result of a gate with its choices | the recipient decides; the todo or the process moves |
  | **todo** | a todo to take over, or the change of a todo's state | files it, or shows the change |
  | **reminder** | a time, what it is about (a message, a document, a round, a todo), who is reminded | delivered at the time; repeats and escalates as declared |
  | **notification** | from a runtime: needs attention, finished, failed, out of budget | shown among the notifications |
  | **command** | to a quest's runtime: queue, pause, proceed | carried out by that runtime (`TAC > TAC-COORD`, CA.19) |

- **CM.3** Beside its text a message can carry a free payload the service
  does not read, for references to files and for what an application shows
  as a card. (S1 § 7.10)
- **CM.4** **Reminders are a feature of the service.** A message can carry a
  time before which it is not delivered (`deliverAt`), and a time after
  which the service reminds the recipient when the message is still unread
  or unanswered, and the sender when it stays so (`remindAfter`). The
  deadline of a review round uses this. (S1 § 7.4)
- **CM.5** A reminder is delivered once to a user, however many devices
  and runtimes that user has. (S1 § 7.4)
- **CM.6** **Delivery follows presence.** A notification is not pushed to a
  device while its user is active on another one; after a time without a
  reaction it goes on to the next channel. (S1 § 7.4)

### <!--[TAC-CONV]--> 9.6 Conversations

- **CM.7** A conversation is direct (two users), among several members (a list of
  members), or attached to something: a document, a review round, a todo, a
  run, a quest. What it is attached to is an anchor the tac client sets and the
  service does not interpret. (S1 § 7.5, § 7.10; S3, WR-4)
- **CM.8** Messages have replies and threads, mentions, and a mute per
  conversation. (S1 § 7.5, § 3.2)
- **CM.9** A conversation's history is stored and read in pages and from a
  point on (a message or a time), so a tac client that was offline catches up.
  Members who are present receive messages live. The time of a message is
  the service's. (S1 § 7.5, § 7.10; S3, WR-4)
- **CM.10** Read state is kept per user: read up to a message, and the
  number of unread messages per conversation. (S1 § 7.5, § 7.10; S3, WR-4)
- **CM.11** Messages are kept for one year unless the team sets another
  time, or sets that they are kept. (S1 § 7.5, WQ-3)
- **CM.12** Every message has a stable address,
  `msg:tac/<team>/<messageId>`, that other documents and messages can refer
  to. (S1 § 7.5, § 3.2)
- **CM.13** A send carries a request id the service remembers for 24 hours.
  A send repeated with the same id is not delivered twice, so a tac client that
  was offline can resend what waited in its outbox. (S1 § 7.5, § 7.10;
  S5 § 5.6; S3, WR-4)
- **CM.14** The messages between runtimes (`TAC > TAC-COORD`) stay as they
  are beside the messages between users. (S1 § 7.10)

### <!--[TAC-DOCS]--> 9.7 Documents

- **CV.1** A file travels through tac as a **blob**: addressed by the
  SHA-256 hash of its content, checked on upload, stored once however often
  it is referenced. A reference in a message carries the hash, the name, the
  media type and the size. (S1 § 7.6, § 7.10; S2 § 5, FO-8; S3, WR-5)
- **CV.2** There is a size limit per file and a quota per team. A tac client
  can read both before it uploads, so it refuses a file that is too large
  before sending it. (S1 § 7.6, § 7.10; S3, WR-5)
- **CV.3** A blob has a lifetime: 7 days by default, at most 30, set per
  message. When it ends, the blob is removed. (S1 § 7.6; S2 § 5, FO-21)
- **CV.4** A process can **pin** its blobs for as long as it runs. Pinned
  blobs count against the team's quota and are released when the process
  ends. (S1 § 7.6, CQ-11)
- **CV.5** A **review set** is a named set of files, pinned for a review,
  that every reviewer of it can open — also a reviewer outside the VPN, or
  one without access to the version control or the file servers, as long as
  their application reaches tac. (S1 § 7.6, CQ-11)
- **CV.6** Only the members of the conversation a blob was sent in, or the
  reviewers of its review set, can download it. (S1 § 7.10; S3, WR-5)
- **CV.7** tac is not a file server (`SCO > SCO-OUT`, O-7). The versioned
  documents and the record of a review are in version control: usually the
  specification folder of the project in the project's repository; in a
  larger organisation a specification repository of its own; usually not the
  quest, since over time a quest spans many projects and products.
  (S1 § 7.6, DQ-4)
- **CV.8** A document is sent in one of three forms: as a reference to
  where it is, as a copy the recipient's application can work on (with the
  version it was taken from), or rendered for reading (Markdown, HTML, PDF).
  (S1 § 3.2, § 7.4)
- **CV.9** An application can tell, and shows: a blob that has expired, a
  copy over the size limit, a returned copy from someone who is not a
  reviewer of the round, and a copy returned twice. (S1 § 3.2)

### <!--[TAC-REVIEW]--> 9.8 The review exchange

- **CV.10** A review covers a set of documents. (S1 § 3.2)
- **CV.11** tac carries the documents of a review round out to the members
  and their copies back. Nobody carries files by hand: the step of a team
  review in which the copies are collected is done by the exchange.
  (S1 § 7.7, § 3.5; S11)
- **CV.12** The course of a round (S1 § 7.7, § 3.2):
  1. The coordinator's runtime creates the round folder and sends a review
     request with the document set to every member, in a thread attached to
     the round.
  2. Each member's application opens the review; the member annotates and
     returns the copy in the same thread.
  3. The coordinator's application writes each returned copy into the round
     folder and commits there.
  4. Reminders go out before the deadline (`TAC > TAC-KINDS`, CM.4).
  5. When all copies are back, or the coordinator decides, the copies are
     merged, and the round is marked as merged; its blobs are then released.
- **CV.13** The **round folder** is the record of a round: the description
  of the round, the base, each member's copy, the merged result. It lies
  beside the documents, in version control (CV.7). tac is the transport, not
  the record. (S1 § 7.7, § 7.6, DQ-4)
- **CV.14** A round's blobs are kept until the round is merged or their
  longest lifetime is reached; there is an operation to extend them to that
  longest lifetime and one to release them. (S1 § 7.10; S3, WR-5)
- **CV.15** A reviewer who has access to no repository needs only an
  application with the review component (`CLI > CLI-UI`) and an identity in
  tac. (S1 § 7.7)

### <!--[TAC-CRYPT]--> 9.9 Encryption

- **CI.16** What travels between a tac client and the tac server is encrypted in
  transit. (S1 § 7.8; S3, WR-3)
- **CI.17** What the service stores is not encrypted by default. Encryption
  at rest is an option (`SCO > SCO-LATER`, L-10). (S1 § 7.8; S2 § 5, FO-20)
- **CI.18** A device that reaches the server from the internet is **paired**
  first: it is enrolled once, from inside, by its user, and gets a key of
  its own. A single device can be removed, and its key then stops working.
  Pairing is part of the first version, since phones and tablets reach the
  server from the internet in it. (S1 § 7.8, CQ-10; PQ-9)
- **CI.19** ___check here___ **An open point for the security model of the
  Solution Blueprint:** whether encryption in transit (HTTPS), the team
  token and the paired device's key are enough for access from the internet,
  or whether end-to-end encryption between a device and a runtime is needed
  in the first version too. The product owner asked it ("think if internet
  access is secured enough with HTTPS + the token"). What can be said now:
  HTTPS with the team token and a device key protects against anyone on the
  network between the device and the server, and a lost device is shut out
  by removing its key. It does not protect against the server itself or
  whoever controls it, because the server and its relay see what they
  forward; end-to-end encryption would. In the first version the server is
  run by the team that uses it, so the server is trusted as the team's
  machines are. The earlier decision made end-to-end encryption mandatory
  with the relay (S1 § 7.8, CQ-10); with the runtime host server for phones
  the path from a device ends at a runtime on that server, where there is no
  second end to encrypt to. The security model decides it; it does not hold
  up the Blueprint. (PQ-13, PQ-9; `SCO > SCO-LATER`, L-6)

> **❓ PQ-28 (2026-11-20T15:05+01:00) — which server a paired device reaches from the internet:** When a phone or tablet reaches "the server" from the internet, is that the tac server (through its relay) or the runtime host server?
>
> **Context:** `TAC > TAC-CRYPT`, CI.18: "A device that reaches the server from the internet is
> **paired** first: it is enrolled once, from inside, by its user, and gets a key of its own. …
> Pairing is part of the first version, since phones and tablets reach the server from the
> internet in it." CI.19, the open point for the security model, speaks of "the network between
> the device and the server", "the server itself or whoever controls it, because the server and
> its relay see what they forward" and "a runtime on the server". The agreed terms name every
> server by its kind. The **tac server** is tac running for a team; its **relay**
> (`TAC > TAC-BACKENDS`, CA.30) "carries TAC and MCP for machines that are not on the VPN and only
> forwards". A **runtime host server** is the program that runs permanently for applications on
> phones, on tablets or in a browser and starts one runtime per connected application
> (`RT > RT-INSTALL`, CR.46); such an application speaks the runtime's protocol to it, not TAC.
> **Pairing** is enrolling a device once so that it gets a key of its own. CI.4 says every
> application reaches tac through a runtime, on a phone "a runtime on a runtime host server".
>
> **Why I ask:** In CI.18 and CI.19 "the server" can be either, and the two readings differ in
> what is exposed to the internet and who checks the device's key. A phone application talks to
> its runtime on the runtime host server, so that is what it must reach; the relay is part of the
> tac server and is said to carry TAC and MCP, not the runtime's protocol. So either the runtime
> host server is itself reachable from the internet and checks paired devices, or the tac server's
> relay also forwards the runtime's protocol to the runtime host server and pairing is with tac.
> The security model of the Solution Blueprint, the item CA.30 and the network topologies (T5,
> T8) read differently depending on it.
>
> - **(a)** The device reaches the tac server, through its relay. The relay also forwards the runtime's protocol to the runtime host server; pairing is with the tac server, which holds the device keys and is the only program reachable from the internet. CI.18 and CI.19 would say "tac server" throughout, and CA.30 would add the runtime's protocol to what the relay carries.
> - (b) The device reaches the runtime host server directly. It is reachable from the internet, holds the device keys and checks them; the tac server need not be reachable from outside for phones. CI.18 would say "runtime host server", and CI.19's "the server and its relay" would be the only place that means the tac server.
> - (c) Both run on one machine behind one reverse proxy, and "the server" in CI.18 and CI.19 becomes "the team's server machine": one address, the proxy routes TAC to the tac server and the runtime's protocol to the runtime host server; pairing is with the tac server.
>
> *Recommendation:* (a) — one program faces the internet, CA.30 already says that whatever comes through the relay is from a paired device, and tac already holds users, devices and team tokens.
>
> *Assumption until answered:* CI.18 and CI.19 keep the bare word "server" where it can be either (with a remark in CI.18); only "a runtime on the server" at the end of CI.19 names the runtime host server.
>
> **Answer (2026-11-20T15:46+01:00):** There is no given solution for this now. I assume the runtime cannot run directly in mobile devices, so there will be an additional relay which connect to a runtime on behalf of the device to participate in the overall scenario. This means there would be a remote runtime client SDK that connects to a remote runtime service running on a server. That remote runtime service would then connect to the tac as usual from the server. For the web scenario we'll need a HTTP-based service, maybe this can be one and the same as what is used by mobile devices. So I suggest we call the component web runtime client SDK and web runtime service, being used in mobile apps and from Flutter-base (or non-Flutter) web applications. We'll provide a Dart and a JS/TS web runtime client SDK for easy and consistent integration.

### <!--[TAC-SPEC]--> 9.10 One specification: `tac/2.0`

- **CA.36** Everything in this section and the integration of
  `PAR > PAR-APPROACH` is specified as one protocol version, `tac/2.0`:
  participants, teams and identity; the tac server; conversations, message kinds
  and reminders; documents, pinning and review sets; integration leases and
  the integration queue; authentication. It is one document, reviewed as a
  whole, and it is built in one go. (S1 § 7.9, CQ-8, WQ-2)
- **CA.37** A service announces, when a tac client connects, the capability
  blocks it implements (participants, teams, messaging, documents,
  integration, and so on). A tac client uses what is announced. (S1 § 7.9, WQ-2)
- **CA.38** New capabilities are added within `tac/2.0`. A runtime of an
  older version that is still running somewhere keeps working with a newer
  service, and a tac client that states no user still works. (S1 § 7.9,
  § 7.10, WQ-2)

### <!--[TAC-WEBWORK]--> 9.11 What Webwork needs, and how it is met

Webwork states six requirements on tac (S3, WR-1 … WR-6; its seventh, on the
runtime, is met in `RT` and `CLI`).

| Requirement | Met by | How |
| --- | --- | --- |
| **WR-1** tac reachable as a server by a small team | CA.26 … CA.28 | The full tac server; a small team is one account on it. (S1 § 7.10, CQ-9) |
| **WR-2** identification by user id and e-mail on connect | CI.3, CI.4, CI.10, CI.14 | Identification is one of the two levels of identity, on a tac server set to open (CI.10; PQ-13). **Differently from the requirement:** an application without a runtime does not register in tac; it goes through a runtime. (S1 § 7.10, WQ-1) |
| **WR-3** encryption on the wire only | CI.16, CI.17, CA.28 | Encrypted in transit, ending at a reverse proxy; nothing required at rest. (S1 § 7.10) |
| **WR-4** user messages | CM.1 … CM.13 | Conversations, history, read state, retention, the request id. (S1 § 7.10, WQ-3) |
| **WR-5** documents as blobs for the review exchange | CV.1 … CV.6, CV.10 … CV.14 | Blobs with limits and lifetimes, pinning, review sets, the exchange. (S1 § 7.10, CQ-11) |
| **WR-6** a Dart client that needs no AI runtime | `CLI > CLI-PACK`, CL.2, CL.3, CL.11 | The Dart tac client SDK is a package of its own. **Differently from the requirement:** an application does not connect to tac directly from a browser or a phone; it uses the runtime client SDK against a runtime on a runtime host server (`RT > RT-INSTALL`, CR.46). The runtime host server is in the first version, for the supervision application; Webwork's own server side is in a later wave of Webwork (`SCO > SCO-LATER`, L-8), and until it exists Webwork's messaging works on the desktop. (S1 § 7.10, CQ-15, WQ-1; PQ-9) |

Webwork does not need leases, endpoints, the GitHub backend or messages
between runtimes for its messaging. (S3, "What Webwork does not need")

## <!--[PAR]--> 10 Parallel work, cross-quest work and repository quests

Several runs, on several machines, by several people, work on the same
repositories at the same time. This section states what hurts in that today,
how the product lets them do it without getting in each other's way, how
work crosses from one quest to another, and how a quest and a person's own
files get repositories of their own.

### <!--[PAR-PROBLEM]--> 10.1 What hurts today

The problems this part solves (S1 § 10.1; S16):

| Id | Problem | What it means |
| --- | --- | --- |
| **P-5** | Everything is committed on the main branch, in clones several sessions share | "One writer per repository" is an agreement nobody enforces. A repository many want is a queue of one. |
| **P-6** | Nothing stands before the main branch | A broken commit is at once the base of every other session, and is published to those who depend on it. |
| **P-7** | An execution cannot be discarded | Work that went wrong is undone by hand. |
| **P-8** | A long execution holds a repository for hours | Half-finished states lie on the main branch meanwhile. |
| **P-9** | Other sessions' uncommitted work is in the way | Installs, builds and syncs meet changes that are not theirs; such changes have been committed by a sync and destroyed by one command. |
| **P-10** | Nobody can ask "is anything writing here" | Before a sync between machines the answer is found by hand, and a queue cannot be asked to pause. |
| **P-11** | Machines drift apart unnoticed | A machine can be thousands of commits behind without anything saying so. |
| **P-12** | Shared files are written whole by one process | One window overwrites what another just set. |
| **P-13** | Requests to another quest get stuck | An item sent to a run that is paused or does not exist waits unseen; a request ends without anything being filed. |
| **P-14** | A release ripples | One release of a shared package moves dozens of dependents, and "version X is published" is nothing a todo can wait for. |

- **CW.1** The trunk is kept: work lands on the main branch of each
  repository, without a pull request per task and without a build server.
  What is added is what the trunk lacks: a check before the main branch, a
  way to discard an execution, leases shorter than an execution, and an answer to who holds
  what. (S1 § 10.3, § 10.4)

### <!--[PAR-APPROACH]--> 10.2 The approach

All of the approach is decided: the parts the concept only proposed (the
lease for the integration, the integration queue, the resources a todo names, the rebase
of waiting executions, the record of commits, publication as a dependency, the
answer to who holds what, the `_ai` state on the main branch, review without
pull requests) are confirmed, with a strict mode added (CW.5). (PQ-14)

**An execution's result is a branch**

An **execution** is the work on one item of a run's queue: it starts when
the run sends the item and ends when the item is done or given up. A run is
the queue itself and lives much longer. (S21, TQ-4)

- **CW.2** Whether executions work in a working tree of their own is a
  setting per repository that the team decides and can change. A repository
  one person works on needs none: it is in **strict mode**. When several
  work on it in parallel, it is in **worktree mode** (also called
  change-branch mode): an execution works in its own working tree, on its
  own branch, and its result is that branch. The `_ai` state never gets
  working trees of its own. (S1 § 10.4, CQ-12; S21, TQ-9)
- **CW.3** A working tree of an execution keeps the relative layout of the
  repositories, so that builds and path dependencies between neighbouring
  repositories keep working; inside it, `_ai` is the one shared `_ai`. The
  execution's tools and its agent work in that tree. (S6,
  part-branches-and-worktrees)

**Claims, leases and the integration step**

- **CW.4** Before a run sends a todo, its runtime claims the todo's
  resources, all or none. When a lease it needs is held for another item, the
  item waits and says who holds it; when the lease is released, the waiting
  item goes on. (S6, part-claims; S1 § 9, § 10.4)
- **CW.5** In worktree mode an execution holds a **shared lease** on what it
  works on, which tells the others who is working there and lets them work
  there too, and takes an **exclusive lease** on the repository only for the
  integration step. The integration step is: rebase the execution's commits
  onto the main branch, run the repository's checks, fast-forward the main
  branch, push. The fencing token is checked at the push. In **strict mode**
  the execution holds an exclusive lease, which keeps every other claim on
  an overlapping resource out, for as long as the todo is executed. A
  repository without working trees per execution (CW.2) is always in strict
  mode. (S1 § 10.4, item 2; PQ-14; S21, TQ-9)
- **CW.6** Every repository has an **integration queue**, kept by tac. It is
  serial and mechanical: it runs the checks the repository declares
  (analysis, the tests the change affects) and lands the execution's commits
  or rejects them back to it. There is no integrator above the
  repositories. (S1 § 10.4, item 3)
- **CW.7** A todo names its **resources**: repositories, and parts of
  repositories by a pattern of paths. That one list is what is claimed, and
  what a run uses to start only todos whose resources do not overlap; it
  says before it starts which todo waits for which. (S1 § 10.4, item 4;
  S21, TQ-4)
- **CW.8** A todo is written with its own resources. A quest lists the
  repositories and parts of repositories it usually works on; for a todo that names nothing, the runtime claims that whole list for as long as the todo is executed. The quest's
  list is the fallback, mainly for older todos. (S1 § 5.5, CQ-3, DQ-5)
- **CW.9** A group of todos can claim its resources with its first todo and release the leases with its last. (S6, BP-10)
- **CW.10** After each integration the executions that wait rebase onto the new
  main branch and run their checks again before they land.
  (S1 § 10.4, item 5)
- **CW.11** For every todo there is a **record of its commits**: per
  repository, the commit before and the commit after. It gives the unit of
  review (the difference a todo made), the way to discard (revert that
  range), and the way from a commit back to the session that made it.
  (S1 § 10.4, item 6)
- **CW.12** A todo can wait for a package to be published at a version or
  later. The runtime checks the package registry and unblocks the todo.
  (S1 § 10.4, item 7)
- **CW.13** tac answers **who holds what**: for a repository, a workspace or
  all machines of a team. A sync between machines or a change of the
  workspace's layout asks instead of assuming. A runtime can be asked to
  pause its queue after its current item. (S1 § 10.4, item 8)
- **CW.14** The `_ai` state stays on the main branch: todo and state files
  are not code, are merged by their own merge drivers and are written file
  by file. (S1 § 10.4, item 9; `TAC > TAC-COORD`, CA.17)
- **CW.15** **Review happens without pull requests.** The difference a todo
  made is shown as a review document; a review agent that starts without the
  execution's context gets only that difference and what the todo says must be
  true when it is done; a person reviews only the paths that carry weight
  (migrations, formats, publishing, credentials); the verdict is recorded
  with the todo. (S1 § 10.4, item 10)
- **CW.16** A repository on which no lease is held can be brought up to date
  automatically, by fast-forward only and only with a clean working tree and
  nothing unpushed. It is switched on per workspace. A repository it had to
  skip is reported. (S6, BP-12, BP-18)
- **CW.17** The system does not take over from others: a pull request per
  task, a merge queue at the repository server, or agents working directly on the
  main branch of a repository several executions want. (S1 § 10.4)

### <!--[PAR-CROSS]--> 10.3 Cross-quest linkage

- **CW.18** One way of addressing holds on one machine and across machines:
  a todo as quest and todo id, a run as quest and run, a session, a user.
  (S1 § 10.5)
- **CW.19** Delivery is acknowledged. Something sent to another quest is
  taken by a run there, refused with a reason, or waits at the sender and is shown there with what it waits for. It does not wait unseen at the receiver. This holds
  between quests of one team; what comes from another team is a todo offer (CW.26).
  (S1 § 10.5, § 9; S21, TQ-11)
- **CW.20** An item or a walk is sent into a named run of another quest: on
  the same machine through the machine's own state (`RT > RT-MACHINE`), on
  another machine as a command through tac (`TAC > TAC-COORD`, CA.19). It is
  one path for both. (S1 § 9, § 10.5)
- **CW.21** A todo names what it waits for, in any quest. The runtime
  follows such blockers across quests, and through tac across machines.
  (S1 § 10.5)
- **CW.22** A request to another quest is a todo in that quest, carrying who
  filed it — not a prompt that can end without anything being filed.
  (S1 § 10.5)
- **CW.23** The notification that a todo is done returns to the run and the
  session that asked for it, also across quests and machines. (S1 § 9;
  `RT > RT-QUEUE`, CR.21)
- **CW.24** Which repositories a quest works on is recorded, so that claims
  and a todo's resources can be checked against it. The repositories of a workspace
  are those of the file the workspace is set up from. (S1 § 10.5, § 5.5,
  CQ-3)

- **CW.25** When work has to be done in another quest, a todo is created in
  that quest. For that it is enough to reach the quest: by writing into the
  quest's repository, or into the shared state repository that holds
  several quests, where the user has access to it; later also by finding a
  runtime of the target quest and sending the todo there, through tac or
  the runtime's MCP server. (PQ-23; CW.20 … CW.24)

- **CW.26** A todo that a member or a runtime of another team sends to a
  quest is a **todo offer**. It is not in the quest until it is accepted: by
  a person of the quest's team, or automatically by a rule a person has set
  for that quest (from whom, of what kind). Accepting stays under a person's
  control. Adding todos is the case this exists for; other kinds of item may
  follow. (S21, TQ-11; CA.44)

### <!--[PAR-QUESTS]--> 10.4 Repository quests and personal files

- **CQ.1** There are two kinds of quest. A **classic quest** is a folder in
  the shared repository of the `_ai` state; whoever shares that repository
  shares the quest. A **repository quest** is a quest whose folder is a
  clone of the quest's own repository, which the shared repository ignores;
  whoever has access to the quest's repository shares the quest. Which kind
  a quest is, is decided per quest. (S2 § 3.7, § 5, FO-18; S1 § 12.5; S4,
  note n)
- **CQ.2** Every user has one **personal repository**, cloned into the
  `_ai` state, with a folder per quest, for the files that are only theirs.
  There are no personal quests. (S2 § 3.7, § 5, FO-13, FO-22; S1 § 12.5)
- **CQ.3** Personal files, kept in the personal repository and never in a
  quest's (S2 § 3.7, § 5, FO-22):
  - the storage of the sessions: the live trail, the history and its
    compacted form;
  - the session todos;
  - the settings of a machine for a quest;
  - the trail and compaction files kept per machine;
  - the **personal notes** of a quest: notes for the current user only.
- **CQ.4** The quest notes stay in the quest: they are the user's, and they
  are read by the agents of every member. (S2 § 5, FO-22)
- **CQ.5** Every tool and every store resolves the place of a quest's file
  and of a personal file through one resolver, so the kind of a quest
  changes nothing for the code that reads and writes it. (S2 § 3.7; S20 § 10, background)
- **CQ.6** For a repository quest the runtime provides: the merge drivers of
  the `_ai` files; a branch per member, with a review of the conflicts when
  the branches meet; one shared process position, moved only on the main
  branch; a second repository beside the quest's, for what only its
  technical members may see, with development credentials kept encrypted; a
  scan for secrets when committing and publishing; the identity of the
  members and their access. (S2 § 3.7)
- **CQ.7** Three operations exist around a quest's repository (S2 § 3.7):
  - **create**: a new quest is set up with its own repository from the
    start;
  - **join**: a second user, or the same user on another machine, starts
    working on an existing repository quest — the quest's repository is
    cloned into place, the personal repository is set up, the user is
    registered as a member;
  - **migrate**: a classic quest becomes a repository quest and keeps its
    history — the quest's folder with its commits is copied into the new
    repository, and a trial migration shows the result before anything is changed.
- **CQ.8** The first quest is migrated alone, to see that it works; then the
  quests worked in most. (S4, note n)

___check here___ CQ.5 is stated only in the superseded first collection
(S20 § 10: "Every tool resolves paths through one resolver"); the current
sources imply it without saying it. It is kept because the Blueprint needs
it, and should be confirmed with this section. — `agent_spec_author`

## <!--[NFR]--> 11 Non-functional expectations

What the system must hold to beyond what it does. Each expectation is stated
by the sources; none carries a number the sources do not give.

**Compatibility and stability**

- **N-1** The runtime protocol only grows within a major version: commands
  and fields are added, not changed or removed. An older runtime client keeps working
  with a newer runtime; it does not get the new features, and nothing it does
  breaks. (S1 § 6.7, DQ-9; `RT > RT-VERSIONS`)
- **N-2** A runtime client returns every field it does not know unchanged when it
  writes a record back, so nothing a newer runtime added is lost. Every client SDK does this, and the conformance suite tests it. (S1 § 6.7, DQ-9)
- **N-3** The protocol's version, the runtime's version and the format of the
  workspace files are checked when a runtime client connects. A runtime does not work
  on workspace files in a format newer than it knows; a migration of the
  files runs once per machine, and the other runtimes pause meanwhile.
  (S1 § 6.7, § 9 F12; `RT > RT-VERSIONS`)
- **N-4** tac's capabilities are added within `tac/2.0`. A service announces
  what it implements, and a runtime of an older version keeps working with a
  newer service. (S1 § 7.9, WQ-2; `TAC > TAC-SPEC`)
- **N-5** The tools keep the names they have today, so every existing prompt
  that names a tool keeps working. (S4, note e; S1 § 6.3)
- **N-6** The protocol names the revision of MCP it speaks; what differs
  between MCP revisions is kept behind an adapter. (S1 § 6.4)
- **N-7** The aim is that the protocol and the formats become very stable
  after a while. (S1 § 6.7, DQ-9)

**Several runtimes and hosts on one machine**

- **N-8** Several runtimes and hosts work on one machine without overwriting
  each other's state. State that belongs to the machine is kept by the runtime alone and is reached through one interface; where files are used, a
  write changes one key, under a file lock, and never the whole file. (S1 § 5.5,
  § 5.6, CQ-2; `RT > RT-MACHINE`)
- **N-9** All hosts of a machine share one installation of the runtime;
  versions stand side by side, and a running runtime keeps its version when a
  newer one is installed. (S2 § 5, FO-3, FO-4; S1 § 5.7, DQ-9;
  `RT > RT-INSTALL`)
- **N-10** Two hosts can work on the same quest at the same time. (S1 § 8 T2;
  S14)

**When the coordination cannot be reached**

- **N-11** With coordination switched off, everything works as it does
  without tac. (S1 § 7.2; `TAC > TAC-BACKENDS`)
- **N-12** When the coordination backend cannot be reached, nothing falls
  back on its own: the queues of the team runtimes stop after their current todo,
  and the user can switch to an emergency local mode. (S6; S1 § 7.2;
  `TAC > TAC-BACKENDS`)
- **N-13** A lease that is no longer renewed becomes stale and is shown; only
  a person frees it. (S5 § 4; S16)
- **N-14** A runtime that is offline still starts with the team's
  configuration as it last saw it. (S1 § 5.5, DQ-11)

**Asks**

- **N-15** An ask is never lost and does not block a process for long: it is
  a stored record that outlives the operating-system process that asked, it moves along a
  chain of people, every open ask of a team can be seen with its age and
  who has it, and nothing is decided automatically unless the ask declared a
  default. (S1 § 6.1, § 6.6, CQ-7, DQ-3; `RT > RT-ASKS`)
- **N-16** A send to tac can be repeated safely: a repeated send is not
  carried out twice. (S5 § 11; S1 § 7.5; S3 WR-4)

**Security**

- **N-17** No secret stands in a configuration or in a file of a quest: a
  configuration holds a reference, resolved at the moment the secret is
  needed. Team tokens are kept the same way. (S2 § 5, FO-15; S1 § 5.8, CQ-16;
  `RT > RT-SECRETS`)
- **N-18** The runtime's MCP server reads and writes only the `_ai` state; no
  file, command, web or git tool is offered through it. That is what makes it
  safe to publish to other machines. (S4; S2 § 5, FO-17; S1 § 6.3, § 6.4)
- **N-19** Whether identification by user id and e-mail address is accepted
  is a setting of the tac server: an open server is right for one user alone
  on the VPN; as soon as other users use a tac server it is strict, and every
  access from the internet is strict whatever the setting. Remote control of
  a runtime is possible only inside a team and only where the runtime's host
  allows it. (S1 § 7.3, CQ-10; PQ-13; `TAC > TAC-PEOPLE`, CI.10)
- **N-20** What travels between a tac client and the tac server is encrypted in
  transit. What the service stores is not encrypted by default. (S3 WR-3;
  S2 § 5, FO-7, FO-20; S1 § 7.8)
- **N-21** Whatever is reachable from the internet is reached only by paired
  devices, each with its own key, over an encrypted connection, with strict
  identity. Whether end-to-end encryption between a device and a runtime is
  required as well is decided in the security model. (S1 § 7.8, CQ-10; PQ-9,
  PQ-13; `TAC > TAC-CRYPT`, CI.18, CI.19)
- **N-22** A user id is generated by the tac server when an invitation is
  redeemed; no tac client chooses one. (S1 § 7.3, DQ-2)
- **N-23** A file a prompt drew from an encrypted document leaves no trail on
  disk: its trail is kept in memory only. (S1 § 3.2; S13)

**Platforms**

- **N-24** The runtime is a Node program written in TypeScript; it imports
  nothing from VS Code, and a test guards that. (S1 § 4; S2 § 3.1)
- **N-25** The Flutter components build for the desktop, the web, iOS and
  Android, are themeable by the host and have no dependency on Tom Forge.
  (S1 § 12.2; `CLI > CLI-UI`)
- **N-26** The client SDKs exist for nine languages: Dart, TypeScript,
  JavaScript, Python, Java, Go, Rust, C and C++. The Dart tac client SDK runs
  with and without `dart:io`. (S1 § 12.1; S2 § 3.5; `CLI > CLI-PACK`)
- **N-27** The fleet's machines are macOS, Linux and Windows; the shared
  installation has a place on each of them. (S2 § 5, FO-3)
- **N-28** The tac service has no runtime dependencies; TLS ends at a reverse
  proxy in front of it. (S5; S1 § 7.10)

**Licence**

- **N-29** The packages are BSD-3, as the framework's packages are.
  `tom_tac_service` carries that licence today, and Webwork's choice of tac
  for its messaging rests on it. (S5; S13, DPMESSAGING-2; S19)
  The new packages are BSD-3 too. For now they are published only to
  pub.dev (the Dart packages) and to the workspace's binaries repository
  (everything a host or a tac server installs: the runtime, the tac service, the
  client SDKs of the other languages). Publication to further registries and to
  the application stores is later. (PQ-15)

**Documentation**

- **N-30** The product is delivered with its documents (S1 § 13.2):
  - the specification, in the structure of the TomSpecs model;
  - an architecture document: components, process model, the topologies and
    the flows as sequences, who owns which state, security;
  - the runtime protocol specification, with its JSON schema;
  - the TAC specification `tac/2.0`;
  - the API documentation of the client SDKs, per language, with
    examples (PQ-18);
  - a user guide and a programmer's guide, written by hand (PQ-18);
  - the screen and component descriptions;
  - guides: integrating the runtime into a Flutter application; setting up a
    tac server and a team; pairing with Tom Secrets Manager; the rules for
    parallel work with what is enforced.

**Testing**

- **N-31** One conformance suite checks every client SDK in every language
  against the protocol; the Dart and the TypeScript and JavaScript client SDKs
  are tested thoroughly, the others through the suite. (S2 § 5, FO-10;
  S1 § 12.1; `CLI > CLI-PACK`)
- **N-32** Guard tests keep the runtime's boundary: no import of VS Code, no
  state of a host except through the host interface, no mutable state at
  module level, and snapshots of the tools' schemas. (S2 § 3.1; S19)
- **N-33** Every stage of the split leaves the extension working and
  installable. (S19; S1 § 13.3)
- **N-34** Builds, tests and checks are started by a person and run from the
  cloned repository; nothing schedules them, and no continuous integration
  runs on GitHub. The integration step runs a repository's declared checks on
  the machine of the execution. (S16; S1 § 10.3, § 10.4)

### <!--[NFR-TOPO]--> 11.1 Network topologies

The topologies the architecture document describes (S1 § 8). T1 to T5 and T8
belong to the first version; T6 and T7 are later. (PQ-9, PQ-16)

| Id | Topology | What runs where | What must be reachable | Source |
| --- | --- | --- | --- | --- |
| **T1** | One machine, VS Code only | One runtime per window, inside the extension; the local tac service once for the machine and user. | Only the loopback interface. Nothing leaves the machine. | S1 § 8 |
| **T2** | One machine, several hosts | VS Code windows, and Webforge with one runtime process per open quest plus one without a quest for Webwork's own AI. Two hosts may work on one quest. | The loopback interface; all hosts find the shared installation and the local tac service. | S1 § 8 |
| **T3** | One user, several machines on the VPN | Each machine as T1 or T2. The runtimes on them are the team runtimes of one team and coordinate through the GitHub backend or the tac server. | Each machine reaches the coordination repository or the tac server; runtimes reach each other's published MCP endpoints directly over the VPN. | S1 § 8 |
| **T4** | A team on the VPN | As T3 with several users; the tac server carries the messaging. Webwork on the desktop connects through its local runtime. | Every member's machine reaches the tac server over TLS on the VPN. | S1 § 8 |
| **T5** | A member off the VPN | A machine outside reaches the tac server's public address; the relay forwards TAC and MCP to runtimes inside. | The tac server's public address over TLS, with strict identity and from a paired device (`TAC > TAC-PEOPLE`, CI.10; `TAC > TAC-CRYPT`, CI.18). Runtimes inside keep an outbound connection to the relay; nothing inside accepts a connection from outside. | S1 § 8; PQ-9, PQ-13 |
| **T6** | Standalone runtimes on an always-on machine (later) | An always-on machine runs runtimes for a long time without a window or a runtime client; quests are worked from the queue and supervised through trc. | The machine reaches the tac server; trc reaches the runtimes' endpoints. (`SCO > SCO-LATER`, L-5; PQ-16) | S1 § 8 |
| **T7** | A cloud agent (later) | A vendor's sandbox clones a repository, works and pushes a branch; the runtime that sent the todo asks the vendor and the repository server for the result. | The sandbox reaches the repository server only; it reaches neither tac nor a runtime. (`SCO > SCO-LATER`, L-1) | S1 § 8 |
| **T8** | A runtime host server for applications on a phone, on a tablet and in a browser | An application without a local runtime uses a runtime on a runtime host server: the runtime host server runs permanently and starts one runtime per connected application, which ends with that application's connection. It is the only way such an application reaches tac. The supervision application on a phone or tablet uses it in the first version; Webwork's web, phone and tablet applications follow in a later wave of Webwork (`SCO > SCO-LATER`, L-8). | The application reaches the runtime host server over WebSocket, from the local network, the VPN or the internet; from the internet only as a paired device with strict identity. The runtime it started reaches tac. (WQ-1; PQ-9, PQ-16; `RT > RT-INSTALL`, CR.46) | S1 § 8 |

T6 depends on a runtime that runs without an application connected to it, while a runtime
is started by its host and ends with it (`RT > RT-INSTALL`, CR.44). It is
later, with standalone runtimes (`SCO > SCO-LATER`, L-5): it is a service
that hosts a runtime for a long time, and that service is not planned now.
On the always-on machine the tac server and the runtime host server (T8) run in the first version; a runtime there is started for a connected application and ends with that application's connection (`RT > RT-INSTALL`, CR.46).
(PQ-16, PQ-9)

#### <!--[NFR-TOPO-FLOWS]--> 11.1.1 Key flows

The flows the architecture document draws as sequences (S1 § 9).

| Id | Flow | In one line | Source |
| --- | --- | --- | --- |
| **F1** | A host attaches | The host finds the installed runtime (it installs the one it carries only when none is installed), starts it, exchanges the versions, registers its tools and subscribes to the events from a sequence number on. A host that finds the runtime too new for it switches the features that use it off, or does not start. | S1 § 9; PQ-6 |
| **F2** | A prompt | The host queues an item (at the end, next, or as an update to the running prompt); the queue sends it when the session is free; the transport streams; tool calls go to runtime tools or back to the host; the result is recorded in the trail. | S1 § 9 |
| **F3** | A todo walk | A walk takes the next ready todo, claims its resources from tac, all or none, executes it, carries out what follows its completion and releases the leases. | S1 § 9 |
| **F4** | A process step with a gate | The step's prompt and its walks are executed; the gate writes its report and asks with the decision buttons; the decision moves the process. | S1 § 9 |
| **F5** | An ask reaches a person elsewhere | A run asks; nobody is active on the asking host; the ask travels through tac to the user's other devices or along its chain, and the answer returns to the run. | S1 § 9 |
| **F6** | A team review | The runtime creates the round folder and sends the review request with the document set to each member through tac; each returns a copy; reminders go out before the deadline; the copies are merged and the round's files are released. | S1 § 9 |
| **F7** | A todo to another quest | An item or a walk is queued in a named run of another quest, on the same machine or another; it is taken, refused with a reason, or waits and is shown at the sender; the done notification returns to the run that asked. From another team it arrives as a todo offer (`PAR > PAR-CROSS`, CW.26). | S1 § 9 |
| **F8** | Two executions on one repository | Each execution works in its own working tree on its own branch, holding a shared lease; when its todo is done it takes the repository's exclusive lease for the integration step, rebases, runs the checks, fast-forwards the main branch and pushes; the next one rebases first. | S1 § 9 |
| **F9** | A todo to the cloud (later) | A todo goes to a hosted agent or a runtime elsewhere; a branch comes back and is integrated as in F8. | S1 § 9 |
| **F10** | Supervising the team runtimes | trc reads the team runtimes and their endpoints from tac, attaches to each runtime's events, shows what waits; the supervisor answers an ask, pauses a queue, continues a process. | S1 § 9 |
| **F11** | A machine joins | The runtime is installed, gets the team's access and registers; it sees the team runtimes; nothing is converged for it. | S1 § 9 |
| **F12** | A version update | After the user asked for it, a host installs a new runtime version beside the old one; running runtimes go on. A migration of the workspace files runs only when the user confirmed it, once under the machine's file lock while the others pause; a runtime that meets files in an older format offers the migration or going back to an older runtime version. | S1 § 9; PQ-6 |

### <!--[NFR-GEN]--> 11.2 Generation units

What the project builds, as far as the sources state it. A generation unit is
one package or application with the technology it is written in.
The kinds in the table (server, client, and "shared" below) are the kind
names of the specification model's register of generation units, not the
terms of this document: by kind the runtime is a "server" there, though as a
program it is a runtime process and never a server.

| Id | Unit | Kind | Builds | Technology | Source |
| --- | --- | --- | --- | --- | --- |
| **G-1** | `tom_ai_runtime` | server (also a library inside the VS Code extension) | The runtime: engine, protocol, runtime tools, the MCP server, the tac client inside the runtime | TypeScript on Node; `tom_ai/ai_build/tom_ai_runtime` | S2 § 5, FO-1; S1 § 4 |
| **G-2** | `tom_tac_service` | server | The coordination and messaging service with its backends, the server mode and the relay | TypeScript on Node, no runtime dependencies; today in `tom_ai/vscode/`, to be in `tom_ai/ai_build/tom_tac_service` | S5; S2 § 5, FO-19 |
| **G-3** | `tom_tac_client` | client | The Dart tac client SDK | Dart, without Flutter | S1 § 12.1, CQ-15 |
| **G-4** | `tom_ai_runtime_client` | client | The Dart runtime client SDK; depends on `tom_tac_client` | Dart, without Flutter | S2 § 5, FO-11; S1 § 12.1 |
| **G-5** | the client SDKs of the eight other languages | client | A runtime client SDK and a tac client SDK each for TypeScript, JavaScript, Python, Java, Go, Rust, C and C++ | each in its language; `tom_ai/ai_build/tom_ai_runtime_nondart/<language>/` | S2 § 5, FO-10, FO-11; S1 § 12.1 |
| **G-6** | `tom_ai_runtime_ui` | client | The Flutter components and their gallery application | Dart with Flutter; `tom_ai/ai_build/tom_ai_runtime_ui` | S2 § 5, FO-11; S1 § 12.2, § 12.3 |
| **G-7** | the supervision application (trc) | client (an application) | The supervision of the team runtimes, as a Webforge application that also runs standalone | Dart with Flutter; it may depend on Tom Forge packages | S2 § 5, FO-12; S1 § 12.4 |

No source names a unit of the kind "shared". What the units share is the
runtime protocol's JSON schema and the TAC specification; the protocol layer
of every client SDK is generated from the schema (S2 § 5, FO-10; `CLI > CLI-PACK`,
CL.4).

**How the units are produced** is decided at the start of Phase 4 of the
specification process, not here (PQ-17, PQ-19). There, for each area of the
specification and for each unit, it is named which mapper or emitter writes
its code and what is produced directly from the specification's structured
output; a generator that is missing is built in that phase, so that as much
as possible is generated and a change later runs through regeneration
quickly. The units differ: for some a mapper or emitter fits, for others the
work starts from the structured output. Until then the register below names
the units and their technology, and no mapper.

**What the tooling offers** (`tomspecs` 0.17.0 in
`$TOM_BINARY_PATH/darwin-arm64/`, asked on 2026-11-19):

| Offered | Names |
| --- | --- |
| Mappers, which write a package from the intermediate form | `dart-tom`, `ts-shared`, `ts-react-client`, `ts-react-native-client`, `ts-hono-server`, `go-server`, `java-spring-server`, `csharp-aspnet-server` |
| Emitters, which write what a standard can express | `openapi`, `jsonschema`, `icu`, `asyncapi`, `markdown` |

The mappers write business applications: entities, repositories, HTTP routes
and screens. None of them writes a runtime, a protocol library or a command
line today (S1 § 3.5); which are used, and which have to be built, is named
at the start of Phase 4.

**Which standard descriptions the project publishes** (JSON Schema for the
two protocols, OpenAPI for the coordination protocol's HTTP operations,
AsyncAPI for the streams) is decided in Phase 4 as well. (PQ-18)

## <!--[DEC]--> 12 Decisions

Every decision of the product owner, as it stands. Source ids: `FO-n` in
S2 § 5; `CQ-n`, `DQ-n`, `WQ-n` in S1 § 14.1; `RT-n` in S19; `RS-n` in S18. A
decision that a later one replaced is listed once, with the earlier id named
under "Replaces or completes".

**The product and its places**

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-1** | FO-1 | The runtime is the package `tom_ai/ai_build/tom_ai_runtime`. | RT-1 (a package `tom_quest_runtime` beside the extension) | `VIS > VIS-SYSTEM`, `NFR > NFR-GEN` |
| **D-2** | FO-19, CQ-15 | The tac service is `tom_ai/ai_build/tom_tac_service`; tac is a reusable component of its own, and its tac client SDK is a package of its own (`tom_tac_client` in Dart), on which the runtime client SDK depends. | FO-19's "TAC clients in the API packages" | `TAC > TAC-BACKENDS`, `CLI > CLI-PACK` |
| **D-3** | FO-10, FO-11 | Client SDKs for nine languages: `tom_ai_runtime_client` for Dart, the others under `tom_ai_runtime_nondart/<language>/`; the protocol layer generated from the schema, a convenience layer by hand, one conformance suite. | — | `CLI > CLI-PACK` |
| **D-4** | FO-11, CQ-14 | Every reusable Flutter component lives in `tom_ai_runtime_ui`; Tom Forge's own component package builds on it. | — | `CLI > CLI-UI` |
| **D-5** | FO-12 | The supervision application is a Webforge application from the start that also runs standalone; it may depend on Tom Forge packages. | — | `CLI > CLI-TRC` |
| **D-6** | FO-16 | Telegram is deferred. | RT-9 (Telegram in the runtime) | `SCO > SCO-LATER` |

**The runtime**

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-7** | FO-2 | No transports implemented by a host: the VS Code language-model and Copilot chat transports are removed; Copilot only through direct calls and its SDK. | S19's host transports | `RT > RT-TRANSPORTS`, `SCO > SCO-OUT` |
| **D-8** | CQ-5 | The Agent Client Protocol in both directions — one adapter for agents that speak it, and the runtime answering as an agent for editors — late in the order. | — | `RT > RT-TRANSPORTS`, `RT > RT-HOST` |
| **D-9** | FO-6, FO-17 | Runtime tools live in the runtime, VS Code's tools stay in the extension and are registered with the runtime there; file, command, web and git tools are runtime tools for the model transports, never offered over the runtime's MCP server. | — | `RT > RT-TOOLS`, `RT > RT-MCP` |
| **D-10** | FO-5 | The streaming connection is length-prefixed JSON-RPC 2.0 over loopback TCP, with WebSocket for remote runtime clients. | confirms RT-2 | `RT > RT-PROTO` |
| **D-11** | RT-7 | The protocol's commands are a superset of today's bridge methods. | — | `RT > RT-PROTO` |
| **D-12** | CQ-6 | The numbered events of a run are kept in memory with a bound; the trail files are the durable record. | — | `RT > RT-PROTO` |
| **D-13** | CQ-2 | The runtime owns machine-wide state; its implementation routes through the local tac service. | — | `RT > RT-MACHINE` |
| **D-14** | FO-3, FO-4, DQ-9 | One installation per machine in the per-user application data folder, versions side by side; version checks, pass-through of unknown fields and upgrade callbacks in every client SDK. Which runtime a host installs and starts: D-49. | — | `RT > RT-INSTALL`, `RT > RT-VERSIONS` |
| **D-15** | CQ-4 | A runtime is started by its host and ends with it; standalone runtimes later. | — | `RT > RT-INSTALL` |
| **D-16** | RT-3 | The Agent SDK server of today becomes a mode of the runtime, so Webwork ships one Node payload. | — | `RT > RT-INSTALL` |
| **D-17** | RS-2, CQ-3, DQ-5 | The runtime finds its places through the workspace layout resolver; the repositories are those of the workspace's setup file; every todo is written with its own resources, and a quest's list of repositories and subtrees is the fallback. | RT-6, RT-10 (locations from a setting) | `RT > RT-LOCATIONS`, `PAR > PAR-APPROACH` |
| **D-18** | DQ-8, DQ-11 | The configuration is split by content: role types, processes and templates in the repository; providers, the allowed list and standard profiles as a team's configuration in tac, stored in whichever backend the team uses; the rest per runtime. | — | `RT > RT-CONFIG` |
| **D-19** | FO-15, CQ-16 | Secrets are references: `tsm:` followed by Tom Secrets Manager's own grammar, `os:`, and `env:` and `file:` as not-secure options; the runtime and the tac service are paired with Tom Secrets Manager once. | FO-15's `tsm:<vault>/<entry>` | `RT > RT-SECRETS` |
| **D-20** | CQ-7, DQ-3 | Asks are routed by presence and by role; every quest has a quest owner; an unanswered ask moves along a chain, can be forwarded and is monitored; asking people outside the team by e-mail is later. | — | `RT > RT-ASKS` |

**Coordination, people and messaging**

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-21** | CQ-8, WQ-2 | tac is specified as one `tac/2.0` and built in one go; a service announces its capabilities, and new ones are added within `tac/2.0`. | the minor versions in the earlier todos | `TAC > TAC-SPEC` |
| **D-22** | CQ-9 | The full tac server (accounts, keys, quotas, administration) is built first; TLS ends at a reverse proxy. | the smaller tac server for one team | `TAC > TAC-BACKENDS` |
| **D-23** | FO-9 | The relay is part of the tac server, carries TAC and MCP, and only forwards. | — | `TAC > TAC-BACKENDS` |
| **D-24** | DQ-1, PQ-23 | A team is a group of users, and its members' runtimes, the team runtimes, coordinate in it; there is no "agent group" as a thing of its own. One runtime belongs to one person. | DQ-1 in the part that kept it as a second thing | `TAC > TAC-PEOPLE`, `GLO` |
| **D-25** | CQ-10, DQ-2 | Identification by user id and e-mail and invitation with team tokens are both built; a team owner invites, a one-time password is passed on by the team owner, the tac server generates the user id; remote control only inside a team and only where the runtime's host allows it. Where identification is accepted: D-54. | — | `TAC > TAC-PEOPLE` |
| **D-26** | DQ-12 | A quest has a home team; its runtime acts for another team only by explicit address, with the person's token for that team. | — | `TAC > TAC-PEOPLE` |
| **D-27** | WQ-1 | An application in a browser, on a phone or on a tablet reaches tac only through a runtime on a runtime host server, the server side of that application; tac's participants are users and runtimes. | the earlier answer that such an application registers in tac, and the concept's earlier text | `TAC > TAC-PEOPLE`, `NFR > NFR-TOPO`, `SCO > SCO-LATER` |
| **D-28** | FO-7, WQ-3 | User messages: conversations that are direct, among several members, or attached, stored with a retention of one year by default that a team may change. | — | `TAC > TAC-CONV` |
| **D-29** | FO-8, FO-21, CQ-11 | Documents travel as content-addressed blobs with a size limit, a quota and a lifetime of 7 days by default and 30 at most; a process may pin its blobs while it runs; a review set is a named set of pinned files. | FO-21's open concept for longer processes | `TAC > TAC-DOCS` |
| **D-30** | DQ-4 | The versioned documents and the record of a review are in the project's specification folder or a specification repository, usually not in the quest. | — | `TAC > TAC-DOCS`, `TAC > TAC-REVIEW` |
| **D-31** | FO-20 | Messages and blobs are not encrypted at rest by default; it is an option, its key in Tom Secrets Manager. | — | `TAC > TAC-CRYPT` |
| **D-32** | WQ-4 | Webwork is told what was decided; its requirements are covered by the product as a whole, built in one go. | — | `TAC > TAC-WEBWORK` |

**Parallel work and quests**

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-33** | CQ-12 | Whether executions work in a working tree of their own is a setting per repository that the team decides and can change. | — | `PAR > PAR-APPROACH` |
| **D-34** | FO-13, FO-18, FO-22 | Repository quests as planned; one personal repository per user with a folder per quest and personal notes; quest notes stay in the quest. | — | `PAR > PAR-QUESTS` |
| **D-35** | CQ-13, DQ-8 | Handing todos to hosted agents is later; a data policy per quest or repository is later. | — | `SCO > SCO-LATER` |

**The specification and the delivery**

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-36** | PQ-19, PQ-17 | The specification's documents are TomSpecs documents, written in the TomSpecs process with all its phases: the Project Idea, the Solution Blueprint, the detailed documents, then the code generation, where the mapping per area and per unit is named at the start of Phase 4. | CQ-17 and DQ-10 (the Blueprint deepened, a detailed document only where a component needs one, the runtime implemented by hand); RS-5 | `DEL`, `NFR > NFR-GEN` |
| **D-37** | PQ-19 | The specification is made in a run of the TomSpecs process, through all its phases. Which steps of a phase can be skipped is suggested as the run proceeds, and the product owner decides each time. | CQ-1 and DQ-13 (a run of the idea-to-todos process on the concept, not the TomSpecs process) | `CON`, `DEL` |
| **D-38** | CQ-18, DQ-7 | The design is delivered as a complete inventory of the extension's screens, a description per screen and component, and a gallery application. | — | `CLI > CLI-SCREENS` |
| **D-39** | DQ-6 | Two tracks are built in parallel: tac, and the runtime. | — | `DEL` |
| **D-40** | RS-3, RT-5 | The split of the extension starts after the extension's features and the workspace layout are finished. | — | `DEL` |
| **D-41** | CQ-19 | During the split the extension is branched, the new line has its own extension id and working tree, and it refuses to start beside the old one in the same window. | RS-1 | `DEL` |
| **D-42** | CQ-20 | The todos filed before the concept are input; a new set replaces them. | RS-4 | `DEL` |
| **D-43** | RT-8 | The Dart runtime client SDK is the client SDK Tom Forge builds on. | — | `CLI > CLI-PACK` |

**Decisions from the answers to the questions `PQ-1` … `PQ-23`** (the
product owner's answers of 2026-11-19, kept in
`01_02_Questions Round/answers.md`; D-36 and D-37 above are from these
answers too)

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-44** | PQ-1, PQ-22 | The product owner (member id `alexis`, display name Alexis) is the only reviewer of the specification; no document type has a team of its own. | — | `USR > USR-TEAM` |
| **D-45** | PQ-8 | No fixed order of building: the order that reaches the finished product fastest, with two runs working in parallel. | — | `DEL` |
| **D-46** | PQ-2, PQ-3 | A run pins the version of its process and takes a changed definition over at a step boundary on confirmation, which is the usual case; a step declares preconditions, which the runtime enforces and the user can override. | — | `RT > RT-RUNS` |
| **D-47** | PQ-10 | Three backends are in the first delivery; the GitHub backend stays. | — | `TAC > TAC-BACKENDS` |
| **D-48** | PQ-4 | A short process for small changes is not part of this product; it is proposed in the quest `tom_specs`. | — | `RT > RT-RUNS`, `SCO > SCO-OUT` |
| **D-49** | PQ-6 | A host installs the runtime when none is installed and otherwise uses the installed one; an update happens only when the user was asked; a host too old for the runtime switches the features off or refuses to start; older workspace files are migrated or the runtime goes back to an older version, on the user's choice. | DQ-9 in the part "every host starts the version it was built with" | `RT > RT-INSTALL`, `RT > RT-VERSIONS` |
| **D-50** | PQ-7 | The client SDKs of all nine languages are in the first delivery. | — | `CLI > CLI-PACK` |
| **D-51** | PQ-9 | The supervision application runs on the phone and the tablet in the first version, reached from the internet as well as from the local network or the VPN; a device is paired and gets a key of its own. | CQ-10 in the part that defers the pairing; WQ-1 in the part that defers the runtime host server | `CLI > CLI-TRC`, `NFR > NFR-TOPO`, `SCO > SCO-LATER`, `TAC > TAC-CRYPT` |
| **D-52** | PQ-16 | Standalone runtimes, also those on an always-on machine, are later; a runtime host server, which runs permanently and hosts one runtime per connected application, each ending with that application's connection, is part of the model. | — | `RT > RT-INSTALL`, `NFR > NFR-TOPO` |
| **D-53** | PQ-12, PQ-23 | An owner of a team may do what the table of rights says; the team runtimes need nothing created or deleted. | — | `TAC > TAC-PEOPLE` |
| **D-54** | PQ-13 | Open (identification) or strict (invitation and team tokens) is a setting of the tac server, for everyone on it; every access from the internet is strict and that cannot be configured. | D-25 in the part that leaves open where identification is accepted | `TAC > TAC-PEOPLE` |
| **D-55** | PQ-14 | The whole approach to parallel work is confirmed; in strict mode an execution holds an exclusive lease for the whole todo, and a repository without working trees per execution is always in it. | — | `PAR > PAR-APPROACH` |
| **D-56** | PQ-15 | The new packages are BSD-3; for now they are published only to pub.dev and to the workspace's binaries repository. | — | `NFR` |
| **D-60** | S21, TQ-1 … TQ-11 | The terminology is agreed: agent, user and person, account, team runtimes and their visibility, todo offers, claim and lease, exclusive and shared leases, strict and worktree mode, execution, resources and their names, application, host, client and server. The glossary states it. | the earlier glossary; "agent group", "customer", "touch set", "unit", "grant" and "request" as nouns, "lock" for a lease | `GLO`, `TAC > TAC-COORD`, `TAC > TAC-PEOPLE`, `PAR > PAR-APPROACH` |
| **D-57** | PQ-17, PQ-18 | Which mapper or generator writes which unit, and which standard descriptions are published, is decided at the start of Phase 4; missing generators are built there. The API documentation of the client SDKs and hand-written user and programmer's guides are delivered. | — | `NFR > NFR-GEN`, `NFR` |
| **D-58** | PQ-21 | The link between a host and its runtime is an API with callbacks in both directions over a wire protocol of JSON structures; its records get object models worked out from the workspace's existing schemas; the shape of a conversation and of a question on the wire is settled in the interface specification; unloading runs is an option, not part of the first version unless measurement warrants it. | — | `RT > RT-PROTO`, `RT > RT-INSTALL` |
| **D-59** | PQ-23, PQ-20 | A resource is a whole repository or a part of one described by a pattern, named and not registered; tac knows only the leases it has given and answers a claim from them; a runtime works with what its user can reach. A person joins a tac server and then creates a team. | S5's declared "units" and infrastructure resources, for now | `TAC > TAC-PEOPLE`, `TAC > TAC-PEOPLE > TAC-GROUPS`, `TAC > TAC-COORD` |

## <!--[CON]--> 13 Contradictions

Where sources disagree, and how it is resolved. The cross-check S10 § 6
lists four of them from the TomSpecs tooling's reading of this quest's
documents (X-1, X-8, X-9, X-10); they stand here as that reading found them.

- **X-1** **Host transports and host tools.** S19 gives a host its own
  transports and tools; S2 § 3.1 says a host "provides no tools and no
  transports"; S3 (WR-7) and S14 need tools that the host carries out —
  Webwork's document tools, Tom Forge's equivalents of the editor tools.
  **Resolved:** there are no host transports (D-7). There are host tools: a
  host registers its tools with its runtime, and the runtime calls the host
  back (S1 § 6.3; `RT > RT-TOOLS`). S2's "VS Code tools stay in the
  extension" and Webwork's "document tools executed in Webwork" are the same
  thing.
- **X-2** **The secret reference.** S2 § 5 (FO-15) writes a Tom Secrets
  Manager reference as `tsm:<vault>/<entry>`; S15 gives the grammar
  `[env:prod]store/path#field`. **Resolved:** the prefix `tsm:` is followed
  by Tom Secrets Manager's own grammar unchanged (D-19).
- **X-3** **An application without a runtime.** S3 (WR-2, WR-6) asks that Webwork
  in a browser or on a phone registers in tac itself, with a Dart tac client that
  needs no runtime; an earlier answer of the product owner said such an application
  connects "through a server part that runs the runtime for them", with a
  partial direct connection for messaging to be investigated; S1 at first had
  such an application talk to tac directly. **Resolved:** every application reaches tac
  through a runtime; an application in a browser, on a phone or on a tablet uses a runtime on a
  runtime host server (D-27). WR-2 and WR-6 are met differently than asked, and
  Webwork's messaging on the web and the phone comes with Webwork's own
  server side (`TAC > TAC-WEBWORK`; `SCO > SCO-LATER`, L-8).
- **X-4** **Two scopes of the tac server.** S6 and S5 plan the full tac server with
  "customers" (in the product: accounts), keys, quotas and an administration
  interface; S3 (WR-1) asks for a small team's tac server without them.
  **Resolved:** the full tac server is built first; a small team is that tac server
  with one account (D-22).
- **X-5** **"Group", "agent group" and team.** S13 says "a Webwork team is
  one tac group"; S5 uses "agent group" for runtimes that coordinate; S1
  § 7.3 (DQ-1) kept the two apart. **Resolved:** a team is a group of users, and its
  members' runtimes, the **team runtimes**, coordinate in it; S5's term
  names no thing of its own and is not used (D-24, D-60).
  Webwork's "one team, one group" holds as "one team".
- **X-6** **One `tac/2.0` against stepwise versions.** The earlier plan (the
  todos S1 § 7.10 describes) added to the protocol in minor versions, one per
  capability; S5 § 8 says minor
  versions only add. **Resolved:** one specification `tac/2.0`, built in one
  go, with capabilities announced on connect (D-21).
- **X-7** **How the specification is made.** S1 § 13.1 and § 14.1 record the
  product owner's decision that the specification "is made in the
  `idea_to_todos` run on this concept, not in the tom_specs process", with
  the Solution Blueprint deepened and a detailed document only where a
  component needs one. This Project Idea is Phase 1 of a run of the TomSpecs
  process. **Resolved:** the decision has changed. The specification is made
  in the TomSpecs process with all its phases; steps that can be skipped are
  suggested as the run proceeds (D-37, D-36). The idea run on the concept is
  not started.

- **X-8** **Which quest owns the coordination.** S5, S6 and S16 name a quest
  `agent_coordination` as the quest that owns tac and the parallel-work rules;
  that quest does not exist. **Resolved:** the quest `ai_runtime` owns them
  (S1 § 2.4).
- **X-9** **Where the packages are.** S19 and S6 place the runtime and the
  service in `tom_ai/vscode/`, the runtime under the name
  `tom_quest_runtime`; `tom_tac_service` is there today. **Resolved:**
  `tom_ai/ai_build/tom_ai_runtime` and `tom_ai/ai_build/tom_tac_service`
  (D-1, D-2); the service is moved.
- **X-10** **Telegram.** S19 puts Telegram into the runtime; S6 keeps it out
  of the coordination idea. **Resolved:** deferred (D-6).
- **X-11** **Messages over the GitHub backend.** S6 says the GitHub backend
  carries no messages between machines; S2 § 3.4 has it keep the blobs of
  messages in the coordination repository. **Resolved:** the GitHub backend
  stays in the first delivery as S6 designed it, for leases, sessions and
  endpoints; messaging, documents and reviews across machines are on the
  tac server only (D-47; `TAC > TAC-BACKENDS`, CA.26).
- **X-12** **Runtimes on an always-on machine and the lifetime of a runtime.** S1 § 8 has a
  topology in which an always-on machine runs runtimes without a window
  (T6); the decision is that a runtime is started by its host and ends with
  it, with standalone runtimes later (D-15). **Resolved:** standalone
  runtimes on an always-on machine are later; a runtime host server, which hosts one runtime per connected
  application, each ending with that application's connection, is part of the model and is not a standalone runtime
  (D-52).

- **X-13** **Which runtime a host starts.** The earlier answer was that every
  host carries the runtime version it was built with and starts that version
  (S1 § 5.7, DQ-9). The answer of the first question round is that a host
  installs a runtime only when none is installed, otherwise uses the
  installed one, and that nothing is updated without the user having been
  asked. **Resolved:** the later answer holds (D-49). Versions can still lie
  side by side (CR.41), which is what going back to an older runtime needs
  (CP.33).
- **X-14** **Pairing of devices and the runtime host server, later or now.**
  S1 § 11.1 defers both (CQ-10, WQ-1). The answer of the first question
  round puts the supervision application on the phone in the first version,
  reached from the internet. **Resolved:** the pairing of devices and the
  runtime host server for the supervision application are in the first
  version (D-51); end-to-end encryption and Webwork's own server side stay
  later (`SCO > SCO-LATER`, L-6, L-8).
- **X-15** **Declared resources or named ones.** S5 and S6 have "units" and
  infrastructure resources declared in tac's data, and four kinds of
  resource. The answer to PQ-23 is that a
  resource is only named when it is claimed, that there are two kinds for
  now, and that tac keeps no list of resources. **Resolved:** the later
  answer holds (D-59); the protocol's other kinds stay unused for now.

## <!--[RISK]--> 14 Risks and dependencies

### <!--[RISK-RISKS]--> 14.1 Risks

| Id | Risk | Trigger | Source |
| --- | --- | --- | --- |
| **R-1** | **The split of a large extension while it keeps changing.** The engine is entangled with the extension: the queue manager and the model handler are large, and process-wide singletons assume one quest per process. Changes to the old line during the split have to be carried into the new one. | A feature or fix lands in the extension after the split has begun; a stage of the split leaves the extension not working. | S19; S1 § 13.3; S18 |
| **R-2** | **What is specified moves.** The extension's features change while they are described; the descriptions of screens and of engine behaviour go out of date. | A change in the extension to a view or an engine feature that a section here describes. | S1 § 12.3, DQ-7; S17 |
| **R-3** | **Team features nobody else has used.** Teams, invitations, escalation of asks and the review exchange are designed by and for one person with several machines. | The first second person joins a team; a reviewer without a repository takes part in a review. | S1 § 7.3, § 6.6, § 7.7; S9 |
| **R-4** | **Overlap with protocols others maintain.** The runtime protocol covers ground the Agent Client Protocol, A2A, MCP and the vendors' own protocols cover; they change quickly. | A revision of one of them (MCP's revisions of 2025-11 and 2026-07 differ); an agent or editor the product wants to reach speaks only one of them. | S9; S1 § 15.1, § 6.4 |
| **R-5** | **Vendors' interfaces in preview.** The agent SDKs and command lines the agent transports rest on, and every interface for hosted agents, are preview or beta; one hosted agent service was shut down with two months' notice. | A vendor changes or withdraws an interface a transport uses. | S9; S1 § 11.5, § 15.4 |
| **R-6** | **The full tac server before anybody uses it.** Accounts, quotas and the administration interface are built before a first team works on the tac server. | The first team's use shows needs the full tac server did not foresee; Webwork's messaging waits for parts it does not need. | S1 § 7.2, CQ-9; S3 |
| **R-7** | **Everything in one go.** tac is built to the whole of `tac/2.0` and Webwork is told the product is built in one go; nothing is used before all of it is there. | An early part proves wrong only when a later part uses it. | S1 § 7.9, WQ-2, WQ-4 |
| **R-8** | **Webwork's messaging on the web and the phone waits.** It comes with Webwork's own server side, in a later wave of Webwork; until then its messaging works on the desktop only. The runtime host server it will use is built in the first version, for the supervision application. | Webwork's team needs messaging or review on a phone or in a browser before Webwork's server side exists. | S1 § 7.10, WQ-1; S13; PQ-9 |
| **R-9** | **Another writer in the repositories.** Other sessions, runs and machines write to the same repositories on one branch while this product is specified and built; uncommitted work of others is in the way of builds and installs. | Two runs touch the same repository; a build or an install runs from a tree another session left changed. | S16; S1 § 10.1 |
| **R-10** | **Leases held for the work of agents.** Others found that what they call "locks", held by agents, are held too long or never given back. | An execution ends without its lease being released; a long execution holds a lease on a repository. | S9; S1 § 15.2 |
| **R-11** | **No gate before the main branch until the integration step exists.** Until then a broken commit is at once every other session's base. | An execution commits a change that breaks a package others build on. | S1 § 10.1, § 10.3 |
| **R-12** | **Nine languages.** Six of the client SDKs are tested only through the conformance suite; nobody uses them yet (see also R-24). | A first user of such a client SDK meets what the suite does not cover. | S2 § 3.5; S1 § 12.1; PQ-7 |
| **R-13** | **Several hosts and runtime versions on one set of workspace files.** On one machine the hosts share the installed runtime, and a host too old for it switches its features off or does not start. Across machines and people the files are shared through git: once they are migrated on one machine, every runtime elsewhere that is older stops working on them until it is updated. | The user confirms a migration on one machine while another machine, or another member of the team, still runs an older runtime; an application is not yet available in a version that fits the installed runtime. | S1 § 6.7, § 9 F12; PQ-6 |
| **R-14** | **The product's value depends on others being able to use its parts.** The protocol, the process format and the coordination are entangled with this workspace's conventions. | A user outside this workspace tries to use tac or a client SDK without the rest. | S9; S1 § 15 |

**Risks the first question round added.** (They are numbered after the
dependencies below, since the numbers before them are taken.)

| Id | Risk | Trigger | Source |
| --- | --- | --- | --- |
| **R-22** | **The tac server and the runtime host server reachable from the internet in the first version.** The tac server and the runtime host server are reached by phones from the internet before the product has been used by anyone but the product owner; the security model is written for a case the first design had deferred. | The public address of the tac server or of the runtime host server is opened; a device is lost; a team token or a device key leaks. | PQ-9, PQ-13; `TAC > TAC-CRYPT`, CI.19 |
| **R-23** | **The full process for a product no mapper fits yet.** The specification runs through every phase of the TomSpecs process, and the code generation has no mapper for a runtime, a protocol library or a command line; generators have to be built in Phase 4. | Phase 4 is reached and the generators needed are larger than the code they would write. | PQ-19, PQ-17; `NFR > NFR-GEN` |
| **R-24** | **Six client SDK languages nobody uses yet, in the first delivery.** They have to be built, kept in step with the protocol and published with the rest. | The protocol changes late; a language's convenience layer falls behind. | PQ-7; `CLI > CLI-PACK` |

### <!--[RISK-DEPS]--> 14.2 Dependencies

| Id | Depends on | For | State | Source |
| --- | --- | --- | --- | --- |
| **R-15** | The workspace layout restructuring (quest `al_the_bear`, and its part in the extension) | The runtime's locations and configuration layers; the repository record the claims use | The resolver and the layered configuration are built in the extension; the migration of the workspace, the new fleet skills and the cutover are open | S12; S1 § 3.4, § 5.5 |
| **R-16** | The extension's remaining features (quest `vscode_extension`) | The engine being complete before it is extracted | open | S1 § 3.1; S18 |
| **R-17** | Tom Secrets Manager's TypeScript client being published | Resolving `tsm:` references in the runtime and the tac service | built, not yet published | S15; S1 § 3.6 |
| **R-18** | Releases of `tom_todo_model` | The todo fields the claims use (a todo's resources); every release moves the lock files (`pubspec.lock`) of its many consumers | 3.1.0 today, a further major release planned | S1 § 2.4, § 10.1 |
| **R-19** | Tom Forge's review component in Flutter | The review group of the UI components, shared by Webwork, the quest application and trc | planned in the quest `tom_forge` | S1 § 3.3, § 12.2; S14 |
| **R-20** | The coordination repository and the tac server on the always-on machine (quest `al_the_bear`) | The GitHub backend; the tac server for the fleet and for a team | open; the tac server waits for this product | S1 § 2.2, § 3.4 |
| **R-21** | The `tomspecs` tool and the SOM packages | The specification tools the runtime carries | one binary, released; new tools are being added in the quest `tom_specs` | S1 § 3.5 |

## <!--[DEL]--> 15 Delivery

**What comes before the building.** (S2 § 4.1; S1 § 13.1; D-40)

1. The VS Code extension's features are finished.
2. The workspace layout is restructured.
3. This specification is written, and the product is built from it. The
   split of the extension starts here.

**Two tracks, in parallel.** (S1 § 13.1, DQ-6; D-39)

| Track | Contains | Depends on the split of the extension |
| --- | --- | --- |
| **tac** | The tac server, participants and teams, messaging, documents, the tac client SDKs | no |
| **the runtime** | The split, the protocol, the runtime client SDK, the UI components, the tac client inside the runtime with claims and the integration step | yes |

The two tracks touch different repositories. Webwork and Tom Forge wait for
their parts and progress on their own meanwhile (`LAND > LAND-WAIT`). Inside
and between the tracks no order is fixed (below).

**The stable extension during the split.** (S1 § 13.3, CQ-19; D-41)

- The extension is branched; the new line gets its own extension id and is
  worked on in a separate working tree.
- The new extension refuses to start while the old one is active in the same
  window.
- The new one is installed everywhere and activated only in the window used
  for testing, where the current one is deactivated.
- The old extension keeps being changed as needed; its changes are merged
  forward into the new line, or their work is repeated there.

**The documents of the specification.** (PQ-19; D-36, D-37)

- The specification runs through the TomSpecs process with all its phases:
  this Project Idea, the Solution Blueprint for the whole system, the
  detailed documents, the code generation, the tests, the implementation,
  the acceptance and the release.
- Where a step of a phase adds nothing for this product, skipping it is
  suggested when the run reaches it, and the product owner decides.
- At the start of Phase 4 the mapping per area of the specification and per
  unit is named, and missing generators are built there
  (`NFR > NFR-GEN`).
- They are TomSpecs documents, so the specification tools work on them.

**The order of building.** (PQ-8; D-45)

- No order of the component groups or of the units is fixed in advance:
  the order is the one that reaches the finished, whole product fastest.
- The work is done by two runs in parallel (the two tracks above). A todo
  that waits for a todo of the other run is held and goes on when that one
  is done; that the queue does this without a person is asked of the
  extension (quest `vscode_extension`, todo
  `vscimpb179_akss-blocked-item-resumes-by-itself`).

**What is delivered** is the code of the units (`NFR > NFR-GEN`) and the
documents of N-30.

**The todos.** The todos filed before the concept are input; the new set
replaces them, and the entries of other quests that wait on them follow
(S1 § 13.4, CQ-20; D-42).

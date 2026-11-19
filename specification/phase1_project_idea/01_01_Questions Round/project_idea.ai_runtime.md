# Project Idea — Tom AI Runtime

## <!--[ABOUT]--> 0 About this document

| | |
| --- | --- |
| **Artifact** | Phase 1 Project Idea (PI) of the TomSpecs project flow (`tom_specs_project_flow.md`, `PF-PHA-P1`) |
| **Product** | Tom AI Runtime (tar), Tom Agent Coordination (tac), Tom Runtime Control (trc), the client packages and the Flutter UI components |
| **Spec root** | `tom_ai/ai_build/specification/` |
| **Product owner and review team** | recorded in `USR > USR-TEAM` |
| **Sources** | section 1 (`SRC`); the three main ones are kept as snapshots in `sources/` |
| **Written by** | `agent_spec_author` |
| **Status** | Question round 1: 19 questions open |
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
| **`R-<n>`** | A risk, with what would trigger it, or a dependency (section 14). |
| **`O-<n>`** | Something out of scope (section 5). |
| **`L-<n>`** | A feature deferred to later (section 5). |
| **`E-<n>`** | A fact about what exists today (section 6). |
| **`T<n>`** | A network topology (section 11.1). |
| **`F<n>`** | A key flow (section 11.1.1). |
| **`PQ-<n>`** | A question to the product owner, standing after the statement it asks about. |

After a statement, its source stands in brackets: the source id and the place
in it, e.g. `(S1 § 7.3, DQ-2)`. `CQ-n`, `DQ-n` and `WQ-n` are the product
owner's answers in S1 § 14.1, `FO-n` those in S2 § 5, `WR-n` the requirements
of S3. A section is referred to by its id chain, outer first
(`TAC > TAC-PEOPLE`).

Capability areas: `CR` runtime core · `CP` protocol and hosts · `CT` tools and
MCP · `CA` coordination between runtimes · `CI` people, teams and identity ·
`CM` messaging · `CV` documents and review · `CW` parallel work and
integration · `CL` client packages · `CU` UI components · `CK` supervision ·
`CQ` repository quests and personal files · `CS` secrets, configuration and
providers.

## <!--[SRC]--> 1 Sources

The idea is drawn from the sources below. Where two of them disagree, S1 wins;
S1 § 2.4 lists what is outdated in the older ones.

| Id | Source | Holds | Standing |
| --- | --- | --- | --- |
| **S1** | `_ai/quests/ai_runtime/ai_runtime_concept.md`; snapshot `sources/ai_runtime_concept.md` | The concept: status, what the other quests bring, the system, runtime, protocol and hosts, coordination and messaging, topologies, flows, parallel work, clients and UI, the deliverables, and the product owner's decisions CQ-1 … CQ-20, DQ-1 … DQ-13, WQ-1 … WQ-4 (§ 14.1) | current; the main source |
| **S2** | `_ai/quests/ai_runtime/ai_runtime_feature_overview.md`; snapshot `sources/ai_runtime_feature_overview.md` | Components and their main features; the decisions FO-1 … FO-22 (§ 5) | current in its decisions; outdated in § 3.1 (the layout resolver is built, the guidelines folder and the configuration layers differ), in the todo model's version, and where it says a host provides no tools |
| **S3** | `_ai/quests/ai_runtime/webwork_requirements.md`; snapshot `sources/webwork_requirements.md` | What Webwork needs from tar and tac, WR-1 … WR-7, each with what exists and what is missing | current as a requirement statement; WR-2 and WR-6 are met differently (S1 § 7.10) |
| **S4** | `_ai/quests/ai_runtime/quest-notes.ai_runtime.md` | The product owner's notes: the names tar, tac, trc, the goals a … n, the split of the MCP server, the relay | current; the owner's words |
| **S5** | `tom_ai/vscode/tom_tac_service/doc/tac_specification.md` | The protocol `tac/1.0` as built: records, lease lifecycle, operations, backends, errors, the HTTP / WebSocket and GitHub refs bindings | current for what is built; it knows no people, teams, user messages or documents, and names a quest `agent_coordination` as its owner |
| **S6** | `_ai/quests/ai_runtime/ideas/agent_collaboration/agent_collaboration.md` | The coordination idea: todo follow-ups, protocol, service, client and backends, claims, branches and worktrees, messages between runtimes, endpoints, the Coordination page, the guideline, the rollout | current for leases, messages between runtimes, endpoints and branches; outdated in its owner, its package places and where it describes submodule pointers |
| **S7** | `_ai/quests/ai_runtime/llm_providers_runtime_integration.ai_runtime.md` | Model providers and the three ways into them | current |
| **S8** | `_ai/quests/ai_runtime/ideas/remote_control_app/remote_control_app.md` | The supervision app in the product owner's words | current; input only |
| **S9** | S1 § 15 "Research: what other teams do" | External research read on 2026-11-18, with its links: client and agent protocols, parallel work and git models, spec-driven work, cloud agents, UI kits, supervision, secrets | current; some claims rest on secondary sources, marked there |
| **S10** | `_ai/quests/tom_specs/tooling/notes_ai_runtime.md` | The components and interfaces of this quest as the TomSpecs tooling sees them, and the contradictions it found | outdated in package names and places; useful as a cross-check |
| **S11** | `_ai/quests/tom_specs/tooling/tom_specs_tooling_suggestions.md` | Suggestions addressed to this product: one review component for every host, review copies that travel without the user, the process engine as a runtime service, the remote control | current |
| **S12** | `_ai/quests/al_the_bear/ideas/workspace_layout/workspace_layout.md` | The workspace layout: root, workspace folders, the layout resolver, the configuration layers, independent repositories, the repository record | current |
| **S13** | `_ai/quests/webwork/ideas/webwork_redesign/webwork_redesign.md` | Webwork's redesign: messaging, the review exchange, the bottom panel with the AI tab, the wave plan | current |
| **S14** | `_ai/quests/tom_forge/spec_quest_workbench.tom_forge.md` | Tom Forge's quest application: the views it expects, hosting a runtime per open quest | outdated in the runtime's name and owner; its second part waits for this specification |
| **S15** | `tom_ai/secrets_clients/protocol/protocol.md` and `_ai/quests/tom_core/ideas/tom_secrets_manager/tom_secrets_manager.md` | Tom Secrets Manager: the client protocol, the reference grammar, how a client is identified and approved | current |
| **S16** | `_copilot_guidelines/parallel_work.md` | The rules for working in parallel today, and what enforces each | current; names a quest `agent_coordination` as the future owner |
| **S17** | `tom_ai/vscode/tom_vscode_extension/`: its code, `tom_ai/vscode/tom_vscode_extension/_copilot_guidelines/architecture.md` and `tom_ai/vscode/tom_vscode_extension/doc/` | The engine as built: the starting point of the runtime and of the UI components | current; it keeps changing |
| **S18** | `_ai/quests/ai_runtime/runtime_split_plan.ai_runtime.md` | What comes before the split of the extension; the stable build during it | its questions are settled in S1 § 14.1 |
| **S19** | `_ai/quests/ai_runtime/quest_runtime_design.ai_runtime.md` | The first runtime design: host interface, process model, stages | outdated in package place and name, locations, host transports, Telegram and its measurements; background only |
| **S20** | `_ai/quests/ai_runtime/ai_runtime_project_idea.md` | The first collection of the idea | superseded by S1; background only |

Every path above resolves in the workspace on 2026-11-19. The snapshots in
`sources/` carry the original's path and the date in their first line; S1 was
taken at the state of 2026-11-19.

**Not a source:** the earlier agent_container and project_coordination work.
It may supply aspects to consider, nothing more (S4, note m).

## <!--[VIS]--> 2 Vision

### <!--[VIS-PROBLEM]--> 2.1 The problem

Work with AI agents is organised today around the coding session: one task,
one agent run, one branch or pull request to review. A larger undertaking
does not fit that unit. It runs for weeks or months, spans many repositories
and several machines, follows a process with phases and gates, and depends on
people who answer questions, review documents and decide (S9; S1 § 15.2,
§ 15.3).

The Tom workspace has an engine for such work: quests, todos, processes with
runs, a prompt queue, sessions, transports to the models, tools, team review.
It lives inside one host, the VS Code extension, and is entangled with it
(S1 § 2.1). Four things follow:

- **Other applications cannot use it.** Webforge (Tom Forge) and Webwork need
  the same engine and would have to build it again (S4, notes a, k).
- **Agents and people work side by side without anything keeping them
  apart.** Everything is committed on one branch in shared clones; "one writer
  per repository" is an agreement; machines drift apart unnoticed; shared
  files are overwritten by another window (S1 § 10.1).
- **People outside the editor cannot take part.** A reviewer or a decider
  without access to a repository gets documents by hand, and a question from
  an agent waits in the window that asked it (S1 § 3.5, § 6.6).
- **Nobody sees the whole.** What waits, where, on which machine, is spread
  over windows (S8).

Why now: the engine's features are complete enough to be extracted; three
hosts and three other quests wait for it (`LAND > LAND-WAIT`); and the
coordination service's first part exists and is used by nothing yet
(S1 § 2.1, § 2.3).

### <!--[VIS-SYSTEM]--> 2.2 What the system becomes

The unit of work is the **project**: a quest with processes, gates, todos and
people, not a coding session (S1 § 4, § 15). The system has three components
and two sets of libraries:

| Component | Short | Is |
| --- | --- | --- |
| **Tom AI Runtime** | tar | The engine as a runtime of its own (`tom_ai/ai_build/tom_ai_runtime`, TypeScript): quests, todos, processes and runs, the queue, sessions, transports, tools and an MCP server, without a VS Code window. A host attaches to it and adds as thin a user interface as it needs. (S1 § 4, § 5; FO-1) |
| **Tom Agent Coordination** | tac | The service through which runtimes find each other and keep out of each other's way (presence, leases, messages, endpoints), and the messaging server between the people who use applications linked with a runtime: documents for review, messages, reminders, decisions. A reusable component of its own. (S1 § 4, § 7.1, § 7.2; CQ-15) |
| **Tom Runtime Control** | trc | The supervision application: every runtime of a team in one view, with full remote control. A Webforge application that also runs standalone. (S1 § 12.4; FO-12) |
| **Client packages** | — | One runtime client and one tac client per language, for nine languages (Dart, TypeScript, JavaScript, Python, Java, Go, Rust, C, C++). (S1 § 12.1; FO-10, FO-11, CQ-15) |
| **Flutter UI components** | — | `tom_ai_runtime_ui`: the reusable user interface of the runtime for Flutter applications. No user interface components for other platforms. (S1 § 12.2; S4, note l) |

The hosts of the first version are the VS Code extension, Webforge and Webwork
(S1 § 4).

### <!--[VIS-GIVES]--> 2.3 What it is to give

- **V-1** One implementation of the `_ai` formats and the engines, used by
  every host, so a quest behaves the same in VS Code, in Webforge and in
  Webwork. (S1 § 5.1; S4, note a)
- **V-2** A comprehensive collaboration system: quests, todos, processes,
  queues and agents run in runtimes that find each other and work together; a
  host only attaches to a runtime and adds a thin user interface, as much of
  it as that host needs. (S4, note k)
- **V-3** Agents that work across runtimes as they work across VS Code
  windows today: on one machine, across the VPN, and through a relay beyond
  it. (S4, notes b … e; S1 § 7.2)
- **V-4** A protocol with a streaming connection and an API over it, so any
  host can attach, and client libraries that make attaching a matter of a few
  lines. (S4, notes f, g, k; S1 § 6.1, § 12.1)
- **V-5** People as participants: messages, documents for review, reminders,
  questions and decisions travel between the people of a team and the runs
  that need them, also to people without access to a repository. (S1 § 7.1,
  § 7.4, § 7.7)
- **V-6** Parallel work that is enforced, not agreed: claims on what a run
  touches, an integration step before the main branch, a record of what each
  todo changed. (S1 § 10.4)
- **V-7** Supervision of a whole team's runtimes from one place. (S8;
  S1 § 12.4)
- **V-8** Putting the runtime's user interface into a Flutter application is
  simple. (S4, note l; S1 § 12.2)

## <!--[USR]--> 3 Users and stakeholders

### <!--[USR-GROUPS]--> 3.0 User groups

| Id | Who | Uses the system to | Source |
| --- | --- | --- | --- |
| **U-1** | **A developer working with agents in an editor.** One person with one or several machines, many quests, many windows. | Queue prompts and todo walks, run processes, answer the agents' questions, review results, and work in parallel without runs disturbing each other. | S1 § 3.1, § 10.1 |
| **U-2** | **A team member who reviews or decides**, often without access to any repository (a business reviewer). | Receive documents for review, annotate and return them; answer questions and take decisions that a run or a colleague addresses to them; exchange messages. | S1 § 3.2, § 7.7; S3 |
| **U-3** | **A team owner.** | Create a team, invite members, remove them, administer the team's configuration (the providers that may be used, standard profiles); is the last in the chain when a question stays unanswered. | S1 § 7.3, § 5.5, § 6.6; DQ-2, DQ-11 |
| **U-4** | **A quest owner.** Every quest has one. | Answer the questions that concern the quest's topics, or forward them. | S1 § 6.6; CQ-7 |
| **U-5** | **A supervisor of a group of runtimes.** Usually a person supervising their own runtimes, or a part of a team's. | See what every runtime does and what waits; queue todos, start and pause runs, continue processes, answer questions, review documents, from one place. | S8; S1 § 12.4; FO-12 |
| **U-6** | **An application developer** who embeds the runtime in a Flutter application, or uses it from another language. | Attach an application to a runtime through a client package, offer the application's own tools to it, and build the user interface from ready components. | S1 § 12.1, § 12.2, § 6.3; S4, notes k, l |
| **U-7** | **An administrator of a tac server.** | Run the server for one or several teams, set it up with TLS, create the first team, pair it with Tom Secrets Manager. | S1 § 7.2, § 5.8; CQ-9, CQ-16 |

### <!--[USR-HOSTS]--> 3.0.1 Hosts and waiting quests

| Id | Stakeholder | Interest | Source |
| --- | --- | --- | --- |
| **U-8** | **The VS Code extension** (quest `vscode_extension`) | Becomes a host: it keeps its views and its VS Code tools and runs the runtime in its window. Its features are finished before the engine is extracted. | S1 § 5, § 13.3; S2 § 3.3 |
| **U-9** | **Webforge / Tom Forge** (quest `tom_forge`) | Hosts one runtime per open quest in its quest application; builds its views on the Flutter components; later hosts trc as an application. | S1 § 3.3; S14 |
| **U-10** | **Webwork** (quest `webwork`) | Its AI tab runs on a runtime without a quest; its team messaging and review exchange run over tac. | S3; S13; S1 § 7.10 |
| **U-11** | **The fleet** (quest `al_the_bear`) | Runs the coordination repository and the tac server; its workspace layout is what the runtime resolves; its rules for parallel work become enforced. | S1 § 3.4; S12; S16 |
| **U-12** | **TomSpecs** (quest `tom_specs`) | Its processes and tools run in the runtime; its team review loses the user as courier of the review copies. | S1 § 3.5; S11 |
| **U-13** | **Tom Secrets Manager** (quest `tom_secrets_manager`) | The runtime and the tac service are its clients. | S15; S1 § 5.8 |

### <!--[USR-TEAM]--> 3.1 Owner and review team

The Project Idea does not record the product owner and the review team yet.
This section is filled from the answer to the question on the owner and the
review team in the round's question list: the owner (always a reviewer), the
members who review the specification by default — each with a member id, a
display name and a role, optionally the stakeholder they represent and an
e-mail address — and whether some document types have a team of their own.

> **❓ PQ-1 (2026-11-19T09:22+01:00) — Product owner and review team:** who is the product owner of this specification, and who reviews it by default?
>
> **Context.** The Project Idea's section "Owner and review team" is empty: no source names them. The Solution Blueprint records a review team — the owner, who is always a reviewer, and the members who review the specification's documents by default — and a document type may have a team of its own. Each member is recorded with:
> - a **member id**: lowercase letters, digits and `_`, for example `alice`; never `agent`. It is the name of that member's copy in a review round and the signature on their comments and answers;
> - a **display name** and a **role** (for example product owner, architect, developer, business reviewer);
> - optionally the **stakeholder** they represent (for example Webwork, Tom Forge, the fleet) and an **e-mail address**, which is only stored.
>
> So far every decision in the sources was taken by one person, and the review rounds of other specifications in this workspace ran with that person alone.
>
> **Why I ask.** The owner and the team go into the Solution Blueprint and decide who gets each document in a review round. With one reviewer a round is the owner's own review; with more it becomes a team review with copies, merging and conflicts. The system itself is also about teams, so reviewing it with a second person would exercise what it specifies.
>
> - **(a)** **The owner alone.** One member: you, as product owner and only reviewer. Please give your member id, display name and role. Every document type uses this team.
> - (b) **The owner and further members.** Please list each member with id, display name and role (and, if you like, stakeholder and e-mail), and say whether all review every document.
> - (c) **Different teams per document type** — for example a business reviewer only for the experience design document, a second developer only for the interface and security documents. Please list the default team and each exception.
>
> *Recommendation:* (a) for now — it matches how the decisions were taken so far; members can be added in the Solution Blueprint when someone joins.
>
> **Answer:**

## <!--[GLO]--> 4 Glossary

**The components**

| Term | Meaning |
| --- | --- |
| **tar** | Tom AI Runtime: the engine as a runtime of its own. |
| **tac** | Tom Agent Coordination: the service for coordination between runtimes and messaging between people; `TAC` is its protocol. |
| **trc** | Tom Runtime Control: the supervision application. |
| **runtime** | One running instance of tar. It serves one quest (or none, for an application's own AI), belongs to exactly one person, and is started by its host. |
| **host** | The application a runtime runs for and through which it reaches a user: the VS Code extension, Webforge, Webwork. The host supplies locations, identity, configuration, the user interface for questions, and its own tools. |

**Work in a runtime**

| Term | Meaning |
| --- | --- |
| **quest** | A larger project, spanning weeks or months, with its documents, todos and process state. It has an owner and a home team. |
| **process** | A defined way of working: phases, steps and sub-steps, the roles doing them, gates, decisions, subprocesses. |
| **gate** | The check that ends a phase of a process: a checklist with a recorded result, followed by a decision a person takes. |
| **run** | The unit of work in a quest: a process position, its variables, a queue lane with its settings, its sessions and a subject. A quest has several runs, working in parallel. |
| **queue** | The ordered list of items a run sends, one after the other. |
| **queue item** | One entry of a queue: a prompt, a todo or a group of todos, with its pre-prompts and follow-ups, the session it runs in and the transport it is sent with. |
| **session** | One conversation with a model or agent, with its history; named, and belonging to a run. |
| **transport** | The way a prompt reaches a model. A **model transport** calls a model's API and the runtime runs the tool loop. An **agent transport** hands the prompt to an agent that runs its own loop and reaches the tools through MCP. |
| **tool** | A function a model can call. A **runtime tool** is carried out by the runtime. A **host tool** is registered by the host and carried out there. |
| **ask** | A question the runtime puts to a person: a question, a pick, a document to work on, a tool approval, a plan, a decision, a gate. It is a stored record with a kind, the allowed answers, an optional default and a deadline. |
| **trail** | The durable record of what a run did: prompts, answers, tool calls, as files. |
| **event** | One thing a runtime tells its clients while it works: a piece of streamed text, a tool call, a queue item changing state, the process moving, an ask opened or answered. Events of a run are numbered. |

**People and coordination**

| Term | Meaning |
| --- | --- |
| **team** | A group of **people**: members, owners, invitations, conversations, review sets, and the right to control each other's runtimes. |
| **agent group** | A group of **runtimes** that coordinate: presence, leases, messages between runtimes, endpoints. A team and an agent group are two different things. |
| **participant** | Someone tac knows: a person (user id, e-mail, display name) or a runtime. A runtime names the person it belongs to. |
| **invitation** | How a person joins a team: an owner creates it for an e-mail address; it carries a one-time password. |
| **team token** | What a person holds after redeeming an invitation: the proof of membership in one team, sent with every request. |
| **lease** | An exclusive right on a resource for a limited time, granted by tac to a session and renewed while it is used. |
| **claim** | What a run asks for before it works: the leases on the resources its todo needs, taken all or none. |
| **fencing token** | A number that grows with every grant of a lease; a write carries it, so a write by a holder whose lease has passed to someone else is refused. |
| **unit** | A declared part of a repository (a path in it) that can be claimed on its own. |
| **endpoint** | An address a runtime publishes through tac for others to reach it (its MCP server, its remote control); it exists only while the runtime is present. |

**Messaging, documents and review**

| Term | Meaning |
| --- | --- |
| **conversation** | A sequence of messages between people: direct, in a group, or attached to a document, a review round, a todo, a run or a quest. |
| **message kind** | What a message is beyond text, so the recipient's application can act on it: document, review request, review return, ask, decision request, todo, reminder, notification, command. |
| **blob** | A file carried by tac, addressed by the hash of its content, with a lifetime. |
| **review set** | A named set of files pinned in tac for a review, which every reviewer of it can open. |
| **review round** | One round of a team review: the documents go out to the members, each returns an annotated copy, the copies are merged. |
| **round folder** | The record of a review round in version control, beside the documents: the base, each member's copy, the merged result. |

**Parallel work and quests**

| Term | Meaning |
| --- | --- |
| **integration step** | Bringing a run's commits onto the main branch: rebase, the repository's checks, fast-forward, push, under a short exclusive lease. |
| **touch set** | What a todo declares it will touch: repositories, packages, paths. |
| **repository quest** | A quest whose folder is a clone of the quest's own repository. |
| **personal repository** | One repository per person for the files that are only theirs: sessions, trails, session todos, machine settings, personal notes. |

## <!--[SCO]--> 5 Scope

The specification's root is `tom_ai/ai_build/specification/`.

### <!--[SCO-IN]--> 5.1 In scope

| Area | In scope | Source |
| --- | --- | --- |
| Runtime core (`CR`) | The `_ai` formats and stores; processes and runs; the queue; sessions; model and agent transports; locations and configuration; machine-wide state; installation, lifetime and versions | S1 § 5 |
| Protocol and hosts (`CP`) | The runtime protocol (commands, numbered events, reverse requests, asks); the host interface; routing and escalation of asks; versions and compatibility; the Agent Client Protocol in both directions | S1 § 6 |
| Tools and MCP (`CT`) | Runtime tools, host tools, the runtime's MCP server, the runtime as client of external MCP servers | S1 § 6.3, § 6.4 |
| Coordination between runtimes (`CA`) | Presence and discovery, sessions, leases and units, messages between runtimes, endpoints; the backends local, GitHub and server; the relay | S1 § 7.1, § 7.2; S5; S6 |
| People, teams and identity (`CI`) | Participants, teams, invitations and team tokens, identification, permission for remote control, a quest's home team and owner | S1 § 7.3 |
| Messaging (`CM`) | Conversations, message kinds, reminders, presence-aware delivery, history and read state | S1 § 7.4, § 7.5 |
| Documents and review (`CV`) | Blobs with lifetimes and pinning, review sets, the review exchange | S1 § 7.6, § 7.7 |
| Parallel work and integration (`CW`) | Claims in the queue, worktrees per repository setting, the integration step and queue, touch sets, the record of a todo's commits, quiescence, cross-quest addressing and delivery | S1 § 10.4, § 10.5 |
| Client packages (`CL`) | The runtime client and the tac client in nine languages, with one conformance suite | S1 § 12.1 |
| UI components (`CU`) | `tom_ai_runtime_ui`, the descriptions of its screens and components, a gallery application | S1 § 12.2, § 12.3 |
| Supervision (`CK`) | trc | S1 § 12.4 |
| Repository quests and personal files (`CQ`) | Quest types, the personal repository, personal notes | S1 § 12.5; S2 § 3.7 |
| Secrets, configuration and providers (`CS`) | Secret references and their resolution; the configuration split into the repository's, the team's and the runtime's part; the model providers | S1 § 5.5, § 5.8; S7 |
| The split | Extracting the engine from the VS Code extension, with a stable extension beside it while that runs | S1 § 13.3 |

### <!--[SCO-OUT]--> 5.2 Out of scope

- **O-1** The VS Code extension's own features: its views, panels and editors,
  and the tools that need VS Code. They stay in the extension, which becomes
  a host. (S1 § 6.3; S2 § 3.3)
- **O-2** The applications that host a runtime — Webforge, Webwork and their
  own tools and screens — apart from what they need from this product. (S3;
  S14)
- **O-3** User interface components for platforms other than Flutter. (S4,
  note l)
- **O-4** Transports implemented by a host: the VS Code language-model
  transport and the Copilot chat transport are removed; Copilot is reached
  only through direct calls and its SDK. (S2 § 5, FO-2)
- **O-5** A port of the engine to another language. The runtime is
  TypeScript; other languages get clients. (S1 § 4, § 12.1)
- **O-6** Converging machines: reconciles of the fleet stay a step the user
  starts. The system answers who holds what; it does not pull or merge clones
  on its own, except where the integration step lands a run's own commits.
  (S1 § 10.4; S16)
- **O-7** A file server: tac carries documents while they travel or while a
  process pins them; the record of documents is version control. (S1 § 7.6;
  FO-8)
- **O-8** The earlier agent_container and project_coordination work as input.
  (S4, note m)

### <!--[SCO-LATER]--> 5.3 Deferred to later

Decided as not part of the first version (S1 § 11.1).

| Id | Feature | What defers it |
| --- | --- | --- |
| **L-1** | Todos to the cloud: handing a todo to a vendor's hosted agent, or to a runtime server of our own, and integrating the branch that comes back | CQ-13: sending work out sends source code out; a data policy comes first (S1 § 11.2 … § 11.5) |
| **L-2** | A data policy per quest or repository: which provider may see what | DQ-8: the centrally administered configuration decides for now |
| **L-3** | Asking people outside the team by e-mail, answered on a web page of the tac server | DQ-3: needs the server to send e-mail and a small web client |
| **L-4** | The tac server sending invitation e-mails itself | DQ-2: the owner passes the one-time password on; the protocol does not change |
| **L-5** | Standalone runtimes that outlive their host, to which a client attaches to supervise and detaches again | CQ-4: a runtime ends with its host; the protocol does not prevent the other |
| **L-6** | Pairing of devices and end-to-end encryption between a device and a runtime | CQ-10: mandatory with the relay, once anything is reachable from outside the VPN |
| **L-7** | A review's own git repository on the tac server, for reviewers without repository access | DQ-4: pinned blobs cover reading and returning |
| **L-8** | A server-side runtime for web, phone and tablet clients, which also hosts the web version; such a client reaches tac only through it | WQ-1: in a later wave; until then messaging in Webwork works on the desktop |
| **L-9** | Telegram: one bot token for every runtime, one chat per machine | FO-16 |
| **L-10** | Encryption at rest of messages and blobs | FO-20: an option, its key in Tom Secrets Manager |
| **L-11** | Billing, and customers of several organisations on one server | the server has the records for it (CQ-9) |

## <!--[LAND]--> 6 What exists today

### <!--[LAND-BUILT]--> 6.1 Built

- **E-1** **The engine, inside the VS Code extension**
  (`tom_ai/vscode/tom_vscode_extension`, version 0.1.0). Its feature areas
  (S1 § 2.1, § 3.1; S17):
  - quests, todos (groups, due dates, follow-ups, cross-quest blockers),
    memory, chat variables, roles and role types, templates, profiles;
  - processes with runs: every process runs in a run of its own, with its
    position, variables, queue lane, settings and sessions; nested
    processes, branches, conditions, decision steps, gates with decision
    buttons;
  - the queue: prompt, todo and group items, pre-prompts and follow-ups,
    walks, timed requests, reminders, soft interrupt, done notifications,
    questions that survive a reload;
  - sessions and trails;
  - transports: the direct API, the Claude Agent SDK, a local model, and the
    two host transports that are removed (`SCO > SCO-OUT`, O-4);
  - the `tomAi_*` tools and one MCP server for all of them;
  - team review and the document browser with questions, marks and
    consolidation;
  - the format-version stamp of the `_ai` files and its migration;
  - a JSON-RPC server for scripts, and the Dart client of it,
    `tom_vscode_scripting_api` 5.0.0.
- **E-2** **Todo follow-ups** (the first stage of coordination): a todo names
  what happens when it is done and who filed it; the done notification
  returns to the run and session that queued it; an item or a walk can be
  sent into a named run of another quest on the same machine. The fields for
  claims are in the todo model (`tom_todo_model` 3.1.0) and unused. (S1 § 2.1,
  § 2.2)
- **E-3** **The protocol `tac/1.0`** and **`tom_tac_service` 0.1.0 in local
  mode** (`tom_ai/vscode/tom_tac_service`, a TypeScript package without
  runtime dependencies, 40 tests): presence, sessions, leases with fencing
  tokens, units, messages between runtimes, endpoints, migration and
  administration, over HTTP and WebSocket on the local machine, with a typed
  client. (S5; S1 § 2.1)
- **E-4** **The workspace layout resolver** in the extension
  (`src/utils/workspaceLayout.ts`): root, workspace folder, the `_ai` folder,
  the configuration layers, the guidelines on two levels. (S12; S1 § 2.1,
  § 5.5)
- **E-5** **Merge drivers for the `_ai` files** in TypeScript. (S1 § 2.1)
- **E-6** **Tom Secrets Manager clients:** Dart (`tom_secrets_client` 0.2.11)
  and TypeScript (`@al-the-bear/tom-secrets-client` 0.1.0), and the command
  line `tsm` 0.2.6. (S15)
- **E-7** **The rules for parallel work** as a guideline, most of them by
  agreement. (S16)

### <!--[LAND-MISSING]--> 6.2 Not built

- **E-8** There is no runtime package: nothing of the engine runs outside the
  VS Code extension. (S1 § 2.1)
- **E-9** There is no runtime server and no runtime protocol; no host other
  than the extension can attach. (S1 § 2.1)
- **E-10** There is no Dart runtime client and no client in any other
  language; no Flutter component of the runtime's user interface exists.
  (S1 § 2.1, § 12)
- **E-11** Nothing uses the tac service: the extension holds no reference to
  it, and claims are not taken anywhere. (S1 § 2.1)
- **E-12** tac has no server mode, no GitHub backend, no people, teams, user
  messages or documents; they exist as specification text or decisions only.
  (S5; S1 § 2.2, § 7)
- **E-13** No supervision application exists. (S8)
- **E-14** No quest is a repository of its own, and there is no personal
  repository. (S2 § 3.7)

### <!--[LAND-WAIT]--> 6.3 Who waits for this

| Id | Quest | Waits for |
| --- | --- | --- |
| **E-15** | `webwork` | Team messaging and the review exchange over tac; the AI tab of its bottom panel over a runtime without a quest, with the Dart runtime client and the Flutter components. It works on what needs neither until the runtime is built. (S3; S1 § 7.10; WQ-4) |
| **E-16** | `tom_forge` | Its quest application: the runtime server and protocol, the Dart client, the host interface and host tools, two hosts on one quest, the Flutter components, the view of the coordination. (S14; S1 § 2.3, § 3.3) |
| **E-17** | `al_the_bear` | Running the tac server on its always-on machine, which needs the server; the coordination repository for the GitHub backend; its parallel-work rules becoming enforced. (S1 § 2.2, § 3.4; S16) |
| **E-18** | `tom_specs` | Review copies that travel without the user; its tools and processes running in every host. (S11; S1 § 3.5) |

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
  and profiles. (S1 § 5.1, § 3.1)
- **CR.3** It carries the format-version stamp of the `_ai` files and the
  migration from one format to the next. (S1 § 5.1; `RT > RT-VERSIONS`)
- **CR.4** It keeps a registry of cleanup tasks, so what a feature leaves
  behind (temporary files, stale records) is removed by one mechanism.
  (S1 § 5.1, § 3.1)
- **CR.5** It carries what the engine has today beyond the stores: team review
  rounds on documents, the expression language used in prompts and process
  definitions, prompt assembly from role, quest, memory and guidelines, and
  the features of Claude Code (skills, subagent definitions, slash commands,
  instruction files, hooks, plan mode) on every transport. (S2 § 3.1;
  S1 § 3.1)
- **CR.6** One runtime instance serves one quest. An application's own AI
  that belongs to no quest runs in an instance without a quest. Inside an
  instance, runs and sessions work in parallel. (S1 § 3.2; S3, WR-7;
  S2 § 3.1)
- **CR.7** A runtime instance belongs to exactly one person.
  (S1 § 7.3, DQ-1)

### <!--[RT-RUNS]--> 7.2 Processes and runs

- **CR.8** A **run** is the unit of work in a quest: a process position, its
  variables, a queue lane with its own settings, its sessions (named
  `<session>@<run>`) and a subject that says what the run works on. A quest
  has several runs, and they work in parallel. (S1 § 5.2, § 3.1)
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
  - decision steps and moves that are not linear (back to a step, back to
    the start of a phase);
  - follow-up processes;
  - gates whose result is shown with the buttons of the decision that
    follows;
  - review steps that name the documents under review;
  - steps the user does himself, which the process only asks him to confirm;
  - steps that queue walks over todo groups, with a closing item.
- **CR.11** A process definition can be written and checked through tools,
  and an agent can suggest a subprocess for the running step.
  (S1 § 3.1)
- **CR.12** A run pins the version of its process: it records the revision of
  the process definition it started on, and a changed definition is taken
  over only at a step boundary the user confirms, never in the middle of a
  step. (S1 § 5.2, a proposal; asked in the round's question list)

> **❓ PQ-2 (2026-11-19T09:22+01:00) — A run and a changed process definition:** when the definition of a process is changed while a run of it is in progress, which definition does the run follow?
>
> **Context.** A process is defined in a file every quest shares (its phases, steps, gates and the prompt of each step). A run of that process can last weeks. The concept proposes, without your confirmation so far: "**Proposal — a run pins its process version.** A run records the revision of the process definition it started on; a changed definition is taken at a step boundary the user confirms, never mid-step." The reason it gives is an incident: while one quest was in the middle of a specification process, another running quest changed that shared process definition with the tool that writes processes, and the first run went on under changed steps without anyone deciding it.
>
> **Why I ask.** The Project Idea states this as a capability of the runtime. It decides what a run stores (a pointer to a revision, or a copy of the definition), what the process view shows when the definition has moved on, and whether an improvement to a process reaches the runs that are already under way.
>
> - **(a)** **Pinned, taken over on confirmation.** A run records the revision it started on. When the definition changes, the run goes on as it was; at its next step boundary the user is shown what changed and decides whether this run takes the new definition. A run never changes in the middle of a step.
> - (b) **Pinned for good.** A run always finishes on the definition it started with; only new runs get the new one. Simplest to reason about; a fix to a process never reaches a run in progress.
> - (c) **Not pinned, as today.** Every run always follows the current definition. A change takes effect everywhere at once; a run can find itself at a step that no longer exists.
>
> *Recommendation:* (a) — long runs need fixes to their process, and the confirmation is the point where a person sees what the fix changes for this run.
>
> **Answer:**

- **CR.13** A step declares what must hold before it starts (answered
  questions, a passed gate, documents that exist). The runtime checks this
  and refuses to start the step with the reason, instead of starting it.
  (S1 § 5.2, a proposal; asked in the round's question list)

> **❓ PQ-3 (2026-11-19T09:22+01:00) — Preconditions of a step:** may a process step refuse to start when what it needs is not there?
>
> **Context.** The concept proposes, without your confirmation so far: "**Proposal — step preconditions.** A step declares what must hold before it starts (answered questions, a passed gate, documents present); the runtime checks it and refuses with the reason instead of starting." It comes from a recorded case: a step that works the answers of a question round into a document was started although none of the twelve questions had been answered, and the agent had to notice that itself and ask. Today a step starts whenever the user presses Proceed; only the agent's prompt can find out that something is missing.
>
> **Why I ask.** As a capability it adds a declared part to every process definition and a check to the runtime. The Blueprint needs to know whether preconditions exist at all, and whether they block or only warn.
>
> - **(a)** **Declared and enforced.** A step may declare preconditions from a fixed set (every question of a named document answered; a named gate passed; named documents exist; a named todo group done). The runtime checks them when the step is to start and refuses with the reason. The user can override, and the override is recorded.
> - (b) **Declared, as a warning.** The same declarations, but the runtime only shows what is missing and starts the step anyway when the user confirms.
> - (c) **None.** A step's prompt keeps checking for itself, as today.
>
> *Recommendation:* (a) — a refusal with the reason costs nothing when everything is in place, and it replaces a wasted agent turn when something is missing.
>
> **Answer:**

- **CR.14** A small change can run through a short process (intent, change,
  check), so the full phases are not the only shape of work. (S1 § 5.2,
  § 15.3, a proposal; asked in the round's question list)

> **❓ PQ-4 (2026-11-19T09:22+01:00) — A short path for small changes:** does the product include a short process for a small change, beside the full processes?
>
> **Context.** The concept proposes, without your confirmation so far: "**Proposal — a fast path.** A small change gets a short process (intent, change, check), so the full phases are not the only shape." It took this from the research on how other teams work with specifications: the most frequent criticism of specification-driven work is that the full sequence of documents and gates is too heavy for a small change. Today a small change in this workspace is either a single todo without any process, or a full process run.
>
> **Why I ask.** A process is content, not engine: the runtime runs whatever process a quest names. The question is whether this product delivers such a short process as part of what it ships (as a process definition with its prompts), or whether the Project Idea should say nothing about it and leave it to whoever writes processes.
>
> - (a) **Part of the product.** The runtime ships a short process: state the intent, make the change, check it (the acceptance stated in the intent), with one gate. It is one more process definition; the engine needs nothing new for it.
> - **(b)** **Not part of this product.** The engine carries any process; which processes exist is decided where processes are written. The Project Idea drops the statement.
> - (c) **Not a process but a property of a todo:** a todo carries its acceptance check as fields the working agent cannot edit, and the runtime records the check's result when the todo is completed. Small changes stay single todos, with a recorded check.
>
> *Recommendation:* (b) — it keeps the product to the engine; (c) is worth its own decision when the parallel-work part is settled, because the same recorded check is what the integration step would run.
>
> **Answer:**

### <!--[RT-QUEUE]--> 7.3 The queue

- **CR.15** Every run has a queue. Its items are prompts, todos and groups of
  todos; an item has pre-prompts and follow-ups, a session it runs in and a
  transport it is sent with. Chat is not a separate path: a chat send is a
  queue item, and a session carries one item at a time. (S1 § 5.3, § 3.1;
  S3, WR-7)
- **CR.16** A host sends a prompt into a run's queue in one of three ways:
  at the end, next (before the waiting items), or as an update to the prompt
  that is running. An update that arrives after the running prompt has
  finished is queued next, and the answer says so. (S1 § 5.3, § 3.2; S3,
  WR-7)
- **CR.17** A run has an option, kept by the runtime, for how results are
  taken: *review each result*, where a prompt's changes come back as a
  preview and the queue waits until the host reports that the user applied
  or discarded them; or *work silently*. Changing the option while a result
  waits leaves that result waiting. (S1 § 5.3, § 3.2; S3, WR-7)
- **CR.18** A run can start a new conversation: the next prompt starts
  without the earlier context, and the earlier conversation stays readable
  in the trail. (S1 § 3.2; S3, WR-7)
- **CR.19** The queue walks a group of todos, lowest number first, one
  iteration per todo; it repeats items; it sends timed requests on a schedule
  and reminders after a wait. (S1 § 5.3, § 3.1)
- **CR.20** A running item can be interrupted softly: the update is read at
  the next point where the transport can take it. An item can wait for its
  own background work and for something outside that only time resolves.
  (S1 § 5.3, § 3.1)
- **CR.21** When an item is done, the queue carries out what its todo names
  for completion (unblocking other todos, notifying, queueing) and delivers
  a done notification to the run and session that queued it. (S1 § 5.3,
  § 2.1)
- **CR.22** A todo can name the profile it runs with; the todo's choice wins
  over the item's. (S1 § 3.1)
- **CR.23** A run reports its state as events: working, waiting for a
  decision, failed with a retry possible. Every prompt can be addressed in
  the trail, so a host can show "this prompt" in a run's log. (S1 § 3.2)
- **CR.24** The trail is the durable record of a run. For a prompt that draws
  on a document the host marks as encrypted, the trail is kept in memory
  only. (S1 § 3.2)

### <!--[RT-TRANSPORTS]--> 7.4 Transports

- **CR.25** A prompt reaches a model through a transport, and there are two
  kinds. A **model transport** calls a model's API, and the runtime runs the
  tool loop, the approvals and the retries. An **agent transport** hands the
  prompt to an agent that runs its own loop and reaches the runtime's tools
  through MCP. (S1 § 5.4; S7)
- **CR.26** All transports are the runtime's own. A host implements no
  transport. (S2 § 5, FO-2; `SCO > SCO-OUT`, O-4)
- **CR.27** The model transports carry what the direct transport has today:
  prompt caching, one retry layer, usage and cost per round, continuation of
  a cut-off answer, compaction of history, effort and thinking settings.
  (S2 § 3.1; S1 § 3.1)
- **CR.28** A soft interrupt is held at the points each transport allows.
  (S1 § 3.1)
- **CR.29** The runtime can run in a mode that offers only the agent
  transport of the Claude Agent SDK to a host, without a quest, so an
  application ships one Node payload. (S2 § 3.2)
- **CR.30** The runtime speaks the Agent Client Protocol as a client: one
  adapter reaches every agent that speaks it, and the native transport of an
  agent is kept where the protocol loses features. This comes after the
  native transports. (S1 § 5.4, CQ-5)
- **CR.31** The runtime also answers the Agent Client Protocol as an agent on
  standard input and output, so an editor that speaks it can open a session
  of a quest. It covers chat, updates and permission requests; the queue,
  todos and processes stay in the runtime's own protocol. This comes late.
  (S1 § 6.5, CQ-5)

### <!--[RT-LOCATIONS]--> 7.5 Locations

- **CR.32** The runtime finds every place it needs through one resolver, the
  workspace layout, as it is built in the extension. Outside VS Code the host
  passes the workspace folder and the quest. (S1 § 5.5; S12)
- **CR.33** The resolver answers:
  - the **root**: the nearest folder at or above the workspace folder that
    holds `.tom/tom_root.yaml`; a workspace folder with none above it is
    standalone and its own root;
  - the **`_ai` folder**: the workspace folder's `_ai` as it is opened, else
    the root's; paths are compared by their real path, because the entry is
    a link onto one clone;
  - the **guidelines**: the root's `_agent_guidelines/`, then the workspace
    folder's; a file of the same relative path in the workspace wins;
  - the **quests of a workspace**: those its list
    `_ai/workspaces/<workspace>.yaml` names, else those recorded for the
    folder, else all.

  (S1 § 5.5; S12)
- **CR.34** The repositories of a workspace are those of the file the
  workspace is set up from (`repos.yaml`). (S1 § 5.5, CQ-3)
- **CR.35** A quest lists the repositories and subtrees it usually works on.
  A todo is written with the resources it needs; a todo that names none
  claims the quest's whole list while it runs. (S1 § 5.5, CQ-3, DQ-5;
  `PAR`)

### <!--[RT-CONFIG]--> 7.6 Configuration

- **CS.1** The configuration is layered, later layers winning: built-in
  defaults, the user's own file, the root's `.tom`, the workspace folder's
  `.tom`, the quest's layer (the same on every machine, and one per machine), the
  host's settings. Objects merge deep; arrays and single values replace.
  (S1 § 5.5; S12)
- **CS.2** A write changes one key in one file: it checks that the file has
  not changed since it was read and writes it atomically, so two runtimes
  changing different keys never lose each other's change. (S1 § 5.5; S12)
- **CS.3** The configuration is split by who decides it (S1 § 5.5, DQ-8,
  DQ-11):

  | Part | Holds | Lives |
  | --- | --- | --- |
  | **The repository's** | what belongs to working on code: role types, process definitions, prompt templates | in the repository, under version control |
  | **The team's** | what belongs to the team as an organisation: the providers and their configurations, which providers may be used, the standard profiles | in tac, as the team's configuration, in whichever backend the team uses |
  | **The runtime's** | queue settings, timeouts, compaction, retries; paths, executables and preferences of a machine or host | per runtime, machine or host, in the layers of CS.1 |

- **CS.4** Only a team's owners change the team's configuration. A runtime
  fetches it when it connects, keeps a copy so it starts when it is offline,
  and is told of changes. (S1 § 5.5, DQ-11; `TAC`)
- **CS.5** In the layering, the team's configuration stands above the user's
  own file for the keys the team owns (a person cannot override them) and
  below it for the keys the team only suggests. (S1 § 5.5, DQ-11)
- **CS.6** Which providers a runtime may use is decided by the team's
  configuration. (S1 § 5.5, DQ-8; `SCO > SCO-LATER`, L-2)

### <!--[RT-MACHINE]--> 7.7 Machine-wide state

- **CR.36** Some state belongs to all runtimes of a machine together: queue
  settings per quest and run, the user's configuration, which runtimes and
  runs exist and what they do, the inbox for items sent from one quest to
  another, notifications for the user. (S1 § 5.6)
- **CR.37** The runtime owns this state. A host or a tool never reads or
  writes its files; it asks its runtime. (S1 § 5.6, CQ-2)
- **CR.38** Inside the runtime there is one interface to this state with two
  implementations: through the local tac service, which runs once per machine
  and user and through which every runtime's access is routed, so concurrent
  access is handled in one place; and through files, one key at a time under
  a lock, when coordination is switched off. (S1 § 5.6, CQ-2)
- **CR.39** The local tac service outlives a single runtime and carries the
  state from one to the next. (S1 § 5.6)

### <!--[RT-INSTALL]--> 7.8 Installation and lifetime

- **CR.40** There is one installation of the runtime per machine and user, in
  the application data folder of the operating system, with the provider
  SDKs beside it (S1 § 5.7; S2 § 5, FO-3):

  | System | Runtime | Provider SDKs |
  | --- | --- | --- |
  | macOS | `~/Library/Application Support/Tom/runtime/` | `~/Library/Application Support/Tom/providers/` |
  | Linux | `~/.local/share/tom/runtime/` | `~/.local/share/tom/providers/` |
  | Windows | `%LOCALAPPDATA%\Tom\runtime\` | `%LOCALAPPDATA%\Tom\providers\` |

- **CR.41** Versions are installed side by side, each in a folder of its
  own, with a pointer `current` to the newest. A running runtime keeps its
  version until it is restarted. (S1 § 5.7; S2 § 5, FO-4)
- **CR.42** Every host carries the runtime version it was built with,
  installs it into the shared location when that version is not there yet,
  and starts that version. Hosts on one machine thereby share installations.
  (S1 § 5.7, DQ-9)
- **CR.43** Provider SDKs are installed on request, when a profile first
  needs one. (S2 § 3.2; S1 § 3.1)
- **CR.44** A runtime is started by its host and ends with it. A long walk
  needs its host open. (S1 § 5.7, CQ-4; `SCO > SCO-LATER`, L-5)
- **CR.45** Inside a running runtime, a run is unloaded when its last
  subscriber has gone and nothing is queued in it. (S1 § 6.1, a proposal;
  asked in the round's question list)

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
- **CS.9** The runtime is paired with the Tom Secrets Manager service once:
  it is approved there as a program of its own. A setup guide describes the
  pairing. (S1 § 5.8, CQ-16; S15)
- **CS.10** When the vault is locked, the queue item that needs the secret
  waits and the user is asked to unlock. (S1 § 5.8, CQ-16; S15)
- **CS.11** Besides provider keys, the team tokens of a person are kept as
  secrets in the same way. (S1 § 5.8; `TAC`)

### <!--[RT-PROTO]--> 7.10 The protocol

- **CP.1** A host outside the runtime's own process attaches over the runtime
  protocol: JSON-RPC 2.0 with length-prefixed messages over a TCP connection
  on the local machine; a remote client attaches over WebSocket. Inside VS
  Code the extension calls the runtime directly, with the same commands.
  (S1 § 6.1; S2 § 5, FO-5)
- **CP.2** A runtime started as a process of its own prints a ready line
  when it accepts connections, ends when its standard input is closed, and
  writes its log to standard error. (S2 § 3.2; S14)
- **CP.3** The protocol has **commands** from the host to the runtime. They
  cover everything the engine does: the queue and timed requests; processes
  (proceed, skip, back, decide, subprocesses, runs); sessions; todos;
  memory; templates; profiles; chat variables; review rounds; coordination;
  calling a tool. (S1 § 6.1; S2 § 3.2)
- **CP.4** The protocol has **events** from the runtime to its clients, one
  stream with subscriptions per connection. An event is one thing the
  runtime tells: a piece of streamed answer text or reasoning, a tool call
  and its result, a queue item changing state, the process position moving,
  an ask opened or answered, a todo changing status, the usage of a round, a
  trail entry. (S1 § 6.1, CQ-6)
- **CP.5** The events of a run are numbered. A client reads "after number N,
  then follow". That serves a client that reconnects, a second client on the
  same run, and a client that attaches late. (S1 § 6.1, CQ-6)
- **CP.6** The numbered events are kept in memory with a bound. A client
  further behind than the bound reloads the run from the trail files, which
  stay the durable record. (S1 § 6.1, CQ-6)
- **CP.7** A conversation is modelled as thread, turn and item: a session
  holds turns, a turn holds items (text, reasoning, tool call, ask, result),
  and an item has started, delta and completed events. A turn can be steered
  and interrupted. (S1 § 6.1, a proposal; asked in the round's question
  list)
- **CP.8** Every question the runtime puts to a person has one form, the
  **ask envelope**: a stable id, a kind (question, pick, document, tool
  approval, plan, decision, gate), the allowed responses, an optional schema
  of the response, a declared default and a deadline. (S1 § 6.1, a
  proposal; asked in the round's question list)

> **❓ PQ-5 (2026-11-19T09:22+01:00) — The shape of the protocol's conversation and questions:** do you confirm the three shapes the concept proposes for the protocol?
>
> **Context.** Decided so far: the wire (JSON-RPC over a local TCP connection, WebSocket for remote clients), commands, numbered events per run kept in memory with a bound, reverse requests, a published JSON schema, and that a pending question is a stored record that can travel to another person. The concept's section on the protocol lists further points under "Proposals from what others built", which you have not confirmed one by one:
> - "**Thread, turn, item.** The chat model follows the lifecycle others converged on: a session holds turns, a turn holds items (text, reasoning, tool call, ask, result) with started, delta and completed events; a turn can be steered and interrupted."
> - "**One ask envelope** for every question the runtime puts to a person: a stable id, a kind (question, pick, document, tool approval, plan, decision, gate), the allowed responses, an optional response schema, a declared default, a deadline."
> - "**Subscriptions per connection**, and a run unloads when its last subscriber has gone and nothing is queued."
>
> Today the extension has one shape per kind of question (a question panel, a picker, a document with buttons, a tool-approval bar, a plan approval, a process decision), and its chat stream is a sequence of live-trail calls (text, thinking, tool call, tool result) without the turn and item levels.
>
> **Why I ask.** These three are the backbone of the protocol and of every client and component built on it: the conversation component draws items, the ask inbox draws envelopes, and the supervision application depends on a run staying loaded while it watches. Changing them later changes all nine clients.
>
> - **(a)** **All three as proposed.** One conversation model (thread, turn, item), one envelope for every kind of question, and a run stays loaded as long as someone is subscribed or something is queued.
> - (b) **The envelope and the unloading, but the chat stream as it is today** (a flat sequence of trail events). Less to change in the engine; the conversation component has to rebuild turns and items from the flat stream itself, in every language.
> - (c) **Different** — say which of the three, and how.
>
> *Recommendation:* (a) — the same three shapes are what the other agent protocols settled on, so adapters to them stay thin.
>
> **Answer:**

- **CP.9** An ask outlives the process that asked: a pending ask is a stored
  record, the turn can end, and the run resumes when the answer arrives.
  That is what lets an ask travel to another device or person.
  (S1 § 6.1, CQ-7)
- **CP.10** The protocol has **reverse requests** from the runtime to the
  host: the asks, notifications, opening a file or a document, and the
  host's tools. (S1 § 6.1, § 6.2)
- **CP.11** The protocol is published as a JSON schema in the runtime's
  package. The client packages generate their protocol layer from it and are
  checked against it. (S1 § 6.1; S2 § 5, FO-10)
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
- **CP.14** In VS Code the interface is implemented in the extension's
  process; in every other host it is carried by the protocol's reverse
  requests. (S1 § 6.2)
- **CP.15** A host refuses a call it has no concept for, with a reason, and
  the runtime leaves out what depends on it. (S1 § 6.2; S2 § 3.1)

### <!--[RT-TOOLS]--> 7.12 Tools

- **CT.1** There are three sets of tools, by where they can live (S1 § 6.3;
  S2 § 5, FO-17):

  | Set | Carried out by | Holds | Offered to |
  | --- | --- | --- | --- |
  | **Runtime tools on `_ai`** | the runtime | todos, queue, processes, sessions, memory, chat variables, review, coordination, messaging, the specification tools and the runner of the TomSpecs binary | every transport, and through the runtime's MCP server also other runtimes |
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
  calls the host back over the protocol when the model calls it. The host
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
- **CT.9** The role a prompt runs in decides which tools it gets: a role type
  names its tools. (S1 § 6.3, § 3.1)
- **CT.10** The tool set grows with the products that run in the runtime.
  TomSpecs adds tools for keeping linked sections of specification documents
  in step and switches for rendering a document for reading; its documents
  are worked on through one bundled binary, and a missing binary is reported
  as such. (S1 § 3.5)

### <!--[RT-MCP]--> 7.13 The MCP servers

- **CT.11** The runtime has an MCP server that offers the runtime tools on
  `_ai`. It reads and writes only `_ai` state and offers no access to files
  or an editor, so it is safe to offer to other machines. (S1 § 6.4; S4,
  first notes)
- **CT.12** The server asks for a bearer token. (S1 § 6.4, § 3.6)
- **CT.13** A runtime can publish its MCP server as an endpoint through tac,
  so other runtimes of its agent group find it and call its tools.
  (S1 § 6.4; `TAC`)
- **CT.14** Inside a runtime, the tools of the local runtime, of the host and
  of a remote runtime are all presented to the model as tools; routing a
  call to the right place is part of carrying the tool out. (S4, note e;
  S2 § 3.3)
- **CT.15** The runtime names the revision of MCP it speaks, and keeps what
  differs between revisions (long-running tasks) behind an adapter.
  (S1 § 6.4, § 15.1)
- **CT.16** The runtime is also a client of external MCP servers, as the
  engine is today. (S1 § 6.4, § 3.1)

### <!--[RT-ASKS]--> 7.14 Routing and escalation of asks

An ask must not get lost, and it must not hold a process up for long
(S1 § 6.6, CQ-7).

- **CP.16** Every quest has an owner. (S1 § 6.6, CQ-7)
- **CP.17** An ask has a chain of people: the person the process or the todo
  names, if any; then the owner of the quest the ask belongs to; then the
  owner of the quest whose todo triggered it; then the owners of the team.
  (S1 § 6.6, CQ-7, DQ-3)
- **CP.18** For each person in the chain: the ask is shown on the host that
  asked; after 10 minutes without an active client there it goes through tac
  to that person's other devices; after a set time without an answer it
  moves on to the next person, and the previous one keeps seeing it. The set
  time is 4 working hours unless the team or the ask says otherwise.
  (S1 § 6.6, DQ-3)
- **CP.19** An ask goes to another person only when the process or the todo
  names that person, or by the chain. (S1 § 6.6, CQ-7)
- **CP.20** At the end of the chain the ask stays open and is marked
  unanswered. Nothing is decided automatically, unless the ask declared a
  default; then the default is taken and recorded as taken by default.
  (S1 § 6.6, DQ-3)
- **CP.21** While an ask waits, the run that asked waits; the other runs and
  the rest of the queue go on, and a walk goes on with the next todo that
  does not depend on the waiting one. (S1 § 6.6, DQ-3)
- **CP.22** Whoever has an ask can forward it to any member of the team, with
  a note. The chain continues from that person, and the answer returns to
  the run that asked. (S1 § 6.6, CQ-7, DQ-3)
- **CP.23** Every open ask of a team can be seen with its age, who has it and
  where it is in its chain. (S1 § 6.6, CQ-7)

Asking a person outside the team is deferred (`SCO > SCO-LATER`, L-3).

### <!--[RT-VERSIONS]--> 7.15 Versions and compatibility

A runtime update often comes with a new format of the workspace and quest
files, and an older runtime does not work on newer files (S1 § 6.7, DQ-9).

- **CP.24** On connect, three versions are checked: the protocol's, the
  runtime's, and the format of the workspace files. (S1 § 6.7, DQ-9)
- **CP.25** An older client keeps working with a newer runtime. It does not
  get the new features, and nothing it does breaks. Within a major version
  the protocol only grows: commands and fields are added, none changed or
  removed. (S1 § 6.7, DQ-9)
- **CP.26** Unknown fields pass through. A client that reads a record,
  changes a field and writes the record back returns every field it did not
  know unchanged. Every client package does this. (S1 § 6.7, DQ-9)
- **CP.27** A client package tells its host through callbacks when the
  runtime was updated, when the workspace files were migrated to a format
  the host's runtime cannot work on, and when the host is too old for the
  runtime it found. The host decides what to show and do. (S1 § 6.7, DQ-9)
- **CP.28** A runtime that finds workspace files in a newer format than it
  knows stops working on them. (S1 § 6.7, DQ-9)
- **CP.29** A migration of the workspace files runs once per machine, under
  a lock; the other runtimes on the machine pause while it runs. (S1 § 6.7,
  § 3.1)

> **❓ PQ-6 (2026-11-19T09:22+01:00) — Migrating the workspace files:** who decides that the files of a workspace are migrated to a new format, when not every runtime that works on them is updated yet?
>
> **Context.** Decided: every host installs the runtime version it was built with; versions exist side by side; three versions are checked on connect; an older client keeps working with a newer runtime; "a runtime update often comes with an update of the workspace/quest files and older runtime don't run on them"; a client library tells its host through callbacks when the files were migrated to a format its runtime cannot work on, and that runtime then stops working on them. Today the extension migrates the `_ai` files when a newer build first opens them, once per machine under a lock, and other windows on the machine pause meanwhile.
>
> What the sources do not say is what happens **between** hosts and machines. Two cases:
> - On one machine, Webforge was updated and brings a runtime with a newer format; the VS Code extension on the same machine is still the older one, working on the same quest files.
> - The quest files are shared through git. One team member's updated runtime migrates them and commits; after the next pull, every colleague whose runtime is older stops working on that quest until they update.
>
> **Why I ask.** With one person and one host, migrating at first sight was harmless. With several hosts and a team, an automatic migration by whoever updates first stops everyone else's work without warning. The Blueprint needs the rule.
>
> - **(a)** **A migration is a decision, asked once.** A newer runtime that finds files in an older format works on them in the older format as long as it can (it keeps the ability to read and write the previous format), and offers the migration. The migration runs when the quest's owner (or on a single-user workspace, the user) confirms it; the confirmation shows which runtimes known to the coordination service are still on an older version and would stop.
> - (b) **Automatic, as today.** The first newer runtime migrates. The others stop with the callback and a message naming the version to install. Simple; whoever updates first decides for all.
> - (c) **Never while an older runtime is present.** The newer runtime refuses to migrate while the coordination service lists an older runtime on the same quest or workspace, and works in the old format until then.
>
> *Recommendation:* (a) — it needs the runtime to support one format back, which is also what makes "an old client keeps working" hold for the files and not only for the protocol.
>
> **Answer:**

- **CP.30** The aim is that the protocol and the formats become very stable
  after a while. (S1 § 6.7, DQ-9)

### <!--[RT-PROVIDERS]--> 7.16 Model providers

- **CS.12** A provider is reached in one of three ways (S7; S1 § 5.4):

  | Way in | How | Providers |
  | --- | --- | --- |
  | **The provider's agent** | an agent transport of its own | GitHub Copilot (its SDK), OpenAI (the Codex SDK), Google (the Gemini command line), Mistral (its coding agent) |
  | **An endpoint compatible with Anthropic's API** | the direct transport and the Claude Agent SDK transport with a base address | DeepSeek, OpenRouter, Moonshot, Zhipu, MiniMax; Claude on Amazon Bedrock and Google Vertex AI |
  | **An endpoint compatible with OpenAI's API** | the client for local models grown into a provider client | xAI, Meta's Llama API, DeepSeek, Baidu, Mistral, OpenRouter, Alibaba, Groq, Together, Fireworks, Cerebras, Azure OpenAI |

- **CS.13** GitHub Copilot is reached only through direct calls and its SDK.
  (S2 § 5, FO-2)
- **CS.14** A provider configuration carries its endpoint, the models it
  offers (read from the provider where it lists them), and its prices, so
  usage and cost are shown per provider. (S7; S2 § 3.8)
- **CS.15** One conformance table checks every provider configuration: a
  prompt, a tool call, streaming, usage. (S2 § 3.8; S7)
- **CS.16** Two agent libraries are evaluated behind the transport
  interface, one as a model transport and one as an agent transport, before
  it is decided whether the runtime takes them. (S1 § 5.4; S2 § 3.8)
- **CS.17** A new transport maps its stream onto the runtime's events (text,
  reasoning, tool call, tool result, retry, notice, usage), bridges the
  runtime's tools, routes approvals, and returns the answer, with a session
  id where the agent owns the conversation. (S7)
- **CS.18** The providers beyond today's transports are built in the
  runtime, after the transports have moved into it; none is built in the
  extension first. (S2 § 3.8; S7)

## <!--[CLI]--> 8 Client packages, UI components and supervision

### <!--[CLI-PACK]--> 8.1 The client packages

- **CL.1** There are client packages for nine languages: Dart, TypeScript,
  JavaScript, Python, Java, Go, Rust, C and C++. (S1 § 12.1; S4, note k)

> **❓ PQ-7 (2026-11-19T09:22+01:00) — Which languages come first:** which of the nine languages' client packages are part of the first delivery?
>
> **Context.** Decided: client packages for nine languages (Dart, TypeScript, JavaScript, Python, Java, Go, Rust, C, C++), each with a runtime client and a tac client; the protocol layer generated from the schema, the convenience layer written by hand per language, one conformance suite; "we will only thoroughly test Dart and JS/TS, as we need those for the two platforms with building". Who needs which: the Flutter applications (Webwork, Tom Forge, the supervision application) need Dart; the VS Code extension and the tac service are TypeScript. No source names a user of the other six yet.
>
> **Why I ask.** Eighteen packages (two per language) are a large part of the work if all are in the first delivery, and each convenience layer is hand-written. The delivery plan and the size of the conformance suite depend on it.
>
> - **(a)** **Dart and TypeScript / JavaScript first; the others follow once the protocol is stable.** The first delivery has the two tested clients, the schema, the generator for the protocol layer and the conformance suite, built so that a further language is added by generating its protocol layer and writing its convenience layer. The other six follow as a later step.
> - (b) **All nine in the first delivery**, the other six with the generated protocol layer and a minimal convenience layer, checked by the conformance suite only.
> - (c) **Dart and TypeScript / JavaScript now, the others only when someone needs one.** No date for the other six; each is added on request.
>
> *Recommendation:* (a) — the protocol will still move while the first hosts are built, and every language added before it settles multiplies each change.
>
> **Answer:**

- **CL.2** In every language there are two clients, each in a package of its
  own: the **runtime client**, which speaks the runtime protocol, and the
  **tac client**, which speaks TAC. The runtime client depends on the tac
  client. (S1 § 12.1, CQ-15)
- **CL.3** The places (S1 § 12.1; S2 § 5, FO-11):

  | Package | Place |
  | --- | --- |
  | The Dart runtime client | `tom_ai/ai_build/tom_ai_runtime_client` |
  | The Dart tac client | `tom_ai/ai_build/tom_tac_client` |
  | The clients of the other eight languages | `tom_ai/ai_build/tom_ai_runtime_nondart/<language>/` |

- **CL.4** A client has two layers. The **protocol layer** is generated from
  the protocol's JSON schema. The **convenience layer** is written by hand
  in each language and is the same in every language. (S1 § 12.1; S2 § 5,
  FO-10)
- **CL.5** The convenience layer of the runtime client: find or start the
  installed runtime, connect, subscribe to events, queue a prompt, walk a
  group of todos, answer an ask, register the host's tools. That of the tac
  client: connect, send a message, send documents for review, receive.
  (S1 § 12.1)
- **CL.6** One conformance suite checks every client in every language
  against a running runtime and a running tac service. It includes the
  pass-through of unknown fields (CP.26). (S1 § 12.1, § 6.7)
- **CL.7** The Dart and the TypeScript and JavaScript clients are tested
  thoroughly, beyond the conformance suite; they are the clients of the
  platforms the product itself is built on. (S1 § 12.1; S4, note k)
- **CL.8** A client carries the version checks and the upgrade callbacks of
  `RT > RT-VERSIONS`. (S1 § 6.7, DQ-9)
- **CL.9** The Dart runtime client has no dependency on Flutter. (S1 § 3.3)
- **CL.10** The Dart runtime client grows out of today's Dart client of the
  extension's script server: its wire layer, its feature APIs and its mirror
  of the Claude Agent SDK. Scripts that use that client keep working against
  a VS Code window and against a runtime. (S2 § 3.5; S1 § 2.1)
- **CL.11** An application reaches tac through its runtime. The tac client is
  used by runtimes, servers and tools. An application in a browser, on a
  phone or on a tablet uses the runtime client against a runtime on a server.
  (S1 § 12.1, § 7.3, WQ-1; `SCO > SCO-LATER`, L-8)

### <!--[CLI-UI]--> 8.2 The Flutter UI components

- **CU.1** `tom_ai/ai_build/tom_ai_runtime_ui` holds every reusable
  component of the runtime's user interface, for Flutter, over the Dart
  runtime client. (S1 § 12.2; S2 § 5, FO-11; CQ-14)
- **CU.2** The components take their look from the host through theme
  parameters. (S1 § 12.2, § 3.2)
- **CU.3** The package depends on nothing of Tom Forge. Tom Forge's own view
  package is built on top of it and keeps only what binds the components
  into the Forge shell. (S1 § 12.2, CQ-14)
- **CU.4** The components build for desktop, web, iOS and Android.
  (S1 § 12.2)
- **CU.5** The basis of each component is what the extension shows today.
  The components' names follow the ones the web component kits for agent
  work have settled on, since no Flutter kit covers agent work. (S1 § 12.2,
  § 15.5)
- **CU.6** The component groups (S1 § 12.2):

  | Group | Components | Starts from |
  | --- | --- | --- |
  | **Conversation** | conversation, message, prompt input with the three send choices, attachments, reasoning, tool card, context and usage, model and profile selector | the chat panel |
  | **Asks** | question, pick, confirmation of a tool call, plan approval, decision, gate result with its buttons, document ask; the ask inbox | the ask panels, plan mode, the document asks |
  | **Queue** | queue list (waiting, running, done; reorder, edit, remove), item editor, timed requests, templates | the queue editor |
  | **Runs and processes** | run tabs with state marks, process view (phases, steps, proceed, decide, skip, back), branching, runs overview | the process view, the runs overview |
  | **Todos** | todo list and tree, todo editor, decisions, session todos, todo log, the panel across quests | the todo panels |
  | **Trail** | live trail, summary trail, a bounded Markdown view that only appends | the trail viewers, the output channels |
  | **Sessions and memory** | sessions, memory, chat variables, notes, personal notes | the sessions view, the editors |
  | **Messaging** | conversation list, conversation, composer, document card, review request card, reminder, people | new; from tac |
  | **Review** | the review component for Markdown documents: questions and answers, comments, marks, team chips, votes, conflicts, consolidation | the document browser |
  | **Supervision** | runtime list, what waits, notifications, the coordination page (claims, leases, the integration queue), status of the machine's runtimes | the window status and notifications views; new |
  | **Settings** | profiles, providers and keys, coordination, team administration, what the extension's status page holds | the status page |

> **❓ PQ-8 (2026-11-19T09:21+01:00) — Which components are built first:** in which order are the component groups of the Flutter library built?
>
> **Context.** Decided: every reusable component lives in one Flutter package; the description work covers the extension's screens completely before building ("We will completely specify what can be specified now"); the product is built in two tracks in parallel, one for the coordination service and one for the runtime. The package has eleven groups: conversation; asks; queue; runs and processes; todos; trail; sessions and memory; messaging; review; supervision; settings. Who waits for which: Webwork's AI tab needs conversation, queue and trail (and the bounded Markdown view); Tom Forge's quest application needs nearly all of them; the supervision application needs asks, runs, queue and supervision; messaging and review need the coordination service's messaging and documents, which the other track builds.
>
> **Why I ask.** The descriptions are complete before building, but the building has an order, and the delivery plan in the Blueprint needs it. It also decides which host can be tried first.
>
> - **(a)** **By who waits.** 1. conversation, queue, trail; 2. asks and the ask inbox; 3. runs and processes; 4. todos; 5. sessions, memory, settings; 6. review; 7. messaging; 8. supervision. The first step is enough for Webwork's AI tab, the first four for a usable quest application.
> - (b) **Messaging and review early**, right after the first step, so that the coordination track has a user interface to be tried with as soon as it has messages and documents.
> - (c) **No fixed order**; each group is built when the host that needs it is being built.
>
> *Recommendation:* (a), with the gallery application built together with the first step, so every later group has a place to be shown.
>
> **Answer:**

- **CU.7** The bounded Markdown view keeps the last so-many lines or
  kilobytes and forgets the rest; it follows its end. It serves a run's log
  and a host's own log channels. (S1 § 3.2; S3, WR-7)
- **CU.8** The trail components show streamed text, reasoning, tool cards,
  the summary of a prompt, and the marks of a prompt that waits for the
  user to apply or discard its result. (S1 § 3.2)
- **CU.9** The review component for Markdown documents is one Flutter
  component, shared by Webwork, Tom Forge's quest application and trc.
  (S1 § 3.3; S11)

### <!--[CLI-SCREENS]--> 8.3 Screen and component descriptions

The design is delivered as descriptions and running code, not as drawings
(S1 § 12.3, CQ-18, DQ-7).

- **CU.10** There is a complete inventory of the extension's screens: every
  view, panel and editor, and for each one what it becomes here.
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
  the client. (S1 § 12.3, CQ-18)
- **CU.13** Everything that can be described now is described completely.
  The extension keeps changing, and the descriptions are amended as it does.
  (S1 § 12.3, DQ-7)
- **CU.14** `tom_ai_runtime_ui` contains a gallery application that shows
  every component with made-up data. It is the living design and the place
  the components are tried. (S1 § 12.3, CQ-18)
- **CU.15** The screens built from the components exist in three widths: a
  desktop panel, a narrow side panel, a phone. They are: the AI panel
  (conversation, queue and trail, switchable or side by side); process and
  runs; todos; the ask inbox with its escalation; messaging; the review
  editor and the consolidation view; supervision (the overview of a group
  of runtimes, the detail of a runtime); the coordination page; settings and team
  administration. (S1 § 12.3)

The inventory as it stands. ___check here___ The outcomes are a first pass
from the names of the extension's views and handlers, not yet from their code;
each is decided when the screen is described. (S1 § 12.3; S17)

| Extension screen | Outcome (first pass) | Component group |
| --- | --- | --- |
| The chat panel | reused | conversation |
| The bars for a question, a pick, a tool approval and a plan approval | reused | asks |
| The panel of open interactions, user notifications | starting point (the ask inbox) | asks |
| Queue editor, queue entry, queue templates | reused | queue |
| Timed requests editor | reused | queue |
| Process view, process branching | reused | runs and processes |
| Process editor, process template editor | starting point | runs and processes |
| Runs overview | reused | runs and processes |
| Quest todos, session todos, workspace todos, the todo panel | reused | todos |
| Quest todo editor | reused | todos |
| Todo log | reused | todos |
| Trail viewer, trail editor, quest logs | reused | trail |
| Output channels | starting point (the bounded Markdown view) | trail |
| Sessions view, session pickers | reused | sessions and memory |
| Memory panel, chat variables editor | reused | sessions and memory |
| Quest notes, workspace notes | reused | sessions and memory |
| VS Code notes | host's own | — |
| The document browser, with questions, marks, team review, consolidation | starting point (the review component) | review |
| Window status | starting point (the list of a team's runtimes) | supervision |
| Notifications | reused | supervision |
| Status page | split (providers, profiles, coordination, diagnostics each on their own) | settings; supervision |
| Editors for prompt templates and reusable prompts | reused | settings |
| Roles editor | reused | settings |
| The workspace panel (guidelines, documents, logs) | starting point | partly host's own |
| Resources, prerequisites, the issues panel, the test panels | host's own | — |
| Reload overlay, migration screens | starting point (the version callbacks) | settings |
| — messaging: conversations, composer, document and review cards | new | messaging |
| — the coordination page: claims, leases, the integration queue | new | supervision |
| — team administration: members, invitations, devices | new | settings |

### <!--[CLI-TRC]--> 8.4 The supervision application (trc)

- **CK.1** trc shows every runtime of a team in one view: what each runtime
  does, and what waits — questions, todos that need a decision, the state of
  the queues, runs, errors, claims, messages. (S8; S1 § 12.4; S2 § 3.6)
- **CK.2** trc is a full remote control: more or less everything a runtime
  can do can be done through it. It queues todos and walks, starts and
  pauses runs and queues, continues processes (proceed, decide, gates),
  answers asks, and lets the user review documents with the review
  component; the result goes back to the run that asked. (S2 § 3.6,
  FO-12; S8)
- **CK.3** Its focus is supervising a group of runtimes, not development work
  on one machine. What it adds to the components it is built from is the overview.
  (S2 § 3.6, FO-12; S1 § 12.4)
- **CK.4** A person supervises their own runtimes, or a part of a team's.
  (S8; S2 § 3.6)
- **CK.5** Remote control is possible only inside a team, and only for a
  runtime whose host allows it by a setting. (S1 § 7.3, CQ-10)
- **CK.6** trc is built from the Dart runtime client and the Flutter
  components. (S1 § 12.4; S2 § 3.6)
- **CK.7** trc is a Webforge application from the start, beside Webwork, the
  quest application and the core Forge application. It also runs standalone,
  outside Tom Forge, first and for testing; it may depend on packages of Tom
  Forge. (S2 § 5, FO-12)
- **CK.8** trc finds the runtimes of a team through tac, by the endpoints
  they publish, and attaches to each runtime's numbered events.
  (S1 § 9, flow F10; S2 § 3.6)

> **❓ PQ-9 (2026-11-19T09:21+01:00) — How the supervision application connects, and where it runs:** does the supervision application have a runtime of its own, and on which platforms does it run in the first version?
>
> **Context.** Decided: the supervision application is "a Webforge application from the start which run standalone, too, outside tom_forge"; it shows every runtime of a team and controls them; remote control works only inside a team and where a runtime's host allows it. Also decided: an application reaches the coordination service only **through a runtime** — a browser, phone or tablet client through a runtime on a server, which comes in a later wave. And your original idea: "our own remote control mobile app […] so I can see all questions, decision-needed, queue-state, errors in a nicely structure app".
>
> These fit together only with one more rule. The supervision application talks to many runtimes (it attaches to each one's events), but to find them and to see a team's open questions it needs the coordination service — and it has no quest of its own.
>
> **Why I ask.** It decides what the supervision application is made of, and whether the phone, the device the idea started from, is in the first version.
>
> - **(a)** **Desktop first, with a runtime of its own without a quest.** On the desktop (inside Webforge or standalone) the supervision application starts a runtime instance that serves no quest, as Webwork's own AI does. Through it, it reaches the coordination service, finds the team's runtimes and attaches to them. The phone and the tablet follow with the server-side runtime, in the later wave.
> - (b) **The same, and the phone in the first version**, which pulls the server-side runtime for phone clients forward into the first version, for this application only.
> - (c) **The supervision application is the one exception:** it may use the coordination service's client directly, without a runtime, on every platform. It is then the only application that does, and the rule "always through a runtime" has an exception to specify and secure.
>
> *Recommendation:* (a) — it keeps one rule for every application, and outside the VPN a phone needs the relay with device pairing anyway, which is also later.
>
> **Answer:**

- **CK.9** The open asks of a team, with their age and their place in the
  chain (CP.23), are part of trc's view. (S1 § 6.6)

Reaching runtimes from outside the VPN needs the relay, and with it the
pairing of devices and end-to-end encryption, which are deferred
(`SCO > SCO-LATER`, L-6).

## <!--[TAC]--> 9 Coordination and messaging (tac)

tac is one service with two jobs: it lets runtimes find each other and keep
out of each other's way, and it carries what people who work with those
runtimes send each other. Its protocol is TAC. What is built is `tac/1.0` in
local mode (`LAND > LAND-BUILT`, E-3); this section states what tac is to be.

### <!--[TAC-JOBS]--> 9.1 Two jobs, one service

| Job | For | Area |
| --- | --- | --- |
| **Coordination** | runtimes: presence, discovery, sessions, leases, units, messages between runtimes, endpoints | `CA` |
| **Messaging** | people, and runtimes acting for them: conversations, messages of several kinds, documents, reminders | `CM`, `CV` |

- **CA.1** Both jobs are done by one service. They share the identities, the
  transport, the store and the server. (S1 § 7.1)
- **CA.2** Coordination happens in an **agent group**: the runtimes whose
  workspaces name the same backend and group id. Messaging happens in a
  **team** (`TAC > TAC-PEOPLE`). (S5 § 3.2; S1 § 7.3, DQ-1)

___check here___ S1 § 7.1 still says "A team is one agent group"; S1 § 7.3
(DQ-1) decides that they are two things. This section follows DQ-1; how a
team, an agent group and a customer are tied to each other is asked
(`new_questions.md`, section `TAC-PEOPLE`). — `agent_spec_author`

### <!--[TAC-COORD]--> 9.2 Coordination between runtimes

**Presence and discovery**

- **CA.3** A runtime registers with its agent group: its id, its kind, its
  machine, its workspace, the quests it serves (none for a runtime without a
  quest), the repositories it coordinates with the state of their clones,
  and the person it belongs to. (S5 § 3.3; S1 § 7.3)
- **CA.4** A runtime is present while it holds its connection to the
  service. The service computes presence; no client writes it. (S5 § 3.3,
  § 5.2)
- **CA.5** A runtime keeps its current state with its registration — per
  quest and run the process position, the number of open asks, of queue
  items needing attention and of reviews waiting, and the state of its queue
  — so a client that connects late shows the right picture at once.
  (S5 § 3.3)
- **CA.6** Any runtime of the agent group can list the agent group's runtimes with their
  presence and state. One quest may have several runtimes. (S5 § 3.3, § 5.2)
- **CA.7** Runtimes find each other through tac and nowhere else: on one
  machine, across the VPN, and through the relay beyond it. (S2 § 3.4;
  S4, note c)

**Sessions**

- **CA.8** A lease belongs to a session, identified by quest, session, run,
  machine and workspace. The identity outlives the runtime process: after a
  restart or a window reload the new process re-attaches to its session and
  finds its leases unchanged. (S5 § 3.4, § 4.3)

**Leases, units and fencing tokens**

- **CA.9** A lease is held on resource keys of four kinds: a whole
  repository; a unit, which is a declared path inside a repository; a
  declared infrastructure resource (something that is not a set of files in
  one repository, such as publishing a package or a release asset); a folder
  of the `_ai` state. (S5 § 3.5 … § 3.7; S6, part-claims)
- **CA.10** A repository is named by its identity (provider, owner, name),
  never by a path on a machine, so the same repository is the same resource
  on every machine. (S5 § 3.5)
- **CA.11** Two keys conflict when they name the same repository and one is
  the whole repository, when they name units of one repository and one
  unit's path contains the other's, or when they are the same infrastructure
  or `_ai` key. A unit can declare shared paths that conflict with nothing.
  Keys conflict only within one agent group. (S5 § 3.5, § 3.7)
- **CA.12** A session acquires all the resources it asks for or none. When
  one is held, the answer names the holders. (S5 § 4.1, § 6.2; S6,
  part-claims)
- **CA.13** A lease is renewed while its session works. Not renewed for 60
  minutes, it is **stale**. A stale lease is only shown: no service and no
  client takes it over, and only a person frees it. Its resources stay held
  until then. (S5 § 4.1, § 4.2; S6, BP-11)
- **CA.14** Every grant of a resource carries a **fencing token**, a number
  that only grows per resource. Freeing a lease raises the tokens of its
  resources. A holder whose lease was freed finds out at its next check, and
  a write it still attempts with its old token is refused. (S5 § 3.8, § 4.2)
- **CA.15** Times that decide about leases and presence are the service's
  clock, never a client's, so a machine with a wrong clock can neither keep
  a lease fresh nor make one go stale. (S5 § 4.4)
- **CA.16** Units and infrastructure resources are declared in the agent
  group's data and can be changed while the group works. (S5 § 3.6, § 3.7;
  S6, BP-9)
- **CA.17** Todo state and journals are not claimed: todo files, the files
  of questions, decisions and progress, the session history and the process
  state are written by many sessions at once, by design. A todo claims an
  `_ai` folder only when it names one. (S6, part-claims)

**Messages between runtimes**

- **CA.18** A runtime sends a message to all quests of its agent group or to named
  quests. The service routes by the target and never reads the type or the
  payload; the meaning of a type is the clients' convention. (S5 § 3.9;
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
- **CA.21** What a todo names for its completion in another quest, or in
  another run, travels as a command to that quest's runtime. (S6,
  part-messages; S1 § 7.4)
- **CA.22** A client shows a type it does not know by the one-line summary
  every payload carries, so a new type never breaks an older client. (S6,
  part-messages)

**Endpoints**

- **CA.23** A runtime publishes the endpoints it serves — its MCP server,
  its remote control — with the address, where the address can be reached
  from (the machine, the VPN, the public network), the protocol with its
  version, and how to authenticate, never a secret. The others of the agent
  group list them. (S5 § 3.10; S1 § 6.4)
- **CA.24** An endpoint exists only while its runtime is present. The
  registry says where an endpoint is; the endpoint itself checks who may use
  it. (S5 § 3.10)

### <!--[TAC-BACKENDS]--> 9.3 Backends and modes

- **CA.25** tac is a reusable component of its own: the service and its
  clients can be used without the runtime. (S1 § 7.2, CQ-15)
- **CA.26** A workspace names its backend, one of three, in its workspace
  configuration for coordination (S1 § 7.2; S5 § 6.1; S6,
  part-client-and-backends):

  | Backend | For | What it offers |
  | --- | --- | --- |
  | **local** | one machine and one user | everything except customers and quotas; the service is started by the first client that needs it and runs once per machine and user |
  | **GitHub** | one user's machines | leases, sessions, units and endpoints as refs in a coordination repository; no messages across machines — messages go through each machine's local service |
  | **server** | a team, or several | everything, independent of git: customers, access keys, quotas, an administration interface |

> **❓ PQ-10 (2026-11-19T09:21+01:00) — The GitHub backend in the first delivery:** is the backend that keeps the coordination in a GitHub repository still part of the first delivery?
>
> **Context.** The coordination service has three planned backends. The **local** one serves one machine and one user and is built. The **server** serves a team, independent of git; it is decided that the full server is built first ("customers, access keys, quotas, the admin API"), and that the whole protocol is built in one go. The **GitHub** backend was designed earlier for one user's several machines, when no server existed: it keeps leases, sessions, units and endpoints as refs in a private coordination repository through GitHub's API, and it carries **no messages across machines** — the coordination idea says "a GitHub-backend workspace has messages on each machine but not across machines". It also needs a call budget, because GitHub limits how often refs may be written, and a coordination repository with a token on every machine.
>
> **Why I ask.** With the server built first, a user with several machines can run the server on one of them and gets everything, messages across machines included. The GitHub backend then serves only those who have several machines and no machine to run a server on. It is a second implementation of leases, with its own rules for clocks, races and limits, to specify, build and test. The Blueprint has to say whether it is in the first delivery.
>
> - (a) **Keep it in the first delivery**, as designed: three backends. A user without a server still coordinates leases across machines; messaging, documents and reviews across machines are not available on it.
> - **(b)** **Defer it.** The first delivery has the local backend and the server. The protocol keeps what the GitHub backend needs (the binding to refs stays specified), so it can be built later without changing clients. The coordination repository and its tokens are not needed now.
> - (c) **Drop it.** Two backends for good; the binding to refs is removed from the protocol.
>
> *Recommendation:* (b) — everything the new parts add (people, teams, messages, documents, the integration queue) needs a service, so the GitHub backend would offer less and less of the whole; deferring keeps the door open at no cost now.
>
> **Answer:**

- **CA.27** The server is the full server from the start: customers, access
  keys kept as salted hashes, quotas per customer, the administration
  interface. A small team's server is the same server with one customer.
  (S1 § 7.2, CQ-9; S5 § 3.1, § 3.12)
- **CA.28** The server runs long, without the idle stop of the local
  service, with the same store and configuration. Encryption in transit ends
  at a reverse proxy in front of it; the service itself stays without
  dependencies. It answers browser clients (cross-origin requests; in a
  browser the access key travels as the WebSocket subprotocol). (S1 § 7.10;
  S5 § 9)
- **CA.29** A quota never blocks giving something back: releasing a lease,
  deregistering, closing a session, acknowledging a command, withdrawing an
  endpoint, or renewing a lease already held. (S5 § 3.12)
- **CA.30** The **relay** is part of the server. It carries TAC and MCP for
  machines that are not on the VPN and only forwards. A machine
  authenticates to it with a key per runtime that the group's administrator
  issues. (S1 § 7.2; S2 § 5, FO-9; S4)
- **CA.31** With coordination switched off (`mode: off`, the default)
  nothing is coordinated and everything works as it does without tac.
  (S1 § 7.2; S6, IDEA-6)
- **CA.32** When the backend cannot be reached, nothing falls back on its
  own: the queues of the agent group stop after their current todo, and the client
  recovers by itself when the backend is back. Working locally meanwhile is
  an emergency step a person confirms twice. (S6, BP-7)
- **CA.33** An agent group moves from one backend to another by a migration that
  carries its units, infrastructure resources, token counters and
  undelivered commands. (S5 § 3.11, § 5.8)
- **CA.34** Every runtime also registers with the local service of its
  machine, whatever its backend. The local service reports, as warnings that
  block nothing: one repository under two different backends, two workspaces
  naming one agent group with different backends, a listed repository whose clone
  is missing or has another origin. (S5 § 6.4)
- **CA.35** The runtime has one client for all of this. The queue, the
  tools, the views and the hosts ask that client and never a backend.
  (S6, part-client-and-backends)

### <!--[TAC-PEOPLE]--> 9.4 People, teams and identity

`tac/1.0` knows runtimes only. Messaging and supervision need people and
teams.

- **CI.1** A **team** is a group of people. An **agent group** is a group of
  runtimes. They are two different things (S1 § 7.3, DQ-1):

  | | Is | Has |
  | --- | --- | --- |
  | **team** | people | members, owners, invitations, conversations, review sets, the right to control each other's runtimes |
  | **agent group** | runtimes that coordinate | presence, leases, messages between runtimes, endpoints |

> **❓ PQ-11 (2026-11-19T09:21+01:00) — Customers, teams and agent groups:** how are a customer, a team and an agent group tied to each other, and who creates the first of each?
>
> **Context.** Three records exist above a person and a runtime. A **customer** is whoever a server serves: it has access keys and quotas, and is created through the server's administration interface. An **agent group** is the set of runtimes that coordinate (they see each other and compete for the same leases); today a group comes into being when the first runtime names it. A **team** is a group of people. It is decided that a team and an agent group are two different things: "A team is a group of humans, each human may run several agent groups, in several runtimes", and that "a team has owners; the first is whoever created the team with the server's admin API". Nothing says yet how the three relate: whether teams and agent groups both belong to a customer, whether an agent group belongs to a team, and who creates the first customer on a new server.
>
> **Why I ask.** The Blueprint's information model needs the relations, and the security part needs to know who may create what. It also decides what a person does on the first day: installing a server and ending up with a working team.
>
> - **(a)** **A customer has teams and agent groups; a team names the agent groups it uses.** Whoever installs the server creates the first customer and its first access key from the server's command line. With that key, a person creates a team and becomes its first owner. An agent group is created by a team's owner and belongs to the customer; a team lists the agent groups its members' runtimes may join, and an agent group may be listed by several teams of the same customer (two teams sharing repositories share the leases on them). A runtime joins an agent group with its person's token of a team that lists that group.
> - (b) **An agent group belongs to exactly one team.** Simpler: a team's owner creates its agent groups, and only that team's members' runtimes join them. Two teams working on the same repositories do not see each other's leases.
> - (c) **Agent groups stay free of teams**, as today: any runtime that has the customer's access key and names a group joins it. Teams only concern messaging and remote control.
>
> *Recommendation:* (a) — leases only help when everyone who writes to a repository is in the same agent group, and that is not always one team.
>
> **Answer:**

- **CI.2** A person is a member of one team or of several. A person runs
  several runtimes, and those may be in several agent groups. One runtime
  belongs to exactly one person. (S1 § 7.3, DQ-1)
- **CI.3** A **participant** is a person (a user id, an e-mail address, a
  display name) or a runtime. A runtime names the person it belongs to, so
  what an agent sends is attributed to the runtime and to its person. A
  person has several devices, each with its own connection and its own read
  position. (S1 § 7.3)
- **CI.4** Every client reaches tac through a runtime: on the desktop the
  host's own runtime, in a browser, on a phone or on a tablet a runtime on a
  server (`CLI > CLI-PACK`, CL.11; `SCO > SCO-LATER`, L-8). tac's
  participants are people and runtimes, never a device on its own.
  (S1 § 7.3, WQ-1)
- **CI.5** A team has owners and members. (S1 § 7.3, DQ-2)

> **❓ PQ-12 (2026-11-19T09:21+01:00) — What an owner of a team may do that a member may not:** which rights does a team's owner have?
>
> **Context.** Decided so far: a team has owners and members; an owner creates invitations and removes members; "only the team's owners change" the team's configuration (the providers, which of them may be used, the standard profiles); a stale lease is freed "only by the user"; an unanswered question ends, at the end of its chain, with the team's owners. Not said: who may make someone an owner, who may free another member's stale lease, who may set the team's limits (how long messages are kept, the worktree setting per repository, the working hours used for escalation), and who may remove a device of another member.
>
> **Why I ask.** The Blueprint's security part lists every operation with who may call it. Without a rule, either everything a member can do to their own things an owner can do to everyone's, or nothing can be done for a member who is away.
>
> **Proposed split**, to confirm or correct:
>
> | Operation | Member | Owner |
> | --- | --- | --- |
> | send messages, send and return documents, answer and forward questions | yes | yes |
> | see the team's people, runtimes, leases and open questions | yes | yes |
> | control another member's runtime remotely (where its host allows it) | yes | yes |
> | free a stale lease | their own | anyone's |
> | remove a device | their own | anyone's |
> | invite a person, remove a member | no | yes |
> | make a member an owner, or take that away (never from the last owner) | no | yes |
> | change the team's configuration and settings (providers, retention of messages, working trees per repository, escalation times) | no | yes |
> | declare units and infrastructure resources of an agent group | yes | yes |
> | create or delete an agent group; delete the team | no | yes |
>
> - **(a)** As in the table.
> - (b) As in the table, but controlling another member's runtime needs that member's consent each time, or an owner.
> - (c) Different — say which rows.
>
> *Recommendation:* (a) — a team is people who trust each other; the runtime's own host setting is the place to refuse remote control.
>
> **Answer:**

- **CI.6** A person joins a team by **invitation** (S1 § 7.3, CQ-10, DQ-2):
  1. An owner creates an invitation for an e-mail address.
  2. Creating it returns a one-time password, as text and as a link or QR
     code. The owner passes it on by a channel they trust. It is valid once,
     for 7 days. The server sends no e-mail (`SCO > SCO-LATER`, L-4).
  3. The invited person's client presents the password together with the
     e-mail address it was issued for.
  4. The server creates the participant with a user id it generates itself,
     so that no client can choose an id, and returns the **team token**.
- **CI.7** A team token is per person and team. Every device registers
  itself under it, so one device can be removed without the others. The
  token is kept as a secret (`RT > RT-SECRETS`, CS.11), never in a file.
  (S1 § 7.3, DQ-2)
- **CI.8** A client sends a team token with every request. A member of
  several teams holds several tokens. (S1 § 7.3, CQ-10)
- **CI.9** An owner removes a member, and the server then refuses that
  member's token. A member can leave. Tokens can be rotated. (S1 § 7.3,
  DQ-2)
- **CI.10** There are two levels of identity, and both are built:
  **identification**, where a client states a user id and an e-mail address
  and is believed, so that work can start without any setup; and
  **invitation with team tokens**. (S1 § 7.3, CQ-10; S3, WR-2)

> **❓ PQ-13 (2026-11-19T09:21+01:00) — Identification without an invitation:** when does a team accept a member who only states a user id and an e-mail address?
>
> **Context.** Two levels of identity are decided, "both built": **identification**, where a client states a user id and an e-mail address and is believed ("we should have (a) and (b) so we can start without troubles, test (b) and fix it while working using (a)"), and **invitation**, where a one-time password proves that the person was invited, the server generates the user id ("so the host cannot fake an id"), and a team token is sent with every request. Not said: whether identification stays possible once invitations work, and who decides that for a team.
>
> **Why I ask.** With identification, anyone who can reach the server and knows a team's name can state any identity; remote control of runtimes is allowed inside a team. The Blueprint has to say where identification is accepted.
>
> - **(a)** **A setting per team, strict by default.** A team accepts identification only when its owner switched it on; a new team requires invitations. Remote control of a runtime and the team's configuration always require a team token, also in a team that accepts identification for messaging.
> - (b) **Identification only on the local backend** (one machine, one user), never on a server.
> - (c) **Identification everywhere until the product owner switches it off** for the whole server, as a means to start; no setting per team.
>
> *Recommendation:* (a) — it lets a first team start without setup, as decided, and keeps the operations that can do harm behind the token.
>
> **Answer:**

- **CI.11** A quest has a **home team** and an owner (`RT > RT-ASKS`,
  CP.16); it records both. Its runtime acts as a member of the home team:
  asks are routed in it, and remote control is allowed from it. (S1 § 7.3,
  DQ-12)
- **CI.12** When an action addresses another team — a review request to that
  team's members, a message into one of its conversations — the runtime uses
  its person's token for that team, for exactly that action. A person's
  devices show all their teams side by side. (S1 § 7.3, DQ-12)
- **CI.13** A runtime can be controlled remotely only by members of a team
  its person is in, and only when its host's setting allows it. (S1 § 7.3,
  CQ-10; `CLI > CLI-TRC`, CK.5)
- **CI.14** A team lists its people, the known and the present ones, with
  their ids and e-mail addresses. A message names the person who sent it.
  (S1 § 7.10; S3, WR-2)
- **CI.15** A team has a configuration that tac keeps and delivers to its
  members' runtimes (`RT > RT-CONFIG`, CS.3 … CS.6). (S1 § 5.5, DQ-11)

### <!--[TAC-KINDS]--> 9.5 Message kinds

- **CM.1** A message between people has a kind. Beyond text, a kind is
  something the recipient's application can act on. The service stores and
  delivers; the kinds are the clients' convention and are versioned with the
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
- **CM.5** A reminder is delivered once to a person, however many devices
  and runtimes that person has. (S1 § 7.4)
- **CM.6** **Delivery follows presence.** A notification is not pushed to a
  device while its person is active on another one; after a time without a
  reaction it goes on to the next channel. (S1 § 7.4)

### <!--[TAC-CONV]--> 9.6 Conversations

- **CM.7** A conversation is direct (two people), a group (a list of
  members), or attached to something: a document, a review round, a todo, a
  run, a quest. What it is attached to is an anchor the client sets and the
  service does not interpret. (S1 § 7.5, § 7.10; S3, WR-4)
- **CM.8** Messages have replies and threads, mentions, and a mute per
  conversation. (S1 § 7.5, § 3.2)
- **CM.9** A conversation's history is stored and read in pages and from a
  point on (a message or a time), so a client that was offline catches up.
  Members who are present receive messages live. The time of a message is
  the service's. (S1 § 7.5, § 7.10; S3, WR-4)
- **CM.10** Read state is kept per person: read up to a message, and the
  number of unread messages per conversation. (S1 § 7.5, § 7.10; S3, WR-4)
- **CM.11** Messages are kept for one year unless the team sets another
  time, or sets that they are kept. (S1 § 7.5, WQ-3)
- **CM.12** Every message has a stable address,
  `msg:tac/<team>/<messageId>`, that other documents and messages can refer
  to. (S1 § 7.5, § 3.2)
- **CM.13** A send carries a request id the service remembers for 24 hours.
  A send repeated with the same id is not delivered twice, so a client that
  was offline can resend what waited in its outbox. (S1 § 7.5, § 7.10;
  S5 § 5.6; S3, WR-4)
- **CM.14** The messages between runtimes (`TAC > TAC-COORD`) stay as they
  are beside the messages between people. (S1 § 7.10)

### <!--[TAC-DOCS]--> 9.7 Documents

- **CV.1** A file travels through tac as a **blob**: addressed by the
  SHA-256 hash of its content, checked on upload, stored once however often
  it is referenced. A reference in a message carries the hash, the name, the
  media type and the size. (S1 § 7.6, § 7.10; S2 § 5, FO-8; S3, WR-5)
- **CV.2** There is a size limit per file and a quota per team. A client
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

- **CI.16** What travels between a client and the server is encrypted in
  transit. (S1 § 7.8; S3, WR-3)
- **CI.17** What the service stores is not encrypted by default. Encryption
  at rest is an option (`SCO > SCO-LATER`, L-10). (S1 § 7.8; S2 § 5, FO-20)
- **CI.18** Pairing of devices and end-to-end encryption between a device
  and a runtime become mandatory as soon as anything can be reached from
  outside the VPN, that is, with the relay (`SCO > SCO-LATER`, L-6).
  (S1 § 7.8, CQ-10)

### <!--[TAC-SPEC]--> 9.10 One specification: `tac/2.0`

- **CA.36** Everything in this section and the integration of
  `PAR > PAR-APPROACH` is specified as one protocol version, `tac/2.0`:
  participants, teams and identity; the server; conversations, message kinds
  and reminders; documents, pinning and review sets; integration leases and
  the integration queue; authentication. It is one document, reviewed as a
  whole, and it is built in one go. (S1 § 7.9, CQ-8, WQ-2)
- **CA.37** A service announces, when a client connects, the capability
  blocks it implements (participants, teams, messaging, documents,
  integration, and so on). A client uses what is announced. (S1 § 7.9, WQ-2)
- **CA.38** New capabilities are added within `tac/2.0`. A runtime of an
  older version that is still running somewhere keeps working with a newer
  service, and a client that states no person still works. (S1 § 7.9,
  § 7.10, WQ-2)

### <!--[TAC-WEBWORK]--> 9.11 What Webwork needs, and how it is met

Webwork states six requirements on tac (S3, WR-1 … WR-6; its seventh, on the
runtime, is met in `RT` and `CLI`).

| Requirement | Met by | How |
| --- | --- | --- |
| **WR-1** tac reachable as a server by a small team | CA.26 … CA.28 | The full server; a small team is one customer on it. (S1 § 7.10, CQ-9) |
| **WR-2** identification by user id and e-mail on connect | CI.3, CI.4, CI.10, CI.14 | Identification is one of the two levels of identity. **Differently from the requirement:** a client without a runtime does not register in tac; it goes through a runtime. (S1 § 7.10, WQ-1) |
| **WR-3** encryption on the wire only | CI.16, CI.17, CA.28 | Encrypted in transit, ending at a reverse proxy; nothing required at rest. (S1 § 7.10) |
| **WR-4** user messages | CM.1 … CM.13 | Conversations, history, read state, retention, the request id. (S1 § 7.10, WQ-3) |
| **WR-5** documents as blobs for the review exchange | CV.1 … CV.6, CV.10 … CV.14 | Blobs with limits and lifetimes, pinning, review sets, the exchange. (S1 § 7.10, CQ-11) |
| **WR-6** a Dart client that needs no AI runtime | `CLI > CLI-PACK`, CL.2, CL.3, CL.11 | The Dart tac client is a package of its own. **Differently from the requirement:** an application does not connect to tac directly from a browser or a phone; it uses the runtime client against a runtime on a server (`SCO > SCO-LATER`, L-8). Until that exists, Webwork's messaging works on the desktop. (S1 § 7.10, CQ-15, WQ-1) |

Webwork does not need leases, units, endpoints, the GitHub backend or
messages between runtimes for its messaging. (S3)

## <!--[PAR]--> 10 Parallel work, cross-quest work and repository quests

Several runs, on several machines, by several people, work on the same
repositories at the same time. This section states what hurts in that today,
how the product lets them do it without getting in each other's way, how
work crosses from one quest to another, and how a quest and a person's own
files get repositories of their own.

### <!--[PAR-PROBLEM]--> 10.1 What hurts today

The problems this part solves (S1 § 10.1; S16):

| Problem | What it means |
| --- | --- |
| Everything is committed on the main branch, in clones several sessions share | "One writer per repository" is an agreement nobody enforces. A repository many want is a queue of one. |
| Nothing stands before the main branch | A broken commit is at once the base of every other session, and is published to those who depend on it. |
| A run cannot be discarded | Work that went wrong is undone by hand. |
| A long run holds a repository for hours | Half-finished states lie on the main branch meanwhile. |
| Other sessions' uncommitted work is in the way | Installs, builds and syncs meet changes that are not theirs; such changes have been committed by a sync and destroyed by one command. |
| Nobody can ask "is anything writing here" | Before a sync between machines the answer is found by hand, and a queue cannot be asked to pause. |
| Machines drift apart unnoticed | A machine can be thousands of commits behind without anything saying so. |
| Shared files are written whole by one process | One window overwrites what another just set. |
| Requests to another quest get stuck | An item sent to a run that is paused or does not exist waits unseen; a request ends without anything being filed. |
| A release ripples | One release of a shared package moves dozens of dependents, and "version X is published" is nothing a todo can wait for. |

- **CW.1** The trunk is kept: work lands on the main branch of each
  repository, without a pull request per task and without a build server.
  What is added is what the trunk lacks: a check before the main branch, a
  way to discard a run, locks shorter than a run, and an answer to who holds
  what. (S1 § 10.3, § 10.4)

### <!--[PAR-APPROACH]--> 10.2 The approach

CW.2 and CW.3 are decided. CW.4 to CW.14 are stated here as capabilities and
wait for the product owner's confirmation (`new_questions.md`, section
`PAR-APPROACH`): the concept proposes them.

> **❓ PQ-14 (2026-11-19T09:21+01:00) — The integration step and what goes with it:** do you confirm the parts of the approach to parallel work that so far are only proposed?
>
> **Context.** Decided: the trunk is kept, and whether runs get a working tree and a branch of their own is a setting per repository that the team decides. The concept proposes nine further parts, as "items 2 to 10" of its section on keeping the trunk, and marks them as proposals. Each, with what it means:
>
> | Nr. | Part | What it means |
> | --- | --- | --- |
> | 2 | The lease covers the integration, not the run | A run holds only an advisory claim on what it touches while it works; the exclusive lock on a repository is taken just for the moment its commits are brought onto the main branch (rebase, checks, fast-forward, push). Today's design locks the repository for the whole todo. |
> | 3 | An integration queue per repository | The coordination service lines up the runs that want to land on a repository, one after the other; each lands if the repository's declared checks pass, else it is sent back to its run. |
> | 4 | A touch set per todo | A todo says which repositories, packages and paths it will touch; the queue starts only todos that do not overlap and says up front who waits for whom. |
> | 5 | Waiting runs rebase | After each landing, the runs still waiting are rebased onto the new main branch and their checks run again before they land. |
> | 6 | A record of each todo's commits | Per repository the commit before and after a todo. It is what a review looks at, what is reverted to discard a todo, and how a commit is traced to its session. |
> | 7 | "Published at version N" as something a todo waits for | A todo can be blocked until a package is published at a version; the runtime checks the registry and unblocks it. |
> | 8 | Quiescence as a question | The coordination service answers who holds what in a repository, a workspace or on all machines; a sync asks instead of assuming; a runtime can be asked to pause its queue after its current item. |
> | 9 | The agent state stays on the main branch | Todo and state files get no working trees and no integration step; they are merged by their own merge drivers. |
> | 10 | Review without pull requests | A todo's difference as a review document, a review agent that sees only the difference and the todo's completion criteria, a person only for paths that carry weight, the verdict recorded with the todo. |
>
> **Why I ask.** These parts are most of what the product adds to parallel work, and parts 2, 3 and 5 change the design of leases that the coordination idea settled earlier (a claim held exclusively from a todo's start to its end). The Blueprint needs to know which of them are requirements. Parts 2, 3 and 5 only make sense where a repository has working trees switched on; with one working tree, two runs cannot work at once whatever the lease covers.
>
> - **(a)** **Confirm all nine.** Where a repository has working trees, the claim during the run is advisory and the exclusive lease is taken for the integration; where it has none, the claim is exclusive for the whole todo, as designed earlier.
> - (b) **Confirm with exceptions** — name the numbers that are not part of the product, or are later.
> - (c) **Only the leases, without the integration queue:** parts 4, 6, 7, 8 and 9 are kept; a claim stays exclusive for the whole todo in every repository, and a run with a working tree merges its branch itself when it holds the lease (parts 2, 3, 5 and 10 are dropped or later).
>
> *Recommendation:* (a) — the integration step is what gives the trunk its missing check and lets several runs work in one repository; without it working trees only move the conflict to the end.
>
> **Answer:**

**A run's result is a branch**

- **CW.2** Whether runs work in a working tree of their own is a setting per
  repository that the team decides and can change. A repository one person
  works on needs none. When several work on it in parallel, a run works in
  its own working tree, on its own branch, and its result is that branch.
  The `_ai` state never gets working trees of its own. (S1 § 10.4, CQ-12)
- **CW.3** A working tree of a run keeps the relative layout of the
  repositories, so that builds and path dependencies between neighbouring
  repositories keep working; inside it, `_ai` is the one shared `_ai`. The
  run's tools and its agent work in that tree. (S6,
  part-branches-and-worktrees)

**Claims and the integration step**

- **CW.4** Before the queue sends a todo, it takes the todo's claims, all or
  none. When a claim is held by someone else, the item waits and says who
  holds it; when the claim is released, the waiting item goes on.
  (S6, part-claims; S1 § 9, § 10.4)
- **CW.5** A run holds a long, advisory claim on what it touches, and takes
  the short, exclusive lease on the repository only to integrate. The
  integration step is: rebase the run's commits onto the main branch, run
  the repository's checks, fast-forward the main branch, push. The fencing
  token is checked at the push. (S1 § 10.4, item 2)
- **CW.6** Every repository has an **integration queue**, kept by tac. It is
  serial and mechanical: it runs the checks the repository declares
  (analysis, the tests the change affects) and lands the run's commits or
  rejects them back to the run. There is no integrator above the
  repositories. (S1 § 10.4, item 3)
- **CW.7** A todo declares its **touch set**: repositories, packages, paths.
  The queue starts only todos whose touch sets do not overlap, and says
  before it starts which todo waits for which. (S1 § 10.4, item 4)
- **CW.8** A todo is written with its own touch set. A quest lists the
  repositories and parts of repositories it usually works on; a todo that
  names nothing claims that whole list while it runs. The quest's list is
  the fallback, mainly for older todos. (S1 § 5.5, CQ-3, DQ-5)
- **CW.9** A group of todos can take its claims with its first todo and give
  them back with its last. (S6, BP-10)
- **CW.10** After each integration the runs that wait rebase onto the new
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
  all machines of an agent group. A sync between machines or a change of the
  workspace's layout asks instead of assuming. A runtime can be asked to
  pause its queue after its current item. (S1 § 10.4, item 8)
- **CW.14** The `_ai` state stays on the main branch: todo and state files
  are not code, are merged by their own merge drivers and are written file
  by file. (S1 § 10.4, item 9; `TAC > TAC-COORD`, CA.17)
- **CW.15** **Review happens without pull requests.** The difference a todo
  made is shown as a review document; a review agent that starts without the
  run's context gets only that difference and what the todo says must be
  true when it is done; a person reviews only the paths that carry weight
  (migrations, formats, publishing, credentials); the verdict is recorded
  with the todo. (S1 § 10.4, item 10)
- **CW.16** A repository nobody claims can be brought up to date
  automatically, by fast-forward only and only with a clean working tree and
  nothing unpushed. It is switched on per workspace. A repository it had to
  skip is reported. (S6, BP-12, BP-18)
- **CW.17** The system does not take over from others: a pull request per
  task, a merge queue at the code host, or agents working directly on the
  main branch of a repository several runs want. (S1 § 10.4)

### <!--[PAR-CROSS]--> 10.3 Cross-quest linkage

- **CW.18** One way of addressing holds on one machine and across machines:
  a todo as quest and todo id, a run as quest and run, a session, a person.
  (S1 § 10.5)
- **CW.19** Delivery is acknowledged. Something sent to another quest is
  accepted by a run there, refused with a reason, or waits at the sender,
  visibly, with what it waits for. It does not wait unseen at the receiver.
  (S1 § 10.5, § 9)
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
  and touch sets can be checked against it. The repositories of a workspace
  are those of the file the workspace is set up from. (S1 § 10.5, § 5.5,
  CQ-3)

### <!--[PAR-QUESTS]--> 10.4 Repository quests and personal files

- **CQ.1** There are two kinds of quest. A **classic quest** is a folder in
  the shared repository of the `_ai` state; whoever shares that repository
  shares the quest. A **repository quest** is a quest whose folder is a
  clone of the quest's own repository, which the shared repository ignores;
  whoever has access to the quest's repository shares the quest. Which kind
  a quest is, is decided per quest. (S2 § 3.7, § 5, FO-18; S1 § 12.5; S4,
  note n)
- **CQ.2** Every person has one **personal repository**, cloned into the
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
  - **join**: a second person, or the same person on another machine, starts
    working on an existing repository quest — the quest's repository is
    cloned into place, the personal repository is set up, the person is
    registered as a member;
  - **migrate**: a classic quest becomes a repository quest and keeps its
    history — the quest's folder with its commits is copied into the new
    repository, and a trial run shows the result before anything is changed.
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
  and fields are added, not changed or removed. An older client keeps working
  with a newer runtime; it does not get the new features, and nothing it does
  breaks. (S1 § 6.7, DQ-9; `RT > RT-VERSIONS`)
- **N-2** A client returns every field it does not know unchanged when it
  writes a record back, so nothing a newer runtime added is lost. Every client
  package does this, and the conformance suite tests it. (S1 § 6.7, DQ-9)
- **N-3** The protocol's version, the runtime's version and the format of the
  workspace files are checked when a client connects. A runtime does not work
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
  each other's state. State that belongs to the machine has one owner, the
  runtime, and is reached through one interface; where files are used, a
  write changes one key, under a lock, and never the whole file. (S1 § 5.5,
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
  back on its own: the queues of the agent group stop after their current todo,
  and the user can switch to an emergency local mode. (S6; S1 § 7.2;
  `TAC > TAC-BACKENDS`)
- **N-13** A lease that is no longer renewed becomes stale and is shown; only
  a person frees it. (S5 § 4; S16)
- **N-14** A runtime that is offline still starts with the team's
  configuration as it last saw it. (S1 § 5.5, DQ-11)

**Asks**

- **N-15** An ask is never lost and does not block a process for long: it is
  a stored record that outlives the process that asked, it moves along a
  chain of people, every open ask of a team can be seen with its age and
  holder, and nothing is decided automatically unless the ask declared a
  default. (S1 § 6.1, § 6.6, CQ-7, DQ-3; `RT > RT-ASKS`)
- **N-16** A send to tac can be repeated safely: a repeated request is not
  carried out twice. (S5 § 11; S1 § 7.5; S3 WR-4)

**Security**

- **N-17** No secret stands in a configuration or in a file of a quest: a
  configuration holds a reference, resolved at the moment the secret is
  needed. Team tokens are kept the same way. (S2 § 5, FO-15; S1 § 5.8, CQ-16;
  `RT > RT-SECRETS`)
- **N-18** The runtime's MCP server reads and writes only the `_ai` state; no
  file, command, web or git tool is offered through it. That is what makes it
  safe to publish to other machines. (S4; S2 § 5, FO-17; S1 § 6.3, § 6.4)
- **N-19** The VPN is the boundary today: inside it, identification by user
  id and e-mail address is accepted. Remote control of a runtime is possible
  only inside a team and only where the runtime's host allows it. (S1 § 7.3,
  CQ-10)
- **N-20** What travels between a client and the tac server is encrypted in
  transit. What the service stores is not encrypted by default. (S3 WR-3;
  S2 § 5, FO-7, FO-20; S1 § 7.8)
- **N-21** As soon as anything is reachable from outside the VPN, pairing of
  devices and end-to-end encryption between a device and a runtime are
  required. (S1 § 7.8, CQ-10; `SCO > SCO-LATER`, L-6)
- **N-22** A user id is generated by the server when an invitation is
  redeemed; no client chooses one. (S1 § 7.3, DQ-2)
- **N-23** A file a prompt drew from an encrypted document leaves no trail on
  disk: its trail is kept in memory only. (S1 § 3.2; S13)

**Platforms**

- **N-24** The runtime is a Node program written in TypeScript; it imports
  nothing from VS Code, and a test guards that. (S1 § 4; S2 § 3.1)
- **N-25** The Flutter components build for the desktop, the web, iOS and
  Android, are themeable by the host and have no dependency on Tom Forge.
  (S1 § 12.2; `CLI > CLI-UI`)
- **N-26** The client packages exist for nine languages: Dart, TypeScript,
  JavaScript, Python, Java, Go, Rust, C and C++. The Dart tac client runs
  with and without `dart:io`. (S1 § 12.1; S2 § 3.5; `CLI > CLI-PACK`)
- **N-27** The fleet's machines are macOS, Linux and Windows; the shared
  installation has a place on each of them. (S2 § 5, FO-3)
- **N-28** The tac service has no runtime dependencies; TLS ends at a reverse
  proxy in front of it. (S5; S1 § 7.10)

**Licence**

- **N-29** The packages are BSD-3, as the framework's packages are.
  `tom_tac_service` carries that licence today, and Webwork's choice of tac
  for its messaging rests on it. (S5; S13, DPMESSAGING-2; S19)
  ___check here___ No decision of the product owner states the licence of the
  new packages; the question on licence and publication asks.

> **❓ PQ-15 (2026-11-19T09:21+01:00) — Licence and publication of the packages:** under which licence are the new packages released, and where are they published?
>
> **Context.** The product builds new packages: the runtime (TypeScript), the coordination service (TypeScript), a runtime client and a coordination client in each of nine languages, the Flutter components, the supervision application. No decision of the product owner names their licence or where they are published. What the sources say:
> - the coordination service that exists today carries the BSD-3 licence, and Webwork chose it for its messaging because it is "own BSD-3", not a copyleft product;
> - the first runtime design said: licence BSD-3, and "one esbuild bundle, installed on demand; nothing published to npm";
> - since then it was decided that every host carries the runtime version it was built with and installs it into a shared place on the machine, and that client packages exist for nine languages "for applications to use".
>
> **Why I ask.** The Solution Blueprint records the licence and how each package reaches its users. A client package that an application developer is to use must be obtainable from that language's registry or in some other stated way; and "nothing published to npm" was decided for the runtime when only Tom's own hosts were to carry it.
>
> - **(a)** **BSD-3 for everything; clients and components published, the runtime and the service carried.** The client packages and the Flutter components are published to their languages' registries (pub.dev for Dart, npm for TypeScript and JavaScript, and so on, each when its client is built). The runtime and the coordination service are not published to a registry: hosts carry the runtime, and the service is installed from the binaries layer or by its own installer.
> - (b) **BSD-3 for everything; everything published**, the runtime and the service to npm too, so anyone can install them without one of Tom's hosts.
> - (c) **BSD-3; nothing published for now.** Everything is used from the workspace's repositories until the product is stable; publication is decided later.
>
> *Recommendation:* (a) — client packages are only useful where a developer can get them, while the runtime's version must match its host and is better carried by it.
>
> **Answer:**

**Documentation**

- **N-30** The product is delivered with its documents (S1 § 13.2):
  - the specification, in the structure of the TomSpecs model;
  - an architecture document: components, process model, the topologies and
    the flows as sequences, who owns which state, security;
  - the runtime protocol specification, with its JSON schema;
  - the TAC specification `tac/2.0`;
  - the API documentation of the clients, per language, with examples;
  - the screen and component descriptions;
  - guides: integrating the runtime into a Flutter application; setting up a
    tac server and a team; pairing with Tom Secrets Manager; the rules for
    parallel work with what is enforced.

**Testing**

- **N-31** One conformance suite checks every client in every language
  against the protocol; the Dart and the TypeScript and JavaScript clients
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
  the machine of the run. (S16; S1 § 10.3, § 10.4)

### <!--[NFR-TOPO]--> 11.1 Network topologies

The topologies the architecture document describes (S1 § 8). T1 to T6 belong
to the first version; T7 and T8 are later.

| Id | Topology | What runs where | What must be reachable |
| --- | --- | --- | --- |
| **T1** | One machine, VS Code only | One runtime per window, inside the extension; the local tac service once for the machine and user. | Only the loopback interface. Nothing leaves the machine. |
| **T2** | One machine, several hosts | VS Code windows, and Webforge with one runtime process per open quest plus one without a quest for Webwork's own AI. Two hosts may work on one quest. | The loopback interface; all hosts find the shared installation and the local tac service. |
| **T3** | One user, several machines on the VPN | Each machine as T1 or T2. The machines form one agent group through the GitHub backend or the server. | Each machine reaches the coordination repository or the tac server; runtimes reach each other's published MCP endpoints directly over the VPN. |
| **T4** | A team on the VPN | As T3 with several people; the server carries the messaging. Webwork on the desktop connects through its local runtime. | Every member's machine reaches the tac server over TLS on the VPN. |
| **T5** | A member off the VPN | A machine outside reaches the server's public address; the relay forwards TAC and MCP to runtimes inside. | The server's public address over TLS. Runtimes inside keep an outbound connection to the relay; nothing inside accepts a connection from outside. |
| **T6** | A runtime server | An always-on machine runs runtimes without a window; quests are worked from the queue and supervised through trc. | The machine reaches the tac server; trc reaches the runtimes' endpoints. |
| **T7** | A cloud agent (later) | A vendor's sandbox clones a repository, works and pushes a branch; the runtime that sent the todo asks the vendor and the repository host for the result. | The sandbox reaches the repository host only; it reaches neither tac nor a runtime. (`SCO > SCO-LATER`, L-1) |
| **T8** | A server-side runtime for web, phone and tablet (later) | A browser or phone client without a local runtime uses a runtime on a server, which also hosts the web version. It is the only way such a client reaches tac. | The client reaches that server over WebSocket; the server-side runtime reaches tac. (`SCO > SCO-LATER`, L-8; WQ-1) |

T6 depends on a runtime that runs without a host application, while a runtime
is started by its host and ends with it (`RT > RT-INSTALL`, CR.44;
`SCO > SCO-LATER`, L-5). The sources do not say what hosts a runtime on a
runtime server; the question on the runtime server asks.

> **❓ PQ-16 (2026-11-19T09:20+01:00) — A runtime server and the lifetime of a runtime:** what runs the runtimes on an always-on machine, when a runtime ends with its host?
>
> **Context.** Two statements of the concept stand side by side:
> - among the network topologies: "A runtime server. A machine that is always on (bigbeast) runs runtime servers without a window: quests worked from the queue, supervised through trc."
> - the decision on the lifetime of a runtime: "the host starts it and it ends with the host, we might later investigate in standalone runtimes to which a client connects to supervise and the disconnects again, similar to the remote control. I think this can be change later easily."
>
> A runtime without a window has no host application in the sense of the three hosts of the first version (the VS Code extension, Webforge, Webwork). Later features rest on such a machine too: the server side for web and phone clients, and handing todos to a runtime of our own.
>
> **Why I ask.** The Solution Blueprint lists the topologies of the first version. If the runtime server belongs to it, something must start, stop and restart runtimes there and give them what a host gives (locations, identity, configuration, an answer to "who is asked"), and the rule "ends with its host" needs that something as the host.
>
> - **(a)** **Not in the first version.** The runtime server is later, together with standalone runtimes and the server side for web and phone. The first version's topologies are: one machine; several hosts on one machine; one user's machines on the VPN; a team on the VPN; a member off the VPN through the relay. On the always-on machine only the coordination server runs.
> - (b) **In the first version, with a small host of its own:** a command-line host (a service on the machine) that starts one runtime per configured quest, restarts it when it fails, and sends every question through the coordination service to the quest's owner. "Ends with its host" holds: the service is the host.
> - (c) **In the first version by running an existing host there** (a VS Code server or a Webforge instance on the always-on machine), with nothing new built.
>
> *Recommendation:* (a) — it follows the decision on the lifetime as it was given; (b) is the natural form when it comes.
>
> **Answer:**

#### <!--[NFR-TOPO-FLOWS]--> 11.1.1 Key flows

The flows the architecture document draws as sequences (S1 § 9).

| Id | Flow | In one line |
| --- | --- | --- |
| **F1** | A host attaches | The host finds the installed runtime, starts it, exchanges the versions, registers its tools and subscribes to the events from a sequence number on. |
| **F2** | A prompt | The host queues an item (at the end, next, or as an update to the running prompt); the queue sends it when the session is free; the transport streams; tool calls go to runtime tools or back to the host; the result is recorded in the trail. |
| **F3** | A todo walk | A walk takes the next ready todo, takes its claims through tac all or none, runs it, carries out what follows its completion and gives the claims back. |
| **F4** | A process step with a gate | The step's prompt and its walks run; the gate writes its report and asks with the decision buttons; the decision moves the process. |
| **F5** | An ask reaches a person elsewhere | A run asks; nobody is active on the asking host; the ask travels through tac to the person's other devices or along its chain, and the answer returns to the run. |
| **F6** | A team review | The runtime creates the round folder and sends the review request with the document set to each member through tac; each returns a copy; reminders go out before the deadline; the copies are merged and the round's files are released. |
| **F7** | A todo to another quest | An item or a walk is queued in a named run of another quest, on the same machine or another; it is accepted, refused with a reason, or waits visibly; the done notification returns to the run that asked. |
| **F8** | Two runs on one repository | Each run works in its own working tree on a run branch; when its todo is done it takes the repository's integration lease, rebases, runs the checks, fast-forwards the main branch and pushes; the next run rebases first. |
| **F9** | A todo to the cloud (later) | A todo goes to a hosted agent or a runtime elsewhere; a branch comes back and is integrated as in F8. |
| **F10** | Supervising a group of runtimes | trc reads the team's runtimes and their endpoints from tac, attaches to each runtime's events, shows what waits; the supervisor answers an ask, pauses a queue, continues a process. |
| **F11** | A machine joins | The runtime is installed, gets the agent group's access and registers; it sees the agent group; nothing is converged for it. |
| **F12** | A version update | A host installs a new runtime version beside the old one; running runtimes go on; a migration of the workspace files runs once under the machine's lock while the others pause. |

### <!--[NFR-GEN]--> 11.2 Generation units

What the project builds, as far as the sources state it. A generation unit is
one package or application with the technology it is written in.

| Unit | Kind | Builds | Technology | Source |
| --- | --- | --- | --- | --- |
| `tom_ai_runtime` | server (also a library inside the VS Code extension) | The runtime: engine, protocol, runtime tools, the MCP server, the tac client inside the runtime | TypeScript on Node; `tom_ai/ai_build/tom_ai_runtime` | S2 § 5, FO-1; S1 § 4 |
| `tom_tac_service` | server | The coordination and messaging service with its backends, the server mode and the relay | TypeScript on Node, no runtime dependencies; today in `tom_ai/vscode/`, to be in `tom_ai/ai_build/tom_tac_service` | S5; S2 § 5, FO-19 |
| `tom_tac_client` | client | The Dart client of tac | Dart, without Flutter | S1 § 12.1, CQ-15 |
| `tom_ai_runtime_client` | client | The Dart client of the runtime; depends on `tom_tac_client` | Dart, without Flutter | S2 § 5, FO-11; S1 § 12.1 |
| the clients of the eight other languages | client | A runtime client and a tac client each for TypeScript, JavaScript, Python, Java, Go, Rust, C and C++ | each in its language; `tom_ai/ai_build/tom_ai_runtime_nondart/<language>/` | S2 § 5, FO-10, FO-11; S1 § 12.1 |
| `tom_ai_runtime_ui` | client | The Flutter components and their gallery application | Dart with Flutter; `tom_ai/ai_build/tom_ai_runtime_ui` | S2 § 5, FO-11; S1 § 12.2, § 12.3 |
| the supervision application (trc) | client (an application) | The supervision of a team's runtimes, as a Webforge application that also runs standalone | Dart with Flutter; it may depend on Tom Forge packages | S2 § 5, FO-12; S1 § 12.4 |

No source names a unit of the kind "shared". What the units share is the
runtime protocol's JSON schema and the TAC specification; the protocol layer
of every client is generated from the schema (S2 § 5, FO-10; `CLI > CLI-PACK`,
CL.4).

**How the units are produced.** The specification takes the document
structure of the TomSpecs model; the runtime is implemented by hand from it,
and the clients' protocol layer is generated from the protocol's JSON schema,
outside the code generation of the TomSpecs process (S1 § 13.1, CQ-17, DQ-10).

**What the tooling offers** (`tomspecs` 0.17.0 in
`$TOM_BINARY_PATH/darwin-arm64/`, asked on 2026-11-19):

| Offered | Names |
| --- | --- |
| Mappers, which write a package from the intermediate form | `dart-tom`, `ts-shared`, `ts-react-client`, `ts-react-native-client`, `ts-hono-server`, `go-server`, `java-spring-server`, `csharp-aspnet-server` |
| Emitters, which write what a standard can express | `openapi`, `jsonschema`, `icu`, `asyncapi`, `markdown` |

The mappers write business applications: entities, repositories, HTTP routes
and screens. None of them writes a runtime, a protocol library or a command
line (S1 § 3.5). Whether a mapper applies to any unit, and which standard
descriptions the project publishes, is asked in the questions on the
generation units.

> **❓ PQ-17 (2026-11-19T09:20+01:00) — Mappers or hand-written code, per unit:** for each unit the project builds, does one of the TomSpecs tooling's mappers write code for it, or is it written by hand?
>
> **Context.** The units the sources name:
>
> | Unit | Builds | Written in |
> | --- | --- | --- |
> | `tom_ai_runtime` | the runtime | TypeScript on Node |
> | `tom_tac_service` | the coordination and messaging service | TypeScript on Node |
> | `tom_tac_client`, `tom_ai_runtime_client` | the Dart clients | Dart |
> | the clients under `tom_ai_runtime_nondart/` | a runtime client and a coordination client for TypeScript, JavaScript, Python, Java, Go, Rust, C, C++ | each language |
> | `tom_ai_runtime_ui` | the Flutter components and their gallery | Dart with Flutter |
> | the supervision application | supervision of a team's runtimes | Dart with Flutter |
>
> The TomSpecs tool (`tomspecs` 0.17.0) offers these mappers, which write a package from the specification's intermediate form: `dart-tom`, `ts-shared`, `ts-react-client`, `ts-react-native-client`, `ts-hono-server`, `go-server`, `java-spring-server`, `csharp-aspnet-server`. (The calls `tomspecs :ir-map --mapper` and `tomspecs :ir-emit --standard` without a value end with "needs a value"; the names are those the tool lists in its help and when given an unknown value.) These mappers write business applications: entities, repositories, HTTP routes with a database behind them, screens over them. None writes a runtime, a protocol library or a set of user interface components.
>
> You decided: the specification takes the document structure of the TomSpecs model; the runtime is implemented by hand; the protocol layer of the clients is generated from the protocol's JSON schema, by a generator of the project's own, outside the code generation of the TomSpecs process.
>
> **Why I ask.** The Solution Blueprint has a register of generation units, and each unit names its mappers or none. One unit is closer to what a mapper writes than the others: the coordination server, which has records (customers, teams, participants, conversations, messages, leases), operations over HTTP and a store. Whether it is still written by hand is not said anywhere.
>
> - **(a)** **Every unit by hand; no mapper.** The register lists the units with no mapper. The only generated code is the clients' protocol layer, from the JSON schemas of the runtime protocol and of the coordination protocol. The code-generation phase of the TomSpecs process is not used for this product.
> - (b) **By hand, except the coordination server's record and route layer**, which `ts-shared` and `ts-hono-server` write from the specification; everything else by hand. It would add the Hono web framework and a database to a service that today has no dependencies and keeps its own journal store.
> - (c) **Decide in the Solution Blueprint**, unit by unit, once its information model shows how much of each unit is plain records and operations.
>
> *Recommendation:* (a) — the service's store, its leases and its streams are not what a business-application mapper writes, and it is to stay free of dependencies.
>
> **Answer:**

> **❓ PQ-18 (2026-11-19T09:20+01:00) — Standard descriptions the project publishes:** in which standard forms are the product's interfaces described and published?
>
> **Context.** The product has three interfaces others program against:
> - the **runtime protocol**: commands, numbered events and requests from the runtime to its host, as JSON-RPC over a local connection or a WebSocket;
> - the **coordination protocol** (TAC): operations over HTTP, and a stream of messages over a WebSocket;
> - the **MCP server** of the runtime, whose tools carry their own schemas.
>
> Decided so far: "the protocol as a JSON schema in the package; the API packages are generated from it and checked against it." The TomSpecs tool can write four standards from a specification's intermediate form: `openapi`, `jsonschema`, `asyncapi` and `icu` (message texts), besides `markdown`. Since the product is not generated through that intermediate form, these descriptions would be written or generated by the project itself.
>
> **Why I ask.** Each description is something to keep in step with the code and to check in the conformance suite; and the client packages in nine languages are generated from one of them. The Solution Blueprint names them as deliverables.
>
> - (a) **JSON Schema for both protocols; OpenAPI for the coordination protocol's HTTP operations; AsyncAPI for the event stream of the runtime and the message stream of the coordination service.** JSON Schema is the source the clients are generated from; OpenAPI and AsyncAPI are derived from it and published for those who use other tools.
> - (b) **JSON Schema only**, for both protocols. One description, the one the clients are generated from; OpenAPI and AsyncAPI are not published.
> - **(c)** **JSON Schema for both, and OpenAPI for the coordination protocol's HTTP operations**, no AsyncAPI: the streams are described in the protocol specifications' text.
>
> *Recommendation:* (c) — the HTTP operations of the coordination service are what an outside developer is most likely to call directly, and OpenAPI is what their tools read; the streams are few and well described in text.
>
> **Answer:**

## <!--[DEC]--> 12 Decisions

Every decision of the product owner, as it stands. Source ids: `FO-n` in
S2 § 5; `CQ-n`, `DQ-n`, `WQ-n` in S1 § 14.1; `RT-n` in S19; `RS-n` in S18. A
decision that a later one replaced is listed once, with the earlier id named
under "Replaces or completes".

**The product and its places**

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-1** | FO-1 | The runtime is the package `tom_ai/ai_build/tom_ai_runtime`. | RT-1 (a package `tom_quest_runtime` beside the extension) | `VIS > VIS-SYSTEM`, `NFR > NFR-GEN` |
| **D-2** | FO-19, CQ-15 | The tac service is `tom_ai/ai_build/tom_tac_service`; tac is a reusable component of its own, and its client is a package of its own (`tom_tac_client` in Dart), on which the runtime client depends. | FO-19's "TAC clients in the API packages" | `TAC > TAC-BACKENDS`, `CLI > CLI-PACK` |
| **D-3** | FO-10, FO-11 | Client packages for nine languages: `tom_ai_runtime_client` for Dart, the others under `tom_ai_runtime_nondart/<language>/`; the protocol layer generated from the schema, a convenience layer by hand, one conformance suite. | — | `CLI > CLI-PACK` |
| **D-4** | FO-11, CQ-14 | Every reusable Flutter component lives in `tom_ai_runtime_ui`; Tom Forge's own component package builds on it. | — | `CLI > CLI-UI` |
| **D-5** | FO-12 | The supervision application is a Webforge application from the start that also runs standalone; it may depend on Tom Forge packages. | — | `CLI > CLI-TRC` |
| **D-6** | FO-16 | Telegram is deferred. | RT-9 (Telegram in the runtime) | `SCO > SCO-LATER` |

**The runtime**

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-7** | FO-2 | No transports implemented by a host: the VS Code language-model and Copilot chat transports are removed; Copilot only through direct calls and its SDK. | S19's host transports | `RT > RT-TRANSPORTS`, `SCO > SCO-OUT` |
| **D-8** | CQ-5 | The Agent Client Protocol in both directions — one adapter for agents that speak it, and the runtime answering as an agent for editors — late in the order. | — | `RT > RT-TRANSPORTS`, `RT > RT-HOST` |
| **D-9** | FO-6, FO-17 | Runtime tools live in the runtime, VS Code's tools stay in the extension and are registered with the runtime there; file, command, web and git tools are runtime tools for the model transports, never offered over the runtime's MCP server. | — | `RT > RT-TOOLS`, `RT > RT-MCP` |
| **D-10** | FO-5 | The streaming connection is length-prefixed JSON-RPC 2.0 over loopback TCP, with WebSocket for remote clients. | confirms RT-2 | `RT > RT-PROTO` |
| **D-11** | RT-7 | The protocol's commands are a superset of today's bridge methods. | — | `RT > RT-PROTO` |
| **D-12** | CQ-6 | The numbered events of a run are kept in memory with a bound; the trail files are the durable record. | — | `RT > RT-PROTO` |
| **D-13** | CQ-2 | The runtime owns machine-wide state; its implementation routes through the local tac service. | — | `RT > RT-MACHINE` |
| **D-14** | FO-3, FO-4, DQ-9 | One installation per machine in the per-user application data folder, versions side by side; every host installs the version it was built with; version checks, pass-through of unknown fields and upgrade callbacks in every client package. | — | `RT > RT-INSTALL`, `RT > RT-VERSIONS` |
| **D-15** | CQ-4 | A runtime is started by its host and ends with it; standalone runtimes later. | — | `RT > RT-INSTALL` |
| **D-16** | RT-3 | The Agent SDK server of today becomes a mode of the runtime, so Webwork ships one Node payload. | — | `RT > RT-INSTALL` |
| **D-17** | RS-2, CQ-3, DQ-5 | The runtime finds its places through the workspace layout resolver; the repositories are those of the workspace's setup file; every todo is written with its own resources, and a quest's list of repositories and subtrees is the fallback. | RT-6, RT-10 (locations from a setting) | `RT > RT-LOCATIONS`, `PAR > PAR-APPROACH` |
| **D-18** | DQ-8, DQ-11 | The configuration is split by content: role types, processes and templates in the repository; providers, the allowed list and standard profiles as a team's configuration in tac, stored in whichever backend the team uses; the rest per runtime. | — | `RT > RT-CONFIG` |
| **D-19** | FO-15, CQ-16 | Secrets are references: `tsm:` followed by Tom Secrets Manager's own grammar, `os:`, and `env:` and `file:` as not-secure options; the runtime and the tac service are paired with Tom Secrets Manager once. | FO-15's `tsm:<vault>/<entry>` | `RT > RT-SECRETS` |
| **D-20** | CQ-7, DQ-3 | Asks are routed by presence and by role; every quest has an owner; an unanswered ask moves along a chain, can be forwarded and is monitored; asking people outside the team by e-mail is later. | — | `RT > RT-ASKS` |

**Coordination, people and messaging**

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-21** | CQ-8, WQ-2 | tac is specified as one `tac/2.0` and built in one go; a service announces its capabilities, and new ones are added within `tac/2.0`. | the minor versions in the earlier todos | `TAC > TAC-SPEC` |
| **D-22** | CQ-9 | The full server (customers, keys, quotas, administration) is built first; TLS ends at a reverse proxy. | the smaller team server | `TAC > TAC-BACKENDS` |
| **D-23** | FO-9 | The relay is part of the server, carries TAC and MCP, and only forwards. | — | `TAC > TAC-BACKENDS` |
| **D-24** | DQ-1 | A team is people, an agent group is runtimes; one runtime belongs to one person. | — | `TAC > TAC-PEOPLE`, `GLO` |
| **D-25** | CQ-10, DQ-2 | Identification by user id and e-mail and invitation with team tokens are both built; an owner invites, a one-time password is passed on by the owner, the server generates the user id; remote control only inside a team and only where the runtime's host allows it. | — | `TAC > TAC-PEOPLE` |
| **D-26** | DQ-12 | A quest has a home team; its runtime acts for another team only by explicit address, with the person's token for that team. | — | `TAC > TAC-PEOPLE` |
| **D-27** | WQ-1 | A browser, phone or tablet client reaches tac only through a runtime on the server side, which also hosts the web version; tac's participants are people and runtimes. | the earlier answer that such a client registers in tac, and the concept's earlier text | `TAC > TAC-PEOPLE`, `NFR > NFR-TOPO`, `SCO > SCO-LATER` |
| **D-28** | FO-7, WQ-3 | User messages: direct, group and attached conversations, stored with a retention of one year by default that a team may change. | — | `TAC > TAC-CONV` |
| **D-29** | FO-8, FO-21, CQ-11 | Documents travel as content-addressed blobs with a size limit, a quota and a lifetime of 7 days by default and 30 at most; a process may pin its blobs while it runs; a review set is a named set of pinned files. | FO-21's open concept for longer processes | `TAC > TAC-DOCS` |
| **D-30** | DQ-4 | The versioned documents and the record of a review are in the project's specification folder or a specification repository, usually not in the quest. | — | `TAC > TAC-DOCS`, `TAC > TAC-REVIEW` |
| **D-31** | FO-20 | Messages and blobs are not encrypted at rest by default; it is an option, its key in Tom Secrets Manager. | — | `TAC > TAC-CRYPT` |
| **D-32** | WQ-4 | Webwork is told what was decided; its requirements are covered by the product as a whole, built in one go. | — | `TAC > TAC-WEBWORK` |

**Parallel work and quests**

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-33** | CQ-12 | Whether runs work in a working tree of their own is a setting per repository that the team decides and can change. | — | `PAR > PAR-APPROACH` |
| **D-34** | FO-13, FO-18, FO-22 | Repository quests as planned; one personal repository per person with a folder per quest and personal notes; quest notes stay in the quest. | — | `PAR > PAR-QUESTS` |
| **D-35** | CQ-13, DQ-8 | Handing todos to hosted agents is later; a data policy per quest or repository is later. | — | `SCO > SCO-LATER` |

**The specification and the delivery**

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-36** | CQ-17, DQ-10 | The specification's documents are TomSpecs documents: the Solution Blueprint first and deepened, a detailed document only where a component needs one. The runtime is implemented by hand. | RS-5 | `DEL`, `NFR > NFR-GEN` |
| **D-37** | CQ-1, DQ-13 | The specification is made in a run of the idea-to-todos process on the concept, not in the TomSpecs process. ___check here___ This document is written in a run of the TomSpecs process; see X-7. | — | `CON` |
| **D-38** | CQ-18, DQ-7 | The design is delivered as a complete inventory of the extension's screens, a description per screen and component, and a gallery application. | — | `CLI > CLI-SCREENS` |
| **D-39** | DQ-6 | Two tracks are built in parallel: tac, and the runtime. | — | `DEL` |
| **D-40** | RS-3, RT-5 | The split of the extension starts after the extension's features and the workspace layout are finished. | — | `DEL` |
| **D-41** | CQ-19 | During the split the extension is branched, the new line has its own extension id and working tree, and it refuses to start beside the old one in the same window. | RS-1 | `DEL` |
| **D-42** | CQ-20 | The todos filed before the concept are input; a new set replaces them. | RS-4 | `DEL` |
| **D-43** | RT-8 | The Dart runtime client is the client Tom Forge builds on. | — | `CLI > CLI-PACK` |

## <!--[CON]--> 13 Contradictions

Where sources disagree, and how it is resolved.

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
- **X-3** **A client without a runtime.** S3 (WR-2, WR-6) asks that Webwork
  in a browser or on a phone registers in tac itself, with a Dart client that
  needs no runtime; an earlier answer of the product owner said such a client
  connects "through a server part that runs the runtime for them", with a
  partial direct connection for messaging to be investigated; S1 at first had
  such a client talk to tac directly. **Resolved:** every client reaches tac
  through a runtime; a browser, phone or tablet client uses a runtime on the
  server side (D-27). WR-2 and WR-6 are met differently than asked, and
  Webwork's messaging on the web and the phone comes with that server side
  (`TAC > TAC-WEBWORK`; `SCO > SCO-LATER`, L-8).
- **X-4** **Two scopes of the server.** S6 and S5 plan the full server with
  customers, keys, quotas and an administration interface; S3 (WR-1) asks for
  a small team's server without them. **Resolved:** the full server is built
  first; a small team is that server with one customer (D-22).
- **X-5** **"Group" where a team is meant.** S13 says "a Webwork team is one
  tac group"; S5 uses "agent group" for runtimes that coordinate.
  **Resolved:** a team is people, an agent group is runtimes (D-24); the
  specification uses the two words so, and Webwork is told.
- **X-6** **One `tac/2.0` against stepwise versions.** The earlier plan added
  to the protocol in minor versions, one per capability; S5 § 8 says minor
  versions only add. **Resolved:** one specification `tac/2.0`, built in one
  go, with capabilities announced on connect (D-21).
- **X-7** **How the specification is made.** ___check here___ **Unresolved.**
  S1 § 13.1 and § 14.1 record the product owner's decision that the
  specification "is made in the `idea_to_todos` run on this concept, not in
  the tom_specs process", and that the next step is such a run. This Project
  Idea is Phase 1 of a run of the TomSpecs process. The same source also says
  that the documents are TomSpecs documents, with the Solution Blueprint
  first and deepened and a detailed document only where a component needs one
  (D-36). The two can fit — this run produces the Project Idea and the
  Solution Blueprint and goes deeper inside the Blueprint — or the decision
  has changed. The question on how the specification is made asks.

> **❓ PQ-19 (2026-11-19T09:20+01:00) — How the specification is made:** this Project Idea is written in a run of the TomSpecs process, while your recorded decision says the specification is not made in that process. How do the two fit?
>
> **Context.** In the concept you answered the question how the specification and the todos are produced: "we should try to get in direction of a specification here in the idea2todo run, very detailed todos and todos to create the detailed documents. The process is not the TomSpecs process. Here in the idea we dicuss what we need and how it is split up. Then I can run through individual component documents one by one, e.g. in a askInMd* guided process with you, document (=component) per document." The concept records as the next step "an `idea_to_todos` run with this document as its input document".
>
> Later answers in the same document point the other way:
> - on the structure: "Can't you simply access the SOM tom_specs uses and go through the sections and collect what we'll need for this project and then use this as a basis to move forward by filling out the sections."
> - on the form of the documents: "(a), however never all documents. And maybe we can simply work only on the blueprint and go deeper in there. Nothing prevents from using only the system blue print … it is easy to generate the 12 other document automatically from a system blueprint".
>
> What is happening now: a run of the TomSpecs process has started in this quest, and this Project Idea is its Phase 1. That process goes on with Phase 2 (the Solution Blueprint), Phase 3 (twelve detailed documents in three waves), Phase 4 (code generation), Phase 5 (tests), Phase 6 (the system), Phase 7 (acceptance) and Phase 8 (release), each ended by a gate.
>
> **Why I ask.** The Project Idea's sections on delivery and on the generation units, and the plan of everything after this phase, depend on which of the two it is. The todos that build the product also have to come from somewhere: the TomSpecs process files them in its later phases, the idea process in its last phase.
>
> - **(a)** **This run, to the Solution Blueprint, and deeper inside it.** The TomSpecs process is used for Phase 1 (this Project Idea) and Phase 2 (the Solution Blueprint), and the Blueprint is deepened until it carries the specification. In Phase 3 a detailed document is written only where a component needs one (for example the interface document for the two protocols, the experience design document for the user interface components); the others are left out. Phase 4's code generation is not used; the todos that build the product are derived from the Blueprint and the detailed documents. The idea run on the concept is not started.
> - (b) **Both, one after the other.** This run produces the Project Idea and the Solution Blueprint and stops there. An idea run then takes the Blueprint as its input, splits the work into parts and files the todos, among them the todos that write the detailed documents, which you go through component by component.
> - (c) **The TomSpecs process as it is defined**, through all its phases, with all twelve detailed documents and the code generation where a mapper applies.
> - (d) **The idea run after all:** this run ends with the Project Idea, which becomes one more input of an idea run on the concept.
>
> *Recommendation:* (a) — it keeps one process and one set of documents, and matches your later answers (the Blueprint first and deepened, never all documents); the gates of Phases 2 and 3 then check exactly what you wanted to walk through component by component.
>
> **Answer:**

- **X-8** **The owner of the coordination.** S5, S6 and S16 name a quest
  `agent_coordination` as the owner of tac and of the parallel-work rules;
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
  messages in the coordination repository. Not resolved by a decision: with
  messaging and documents on the server, what of them the GitHub backend
  carries is part of the question on that backend in the first delivery
  (`TAC > TAC-BACKENDS`).
- **X-12** **The runtime server and the lifetime of a runtime.** S1 § 8 has a
  topology in which an always-on machine runs runtimes without a window
  (T6); the decision is that a runtime is started by its host and ends with
  it, with standalone runtimes later (D-15). ___check here___ Not resolved;
  the question on the runtime server asks.

## <!--[RISK]--> 14 Risks and dependencies

### <!--[RISK-RISKS]--> 14.1 Risks

| Id | Risk | Trigger | Source |
| --- | --- | --- | --- |
| **R-1** | **The split of a large extension while it keeps changing.** The engine is entangled with the extension: the queue manager and the model handler are large, and process-wide singletons assume one quest per process. Changes to the old line during the split have to be carried into the new one. | A feature or fix lands in the extension after the split has begun; a stage of the split leaves the extension not working. | S19; S1 § 13.3; S18 |
| **R-2** | **What is specified moves.** The extension's features change while they are described; the descriptions of screens and of engine behaviour go out of date. | A change in the extension to a view or an engine feature that a section here describes. | S1 § 12.3, DQ-7; S17 |
| **R-3** | **Team features nobody else has used.** Teams, invitations, escalation of asks and the review exchange are designed by and for one person with several machines. | The first second person joins a team; a reviewer without a repository takes part in a review. | S1 § 7.3, § 6.6, § 7.7; S9 |
| **R-4** | **Overlap with protocols others maintain.** The runtime protocol covers ground the Agent Client Protocol, A2A, MCP and the vendors' own protocols cover; they change quickly. | A revision of one of them (MCP's revisions of 2025-11 and 2026-07 differ); an agent or editor the product wants to reach speaks only one of them. | S9; S1 § 15.1, § 6.4 |
| **R-5** | **Vendors' interfaces in preview.** The agent SDKs and command lines the agent transports rest on, and every interface for hosted agents, are preview or beta; one hosted agent service was shut down with two months' notice. | A vendor changes or withdraws an interface a transport uses. | S9; S1 § 11.5, § 15.4 |
| **R-6** | **The full server before anybody uses it.** Customers, quotas and the administration interface are built before a first team works on the server. | The first team's use shows needs the full server did not foresee; Webwork's messaging waits for parts it does not need. | S1 § 7.2, CQ-9; S3 |
| **R-7** | **Everything in one go.** tac is built to the whole of `tac/2.0` and Webwork is told the product is built in one go; nothing is used before all of it is there. | An early part proves wrong only when a later part uses it. | S1 § 7.9, WQ-2, WQ-4 |
| **R-8** | **Webwork's messaging on the web and the phone waits.** It comes with the server-side runtime, which is later; until then messaging works on the desktop only. | Webwork's team needs messaging or review on a phone or in a browser before that server side exists. | S1 § 7.10, WQ-1; S13 |
| **R-9** | **Another writer in the repositories.** Other sessions, runs and machines write to the same repositories on one branch while this product is specified and built; uncommitted work of others is in the way of builds and installs. | Two runs touch the same repository; a build or an install runs from a tree another session left changed. | S16; S1 § 10.1 |
| **R-10** | **Leases held by agents.** Others found that locks held by agents are held too long or never given back. | A run ends without releasing its claim; a long run holds a repository. | S9; S1 § 15.2 |
| **R-11** | **No gate before the main branch until the integration step exists.** Until then a broken commit is at once every other session's base. | A run commits a change that breaks a package others build on. | S1 § 10.1, § 10.3 |
| **R-12** | **Nine languages.** Seven of the client packages are tested only through the conformance suite; nobody uses them yet. | A first user of such a client meets what the suite does not cover. | S2 § 3.5; S1 § 12.1 |
| **R-13** | **Two hosts and several runtime versions on one set of workspace files.** A host with an older runtime stops working when the files are migrated. | A host is updated and migrates the files while another host with an older runtime is in use. | S1 § 6.7, § 9 F12 |
| **R-14** | **The product's value depends on others being able to use its parts.** The protocol, the process format and the coordination are entangled with this workspace's conventions. | A user outside this workspace tries to use tac or a client without the rest. | S9; S1 § 15 |

### <!--[RISK-DEPS]--> 14.2 Dependencies

| Id | Depends on | For | State | Source |
| --- | --- | --- | --- | --- |
| **R-15** | The workspace layout restructuring (quest `al_the_bear`, and its part in the extension) | The runtime's locations and configuration layers; the repository record the claims use | The resolver and the layered configuration are built in the extension; the migration of the workspace, the new fleet skills and the cutover are open | S12; S1 § 3.4, § 5.5 |
| **R-16** | The extension's remaining features (quest `vscode_extension`) | The engine being complete before it is extracted | open | S1 § 3.1; S18 |
| **R-17** | Tom Secrets Manager's TypeScript client being published | Resolving `tsm:` references in the runtime and the tac service | built, not yet published | S15; S1 § 3.6 |
| **R-18** | Releases of `tom_todo_model` | The todo fields the claims and touch sets use; every release moves the locks of its many consumers | 3.1.0 today, a further major release planned | S1 § 2.4, § 10.1 |
| **R-19** | Tom Forge's review component in Flutter | The review group of the UI components, shared by Webwork, the quest application and trc | planned in the quest `tom_forge` | S1 § 3.3, § 12.2; S14 |
| **R-20** | The coordination repository and the tac server on the always-on machine (quest `al_the_bear`) | The GitHub backend; the server for the fleet and for a team | open; the server waits for this product | S1 § 2.2, § 3.4 |
| **R-21** | The `tomspecs` tool and the SOM packages | The specification tools the runtime carries | one binary, released; new tools are being added in the quest `tom_specs` | S1 § 3.5 |

## <!--[DEL]--> 15 Delivery

**The order.** (S2 § 4.1; S1 § 13.1; D-40)

1. The VS Code extension's features are finished.
2. The workspace layout is restructured.
3. This specification is written, and the product is built from it. The
   split of the extension starts here.

**Two tracks, in parallel.** (S1 § 13.1, DQ-6; D-39)

| Track | Contains | Depends on the split of the extension |
| --- | --- | --- |
| **tac** | The server, participants and teams, messaging, documents, the tac clients | no |
| **the runtime** | The split, the protocol, the runtime client, the UI components, then the tac client inside the runtime with claims and the integration step | yes |

The two tracks touch different repositories. Webwork and Tom Forge wait for
their parts and progress on their own meanwhile (`LAND > LAND-WAIT`).

**The stable extension during the split.** (S1 § 13.3, CQ-19; D-41)

- The extension is branched; the new line gets its own extension id and is
  worked on in a separate working tree.
- The new extension refuses to start while the old one is active in the same
  window.
- The new one is installed everywhere and activated only in the window used
  for testing, where the current one is deactivated.
- The old extension keeps being changed as needed; its changes are merged
  forward into the new line, or their work is repeated there.

**The documents of the specification.** (S1 § 13.1, CQ-17, DQ-10; D-36)

- The Solution Blueprint comes first, one for the whole system, and the work
  goes deeper inside it.
- A detailed document is written only where a component needs one — for
  example the interface document for the runtime protocol and for TAC, the
  experience design document for the UI components — never all of them.
- They are TomSpecs documents, so the specification tools work on them.
- How this fits the decision that the specification is made in an idea run is
  X-7.

**What is delivered** is the code of the units (`NFR > NFR-GEN`) and the
documents of N-30.

**The todos.** The todos filed before the concept are input; the new set
replaces them, and the entries of other quests that wait on them follow
(S1 § 13.4, CQ-20; D-42).

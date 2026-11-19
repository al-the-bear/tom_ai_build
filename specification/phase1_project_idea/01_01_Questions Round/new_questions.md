# New questions — Phase 1, question round 1

The questions the round's todos derive, by section of the Project Idea, until
the last todo inserts them into the document. Each is written in the question
block form: header `> **❓ <ID> — <topic>:** <question>`, options `> - (a) …`
(the recommended one bold), `> **Answer:**`. Ids: `PQ-<n>`, numbered in the
order they are written here. Every question stands on its own: it quotes what
it refers to, says why it is asked and what each option means.

**Inserted** by the round's last todo: all 19 questions stand in
`tom_ai/ai_build/specification/phase1_project_idea/project_idea.ai_runtime.md`,
each directly after the paragraph or item it asks about; the place is named
under each question below. No two questions ask the same thing, so none was
merged. In the document a question's header also carries the time it was
inserted. One slip was corrected on the way: a stray `**` at the end of
PQ-7's option (c).

## `USR-TEAM` — Owner and review team

> **❓ PQ-1 — Product owner and review team:** who is the product owner of this specification, and who reviews it by default?
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

*Inserted into the Project Idea:* section `USR-TEAM`, after the section's paragraph.

## `RT-RUNS` — Processes and runs

> **❓ PQ-2 — A run and a changed process definition:** when the definition of a process is changed while a run of it is in progress, which definition does the run follow?
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

*Inserted into the Project Idea:* section `RT-RUNS`, after CR.12.

> **❓ PQ-3 — Preconditions of a step:** may a process step refuse to start when what it needs is not there?
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

*Inserted into the Project Idea:* section `RT-RUNS`, after CR.13.

> **❓ PQ-4 — A short path for small changes:** does the product include a short process for a small change, beside the full processes?
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

*Inserted into the Project Idea:* section `RT-RUNS`, after CR.14.

## `RT-PROTO` — The protocol

> **❓ PQ-5 — The shape of the protocol's conversation and questions:** do you confirm the three shapes the concept proposes for the protocol?
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

*Inserted into the Project Idea:* section `RT-PROTO`, after CP.8 (it also asks about CP.7 and about CR.45 in `RT-INSTALL`).

## `RT-VERSIONS` — Versions and compatibility

> **❓ PQ-6 — Migrating the workspace files:** who decides that the files of a workspace are migrated to a new format, when not every runtime that works on them is updated yet?
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

*Inserted into the Project Idea:* section `RT-VERSIONS`, after CP.29.

## `CLI-PACK` — The client packages

> **❓ PQ-7 — Which languages come first:** which of the nine languages' client packages are part of the first delivery?
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

*Inserted into the Project Idea:* section `CLI-PACK`, after CL.1.

## `CLI-UI` — The Flutter UI components

> **❓ PQ-8 — Which components are built first:** in which order are the component groups of the Flutter library built?
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

*Inserted into the Project Idea:* section `CLI-UI`, after the table of CU.6.

## `CLI-TRC` — The supervision application

> **❓ PQ-9 — How the supervision application connects, and where it runs:** does the supervision application have a runtime of its own, and on which platforms does it run in the first version?
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

*Inserted into the Project Idea:* section `CLI-TRC`, after CK.8.

## `TAC-BACKENDS` — Backends and modes

> **❓ PQ-10 — The GitHub backend in the first delivery:** is the backend that keeps the coordination in a GitHub repository still part of the first delivery?
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

*Inserted into the Project Idea:* section `TAC-BACKENDS`, after the table of CA.26.

## `TAC-PEOPLE` — People, teams and identity

> **❓ PQ-11 — Customers, teams and agent groups:** how are a customer, a team and an agent group tied to each other, and who creates the first of each?
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

*Inserted into the Project Idea:* section `TAC-PEOPLE`, after the table of CI.1.

> **❓ PQ-12 — What an owner of a team may do that a member may not:** which rights does a team's owner have?
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

*Inserted into the Project Idea:* section `TAC-PEOPLE`, after CI.5.

> **❓ PQ-13 — Identification without an invitation:** when does a team accept a member who only states a user id and an e-mail address?
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

*Inserted into the Project Idea:* section `TAC-PEOPLE`, after CI.10.

## `PAR-APPROACH` — The approach to parallel work

> **❓ PQ-14 — The integration step and what goes with it:** do you confirm the parts of the approach to parallel work that so far are only proposed?
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

*Inserted into the Project Idea:* section `PAR-APPROACH`, after the section's opening paragraph, before the capabilities it asks about.

## `NFR` — Non-functional expectations

> **❓ PQ-15 — Licence and publication of the packages:** under which licence are the new packages released, and where are they published?
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

*Inserted into the Project Idea:* section `NFR`, after N-29.

## `NFR-TOPO` — Network topologies and key flows

> **❓ PQ-16 — A runtime server and the lifetime of a runtime:** what runs the runtimes on an always-on machine, when a runtime ends with its host?
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

*Inserted into the Project Idea:* section `NFR-TOPO`, after the paragraph on T6 under the table of topologies.

## `NFR-GEN` — Generation units

> **❓ PQ-17 — Mappers or hand-written code, per unit:** for each unit the project builds, does one of the TomSpecs tooling's mappers write code for it, or is it written by hand?
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

*Inserted into the Project Idea:* section `NFR-GEN`, after the section's last paragraph.

> **❓ PQ-18 — Standard descriptions the project publishes:** in which standard forms are the product's interfaces described and published?
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
> - **(a)** **JSON Schema for both protocols; OpenAPI for the coordination protocol's HTTP operations; AsyncAPI for the event stream of the runtime and the message stream of the coordination service.** JSON Schema is the source the clients are generated from; OpenAPI and AsyncAPI are derived from it and published for those who use other tools.
> - (b) **JSON Schema only**, for both protocols. One description, the one the clients are generated from; OpenAPI and AsyncAPI are not published.
> - (c) **JSON Schema for both, and OpenAPI for the coordination protocol's HTTP operations**, no AsyncAPI: the streams are described in the protocol specifications' text.
>
> *Recommendation:* (c) — the HTTP operations of the coordination service are what an outside developer is most likely to call directly, and OpenAPI is what their tools read; the streams are few and well described in text.
>
> **Answer:**

*Inserted into the Project Idea:* section `NFR-GEN`, after the section's last paragraph, following PQ-17.

## `CON` — Contradictions

> **❓ PQ-19 — How the specification is made:** this Project Idea is written in a run of the TomSpecs process, while your recorded decision says the specification is not made in that process. How do the two fit?
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

*Inserted into the Project Idea:* section `CON`, after X-7.

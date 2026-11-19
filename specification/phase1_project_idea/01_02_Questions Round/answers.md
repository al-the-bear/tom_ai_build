# Answers — Phase 1, question round 2

The 19 questions of round 1 (`PQ-1` … `PQ-19`) with the product owner's answers of
2026-11-19, as they stood in the Project Idea before this round took them in.
What each answer did to the text is in `changes.md` beside this file.

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
> **Answer (2026-11-19T10:45+01:00):** (a), owner and reviewer am I, alexis

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
> **Answer (2026-11-19T10:46+01:00):** (a), usually the updates are intended to be used immediately

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
> **Answer (2026-11-19T10:46+01:00):** (a)

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
> **Answer (2026-11-19T10:48+01:00):** File this with concrete proposal in the tom_specs quest. The is already a change mode in the tom_specs process, but it's still very heavy. A quick path for smaller changes seems appropriate. Check the tom_specs process for the current change/revision mode, so you don't miss any important steps for the new and shortened process.

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
> **Answer (2026-11-19T10:54+01:00):** I think we have two ways today: (1) review outside of a turn, the process waits until I prompt for continuation (2) the ask tool to ask individual questions (the agent can put ids there if he wants) (3) Asking in a document using the askInMd tool, which has the questions inside a document and usually with a unique questions id. Isn't that already the three things? We are also working on a review subprocess to be started at review points in (1). What are we missing? It seems we are covering all of that.

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
> **Answer (2026-11-19T11:01+01:00):** 1. every host install the runtime if none is installed and offers updating it in the corresponding section of the app (which might offer other things to install/uninstall).
> 2. if there is a runtime it uses it and if this is a too new runtime it disables all features that would use it or refuses to start and asks the user to upgrade to a new application version (that hopefully already exists)
> 3. upgrade only happens after having been asked to. This happens actively if the runtime detects a workspace format it can't handle, because it has been upgraded already from somewhere else.
> 4. if the runtime finds a workspace that is older that what it supports it must offer to migrate to the new version or to downgrade to an older version of the runtime that can work with the old format (if there is one that is compatible with the application). If there is no compatible version it says so and only offers to upgrade the workspace.
> 5. I'm assuming that we usually upgrade runtime and workspace when the first host has updated and we try to keep hosts to be compatible with several runtime versions through the SDK layer and protocol backwards compatibility in the evolution of the runtime.

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
> **Answer (2026-11-19T11:01+01:00):** (b)

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
> **Answer (2026-11-19T11:04+01:00):** We build in the order that will get us to the finished full product fastest. We should consider working in parallel for our own todos here, so they run in two runs in parallel. I queued some todos in vscode extension that should help with this for waiting if a todos is blocked and continuing once it is unblocked (verify this is complete in the todos queued, in the todo list or in the recently done todos (today). If something is missing, add a vscimpb* todo to vscode extension

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
> **Answer (2026-11-19T11:07+01:00):** (b), I want to make sure we get the architecture right for apps on phones and tablets. This will require connecting to an internet tac or on the LAN/VPN. We should check for testing if our VPN can be used from iphone and android, but we also need to cover the internet case as this is very relevant to check on the road what is going on and answer questions while away. Of course this must be secure, so probably there must be some pairing process to get a device-specific key etc.

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
> **Answer (2026-11-19T11:08+01:00):** (a)

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
> **Answer (2026-11-19T11:10+01:00):** Explain this in more details, how do agent groups compare with our quests with their run and prompts? I can only decide what we need here if I understand what you are proposed in detail. What IS an agent group?

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
> **Answer (2026-11-19T11:12+01:00):** (a), the last row depends on the result of the previous question. I'd say team member can create or delete their own agent groups, but this depends on our definitions for the last question.

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
> **Answer (2026-11-19T11:15+01:00):** (a), setting per server in the server configuration, a server either only works with strict invitation/identity check or completely without it, so it is open. While me being alone on the VPN only the open server is fine, once I open to the internet or there are other people there must be a secure link (think if internet access is secured enough with HTTPS + the token). I think identification must be strict for all internet access, non-configurable.

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
> **Answer (2026-11-19T11:19+01:00):** (a), but (1) must have a strict mode that blocks all the time, just as we need to have a non-worktree mode which always requires strict locks while a todo executes.

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
> **Answer (2026-11-19T11:20+01:00):** (a), for now we publish only to pub.dev and to our tom_binaries repo. We'll later publish to more official repos and the app stores.

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
> **Answer (2026-11-19T11:23+01:00):** (a), however there can already be a server for a web application or apps that hosts one runtime per client in the current model. The server would be permanent, the runtimes start and die with the apps/users. Fully standalone runtime will come later, if needed. For me this is just a special case where a longterm service hosts a runtime for a long time and we're not planning this service now.

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
> **Answer (2026-11-19T11:26+01:00):** I think this is complicated for this project as we have multiple components we're creating. For some the mapping/emitters might be useful, for other we start directly from the JSON/YAML output. I actually suggest to name at the beginning of phase 4 which mapping we need for each areas of the specification and how to proceed with it for each component and see if there are missing generators we should build in phase 4 to keep the process as automated as possible. I'd like to be able to run through regeneration quickly when we have changes later.

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
> **Answer (2026-11-19T11:28+01:00):** Let's decide this in phase 4, we also need API docs for the SDKs and (handwritten) user and programmer's guides.

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
> **Answer (2026-11-19T11:30+01:00):** (c), make suggestions if you think we can skip some of the steps of a phase, but we should go through the normal process with all its phases. You can do this while we proceed.

## Answers to the questions of this round

The product owner's answers of 2026-11-19 to `PQ-20`, `PQ-21` and `PQ-22`, given in the review of this round, as they stood before they were taken in.

> **❓ PQ-22 (2026-11-19T18:45+01:00) — Your entry in the review team:** how are you written in the review team of the specification documents?
>
> **Context.** You answered that you are the owner and the only reviewer: "owner and reviewer am I, alexis". The Solution Blueprint records its review team as a list of members, each with a member id (lowercase letters, digits and `_`), a display name and a role; the owner is marked. The member id is what review marks and answers are signed with; the display name is what the documents show. From your answer I took the member id `alexis` and the role "product owner". The display name was not given.
>
> **Why I ask.** The first step of the next phase writes this entry into the Blueprint, and review copies are named after the member id.
>
> - **(a)** Member id `alexis`, display name "Alexis", role "Product owner". No e-mail address is stored.
> - (b) The same, with another display name or an e-mail address — write them in the answer.
>
> *Recommendation:* (a).
>
> **Answer (2026-11-19T19:06+01:00):** (a)

> **❓ PQ-21 (2026-11-19T18:45+01:00) — Three shapes of the runtime's protocol:** do you confirm how the runtime tells a host about a conversation, about a question, and when it lets go of a run?
>
> **Context.** This asks the earlier question again, in other words. It is **not** about the ways an agent asks you something. Those stay exactly as they are: a review outside a turn, the tool that asks single questions, and questions inside a document. You named them in your answer, and nothing is missing there.
>
> The question is about the **wire between a runtime and a host**. Today the engine and the views are one program (the VS Code extension), so the engine just calls the view. Once the runtime is a program of its own, a host (Webforge, Webwork, the supervision application) is a separate program that only receives messages. Three things about those messages are so far only proposed:
>
> 1. **How a conversation arrives.** Today the engine writes a flat trail: one entry after another (text, a tool call, a result). Proposed: the runtime sends a conversation in three levels. A *thread* is a session. A *turn* is one prompt with everything that answers it. An *item* is one piece of a turn: a text, a piece of reasoning, a tool call, a question, a result. Each item is announced when it starts, streamed in pieces, and closed. Example of what a host receives for one prompt: `turn started` → `item started (reasoning)` … `item completed` → `item started (tool call: read file)` → `item completed (result)` → `item started (text)` → `delta "The file…"` → `delta " holds…"` → `item completed` → `turn completed (usage)`. A host can then draw a tool card or a reasoning block without guessing where it begins and ends, and can steer or interrupt a turn by its id.
> 2. **How a question arrives.** Today each way of asking has its own code path to its own panel. Proposed: whatever the way of asking, the runtime sends the host **one record** with the same fields: an id; a kind (question, pick from a list, a document to answer in, approval of a tool call, approval of a plan, a decision, a gate result); the allowed responses; an optional form of the response; a default, if one was declared; a deadline. Example: your gate decision arrives as `{id, kind: gate, responses: [passed, failed], deadline: none}`, and a tool approval as `{id, kind: tool approval, responses: [allow, deny], default: deny}`. A host needs one inbox and one way to answer instead of seven, and a question can be passed on to another device or person because it is a record.
> 3. **When a run is let go.** A runtime holds every run of its quest in memory. Proposed: a run that nobody watches (no host is subscribed to it) and that has nothing queued is unloaded, and loaded again from its files when someone opens it or queues something. Example: Webwork has one run per area; the runs of areas you have not opened today cost nothing.
>
> **Why I ask.** The protocol specification is written from these shapes, and every client library in every language and every UI component is built on them. Changing them later changes all of those.
>
> - **(a)** **All three as described.**
> - (b) **The question record and the unloading, but the conversation stays a flat trail** as today. Less to change in the engine; every host then has to work out by itself where a turn and a tool call begin and end, in every language.
> - (c) **Different** — say which of the three, and how.
>
> *Recommendation:* (a) — the three levels are what the other agent protocols have settled on, so the UI components and an adapter to those protocols get simpler.
>
> **Answer (2026-11-19T19:15+01:00):** Well, as we are talking about the link between client and runtime I was assuming that we build an API that supports callback, so the agents' tool the agents call in the runtime can call right into the client/host to trigger the necessary UI actions. This is a bit similar to what the CLI server in the extension does so the VS Code APIs can be used from Dart.
> Of course there is a wire protocol for this, usually using JSON structures. The details will reflect what the tools need. We may need to work out object models for the various entities, for this the existing schemas in the workspace for the extension will be helpful.
> run loading/unloading sounds like a reasonable mechanism, but might bring a lot of complexity. As runs get loaded again when the runtime restart when the client starts this might be simpler than expected though. I'm not sure if this needs enough memory to warrant the effort.

> **❓ PQ-20 (2026-11-19T18:45+01:00) — Who an agent group belongs to:** on a server, who creates an agent group, and which runtimes may join it?
>
> **Context.** The section above this question explains what an agent group is: the set of runtimes that share repositories and therefore share one pool of leases, across quests and machines. A **team** is people. A **customer** is whoever a server serves (an organisation, or you); the server keeps access keys and quotas per customer. You decided that a team and an agent group are two different things, that "a team has owners; the first is whoever created the team", and you wrote about this question: "I'd say team member can create or delete their own agent groups, but this depends on our definitions."
>
> Three things are not said anywhere: whether an agent group belongs to a customer, to a team or to a person; who creates the first customer on a new server; and which runtimes may join a group.
>
> **Why I ask.** The Solution Blueprint has an information model (which records exist and how they point to each other) and a security model (who may call which operation). Both need this. It also decides what the first day on a new server looks like.
>
> - **(a)** **A group belongs to the customer and is opened to teams; a team's owner creates it.** Whoever installs the server creates the first customer and its first access key from the server's command line. With that key a person creates a team and is its first owner. A team's owner creates an agent group; it belongs to the customer. A team lists the agent groups its members' runtimes may join, and a group may be listed by several teams of the same customer, so two teams that share repositories share the leases on them. A runtime joins a group with its person's token of a team that lists the group. For you: one customer, one team with you in it, one agent group for all your machines.
> - (b) **As (a), and every member may create agent groups**, as you suggested: a member creates a group, it is listed in that member's team, and the member who created it (or an owner) may delete it. More freedom; a team can end up with several groups over the same repositories, whose runtimes then do not see each other's leases — the one thing a group is for.
> - (c) **A group belongs to exactly one team.** A team's owner creates its groups, and only that team's members' runtimes join them. Simpler to explain. Two teams working on the same repositories cannot share leases.
> - (d) **Groups stay as today:** no owner, no creation; any runtime with the customer's key that names a group is in it. Teams only concern messaging and remote control. Nothing to administer; nothing keeps a runtime out of a group.
>
> *Recommendation:* (a) — a group only works when everyone who writes to a repository is in the same one, so creating one should be a deliberate act of an owner, and it must be possible for two teams to share one.
>
> **Answer (2026-11-19T19:20+01:00):** This doesn't seem to match the setup we'll have: each runtime calls the LLM/direct APIs or the SDK directly, just like VS Code does, no agent groups involved. The runtime just splits that part of VS Code into the runtime, otherwise this will be identical.
> The sequence with joining a server, then creating a team makes sense to me. Quest information and other AI state always live on the machine of the host and is accessed directly using the runtime either through the tool of the runtime or the tools of the SDKs (Anthropic, Github etc. SDKs).
> Every runtime is linked to a single quest. Hosts with several quests start several runtime processes.
> I don't see any groups of agent here.

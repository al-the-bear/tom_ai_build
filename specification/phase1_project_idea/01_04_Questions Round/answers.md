# Answers — Phase 1, question round 4

**Round:** 4 · **Extracted:** 2026-11-20 · **Document:** `../project_idea.ai_runtime.md` as round 3 and the product owner's review left it.

The change marks of round 3 (432 substitutions, 13 additions, 1 deletion, 7 remarks) carried no comment and no rejection; all were accepted before this extraction (the document before: `project_idea.before_marks.md`). No reviewer comment block is in the document.

## The product owner's instruction for this round

> Please revise the document once more and make it consistent. Check what todos (current and recently archived) and planning documents are in vscode_extension, webwork, tom forge and al_the_bear and look for further input for the project idea, to complete it. You may suggest your improvement ideas, too.

## Questions and answers

### PQ-24 — what waits while an ask is open

- **Section:** `RT > RT-ASKS`
- **Question:** When an item's execution asks a person something, does only that execution wait, or the whole run (the queue) it belongs to?
- **Options:**
  - **(a)** Only the execution that asked waits. The run goes on with its other items that do not depend on the waiting one (a walk with its next independent todo), and the other runs go on. CP.21 would read "the execution that asked waits; its run goes on with the items that do not depend on it, and the other runs go on"; CP.9 "the execution resumes when the answer arrives"; CP.22 "the answer returns to the execution that asked". One open question then never stops a run.
  - (b) The run that asked waits as a whole: nothing further is sent from its queue until the answer arrives; only the other runs go on. CP.21 would lose "the rest of the queue" and the walk clause. Simpler to follow, but one unanswered ask holds a run for as long as the escalation chain takes.
  - (c) The session waits: the run goes on only with items that are executed in another session; items queued for the same session wait behind the ask. CP.21 would say so. This follows from CR.15 (a session carries one item at a time) and is between (a) and (b).
- **Answer (2026-11-20T15:26+01:00), verbatim:** (b), please review the recently done todo and currently existing todos in vscode extension for more details, there have been some important additions and also look at al_the_bear for a planned restructuring of the _ai folder and an updated and for now definite approach to quests in repos (which I'd consider the standard from now on).

### PQ-25 — "new conversation" and the session

- **Section:** `RT > RT-QUEUE`
- **Question:** When a run starts a new conversation with the model, is that a new session, or the same session starting over?
- **Options:**
  - **(a)** The session stays and starts over: the same named session begins a new conversation with the model, with empty history; what was said before stays in the trail. CR.18 would read "A run can start a session over: the next prompt starts without the earlier context …", and the glossary would define a session as a named line of conversation with a model that can be started over.
  - (b) A new session is created: "new conversation" makes a new named session in the run and the run's next prompt is executed in it; the old session stays, with its history. CR.18 would say so, and a host would have to show and name the sessions of a run.
  - (c) Both exist as separate commands: starting a session over, and creating a new session.
- **Answer (2026-11-20T15:22+01:00), verbatim:** (a)

### PQ-26 — who uses the tac client SDK besides runtimes

- **Section:** `CLI > CLI-PACK`
- **Question:** Which "servers" use the tac client SDK: the runtime host server itself, or none besides the runtimes it starts?
- **Options:**
  - **(a)** No server uses it: CL.11 reads "The tac client SDK is used by runtimes and tools." A runtime host server reaches tac only through the runtimes it starts; it checks a connecting application against its own configuration or by starting the runtime, which then presents the user's team token. tac's participants stay users and runtimes.
  - (b) The runtime host server uses it too: CL.11 reads "… by runtimes, runtime host servers and tools." The runtime host server connects to tac itself (for example to check a team token before it starts a runtime, or to publish its address as an endpoint). tac then knows a third kind of program, and `TAC` needs an item saying what a runtime host server may do there.
  - (c) Leave the word open in Phase 1: CL.11 reads "… by runtimes and tools, and by other programs of ours where they need tac", and the Solution Blueprint decides for the runtime host server.
- **Answer (2026-11-20T15:28+01:00), verbatim:** (a)

### PQ-27 — what becomes of the "session" record of `tac/1.0`

- **Section:** `TAC > TAC-COORD`
- **Question:** Does tac keep a record of its own for whoever holds leases, and what replaces the three places where the Project Idea still says "session" for it?
- **Options:**
  - **(a)** tac keeps no such record: a lease carries its holder (the runtime, the quest, the run, the item, the machine, the workspace), and that is all. CA.20 would announce "an execution started or ended"; CA.26 would read "leases and endpoints as refs"; CA.29 would drop "closing a session". Simplest; the notification about executions stays, because the others want to know what a runtime works on.
  - (b) tac keeps one record per execution that holds leases, under a new name ("holder record"): opened with the first claim of an execution, closed when the execution ends. The three places keep their entry with that name. Nearest to what is built, one more thing to specify.
  - (c) As (a), and CA.20 loses the notification altogether: what an execution works on is visible from its leases, and nothing separate is announced.
- **Answer (2026-11-20T15:30+01:00), verbatim:** (a)

### PQ-28 — which server a paired device reaches from the internet

- **Section:** `TAC > TAC-CRYPT`
- **Question:** When a phone or tablet reaches "the server" from the internet, is that the tac server (through its relay) or the runtime host server?
- **Options:**
  - **(a)** The device reaches the tac server, through its relay. The relay also forwards the runtime's protocol to the runtime host server; pairing is with the tac server, which holds the device keys and is the only program reachable from the internet. CI.18 and CI.19 would say "tac server" throughout, and CA.30 would add the runtime's protocol to what the relay carries.
  - (b) The device reaches the runtime host server directly. It is reachable from the internet, holds the device keys and checks them; the tac server need not be reachable from outside for phones. CI.18 would say "runtime host server", and CI.19's "the server and its relay" would be the only place that means the tac server.
  - (c) Both run on one machine behind one reverse proxy, and "the server" in CI.18 and CI.19 becomes "the team's server machine": one address, the proxy routes TAC to the tac server and the runtime's protocol to the runtime host server; pairing is with the tac server.
- **Answer (2026-11-20T15:46+01:00), verbatim:** There is no given solution for this now. I assume the runtime cannot run directly in mobile devices, so there will be an additional relay which connect to a runtime on behalf of the device to participate in the overall scenario. This means there would be a remote runtime client SDK that connects to a remote runtime service running on a server. That remote runtime service would then connect to the tac as usual from the server. For the web scenario we'll need a HTTP-based service, maybe this can be one and the same as what is used by mobile devices. So I suggest we call the component web runtime client SDK and web runtime service, being used in mobile apps and from Flutter-base (or non-Flutter) web applications. We'll provide a Dart and a JS/TS web runtime client SDK for easy and consistent integration.

### PQ-29 — the personal team with the GitHub backend

- **Section:** `TAC > TAC-PEOPLE > TAC-GROUPS`
- **Question:** Which team do a user's runtimes on several machines belong to when the user coordinates through the GitHub backend, without a tac server?
- **Options:**
  - **(a)** The personal team covers both backends that work without a tac server. Its team runtimes are the user's runtimes on one machine (local backend) or on all machines that use the same coordination repository (GitHub backend). The glossary entry would read "… without a tac server (the local or the GitHub backend): the user is its only member, and the user's runtimes, on the machine or on all machines that share the coordination repository, are its team runtimes." T3 stays as it is.
  - (b) The personal team is per machine, as the glossary says. With the GitHub backend the user's machines share leases and endpoints without being one team; T3 would say "the runtimes on them coordinate their leases through the GitHub backend", and "team runtimes" would not be used for it. The supervision application then shows one personal team per machine.
  - (c) The GitHub backend gets a named team of its own kind: the coordination repository names the team, and the user is its only member. The personal team stays the local backend's. One more record to describe in `TAC`.
- **Answer (2026-11-20T15:38+01:00), verbatim:** The git-based tac service must support simple teams of multiple members, too, besides a single-member personal team, the local implementation works only on a single machine.

### PQ-30 — what the review application is, and how it reaches tac

- **Section:** `TAC > TAC-PEOPLE`
- **Question:** Is the "review application" the glossary names a product of this project, and how does it reach tac while it is not connected to a runtime?
- **Options:**
  - **(a)** There is no review application of its own in the first version. Reviewers use an application that contains the review component — Webwork on the desktop, Tom Forge's quest application, or the supervision application, also on a phone or a tablet — and each reaches tac through its runtime, as CI.4 says. The glossary's "review application" stays as the name of a possible later application. CA.28 would lose "tac clients in a browser" for the first version (kept as what the tac server can answer later), and `SCO > SCO-LATER` would get a line for a review application of its own.
  - (b) The review application is a product of this project in the first version: a small application for reviewers (in a browser and on a phone) with the review component and messaging. It reaches tac through a runtime on a runtime host server like every such application, so CI.4 holds without exception and the glossary's "will only later connect to a runtime" is dropped. It is added to the scope, to the hosts of the first version and to the generation units; CA.28 loses "tac clients in a browser".
  - (c) The review application is a product of this project and, until it is connected to a runtime, it speaks to tac directly as a tac client in a browser. CI.4 gets this one exception (messaging and the review exchange only), CA.28 stays, and tac's participants then include a user's application without a runtime. This reopens what was decided for Webwork (every application through a runtime).
- **Answer (2026-11-20T15:35+01:00), verbatim:** (a), the review application will never be part of the ai_runtime project. It is currently integrated into the VS Code Extension and will later completed with Webwork and WebForge, first just on desktop, later with a web version. However, this is none of our concern here. An application that needs to connect to tac will go through a runtime and use the runtime client SDK. This can be either webwork directly or the documents reach webwork indirectly. I'm not excluding that there may come additional services that use tac directly (through the tac client SDK), this could be useful to use only some aspects of tac, like messaging. This isn't planned for the moment. For the moment messaging will be in Webwork through the runtime and we'll add messaging into the VS Code extension once the ai runtime is build.

### PQ-31 — claiming a folder of the `_ai` state

- **Section:** `TAC > TAC-COORD`
- **Question:** When a todo names a folder of the `_ai` state, what does its runtime claim: a part of a repository like any other, or nothing?
- **Options:**
  - **(a)** It is a part of a repository like any other. CA.17 would read "A runtime claims a part of the `_ai` state's repository for a todo only when the todo names it among its resources (for example `al-the-bear/tom_agent_state#quests/ai_runtime/specification/**`); todo state and journals are never named." CA.9 stays: two kinds, and the old kind "folder of the `_ai` state" is not used.
  - (b) Nothing of the `_ai` state is claimed in the first version. CA.17 loses its last sentence; two todos that rewrite the same document in a quest are kept apart by agreement, as today.
  - (c) The old kind is used after all: CA.9 would name three kinds in use (a whole repository, a part of one, a folder of the `_ai` state), and CA.17 stays as it is.
- **Answer (2026-11-20T15:30+01:00), verbatim:** (a), we may run into other types of resources in the future, but for now that is what we need. Using a prefix git:... we can have as many notations as needed and introduce them as they come.

### PQ-32 — "pairing" used for two things

- **Section:** `RT > RT-SECRETS`
- **Question:** Should "pairing" be kept for devices only, with another word for the one-time approval of the runtime and of tac by Tom Secrets Manager?
- **Options:**
  - **(a)** "Pairing" is used for devices only. For Tom Secrets Manager the text says "approved by": CS.9 would read "The runtime is approved by the Tom Secrets Manager service once, as a program of its own. A setup guide describes the approval."; U-7 "have the tac server approved by Tom Secrets Manager"; D-19 and N-30 likewise.
  - (b) Both uses stay, and the glossary gets a second entry: "pairing (with Tom Secrets Manager): the one-time approval of a program as a reader of secrets".
  - (c) Both uses stay and the glossary is not changed: the context makes clear which is meant.
- **Answer (2026-11-20T15:23+01:00), verbatim:** (a)

### PQ-33 — terms the document uses that the glossary does not list

- **Section:** `GLO`
- **Question:** Should the glossary get entries for the further words the document uses in a fixed sense, and are the two definitions proposed here for "profile" and "coordinator" right?
- **Options:**
  - **(a)** All of them get a glossary entry, in a further table "Further terms of this document", each with the wording of the item named above, and "profile" and "coordinator" with the two definitions proposed here (or as corrected in the answer). The terminology document (S21) gets the same entries, so glossary and terminology stay equal.
  - (b) Only "profile" and "coordinator" get an entry, because they are defined nowhere; the others stay defined by their items.
  - (c) The glossary stays the agreed terminology and nothing is added; "profile" and "coordinator" are explained in the items that use them first (CR.22 and CV.12).
- **Answer (2026-11-20T15:22+01:00), verbatim:** (a)

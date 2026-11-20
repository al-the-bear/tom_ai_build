# Changes — Phase 1, question round 3 (terminology pass)

The round's summary first (written by `p1s1r3-7`), then one section per todo of the round, as each
appended it.

## Summary of the round

The Project Idea (`../project_idea.ai_runtime.md`) was read part by part against the agreed
terminology (`_ai/quests/ai_runtime/ai_runtime_terminology.md` § 2) and then as a whole. Every
change is an inline review mark. The document now carries **453 marks**: 432 substitutions, 13
additions, 1 deletion and 7 remarks. No id changed, and no item changed in what it demands, with
the two exceptions named below, each of which § 2 decides.

**Changes per part**

| Todo | Part | Marks | Mainly |
| --- | --- | --- | --- |
| `p1s1r3-1` | `ABOUT`, `SRC`, `VIS`, `USR`, `SCO`, `LAND` | 62 | client SDK; client and server with their kind; owner qualified; person → user |
| `p1s1r3-2` | `RT` | 48 | runtime client, runtime client SDK; items are "executed"; the outside program of an agent transport is not an agent; file lock |
| `p1s1r3-3` | `CLI` | 36 and 1 remark | client SDK; team runtimes; runtime host server |
| `p1s1r3-4` | `TAC` | 122 and 5 remarks | tac server, tac client; person → user or member; team owner; claim and lease; the heading of `TAC-GROUPS` |
| `p1s1r3-5` | `PAR`, `NFR` | 81 | run → execution; client SDK; tac server; team runtimes; T8 in the wording of CR.46; the known leftover in `NFR-TOPO` corrected |
| `p1s1r3-6` | `DEC`, `CON`, `RISK`, `DEL` | 82 and 1 remark | the same words in the short forms of the decisions, contradictions and risks |
| `p1s1r3-7` | the whole document | 15 | alignment between the parts; the status lines; one question answered by § 2 applied |

**Two changes that are more than a word,** each because § 2 decides it: CI.13 (remote control only
from the home team of a runtime's quest; `p1s1r3-4`, with a remark in the text) and CW.19 / F7
(work from another team is a todo offer; `p1s1r3-7`, below).

**The glossary** (`GLO`) equals terminology § 2 in content: all 70 table rows of § 2.1 … § 2.6 are
in `GLO` with the same text, nothing in `GLO` is beyond them, and the list of words not used is
the list of § 2.6. `GLO` needed no change.

**Remaining uses, checked** (the whole text as it reads with the marks accepted, without `GLO` and
without the question blocks; every hit was read in its sentence):

| Word | Hits left | Why they stay |
| --- | --- | --- |
| agent group, tac group | 6 | CA.39 (what `tac/1.0` calls it, said once); D-24 and D-60 (in quotes: the word that is no longer used); X-5 (its title and the quotations of S5 and S13) |
| group | 35 (6 of them the row above, 5 in the ids `TAC-GROUPS` and `USR-GROUPS`) | group of todos, todo groups, group items (E-1, CR.2, CR.10, CR.13, CR.15, CR.19, CL.5, CW.9); component groups (CU.6, the inventory, R-19, `DEL`); "user group" (the TomSpecs name of `U-<n>`); "a group of users" (CI.1, D-24, X-5: the glossary's own definition of team); "two groups of quests" (CA.44, the glossary's wording of visible); "its group id" (CA.39, a name of `tac/1.0`); the verb in CT.6 |
| customer | 3 | CA.27 and X-4 (in quotes: the word of `tac/1.0`, S5 and S6); D-60 (the list of replaced words) |
| grant | 1 | D-60 (the list of replaced words) |
| lock | 10 | file locks on one machine (CR.38, CP.29, N-8, F12 — now all "file lock"); the locked vault of Tom Secrets Manager (CS.10, twice); "locks" in quotes for what others reported (R-10); lock files `pubspec.lock` (R-18, twice); D-60 (the list of replaced words). The other hits of the letters are "block", "unblock", "clock" |
| request | 29 | pull request (5); timed requests, the engine's feature (5); reverse requests, a kind of protocol message (3); permission requests of the Agent Client Protocol (1); review request and decision request, message kinds of § 2.5 (6); request id, the protocol field (2); HTTP requests (CA.28, CI.8); "on request" (CR.43); a request to another quest, something asked of it (P-13 twice, CW.22); D-60 (the list of replaced words). None is a claim |
| touch set | 1 | D-60 (the list of replaced words) |
| unit | 25 | generation units (`ABOUT-READ`, `NFR-GEN`, D-36, D-57, `DEL`: 17); "unit" in general speech (`VIS`: "does not fit that unit", "the unit of work is the project"; CW.11 "the unit of review"); record names of `tac/1.0` and S5, said as such (E-3 twice, CA.16, D-59, X-15); D-60 |
| session | 54 | the session of a run, a conversation with a model (the agreed sense): `VIS`, `SCO`, E-1, E-2, CR.2, CR.6, CR.8, CR.15, CR.21, CR.31, CP.3, CP.7, CP.35, CT.1, CS.17, CU.6, SC-9, SC-14 … SC-16, CA.17, CA.39, CW.11, CW.18, CW.23, CQ.3, F2; "coding session" (`VIS`, twice); today's working sessions on shared clones (P-5, P-6, P-9, R-9, R-11); CA.8 (says the word is not used for a holder); the `tac/1.0` record: E-3 (said as such), and CA.20, CA.26, CA.29, X-11, each with a remark, open under PQ-27 |
| client without "runtime" / "tac" before it | 32 | the Agent Client Protocol and its two roles (`SCO`, CR.30, CR.31, D-8, R-4: 7); Tom Secrets Manager's clients and its client protocol (S15, U-13, E-6: 7); the MCP client (not matched as bare); the client for local models (CS.12, twice); today's Dart client of the extension's script server (E-1, CL.10 twice); "client and agent protocols" (S9, the research topic); the kind "client" of the register of generation units (`NFR-GEN`: 6) and mapper names (2); the title of WR-6, quoted from S3; `part-client-and-backends` (a section name of S6, twice); D-60 (the term named) |
| server without its kind before it | 31 | CI.18 and CI.19 (8), kept bare with a remark, open under PQ-28; CL.11 "servers", with a remark, open under PQ-26; Webwork's own server side, and "the server side of" an application (L-8, CR.46, the row WR-6, D-27, X-3, X-14, R-8: 8); the kind "server" of the register of generation units and its explanation (`NFR-GEN`: 5), "the server mode" of `tom_tac_service` (G-2) and mapper names (4); the title of WR-1, quoted from S3; "a server part", the product owner's quoted answer (X-3); "the Agent SDK server of today" (D-16, the name of today's program); D-60 (the term named) |
| owner without its kind before it | 11 | qualified after the word: "the owner of the quest", "the owners of the team" (CP.17), "a team's owners" (CS.4), "an owner of the team" (CA.30), "An owner of a team" (D-53), "Owner of the review team" (`USR-TEAM`); "the product owner's" across a line break (`ABOUT-READ`, CP.7); `<owner>/<repository>`, the form of a resource name (CA.10, twice) |
| client package, client library | 0 | — |
| API package | 1 | D-2, a quotation of FO-19 |
| person, people | 73 (18 of them in the id `TAC-PEOPLE`, 3 in the name of the area `CI` and its heading) | any human, not someone using an application: who an ask goes to and its chain (CP.8, CP.9, CP.17 … CP.19, CP.22, the closing line of `RT-ASKS`, N-15, F5); "a runtime's person", "the person it belongs to", "one runtime belongs to exactly one person" (CR.7, CA.3, CI.2, CI.3, CI.12, CA.40, D-24, D-26); only a person frees a stale lease (CA.13, N-13); "a single person" in the definition of account (CA.27); whoever is invited or joins a tac server and is not a user yet (CI.5, CI.6, CI.20, D-59, R-3); the agreed wording of todo offer (CW.26, three times); `VIS`, P-2, P-3, L-3, D-20 (people outside the applications or the team); U-1, CW.2, R-3 "one person"; CW.15, N-34, `DEL` "a person" who reviews, starts a build, or is not needed; the lead-in of `PAR`, R-13; "people", the name of a component (CU.6); D-60 (the term named) |
| app | 0 | — |

**The same word for the same thing across the parts** was checked for: repository server; runtime
host server and "connected application"; runtime process; standalone runtime; team runtimes;
client SDK, runtime client SDK, tac client SDK; file lock; "the runtime claims … for a todo"; user
against person in sentences that say the same thing in two parts. What differed is aligned
(`p1s1r3-7` below).

**References and marks:** every section-id chain names existing section ids, every item id that is
referred to is defined, no chain is broken across lines, and the document has no link that uses a
heading title as an anchor (so the three changed titles — `CLI`, `CLI-PACK`, `TAC-GROUPS` — left
nothing stale). Every `{~~` has exactly one `~>` and its `~~}`, every `{++`, `{--` and `{>>` its
closing mark, and none is nested or stray.

**Questions asked: 10, PQ-24 … PQ-33**, each inserted in the Project Idea directly after the item
it concerns, in the self-contained form.

| Id | Place | Topic |
| --- | --- | --- |
| PQ-24 | `RT > RT-ASKS`, after CP.21 | what waits while an ask is open: the execution or the run |
| PQ-25 | `RT > RT-QUEUE`, after CR.18 | "new conversation": the same session starting over, or a new session |
| PQ-26 | `CLI > CLI-PACK`, after CL.11 | who uses the tac client SDK besides runtimes ("servers") |
| PQ-27 | `TAC > TAC-COORD`, after CA.20 | what becomes of the `session` record of `tac/1.0` |
| PQ-28 | `TAC > TAC-CRYPT`, after CI.19 | which server a paired device reaches from the internet |
| PQ-29 | `TAC > TAC-PEOPLE > TAC-GROUPS`, after CA.39 | the personal team with the GitHub backend |
| PQ-30 | `TAC > TAC-PEOPLE`, after CI.4 | what the review application is, and how it reaches tac |
| PQ-31 | `TAC > TAC-COORD`, after CA.17 | claiming a folder of the `_ai` state (CA.9 against CA.17) |
| PQ-32 | `RT > RT-SECRETS`, after CS.9 | "pairing" used for devices and for Tom Secrets Manager |
| PQ-33 | `GLO`, after its last table | terms the document uses that the glossary does not list |

**One question dropped because § 2 answers it:** the question `p1s1r3-5` raised as PQ-29
("accepted" for work sent to another quest, inside a team and across teams). See `p1s1r3-7` below.


## p1s1r3-1 — the framing sections (`ABOUT`, `SRC`, `VIS`, `USR`, `SCO`, `LAND`)

**62 marked changes:** 61 substitutions (`{~~old~>new~~}`) and 1 addition (`{++…++}`); no
deletion. No id, reference chain or source citation was changed; `GLO` and everything from `RT` on
are untouched.

| Kind | Count | What became what |
| --- | --- | --- |
| client SDK | 12 | "client packages", "client libraries", "a client package", "clients" (for the libraries), "the Dart client", "runtime client and tac client" (as what is built) → client SDK, runtime client SDK, tac client SDK. Places: `ABOUT` (Product row, area `CL`), `SRC` S1, `VIS > VIS-SYSTEM` (component table), V-4, U-6, `SCO > SCO-IN` (`CL` row), O-5, E-10, E-15 (E-16 is counted under "runtime is not a server") |
| client with its kind | 6 | bare "client" → tac client (S6, E-3), MCP client (`CT` row), runtime client (L-5); "a client" of Tom Secrets Manager → "one of its clients", "the client protocol" → "its client protocol" (S15) |
| server with its kind | 13 | bare "server" → tac server (U-3, U-7 twice, `CA` and `CI` rows, L-3, L-11 twice, E-17); "no server mode" → "no tac server" (E-12); "a server that runs one runtime per client" and "server-side runtime" → runtime host server (`VIS > VIS-SYSTEM`, L-8); "messaging server between the people who use applications" → "messaging service between the users of applications" (tac row) |
| runtime is not a server | 3 | "runtime server" → "runtime process (of its own)" (E-9, E-16); "a runtime server of our own" → "a runtime on a machine of our own" (L-1) |
| owner qualified | 9 | "the owner's words" → product owner's (S4); "its owner", "the future owner", "name and owner" of a document or runtime → "the quest it belongs to" (S5, S6, S14, S16); "owner" → quest owner (`CI` row), team owner (L-4); heading `USR-TEAM` "Owner and review team" → "Product owner and review team"; its table column "Owner" → "Owner of the review team" |
| person / user | 6 | "people" → "users" where the sentence means people using an application or held by tac: V-5 (three times), S5, E-12; "the people who use applications" → "the users of applications" (tac row, counted above); U-5 "a person supervising" → "a user" |
| run / execution | 3 | "one agent run" → "one execution by an agent" (`VIS > VIS-PROBLEM`); "what a run touches" → "the resources an execution works on" (V-6); "a run's own commits" → "an execution's" (O-6) |
| agent | 1 | V-3 "Agents that work across runtimes as they work across VS Code windows today" → "Runtimes that work with each other, so that an agent's tools reach other runtimes as they reach other VS Code windows today" (what acts towards the outside is the runtime) |
| team runtimes, group | 2 | U-5 "a group of runtimes" → "several runtimes"; "a part of a team's" → "some of the team runtimes" |
| session in coordination | 1 + 1 addition | `CA` row "sessions, leases on named resources" → "leases on named resources, held by a runtime for an item of a run"; E-3 gets the addition `("session" and "unit" are record names of tac/1.0)` |
| strict / worktree mode | 1 | `CW` row "worktrees per repository setting" → "a repository's strict or worktree mode" |
| application / host | 4 | "supervision app" → "supervision application" (S8); "It lives inside one host" → "one application" (the extension is not yet a host); "three hosts … wait for it" → "three future hosts"; "a small web client" → "a small web application" (L-3) |

**Old words kept on purpose:**

- `SRC` S9 "client and agent protocols": the research topic is outside protocols between an editor
  and a coding agent (the Agent Client Protocol and others), not one of our clients.
- `SRC` S9 "cloud agents", `VIS > VIS-PROBLEM` "AI agents", P-2 "Agents and people", P-3 "a question
  from an agent", U-1 "working with agents", "the agents' questions": the agent here is the model
  acting in a session, which is the agreed sense; none of these is about tac.
- `ABOUT > ABOUT-READ` and capability-area names: "`CI` people, teams and identity" (the area's
  name, shared with the heading of `TAC > TAC-PEOPLE`, which is `p1s1r3-4`'s part); "generation
  unit" (`G-<n>`, a TomSpecs term, not a coordination unit); "user group" (`U-<n>`, `USR-GROUPS`:
  the TomSpecs name of the section).
- `VIS` "people who answer questions, review documents and decide", "a quest with processes, gates,
  todos and people", P-3 "People outside the editor", L-3 "people outside the team": any human is
  meant, not someone using one of the applications. U-1 "One person with one or several machines".
- E-1 "the two host transports that are removed", O-4 and S19 "host transports": the name of what
  is removed.
- E-1 "a JSON-RPC server for scripts, and the Dart client of it": the server has its kind, and the
  client is named by what it is a client of. Likewise U-13 "its clients" and E-6 "Tom Secrets
  Manager clients" (the clients of that product), and O-7 "a file server".
- E-3 "sessions" and "units": what `tac/1.0` has built, under its own record names (said once, in
  the addition).
- E-2 "the run and session that queued it": the session of a run in the runtime, not coordination.
- L-8 "Webwork's own server side": Webwork's part, not one of our servers.
- E-11, U-13 "the tac service": the service as a component (`tom_tac_service`), not a server.
- V-6 "claims", E-2 "the fields for claims", E-11 "claims are not taken": the agreed word.
- U-1 "without runs disturbing each other", V-5 "the runs that need them": the run as the queue.

**Questions raised:** none.

## p1s1r3-2 — the runtime section (`RT`)

**48 marked changes:** 45 substitutions (`{~~old~>new~~}`) and 3 additions (`{++…++}`); no
deletion. No id, reference chain or source citation was changed; nothing outside `RT` (from its
heading to the heading `CLI`) was touched.

| Kind | Count | What became what |
| --- | --- | --- |
| client with its kind | 13 | bare "client" → runtime client (CP.1, CP.4, CP.5 twice, CP.6, CP.18, CP.25, CP.26, the last sentence of CR.46); "a client of external MCP servers" → "an MCP client" (CT.16); in CR.46 the "clients" a runtime host server serves → "applications", "one runtime per client" → "per connected application", "that client's session" → "that application's connection" (a connection, not a session with a model) |
| client SDK | 4 | "client package(s)" → runtime client SDK(s) (CP.11, CP.26, CP.27, CP.34) |
| server with its kind | 3 | "A server can host runtimes", "the server is the host" → runtime host server (CR.46); "The server asks for a bearer token" → "The MCP server" (CT.12) |
| run, the queue | 2 | CR.8: "the unit of work in a quest" → "a queue in a quest that executes todos and prompts, one line of work" ("unit" is no longer used, and the run is the queue); "a queue lane with its own settings" → "its own queue settings" |
| execution of an item | 6 | an item, prompt or todo that "runs" → "is executed": CR.15 (a session it is executed in), CR.16 twice (the prompt being executed; that prompt's execution), CR.20 (an item that is being executed), CR.22 (the profile it is executed with), CT.9 (the role a prompt is executed in) |
| claim | 1 | CR.35: "a todo that names none claims the quest's whole list while it runs" → "for a todo that names none, the runtime claims the quest's whole list for as long as the todo is executed" (the runtime claims, for an item; a todo claims nothing) |
| agent | 9 + 1 addition | the outside program of an agent transport is no longer called an agent: CR.25 "an agent that runs its own loop" → "an outside program (an agent SDK or a command line) that runs the loop itself"; CS.12 "The provider's agent" → "agent SDK or command line"; CS.17 "where the agent owns the conversation" → "the outside program of an agent transport". The two sides of the Agent Client Protocol are named as that protocol's roles, said once: CR.30 "as a client" → "in that protocol's role of the client (…)", "every agent" → "every outside program … in the role of the agent" (addition), "an agent" → "such a program"; CR.31 "as an agent" → "in the protocol's role of the agent". What calls a tool is the agent, not the model: CT.5, CT.14 "the model" → "the agent" |
| lock | 2 | CR.38 "under a lock" → "a file lock"; CP.29 "under a lock" → "a file lock on that machine". Both are locks on one machine, not leases |
| person / user | 2 | CS.5 "a person cannot override them" → "a user" (the user's own configuration file); CS.11 "the team tokens of a person" → "of a user" |
| owner qualified | 1 | CP.16 "Every quest has an owner" → "a quest owner" |
| team runtimes | 1 | CT.13 "other runtimes of its team" → "the other team runtimes" |
| process | 1 | CP.9 "An ask outlives the process that asked" → "the operating-system process" (a "process" alone is the defined way of working) |
| conversation with a model | 2 additions | CR.18 "a new conversation" and CP.7 "A conversation" get "with the model" / "with a model", so the word is not read as a conversation between users (the messaging term) |

**Old words kept on purpose:**

- CP.21, CP.9, CP.22 "the run that asked (waits / resumes)": making them consistent decides
  whether the run or only the execution waits (PQ-24). Unchanged and unmarked.
- CR.19, CP.3 "timed requests"; CP.10, CP.14 "reverse requests"; CR.31 "permission requests": the
  name of a feature of the engine, of a kind of protocol message, and of a message of the Agent
  Client Protocol. None is a claim.
- CS.10 "the vault is locked": the state of the Tom Secrets Manager vault.
- CS.7 `os:<service>/<account>`: the form of a reference into the operating system's secret
  store; the account there is a keychain account, not an account of a tac server.
- CR.8, CR.15, CP.3, CP.7, CP.35, CT.1, CR.21, CR.31 "session": the session of a run in the
  runtime (a conversation with a model), which is the agreed sense. CS.17 "a session id": the id
  the outside program gives its own conversation.
- CR.6, CR.9, CR.12, CR.17, CR.23, CR.24, CR.45, CP.5, CP.6, CT.4 "run": the run as the queue.
  "runs" as a verb for programs and processes ("the runtime runs the tool loop", "every process
  runs in a run of its own", "a running runtime", "the running step") stays.
- CR.7, CP.8, CP.9, CP.17–CP.19, the closing line of `RT-ASKS` "person", "a chain of people": an
  ask goes to a person (the agreed definition of ask), who may be outside any application at
  that moment.
- CP.17 "the owner of the quest", "the owners of the team"; CS.4 "a team's owners"; CP.7 "the
  product owner's direction": each owner is qualified.
- CR.10 "walks over todo groups", CR.13 "a named group of todos", CR.19 "a group of todos": the
  allowed sense of "group".
- CR.5 "subagent definitions": the name of a Claude Code feature. CR.11, CP.8, CP.35 "an agent":
  the model acting in a session.
- CS.12 "Mistral (its coding agent)", CS.16 "Two agent libraries": what the outside products are
  called; CS.12 "the client for local models grown into a provider client": clients named by what
  they are clients of, not one of our two client kinds.
- CR.46 "the server side of a web application": Webwork's or another application's own part,
  named by what it is; CP.12, CP.35 "the extension's JSON-RPC server", "script server": servers
  with their kind.
- CR.38, CR.39 "the local tac service": the service as a component, not a server.
- CR.35 "subtrees": a part of a repository in plain words; the sentence names them as the
  quest's list, which the todo's "resources" refer to.

**Questions raised:** PQ-24 (what waits while an ask is open: the execution or the run),
PQ-25 ("new conversation": the same session starting over, or a new session).

## p1s1r3-3 — client SDKs, UI components and supervision (`CLI`)

**36 marked changes**, all substitutions (`{~~old~>new~~}`), and 1 remark (`{>>…<<}`, in CL.11,
pointing to PQ-26); no addition, no deletion. No id, reference chain or source citation was
changed; nothing outside `CLI` (from its heading to the heading `TAC`) was touched. The section
has the items CL.*, CU.*, CK.* and the inventory rows SC-*; it holds no CT.* or CS.* item (those
are in `RT`).

| Kind | Count | What became what |
| --- | --- | --- |
| client SDK | 24 | "client packages" → client SDKs (the section title, the title of `CLI-PACK`, CL.1); "two clients", "the runtime client", "the tac client" as what is built → client SDKs, runtime client SDK, tac client SDK (CL.2 five times, CL.3 three table rows, CL.5 twice, CL.9, CL.10, CL.11 twice, CU.1, CK.6); "a client", "every client", "the … clients" for the libraries → client SDK(s) (CL.4, CL.6, CL.7 twice, CL.8) |
| client with its kind | 1 | CU.12 "the data each needs from the client" → "the runtime client" (an application reaches everything, tac included, through its runtime) |
| server with its kind | 2 | "a runtime on a server" → "on a runtime host server" (CL.11, CK.10; both cite CR.46, which names it so) |
| application / host | 2 | CU.2 "take their look from the host" → "from the application"; CU.7 "a host's own log channels" → "an application's" (the Flutter application that embeds the components; on a phone the host is the runtime host server, which has no look and no log panel) |
| team runtimes | 6 | "a group of runtimes" → team runtimes (CU.15, CK.3); "a team's runtimes", "every runtime of a team", "the runtimes of a team" → team runtimes, a team's team runtimes (SC-19, CK.1, CK.8); CK.4 "a part of a team's" → "some of the team runtimes" (as U-5 in `USR`) |
| person / user | 1 | CK.4 "A person supervises" → "A user supervises" (someone using the supervision application) |

**Headings whose title changed** (ids unchanged): `CLI` "8 Client packages, UI components and
supervision" → "8 Client SDKs, UI components and supervision"; `CLI-PACK` "8.1 The client
packages" → "8.1 The client SDKs". **For `p1s1r3-7`:** the document has no link that uses either
old title as an anchor (searched for `#8-client-packages…`, `#81-the-client-packages`,
`client-packages` and `(#cli`: no hit); every reference to these sections uses the id chains
`CLI`, `CLI > CLI-PACK`. The words "client packages" still stand, outside my part, in N-26, in the
deliverables list near it ("the API documentation of the client packages"), in D-3, D-50 and R-12.

**Old words kept on purpose:**

- CL.2, CL.3 "each in a package of its own", the column "Package", CU.3 "The package", "Tom
  Forge's own view package", CK.7 "packages of Tom Forge": the software package a client SDK or
  the components are delivered in, not the word for the SDK.
- CL.10 "today's Dart client of the extension's script server", "Scripts that use that client":
  an existing library that is neither a runtime client nor a tac client; it is named by what it is
  a client of, and the server has its kind (as E-1 in `LAND`).
- CL.6 "a running tac service": the service as a component under test (local backend or tac
  server), not a server.
- CL.11 "servers" in "used by runtimes, servers and tools": no kind fits without adding or
  removing a requirement (PQ-26); unchanged, with a remark.
- CL.5 "register the host's tools", CK.5 "a runtime whose host allows it": the host in the agreed
  sense (host tools; the host's setting for remote control).
- CU.11 and the inventory (SC-17, SC-24, SC-25) "host's own": the name of an outcome in the
  table of CU.11, used as a value in the inventory; it means what stays in the VS Code extension.
- CU.6 "Messaging … people": the name of a component in the list (the people of a conversation
  or team).
- CU.6 "Component groups", "Group", the column "Component group", CL.5 "a group of todos": the
  allowed uses of "group".
- CU.6 "session todos", "Sessions and memory", SC-9, SC-14: sessions of a run in the runtime, not
  coordination.
- CK.1 "claims", CU.6 and SC-28 "claims, leases, the integration queue": the agreed words.
- CK.2 "starts and pauses runs and queues", "the run that asked": the run as the queue; whether
  the run or the execution waits on an ask is PQ-24.
- CK.11 "strict", "a device is paired first and gets a key of its own": already the words of
  § 2.3 (strict server, pairing, a key of its own).

**Questions raised:** PQ-26 (who uses the tac client SDK besides runtimes: CL.11 "servers").

## p1s1r3-4 — coordination and messaging (`TAC`)

**122 marked changes:** 119 substitutions (`{~~old~>new~~}`), 2 additions (`{++…++}`) and 1
deletion (`{--…--}`), and 5 remarks (`{>>…<<}`). No id, reference chain or source citation was
changed; nothing outside `TAC` (from its heading to the heading `PAR`) was touched.

| Kind | Count | What became what |
| --- | --- | --- |
| server with its kind | 33 | bare "server" → tac server: CA.1, the backend table of CA.26 (the backend's name too) and the paragraph under it, CA.27 (five times), CA.28, CA.30, CI.6 (twice), CI.9, CI.10 (four times), CI.16, CI.20 (four times), CA.39, CA.36, the rows WR-1 and WR-2. → runtime host server: CI.4, the row WR-6 ("a runtime on a server", "the server-side runtime"), CI.19 ("the server-side runtime for phones"; "a runtime on the server" → "on that server"). CA.40 "repository host" → "repository server" (the word of CA.10; "host" is the program that starts a runtime) |
| client with its kind | 27 | bare "client" → tac client: CA.4, CA.5, CA.13, CA.15, CA.18, CA.22 (twice), CA.26 (local row), CA.32, CA.35 (twice), CI.6 step 4, CI.8, CI.10, CM.1, CM.7, CM.9, CM.13, CV.2, CI.16, CA.37 (twice), CA.38; CA.28 "browser clients" → "tac clients in a browser". Where the sentence means the program a user works with → application: CI.4 ("Every client reaches tac through a runtime"), the row WR-2. CI.6 step 3 "The invited person's client" → "runtime" (an application reaches tac through its runtime, CI.4) |
| client SDK | 3 | CA.25 "the service and its clients" → "its tac client SDKs"; the row WR-6 "The Dart tac client" → "tac client SDK", "the runtime client" → "runtime client SDK" |
| person / user | 27 | "people", "person" → users, user where someone using an application or held by tac is meant: the lead-in of `TAC`, the Messaging row of `TAC-JOBS`, the lead-in of `TAC-PEOPLE`, CI.1, CI.2 (twice), CI.3 (twice), CI.4, CI.7, CI.10 (twice), CI.12, CI.14, CI.18, CA.32, CA.38, CM.1, CM.5 (twice), CM.6, CM.7, CM.10, CM.14; → members where the team's own people are meant: CA.2, CI.5 (table), CI.14 |
| owner qualified | 10 | "owner(s)" → team owner(s): CI.1, CI.5 (lead-in, the column head, the row on making an owner twice), CI.6 (twice), CI.9, CI.20; CI.11 "an owner" → "a quest owner" |
| team runtimes | 4 | CA.6 "Any runtime of the team can list the team's runtimes" → "Any team runtime can list the team runtimes"; CA.23 "The others of the team" → "The other team runtimes"; CA.32 "the team's runtimes" → "the team runtimes" |
| claim / lease | 7 | CA.16 "asked for … given back" → "claimed … its lease is released"; CA.13 "Its resources stay held" → "stay leased"; CA.17 "A todo claims an `_ai` folder only when it names one" → "A runtime claims an `_ai` folder for a todo only when the todo names one" (the runtime claims, for an item); `TAC-GROUPS` lead-in "the resources they hold" → "hold leases on" |
| holder of a lease | 1 | `TAC-JOBS` table: "sessions, leases on named resources" → "leases on named resources, held by a runtime for an item of a run" (as `p1s1r3-1` wrote the same row in `ABOUT`) |
| strict / worktree mode | 1 | CI.5 "working trees per repository" (a team setting) → "strict or worktree mode per repository" |
| agent | 1 | CI.3 "what an agent sends" → "what the runtime sends for an agent" (an agent is never something tac deals with) |
| group | 1 | CM.7 "a group (a list of members)" → "among several members (a list of members)" |
| visible / home team | 1 + 1 deletion | CI.13 "only by members of a team its person is in" → "only by members of the home team of its quest" — see below |
| protocol names said once | 1 addition | CA.16 "The declared units and infrastructure resources of the protocol as built" gets "(record names of `tac/1.0`)" |
| run | 1 | CA.40 "the person it runs for" → "the person it belongs to" (the agreed phrase for a runtime's person) |
| application / host | 1 | CI.4 "on the desktop the host's own runtime" → "the runtime it hosts" (on a desktop the application is the host) |
| heading | 1 | `TAC-GROUPS`, see below |

**One change that goes beyond a word, made because § 2 decides it:** CI.13 said a runtime can be
remote-controlled "by members of a team its person is in". The agreed term **visible** (S21,
TQ-11) and CA.44 in the same section say: remote control only from the home team of its quest, in
the user's other teams the runtime is only seen and can be offered todos. CI.13 now says "members
of the home team of its quest", with a remark. If CI.13 was meant to stay wider, the remark is
the place to say so.

**Heading whose title changed** (id unchanged): `TAC-GROUPS` "9.4.1 The team is what its runtimes
coordinate in" → "9.4.1 The team runtimes". **For `p1s1r3-7`:** the document has no link that uses
the old title as an anchor (searched for `the-team-is-what`, `coordinate-in`, `#94`: no hit); the
three references to it use the id chain `TAC > TAC-PEOPLE > TAC-GROUPS` (CA.2, CI.1) or the id.
The heading `TAC-PEOPLE` "9.4 People, teams and identity" keeps its title: it is the name of the
capability area `CI`, which `ABOUT` and `SCO` use.

**Old words kept on purpose:**

- CA.20 "a session started or ended", CA.26 "leases, sessions and endpoints", CA.29 "closing a
  session": the `session` record of `tac/1.0`; replacing it decides what tac stores and announces
  (PQ-27). Each has a remark.
- CI.18 and CI.19 "the server" (nine times): it can be the tac server or the runtime host server,
  and naming it decides what faces the internet (PQ-28). CI.18 has a remark.
- CA.9 "a declared infrastructure resource", CA.16 "declared units and infrastructure
  resources", CA.27 "the protocol as built says 'customer'", CA.39 "agent group" and "its group
  id": names of `tac/1.0`, each said as such. CA.16 "Resources are not declared anywhere
  beforehand": the verb, saying what the product does not do.
- CA.8 "session": the item explains that the word is not used. CA.17 "the session history",
  "written by many sessions at once": sessions of a run in the runtime (conversations with a
  model), not coordination.
- "the service" (CA.1, CA.4, CA.13, CA.15, CA.18, CM.1, CM.4, CM.9, CA.37 and others) and "the
  local service": tac as a component, whatever its backend; not a server.
- CA.3, CI.3, CI.12, CA.40 "the person it belongs to", "its person": the agreed phrase "a
  runtime's person". CI.2 "One runtime belongs to exactly one person": the definition of runtime.
  CA.13 "only a person frees it": the definition of stale / free. CA.27 "a single person": the
  definition of account. CI.6, CI.20, the row "invite a person": the receiver of an invitation,
  or whoever joins a tac server, is not a user yet.
- CA.30 "an owner of the team", CI.20 "the first account": already qualified.
- CI.10 "An **open** server", "strict": the agreed terms open server and strict server.
- CA.26 "one of three", the backend names **local** and **GitHub**; "mode: off" and "local mode":
  names of settings.
- CM.2 "review request", "decision request", CM.13 and the row WR-4 "request id", CI.8 "with
  every request", CA.28 "cross-origin requests": message kinds of § 2.5, the protocol field
  `requestId`, and HTTP requests; none is a claim.
- CM.2, ask row "the answer returns to the run that asked": open under PQ-24 (from `p1s1r3-2`).
- CA.40 "An agent uses only resources it can reach", CA.39 "agent SDKs": the model acting in a
  session; neither is something tac deals with.
- CA.44 "link two groups of quests": the wording of the agreed definition of visible.
- CV.5 "the file servers", CV.7 "a file server", CA.23 "its MCP server": servers with their kind.
- CV.4 "A process can pin its blobs for as long as it runs", "the step of a team review": the
  process as the defined way of working.
- The titles of the Webwork requirements in `TAC-WEBWORK` ("tac reachable as a server by a small
  team", "a Dart client that needs no AI runtime", "user messages"): quoted from S3.
- `<owner>/<repository>` in CA.10 and CA.41: the form of a resource name.

**Noticed, not changed (content, not wording):** CA.9 says the kind "folder of the `_ai` state"
is not used for now, while CA.17 says an `_ai` folder is claimed when a todo names one. CA.28
speaks of tac clients in a browser, while CI.4 says every application reaches tac through a
runtime (a browser application's runtime is on a runtime host server). Both are for the closing
todo or the next round to look at.

**Questions raised:** PQ-27 (what becomes of the `session` record of `tac/1.0`: CA.20, CA.26,
CA.29), PQ-28 (which server a paired device reaches from the internet: CI.18, CI.19).

## p1s1r3-5 — parallel work and the non-functional expectations (`PAR`, `NFR`)

Part: from the `<!--[PAR]-->` heading to the heading `DEC`: `PAR-PROBLEM`, `PAR-APPROACH`,
`PAR-CROSS`, `PAR-QUESTS`, `NFR` with N-1 … N-34, `NFR-TOPO` (T1 … T8), `NFR-TOPO-FLOWS`
(F1 … F12) and `NFR-GEN` (G-1 … G-7). Read sentence by sentence against terminology § 2.

**81 marked changes:** 79 substitutions (`{~~old~>new~~}`) and 2 additions (`{++…++}`). No id
and no reference chain changed. CW.2, CW.3, CW.5 … CW.8, CW.26 and F8 were already in the agreed
wording and are unchanged.

**The known leftover is corrected.** `NFR > NFR-TOPO`, the paragraph on T6: "On the always-on
machine only the tac server runs in the first version." now reads "On the always-on machine the
tac server and the runtime host server (T8) run in the first version; a runtime there is started
for a connected application and ends with that application's connection (`RT > RT-INSTALL`,
CR.46)." It agrees with T8, CR.46, D-51 and D-52; PQ-9 is added to its source beside PQ-16.

**Kinds of change:**

| Old | New | Where |
| --- | --- | --- |
| "run" for the work on one item | execution | P-7, P-8, CW.1 (twice), the lead-in of `PAR-APPROACH` ("waiting runs"), CW.10, CW.15 ("the run's context"), CW.17, N-34 ("the machine of the run") |
| "locks shorter than a run" | leases shorter than an execution | CW.1 |
| "held by someone else" | held for another item | CW.4 (a lease names the runtime, the run and the item) |
| "take its claims", "give them back", "gives the claims back", "takes its claims through tac", "runs it" | claim its resources, release the leases, executes it | CW.9, F3 |
| "A repository nobody claims" | on which no lease is held | CW.16 |
| "code host", "repository host" | repository server | CW.17, T7 (twice) |
| "person" where a user of an application is meant | user | CW.18, CQ.2, CQ.7 (three times), F5 ("the person's other devices") |
| "visibly" | "is shown" (visible is the term for a runtime in a team) | CW.19, F7 |
| "a trial run" | a trial migration | CQ.7 |
| bare "client" | runtime client / tac client | N-1, N-2, N-3 (runtime client); N-20, N-22 (tac client); T6 (runtime client) |
| "client package(s)", "clients" of a language, "the Dart client of …" | client SDK(s), runtime client SDK, tac client SDK | N-2, N-26 (twice), N-29, N-30, N-31 (twice), G-3, G-4, G-5 (three times), the paragraph under the table of `NFR-GEN` |
| bare "server" | tac server | N-19 (twice), N-22, N-29, T3, T4, T5 (twice) |
| "has one owner, the runtime," | is kept by the runtime alone | N-8 (bare "owner") |
| "the team's runtimes", "a team's runtimes", "a group of runtimes", "coordinate in one team" | the team runtimes; "are the team runtimes of one team and coordinate" | N-12, T3, F10 (title and text), F11, G-7 |
| "the process that asked" | the operating-system process that asked | N-15 (as CP.9 in `RT`) |
| "holder" of an ask | who has it | N-15 (holder is the term for a lease) |
| "a repeated request" | a repeated send | N-16 |
| "A runtime server (later)" | Standalone runtimes on an always-on machine (later) | T6 (a runtime is never a server; the words of L-5) |
| "A server-side runtime for phone, tablet and web clients", "a client", "a server", "the client's session", "that server", "the server-side runtime" | A runtime host server for applications on a phone, on a tablet and in a browser; application, runtime host server, "that application's connection", "the runtime it started" | T8 (11 marks, the wording of CR.46) |
| "without a host application" | without an application connected to it | the paragraph on T6 |
| "its walks run" | are executed | F4 |

**Added:** in `NFR-GEN`, one sentence saying that the kinds in the table (server, client,
"shared") are the kind names of the specification model's register of generation units, not this
document's terms: by kind the runtime (G-1) is a "server" there, though it is a runtime process.

**Old words kept on purpose:**

- "unit": CW.11 "the unit of review" (what is reviewed, not something leased); all of `NFR-GEN`
  "generation unit", "the units" (packages and applications that are built). No "unit" in the
  part meant a resource; "touch set" does not occur.
- "group": CW.9 "A group of todos" (the allowed sense).
- "lock": N-8 "under a lock" and F12 "the machine's lock" are file locks on one machine, the one
  sense § 2.4 leaves to the word.
- "request": P-13 "Requests to another quest", "a request ends", CW.22 "A request to another
  quest" (something asked of another quest, not a claim); "pull request" (CW.1, the lead-in of
  `PAR-APPROACH`, CW.15, CW.17); F6 "the review request" (a message kind of § 2.5).
- "session": P-5, P-6, P-9, CW.11 "the session that made it", CQ.3 "the storage of the
  sessions", "the session todos", F2 "when the session is free": conversations with a model in a
  runtime, not coordination. CW.18 "a session" as something addressed and CW.23 "the run and the
  session that asked for it" restate CR.21 (`RT`), where a done notification returns to the
  session that queued the todo; it is delivered inside the receiving runtime, and what tac keeps
  of a session is open under PQ-27.
- "run" as the queue: the lead-in of `PAR`, P-13, CW.4, CW.7, CW.18 … CW.20, CW.23, F7; and as a
  verb ("run the checks", "runs permanently", "trial"). F5 "A run asks" and "the answer returns
  to the run", F7 "returns to the run that asked": unchanged and unmarked, open under PQ-24 (from
  `p1s1r3-2`).
- "person", "people": the lead-in of `PAR` ("by several people", "a person's own files"), CW.2
  "one person works on", CW.15 "a person reviews", CW.26 (the agreed wording of todo offer), N-13
  "only a person frees it" (the definition of stale / free), N-15 "a chain of people", N-19 "one
  person alone", "other people" (whoever uses a tac server, as in the definition of account),
  N-34 "started by a person", T4 "several people", F5 "An ask reaches a person elsewhere" (an ask
  is put to a person).
- "server" with a kind that is not ours: CW.1 "a build server"; "an open server" in N-19 (the
  agreed term). "the server mode" in G-2: the name of a mode of `tom_tac_service`. Mapper names
  (`ts-hono-server`, `ts-react-client`, …): tool names.
- "service": N-4 "A service announces", N-20 "What the service stores", N-28 "The tac service",
  N-29, T1 and T2 "the local tac service", the paragraph on T6 "a service that hosts a runtime":
  tac as a component whatever its backend (as in `TAC`), or a service in the general sense.
- "client" as a kind in the table of `NFR-GEN` and "the tac client inside the runtime" (G-1,
  with its kind): see the added sentence.
- "host": N-19, N-25, N-29, N-32, F1, F2, F5, F12 use it in the agreed sense (the program that
  starts a runtime). "hosted agent" (F9) and "a service that hosts a runtime" are the verb.
- "process": P-12 "written whole by one process" and N-3 are operating-system processes named
  beside "window" and "runtime"; F4, N-15 "does not block a process" and N-30 "process model" are
  the defined way of working or the architecture's term.
- "agent": CW.3 "its agent", CW.15 "a review agent", CW.17 "agents working directly on the main
  branch", CQ.4 "the agents of every member", T7 "A cloud agent", F9 "a hosted agent": the model
  acting in a session; none is something tac deals with.
- "supervisor" in F10: the user of the supervision application, as `USR` names the role.
- "released" in F6 ("the round's files are released"): the word `TAC` uses for blobs (CV.4).
- T5 names the tac server as what a machine off the VPN reaches, because the relay is part of the
  tac server (G-2); which server a paired phone or tablet reaches is open under PQ-28 and concerns
  T8, whose "reaches the runtime host server … from the internet" is the wording of CR.46.

**Noticed, not changed (content, not wording):** T3 says the runtimes of one user on several
machines "are the team runtimes of one team" through the GitHub backend or the tac server; § 2
defines the personal team only for the local backend, so which team that is with the GitHub
backend is not said anywhere. `NFR-GEN` G-1 … G-7 name package names (`tom_tac_client`,
`tom_ai_runtime_client`) that are client SDKs in the agreed terms; the package names are kept.

**Question raised:** PQ-29 ("accepted" for work sent to another quest, inside a team and across
teams: CW.19, CW.20, F7 against CW.26).

## p1s1r3-6 — decisions, contradictions, risks and delivery (`DEC`, `CON`, `RISK`, `DEL`)

**83 marked changes** (81 substitutions, 1 insertion, 1 remark), from the `DEC` heading to the
end of the document. No id changed, no decision changed in what it decides. No question raised.

**Kinds of change**

| Was | Is now | Where |
| --- | --- | --- |
| "client package(s)", "the client" (a library) | **client SDK(s)**, **runtime client SDK**, **tac client SDK** | D-2, D-3, D-14, D-43, D-50, D-57; R-12, R-14, R-24; the two tracks of `DEL` |
| bare "client" (a program) | **runtime client**, **tac client**, or **application** where the program a user uses is meant | D-10 (remote runtime clients); D-27 and X-3 (an application in a browser, on a phone or on a tablet); X-3 (a Dart tac client) |
| bare "server" | **tac server** | D-22, D-23, D-25, D-54, D-59; X-4, X-11; R-6, R-20; the tac track of `DEL` |
| "the server side", "server-side runtime", "a permanent server that hosts one runtime per client" | **runtime host server** (one runtime per connected application, ending with that application's connection — the wording of CR.46) | D-27, D-51, D-52; X-3, X-12, X-14; R-8, R-22 |
| "a runtime server on an always-on machine" | **standalone runtimes on an always-on machine** (the wording of T6 and L-5; a runtime is never a server) | D-52; X-12 |
| "team server" | "tac server for one team" | D-22 (what it replaces) |
| bare "owner" | **quest owner**, **team owner**, **product owner**; "which quest owns" | D-20, D-25; X-8; R-22 |
| "agent group" outside quotes | in quotes once, or the sentence rebuilt without it | D-24; X-5 |
| "customers" | "customers" in quotes once as S5's word (X-4); **accounts** (R-6) | X-4; R-6 |
| "units" as resources | in quotes, as S5's word | D-59; X-15 |
| "the group's data" | "tac's data" | X-15 |
| "asked for" (a resource) | **claimed** | X-15 |
| "runs" for the work on one item | **executions** | D-33; R-10, R-11 |
| "locks held by agents", "releasing its claim" | what others call "locks"; an execution's **lease** being released (a claim is the attempt, a lease is what is held and released; an agent holds nothing) | R-10 |
| "locks" of a package's consumers | "lock files (`pubspec.lock`)" — the files, to keep them apart from leases | R-18 |
| "people" (members of a team, participants) | **users** | D-24, D-27; X-5 |
| "direct, group and attached conversations" | "conversations that are direct, among several members, or attached" (the glossary's wording) | D-28 |

**Old words kept on purpose**

- "agent group": D-24 (once, in quotes, as what is no longer a thing), D-60 (the list of replaced
  words), X-5 (the title and "S5 uses"): these entries are about the word. "one tac group" and
  "one team, one group" in X-5 are quotations of S13.
- "customers" in X-4 (once, in quotes: S5's and S6's word, with "in the product: accounts");
  "customer", "touch set", "unit", "grant" in D-60's list of replaced words.
- "units" in D-59 and X-15: S5's declared units, in quotes.
- "unit" as a **generation unit**: D-36, D-57, and the `DEL` paragraphs ("per unit", "of the
  units", "the code of the units"). Not a resource; `NFR > NFR-GEN` defines it.
- "locks" in R-10: in quotes, as the word of those who reported the finding (S9).
- "server" with a kind that is not ours, or in a quotation: "the runtime's MCP server" (D-9, an
  agreed kind); "the Agent SDK server of today" (D-16: the name of today's program, which becomes
  a mode of the runtime); "through a server part that runs the runtime for them" (X-3, the
  product owner's quoted answer); "Webwork's own server side" (X-3, X-14, R-8: the wording of
  L-8, Webwork's part, not a server of this product); "client and server" in D-60 (the terms
  being named).
- "client": "Tom Secrets Manager's TypeScript client" (R-17: another product's client, named
  with its kind); package names (`tom_tac_client`, `tom_ai_runtime_client`); "TAC clients in the
  API packages" in D-2 (a quotation of FO-19); "the tac client inside the runtime" in the runtime
  track of `DEL` (with its kind: the runtime in its role towards tac, as in G-1).
- "owner": "An owner of a team" in D-53 (qualified).
- "group": "The review group of the UI components" (R-19) and "the component groups" (`DEL`):
  component groups, an allowed sense.
- "sessions": X-11 "leases, sessions and endpoints" is unchanged with a remark, open under PQ-27
  (from `p1s1r3-4`), as in CA.26. R-9 and R-11 ("other sessions", "another session", "every other
  session's base") describe today's working sessions writing to shared clones, as P-5, P-6 and
  P-9 in `PAR > PAR-PROBLEM` do; they are not coordination records.
- "run" as the queue or as a run of a process: D-12, D-37, D-45, D-46, X-7, R-9 ("Other
  sessions, runs and machines", "Two runs touch the same repository"), and the `DEL` paragraphs
  ("two runs in parallel").
- "person", "people": D-24 "One runtime belongs to one person", D-26 "the person's token" (a
  runtime's person), D-34 "per person", D-20 "asking people outside the team" (not users of an
  application), D-59 "A person joins a tac server" and R-3 "the first second person joins a team"
  (as CI.6 says it: a person becomes a user by joining), R-13 "across machines and people",
  `DEL` "without a person".
- "agents": D-8 ("agents that speak" the Agent Client Protocol, "answering as an agent": the
  protocol's own roles), D-35 and R-5 ("hosted agents": vendors' services), R-10 ("the work of
  agents", "held by agents" for what others reported).

**Noticed, not changed (content, not wording):** D-60's list of replaced words does not name
"lock" and "request" as a noun, which § 2.6 also replaces. R-22's trigger now names both servers,
because which of them a paired device reaches from the internet is open under PQ-28.

**Questions raised:** none.

## p1s1r3-7 — the whole document, the glossary and the questions

**15 marked changes:** 11 substitutions (`{~~old~>new~~}`) and 4 additions (`{++…++}`). No id and
no reference chain changed. `GLO` was compared with terminology § 2 row by row and is unchanged.

| Kind | Where | What |
| --- | --- | --- |
| the same wording in two parts | CW.8 | "a todo that names nothing claims that whole list while it is executed" → "for a todo that names nothing, the runtime claims that whole list for as long as the todo is executed" (as CR.35 in `RT` and CA.17 in `TAC`: the runtime claims, for an item) |
| file lock | N-8, F12 | "under a lock", "the machine's lock" → "file lock" (as CR.38 and CP.29 say it for the same two locks) |
| person → user | N-19 (twice), T4, D-34 | N-19 restates CI.10, which says "one user alone" and "other users"; T4 follows T3's "One user"; D-34 restates CQ.2, "Every user has one personal repository" |
| the list of replaced words | D-60 | "grant" as a noun → "grant" and "request" as nouns, "lock" for a lease (§ 2.6 lists all three) |
| taken / todo offer | CW.19, F7 | "accepted" by a run → "taken" (2 substitutions), a sentence added in each that work from another team is a todo offer (CW.26), and S21, TQ-11 added to CW.19's source |
| status | `ABOUT` (Status row), `ABOUT-READ` (the `PQ-<n>` row) | "no question open" → the round and its open questions PQ-24 … PQ-33 |

**The question dropped, and why.** `p1s1r3-5` asked (as PQ-29) whether CW.19, CW.20 and F7 hold
only between quests of one team, and which word names a run taking an item. Terminology § 2.3
decides the first part: a runtime "can be sent items" only in the home team of its quest, and in
its user's other teams it "can be **offered todos**: no remote control from there"; a todo from
another team is a **todo offer**, "not in the quest until it is accepted" by a person or a
person's rule. So nothing from another team is queued directly, which was the question's
recommended option (a) and rules out its option (c). The second part follows from the same
definition: "accepted" is the word for a todo offer, so for a run the text now uses "taken", the
word CA.19 already uses for a command. CW.20 is unchanged. If CW.19 was meant to hold across
teams after all, the two added sentences are the place to say so.

**Old words kept on purpose** (beyond what the parts recorded; all counted in the summary's
table):

- E-1 "queue lane": the feature of the extension as built; CR.8 states the run's "own queue
  settings" for the product.
- G-2 "the server mode": the name of a mode of `tom_tac_service`, as `p1s1r3-5` recorded.
- CI.1, D-24, X-5 "a group of users": the glossary's own definition of team.
- CS.9, U-7, D-19, N-30 "paired", "pairing" with Tom Secrets Manager: a second sense of a glossary
  term, in the product owner's wording; asked as PQ-32, unchanged.
- CA.28 "tac clients in a browser": stands against CI.4; it depends on what the review
  application is, asked as PQ-30, unchanged.
- CA.9 and CA.17 on a folder of the `_ai` state: asked as PQ-31, unchanged.
- T3 "the team runtimes of one team" with the GitHub backend: asked as PQ-29, unchanged.

**The questions.** `new_questions.md` held six. None duplicated another. Five were checked
against the form and kept as written (PQ-24 … PQ-28: each quotes its passages in full, explains
the terms, says what depends on the answer, has full-sentence options with their consequence,
exactly one bold option that the recommendation names, an assumption and an empty answer). One
was dropped (above). Five were added from the cross-check, PQ-29 … PQ-33; the ids run from PQ-24
to PQ-33 without a gap. All ten are inserted in the Project Idea; `new_questions.md` is now the
list of what was inserted where.

**Terms without a glossary entry** (step 1): the document uses further words in one fixed sense
that § 2 does not hold — walk, gate, role and role type, quest owner, done notification, relay,
notification and command, capability block, repository server, standalone runtime, classic quest,
repository quest, personal repository, root, workspace folder — each explained by an item, and
two that no item explains: profile and coordinator. None was added to `GLO`; PQ-33 asks.

## Closing check

Done by the round's closing item on 2026-11-20, after all seven todos were completed.

- **Marks:** 432 substitutions, 13 additions, 1 deletion, 7 remarks; every one closed, none
  nested. With every mark rejected and the ten question blocks taken out, the text equals the
  committed version except for re-wrapped lines: nothing was changed outside a mark.
- **Ids:** the 569 item ids and the 70 section ids are the same as before the round. Every
  section-id chain names existing sections; none is broken across lines.
- **Questions:** PQ-24 … PQ-33 each have Context, Why I ask, three options with exactly one bold,
  a recommendation naming that option, an assumption and an empty answer.
- **Words not used:** scanned again in the text as it reads with the marks accepted; the hits
  are the ones "Remaining uses, checked" lists. Nothing slipped through.

## G1 reading

A reading against gate run 2 (`quality/evidence/gates/G1_20261119-2045.gate.md`), not a gate run.

| Item | Run 2 | After this round |
| --- | --- | --- |
| G1-DOC-1 | pass | unchanged |
| G1-PROB-1 | pass | unchanged |
| G1-USER-1 | pass | unchanged; `USR` now says user where someone uses an application |
| G1-SCOPE-1 | pass | unchanged |
| G1-SRC-1 | pass | unchanged; S21 (the terminology) is listed |
| G1-ID-1 | pass | unchanged: no id added, dropped or renamed |
| G1-CLAR-1 | pass (no open question) | **to be read again:** ten questions are open (PQ-24 … PQ-33). Each has a working assumption the text already follows, so none stops Blueprint work from starting. Four decide something the Blueprint's architecture builds on and should be answered before G1 is run again: PQ-27 (the record for whoever holds leases), PQ-28 (which server a paired device reaches), PQ-29 (the personal team with the GitHub backend), PQ-31 (claiming a folder of the `_ai` state). The other six are wording or glossary questions. |
| G1-RISK-1 | pass | unchanged (below) |
| G1-CHANGE-1 | not applicable (initial development) | unchanged |

Run 2 evaluated the document before the terminology was taken in; G1 has to be run again on the
document as it stands after the answers of this round.

## Risk review

No change. No risk and no dependency of `RISK` changed its state; the entries were reworded only
(R-12, R-22, R-24 among them). PQ-28 touches R-22 (servers reachable from the internet): its
answer may narrow the risk to one server, which the round that takes it in decides.

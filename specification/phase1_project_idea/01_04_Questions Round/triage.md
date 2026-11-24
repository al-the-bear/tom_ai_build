# Triage — Phase 1, question round 4

Written by `p1s1r4-1` on 2026-11-20. It decides once, for the whole Project Idea
(`../project_idea.ai_runtime.md`), what is done with each answer (PQ-24 … PQ-33, `answers.md`) and
each finding of the four input files, so that the part todos `p1s1r4-2` … `p1s1r4-11` do not decide
the same thing differently. It changes nothing in the Project Idea.

How to use it: read § 1 completely (every part applies these words), then the table of your part in
§ 2. A row is a pointer: read the finding itself in its input file before you act on it. § 3 lists
the questions of the round and which part writes each. § 4 lists the sources `p1s1r4-2` adds.
The question keys (QT-<n>) in § 1 are those of § 3; § 3 has the complete list of findings behind
each question. § 5 is the count check.

**The parts** (from `iteration_split.md`):

| Todo | Sections | Item ids |
| --- | --- | --- |
| `p1s1r4-2` | `ABOUT`, `SRC`, `VIS`, `USR`, `SCO`, `LAND` | P-1 … P-4, V-*, U-*, O-*, L-*, E-* |
| `p1s1r4-3` | `RT-HOLDS`, `RT-RUNS`, `RT-QUEUE`, `RT-TRANSPORTS`, `RT-LOCATIONS`, `RT-CONFIG`, `RT-MACHINE`, `RT-INSTALL` | CR.1 … CR.46, CS.1 … CS.6 |
| `p1s1r4-4` | `RT-SECRETS`, `RT-PROTO`, `RT-HOST`, `RT-TOOLS`, `RT-MCP`, `RT-ASKS`, `RT-VERSIONS`, `RT-PROVIDERS` | CS.7 … CS.18, CP.1 … CP.34, CT.1 … CT.16 |
| `p1s1r4-5` | `CLI` (`CLI-PACK`, `CLI-UI`, `CLI-SCREENS`, `CLI-TRC`) | CL.*, CU.*, SC-*, CK.* |
| `p1s1r4-6` | `TAC-JOBS`, `TAC-COORD`, `TAC-BACKENDS` | CA.1 … CA.35 |
| `p1s1r4-7` | `TAC-PEOPLE` (with `TAC-GROUPS`), `TAC-KINDS`, `TAC-CONV`, `TAC-DOCS`, `TAC-REVIEW`, `TAC-CRYPT`, `TAC-SPEC`, `TAC-WEBWORK` | CI.*, CA.36 … CA.44, CM.*, CV.*, WR-* |
| `p1s1r4-8` | `PAR` | P-5 … P-14, CW.*, CQ.* |
| `p1s1r4-9` | `NFR`, `NFR-TOPO`, `NFR-GEN` | N-*, T1 … T8, F1 … F12, G-* |
| `p1s1r4-10` | `DEC`, `CON`, `RISK`, `DEL` | D-*, X-*, R-* |
| `p1s1r4-11` | `GLO`, and the whole document | the glossary entries |

## 1 Cross-cutting rulings

### 1.1 PQ-24 (b): what waits while an ask is open

**The one rule** (CP.21 states it; every other place refers to it or uses the same words):

> While an ask of a run is open, the run that asked waits: nothing further is sent from its queue
> until the ask is settled. The other runs go on.

- **"Settled"** means: answered; closed unanswered because the execution that asked was ended
  (VX-5); or resolved by its declared default (CP.20).
- **The subject of a waiting rule is always the run**, never "the queue", "the rest of the queue" or
  "the item" alone. The item that asked stays in execution (the extension's state `sending`); it is
  not moved to another state (VX-PQ24 points 2 and 3).
- **A walk does not go on with another todo** while its run waits. The clause "a walk goes on with
  the next todo that does not depend on the waiting one" goes everywhere it stands (CP.21; D-20;
  F5). A walk holds at the first todo it cannot run (VX-27); skipping it is the user's action on the
  item, not the runtime's choice.
- **Two words, kept apart in every part:**
  - a run **waits** when its item is still being executed and blocked in something: an open ask, a
    wait the agent declared (VX-9), the item's own background work (VX-11), a lease another holder
    has (CW.4), a secret that needs an unlock (CS.10), a result the user has to apply or discard
    (CR.17). The run's settings are untouched, and the run goes on by itself when the cause ends.
  - a run **is held** when its next item is not executed at all: a todo with open decisions, a
    blocked todo, an item that needs attention, an error, out of budget (VX-27, VX-32). The run's
    automatic sending is switched off, and the run goes on when the user resumes it (planned: by
    itself when the blocker is done, VX-28).
  - **paused** is what the user did to a run.
- **How the other waiting rules are worded beside it:**

| Item | Says from now on | Source |
| --- | --- | --- |
| CP.21 (`RT > RT-ASKS`) | the rule above | PQ-24 (b); VX-2, VX-PQ24 |
| CP.9 | stands ("the run resumes when the answer arrives"); add how: the answer is delivered as the next prompt in the same session, quoting question and answer, when the turn that asked has ended | VX-3 |
| CP.22 | stands ("the answer returns to the run that asked") | PQ-24 (b) |
| CS.10 (`RT > RT-SECRETS`) | asking the user to unlock is an ask: "the user is asked to unlock, and the run waits as for any ask (CP.21)" | PQ-24 (b) |
| CW.4 (`PAR > PAR-APPROACH`) | "the item waits and says who holds the lease; its run sends nothing else meanwhile; when the lease is released, the item goes on" | VX-17 (a lane whose next item cannot start waits; later items do not jump ahead) |
| CR.13 (`RT > RT-RUNS`) | no waiting: a step whose precondition does not hold is refused with the reason, nothing of it is queued, and the process stays at its position | as it stands; only the wording is checked against the two words above |
| CR.17 (`RT > RT-QUEUE`) | "the run waits until the host reports that the user applied or discarded the result" (not "the queue waits") | PQ-24 (b) |
| CR.20 (`RT > RT-QUEUE`) | split in two (VX-31): the waits (declared wait, own background work: "the run waits") and the interrupts (soft, hard, held, resume) | VX-9, VX-11, VX-31 |
| CR.23 (`RT > RT-QUEUE`) | the states a run reports are the extension's: waiting for the user, waiting for an event, waiting for its own background work, running, paused, idle, and held; the first that applies wins | VX-15 |

- **One open ask per run** is built behaviour and is written as such (VX-1): a run has at most one
  open ask at a time; a second from the same run is refused; a tool approval belongs to the
  execution whose tool call waits.
- **A held or waiting run says so everywhere** (ID-6 is applied, it follows from the answer and
  VX-14, VX-15): CA.5 (what a runtime reports with its registration), CK.1 / CK.9, CU.6 and CU.15
  show which run waits for which ask since when.
- **`RT > RT-ASKS` lead-in and N-15** no longer promise that an ask "does not hold a process up for
  long". They say what is true: an ask is never lost, is escalated, and is visible; the other runs
  go on; the user can answer, skip or resend the waiting item (VX-6).
- **Open, asked once (QT-1, by `p1s1r4-4`):** whether leases are kept while a run waits for an ask
  (AN-5), and whether a chat send in another session of the waiting run still goes out (VX-17).
  Until answered the text says neither: leases are held "for as long as the item is executed" as
  today, and CR.15 is not changed.
- **A new risk** (AN-7) is written by `p1s1r4-10`.

### 1.2 PQ-28: the web runtime client SDK and the web runtime service

**What the answer settles:**

1. A runtime does not run on a phone or tablet (nor in a browser).
2. Such an application uses a **web runtime client SDK**. It is provided in Dart and in
   JavaScript / TypeScript.
3. It talks to a **web runtime service** on a server. The service is HTTP-based, and one service
   may serve applications on phones and tablets and web applications (built with Flutter or not).
4. The service connects to a runtime on behalf of the device.
5. The two names are the product owner's suggestion and are used from now on.
6. "There is no given solution for this now": the architecture behind the names is open. The
   answer picks none of PQ-28's options (a), (b), (c).

**How it relates to what the document has:**

- **Runtime host server.** The document's term (agreed in S21) for "a program on a server that
  starts a runtime for each connected application". The parts write **web runtime service** where
  the document says "runtime host server", in their own sections; `p1s1r4-11` changes `GLO` and the
  terminology document. Whether the two are the same thing under a new name is open (QT-2). So every
  statement that describes how the service works (one runtime per connected application; the runtime
  ends with the application's connection; WebSocket) is kept and marked "assumed until PQ-<n>",
  not rewritten.
- **"Connect to the tac as usual from the server."** PQ-26 (a), answered the same day, says a server
  reaches tac only through the runtimes it starts, and no server uses the tac client SDK. The parts
  write: the web runtime service reaches tac through the runtime on the server (CI.4 and CL.11 stand).
- **Relay.** "Relay" stays the name of the tac server's relay only (CA.30). The answer's "an
  additional relay" is the web runtime service; the word is not used for it. "Remote runtime
  service" and "remote runtime client SDK" are not used.
- **Device pairing** (CI.18, CI.19, `GLO` device / pairing). Which program a paired device reaches
  from the internet, and which holds the device keys, stays open. The parts write "the server a
  device reaches from the internet (which program that is, is open: PQ-<n>)" and do not put a name
  there.
- **The wire.** CP.1 / D-10 stand for a host on the same machine and for a remote runtime client.
  For the web runtime service the text says "HTTP-based" (the answer) and that the event stream and
  the reverse requests (asks, the host's tools) over it are open.
- **Client SDK counts.** "One runtime client SDK and one tac client SDK per language, for nine
  languages" stands; the web runtime client SDK is added beside them as "in Dart and in JavaScript /
  TypeScript". No part writes that it replaces or extends another SDK.
- **First version.** D-51 ("the architecture for applications on phones and tablets is part of the
  first version") is not changed; it is one of the open points.

**Questions (asked once):**

| Key | Topic | Asked by | Findings |
| --- | --- | --- | --- |
| QT-2 | What the web runtime service is: the runtime host server under a new name or a front to runtimes that exist anyway; how long the runtime behind it lives; whose runtime it is and where its files, settings and secrets are; whether it also serves a web application's files | `p1s1r4-3` (at CR.46) | AN-20, AN-24, AN-25, GA-1, GA-2, WRS |
| QT-3 | The web runtime client SDK: a third SDK or the runtime client SDK with a second binding; which languages; what crosses HTTP (events, asks, host tools); the same convenience layer; TypeScript and JavaScript as one SDK (ID-9) | `p1s1r4-5` (at CL.1) | AN-22, AN-23, ID-9, WRS |
| QT-4 | Phones and tablets in the first version or not; which program is reachable from the internet and holds the device keys; whether tac's relay carries the runtime's protocol | `p1s1r4-7` (at CI.18) | AN-19, AN-21, AN-26, IC-19, IC-25, GA-16 |

### 1.3 PQ-29: the GitHub backend serves teams of several members

**What the answer settles (apply):**

- The local backend works on one machine only. Its team is the personal team of one user on that
  machine.
- The GitHub backend serves the single-member personal team of a user across that user's machines,
  **and** simple teams of several members.
- So: `GLO` team is not bound to a tac server; `GLO` personal team covers the local backend (one
  machine) and the GitHub backend (the user's machines that share the coordination repository);
  CA.26's GitHub row reads "one user's machines, or a simple team of several members"; CA.39 no
  longer says every user without a tac server has a personal team with only themselves; T3 stands
  and T4 gets the variant "a team on the GitHub backend".
- The document keeps the name **GitHub backend**. "Git-based" is the answer's word; whether another
  git server than GitHub is meant is part of QT-5.

**What cannot be applied without a further answer (ask, once each):**

| Key | Topic | Asked by | Findings |
| --- | --- | --- | --- |
| QT-5 | What a team on the GitHub backend has: CA.26 says "no messages across machines", so commands between runtimes, asks to other people, messaging, the review exchange, reminders and todo offers do not travel. Per capability: not available there, or carried by the repository. Also who computes presence and staleness without a service (IC-8), and GitHub only or any git server. With a capability table per backend as the recommended form (ID-5) | `p1s1r4-6` (at CA.26) | AN-30, AN-32, IC-8, ID-5 |
| QT-6 | Who is a member and an owner of a team on the GitHub backend: whoever can push to the coordination repository, or a record in it; whether invitation, team token and the owner-only rules (CI.5, CS.4) exist there or are agreements | `p1s1r4-7` (at CI.5) | AN-31 |

Until answered: the text says a team on the GitHub backend shares leases and endpoints through the
coordination repository, and that what else such a team has is open. No part extends messaging,
asks to other people or the review exchange to the GitHub backend.

### 1.4 PQ-30: no review application in this project

- **Out of scope, not later.** A new `O-<n>` in `SCO > SCO-OUT` (`p1s1r4-2`): "A review application
  of its own. Reviewing is part of the applications that carry the review component: the VS Code
  extension today, Webwork and Webforge later; none of them is built here." `GLO` loses "review
  application" (application, host, user entries; `p1s1r4-11`). No part writes "review application".
- **Every application reaches tac through a runtime, with the runtime client SDK.** CI.4, D-27 and
  X-3 stand without exception. CV.5 and CV.15 add "through its runtime".
- **Services that use tac directly** through the tac client SDK, for a part of tac such as
  messaging, are possible later and not planned: a new `L-<n>` in `SCO > SCO-LATER` (`p1s1r4-2`).
  CA.28's "tac clients in a browser" and N-26's "without `dart:io`" are kept as capabilities for
  that, marked as not used by any application of the first version.
- **Messaging.** In the first version messaging is in Webwork, through its runtime. The VS Code
  extension gets messaging once the runtime is built; its views are the extension's own and are not
  built here (O-1 stands).
- **Where the review component is built** is open and asked once (QT-7, `p1s1r4-5`, at CU.9): in
  this project as the Review group of `tom_ai_runtime_ui` (CU.6, CU.9, G-6), in the `tom_forge` quest
  (WW-1, R-19), or as the extension's shared web page behind a host (VX-48). Findings: IC-28, AN-34,
  WW-1, VX-48, TF-8. Until answered CU.6's Review group, CU.9, SC-18, G-6 and R-19 keep their text.
- "The documents reach webwork indirectly" in the answer is not explained and is not written.

### 1.5 PQ-31: resource names with a prefix

- A resource name starts with a **prefix that names its notation**. `git:` is the only prefix for
  now: `git:<owner>/<repository>` for a whole repository, `git:<owner>/<repository>#<pattern>` for a
  part of one, and `git:<server>/<owner>/<repository>…` in full when a team has more than one
  repository server. Further prefixes are introduced as they are needed.
- Examples are written `git:al-the-bear/tom_ai_build` and
  `git:al-the-bear/tom_ai_build#tom_ai_runtime/**`.
- CA.17 as option (a) words it, with the prefix: a runtime claims a part of the `_ai` state's
  repository for a todo only when the todo names it among its resources; todo state and journals
  are never named.
- CA.9: the two kinds of `tac/1.0` that "are not used for now" become "further prefixes can be
  added"; "a folder of the `_ai` state" is not a kind.
- Overlap is defined among `git:` names; resources of different prefixes never overlap.
- **Open, asked once (QT-8, `p1s1r4-6`, at CA.10):** the grammar's details — whether a name without
  a prefix is accepted from existing todos; how a document of a quest in a multi-quest repository
  is named, since the name has no branch (Q-14); whether the other prefixed notations (secrets
  `tsm:` / `os:` / `env:` / `file:`, messages `msg:`) and the addresses of CW.18 are written as one
  family (ID-4). Findings: AN-40, AN-41, AN-42, Q-14, ID-4.

### 1.6 The `_ai` restructuring and the three quest types

**The standard** is `_ai/quests/al_the_bear/ai_format_migration.md` (decided 2026-11-20, not built;
new source S22, § 4). Where it differs from the Project Idea, the Project Idea follows it, except
for what a decision of the product owner backs (below).

**What the Project Idea says from now on (apply):**

- **Three quest types**, one register. `PAR > PAR-QUESTS` CQ.1, `GLO` quest and CR.33:
  - a **classic quest** is a folder in the shared state repository (the standard's type `folder`);
  - a **repository quest** is a quest in a repository of its own kind, in one of two forms: a
    **single-quest repository** (one clone at the quest's place; the standard's type `repo`) or a
    **multi-quest repository** (one bare clone under `_ai/.quest-repos/`, each quest a branch
    `quest/<id>` checked out as a working tree at the quest's place; the standard's type `multi`);
  - the register `_ai/quests.yaml` lists every quest with its type; a workspace's list picks from
    it; a quest's checkout may be missing on a machine, which the runtime reports as a state.
- **The words.** "Classic quest" and "repository quest" stay (agreed in S21); the two forms are
  named "single-quest repository" and "multi-quest repository". The standard's words "folder quest"
  and "repo-based quest" are named once in `GLO` as its words for them.
- **The same inside for every type** (CQ.5: one resolver; its source is now S22 § 3.1, and its
  `___check here___` mark goes).
- **Format version 10** is what the runtime is built on (CR.3), with the quest folder's layout of
  S22 § 3, and the **four classes of files** (CR.2, a new item after it): shared and merged; per
  host and never merged; derived and not tracked; machine-local. Each store names its class.
- **Reminders of the queue are gone** (A-10, VX-41): CR.19 and E-1 lose them. The reminders that
  remain are the todo's (VX-39), the one reminder to an agent about its background work (VX-11) and
  tac's message kind (CM.4).
- **Memory** is the quest's: curated facts shared, candidates per host, promoted by the user; no
  shared scope across quests (A-8, VX-42).
- **The journal of asks and answers** per host and quest is a store of the runtime (A-6, VX-13,
  VX-44), written as planned with S22 as its source.
- **Quest operations** beyond create, join and migrate are added to CQ.7: pick and unpick for a
  workspace, remove from the workspace or the machine, pull / push / status started by the user,
  set up this machine, check and fix (Q-7, VX-46).
- **Built or planned.** None of this is built. `LAND` says so (`p1s1r4-2`); the `RT` and `PAR`
  items state it as what the runtime does, with S22 as the source.

**What it leaves open — questions, not silent changes:**

| Key | Topic | Asked by | Findings | Decision it would change |
| --- | --- | --- | --- | --- |
| QT-9 | Personal files: the standard keeps sessions, the compact trail, the journal, the host's configuration and memory candidates in the quest, one file per host, and has no personal repository; CQ.2 / CQ.3 put them into one personal repository per user, "never in a quest's" | `p1s1r4-8` (at CQ.2) | Q-3, Q-4, VX-43, A-4 | CQ.2, CQ.3, D-34 (FO-13, FO-22, DQ-…) |
| QT-10 | What of CQ.6 remains on top of the new types: a branch per member with a review of conflicts, the second repository with encrypted development credentials, the secret scan, member identity and access; and the trial migration of CQ.7 | `p1s1r4-8` (at CQ.6) | Q-6, IC-6, Q-7 | CQ.6, D-34 |
| QT-11 | Whether the quest operations are commands of the runtime (so every host gets them) or the VS Code host's view only; and whether a quest inside a project's repository is wanted | `p1s1r4-8` (at CQ.7) | Q-11, Q-2, TF-10 | — |
| QT-12 | When a format migration runs: the standard migrates on each host's first window after the update without a confirmation and records it in a versioned file; CP.29 / CP.32 say once per machine, under a lock, only when the user confirmed | `p1s1r4-4` (at CP.29) | A-14 | CP.29, CP.32 |

Until answered: CQ.2, CQ.3, CQ.6 and D-34 keep their text. No part writes "personal repository"
into new text, and no part writes the per-host files as decided where CQ.3 says otherwise; new
text about sessions, trails and the journal says "per host" and leaves the place to QT-9.

### 1.7 Names used by several parts

| Thing | Written as | Note |
| --- | --- | --- |
| The runtime's package | `tom_ai_runtime` (`tom_ai/ai_build/`) | "tar" in running text as the glossary allows |
| An installed copy of it | "the runtime installation" | "runtime" alone is a running instance (IC-9); CR.42, CL.5, F1, R-13 follow |
| The coordination service | "tac"; the program `tom_tac_service`; "tac server", "local tac service" with their kind | |
| Client SDKs | "runtime client SDK", "tac client SDK"; Dart packages `tom_ai_runtime_client`, `tom_tac_client` | |
| For phones, tablets, browsers | "web runtime client SDK", "web runtime service" | § 1.2; no package names are written |
| UI components | `tom_ai_runtime_ui` | |
| Who uses the tac client SDK | "runtimes and command-line programs of ours" | PQ-26 (a); "tools" there contradicted the glossary (AN-13) |
| Tom Secrets Manager | a program is "approved by" it; "pairing" is for devices only | PQ-32 (a) |
| The backends | "local backend", "GitHub backend", "tac server" | § 1.3 |
| Quest types | "classic quest", "repository quest", "single-quest repository", "multi-quest repository" | § 1.6 |
| Resource names | with the prefix `git:` | § 1.5 |
| The source of the `_ai` format | S22 | § 4 |
| Version numbers | only in `LAND > LAND-BUILT` and `RISK > RISK-DEPS`; other items refer to E-<n> | checked 2026-11-20 in the tree: `tom_todo_model` 4.2.0, the extension 0.1.0, `tom_tac_service` 0.1.0, `tomspecs` 0.17.0, `tom_vscode_scripting_api` 6.0.0 |
| Question rounds | not counted in items; an item cites the PQ id only | IC-33 |
| A run that cannot go on | "waits" or "is held", as § 1.1 defines them | |
| "review application", "runtime host server", "remote runtime service", "pairing with Tom Secrets Manager", "folder of the `_ai` state" (as a resource kind) | not written | |

## 2 The work list

One table per part. **Finding** is the id in its input file (`consistency_read.md`: IC, AN, GA, ST, ID; `inputs_vscode_extension.md`: VX, and VX-PQ24 for its section "Specifically for PQ-24"; `inputs_al_the_bear.md`: A, Q, AB; `inputs_webwork_tom_forge.md`: WW, TF, and WRS for its closing section on the web runtime service). Every finding has exactly one row, in the part that owns it. A finding that also reaches other parts is listed there in the second table of that part, "Also reaches this part": the owning row says what to do, the second table says where in this part.

**Ruling:** **apply** — write it, as the row says, citing the source named; **ask** — the row's question (§ 3) is written by the part named there, and the row says what the text says until it is answered; **drop** — nothing is written, for the reason given.

### 2.1 `p1s1r4-2` — `ABOUT`, `SRC`, `VIS`, `USR`, `SCO`, `LAND`

23 findings: 20 apply, 2 ask, 1 drop.

| Finding | Items (section chain) | Ruling | What the text is to say, the question, or the reason |
| --- | --- | --- | --- |
| **AN-34** | new O-<n> (SCO > SCO-OUT); new L-<n> (SCO > SCO-LATER) | **apply** | A new O-<n>: "A review application of its own. Reviewing is part of the applications that carry the review component: the VS Code extension today, Webwork and Webforge later; none of them is built here." A new L-<n>: services that use tac directly through the tac client SDK for a part of tac such as messaging, not planned. Where the review component is built is asked with IC-28 (QT-7). Source: PQ-30; triage § 1.4 |
| **AN-37** | U-8 (USR > USR-HOSTS); O-1 (SCO > SCO-OUT) | **apply** | In the first version messaging is in Webwork, through its runtime. The VS Code extension gets messaging once the runtime is built; its messaging views are the extension's own and are not built here (O-1 stands and names them). SC-27 and the Messaging group of CU.6 stay Flutter components; DEL places the extension's messaging after the runtime. Source: PQ-30; triage § 1.4 |
| **IC-3** | O-6 (SCO > SCO-OUT) | **apply** | O-6 names the second exception: besides the integration step, a repository on which no lease is held can be fast-forwarded automatically where the workspace switched that on (CW.16, off unless switched on). F11 says "nothing is converged for it unless the workspace switched the fast-forward of CW.16 on". Source: CW.16 (S6, BP-12, BP-18) |
| **IC-13** | VIS-SYSTEM host list (VIS > VIS-SYSTEM) | **apply** | The hosts are listed as programs: the VS Code extension; Webforge with its applications (the quest application, Webwork, trc); trc standalone; the web runtime service for phones, tablets and browsers (assumed until QT-2). A host may start several runtimes: one per open quest and one without a quest per application that needs one. Source: T2, CK.7, D-5; triage § 1.2 |
| **IC-14** | U-9 (USR > USR-HOSTS) | **apply** | U-9 loses "later": Webforge hosts trc as an application from the start; trc also runs standalone. Source: D-5 (FO-12), CK.7 |
| **IC-22** | L-11 (SCO > SCO-LATER) | **apply** | L-11 says what is later: billing, and running one tac server for several organisations. The first version has the account record, access keys, quotas per account and the administration interface, used with one account. Source: D-22 (CQ-9), CA.27 |
| **IC-25** | L-6 (SCO > SCO-LATER) | **ask** QT-4 (written by `p1s1r4-7`) | Whether end-to-end encryption between a device and a runtime is in the first version or later. Until answered L-6 is taken out of the decided deferrals and listed as an open point with CI.19 and N-21. |
| **IC-32** | E-1, E-2, E-3, E-6 (LAND > LAND-BUILT) | **apply** | The version facts are those of the tree on 2026-11-20: tom_todo_model 4.2.0, the extension 0.1.0, tom_tac_service 0.1.0, tomspecs 0.17.0, tom_vscode_scripting_api 6.0.0. Version numbers stand only in LAND > LAND-BUILT and RISK > RISK-DEPS; other items refer to E-<n>. Source: triage § 1.7; the packages' pubspec.yaml |
| **IC-33** | ABOUT status; ABOUT-READ (ABOUT > ABOUT-READ) | **apply** | Question rounds are not counted in items: an item cites the PQ id only, and where the answers are kept is named by the folder (01_02_Questions Round, 01_04_Questions Round). Source: triage § 1.7 |
| **GA-22** | USR > USR-GROUPS (new U-<n>); U-2 (USR > USR-GROUPS) | **apply** | USR names the people who act in the items: the coordinator of a review round (CV.12; glossary entry by PQ-33 (a)), a quest member (CQ.7), and a developer of a web application built with Flutter or not who uses the web runtime client SDK (PQ-28); U-2 says which application a reviewer uses (the VS Code extension today, Webwork and Webforge later, each through its runtime). Who operates the web runtime service is left to QT-2, and a developer outside this workspace and a person asked from outside the team are not added (R-14, L-3 stand). Source: PQ-33 (a); PQ-28; PQ-30 (triage § 1.4, AN-36); CQ.7. |
| **GA-25** | SRC (the sentence "Where two of them disagree, S1 wins") | **apply** | SRC says that an answer of the product owner (a PQ id) wins over every source, S1 included, and that S22 is the standard for the `_ai` folder and quests in repositories. CQ.5 takes S22 § 3.1 as its source and loses its `___check here___` mark; the screen inventory's standing is stated plainly (ST-2). The note on S9's secondary sources stands. Source: round_instructions § What decides, points 1 and 2; triage § 1.6 (CQ.5). |
| **GA-30** | SCO > SCO-IN (the row on the split) | **ask** QT-18 (written by `p1s1r4-3`) | What the VS Code extension is after the split: which of its features become the runtime's and which stay the host's own, that inside VS Code the runtime is not a process of its own (CP.1, so CP.2 does not apply there), and when the old line ends. Until answered SCO-IN keeps "no area of its own" and CP.2 keeps "a runtime started as a process of its own". |
| **ST-1** | ABOUT (status); ABOUT > ABOUT-READ (the PQ row) | **apply** | The status and the PQ row say that PQ-1 … PQ-33 are answered and taken into the text and name the open questions of this round by their ids; the decisions from PQ-24 … PQ-33 go to DEC as new ids from D-61 under a sibling heading and are cited as sources like the earlier ones. The ten question blocks stay until `p1s1r4-11` removes them. Source: answers.md (PQ-24 … PQ-33 answered 2026-11-20); round_instructions § Rules for the text (question blocks). |
| **ST-11** | ABOUT > ABOUT-READ; SRC (the rows S4, S6, S13, S21) | **apply** | Each id that comes from inside a source is explained once, in the row of its source or in ABOUT-READ: TQ-n and C-n (S21), BP-n, IDEA-n, "part-claims" and "part-messages" (S6), RT-n and RS-n (now only in the lead-in of DEC), DPMESSAGING-n (S13), and the notes a … n of S4. Source: the sources themselves (S4, S6, S13, S21); a correction with only one reasonable reading. |
| **ST-18** | VIS > VIS-SYSTEM (the count and the table) | **apply** | The table lists every program that runs somewhere: the runtime, the local tac service, the tac server with its relay, the web runtime service, and trc; and the libraries: the runtime client SDK and the tac client SDK per language, and beside them the web runtime client SDK in Dart and in JavaScript / TypeScript. The lead-in does not count "three components and two sets", and what the web runtime service is stays marked open (QT-2). Source: PQ-28 (triage § 1.2, Client SDK counts); T1 … T8. |
| **VX-54** | L-9 (SCO > SCO-LATER) | **drop** | nothing to change (confirms): Telegram stays deferred (L-9, D-6, X-10); an ask reaches a person away from the host through tac (CP.18) |
| **A-1** | S22 (SRC, new source) | **apply** | Add `_ai/quests/al_the_bear/ai_format_migration.md` as source S22: the format of the `_ai` folder and of the quest folder (format version 10), the quest types and the quest operations, decided 2026-11-20, not built; SRC says that for the `_ai` format and for quests in repositories S22 is the standard and S2 § 3.7 holds only where S22 says nothing. Source: PQ-24 (the answer names it the standard); triage § 1.6, § 4. |
| **A-11** | O-4 (SCO > SCO-OUT) | **apply** | O-4 adds one sentence: in the VS Code extension the "VS Code LM" transport inside the Anthropic panel stays until the route through the Copilot SDK works; the runtime carries neither host transport. Source: S22 § 2.3 (AC-19). |
| **Q-13** | E-14 (LAND > LAND-MISSING) | **apply** | E-14 adds that the register `_ai/quests.yaml` does not exist and that nothing of format version 10 or of the quest operations is built. Source: S22 § 5, § 7 (all todos not-started); triage § 1.6. |
| **AB-12** | E-5 (LAND > LAND-BUILT) | **apply** | E-5 says the merge drivers are built from the fleet's source (the al_the_bear repository) into the binaries repository, and the extension takes them from there (planned: vscode_extension `vscimpb152aaa_akqp-…`). The runtime registers the drivers on a machine and does not own their source; the finding's question is not asked, the product owner decided it. Source: al_the_bear `tsmergedrivers1_akqh` (completed 2026-11-18, the product owner's decision); S22 § 3.5. |
| **WW-17** | L-8 (SCO > SCO-LATER) | **apply** | L-8 names the wave: Webwork's web, phone and tablet builds have neither AI nor messaging until wave 3 of Webwork, and Webwork expects one server side to carry both; the server side is written "web runtime service" (triage § 1.2). Source: webwork decision DPPHONE-5; the idea part-wave-plan, Later todos; webwork todos `06_woneb9`, `13_woneb5`, `10_woneb1`; PQ-28. |
| **WW-20** | E-2 (LAND > LAND-BUILT) | **apply** | E-2 gives `tom_todo_model` as 4.2.0 (with `TomItem`, the reminder fields and the fields `role` and `guidelines`), and R-18 the same state. The rule that a todo field the runtime writes exists with the same meaning in `tom_todo_model` is not written here: it follows the question of TF-9. Source: checked in the tree (triage § 1.7); webwork todos `wwremind1`, `wwaspect1`. |
| **TF-7** | U-9 (USR > USR-HOSTS) | **apply** | U-9 adds that every application composed from Tom Forge's composition library holds the quest applications and is such a host: Tom Forge's own application, the TomSpecs editor and Webforge. Source: `spec_quest_workbench.tom_forge.md`, introduction (S14). |

**Also reaches this part** (ruled in the owning part's row; read that row and the finding):

| Finding | Items of this part | Owner | Ruling there |
| --- | --- | --- | --- |
| AN-8 | SRC (S22; the standing of S2 § 3.7 and S12), E-14 | `p1s1r4-8` | apply |
| AN-17 | E-3 (stands) | `p1s1r4-6` | apply |
| AN-19 | ABOUT status | `p1s1r4-7` | ask QT-4 |
| AN-20 | VIS-SYSTEM, L-8 | `p1s1r4-3` | ask QT-2 |
| AN-21 | V-3, SCO-IN row CA | `p1s1r4-6` | ask QT-4 |
| AN-22 | VIS-SYSTEM, SCO-IN row CL | `p1s1r4-5` | ask QT-3 |
| AN-25 | L-5 | `p1s1r4-3` | ask QT-2 |
| AN-26 | VIS-SYSTEM, SCO-IN row CK, V-7, U-5, L-8 | `p1s1r4-5` | ask QT-4 |
| AN-27 | U-6, U-7, E-9, E-10 | `p1s1r4-9` | apply |
| AN-32 | U-3, U-11, E-17, SCO-IN row CA | `p1s1r4-7` | apply |
| AN-36 | U-2, V-5, P-3 | `p1s1r4-7` | apply |
| AN-41 | E-2 | `p1s1r4-8` | ask QT-8 |
| AN-43 | U-7 | `p1s1r4-4` | apply |
| AN-45 | SRC row S21 | `p1s1r4-11` | apply |
| IC-12 | E-16 | `p1s1r4-3` | ask QT-16 |
| IC-30 | SCO-IN rows CP, CR, CI | `p1s1r4-10` | apply |
| IC-34 | VIS-SYSTEM row Client SDKs, SCO-IN last row | `p1s1r4-9` | apply |
| GA-1 | U-7 (USR > USR-GROUPS) | `p1s1r4-3` | ask QT-2 |
| GA-6 | E-16 | `p1s1r4-3` | ask QT-16 |
| GA-10 | P-7 | `p1s1r4-8` | apply |
| GA-11 | O-6 | `p1s1r4-8` | apply |
| GA-17 | SCO > SCO-OUT, SCO > SCO-LATER | `p1s1r4-7` | ask QT-4 |
| GA-18 | USR > USR-TEAM | `p1s1r4-9` | apply |
| GA-23 | U-1 … U-13, V-1 … V-8, P-1 … P-4 | `p1s1r4-11` | ask QT-21 |
| GA-24 | ABOUT > ABOUT-READ (the PQ row) | `p1s1r4-10` | apply |
| ST-3 | LAND > LAND-BUILT, O-4 | `p1s1r4-6` | apply |
| ST-5 | ABOUT > ABOUT-READ | `p1s1r4-11` | ask QT-21 |
| ST-7 | O-4, O-9 | `p1s1r4-11` | ask QT-21 |
| ID-1 | SCO > SCO-LATER | `p1s1r4-11` | ask QT-21 |
| ID-10 | USR, VIS | `p1s1r4-11` | ask QT-21 |
| VX-33 | E-2 | `p1s1r4-3` | apply |
| VX-36 | E-1 (the todo model's fields) | `p1s1r4-3` | apply |
| VX-38 | E-1 (todo groups) | `p1s1r4-3` | apply |
| VX-39 | E-1 | `p1s1r4-3` | apply |
| VX-40 | E-2 | `p1s1r4-3` | apply |
| VX-41 | E-1 (reminders and the two host transports marked as leaving), O-4 | `p1s1r4-3` | apply |
| VX-45 | E-1, E-5 | `p1s1r4-4` | apply |
| VX-55 | E-1 (LAND-BUILT does not count the registry as built) | `p1s1r4-3` | apply |
| A-2 | E-1 | `p1s1r4-3` | apply |
| A-10 | E-1 | `p1s1r4-3` | apply |
| Q-1 | E-14 | `p1s1r4-8` | apply |
| Q-3 | E-14 | `p1s1r4-8` | ask QT-9 |
| Q-10 | O-6 | `p1s1r4-8` | apply |
| AB-3 | E-4 | `p1s1r4-3` | apply |
| AB-9 | O-6 | `p1s1r4-8` | apply |
| AB-10 | O-6 | `p1s1r4-8` | ask QT-23 |
| AB-11 | E-17 | `p1s1r4-8` | apply |
| AB-14 | O-6 | `p1s1r4-8` | ask QT-13 |
| WW-11 | E-15 | `p1s1r4-3` | ask QT-22 |
| WW-18 | U-2 | `p1s1r4-7` | apply |
| WW-19 | E-10, new E-<n> in LAND-BUILT | `p1s1r4-5` | ask QT-7 |
| WW-22 | E-15 | `p1s1r4-10` | apply |
| TF-1 | E-16, S14 (its note "outdated" stands) | `p1s1r4-10` | apply |
| TF-2 | O-4 (check only) | `p1s1r4-4` | ask QT-16 |
| TF-9 | E-2 | `p1s1r4-3` | ask QT-23 |
| TF-10 | SCO-LATER (the web build of the quest workbench) | `p1s1r4-8` | ask QT-11 |
| TF-14 | E-16 (check only) | `p1s1r4-10` | drop |
| WRS | L-8 | `p1s1r4-3` | ask QT-2 |

### 2.2 `p1s1r4-3` — `RT-HOLDS` … `RT-INSTALL`

80 findings: 59 apply, 17 ask, 4 drop.

| Finding | Items (section chain) | Ruling | What the text is to say, the question, or the reason |
| --- | --- | --- | --- |
| **AN-4** | CR.13 (RT > RT-RUNS); CR.17 (RT > RT-QUEUE); CR.20 (RT > RT-QUEUE) | **apply** | Every waiting rule has the run as its subject and refers to CP.21: CR.17 "the run waits until the host reports that the user applied or discarded the result"; CR.20 split into the waits (declared wait, own background work) and the interrupts; CR.13 is no wait (the step is refused, nothing is queued); CS.10 "the user is asked to unlock, and the run waits as for any ask (CP.21)"; CW.4 "the item waits and says who holds the lease; its run sends nothing else meanwhile". Source: PQ-24 (b); triage § 1.1 (table) |
| **AN-6** | CR.23 (RT > RT-QUEUE) | **apply** | CR.23 lists the states a run reports: waiting for the user, waiting for an event, waiting for its own background work, running, paused, idle, and held; the first that applies wins. CA.5 carries which runs wait or are held; CK.1, CK.9, CU.6 and CU.15 show which run waits for which ask since when; F4 and F5 say "the run waits"; D-20 gets the clause; CP.9 and CP.22 stand. Source: PQ-24 (b); triage § 1.1 (VX-14, VX-15; ID-6 applied) |
| **AN-9** | CR.18 (RT > RT-QUEUE) | **apply** | CR.18: "A run can start a session over: the next prompt starts without the earlier context; what was said before stays readable in the trail." GLO session: a named line of conversation with a model, belonging to a run, that can be started over. Source: PQ-25 (a) |
| **AN-14** | CR.46 (RT > RT-INSTALL) | **apply** | CR.46 gets the statement of the option taken, with the service's name: the web runtime service reaches tac only through the runtimes it starts; it checks a connecting application against its own configuration or by starting the runtime, which then presents the user's team token. It is marked "assumed until" the question of QT-2, as every statement on how the service works. Source: PQ-26 (a); triage § 1.2 |
| **AN-20** | CR.46 (RT > RT-INSTALL) | **ask** QT-2 (written by this part) | Whether the web runtime service is the runtime host server under a new name or a front to runtimes that exist anyway. Until answered every part writes "web runtime service" where the document says "runtime host server", and each statement on how it works (one runtime per connected application, ending with the connection, WebSocket) is kept and marked as assumed. |
| **AN-24** | CR.7 (RT > RT-HOLDS); CR.40 (RT > RT-INSTALL); CS.1 (RT > RT-CONFIG) | **ask** QT-2 (written by this part) | Whose runtime runs behind the web runtime service, and where its user settings, secrets, installation and clones are. Until answered the items keep their text, with a remark that they are stated for a host on the user's machine. |
| **AN-25** | CR.46 (RT > RT-INSTALL); CR.44 (RT > RT-INSTALL) | **ask** QT-2 (written by this part) | How long the runtime behind the web runtime service lives: until the application's connection ends (a phone loses it in the background) or on its own. Until answered "ends with that application's connection" is kept and marked as assumed. |
| **IC-9** | CR.42 (RT > RT-INSTALL); CR.6 (RT > RT-HOLDS); CR.7 (RT > RT-HOLDS) | **apply** | The files on disk are "the runtime installation"; "runtime" alone is a running instance. CR.42: hosts on one machine share one runtime installation, each starts its own runtime. CR.6 and CR.7 say "runtime", not "runtime instance". Source: triage § 1.7; GLO runtime; CR.44 |
| **IC-12** | CR.44 (RT > RT-INSTALL); CR.6 (RT > RT-HOLDS) | **ask** QT-16 (written by this part) | Whether two hosts on one quest are two runtimes or one runtime with two runtime clients, and which runtime executes a run. Until answered N-10, T2, CR.44, CA.6 and CP.5 keep their text. |
| **GA-1** | CR.46 (RT > RT-INSTALL) | **ask** QT-2 (written by this part) | What the program for phones and browsers (the web runtime service) is as a product part: who starts and operates it, what it authenticates, how many runtimes it starts, what it stores, how it is updated, and which unit, deliverable and document it gets. Until answered CR.46 keeps its statements marked "assumed until PQ-<n>" and no unit, deliverable or user group is added for it. |
| **GA-2** | CR.46 (RT > RT-INSTALL); CR.7 (RT > RT-HOLDS) | **ask** QT-2 (written by this part) | Whose runtime runs behind the web runtime service on a shared server, and where its settings, secrets, installation and clones are. Until answered CR.7 stands ("belongs to exactly one person") and CR.46 says that the person, the files and the secrets of a runtime behind the web runtime service are open (PQ-<n>). |
| **GA-4** | CR.15 (RT > RT-QUEUE) | **apply** | State it: a run executes one item at a time, the runs execute in parallel, and a run whose next item cannot start waits without later items jumping ahead; so while a run waits (CP.21) it has no other execution of its queue. CW.7's sentence then reads that the list is what the runs use so that only todos whose resources do not overlap are executed at the same time. The chat send beside the run's item is left to QT-1 and CR.15's chat sentence is not changed. Source: VX-17 (`vscimpb46_akjp-queue-lanes-per-run`, built); PQ-24 (b); triage § 1.1. |
| **GA-6** | CR.44 (RT > RT-INSTALL) | **ask** QT-16 (written by this part) | Two hosts on one quest: which runtime executes a run, and how two runtimes of two people on one repository quest share the one process position. Until answered CR.44, N-10 and T2 keep their text and no rule on which runtime executes a run is written. |
| **GA-15** | CS.3, CS.4, CS.5 (RT > RT-CONFIG) | **apply** | No source lists it, so one line under CS.5 says what the Solution Blueprint must settle: which keys the team owns and which it only suggests, where the copy for offline starts is kept, and that a runtime uses the configuration of the home team of its quest when its person belongs to several teams (the allowed providers of CS.6 included). Source: round_instructions § What decides, point 5; CS.4, CS.6 (S1 § 5.5, DQ-8). |
| **GA-28** | CR.12 (RT > RT-RUNS); CR.22 (RT > RT-QUEUE); CS.3 (RT > RT-CONFIG) | **apply** | CR.22 adds that the team's allowed providers (CS.6) limit both the todo's and the item's choice; one line under CS.3 and CR.12 says what the Solution Blueprint must settle: in which repository role types, process definitions and prompt templates lie when a quest works on several, and what "the revision of the process definition" is. Source: CS.6 (S1 § 5.5, DQ-8); round_instructions § What decides, point 5. |
| **VX-6** | new item in RT > RT-QUEUE (after CR.16); CR.16 | **apply** | The commands a user has on an item that is being executed: answer its open ask; resend the stage (the turn is cancelled and the same stage sent again with a note that it was interrupted); skip to the next stage or todo; stop (the item goes back to staged). Resend, skip and stop close an open ask unanswered (VX-5). Continuing an item that waits always offers these choices and never acts by itself; a question that waits long has no timeout. Source: vscimpb55_akkh-queue-item-waiting-for-answer (done) |
| **VX-9** | CR.20 (RT > RT-QUEUE), the part on waits; CR.23 | **apply** | The declared wait: an agent declares a wait for something only time resolves, with a reason and an end, at most 48 hours; the item stays in execution and its run waits (nothing else is sent from its queue, the other runs go on); the run reports "waiting for an event" with the reason and the time left; the wait survives a restart; the user can interrupt it: the agent ends its turn with a note of what is still to do, the item steps back behind the next pending item of its run (to staged when none follows) and its stage is sent again later with a resume note. Source: vscimpb82_akmi-session-wait-tool (done); triage § 1.1 |
| **VX-10** | CR.16 (RT > RT-QUEUE); CR.20 | **apply** | CR.16: an update to the prompt being executed also reaches a turn that waits (a declared wait, its own background work), and the wait goes on afterwards; where it is taken depends on the transport kind: an agent transport takes it as a further user message of the running query, a model transport as the next user message of its tool loop; a declared wait returns with the message and is entered again with the same end. Each message is kept with the item together with what became of it, and recorded in the journal of asks and answers. Source: vscimpb173_akrn-message-into-waiting-turn (done) |
| **VX-11** | CR.20 (RT > RT-QUEUE), the part on waits | **apply** | Waiting for the item's own background work: the work counts as alive while its process is alive, not while it prints; the wait has a limit set per item, else per profile, else 6 hours (0 means no wait); a command that detaches itself is refused in a queue execution on an agent transport; when a turn ends its answer while its work still runs, the runtime sends the agent one reminder prompt into the same turn (an editable template); the user can wait without a limit, restart the limit, or stop waiting. The run "waits" (triage § 1.1). Source: vscimpb56, vscimpb57 (done), vscimpb143_akps-own-background-work-reminder-prompt (done) |
| **VX-12** | CR.19 (RT > RT-QUEUE) | **apply** | After each todo of a walk the runtime reads the todo: when it is not completed and names no blocker, decision or open question, the runtime sends a continuation into the same session, at most a set number of times (default 2, set per item and per run); then the item stops as "needs attention" and its run is held. The answer kept for the todo is that of the last turn. Source: vscimpb58_akkj-walk-iteration-completion-check (done) |
| **VX-15** | CR.23 (RT > RT-QUEUE) | **apply** | CR.23 names the states a run reports, the first that applies wins: waiting for the user (an ask, approval, plan, pick or document ask of the run is open), waiting for an event (a declared wait, with reason and until when), waiting for its own background work, running, paused (by the user, with the count of pending items), idle; and held (its next item is not executed: open decisions, a blocked todo, needs attention, an error, out of budget; a soft interrupt). Each state carries its detail and is published with the runtime's registration. Source: vscimpb123_akon-tom-info-sidebar-runs-overview, vscimpb112 (done); triage § 1.1 |
| **VX-16** | new item in RT > RT-QUEUE (after CR.15) | **apply** | The states of a queue item: staged (queued but not released; the state of a new item), pending, being executed, done, error, held on a todo's open decisions, held on a blocked todo, interrupted; an item being executed carries the marks waiting for the user, waiting for an event, waiting for its background work, held, needs attention, yields after this iteration. Staged is distinct from pending. Source: vscimpb55, vscimpb37, vscimpb112 (done); the extension's user guide § 4 |
| **VX-17** | CR.15 (RT > RT-QUEUE) | **ask** QT-1 (written by `p1s1r4-4`) | Whether a chat send in another session of a run whose ask is open still goes out (as the extension does: a chat send is outside the run's lane and holds one busy slot per session) or waits behind the ask like every other item. Until answered CR.15 is not changed; the lane rule that is built is written beside it: one item of a run is executed at a time, the runs work in parallel, and a run whose next item cannot start waits without its later items jumping ahead (vscimpb46, done). |
| **VX-18** | CR.8 (RT > RT-RUNS); new item in RT > RT-QUEUE; CR.36 (RT > RT-MACHINE) | **apply** | A run's queue settings are: automatic sending, automatic start, automatic pause when all its items are done (default on), automatic continuing after a restart, the defaults of new items (transport, profile, prompt template, session; planned: role and guideline choices, gsel3) and the number of walk continuations; shared by all runs are only the models for compaction and memory extraction. Rule: whatever stops sending by itself stops one run only (an error, an interrupt, a walk that needs attention or is held, out of budget, automatic pause, pause after this item); switching automatic sending off never interrupts the item being executed. The settings are kept per quest and run in the machine-wide state, and a writer writes only the runs it changed (CS.2). Source: vscimpb60a_aklu-queue-settings-per-run, vscimpb168_akri-queue-run-pauses-itself (done) |
| **VX-19** | CR.8 (RT > RT-RUNS); CR.15 | **apply** | A run is created with its default session `default@<run>`, based on the default run's session `default@default`; an item that names no session is executed in its run's default session. Source: qrun1_aklu-run-default-session, vscimpb151_akqh-run-switch-default-session (done); PQ-25 (a) |
| **VX-20** | CR.18 (RT > RT-QUEUE); new item after it on sessions | **apply** | A session has a base, a lifetime and optionally a profile. Lifetimes: continue (one conversation; with a base its first prompt starts from the base's conversation), per prompt (every prompt starts again from the base or fresh and changes nothing), per iteration (one conversation per repetition or per todo of a walk, continued by its pre-prompts and follow-ups). An item whose profile cannot continue the session's existing conversation is refused when it is queued. A temporary session is created for one item and removed when the item and its notification are done. A session can be started over (PQ-25 (a): the conversation is forgotten, the definition stays) and deleted with its storage. Source: the extension's user guide § Named sessions (built); PQ-25 (a) |
| **VX-21** | CR.9 (RT > RT-RUNS) | **drop** | nothing to change (confirms) |
| **VX-22** | CR.8 (RT > RT-RUNS); CR.9 | **apply** | The subject of a run is a run parameter its process declares, set by the process's first step and shown wherever the run is shown and in the process context of the prompt; planned: preset with the run's name. Source: vscimpb118_akoi-process-run-subject-variable (done); vscimpb156_akqk-preset-process-subject-with-run-name (planned) |
| **VX-23** | none until answered (a new item in RT > RT-QUEUE if it is the runtime's) | **ask** QT-18 (written by this part) | Whether the quest refresh (a prompt queued after a set number of prompts, with the marker that keeps items of a process step from counting) is a feature of the runtime or the VS Code host's own. Until answered the text says nothing about it. |
| **VX-24** | CR.10 (RT > RT-RUNS); CR.11 | **apply** | Two details are added: a decision step has three modes (decided by a condition, by the user, or by the agent's judgement with a recorded reason); a subprocess the agent suggests is shown only after the step's items are done, and the step's move waits for the user. The rest confirms CR.10 and CR.11. Source: vscimpb95 (done); ccparity_e_process-8 (done) |
| **VX-25** | CR.5 (RT > RT-HOLDS) | **apply** | Plan mode is per run: while it is on for a run, every writing tool is refused on every transport, reading and asking work; only the user ends it, and a prompt that ends while its plan is proposed leaves plan mode on. Source: vscimpb81_akmi-one-question-per-run (done) |
| **VX-26** | CR.15 (RT > RT-QUEUE); CR.19 | **apply** | An item has a kind: a todo, a group, a prefix (a walk over the todos of an id prefix), an iteration (a repeated prompt), a chat send, a prompt. An item bound to a todo does more than a prompt: the todo's record is appended to the prompt, the todo is claimed (in progress) when the item is sent and handed back when the send fails, and its completion is checked (VX-12). A group item walks the members of a group todo in their order, and the user or an agent can choose which members still to come are sent. One walk engine serves prefix, todo and group items. Source: vscimpb127_akon-queue-todo-and-group-items, vscimpb128, vscimpb129 (done) |
| **VX-27** | CR.19 (RT > RT-QUEUE) | **apply** | A walk takes the lowest-numbered open todo; it passes completed and cancelled todos and the user's own. It holds at the first todo it cannot run, never earlier: a todo with open decisions or one blocked by a todo that is not done (a blocker that runs earlier in the same walk or in an item ahead does not hold). The item is then held, its run is held (automatic sending off) and the user is notified. On a held item the user can stop, continue (the todo is skipped) or run it anyway; skipping is the user's action, not the runtime's. A walk with nothing to do ends as an error at once. Source: vscimpb37_akjl-decision-needed-holds-only-next (done); triage § 1.1 |
| **VX-28** | new item in RT > RT-QUEUE (after CR.19) | **apply** | Planned: when the blocker of a held item is completed or cancelled anywhere (the same run, another run, another quest), the item goes back to pending and its run's automatic sending is switched on again if the hold switched it off (a run the user paused stays paused); a setting per run, default on; the same for a release condition on a package version. Until it is built a held run goes on when the user resumes it. Source: vscimpb179_akss-blocked-item-resumes-by-itself (planned); PQ-8; D-45; triage § 1.1 |
| **VX-30** | CR.16 (RT > RT-QUEUE); new item after CR.19 | **apply** | A repeating item holds its run until its last iteration. "Next" under a repeating item means between two of its iterations; a repeating item can let the next pending item go first and resumes after it with its position kept; an item can be marked to pause its run when its last stage is done; a pending item that is being edited is not sent until it is saved. Source: vscimpb60e_aklv-iteration-item-yields-to-next (done); the extension's user guide § 4 |
| **VX-31** | CR.20 (RT > RT-QUEUE), the part on interrupts; CR.28 (RT > RT-TRANSPORTS) | **apply** | CR.20 is split (triage § 1.1): an update (CR.16) is text the running prompt reads; a soft interrupt holds the execution at the result of its next tool call, the turn stays open and the run's automatic sending goes off; without a hold point within 15 seconds it becomes a hard interrupt unless the user asked to wait; a turn waiting in an ask, a declared wait or for background work counts as held at once, and an answer given meanwhile is kept until resume. Resume hands the held result back and sends nothing again. A hard interrupt cancels the prompt: the item is interrupted and its current repetition is sent again on resume, with a note, in the same conversation. After a restart while held, a model transport continues where it stopped and an agent transport is sent the prompt again with the note and the held result. Source: vscimpb112_aknq-soft-interrupt-for-continuation-and-run-tab-icons (done) |
| **VX-32** | new item in RT > RT-QUEUE; CR.27 (RT > RT-TRANSPORTS) | **apply** | An item stopped for lack of credit is marked out of budget and its run is held. It can be continued on another profile by the user, by an agent, or automatically through a configured fallback: the stopped stage is sent as a hand-over prompt (what stopped where, the session's live trail, the original prompt), in the item's session unless that profile cannot continue the conversation, and the later stages follow on that profile. Source: ccparity_e_process-10_aker-continue-on-profile-tool (done); triage § 1.1 |
| **VX-33** | CR.21 (RT > RT-QUEUE) | **apply** | The done notification is a prompt queued ahead of every other pending item when the item is finished or has ended in an error that will not recover (not for a quota or rate-limit wait), once per run of the item. It carries the outcome, the item's answer (per todo for a walk, shortened with a pointer), its title, its todos with their status and the sending quest and run, and can be aimed at a named quest and run. Every item records who queued it (quest, run, session). A todo's done notification has no default: it goes to the run and session that queued the todo, and without one nothing is sent, which is logged. Source: vscimpb71, vscimpb72 (done), vscimpb146_akps-done-notification-to-queuing-session (done) |
| **VX-35** | CR.15 (RT > RT-QUEUE), one sentence | **apply** | A todo is queued once: an item whose todos are already staged, pending or being executed in the quest is refused, unless the caller says the repeat is meant. Source: vscimpb77_akkk-one-todo-enqueued-three-times-in-110ms, ccparity_e_process-2 (done) |
| **VX-36** | CR.22 (RT > RT-QUEUE) | **apply** | CR.22 extends to role and guideline choices: a todo can name the role and the guideline choices it is executed with (the fields are built). Planned: the role of a queued prompt is the todo's, else the item's, else the role of the step that queued it, else the run's; a run's queue defaults may name a role; a todo can name its profile and chat variables that are set while it runs, with a flag to unset them when it is finished; a todo's profile that does not exist or cannot continue the walk's session is an error when the item is queued, never a fallback. Source: gsel1_aktl (done); gsel3_aktl-roles-on-todos-items-runs (in progress, planned); vscimpb174_akrr-todo-profile (planned) |
| **VX-37** | CR.5 (RT > RT-HOLDS); CR.2 | **ask** QT-18 (written by this part) | Whether the level "window" of the guideline choices (today one host on one machine) is the runtime instance or the host in the runtime, or stays the VS Code host's own. Until answered the text says: prompt assembly takes one option's text per section from a store of aspect guidelines shared by every quest and machine, placed in the system prompt or before the user prompt on every transport (store and resolver built, gsel2; the selector planned, gsel4 … gsel10), with the choice resolved over section default, quest default, run, role type, role, item and todo, the last winning; the window level is not written. |
| **VX-38** | CR.2 (RT > RT-HOLDS); CR.19 (RT > RT-QUEUE) | **apply** | There are two kinds of todo group: all todos of an id prefix, and a group todo that names its members (also of other quests). A group todo is completed by itself when all its members are done; what a todo is a part of is derived; members of another quest are not walked by the group's item. Source: vscimpb125_akon-todo-groups-status-and-comprised-of, vscimpb126 (done) |
| **VX-39** | CR.2 (RT > RT-HOLDS); CR.19 (RT > RT-QUEUE); CR.44 (RT > RT-INSTALL) | **apply** | CR.2 adds to a todo's dates: a due date with a derived overdue state and one reminder; a reminder schedule that rings while the todo is open; one-shot reminders; repetition (the todo comes back after it is done). They are checked on the runtime's one clock, the tick of the timed requests, and ring through the user notification. Consequence of CR.44, said there: they ring only while a host has the runtime running; a missed moment rings once at the next start. These are the todo's reminders that remain (triage § 1.6). Source: vscimpb152aa_akoq-todo-due-reminder-overdue, vscimpb152ab_akoq-todo-reminder-schedule, vscimpb34 (done) |
| **VX-40** | CR.2 (RT > RT-HOLDS) | **apply** | CR.2 adds to what a todo carries: a mark that only the user can do it (a walk passes it; it is shown among what is directed at the user); the block of open decisions with the status "decision needed" until they are answered; what happens when it is done and who filed it (written from the caller's context, never by the agent); the answer of the execution that completed it. The views of what waits for a person are built from these. Source: ww_a_collab-2, ww_a_collab-5 (done); the extension's user guide § Your own todos, § Decisions |
| **VX-41** | CR.19 (RT > RT-QUEUE) | **apply** | CR.19 loses "and reminders after a wait": the queue has no reminders. The reminders that remain are the todo's (VX-39), the one reminder to an agent about its background work (VX-11) and tac's message kind (CM.4). O-4, D-7 and CS.13 stand (the host transports and everything of Copilot's chat path are removed; Copilot only through direct calls and its SDK). Source: triage § 1.6; S22; 01_aifmt-1_aktn-copilot-removal (planned, decided) |
| **VX-42** | CR.2 (RT > RT-HOLDS) | **apply** | Planned: memory is the quest's: curated facts shared by its members, and candidates per host (each naming its session) that the user promotes with a prompt; there is no scope shared across quests and no session level. Saved prompts are per quest; quest notes are several files of the quest; a workspace has notes of its own. The place of the per-host files follows QT-9. Source: triage § 1.6; S22; 01_aifmt-3_aktn-quest-prompts-notes-memory, 00_aifmt-3 (planned) |
| **VX-44** | CR.2 (RT > RT-HOLDS) | **apply** | Planned: a journal of asks and answers per host and quest is a store of the runtime: the questions put to the user by the ask tools with their answers and the run of each, the answers handed to the user without an ask (VX-13), and the messages written to waiting turns, in time order; the decisions document of a quest is a rendering of the archived todos' decisions. The place of the store follows QT-9: the text says "per host" and names no place. Source: triage § 1.6; S22; 01_aifmt-4_aktn-per-host-trail-qa-history (planned) |
| **VX-47** | CR.2 (RT > RT-HOLDS); CR.33 (RT > RT-LOCATIONS); CR.34 | **apply** | A quest has a short description as one of its files (a title, two to four sentences, a state line), required when a quest is set up and served with the list of quests; a workspace is named after the root folder the host opened. Planned: what the runtime answers about a workspace includes the repositories of `repos.yaml`, each with a description and whether it is cloned on this machine. That the quest refresh keeps the short description current is not written (QT-18). Source: vscimpb144_akps-ai-workspace-quests, vscimpb145_akps-quest-short-description, questsetup1 (done); vscimpb154, 00_aifmt-2_aktn-workspaceinfo-repos (planned) |
| **VX-52** | CR.27 (RT > RT-TRANSPORTS); CR.36 (RT > RT-MACHINE) | **apply** | CR.27: usage and cost are reported per round and per prompt, also in a resumed conversation of an agent transport (the prompt's own rounds, tokens and cost, not the whole session's). CR.36 adds the usage ledger to the machine-wide state: usage and cost per day and model, for the last 62 days, added as each round's response arrives. Source: qrfix3_akgu-agent-sdk-per-prompt-usage (done); the extension's `src/utils/usageLedger.ts` (exists; 62 days, per day and model) |
| **VX-53** | CR.19 (RT > RT-QUEUE) | **apply** | Timed requests have two modes (every so many minutes; at times of day, daily or once on a date), a switch for all of them and a switch per entry (both must be on), and a maximum number of sends after which the entry pauses. Their tick is the runtime's one clock: the checks of repeated todos and of todo reminders run on it. Source: vscimpb24_akjl (done); the extension's user guide § 5; vscimpb152ab (done) |
| **VX-55** | CR.4 (RT > RT-HOLDS) | **apply** | CR.4 is written as planned: the registry of cleanup tasks (each task finds and applies, run by an agent through a tool) is decided and not built. Source: aaa_cleanup1_akki-cleanup-tasks-and-tool, aaa_cleanup2 (planned) |
| **VX-57** | none until answered (a new item in RT > RT-QUEUE if it is the runtime's) | **ask** QT-18 (written by this part) | Whether a prompt stored for after a restart (queued at the front of a run when the runtime starts and sent also while the run is paused; built in the extension, vscimpb109) is a feature of the runtime or the VS Code host's own. Until answered the text says nothing about it. |
| **A-2** | CR.3 (RT > RT-HOLDS) | **apply** | CR.3 names the starting point: the runtime is built on format version 10 of the `_ai` files, with the quest folder's layout of the standard; CR.1 stands. Written as what the runtime does, not built today. Source: S22 § 3.2, § 3.6; triage § 1.6. |
| **A-3** | new item after CR.2 (RT > RT-HOLDS) | **apply** | A new item states the four classes of a quest's files: shared and merged between machines; per host, tracked, one file per host and never merged; derived when needed and not tracked; machine-local and not tracked. Every store of CR.2 names its class, which decides whether it travels. Source: S22 § 2.2 (CQ classes), § 3.2; triage § 1.6. |
| **A-5** | CR.15 (RT > RT-QUEUE); new item beside CR.18 (RT > RT-QUEUE) | **apply** | A session carries a required choice made when it is created, "contributes to trail and memory"; with it off, the session's turns go neither into the host's trail nor into memory or history; existing sessions count as on. Written as planned. Source: S22 § 2.2 (CQ-7, CQ-14, CQ-18). |
| **A-6** | new item after CR.2 (RT > RT-HOLDS) | **apply** | The journal of asks and answers is a store of the runtime: every ask put to the user with its answer, and every answer given to the user, is recorded per host and quest in time order, and the views of asks and answers read every host's journal. Written as planned and "per host", the place left to QT-9; a line under it says the Blueprint settles whether an ask answered on another machine through tac is recorded in the asking host's journal. Source: S22 § 2.2 (CQ-2, CQ-15, QJ-1); triage § 1.6. |
| **A-8** | CR.2 (RT > RT-HOLDS) | **apply** | Memory is the quest's: curated facts are shared, candidates are kept per host and promoted by the user's decision; there is no scope shared across quests and no session level. Whether a runtime instance without a quest (CR.6) has any memory is part of QT-15 and is not written here. Source: S22 § 2.2 (CQ-8, CQ-18), § 2.3 (AC-17); triage § 1.6. |
| **A-9** | CR.2 (RT > RT-HOLDS); CS.3 (RT > RT-CONFIG) | **apply** | CR.2 names saved prompts as a store of the quest (its `prompt/` folder, shared) and the notes: quest notes in the quest, workspace notes per workspace in `_ai/workspaces/`; CS.3 keeps prompt templates in the repository's configuration and says saved prompts are not part of it. The per-machine notes file is the VS Code host's own (SC-17). Source: S22 § 2.3 (AC-4, AC-5, AC-11, AC-12), § 3.2. |
| **A-10** | CR.19 (RT > RT-QUEUE) | **apply** | CR.19 loses "and reminders after a wait": the queue sends no reminders. The reminders that remain are the todo's, the one reminder to an agent about its background work and tac's message kind (CM.4). The finding's own question (a reminder after a wait for an ask) is not asked: the escalation of CP.18 covers an ask nobody answers. Source: S22 § 2.3 (AC-22); triage § 1.6. |
| **A-12** | - | **drop** | nothing to change (confirms) |
| **A-13** | CR.36 (RT > RT-MACHINE); CR.37 (RT > RT-MACHINE) | **apply** | Nothing of the machine-wide state, of the local tac service's store or of the inbox lies in `_ai`: its top level is a closed list that a commit guard keeps. A line under CR.36 says the Blueprint settles the place outside `_ai`. Source: S22 § 1, § 3.6. |
| **Q-9** | CR.33 (RT > RT-LOCATIONS) | **apply** | CR.33 adds the register `_ai/quests.yaml`: every quest of the `_ai` with its type and setup; a workspace's list picks from it, and without a list every quest counts; a repository quest's checkout may be missing on a machine, which the runtime reports as a state of the quest and not as an error of the store. Source: S22 § 3.4, § 2.4 (QM-1, QM-2), § 4; triage § 1.6. |
| **AB-1** | CR.33 (RT > RT-LOCATIONS); CR.32 (RT > RT-LOCATIONS) | **apply** | CR.33 says its places are defaults: the root's `.tom/tom_root.yaml` and a workspace folder's optional `.tom/tom_workspace.yaml` can name other places for `_ai`, the guidelines and the configuration; CR.32 says a host passes the overrides it holds (in VS Code those of the quest's `.code-workspace`). Source: S12; the root guideline `workspace_layout.md` § 2, § 3, § 5 (built in the extension's resolver, E-4). |
| **AB-2** | CR.33 (RT > RT-LOCATIONS) | **ask** QT-15 (written by `p1s1r4-7`) | Whether the default quest that a window on a plain folder works on is the same thing as CR.6's instance without a quest. Until answered CR.33 states the nested cases as the resolver has them (the nearest root marker wins and an inner root inherits nothing; a workspace folder inside another has its own `.tom` and the root's as layers; a plain folder works on the default quest; in a workspace of several folders the first is the workspace folder; paths are compared by real path; source S12 and `workspace_layout.md` § 7), and CR.6 keeps its text. |
| **AB-3** | CR.33 (RT > RT-LOCATIONS) | **apply** | CR.33 names the third level of guidelines, a project's own `_agent_guidelines/`, read before the workspace folder's and the root's when work touches that project. That a guidelines folder may become a clone of its own is only a "maybe" of al_the_bear (`14_loose_maybe_wslayout-1`) and is not written. Source: the root guidelines `workspace_agents.md` § Guidelines, `workspace_layout.md` § 2; built in the extension (the project guideline tools). |
| **AB-4** | CS.1 (RT > RT-CONFIG) | **apply** | CS.1 says which layer a write goes to: the root's file, until the user picks a layer (planned: vscode_extension `13d_wslayout-1` … `-4`); only the root's and the workspace folder's `.tom` are layers. The user's own file is part of the machine-wide state (CR.36), one for all hosts of a machine and user, its place settled with that state's (A-13). Source: S12; `workspace_layout.md` § 5 (built); vscode_extension `13d_wslayout-1` … `-4` (planned). |
| **AB-5** | CR.34 (RT > RT-LOCATIONS) | **apply** | CR.34 says the record gives each repository a kind and a branch, and that a repository may be absent on a machine by design; the claims and the integration step respect it: the integration step lands on the branch the record names for the repository, and a repository the record marks read-only or a binaries repository is never its target. Source: `repos.yaml` and `workspace_layout_multi.md` § 3 (the record as it exists); a description per entry is planned (al_the_bear `00_aifmt-5`, vscode_extension `00_aifmt-2`). |
| **AB-6** | CR.35 (RT > RT-LOCATIONS) | **apply** | A line under CR.35 says that no source fixes where a quest's list of repositories is recorded (the register `_ai/quests.yaml` has no such field) and that the Blueprint settles the place. Source: S22 § 3.4; vscode_extension `vscimpb154_akqj-short-description-repositories` (needs the record, open). |
| **AB-7** | CR.5 (RT > RT-HOLDS) | **apply** | CR.5 says how instruction files are found: an agent transport is started with the workspace folder as its working directory, and for a model transport the runtime collects the instruction files by the same rules (the root's, then the workspace folder's, imports followed). A line under CW.3 says the Blueprint settles that an execution in a working tree of its own still gets the instruction files of its workspace folder. Source: S12; `workspace_layout.md` § 6. |
| **AB-23** | CR.4 (RT > RT-HOLDS) | **apply** | CR.4 says the runtime's own temporary files for a workspace, and its tools', lie in the workspace root's ignored scratch folder `ztmp/`, never in the system's temporary folder, and carry the quest, the date and the todo in their name, so the registry removes them when the todo is done. Source: the root guideline `workspace_agents.md` § Scratch folders. |
| **AB-24** | CR.2 (RT > RT-HOLDS) | **apply** | CR.2 adds that a todo id never disappears (a rename leaves a cancelled stub of the old id) and that what the runtime writes passes the commit guards of the repository it writes into, in `_ai` and in a repository quest alike. Source: built in the extension (the rename tools, the todo-schema guard in `_ai/.githooks/pre-commit`); S22 § 3.6, § 2.4 (QM-7). |
| **AB-25** | - | **drop** | covered by A-13 (the machine-wide state lies outside `_ai`, its place for the Blueprint) and A-6 (the answers move into the per-host journal) |
| **AB-26** | - | **drop** | nothing to change (confirms); the git settings of a quest's window are the VS Code host's, and CR.34 already answers which repository a file belongs to |
| **WW-9** | CR.6 (RT > RT-HOLDS) | **apply** | CR.6 adds: one host can hold an instance without a quest and instances that serve quests at the same time; a run bound to a quest folder runs in that quest's instance, and any host can start a quest's runtime, not only a workbench (T2 says so for Webforge). Whether standalone Webwork does this is the webwork quest's choice (webwork `qavs_wwworkbench-2`) and is not written. Source: webwork todo `12a_woneb1` (planned), the idea part-bottom-panel; T2; CR.42. |
| **WW-10** | CR.17 (RT > RT-QUEUE) | **apply** | CR.17 stands: the option is kept by the runtime, which needs it to make the run wait (worded as triage § 1.1 says); add as Webwork's need that every run of its own AI starts in review each result (planned), and that which value a new run starts with is for the Solution Blueprint to settle. Source: S1 § 5.3; S3, WR-7; webwork todo `13_woneb2` (planned), the idea part-bottom-panel, Review per run. |
| **WW-11** | CR.29 (RT > RT-TRANSPORTS) | **ask** QT-22 (written by this part) | Whether the mode that offers only the agent transport of the Claude Agent SDK (CR.29, D-16) is still a requirement and for whom, now that Webwork plans the full instance without a quest with runs and queues (webwork `13_woneb1`, `13_woneb4`), or whether CR.29 reduces to "the instance without a quest offers every transport". Until answered CR.29 and D-16 keep their text. |
| **TF-4** | CR.40 (RT > RT-INSTALL); CR.42 (RT > RT-INSTALL) | **ask** QT-22 (written by this part) | Where Node comes from for a host that is not VS Code: brought by the runtime installation or found on the machine, with which lowest version, and what a host is told when Node is missing or too old (Tom Forge plans to report it with the remedy, tom_forge `qavs_wwworkbench-3`). Until answered CR.40 … CR.42 and N-24 keep their text and name no source of Node. |
| **TF-6** | new item in RT-MACHINE (RT > RT-MACHINE); CR.6 (RT > RT-HOLDS) | **ask** QT-16 (written by this part) | Two hosts on one quest: Tom Forge's specification reads the claim rules as refusing a second runtime over one `_ai` folder and allows at most one quest application per quest, while N-10, T2 and the line "One quest may have several runtimes" allow it; what the two share and what the second is refused is open, with the scenario of tom_forge `qavs_none-1` as the acceptance case of N-10. Until answered N-10 and T2 keep their text. |
| **TF-9** | CR.1 (RT > RT-HOLDS) | **ask** QT-23 (written by this part) | Whether programs outside the runtime keep writing `_ai` formats: Dart code writes todo files (`tom_todo_model`), the decisions journal and the live trail (`tom_llm`) today and Tom Forge plans to keep that, asking for the runtime's format fixtures per operation and for the rule a writer follows so that it cannot lose a runtime's write, while CR.1 says the runtime is the one implementation. Until answered CR.1 keeps its text and no item speaks of fixtures for other writers. |
| **WRS** | CR.46 (RT > RT-INSTALL) | **ask** QT-2 (written by this part) | What the web runtime service is for the two quests: Webwork planned "a server-side runtime that also hosts the web version" for AI and messaging in wave 3, so whether the service also serves a web application's files, how long the runtime behind it lives (nothing on the server watches for a user whose phone application is closed) and whether it holds a working copy for a quest (tom_forge `later23`) are open with QT-2. The SDK points belong to QT-3: the web runtime client SDK and the Dart runtime client SDK offering the same convenience layer, `tom_ai_runtime_ui` working over either, and whether host tools, asks and the numbered events cross the service (without them AI on the web cannot edit Webwork documents). Until answered the parts write "web runtime service" and "web runtime client SDK" and keep the statements on how it works as "assumed until PQ-<n>" (triage § 1.2). |

Questions this part writes: QT-2, QT-16, QT-18, QT-22, QT-23 (§ 3).

**Also reaches this part** (ruled in the owning part's row; read that row and the finding):

| Finding | Items of this part | Owner | Ruling there |
| --- | --- | --- | --- |
| AN-8 | CR.2, CR.3, CR.33, CS.1 | `p1s1r4-8` | apply |
| AN-10 | CR.21 | `p1s1r4-4` | apply |
| AN-11 | CR.18 | `p1s1r4-5` | ask QT-19 |
| AN-23 | CR.42 | `p1s1r4-4` | ask QT-3 |
| AN-31 | CS.3, CS.4, CS.5 | `p1s1r4-7` | ask QT-6 |
| AN-41 | CR.35 | `p1s1r4-8` | ask QT-8 |
| IC-4 | CR.36 | `p1s1r4-8` | apply |
| IC-16 | CR.38 | `p1s1r4-6` | ask QT-17 |
| GA-5 | CR.38, CR.39, CR.40, CR.41 | `p1s1r4-6` | ask QT-17 |
| GA-7 | CR.44 (QT-16) | `p1s1r4-6` | apply |
| GA-9 | CR.4 | `p1s1r4-8` | ask QT-13 |
| GA-19 | CR.30, CR.31, CR.45 | `p1s1r4-11` | ask QT-21 |
| GA-20 | CR.46 (QT-2) | `p1s1r4-9` | apply |
| GA-29 | CR.23 | `p1s1r4-4` | apply |
| ST-3 | CR.45 | `p1s1r4-6` | apply |
| ST-5 | RT | `p1s1r4-11` | ask QT-21 |
| ST-7 | CR.14, CR.34, CR.35, CR.44, CR.46 | `p1s1r4-11` | ask QT-21 |
| ST-9 | CR.19, CR.21, CR.36, CR.38 | `p1s1r4-11` | ask QT-19 |
| ST-16 | CR.5 | `p1s1r4-11` | ask QT-21 |
| ID-1 | CR.30, CR.31, CR.45 | `p1s1r4-11` | ask QT-21 |
| ID-6 | CR.23 | `p1s1r4-5` | apply |
| ID-8 | CR.13 | `p1s1r4-7` | ask QT-14 |
| VX-PQ24 | CR.15, CR.17, CR.19, CR.20, CR.23 | `p1s1r4-4` | apply |
| VX-1 | CR.5 (plan mode is per run, VX-25) | `p1s1r4-4` | apply |
| VX-2 | CR.17, CR.19, CR.20, CR.23 | `p1s1r4-4` | apply |
| VX-3 | CR.16 (commands on an executing item, VX-6), CR.23 (the run stays waiting across a restart) | `p1s1r4-4` | apply |
| VX-4 | CR.36 | `p1s1r4-4` | apply |
| VX-5 | CR.20 (the interrupts, VX-31) | `p1s1r4-4` | apply |
| VX-8 | CR.10 (gates shown with the decision's buttons: the move acts on the asking run) | `p1s1r4-4` | apply |
| VX-13 | CR.2 (the journal as a store, VX-44), CR.36 (answers among what is directed at the user) | `p1s1r4-4` | apply |
| VX-14 | CR.36 (notifications for the user: the two classes, one log per machine) | `p1s1r4-4` | apply |
| VX-29 | CR.2 (blockers and release conditions among a todo's fields), CR.21 | `p1s1r4-8` | apply |
| VX-34 | CR.36 (the inbox) | `p1s1r4-8` | apply |
| VX-43 | CR.2, CR.24 | `p1s1r4-8` | ask QT-9 |
| VX-45 | CR.3 (format version 10, triage § 1.6) | `p1s1r4-4` | apply |
| VX-46 | CR.33 | `p1s1r4-8` | apply |
| VX-49 | CR.5 (team review rounds) | `p1s1r4-7` | apply |
| VX-50 | CR.40 (the per-platform binaries of the runtime installation), CR.33 (the projects of a workspace) | `p1s1r4-4` | apply |
| A-1 | CR.2, CR.3, CR.33 | `p1s1r4-2` | apply |
| A-4 | CR.2, CR.24 | `p1s1r4-8` | ask QT-9 |
| Q-1 | CR.33 | `p1s1r4-8` | apply |
| Q-3 | CR.2 | `p1s1r4-8` | ask QT-9 |
| AB-12 | CR.1 | `p1s1r4-2` | apply |
| AB-20 | CR.42 | `p1s1r4-9` | apply |
| WW-2 | CR.5 | `p1s1r4-7` | apply |
| WW-5 | RT-MACHINE (a store per machine and user, if the runtime keeps them) | `p1s1r4-7` | ask QT-24 |
| WW-7 | CR.6, CR.29 | `p1s1r4-7` | ask QT-15 |
| TF-5 | CR.44, CR.23 | `p1s1r4-5` | apply |
| TF-10 | CR.46 (QT-2) | `p1s1r4-8` | ask QT-11 |
| TF-15 | CR.5 | `p1s1r4-4` | apply |

### 2.3 `p1s1r4-4` — `RT-SECRETS` … `RT-PROVIDERS`

28 findings: 22 apply, 6 ask, 0 drop.

| Finding | Items (section chain) | Ruling | What the text is to say, the question, or the reason |
| --- | --- | --- | --- |
| **AN-1** | CP.21 (RT > RT-ASKS) | **apply** | CP.21 states the one rule: while an ask of a run is open, the run that asked waits: nothing further is sent from its queue until the ask is settled; the other runs go on. "The rest of the queue" and the walk clause go. Source: PQ-24 (b); triage § 1.1 |
| **AN-2** | RT-ASKS lead-in (RT > RT-ASKS) | **apply** | The lead-in and N-15 no longer promise that an ask does not hold a process up for long: an ask is never lost, is escalated and is visible; the other runs go on; the user can answer, skip or resend the waiting item. Source: PQ-24 (b); triage § 1.1 |
| **AN-5** | CP.21 (RT > RT-ASKS) | **ask** QT-1 (written by this part) | Whether an execution keeps its leases while its run waits for an ask, releases and claims them again, or has them downgraded. Until answered leases are held "for as long as the item is executed" as today, and CR.15 is not changed. |
| **AN-10** | CP.3 (RT > RT-PROTO); CP.7 (RT > RT-PROTO); CS.17 (RT > RT-PROVIDERS) | **apply** | Starting over is said where a session is taken as one conversation: CP.3 lists "start over" among the session commands; CP.7 says that starting over ends the thread and begins a new one in the same session; CS.17 says that it means a new outside session id under the same session name; CW.11 records the place in the trail besides the session name; CQ.3 says that the history before a start-over stays in the trail; CR.21 and CW.23 stand. Source: PQ-25 (a) |
| **AN-23** | CP.1, CP.11 (RT > RT-PROTO); CP.24, CP.25, CP.26, CP.27 (RT > RT-VERSIONS) | **ask** QT-3 (written by `p1s1r4-5`) | What crosses HTTP to the web runtime service: the event stream, the reverse requests (asks, opening a document, the host's tools), and the version checks for an application that never installs a runtime. Until answered CP.1 and D-10 stand for a host on the same machine and a remote runtime client; for the web runtime service the text says "HTTP-based" and that the event stream and the reverse requests over it are open. |
| **AN-43** | CS.9 (RT > RT-SECRETS) | **apply** | CS.9: "The runtime is approved by the Tom Secrets Manager service once, as a program of its own. A setup guide describes the approval." U-7 "have the tac server approved by Tom Secrets Manager"; D-19 and N-30 likewise. "Pairing" is for devices only. Source: PQ-32 (a) |
| **IC-29** | CP.7 (RT > RT-PROTO) | **ask** QT-19 (written by `p1s1r4-11`) | "Item" names a queue entry (GLO) and a part of a turn (CP.7); "thread" and "turn" are not defined. Until answered CP.7 keeps its text and its mark as a proposal. |
| **GA-8** | CP.16, CP.18, CP.20 (RT > RT-ASKS) | **apply** | CP.20 adds what is built: the ask is settled when it is answered, closed because the execution that asked was ended, or resolved by its declared default, and the user can answer, skip or resend the waiting item, so a held run can be given up. One line under CP.16 / CP.18 says what the Solution Blueprint must settle: where the quest owner is recorded and who may change it, the chain when the quest owner leaves the team or the quest has a personal team, what "working hours" are, and by what a process or todo names a person. Source: triage § 1.1 (settled; VX-5, VX-6, built); round_instructions § What decides, point 5. |
| **GA-12** | CT.12, CT.13 (RT > RT-MCP) | **ask** QT-14 (written by `p1s1r4-7`) | Who issues the bearer token of a published MCP endpoint, how a team runtime obtains it, what the endpoint checks, and the same for the remote-control endpoint with the protocol it speaks. Until answered CT.12, CA.23 and CA.24 keep their text. |
| **GA-29** | CP.2, CP.9 (RT > RT-PROTO) | **apply** | State what is built: an item whose execution was cut off is reported as interrupted and the user resends or skips it; an open ask outlives a restart of the host and is answered by a continuation prompt in the same session. One line under CP.2 says what the Solution Blueprint must settle: what a host shows and can do when the runtime process dies, and what of a half-done execution is kept. Source: VX-16 (item state `interrupted`, built); VX-PQ24 point 9 and VX-3 (the ask outlives a restart); round_instructions § What decides, point 5. |
| **VX-PQ24** | lead-in of RT > RT-ASKS; CP.21 (RT > RT-ASKS); CP.9 (RT > RT-PROTO) | **apply** | The part takes from the section: the item that asked stays in execution and is not moved to another state; nothing else of its run is sent meanwhile (not the next item, not the next todo of a walk, not its follow-ups); the run's settings are untouched and the run goes on by itself when the ask is settled (unlike a held run); the user's ways out without answering are resend and skip, which close the ask unanswered, and stop; the ask and the waiting survive a restart of the host (CP.9). The lead-in no longer promises that an ask does not hold a process up for long: an ask is never lost, is escalated and is visible; the other runs go on; the user can answer, skip or resend the waiting item. The two open points go to QT-1 and VX-1 (applied). Source: PQ-24 (b); triage § 1.1; vscimpb46, vscimpb55, vscimpb81, vscimpb82, vscimpb123, vscimpb166 (done) |
| **VX-1** | new item after CP.21 (RT > RT-ASKS); CP.8 (RT > RT-PROTO) | **apply** | A run has at most one open ask at a time (question, pick, document ask, plan proposal alike); a second ask from the same run while the first is open is refused, not queued; asks of different runs are open at the same time and answered in any order; a tool approval belongs to the execution whose tool call waits. No question is asked about keeping the rule. Source: triage § 1.1; vscimpb81_akmi-one-question-per-run (done); PQ-24 (b) |
| **VX-2** | CP.21 (RT > RT-ASKS) | **apply** | CP.21 reads as triage § 1.1 words it: while an ask of a run is open, the run that asked waits: nothing further is sent from its queue until the ask is settled; the other runs go on. "The rest of the queue" and the walk clause go. Source: PQ-24 (b); triage § 1.1; vscimpb46, vscimpb82 (done) |
| **VX-3** | CP.9 (RT > RT-PROTO) | **apply** | CP.9 keeps "the run resumes when the answer arrives" and adds how: the open ask is stored with its queue item; when the turn that asked has ended (a restart), the item stays in execution, the ask is shown again with the same content, and the answer is delivered as the next prompt in the same session, quoting question and answer; resend, skip or stop meanwhile close the restored ask. Source: vscimpb166_akri-ask-panel-survives-reload (done); triage § 1.1 |
| **VX-4** | CP.18 (RT > RT-ASKS); new item after it | **apply** | An open ask is offered to every runtime client attached to the runtime, and to the other runtimes of the machine through the machine-wide state (CR.36); the first answer settles it, the answer is the same wherever it was given, and the ask closes everywhere it is shown. Telegram as a place to answer is not written (L-9). Source: vscimpb173_akrn-message-into-waiting-turn, vscimpb170_akrm-user-notifications-section (done) |
| **VX-5** | new item after CP.21 (RT > RT-ASKS) | **apply** | An ask is owned by the execution of its item: when that execution is ended (stop, resend, skip, a hard interrupt), every wait it is blocked in ends at once on every transport: the question and the pick close unanswered, an approval counts as denied, a plan as not accepted, and the tool answers that the prompt was ended; an answer given after the close is not delivered, and the ask closes for everyone it was shown or escalated to. This is the second meaning of "settled" in CP.21. Source: vscimpb78_aklr-cancel-ends-blocked-tool-calls, vscimpb33 (done); triage § 1.1 |
| **VX-7** | CP.8 (RT > RT-PROTO) | **apply** | CP.8 adds that an ask has no deadline unless the one who asks declares one together with a safe default: waiting without a limit is the default of the envelope. CP.20 stands. Source: vscimpb120_akon-with-asking-template-and-ask-tool-hints (done); the descriptions of the three ask tools |
| **VX-8** | CP.8 (RT > RT-PROTO) | **apply** | An allowed response of an ask can be an action the runtime carries out itself when it is chosen: a process move, the start of a branch or a subprocess, finishing a review round, the choices of a decision or of a gate. The runtime makes the move, not the agent; it acts on the run of the prompt that asked, not on the run a host shows; every such response is checked when the ask is opened. Source: vscimpb85, vscimpb104, vscimpb89 (done) |
| **VX-13** | new item in RT > RT-TOOLS (after CT.10); CT.1 (row "Runtime tools on `_ai`") | **apply** | A non-blocking tool hands the user an answer (a title, Markdown, the question quoted) with suggested todos (complete records, written on the user's click, filed by the agent) and suggested prompts (only copied, never queued); the answers are kept out of the trail and shown with their read state across quests. Built (vscimpb171). Planned: the answers are kept in the journal of asks and answers per host and quest (VX-44); the place of that store follows QT-9, so the text says "per host" and names no place. Source: vscimpb171_akrm-answer-user-tool (done); 01_aifmt-4_aktn-per-host-trail-qa-history (planned); S22; triage § 1.6 |
| **VX-14** | CP.4 (RT > RT-PROTO) | **apply** | CP.4 names two classes of notification: events on queues and todos (item queued or deleted, todo created, edited, status changed), and events directed at the user (an ask opened or closed with the answer or the reason, a message of the notify tool with its urgency, an answer, suggested processes, a process decision waiting, a todo waiting for decisions, a todo that is the user's to do, a run that is held: decision needed, error, needs attention, blocked). Each event records the quest, the run and who caused it: an agent (transport, profile, session, the item and todo it worked on), the user, or the runtime by itself. The log is kept for the machine. Source: vscimpb124_akon-tom-info-notifications, vscimpb170_akrm-user-notifications-section (done); triage § 1.1 (a held or waiting run says so everywhere) |
| **VX-45** | CP.29 (RT > RT-VERSIONS) | **apply** | CP.29 adds two details that are built: once one runtime of a machine has migrated, the other runtimes of the machine pause every run, refuse new sends and list what still executes, each with an interrupt, until they are restarted; a runtime that finds files in an older or newer format does not start its normal parts and says why, instead of working on them. The migration runs from the installed product, and the merge drivers of the `_ai` files ship with it and are checked on upgrade. When a migration runs is left to QT-12. Source: vscimpb142, vscimpb142a … vscimpb142d (done); 01_aifmt-5_aktn-format-version-10 (planned) |
| **VX-50** | CT.10 (RT > RT-TOOLS) | **apply** | CT.10: a tool that needs a binary (the build tool, the TomSpecs binary) looks for a configured one, then a bundled one, and answers that the binary is missing for this platform, with help, when there is none. The runtime's list of a workspace's projects (used by todo scopes, prompt scopes and the project-list tool) comes from the build tool's listing, with a built-in port of the same rules as the fallback. Where the runtime installation keeps the binaries per platform is for the Blueprint to settle (a line under CR.40). Source: vscimpb83_akmj-bundle-tom-build-binaries, vscimpb84_akmk-project-detector-onto-buildkit-listing, vscimpb147, vscimpb103 (done) |
| **A-14** | CP.29 (RT > RT-VERSIONS) | **ask** QT-12 (written by this part) | When a format migration runs: the standard runs version 10 on each host's first window after the update, without a confirmation, and records it in the versioned `_ai/format-version.yaml`, while CP.29 and CP.32 say once per machine, under a file lock, only after the user confirmed; also how a step that renames one host's files is recorded when the stamp is one shared file. Until answered CP.29, CP.32 and F12 keep their text. |
| **WW-4** | CP.3 (RT > RT-PROTO); CP.4 (RT > RT-PROTO) | **apply** | CP.3 names messaging and documents among the commands (conversations by newest activity with unread counts, history in pages, send with a request id, read state, mute, threads attached to a document or round, the team's members, blob upload and download with the size limit known before sending, extending and releasing a round's blobs, review request and return) and CP.4 the events for an arriving message and a changed read state, because an application has no tac connection of its own and messaging in Webwork runs through its runtime; the list is recorded as what Webwork needs. Source: PQ-30; PQ-26 (a); CI.4, CL.11; webwork todos `13_woneb6` … `13_woneb10` (planned). |
| **WW-14** | CS.11 (RT > RT-SECRETS) | **apply** | CS.11 stands and says it in full: a user's team tokens are kept by the runtime as secret references, one place per machine and user for every host; a host shows the account (user id, e-mail address, server address) and signs out through the runtime, and supplies no credential through the host interface (CP.13). Webwork's plan to keep the token in its settings container is recorded as differing. Source: S1 § 5.8; N-17; webwork todo `13_woneb6` (the need to show the account and sign out). |
| **TF-2** | CT.1 (RT > RT-TOOLS); CP.15 (RT > RT-HOST) | **ask** QT-16 (written by `p1s1r4-3`) | Whether a host may answer a host tool by forwarding it to another host's window (Tom Forge to a running VS Code window over the script server, tom_forge `qavs_wwworkbench-5`, decided there before O-4), or whether such a tool is absent in a host without the concept. Until answered CT.1 and CP.15 keep their text (the host refuses with a reason); for the transports nothing is open: O-4 and CR.26 leave none to forward. |
| **TF-3** | CT.11 (RT > RT-MCP); CT.12 (RT > RT-MCP) | **apply** | CT.11 and N-18 stand: host tools are not reachable through the runtime's MCP server. Add under CT.12 a line of what the Solution Blueprint must settle: how several runtimes on one machine get the ports of their MCP servers, and what the server's card says when two hosts serve one workspace (a need of Tom Forge). Source: S1 § 6.4; N-18; tom_forge todo `qavs_none-3`. |
| **TF-15** | CP.3 (RT > RT-PROTO); CP.4 (RT > RT-PROTO) | **apply** | CP.3 and CP.4 name what a second host needs from the runtime for features the extension has: the completion of commands and skills with their argument prompts and expansion as a command, the progress of subagents as an event, the assist actions on a document's questions (asking through a document, proposed answers, choices that move a process), and continuing an item that stopped for lack of credit on another profile; each only where the VX-* row for the same feature does not already write it, and what is not built is written "planned". Tom Forge's `qavs_ccparity_*` and `qavs_dapieff-*` todos are named at CU.10 as the check of the inventory. Source: built behaviour of the extension (`inputs_vscode_extension.md`), as listed by tom_forge todos `qavs_ccparity_b_panels-3`, `qavs_ccparity_d_claudecode-4`, `qavs_dapieff-1`, `qavs_ccparity_i_assist-1/-2`, `qavs_ccparity_h_pi-1`. |

Questions this part writes: QT-1, QT-12 (§ 3).

**Also reaches this part** (ruled in the owning part's row; read that row and the finding):

| Finding | Items of this part | Owner | Ruling there |
| --- | --- | --- | --- |
| AN-4 | CS.10 | `p1s1r4-3` | apply |
| AN-6 | CP.9, CP.22 | `p1s1r4-3` | apply |
| AN-11 | CP.7, CS.17 | `p1s1r4-5` | ask QT-19 |
| AN-24 | CS.7, CS.8, CS.9, CS.10, CS.11, CP.13 | `p1s1r4-3` | ask QT-2 |
| AN-27 | CP.18 | `p1s1r4-9` | apply |
| AN-30 | CP.17, CP.18, CP.22 | `p1s1r4-6` | ask QT-5 |
| AN-42 | CS.7 | `p1s1r4-6` | ask QT-8 |
| AN-44 | CS.9 | `p1s1r4-11` | apply |
| IC-12 | CP.5 | `p1s1r4-3` | ask QT-16 |
| IC-13 | CP.13 (one user-settings layer per host program) | `p1s1r4-2` | apply |
| IC-17 | CT.11, CT.12, CT.13 | `p1s1r4-7` | ask QT-14 |
| IC-18 | CT.12 | `p1s1r4-7` | ask QT-14 |
| GA-2 | CS.7 … CS.11 | `p1s1r4-3` | ask QT-2 |
| GA-6 | CP.5 | `p1s1r4-3` | ask QT-16 |
| GA-13 | CP.8 | `p1s1r4-5` | ask QT-14 |
| GA-18 | CP.6, CS.14 | `p1s1r4-9` | apply |
| GA-19 | CS.12, CS.16, CS.18, CT.10 | `p1s1r4-11` | ask QT-21 |
| GA-27 | CP.13 | `p1s1r4-7` | apply |
| GA-30 | CP.1, CP.2 | `p1s1r4-2` | ask QT-18 |
| ST-3 | CP.7, CP.8 | `p1s1r4-6` | apply |
| ST-5 | RT | `p1s1r4-11` | ask QT-21 |
| ST-7 | CP.16, CS.13 | `p1s1r4-11` | ask QT-21 |
| ST-9 | CP.1, CP.2, CP.3, CP.10, CP.13, CT.1 | `p1s1r4-11` | ask QT-19 |
| ID-1 | CS.16, CS.18 | `p1s1r4-11` | ask QT-21 |
| ID-3 | CT.12, CS.9 | `p1s1r4-7` | ask QT-14 |
| ID-4 | CS.7, CS.8 | `p1s1r4-6` | ask QT-8 |
| ID-8 | CP.20 | `p1s1r4-7` | ask QT-14 |
| VX-6 | CP.3 (the queue commands), RT-ASKS lead-in (the user can answer, skip or resend the waiting item) | `p1s1r4-3` | apply |
| VX-9 | CT.1 (the wait tool among the runtime tools on `_ai`) | `p1s1r4-3` | apply |
| VX-15 | CP.4 (run-state events) | `p1s1r4-3` | apply |
| VX-17 | CP.21 (QT-1 is asked there) | `p1s1r4-3` | ask QT-1 |
| VX-25 | CP.8 (kind plan) | `p1s1r4-3` | apply |
| VX-27 | CP.21 (the walk clause goes) | `p1s1r4-3` | apply |
| VX-32 | CS.14 (the fallback profile in the configuration) | `p1s1r4-3` | apply |
| VX-36 | CT.9 (the role decides the tools) | `p1s1r4-3` | apply |
| VX-37 | CT.1 (the tools take role and guideline choices, planned) | `p1s1r4-3` | ask QT-18 |
| VX-41 | CS.13 | `p1s1r4-3` | apply |
| VX-42 | CT.1 (the memory tools) | `p1s1r4-3` | apply |
| VX-44 | CP.23, CT.1 (VX-13) | `p1s1r4-3` | apply |
| VX-51 | CS.7 … CS.11 | `p1s1r4-5` | ask QT-18 |
| VX-52 | CS.14 (usage and cost shown per provider) | `p1s1r4-3` | apply |
| A-5 | CP.3 | `p1s1r4-3` | apply |
| A-6 | CP.22 (RT > RT-ASKS lead-in) | `p1s1r4-3` | apply |
| A-11 | CS.13 | `p1s1r4-2` | apply |
| Q-9 | CP.4 | `p1s1r4-3` | apply |
| AB-15 | CS.7 | `p1s1r4-6` | apply |
| WW-5 | CP.3 (search over cached conversations) | `p1s1r4-7` | ask QT-24 |
| WW-8 | CT.13, CP.13 (the host interface would declare it) | `p1s1r4-6` | ask QT-14 |
| WW-13 | CP.23 (the channels of the escalation chain) | `p1s1r4-7` | ask QT-4 |
| TF-5 | CP.3 | `p1s1r4-5` | apply |

### 2.4 `p1s1r4-5` — `CLI`

22 findings: 10 apply, 11 ask, 1 drop.

| Finding | Items (section chain) | Ruling | What the text is to say, the question, or the reason |
| --- | --- | --- | --- |
| **AN-11** | CU.6 (CLI > CLI-UI); CU.15 (CLI > CLI-SCREENS) | **ask** QT-19 (written by `p1s1r4-11`) | "Conversation" names the exchange with a model and the messaging between users, both in one table of CU.6; the proposal is "chat" for the model side. Until answered the items keep their words. |
| **AN-12** | CL.11 (CLI > CLI-PACK) | **apply** | CL.11: "The tac client SDK is used by runtimes and command-line programs of ours." No server uses it. Source: PQ-26 (a); triage § 1.7 |
| **AN-13** | CL.11 (CLI > CLI-PACK) | **drop** | covered by triage § 1.7 ("runtimes and command-line programs of ours", applied with AN-12) |
| **AN-15** | CL.2 (CLI > CLI-PACK); CL.6 (CLI > CLI-PACK) | **apply** | The places that say who uses the tac client SDK say "runtimes and command-line programs of ours": GLO client SDK adds them; CA.25 stands; CA.28 ("tac clients in a browser") and N-26 ("without dart:io") are kept as capabilities and marked as not used by any application of the first version; WR-6 follows; G-1 names which tac client SDK the runtime contains (the TypeScript one of G-5) or carries a line that the Blueprint must settle it; CL.6 says that the conformance suite drives each tac client SDK by a test program without a runtime. Source: PQ-26 (a); PQ-30; triage § 1.4, § 1.7 |
| **AN-22** | CL.1, CL.2, CL.3, CL.9 (CLI > CLI-PACK) | **ask** QT-3 (written by this part) | Whether the web runtime client SDK is a third SDK or the runtime client SDK with a second binding, and for which languages. Until answered "one runtime client SDK and one tac client SDK per language, for nine languages" stands, and the web runtime client SDK is added beside them "in Dart and in JavaScript / TypeScript"; no part writes that it replaces or extends another SDK. |
| **AN-26** | CK.10, CK.11 (CLI > CLI-TRC) | **ask** QT-4 (written by `p1s1r4-7`) | Whether applications on phones and tablets stay part of the first version (D-51) when no solution is given for them. Until answered D-51 is not changed and is named as one of the open points. |
| **IC-28** | CU.6 (CLI > CLI-UI); CU.9 (CLI > CLI-UI) | **ask** QT-7 (written by this part) | Where the review component is built: here as the Review group of tom_ai_runtime_ui, or in the quest tom_forge (R-19), which CU.3 excludes as a dependency. Until answered CU.6's Review group, CU.9, SC-18, G-6 and R-19 keep their text. |
| **GA-13** | CK.2 (CLI > CLI-TRC) | **ask** QT-14 (written by `p1s1r4-7`) | What remote control covers and what it excludes (host tools, file tools, settings, approving a tool call on another person's machine), the default of the host's setting, whether the local user sees it and who wins when both act. Until answered CK.2 keeps "more or less everything a runtime can do". |
| **ST-2** | the paragraph before SC-1 (CLI > CLI-SCREENS) | **apply** | The remark before the screen inventory becomes a plain statement of standing without the mark: the outcomes are a first pass from the names of the extension's views and handlers and the Solution Blueprint confirms them from the code. CQ.5's mark goes with its new source S22 § 3.1; CI.19 keeps its mark only as the open point that QT-4 asks. Source: triage § 1.6 (CQ.5); round_instructions § Rules for the text (Signing: sparingly, with the reason). |
| **ST-14** | SC-21, SC-24, SC-27, SC-28, SC-29 (CLI > CLI-SCREENS) | **apply** | The column "Component group" holds only groups of CU.6: "partly host's own" of SC-24 moves to the outcome column, and SC-21's "diagnostics" is named as a group of CU.6 or as the host's own; SC-27 … SC-29 say "none in the extension" instead of a dash. SC-18 is not touched (QT-7). Source: CU.6 (the list of component groups); a correction with only one reasonable reading. |
| **ID-6** | CK.1, CK.9 (CLI > CLI-TRC); CU.6, CU.15 (CLI > CLI-UI) | **apply** | A run that waits or is held says so everywhere: the run tab, trc's overview and the state a runtime reports with its registration show which run waits for which ask (or lease, secret, time, blocked todo) since when. Setting an ask's deadline and default per process step is not written (no source). Source: triage § 1.1 (ID-6 is applied); PQ-24 (b); VX-14, VX-15 (built). |
| **ID-9** | CL.1 (CLI > CLI-PACK) | **ask** QT-3 (written by this part) | TypeScript and JavaScript as one client SDK (one package, eight languages). Until answered CL.1, CL.7 and G-5 keep nine languages. |
| **VX-48** | CU.9 (CLI > CLI-UI); SC-18 (CLI > CLI-SCREENS) | **ask** QT-7 (written by this part) | Whether the review component is one Flutter component (CU.9), the extension's shared web page behind a host with its versioned page protocol (built: 01b_woneb1, 01b_woneb2), or one per platform; and where it is built. Until answered CU.6's Review group, CU.9 and SC-18 keep their text; the page protocol is named as an input for the component's interface. |
| **VX-51** | SC-25 (CLI > CLI-SCREENS) | **ask** QT-18 (written by `p1s1r4-3`) | Whether the file that says what a project needs (`prerequisites.yaml`: the secrets it needs and other prerequisites, never a value) is a format of the runtime, so every host and an agent read and check it the same way, or stays the VS Code host's own as SC-25 says. Until answered SC-25 keeps "host's own" and RT-SECRETS says nothing about it. |
| **AB-18** | CK.12 (CLI > CLI-TRC) | **apply** | CK.12 names who checks it: the quest `al_the_bear`, which runs the VPN; no todo for it exists there yet. R-20, or a dependency row beside it, lists the check. Source: the finding's search of al_the_bear's todos and documents (2026-11-20). |
| **WW-1** | CU.6 (CLI > CLI-UI); CU.9 (CLI > CLI-UI); SC-18 (CLI > CLI-SCREENS); CK.2 (CLI > CLI-TRC) | **ask** QT-7 (written by this part) | Where the review component is built: the webwork and tom_forge quests plan it outside this product, in two forms (the extension's MD Browser page hosted in a webview, webwork `09_woneb5`; a Dart component in the tom_forge repository, tom_forge `05b_woneb1` … `05b_woneb5`), and whether trc then depends on that component or opens review documents in another application. Until answered CU.6's Review group, CU.9, SC-18, G-6 and R-19 keep their text (triage § 1.4). |
| **WW-12** | CU.6 Messaging row (CLI > CLI-UI); new item in CLI-UI (CLI > CLI-UI) | **apply** | A new item records what Webwork needs of the messaging components: the attachment kinds, the card kinds and the card actions come from the host (Attach of a file, an item, a section, a document; a received copy's card with Open, Save into, Merge, Remind me, Make todo), and the conversation list, the conversation and the composer are separate components that a host lays out narrow, full or as two screens (CU.15); how the components take them is for the Solution Blueprint. Whether Webwork builds its Messaging area from `tom_ai_runtime_ui` is not written (unverified: its D40 is not written). Source: webwork todos `13_woneb7` … `13_woneb9` (planned); CM.3; CV.9. |
| **WW-19** | CU.5 (CLI > CLI-UI); CU.1 (CLI > CLI-UI) | **ask** QT-7 (written by this part) | What becomes of the Flutter packages with agent and todo views that already exist over other backends (`tom_agentic_ui` over `tom_core_agentic`, `tom_ai_trail_ui` over `tom_llm`, and `tom_todo_ui` over `tom_todo_model`, see TF-8): input for the components, replaced by `tom_ai_runtime_ui`, a base it builds on, or kept for applications without a runtime. Until answered CU.5 keeps its text, and part 2 states the fact: E-10 says that no Flutter component over the runtime exists, and `LAND > LAND-BUILT` names the packages as built over other backends (tom_forge todo `02b_woneb8`, completed; checked in `tom_ai/modules`). |
| **WW-21** | CU.7 (CLI > CLI-UI) | **apply** | CU.7 adds: the bounded Markdown view works without a connection to a runtime, on text its host gives it, and the host sets its bound per use. Source: S3, WR-7 (it serves an application's own log channels); webwork todos `06_woneb8`, `13_woneb4` (planned). |
| **TF-5** | CL.5 (CLI > CLI-PACK) | **apply** | CL.5 records what Tom Forge needs of the runtime client SDK's convenience layer: for a runtime it started, to report its exit with the last log lines, to restart it and to resubscribe from the numbered events (CP.5); and CP.3 gets a command that answers what is running or scheduled in an instance (a running item, a waiting timed request), for a host's question before it quits. Source: tom_forge todo `qavs_wwworkbench-3` (planned); `spec_quest_workbench.tom_forge.md` § 3; CP.2, CP.5, CR.23, CR.44. |
| **TF-8** | CU.6 Todos row (CLI > CLI-UI); CU.3 (CLI > CLI-UI) | **ask** QT-7 (written by this part) | Where components are built that another package already holds: for the review component this is QT-7 (triage § 1.4 lists this finding there); the same choice for the Todos group, built on the existing `tom_todo_ui` (then `tom_ai_runtime_ui` depends on packages of `tom_ai/modules`) or beside it, is asked with WW-19's question. CU.3 stands (CQ-14): Tom Forge's `qavs_ccparity_*` todos embed the components instead of building views, which the message of TF-1 says. Until answered CU.6 keeps its text. |
| **TF-11** | CK.7 (CLI > CLI-TRC); CK.10 (CLI > CLI-TRC) | **apply** | CK.7 and CK.10 add: Tom Forge's shell builds for the desktop and for tablets and not for phones (planned), so the phone layout of trc is built from the phone-width screens of `tom_ai_runtime_ui` (CU.15) without Forge's shell, and the tablet and desktop builds may use it. Whether phones are in the first version stays with QT-4. Source: tom_forge todo `wwkit3` (planned); `decisions.tom_forge.md`, `forgeinv9`; webwork idea part-forge-investigation. |

Questions this part writes: QT-3, QT-7 (§ 3).

**Also reaches this part** (ruled in the owning part's row; read that row and the finding):

| Finding | Items of this part | Owner | Ruling there |
| --- | --- | --- | --- |
| AN-6 | CK.1, CK.9, CU.6, CU.15 | `p1s1r4-3` | apply |
| AN-17 | SC-28, CU.6 | `p1s1r4-6` | apply |
| AN-20 | CL.11, CK.10 | `p1s1r4-3` | ask QT-2 |
| AN-21 | CK.11 | `p1s1r4-6` | ask QT-4 |
| AN-23 | CL.6, CL.8 | `p1s1r4-4` | ask QT-3 |
| AN-27 | CU.1, CU.4, CK.6, CK.12 | `p1s1r4-9` | apply |
| AN-30 | CK.8 | `p1s1r4-6` | ask QT-5 |
| AN-34 | CU.6, CU.9, SC-18 (QT-7) | `p1s1r4-2` | apply |
| AN-37 | SC-27, CU.6 | `p1s1r4-2` | apply |
| AN-41 | SC-28, CU.6 | `p1s1r4-8` | ask QT-8 |
| IC-9 | CL.5 | `p1s1r4-3` | apply |
| IC-11 | CK.10 | `p1s1r4-7` | ask QT-15 |
| IC-17 | CK.5 | `p1s1r4-7` | ask QT-14 |
| IC-34 | CL.2, CK.4 | `p1s1r4-9` | apply |
| GA-12 | CK.2, CK.5 | `p1s1r4-4` | ask QT-14 |
| GA-16 | CK.12 | `p1s1r4-7` | ask QT-4 |
| GA-17 | CK.11 | `p1s1r4-7` | ask QT-4 |
| GA-18 | CU.7 | `p1s1r4-9` | apply |
| GA-19 | CU.15 | `p1s1r4-11` | ask QT-21 |
| GA-25 | SC-1 … SC-29 (CLI > CLI-SCREENS) | `p1s1r4-2` | apply |
| ST-7 | CK.5 | `p1s1r4-11` | ask QT-21 |
| ST-8 | CL.1 | `p1s1r4-10` | apply |
| ID-8 | CK.5 | `p1s1r4-7` | ask QT-14 |
| VX-PQ24 | CU.6, CU.15, CK.1, CK.9 | `p1s1r4-4` | apply |
| VX-4 | CU.6 (Asks group, the ask inbox), SC-3 | `p1s1r4-4` | apply |
| VX-6 | CU.6 (Queue group) | `p1s1r4-3` | apply |
| VX-13 | CU.6 (Asks group: an answers component), SC-3 | `p1s1r4-4` | apply |
| VX-14 | CU.6 (Supervision: notifications, what waits), SC-3, SC-20 | `p1s1r4-4` | apply |
| VX-15 | CU.6 (run tabs with state marks, what waits), CU.15, CK.1, CK.9 | `p1s1r4-3` | apply |
| VX-16 | CU.6 (Queue group: "waiting, running, done" follows these states) | `p1s1r4-3` | apply |
| VX-20 | CU.6 (Sessions and memory) | `p1s1r4-3` | apply |
| VX-26 | CU.6 (Queue group, item editor) | `p1s1r4-3` | apply |
| VX-40 | CU.6 (Todos: decisions; Supervision: what waits) | `p1s1r4-3` | apply |
| VX-44 | CU.6 (a component for the journal, with questions and decisions across quests), SC-3 | `p1s1r4-3` | apply |
| VX-45 | SC-26 | `p1s1r4-4` | apply |
| VX-47 | CK.1 (a list of quests shows the short description) | `p1s1r4-3` | apply |
| VX-49 | CU.6 (Review group), CU.9 | `p1s1r4-7` | apply |
| VX-53 | CU.6 (Queue group: timed requests) | `p1s1r4-3` | apply |
| A-6 | SC-14, CK.9 | `p1s1r4-3` | apply |
| A-9 | SC-16, SC-22 | `p1s1r4-3` | apply |
| Q-7 | SC-* (CLI > CLI-SCREENS, with Q-11) | `p1s1r4-8` | apply |
| Q-11 | SC-* (CLI > CLI-SCREENS) | `p1s1r4-8` | ask QT-11 |
| WW-4 | CL.5 (the runtime client SDK's convenience layer gets messaging and documents) | `p1s1r4-4` | apply |
| WW-7 | CK.1 | `p1s1r4-7` | ask QT-15 |
| WW-13 | CK.11 | `p1s1r4-7` | ask QT-4 |
| TF-2 | CL.10 | `p1s1r4-4` | ask QT-16 |
| TF-4 | CL.5 (find or start reports it) | `p1s1r4-3` | ask QT-22 |
| TF-9 | CL.6 | `p1s1r4-3` | ask QT-23 |
| TF-10 | CU.6, CU.11 | `p1s1r4-8` | ask QT-11 |
| TF-12 | CU.4 | `p1s1r4-9` | apply |
| TF-13 | CL.3, CU.1 | `p1s1r4-9` | apply |
| TF-15 | CU.6 (Conversation, Asks, Settings rows), CU.10 | `p1s1r4-4` | apply |
| WRS | CL.1, CL.4, CL.11, CU.1, CU.4, CK.10 (QT-3) | `p1s1r4-3` | ask QT-2 |

### 2.5 `p1s1r4-6` — `TAC-JOBS`, `TAC-COORD`, `TAC-BACKENDS`

27 findings: 13 apply, 14 ask, 0 drop.

| Finding | Items (section chain) | Ruling | What the text is to say, the question, or the reason |
| --- | --- | --- | --- |
| **AN-16** | CA.20 (TAC > TAC-COORD); CA.26 (TAC > TAC-BACKENDS); CA.29 (TAC > TAC-BACKENDS) | **apply** | CA.20 announces "an execution started or ended"; CA.26's GitHub row reads "leases and endpoints as refs"; CA.29 drops "closing a session". tac keeps no record for the holder. Source: PQ-27 (a) |
| **AN-17** | CA.8 (TAC > TAC-COORD); CA.5 (TAC > TAC-COORD) | **apply** | CA.8 loses its last sentence about the word "session" and carries the full list of what a lease names (IC-15); a restarted runtime recognises its leases by the names on them. CA.5 lists executions, not sessions. X-11 reads "for leases and endpoints"; CA.36 says that tac/2.0 has no session record; SC-28 and CU.6 (the coordination page) list executions; GLO holder adds quest, machine, workspace; E-3 keeps its parenthesis. Source: PQ-27 (a) |
| **AN-21** | CA.30 (TAC > TAC-BACKENDS); CA.23 (TAC > TAC-COORD) | **ask** QT-4 (written by `p1s1r4-7`) | Whether tac's relay also carries the runtime's protocol, and whether a phone reaches runtimes directly (CA.23, CK.11). Until answered "relay" names the tac server's relay only (CA.30); the answer's "additional relay" is the web runtime service and the word is not used for it. |
| **AN-29** | CA.26 (TAC > TAC-BACKENDS) | **apply** | CA.26's GitHub row reads "one user's machines, or a simple team of several members"; the paragraph under the table says that a team on the GitHub backend shares leases and endpoints through the coordination repository and that what else such a team has is open. X-11 and D-47 follow. Source: PQ-29; triage § 1.3 |
| **AN-30** | CA.26 (TAC > TAC-BACKENDS) | **ask** QT-5 (written by this part) | What a team of several members has on the GitHub backend, per capability (commands between runtimes, asks to other people, messaging, the review exchange, reminders, todo offers, remote control), since CA.26 says "no messages across machines". Until answered no part extends messaging, asks to other people or the review exchange to the GitHub backend. |
| **AN-35** | CA.28 (TAC > TAC-BACKENDS) | **apply** | CA.28 keeps "tac clients in a browser" as a capability for services that use tac directly later, marked as not used by any application of the first version; N-26 and WR-6 follow. Source: PQ-30; triage § 1.4 |
| **AN-39** | CA.17 (TAC > TAC-COORD); CA.9 (TAC > TAC-COORD) | **apply** | CA.17: a runtime claims a part of the _ai state's repository for a todo only when the todo names it among its resources (for example git:al-the-bear/tom_agent_state#quests/ai_runtime/specification/**); todo state and journals are never named. CA.9: one notation for now, the prefix git:, for a whole repository and a part of one; further prefixes can be added; "a folder of the _ai state" is not a kind. Source: PQ-31 (a); triage § 1.5 |
| **AN-40** | CA.10, CA.11, CA.16 (TAC > TAC-COORD) | **apply** | Every statement of the name's form and every example carries the prefix: git:<owner>/<repository>, git:<owner>/<repository>#<pattern>, in full git:<server>/<owner>/<repository> when a team has more than one repository server; examples git:al-the-bear/tom_ai_build and git:al-the-bear/tom_ai_build#tom_ai_runtime/**. Overlap is defined among git: names; resources of different prefixes never overlap. X-15 says "one prefix for now". The details of the grammar are left to QT-8. Source: PQ-31; triage § 1.5 |
| **AN-42** | CA.10 (TAC > TAC-COORD) | **ask** QT-8 (written by this part) | Whether the prefixed notations (secrets tsm: / os: / env: / file:, messages msg:, resources git:) and the addresses of CW.18 are written as one family. Until answered each keeps its own form. |
| **IC-1** | CA.11 (TAC > TAC-COORD) | **ask** QT-13 (written by this part) | Whether an integration lease exists as a third kind that coexists with shared leases, since by CA.11 the exclusive lease of the integration step can never be given while shared leases are held (F8 cannot happen). Until answered CA.11, CW.5 and F8 keep their text, with a remark that the lease rules are open. |
| **IC-7** | CA.14 (TAC > TAC-COORD) | **ask** QT-13 (written by this part) | Who checks the fencing token and how a write is refused, since a push goes to a repository server that knows no token. Until answered CA.14 and CW.5 keep their text; no part writes a mechanism per backend. |
| **IC-8** | CA.4 (TAC > TAC-COORD); CA.15 (TAC > TAC-COORD) | **ask** QT-5 (written by this part) | Who computes presence and staleness, and whose clock decides, on the GitHub backend, where no service stands between the machines. Until answered CA.4 and CA.15 keep their text and say that they are stated for the local backend and the tac server. |
| **IC-10** | CA.3 (TAC > TAC-COORD); CA.5 (TAC > TAC-COORD) | **apply** | CA.3: a runtime registers "the quest it serves (none for a runtime without a quest)". CA.5: the process position "per run". Source: CR.6, CA.39, GLO runtime |
| **IC-15** | CA.8 (TAC > TAC-COORD) | **apply** | One list of what a lease names, the same in CA.8 and in GLO holder: the runtime, the quest, the run, the item, the machine, the workspace. A line under CA.8 says that the Blueprint must settle what identifies the same runtime after a restart (GA-7). Source: PQ-27 (a) |
| **IC-16** | CA.31 (TAC > TAC-BACKENDS) | **ask** QT-17 (written by this part) | Whether "off, the default" switches coordination off as a whole or only the claims, given that the local tac service runs once per machine and every runtime registers with it (CR.38, CA.34, T1, D-13). Until answered CA.31, CR.38 and T1 keep their text. |
| **GA-3** | CA.13, CA.14, CA.20 (TAC > TAC-COORD) | **apply** | No source gives the numbers or the failure behaviour, so one line under CA.14 says what the Solution Blueprint must settle: the renewal interval, how long a claim waits and whether it times out, the order in which waiting claims are served and whether an exclusive claim can starve, what a runtime does when its lease was freed under it, and what becomes of the leases of a runtime that ends in the middle of an execution. The lease kinds themselves are QT-13. Source: round_instructions § What decides, point 5 (a gap without a source becomes a line saying what the Blueprint must settle); CA.13 (the one number the sources give). |
| **GA-5** | CA.26, CA.28 (TAC > TAC-BACKENDS) | **ask** QT-17 (written by this part) | What the local tac service is: who installs and updates it, what happens to machine-wide state when it crashes, its version check against runtimes of different versions, and how the file implementation and the service hand state over when coordination is switched on or off. Until answered CR.38, CR.39, CA.26 and CA.28 keep their text. |
| **GA-7** | CA.3, CA.8 (TAC > TAC-COORD) | **apply** | No source says how a runtime's id is made, so one line under CA.3 says what the Solution Blueprint must settle: who generates the id and from what, and what a restarted runtime presents to find its leases (CA.8); whether two windows on one quest are two runtimes with two ids is part of QT-16 and is not written. Source: round_instructions § What decides, point 5; CA.8 (the holder's identity outlives the runtime process). |
| **ST-3** | CA.8, CA.9, CA.16 (TAC > TAC-COORD); CA.27 (TAC > TAC-BACKENDS) | **apply** | Each item states only what the product does: the sentences on what `tac/1.0` has and the product does not use (the session record, the unused resource kinds, units and infrastructure resources, "customer", "agent group") move to one short list in LAND > LAND-BUILT; lead-ins and items lose "is decided", "earlier decision", "the first question round added"; the two "Differently from the requirement" notes are carried by X-3; the dated `tomspecs` version stays only in LAND > LAND-BUILT. CP.7, CP.8 and CR.45 keep their standing as proposals, said in one clause. Source: round_instructions § Rules for the text (Current state only; history belongs to DEC and CON); triage § 1.7 (version numbers); PQ-27 (a), PQ-31 (CA.8, CA.9). |
| **ID-2** | CA.11, CA.42 (TAC > TAC-COORD) | **ask** QT-13 (written by this part) | The lease rules as one matrix (lease asked for against lease held) with one line per mode. Until answered CA.11, CA.42, CW.5 and F8 keep their text. |
| **ID-4** | CA.10 (TAC > TAC-COORD) | **ask** QT-8 (written by this part) | One written form `<scheme>:<body>` for everything that is addressed: resources, secrets, messages and the addresses of CW.18. Until answered only `git:` resource names are written as triage § 1.5 says, and CW.18 keeps its text. |
| **ID-5** | CA.26 (TAC > TAC-BACKENDS) | **ask** QT-5 (written by this part) | A capability table per backend (local, GitHub for a personal team, GitHub for a team of several, tac server). Until answered the text says that a team on the GitHub backend shares leases and endpoints through the coordination repository and that what else it has is open. |
| **A-7** | CA.17 (TAC > TAC-COORD) | **apply** | CA.17's list of what is never claimed names todo files, the process state, the progress file and the per-host files (sessions, trail, the journal of asks and answers, each written by one host); "the files of questions, decisions" goes, since the decisions are a view rendered from the archived todos and the journal is per host. Source: S22 § 2.2 (CQ-1, CQ-2, CQ-15), § 3.2; PQ-31 (a) for the rest of the item. |
| **Q-14** | CA.10 (TAC > TAC-COORD) | **ask** QT-8 (written by this part) | How a document of a quest in a multi-quest repository is named as a resource: all its quests share one repository and differ only by branch, and the name `git:<owner>/<repository>#<pattern>` has no branch. Until answered CA.17's example stays a classic quest in the `_ai` state's repository, and the text says a repository quest's files are named by the quest's own repository. |
| **AB-15** | CA.26 (TAC > TAC-BACKENDS) | **apply** | CA.26 says the GitHub backend's credential is named by a secret reference like every other (CS.7; the fleet's environment file is the `env:` form) and has rights on the coordination repository only, never on the whole account. The repository's name and the group name are the fleet's. Source: al_the_bear `14_loose_wslayout-4_akto-coordination-repo-and-tokens` (planned); CS.7. |
| **WW-6** | CA.31 (TAC > TAC-BACKENDS); CA.32 (TAC > TAC-BACKENDS) | **ask** QT-17 (written by this part) | Whether messaging can be on while coordination is off (`mode: off`), and whether CA.32's stop of the queues holds for a runtime that takes no claims (Webwork's own AI, a runtime without a quest; what such a runtime may do is QT-15). Until answered CA.31, CA.32 and N-12 keep their text; Webwork's need is recorded in `TAC > TAC-WEBWORK`: with the tac server unreachable its messaging shows the cached history read-only and keeps outgoing messages for later (webwork idea part-messaging, Edge cases). |
| **WW-8** | CA.23 (TAC > TAC-COORD) | **ask** QT-14 (written by `p1s1r4-7`) | Whether a runtime can publish, with the same record, an endpoint that its host serves (Webwork plans an MCP endpoint of its own for remote control of Webwork and does not publish the runtime's MCP server), or whether only endpoints the runtime serves are published. Until answered CA.23 keeps "the endpoints it serves" and CT.13 stands. |

Questions this part writes: QT-5, QT-8, QT-13, QT-17 (§ 3).

**Also reaches this part** (ruled in the owning part's row; read that row and the finding):

| Finding | Items of this part | Owner | Ruling there |
| --- | --- | --- | --- |
| AN-5 | CA.13 | `p1s1r4-4` | ask QT-1 |
| AN-6 | CA.5 | `p1s1r4-3` | apply |
| AN-8 | CA.17 (the example name) | `p1s1r4-8` | apply |
| AN-15 | CA.25, CA.28 | `p1s1r4-5` | apply |
| AN-18 | CA.17 | `p1s1r4-8` | ask QT-19 |
| AN-32 | CA.2, CA.4, CA.10, CA.13, CA.15, CA.32, CA.33, CA.34 | `p1s1r4-7` | apply |
| AN-41 | CA.3 | `p1s1r4-8` | ask QT-8 |
| IC-2 | CA.26 (what the integration queue is per backend, QT-13) | `p1s1r4-8` | apply |
| IC-4 | CA.19 | `p1s1r4-8` | apply |
| IC-12 | CA.6, CA.19 | `p1s1r4-3` | ask QT-16 |
| IC-18 | CA.27, CA.28, CA.30 | `p1s1r4-7` | ask QT-14 |
| IC-19 | CA.30 | `p1s1r4-7` | ask QT-4 |
| IC-22 | CA.27 | `p1s1r4-2` | apply |
| GA-6 | CA.6, CA.19 | `p1s1r4-3` | ask QT-16 |
| GA-9 | CA.26, CA.36 | `p1s1r4-8` | ask QT-13 |
| GA-12 | CA.23, CA.24 | `p1s1r4-4` | ask QT-14 |
| GA-14 | CA.19 | `p1s1r4-7` | apply |
| GA-18 | CA.27 | `p1s1r4-9` | apply |
| GA-19 | CA.33 | `p1s1r4-11` | ask QT-21 |
| ST-7 | CA.9, CA.10 | `p1s1r4-11` | ask QT-21 |
| ST-8 | CA.26 | `p1s1r4-10` | apply |
| ST-9 | CA.8, CA.19 | `p1s1r4-11` | ask QT-19 |
| ST-15 | CA.26 | `p1s1r4-11` | ask QT-21 |
| ST-16 | CA.30 | `p1s1r4-11` | ask QT-21 |
| ID-3 | CA.23, CA.24, CA.30 | `p1s1r4-7` | ask QT-14 |
| ID-6 | CA.5 | `p1s1r4-5` | apply |
| ID-8 | CA.14 | `p1s1r4-7` | ask QT-14 |
| VX-PQ24 | CA.5 | `p1s1r4-4` | apply |
| VX-14 | CA.20 | `p1s1r4-4` | apply |
| VX-15 | CA.5 | `p1s1r4-3` | apply |
| A-3 | CA.17 | `p1s1r4-3` | apply |
| A-6 | CA.17 | `p1s1r4-3` | apply |
| Q-12 | CA.26 | `p1s1r4-8` | apply |
| AB-14 | CA.9 | `p1s1r4-8` | ask QT-13 |
| AB-16 | CA.28 | `p1s1r4-10` | apply |
| AB-17 | CA.32 | `p1s1r4-10` | apply |
| WW-7 | CA.5 | `p1s1r4-7` | ask QT-15 |
| TF-3 | WW-8 (an endpoint of the host's own) | `p1s1r4-4` | apply |
| TF-6 | CA.5 ("One quest may have several runtimes") | `p1s1r4-3` | ask QT-16 |

### 2.6 `p1s1r4-7` — `TAC-PEOPLE` … `TAC-WEBWORK`

29 findings: 14 apply, 13 ask, 2 drop.

| Finding | Items (section chain) | Ruling | What the text is to say, the question, or the reason |
| --- | --- | --- | --- |
| **AN-19** | CI.18 (TAC > TAC-CRYPT); CI.19 (TAC > TAC-CRYPT) | **ask** QT-4 (written by this part) | Which program a paired device reaches from the internet and which holds the device keys: the answer to PQ-28 picks none of its options. Until answered the text says "the server a device reaches from the internet (which program that is, is open)" and puts no name there; ABOUT's status and R-22 carry it as open. |
| **AN-31** | CI.5, CI.6, CI.7, CI.8, CI.9, CI.10, CI.11, CI.14, CI.15, CI.20 (TAC > TAC-PEOPLE) | **ask** QT-6 (written by this part) | Who is a member and an owner of a team on the GitHub backend, and whether invitation, team token and the owner-only rules exist there or are agreements. Until answered the items keep their text, stated for the tac server. |
| **AN-32** | CA.39 (TAC > TAC-PEOPLE > TAC-GROUPS); the closing sentence of TAC-WEBWORK (TAC > TAC-WEBWORK) | **apply** | CA.39 no longer says that every user without a tac server has a personal team with only themselves: the personal team is the local backend's and the single-member case of the GitHub backend, which also serves simple teams of several members. T3 stands; T4 gets the variant "a team on the GitHub backend"; the other places follow in these words. Presence and the clock without a service, the integration queue in refs and "GitHub or any git server" are left to QT-5 and QT-13; the document keeps the name "GitHub backend". Source: PQ-29; triage § 1.3 |
| **AN-36** | CV.5 (TAC > TAC-DOCS); CV.15 (TAC > TAC-REVIEW) | **apply** | CV.5 and CV.15 add that the reviewer's application reaches tac through its runtime. U-2, V-5 and P-3 say that a reviewer without a repository uses an application that carries the review component (the VS Code extension today, Webwork and Webforge later, none built here). "The documents reach webwork indirectly" is not written. Source: PQ-30; triage § 1.4 |
| **AN-38** | CV.12 (TAC > TAC-REVIEW) | **apply** | CV.12 names one actor for writing and committing the copies: the coordinator's runtime, which the coordinator's application drives. CI.4, D-27 and X-3 stand without exception, and X-3 adds that no application of the first version is a tac client. R-3's trigger says that the reviewer's application is built outside this project. Source: PQ-30; triage § 1.4; CI.4 |
| **IC-11** | CI.2 (TAC > TAC-PEOPLE); CA.39 (TAC > TAC-PEOPLE > TAC-GROUPS) | **ask** QT-15 (written by this part) | In which team a runtime without a quest (Webwork's own AI, trc on the desktop) registers and what it may do there, since coordination is defined through the home team of a quest. Until answered the items keep their text, with a remark that the team of a runtime without a quest is open. |
| **IC-17** | CI.13 (TAC > TAC-PEOPLE) | **ask** QT-14 (written by this part) | Whether the host's setting for remote control also governs the published MCP endpoint, through which other team runtimes can queue items and move a process. Until answered CI.13, CT.11, CT.12 and CT.13 keep their text. |
| **IC-18** | CI.8 (TAC > TAC-PEOPLE) | **ask** QT-14 (written by this part) | Which credential a tac client presents (the account's access key, the team token, a key per runtime, a key per device, the bearer token of the MCP server). Until answered the items keep their text; no part writes a new credential. |
| **IC-19** | CI.18 (TAC > TAC-CRYPT) | **ask** QT-4 (written by this part) | Whether the relay authenticates a key per runtime issued by a team owner (CA.30) or the key of a paired device (CI.18, T5). Until answered CA.30 keeps its text marked as part of the open point, and D-23 and T5 state neither side as decided. |
| **IC-20** | WR-2 (TAC > TAC-WEBWORK); CI.10 (TAC > TAC-PEOPLE) | **apply** | WR-2: met differently: a team's tac server is strict (invitation and team token); identification by user id and e-mail alone exists only on an open tac server for one user. CI.10 says that open or strict is a setting of the tac server its administrator sets, and that strict is the setting for a tac server other users use. Source: D-54 (PQ-13), CI.10, N-19 |
| **IC-21** | CA.38 (TAC > TAC-SPEC) | **apply** | "A tac client that states no user still works" is restricted to the local backend. The promise that a runtime of an older version keeps working is stated from tac/2.0 on, since nothing uses tac/1.0. Source: D-54 (PQ-13), CI.10, E-11 |
| **IC-26** | CM.1 (TAC > TAC-KINDS); CM.2 (TAC > TAC-KINDS) | **apply** | CM.1 and CM.2 name sender and recipient per kind: eight kinds are messages between users; "notification" (from a runtime) and "command" (to a quest's runtime) are the two kinds between runtimes of CA.19 and are listed apart from them, as CM.14 says. The several senses of "notification" and "command" are left to QT-19. Source: CA.19, CM.14 |
| **IC-27** | CV.14 (TAC > TAC-REVIEW) | **apply** | CV.14: a round's blobs that a process pinned are kept for as long as the process runs (CV.4); the longest lifetime of 30 days holds for blobs that are not pinned. Source: D-29 (FO-8, FO-21, CQ-11), CV.4 |
| **GA-14** | CA.44 (TAC > TAC-PEOPLE > TAC-GROUPS); CI.6 (TAC > TAC-PEOPLE) | **apply** | No source says more, so one line under CA.44 says what the Solution Blueprint must settle: where a todo offer waits and who sees it, the form of the accepting rule, what the sender is told, its expiry, and where the switch "visible in another team" is stored; CI.6 and CA.19 each get the same kind of line for what happens to an invitation and to a stored command after their 7 days. Source: round_instructions § What decides, point 5. |
| **GA-16** | CI.18 (TAC > TAC-CRYPT) | **ask** QT-4 (written by this part) | Device pairing as a procedure: from inside what, with which program, where the key is kept on the device, expiry and rotation, a desktop machine off the VPN, a browser as a device. Until answered CI.18 says "the server a device reaches from the internet (which program that is, is open: PQ-<n>)" and describes no procedure. |
| **GA-17** | CM.6 (TAC > TAC-KINDS) | **ask** QT-4 (written by this part) | How a phone whose application is closed learns of an ask: a push service of the platform vendors is neither in scope nor out of scope. Until answered CM.6 and CK.11 keep their text and no push service is named. |
| **GA-26** | CM.11 (TAC > TAC-CONV) | **drop** | Phase 2 detail (editing, deleting, search, attachments and who may create a conversation are worked out in the Solution Blueprint; no source states them and nothing in the items is wrong) |
| **GA-27** | CV.12 (TAC > TAC-REVIEW) | **apply** | CV.12 says that every reviewer of a round is a member of the team (asking a person outside the team is later, L-3), and one line under it says what the Solution Blueprint must settle: a member who never returns a copy, a coordinator's runtime that is offline while the blobs expire, which repository and lease the coordinator's commit uses, and how the review round's member id relates to the tac user id. Source: L-3 (SCO > SCO-LATER); round_instructions § What decides, point 5. |
| **ID-3** | CI.18, CI.19 (TAC > TAC-CRYPT) | **ask** QT-14 (written by this part) | A table of credentials (who issues each, to whom, where it is kept, what it proves, how it is withdrawn). Until answered each credential stays described in its own item. |
| **ID-8** | CI.13 (TAC > TAC-PEOPLE) | **ask** QT-14 (written by this part) | One journal per quest of what people did to runs that are not theirs (remote control, a freed lease, an overridden precondition, a default taken, an accepted todo offer). Until answered "recorded" stays in CR.13, CP.20 and CA.14 without a named place. |
| **VX-49** | CV.12 (TAC > TAC-REVIEW); CV.13 | **apply** | The review round adds what is built: a reviewer who is not on the team takes part as a guest, named with name and role, and the merge writes a question about the guest; conflicts between members' changes, each with a decision; individual answers beside the team answer; proposed answers a person accepts, edits or discards; the time of an annotation's last change; the round's record keeps the next round. Source: ccparity_f_teamreview-1 … -3, vscimpb107, vscimpb115, qrfix10, vscimpb66b, vscimpb23 (done) |
| **WW-2** | CV.12 (TAC > TAC-REVIEW); CV.13 (TAC > TAC-REVIEW) | **apply** | CV.12 step 1 and CV.13 say that the round folder is created and merged by the coordinator's runtime or, for document kinds the runtime does not know, by the coordinator's application (Webwork creates and merges its own rounds, planned), and that it lies in the documents' storage, which is usually version control and for Webwork a local folder or a GitHub repository; tac is the transport in both cases. Source: webwork todo `09_woneb3` (planned), the idea `webwork_redesign` part-review; CV.12 step 3 already names the coordinator's application. |
| **WW-3** | CV.5 (TAC > TAC-DOCS) | **apply** | CV.5 adds one sentence: tac's review set is the pinned blobs of one round; the definition of what is under review (files, documents, sections, with its rounds) is the application's and lies in the documents' storage (Webwork: a YAML file, planned). The glossary entry "pinned in tac" stands. Source: webwork todo `09_woneb2` (planned); `GLO` review set (S21). |
| **WW-5** | CM.9 (TAC > TAC-CONV); CM.13 (TAC > TAC-CONV) | **ask** QT-24 (written by this part) | Where the conversation cache and the outbox of a user's messaging live, and who offers search over the cache: the runtime (one per machine and user, shared by its hosts) or each host for itself with the runtime only passing through; it decides whether Webwork builds a cache (webwork `13_woneb6`, `13_woneb7`). Until answered CM.9 and CM.13 keep "a tac client that was offline", which with CL.11 is the tac client inside the runtime, and no item says that a host keeps a cache or an outbox. |
| **WW-7** | new item in TAC-GROUPS (TAC > TAC-PEOPLE > TAC-GROUPS); CI.2 (TAC > TAC-PEOPLE) | **ask** QT-15 (written by this part) | How a runtime without a quest appears in tac: under which name it registers (Webwork plans the instance name `webwork-app`, registered without a quest and able to take part in the claims), which team it belongs to since CI.2 gives a runtime the home team of its quest, and whether it is listed among the team runtimes in trc. Until answered CR.6, CR.29 and T2 keep their text and no name is written. |
| **WW-13** | CM.6 (TAC > TAC-KINDS) | **ask** QT-4 (written by this part) | Whether the first version uses the platforms' push services (APNs, FCM) for asks and messages on a phone, or a phone learns of them only while the application runs and on start and resume, as Webwork decided for itself (webwork decision DPPHONE-4); the channels of CM.6 are named accordingly. Until answered CM.6 keeps its text and names no push service. |
| **WW-15** | CI.10 (TAC > TAC-PEOPLE) | **apply** | Add at CI.10: on a tac server set to open the member list can hold two entries with one e-mail address, or one person with two ids; tac returns both with their ids and does not merge them. Source: CI.10, N-19, N-22 (a stated identity is believed, ids are generated on redeeming an invitation); webwork idea part-messaging, Edge cases; webwork todo `13_woneb6`. |
| **WW-16** | CM.12 (TAC > TAC-CONV) | **drop** | nothing to change (confirms): CM.12 has `msg:tac/<team>/<messageId>`; the two older webwork todos that write `<server-group>` are corrected by the message of WW-22. |
| **WW-18** | CV.15 (TAC > TAC-REVIEW) | **apply** | CV.15 says which application that is: one that carries the review component and reaches tac through its runtime, which is the VS Code extension today, Webwork and Webforge on the desktop later and a web version after that, none of them built here; so a business reviewer (U-2) needs one of these on a desktop until then. Source: PQ-30 (triage § 1.4); webwork todo `13_woneb10`. |

Questions this part writes: QT-4, QT-6, QT-14, QT-15, QT-24 (§ 3).

**Also reaches this part** (ruled in the owning part's row; read that row and the finding):

| Finding | Items of this part | Owner | Ruling there |
| --- | --- | --- | --- |
| AN-11 | TAC-CONV | `p1s1r4-5` | ask QT-19 |
| AN-15 | WR-6 | `p1s1r4-5` | apply |
| AN-17 | CA.36 | `p1s1r4-6` | apply |
| AN-20 | CI.4, CI.19, WR-6 | `p1s1r4-3` | ask QT-2 |
| AN-24 | CI.2, CI.3, CI.6, CI.7, CA.40 | `p1s1r4-3` | ask QT-2 |
| AN-26 | WR-6 | `p1s1r4-5` | ask QT-4 |
| AN-30 | CA.44, CM.4, CV.11 | `p1s1r4-6` | ask QT-5 |
| AN-35 | WR-6 | `p1s1r4-6` | apply |
| AN-40 | CA.41, CA.42 | `p1s1r4-6` | apply |
| AN-41 | CA.36 | `p1s1r4-8` | ask QT-8 |
| AN-42 | CM.12 | `p1s1r4-6` | ask QT-8 |
| IC-1 | CA.36, CA.42 | `p1s1r4-6` | ask QT-13 |
| IC-25 | CI.19 | `p1s1r4-2` | ask QT-4 |
| GA-2 | CI.2, CA.40 | `p1s1r4-3` | ask QT-2 |
| GA-8 | CI.11 | `p1s1r4-4` | apply |
| GA-11 | CV.12 | `p1s1r4-8` | apply |
| GA-13 | CI.5, CI.13 | `p1s1r4-5` | ask QT-14 |
| GA-15 | CI.15 | `p1s1r4-3` | apply |
| GA-18 | CV.2, CI.3, CI.14, CM.2 | `p1s1r4-9` | apply |
| GA-19 | CM.6 | `p1s1r4-11` | ask QT-21 |
| GA-22 | CV.12, CV.15 | `p1s1r4-2` | apply |
| ST-2 | CI.19 (QT-4) | `p1s1r4-5` | apply |
| ST-3 | CA.39, CI.19, the lead-in of TAC > TAC-PEOPLE, TAC > TAC-WEBWORK | `p1s1r4-6` | apply |
| ST-5 | TAC > TAC-PEOPLE > TAC-GROUPS, TAC > TAC-CRYPT | `p1s1r4-11` | ask QT-21 |
| ST-7 | CA.41, CA.42, CA.44, CI.5, CI.11, CI.13 | `p1s1r4-11` | ask QT-21 |
| ST-9 | CI.5, CM.2, CM.4, CM.6, CV.12 | `p1s1r4-11` | ask QT-19 |
| ST-16 | CA.39, CI.10 | `p1s1r4-11` | ask QT-21 |
| ID-4 | CM.* | `p1s1r4-6` | ask QT-8 |
| ID-5 | CI.5 | `p1s1r4-6` | ask QT-5 |
| VX-32 | TAC-KINDS (notification "out of budget") | `p1s1r4-3` | apply |
| VX-39 | CM.4 (tac's reminders are kept apart) | `p1s1r4-3` | apply |
| VX-40 | TAC-KINDS (decision request) | `p1s1r4-3` | apply |
| A-8 | CR.6 (QT-15) | `p1s1r4-3` | apply |
| A-10 | CM.4 | `p1s1r4-3` | apply |
| WW-1 | CV.15 | `p1s1r4-5` | ask QT-7 |
| WW-4 | WR-4, WR-5 rows of TAC-WEBWORK (met through the runtime client SDK, CP.3) | `p1s1r4-4` | apply |
| WW-6 | TAC-WEBWORK (the line recording the need), QT-15 | `p1s1r4-6` | ask QT-17 |
| WW-8 | QT-14 (which credential such an endpoint asks for) | `p1s1r4-6` | ask QT-14 |
| WW-12 | CM.3, CV.9 (check only) | `p1s1r4-5` | apply |
| WW-17 | WR-6 row of TAC-WEBWORK | `p1s1r4-2` | apply |
| WRS | CI.4, CI.18, CI.19, CM.6, WR-6 row (QT-4 for which of token or device key the device holds; WW-13) | `p1s1r4-3` | ask QT-2 |

### 2.7 `p1s1r4-8` — `PAR`

35 findings: 18 apply, 14 ask, 3 drop.

| Finding | Items (section chain) | Ruling | What the text is to say, the question, or the reason |
| --- | --- | --- | --- |
| **AN-8** | CQ.1, CQ.5, CQ.7 (PAR > PAR-QUESTS) | **apply** | The Project Idea follows the standard: three quest types in one register (classic quest; repository quest as a single-quest repository or a multi-quest repository; _ai/quests.yaml), the same inside for every type (CQ.5, its check mark goes), the further quest operations in CQ.7; none of it built. CQ.2, CQ.3, CQ.6 and D-34 keep their text until QT-9 and QT-10 are answered. Source: PQ-24 (second half); S22 (§ 3, § 3.1); triage § 1.6 |
| **AN-18** | P-5, P-9 (PAR > PAR-PROBLEM); CW.11 (PAR > PAR-APPROACH); CW.18 (PAR > PAR-CROSS) | **ask** QT-19 (written by `p1s1r4-11`) | "Session" is used for "another writer" where an execution or a runtime is meant, and CW.18 names a session as an address. Until answered the items keep their words. |
| **AN-41** | CW.7, CW.8 (PAR > PAR-APPROACH); CW.24 (PAR > PAR-CROSS) | **ask** QT-8 (written by `p1s1r4-6`) | Whether a resource name without a prefix is accepted from existing todos, and whether the repositories a runtime registers (CA.3) use the same notation. Until answered resources are written with the prefix git: wherever a quest's list or a todo names them, and nothing is said about names without it. |
| **IC-2** | CW.6 (PAR > PAR-APPROACH) | **apply** | CW.6 says: tac keeps the order (the integration queue); the runtime whose execution is first in it carries out the integration step on its machine (rebase, the repository's declared checks, fast-forward, push). tac runs no checks and lands no commits. What the queue is on the local and the GitHub backend is left to QT-13. Source: N-34, N-28, CW.5 |
| **IC-4** | CW.19 (PAR > PAR-CROSS) | **apply** | One statement of the path: what is sent to another quest is kept as a record by tac (on one machine: in the machine-wide state), the sender's run shows it with its delivery state and what it waits for, and it is not shown as taken at the receiver before a run there took it. CA.19 and CR.36 refer to CW.19 and use the same words. What happens after the 7 days is GA-14. Source: CW.19 (S21, TQ-11), CA.19, CR.36 |
| **IC-5** | CW.25 (PAR > PAR-CROSS) | **apply** | CW.25 keeps "later" and says what is later: creating a todo in another quest by handing it to a runtime of that quest. Sending a queue item or a walk into a named run of another quest as a command through tac (CW.20, CA.21, F7) is in the first version; the two are named apart so they do not read as one path. Source: PQ-23 (CW.25), CW.20 (S1 § 9, § 10.5) |
| **IC-6** | CQ.6 (PAR > PAR-QUESTS) | **ask** QT-10 (written by this part) | Whether a repository quest still has a branch per member (CQ.6) when the _ai state stays on the main branch and never gets working trees (CW.14, CW.2). Until answered CQ.6, CW.14 and CW.2 keep their text. |
| **GA-9** | CW.5, CW.6, CW.10 (PAR > PAR-APPROACH) | **ask** QT-13 (written by `p1s1r4-6`) | What happens when the integration step fails: what the execution does with a rejection, who resolves a rebase conflict, how often the re-run repeats, a finished branch whose runtime ended, how long the integration lease is held, where the checks and the working trees are, and the integration queue on the local and GitHub backends. Until answered CW.5, CW.6 and CW.10 keep "lands the execution's commits or rejects them back to it". |
| **GA-10** | CW.11, CW.1 (PAR > PAR-APPROACH) | **apply** | No source describes the discard beyond CW.11, so one line under CW.11 says what the Solution Blueprint must settle: who triggers a discard and through what, what it does in worktree mode before integration (the branch) and after (the revert of the range), and what happens to the todo's state and to `_ai` changes the execution made. Source: round_instructions § What decides, point 5; CW.11 (S1 § 10.4, item 6). |
| **GA-11** | CW.25, CW.21, CW.22 (PAR > PAR-CROSS) | **apply** | State how a change in the `_ai` state or in a quest's repository reaches another machine: by a pull and a push the user starts (the quest operations of CQ.7; O-6 stands); a todo written for another quest or a blocker followed across machines is seen there after that step, and tac carries only the live notice. Who commits what the runtime wrote, and under which lease, is not written here: it goes with AB-10. Source: S22 (quest operations Pull / Push / Status, "started by you, never automatic", ATB QM-10); triage § 1.6; O-6. |
| **VX-29** | CW.21 (PAR > PAR-CROSS); P-14 (PAR > PAR-PROBLEM) | **apply** | CW.21 names both directions: on every status change of a todo, by any writer, every todo of every quest that names it as a blocker is evaluated again: released when all its conditions are met (to decision needed when it has open decisions), blocked again when a blocker is reopened; and a todo can wait for a published package version (a release condition read from the package registry). What blocks what in the other direction is derived, never stored. P-14 is reworded to what still hurts: the ripple of a release through the dependents, and that a release condition is only checked when a blocker completes. Source: vscimpb121_akon-blocked-todos-follow-their-blockers, ideatests2_akqj-cross-quest-dependencies-as-blocked-by (done) |
| **VX-34** | CW.19 (PAR > PAR-CROSS); CW.20 | **apply** | CW.20 adds the two rules: a sent item never creates a run (a run the receiver does not have is refused; without a run named it goes into the receiver's run `default`, never the run a host there happens to show), and it is queued with the receiver's own defaults unless the sender names a profile, a session or a new, possibly temporary, session; a walk or a todo or group item runs over the receiver's todos. CW.19 stands as it is. Source: ww_a_collab-4_akmt-send-item-to-quest-walk-in-run (done) |
| **VX-43** | CQ.3 (PAR > PAR-QUESTS); CQ.2 | **ask** QT-9 (written by this part) | Where sessions, the compact trail and the live trail are kept: per host in the quest folder with the consolidated trail and the history derived and untracked (the standard, S22; 01_aifmt-4, 00_aifmt-1), or in the personal repository (CQ.3, D-34). Until answered CQ.2 and CQ.3 keep their text, and new text about sessions and trails says "per host" without naming the place. |
| **VX-46** | CQ.1 (PAR > PAR-QUESTS); CQ.7 | **apply** | CQ.1 names three quest types with one register, as triage § 1.6 words them: a classic quest; a repository quest as a single-quest repository or as a multi-quest repository (one bare clone, each quest a branch checked out as a working tree at the quest's place); the register `_ai/quests.yaml` lists every quest with its type, and a workspace's list picks from it. CQ.7 adds: pick and unpick for a workspace, remove from the workspace or the machine (refused with unpushed work), pull, push and status started by the user only, set up this machine, check and fix. Whether these are commands of the runtime is QT-11. Source: S22; triage § 1.6; 02_aifmt-1_aktn-quest-management (planned) |
| **A-4** | CQ.3 (PAR > PAR-QUESTS) | **ask** QT-9 (written by this part) | Where sessions, the trail and the history are kept: the standard keeps sessions and the compact trail in the quest, one file per host, derives the history and keeps the live trail machine-local, while CQ.3 puts them into the personal repository. Until answered CQ.3 keeps its text, and new text about sessions and trails says "per host", names the class (derived, machine-local) where S22 gives it, and leaves the place to the question. |
| **Q-1** | CQ.1 (PAR > PAR-QUESTS) | **apply** | CQ.1 names three quest types: a classic quest (a folder in the shared state repository) and a repository quest in two forms, a single-quest repository (one clone at the quest's place) and a multi-quest repository (one bare clone under `_ai/.quest-repos/`, each quest a branch `quest/<id>` checked out as a working tree at the quest's place); the types coexist in one `_ai`. The words stay "classic quest" and "repository quest" (S21); the standard's "folder quest" and "repo-based quest" are named once in GLO, so the finding's question on words is not asked. Source: S22 § 3.1, § 2.4 (QM-3, QM-4); triage § 1.6. |
| **Q-2** | CQ.7 (PAR > PAR-QUESTS) | **ask** QT-11 (written by this part) | Whether a quest inside a project's own repository (a folder of it, or a branch of it through the single-quest form) is wanted; no source describes it. Until answered CQ.1 names the three types only and says nothing of a quest in a project's repository. |
| **Q-3** | CQ.2 (PAR > PAR-QUESTS); CQ.3 (PAR > PAR-QUESTS) | **ask** QT-9 (written by this part) | Personal files: the standard has no personal repository and tracks sessions, the compact trail, the journal, the host's configuration and the memory candidates in the quest, one file per host, which puts each member's prompts and answers into a shared quest's repository; CQ.2, CQ.3 and D-34 keep them in a personal repository, "never in a quest's". The question also names that the files are per host, not per user. Until answered CQ.2, CQ.3 and D-34 keep their text and no new text writes "personal repository". |
| **Q-4** | CQ.3 (PAR > PAR-QUESTS) | **ask** QT-9 (written by this part) | Personal notes of a quest: the standard has quest notes in the quest (shared, the user's, never written by agents, as CQ.4 says) and no notes for one user only. Until answered CQ.3's entry "personal notes" keeps its text and CQ.4 stands. |
| **Q-5** | CQ.5 (PAR > PAR-QUESTS) | **apply** | CQ.5 stands and takes the standard as its source: every quest folder has the same inside whatever its type, so one resolver serves all three types; the `___check here___` paragraph after CQ.8 goes. Its words "and of a personal file" keep their text until QT-9. Source: S22 § 3.1, § 3.2; triage § 1.6. |
| **Q-6** | CQ.6 (PAR > PAR-QUESTS) | **ask** QT-10 (written by this part) | What of CQ.6 remains on top of the new types: the standard has one branch per quest merged between machines by the drivers, the quest's own `.gitattributes` and the hooks path, and says nothing of a branch per member, the second repository with encrypted credentials, the secret scan or member access; a multi-quest repository's never-merged branches leave no room for member branches. Until answered CQ.6 keeps its text. |
| **Q-7** | CQ.7 (PAR > PAR-QUESTS) | **apply** | CQ.7 adds the operations of the standard beside create, join and migrate: add an existing quest, pick and unpick for a workspace, remove from the workspace or from the machine (refused with uncommitted or unpushed work; nothing in git is deleted), pull / push / status started by the user, set up this machine, check and fix; migrate takes several quests at once into either form and goes one way. Join's "the personal repository is set up, the user is registered as a member" and migrate's trial migration keep their text until QT-9 and QT-10. Source: S22 § 4, § 2.4 (QM-5 … QM-10, C-1); triage § 1.6. |
| **Q-8** | - | **drop** | nothing to change (confirms) |
| **Q-10** | CW.25 (PAR > PAR-CROSS) | **apply** | CW.25 says a todo is written into another quest directly only where that quest is checked out on this machine; a repository quest that is missing here is reached through a runtime of it (tac, its MCP server), as the item already says. O-6 adds that pull and push of a quest's repository are steps the user starts. Source: S22 § 4 (actions 4, 6), § 2.4 (QM-10). |
| **Q-11** | CQ.7 (PAR > PAR-QUESTS) | **ask** QT-11 (written by this part) | Whether the quest operations are commands of the runtime, so that every host gets them, or the VS Code host's view only (the standard specifies a view of the extension; creating a GitHub repository or running `git filter-repo` from a runtime behind a web runtime service is probably not wanted). Until answered CQ.7 names the operations without saying which program carries them, and no screen row is added. |
| **Q-12** | CQ.7 (PAR > PAR-QUESTS) | **apply** | CQ.7's create says: a repository created for a quest (a single-quest or a multi-quest one) is created only after a confirmation, private and with GitHub Actions switched off; an existing repository can be taken instead. Source: S22 § 2.4 (QM-5, QM-6), § 4 action 1. The coordination repository gets the same words from al_the_bear `14_loose_wslayout-4` (planned). |
| **AB-8** | CW.3 (PAR > PAR-APPROACH) | **apply** | CW.3 names the place: the working trees lie under the root's `.worktrees/`, which the fleet's skills skip and report uncommitted work in. The tree is per execution, as CW.2 and S21 (TQ-4) say; the finding's question is not asked, and the fleet's fixture, which names trees by run, is al_the_bear's to align. Source: al_the_bear `11a_wslayout-1_aksp-collab-d1-worktree-fixture` (completed), `repo_skills_new.md` § 5.12, § 5.13; S21, TQ-4. |
| **AB-9** | CW.16 (PAR > PAR-APPROACH) | **apply** | CW.16 says when it happens: when a claim is taken or when the user asks, never on a schedule. O-6 names it as its second exception beside the integration step. Source: al_the_bear `14_loose_wslayout-5_akto-reconcile-rule-auto-update-exception` (planned). |
| **AB-10** | CW.14 (PAR > PAR-APPROACH) | **ask** QT-23 (written by `p1s1r4-3`) | Who commits and pushes what the runtime writes in `_ai` and in a quest's repository: the runtime by path with a message, or nobody but the snapshot of a sync and the user. Until answered the text says the runtime writes the files and says nothing on committing; it never stashes and never discards changes it did not make. |
| **AB-11** | CW.13 (PAR > PAR-APPROACH) | **apply** | CW.13 adds that a sync may merge `_ai` in place while runtimes run, so a runtime never assumes the copy of an `_ai` file it read is the file's state and reads it again before it writes. E-17 adds that the fleet's skills recognise only VS Code processes today and have no todo yet for asking tac or a runtime process. Source: `repo_skills_new.md` § 4; al_the_bear `12a_wslayout-2` step 1. |
| **AB-13** | CW.6 (PAR > PAR-APPROACH) | **apply** | CW.6 says the checks of the integration step run on the machine of the execution, as part of an item a person queued; they are no scheduled and no hosted check (CW.1: no build server). The exception this needs in the fleet's rule is al_the_bear's work. Source: the root guideline `workspace_agents.md` § General Rules; CW.1, CW.5. |
| **AB-14** | CW.13 (PAR > PAR-APPROACH); CW.5 (PAR > PAR-APPROACH) | **ask** QT-13 (written by `p1s1r4-6`) | Whether a running reconcile of the fleet is a lease in tac (so the push of an integration step waits for it and a second reconcile is refused) or only something tac shows. Until answered CW.13 keeps its text (a sync asks who holds what and can ask a runtime to pause its queue) and nothing is written about a reconcile as a lease. |
| **AB-21** | - | **drop** | covered by Q-12 (nothing else to change, confirms CW.1) |
| **AB-22** | - | **drop** | covered by Q-7 (remove deletes nothing in git, S22 QM-8); retiring a quest into the archive repository is the workspace's rule, not this product |
| **TF-10** | CQ.7 (PAR > PAR-QUESTS) | **ask** QT-11 (written by this part) | Tom Forge needs the operations on repository quests as commands of the runtime and components for them (member branch state, Publish and Update, conflict review, create and join, the migration with its dry run, the key prompt), and for a later web build a working copy per member on the server with commits through a GitHub App (tom_forge `qavs_wwwgitruntime-1`, `later23`); whether they are commands of the runtime, so that every host gets them, is QT-11, and what of member branches remains is QT-10. Until answered CU.6 has no component for repository quests and CR.46 says nothing of a working copy on a server (that part belongs to QT-2). |

Questions this part writes: QT-9, QT-10, QT-11 (§ 3).

**Also reaches this part** (ruled in the owning part's row; read that row and the finding):

| Finding | Items of this part | Owner | Ruling there |
| --- | --- | --- | --- |
| AN-4 | CW.4 | `p1s1r4-3` | apply |
| AN-5 | CW.5 | `p1s1r4-4` | ask QT-1 |
| AN-10 | CW.11, CW.23, CQ.3 | `p1s1r4-4` | apply |
| AN-30 | CW.20, CW.21, CW.23, CW.26 | `p1s1r4-6` | ask QT-5 |
| AN-32 | CW.6 | `p1s1r4-7` | apply |
| AN-42 | CW.18 | `p1s1r4-6` | ask QT-8 |
| IC-1 | CW.5 | `p1s1r4-6` | ask QT-13 |
| IC-7 | CW.5 | `p1s1r4-6` | ask QT-13 |
| GA-4 | CW.7 | `p1s1r4-3` | apply |
| GA-6 | CQ.3, CQ.6, CQ.7 | `p1s1r4-3` | ask QT-16 |
| GA-14 | CW.26 | `p1s1r4-7` | apply |
| GA-19 | CW.12, CW.16, CQ.6, CQ.7, CQ.8 | `p1s1r4-11` | ask QT-21 |
| GA-23 | P-5 … P-14 | `p1s1r4-11` | ask QT-21 |
| GA-25 | CQ.5 | `p1s1r4-2` | apply |
| GA-27 | CW.5 | `p1s1r4-7` | apply |
| ST-2 | CQ.5 and the remark after CQ.8 | `p1s1r4-5` | apply |
| ST-3 | the lead-in of PAR > PAR-APPROACH | `p1s1r4-6` | apply |
| ST-5 | PAR | `p1s1r4-11` | ask QT-21 |
| ST-7 | CW.2, CW.8, CW.24, CW.26 | `p1s1r4-11` | ask QT-21 |
| ST-9 | CQ.7 | `p1s1r4-11` | ask QT-19 |
| ST-10 | CW.2 | `p1s1r4-11` | apply |
| ST-16 | CW.5, CQ.6 | `p1s1r4-11` | ask QT-21 |
| ID-1 | CW.16, CW.25 | `p1s1r4-11` | ask QT-21 |
| ID-2 | CW.5 | `p1s1r4-6` | ask QT-13 |
| ID-4 | CW.18 | `p1s1r4-6` | ask QT-8 |
| ID-10 | PAR > PAR-PROBLEM | `p1s1r4-11` | ask QT-21 |
| VX-17 | CW.4 | `p1s1r4-3` | ask QT-1 |
| VX-28 | CW.21 | `p1s1r4-3` | apply |
| VX-33 | CW.23 | `p1s1r4-3` | apply |
| VX-42 | CQ.3, CQ.4 (quest notes against the notes folder) | `p1s1r4-3` | apply |
| VX-44 | CQ.3 (QT-9) | `p1s1r4-3` | apply |
| A-1 | CQ.1, CQ.5, CQ.7 | `p1s1r4-2` | apply |
| A-3 | CW.14 | `p1s1r4-3` | apply |
| A-7 | CW.14 | `p1s1r4-6` | apply |
| Q-9 | CQ.1 | `p1s1r4-3` | apply |
| AB-5 | CW.5, CW.24 | `p1s1r4-3` | apply |
| AB-6 | CW.8, CW.24 | `p1s1r4-3` | apply |
| AB-7 | CW.3 | `p1s1r4-3` | apply |
| AB-12 | CQ.6, CW.14 | `p1s1r4-2` | apply |
| AB-19 | CW.3 | `p1s1r4-10` | apply |
| AB-24 | CQ.6 | `p1s1r4-3` | apply |
| TF-6 | PAR-APPROACH | `p1s1r4-3` | ask QT-16 |

### 2.8 `p1s1r4-9` — `NFR`

8 findings: 8 apply, 0 ask, 0 drop.

| Finding | Items (section chain) | Ruling | What the text is to say, the question, or the reason |
| --- | --- | --- | --- |
| **AN-27** | N-19, N-21, N-25, N-29, N-30 (NFR); T5, T8 and the paragraph under the table (NFR > NFR-TOPO); F1, F10, a new flow (NFR > NFR-TOPO > NFR-TOPO-FLOWS); G units (NFR > NFR-GEN) | **apply** | Every place writes "web runtime service" and adds the web runtime client SDK (Dart; JavaScript / TypeScript) beside the two client SDKs; the service is HTTP-based and reaches tac through the runtime on the server; statements on how it works are marked as assumed; a new decision records the answer as a direction, not a design; what is open stays with QT-2, QT-3 and QT-4 (the browser as a device in N-21, the publishing of N-29, the units, the flow for a phone). Source: PQ-28; triage § 1.2 |
| **IC-31** | F1, F3, F6, F10, F11 (NFR > NFR-TOPO > NFR-TOPO-FLOWS) | **apply** | The flows follow their items: F3 "lowest number first" (CR.19); F6 "the round's blobs are released" and the step that writes the copies into the round folder and commits them (CV.12); F1 ends with the registration with tac (CA.3, CA.34); F10 "trc reads through its runtime" (CI.4); F11 names its steps: the invitation (CI.6), the device pairing off the VPN (CI.18), the registration (CA.3). Source: CR.19, CV.12, CA.3, CA.34, CI.4, CI.6, CI.18 |
| **IC-34** | N-6 (NFR); N-23 (NFR); NFR-GEN lead-in (NFR > NFR-GEN) | **apply** | N-6: "the runtime names the revision of MCP it speaks" (CT.15). N-23: a prompt that draws on a document the host marks as encrypted leaves no trail on disk (CR.24), with a line that the Blueprint must settle how a reload (CP.6) and the commit record (CW.11) work for it. NFR-GEN: "the register above". Further: the VIS-SYSTEM row of the client SDKs adds PQ-7; the SCO-IN row adds N-24; CL.2 states why the runtime client SDK depends on the tac client SDK or carries a line that the Blueprint must settle it; CK.4 carries a line that it is open whether trc shows one team at a time or all of the user's. TypeScript and JavaScript as one SDK is left to QT-3. Source: correction; CT.15, CR.24 |
| **GA-18** | NFR (the lead-in and a new closing list) | **apply** | The sources give none of these numbers, so NFR gets one list "Not stated by the sources; the Solution Blueprint settles" naming performance, capacity, limits and quotas, availability and backup of the tac server, privacy (deletion and export of a user's data, what the trail may contain), observability, supported versions, accessibility and languages of the UI components, and the budget behind "out of budget"; the audit record is left to QT-14 (ID-8). USR > USR-TEAM's "No e-mail address is stored" is worded as a statement about this document's review team, not about tac. Source: NFR lead-in ("none carries a number the sources do not give"); round_instructions § What decides, point 5. |
| **GA-20** | G-1 … G-7 (NFR > NFR-GEN); N-30 (NFR) | **apply** | NFR-GEN gets one line naming what is delivered and has no unit yet, for the Solution Blueprint to assign: the conformance suite (CL.6), the VS Code extension as a host on the new line (D-41), the tac server's command line and administration interface (CI.20, CA.27), the migration between backends (CA.33), the merge drivers (E-5, CQ.6), the successor of `tom_vscode_scripting_api` (CL.10); N-30 adds the security model that CI.19, N-21, CA.30 and R-22 defer to. The program for phones and browsers is left to QT-2 (GA-1). Source: the items named (CL.6, D-41, CI.20, CA.27, CA.33, CL.10, CI.19, N-21); round_instructions § What decides, point 5. |
| **AB-20** | N-29 (NFR) | **apply** | N-29 adds: the binaries repository is public, so every third-party package bundled into what is published there has a licence that is not copyleft; the payload is built per platform by a build the user starts; a machine without the workspace takes the payload from the public repository or inside a host's installer (CR.42). Source: al_the_bear `binlic1`, `binpriv1` (completed); `repo_structure_new.md` § 4. |
| **TF-12** | N-25 (NFR) | **apply** | N-25 adds: the components are written for the Flutter version and the widget libraries their hosts are on, since a component and its host must share those types; the version itself stands as a dependency in `RISK > RISK-DEPS` (the hosts move to Flutter 3.50 and Dart 3.14 with `material_ui` and `cupertino_ui`, planned). Source: tom_forge todo `06a_flutterm1`; webwork todos `05a_flutterm1`, `06b_flutterm1` (planned); triage § 1.7 for the place of version numbers. |
| **TF-13** | N-29 (NFR) | **apply** | N-29 adds: the Dart client SDKs and `tom_ai_runtime_ui` take only dependencies without a copyleft licence, because Tom Forge and Webwork test the resolved graph of their applications; whether the same holds for what the runtime installs (npm packages, provider SDKs) is for the Solution Blueprint to settle (unverified whether the hosts' tests look at those). Source: `spec_quest_workbench.tom_forge.md` § 4 (test `qim_none-1`); webwork idea part-messaging; webwork todo `13_woneb6`. |

**Also reaches this part** (ruled in the owning part's row; read that row and the finding):

| Finding | Items of this part | Owner | Ruling there |
| --- | --- | --- | --- |
| AN-1 | F5 | `p1s1r4-4` | apply |
| AN-2 | N-15 | `p1s1r4-4` | apply |
| AN-6 | F4, F5 | `p1s1r4-3` | apply |
| AN-14 | T8 | `p1s1r4-3` | apply |
| AN-15 | N-26, G-1 | `p1s1r4-5` | apply |
| AN-20 | T8 and the paragraph under the topology table | `p1s1r4-3` | ask QT-2 |
| AN-21 | T5 | `p1s1r4-6` | ask QT-4 |
| AN-22 | N-26, N-31, G-3, G-4, G-5 | `p1s1r4-5` | ask QT-3 |
| AN-23 | T8 | `p1s1r4-4` | ask QT-3 |
| AN-25 | T6, T8 | `p1s1r4-3` | ask QT-2 |
| AN-26 | T8 and the sentence "T1 to T5 and T8 belong to the first version" | `p1s1r4-5` | ask QT-4 |
| AN-30 | F5, F10 | `p1s1r4-6` | ask QT-5 |
| AN-32 | N-12, T3, T4, F11 | `p1s1r4-7` | apply |
| AN-34 | G-6 | `p1s1r4-2` | apply |
| AN-35 | N-26 | `p1s1r4-6` | apply |
| AN-43 | N-30 | `p1s1r4-4` | apply |
| IC-1 | F8 | `p1s1r4-6` | ask QT-13 |
| IC-3 | F11 | `p1s1r4-2` | apply |
| IC-9 | F1 | `p1s1r4-3` | apply |
| IC-11 | T2 | `p1s1r4-7` | ask QT-15 |
| IC-12 | N-10, T2 | `p1s1r4-3` | ask QT-16 |
| IC-16 | T1 | `p1s1r4-6` | ask QT-17 |
| IC-19 | T5 | `p1s1r4-7` | ask QT-4 |
| IC-21 | N-4 | `p1s1r4-7` | apply |
| IC-25 | N-21 | `p1s1r4-2` | ask QT-4 |
| IC-28 | G-6 | `p1s1r4-5` | ask QT-7 |
| GA-1 | G-1 … G-7, N-30, T8 | `p1s1r4-3` | ask QT-2 |
| GA-2 | T8 | `p1s1r4-3` | ask QT-2 |
| GA-3 | N-13 | `p1s1r4-6` | apply |
| GA-5 | G-2 | `p1s1r4-6` | ask QT-17 |
| GA-6 | N-10, T2 | `p1s1r4-3` | ask QT-16 |
| GA-9 | F8 | `p1s1r4-8` | ask QT-13 |
| GA-13 | N-19 | `p1s1r4-5` | ask QT-14 |
| GA-16 | T5 | `p1s1r4-7` | ask QT-4 |
| GA-30 | T1, N-32, N-33 | `p1s1r4-2` | ask QT-18 |
| ST-3 | NFR > NFR-GEN, N-13 | `p1s1r4-6` | apply |
| ST-6 | N-1 … N-7, N-11 … N-14, N-16 … N-20, N-22, N-23, N-25, N-26, N-31 | `p1s1r4-11` | ask QT-21 |
| ST-7 | N-19, T8 | `p1s1r4-11` | ask QT-21 |
| ST-9 | G-2 | `p1s1r4-11` | ask QT-19 |
| ST-13 | T1 … T8, F1 … F12, G-1 … G-7 | `p1s1r4-11` | ask QT-21 |
| ST-15 | T8 | `p1s1r4-11` | ask QT-21 |
| ST-18 | T8 | `p1s1r4-2` | apply |
| ID-1 | T6, T7, F9 | `p1s1r4-11` | ask QT-21 |
| ID-2 | F8 | `p1s1r4-6` | ask QT-13 |
| ID-7 | F1, F2, F3, F8 | `p1s1r4-10` | ask QT-20 |
| ID-9 | G-5 | `p1s1r4-5` | ask QT-3 |
| VX-PQ24 | N-15, F5 | `p1s1r4-4` | apply |
| VX-2 | N-15, F5 | `p1s1r4-4` | apply |
| VX-27 | F5 | `p1s1r4-3` | apply |
| VX-48 | G-6 | `p1s1r4-5` | ask QT-7 |
| A-14 | F12 | `p1s1r4-4` | ask QT-12 |
| AB-17 | N-27 | `p1s1r4-10` | apply |
| AB-19 | N-27 | `p1s1r4-10` | apply |
| WW-1 | G-6, N-25 | `p1s1r4-5` | ask QT-7 |
| WW-6 | N-11, N-12 | `p1s1r4-6` | ask QT-17 |
| WW-7 | T2 | `p1s1r4-7` | ask QT-15 |
| WW-9 | T2 | `p1s1r4-3` | apply |
| WW-14 | N-17 (check only) | `p1s1r4-4` | apply |
| WW-17 | T8 | `p1s1r4-2` | apply |
| WW-19 | N-25, G-6 | `p1s1r4-5` | ask QT-7 |
| WW-20 | the compatibility items of NFR (after TF-9's answer) | `p1s1r4-2` | apply |
| TF-3 | N-18 (check only) | `p1s1r4-4` | apply |
| TF-4 | N-24 | `p1s1r4-3` | ask QT-22 |
| TF-6 | N-10, T2, N-8 | `p1s1r4-3` | ask QT-16 |
| TF-8 | G-6 | `p1s1r4-5` | ask QT-7 |
| TF-9 | N-8, a new testing item in NFR | `p1s1r4-3` | ask QT-23 |
| WRS | T8, the units of NFR-GEN | `p1s1r4-3` | ask QT-2 |

### 2.9 `p1s1r4-10` — `DEC`, `CON`, `RISK`, `DEL`

17 findings: 14 apply, 2 ask, 1 drop.

| Finding | Items (section chain) | Ruling | What the text is to say, the question, or the reason |
| --- | --- | --- | --- |
| **AN-7** | new R-<n> (RISK > RISK-RISKS); DEL "The order of building" | **apply** | A new risk: one unanswered ask makes a whole run wait (and, in strict mode, keeps a repository leased) for as long as its chain takes; trigger: an ask without a default addressed to a person who is away. R-10 names it as a second trigger. DEL's sentence about a todo that waits for a todo of the other run uses the words of triage § 1.1 ("is held"). Source: PQ-24 (b); triage § 1.1 |
| **IC-23** | D-22 (DEC); X-4 (CON) | **apply** | D-22 and X-4 say: the tac server is built as the full tac server; there is no smaller one before it. "Built first" goes, since no order of building is fixed. Source: D-45 (PQ-8), CA.27 |
| **IC-24** | D-20 (DEC) | **apply** | D-20 says: asks are routed by presence and along a chain of persons (the person named, the quest owner, the owner of the triggering quest, the team owners). "By role" goes; the items have no routing to whoever holds a role. Source: CP.17, CP.18, CP.19 (CQ-7, DQ-3) |
| **IC-30** | D-8 (DEC); D-16 (DEC); D-59 (DEC) | **apply** | D-8 names RT > RT-TRANSPORTS only (CR.30, CR.31); D-16 names RT > RT-TRANSPORTS (CR.29); the sentence of PQ-20 in D-59 moves to a decision of its own that shaped TAC > TAC-PEOPLE (CI.20). In SCO > SCO-IN the Agent Client Protocol stands in the row of CR, and the row CI adds PQ-12, PQ-20 and PQ-23 to its sources. Source: correction; CR.29, CR.30, CR.31, CI.5, CI.20, CA.39 |
| **GA-21** | DEL | **ask** QT-20 (written by this part) | What "finished" is checked against (which topologies and flows must run) and whether a first usable state exists inside "one go". Until answered DEL keeps D-45, D-21 and D-32 as they stand. |
| **GA-24** | DEC (the heading over the decisions from PQ-1 … PQ-23) | **apply** | DEC says in one sentence that PQ-5 and PQ-11 carry no decision of their own: each was asked again, PQ-5 as PQ-21 and PQ-11 as PQ-20, and their effect is cited under those ids. Source: `01_02_Questions Round/changes.md` (rows PQ-5, PQ-11). |
| **ST-8** | D-47, D-50 (DEC); R-24 (RISK > RISK-RISKS); the entry in CON that says "first delivery" | **apply** | The document says "first version" in every place; "first delivery" is not used, since the product is built in one go (D-21, D-32) and both words name the same thing. What the first version contains as one list is ID-1 (QT-21). Source: D-21, D-32 (one delivery); the correction has only one reasonable reading. |
| **ID-7** | DEL | **ask** QT-20 (written by this part) | One thin path that is run end to end as early as possible (T1, the local tac service, one claim and one integration step in each mode) as the first usable state and first acceptance. Until answered DEL names no intermediate state. |
| **VX-56** | R-16 (RISK > RISK-DEPS) | **apply** | R-16 names, beside the remaining features, the layering of the engine as work the extraction depends on: the engine's services still import handlers and tools, and nothing checks the rule. Source: vscimpb176_aksm-services-not-importing-handlers-tools (planned) |
| **A-15** | R-16 (RISK > RISK-DEPS); R-15 (RISK > RISK-DEPS) | **apply** | R-16 names format version 10 and the quest management (the standard's phases 1 and 2) as part of the extension's remaining features, both open and both after the workspace layout cutover; R-15 names the cutover as what they wait for. Source: S22 § 5, § 7; planned in vscode_extension `01_aifmt-1` … `-5`, `02_aifmt-1`. |
| **AB-16** | R-20 (RISK > RISK-DEPS) | **apply** | R-20's state says the fleet's todo for the tac server describes a server on the VPN only, run from a clone, and is rewritten against CA.27 … CA.30, N-28 and N-29 (accounts, the relay's public address behind a reverse proxy, installed from the binaries repository); a reverse proxy with certificates exists on the always-on machine. How the server is deployed beyond that is a Phase 2 detail. Source: al_the_bear `14_loose_wslayout-6_akto-coordination-server-on-bigbeast` (planned, blocked), `tsmfleet3`, `tsmfleet9` (completed). |
| **AB-17** | new risk (RISK > RISK-RISKS) | **apply** | A new risk: one machine's VPN fails for hours unnoticed, so its runtimes cannot reach the backend and their queues stop (CA.32); what the user is shown meanwhile and the recovery matter in daily use. R-13's trigger adds a machine that was offline for weeks and meets newer formats when it returns. Source: al_the_bear `vpnhang1` (2026-11-14); `repo_structure_new.md` § 2. |
| **AB-19** | new risk (RISK > RISK-RISKS) | **apply** | A new risk: a working tree of an execution lengthens every path by the tree's prefix, and Windows builds of this workspace are at the path-length limit already; a line under CW.3 says the Blueprint keeps the place and the names of the trees short or settable per machine. Source: al_the_bear `legws1_aktp-legiondary01-root-to-c-ws` (the product owner's decision of 2026-11-20). |
| **AB-27** | R-15 (RISK > RISK-DEPS) | **apply** | R-15's state says: the resolver and the layered configuration are built in the extension, the migration tool and the new fleet skills are written and tested; the cutover and what follows it are open. It names the order: cutover, then format version 10, then quest management, then the coordination repository and the tac server. Source: al_the_bear `workspace_layout_plan.md` (2026-11-19), `12a_wslayout-2`; S22 § 5. |
| **WW-22** | DEL, last paragraph "The todos" (DEL) | **apply** | Add to `DEL`: the quest `webwork` waits for two messages, the map WR-1 … WR-7 to the covering todos when the todos are filed and a second one when the runtime is complete; its wave 1b2 starts after its wave-1b1 release, assumes the runtime finished and gives no date; its specifications D13 (amended) and D40 are written against the runtime protocol specification and `tac/2.0`, so webwork needs those two documents before the code. The first message also carries what this round tells webwork (WW-10, WW-14, WW-16, the names of triage § 1.2). Source: `webwork_wave1_plan.md`; the notes on webwork todos `12a_woneb1` … `14_woneb2`; D-42. |
| **TF-1** | DEL, last paragraph "The todos" (DEL) | **apply** | Add to `DEL`, beside the line of WW-22: the quest `tom_forge` waits for a message when the todos are filed, since part two of its quest workbench specification is written from this specification: the runtime client's package and place (CL.3), Telegram deferred (L-9), the bearer token of the MCP server (CT.12), host tools not reachable through it (TF-3), its views embedding the components (CU.3, TF-8), and its waiting entries re-pointed (the list of TF-14). Source: `spec_quest_workbench.tom_forge.md` part two; tom_forge todo `qavs_wwworkbench-1`; D-42. |
| **TF-14** | DEL, last paragraph "The todos" (DEL) | **drop** | covered by TF-1: `DEL` already says that the waiting entries of other quests follow the new todo set, and TF-1's line names the re-pointing; the list of entries (`ai_runtime/ww_d_workbench-9` … `ww_f_collab-3`, in webwork also `ww_c_collab-3`, `ww_f_collab-2`, `12b_woneb1…3`, `tac_webwork-6`) is input of the todo filing, not text of the Project Idea. |

Questions this part writes: QT-20 (§ 3).

**Also reaches this part** (ruled in the owning part's row; read that row and the finding):

| Finding | Items of this part | Owner | Ruling there |
| --- | --- | --- | --- |
| AN-1 | D-20 | `p1s1r4-4` | apply |
| AN-2 | new risk (AN-7) | `p1s1r4-4` | apply |
| AN-5 | D-55, R-10 | `p1s1r4-4` | ask QT-1 |
| AN-6 | D-20 | `p1s1r4-3` | apply |
| AN-8 | D-34, R-15, R-16, DEL steps 1 and 2 | `p1s1r4-8` | apply |
| AN-15 | D-2 | `p1s1r4-5` | apply |
| AN-17 | X-11 | `p1s1r4-6` | apply |
| AN-18 | R-9, R-11 | `p1s1r4-8` | ask QT-19 |
| AN-19 | R-22 | `p1s1r4-7` | ask QT-4 |
| AN-20 | D-27, D-51, D-52, X-3, X-12, X-14, R-8, R-22 | `p1s1r4-3` | ask QT-2 |
| AN-21 | D-23 | `p1s1r4-6` | ask QT-4 |
| AN-22 | D-3, D-50, R-12, R-24 | `p1s1r4-5` | ask QT-3 |
| AN-23 | D-10 | `p1s1r4-4` | ask QT-3 |
| AN-25 | D-52, X-12 | `p1s1r4-3` | ask QT-2 |
| AN-26 | D-51, X-14, R-8 | `p1s1r4-5` | ask QT-4 |
| AN-27 | D-3, D-10, D-27, D-50, D-51, D-52, a new D-<n>, X-3, X-12, X-14, R-8, R-12, R-22, R-24, DEL (which track builds it) | `p1s1r4-9` | apply |
| AN-29 | X-11, D-47 | `p1s1r4-6` | apply |
| AN-30 | X-11 | `p1s1r4-6` | ask QT-5 |
| AN-31 | D-18 | `p1s1r4-7` | ask QT-6 |
| AN-32 | R-3, R-20, D-24, D-25, D-47, D-53, D-54 | `p1s1r4-7` | apply |
| AN-34 | R-19 | `p1s1r4-2` | apply |
| AN-37 | DEL | `p1s1r4-2` | apply |
| AN-38 | X-3, D-27, R-3 | `p1s1r4-7` | apply |
| AN-40 | D-59, D-60, X-15 | `p1s1r4-6` | apply |
| AN-41 | R-18 | `p1s1r4-8` | ask QT-8 |
| AN-43 | D-19 | `p1s1r4-4` | apply |
| AN-45 | D-60 | `p1s1r4-11` | apply |
| IC-1 | D-55 | `p1s1r4-6` | ask QT-13 |
| IC-9 | R-13 | `p1s1r4-3` | apply |
| IC-16 | D-13 | `p1s1r4-6` | ask QT-17 |
| IC-19 | D-23 | `p1s1r4-7` | ask QT-4 |
| IC-28 | R-19 | `p1s1r4-5` | ask QT-7 |
| IC-32 | R-18 | `p1s1r4-2` | apply |
| IC-33 | X-13, X-14, the heading "Risks the first question round added", the DEC lead-in | `p1s1r4-2` | apply |
| IC-34 | D-2 | `p1s1r4-9` | apply |
| GA-1 | D-51, D-52, DEL | `p1s1r4-3` | ask QT-2 |
| GA-20 | DEL, R-23 | `p1s1r4-9` | apply |
| GA-30 | D-40, D-41, R-1, DEL | `p1s1r4-2` | ask QT-18 |
| ST-1 | DEC (D-61 on, new heading) | `p1s1r4-2` | apply |
| ST-3 | the lead-in of RISK, X-3 | `p1s1r4-6` | apply |
| ST-7 | D-7, D-15, D-17, D-25, D-48, D-52, D-59, X-12, R-12, R-24 | `p1s1r4-11` | ask QT-21 |
| ST-11 | the lead-in of DEC | `p1s1r4-2` | apply |
| ST-13 | DEL | `p1s1r4-11` | ask QT-21 |
| ST-15 | D-36, D-49, D-58 | `p1s1r4-11` | ask QT-21 |
| ID-2 | D-55 | `p1s1r4-6` | ask QT-13 |
| ID-9 | D-50, R-12, R-24 | `p1s1r4-5` | ask QT-3 |
| VX-PQ24 | D-20 | `p1s1r4-4` | apply |
| VX-2 | D-20 | `p1s1r4-4` | apply |
| VX-27 | D-20 | `p1s1r4-3` | apply |
| VX-28 | DEL "The order of building" (names the todo; stays) | `p1s1r4-3` | apply |
| VX-41 | D-7 | `p1s1r4-3` | apply |
| VX-43 | D-34 | `p1s1r4-8` | ask QT-9 |
| VX-48 | R-19 | `p1s1r4-5` | ask QT-7 |
| A-14 | R-13 | `p1s1r4-4` | ask QT-12 |
| Q-3 | D-34 | `p1s1r4-8` | ask QT-9 |
| Q-6 | D-34 | `p1s1r4-8` | ask QT-10 |
| AB-8 | R-15 | `p1s1r4-8` | apply |
| AB-11 | R-15 | `p1s1r4-8` | apply |
| AB-15 | R-20 | `p1s1r4-6` | apply |
| AB-18 | R-20 | `p1s1r4-5` | apply |
| AB-20 | D-56 | `p1s1r4-9` | apply |
| WW-1 | R-19 | `p1s1r4-5` | ask QT-7 |
| WW-10 | DEL (the message of WW-22 tells webwork that the option is the runtime's, not device state) | `p1s1r4-3` | apply |
| WW-11 | D-16 | `p1s1r4-3` | ask QT-22 |
| WW-14 | DEL (the message of WW-22 tells webwork before its D40 is written) | `p1s1r4-4` | apply |
| WW-16 | DEL (the message of WW-22 names `<team>` as the form) | `p1s1r4-7` | drop |
| WW-20 | R-18 | `p1s1r4-2` | apply |
| TF-3 | DEL (the message of TF-1) | `p1s1r4-4` | apply |
| TF-8 | DEL (the message of TF-1) | `p1s1r4-5` | ask QT-7 |
| TF-9 | R-18 | `p1s1r4-3` | ask QT-23 |
| TF-12 | new R-<n> in RISK-DEPS | `p1s1r4-9` | apply |
| WRS | D-27, DEL (the messages of WW-22 and TF-1 carry the new names) | `p1s1r4-3` | ask QT-2 |

### 2.10 `p1s1r4-11` — `GLO` and the whole document

21 findings: 8 apply, 11 ask, 2 drop.

| Finding | Items (section chain) | Ruling | What the text is to say, the question, or the reason |
| --- | --- | --- | --- |
| **AN-3** | GLO ask; GLO run; GLO execution | **apply** | GLO ask gets "the run that asked waits until the ask is settled"; GLO run says that a run waits while an ask of it is open; GLO execution says that an execution waiting for an answer is still the same execution. Whether it keeps its leases is not written (QT-1). Source: PQ-24 (b); triage § 1.1 |
| **AN-28** | GLO team; GLO personal team; GLO backend | **apply** | GLO team is not bound to a tac server; GLO personal team covers the local backend (one machine) and the GitHub backend (the user's machines that share the coordination repository); backend stays. Member, owner, invitation, team token, open / strict and account keep their definitions for the tac server, with a line that what holds on the GitHub backend is open (QT-6). Source: PQ-29; triage § 1.3 |
| **AN-33** | GLO application; GLO host; GLO user | **apply** | GLO application drops "the review application"; GLO host drops its last sentence; GLO user says "a person using an application". Source: PQ-30; triage § 1.4 |
| **AN-44** | GLO device; GLO pairing | **apply** | GLO pairing adds "used for devices only" and says "the server a device reaches from the internet (which program that is, is open)". CS.9 says once per runtime installation (one per machine and user, CR.40); the approval for a runtime behind the web runtime service is part of QT-2. U-13 and R-17 stand. Source: PQ-32 (a); CR.40; triage § 1.2 |
| **AN-45** | GLO, a new table "Further terms of this document" | **apply** | The table gets the terms of PQ-33, each with the wording of its item. Three follow the rulings: "relay" is the tac server's relay only (§ 1.2); "classic quest" and "repository quest" with the forms "single-quest repository" and "multi-quest repository" (§ 1.6), "personal repository" with the wording of CQ.2 until QT-9; "notification" and "command" as the two kinds between runtimes of CA.19, their further senses with QT-19. S21, D-60's list and the SRC row of S21 get the same entries. Source: PQ-33 (a); triage § 1.2, § 1.6 |
| **AN-46** | GLO, the table "Further terms of this document" | **apply** | The table also gets the terms the document uses in a fixed sense and an item defines, each with the wording of that item (among them the _ai state, coordination repository, always-on machine, subject, step boundary, pre-prompt, follow-up, timed request, ask envelope, reverse request, access key, review copy, base, web runtime service, web runtime client SDK). A term with several senses (reminder, thread and turn, machine against device, main branch against trunk, reconcile / sync / converge, member id against user id) goes to QT-19; "integration lease" waits for QT-13; "first version" against "first delivery" for QT-20. Source: PQ-33 (a) |
| **GA-19** | SCO (a register of the first version) | **ask** QT-21 (written by this part) | Which items marked "comes late", "an option", "evaluated" or "after" are inside the first version. Until answered every such item keeps its wording and nothing is moved to SCO > SCO-LATER. |
| **GA-23** | the whole document (capability groups against U-*, V-*, P-*) | **ask** QT-21 (written by this part) | Whether capabilities are traced to the user groups, vision statements and problems they serve. Until answered no "serves" line is written. |
| **ST-4** | - | **drop** | nothing to change (confirms): ids are never renumbered and keep their meaning (round_instructions § Ids), an item stands where its topic is, and no id is defined twice or used undefined |
| **ST-5** | the whole document (sections against capability areas) | **ask** QT-21 (written by this part) | Whether the sections are regrouped to match the thirteen capability areas (RT split by area, TAC-GROUPS under TAC-COORD). Until answered the sections stay and ABOUT > ABOUT-READ says which sections hold which area. |
| **ST-6** | NFR (N-1 … N-31 that restate capabilities) | **ask** QT-21 (written by this part) | Whether NFR keeps only qualities with a measure and refers to the capability items for the rest. Until answered each restating N item stays and is made to agree in wording with the item it restates. |
| **ST-7** | the whole document (statements made in several places) | **ask** QT-21 (written by this part) | Whether a statement is made in one item and only referred to elsewhere. Until answered the copies stay, and each part makes its copies agree with the cross-cutting rulings of triage § 1. |
| **ST-9** | GLO | **ask** QT-19 (written by this part) | Words used in several senses: notification, command, strict, member, service and server, process, reminder, and with them conversation, item, relay, session. Until answered each part writes the word with its qualifier where the sense is not plain (for example "operating-system process", "message kind command") and GLO is not changed. |
| **ST-10** | GLO run; GLO quest; GLO host; GLO worktree mode | **apply** | The entry "run" says what a run is without pointing to the extension, with what CR.8 and CR.9 state (a run follows at most one process; the run `default` follows none); "quest" loses the comparison; "host" loses the sentence on the review application. The second name "change-branch mode" is an agreed term (S21) and goes with QT-19, unchanged until answered. Source: CR.8, CR.9; PQ-33 (a) (entries with the wording of their items); PQ-30 (triage § 1.4). |
| **ST-12** | - | **drop** | nothing to change (confirms): ids are never renumbered (round_instructions § Ids) and ABOUT > ABOUT-READ explains the ranges; new entries of this round take the next free number of their area |
| **ST-13** | NFR > NFR-TOPO; NFR > NFR-TOPO-FLOWS; NFR > NFR-GEN | **ask** QT-21 (written by this part) | Whether topologies and flows get a section of their own before NFR and the generation units move to DEL. Until answered the three subsections stay under NFR. |
| **ST-15** | the whole document (long table cells) | **ask** QT-21 (written by this part) | Whether statements inside long table cells (T8, the GitHub row of CA.26, GLO visible, GLO resource name, D-36, D-49, D-58) get items of their own so they can be cited. Until answered the cells stay, and the cells that triage § 1.2, § 1.3 and § 1.5 change are reworded there. |
| **ST-16** | the whole document (items with several topics) | **ask** QT-21 (written by this part) | Whether items that hold several provisions (CA.39, CW.5, CQ.6, CR.5, CI.10, CA.30) are split into items with ids of their own. Until answered no item is split; CA.39 loses its history under ST-3, and CW.5 and CQ.6 wait for QT-13 and QT-10. |
| **ST-17** | the whole document (the lists around the PQ blocks) | **apply** | When the ten question blocks are removed, the lists they stood in are closed up, and the blank lines that earlier blocks left inside lists are removed (before CR.13, CR.14, CP.9, CP.30, CI.11, CK.9, CK.10, CW.25, CW.26, X-8, X-13), so every list is one list. Source: round_instructions § Rules for the text (the question blocks stay until `p1s1r4-11` removes them); a correction with only one reasonable reading. |
| **ID-1** | SCO (a register "what the first version contains") | **ask** QT-21 (written by this part) | One register of what the first version contains (first version; first version, late; option; later) in place of the scattered adverbs. Until answered the adverbs stay in their items. |
| **ID-10** | the whole document (a "serves" line per capability group) | **ask** QT-21 (written by this part) | A line per capability group naming the user groups, vision statements and problems it serves, and per user group the groups that serve it. Until answered no such line is written. |

Questions this part writes: QT-19, QT-21 (§ 3).

**Also reaches this part** (ruled in the owning part's row; read that row and the finding):

| Finding | Items of this part | Owner | Ruling there |
| --- | --- | --- | --- |
| AN-5 | GLO strict mode | `p1s1r4-4` | ask QT-1 |
| AN-8 | GLO quest, classic quest, repository quest, personal repository | `p1s1r4-8` | apply |
| AN-9 | GLO session | `p1s1r4-3` | apply |
| AN-11 | GLO session, transport, conversation | `p1s1r4-5` | ask QT-19 |
| AN-15 | GLO client SDK | `p1s1r4-5` | apply |
| AN-17 | GLO holder | `p1s1r4-6` | apply |
| AN-20 | GLO host, server, the words-not-used table, a line for "service" | `p1s1r4-3` | ask QT-2 |
| AN-24 | GLO host | `p1s1r4-3` | ask QT-2 |
| AN-40 | GLO resource, resource name, overlap; S21 (terminology) | `p1s1r4-6` | apply |
| IC-1 | GLO exclusive lease, worktree mode, overlap | `p1s1r4-6` | ask QT-13 |
| IC-7 | GLO fencing token | `p1s1r4-6` | ask QT-13 |
| IC-11 | GLO runtime | `p1s1r4-7` | ask QT-15 |
| IC-13 | GLO host | `p1s1r4-2` | apply |
| IC-15 | GLO holder | `p1s1r4-6` | apply |
| IC-26 | GLO message kind | `p1s1r4-7` | apply |
| IC-29 | GLO queue item | `p1s1r4-4` | ask QT-19 |
| GA-4 | GLO run | `p1s1r4-3` | apply |
| GA-14 | GLO todo offer, GLO visible | `p1s1r4-7` | apply |
| GA-22 | GLO coordinator | `p1s1r4-2` | apply |
| ST-1 | the ten PQ blocks | `p1s1r4-2` | apply |
| ST-3 | GLO team runtimes | `p1s1r4-6` | apply |
| ID-2 | GLO exclusive lease, overlap, worktree mode | `p1s1r4-6` | ask QT-13 |
| VX-19 | GLO (session) | `p1s1r4-3` | apply |
| VX-20 | GLO (session) | `p1s1r4-3` | apply |
| VX-46 | GLO (quest) | `p1s1r4-8` | apply |
| A-4 | GLO trail | `p1s1r4-8` | ask QT-9 |
| Q-1 | GLO quest, classic quest, repository quest | `p1s1r4-8` | apply |
| Q-3 | GLO personal repository | `p1s1r4-8` | ask QT-9 |
| AB-5 | GLO integration step | `p1s1r4-3` | apply |
| WW-2 | GLO review round / round folder ("in version control") | `p1s1r4-7` | apply |
| WW-3 | GLO review set (check only, no change) | `p1s1r4-7` | apply |
| WRS | GLO | `p1s1r4-3` | ask QT-2 |

### 2.11 Dropped

The findings ruled **drop**, each also in its part's table above:

| Finding | Part | Reason |
| --- | --- | --- |
| AN-13 | `p1s1r4-5` | covered by triage § 1.7 ("runtimes and command-line programs of ours", applied with AN-12) |
| GA-26 | `p1s1r4-7` | Phase 2 detail (editing, deleting, search, attachments and who may create a conversation are worked out in the Solution Blueprint; no source states them and nothing in the items is wrong) |
| ST-4 | `p1s1r4-11` | nothing to change (confirms): ids are never renumbered and keep their meaning (round_instructions § Ids), an item stands where its topic is, and no id is defined twice or used undefined |
| ST-12 | `p1s1r4-11` | nothing to change (confirms): ids are never renumbered (round_instructions § Ids) and ABOUT > ABOUT-READ explains the ranges; new entries of this round take the next free number of their area |
| VX-21 | `p1s1r4-3` | nothing to change (confirms) |
| VX-54 | `p1s1r4-2` | nothing to change (confirms): Telegram stays deferred (L-9, D-6, X-10); an ask reaches a person away from the host through tac (CP.18) |
| A-12 | `p1s1r4-3` | nothing to change (confirms) |
| Q-8 | `p1s1r4-8` | nothing to change (confirms) |
| AB-21 | `p1s1r4-8` | covered by Q-12 (nothing else to change, confirms CW.1) |
| AB-22 | `p1s1r4-8` | covered by Q-7 (remove deletes nothing in git, S22 QM-8); retiring a quest into the archive repository is the workspace's rule, not this product |
| AB-25 | `p1s1r4-3` | covered by A-13 (the machine-wide state lies outside `_ai`, its place for the Blueprint) and A-6 (the answers move into the per-host journal) |
| AB-26 | `p1s1r4-3` | nothing to change (confirms); the git settings of a quest's window are the VS Code host's, and CR.34 already answers which repository a file belongs to |
| WW-16 | `p1s1r4-7` | nothing to change (confirms): CM.12 has `msg:tac/<team>/<messageId>`; the two older webwork todos that write `<server-group>` are corrected by the message of WW-22. |
| TF-14 | `p1s1r4-10` | covered by TF-1: `DEL` already says that the waiting entries of other quests follow the new todo set, and TF-1's line names the re-pointing; the list of entries (`ai_runtime/ww_d_workbench-9` … `ww_f_collab-3`, in webwork also `ww_c_collab-3`, `ww_f_collab-2`, `12b_woneb1…3`, `tac_webwork-6`) is input of the todo filing, not text of the Project Idea. |

## 3 Questions planned

24 questions settle the 90 findings ruled **ask**. Each is written once, by the part named, self-contained as `round_instructions.md` § Questions asks, at the item named, and gets the next free id from PQ-34 on when it is appended to `new_questions.md`. The other parts that a question concerns do not ask it again; they write what their row says the text says until it is answered. `p1s1r4-11` may still merge questions of one topic (QT-2, QT-3 and QT-4 all follow from PQ-28; QT-5 and QT-6 from PQ-29; QT-9, QT-10 and QT-11 from the standard for quests).

| Key | Topic | Written by | At | Findings behind it | Improvement idea as the recommended option |
| --- | --- | --- | --- | --- | --- |
| QT-1 | While a run waits for an ask: are its leases kept, released or claimed again; and does a chat send in another session of that run still go out (as in the extension today) or wait behind the ask | `p1s1r4-4` | CP.21 (`RT > RT-ASKS`) | AN-5, VX-17 | — |
| QT-2 | What the web runtime service is: the runtime host server under a new name, or a front to runtimes that exist anyway; how long the runtime behind it lives; whose runtime it is and where its files, settings and secrets are; who operates it; whether it also serves a web application's files | `p1s1r4-3` | CR.46 (`RT > RT-INSTALL`) | AN-20, AN-24, AN-25, GA-1, GA-2, WRS | — |
| QT-3 | The web runtime client SDK: a third SDK or the runtime client SDK with a second binding; which languages; what crosses HTTP (events, asks, the host's tools); the same convenience layer as the runtime client SDK | `p1s1r4-5` | CL.1 (`CLI > CLI-PACK`) | AN-22, AN-23, ID-9 | ID-9 (TypeScript and JavaScript as one client SDK) as the recommended option of its sub-point |
| QT-4 | Phones and tablets: in the first version or not; which program is reachable from the internet and holds the device keys; whether tac's relay carries the runtime's protocol; end-to-end encryption in the first version or later; pairing as a procedure; how a person who is away is reached (push services) | `p1s1r4-7` | CI.18 (`TAC > TAC-CRYPT`) | AN-19, AN-21, AN-26, IC-19, IC-25, GA-16, GA-17, WW-13 | — |
| QT-5 | What a team on the GitHub backend has, per capability (commands between runtimes, asks to other people, messaging, review exchange, reminders, todo offers, the integration queue); who computes presence and staleness without a service; GitHub only or any git server | `p1s1r4-6` | CA.26 (`TAC > TAC-BACKENDS`) | AN-30, IC-8, ID-5 | ID-5 (one capability table per backend) as the recommended form of the answer |
| QT-6 | Who is a member and an owner of a team on the GitHub backend, and whether invitation, team token and the owner-only rules exist there or are agreements | `p1s1r4-7` | CI.5 (`TAC > TAC-PEOPLE`) | AN-31 | — |
| QT-7 | Where the review component is built (the Review group of `tom_ai_runtime_ui`, the `tom_forge` quest, the extension's shared web page behind a host), and what becomes of the Flutter view packages that exist (`tom_agentic_ui`, `tom_ai_trail_ui`, `tom_todo_ui`) and of Tom Forge's own view packages beside `tom_ai_runtime_ui` | `p1s1r4-5` | CU.9 (`CLI > CLI-UI`) | IC-28, VX-48, WW-1, WW-19, TF-8 | — |
| QT-8 | The grammar of resource names: a name without a prefix from existing todos; a document of a quest in a multi-quest repository (the name has no branch); whether secrets, messages, resources and the addresses of CW.18 are written as one family of notations | `p1s1r4-6` | CA.10 (`TAC > TAC-COORD`) | AN-41, AN-42, ID-4, Q-14 | ID-4 (one grammar for everything that is addressed) as the recommended option |
| QT-9 | Personal files: per-host files in the quest, tracked (the standard S22), or one personal repository per user (CQ.2, CQ.3, D-34); what happens to personal notes | `p1s1r4-8` | CQ.2 (`PAR > PAR-QUESTS`) | VX-43, A-4, Q-3, Q-4 | — |
| QT-10 | What of CQ.6 remains on top of the three quest types: a branch per member with a review of conflicts, the second repository with encrypted development credentials, the secret scan, member identity and access; and the trial migration of CQ.7 | `p1s1r4-8` | CQ.6 (`PAR > PAR-QUESTS`) | IC-6, Q-6 | — |
| QT-11 | Whether the quest operations are commands of the runtime (every host gets them) or the VS Code host's view only; whether a quest inside a project's repository is wanted; working copies on a server for a web build | `p1s1r4-8` | CQ.7 (`PAR > PAR-QUESTS`) | Q-2, Q-11, TF-10 | — |
| QT-12 | When a format migration runs: on each host's first start after the update without a confirmation, recorded in a versioned file (S22), or once per machine under a lock and only when the user confirmed (CP.29, CP.32) | `p1s1r4-4` | CP.29 (`RT > RT-VERSIONS`) | A-14 | — |
| QT-13 | The lease rules: an integration lease that coexists with shared leases, so that the integration step of worktree mode can happen at all; where and by whom the fencing token is checked at a push; what happens when the integration step fails; what the integration queue is on each backend | `p1s1r4-6` | CA.11 (`TAC > TAC-COORD`) | IC-1, IC-7, GA-9, ID-2, AB-14 | ID-2 (the lease rules as one matrix) as the recommended option |
| QT-14 | One permission and credential model: what remote control covers; whether the host's setting also governs the published MCP endpoint and an endpoint a host serves through its runtime; which credential a tac client presents (access key, team token, device key, bearer token); a record of what people did to runs that are not theirs | `p1s1r4-7` | CI.13 (`TAC > TAC-PEOPLE`) | IC-17, IC-18, GA-12, GA-13, ID-3, ID-8, WW-8 | ID-3 (a table of credentials) and ID-8 (a record of what people did to others' runs) as recommended options |
| QT-15 | A runtime without a quest (Webwork's, trc's): in which team or teams it registers, what it may do there, under which name it appears, and whether it has memory | `p1s1r4-7` | CI.2 (`TAC > TAC-PEOPLE`) | IC-11, AB-2, WW-7 | — |
| QT-16 | Two hosts on one quest: one runtime with two runtime clients, or two runtimes; which of them executes a run, takes a command and owns a session; at most one runtime per quest inside one host; whether a host's tools can be called for another host | `p1s1r4-3` | CR.6 (`RT > RT-HOLDS`) | IC-12, GA-6, TF-2, TF-6 | — |
| QT-17 | Coordination "off by default" against the local tac service through which everything is routed: what the default installation runs, what "off" switches off, what the local tac service is and does when the tac server cannot be reached | `p1s1r4-6` | CA.31 (`TAC > TAC-BACKENDS`) | IC-16, GA-5, WW-6 | — |
| QT-18 | Features of the extension — the runtime's or the VS Code host's own: the quest refresh, the "window" level of the guideline choices, the `prerequisites.yaml` format, a prompt stored for after a restart; and what of the split stays in the extension | `p1s1r4-3` | CR.5 (`RT > RT-HOLDS`) | GA-30, VX-23, VX-37, VX-51, VX-57 | — |
| QT-19 | Words with several senses: "conversation" for the exchange with a model and for messaging (proposal: "chat" for the model side), "notification", "command", "item", "reminder", "session" for another writer | `p1s1r4-11` | `GLO` | AN-11, AN-18, IC-29, ST-9 | — |
| QT-20 | Delivery: a first usable state and an acceptance inside "one go" | `p1s1r4-10` | `DEL` | GA-21, ID-7 | ID-7 (a first usable state inside "one go") as the recommended option |
| QT-21 | The document's structure in the next round: one register of what the first version contains, every capability traced to the user group it serves, sections against capability areas, `NFR` items that repeat capabilities, topologies and generation units out of `NFR`, long cells and items split | `p1s1r4-11` | `ABOUT` | GA-19, GA-23, ST-5, ST-6, ST-7, ST-13, ST-15, ST-16, ID-1, ID-10 | ID-1 (one register "what the first version contains") and ID-10 (trace every capability to whom it serves) as recommended options |
| QT-22 | The runtime outside VS Code: Node bundled with the runtime installation or found on the machine, and its lowest version; whether the Agent-SDK-only mode (CR.29, D-16) is still needed now that Webwork plans no use of it | `p1s1r4-3` | CR.40 (`RT > RT-INSTALL`) | WW-11, TF-4 | — |
| QT-23 | Who writes and commits `_ai` files besides the runtime: Dart code that writes the formats today (`tom_todo_model`, the journal, the live trail) allowed with a write rule and shared fixtures, or everything through the runtime; and who commits and pushes what the runtime writes in `_ai` and in a quest's repository | `p1s1r4-3` | CR.1 (`RT > RT-HOLDS`) | AB-10, TF-9 | — |
| QT-24 | Messaging for an application through its runtime: where the conversation cache and the outbox live (the runtime or the host), so an application can read and write while tac cannot be reached | `p1s1r4-7` | CM.7 (`TAC > TAC-CONV`) | WW-5 | — |

**Improvement ideas.** Proposed as a question (with the idea as the recommended option, or among the topics of the question): ID-1, ID-2, ID-3, ID-4, ID-5, ID-7, ID-8, ID-9, ID-10. Otherwise: ID-6 (apply).

## 4 Sources to add to `SRC` (by `p1s1r4-2`)

The other parts cite these ids; only `p1s1r4-2` writes the rows.

| Id | Path | Date | What it is |
| --- | --- | --- | --- |
| **S22** | `_ai/quests/al_the_bear/ai_format_migration.md` | 2026-11-20 ("Round 2: everything is decided") | The `_ai` folder and the quest folder in format version 10, the four classes of files, the three quest types with the register `_ai/quests.yaml`, quest management, the migration in three phases. Decided, not built. The product owner named it the standard (answer to PQ-24). Its own decision ids (`CQ-n`, `AC-n`, `QM-n`, `QJ-1`, `MG-1`) collide with ids of this document: cite it as "S22 § n" or "S22 AC-n". Standing: current; where it differs from S2 § 3.7 and S12, it wins, except for what QT-9 and QT-10 ask. |
| **S23** | `_ai/quests/vscode_extension/todos.vscode_extension.todo.yaml`, `todos-archived.vscode_extension.todo.yaml` (the todos completed 2026-11-10 … 2026-11-20), `progress.vscode_extension.md` (the entries of 2026-11-19 and 2026-11-20) | state of 2026-11-20 | What the extension's engine does today and what is planned for it, cited by todo id (`vscimpb*`, `qrun*`, `gsel*`, `*_aifmt-*`, `ccparity_*`). A todo that is done is built behaviour; one not started is a plan. |
| **S24** | `_ai/quests/vscode_extension/role_and_guideline_selector.vscode_extension.md` | 2026-11-20 | The design of roles and aspect guidelines per todo, item, run and window (R-1 … R-4, A-1 … A-5, L-1 … L-8). |
| **S25** | `_ai/quests/webwork/todos.webwork.todo.yaml` (the groups `12a_woneb*`, `13_woneb*`, `14_woneb*`, `qavs_*`), `webwork_wave1_plan.md`, `md_browser_probe.webwork.md` | state of 2026-11-20 | What Webwork plans on the runtime and tac beyond S3 and S13, cited by todo id and by Webwork's decision ids (DPPHONE-*, DPMESSAGING-*). |
| **S26** | `_ai/quests/tom_forge/todos.tom_forge.todo.yaml` (the groups `qavs_*`, `later23`, `later25`, `05b_woneb*`, `wwkit*`), `decisions.tom_forge.md`, `tom_forge_componentization.md` | state of 2026-11-20 | What Tom Forge plans on the runtime beyond S14: hosting runtime processes, its view packages, the review component, the web runtime server for repository quests. |
| **S27** | `_ai/quests/al_the_bear/todos.al_the_bear.todo.yaml` (the `*_aifmt-*` and `*_wslayout-*` todos), `workspace_layout_plan.md`; at the fleet root `_agent_guidelines/workspace_layout.md`, `workspace_layout_multi.md`, `repos.yaml`, `repo_structure_new.md`, `repo_skills_new.md` | state of 2026-11-20 | The workspace layout as it is being built (root and workspace markers, the places that can be changed, independent clones, the fleet skills after the cutover), beyond S12. |

Also for `p1s1r4-2`:

- **S17** (the extension): its row names the documents the findings cite, `doc/user_guide.md`, `doc/llm_tools.md`, `doc/multi_transport_prompt_queue_revised.md`, `doc/md_browser_page_protocol.md`.
- **S2** § 3.7 and **S12**: their standing says "outdated where S22 differs" (A-1, AN-8).
- **S14**: part two of the quest workbench specification is a placeholder that waits for this specification (TF-1).
- **Not sources:** the four input files and `triage.md` of this round are working papers; an item cites the source a finding names, never the finding.
- The sentence under the table ("Every path above resolves in the workspace on 2026-11-19") gets the date of the check `p1s1r4-2` makes.

## 5 The count check

Made mechanically on 2026-11-20: the finding ids were listed from the headings and table rows of each input file and compared with the rows of the tables in § 2 (first column, bold id). Every id of an input file has exactly one row; no row has an id the input files do not have, except the two rows for the unnumbered sections.

| Input file | Finding ids in the file | Rows in § 2 | apply | ask | drop | Missing | Twice |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `consistency_read.md` | 138 | 138 | 77 | 57 | 4 | none | none |
| `inputs_vscode_extension.md` | 57 | 57 | 48 | 7 | 2 | none | none |
| `inputs_al_the_bear.md` | 56 | 56 | 39 | 11 | 6 | none | none |
| `inputs_webwork_tom_forge.md` | 37 | 37 | 21 | 14 | 2 | none | none |
| **Total** | 288 | 288 | | | | | |

Rows without a numbered finding: VX-PQ24, WRS (the section "Specifically for PQ-24" of `inputs_vscode_extension.md`, and the closing section on the web runtime service of `inputs_webwork_tom_forge.md`). All rows: 290 — 186 apply, 90 ask, 14 drop.

`iteration_split.md` counts 276 findings; the files hold 288 numbered ones (IC 34, AN 46, GA 30, ST 18, ID 10; VX 57; A 15, Q 14, AB 27; WW 22, TF 15).

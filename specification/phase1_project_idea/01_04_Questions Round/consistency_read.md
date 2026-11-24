# Consistency read — Project Idea "Tom AI Runtime"

**Read:** `../project_idea.ai_runtime.md` (2,736 lines, all of them), with the answers of this round in `answers.md`.
**Reader's position:** an independent reader who has to write the Solution Blueprint from the document.
**Date:** 2026-11-20.

The findings are numbered per category: `IC` inconsistencies, `AN` consequences of the answers `PQ-24` … `PQ-33` (grouped by question), `GA` gaps, `ST` structure and readability, `ID` improvement ideas. Places are given as item ids with their section-id chain. Where the document does not say something, the finding says so and proposes a question; nothing about the product is assumed.

| Category | Count |
| --- | --- |
| Inconsistencies (`IC`) | 34 |
| Answer consequences (`AN`) | 46 |
| Gaps (`GA`) | 30 |
| Structure and readability (`ST`) | 18 |
| Improvement ideas (`ID`) | 10 |

---

## 1 Inconsistencies

### Leases, integration and parallel work

**IC-1 — The exclusive lease for the integration step can never be given while anyone else works in the repository.**
- `GLO`, overlap: "tac gives no exclusive lease on a resource that overlaps a leased one, and no lease at all on one that overlaps an exclusively leased one." The same in `TAC > TAC-COORD`, CA.11.
- `PAR > PAR-APPROACH`, CW.5: in worktree mode an execution "holds a **shared lease** on what it works on … and takes an **exclusive lease** on the repository only for the integration step."
- `NFR > NFR-TOPO > NFR-TOPO-FLOWS`, F8: "Each execution works in its own working tree on its own branch, holding a shared lease; when its todo is done it takes the repository's exclusive lease for the integration step …".
- Taken together: two executions each hold a shared lease on (a part of) the repository. The whole repository overlaps every part of it, both parts are leased, so by CA.11 neither execution can get the exclusive lease on the repository. F8, the flow worktree mode exists for, cannot happen. CA.42 states the rule only for exclusive leases ("while the whole repository is exclusively leased, no part of it can be leased …") and so reads differently from CA.11 again.
- **Proposal:** state the lease rules once as a matrix (see `ID-2`) with a third kind, the **integration lease** (CA.36 already says "integration leases"): it is exclusive only against other integration leases and against exclusive leases on an overlapping resource, and coexists with shared leases. Then correct the glossary entries "exclusive lease", "worktree mode" and "overlap", CA.11, CA.42, CW.5, F8 and D-55 to it.

**IC-2 — Who carries out the integration step: tac, or the runtime of the execution.**
- `PAR > PAR-APPROACH`, CW.6: "Every repository has an **integration queue**, kept by tac. It is serial and mechanical: it runs the checks the repository declares (analysis, the tests the change affects) and lands the execution's commits or rejects them back to it."
- CW.5: the integration step is "rebase the execution's commits onto the main branch, run the repository's checks, fast-forward the main branch, push" — done by the execution that holds the lease.
- `NFR`, N-34: "The integration step runs a repository's declared checks on the machine of the execution." N-28: "The tac service has no runtime dependencies".
- CW.6 reads as if tac ran checks and landed commits; N-34 and N-28 exclude that.
- **Proposal:** CW.6: "tac keeps the order (the integration queue); the runtime whose execution is first in it carries out the integration step on its machine." Say also what "kept by tac" means on the local and the GitHub backend (`GA-9`).

**IC-3 — "The system does not pull on its own" against the automatic fast-forward.**
- `SCO > SCO-OUT`, O-6: "The system answers who holds what; it does not pull or merge clones on its own, except where the integration step lands an execution's own commits."
- `PAR > PAR-APPROACH`, CW.16: "A repository on which no lease is held can be brought up to date automatically, by fast-forward only … It is switched on per workspace."
- **Proposal:** either O-6 names the second exception (the optional fast-forward of CW.16, off by default), or CW.16 moves to `SCO > SCO-LATER`. F11 ("nothing is converged for it") has to match the choice.

**IC-4 — Where an item sent to another quest waits when it cannot be delivered.**
- `PAR > PAR-CROSS`, CW.19: it "waits at the sender and is shown there with what it waits for. It does not wait unseen at the receiver."
- `TAC > TAC-COORD`, CA.19: "A **command** is stored for 7 days with a delivery state per target quest" — it waits in the service.
- `RT > RT-MACHINE`, CR.36: machine-wide state holds "the inbox for items sent from one quest to another" — it waits at the receiver's machine.
- **Proposal:** one statement of the path: the record is kept by tac (or, on one machine, in the machine-wide state), the sender's run shows it with its delivery state, and what happens after the 7 days (CA.19) is said (`GA-14`).

**IC-5 — Sending a todo to another quest's runtime through tac: first version or later.**
- `PAR > PAR-CROSS`, CW.25: "… later also by finding a runtime of the target quest and sending the todo there, through tac or the runtime's MCP server."
- CW.20: "An item or a walk is sent into a named run of another quest: … on another machine as a command through tac"; CA.21; F7. None of them is marked later.
- **Proposal:** drop "later" in CW.25 or mark CW.20 (across machines), CA.21 and F7 accordingly; one of the two is wrong.

**IC-6 — A repository quest has a branch per member; the `_ai` state stays on the main branch.**
- `PAR > PAR-QUESTS`, CQ.6: for a repository quest the runtime provides "a branch per member, with a review of the conflicts when the branches meet; one shared process position, moved only on the main branch".
- `PAR > PAR-APPROACH`, CW.14: "The `_ai` state stays on the main branch: todo and state files are not code, are merged by their own merge drivers and are written file by file." CW.2: "The `_ai` state never gets working trees of its own." CA.17: these files "are written by many sessions at once, by design".
- A repository quest's folder is `_ai` state. **Proposal:** say whether CW.14 and CW.2 hold for classic quests only, or CQ.6's branch per member is gone. The product owner's answer to PQ-24 points to a new, "for now definite approach to quests in repos" (see `AN-8`); this pair is the first place it has to settle.

**IC-7 — A fencing token "checked at the push".**
- `GLO`, fencing token: "a write carries it, so a write by a holder whose lease has passed to someone else is refused." CA.14 the same. CW.5: "The fencing token is checked at the push."
- A push goes to the repository server, which knows no fencing token; no item says who checks it and how a push is refused. On the GitHub backend S5 may do it with refs, but the document does not say so, and on the tac server and local backends nothing stands between the runtime and the repository server.
- **Proposal:** state the mechanism per backend, or weaken the statement to what is true ("the runtime checks its token with tac immediately before the push"), and name the remaining window as a risk.

**IC-8 — "The service's clock" and "the service computes presence" against a backend that is a git repository.**
- CA.15: "Times that decide about leases and presence are the service's clock, never a tac client's". CA.4: "The service computes presence; no tac client writes it."
- CA.26: the GitHub backend keeps "leases, sessions and endpoints as refs in a coordination repository" — there is no service between the machines.
- **Proposal:** say per backend who computes presence and staleness (the local service of each machine? the repository server's time?), or restrict CA.4 and CA.15 to the local and tac server backends. It matters more now that the GitHub backend serves several members (`AN-27`).

### Runtime, host and quest

**IC-9 — "Runtime" as a running instance and as the installed program.**
- `GLO`, runtime: "One running instance of tar. It serves one quest … and is started by its host and ends with it."
- `RT > RT-INSTALL`, CR.42: "Every host carries a runtime and installs it … Hosts on one machine thereby share one runtime." `RISK`, R-13: "the hosts share the installed runtime". `CLI > CLI-PACK`, CL.5: "find or start the installed runtime". F1: "The host finds the installed runtime …, starts it".
- Read with the glossary, CR.42 says several hosts share one running instance, which contradicts CR.44 and T1 ("One runtime per window").
- **Proposal:** "the runtime installation" (or "the installed tar") for the files on disk; "runtime" only for an instance. CR.6 and CR.7 then also lose "runtime instance".

**IC-10 — One quest per runtime, or several.**
- CR.6: "One runtime instance serves one quest." `GLO` the same; CA.39: "Every runtime … serves one quest".
- `TAC > TAC-COORD`, CA.3: a runtime registers "the quests it serves"; CA.5: "per quest and run the process position …".
- **Proposal:** CA.3 "the quest it serves (none for a runtime without a quest)"; CA.5 "per run".

**IC-11 — A runtime without a quest has no home team, but everything about coordination is defined through the home team of the quest.**
- `GLO`, runtime: "serves one quest (or none, for an application's own AI)". CK.10: trc on the desktop "has a runtime of its own that serves no quest". T2: "one without a quest for Webwork's own AI".
- CI.2: "A user runs several runtimes; each coordinates in the home team of its quest." CA.39: "A runtime does this in the home team of its quest (CI.11), where it is always visible." CA.44, CI.11 and CI.13 the same.
- The two runtimes the first version needs most for people — Webwork's (messaging, review exchange) and trc's (supervision of a team) — have no quest and therefore, by the text, no team in which they are present, act or may control anything.
- **Proposal:** an item in `TAC > TAC-PEOPLE`: in which team(s) a runtime without a quest registers (all teams of its person? one chosen at the host?), what it may do there (messaging, asks, remote control as its person) and that it holds no leases.

**IC-12 — Two hosts on one quest: one runtime with two runtime clients, or two runtimes.**
- N-10: "Two hosts can work on the same quest at the same time." T2: "Two hosts may work on one quest." E-16: "two hosts on one quest".
- CR.44 / `GLO` host: a runtime "is started by its host and ends with it" — so each host has its own runtime; CA.6: "One quest may have several runtimes."
- CP.5: numbered events serve "a second one on the same run" — a second runtime client on the same runtime.
- Neither reading is stated, and with two runtimes of one person on one quest nothing says which of them executes a run's queue, takes a command ("the first runtime of that quest that acknowledges it takes it", CA.19) or owns a session.
- **Proposal:** decide and state it; if two runtimes, add the rule that a run is executed by exactly one runtime at a time and how the second one sees it (see `GA-6`).

**IC-13 — Who is the host when Webforge carries the application.**
- `VIS > VIS-SYSTEM`: "The hosts of the first version are the VS Code extension, Webforge, Webwork and the supervision application".
- `CLI > CLI-TRC`, CK.7: "trc is a Webforge application from the start, beside Webwork, the quest application and the core Forge application." T2: "Webforge with one runtime process per open quest plus one without a quest for Webwork's own AI." CK.10: trc on the desktop "has a runtime of its own".
- If Webwork and trc are applications inside Webforge, the list of four hosts counts the same program up to three times, and it is open whether Webforge is the host (one program, several runtimes, one user-settings layer of CP.13) or each Webforge application is.
- **Proposal:** in `GLO` host: a host may start several runtimes (one per open quest, one without a quest per application that needs one); list the hosts as programs (VS Code extension; Webforge with its applications; trc standalone; the service for phones and browsers).

**IC-14 — trc in Webforge: from the start, or later.**
- `USR > USR-HOSTS`, U-9: Webforge "later hosts trc as an application".
- `VIS > VIS-SYSTEM`: trc is "A Webforge application that also runs standalone"; CK.7: "a Webforge application from the start … It also runs standalone, outside Tom Forge, first and for testing"; D-5 the same.
- **Proposal:** U-9 without "later", or CK.7 / D-5 say plainly "standalone first, in Webforge when Webforge can carry it".

**IC-15 — What a lease names.**
- `GLO`, holder: "A lease names the runtime, the run and the item it is for."
- CA.8: "the lease names the runtime's quest, the run, the item, the machine and the workspace" (no runtime). The answer option taken in PQ-27: "the runtime, the quest, the run, the item, the machine, the workspace".
- CA.8 also says "That identity outlives the runtime process", while a runtime ends with its host: what identifies "the same runtime" after a restart is not defined (`GA-7`).
- **Proposal:** one list in the glossary and in CA.8, with the person added (CI.3 attributes everything to runtime and person).

**IC-16 — Coordination "off by default" against the local tac service that everything is routed through.**
- `TAC > TAC-BACKENDS`, CA.31: "With coordination switched off (`mode: off`, the default) nothing is coordinated".
- `RT > RT-MACHINE`, CR.38: machine-wide state goes "through the local tac service, which runs once per machine and user and through which every runtime's access is routed … and through files … when coordination is switched off". D-13: "its implementation routes through the local tac service". T1 (the simplest topology): "the local tac service once for the machine and user". CA.34: "Every runtime also registers with the local service of its machine, whatever its backend."
- If off is the default, the default installation uses the file implementation and T1 is wrong; if the local service always runs, "off" only switches claims off. CA.26 calls local, GitHub and tac server the "one of three" backends, so `off` is a fourth value of something else.
- **Proposal:** separate the two settings (the backend; whether claims are taken), say what the default installation runs, and correct T1 or CA.31.

**IC-17 — The MCP server published to the team against "remote control only where the host allows it".**
- `RT > RT-MCP`, CT.11 / CT.13: the MCP server offers the runtime tools on `_ai` (todos, queue, processes, sessions, … per CT.1) and "A runtime can publish its MCP server as an endpoint through tac, so the other team runtimes find it and call its tools."
- CI.13 / CK.5: "A runtime can be controlled remotely only by members of the home team of its quest and only when its host's setting allows it."
- Queueing items and moving a process through the published MCP tools is remote control in everything but the name. No item says that the host's setting also governs the MCP endpoint, or what the bearer token of CT.12 proves.
- **Proposal:** one permission model for both endpoints (see `GA-12`, `ID-3`).

### Identity, teams, tac server

**IC-18 — Which credential a tac client presents: the account's access key or the team token.**
- CI.8: "A tac client sends a team token with every request."
- CA.27: accounts have "access keys kept as salted hashes"; CA.28: "in a browser the access key travels as the WebSocket subprotocol"; CI.20: "With that key a person joins the tac server, creates a team".
- CA.30 adds "a key per runtime that an owner of the team issues", CI.18 a key per device, CT.12 a bearer token.
- **Proposal:** a table of credentials (`ID-3`); correct CA.28 if a browser client would send a team token.

**IC-19 — The relay authenticates "a key per runtime", pairing gives "a key per device".**
- CA.30: "A machine authenticates to it with a key per runtime that an owner of the team issues."
- CI.18: a device "is enrolled once, from inside, by its user, and gets a key of its own". T5: "from a paired device".
- Runtimes are started per host and per quest and end with the host (CR.44); a key per runtime issued by a team owner cannot be meant literally. CA.30 itself calls the relation "part of the open point for the security model" — but then D-23 and T5 should not state one side as decided.

**IC-20 — WR-2 is said to be met by a setting a team cannot use.**
- `TAC > TAC-WEBWORK`, WR-2: "Identification is one of the two levels of identity, on a tac server set to open (CI.10; PQ-13)."
- CI.10 / N-19: "An open server is right for one user alone on the VPN. As soon as other users use the tac server it is strict."
- Webwork's requirement is about a small team. **Proposal:** WR-2 "met differently: a team's tac server is strict; identification by user id and e-mail alone exists only on an open server for one user".
- Also in CI.10: "As soon as other users use the tac server it is strict" — a rule the server enforces (it switches, or refuses a second user), or advice to the administrator? Not said.

**IC-21 — "A tac client that states no user still works" against the strict server.**
- CA.38: "… and a tac client that states no user still works."
- CI.10 / D-54: on a strict server everyone needs an invitation and a team token; from the internet always.
- **Proposal:** restrict the clause to the local backend, or drop it: nothing uses `tac/1.0` today (E-11), so there is no older tac client to keep working. The same holds for "A runtime of an older version that is still running somewhere keeps working" (CA.38, N-4) — true only from `tac/2.0` on.

**IC-22 — Accounts: "the full tac server from the start" against "accounts of several organisations later".**
- CA.27 / D-22: "the full tac server from the start: accounts, access keys …, quotas per account, the administration interface"; U-7 "for one or several teams".
- `SCO > SCO-LATER`, L-11: "Billing, and accounts of several organisations on one tac server" are later.
- **Proposal:** say what the first version has: the account record and quotas for one account, and what exactly is later (creating further accounts? separation between them? billing only?).

**IC-23 — "The full tac server is built first" against "no order is fixed".**
- D-22 and X-4: "the full tac server is built first".
- D-45 / `DEL`: "No order of the component groups or of the units is fixed in advance". CA.27 says "from the start".
- **Proposal:** D-22 and X-4: "the tac server is built as the full tac server; there is no smaller one before it".

**IC-24 — Asks "routed by presence and by role".**
- D-20: "Asks are routed by presence and by role".
- `RT > RT-ASKS`, CP.17 … CP.19: a chain of persons (the person named, the quest owner, the owner of the triggering quest, the team owners); "An ask goes to another person only when the process or the todo names that person, or by the chain." No routing by role exists in the items.
- **Proposal:** D-20 "by presence and along a chain of persons", or add the item that routes to whoever holds a role.

**IC-25 — End-to-end encryption: decided as later, and open.**
- `SCO > SCO-LATER`, lead-in: "Decided as not part of the first version"; L-6 lists end-to-end encryption between a device and a runtime.
- CI.19 and N-21: whether it "is needed in the first version too" is "an open point for the security model".
- **Proposal:** take L-6 out of the table of decided deferrals and list it as an open point, or decide it.

### Messaging, documents, review

**IC-26 — "Notification" and "command" as kinds of a message between users.**
- CM.1: "A message between users has a kind." CM.2 lists "**notification** — from a runtime" and "**command** — to a quest's runtime: queue, pause, proceed".
- CA.19 defines notification and command as the two kinds of message *between runtimes*; CM.14: those "stay as they are beside the messages between users".
- So two of CM.2's ten kinds are not messages between users, and "notification" is also what a host shows the user (CP.10), the done notification (CR.21) and a push to a device (CM.6).
- **Proposal:** CM.2 keeps the eight kinds between users (or says "between participants" and names sender and recipient per kind); the glossary's "message kind" entry follows; see `ST-9` for the word.

**IC-27 — How long a pinned blob lives.**
- CV.4 / D-29: "A process can **pin** its blobs for as long as it runs."
- CV.14: "A round's blobs are kept until the round is merged or their longest lifetime is reached"; CV.3: "at most 30" days.
- A review round in a process that runs longer than 30 days: pinned for as long as the process runs, or gone after 30 days? D-29 "Replaces: FO-21's open concept for longer processes" suggests the first; CV.14 says the second.

**IC-28 — Who builds the review component.**
- `CLI > CLI-UI`, CU.1: `tom_ai_runtime_ui` "holds every reusable component of the runtime's user interface"; CU.6 lists the group **Review**; CU.3: "The package depends on nothing of Tom Forge."
- `RISK > RISK-DEPS`, R-19: "Tom Forge's review component in Flutter — the review group of the UI components … planned in the quest `tom_forge`."
- Either it is built here (G-6) and R-19 is no dependency, or it is built in `tom_forge` and `tom_ai_runtime_ui` depends on Tom Forge, against CU.3. The answer to PQ-30 ("none of our concern here") bears on it (`AN-34`).

**IC-29 — "Item" for two things.**
- `GLO`, queue item (item): "One entry of a run's queue".
- `RT > RT-PROTO`, CP.7: "a turn holds items (text, reasoning, tool call, ask, result), and an item has started, delta and completed events".
- CP.7 is marked a proposal, but the word is fixed by the glossary. **Proposal:** "part" or "entry" in CP.7; "thread" and "turn" need a definition or the same marking in the glossary.

### Scope, decisions, flows, numbers

**IC-30 — Cross-references of decisions and scope that point to the wrong place.**
- D-8 (Agent Client Protocol) names `RT > RT-HOST` as shaped; the items are CR.30 and CR.31 in `RT > RT-TRANSPORTS`, none in `RT-HOST`.
- D-16 (the Agent SDK mode) names `RT > RT-INSTALL`; the item is CR.29 in `RT > RT-TRANSPORTS`.
- `SCO > SCO-IN`, row `CP`: "the Agent Client Protocol in both directions" — the items are `CR`, not `CP`.
- `SCO > SCO-IN`, row `CI`, source "S1 § 7.3; PQ-9, PQ-13" — misses PQ-12, PQ-20, PQ-23 that shaped CI.5, CI.20, CA.39.
- D-59 "A person joins a tac server and then creates a team" is PQ-20's and sits in a decision about resources.

**IC-31 — Flows that say something else than their items.**
- F3: "A walk takes the next ready todo" — CR.19: "lowest number first".
- F6: "the round's files are released" — CV.12: "its blobs are then released"; F6 also leaves out step 3 (the copies are written into the round folder and committed).
- F1 ends at "subscribes to the events" and has no registration with tac (CA.3, CA.34), though T1 … T5 all depend on it.
- F10: "trc reads the team runtimes and their endpoints from tac" — by CI.4 trc reaches tac only through its runtime.
- F11: "The runtime is installed, gets the team's access and registers" — the steps of CI.6 (invitation), CI.18 (pairing, when off the VPN) and CA.3 are meant, none is named.

**IC-32 — Versions stated as "today" that are no longer today's.**
- `LAND > LAND-BUILT`, E-2: "`tom_todo_model` 3.1.0"; `RISK > RISK-DEPS`, R-18: "3.1.0 today, a further major release planned". The package in the workspace is at 4.2.0 (`tom_ai/modules/tom_todo_model/pubspec.yaml`). The document itself calls S2 "outdated … in the todo model's version".
- The other version facts (E-1 extension 0.1.0, E-3 `tom_tac_service` 0.1.0 with "40 tests", E-6, `tomspecs` 0.17.0, `tom_vscode_scripting_api` 5.0.0) should be checked in the same pass; the extension's is still 0.1.0.

**IC-33 — The question rounds are counted differently in four places.**
- `ABOUT`, status: "Question round 2 closed: every answer of `PQ-1` … `PQ-23` … Question round 3 (the terminology pass) … `PQ-24` … `PQ-33`".
- `CON`, X-13 and X-14: "The answer of the first question round" (meaning PQ-6, PQ-9); `RISK`: "Risks the first question round added" (PQ-7 … PQ-19).
- `ABOUT > ABOUT-READ` and `DEC`: the answers to PQ-1 … PQ-23 are "kept in `01_02_Questions Round/answers.md`"; this round's `answers.md` is headed "question round 4" in the folder `01_04_Questions Round`.
- **Proposal:** name rounds by their folder (`01_02`, `01_04`) or not at all; in the items cite only the PQ id.

**IC-34 — Smaller disagreements in wording.**
- N-6: "The protocol names the revision of MCP it speaks" — CT.15: "The runtime names the revision of MCP it speaks".
- N-23: "A file a prompt drew from an encrypted document leaves no trail on disk" — CR.24: "For a prompt that draws on a document the host marks as encrypted, the trail is kept in memory only." N-23's subject is wrong (the prompt leaves no trail, not the file), and neither says how CP.6 ("reloads the run from the trail files") and CW.11 work for such a prompt.
- `VIS > VIS-SYSTEM`, Client SDKs row: sources "FO-10, FO-11, CQ-15"; CL.1 adds PQ-7; the row calls TypeScript and JavaScript two languages, CL.7 treats them as one ("The Dart and the TypeScript and JavaScript client SDKs").
- `CLI > CLI-PACK`, CL.2 / D-2 / G-4: "The runtime client SDK depends on the tac client SDK" — CL.11 / CI.4 / D-27: an application never speaks to tac, it "reaches tac through its runtime". Why the application's SDK then needs the tac client SDK is said nowhere (shared record types?). State the reason or drop the dependency.
- `NFR > NFR-GEN`: "Until then the register below names the units" — the register is the table above.
- `SCO > SCO-IN`, last row cites N-32, N-33 for the split; N-24 (no import of VS Code, guarded by a test) belongs there too.
- CK.4 / U-5: "A user supervises their own runtimes, or some of the team runtimes" — CK.1: "a team's team runtimes in one view". A user's own runtimes lie in several teams (CI.2); whether trc shows one team at a time or all of the user's is not said (CI.12: "A user's devices show all their teams side by side").

---

## 2 Consequences of the answers PQ-24 … PQ-33

Each entry names a place that has to change beyond the place the question sits at. "Open" marks what the answer leaves undecided and the Blueprint needs.

### PQ-24 — the run that asked waits as a whole (answer (b))

**AN-1 — `RT > RT-ASKS`, CP.21.** New text, e.g.: "While an ask waits, the run that asked waits: nothing further is sent from its queue until the answer arrives. The other runs go on." "the rest of the queue" and the walk clause go.

**AN-2 — The lead-in of `RT > RT-ASKS` and N-15.** "An ask … must not hold a process up for long" and N-15 "does not block a process for long" no longer follow from the items: with CP.18 (4 working hours per person) and CP.17 (up to four links) a run can be held for two working days, and by CP.20 for ever when nobody answers and no default is declared. Reword to what is true (an ask is never lost, is escalated and is visible), and add a risk (`AN-7`).

**AN-3 — `GLO`.** "ask" gets the sentence "the run that asked waits until it is answered"; "run" may say that a run is held by an open ask of one of its executions. `GLO` "execution": "ends when the item is done or given up" — say that an execution waiting for an answer is still the same execution and keeps its leases (or does not: open, see `AN-5`).

**AN-4 — The other things an item waits for must say the same or the opposite, explicitly.** CS.10 ("the queue item that needs the secret waits and the user is asked to unlock" — an ask by CP.8's definition?), CW.4 ("the item waits and says who holds it; when the lease is released, the waiting item goes on" — does the run wait, or take another item, as CW.7 "a run uses [the list] to start only todos whose resources do not overlap" suggests?), CR.20 ("An item can wait for its own background work and for something outside that only time resolves"), CR.17 ("the queue waits until the host reports that the user applied or discarded"), CR.13 (a refused step). Today five items describe waiting, each with its own subject (item, queue, run). Open: one rule for all, or a rule per cause.

**AN-5 — Leases while a run waits.** An execution in strict mode holds an exclusive lease "for as long as the item is executed" (`GLO` strict mode, CW.5, D-55). With (b) and an escalation chain, a repository can be leased exclusively for days by a run that waits for a person; CA.13 keeps the lease fresh as long as the runtime renews. Open: are leases kept, released and claimed again, or downgraded while an ask waits? R-10 ("held too long") gets a second trigger either way.

**AN-6 — States, events and views.** CR.23 lists "working, waiting for a decision, failed with a retry possible" — add "waiting for an answer" (and for a lease, a secret, a time, per `AN-4`). CA.5 (the state a runtime keeps with its registration: "the number of open asks") should carry "runs held". CK.1 / CK.9 / CU.6 (run tabs "with state marks", the ask inbox) / CU.15: trc and the run tabs show which run is held by which ask since when. F4 and F5 say "the run waits" in their line. D-20 gets the clause. CP.9 ("the run resumes when the answer arrives") and CP.22 ("the answer returns to the run that asked") now stand as written.

**AN-7 — `RISK`.** New risk: one unanswered ask holds a whole run (and, in strict mode, a repository) for as long as its chain takes; trigger: an ask without a default addressed to a person who is away. `DEL`, "The order of building" ("A todo that waits for a todo of the other run is held and goes on when that one is done") is the same pattern and should name it.

**AN-8 — The second half of the answer is an instruction that changes the sources.** "…review the recently done todo and currently existing todos in vscode extension for more details, there have been some important additions and also look at al_the_bear for a planned restructuring of the `_ai` folder and an updated and for now definite approach to quests in repos (which I'd consider the standard from now on)." Places that depend on it and cannot be corrected from the document itself:
- `SRC`: new sources (the al_the_bear restructuring document, the extension's recent todos); the standing of S2 § 3.7 and S12 changes.
- `PAR > PAR-QUESTS`, CQ.1 ("Which kind a quest is, is decided per quest" — against "the standard from now on"), CQ.2 … CQ.8, D-34 ("Repository quests as planned"), E-14, `GLO` quest, the PQ-33 terms "classic quest / repository quest / personal repository".
- `RT > RT-LOCATIONS`, CR.33 (how the `_ai` folder and the quests of a workspace are found), CS.1 (the quest's layer), CQ.5 (the one resolver, still marked `___check here___`).
- CW.14, CW.2, CA.17 and CW.25 ("the shared state repository that holds several quests"), and the example name in the answer to PQ-31 (`al-the-bear/tom_agent_state#quests/…`), which assumes classic quests.
- `RISK > RISK-DEPS`, R-15 and R-16 (their states), `DEL` steps 1 and 2.
- `IC-6` is decided by it.

### PQ-25 — a session starts over (answer (a))

**AN-9 — CR.18 and `GLO` session.** CR.18: "A run can start a session over: the next prompt starts without the earlier context; what was said before stays readable in the trail." `GLO` session: "a named line of conversation with a model, belonging to a run, that can be started over" (the answer's wording).

**AN-10 — Places that assume a session is one conversation.** CP.7 ("A conversation with a model is modelled as thread, turn and item: a session holds turns") — say that starting over ends the thread and begins a new one in the same session. CP.3 (commands: "sessions") gets "start over". CS.17 ("with a session id where the outside program of an agent transport owns the conversation") — starting over means a new outside session id under the same session name. CW.11 ("the way from a commit back to the session that made it") — after a start-over the session name no longer identifies the conversation; the record needs the place in the trail. CQ.3 ("the storage of the sessions: the live trail, the history and its compacted form") — what of the history is kept on a start-over. CR.21 / CW.23 (done notification "to the run and session that queued it") — still valid, but it now arrives in a conversation that does not know the request.

**AN-11 — The word "conversation" for the model side.** After (a) the document still uses "conversation" for the exchange with a model (CP.7, CR.18, CS.17, `GLO` session and transport) and for messaging between users (`GLO` conversation, `TAC > TAC-CONV`). `CLI > CLI-UI`, CU.6 has both in one table: the group **Conversation** ("conversation, message, prompt input …", from the chat panel) and, under **Messaging**, "conversation list, conversation, composer". CU.15: "the AI panel (conversation, queue and trail …)". Proposal: "chat" (the extension's word, SC-1 "The chat panel") for the model side in `CLI`, and "exchange with the model" in `RT`.

### PQ-26 — no server uses the tac client SDK (answer (a))

**AN-12 — CL.11.** "The tac client SDK is used by runtimes and tools."

**AN-13 — "tools" is undefined here.** In the glossary a tool is "a function an agent can call"; CL.11 means programs (command lines, fleet scripts?). Name them or say "command-line programs of ours"; otherwise CL.11 contradicts the glossary.

**AN-14 — What the option taken says about the server must become an item.** "A runtime host server reaches tac only through the runtimes it starts; it checks a connecting application against its own configuration or by starting the runtime, which then presents the user's team token." No item says how the server (after PQ-28: the web runtime service) authenticates an application; CR.46 and T8 need it (`AN-24`).

**AN-15 — Places that list who uses or needs the tac client SDK.** `GLO` client SDK ("which the runtime uses to reach tac" — add the tools); CA.25 ("the service and its tac client SDKs can be used without the runtime" — stays, and is what the last part of the answer to PQ-30 relies on); CA.28 ("It answers tac clients in a browser"); N-26 ("The Dart tac client SDK runs with and without `dart:io`") — both describe a tac client in a browser that the first version does not have (`AN-33`); `TAC > TAC-WEBWORK`, WR-6; D-2; G-1 ("the tac client inside the runtime" — say that it is the TypeScript tac client SDK of G-5, or that it is not); CL.2 (the dependency, `IC-34`); CL.6 (the conformance suite needs a program that drives each tac client SDK without a runtime).

### PQ-27 — tac keeps no record for the holder (answer (a))

**AN-16 — The three places named in the question.** CA.20: "an execution started or ended" in place of "a session started or ended". CA.26, GitHub row: "leases and endpoints as refs". CA.29: drop "closing a session".

**AN-17 — Further places.** `CON`, X-11: "for leases, sessions and endpoints" → "for leases and endpoints". CA.8: the last sentence ("The word 'session' is not used for this; a session is a conversation.") can go; the item needs the full list of what a lease names (`IC-15`) and how a restarted runtime recognises its leases without a record of its own (by the names on the lease — then the runtime's id must be stable, `GA-7`). `GLO` holder: add quest, machine, workspace. CA.36: `tac/2.0` drops the session record of `tac/1.0` — say so, since CA.33 migrates "token counters and undelivered commands" from what is built. CA.5 and SC-28 / CU.6 (the coordination page: "claims, leases, the integration queue") list executions, not sessions. E-3 keeps its parenthesis (it describes what is built).

**AN-18 — "Session" still used for "another writer".** CA.17 ("written by many sessions at once"), P-5, P-9 (`PAR > PAR-PROBLEM`), R-9, R-11, CW.11, CW.18 ("a session, a user" as an address). By the glossary a session is a conversation with a model inside a run; in P-5, P-9, R-9, R-11 and CA.17 the writer is an execution or a runtime. CW.18 should say whether a session really is addressable from another quest.

### PQ-28 — a web runtime client SDK and a web runtime service

The answer: "There is no given solution for this now. I assume the runtime cannot run directly in mobile devices, so there will be an additional relay which connect to a runtime on behalf of the device … a remote runtime client SDK that connects to a remote runtime service running on a server. That remote runtime service would then connect to the tac as usual from the server. For the web scenario we'll need a HTTP-based service, maybe this can be one and the same as what is used by mobile devices. So I suggest we call the component web runtime client SDK and web runtime service, being used in mobile apps and from Flutter-base (or non-Flutter) web applications. We'll provide a Dart and a JS/TS web runtime client SDK …".

**AN-19 — The answer does not choose among (a), (b), (c); the question stays open, and the document must say so.** CI.18 and CI.19 keep an undetermined "the server". What the answer adds is a component and two SDKs; which program faces the internet, which holds the device keys, and whether tac's relay (CA.30) is involved, is not answered. `ABOUT` status, CI.19 (the open point) and R-22 have to carry this as open, not as settled.

**AN-20 — Names: "runtime host server" (41 lines) against "web runtime service".** The document's term, agreed in S21, is **runtime host server**: `GLO` (host, server, the words-not-used table "server (alone)"), `VIS > VIS-SYSTEM`, L-8, CR.46, CL.11, CK.10, CI.4, CI.19, `TAC > TAC-WEBWORK` WR-6, T8 and the paragraph under the topology table, D-27, D-51, D-52, X-3, X-12, X-14, R-8, R-22. The product owner now "suggests" **web runtime service** and uses "relay" and "remote runtime service" for it in the same answer. Open, and the first thing to ask: is the web runtime service the runtime host server under a new name (one runtime per connected application, ending with the connection), or a different thing (a relay in front of runtimes that exist anyway — "connect to a runtime on behalf of the device")? Until answered every one of the places above is uncertain. The glossary's rule "server: always with its kind" and "A runtime running as a process of its own is … not a server" needs a line for "service" (`ST-9`).

**AN-21 — "Relay" now names two things.** CA.30 / D-23 / T5 / `SCO > SCO-IN` row `CA` / V-3 / CA.7: the relay is "part of the tac server", "carries TAC and MCP … and only forwards". The answer: "an additional relay which connect to a runtime on behalf of the device". Either the second is the web runtime service (then the answer's word must not enter the document), or tac's relay gets a third protocol. CA.23 (a runtime publishes "its remote control" endpoint with where it "can be reached from (the machine, the VPN, the public network)") and CK.11 ("A phone or tablet reaches the tac server and the runtimes from the internet") describe a third path — the phone reaching runtimes directly — that agrees with neither.

**AN-22 — The client SDK list and "nine languages".** Today: "One runtime client SDK and one tac client SDK per language, for nine languages" (`VIS > VIS-SYSTEM`; CL.1, CL.2, CL.3; N-26; N-31; D-3, D-50; G-3 … G-5; `SCO > SCO-IN` row `CL`; R-12, R-24). The answer adds a **web runtime client SDK** in Dart and in JS/TS. Open: (1) is it a third SDK beside the two, or the runtime client SDK with a second transport (CP.1 already says "a remote runtime client attaches over WebSocket")? (2) do the other seven languages get one? (3) does the JS/TS one replace the TypeScript and JavaScript runtime client SDKs for browsers (a browser cannot do CL.5's "find or start the installed runtime" nor CP.1's TCP)? (4) CL.2's dependency on the tac client SDK — does it hold for the web SDK? (5) CL.9 ("The Dart runtime client SDK has no dependency on Flutter") for the web one. Every place above then changes; G-units need at least two more rows.

**AN-23 — The wire.** CP.1 / D-10: "length-prefixed JSON-RPC 2.0 over loopback TCP, with WebSocket for remote runtime clients"; T8: "The application reaches the runtime host server over WebSocket". The answer: "we'll need a HTTP-based service". Open: HTTP with a stream for events (CP.4, CP.5), and how the **reverse requests** travel to a phone or a browser — asks, opening a document, and above all the host's tools (CP.10, CP.14, CP.35 "an API with callbacks in both directions", CT.4, CT.5). CP.11 (one JSON schema, from which SDKs are generated) and CL.6 (the conformance suite) must cover the second binding. CP.24 … CP.27 and CL.8 (version checks and upgrade callbacks) need a statement for an application that never installs a runtime (CR.42: "Every host carries a runtime and installs it" does not hold for it).

**AN-24 — Who is the host, whose runtime is it, and where are its files.** `GLO` host: "For an application on a phone, on a tablet or in a browser the host is a runtime host server". With a service that many users reach, these items no longer follow: CR.7 / CI.2 ("A runtime … belongs to exactly one person") — whose user settings (CS.1 "the user's own file"), whose secrets (CS.7 … CS.11: the team tokens "kept as secrets", the vault unlock of CS.10 asked of whom, the approval by Tom Secrets Manager of CS.9 per runtime); CR.40 ("one installation of the runtime per machine and user"); CA.40 ("the repositories the person it belongs to has access to …, cloned on its machine") — a service on a server has no clones of the user, so which quests can a phone work on? CP.13 (the host interface supplies "the kind of host, the user"); CI.6 step 3 ("The invited person's runtime presents the password"); CI.7 ("Every device registers itself under it"); CI.3 ("A user has several devices, each with its own connection and its own read position"). All open.

**AN-25 — Lifetime.** CR.46 / T8 / D-52 / X-12: the runtime "ends with that application's connection". A phone application loses its connection whenever it goes to the background. For trc that only costs a restart of a runtime without a quest; for anything with a queue it ends the work (CR.44: "A long walk needs its host open"). If the web runtime service "connect[s] to a runtime on behalf of the device", the lifetime is the runtime's own and L-5 / T6 (standalone runtimes, later) are touched. Open.

**AN-26 — First version or not.** D-51 / CK.10 / CK.11 / X-14 / L-8 / R-8 / WR-6: "The architecture for applications on phones and tablets is part of the first version"; "the runtime host server … is in the first version, for the supervision application". The answer begins "There is no given solution for this now". Open: does D-51 stand (trc on the phone in the first version, from the internet), or is it conditional on the solution? `SCO > SCO-IN` row `CK`, V-7, U-5, T8's place in "T1 to T5 and T8 belong to the first version", `VIS > VIS-SYSTEM` (trc row and the paragraph under the table) depend on it.

**AN-27 — Further places.** `USR`: U-6 (an application developer of a web application, "Flutter-base (or non-Flutter)" — the non-Flutter one is new: O-3 says there are no UI components for other platforms, so such a developer gets only the SDK); U-7 or a new user group for whoever runs the web runtime service. `LAND`: E-9, E-10. `CLI > CLI-UI`: CU.1 ("over the Dart runtime client SDK") and CU.4 / N-25 ("build for desktop, web, iOS and Android") — the components must work over both Dart SDKs. CK.6 ("built from the Dart runtime client SDK"). CK.12 (the VPN check on iPhone and Android) stays. CP.18 ("without an active runtime client there"). `NFR`: N-19, N-21 ("Whatever is reachable from the internet is reached only by paired devices") — a web application in a browser is not a paired device in the sense of CI.18; N-29 (the JS/TS SDK published only to "the workspace's binaries repository" does not fit "easy and consistent integration" for a web developer — npm is "later"); N-30 (a guide for setting up the service). `NFR > NFR-TOPO`: T5, T8, the paragraph under the table ("On the always-on machine the tac server and the runtime host server (T8) run in the first version"), F1, F10, and a new flow for an application on a phone. `NFR > NFR-GEN`: units for the service and the web SDKs (`GA-1`). `DEC`: D-3, D-10, D-27, D-50, D-51, D-52, plus a new decision that records the answer as it is (a direction, not a design). `CON`: X-3, X-12, X-14. `RISK`: R-22 (now: an architecture that is undecided and reachable from the internet in the first version), R-8, R-12, R-24. `DEL`: which track builds it.

### PQ-29 — the git-based backend serves teams of several members; the local one a single machine

The answer: "The git-based tac service must support simple teams of multiple members, too, besides a single-member personal team, the local implementation works only on a single machine."

**AN-28 — `GLO`.** team: "A group of users on a tac server, within an account" → a team exists on the GitHub backend too, without an account. personal team: "The implicit team of a user who works without a tac server (the local backend)" → on the local backend (one machine) and, as a single-member team, on the GitHub backend. backend: "local (one machine), GitHub, or a tac server" stays. member / owner, invitation / team token, open / strict server, account: each is defined through the tac server and needs a statement for a git-based team, or the statement that it does not exist there.

**AN-29 — CA.26.** GitHub row: "For: one user's machines" → "one user's machines, or a simple team of several members". The paragraph under the table ("On the GitHub backend a user without a tac server coordinates leases across machines; messaging, documents and reviews across machines need the tac server") must say what a **team** on the GitHub backend has and lacks. X-11 and D-47 say the same and follow.

**AN-30 — What a team of several members needs that the GitHub backend does not carry, by the document's own items.** With "no messages across machines" (CA.26): commands between runtimes (CA.19, CA.21) — so cross-quest items to another member's machine (CW.20), blockers and done notifications across machines (CW.21, CW.23), todo offers (CW.26, CA.44) do not travel; asks cannot go "through tac to that person's other devices" or to the next person in the chain (CP.17, CP.18, CP.22, F5); no review exchange (CV.11), no reminders (CM.4); remote control and trc (CK.8, F10) would rest on endpoints alone. Open, per capability: not available on a git-based team, or the answer changes "no messages" (S2 § 3.4 once had the GitHub backend carry message blobs — X-11). A table per backend makes this decidable (`ID-5`).

**AN-31 — Identity and rights in a git-based team.** CI.5 (the table of rights: who is a team owner, who may free "anyone's" stale lease, who changes the team's configuration), CI.6 … CI.9 (invitation, team token, removal), CI.10 (open or strict is "a setting of the tac server") , CI.14 (the member list), CI.20, CI.11 (a quest's home team: how is a git-based team named in a quest?), CI.15 / CS.3 / CS.4 / CS.5 / D-18 ("in tac, as the team's configuration, in whichever backend the team uses"; "Only a team's owners change the team's configuration"; keys "a user cannot override") — in a repository every member with push access can write. Open: is membership "whoever can push to the coordination repository", and are the owner-only rules then agreements?

**AN-32 — Further places.** CA.39 ("a user who works without a tac server has a **personal team** with themselves as its only member") — no longer true for a member of a git-based team. CA.2, CI.1 ("on a tac server" is not in CI.1, good; the glossary is the odd one). CA.4, CA.13, CA.15 (`IC-8`: presence, staleness and "the service's clock" without a service). CW.6 (the integration queue "kept by tac" — in refs?). CA.32 / N-12 (the backend cannot be reached = the repository server cannot be reached). CA.33 (migration from a git-based team to a tac server: members and identities too). CA.34 (the warnings). `NFR > NFR-TOPO`: T3 ("One user, several machines … coordinate through the GitHub backend or the tac server") stays; T4 ("A team on the VPN: As T3 with several users; the tac server carries the messaging") needs the variant "a team on the GitHub backend, without messaging"; F11. `TAC > TAC-WEBWORK`, closing sentence ("Webwork does not need … the GitHub backend"). `USR`: U-3 ("Create a team on a tac server they have joined"), U-11; E-17, R-20; R-3 (team features nobody has used) gets the second backend. D-24, D-25, D-47, D-53, D-54. `SCO > SCO-IN` row `CA`.
- Also open: the answer says "git-based tac service"; the document says "GitHub backend" and S5 "the GitHub refs binding". Is the backend bound to GitHub, or to any git server? CA.10 (`<owner>/<repository>` "when the team has one repository server") and O-level statements depend on it.

### PQ-30 — no review application in this project

The answer: "(a), the review application will never be part of the ai_runtime project. It is currently integrated into the VS Code Extension and will later completed with Webwork and WebForge, first just on desktop, later with a web version. … An application that needs to connect to tac will go through a runtime and use the runtime client SDK. … I'm not excluding that there may come additional services that use tac directly (through the tac client SDK) … This isn't planned for the moment. For the moment messaging will be in Webwork through the runtime and we'll add messaging into the VS Code extension once the ai runtime is build."

**AN-33 — `GLO`.** application: drop "the review application". host: drop the last sentence ("An application that will only later connect to a runtime (the review application) is a host from then on"). user: "or another application such as the review application" → every application a user uses reaches tac through a runtime, so "a person using an application" suffices.

**AN-34 — Scope: out, not later.** Option (a) proposed a line in `SCO > SCO-LATER`; the answer says "never be part of the ai_runtime project". So: a new `O-n` in `SCO > SCO-OUT` ("A review application of its own. Review is part of the applications that carry the review component: the VS Code extension today, Webwork and Webforge later; none of them is built here"), and a new `L-n` only for "services that use tac directly through the tac client SDK, for a part of tac such as messaging — not planned".
- This sharpens `IC-28`: if the review function "is currently integrated into the VS Code Extension and will later completed with Webwork and WebForge", is the **Review** group of CU.6, CU.9, SC-18, G-6 and R-19 still built in this project? Open; ask.

**AN-35 — CA.28.** "It answers tac clients in a browser (cross-origin requests; in a browser the access key travels as the WebSocket subprotocol)" — nothing in the first version is a tac client in a browser. Mark it as a capability kept for the services of the new `L-n`, or remove it; N-26 ("with and without `dart:io`") and `TAC > TAC-WEBWORK` WR-6 follow.

**AN-36 — The reviewer without a repository (U-2).** CV.15: "needs only an application with the review component (`CLI > CLI-UI`) and an identity in tac"; CV.5: "as long as their application reaches tac". With the answer, in the first version that application is Webwork on the desktop (an application that is not built here, O-2), trc, or the VS Code extension; each "through a runtime". Add "and that application reaches tac through its runtime" to CV.5 and CV.15, and say in U-2, V-5 and P-3 which application a business reviewer uses in the first version. "the documents reach webwork indirectly" in the answer is not explained — open.

**AN-37 — Messaging in the VS Code extension.** New statement of the product owner: "we'll add messaging into the VS Code extension once the ai runtime is build". Places: U-8 (the extension as a host gets messaging), O-1 (messaging views are not among "the VS Code extension's own features"), SC-27 ("new"), CU.6 Messaging ("new; from tac") — the extension is a web-view host, not Flutter, so who builds its messaging views (O-3: no components for other platforms)? `DEL`: after the runtime. E-15 and U-10 stay ("messaging will be in Webwork through the runtime").

**AN-38 — Further places.** CI.4 and D-27 stand without exception; X-3 the same — add that no application of the first version is a tac client. CL.11 as in `AN-12`. CM.1 / CM.2 / CV.9 / CV.12 ("the recipient's application", "Each member's application", "The coordinator's application") — fine, but CV.12 step 1 says "The coordinator's runtime" and step 3 "The coordinator's application": one of the two does the writing and committing. R-3's trigger ("a reviewer without a repository takes part in a review") now depends on an application outside this project.

### PQ-31 — resource names with a prefix (`git:`)

The answer: "(a), we may run into other types of resources in the future, but for now that is what we need. Using a prefix git:... we can have as many notations as needed and introduce them as they come."

**AN-39 — CA.17 and CA.9.** CA.17 as option (a) words it, with the prefix. CA.9: one kind of name for now (`git:`), covering a whole repository and a part of one; the two kinds of `tac/1.0` that "are not used for now" become "further prefixes can be added" — the sentence about "a folder of the `_ai` state" as a kind goes.

**AN-40 — Every place that states the name's form or an example.** `GLO` resource and resource name ("`<owner>/<repository>` …, in full (`github.com/<owner>/<repository>`) …. Example: `al-the-bear/tom_ai_build` and `al-the-bear/tom_ai_build#tom_ai_runtime/**`"); CA.10; CA.41; CA.11 and `GLO` overlap ("when they name the same repository" → resources of different prefixes never overlap); CA.16, CA.42; D-59; D-60; X-15 ("there are two kinds for now"). Open: the exact grammar — `git:<owner>/<repository>[#<pattern>]`, where the server part goes when a team has several repository servers, and how a pattern containing `#` or spaces is written in a todo's YAML.

**AN-41 — Where resources are written and read.** CR.35, CW.7, CW.8, CW.24 (a quest's list, a todo's resources — written with the prefix; is a name without prefix accepted from older todos?); R-18 / E-2 (the fields of `tom_todo_model`); SC-28 and CU.6 (the coordination page shows names); CA.3 (the repositories a runtime registers — same notation?); CA.36 (`tac/2.0`: the name is an opaque string to tac except for the overlap rule per prefix — say which). S21 (the terminology) gets the same change.

**AN-42 — One notation family.** The document now has three prefixed notations: secrets (`tsm:`, `os:`, `env:`, `file:` — CS.7), messages (`msg:tac/<team>/<messageId>` — CM.12) and resources (`git:`). CW.18 ("One way of addressing … a todo as quest and todo id, a run as quest and run, a session, a user") has no written form at all. See `ID-4`.

### PQ-32 — "pairing" for devices only (answer (a))

**AN-43 — The four places of the question.** CS.9: "The runtime is approved by the Tom Secrets Manager service once, as a program of its own. A setup guide describes the approval." U-7: "have the tac server approved by Tom Secrets Manager". D-19: "the runtime and the tac service are approved by Tom Secrets Manager once". N-30: "having the runtime and the tac server approved by Tom Secrets Manager".

**AN-44 — Further places.** `GLO` device, pairing: "…may reach the server from the internet" — "the server" is the undetermined one of `AN-19`; add "used for devices only". CS.9 says "The runtime is approved … once" — once per installation, per machine and user, or per runtime instance (instances are started per host and quest)? With the service of PQ-28, once per user on the server? Open. U-13 ("The runtime and the tac service are its clients") and R-17 agree as they are.

### PQ-33 — further glossary terms (answer (a))

**AN-45 — The new table.** "Further terms of this document" with: walk, gate, role, role type, quest owner, done notification, relay, notification, command, capability block, repository server, standalone runtime, classic quest, repository quest, personal repository, root, workspace folder, profile, coordinator — each "with the wording of the item named". Three of them cannot be taken over as they stand: **relay** (`AN-21`), **notification** and **command** (`IC-26`, `ST-9`: each has several senses in the document), and **classic quest / repository quest / personal repository** (`AN-8`: the approach changes). S21 gets the same entries; D-60's list of agreed terms and the `SRC` row of S21 ("TQ-1 … TQ-11") follow.

**AN-46 — Terms the question's list misses, used in a fixed sense and defined nowhere.** From this read: **first version** / **first delivery** (`ST-7`); **the `_ai` state**, **coordination repository**, **always-on machine**, **the fleet**, **window**, **machine** (against device); **subject** (of a run, CR.8), **lane** (E-1 "queue lane"), **step boundary** (CR.12), **pre-prompt**, **follow-up**, **timed request**, **reminder** (queue, CR.19, against the messaging reminder of CM.4); **thread**, **turn** (CP.7); **ask envelope** (CP.8), **reverse request** (CP.10); **access key** (CA.27), **one-time password**, **identification**; **member id** (in review rounds, CP.13, against the user id of CI.6); **review copy**, **base**, **merge / consolidation** (CV.12, CU.6); **quest member** (CQ.6, CQ.7 "the user is registered as a member"); **integration lease** (CA.36); **web runtime service**, **web runtime client SDK** (PQ-28); **budget** ("out of budget", CM.2); **main branch** against **trunk** (CW.1); **reconcile**, **sync**, **converge** (O-6, CW.13, F11).

---

## 3 Gaps

**GA-1 — The program that serves phones and browsers has no capability area, no generation unit and no deliverable.** The runtime host server is "in the first version" (D-51, D-52, T8, WR-6) and is described by one item (CR.46). `NFR > NFR-GEN` G-1 … G-7 contain no unit for it, `DEL`'s two tracks do not name it, N-30 has no document for it, no user group runs it. With PQ-28 it becomes the web runtime service plus two SDKs. Needed: who starts and operates it, what it authenticates, how many runtimes it may start, what it stores, how it is updated (CR.41 … CR.42 are written for a desktop host).

**GA-2 — Whose runtime runs on a shared server.** See `AN-24`: person, settings, secrets, installation "per machine and user", clones "on its machine". Without it CR.7 and CA.40 cannot be turned into requirements for T8.

**GA-3 — Renewal and claims: no numbers and no failure behaviour.** CA.13 gives the one number (stale after 60 minutes). Missing: how often a runtime renews; how long a claim waits and whether it can time out; the order in which waiting claims are served ("A released lease wakes the runtimes that wait for it", CA.20 — all of them, first come?); whether an exclusive claim can starve while shared leases keep coming; what a runtime does when its lease was freed under it (CA.14: "finds out at its next check" — and then? stop the execution, discard the working tree?); what happens to the leases of a runtime that ends normally with its host in the middle of an execution.

**GA-4 — Whether a run executes one item at a time.** `GLO` run: "A queue that executes todos and prompts"; CR.15: "a session carries one item at a time"; CW.7: "what a run uses to start only todos whose resources do not overlap". CW.7 implies several executions of one run at once; nothing states it. PQ-24 (b) ("the run … waits as a whole") needs it: are the run's other running executions stopped, finished, or do they not exist?

**GA-5 — The local tac service.** CR.38 / CR.39 / CA.26: "started by the first tac client that needs it", "runs once per machine and user", "outlives a single runtime", has an "idle stop" (CA.28). Missing: who installs and updates it (it is G-2, not part of the runtime installation of CR.40), what happens to machine-wide state when it crashes, its version check against runtimes of different versions (CR.41 keeps old runtimes running), and how the file implementation and the service implementation of CR.38 hand state to each other when coordination is switched on or off.

**GA-6 — Two runtimes on one quest.** See `IC-12`. Missing: which runtime executes a run; how two runtimes of two different people on one quest (a repository quest joined by a second user, CQ.7) share "one shared process position" (CQ.6) when each has personal sessions and trails (CQ.3).

**GA-7 — The identity of a runtime.** CA.3 registers "its id"; CA.8 says the holder's identity "outlives the runtime process". Not said: who generates the id, from what (machine, workspace, quest, host kind, person?), whether two windows on one quest have different ids, and what a restarted runtime presents to find its leases.

**GA-8 — The quest owner and the chain.** CP.16 / CI.11: "Every quest has a quest owner … it records both." Missing: where it is recorded, who may change it, what happens when the quest owner leaves the team or the quest has no home team (local backend: every link of the chain is the same person). CP.18: "4 working hours" — working hours are defined nowhere (per team? per person? time zone? holidays?); "the person the process or the todo names" — by user id, e-mail or role? CP.20: an ask "stays open and is marked unanswered" — with PQ-24 (b) the run stays held; is there a way to give up?

**GA-9 — The integration step when it fails.** CW.5, CW.6, CW.10: "lands the execution's commits or rejects them back to it". Missing: what the execution does with a rejection (the item is done by then — is it a new item, the same session?), who resolves a rebase conflict, how often CW.10's re-run may repeat, what happens to a finished branch when the runtime ends before its turn in the queue, how long the integration lease may be held, where "the checks the repository declares" are declared, where working trees are created and when they are removed (CR.4's cleanup registry?), and what the integration queue is on the local and GitHub backends.

**GA-10 — Discarding an execution.** P-7 and CW.1 promise "a way to discard an execution"; CW.11 gives "revert that range". Missing: who triggers it (a command? trc?), what it does in worktree mode before integration (drop the branch) and after, and what happens to the todo's state and to `_ai` changes the execution made on the main branch (CW.14).

**GA-11 — How `_ai` changes travel between machines.** O-6: reconciles "stay a step the user starts". But CW.21 ("The runtime follows such blockers across quests, and through tac across machines"), CW.22 ("A request to another quest is a todo in that quest"), CW.25 ("by writing into the quest's repository") and CV.12 step 3 ("commits there") assume that todo and state files are committed and pushed by someone at some time. Who commits and pushes `_ai`, when, and under which lease, is said nowhere.

**GA-12 — Authentication of the published endpoints.** CT.12: "The MCP server asks for a bearer token." CA.23: an endpoint says "how to authenticate, never a secret"; CA.24: "the endpoint itself checks who may use it." Missing: who issues the bearer token, how a team runtime obtains it, whether it is the team token, what the runtime checks (membership of the home team? the host's setting?), and the same for the remote-control endpoint — including which protocol that endpoint speaks (the runtime protocol over WebSocket, CP.1?).

**GA-13 — What remote control covers.** CK.2: "more or less everything a runtime can do". Missing: what is excluded (host tools? the file tools? changing settings? approving tool calls on another person's machine — CP.8 lists "tool approval" as an ask kind, so a supervisor could approve commands on a colleague's machine); the default of the host's setting; whether the local user sees that someone controls the runtime; who wins when both act.

**GA-14 — Todo offers, visibility and expiry.** CA.44 / CW.26 / `GLO`. Missing: where an offer waits and who sees it, the form of the accepting rule ("from whom, of what kind"), what the sender is told, expiry; where the switch "visible in another team" is stored (host setting? per quest?). CA.19: what happens to a command after its 7 days. CI.6: what happens to an invitation after 7 days.

**GA-15 — The team's configuration.** CS.3 … CS.6, CI.15. Missing: which keys the team owns and which it "only suggests" (CS.5), where the copy for offline starts is kept (CS.4 — it holds provider configurations; secrets are references, good), and what a runtime in the home team of quest A uses when its person belongs to two teams with different allowed providers.

**GA-16 — Device pairing as a procedure.** CI.18: "enrolled once, from inside, by its user". Missing: inside what (the VPN — then CK.12's check is a precondition, not a convenience), with which program, where the key is kept on the device, expiry and rotation, pairing of a desktop machine that is off the VPN (T5 demands "from a paired device" for machines too), and how a browser is "a device".

**GA-17 — Reaching a person who is away.** CK.11: "looking at what is going on and answering questions while away is what the application is for"; CM.6: "A notification is not pushed to a device while its user is active on another one". Nothing says how a phone whose application is closed learns of an ask — a push service of the platform vendors is neither in scope nor out of scope, and with CR.46 the phone has no runtime while it is not connected.

**GA-18 — Non-functional expectations that are missing altogether.** `NFR` says "none carries a number the sources do not give"; the Blueprint will need at least a statement (a number, or "not stated") for:
- performance: start time of a runtime, delay of streamed events, the "bound" of CP.6, the size CU.7 keeps;
- capacity: runtimes per machine, runs per runtime, members and runtimes per team, teams and users per account;
- limits: the size limit per file and the quota per team (CV.2), the quotas per account (CA.27), message size;
- availability of the tac server, backup and restore of its store, behaviour of clients during its restart;
- privacy: e-mail addresses and display names are stored (CI.3, CI.14) while `USR > USR-TEAM` says "No e-mail address is stored" for the review team; deletion and export of a user's data; what the trail may contain;
- audit: who did what by remote control, who freed a lease, who overrode a precondition (CR.13 "the override is recorded" — where?), who took a default (CP.20);
- observability: logs of the tac server and of a runtime (CP.2 "writes its log to standard error" only);
- supported versions of Node, Flutter, the operating systems (N-27 names the three systems only), browsers;
- accessibility and languages of the UI components;
- cost: "usage and cost are shown per provider" (CS.14) and "out of budget" (CM.2) — a budget exists nowhere.

**GA-19 — First version or later: not said.** CR.30 ("This comes after the native transports"), CR.31 ("This comes late") — inside the first version or after it? CS.12 (which of some twenty providers), CS.16 ("Two agent libraries are evaluated" — which two, and is the evaluation a deliverable?), CS.18; CR.45 (an "option"); CW.12 (which package registries), CW.16; CQ.6 … CQ.8 (repository quests: all of it in the first version?); CA.33 (backend migration); CT.10 (TomSpecs tools — built here or in `tom_specs`?); CU.15 (all screens in three widths); the Telegram-like channels of CM.6 ("the next channel" — which channels exist in the first version?).

**GA-20 — Deliverables without an item, and items without a deliverable.** `DEL`: "What is delivered is the code of the units (`NFR > NFR-GEN`) and the documents of N-30." Not among the units: the conformance suite (CL.6), the VS Code extension as a host on the new line (D-41; the split is "in scope" by `SCO > SCO-IN`'s last row), the program for phones and browsers (`GA-1`), the tac server's command line and administration interface (CI.20, CA.27 — inside G-2?), the migration between backends (CA.33), the merge drivers (E-5, CQ.6), the gallery (inside G-6, fine), the successor of `tom_vscode_scripting_api` (CL.10: G-4?). R-23 speaks of "a command line" as something to generate — which command line? Not among the documents of N-30: the security model that CI.19, N-21, CA.30 and R-22 all defer to; a setup guide for device pairing; the administration guide of the tac server beyond "setting up".

**GA-21 — `DEL` has no acceptance and no first usable state.** "the order is the one that reaches the finished, whole product fastest" (D-45), "built in one go" (D-21, D-32). There is no statement of what "finished" is checked against (which topologies and flows must run), and no intermediate state anybody uses, although R-6 and R-7 name exactly that as risks.

**GA-22 — Users and stakeholders that act in the items but are not in `USR`.** The **coordinator** of a review round (CV.12); a **quest member** (CQ.6, CQ.7); whoever **operates the program for phones and browsers** and the always-on machine (U-7 administers the tac server only; U-11 is a quest); a **developer of a web application that is not Flutter** (PQ-28); a **developer outside this workspace** who uses tac or an SDK alone (R-14's trigger; CA.25); the **person asked from outside the team** (L-3, later); the **providers and vendors** whose interfaces the transports rest on (R-5) as dependencies. U-2 has no statement of which application they use (`AN-36`).

**GA-23 — No item cites a user group, a vision statement or a problem.** U-1 … U-13 and V-1 … V-8 are each cited exactly once in the whole document — at their definition (U-7 only inside PQ-32). P-1 … P-14 likewise. The Blueprint cannot tell which capability serves whom; e.g. nothing ties CW.11 to P-7 or CK.11 to U-5.

**GA-24 — PQ-5 and PQ-11 are cited nowhere.** `ABOUT > ABOUT-READ`: "`PQ-1` to `PQ-23` are answered and taken into the text". PQ-5 and PQ-11 appear in no item, decision or contradiction. Either they changed nothing (say so in `DEC`) or their effect lost its source.

**GA-25 — Items whose source is weak or missing.** CQ.5 (stated only in the superseded S20; marked `___check here___`). The screen inventory SC-1 … SC-29 ("a first pass from the names of the extension's views and handlers, not yet from their code"). CA.40 … CA.43 and CW.25 rest on PQ-23 alone, CP.31 … CP.34 on PQ-6 alone, CP.35 on PQ-21 alone — fine as sources, but S1 was not updated, so "Where two of them disagree, S1 wins" (`SRC`) is no longer true for them; say that a PQ answer wins over S1. The undated "S9 … some claims rest on secondary sources" stands behind R-4, R-5, R-10.

**GA-26 — Messaging: what a user would look for.** Editing and deleting a message, search, attachments beyond blobs, who may create a conversation "among several members", conversations across teams (CI.12 allows "a message into one of its conversations"), what a removed member still sees (CI.9), and what "kept for one year" means for a conversation attached to a quest that runs longer (CM.11).

**GA-27 — The review exchange when something is missing.** CV.12: a member who never returns a copy; the coordinator's runtime offline when copies return (the blobs live 7 to 30 days); which repository and which lease "commits there" uses (CV.12 step 3, against CW.5); a reviewer who is not in the team (L-3 is later, so every reviewer is a team member — say it in CV.12); the relation of the review round's "member id" (CP.13) to the tac user id.

**GA-28 — Processes, roles and profiles in a team.** CS.3 puts "role types, process definitions, prompt templates" in the repository — which repository when a quest works on many (CR.35)? CR.12 pins "the revision of the process definition" — a git revision, a hash? CR.22: "the todo's choice wins over the item's" — and the team's allowed providers (CS.6) win over both?

**GA-29 — Errors of the runtime itself.** CR.23 names "failed with a retry possible". Missing: what a host shows and can do when the runtime process dies (CP.2), whether executions resume after a restart (an ask does, CP.9; a running tool loop?), and what of a half-done execution is kept.

**GA-30 — The split.** `SCO > SCO-IN`: "no area of its own". D-40, D-41, N-32, N-33, R-1 and `DEL` describe how the extension is kept stable, but no item says what the extension is afterwards (which views call the runtime directly, CP.1 "Inside VS Code the extension calls the runtime directly"; T1 "inside the extension" — so in VS Code the runtime is not a process of its own and CP.2 does not apply), nor when the old line ends.

---

## 4 Structure and readability

**ST-1 — The status is stale.** `ABOUT`, status: "its questions `PQ-24` … `PQ-33` are open"; `ABOUT > ABOUT-READ`, PQ row: "`PQ-24` to `PQ-33` are the open questions of round 3". All ten carry an answer. Each block also still has "*Assumption until answered*". After applying: remove the ten blocks, move their decisions to `DEC` (new ids from D-61; the heading "Decisions from the answers to the questions `PQ-1` … `PQ-23`" needs a sibling), cite them as sources like the earlier ones.

**ST-2 — Three `___check here___` marks are left.** Before the screen inventory (`CLI > CLI-SCREENS`, line 1250), in CI.19 (`TAC > TAC-CRYPT`), and after CQ.8 (`PAR > PAR-QUESTS`, signed "— `agent_spec_author`"). The first and third are author's remarks inside the text; turn them into a question or a plain statement of standing.

**ST-3 — History in a document that "states the idea as it stands".** Places that tell what was, not what is:
- CI.19: "The earlier decision made end-to-end encryption mandatory with the relay (S1 § 7.8, CQ-10); with the runtime host server for phones …", and the quoted instruction of the product owner.
- CA.8: "The word 'session' is not used for this"; CA.9: "The protocol as built has two more kinds … they are not used for now"; CA.16: "The declared units and infrastructure resources of the protocol as built … are not needed"; CA.27: "(the protocol as built says 'customer')"; CA.39: "What the coordination protocol as built (`tac/1.0`) calls an 'agent group' … It has nothing to do with how a runtime works with its models …" (six sentences of an item about team runtimes); `GLO` team runtimes: "This replaces 'agent group'".
- `PAR > PAR-APPROACH`, lead-in: "All of the approach is decided: the parts the concept only proposed (…) are confirmed, with a strict mode added".
- `TAC > TAC-PEOPLE`, lead-in: "`tac/1.0` knows runtimes only."
- `RISK`: "**Risks the first question round added.** (They are numbered after the dependencies below, since the numbers before them are taken.)"
- CP.7, CP.8: "This shape is a proposal, not a decision: the product owner's direction is that …".
- CR.45: the argument why unloading is not needed.
- `TAC > TAC-WEBWORK`: "**Differently from the requirement:**" twice (legitimate, but belongs in `CON`, X-3).
- O-4: "are removed"; N-13: "no longer renewed" (harmless).
- `NFR > NFR-GEN`: "`tomspecs` 0.17.0 in `$TOM_BINARY_PATH/darwin-arm64/`, asked on 2026-11-19" — a dated snapshot of tooling in a section about the product.
- **Proposal:** one subsection in `LAND` "What `tac/1.0` has that the product does not use" (session record, units, infrastructure resources, agent group, customer) and the items state only the product; `DEC` and `CON` are the places for history.

**ST-4 — Ids out of order, and section numbers that do not count.** CP.35 stands between CP.10 and CP.11; CI.20 between CI.15 and CI.16; CA.39 … CA.44 before CA.36 … CA.38; D-60 between D-56 and D-57; R-22 … R-24 before R-15 … R-21. Section numbers "3.0", "3.0.1", "9.4.1", "11.1.1". No id is defined twice and none is used without a definition, except the source-internal ones of `ST-11`.

**ST-5 — Capability areas and sections do not match.** `ABOUT > ABOUT-READ` defines thirteen areas; the sections mix them: `RT` holds `CR`, `CP`, `CT` and `CS` (sixteen subsections, about 150 items — a third of the document's capabilities); `CS` is split over `RT-CONFIG`, `RT-SECRETS` and `RT-PROVIDERS`; `CA` items sit in `TAC > TAC-PEOPLE > TAC-GROUPS`, `CI` items in `TAC > TAC-CRYPT`; `CQ` in `PAR`. **Proposal:** split `RT` into "runtime core" (`CR`), "protocol and hosts" (`CP`), "tools and MCP" (`CT`), "configuration, secrets and providers" (`CS`) as top-level sections, and move `TAC-GROUPS` under `TAC-COORD`.

**ST-6 — `NFR` repeats the capabilities.** N-1 = CP.25; N-2 = CP.26; N-3 = CP.24 + CP.28 + CP.29; N-4 = CA.37 + CA.38; N-5 = CT.2; N-6 = CT.15; N-7 = CP.30; N-11 = CA.31; N-12 = CA.32; N-13 = CA.13; N-14 = CS.4; N-16 = CM.13; N-17 = CS.7 + CS.8 + CS.11; N-18 = CT.11; N-19 = CI.10 + CK.5; N-20 = CI.16 + CI.17; N-22 = CI.6; N-23 = CR.24; N-25 = CU.2 … CU.4; N-26 = CL.1; N-31 = CL.6 + CL.7. Twenty-one of thirty-four expectations are restatements, some with a different wording (`IC-34`), while the expectations a Blueprint looks for are absent (`GA-18`). **Proposal:** keep in `NFR` what is a quality with a measure; let the rest be a reference.

**ST-7 — Other statements made several times.** "A runtime is started by its host and ends with it; the server starts one runtime per connected application, ending with the connection": `GLO` runtime, `GLO` host, CR.44, CR.46, T8, the paragraph under the topologies, D-15, D-52, X-12. A todo's resources and the quest's list as fallback: CR.35, CW.8, CW.24, D-17 (CR.34 = CW.24's second sentence). The resource and its name: `GLO` (three entries), CA.9, CA.10, CA.41, CA.42, D-59. Visible: `GLO` and CA.44 word for word. Todo offer: `GLO` and CW.26 word for word. Execution: `GLO`, the paragraph in `PAR > PAR-APPROACH`, CW.2. Remote control only in the home team where the host allows: CI.5, CI.13, CK.5, N-19, D-25, `GLO` visible, CA.44. No short process: CR.14, O-9, D-48. Copilot only through direct calls and its SDK: O-4, CS.13, D-7. R-12 and R-24 are one risk. CP.16 = CI.11 (first clause). Each copy is a place that can drift — several already have.

**ST-8 — "First version" and "first delivery".** 28 and 6 uses for what seems to be the same thing (CL.1: "All nine are part of the first delivery"; CA.26: "All three are part of the first delivery"; D-47, D-50). Neither is defined, and there is no one list of what the first version contains; it has to be collected from `SCO-LATER`, the "later" marks in T6 / T7 / F9, and adverbs ("comes late", "an option") in single items. See `ID-1`.

**ST-9 — Words with several senses.**
- **notification:** a live message between runtimes (CA.19); a message kind from a runtime to users (CM.2); what a host shows the user (CP.10, CP.13, CR.36); the done notification (CR.21); a push to a device (CM.6).
- **command:** from a host to its runtime (CP.3); a stored message between runtimes (CA.19); a message kind (CM.2); a shell command (CT.1 "running commands").
- **strict:** a tac server's identity setting (`GLO` strict server) and a repository's mode (`GLO` strict mode); CI.5 has both in one table row ("strict or worktree mode per repository").
- **member:** of a team; of a review round (CV.12 "every member"); of a quest (CQ.7).
- **service / server:** "tac service" (the program, G-2), "the local service", "the tac server", "the Tom Secrets Manager service", and now "web runtime service"; `GLO` regulates "server" only.
- **process:** a way of working, and an operating-system process (handled in CP.9 and N-15 by "operating-system process", not in CP.1, CP.2, CR.38, CA.8).
- **reminder:** of the queue (CR.19) and of messaging (CM.4).
- **conversation**, **item**, **relay**, **session**: `AN-11`, `IC-29`, `AN-21`, `AN-18`.

**ST-10 — Glossary entries that explain by analogy or by reference.** run: "A queue that executes todos and prompts, as the term is used in the VS Code extension" — a reader of the Blueprint does not know the extension; CR.8 / CR.9 say more (a run follows at most one process; `default` follows none). quest: "like a team's area in a department". host: four sentences, one of them about the review application. worktree mode: "(… also **change-branch mode**)" — a second name for one thing, used once more in CW.2.

**ST-11 — Source-internal ids that `ABOUT > ABOUT-READ` does not explain.** `TQ-n` and `C-4` (S21: "S21, C-4" in CA.2 and CA.39 — TQ is explained in the `SRC` row, C-4 nowhere); `BP-7`, `BP-10`, `BP-11`, `BP-12`, `BP-18`, `IDEA-6`, "part-claims", "part-messages" (S6); `RT-n` and `RS-n` (explained only in the lead-in of `DEC`); `DPMESSAGING-2` (S13); "S4, note a … n".

**ST-12 — `E-n` and `R-n` each carry two kinds of thing.** E-15 … E-18 ("Who waits for this") are not "a fact about what exists today" and repeat U-9 … U-12. R-15 … R-21 are dependencies under the risk prefix, which forces the explanation in `ABOUT > ABOUT-READ` ("`R-1` to `R-14` and `R-22` to `R-24` are risks, `R-15` to `R-21` dependencies"). `P-n` is split over two sections the same way. New entries should not continue this.

**ST-13 — Topologies and generation units are filed under non-functional expectations.** `NFR > NFR-TOPO`, `NFR > NFR-TOPO-FLOWS`, `NFR > NFR-GEN`. They are architecture and delivery; a reader looking for T8 or G-2 does not look in `NFR`. Proposal: a section "System shape" (topologies, flows) before `NFR`, and the units in `DEL`.

**ST-14 — The screen inventory.** SC-1 … SC-29 sit after CU.15 with a paragraph that is not an item. Column "Component group" holds "partly host's own" (SC-24), which is an outcome, not a group; SC-21 names a part "diagnostics" that no group of CU.6 has. SC-27 … SC-29 start with "—" in the column "Extension screen".

**ST-15 — Long table cells that hold several statements.** T8 ("What runs where": five sentences, three of them decisions), the GitHub row of CA.26, `GLO` visible, `GLO` resource name, D-36, D-49, D-58. Each statement in them has no id of its own and cannot be cited.

**ST-16 — Items that should be split.** CA.39 (definition of team runtimes; personal team; history of "agent group"; what an agent is; where a runtime reads and writes) — five topics. CW.5 (shared lease; the integration step; fencing token; strict mode; the rule for repositories without working trees). CQ.6 (six provisions, each a requirement). CR.5 (review rounds, expression language, prompt assembly, the Claude Code features). CI.10 (two identity levels; the server setting; the rule for several users; the rule for the internet). CA.30 (what the relay is; its authentication; the open point).

**ST-17 — Question blocks interrupt lists.** PQ-25 between CR.18 and CR.19, PQ-32 between CS.9 and CS.10, PQ-24 between CP.21 and CP.22, PQ-31 between CA.17 and "Messages between runtimes", PQ-27 between CA.20 and CA.21, PQ-29 between CA.39 and CA.40, PQ-30 between CI.4 and CI.5. Blank lines left by earlier blocks split lists in the same way (before CR.13, CR.14, CP.9, CP.30, CI.11, CK.9, CK.10, CW.25, CW.26, X-8, X-13). Harmless in rendering, but each makes a list restart in a strict Markdown reader.

**ST-18 — "Three components and two sets of libraries".** `VIS > VIS-SYSTEM` counts the system that way; with the program for phones and browsers (already "in the first version" before PQ-28) it has four programs, and with PQ-28 three sets of SDKs. The table should list every program that runs somewhere: the runtime, the local tac service, the tac server with its relay, the program for phones and browsers, trc — the topologies speak of all five.

---

## 5 Improvement ideas

**ID-1 — One register "what the first version contains".** A table in `SCO` with every capability group and every item that is not plainly in: *first version*, *first version, late*, *option*, *later* — replacing the scattered adverbs (CR.30, CR.31, CR.45, CS.16, CS.18, CW.16, CW.25, T6, T7, F9). Why: the Blueprint's scope and the acceptance of `DEL` (`GA-21`) can then be read off one place, and `ST-8` disappears.

**ID-2 — The lease rules as one matrix.** Rows: the lease asked for (shared, exclusive, integration); columns: what is already held on an overlapping resource (nothing, shared, exclusive, integration); cells: given or refused. Beside it one line per mode (strict, worktree) saying which lease an execution takes when. Why: it removes `IC-1`, makes `tac/2.0` testable from the Project Idea, and replaces five prose statements that already disagree.

**ID-3 — A table of credentials.** One row each for: the account's access key, the invitation's one-time password, the team token, the device key, the relay's key, the MCP server's bearer token, the approval by Tom Secrets Manager, the repository server's own credentials. Columns: who issues it, to whom, where it is kept, what it proves, how it is withdrawn. Why: `IC-18`, `IC-19`, `GA-12` and `GA-16` are all one missing picture, and the security model that four items defer to starts from exactly this table.

**ID-4 — One grammar for everything that is addressed.** The product owner's `git:` prefix (PQ-31) is the third prefixed notation beside `tsm:` / `os:` / `env:` / `file:` and `msg:`. Define a single form `<scheme>:<body>` and give the addresses of CW.18 one too (`todo:<quest>/<id>`, `run:<quest>/<run>`, `user:<id>`, `quest:<team>/<quest>`). Why: tools, todos, messages and the coordination page can then link anything to anything, new kinds of resource come "as they come" without a protocol change, and CW.18's "one way of addressing" gets a written form.

**ID-5 — A capability table per backend.** Rows: presence, leases, the integration queue, endpoints, commands between runtimes, messaging, documents and review, routing of asks to other people, the team's configuration, remote control, identity (who is a member, who is a team owner). Columns: local, GitHub (personal team), GitHub (team of several), tac server. Cells: yes / no / by agreement. Why: PQ-29's answer cannot be applied without it (`AN-30`, `AN-31`), it is what CA.37's capability blocks announce, and a user choosing a backend needs precisely this.

**ID-6 — A run that is held says so, everywhere.** With PQ-24 (b) the most common reason for "nothing happens" becomes an unanswered ask. Give every run a visible *held by* (the ask, the lease, the secret, the time, the other todo — `AN-4`), with since-when and who can release it; show it on the run tab, in trc's overview and in the state a runtime registers (CA.5); let the ask's deadline and default (CP.8) be set per process step. Why: it turns the cost of answer (b) into something a supervisor sees at a glance, which is what trc is for (U-5).

**ID-7 — A first usable state inside "one go".** Without fixing an order (D-45), name one thin path that is run end to end as early as possible: T1 with the runtime inside the new extension line, the local tac service, one claim and one integration step on one repository in each mode (F1, F2, F3, F8). Why: R-6, R-7 and R-3 all say that nothing is used before everything exists; one path used daily by the product owner finds the wrong assumption while it is cheap, and it is the natural first acceptance of `GA-21`.

**ID-8 — A record of what people did to runs that are not theirs.** Every action through remote control, every freed lease, every overridden precondition (CR.13), every default taken (CP.20) and every accepted todo offer is written to one journal per quest, with the person and the runtime. Why: a team will only switch remote control on (CK.5's setting) if it can see afterwards who did what; the document already promises "recorded" in three places without saying where.

**ID-9 — TypeScript and JavaScript as one client SDK.** The document counts them as two of nine languages (CL.1, G-5) but treats them as one in CL.7 and in the product owner's own words ("a Dart and a JS/TS web runtime client SDK"). One package, written in TypeScript and usable from JavaScript, makes it eight languages. Why: one conformance run, one convenience layer and one publication less (R-12, R-24), at no loss for a JavaScript user.

**ID-10 — Trace every capability to whom it serves.** Add to each capability group (not each item) a line "serves: U-…, V-…, solves: P-…", and to each user group in `USR` the groups that serve it. Why: today no U, V or P is cited anywhere (`GA-23`); the Blueprint's requirements need a stakeholder each, the reviewer can see at once which user group has thin coverage (U-2 and U-7 do), and deferring a feature shows whose need is deferred.

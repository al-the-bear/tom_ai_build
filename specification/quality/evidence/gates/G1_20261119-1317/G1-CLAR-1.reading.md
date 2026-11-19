# G1-CLAR-1 — reading: the clarifications of the Project Idea and whether one blocks Phase 2

Inspected: `tom_ai/ai_build/specification/phase1_project_idea/project_idea.ai_runtime.md`
as in the working tree (revision `33c15b36…`, 2,473 lines), not changed.

## What the project's clarifications are

- **Clarification files:** none for this project. `_ai/clarifications/` holds
  six files (tom_core, the buildkit consolidation plan, tom_brain, two of
  tom_forge, d4rt); none names ai_runtime. The specification root has no
  clarifications folder.
- **Question blocks:** 19, `PQ-1` … `PQ-19` (tomAi_mdQuestions: total 19,
  open 0). Every one carries an answer of the product owner. No round has
  taken the answers into the text.

## Classification of the answers

Kinds: **(1)** a plain choice of an option; **(2)** a choice with a condition
or an addition that changes what the document says; **(3)** an answer that
does not decide (asks back, asks for an explanation, defers, or contradicts).

| Question | Topic | Answer (quoted in short) | Kind | Settled? | What it does to the text |
| --- | --- | --- | --- | --- | --- |
| PQ-1 | Product owner and review team | "(a), owner and reviewer am I, alexis" | 1 | yes | `USR > USR-TEAM`: the one member named; display name and role are not given (the question asked for them) — a detail for the round |
| PQ-2 | A run and a changed process definition | "(a), usually the updates are intended to be used immediately" | 2 | yes | `RT > RT-RUNS`: pinned, taken over on confirmation; the remark makes taking over the expected case |
| PQ-3 | Preconditions of a step | "(a)" | 1 | yes | `RT > RT-RUNS`: declared and enforced |
| PQ-4 | A short path for small changes | "File this with concrete proposal in the tom_specs quest … Check the tom_specs process for the current change/revision mode" | 2 | yes | not part of this product; the statement leaves the Project Idea; **an action is owed:** a proposal todo in the tom_specs quest |
| PQ-5 | The shape of the protocol's conversation and questions | "I think we have two ways today: (1) review outside of a turn … (2) the ask tool … (3) … askInMd … Isn't that already the three things? … What are we missing?" | **3** | **no** | asks back; it reads the three shapes as the three ways of asking, while the question was about the conversation model (thread, turn, item), one envelope for every question, and when a run unloads |
| PQ-6 | Migrating the workspace files | five numbered rules of the owner's own (hosts install and offer the update; a too new runtime disables features or refuses; upgrade only when asked; an older workspace is migrated or the runtime downgraded; runtime and workspace usually upgraded with the first host) | 2 | yes | `RT > RT-VERSIONS`, `RT > RT-INSTALL`: the rules replace option (a)'s wording; the downgrade of a runtime is new |
| PQ-7 | Which languages come first | "(b)" | 1 | yes | all nine languages in the first delivery; changes `CLI > CLI-PACK` and `DEL` |
| PQ-8 | Which components are built first | "We build in the order that will get us to the finished full product fastest. We should consider working in parallel … verify this is complete in the todos queued … If something is missing, add a vscimpb* todo to vscode extension" | 2 | yes, as a principle | no fixed order of the component groups; two runs in parallel; **an action is owed:** check the vscode_extension todos for waiting on a blocked todo and continuing when it is unblocked |
| PQ-9 | How the supervision application connects, and where it runs | "(b), I want to make sure we get the architecture right for apps on phones and tablets … we also need to cover the internet case … there must be some pairing process to get a device-specific key" | 2 | yes | the phone in the first version: pulls the server-side runtime (`SCO > SCO-LATER`, L-8; T8) and the pairing of devices (L-6) into the first version, the internet case included; a check of the VPN from iPhone and Android is asked for |
| PQ-10 | The GitHub backend in the first delivery | "(a)" | 1 | yes | three backends stay, as the text has it |
| PQ-11 | Customers, teams and agent groups | "Explain this in more details, how do agent groups compare with our quests with their run and prompts? I can only decide what we need here if I understand what you are proposed in detail. What IS an agent group?" | **3** | **no** | asks for an explanation before deciding |
| PQ-12 | What an owner of a team may do | "(a), the last row depends on the result of the previous question. I'd say team member can create or delete their own agent groups, but this depends on our definitions" | 2, one row **3** | all rows but the last | the table stands; the row on agent groups is open with PQ-11 |
| PQ-13 | Identification without an invitation | "(a), setting per server in the server configuration, a server either only works with strict invitation/identity check or completely without it … identification must be strict for all internet access, non-configurable … (think if internet access is secured enough with HTTPS + the token)" | 2, one point **3** | yes, except the owner's own question | the setting is per **server**, not per team; strict for every access from the internet; changes `TAC > TAC-PEOPLE` (CI.10); the owner asks back whether HTTPS and the token are enough from the internet |
| PQ-14 | The integration step and what goes with it | "(a), but (1) must have a strict mode that blocks all the time, just as we need to have a non-worktree mode which always requires strict locks" | 2 | yes | all nine confirmed; a strict mode is added to `PAR > PAR-APPROACH` |
| PQ-15 | Licence and publication | "(a), for now we publish only to pub.dev and to our tom_binaries repo. We'll later publish to more official repos and the app stores." | 2 | yes | BSD-3; publication narrowed to pub.dev and tom_binaries for now |
| PQ-16 | A runtime server and the lifetime of a runtime | "(a), however there can already be a server for a web application or apps that hosts one runtime per client in the current model … Fully standalone runtime will come later" | 2 | yes | T6 is later; a permanent server that hosts one runtime per client is part of the model (it is what PQ-9 needs) |
| PQ-17 | Mappers or hand-written code, per unit | "… I actually suggest to name at the beginning of phase 4 which mapping we need for each areas … and see if there are missing generators we should build in phase 4 … I'd like to be able to run through regeneration quickly" | **3** (defers) | deferred to Phase 4 | not option (a): the code generation of the TomSpecs process **is** used; changes `NFR > NFR-GEN` ("implemented by hand … outside the code generation") and D-36 |
| PQ-18 | Standard descriptions the project publishes | "Let's decide this in phase 4, we also need API docs for the SDKs and (handwritten) user and programmer's guides." | **3** (defers) | deferred to Phase 4 | the API documentation and the guides are added to what is delivered |
| PQ-19 | How the specification is made | "(c), make suggestions if you think we can skip some of the steps of a phase, but we should go through the normal process with all its phases." | 2 | yes | the full TomSpecs process; reverses D-37 and D-36, resolves X-7; changes `DEL` ("never all of them") |

**Counts:** kind 1: 4 (PQ-1, PQ-3, PQ-7, PQ-10); kind 2: 11 (PQ-2, PQ-4, PQ-6,
PQ-8, PQ-9, PQ-12, PQ-13, PQ-14, PQ-15, PQ-16, PQ-19); kind 3: 4 (PQ-5, PQ-11,
PQ-17, PQ-18), plus one row of PQ-12 and one point of PQ-13.

PQ-19 was listed as a candidate for "contradicts a recorded decision". It does
reverse D-37, but the question asked exactly whether that decision still
holds (X-7, "or the decision has changed"), and the answer says so. It is a
decision, not an open point.

## The open clarifications, and whether each blocks Phase 2

| Open | Blocks Phase 2? | Reason |
| --- | --- | --- |
| **PQ-11** — what an agent group is, and how customer, team and agent group are tied | **yes**, for the parts that rest on it (borderline for the Blueprint as a whole) | The term is in the glossary and in 31 places (`TAC > TAC-COORD` CA.2, `TAC > TAC-PEOPLE` CI.1, the topologies T3 … T5). The Blueprint's information model and its security and access model need the three records and who creates them; the owner says he cannot decide because the document does not explain the term ("What IS an agent group?"). The Blueprint could carry the proposal as a question of its own, but it would then build two of its models on a concept its owner has not understood. The explanation costs one question round. |
| **PQ-12**, last row — who may create and delete agent groups | with PQ-11 | follows from PQ-11 |
| **PQ-5** — the three protocol shapes | no | The question was misread, so nothing is decided. The shapes are detail of the interface specification; the Blueprint can state the protocol's parts (commands, numbered events, reverse requests, asks) without them. It needs asking again, better explained; a Blueprint round can do that. |
| **PQ-13**, the owner's question — is HTTPS and the token enough from the internet | no | A security analysis the Blueprint's security model, and after it the security document, give. With PQ-9 it gets weight: phones reach tac from the internet. |
| **PQ-17** — which mapper per area | no | Deferred by the owner to the start of Phase 4. The Blueprint's unit register lists the units; the mapper per area is named in Phase 4. |
| **PQ-18** — the standard descriptions | no | Deferred by the owner to Phase 4. |

## The text against the answers

The answers are not in the text, and several of them change statements the
Blueprint will cite. Where the text now says the opposite of its owner's
answer:

| Statement in the text | Where | The answer |
| --- | --- | --- |
| "The specification is made in a run of the idea-to-todos process on the concept, not in the TomSpecs process." | `DEC`, D-37 | PQ-19 (c): the TomSpecs process with all its phases |
| "a detailed document only where a component needs one. The runtime is implemented by hand." / "never all of them" | `DEC`, D-36; `DEL` | PQ-19 (c): all phases, all documents unless a skip is suggested and accepted; PQ-17: generation where a mapper fits |
| "**Unresolved.**" | `CON`, X-7 | PQ-19 resolves it |
| "the runtime is implemented by hand from it, and the clients' protocol layer is generated …, outside the code generation of the TomSpecs process" | `NFR > NFR-GEN` | PQ-17: the mappings per area are named at the start of Phase 4, missing generators are built, regeneration is wanted |
| L-8 "A server-side runtime for web, phone and tablet clients" deferred; T8 "(later)"; "T7 and T8 are later" | `SCO > SCO-LATER`; `NFR > NFR-TOPO` | PQ-9 (b): the phone in the first version, with the internet case; PQ-16: a permanent server hosting one runtime per client is in the model |
| L-6 "Pairing of devices and end-to-end encryption" deferred | `SCO > SCO-LATER` | PQ-9: "there must be some pairing process to get a device-specific key" |
| "There are two levels of identity, and both are built" (identification as a level of a team) | `TAC > TAC-PEOPLE`, CI.10 | PQ-13: open or strict is a setting of the **server**; strict for all access from the internet, not configurable |
| the first delivery of the client packages left to the question | `CLI > CLI-PACK`; `DEL` | PQ-7 (b): all nine in the first delivery |
| the statement on a short process for small changes | `RT > RT-RUNS` | PQ-4: not this product's; a proposal in the tom_specs quest |

The scope (`SCO > SCO-IN`, `SCO > SCO-LATER`), the decisions (`DEC`), the
contradictions (`CON`) and the delivery (`DEL`) are what the Blueprint cites
first. Two entries of the deferred list move into the first version, two
decisions are reversed and one contradiction is resolved by the answers, and
none of it is in the text.

## Verdict

**Fail.** By the item's `pass` text ("None blocks Phase 2"):

1. PQ-11 is open and holds up the Blueprint's information model and security
   and access model (borderline: the Blueprint could ask it again itself, but
   the owner's answer says the term is not understood, and a round is needed
   anyway).
2. The document's text contradicts its owner's answers in statements the
   Blueprint cites (scope, decisions, contradictions, delivery). A Blueprint
   written from this text would start from two reversed decisions and a scope
   that leaves the phone and the pairing out.

**Remediation:** a second question round of Phase 1 takes the 19 answers into
the text, explains the agent group and asks PQ-11 (with the last row of
PQ-12) again, asks PQ-5 again in plain terms, and carries out the two actions
the answers ask for (PQ-4, PQ-8). PQ-17 and PQ-18 are recorded as deferred to
Phase 4; the owner's question in PQ-13 goes to the Blueprint's security model.

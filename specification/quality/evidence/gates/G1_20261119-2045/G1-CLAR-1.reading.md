# G1-CLAR-1, run 2 — reader's note

Item: "No open clarification prevents Blueprint work." Pass: "None blocks
Phase 2." The queries are in `G1-CLAR-1.questions.txt`.

## 1. Open questions and clarification files

- The document holds no question block: `tomAi_mdQuestions` answers 0 of 0.
- `_ai/clarifications/` holds six files, none for this project.
- The project's clarifications are the 23 questions PQ-1 … PQ-23, all
  answered, kept in `phase1_project_idea/01_02_Questions Round/answers.md`.

## 2. The 23 answers, each against the text

"Says it" means: the statement says what the answer says.

| Question | The answer, in short | Where the document states it | Says it? |
| --- | --- | --- | --- |
| PQ-1 | (a): owner and only reviewer is alexis | `USR > USR-TEAM` (paragraph and table); `ABOUT` (table, "Product owner and review team"); D-44 | yes |
| PQ-2 | (a): pinned, taken over on confirmation; "usually the updates are intended to be used immediately" | `RT > RT-RUNS`, CR.12 ("Taking it over is the usual case …"); D-46 | yes |
| PQ-3 | (a): declared and enforced, override recorded | `RT > RT-RUNS`, CR.13; D-46 | yes |
| PQ-4 | file a concrete proposal in tom_specs; look at its change mode | `RT > RT-RUNS`, CR.14; `SCO > SCO-OUT`, O-9; D-48. The todo exists: tom_specs `smallchange1_akss-short-change-process-proposal` | yes |
| PQ-5 | asked back: are the three ways of asking not already the three things? | `RT > RT-PROTO`, CP.8 ("The ways an agent asks today stay as they are: a review outside a turn, the tool that asks single questions, and questions inside a document"); asked again as PQ-21 | yes (section 3) |
| PQ-6 | five rules: install only when none is installed; a host too old for the runtime switches off or does not start; update only when asked; older files: migrate or go back to an older runtime; usually runtime and files are updated together | `RT > RT-INSTALL`, CR.42 (rules 1, 2); `RT > RT-VERSIONS`, CP.31 (2), CP.32 and CP.28 (3), CP.33 (4), CP.34 (5); `NFR > NFR-TOPO > NFR-TOPO-FLOWS`, F1 and F12; D-49; X-13; R-13 | yes |
| PQ-7 | (b): all nine languages in the first delivery | `CLI > CLI-PACK`, CL.1; D-50; R-12, R-24 | yes |
| PQ-8 | the order that reaches the full product fastest; two runs in parallel; verify the extension's todos, add one if missing | `DEL`, "The order of building"; D-45. The todo exists: vscode_extension `vscimpb179_akss-blocked-item-resumes-by-itself` | yes |
| PQ-9 | (b): phone and tablet in the first version; LAN, VPN and internet; check the VPN from iPhone and Android; secure, with pairing and a key per device | `CLI > CLI-TRC`, CK.10, CK.11, CK.12; `RT > RT-INSTALL`, CR.46; `TAC > TAC-CRYPT`, CI.18; `NFR > NFR-TOPO`, T5, T8; `NFR`, N-21; `SCO > SCO-LATER`, L-6, L-8; `VIS > VIS-GIVES`, V-7; D-51; X-14; R-22 | yes |
| PQ-10 | (a): the GitHub backend stays in the first delivery | `TAC > TAC-BACKENDS`, CA.26; D-47; X-11 | yes |
| PQ-11 | not decided: "What IS an agent group?" | settled by PQ-20 and PQ-23: `TAC > TAC-PEOPLE > TAC-GROUPS`, CA.39; `GLO`, "agent group"; D-24; X-5 | yes (through PQ-23) |
| PQ-12 | (a); the last row depends on PQ-11 | `TAC > TAC-PEOPLE`, CI.5: the table as asked; of its two rows on agent groups one is gone (declaring units and infrastructure resources) and the other keeps only "delete the team" as an owner's right; D-53 | yes |
| PQ-13 | a setting of the server, open or strict for everyone on it; strict for all access from the internet, not configurable; "think if internet access is secured enough with HTTPS + the token" | `TAC > TAC-PEOPLE`, CI.10; `GLO`, "open server, strict server"; `NFR`, N-19; D-54; the owner's question: `TAC > TAC-CRYPT`, CI.19, and `NFR`, N-21 | yes (section 3) |
| PQ-14 | (a): all nine parts; a strict mode that blocks all the time; without working trees always strict locks while a todo executes | `PAR > PAR-APPROACH`, the introduction, CW.5 … CW.15; `GLO`, "strict mode"; D-55 | yes |
| PQ-15 | (a): BSD-3; for now only pub.dev and the binaries repository | `NFR`, N-29; D-56 | yes |
| PQ-16 | (a): the runtime server is later; a permanent server that hosts one runtime per client is in the model | `RT > RT-INSTALL`, CR.46; `NFR > NFR-TOPO`, T6, T8; `SCO > SCO-LATER`, L-5; D-52; X-12 | yes, except one sentence (section 4) |
| PQ-17 | no option: name the mapping per area and per component at the start of Phase 4; build missing generators there; regeneration must be quick | `NFR > NFR-GEN`, "How the units are produced"; `CLI > CLI-PACK`, CL.4; `DEL`; D-57, D-36; R-23 | yes (section 3) |
| PQ-18 | no option: decide in Phase 4; API documentation of the SDKs and hand-written user and programmer's guides | `NFR > NFR-GEN`, last paragraph; `NFR`, N-30; D-57 | yes (section 3) |
| PQ-19 | (c): the TomSpecs process with all its phases; suggest steps to skip while proceeding | D-36, D-37; X-7; `DEL`, "The documents of the specification" | yes |
| PQ-20 | no option: no groups of agents; joining a server, then creating a team makes sense; AI state lives on the host's machine; one runtime per quest | `TAC > TAC-PEOPLE`, CI.20 (the sequence); `TAC > TAC-PEOPLE > TAC-GROUPS`, CA.39 ("every runtime calls the model APIs and the agent SDKs directly, serves one quest, and reads and writes the quest's files … on the machine of its host"); `RT > RT-HOLDS`, CR.6; D-59 | yes |
| PQ-21 | no option: an API with callbacks, the wire in JSON, object models from the existing schemas; unloading runs reasonable, perhaps not worth it | `RT > RT-PROTO`, CP.35, CP.7, CP.8; `RT > RT-INSTALL`, CR.45; D-58 | yes (section 3) |
| PQ-22 | (a): member id `alexis`, display name "Alexis", role "Product owner", no e-mail | `USR > USR-TEAM` (table; "No e-mail address is stored."); D-44 | yes |
| PQ-23 | (a): the team is the list; a resource is a repository or a part of one by a pattern; tac knows only what it granted; a runtime works with what its user can reach; work for another quest is a todo there | `TAC > TAC-JOBS`, CA.2; `TAC > TAC-PEOPLE`, CI.1; `TAC > TAC-PEOPLE > TAC-GROUPS`, CA.39 … CA.43; `TAC > TAC-COORD`, CA.3, CA.9, CA.11, CA.16; `PAR > PAR-CROSS`, CW.25; `GLO`, "resource"; D-24, D-59; X-15 | yes |

All 23 answers are in the text.

## 3. The answers that chose no option

| Answer | How the document carries it | Does what stays open prevent the Blueprint? |
| --- | --- | --- |
| PQ-5 / PQ-21, the protocol's shapes | Decided and stated: the link is an API with callbacks in both directions over a wire of JSON structures, and its records get object models from the workspace's schemas (CP.35, D-58); the ways of asking stay (CP.8). Left as proposals, each marked so: the conversation as thread, turn and item (CP.7), the one record for every question (CP.8), unloading a run (CR.45: "an option, not part of the first version unless measurement shows …"). "The interface specification settles the shape of a conversation on the wire." | **No.** The Blueprint states the architecture and the interfaces by kind: a runtime protocol with commands, numbered events (decided, D-12) and callbacks, and questions as stored records (decided, CP.9). The shape of the messages is the matter of the interface specification in Phase 3, and the owner said the details follow what the tools need. |
| PQ-17, mappers per unit | "How the units are produced is decided at the start of Phase 4 … not here"; the register names the units G-1 … G-7 with their technology and no mapper (`NFR > NFR-GEN`; D-57). | **No.** The Blueprint's register of generation units takes the seven units and their technology. Phase 2's gate checklist has no item on mappers (`G1-CLAR-1.questions.txt`, point 5). The risk of it is recorded (R-23). |
| PQ-18, standard descriptions | Decided in Phase 4; the documents delivered are listed now, with the API documentation and the hand-written guides (N-30; D-57). | **No.** The Blueprint names the deliverables from N-30; which standards describe the interfaces is a Phase 4 matter by the owner's decision. |
| PQ-13, the owner's question whether HTTPS with the token is enough from the internet | CI.19, marked `___check here___`, "An open point for the security model of the Solution Blueprint": it says what HTTPS, the team token and a device key protect against and what not, that the server is run by the team that uses it, and that with a server-side runtime "there is no second end to encrypt to". N-21 and L-6 point to it. | **No, borderline.** What is decided is enough to write the security model: strict identity and a paired device with its own key for all access from the internet (CI.10, CI.18, D-51, D-54). Whether end-to-end encryption is needed on top is a question the security model answers; the owner asked for it to be thought through, the document does that and gives a position, and the Blueprint puts the result to the owner. It would block only if the Blueprint had to wait for an answer before it could start, which it does not. |

## 4. The statements run 1 named

| Statement | Run 1 | Now |
| --- | --- | --- |
| D-36 | said the Blueprint is deepened and the runtime written by hand, against PQ-19 and PQ-17 | "written in the TomSpecs process with all its phases … the mapping per area and per unit is named at the start of Phase 4"; the earlier decisions are named under "Replaces or completes". Fixed. |
| D-37 | said the idea-to-todos run makes the specification | "made in a run of the TomSpecs process, through all its phases. Which steps of a phase can be skipped is suggested as the run proceeds". Fixed. |
| X-7 | resolved the other way | "**Resolved:** the decision has changed. The specification is made in the TomSpecs process with all its phases … The idea run on the concept is not started." Fixed. |
| `DEL` | planned detailed documents only where needed, no code generation | "The documents of the specification": all phases named, skipping suggested and decided by the owner, the mapping named at the start of Phase 4. Fixed. |
| `NFR > NFR-GEN` | "no mapper; by hand" | "How the units are produced is decided at the start of Phase 4"; "which are used, and which have to be built, is named at the start of Phase 4". Fixed. |
| `SCO > SCO-LATER`, L-6 | deferred the pairing of devices | L-6 is now only "End-to-end encryption between a device and a runtime"; "the pairing of devices is in the first version". Fixed. |
| `SCO > SCO-LATER`, L-8 | deferred the server-side runtime | L-8 is now "Webwork's own server side"; "the server-side runtime it will use is in the first version, for the supervision application". Fixed. |
| `NFR > NFR-TOPO`, T8 | "later" | "The supervision application on a phone or tablet uses it in the first version"; the line above the table: "T1 to T5 and T8 belong to the first version". Fixed. |
| `TAC > TAC-PEOPLE`, CI.10 | a setting per team | "a setting of the **server**, in its configuration, not of a team … Every access from the internet is strict, whatever the setting; that cannot be configured." Fixed. |
| `CLI > CLI-PACK` | Dart and TypeScript first, the others later | CL.1: "All nine are part of the first delivery". Fixed. |

**One sentence still stands against an answer.** `NFR > NFR-TOPO`, the
paragraph after the table: "On the always-on machine only the tac server runs
in the first version. (PQ-16)". The answer to PQ-16 adds that "there can
already be a server for a web application or apps that hosts one runtime per
client", and PQ-9 puts that server into the first version; T8 in the same
section says "the server runs permanently and starts one runtime per client",
as do CR.46, CK.10 and D-52. A server that runs permanently runs on an
always-on machine, and the document names no other machine for it. The
sentence has no id; every id-carrying statement on the matter agrees with the
answers. It does not block: the Blueprint cites T8, CR.46 and D-52. It should
be corrected when the document is next touched.

## 5. The three review marks

| Mark | Says | Blocks? |
| --- | --- | --- |
| `CLI > CLI-SCREENS`, before the inventory | the outcomes of SC-1 … SC-29 are a first pass from names, "each is decided when the screen is described" | no: the document says when it is decided (the screen descriptions, CU.12), and the rows have ids to decide on |
| `TAC > TAC-CRYPT`, CI.19 | the open point for the security model | no (section 3) |
| `PAR > PAR-QUESTS`, after CQ.8 | CQ.5 (one resolver for the place of a quest's and a personal file) is stated only in a superseded source and "should be confirmed with this section" | no: it is a statement the review of this document confirms or strikes; the Blueprint can take it as stated. It was not put to the owner as a question in either round. |

## 6. Clarifications the answers opened and nobody asked

Read for what an answer leaves undecided. Five points; none prevents the
Blueprint, each is something the Blueprint settles or asks itself.

| Opened by | What is not said | Why it does not block |
| --- | --- | --- |
| PQ-9, PQ-16 | on which machine the server that hosts one runtime per phone or tablet client runs in the first version, and whether it is the tac server's machine (see the sentence in section 4) | a matter of the Blueprint's topology and deployment; T8 and CR.46 say what the server does |
| PQ-14 | where the strict mode is switched on: per repository (as the working-tree setting, CW.2), per team or per todo. CW.5 says only "There is a **strict mode**" and when a repository is always in it | the rule that matters is decided (no working trees: always strict); the place of the setting is a detail of the requirement the Blueprint writes |
| PQ-6 | what a host does when the installed runtime is too old for it. The five rules cover a runtime too new for the host (CP.31) and files too new or too old for the runtime (CP.28, CP.33); a newer host on an older runtime is covered only by "A host offers updating the runtime" (CR.42) | follows the same pattern as CP.31; the Blueprint states it or asks |
| PQ-23 | the written form of a resource's name. CA.10 names a repository "by its identity (provider, owner, name)"; the owner's example, taken into CA.41, is `al_the_bear/ai_build` and `al_the_bear/ai_build#runtime/**`, without a provider | syntax, for the TAC specification |
| PQ-13, PQ-9 | how the key per runtime that an owner issues for the relay and the key of a paired device relate (CA.30 says so itself and assigns it to CI.19), and how a server tells access from the internet from access on the VPN | part of the security model the Blueprint writes |

Also read: PQ-4 and PQ-8 asked for actions outside the document; both todos
exist (`G1-CLAR-1.questions.txt`, point 4).

## 7. Result

**Pass.** No clarification is open: no question block, no clarification
file, all 23 answers in the text, every statement run 1 named corrected.
What the answers left to later (the protocol's shapes to the interface
specification, mappers and standard descriptions to Phase 4, end-to-end
encryption to the security model) is carried as such by the document and does
not prevent the Solution Blueprint.

Borderline, recorded: one sentence without an id in `NFR > NFR-TOPO` still
stands against the answers to PQ-16 and PQ-9 (section 4); CI.19 leaves a
decision to the Blueprint's security model that the owner will be asked to
confirm there.

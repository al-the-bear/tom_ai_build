# Project Idea — Tom AI Runtime

## <!--[ABOUT]--> 0 About this document

| | |
| --- | --- |
| **Artifact** | Phase 1 Project Idea (PI) of the TomSpecs project flow (`tom_specs_project_flow.md`, `PF-PHA-P1`) |
| **Product** | Tom AI Runtime (tar), Tom Agent Coordination (tac), Tom Runtime Control (trc), the client SDKs, the web runtime service with its client SDK{~~, and the Flutter UI components~>, the Flutter UI components, and the new VS Code extension as the VS Code host (-> D-73)~~} |
| **Spec root** | `tom_ai/ai_build/specification/` |
| **Product owner and review team** | alexis, product owner and only reviewer (`USR > USR-TEAM`) |
| **Sources** | section 1 (`SRC`); the three main ones are kept as snapshots in `sources/` |
| **Written by** | `agent_spec_author` |
| **Status** | Terminology agreed and taken in (2026-11-20, S21). Every answer of `PQ-1` … `PQ-33` is in the text. The text is completed from the quests `vscode_extension`, `webwork`, `tom_forge` and `al_the_bear` {~~(S22 … S27)~>(<- S22 … S27)~~} and read as a whole for consistency. Question round 4 is taken in: the answers to `PQ-24` … `PQ-33` are in the text and their question blocks are removed. {~~Open are the 26 questions of round 4, `PQ-34` … `PQ-59`, each standing after the item it asks about; among them~>Open are 33 questions, each standing after the item it asks about: the 26 of round 4, `PQ-34` … `PQ-59`, reworked in question round 5, and the 7 new ones of round 5, `PQ-60` … `PQ-66`; among them~~} what serves applications on phones, on tablets and in browsers (PQ-38, PQ-41, PQ-49): PQ-28 gave its names, not its design{++. Question round 5 reworks the text and these questions on the product owner's two instructions of 2026-11-25: the feature baseline of the first version (D-74) and the new VS Code extension, a copy of the old one in `tom_ai/ai_build` that takes its place (D-73) (<- S31)++} |
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
| **`R-<n>`** | A risk, with what would trigger it, or a dependency (section 14). {~~`R-1` to `R-14` and `R-22` to `R-28` are risks, `R-15` to `R-21` and `R-29` dependencies.~>`R-1` to `R-14`, `R-22` to `R-28` and `R-30` to `R-32` are risks, `R-15` to `R-21` and `R-29` dependencies.~~} |
| **`O-<n>`** | Something out of scope (section 5). |
| **`L-<n>`** | A feature deferred to later (section 5). |
| **`E-<n>`** | A fact about what exists today (section 6). |
| **`P-<n>`** | A problem the product solves: of the vision (section 2.1, `P-1` to `P-4`) and of parallel work today (section 10.1, `P-5` to `P-14`). |
| **`SC-<n>`** | A row of the screen inventory: a screen of the extension, or a new screen, with what it becomes (section 8.3). |
| **`G-<n>`** | A generation unit: a package or application the project builds (section 11.2). |
| **`T<n>`** | A network topology (section 11.1). |
| **`F<n>`** | A key flow (section 11.1.1). |
| **`PQ-<n>`** | A question to the product owner, standing after the statement it asks about. `PQ-1` to `PQ-33` are answered and taken into the text; their answers are cited as sources (`PQ-7`) and kept in `01_02_Questions Round/answers.md` (`PQ-1` to `PQ-23`) and `01_04_Questions Round/answers.md` (`PQ-24` to `PQ-33`). {~~`PQ-34` to `PQ-59` are the open questions of round 4.~>`PQ-34` to `PQ-59` are the open questions of round 4, reworked in round 5; `PQ-60` to `PQ-66` are asked in round 5.~~} |

{~~After a statement, its source stands in brackets: the source id and the place
in it, e.g. `(S1 § 7.3, DQ-2)`.~>After a statement, its source stands in a citation shape at the end of the clause: `(-> D-61, CR.17)` names the ids that back it (decisions, answers, items), `(<- S22 § 3)` the source it is taken from with the place in it, `(<- S23: vscimpb179)` a todo of that source, and `(<~ S23: vscimpb179)` a source it is extrapolated from; a longer note on where a statement came from is a provenance or aside block. A reader may skip them without losing a requirement (the TomSpecs process, *Secondary prose*; DocSpecs, *Reading Notation*, RN-3).~~} `CQ-n`, `DQ-n` and `WQ-n` are the product
owner's answers in S1 § 14.1, {~~`FO-n` those in S2 § 5,~>`FO-n` those in S2 § 5 (FO-1 … FO-22, without FO-14, which was not assigned),~~} `WR-n` the requirements
of S3. A section is referred to by its id chain, outer first
(`TAC > TAC-PEOPLE`).

Further ids from inside a source are explained in the row of that source in
{~~section 1: `TQ-n` and `C-n` (S21),~>section 1: `TQ-n` and `C-n` (S21), `OR-n`, `FQ-n`, `C<n>` and `Q-n` (S29, always written with the source, as `S29: FQ-11`, since S21 has `C-n` too),~~} `IDEA-n`, `BP-n` and `part-…` (S6),
`DPMESSAGING-n` and `DPPHONE-n` (S13, S25), the notes a … n (S4), `RT-n` (S19)
and `RS-n` (S18), which stand only in the lead-in of `DEC`. The standard for
the `_ai` format is cited as `S22 § n` or `S22 AC-n`: its own ids (`CQ-n`
among them) collide with ids of this document and are never written without
`S22`. {~~A todo id after one of the sources S23, S25, S26 or S27~>A todo id after one of the sources S23, S25, S26, S27, S28 or S30~~}
(`vscimpb146`, `13_woneb5`) names a todo of the quest that source belongs to:
a completed todo is built behaviour, an open one a plan.

Capability areas: `CR` runtime core · `CP` protocol and hosts · `CT` tools and
MCP · `CA` coordination between runtimes · `CI` people, teams and identity ·
`CM` messaging · `CV` documents and review · `CW` parallel work and
integration · `CL` client SDKs · `CU` UI components · `CK` supervision ·
`CQ` repository quests and personal files · `CS` secrets, configuration and
providers.

Ids are never renumbered and keep their meaning. An item added later takes the next free number of its area and stands where its topic belongs, so the numbers of an area are not in order. The highest ids are: {~~`CR.110`, `CP.44`, `CT.17`, `CA.44`, `CI.20`, `CM.14`, `CV.16`, `CW.27`, `CL.12`, `CU.17`, `CK.12`, `CQ.13`, `CS.20`; `S27`, `V-8`, `U-16`, `O-10`, `L-12`, `E-22`, `P-14`, `SC-31`, `N-43`, `T8`, `F13`, `G-10`, `D-72`, `X-21`, `R-29`; the questions run from `PQ-1` to `PQ-59`.~>`CR.142`, `CP.45`, `CT.21`, `CA.45`, `CI.20`, `CM.15`, `CV.19`, `CW.29`, `CL.15`, `CU.18`, `CK.12`, `CQ.13`, `CS.26`; `S31`, `V-8`, `U-17`, `O-11`, `L-15`, `E-23`, `P-14`, `SC-38`, `N-45`, `T8`, `F13`, `G-10`, `D-74`, `X-26`, `R-32`; the questions run from `PQ-1` to `PQ-66`.~~}

> **❓ PQ-59 (2026-11-25T20:48+01:00) — the structure of the Project Idea in the next round:** Which of the seven changes of structure listed below should the next round make, before the Project Idea goes into the Solution Blueprint?
>
> **Context:** The Project Idea is the input of Phase 2, the Solution Blueprint, which cites it by its ids (`ABOUT`: "the Solution Blueprint cites it by the ids below"). Its sections and ids grew over five question rounds; ids are never renumbered and an item added later takes the next free number of its area, so an area's numbers are not in order (`ABOUT > ABOUT-READ`). The consistency read of round 4 found seven things about its structure, none of which changes what the product is:
>
> 1. **What the first version contains is spread over adverbs.** Items say "This comes after the native transports" (`RT > RT-TRANSPORTS`, CR.30), "This comes late" (CR.31), "an option" (`RT > RT-PROTO` and `RT > RT-INSTALL`, CR.45), "Two agent libraries are evaluated" (`RT > RT-PROVIDERS`, CS.16), "later" (`PAR > PAR-APPROACH`, CW.16, CW.25; `NFR > NFR-TOPO`, T6, T7; flow F9); the deferred features are in `SCO > SCO-LATER`. Nothing lists in one place which capability groups and items are in the first version, which are in it but late, which are options and which are later.
> 2. **No capability names whom it serves.** The user groups U-1 … U-16 (`USR`), the vision statements V-1 … V-8 (`VIS > VIS-GIVES`) and the problems P-1 … P-14 are each cited only where they are defined; no capability group says which of them it serves, so the Blueprint cannot tell from the document which requirement serves which stakeholder, or which user group is covered thinly.
> 3. **Sections and capability areas do not match.** `ABOUT > ABOUT-READ` defines thirteen capability areas (`CR`, `CP`, `CT`, `CA`, `CI`, `CM`, `CV`, `CW`, `CL`, `CU`, `CK`, `CQ`, `CS`); section `RT` holds four of them (`CR`, `CP`, `CT`, `CS`) in sixteen subsections, `CS` is spread over `RT > RT-CONFIG`, `RT > RT-SECRETS` and `RT > RT-PROVIDERS`, `CA` items stand in `TAC > TAC-PEOPLE > TAC-GROUPS`, and `CQ` in `PAR`.
> 4. **`NFR` repeats capabilities.** About twenty of the non-functional expectations restate a capability item in other words (for example N-1 restates CP.25, N-12 CA.32, N-26 CL.1); round 4 made each agree with the item it restates.
> 5. **Some statements are made in several places.** For example "a runtime is started by its host and ends with it" (`GLO` runtime, CR.44, T8, D-15, X-12), the resource and its name (`GLO`, CA.9, CA.10, CA.41, CA.42, D-59), or "remote control only in the home team and where the host allows it" (CI.5, CI.13, CK.5, N-19, D-25, `GLO` visible, CA.44). Each copy is a place that can drift; round 4 made the copies agree.
> 6. **Topologies, flows and generation units stand under non-functional expectations** (`NFR > NFR-TOPO`, `NFR > NFR-TOPO > NFR-TOPO-FLOWS`, `NFR > NFR-GEN`), where a reader looking for T8 or G-2 does not look; they are the shape of the system and its delivery.
> 7. **Long table cells and items with several topics** hold statements that have no id of their own and cannot be cited: the cells of T8, the GitHub row of CA.26, `GLO` visible and resource name, D-36, D-49, D-58; the items CA.39, CW.5, CQ.6, CR.5, CI.10 and CA.30, each with several provisions.
>
> **Why I ask:** Each change makes the document easier to turn into a Blueprint, and each costs a round of edits; the ones that move sections (3, 6) also change the section-id chains by which the Project Idea is cited (the other quests' todos cite items, the decisions name the sections they shaped). Points 1 and 2 add content the Blueprint needs anyway: its scope and the stakeholder of each requirement. Points 4, 5 and 7 remove places where the text can contradict itself. The Solution Blueprint follows a structure of its own (the TomSpecs model of the Blueprint), so the Project Idea's sections need not match it.
>
> - (a) **All seven** in the next round: one register of what the first version contains in `SCO`; a "serves" line per capability group and per user group; the sections regrouped by capability area (`RT` split into four sections, `TAC-GROUPS` under `TAC-COORD`); `NFR` keeps only qualities with a measure and refers to the capability items for the rest; each statement made once and referred to elsewhere; a section "System shape" with the topologies and flows before `NFR`, the generation units in `DEL`; long cells and multi-topic items split into items with ids of their own.
> - **(b)** **The four that add or secure content, not the three that move sections:** the register of what the first version contains (point 1); a "serves" line per capability group — the user groups, vision statements and problems it serves — and per user group the groups that serve it (point 2); `NFR` keeps only qualities with a measure and refers to the capability items for the rest (point 4); long cells and multi-topic items split into items with ids of their own, which keep their old id for their first provision (point 7). The sections, the copies in `GLO` and `DEC`, and the place of topologies, flows and units stay (points 3, 5, 6), since the Blueprint brings its own structure and the section chains stay valid.
> - (c) **None:** the Project Idea keeps its structure, and the Solution Blueprint orders, traces and splits as its own model requires.
>
> *Recommendation:* (b) — the register and the "serves" lines are what the Blueprint's scope and requirements need and no one else will write; shortening `NFR` and splitting crowded items remove the places that drifted in round 4; moving sections would break every chain other documents cite, for a structure the Blueprint does not take over.
>
> *Assumption until answered:* the structure stays as it is: the adverbs stay in their items and nothing is moved to `SCO > SCO-LATER`; no "serves" line is written; restating `NFR` items stay and agree in wording with the items they restate; no item is split.
>
> **Answer:**

## <!--[SRC]--> 1 Sources

The idea is drawn from the sources below. An answer of the product owner to a question of this document (a `PQ` id) wins over every source, S1 included; S1 does not hold those answers. For the `_ai` folder and for quests in repositories S22 is the standard: S2 § 3.7 and S12 hold only where S22 says nothing. Otherwise, where two sources disagree, S1 wins;
S1 § 2.4 lists what is outdated in the older ones.

| Id | Source | Holds | Standing |
| --- | --- | --- | --- |
| **S1** | `_ai/quests/ai_runtime/ai_runtime_concept.md`; snapshot `sources/ai_runtime_concept.md` | The concept: status, what the other quests bring, the system, runtime, protocol and hosts, coordination and messaging, topologies, flows, parallel work, the client SDKs and UI, the deliverables, and the product owner's decisions CQ-1 … CQ-20, DQ-1 … DQ-13, WQ-1 … WQ-4 (§ 14.1) | current; the main source |
| **S2** | `_ai/quests/ai_runtime/ai_runtime_feature_overview.md`; snapshot `sources/ai_runtime_feature_overview.md` | {~~Components and their main features; the decisions FO-1 … FO-22 (§ 5)~>Components and their main features; the decisions FO-1 … FO-22, without FO-14, which was not assigned (§ 5)~~} | current in its decisions; outdated in § 3.1 (the layout resolver is built, the guidelines folder and the configuration layers differ), in the todo model's version, and where it says a host provides no tools; § 3.7 (quests in repositories, personal files) is outdated where S22 differs |
| **S3** | `_ai/quests/ai_runtime/webwork_requirements.md`; snapshot `sources/webwork_requirements.md` | What Webwork needs from tar and tac, WR-1 … WR-7, each with what exists and what is missing | current as a requirement statement; WR-2 and WR-6 {~~are met differently (S1 § 7.10)~>are met differently (<- S1 § 7.10)~~} |
| **S4** | `_ai/quests/ai_runtime/quest-notes.ai_runtime.md` | The product owner's notes: the names tar, tac, trc, the goals a … n (cited as "note a" … "note n"), the split of the MCP server, the relay | current; the product owner's words |
| **S5** | `tom_ai/vscode/tom_tac_service/doc/tac_specification.md` | The protocol `tac/1.0` as built: records, lease lifecycle, operations, backends, errors, the HTTP / WebSocket and GitHub refs bindings | current for what is built; it knows no users, teams, user messages or documents, and names a quest `agent_coordination` as the quest it belongs to |
| **S6** | `_ai/quests/ai_runtime/ideas/agent_collaboration/agent_collaboration.docspecs.md` | The coordination idea: todo follow-ups, protocol, service, tac client and backends, claims, branches and worktrees, messages between runtimes, endpoints, the Coordination page, the guideline, the rollout. Its ids: `IDEA-n` and `BP-n` are the decisions of its idea and blueprint rounds; `part-claims`, `part-messages` and the other `part-…` names are its sections | current for leases, messages between runtimes, endpoints and branches; outdated in the quest it names as the one it belongs to, its package places and where it describes submodule pointers |
| **S7** | `_ai/quests/ai_runtime/llm_providers_runtime_integration.ai_runtime.md` | Model providers and the three ways into them | {~~current~>predates the provider decisions in this quest's `xx*` todos (S30), which win~~} |
| **S8** | `_ai/quests/ai_runtime/ideas/remote_control_app/remote_control_app.docspecs.md` | The supervision application in the product owner's words | current; input only |
| **S9** | S1 § 15 "Research: what other teams do" | External research read on 2026-11-18, with its links: client and agent protocols, parallel work and git models, spec-driven work, cloud agents, UI kits, supervision, secrets | current; some claims rest on secondary sources, marked there |
| **S10** | `_ai/quests/tom_specs/tooling/notes_ai_runtime.md` | The components and interfaces of this quest as the TomSpecs tooling sees them, and the contradictions it found | outdated in package names and places; useful as a cross-check |
| **S11** | `_ai/quests/tom_specs/tooling/tom_specs_tooling_suggestions.md` | Suggestions addressed to this product: one review component for every host, review copies that travel without the user, the process engine as a runtime service, the remote control | current |
| **S12** | `_ai/quests/al_the_bear/ideas/workspace_layout/workspace_layout.docspecs.md` | The workspace layout: root, workspace folders, the layout resolver, the configuration layers, independent repositories, the repository record | current for the layout; outdated for the `_ai` folder and the quest folder where S22 differs; the layout as it is being built is in S27 |
| **S13** | `_ai/quests/webwork/ideas/webwork_redesign/webwork_redesign.docspecs.md` | Webwork's redesign: messaging, the review exchange, the bottom panel with the AI tab, the wave plan. Its decisions are cited by their ids there: `DPMESSAGING-n` on messaging, `DPPHONE-n` on the builds for the phone and the web | current |
| **S14** | `_ai/quests/tom_forge/spec_quest_workbench.tom_forge.md` | Tom Forge's quest application: the views it expects, hosting a runtime per open quest | outdated in the runtime's name and the quest it belongs to; its second part (chapters 5 … 10) is a placeholder that waits for this specification |
| **S15** | `tom_ai/secrets_clients/protocol/protocol.md` and `_ai/quests/tom_core/ideas/tom_secrets_manager/tom_secrets_manager.docspecs.md` | Tom Secrets Manager: its client protocol, the reference grammar, how one of its clients is identified and approved | current |
| **S16** | `_agent_guidelines/parallel_work.md` | The rules for working in parallel today, and what enforces each | current; names a quest `agent_coordination` as the quest they will belong to |
| **S17** | `tom_ai/vscode/tom_vscode_extension/`: its code, `tom_ai/vscode/tom_vscode_extension/_agent_guidelines/architecture.md` and `tom_ai/vscode/tom_vscode_extension/doc/` {~~(among it `user_guide.md`, `llm_tools.md`, `multi_transport_prompt_queue_revised.md`, `md_browser_page_protocol.md`)~>(among it `user_guide.md`, `llm_tools.md`, `mcp_server.md`, `telegram_integration.md`, `multi_transport_prompt_queue_revised.md`, `md_browser_page_protocol.md`, `reading_notation_sample.md`)~~} | {~~The engine as built: the starting point of the runtime and of the UI components~>The old extension's engine as built: the starting point of the runtime, of the new extension and of the UI components~~} | {~~current; it keeps changing~>state of 2026-11-25; it keeps changing~~} |
| **S18** | `_ai/quests/ai_runtime/runtime_split_plan.ai_runtime.md` | {~~What comes before the split of the extension; the stable build during it; its questions are `RS-n`~>What its plan puts before an in-place split of the extension, and the stable build during it; its questions are `RS-n`~~} | {~~its questions are settled in S1 § 14.1~>its questions are settled in S1 § 14.1; RS-1 is replaced by D-73~~} |
| **S19** | `_ai/quests/ai_runtime/quest_runtime_design.ai_runtime.md` | The first runtime design: host interface, process model, stages; its decisions are `RT-n` | outdated in package place and name, locations, {~~host transports, Telegram and its measurements; background only~>host transports, Telegram and its measurements; its § 7 stages are replaced by D-73; background only~~} |
| **S20** | `_ai/quests/ai_runtime/ai_runtime_project_idea.md` | The first collection of the idea | superseded by S1; background only |
| **S21** | `_ai/quests/ai_runtime/ai_runtime_terminology.md` | The agreed terminology: every term with its meaning, the words not used, and the product owner's answers TQ-1 … TQ-11 on them (its § 4), with the further changes agreed beside them, `C-n` in the same table | current; the glossary (`GLO`) is taken from it, and the two are kept equal in content: the further terms of D-70 and the terms of the answers to PQ-24 … PQ-33 are in both |
| **S22** | `_ai/quests/al_the_bear/ai_format_migration.md` | The `_ai` folder and the quest folder in format version 11; the four classes of files; the three quest types with the register `_ai/quests.yaml`; the quest operations; the migration in three phases. Decided 2026-11-20, not built. Its own decision ids (`CQ-n`, `AC-n`, `QM-n`, `QJ-1`, `MG-1`) are cited with the source, as `S22 § n` or `S22 AC-n` | current; the standard for the `_ai` folder and for quests in repositories, named so by the product owner (answer to PQ-24). Where it differs from S2 § 3.7 and S12 it wins, except for what a decision of this document backs and an open question names (PQ-53, PQ-54) |
| **S23** | `_ai/quests/vscode_extension/todos.vscode_extension.todo.yaml`, {~~`todos-archived.vscode_extension.todo.yaml` (the todos completed 2026-11-10 … 2026-11-20) and `progress.vscode_extension.md` (the entries of 2026-11-19 and 2026-11-20)~>`todos-archived.vscode_extension.todo.yaml` (the todos completed through 2026-11-25, among them `finishvsc2` of 2026-10-27 and `vsc_setup-…` of 2026-11-08) and `progress.vscode_extension.md` (the entries of 2026-11-19 … 2026-11-25)~~} | What the extension's engine does today and what is planned for it, cited by todo id (`vscimpb…`, `qrun…`, `gsel…`, `…_aifmt-…`, `ccparity_…`) | {~~state of 2026-11-20;~>state of 2026-11-25;~~} a completed todo is built behaviour, one not started is a plan |
| **S24** | `_ai/quests/vscode_extension/role_and_guideline_selector.vscode_extension.md` | The design of roles and aspect guidelines per todo, item, run and window (its ids R-1 … R-4, A-1 … A-5, L-1 … L-8, cited with the source) | current (2026-11-20); built in part |
| **S25** | {~~`_ai/quests/webwork/todos.webwork.todo.yaml` (the groups `12a_woneb…`, `13_woneb…`, `14_woneb…`, `qavs_…`)~>`_ai/quests/webwork/todos.webwork.todo.yaml` (the groups `09_woneb…`, `03a_woneb…`, `12a_woneb…`, `13_woneb…`, `14_woneb…`, `qavs_…`, `caf_17…`)~~}, `_ai/quests/webwork/webwork_wave1_plan.md`, `_ai/quests/webwork/md_browser_probe.webwork.md` | What Webwork plans on the runtime and tac beyond S3 and S13, cited by todo id and by Webwork's decision ids (`DPPHONE-n`, `DPMESSAGING-n`) | {~~state of 2026-11-20; plans of another quest~>state of 2026-11-25; plans of another quest~~} |
| **S26** | `_ai/quests/tom_forge/todos.tom_forge.todo.yaml` (the groups `qavs_…`, `later23`, `later25`, `05b_woneb…`, `wwkit…`), `_ai/quests/tom_forge/decisions.tom_forge.md`, `_ai/quests/tom_forge/tom_forge_componentization.md` | What Tom Forge plans on the runtime beyond S14: hosting runtime processes, its view packages, the review component, a server side for repository quests in a web build | state of 2026-11-20; plans of another quest |
| **S27** | `_ai/quests/al_the_bear/todos.al_the_bear.todo.yaml` (the `…_aifmt-…` and `…_wslayout-…` todos), `_ai/quests/al_the_bear/workspace_layout_plan.md`; at the fleet root (the folder above the workspace folder that holds `.tom/tom_root.yaml`): `_agent_guidelines/workspace_layout.md`, `workspace_layout_multi.md`, `repos.yaml`, `repo_structure_new.md`, `repo_skills_new.md` | The workspace layout as it is being built: the root and workspace markers, the places that can be changed, independent clones, the fleet's skills after the cutover; beyond S12 | state of 2026-11-20; partly built |
| {++**S28**++} | {++`_ai/quests/vscode_extension/ideas/collab_and_features/collab_and_features.docspecs.md` and `_ai/quests/vscode_extension/ideas/collab_and_features/collab_and_features_input.md`++} | {++The extension quest's plan for leases as git refs, a resource notation, feature branches and worktrees, agent groups with a supervisor, features and feature runs, standard runs, review todos and an issue flow, with its 76 `caf_…` todos (cited by todo id)++} | {++state of 2026-11-24; planned, not built; it differs from `TAC > TAC-COORD`, D-24 and D-68 (PQ-63, X-22)++} |
| {++**S29**++} | {++`_ai/quests/webwork/webwork_office_and_review.webwork.md` and `_ai/quests/webwork/webwork_component_placement.webwork.md`++} | {++Webwork's decisions on office documents and review — `OR-n`, and the answers `FQ-n`: the review folder layout (FQ-11), the channels besides tac (FQ-9), the areas Review and Team Review (FQ-5, FQ-8), the installer (FQ-3) — and on where its components are built (`C<n>`, `Q-n`: `tom_messaging_ui`, C21, Q-8)++} | {++state of 2026-11-25; decided in the webwork quest++} |
| {++**S30**++} | {++`_ai/quests/ai_runtime/todos.ai_runtime.todo.yaml`++} | {++This quest's own todo groups and the product owner's answers in their decisions (`ww_b_workbench-…`, `ww_d_workbench-…`, `ww_…_collab-…`, `tac_webwork-…`, `12b_woneb…`, `xx…`, `ccparity_h_pi-…`, `ww_e_gitruntime-…`, `ww_e_runtimeapi-…`, `a2a1`, `rca1`, `checks…`), cited by todo id++} | {++state of 2026-11-25; input, replaced by the todos of this specification (D-42); the answer in `ww_e_runtimeapi-1` on the place of the runtime is superseded by D-1++} |
| {++**S31**++} | {++`tom_ai/ai_build/specification/phase1_project_idea/01_05_Questions Round/answers.md`++} | {++The product owner's instructions (a) and (b) of question round 5, verbatim: the feature baseline of the first version and the new VS Code extension++} | {++current; the words behind D-73 and D-74++} |

{~~Every path above resolves on 2026-11-20,~>Every path above resolves on 2026-11-25,~~} in the workspace or, for the files of S27 named so, at the fleet root. The snapshots in
`sources/` carry the original's path and the date in their first line; S1 was
taken at the state of 2026-11-19.

{~~**Not a source:** theagent_container and project_coordination work,~>**Not a source:** the agent_container and project_coordination work,~~} archived in `tom_archived`.
{~~It may supply aspects to consider, nothing more (S4, note m).~>It may supply aspects to consider, nothing more (<- S4: note m).~~}

## <!--[VIS]--> 2 Vision

### <!--[VIS-PROBLEM]--> 2.1 The problem

Work with AI agents is organised today around the coding session: one task,
one execution by an agent, one branch or pull request to review. A larger undertaking
does not fit that unit. It runs for weeks or months, spans many repositories
and several machines, follows a process with phases and gates, and depends on
people who answer questions, review documents and decide {~~(S9; S1 § 15.2,
§ 15.3)~>(<- S9; S1 § 15.2, § 15.3)~~}.

The Tom workspace has an engine for such work: quests, todos, processes with
runs, a prompt queue, sessions, transports to the models, tools, team review.
It lives inside one application, the VS Code extension, and is entangled with it
{~~(S1 § 2.1). Four things follow:~>(<- S1 § 2.1). Four things follow:~~}

- **P-1** **Other applications cannot use it.** Webforge (Tom Forge) and Webwork need
  the same engine and {~~would have to build it again (S4, notes a, k).~>would have to build it again (<- S4: notes a, k).~~}
- **P-2** **Agents and people work side by side without anything keeping them
  apart.** Everything is committed on one branch in shared clones; "one writer
  per repository" is an agreement; machines drift apart unnoticed; shared
  {~~files are overwritten by another window (S1 § 10.1).~>files are overwritten by another window (<- S1 § 10.1).~~}
- **P-3** **People outside the editor cannot take part.** A reviewer or a decider
  without access to a repository gets documents by hand, and a question from
  {~~an agent waits in the window that asked it (S1 § 3.5, § 6.6).~>an agent waits in the window that asked it (<- S1 § 3.5, § 6.6).~~} With the product such a reviewer uses an application that carries the review component (the VS Code extension today, Webwork and Webforge later; none of them is built here), and that application {~~reaches tac through its runtime (D-67).~>reaches tac through its runtime (-> D-67).~~}
- **P-4** **Nobody sees the whole.** What waits, where, on which machine, is spread
  {~~over windows (S8).~>over windows (<- S8).~~}

{~~Why now: the engine's features are complete enough to be extracted; the hosts~>Why now: the engine's features are complete enough to be carried into a runtime of its own; the hosts~~}
that are to use it and the quests of `LAND > LAND-WAIT` wait for it; and the
coordination service's first part exists and is used by nothing yet
{~~(S1 § 2.1, § 2.3).~>(<- S1 § 2.1, § 2.3).~~}

### <!--[VIS-SYSTEM]--> 2.2 What the system becomes

The unit of work is the **project**: a quest with processes, gates, todos and
{~~people, not a coding session (S1 § 4, § 15).~>people, not a coding session (<- S1 § 4, § 15).~~} The system is the programs and
the libraries of this table:

| Component | Short | Is |
| --- | --- | --- |
| **Tom AI Runtime** | tar | The engine as a runtime of its own (`tom_ai/ai_build/tom_ai_runtime`, TypeScript): quests, todos, processes and runs, the queue, sessions, transports, tools and an MCP server, without a VS Code window. A host attaches to it and {~~adds as thin a user interface as it needs. (S1 § 4, § 5; FO-1)~>adds as thin a user interface as it needs. (<- S1 § 4, § 5) (-> FO-1)~~} |
| **Tom Agent Coordination** | tac | The service through which runtimes find each other and keep out of each other's way (presence, leases, messages, endpoints), and the messaging service between the users of applications linked with a runtime: documents for review, messages, reminders, decisions. A reusable component of its own. It runs as the local tac service on a user's machine and as the tac server with its relay for a team; with the GitHub backend a coordination repository takes the service's place {~~(`TAC > TAC-BACKENDS`). (S1 § 4, § 7.1, § 7.2; CQ-15)~>(`TAC > TAC-BACKENDS`). (<- S1 § 4, § 7.1, § 7.2) (-> CQ-15)~~} |
| **Tom Runtime Control** | trc | The supervision application: every runtime of a team in one view, with full remote control. A Webforge application that also runs standalone, on the desktop and, in the first version, on the phone and the tablet. On a phone or a tablet it uses a runtime through the web runtime service; what that takes, and whether it stays in the first version, {~~is an open question (PQ-49). (S1 § 12.4; FO-12; PQ-9, PQ-28)~>is an open question (PQ-49). (<- S1 § 12.4) (-> FO-12, PQ-9, PQ-28)~~} |
| **Web runtime service** | — | The program on a server through which an application on a phone, on a tablet or in a browser uses a runtime, since a runtime does not run there. It is HTTP-based, connects to a runtime on the server on behalf of the application, and reaches tac through that runtime. What it is beyond that is open; assumed until PQ-38 is answered: it starts one runtime per connected application {~~(`RT > RT-INSTALL`, CR.46). (PQ-28; PQ-9, PQ-16)~>(`RT > RT-INSTALL`, CR.46). (-> PQ-28, PQ-9, PQ-16)~~} |
| **Client SDKs** | — | One runtime client SDK and one tac client SDK per language, for nine languages (Dart, TypeScript, JavaScript, Python, Java, Go, Rust, C, C++). Beside them a web runtime client SDK, in Dart and in JavaScript / TypeScript, for applications on phones, on tablets and in browsers, built with Flutter or not; how it relates to the runtime client SDK {~~is an open question (PQ-41). (S1 § 12.1; FO-10, FO-11, CQ-15; PQ-7, PQ-28)~>is an open question (PQ-41). (<- S1 § 12.1) (-> FO-10, FO-11, CQ-15, PQ-7, PQ-28)~~} |
| **Flutter UI components** | — | `tom_ai_runtime_ui`: the reusable user interface of the runtime for Flutter applications. {~~No user interface components for other platforms. (S1 § 12.2; S4, note l)~>No user interface components for other platforms. (<- S1 § 12.2; S4: note l)~~} |
| {++**New VS Code extension**++} | {++—++} | {++The VS Code host: a copy of the old VS Code extension in `tom_ai/ai_build`, rewired to the runtime until every feature works as before, distributed and with a team. It keeps the old extension's views and VS Code tools, and takes the old one's place when it is stable; the old extension is left as it is meanwhile. Its identity beside the old one and the swap are an open question (PQ-60). (-> D-73) (<- S31)++} |

{~~The hosts of the first version are programs: the VS Code extension; Webforge~>The hosts of the first version are programs: the new VS Code extension (-> D-73); Webforge~~}
with its applications (the quest application, Webwork and the supervision
application); the supervision application standalone; and, for applications
on phones, on tablets and in browsers, the web runtime service (assumed until
PQ-38 is answered: it runs one runtime per connected
application). A host may start several runtimes: one per open quest, and one
without a quest for each of its applications that needs one {~~(S1 § 4;
PQ-9, PQ-16, PQ-28; `NFR > NFR-TOPO`, T2; `CLI > CLI-TRC`, CK.7; `RT > RT-INSTALL`, CR.46).~>(<- S1 § 4) (-> PQ-9, PQ-16, PQ-28, T2, CK.7, CR.46).~~}

### <!--[VIS-GIVES]--> 2.3 What it is to give

- **V-1** One implementation of the `_ai` formats and the engines, used by
  every host, so a quest behaves the same in VS Code, in Webforge and in
  {~~Webwork. (S1 § 5.1; S4, note a)~>Webwork. (<- S1 § 5.1; S4: note a)~~}
- **V-2** A comprehensive collaboration system: quests, todos, processes,
  queues and agents run in runtimes that find each other and work together; a
  host only attaches to a runtime and adds a thin user interface, as much of
  {~~it as that host needs. (S4, note k)~>it as that host needs. (<- S4: note k)~~}
- **V-3** Runtimes that work with each other, so that an agent's tools reach other
  runtimes as they reach other VS Code windows today: on one machine, across the VPN, and through the tac server's relay beyond
  {~~it. (S4, notes b … e; S1 § 7.2)~>it. (<- S4: notes b … e; S1 § 7.2)~~}
- **V-4** A protocol with a streaming connection and an API over it, so any
  host can attach, and client SDKs that make attaching a matter of a few
  {~~lines. (S4, notes f, g, k; S1 § 6.1, § 12.1)~>lines. (<- S4: notes f, g, k; S1 § 6.1, § 12.1)~~}
- **V-5** Users as participants: messages, documents for review, reminders,
  questions and decisions travel between the users of a team and the runs
  that need them, also to users without access to a repository. Such a user
  takes part through an application that carries the review component and
  reaches tac through its runtime: the VS Code extension today, Webwork and
  Webforge later; none of them is built here. {~~(S1 § 7.1,
  § 7.4, § 7.7; PQ-30)~>(<- S1 § 7.1, § 7.4, § 7.7) (-> PQ-30)~~}
- **V-6** Parallel work that is enforced, not agreed: claims on the resources an
  execution works on, an integration step before the main branch, a record of what each
  {~~todo changed. (S1 § 10.4)~>todo changed. (<- S1 § 10.4)~~}
- **V-7** Supervision of a whole team's runtimes from one place, also from
  a phone or a tablet while away, {~~through the web runtime service. (S8; S1 § 12.4; PQ-9, PQ-28)~>through the web runtime service. (<- S8; S1 § 12.4) (-> PQ-9, PQ-28)~~}
- **V-8** Putting the runtime's user interface into a Flutter application is
  {~~simple. (S4, note l; S1 § 12.2)~>simple. (<- S4: note l; S1 § 12.2)~~}

## <!--[USR]--> 3 Users and stakeholders

### <!--[USR-GROUPS]--> 3.0 User groups

| Id | Who | Uses the system to | Source |
| --- | --- | --- | --- |
| **U-1** | **A developer working with agents in an editor.** One person with one or several machines, many quests, many windows. | Queue prompts and todo walks, run processes, answer the agents' questions, review results, and work in parallel without runs disturbing each other. | S1 § 3.1, § 10.1 |
| **U-2** | **A team member who reviews or decides**, often without access to any repository (a business reviewer). | {~~Receive documents for review, annotate and return them; answer questions~>Receive the review requests addressed to them and the documents of a review round, annotate and return them — through tac, or by export and import, by mail or by hand into the review folder; answer questions~~} and take decisions that a run or a colleague addresses to them; exchange messages. They do it in an application that carries the review component and reaches tac through its runtime: the VS Code extension today, Webwork and Webforge on the desktop later, a web version after that; none of them is built here. Until a web version exists, such a reviewer needs one of them on a desktop. | S1 § 3.2, § 7.7; S3; {~~PQ-30; S25 (`13_woneb10`)~>PQ-30; S25 (`13_woneb10`); S29 (FQ-9)~~} |
| **U-3** | **A team owner.** | Create a team on a tac server they have joined (a team on the GitHub backend has several members too; who owns it and what an owner does there is an open question: PQ-47), invite members, remove them, administer the team's configuration (the providers that may be used, standard profiles); is the last in the chain when a question stays unanswered. | S1 § 7.3, § 5.5, § 6.6; DQ-2, DQ-11; PQ-20, PQ-29 |
| **U-4** | **A quest owner.** Every quest has one. | Answer the questions that concern the quest's topics, or forward them. | S1 § 6.6; CQ-7 |
| **U-5** | **A supervisor of several runtimes.** Usually a user supervising their own runtimes, or some of the team runtimes. | See what every runtime does and what waits; queue todos, start and pause runs, continue processes, answer questions, review documents, from one place: at the desk, and from a phone or a tablet while away. | S8; S1 § 12.4; FO-12; PQ-9 |
| **U-6** | **An application developer** who embeds the runtime in a Flutter application, or uses it from another language. | Attach an application to a runtime through the runtime client SDK, offer the application's own tools to it, and build the user interface from ready components. For an application on a phone, on a tablet or in a browser: U-14. | S1 § 12.1, § 12.2, § 6.3; S4, notes k, l |
| **U-7** | **An administrator of a tac server.** | Run the tac server for one or several teams, set it up with TLS, set whether it is open or strict, create the first account and its access key, have the tac server approved by Tom Secrets Manager. | S1 § 7.2, § 5.8; CQ-9, CQ-16; PQ-13, PQ-20, PQ-32 |
| **U-14** | **A developer of an application for a phone, a tablet or a browser**, built with Flutter or not. | Attach the application to a runtime on a server through the web runtime client SDK (Dart; JavaScript / TypeScript) and the web runtime service. A Flutter application also gets the UI components; an application that is not built with Flutter gets the SDK only (`SCO > SCO-OUT`, O-3). | PQ-28 |
| **U-15** | {~~**The coordinator of a review round:** the user whose runtime started the round.~>**The coordinator of a review:** the user who starts a review and its rounds, through their runtime, or through their application for document kinds the runtime does not know.~~} | {~~Send a set of documents to the members for review, receive the returned copies, and decide when the round is merged.~>Send the review set of a round to the members (the same documents to all, or files of their own to one), receive the returned copies through tac or another channel, consolidate them, decide when the round is merged, and start the next round.~~} | {~~`TAC > TAC-REVIEW`, CV.12; PQ-33~>`TAC > TAC-REVIEW`, CV.12; PQ-33; S29 (FQ-9, FQ-11); S25 (`09_woneb3`)~~} |
| **U-16** | **A quest member:** a user registered as a member of a repository quest, also the same user on a further machine. | Join the quest on a machine, work in its repository beside the other members, and take in their work. | `PAR > PAR-QUESTS`, CQ.7; S22 § 4 |
| {++**U-17**++} | {++**A guest reviewer:** somebody who is not on the team and reviews a round's documents.++} | {++Return an annotated copy by another way than tac (export, mail, by hand into the review folder); the coordinator names the guest, with name and role, in the review before the merge.++} | {++`TAC > TAC-REVIEW`, CV.16; S25 (`09_woneb3`); S29 (FQ-9)++} |

### <!--[USR-HOSTS]--> 3.0.1 Hosts and waiting quests

| Id | Stakeholder | Interest | Source |
| --- | --- | --- | --- |
| **U-8** | **The VS Code extension** (quest `vscode_extension`) | {~~Becomes a host: it keeps its views and its VS Code tools and runs the runtime in its window. Its features are finished before the engine is extracted. It gets messaging~>Keeps the old extension, which is left as it is while its copy, the new extension in `tom_ai/ai_build`, is rewired to the runtime. The new extension becomes the VS Code host: it keeps the old one's views and VS Code tools, takes its features from the runtime, distributed and with a team, and takes the old one's place when it is stable; which features it does not keep is an open question (PQ-62), and so is which quest owns it after the swap (PQ-60). The old extension's features, built and planned, are part of the first version (-> D-74). It gets messaging~~} once the runtime is built; its messaging views are its own and are not built here (`SCO > SCO-OUT`, O-1). | {~~S1 § 5, § 13.3; S2 § 3.3; PQ-30~>S1 § 5, § 13.3; S2 § 3.3; PQ-30; S31 (D-73, D-74)~~} |
| **U-9** | **Webforge / Tom Forge** (quest `tom_forge`) | Hosts one runtime per open quest in its quest application; builds its views on the Flutter components; hosts trc as an application from the start. Every application composed from Tom Forge's composition library holds the quest applications and is such a host: Tom Forge's own application, the TomSpecs editor and Webforge. | S1 § 3.3; S14; D-5 (FO-12); `CLI > CLI-TRC`, CK.7 |
| **U-10** | **Webwork** (quest `webwork`) | Its AI tab runs on a runtime without a quest; its team messaging and review exchange run over tac, through its runtime; in the first version messaging is in Webwork. Its builds for the web, the phone and the tablet have neither AI nor messaging until its wave 3 (`SCO > SCO-LATER`, L-8). | S3; S13; S1 § 7.10; PQ-30; S25 |
| **U-11** | **The fleet** (quest `al_the_bear`) | Runs the coordination repository and the tac server; its workspace layout is what the runtime resolves; its rules for parallel work become enforced; its format of the `_ai` folder and of quests in repositories is what the runtime is built on. | S1 § 3.4; S12; S16; S22; S27 |
| **U-12** | **TomSpecs** (quest `tom_specs`) | Its processes and tools run in the runtime; its team review loses the user as courier of the review copies. | S1 § 3.5; S11 |
| **U-13** | **Tom Secrets Manager** (quest `tom_secrets_manager`) | The runtime and the tac service are its clients. | S15; S1 § 5.8 |

### <!--[USR-TEAM]--> 3.1 Product owner and review team

The product owner is the only reviewer. Every document type uses this team;
no document type has a team of its own. This document's review team records no e-mail address; that says nothing about what tac keeps for a user.
{~~(PQ-1, PQ-22)~>(-> PQ-1, PQ-22)~~}

| Member id | Display name | Role | Owner of the review team |
| --- | --- | --- | --- |
| `alexis` | Alexis | Product owner | yes |

## <!--[GLO]--> 4 Glossary

The terms as agreed with the product owner {~~(S21)~>(<- S21)~~}, and the further terms the
document uses in a fixed sense (D-70). A word in the last table is
not used, or only in the sense named there.

**Components and programs**

| Term | Meaning |
| --- | --- |
| **tar** (Tom AI Runtime) | The product: the engine as a runtime of its own. |
| **runtime** | One running instance of tar. It serves one quest (or none, for an application's own AI), belongs to exactly one person, and is started by its host and ends with it. An installed copy of tar is a **runtime installation** (one per machine and user, `RT > RT-INSTALL`, CR.40); "runtime" alone is always a running instance. |
| **application** | A program a person uses: VS Code with the extension, Webforge, Webwork, the supervision application; on any device. |
| **host** | The program that starts a runtime and through which the runtime reaches a user. On a desktop the application itself is the host. For an application on a phone, on a tablet or in a browser a runtime does not run there: the **web runtime service** on a server connects to a runtime on the application's behalf (D-65); that the service is then the host and starts one runtime per connected application is assumed until PQ-38 is answered. |
| **client** | A program in its role of speaking a protocol to another, always with its kind: a **runtime client** connects to a runtime, a **tac client** connects to tac. |
| **client SDK** | The library we build for a client: the **runtime client SDK** (for applications on a machine where a runtime runs, to reach a runtime) and the **tac client SDK** (which runtimes and command-line programs of ours use to reach tac; no application and no server uses it, D-63), in each supported language; and the **web runtime client SDK**, in Dart and in JavaScript / TypeScript, for applications on a phone, on a tablet or in a browser, to reach a web runtime service (`CLI > CLI-PACK`, CL.12; D-65). |
| **server** | Always with its kind: {~~the **tac server**,an **MCP server**~>the **tac server**, an **MCP server**~~}. A runtime running as a process of its own is a **runtime process**, not a server. The **web runtime service** is a program on a server and is named by that name. |
| **tac** (Tom Agent Coordination) | The service for coordination between runtimes and messaging between people. `TAC` is its protocol. |
| **backend** | Where tac's data lives for a workspace: local (one machine and one user), GitHub (a coordination repository, for one user's machines or a simple team of several members), or a tac server (`TAC > TAC-BACKENDS`, CA.26; D-66). |
| **trc** (Tom Runtime Control) | The supervision application. |

**Work in a runtime**

| Term | Meaning |
| --- | --- |
| **quest** | An area of work: its documents, todos and process state. It is small enough to hold one project at a time, and holds more projects over time. It has a quest owner and a home team. A quest is a **classic quest** or a **repository quest** (a **single-quest repository** or a **multi-quest repository**); the register of quests lists every quest with its type (`PAR > PAR-QUESTS`, CQ.1; `RT > RT-LOCATIONS`, CR.100; D-71). |
| **process** | A defined way of working: phases, steps, the roles doing them, gates, decisions, subprocesses. |
| **run** | A queue that executes todos and prompts. A quest has several runs, working in parallel; a run has its process position, its variables, its settings and its sessions. A run lives as long as its line of work, often for weeks. A run follows at most one process; the run `default` follows none (`RT > RT-RUNS`, CR.8, CR.9). A run executes one item at a time (CR.67). While an ask of the run is open, the run waits (`RT > RT-ASKS`, CP.21). |
| **queue item** (item) | One entry of a run's queue: a prompt, a todo or a group of todos, with the session it is executed in and the transport it is sent with. |
| **todo** | A unit of planned work in a quest: an id, a description, a status, what it depends on, and the resources it needs. |
| **execution** | The work on one item: it starts when the run sends the item and ends when the item is done or given up. An execution claims the item's resources at its start and releases them at its end; where a repository has working trees, it works in one, and its result is a branch that the integration step lands. An execution that waits for the answer to an ask is still the same execution. |
| **session** | A named line of conversation with a model, belonging to a run, that can be started over: the same session then begins a new conversation with empty history, and what was said before stays in the trail (D-62). A session has a base, a lifetime and optionally a profile (`RT > RT-QUEUE`, CR.75); a run is created with its default session `default@<run>`. An item is always executed in a session; an item that names none is executed in its run's default session. *The word is not used for anything in coordination.* |
| **agent** | The model acting in a session, or a sub-agent it started. It receives a prompt, reasons, calls tools and answers. An agent has no identity outside its session: it is not a member of anything, holds nothing and is never addressed by tac. What acts towards the outside is the runtime, for its person. |
| **sub-agent** | An agent started by an agent for a part of its work. |
| **transport** | The way a prompt reaches a model. With a **model transport** the runtime calls the model's API and runs the tool loop itself. With an **agent transport** an outside program (an agent SDK or command line) runs the loop and reaches the tools through MCP. In both, what works in the session is an agent. |
| **tool** | A function an agent can call. A **runtime tool** is carried out by the runtime, a **host tool** is registered by the host and carried out there. |
| **ask** | A question the runtime puts to a person: a question, a pick, a document to work on, a tool approval, a plan, a decision, a gate. A stored record. While it is open, the run that asked waits until the ask is **settled**: answered, closed unanswered because its execution was ended, or resolved by its declared default (`RT > RT-ASKS`, CP.20, CP.21; D-61). |
| **trail** | The durable record of what a run did: prompts, answers, tool calls, as files. |
| **event** | One thing a runtime tells its clients while it works; numbered per run. |

**People**

| Term | Meaning |
| --- | --- |
| **person** | Any human being. |
| **user** | A person using an application. A user has an identity (user id, e-mail address, display name) and devices. |
| **a runtime's person** | The person a runtime belongs to: the user of its host. |
| **participant** | tac's technical word for whoever can send or receive: a user or a runtime. Used only where both are meant. |
| **account** (= customer) | Whoever a tac server serves: an organisation, or a single person. An account has several teams and many users; quotas attach to it. Installing a server creates the first account. "Customer" is the same thing and is not used beside it. |
| **team** | A group of users: members, owners, invitations, conversations, review sets, and the right to control each other's runtimes. A team exists with each backend: on the local backend it is the personal team of one user on one machine; on the GitHub backend a user's personal team across that user's machines, or a simple team of several members; on a tac server any team, within an account (`TAC > TAC-PEOPLE`, CI.1; D-66). |
| **member**, **owner** (of a team) | A user in a team; an owner may also invite, remove, make owners, change the team's settings, free anyone's stale lease, and delete the team. These rights are stated for a tac server; what holds for a team on the GitHub backend is open (PQ-47). "Owner" alone is never used: it is the owner *of a team*, *of a quest*, or the *product owner*. |
| **team runtimes** | All the runtimes started by the members of a team (through their hosts). "Agent group" is not used for them. |
| **visible** (a runtime in a team) | A runtime is always visible in the home team of its quest: there it is seen, can be sent items, can be remote-controlled by the team's members where its host allows it, and claims its leases. In its user's other teams it is not visible by default; the user can switch it visible at the host. In such a team it is only seen, with its quest, and can be **offered todos**: no remote control from there, and no leases there. A user in two teams can so act as a liaison and link two groups of quests, or not show the other membership. |
| **todo offer** | A todo that a member or a runtime of another team sends to a quest. It is not in the quest until it is **accepted**: by a person of the quest's team, or automatically by a rule a person has set for that quest (from whom, of what kind). Accepting is always under a person's control. Adding todos is the case this exists for; other kinds of item may follow. |
| **home team** | The team a quest belongs to. Its runtime is always visible in that team and acts as a member of it. |
| **personal team** | The implicit team of a user on a backend without a tac server, with the user as its only member: on the local backend its team runtimes are the user's runtimes on that one machine; on the GitHub backend they are the user's runtimes on all machines that share the coordination repository (`TAC > TAC-PEOPLE > TAC-GROUPS`, CA.39; D-66). |
| **invitation**, **team token** | How a user joins a team on a tac server (an owner creates it for an e-mail address; a one-time password); the proof of membership, sent with every request. Whether they exist for a team on the GitHub backend is open (PQ-47). |
| **device**, **pairing** | A machine, phone or tablet of a user; enrolling it once so that it gets a key of its own and may reach a server from the internet. "Pairing" is used for devices only (D-69); which program a device reaches from the internet, and which holds the device keys, is open (PQ-49). |
| **open server**, **strict server** | A tac server's setting for identity: stated identity is believed, or everyone needs an invitation and a team token. From the internet always strict. |

**Coordination: who may write where**

| Term | Meaning |
| --- | --- |
| **resource** | What can be leased: for now a whole repository, or a part of one described by a pattern of paths; further kinds come with further prefixes of the resource name (D-68). A resource is named when it is claimed and registered nowhere; tac knows only the leases it has given. "Unit" and "touch set" are not used: a todo names its **resources**. |
| **resource name** | Globally unique, the same on every machine, whatever folder the clone lies in: a prefix that names its notation, then the name in that notation. `git:` is the only prefix for now: the repository's identity at its repository server, and for a part a `#` and a path pattern relative to the repository's root. `git:<owner>/<repository>` when the team has one repository server, in full (`git:<server>/<owner>/<repository>`, for example `git:github.com/al-the-bear/tom_ai_build`) when it has several. Example: `git:al-the-bear/tom_ai_build` and `git:al-the-bear/tom_ai_build#tom_ai_runtime/**`. A runtime derives the name from the clone's remote, never from its path. Further prefixes are added as they are needed (`TAC > TAC-COORD`, CA.9, CA.10; D-68); the details of the grammar are open (PQ-45). |
| **claim** | The attempt to get leases: before an item is executed, its runtime claims the item's resources from tac, all or none. A claim is answered with the leases, or refused with who holds what. "Request" means the same. |
| **lease** | The right on a resource for a limited time, given by tac in answer to a claim. It is **exclusive** or **shared** (below). "Grant" (as a noun) and "lock" mean the same and are not used; tac **grants** a lease (the verb). "Lock" is only a file lock on one machine. |
| **exclusive lease** | A lease that keeps every other claim on an overlapping resource out while it is held. |
| **shared lease** | A lease that records that an execution works on the resource. Others can take shared leases on it too; it is refused only while someone holds an exclusive lease there. It is what shows who is working where. |
| **strict mode** (of a repository) | The repository has no working tree per execution. An execution holds an exclusive lease for as long as the item is executed. |
| **worktree mode** (of a repository; also **change-branch mode**) | The repository has a working tree per execution. An execution holds a shared lease while it works in its tree, on its branch, and takes an exclusive lease only for the integration step. |
| **holder** | The runtime holds a lease, for the item it executes in one of its runs. A lease names its holder: the runtime, the quest, the run, the item, the machine and the workspace; tac keeps no record of the holder beside the lease (`TAC > TAC-COORD`, CA.8; D-64). It can be said to belong to the item, or to the run that executes it; it does not belong to a session. |
| **renew**, **release** | The runtime renews a lease while the execution works, and releases it when the execution ends. |
| **stale**, **free** | A lease not renewed for 60 minutes is stale. It is only shown; a person frees it. |
| **fencing token** | A number that grows each time a lease on a resource is given; a write carries it, so a write by a holder whose lease has passed to someone else is refused. |
| **overlap** | Two `git:` resources overlap when they name the same repository and one is the whole repository, or when their patterns can match the same path; resources with different prefixes never overlap (`TAC > TAC-COORD`, CA.11). tac gives no exclusive lease on a resource that overlaps a leased one, and no lease at all on one that overlaps an exclusively leased one. |
| **working tree** (per execution) | A second checkout of a repository on its own branch, in which one execution works. Whether a repository has them (worktree mode) or not (strict mode) is a setting the team decides. |
| **integration step**, **integration queue** | Bringing an execution's commits onto the branch the record of repositories names for the repository (`RT > RT-LOCATIONS`, CR.104) (rebase, the repository's checks, fast-forward, push); the serial order in which a repository's executions do that. |
| **endpoint** | An address a runtime publishes through tac for the other team runtimes to reach it; it exists only while the runtime is present. |


**Messaging, documents, review**

| Term | Meaning |
| --- | --- |
| **conversation** | A sequence of messages between users of a team: direct, among several members, or attached to a document, a review round, a todo, a run or a quest. |
| **message kind** | What a message is beyond text. Eight kinds are messages between users, or from a run to a person: text, document, review request, review return, ask, decision request, todo, reminder; notification and command are the two kinds of message between runtimes (`TAC > TAC-COORD`, CA.19), listed beside them because a host shows them too (`TAC > TAC-KINDS`, CM.1, CM.2). |
| **blob** | A file carried by tac, addressed by the hash of its content, with a lifetime. |
| **review set** | {~~A named set of files pinned in tac for a review.~>The set of documents a review covers, named in its `review.yaml`; sent through tac, its files are pinned blobs (`TAC > TAC-DOCS`, CV.5; `TAC > TAC-REVIEW`, CV.17; D-29).~~} |
| **review round**, **round folder** | {~~One round of a team review; its record beside the documents, in the documents' storage, which is usually version control (`TAC > TAC-REVIEW`, CV.13).~>One round of a review; its folder `round-<n>/` in the review folder holds `outbound/base/` (the documents as sent to everyone, the base of the merge), `outbound/<member>/` only where a member gets something different, `returned/<member>/` (what each member sent back) and `consolidated/` (the merged documents and the merge report `merge-report.json`). The round's state is read from it (`TAC > TAC-REVIEW`, CV.17, CV.18).~~} |

**Further terms of this document**

| Term | Meaning |
| --- | --- |
| **walk** | A queue item that goes through a group of todos, lowest number first, one iteration per todo (`RT > RT-QUEUE`, CR.19, CR.64). |
| **walk continuation** | A prompt the runtime sends into the same session after a todo of a walk that is not completed and names no blocker, decision or open question; at most a set number of times, then the item stops as "needs attention" (`RT > RT-QUEUE`, CR.82). |
| **gate** | What ends each phase of a process (`RT > RT-RUNS`, CR.10). |
| **step boundary** | The point between two steps of a process; a run takes a changed process definition over only there, after the user confirmed it (`RT > RT-RUNS`, CR.12). |
| **subject** | What a run works on: a run parameter its process declares and its first step sets (`RT > RT-RUNS`, CR.63). |
| **role**, **role type** | What a prompt is executed as; a role type names the tools the prompt gets (`RT > RT-TOOLS`, CT.9). |
| {++**replay key**++} | {++The key under which the result of a tool call of a session is stored, kept for a set number of days and up to a set number per session; agents list past tool calls, search their results and read a result in pages by it (`RT > RT-TOOLS`, CT.19).++} |
| **profile** | A named configuration for sending a prompt: the provider and model, the transport, effort and thinking settings, the tools and how tool calls are approved (D-70; `RT > RT-QUEUE`, CR.22, CR.75; `RT > RT-CONFIG`, CS.3). |
| {++**adapter** (of a provider)++} | {++The way the runtime reaches a provider's API: one of its own clients (the direct client with a base address, the provider client), the Vercel AI SDK as one adapter for many APIs, or the provider's official SDK. A provider can have several; a profile names the one it uses (`RT > RT-PROVIDERS`, CS.21).++} |
| {++**preset** (of a provider)++} | {++A provider with its way in that the first version knows ready-made (the providers `RT > RT-PROVIDERS`, CS.12 lists); any endpoint compatible with Anthropic's or OpenAI's API can be configured without one (CS.12).++} |
| {~~**aspect guidelines**~>**aspect guidelines**, **aspect**, **choice**~~} | {~~Sections of guideline text, each with options; prompt assembly takes one option per section, chosen over levels (`RT > RT-HOLDS`, CR.61).~>Guideline text grouped in aspects, each with choices; a choice is its own text or a guideline file. Prompt assembly takes, for each aspect, the texts of the choices in effect, resolved over levels from the aspect's default to the todo, a later level replacing the choices below it, adding to them or removing some of them (`RT > RT-HOLDS`, CR.61).~~} |
| {++**night mode**++} | {++An aspect of the aspect guidelines that is sent while a variable of the runtime is on: the agent then asks nobody, decides by itself, records each decision as a question block with its answer, and stops only before what cannot be undone (`RT > RT-HOLDS`, CR.121). Who switches it on, and for which of a person's runtimes, is open (PQ-35).++} |
| {++**assist**++} | {++A prompt of the template category *assist prompts* that the runtime carries for one use: Grill me, Explain in detail and proposed answers on a question of a document under review; Explain a decision and Grill me at a process decision; Finish review round; the gate decision; out of budget; the reminder about background work. Every host sends it into a run of its own (`RT > RT-HOLDS`, CR.119).++} |
| **pre-prompt**, **follow-up** | A prompt an item sends in its session before its main prompt, and one it sends after it (`RT > RT-QUEUE`, CR.15). |
| **timed request** | A prompt the queue sends on a schedule (`RT > RT-QUEUE`, CR.19); it is sent only while a host has the runtime running (`RT > RT-INSTALL`, CR.44). |
| **staged** | The state of a new queue item: queued but not released; distinct from pending (`RT > RT-QUEUE`, CR.69). |
| {++**lane** (of a run)++} | {++The order of a run's queue items, executed one at a time; an item that is not sent can be moved to another place in it, and chat sends stand outside it (`RT > RT-QUEUE`, CR.15, CR.67, CR.127).++} |
| {++**chat send**++} | {++A prompt a user sends from a chat into a session: a queue item of its own kind, outside the runs' lanes, which takes the session's one busy slot (`RT > RT-QUEUE`, CR.15, CR.64).++} |
| {++**marker** (of a process step)++} | {++The entry the runtime queues behind a process step's prompt in the run's lane; the process moves when the lane reaches it with the step's items done, and an item of the step that failed holds it (`RT > RT-RUNS`, CR.123).++} |
| {++**control item**++} | {++A queue item the runtime carries out itself instead of sending a prompt: starting, pausing, interrupting, resuming or silencing runs, also of another quest or on another machine; with them the extension plans items that wait for a todo, a run or a notification, a Notify item that sends one, and a barrier between runs. They are planned in the extension; which are in the first version and how far they reach is open (`PAR > PAR-APPROACH`, CW.13; `PAR > PAR-CROSS`, CW.20; PQ-64).++} |
| **waits**, **is held**, **paused** (a run) | A run **waits** while its item is still being executed and blocked in something (an open ask, a declared wait, its own background work, a lease, a secret to unlock, a result to apply or discard); it goes on by itself when the cause ends. A run **is held** when its next item is not executed at all (open decisions, a blocked todo, needs attention, an error, out of budget); its automatic sending is off until the user resumes it. A run is **paused** when the user paused it (`RT > RT-QUEUE`, CR.23; `RT > RT-ASKS`, CP.21). |
| **settled** (an ask) | Answered, closed unanswered because the execution that asked was ended, or resolved by its declared default (`RT > RT-ASKS`, CP.20). |
| **done notification** | A prompt queued ahead of every other pending item when an item is finished or has ended in an error that will not recover; it carries the outcome and goes to the run and session that queued the item (`RT > RT-QUEUE`, CR.21, CR.93). |
| **journal of asks and answers** | A store of the runtime, per host and quest, in time order: every ask put to the user with its answer and the run it came from, every answer handed to the user without an ask, every message written to a waiting turn (`RT > RT-HOLDS`, CR.55; planned). |
| **ask envelope** | The one form of every question the runtime puts to a person: a stable id, a kind, the allowed responses, an optional schema of the response, and a deadline with a safe default when the one who asks declares them (`RT > RT-PROTO`, CP.8; a proposal the interface specification settles). |
| **reverse request** | A request from the runtime to the host: an ask, a notification, opening a file or a document, a call of a host tool (`RT > RT-PROTO`, CP.10). |
| **quest owner** | The user who answers the asks that concern a quest, first after the person the process or the todo names (`RT > RT-ASKS`, CP.16, CP.17); a quest records it (`TAC > TAC-PEOPLE`, CI.11). |
| **quest member** | A user registered as a member of a repository quest, also the same user on a further machine (`USR > USR-GROUPS`, U-16; `PAR > PAR-QUESTS`, CQ.7). |
| **coordinator** (of a review round) | The user who starts a review round, through their runtime, or through their application for document kinds the runtime does not know; the copies return to them, and they decide when the round is merged (D-70; `USR > USR-GROUPS`, U-15; `TAC > TAC-REVIEW`, CV.12). |
| **review copy**, **base** | {~~The copy of the document set a member annotates and returns in the round's thread; the base is the documents as the round sent them out. Both are kept in the round folder (`TAC > TAC-REVIEW`, CV.12, CV.13).~>The copy of the document set a member annotates and returns, through tac or another way; the base is the documents as the round sent them out to everyone. The base is kept in the round folder's `outbound/base/`, a returned copy in its `returned/<member>/` (`TAC > TAC-REVIEW`, CV.11, CV.12, CV.17).~~} |
| {++**review**, **review folder**++} | {++A team review of a set of documents, over one or more rounds, with its members and its coordinator. Its record is the review folder `reviews/<review-name>/` beside the documents, in the documents' storage, which is usually version control; its `review.yaml` names the documents, the members, the coordinator, the rounds and what was sent. tac is the transport, not the record (`TAC > TAC-REVIEW`, CV.13, CV.17).++} |
| {++**review document bundle**++} | {++The documents of a review round as they travel to a member, and a member's copy as it travels back: through tac, or another way (exported and imported as a file, by mail, put into the review folder by hand) (`TAC > TAC-REVIEW`, CV.11, CV.19; `TAC > TAC-WEBWORK`; D-74). How a round's set travels through tac is open (PQ-66).++} |
| {++**guest** (of a review round)++} | {++A reviewer who is not on the round's review team: returns a copy by another way than tac, is named by the coordinator with name and role, and the merge writes a question about the guest (`USR > USR-GROUPS`, U-17; `TAC > TAC-REVIEW`, CV.16).++} |
| **approved by** (Tom Secrets Manager) | What a program is once Tom Secrets Manager lets it read secrets: the runtime, once per runtime installation, and the tac server, each as a program of its own (`RT > RT-SECRETS`, CS.9; D-69). |
| **access key** | The key of an account on a tac server; whoever installs the tac server creates the first account and its first access key, and with it a person joins the tac server and creates a team (`TAC > TAC-PEOPLE`, CI.20; `TAC > TAC-BACKENDS`, CA.27). |
| **notification**, **command** (between runtimes) | The two kinds of message between runtimes: a notification is live only and not stored; a command is stored and taken by the first runtime of the target quest that acknowledges it (`TAC > TAC-COORD`, CA.19). Their further senses are asked in PQ-58. |
| **capability block** | A part of `tac/2.0` that a service announces it implements, when a tac client connects (`TAC > TAC-SPEC`, CA.37). |
| **relay** | The part of the tac server that carries TAC and MCP for machines that are not on the VPN, and only forwards (`TAC > TAC-BACKENDS`, CA.30). The word names nothing else. |
| **coordination repository** | The git repository in which the GitHub backend keeps a team's leases and endpoints as refs, in place of a service (`TAC > TAC-BACKENDS`, CA.26). |
| {++**coordination page**++} | {++The view of a team's coordination: the team runtimes with their runs, the leases with what holds them and what waits for them, the endpoints, the commands not yet taken, the repositories the fast-forward skipped and the orphans, with actions that free leases, resend or drop commands and retry a skipped update, each confirmed and announced to the team runtimes (`CLI > CLI-UI`, CU.18; planned).++} |
| {++**orphan**++} | {++A working tree or a branch of an execution that no lease names any more; the coordination page shows it, and the user integrates, keeps or removes it (`PAR > PAR-APPROACH`, CW.29; planned).++} |
| **repository server** | Where a repository is kept and from which its name is taken, for example GitHub (`TAC > TAC-COORD`, CA.10). |
| **web runtime service** | The HTTP-based program on a server through which an application on a phone, on a tablet or in a browser uses a runtime: it connects to a runtime on the application's behalf and reaches tac through that runtime (`RT > RT-INSTALL`, CR.108, CR.110; D-65). What it is beyond that is open (PQ-38). |
| **web runtime client SDK** | The client SDK, in Dart and in JavaScript / TypeScript, with which such an application talks to a web runtime service (`CLI > CLI-PACK`, CL.12; D-65); what it is beside the runtime client SDK is open (PQ-41). |
| **standalone runtime** | A runtime that outlives its host, to which a runtime client attaches to supervise and detaches again; later (`SCO > SCO-LATER`, L-5). |
| **always-on machine** | A machine that runs without pause and can run runtimes without a window (`NFR > NFR-TOPO`, T6, later), and the fleet's place for its tac server (`LAND > LAND-WAIT`, E-17). |
| **the `_ai` state** | The shared repository of quests, todos and processes, cloned once per machine; its folder is found as the `_ai` folder of the workspace folder, else of the root (`RT > RT-LOCATIONS`, CR.33). |
| **root**, **workspace folder** | The workspace folder is the folder a host works in; the root is the nearest folder at or above it that holds `.tom/tom_root.yaml`, and a workspace folder with none above it is its own root (`RT > RT-LOCATIONS`, CR.33). |
| **classic quest** | A quest that is a folder in the shared repository of the `_ai` state; whoever shares that repository shares the quest (`PAR > PAR-QUESTS`, CQ.1). The standard for the `_ai` format (S22) calls it a "folder quest". |
| **repository quest** | A quest in a repository of its own, which the shared repository ignores; S22 calls it a "repo-based quest". Its two forms: a **single-quest repository**, one clone of the quest's repository at the branch its entry names, at the quest's place; a **multi-quest repository**, which holds one quest per branch `quest/<id>`, is cloned once per machine without a checkout of its own, and has each quest as a working tree of its branch at the quest's place (`PAR > PAR-QUESTS`, CQ.1). |
| **register of quests** | The file `_ai/quests.yaml`, which lists every quest of the `_ai` state with its type and its setup; a workspace's list picks from it (`RT > RT-LOCATIONS`, CR.100; `PAR > PAR-QUESTS`, CQ.9). |
| **classes of files** (of a quest) | Every file of a quest is **shared** (tracked and merged between machines), **per host** (tracked, one file per host, written only by that host and never merged), **derived** (built when needed, not tracked) or **machine-local** (not tracked) (`RT > RT-HOLDS`, CR.47; `PAR > PAR-QUESTS`, CQ.11). |
| {++**dated journal**++} | {++A shared Markdown file of a quest made of dated sections — the progress, the deferred work, the documentation updates — merged between machines as the union of its sections, sorted by date and time (`PAR > PAR-QUESTS`, CQ.12; the merge planned).++} |
| **personal repository** | One repository per user, cloned into the `_ai` state, with a folder per quest, for the files that are only theirs (`PAR > PAR-QUESTS`, CQ.2). Whether it exists beside the per-host files of the standard is open (PQ-53). |
| {++**old extension**++} | {++The VS Code extension as it is today (`tom_ai/vscode/tom_vscode_extension`, quest `vscode_extension`), with an engine of its own; it is not a host of the runtime, and it is left as it is while the new extension is built (`LAND > LAND-WAIT`, E-22; `RT > RT-HOLDS`, CR.112; D-73). "The VS Code extension" alone is written where nothing of D-73 is meant.++} |
| {++**new extension**++} | {++The copy of the old extension in the repository `tom_ai_build` (`tom_ai/ai_build`), with an extension id of its own, rewired to the runtime as its VS Code host until every feature of the old extension works as before, distributed and with a team; it carries the old one's views over (`SCO > SCO-IN`; `SCO > SCO-OUT`, O-1; `RT > RT-INSTALL`, CR.142; D-73). Its folder is not named yet, and its identity beside the old one is open (PQ-60).++} |
| {++**copy point**++} | {++The moment the old extension is copied for the new extension; the two diverge from it (`RISK > RISK-RISKS`, R-1; `DEL`; D-40, D-73). When it is, and from what, is open (PQ-61).++} |
| {++**swap**++} | {++The new extension taking the old one's place, so that it looks like the old one's next major version; the old extension is then retired and archived, and both may be maintained side by side for a while first (`RISK > RISK-RISKS`, R-32; `DEL`; D-73). The new extension's identity, place and version after it are open (PQ-60).++} |
| {++**parallel period**++} | {++The time in which the old and the new extension are both in use: on one machine the old extension's own engine, which is not a runtime, and the runtime then work on one `_ai` folder (`RT > RT-HOLDS`, CR.112; `NFR > NFR-TOPO`, T1; `RISK > RISK-RISKS`, R-31; D-73). Whether both work on the same quest at the same time is open (PQ-36), and so is the format version both use (PQ-40).++} |
| {++**feature baseline**++} | {++The features of the first version: those of the VS Code extension, built and planned, of Webwork's plans for the runtime and tac (team review and review document bundles first), and of this quest's queued todos and documents, carried across machines, between the members of a team and over the internet. A feature of it is in the first version unless a decision puts it out of scope or later (`SCO > SCO-IN`; D-74).++} |

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
| server (alone) | {~~**tac server**,**MCP server**~>**tac server**, **MCP server**~~}; the **web runtime service** by its name |
| client (alone) | **runtime client**, **tac client**; the libraries are the **client SDKs** |
| owner (alone) | owner of a team, owner of a quest, product owner |
| runtime host server | **web runtime service** (D-65) |
| remote runtime service, remote runtime client SDK | **web runtime service**, **web runtime client SDK** (D-65) |
| relay (for anything but the tac server's relay) | the **web runtime service**, where a device is meant to reach a runtime |
| review application | not part of this product: reviewing is part of the applications that carry the review component (D-67) |
| pairing (with Tom Secrets Manager) | **approved by** Tom Secrets Manager (D-69) |
| folder of the `_ai` state (as a kind of resource) | a part of the `_ai` state's repository, named with `git:` (D-68) |
| folder quest, repo-based quest | **classic quest**, **repository quest** (the words of S22 for them) |
| runtime (for an installed copy) | **runtime installation** |
| {++the split++} | {++**copy point**, **swap**, **new extension** (D-73)++} |
| {++v1, the stable extension++} | {++**old extension**++} |
| {++the second extension, v2++} | {++**new extension**; "v2" only in the product owner's words and as the version the swap may give it (PQ-60)++} |
| {++round folder (for a whole review)++} | {++**review folder**++} |

> **❓ PQ-58 (2026-11-25T23:10+01:00) — the words for the new extension, and the words the document uses in several senses:** Are the words the glossary now uses for the second extension and for Webwork's teams right, and should each sense of the ten words listed below get a word or a fixed qualifier of its own?
>
> **Context:** The glossary (`GLO`, section 4 of the Project Idea) fixes one meaning per term; the terminology document of the quest (S21) holds the same entries, and the Solution Blueprint (the next phase, which turns this Project Idea into a structured design) will cite the glossary for every term. Two groups of words are concerned.
>
> **1. The words of D-73.** The product owner's instruction (b) of this round (S31) reads: "I want to create a second extension for this and leave the existing extension alone until we have really finished the new extension. For this we'll make a copy of the extension in the ai_build repo … Once the new extension is working fine and stable I will retire the old extension and move the new one in its place, so it looks as if it is just a new (v2!) version of the extension. Maybe I will maintain both vs code extension for longer." `DEC`, D-73 writes it: "The old extension (`tom_ai/vscode/tom_vscode_extension`) is copied into the repository `tom_ai_build` (`tom_ai/ai_build`) as the new extension, with an extension id of its own, and the copy is rewired to the runtime as the VS Code host until every feature of the old extension works as before, only distributed and with a team. The old extension is left as it is meanwhile. When the new extension works and is stable, it takes the old one's place (the swap) and looks like its next major version (v2); the old extension is retired, and both may be maintained side by side for a while." The round gave the glossary five entries for it, and every part of the document now uses them:
>
> - **old extension** — "The VS Code extension as it is today (`tom_ai/vscode/tom_vscode_extension`, quest `vscode_extension`), with an engine of its own; it is not a host of the runtime, and it is left as it is while the new extension is built (`LAND > LAND-WAIT`, E-22; `RT > RT-HOLDS`, CR.112; D-73). "The VS Code extension" alone is written where nothing of D-73 is meant."
> - **new extension** — "The copy of the old extension in the repository `tom_ai_build` (`tom_ai/ai_build`), with an extension id of its own, rewired to the runtime as its VS Code host until every feature of the old extension works as before, distributed and with a team; it carries the old one's views over (`SCO > SCO-IN`; `SCO > SCO-OUT`, O-1; `RT > RT-INSTALL`, CR.142; D-73). Its folder is not named yet, and its identity beside the old one is open (PQ-60)."
> - **copy point** — "The moment the old extension is copied for the new extension; the two diverge from it (`RISK > RISK-RISKS`, R-1; `DEL`; D-40, D-73). When it is, and from what, is open (PQ-61)."
> - **swap** — "The new extension taking the old one's place, so that it looks like the old one's next major version; the old extension is then retired and archived, and both may be maintained side by side for a while first (`RISK > RISK-RISKS`, R-32; `DEL`; D-73)."
> - **parallel period** — "The time in which the old and the new extension are both in use: on one machine the old extension's own engine, which is not a runtime, and the runtime then work on one `_ai` folder (`RT > RT-HOLDS`, CR.112; `NFR > NFR-TOPO`, T1; `RISK > RISK-RISKS`, R-31; D-73)."
>
> The glossary's table of words not used adds: "the split" → copy point, swap, new extension; "v1, the stable extension" → old extension; "the second extension, v2" → new extension, "v2" only in the product owner's words and as the version the swap may give it (PQ-60). "The split" was the word for moving the engine out of the running extension stage by stage, which D-73 replaces. The product owner's own words are "the existing extension", "the new extension", "a second extension" and "v2".
>
> **2. Webwork's "group".** Webwork's areas (its decision DPAREAS-7) and part of its plans speak of a "group" of people; Webwork's own todo `12a_woneb2` settles it: "a Webwork team (DPAREAS-7) is a tac **team**, a group of people (members, owners, invitations, conversations, review sets) … Use the word "team" throughout." The glossary has **team** ("A group of users: members, owners, invitations, conversations, review sets, and the right to control each other's runtimes"), **team runtimes** ("All the runtimes started by the members of a team (through their hosts). "Agent group" is not used for them.") and, among the words not used, "group — only in *group of todos*, *component group* and "several members" of a conversation; never a thing of its own". So the round writes Webwork's group as **team**, its members' runtimes as **team runtimes**.
>
> **3. Ten words still used in several senses** (found by round 4's consistency read and still in the text), with no glossary entry that tells the senses apart:
>
> - **conversation** — the exchange with a model in a session (`RT > RT-QUEUE`, CR.18 "the next prompt starts without the earlier context"; `RT > RT-PROTO`, CP.7 "A conversation with a model is modelled as thread, turn and item"; `GLO` session "a named line of conversation with a model"), and a sequence of messages between users (`GLO` conversation; `TAC > TAC-CONV`). `CLI > CLI-UI`, CU.6 has both in one table: the group **Conversation** ("conversation, message, prompt input …", the chat with a model) and, in the group **Messaging**, "conversation list, conversation, composer". The VS Code extension calls the model side **chat** (its chat panel, `CLI > CLI-SCREENS`, SC-1), and the glossary now has **chat send** (a prompt a user sends from a chat into a session, `RT > RT-QUEUE`, CR.15).
> - **item** — one entry of a run's queue (`GLO` queue item), and a piece of a turn: CP.7 "a turn holds items (text, reasoning, tool call, ask, result), and an item has started, delta and completed events". CP.7 is marked a proposal; "thread" and "turn" have no glossary entry.
> - **session** — a named line of conversation with a model (`GLO`), and in a few places another writer of files: `TAC > TAC-COORD`, CA.17 "the todo files, the process state and the progress file are written by many sessions at once, by design"; `PAR > PAR-PROBLEM`, P-5 ("in clones several sessions share") and P-9 ("Other sessions' uncommitted work is in the way"); `RISK > RISK-RISKS`, R-9 ("Other sessions, runs and machines write to the same repositories") and R-11 ("every other session's base"); `PAR > PAR-APPROACH`, CW.11; and `PAR > PAR-CROSS`, CW.18 lists "a session" as something addressed across quests. The writer meant there is an execution or a runtime.
> - **notification** — a live message between runtimes that is not stored (`TAC > TAC-COORD`, CA.19); a message kind from a runtime, shown to users (`TAC > TAC-KINDS`, CM.2); what a host shows its user (`RT > RT-PROTO`, CP.10, CP.13; `RT > RT-MACHINE`, CR.36); the done notification, which is a prompt (`RT > RT-QUEUE`, CR.21, CR.93); a push to a device (CM.6); and, in the extension's plans the round added (`PAR > PAR-CROSS`, CW.20; PQ-64), a named notification a queue item waits for and a Notify item sends.
> - **command** — what a host sends its runtime (`RT > RT-PROTO`, CP.3); a stored message between runtimes, taken by the first runtime of the target quest (CA.19); a message kind (CM.2); a shell command (`RT > RT-TOOLS`, CT.1 "running commands").
> - **member** — of a team (`GLO`); of a review round (`TAC > TAC-REVIEW`, CV.12 "sends a review request … to every member"; CV.17 `returned/<member>/`); of a quest (`USR > USR-GROUPS`, U-16, "quest member").
> - **strict** — a tac server's setting for identity (`GLO` strict server) and a repository's mode (`GLO` strict mode); `TAC > TAC-PEOPLE`, CI.5 has both in one table.
> - **service** — "the tac service" (the program `tom_tac_service`), "the local tac service", "the Tom Secrets Manager service", "the web runtime service"; `GLO` fixes "server" (always with its kind), not "service".
> - **process** — a defined way of working (`GLO`), and an operating-system process; CP.2, CP.9 and N-15 say "operating-system process", while CP.1, `RT > RT-MACHINE`, CR.38 and CA.8 say "process" for it.
> - **reminder** — a todo's reminder (`RT > RT-HOLDS`, CR.50), the one reminder to an agent about its own background work (`RT > RT-QUEUE`, CR.88), and tac's message reminder between users (`TAC > TAC-KINDS`, CM.4). CR.19 and CM.4 already tell them apart in a sentence.
>
> One more is a second name, not a second sense: **change-branch mode**, agreed in the terminology (S21, TQ-9) as another name of **worktree mode** and used once (`PAR > PAR-APPROACH`, CW.2 "also called change-branch mode").
>
> **Why I ask:** The glossary is the agreed terminology (D-60, D-70): the words of group 1 and 2 are new to it, chosen by this round from the triage's naming rules, not by the product owner, and every part of the document already uses them, so a different word is cheapest now. "v2" in particular is the product owner's word, but written as a name it would read as a version number before the version after the swap is decided (PQ-60), and "old" may sound like a judgement while both extensions are maintained. Group 3 is where a Solution Blueprint goes wrong without anyone noticing: a requirement written for "a notification" may be implemented as a live message between runtimes or as a message to a user, and "every member of a round" may be read as every member of the team. New words or qualifiers change what was agreed; the items listed above would be reworded in the next round, and the terminology document (S21) would get the same entries.
>
> - (a) **The round's words stand, qualifiers only for the ten words.** Old extension, new extension, copy point, swap, parallel period and team for Webwork's group stay as written. The ten words keep their senses; the glossary gets one entry per sense, and each item writes the word with its qualifier where the sense is not plain from the sentence ("a notification to the user", "a tac command", "an operating-system process", "a member of the round"). Nothing is renamed; "change-branch mode" stays as the second name.
> - **(b)** **The round's words stand, and a word or a fixed qualifier per sense** for the ten words, in the glossary and the terminology document, every item reworded in the next round: **chat** for the exchange with a model (the extension's word; `CLI` and the UI components), "conversation" only for messages between users; a turn holds **parts**, not items (CP.7), and **thread** and **turn** get entries marked as a proposal with CP.7; "session" never for a writer of files — **execution** or **runtime**, by what is meant — and CW.18 addresses a todo, a run and a user, not a session; between runtimes a **live message** (CA.19's notification, and what the extension's Notify item would send if PQ-64 takes it over) and a **stored command** (CA.19's command); a **command** alone is what a host sends its runtime, a **shell command** what a tool runs; a **notification** is what a user is shown, a **push** what reaches a device, and the **done notification** keeps its name; a **reviewer** is a member of a review round, a **quest member** a member of a repository quest, "member" alone a member of a team; **strict server** and **strict mode** are always written in full; **service** gets an entry ("a program that runs without a user interface and answers others; always with its name"); an operating-system process is always written so; a **todo reminder**, the **background-work reminder** and a **message reminder** (tac's); "change-branch mode" is dropped.
> - (c) **The product owner's words for the extensions, and (b) for the rest.** The old extension is written "the extension (v1)" and the new extension "the extension v2", as the instruction says; copy point, swap, parallel period and team stay. The ten words are treated as in (b). "v2" is then a name before it is a version, and the glossary has to say that the version after the swap is still open (PQ-60).
> - (d) **The round's words stand, and nothing changes for the ten words:** the context of each sentence makes the sense plain, and the glossary keeps one entry per word.
>
> *Recommendation:* (b) — the round's words follow the product owner's own "existing", "new" and "second extension" without turning "v2" into a name before PQ-60 decides the version, and each pair of group 3 is one a reader can confuse; the replacement words are ones the document or the extension already uses, and fixing them now is cheaper than in a Blueprint that cites the glossary everywhere.
>
> *Assumption until answered:* the glossary's entries old extension, new extension, copy point, swap, parallel period, team and team runtimes stand as written; the ten words keep one entry each as they stand, and the items write the word with its qualifier where the sense is not plain; "change-branch mode" stays as the second name of worktree mode.
>
> **Answer:**

## <!--[SCO]--> 5 Scope

The specification's root is `tom_ai/ai_build/specification/`.

### <!--[SCO-IN]--> 5.1 In scope

{++The first version has the feature baseline of D-74: the features of the VS Code extension, built and planned; of Webwork's plans for the runtime and tac, team review and review document bundles first; and of this quest's queued todos and documents — carried across machines, between the members of a team and over the internet. A feature of that baseline is in the first version unless `SCO-OUT` or `SCO-LATER` puts it elsewhere; the areas below hold it. (-> D-74) (<- S31; S23; S25; S29; S30)++}

| Area | In scope | Source |
| --- | --- | --- |
| Runtime core (`CR`) | The `_ai` formats and stores in format version 11; processes and runs; the queue; sessions; model and agent transports, among them the Agent Client Protocol in both directions; locations and configuration; machine-wide state; installation, lifetime and versions; the web runtime service for applications on phones, on tablets and in browsers (what it is beyond its name is an open question: PQ-38) | S1 § 5; S22; PQ-28 |
| Protocol and hosts (`CP`) | The runtime protocol (commands, numbered events, reverse requests, asks); the host interface; routing and escalation of asks; versions and compatibility | S1 § 6 |
| Tools and MCP (`CT`) | Runtime tools, host tools, the runtime's MCP server, the runtime as MCP client of external MCP servers | S1 § 6.3, § 6.4 |
| Coordination between runtimes (`CA`) | Presence and discovery, leases on named resources (a name starts with the prefix of its notation, `git:` for now), held by a runtime for an item of a run, messages between runtimes, endpoints; the backends local (one machine), GitHub (one user's machines, or a simple team of several members) and tac server; the tac server's relay | S1 § 7.1, § 7.2; S5; S6; PQ-10, PQ-23, PQ-29, PQ-31 |
| People, teams and identity (`CI`) | Participants, teams, invitations and team tokens, identification, the open or strict tac server, the pairing of devices, permission for remote control, a quest's home team and quest owner | S1 § 7.3; PQ-9, PQ-12, PQ-13, PQ-20, PQ-23 |
| Messaging (`CM`) | Conversations, message kinds, reminders, presence-aware delivery, history and read state | S1 § 7.4, § 7.5 |
| Documents and review (`CV`) | {~~Blobs with lifetimes and pinning, review sets, the review exchange~>Blobs with lifetimes and pinning, review sets, the review folder with its rounds, the review exchange through tac beside the other channels (export and import, mail, by hand)~~} | {~~S1 § 7.6, § 7.7~>S1 § 7.6, § 7.7; S29 (FQ-9, FQ-11)~~} |
| Parallel work and integration (`CW`) | Claims in the queue, a repository's strict or worktree mode, the integration step and queue, the resources a todo names, the record of a todo's commits, quiescence, cross-quest addressing and delivery | S1 § 10.4, § 10.5 |
| Client SDKs (`CL`) | The runtime client SDK and the tac client SDK in nine languages, with one conformance suite; the web runtime client SDK in Dart and in JavaScript / TypeScript | S1 § 12.1; PQ-28 |
| UI components (`CU`) | `tom_ai_runtime_ui`, the descriptions of its screens and components, a gallery application | S1 § 12.2, § 12.3 |
| Supervision (`CK`) | trc, on the desktop, the phone and the tablet (on the phone and the tablet through the web runtime service; an open point: PQ-49) | S1 § 12.4; PQ-9, PQ-28 |
| Repository quests and personal files (`CQ`) | The three quest types and their register, the quest operations, the personal repository, personal notes (where personal files are kept is an open question: PQ-53) | S1 § 12.5; S2 § 3.7; S22 |
| Secrets, configuration and providers (`CS`) | Secret references and their resolution; the configuration split into the repository's, the team's and the runtime's part; the model providers | S1 § 5.5, § 5.8; S7 |
| {~~The split (no area of its own: D-40, D-41; N-24, N-32, N-33; R-1; `DEL`)~>The new VS Code extension (no area of its own: D-73; N-24, N-32, N-33; R-1; `DEL`)~~} | {~~Extracting the engine from the VS Code extension, with a stable extension beside it while that runs~>A copy of the old extension in `tom_ai/ai_build`, rewired to the runtime as the VS Code host until every feature works as before, distributed and with a team, and its taking the old one's place (the swap); its views are carried over, not redesigned (O-1). Open: its identity beside the old one and the swap (PQ-60), the copy point (PQ-61), what "every feature as before" leaves out or adds (PQ-62)~~} | {~~S1 § 13.3~>S31; D-73~~} |

### <!--[SCO-OUT]--> 5.2 Out of scope

- **O-1** The VS Code extension's own features: its views, panels and editors,
  and the tools that need VS Code. {~~They stay in the extension, which becomes
  a host.~>They stay VS Code views: the new extension carries them over unchanged as the VS Code host's own.~~} Its messaging views, which it gets once the runtime is built, are
  among them: messaging is built here as Flutter components only {~~(O-3). (S1 § 6.3; S2 § 3.3; PQ-30)~>(O-3). (<- S1 § 6.3; S2 § 3.3; S17 package.json, quick_reference.md, marktext_integration.md) (-> PQ-30, D-73)~~}
- **O-2** The applications that host a runtime — Webforge, Webwork and their
  own tools and screens — apart from what they need from this product. {~~(S3,
  "Why Webwork needs it, and when" and WR-7; S14, part two, § 5)~>(<- S3 "Why Webwork needs it, and when", WR-7; S14 part two § 5)~~}
- **O-3** User interface components for platforms other than Flutter. {~~(S4,
  note l)~>(<- S4: note l)~~}
- **O-4** Transports implemented by a host: the VS Code language-model
  transport and the Copilot chat transport are not carried by the runtime; Copilot is reached
  only through direct calls and its SDK. {~~In the VS Code extension the
  "VS Code LM" transport inside its Anthropic panel stays until the route
  through the Copilot SDK works. (S2 § 5, FO-2; S22 § 2.3, AC-19)~>In the old extension the "VS Code LM" transport inside its Anthropic panel stays until the route through the Copilot SDK works; whether the new extension keeps it is an open question (PQ-62). The old extension removes its Copilot chat panel and transport, the answer wrapper and answer files, and the VS Code language-model tools (O-11). (-> FO-2) (<- S2 § 5; S22 § 2.3 AC-19; S23: ccparity_c_transports-4; 01_aifmt-1, in progress)~~}

> **❓ PQ-62 (2026-11-25T20:48+01:00) — what "every feature as before" means for the new extension:** Which of the old extension's features that the runtime does not carry — the VS Code language-model transport, the per-quest Telegram, the script server — does the new extension keep, and which views of team work does it add?
>
> **Context:** The product owner's instruction (b) of this round (`answers.md`, S31): "we'll make a copy of the extension in the ai_build repo and work on this until it works with the AI runtime and all features working as before (only distributed and with a team). Once the new extension is working fine and stable I will retire the old extension and move the new one in its place". It is decision **D-73** (written by this round). Words used here: the **old extension** is the VS Code extension as it is today (`tom_ai/vscode/tom_vscode_extension`), with its engine inside; the **new extension** is its copy in `tom_ai/ai_build`, rewired to the runtime as the VS Code host; a **host** is the program that starts a runtime and adds a user interface; a **transport** is the runtime's way to a model or an agent; **tac** is the coordination and messaging service; **trc** is the supervision application. Four features of the old extension stand against items of this document:
>
> 1. **The VS Code language-model transport.** D-7 (`DEC`): "No transports implemented by a host: the runtime does not carry the VS Code language-model and Copilot chat transports; Copilot only through direct calls and its SDK." `SCO > SCO-OUT`, O-4: "In the old extension the "VS Code LM" transport inside its Anthropic panel stays until the route through the Copilot SDK works; whether the new extension keeps it is an open question (PQ-62). The old extension removes its Copilot chat panel and transport, the answer wrapper and answer files, and the VS Code language-model tools (O-11)." The removal is in progress (vscode_extension `01_aifmt-1`); the VS Code LM transport itself stays in the old extension until the route through the Copilot SDK works, and what the new extension does is this question.
> 2. **Telegram.** The old extension has a Telegram bot per quest: commands for the queue, the chat and the workspace, live forwarding of the trails, questions answered with `<run>: answer`, todo reminders (`telegram_integration.md` § 2, § 6, § 7; vscode_extension `vscimpb25`, `vscimpb26`). It is today the only channel that reaches the user away from the host. For the runtime, D-6 says "Telegram is deferred", and `SCO > SCO-LATER`, L-9 defers "one bot token for every runtime, one chat per machine" (this quest's todo `ww_f_collab-6`, kept deferred). `RT > RT-ASKS`, CP.18: an ask leaves the host that asked only through tac, to the person's other devices.
> 3. **The script server.** Dart scripts and the VS Code bridge reach the old extension's JSON-RPC server on ports 19900 – 19909 through `tom_vscode_scripting_api` 7.0.0, which also has a VS Code namespace (calls into VS Code itself). `CLI > CLI-PACK`, CL.10: "The Dart runtime client SDK grows out of today's Dart client of the extension's script server … Scripts that use that client keep working against a VS Code window and against a runtime." While the old and the new extension are both installed on a machine, two such servers may run.
> 4. **Views for team work.** The old extension has no view of other people's runtimes, leases, claims, the integration queue or asks from other runtimes. Messaging is decided: the VS Code extension gets messaging once the runtime is built, with views of its own that are not built here (`USR > USR-HOSTS`, U-8; `SCO > SCO-OUT`, O-1; answer to PQ-30); this product builds messaging only as Flutter components (O-3). The screen inventory has SC-19 "Window status — starting point (the list of team runtimes)" and SC-28 "none in the extension: the coordination page (CU.18); the extension plans a view of resource leases with a clean-up of dead leases"; the **coordination page** (`CLI > CLI-UI`, CU.18) "shows the team runtimes with their runs, the leases (stale ones marked) with what holds them and what waits for them, the endpoints, the commands not yet taken …". Nothing says whether the coordination page and the list of team runtimes become VS Code views of the new extension.
>
> **Why I ask:** "All features working as before" is the bar for retiring the old extension (D-73), so every feature the new extension does not have must be named, or the acceptance (PQ-57) cannot be checked. D-7 and D-6 decide what the *runtime* carries; they do not decide what the *new extension* keeps as the VS Code host's own. If the new extension drops Telegram, a user who answers questions from the phone today loses that until trc runs on the phone (PQ-49); if it keeps it, the per-quest bot runs beside tac's routing of asks (CP.18) and two channels can answer the same ask. The script server decides whether scripts that call VS Code itself keep working. The team views decide whether a VS Code user sees, inside VS Code, who holds what (`TAC > TAC-COORD`) or only in trc.
>
> - (a) Everything as before, plus the team views: the new extension keeps the VS Code language-model transport (as the VS Code host's own, outside the runtime, against the spirit of D-7), keeps today's per-quest Telegram as its own channel beside tac, keeps a script server for the VS Code namespace, and gets VS Code views for the coordination page, the team runtimes and the asks of other runtimes, beside its messaging views (PQ-30). Nothing is lost; D-7 and D-6 are bent for the VS Code host, and the new extension grows beyond the old one.
> - **(b)** The old extension minus what the runtime decisions remove, plus two team views: the new extension does not have the VS Code language-model transport (D-7; Copilot through its SDK, CS.13) nor today's per-quest Telegram (D-6: the redesign of L-9 comes later, for every runtime; until then the user reaches a waiting ask through tac on another device); it keeps a script server for the VS Code namespace only, and every other script call goes to the runtime (CL.10); a script names which extension it wants while both run, and the ports are taken upward from 19900 as today. It gets the coordination page and the team-runtimes view as VS Code views (SC-19, SC-28), beside its messaging views (PQ-30); asks from other runtimes reach it as asks (CP.18). Every other feature of the old extension is kept; what is dropped is listed by name in the acceptance checklist (PQ-57).
> - (c) The old extension minus D-7's transports only: the VS Code language-model transport goes (D-7); the per-quest Telegram and the script server are kept as they are; besides its messaging views (PQ-30) no team views (who holds what, and which runtimes are there, is seen in trc only).
>
> *Recommendation:* (b) — it holds the bar "every feature as before" for everything the product owner has not decided away, applies D-7 and D-6 to the VS Code host as well so the runtime has one way to each model and one channel for asks, keeps scripts that call VS Code working, and gives a VS Code user what working in a team needs: who holds what and which runtimes are there.
>
> *Assumption until answered:* as (b): `SCO > SCO-OUT` O-4 says the VS Code language-model transport stays in the old extension only; the new extension has no Telegram (D-6, L-9); nothing in the Project Idea says the new extension keeps or drops the script server, and CL.10 stands; SC-19 and SC-28 stand as written.
>
> **Answer:**

- **O-5** A port of the engine to another language. The runtime is
  {~~TypeScript; other languages get client SDKs. (S1 § 4, § 12.1)~>TypeScript; other languages get client SDKs. (<- S1 § 4, § 12.1)~~}
- **O-6** Converging machines: reconciles of the fleet stay a step the user
  starts. The system answers who holds what; it does not pull or merge clones
  on its own, except in two cases: where the integration step lands an execution's own commits, and where a workspace switched on the fast-forward of repositories on which no lease is held (CW.16: off unless switched on; done when a claim is taken or when the user asks, never on a schedule). Pull and push of the `_ai` state and of a quest's
  repository are steps the user starts too (CQ.7).
  {~~(S1 § 10.4; S16; S6, BP-12, BP-18; S22 § 2.4, QM-10; S27 (`14_loose_wslayout-5`))~>(<- S1 § 10.4; S16; S6 BP-12, BP-18; S22 § 2.4 QM-10; S27: 14_loose_wslayout-5)~~}
- **O-7** A file server: tac carries documents while they travel or while a
  process pins them; the record of documents is version control. {~~(S1 § 7.6;
  FO-8)~>(<- S1 § 7.6) (-> FO-8)~~}
{~~- **O-8** Theagent_container~>- **O-8** The agent_container~~} and project_coordination work (archived in `tom_archived`) {~~as input.
  (S4, note m)~>as input.
  (<- S4: note m)~~}
- **O-9** A short process for small changes. The engine carries any
  process; which processes exist is decided where they are written. It is
  {~~proposed in the quest `tom_specs`. (PQ-4)~>proposed in the quest `tom_specs`. (-> PQ-4)~~}
- **O-10** A review application of its own. Reviewing is part of the
  applications that carry the review component: the VS Code extension today,
  Webwork and Webforge later; none of them is built here. An application that
  needs tac reaches it through its runtime, with the runtime client SDK.
  Where the review component itself is built is an open question
  {~~(PQ-43). (PQ-30)~>(PQ-43). (-> PQ-30)~~}
- {++**O-11** What the old extension removes, and the runtime therefore does not carry: the Copilot chat panel and transport, Send to Copilot, the answer wrapper and answer files, the VS Code language-model tools and the Copilot items of the queue (answer-file detection, answer-wait minutes, the Copilot Queue Wrapper); the answer-wrapper and reminder fields of a timed request; queue reminders after a wait; and memory shared across quests. The queue sends no reminders of its own (CR.19), and memory is the quest's (CR.53). (-> O-4, CR.19, CR.53) (<- S23: 01_aifmt-1, in progress; 00_aifmt-3)++}

### <!--[SCO-LATER]--> 5.3 Deferred to later

{~~Decided as not part of the first version (S1 § 11.1);~>Decided as not part of the first version (<- S1 § 11.1);~~} L-6 alone is not decided and stands here as an open point.

| Id | Feature | What defers it |
| --- | --- | --- |
| **L-1** | Todos to the cloud: handing a todo to a vendor's hosted agent, or to a runtime on a machine of our own, and integrating the branch that comes back | CQ-13: sending work out sends source code out; {~~a data policy comes first (S1 § 11.2 … § 11.5)~>a data policy comes first (<- S1 § 11.2 … § 11.5)~~} |
| **L-2** | A data policy per quest or repository: which provider may see what | DQ-8: {~~the centrally administered configuration decides for now (S1 § 11.1)~>the centrally administered configuration decides for now (<- S1 § 11.1)~~} |
| **L-3** | Asking people outside the team by e-mail, answered on a web page of the tac server | DQ-3: {~~needs the tac server to send e-mail and a small web application (S1 § 11.1)~>needs the tac server to send e-mail and a small web application (<- S1 § 11.1)~~} |
| **L-4** | The tac server sending invitation e-mails itself | DQ-2: the team owner passes the one-time password on; {~~the protocol does not change (S1 § 11.1)~>the protocol does not change (<- S1 § 11.1)~~} |
| **L-5** | Standalone runtimes that outlive their host, to which a runtime client attaches to supervise and detaches again | CQ-4, PQ-16: a runtime ends with its host; the protocol does not prevent the other; how long the runtime behind the web runtime service lives {~~is an open question (PQ-38) (S1 § 11.1)~>is an open question (PQ-38) (<- S1 § 11.1)~~} |
| **L-6** | End-to-end encryption between a device and a runtime, on top of encryption in transit and the paired device's key | Not decided as deferred. {~~The pairing of devices is in the first version (CQ-10, PQ-9);~>The pairing of devices is in the first version (-> CQ-10, PQ-9);~~} whether end-to-end encryption has to be in it too is open, and is asked with the question on phones and tablets (PQ-49) {~~(S1 § 11.1; `TAC > TAC-CRYPT`, CI.19; `NFR`, N-21)~>(<- S1 § 11.1) (-> CI.19, N-21)~~} |
| **L-7** | A review's own git repository on the tac server, for reviewers without repository access | DQ-4: {~~pinned blobs cover reading and returning (S1 § 11.1)~>pinned blobs cover reading and returning (<- S1 § 11.1)~~} |
| **L-8** | Webwork in a browser, on a phone and on a tablet, with its AI and its messaging there | WQ-1: in wave 3 of Webwork (its decision DPPHONE-5); until then these builds have neither. Webwork expects one server side to carry both: that is the web runtime service, which the first version has for the supervision application as far as the open question on it leaves that standing (PQ-38) {~~(S1 § 11.1; `NFR > NFR-TOPO`, T8; PQ-9, PQ-28; S25 (`06_woneb9`, `13_woneb5`, `10_woneb1`))~>(<- S1 § 11.1; S25: 06_woneb9, 13_woneb5, 10_woneb1) (-> T8, PQ-9, PQ-28)~~} |
| **L-9** | Telegram: one bot token for every runtime, one chat per machine | {~~FO-16 (S1 § 11.1)~>FO-16 (<- S1 § 11.1). The old extension keeps its Telegram per quest; whether the new extension does is an open question (PQ-62)~~} |
| **L-10** | Encryption at rest of messages and blobs | FO-20: {~~an option, its key in Tom Secrets Manager (S1 § 11.1)~>an option, its key in Tom Secrets Manager (<- S1 § 11.1)~~} |
| **L-11** | Billing, and running one tac server for several organisations | the first version has the account record, access keys, quotas per account and the administration interface, and is used with one account {~~(S1 § 11.1; CQ-9; `TAC > TAC-BACKENDS`, CA.27)~>(<- S1 § 11.1) (-> CQ-9, CA.27)~~} |
| **L-12** | Services that use tac directly, through the tac client SDK and without a runtime, for a part of tac such as messaging | {~~PQ-30: possible, not planned. Every application~>PQ-30: possible; to be investigated for messaging and other light parts (X-3), not planned for the first version (<- S30: tac_webwork-1). Every application~~} of the first version reaches tac through its runtime. The tac server keeps what such a service would need (it answers tac clients in a browser: `TAC > TAC-BACKENDS`, CA.28); no application of the first version uses it |
| {++**L-13**++} | {++A gateway for agents outside the product that speak A2A (Agent2Agent): agent cards for the capabilities a runtime publishes, and tasks with their states++} | {++Between the product's runtimes TAC's commands and messages do this; A2A is an option for agents outside the product, and what to take over follows from comparing it with TAC (<- S9; S30: a2a1, planned)++} |
| {++**L-14**++} | {++The OpenAI Agents SDK as a transport (handoffs, guardrails, tracing)++} | {++A second tool loop beside the runtime's own; decided after the OpenAI transports run (<- S30: xxlater1)++} |
| {++**L-15**++} | {++Tools a provider runs on its own servers (for xAI: search and code execution through its SDK)++} | {++Taken when they bring an advantage over the runtime's own tools; the SDK is experimental (<- S30: xxxai1)++} |

## <!--[LAND]--> 6 What exists today

### <!--[LAND-BUILT]--> 6.1 Built

{~~- **E-1** **The engine, inside the VS Code extension**~>- **E-1** **The engine, inside the old VS Code extension**~~}
  (`tom_ai/vscode/tom_vscode_extension`, version 0.1.0). {~~Its feature areas
  (S1 § 2.1, § 3.1; S17; S23):~>Its feature areas
  (<- S1 § 2.1, § 3.1; S17; S23):~~}
  - quests, todos (groups of two kinds: all todos of an id prefix, and a group todo that names its members, due dates with reminders and repetition, follow-ups, cross-quest blockers, a mark that only the user can do a todo, its open decisions, the role and the guideline choices it is executed with),
    memory, chat variables, roles and role types, templates, profiles;
  - processes with runs: every process runs in a run of its own, with its
    position, variables, queue lane, settings and sessions; nested
    processes, branches, conditions, decision steps, gates with decision
    buttons;
  - the queue: prompt, todo and group items, pre-prompts and follow-ups,
    {~~walks, timed requests, reminders after a wait (they leave with format version 11: S22 § 2.3, AC-22), soft interrupt,~>walks, timed requests, reminders after a wait (being removed, since format version 11 has none: O-11) (<- S22 § 2.3 AC-22; S23: 01_aifmt-1, in progress), soft interrupt,~~} done notifications,
    questions that survive a reload;
  - sessions and trails;
  - transports: the direct API, the Claude Agent SDK, a local model, {~~and the
    two host transports the runtime does not carry (`SCO > SCO-OUT`, O-4);~>the VS Code language-model transport, which the runtime does not carry, and the Copilot chat transport, which is being removed (`SCO > SCO-OUT`, O-4, O-11);~~}
  - the `tomAi_*` tools and one MCP server for all of them;
  - team review and the document browser with questions, marks and
    consolidation;
  - the format-version stamp of the `_ai` files (version 10 today, written since 2026-11-23, `_ai/format-version.yaml`; version 11 is decided and not built: S22 § 3.6) and its migration;
  - {++the preparation of format version 11, begun on 2026-11-25: shared memory and the readers of `_ai/notes` and the clarification folders are removed, the summary and raw trails are trimmed by every writer, the repositories of `repos.yaml` are served, and the Copilot removal is in progress; the per-host trails and journals, the quest's saved prompts, notes and memory, format version 11 itself and the quest management panel are planned (<- S23: 00_aifmt-1 … 00_aifmt-4, 01_aifmt-1, in progress; 01_aifmt-3 … 01_aifmt-5, 02_aifmt-1, planned);++}
  - a JSON-RPC server for scripts, and the Dart client of it,
    {~~`tom_vscode_scripting_api` 6.0.0.~>`tom_vscode_scripting_api` 7.0.0.~~}
- **E-2** **Todo follow-ups** (the first stage of coordination): a todo names
  what happens when it is done and who filed it; the done notification
  returns to the run and session that queued it (it has no default: without one, nothing is sent); an item or a walk can be
  sent into a named run of another quest on the same machine. The fields for
  claims are in the todo model {~~(`tom_todo_model` 4.2.0,~>(`tom_todo_model` 6.0.0,~~} with the item model `TomItem`, the reminder fields and the fields for a todo's role and guideline choices) and unused. {~~(S1 § 2.1,
  § 2.2; S23; S25 (`wwremind1`, `wwaspect1`))~>(<- S1 § 2.1, § 2.2; S23; S25: wwremind1, wwaspect1; tom_ai/modules/tom_todo_model/pubspec.yaml)~~}
- **E-3** **The protocol `tac/1.0`** and **`tom_tac_service` 0.1.0 in local
  mode** (`tom_ai/vscode/tom_tac_service`, a TypeScript package without
  runtime dependencies, 40 tests): presence, sessions, leases with fencing
  tokens, units, messages between runtimes, endpoints, migration and
  administration ("session" and "unit" are record names of `tac/1.0`), over HTTP and WebSocket on the local machine, with a typed
  {~~tac client. (S5; S1 § 2.1)~>tac client. (<- S5; S1 § 2.1; S17)~~}
- **E-19** **What `tac/1.0` has that the product does not use:** its session
  record (the product keeps no record for the holder of leases: a lease names
  its holder; PQ-27); declared units and infrastructure resources (a resource
  exists for tac from the moment it is claimed; PQ-23); a resource kind of
  its own for a folder of the `_ai` state (such a folder is claimed as a part
  of a repository; PQ-31); the name "agent group" with its group id (in the
  product: the team; S21, C-4); and the name "customer" (in the product: the
  {~~account). (S5 § 3.1, § 3.4 … § 3.7)~>account). (<- S5 § 3.1, § 3.4 … § 3.7)~~}
- **E-4** **The workspace layout resolver** in the extension
  (`src/utils/workspaceLayout.ts`): root, workspace folder, the `_ai` folder,
  the configuration layers, the guidelines on three levels (the root's, the workspace folder's and a project's own). {~~(S12; S1 § 2.1,
  § 5.5; S27)~>(<- S12; S1 § 2.1, § 5.5; S27)~~}
- **E-5** **Merge drivers for the `_ai` files** in TypeScript. Their source is the
  fleet's (the repository `al_the_bear`); they are built from it into the
  binaries repository. The extension carries a built copy and checks it when
  it is upgraded; it is to take the bundle from the binaries repository
  {~~(planned: vscode_extension `vscimpb152aaa`). (S1 § 2.1; S22 § 3.5; S23; S27 (`tsmergedrivers1`))~>(planned). (<- S1 § 2.1; S22 § 3.5; S17 user guide § 2 *Merge drivers*; S23: vscimpb142c; vscimpb152aaa, planned; S27: tsmergedrivers1)~~}
- **E-6** **Tom Secrets Manager clients:** {~~Dart (`tom_secrets_client` 0.2.11)~>Dart (`tom_secrets_client` 0.2.24)~~}
  and TypeScript (`@al-the-bear/tom-secrets-client` 0.1.0), client libraries in Python, Go, Rust, Java, C and C++ (each 0.1.0), and the command
  {~~line `tsm` 0.2.7. (S15: the protocol document, § 5 "The client endpoint";
  the idea document, part-clients)~>line `tsm` 0.2.15. (<- S15 protocol document § 5 "The client endpoint"; S15 idea document part-clients; tom_ai/secrets_clients/clients/dart/tom_secrets_client/pubspec.yaml; tom_ai/secrets_clients/clients/dart/tsm/pubspec.yaml)~~}
- **E-7** **The rules for parallel work** as a guideline, most of them by
  agreement. {~~(S16, § 1 … § 6 and "What enforces what")~>(<- S16 § 1 … § 6, "What enforces what")~~}
- **E-20** **Flutter packages with agent and todo views, over other backends**
  (`tom_ai/modules`): `tom_agentic_ui` 0.1.0 (the chat composer, the prompt
  queue and the prompt trail, the connection picker, the review of changes)
  over `tom_core_agentic`; `tom_ai_trail_ui` 0.1.0 (the live trails of AI
  sessions) over `tom_llm`; `tom_todo_ui` 0.2.0 (the todo row, the details
  editor, the editor of a todo file) over `tom_todo_model`. None of them
  works over the runtime. What becomes of them beside `tom_ai_runtime_ui` is
  {~~an open question (PQ-44). (S26: tom_forge `02b_woneb8`; S25:
  webwork `06_woneb9`)~>an open question (PQ-44). Webwork's AI in its wave 1b1 runs on `tom_ai_trail_ui` and moves to the runtime's components in its wave 1b2. (<- S26: 02b_woneb8; S25: 06_woneb9, 13_woneb4)~~}
- **E-21** **The specification tooling:** the binary `tomspecs` 0.18.0
  (`tom_ai/ai_build/tom_specs_clitool`, its version on 2026-11-25) and the SOM packages, which the
  {~~extension bundles today. (S1 § 3.5; `RISK > RISK-DEPS`, R-21)~>extension bundles today. (<- S1 § 3.5) (-> R-21)~~}

### <!--[LAND-MISSING]--> 6.2 Not built

- **E-8** There is no runtime package: nothing of the engine runs outside {~~the
  VS Code extension. (S1 § 2.1)~>the
  VS Code extension. (<- S1 § 2.1)~~}
- **E-9** There is no runtime process of its own and no runtime protocol; no host other
  than the extension can attach. {~~There is no web runtime service. (S1 § 2.1)~>There is no web runtime service. (<- S1 § 2.1)~~}
- **E-10** There is no Dart runtime client SDK and no client SDK in any other
  language, and no web runtime client SDK; no Flutter component over the runtime exists (the
  {~~Flutter packages of E-20 work over other backends).
  (S1 § 2.1, § 12)~>Flutter packages of E-20 work over other backends). The messaging components, which Webwork places as `tom_messaging_ui` in `tom_modules`, are not built.
  (<- S1 § 2.1, § 12; S29: C21, Q-8 (a))~~}
- **E-11** Nothing uses the tac service: the extension holds no reference to
  {~~it, and claims are not taken anywhere. (S1 § 2.1)~>it, and claims are not taken anywhere. (<- S1 § 2.1; S17)~~}
- **E-12** tac has no tac server, no GitHub backend, no users, teams, user
  messages or documents; they exist as specification text or decisions only.
  {~~(S5; S1 § 2.2, § 7)~>(<- S5; S1 § 2.2, § 7)~~}
- **E-13** No supervision application exists. {~~(S8, section `input`: the idea
  only)~>(<- S8 section `input`: the idea only)~~}
- **E-14** No quest is a repository of its own, and there is no personal
  repository. The register of quests `_ai/quests.yaml` does not exist, and
  nothing of format version 11, of the three quest types or of the quest
  operations is built: every todo of the migration is not started. This
  fleet keeps no list of a workspace's quests
  {~~(`_ai/workspaces/<workspace>.yaml`). (S2 § 3.7; S22 § 5, § 7; S27)~>(`_ai/workspaces/<workspace>.yaml`). (<- S2 § 3.7; S22 § 5, § 7; S27)~~}
- {++**E-23** There is no new VS Code extension: the copy of the old extension in `tom_ai/ai_build` has not been taken, and when it is taken is an open question (PQ-61). (-> D-73)++}

### <!--[LAND-WAIT]--> 6.3 Who waits for this

| Id | Quest | Waits for |
| --- | --- | --- |
| **E-15** | `webwork` | Team messaging and the review exchange over tac; the AI tab of its bottom panel over a runtime without a quest, with the Dart runtime client SDK and {~~the Flutter components. It works on what needs neither until the runtime is built. Its wave 1b2 carries the AI tab and messaging together, starts after its wave-1b1 release and assumes the runtime finished; no date is set.~>the Flutter components. Webwork is on hold: no Webwork todo runs until tom_forge's last restructuring step and this quest's runtime specification are done. Its wave 1b1 needs neither the runtime nor tac; its wave 1b2 carries the AI run tabs, team messaging and the review exchange through tac, starts after its wave-1b1 release and assumes the runtime complete; no date is set. Its review folder and the channels besides tac are decided, and its messaging components are to be `tom_messaging_ui` in `tom_modules`.~~} Its specifications D13 (amended) and D40 are written against the runtime protocol specification and `tac/2.0`, so it needs those two documents before the code. It waits for two messages: which todos cover WR-1 … WR-7, and that the runtime is complete. Its builds for the web, the phone and the tablet wait for the web runtime service {~~(`SCO > SCO-LATER`, L-8). (S3; S1 § 7.10; WQ-4; S25)~>(`SCO > SCO-LATER`, L-8). (<- S3; S1 § 7.10; S25: 03a_woneb1, webwork_wave1_plan.md; S29: FQ-9, FQ-11, C21) (-> WQ-4)~~} |
| **E-16** | `tom_forge` | Its quest application: the runtime process and its protocol, the Dart runtime client SDK, the host interface and host tools, two hosts on one quest, the Flutter components, the view of the coordination. The second part of its quest workbench specification is written from this specification. For repository quests it needs their operations as commands of the runtime (an open question: PQ-55). {~~(S14; S1 § 2.3, § 3.3; S26)~>(<- S14; S1 § 2.3, § 3.3; S26)~~} |
| **E-17** | `al_the_bear` | Running the tac server on its always-on machine, which needs the tac server; the coordination repository for the GitHub backend; its parallel-work rules becoming enforced. The coordination repository does not exist yet; its todo waits for the fleet's cutover to independent clones. The fleet's skills recognise only VS Code processes when they quiet the work before a merge, and no todo exists yet for asking tac or a runtime process. In the other direction the runtime waits for the fleet: the format of the `_ai` folder it is built on (S22) is decided and not built. {~~(S1 § 2.2, § 3.4; S16; S22; S27 (`14_loose_wslayout-4`, `14_loose_wslayout-6`, `12a_wslayout-2`))~>(<- S1 § 2.2, § 3.4; S16; S22; S27: 14_loose_wslayout-4, 14_loose_wslayout-6, 12a_wslayout-2)~~} |
| **E-18** | `tom_specs` | Review copies that travel without the user; its tools and processes running in every host. {~~(S11; S1 § 3.5)~>(<- S11; S1 § 3.5)~~} |
| **E-22** | `vscode_extension` | {~~The split: its engine becomes the runtime and the extension a host. Messaging, which the extension gets once the runtime is built. Until the split its engine keeps changing, and the migration to format version 11 is done there. (PQ-30; S22 § 7; S23)~>Keeps the old extension, which is left as it is once the copy for the new extension is taken; until then its engine keeps changing, and the migration to format version 11 is done there. When the copy is taken is an open question (PQ-61), and so is which quest owns the new extension after the swap (PQ-60). Messaging comes to VS Code with the new extension, in views of its own. (-> D-73, PQ-30) (<- S22 § 7; S23; S31)~~} |

## <!--[RT]--> 7 The runtime (tar)

The runtime is the engine as a program of its own: one TypeScript package,
`tom_ai/ai_build/tom_ai_runtime`, with no dependency on VS Code. A host starts
it, attaches to it and shows what it does. {~~(S1 § 4, § 5; FO-1)~>(<- S1 § 4, § 5) (-> FO-1)~~}

### <!--[RT-HOLDS]--> 7.1 What the runtime holds

- **CR.1** The runtime is the one implementation of the `_ai` formats and of
  the engines that work on them. Every host uses it, so a quest behaves the
  same in each. {~~(S1 § 5.1; S4, note a)~>(<- S1 § 5.1; S4: note a)~~}
- {++**CR.112** While the old and the new VS Code extension are both in use (D-73), the old extension keeps its own engine and is not a host of the runtime; on one machine its engine and the runtime then work on one `_ai` folder. Whether both may work on the same quest at the same time is open (PQ-36), and so is the format version both use (PQ-40). (-> D-73)++}

> **❓ PQ-34 (2026-11-25T19:40+01:00) — who writes and commits `_ai` files besides the runtime:** May programs other than the runtime write the `_ai` files (todo files, the decisions journal, the live trail), and who commits and pushes what the runtime writes?
>
> **Context:** `RT > RT-HOLDS`, CR.1: "The runtime is the one implementation of the `_ai` formats and of the engines that work on them. Every host uses it, so a quest behaves the same in each." The **`_ai` formats** are the file formats of the shared state folder `_ai`: the todo files (`*.todo.yaml`), the process state, queue entries, trails, memory, the journals. **One implementation** means: only the runtime's code reads and writes them. A **host** is a program that starts a runtime and shows what it does (the VS Code extension, Webforge, Webwork). Three groups of other writers exist or are planned:
>
> 1. **Dart code.** The package `tom_todo_model` writes todo files; its consumers move to version 6.0.0 (vscode_extension todo `vscimpb180`, planned). Tom Forge's code writes the decisions journal of a quest, and the package `tom_llm` writes the live trail of a session. Tom Forge plans to keep this for its quest workbench (tom_forge todo `qavs_wwworkbench-6`) and asks this project for "the runtime's own conformance fixtures" (the files the runtime writes for a given operation, so that a Dart writer can be tested against them) and for the rule a writer outside the runtime must follow so that it cannot lose a runtime's write (re-read before writing; respect the claim a walk puts on a todo). Webwork's todo area writes todo files through `tom_todo_model` today.
> 2. **The old extension's own engine.** The product owner's decision D-73 (this round): the VS Code extension is copied into `tom_ai/ai_build` as a new extension that works with the runtime; the old one is left alone until the new one replaces it, and both may be maintained for a while. During that parallel period the old extension's engine writes every `_ai` format as today, on the same `_ai` folder as the runtime (`RT > RT-HOLDS`, CR.112).
> 3. **Commits.** Nothing in the Project Idea says who commits and pushes what the runtime writes. Today an agent commits its own paths in the `_ai` state, and the fleet's snapshot skills commit everything else when the user starts them; for a quest in a repository of its own (a repository quest) the standard for the `_ai` format (S22) has pull, push and status as steps the user starts.
>
> **Why I ask:** If other programs may write, CR.1 is wrong as written, and the product owes them fixtures, a write rule and a compatibility promise for every format change (an older Dart writer on files of a newer format). If they may not, Tom Forge, Webwork and every Dart application must reach todos and journals through a runtime, also where they have none today. The old extension's engine is a writer in any case for as long as both extensions are in use; the question is whether the Project Idea states a rule it and the runtime both follow, and whether the runtime is tested against files the old engine wrote. Without a statement on commits, the Solution Blueprint cannot say whether the runtime needs git commands for the `_ai` state at all.
>
> - (a) Only the runtime writes. CR.1 stands. Every program reaches the `_ai` files through a runtime; `tom_todo_model` stays as the model and reader, and its writing of quest todo files is retired once a runtime is available to its application. The old extension's engine is the one exception, for the parallel period only. No fixtures for other writers.
> - **(b)** The runtime is the reference, and named other writers are allowed under a rule. CR.1 would read "The runtime is the reference implementation of the `_ai` formats …; `tom_todo_model` may write todo files, and the old extension's engine writes every format during the parallel period of D-73, under the write rule of `NFR`". A new item in `NFR` states the write rule (re-read and compare before writing, write atomically, respect a todo that is claimed) and that the runtime publishes fixtures per operation, which such a writer is tested against; the runtime is in turn tested against files the old extension wrote. The decisions journal and the live trail are written by the runtime only (and by the old engine during the parallel period).
> - (c) As (b), for all three formats Tom Forge names: todo files, the decisions journal and the live trail.
>
> For the commits, in each case: the runtime commits nothing by itself. An agent commits the paths its todo changed, as today; pull and push of the `_ai` state and of a quest's repository are steps the user starts (`SCO > SCO-OUT`, O-6).
>
> *Recommendation:* (b) — todo files are written by applications that have no runtime at hand (Webwork's todo area today), `tom_todo_model` already shares the schema, and the old engine must follow the same rule anyway while both extensions are in use; the journal and the trail are written only while an agent works, which is always in a runtime.
>
> *Assumption until answered:* CR.1 keeps its text; CR.112 names the old engine as a writer during the parallel period; no item speaks of fixtures or of a rule for other writers, and none says that the runtime commits or pushes.
>
> **Answer:**

- **CR.2** It reads and writes the stores of a quest and a workspace: quests,
  todos (with groups, due dates, follow-ups and blockers in other quests),
  memory, sessions, trails, chat variables, {~~roles and role types, templates
  and profiles~>roles and role types, templates of every category (CS.3)
  and profiles~~}, the quest's short description, saved prompts and notes, {~~the journal of asks and answers and the aspect guidelines.~>the journal of asks and answers, the aspect guidelines and the workspace's own todo file `workspace.todo.yaml`.~~} CR.47 to CR.56 and CR.61 say what each holds. {~~(S1 § 5.1, § 3.1)~>(<- S1 § 5.1, § 3.1; S17 user guide § 2, § 3; S17 llm_tools § 4.11, § 4.16, § 4.17; S23: gsel7)~~}
- **CR.47** Every file of a quest belongs to one of four classes, and the class decides whether it travels between machines: **shared** files are tracked and merged between machines (the quest's documents, its todos, the process state, the shared configuration, curated memory, notes, saved prompts); **per-host** files are tracked, one file per host, written only by that host and never merged; **derived** files are built when needed and not tracked; **machine-local** files are not tracked. Every store of CR.2 names its class. {~~(S22 § 2.2, § 3.2)~>(<- S22 § 2.2, § 3.2; S17 user guide § 2, *State per quest*; S23: 00_aifmt-1)~~}
- **CR.48** A todo carries, besides its id, description, status and resources: its blockers, also in other quests, and release conditions; a mark that only the user can do it (a walk passes such a todo, and it is shown among what is directed at the user); the block of its open decisions, with the status "decision needed" until they are answered; what happens when it is done, and who filed it (written from the caller's context, never by the agent); the answer of the execution that completed it. The views of what waits for a person are built from these. {~~(S23: ww_a_collab-2, ww_a_collab-5, vscimpb121; S17, the user guide § Your own todos, § Decisions)~>(<- S23: ww_a_collab-2, ww_a_collab-5, vscimpb121; S17 user guide *Your own todos*, *Decisions*, *After done and Filed by*; S17 llm_tools § 4.11)~~}
- {++**CR.113** A completed todo is archived into a sibling file of its todo file, and a todo that was not completed is deleted into another sibling file; both stay recoverable and can be restored, and the two sibling files are terminal. Archiving copies the todo's decisions into the decisions journal of the quest (CR.55). (<- S17 user guide *Quest TODO Panel*, *Moving todos*; S23: tra1 … tra3)++}
- {++**CR.114** Todos move between todo files, groups, quests and the workspace's own todo file; a todo moved into another group is renumbered into it, and a finalizer stays the last of its group. (<- S17 user guide *Moving todos*; S17 llm_tools § 4.11)++}
- {++**CR.115** A todo id is made from a date code that a tool generates and is checked against the todo schema's id pattern; an id stem already in use is warned about. (<- S17 llm_tools § 4.11a)++}
- {++**CR.116** The dependencies of a set of todos (those shown, those of the quests in use, or every quest) can be repaired in one pass: done and vanished blockers are removed, todos are released, the derived `blocking` is set right, and the counts are reported. (<- S17 user guide *Todos that block others*)++}
- {++**CR.117** The answer of the walk that completed a todo is kept with it. An answer reports response values (`TODO=<ref>` and the like), which the runtime reads from the trail, and the newest answer in the quest's trails that reported a todo can be read. The old extension's Copilot answer files are not carried (O-4). (<- S17 user guide *Todo iteration*, *Todo stack*)++}
- {++**CR.118** Planned: a query returns the dependency closure of a set of todos across quests, together with the queued items of every runtime that work on them. (<- S23: todoanalyzer1 … todoanalyzer4, planned)++}
- **CR.49** There are two kinds of todo group: all todos of an id prefix, and a group todo that names its members, also of other quests. A group todo is completed by itself when all its members are done; what a todo is a part of is derived, never stored. {~~(S23: vscimpb125, vscimpb126)~>(<- S23: vscimpb125, vscimpb126; S17 user guide *Prefix groups*)~~}
- **CR.50** A todo's dates: a due date with a derived overdue state and one reminder; a reminder schedule that rings while the todo is open; one-shot reminders; and repetition (the todo comes back after it is done). They are checked on the runtime's one clock (CR.84) and ring through the notification for the user. They ring only while a host has the runtime running (CR.44); {~~a missed moment rings once at the next start. (S23: vscimpb152aa, vscimpb152ab, vscimpb34)~>a missed moment rings once at the next start. A reminder is recorded before it is sent, so it rings once across the hosts and machines of a person. Planned: a repeated todo's next occurrence takes its due date and reminders with it, and a reminder can be snoozed. (<- S23: vscimpb152aa, vscimpb152ab, vscimpb34; wwremind2, wwremind3, planned)~~}
- **CR.51** A todo id never disappears: a rename leaves a cancelled stub under the old id. {~~(S27; built in the extension's rename tools, E-1)~>(<- S27; S17 user guide *Moving todos*) (-> E-1)~~}
- **CR.52** What the runtime writes passes the commit guards of the repository it writes into, in the `_ai` state and in a repository quest alike. {~~(S22 § 3.6, § 2.4 QM-7)~>(<- S22 § 3.6, § 2.4 QM-7)~~}
- **CR.53** Planned: memory is the quest's. Curated facts are shared by the quest's members; candidates are kept per host, each naming its session, and the user promotes them with a prompt. {~~There is no scope shared across quests and no level per session. (S22 § 2.2 CQ-8, CQ-18, § 2.3 AC-17; S23: 01_aifmt-3, 00_aifmt-3)~>There is no scope shared across quests and no level per session; the old extension's shared memory (`_ai/memory/shared/`, shared across quests) is removed already and not carried. (<- S22 § 2.2 CQ-8, CQ-18, § 2.3 AC-17; S23: 00_aifmt-3; 01_aifmt-3, planned)~~}
- **CR.54** Planned: saved prompts are a store of the quest (shared); quest notes are several files of the quest, the user's, which agents read and never write; a workspace has notes of its own in the `_ai` state. A notes file per machine is the VS Code host's own (`CLI > CLI-SCREENS`, SC-17). {~~(S22 § 2.3 AC-4, AC-5, AC-11, AC-12, § 3.2; S23: 01_aifmt-3)~>(<- S22 § 2.3 AC-4, AC-5, AC-11, AC-12, § 3.2; S17 user guide § 3, *Notes views*; S23: 00_aifmt-3; 01_aifmt-3, planned)~~}
- **CR.55** Planned: the journal of asks and answers is a store of the runtime, per host and quest, in time order: every ask put to the user with its answer and the run it came from, every answer handed to the user without an ask, and every message written to a waiting turn (CR.72). The views of asks and answers read every host's journal, and {~~the decisions document of a quest is a rendering of the decisions of its archived todos.~>the decisions document of a quest is a rendering of the decisions of its archived todos, together with every move of a process that is not a plain step (jumps, resets, follow-up switches, aborted levels, left-out steps), as the decisions journal records them today.~~} Where the per-host files lie is open (PQ-53). The Solution Blueprint settles whether an ask answered on another machine through tac is recorded in the asking host's journal. {~~(S22 § 2.2 CQ-2, CQ-15, QJ-1; S23: 01_aifmt-4)~>(<- S22 § 2.2 CQ-2, CQ-15, QJ-1; S17 user guide § 2, *Processes*; S23: vscimpb81, vscimpb173; 01_aifmt-4, planned)~~}
- **CR.56** A quest has a short description as one of its files: a title, two to four sentences and a line on its state. It is required when a quest is set up and is served with the list of quests. {~~(S23: vscimpb145, questsetup1)~>(<- S23: vscimpb145, questsetup1)~~}
- **CR.3** It carries the format-version stamp of the `_ai` files and the
  migration from one format to the next. The runtime is built on format version 11 of the `_ai` files, with the layout of the quest folder that S22 § 3 defines; that version is decided and not built (`LAND > LAND-BUILT`, E-1). {~~(S1 § 5.1; `RT > RT-VERSIONS`; S22 § 3.2, § 3.6)~>(<- S1 § 5.1; S22 § 3.2, § 3.6; S17 user guide § 2 *Upgrading the workspace*; S23: vscimpb142, vscimpb142a … vscimpb142d; 01_aifmt-5, planned) (-> CP.28)~~}
- **CR.4** It keeps a registry of cleanup tasks, so what a feature leaves
  behind (temporary files, stale records) is removed by one mechanism.
  Each task finds what is left and applies its removal, and an agent runs the tasks through a tool. {~~Planned: the registry is decided and not built (S23: aaa_cleanup1, aaa_cleanup2).
  (S1 § 5.1, § 3.1)~>Planned: the registry is decided and not built. (<- S1 § 5.1, § 3.1; S23: aaa_cleanup1, aaa_cleanup2, planned)~~}
- **CR.57** The runtime's own temporary files for a workspace, and its tools', lie in the workspace root's ignored scratch folder `ztmp/`, never in the system's temporary folder, and carry the quest, the date and the todo in their name, so that the registry of CR.4 removes them when the todo is done. {~~(S27, `workspace_agents.md` § Scratch folders)~>(<- S27: `workspace_agents.md` § Scratch folders)~~}
- **CR.5** It carries what the engine has today beyond the stores: team review
  rounds on documents, the expression language used in prompts and process
  definitions, {~~prompt assembly from role, quest, memory and guidelines,~>prompt assembly from role, quest, memory, guidelines and the process context (the process's values also as chat variables),~~} and
  the features of Claude Code (skills, subagent definitions, slash commands,
  instruction files, hooks, plan mode) on every transport.{++ A team review round is kept in the layout of a review (`TAC > TAC-REVIEW`, CV.17).++} {~~(S2 § 3.1;
  S1 § 3.1)~>(<- S2 § 3.1; S1 § 3.1; S17 placeholder_engine.md, anthropic_handler § 4, llm_tools § 6, user guide *In the system prompt*; S23: cc_parity_a_start-26, ccparity_f_teamreview-1 … ccparity_f_teamreview-3, vscimpb107, vscimpb115, ccparity_d_claudecode-1 … ccparity_d_claudecode-6, gsel18)~~}
- {++**CR.119** The runtime carries the assists, each a prompt of the template category *assist prompts* chosen per use (CS.3): Grill me, Explain in detail and proposed answers on a question of a document under review; Explain a decision and Grill me at a process decision; Finish review round; the gate decision; out of budget (CR.92); the reminder about background work (CR.88). Every host sends them into a run of its own; an assist at a decision runs in a temporary session based on the session of the process. (<- S17 user guide *Assist prompts*; S23: ccparity_i_assist-3, ccparity_i_assist-7; S25: 13_woneb5)++}
- {++**CR.120** The expression language of prompts, templates and process definitions is one language, evaluated the same way by the runtime and by Dart applications. Tom Forge plans an expression system common to JavaScript and Dart to replace `${{ … }}`; the runtime takes it over when it exists, and the expressions already written keep working. (<- S1 § 3.3; S2 § 3.1; S26: qavs_wwworkbench-1, planned)++}

> **❓ PQ-35 (2026-11-25T20:48+01:00) — the quest refresh, the stored prompt, the host's level of aspect choices, night mode and `prerequisites.yaml`: the runtime's or the host's, and once per quest and per person:** Which of five built features of the VS Code extension become features of the runtime, and how do they behave when a quest is worked on from several hosts, machines and people?
>
> **Context:** The product owner's decision D-74 (this round): the first version has the features of the VS Code extension, built and planned, "carried across machines, between the members of a team and over the internet". All five features below are built in the extension and are therefore in the first version; what is not decided is where each acts (in the runtime, so every host has it, or in a host) and what carrying it across machines needs. `RT > RT-HOLDS`, CR.5: "It carries what the engine has today beyond the stores: team review rounds on documents, the expression language used in prompts and process definitions, prompt assembly from role, quest, memory, guidelines and the process context …, and the features of Claude Code … on every transport." The **host** is the program that starts a runtime and shows what it does; a **run** is a queue in a quest that executes todos and prompts (CR.8).
>
> 1. **The quest refresh.** After a set number of counted prompts the extension's queue sends a refresh prompt by itself that brings the quest's progress, overview and short description up to date and files a refresh-notes and decisions todo; items that a process step queues carry a mark (`processItem`) so that they neither count nor trigger it; the user can also run it by hand (vscode_extension todos `vscimpb97`, `vscimpb145`, done). Today each window counts for itself.
> 2. **A prompt stored for after a restart.** A prompt stored per quest is queued at the front of the window's run when the window starts and sent also while the run is paused (vscode_extension todo `vscimpb109`, done). It is how an agent continues after it asked the user to reload the window.
> 3. **The host's level of the aspect choices.** `RT > RT-HOLDS`, CR.61 now reads: the choices in effect "are resolved over levels, the later winning: the aspect's default, the workspace …, the quest's default, the host's choice for this runtime, the run, the role type, the role, the item, the todo … The level 'the host's choice for this runtime' stands where the old extension has the level of a window". In the extension the level is one VS Code window on one machine (vscode_extension `gsel19`, `gsel20`).
> 4. **Night mode.** `RT > RT-HOLDS`, CR.121: "Night mode is an aspect of the aspect guidelines (CR.61) that is sent while a variable of the runtime is on. While it is on, the agent asks nobody …". In the extension the variable `night-mode` is window-wide and is switched "in this window or every window of the machine" (built 2026-11-25).
> 5. **The file `prerequisites.yaml`.** Per project it lists the secrets the project needs (never a value) and other prerequisites such as installed software; a view of the extension checks what can be checked in VS Code's environment and a login shell (vscode_extension todo `vscimpb152`, done). The screen inventory treats the view as the host's own (`CLI > CLI-SCREENS`, SC-25).
>
> **Why I ask:** A feature of the runtime needs items in `RT`, commands in the protocol and a place in the client SDKs; a host's own feature needs none and exists only in the hosts that build it. Carried across machines and people, three of them change meaning: a quest refresh counted per host runs twice when two hosts or two machines work on the quest; a choice "of the window" has no owner when a person has a runtime in VS Code, one in Webforge and one on another machine; and a project's prerequisites must be checked on each member's machine, not only where the file was written.
>
> - (a) All five are the runtime's, each per runtime: every runtime counts and refreshes for itself, the stored prompt is a runtime command "queue this at the next start", the host's level and night mode are set per runtime, and `prerequisites.yaml` is a format the runtime reads and checks through a tool on its machine.
> - **(b)** All five are the runtime's, with an owner for what is shared: the quest refresh is counted by the runtime that holds the quest's run `default` on a machine (the rule that PQ-36 (b), on two engines on one quest, proposes: one runtime holds a run at a time), and process items do not count; two machines may each refresh between two reconciles, and their results meet in the shared files, which merge. The stored prompt is a runtime command "queue this at the next start". The host's level is "the host's choice for this runtime", passed by the host. Night mode is a variable of the person that a host switches for one runtime or for all of the person's runtimes on the machine; across machines it is switched on each. `prerequisites.yaml` is a format the runtime reads; a tool checks it on the runtime's machine, so each member's runtime checks its own machine, and the view stays the host's.
> - (c) Split by what they act on: the quest refresh and the stored prompt are the runtime's; the host's level is passed by the host; night mode and `prerequisites.yaml` stay the VS Code host's own until a second host needs them (Webwork and Webforge then have neither).
>
> *Recommendation:* (b) — D-74 puts all five into the first version for every host; one counting runtime per machine matches the rule of PQ-36 (b) that one runtime holds a run; per-machine night mode and prerequisite checks need nothing that carries a switch across machines.
>
> *Assumption until answered:* CR.61 writes the level "the host's choice for this runtime" and CR.121 writes night mode with "who switches it on, and for which of a person's runtimes, is open (PQ-35)". The quest refresh, the stored prompt and `prerequisites.yaml` are named only in this question.
>
> **Answer:**

- **CR.58** Plan mode is per run: while it is on for a run, every writing tool is refused on every transport, and reading and asking work. Only the user ends it; a prompt that ends while its plan is proposed leaves plan mode on. {~~(S23: vscimpb81)~>(<- S23: vscimpb81, ccparity_c_transports-3)~~}
- **CR.59** Instruction files are found from the workspace folder: an agent transport is started with the workspace folder as its working directory, and for a model transport the runtime collects the instruction files by the same rules (the root's, then the workspace folder's, imports followed). {~~(S12; S27, `workspace_layout.md` § 6)~>(<- S12; S27: `workspace_layout.md` § 6; S23: ccparity_d_claudecode-4, gsel18)~~}
- **CR.61** {~~Prompt assembly takes, for each section of the aspect guidelines, the text of one option from a store that every quest and machine shares, and places it in the system prompt or before the user prompt, on every transport. Which option is taken is resolved over levels, the last winning: the section's default, the quest's default, the run, the role type, the role, the item, the todo. The store and the resolver are built; choosing per level is planned. Whether a level for the host stands between quest and run is open (PQ-35). (S24, A-1 … A-5, L-1 … L-8; S23: gsel2, gsel4 … gsel10)~>Prompt assembly takes, for each aspect of the aspect guidelines, the texts of the choices in effect and places them in the system prompt or before the user prompt, on every transport. The store is shared by every quest and machine; a choice is its own text or a guideline file looked up over the root and the workspace folders. The choices in effect are resolved over levels, the later winning: the aspect's default, the workspace (its `workspace_aspects` files, which import guideline files with `@<path>` lines), the quest's default, the host's choice for this runtime, the run, the role type, the role, the item, the todo; a level replaces the choices below it, adds to them or removes some of them. A choice or a whole aspect can carry a condition over chat variables and facts of the prompt (its transport, kind and role), under which it applies or is removed. Renaming an aspect carries the stored choices over. The level "the host's choice for this runtime" stands where the old extension has the level of a window; whose choice it is when a person has several runtimes is open (PQ-35). (<- S24; S17 user guide; S23: gsel2, gsel4 … gsel10, gsel16, gsel17, gsel19, gsel20, gsel27)~~}
- {++**CR.121** Night mode is an aspect of the aspect guidelines (CR.61) that is sent while a variable of the runtime is on. While it is on, the agent asks nobody: it decides by itself, records each decision as a question block with its answer, and stops only before what cannot be undone. Who switches it on, and for which of a person's runtimes, is open (PQ-35). (<- S23: progress 2026-11-24, 2026-11-25)++}
- **CR.6** One runtime serves one quest. An application's own AI
  that belongs to no quest runs in a runtime without a quest. Inside a runtime, runs and sessions work in parallel. {~~(S1 § 3.2; S3, WR-7;
  S2 § 3.1)~>(<- S1 § 3.2; S3: WR-7; S2 § 3.1; S17 user guide § 2)~~}
- {++**CR.122** A host may create runs of its own in a runtime without a quest, one per part of its application; they follow no process, and each starts in its default session (CR.62). (<- S3: WR-7; S25: 12a_woneb1)++}

> **❓ PQ-36 (2026-11-25T20:48+01:00) — two engines on one quest: two hosts, the old extension beside the runtime, timed requests, and where queue entries live:** When two engines work on the same quest on one machine (two hosts with their runtimes, or the old extension's engine and a runtime), which of them executes a run, which sends a timed request, and where do the queue entries live?
>
> **Context:** A **host** is the program that starts a runtime and shows what it does (a VS Code window, Webforge); a **runtime** is one running instance of the engine; a **runtime client** is a program connected to a runtime; a **run** is a queue in a quest that executes todos and prompts; a **timed request** is a prompt the queue sends on a schedule (`RT > RT-QUEUE`, CR.84). The Project Idea says:
>
> - `NFR`, N-10: "Two hosts can work on the same quest at the same time." `NFR > NFR-TOPO`, T2: "Two hosts may work on one quest."
> - `RT > RT-HOLDS`, CR.6: "One runtime serves one quest." `RT > RT-INSTALL`, CR.44: "A runtime is started by its host and ends with it." So each host has a runtime of its own.
> - `RT > RT-HOLDS`, CR.112: "While the old and the new VS Code extension are both in use (D-73), the old extension keeps its own engine and is not a host of the runtime; on one machine its engine and the runtime then work on one `_ai` folder."
> - `TAC > TAC-COORD`, CA.6: "One quest may have several runtimes." CA.19: a command sent to a quest is taken by "the first runtime of that quest that acknowledges it".
> - `RT > RT-PROTO`, CP.5: the numbered events serve "a runtime client that reconnects, a second one on the same run, and one that attaches late". `RT > RT-HOST`, CP.15: whether a host may answer a host tool by forwarding it to another host is open.
> - `RT > RT-MACHINE`, CR.106: "Nothing of the machine-wide state, of the local tac service's store or of the inbox lies in the `_ai` folder: its top level is a closed list that a commit guard keeps."
>
> What the sources say: Tom Forge's specification of the quest workbench (S14 § 3) allows "at most one quest application per quest", because two applications would run two runtimes over one `_ai` folder. This quest's todo `ww_d_workbench-11` (S30) plans the extension and a runtime server on the same quest: each loads only its own queue entries, a timed request fires once, todo claims work both ways. In the old extension today, two windows on one quest are two engines on the same files; a queue item is taken over by another window only when the first window's heartbeat is gone; queue entries are one file per entry in `_ai/queue/`, named with the host, the workspace and the quest, and synchronised between windows by watchers (vscode_extension user guide *Queue Storage*). This quest's inventory for the new extension (V2-17) recommends that the old extension keep its own engine and that the two not run on the same quest at the same time during development, the new one working on sandbox quests.
>
> **Why I ask:** Neither reading is stated. With two engines, nothing says which executes a run's queue, sends a timed request (once, not once per engine), takes a command addressed to the quest, or owns a session. With one runtime and two runtime clients, CR.44 is wrong. And the queue entries lie in `_ai/queue/` today, which CR.106's closed list of `_ai` does not name; the runtime must keep them somewhere, and during the parallel period the old engine still reads them from `_ai/queue/`. N-10, T2, CR.44, CA.6, CA.19, CP.5 and CR.106 all read differently by the answer.
>
> - (a) One runtime per quest and machine, several runtime clients. The first host starts the runtime; a second host on the same quest attaches as a second runtime client; the runtime ends when its last host has gone (CR.44 changes). Queue entries are machine-wide state outside `_ai`. The old extension and the runtime never work on the same quest at the same time during the parallel period.
> - **(b)** Two runtimes, and every run is executed by exactly one of them at a time. Each host starts its runtime (CR.44 stands). A run is executed by the runtime that holds it: the first to take it, recorded in the machine-wide state; the other shows the run, can queue into it and answer its asks, and its commands are passed to the holder; when the holder ends, another takes the run over. Timed requests and commands addressed to the quest are taken by the runtime that holds the run `default`, so a timed request fires once per machine. Queue entries are machine-wide state outside `_ai` (CR.106), kept by the runtime that holds the run. The same rule serves two users on one repository quest, with the run held through tac. A host may answer a host tool by forwarding it to another host of the same user on the same machine. During the parallel period of D-73 the old extension keeps `_ai/queue/`; the old extension and a runtime do not work on the same quest at the same time until `ww_d_workbench-11`'s rules are built, and the new extension is tested on sandbox quests meanwhile.
> - (c) Two runtimes that each execute only their own runs: a run belongs to the host that created it, the other host does not see it; each runtime keeps its own queue entries and fires its own timed requests. N-10 then means only "both can work on the quest's todos and documents".
> - (d) At most one engine per quest on a machine: a second host, or the old extension beside a runtime, is refused on that quest with the name of the first. N-10 and T2 lose their sentences; queue entries are machine-wide state outside `_ai`.
>
> *Recommendation:* (b) — it keeps "a runtime is started by its host and ends with it", it is what two VS Code windows nearly do today, one rule covers two hosts of one user and two users on one quest, and it keeps the old extension and the runtime apart until the rule is built.
>
> *Assumption until answered:* N-10, T2, CR.44, CA.6, CA.19, CP.5 and CR.106 keep their text; CR.112 says the old engine and the runtime work on one `_ai` folder, and whether on the same quest is open; no item says where queue entries live.
>
> **Answer:**

- **CR.60** One host can have a runtime without a quest and runtimes that serve quests at the same time; a run that is bound to a quest's folder runs in that quest's runtime. Any host can start a quest's runtime, not only a workbench. {~~(S25: 12a_woneb1; `NFR > NFR-TOPO`, T2; CR.42)~>(<- S25: 12a_woneb1) (-> T2, CR.42)~~}
- **CR.7** A runtime belongs to exactly one person. This is stated for a host on the user's machine; whose runtime runs behind the web runtime service is open (PQ-38).
  {~~(S1 § 7.3, DQ-1)~>(<- S1 § 7.3) (-> DQ-1)~~}

### <!--[RT-RUNS]--> 7.2 Processes and runs

- **CR.8** A **run** is a queue in a quest that executes todos and prompts, one line of work: a process position, its
  variables, its own queue settings (CR.70), its sessions (named
  `<session>@<run>`) and a subject that says what the run works on. A quest
  has several runs, and they work in parallel: each run sends its items beside the others (CR.67). {~~(S1 § 5.2, § 3.1)~>(<- S1 § 5.2, § 3.1; S17 user guide *Runs*, *State per quest*, § 3; S23: vscimpb118, vscimpb122)~~}
- **CR.62** A run is created with its default session `default@<run>`, based on the default run's session `default@default`. An item that names no session is executed in its run's default session. {~~(S23: qrun1, vscimpb151; PQ-25)~>(<- S23: qrun1, vscimpb151; S17 user guide *Named sessions*) (-> PQ-25)~~}
- **CR.63** The subject of a run is a run parameter that its process declares. The process's first step sets it; it is shown wherever the run is shown, and in the process context of a prompt. Planned: it is preset with the run's name. {~~(S23: vscimpb118; vscimpb156, planned)~>(<- S23: vscimpb118; vscimpb156, planned)~~}
- **CR.9** The run `default` follows no process. Every process runs in a run
  of its own. A run can be reset as a whole, or only put back to the start of
  its process. A process declares the parameters a run of it takes.
  {~~(S1 § 5.2, § 3.1)~>(<- S1 § 5.2, § 3.1; S17 user guide *Runs*; S23: vscimpb122, vscimpb91)~~}
- **CR.10** A process is defined by phases, steps and sub-steps, the role
  that does each, and a gate that ends each phase. The engine carries these
  shapes {~~(S1 § 3.1, § 3.5):~>(<- S1 § 3.1, § 3.5; S17 user guide *Processes*; S23: vscimpb95, vscimpb96, vscimpb36, vscimpb47, ccparity_e_process-5 … ccparity_e_process-8, vscimpb64, vscimpb85, vscimpb89, ccparity_i_assist-5):~~}
  - nested processes with inputs and outputs, and branches that hand nothing
    back;
  - conditional phases and steps;
  - decision steps, decided by a condition, by the user, or by the agent's judgement with a recorded reason, and moves that are not linear (back to a step, back to
    the start of a phase);
  - follow-up processes;
  - gates whose result is shown with the buttons of the decision that
    follows; {~~the move a button makes acts on the run of the prompt that asked;~>the move a button makes acts on the run of the prompt that asked, and a move offered by a button (finishing a review round, a decision) is accepted at a sub-step of the step it belongs to (<- S1 § 3.5);~~}
  - {~~review steps that name the documents under review;~>review steps that name the documents under review; planned: the documents taken from a chat variable that holds several paths (<- S23: vscimpb163, planned);~~}
  - steps the user does himself, which the process only asks him to confirm;
  - steps that queue walks over todo groups, with a closing item.
- **CR.11** A process definition can be written and checked through tools,
  and an agent can suggest a subprocess for the running step. A suggested subprocess is shown only after the step's items are done, and the step's move waits for the user.
  {~~(S1 § 3.1; S23: vscimpb95, ccparity_e_process-8)~>(<- S1 § 3.1; S23: vscimpb95, ccparity_e_process-8, ccparity_j_ideaprocess-1, vscimpb92)~~}
- {++**CR.123** A process step is executed by queueing its prompt and, behind it, a marker in the run's lane. The process moves when the lane reaches the marker with the step's items done; an item of the step that failed holds the marker, and the user repeats the step or moves on. (<- S17 user guide *Proceed*, *Processes*; S23: cc_parity_a_start-15)++}
- {++**CR.124** The prompt that executes a position is built from a template the workspace can edit, the Proceed template; it names the role and the guideline choices for the work the step queues. (<- S17 user guide *Process template editor*; S23: gsel8)++}
- **CR.12** A run pins the version of its process: it records the revision of
  the process definition it started on. When the definition changes, the run
  goes on as it was; at its next step boundary the user is shown what changed
  and confirms that the run takes the new definition over. Taking it over is
  the usual case, since a change to a process is normally meant to be used at
  once; a run never changes in the middle of a step. The Solution Blueprint settles what "the revision of the process definition" is. {~~(S1 § 5.2; PQ-2)~>(<- S1 § 5.2) (-> PQ-2)~~}
- **CR.13** A step declares what must hold before it starts (answered
  questions, a passed gate, documents that exist). The runtime checks this
  and refuses to start the step with the reason, instead of starting it. This is a refusal, not a wait: nothing of the step is queued, and the process stays at its position.
  The preconditions come from a fixed set: every question of a named
  document answered, a named gate passed, named documents exist, a named
  group of todos done. The user can override a refusal, and the override is
  recorded. {~~(S1 § 5.2; PQ-3)~>(<- S1 § 5.2) (-> PQ-3)~~}
- **CR.14** Which processes exist is not the runtime's matter: the engine
  carries any process definition. A short process for small changes is not
  part of this product; it is proposed where the specification process is
  {~~defined. (PQ-4; `SCO > SCO-OUT`)~>defined, outside this product (`SCO > SCO-OUT`). (<- S23: ccparity_j_ideaprocess-2, ccparity_j_ideaprocess-3) (-> PQ-4)~~}

### <!--[RT-QUEUE]--> 7.3 The queue

- **CR.15** Every run has a queue. Its items are prompts, todos and groups of
  todos (the kinds: CR.64); an item has pre-prompts and follow-ups, a session it is executed in and a
  transport it is sent with. Chat is not a separate path: {~~a chat send is a
  queue item, and a session carries one item at a time. (S1 § 5.3, § 3.1;
  S3, WR-7)~>a chat send is a queue item, and a session carries one item at a time, in this host or another of the quest. Chat sends stand outside the runs' lanes: they are shown with the queue and take the session's one busy slot, and a pending item of that session waits while a chat send runs in it. A chat send into a busy session offers an update to the running prompt, sending next, sending after the current item, or a free session. (<- S1 § 5.3, § 3.1; S3: WR-7; S17 user guide § 4 *Queue Entry Fields*, *Two prompts never share a session*; S23: vscimpb132, vscimpb135) (-> D-74)~~}
- **CR.64** An item has a kind: a todo, a group, a prefix (a walk over the todos of an id prefix), an iteration (a repeated prompt), a chat send, or a prompt. {~~(S23: vscimpb127, vscimpb128, vscimpb129)~>(<- S23: vscimpb127, vscimpb128, vscimpb129)~~}

> **❓ PQ-64 (2026-11-25T19:40+01:00) — control items and wait / notify items in the queue, across machines and people:** Does the first version have queue items that the runtime carries out itself (start, pause, interrupt, resume or silence runs; wait for a todo, a run or a notification; notify; a barrier), and do they reach runs on other machines and of other people?
>
> **Context:** A **queue item** is an entry of a run's queue (`RT > RT-QUEUE`, CR.15: prompts, todos and groups of todos); a **run** is a queue in a quest that executes todos and prompts. One item the runtime carries out itself is built: the marker of a process step (`RT > RT-RUNS`, CR.123: "A process step is executed by queueing its prompt and, behind it, a marker in the run's lane. The process moves when the lane reaches the marker with the step's items done"). The VS Code extension plans more (all planned, so in the first version by the product owner's decision D-74 unless decided otherwise):
>
> 1. **Control items** (vscode_extension todo `vscimpb187`, its decisions open): start, pause, interrupt and resume runs in this or other windows, interrupt everything and silence the workspace for a reconcile, notify the user. Its open decision is whether they act on "this machine's windows only".
> 2. **Further control items** (`vscimpb188`, a decision open): wait for a todo, wait for a run, a barrier between runs, set a variable.
> 3. **Wait for notifications and Notify** (`caf_07c`, part of the extension's collaboration plan S28): a pseudo-item that waits for named notifications, kept in a notification store so that a wait finds notifications sent before it, and a Notify item that sends one.
>
> What the Project Idea has: `PAR > PAR-APPROACH`, CW.13: "a runtime can be asked to pause its queue after its current item" (for a reconcile's quiet phase); `TAC > TAC-COORD`, CA.19: a command sent to a quest is taken by the first runtime of that quest that acknowledges it; remote control of another person's runtime is possible only inside a team and where the runtime's host allows it (`TAC > TAC-PEOPLE`). Carried "across machines, between the members of a team" (D-74), a pause, a wait or a barrier names a run that may be on another machine or belong to another person.
>
> **Why I ask:** On one machine these items are a matter of the queue. Across machines they are commands through tac, and across people they are remote control, which needs the team's permission rules. What the first version promises decides whether `RT-QUEUE` gets one item or a family, whether tac carries commands to runs (not only to quests), and how a wait across machines is told that its condition holds.
>
> - (a) On one machine only: the control, wait, notify and barrier items act on the runs of the runtimes of this machine; other machines are reached only by CW.13's pause request.
> - **(b)** On one machine and across the person's own machines: a new `RT-QUEUE` item says "Besides items sent to a model, a queue holds items the runtime carries out itself when its lane reaches them: the marker of a process step, a notification sent, a wait for named notifications, for a todo or for a run, a barrier between runs, and commands to other runs (start, pause, interrupt, resume, silence)". They act on runs of the same person's runtimes on other machines through tac commands (CA.19). A notification is kept in a store, so a wait finds one sent before it. Runs of other people are reached only through asks and messages, not through control items, in the first version.
> - (c) As (b), and also on runs of other members of the team, as remote control within the permissions of `TAC > TAC-PEOPLE`.
> - (d) None in the first version beyond the process-step marker and CW.13; the plans stay the old extension's.
>
> *Recommendation:* (b) — it carries the extension's plan to the person's own machines, which is what "distributed" adds for one user, and leaves acting on another person's runs to the remote-control rules that still have open questions.
>
> *Assumption until answered:* `RT-QUEUE` names only the process-step marker (CR.123) and CW.13's pause request; no control, wait, notify or barrier item is written.
>
> **Answer:**

- **CR.65** An item bound to a todo does more than a prompt: the todo's record is appended to the prompt; the todo is set to in progress when the item is sent and put back when the send fails; and its completion is checked (CR.82). {~~(S23: vscimpb127)~>(<- S23: vscimpb127, dapieff8, dapieff9)~~}
- **CR.66** A group item walks the members of a group todo in their order, and the user or an agent can choose which of the members still to come are sent; members of another quest are not walked. One walk engine serves prefix, todo and group items. {~~(S23: vscimpb127, vscimpb125)~>(<- S23: vscimpb127 … vscimpb129, vscimpb125)~~}
- **CR.67** A run executes one item at a time, and the runs execute in parallel. A run whose next item cannot start waits, and its later items do not jump ahead. So while a run waits (`RT > RT-ASKS`, CP.21), {~~nothing else of its queue is executed. (S23: vscimpb46; PQ-24)~>nothing else of its queue is executed; a chat send in another session of the waiting run goes out, since chat sends stand outside the lanes (CR.15). (<- S23: vscimpb46, vscimpb132, vscimpb135; caf_03a, planned) (-> PQ-24, D-74)~~}
- **CR.68** A todo is queued once: an item whose todos are already staged, pending or being executed in the quest is refused, unless the caller says the repeat is meant. {~~(S23: vscimpb77, ccparity_e_process-2)~>(<- S23: vscimpb77, ccparity_e_process-2)~~}
- {++**CR.125** A chat send that gets no result within the queue's response time (60 minutes by default) is stopped. (<- S17 user guide *Chat sends*)++}
- **CR.69** The states of a queue item: staged (queued but not released; the state of a new item), pending, being executed, done, error, held on a todo's open decisions, {~~held on a blocked todo, interrupted.~>held on a blocked todo, interrupted, waiting for a rate limit or a quota until a time (shown with the time), retrying (shown as the count of tries, n of m, and the time of the next).~~} Staged is distinct from pending. An item that is being executed carries marks: waiting for the user, waiting for an event, waiting for its background work, held, needs attention, yields after this iteration. {~~(S23: vscimpb55, vscimpb37, vscimpb112; S17, the user guide § 4)~>(<- S23: vscimpb55, vscimpb37, vscimpb112, trb4, ccparity_a_directapi-2, vbs4; S17 user guide § 4 *Queue Editor*)~~}
- **CR.70** A run's queue settings are: automatic sending; automatic start; automatic pause when all its items are done (on by default); automatic continuing after a restart; the defaults of new items {~~(transport, profile, prompt template, session; planned: role and guideline choices)~>(transport, profile, prompt template, session, role and guideline choices)~~}; and the number of walk continuations (CR.82). Shared by all runs are only the models for compaction and for memory extraction. {~~(S23: vscimpb60a; gsel3, planned)~>(<- S23: vscimpb60a, gsel3, ccparity_a_directapi-4; S17 llm_configuration § 3, § 7)~~}
- **CR.71** Whatever stops sending by itself stops one run only: an error, an interrupt, a walk that needs attention or is held, out of budget, the automatic pause, a pause after this item. Switching automatic sending off never interrupts the item that is being executed. {~~(S23: vscimpb60a, vscimpb168)~>(<- S23: vscimpb60a, vscimpb168)~~}
- **CR.16** A host sends a prompt into a run's queue in one of three ways:
  at the end, next (before the waiting items), or as an update to the prompt
  that is being executed. An update that arrives after that prompt's execution has
  finished is queued next, and the answer says so. A pending item that is being edited is not sent until it is saved. {~~(S1 § 5.3, § 3.2; S3,
  WR-7)~>(<- S1 § 5.3, § 3.2; S3: WR-7; S17 user guide § 4, *Editing a pending item*, *Send to Anthropic/LLM*, *Where a todo is queued and sent*)~~}
- **CR.72** An update to the prompt being executed also reaches a turn that waits (a declared wait, the item's own background work), and the wait goes on afterwards. Where an update is taken depends on the kind of transport: an agent transport takes it as a further user message of the running query, a model transport as the next user message of its tool loop; a declared wait returns with the message and is entered again with the same end. Each message is kept with the item, together with what became of it, and recorded in the journal of asks and answers (CR.55). {~~(S23: vscimpb173)~>(<- S23: vscimpb173)~~}
- **CR.73** A repeating item holds its run until its last iteration. "Next" (CR.16) under a repeating item means between two of its iterations. A repeating item can let the next pending item go first and resumes after it, its position kept. An item can be marked to pause its run when its last stage is done. {~~(S23: vscimpb60e; S17, the user guide § 4)~>(<- S23: vscimpb60e; S17 user guide § 4)~~}
- **CR.74** The commands a user has on an item that is being executed: answer its open ask; resend the stage (the turn is cancelled and the same stage is sent again, with a note that it was interrupted); skip to the next stage or todo; stop (the item goes back to staged). Resend, skip and stop close an open ask unanswered (`RT > RT-ASKS`). Continuing an item that waits always offers these choices and never acts by itself, and a question that waits long has no time limit of its own. {~~(S23: vscimpb55, vscimpb78)~>(<- S23: vscimpb55, vscimpb78)~~}
- {++**CR.126** Besides the commands on an item that is being executed (CR.74), the user has commands on a run's queue: send an item now (a sent item again, from its first prompt); send every staged item; clear the sent items, or all; delete the items in error; retry an item in error now, or every item in error, which switches the automatic sending of their runs on again; restart the queue; stop it. (<- S17 user guide § 4 *Queue Editor*; S23: trb4, ccparity_a_directapi-2, vbs4)++}
- {++**CR.127** Any item that is not sent can be moved to another run, to another session and to another place in its lane (the end, the top, next between the iterations of a repeating item); an item that is being executed is stopped first. An item's status can be set by hand to pending, staged or sent. (<- S23: progress 2026-11-24, 2026-11-25)++}
- {++**CR.128** A run's settings can become the start values of new runs; a run's defaults can be applied to its waiting items; and an item can follow its run's defaults, which are then taken when it is sent. (<- S23: progress 2026-11-23, 2026-11-24)++}
- **CR.17** A run has an option, kept by the runtime, for how results are
  taken: *review each result*, where a prompt's changes come back as a
  preview and the run waits, as for an ask (`RT > RT-ASKS`, CP.21), until the host reports that the user applied
  or discarded them; or *work silently*. Changing the option while a result
  waits leaves that result waiting. {~~Webwork needs every run of its own AI to start in *review each result* (S25: 13_woneb2, planned);~>Webwork needs every run of its own AI to start in *review each result* (<- S25: 13_woneb2, planned);~~} which value a new run starts with is for the Solution Blueprint to settle. {~~(S1 § 5.3, § 3.2; S3, WR-7)~>(<- S1 § 5.3, § 3.2; S3: WR-7)~~}
- {++**CR.129** The changes an agent made to a document can be reviewed in a document view of the host, each change accepted or rejected on its own. (<- S23: vscimpa11)++}
- **CR.18** A run can start a session over: the next prompt starts
  without the earlier context; the session keeps its name and its definition, and what was said before stays readable
  in the trail. {~~(S1 § 3.2; S3, WR-7; PQ-25)~>(<- S1 § 3.2; S3: WR-7; S23: qri1) (-> PQ-25)~~}
- **CR.75** A session has a base, a lifetime and optionally a profile. The lifetimes are: *continue* (one conversation; with a base, its first prompt starts from the base's conversation), *per prompt* (every prompt starts again from the base, or fresh, and changes nothing), and *per iteration* (one conversation per repetition or per todo of a walk, which its pre-prompts and follow-ups continue). {~~(S17, the user guide § Named sessions; S23: qrun1)~>A transport whose outside program cannot fork a conversation, as the Copilot SDK, offers only *continue*. (<- S17 user guide *Named sessions*; S23: qrun1, vas1 … vas3; S30: xxcopilotsdk1)~~}
- {++**CR.130** A session that an item names and that does not exist yet is created at the item's first dispatch, from the item's spec (name, base, lifetime, profile). (<- S17 user guide *Named sessions*)++}
- **CR.76** An item whose profile cannot continue the existing conversation of its session is refused when it is queued. {~~(S17, the user guide § Named sessions)~>(<- S17 user guide *Named sessions*, *Profile*)~~}
- **CR.77** A temporary session is created for one item and removed when the item and its done notification are done. {~~(S17, the user guide § Named sessions)~>(<- S17 user guide *Named sessions*, *Fresh*, *Items from other quests*)~~}
- **CR.78** A session can be deleted, with its storage. {~~(S17, the user guide § Named sessions)~>(<- S17 user guide *Named sessions*, *SESSIONS view*; S23: qri1)~~}
- **CR.79** Planned: a session carries a choice that is required when it is created, "contributes to trail and memory". With it off, the session's turns go neither into the host's trail nor into memory or history. Sessions that exist count as on. {~~(S22 § 2.2 CQ-7, CQ-14, CQ-18)~>(<- S22 § 2.2 CQ-7, CQ-14, CQ-18; S23: 01_aifmt-4, planned)~~}
- {++**CR.131** Planned in the old extension: a session's storage, the compact trail and the journal of asks and answers become per-host files in the quest (`history/<host>/…`, the per-host class of CR.47); history is derived, not tracked, and can be rebuilt. Where the runtime keeps a host's files is open (PQ-53). (<- S23: 01_aifmt-4, planned)++}
- {++**CR.132** When an agent transport no longer has a session's conversation (it was held on another machine, or its store was cleared), the runtime starts a new conversation in the same session, once, and says so in the trail; the session goes on in the new conversation without the earlier context. (<- S17 user guide *A session Claude Code no longer has*)++}
- **CR.19** The queue walks a group of todos, lowest number first, one
  iteration per todo; it repeats items; and it sends timed requests on a schedule. {~~The queue itself sends no reminders:~>The queue itself sends no reminders (the old extension's queue reminders after a wait are being removed and are not carried):~~} the reminders there are, are a todo's (CR.50), the one reminder to an agent about its background work (CR.88) and tac's message kind (`TAC > TAC-KINDS`, CM.4). {~~(S1 § 5.3, § 3.1; S22 § 2.3 AC-22)~>(<- S1 § 5.3, § 3.1; S22 § 2.3 AC-22; S17 user guide *Repeat and Affix Support*, *Todo iteration*; S23: 01_aifmt-1, in progress)~~}
- **CR.80** A walk takes the open todo with the lowest number. It passes completed and cancelled todos and the user's own (CR.48). It holds at the first todo it cannot run, never earlier: a todo with open decisions, or one blocked by a todo that is not done (a blocker that runs earlier in the same walk, or in an item ahead of it, does not hold). The item is then held, its run is held (its automatic sending is switched off), and the user is notified. {~~(S23: vscimpb37; PQ-24)~>(<- S23: vscimpb37; S17 user guide *Todo iteration*) (-> PQ-24)~~}
- **CR.81** On a held item the user can stop it, continue (the todo is skipped and the walk goes on) or run the todo anyway. Skipping a todo is the user's action, never the runtime's choice. A walk with nothing to do ends as an error at once. {~~(S23: vscimpb37)~>(<- S23: vscimpb37)~~}
- **CR.82** After each todo of a walk the runtime reads the todo. When it is not completed and names no blocker, decision or open question, the runtime sends a continuation into the same session, at most a set number of times (2 by default, set per item and per run); then the item stops as "needs attention" and its run is held. The answer kept for the todo is that of the last turn. {~~(S23: vscimpb58)~>(<- S23: vscimpb58)~~}
- **CR.83** {~~Planned: when the blocker of a held item is completed or cancelled anywhere (in the same run, another run or another quest), the item goes back to pending, and its run's automatic sending is switched on again if the hold switched it off; a run the user paused stays paused. This is a setting per run, on by default, and holds for a release condition on a package version too. Until it is built, a held run goes on when the user resumes it. (S23: vscimpb179, planned; PQ-8; `DEC`, D-45)~>When the blocker of a held item is completed or cancelled anywhere (in the same run, another run or another quest), or the decisions it waits on are answered, the item goes back to pending, and its run's automatic sending is switched on again if the hold switched it off; a run the user paused stays paused. This is a setting per run, on by default, and holds for a release condition on a package version too. (<- S23: vscimpb179) (-> PQ-8, D-45)~~}
- **CR.84** Timed requests have two modes (every so many minutes; at times of day, daily or once on a date), a switch for all of them and a switch per entry (both must be on), and a largest number of sends after which the entry pauses. Their tick is the runtime's one clock: the checks of repeated todos and of todo reminders (CR.50) run on it. {~~(S23: vscimpb24, vscimpb152ab; S17, the user guide § 5)~>(<- S23: vscimpb24, vscimpb152ab; S17 user guide § 5, *Repeated todos*)~~}
- {++**CR.133** Timed requests also have global schedule slots that hold for every entry: weekdays, a time-of-day window and months; outside them no timed request is sent. (<- S17 user guide *Global Schedule Slots*)++}
- **CR.20** An item that is being executed can wait, and it can be interrupted; the two are different things. It waits for something outside that only time resolves (a wait the agent declares, CR.85) or for its own background work (CR.86); the item stays in execution and its run waits, as for an ask (`RT > RT-ASKS`, CP.21). An interrupt is the user's: soft (CR.89) or hard (CR.90). An update (CR.16) is neither: it is text the running prompt reads.{~~
  (S1 § 5.3, § 3.1)~>
  (<- S1 § 5.3, § 3.1)~~}
- **CR.85** The declared wait: an agent declares a wait for something only time resolves, with a reason and an end, at most 48 hours. Its run reports "waiting for an event" with the reason and the time left, and the wait survives a restart. The user can interrupt it: the agent then ends its turn with a note of what is still to do, the item steps back behind the next pending item of its run (to staged when none follows), and its stage is sent again later with a note to resume. {~~(S23: vscimpb82)~>(<- S23: vscimpb82)~~}
- **CR.86** Waiting for the item's own background work: the work counts as alive while its process is alive, not while it prints. The wait has a limit, set per item, else per profile, else 6 hours (0 means no wait). The user can wait without a limit, start the limit again, or stop waiting. {~~(S23: vscimpb56, vscimpb57)~>(<- S23: vscimpb56, vscimpb57)~~}
- **CR.87** A command that detaches itself from the execution is refused in a queue execution on an agent transport. {~~(S23: vscimpb56)~>(<- S23: vscimpb56)~~}
- **CR.88** When a turn ends its answer while its background work still runs, the runtime sends the agent one reminder prompt into the same turn; the prompt is a template that can be edited. {~~(S23: vscimpb143)~>(<- S23: vscimpb143)~~}
- **CR.89** A soft interrupt holds the execution at the result of its next tool call: the turn stays open, and the run's automatic sending goes off. Without a point to hold at within 15 seconds it becomes a hard interrupt, unless the user asked to wait. A turn that waits in an ask, in a declared wait or for background work counts as held at once, and an answer given meanwhile is kept until the resume. Resuming hands the held result back and sends nothing again. {~~(S23: vscimpb112)~>(<- S23: vscimpb112)~~}
- {++**CR.134** On an agent transport the hold point of a soft interrupt is the result of a runtime tool called through MCP, or the outside program's tool hook where it has one; where neither comes within the time of CR.89, the soft interrupt becomes a hard one. (<- S30: xxproviders8)++}
- **CR.90** A hard interrupt cancels the prompt: the item is interrupted, and on resume its current repetition is sent again, with a note, in the same conversation. {~~(S23: vscimpb112)~>(<- S23: vscimpb112)~~}
- **CR.91** After a restart while an execution was held, a model transport continues where it stopped, and an agent transport is sent the prompt again with the note and the held result. {~~(S23: vscimpb112)~>(<- S23: vscimpb112)~~}
- **CR.92** An item stopped for lack of credit is marked out of budget, and its run is held. It can be continued on another profile: by the user, by an agent, or automatically through a configured fallback. The stopped stage is then sent as a hand-over prompt (what stopped where, the session's live trail, the original prompt), in the item's session unless that profile cannot continue the conversation, and the later stages follow on that profile. {~~(S23: ccparity_e_process-10)~>(<- S23: ccparity_e_process-10)~~}
- **CR.21** When an item is done, the queue carries out what its todo names
  for completion (unblocking other todos, notifying, queueing) and delivers
  the done notification that the item or its todo asks for (CR.93, CR.94) to the run and session that queued it. {~~(S1 § 5.3,
  § 2.1)~>(<- S1 § 5.3, § 2.1; S17 user guide *After done and Filed by*; S23: ww_a_collab-2, ww_a_collab-5)~~}
- **CR.93** The done notification is a prompt that is queued ahead of every other pending item when the item is finished, or has ended in an error that will not recover (not for a wait on a quota or a rate limit); once per run of the item. It carries the outcome, the item's answer (per todo for a walk, shortened with a pointer), its title, its todos with their status, and the sending quest and run. It can be aimed at a named quest and run. {~~(S23: vscimpb71, vscimpb72)~>(<- S23: vscimpb71, vscimpb72, vscimpb146)~~}
- **CR.94** Every item records who queued it: the quest, the run and the session. A todo's done notification has no default: it goes to the run and session that queued the todo, and without one nothing is sent, which is logged. {~~(S23: vscimpb146)~>(<- S23: vscimpb146)~~}
- **CR.22** A todo can name the profile it is executed with; the todo's choice wins
  over the item's. The team's allowed providers (CS.6) limit both choices. {~~Planned (S23: vscimpb174). (S1 § 3.1)~>Planned. (<- S1 § 3.1; S23: vscimpb174, planned)~~}
- **CR.95** A todo can name the role and the guideline choices (CR.61) it is executed with. {~~(S23: gsel1; S24)~>(<- S23: gsel1, gsel3; S24)~~}
- **CR.96** {~~Planned: the role of a queued prompt~>The role of a queued prompt~~} is the todo's, else the item's, else the role of the step that queued it, else the run's; a run's queue defaults (CR.70) may name a role. {~~(S24, R-1 … R-4; S23: gsel3)~>(<- S24: R-1 … R-4; S23: gsel3, gsel11)~~}
- **CR.97** Planned: a todo can name chat variables that are set while it runs, with a flag to unset them when it is finished. A todo's profile that does not exist, or that cannot continue the session of its walk, is an error when the item is queued, never a fallback. {~~(S23: vscimpb174)~>(<- S23: vscimpb174, planned)~~}
- **CR.23** A run reports its state as events. It is one of the following, the first that applies {~~(S23: vscimpb123, vscimpb112; PQ-24):~>(<- S23: vscimpb123, vscimpb112) (-> PQ-24):~~}
  - **waiting for the user**: an ask, an approval, a plan, a pick or a document ask of the run is open;
  - **waiting for an event**: a declared wait (CR.85), with its reason and until when;
  - **waiting for its own background work** (CR.86);
  - **running**;
  - **paused**: by the user, with the count of its pending items;
  - **idle**;
  - and **held**: its next item is not executed (open decisions, a blocked todo, needs attention, an error, out of budget), or a soft interrupt holds its execution.

  A run **waits** while its item is still being executed and blocked in something; its settings are untouched and it goes on by itself when the cause ends. A run **is held** when its next item is not executed at all; its automatic sending is off, and it goes on when the user resumes it (CR.83). **Paused** is what the user did to a run. Each state carries its detail and is published with the runtime's registration (`TAC > TAC-COORD`, CA.5); a waiting run stays waiting across a restart of its host. The Solution Blueprint settles where "held" stands in the order.
  Every prompt can be addressed in
  the trail, {~~so a host can show "this prompt" in a run's log. (S1 § 3.2)~>so a host can show "this prompt" in a run's log. (<- S1 § 3.2)~~}
- **CR.24** The trail is the durable record of a run. For a prompt that draws
  on a document the host marks as encrypted, the trail is kept in memory
  {~~only. (S1 § 3.2)~>only. (<- S1 § 3.2; S17 user guide § 9; S23: 00_aifmt-1, 00_aifmt-4, gsel11)~~}
- {++**CR.135** The trail records each prompt as it was typed and as it was sent, together with its system prompt; the record of a session's current prompt is kept for chat sends and queue items alike and is machine-local. (<- S17 user guide *Current Prompt sub-tab*)++}
- {++**CR.136** The prompt and answer pairs of a quest can be listed and read across its sessions. (<- S17 llm_tools § 10)++}
- {++**CR.137** A session's history and memory can be rebuilt from its trail, and a compaction can be tried without writing anything. (<- S17 user guide § 9)++}
- {++**CR.138** Planned: every tool call is attributed to the execution that made it, also when several executions of one runtime run at once, so that what it records (who filed a todo, a claim) names the right session. (<- S23: qr5, planned)++}

### <!--[RT-TRANSPORTS]--> 7.4 Transports

- **CR.25** A prompt reaches a model through a transport, and there are two
  kinds. A **model transport** calls a model's API, and the runtime runs {~~the
  tool loop, the approvals and the retries.~>the
  tool loop, the approvals (CR.139) and the retries.~~} An **agent transport** hands the
  prompt to an outside program (an agent SDK or a command line) that runs the loop itself and reaches the runtime's tools
  {~~through MCP. (S1 § 5.4; S7)~>through MCP. (<- S1 § 5.4; S7; S23: ccparity_c_transports-1, ccparity_c_transports-2, ccparity_c_transports-9, ccparity_d_claudecode-5)~~}
- {++**CR.139** A profile sets how tool calls are approved: *always* (every writing tool asks), *accept edits* (edits are taken without asking), or a tool allowed for the rest of the session; reading tools never ask, and a queued prompt never asks. (<- S17 llm_tools § 5.1; S23: ccparity_c_transports-2, ccparity_c_transports-6)++}
- **CR.26** All transports are the runtime's own. A host implements no
  transport. {~~(S2 § 5, FO-2; `SCO > SCO-OUT`, O-4)~>(<- S2 § 5) (-> FO-2, O-4)~~}
- **CR.27** The model transports carry what the direct transport has today:
  prompt caching, one retry layer, usage and cost per round, continuation of
  a cut-off answer, compaction of history, {~~effort and thinking settings.
  (S2 § 3.1; S1 § 3.1)~>effort and thinking settings; a core set of tools sent in full and the other tools deferred behind the provider's tool search, with the tools a prompt or its template names sent in full; the server-side clearing of old tool results; images and documents (PDF) as content to the model; a retry with the transport retry template while the provider's backend is busy. (<- S2 § 3.1; S1 § 3.1; S17 anthropic_handler § 7, llm_tools § 5.0, llm_configuration § 3, § 7; S23: ccparity_a_directapi-1, ccparity_a_directapi-2, ccparity_c_transports-5, ccparity_c_transports-8, ccparity_c_transports-10, cc_parity_a_start-5, dapieff5, dapieff7)~~}
- **CR.98** Usage and cost are reported per round and per prompt on every transport, also in a resumed conversation of an agent transport: the prompt's own rounds, tokens and cost, not the whole session's. {~~(S23: qrfix3)~>(<- S23: qrfix3, ccparity_a_directapi-3, dapieff2)~~}
- {++**CR.140** When an agent transport's outside program fails, the runtime reports the real cause (an expired sign-in and the like), not only that the program ended. (<- S23: sdkerr)++}
- **CR.28** A soft interrupt (CR.89) holds an execution at the result of a tool call on every transport; what differs by the kind of transport is where an update is taken (CR.72) and how a held execution continues after a restart (CR.91).{~~
  (S1 § 3.1)~>
  (<- S1 § 3.1)~~}
- **CR.29** The runtime can run in a mode that offers only the agent
  transport of the Claude Agent SDK to a host, without a quest, so an
  application ships one Node payload. {~~(S2 § 3.2)~>(<- S2 § 3.2) (-> D-16)~~}
- **CR.30** The runtime speaks the Agent Client Protocol in that protocol's role of the client ("client" and "agent" are the protocol's names for its two sides): one
  adapter reaches every outside program that speaks it in the role of the agent, and the native transport of such a program
  is kept where the protocol loses features. This comes after the
  native transports. {~~(S1 § 5.4, CQ-5)~>(<- S1 § 5.4) (-> CQ-5)~~}
- **CR.31** The runtime also answers the Agent Client Protocol in the protocol's role of the agent on
  standard input and output, so an editor that speaks it can open a session
  of a quest. It covers chat, updates and permission requests; the queue,
  todos and processes stay in the runtime's own protocol. This comes late.{~~
  (S1 § 6.5, CQ-5)~>
  (<- S1 § 6.5) (-> CQ-5)~~}

### <!--[RT-LOCATIONS]--> 7.5 Locations

- **CR.32** The runtime finds every place it needs through one resolver, the
  workspace layout, as it is built in the extension. Outside VS Code the host
  passes the workspace folder and the quest. Every host passes the overrides it holds; in VS Code those are the ones of the quest's `.code-workspace` file. {~~(S1 § 5.5; S12)~>(<- S1 § 5.5; S12; S17 user guide § 2, § 7)~~}
- **CR.33** The resolver answers:
  - the **root**: the nearest folder at or above the workspace folder that
    holds `.tom/tom_root.yaml`; a workspace folder with none above it is
    standalone and its own root;
  - the **`_ai` folder**: the workspace folder's `_ai` as it is opened, else
    the root's; paths are compared by their real path, because the entry is
    a link onto one clone;
  - the **guidelines**: the root's `_agent_guidelines/`, then the workspace
    folder's; a file of the same relative path in the workspace wins; {~~a project's own `_agent_guidelines/` is read before both when the work touches that project;~>a project's own `_agent_guidelines/` is read before both when the work touches that project; the old folder name `_copilot_guidelines` is read beside `_agent_guidelines` until dropping it, which is planned (<- S23: 15a_wslayout-1, planned);~~}
  - the **quests of a workspace**: those its list
    `_ai/workspaces/<workspace>.yaml` names; without a list, every quest of the register (CR.100).

{~~  (S1 § 5.5; S12)~>  (<- S1 § 5.5; S12; S17 user guide § 2, § 7; S23: vscimpb144)~~}
- **CR.99** The places CR.33 names are defaults: the root's `.tom/tom_root.yaml` and a workspace folder's optional `.tom/tom_workspace.yaml` can name other places for the `_ai` folder, the guidelines and the configuration. {~~(S12; S27, `workspace_layout.md` § 2, § 3, § 5)~>(<- S12; S27: `workspace_layout.md` § 2, § 3, § 5)~~}
- **CR.100** The register `_ai/quests.yaml` lists every quest of the `_ai` state with its type (a classic quest, or a repository quest as a single-quest repository or a multi-quest repository; `PAR > PAR-QUESTS`, CQ.1) and its setup. A workspace's list picks from it. The checkout of a repository quest may be missing on a machine: the runtime reports that as a state of the quest, not as an error of the store. Planned with format version 11 (CR.3). {~~(S22 § 3.4, § 2.4 QM-1, QM-2, § 4)~>(<- S22 § 3.4, § 2.4 QM-1, QM-2, § 4; S23: 02_aifmt-1, planned)~~}
- **CR.101** The nested cases, as the resolver has them: the nearest root marker wins, and an inner root inherits nothing from an outer one; a workspace folder inside another has its own `.tom` and the root's as layers; a plain folder without a quest file works on the default quest; in a workspace of several folders the first is the workspace folder. {~~(S12; S27, `workspace_layout.md` § 7)~>(<- S12; S27: `workspace_layout.md` § 7; S17 user guide § 7)~~}
- **CR.102** {~~A workspace is named after the root folder its host opened. Planned: what the runtime answers about a workspace includes the repositories of the record (CR.34), each with a description and whether it is cloned on this machine. (S23: vscimpb144; vscimpb154, 00_aifmt-2, planned)~>A workspace is named after the root folder its host opened. What the runtime answers about a workspace: its name and file, its folders, the quest, the git state, the host's build running and installed (whether a reload is needed), the Dart binaries, and on request the projects, the layout, the workspace folders, the quests and the repositories of the record (CR.34), each repository with its kind, its branch or pin, its address, a description, whether it is cloned on this machine and the projects inside it. Planned: the quests' short descriptions name the repositories a quest works on. (<- S23: vscimpb144, gsel12, 00_aifmt-2; vscimpb154, planned; S17 llm_tools § 10)~~}
- **CR.34** The repositories of a workspace are those of the file the
  workspace is set up from (`repos.yaml`). {~~(S1 § 5.5, CQ-3)~>(<- S1 § 5.5; S23: gsel12, 00_aifmt-2) (-> CQ-3)~~}
- **CR.103** The record gives each repository a kind and a branch, and a repository may be absent on a machine by design. {~~(S27, `repos.yaml`, `workspace_layout_multi.md` § 3)~>(<- S27: `repos.yaml`, `workspace_layout_multi.md` § 3; S23: gsel12)~~}
- **CR.104** The claims and the integration step respect the record: the integration step lands on the branch the record names for the repository, and a repository the record marks as read-only, or a binaries repository, {~~is never its target. (S27, `repos.yaml`, `workspace_layout_multi.md` § 3; `PAR > PAR-APPROACH`)~>is never its target (`PAR > PAR-APPROACH`). (<- S27: `repos.yaml`, `workspace_layout_multi.md` § 3)~~}
- **CR.35** A quest lists the repositories and subtrees it usually works on.
  A todo is written with the resources it needs; for a todo that names none, the runtime claims the quest's whole list for as long as the todo is executed. {~~No source fixes where a quest's list is recorded (the register of CR.100 has no field for it); the Solution Blueprint settles the place. (S1 § 5.5, CQ-3, DQ-5;
  `PAR`)~>S1 and S6 name a quest file `quest-resources.<quest>.yaml` (`default_resources`); the format standard S22 has no such file and the register of CR.100 no field for it; the Solution Blueprint settles which it is. (<- S1 § 5.5; S6: BP-8) (-> CQ-3, DQ-5, CW.8)~~}

### <!--[RT-CONFIG]--> 7.6 Configuration

- **CS.1** The configuration is layered, later layers winning: built-in
  defaults, the user's own file, the root's `.tom`, the workspace folder's
  `.tom`, the quest's layer (the same on every machine, and one per machine), the
  host's settings. Objects merge deep; arrays and single values replace.
  Of the `.tom` folders only the root's and the workspace folder's are layers.{~~
  (S1 § 5.5; S12)~>
  (<- S1 § 5.5; S12; S17 user guide § 7)~~}
- **CS.19** A write goes to the root's file, until the user picks a layer; picking a layer is planned. {~~(S27, `workspace_layout.md` § 5; S23: 13d_wslayout-1 … 13d_wslayout-4, planned)~>(<- S27: `workspace_layout.md` § 5; S23: 13d_wslayout-1 … 13d_wslayout-4, planned)~~}
- **CS.20** The user's own file is part of the machine-wide state (CR.36): one file for all hosts of a machine and user, at the place of that state (CR.106). This is stated for a host on the user's machine; what a runtime behind the web runtime service has in its place is open (PQ-38). {~~(S12; S27, `workspace_layout.md` § 5)~>(<- S12; S27: `workspace_layout.md` § 5)~~}
- **CS.2** A write changes one key in one file: it checks that the file has
  not changed since it was read and writes it atomically, so two runtimes
  changing different keys never lose each other's change. {~~(S1 § 5.5; S12)~>(<- S1 § 5.5; S12; S17 user guide § 7)~~}
- **CS.3** The configuration is split by who decides it {~~(S1 § 5.5, DQ-8,
  DQ-11):~>(<- S1 § 5.5; S17 user guide *Copilot*, *Group prompt editor*, *Process template editor*, *Assist prompts*, anthropic_handler § 5; S23: vscimpb120) (-> DQ-8, DQ-11):~~}

  | Part | Holds | Lives |
  | --- | --- | --- |
  | **The repository's** | what belongs to working on code: {~~role types, process definitions, prompt templates (saved prompts are not part of it: they are a store of the quest, CR.54)~>role types, process definitions, templates of every category: user-message templates, group prompts, assist prompts (CR.119), the templates of the todo buttons and of the Proceed prompt (CR.124), the queue templates, and the templates of profiles' system prompts, compaction, memory extraction, transport retry and interactive questions (saved prompts are not part of it: they are a store of the quest, CR.54; reminder templates are not carried, CR.19)~~} | in the repository, under version control |
  | **The team's** | what belongs to the team as an organisation: the providers and their configurations, which providers may be used, the standard profiles | in tac, as the team's configuration, in whichever backend the team uses |
  | **The runtime's** | queue settings, timeouts, compaction, retries; paths, executables and preferences of a machine or host | per runtime, machine or host, in the layers of CS.1 |

  The Solution Blueprint settles in which repository role types, process definitions and prompt templates lie when a quest works on several.

- **CS.4** Only a team's owners change the team's configuration. A runtime
  fetches it when it connects, keeps a copy so it starts when it is offline,
  and is told of changes. {~~(S1 § 5.5, DQ-11; `TAC`)~>(<- S1 § 5.5) (-> DQ-11)~~}
- **CS.5** In the layering, the team's configuration stands above the user's
  own file for the keys the team owns (a user cannot override them) and
  below it for the keys the team only suggests. The Solution Blueprint settles: which keys the team owns and which it only suggests; where the copy for offline starts (CS.4) is kept; and that a runtime uses the configuration of the home team of its quest when its person belongs to several teams, the allowed providers of CS.6 included. {~~(S1 § 5.5, DQ-11)~>(<- S1 § 5.5) (-> DQ-11)~~}
- **CS.6** Which providers a runtime may use is decided by the team's
  configuration. {~~(S1 § 5.5, DQ-8; `SCO > SCO-LATER`, L-2)~>(<- S1 § 5.5) (-> DQ-8, L-2)~~}

### <!--[RT-MACHINE]--> 7.7 Machine-wide state

- **CR.36** Some state belongs to all runtimes of a machine together: queue
  settings per quest and run (a writer writes only the runs it changed, CS.2), the user's configuration, which runtimes and
  runs exist and what they do, the inbox for items sent from one quest to
  another (`PAR > PAR-CROSS`, CW.19), notifications for the user, the open asks of the machine's runtimes, so that an ask can be answered from another runtime of the machine (`RT > RT-ASKS`), and the usage ledger (CR.105). {~~(S1 § 5.6; S23: vscimpb60a, vscimpb168)~>(<- S1 § 5.6; S17 user guide *Window Status Panel*; S23: vscimpb60a, vscimpb168, gsel3)~~}
- **CR.105** The usage ledger holds usage and cost {~~per day and model~>per day, provider and model~~} for the last 62 days, added as each round's response arrives. {~~(S23: qrfix3; S17, the extension's usage ledger)~>(<- S23: qrfix3, ccparity_a_directapi-3, dapieff2; S17: the extension's usage ledger; S30: xxproviders4)~~}
- {++**CR.141** Planned: the size of the tool definitions each role type sends per turn is measured. (<- S23: tooloptimize15, planned)++}
- **CR.106** Nothing of the machine-wide state, of the local tac service's store or of the inbox lies in the `_ai` folder: its top level is a closed list that a commit guard keeps. The Solution Blueprint settles the place outside `_ai`. {~~(S22 § 1, § 3.6)~>(<- S22 § 1, § 3.6)~~}
- **CR.107** The notifications are one log for the machine, of the two classes `RT > RT-PROTO`, CP.4 names: events on queues and todos, and events directed at the user, among them the answers handed to the user. {~~(S23: vscimpb124, vscimpb170, vscimpb171)~>(<- S23: vscimpb124, vscimpb170, vscimpb171)~~}
- **CR.37** The runtime owns this state. A host or a tool never reads or
  writes its files; it asks its runtime. {~~(S1 § 5.6, CQ-2)~>(<- S1 § 5.6) (-> CQ-2)~~}
- **CR.38** Inside the runtime there is one interface to this state with two
  implementations: through the local tac service, which runs once per machine
  and user and through which every runtime's access is routed, so concurrent
  access is handled in one place; and through files, one key at a time under
  a file lock, when coordination is switched off. {~~(S1 § 5.6, CQ-2)~>(<- S1 § 5.6) (-> CQ-2)~~}
- **CR.39** The local tac service outlives a single runtime and carries the
  state from one to the next. {~~(S1 § 5.6)~>(<- S1 § 5.6)~~}

### <!--[RT-INSTALL]--> 7.8 Installation and lifetime

- **CR.40** There is one runtime installation per machine and user, in
  the application data folder of the operating system, with the provider
  SDKs beside it. This is stated for a host on the user's machine (the web runtime service: PQ-38). Which Node runs a runtime outside VS Code is open (PQ-37), and the Solution Blueprint settles where the runtime installation keeps the binaries per platform {~~(S1 § 5.7; S2 § 5, FO-3):~>(<- S1 § 5.7; S2 § 5; S17 user guide *Provider SDKs*; S23: chat2) (-> FO-3):~~}

  | System | Runtime | Provider SDKs |
  | --- | --- | --- |
  | macOS | `~/Library/Application Support/Tom/runtime/` | `~/Library/Application Support/Tom/providers/` |
  | Linux | `~/.local/share/tom/runtime/` | `~/.local/share/tom/providers/` |
  | Windows | `%LOCALAPPDATA%\Tom\runtime\` | `%LOCALAPPDATA%\Tom\providers\` |

> **❓ PQ-37 (2026-11-25T20:48+01:00) — how every host gets and starts the runtime: Node, the Agent-SDK-only mode, the installer, and the new extension:** Where does Node come from for a runtime outside VS Code, who installs the runtime and the provider SDKs, is the Agent-SDK-only mode still needed, and does the new VS Code extension run the runtime in its own process or as a process?
>
> **Context:** Four points about getting and starting the runtime.
>
> **Node.** `NFR`, N-24: "The runtime is a Node program written in TypeScript". `RT > RT-INSTALL`, CR.40: "There is one runtime installation per machine and user, in the application data folder of the operating system, with the provider SDKs beside it"; CR.42: "Every host carries a runtime installation and installs it into the shared location when none is installed there." Nothing says which Node runs a runtime outside VS Code. Tom Forge plans to start the runtime "with the Node the packaging names" and to report "a missing or too-old Node … with the remedy rather than a hang" (tom_forge todo `qavs_wwworkbench-3`). This quest's todo `ww_d_workbench-10` (S30) plans one bundle installed with `npm ci --omit=dev`, the Agent SDK not redistributed.
>
> **The installer.** CR.43: "Provider SDKs, and the command lines and native runtimes some providers need, are installed on request, when a profile first needs one" — by the runtime. The product owner decided in the webwork quest (FQ-3 (a)) one installer package in `tom_ai/modules`, `tom_tool_installer` (pure Dart, with `tom_tool_installer_ui`), which takes the Agent SDK server install from `tom_core_agentic` and later other providers' SDKs, with publisher, terms, exact version and a confirmation for every install (tom_forge todo `03b_woneb2`). A Dart installer cannot run inside the Node runtime.
>
> **The Agent-SDK-only mode.** `RT > RT-TRANSPORTS`, CR.29: "The runtime can run in a mode that offers only the agent transport of the Claude Agent SDK to a host, without a quest, so an application ships one Node payload." (`DEC`, D-16.) It was meant for Webwork, whose AI talks to a small Node server around the Claude Agent SDK today. Webwork's plan has changed: from its wave 1b2 on it uses a full runtime without a quest and removes its own transports (webwork todos `13_woneb1`, `13_woneb4`). No other user of the mode is named.
>
> **The new extension.** D-73: the VS Code extension is copied into `tom_ai/ai_build` and "work[ed] on … until it works with the AI runtime and all features working as before (only distributed and with a team)". `NFR > NFR-GEN`, G-1, calls the runtime a "server (also a library inside the new VS Code extension, as long as PQ-37 leaves that standing …)"; `RT > RT-HOST`, CP.14: "In VS Code the new extension (D-73) implements the interface in its own process and the runtime calls it directly, as long as the runtime runs in that process …; in every other host it is carried by the protocol's reverse requests"; `NFR > NFR-TOPO`, T1: "One runtime per window, inside the new VS Code extension (in its own process until PQ-37 is answered …)". `RT > RT-INSTALL`, CR.142: "Whether it runs the runtime inside its own process or starts it as a process from the runtime installation, as every other host does, is open (PQ-37); until that is answered it runs the runtime in its own process".
>
> **Why I ask:** A runtime installation that brings its own Node is larger but starts on every machine; one that uses the machine's Node fails on a machine without Node, the normal case for a Webwork user who is not a developer. Two installers for the same machine (the runtime's and `tom_tool_installer`) need a rule for who installs what, or the terms rule FQ-3 decided is bypassed. If nobody uses the Agent-SDK-only mode, CR.29 and D-16 describe a second way of running the runtime to be specified, built and tested for nothing. And a new extension that runs the runtime in its own process tests a path no other host uses, while one that starts a process tests the protocol every other host depends on; G-1, CP.14, T1 and `RT > RT-TOOLS`, CT.8, read differently by the answer.
>
> - (a) Node is found on the machine, with a lowest version the runtime installation names. The runtime installs its provider SDKs itself; `tom_tool_installer` installs only tools outside the runtime. The Agent-SDK-only mode stays (CR.29, D-16). The new extension runs the runtime in its own process (G-1, CP.14, T1 stand).
> - **(b)** The runtime installation brings its own Node per platform; a host never looks for one. For a Dart host outside VS Code (Webwork, Tom Forge), `tom_tool_installer` installs the runtime installation, through a descriptor the installation publishes, with the terms and confirmation FQ-3 decided; the runtime installs only its provider SDKs, showing the same facts (publisher, terms, version) and asking for the same confirmation. The Agent-SDK-only mode is dropped: CR.29 reads "A runtime without a quest offers every transport", and D-16 "The Agent SDK server of today is replaced by a runtime without a quest". The new extension starts the runtime as a process from the runtime installation, like every other host, and is a runtime client over the protocol; G-1 no longer names a library inside the new extension, CP.14 loses its first half, and T1 says that the runtime of a window runs as a process beside the new extension.
> - (c) The runtime installation uses the machine's Node when it is new enough and installs its own on request when not. Every install, the provider SDKs included, goes through `tom_tool_installer` in the host; the runtime only reports what is missing. The Agent-SDK-only mode is dropped as in (b). The new extension runs the runtime in its own process first and moves to a process later.
> - (d) As (b), but the Agent-SDK-only mode stays, for an application that wants an agent without queues and runs.
>
> *Recommendation:* (b) — Webwork's and the supervision application's users have no Node; one installer for the Dart hosts keeps the terms rule while the runtime stays the one place that knows which provider SDK a profile needs; the mode has lost its only user; and a new extension that starts a process tests the protocol every other host depends on, which is what "distributed and with a team" asks of it.
>
> *Assumption until answered:* CR.40 … CR.43 and N-24 name no source of Node and no installer besides the host; CR.29 and D-16 keep their text; CR.142 says the new extension runs the runtime in its own process, as G-1 and CP.14 say.
>
> **Answer:**

- **CR.41** Versions are installed side by side, each in a folder of its
  own, with a pointer `current` to the newest. A running runtime keeps its
  version until it is restarted. {~~(S1 § 5.7; S2 § 5, FO-4)~>(<- S1 § 5.7; S2 § 5) (-> FO-4)~~}
- **CR.42** Every host carries a runtime installation and installs it into the shared
  location when none is installed there. When one is installed, the
  host uses it. Hosts on one machine thereby share one runtime installation, and each starts its own runtime from it. A host
  offers updating the runtime in the part of its settings where it offers
  what can be installed and removed; nothing is updated without the user
  having asked for it. {~~(S1 § 5.7, DQ-9; PQ-6)~>(<- S1 § 5.7) (-> DQ-9, PQ-6)~~}
- {++**CR.142** The new VS Code extension (D-73) is the VS Code host of the runtime. Whether it runs the runtime inside its own process or starts it as a process from the runtime installation, as every other host does, is open (PQ-37); until that is answered it runs the runtime in its own process, as `NFR > NFR-GEN`, G-1, and `RT > RT-HOST`, CP.14, say. (-> D-73)++}
- **CR.43** {~~Provider SDKs are installed on request~>Provider SDKs, and the command lines and native runtimes some providers need, are installed on request~~}, when a profile first
  needs one. {~~(S2 § 3.2; S1 § 3.1)~>(<- S2 § 3.2; S1 § 3.1; S17 user guide *Provider SDKs*; S23: chat2; S30: xxcopilotsdk1)~~}
- {++**CR.111** A host offers a provider page: per provider its ways in with a short explanation (where it processes data, what account it needs), installing what a way in needs (an SDK, a command line, a native runtime), and fields for the secret references, environment-variable names and accounts of its configurations. Providers that need no transport of their own are listed with how they are configured. (<- S30: xxproviders1, xxbaidu1, xxdeepseek1)++}
- **CR.44** A runtime is started by its host and ends with it. A long walk
  needs its host open, and so do timed requests and a todo's reminders (CR.50): they are sent and ring only while a host has the runtime running. {~~(S1 § 5.7, CQ-4; `SCO > SCO-LATER`, L-5)~>(<- S1 § 5.7) (-> CQ-4, L-5)~~}
- **CR.45** Inside a running runtime, a run is unloaded when its last
  subscriber has gone and nothing is queued in it. This is an option, not
  part of the first version unless measurement shows the memory is worth the
  added complexity: a runtime ends with its host and loads its runs again
  when the host starts, so a run is not held for long anyway. {~~(S1 § 6.1;
  PQ-21)~>(<- S1 § 6.1) (-> PQ-21)~~}
- **CR.108** A runtime does not run on a phone, on a tablet or in a browser. An application there uses the web runtime client SDK and talks to a web runtime service on a server, which connects to a runtime on the application's behalf. The service is HTTP-based, and one service may serve applications on phones and tablets and web applications. How the events of a run, asks and a host's tools cross it is open. {~~(PQ-28)~>(-> PQ-28)~~}
- **CR.46** A web runtime service can host runtimes for applications that have none of their
  own: the server side of a web application or of an application on a phone
  or a tablet runs permanently and starts one runtime per connected application, which ends
  with that application's connection. The rule of CR.44 holds: the web runtime service is the
  host. A runtime that runs for a long time without any runtime client, on an
  always-on machine, is later (`SCO > SCO-LATER`, L-5). How the service works (one runtime per connected application, ending with the connection, the service as the host) is assumed until PQ-38 is answered. {~~(PQ-16, PQ-9;
  `NFR > NFR-TOPO`, T8)~>(-> PQ-16, PQ-9, T8)~~}

> **❓ PQ-38 (2026-11-20T16:30+01:00) — what the web runtime service is:** Is the web runtime service a program that starts a runtime for each connected application, or a front to runtimes that run anyway; and whose runtime is it, how long does it live, and who operates the service?
>
> **Context:** Your answer to PQ-28: "I assume the runtime cannot run directly in mobile devices, so there will be an additional relay which connect to a runtime on behalf of the device … there would be a remote runtime client SDK that connects to a remote runtime service running on a server. That remote runtime service would then connect to the tac as usual from the server. For the web scenario we'll need a HTTP-based service, maybe this can be one and the same as what is used by mobile devices. So I suggest we call the component web runtime client SDK and web runtime service …". The text now uses the two names: an application on a phone, on a tablet or in a browser uses the **web runtime client SDK** and talks to a **web runtime service** on a server.
>
> What the Project Idea said before, under the name "runtime host server", and still says, marked as assumed: `RT > RT-INSTALL`, CR.46: "A web runtime service can host runtimes for applications that have none of their own: the server side of a web application or of an application on a phone or a tablet runs permanently and starts one runtime per connected application, which ends with that application's connection. The rule of CR.44 holds: the web runtime service is the host." Other items build on a runtime that sits on its user's machine: CR.7 "A runtime belongs to exactly one person"; `RT > RT-CONFIG`, CS.1 (the configuration includes "the user's own file"); `RT > RT-SECRETS` (secrets come from the user's Tom Secrets Manager or the operating system's secret store; a locked vault is unlocked by the user); CR.40 (one runtime installation "per machine and user"); `TAC > TAC-PEOPLE`, CA.40 (a runtime sees "the repositories the person it belongs to has access to …, cloned on its machine"). Your answer to PQ-26 (a) says a server reaches tac only through the runtimes it starts.
>
> **Why I ask:** "Connect to a runtime on behalf of the device" can be read in two ways, and the items above come out differently:
>
> - If the service **starts** a runtime per connected application, the runtime ends when the connection ends. A phone loses its connection whenever the application goes to the background, so a queue or a walk stops there, and nothing on the server watches for the user meanwhile. And the runtime runs on a server that many users share: whose settings, whose secrets, which clones?
> - If the service is a **front** to runtimes that exist anyway (the user's runtime on a desktop that is switched on, or a runtime that runs on the server for a long time), the runtime's life is its own. Then "standalone runtimes on an always-on machine" (`SCO > SCO-LATER`, L-5; T6), which are deferred, come into the first version, or a phone works only while the user's desktop runs.
>
> Also open with it: who installs and operates the service (the team's administrator beside the tac server, on the same machine?); whether it also serves a web application's files (Webwork planned "a server-side runtime that also hosts the web version"); and what it gets in the delivery: `NFR > NFR-GEN` names it as a unit (G-10, its technology "not stated"), and no deliverable, document or user group exists for it yet.
>
> - (a) The service starts a runtime without a quest per signed-in user (not per connection) on the server, and keeps it for a set time after the last connection ended, so a phone that comes back finds its runtime. The runtime is that user's: it presents the user's team token to tac; it has no clones and no user file, so it serves messaging, asks, review and supervision, and no work on repositories. Secrets it needs are the server's. The team's administrator operates the service beside the tac server; it does not serve application files.
> - **(b)** As (a) for the first version, and the service can also attach a device to a runtime of the same user that runs elsewhere (on the user's desktop, found through tac) when that runtime allows remote control: the phone then sees and steers the real runs, queues and asks of that runtime. Work on repositories from a phone alone (a runtime with clones on the server) is later, with the standalone runtimes of L-5.
> - (c) The service is only a front: it never starts a runtime. A device reaches the user's own runtimes (on a desktop that is on, or standalone ones on a server, which then are part of the first version). Messaging and asks on a phone work only while one of the user's runtimes runs.
> - (d) The service starts a full runtime per user on the server, with clones of the user's repositories there (a working copy per member, commits through a GitHub App, as tom_forge's todo `later23` sketches), so a phone or a browser can do everything a desktop can.
>
> *Recommendation:* (b) — it gives a phone what trc and messaging need (asks, messages, review, supervising the runs of one's own machines) without server-side clones or standalone runtimes, and it keeps CR.7 true: every runtime behind the service is one user's.
>
> *Assumption until answered:* The text says "web runtime service" where it said "runtime host server". CR.46's statements on how it works (one runtime per connected application, ending with the connection, the service as the host) and CR.110 (how it checks an application and reaches tac) are kept and marked as assumed. CR.7, CS.1 and CR.40 are stated for a host on the user's machine. Beside the unit G-10, no deliverable or user group is added for the service.
>
> **Answer:**

- **CR.110** The web runtime service reaches tac only through the runtimes it starts. It checks a connecting application against its own configuration, or by starting the runtime, which then presents the user's team token. Assumed until PQ-38 is answered. {~~(PQ-26)~>(-> PQ-26)~~}
- **CR.109** Open for a runtime behind the web runtime service (PQ-38): whose it is, where its settings, its secrets, its runtime installation and its clones are, how long it lives, and who operates the service. The Solution Blueprint describes the service, its deliverables and who uses it once that is answered; `NFR > NFR-GEN`, G-10 names it as a unit already.

### <!--[RT-SECRETS]--> 7.9 Secrets

- **CS.7** A configuration names a secret and never holds one. The forms of a
  reference {~~(S1 § 5.8, CQ-16; S2 § 5, FO-15):~>(<- S1 § 5.8; S2 § 5) (-> CQ-16, FO-15):~~}

  | Form | Resolved from |
  | --- | --- |
  | `tsm:<reference>` | Tom Secrets Manager; the reference is in its own grammar, for example `tsm:[env:prod]providers/anthropic#apiKey` |
  | `os:<service>/<account>` | the secret store of the operating system: macOS Keychain, Windows Credential Manager, Linux Secret Service |
  | `env:<variable>` | an environment variable; allowed, marked as not secure |
  | `file:<path>` | a file; allowed, marked as not secure |

- **CS.8** The runtime resolves a reference at the moment the secret is
  needed; the secret is not written to any file of the {~~workspace.
  (S1 § 5.8)~>workspace.
  (<- S1 § 5.8)~~}
- **CS.9** The runtime is approved by the Tom Secrets Manager service once, as a program of its own. A setup guide describes the approval. The approval is given once for a runtime installation (`RT > RT-INSTALL`, CR.40). {~~(S1 § 5.8, CQ-16; S15; PQ-32)~>(<- S1 § 5.8; S15) (-> CQ-16, PQ-32)~~}
- **CS.10** When the vault is locked, the user is asked to unlock, and the run of the item that needs the secret waits as for any ask (`RT > RT-ASKS`, CP.21). {~~(S1 § 5.8, CQ-16; S15; PQ-24)~>(<- S1 § 5.8; S15) (-> CQ-16, PQ-24)~~}
- **CS.11** Besides provider keys, the team tokens of a user are kept by the runtime as secrets in the same way, named by secret references: one place per machine and user, for every host. A host shows the account (user id, e-mail address, server address) and signs out through the runtime; it supplies no credential through the host interface (`RT > RT-HOST`, CP.13). Webwork plans to keep the team token {~~in its own settings container (S25: 13_woneb6), which differs from this. (S1 § 5.8; `TAC`; `NFR`, N-17)~>in its own settings container, which differs from this (<- S25: 13_woneb6, planned). (<- S1 § 5.8) (-> N-17)~~}
- {++**CS.26** A command that a tool runs may name secret references. Only those are resolved, into the environment of that command alone; their values never enter a prompt, a tool result, a trail or a log, and the results of tools are scanned for them and masked. (<- S30: ww_e_gitruntime-5, planned)++}

CS.7 … CS.11 are stated for a runtime on the user's machine. Where the secrets of a runtime behind the web runtime service are kept, and how such a runtime is approved by Tom Secrets Manager, is open (`RT > RT-INSTALL`, CR.109; PQ-38).

### <!--[RT-PROTO]--> 7.10 The protocol

- **CP.1** A host outside the runtime's own process attaches over the runtime
  protocol: JSON-RPC 2.0 with length-prefixed messages over a TCP connection
  on the local machine; a remote runtime client attaches over WebSocket. {~~Inside VS
  Code the extension calls the runtime directly, with the same commands.~>Inside VS
  Code the new extension (D-73) calls the runtime directly, with the same commands, as long as it runs the runtime in its own process; whether it does is open (PQ-37), and until that is answered it does (`RT > RT-INSTALL`, CR.142).~~}
  For an application behind the web runtime service the wire is HTTP-based (`RT > RT-INSTALL`, CR.108); how the events (CP.4, CP.5) and the reverse requests (CP.10: the asks, opening a document, the host's tools) cross it is open (PQ-41).
  {~~(S1 § 6.1; S2 § 5, FO-5; PQ-28)~>(<- S1 § 6.1; S2 § 5) (-> FO-5, PQ-28)~~}
- **CP.2** A runtime started as an operating-system process of its own prints a ready line
  when it accepts connections, ends when its standard input is closed, and
  writes its log to standard error. An item whose execution was cut off, for example because that operating-system process died, is reported as interrupted (`RT > RT-QUEUE`, CR.69), and the user resends or skips it (CR.74). The Solution Blueprint settles what a host shows and can do when the runtime's operating-system process dies, and what of a half-done execution is kept. {~~(S2 § 3.2; S14; S17, the user guide § 4; S26: qavs_wwworkbench-3)~>(<- S2 § 3.2; S14; S17 user guide § 4; S26: qavs_wwworkbench-3)~~}
- **CP.3** The protocol has **commands** from the host to the runtime. They
  cover everything the engine does: the queue and timed requests, {~~with the commands on an item that is being executed (`RT > RT-QUEUE`, CR.74); processes~>with the commands on an item that is being executed (`RT > RT-QUEUE`, CR.74) and on a run's queue (CR.126), moving items between runs, sessions and places (CR.127) and the defaults of a run (CR.128); processes~~}
  (proceed, skip, back, decide, subprocesses, runs); sessions, with starting a session over (CR.18); todos;
  {~~memory; templates; profiles; chat variables; review rounds; coordination;
  calling a tool. (S1 § 6.1; S2 § 3.2; PQ-25)~>memory; templates; profiles; chat variables; the layers of the configuration (`RT > RT-CONFIG`); review rounds; coordination;
  calling a tool. (<- S1 § 6.1; S2 § 3.2; S17 llm_tools § 4.20, § 10; S17 user guide § 4 *Queue Editor*) (-> PQ-25)~~}
- **CP.36** Messaging and documents are among the commands, because an application has no connection to tac of its own (`TAC > TAC-PEOPLE`, CI.4) and reaches both through its runtime: the conversations by newest activity with their unread counts, the history of a conversation in pages, sending with a request id, the read state, muting, threads attached to a document or a review round, the members of the team, uploading and downloading a blob with the size limit known before sending, {~~extending and releasing the blobs of a review round, and the review request and its return. The list is what Webwork needs.~>extending and releasing the blobs of a review round, the review request and its return, the review requests addressed to the user, open or returned, across conversations, and, for a review request, per member whether tac accepted it for delivery (<- S25: 09_woneb2, 09_woneb3, planned), and the state of a review's rounds as it is read from the review folder (`TAC > TAC-REVIEW`, CV.18). The list is what Webwork needs; how a round's set of documents travels through tac is open (PQ-66).~~} Where the cache of conversations and the outbox of a user's messaging are kept, in the runtime or in the host, is open (PQ-52). {~~(PQ-30; PQ-26; S25: 13_woneb6 … 13_woneb10, planned)~>(<- S25: 13_woneb6 … 13_woneb10, planned; S29: FQ-9, FQ-11) (-> PQ-30, PQ-26)~~}
- **CP.37** One command answers what is being executed or is scheduled in a runtime: an item that is being executed, a timed request that waits. A host asks it before it ends, so it can tell the user what ending would stop. {~~Tom Forge needs it. (S26: qavs_wwworkbench-3, planned; S14 § 3)~>Tom Forge needs it. (<- S26: qavs_wwworkbench-3, planned; S14 § 3)~~}
- **CP.38** The commands also cover what a second host needs for features the extension has: {~~the completion of slash commands and skills, with the prompts for their arguments and their expansion; the assist actions on the questions of a document (asking through a document, proposing an answer, choices that move a process: CP.8); and continuing an item that stopped for lack of credit on another profile (`RT > RT-QUEUE`, CR.92). (S17; S26: qavs_ccparity_d_claudecode-4, qavs_ccparity_i_assist-1, qavs_ccparity_i_assist-2, qavs_dapieff-1)~>the data for completing a prompt, which are the slash commands and skills with the prompts for their arguments and their expansion, and the files of the quest after `@` (<- S17 user guide § 10 *Keyboard productivity*); the queued todos with their items; the models a profile can use (<- S23: progress 2026-11-24); the assists (`RT > RT-HOLDS`, CR.119) on the questions of a document and at a process decision, where Grill me and Explain run as assist prompts in a temporary session based on the position's session and the decision's choices are offered as buttons (<- S23: ccparity_i_assist-6, ccparity_i_assist-7); finishing a review round and the decision after a gate; asking through a document, proposing an answer and the choices that move a process (CP.8); continuing an item that stopped for lack of credit on another profile (`RT > RT-QUEUE`, CR.92); and the state of the provider SDKs and of the binaries a host shows (`RT > RT-INSTALL`, CR.43, CR.111; `RT > RT-TOOLS`, CT.10). (<- S17 user guide *Assist prompts*, *Processes*; S26: qavs_ccparity_d_claudecode-4, qavs_ccparity_i_assist-1, qavs_ccparity_i_assist-2, qavs_dapieff-1)~~}
- **CP.4** The protocol has **events** from the runtime to its runtime clients, one
  stream with subscriptions per connection. An event is one thing the
  runtime tells: a piece of streamed answer text or reasoning, a tool call
  and its result, a queue item changing state, the process position moving,
  an ask opened or settled (CP.20), a todo changing status, the usage of a round, a
  trail entry, the state of a run (`RT > RT-QUEUE`, CR.23), the progress of a subagent, an arriving message and a changed read state (CP.36), {~~the state of a quest whose checkout is missing on the machine (`RT > RT-LOCATIONS`, CR.100). (S1 § 6.1, CQ-6; S26: qavs_ccparity_d_claudecode-4)~>the state of a quest whose checkout is missing on the machine (`RT > RT-LOCATIONS`, CR.100), per todo whether and where it is queued (the run and the place in its queue), so a host can mark it live (<~ S17 user guide *Quest TODO Panel*), the runtimes of the machine with their runs and what they do (`RT > RT-MACHINE`, CR.36) (<- S23: vscimpb123), and a user notification dismissed (<- S23: vscimpb170). (<- S1 § 6.1; S26: qavs_ccparity_d_claudecode-4) (-> CQ-6)~~}
- **CP.39** The notifications are of two classes. Events on queues and todos: an item queued or deleted; a todo created, edited or changed in status. Events directed at the user: an ask opened, or closed with its answer or the reason; a message an agent sends the user, with its urgency; an answer handed to the user (`RT > RT-TOOLS`, CT.17); suggested processes; a process decision that waits; a todo that waits for decisions; a todo that is the user's to do; a run that is held, with the cause (a decision needed, an error, an item that needs attention, a blocked todo). Each event records the quest, the run and who caused it: an agent (with its transport, profile and session, and the item and todo it worked on), the user, or the runtime by itself. {~~The log is kept for the machine (`RT > RT-MACHINE`, CR.107). (S23: vscimpb124, vscimpb170)~>The log is kept for the machine (`RT > RT-MACHINE`, CR.107). (<- S23: vscimpb124, vscimpb170; S17 llm_tools § 4.18)~~}
- **CP.5** The events of a run are numbered. A runtime client reads "after number N,
  then follow". {~~That serves a runtime client that reconnects, a second one on the same run, and one that attaches late. (S1 § 6.1, CQ-6)~>That serves a runtime client that reconnects, a second one on the same run, and one that attaches late. (<- S1 § 6.1) (-> CQ-6)~~}
- **CP.6** The numbered events are kept in memory with a bound. A runtime client
  further behind than the bound reloads the run from the trail files, which
  {~~stay the durable record. (S1 § 6.1, CQ-6)~>stay the durable record. (<- S1 § 6.1) (-> CQ-6)~~}
- **CP.7** A conversation with a model is modelled as thread, turn and item: a session
  holds turns, a turn holds items (text, reasoning, tool call, ask, result),
  and an item has started, delta and completed events. A turn can be steered
  and interrupted. This shape is a proposal, not a decision: the product
  owner's direction is that the wire follows what the tools and the hosts
  need, and that the records it carries are worked out as object models
  from the schemas the workspace already has for the extension (CP.35). The
  interface specification settles the shape of a conversation on the wire.
  Starting a session over (`RT > RT-QUEUE`, CR.18) ends the thread and begins a new one in the same session.
{~~  (S1 § 6.1; PQ-21; PQ-25)~>  (<- S1 § 6.1) (-> PQ-21, PQ-25)~~}
- **CP.8** Every question the runtime puts to a person has one form, the
  **ask envelope**: a stable id, a kind (question, pick, document, tool
  approval, plan, decision, gate), the allowed responses, an optional schema
  of the response, and a deadline together with a safe default, both only when the one who asks declares them: an ask without them waits without a limit. An allowed response can be an action the runtime carries out itself when it is chosen: a process move, the start of a branch or of a subprocess, finishing a review round, the choices of a decision or of a gate. The runtime makes the move, not the agent; it acts on the run of the prompt that asked, not on the run a host shows; and every such response is checked when the ask is opened. {~~The ways an agent asks
  today stay as they are: a review outside a turn, the tool that asks single
  questions, and questions inside a document;~>The ways an agent asks
  today stay as they are: a review outside a turn; the tool that asks up to 15 questions, with choices at markers in them; the picker with a free answer beside its items; questions inside a document, with the buttons of the document ask; and the question tool, the tool approvals and the plan proposals of the Claude Agent SDK (<- S17 llm_tools § 4.18, § 10; S17 user guide *The user-input panel*; S23: ccparity_i_assist-1);~~} the envelope is the one record
  {~~the runtime sends a host for any of them. Like CP.7 it is a proposal that
  the interface specification settles, from the object models of CP.35.
  (S1 § 6.1; PQ-21; S23: vscimpb120, vscimpb85, vscimpb104, vscimpb89)~>the runtime sends a host for any of them. A tool approval follows the approval mode of the profile (`RT > RT-TRANSPORTS`, CR.139). Whether an ask, and an answer handed to the user (CT.17), can also carry question blocks and prompt buttons is open (PQ-65). Like CP.7 the envelope is a proposal that
  the interface specification settles, from the object models of CP.35.
  (<- S1 § 6.1; S23: vscimpb120, vscimpb85, vscimpb104, vscimpb89) (-> PQ-21)~~}
- **CP.9** An ask outlives the operating-system process that asked: a pending ask is a stored
  record, the turn can end, and the run resumes when the answer arrives.
  That is what lets an ask travel to another device or person.
  The open ask is stored with its queue item. When the turn that asked has ended, for example by a restart of the host, the item stays in execution, the ask is shown again with the same content, and the answer is delivered as the next prompt in the same session, quoting the question and the answer. Resend, skip or stop meanwhile close the restored ask (CP.42).
{~~  (S1 § 6.1, CQ-7; S23: vscimpb166)~>  (<- S1 § 6.1; S23: vscimpb166) (-> CQ-7)~~}
- **CP.10** The protocol has **reverse requests** from the runtime to the
  host: the asks, notifications, opening a file or a document, and the
  {~~host's tools. (S1 § 6.1, § 6.2)~>host's tools. (<- S1 § 6.1, § 6.2)~~}
- **CP.35** The link between a host and its runtime is an API with callbacks in both directions: the host calls the
  runtime, and a tool an agent calls in the runtime can call straight into
  the host to trigger what the host has to show or do, in the way the
  extension's script server lets Dart code call VS Code today. Under it is a
  wire protocol of JSON structures whose details follow what the tools need.
  The records it carries (quest, todo, run, queue item, session, question,
  {~~trail entry and the others) get object models, worked out from the schemas
  the workspace already has for the extension's files. (PQ-21; CP.10)~>trail entry and the others) get object models, worked out from the schemas
  the workspace already has for the extension's files. (-> PQ-21, CP.10)~~}
- **CP.11** The protocol is published as a JSON schema in the runtime's
  package. The runtime client SDKs generate their protocol layer from it and are
  {~~checked against it. Whether the web runtime client SDK is generated from the same schema is open (PQ-41). (S1 § 6.1; S2 § 5, FO-10)~>checked against it. Whether the web runtime client SDK is generated from the same schema is open (PQ-41). (<- S1 § 6.1; S2 § 5) (-> FO-10)~~}
- **CP.12** The commands are a superset of the methods scripts use today
  through the extension's JSON-RPC server, so what a script does there it can
  {~~do against a runtime. (S2 § 3.2; S1 § 2.1)~>do against a runtime. (<- S2 § 3.2; S1 § 2.1; S17 agent_sdk_scripting_mirror.md, llm_tools § 9, user guide § 6; S23: 00_aifmt-5, 00_aifmt-6)~~}
- {++**CP.45** The commands, events and reverse requests carry every feature of the old extension's views, so that the new extension feeds the same views from its runtime instead of from an engine of its own: what a view shows comes from commands and events, and what it does goes back as commands. Beyond what CP.3 … CP.12 and CP.35 … CP.39 name, that is: every command on items and runs of the queue editor (sending between the iterations of a walk, pausing after the current item, letting the next item go first, making a setting the default, choosing the members of a group); the restored ask (CP.9) and the stand-in ask from another runtime of the machine (CP.40), with the buttons of every ask kind; the flow of a migration, with the format stamps, the dry run and its report, and the pause of the other runtimes with what they are executing and its interrupt (`RT > RT-VERSIONS`, CP.29); the host's settings layer read and written through the runtime (CP.13). The screen inventory (`CLI > CLI-SCREENS`, CU.10) is the list it is checked against. (-> D-73, D-74) (<~ S17 user guide § 4, § 5; S23: vscimpb81, vscimpb142)++}

### <!--[RT-HOST]--> 7.11 The host interface

- **CP.13** The runtime reaches its host's world through one interface and
  {~~nothing else. It supplies (S1 § 6.2):~>nothing else. It supplies (<- S1 § 6.2; S23: ccparity_f_teamreview-1):~~}
  - locations (the workspace folder and the quest);
  - identity: the kind of host, the user, and the member id the user has in
    review rounds;
  - configuration (the host's settings layer);
  - the asks: a question, a pick, a document to work on, a tool approval,
    accepting a plan, a decision;
  - a notification to the user;
  - opening a file, and opening a document for reading or review;
  - the host's tools{~~.~>;~~}
  - {++the places of what the host carries for the runtime (the provider SDKs it installed, the Dart binaries), where the host and not the runtime installation provides them (<- S30: ww_b_workbench-4).++}

  {~~The host supplies no credential through it:~>The host supplies no transport through it (-> D-7), and no credential:~~} the team tokens of a user are the runtime's (`RT > RT-SECRETS`, CS.11).
{~~- **CP.14** In VS Code the interface is implemented in the extension's
  process; in every other host it is carried by the protocol's reverse
  requests. (S1 § 6.2)~>- **CP.14** In VS Code the new extension (D-73) implements the interface in its own process and the runtime calls it directly, as long as the runtime runs in that process (`RT > RT-INSTALL`, CR.142; open: PQ-37); in every other host it is carried by the protocol's reverse
  requests. (<- S1 § 6.2) (-> D-73)~~}
- **CP.15** A host refuses a call it has no concept for, with a reason, and
  the runtime leaves out what depends on it. Whether a host may instead answer a host tool by forwarding it to another host, {~~as Tom Forge plans towards a running VS Code window (S26: qavs_wwworkbench-5), is open (PQ-36). (S1 § 6.2; S2 § 3.1)~>as Tom Forge plans towards a running VS Code window (<- S26: qavs_wwworkbench-5, planned), is open (PQ-36). (<- S1 § 6.2; S2 § 3.1)~~}

### <!--[RT-TOOLS]--> 7.12 Tools

{~~- **CT.1** There are three sets of tools, by where they can live (S1 § 6.3;
  S2 § 5, FO-17):~>- **CT.1** There are four sets of tools, by where they can live (<- S1 § 6.3; S2 § 5; S17 llm_tools § 4, § 4.4 … § 4.10, § 4.14, § 4.15, § 4.20, § 4.23a; S23: vsctsa1 … vsctsa22, ccparity_i_assist-2) (-> FO-17):~~}

  | Set | Carried out by | Holds | Offered to |
  | --- | --- | --- | --- |
  | **Runtime tools on `_ai`** | the runtime | todos, queue, processes, sessions, memory, chat variables, review, coordination, messaging, asking the user (CP.8), handing the user an answer without waiting (CT.17), declaring a wait (`RT > RT-QUEUE`, CR.85), {~~the specification tools and the runner of the TomSpecs binary | every transport~>the specification tools, also those of code generation (Phase 4 of TomSpecs) with their guides, the question tools on plain Markdown documents (list, answer, propose an answer, insert a question), and the runner of the TomSpecs binary | every transport~~}, and through the runtime's MCP server also other runtimes |
  | **Runtime tools on files** | the runtime | {~~reading, editing and finding files, running commands, the web, git~>reading, editing and finding files, running commands (also as a stream that is read and stopped), the web, git~~} | the model transports only; never through the runtime's MCP server |
  | {++**Runtime tools on the workspace**++} | {++the runtime++} | {++the guidelines and the pattern prompts, the lists of the projects and the repositories, the issue and test trackers over a provider++} | {++every transport; through the runtime's MCP server only those that read++} |
  | **Host tools** | the host | what only that host can do: {~~in VS Code the editor, language services, commands, the document browser, notebooks;~>in VS Code the editor, language services, code actions and renaming, commands, tasks, debug configurations, notebooks, the open editors, the problems, the output channels and the document browser's panels;~~} in Webwork its document tools; in Tom Forge its equivalents | the transports of the run or prompt they are registered for |

- **CT.2** The tools keep the names they have today, so {~~every prompt that
  names a tool keeps working. (S1 § 6.3; S4, note e)~>every prompt that
  names a tool keeps working. (<- S1 § 6.3; S4 note e)~~}
- **CT.3** An agent transport that brings file, command and web tools of its
  own uses its own; the runtime's tools of the same purpose are hidden from
  {~~it. (S2 § 3.3, FO-17)~>it. (<- S2 § 3.3) (-> FO-17)~~}
- **CT.4** A host registers its tools with its runtime: for each a name, a
  schema and a description, for a run or for a single prompt (the tools of
  {~~the part of the application a prompt is sent from). (S1 § 6.3, § 3.2; S3,
  WR-7)~>the part of the application a prompt is sent from). (<- S1 § 6.3, § 3.2; S3 WR-7)~~}
- **CT.5** The runtime offers a registered host tool to the transport and
  calls the host back over the protocol when the agent calls it. The host
  carries it out and returns the result; an error or a refusal comes back as
  a {~~tool error. (S1 § 6.3, § 3.2)~>tool error. (<- S1 § 6.3, § 3.2)~~}
- **CT.6** The runtime signals the boundaries of a prompt to the host: when a
  prompt starts and when it ends. A host uses them to group what a prompt
  wrote (for undo) and to {~~offer the preview of CR.17. (S1 § 6.3, § 3.2)~>offer the preview of CR.17. (<- S1 § 6.3, § 3.2)~~}
{~~- **CT.7** The trail shows, for each prompt, the set of tools it was given.
  (S1 § 3.2)~>- **CT.7** The trail shows, for each prompt, the set of tools it was given, and each tool call names the execution that made it (`RT > RT-TRANSPORTS`, CR.138).
  (<- S1 § 3.2)~~}
{~~- **CT.8** Inside VS Code the extension may offer its tools to the runtime as
  one MCP server instead of single registered tools. (S1 § 6.3; S2 § 5,
  FO-6)~>- **CT.8** Inside VS Code the new extension may offer its tools to the runtime as
  one MCP server instead of single registered tools. (<- S1 § 6.3; S2 § 5) (-> FO-6)~~}
- **CT.9** The role a prompt is executed in decides which tools it gets: a role type
  {~~names its tools. A todo can name the role it is executed with (`RT > RT-QUEUE`, CR.95). (S1 § 6.3, § 3.1)~>names its tools, as a selection per group of tools or the profile's default, with tools that are always on. A profile enables tools as well, and the runtime's MCP server has a selection of its own. A todo can name the role it is executed with (`RT > RT-QUEUE`, CR.95). Planned: the role types reviewer, planner, coordinator and specification author, every role naming its type (<- S23: tooloptimize10 … tooloptimize15, planned). (<- S1 § 6.3, § 3.1; S17 user guide *Tools by role*, llm_tools § 9; S23: gsel28)~~}
- **CT.10** The tool set grows with the products that run in the runtime.
  TomSpecs adds tools for keeping linked sections of specification documents
  in step and switches for rendering a document for reading; its documents
  are worked on through one bundled binary, and a missing binary is reported
  as such. A tool that needs a binary (the build tool, the TomSpecs binary) looks for a configured one, then for a bundled one, and answers that the binary is missing for this platform, with help, when there is none. The runtime's list of the projects of a workspace, which the scopes of todos and prompts and the project-list tool use, comes from the build tool's listing, {~~with a built-in port of the same rules as the fallback. (S1 § 3.5; S23: vscimpb83, vscimpb84, vscimpb147, vscimpb103)~>with a built-in port of the same rules as the fallback; planned: that listing also knows Scala and C / C++ projects built with Meson, Bazel or Ceedling (<- S23: vscimpb169, planned). Planned: specialised tools for searching code, a file's outline and its sections, replacing in files, finding todos, committing paths, running the checks and a git overview, which the guidelines prefer over the shell (<- S23: tooloptimize2 … tooloptimize9, tooloptimize16, planned); marked edits of typed values and headlines in specification documents (<- S23: vscimpb189, planned); the impact walk and the requirements fill tool of TomSpecs (<- S23: vscimpb178, specfrem1, planned). (<- S1 § 3.5; S17 llm_tools § 4.23a; S23: vscimpb83, vscimpb84, vscimpb147, vscimpb103, gsel13, gsel14, vsc_nodart, 05b_rdv3, 05b_sau1, 05b_sau2)~~}
- **CT.17** A tool hands the user an answer without waiting for anything: a title, the answer as Markdown and the user's question quoted, with suggested todos (complete records, written when the user clicks, filed as by the agent) and suggested prompts (only copied, never queued). The call returns at once, and the turn goes on. The answers are kept out of the trail and shown with their read state across quests. {~~Planned: they are kept in the journal of asks and answers, per host and quest (`RT > RT-HOLDS`, CR.55). (S23: vscimpb171; 01_aifmt-4, planned; S22 § 2.2)~>Planned: they are kept in the journal of asks and answers, per host and quest (`RT > RT-HOLDS`, CR.55); whether that record is one file per host or one file per answer is open (PQ-65). (<- S23: vscimpb171; 01_aifmt-4, planned; S22 § 2.2)~~}
- {++**CT.19** The result of every tool call of a session is stored under a replay key and kept for a set number of days and up to a set number per session. Agents list past tool calls, search their results and read a result in pages through tools. (<- S17 llm_tools; S17 user guide § 9 *Retention*; S23: dapieff1)++}
- {++**CT.20** A tool that writes a document refuses when the file has changed since it was read, or when a host has it open with changes not yet saved. (<- S17 user guide *Editing is guarded*)++}
- {++**CT.21** The tool definitions sent to a model are a core set given in full; the long description of a tool is read through a tool of its own, and a test keeps every description within a length limit. (<- S17 llm_tools § 10; S23: dapieff6)++}

### <!--[RT-MCP]--> 7.13 The MCP servers

- **CT.11** The runtime has an MCP server that offers the runtime tools on
  `_ai`. It reads and writes only `_ai` state and offers no access to files
  or an editor, {~~so it is safe to offer to other machines. Host tools are not reachable through it (CT.1; `NFR`, N-18). (S1 § 6.4; S4,
  first notes)~>so it is safe to offer to other machines. Host tools are not reachable through it (CT.1; `NFR`, N-18). (<- S1 § 6.4; S4 first notes)~~}{++ Whether a second endpoint for the local machine only offers the file and host tools beside it is open (CT.12; PQ-50).++}
{~~- **CT.12** The MCP server asks for a bearer token. Who issues the token, how a team runtime obtains it and what the server checks is open (PQ-50).~>- **CT.12** The MCP server asks for a bearer token. Without a valid token it serves only the tools that read, and only to the local machine and the VPN (<- S17 mcp_server.md § 3). Who issues the token, how a team runtime obtains it and what the server checks is open (PQ-50), and so is whether the runtime keeps, for the local machine only, a second endpoint with the file and host tools that the old extension's MCP server serves to the holders of its key today (<- S17 mcp_server.md § 1 … § 4).~~} The Solution Blueprint settles how several runtimes on one machine get the ports of their MCP servers, and what the server's card says when two hosts serve one workspace, {~~which Tom Forge needs (S26: qavs_none-3). (S1 § 6.4, § 3.6)~>which Tom Forge needs (<- S26: qavs_none-3, planned). (<- S1 § 6.4, § 3.6)~~}
{~~- **CT.13** A runtime can publish its MCP server as an endpoint through tac,
  so the other team runtimes find it and call its tools.
  (S1 § 6.4; `TAC`)~>- **CT.13** A runtime can publish its MCP server as an endpoint through tac,
  so the other team runtimes find it and call its tools.
  (<- S1 § 6.4)~~}
- **CT.14** Inside a runtime, the tools of the local runtime, of the host and
  of a remote runtime are all presented to the agent as tools; routing a
  call to the right place is part of {~~carrying the tool out. (S4, note e;
  S2 § 3.3)~>carrying the tool out. (<- S4 note e; S2 § 3.3)~~}
- {++**CT.18** A tool of another runtime keeps its name. The agent chooses the runtime by an argument naming the target quest (and, where a quest has several team runtimes, the user), not by a different tool name. A call to another runtime is checked there by the bearer token of CT.12. (<- S20 § 12; S4 note e)++}
- **CT.15** The runtime names the revision of MCP it speaks, and keeps what
  differs between revisions (long-running tasks) {~~behind an adapter.
  (S1 § 6.4, § 15.1)~>behind an adapter.
  (<- S1 § 6.4, § 15.1)~~}
{~~- **CT.16** The runtime is also an MCP client of external MCP servers, as the
  engine is today. (S1 § 6.4, § 3.1)~>- **CT.16** The runtime is also an MCP client of external MCP servers, as the
  engine is today, on every transport: the servers of the workspace's configuration and of the agent program's own; a project's servers are approved before their first use, and their tools that only read do not ask. (<- S1 § 6.4, § 3.1; S23: ccparity_d_claudecode-7)~~}

### <!--[RT-ASKS]--> 7.14 Routing and escalation of asks

An ask must not get lost: it is escalated, and it can be seen for as long as it is open. While it is open, its run waits (CP.21) and the other runs go on; the user can answer it, or skip or resend the item that waits {~~(`RT > RT-QUEUE`, CR.74)
(S1 § 6.6, CQ-7; PQ-24).~>(`RT > RT-QUEUE`, CR.74)
(<- S1 § 6.6) (-> CQ-7, PQ-24).~~}

- **CP.16** Every quest has a quest owner. The Solution Blueprint settles where the quest owner is recorded and {~~who may change it. (S1 § 6.6, CQ-7)~>who may change it. (<- S1 § 6.6) (-> CQ-7)~~}
- **CP.17** An ask has a chain of people: the person the process or the todo
  names, if any; then the owner of the quest the ask belongs to; then the
  owner of the quest whose todo triggered it; then the owners of the team.
{~~  (S1 § 6.6, CQ-7, DQ-3)
- **CP.18**~>  (<- S1 § 6.6) (-> CQ-7, DQ-3)
- **CP.18**~~} For each person in the chain: the ask is shown on the host that
  asked; after 10 minutes without an active runtime client there it goes through tac
  to that person's other devices; after a set time without an answer it
  moves on to the next person, and the previous one keeps seeing it. The set
  time is 4 working hours unless the team or the ask says otherwise.
  The Solution Blueprint settles what working hours are, by what a process or a todo names a person, and what the chain is when the quest owner leaves the team or {~~the quest's team is a personal team.
  (S1 § 6.6, DQ-3)~>the quest's team is a personal team.
  (<- S1 § 6.6) (-> DQ-3)~~}
- **CP.40** An open ask is offered to every runtime client attached to the runtime, and to the other runtimes of the machine through the machine-wide state (`RT > RT-MACHINE`, CR.36). The first answer settles it; the answer is the same wherever it was given, and {~~the ask closes everywhere it is shown. (S23: vscimpb173, vscimpb170)~>the ask closes everywhere it is shown. (<- S23: vscimpb173, vscimpb170)~~}
- **CP.19** An ask goes to another person only when the process or the todo
  {~~names that person, or by the chain. (S1 § 6.6, CQ-7)~>names that person, or by the chain. (<- S1 § 6.6) (-> CQ-7)~~}
- **CP.20** At the end of the chain the ask stays open and is marked
  unanswered. Nothing is decided automatically, unless the ask declared a
  default; then the default is taken and recorded as taken by default.
  An ask is **settled** when it is answered, when it is closed unanswered because the execution that asked was ended (CP.42), or when its declared default is taken. A run that waits for an ask nobody answers can so be given up: the user skips or resends the item that waits, or stops it (`RT > RT-QUEUE`, CR.74).
{~~  (S1 § 6.6, DQ-3; S23: vscimpb55, vscimpb78)~>  (<- S1 § 6.6; S23: vscimpb55, vscimpb78) (-> DQ-3)~~}
- **CP.21** While an ask of a run is open, the run that asked waits: nothing further is sent from its queue until the ask is settled (CP.20). The other runs go on. The item that asked stays in execution and is not moved to another state. Nothing else of its run is sent meanwhile: not the next item, not the next todo of a walk, not its follow-ups. The settings of the run are untouched, and the run goes on by itself when the ask is settled, unlike a run that is held (`RT > RT-QUEUE`, CR.23). {~~Whether the execution keeps its leases while its run waits, and whether a chat send in another session of that run still goes out, is open (PQ-39). (S1 § 6.6, DQ-3; PQ-24; S23: vscimpb46, vscimpb55, vscimpb82, vscimpb123)~>A chat send in another session of the waiting run still goes out: chat sends stand outside the lanes and are held back only while their own session carries an item (`RT > RT-QUEUE`, CR.15, CR.67) (-> D-74) (<- S23: vscimpb132, vscimpb135). Whether the execution keeps its leases while its run waits is open (PQ-39). (<- S1 § 6.6; S23: vscimpb46, vscimpb55, vscimpb82, vscimpb123) (-> DQ-3, PQ-24)~~}

> **❓ PQ-39 (2026-11-25T19:47+01:00) — the leases of an execution that waits for an ask:** While a run waits for the answer to an ask, does the execution that asked keep the leases it holds on repositories, or are they released or weakened after a while?
>
> **Context:** The terms: a **run** is a queue in a quest that executes todos and prompts one after the other; an **execution** is the work on one item of that queue; an **ask** is a question the runtime puts to a person (a question, a pick, a tool approval, a plan, a decision); a **lease** is the right that tac, the coordination service, gives an execution to work on a resource (a repository, or a part of one) for a time; **strict mode** is the mode of a repository without a working tree per execution, where only one execution may write at a time.
>
> `RT > RT-ASKS`, CP.21: "While an ask of a run is open, the run that asked waits: nothing further is sent from its queue until the ask is settled (CP.20). The other runs go on. The item that asked stays in execution and is not moved to another state." Your answer to PQ-24 was (b): "The run that asked waits as a whole: nothing further is sent from its queue until the answer arrives; only the other runs go on." The other half of the earlier question — whether a chat send in another session of the waiting run still goes out — is settled by your instruction that the extension's features, built and planned, are the first version's (D-74): it goes out, as the extension does it today (vscode_extension `vscimpb132`, `vscimpb135`), and CP.21, CR.15 and CR.67 say so. What remains open are the leases:
>
> - `PAR > PAR-APPROACH`, CW.5: "In **strict mode** the execution holds an exclusive lease, which keeps every other claim on an overlapping resource out, for as long as the todo is executed."
> - `TAC > TAC-COORD`, CA.13: "A lease is renewed while its execution works. Not renewed for 60 minutes, it is **stale**."
> - `PAR > PAR-APPROACH`, CW.4: "When a lease it needs is held for another item, the item waits and says who holds it."
> - `RT > RT-ASKS`, CP.18 gives each person in the chain of an ask 4 working hours before it moves on; CP.17 allows up to four people in the chain; by CP.20 an ask without a declared default stays open when nobody answers.
>
> An item that asked stays in execution, so its lease stays and is renewed. A repository in strict mode can so be closed to every other run of every member of the team for two working days or longer, by a run that only waits for a person. The extension's own plan for leases (vscode_extension `caf_04b`, planned, in its collaboration plan S28) shows the holder to whoever waits and offers **Proceed anyway**, which lets the waiting item go on despite the held lease; whether that plan is carried into the runtime at all is asked separately (PQ-63).
>
> **Why I ask:** Without a rule, the first unanswered question in a strict-mode repository stops everybody else who needs that repository. Releasing the lease has a price: when the answer arrives, the execution has to claim again, may find the resource taken, and goes on in files another execution has changed meanwhile. The answer changes CW.4, CW.5, CA.13 and CP.21, and what the supervision application shows for a waiting run.
>
> - (a) Leases are kept for as long as the execution lasts, and nothing more is said: CW.5 and CA.13 stand. A long ask in a strict-mode repository blocks the others until somebody skips or stops the waiting item.
> - **(b)** Leases are kept, and the lease shows the open ask with its age, so whoever waits for the repository sees why it is held and by whose open question; the owner of the waiting run can skip or stop the item to free it. CW.4 and CP.21 would say so.
> - (c) Leases are released when the ask has been open for a set time (for example 30 minutes) and claimed again when the answer arrives; when the claim then fails, the item waits for the lease like any other (CW.4). The Solution Blueprint has to say what an execution does that comes back to changed files.
> - (d) As (c), but the lease is downgraded, not released: an exclusive lease becomes a shared one while the run waits, so others may work there and see who was working, and it is raised again with the answer.
>
> *Recommendation:* (b) — it keeps the execution's files as they were, it is what the extension does with a held lease today, and the shown age gives the people waiting what they need to ask the owner; releasing leases under a half-done execution (c, d) adds a failure case the first version does not need as long as the owner can skip or stop the waiting item.
>
> *Assumption until answered:* leases are held "for as long as the todo is executed" (CW.5); CP.21 names the leases as open.
>
> **Answer:**

- **CP.41** A run has at most one open ask at a time, whatever its kind: a question, a pick, an ask in a document, the proposal of a plan. A second ask from the same run while the first is open is refused, not queued. Asks of different runs are open at the same time and are answered in any order. {~~A tool approval belongs to the execution whose tool call waits. (S23: vscimpb81; PQ-24)~>A tool approval belongs to the execution whose tool call waits. (<- S23: vscimpb81) (-> PQ-24)~~}
- **CP.42** An ask belongs to the execution of its item. When that execution is ended (stop, resend, skip, a hard interrupt), every wait it is blocked in ends at once, on every transport: a question and a pick close unanswered, an approval counts as denied, a plan as not accepted, and the tool answers that the prompt was ended. An answer given after that is not delivered, and the ask closes for everyone it was shown to {~~or escalated to. (S23: vscimpb78, vscimpb33)~>or escalated to. (<- S23: vscimpb78, vscimpb33)~~}
- **CP.43** Waiting for time or for an event outside is not an ask. An agent declares such a wait (`RT > RT-QUEUE`, CR.85); nobody is asked and nothing is escalated. Its run waits by the rule of CP.21 and reports {~~a state of its own, "waiting for an event" (CR.23). (S23: vscimpb82)~>a state of its own, "waiting for an event" (CR.23). (<- S23: vscimpb82)~~}
- **CP.44** An answer handed to the user without waiting (`RT > RT-TOOLS`, CT.17) is not an ask either: nothing is open afterwards, {~~and no run waits for it. (S23: vscimpb171)~>and no run waits for it. (<- S23: vscimpb171)~~}
- **CP.22** Whoever has an ask can forward it to any member of the team, with
  a note. The chain continues from that person, and the answer returns to
  {~~the run that asked. (S1 § 6.6, CQ-7, DQ-3)~>the run that asked. (<- S1 § 6.6) (-> CQ-7, DQ-3)~~}
- **CP.23** Every open ask of a team can be seen with its age, who has it,
  where it is in its chain and which run waits for it. {~~Planned: every ask and its answer is recorded in the journal of asks and answers (`RT > RT-HOLDS`, CR.55). (S1 § 6.6, CQ-7; S22 § 2.2 QJ-1)~>Planned: every ask and its answer is recorded in the journal of asks and answers (`RT > RT-HOLDS`, CR.55); whether that record is one file per host or one file per ask and per answer is open (PQ-65). (<- S1 § 6.6; S22 § 2.2 QJ-1) (-> CQ-7)~~}

> **❓ PQ-65 (2026-11-25T19:40+01:00) — the store of asks and answers, and asks and answers with question blocks and prompts:** How does the runtime keep the record of asks and answers — one file per host, or one file per ask and per answer — and can an ask or an answer carry question blocks and prompt buttons?
>
> **Context:** An **ask** is a question a run puts to the user (a question, a pick, a tool approval, a plan, a decision, a document to review; `RT > RT-ASKS`, CP.8); an **answer handed to the user** is a reply an agent gives without being asked (`tomAi_answerUser`). `RT > RT-HOLDS`, CR.55: "Planned: the journal of asks and answers is a store of the runtime, per host and quest, in time order: every ask put to the user with its answer and the run it came from, every answer handed to the user without an ask, and every message written to a waiting turn (CR.72). … Where the per-host files lie is open (PQ-53)." Its source is the extension's plan `01_aifmt-4` and the format standard S22 (`qa.<host>.<quest>.md`, one file per host). The extension has since planned something else (vscode_extension todos of 2026-11-25, decisions open):
>
> 1. **One file per entry** (`vscimpb183`): every ask and every answer is a file of its own in the quest's folder `question_and_answers/`.
> 2. **Answers with question blocks** (`vscimpb184`): an answer handed to the user can carry question blocks with choice buttons, a text field, *Send prompt* through an answer-tool template, and *Give me more details*.
> 3. **Asks with prompt buttons** (`vscimpb185`): an ask can carry extra prompt buttons beside *Send answers* and *Give me more details*.
>
> The baseline (D-74) carries this across machines and members of a team: a file per host never conflicts in a merge, but a team member answering an ask from another machine writes into which host's file; a file per entry never conflicts either and can be written by whoever answers.
>
> **Why I ask:** The two plans contradict each other and CR.55; the store is a format of the runtime (CR.1), so it has to be one. Whether question blocks and prompt buttons are part of the ask envelope (CP.8) decides what every host's ask component (`CLI > CLI-UI`) must render and what the protocol carries.
>
> - (a) One file per host, as CR.55 says; asks and answers carry no question blocks or prompt buttons in the first version.
> - **(b)** One file per ask and per answer (`question_and_answers/`), written by whoever puts or answers it, so members and machines never write the same file; the views read the folder. An ask and an answer handed to the user can both carry question blocks and prompts; choosing one queues its prompt into the run that asked or answered. CR.55 is rewritten so, and CP.8's envelope gets the question blocks and prompts.
> - (c) One file per ask and per answer as in (b), without question blocks and prompt buttons in the first version.
>
> *Recommendation:* (b) — it is the extension's newest plan, it removes the question of whose file a team member writes into, and the question blocks give a team member on a phone the same answer form as at the desk.
>
> *Assumption until answered:* CR.55 keeps its text (per host and quest); CP.8 names neither question blocks nor prompt buttons.
>
> **Answer:**

Asking a person outside the team is deferred (`SCO > SCO-LATER`, L-3).

{++Telegram is not a channel of the runtime (`SCO > SCO-LATER`, L-9): an ask reaches a person away from the host through tac (CP.18). The old extension keeps its Telegram bot per quest, through which asks are answered and todo reminders are sent today; whether the new extension keeps it is open (PQ-62). (-> D-6) (<- S17 telegram_integration.md § 2, § 7; S23: vscimpb25, vscimpb26)++}

What of CP.17 … CP.23 a team on the GitHub backend has is open (PQ-47), and so is how a phone or tablet whose application is not running learns of an ask (PQ-49).

### <!--[RT-VERSIONS]--> 7.15 Versions and compatibility

A runtime update often comes with a new format of the workspace and quest
{~~files, and an older runtime does not work on newer files (S1 § 6.7, DQ-9).~>files, and an older runtime does not work on newer files (<- S1 § 6.7) (-> DQ-9).~~}

- **CP.24** On connect, three versions are checked: the protocol's, the
  runtime's, and {~~the format of the workspace files. (S1 § 6.7, DQ-9)~>the format of the workspace files. (<- S1 § 6.7) (-> DQ-9)~~}
- **CP.25** An older runtime client keeps working with a newer runtime. It does not
  get the new features, and nothing it does breaks. Within a major version
  the protocol only grows: commands and fields are added, none changed or
  {~~removed. (S1 § 6.7, DQ-9)~>removed. (<- S1 § 6.7) (-> DQ-9)~~}
- **CP.26** Unknown fields pass through. A runtime client that reads a record,
  changes a field and writes the record back returns every field it did not
  {~~know unchanged. Every runtime client SDK does this. (S1 § 6.7, DQ-9)~>know unchanged. Every runtime client SDK does this. (<- S1 § 6.7) (-> DQ-9)~~}
- **CP.27** A runtime client SDK tells its host through callbacks when the
  runtime was updated, when the workspace files were migrated to a format
  the host's runtime cannot work on, and when the host is too old for the
  {~~runtime it found. The host decides what to show and do. (S1 § 6.7, DQ-9)~>runtime it found. The host decides what to show and do. (<- S1 § 6.7; S17 user guide *Which build a window runs*) (-> DQ-9)~~}
- **CP.28** A runtime that finds workspace files in a newer format than it
  knows stops working on them, says that they were upgraded from somewhere
  else, and {~~offers the update of the runtime. (S1 § 6.7, DQ-9; PQ-6)~>offers the update of the runtime. (<- S1 § 6.7) (-> DQ-9, PQ-6)~~}
- **CP.29** A migration of the workspace files runs once per machine, under
  a file lock on that machine; the other runtimes on the machine pause while it runs. Once one runtime of a machine has migrated, the other runtimes of that machine pause every run, refuse new sends and list what is still being executed, each with an interrupt, until they are restarted. A runtime that finds files in an older or a newer format does not start its normal parts and says why, instead of working on them (CP.28, CP.33). The migration runs from the runtime installation, and the merge drivers of the `_ai` files come with it and are checked on an upgrade. {~~When a migration runs, and whether the user confirms it first, is open (PQ-40). (S1 § 6.7,
  § 3.1; S23: vscimpb142, vscimpb142a … vscimpb142d; 01_aifmt-5, planned)~>When a migration runs, whether the user confirms it first, and which format version the old extension and the runtime use while both work on one machine (D-73; `RT > RT-HOLDS`, CR.112) is open (PQ-40). (<- S1 § 6.7, § 3.1; S23: vscimpb142, vscimpb142a … vscimpb142d; 01_aifmt-5, planned)~~}

> **❓ PQ-40 (2026-11-25T20:48+01:00) — the `_ai` format while the old extension and the runtime both work, and when a migration runs:** Which format version of the `_ai` files do the old extension and the runtime use while both work on the same machines, and does a migration to a new format run by itself or only after the user confirmed it?
>
> **Context:** The **workspace files** are the files of the `_ai` folder (todos, queues, process state, sessions, trails), which every runtime of a team reads and writes and which are shared through git. Their **format** has a version number, kept in `_ai/format-version.yaml`; a program works only on the format version it was built for. A **migration** rewrites the files from one version to the next. The files are in format version 10 since 2026-11-23; version 11 is decided (al_the_bear's `ai_format_migration.md`, S22 § 3.6) and not built; the extension's todo `01_aifmt-5` (planned) builds it.
>
> Your instruction for this round (D-73): a copy of the extension in `tom_ai/ai_build` — **the new extension** — is rewired to the runtime until every feature works as before, while **the old extension** is left as it is; when the new one is stable it takes the old one's place. During that **parallel period** the old extension keeps its own engine, and on one machine its engine and the runtime work on one `_ai` folder (`RT > RT-HOLDS`, CR.112). The Project Idea says:
>
> - `SCO > SCO-IN`: the runtime's core is "The `_ai` formats and stores in format version 11".
> - `RT > RT-VERSIONS`, CP.28: "A runtime that finds workspace files in a newer format than it knows stops working on them, says that they were upgraded from somewhere else, and offers the update of the runtime."
> - CP.29: "A migration of the workspace files runs once per machine, under a file lock on that machine; the other runtimes on the machine pause while it runs."
> - CP.32: "A runtime is updated only after the user was asked."
> - CP.33: "… Files are never migrated without the user having confirmed it." (Your answer to PQ-6.)
> - `NFR > NFR-TOPO > NFR-TOPO-FLOWS`, F12: "A migration of the workspace files runs only when the user confirmed it …"
>
> Two facts pull against this. First, the plan for version 11 (S22 § 3.6, and `01_aifmt-5`): "on each host's first window after the update and recorded in `_ai/format-version.yaml`", with a dry run listing the moves and no confirmation by the user; version 11 also renames files that belong to one machine (its sessions and its journal), so the step has to run on every machine while the stamp is one shared file. Second, the parallel period: the plan that D-73 replaces (moving the engine out of the running extension stage by stage, S18) had the rule "the development build must not raise the `_ai` format while the stable build uses the same `_ai`; test windows work on a sandbox `_ai`" (S18 § 3, rule 1 and 2); with two engines on one folder, a format change made by either stops the other (CP.28).
>
> **Why I ask:** Who decides a migration decides whether updating one machine silently makes the files unreadable to other machines and members; and during the parallel period, a format change in either the old extension or the runtime stops the other one on every machine that shares the folder. CP.28, CP.29, CP.32, CP.33, F12, CR.112 and the risks R-13 and R-31 read differently by the answer.
>
> - (a) The old extension reaches format version 11 before the copy is taken, by itself as its plan says; from then on the runtime writes version 11 and the Project Idea's rule (the user confirms) holds for every later migration. During the parallel period the format does not change: a change that becomes necessary waits for the swap, or is made in the old extension first and then in the runtime. The new extension's test windows work on sandbox quests until both write the same files.
> - **(b)** As (a) for the parallel period — one format, version 11, reached by the old extension before the copy, no format change until the swap, sandbox quests for the new extension's tests — and for migrations the Project Idea's rule holds from now on, version 11 included: a migration of shared files runs only after the user confirmed it, once, on the first machine; the steps that touch only one machine's own files run by themselves on each machine when its program first finds them in the old form, and are recorded on that machine. CP.29 and CP.33 would say so; F12 stands; the plan for version 11 is changed to ask.
> - (c) The runtime reads and writes two format versions during the parallel period, so the old extension can stay on version 10 or 11 while the runtime moves on; migrations run by themselves on a host's first start, as the plan says. CP.33 loses "Files are never migrated without the user having confirmed it"; F12 is rewritten; CR.1 (one implementation of one format) gets an exception.
> - (d) The new extension and its runtime work only on a separate `_ai` (a second clone) until the swap, so the two engines never share files; migrations as in (b).
>
> *Recommendation:* (b) — one format for both engines keeps the old extension the reference the new one is checked against; the confirmation protects the other machines and members from files their program cannot read, at the cost of one click; splitting shared steps from per-machine steps removes the question of how one shared stamp can record what each machine did. (c) adds a second format the Project Idea rules out, and (d) cannot test "distributed and with a team" on real quests.
>
> *Assumption until answered:* CP.29, CP.32, CP.33 and F12 keep their text; CP.29 names the format during the parallel period and the time of a migration as open; CR.112 says the same.
>
> **Answer:**

- **CP.30** The aim is that the protocol and the formats become very stable
  {~~after a while. (S1 § 6.7, DQ-9)~>after a while. (<- S1 § 6.7) (-> DQ-9)~~}
- **CP.31** A host that finds a runtime installation too new for it switches
  off every feature that would use the runtime, or refuses to start, and asks
  {~~the user to update the application. (PQ-6)~>the user to update the application. (-> PQ-6)~~}
- **CP.32** A runtime is updated only after the user was asked. The question
  is put actively when the runtime meets workspace files it cannot work on
  {~~because they were upgraded elsewhere. (PQ-6)~>because they were upgraded elsewhere. (-> PQ-6)~~}
- **CP.33** A runtime that finds workspace files in an older format than it
  works on offers two ways: to migrate the files to its format, or to go back
  to an older version of the runtime that works on the old format, if there
  is one the application is compatible with. When there is none, it says so
  and offers only the migration. Files are never migrated without the user
  {~~having confirmed it. (PQ-6)~>having confirmed it. (-> PQ-6)~~}
- **CP.34** The usual course is that the runtime and the workspace files are
  updated together, when the first host has been updated. The other hosts
  keep working because a host is compatible with several versions of the
  runtime, through the runtime client SDK and the protocol's backward
  {~~compatibility (CP.25). (PQ-6)~>compatibility (CP.25). (-> PQ-6)~~}

CP.24 … CP.27 are stated for a host that carries a runtime. What of them holds for an application behind the web runtime service, which installs no runtime, is open (PQ-41).

### <!--[RT-PROVIDERS]--> 7.16 Model providers

{~~- **CS.12** A provider is reached in one of three ways (S7; S1 § 5.4):~>- **CS.12** A provider is reached in one of three ways (<- S7; S1 § 5.4; S30: xxcopilotsdk1, xxopenai1, xxgoogle1, xxmeta1, xxmistral1, xxopenrouter1, xxotherproviders1):~~}

  | Way in | How | Providers |
  | --- | --- | --- |
  | **The provider's agent SDK or command line** | an agent transport of its own {~~| GitHub Copilot (its SDK), OpenAI (the Codex SDK), Google (the Gemini command line), Mistral (its coding agent) |~>| GitHub Copilot (its SDK), OpenAI (the Codex SDK), Google (the Gemini command line, run without a window), Mistral (its coding agent Vibe) |~~}
  | **An endpoint compatible with Anthropic's API** | the direct transport and the Claude Agent SDK transport with a base address {~~| DeepSeek, OpenRouter, Moonshot, Zhipu, MiniMax; Claude on Amazon Bedrock and Google Vertex AI |~>| DeepSeek, OpenRouter, Moonshot (Kimi), Zhipu (GLM); Claude on Amazon Bedrock and Google Vertex AI as an Anthropic configuration with a cloud provider, its credentials from the cloud's command line instead of a base address |~~}
  | **An endpoint compatible with OpenAI's API** | the client for local models grown into a provider client {~~| xAI, Meta's Llama API, DeepSeek, Baidu, Mistral, OpenRouter, Alibaba, Groq, Together, Fireworks, Cerebras, Azure OpenAI |~>| OpenAI (the Responses API), Google (the Gemini API, through its OpenAI-compatible endpoint or its own client), xAI, DeepSeek, Baidu, Mistral, OpenRouter, Alibaba (Qwen), Groq, Azure OpenAI, LiteLLM; Llama models through the routers and providers that serve them and through local models |~~}

  {++These are the presets of the first version. Any endpoint compatible with one of the two APIs can be configured without a preset; Meta's own Llama API is not used. (<- S30: xxotherproviders1, xxmeta1, xxopenai2 … xxopenai4, xxgoogle1)++}

{~~- **CS.13** GitHub Copilot is reached only through direct calls and its SDK.
  (S2 § 5, FO-2)~>- **CS.13** GitHub Copilot is reached only through direct calls and its SDK.
  (<- S2 § 5; S23: later1, planned) (-> FO-2)~~}
- **CS.14** A provider configuration carries its endpoint, the models it
  offers (read from the provider where it lists them), and its prices, so
  usage and cost are shown per provider.{++ The prices are taken from the provider (its model list, or the cost it reports per answer) or from a published price list, never maintained by hand; where no price is available, usage is shown without a cost. Premium requests and a remaining quota are shown where the provider reports them (<- S30: xxproviders4, xxcopilotsdk1). A router's configuration carries its routing preferences: the upstream providers preferred or excluded, whether fallbacks are allowed, and the collection of data by the provider, off by default (<- S30: xxopenrouter1).++} Usage and cost are reported per round and per prompt (`RT > RT-TRANSPORTS`, CR.98) and kept in the usage ledger (`RT > RT-MACHINE`, CR.105). The configuration can name the profile on which an {~~item that ran out of budget is continued (`RT > RT-QUEUE`, CR.92). (S7; S2 § 3.8)~>item that ran out of budget is continued (`RT > RT-QUEUE`, CR.92). (<- S7; S2 § 3.8; S23: dapieff16, progress 2026-11-24; S30: xxproviders5)~~}
{~~- **CS.15** One conformance table checks every provider configuration: a
  prompt, a tool call, streaming, usage. (S2 § 3.8; S7)~>- **CS.15** One conformance table checks every provider configuration against a recorded or simulated server: a prompt, a streamed answer, a tool call and its result, a refused key, a rate limit with its retry time, and usage; and, when asked for, a short live check per provider with a real key. (<- S2 § 3.8; S7; S30: xxproviders6)~~}
{~~- **CS.16** Two agent libraries are evaluated behind the transport
  interface, one as a model transport and one as an agent transport, before
  it is decided whether the runtime takes them. (S1 § 5.4; S2 § 3.8)~>- **CS.16** Two agent libraries are evaluated behind the transport interface before it is decided whether the runtime takes them: `pi-ai` (one interface to Anthropic, OpenAI, Google and OpenAI-compatible endpoints) as a model transport, and `pi-coding-agent` (a coding agent driven over RPC as a child process, reaching the runtime's tools through MCP) as an agent transport; `pi-agent-core` is not used, as it duplicates the runtime's tool loop. The evaluation compares answers, tool use, cost and the handling of failures with the runtime's own transports; a library that is taken keeps what CR.27 requires. (<- S1 § 5.4; S2 § 3.8; S30: ccparity_h_pi-1 … ccparity_h_pi-3)~~}
- **CS.17** A new transport maps its stream onto the runtime's events (text,
  reasoning, tool call, tool result, retry, notice, usage), bridges the
  runtime's tools, routes approvals, and returns the answer, with a session
  id where the outside program of an agent transport owns the conversation. Starting a session over (`RT > RT-QUEUE`, CR.18) then means a new session id of the outside program under the same session name. {~~(S7, "How the runtime
  reaches a model today"; PQ-25)~>(<- S7 *How the runtime reaches a model today*) (-> PQ-25)~~}
{~~- **CS.18** The providers beyond today's transports are built in the
  runtime, after the transports have moved into it; none is built in the
  extension first. (S2 § 3.8; S7)~>- **CS.18** The providers beyond today's transports are built in the
  runtime, once it carries today's transports; none is built in the
  old extension first. (<- S2 § 3.8; S7; S30: xxproviders1)~~}
- {++**CS.21** A provider is reached through an adapter, and one provider can have several: the runtime's own clients (the direct client with a base address, the provider client grown from the client for local models), the Vercel AI SDK as one adapter for many APIs, and a provider's official SDK. A profile names the adapter it uses. Configurations of local models are provider configurations like the others. (<- S30: xxproviders1, xxproviders3)++}
- {++**CS.22** A configuration on an Anthropic-compatible endpoint carries its base address, its key reference and a mapping of the Claude Agent SDK's model slots to the provider's models. The runtime gives them to that configuration's sends only, never to the whole process, so profiles on Anthropic and on a compatible provider run side by side. (<- S30: xxproviders2, xxdeepseek1, xxotherproviders4)++}
- {++**CS.23** A transport that signs in to a vendor's account offers per configuration the account the host is signed in with, where the host has one, a token or key named by a secret reference (CS.7), or cloud credentials; the provider page shows the sign-in state (`RT > RT-INSTALL`, CR.111). (<- S30: xxcopilotsdk1, xxopenai1, xxgoogle1)++}
- {++**CS.24** On an agent transport whose outside program has tools and instruction files of its own, a profile chooses whether they are used; by default they are off. (<- S30: xxcopilotsdk1)++}
- {++**CS.25** A provider API that keeps the conversation on the provider's side (Mistral's Conversations) is a model transport whose session id is the provider's conversation id (CS.17). (<- S30: xxmistral1)++}

## <!--[CLI]--> 8 Client SDKs, UI components and supervision

### <!--[CLI-PACK]--> 8.1 The client SDKs

- **CL.1** The runtime client SDK and the tac client SDK exist in nine languages: Dart, TypeScript,
  JavaScript, Python, Java, Go, Rust, C and C++. All nine are part of the
  first version: Dart, TypeScript and JavaScript tested thoroughly (CL.7),
  the other six with the generated protocol layer and their convenience
  layer, checked by the conformance suite. Whether TypeScript and JavaScript are one client SDK, which would make it eight languages, is open (PQ-42). {~~(S1 § 12.1; S4, note k; PQ-7)~>(<- S1 § 12.1; S4: note k) (-> PQ-7)~~}

> **❓ PQ-42 (2026-11-20T16:45+01:00) — TypeScript and JavaScript: one client SDK or two:** Are TypeScript and JavaScript served by one client SDK (which makes eight languages), or by two, as the count of nine languages has it?
>
> **Context:** `CLI > CLI-PACK`, CL.1: "The runtime client SDK and the tac client SDK exist in nine languages: Dart, TypeScript, JavaScript, Python, Java, Go, Rust, C and C++. All nine are part of the first version". A **client SDK** is a library an application is built with: the runtime client SDK to speak to a runtime, the tac client SDK to speak to tac (the coordination and messaging service). `NFR > NFR-GEN`, G-5 counts "the client SDKs of the eight other languages" beside Dart and so lists TypeScript and JavaScript as two; the places are `tom_ai/ai_build/tom_ai_runtime_nondart/<language>/` (CL.3). In other places the document treats the two as one: CL.7 ("The Dart and the TypeScript and JavaScript client SDKs are tested thoroughly"), and your own words in the answer to PQ-28 ("a Dart and a JS/TS web runtime client SDK"). A library written in TypeScript is compiled to JavaScript and published with its type declarations; a JavaScript program uses it as it is. The nine languages come from the concept (S1 § 12.1) and your note k, and are those of the SOM runtimes in `tom_ai/ai_build`, where TypeScript and JavaScript are two packages.
>
> **Why I ask:** Each language is two client SDKs to generate, to give a convenience layer by hand, to run through the conformance suite and to publish (`RISK > RISK-RISKS`, R-12 and R-24 name that effort as a risk). Two packages for TypeScript and JavaScript would hold the same code twice, or the JavaScript one would be the TypeScript one compiled. This is an improvement idea of the consistency read, not something a source demands.
>
> - (a) Two client SDKs, as counted today: a TypeScript package and a JavaScript package of each SDK, nine languages. The JavaScript one is written in JavaScript with documentation comments for its types; it matches the SOM runtimes' layout.
> - **(b)** One client SDK for both: one package of each SDK, written in TypeScript, published as JavaScript with type declarations and usable from either. The text says "eight languages (TypeScript and JavaScript as one)"; CL.1, CL.3, CL.7 and G-5 follow, and the web runtime client SDK "in Dart and in JavaScript / TypeScript" is two packages.
> - (c) One source, two published packages: written once in TypeScript, published under a TypeScript name and under a JavaScript name, so that the list of nine languages and the folder per language stay as they are.
>
> *Recommendation:* (b) — a JavaScript user loses nothing, and one conformance run, one convenience layer and one publication per SDK fall away.
>
> *Assumption until answered:* CL.1, CL.3, CL.7 and G-5 keep nine languages, with TypeScript and JavaScript counted as two; CL.1 names the point as open.
>
> **Answer:**

- **CL.2** In each of the nine languages there are two client SDKs, each in a package of its
  own: the **runtime client SDK**, which speaks the runtime protocol, and the
  **tac client SDK**, which speaks TAC. The runtime client SDK depends on the
  tac client SDK. The Solution Blueprint settles what the runtime client SDK takes from the tac client SDK, since an application never speaks to tac itself (CL.11). {~~(S1 § 12.1, CQ-15)
- **CL.12**~>(<- S1 § 12.1) (-> CQ-15)
- **CL.12**~~} {~~Three client SDKs exist (PQ-28; PQ-26; PQ-30):~>Three client SDKs exist (-> PQ-28, PQ-26, PQ-30):~~}
  - the **runtime client SDK**, with which a host speaks the runtime protocol to its runtime (`RT > RT-PROTO`, CP.1): for an application on a machine where a runtime runs. In nine languages (CL.1);
  - the **tac client SDK**, which speaks TAC to tac: for runtimes and command-line programs of ours, for no application and no server (CL.11). In nine languages (CL.1);
  - the **web runtime client SDK**, which talks over HTTP to a web runtime service on a server (`RT > RT-INSTALL`, CR.108): for an application on a phone, on a tablet or in a browser, built with Flutter or not, where no runtime runs. In Dart and in JavaScript / TypeScript.

  Open for the web runtime client SDK (PQ-41): whether it is a client SDK of its own or the runtime client SDK with a second way to connect; whether it has the two layers of CL.4 and the convenience layer of CL.5, as far as that applies where no runtime can be found or started; whether the two Dart SDKs offer one programming interface, so that an application and the Flutter components (`CLI > CLI-UI`, CU.1) work over either; how events, asks and the host's tools cross HTTP (CP.1); and whether CL.6, CL.8 and CL.9 hold for it. CL.4 to CL.10 are stated for the runtime client SDK and the tac client SDK. `NFR > NFR-GEN` names the two web runtime client SDKs as units (G-8, G-9).

> **❓ PQ-41 (2026-11-20T16:45+01:00) — what the web runtime client SDK is beside the runtime client SDK:** Is the web runtime client SDK a client SDK of its own, or the runtime client SDK with a second way to connect — and does an application, and do the Flutter UI components, work the same over either?
>
> **Context:** Your answer to PQ-28: "there would be a remote runtime client SDK that connects to a remote runtime service running on a server … For the web scenario we'll need a HTTP-based service … I suggest we call the component web runtime client SDK and web runtime service, being used in mobile apps and from Flutter-base (or non-Flutter) web applications. We'll provide a Dart and a JS/TS web runtime client SDK for easy and consistent integration." A **client SDK** is a library an application is built with. The Project Idea had two, each in nine languages (`CLI > CLI-PACK`, CL.1, CL.2): the **runtime client SDK**, with which a host (the application that starts a runtime and shows what it does) speaks the runtime's protocol to its runtime, and the **tac client SDK**, with which a runtime speaks to tac, the coordination and messaging service. The text now names a third beside them, as you said it: the **web runtime client SDK**, in Dart and in JavaScript / TypeScript, for an application on a phone, on a tablet or in a browser, where no runtime runs; it talks over HTTP to the **web runtime service** on a server, which connects to a runtime for it (CL.12; `RT > RT-INSTALL`, CR.108).
>
> What the Project Idea says of the runtime client SDK, and what is not said of the new one:
>
> - CL.4: "A client SDK has two layers. The **protocol layer** is generated from the protocol's JSON schema. The **convenience layer** is written by hand in each language and is the same in every language." CL.5 lists the convenience layer: "find or start the installed runtime, connect, subscribe to events, queue a prompt, walk a group of todos, answer an ask, register the host's tools". An application in a browser cannot find or start a runtime; the rest it needs as well.
> - `RT > RT-PROTO`, CP.1: a host attaches with "JSON-RPC 2.0 with length-prefixed messages over a TCP connection on the local machine; a remote runtime client attaches over WebSocket". The protocol has three directions (CP.3, CP.4, CP.10): **commands** from the application, **events** from the runtime (streamed text, the state of a run, an ask opened), and **reverse requests** from the runtime to the application: an ask the user must answer, opening a document, and a call of one of the **host's tools** (a tool the application itself carries out, such as Webwork's document tools, `RT > RT-TOOLS`, CT.4). "HTTP-based" says nothing on how events and reverse requests reach a phone or a browser.
> - `CLI > CLI-UI`, CU.1: the Flutter UI components (`tom_ai_runtime_ui`) are built "over the Dart runtime client SDK"; CU.4: "The components build for desktop, web, iOS and Android." On the web, iOS and Android an application has only the web runtime client SDK. Webwork plans one body of Dart code for its desktop, web and phone builds (webwork todo `13_woneb6`).
> - `NFR`, N-29: the packages "are published only to pub.dev (the Dart packages) and to the workspace's binaries repository (everything a host or a tac server installs …). Publication to further registries and to the application stores is later." A JavaScript / TypeScript library for web applications is usually taken from npm, the registry web developers look in.
> - CL.6 (one conformance suite checks every client SDK), CL.8 (a client SDK carries the version checks and the upgrade callbacks: `RT > RT-VERSIONS`, CP.24 … CP.27, written for a host that installs a runtime on its machine) and CL.9 ("The Dart runtime client SDK has no dependency on Flutter") are stated for the two SDKs only.
>
> **Why I ask:** The answer names the SDK and its two languages and leaves open what it is. Four things depend on it: whether Webwork and trc (the supervision application) write their code once or twice in Dart; whether the UI components can be used at all in the builds CU.4 names; whether AI in a browser can edit a document (it needs the host's tools, a reverse request); and how many packages are generated, tested and published (`NFR > NFR-GEN` names it as two units, G-8 and G-9, without a package or a place). What the web runtime service itself is, is asked in PQ-38; which program a phone reaches from the internet, in PQ-49.
>
> - (a) A client SDK of its own, with its own programming interface, made for what a phone or a browser needs (messaging, asks, review, supervision): commands and a stream of events, no reverse requests for the host's tools. Dart and JavaScript / TypeScript only. An application that runs on the desktop and on a phone is written against two interfaces, and the Flutter UI components get a thin layer of their own over each. AI that edits an application's documents does not work in a browser or on a phone.
> - **(b)** A package of its own in Dart and in JavaScript / TypeScript, with the **same programming interface** as the runtime client SDK of that language, less what needs a runtime on the same machine (finding, starting and supervising a runtime; installing one). It carries the whole runtime protocol over HTTP: commands as requests, and one stream from the server for the events and the reverse requests, which the application answers with a request — so asks and the host's tools work. Its protocol layer is generated from the same JSON schema, the conformance suite checks it against a running web runtime service, the version checks apply as "this application is too old for this service", and the Dart one has no dependency on Flutter. The Flutter UI components are written against the shared interface and work over either SDK. The seven other languages get none. It is published like the other packages (N-29): the Dart one on pub.dev, the JavaScript / TypeScript one in the binaries repository; npm comes with the further registries, later.
> - (c) No separate SDK: the runtime client SDK of every language gets a second way to connect (HTTP to a web runtime service, beside TCP and WebSocket to a runtime), chosen when the application connects. One package per language, all nine languages; the name "web runtime client SDK" then names that way of connecting in Dart and JavaScript / TypeScript, where it is tested thoroughly. Every runtime client SDK carries code a desktop host never uses, and a browser build carries code for finding and starting a runtime that it cannot use.
>
> *Recommendation:* (b) — it is what you named (a component of its own, in two languages), it lets Webwork, trc and the UI components be written once, and it keeps what a browser cannot do out of the browser's package; (c) has the same effect for an application but puts two transports into nine SDKs.
>
> *Assumption until answered:* N-29 says where the JavaScript / TypeScript web runtime client SDK is published is open. CL.12 names three client SDKs: the runtime client SDK and the tac client SDK in nine languages, and the web runtime client SDK in Dart and in JavaScript / TypeScript, with no package name and no place. CL.4 … CL.9 are stated for the first two. CU.1 keeps "over the Dart runtime client SDK" and says that it is open over which SDK the components work on the web, iOS and Android. CP.1 says the wire to the web runtime service is HTTP-based and that events and reverse requests over it are open. `NFR > NFR-GEN` names it as two units (G-8, G-9) without a package or a place.
>
> **Answer:**

{~~- **CL.3** The places (S1 § 12.1; S2 § 5, FO-11):~>- **CL.3** The places (<- S1 § 12.1; S2 § 5) (-> FO-11, D-1):~~}

  | Package | Place |
  | --- | --- |
  | The Dart runtime client SDK | `tom_ai/ai_build/tom_ai_runtime_client` |
  | The Dart tac client SDK | `tom_ai/ai_build/tom_tac_client` |
  | The client SDKs of the other eight languages | `tom_ai/ai_build/tom_ai_runtime_nondart/<language>/` |
  | The web runtime client SDK, in Dart and in JavaScript / TypeScript | not named until PQ-41 is answered |

  {++The runtime itself is in `tom_ai/ai_build/tom_ai_runtime`, in the repository `tom_ai_build`, beside these packages, and the new VS Code extension is built in the same repository (`DEC`, D-73). (-> D-1, D-73)++}

- **CL.4** A client SDK has two layers. The **protocol layer** is generated from
  the protocol's JSON schema. The **convenience layer** is written by hand
  in each language and is the same in every language. Which generator
  writes what, and what more can be generated, is named at the start of
  Phase 4 (`NFR > NFR-GEN`). {~~(S1 § 12.1; S2 § 5, FO-10; PQ-17)~>(<- S1 § 12.1; S2 § 5) (-> FO-10, PQ-17)~~}
- **CL.5** The convenience layer of the runtime client SDK: find the runtime installation and start a runtime from it, connect, subscribe to events, queue a prompt, walk a
  group of todos, answer an ask, register the host's tools, and messaging and documents for the host's user (`RT > RT-PROTO`, CP.36). That of the
  tac client SDK: connect, send a message, send documents for review, receive.
  Tom Forge needs more of it for a runtime it started: to report the runtime's exit with its last log lines, to start it again, and to subscribe again from the numbered events (CP.5); and to ask what is being executed or scheduled before it ends (CP.37).
  {~~(S1 § 12.1; PQ-30; S25: 13_woneb6, planned; S26: qavs_wwworkbench-3, planned)~>(<- S1 § 12.1; S25: 13_woneb6, planned; S26: qavs_wwworkbench-3, planned) (-> PQ-30)~~}
- **CL.6** One conformance suite checks every client SDK in every language
  against a running runtime and a running tac service. It includes the
  pass-through of unknown fields (CP.26). It drives each tac client SDK by a test program of its own, without a runtime, since no application uses that SDK (CL.11). {~~(S1 § 12.1, § 6.7; PQ-26)~>(<- S1 § 12.1, § 6.7) (-> PQ-26)~~}
- **CL.7** The Dart and the TypeScript and JavaScript client SDKs are tested
  thoroughly, beyond the conformance suite; they are the client SDKs of the
  {~~platforms the product itself is built on. (S1 § 12.1; S4, note k)~>platforms the product itself is built on. (<- S1 § 12.1; S4: note k)~~}
- **CL.8** A client SDK carries the version checks and the upgrade callbacks of
  {~~`RT > RT-VERSIONS`. (S1 § 6.7, DQ-9)~>`RT > RT-VERSIONS`. (<- S1 § 6.7) (-> DQ-9)~~}
{~~- **CL.9** The Dart runtime client SDK has no dependency on Flutter. (S1 § 3.3)~>- **CL.9** The Dart runtime client SDK has no dependency on Flutter, nor on the VS Code scripting API. (<- S1 § 3.3; S30: ww_e_runtimeapi-3, planned)~~}
- **CL.10** The Dart runtime client SDK grows out of today's Dart client of the
  extension's script server: its wire layer, its feature APIs and its mirror
  of the Claude Agent SDK. Scripts that use that client keep working against
{~~  a VS Code window and against a runtime. (S2 § 3.5; S1 § 2.1)~>  a VS Code window and against a runtime. Its connection is an exchangeable transport: one to a VS Code window's script server, one to a runtime (`RT > RT-PROTO`, CP.1), each carrying the commands and the reverse requests (CP.10); for the commands both serve, it answers the same through either. (<- S2 § 3.5; S1 § 2.1; S30: ww_e_runtimeapi-2, ww_e_runtimeapi-4, planned)~~}
- **CL.11** An application reaches tac through its runtime. The tac client SDK is
  used by runtimes and command-line programs of ours; no server uses it. An application in a browser, on a
  phone or on a tablet uses the web runtime client SDK against a web runtime service, which reaches tac through the runtime on the server
  (`RT > RT-INSTALL`, CR.108, CR.110). {~~(S1 § 12.1, § 7.3, WQ-1; PQ-26; PQ-28; PQ-30; `NFR > NFR-TOPO`, T8)~>(<- S1 § 12.1, § 7.3) (-> WQ-1, PQ-26, PQ-28, PQ-30, T8)~~}
- {++**CL.13** `tom_vscode_scripting_api` (7.0.0) keeps only what a VS Code window serves, its VS Code namespace; it depends on the Dart runtime client SDK and re-exports it, so that existing scripts keep their import. (<- S30: ww_e_runtimeapi-1, planned)++}
- {++**CL.14** The users of today's Dart client of the extension's script server — the d4rt command line and its script bridges, the VS Code bridge, and Tom Core's agent code — move to the Dart runtime client SDK when it is published; each is released by its own quest. (<- S30: ww_e_runtimeapi-5, planned)++}
- {++**CL.15** The new VS Code extension (D-73) is a host written in TypeScript. When it starts the runtime as a process from the runtime installation, as every other host does, it speaks the runtime protocol through the TypeScript runtime client SDK; as long as it runs the runtime in its own process it calls the runtime directly (`RT > RT-INSTALL`, CR.142). Which of the two it does is open (PQ-37), and whether the TypeScript and the JavaScript client SDK are one package is open (PQ-42). (-> D-73, CR.142)++}

### <!--[CLI-UI]--> 8.2 The Flutter UI components

- **CU.1** `tom_ai/ai_build/tom_ai_runtime_ui` holds every reusable
  component of the runtime's user interface, for Flutter, over the Dart
  runtime client SDK. On the web, on iOS and on Android no runtime runs, and an application there has the web runtime client SDK (`CLI > CLI-PACK`, CL.12); over which SDK the components work there is open (PQ-41). {~~(S1 § 12.2; S2 § 5, FO-11; CQ-14; PQ-28)~>(<- S1 § 12.2; S2 § 5) (-> FO-11, CQ-14, PQ-28)~~}
- **CU.2** The components take their look from the application through theme
{~~  parameters. (S1 § 12.2, § 3.2)~>  parameters. (<- S1 § 12.2, § 3.2)~~}
- **CU.3** The package depends on nothing of Tom Forge. Tom Forge's own view
  package is built on top of it and keeps only what binds the components
{~~  into the Forge shell. (S1 § 12.2, CQ-14)~>  into the Forge shell. (<- S1 § 12.2) (-> CQ-14)~~}
{~~- **CU.4** The components build for desktop, web, iOS and Android.
  (S1 § 12.2)~>- **CU.4** The components build for desktop, web, iOS and Android.
  (<- S1 § 12.2)~~}
- **CU.5** The basis of each component is what the extension shows today.
  The components' names follow the ones the web component kits for agent
  work have settled on, since no Flutter kit covers agent work. What becomes of the Flutter packages with agent and todo views that exist over other backends (`LAND > LAND-BUILT`, E-20), and whether the Todos group is built on one of them, is open {~~(PQ-44). (S1 § 12.2,
  § 15.5)~>(PQ-44). (<- S1 § 12.2, § 15.5)~~}

> **❓ PQ-44 (2026-11-25T20:48+01:00) — the Flutter view packages that exist beside the new UI components:** What becomes of the three Flutter packages with agent and todo views that exist today, once `tom_ai_runtime_ui` is built — and is its Todos group built on the existing todo editor?
>
> **Context:** `CLI > CLI-UI`, CU.1: "`tom_ai/ai_build/tom_ai_runtime_ui` holds every reusable component of the runtime's user interface, for Flutter, over the Dart runtime client SDK." CU.5: "The basis of each component is what the extension shows today." CU.6 lists its groups, among them "**Conversation**" (the chat with a model), "**Queue**", "**Trail**" and "**Todos** — todo list and tree, todo editor, decisions, … session todos, todo log, the panel across quests". CU.3: "The package depends on nothing of Tom Forge. Tom Forge's own view package is built on top of it and keeps only what binds the components into the Forge shell." The **runtime** is the engine that every host starts and works through (`RT`); a component "over the runtime client SDK" shows what a runtime holds and sends the user's actions to it.
>
> Three Flutter packages with such views exist in `tom_ai/modules`, over other things than the runtime (`LAND > LAND-BUILT`, E-20):
>
> - `tom_agentic_ui`: the chat composer, the prompt queue and the prompt trail with their controllers, the picker of an agent connection, the review of changes; over `tom_core_agentic`, the Dart agent code of Tom Core (tom_forge todo `02b_woneb8`, completed 2026-11-20).
> - `tom_ai_trail_ui`: the live trail of an AI session, over `tom_llm`. Webwork's AI runs on it in its wave 1b1 and keeps it until wave 1b2, when its AI moves to the runtime and the package is retired from its desktop builds (webwork todos `06_woneb9`, `13_woneb4`).
> - `tom_todo_ui`: the row of a todo, its details editor and the editor of a todo file, over `tom_todo_model` (6.0.0), the Dart model of the todo files. It is Webwork's todo-file editor, and Tom Forge plans its quest todo views with it, sending and queueing "through a host capability" (tom_forge todos `qavs_ccparity_e_process-4`, `qavs_wwworkbench-8`).
>
> Two plans disagree with CU.1 and CU.3: Tom Forge's todo for its quest application (`qavs_ccparity_d_claudecode-1`) still plans chat, queue and trail views of its own in `tom_forge_agentic`, written before CU.3; and Webwork's component placement (C22, S29) lists its AI run tabs as "existing modules" (`tom_agentic_ui`, `tom_ai_trail_ui`), while its todo `13_woneb2` takes them from `tom_ai_runtime_ui` — the two disagree inside the webwork quest.
>
> **Why I ask:** The Project Idea names none of these packages in `CLI`, so it does not say whether the new components start from them, replace them or stand beside them. For the Todos group there would be two todo editors: the existing one that reads and writes todo files directly through `tom_todo_model`, and a new one that goes through the runtime (which, by `RT > RT-HOLDS`, CR.1, writes the `_ai` files; whether Dart code may keep writing them is PQ-34). It decides what Webwork and Tom Forge embed in wave 1b2 and in the quest application, which of Webwork's two placements is corrected, whether `tom_ai_runtime_ui` may depend on packages of `tom_ai/modules`, and what is maintained afterwards.
>
> - (a) The new components replace all three. `tom_ai_runtime_ui` is written new from what the extension shows (CU.5), with the three packages as input for the look and the structure of the widgets; it depends on none of them. `tom_agentic_ui` and `tom_ai_trail_ui` are retired when their users have moved to the runtime (Webwork with its wave 1b2); `tom_todo_ui` stays only for an application that edits a todo file without a runtime.
> - **(b)** Split by what the package works over. The agent views (`tom_agentic_ui`, `tom_ai_trail_ui`) are input and are replaced: the Conversation, Queue and Trail groups are written new over the runtime client SDK, and the two packages are retired when Webwork (wave 1b2) and Tom Forge have moved; Webwork's C22 is corrected to `tom_ai_runtime_ui`, as `13_woneb2` already has it. The Todos group is **built on `tom_todo_ui`**: its widgets for a row, the details and a file stay the one todo editor, and `tom_ai_runtime_ui` adds what needs a runtime (the todos of a quest and across quests, queueing and sending a todo, decisions, todo offers, the todo log). `tom_ai_runtime_ui` may then depend on packages of `tom_ai/modules`, never on Tom Forge.
> - (c) The three packages are the base: `tom_ai_runtime_ui` is built on all of them, giving each a second backend (the runtime client SDK beside `tom_core_agentic` and `tom_llm`). Least new code for the views, and Webwork's C22 stands; the components then carry the shape of code written for another agent model, and CU.5 ("what the extension shows today") holds only in part.
>
> *Recommendation:* (b) — the chat, queue and trail of the runtime differ from those of `tom_core_agentic` (runs, the states of an item, asks, the numbered events), so building on them would bend one of the two; a todo is the same record in both, and one todo editor is less to maintain than two. In every option Tom Forge's quest application embeds the components instead of building views of its own (CU.3), and the quests `tom_forge` and `webwork` are told when the todos are filed.
>
> *Assumption until answered:* CU.1, CU.3, CU.5 and CU.6 keep their text; CU.5 names the point as open. E-20 states the three packages as built over other backends, and Webwork keeps `tom_ai_trail_ui` until its wave 1b2.
>
> **Answer:**

{~~- **CU.6** The component groups (S1 § 12.2):~>- **CU.6** The component groups (<- S1 § 12.2):~~}

  | Group | Components | Starts from |
  | --- | --- | --- |
  | **Conversation** | conversation, message, prompt input with the three send choices and the completion of slash commands and skills (`RT > RT-PROTO`, CP.38), attachments, reasoning, tool card, context and usage, model and profile selector | the chat panel |
  | **Asks** | question, pick, confirmation of a tool call, plan approval, decision, gate result with its buttons, document ask; the ask inbox, which shows for each open ask the run that waits for it and since when (`RT > RT-ASKS`, CP.23) and closes an ask in every place once it is settled (CP.40); the answers handed to the user (`RT > RT-TOOLS`, CT.17); {~~planned: the journal of asks and answers, with the questions and decisions across quests (`RT > RT-HOLDS`, CR.55) | the ask panels~>planned: the journal of asks and answers, with the questions and decisions across quests (`RT > RT-HOLDS`, CR.55), shown in one editor of questions and answers (<- S23: vscimpb186, planned); planned: an ask or a todo's decisions answered inline from the notifications list of any host (<- S23: vscimpb182, planned) | the ask panels~~}, plan mode, the document asks, the answers page |
  | **Queue** | queue list (the states of an item and the marks of an item that is being executed: `RT > RT-QUEUE`, CR.69; reorder, edit, remove), the commands on an item that is being executed (answer, resend, skip, stop: CR.74), item editor for the kinds of an item (CR.64), timed requests with their switches (CR.84), templates | the queue editor |
  | **Runs and processes** | run tabs with the state of the run and what it waits for or is held by (CU.17), process view (phases, steps, proceed, decide, skip, back), branching, runs overview | the process view, the runs overview |
  | **Todos** | todo list and tree, todo editor, decisions, todos that are the user's to do, {~~todo offers to accept or refuse (`PAR > PAR-CROSS`, CW.26), session todos, todo log, the panel across quests | the todo panels~>todo offers to accept or refuse (`PAR > PAR-CROSS`, CW.26), session todos, todo log, the panel across quests; planned: the dependency closure of a set of todos and their order of work (`RT > RT-HOLDS`, CR.118) | the todo panels~~} |
  | **Trail** | live trail, summary trail, a bounded Markdown view that only appends | the trail viewers, the output channels |
  | **Sessions and memory** | sessions with their base, lifetime and profile, started over or deleted (`RT > RT-QUEUE`, CR.75), memory, chat variables, notes, personal notes | the sessions view, the editors |
  | **Messaging** | conversation list, conversation, composer, document card, review request card, reminder, people | new; from tac |
  | **Review** | the review component for Markdown documents: questions and answers, comments, marks, team chips, votes, conflicts, consolidation | the document browser |
  | **Supervision** | runtime list, what waits or is held, per run (CU.17), notifications of both classes (`RT > RT-PROTO`, CP.39), {~~the coordination page (claims, leases with the executions that hold them, the integration queue), status~>the coordination page (CU.18), status~~} of the machine's runtimes | the window status and notifications views; new |
  | **Settings** | profiles, providers and keys, coordination, team administration, what the extension's status page holds | the status page |

- **CU.7** The bounded Markdown view keeps the last so-many lines or
  kilobytes and forgets the rest; it follows its end. It serves a run's log
  and an application's own log channels. It works without a connection to a runtime, on text its host gives it, and the host sets its bound per use. {~~(S1 § 3.2; S3, WR-7; S25: 06_woneb8, 13_woneb4, planned)~>(<- S1 § 3.2; S3 WR-7; S25: 06_woneb8, 13_woneb4, planned)~~}
- **CU.8** The trail components show streamed text, reasoning, tool cards,
  the summary of a prompt, and the marks of a prompt that waits for the
{~~  user to apply or discard its result. (S1 § 3.2)~>  user to apply or discard its result. (<- S1 § 3.2)~~}
- **CU.9** The review component for Markdown documents is one Flutter
  component, shared by Webwork, Tom Forge's quest application and trc.
{~~  Where it is built, and in which form, is open (PQ-43): the quests `webwork` and `tom_forge` plan it outside this product, as the extension's document browser page shown in a web view and as a Dart component in the `tom_forge` repository (S25: 09_woneb5; S26: 05b_woneb1 … 05b_woneb5, planned). The protocol between the extension's document browser page and its host (S23: 01b_woneb1, 01b_woneb2) is an input for the component's interface. An application of its own for reviewing is not part of this product (`SCO > SCO-OUT`, O-10).
  (S1 § 3.3; S11)~>  Where it is built, and in which form, is open (PQ-43): the quests `webwork` and `tom_forge` plan it outside this product, as the extension's document browser page shown in a web view and as a Dart component in the `tom_forge` repository (<- S25: 09_woneb5; S26: 05b_woneb1 … 05b_woneb5, planned; S29: OR-19, OR-20). The extension's document browser page runs behind a host object, with a versioned protocol between the page and its host (version 1) (<- S23: 01b_woneb1, 01b_woneb2); planned: the page reveals an item, reports the reading position and reports changes, and its bundle is published in the binaries repository with a conformance suite for the page's hosts (<- S23: 04c_woneb3, 04c_woneb2, 04c_woneb1, planned). That protocol is an input for the component's interface. An application of its own for reviewing is not part of this product (`SCO > SCO-OUT`, O-10). (<- S1 § 3.3; S11)~~}

> **❓ PQ-43 (2026-11-25T20:48+01:00) — which UI components this product builds for review and messaging:** Are the review component and the messaging components built in this product, as groups of the Flutter UI components, or outside it as the quests webwork and tom_forge plan them — and what does the supervision application then contain for a document under review?
>
> **Context:** The **runtime** is the engine that every host starts and works through (`RT`); the **Flutter UI components** are the reusable parts of its user interface that an application embeds. `CLI > CLI-UI`, CU.1: "`tom_ai/ai_build/tom_ai_runtime_ui` holds every reusable component of the runtime's user interface, for Flutter, over the Dart runtime client SDK." CU.3: "The package depends on nothing of Tom Forge." CU.6 lists among its groups "**Messaging** — conversation list, conversation, composer, document card, review request card, reminder, people — new; from tac" and "**Review** — the review component for Markdown documents: questions and answers, comments, marks, team chips, votes, conflicts, consolidation". CU.9: "The review component for Markdown documents is one Flutter component, shared by Webwork, Tom Forge's quest application and trc. Where it is built, and in which form, is open (PQ-43)". CU.16 says what Webwork needs of the messaging components. `CLI > CLI-TRC`, CK.2: trc (the supervision application) "lets the user review documents with the review component". `RISK > RISK-DEPS`, R-19 lists "Tom Forge's review component in Flutter" as a dependency of this product. **tac** is the coordination and messaging service; `TAC > TAC-PEOPLE`, CI.4: "Every application reaches tac through a runtime"; `RT > RT-PROTO`, CP.36: messaging and documents are commands of the runtime protocol for that reason.
>
> What the other quests decided or plan:
>
> - **The review component outside this product, in two routes** (webwork decisions of 2026-11-19 and 2026-11-25, OR-19, OR-20; S29): route 1 is the extension's document browser page shown in a web view inside the application (webwork todo `09_woneb5`); route 2 is a new Dart component in the `tom_forge` repository, working name `tom_md_browser_editor`, on `tom_som_dart_runtime` and `tom_forge_shared_ui` (tom_forge todos `05b_woneb1` … `05b_woneb5`); TomSpecs documents in YAML open in a TomSpecs editor of tom_forge. Both routes carry one **navigation contract** — reveal an item, report the reading position, report changes (OR-19; vscode_extension `04c_woneb3`, tom_forge `05b_woneb1`, planned).
> - **The messaging components as a module `tom_messaging_ui` in `tom_modules`** (webwork's component placement C21, Q-8 (a); S29), there assumed to work "over tac's Dart client" — which CI.4 does not allow, since an application has no tac connection of its own.
> - **Webwork's two review areas** (FQ-5, FQ-8; both in Webwork's wave 1b1, OR-21): **Review**, the reviewer's — the reviews waiting for the user, the document with its outline and items, and **Send back** to the coordinator through the channel the copy came by; **Team Review**, the coordinator's — review sets and rounds, sending, tracking per reviewer, the returned copies, consolidation (merged document, conflicts, votes). They are Webwork's own and use the review component; this question does not move them.
> - **What the extension's page does today** (S17; S23), which a component that replaces it must carry: the reading notation (provenance, editorial and aside passages, references, records, citations) with reading modes (`03b_rdv1`); rejected blocks with their resolution buttons and errors in navigation and search (`05b_rdv2`); marks from a selection and tracked changes written as signed marks, word by word (progress 2026-11-20); stepping through a review by kind, author, change time, check-here markers and agents' annotations (user guide *Stepping through a review*); panel settings across reloads and large documents rendered in steps (`02c_rdv1`, `mdbwebkit1`); planned: export and import buttons, a section copy shown read-only, headings past level 10 (`06b_rdv1`, `sauvoc2`, `vscimpb162`). The page already runs behind a host object with a versioned protocol (version 1: 25 messages from the page, 15 to it; `01b_woneb1`, `01b_woneb2`), and publishing its bundle with a conformance suite for hosts is planned (`04c_woneb2`, `04c_woneb1`).
> - **The product owner's answer to PQ-30:** "the review application will never be part of the ai_runtime project … this is none of our concern here." It speaks of the review **application** (`SCO > SCO-OUT`, O-10), not the component.
>
> The feature baseline of the first version (`DEC`, D-74) includes Webwork's team review and the sending of review document bundles through tac; the review **exchange** (`TAC > TAC-REVIEW`) and the runtime's review tools are this product's in every option.
>
> **Why I ask:** CU.6, CU.9 and G-6 (`NFR > NFR-GEN`) say this product builds both groups; R-19, the webwork quest and the tom_forge quest say the review component is built in tom_forge and the messaging components in `tom_modules`. If `tom_ai_runtime_ui` took the review component from tom_forge it would depend on Tom Forge, which CU.3 excludes. The answer decides what this product delivers and tests, what the components' interface to their host must carry (the navigation contract, the page's features), what trc shows of a document under review on the desktop and on a phone, and whether the review exchange can be tried end to end inside this product.
>
> - (a) Both built here, as CU.6 says: the Review group as one Flutter component in `tom_ai_runtime_ui` on the SOM Dart runtime, carrying the page's features listed above and the navigation contract, and the Messaging group over the runtime client SDK's messaging commands (CP.36). Webwork, Tom Forge and trc take both from here; R-19 is no dependency; the quests `tom_forge` and `webwork` are told that `05b_woneb1` … `05b_woneb5` and `tom_messaging_ui` move into this project or build on these components.
> - **(b)** Both outside this product: the review component as the two routes of the quests webwork and tom_forge, the messaging components as `tom_messaging_ui` in `tom_modules`, working over the runtime client SDK's messaging commands (CP.36), not over a tac client (CI.4). CU.6 loses the Review and the Messaging group but keeps the review request card among the Asks; CU.9 and SC-18 say "supplied by the quest `tom_forge`", CU.16 becomes what this product's commands give `tom_messaging_ui`; R-19 is the dependency for trc, which embeds both on the desktop and the tablet (CK.7 allows packages of Tom Forge) and on a phone shows a document under review read-only, its questions answerable through the ask components, until a phone form of the component exists. This product delivers the runtime and tac sides of review and messaging and the commands they use; the webwork quest is told that `tom_messaging_ui` must use the runtime client SDK.
> - (c) Review outside, messaging here: the review component as in (b); the Messaging group stays in `tom_ai_runtime_ui` as CU.6 and CU.16 say, and `tom_messaging_ui` is not built — Webwork takes the Messaging group from this product.
>
> *Recommendation:* (b) — it follows what you decided in the webwork quest on 2026-11-19 and 2026-11-25 and your "none of our concern here", keeps `tom_ai_runtime_ui` free of Tom Forge (CU.3), and corrects only one point of Webwork's placement: the messaging module works through the runtime, not through a tac client of its own.
>
> *Assumption until answered:* CU.6's Review and Messaging groups, CU.9, CU.16, SC-18, SC-27, CK.2, G-6 and R-19 keep their text; CU.9 names the two routes the other quests plan, the page protocol and its planned navigation, and says the place is open; CU.16 names `tom_messaging_ui` and says the place is open.
>
> **Answer:**

- **CU.16** What Webwork needs of the messaging components: the kinds of attachment, the kinds of card and the actions on a card come from the host (attaching a file, an item, a section or a document; on the card of a received copy: open, save into, merge, remind me, make a todo); the conversation list, the conversation and the composer are separate components, so that a host lays them out narrow, full or as two screens (CU.15); and they show the states of `TAC > TAC-DOCS`, CV.9. How the components take what the host supplies is for the Solution Blueprint. The components are Flutter components; the messaging views of the VS Code extension are the extension's own (`SCO > SCO-OUT`, O-1). {~~(S25: 13_woneb7 … 13_woneb9, planned; `TAC > TAC-KINDS`, CM.3; PQ-30)~>(<- S25: 13_woneb7 … 13_woneb9, planned) (-> CM.3, PQ-30)~~} {++Webwork plans these components as a module `tom_messaging_ui` in `tom_modules`, outside this product; whether the Messaging group is built here or there is open (PQ-43). (<- S29: C21, Q-8)++}
- **CU.17** A run that waits or is held says so wherever it is shown. The run tab, the runs overview, the queue and the supervision components show the state of the run (`RT > RT-QUEUE`, CR.23), what it waits for or is held by (an ask, a lease another execution has, a secret to unlock, a time or an event, its own background work, a result to apply or discard, a blocked todo, open decisions, an error) and {~~since when. (PQ-24; S23: vscimpb123, vscimpb124)~>since when. (<- S23: vscimpb123, vscimpb124) (-> PQ-24)~~}
- {++**CU.18** The coordination page shows the team runtimes with their runs, the leases (stale ones marked) with what holds them and what waits for them, the endpoints, the commands not yet taken, the repositories the fast-forward skipped (`PAR > PAR-APPROACH`, CW.16), and the working trees and branches of executions that were not integrated. Its actions — free a lease, free every lease of one machine, resend or drop a command, retry a skipped update — each ask for confirmation, are announced to the team runtimes and are kept with the lease or command they acted on. (<- S6 part-coordination-page-and-tools; S30: ww_f_collab-3, planned) (-> CA.13, CA.19, CW.16)++}

### <!--[CLI-SCREENS]--> 8.3 Screen and component descriptions

The design is delivered as descriptions and running code, not as drawings
{~~(S1 § 12.3, CQ-18, DQ-7).~>(<- S1 § 12.3) (-> CQ-18, DQ-7).~~}

- **CU.10** There is a complete inventory of the extension's screens: every
  view, panel and editor, and for each one what it becomes here.
{~~  Tom Forge's todos for its quest application each name a feature of the extension and what it needs from the runtime; they are the check of the inventory (S26: qavs_ccparity_…, qavs_dapieff-…).
  (S1 § 12.3, DQ-7)~>  Tom Forge's todos for its quest application each name a feature of the extension and what it needs from the runtime; they are the check of the inventory (<- S26: qavs_ccparity_…, qavs_dapieff-…). (<- S1 § 12.3) (-> DQ-7)~~}
  {++The same inventory lists, per screen, whether the new VS Code extension keeps it as it is over the runtime, changes it or drops it; a screen that is not listed as changed or dropped is kept. It is the list the runtime protocol is checked against (`RT > RT-PROTO`, CP.45). (-> D-73, CP.45)++}
{~~- **CU.11** What a screen of the extension becomes is one of (S1 § 12.3,
  DQ-7):~>- **CU.11** What a screen of the extension becomes is one of (<- S1 § 12.3) (-> DQ-7):~~}

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
{~~  the runtime client. (S1 § 12.3, CQ-18)~>  the runtime client. (<- S1 § 12.3) (-> CQ-18)~~}
- **CU.13** Everything that can be described now is described completely.
{~~  The extension keeps changing, and the descriptions are amended as it does.
  (S1 § 12.3, DQ-7)~>  The extension keeps changing, and the descriptions are amended as it does.
  (<- S1 § 12.3) (-> DQ-7)~~}
- **CU.14** `tom_ai_runtime_ui` contains a gallery application that shows
{~~  every component with made-up data. It is the living design and the place
  the components are tried. (S1 § 12.3, CQ-18)~>  every component with made-up data. It is the living design and the place
  the components are tried. (<- S1 § 12.3) (-> CQ-18)~~}
- **CU.15** The screens built from the components exist in three widths: a
  desktop panel, a narrow side panel, a phone. They are: the AI panel
  (conversation, queue and trail, switchable or side by side); process and
  runs, with the state of each run and what it waits for (CU.17); todos; the ask inbox with its escalation; messaging; the review
  editor and the consolidation view; supervision (the overview of
  team runtimes, the detail of a runtime); the coordination page; settings and team
{~~  administration. (S1 § 12.3)~>  administration. (<- S1 § 12.3)~~}

{~~The inventory as it stands.The outcomes are a first pass~>The inventory as it stands. The outcomes are a first pass~~}
from the names of the extension's views and handlers, not yet from their code;
{~~the Solution Blueprint confirms each from the code when the screen is described. (S1 § 12.3; S17)~>the Solution Blueprint confirms each from the code when the screen is described. (<- S1 § 12.3; S17)~~}

| Id | Extension screen | Outcome (first pass) | Component group |
| --- | --- | --- | --- |
| **SC-1** | The chat panel | reused | conversation |
| **SC-2** | The bars for a question, a pick, a tool approval and a plan approval | reused | asks |
| **SC-3** | The panel of open interactions, user notifications, the answers page | starting point (the ask inbox) | asks |
| **SC-4** | {~~Queue editor, queue entry, queue templates |~>Queue editor (run tabs, item cards with their chips), queue entry, queue templates (<- S17 user guide § 4 *Queue Editor*, package.json) |~~} reused | queue |
| **SC-5** | {~~Timed requests editor |~>Timed requests editor (<- S17 package.json) |~~} reused | queue |
| **SC-6** | {~~Process view, process branching |~>Process view (position, the action bar, runs, flow, jumps, left out), process branching (<- S17 user guide *Processes*) |~~} reused | runs and processes |
| **SC-7** | {~~Process editor, process template editor |~>Process editor, process template editor (<- S17 user guide *Processes*) |~~} starting point | runs and processes |
| **SC-8** | Runs overview | reused | runs and processes |
| **SC-9** | {~~Quest todos, session todos, workspace todos, the todo panel |~>Quest todos, session todos, workspace todos, the todo panel with its scopes, filters, sort and group headers; planned: *Do next* inside a group, sorting groups by stem (<- S17 user guide *Quest TODO Panel*; S23: vscimpb137, vscimpb138; vscimpb159, vscimpb175, vscimpb177, planned) |~~} reused | todos |
| **SC-10** | Quest todo editor | reused | todos |
| **SC-11** | {~~Todo log |~>Todo log (<- S17 package.json) |~~} reused | todos |
| **SC-12** | {~~Trail viewer, trail editor, quest logs |~>Trail viewer, trail editor, quest logs (<- S17 user guide *Logs Panel*) |~~} reused | trail |
| **SC-13** | {~~Output channels |~>Output channels (<- S17 user guide § 8) |~~} starting point (the bounded Markdown view) | trail |
| **SC-14** | {~~Sessions view, session pickers |~>Sessions view, session pickers (<- S23: vas5) |~~} reused | sessions and memory |
| **SC-15** | {~~Memory panel, chat variables editor |~>Memory panel, chat variables editor (<- S17 package.json) |~~} reused | sessions and memory |
| **SC-16** | Quest notes, workspace notes | reused | sessions and memory |
| **SC-17** | VS Code notes | host's own | — |
| **SC-18** | {~~The document browser, with questions, marks, team review, consolidation |~>The document browser, with questions, marks, team review, consolidation (<- S17 user guide *Markdown Browser*; S23: 05b_rdv1, vscannot2, vscannot4, ccparity_f_teamreview-3, 01b_woneb1, 01b_woneb2; 04c_woneb2, 04c_woneb3, planned) |~~} starting point (the review component) | review |
| **SC-19** | Window status | starting point (the list of team runtimes) | supervision |
| **SC-20** | Notifications | reused | supervision |
| **SC-21** | {~~Status page |~>Status page, the overlay of the extension's tools (<- S17 user guide § 3, § 7) |~~} split (providers, profiles and coordination each on their own; the state of the machine's runtimes; the diagnostics of the extension's own parts stay the host's own) | settings; supervision |
| **SC-22** | {~~Editors for prompt templates and reusable prompts |~>Editors for prompt templates and reusable prompts (<- S17 user guide § 3) |~~} reused | settings |
| **SC-23** | {~~Roles editor |~>Roles editor; the guideline picker on every level and the editor of the aspect guidelines (<- S17 user guide; S23: gsel5, gsel5b, gsel7, gsel7b) |~~} reused | settings |
| **SC-24** | {~~The workspace panel (guidelines, documents, logs) |~>The workspace panel (guidelines, documents, logs), the quest documents shown read-only (<- S17 user guide § 2 *Documentation Panel*, *Logs Panel*) |~~} starting point for the logs; the rest host's own | trail |
| **SC-25** | {~~Resources, prerequisites, the issues panel, the test panels |~>Resources, prerequisites, the issues panel, the test panels; planned: an editor for `prerequisites.yaml` (<- S17 user guide *@TOM VSC*, *Issues Panel*; S23: vscimpb152b, vscimpb152c, planned) |~~} host's own | — |
| **SC-26** | Reload overlay, migration screens, the screen of a runtime that does not start on files in another format (`RT > RT-VERSIONS`, CP.29) | starting point (the version callbacks) | settings |
| **SC-27** | none in the extension: messaging: conversations, composer, document and review cards | new | messaging |
| **SC-28** | {~~none in the extension: the coordination page: claims, leases with the executions that hold them, the integration queue~>none in the extension: the coordination page (CU.18); the extension plans a view of resource leases with a clean-up of dead leases (<- S28: caf_04d, planned)~~} | new | supervision |
| **SC-29** | none in the extension: team administration: members, invitations, devices | new | settings |
| **SC-30** | none in the extension: todo offers, to accept or refuse (`PAR > PAR-CROSS`, CW.26) | new | todos |
| **SC-31** | {~~planned in the extension: the view of questions and decisions across quests, over the journal of asks and answers (S23: 01_aifmt-4; `RT > RT-HOLDS`, CR.55)~>planned in the extension: one editor of questions and answers across quests and windows, over the journal of asks and answers (`RT > RT-HOLDS`, CR.55) (<- S23: 01_aifmt-4, vscimpb186, planned)~~} | starting point | asks |
| {++**SC-32**++} | {++The quest's overview opened once per machine the first time a quest window opens (<- S23: vsc_setup-6)++} | {++host's own (it needs only opening a document: `RT > RT-PROTO`, CP.10)++} | {++—++} |
| {++**SC-33**++} | {++The todo stack: todos picked and queued one item each, or sent as one prompt (<- S17 user guide *Todo stack*; S23: trb3)++} | {++reused++} | {++todos++} |
| {++**SC-34**++} | {++The question after *Guide me*: mark completed, mark in progress, queue it, leave it (<- S17 user guide *Guide me*)++} | {++reused++} | {++todos++} |
| {++**SC-35**++} | {++*Queue anyway* when a group waits for todos that do not run first; the tools do not ask (<- S17 user guide *Todo iteration*)++} | {++reused++} | {++queue++} |
| {++**SC-36**++} | {++planned in the extension: one set of icons for the place an item is queued at (end, top, next) (<- S23: vscimpb181, planned)++} | {++host's own++} | {++—++} |
| {++**SC-37**++} | {++planned in the extension: the views of the dependency closure of a set of todos and of their order of work, with the queued items of every runtime (`RT > RT-HOLDS`, CR.118) (<- S23: todoanalyzer1 … todoanalyzer4, planned)++} | {++starting point++} | {++todos++} |
| {++**SC-38**++} | {++The review of the changes an agent made to a document, each change accepted or rejected (`RT > RT-HOLDS`, CR.129) (<- S23: vscimpa11)++} | {++host's own++} | {++—++} |

The inventory has no row for the management of quests (the register of quests, `RT > RT-LOCATIONS`, CR.100, and the operations of `PAR > PAR-QUESTS`, CQ.7), {~~which the extension plans as a view of its own (S22 § 4; S23: 02_aifmt-1, planned)~>which the extension plans as a view of its own (<- S22 § 4; S23: 02_aifmt-1, planned)~~}, and `CLI > CLI-UI`, CU.6 has no component for it nor {~~for repository quests, which Tom Forge needs (S26: qavs_wwwgitruntime-1).~>for repository quests, which Tom Forge needs (<- S26: qavs_wwwgitruntime-1).~~} Whether those operations are commands of the runtime, so that every host gets screens for them, is open (PQ-55).

### <!--[CLI-TRC]--> 8.4 The supervision application (trc)

- **CK.1** trc shows a team's team runtimes in one view: what each runtime
  does, and what waits — questions, todos that need a decision, the state of
  the queues, runs, errors, claims, messages. For each run it shows the state the runtime reports with its registration (`RT > RT-QUEUE`, CR.23; `TAC > TAC-COORD`, CA.5) and what the run waits for or is held by, since when (`CLI > CLI-UI`, CU.17); {~~a quest is listed with its short description (`RT > RT-HOLDS`, CR.56). (S8; S1 § 12.4; S2 § 3.6; PQ-24)~>a quest is listed with its short description (`RT > RT-HOLDS`, CR.56). (<- S8; S1 § 12.4; S2 § 3.6) (-> PQ-24)~~} {++It shows the notifications of both classes of every team runtime (`RT > RT-PROTO`, CP.39), as the extension shows those of the windows on one machine (<- S23: vscimpb123, vscimpb124), and the team's reviews with the state of each round per member (`TAC > TAC-REVIEW`, CV.18), from which a returned copy or the consolidation is opened (CK.2). (<~ S8; S29: FQ-8)++}
- **CK.2** trc is a full remote control: more or less everything a runtime
  can do can be done through it. It queues todos and walks, starts and
  pauses runs and queues, continues processes (proceed, decide, gates),
  answers asks, and lets the user review documents with the review
  {~~component; the result goes back to the run that asked. What remote control covers and what it excludes is open (PQ-50), and so is whether trc contains the review component (PQ-43). (S2 § 3.6,
  FO-12; S8)~>component; the result goes back to the run that asked. What remote control covers and what it excludes is open (PQ-50), and so is whether trc contains the review component (PQ-43). (<- S2 § 3.6; S8) (-> FO-12)~~}
- **CK.3** Its focus is supervising team runtimes, not development work
  on one machine. What it adds to the components it is built from is the overview.
{~~  (S2 § 3.6, FO-12; S1 § 12.4)~>  (<- S2 § 3.6; S1 § 12.4) (-> FO-12)~~}
- **CK.4** A user supervises their own runtimes, or some of the team runtimes.
  The Solution Blueprint settles whether trc shows one team at a time or all of the user's teams side by side (`TAC > TAC-PEOPLE`, CI.12).
{~~  (S8; S2 § 3.6)
- **CK.5**~>  (<- S8; S2 § 3.6)
- **CK.5**~~} Remote control is possible only inside a team, and only for a
{~~  runtime whose host allows it by a setting. (S1 § 7.3, CQ-10)~>  runtime whose host allows it by a setting. (<- S1 § 7.3) (-> CQ-10)~~}
- **CK.6** trc is built from the Dart runtime client SDK and the Flutter
  components; {~~on a phone or a tablet from the Dart web runtime client SDK (CK.10). (S1 § 12.4; S2 § 3.6; PQ-28)~>on a phone or a tablet from the Dart web runtime client SDK (CK.10). (<- S1 § 12.4; S2 § 3.6) (-> PQ-28)~~}
- **CK.7** trc is a Webforge application from the start, beside Webwork, the
  quest application and the core Forge application. It also runs standalone,
  outside Tom Forge, first and for testing; it may depend on packages of Tom
  Forge. Tom Forge's shell builds for the desktop and for tablets and not for phones (planned), so the desktop and the tablet build of trc may use it, and the phone build does not (CK.10). {~~(S2 § 5, FO-12; S26: wwkit3, `decisions.tom_forge.md` forgeinv9)~>(<- S2 § 5; S26: wwkit3, decisions.tom_forge.md forgeinv9) (-> FO-12)~~}
- **CK.8** trc finds a team's team runtimes through tac, by the endpoints
  they publish, and attaches to each runtime's numbered events.
{~~  (S1 § 9, flow F10; S2 § 3.6)~>  (<- S1 § 9 flow F10; S2 § 3.6)~~}
- **CK.9** The open asks of a team, with their age, their place in the
  chain and the run that waits for each (CP.23), are {~~part of trc's view. (S1 § 6.6; PQ-24)~>part of trc's view. (<- S1 § 6.6) (-> PQ-24)~~}
- **CK.10** trc runs on the phone and the tablet in the first version, beside
  the desktop. On the desktop it has a runtime of its own that serves no
  quest (in which team such a runtime registers is open: PQ-51); on a phone or a tablet no runtime runs: it uses the web runtime client SDK and talks to a web runtime service on a server, which connects to a runtime on its behalf
  (`RT > RT-INSTALL`, CR.108). The architecture for applications on phones
  and tablets is part of the first version (`DEC`, D-51); no solution is given for it yet, and whether phones and tablets stay in the first version is one of the open points (PQ-49). Which runtime the service connects trc to, and so which runs a phone shows and steers, is open (PQ-38). The phone layout of trc is built from the phone-width screens of `tom_ai_runtime_ui` (`CLI > CLI-SCREENS`, CU.15), {~~without Tom Forge's shell (CK.7). (PQ-9; PQ-28; S26: wwkit3)~>without Tom Forge's shell (CK.7). (<- S26: wwkit3) (-> PQ-9, PQ-28)~~}
- **CK.11** A phone or tablet is used from
  the internet as well as from the local network or the VPN: looking at what
  is going on and answering questions while away is what the application is
  for. Every access from the internet is strict (`TAC > TAC-PEOPLE`, CI.10),
  and a device is paired first and gets a key of its own
  (`TAC > TAC-CRYPT`, CI.18). Which program a device reaches from the internet and which holds the device keys is open, and so is {~~how a phone whose application is not running learns of an ask (PQ-49). (PQ-9; PQ-28)~>how a phone whose application is not running learns of an ask (PQ-49). (-> PQ-9, PQ-28)~~}
- **CK.12** Whether the VPN can be used from an iPhone and from an Android
  device is checked by the quest `al_the_bear`, which runs the VPN, so that the application can be tried on the VPN before
  the access from the internet is opened. No todo for the check exists there yet {~~(`RISK > RISK-DEPS`, R-20). (PQ-9; S27)~>(`RISK > RISK-DEPS`, R-20). (<- S27) (-> PQ-9)~~}

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
  transport, the store and the tac server. {~~(S1 § 7.1)~>(<- S1 § 7.1)~~}
- **CA.2** Coordination and messaging both happen in a **team**
  (`TAC > TAC-PEOPLE`): its members message each other, and its members'
  runtimes, the **team runtimes**, coordinate
  (`TAC > TAC-PEOPLE > TAC-GROUPS`, CA.39). {~~(S5 § 3.2; PQ-23; S21, C-4)~>(<- S5 § 3.2; S21: C-4) (-> PQ-23, D-24)~~}

### <!--[TAC-COORD]--> 9.2 Coordination between runtimes

**Presence and discovery**

- **CA.3** A runtime registers with its team: its id, its kind, its
  machine, its workspace, the quest it serves (none for a runtime without a
  quest), the repositories it coordinates with the state of their clones,
  and the person it belongs to. The repositories are what the runtime says
  about itself, for the answer to who works where (`PAR > PAR-APPROACH`,
  CW.13, CW.16); they are not a list tac gives leases from (CA.42).
  {~~(S5 § 3.3; S1 § 7.3; PQ-23; CR.6)~>(<- S5 § 3.3; S1 § 7.3) (-> PQ-23, CR.6)~~}
  The Solution Blueprint settles what identifies a runtime: who generates its id and from what, and what a restarted runtime presents to find its leases (CA.8).
- **CA.4** A runtime is present while it holds its connection to the
  service. The service computes presence; no tac client writes it. {~~(S5 § 3.3,
  § 5.2)~>(<- S5 § 3.3, § 5.2)~~} This is stated for the local backend and the tac server; who computes presence on the GitHub backend, where no service stands between the machines, is open (PQ-47).
- **CA.5** A runtime keeps its current state with its registration — per
 run the process position, the number of open asks, of queue
  items needing attention and of reviews waiting, the run's state as CR.23 names it (which run waits or is held, for what — an ask, a lease, a secret, a time, a blocked todo — and since when; CP.23), and the executions under way
  — so a tac client that connects late shows the right picture at once.
  {~~(S5 § 3.3; PQ-24; S23: vscimpb123)~>(<- S5 § 3.3; S23: vscimpb123) (-> PQ-24)~~}
- **CA.6** Any team runtime can list the team runtimes with their
  presence and state. One quest may have several runtimes. {~~(S5 § 3.3, § 5.2)~>(<- S5 § 3.3, § 5.2)~~}
- **CA.7** Runtimes find each other through tac and nowhere else: on one
  machine, across the VPN, and through the relay beyond it. {~~(S2 § 3.4;
  S4, note c)~>(<- S2 § 3.4; S4: note c)~~}

**Who holds a lease**

- **CA.8** The runtime holds a lease, for the item it executes in one of its
  runs; the lease names its holder: the runtime, the quest, the run, the item, the machine and the workspace. tac keeps no record of the holder beside the lease. That identity outlives the runtime process: after a
  restart or a window reload the new process finds its leases unchanged, by the names on them.
  {~~(S5 § 3.4, § 4.3; S21, TQ-3; PQ-27)~>(<- S5 § 3.4, § 4.3; S21: TQ-3) (-> PQ-27)~~}

**Leases, resources and fencing tokens**

- **CA.9** A lease is held on resources. A resource's name starts with a prefix that says its kind; for now there is one, `git:`, for a whole repository or a part of a repository described by a pattern of paths (CA.41). Further prefixes are added as further kinds of resource are needed. What the protocol as built has beyond this is listed in E-19. {~~(S5 § 3.5 … § 3.7; S6, part-claims; PQ-23; PQ-31)~>(<- S5 § 3.5 … § 3.7; S6: part-claims) (-> PQ-23, PQ-31, D-68)~~}
- **CA.10** A repository is named by its identity at its repository server,
  never by a path on a machine, so the same repository is the same resource
  on every machine, whatever folder its clone lies in. The name is
  `git:<owner>/<repository>` when the team has one repository server, and in
  full (`git:<server>/<owner>/<repository>`, for example `git:github.com/al-the-bear/tom_ai_build`) when it has several; a part of a repository is `git:<owner>/<repository>#<pattern>`, for example `git:al-the-bear/tom_ai_build#tom_ai_runtime/**`; a runtime
  derives the repository's name from the clone's remote. {~~(S5 § 3.5; S21, TQ-8; PQ-31)~>(<- S5 § 3.5; S21: TQ-8) (-> PQ-31, D-68)~~} The details of the grammar — a name without a prefix from existing todos, a document of a quest in a multi-quest repository, one written form for every prefixed notation of the document — are open (PQ-45).{++ The extension plans a notation of its own for its leases, `<type>://<server>[:<port>]/<path>` with the types `git`, `git-release` and `named`; which notation the runtime takes is open as well (PQ-45, PQ-63). (<- S28: part-leases; S23: caf_01a, planned)++}

> **❓ PQ-45 (2026-11-25T20:05+01:00) — how resources and the other addressed things are written:** Which written form do resource names have — tac's `git:` names or the extension's planned `<type>://` notation — and which details does Phase 1 fix: old names without a prefix, quests in a multi-quest repository, the repositories a runtime registers, and one form for every addressed thing?
>
> **Context:** A **resource** is what a runtime can lease from tac so that two executions do not write the same files at once; it is named, never registered beforehand. The product owner answered PQ-31: "we may run into other types of resources in the future, but for now that is what we need. Using a prefix git:... we can have as many notations as needed and introduce them as they come." That is decision D-68. `TAC > TAC-COORD`, CA.9: "A resource's name starts with a prefix that says its kind; for now there is one, `git:`, for a whole repository or a part of a repository described by a pattern of paths." CA.10: "The name is `git:<owner>/<repository>` when the team has one repository server, and in full (`git:<server>/<owner>/<repository>`, for example `git:github.com/al-the-bear/tom_ai_build`) when it has several; a part of a repository is `git:<owner>/<repository>#<pattern>`, for example `git:al-the-bear/tom_ai_build#tom_ai_runtime/**`." CA.17: "A runtime claims a part of the `_ai` state's repository for a todo only when the todo names it among its resources (for example `git:al-the-bear/tom_agent_state#quests/ai_runtime/specification/**`)."
>
> The VS Code extension plans another notation for its own leases (idea `collab_and_features`, source S28; todo `caf_01a`, planned), which the product owner's instruction (a) of this round (D-74) makes part of the first version's baseline: `<type>://<server>[:<port>]/<path>[@<branch>][#<path>]`, for example `git://github.com/al-the-bear/tom_vscode#tom_vscode_extension/src/managers/`, with the types `git` (a repository, a part of it, or a branch of it), `git-release` (a release asset) and `named` (something that is no set of files, for example `named://pub.dev/tom_core`). Whether the runtime takes over the rest of that plan is PQ-63.
>
> Four further points the text does not settle:
> 1. **Old names.** Todos written today name resources without a prefix (`al-the-bear/tom_ai_build`) in the todo field `resources:`; a quest's list of what it usually works on (`RT > RT-LOCATIONS`, CR.35; `PAR > PAR-APPROACH`, CW.8) is written the same way.
> 2. **Quests in a multi-quest repository.** The standard for quests (S22) has a **multi-quest repository**: one repository holds several quests, each on a branch of its own (`quest/<id>`), checked out as a working tree at the quest's place. A resource name carries no branch, so `git:<owner>/<repository>#specification/**` would mean the same path in every quest of that repository.
> 3. **The repositories a runtime registers.** CA.3: "A runtime registers with its team: … the repositories it coordinates with the state of their clones"; nothing says whether they are written as resource names.
> 4. **The other notations.** Secrets are written `tsm:<reference>`, `os:<service>/<account>`, `env:<variable>`, `file:<path>` (`RT > RT-SECRETS`, CS.7); a message's address is `msg:tac/<team>/<messageId>` (`TAC > TAC-CONV`, CM.12); `PAR > PAR-CROSS`, CW.18 says "One way of addressing holds on one machine and across machines: a todo as quest and todo id, a run as quest and run, a session, a user", with no written form.
>
> **Why I ask:** The name is what todos, the queue, the coordination page and tac compare when they decide whether two executions may run at the same time, so a todo written today must still be understood when `tac/2.0` exists, and two notations for one repository would let two programs miss each other's leases. If old names are refused, every existing todo's resources need rewriting; if a multi-quest repository's quests cannot be told apart, a lease on one quest's specification blocks the same path in every other quest of that repository.
>
> - (a) tac's notation as CA.10 states it, and nothing more fixed now: an old name without a prefix is refused; the multi-quest case, the registered repositories and the other notations are left to the Solution Blueprint; the extension's `<type>://` notation is not taken.
> - **(b)** tac's notation, as one written form `<scheme>:<body>` for everything addressed. Resources: `git:` as in CA.10; a name without a prefix in an existing todo is read as `git:`; a quest of a multi-quest repository is named with its branch after the repository, `git:<owner>/<repository>@quest/<id>#<pattern>`, and names with different branches never overlap; the repositories a runtime registers are written as resource names; further kinds of resource get further schemes as D-68 says (the extension's `git-release` and `named` would become, for example, `release:` and `name:`). The addresses of CW.18 get the same form (`todo:<quest>/<id>`, `run:<quest>/<run>`, `user:<id>`), beside `tsm:`, `os:`, `env:`, `file:` and `msg:`. The extension's `<type>://` notation is not taken; the extension, if it builds its leases before the runtime, writes tac's names.
> - (c) The extension's notation `<type>://<server>[:<port>]/<path>[@<branch>][#<path>]` replaces CA.10's, as the one notation of todos, claims and leases: the branch part settles the multi-quest case, `git-release` and `named` are further types; D-68 is replaced; old names without a prefix are read as `git://<server>/<owner>/<repository>`.
>
> *Recommendation:* (b) — D-68 already decided the prefix form, it answers the four open points with one rule, it gives CW.18's "one way of addressing" a written form, and the extension's branch and named resources fit into it as further schemes without a second syntax.
>
> *Assumption until answered:* the text writes resource names with `git:` as CA.10 says; CA.10 records that the extension plans its own notation; CA.17's example is a classic quest in the `_ai` state's repository; CS.7, CM.12 and CW.18 keep their own forms.
>
> **Answer:**

- **CA.11** Two `git:` resources **overlap** when they name the same repository and
  one is the whole repository, or when they name parts of one repository
  whose patterns can match the same path; resources with different prefixes never overlap. A lease is **exclusive** or
  **shared**: tac gives no exclusive lease on a resource that overlaps a
  leased one, and no lease at all on one that overlaps an exclusively leased
  one. Resources overlap only within one team.
  {~~(S5 § 3.5, § 3.7; PQ-23; CA.42; PQ-31)~>(<- S5 § 3.5, § 3.7) (-> PQ-23, PQ-31, CA.42)~~} By this rule the exclusive lease that worktree mode takes on the whole repository for the integration step (`PAR > PAR-APPROACH`, CW.5; F8) can never be given while another execution holds a shared lease on a part of it; the lease rules are open (PQ-46).{++ The extension plans leases of its own, kept as one table per repository in that repository's remote and stale after 30 minutes; whether the runtime takes them over is open (PQ-63). (<- S28: part-leases; S23: caf_04a, planned)++}

> **❓ PQ-63 (2026-11-25T20:05+01:00) — the extension's own collaboration plan against tac:** Which parts of the VS Code extension's planned collaboration and feature tools does the runtime take over in its first version, and which are replaced by tac's leases, worktree mode and integration step?
>
> **Context:** The product owner's instruction (a) of this round (decision D-74, `DEC`) makes the VS Code extension's features — built and planned — part of the first version of the runtime: "A feature of that baseline is in the first version unless a decision puts it out of scope or later." On 2026-11-23 and 2026-11-24 the extension's quest planned a large set of its own collaboration tools, the idea `collab_and_features` (source S28, 76 todos `caf_*` in the extension's todo file S23; none of them is built yet). Its idea document says of itself: "This idea is built in the extension now and depends on none of the agent-collaboration todos in the ai_runtime quest … TAC may later replace parts of it." What it plans:
> 1. **Leases in the git remote** (`caf_04a`): every repository with leases has one ref `refs/tom-leases/table` whose commit message is a table of leases as JSON; a lease is taken by compare-and-swap on that ref, renewed, released, and **stale after 30 minutes**; leases are switched on or off per quest; a quest with leases off only checks and waits, with a *Proceed anyway* button (`caf_04b`); an agent can claim more during a turn, waiting at most 15 minutes (`caf_04c`).
> 2. **A resource notation** `<type>://<server>[:<port>]/<path>[@<branch>][#<path>]` with the types `git`, `git-release` and `named` (`caf_01a`).
> 3. **Feature branches and worktrees** (`caf_06a`, `caf_06b`): branches `todo/<id>`, `group-todo/<id>`, `feature/<id>`, worktrees `<folder>@<branch>` beside the main clones, a merge tool with a review gate, three development models per feature (main only, feature branches strict, feature branches free).
> 4. **Agent groups** (`caf_05a` … `caf_05e`): runs of one person form a group with one **supervisor** run and **collaborators**, six exchange tools between them, a supervisor loop that pings every 2 minutes for unanswered exchanges and may answer for the user, an AGENT COLLABORATION view.
> 5. **Features** (`caf_07a` … `caf_07f`, `caf_01a` … `caf_01d`): a feature is a group todo of group todos in phases (todo fields `featureId`, `featurePhases`, `partOfFeature`, `useFeatureBranch`, `leasesAlways`, `review`); the extension builds a **feature run** per quest the feature touches and moves it phase by phase with two queue items, *Wait for notifications* and *Notify*; a coordinator role, Replan and Retry.
> 6. **Standard runs** (`caf_03b` … `caf_03h`): every quest has the runs `default`, `planning` and `quest-keeper`; an item queued by a running item goes right after it; queuing by hand into `planning` or a running feature run asks for confirmation; `quest-keeper` reads the quest once and holds the quest's `defaultResources`.
> 7. **Reviews** (`caf_08a`, `caf_08b`): a group whose review is on ends with a review todo run in a fresh session by a reviewer role; a failed review files rework todos; after three failed rounds the user is asked.
> 8. **The issue flow** (`caf_10a` … `caf_10g`): incoming, accepted and verified issues in the todo side panel, an `issue2feature` process, closing after 14 days.
> 9. **Views**: AGENT COLLABORATION, RESOURCE LEASES, FEATURE BRANCHES, BRANCH LOG, FEATURE EXPLORER, WORKSPACE REPOS, the issue views; the system aspects `agent_role` and `feature_branches`.
>
> The Project Idea states something else for the same ground. `TAC > TAC-COORD`, CA.8 … CA.17: a runtime holds a **lease** from tac for the item it executes; "Not renewed for 60 minutes, it is **stale**"; "Every lease given on a resource carries a **fencing token**, a number that only grows per resource"; CA.10 (decision D-68): resources are named `git:<owner>/<repository>` and `git:<owner>/<repository>#<pattern>`. `PAR > PAR-APPROACH`, CW.2: "Whether executions work in a working tree of their own is a setting per repository that the team decides" (**strict mode** without, **worktree mode** with); CW.5 and CW.6: an **integration step** (rebase, the repository's checks, fast-forward, push) in a serial **integration queue** per repository kept by tac; CW.15: "Review happens without pull requests … a review agent that starts without the execution's context gets only that difference". `DEC`, D-24: "there is no 'agent group' as a thing of its own"; a **team** is a group of users, and its members' runtimes coordinate in it. `RT > RT-HOLDS`, CR.9: every quest has the run `default`; no other standard run is named. A **run** is a process position of a quest with its own queue lane.
>
> Decision D-73 (this round) adds: the extension is copied into `tom_ai/ai_build` as the new extension, which has to work "with all features working as before (only distributed and with a team)"; whatever the old extension builds of `collab_and_features` before the copy point is therefore a feature the new extension must have.
>
> **Why I ask:** By D-74 the plan belongs to the first version, but as planned it duplicates and contradicts what tac is specified to do: two kinds of lease (a table in each repository's remote with 30 minutes, and tac's leases with fencing tokens and 60 minutes), two notations for the same repository, two branch models, and agent groups that D-24 excludes. The Solution Blueprint cannot specify both. The answer decides what `tac/2.0` must offer, which `caf_*` todos are built in the old extension before the copy point and which wait for the runtime, whether the todo model gets the feature fields, which standard runs every quest has, and whether D-24 is reopened.
>
> - (a) Carry the plan into the runtime as it is: the lease table in each repository's remote becomes one more tac backend beside local, GitHub and the tac server; its notation replaces D-68's; agent groups with a supervisor become runtime items, which reopens D-24; features, standard runs, reviews and the issue flow become runtime capabilities.
> - **(b)** Take over the plan's run and feature concepts — features (group todos of group todos in phases, feature runs per quest with *Wait for notifications* and *Notify*), the standard runs `planning` and `quest-keeper`, review todos with rework, the issue flow — as runtime capabilities written into `RT` and `PAR`, and keep tac for leases, branches and the integration step (CA, CW): the extension's lease table, branch names and merge tool are replaced by tac's leases with fencing tokens, worktree mode and the integration queue. There are no agent groups (D-24 stands): what a supervisor and its collaborators exchange becomes asks and messages routed between runs (CP.17, CP.18, CA.18). One resource notation serves todos, claims and leases; which one is PQ-45. The `caf_*` todos for leases, branches and the merge tool are not built in the old extension, or are built there only as a stopgap that the new extension does not carry over.
> - (c) None of it in the first version: the plan stays the old extension's own, recorded as input (S28); the runtime has only what the Project Idea states today, and the new extension leaves out what the old one built of it — an exception to D-73's "every feature as before" that a decision must record.
>
> *Recommendation:* (b) — features, standard runs, reviews and the issue flow add capabilities the Project Idea lacks and fit its runs and todos; leases, branches and integration exist once, in tac, where they work across machines and teams with fencing tokens; and D-24, decided on purpose, stays.
>
> *Assumption until answered:* no `caf_*` feature is written as a runtime item; CA.10 and CA.11 say that the extension plans a notation and leases of its own and that this is open (PQ-45, PQ-63); `CON` records the conflict (X-22).
>
> **Answer:**

> **❓ PQ-46 (2026-11-25T20:05+01:00) — the lease rules: integration lease, fencing at the push, and the extension's lease table:** How does the integration step of worktree mode get its lease while others work in the same repository, who checks the fencing token when the result is pushed to a repository server that knows no token, and do tac's leases or the extension's planned lease table in the repository's remote hold them?
>
> **Context:** A **lease** is a runtime's right on a resource (a repository or a part of one) for the item it executes; a **claim** asks for leases on all the resources a todo names, or none. `TAC > TAC-COORD`, CA.11: "A lease is **exclusive** or **shared**: tac gives no exclusive lease on a resource that overlaps a leased one, and no lease at all on one that overlaps an exclusively leased one." Two resources overlap when they name the same repository and one is the whole repository, or parts whose path patterns can match the same path. CA.13: "Not renewed for 60 minutes, it is **stale** … only a person frees it." CA.14: "Every lease given on a resource carries a **fencing token**, a number that only grows per resource … a write it still attempts with its old token is refused." **Worktree mode** is the way of working in which each execution has its own working tree on its own branch; `PAR > PAR-APPROACH`, CW.5: "In worktree mode an execution holds a **shared lease** on what it works on … and takes an **exclusive lease** on the repository only for the integration step. The integration step is: rebase the execution's commits onto the branch the record names for the repository, run the repository's checks, fast-forward that branch, push. The fencing token is checked at the push." CW.6: "Every repository has an **integration queue**. tac keeps its order, and it is serial." Flow F8 (`NFR > NFR-TOPO > NFR-TOPO-FLOWS`): each execution "when its todo is done … takes the repository's exclusive lease for the integration step, rebases, runs the checks, fast-forwards the main branch and pushes; the next one rebases first".
>
> Two sources add options. This quest's coordination idea (S6, part-branches-and-worktrees; todo `ww_g_collab-1`, planned) puts the token into the merge commit as a trailer, `Tac-Fence: <token>`, so the token travels with the push and can be checked afterwards. The VS Code extension plans leases of its own (S28, part-leases; todo `caf_04a`, planned), part of the first version's baseline by the product owner's instruction (a) (D-74): one ref `refs/tom-leases/table` in each repository's remote whose commit is the table of that repository's leases; a lease is taken by compare-and-swap on that ref (the push fails when someone else moved the ref since it was read), stale after 30 minutes, released by rewriting the table; there is no fencing token. Whether the runtime takes over that plan at all is PQ-63.
>
> **Why I ask:** Read together, the rules contradict each other twice. First, the whole repository overlaps every part of it, so while any other execution holds a shared lease in the repository, CA.11 never gives the exclusive lease on the whole repository: the integration step of F8 — the flow worktree mode exists for — can never start. Second, the push goes to the repository server (GitHub), which knows no fencing token, so nothing refuses a push by a holder whose lease was freed; no item says who checks the token. A third point follows from the baseline: the extension's lease table would be a second, incompatible lease store for the same repositories. Two neighbouring points are open too: what happens when the integration step fails (a rebase conflict or a failing check after the item itself is done), and whether a running fleet reconcile (the workspace's sync of all machines, started by the user, during which no one may push) is something tac knows, so that integrations wait for it.
>
> - (a) Two kinds of lease, a changed order: an execution in worktree mode gives up its shared lease when its todo is done and then waits for the exclusive lease on the whole repository, which it gets once no one else holds a lease there. The runtime checks the token with tac immediately before the push. Simple; with steady work in a repository an integration may wait long.
> - **(b)** A third kind, the **integration lease**, and the rules as one table. An integration lease on a repository coexists with shared leases on it and excludes another integration lease and any exclusive lease on an overlapping resource, so the integrations of one repository happen one after another, in the order of the integration queue. The text gets one matrix (lease asked for: shared, exclusive, integration; already held on an overlapping resource: nothing, shared, exclusive, integration; each cell given or refused) and one line per mode (strict mode: an exclusive lease for the whole execution; worktree mode: a shared lease while working, an integration lease for the integration step). The runtime checks the token with tac immediately before the push and writes it into the integrated commit as the trailer `Tac-Fence: <token>`, so a push with an old token can be found afterwards; the short window between check and push is named as a risk. A failed integration step leaves the execution's branch and working tree as they are and puts the item into "needs attention" in its run, with the reason. A running fleet reconcile shows in tac as an exclusive lease on the repositories it walks. Leases are tac's on every backend; the extension's lease table in the repository's remote is not taken, and on the GitHub backend tac's own refs in the coordination repository carry the leases.
> - (c) No lease for the integration step: the integration queue alone orders the integrations, the shared leases stay; the fencing token is used only in strict mode.
> - (d) The extension's model: leases are kept as a table in each repository's own remote, taken by compare-and-swap on its ref, stale after 30 minutes; the compare-and-swap replaces the fencing token, and an integration is the holder of the whole repository in that table. tac keeps no leases; CA.8 … CA.16 are rewritten for this model and D-68's names are mapped onto it.
>
> *Recommendation:* (b) — it lets F8 happen, keeps integrations of one repository strictly one at a time, makes `tac/2.0` testable from one table, states honestly how far a fencing token protects a push to a server that does not know it, and keeps one lease store across all three backends.
>
> *Assumption until answered:* CA.11, CA.13, CA.14, CW.5 and F8 keep their text; CA.11 says the lease rules are open and that the extension plans leases of its own (PQ-63); CA.14 says the check at the push is open.
>
> **Answer:**

- **CA.12** A **claim** is the attempt to get leases: it is answered with
  leases on all the resources it names, or with none. When one is held, the
  answer names the holders. {~~(S5 § 4.1, § 6.2; S6,
  part-claims)~>(<- S5 § 4.1, § 6.2; S6: part-claims)~~}
- **CA.13** A lease is renewed while its execution works. Not renewed for 60
  minutes, it is **stale**. A stale lease is only shown: no service and no
  tac client takes it over, and only a person frees it. Its resources stay leased
  until then. {~~(S5 § 4.1, § 4.2; S6, BP-11)~>(<- S5 § 4.1, § 4.2; S6: BP-11)~~}
- **CA.14** Every lease given on a resource carries a **fencing token**, a number
  that only grows per resource. Freeing a lease raises the tokens of its
  resources. A holder whose lease was freed finds out at its next check, and
  a write it still attempts with its old token is refused. {~~(S5 § 3.8, § 4.2)~>(<- S5 § 3.8, § 4.2)~~} Who checks the token at the integration step's push, which goes to a repository server that knows no token, and how that push is refused, is open (PQ-46).
  The Solution Blueprint settles: how often a lease is renewed; how long a claim waits and whether it times out; in which order waiting claims are served, and whether an exclusive claim can starve while shared leases keep coming; what a runtime does when its lease was freed under it; and what becomes of the leases of a runtime that ends in the middle of an execution.
- **CA.15** Times that decide about leases and presence are the service's
  clock, never a tac client's, so a machine with a wrong clock can neither keep
  a lease fresh nor make one go stale. {~~(S5 § 4.4)~>(<- S5 § 4.4)~~} Stated, like CA.4, for the local backend and the tac server; whose clock decides on the GitHub backend is open (PQ-47).
- **CA.16** Resources are not declared anywhere beforehand: a part of a
  repository exists for tac from the moment it is claimed until its lease is
  released (CA.42). {~~(PQ-23; E-19)~>(-> PQ-23, E-19)~~}
- **CA.17** Todo state and journals are not claimed: the todo files, the process state and the progress file are written by many sessions at once, by design, and the per-host files — sessions, the trail, the journal of asks and answers — are each written by one host. A runtime claims a part of the `_ai` state's repository for a todo only when the todo names it among its resources (for example `git:al-the-bear/tom_agent_state#quests/ai_runtime/specification/**`); todo state and journals are never named. The files of a repository quest are named by the quest's own repository; how a document of a quest in a multi-quest repository is named is open (PQ-45). {~~(S6, part-claims; PQ-31; S22 § 2.2, § 3.2)~>(<- S6: part-claims; S22 § 2.2, § 3.2) (-> PQ-31, D-68)~~}

**Messages between runtimes**

- **CA.18** {~~A runtime sends a message to all quests of its team or to named
  quests.~>A runtime sends a notification to all quests of its team or to named quests; a command names its target quests, never all of them, and may prefer a machine: while a runtime of a target quest is present on that machine, the command is delivered there only. A notification is not delivered back to the runtime that sent it; a command is, since it may target another run of the sender's own quest.~~} The service routes by the target and never reads the type or the
  payload; the meaning of a type is the tac clients' convention. {~~(S5 § 3.9;
  S6, part-messages)~>(<- S5 § 3.9, § 11 items 6 and 16; S6: part-messages; S30: ww_f_collab-1, planned)~~}
- **CA.19** A **notification** is live only: it reaches the runtimes
  connected at the time and is not stored. A **command** is stored for 7
  days with a delivery state per target quest; the first runtime of that
  quest that acknowledges it takes it, with the outcome taken, refused (with
  a reason) or filed. Until a run there takes it, it waits at the sender and is shown there with what it waits for (`PAR > PAR-CROSS`, CW.19). {~~(S5 § 3.9, § 5.6)~>(<- S5 § 3.9, § 5.6)~~}
  The Solution Blueprint settles what happens to a command nobody took within its 7 days.
- **CA.20** The notifications runtimes send each other: the process position
  moved; something worth telling the user; an ask started or stopped
  waiting; a queue item needs attention; a review waits; a todo was created,
  started, completed, blocked or unblocked; a runtime came online or went
  offline; an execution started or ended; {~~a lease is waited for or was
  released.~>a lease is waited for or was released; a repository could not be brought up to date (`PAR > PAR-APPROACH`, CW.16); the team's configuration or a backend's limits need attention.~~} A released lease wakes the runtimes that wait for it. {~~(S6,
  part-messages; PQ-27)~>(<- S6: part-messages; S30: ww_f_collab-1, planned) (-> PQ-27)~~}
- **CA.21** What a todo names for its completion in another quest, or in
  another run, travels as a command to that quest's runtime. {~~(S6,
  part-messages; S1 § 7.4)~>(<- S6: part-messages; S1 § 7.4)~~}
- **CA.22** A tac client shows a type it does not know by the one-line summary
  every payload carries, so a new type never breaks an older tac client. {~~(S6,
  part-messages)~>(<- S6: part-messages)~~}

**Endpoints**

- **CA.23** A runtime publishes the endpoints it serves — its MCP server,
  its remote control — with the address, where the address can be reached
  from (the machine, the VPN, the public network), the protocol with its
  version, and how to authenticate, never a secret. The other team runtimes
  list them. {~~(S5 § 3.10; S1 § 6.4)~>(<- S5 § 3.10; S1 § 6.4)~~}
- **CA.24** An endpoint exists only while its runtime is present. The
  registry says where an endpoint is; the endpoint itself checks who may use
  it. {~~(S5 § 3.10)~>(<- S5 § 3.10)~~}

### <!--[TAC-BACKENDS]--> 9.3 Backends and modes

- **CA.25** tac is a reusable component of its own: the service and its
  tac client SDKs can be used without the runtime. {~~(S1 § 7.2, CQ-15)~>(<- S1 § 7.2) (-> CQ-15)~~}
- **CA.26** {~~A workspace names its backend, one of three, in its workspace
  configuration for coordination (S1 § 7.2; S5 § 6.1; S6,
  part-client-and-backends):~>A workspace names its backend, one of the three below, in its workspace configuration for coordination, the versioned file `agent.workspace.yaml` at the workspace root with a JSON schema: the backend, the team, and the repositories the workspace coordinates and those it brings up to date (`PAR > PAR-APPROACH`, CW.16). Every kind of runtime reads it. (<- S1 § 7.2; S5 § 6.1; S6: part-client-and-backends, BP-21, BP-22; S30: ww_c_collab-3, planned)~~}

  | Backend | For | What it offers |
  | --- | --- | --- |
  | **local** | one machine and one user; it works on that machine only | everything except accounts and quotas; the service is started by the first tac client that needs it and runs once per machine and user |
  | **GitHub** | one user's machines, or a simple team of several members | leases and endpoints as refs in a coordination repository; no messages across machines — messages go through each machine's local service |
  | **tac server** | a team, or several | everything, independent of git: accounts, access keys, quotas, an administration interface |

  All three are part of the first version. On the GitHub backend a team — a user's personal team across that user's machines, or a simple team of several members — shares leases and endpoints through the coordination repository. {~~(PQ-10; PQ-29)~>(-> PQ-10, PQ-29, D-47, D-66)~~}
  Without a tac server nothing else travels between machines: no commands between runtimes, and so no item or walk sent to a run on another machine (CW.20), no blockers or done notifications across machines (CW.21, CW.23); no ask routed to another device or to the next person in its chain (CP.17, CP.18); no todo offers (CW.26, CA.44); no messaging, documents or review exchange (`TAC > TAC-CONV`, `TAC > TAC-DOCS`, `TAC > TAC-REVIEW`); no reminders (CM.4). What else a team on the GitHub backend has, capability by capability, is open (PQ-47).
  The GitHub backend's credential is named by a secret reference like every other (`RT > RT-SECRETS`, CS.7) and has rights on the coordination repository only, never on the whole account. A coordination repository created for a team is created private and with GitHub Actions switched off. The fleet plans its coordination repository `al-the-bear/tom_coordination` with a fine-grained token per machine, scoped to that one repository and kept in an environment variable the backend reads, which is the `env:` form of CS.7, marked as not secure {~~(S27: al_the_bear `14_loose_wslayout-4_akto-coordination-repo-and-tokens`, planned)~>(<- S27: al_the_bear `14_loose_wslayout-4_akto-coordination-repo-and-tokens`, planned)~~}.

> **❓ PQ-47 (2026-11-25T20:05+01:00) — a team on the GitHub backend: what it has, and who is a member and a team owner:** Which of tac's capabilities does a team that coordinates through the GitHub backend, without a tac server, have; are its leases kept in one coordination repository or in each repository's own remote; and who is a member and who is a team owner of such a team?
>
> **Context:** tac has three backends. `TAC > TAC-BACKENDS`, CA.26: the **local** backend serves "one machine and one user; it works on that machine only"; the **GitHub** backend serves "one user's machines, or a simple team of several members" and keeps "leases and endpoints as refs in a coordination repository; no messages across machines — messages go through each machine's local service"; the **tac server** offers "everything, independent of git". A **coordination repository** is a git repository on GitHub that the team's runtimes use as their shared store; whoever may push to it can write every ref in it. The product owner answered PQ-29: "The git-based tac service must support simple teams of multiple members, too, besides a single-member personal team, the local implementation works only on a single machine." (decisions D-47, D-66). The text says: "Without a tac server nothing else travels between machines: no commands between runtimes, and so no item or walk sent to a run on another machine (CW.20), no blockers or done notifications across machines (CW.21, CW.23); no ask routed to another device or to the next person in its chain (CP.17, CP.18); no todo offers (CW.26, CA.44); no messaging, documents or review exchange; no reminders (CM.4)." A **command** is a stored message between runtimes that the first runtime of the target quest takes (CA.19).
>
> Presence and time. CA.4: "The service computes presence; no tac client writes it", and CA.15: "Times that decide about leases and presence are the service's clock, never a tac client's" — both stated for the local backend and the tac server. For the GitHub backend the protocol as built (S5) already fixes them: § 10: "`renewedAt` of a lease and `presenceRenewedAt` of a runtime are the committer dates GitHub assigns to the commits of the session and runtime refs. A lease's staleness is computed from its session ref's last commit"; § 11 item 11: presence lasts "on GitHub, 60 minutes after the last renewal"; § 6.1: presence is "renewed with the lease renewals (at least hourly)". The GitHub backend runs in each runtime's tac client, which keeps within GitHub's rate limits (CA.45, from S5 § 6.3).
>
> Where the leases lie. CA.26 and S5 § 10 keep a team's leases in one coordination repository, one ref per coordinated repository. The VS Code extension plans another place (S28, part-leases; todo `caf_04a`, planned; part of the first version's baseline by instruction (a), D-74): a lease table as a ref `refs/tom-leases/table` in **each leased repository's own remote**, so that no extra repository is needed; whether the runtime takes over that plan at all is PQ-63.
>
> People. The rules are written for a tac server. `TAC > TAC-PEOPLE`, CI.5 lists what a member and a **team owner** may do: only a team owner may "free a stale lease" of anyone, "invite a person, remove a member", "make a member a team owner", "change the team's configuration and settings" and "delete the team". CI.6: "A person joins a team by invitation: … The tac server creates the participant with a user id it generates itself … and returns the team token." CI.9: "A team owner removes a member, and the tac server then refuses that member's token." CI.20: "On a tac server a team belongs to an account." `RT > RT-CONFIG`, CS.4: "Only a team's owners change the team's configuration."
>
> **Why I ask:** For a personal team across one user's machines, "no messages across machines" costs little; for a team of several members it means a member's runtime cannot send an item to a colleague's quest, an ask cannot reach the colleague who owns the quest, and no document can be sent for review. Either those capabilities stay with the tac server, or the coordination repository carries more. The extension's per-repository tables would remove the coordination repository but put lease data into every project repository and need write access to each. And every right of CI.5 assumes a service that checks a token; with a repository instead, "only a team owner may" can be enforced only by the repository server's permissions, or by agreement. The answer decides `tac/2.0`'s GitHub binding, what a user is told when choosing a backend, topology T4, what a team on the GitHub backend records, and what a move to a tac server (CA.33) carries.
>
> - (a) A team on the GitHub backend shares leases and endpoints only, in one coordination repository; everything else needs a tac server. Presence and staleness as S5 fixes them. Membership is push access to the coordination repository; every member has every right of CI.5; no team owners, invitations or team tokens.
> - **(b)** One table of capabilities per backend in the text — rows: presence, leases, the integration queue, endpoints, commands between runtimes, messaging, documents and review exchange, routing of asks to other people, the team's configuration, remote control, who is a member and an owner; columns: local, GitHub (personal team), GitHub (team of several), tac server; cells: yes, no, or by agreement. The GitHub column for a team of several carries leases, endpoints, the integration queue and commands between runtimes as refs in **one** coordination repository (so items, blockers and done notifications travel between members' quests), but not messaging, documents, review exchange or asks routed to other people. Presence and staleness are as S5 fixes them: the committer time GitHub gives a push, presence for 60 minutes after the last renewal; CA.4 and CA.15 say so for this backend. The coordination repository holds a small record of the team — its name, its members by user id and e-mail address, and which of them are team owners — changed by team owners; the runtimes follow it and refuse an action of CI.5 their user's role does not allow; these are agreements the runtimes keep, not something a service enforces, and the text says so. No invitation and no team token: a person becomes a member when a team owner adds them to the record and they have push access. The extension's per-repository lease tables are not taken. Moving the team to a tac server carries the record as its member list.
> - (c) A team of several members needs a tac server: the GitHub backend serves only a user's personal team across that user's machines; every rule about people stays with the tac server.
> - (d) As (b), but the leases are kept as the extension plans them, in each leased repository's own remote; the coordination repository keeps only the team's record, endpoints and commands.
>
> *Recommendation:* (b) — a table makes the backend choice decidable for a user and testable for `tac/2.0`; S5 already fixes presence and time; commands as refs keep the cross-quest work a team needs most; one coordination repository keeps lease data out of the project repositories and needs write access to one repository only; and the record gives the roles of a tac server without claiming a security the repository cannot give.
>
> *Assumption until answered:* the text says that a team on the GitHub backend shares leases and endpoints through the coordination repository and that what else it has is open; CA.4 and CA.15 are stated for the local backend and the tac server; CI.5 … CI.10, CI.14, CI.15, CI.20 and CS.4 are stated for a tac server.
>
> **Answer:**

- **CA.27** The tac server is the full tac server from the start: accounts, access
  keys kept as salted hashes, quotas per account, the administration
  interface. An **account** is whoever the tac server serves, an organisation or
  a single person; it has several
  teams and many users. {~~A small team's tac server is the same tac server with one
  account.
  (S1 § 7.2, CQ-9; S5 § 3.1, § 3.12; E-19)~>A small team's tac server is the same tac server with one account. Its quotas count at least the resources leased and the calls per hour. It listens on the VPN only unless its administrator opens it; whatever it serves from the internet is strict (`TAC > TAC-PEOPLE`, CI.10). (<- S1 § 7.2; S5 § 3.1, § 3.12; S6: IDEA-16, BP-5; S30: ww_g_collab-2, planned) (-> CQ-9, E-19)~~}
- **CA.28** The tac server runs long, without the idle stop of the local
  service, with the same store and configuration. Encryption in transit ends
  at a reverse proxy in front of it; the service itself stays without
  dependencies. It can answer tac clients in a browser (cross-origin requests; in a
  browser the access key travels as the WebSocket subprotocol): a capability kept for services that use tac directly later (`SCO > SCO-LATER`, L-12); no application of the first version uses it, since every application reaches tac through its runtime (`TAC > TAC-PEOPLE`, CI.4). {~~(S1 § 7.10;
  S5 § 9; PQ-30)~>(<- S1 § 7.10; S5 § 9) (-> PQ-30)~~}
  The fleet's plan for its tac server on the always-on machine differs: a service run from that machine's clone, reachable on the VPN only (bound to its VPN address), under a system user of its own, its keys in an environment file outside the repository. The plan does not know the accounts and the relay and is to be rewritten against CA.27 … CA.30 (`RISK > RISK-DEPS`, R-20). A reverse proxy with certificates for HTTP and WebSocket exists on that machine. {~~(S27: al_the_bear `14_loose_wslayout-6_akto-coordination-server-on-bigbeast`, planned; `tsmfleet3`, `tsmfleet9`, completed)~>(<- S27: al_the_bear `14_loose_wslayout-6_akto-coordination-server-on-bigbeast`, planned; `tsmfleet3`, `tsmfleet9`, completed)~~}
- **CA.29** A quota never blocks giving something back: releasing a lease,
  {~~deregistering,acknowledging~>deregistering, acknowledging~~} a command, withdrawing an
  endpoint, or renewing a lease already held. {~~(S5 § 3.12; PQ-27)~>(<- S5 § 3.12) (-> PQ-27)~~}
- **CA.30** The **relay** is part of the tac server. It carries TAC and MCP for
  machines that are not on the VPN and only forwards. A machine
  authenticates to it with a key per runtime that an owner of the team
  issues. What comes through the relay comes from the internet: it is strict
  and from a paired device (`TAC > TAC-PEOPLE`, CI.10; `TAC > TAC-CRYPT`,
  CI.18). How the key per runtime and the paired device's key relate is part
  of the open point for the security model (CI.19).
  {~~(S1 § 7.2; S2 § 5, FO-9; S4; PQ-9, PQ-13)~>(<- S1 § 7.2; S2 § 5; S4) (-> FO-9, PQ-9, PQ-13)~~}
- **CA.31** With coordination switched off (`mode: off`, the default)
  nothing is coordinated and everything works as it does without tac.
  {~~(S1 § 7.2; S6, IDEA-6)~>(<- S1 § 7.2; S6: IDEA-6)~~} What "off" switches off, while machine-wide state is routed through the local tac service (`RT > RT-MACHINE`, CR.38) and every runtime registers with it (CA.34), what the local tac service is, and whether messaging can be on while coordination is off, is open (PQ-48).

> **❓ PQ-48 (2026-11-25T20:48+01:00) — what "coordination off" switches off, and what the local tac service is:** With coordination switched off by default, does the local tac service still run on every machine — given that the runtime's machine-wide state is routed through it — and what does a runtime do without it?
>
> **Context:** The **local tac service** is the tac service in local mode: one process per machine and user, on the machine's loopback address. The service as built (S5; `tom_ai/vscode/tom_tac_service`) has a function `ensureLocalService()` with which a tac client finds the running service or starts it as a detached process of its own (the port is the lock; two starts at once, a foreign process on the port and a service of another major version are handled); this quest's todo `ww_c_collab-3` (planned) has the runtime start the service this way when none runs. `TAC > TAC-BACKENDS`, CA.26: the local backend "is started by the first tac client that needs it and runs once per machine and user". CA.31: "With coordination switched off (`mode: off`, the default) nothing is coordinated and everything works as it does without tac." But other items route things through that service unconditionally. Decision D-13: "The runtime owns machine-wide state; its implementation routes through the local tac service." `RT > RT-MACHINE`, CR.38: "Inside the runtime there is one interface to this state [the machine-wide state: queue settings, the inbox, notifications, presence] with two implementations: through the local tac service, which runs once per machine and user and through which every runtime's access is routed, so concurrent access is handled in one place; and through files, one key at a time under a file lock, when coordination is switched off." CR.39: "The local tac service outlives a single runtime and carries the state from one to the next." CA.34: "Every runtime also registers with the local service of its machine, whatever its backend." Topology T1 (the simplest setup): "One runtime per window, inside the new VS Code extension …; the local tac service once for the machine and user (the local backend serves this one machine only; what the local tac service does with coordination switched off: PQ-48)." The workspace's coordination settings are the file `agent.workspace.yaml` at the workspace root (CA.26), which names the backend; `off` is not one of the three backends. CA.32: "When the backend cannot be reached … the runs of the team runtimes are held after their current item." Webwork's own AI takes no claims and only uses messaging; when the tac server cannot be reached, its messaging area "keeps the cached history read-only, says why, and keeps outgoing messages in the outbox" (webwork idea `webwork_redesign`, part-messaging). Nothing says who installs and updates the local tac service, what happens to machine-wide state when it crashes, how it checks the versions of runtimes of different versions, or how state moves between the file implementation and the service when coordination is switched on or off.
>
> **Why I ask:** If "off" is the default and the files are used then, the default installation never runs the local tac service, T1 is wrong and D-13's routing never happens; if the service always runs, "off" switches off only the claims and the other machines. It also decides whether Webwork's messaging can be used without coordination, and whether a messaging-only runtime's queues stop when the tac server is away.
>
> - (a) "Off" switches tac off completely: no local tac service runs, machine-wide state is in files, nothing registers; T1 and D-13's routing are corrected to say so; messaging needs coordination on.
> - **(b)** Two settings, not one. The local tac service always runs: installed and updated with the runtime installation, started by the first runtime of the machine with `ensureLocalService()`, version-checked against each runtime on connect, its state on disk so a crash loses nothing and it restarts with the next runtime. Every runtime registers with it, and machine-wide state always goes through it; the file implementation is only a fallback while the service cannot start. The coordination setting in `agent.workspace.yaml` picks the backend (local, GitHub, tac server) and whether claims are taken; off, the default, means "no claims, no other machines". Messaging is a capability of its own and can be on with claims off; CA.32's hold applies only to runtimes that take claims, and a runtime that only messages keeps its queues running and works from its cache and outbox.
> - (c) "Off" switches off the claims and the other machines, but the local tac service runs only when a host asks for coordination or messaging; otherwise files are used.
>
> *Recommendation:* (b) — it matches what D-13, CR.38, CA.34 and T1 already describe, keeps one way machine-wide state is handled, uses the start mechanism that exists, and gives Webwork messaging without leases.
>
> *Assumption until answered:* CA.31, CA.32, CR.38 and T1 keep their text, with a pointer here.
>
> **Answer:**

- **CA.32** When the backend cannot be reached, nothing falls back on its
  own: the runs of the team runtimes are held after their current item, and the tac client
  recovers by itself when the backend is back. Working locally meanwhile is
  an emergency step a user confirms twice. {~~(S6, BP-7)~>(<- S6: BP-7)~~} Whether this holds for a runtime that takes no claims, such as Webwork's own AI, is open (PQ-48).
- **CA.33** A team's coordination moves from one backend to another by a
  {~~migration that carries its token counters and undelivered commands.
  (S5 § 3.11, § 5.8)~>migration that carries its token counters and undelivered commands. While it runs, one runtime holds every repository of the team exclusively and the others wait. (<- S5 § 3.11, § 5.8; S6: BP-9; S30: ww_g_collab-3, planned)~~}
- **CA.34** Every runtime also registers with the local service of its
  machine, whatever its backend. The local service reports, as warnings that
  block nothing: one repository under two different backends, two workspaces
  naming one team with different backends, a listed repository whose clone
  is missing or has another origin. {~~(S5 § 6.4)~>(<- S5 § 6.4)~~}
- **CA.35** The runtime has one tac client for all of this. The queue, the
  tools, the views and the hosts ask that tac client and never a backend.
  {~~(S6, part-client-and-backends)~>(<- S6: part-client-and-backends)~~}
{++- **CA.45** On the GitHub backend each runtime's tac client keeps within the repository server's limits: it counts its own calls, always lets renewals and releases through, holds claims back while its share is spent, and after a refusal for a rate limit stops every call of its machine until the time the repository server names. The coordination repository's history is shortened by a maintenance step the user starts, with exclusive access. (<- S5 § 6.3, § 10; S30: ww_f_collab-4, planned)++}

### <!--[TAC-PEOPLE]--> 9.4 People, teams and identity

`tac/1.0` knows runtimes only. Messaging and supervision need users and
teams.

- **CI.1** A **team** is a group of users. It has members, team owners,
  invitations, conversations, review sets and the right to control each
  other's runtimes; and its members' runtimes coordinate in it: presence,
  leases, messages between runtimes, endpoints
  (`TAC > TAC-PEOPLE > TAC-GROUPS`, CA.39). A team exists with each backend (CA.39): on the local backend it is the personal team of one user on one machine, on the GitHub backend a user's personal team across that user's machines or a simple team of several members, on a tac server any team. {~~(S1 § 7.3, DQ-1; PQ-23; PQ-29)~>(<- S1 § 7.3: DQ-1) (-> PQ-23, PQ-29)~~}

- **CI.2** A user is a member of one team or of several. A user runs
  several runtimes; each coordinates in the home team of its quest. One
  runtime belongs to exactly one person. A runtime that serves no quest (an application's own AI, such as Webwork's, and the supervision application's runtime on the desktop: `RT > RT-HOLDS`, CR.6; `CLI > CLI-TRC`, CK.10) has no home team; in which team it registers, under which name, and what it may do there is open (PQ-51). Whose runtime runs behind the web runtime service is open as well (`RT > RT-HOLDS`, CR.7; PQ-38). {~~(S1 § 7.3, DQ-1)~>(<- S1 § 7.3: DQ-1)~~}

> **❓ PQ-51 (2026-11-25T17:12+01:00) — a runtime that serves no quest, and its team:** In which team does a runtime that serves no quest register, under which name, and what may it do there?
>
> **Context:** A **runtime** is one running instance of the engine; normally it serves one quest, and a **quest** records its **home team** (`TAC > TAC-PEOPLE`, CI.11: "A quest has a home team and a quest owner … Its runtime acts as a member of the home team: asks are routed in it, and remote control is allowed from it."). Everything about coordination is defined through that home team. CI.2: "A user runs several runtimes; each coordinates in the home team of its quest." `TAC > TAC-PEOPLE > TAC-GROUPS`, CA.39: "A runtime does this in the home team of its quest (CI.11), where it is always visible." CA.44: a runtime is visible, can be sent items, can be remote-controlled and claims its leases "in the home team of its quest"; CI.13 the same for remote control. But two runtimes of the first version serve no quest: `RT > RT-HOLDS`, CR.6: "An application's own AI that belongs to no quest runs in a runtime without a quest" — Webwork's AI tab, which also carries Webwork's messaging and review exchange — and `CLI > CLI-TRC`, CK.10: trc "on the desktop … has a runtime of its own that serves no quest". Webwork plans to register its runtime under the instance name `webwork-app`, "with `hasQuest: false`; it may take part in the claims" (S25: webwork `qavs_collab_b-1_akmt`). A related point: the extension today lets a window on a plain folder work on a "default quest" (`RT > RT-LOCATIONS`, CR.101); whether that is the same as a runtime without a quest is not said. A runtime keeps memory per quest (`RT > RT-HOLDS`, CR.6; the standard S22). The product owner's notes also name "the MCP server of the VS Code instance (or the webwork instance or the webforge instance)" (S4, note d), and Webwork plans a Webwork MCP endpoint of its own (`qavs_collab_b-1`); what such a runtime may publish in a team is part of "what it may do there".
>
> **Why I ask:** By the text as it stands, the two runtimes the first version needs most for people — Webwork's, for messaging and the review exchange, and trc's, for supervising a team — have no team in which they are present, act or may control anything. The answer decides what such a runtime presents to tac, whether it is listed among the team runtimes in trc, whether it can claim leases, and whether it has memory.
>
> - (a) A runtime without a quest registers in every team its user is a member of. It is present there as its user's application (listed under the application's name, such as `webwork-app`, apart from the quest runtimes), sends and receives messages and documents, answers asks addressed to its user, and — trc's runtime only — controls other runtimes where their hosts allow it. It holds no leases and cannot be remote-controlled itself. It has no memory of its own.
> - **(b)** As (a), but the user chooses at the host which of their teams such a runtime registers in (all by default), and it may claim leases when its host asks it to (Webwork's plan that it "may take part in the claims"); a window on a plain folder works on the default quest, which is a quest like any other with the user's personal team as its home team, not a runtime without a quest.
> - (c) A runtime without a quest registers in one team only, chosen at the host, and acts there as a quest runtime would; another team is reached only by explicit address, as CI.12 says for quests.
>
> *Recommendation:* (b) — it lets Webwork and trc work in all of a user's teams without the user choosing each time, keeps Webwork's plan for claims possible, and keeps the default quest out of this special case.
>
> *Assumption until answered:* CI.2, CI.13, CA.39 and CA.44 keep their text, each with a line that the team of a runtime without a quest is open; CR.6, CR.29 and T2 keep their text and no name such as `webwork-app` is written.
>
> **Answer:**

- **CI.3** A **participant** is a user (a user id, an e-mail address, a
  display name) or a runtime. A runtime names the person it belongs to, so
  what the runtime sends for an agent is attributed to the runtime and to its person. A
  user has several devices, each with its own connection and its own read
  position. {~~(S1 § 7.3)~>(<- S1 § 7.3)~~}
- **CI.4** Every application reaches tac through a runtime: on the desktop the
  runtime it hosts, in a browser, on a phone or on a tablet the web runtime service, which reaches tac through the runtime on the server (`RT > RT-INSTALL`, CR.108, CR.110) (`CLI > CLI-PACK`, CL.11; `NFR > NFR-TOPO`, T8). tac's
  participants are users and runtimes, never a device on its own. This holds without exception: no application of the first version is a tac client. An application uses the runtime client SDK, or in a browser, on a phone or on a tablet the web runtime client SDK (`CLI > CLI-PACK`, CL.12). Services that use tac directly through the tac client SDK, for a part of it such as messaging, are possible later and not planned (`SCO > SCO-LATER`, L-12).
  {~~(S1 § 7.3, WQ-1; PQ-28; PQ-30)~>(<- S1 § 7.3: WQ-1) (-> PQ-28, PQ-30)~~}
- **CI.5** A team has team owners and members. What each may do {~~(S1 § 7.3, DQ-2;
  PQ-12)~>(<- S1 § 7.3: DQ-2) (-> PQ-12)~~}:

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

  CI.5 … CI.10, CI.14 and CI.20 are stated for a tac server, and so is the team's configuration that only team owners change (CI.15; `RT > RT-CONFIG`, CS.4). Who is a member and a team owner of a team on the GitHub backend, and whether invitation, team token and the owner-only rules exist there or are agreements among its members, is open (PQ-47). What remote control covers is open as well (CI.13; PQ-50).

- **CI.6** A person joins a team by **invitation** {~~(S1 § 7.3, CQ-10, DQ-2)~>(<- S1 § 7.3: CQ-10, DQ-2)~~}:
  1. A team owner creates an invitation for an e-mail address.
  2. Creating it returns a one-time password, as text and as a link or QR
     code. The team owner passes it on by a channel they trust. It is valid once,
     for 7 days. The tac server sends no e-mail (`SCO > SCO-LATER`, L-4).
  3. The invited person's runtime presents the password together with the
     e-mail address it was issued for.
  4. The tac server creates the participant with a user id it generates itself,
     so that no tac client can choose an id, and returns the **team token**.

  The Solution Blueprint settles what happens to an invitation that was not redeemed within its 7 days.
- **CI.7** A team token is per user and team. Every device registers
  itself under it, so one device can be removed without the others. The
  token is kept as a secret (`RT > RT-SECRETS`, CS.11), never in a file.
  {~~(S1 § 7.3, DQ-2)~>(<- S1 § 7.3: DQ-2)~~}
- **CI.8** A tac client sends a team token with every request. A member of
  several teams holds several tokens. Which credential a tac client presents where several exist — the account's access key (CI.20), the team token, a paired device's key (CI.18) — and what each proves is open (PQ-50). {~~(S1 § 7.3, CQ-10)~>(<- S1 § 7.3: CQ-10)~~}
- **CI.9** A team owner removes a member, and the tac server then refuses that
  member's token. A member can leave. Tokens can be rotated. {~~(S1 § 7.3,
  DQ-2)~>(<- S1 § 7.3: DQ-2)~~}
- **CI.10** There are two levels of identity, and both are built:
  **identification**, where a tac client states a user id and an e-mail address
  and is believed, so that work can start without any setup; and
  **invitation with team tokens**. Which of them a tac server works with is a
  setting of the **tac server**, in its configuration, not of a team: a tac server
  is either **open** (identification for everyone on it) or **strict**
  (invitation and team tokens for everyone on it). An open server is right
  for one user alone on the VPN. The tac server's administrator sets it (CI.20); strict is the setting for a tac server that other users use. Every access from the internet is strict, whatever the setting;
  that cannot be configured. On a tac server set to open the member list can hold two entries with one e-mail address, or one person under two ids: tac returns both with their ids and does not merge them. {~~(S1 § 7.3, CQ-10; S3, WR-2; PQ-13; N-19, N-22; S25: 13_woneb6, planned)~>(<- S1 § 7.3: CQ-10; S3: WR-2; S25: 13_woneb6, planned) (-> PQ-13, N-19, N-22)~~}
- **CI.11** A quest has a **home team** and a quest owner (`RT > RT-ASKS`,
  CP.16); it records both. Its runtime acts as a member of the home team:
  asks are routed in it, and remote control is allowed from it. {~~(S1 § 7.3,
  DQ-12)~>(<- S1 § 7.3: DQ-12)~~}
- **CI.12** When an action addresses another team — a review request to that
  team's members, a message into one of its conversations — the runtime uses
  its person's token for that team, for exactly that action. A user's
  devices show all their teams side by side. {~~(S1 § 7.3, DQ-12)~>(<- S1 § 7.3: DQ-12)~~}
- **CI.13** A runtime can be controlled remotely only by members of the home team of its quest
 and only when its host's setting allows it. What remote control covers and excludes; {~~whether this setting also governs the MCP server a runtime publishes, through which other team runtimes can queue items and move a process (`RT > RT-MCP`, CT.12, CT.13), and an endpoint its host serves;~>whether this setting also governs the MCP server a runtime publishes, through which other team runtimes can queue items and move a process (`RT > RT-MCP`, CT.12, CT.13), and an endpoint its host serves; whether the runtime keeps a second MCP endpoint for the local machine only, with the file and host tools (CT.12);~~} and whether what people do to runs that are not theirs is recorded in one place, is open (PQ-50). {~~(S1 § 7.3,
  CQ-10; `CLI > CLI-TRC`, CK.5)~>(<- S1 § 7.3: CQ-10) (-> CK.5)~~}

> **❓ PQ-50 (2026-11-25T20:40+01:00) — one model for remote control, the MCP server's reach and tac's credentials:** What does remote control cover, does the host's setting for it also govern the MCP server a runtime publishes, does the runtime keep a second MCP endpoint for the local machine with the file and host tools, which credential does each program present, and is what people do to runs that are not theirs recorded?
>
> **Context:** **Remote control** is acting on a runtime of another person, or on one's own from another device: queueing items, pausing and continuing runs, moving a process, answering asks. `TAC > TAC-PEOPLE`, CI.13: "A runtime can be controlled remotely only by members of the home team of its quest and only when its host's setting allows it." `CLI > CLI-TRC`, CK.2: the supervision application (trc) "is a full remote control: more or less everything a runtime can do"; CK.5 restates CI.13. The **MCP server** of a runtime is the server through which agents call tools (MCP, the Model Context Protocol). `RT > RT-MCP`, CT.11 limits it to the runtime tools on the `_ai` state — todos, the queue, processes, sessions. CT.13: "A runtime can publish its MCP server as an endpoint through tac, so the other team runtimes find it and call its tools." CT.12 now reads: "The MCP server asks for a bearer token. Without a valid token it serves only the tools that read, and only to the local machine and the VPN. Who issues the token, how a team runtime obtains it and what the server checks is open (PQ-50), and so is whether the runtime keeps, for the local machine only, a second endpoint with the file and host tools that the old extension's MCP server serves to the holders of its key today." **What is built** (the old extension's standalone MCP server, S17 `mcp_server.md` § 1 … § 4): Streamable HTTP, bound to all addresses from port 19920 upward, a bearer key from an environment variable, and it serves **every enabled tool, the file and host tools included**, to whoever holds the key; without the key it serves only a read-only floor, and only to requests from the local machine (loopback) or the VPN. An agent outside VS Code on the same machine — Claude Code in a terminal working with the quest's tools — uses it that way today. **What is planned** for endpoints (S6, part-endpoints; this quest's `ww_f_collab-2`, S30): two endpoint types, `remote-control` (the runtime server, length-prefixed JSON-RPC over TCP) published with scope `loopback` only — "it serves the runtimes and clients of the same machine … From another machine a client uses the `mcp` endpoint instead" — and `mcp`, published per scope it can be reached from (`loopback`, `vpn`), which "is a remote-control endpoint as well, the one that already works across the VPN". `TAC > TAC-COORD`, CA.23: a runtime publishes its endpoints "with the address, where the address can be reached from (the machine, the VPN, the public network) … and how to authenticate, never a secret"; CA.24: "the endpoint itself checks who may use it". Webwork plans to publish an MCP endpoint of its own, served by the application, for remote control of Webwork (S25: webwork `qavs_collab_b-1`). Several credentials appear without one place that relates them: the **account's access key** (CI.20, CA.27: a person joins the tac server with it), the **one-time password** of an invitation (CI.6), the **team token** (CI.7, CI.8: "A tac client sends a team token with every request"), the **key per runtime** a team owner issues for the relay (`TAC > TAC-BACKENDS`, CA.30), the **paired device's key** (`TAC > TAC-CRYPT`, CI.18), the MCP server's **bearer token** (CT.12), the approval of a program by Tom Secrets Manager (`RT > RT-SECRETS`, CS.9), and the repository server's own credentials. Two items promise that something done in a run is "recorded" without saying where: CR.13 (an overridden precondition of a step) and CP.20 (a default taken for an unanswered ask); a person freeing another's stale lease (`TAC > TAC-COORD`, CA.13) is not said to be recorded at all.
>
> **Why I ask:** Queueing items and moving a process through the published MCP server is remote control in everything but the name, so either the host's setting governs both, or the MCP server is a way around CI.13. The built server also serves the file and host tools to a key holder; CT.11 allows only `_ai` tools, so the first version either drops what an agent in a terminal uses today on the same machine, or keeps a second endpoint that CT.11 does not describe. The planned rule that the `remote-control` endpoint is reachable only from the machine is a third answer to the same question (where remote control may come from). A team will only switch remote control on if it can see afterwards who did what. The security model of the Solution Blueprint starts from a list of the credentials; today four items (CI.8, CA.30, CI.18, CT.12) each describe one and contradict each other on what a tac client presents.
>
> - (a) Remote control and the MCP server are kept apart: the host's setting governs remote control only; the MCP server is for agents of the team, serves only the `_ai` tools (CT.11) and is protected by its bearer token alone; no second endpoint with file and host tools. Each credential stays described in its own item, and nothing is recorded centrally.
> - **(b)** One model, stated in `TAC > TAC-PEOPLE`: (1) remote control covers the commands of the runtime protocol that change something (queue, pause, continue, move a process, answer an ask) and excludes the host's tools, the file tools and the host's settings; (2) the host's setting governs every way in — remote control through tac, the published MCP server, and an endpoint a host serves through its runtime — and is off by default; the runtime protocol's own endpoint is reachable from the machine only, and from elsewhere a runtime is controlled through tac or its published MCP server; (3) the runtime keeps, beside the published MCP server with the `_ai` tools, a second MCP endpoint reachable only from the local machine, with the file and host tools, for an agent of the same user on that machine; it is never published through tac and needs its own bearer token; (4) a table of credentials — who issues each, to whom, where it is kept, what it proves, how it is withdrawn — with the team token as what a runtime presents to tac, the account's access key only for the administration of the tac server, the device key only on the path from the internet, and the MCP server's bearer token issued by the runtime that serves it and handed out through tac to the team runtimes that may call it; (5) one journal per quest of what people did to runs that are not theirs — every remote action, freed lease, overridden precondition, default taken and accepted todo offer, with the person and the runtime — shown in the supervision application.
> - (c) As (b) without point (3): CT.11 is strict, the published MCP server is the only one, and an agent outside the host on the same machine uses the `_ai` tools only.
> - (d) Leave all points to the security model of the Solution Blueprint; the Project Idea names them as open in CI.13 and CT.12.
>
> *Recommendation:* (b) — it closes the way around CI.13, keeps what a terminal agent on the same machine uses today without letting the file tools leave the machine, gives the security model its starting table, and gives "recorded" a place; each point can still be corrected in the answer.
>
> *Assumption until answered:* CI.13, CK.2, CK.5, CT.11, CT.12, CT.13 and CA.23 keep their text, each saying that the point is open; no part writes a new credential or a second endpoint.
>
> **Answer:**

- **CI.14** A team lists its members, the known and the present ones, with
  their ids and e-mail addresses. A message names the user who sent it.
  {~~(S1 § 7.10; S3, WR-2)~>(<- S1 § 7.10; S3: WR-2)~~}
- **CI.15** A team has a configuration that tac keeps and delivers to its
  members' runtimes (`RT > RT-CONFIG`, CS.3 … CS.6). {~~(S1 § 5.5, DQ-11)~>(<- S1 § 5.5: DQ-11)~~}
- **CI.20** On a tac server a team belongs to an account. Whoever installs the
  tac server creates the first account and its first access key from the
  tac server's command line. With that key a person joins the tac server, creates a
  team and is its first team owner; the others join the team by invitation
  (CI.6). {~~(PQ-20; S1 § 7.3, DQ-2; `TAC > TAC-BACKENDS`, CA.27)~>(<- S1 § 7.3: DQ-2) (-> PQ-20, CA.27)~~}

#### <!--[TAC-GROUPS]--> 9.4.1 The team runtimes

The team of CI.1 is also where its members' runtimes coordinate. This
subsection says what that means for the runtimes, and for the resources they
hold leases on. {~~(PQ-23)~>(-> PQ-23)~~}

- **CA.39** The runtimes started by a team's members are the **team
  runtimes**. They coordinate with each other: they see each other as
  present, they claim their leases from the same service, and they can send
  each other items. A runtime does this in the home team of its quest
  (CI.11), where it is always visible. There is no separate record for it
  beside the team and nothing to create or administer. Which team a user's runtimes belong to follows from the backend (`TAC > TAC-BACKENDS`, CA.26): on the local backend, which works on one machine only, they are the **personal team** of that user on that machine, with the user as its only member; on the GitHub backend they are either the user's personal team across the machines that share the coordination repository, or a simple team of several members whose runtimes share that repository; on a tac server they coordinate in the teams their user is a member of. The protocol as built names the team differently (`LAND > LAND-BUILT`, E-19). A runtime that serves no quest has no home team; where it is visible and what it may do is open (CI.2; PQ-51). It has nothing to do with how a runtime works with its models:
  an **agent** is the model acting in a session, or a sub-agent it started,
  and is never something tac deals with. Every
  runtime calls the model APIs and the agent SDKs directly, serves one
  quest, and reads and writes the quest's files and the other AI state on
  the machine of its host. {~~(PQ-23, PQ-20; S21, TQ-1, TQ-2, C-4; PQ-29)~>(<- S21: TQ-1, TQ-2, C-4) (-> PQ-23, PQ-20, PQ-29)~~}
- **CA.40** A runtime works with what its user can reach: the repositories
  the person it belongs to has access to at the repository server, cloned on its
  machine. A user who works on a quest normally has access to all of the
  quest's repositories. An agent uses only resources it can reach; when work
  needs something it cannot reach, it says that the work cannot be done here
  and has to be done elsewhere. This is stated for a runtime on the user's machine; for a runtime behind the web runtime service it is open (`RT > RT-INSTALL`, CR.109; PQ-38). {~~(PQ-23)~>(-> PQ-23)~~}
- **CA.41** A **resource** is, for now, a whole repository or a part of one
  described by a pattern of paths. It is named, not registered: the
  repository by its identity, the part by the repository and the pattern,
  for example `git:al-the-bear/tom_ai_build` and
  `git:al-the-bear/tom_ai_build#tom_ai_runtime/**`. The pattern is relative to
  the repository's root. A resource name starts with a prefix that names its notation; `git:` is the only prefix for now, and further ones are added as they are needed (CA.10). {~~(PQ-23; CA.9, CA.10; S21, TQ-8; PQ-31)~>(<- S21: TQ-8) (-> PQ-23, CA.9, CA.10, PQ-31)~~}
- **CA.42** tac knows the leases it has given, and nothing else. A runtime
  that is about to execute a todo claims the resources the todo names. tac
  understands the names: while the whole repository is exclusively leased,
  no part of it can be leased, and while a part is, neither the whole
  repository nor a part that overlaps it. Overlap is defined among `git:` names; resources with different prefixes never overlap (CA.11). Whether a claim can be answered
  with leases follows from the leases that exist; tac does not need to know
  which
  repositories or paths exist, keeps no list of resources, and does not have
  to store a resource that nobody holds. {~~(PQ-23)~>(-> PQ-23)~~}
- **CA.43** A lease that is stuck is known to tac, because tac gave it: it
  is listed and can be freed (CA.13). {~~(PQ-23)~>(-> PQ-23)~~}
- **CA.44** A runtime is **visible** in the home team of its quest, always:
  there it is seen, can be sent items, can be remote-controlled by the
  team's members where its host allows it, and claims its leases. In its
  user's other teams it is not visible unless the user switches it visible
  at the host. In such a team it is only seen, with its quest, and can be
  offered todos: no remote control from there, and no leases there. A user
  in two teams can so act as a liaison and link two groups of quests, or
  not show the other membership. {~~(S21, TQ-10, TQ-11)~>(<- S21: TQ-10, TQ-11)~~}
  The Solution Blueprint settles where a todo offer waits and who sees it, the form of the rule by which a runtime accepts offers, what the sender is told, when an offer expires, and where the switch "visible in another team" is stored.

### <!--[TAC-KINDS]--> 9.5 Message kinds

- **CM.1** A message between users has a kind. Beyond text, a kind is
  something the recipient's application can act on. The service stores and
  delivers; the kinds are the tac clients' convention and are versioned with the
  protocol. The first eight kinds of CM.2 are messages between users, or from a run to a person; notification and command are the two kinds of message between runtimes (`TAC > TAC-COORD`, CA.19), listed beside them because a host shows them too (CM.14). {~~(S1 § 7.4; CA.19)~>(<- S1 § 7.4) (-> CA.19)~~}
- **CM.2** The kinds {~~(S1 § 7.4)~>(<- S1 § 7.4)~~}:

  | Kind | Carries | What the recipient's application does | From → to |
  | --- | --- | --- | --- |
  | **text** | Markdown, mentions, a reference to the message it replies to | shows it | a user → the members of a conversation |
  | **document** | one or several files or references, and the form (`TAC > TAC-DOCS`, CV.8) | opens it, saves it into a place, makes a todo of it | a user → the members of a conversation |
  {~~| **review request** | the round, the set of documents, the deadline, the versions the review starts from |~>| **review request** | the round, the set of documents (the base, or the member's own files where the round has them: `TAC > TAC-REVIEW`, CV.17), the deadline, the versions the review starts from |~~} opens the review; the reviewer returns a copy in the same thread | the coordinator, through their runtime → the reviewers of the round |
  {~~| **review return** | the round and the returned copies | whoever created the round folder writes them into it (CV.12) and offers the merge |~>| **review return** | the round and the returned copies | whoever created the round writes them into the round's `returned/<member>/` (CV.12, CV.17) and offers the merge |~~} a reviewer → the coordinator |
  | **ask** | an ask (`RT > RT-PROTO`): a question, the allowed answers, a default, a deadline | shows buttons or a form; the answer returns to the run that asked | a run → a person of its chain (`RT > RT-ASKS`, CP.17) |
  | **decision request** | the open decisions of a todo, or the result of a gate with its choices | the recipient decides; the todo or the process moves | a run → a person |
  | **todo** | a todo to take over, or the change of a todo's state | files it, or shows the change | a user or a run → a user or a quest (a todo offer: CA.44) |
  | **reminder** | a time, what it is about (a message, a document, a round, a todo), who is reminded | delivered at the time; repeats and escalates as declared | the service → the recipient, and the sender (CM.4) |
  | **notification** | from a runtime: needs attention, finished, failed, out of budget | shown among the notifications | a runtime → the runtimes of its team, shown to their users (CA.19, CA.20) |
  | **command** | to a quest's runtime: queue, pause, proceed | carried out by that runtime (`TAC > TAC-COORD`, CA.19) | a runtime, or a user through their runtime → a quest's runtime (CA.19) |

- **CM.3** Beside its text a message can carry a free payload the service
  does not read, for references to files and for what an application shows
  as a card. {~~(S1 § 7.10)~>(<- S1 § 7.10)~~}
- **CM.4** **Reminders are a feature of the service.** A message can carry a
  time before which it is not delivered (`deliverAt`), and a time after
  which the service reminds the recipient when the message is still unread
  or unanswered, and the sender when it stays so (`remindAfter`). The
  deadline of a review round uses this. These are tac's reminders, between users; the reminders of a todo (`RT > RT-QUEUE`, CR.50) and the one reminder to an agent about its own background work are the runtime's and are not messages. {~~(S1 § 7.4)~>(<- S1 § 7.4)~~}
- **CM.5** A reminder is delivered once to a user, however many devices
  and runtimes that user has. {~~(S1 § 7.4)~>(<- S1 § 7.4)~~}
- **CM.6** **Delivery follows presence.** A notification is not pushed to a
  device while its user is active on another one; after a time without a
  reaction it goes on to the next channel. Which channels exist for a phone or a tablet — whether the first version uses the platforms' push services, or a device learns of an ask or a message only while its application runs and when it starts or resumes, as Webwork decided for itself — is open (PQ-49). {~~(S1 § 7.4)~>(<- S1 § 7.4)~~}

### <!--[TAC-CONV]--> 9.6 Conversations

- **CM.7** A conversation is direct (two users), among several members (a list of
  members), or attached to something: a document, a review round, a todo, a
  run, a quest. What it is attached to is an anchor the tac client sets and the
  service does not interpret. {~~(S1 § 7.5, § 7.10; S3, WR-4)~>(<- S1 § 7.5, § 7.10; S3: WR-4; S25: 13_woneb7, 13_woneb8, planned)~~}
  An application reaches its conversations through its runtime (`RT > RT-PROTO`, CP.36), so "a tac client" in CM.9 and CM.13 is the tac client inside a runtime (`CLI > CLI-PACK`, CL.11). Where the cache of conversations and the outbox of a user's messaging are kept — in the runtime, one per machine and user and shared by its hosts, or in each host — and who offers search over the cache, is open (PQ-52).

> **❓ PQ-52 (2026-11-25T17:12+01:00) — where the cache and the outbox of a user's messaging live:** Does the runtime keep the cache of conversations and the outbox of its user's messaging, or does each host keep its own?
>
> **Context:** Applications reach messaging only through their runtime: `TAC > TAC-PEOPLE`, CI.4 ("Every application reaches tac through a runtime … no application of the first version is a tac client"); `RT > RT-PROTO`, CP.36 lists the messaging commands a host uses through the runtime client SDK (conversations with unread counts, history in pages, sending with a request id, read state, members, blobs) and leaves this point open, pointing here. `TAC > TAC-CONV`, CM.9: "A conversation's history is stored and read in pages and from a point on (a message or a time), so a tac client that was offline catches up." CM.13: "A send repeated with the same id is not delivered twice, so a tac client that was offline can resend what waited in its outbox." With CL.11 that tac client is the one inside the runtime. Webwork plans "the conversation cache on the device; the outbox kept device-local …, each send with its request id, retried when the server answers; the cached history read-only while the server is unreachable" (S25: webwork `13_woneb6`) and "search across the cached conversations" (`13_woneb7`). A runtime is started by its host and ends with it (`RT > RT-HOLDS`, CR.44), so a cache inside a runtime lives as long as the runtime's files on the machine, not as long as the process. The runtime already keeps machine-wide state once per machine and user (`RT > RT-MACHINE`, CR.36).
>
> **Why I ask:** If each host keeps a cache, Webwork, the VS Code extension and trc each build one, and two hosts of one user on one machine show different unread states while offline. If the runtime keeps it, the hosts build none, but the runtime gets a store and a search it does not have yet. It decides whether Webwork's `13_woneb6` builds a cache at all, and what CP.36's commands return while tac cannot be reached.
>
> - (a) Each host keeps its own cache and outbox; the runtime only passes messages through and reports when tac cannot be reached.
> - **(b)** The runtime keeps them: one cache of conversations and one outbox per machine and user, in the machine-wide state (CR.36), shared by all hosts of that user. While tac cannot be reached, CP.36's commands answer from the cache (read-only) and a send goes into the outbox with its request id, sent when tac is back. The runtime offers search over the cached conversations. A host keeps no messages of its own.
> - (c) The runtime keeps the outbox only (so no send is lost); the cache of history is each host's.
>
> *Recommendation:* (b) — one store for every host follows from "every application through its runtime", gives the same unread state in every host, and saves each application building its own.
>
> *Assumption until answered:* CM.9 and CM.13 keep "a tac client that was offline", which is the tac client inside the runtime; no item says that a host keeps a cache or an outbox.
>
> **Answer:**

- **CM.8** Messages have replies and threads, mentions, and a mute per
  conversation. {~~(S1 § 7.5, § 3.2)~>(<- S1 § 7.5, § 3.2; S25: 13_woneb7, 13_woneb8, planned)~~}
- **CM.9** A conversation's history is stored and read in pages and from a
  point on (a message or a time), so a tac client that was offline catches up.
  {~~Members who are present receive messages live. The time of a message is
  the service's.~>Members who are present receive messages live.~~} {~~(S1 § 7.5, § 7.10; S3, WR-4)~>(<- S1 § 7.5, § 7.10; S3: WR-4)~~}
- **CM.10** Read state is kept per user: read up to a message, and the
  number of unread messages per conversation. {~~(S1 § 7.5, § 7.10; S3, WR-4)~>(<- S1 § 7.5, § 7.10; S3: WR-4; S25: 13_woneb8, planned)~~}
- **CM.11** Messages are kept for one year unless the team sets another
  time, or sets that they are kept. {~~(S1 § 7.5, WQ-3)~>(<- S1 § 7.5: WQ-3)~~}
- **CM.12** Every message has a stable address,
  `msg:tac/<team>/<messageId>`, that other documents and messages can refer
  to. {~~(S1 § 7.5, § 3.2)~>(<- S1 § 7.5, § 3.2; S25: 13_woneb9, planned)~~}
- **CM.13** A send carries a request id the service remembers for 24 hours.
  A send repeated with the same id is not delivered twice, so a tac client that
  was offline can resend what waited in its outbox. {~~(S1 § 7.5, § 7.10;
  S5 § 5.6; S3, WR-4)~>(<- S1 § 7.5, § 7.10; S5 § 5.6; S3: WR-4)~~}
- **CM.14** The messages between runtimes (`TAC > TAC-COORD`) stay as they
  are beside the messages between users. {~~(S1 § 7.10)~>(<- S1 § 7.10)~~}
- {++**CM.15** The time of a message is set by the service's clock when the service accepts the message, never by the sending tac client; the history, the read state and the retention of messages are ordered by it. (<- S1 § 7.10)++}

### <!--[TAC-DOCS]--> 9.7 Documents

- **CV.1** A file travels through tac as a **blob**: addressed by the
  SHA-256 hash of its content, checked on upload, stored once however often
  it is referenced. A reference in a message carries the hash, the name, the
  media type and the size. {~~(S1 § 7.6, § 7.10; S2 § 5, FO-8; S3, WR-5)~>(<- S1 § 7.6, § 7.10; S2 § 5: FO-8; S3: WR-5)~~}
- **CV.2** There is a size limit per file and a quota per team. A tac client
  can read both before it uploads, so it refuses a file that is too large
  before sending it. {~~(S1 § 7.6, § 7.10; S3, WR-5)~>(<- S1 § 7.6, § 7.10; S3: WR-5)~~}
- **CV.3** A blob has a lifetime: 7 days by default, at most 30, set per
  message. When it ends, the blob is removed. {~~(S1 § 7.6; S2 § 5, FO-21)~>(<- S1 § 7.6; S2 § 5: FO-21)~~}
- **CV.4** A process can **pin** its blobs for as long as it runs. Pinned
  blobs count against the team's quota and are released when the process
  ends. {~~(S1 § 7.6, CQ-11)~>(<- S1 § 7.6: CQ-11)~~}
- **CV.5** A **review set** is a named set of files, pinned for a review,
  that every reviewer of it can open — also a reviewer outside the VPN, or
  one without access to the version control or the file servers, as long as
  their application reaches tac through its runtime (`TAC > TAC-PEOPLE`, CI.4). {~~This is tac's review set: the pinned blobs of one round. What is under review — files, documents, sections, with the rounds under it — is defined by the application and kept in the documents' storage (Webwork plans a small YAML file there: S25, `09_woneb2`, planned). (S1 § 7.6, CQ-11; PQ-30)~>What is under review — files, documents, sections — with its members, its coordinator and its rounds is named in the review's `review.yaml` (`TAC > TAC-REVIEW`, CV.17), the same for every application and for the runtime's round operations; the files of a round that goes out through tac are its pinned blobs. (<- S1 § 7.6: CQ-11; S29: FQ-11) (-> PQ-30, D-29)~~}
- **CV.6** Only the members of the conversation a blob was sent in, or the
  reviewers of its review set, can download it. {~~(S1 § 7.10; S3, WR-5)~>(<- S1 § 7.10; S3: WR-5)~~}
- **CV.7** tac is not a file server (`SCO > SCO-OUT`, O-7). The versioned
  documents and the record of a review are in version control: usually the
  specification folder of the project in the project's repository; in a
  larger organisation a specification repository of its own; usually not the
  quest, since over time a quest spans many projects and products.
  {~~(S1 § 7.6, DQ-4)~>(<- S1 § 7.6: DQ-4)~~}
- **CV.8** A document is sent in one of three forms: as a reference to
  where it is, as a copy the recipient's application can work on (with the
  version it was taken from), or rendered for reading (Markdown, HTML, PDF).
  {~~(S1 § 3.2, § 7.4)~>(<- S1 § 3.2, § 7.4)~~}
- **CV.9** An application can tell, and shows: a blob that has expired, a
  copy over the size limit, a returned copy from someone who is not a
  reviewer of the round, and a copy returned twice. {~~(S1 § 3.2)~>(<- S1 § 3.2; S25: 13_woneb9, 13_woneb10, planned)~~}

### <!--[TAC-REVIEW]--> 9.8 The review exchange

- **CV.10** A review covers a set of documents. {~~(S1 § 3.2)~>(<- S1 § 3.2)~~}
{~~- **CV.11** tac carries the documents of a review round out to the members
  and their copies back. Nobody carries files by hand: the step of a team
  review in which the copies are collected is done by the exchange.
  (S1 § 7.7, § 3.5; S11)~>- **CV.11** tac carries the documents of a review round out to the members and their copies back, for the members who reach the round only through tac; for them the step of a team review in which the copies are collected is done by the exchange. A copy that arrives another way — exported and imported as a file, sent by mail through the system's mail client, or put into the review folder by hand — counts the same once it is in the round's `returned/<member>/` (CV.17, CV.18). (<- S29: FQ-9; S25: 09_woneb3, 13_woneb9, planned; S1 § 7.7, § 3.5; S11)~~}
{~~- **CV.12** The course of a round (S1 § 7.7, § 3.2):~>- **CV.12** The course of a round (<- S1 § 7.7, § 3.2; S29: FQ-11):~~}
  1. The coordinator's runtime (the coordinator: `USR`, U-15) — or, for document kinds the runtime does not know, the coordinator's application {~~(Webwork creates and merges its own rounds: S25, `09_woneb3`, planned) — creates the round folder and sends a review
     request with the document set to every member, in a thread attached to
     the round.~>(Webwork creates and merges its own rounds) (<- S25: 09_woneb3, planned) — creates the round (`round-<n>/` of the review, CV.17) and sends a review request with the document set to every member — the base, or the member's own files where the round has them — in a thread attached to the round.~~}
  2. Each member's application opens the review; the member annotates and
     returns the copy in the same thread.
{~~  3. Whoever created the round folder writes each returned copy into it and records it~>  3. Whoever created the round writes each returned copy into the round's `returned/<member>/` (CV.17) and records it~~} in the documents' storage (a commit where that is version control): the coordinator's runtime, which the coordinator's application drives, or the coordinator's application for the document kinds of step 1.
  4. Reminders go out before the deadline (`TAC > TAC-KINDS`, CM.4).
  5. When all copies are back, or the coordinator decides, {~~the copies are
     merged by whoever created the round folder, and the round is marked as merged; its blobs are then released.~>the copies are merged by whoever created the round, into the round's `consolidated/` (CV.17), and the round is marked as merged; its blobs are then released.~~}

  Every reviewer who receives a round through tac is a member of the team (asking a person outside the team is later: `SCO > SCO-LATER`, L-3; a guest of CV.16 returns a copy by another way).
  The Solution Blueprint settles: a member who never returns a copy; {~~a coordinator's runtime that is offline while returned copies wait and their blobs expire;~>a coordinator's runtime that is offline while returned copies wait and their blobs expire (the merge itself runs against the base in the round's folder: CV.19);~~} {~~which repository, and which lease, the recording of a copy uses (`PAR > PAR-APPROACH`, CW.5); and how the member id of a review round (`RT > RT-HOST`, CP.13) relates to the user id in tac.~>and which repository, and which lease, the recording of a copy uses (`PAR > PAR-APPROACH`, CW.5). How a round's set of documents travels through tac, how the member id of a review round (`RT > RT-HOST`, CP.13) relates to the user in tac, and how long a round's blobs stay on the tac server is open (PQ-66).~~}

> **❓ PQ-66 (2026-11-25T20:48+01:00) — the review exchange over tac: how a round travels, who a returned copy is from, how long its blobs stay:** When a review round goes through tac, does its set of documents travel as one archive per member or as one blob per file, how is a review member id matched to a tac user, and how long does the tac server keep the round's blobs?
>
> **Context:** A **review** (`TAC > TAC-REVIEW`, CV.17) lies in a folder `reviews/<review-name>/` beside the documents; its `review.yaml` names the documents, the members, the coordinator and the rounds; each **round** is a folder `round-<n>/` with `outbound/base/` (the documents as sent to everyone, the base of the merge), `outbound/<member>/` "only where a member gets something different", `returned/<member>/` (what each member sent back) and `consolidated/`. This layout is the product owner's decision in the webwork quest (S29: FQ-11, 2026-11-25), shared by the runtime's round operations, the VS Code extension (`04c_woneb4`, planned) and Webwork. A round covers a **set** of documents (CV.10); a Webwork document travels as one file, its `.webwork.zip` part bundle (S25: `09_woneb3`, `13_woneb9`). **tac** is the coordination and messaging service; a file travels through it as a **blob** — `TAC > TAC-DOCS`, CV.1: "addressed by the SHA-256 hash of its content, checked on upload, stored once however often it is referenced. A reference in a message carries the hash, the name, the media type and the size." CV.2: "There is a size limit per file and a quota per team." `TAC > TAC-KINDS`, CM.2: a **review request** carries "the round, the set of documents, the deadline, the versions the review starts from"; a **review return** carries "the round and the returned copies". Nothing says whether a set of several files is several blobs or one. **Member id:** in a review round a person signs as a **review member id** (`[a-z0-9_]+`, the extension's member id, `RT > RT-HOST`, CP.13: "the member id the user has in review rounds"); returned copies are filed under `returned/<member>/` and attributions are written `{@<memberId>}`. A copy returned through tac arrives from a **tac user** (a user id and an e-mail address, `TAC > TAC-PEOPLE`, CI.3). CV.12 names this as open: "how the member id of a review round (`RT > RT-HOST`, CP.13) relates to the user in tac … is open (PQ-66)". **Lifetime:** CV.3: "A blob has a lifetime: 7 days by default, at most 30, set per message." CV.4: "A process can pin its blobs for as long as it runs." CV.14: "A round's blobs are kept until the round is merged"; `DEC`, D-29: "a review set is a named set of pinned files". Webwork's requirement and plan say otherwise: kept "until it is merged or the maximum is reached" (S3, WR-5), "until the round is merged or their maximum lifetime ends" (Webwork's idea, part-review and part-messaging); "the round folder keeps the copies for good"; when the merge is done "the server is told so its blobs can go" (S25: `13_woneb10`). **Who uses tac for a review at all:** only members who cannot open the documents' storage; the others work in the shared review folder, and copies may also travel by export and import, by mail or by hand (`TAC > TAC-REVIEW`, CV.11; S29: FQ-9).
>
> **Why I ask:** These three points are what Webwork's review exchange through tac (its wave 1b2, `13_woneb10`) needs and what no source settles; the product owner's instruction for this round names "sending review document bundle within the team/users on the TAC" as what the first version must provide. How a set travels decides the review request's and return's payload (CM.2), whether an identical base is stored once for all members, whether a reviewer can return only what changed, and whether the size limit (CV.2) applies per file or per round. The member mapping decides under which `returned/<member>/` the coordinator files a copy and how a member is attributed in the merge; without it a copy through tac cannot be merged automatically. The lifetime decides whether tac holds a forgotten round's files without end (against "tac is not a file server", `SCO > SCO-OUT`, O-7) or a slow round loses its blobs before every member has opened them.
>
> - (a) **One archive per member and round:** the base, or the member's own folder, is packed into one blob; the return is one archive of `returned/<member>/`. The member id is carried in tac's member record (set when a person joins a team; every application uses it). A round's blobs are pinned until the round is marked merged, with no other bound than the team's quota.
> - **(b)** **One blob per file, mapped in `review.yaml`, bounded:** (1) the review request lists every file of the member's round with its path inside the round (`outbound/base/…` or `outbound/<member>/…`), its hash, name, media type and size; the return lists the files of `returned/<member>/` the same way; a Webwork document is one file (its `.webwork.zip`); an identical base is stored once for all members (CV.1), a reviewer may return only what changed, and the size limit applies per file; (2) `review.yaml` names, per member, the review member id and the tac user (id and e-mail); the review request tells each reviewer the member id to sign with; the coordinator files a return under the member whose tac user sent it, and a return from a tac user the review does not name is shown and not merged (CV.9); (3) a round's blobs are pinned until the round is marked merged, but at most 30 days from the request; the coordinator's application can extend them while the round is open (CV.14's extend operation); after that the round folder is the only copy.
> - (c) **Left to the applications:** tac carries opaque blobs and the review request and return as kinds (CM.2); how a set maps onto blobs, how a member id maps to a tac user, and how long a round's blobs stay are each application's convention, within CV.3's 7 and 30 days unless the application pins them.
>
> *Recommendation:* (b) — it uses CV.1's content addressing as intended, matches the review folder file for file, keeps the mapping in the review's own record so it works for members who never use tac and needs nothing new in tac's people model, and bounds what tac holds as WR-5 and Webwork state; each of the three points can be answered on its own.
>
> *Assumption until answered:* CM.2, CV.1 and CV.14 keep their text; CV.12 names the three points as open (PQ-66); no item says how a set travels, how a member is matched or that a round's blobs are capped.
>
> **Answer:**

{~~- **CV.13** The **round folder** is the record of a round: the description
  of the round, the base, each member's copy, the merged result. It lies
  beside the documents, in the documents' storage, which is usually version control (CV.7) and for Webwork a local folder or a GitHub repository. tac is the transport, not
  the record. (S1 § 7.7, § 7.6, DQ-4; S25: 09_woneb3, planned)~>- **CV.13** The **review folder** (`reviews/<review-name>/`, CV.17) is the record of a review and its rounds: what was sent, the base, each member's returned copy, the merged result. It lies beside the documents, in the documents' storage, which is usually version control (CV.7) and for Webwork a local folder, a GitHub repository or a git repository. tac is the transport, not the record. (<- S1 § 7.7, § 7.6: DQ-4; S29: FQ-1, FQ-11; S25: 09_woneb3, planned)~~}
{~~- **CV.14** A round's blobs are kept until the round is merged; blobs a process pinned are kept for as long as that process runs (CV.4), and the longest lifetime of 30 days (CV.3) holds for blobs that are not pinned; there is an operation to extend blobs that are not pinned to that
  longest lifetime and one to release them. (S1 § 7.10; S3, WR-5; D-29)~>- **CV.14** A round's blobs are kept until the round is merged; whether a longest lifetime bounds them too is open (PQ-66). Blobs a process pinned are kept for as long as that process runs (CV.4); the longest lifetime of 30 days (CV.3) holds for blobs that are not pinned, and there is an operation to extend blobs that are not pinned to that longest lifetime and one to release them. (<- S1 § 7.10; S3: WR-5) (-> D-29)~~}
- **CV.15** A reviewer who has access to no repository needs only an
  application that carries the review component (`CLI > CLI-UI`) and reaches tac through its runtime (`TAC > TAC-PEOPLE`, CI.4), and an identity in
  tac. Such applications are built outside this project (`SCO > SCO-OUT`, O-10): the VS Code extension, which carries the review component today and reaches tac once it hosts the runtime; Webwork and Webforge on the desktop later; and a web version of them after that. Until a web version exists, a reviewer without a repository works on a desktop. {~~(S1 § 7.7; PQ-30; S25: 13_woneb10, planned)~>(<- S1 § 7.7; S25: 13_woneb10, planned) (-> PQ-30)~~}
- **CV.16** A review round has, as the extension builds it today: individual answers of the members beside the team's answer; conflicts where members changed the same place differently, each with a decision; guests — a reviewer who is not on the round's review team returns a copy, is named with name and role, and the merge writes a question about the guest; proposed answers a person accepts, edits or discards; the time of each annotation's last change; and the round's record keeps the next round. {~~(S23: ccparity_f_teamreview-1 … -3, vscimpb107, vscimpb115, qrfix10, vscimpb66b, vscimpb23, done)~>(<- S23: ccparity_f_teamreview-1 … ccparity_f_teamreview-3, vscimpb107, vscimpb115, qrfix10, vscimpb66b, vscimpb23, vscannot3)~~}
- {++**CV.17** **The layout of a review.** A review lies in a folder `reviews/<review-name>/` in a storage location beside the documents (by default `reviews/` at its root). Its `review.yaml` names the documents, the members, the coordinator, the rounds and what was sent. Each round is a folder `round-<n>/` with `outbound/base/` (the documents as sent to everyone, the base of the merge), `outbound/<member>/` only where a member gets something different, `returned/<member>/` (what each member sent back) and `consolidated/` (the merged documents and the merge report `merge-report.json`). The runtime's round operations (`RT > RT-HOLDS`, CR.5), the VS Code extension and Webwork write and read this one layout; a round folder in the layout the extension writes today (`round.yaml`, the base, one copy per member, `merged/`) is read and converted on first use. (<- S29: FQ-11; S23: 04c_woneb4, planned; S25: 09_woneb3, planned)++}
- {++**CV.18** **The state of a round** is read from its folder: prepared (the base, or a member's own files, is there), sent (recorded in `review.yaml` by the channel that sent it, or by hand), returned (files in `returned/<member>/`), valid (the structure of a returned copy fits the base), consolidated (the merged documents are there and every conflict is decided). A file put into the folder by hand counts like one that arrived through tac. A reviewer's application lists the review requests addressed to its user, open or returned (`RT > RT-PROTO`, CP.36). (<- S29: FQ-11; S25: 09_woneb2, 09_woneb3, planned)++}
- {++**CV.19** **Where the review exchange works.** A member who can open the documents' storage works on the round in the shared review folder, and nothing travels; a member who cannot receives the round through tac, on a desktop as long as no web version exists (CV.15). Without a connection to tac the review folder still holds everything: the merge runs against the base there, also when tac's blobs have expired, while sending and returning wait until tac is reached again (`TAC > TAC-CONV`, CM.13; PQ-52). The size limit (CV.2) applies to every file of a round; a file over it is offered as a reference or in rendered form instead (CV.8). What travels is encrypted in transit and not at rest (`TAC > TAC-CRYPT`, CI.16, CI.17). (<- S25: 09_woneb3, 13_woneb9, 13_woneb10, planned; S25: the idea `webwork_redesign`, part-review and part-messaging, *Edge cases*)++}

### <!--[TAC-CRYPT]--> 9.9 Encryption

- **CI.16** What travels between a tac client and the tac server is encrypted in
  transit. {~~(S1 § 7.8; S3, WR-3)~>(<- S1 § 7.8; S3: WR-3)~~}
- **CI.17** What the service stores is not encrypted by default. Encryption
  at rest is an option (`SCO > SCO-LATER`, L-10). {~~(S1 § 7.8; S2 § 5, FO-20)~>(<- S1 § 7.8; S2 § 5: FO-20)~~}
- **CI.18** A device that reaches a server from the internet is **paired**
  first: it is enrolled once, from inside, by its user, and gets a key of
  its own. A single device can be removed, and its key then stops working.
  Pairing is part of the first version, since phones and tablets are in it {~~(`DEC`, D-51)~>(-> D-51)~~}. A phone, a tablet or a browser reaches a runtime only through the web runtime service (`RT > RT-INSTALL`, CR.108). Which program a device reaches from the internet and which holds the device keys, whether the relay of the tac server (`TAC > TAC-BACKENDS`, CA.30) is on that path, pairing as a procedure (from inside what, with which program, where the key is kept on the device, its expiry and rotation, a desktop machine off the VPN, a browser as a device), and whether phones and tablets stay in the first version while no solution for them is given, is open (PQ-49). {~~(S1 § 7.8, CQ-10; PQ-9; PQ-28)~>(<- S1 § 7.8: CQ-10) (-> PQ-9, PQ-28)~~}

> **❓ PQ-49 (2026-11-25T17:12+01:00) — phones and tablets: which program faces the internet, pairing, and how a person away is reached:** For an application on a phone or a tablet, which program does the device reach from the internet and which holds the device keys, how is a device paired, how does a person whose application is closed learn of an ask, is end-to-end encryption in the first version — and do phones and tablets stay in the first version at all?
>
> **Context:** The product owner answered PQ-28: "There is no given solution for this now. I assume the runtime cannot run directly in mobile devices, so there will be an additional relay which connect to a runtime on behalf of the device … So I suggest we call the component web runtime client SDK and web runtime service, being used in mobile apps and from Flutter-base (or non-Flutter) web applications." The text now says (`RT > RT-INSTALL`, CR.108): "A runtime does not run on a phone, on a tablet or in a browser. An application there uses the web runtime client SDK and talks to a web runtime service on a server, which connects to a runtime on the application's behalf. The service is HTTP-based … How the events of a run, asks and a host's tools cross it is open." What the web runtime service is (a program that starts a runtime per connected application, or a front to runtimes that exist anyway) is asked in PQ-38. The decision stands: `DEC`, D-51: "The supervision application runs on the phone and the tablet in the first version, reached from the internet as well as from the local network or the VPN; a device is paired and gets a key of its own." `TAC > TAC-CRYPT`, CI.18: "A device that reaches a server from the internet is **paired** first: it is enrolled once, from inside, by its user, and gets a key of its own." **Pairing** is that enrolment. The tac server has a **relay** (`TAC > TAC-BACKENDS`, CA.30): "It carries TAC and MCP for machines that are not on the VPN and only forwards. A machine authenticates to it with a key per runtime that an owner of the team issues." CI.19 leaves open "whether encryption in transit (HTTPS), the team token and the paired device's key are enough for access from the internet, or whether end-to-end encryption between a device and a runtime is needed in the first version too"; `SCO > SCO-LATER`, L-6 lists end-to-end encryption as an open point, not a decided deferral. `TAC > TAC-KINDS`, CM.6: "A notification is not pushed to a device while its user is active on another one; after a time without a reaction it goes on to the next channel." `CLI > CLI-TRC`, CK.11: trc on a phone is for "looking at what is going on and answering questions while away". Webwork decided for its own phone build: "a new message arrives while the app runs or when it syncs on start and resume (no outside push service)" (its decision DPPHONE-4). The runtime behind the web runtime service ends with the application's connection (CR.46, assumed until PQ-38), so nothing on the server watches for a user whose application is closed.
>
> **Why I ask:** The answer to PQ-28 names the component but leaves open what faces the internet: the web runtime service itself, the tac server through its relay (which today carries TAC and MCP, not the runtime's protocol), or both behind one address. That decides which program holds and checks the device keys, whether the relay's "key per runtime" and the device key are the same thing (CA.30 against CI.18), and how pairing works (from inside the VPN with which program, where the key is kept on the device, expiry and rotation, whether a desktop machine off the VPN or a browser is paired too). Without a push service a person away from the desk learns of an ask only when they open the application, which is what CK.11 says the application is for. And D-51 puts all of this into the first version although "there is no given solution for this now"; `ABOUT`, CK.10, the topologies T5 and T8 and the risk R-22 depend on whether it stays there.
>
> - (a) Phones and tablets leave the first version: D-51 is moved to `SCO > SCO-LATER` with the web runtime service, and the first version's applications run on the desktop only; pairing, the program facing the internet, push services and end-to-end encryption are settled when that later version is specified.
> - **(b)** Phones and tablets stay in the first version, and the Project Idea fixes the frame: (1) the web runtime service is the only program reachable from the internet for applications; it holds the paired devices' keys and checks them, and reaches tac through the runtime on the server, so the tac server's relay carries TAC and MCP only and is not on a device's path; (2) a device is paired from inside the VPN with the supervision application on the desktop, which shows a one-time code; the device keeps its key in the platform's secure storage; a key does not expire and is withdrawn by removing the device (CI.5); a browser is a device when it connects from the internet; (3) the first version uses no push service of the platforms: a phone learns of asks and messages while its application runs and when it starts or resumes, as Webwork decided, and CM.6's channels are the attached devices only; a push service is later; (4) end-to-end encryption is not in the first version, since the path ends at a runtime on the team's own server (CI.19); L-6 becomes a decided deferral.
> - (c) Phones and tablets stay in the first version, but which program faces the internet, pairing, push services and end-to-end encryption are all left to the security model of the Solution Blueprint; the Project Idea names them as open.
>
> *Recommendation:* (b) — it keeps D-51 without reopening the decision, gives the web runtime service the one job the answer to PQ-28 describes, keeps the relay to what CA.30 says, and leaves out the parts (push services, end-to-end encryption) no source asks for in the first version. Each of the four points can be corrected in the answer.
>
> *Assumption until answered:* CI.18 says "a server a device reaches from the internet" and names no program; CI.19, CK.10, CK.11, CM.6, CA.30, T5, T8, D-51 and R-22 keep their text and name the point as open; no push service is named; L-6 is an open point.
>
> **Answer:**

- **CI.19** ___check here___ **An open point for the security model of the
  Solution Blueprint:** whether encryption in transit (HTTPS), the team
  token and the paired device's key are enough for access from the internet,
  or whether end-to-end encryption between a device and a runtime is needed
  in the first version too. The product owner asked it ("think if internet
  access is secured enough with HTTPS + the token"). What can be said now:
  HTTPS with the team token and a device key protects against anyone on the
  network between the device and the server it reaches from the internet (which program that is: CI.18), and a lost device is shut out
  by removing its key. It does not protect against the server itself or
  whoever controls it, because the server and its relay see what they
  forward; end-to-end encryption would. In the first version the server is
  run by the team that uses it, so the server is trusted as the team's
  machines are. S1 makes end-to-end encryption mandatory with the relay {~~(S1 § 7.8, CQ-10)~>(<- S1 § 7.8: CQ-10)~~}; with the web runtime service for phones
  the path from a device ends at a runtime on that server, where there is no
  second end to encrypt to. The security model decides it; it does not hold
  up the Blueprint. Whether end-to-end encryption is in the first version is asked together with CI.18 (PQ-49). {~~(PQ-13, PQ-9; `SCO > SCO-LATER`, L-6; PQ-28)~>(-> PQ-13, PQ-9, L-6, PQ-28)~~}

### <!--[TAC-SPEC]--> 9.10 One specification: `tac/2.0`

- **CA.36** Everything in this section and the integration of
  `PAR > PAR-APPROACH` is specified as one protocol version, `tac/2.0`:
  participants, teams and identity; the tac server; conversations, message kinds
  and reminders; documents, pinning and review sets; integration leases and
  the integration queue; authentication. It is one document, reviewed as a
  whole, and it is built in one go. `tac/2.0` has no record of its own for whoever holds leases: a lease carries its holder (`TAC > TAC-COORD`, CA.8). {~~(S1 § 7.9, CQ-8, WQ-2; PQ-27)~>(<- S1 § 7.9: CQ-8, WQ-2) (-> PQ-27)~~}
- **CA.37** A service announces, when a tac client connects, the capability
  blocks it implements (participants, teams, messaging, documents,
  integration, and so on). A tac client uses what is announced. {~~(S1 § 7.9, WQ-2)~>(<- S1 § 7.9: WQ-2)~~}
- **CA.38** New capabilities are added within `tac/2.0`. From `tac/2.0` on, a runtime of an older version that is still running somewhere keeps working with a newer service; nothing uses `tac/1.0` (`LAND > LAND-BUILT`, E-11). A tac client that states no user still works on the local backend; a tac server set to strict refuses it (CI.10). {~~(S1 § 7.9,
  § 7.10, WQ-2; D-54)~>(<- S1 § 7.9, § 7.10: WQ-2) (-> D-54)~~}

### <!--[TAC-WEBWORK]--> 9.11 What Webwork needs, and how it is met

Webwork states six requirements on tac (S3, WR-1 … WR-6) and a seventh on the runtime (WR-7).

| Requirement | Met by | How |
| --- | --- | --- |
| **WR-1** tac reachable as a server by a small team | CA.26 … CA.28 | The full tac server; a small team is one account on it. A team on the GitHub backend has no messaging (CA.26), so a Webwork team uses a tac server. {~~(S1 § 7.10, CQ-9; PQ-29)~>(<- S1 § 7.10: CQ-9) (-> PQ-29)~~} |
{~~| **WR-2** identification by user id and e-mail on connect | CI.3, CI.4, CI.6 … CI.9, CI.10, CI.14 | **Met differently:** a team's tac server is set to strict, with invitation and team token (CI.6 … CI.9); identification by user id and e-mail alone exists only on a tac server set to open, which is for one user (CI.10; PQ-13). **Also differently:** an application without a runtime does not register in tac; it goes through a runtime. (S1 § 7.10, WQ-1; D-54) |~>| **WR-2** identification by user id and e-mail on connect | CI.3, CI.4, CI.6 … CI.9, CI.10, CI.14; `RT > RT-HOST`, CP.13; `RT > RT-SECRETS`, CS.11 | **Met differently:** a team's tac server is set to strict, with invitation and team token (CI.6 … CI.9); identification by user id and e-mail alone exists only on a tac server set to open, which is for one user (CI.10; PQ-13). **Also differently:** an application without a runtime does not register in tac; it goes through a runtime, and the team tokens of its user are kept by the runtime, not by the application (CP.13, CS.11). (<- S1 § 7.10: WQ-1) (-> D-54) |~~}
| **WR-3** encryption on the wire only | CI.16, CI.17, CA.28 | Encrypted in transit, ending at a reverse proxy; nothing required at rest. {~~(S1 § 7.10)~>(<- S1 § 7.10)~~} |
{~~| **WR-4** user messages | CM.1 … CM.13; `RT > RT-PROTO`, CP.36 | Conversations, history, read state, retention, the request id. An application reaches them through its runtime (CP.36); where the cache of conversations and the outbox are kept is open (PQ-52). (S1 § 7.10, WQ-3; PQ-30) |~>| **WR-4** user messages | CM.1 … CM.15; `RT > RT-PROTO`, CP.36 | Conversations, history, read state, retention, the request id; every message has the address `msg:tac/<team>/<messageId>` (CM.12) and the service's time (CM.15). An application reaches them through its runtime (CP.36); where the cache of conversations and the outbox are kept is open (PQ-52). (<- S1 § 7.10: WQ-3; S25: 13_woneb6 … 13_woneb9, planned) (-> PQ-30) |~~}
{~~| **WR-5** documents as blobs for the review exchange | CV.1 … CV.6, CV.10 … CV.14; `RT > RT-PROTO`, CP.36 | Blobs with limits and lifetimes, pinning, review sets, the exchange, reached through the runtime (CP.36); Webwork creates and merges its own rounds (CV.12). (S1 § 7.10, CQ-11; PQ-30) |~>| **WR-5** documents as blobs for the review exchange | CV.1 … CV.6, CV.10 … CV.19; `RT > RT-PROTO`, CP.36 | Blobs with limits and lifetimes, pinning, review sets, the exchange, reached through the runtime (CP.36); Webwork creates and merges its own rounds (CV.12) in the one review folder layout (CV.17), whose state is read from the folder (CV.18); tac is one channel beside export and import, mail and files put in by hand (CV.11). How a round's set travels, how a member id is matched to a tac user and how long a round's blobs stay is open (PQ-66). (<- S1 § 7.10: CQ-11; S29: FQ-9, FQ-11) (-> PQ-30) |~~}
| **WR-6** a Dart client that needs no AI runtime | `CLI > CLI-PACK`, CL.2, CL.3, CL.11, CL.12 | The Dart tac client SDK is a package of its own, used by runtimes and command-line programs of ours (CL.11). **Differently from the requirement:** an application does not connect to tac directly; on the desktop it uses the runtime client SDK, and in a browser, on a phone or on a tablet the web runtime client SDK against a web runtime service (`RT > RT-INSTALL`, CR.108; CL.12). Webwork's builds for the web and the phone get AI and messaging with its wave 3 (`SCO > SCO-LATER`, L-8); until then Webwork's messaging works on the desktop. Whether phones and tablets stay in the first version is open (`TAC > TAC-CRYPT`, CI.18; PQ-49). {~~(S1 § 7.10, CQ-15, WQ-1; PQ-9; PQ-26; PQ-28; PQ-30)~>(<- S1 § 7.10: CQ-15, WQ-1) (-> PQ-9, PQ-26, PQ-28, PQ-30)~~} |
{~~| **WR-7** the runtime's runs, queues, sessions and trail for Webwork's bottom panel | `RT > RT-HOLDS`, CR.6; `RT > RT-QUEUE`, CR.15 … CR.18; `RT > RT-HOST`, CT.4; `CLI > CLI-UI`, CU.6, CU.7 | A runtime without a quest for Webwork's own AI (CR.6), whose team is open (PQ-51); a queue per run with the three ways to send (CR.15, CR.16); the per-run option *review each result* (CR.17); starting a session over (CR.18); the host's own tools (CT.4); the conversation, queue and trail components and the bounded Markdown view (CU.6, CU.7). (S3, WR-7) |~>| **WR-7** the runtime's runs, queues, sessions and trail for Webwork's bottom panel | `RT > RT-HOLDS`, CR.6; `RT > RT-QUEUE`, CR.15 … CR.18; `RT > RT-HOST`, CT.4; `CLI > CLI-UI`, CU.6, CU.7 | A runtime without a quest for Webwork's own AI (CR.6), whose team is open (PQ-51); a queue per run with the three ways to send (CR.15, CR.16); the per-run option *review each result*, kept by the runtime, not by the host (CR.17); starting a session over (CR.18); the host's own tools (CT.4); the conversation, queue and trail components and the bounded Markdown view (CU.6, CU.7). (<- S3: WR-7) |~~}

Webwork does not need leases, endpoints, the GitHub backend or messages
between runtimes for its messaging. {~~(S3, "What Webwork does not need")~>(<- S3 § What Webwork does not need)~~}

{++Beyond WR-1 … WR-7, the product owner's instruction for the first version names what Webwork needs for team review and for sending review document bundles within a team and between users through tac (-> D-74). It is met by the review folder layout (CV.17) and the round's state read from it (CV.18), the round sent out and the copies returned through tac beside the other channels (CV.11, CV.12), where the exchange works and with which limits (CV.19), the review requests a reviewer lists (`RT > RT-PROTO`, CP.36), and the assists on documents under review (`RT > RT-HOLDS`, CR.119). Open is how a round's set travels through tac, how a review member id is matched to a tac user and how long a round's blobs stay (PQ-66). (<- S31; S29: FQ-9, FQ-11)++}

{++Three points of this text differ from what Webwork's plans assume, and Webwork is to be told them: the team tokens of a user are kept by the runtime, not in the application's settings (`RT > RT-HOST`, CP.13; `RT > RT-SECRETS`, CS.11), where Webwork's `13_woneb6` keeps them in its settings container; a message's address is `msg:tac/<team>/<messageId>` (CM.12), where Webwork's `12a_woneb2` and `13_woneb9` write `<server-group>`; the option *review each result* of a run is kept by the runtime (`RT > RT-QUEUE`, CR.17), where Webwork's `13_woneb2` keeps it as the device's state. (<- S25: 13_woneb6, 12a_woneb2, 13_woneb9, 13_woneb2, planned)++}

Webwork also needs its messaging to keep working while the tac server cannot be reached: the cached history read-only, outgoing messages kept in an outbox. Whether a runtime that takes no claims keeps its runs going then is open (`TAC > TAC-BACKENDS`, CA.32; PQ-48), and so is where the cache and the outbox are kept (PQ-52). {~~(S25: the idea `webwork_redesign`, part-messaging, Edge cases; 13_woneb6, planned)~>(<- S25: the idea `webwork_redesign`, part-messaging, *Edge cases*; 13_woneb6, planned)~~}

## <!--[PAR]--> 10 Parallel work, cross-quest work and repository quests

Several runs, on several machines, by several people, work on the same
repositories at the same time. This section states what hurts in that today,
how the product lets them do it without getting in each other's way, how
work crosses from one quest to another, and how quests are kept, in the shared state repository or in repositories of their own, and where a person's own files lie.

### <!--[PAR-PROBLEM]--> 10.1 What hurts today

The problems this part solves {~~(S1 § 10.1; S16)~>(<- S1 § 10.1; S16)~~}:

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
| **P-14** | A release ripples | One release of a shared package moves dozens of dependents. A todo can wait for a published version (CW.12), but that condition is evaluated only when one of the todo's blockers changes its status, not when the package is published. |

- **CW.1** The trunk is kept: work lands on the main branch of each
  repository, without a pull request per task and without a build server.
  What is added is what the trunk lacks: a check before the main branch, a
  way to discard an execution, leases shorter than an execution, and an answer to who holds
  what. {~~(S1 § 10.3, § 10.4)~>(<- S1 § 10.3, § 10.4)~~}

### <!--[PAR-APPROACH]--> 10.2 The approach

The whole approach is decided: the lease for the integration, the integration queue, the resources a todo names, the rebase of waiting executions, the record of commits, publication as a dependency, the answer to who holds what, the `_ai` state on its branch, review without pull requests, and a strict mode (CW.5). {~~(PQ-14)~>(-> PQ-14)~~}

{++The VS Code extension plans a collaboration model of its own on the same ground: leases as a table in the remote of each repository, stale after 30 minutes, with *Proceed anyway*; branches `todo/<id>`, `group-todo/<id>` and `feature/<id>` in working trees `<folder>@<branch>` beside the main clones; a merge tool with a review gate; review todos with rework; features executed in feature runs; and the standard runs `planning` and `quest-keeper`. By D-74 the extension's planned features belong to the first version, but this plan covers the ground of CW.2 … CW.15 differently. Which of it the runtime takes over, and which tac's leases, worktree mode and integration step replace, is open (PQ-63); until it is answered, none of it is an item of this section. (<- S28; S23: caf_03b … caf_08b, planned) (-> D-74)++}

**An execution's result is a branch**

An **execution** is the work on one item of a run's queue: it starts when
the run sends the item and ends when the item is done or given up. A run is
the queue itself and lives much longer. {~~(S21, TQ-4)~>(<- S21: TQ-4)~~}

- **CW.2** Whether executions work in a working tree of their own is a
  setting per repository that the team decides and can change. A repository
  one person works on needs none: it is in **strict mode**. When several
  work on it in parallel, it is in **worktree mode** (also called
  change-branch mode): an execution works in its own working tree, on its
  own branch, and its result is that branch. The `_ai` state never gets
  working trees per execution: a quest of a multi-quest repository is checked out as a working tree of its branch (CQ.1), and that is its one checkout on the machine, not one per execution. {~~(S1 § 10.4, CQ-12; S21, TQ-9; S22 § 3.1)~>(<- S1 § 10.4; S21: TQ-9; S22 § 3.1) (-> CQ-12)~~}
- **CW.3** A working tree of an execution keeps the relative layout of the
  repositories, so that builds and path dependencies between neighbouring
  repositories keep working; inside it, `_ai` is the one shared `_ai`. The
  execution's tools and its agent work in that tree. The working trees lie under the root's `.worktrees/`, which the fleet's skills skip and in which they report uncommitted work, so that a sync holds it. The tree is per execution (CW.2); the fleet's skills name a tree after its run today (`.worktrees/<run>/`, branches `run/<id>`). The Solution Blueprint settles the names of a tree and of its branch, and the fleet's skills follow them{++; the extension plans other names (branches `todo/<id>`, `group-todo/<id>`, `feature/<id>`, working trees `<folder>@<branch>`), which is open with PQ-63++}. {~~(S6,
  part-branches-and-worktrees; S27, `repo_skills_new.md` § 5.12, § 5.13; S21, TQ-4)~>(<- S6: part-branches-and-worktrees; S27: `repo_skills_new.md` § 5.12, § 5.13; S21: TQ-4; S23: caf_06a, planned)~~}
  The Solution Blueprint settles that an execution in a working tree of its own still gets the instruction files of its workspace folder (`RT > RT-LOCATIONS`, CR.59), and keeps the place and the names of the trees short or settable per machine: a working tree lengthens every path by its prefix, and Windows builds of this workspace are at the path-length limit already {~~(S27: `legws1`)~>(<- S27: `legws1`)~~}.
- {++**CW.29** A working tree or a branch of an execution that no lease names any more is an **orphan**: the coordination page (`CLI > CLI-UI`, CU.18) shows it, and the user integrates, keeps or removes it; nothing removes it on its own. (<- S6: part-branches-and-worktrees; S30: ww_g_collab-1, planned)++}

**Claims, leases and the integration step**

- **CW.4** Before a run sends a todo, its runtime claims the todo's
  resources, all or none. When a lease it needs is held for another item, the
  item waits and says who holds it; its run sends nothing else meanwhile (`RT > RT-QUEUE`, CR.67); when the lease is released, the waiting
  item goes on. {~~(S6, part-claims; S1 § 9, § 10.4; PQ-24)~>(<- S6: part-claims; S1 § 9, § 10.4) (-> PQ-24)~~}
- **CW.5** In worktree mode an execution holds a **shared lease** on what it
  works on, which tells the others who is working there and lets them work
  there too, and takes an **exclusive lease** on the repository only for the
  integration step. The integration step is: rebase the execution's commits
  onto the branch the record names for the repository (`RT > RT-LOCATIONS`, CR.104), run the repository's checks, fast-forward that branch, push. The fencing token is checked at the push. In **strict mode**
  the execution holds an exclusive lease, which keeps every other claim on
  an overlapping resource out, for as long as the todo is executed. A
  repository without working trees per execution (CW.2) is always in strict
  mode. {~~(S1 § 10.4, item 2; PQ-14; S21, TQ-9)~>(<- S1 § 10.4, item 2; S21: TQ-9) (-> PQ-14)~~}
  How the exclusive lease of the integration step is taken while others hold shared leases, where and by whom the fencing token is checked at a push, and what happens when the integration step fails are open (PQ-46{++; whether the extension's planned merge tool takes the integration step's place, PQ-63++}). Whether a lease is kept while its run waits for an ask — in strict mode an exclusive one — is open too (PQ-39); until it is answered, a lease is held for as long as the todo is executed.
- **CW.6** Every repository has an **integration queue**. tac keeps its order, and it is serial. The runtime whose execution is first in it carries out the integration step (CW.5) on its own machine: it rebases, runs the checks the repository declares (analysis, the tests the change affects), and lands the execution's commits or rejects them back to the execution. tac runs no checks and lands no commits. The checks run on the machine of the execution, as part of an item a person queued: they are no scheduled and no hosted check (CW.1). There is no integrator above the
  repositories. {~~(S1 § 10.4, item 3; `NFR`, N-34, N-28)~>(<- S1 § 10.4, item 3) (-> N-34, N-28)~~}
  What the integration queue is on the local and on the GitHub backend is open (PQ-46, PQ-47).
- **CW.7** A todo names its **resources**: repositories, and parts of
  repositories by a pattern of paths, each by its resource name (`git:<owner>/<repository>`, `git:<owner>/<repository>#<pattern>`; `TAC > TAC-COORD`, CA.10). That one list is what is claimed, and
  what the runs use so that only todos whose resources do not overlap are executed at the same time (a run executes one item at a time, `RT > RT-QUEUE`, CR.67); it
  says before it starts which todo waits for which. {~~(S1 § 10.4, item 4;
  S21, TQ-4; PQ-31)~>(<- S1 § 10.4, item 4; S21: TQ-4) (-> PQ-31)~~}
- **CW.8** A todo is written with its own resources. A quest lists the
  repositories and parts of repositories it usually works on, by their resource names (CW.7); for a todo that names nothing, the runtime claims that whole list for as long as the todo is executed. The quest's
  list is the fallback, mainly for older todos. {++Where the quest's list is recorded is settled with `RT > RT-LOCATIONS`, CR.35 (S1 and S6 name a file `quest-resources.<quest>.yaml`); the extension plans to hold it as the `defaultResources` of its run `quest-keeper`, which is open with PQ-63.++} {~~(S1 § 5.5, CQ-3, DQ-5)~>(<- S1 § 5.5; S6: BP-8; S23: caf_03f … caf_03h, planned) (-> CQ-3, DQ-5)~~}
- **CW.9** A group of todos can claim its resources with its first todo and release the leases with its last. {~~(S6, BP-10)~>(<- S6: BP-10)~~}
- {++**CW.28** Only an item that executes a todo claims. An item that executes no todo claims nothing and names no resources, and an agent's claim tool is refused outside an item that executes a todo. (<- S6: DPR-1, DP-part-claims-2; S30: ww_c_collab-4, planned)++}
- **CW.10** After each integration the executions that wait rebase onto the new
  main branch and run their checks again before they land.
  {~~(S1 § 10.4, item 5)~>(<- S1 § 10.4, item 5)~~}
- **CW.11** For every todo there is a **record of its commits**: per
  repository, the commit before and the commit after. It gives the unit of
  review (the difference a todo made), the way to discard (revert that
  range), and the way from a commit back to the session and the place in its trail where it was made, since a session can be started over (`RT > RT-QUEUE`, CR.18).
  {~~(S1 § 10.4, item 6; PQ-25)~>(<- S1 § 10.4, item 6) (-> PQ-25)~~}
  The Solution Blueprint settles the discard: who starts it and through what; what it does in worktree mode before the integration (the execution's branch is dropped) and after it (the range is reverted); and what happens to the todo's state and to the changes the execution made in the `_ai` state.
- **CW.12** A todo can wait for a package to be published at a version or
  later. The runtime checks the package registry and unblocks the todo.
  {~~(S1 § 10.4, item 7)~>(<- S1 § 10.4, item 7; S17 user guide *Todos that block others*; S23: finishvsc2)~~}
- **CW.13** tac answers **who holds what**: for a repository, a workspace or
  all machines of a team. A sync between machines or a change of the
  workspace's layout asks instead of assuming. A runtime can be asked to
  pause its queue after its current item.{++ Further control items the extension plans (starting, pausing, interrupting, resuming and silencing runs, also on other machines) are open (PQ-64).++} A sync may merge the `_ai` state in place while runtimes run, so a runtime never takes the copy of an `_ai` file it read for the file's state: it reads the file again before it writes. {~~(S1 § 10.4, item 8; S27, `repo_skills_new.md` § 4)~>(<- S1 § 10.4, item 8; S27: `repo_skills_new.md` § 4)~~}
- **CW.14** The `_ai` state stays on the main branch: todo and state files
  are not code, are merged by their own merge drivers and are written file
  by file. For a quest in a repository of its own, its main branch is the branch its entry in the register names (`quest/<id>` in a multi-quest repository; CQ.1, CQ.9); whether such a quest also has a branch per member is open (PQ-54). The runtime writes these files; it never stashes and never discards changes it did not make. Who commits and pushes what it writes is open (PQ-34). {~~(S1 § 10.4, item 9; `TAC > TAC-COORD`, CA.17; S22 § 3.1, § 3.4)~>(<- S1 § 10.4, item 9; S22 § 3.1, § 3.4) (-> CA.17)~~}
- **CW.15** **Review happens without pull requests.** The difference a todo
  made is shown as a review document; a review agent that starts without the
  execution's context gets only that difference and what the todo says must be
  true when it is done; a person reviews only the paths that carry weight
  (migrations, formats, publishing, credentials); the verdict is recorded
  with the todo. {++A draft pull request is opened only for a todo that carries risk, and only when a person asks for one. The extension plans review todos at the end of a group of todos, executed in a fresh session by a reviewer, with rework todos after a failed review; whether the runtime takes them over is open (PQ-63).++} {~~(S1 § 10.4, item 10)~>(<- S1 § 10.4, item 10; S23: caf_08a, caf_08b, planned)~~}
- **CW.16** A repository on which no lease is held can be brought up to date
  automatically, by fast-forward only and only with a clean working tree and
  nothing unpushed. It is switched on per workspace and is off unless switched on; it happens when a claim is taken or when the user asks, never on a schedule (`SCO > SCO-OUT`, O-6). A repository it had to
  skip is reported. {~~(S6, BP-12, BP-18; S27: `14_loose_wslayout-5`)~>(<- S6: BP-12, BP-18; S27: `14_loose_wslayout-5`)~~}
- **CW.17** The system does not take over from others: a pull request per
  task, a merge queue at the repository server, or agents working directly on the
  main branch of a repository several executions want. {~~(S1 § 10.4)~>(<- S1 § 10.4)~~}

### <!--[PAR-CROSS]--> 10.3 Cross-quest linkage

- **CW.18** One way of addressing holds on one machine and across machines:
  a todo as quest and todo id, a run as quest and run, a session, a user.
  {~~(S1 § 10.5)~>(<- S1 § 10.5)~~}
- **CW.19** Delivery is acknowledged. Something sent to another quest is
  taken by a run there, refused with a reason, or waits at the sender and is shown there with what it waits for. It does not wait unseen at the receiver. Until a run there takes it, tac keeps it as a record — on one machine, the machine-wide state (`RT > RT-MACHINE`, CR.36) — and the sender's run shows it with its delivery state and what it waits for; it is not shown as taken at the receiver before a run there took it. What happens to it when nobody took it within the 7 days a command is kept is settled under `TAC > TAC-COORD`, CA.19. This holds
  between quests of one team; what comes from another team is a todo offer (CW.26).
  {~~(S1 § 10.5, § 9; S21, TQ-11)~>(<- S1 § 10.5, § 9; S21: TQ-11; S23: ww_a_collab-4)~~}
- **CW.20** An item or a walk is sent into a named run of another quest: on
  the same machine through the machine's own state (`RT > RT-MACHINE`), on
  another machine as a command through tac (`TAC > TAC-COORD`, CA.19). It is
  one path for both, and it is part of the first version. A sent item never creates a run: a run the receiving quest does not have is refused, and an item that names no run goes into the receiver's run `default`, never into the run a host there happens to show. It is queued with the receiver's own defaults unless the sender names a profile, a session or a new, possibly temporary, session. A walk, or an item for a todo or for a group, runs over the receiving quest's todos. {~~(S1 § 9, § 10.5; S23: ww_a_collab-4)~>(<- S1 § 9, § 10.5; S23: ww_a_collab-4)~~}
  {++Items that wait for a todo or a run of another quest, a barrier between runs, and control items that start, pause, interrupt or resume runs of another quest or on another machine are planned in the extension; whether they are in the first version and how far they reach is open (PQ-64). (<- S23: vscimpb187, vscimpb188, caf_07c, planned)++}
- **CW.21** A todo names what it waits for, in any quest. The runtime
  follows such blockers across quests, and through tac across machines (tac carries the notice; the todo files themselves travel as CW.27 says). On every status change of a todo, by any writer, every todo of every quest that names it as a blocker is evaluated again: it is released when all its conditions are met (to "decision needed" when it has open decisions), and blocked again when a blocker is reopened. A todo can also wait for a package to be published at a version (CW.12), a condition read from the package registry. What a todo blocks is derived, never stored. A held item whose blocker is done goes on as `RT > RT-QUEUE`, CR.83 says.
  {~~(S1 § 10.5; S23: vscimpb121, ideatests2)~>(<- S1 § 10.5; S23: vscimpb121, ideatests2)~~}
- **CW.22** A request to another quest is a todo in that quest, carrying who
  filed it — not a prompt that can end without anything being filed.
  {~~(S1 § 10.5)~>(<- S1 § 10.5)~~}
- **CW.23** The done notification that an item or its todo asks for (`RT > RT-QUEUE`, CR.93, CR.94) returns to the run and the
  session that queued it, also across quests and machines; when none is asked for, nothing is sent. {~~(S1 § 9;
  `RT > RT-QUEUE`, CR.21; S23: vscimpb146)~>(<- S1 § 9; S23: vscimpb146) (-> CR.21)~~}
- **CW.24** Which repositories a quest works on is recorded, by their resource names (CW.7), so that claims
  and a todo's resources can be checked against it. The repositories of a workspace
  are those of the file the workspace is set up from. {~~(S1 § 10.5, § 5.5,
  CQ-3)~>(<- S1 § 10.5, § 5.5) (-> CQ-3)~~}
- **CW.25** When work has to be done in another quest, a todo is created in
  that quest. For that it is enough to reach the quest: by writing into the
  quest's repository, or into the shared state repository that holds
  several quests, where the user has access to it and the quest is checked out on this machine; later also by finding a
  runtime of the target quest and sending the todo there, through tac or
  the runtime's MCP server. Only creating a todo by handing it to a runtime of the other quest is later; sending a queue item or a walk into a named run of another quest, also through tac to another machine, is part of the first version (CW.20). A quest in a repository of its own that is not checked out on this machine cannot be written into here: the todo then goes through a runtime of that quest, once handing a todo to a runtime exists, or is written after the user has checked the quest out (CQ.7). {++A todo already written can also be moved into another quest (`RT > RT-HOLDS`, CR.114).++} {~~(PQ-23; CW.20 … CW.24; S22 § 4)~>(<- S22 § 4) (-> PQ-23)~~}
- **CW.26** A todo that a member or a runtime of another team sends to a
  quest is a **todo offer**. It is not in the quest until it is accepted: by
  a person of the quest's team, or automatically by a rule a person has set
  for that quest (from whom, of what kind). Accepting stays under a person's
  control. Adding todos is the case this exists for; other kinds of item may
  follow. {~~(S21, TQ-11; CA.44)~>(<- S21: TQ-11) (-> CA.44)~~}
  Where an offer waits and who sees it, the form of the accepting rule, what the sender is told and when an offer expires are settled in the Solution Blueprint (`TAC > TAC-PEOPLE > TAC-GROUPS`, CA.44).

- **CW.27** Changes in the `_ai` state and in a quest's repository reach another machine by a pull and a push the user starts (the quest operations of CQ.7; `SCO > SCO-OUT`, O-6). A todo written for another quest, or a blocker followed across machines (CW.21), is seen on the other machine after that step; tac carries only the live notice. {~~(S22 § 4, action 6; S22 § 2.4 QM-10; O-6)~>(<- S22 § 4, action 6; S22 § 2.4: QM-10) (-> O-6)~~}

### <!--[PAR-QUESTS]--> 10.4 Repository quests and personal files

- **CQ.1** There are three types of quest, side by side in one `_ai` state. A **classic quest** is a folder in the shared repository of the `_ai` state; whoever shares that repository shares the quest. A **repository quest** lives in a repository of its own, which the shared repository ignores, in one of two forms. A **single-quest repository** is one clone of the quest's repository, at the branch its entry names, at the quest's place. A **multi-quest repository** holds one quest per branch `quest/<id>`, and these branches are never merged with each other (its main branch holds only a description); it is cloned once per machine under `_ai/.quest-repos/`, without a checkout of its own, and each of its quests is a working tree of its branch at the quest's place. Whoever has access to a quest's repository shares the quest. Which type a quest is, is decided per quest; a classic quest stays one until the user migrates it (CQ.7). {~~(S2 § 3.7, § 5, FO-18; S1 § 12.5; S4,
  note n; S22 § 3.1, § 2.4 QM-3, QM-4, QM-11)~>(<- S2 § 3.7, § 5; S1 § 12.5; S4: note n; S22 § 3.1; S22 § 2.4: QM-3, QM-4, QM-11; S23: 02_aifmt-1, planned) (-> FO-18, D-71)~~}
- **CQ.9** The register `_ai/quests.yaml` lists every quest of the `_ai` state once, classic quests included, with its type and its setup: for a single-quest repository the repository and the branch, for a multi-quest repository the repository, in which the quest's branch is `quest/<id>`. A workspace's list `_ai/workspaces/<workspace>.yaml` picks from it; without a list a workspace has every quest (`RT > RT-LOCATIONS`, CR.33, CR.100). The whole setup is in versioned files, so that a workspace can be set up the same way on another machine. A quest in a repository of its own is checked out once per machine, and every workspace sees that one checkout; its checkout may be missing on a machine, which the runtime reports as a state of the quest. {~~(S22 § 3.1, § 3.4; S22 § 2.4 QM-1, QM-2)~>(<- S22 § 3.1, § 3.4; S22 § 2.4: QM-1, QM-2; S23: 02_aifmt-1, planned)~~}
- **CQ.10** A quest belongs to the workspace folder it is opened through: its workspace file lies at the top of the quest folder and names the workspace folder through which `_ai` is reached, and the quest's id is the file's name. This holds for every type, because every quest folder lies at `_ai/quests/<id>/`. {~~(S22 § 3.2; S27, `workspace_layout.md` § 4)~>(<- S22 § 3.2; S27: `workspace_layout.md` § 4)~~}
- **CQ.2** Every user has one **personal repository**, cloned into the
  `_ai` state, with a folder per quest, for the files that are only theirs.
  There are no personal quests. {~~(S2 § 3.7, § 5, FO-13, FO-22; S1 § 12.5)~>(<- S2 § 3.7, § 5; S1 § 12.5) (-> FO-13, FO-22, D-34)~~}
  The standard for quests (S22) has no personal repository and keeps a host's files in the quest, one file per host (CQ.11){++, and the extension plans exactly that (<- S23: 01_aifmt-4, planned); this quest's own plan keeps the personal files of a repository quest in a folder `_ai/personal/<id>/` of the shared `_ai` state instead (<- S30: ww_e_gitruntime-1, planned)++}; {~~which of the two holds is open~>whether any personal place remains beside the per-host files, and where the personal notes go, is open~~} (PQ-53). Until it is answered, CQ.2 and CQ.3 keep their text.

> **❓ PQ-53 (2026-11-25T20:15+01:00) — a personal place beside the per-host files in the quest, and the personal notes:** Beside the per-host files that the standard for quests keeps in the quest folder, does a user have any personal place for their files of a quest — a personal repository, or a folder `_ai/personal/<id>/` of the shared `_ai` state — and where do the personal notes of a quest go?
>
> **Context:** The **`_ai` state** is the shared repository of quests, todos and processes (`tom_agent_state`), cloned once per machine. A **quest folder** is `_ai/quests/<id>/`; a **classic quest** is a folder of the `_ai` state, a **repository quest** lives in a repository of its own (`PAR > PAR-QUESTS`, CQ.1). A **host** is one machine's program that runs the runtime; "per host" means one file per machine.
>
> What the Project Idea says. `PAR > PAR-QUESTS`, CQ.2: "Every user has one **personal repository**, cloned into the `_ai` state, with a folder per quest, for the files that are only theirs. There are no personal quests." CQ.3: "Personal files, kept in the personal repository and never in a quest's: the storage of the sessions: the live trail, the history and its compacted form; the session todos; the settings of a machine for a quest; the trail and compaction files kept per machine; the **personal notes** of a quest: notes for the current user only." `DEC`, D-34 (the product owner's earlier answers FO-13, FO-22): "one personal repository per user with a folder per quest and personal notes; quest notes stay in the quest." CQ.11: "**Per host, tracked and never merged:** a host's sessions, its compact trail (one block per turn of all its sessions), its journal of asks and answers, its configuration for the quest and its memory candidates."
>
> What the baseline says. The product owner made al_the_bear's `ai_format_migration.md` (S22) the standard for quests (D-71). It keeps every per-host file in the quest folder — sessions `history/<host>/<session>.session.json`, the compact trail `history/trail.<host>.md`, the journal `qa.<host>.<q>.md`, the host's configuration for the quest, its memory candidates — and has no personal repository and no notes for one user: quest notes are shared, and the only private notes are a per-machine file outside `_ai`. **The VS Code extension plans exactly that** (its todo `01_aifmt-4`, planned): sessions and the compact trail per host in the quest, a choice required when a session is created, "contributes to trail and memory" (now `RT > RT-QUEUE`, CR.79), the history derived and not tracked. By the product owner's instruction (a) of this round (D-74), the extension's planned features belong to the first version unless a decision puts them out of scope or later — so the per-host files in the quest are the baseline. Session todos are built today as one file per session, on its machine, deleted with the session (the extension's user guide, *Session todos*). **This quest's own plan differs again:** its todo `ww_e_gitruntime-1` (planned) keeps a repository quest's personal files — "sessions with their trails and histories, session todos, machine settings, the member's quest settings" — in `_ai/personal/<id>/`, "tracked by tom_agent_state so they still reach the member's other machines"; its todos for migrating, creating and joining a repository quest (`ww_e_gitruntime-8`, `-10`, `-11`) create that folder. A folder of the `_ai` state is read by everyone who shares the `_ai` repository: for one person's own machines that is only them, in a team that shares one `_ai` repository it is every member. The older plan behind D-34 kept these files out of a quest's repository on purpose: trails "are the one place secrets and personal material land unfiltered".
>
> **Why I ask:** Three sources name three places for the same files (the quest folder; a personal repository; `_ai/personal/<id>/`), and D-34 is a decision of the product owner that the baseline contradicts, so it is not replaced silently. What remains open is whether any personal place is kept at all, and what becomes of the personal notes. The answer decides what CQ.2, CQ.3 and D-34 say, what creating, joining and migrating a quest set up (CQ.7), what the one resolver must find (CQ.5), what a team member can read of another's work, and whether the glossary keeps "personal repository".
>
> - **(a)** No personal place. A host's files lie in the quest folder, one file per host, as S22 and the extension's plan have it; privacy in a shared quest is the session's choice "contributes to trail and memory" (CR.79); session todos stay on their machine as built. The personal notes of a quest are dropped; a user's private notes are the per-machine notes file outside `_ai`. CQ.2 and CQ.3 are marked as removed and replaced by CQ.11; D-34 is replaced by a new decision; `ww_e_gitruntime-1`, `-8`, `-10` and `-11` are rewritten without the personal tree.
> - (b) A folder `_ai/personal/<id>/` of the shared `_ai` state, as this quest's `ww_e_gitruntime-1` plans: a repository quest's per-host files and its personal notes lie there, so nothing personal enters the quest's own repository; a classic quest keeps them in its folder. Two places, chosen by the quest's type; private only as far as the `_ai` repository is the user's own.
> - (c) A personal repository per user only for the personal notes of each quest; sessions, trails and the journal lie in the quest as in (a). One private place remains, for notes.
> - (d) A personal repository per user, as D-34 decided, for all per-host files of quests shared with other people; a quest only the user works on keeps them in its folder. Two places, chosen by whether the quest is shared; the resolver (CQ.5) and joining (CQ.7) carry the difference.
>
> *Recommendation:* (a) — it is the standard the product owner chose and what the extension builds; it needs no second repository and no second rule for shared quests, and CR.79 already lets a member keep a session's turns out of what others read.
>
> *Assumption until answered:* CQ.2, CQ.3 and D-34 keep their text; CQ.11 states the four classes and says that the place of the per-host files is open; CR.53, CR.55 and CR.79 say "per host" without naming the place; no new text writes "personal repository" or `_ai/personal/`.
>
> **Answer:**

- **CQ.3** Personal files, kept in the personal repository and never in a
  quest's {~~(S2 § 3.7, § 5, FO-22)~>(<- S2 § 3.7, § 5) (-> FO-22)~~}:
  - the storage of the sessions: the live trail, the history and its
    compacted form;
  - the session todos{++ (<- S17 user guide *Session todos*)++};
  - the settings of a machine for a quest;
  - the trail and compaction files kept per machine;
  - the **personal notes** of a quest: notes for the current user only.
- **CQ.4** The quest notes stay in the quest, in its folder of notes beside further notes: they are the user's, and they
  are read by the agents of every member, which never write them. {~~(S2 § 5, FO-22; S22 § 2.2 AC-13)~>(<- S2 § 5; S22 § 2.2: AC-13) (-> FO-22)~~}
- **CQ.5** Every tool and every store resolves the place of a quest's file
  and of a personal file through one resolver, so the type of a quest
  changes nothing for the code that reads and writes it: every quest folder has the same inside, whatever its type. {~~(S22 § 3.1, § 3.2; S2 § 3.7)~>(<- S22 § 3.1, § 3.2; S2 § 3.7; S30: ww_e_gitruntime-1, planned)~~}
- **CQ.11** Inside a quest folder, whatever its type, the files fall into the four classes of `RT > RT-HOLDS`, CR.47. **Shared and merged:** the quest's documents and document folders, its todo files, the process states, the quest's shared configuration, the curated memory, the notes, the saved prompts, the overview, the progress and the like. **Per host, tracked and never merged:** a host's sessions, its compact trail (one block per turn of all its sessions), its journal of asks and answers, its configuration for the quest and its memory candidates. **Derived and not tracked:** the trail consolidated over all hosts, the history and its compacted form, and the decisions document, which is rendered from the archived todos. **Machine-local and not tracked:** the live trail, the raw results of a session, the notes of a quest refresh. The standard keeps the per-host files in the quest folder; whether they lie there or in a personal repository is open (PQ-53). {~~(S22 § 2.2, § 3.2)~>(<- S22 § 2.2, § 3.2; S23: 01_aifmt-4, planned)~~}
- **CQ.6** For a repository quest the runtime provides: the registration of the merge drivers of the `_ai` files on the machine (the drivers are the fleet's, built into the binaries repository; `LAND > LAND-BUILT`, E-5){++ (<- S23: vscimpb152aaa, planned)++}; a branch per member, with a review of the conflicts when
  the branches meet; {~~one shared process position, moved only on the main
  branch~>for each run one shared file of its process position, moved only on the main branch, a move refused when that file changed on the main branch since it was read (<- S30: ww_e_gitruntime-4, planned)~~}; a second repository beside the quest's, for what only its
  technical members may see, with development credentials kept encrypted; a
  scan for secrets when committing and publishing; the identity of the
  members and their access. {~~(S2 § 3.7)~>(<- S2 § 3.7; S30: ww_e_gitruntime-3 … -7, planned) (-> D-34)~~}
  The standard for quests (S22) has one branch per quest, merged between machines by the drivers, and says nothing of a branch per member, the second repository, the scan for secrets or the members' access{++, which are this quest's own queued todos (<- S30: ww_e_gitruntime-3, -5, -6, -7, planned) and so in the first version unless a decision puts them out of scope or later (-> D-74)++}; what of them remains is open (PQ-54). Until it is answered this item keeps its text.

> **❓ PQ-54 (2026-11-25T20:15+01:00) — member branches, the internal repository, the secret scan and member access: this quest's own queued todos:** Are a branch per member with publish, update and a review of conflicts, a second repository for technical members with development credentials, a scan for secrets, and the members' identity and access at the repository server in the first version on top of the standard's three types of quest, later, or dropped — and does a migration keep its trial run?
>
> **Context:** A **repository quest** is a quest kept in a repository of its own; the standard for quests (al_the_bear's `ai_format_migration.md`, S22, made the standard by D-71) has two forms (`PAR > PAR-QUESTS`, CQ.1): a **single-quest repository** (one clone at a named branch) and a **multi-quest repository** (one quest per branch `quest/<id>`, the branches never merged with each other). S22 gives a repository quest one branch per quest, merged between machines by the merge drivers like the `_ai` state today, with the quest's own merge rules and the `_ai` guards (CQ.12). It says nothing of a branch per member, a second repository, a secret scan or member access, and its migration (its QUEST MANAGEMENT, action 5) names no trial run.
>
> What the Project Idea says. `PAR > PAR-QUESTS`, CQ.6: "For a repository quest the runtime provides: the registration of the merge drivers of the `_ai` files on the machine …; a branch per member, with a review of the conflicts when the branches meet; for each run one shared file of its process position, moved only on the main branch, a move refused when that file changed on the main branch since it was read; a second repository beside the quest's, for what only its technical members may see, with development credentials kept encrypted; a scan for secrets when committing and publishing; the identity of the members and their access." (The process position is written independent of this question.) CQ.7, migrate: "… a migration goes one way only, and a trial migration shows the result before anything is changed." `DEC`, D-34: "Repository quests in the two forms of the standard …". `PAR > PAR-APPROACH`, CW.14: "The `_ai` state stays on the main branch: todo and state files are not code, are merged by their own merge drivers and are written file by file." In a multi-quest repository a branch per member has no place: each quest already is one branch, never merged.
>
> What the baseline says. By the product owner's instruction (a) of this round (D-74), "the currently queued todos and documents in the quest should now cover the base feature set": these four features are this quest's own queued todos (S30), all planned:
> 1. `ww_e_gitruntime-3` — each member works on `member/<id>` (one branch for all of a member's machines); *update* merges the main branch in; *publish* merges the member branch into the main branch by itself when the merge drivers resolve everything, and opens a review of the conflicts otherwise; publishing is started by the member — a button, and an offer when a todo is completed or a review round finished, with "Always publish automatically" as the member's setting for that quest; a host shows each member branch as ahead, behind or in conflict; the same runtime operations serve VS Code and Webwork.
> 2. `ww_e_gitruntime-5` — a second repository `<quest>_internal` for technical members only (runbooks, environment notes, test accounts, technical investigations, development credentials); the credentials are a KeePass (KDBX) file in it, its key passed by hand within the development team and kept in the operating system's key store after the first entry; a command names the entries it needs, only those reach its environment, and their values never enter a prompt, a tool result or a trail. The todo names the library `tom_kdbx`, which was retired over its licence (GPL-3) and is not to be depended on; the workspace's KDBX layer is `tom_kdbx_store` over `tom_kpasslib` (MIT). The part about secrets in a command's environment is written into `RT > RT-SECRETS` independent of this question.
> 3. `ww_e_gitruntime-6` — one pattern scan before every commit and publish of a repository quest (key prefixes, `.env` shapes, PEM blocks, the masked credential values), refusing the commit with the file and line; trails and logs are refused by path; "kept small".
> 4. `ww_e_gitruntime-7` — a member id names a member in branch names, session names and review attribution and is mapped to an account at the repository server (the account suggests the id when a member is added and stands in when none is set); access to a quest's repository and to its internal repository is granted through a team of that server per repository (`<quest>` and `<quest>_internal`). The Project Idea's people model (`TAC > TAC-PEOPLE`) has no mapping of a member to an account at the repository server.
>
> This quest's live check `checks11` pilots it: a new repository quest with two members, one joining from a second machine, both publishing and updating, one conflicting change through the review, the process position moved on the main branch, a credential used from the internal repository. Tom Forge plans its workbench's views on these features (its todo `qavs_wwwgitruntime-1`: member branch state, Publish and Update, the conflict review, the key prompt).
>
> **Why I ask:** D-74 puts the queued todos into the first version, D-34 kept repository quests "as planned", and the standard the product owner chose (D-71) has none of the four features and cannot hold member branches in its multi-quest form. The Solution Blueprint cannot plan both "one branch per quest" and "a branch per member" without a rule. The answer decides the scope of the first version (`SCO`), whether CW.14 needs an exception for member branches, what `TAC > TAC-PEOPLE` says about members and their accounts, whether `RT > RT-SECRETS` gets a form for a KDBX file, whether `NFR` gets a flow for two members, and what Tom Forge's workbench can build on.
>
> - (a) Dropped: a repository quest has the standard's one branch per quest; there are no member branches, no internal repository, no secret scan of the runtime's own and no member records beyond tac's teams; the trial migration goes too. CQ.6 is reduced to the drivers, the process position and the guards (CQ.12); D-34 is replaced; `ww_e_gitruntime-3`, `-5` (its internal repository), `-6`, `-7` and `checks11` are cancelled and Tom Forge is told.
> - (b) In the first version, for single-quest repositories only: member branches with update, publish, the publish offer and setting, the conflict review and the ahead / behind display; the internal repository with a KDBX file read through `tom_kdbx_store` over `tom_kpasslib`; the secret scan; members mapped to accounts at the repository server, with access through that server's teams. A multi-quest repository has none of them. CW.14 gets an exception (a member's work lands on the main branch by publishing), `NFR` a flow for two members (join, publish, update, conflict review, process move) as `checks11` pilots it, and the trial migration stays.
> - **(c)** Later: the first version has the standard only (one branch per quest, the drivers, the process position on the main branch, the guards). A branch per member with its publishing and conflict review, the internal repository with its credentials, the secret scan and members' access move to `SCO > SCO-LATER` as one line, to be planned when a quest is shared with people outside the user's own machines; `ww_e_gitruntime-3`, `-5`, `-6`, `-7` and `checks11` wait for that. The trial migration stays in the first version: a migration shows what it would do before it changes anything.
>
> *Recommendation:* (c) — the standard is what is decided and what the extension builds (S22's todos); the four features matter for a quest shared with other people, which no quest is today (`LAND`, E-14); building them now against a model that has changed would be rework, and putting them later is the decision D-74 asks for to leave a queued todo out of the first version. A trial run costs little and protects a step that rewrites history.
>
> *Assumption until answered:* CQ.6 keeps its text with a line saying this is open; CW.14 says that for a quest in a repository of its own its main branch is the branch the register names, and that member branches are open; CQ.7's join and migrate keep their text.
>
> **Answer:**

- **CQ.12** A quest in a repository of its own carries the merge rules of the `_ai` state in its own attributes file, and its clone uses the guards of the `_ai` state: the todo-schema guard, and the guard that refuses a new kind of file or folder at a quest's top level (documents may be added freely). The merge drivers are registered on each machine. Shared files are merged with a driver per kind: todos, process states and the shared configuration as YAML by id; the overview, {--the progress, --}the curated memory and similar Markdown files by section; {++the dated journals (the progress, the deferred work, the documentation updates) as the union of their dated sections, sorted by date and time (<- S30: ww_e_gitruntime-2, planned);++} notes and documents in subfolders as plain text. Per-host files are never merged, since each has one writer. Between machines a single-quest repository is synced like a code repository, a multi-quest repository with one fetch and a merge per working tree; syncing stays a step the user starts (CW.27). {~~(S22 § 2.2 CQ-17, § 3.5, § 3.6; S22 § 2.4 QM-7, QM-9)~>(<- S22 § 2.2: CQ-17; S22 § 3.5, § 3.6; S22 § 2.4: QM-7, QM-9)~~}
- **CQ.13** For a quest in a repository of its own, the `_ai` state keeps only its entry in the register, its pick in a workspace's list, its line in the generated block of ignored folders, and the clone of a multi-quest repository, which is not tracked; nothing of the quest's content. Besides the quests, the `_ai` state keeps what is no quest: processes, roles, role types, schemas and the guards. {~~(S22 § 1, § 3.3, § 3.4)~>(<- S22 § 1, § 3.3, § 3.4)~~}
- **CQ.7** These operations exist on quests {~~(S2 § 3.7; S22 § 4; S22 § 2.4 QM-5 … QM-10, C-1)~>(<- S2 § 3.7; S22 § 4; S22 § 2.4: QM-5 … QM-10, C-1; S23: 02_aifmt-1, planned)~~}:
  - **create**: a new quest is set up as any of the three types; for a quest in a repository of its own, an existing repository is taken, or a new one is created at the repository server, only after a confirmation, private and with GitHub Actions switched off; the quest is registered, picked for the workspace and checked out (CQ.12);
  - **add an existing quest**: from a single-quest repository (its address and branch), or from a multi-quest repository, whose quest branches are listed;
  - **pick and unpick** a quest for the workspace;
  - **remove**: from the workspace (only its pick), and for a quest in a repository of its own from this machine (its checkout is deleted; refused while it holds uncommitted or unpushed work); nothing in git is deleted;
  - **join**: a second user, or the same user on another machine, starts
    working on an existing repository quest — the quest's repository is
    cloned into place, the personal repository is set up, the user is
    registered as a member;
  - **migrate**: classic quests, several at once, become repository quests, each in a single-quest repository of its own or as one branch each of a multi-quest repository, and keep their
    history — the quest's folder with its commits is copied into the new
    repository, and the folder leaves the shared state repository in the same commit that registers the quest; a migration goes one way only, and a trial migration shows the result before anything is changed;
  - **pull, push and status** of quests in repositories of their own, started by the user, never automatically;
  - **set up this machine**: every quest in a repository of its own that the workspace picks and the machine lacks is checked out, so that a workspace is set up the same way on another machine;
  - **check and fix**: the quest folders are compared with the register, the workspace's list, the block of ignored folders and the state of git, and a fix is offered for each finding (a folder that is not registered, an entry without a folder, a checkout on another branch or address than its entry, a picked id that is no quest, a folder not in the current format).
  Whether these operations{++, the setting up of a workspace folder from the workspace template, and the creation of a quest with its setup todo and its short description++} are commands of the runtime, so that every host has them, or the VS Code host's own view, is open (PQ-55); until it is answered this item names the operations without saying which program carries them. The joining user's personal repository and registration as a member keep their text until PQ-53 and PQ-54 are answered.

> **❓ PQ-55 (2026-11-25T20:15+01:00) — who carries the quest operations, the workspace setup and the creation of a quest; a quest inside a project's repository; quests worked on from a server:** Are the operations on quests, the setting up of a workspace folder from the workspace template and the creation of a quest with its setup todo commands of the runtime that every host gets, or the VS Code host's own; is a quest inside a project's code repository wanted; and does a runtime on a server need working copies of quests?
>
> **Context:** A **host** is a program that runs or reaches a runtime: the VS Code extension, Tom Forge's quest application, Webwork, the supervision application, and applications on phones, tablets and in browsers, which reach a runtime through the **web runtime service** on a server (what that service is, is PQ-38). A **root** is the folder above the workspace folders that holds `.tom/tom_root.yaml`; a **workspace folder** is the folder a window works in (`RT > RT-LOCATIONS`).
>
> What the Project Idea says. `PAR > PAR-QUESTS`, CQ.7 lists the operations on quests: **create** (any of the three types; a new repository only after a confirmation, private, with GitHub Actions switched off; registered, picked for the workspace, checked out), **add an existing quest**, **pick and unpick** for the workspace, **remove** (from the workspace, or a checkout from this machine; refused while it holds uncommitted or unpushed work), **join**, **migrate** (classic quests into repositories, history kept, one way), **pull, push and status** (started by the user only), **set up this machine**, **check and fix**. It ends: "Whether these operations, the setting up of a workspace folder from the workspace template, and the creation of a quest with its setup todo and its short description are commands of the runtime, so that every host has them, or the VS Code host's own view, is open (PQ-55)". CQ.1 names three types of quest (a folder of the `_ai` state; a single-quest repository; a multi-quest repository).
>
> What the baseline says. By the product owner's instruction (a) of this round (D-74), the extension's built and planned features belong to the first version; the instruction does not say which program carries them.
> 1. **Built — creating a quest** (the extension's user guide § 2 *Setting up*; its todo `vsc_setup-5`): id, name and purpose; the quest's files with their headings; a short description `short_description.<quest>.md`, required at setup; one **setup todo** that defines the quest in question rounds; an offer to open the quest's workspace. Agents can run it as a tool.
> 2. **Built — setting up a workspace folder** (`vsc_setup-2` … `-13`; the extension's `workspace_setup.md`): *Setup New Workspace Folder* unpacks the **workspace template** the extension's package carries, in one of three forms — a new root with a first workspace folder, a workspace folder inside a root, or a standalone folder; it asks per file (Overwrite, Skip, All, Cancel), says what to adapt in the configuration, offers to register the merge drivers and opens the introduction quest.
> 3. **Built — the template itself:** every build of the extension packs it (a root part with the configuration, the root guidelines, `CLAUDE.md`, `AGENTS.md`, the `_ai` roles, processes, schemas, aspect guidelines and the `tomai_introduction` quest; a workspace part).
> 4. **Planned — QUEST MANAGEMENT** (the extension's todo `02_aifmt-1`, from S22 § 4): a panel in the extension's side bar listing every quest of the register with its pick, type, repository, branch and state (missing here, clean, uncommitted, ahead / behind), with the actions of CQ.7. S22 specifies it as a view of the VS Code extension and names no runtime command.
>
> Tom Forge needs the operations on repository quests as commands of the runtime with components for them (its todo `qavs_wwwgitruntime-1`), and for a later web build "a working copy per member … on the server, with commits through a GitHub App" (its decided todo `later23`). Creating a repository at GitHub, rewriting history (a migration) or writing files on a machine from a runtime behind the web runtime service may not be wanted. No source describes a quest kept as a folder inside a project's own code repository (the single-quest form can use a branch of any repository, not a subfolder of it).
>
> **Why I ask:** The answer decides whether the runtime protocol (`RT > RT-PROTO`) carries the operations and the setup, whether the runtime's installation carries the workspace template (`RT > RT-INSTALL`) or each host's package does, whether Tom Forge's quest application, Webwork and the supervision application can manage quests and set up workspaces, whether the screen inventory (`CLI > CLI-SCREENS`) gets a row and `tom_ai_runtime_ui` a component, which operations are refused behind the web runtime service, whether the register (CQ.9) needs a fourth type, and whether working copies on a server belong to the first version.
>
> - **(a)** Commands of the runtime: the operations on quests, setting up a workspace folder in its three forms, and creating a quest with its files, short description and setup todo; the runtime's installation carries the workspace template. Every host gets them through the runtime protocol; the screen inventory gets a row and `CLI-UI` a component for managing quests. Behind the web runtime service the operations that create repositories, rewrite history or set up a workspace are refused. A quest inside a project's code repository is not wanted: the three types stay. Working copies of quests on a server are later (`SCO > SCO-LATER`), with the web runtime service (PQ-38).
> - (b) The VS Code host's own, as S22 and today's extension have it: the runtime reads the register, reports each quest's state and resolves the folders; the operations, the workspace template and the setup are the extension's. Other hosts do not manage quests or set up workspaces in the first version. No fourth type; working copies on a server later.
> - (c) As (a), and a quest inside a project's code repository becomes a fourth type: a folder of the project's repository, registered with that repository and the folder's path, so a project can carry its own quest.
> - (d) As (a) for the operations on quests and the creation of a quest, but the workspace template and the setup of a workspace folder stay with each host's package and installer (the extension's package, Webwork's installer), since a workspace is set up before any runtime serves a quest in it.
>
> *Recommendation:* (a) — the runtime is the one implementation of the `_ai` formats for every host; keeping quest management and quest creation in one host would leave Tom Forge, Webwork and the supervision application without them and duplicate the rules on the register and the template, while refusing the heavy operations behind the web runtime service keeps them where a person sits at the machine.
>
> *Assumption until answered:* CQ.7 names the operations, the workspace setup and the creation of a quest without saying which program carries them; no screen row and no component are added; no item names the workspace template or the setup todo; CQ.1 and CQ.9 name three types; nothing is said of working copies on a server.
>
> **Answer:**

- **CQ.8** The first quest is migrated alone, to see that it works; then the
  quests worked in most. {~~(S4, note n)~>(<- S4: note n)~~}



## <!--[NFR]--> 11 Non-functional expectations

What the system must hold to beyond what it does. Each expectation is stated
by the sources; none carries a number the sources do not give.
Where a capability item already states what is expected, the entry here names the quality and refers to that item. What a Solution Blueprint needs and no source gives is listed at the end of this section; the numbers among it are asked for with a proposed value each (PQ-56).

**Compatibility and stability**

- **N-1** Compatibility within a major version of the runtime protocol: an older runtime client keeps working with a newer runtime (`RT > RT-VERSIONS`, CP.25). {~~(S1 § 6.7, DQ-9; `RT > RT-VERSIONS`)~>(<- S1 § 6.7) (-> DQ-9)~~}
- **N-2** Nothing a newer runtime added is lost when an older runtime client writes a record back (`RT > RT-VERSIONS`, CP.26); the conformance suite tests it (`CLI > CLI-PACK`, CL.6). {~~(S1 § 6.7, DQ-9)~>(<- S1 § 6.7) (-> DQ-9)~~}
- **N-3** No runtime works on workspace files newer than it knows: the versions are checked when a runtime client connects (`RT > RT-VERSIONS`, CP.24, CP.28). When a migration of the files runs, and whether the other runtimes pause meanwhile, is open (CP.29; PQ-40).
  {~~(S1 § 6.7, § 9 F12; `RT > RT-VERSIONS`; S22 § 5)~>(<- S1 § 6.7, § 9 F12; S22 § 5)~~}
- **N-4** Compatibility of tac: from `tac/2.0` on, a runtime of an older version keeps working with a newer service (`TAC > TAC-SPEC`, CA.37, CA.38). {~~(S1 § 7.9, WQ-2; `TAC > TAC-SPEC`)~>(<- S1 § 7.9) (-> WQ-2)~~}
- **N-5** Every existing prompt that names a tool keeps working (`RT > RT-TOOLS`, CT.2). {~~(S4, note e; S1 § 6.3)~>(<- S4 note e; S1 § 6.3)~~}
- **N-6** A change between revisions of MCP stays contained: the runtime names the revision it speaks and keeps what differs behind an adapter (`RT > RT-MCP`, CT.15). {~~(S1 § 6.4)~>(<- S1 § 6.4)~~}
- **N-7** The aim is that the protocol and the formats become very stable
  after a while (`RT > RT-VERSIONS`, CP.30). {~~(S1 § 6.7, DQ-9)~>(<- S1 § 6.7) (-> DQ-9)~~}

**Several runtimes and hosts on one machine**

- **N-8** Several runtimes and hosts work on one machine without overwriting
  each other's state. State that belongs to the machine is kept by the runtime alone and is reached through one interface; where files are used, a
  write changes one key, under a file lock, and never the whole file. {~~(S1 § 5.5,
  § 5.6, CQ-2; `RT > RT-MACHINE`)~>(<- S1 § 5.5, § 5.6) (-> CQ-2)~~}
- **N-9** All hosts of a machine share one installation of the runtime;
  versions stand side by side, and a running runtime keeps its version when a
  newer one is installed. {~~(S2 § 5, FO-3, FO-4; S1 § 5.7, DQ-9;
  `RT > RT-INSTALL`)~>(<- S2 § 5; S1 § 5.7) (-> FO-3, FO-4, DQ-9)~~}
- **N-10** Two hosts can work on the same quest at the same time; whether that is one runtime with two runtime clients or two runtimes is open (`RT > RT-HOLDS`, CR.6; PQ-36). {~~(S1 § 8 T2;
  S14)~>(<- S1 § 8 T2; S14)~~}
  {++While the old and the new VS Code extension are both in use, the old extension's own engine, which is not a runtime, may work on the same machine and the same `_ai` folder as the runtimes there (`RT > RT-HOLDS`, CR.112); whether on the same quest is open as well (PQ-36), and so is the format version both use (PQ-40). (-> D-73)++}

{++**The queue keeps going**++}

- {++**N-44** The runtime watches its own queue: every 60 seconds it takes items other quests sent that it missed, puts items that waited out a usage limit or a retry countdown back to pending once their time has come, and sends pending items on that have stalled. (<- S17 user guide *Watchdog and Health Check*)++}

**When the coordination cannot be reached**

- **N-11** Working without coordination: with coordination switched off, everything works as it does without tac (`TAC > TAC-BACKENDS`, CA.31); what "off" switches off is open (PQ-48). {~~(S1 § 7.2; `TAC > TAC-BACKENDS`)~>(<- S1 § 7.2)~~}
- **N-12** No silent fallback: when the backend cannot be reached (for the GitHub backend, the repository server), the runs of the team runtimes are held after their current item, nothing falls back on its own, and working locally meanwhile is a step a user confirms (`TAC > TAC-BACKENDS`, CA.32). {~~(S6; S1 § 7.2;
  `TAC > TAC-BACKENDS`; PQ-29)~>(<- S6; S1 § 7.2) (-> PQ-29)~~}
- **N-13** No lease is taken over by a machine: a lease that is not renewed becomes stale, is shown, and only a person frees it (`TAC > TAC-COORD`, CA.13). {~~(S5 § 4; S16)~>(<- S5 § 4; S16)~~}
- **N-14** A runtime that is offline still starts (`RT > RT-CONFIG`, CS.4: with the team's configuration as it last saw it). {~~(S1 § 5.5, DQ-11)~>(<- S1 § 5.5) (-> DQ-11)~~}

**Asks**

- **N-15** An ask is never lost, is escalated and is visible: it is a stored record that outlives the operating-system process that asked, it moves along a chain of people, every open ask of a team can be seen with its age and who has it, and nothing is decided automatically unless the ask declared a default. While it is open the run that asked waits and the other runs go on (`RT > RT-ASKS`, CP.21); the user can answer, skip or resend the waiting item. {~~(S1 § 6.1, § 6.6, CQ-7, DQ-3; `RT > RT-ASKS`; PQ-24; S23: vscimpb46, vscimpb55)~>(<- S1 § 6.1, § 6.6; S23: vscimpb46, vscimpb55) (-> CQ-7, DQ-3, PQ-24)~~}
- **N-16** A send to tac can be repeated safely (`TAC > TAC-CONV`, CM.13). {~~(S5 § 11; S1 § 7.5; S3 WR-4)~>(<- S5 § 11; S1 § 7.5; S3: WR-4)~~}

**Security**

- **N-17** No secret stands in a configuration or in a file of a quest, team tokens included (`RT > RT-SECRETS`, CS.7, CS.8, CS.11). {~~(S2 § 5, FO-15; S1 § 5.8, CQ-16;
  `RT > RT-SECRETS`)~>(<- S2 § 5; S1 § 5.8) (-> FO-15, CQ-16)~~}
- **N-18** The runtime's MCP server is safe to publish to other machines, because it reaches only the `_ai` state (`RT > RT-MCP`, CT.11). {~~(S4; S2 § 5, FO-17; S1 § 6.3, § 6.4)~>(<- S4; S2 § 5; S1 § 6.3, § 6.4) (-> FO-17)~~}
- **N-19** Identity is strict wherever others can reach in: a tac server that other users use is strict, and every access from the internet is strict whatever the setting (`TAC > TAC-PEOPLE`, CI.10). Remote control of a runtime is possible only inside a team and only where the runtime's host allows it (`CLI > CLI-TRC`, CK.5); what it covers is open (PQ-50). {~~(S1 § 7.3, CQ-10; PQ-13; `TAC > TAC-PEOPLE`, CI.10)~>(<- S1 § 7.3) (-> CQ-10, PQ-13)~~}
- **N-20** Encryption in transit between a tac client and the tac server; what the service stores is not encrypted by default (`TAC > TAC-CRYPT`, CI.16, CI.17). {~~(S3 WR-3;
  S2 § 5, FO-7, FO-20; S1 § 7.8)~>(<- S3: WR-3; S2 § 5; S1 § 7.8) (-> FO-7, FO-20)~~}
- **N-21** Whatever is reachable from the internet is reached over an encrypted connection and with strict identity; a phone or a tablet is paired first and has a key of its own (`TAC > TAC-CRYPT`, CI.18). Which program a device reaches from the internet (the tac server's relay, the web runtime service, or both), how an application in a browser is identified there, and whether end-to-end encryption between a device and a runtime is required are open (CI.19; PQ-49). {~~(S1 § 7.8, CQ-10; PQ-9,
  PQ-13; `TAC > TAC-CRYPT`, CI.18, CI.19; PQ-28)~>(<- S1 § 7.8) (-> CQ-10, PQ-9, PQ-13, PQ-28)~~}
- **N-22** No client chooses a user id (`TAC > TAC-PEOPLE`, CI.6: the tac server generates it when an invitation is redeemed). {~~(S1 § 7.3, DQ-2)~>(<- S1 § 7.3) (-> DQ-2)~~}
- **N-23** A prompt that draws on a document the host marks as encrypted leaves no trail on disk: its trail is kept in memory only (`RT > RT-QUEUE`, CR.24). {~~(S1 § 3.2; S13)~>(<- S1 § 3.2; S13)~~}
  The Solution Blueprint settles how a reload from the trail files (`RT > RT-PROTO`, CP.6) and the record of a todo's commits (`PAR > PAR-APPROACH`, CW.11) work for such a prompt.

**Platforms**

- **N-24** The runtime is a Node program written in TypeScript; it imports
  nothing from VS Code, and a test guards that. Where Node comes from outside VS Code, and its lowest version, is open (`RT > RT-INSTALL`, CR.40; PQ-37). {~~(S1 § 4; S2 § 3.1)~>(<- S1 § 4; S2 § 3.1)~~}
- **N-25** The Flutter components run wherever their hosts run: desktop, web, iOS and Android, themeable by the host, without a dependency on Tom Forge (`CLI > CLI-UI`, CU.2 … CU.4), over either Dart client SDK (CU.1).
  {~~(S1 § 12.2; `CLI > CLI-UI`)~>(<- S1 § 12.2)~~}
  They are written for the Flutter version and the widget libraries their hosts are on, since a component and its host share those types; the version stands in `RISK > RISK-DEPS`. {~~(S26: `06a_flutterm1`; S25: `05a_flutterm1`, `06b_flutterm1`, planned)~>(<- S26: 06a_flutterm1; S25: 05a_flutterm1, 06b_flutterm1, planned)~~}
- **N-26** Every platform the workspace supports gets the client SDKs: the runtime client SDK and the tac client SDK for nine languages (`CLI > CLI-PACK`, CL.1; TypeScript and JavaScript as one or two: PQ-42), and beside them the web runtime client SDK in Dart and in JavaScript / TypeScript (CL.12; what it is: PQ-41). The Dart tac client SDK runs with and without `dart:io`: a capability no application of the first version uses, since every application reaches tac through its runtime (`TAC > TAC-BACKENDS`, CA.28; `TAC > TAC-PEOPLE`, CI.4). {~~(S1 § 12.1; S2 § 3.5; `CLI > CLI-PACK`; PQ-26, PQ-28, PQ-30)~>(<- S1 § 12.1; S2 § 3.5) (-> PQ-26, PQ-28, PQ-30)~~}
- **N-27** The fleet's machines are macOS, Linux and Windows; the shared
  installation has a place on each of them. On Windows the workspace's paths are at the length limit already, and an execution's working tree (`PAR > PAR-APPROACH`, CW.3) lengthens them. {~~(S2 § 5, FO-3; S27: `legws1`)~>(<- S2 § 5; S27: legws1) (-> FO-3)~~}
- **N-28** The tac service has no runtime dependencies; TLS ends at a reverse
  proxy in front of it. {~~(S5; S1 § 7.10)~>(<- S5; S1 § 7.10)~~}

**Licence**

- **N-29** The packages are BSD-3, as the framework's packages are.
  `tom_tac_service` carries that licence today, and Webwork's choice of tac
  for its messaging rests on it. {~~(S5; S13, DPMESSAGING-2; S19)~>(<- S5; S13: DPMESSAGING-2; S19)~~}
  The new packages are BSD-3 too. For now they are published only to
  pub.dev (the Dart packages) and to the workspace's binaries repository
  (everything a host or a tac server installs: the runtime, the tac service, the
  client SDKs of the other languages). Publication to further registries and to
  the application stores is later. {~~(PQ-15)~>(-> PQ-15)~~}
  The binaries repository is public, so every third-party package bundled into what is published there has a licence that is not copyleft. The payload is built per platform by a build the user starts; a machine without the workspace takes it from the public repository or inside a host's installer (`RT > RT-INSTALL`, CR.42). {~~(S27: al_the_bear `binlic1`, `binpriv1`, completed; `repo_structure_new.md` § 4)~>(<- S27: binlic1, binpriv1; al_the_bear `repo_structure_new.md` § 4)~~}
  The Dart client SDKs and `tom_ai_runtime_ui` take only dependencies without a copyleft licence, since Tom Forge and Webwork test the resolved dependency graph of their applications. Whether the same holds for what the runtime installs (npm packages, provider SDKs) the Solution Blueprint settles. {~~(S14 § 4, test `qim_none-1`; S25: `13_woneb6`)~>(<- S14 § 4, test qim_none-1; S25: 13_woneb6, planned)~~}
  Where the web runtime client SDK for JavaScript / TypeScript is published (the binaries repository only, or also the registry web developers look in) is open (PQ-41).

**Documentation**

- **N-30** The product is delivered with its documents {~~(S1 § 13.2)~>(<- S1 § 13.2)~~}:
  - the specification, in the structure of the TomSpecs model;
  - an architecture document: components, process model, the topologies and
    the flows as sequences, who owns which state, security;
  - the runtime protocol specification, with its JSON schema;
  - the TAC specification `tac/2.0`;
  - the API documentation of the client SDKs, per language, with
    examples {~~(PQ-18)~>(-> PQ-18)~~};
  - a user guide and a programmer's guide, written by hand {~~(PQ-18)~>(-> PQ-18)~~};
  - the screen and component descriptions;
  - guides: integrating the runtime into a Flutter application; setting up a
    tac server and a team; having the runtime and the tac server approved by Tom Secrets Manager {~~(PQ-32)~>(-> PQ-32)~~}; the rules for
    parallel work with what is enforced;
  - the security model that `TAC > TAC-CRYPT`, CI.19, N-21, `TAC > TAC-BACKENDS`, CA.30 and `RISK > RISK-RISKS`, R-22 defer to.
  A guide for the web runtime service follows once the service is described (`RT > RT-INSTALL`, CR.109; PQ-38).

**Testing**

- **N-31** Every client SDK passes one conformance suite against the protocol (`CLI > CLI-PACK`, CL.6), and the Dart and the TypeScript and JavaScript client SDKs are tested thoroughly besides (CL.7). {~~(S2 § 5, FO-10;
  S1 § 12.1; `CLI > CLI-PACK`)~>(<- S2 § 5; S1 § 12.1) (-> FO-10)~~}
- **N-32** Guard tests keep the runtime's boundary: no import of VS Code, no
  state of a host except through the host interface, no mutable state at
  module level, and snapshots of the tools' schemas. {~~(S2 § 3.1; S19)~>(<- S2 § 3.1; S19)~~}
- **N-33** {~~Every stage of the split leaves the extension working and
  installable. (S19; S1 § 13.3)~>The work on the new VS Code extension changes nothing of the old one; the new extension is installable at every step, in a window or a profile where the old one is not active. (<- S1 § 13.3) (-> D-73)~~}
- **N-34** Builds, tests and checks are started by a person and run from the
  cloned repository; nothing schedules them, and no continuous integration
  runs on GitHub. The integration step runs a repository's declared checks on
  the machine of the execution. {~~(S16; S1 § 10.3, § 10.4)~>(<- S16; S1 § 10.3, § 10.4)~~}
- {++**N-45** The runtime's tools on specification documents work on documents of the size the specification process produces (this Project Idea is about 480 KB): an edit on a large document neither fails nor runs out of time where the same edit on a small one succeeds. The Solution Blueprint names the size the tools are tested at. (<- S1 § 3.5)++}

**Not stated by the sources; the Solution Blueprint settles**

- **N-35** Performance: the start time of a runtime, the delay of streamed events, the bound of the numbered events (`RT > RT-PROTO`, CP.6), what the bounded Markdown view keeps (`CLI > CLI-UI`, CU.7). Proposed values: PQ-56.
- **N-36** Capacity: runtimes per machine, runs per runtime, {++machines per user, ++}members and runtimes per team, teams and users per account{++, members and files of a review round (`TAC > TAC-REVIEW`, CV.17)++}. Proposed values: PQ-56.
- **N-37** Limits: the size limit per file and the quota per team (`TAC > TAC-DOCS`, CV.2), {++which every file of a review round meets (`TAC > TAC-REVIEW`, CV.19), ++} the quotas per account (`TAC > TAC-BACKENDS`, CA.27), the size of a message. Proposed values: PQ-56.
- **N-38** Availability of the tac server: backup and restore of its store, and what tac clients do while it restarts. Proposed values: PQ-56.
- **N-39** Privacy: a user's e-mail address and display name are stored by tac (`TAC > TAC-PEOPLE`, CI.3, CI.14); how a user's data is deleted and exported, and what a trail may contain.
- **N-40** Observability: what the tac server and a runtime log, and where (`RT > RT-PROTO`, CP.2 names standard error only).
- **N-41** Supported versions: of Node (open with PQ-37), of Flutter (N-25), of the operating systems (N-27 names the three) and of the browsers an application behind the web runtime service runs in.
- **N-42** Accessibility and languages of the Flutter components.
- **N-43** The budget behind "out of budget" (`TAC > TAC-KINDS`, CM.2) and behind usage and cost per provider (`RT > RT-PROVIDERS`, CS.14): who sets it, per what, and what happens when it is reached.

A record of what people did to runs that are not theirs is part of the question on remote control (PQ-50).

> **❓ PQ-56 (2026-11-25T21:40+01:00) — numbers the Solution Blueprint needs and no source gives:** Should the Project Idea carry starting values for the limits, times, sizes and counts listed below — now including what the first version's baseline adds (review rounds sent through tac, a person's several machines, the members of a team) — and are the proposed values right?
>
> **Context:** `NFR` (section 11, "Non-functional expectations") lists what the system must hold to beyond what it does. Its lead-in says: "Each expectation is stated by the sources; none carries a number the sources do not give." A Solution Blueprint (the next phase of the specification, which turns this Project Idea into a structured design) needs a number or an explicit "not stated" for each point below.
>
> The first version's feature baseline (`DEC`, D-74: the features of the VS Code extension, built and planned, of Webwork's plans for the runtime and tac, team review and review document bundles first, and of this quest's queued todos, carried across machines, between the members of a team and over the internet) fixes some numbers already, because they are built or decided. They are **not** asked here:
> - the queue's watchdog runs every 60 seconds (`NFR`, N-44, from the extension's user guide);
> - a chat send that gets no result within the queue's response time, 60 minutes by default, is stopped (`RT > RT-QUEUE`, CR.125);
> - a lease not renewed for 60 minutes becomes stale (`TAC > TAC-COORD`, CA.13);
> - an ask moves to the next person after 4 working hours (`RT > RT-ASKS`, CP.18);
> - an invitation is valid for 7 days (`TAC > TAC-PEOPLE`, CI.6);
> - a blob lives 7 days by default and at most 30 (`TAC > TAC-DOCS`, CV.3); how long a review round's blobs stay is asked in PQ-66 (until the round is merged, with or without that maximum);
> - user messages are kept one year by default (`DEC`, D-28);
> - a message's payload is at most 1 MiB in the coordination protocol as built (`tac/1.0`).
>
> The closing list of `NFR` names the rest:
> - "**N-35** Performance: the start time of a runtime, the delay of streamed events, the bound of the numbered events (`RT > RT-PROTO`, CP.6), what the bounded Markdown view keeps (`CLI > CLI-UI`, CU.7)." CP.6: "The numbered events are kept in memory with a bound. A runtime client further behind than the bound reloads the run from the trail files." CU.7: the bounded Markdown view keeps the last so-many lines or kilobytes, and the host sets its bound per use.
> - "**N-36** Capacity: runtimes per machine, runs per runtime, machines per user, members and runtimes per team, teams and users per account, members and files of a review round (`TAC > TAC-REVIEW`, CV.17)." A runtime is one running instance serving one quest; a run is one line of work in it with its own queue; a team is a group of people whose runtimes coordinate through tac; an account is whoever a tac server serves, with several teams; a review round is one sending of a review's documents to its members and their copies coming back (`round-<n>/` of the review folder `reviews/<name>/`).
> - "**N-37** Limits: the size limit per file and the quota per team (`TAC > TAC-DOCS`, CV.2), which every file of a review round meets (`TAC > TAC-REVIEW`, CV.19), the quotas per account (`TAC > TAC-BACKENDS`, CA.27), the size of a message." CV.2: "There is a size limit per file and a quota per team. A tac client can read both before it uploads." CV.19: a file of a round over the limit "is offered as a reference or in rendered form instead".
> - "**N-38** Availability of the tac server: backup and restore of its store, and what tac clients do while it restarts." `TAC > TAC-BACKENDS`, CA.32: when the backend cannot be reached, the runs of the team runtimes are held after their current item.
>
> **What the baseline adds and no source numbers:** Webwork sends a document of a review round as a `.webwork.zip` bundle, and a Webwork document can hold image assets; Webwork refuses a copy over the server's size limit before sending and offers a reference or the rendered form instead, but no Webwork source gives the limit, and whether review bundles regularly exceed a few MiB is not known (`inventory_webwork.md` § 2.5). A person works on several machines (the fleet today: four), and the extension's views already show every run of every window on a machine.
>
> **Proposed values** (starting values; each can be corrected in the answer):
>
> | Point | Proposed value | Why |
> | --- | --- | --- |
> | Start of a runtime until it accepts a runtime client | at most 3 s on a developer machine, not counting a first installation | a host starts one per window or open quest; the user waits for it |
> | Delay of a streamed event, from the transport to the runtime client | at most 200 ms on the same machine, at most 1 s over the VPN | the chat must feel live |
> | Bound of the numbered events per run (CP.6) | the last 10,000 events | one long prompt streams thousands; a reload from the trail is the fallback |
> | Bounded Markdown view (CU.7) | 2,000 lines or 512 KB unless the host sets another bound | the host sets it per use anyway |
> | Runtimes per machine | 20 at the same time | eleven quest windows are open today, plus Webforge |
> | Runs per runtime | 10 executing at the same time | today's busiest quests use three or four |
> | Machines per user | 6 | the fleet has four; one more for a laptop and a server |
> | Members per team; runtimes per team | 25 members; 100 runtimes present | a small team with several machines each |
> | Teams per account; users per account | 20 teams; 200 users | one organisation |
> | Members of a review round; files of a review round | 25 members (a team); 200 files | a specification set or a document with its sections |
> | Size limit per file (CV.2, CV.19) | 50 MB | a `.webwork.zip` bundle with images, or a PDF, must fit; a larger file goes as a reference or rendered (CV.19) |
> | Quota per team (CV.2) | 5 GB of blobs | blobs live at most 30 days unless pinned; a round's blobs count until it is merged (PQ-66) |
> | Quotas per account (CA.27) | 20 GB of blobs, the sum over its teams | |
> | Size of a message | 1 MiB, the default of `tac/1.0` | a source gives it; documents travel as blobs |
> | Backup of the tac server's store | daily, kept 14 days, restore checked once before the first team uses the server | the store holds leases, messages and the review exchange of a team |
> | A restart of the tac server | runtimes reconnect by themselves; an outage up to 5 minutes is waited out without holding runs, a longer one counts as "cannot be reached" (CA.32) | an update of the server must not hold every team run |
>
> **Why I ask:** Without values the Blueprint invents them or leaves them out, and the tac server's quotas, the conformance suite and the capacity tests have nothing to check against. The review exchange depends on the size limit most: too small, and every Webwork review with pictures falls back to references; too large, and one team's rounds fill the quota. Which values hold changes N-35 … N-38 and the items they refer to (CP.6, CU.7, CV.2, CV.19, CA.27, CA.32).
>
> - (a) The values become requirements of the Project Idea, as proposed or as corrected in the answer: N-35 … N-38 state them as what the system must hold to.
> - **(b)** The values are written into N-35 … N-38 as starting values: the Solution Blueprint starts from them and may change one with a stated reason; corrections in the answer replace them.
> - (c) No values in the Project Idea: N-35 … N-38 stay a list of topics, and the Solution Blueprint sets every number.
>
> *Recommendation:* (b) — the Blueprint gets something concrete to check, and a value that proves wrong in design can still move without reopening the Project Idea.
>
> *Assumption until answered:* N-35 … N-38 name the topics and point to this question; no value is written into an item.
>
> **Answer:**

### <!--[NFR-TOPO]--> 11.1 Network topologies

The topologies the architecture document describes {~~(S1 § 8)~>(<- S1 § 8)~~}. T1 to T5 and T8
belong to the first version (T8 for phones and tablets as far as PQ-49 leaves it); T6 and T7 are later. {~~(PQ-9, PQ-16)~>(-> PQ-9, PQ-16)~~}

| Id | Topology | What runs where | What must be reachable | Source |
| --- | --- | --- | --- | --- |
| **T1** | One machine, VS Code only | One runtime per window, inside the {~~extension~>new VS Code extension (in its own process until PQ-37 is answered: `RT > RT-HOLDS`, CR.142)~~};{++ during the parallel period the old extension's windows run its own engine, which is not a runtime, on the same `_ai` folder (CR.112);++} the local tac service once for the machine and user (the local backend serves this one machine only; what the local tac service does with coordination switched off: PQ-48). | Only the loopback interface. Nothing leaves the machine. | S1 § 8{++; D-73++} |
| **T2** | One machine, several hosts | VS Code windows, and Webforge with one runtime process per open quest plus one without a quest for Webwork's own AI (its team: PQ-51). Two hosts may work on one quest (one runtime or two: PQ-36).{++ A host whose run is bound to a quest folder uses that quest's runtime. (<- S25: 12a_woneb1, planned)++} | The loopback interface; all hosts find the shared installation and the local tac service. | S1 § 8 |
| **T3** | One user, several machines on the VPN | Each machine as T1 or T2. The runtimes on them are the team runtimes of one team and coordinate through the GitHub backend or the tac server (without a tac server it is the user's personal team, which the GitHub backend serves across the user's machines; the local backend serves one machine only). | Each machine reaches the coordination repository or the tac server; runtimes reach each other's published MCP endpoints directly over the VPN. | S1 § 8 |
| **T4** | A team on the VPN | As T3 with several users; the tac server carries the messaging. Webwork on the desktop connects through its local runtime. A simple team of several members can also coordinate through the GitHub backend: it shares leases and endpoints through the coordination repository, and what else it has (messaging, asks to other people, the review exchange) and who is a member and an owner of such a team are open (PQ-47). | Every member's machine reaches the tac server over TLS on the VPN, or the coordination repository. | S1 § 8; PQ-29 |
| **T5** | A member off the VPN | A machine outside reaches the tac server's public address; the relay forwards TAC and MCP to runtimes inside. A phone, a tablet or a browser reaches a runtime only through the web runtime service (T8); which program a device reaches from the internet, and whether the relay also carries the runtime's protocol, is open (PQ-49). | The tac server's public address over TLS, with strict identity and from a paired device (`TAC > TAC-PEOPLE`, CI.10; `TAC > TAC-CRYPT`, CI.18). Runtimes inside keep an outbound connection to the relay; nothing inside accepts a connection from outside. | S1 § 8; PQ-9, PQ-13 |
| **T6** | Standalone runtimes on an always-on machine (later) | An always-on machine runs runtimes for a long time without a window or a runtime client; quests are worked from the queue and supervised through trc. | The machine reaches the tac server; trc reaches the runtimes' endpoints. {~~(`SCO > SCO-LATER`, L-5; PQ-16)~>(-> L-5, PQ-16)~~} | S1 § 8 |
| **T7** | A cloud agent (later) | A vendor's sandbox clones a repository, works and pushes a branch; the runtime that sent the todo asks the vendor and the repository server for the result. | The sandbox reaches the repository server only; it reaches neither tac nor a runtime. {~~(`SCO > SCO-LATER`, L-1)~>(-> L-1)~~} | S1 § 8 |
| **T8** | A web runtime service for applications on a phone, on a tablet and in a browser | An application without a local runtime uses the web runtime client SDK (in Dart or in JavaScript / TypeScript) and talks to a web runtime service on a server, which connects to a runtime on the application's behalf (`RT > RT-INSTALL`, CR.108). Assumed until PQ-38: the service runs permanently and starts one runtime per connected application, which ends with that application's connection (CR.46). It is the only way such an application reaches tac: the service reaches tac through the runtime on the server (CR.110). The supervision application on a phone or tablet uses it in the first version (as far as PQ-49 leaves that standing); Webwork's web, phone and tablet applications follow in wave 3 of Webwork (`SCO > SCO-LATER`, L-8). | The application reaches the web runtime service over HTTP (how the events, asks and a host's tools cross it is open: PQ-41), from the local network, the VPN or the internet; from the internet only with strict identity (pairing and which program faces the internet: PQ-49). The runtime it started reaches tac. {~~(WQ-1; PQ-9, PQ-16; `RT > RT-INSTALL`, CR.46, CR.108, CR.110)~>(-> WQ-1, PQ-9, PQ-16, CR.46, CR.108, CR.110)~~} | S1 § 8; PQ-28 |

T6 depends on a runtime that runs without an application connected to it, while a runtime
is started by its host and ends with it (`RT > RT-INSTALL`, CR.44). It is
later, with standalone runtimes (`SCO > SCO-LATER`, L-5): it is a service
that hosts a runtime for a long time, and that service is not planned now.
On the always-on machine the tac server and the web runtime service (T8) run in the first version; a runtime there is started for a connected application and ends with that application's connection (`RT > RT-INSTALL`, CR.46; assumed until PQ-38).
{~~(PQ-16, PQ-9)~>(-> PQ-16, PQ-9)~~}

#### <!--[NFR-TOPO-FLOWS]--> 11.1.1 Key flows

The flows the architecture document draws as sequences {~~(S1 § 9)~>(<- S1 § 9)~~}.

| Id | Flow | In one line | Source |
| --- | --- | --- | --- |
| **F1** | A host attaches | The host finds the runtime installation (it installs the one it carries only when none is installed), starts a runtime from it{++ (the new VS Code extension runs it in its own process until PQ-37 is answered: `RT > RT-HOLDS`, CR.142)++}, exchanges the versions, registers its tools and subscribes to the events from a sequence number on. A host that finds the runtime too new for it switches the features that use it off, or does not start. The runtime registers with its team (`TAC > TAC-COORD`, CA.3) and with the local service of its machine (`TAC > TAC-BACKENDS`, CA.34). | S1 § 9; PQ-6 |
| **F2** | A prompt | The host queues an item (at the end, next, or as an update to the running prompt); the queue sends it when the session is free; the transport streams; tool calls go to runtime tools or back to the host; the result is recorded in the trail. | S1 § 9 |
| **F3** | A todo walk | A walk takes the lowest-numbered open todo (`RT > RT-QUEUE`, CR.19), claims its resources from tac, all or none, executes it, carries out what follows its completion and releases the leases. At the first todo it cannot run (open decisions, or a blocker that is not done) the walk holds and its run is held; going on past that todo is the user's action (CR.19, CR.23). | S1 § 9; S23: vscimpb37 |
| **F4** | A process step with a gate | The step's prompt and its walks are executed; the gate writes its report and asks with the decision buttons; the run waits until the decision is taken (`RT > RT-ASKS`, CP.21); the decision moves the process. | S1 § 9; PQ-24 |
| **F5** | An ask reaches a person elsewhere | A run asks and waits (`RT > RT-ASKS`, CP.21); nobody is active on the asking host; the ask travels through tac to the user's other devices or along its chain, and the answer returns to the run, which goes on. What of this travels on the GitHub backend (PQ-47), and how a phone learns of an ask while its application is closed (PQ-49), is open. | S1 § 9; PQ-24 |
| **F6** | A team review | {~~The coordinator's runtime creates the round folder and sends the review request with the document set to each member through tac; each returns a copy, which whoever created the round folder writes into it and records in the documents' storage; reminders go out before the deadline; the copies are merged and the round's blobs are released (`TAC > TAC-REVIEW`, CV.12).~>The coordinator's runtime (or, for document kinds it does not know, the coordinator's application) creates the round `round-<n>/` in the review folder (`TAC > TAC-REVIEW`, CV.17) and sends the review request with the round's documents through tac to each member who reaches the round only through tac; a member who can open the documents' storage works in the review folder and nothing travels (CV.19). Each member returns a copy through tac or another way; whoever created the round writes it into `returned/<member>/` and records it in the documents' storage (CV.11). The round's state is read from the folder (CV.18); reminders go out before the deadline; the copies are merged into `consolidated/` and the round's blobs are released (CV.12). How the round's documents travel through tac, how a review member is matched to a tac user and how long the round's blobs stay is open (PQ-66).~~} | S1 § 9{++; S29: FQ-9, FQ-11; S25: 09_woneb3, 13_woneb10++} |
| **F7** | A todo to another quest | An item or a walk is queued in a named run of another quest, on the same machine or another (a run the receiver does not have is refused; an item that names no run goes to the receiver's run `default`: `PAR > PAR-CROSS`, CW.20); it is taken, refused with a reason, or waits and is shown at the sender (CW.19); the done notification returns to the run and the session that queued it, when one was asked for (CW.23). From another team it arrives as a todo offer (`PAR > PAR-CROSS`, CW.26). | S1 § 9 |
| **F8** | Two executions on one repository | Each execution works in its own working tree on its own branch, holding a shared lease; when its todo is done it takes the repository's exclusive lease for the integration step, rebases, runs the checks, fast-forwards the branch the repository's record names (`RT > RT-LOCATIONS`, CR.104) and pushes; the next one rebases first. How the lease for the integration step coexists with the shared leases, where the fencing token is checked, and what happens when the step fails is open (PQ-46). | S1 § 9 |
| **F9** | A todo to the cloud (later) | A todo goes to a hosted agent or a runtime elsewhere; a branch comes back and is integrated as in F8. | S1 § 9 |
| **F10** | Supervising the team runtimes | trc reads through its runtime (`TAC > TAC-PEOPLE`, CI.4; on a phone or a tablet through the web runtime service, T8) the team runtimes and their endpoints from tac, attaches to each runtime's events, shows what waits (which run waits for which ask, and since when); the supervisor answers an ask, pauses a queue, continues a process. | S1 § 9 |
| **F11** | A machine joins | The runtime installation is placed; the user joins the team by invitation (`TAC > TAC-PEOPLE`, CI.6), pairs the device when it is off the VPN (`TAC > TAC-CRYPT`, CI.18), and the runtime registers (`TAC > TAC-COORD`, CA.3); it sees the team runtimes; nothing is converged for it unless the workspace switched on the fast-forward of repositories on which no lease is held (`PAR > PAR-APPROACH`, CW.16). On the GitHub backend, how a member is admitted is open (PQ-47). | S1 § 9 |
| **F12** | A version update | After the user asked for it, a host installs a new version of the runtime installation beside the old one; running runtimes go on. A migration of the workspace files runs only when the user confirmed it, once under the machine's file lock while the others pause; a runtime that meets files in an older format offers the migration or going back to an older runtime version. The standard for the `_ai` format (S22 § 5) migrates on each host's first start after the update instead; which holds is open (`RT > RT-VERSIONS`, CP.29; PQ-40), and this line stands until it is answered. | S1 § 9; PQ-6 |
| **F13** | An application on a phone, a tablet or in a browser attaches | The application connects to the web runtime service with the web runtime client SDK; the service connects to a runtime on its behalf, and that runtime registers with tac (`RT > RT-INSTALL`, CR.108, CR.110). How the service starts or finds that runtime, how long it lives, and which program the device reaches from the internet are assumed or open (PQ-38, PQ-41, PQ-49). | PQ-28 |

### <!--[NFR-GEN]--> 11.2 Generation units

What the project builds, as far as the sources state it. A generation unit is
one package or application with the technology it is written in.
The kinds in the table (server, client, and "shared" below) are the kind
names of the specification model's register of generation units, not the
terms of this document: by kind the runtime is a "server" there, though as a
program it is a runtime process and never a server.

| Id | Unit | Kind | Builds | Technology | Source |
| --- | --- | --- | --- | --- | --- |
| **G-1** | `tom_ai_runtime` | server (also a library inside the {~~VS Code extension~>new VS Code extension, as long as PQ-37 leaves that standing: `RT > RT-HOLDS`, CR.142~~}) | The runtime: engine, protocol, runtime tools, the MCP server, the tac client inside the runtime (whether that is the TypeScript tac client SDK of G-5 or one of its own, the Solution Blueprint settles) | TypeScript on Node; `tom_ai/ai_build/tom_ai_runtime` | S2 § 5, FO-1; S1 § 4 |
| **G-2** | `tom_tac_service` | server | The coordination and messaging service with its backends, the server mode and the relay | TypeScript on Node, no runtime dependencies; today in `tom_ai/vscode/`, to be in `tom_ai/ai_build/tom_tac_service` | S5; S2 § 5, FO-19 |
| **G-3** | `tom_tac_client` | client | The Dart tac client SDK | Dart, without Flutter | S1 § 12.1, CQ-15 |
| **G-4** | `tom_ai_runtime_client` | client | The Dart runtime client SDK; depends on `tom_tac_client` | Dart, without Flutter | S2 § 5, FO-11; S1 § 12.1 |
| **G-5** | the client SDKs of the eight other languages | client | A runtime client SDK and a tac client SDK each for TypeScript, JavaScript, Python, Java, Go, Rust, C and C++ | each in its language; `tom_ai/ai_build/tom_ai_runtime_nondart/<language>/` | S2 § 5, FO-10, FO-11; S1 § 12.1 |
| **G-6** | `tom_ai_runtime_ui` | client | The Flutter components and their gallery application (where the Review group is built: PQ-43) | Dart with Flutter; `tom_ai/ai_build/tom_ai_runtime_ui` | S2 § 5, FO-11; S1 § 12.2, § 12.3 |
| **G-7** | the supervision application (trc) | client (an application) | The supervision of the team runtimes, as a Webforge application that also runs standalone | Dart with Flutter; it may depend on Tom Forge packages | S2 § 5, FO-12; S1 § 12.4 |
| **G-8** | the web runtime client SDK for Dart | client | What an application on a phone, on a tablet or in a browser written in Dart uses to talk to the web runtime service | Dart | PQ-28; `CLI > CLI-PACK`, CL.12 |
| **G-9** | the web runtime client SDK for JavaScript / TypeScript | client | The same for web applications that are not written in Dart | JavaScript / TypeScript | PQ-28; `CLI > CLI-PACK`, CL.12 |
| **G-10** | the web runtime service | server | The HTTP-based service on a server through which such applications reach a runtime | not stated | PQ-28; `RT > RT-INSTALL`, CR.108 |

G-8 to G-10 are named by the answer to PQ-28 and nothing more: whether G-8 and G-9 are units of their own or a second binding of G-4 and G-5 is open (PQ-41), and so is what G-10 is and whether it is a unit beside G-1 (PQ-38); no mapper or emitter is named for them.

Delivered and not yet assigned to a unit, for the Solution Blueprint to assign: the conformance suite (`CLI > CLI-PACK`, CL.6); the {~~VS Code extension as a host on the new line (`DEC`, D-41)~>new VS Code extension, the copy of the extension in `tom_ai/ai_build` rewired to the runtime as the VS Code host (`DEC`, D-73; its folder and name: PQ-60)~~}; the tac server's command line and administration interface (`TAC > TAC-PEOPLE`, CI.20; `TAC > TAC-BACKENDS`, CA.27); the migration between backends (CA.33); the merge drivers of the `_ai` files (`LAND > LAND-BUILT`, E-5; `PAR > PAR-QUESTS`, CQ.6); the successor of today's Dart client of the extension (CL.10).

No source names a unit of the kind "shared". What the units share is the
runtime protocol's JSON schema and the TAC specification; the protocol layer
of every client SDK is generated from the schema {~~(S2 § 5, FO-10; `CLI > CLI-PACK`,
CL.4)~>(<- S2 § 5) (-> FO-10, CL.4)~~}.

**How the units are produced** is decided at the start of Phase 4 of the
specification process, not here {~~(PQ-17, PQ-19)~>(-> PQ-17, PQ-19)~~}. There, for each area of the
specification and for each unit, it is named which mapper or emitter writes
its code and what is produced directly from the specification's structured
output; a generator that is missing is built in that phase, so that as much
as possible is generated and a change later runs through regeneration
quickly. The units differ: for some a mapper or emitter fits, for others the
work starts from the structured output. Until then the register above names
the units and their technology, and no mapper.

**What the tooling offers** (the specification tooling of `LAND > LAND-BUILT`, E-21, as `tomspecs :ir-map --mapper` and `:ir-emit --standard` list them):

| Offered | Names |
| --- | --- |
| Mappers, which write a package from the intermediate form | `dart-tom`, `ts-shared`, `ts-react-client`, `ts-react-native-client`, `ts-hono-server`, `go-server`, `java-spring-server`, `csharp-aspnet-server` |
| Emitters, which write what a standard can express | `openapi`, `jsonschema`, `icu`, `asyncapi`, `markdown` |

The mappers write business applications: entities, repositories, HTTP routes
and screens. None of them writes a runtime, a protocol library or a command
line today {~~(S1 § 3.5)~>(<- S1 § 3.5)~~}; which are used, and which have to be built, is named
at the start of Phase 4.

**Which standard descriptions the project publishes** (JSON Schema for the
two protocols, OpenAPI for the coordination protocol's HTTP operations,
AsyncAPI for the streams) is decided in Phase 4 as well. {~~(PQ-18)~>(-> PQ-18)~~}

## <!--[DEC]--> 12 Decisions

Every decision of the product owner, as it stands. Source ids: `FO-n` in
{~~S2 § 5; `CQ-n`, `DQ-n`, `WQ-n` in S1 § 14.1; `RT-n` in S19; `RS-n` in S18. A~>S2 § 5; `CQ-n`, `DQ-n`, `WQ-n` in S1 § 14.1; `RT-n` in S19; `RS-n` in S18; the product owner's instructions of question round 5 in S31. A~~}
decision that a later one replaced is listed once, with the earlier id named
under "Replaces or completes".

**The product and its places**

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-1** | FO-1 | The runtime is the package `tom_ai/ai_build/tom_ai_runtime`. | RT-1 (a package `tom_quest_runtime` beside the extension) | `VIS > VIS-SYSTEM`, `NFR > NFR-GEN` |
| **D-2** | FO-19, CQ-15 | The tac service is `tom_ai/ai_build/tom_tac_service`; tac is a reusable component of its own, and its tac client SDK is a package of its own (`tom_tac_client` in Dart), on which the runtime client SDK depends; what the runtime client SDK takes from it is for the Solution Blueprint, since an application never speaks to tac itself, and the tac client SDK is used by runtimes and command-line programs of ours (D-63; `CLI > CLI-PACK`, CL.2, CL.11). | FO-19's "TAC clients in the API packages" | `TAC > TAC-BACKENDS`, `CLI > CLI-PACK` |
| **D-3** | FO-10, FO-11 | The runtime client SDK and the tac client SDK in nine languages: `tom_ai_runtime_client` for Dart, the others under `tom_ai_runtime_nondart/<language>/`; the protocol layer generated from the schema, a convenience layer by hand, one conformance suite. Beside them the web runtime client SDK, in Dart and JavaScript / TypeScript (D-65). Whether the web runtime client SDK is a client SDK of its own or the runtime client SDK with a second way to connect, and whether TypeScript and JavaScript are one client SDK, is asked (PQ-41, PQ-42). | {~~—~>S4 note k (the other languages generated mechanically from the Dart code; FO-10 generates them from the schema)~~} | `CLI > CLI-PACK` |
| **D-4** | FO-11, CQ-14 | Every reusable Flutter component lives in `tom_ai_runtime_ui`; Tom Forge's own component package builds on it. | — | `CLI > CLI-UI` |
| **D-5** | FO-12 | The supervision application is a Webforge application from the start that also runs standalone; it may depend on Tom Forge packages. | — | `CLI > CLI-TRC` |
| **D-6** | FO-16 | Telegram is deferred. | RT-9 (Telegram in the runtime) | `SCO > SCO-LATER` |

**The runtime**

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-7** | FO-2 | No transports implemented by a host: the runtime does not carry the VS Code language-model and Copilot chat transports; Copilot only through direct calls and its SDK. | S19's host transports | `RT > RT-TRANSPORTS`, `SCO > SCO-OUT` |
| **D-8** | CQ-5 | The Agent Client Protocol in both directions — one adapter for agents that speak it, and the runtime answering as an agent for editors — late in the order. | — | `RT > RT-TRANSPORTS` |
| **D-9** | FO-6, FO-17 | {~~Runtime tools live in the runtime, VS Code's tools stay in the extension and are registered with the runtime there;~>Runtime tools live in the runtime, VS Code's tools stay in the VS Code extension (the new extension, D-73) and are registered with the runtime there;~~} file, command, web and git tools are runtime tools for the model transports, never offered over the runtime's MCP server. | — | `RT > RT-TOOLS`, `RT > RT-MCP` |
| **D-10** | FO-5 | The streaming connection is length-prefixed JSON-RPC 2.0 over loopback TCP, with WebSocket for remote runtime clients. The web runtime service is HTTP-based; how the events of a run, asks and a host's tools cross it is open (D-65; PQ-41). | confirms RT-2 | `RT > RT-PROTO` |
| **D-11** | RT-7 | The protocol's commands are a superset of today's bridge methods. | — | `RT > RT-PROTO` |
| **D-12** | CQ-6 | The numbered events of a run are kept in memory with a bound; the trail files are the durable record. | — | `RT > RT-PROTO` |
| **D-13** | CQ-2 | The runtime owns machine-wide state; its implementation routes through the local tac service. What "coordination off" switches off while machine-wide state is routed through the local tac service, and what that service is, is asked (PQ-48). | — | `RT > RT-MACHINE` |
| **D-14** | FO-3, FO-4, DQ-9 | One installation per machine in the per-user application data folder, versions side by side; version checks, pass-through of unknown fields and upgrade callbacks in every client SDK. Which runtime a host installs and starts: D-49. | — | `RT > RT-INSTALL`, `RT > RT-VERSIONS` |
| **D-15** | CQ-4 | A runtime is started by its host and ends with it; standalone runtimes later. | — | `RT > RT-INSTALL` |
| **D-16** | RT-3 | The Agent SDK server of today becomes a mode of the runtime, so Webwork ships one Node payload. Open again: whether the mode is still needed, now that Webwork plans no use of it, is asked (PQ-37). | — | `RT > RT-TRANSPORTS` |
| **D-17** | RS-2, CQ-3, DQ-5 | The runtime finds its places through the workspace layout resolver; the repositories are those of the workspace's setup file; every todo is written with its own resources, and a quest's list of repositories and subtrees is the fallback. The quests are those of the register `_ai/quests.yaml` (D-71; `RT > RT-HOLDS`, CR.100). | RT-6, RT-10 (locations from a setting) | `RT > RT-LOCATIONS`, `PAR > PAR-APPROACH` |
| **D-18** | DQ-8, DQ-11 | The configuration is split by content: role types, processes and templates in the repository; providers, the allowed list and standard profiles as a team's configuration in tac, stored in whichever backend the team uses; the rest per runtime. Who changes a team's configuration on the GitHub backend, where no account and no owner records exist, is asked (PQ-47). | — | `RT > RT-CONFIG` |
| **D-19** | FO-15, CQ-16 | Secrets are references: `tsm:` followed by Tom Secrets Manager's own grammar, `os:`, and `env:` and `file:` as not-secure options; the runtime and the tac service are approved by Tom Secrets Manager once (D-69). | FO-15's `tsm:<vault>/<entry>` | `RT > RT-SECRETS` |
| **D-20** | CQ-7, DQ-3 | Asks are routed by presence and along a chain of persons: the person the process or the todo names, the quest owner, the owner of the quest whose todo triggered the ask, the team owners; every quest has a quest owner; an unanswered ask moves along that chain, can be forwarded and is monitored; while it is open, the run that asked waits and the other runs go on (D-61); asking people outside the team by e-mail is later. | DQ-3's "the rest of the queue goes on, and a walk goes on with the next todo that does not depend on the waiting one" (D-61) | `RT > RT-ASKS` |

**Coordination, people and messaging**

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-21** | CQ-8, WQ-2 | tac is specified as one `tac/2.0` and built in one go; a service announces its capabilities, and new ones are added within `tac/2.0`. | the minor versions in the earlier todos | `TAC > TAC-SPEC` |
| **D-22** | CQ-9 | The tac server is built as the full tac server (accounts, keys, quotas, administration); there is no smaller one before it; TLS ends at a reverse proxy. | the smaller tac server for one team | `TAC > TAC-BACKENDS` |
| **D-23** | FO-9 | The relay is part of the tac server, carries TAC and MCP, and only forwards. Whether it is on the path of a phone or a tablet, and which program a device reaches from the internet, is asked (PQ-49); the web runtime service is not a relay (D-65). | — | `TAC > TAC-BACKENDS` |
| **D-24** | DQ-1, PQ-23 | A team is a group of users, and its members' runtimes, the team runtimes, coordinate in it; there is no "agent group" as a thing of its own. One runtime belongs to one person. A team exists with each backend: on the GitHub backend a user's personal team or a simple team of several members (D-66). | DQ-1 in the part that kept it as a second thing | `TAC > TAC-PEOPLE`, `GLO` |
| **D-25** | CQ-10, DQ-2 | Identification by user id and e-mail and invitation with team tokens are both built; a team owner invites, a one-time password is passed on by the team owner, the tac server generates the user id; remote control only inside a team and only where the runtime's host allows it. Where identification is accepted: D-54. Whether invitation and team tokens exist on the GitHub backend is asked (PQ-47); what remote control covers is asked (PQ-50). | — | `TAC > TAC-PEOPLE` |
| **D-26** | DQ-12 | A quest has a home team; its runtime acts for another team only by explicit address, with the person's token for that team. | — | `TAC > TAC-PEOPLE` |
| **D-27** | WQ-1 | An application in a browser, on a phone or on a tablet reaches tac only through the web runtime service, which reaches tac through the runtime on the server (D-65); tac's participants are users and runtimes. This holds without exception: no application of the first version is a tac client (D-67). | the earlier answer that such an application registers in tac, and the concept's earlier text | `TAC > TAC-PEOPLE`, `NFR > NFR-TOPO`, `SCO > SCO-LATER` |
| **D-28** | FO-7, WQ-3 | User messages: conversations that are direct, among several members, or attached, stored with a retention of one year by default that a team may change. | — | `TAC > TAC-CONV` |
| **D-29** | FO-8, FO-21, CQ-11 | Documents travel as content-addressed blobs with a size limit, a quota and a lifetime of 7 days by default and 30 at most; a process may pin its blobs while it runs; a review set is a named set of pinned files. | FO-21's open concept for longer processes | `TAC > TAC-DOCS` |
| **D-30** | DQ-4 | The versioned documents and the record of a review are in the project's specification folder or a specification repository, usually not in the quest. | — | `TAC > TAC-DOCS`, `TAC > TAC-REVIEW` |
| **D-31** | FO-20 | Messages and blobs are not encrypted at rest by default; it is an option, its key in Tom Secrets Manager. | — | `TAC > TAC-CRYPT` |
| **D-32** | WQ-4 | Webwork is told what was decided; its requirements are covered by the product as a whole, built in one go. | — | `TAC > TAC-WEBWORK` |

**Parallel work and quests**

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-33** | CQ-12 | Whether executions work in a working tree of their own is a setting per repository that the team decides and can change. | — | `PAR > PAR-APPROACH` |
| **D-34** | FO-13, FO-18, FO-22 | Repository quests in the two forms of the standard for quests, a single-quest repository and a multi-quest repository (D-71); one personal repository per user with a folder per quest and personal notes; quest notes stay in the quest. Open again: the standard keeps a host's own files in the quest, one file per host, and has no personal repository, so the personal repository is asked again (PQ-53); what remains of a branch per member, the second repository for technical members, the scan for secrets and the members' access is asked (PQ-54). | — | `PAR > PAR-QUESTS` |
| **D-35** | CQ-13, DQ-8 | Handing todos to hosted agents is later; a data policy per quest or repository is later. | — | `SCO > SCO-LATER` |

**The specification and the delivery**

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-36** | PQ-19, PQ-17 | The specification's documents are TomSpecs documents, written in the TomSpecs process with all its phases: the Project Idea, the Solution Blueprint, the detailed documents, then the code generation, where the mapping per area and per unit is named at the start of Phase 4. | CQ-17 and DQ-10 (the Blueprint deepened, a detailed document only where a component needs one, the runtime implemented by hand); RS-5 | `DEL`, `NFR > NFR-GEN` |
| **D-37** | PQ-19 | The specification is made in a run of the TomSpecs process, through all its phases. Which steps of a phase can be skipped is suggested as the run proceeds, and the product owner decides each time. | CQ-1 and DQ-13 (a run of the idea-to-todos process on the concept, not the TomSpecs process) | `CON`, `DEL` |
| **D-38** | CQ-18, DQ-7 | The design is delivered as a complete inventory of the extension's screens, a description per screen and component, and a gallery application. | — | `CLI > CLI-SCREENS` |
| **D-39** | DQ-6 | Two tracks are built in parallel: tac, and the runtime. | — | `DEL` |
| **D-40** | RS-3, RT-5 | {~~The split of the extension starts after the extension's features and the workspace layout are finished.~>The copy of the old extension from which the new extension is built (D-73) is taken after the extension's features and the workspace layout are finished; when exactly it is taken is asked (PQ-61).~~} The extension's features include the new format of the `_ai` files and the quest management of the standard (D-71), which follow the cutover of the workspace layout (`RISK > RISK-DEPS`, R-15, R-16). | — | `DEL` |
| **D-41** | CQ-19 | {~~During the split the extension is branched, the new line has its own extension id and working tree, and it refuses to start beside the old one in the same window.~>Replaced by D-73: a copy of the extension in `tom_ai/ai_build`, not a branch.~~} | RS-1 | `DEL` |
| **D-42** | CQ-20 | The todos filed before the concept are input; a new set replaces them. | RS-4 | `DEL` |
| **D-43** | RT-8 | The Dart runtime client SDK is the client SDK Tom Forge builds on. | — | `CLI > CLI-PACK` |
| {++**D-73**++} | {++S31 (b)++} | {++The runtime is not extracted from the VS Code extension in place. The old extension (`tom_ai/vscode/tom_vscode_extension`) is copied into the repository `tom_ai_build` (`tom_ai/ai_build`) as the new extension, with an extension id of its own, and the copy is rewired to the runtime as the VS Code host until every feature of the old extension works as before, only distributed and with a team. The old extension is left as it is meanwhile. When the new extension works and is stable, it takes the old one's place (the swap) and looks like its next major version (v2); the old extension is retired, and both may be maintained side by side for a while. The new extension is in this product's scope as the VS Code host: its implementation of the host interface, its rewiring to the runtime, and its views for the team as far as PQ-62 decides; the old one's views are carried over, not redesigned (`SCO > SCO-OUT`, O-1). Open: its identity beside the old one, the swap, the retirement of the old one and which quest owns the new one after the swap (PQ-60); the copy point and what the old extension gets meanwhile (PQ-61); what "every feature as before" leaves out or adds (PQ-62).++} | {++D-41 (CQ-19: a branch of the extension); RS-1's recommended option (a), one source line with a pinned stable build — the product owner took RS-1 (b), a copied source folder as a second extension, in `tom_ai/ai_build`; the in-place extraction in stages of S19 § 7++} | {++`SCO > SCO-IN`, `SCO > SCO-OUT` (O-1), `LAND > LAND-WAIT` (E-22, E-23), `RT > RT-HOLDS` (CR.112), `RT > RT-INSTALL` (CR.142), `NFR` (N-10, N-33), `RISK` (R-1, R-31, R-32), `DEL`++} |
| {++**D-74**++} | {++S31 (a)++} | {++The first version of the runtime has the features of the VS Code extension, built and planned, of Webwork's plans for the runtime and tac (team review and review document bundles first), and of this quest's queued todos and documents, carried across machines, between the members of a team and over the internet. A feature of that baseline is in the first version unless a decision puts it out of scope or later (`SCO > SCO-OUT`, `SCO > SCO-LATER`); where carrying it across machines or to a team needs a choice, it is asked.++} | {++— (it changes no earlier decision; it settles the chat half of PQ-39 as built: D-61)++} | {++`SCO > SCO-IN`, `TAC > TAC-WEBWORK`, every part that describes a feature of the baseline, `DEL`++} |

**Decisions from the answers to the questions `PQ-1` … `PQ-23`** (the
product owner's answers of 2026-11-19, kept in
`01_02_Questions Round/answers.md`; D-36 and D-37 above are from these
answers too). PQ-5 and PQ-11 carry no decision of their own: each was asked again, PQ-5 as PQ-21 and PQ-11 as PQ-20, and their effect is cited under those ids.

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-44** | PQ-1, PQ-22 | The product owner (member id `alexis`, display name Alexis) is the only reviewer of the specification; no document type has a team of its own. | — | `USR > USR-TEAM` |
| **D-45** | PQ-8 | No fixed order of building: the order that reaches the finished product fastest, with two runs working in parallel. | — | `DEL` |
| **D-46** | PQ-2, PQ-3 | A run pins the version of its process and takes a changed definition over at a step boundary on confirmation, which is the usual case; a step declares preconditions, which the runtime enforces and the user can override. | — | `RT > RT-RUNS` |
| **D-47** | PQ-10 | Three backends are in the first version; the GitHub backend stays, for one user's machines and for simple teams of several members (D-66). | — | `TAC > TAC-BACKENDS` |
| **D-48** | PQ-4 | A short process for small changes is not part of this product; it is proposed in the quest `tom_specs`. | — | `RT > RT-RUNS`, `SCO > SCO-OUT` |
| **D-49** | PQ-6 | A host installs the runtime when none is installed and otherwise uses the installed one; an update happens only when the user was asked; a host too old for the runtime switches the features off or refuses to start; older workspace files are migrated or the runtime goes back to an older version, on the user's choice. | DQ-9 in the part "every host starts the version it was built with" | `RT > RT-INSTALL`, `RT > RT-VERSIONS` |
| **D-50** | PQ-7 | The runtime and tac client SDKs of all nine languages are in the first version, and the web runtime client SDK in Dart and JavaScript / TypeScript (D-65); whether TypeScript and JavaScript count as one language is asked (PQ-42). | — | `CLI > CLI-PACK` |
| **D-51** | PQ-9 | The supervision application runs on the phone and the tablet in the first version, reached from the internet as well as from the local network or the VPN; a device is paired and gets a key of its own. On a phone or a tablet it reaches a runtime through the web runtime service (D-65). No solution is given for applications on phones and tablets yet: which program a device reaches from the internet and holds the device keys, and whether phones and tablets stay in the first version, is asked (PQ-49). | CQ-10 in the part that defers the pairing; WQ-1 in the part that defers the runtime host server | `CLI > CLI-TRC`, `NFR > NFR-TOPO`, `SCO > SCO-LATER`, `TAC > TAC-CRYPT` |
| **D-52** | PQ-16 | Standalone runtimes, also those on an always-on machine, are later; the web runtime service is part of the model (D-65). That it runs permanently and hosts one runtime per connected application, each ending with that application's connection, is assumed until PQ-38 is answered. | — | `RT > RT-INSTALL`, `NFR > NFR-TOPO` |
| **D-53** | PQ-12, PQ-23 | An owner of a team may do what the table of rights says; the team runtimes need nothing created or deleted. Who is an owner of a team on the GitHub backend is asked (PQ-47). | — | `TAC > TAC-PEOPLE` |
| **D-54** | PQ-13 | Open (identification) or strict (invitation and team tokens) is a setting of the tac server, for everyone on it; every access from the internet is strict and that cannot be configured. | D-25 in the part that leaves open where identification is accepted | `TAC > TAC-PEOPLE` |
| **D-55** | PQ-14 | The whole approach to parallel work is confirmed; in strict mode an execution holds an exclusive lease for the whole todo, and a repository without working trees per execution is always in it. How the exclusive lease of the integration step is taken while others hold shared leases, and who checks the fencing token at the push, is asked (PQ-46); whether a lease is kept while its run waits for an ask (D-61) is asked (PQ-39). | — | `PAR > PAR-APPROACH` |
| **D-56** | PQ-15 | The new packages are BSD-3; for now they are published only to pub.dev and to the workspace's binaries repository. That repository is public, so nothing bundled into what it carries has a copyleft licence (`NFR`, N-29). | — | `NFR` |
| **D-60** | S21, TQ-1 … TQ-11 | The terminology is agreed: agent, user and person, account, team runtimes and their visibility, todo offers, claim and lease, exclusive and shared leases, strict and worktree mode, execution, resources and their names (with a prefix: D-68), application, host, client and server. The glossary states it. Further terms the document uses in a fixed sense: D-70. | the earlier glossary; "agent group", "customer", "touch set", "unit", "grant" and "request" as nouns, "lock" for a lease | `GLO`, `TAC > TAC-COORD`, `TAC > TAC-PEOPLE`, `PAR > PAR-APPROACH` |
| **D-57** | PQ-17, PQ-18 | Which mapper or generator writes which unit, and which standard descriptions are published, is decided at the start of Phase 4; missing generators are built there. The API documentation of the client SDKs and hand-written user and programmer's guides are delivered. | — | `NFR > NFR-GEN`, `NFR` |
| **D-58** | PQ-21 | The link between a host and its runtime is an API with callbacks in both directions over a wire protocol of JSON structures; its records get object models worked out from the workspace's existing schemas; the shape of a conversation and of a question on the wire is settled in the interface specification; unloading runs is an option, not part of the first version unless measurement warrants it. | — | `RT > RT-PROTO`, `RT > RT-INSTALL` |
| **D-59** | PQ-23 | A resource is a whole repository or a part of one described by a pattern, named and not registered, its name written with the prefix `git:` (D-68); tac knows only the leases it has given and answers a claim from them; a runtime works with what its user can reach. How a person joins a tac server and creates a team: D-72. | S5's declared "units" and infrastructure resources, for now |`TAC > TAC-COORD` |
| **D-72** | PQ-20 | Whoever installs a tac server creates the first account and its first access key from the tac server's command line; with that key a person joins the tac server, creates a team and is its first team owner; the others join the team by invitation. | D-59 in the part that held this sentence | `TAC > TAC-PEOPLE`, `TAC > TAC-PEOPLE > TAC-GROUPS` |

**Decisions from the answers to the questions `PQ-24` … `PQ-33`** (the product owner's answers of 2026-11-20, kept in `01_04_Questions Round/answers.md`), and the standard for the `_ai` state the product owner named with them:

| Id | Source id | Decision | Replaces or completes | Shaped |
| --- | --- | --- | --- | --- |
| **D-61** | PQ-24 | While an ask of a run is open, the run that asked waits: nothing further is sent from its queue until the ask is settled (answered, closed unanswered with its execution, or resolved by its declared default). The other runs go on. A walk does not go on with another todo meanwhile. {~~Whether the execution keeps its leases while its run waits, and whether a chat send in another session of that run still goes out, is asked (PQ-39).~>A chat send in another session of that run still goes out, as the old extension does it today (D-74; `RT > RT-QUEUE`, CR.67); whether the execution keeps its leases while its run waits is asked (PQ-39).~~} | DQ-3's "the rest of the queue goes on" and the walk going on with the next todo (D-20) | `RT > RT-ASKS` (CP.21), `RT > RT-QUEUE` (CR.23, CR.67), `RT > RT-SECRETS` (CS.10), `PAR > PAR-APPROACH` (CW.4), `NFR`, N-15 |
| **D-62** | PQ-25 | A run can start a session over: the same named session begins a new conversation with the model, with empty history, and what was said before stays in the trail. No new session is created for it. | — | `RT > RT-QUEUE` (CR.18), `GLO` session |
| **D-63** | PQ-26 | The tac client SDK is used by runtimes and command-line programs of ours; no server uses it. A program on a server reaches tac only through the runtimes it starts, which present the user's team token. | — | `CLI > CLI-PACK` (CL.11, CL.12), `RT > RT-INSTALL` (CR.110) |
| **D-64** | PQ-27 | tac keeps no record for whoever holds leases: a lease names its holder (the runtime, the quest, the run, the item, the machine and the workspace), and a restarted runtime finds its leases by those names. That an execution started or ended is still announced to the other runtimes. | the session record of `tac/1.0` (`LAND > LAND-BUILT`, E-19) | `TAC > TAC-COORD` (CA.5, CA.8, CA.20), `CON`, X-11 |
| **D-65** | PQ-28 | A runtime does not run on a phone, on a tablet or in a browser. An application there uses the **web runtime client SDK**, provided in Dart and in JavaScript / TypeScript, and talks to a **web runtime service** on a server, which connects to a runtime on its behalf. The service is HTTP-based, and one service may serve applications on phones and tablets and web applications, built with Flutter or not; it reaches tac through the runtime on the server (D-63). This is a direction, not a design: what the service is (PQ-38), what the web runtime client SDK is beside the runtime client SDK (PQ-41), and which program a device reaches from the internet (PQ-49) are asked. | the runtime host server as the name and the runtime client SDK against it (D-27, D-52) | `RT > RT-INSTALL` (CR.108 … CR.110), `CLI > CLI-PACK` (CL.11, CL.12), `TAC > TAC-PEOPLE` (CI.4), `NFR > NFR-TOPO` (T8, F13), `NFR > NFR-GEN` (G-8 … G-10) |
| **D-66** | PQ-29 | The local backend works on one machine only; its team is the personal team of one user on that machine. The GitHub backend serves a user's personal team across the user's machines that share the coordination repository, and simple teams of several members. What a team on the GitHub backend has beyond leases and endpoints, and who is a member and an owner there, is asked (PQ-47). | the personal team as the team of a user "without a tac server"; the GitHub backend for one user's machines only (X-11) | `TAC > TAC-BACKENDS` (CA.26), `TAC > TAC-PEOPLE` (CA.39, CI.1), `NFR > NFR-TOPO` (T3, T4), `GLO` personal team, team |
| **D-67** | PQ-30 | No application of its own for reviewing is part of this product: reviewing is part of the applications that carry the review component (`SCO > SCO-OUT`, O-10). Every application reaches tac through its runtime, with the runtime client SDK; services that use tac directly through the tac client SDK, for a part of it such as messaging, are possible later and not planned (`SCO > SCO-LATER`, L-12). In the first version messaging is in Webwork, through its runtime; {~~the VS Code extension gets messaging once the runtime is built, in views of its own.~>messaging comes to VS Code with the new extension (D-73), in views of its own.~~} Where the review component is built is asked (PQ-43). | the glossary's "review application" | `SCO > SCO-OUT` (O-10), `SCO > SCO-LATER` (L-12), `TAC > TAC-PEOPLE` (CI.4), `TAC > TAC-BACKENDS` (CA.28), `CLI > CLI-UI` (CU.9) |
| **D-68** | PQ-31 | A resource's name starts with a prefix that names its notation. `git:` is the only prefix for now, for a whole repository (`git:<owner>/<repository>`) or a part of one described by a pattern (`git:<owner>/<repository>#<pattern>`). A part of the `_ai` state's repository is claimed for a todo like any other part, only when the todo names it among its resources; todo state and journals are never named. Further prefixes are added as further kinds of resource are needed; resources with different prefixes never overlap. The details of the grammar are asked (PQ-45). | the kind "folder of the `_ai` state" of `tac/1.0` (E-19); the names without a prefix of D-59 | `TAC > TAC-COORD` (CA.9, CA.10, CA.11, CA.17), `GLO` resource name |
| **D-69** | PQ-32 | "Pairing" is used for devices only. The runtime and the tac server are approved by the Tom Secrets Manager service once, each as a program of its own; a setup guide describes the approval. | "paired with Tom Secrets Manager" in D-19 | `RT > RT-SECRETS` (CS.9), `USR`, U-7, `NFR`, N-30, `GLO` pairing |
| **D-70** | PQ-33 | The glossary gets an entry for every further word the document uses in a fixed sense, in a table of further terms, with "profile" and "coordinator" defined there; the terminology document (S21) gets the same entries, so that glossary and terminology stay equal. | — | `GLO`; S21 |
| **D-71** | PQ-24 (its second part); S22 | al_the_bear's approach to the `_ai` state and to quests in repositories is the standard: the format version the runtime is built on, the layout of the quest folder, the four classes of files, three types of quest in one register `_ai/quests.yaml` (a classic quest; a repository quest as a single-quest repository or a multi-quest repository) and the operations on quests. Where it differs from this document, the document follows it, except where that would drop something a decision of the product owner backs; there the question is asked: the personal repository (PQ-53), what of D-34 remains for repository quests (PQ-54), the quest operations as commands of the runtime (PQ-55), and when a migration runs (PQ-40). | S2 § 3.7 and S12 where they differ; the first part of D-34 ("repository quests as planned") | `PAR > PAR-QUESTS` (CQ.1, CQ.5, CQ.7, CQ.9 … CQ.13), `RT > RT-HOLDS` (CR.2, CR.3, CR.100), `RT > RT-VERSIONS` (CP.29), `LAND > LAND-BUILT` (E-14) |

## <!--[CON]--> 13 Contradictions

Where sources disagree, and how it is resolved. The cross-check S10 § 6
lists four of them from the TomSpecs tooling's reading of this quest's
documents (X-1, X-8, X-9, X-10); they stand here as that reading found them.

- **X-1** **Host transports and host tools.** S19 gives a host its own
  transports and tools; S2 § 3.1 says a host "provides no tools and no
  transports"; S3 (WR-7) and S14 need tools that the host carries out —
  Webwork's document tools, Tom Forge's equivalents of the editor tools.
  **Resolved:** there are {~~no host transports (D-7). There are host tools~>no host transports (-> D-7). There are host tools~~}: a
  host registers its tools with its runtime, and the runtime calls the host
{~~  back (S1 § 6.3; `RT > RT-TOOLS`). S2's "VS Code tools stay in the~>  back (<- S1 § 6.3; `RT > RT-TOOLS`). S2's "VS Code tools stay in the~~}
  extension" and Webwork's "document tools executed in Webwork" are the same
  thing.
- **X-2** **The secret reference.** S2 § 5 (FO-15) writes a Tom Secrets
  Manager reference as `tsm:<vault>/<entry>`; S15 gives the grammar
  `[env:prod]store/path#field`. **Resolved:** the prefix `tsm:` is followed
{~~  by Tom Secrets Manager's own grammar unchanged (D-19).~>  by Tom Secrets Manager's own grammar unchanged (-> D-19).~~}
- **X-3** **An application without a runtime.** S3 (WR-2, WR-6) asks that Webwork
  in a browser or on a phone registers in tac itself, with a Dart tac client that
  needs no runtime; an earlier answer of the product owner said such an application
  connects "through a server part that runs the runtime for them", with a
  partial direct connection for messaging to be investigated; S1 at first had
  such an application talk to tac directly. **Resolved:** every application reaches tac
  through a runtime; an application in a browser, on a phone or on a tablet uses {~~the web runtime service, which reaches tac through the runtime on the server (D-27, D-65). No application of the first version is a tac client; services that use tac directly are possible later and not planned (D-67; `SCO > SCO-LATER`, L-12).~>the web runtime service, which reaches tac through the runtime on the server (-> D-27, D-65). No application of the first version is a tac client; services that use tac directly are possible later and not planned (-> D-67; `SCO > SCO-LATER`, L-12).~~} WR-2 and WR-6 are met differently than asked, and
  Webwork's messaging on the web and the phone comes with the web runtime service, in Webwork's wave 3 (`TAC > TAC-WEBWORK`; `SCO > SCO-LATER`, L-8).
- **X-4** **Two scopes of the tac server.** S6 and S5 plan the full tac server with
  "customers" (in the product: accounts), keys, quotas and an administration
  interface; S3 (WR-1) asks for a small team's tac server without them.
  **Resolved:** the tac server is built as the full tac server, and there is no smaller one before it; a small team is that tac server
{~~  with one account (D-22).~>  with one account (-> D-22).~~}
- **X-5** **"Group", "agent group" and team.** S13 says "a Webwork team is
  one tac group"; S5 uses "agent group" for runtimes that coordinate; S1
  § 7.3 (DQ-1) kept the two apart. **Resolved:** a team is a group of users, and its
  members' runtimes, the **team runtimes**, coordinate in it; S5's term
{~~  names no thing of its own and is not used (D-24, D-60).~>  names no thing of its own and is not used (-> D-24, D-60).~~}
  Webwork's "one team, one group" holds as "one team".
- **X-6** **One `tac/2.0` against stepwise versions.** The earlier plan (the
  todos S1 § 7.10 describes) added to the protocol in minor versions, one per
  capability; S5 § 8 says minor
  versions only add. **Resolved:** one specification `tac/2.0`, built in one
{~~  go, with capabilities announced on connect (D-21).~>  go, with capabilities announced on connect (-> D-21).~~}
- **X-7** **How the specification is made.** S1 § 13.1 and § 14.1 record the
  product owner's decision that the specification "is made in the
  `idea_to_todos` run on this concept, not in the tom_specs process", with
  the Solution Blueprint deepened and a detailed document only where a
  component needs one. This Project Idea is Phase 1 of a run of the TomSpecs
  process. **Resolved:** the decision has changed. The specification is made
  in the TomSpecs process with all its phases; steps that can be skipped are
{~~  suggested as the run proceeds (D-37, D-36). The idea run on the concept is~>  suggested as the run proceeds (-> D-37, D-36). The idea run on the concept is~~}
  not started.
- **X-8** **Which quest owns the coordination.** S5, S6 and S16 name a quest
  `agent_coordination` as the quest that owns tac and the parallel-work rules;
  that quest does not exist. **Resolved:** the quest `ai_runtime` owns them
{~~  (S1 § 2.4).~>  (<- S1 § 2.4).~~}
- **X-9** **Where the packages are.** S19 and S6 place the runtime and the
  service in `tom_ai/vscode/`, the runtime under the name
  `tom_quest_runtime`; `tom_tac_service` is there today. **Resolved:**
  `tom_ai/ai_build/tom_ai_runtime` and `tom_ai/ai_build/tom_tac_service`
{~~  (D-1, D-2); the service is moved.~>  (-> D-1, D-2); the service is moved.~~}
{~~- **X-10** **Telegram.** S19 puts Telegram into the runtime; S6 keeps it out
  of the coordination idea. **Resolved:** deferred (D-6).~>- **X-10** **Telegram.** S19 puts Telegram into the runtime; S6 keeps it out
  of the coordination idea. **Resolved:** deferred (-> D-6).~~}
- **X-11** **Messages over the GitHub backend.** S6 says the GitHub backend
  carries no messages between machines; S2 § 3.4 has it keep the blobs of
  messages in the coordination repository. **Resolved:** the GitHub backend
  stays in the first version as S6 designed it, for leases and
{~~  endpoints (tac keeps no record of the holder of leases: D-64), for one user's machines and for simple teams of several members (D-66); messaging, documents and reviews across machines are on the
  tac server (D-47; `TAC > TAC-BACKENDS`, CA.26).~>  endpoints (tac keeps no record of the holder of leases: D-64), for one user's machines and for simple teams of several members (-> D-66); messaging, documents and reviews across machines are on the
  tac server (-> D-47; `TAC > TAC-BACKENDS`, CA.26).~~} Whether a team on the GitHub backend gets any of them through the coordination repository is asked (PQ-47).
- **X-12** **Runtimes on an always-on machine and the lifetime of a runtime.** S1 § 8 has a
  topology in which an always-on machine runs runtimes without a window
  (T6); the decision is that a runtime is started by its host and ends with
{~~  it, with standalone runtimes later (D-15). **Resolved:** standalone
  runtimes on an always-on machine are later; the web runtime service is part of the model and is not a standalone runtime (D-52, D-65);~>  it, with standalone runtimes later (-> D-15). **Resolved:** standalone
  runtimes on an always-on machine are later; the web runtime service is part of the model and is not a standalone runtime (-> D-52, D-65);~~} that it hosts one runtime per connected application, each ending with that application's connection, is assumed until PQ-38 is answered.
- **X-13** **Which runtime a host starts.** The earlier answer was that every
  host carries the runtime version it was built with and starts that version
  {~~(S1 § 5.7, DQ-9)~>(<- S1 § 5.7) (-> DQ-9)~~}. The answer to PQ-6 is that a host
  installs a runtime only when none is installed, otherwise uses the
  installed one, and that nothing is updated without the user having been
{~~  asked. **Resolved:** the later answer holds (D-49). Versions can still lie
  side by side (CR.41), which is what going back to an older runtime needs
  (CP.33).~>  asked. **Resolved:** the later answer holds (-> D-49). Versions can still lie
  side by side, which is what going back to an older runtime needs
  (-> CR.41, CP.33).~~}
- **X-14** **Pairing of devices and the server side for phones, later or now.**
  S1 § 11.1 defers both (CQ-10, WQ-1). The answer to PQ-9 puts the supervision application on the phone in the first version,
  reached from the internet. **Resolved:** the pairing of devices and the
{~~  web runtime service (D-65) for the supervision application are in the first
  version (D-51);~>  web runtime service (D-65) for the supervision application are in the first
  version (-> D-51);~~} Webwork's builds for the web and the phone stay later (`SCO > SCO-LATER`, L-8). Open again: the answer to PQ-28 gives no solution for phones and tablets yet, so whether they stay in the first version, which program a device reaches from the internet, and whether end-to-end encryption is in the first version (L-6) are asked (PQ-49).
- **X-15** **Declared resources or named ones.** S5 and S6 have "units" and
  infrastructure resources declared in tac's data, and four kinds of
  resource. The answer to PQ-23 is that a
  resource is only named when it is claimed, that there are two kinds for
  now, and that tac keeps no list of resources. **Resolved:** the later
{~~  answer holds (D-59). A resource's name carries a prefix~>  answer holds (-> D-59). A resource's name carries a prefix~~} for its notation, and there is one prefix for now, `git:`, for a whole repository or a part of one; a folder of the `_ai` state is claimed as a part of a repository, and {~~further prefixes are added as they are needed (D-68).~>further prefixes are added as they are needed (-> D-68).~~}

- **X-16** **Where the team token is kept.** Webwork plans to keep a user's team token and messaging account {~~in its own settings container (S25: `13_woneb6`);~>in its own settings container (<- S25: `13_woneb6`, planned);~~} CS.11 keeps the team tokens in the runtime, as secrets named by references, one place per machine and user for every host, and a host supplies no credential through the host interface (CP.13). {~~**Resolved:** the runtime keeps them (D-19; `RT > RT-SECRETS`, CS.11).~>**Resolved:** the runtime keeps them (-> D-19; `RT > RT-SECRETS`, CS.11).~~} The quest `webwork` is told before its specification D40 is written (`DEL`).
- **X-17** **Where a person's own files of a quest lie.** The standard for quests (S22 § 3.2) keeps a host's sessions, its compact trail, the journal of asks and answers, the host's configuration and the memory candidates in the quest folder, one tracked file per host, and has no personal repository. `PAR > PAR-QUESTS`, CQ.2 and CQ.3, and D-34 keep them "in the personal repository and never in a quest's", one personal repository per user. **Not settled:** asked (PQ-53). Until it is answered CQ.2, CQ.3 and D-34 keep their text, and new text says "per host" without a place.
- **X-18** **When a migration of the workspace files runs.** The standard (S22 § 5) migrates on each host's first start after the update, without a confirmation, and records it in a versioned file; `RT > RT-VERSIONS`, CP.29 and CP.32, run it once per machine, under a lock, {~~and only when the user confirmed it (D-49). **Not settled:** asked (PQ-40).~>and only when the user confirmed it (-> D-49). While the old extension's own engine and the runtime both work on one machine (D-73; `RT > RT-HOLDS`, CR.112), which format version both use and when it may change is part of the same question. **Not settled:** asked (PQ-40).~~}
- **X-19** **Where the review component is built.** `CLI > CLI-UI`, CU.1 and CU.3: `tom_ai_runtime_ui` holds every reusable component, among them the Review group, {~~and depends on nothing of Tom Forge (D-4).~>and depends on nothing of Tom Forge (-> D-4).~~} `RISK > RISK-DEPS`, R-19, and the quests `webwork` and `tom_forge` plan the component outside this product: as the extension's document browser page in a web view, and {~~as a Dart component in the `tom_forge` repository (S25: `09_woneb5`; S26: `05b_woneb1` … `05b_woneb5`).~>as a Dart component in the `tom_forge` repository (<- S25: `09_woneb5`; S26: `05b_woneb1` … `05b_woneb5`).~~} **Not settled:** asked (PQ-43). Until it is answered CU.6's Review group, CU.9, G-6 and R-19 keep their text.
- **X-20** **Coordination off by default, and everything routed through the local tac service.** `TAC > TAC-BACKENDS`, CA.31: "With coordination switched off (`mode: off`, the default) nothing is coordinated and everything works as it does without tac." D-13 and `RT > RT-MACHINE`, CR.38: the runtime's machine-wide state is routed through the local tac service, and every runtime registers with it (CA.34). **Not settled:** asked (PQ-48).
- **X-21** **The fleet's plan for its tac server.** The fleet's todo for the tac server on the always-on machine describes a service run from that machine's clone, reachable on the VPN only, {~~written before the accounts and the relay were decided (S27: al_the_bear `14_loose_wslayout-6_akto-coordination-server-on-bigbeast`);~>written before the accounts and the relay were decided (<- S27: al_the_bear `14_loose_wslayout-6_akto-coordination-server-on-bigbeast`);~~} `TAC > TAC-BACKENDS`, CA.27 … CA.30, and `NFR`, N-28 and N-29, have the full tac server with accounts, a public address for the relay behind a reverse proxy, and what it installs from the binaries repository. {~~**Resolved:** this document holds (D-22, D-23); the fleet's todo is rewritten against it (CA.28; `RISK > RISK-DEPS`, R-20).~>**Resolved:** this document holds (-> D-22, D-23); the fleet's todo is rewritten against it (-> CA.28; `RISK > RISK-DEPS`, R-20).~~}
- {++**X-22** **The extension's own collaboration plan against tac.** The quest `vscode_extension` planned its own collaboration model on 2026-11-24 (S28; its 76 `caf_…` todos): leases kept as git refs in a table per repository, stale after 30 minutes; the notation `<type>://<server>[:<port>]/<path>` for resources; a branch `todo/<id>` and a working tree `<folder>@<branch>` per todo, with a merge tool; agent groups with a supervisor run; features (group todos in phases) with feature runs and Wait and Notify items; the standard runs `planning` and `quest-keeper`; review todos; an issue flow. This document has tac's leases (60 minutes, fencing tokens, names with the prefix `git:`), worktree mode and an integration step, and no agent group of its own. D-74 makes the extension's planned features part of the first version's baseline, so the two plans meet. **Not settled:** asked (PQ-63; the notation in PQ-45, the lease rules in PQ-46). Until it is answered no `caf_…` feature is written as an item of the runtime, and D-24 and D-68 stand. (-> D-24, D-55, D-68, D-74) (<- S28)++}
- {++**X-23** **Where the runtime and the Dart runtime client SDK are.** The product owner's answer in this quest's todo `ww_e_runtimeapi-1` places the Dart runtime client in the tom_vscode repository as `tom_runtime_scripting_api` and says "the runtime shall go into the vscode repository, too"; D-1 and `CLI > CLI-PACK`, CL.3, place the runtime and the Dart runtime client SDK in `tom_ai/ai_build`. **Resolved:** D-1 holds, and D-73 puts the new extension in `tom_ai/ai_build` too; `tom_vscode_scripting_api` keeps only the VS Code namespace and re-exports the Dart runtime client SDK (`CLI > CLI-PACK`, CL.13). The todo is replaced by the specification's todos. (-> D-1, D-42, D-73) (<- S30: ww_e_runtimeapi-1)++}
- {++**X-24** **Telegram in this quest's todos.** This quest's todo `ww_f_collab-6` plans one Telegram bot token for every runtime and one chat per machine. **Resolved:** Telegram is deferred for the runtime (`SCO > SCO-LATER`, L-9), and the todo stays deferred; the old extension keeps its Telegram per quest, and whether the new extension keeps it is asked (PQ-62). (-> D-6) (<- S30: ww_f_collab-6)++}
- {++**X-25** **Copies of a review that do not travel through tac.** `TAC > TAC-REVIEW`, CV.11, had tac carry every copy of a review round, so that nobody carries files by hand; Webwork decided that tac is one of several channels, beside export and import as a file, mail through the system's mail client and a file put into the review folder by hand. **Resolved:** Webwork's decision holds: tac carries the documents for the members who reach the round only through tac, and a copy that arrives another way counts the same once it is in the review folder (`TAC > TAC-REVIEW`, CV.11, CV.17, CV.18). (<- S29: FQ-9, FQ-11)++}
- {++**X-26** **The in-place split against a second extension.** S19 § 7 and this quest's todos `ww_b_workbench-2` … `7` move the engine out of the running extension stage by stage, the extension working after each stage; S18 § 3 recommends one source line with a pinned stable build (RS-1 (a)); D-41 had the extension branched. The product owner's instruction (b) of round 5 leaves the old extension as it is and builds the new extension from a copy in `tom_ai/ai_build`. **Resolved:** D-73 replaces D-41 and the in-place extraction; the stages are replanned against the copy (`DEL`). (-> D-73) (<- S31; S30: ww_b_workbench-2 … ww_b_workbench-7)++}

## <!--[RISK]--> 14 Risks and dependencies

### <!--[RISK-RISKS]--> 14.1 Risks

| Id | Risk | Trigger | Source |
| --- | --- | --- | --- |
| **R-1** | {~~**The split of a large extension while it keeps changing.** The engine is entangled with the extension: the queue manager and the model handler are large, and process-wide singletons assume one quest per process. Changes to the old line during the split have to be carried into the new one.~>**Two copies of one large code base.** The old extension and its copy, the new extension, diverge from the copy point: every fix the old one still gets has to be repeated in the new one, and a feature added to the old one after the copy point is a feature the new one lacks. The engine the copy carries is entangled with the extension (the queue manager and the model handler are large, and process-wide singletons assume one quest per process), so rewiring it to the runtime is large work, done while the old one stays in daily use.~~} | {~~A feature or fix lands in the extension after the split has begun; a stage of the split leaves the extension not working.~>A fix or a feature lands in the old extension after the copy point (what it still gets meanwhile is asked: PQ-61); a step of the rewiring leaves the new extension not working or not installable (`NFR`, N-33).~~} | {~~S19; S1 § 13.3; S18~>S19; S18; S31 (D-73)~~} |
| **R-2** | **What is specified moves.** The extension's features change while they are described; the descriptions of screens and of engine behaviour go out of date. | A change in the extension to a view or an engine feature that a section here describes. | S1 § 12.3, DQ-7; S17 |
| **R-3** | **Team features nobody else has used.** Teams, invitations, escalation of asks and the review exchange are designed by and for one person with several machines. | The first second person joins a team, on a tac server or through the GitHub backend (D-66); a reviewer without a repository takes part in a review, through an application that carries the review component and is built outside this product (D-67). | S1 § 7.3, § 6.6, § 7.7; S9; PQ-29, PQ-30 |
| **R-4** | **Overlap with protocols others maintain.** The runtime protocol covers ground the Agent Client Protocol, A2A, MCP and the vendors' own protocols cover; they change quickly. | A revision of one of them (MCP's revisions of 2025-11 and 2026-07 differ); an agent or editor the product wants to reach speaks only one of them. | S9; S1 § 15.1, § 6.4 |
| **R-5** | **Vendors' interfaces in preview.** The agent SDKs and command lines the agent transports rest on, and every interface for hosted agents, are preview or beta; one hosted agent service was shut down with two months' notice. | A vendor changes or withdraws an interface a transport uses. | S9; S1 § 11.5, § 15.4 |
| **R-6** | **The full tac server before anybody uses it.** Accounts, quotas and the administration interface are built before a first team works on the tac server. | The first team's use shows needs the full tac server did not foresee; Webwork's messaging waits for parts it does not need. | S1 § 7.2, CQ-9; S3 |
| **R-7** | **Everything in one go.** tac is built to the whole of `tac/2.0` and Webwork is told the product is built in one go; nothing is used before all of it is there. | An early part proves wrong only when a later part uses it. | S1 § 7.9, WQ-2, WQ-4 |
| **R-8** | **Webwork's messaging on the web and the phone waits.** It comes in Webwork's wave 3, with the web runtime service (`SCO > SCO-LATER`, L-8); until then its messaging works on the desktop only. The web runtime service it will use (D-65) is in the first version for the supervision application, as far as the open questions on it leave that standing (PQ-38, PQ-49). | Webwork's team needs messaging or review on a phone or in a browser before the web runtime service carries Webwork's builds there. | S1 § 7.10, WQ-1; S13; PQ-9; PQ-28 |
| **R-9** | **Another writer in the repositories.** Other sessions, runs and machines write to the same repositories on one branch while this product is specified and built; uncommitted work of others is in the way of builds and installs. | Two runs touch the same repository; a build or an install runs from a tree another session left changed. | S16; S1 § 10.1 |
| **R-10** | **Leases held for the work of agents.** Others found that what they call "locks", held by agents, are held too long or never given back. | An execution ends without its lease being released; a long execution holds a lease on a repository; a run waits for a person while its execution holds a lease, in strict mode an exclusive one (R-25; whether the lease is kept meanwhile is asked: PQ-39). | S9; S1 § 15.2 |
| **R-11** | **No gate before the main branch until the integration step exists.** Until then a broken commit is at once every other session's base. | An execution commits a change that breaks a package others build on. | S1 § 10.1, § 10.3 |
| **R-12** | **Nine languages.** Six of the client SDKs are tested only through the conformance suite; nobody uses them yet (see also R-24). The web runtime client SDK adds a third client SDK in Dart and JavaScript / TypeScript (D-65); whether TypeScript and JavaScript are one client SDK is asked (PQ-42). | A first user of such a client SDK meets what the suite does not cover. | S2 § 3.5; S1 § 12.1; PQ-7 |
| **R-13** | **Several hosts and runtime versions on one set of workspace files.** On one machine the hosts share the runtime installation, and a host too old for it switches its features off or does not start. Across machines and people the files are shared through git: once they are migrated on one machine, every runtime elsewhere that is older stops working on them until it is updated. | A migration runs on one machine while another machine, or another member of the team, still runs an older runtime (whether it runs only after the user confirmed it, or by itself on a host's first start as the standard has it, is asked: PQ-40); an application is not yet available in a version that fits the runtime installation; a machine that was offline for weeks comes back and meets files in a newer format. | S1 § 6.7, § 9 F12; PQ-6; S22 § 5; S27 (`repo_structure_new.md` § 2) |
| **R-14** | **The product's value depends on others being able to use its parts.** The protocol, the process format and the coordination are entangled with this workspace's conventions. | A user outside this workspace tries to use tac or a client SDK without the rest. | S9; S1 § 15 |

**Further risks.** They are numbered after the dependencies R-15 … R-21 below.

| Id | Risk | Trigger | Source |
| --- | --- | --- | --- |
| **R-22** | **An architecture for phones and browsers that is not designed yet, reachable from the internet in the first version.** The tac server and the web runtime service (D-65) are reached by phones from the internet before the product has been used by anyone but the product owner; the security model is written for a case the first design had deferred. What the web runtime service is (PQ-38), and which program a device reaches from the internet and holds the device keys (PQ-49), are asked; until they are answered the security model has no design to check. | The public address of the tac server or of the web runtime service is opened; a device is lost; a team token or a device key leaks. | PQ-9, PQ-13; `TAC > TAC-CRYPT`, CI.19; PQ-28 |
| **R-23** | **The full process for a product no mapper fits yet.** The specification runs through every phase of the TomSpecs process, and the code generation has no mapper for a runtime, a protocol library or a command line; generators have to be built in Phase 4. | Phase 4 is reached and the generators needed are larger than the code they would write; a deliverable that has no unit yet (the paragraph under the register of `NFR > NFR-GEN`) is left out of Phase 4. | PQ-19, PQ-17; `NFR > NFR-GEN` |
| **R-24** | **Six client SDK languages nobody uses yet, in the first version.** They have to be built, kept in step with the protocol and published with the rest. | The protocol changes late; a language's convenience layer falls behind. | PQ-7; `CLI > CLI-PACK` |
| **R-25** | **One unanswered ask holds a whole run.** While an ask of a run is open, nothing further is sent from that run (D-61), and an unanswered ask moves along a chain of up to four persons with a set time each, or waits without a limit when it has no default (`RT > RT-ASKS`, CP.17 … CP.20). In strict mode the execution that asked may keep a repository leased meanwhile (PQ-39). | An ask without a default is addressed to a person who is away; a run with a long walk asks early in the walk. | PQ-24; `RT > RT-ASKS`, CP.21 |
| **R-26** | **One machine's network fails for hours unnoticed.** A machine whose VPN is down cannot reach the backend; its runtimes' runs are held after their current item, and nothing falls back on its own (`TAC > TAC-BACKENDS`, CA.32). What the user is shown meanwhile, and how the runtimes recover, matters in daily use. | The VPN of a machine goes down (on 2026-11-14 one machine's VPN was down for about 7.5 hours before anyone noticed). | S27 (al_the_bear `vpnhang1`; `repo_structure_new.md` § 2) |
| **R-27** | **Paths too long on Windows.** A working tree of an execution lengthens every path by the tree's prefix (`PAR > PAR-APPROACH`, CW.3), and Windows builds of this workspace are at the path-length limit already: the compiler is not long-path aware, and a Flutter build for Windows failed at 261 and 272 characters. | Worktree mode is switched on for a repository that is built on Windows. | S27 (al_the_bear `legws1_aktp-legiondary01-root-to-c-ws`); `NFR`, N-27 |
| **R-28** | {~~**Two hosts that wait for the whole product without a date.** Webwork's wave 1b2 (its AI tab and its messaging) starts after its wave-1b1 release and assumes the runtime finished;~>**Two hosts that wait for the whole product without a date.** Webwork is on hold until this specification exists as a document: no Webwork todo runs until tom_forge's last restructuring step and this quest's runtime specification are done (`LAND > LAND-WAIT`, E-15). Webwork's wave 1b2 (its AI run tabs, its messaging and the review exchange through tac) starts after its wave-1b1 release and assumes the runtime complete;~~} Tom Forge's quest application waits for the runtime process, its protocol and the Dart runtime client SDK, and the second part of its specification is written from this one. Neither quest has a date, and both assume the product complete, while it is built in one go (D-21, D-32, D-45). | {~~Webwork's wave-1b1 release is out and wave 1b2 cannot start; Tom Forge's quest application is ready for the runtime before the runtime is.~>The specification is not finished while Webwork's todos wait for it; Webwork's wave-1b1 release is out and wave 1b2 cannot start; Tom Forge's quest application is ready for the runtime before the runtime is.~~} | {~~S25 (`webwork_wave1_plan.md`); S26 (`qavs_wwworkbench-1`); `LAND > LAND-WAIT`, E-15, E-16~>S25 (`webwork_wave1_plan.md`, `03a_woneb1`); S26 (`qavs_wwworkbench-1`); `LAND > LAND-WAIT`, E-15, E-16~~} |
| {++**R-30**++} | {++**An agent transport that needs another language runtime on every host.** Mistral's coding agent (Vibe) needs Python and uv on every host where a profile on that transport is used (`RT > RT-PROVIDERS`, CS.12).++} | {++A profile on that transport is used on a machine, or by a member of the team, without Python or uv.++} | {++S30 (`xxmistral1`)++} |
| {++**R-31**++} | {++**Two engines on one `_ai` during the parallel period.** While the old and the new extension are both in use, the old extension's own engine, which is not a runtime, and the runtime read and write the same quest files on one machine (`RT > RT-HOLDS`, CR.112; `NFR`, N-10). A difference of format or behaviour between them misreads or damages a file, and a run's item, a timed request or a command addressed to the quest can be carried out twice.++} | {++The new extension works on a quest the old one also works on (whether it may is asked: PQ-36); the runtime writes a format version the old engine does not know (`RT > RT-VERSIONS`, CP.28; which version both use is asked: PQ-40).++} | {++S31 (D-73); S18 § 3++} |
| {++**R-32**++} | {++**The swap.** The new extension takes the old one's place and looks like its next major version: the users' settings and key bindings, and the documents, prompts and scripts that name the extension's commands, views and settings, must keep working; the old extension's last state must be archived before its folder or its identity is taken over.++} | {++The new extension is published in the old one's place (its identity, its place and its version are asked: PQ-60); the old extension is retired while a window still uses it.++} | {++S31 (D-73); the workspace guideline `retiring_and_archiving.md`++} |

### <!--[RISK-DEPS]--> 14.2 Dependencies

| Id | Depends on | For | State | Source |
| --- | --- | --- | --- | --- |
| **R-15** | The workspace layout restructuring (quest `al_the_bear`, and its part in the extension) | The runtime's locations and configuration layers; the repository record the claims use | The resolver and the layered configuration are built in the extension; the migration tool and the new fleet skills are written and tested; the cutover, which the user starts on the fleet's machines, and what follows it are open. The order is: the cutover, then the new format of the `_ai` files (`RT > RT-HOLDS`, CR.3), then the quest management, then the coordination repository and the tac server (R-20). The format and the quest management wait for the cutover | S12; S1 § 3.4, § 5.5; S22 § 5; S27 (`workspace_layout_plan.md`, `12a_wslayout-2`) |
| **R-16** | The extension's remaining features (quest `vscode_extension`) | {~~The engine being complete before it is extracted~>The engine being complete before it is copied for the new extension (D-73)~~} | open{++; when the copy is taken is asked (PQ-61)++}. Among them: the new format of the `_ai` files and the quest management of the standard (D-71), both after the cutover (R-15), none of it built (`LAND > LAND-BUILT`, E-14); {~~and the layering of the engine, which the extraction depends on: some of the engine's services still import handlers and tools, and nothing checks the rule~>and the layering of the engine, which the rewiring of the copy depends on: some of the engine's services still import handlers and tools, and nothing checks the rule~~} | S1 § 3.1; S18; S22 § 5, § 7; S23 (`01_aifmt-1` … `01_aifmt-5`, `02_aifmt-1`, `vscimpb176_aksm-services-not-importing-handlers-tools`, planned) |
| **R-17** | Tom Secrets Manager's TypeScript client being published | Resolving `tsm:` references in the runtime and the tac service | built, not yet published | S15; S1 § 3.6 |
| **R-18** | Releases of `tom_todo_model` | The todo fields the claims use (a todo's resources); every release moves the lock files (`pubspec.lock`) of its many consumers | {~~4.2.0 today (`LAND > LAND-BUILT`, E-2).~>6.0.0 today (`tom_ai/modules/tom_todo_model/pubspec.yaml`, 2026-11-25; `LAND > LAND-BUILT`, E-2); its consumers are being moved to it (<- S23: vscimpb180, planned).~~} How a todo's resources written without a prefix are read is asked (PQ-45), and whether Dart code besides the runtime keeps writing the todo files is asked (PQ-34) | S1 § 2.4, § 10.1; S23; S25 |
| **R-19** | Tom Forge's review component in Flutter | The review group of the UI components, shared by Webwork, the quest application and trc{++; beside it Webwork's messaging components (`tom_messaging_ui` in `tom_modules`, S29: C21)++} | planned in the quest `tom_forge`, and in the quest `webwork` as the extension's document browser page shown in a web view; where it is built, here as the Review group of `tom_ai_runtime_ui` or outside this product, is asked (PQ-43; `CON`, X-19) | S1 § 3.3, § 12.2; S14; S25 (`09_woneb5`); S26 (`05b_woneb1` … `05b_woneb5`) |
| **R-20** | The coordination repository and the tac server on the always-on machine (quest `al_the_bear`) | The GitHub backend, for one user's machines and for teams of several members (D-66); the tac server for the fleet and for a team; the check that the VPN works from an iPhone and an Android device (`CLI > CLI-TRC`, CK.12) | open; the tac server waits for this product. Both come after the cutover, the new format and the quest management (R-15). The fleet's todo for the tac server describes a server on the VPN only, run from a clone, and is rewritten against CA.27 … CA.30, N-28 and N-29 (accounts, the relay's public address behind a reverse proxy, installed from the binaries repository; `CON`, X-21); a reverse proxy with certificates exists on the always-on machine. How the server is deployed beyond that is for the Solution Blueprint. No todo exists for the check of the VPN on phones | S1 § 2.2, § 3.4; S27 (`14_loose_wslayout-6_akto-coordination-server-on-bigbeast`, planned; `tsmfleet3`, `tsmfleet9`, completed); `TAC > TAC-BACKENDS`, CA.28 |
| **R-21** | The `tomspecs` tool and the SOM packages | The specification tools the runtime carries | one binary, released (`LAND > LAND-BUILT`, E-21); new tools are being added in the quest `tom_specs` | S1 § 3.5 |
| **R-29** | The hosts' move to Flutter 3.50 and Dart 3.14, with the widget libraries `material_ui` and `cupertino_ui` | `tom_ai_runtime_ui`, whose components share widget types with their hosts (`NFR`, N-25) | planned in the quests `tom_forge` and `webwork`; a component library and every host that passes such types to it move together | S26 (`06a_flutterm1`); S25 (`05a_flutterm1`, `06b_flutterm1`) |

## <!--[DEL]--> 15 Delivery

{~~**What comes before the building.** (S2 § 4.1; S1 § 13.1; D-40)~>**What comes before the building.** (<- S2 § 4.1; S1 § 13.1) (-> D-40, D-73)~~}

1. The VS Code extension's features are finished. They include the new format of the `_ai` files and the quest management of the standard (D-71), which follow the cutover of step 2 (`RISK > RISK-DEPS`, R-15, R-16).
2. The workspace layout is restructured.
3. {~~This specification is written, and the product is built from it. The
   split of the extension starts here.~>This specification is written, and the product is built from it. The copy of the old extension, from which the new extension is built (D-73), is taken after steps 1 and 2; when exactly is asked (PQ-61).~~}

{~~**Two tracks, in parallel.** (S1 § 13.1, DQ-6; D-39)~>**Two tracks, in parallel.** (<- S1 § 13.1) (-> DQ-6, D-39)~~}

| Track | Contains | {~~Depends on the split of the extension~>Depends on the copy of the extension~~} |
| --- | --- | --- |
| **tac** | The tac server, participants and teams, messaging, documents, the tac client SDKs | no |
| **the runtime** | {~~The split, the protocol,~>The runtime and the new VS Code extension (D-73), the protocol,~~} the runtime client SDK, the UI components, the tac client inside the runtime with claims and the integration step, the web runtime service and the web runtime client SDK (D-65; what they are is asked: PQ-38, PQ-41) | yes |

{~~The two tracks touch different repositories. Webwork and Tom Forge wait for
their parts and progress on their own meanwhile (`LAND > LAND-WAIT`). Inside
and between the tracks no order is fixed (below).~>The two tracks touch different repositories. Webwork and Tom Forge wait for their parts (`LAND > LAND-WAIT`): Webwork is on hold until this specification exists (E-15), and Tom Forge progresses on its own meanwhile. Inside and between the tracks no order is fixed (below). What the coordination idea called the hand-off of the coordination work to this quest is the swap. (<- S30: ww_g_collab-999) (-> D-73)~~}

{~~**The stable extension during the split.** (S1 § 13.3, CQ-19; D-41)~>**The new VS Code extension.** (<- S31) (-> D-73)~~}

- {~~The extension is branched; the new line gets its own extension id and is
  worked on in a separate working tree.~>At the copy point the old extension is copied into the repository `tom_ai_build` (`tom_ai/ai_build`) as the new extension, with an extension id of its own; the copy is rewired to the runtime there, as the VS Code host, stage by stage (the todos below). When the copy point is, and whether the copy is taken from a tag and without history, is asked (PQ-61).~~}
- {~~The new extension refuses to start while the old one is active in the same
  window.~>The old extension is left as it is: no work of the new one is done in it. What it still gets meanwhile — fixes only, each repeated in the new one, is the recommendation — is asked (PQ-61).~~}
- {~~The new one is installed everywhere and activated only in the window used
  for testing, where the current one is deactivated.~>While both are installed, the new extension is used in a window or a profile where the old one is not active (`NFR`, N-33); whether it keeps the old one's contribution ids and refuses to start beside it in one window is asked (PQ-60).~~}
- {~~The old extension keeps being changed as needed; its changes are merged
  forward into the new line, or their work is repeated there.~>The new extension is finished when every feature of the old one works in it as before, through the runtime, and the team features work across machines and between the members of a team. What that is checked against is asked (PQ-57), and what "every feature as before" leaves out or adds (PQ-62).~~}
- {++Then the new extension takes the old one's place and looks like its next major version (the swap). The old extension is retired as the workspace guideline `retiring_and_archiving.md` says: its last committed state is copied into the archive repository `tom_archived` (category `code/`, a folder `<yymmdd>_<description>/` with a `RETIRED.md`, an entry in its `INDEX.md`) before it is removed from its repository; retiring is the product owner's decision, and both extensions may be maintained side by side for a while first. The new extension's identity, place and version after the swap, when the old one is retired, and which quest owns the new one then, are asked (PQ-60).++}

> **❓ PQ-60 (2026-11-25T22:30+01:00) — the new extension beside the old one, the swap, retiring the old one, and who owns the new one:** While both VS Code extensions are installed, what identity does the new one have; at the swap, where does it go, under which name and version; when is the old one retired; and which quest owns the new one after the swap?
>
> **Context:** D-73 (the product owner, 2026-11-25): "The old extension (`tom_ai/vscode/tom_vscode_extension`) is copied into the repository `tom_ai_build` (`tom_ai/ai_build`) as the new extension, with an extension id of its own, and the copy is rewired to the runtime as the VS Code host until every feature of the old extension works as before, only distributed and with a team. The old extension is left as it is meanwhile. When the new extension works and is stable, it takes the old one's place (the swap) and looks like its next major version (v2); the old extension is retired, and both may be maintained side by side for a while." The product owner's words (S31): "Once the new extension is working fine and stable I will retire the old extension and move the new one in its place, so it looks as if it is just a new (v2!) version of the extension. Maybe I will maintain both vs code extension for longer." D-73 replaces D-41, which said: "During the split the extension is branched, the new line has its own extension id and working tree, and it refuses to start beside the old one in the same window."
>
> What exists: VS Code identifies an extension by publisher and name; the old extension's `package.json` name is `tom-ai-extension`, display name `@Tom`, version `0.1.0`. Its contributions — 85 commands, 21 views in the activity bar and the panel, 16 settings, two custom editors (`tomAi.todoEditor`, `tomAi.trailViewer`) — all carry the prefix `tomAi.`; contribution ids are global inside one VS Code window, so two extensions with the same ids cannot both be active there. Users' settings, key bindings, and the workspace's documents, prompts and scripts name these ids. `NFR`, N-33: "The work on the new VS Code extension changes nothing of the old one; the new extension is installable at every step, in a window or a profile where the old one is not active." Retiring something in this workspace follows the guideline `retiring_and_archiving.md`: before it is removed from its repository, its last committed state is copied into the private archive repository `tom_archived` (category `code/`, a folder `<yymmdd>_<description>/` with a `RETIRED.md`, an entry in `INDEX.md`); retiring is the user's decision. The new extension is built by this quest (`ai_runtime`) in `tom_ai/ai_build`; the old one belongs to the quest `vscode_extension` (`LAND > LAND-WAIT`, E-22).
>
> **Why I ask:** The identity decides whether the swap is a plain re-publish or a rename of everything: with new contribution ids, every setting, key binding, document and prompt that names a `tomAi.` id would have to be migrated at the swap. The place decides where the new extension's history lives and what the tom_vscode repository holds afterwards. When the old one is retired decides how long two engines work on one `_ai` (R-31) and how long fixes have to be made twice (R-1). The owner decides which quest's todos carry the new extension's work after the swap. N-33, R-32 (the swap), `DEL` ("The new VS Code extension") and the unit register (`NFR > NFR-GEN`: the new extension has no unit and no folder name yet) all read differently by the answer.
>
> - **(a)** While both are installed: the new extension has its own name (for example `tom-ai-extension-v2`, display name "@Tom v2") but the **same** contribution ids and `tomAi.` settings as the old one; the two are never active in one window (separate VS Code profiles, or one disabled per workspace), and the new one refuses to start while the old one is active, as D-41 had it. At the swap the new extension's folder moves into `tom_ai/vscode` in place of `tom_vscode_extension` (the old folder archived first), and it is published under the old name `tom-ai-extension` and publisher as version 2.0.0; nothing is renamed, so settings, key bindings, documents and prompts stay valid. The old extension is retired — archived and removed — only when its maintenance ends, not at the swap, since both may be kept for a while. After the swap the quest `vscode_extension` owns the extension (the new one); until then `ai_runtime` owns the new one.
> - (b) As (a), but with new contribution ids (`tomAi2.…`) so both can be active in one window; at the swap every id is renamed back and users' settings and key bindings are migrated.
> - (c) As (a), but the new extension stays in `tom_ai/ai_build` after the swap, and `tom_ai/vscode` keeps only the scripting API and the bridge; `ai_runtime` keeps owning it.
> - (d) As (a), but the old extension is retired at the swap itself, and nothing is maintained side by side.
>
> *Recommendation:* (a) — the swap stays a re-publish under the old identity with nothing renamed, which is what "looks as if it is just a new (v2!) version" needs; it keeps the product owner's option to maintain both for a while; (b) doubles the swap's work and breaks every prompt that names a command until the rename; (c) leaves the extension in the build repository for good.
>
> *Assumption until answered:* the new extension has an extension id of its own and is used in a window or profile where the old one is not active (N-33); everything else about its identity, the swap and the retirement is open; `ai_runtime` builds it.
>
> **Answer:**

> **❓ PQ-61 (2026-11-25T22:30+01:00) — the copy point, what the old extension gets meanwhile, and when the Dart scripting API is split:** When is the old extension copied for the new one, from what, which of the extension's open todos still land in the old one before that, what does the old one get after it, and is the Dart scripting API split before the copy or on the copy?
>
> **Context:** D-73: the old VS Code extension "is copied into the repository `tom_ai_build` (`tom_ai/ai_build`) as the new extension … The old extension is left as it is meanwhile." D-40 (changed this round): "The copy of the old extension from which the new extension is built (D-73) is taken after the extension's features and the workspace layout are finished; when exactly it is taken is asked (PQ-61)." `DEL`, "What comes before the building": "1. The VS Code extension's features are finished. They include the new format of the `_ai` files and the quest management of the standard (D-71), which follow the cutover of step 2. 2. The workspace layout is restructured. 3. … The copy of the old extension … is taken after steps 1 and 2; when exactly is asked." D-40 goes back to RT-5 in the first runtime design (S19): extract the engine "after the open feature work and the format migration", so each line is moved once, in its final form.
>
> What the old extension's quest has open (S23, 2026-11-25): about 210 todos not started, among them the Copilot removal (`01_aifmt-1`, in progress), the move to format version 11 of the `_ai` files (`01_aifmt-5`, planned; the `_ai` files are at version 10 today), the quest management panel (`02_aifmt-1`, planned), and the extension's own collaboration plan (76 `caf_…` todos, S28; whether the runtime takes it over is PQ-63). The **cutover** is the workspace layout's switch of the fleet's machines to independent clones, started by the user (quest `al_the_bear`, `RISK > RISK-DEPS`, R-15); format 11 and quest management wait for it. The Dart scripting API `tom_vscode_scripting_api` (7.0.0) is today's client of the extension's script server; this quest's todos `ww_e_runtimeapi-1` … `6` split it into the Dart runtime client SDK and a VS Code part, and `CLI > CLI-PACK`, CL.13, says it "keeps only what a VS Code window serves, its VS Code namespace; it depends on the Dart runtime client SDK and re-exports it". RISK R-1 ("Two copies of one large code base"): "every fix the old one still gets has to be repeated in the new one, and a feature added to the old one after the copy point is a feature the new one lacks."
>
> **Why I ask:** The copy point decides how much work is done twice. Copied early, every later feature of the old extension has to be built again in the copy (R-1); copied late, the runtime work waits for the old extension's backlog. What the old extension gets after the copy decides whether it is really "left alone" while agents keep working with it every day. Whether the scripting API is split before or after decides where that mechanical change is made and whether it is made twice. `DEL` step 3, D-40, R-1, R-16 and the message owed to the quest `vscode_extension` (`DEL`) depend on it, and the quest `vscode_extension` needs to know which of its todos are still worth doing in the old extension.
>
> - **(a)** The copy is taken once the old extension's open work that changes the engine or the format is done — the Copilot removal (`01_aifmt-1`), format version 11 (`01_aifmt-5`) and the quest management panel (`02_aifmt-1`), all after the cutover — from a tag in the tom_vscode repository (name to choose), as a plain copy without history, the tag named in the new extension's README. The rest of the old extension's open todos is sorted into a list, one line per todo group, saying whether it lands in the old extension before the copy, is carried to the new extension, or is dropped; the product owner decides the list. After the copy the old extension gets fixes only, each repeated in the new one by a todo, and no features. The Dart scripting API is split on the copy, in the runtime track, so the old extension is not touched.
> - (b) The copy is taken now, from `main`, and every later feature of the old extension is repeated in the copy as it lands.
> - (c) As (a), but with the old extension's history (the folder extracted with `git filter-repo` or `git subtree` into `tom_ai/ai_build`).
> - (d) As (a), but the Dart scripting API is split in the old extension before the copy, so the copy starts from the split.
>
> *Recommendation:* (a) — copy once, from the final form (RT-5's reason); the engine and the format are stable when the rewiring starts; "leave the existing extension alone" holds while agents still run on it; history is only worth carrying if the new extension moves back into tom_vscode at the swap (PQ-60), where the old history is anyway.
>
> *Assumption until answered:* the copy is taken after the extension's features and the workspace layout are finished (D-40); nothing else about it is fixed; the old extension keeps getting what its quest plans.
>
> **Answer:**

{~~**The documents of the specification.** (PQ-19; D-36, D-37)~>**The documents of the specification.** (-> PQ-19, D-36, D-37)~~}

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

{~~**The order of building.** (PQ-8; D-45)~>**The order of building.** (-> PQ-8, D-45)~~}

- No order of the component groups or of the units is fixed in advance:
  the order is the one that reaches the finished, whole product fastest.
- The work is done by two runs in parallel (the two tracks above). A todo
  that waits for a todo of the other run is held, and its run with it (`RT > RT-QUEUE`, CR.23), {~~and goes on when that one
  is done; that the queue does this without a person is asked of the
  extension (quest `vscode_extension`, todo
  `vscimpb179_akss-blocked-item-resumes-by-itself`; `RT > RT-QUEUE`, CR.83, planned).~>and goes on by itself when that one is done (`RT > RT-QUEUE`, CR.83). (<- S23: vscimpb179)~~} {~~A run that waits for an ask sends nothing meanwhile either (D-61; `RISK > RISK-RISKS`, R-25).~>A run that waits for an ask sends nothing meanwhile either (-> D-61; `RISK > RISK-RISKS`, R-25).~~}
- Everything is delivered in one go {~~(D-21, D-32, D-45)~>(-> D-21, D-32, D-45)~~}. {~~What "finished" is checked against, and whether a first usable state is run end to end before everything is there, is asked (PQ-57).~>What "finished" is checked against, how the new extension is accepted against the old one, and whether a first usable state is run end to end before everything is there, is asked (PQ-57).~~}

> **❓ PQ-57 (2026-11-25T22:30+01:00) — delivery: what "finished" is checked against, the new extension's acceptance, and a first usable state:** Against what is the product checked before it counts as finished, how is the new VS Code extension accepted as doing "every feature as before", and are one or two thin paths run end to end as early as possible inside "one go", as the first usable state?
>
> **Context:** `DEL` ("Delivery", the last section of the Project Idea) says under "The order of building": "No order of the component groups or of the units is fixed in advance: the order is the one that reaches the finished, whole product fastest. The work is done by two runs in parallel (the two tracks above). … Everything is delivered in one go (-> D-21, D-32, D-45). What \"finished\" is checked against, how the new extension is accepted against the old one, and whether a first usable state is run end to end before everything is there, is asked." The decisions behind it: D-45: "No fixed order of building: the order that reaches the finished product fastest, with two runs working in parallel"; D-21: tac "is specified as one `tac/2.0` and built in one go"; D-32: Webwork's requirements "are covered by the product as a whole, built in one go".
>
> Two decisions of this round add to it. **D-74** (the feature baseline): the first version has the features of the VS Code extension, built and planned, of Webwork's plans for the runtime and tac — "team review and review document bundles first" — and of this quest's queued todos, "carried across machines, between the members of a team and over the internet". **D-73** (the new extension): the old extension (`tom_ai/vscode/tom_vscode_extension`, today's VS Code extension with its engine inside) is copied into `tom_ai/ai_build` as the **new extension**, which is rewired to the runtime "until every feature of the old extension works as before, only distributed and with a team"; when it is stable it takes the old one's place (**the swap**) and the old one is retired. So "finished" now also means: the new extension does what the old one does.
>
> Terms: a **topology** (`NFR > NFR-TOPO`, T1 … T8) is a way the parts are laid out on machines, from T1 "one machine, VS Code only" through T3 "one user, several machines on the VPN" and T4 "a team" to T8 "an application on a phone, a tablet or in a browser through the web runtime service". A **flow** (F1 … F13) is a key sequence: F1 a host attaches, F2 a prompt, F3 a todo walk (claims taken, the todo run, its follow-ups), F6 a team review (a review request with the documents goes to each member through tac, each member returns a copy, the merge runs), F8 two executions on one repository (each in its own working tree; the exclusive lease only for the integration step). The **screen inventory** (`CLI > CLI-SCREENS`, CU.10) lists every view, panel and editor of the extension and says, per screen, whether the new extension keeps it over the runtime, changes it or drops it. The runtime server's planned **conformance test** (this quest's todo `ww_d_workbench-9`) checks that "the files it writes match what the extension writes for the same operations". A **way in** to a provider (`RT > RT-PROVIDERS`, CS.12) is one of the three kinds of connection: the provider's own agent harness, an Anthropic-compatible endpoint, an OpenAI-compatible endpoint. Webwork planned an **end-to-end check** of its messaging (this quest's todo `tac_webwork-6`): "a server with TLS, two machines and a browser exchange messages and a `.webwork.zip`-sized blob in a thread attached to a review round". The risks: R-7 ("Everything in one go … an early part proves wrong only when a later part uses it"), R-3 (the team features have been used by nobody but the product owner), R-28 (Webwork and Tom Forge wait for the whole product without a date; Webwork's wave 1b2, its messaging and review exchange, assumes the runtime complete).
>
> **Why I ask:** The Solution Blueprint and its Quality and Acceptance Plan need an acceptance to check against, and the todos need an order once the specification is done. Without an agreed acceptance, "finished" is whatever the last todo says, and the swap has no criterion: nobody can say when the new extension "works fine and stable". Without a first usable state, a wrong assumption in the protocol, the leases, the integration step or the review exchange is found only when everything is built (R-7). The product owner names team review and review bundles as what Webwork must get (D-74); a team review on a path that runs early would let Webwork's wave 1b2 start before the last part of the product is done, without fixing an order of the component groups (D-45 stands either way).
>
> - (a) Nothing more is fixed in Phase 1: the Quality and Acceptance Plan of Phase 3 names the acceptance, including the new extension's; the order stays the fastest one (D-45); `DEL` names no intermediate state.
> - **(b)** The product counts as finished when (1) every topology of the first version (T1 … T5, T8, as far as the open questions leave them) and every flow F1 … F13 runs; (2) the new extension is accepted against the old one, having been installable at every step without changing the old one (`NFR`, N-33): it passes the old extension's test suites, copied with it and pointed at the runtime; the runtime passes the conformance test against files the old extension wrote for the same operations; the screen inventory and the tools are checked off in a live run per feature, with every dropped feature named there (PQ-62); the team features are checked on two machines of one user (T3) and with a second member (T4); and (3) one queue item with a tool call runs on a profile of each way in to a provider. Inside "one go", two thin paths run end to end as early as possible, used daily by the product owner as the first usable state: **path 1**, T1 with the runtime in the new extension, the local tac service, a host attaching (F1), a prompt (F2), a todo walk with one claim (F3), and one integration step on one repository in strict mode and in worktree mode (F8); **path 2**, a team review (F6) between two desktops through a tac server behind TLS — the runtime that serves no quest, the messaging and blob commands of the runtime client SDK, a team with an invitation, user messages, blobs pinned for the round, the review request and the return, a blob the size of a Webwork copy — after which Webwork is told that its wave 1b2 can start. Everything else is built around the two paths, in the order that is fastest. `DEL` and the Quality and Acceptance Plan say so.
> - (c) As (b) for the acceptance, with path 1 only: the review exchange comes with the whole product, and Webwork waits for "runtime complete".
> - (d) As (b) for the acceptance, without any thin path: the first use is when everything is there.
>
> *Recommendation:* (b) — it gives the swap a criterion that can be checked (the old extension as the reference), keeps D-45 (no fixed order of the groups), and puts the one feature the product owner names for Webwork on a path that is tested first.
>
> *Assumption until answered:* `DEL` names no intermediate state; the new extension is finished when "every feature of the old one works in it as before, through the runtime, and the team features work across machines and between the members of a team", without a named check; D-45, D-21 and D-32 stand as they are.
>
> **Answer:**

{++**What the first version contains** is the feature baseline: the features of the old extension, built and planned, of Webwork's plans for the runtime and tac (team review and review document bundles first), and of this quest's queued todos, carried across machines, between the members of a team and over the internet, except what a decision puts out of scope or later (`SCO > SCO-IN`, `SCO > SCO-OUT`, `SCO > SCO-LATER`). (-> D-74)++}

**What is delivered** is the code of the units (`NFR > NFR-GEN`) and the
documents of N-30. In the terms of the items:

- the runtime (G-1) and the tac service with its server and relay (G-2);
- three client SDKs (`CLI > CLI-PACK`, CL.12): the runtime client SDK and the tac client SDK in nine languages (G-3 … G-5; whether TypeScript and JavaScript are one: PQ-42), and the web runtime client SDK in Dart and in JavaScript / TypeScript (G-8, G-9; whether it is a client SDK of its own: PQ-41);
- the web runtime service (G-10; what it is: PQ-38);
- the Flutter components `tom_ai_runtime_ui` with their gallery application (G-6). They are new; three Flutter packages with agent and todo views exist over other backends (`LAND > LAND-BUILT`, E-20), and what becomes of them is asked (PQ-44). Whether the review component is one of them or is built outside this product is asked (PQ-43);
- the supervision application (G-7);
- what has no unit yet (the paragraph under the register of `NFR > NFR-GEN`): {~~the conformance suite, the VS Code extension as a host on the new line, the tac server's~>the conformance suite, the new VS Code extension (D-73; its folder and name: PQ-60), the tac server's~~} command line and administration interface, the migration between backends, the merge drivers of the `_ai` files, the successor of today's Dart client of the extension.

{~~Not delivered here: an application of its own for reviewing (`SCO > SCO-OUT`, O-10), and the VS Code extension's own views, among them the messaging views it gets once the runtime is built (O-1; D-67).~>Not delivered here: an application of its own for reviewing (`SCO > SCO-OUT`, O-10), and new designs of the VS Code extension's own views: the new extension carries the old one's views over unchanged (O-1); its messaging views and its views for the team come as far as PQ-62 decides (-> D-67, D-73).~~}

{~~**The todos.** The todos filed before the concept are input; the new set
replaces them, and the entries of other quests that wait on them follow
(S1 § 13.4, CQ-20; D-42).~>**The todos.** The todos filed before the concept are input; the new set replaces them, and the entries of other quests that wait on them follow. (<- S1 § 13.4) (-> CQ-20, D-42)~~}

{++What replaces which of this quest's todo groups (<- S30) (-> D-73):++}

- {++`ww_b_workbench-2` … `7` (the in-place extraction): replanned against the copy. First the runtime package `tom_ai/ai_build/tom_ai_runtime` (D-1) with its build, tests, licence and the guard against VS Code imports, and the copy of the old extension in `tom_ai/ai_build`, building, packaging and passing the old extension's suites unchanged, the old extension's folder and repository untouched. Then the modules free of VS Code, the host interface with its VS Code implementation in the new extension, the stores and managers, the engines and transports, the tools and the MCP server, each moved from the copy into the runtime; each step leaves the new extension installable in a test window or profile (`NFR`, N-33). If the new extension starts the runtime as a process (PQ-37), the host interface is reverse requests from the start and the runtime server comes before the engines.++}
- {++`ww_d_workbench-9` … `12`: the runtime server and its protocol, whose conformance test checks the files it writes against what the old extension writes for the same operations; the packaging, in which the new extension uses the runtime installation (`RT > RT-INSTALL`); the old extension's engine and the runtime on one `_ai` (R-31; PQ-36) in place of two hosts on one quest; the new extension's documents.++}
- {++New, with the specification's todos: the new extension's views for the team (PQ-62); the acceptance run against the screen inventory and the tools (`CLI > CLI-SCREENS`, CU.10; PQ-57); the swap (PQ-60); the retirement and archiving of the old extension (PQ-60); the script server and its ports in the new extension (PQ-62).++}
- {++`rca1` (the supervision application taken through the idea process, with a Telegram premise that D-6 defers): replaced by `CLI > CLI-TRC`.++}
- {++`ww_g_collab-999` (finishing the coordination and handing it to this quest): its hand-off is the swap.++}

{~~**What the other quests are told when the todos are filed** (D-42):~>**What the other quests are told when the todos are filed** (-> D-42):~~}

- {~~**`webwork`** waits for two messages: the map of WR-1 … WR-7 to the todos that cover them, when the todos are filed, and a second one when the runtime is complete.~>**`webwork`** is on hold until this specification exists as a document (<- S25: 03a_woneb1) (`LAND > LAND-WAIT`, E-15). It is told when the specification is finished; then it gets the map of WR-1 … WR-7 to the todos that cover them, when the todos are filed, with its `blocked_by` entries that name this quest's old todos (`12b_woneb1` … `12b_woneb3`, `tac_webwork-1` … `tac_webwork-6`, `ww_…`) moved to the new ones; and a last message when the runtime is complete.~~} {~~Its wave 1b2 starts after its wave-1b1 release, assumes the runtime finished and gives no date.~>Its wave 1b2 starts after its wave-1b1 release, assumes the runtime complete and gives no date.~~} Its specifications D13 (amended) and D40 are written against the runtime protocol specification and `tac/2.0`, so it needs those two documents before the code. The first message also says: the names "web runtime client SDK" and "web runtime service" for its builds on the web, the phone and the tablet (D-65); {~~that the per-run choice between reviewing each prompt's result and working silently is kept by the runtime, not on the device (`RT > RT-QUEUE`, CR.17);~>that the per-run choice between reviewing each prompt's result and working silently is kept by the runtime, not on the device as its `13_woneb2` has it (`RT > RT-QUEUE`, CR.17);~~} {~~that the team token is kept by the runtime, not in its settings container (`RT > RT-SECRETS`, CS.11; `CON`, X-16), which it needs before its D40 is written;~>that the team token is kept by the runtime, not in the device's settings container as its `13_woneb6` has it (`RT > RT-SECRETS`, CS.11; `CON`, X-16), which it needs before its D40 is written;~~} {~~and that a message's anchor is `msg:tac/<team>/<messageId>` (`TAC > TAC-CONV`, CM.12).~>and that a message's anchor is `msg:tac/<team>/<messageId>` (`TAC > TAC-CONV`, CM.12), where its `12a_woneb2` and `13_woneb9` still write `<server-group>`.~~} {~~(S25: `webwork_wave1_plan.md`, the notes on `12a_woneb1` … `14_woneb2`)~>(<- S25: `webwork_wave1_plan.md`, the notes on `12a_woneb1` … `14_woneb2`)~~}
- **`tom_forge`** waits for a message when the todos are filed, since the second part of its quest workbench specification is written from this one: the runtime client's package and place (`CLI > CLI-PACK`, CL.3); Telegram deferred (`SCO > SCO-LATER`, L-9), so its open decision on it falls away; the MCP server asks for a bearer token (`RT > RT-MCP`, CT.12) and host tools are not reachable through it (CT.11); its views embed the Flutter components (`CLI > CLI-UI`, CU.3), its todos for the quest application are the check of the screen inventory (CU.10), and what its view packages become follows PQ-44; {~~and its entries that wait on todos of this quest are moved to the new ones. (S14 part two; S26: `qavs_wwworkbench-1`)~>that the VS Code host is the new extension in `tom_ai/ai_build` (D-73), so a VS Code-bound tool it passes to a running VS Code window reaches the old or the new extension during the parallel period; and its entries that wait on todos of this quest are moved to the new ones. (<- S14 part two; S26: `qavs_wwworkbench-1`)~~}
- {++**`vscode_extension`** is told the copy point once PQ-61 is answered, and from then on what the old extension still gets; the open todos of its own that land before the copy are named in that answer. (-> D-73)++}
- {++**`al_the_bear`** is told, once PQ-53 and PQ-54 are answered, what of the personal files of a quest and of what remains for repository quests differs from its standard (S22), if anything does. (<- S30: ww_e_gitruntime-9) (-> D-71)++}

# G1-RISK-1 — reader's note

Inspected: `phase1_project_idea/project_idea.ai_runtime.md`, working tree, 2026-11-19.
Item: the risks known so far are listed, each with what would trigger it, and
the dependencies the Project Idea names; `pass`: every risk the Project Idea
mentions is listed with a trigger, or the Project Idea states that none is
known.

## The risks and their triggers

`RISK > RISK-RISKS` ("14.1 Risks"): a table of 14, columns Id, Risk, Trigger,
Source. Every row has a trigger.

| Id | Risk | Trigger |
| --- | --- | --- |
| R-1 | The split of a large extension while it keeps changing | A feature or fix lands in the extension after the split has begun; a stage of the split leaves the extension not working |
| R-2 | What is specified moves | A change in the extension to a view or an engine feature that a section describes |
| R-3 | Team features nobody else has used | The first second person joins a team; a reviewer without a repository takes part in a review |
| R-4 | Overlap with protocols others maintain | A revision of one of them; an agent or editor the product wants to reach speaks only one of them |
| R-5 | Vendors' interfaces in preview | A vendor changes or withdraws an interface a transport uses |
| R-6 | The full server before anybody uses it | The first team's use shows needs the full server did not foresee; Webwork's messaging waits for parts it does not need |
| R-7 | Everything in one go | An early part proves wrong only when a later part uses it |
| R-8 | Webwork's messaging on the web and the phone waits | Webwork's team needs messaging or review on a phone or in a browser before that server side exists |
| R-9 | Another writer in the repositories | Two runs touch the same repository; a build or an install runs from a tree another session left changed |
| R-10 | Leases held by agents | A run ends without releasing its claim; a long run holds a repository |
| R-11 | No gate before the main branch until the integration step exists | A run commits a change that breaks a package others build on |
| R-12 | Nine languages | A first user of such a client meets what the suite does not cover |
| R-13 | Two hosts and several runtime versions on one set of workspace files | A host is updated and migrates the files while another host with an older runtime is in use |
| R-14 | The product's value depends on others being able to use its parts | A user outside this workspace tries to use tac or a client without the rest |

## The dependencies

`RISK > RISK-DEPS` ("14.2 Dependencies"): a table of seven, columns Id,
Depends on, For, State, Source.

| Id | Depends on | State |
| --- | --- | --- |
| R-15 | The workspace layout restructuring (quest `al_the_bear`, and its part in the extension) | resolver and layered configuration built; migration, new fleet skills and cutover open |
| R-16 | The extension's remaining features (quest `vscode_extension`) | open |
| R-17 | Tom Secrets Manager's TypeScript client being published | built, not yet published |
| R-18 | Releases of `tom_todo_model` | 3.1.0 today, a further major release planned |
| R-19 | Tom Forge's review component in Flutter | planned in the quest `tom_forge` |
| R-20 | The coordination repository and the tac server on the always-on machine (quest `al_the_bear`) | open; the server waits for this product |
| R-21 | The `tomspecs` tool and the SOM packages | one binary, released; new tools being added |

By kind: other quests' work (R-15, R-16, R-19, R-20, R-21), a package release
(R-17, R-18). Vendors appear as a risk (R-5), not as a dependency.

## Risks mentioned elsewhere in the document

The rest of the document was read for statements of something that can go
wrong (search for risk, fail, lose, stop, wait, preview, stale, drift,
conflict and similar words outside section 14, then the passages read).

| Where | What it says | In the list |
| --- | --- | --- |
| `VIS > VIS-PROBLEM`; `PAR > PAR-PROBLEM` (the table of ten) | Today's problems: one branch in shared clones, no check before the main branch, other sessions' uncommitted work, machines drifting apart, shared files overwritten, requests to another quest stuck, a release rippling | They are the problem the product solves. As risks to the project while it is built: R-9 (another writer), R-11 (no gate until the integration step exists), R-18 (releases of `tom_todo_model`). |
| `RT > RT-VERSIONS`, question PQ-9, "Why I ask" | "With several hosts and a team, an automatic migration by whoever updates first stops everyone else's work without warning." | R-13. Its wording names hosts on "one set of workspace files"; the case of a colleague's machine that shares the files through git is the same risk and is not spelled out there. |
| `SCO > SCO-LATER`, L-1 | "sending work out sends source code out; a data policy comes first" | The reason a feature is deferred; no risk of the first version. Not in the list, and not required there. |
| `SCO > SCO-LATER`, L-6 | Pairing and end-to-end encryption "mandatory with the relay, once anything is reachable from outside the VPN" | A condition on a deferred feature; the relay itself is in scope (`SCO > SCO-IN`, `CA`). Borderline: the document does not state it as a risk. |
| `CLI > CLI-SCREENS`, before the inventory (marked `___check here___`) | The inventory's outcomes "are a first pass from the names of the extension's views and handlers, not yet from their code" | An open point of the content, near R-2 (what is specified moves). Not stated as a risk. |
| `NFR > NFR-TOPO` and `CON`, X-12; question PQ-16 | A runtime server needs a runtime without a host, while a runtime ends with its host; "not resolved" | A contradiction with its question (answered by the product owner, not yet taken in), not a risk. |
| `CON`, X-7; question PQ-19 | How the specification is made: "Unresolved" | A decision the project waited on; answered in PQ-19, not yet taken in. It is not in `RISK > RISK-DEPS`. |
| `RT > RT-SECRETS` | On a locked vault "the item waits and the user is asked to unlock" | Specified behaviour, not a risk. |
| `LAND > LAND-WAIT` | Three quests wait for this product | The reverse of a dependency; R-6 and R-8 carry the waiting of Webwork as triggers. |

No statement of a risk was found outside section 14 that the list does not
carry.

## Judgement

Every risk the Project Idea mentions is in `RISK > RISK-RISKS`, each with a
trigger; the dependencies are named in `RISK > RISK-DEPS`. **Pass.**

**Borderline, for the second round of the Project Idea** (none of it fails
the `pass` text, which is about risks and their triggers):

- R-13 could name the team case of PQ-9 (files shared through git) beside
  the two hosts on one machine.
- The decisions the project waited on (X-7 / PQ-19, X-12 / PQ-16) are
  answered but not taken in, and `RISK > RISK-DEPS` lists no decision.
- The answers to the 19 questions may bring risks of their own (PQ-19: the
  whole TomSpecs process with all its phases, for a product no mapper
  generates); they are not in the text yet, so they were not judged here.

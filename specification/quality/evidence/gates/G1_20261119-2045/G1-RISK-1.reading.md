# G1-RISK-1 — risks and dependencies (run 2, reader's note)

Document: `tom_ai/ai_build/specification/phase1_project_idea/project_idea.ai_runtime.md`
(ai_build `07412a22`). Read: `RISK` whole (lines 2300–2340); then the rest of
the document for a risk mentioned elsewhere that the list lacks: `VIS`,
`SCO`, `LAND > LAND-WAIT`, `RT > RT-INSTALL`, `RT > RT-VERSIONS`,
`CLI > CLI-SCREENS`, `CLI > CLI-TRC`, `TAC > TAC-BACKENDS`, `TAC > TAC-CRYPT`,
`PAR > PAR-PROBLEM`, `NFR` with `NFR-TOPO` and `NFR-GEN`, the decisions of
round 2 (D-44 … D-59), `CON` X-12 … X-15, `DEL`; and a search of the whole
text for the words a risk is stated with (risk, open point, not yet, until
then, cannot, lost, leak, too old, preview, depends on, waits for, nobody).

## The risks listed — `RISK > RISK-RISKS`

Seventeen, each with a trigger in the column "Trigger" and a source:

| Id | Risk (short) | Trigger (quoted, shortened) |
| --- | --- | --- |
| R-1 | The split of a large extension while it keeps changing | "A feature or fix lands in the extension after the split has begun; a stage of the split leaves the extension not working." |
| R-2 | What is specified moves | "A change in the extension to a view or an engine feature that a section here describes." |
| R-3 | Team features nobody else has used | "The first second person joins a team; a reviewer without a repository takes part in a review." |
| R-4 | Overlap with protocols others maintain | "A revision of one of them …; an agent or editor the product wants to reach speaks only one of them." |
| R-5 | Vendors' interfaces in preview | "A vendor changes or withdraws an interface a transport uses." |
| R-6 | The full server before anybody uses it | "The first team's use shows needs the full server did not foresee; Webwork's messaging waits for parts it does not need." |
| R-7 | Everything in one go | "An early part proves wrong only when a later part uses it." |
| R-8 | Webwork's messaging on the web and the phone waits | "Webwork's team needs messaging or review on a phone or in a browser before Webwork's server side exists." |
| R-9 | Another writer in the repositories | "Two runs touch the same repository; a build or an install runs from a tree another session left changed." |
| R-10 | Leases held by agents | "A run ends without releasing its claim; a long run holds a repository." |
| R-11 | No gate before the main branch until the integration step exists | "A run commits a change that breaks a package others build on." |
| R-12 | Nine languages | "A first user of such a client meets what the suite does not cover." |
| R-13 | Several hosts and runtime versions on one set of workspace files | "The user confirms a migration on one machine while another machine, or another member of the team, still runs an older runtime; an application is not yet available in a version that fits the installed runtime." |
| R-14 | The product's value depends on others being able to use its parts | "A user outside this workspace tries to use tac or a client without the rest." |
| R-22 | A server reachable from the internet in the first version | "The server's public address is opened; a device is lost; a team token or a device key leaks." |
| R-23 | The full process for a product no mapper fits yet | "Phase 4 is reached and the generators needed are larger than the code they would write." |
| R-24 | Six client languages nobody uses yet, in the first delivery | "The protocol changes late; a language's convenience layer falls behind." |

R-22 … R-24 are numbered after the dependencies; the document says so under
the first table, and `ABOUT > ABOUT-READ` names the ranges ("`R-1` to `R-14`
and `R-22` to `R-24` are risks, `R-15` to `R-21` dependencies").

## The dependencies listed — `RISK > RISK-DEPS`

Seven, each with what it is needed for, its state and a source: R-15 the
workspace layout restructuring (quest `al_the_bear`); R-16 the extension's
remaining features (quest `vscode_extension`); R-17 Tom Secrets Manager's
TypeScript client being published; R-18 releases of `tom_todo_model`; R-19
Tom Forge's review component in Flutter; R-20 the coordination repository and
the tac server on the always-on machine; R-21 the `tomspecs` tool and the SOM
packages.

## What round 2 brought in, and where the list has it

| Brought in by round 2 | Where the document states it | In the list |
| --- | --- | --- |
| A server reachable from the internet (phones and tablets, PQ-9, PQ-13) | CK.11, CI.18, CI.19, CA.30, N-19, N-21, T5, T8 | **R-22**, with CI.19 named as its source. CI.19's own point (HTTPS with the team token and a device key "does not protect against the server itself or whoever controls it") is the content of the risk; its triggers name the opening of the address, a lost device and a leaked token or key. |
| The full specification process for a product no generator fits (PQ-19, PQ-17) | `NFR > NFR-GEN` ("None of them writes a runtime, a protocol library or a command line today"), `DEL`, D-36, D-37, D-57 | **R-23** |
| Six more client languages in the first delivery (PQ-7) | CL.1, N-26, N-31, D-50 | **R-24**, and R-12 points to it |
| One shared runtime per machine; nothing updated unasked; a host too old or too new; migration and going back (PQ-6) | CR.42, CP.28, CP.31 … CP.34, N-9, D-49, X-13 | **R-13**: "On one machine the hosts share the installed runtime, and a host too old for it switches its features off or does not start. Across machines and people the files are shared through git …" Run 1's borderline (the team case of files shared through git not spelled out) is gone. |
| A server that hosts one runtime per client (PQ-16) | CR.46, T8, D-52 | part of R-22 ("The tac server and the server-side runtime are reached by phones from the internet") and of R-8 |
| No fixed order of building, two runs in parallel (PQ-8) | `DEL`, D-45 | R-7 and R-9 cover what it risks; see the dependency noted below |

Run 1's second borderline (the answers to PQ-16 and PQ-19 not yet in the
text) is gone: both are in the text (CR.46, D-52; `DEL`, D-37) and in the
list (R-22, R-23).

## Read for a risk the list lacks

Nothing the document states as a risk is missing from the list. Four places
are close to it; none is stated as a risk, and I note them so the Blueprint's
register can decide:

1. **A dependency named in `DEL` and not in `RISK > RISK-DEPS`.** "A todo that
   waits for a todo of the other run is held and goes on when that one is
   done; that the queue does this without a person is asked of the extension
   (quest `vscode_extension`, todo
   `vscimpb179_akss-blocked-item-resumes-by-itself`)." It can be read as one
   of "the extension's remaining features" (R-16), but R-16 is there "for the
   engine being complete before it is extracted", not for the two runs that
   build the product. The checklist's pass speaks of risks; the dependency is
   found and reported here.
2. **`CLI > CLI-SCREENS`, the screen inventory** carries a check mark: "The
   outcomes are a first pass from the names of the extension's views and
   handlers, not yet from their code; each is decided when the screen is
   described." It is stated as work still to do, not as a risk; R-2 covers
   descriptions going out of date, not a first pass being wrong.
3. **CK.12:** "Whether the VPN can be used from an iPhone and from an Android
   device is checked, so that the application can be tried on the VPN before
   the access from the internet is opened." An unknown the document plans to
   check; if the answer is no, the first trial of the phone application is
   from the internet, which is R-22's first trigger.
4. **CA.32 / N-12:** when the backend cannot be reached "the queues of the
   team's runtimes stop after their current todo". It is stated as the
   system's behaviour, with the emergency step a person confirms; with the
   server on one machine (R-20) it is also where a team's work stops. Not
   stated as a risk.

`SCO > SCO-LATER` L-1 gives a risk as the reason for deferring ("sending work
out sends source code out; a data policy comes first"); the feature is not in
the first version, so the risk is not one of this delivery.

## Judgement

The checklist's pass: "Every risk the Project Idea mentions is listed with a
trigger, or the Project Idea states that none is known." Every risk the
document mentions is in `RISK > RISK-RISKS` with a trigger, including the
four things round 2 brought in; the seven dependencies are listed with their
state. **pass.** Borderline in one point only: the dependency on the
extension's todo `vscimpb179` is named in `DEL` and not in the dependency
table (note 1); the pass text does not ask for it, and notes 2 to 4 are not
stated as risks.

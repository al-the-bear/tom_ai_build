# G1-SCOPE-1 — the scope (run 2, reader's note)

Document: `tom_ai/ai_build/specification/phase1_project_idea/project_idea.ai_runtime.md`
(ai_build `07412a22`). Read: `SCO` whole (lines 272–339), and for the
agreement the places listed in the last table.

## In scope — `SCO > SCO-IN`

A table of fourteen rows: the thirteen capability areas (`CR`, `CP`, `CT`,
`CA`, `CI`, `CM`, `CV`, `CW`, `CL`, `CU`, `CK`, `CQ`, `CS`) and the split of
the extension. Two of them, quoted:

- "Runtime core (`CR`) | The `_ai` formats and stores; processes and runs;
  the queue; sessions; model and agent transports; locations and
  configuration; machine-wide state; installation, lifetime and versions |
  S1 § 5"
- "Supervision (`CK`) | trc, on the desktop, the phone and the tablet |
  S1 § 12.4; PQ-9"

## Out of scope — `SCO > SCO-OUT`

Nine statements O-1 … O-9. Three of them, quoted:

- O-1: "The VS Code extension's own features: its views, panels and editors,
  and the tools that need VS Code. They stay in the extension, which becomes
  a host."
- O-5: "A port of the engine to another language. The runtime is TypeScript;
  other languages get clients."
- O-9 (new in round 2, PQ-4): "A short process for small changes. The engine
  carries any process; which processes exist is decided where they are
  written. It is proposed in the quest `tom_specs`."

## Deferred — `SCO > SCO-LATER`

Eleven features L-1 … L-11, each with what defers it and its source.

## What round 2 moved between "later" and the first version

| Thing | Before (S1 § 11.1) | Now | Where the document says it |
| --- | --- | --- | --- |
| The supervision application on the phone and the tablet | desktop first | first version | `SCO > SCO-IN`, row `CK`; `VIS > VIS-SYSTEM` (trc row); CK.10, CK.11; U-5; V-7; D-51 |
| The pairing of devices | later, with the relay (CQ-10) | first version | `SCO > SCO-IN`, row `CI` ("the pairing of devices"); CI.18 ("Pairing is part of the first version"); N-21; T5; D-51 |
| End-to-end encryption between a device and a runtime | later, mandatory with the relay | still later, **L-6**, as an open point for the security model | L-6; CI.19; N-21; X-14 |
| The server-side runtime | later (WQ-1, Webwork wave 3) | first version, for the supervision application | CR.46; T8; `VIS > VIS-SYSTEM` (last paragraph); D-51, D-52 |
| Webwork in a browser, on a phone and a tablet | later | still later, **L-8**: "Webwork's own server side" | L-8; R-8; `TAC > TAC-WEBWORK`; X-3 |
| A runtime server on an always-on machine, standalone runtimes | later (CQ-4) | still later, **L-5** | L-5; CR.44, CR.46; T6 "(later)"; D-15, D-52 |

## Does `SCO > SCO-LATER` agree with the rest?

Checked each `L-<n>` against every place that names it or its subject
(search for `later`, `deferred`, `first version`, `L-<n>` over the whole
document):

| Id | Agrees with | Result |
| --- | --- | --- |
| L-1 | T7 "(later)", F9 "(later)", D-35 | agrees |
| L-2 | CS.6 ("Which providers a runtime may use is decided by the team's configuration"), D-35 | agrees |
| L-3 | `RT > RT-ASKS` ("Asking a person outside the team is deferred"), D-20 | agrees |
| L-4 | `TAC > TAC-PEOPLE` ("The server sends no e-mail") | agrees |
| L-5 | CR.44, CR.46, T6, the paragraph under the topologies ("On the always-on machine only the tac server runs in the first version"), D-15, D-52, X-12 | agrees |
| L-6 | CI.18, CI.19, CA.30, N-21, X-14 | agrees: pairing now, end-to-end encryption an open point the security model decides |
| L-7 | named nowhere else; `TAC > TAC-DOCS` and `TAC > TAC-REVIEW` describe pinned blobs and the review exchange without such a repository | nothing contradicts it |
| L-8 | T8, R-8, `TAC > TAC-WEBWORK`, X-3, X-14 | agrees |
| L-9 | D-6, X-10 | agrees |
| L-10 | CI.17, N-20 | agrees |
| L-11 | named nowhere else; CA.27 has the full server with customers from the start, which is what L-11 builds on | nothing contradicts it |

The sentence under the topologies agrees with the table: "T1 to T5 and T8
belong to the first version; T6 and T7 are later."

Two wordings to note; neither contradicts the scope:

- The section opens "Decided as not part of the first version (S1 § 11.1)",
  while L-6 and L-8 now differ from S1 § 11.1 in the part round 2 moved. Each
  of the two rows says so itself and names PQ-9.
- U-9 says Tom Forge "later hosts trc as an application", while
  `VIS > VIS-SYSTEM` and CK.7 have trc as a Webforge application from the
  start that also runs standalone. "Later" there reads as "once trc exists".

## Judgement

The checklist's pass: "At least one in-scope and one out-of-scope statement."
There are fourteen in-scope rows and nine out-of-scope statements, and the
deferred list agrees with the rest of the document after round 2. **pass.**

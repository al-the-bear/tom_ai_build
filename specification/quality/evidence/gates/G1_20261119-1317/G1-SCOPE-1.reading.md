# G1-SCOPE-1 — reader's note

Inspected: `phase1_project_idea/project_idea.ai_runtime.md`, working tree, 2026-11-19.
Item: in-scope and out-of-scope boundaries are sketched; `pass`: at least one
in-scope and one out-of-scope statement.

## In scope

`SCO > SCO-IN` ("5.1 In scope"): a table of 14 areas, each with what is in
scope and its sources. The areas: Runtime core (`CR`), Protocol and hosts
(`CP`), Tools and MCP (`CT`), Coordination between runtimes (`CA`), People,
teams and identity (`CI`), Messaging (`CM`), Documents and review (`CV`),
Parallel work and integration (`CW`), Client packages (`CL`), UI components
(`CU`), Supervision (`CK`), Repository quests and personal files (`CQ`),
Secrets, configuration and providers (`CS`), The split.

One of them, as an example:

> | Runtime core (`CR`) | The `_ai` formats and stores; processes and runs; the queue; sessions; model and agent transports; locations and configuration; machine-wide state; installation, lifetime and versions | S1 § 5 |

## Out of scope

`SCO > SCO-OUT` ("5.2 Out of scope"): eight statements, O-1 … O-8.

| Id | Out of scope |
| --- | --- |
| O-1 | The VS Code extension's own features: its views, panels and editors, and the tools that need VS Code |
| O-2 | The applications that host a runtime (Webforge, Webwork) and their own tools and screens, apart from what they need from this product |
| O-3 | User interface components for platforms other than Flutter |
| O-4 | Transports implemented by a host |
| O-5 | A port of the engine to another language |
| O-6 | Converging machines: reconciles of the fleet stay a step the user starts |
| O-7 | A file server |
| O-8 | The earlier agent_container and project_coordination work as input |

## A third boundary

`SCO > SCO-LATER` ("5.3 Deferred to later"): eleven features decided as not
part of the first version, L-1 … L-11, each with the decision that defers it
(for example L-1, todos to the cloud; L-8, a server-side runtime for web,
phone and tablet clients).

## Judgement

14 in-scope areas and 8 out-of-scope statements, plus 11 deferred features.
**Pass.**

# G1-PROB-1 — the problem statement (run 2, reader's note)

Document: `tom_ai/ai_build/specification/phase1_project_idea/project_idea.ai_runtime.md`
(ai_build `07412a22`). Read: `VIS > VIS-PROBLEM` (lines 93–122), with
`VIS > VIS-SYSTEM` and `USR > USR-GROUPS` for "for whom".

## What the system solves

`VIS > VIS-PROBLEM`, first paragraph, in the document's own words:

> Work with AI agents is organised today around the coding session: one task,
> one agent run, one branch or pull request to review. A larger undertaking
> does not fit that unit. It runs for weeks or months, spans many repositories
> and several machines, follows a process with phases and gates, and depends on
> people who answer questions, review documents and decide (S9; S1 § 15.2,
> § 15.3).

Second paragraph: the workspace has an engine for such work, and "It lives
inside one host, the VS Code extension, and is entangled with it (S1 § 2.1).
Four things follow:" — the four problems, each with an id (run 1 found them
without ids):

| Id | Statement (quoted) |
| --- | --- |
| P-1 | "Other applications cannot use it. Webforge (Tom Forge) and Webwork need the same engine and would have to build it again (S4, notes a, k)." |
| P-2 | "Agents and people work side by side without anything keeping them apart. Everything is committed on one branch in shared clones; "one writer per repository" is an agreement; machines drift apart unnoticed; shared files are overwritten by another window (S1 § 10.1)." |
| P-3 | "People outside the editor cannot take part. A reviewer or a decider without access to a repository gets documents by hand, and a question from an agent waits in the window that asked it (S1 § 3.5, § 6.6)." |
| P-4 | "Nobody sees the whole. What waits, where, on which machine, is spread over windows (S8)." |

## For whom

Inside the statement: the other applications (P-1: Webforge, Webwork), the
agents and people who work side by side (P-2), "a reviewer or a decider
without access to a repository" (P-3), whoever has to see the whole (P-4).
`USR > USR-GROUPS` names them as user groups U-1 … U-7; `VIS > VIS-GIVES`
V-1 … V-8 answers the four problems one by one.

## Why now

`VIS > VIS-PROBLEM`, last paragraph:

> Why now: the engine's features are complete enough to be extracted; three
> hosts and three other quests wait for it (`LAND > LAND-WAIT`); and the
> coordination service's first part exists and is used by nothing yet
> (S1 § 2.1, § 2.3).

`LAND > LAND-WAIT` exists and lists the waiting quests (E-15 … E-18: webwork,
tom_forge, al_the_bear, tom_specs).

## Against run 1

The text of the section is the one run 1 read, with the ids P-1 … P-4 added.
Round 2 changed nothing in what the problem is. One number to note, not a
finding for this item: "three hosts and three other quests wait" stands beside
four rows in `LAND > LAND-WAIT` (E-15 … E-18) and four hosts of the first
version in `VIS > VIS-SYSTEM` (the supervision application is the fourth, and
it is part of the product, not waiting for it).

## Judgement

The checklist's pass: "The problem is stated in the Project Idea's own
words." It is: what is solved, for whom and why now are each stated in
`VIS > VIS-PROBLEM`, in the document's words, with sources. **pass.**

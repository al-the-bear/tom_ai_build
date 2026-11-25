# Answers — Phase 1, question round 5

**Round:** 5 · **Extracted:** 2026-11-25 · **Document:** `../project_idea.ai_runtime.md` as round 4 and the product owner's review left it.

The change marks of round 4 (218 substitutions, 910 additions, 27 deletions) carried no comment and no rejection; all were accepted before this round (the document before: `project_idea.before_marks.md`). No reviewer comment block is in the document.

## Questions answered

None. The 26 questions round 4 asked (PQ-34 … PQ-59) carry no answer. They stay in the document; this round reworks them (see the product owner's instruction below), and each stays, is rewritten, merged or replaced as `p1s1r5-1`'s triage rules.

| Id | Section | Topic |
| --- | --- | --- |
| PQ-34 | `RT > RT-HOLDS` | who writes and commits `_ai` files besides the runtime |
| PQ-35 | `RT > RT-HOLDS` | features of the extension: the runtime's or the VS Code host's own |
| PQ-36 | `RT > RT-HOLDS` | two hosts on one quest |
| PQ-37 | `RT > RT-INSTALL` | Node for a host that is not VS Code, and the Agent-SDK-only mode |
| PQ-38 | `RT > RT-INSTALL` | what the web runtime service is |
| PQ-39 | `RT > RT-ASKS` | leases and chat sends while a run waits for an ask |
| PQ-40 | `RT > RT-VERSIONS` | when a migration of the workspace files runs |
| PQ-41 | `CLI > CLI-PACK` | what the web runtime client SDK is beside the runtime client SDK |
| PQ-42 | `CLI > CLI-PACK` | TypeScript and JavaScript: one client SDK or two |
| PQ-43 | `CLI > CLI-UI` | where the review component is built, and in which form |
| PQ-44 | `CLI > CLI-UI` | the Flutter view packages that exist beside the new UI components |
| PQ-45 | `TAC > TAC-COORD` | how resources and the other addressed things are written |
| PQ-46 | `TAC > TAC-COORD` | the lease rules: integration lease, fencing at the push |
| PQ-47 | `TAC > TAC-BACKENDS` | a team on the GitHub backend: what it has, and who is a member and a team owner |
| PQ-48 | `TAC > TAC-BACKENDS` | what "coordination off" switches off, and what the local tac service is |
| PQ-49 | `TAC > TAC-CRYPT` | phones and tablets: which program faces the internet, pairing, and how a person away is reached |
| PQ-50 | `TAC > TAC-PEOPLE` | one model for remote control and for tac's credentials |
| PQ-51 | `TAC > TAC-PEOPLE` | a runtime that serves no quest, and its team |
| PQ-52 | `TAC > TAC-CONV` | where the cache and the outbox of a user's messaging live |
| PQ-53 | `PAR > PAR-QUESTS` | where a person's own files of a quest lie: in the quest, per host, or in a personal repository |
| PQ-54 | `PAR > PAR-QUESTS` | what remains of member branches, the internal repository, the secret scan and member access for repository quests |
| PQ-55 | `PAR > PAR-QUESTS` | who carries the quest operations, a quest inside a project's repository, and quests worked on from a server |
| PQ-56 | `NFR` | numbers the Solution Blueprint needs and no source gives |
| PQ-57 | `DEL` | delivery: what "finished" is checked against, and a first usable state |
| PQ-58 | `GLO` | words the document uses in several senses |
| PQ-59 | `ABOUT > ABOUT-READ` | the structure of the Project Idea in the next round |

## The product owner's instructions for this round (verbatim)

> a) Please go through the vscode_extension and webwork quests to see their "current state of todos, done and planned". This should be the basis of what to cover in a v1 version of the AI runtime, featurewise, but of course in the AI runtime we have to do it across machines and potentially over the internet. We must provide Webwork with what it needs for the team review features and sending review document bundle within the team/users on the TAC. The currently queued todos and documents in the quest should now cover the base feature set we need. Rework the project idea documents and the questions for it to cover all of this.
>
> b) I want to create a second extension for this and leave the existing extension alone until we have really finished the new extension. For this we'll make a copy of the extension in the ai_build repo and work on this until it works with the AI runtime and all features working as before (only distributed and with a team). Once the new extension is working fine and stable I will retire the old extension and move the new one in its place, so it looks as if it is just a new (v2!) version of the extension. Maybe I will maintain both vs code extension for longer.

Both are decisions of the product owner: (a) fixes the feature baseline of the first version, (b) replaces the in-place split of the extension by a second extension. They are written into the Project Idea as decisions; what they leave open is asked.

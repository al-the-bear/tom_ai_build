# G1-USER-1 — reader's note

Inspected: `phase1_project_idea/project_idea.ai_runtime.md`, working tree, 2026-11-19.
Item: the primary user groups and the owner are identified; `pass`: at least
one primary user group and the owner are named.

## User groups found

`USR > USR-GROUPS` ("3.0 User groups"), a table of seven, each with what the
group uses the system for and its sources:

| Id | Who |
| --- | --- |
| U-1 | A developer working with agents in an editor |
| U-2 | A team member who reviews or decides, often without access to any repository |
| U-3 | A team owner |
| U-4 | A quest owner |
| U-5 | A supervisor of a group of runtimes |
| U-6 | An application developer who embeds the runtime or uses it from another language |
| U-7 | An administrator of a tac server |

`USR > USR-HOSTS` ("3.0.1 Hosts and waiting quests") adds six stakeholders,
U-8 … U-13: the VS Code extension, Webforge / Tom Forge, Webwork, the fleet,
TomSpecs, Tom Secrets Manager.

The document does not mark any group as "primary". U-1 … U-7 are the people
who use the system; U-1 stands first and is the user the engine serves today.

## The owner

`USR > USR-TEAM` ("3.1 Owner and review team"). The section's own text says:

> The Project Idea does not record the product owner and the review team yet.
> This section is filled from the answer to the question on the owner and the
> review team in the round's question list

Below it, in the same section, stands question PQ-1 ("Product owner and
review team") with the product owner's answer:

> **Answer (2026-11-19T10:45+01:00):** (a), owner and reviewer am I, alexis

Option (a) of PQ-1 reads: "**The owner alone.** One member: you, as product
owner and only reviewer. Please give your member id, display name and role.
Every document type uses this team."

What the document holds, then:

- the owner is named, as `alexis`, in the answer to PQ-1 — inside
  `USR > USR-TEAM`, but not in the section's text;
- the section's text still says that the owner is not recorded;
- the answer gives one name. It does not say separately which of member id,
  display name and role it is; "alexis" fits a member id (lowercase letters),
  and the role follows from option (a): product owner and only reviewer.

## Judgement

At least one primary user group is named (seven are). The owner is named in
the document, by the product owner's own answer. Judged by the `pass` text
("at least one primary user group and the owner are named"): **pass**.

**Borderline.** The naming exists only as an answer under a question whose
section text says the opposite. The section text of `USR > USR-TEAM` still
has to take the answer in: the owner `alexis` as product owner and only
reviewer, with member id, display name and role, and "every document type
uses this team" — and the sentence "does not record the product owner and the
review team yet" has to go. A stricter reading that counts only section text
would fail the item on the owner.

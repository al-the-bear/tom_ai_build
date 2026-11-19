# G1-USER-1 — users, stakeholders and the owner (run 2, reader's note)

Document: `tom_ai/ai_build/specification/phase1_project_idea/project_idea.ai_runtime.md`
(ai_build `07412a22`). Read: `USR` whole (lines 170–203), `ABOUT` (line 10),
`DEC` D-44.

## The user groups — `USR > USR-GROUPS`

| Id | Who (quoted) |
| --- | --- |
| U-1 | "A developer working with agents in an editor." |
| U-2 | "A team member who reviews or decides, often without access to any repository (a business reviewer)." |
| U-3 | "A team owner." |
| U-4 | "A quest owner. Every quest has one." |
| U-5 | "A supervisor of a group of runtimes." |
| U-6 | "An application developer who embeds the runtime in a Flutter application, or uses it from another language." |
| U-7 | "An administrator of a tac server." |

Each row says what the group uses the system for and names its source. Round 2
changed three of them: U-3 ("Create a team on a server they have joined",
PQ-20), U-5 ("at the desk, and from a phone or a tablet while away", PQ-9),
U-7 ("set whether it is open or strict", PQ-13).

## The stakeholders — `USR > USR-HOSTS`

U-8 the VS Code extension, U-9 Webforge / Tom Forge, U-10 Webwork, U-11 the
fleet, U-12 TomSpecs, U-13 Tom Secrets Manager: each with its interest and
source.

## The owner — `USR > USR-TEAM`

Run 1 found the owner only in an answer inside this section, while the
section's text said the owner was not recorded. The section now reads:

> The product owner is the only reviewer. Every document type uses this team;
> no document type has a team of its own. No e-mail address is stored.
> (PQ-1, PQ-22)
>
> | Member id | Display name | Role | Owner |
> | --- | --- | --- | --- |
> | `alexis` | Alexis | Product owner | yes |

Member id (`alexis`), display name (Alexis) and role (Product owner) are in
the section's own text; no question block is left in it. The same is stated
in two more places, and they agree:

- `ABOUT`, row "Product owner and review team": "alexis, product owner and
  only reviewer (`USR > USR-TEAM`)";
- `DEC`, D-44 (PQ-1, PQ-22): "The product owner (member id `alexis`, display
  name Alexis) is the only reviewer of the specification; no document type
  has a team of its own."

The answers are in `phase1_project_idea/01_02_Questions Round/answers.md`
(PQ-1 and PQ-22 are among its 23).

## Judgement

The checklist's pass: "At least one primary user group and the owner are
named." Seven user groups are named, and the owner is named in the section's
text. Run 1's borderline is gone. **pass.**

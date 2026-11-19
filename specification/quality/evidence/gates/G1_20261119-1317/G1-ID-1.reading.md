# G1-ID-1 — statements without an id (reader's note)

Inspected: `tom_ai/ai_build/specification/phase1_project_idea/project_idea.ai_runtime.md`
(2,473 lines), 2026-11-19. The counts are in `G1-ID-1.counts.md`, the
per-section tally of list items and table rows with and without an id in
`G1-ID-1.sections.txt`.

## What carries ids

Every capability statement, non-functional expectation, vision statement, user
group, decision, contradiction, risk and dependency, out-of-scope item,
deferred feature, fact about today, topology and flow stands with a bold id at
the start of its list item or table row: 449 items, numbered without a gap and
without a duplicate in every kind. In the capability sections (`RT`, `CLI`,
`TAC`, `PAR`) and in `NFR`, `DEC`, `CON`, `RISK` the tally finds no list item
and no table row without an id, apart from the tables named below.

## Statements the Blueprint will need to cite that carry no id

| # | Where | What stands there without an id | Why the Blueprint needs it |
| --- | --- | --- | --- |
| 1 | `NFR > NFR-GEN` (table "Unit / Kind / Builds / Technology / Source", 7 rows) | The generation units: `tom_ai_runtime`, `tom_tac_service`, `tom_tac_client`, `tom_ai_runtime_client`, "the clients of the eight other languages", `tom_ai_runtime_ui`, "the supervision application (trc)" | The Blueprint's generation-unit register is built from exactly these rows. Five are keyed by a package name; two ("the clients of the eight other languages", "the supervision application (trc)") have only a description. |
| 2 | `CLI > CLI-SCREENS` (table "Extension screen / Outcome (first pass) / Component group", 29 rows) | The inventory of the extension's screens with what each becomes, e.g. "The chat panel — reused — conversation", "Status page — split (providers, profiles, coordination, diagnostics each on their own)", and the three new rows (messaging, the coordination page, team administration) | CU.10 says the inventory exists and CU.11 defines the outcomes, but a single screen's outcome can only be cited as "the row named …". The experience design part of the Blueprint cites screens one by one. The table is marked `___check here___` as a first pass. |
| 3 | `VIS > VIS-PROBLEM` (4 list items) | The four consequences of the engine living in one host: "Other applications cannot use it.", "Agents and people work side by side without anything keeping them apart.", "People outside the editor cannot take part.", "Nobody sees the whole." | The problem statement the Blueprint's introduction and scope trace to. `V-1` … `V-8` (what the system gives) have ids; the problems they answer do not. |
| 4 | `PAR > PAR-PROBLEM` (table "Problem / What it means", 10 rows) | The ten problems of parallel work today, e.g. "Nothing stands before the main branch", "A run cannot be discarded", "Machines drift apart unnoticed" | The requirements derived from CW.1 … CW.24 are justified by these; the Blueprint's current-landscape part cites them. |
| 5 | `SCO > SCO-IN` (last row, "The split") | "Extracting the engine from the VS Code extension, with a stable extension beside it while that runs" — the only in-scope row that is not keyed by a capability area code | Scope rows are otherwise cited by their area (`CR` … `CS`). The content is covered by D-40, D-41, N-33 and R-1, so it can be cited through those. |
| 6 | `USR > USR-TEAM` | The product owner and review team: stated only in the answer to PQ-1 ("(a), owner and reviewer am I, alexis") | The Blueprint records the review team. Citable as PQ-1 for now. |

Not counted as missing:

- **`GLO`** (37 terms): a glossary term is cited by the term.
- **`ABOUT > ABOUT-READ`**, **`VIS > VIS-SYSTEM`** (the component table), **`TAC > TAC-JOBS`** (the two-jobs table), **`CLI > CLI-SCREENS`** outcome table inside CU.11, **`NFR > NFR-GEN`** tooling table: explanatory; the statements they support have ids.
- **`DEL`** (11 list items, 3 table rows): each paragraph names the decision it restates (D-36, D-39, D-40, D-41, D-42, N-30, X-7).
- **The 19 answers to PQ-1 … PQ-19**: answered on 2026-11-19 and not yet taken into the text. Each can be cited by its question id; once taken in, what they decide becomes `C`, `N` or `D` items.

## Reading

The pass criterion is "Every item the Blueprint will need to cite has an id."
All capabilities and expectations carry ids. What is missing are four tables
and lists of other kinds (rows 1 to 4: 50 rows and list items). Row 1 is the
clearest: the Blueprint's unit register is a one-to-one take-over. Rows 5 and
6 are citable through other ids. The reading is borderline in that none of the
missing items is a capability or an expectation; it fails on the wording
"every item".

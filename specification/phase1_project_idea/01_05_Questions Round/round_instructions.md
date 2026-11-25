# Round instructions — Phase 1, question round 5

For every todo `p1s1r5-*`. Document: `../project_idea.ai_runtime.md` (the Project Idea, plain
Markdown). Read these instructions completely before changing anything.

## What the round is for

The product owner's two instructions are in `answers.md`, verbatim. In short:

- **(a) The feature baseline of the first version.** What the VS Code extension does today and
  has planned (quest `vscode_extension`), what Webwork has done and planned (quest `webwork`), and
  what this quest's own queued todos and documents stand for, together are the feature set of the
  first version of the runtime — carried across machines, between the members of a team and over
  the internet. Webwork gets what it needs for team review and for sending review document
  bundles within a team and between users through tac. The Project Idea and its questions are
  reworked to cover all of it.
- **(b) A second extension.** The existing extension is left alone. A copy of it is made in the
  `ai_build` repository and rewired to the runtime until every feature works as before, only
  distributed and with a team. When it is stable it replaces the old extension and looks like its
  next major version (v2); both may be maintained for a while. This replaces the in-place split
  of the extension (moving the engine out of the running extension stage by stage).

None of the 26 questions of round 4 (PQ-34 … PQ-59) is answered. They are reworked: each is kept,
rewritten (so that it covers what (a) and (b) add, and stands on its own), merged into another,
or settled — the last only where (a) or (b) decides it.

## What you work from

- `answers.md` — the instructions verbatim, and the list of open questions.
- `triage.md` — written by `p1s1r5-1`: the cross-cutting rulings, and per part the work list:
  every finding and every open question with the ruling **apply** (what to write, the source),
  **ask** (a new or rewritten question, and which part writes it), **settle** (an open question
  that (a) or (b) decides, with the decision) or **drop** (with the reason). **Your part's rows
  are your work list.** Read the finding itself in its file before acting on a row.
- The three inventories of this round: `inventory_vscode_extension.md` (the extension's
  features, built and planned, mapped to the Project Idea), `inventory_webwork.md` (Webwork's
  needs, team review and review bundles first), `inventory_ai_runtime_quest.md` (this quest's
  todos and documents, and what the second extension changes). The previous round's input files
  in `../01_04_Questions Round/` stay valid where this round's inventories do not say otherwise.
- The binding terminology: `_ai/quests/ai_runtime/ai_runtime_terminology.md` § 2 and the
  glossary `GLO`. New text uses those terms.

## What decides, in this order

1. **The product owner's instructions (a) and (b)** and his earlier answers (the decisions
   D-<n> in `DEC`). A feature of the baseline is in the first version unless the product owner
   decided otherwise (`SCO > SCO-OUT`, `SCO > SCO-LATER`); where carrying a feature across
   machines or to a team needs a choice, ask.
2. **A decided source**: al_the_bear's `ai_format_migration.md` (S22) for the `_ai` state and
   quests, as before.
3. **What is built** (in the extension, in Webwork): written as what the runtime does, citing the
   source (doc section, todo id). **What is planned** in a todo: written as planned, with the todo
   id. A feature the baseline has and the Project Idea lacks gets an item; one the Project Idea
   has and no source backs is kept only if a decision backs it, otherwise asked.
4. **Consistency**: an inconsistency is resolved toward the item a decision backs; otherwise ask.
5. **Improvement ideas** are never written as decided: a question with the idea as the
   recommended option, or dropped with the reason in `changes.md`.

## Rules for the text

- **Ids.** Existing ids keep their meaning and are never reused. A new item gets the next free
  number of its area (grep the whole document just before you write; another todo may have added
  one). An item that no longer holds is marked removed with one sentence saying what replaces it.
  New sources: only `p1s1r5-2` adds them to `SRC`, from the triage's list; the others cite them.
- **Current state only.** No "no longer", "was changed", "earlier" outside `DEC` and `CON`.
- **Obligations.** No requirement is approved yet (G1 has not passed); list every change that
  alters what an item demands in `changes.md` under "Obligations changed".
- **Marks.** Every change is an inline review mark: `{~~old~>new~~}`, `{++added++}`,
  `{--removed--}`; a remark as `{>>…<<}` only where the reason is not obvious. No blank line
  inside a mark: mark each paragraph or list item on its own. Do not rewrap what you did not
  change.
- **Secondary prose** (process description § Secondary prose; DocSpecs § Reading Notation): in
  what you write and in every section you touch, a source note is a citation shape at the end of
  the clause — `(-> D-61, CR.17)` for ids that back a statement, `(<- S22 § 3)` for "taken from",
  `(<~ S23: vscimpb179)` for "extrapolated from" — and a longer provenance, editorial or aside
  text is a div (`::: {.provenance}` … `:::`, `::: {.editorial}`, `::: {.aside}`) or a span
  (`[…]{.aside}`). The test: would the specification state the same requirements without the
  text? If yes, mark it; if dropping it would change what the system must do, it stays unmarked;
  when in doubt, unmarked. An id the sentence is about, a reference to a section (a link, a
  section-id chain) and a table column of ids are content, never a citation. Existing source
  notes in a section you touch, such as `(S1 § 5.5, CQ-3, DQ-5)`, are rewritten into the shapes
  as marked changes.
- **References** on one line: never break a section-id chain (`A > B > C`) across lines; no line
  may start with `>` except in a question block.
- **Question blocks stay where they are** until `p1s1r5-11` puts the final set in.
- **Signing.** A remark that needs the product owner's eye starts with `___check here___` and
  says why. Sparingly.
- **No commit.** The closing item commits. Scratch files only in `ztmp/` (never `/tmp`), named
  `ai_runtime_261125_<todo-id>_<what>`, deleted when done.
- **Only your part.** What you find for another part goes into `changes.md` under "For other
  parts", addressed to its todo.

## Questions

Append each question (new or rewritten) to `new_questions.md` under its section; a new one takes
the next free id from PQ-60 on, a rewritten one keeps its id. **Each question must be
understandable on its own**, by someone who reads nothing else: quote the passage in full with its
item id and section chain, say what each term in it means, say what the source, the baseline or
the product owner's instruction says that raises it, and why it matters — which items read
differently, what the Blueprint could get wrong.

```markdown
> **❓ PQ-60 (2026-11-25T19:10+01:00) — <topic in a few words>:** <the question, one sentence>
>
> **Context:** <the passage(s) quoted in full with item id and section chain; each term explained
> in a sentence; what the source, the baseline or the instruction says, quoted>
>
> **Why I ask:** <what is undecided or contradictory, and what depends on the answer>
>
> - (a) <option as a full sentence: what the text would then say, and its consequence>
> - **(b)** <the recommended option, bold>
> - (c) <…>
>
> *Recommendation:* (b) — <why>
>
> *Assumption until answered:* <what the text says meanwhile>
>
> **Answer:**
```

Exactly one option is bold, and the recommendation names the same one. Ask what is a real
choice; prefer one question that settles a topic over several small ones.

## How a part todo works (`p1s1r5-2` … `p1s1r5-10`)

1. Read these instructions, `answers.md`, and in `triage.md` the cross-cutting rulings and your
   work list. Find your sections by their `<!--[ID]-->` headings; line numbers move.
2. For each row: read the finding in its file and the item it concerns, then apply it as a marked
   change, write its question into `new_questions.md`, or — when on reading it the ruling does
   not hold — record in `changes.md` why you did otherwise.
3. Do what your todo's description names besides the rows.
4. Read your part once more from start to end as someone who has to write a Solution Blueprint
   from it: every item states one thing, in the agreed terms, in the current state, with its
   source in the citation shapes; every feature of the baseline that belongs to your part is in
   it; nothing contradicts another item or a cross-cutting ruling.
5. Record your part in `changes.md` (below) and complete the todo.

## At the end of your todo

Append to `changes.md` (create it if missing) a section for your part: the rows applied (finding
ids → item ids changed or added), the questions written (new and rewritten ids), the open
questions you settled (id → decision), the rows dropped and why, "Obligations changed",
"Sources needed", "For other parts". Then set the todo to completed.

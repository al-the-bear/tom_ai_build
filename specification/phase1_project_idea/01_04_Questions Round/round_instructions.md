# Round instructions — Phase 1, question round 4

For every todo `p1s1r4-*`. Document: `../project_idea.ai_runtime.md` (the Project Idea, plain
Markdown). Read these instructions completely before changing anything.

## What the round is for

The product owner's instruction, verbatim: "Please revise the document once more and make it
consistent. Check what todos (current and recently archived) and planning documents are in
vscode_extension, webwork, tom forge and al_the_bear and look for further input for the project
idea, to complete it. You may suggest your improvement ideas, too."

So the round does three things: it takes in the ten answers (`answers.md`), it completes the
Project Idea from the other quests (the three `inputs_*.md` files), and it makes the document
consistent (`consistency_read.md`). Unlike round 3, **meaning changes** in this round — but only
where an answer or a decided source says so.

## What you work from

- `answers.md` — PQ-24 … PQ-33 with the answers verbatim.
- `triage.md` — written by `p1s1r4-1`: every finding and answer consequence, assigned to a part,
  with the ruling **apply** (and what to write), **ask** (a question for the product owner) or
  **drop** (with the reason). **Your part's rows are your work list.** Read the finding itself in
  its input file before you act on a row; the triage row is a pointer, not the full text.
- The four input files, for the full text of a finding. A finding that points to a source (a todo
  id, a document) may be checked there; the sources are read-only.
- The binding terminology: `_ai/quests/ai_runtime/ai_runtime_terminology.md` § 2, and the glossary
  `GLO` of the Project Idea. New text uses those terms.

## What decides, in this order

1. **An answer of the product owner** (`answers.md`). Where an answer picks an option, apply that
   option's consequence everywhere it reaches, not only at the question's place. Where an answer
   is free text (PQ-24's second half, PQ-28, PQ-29, PQ-30, PQ-31), apply what it states and ask
   about what it leaves open — do not fill the gap with an invention.
2. **A decided source the product owner named as the standard**: al_the_bear's
   `_ai/quests/al_the_bear/ai_format_migration.md` for the `_ai` folder and for quests in
   repositories ("an updated and for now definite approach to quests in repos (which I'd consider
   the standard from now on)"). Where it differs from the Project Idea, the Project Idea follows
   it — except where that would drop something the Project Idea decided with the product owner
   (a D-<n> from an answered question): then ask, naming both.
3. **What the extension does today** (`inputs_vscode_extension.md`): engine behaviour that is
   built and that the runtime carries over is written into the Project Idea as what the runtime
   does. Behaviour only planned in a todo is written as planned, with its todo id as the source.
4. **What Webwork and Tom Forge need** (`inputs_webwork_tom_forge.md`): a need is recorded as a
   need of that host; whether this product meets it is the product owner's choice where the
   Project Idea does not already say — ask.
5. **The consistency read**: an inconsistency is resolved toward the item a decision (D-<n>) or
   an answer backs; where neither item is backed, ask. A gap is filled only from a source;
   otherwise it becomes a question or a line under the item saying what the Blueprint must settle.
6. **Improvement ideas** (ID-<n>, and your own): never written into the text as if decided. Each
   one worth proposing becomes a question with the idea as its recommended option, or is dropped
   in `changes.md` with the reason.

## Rules for the text

- **Ids.** Existing ids keep their meaning and are never reused. A new item gets the next free
  number of its area (grep the whole document for the highest; another todo may have added one —
  check again just before you write). An item that no longer holds is not deleted silently: mark
  its text as removed and say in one sentence what replaces it, so references to its id still
  land. New sources get the next `S<n>` in `SRC` (only `p1s1r4-2` adds sources; the others list
  the sources they need in `changes.md` under "Sources needed", and cite them as the triage names
  them).
- **Current state only.** The document says what is, not what it used to say: no "no longer",
  "was changed", "earlier". History belongs to `DEC` (a decision names what it replaced) and `CON`.
- **Requirements whose obligation changes.** The Project Idea has no approved requirements yet
  (G1 has not passed), so no status is set back; but every change that alters what an item
  demands is listed in `changes.md` under "Obligations changed", with the answer or source.
- **Marks.** Every change is an inline review mark: `{~~old~>new~~}`, `{++added++}`,
  `{--removed--}`; a remark for the reader as `{>>…<<}` only where the reason is not obvious from
  the answer. A whole new item or paragraph is one `{++…++}` (no blank line inside a mark: mark
  each paragraph or list item on its own). Do not rewrap paragraphs you did not change.
- **References** on one line: never break a section-id chain (`A > B > C`) across lines; no line
  may start with `>` except in a question block.
- **The question blocks PQ-24 … PQ-33 stay where they are** until `p1s1r4-11` removes them.
- **Signing.** A remark that needs the product owner's eye starts with `___check here___` and says
  why. Use it sparingly.
- **No commit.** The round's closing item commits. Scratch files only in `ztmp/` (never `/tmp`),
  named `ai_runtime_261120_<todo-id>_<what>`, deleted when done.
- **Only your part.** Do not edit another part's sections. What you find for another part goes
  into `changes.md` under "For other parts", addressed to its todo; `p1s1r4-11` picks up what is
  left.

## Questions

Append each question to `new_questions.md` under its section, with the next free id from PQ-34
on (re-read the file just before appending; ids must not collide). **Each question must be
understandable on its own**, by someone who reads nothing else: quote the passage in full with
its item id and section chain, say what each term in it means, say what the source or answer
says that raises the question, and why it matters — which items would read differently, what the
Blueprint could get wrong.

```markdown
> **❓ PQ-34 (2026-11-20T17:10+01:00) — <topic in a few words>:** <the question, one sentence>
>
> **Context:** <the passage(s) quoted in full with item id and section chain; each term explained
> in a sentence; what the answer, source or other item says, quoted>
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
choice; do not ask what an answer, the terminology or a decided source already settles. Prefer
one question that settles a topic over several small ones: questions on the same topic from
several parts are merged by `p1s1r4-11`.

## At the end of your todo

Append to `changes.md` (create it if missing) a section for your part: the triage rows you
applied (finding ids → item ids changed or added), the rows you turned into questions (ids), the
rows you dropped and why, "Obligations changed", "Sources needed", "For other parts". Then set the
todo to completed.

## How a part todo works (`p1s1r4-2` … `p1s1r4-10`)

1. Read these instructions, `answers.md`, and in `triage.md` the cross-cutting rulings and the
   work list of your todo. Find your sections by their `<!--[ID]-->` headings; line numbers move.
2. For each row of your work list: read the finding itself in its input file and the item it
   concerns, then apply it as a marked change, or write its question into `new_questions.md`
   (only the questions the triage assigns to your part), or — when on reading it the ruling does
   not hold — record in `changes.md` why you did otherwise.
3. Do what your todo's description names besides the rows.
4. Read your part once more from start to end as someone who has to write a Solution Blueprint
   from it: every item states one thing, in the agreed terms, in the current state, with its
   source; nothing contradicts another item of the part or a cross-cutting ruling. What you see
   beyond the work list is handled by the same rules. Ideas of your own become questions.
5. Record your part in `changes.md` (§ At the end of your todo) and complete the todo.

A part todo is done when every row of its work list is applied, asked or recorded as dropped,
the answers that reach the part are in its text, each change is a well-formed mark, and the
part reads consistently in itself.

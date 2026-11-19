# Gate G1 (Project Idea Captured), Tom AI Runtime — run 2: how the items are evaluated

Run 2 re-evaluates run 1 (`G1_20261119-1317`, result fail: G1-ID-1 and
G1-CLAR-1). Every todo `p1gr2-<n>` of this run follows these rules.

- **Inspected document:** `tom_ai/ai_build/specification/phase1_project_idea/project_idea.ai_runtime.md`
  as committed in ai_build `07412a22`: after question round 2, in which the
  product owner's 23 answers (PQ-1 … PQ-23) were taken into the text and the
  text was read as a whole against them (round folder
  `phase1_project_idea/01_02_Questions Round/`: `answers.md`, `changes.md`).
  Do not change the document.
- **Checklist:** `tom_ai/ai_build/specification/gates/G1.checklist.yaml`. For
  each item read `inspect`, `method`, `how`, `evidence` and `pass`, and
  evaluate exactly that, on the document as it is now. Run 1's evidence
  (`../G1_20261119-1317/`) may be read to see what was found then; a result
  is never copied from it.
- **Evidence** goes into this folder, one or more files per item, named
  `<item id>.<what>.<ext>`: the output of a command or query, or a reader's
  note that quotes what was found and names where, by section-id chain on one
  line (`VIS > VIS-PROBLEM`).
- **Result:** one `<item id>.result.yaml` per item: `id`, `status`
  (`pass` | `fail` | `not-run`), `run1` (its status in run 1),
  `evidence` (the file names), `finding` (one or two sentences), and on a
  fail `remediation` and `phasetodo`.
- **A failed item is never waived.** It becomes a quest todo in ai_runtime:
  id `phasetodosone<n>_<date code>-<short description>` (the next free
  `<n>` after 2; the date code from tomAi_generateIdPrefix), a self-contained
  description (the document, the item, the finding, what to do, DONE WHEN the
  item's `pass` holds), tags `tom_specs`, `phase1`, `gate-g1`.
- Judge by the checklist's `pass` text, not more strictly and not more
  leniently; where a reading is borderline, say so in the finding.
- Do not commit: the gate's closing item commits. Set your todo to completed
  when its items are recorded (also when an item fails).

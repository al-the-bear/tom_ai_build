# Gate G1 (Project Idea Captured), Tom AI Runtime — run 1: how the items are evaluated

Every todo `p1gr1-<n>` of this gate run follows these rules.

- **Inspected document:** `tom_ai/ai_build/specification/phase1_project_idea/project_idea.ai_runtime.md`
  as it is in the working tree: question round 1 written (19 questions `PQ-1` …
  `PQ-19`), every question answered by the product owner on 2026-11-19, the
  answers **not yet taken into the text** (no second round ran). Do not change
  the document.
- **Checklist:** `tom_ai/ai_build/specification/gates/G1.checklist.yaml` (the
  generic G1 checklist 1.2.0, unchanged). For each item read `inspect`, `method`,
  `how`, `evidence` and `pass`, and evaluate exactly that.
- **Evidence** goes into this folder, one or more files per item, named
  `<item id>.<what>.<ext>`: the output of a command or query
  (`G1-SRC-1.resolve.txt`), or a reader's note (`G1-PROB-1.reading.md`) that
  quotes what was found and names where, by section-id chain on one line
  (`VIS > VIS-PROBLEM`).
- **Result:** one `<item id>.result.yaml` per item:
  `id`, `status` (`pass` | `fail` | `not-run`), `evidence` (the file names),
  `finding` (one or two sentences, on a fail: what is missing or wrong),
  `remediation` (on a fail: what makes it pass).
- **A failed item is never waived.** It becomes a quest todo in ai_runtime:
  id `phasetodosone<n>_<date code>-<short description>` (the next free `<n>`;
  the date code from tomAi_generateIdPrefix), title naming the item, a
  self-contained description (the document, the item, the finding, what to do,
  DONE WHEN the item's `pass` holds), tags `tom_specs`, `phase1`, `gate-g1`.
  Name the todo's id in the result file (`phasetodo:`).
- Judge by the checklist's `pass` text, not more strictly and not more
  leniently; where a reading is borderline, say so in the finding.
- Do not commit: the gate's closing item commits. Set your todo to completed
  when its items are recorded (also when an item fails).

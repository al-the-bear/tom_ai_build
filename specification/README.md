# Tom AI Runtime specification (TomSpecs)

This folder holds the specification of the Tom AI Runtime (tar), Tom Agent
Coordination (tac), Tom Runtime Control (trc), their client packages and the
Flutter UI components, produced with the TomSpecs project flow. The process
authority is `tom_specs_project_flow.md` in the `tom_specs_model` package
(`../tom_specs_model/doc/`); the phase and gate ids below are its.

## Layout

| Folder | Phase | Content |
| --- | --- | --- |
| [`phase1_project_idea/`](phase1_project_idea/) | 1 — Project Idea | The free-form idea, [`sources/`](phase1_project_idea/sources/) with snapshots of what it was drawn from, and one folder per question round |
| [`gates/`](gates/) | — | The project's gate checklists (`G<N>.checklist.yaml`) |
| [`quality/evidence/gates/`](quality/evidence/gates/) | — | Per gate run: the report of record (`.gate.yaml`), its summary (`.gate.md`) and the evidence folder |

## Status

| Phase | Artifact | State | Gate |
| --- | --- | --- | --- |
| 1 | [`project_idea.ai_runtime.md`](phase1_project_idea/project_idea.ai_runtime.md) | Five question rounds; the answers PQ-1 … PQ-33 are in the text; round 5 (as change marks, to be reviewed) wrote the first version's feature baseline from the extension, Webwork and this quest (D-74), the review exchange for Webwork, and the new VS Code extension in `ai_build` (D-73); **33 questions open** (PQ-34 … PQ-66), ten of which block the Blueprint | G1 run 2 on 2026-11-19 passed all nine items — [report](quality/evidence/gates/G1_20261119-2045.gate.md) — on the document before rounds 3 to 5; **to be run again** after the answers (G1-CLAR-1 fails as it stands). Run 1 failed ([report](quality/evidence/gates/G1_20261119-1317.gate.md)) |

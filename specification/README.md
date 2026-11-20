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
| 1 | [`project_idea.ai_runtime.md`](phase1_project_idea/project_idea.ai_runtime.md) | Three question rounds; the answers PQ-1 … PQ-23 are in the text, and it uses the agreed terminology throughout (as change marks, to be reviewed); **ten questions open** (PQ-24 … PQ-33) | G1 run 2 on 2026-11-19 passed all nine items — [report](quality/evidence/gates/G1_20261119-2045.gate.md) — on the document before round 3; to be run again after its answers. Run 1 failed ([report](quality/evidence/gates/G1_20261119-1317.gate.md)) |

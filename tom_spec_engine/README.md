# tom_spec_engine

The **TomSpecs scripting/engine plane** — the pure-Dart host behind the TomSpecs
editor's D4rt scripting & LLM tooling. It is factored as its own project so it
stays usable headless (CLI, tests) and is linked **in-process** by the Flutter
editor.

> **Status: Phase-A scaffold.** Only package metadata ships today. The
> capabilities below are the target surface; they land step by step per
> [`d4rt_and_llm_tools_plan.md`](../../../_ai/quests/tom_specs/d4rt_and_llm_tools_plan.md).

## What it will own

| Area | Role | Plan steps |
| --- | --- | --- |
| **Scope registry** | Named, immutable sets of bridged D4rt libraries + globals + permission grants; the three base scopes `spec` / `files` / `memory`. | 6–8 |
| **`spec` scope** | The `tom_som` document API (generic / reflection / typed `tom_som_dart_v0`) bound to the live `SpecDocumentController`, plus search. | 7 |
| **`files` scope** | A restricted `dcli` facade — read anywhere, write only under `agent/scratchpad`. | 8 |
| **Search index** | Structural/lexical (BM25/FTS + facets) over the object model, zero-LLM, incremental refresh; backs grep-like cursor search. | 9 |
| **RAG memory** | Section-level nodes in **Tom Brain named memory**; tier-1 lexical + tier-2 incremental vectors (Tom Brain embedding API); fused recall. | 10–12 |
| **Agent substrate** | Pluggable `AgentSubstrate` — direct Agent SDK (mode a) and Agent-SDK-through-Tom-Brain (mode b) — over profiles / named sessions / named memory. | 15–17 |

## Dependencies

- [`tom_d4rt`](../../d4rt/tom_d4rt) `^1.10.1` — the sandboxed interpreter (now on
  `analyzer ^10`, so it co-resolves with the editor's `tom_dart_editor`).
- [`tom_d4rt_dcli`](../../d4rt/tom_d4rt_dcli) `^1.1.3` — dcli bridged into D4rt;
  wrapped (never exposed raw) by the `files` scope facade.
- [`tom_som_dart_runtime`](../tom_som_dart_runtime),
  [`tom_som_dart_v0`](../tom_som_dart_v0) — the document model the `spec` scope
  exposes.

The **embeddable Tom Brain** packages (substrate / memory / procedure) are added
in plan step 2, where the in-process substrate façade is adopted — see
[`d4rt_and_llm_tools_decisions.md`](../../../_ai/quests/tom_specs/d4rt_and_llm_tools_decisions.md).

## Develop

```bash
dart pub get
dart analyze
dart test     # or: testkit :test
```

# tom_spec_engine — documentation

The package documentation for `tom_spec_engine`: how to use this package's code.
The scripting plane's *design* — what each scope is, what the tool surface is
for, how the memory tiers are meant to work — is the **subject-matter tier**,
owned by
[`llm_and_d4rt_tools.md`](../../tom_specs_model/doc/llm_and_d4rt_tools.md) and
catalogued by
[`tom_specs_model/doc/index.md`](../../tom_specs_model/doc/index.md). Documents
here cite it rather than restating it
(`tom_specs_documentation_standard.md` §1.2).

## Guides

| Document | Covers |
|----------|--------|
| [scripting.md](scripting.md) | Running a script end to end: the `SpecController` port you supply, the scope registry, `ScriptTools`, **the import a script needs**, choosing between the two barrels, and storing a script for re-use |
| [searching.md](searching.md) | The free tier-1 index: building it from node projections, text and structural queries, refreshing it, and when a question needs the memory plane instead |
| [memory.md](memory.md) | The two-tier RAG plane: `SpecRecall` and its fusion, the graph tier, **the vector-runtime precondition**, and how to tell a degraded result from a full one |
| [tools.md](tools.md) | The four tool families an agent calls, why results are values rather than exceptions, and which barrel exposes each |

## API reference

| Document | Covers |
|----------|--------|
| [api/api_summary_index.md](api/api_summary_index.md) | The index of the per-module API summaries |
| [api/api_summary_scope.md](api/api_summary_scope.md) | The port, the scopes, the registry, the file facade |
| [api/api_summary_tools.md](api/api_summary_tools.md) | The four tool families and their result values |
| [api/api_summary_index_module.md](api/api_summary_index_module.md) | The structural / lexical index |
| [api/api_summary_memory.md](api/api_summary_memory.md) | The recall, memory, graph and embedder surfaces |
| [api/api_summary_agent.md](api/api_summary_agent.md) | The agent substrates and context |

## Where to start

- **Embedding the engine?** [scripting.md](scripting.md) — and settle the barrel
  question first: `scripting.dart` for Flutter, `tom_spec_engine.dart` elsewhere.
- **A script fails with `Undefined variable: spec`?**
  [scripting.md § The import a script needs](scripting.md#the-import-a-script-needs).
  The scope grants the authority; the import brings the names into lexical scope.
- **Finding sections?** [searching.md](searching.md). Reach for a facet before a
  text term — both are free, and one is exact.
- **A memory run refuses to start?**
  [memory.md § The vector-runtime precondition](memory.md#the-vector-runtime-precondition).
  It is almost always the host's `libsqlite3`, not the engine.

## Development documentation

`_copilot_guidelines/` holds this package's **development** documentation and is
not part of the tier above:

| Document | Covers |
|----------|--------|
| [`_copilot_guidelines/index.md`](../_copilot_guidelines/index.md) | The catalogue of this package's development guidelines |
| [`_copilot_guidelines/bridge_regeneration.md`](../_copilot_guidelines/bridge_regeneration.md) | When to re-run the D4rt bridge generator, and what the freshness stamp catches |

## Beyond this package

| Where | What it decides |
|-------|-----------------|
| [`llm_and_d4rt_tools.md`](../../tom_specs_model/doc/llm_and_d4rt_tools.md) | The scripting plane itself — the D4rt host, the `spec` / `files` / `memory` scopes, search, the tool surface, the memory tiers, the agent substrate |
| [`llm_guidelines_specification.md`](../../tom_specs_model/doc/llm_guidelines_specification.md) | What the in-editor agent is told about authoring a script, including the library each scope binds |
| [`tom_specs_editor_specification.md`](../../tom_specs_model/doc/tom_specs_editor_specification.md) | The application that links this engine in-process |
| [`tom_specs_model/doc/index.md`](../../tom_specs_model/doc/index.md) | The catalogue of the whole subject-matter tier, and the `§` citation convention |

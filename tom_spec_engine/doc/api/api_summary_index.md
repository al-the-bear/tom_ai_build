# TomSpecs Engine API Reference: Index

The public API of `tom_spec_engine`, one summary per module. Which barrel
exposes what is the first thing to settle — see
[scripting.md § Choosing which barrel](../scripting.md#choosing-which-barrel-to-import).

| Module | Summary | Covers | Behind |
|--------|---------|--------|--------|
| `scope` | [api_summary_scope.md](api_summary_scope.md) | The `SpecController` port, the base scopes, the registry, the file facade and the injected globals | both barrels |
| `tools` | [api_summary_tools.md](api_summary_tools.md) | `ScriptTools`, `DocTools`, `FileTools`, `MemoryTools` and their result values | both, except `MemoryTools` |
| `index` | [api_summary_index_module.md](api_summary_index_module.md) | `StructuralLexicalIndex`, `IndexQuery`, `IndexHit` | both barrels |
| `memory` | [api_summary_memory.md](api_summary_memory.md) | `SpecRecall`, `SpecMemory`, `SpecRagGraph`, the incremental indexer and the embedder | full barrel only |
| `agent` | [api_summary_agent.md](api_summary_agent.md) | The agent substrates, the per-application context and the procedure host | full barrel only |

For task-oriented guides rather than reference tables, see the
[documentation index](../index.md).

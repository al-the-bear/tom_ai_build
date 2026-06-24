/// TomSpecs scripting/engine plane.
///
/// The pure-Dart host behind the TomSpecs editor's D4rt scripting & LLM
/// tooling. As the implementation lands (see
/// `_ai/quests/tom_specs/d4rt_and_llm_tools_plan.md`) this package will own:
///
///   * the D4rt **scope registry** and the three base scopes
///     (`spec` / `files` / `memory`);
///   * the restricted **`dcli` file facade** (read-any / write-`agent/scratchpad`);
///   * the structural/lexical **search index** + cursor iteration;
///   * the **RAG memory** and **agent substrate**, both built on the embeddable
///     Tom Brain (profiles / named sessions / named memory).
///
/// It is factored as its own pure-Dart project so it stays reusable headless
/// (CLI, tests), and is linked **in-process** by the Flutter editor.
///
/// Phase A is landing step by step. Exported so far:
///   * package metadata (`engine_meta.dart`);
///   * the **Tom Brain memory façade** (`memory/`) — `SpecMemory` /
///     `MemoryScope` over the embeddable, profile-isolated, in-process memory
///     plane (plan step 2);
///   * the **D4rt scripting scope model** (`scope/`) — `ScriptScope` /
///     `ScopeRegistry` / `RunEnvironment` / `ScopeProfile` and the reusable
///     `tom_som` bridged-library block (plan step 6, §4);
///   * the **`spec` base scope** (`scope/`) — `SpecController` (the live-document
///     controller port), the `SpecApi` script facade + its D4rt bridge, and the
///     `specScope()` factory that binds document editing to the live controller
///     so a script edit shares the change log + undo stack with a tool edit
///     (plan step 7, §5);
///   * the **`files` base scope** (`scope/`) — `SpecFileFacade` (the audited
///     read-anywhere / write-whitelist file surface, default writable
///     `agent/scratchpad`) plus the `filesScope()` factory that bridges only the
///     facade (raw `dcli` / `dart:io` writes stay unbridged) and grants the D4rt
///     permission system `read=any` + `write=<whitelist>` as a backstop
///     (plan step 8, §7);
///   * the **tier-1 structural/lexical index** (`index/`) —
///     `StructuralLexicalIndex`, an inverted BM25 text index + structural facets
///     built directly from the object model (`SpecNodeProjection`s), with zero
///     model calls and incremental per-section refresh, backing the §6 search
///     facility (plan step 9, §9.2);
///   * the **section-level RAG store** (`memory/`) — the pure `SpecRagGraph`
///     builder (section nodes + tree/`@MapsTo`/`@DetailedIn` edges from a
///     document's projections, zero I/O / zero model calls) plus
///     `SpecDocumentMemory.indexDocument` / `recallSections` / `edgesFrom`,
///     which persist that graph as `Concept` nodes + `part_of` / `mentions`
///     edges into the document's profile-isolated Tom Brain named memory and
///     recall it back, all in-process (plan step 10, §9.1);
///   * the **fused two-tier recall** (`memory/`) — `SpecRecall.recall`, which
///     combines the tier-1 lexical (BM25) + symbolic (facet) modes with the
///     tier-2 vector mode and an optional GraphWalk via weighted Reciprocal
///     Rank Fusion + MMR, degrading gracefully to tier 1 while tier 2 warms;
///     plus `SpecDocumentMemory.indexChangedSections`, the incremental
///     embed-changed-only refresh (content-addressed nodes, forget-on-update /
///     forget-on-remove) that feeds it (plan step 11, §9.2 / §9.3);
///   * the **`memory` base scope** (`scope/`) — `MemoryApi` (the read-only
///     recall facade over `SpecRecall`) + its D4rt bridge, and the
///     `memoryScope()` factory that injects a single recall-bound `memory`
///     global and grants no permission, so a sandboxed script can recall but
///     has no mutation path at all (plan step 12, §4 / §9);
///   * the **script tools** (`tools/`) — `ScriptTools` (the engine logic behind
///     the `script_author` / `script_validate` / `script_run` / `script_list` /
///     `script_get` MCP tools) over a `ScopeRegistry` + a `ScriptStore`
///     (`FileScriptStore` persists `*.d4rt.dart` under `agent/scripts/`): author
///     a named script recording its scopes, validate it against the granted
///     scope without running, and run it under named scopes capturing stdout +
///     the auto-awaited `main()` return + error/stack (plan step 13, §8.1);
///   * the **in-memory read/write/search tools** (`tools/`) — the engine logic
///     behind the §8.2 `doc_*` / `mem_*` / `file_*` MCP tools (plan step 14):
///     `DocTools` (`doc_search` + `doc_search_iterate` over the §6 cursor,
///     `doc_reflect` meta-model facts, and `doc_add_node` routed through the
///     `SpecController` so it lands in the one change log), `MemoryTools`
///     (`mem_recall` over the fused `SpecRecall` with an optional per-mode
///     filter, `mem_refresh` over an injected re-index callback), and
///     `FileTools` (`file_read` / `file_find` / `file_write` over the audited
///     `SpecFileFacade`). Every result is a typed value with a compact `toJson`
///     (plan step 14, §8.2);
///   * the **agent substrate** (`agent/`) — the §10 pluggable [AgentSubstrate]
///     (`AgentTask` / `AgentRunResult`) and its **mode (a)** implementation
///     `DirectAgentSubstrate`: a headless procedure host that drives the
///     **complex agent procedure** (`AgentProcedure.searchRecallEditVerify`, a
///     D4rt script over the §8 tools) through a search → recall → edit → verify
///     loop. The procedure reaches the toolsets through one bridged `agent`
///     global (`AgentToolsApi`, the `agent` scope), so every edit lands in the
///     one change log and every step returns compact JSON (plan step 15, §10);
///   * **mode (b)** (`agent/`) — `BrainAgentSubstrate`, the
///     **Agent-SDK-through-`tom_brain`** substrate: it drives the *same*
///     procedure through the *same* host (`runAgentProcedure`, now shared with
///     mode (a)) but wraps each run in a Tom Brain **session envelope**
///     (`BrainSessionEnvelope`) — a profile (application) + named session
///     (phase/task) + named memory (document) addressed by a `MemoryScope`,
///     recording the run into that named memory. `buildAgentSubstrate` +
///     `AgentSubstrateMode` are the selector the application uses to pick a mode
///     behind the one `AgentSubstrate` interface — **mode (b) is the default**
///     (`defaultAgentSubstrateMode`, decision F2); mode (a) is opt-in for the
///     lightest single-application use; the headless
///     `RecordingBrainEnvelope` keeps the "same loop test" host-independent
///     while the live `tom_brain_memory`-backed envelope is wired in the editor
///     (plan step 16, §10).
///   * the **per-application AgentContext** (`agent/`) — the §11
///     [AgentContext] (`{guidelines doc, tool set, scope profile}`) realised as
///     a Tom Brain profile (`application` → profile, `guidelinesName` →
///     prompt, `toolset` → [AgentToolGroup]s, `scopeProfile` → enabled base
///     scopes) with a named session per phase/task and a named memory per
///     document via [AgentContext.memoryScope]. The **toolset ⊆ scopes**
///     invariant is enforced at construction; [AgentContext.brainSubstrate]
///     bridges to step-16's mode (b); [docSpecsAgentContext] is the reference
///     application (all four tool groups + the three base scopes); and
///     [AgentContextRegistry] is the application switch — one `context(name)`
///     call swaps guidelines + tools + scopes + memory together (plan step 17,
///     §11).
library;

export 'src/agent/agent_context.dart';
export 'src/agent/agent_procedure.dart';
export 'src/agent/agent_procedure_host.dart';
export 'src/agent/agent_scope.dart';
export 'src/agent/agent_substrate.dart';
export 'src/agent/agent_substrate_factory.dart';
export 'src/agent/agent_tools_api.dart';
export 'src/agent/brain_agent_substrate.dart';
export 'src/agent/brain_session_envelope.dart';
export 'src/agent/conversational_substrate.dart';
export 'src/agent/direct_agent_substrate.dart';
export 'src/agent/spec_brain_envelope.dart';
export 'src/engine_meta.dart';
export 'src/memory/incremental_indexer.dart';
export 'src/memory/provider_embedder.dart';
export 'src/memory/spec_memory.dart';
export 'src/memory/spec_rag_graph.dart';
export 'src/memory/spec_recall.dart';
export 'src/index/structural_lexical_index.dart';
export 'src/scope/files_scope.dart';
export 'src/scope/memory_api.dart';
export 'src/scope/memory_scope.dart';
export 'src/scope/scope.dart';
export 'src/scope/scope_registry.dart';
export 'src/scope/som_library.dart';
export 'src/scope/spec_api.dart';
export 'src/scope/spec_controller.dart';
export 'src/scope/spec_file_facade.dart';
export 'src/scope/spec_scope.dart';
export 'src/tools/doc_tools.dart';
export 'src/tools/file_tools.dart';
export 'src/tools/memory_tools.dart';
export 'src/tools/script_store.dart';
export 'src/tools/script_tools.dart';

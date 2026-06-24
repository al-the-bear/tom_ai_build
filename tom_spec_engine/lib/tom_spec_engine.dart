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
///     `tom_som` bridged-library block (plan step 6, §4).
library;

export 'src/engine_meta.dart';
export 'src/memory/spec_memory.dart';
export 'src/scope/scope.dart';
export 'src/scope/scope_registry.dart';
export 'src/scope/som_library.dart';

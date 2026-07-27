/// The **Flutter-safe scripting facade** of the engine (plan step 18, §3 / §5 /
/// §8.1).
///
/// The TomSpecs editor links the engine **in-process** to give its agent a D4rt
/// scripting surface over the live document (§3.1). The full barrel
/// (`tom_spec_engine.dart`) also exports the RAG **memory** plane, which depends
/// on `tom_brain_memory` (sqlite3 FFI / `vec0` — a server-only, non-Flutter
/// surface, §2). The editor needs only the **scripting** surface — the `spec`
/// scope bound to a live [SpecController], the scope registry, and the script
/// tools — none of which touch memory.
///
/// This partial library re-exports exactly that scripting surface, so the editor
/// can `import 'package:tom_spec_engine/scripting.dart'` and link the engine
/// in-process **without** pulling the memory plane into the Flutter compile.
/// Everything reachable from here depends only on `tom_d4rt` +
/// `tom_som_dart_runtime` (both already on the editor's resolved graph).
///
/// Beyond the scripting surface it also re-exports the **memory-free §8 tool
/// classes** the editor's `AgentToolsModule` registers as MCP tools
/// (`llm_and_d4rt_tools.md` §8): [DocTools] (the §6 `doc_*` search /
/// reflect / add-node logic over a [SpecController]) and [FileTools] (the audited
/// `file_*` surface over a [SpecFileFacade]). The `mem_*` `MemoryTools` are
/// **not** re-exported here — they depend on the server-only memory plane
/// (`tom_brain_memory`), so they stay out of the Flutter compile until the
/// embeddable memory plane is wired into the editor.
library;

export 'src/scope/scope.dart'
    show BridgedLibrary, ScopeGlobal, ScriptScope, ScopeError;
export 'src/scope/scope_registry.dart';
export 'src/scope/spec_api.dart';
export 'src/scope/spec_controller.dart';
export 'src/scope/spec_file_facade.dart';
export 'src/scope/spec_model_api.dart';
export 'src/scope/spec_scope.dart';
export 'src/scope/spec_search_api.dart';
export 'src/tools/doc_tools.dart';
export 'src/tools/file_tools.dart';
export 'src/tools/script_store.dart';
export 'src/tools/script_tools.dart';

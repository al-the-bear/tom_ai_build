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
library;

export 'src/scope/scope.dart'
    show BridgedLibrary, ScopeGlobal, ScriptScope, ScopeError;
export 'src/scope/scope_registry.dart';
export 'src/scope/spec_api.dart';
export 'src/scope/spec_controller.dart';
export 'src/scope/spec_scope.dart';
export 'src/tools/script_store.dart';
export 'src/tools/script_tools.dart';

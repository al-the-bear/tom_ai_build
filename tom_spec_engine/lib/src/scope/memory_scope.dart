/// The `memory` base scope (§4, §9, plan step 12).
///
/// Builds the [ScriptScope] that binds the document's fused two-tier recall to
/// a sandboxed script as a **read-only** surface. The scope exposes exactly one
/// bridged-library block, `memory_api`, whose registrar:
///
///   1. registers the [MemoryApi] bridged class on the interpreter, and
///   2. injects a single recall-bound [MemoryApi] instance as the `memory`
///      global under [memoryApiLibrary].
///
/// A script that imports `package:tom_spec_engine/memory.dart` then `await`s
/// recall through `memory` (`await memory.recall(...)`,
/// `await memory.recallPaths(...)`) — and can do nothing else. The scope grants
/// **no `tom_d4rt` permission** (§4: "none beyond memory"): recall is an
/// in-memory read, not a filesystem/network capability, and the editing API
/// (`spec`) and file facade (`files`) are simply never registered, so there is
/// no mutation path under this scope at all.
library;

import '../memory/spec_recall.dart';
import 'memory_api.dart';
import 'scope.dart';

/// The conventional name of the `memory` base scope.
const String memoryScopeName = 'memory';

/// Builds the `memory` scope bound to [recall].
///
/// [name] defaults to [memoryScopeName]; override it only to register the same
/// recall binding under an alternate scope label.
ScriptScope memoryScope(SpecRecall recall, {String name = memoryScopeName}) {
  final api = MemoryApi(recall);
  return ScriptScope(
    name: name,
    libraries: [
      BridgedLibrary(memoryApiLibraryName, (interpreter) {
        interpreter.registerBridgedClass(
            memoryApiBridgedClass(), memoryApiLibrary);
        interpreter.registerGlobalVariable(
            memoryApiGlobalName, api, memoryApiLibrary);
      }),
    ],
  );
}

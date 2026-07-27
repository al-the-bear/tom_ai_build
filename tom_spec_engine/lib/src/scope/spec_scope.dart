/// The `spec` base scope (§4, §5).
///
/// Builds the [ScriptScope] that binds the document editing API to a **live**
/// [SpecController]. The scope exposes exactly one bridged-library block,
/// `spec_api`, whose registrar:
///
///   1. registers the [SpecApi] bridged class on the interpreter, and
///   2. injects a single controller-bound [SpecApi] instance as the `spec`
///      global under [specApiLibrary].
///
/// A script that imports `package:tom_spec_engine/spec_api.dart` then drives the
/// document through `spec` (`spec.setContent(...)`, `spec.addChild(...)`, …) —
/// every call mediated by the controller, so the change log and undo stack see
/// a script edit and a tool edit identically (§5 "one change log").
///
/// The scope grants **no extra `tom_d4rt` permission**: document access is not a
/// filesystem/network capability but an in-memory operation gated by the
/// controller itself (the §4 table's "document read+write (mediated)" is the
/// controller mediation, not a `Permission`). The `files` and `memory` scopes
/// (§7, §9) carry the actual permission grants.
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show SpecModel, SpecQueryEngine;

import 'scope.dart';
import 'spec_api.dart';
import 'spec_controller.dart';
import 'spec_model_api.dart';
import 'spec_search_api.dart';

/// The conventional name of the `spec` base scope.
const String specScopeName = 'spec';

/// Builds the `spec` scope bound to [controller].
///
/// The scope always injects the controller-mediated editing facade ([SpecApi])
/// as the `spec` global. When [model] is supplied it *additionally* injects the
/// read-only reflection facade ([SpecModelApi]) as the `model` global (§4, §5) —
/// the typed-read / meta-model surface a script consults before editing. When
/// [search] is supplied it *also* injects the read-only §6 grep facade
/// ([SpecSearchApi]) as the `search` global — the lexical/structural query
/// cursor a script pages over the live document, mirroring the `doc_search` MCP
/// tool.
///
/// [model] and [search] are **lazy, null-tolerant** providers, not values: each
/// is queried every time the scope's registrar runs (once per interpreter build
/// — i.e. on every `validate` and every `run`), so they see the live document's
/// current [SpecModel] / [SpecQueryEngine]. A provider returns `null` when its
/// backing state is not yet loaded; in that case the corresponding global is
/// simply not injected for that build, so a synchronous `validate` against a
/// not-yet-loaded controller degrades gracefully instead of throwing. A run
/// binds them only after the model has loaded.
///
/// [name] defaults to [specScopeName]; override it only to register the same
/// controller binding under an alternate scope label.
ScriptScope specScope(
  SpecController controller, {
  String name = specScopeName,
  SpecModel? Function()? model,
  SpecQueryEngine? Function()? search,
}) {
  final api = SpecApi(controller);
  return ScriptScope(
    name: name,
    libraries: [
      BridgedLibrary(specApiLibraryName, (interpreter) {
        interpreter.registerBridgedClass(specApiBridgedClass(), specApiLibrary);
        interpreter.registerGlobalVariable(
            specApiGlobalName, api, specApiLibrary);
      }),
      if (model != null)
        BridgedLibrary(specModelApiLibraryName, (interpreter) {
          final m = model();
          if (m == null) return;
          interpreter.registerBridgedClass(
              specModelApiBridgedClass(), specModelApiLibrary);
          interpreter.registerGlobalVariable(
              specModelApiGlobalName, SpecModelApi(m), specModelApiLibrary);
        }),
      if (search != null)
        BridgedLibrary(specSearchApiLibraryName, (interpreter) {
          final engine = search();
          if (engine == null) return;
          interpreter.registerBridgedClass(
              specSearchApiBridgedClass(), specSearchApiLibrary);
          interpreter.registerBridgedClass(
              specSearchCursorBridgedClass(), specSearchApiLibrary);
          interpreter.registerGlobalVariable(
              specSearchApiGlobalName, SpecSearchApi(engine), specSearchApiLibrary);
        }),
    ],
  );
}

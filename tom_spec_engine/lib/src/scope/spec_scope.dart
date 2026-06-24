/// The `spec` base scope (§4, §5, plan step 7).
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
/// (plan steps 8, 12) carry the actual permission grants.
library;

import 'scope.dart';
import 'spec_api.dart';
import 'spec_controller.dart';

/// The conventional name of the `spec` base scope.
const String specScopeName = 'spec';

/// Builds the `spec` scope bound to [controller].
///
/// [name] defaults to [specScopeName]; override it only to register the same
/// controller binding under an alternate scope label.
ScriptScope specScope(SpecController controller, {String name = specScopeName}) {
  final api = SpecApi(controller);
  return ScriptScope(
    name: name,
    libraries: [
      BridgedLibrary(specApiLibraryName, (interpreter) {
        interpreter.registerBridgedClass(specApiBridgedClass(), specApiLibrary);
        interpreter.registerGlobalVariable(
            specApiGlobalName, api, specApiLibrary);
      }),
    ],
  );
}

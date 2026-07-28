/// The `tom_som` bridged-library building block (`llm_and_d4rt_tools.md` §5).
///
/// Wraps the generated [TomSomBridge] registration as a reusable
/// [BridgedLibrary] so a scope — chiefly the `spec` scope
/// (`llm_and_d4rt_tools.md` §5) — can expose the complete `tom_som` document
/// API (generic runtime + reflection + typed `tom_som_dart_v0`) to a sandboxed
/// script. Binding it to the *live controller* (change log / undo) is the
/// `spec` scope's concern; this block exposes the bridged surface itself.
library;

import '../../dartscript.b.dart';
import 'scope.dart';

/// The canonical name of the `tom_som` bridged-library block.
const String somLibraryName = 'tom_som';

/// Returns the reusable [BridgedLibrary] that registers the full generated
/// `tom_som` D4rt bridge ([TomSomBridge]) on an interpreter.
BridgedLibrary somBridgedLibrary() =>
    BridgedLibrary(somLibraryName, TomSomBridge.register);

/// The `tom_som` bridged-library building block (§5, plan steps 5 + 6).
///
/// Wraps the generated [TomSomBridge] registration (step 5) as a reusable
/// [BridgedLibrary] so a scope — chiefly the forthcoming `spec` scope (step 7) —
/// can expose the complete `tom_som` document API (generic runtime + reflection
/// + typed `tom_som_dart_v0`) to a sandboxed script. Binding it to the *live
/// controller* (change log / undo) is step 7's concern; this block exposes the
/// bridged surface itself.
library;

import '../../dartscript.b.dart';
import 'scope.dart';

/// The canonical name of the `tom_som` bridged-library block.
const String somLibraryName = 'tom_som';

/// Returns the reusable [BridgedLibrary] that registers the full generated
/// `tom_som` D4rt bridge ([TomSomBridge]) on an interpreter.
BridgedLibrary somBridgedLibrary() =>
    BridgedLibrary(somLibraryName, TomSomBridge.register);

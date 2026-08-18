// D4rt Bridge - Generated file, do not edit
// Dartscript registration for tom_spec_engine
// Generated: 2026-08-18T09:33:45.355462

/// D4rt Bridge Registration for tom_spec_engine
library;

import 'package:tom_d4rt/d4rt.dart';
import 'src/bridges/som_runtime_bridges.b.dart' as som_runtime_bridges;
import 'src/bridges/som_v0_bridges.b.dart' as som_v0_bridges;
import 'src/bridges/relaxers.b.dart' as relaxer_factories;

/// Combined bridge registration for tom_spec_engine.
class TomSomBridge {
  /// Register all bridges with D4rt interpreter.
  static void register([D4rt? interpreter]) {
    final d4rt = interpreter ?? D4rt();

    som_runtime_bridges.SomRuntimeBridge.registerBridges(
      d4rt,
      'package:tom_som_dart_runtime/tom_som_dart_runtime.dart',
    );
    // Register under sub-package barrels for direct imports
    for (final barrel in som_runtime_bridges.SomRuntimeBridge.subPackageBarrels()) {
      som_runtime_bridges.SomRuntimeBridge.registerBridges(d4rt, barrel);
    }
    som_v0_bridges.SomV0Bridge.registerBridges(
      d4rt,
      'package:tom_som_dart_v0/tom_som_dart_v0.dart',
    );
    // Register under sub-package barrels for direct imports
    for (final barrel in som_v0_bridges.SomV0Bridge.subPackageBarrels()) {
      som_v0_bridges.SomV0Bridge.registerBridges(d4rt, barrel);
    }

    // RC-2: Register generic constructor factories
    relaxer_factories.registerGenericConstructors();
    // GEN-079: Register relaxer wrapper factories
    relaxer_factories.registerRelaxers();
  }

  /// Get import block for all modules.
  static String getImportBlock() {
    final buffer = StringBuffer();
    buffer.writeln(som_runtime_bridges.SomRuntimeBridge.getImportBlock());
    buffer.writeln(som_v0_bridges.SomV0Bridge.getImportBlock());
    return buffer.toString();
  }
}

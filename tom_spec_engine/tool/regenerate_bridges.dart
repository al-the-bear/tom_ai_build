// ignore_for_file: avoid_print
/// Regenerate the TomSpecs SOM D4rt bridges from `buildkit.yaml`'s `d4rtgen:`
/// block (`llm_and_d4rt_tools.md` §13.1).
///
/// The bridges are generated here, in the engine plane, NOT in the lean
/// pure-data `tom_som_dart_runtime` / `tom_som_dart_v0` packages. Run this
/// whenever the public surface of those SOM packages changes. See
/// `_copilot_guidelines/bridge_regeneration.md` for the full workflow.
///
/// Run from the tom_spec_engine project root:
///   dart run tool/regenerate_bridges.dart
library;

import 'dart:io';

import 'package:tom_d4rt_generator/tom_d4rt_generator.dart';

import 'som_surface.dart';

Future<void> main() async {
  final projectPath = Directory.current.path;
  final configPath = '$projectPath/buildkit.yaml';

  print('Regenerating SOM bridges for: $projectPath');
  print('Config: $configPath');
  print('');

  final stopwatch = Stopwatch()..start();

  final result = await generateBridges(
    configPath: configPath,
    projectPath: projectPath,
  );

  stopwatch.stop();

  print('');
  print('=== Generation Complete ===');
  print('Total classes: ${result.totalClasses}');
  print('Total modules: ${result.totalModules}');
  print('Output files: ${result.outputFiles.length}');
  for (final f in result.outputFiles) {
    print('  - $f');
  }
  if (result.errors.isNotEmpty) {
    print('Errors:');
    for (final e in result.errors) {
      print('  ERROR: $e');
    }
  }
  print('Time: ${stopwatch.elapsed}');
  print('Success: ${result.isSuccess}');

  if (!result.isSuccess) {
    exitCode = 1;
    return;
  }

  // Record the SOM surface these bridges were generated from. This is what
  // makes the staleness guard possible at all: `som_bridge_freshness_test.dart`
  // recomputes the fingerprint and fails when it no longer matches, which is
  // precisely the case "SOM moved, the bridges did not". Written only on
  // success — stamping a failed run would certify bridges that were never
  // produced.
  final mismatch = somSurfaceModuleMismatch(engineRoot: projectPath);
  if (mismatch != null) {
    print('ERROR: cannot stamp the SOM surface — $mismatch');
    exitCode = 1;
    return;
  }

  final surface = computeSomSurface(engineRoot: projectPath);
  writeSomSurfaceStamp(surface, engineRoot: projectPath);
  print('');
  print('SOM surface stamped in $somSurfaceStampPath');
  print('  fingerprint: ${surface.fingerprint}');
  for (final entry in surface.declarationCounts.entries) {
    print('  ${entry.key}: ${entry.value} top-level declarations');
  }
}

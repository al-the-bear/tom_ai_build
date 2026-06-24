// ignore_for_file: avoid_print
/// Regenerate the TomSpecs SOM D4rt bridges from `buildkit.yaml`'s `d4rtgen:`
/// block (plan step 5 / spec §13.1).
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
  }
}

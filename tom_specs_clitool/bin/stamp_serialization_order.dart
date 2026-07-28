import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// One-shot tool (SOM §5.2) that stamps `@SerializationOrder(n)` above **every
/// instance member of every spec-model class**, numbered by source declaration
/// order (0-based, per class).
///
/// The stamping logic now lives in `stampSerializationOrder` (library
/// `src/serialization_order.dart`) so the SOM generator can invoke it as its
/// mandatory first step; this CLI is a thin wrapper over that function. It is a
/// pure source rewrite of every `.dart` file under the package's `lib/src`
/// (excluding the snapshot/serialization/generated engine dirs and
/// `*.versioner.dart` build artifacts — the same set [ModelReader] reflects) and
/// is re-runnable: any pre-existing `@SerializationOrder(...)` on a member is
/// removed before the fresh ordinal is inserted, so a second run renumbers
/// cleanly after the model is edited.
///
/// Usage:
///   `dart run bin/stamp_serialization_order.dart --package <model-path> [--dry-run]`
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('package',
        abbr: 'p',
        help: 'Path to the target Dart package (its lib/src is rewritten).',
        mandatory: true)
    ..addFlag('dry-run',
        help: 'Report what would change without writing files.',
        negatable: false)
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stdout.writeln(parser.usage);
    exit(2);
  }
  if (results.flag('help')) {
    stdout.writeln('Usage: dart run bin/stamp_serialization_order.dart '
        '--package <path> [--dry-run]');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final packagePath = p.normalize(p.absolute(results.option('package')!));
  final dryRun = results.flag('dry-run');

  final SerializationStampResult result;
  try {
    result = stampSerializationOrder(packagePath: packagePath, dryRun: dryRun);
  } on StateError catch (e) {
    stderr.writeln('Error: ${e.message}');
    exit(1);
  }

  stdout.writeln('stamp_serialization_order: '
      '${dryRun ? '[dry-run] ' : ''}'
      'files changed: ${result.filesChanged}, '
      'members stamped: ${result.membersStamped}'
      '${result.membersRestamped > 0 ? ', restamped (removed old): '
          '${result.membersRestamped}' : ''}');
  if (result.multiVarWarnings.isNotEmpty) {
    stderr.writeln('WARNING: ${result.multiVarWarnings.length} multi-variable '
        'field declaration(s) share one ordinal:');
    for (final w in result.multiVarWarnings) {
      stderr.writeln('  - $w');
    }
  }
}

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Generates the `spec_ops.g.dart` registry that adopts the snapshot/
/// serialization contract across every `tom_specs_model` class (OE-2).
///
/// Reads the model package with the analyzer (same path as `model_json.dart`),
/// then emits one `registerSpecOps()` registering a `SpecClassOps` per concrete
/// type.
///
/// **This is the ad-hoc entry point, not the canonical one.** The registry is
/// generated out of `tom_specs_model` exactly like the nine language packages,
/// so `bin/generate_som.dart` produces it as part of the one regeneration
/// command and the model fingerprint that command stamps certifies it. Reach
/// for this CLI to write the registry somewhere else, or to regenerate it alone
/// without paying for a nine-language run.
Future<void> main(List<String> arguments) async {
  final aiBuild = p.dirname(p.normalize(
      p.dirname(p.dirname(p.fromUri(Platform.script)))));

  final parser = ArgParser()
    ..addOption(
      'package',
      abbr: 'p',
      help: 'Path to the tom_specs_model package (its lib/ is scanned). '
          'Default: <ai_build>/tom_specs_model.',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output .dart file path. '
          'Default: <package>/${specOpsPathSegments.join('/')}.',
    )
    ..addFlag('help', abbr: 'h', help: 'Show usage information.',
        negatable: false);

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stdout.writeln(parser.usage);
    exit(2);
  }

  if (results.flag('help')) {
    stdout.writeln('Usage: dart run bin/spec_ops.dart '
        '[--package <model-path>] [--output <file.g.dart>]\n');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final packagePath = p.normalize(p.absolute(
      results.option('package') ?? p.join(aiBuild, 'tom_specs_model')));

  stdout.writeln('spec_ops: analyzing $packagePath ...');
  final SpecOpsResult result;
  try {
    result = await generateSpecOpsRegistry(
      modelPackagePath: packagePath,
      outputPath: results.option('output'),
    );
  } on StateError catch (e) {
    stderr.writeln('Error: ${e.message}');
    exit(1);
  }
  stdout.writeln('Found ${result.classCount} classes.');
  stdout.writeln('${result.changed ? 'Wrote' : 'Unchanged'} spec-ops registry '
      'at ${result.outputPath}');
}

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Generates the `spec_ops.g.dart` registry that adopts the snapshot/
/// serialization contract across every `tom_specs_model` class (OE-2).
///
/// Reads the model package with the analyzer (same path as `model_json.dart`),
/// then emits one `registerSpecOps()` registering a `SpecClassOps` per concrete
/// type. Run as a build step beside `model_json.dart`.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'package',
      abbr: 'p',
      help: 'Path to the tom_specs_model package (its lib/ is scanned).',
      mandatory: true,
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output .dart file path (e.g. lib/src/generated/spec_ops.g.dart).',
      mandatory: true,
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
        '--package <model-path> --output <file.g.dart>');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final packagePath = p.normalize(p.absolute(results.option('package')!));
  final outputPath = p.normalize(p.absolute(results.option('output')!));
  final libPath = p.join(packagePath, 'lib');
  if (!Directory(libPath).existsSync()) {
    stderr.writeln('Error: lib/ directory not found at $libPath');
    exit(1);
  }

  stdout.writeln('spec_ops: analyzing $packagePath ...');
  final driver = createAnalysisDriver(packagePath);
  final reader = ModelReader(driver);
  await reader.analyzePackage(libPath);
  stdout.writeln('Found ${reader.classes.length} classes.');

  final source = SpecOpsGenerator(reader.classes).generate();
  final outFile = File(outputPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(source);
  stdout.writeln('Wrote spec-ops registry to $outputPath');
}

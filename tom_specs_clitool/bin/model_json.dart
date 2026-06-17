import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Exports the tom_specs_model class graph as JSON for the spec editor.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'package',
      abbr: 'p',
      help: 'Path to the target Dart package (its lib/ directory is scanned).',
      mandatory: true,
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output JSON file path.',
      mandatory: true,
    )
    ..addOption(
      'model-version',
      help: 'S2 model-version counter to stamp into the JSON (integer). '
          'Fed from the tom_specs_model version stamp by the build. Default: 0.',
      defaultsTo: '0',
    )
    ..addOption(
      'model-label',
      help: 'Human-readable build label for the model version stamp '
          '(e.g. TomSpecsModelVersionInfo.versionMedium).',
    )
    ..addFlag('help', abbr: 'h', help: 'Show usage information.', negatable: false);

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stdout.writeln(parser.usage);
    exit(2);
  }

  if (results.flag('help')) {
    stdout.writeln('Usage: dart run bin/model_json.dart '
        '--package <path> --output <file.json>');
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

  stdout.writeln('model_json: analyzing $packagePath ...');
  final driver = createAnalysisDriver(packagePath);
  final reader = ModelReader(driver);
  await reader.analyzePackage(libPath);
  stdout.writeln('Found ${reader.classes.length} classes, '
      '${reader.enums.length} enums.');

  final modelVersion = int.tryParse(results.option('model-version') ?? '0') ?? 0;
  final modelLabel = results.option('model-label');
  final json = ModelJsonExporter(
    reader.classes,
    modelVersion: modelVersion,
    modelVersionLabel: (modelLabel?.isNotEmpty ?? false) ? modelLabel : null,
  ).export();
  final encoded = const JsonEncoder.withIndent('  ').convert(json);

  final outFile = File(outputPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync('$encoded\n');

  stdout.writeln('Wrote ${json['rootCount']} roots, '
      '${json['classCount']} classes to $outputPath');
}

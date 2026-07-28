import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show somModelVersionString;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Generates the DocSpecs schemas (`som_multiplatform_spec_model.md` §13)
/// from the TomSpecs object model.
///
/// Emits one `*.docspecs-schema.yaml` per `@Document` root (1 global Project
/// Definition + 12 projection roots = 13) into `<out-dir>/<id>/<id>.<ver>...`.
/// The `--version` integer is the model stamp (S2) and counts up as the model
/// changes; it is rendered as `<version>.0` to stay parseable by the DocSpecs
/// filename grammar.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'package',
      abbr: 'p',
      help: 'Path to the tom_specs_model package (its lib/ is scanned).',
      mandatory: true,
    )
    ..addOption(
      'out-dir',
      abbr: 'o',
      help: 'Output directory for the schema tree '
          '(default: <cwd>/.tom/docspecs-schema).',
    )
    ..addOption(
      'version',
      abbr: 'v',
      help: 'Model version stamp (integer major, counts up). Default: 1.',
      defaultsTo: '1',
    )
    ..addOption(
      'label',
      abbr: 'l',
      help: 'Full model build label (e.g. 1.3.0+5.abc1234). When it carries a '
          'major.minor the in-file schema version tracks it (matching the _v0 '
          'facades); otherwise the version is <version>.0.',
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
    stdout.writeln('Usage: dart run bin/docspecs_schema.dart '
        '--package <path> [--out-dir <dir>] [--version <n>] [--label <s>]');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final packagePath = p.normalize(p.absolute(results.option('package')!));
  final outDir = p.normalize(p.absolute(
    results.option('out-dir') ??
        p.join(Directory.current.path, '.tom', 'docspecs-schema'),
  ));
  final modelVersion = int.tryParse(results.option('version')!);
  if (modelVersion == null || modelVersion < 1) {
    stderr.writeln('Error: --version must be a positive integer.');
    exit(2);
  }
  final modelLabel = results.option('label');
  final versionString = somModelVersionString(modelVersion, modelLabel);

  final libPath = p.join(packagePath, 'lib');
  if (!Directory(libPath).existsSync()) {
    stderr.writeln('Error: lib/ directory not found at $libPath');
    exit(1);
  }

  stdout.writeln('docspecs_schema: analyzing $packagePath ...');
  final driver = createAnalysisDriver(packagePath);
  final reader = ModelReader(driver);
  await reader.analyzePackage(libPath);

  final schemas = DocSpecsSchemaGenerator(reader.classes)
      .generateAll(modelVersion: modelVersion, modelLabel: modelLabel);
  stdout.writeln('Generated ${schemas.length} schema(s) at version '
      '$versionString.');

  for (final schema in schemas.values) {
    final fileName = DocSpecsSchemaGenerator.fileNameFor(schema);
    final file = File(p.join(outDir, schema.id, fileName));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(DocSpecsSchemaGenerator.toYamlString(schema));
    stdout.writeln('  wrote ${schema.id} '
        '(${schema.sectionTypes.length} section-types) -> ${file.path}');
  }
}

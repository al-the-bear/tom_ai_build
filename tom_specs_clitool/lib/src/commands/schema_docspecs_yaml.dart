import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Generates the standalone JSON Schema for the generic on-disk
/// `*.docspecs.yaml` **document wire format**.
///
/// Unlike `tomspecs :schema-docspecs` — which emits one per-root DocSpecs schema
/// describing the section grammar of a single document root — this emits a
/// single schema for the *file envelope* every `*.docspecs.yaml` shares
/// (`version` / `modelVersion` / `document` / `review`), so a saved file can be
/// schema-validated without resolving its model.
/// Runs `tomspecs :schema-docspecs-yaml` with [arguments] and returns its exit code, without ending
/// the process (the `tomspecs` command calls it).
Future<int> runDocspecsYamlSchema(List<String> arguments) async {
  _exitCode = 0;
  try {
    await _mainDocspecsYamlSchema(arguments);
  } on ToolExit catch (e) {
    return e.code;
  }
  return _exitCode;
}

int _exitCode = 0;

/// The options of `tomspecs :schema-docspecs-yaml`.
ArgParser docspecsYamlSchemaParser() => ArgParser()
  ..addOption(
    'out-dir',
    abbr: 'o',
    help:
        'Output directory for the schema '
        '(default: <cwd>/.tom/json-schema).',
  )
  ..addFlag(
    'help',
    abbr: 'h',
    help: 'Show usage information.',
    negatable: false,
  );

Future<void> _mainDocspecsYamlSchema(List<String> arguments) async {
  final parser = docspecsYamlSchemaParser();

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stdout.writeln(parser.usage);
    throw ToolExit(2);
  }

  if (results.flag('help')) {
    stdout.writeln(
      'Usage: tomspecs :schema-docspecs-yaml '
      '[--out-dir <dir>]',
    );
    stdout.writeln(parser.usage);
    throw ToolExit(0);
  }

  final outDir = p.normalize(
    p.absolute(
      results.option('out-dir') ??
          p.join(Directory.current.path, '.tom', 'json-schema'),
    ),
  );

  final generator = DocspecsYamlSchemaGenerator();
  final file = File(p.join(outDir, DocspecsYamlSchemaGenerator.fileName));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(generator.toJsonString());

  stdout.writeln(
    'schema-docspecs-yaml: wrote ${file.path} '
    '(format version ${generator.formatVersion}).',
  );
}

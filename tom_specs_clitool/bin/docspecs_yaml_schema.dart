import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Generates the standalone JSON Schema for the generic on-disk
/// `*.docspecs.yaml` **document wire format** (followup item 12, D20).
///
/// Unlike `docspecs_schema.dart` — which emits one per-root DocSpecs schema
/// describing the section grammar of a single document root — this emits a
/// single schema for the *file envelope* every `*.docspecs.yaml` shares
/// (`version` / `modelVersion` / `document` / `review`), so a saved file can be
/// schema-validated without resolving its model.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'out-dir',
      abbr: 'o',
      help: 'Output directory for the schema '
          '(default: <cwd>/.tom/json-schema).',
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
    stdout.writeln('Usage: dart run bin/docspecs_yaml_schema.dart '
        '[--out-dir <dir>]');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final outDir = p.normalize(p.absolute(
    results.option('out-dir') ??
        p.join(Directory.current.path, '.tom', 'json-schema'),
  ));

  final generator = DocspecsYamlSchemaGenerator();
  final file = File(p.join(outDir, DocspecsYamlSchemaGenerator.fileName));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(generator.toJsonString());

  stdout.writeln('docspecs_yaml_schema: wrote ${file.path} '
      '(format version ${generator.formatVersion}).');
}

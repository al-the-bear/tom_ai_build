import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Regenerates the machine-readable **CodeSpecs area catalogue** — the input
/// the nine-runtime `spec_codespecs_extract` surface reads — by transcribing
/// `codespecs_mapping.md` §4.1, §4.4.3 and §4.4.6.
///
///   dart run bin/codespecs_areas.dart
///   dart run bin/codespecs_areas.dart --check
///
/// `--check` writes nothing and exits 1 when the committed file disagrees with
/// the document, which is what makes the catalogue drift-proof: the mapping
/// document stays the single authority and the JSON is its transcription.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('mapping',
        help: 'The mapping document to transcribe. Default: the sibling '
            'tom_specs_model/doc/codespecs_mapping.md.')
    ..addOption('output',
        help: 'Where to write the catalogue. Default: '
            'tom_specs_model/generated-doc/codespecs/codespecs_areas.json.')
    ..addFlag('check',
        help: 'Verify the committed file matches the document; write nothing.',
        negatable: false)
    ..addFlag('help',
        abbr: 'h', help: 'Show usage information.', negatable: false);

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stdout.writeln(parser.usage);
    exit(2);
  }

  if (results.flag('help')) {
    stdout.writeln('Usage: dart run bin/codespecs_areas.dart [options]');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final clitoolRoot = p.dirname(p.dirname(p.fromUri(Platform.script)));
  final modelRoot = p.normalize(p.join(clitoolRoot, '..', 'tom_specs_model'));

  final mappingPath = p.normalize(p.absolute(results.option('mapping') ??
      p.join(modelRoot, 'doc', 'codespecs_mapping.md')));
  final outputPath = p.normalize(p.absolute(results.option('output') ??
      p.join(modelRoot, 'generated-doc', 'codespecs',
          'codespecs_areas.json')));

  final String text;
  try {
    if (results.flag('check')) {
      final mapping = File(mappingPath);
      if (!mapping.existsSync()) {
        throw AreasCatalogException('mapping document not found: $mappingPath');
      }
      text = buildAreasCatalog(mapping.readAsStringSync()).toJsonText();
      final committed = File(outputPath);
      if (!committed.existsSync()) {
        stderr.writeln('codespecs_areas --check: $outputPath does not exist.');
        exit(1);
      }
      if (committed.readAsStringSync() != text) {
        stderr.writeln('codespecs_areas --check: '
            '${p.relative(outputPath, from: clitoolRoot)} is stale — '
            'run `dart run bin/codespecs_areas.dart` and commit the diff.');
        exit(1);
      }
    } else {
      text = writeAreasCatalog(mappingPath: mappingPath, outputPath: outputPath);
    }
  } on AreasCatalogException catch (e) {
    stderr.writeln('codespecs_areas error: ${e.message}');
    exit(1);
  }

  final catalog = buildAreasCatalog(File(mappingPath).readAsStringSync());
  stdout.writeln('${results.flag('check') ? 'OK — up to date' : 'Wrote'} '
      '${p.relative(outputPath, from: clitoolRoot)}');
  stdout.writeln('  ${catalog.areas.length} area(s), '
      '${catalog.slices.length} slice(s), '
      '${text.length} byte(s).');
  exit(0);
}

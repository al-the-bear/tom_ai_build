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
    ..addOption(
      'mapping',
      help:
          'The mapping document to transcribe. Default: the sibling '
          'tom_specs_model/doc/codespecs_mapping.md.',
    )
    ..addOption(
      'output',
      help:
          'Where to write the catalogue. Default: '
          'tom_specs_model/generated-doc/codespecs/codespecs_areas.json.',
    )
    ..addFlag(
      'check',
      help: 'Verify the committed file matches the document; write nothing.',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show usage information.',
      negatable: false,
    );

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

  final mappingPath = p.normalize(
    p.absolute(
      results.option('mapping') ??
          p.join(modelRoot, 'doc', 'codespecs_mapping.md'),
    ),
  );
  final outputPath = p.normalize(
    p.absolute(
      results.option('output') ??
          p.join(
            modelRoot,
            'generated-doc',
            'codespecs',
            'codespecs_areas.json',
          ),
    ),
  );

  // The Dart accessor that ships beside the JSON. Same content, second form:
  // the JSON is what the eight non-Dart runtimes read, the library is what a
  // Dart consumer imports without walking a package URI.
  final accessorPath = p.normalize(
    p.join(modelRoot, 'lib', 'codespecs_areas.dart'),
  );

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
        stderr.writeln(
          'codespecs_areas --check: '
          '${p.relative(outputPath, from: clitoolRoot)} is stale — '
          'run `dart run bin/codespecs_areas.dart` and commit the diff.',
        );
        exit(1);
      }
      // The accessor is checked too, and separately: the two are written in
      // one pass but committed as two files, so a partial commit is exactly
      // the state that leaves a Dart consumer reading a catalogue the JSON no
      // longer agrees with.
      final accessor = File(accessorPath);
      if (!accessor.existsSync()) {
        stderr.writeln(
          'codespecs_areas --check: $accessorPath does not exist.',
        );
        exit(1);
      }
      if (accessor.readAsStringSync() !=
          await _formatted(areasAccessorLibrary(text), accessorPath)) {
        stderr.writeln(
          'codespecs_areas --check: '
          '${p.relative(accessorPath, from: clitoolRoot)} is stale — '
          'run `dart run bin/codespecs_areas.dart` and commit the diff.',
        );
        exit(1);
      }
    } else {
      text = writeAreasCatalog(
        mappingPath: mappingPath,
        outputPath: outputPath,
      );
      File(accessorPath).writeAsStringSync(
        await _formatted(areasAccessorLibrary(text), accessorPath),
      );
    }
  } on AreasCatalogException catch (e) {
    stderr.writeln('codespecs_areas error: ${e.message}');
    exit(1);
  }

  final catalog = buildAreasCatalog(File(mappingPath).readAsStringSync());
  stdout.writeln(
    '${results.flag('check') ? 'OK — up to date' : 'Wrote'} '
    '${p.relative(outputPath, from: clitoolRoot)}',
  );
  stdout.writeln(
    '  ${catalog.areas.length} area(s), '
    '${catalog.slices.length} slice(s), '
    '${text.length} byte(s).',
  );
  stdout.writeln('  accessor: ${p.relative(accessorPath, from: clitoolRoot)}');
  exit(0);
}

/// [source] run through `dart format`, or unchanged if the formatter is absent.
///
/// `tom_specs_model` is inside the formatting gate (`tool/format_set.yaml`), so
/// a generator writing into it is obliged to emit formatted output — otherwise
/// the tree is clean until the next regeneration and red after it, for
/// something nobody did. Shelling out to the installed `dart` rather than
/// linking `package:dart_style` is the same choice `check_format.dart` made: a
/// pinned formatter and the SDK binary drift apart at every SDK bump.
Future<String> _formatted(String source, String path) async {
  final tmp = File(
    '${Directory.systemTemp.path}/'
    '${p.basename(path)}.$pid.tmp.dart',
  )..writeAsStringSync(source);
  try {
    final r = await Process.run('dart', [
      'format',
      '--output=show',
      '--summary=none',
      tmp.path,
    ]);
    if (r.exitCode == 0 && (r.stdout as String).isNotEmpty) {
      return r.stdout as String;
    }
    return source;
  } on ProcessException {
    return source;
  } finally {
    if (tmp.existsSync()) tmp.deleteSync();
  }
}

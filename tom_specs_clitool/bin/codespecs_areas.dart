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
/// Runs `codespecs_areas` with [arguments] and returns its exit code, without ending
/// the process (the `tomspecs` command calls it).
Future<int> runCodespecsAreas(List<String> arguments) async {
  _exitCode = 0;
  try {
    await _mainCodespecsAreas(arguments);
  } on ToolExit catch (e) {
    return e.code;
  }
  return _exitCode;
}

int _exitCode = 0;

Future<void> main(List<String> arguments) async =>
    exit(await runCodespecsAreas(arguments));

/// The options of `codespecs_areas` (also the `tomspecs` command's).
ArgParser codespecsAreasParser() => ArgParser()
  ..addOption(
    'mapping',
    help:
        'The mapping document to transcribe. Default: '
        'tom_ai/ai_build/tom_core_codespecs/doc/codespecs_mapping.md.',
  )
  ..addOption(
    'prompt',
    help:
        'The starting-prompt document whose §4.4/§4.5 gate tables are '
        'transcribed. Default: '
        'tom_specs_model/doc/codespecs_prompt.md.',
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

Future<void> _mainCodespecsAreas(List<String> arguments) async {
  final parser = codespecsAreasParser();

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stdout.writeln(parser.usage);
    throw ToolExit(2);
  }

  if (results.flag('help')) {
    stdout.writeln('Usage: dart run bin/codespecs_areas.dart [options]');
    stdout.writeln(parser.usage);
    throw ToolExit(0);
  }

  final clitoolRoot = clitoolPackageRoot();
  final modelRoot = p.normalize(p.join(clitoolRoot, '..', 'tom_specs_model'));

  final mappingPath = p.normalize(
    p.absolute(
      results.option('mapping') ??
          p.join(
            clitoolRoot,
            '..',
            'tom_core_codespecs',
            'doc',
            'codespecs_mapping.md',
          ),
    ),
  );
  final promptPath = p.normalize(
    p.absolute(
      results.option('prompt') ??
          p.join(modelRoot, 'doc', 'codespecs_prompt.md'),
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
      text = buildAreasCatalog(
        mapping.readAsStringSync(),
        promptDocument: File(promptPath).readAsStringSync(),
      ).toJsonText();
      final committed = File(outputPath);
      if (!committed.existsSync()) {
        stderr.writeln('codespecs_areas --check: $outputPath does not exist.');
        throw ToolExit(1);
      }
      if (committed.readAsStringSync() != text) {
        stderr.writeln(
          'codespecs_areas --check: '
          '${p.relative(outputPath, from: clitoolRoot)} is stale — '
          'run `dart run bin/codespecs_areas.dart` and commit the diff.',
        );
        throw ToolExit(1);
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
        throw ToolExit(1);
      }
      if (accessor.readAsStringSync() !=
          await _formatted(areasAccessorLibrary(text), accessorPath)) {
        stderr.writeln(
          'codespecs_areas --check: '
          '${p.relative(accessorPath, from: clitoolRoot)} is stale — '
          'run `dart run bin/codespecs_areas.dart` and commit the diff.',
        );
        throw ToolExit(1);
      }
    } else {
      text = writeAreasCatalog(
        mappingPath: mappingPath,
        promptPath: promptPath,
        outputPath: outputPath,
      );
      File(accessorPath).writeAsStringSync(
        await _formatted(areasAccessorLibrary(text), accessorPath),
      );
    }
  } on AreasCatalogException catch (e) {
    stderr.writeln('codespecs_areas error: ${e.message}');
    throw ToolExit(1);
  }

  final catalog = buildAreasCatalog(
    File(mappingPath).readAsStringSync(),
    promptDocument: File(promptPath).readAsStringSync(),
  );
  stdout.writeln(
    '${results.flag('check') ? 'OK — up to date' : 'Wrote'} '
    '${p.relative(outputPath, from: clitoolRoot)}',
  );
  stdout.writeln(
    '  ${catalog.areas.length} area(s), '
    '${catalog.slices.length} slice(s), '
    '${catalog.steps.length} step(s), '
    '${text.length} byte(s).',
  );
  stdout.writeln('  accessor: ${p.relative(accessorPath, from: clitoolRoot)}');
  throw ToolExit(0);
}

/// [source] as the formatter writes it at [path], or unchanged when it does
/// not parse.
///
/// `tom_specs_model` is inside the formatting gate (`tool/format_set.yaml`), so
/// a generator writing into it is obliged to emit formatted output — otherwise
/// the tree is clean until the next regeneration and red after it, for
/// something nobody did. The formatter is the linked `dart_style`
/// ([DartFormat]) the gate uses, in the language version of the package
/// [path] lies in.
Future<String> _formatted(String source, String path) async {
  try {
    return DartFormat().format(source, path: path);
  } on DartFormatFailure {
    return source;
  }
}

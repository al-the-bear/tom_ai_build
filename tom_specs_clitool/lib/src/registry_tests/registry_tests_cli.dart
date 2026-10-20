/// `generate_registry_tests` — derives the registry part of an application's
/// test suite from its specification (`tom_specs_project_flow.md`, Phase 5).
///
/// Usage: `generate_registry_tests SPEC --out DIR [--check]
/// [--harness-import URI]`. Writes `registry_harness.g.dart`,
/// `registry_operations_test.dart` and `registry_screens_test.dart` into
/// `--out`; the application supplies `registry_harness.dart` there (or at
/// `--harness-import`) with `createRegistryTestHarness()`. With `--check`
/// nothing is written: the files on disk are compared with what the
/// registries give. Exit codes: `0` clean, `1` a registry finding or a stale
/// suite, `2` bad usage.
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';

import 'generator.dart';
import 'registries.dart';

/// Runs the command; returns the exit code.
Future<int> runGenerateRegistryTests(
  List<String> arguments, {
  StringSink? out,
}) async {
  final sink = out ?? stdout;
  final parser = ArgParser()
    ..addOption('out', help: 'The test folder the suites are written to.')
    ..addOption(
      'harness-import',
      defaultsTo: 'registry_harness.dart',
      help: "Import URI of the application's harness.",
    )
    ..addFlag('check', negatable: false, help: 'Compare, write nothing.')
    ..addFlag('help', abbr: 'h', negatable: false);
  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    sink.writeln('generate_registry_tests: ${e.message}');
    return 2;
  }
  if (results.flag('help') || results.rest.length != 1) {
    sink.writeln(
      'Usage: generate_registry_tests <spec.docspecs.yaml|.md> --out <dir> '
      '[--check]\n${parser.usage}',
    );
    return results.flag('help') ? 0 : 2;
  }
  final specPath = results.rest.single;
  final outDir = results.option('out');
  if (outDir == null) {
    sink.writeln('generate_registry_tests: --out is required');
    return 2;
  }
  final file = File(specPath);
  if (!file.existsSync()) {
    sink.writeln('generate_registry_tests: no such file $specPath');
    return 2;
  }

  final SpecDocument doc;
  if (specPath.endsWith('.md')) {
    doc = SpecDocument.fromMarkdown(
      file.readAsStringSync(),
      somSpecModel,
    ).document;
  } else {
    final tree = buildSomMetaTree(
      somSpecModel,
      rootType: 'D00SolutionBlueprint',
    );
    doc = SpecDocument.fromFile(specPath, tree);
  }
  final registries = readRegistries(somSpecModel, doc);
  final generation = generateRegistryTests(
    registries,
    harnessImport: results.option('harness-import')!,
  );
  sink.writeln(
    'generate_registry_tests: ${registries.operations.length} operation(s), '
    '${registries.roles.length} role(s), ${registries.errorCodes.length} '
    'error code(s), ${registries.screens.length} screen(s)',
  );
  for (final f in generation.findings) {
    sink.writeln('  $f');
  }

  if (results.flag('check')) {
    final existing = <String, String?>{
      for (final name in generation.files.keys)
        name: File(p.join(outDir, name)).existsSync()
            ? File(p.join(outDir, name)).readAsStringSync()
            : null,
    };
    final stale = checkRegistryTests(generation, existing);
    for (final f in stale) {
      sink.writeln('  $f');
    }
    final ok = generation.findings.isEmpty && stale.isEmpty;
    sink.writeln(
      ok
          ? 'generate_registry_tests: the suites match the registries'
          : 'generate_registry_tests: ${generation.findings.length + stale.length} finding(s)',
    );
    return ok ? 0 : 1;
  }

  Directory(outDir).createSync(recursive: true);
  for (final MapEntry(key: name, value: content) in generation.files.entries) {
    File(p.join(outDir, name)).writeAsStringSync(content);
  }
  // Generated Dart is written formatted, so a formatting gate in the
  // application never fails on it.
  final format = await Process.run('dart', [
    'format',
    for (final name in generation.files.keys) p.join(outDir, name),
  ]);
  sink.writeln(
    'generate_registry_tests: wrote ${generation.files.length} file(s) to '
    '$outDir${format.exitCode == 0 ? '' : ' (dart format failed: ${format.stderr})'}',
  );
  return generation.findings.isEmpty ? 0 : 1;
}

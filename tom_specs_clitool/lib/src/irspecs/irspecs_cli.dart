/// The `irspecs` command, as a function the entry point and the tests both
/// call.
///
/// Two subcommands:
///
/// * `irspecs from-codespecs` reads a CodeSpecs trio and writes its IR
///   (`irspecs_ir.md`): one `<CE-CODE>.ir.yaml` per area holding files, plus
///   `package.ir.yaml` for the files no area claims, into `--out` (a spec
///   root's `irspecs/` folder). An IR file in `--out` that the trio no longer
///   produces is deleted, so the folder is always the IR of exactly that
///   trio.
/// * `irspecs map --mapper dart-tom --ir <dir> --out <dir>` writes the trio
///   an IR folder describes, one folder per package under `--out`, through
///   the Dart + Tom mapper, formatted with `dart format`. With
///   `--spec <document> --unit <unit id>` it writes one generation unit
///   instead: the specification's register names the unit's kind and, per
///   area, its mapper, and only the areas `--mapper` holds for the unit are
///   written, into `--out/<unit id>` (`irspecs_ir.md` §8.1).
///
/// Exit codes: `0` written, `1` the mapper refused the IR, `2` bad usage.
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show
        CodeSpecsAreaCatalog,
        SpecDocument,
        buildSomMetaTree,
        specGenerationUnits;
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart' show somSpecModel;

import '../codespecs/cs_model.dart';
import '../codespecs/cs_reader.dart';
import '../validate_spec_cli.dart' show resolveSpecDocumentRoot;
import 'ir_model.dart';
import 'ir_units.dart';
import 'ir_yaml.dart';
import 'mappers/dart_tom/dart_tom_mapper.dart';

/// The `from-codespecs` option set — exposed so the README correspondence
/// test reads it.
ArgParser irspecsParser() => ArgParser()
  ..addOption(
    'shared',
    help: 'Path to the CodeSpecs <app>_codespec_shared package.',
  )
  ..addOption(
    'client',
    help: 'Path to the CodeSpecs <app>_codespec_client package.',
  )
  ..addOption(
    'server',
    help: 'Path to the CodeSpecs <app>_codespec_server package.',
  )
  ..addOption(
    'out',
    help:
        "from-codespecs: the folder to write the IR to, a spec root's "
        'irspecs/ folder. map: the folder to write the packages into.',
  )
  ..addOption(
    'ir',
    help: 'map: the folder of *.ir.yaml documents to write code from.',
  )
  ..addOption(
    'mapper',
    help: 'map: which mapper writes the code.',
    allowed: [kDartTomMapper],
  )
  ..addOption(
    'spec',
    help:
        'map: the specification document (*.docspecs.yaml or its Markdown '
        'rendition) whose generation-unit register names --unit.',
  )
  ..addOption(
    'unit',
    help:
        'map: write only this generation unit, into --out/<unit id> '
        '(needs --spec).',
  )
  ..addOption(
    'areas',
    help:
        'The CodeSpecs area catalogue (codespecs_areas.json, '
        'tom_specs_model/generated-doc/codespecs/), which assigns each file '
        'to its area.',
  )
  ..addFlag(
    'help',
    abbr: 'h',
    help: 'Show usage information.',
    negatable: false,
  );

/// Runs `irspecs` with [arguments]; returns the exit code. Output goes to
/// [out] and [err] (stdout and stderr by default).
Future<int> runIrspecs(
  List<String> arguments, {
  StringSink? out,
  StringSink? err,
}) async {
  final stdoutSink = out ?? stdout;
  final stderrSink = err ?? stderr;
  final parser = irspecsParser();
  void usage() => stderrSink.writeln(
    'Usage: dart run tom_specs_clitool:irspecs from-codespecs '
    '--shared <dir> --client <dir> --server <dir> --areas <json> '
    '--out <dir>\n'
    '       dart run tom_specs_clitool:irspecs map --mapper dart-tom '
    '--ir <dir> --out <dir> [--spec <document> --unit <unit id>]\n\n'
    '${parser.usage}',
  );

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderrSink.writeln(e.message);
    usage();
    return 2;
  }
  if (results.flag('help')) {
    stdoutSink.writeln(parser.usage);
    return 0;
  }
  final subcommand = results.rest.length == 1 ? results.rest.single : null;
  if (subcommand != 'from-codespecs' && subcommand != 'map') {
    stderrSink.writeln(
      results.rest.isEmpty
          ? 'Name the subcommand: from-codespecs or map.'
          : 'Unknown subcommand: ${results.rest.join(' ')}.',
    );
    usage();
    return 2;
  }
  if (subcommand == 'map') {
    return _map(results, stdoutSink, stderrSink, usage);
  }
  final missing = [
    for (final option in ['shared', 'client', 'server', 'areas', 'out'])
      if (results.option(option) == null) '--$option',
  ];
  if (missing.isNotEmpty) {
    stderrSink.writeln('Missing ${missing.join(', ')}.');
    usage();
    return 2;
  }

  final CodeSpecsAreaCatalog catalog;
  try {
    final areasPath = results.option('areas')!;
    catalog = CodeSpecsAreaCatalog.fromJson(
      jsonDecode(File(areasPath).readAsStringSync()) as Map<String, dynamic>,
    );
  } on Object catch (e) {
    stderrSink.writeln('Cannot read the area catalogue: $e');
    return 2;
  }

  final projects = <CsLocus, CsLocusProject>{};
  for (final locus in CsLocus.values) {
    final root = p.normalize(p.absolute(results.option(locus.name)!));
    if (!Directory(root).existsSync()) {
      stderrSink.writeln('${locus.label} package not found: $root');
      return 2;
    }
    projects[locus] = readCsLocusProjectFromDirectory(
      locus: locus,
      packageName: p.basename(root),
      root: root,
    );
  }

  final documents = irFromCsModel(
    shared: projects[CsLocus.shared]!,
    client: projects[CsLocus.client]!,
    server: projects[CsLocus.server]!,
    areas: IrAreaIndex(catalog),
  );
  final outDir = Directory(results.option('out')!)..createSync(recursive: true);
  final written = {for (final d in documents) d.fileName};
  for (final document in documents) {
    final file = File(p.join(outDir.path, document.fileName));
    final text = writeIrYaml(document);
    final state = !file.existsSync()
        ? 'new'
        : file.readAsStringSync() == text
        ? 'unchanged'
        : 'changed';
    if (state != 'unchanged') file.writeAsStringSync(text);
    final count = document.files.length;
    stdoutSink.writeln(
      '${document.fileName.padRight(22)} $state, $count file(s)',
    );
  }
  for (final stale in outDir.listSync().whereType<File>()) {
    final name = p.basename(stale.path);
    if (name.endsWith('.ir.yaml') && !written.contains(name)) {
      stale.deleteSync();
      stdoutSink.writeln('${name.padRight(22)} deleted (no file in the trio)');
    }
  }
  return 0;
}

Future<int> _map(
  ArgResults results,
  StringSink stdoutSink,
  StringSink stderrSink,
  void Function() usage,
) async {
  final missing = [
    for (final option in ['mapper', 'ir', 'out'])
      if (results.option(option) == null) '--$option',
  ];
  if (missing.isNotEmpty) {
    stderrSink.writeln('Missing ${missing.join(', ')}.');
    usage();
    return 2;
  }
  final spec = results.option('spec');
  final unitId = results.option('unit');
  if ((spec == null) != (unitId == null)) {
    stderrSink.writeln('--spec and --unit go together.');
    usage();
    return 2;
  }
  List<IrDocument> documents;
  try {
    final unit = spec == null ? null : _unitOf(spec, unitId!);
    documents = readIrFolder(results.option('ir')!);
    if (unit != null) {
      documents = irDocumentsForUnit(
        documents,
        unit,
        mapper: results.option('mapper')!,
      );
    }
  } on IrSpecsException catch (e) {
    stderrSink.writeln(e.message);
    return 2;
  }
  try {
    final written = await writeDartTom(documents, results.option('out')!);
    stdoutSink.writeln('${written.length} file(s) written and formatted.');
    return 0;
  } on IrMapException catch (e) {
    stderrSink.writeln(e.message);
    return 1;
  }
}

/// The generation unit [unitId] of the specification at [specPath]. Throws
/// [IrSpecsException] when the file cannot be read or decoded, or declares no
/// such unit.
IrUnit _unitOf(String specPath, String unitId) {
  final file = File(specPath);
  if (!file.existsSync()) {
    throw IrSpecsException('--spec: no file at $specPath');
  }
  final text = file.readAsStringSync();
  final isMarkdown = specPath.toLowerCase().endsWith('.md');
  final SpecDocument document;
  try {
    final root = resolveSpecDocumentRoot(
      somSpecModel,
      null,
      text,
      isMarkdown: isMarkdown,
    );
    document = isMarkdown
        ? SpecDocument.fromMarkdown(text, somSpecModel).document
        : SpecDocument.fromYaml(
            text,
            buildSomMetaTree(somSpecModel, rootType: root.type),
          );
  } on Object catch (e) {
    throw IrSpecsException('--spec: $specPath does not decode: $e');
  }
  final units = specGenerationUnits(somSpecModel, document);
  for (final u in units) {
    if (u.unitId == unitId) return IrUnit.fromRegister(u);
  }
  throw IrSpecsException(
    '--unit: $specPath declares no generation unit "$unitId"'
    '${units.isEmpty ? '' : '; it declares ${units.map((u) => u.unitId).join(', ')}'}',
  );
}

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
///   written, into `--out/<unit id>` (`irspecs_ir.md` §8.1). The other
///   mappers write other languages from the same IR: `ts-shared`,
///   `ts-react-client` and `ts-hono-server` an npm workspace
///   (`irspecs_ir.md` §11), `go-server` the server as a Go module
///   (`irspecs_ir.md` §12), `java-spring-server` as a Spring Boot project
///   (`irspecs_ir.md` §13).
///
/// * `irspecs emit --standard <name> --ir <dir> --out <dir>`, the name one
///   of `openapi`, `jsonschema`, `icu` and `asyncapi`, writes what a standard
///   can express of an IR folder in that standard (`irspecs_ir.md` §10), and
///   lists on stdout every fact it could not.
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
import 'emitters/asyncapi_emitter.dart';
import 'emitters/emit_common.dart';
import 'emitters/icu_emitter.dart';
import 'emitters/json_schema_emitter.dart';
import 'emitters/openapi_emitter.dart';
import 'mappers/dart_tom/dart_tom_mapper.dart';
import 'mappers/go/go_mapper.dart';
import 'mappers/java/java_spring_mapper.dart';
import 'mappers/ts/ts_mapper.dart';

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
    allowed: [
      kDartTomMapper,
      ...kTsMappers.keys,
      kGoServerMapper,
      kJavaSpringServerMapper,
    ],
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
    'standard',
    help: 'emit: the standard to write the IR in.',
    allowed: irStandards.keys.toList(),
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
    '--ir <dir> --out <dir> [--spec <document> --unit <unit id>]\n'
    '       dart run tom_specs_clitool:irspecs emit --standard '
    '<${irStandards.keys.join('|')}> --ir <dir> --out <dir>\n\n'
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
  if (subcommand == 'emit') {
    return _emit(results, stdoutSink, stderrSink, usage);
  }
  if (subcommand != 'from-codespecs' && subcommand != 'map') {
    stderrSink.writeln(
      results.rest.isEmpty
          ? 'Name the subcommand: from-codespecs, map or emit.'
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
  final List<IrDocument> all;
  try {
    final unit = spec == null ? null : _unitOf(spec, unitId!);
    documents = all = readIrFolder(results.option('ir')!);
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
  final mapper = results.option('mapper')!;
  try {
    if (mapper != kDartTomMapper) {
      final files = switch (mapper) {
        kGoServerMapper => mapGoServer(documents, all: all),
        kJavaSpringServerMapper => mapJavaSpring(documents, all: all),
        _ => mapTypeScript(documents, mapper, all: all),
      };
      for (final MapEntry(key: path, value: text) in files.entries) {
        File(p.joinAll([results.option('out')!, ...path.split('/')]))
          ..parent.createSync(recursive: true)
          ..writeAsStringSync(text);
      }
      stdoutSink.writeln('${files.length} file(s) written.');
      return 0;
    }
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

/// The standards `irspecs emit` writes, by `--standard` name
/// (`irspecs_ir.md` §10).
const Map<String, IrEmission Function(List<IrDocument>)> irStandards = {
  'openapi': emitOpenApi,
  'jsonschema': emitJsonSchema,
  'icu': emitIcu,
  'asyncapi': emitAsyncApi,
};

int _emit(
  ArgResults results,
  StringSink stdoutSink,
  StringSink stderrSink,
  void Function() usage,
) {
  final missing = [
    for (final option in ['standard', 'ir', 'out'])
      if (results.option(option) == null) '--$option',
  ];
  if (missing.isNotEmpty) {
    stderrSink.writeln('Missing ${missing.join(', ')}.');
    usage();
    return 2;
  }
  final List<IrDocument> documents;
  try {
    documents = readIrFolder(results.option('ir')!);
  } on IrSpecsException catch (e) {
    stderrSink.writeln(e.message);
    return 2;
  }
  final emission = irStandards[results.option('standard')!]!(documents);
  final outDir = Directory(results.option('out')!)..createSync(recursive: true);
  for (final MapEntry(key: name, value: text) in emission.files.entries) {
    File(p.join(outDir.path, name)).writeAsStringSync(text);
    stdoutSink.writeln('$name written');
  }
  if (emission.notExpressed.isEmpty) {
    stdoutSink.writeln('Every fact the standard reads was expressed.');
  } else {
    stdoutSink.writeln('Not expressed (irspecs_ir.md §10.2):');
    for (final line in emission.notExpressed) {
      stdoutSink.writeln('  - $line');
    }
  }
  return 0;
}

/// The `irspecs` command, as a function the entry point and the tests both
/// call.
///
/// Four subcommands:
///
/// * `tomspecs :ir-from-codespecs` reads a CodeSpecs trio and writes its IR
///   (`irspecs_ir.md`): one `<CE-CODE>_<canonical id>.ir.yaml` per area
///   holding files (`CE-DB_data_access.ir.yaml`), plus
///   `package.ir.yaml` for the files no area claims, into `--out` (a spec
///   root's `irspecs/` folder). An IR file in `--out` that the trio no longer
///   produces is deleted, so the folder is always the IR of exactly that
///   trio.
/// * `tomspecs :ir-map --mapper dart-tom --ir <dir> --out <dir>` writes the trio
///   an IR folder describes, one folder per package under `--out`, through
///   the Dart + Tom mapper, formatted with the linked `dart_style` (pinned to
///   the SDK's formatter, so no Dart SDK is needed). With
///   `--spec <document> --unit <unit id>` it writes one generation unit
///   instead: the specification's register names the unit's kind and, per
///   area, its mapper, and only the areas `--mapper` holds for the unit are
///   written, into `--out/<unit id>` (`irspecs_ir.md` §8.1). The other
///   mappers write other languages from the same IR: `ts-shared`,
///   `ts-react-client`, `ts-react-native-client` and `ts-hono-server` an npm
///   workspace (`irspecs_ir.md` §11), `go-server` the server as a Go module
///   (`irspecs_ir.md` §12), `java-spring-server` as a Spring Boot project
///   (`irspecs_ir.md` §13), `csharp-aspnet-server` as a .NET solution
///   (`irspecs_ir.md` §14).
///
/// * `tomspecs :ir-emit --standard <name> --ir <dir> --out <dir>`, the name one
///   of `openapi`, `jsonschema`, `icu` and `asyncapi`, writes what a standard
///   can express of an IR folder in that standard (`irspecs_ir.md` §10), and
///   lists on stdout every fact it could not.
///   `--standard markdown --areas <codespecs_areas.json>` writes the IR's
///   Markdown rendering instead, one
///   DocSpecs document per area and `index.md` (`irspecs_ir.md` §10.3); with
///   `--spec <document>` the index lists the generation units, a back-link
///   whose token a heading of the document's Markdown rendition carries links
///   into it, and `--out` defaults to
///   `<spec-root>/generated-doc/irspecs_md/`.
///
/// * `tomspecs :ir-export --format json --ir <dir> --out <dir>` writes every IR
///   document of the folder as JSON, `<name>.ir.json` beside its
///   `<name>.ir.yaml` name (`CE-DB_data_access.ir.json`): the same records,
///   valid against `tool/irspecs_ir.schema.json` (`irspecs_ir.md` §15). The
///   YAML stays the IR's committed form; an `*.ir.json` in `--out` the
///   folder no longer produces is deleted.
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
        SpecGenerationUnit,
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
import 'emitters/markdown_emitter.dart';
import 'emitters/openapi_emitter.dart';
import 'mappers/dart_tom/dart_tom_mapper.dart';
import 'mappers/csharp/csharp_aspnet_mapper.dart';
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
        'irspecs/ folder. map: the folder to write the packages into. '
        'emit, export: the folder to write the output into.',
  )
  ..addOption(
    'ir',
    help: 'map, emit, export: the folder of *.ir.yaml documents to read.',
  )
  ..addOption(
    'mapper',
    help: 'map: which mapper writes the code.',
    allowed: [
      kDartTomMapper,
      ...kTsMappers.keys,
      kGoServerMapper,
      kJavaSpringServerMapper,
      kCsharpAspnetServerMapper,
    ],
  )
  ..addOption(
    'spec',
    help:
        'map, emit: the specification document (*.docspecs.yaml or its '
        'Markdown rendition) whose generation-unit register names --unit.',
  )
  ..addOption(
    'unit',
    help:
        'map: write only this generation unit, into --out/<unit id>. emit: '
        'write every standard the unit\'s emitters name, instead of '
        '--standard. Needs --spec.',
  )
  ..addOption(
    'standard',
    help:
        'emit: the standard to write the IR in (or --spec and --unit). '
        '`markdown` needs --areas; with --spec it also lists the units and '
        'links each back-link a rendition heading carries, and --out '
        'defaults to '
        '<spec-root>/generated-doc/irspecs_md/.',
    allowed: kIrEmitStandards,
  )
  ..addOption(
    'format',
    help: 'export: the format to write the IR in.',
    allowed: kIrExportFormats,
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
    'Usage: dart run tom_specs_clitool:tomspecs :ir-from-codespecs '
    '--shared <dir> --client <dir> --server <dir> --areas <json> '
    '--out <dir>\n'
    '       dart run tom_specs_clitool:tomspecs :ir-map --mapper dart-tom '
    '--ir <dir> --out <dir> [--spec <document> --unit <unit id>]\n'
    '       dart run tom_specs_clitool:tomspecs :ir-emit --standard '
    '<${kIrEmitStandards.join('|')}> --ir <dir> --out <dir> '
    '[--areas <json>] [--spec <document>]\n'
    '       dart run tom_specs_clitool:tomspecs :ir-export --format '
    '<${kIrExportFormats.join('|')}> --ir <dir> --out <dir>\n\n'
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
  if (subcommand == 'export') {
    return _export(results, stdoutSink, stderrSink, usage);
  }
  if (subcommand != 'from-codespecs' && subcommand != 'map') {
    stderrSink.writeln(
      results.rest.isEmpty
          ? 'Name the subcommand: from-codespecs, map, emit or export.'
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

  final index = IrAreaIndex(catalog);
  final documents = irFromCsModel(
    shared: projects[CsLocus.shared]!,
    client: projects[CsLocus.client]!,
    server: projects[CsLocus.server]!,
    areas: index,
  );
  final outDir = Directory(results.option('out')!)..createSync(recursive: true);
  final written = {for (final d in documents) index.fileNameOf(d.area)};
  final writtenAreas = {for (final d in documents) d.area};
  for (final document in documents) {
    final name = index.fileNameOf(document.area);
    final file = File(p.join(outDir.path, name));
    final text = writeIrYaml(document);
    final state = !file.existsSync()
        ? 'new'
        : file.readAsStringSync() == text
        ? 'unchanged'
        : 'changed';
    if (state != 'unchanged') file.writeAsStringSync(text);
    final count = document.files.length;
    stdoutSink.writeln('${name.padRight(34)} $state, $count file(s)');
  }
  for (final stale in outDir.listSync().whereType<File>()) {
    final name = p.basename(stale.path);
    if (name.endsWith('.ir.yaml') && !written.contains(name)) {
      stale.deleteSync();
      final area = irAreaOfFileName(name);
      stdoutSink.writeln(
        area != null && writtenAreas.contains(area)
            ? '${name.padRight(34)} deleted (now ${index.fileNameOf(area)})'
            : '${name.padRight(34)} deleted (no file in the trio)',
      );
    }
  }
  return 0;
}

/// The formats `tomspecs :ir-export --format` writes.
const List<String> kIrExportFormats = ['json'];

Future<int> _export(
  ArgResults results,
  StringSink stdoutSink,
  StringSink stderrSink,
  void Function() usage,
) async {
  final missing = [
    for (final option in ['format', 'ir', 'out'])
      if (results.option(option) == null) '--$option',
  ];
  if (missing.isNotEmpty) {
    stderrSink.writeln('Missing ${missing.join(', ')}.');
    usage();
    return 2;
  }
  final ignored = [
    for (final option in [
      'shared',
      'client',
      'server',
      'mapper',
      'spec',
      'unit',
      'standard',
      'areas',
    ])
      if (results.option(option) != null) '--$option',
  ];
  if (ignored.isNotEmpty) {
    stderrSink.writeln('export takes no ${ignored.join(', ')}.');
    usage();
    return 2;
  }
  final List<({String name, IrDocument document})> files;
  try {
    files = readIrFolderFiles(results.option('ir')!);
  } on IrSpecsException catch (e) {
    stderrSink.writeln(e.message);
    return 2;
  }
  final outDir = Directory(results.option('out')!)..createSync(recursive: true);
  final written = <String>{};
  for (final f in files) {
    final name = irJsonFileName(f.name);
    written.add(name);
    final file = File(p.join(outDir.path, name));
    final text = writeIrJson(f.document);
    final state = !file.existsSync()
        ? 'new'
        : file.readAsStringSync() == text
        ? 'unchanged'
        : 'changed';
    if (state != 'unchanged') file.writeAsStringSync(text);
    stdoutSink.writeln(
      '${name.padRight(34)} $state, ${f.document.files.length} file(s)',
    );
  }
  for (final stale in outDir.listSync().whereType<File>()) {
    final name = p.basename(stale.path);
    if (name.endsWith('.ir.json') && !written.contains(name)) {
      stale.deleteSync();
      stdoutSink.writeln('${name.padRight(34)} deleted (not in the IR)');
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
        kCsharpAspnetServerMapper => mapCsharpAspnet(documents, all: all),
        // A TypeScript package joins the workspace already in --out, so a
        // web and a mobile client unit can share it (irspecs_ir.md §11.2).
        _ => mergeTsWorkspaceRoot(
          mapTypeScript(documents, mapper, all: all),
          switch (File(p.join(results.option('out')!, 'package.json'))) {
            final root when root.existsSync() => root.readAsStringSync(),
            _ => null,
          },
        ),
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

/// The generation unit [unitId] of the specification at [specPath], as the
/// IR mappers take it. Throws [IrSpecsException] when the file cannot be read
/// or decoded, declares no such unit, or the unit is not of a trio locus.
IrUnit _unitOf(String specPath, String unitId) =>
    IrUnit.fromRegister(_registerUnitOf(specPath, unitId));

/// The register entry [unitId] of the specification at [specPath]. Throws
/// [IrSpecsException] when the file cannot be read or decoded, or declares no
/// such unit.
SpecGenerationUnit _registerUnitOf(String specPath, String unitId) {
  final units = _registerUnitsOf(specPath);
  for (final u in units) {
    if (u.unitId == unitId) return u;
  }
  throw IrSpecsException(
    '--unit: $specPath declares no generation unit "$unitId"'
    '${units.isEmpty ? '' : '; it declares ${units.map((u) => u.unitId).join(', ')}'}',
  );
}

/// Every generation unit the specification at [specPath] declares. Throws
/// [IrSpecsException] when the file cannot be read or decoded.
List<SpecGenerationUnit> _registerUnitsOf(String specPath) {
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
  return specGenerationUnits(somSpecModel, document);
}

/// The standards `tomspecs :ir-emit` writes, by `--standard` name
/// (`irspecs_ir.md` §10). The Markdown rendering is written by
/// [emitMarkdown], which needs the area catalogue as well
/// ([kIrEmitStandards] lists every name).
const Map<String, IrEmission Function(List<IrDocument>)> irStandards = {
  'openapi': emitOpenApi,
  'jsonschema': emitJsonSchema,
  'icu': emitIcu,
  'asyncapi': emitAsyncApi,
};

/// The name of the Markdown rendering among the standards.
const String kIrMarkdownStandard = 'markdown';

/// Every name `tomspecs :ir-emit` writes: the standards of [irStandards] and the
/// Markdown rendering (`irspecs_ir.md` §10.3).
const List<String> kIrEmitStandards = [
  'openapi',
  'jsonschema',
  'icu',
  'asyncapi',
  kIrMarkdownStandard,
];

/// The specification's Markdown rendition: [specPath] itself when it is
/// Markdown, else the `.md` beside a `*.docspecs.yaml`; `null` when there is
/// none.
String? _specRenditionFile(String specPath) {
  final String md;
  if (specPath.toLowerCase().endsWith('.md')) {
    md = specPath;
  } else if (specPath.endsWith('.docspecs.yaml')) {
    md =
        '${specPath.substring(0, specPath.length - '.docspecs.yaml'.length)}.md';
  } else {
    return null;
  }
  return File(md).existsSync() ? md : null;
}

int _emit(
  ArgResults results,
  StringSink stdoutSink,
  StringSink stderrSink,
  void Function() usage,
) {
  final standard = results.option('standard');
  final spec = results.option('spec');
  final unitId = results.option('unit');
  final markdownOnly = standard == kIrMarkdownStandard;
  final missing = [
    if (results.option('ir') == null) '--ir',
    if (results.option('out') == null && !(markdownOnly && spec != null))
      '--out',
    if (standard == null && spec == null && unitId == null)
      '--standard (or --spec and --unit)',
  ];
  if (missing.isNotEmpty) {
    stderrSink.writeln('Missing ${missing.join(', ')}.');
    usage();
    return 2;
  }
  if (unitId != null && spec == null) {
    stderrSink.writeln('--unit needs --spec (--spec and --unit go together).');
    usage();
    return 2;
  }
  if (spec != null && unitId == null && standard == null) {
    stderrSink.writeln(
      '--spec goes with --unit (the unit\'s emitters), or with --standard '
      'markdown.',
    );
    usage();
    return 2;
  }
  if (standard != null && unitId != null) {
    stderrSink.writeln(
      'Give --standard, or --spec and --unit (the unit\'s emitters), not both.',
    );
    usage();
    return 2;
  }
  if (standard != null && spec != null && !markdownOnly) {
    stderrSink.writeln(
      '--spec goes with --unit, or with --standard markdown (the units and '
      'the back-link targets).',
    );
    usage();
    return 2;
  }
  final List<IrDocument> documents;
  final List<String> standards;
  var units = const <SpecGenerationUnit>[];
  try {
    if (standard != null) {
      standards = [standard];
    } else {
      final unit = _registerUnitOf(spec!, unitId!);
      final unknown = [
        for (final e in unit.emitters)
          if (!kIrEmitStandards.contains(e)) e,
      ];
      if (unknown.isNotEmpty) {
        throw IrSpecsException(
          'generation unit "${unit.unitId}" names ${unknown.join(', ')}, '
          'which tomspecs :ir-emit does not write (it writes '
          '${kIrEmitStandards.join(', ')})',
        );
      }
      standards = unit.emitters;
      if (standards.isEmpty) {
        stdoutSink.writeln(
          'Generation unit "${unit.unitId}" names no emitter; nothing written.',
        );
        return 0;
      }
    }
    if (standards.contains(kIrMarkdownStandard) && spec != null) {
      units = _registerUnitsOf(spec);
    }
    documents = readIrFolder(results.option('ir')!);
  } on IrSpecsException catch (e) {
    stderrSink.writeln(e.message);
    return 2;
  }
  CodeSpecsAreaCatalog? catalog;
  if (standards.contains(kIrMarkdownStandard)) {
    final areasPath = results.option('areas');
    if (areasPath == null) {
      stderrSink.writeln(
        'markdown needs --areas <codespecs_areas.json>: the area catalogue '
        'names each document (irspecs_ir.md §10.3).',
      );
      usage();
      return 2;
    }
    try {
      catalog = CodeSpecsAreaCatalog.fromJson(
        jsonDecode(File(areasPath).readAsStringSync()) as Map<String, dynamic>,
      );
    } on Object catch (e) {
      stderrSink.writeln('Cannot read the area catalogue: $e');
      return 2;
    }
  }
  final outPath =
      results.option('out') ??
      p.join(p.dirname(spec!), 'generated-doc', 'irspecs_md');
  final outDir = Directory(outPath)..createSync(recursive: true);
  final rendition = spec == null ? null : _specRenditionFile(spec);
  for (final name in standards) {
    if (standards.length > 1) stdoutSink.writeln('$name:');
    final emission = name == kIrMarkdownStandard
        ? emitMarkdown(
            documents,
            catalog: catalog!,
            units: units,
            specRendition: rendition == null
                ? null
                : p.relative(
                    p.absolute(rendition),
                    from: p.absolute(outDir.path),
                  ),
            renditionSectionIds: rendition == null
                ? const {}
                : markdownHeadingSectionIds(File(rendition).readAsStringSync()),
          )
        : irStandards[name]!(documents);
    for (final MapEntry(key: file, value: text) in emission.files.entries) {
      File(p.join(outDir.path, file)).writeAsStringSync(text);
      stdoutSink.writeln('$file written');
    }
    if (emission.notExpressed.isEmpty) {
      stdoutSink.writeln('Every fact the standard reads was expressed.');
    } else {
      stdoutSink.writeln('Not expressed (irspecs_ir.md §10.2):');
      for (final line in emission.notExpressed) {
        stdoutSink.writeln('  - $line');
      }
    }
  }
  return 0;
}

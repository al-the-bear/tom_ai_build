// `spec_checks` — the TomSpecs process checks on any project's specification,
// over the runtime library `package:tom_som_dart_runtime/spec_checks.dart`.
//
// Each subcommand is one check; a project's own data is read from
// `<spec-root>/checks/` (the spec root found from the document, or
// `--spec-root`), never from beside the tool. The output lines are the
// checks' own report formats, and the exit code is 0 when clean, 1 on
// findings, 2 on a usage error.
import 'dart:io';

import 'package:args/args.dart';
import 'package:tom_som_dart_runtime/spec_checks.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_schemas.dart';

import 'validate_spec_cli.dart' show resolveSpecDocumentRoot, specSchemaIdFor;

/// The subcommands, each with its usage line.
const Map<String, String> specChecksCommands = {
  'validate':
      'validate <doc.docspecs.yaml> [<rendition.md>] — decode, schema and '
      'instance tiers; writes the markdown rendition when a path is given',
  'import-answers':
      'import-answers [--dry-run] [--allow-other-edits] <doc.docspecs.yaml> '
      '<rendition.md> — the answers typed into the rendition, into the YAML',
  'accept-marks':
      'accept-marks <doc.docspecs.yaml> [--under <ID>/<ID>] [--write] — every '
      'inline change mark accepted in place',
  'required-fields':
      'required-fields <doc.docspecs.yaml> — required form fields filled, '
      'int / bool / enum values typed',
  'question-register':
      'question-register <doc.docspecs.yaml> <index.md> [--write] — the '
      "question index against the document's question blocks "
      '(checks/question_register.yaml)',
  'feature-register':
      'feature-register <sbp.docspecs.yaml> — every functional requirement '
      'linked by exactly one feature',
  'project-idea-coverage':
      'project-idea-coverage <project_idea.md> <sbp.docspecs.yaml> [--exclusions <yaml>] [--all] — '
      "the requirements' coverage of the Project Idea "
      '(checks/project_idea_coverage.yaml)',
  'authorization':
      'authorization <sbp.docspecs.yaml> — operations, role matrix, screens '
      'and use cases agree (checks/authorization_cross_check.yaml)',
  'coverage':
      'coverage <sample.docspecs.yaml> <sbp.docspecs.yaml> [<old.docspecs.yaml>] '
      '[--tsv <out.tsv>] — how much of the model the document fills '
      '(checks/coverage_rows.yaml, checks/coverage_reasons.yaml)',
};

/// The top-level options; a check's own arguments follow its name and are
/// read by the check.
ArgParser specChecksParser() => ArgParser(allowTrailingOptions: false)
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Print the checks.')
  ..addOption(
    'spec-root',
    valueHelp: 'dir',
    help:
        "The spec root whose checks/ folder holds the project's data; default "
        'found from the document.',
  );

/// Runs `spec_checks` with [arguments] and returns its exit code; output goes
/// to [out] and [err] (default stdout / stderr).
int runSpecChecks(List<String> arguments, {IOSink? out, IOSink? err}) {
  final o = out ?? stdout;
  final e = err ?? stderr;
  final ArgResults top;
  try {
    top = specChecksParser().parse(arguments);
  } on FormatException catch (x) {
    e.writeln('spec_checks: ${x.message}');
    _usage(e);
    return 2;
  }
  final specRoot = top.option('spec-root');
  final args = [...top.rest];
  if (top.flag('help')) {
    _usage(o);
    return 0;
  }
  if (args.isEmpty) {
    _usage(e);
    return 2;
  }
  final command = args.removeAt(0);
  if (!specChecksCommands.containsKey(command)) {
    e.writeln('spec_checks: unknown check `$command`');
    _usage(e);
    return 2;
  }
  try {
    return switch (command) {
      'validate' => _validate(args, o, e),
      'import-answers' => _importAnswers(args, o, e),
      'accept-marks' => _acceptMarks(args, o, e),
      'required-fields' => _requiredFields(args, o, e),
      'question-register' => _questionRegister(args, specRoot, o, e),
      'feature-register' => _featureRegister(args, o, e),
      'project-idea-coverage' => _projectIdeaCoverage(args, specRoot, o, e),
      'authorization' => _authorization(args, specRoot, o, e),
      'coverage' => _coverage(args, specRoot, o, e),
      _ => 2,
    };
  } on _Usage catch (u) {
    e.writeln('usage: spec_checks ${specChecksCommands[command]}');
    if (u.message.isNotEmpty) e.writeln(u.message);
    return 2;
  }
}

void _usage(IOSink sink) {
  sink.writeln(
    'usage: spec_checks [--spec-root <dir>] <check> <arguments>\n'
    "The project's data is read from <spec-root>/checks/; the spec root is\n"
    "found from the document (the nearest folder above it holding checks/,\n"
    "else the document folder's parent) unless --spec-root names it.\n",
  );
  sink.writeln(specChecksParser().usage);
  sink.writeln();
  for (final line in specChecksCommands.values) {
    sink.writeln('  $line');
  }
}

class _Usage implements Exception {
  _Usage([this.message = '']);
  final String message;
}

/// Removes `name <value>` from [args] and returns the value, or null.
String? _option(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i < 0) return null;
  if (i + 1 >= args.length) throw _Usage('$name needs a value');
  final v = args[i + 1];
  args.removeRange(i, i + 2);
  return v;
}

/// Removes the flag [name] from [args] and says whether it was there.
bool _flag(List<String> args, String name) => args.remove(name);

String _read(String path) {
  final f = File(path);
  if (!f.existsSync()) throw _Usage('no such file: $path');
  return f.readAsStringSync();
}

/// The spec root of the document at [documentPath]: [explicit] when given,
/// else the nearest folder above the document holding a `checks/` folder,
/// else the document folder's parent.
String specRootOf(String documentPath, [String? explicit]) {
  if (explicit != null) return explicit;
  var dir = File(documentPath).absolute.parent;
  for (var depth = 0; depth < 4; depth++) {
    if (Directory('${dir.path}/checks').existsSync()) return dir.path;
    if (dir.parent.path == dir.path) break;
    dir = dir.parent;
  }
  return File(documentPath).absolute.parent.parent.path;
}

/// The project data file [name] under the spec root's `checks/`, or null
/// when the project has none.
String? _checkData(String specRoot, String name) {
  final f = File('$specRoot/checks/$name');
  return f.existsSync() ? f.readAsStringSync() : null;
}

/// The model, tree, root type and schema of the document [yamlText].
SpecRootDefinition _definitionOf(String yamlText) {
  final root = resolveSpecDocumentRoot(
    somSpecModel,
    null,
    yamlText,
    isMarkdown: false,
  );
  return SpecRootDefinition(
    model: somSpecModel,
    tree: buildSomMetaTree(somSpecModel, rootType: root.type),
    rootType: root.type,
    schema: somDocSpecsSchema(specSchemaIdFor(root)),
  );
}

void _report(SbpValidation v, IOSink o, IOSink e) {
  for (final line in v.reportLines()) {
    (line.startsWith('SCHEMA') || line.startsWith('INSTANCE') ? e : o).writeln(
      line,
    );
  }
}

int _validate(List<String> args, IOSink o, IOSink e) {
  if (args.isEmpty || args.length > 2) throw _Usage();
  final text = _read(args[0]);
  final SpecRootDefinition type;
  final SpecDocument doc;
  try {
    type = _definitionOf(text);
    doc = type.decode(text);
  } on Exception catch (x) {
    e.writeln('DECODE FAILED: $x');
    return 1;
  } on ArgumentError catch (x) {
    e.writeln('DECODE FAILED: ${x.message}');
    return 1;
  }
  o.writeln('decode    OK');
  final String markdown;
  try {
    markdown = type.render(doc);
  } on SbpRenderException catch (x) {
    e.writeln('RENDER FAILED: $x');
    return 1;
  }
  if (args.length == 2) {
    File(args[1]).writeAsStringSync(markdown);
    o.writeln('rendition ${args[1]}');
  }
  final v = type.validate(doc, markdown: markdown);
  _report(v, o, e);
  return v.isClean ? 0 : 1;
}

int _importAnswers(List<String> args, IOSink o, IOSink e) {
  final dryRun = _flag(args, '--dry-run');
  final allowOther = _flag(args, '--allow-other-edits');
  if (args.length != 2 || args.any((a) => a.startsWith('-'))) throw _Usage();
  final yamlPath = args[0], markdownPath = args[1];
  final yamlText = _read(yamlPath);
  final markdown = _read(markdownPath);
  final AnswerImporter importer;
  try {
    importer = AnswerImporter.forYaml(
      _definitionOf(yamlText),
      yamlText,
      allowOtherEdits: allowOther,
    );
  } on SbpRenderException catch (x) {
    o.writeln('decode    OK');
    e.writeln('RENDER FAILED: $x');
    return 1;
  } on Exception catch (x) {
    e.writeln('DECODE FAILED: $x');
    return 1;
  } on ArgumentError catch (x) {
    e.writeln('DECODE FAILED: ${x.message}');
    return 1;
  }
  o.writeln('decode    OK');
  final ImportPlan plan;
  try {
    plan = importer.plan(markdown);
  } on ImportVerificationException catch (x) {
    e.writeln('VERIFY    $x — nothing written');
    return 1;
  } on YamlRewriteException catch (x) {
    e.writeln('VERIFY    $x — nothing written');
    return 1;
  }
  for (final r in plan.rejections) {
    e.writeln('REJECTED  $r');
  }
  for (final reason in plan.refusals) {
    e.writeln('REFUSED   $reason');
  }
  for (final a in plan.answers) {
    o.writeln(a.reportLine);
  }
  for (final v in plan.values) {
    o.writeln(v.reportLine);
  }
  if (plan.isRefused) return 2;
  o.writeln(
    'import    ${plan.answers.length} answer(s), '
    '${plan.values.length} other value(s)',
  );
  final doc = plan.newDocument ?? importer.document;
  final validation = importer.type.validate(
    doc,
    markdown: plan.hasChanges ? null : importer.rendition,
  );
  if (dryRun) {
    o.writeln('dry run   nothing written');
  } else {
    if (plan.hasChanges) {
      final file = File(yamlPath)..writeAsStringSync(plan.newYaml!);
      if (file.readAsStringSync() != plan.newYaml) {
        file.writeAsStringSync(yamlText);
        e.writeln(
          'VERIFY    $yamlPath did not read back as written — restored',
        );
        return 1;
      }
      o.writeln('written   $yamlPath');
    }
    File(markdownPath).writeAsStringSync(validation.markdown);
    o.writeln('rendition $markdownPath');
  }
  _report(validation, o, e);
  return validation.isClean ? 0 : 1;
}

int _acceptMarks(List<String> args, IOSink o, IOSink e) {
  final under = _option(args, '--under');
  final write = _flag(args, '--write');
  if (args.length != 1) throw _Usage();
  final text = _read(args[0]);
  final MarksInPlaceResult r;
  try {
    r = acceptMarksInPlace(text, _definitionOf(text).tree, under: under);
  } on MarksSectionNotFound catch (x) {
    e.writeln('$x');
    return 2;
  }
  o.writeln('runtime: applied ${r.applied}, malformed ${r.malformed}');
  if (r.sectionLines != null) {
    o.writeln('section $under: lines ${r.sectionLines}');
  }
  o.writeln('block scalars rewritten: ${r.changedValues}');
  for (final d in r.differences) {
    o.writeln(d);
  }
  o.writeln('value differences vs runtime: ${r.differenceCount}');
  o.writeln('marks left: ${r.marksLeft}');
  if (write && r.verified) {
    File(args[0]).writeAsStringSync(r.text);
    o.writeln('written');
  }
  return r.verified ? 0 : 1;
}

int _requiredFields(List<String> args, IOSink o, IOSink e) {
  if (args.length != 1) throw _Usage();
  final r = checkRequiredFields(_read(args[0]), somSpecModelJson);
  for (final m in r.missing) {
    o.writeln('MISSING   $m');
  }
  for (final m in r.badTypes) {
    o.writeln('TYPE      $m');
  }
  o.writeln(
    'forms checked ${r.forms} missing ${r.missing.length} bad types ${r.badTypes.length}',
  );
  return r.missing.isEmpty && r.badTypes.isEmpty ? 0 : 1;
}

int _questionRegister(List<String> args, String? specRoot, IOSink o, IOSink e) {
  final write = _flag(args, '--write');
  if (args.length != 2) throw _Usage();
  final data = _checkData(
    specRootOf(args[0], specRoot),
    'question_register.yaml',
  );
  final file = File(args[1]);
  final index = _read(args[1]);
  final report = checkQuestionRegister(
    _read(args[0]),
    index,
    config: data == null
        ? QuestionRegisterConfig.defaults
        : QuestionRegisterConfig.parse(data),
  );
  var findings = report.findings;
  if (write && report.rewritten != index) {
    file.writeAsStringSync(report.rewritten);
    findings = findings
        .where((f) => !f.startsWith('the status counts'))
        .toList();
    o.writeln('counts    rewritten');
  }
  for (final f in findings) {
    o.writeln('REGISTER  $f');
  }
  if (report.answeredNotApplied.isNotEmpty) {
    o.writeln(
      'answered in the Blueprint, not yet applied: ${report.answeredNotApplied.join(', ')}',
    );
  }
  o.writeln(
    'register  ${report.rows} index rows, ${report.blocks} blocks in the Blueprint, '
    '${report.waiting} waiting (${report.waitingStarred} ★) — ${findings.length} finding(s)',
  );
  return findings.isEmpty ? 0 : 1;
}

int _featureRegister(List<String> args, IOSink o, IOSink e) {
  if (args.length != 1) throw _Usage();
  final report = checkFeatureRegister(_read(args[0]));
  for (final finding in report.findings) {
    o.writeln('FEATURES  $finding');
  }
  o.writeln(
    'features  ${report.features} features, '
    '${report.functionalRequirements} functional requirements, '
    '${report.prototypeFeatures} prototype features — '
    '${report.findings.length} finding(s)',
  );
  return report.findings.isEmpty ? 0 : 1;
}

int _projectIdeaCoverage(
  List<String> args,
  String? specRoot,
  IOSink o,
  IOSink e,
) {
  final all = _flag(args, '--all');
  final exclusionsPath = _option(args, '--exclusions');
  if (args.length != 2) throw _Usage();
  final idea = parseProjectIdea(_read(args[0]));
  final sources = requirementSources(_read(args[1]));
  final data = exclusionsPath != null
      ? _read(exclusionsPath)
      : _checkData(specRootOf(args[1], specRoot), 'project_idea_coverage.yaml');
  final exclusions = data == null
      ? <CoverageExclusion>[]
      : parseExclusions(data);
  final report = measureProjectIdeaCoverage(
    idea,
    sources,
    exclusions: exclusions,
  );
  for (final entry in report.entries) {
    if (!all && entry.cls == CoverageClass.covered) continue;
    o.writeln(
      '${entry.cls.name.padRight(9)} ${entry.item.id.padRight(6)} '
      '${entry.item.kind.padRight(11)} ${entry.detail}',
    );
  }
  for (final id in report.unknownExclusions) {
    o.writeln('UNKNOWN   $id — in the exclusion list, not in the Project Idea');
  }
  final kinds = <String, int>{};
  for (final i in idea.items) {
    kinds[i.kind] = (kinds[i.kind] ?? 0) + 1;
  }
  o.writeln(
    'ids       ${idea.items.length} '
    '(${kinds.entries.map((k) => '${k.value} ${k.key}').join(', ')}); '
    '${report.requirements} requirements read',
  );
  o.writeln(
    'coverage  ${[for (final c in CoverageClass.values) '${c.name} ${report.of(c).length}'].join(', ')}',
  );
  return report.of(CoverageClass.uncovered).isEmpty &&
          report.unknownExclusions.isEmpty
      ? 0
      : 1;
}

int _authorization(List<String> args, String? specRoot, IOSink o, IOSink e) {
  if (args.length != 1) throw _Usage();
  final root = specRootOf(args[0], specRoot);
  final config = _checkData(root, 'authorization_cross_check.yaml');
  if (config == null) {
    throw _Usage(
      'the role model is the project\'s: $root/checks/authorization_cross_check.yaml',
    );
  }
  final report = crossCheckAuthorization(_read(args[0]), config);
  for (final check in CrossCheckReport.checks) {
    final list = report.findings[check]!;
    o.writeln('## $check: ${list.length} finding(s)');
    for (final m in list) {
      o.writeln('  - $m');
    }
  }
  o.writeln(
    '## C use cases — steps performed by another actor than the '
    'primary one (consistent): ${report.otherActor.length}',
  );
  for (final m in report.otherActor) {
    o.writeln('  - $m');
  }
  o.writeln(
    '## C use cases — steps whose actor waits for an open question '
    '(stated in the step): ${report.pending.length}',
  );
  for (final m in report.pending) {
    o.writeln('  - $m');
  }
  o.writeln(
    'SUMMARY ${{for (final c in CrossCheckReport.checks) c: report.findings[c]!.length}} '
    'operations ${report.operations} screens ${report.screens} use cases ${report.useCases}',
  );
  return report.total == 0 ? 0 : 1;
}

int _coverage(List<String> args, String? specRoot, IOSink o, IOSink e) {
  final tsv = _option(args, '--tsv');
  if (args.length < 2 || args.length > 3) throw _Usage();
  final root = specRootOf(args[1], specRoot);
  final rows = _checkData(root, 'coverage_rows.yaml');
  final reasons = _checkData(root, 'coverage_reasons.yaml');
  if (rows == null || reasons == null) {
    throw _Usage(
      "the rows and reasons are the project's: $root/checks/coverage_rows.yaml "
      'and coverage_reasons.yaml',
    );
  }
  final report = measureCoverage(
    sampleYaml: _read(args[0]),
    metaJson: somSpecModelJson,
    blueprintYaml: _read(args[1]),
    oldBlueprintYaml: args.length == 3 ? _read(args[2]) : null,
    rowsYaml: rows,
    reasonsYaml: reasons,
  );
  o.write(report.render());
  if (tsv != null) File(tsv).writeAsStringSync(report.renderTsv());
  return 0;
}

// The `tomspecs :spec-*` commands — the TomSpecs process checks on any
// project's specification, over the runtime library
// `package:tom_som_dart_runtime/spec_checks.dart`.
//
// Each command is one check, called here by its check id; a project's own data is read from
// `<spec-root>/checks/` (the spec root found from the document, or
// `--spec-root`), never from beside the tool. The output lines are the
// checks' own report formats, and the exit code is 0 when clean, 1 on
// findings, 2 on a usage error.
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:tom_som_dart_runtime/spec_checks.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_schemas.dart';

import 'validate_spec_cli.dart' show resolveSpecDocumentRoot, specSchemaIdFor;

/// The `tomspecs` command each check id runs as.
const Map<String, String> specCheckCommandNames = {
  'validate': 'spec-render',
  'render': 'spec-readable',
  'import-answers': 'spec-import-answers',
  'accept-marks': 'spec-accept-marks',
  'required-fields': 'spec-required-fields',
  'question-register': 'spec-question-register',
  'feature-register': 'spec-feature-register',
  'project-idea-coverage': 'spec-idea-coverage',
  'authorization': 'spec-authorization',
  'coverage': 'spec-coverage',
  'fill-frem': 'spec-fill-frem',
};

/// [specChecksCommands]' usage line of [check], with the check id replaced by
/// its `tomspecs` command.
String specCheckUsage(String check) {
  final line = specChecksCommands[check]!;
  return 'tomspecs :${specCheckCommandNames[check]}'
      '${line.substring(check.length)}';
}

/// The checks by id, each with its usage line.
const Map<String, String> specChecksCommands = {
  'validate':
      'validate <doc.tomspecs.yaml> [<rendition.tomspecs.md>] — decode, schema and '
      'instance tiers; writes the markdown rendition when a path is given',
  'render':
      'render <doc.tomspecs.yaml> [<out.readable.md>] [-drop:<names>] '
      '[-unmark:<names>] [-appendix:<names>] [--appendix-references] '
      '[--heading-divs] | --merge-onto <doc.tomspecs.yaml> '
      '<edited.readable.md> [--base <file>] [switches] [--write] — a readable '
      'rendition (to the path or stdout), or the merge of an edited one back '
      'onto the document (a dry run without --write)',
  'import-answers':
      'import-answers [--dry-run] [--allow-other-edits] <doc.tomspecs.yaml> '
      '<rendition.tomspecs.md> — the answers typed into the rendition, into the YAML',
  'accept-marks':
      'accept-marks <doc.tomspecs.yaml> [--under <ID>/<ID>] [--write] — every '
      'inline change mark accepted in place',
  'required-fields':
      'required-fields <doc.tomspecs.yaml> — required form fields filled, '
      'int / bool / enum values typed',
  'question-register':
      'question-register <doc.tomspecs.yaml> <index.md> [--write] — the '
      "question index against the document's question blocks "
      '(checks/question_register.yaml)',
  'feature-register':
      'feature-register <sbp.tomspecs.yaml> — every functional requirement '
      'linked by exactly one feature',
  'project-idea-coverage':
      'project-idea-coverage <project_idea.md> <sbp.tomspecs.yaml> [--exclusions <yaml>] [--all] — '
      "the requirements' coverage of the Project Idea "
      '(checks/project_idea_coverage.yaml)',
  'authorization':
      'authorization <sbp.tomspecs.yaml> — operations, role matrix, screens '
      'and use cases agree (checks/authorization_cross_check.yaml)',
  'coverage':
      'coverage <sample.tomspecs.yaml> <sbp.tomspecs.yaml> [<old.tomspecs.yaml>] '
      '[--tsv <out.tsv>] — how much of the model the document fills '
      '(checks/coverage_rows.yaml, checks/coverage_reasons.yaml)',
  'fill-frem':
      'fill-frem <doc.tomspecs.yaml> [--dry-run] [--rendition <doc.tomspecs.md>] '
      "— every functional requirement's FREM (version, date, author) from the "
      'document revision of the git revision that last changed it',
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

/// Runs the check whose id [arguments] start with and returns its exit code;
/// output goes
/// to [out] and [err] (default stdout / stderr).
int runSpecChecks(List<String> arguments, {IOSink? out, IOSink? err}) {
  final o = out ?? stdout;
  final e = err ?? stderr;
  final ArgResults top;
  try {
    top = specChecksParser().parse(arguments);
  } on FormatException catch (x) {
    e.writeln('tomspecs: ${x.message}');
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
    e.writeln('tomspecs: unknown check `$command`');
    _usage(e);
    return 2;
  }
  try {
    return switch (command) {
      'validate' => _validate(args, o, e),
      'render' => _render(args, o, e),
      'import-answers' => _importAnswers(args, o, e),
      'accept-marks' => _acceptMarks(args, o, e),
      'required-fields' => _requiredFields(args, o, e),
      'question-register' => _questionRegister(args, specRoot, o, e),
      'feature-register' => _featureRegister(args, o, e),
      'project-idea-coverage' => _projectIdeaCoverage(args, specRoot, o, e),
      'authorization' => _authorization(args, specRoot, o, e),
      'coverage' => _coverage(args, specRoot, o, e),
      'fill-frem' => _fillFrem(args, o, e),
      _ => 2,
    };
  } on _Usage catch (u) {
    e.writeln('usage: ${specCheckUsage(command)}');
    if (u.message.isNotEmpty) e.writeln(u.message);
    return 2;
  }
}

void _usage(IOSink sink) {
  sink.writeln(
    'usage: tomspecs :spec-<check> [--spec-root <dir>] <arguments>\n'
    "The project's data is read from <spec-root>/checks/; the spec root is\n"
    "found from the document (the nearest folder above it holding checks/,\n"
    "else the document folder's parent) unless --spec-root names it.\n",
  );
  sink.writeln(specChecksParser().usage);
  sink.writeln();
  for (final check in specChecksCommands.keys) {
    sink.writeln('  ${specCheckUsage(check)}');
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

// --- render ------------------------------------------------------------------

/// The `render` check: the readable rendition of a document, or, with
/// `--merge-onto`, the merge of an edited one back onto it (SOM §11.10).
int _render(List<String> args, IOSink o, IOSink e) {
  final mergeOnto = _option(args, '--merge-onto');
  final base = _option(args, '--base');
  final write = _flag(args, '--write');
  final headingDivs = _flag(args, '--heading-divs');
  final appendixReferences = _flag(args, '--appendix-references');
  final drop = _kindSwitch(args, 'drop');
  final unmark = _kindSwitch(args, 'unmark');
  final appendix = _kindSwitch(args, 'appendix');
  for (final a in args) {
    if (a.startsWith('-')) throw _Usage('unknown switch `$a`');
  }
  SpecStripOptions? options;
  if (drop != null ||
      unmark != null ||
      appendix != null ||
      headingDivs ||
      appendixReferences) {
    try {
      options = SpecStripOptions.fromNames(
        drop: drop ?? const [],
        unmark: unmark ?? const [],
        appendix: appendix ?? const [],
        appendixReferences: appendixReferences,
        headingDivs: headingDivs,
      );
    } on SpecStripUsageError catch (x) {
      throw _Usage(x.message);
    }
  }
  if (mergeOnto != null) {
    if (args.length != 1) {
      throw _Usage('--merge-onto takes the document and one edited rendition');
    }
    return _renderMerge(mergeOnto, args.single, base, options, write, o, e);
  }
  if (base != null) throw _Usage('--base belongs to --merge-onto');
  if (write) throw _Usage('--write belongs to --merge-onto');
  if (args.isEmpty || args.length > 2) throw _Usage();
  return _renderReadable(
    args[0],
    args.length == 2 ? args[1] : null,
    options ?? const SpecStripOptions(),
    o,
    e,
  );
}

/// Removes every `-<name>:<names>`, `--<name>=<names>` and
/// `--<name> <names>` from [args] and returns the names given, or null when
/// the switch is not there.
List<String>? _kindSwitch(List<String> args, String name) {
  List<String>? found;
  for (var i = 0; i < args.length;) {
    final a = args[i];
    String? value;
    var take = 1;
    if (a.startsWith('-$name:')) {
      value = a.substring(name.length + 2);
    } else if (a.startsWith('--$name=')) {
      value = a.substring(name.length + 3);
    } else if (a == '--$name') {
      if (i + 1 >= args.length) throw _Usage('--$name needs kind names');
      value = args[i + 1];
      take = 2;
    }
    if (value == null) {
      i++;
      continue;
    }
    if (value.trim().isEmpty) throw _Usage('-$name: needs kind names');
    (found ??= []).add(value);
    args.removeRange(i, i + take);
  }
  return found;
}

/// The rendition `<doc>.tomspecs.md` beside [yamlPath], or null when the
/// document is not named `<doc>.tomspecs.yaml`.
String? _ownRendition(String yamlPath) {
  const suffix = '.tomspecs.yaml';
  if (!yamlPath.endsWith(suffix)) return null;
  return '${yamlPath.substring(0, yamlPath.length - suffix.length)}'
      '.tomspecs.md';
}

/// The revision of a document's text: the content hash the spec tools pass
/// as `expectedRevision` (sha256 of its UTF-8 bytes, hex).
String specDocumentRevision(String text) =>
    sha256.convert(utf8.encode(text)).toString();

/// The source of the document at [path] for a readable header: its name,
/// the revision of [text], and the commit that last changed it (`+dirty`
/// when the file differs from it), when it is in a git repository.
SpecReadableSource _readableSource(String path, String text) {
  final file = File(path).absolute;
  String? commit;
  var dirty = false;
  try {
    final log = Process.runSync('git', [
      'log',
      '-1',
      '--format=%H',
      '--',
      p.basename(file.path),
    ], workingDirectory: file.parent.path);
    final sha = '${log.stdout}'.trim();
    if (log.exitCode == 0 &&
        sha.length == 40 &&
        RegExp(r'^[0-9a-f]+').stringMatch(sha) == sha) {
      commit = sha;
      final status = Process.runSync('git', [
        'status',
        '--porcelain',
        '--',
        p.basename(file.path),
      ], workingDirectory: file.parent.path);
      dirty = status.exitCode != 0 || '${status.stdout}'.trim().isNotEmpty;
    }
  } on ProcessException {
    commit = null;
  }
  return SpecReadableSource(
    file: p.basename(path),
    revision: specDocumentRevision(text),
    commit: commit,
    dirty: dirty,
  );
}

int _renderReadable(
  String yamlPath,
  String? outPath,
  SpecStripOptions options,
  IOSink o,
  IOSink e,
) {
  if (outPath != null) {
    final out = p.normalize(File(outPath).absolute.path);
    final own = _ownRendition(yamlPath);
    if (out == p.normalize(File(yamlPath).absolute.path)) {
      throw _Usage('the rendition would overwrite the document itself');
    }
    if (own != null && out == p.normalize(File(own).absolute.path)) {
      throw _Usage(
        "the rendition would overwrite the document's own rendition $own; "
        'name a <doc>.readable.md',
      );
    }
  }
  final text = _read(yamlPath);
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
  final strip = SpecDocumentStrip.strip(
    doc,
    options,
    model: type.model,
    schema: type.schema,
    rootType: type.rootType,
    source: _readableSource(yamlPath, text),
  );
  // Without an output file the rendition is stdout, so the report goes to
  // stderr.
  final report = outPath == null ? e : o;
  final readable = strip.readable;
  if (readable == null) {
    for (final f in strip.findings) {
      e.writeln('FINDING   $f');
    }
    e.writeln('RENDER FAILED: no rendition — nothing written');
    return 1;
  }
  if (outPath == null) {
    o.write(readable);
  } else {
    File(outPath).writeAsStringSync(readable);
  }
  report.writeln(strip.readableHeader);
  for (final line in strip.report) {
    report.writeln('stripped  $line');
  }
  for (final f in strip.findings) {
    e.writeln('FINDING   $f');
  }
  report.writeln(
    'readable  ${outPath ?? 'stdout'} — ${strip.values.length} value(s) '
    'changed, ${strip.kept.length} kept, ${strip.findings.length} finding(s)',
  );
  return strip.ok ? 0 : 1;
}

int _renderMerge(
  String yamlPath,
  String editedPath,
  String? basePath,
  SpecStripOptions? options,
  bool write,
  IOSink o,
  IOSink e,
) {
  final text = _read(yamlPath);
  final edited = _read(editedPath);
  final baseText = basePath == null ? null : _read(basePath);
  final SpecRootDefinition type;
  final SpecYamlContents decoded;
  SpecDocument? base;
  try {
    type = _definitionOf(text);
    decoded = SpecDocumentYaml.decode(text, type.tree);
    if (baseText != null) base = type.decode(baseText);
  } on Exception catch (x) {
    e.writeln('DECODE FAILED: $x');
    return 1;
  } on ArgumentError catch (x) {
    e.writeln('DECODE FAILED: ${x.message}');
    return 1;
  }
  final SpecStripMergeResult result;
  try {
    result = SpecStripMerge.merge(
      decoded.document,
      edited,
      model: type.model,
      schema: type.schema,
      rootType: type.rootType,
      options: options,
      currentRevision: specDocumentRevision(text),
      base: base,
      loadBase: (source) {
        final commit = source.commit;
        if (commit == null) return null;
        final then = SpecStripMerge.gitShowFile(commit, yamlPath);
        if (then == null) return null;
        try {
          return type.decode(then);
        } on Exception {
          return null;
        } on ArgumentError {
          return null;
        }
      },
    );
  } on SpecStripUsageError catch (x) {
    throw _Usage(x.message);
  }
  for (final line in result.report) {
    (line.startsWith('MERGED') || line.startsWith('PLACED') ? o : e).writeln(
      line,
    );
  }
  final placed = result.merged.fold<int>(0, (n, m) => n + m.placed.length);
  o.writeln(
    'merge     ${result.merged.length} value(s), $placed placed, '
    '${result.conflicts.length} conflict(s), ${result.refusals.length} '
    'refusal(s)${result.stale ? ' — three-way, the original moved since '
              'the export' : ''}',
  );
  final merged = result.document;
  if (!result.ok || merged == null) {
    o.writeln('merge     nothing written');
    return 1;
  }
  if (result.merged.isEmpty) {
    o.writeln('merge     nothing to merge');
    return 0;
  }
  final MergedYaml newYaml;
  try {
    newYaml = mergedYaml(text, type.tree, decoded, merged, result.merged);
  } on MergedYamlVerificationException catch (x) {
    e.writeln('VERIFY    $x — nothing written');
    return 1;
  }
  o.writeln(
    'yaml      ${newYaml.inPlace ? '${result.merged.length} block scalar(s) '
              'rewritten in place' : 're-encoded (${newYaml.reason})'}',
  );
  if (!write) {
    o.writeln('dry run   nothing written');
    return 0;
  }
  // The staged write: a sibling file, read back, then renamed over the
  // document, so the document is never half written.
  final stage = File('$yamlPath.render.stage')..writeAsStringSync(newYaml.text);
  if (stage.readAsStringSync() != newYaml.text) {
    stage.deleteSync();
    e.writeln('VERIFY    the staged file did not read back — nothing written');
    return 1;
  }
  stage.renameSync(yamlPath);
  o.writeln('written   $yamlPath');
  final rendition = _ownRendition(yamlPath);
  if (rendition != null) {
    final String markdown;
    try {
      markdown = type.render(type.decode(newYaml.text));
    } on SbpRenderException catch (x) {
      e.writeln('RENDER FAILED: $x');
      return 1;
    }
    File(rendition).writeAsStringSync(markdown);
    o.writeln('rendition $rendition');
  }
  return 0;
}

/// The YAML text a merge writes, and how it was made.
class MergedYaml {
  /// [text], rewritten in place when [inPlace], else re-encoded for
  /// [reason].
  const MergedYaml(this.text, {required this.inPlace, this.reason});

  /// The document's new YAML text.
  final String text;

  /// Whether only the merged values' block scalars changed.
  final bool inPlace;

  /// Why the document had to be re-encoded, when it was.
  final String? reason;
}

/// Thrown when the written YAML does not decode to the merged document.
class MergedYamlVerificationException implements Exception {
  /// The failure, with [message].
  MergedYamlVerificationException(this.message);

  /// What differs.
  final String message;

  @override
  String toString() => message;
}

/// The YAML of [merged]: [yamlText] with the block scalar of each value in
/// [values] rewritten in place (only those lines change), or, when one of
/// them has no block scalar in the encoder's shape (a value the reader
/// filled in, an older layout), the whole document re-encoded with the
/// model version and review of [decoded]. Either way the text is decoded
/// again and must give [merged], else [MergedYamlVerificationException].
MergedYaml mergedYaml(
  String yamlText,
  SomMetaTree tree,
  SpecYamlContents decoded,
  SpecDocument merged,
  List<SpecStripMergedValue> values,
) {
  String? reason;
  String? text;
  try {
    final located = locateAllValues(yamlText, tree);
    final edits = <ValueEdit>[];
    for (final v in values) {
      final ref = v.ref;
      final field = ref.field;
      final ValueLocation? location;
      if (ref.headline) {
        location = located.headlines[ref.path];
      } else if (field != null) {
        location = (located.formFields[ref.path] ?? const {})[field];
      } else {
        location = located.content[ref.path];
      }
      if (location == null) {
        throw YamlRewriteException(
          ref.label,
          'the document holds no such value yet',
        );
      }
      edits.add(ValueEdit(location, v.text));
    }
    text = rewriteValues(yamlText, edits);
  } on YamlRewriteException catch (x) {
    reason = x.toString();
  } on SpecYamlFormatException catch (x) {
    reason = x.toString();
  }
  text ??= SpecDocumentYaml.encode(
    document: merged,
    tree: tree,
    modelVersion: decoded.modelVersion,
    review: decoded.review,
  );
  final again = SpecDocumentYaml.decode(text, tree);
  if (jsonEncode(again.document.toJson()) != jsonEncode(merged.toJson())) {
    throw MergedYamlVerificationException(
      'the written YAML does not decode to the merged document',
    );
  }
  return MergedYaml(text, inPlace: reason == null, reason: reason);
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

/// The versions of the document at [path] in git, oldest first, with the
/// working tree last when it differs from the last commit; null when the file
/// is not under git.
List<FremHistoryVersion>? fremGitHistory(String path) {
  final file = File(path).absolute;
  final dir = file.parent.path;
  final name = file.uri.pathSegments.last;
  ProcessResult git(List<String> a, {String? cwd}) =>
      Process.runSync('git', a, workingDirectory: cwd ?? dir);
  final top = git(['rev-parse', '--show-toplevel']);
  if (top.exitCode != 0) return null;
  final topDir = '${top.stdout}'.trim();
  final log = git([
    'log',
    '--follow',
    '--format=%x01%H',
    '--name-only',
    '--',
    name,
  ]);
  if (log.exitCode != 0) return null;
  final commits = <(String, String)>[];
  for (final block in '${log.stdout}'.split('\x01').skip(1)) {
    final lines = block
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length < 2) continue;
    commits.add((lines.first, lines.last));
  }
  if (commits.isEmpty) return null;
  final versions = <FremHistoryVersion>[];
  for (final (hash, repoPath) in commits.reversed) {
    final show = git(['show', '$hash:$repoPath'], cwd: topDir);
    if (show.exitCode != 0) continue;
    versions.add(FremHistoryVersion(hash, '${show.stdout}'));
  }
  final current = file.readAsStringSync();
  if (versions.isEmpty || versions.last.text != current) {
    versions.add(FremHistoryVersion('working tree', current));
  }
  return versions;
}

int _fillFrem(List<String> args, IOSink o, IOSink e) {
  final dryRun = _flag(args, '--dry-run');
  final rendition = _option(args, '--rendition');
  if (args.length != 1 || args.first.startsWith('-')) throw _Usage();
  final path = args.first;
  final text = _read(path);
  final history = fremGitHistory(path);
  if (history == null) {
    throw _Usage('$path is not a committed file of a git repository');
  }
  final SpecRootDefinition type;
  final FremFillPlan plan;
  try {
    type = _definitionOf(text);
    plan = planFremFill(history, type.tree);
  } on FremFillVerificationException catch (x) {
    e.writeln('VERIFY    $x — nothing written');
    return 1;
  } on Exception catch (x) {
    e.writeln('DECODE FAILED: $x');
    return 1;
  } on ArgumentError catch (x) {
    e.writeln('DECODE FAILED: ${x.message}');
    return 1;
  }
  for (final f in plan.fills) {
    o.writeln(f.reportLine);
  }
  for (final finding in plan.findings) {
    o.writeln(finding);
  }
  o.writeln(
    'fill-frem ${history.length} version(s), ${plan.fills.length} '
    'requirement(s), ${plan.changed.length} to change'
    '${plan.newText == null
        ? ''
        : plan.inPlace
        ? ' (in place)'
        : ' (re-encoded)'}'
    ' — ${plan.findings.length} finding(s)',
  );
  final newText = plan.newText;
  if (newText != null) {
    if (dryRun) {
      o.writeln('dry run   nothing written');
    } else {
      // The staged write: a sibling file, read back, then renamed over the
      // document, so the document is never half written.
      final stage = File('$path.fill-frem.stage')..writeAsStringSync(newText);
      if (stage.readAsStringSync() != newText) {
        stage.deleteSync();
        e.writeln(
          'VERIFY    the staged file did not read back — nothing written',
        );
        return 1;
      }
      stage.renameSync(path);
      o.writeln('written   $path');
      if (rendition != null) {
        final doc = type.decode(newText);
        File(rendition).writeAsStringSync(type.render(doc));
        o.writeln('rendition $rendition');
      }
    }
  }
  return plan.findings.isEmpty ? 0 : 1;
}

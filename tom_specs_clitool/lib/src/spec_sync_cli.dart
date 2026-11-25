/// The `tomspecs :spec-sync-report`, `:spec-backfill`, `:spec-prefill`,
/// `:spec-derive-fields` and `:spec-rename-id` commands: the document-set
/// validation and the operations over a project's specification documents
/// (`tom_specs_model_rules.md` §9.7, the runtime's `SpecDocumentSet`).
///
/// The documents of a set are given as files, `*.tomspecs.yaml` or SOM
/// Markdown; files of one root are fragments of one document and are
/// assembled. A document assembled from fragments, or read from Markdown, is
/// never written.
///
/// **A write never shows an intermediate state.** The new state of a
/// document is staged first: its YAML written to a temporary file and renamed
/// when complete, its Markdown rendition rendered beside it — in
/// `--stage-folder` when given, else beside the document of record. Only when
/// the stage is complete is it copied over the document of record and its
/// rendition (`<stem>.tomspecs.md` beside the YAML), each through a temporary
/// file and a rename.
///
/// Exit codes: `0` clean or nothing to write, `1` findings, `2` a usage error
/// or a refused set. `--json` prints the operation result's `toJson()` (a
/// refusal as `{"refused": …}`).
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';

class _UsageError implements Exception {
  const _UsageError(this.message);
  final String message;
}

/// A refusal: printed, exit 2.
class _Refused implements Exception {
  const _Refused(this.json, this.message);
  final Map<String, Object?> json;
  final String message;
}

/// Called between staging a write and copying it over the document of
/// record, with the staged YAML's path; tests read the document of record
/// there. Null in normal runs.
typedef SpecStageHook = void Function(String stagedYaml, String record);

// ---------------------------------------------------------------------------
// The option sets — read by the README correspondence test.
// ---------------------------------------------------------------------------

void _common(ArgParser p, {bool pairs = true, bool dryRun = true}) {
  if (pairs) {
    p.addOption(
      'pairs',
      help: 'Only these pairs, by section id (FR,OR,…).',
      valueHelp: 'ids',
    );
  }
  if (dryRun) {
    p.addFlag(
      'dry-run',
      help: 'Show what would be written, write nothing.',
      negatable: false,
    );
  }
  p
    ..addFlag(
      'json',
      help: "Print the operation result's toJson() on stdout.",
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show usage information.',
      negatable: false,
    );
}

void _stage(ArgParser p) => p.addOption(
  'stage-folder',
  help:
      'Stage the new document and its rendition in this folder before it '
      'is copied over the document of record (the step folder).',
  valueHelp: 'dir',
);

/// `:spec-sync-report` `<file>… [--pairs] [--json]`.
ArgParser specSyncReportParser() =>
    ArgParser()..also((p) => _common(p, dryRun: false));

/// `:spec-backfill` `<file>… [--pairs] [--path] [--stage-folder]`
/// `[--dry-run] [--json]`.
ArgParser specBackfillParser() => ArgParser()
  ..addOption(
    'path',
    help: 'Only the findings at or below this Blueprint path.',
    valueHelp: 'path',
  )
  ..also(_stage)
  ..also(_common);

/// `:spec-prefill` `<file>… --root [--target] [--pairs] [--stage-folder]`
/// `[--dry-run] [--json]`.
ArgParser specPrefillParser() => ArgParser()
  ..addOption(
    'root',
    help: 'The Phase 3 root to fill, a type name or section id (RSP).',
    valueHelp: 'root',
  )
  ..addOption(
    'target',
    help:
        "The document's file (*.tomspecs.yaml), created when missing; "
        'default the set\'s document of the root.',
    valueHelp: 'file',
  )
  ..also(_stage)
  ..also(_common);

/// `:spec-derive-fields` `<file> [--unmarked] [--author] [--at]`
/// `[--stage-folder] [--dry-run] [--json]`.
ArgParser specDeriveFieldsParser() => ArgParser()
  ..addFlag(
    'unmarked',
    help: 'Write plain values instead of review marks (a new document).',
    negatable: false,
  )
  ..addOption(
    'author',
    help: 'The review member the marks are attributed to.',
    valueHelp: 'id',
  )
  ..addOption(
    'at',
    help: 'The change time the marks record (2026-11-07T14:05+01:00).',
    valueHelp: 'time',
  )
  ..also(_stage)
  ..also((p) => _common(p, pairs: false));

/// `:spec-rename-id` `<file>… --from --to [--dry-run] [--json]`.
ArgParser specRenameIdParser() => ArgParser()
  ..addOption('from', help: 'The section id to rename.', valueHelp: 'id')
  ..addOption('to', help: 'Its new id.', valueHelp: 'id')
  ..also((p) => _common(p, pairs: false));

extension on ArgParser {
  void also(void Function(ArgParser) f) => f(this);
}

// ---------------------------------------------------------------------------
// The commands
// ---------------------------------------------------------------------------

/// `:spec-sync-report`: the document-set validation; writes nothing.
Future<int> runSpecSyncReport(
  List<String> arguments, {
  StringSink? out,
  StringSink? err,
}) => _run(
  'spec-sync-report <file>…',
  'The document-set validation of the documents given; writes nothing.',
  specSyncReportParser(),
  arguments,
  out,
  err,
  (r, o) {
    final set = _Set.load(r.rest);
    final report = syncReport(set.set, pairs: _pairs(r));
    if (r.flag('json')) {
      o.writeln(jsonEncode(report.toJson()));
    } else {
      for (final f in report.findings) {
        o.writeln(
          '${f.isInfo ? 'INFO' : 'FINDING'}  ${f.code.name} ${f.pair} '
          '${f.blueprint.path}'
          '${(f.blueprint.field ?? f.detail.field) == null ? '' : ' ${f.blueprint.field ?? f.detail.field}'}'
          ' (${f.resolution.name})',
        );
      }
      for (final e in report.documentFindings.entries) {
        for (final v in e.value) {
          o.writeln('DOCUMENT ${e.key} ${v.code.name} ${v.path}');
        }
      }
      for (final n in report.notStarted) {
        o.writeln('NOT STARTED $n');
      }
      o.writeln(
        'sync-report: ${report.findings.length} finding(s), '
        '${report.clean ? 'clean' : 'not clean'}',
      );
    }
    return report.clean ? 0 : 1;
  },
);

/// `:spec-backfill`: the Phase 3 documents' values into the Blueprint.
Future<int> runSpecBackfill(
  List<String> arguments, {
  StringSink? out,
  StringSink? err,
  SpecStageHook? onStaged,
}) => _run(
  'spec-backfill <file>…',
  "Carry each Phase 3 document's values into the Blueprint, as plain values.",
  specBackfillParser(),
  arguments,
  out,
  err,
  (r, o) {
    final set = _Set.load(r.rest);
    final dryRun = r.flag('dry-run');
    final SpecBackfillResult result;
    try {
      result = backfill(
        set.set,
        pairs: _pairs(r),
        path: r.option('path'),
        dryRun: dryRun,
      );
    } on SpecBackfillError catch (x) {
      throw _Refused({'refused': x.toJson()}, '$x');
    }
    final name = set.set.nameOf(set.set.blueprintRoot!)!;
    final write = result.changes.isNotEmpty && !dryRun;
    if (write) {
      set.write(name, result.blueprint, r.option('stage-folder'), onStaged);
    }
    if (r.flag('json')) {
      o.writeln(jsonEncode(result.toJson()));
    } else {
      for (final c in result.changes) {
        o.writeln(
          'CHANGE   ${c.kind} ${c.pair} ${c.path}'
          '${c.field == null ? '' : ' ${c.field}'}',
        );
      }
      for (final l in result.left) {
        o.writeln(
          'LEFT     ${l.finding.code.name} ${l.finding.pair} (${l.reason})',
        );
      }
      o.writeln(
        'backfill: ${result.changes.length} change(s), '
        '${result.left.length} left; '
        '${write
            ? 'wrote ${set.fileOf(name)}'
            : dryRun
            ? 'dry run, nothing written'
            : 'nothing to write'}',
      );
    }
    return result.left.any((l) => !l.finding.isInfo) ? 1 : 0;
  },
);

/// `:spec-prefill`: a Phase 3 document started from the Blueprint.
Future<int> runSpecPrefill(
  List<String> arguments, {
  StringSink? out,
  StringSink? err,
  SpecStageHook? onStaged,
}) => _run(
  'spec-prefill <file>… --root <root>',
  'Start a Phase 3 document from the Blueprint: every pair it holds nothing '
      'of yet filled once.',
  specPrefillParser(),
  arguments,
  out,
  err,
  (r, o) {
    final rootArg = r.option('root');
    if (rootArg == null) throw const _UsageError('--root is required');
    final root = somSpecModel.roots
        .where((x) => x.type == rootArg || x.sectionId == rootArg)
        .firstOrNull;
    if (root == null) {
      throw _UsageError('--root $rootArg names no root of the model');
    }
    final target = r.option('target');
    final files = [...r.rest];
    if (target != null &&
        File(target).existsSync() &&
        !files.contains(target)) {
      files.add(target);
    }
    final set = _Set.load(files);
    final existing = set.set.nameOf(root.type);
    if (target != null) {
      if (!target.endsWith('.tomspecs.yaml')) {
        throw const _UsageError('--target names a *.tomspecs.yaml file');
      }
      final name = target.split('/').last;
      if (File(target).existsSync() && set.set.rootOf(name) != root.type) {
        throw _Refused({
          'refused': {'code': 'rootMismatch', 'file': target},
        }, '$target is no document of ${root.type}');
      }
      if (existing != null && existing != name) {
        throw _Refused({
          'refused': {'code': 'rootTaken', 'document': existing},
        }, 'the set holds ${root.type} as $existing already');
      }
    } else if (existing == null) {
      throw const _UsageError(
        'the set holds no document of the root: name the new one with '
        '--target',
      );
    }
    final SpecPrefillResult result;
    try {
      result = prefill(
        set.set,
        root.type,
        name: target?.split('/').last,
        pairs: _pairs(r),
      );
    } on SpecPrefillError catch (x) {
      throw _Refused({
        'refused': {'code': x.code, 'message': x.message},
      }, '$x');
    }
    final dryRun = r.flag('dry-run');
    final wrote =
        result.filledPairs.isNotEmpty || result.derived.changes.isNotEmpty;
    if (wrote && !dryRun) {
      if (target != null) set.files[result.name] = [target];
      set.write(
        result.name,
        result.document,
        r.option('stage-folder'),
        onStaged,
        rootType: root.type,
      );
    }
    if (r.flag('json')) {
      o.writeln(jsonEncode(result.toJson()));
    } else {
      for (final p in result.filledPairs) {
        o.writeln('FILLED   $p');
      }
      for (final p in result.skippedPairs) {
        o.writeln('SKIPPED  $p (its anchor holds a value)');
      }
      for (final f in result.findings) {
        o.writeln('FINDING  ${f.code.name} ${f.path}');
      }
      o.writeln(
        'prefill: ${result.filledPairs.length} pair(s) filled, '
        '${result.findings.length} finding(s); '
        '${wrote && !dryRun
            ? 'wrote ${target ?? set.fileOf(result.name)}'
            : dryRun
            ? 'dry run, nothing written'
            : 'nothing to write'}',
      );
    }
    return result.findings.isEmpty ? 0 : 1;
  },
);

/// `:spec-derive-fields`: the derived places of one document.
Future<int> runSpecDeriveFields(
  List<String> arguments, {
  StringSink? out,
  StringSink? err,
  SpecStageHook? onStaged,
}) => _run(
  'spec-derive-fields <file>',
  'Derive the derived places of one document: as review marks, or plain '
      'with --unmarked.',
  specDeriveFieldsParser(),
  arguments,
  out,
  err,
  (r, o) {
    if (r.rest.length != 1) {
      throw const _UsageError('give exactly one document');
    }
    final set = _Set.load(r.rest, single: true);
    final name = set.set.names.single;
    final dryRun = r.flag('dry-run');
    final result = deriveFields(
      somSpecModel,
      set.set[name]!,
      marked: !r.flag('unmarked'),
      author: r.option('author'),
      at: r.option('at'),
      dryRun: dryRun,
    );
    final write = result.changes.isNotEmpty && !dryRun;
    if (write) {
      set.write(name, result.document, r.option('stage-folder'), onStaged);
    }
    if (r.flag('json')) {
      o.writeln(jsonEncode(result.toJson()));
    } else {
      for (final c in result.changes) {
        o.writeln('CHANGE   ${c.toJson()['kind']} ${c.toJson()['path']}');
      }
      for (final u in result.unresolved) {
        o.writeln('UNRESOLVED ${u.code.name} ${u.path}');
      }
      o.writeln(
        'derive-fields: ${result.changes.length} change(s), '
        '${result.unresolved.length} unresolved; '
        '${write
            ? 'wrote ${set.fileOf(name)}'
            : dryRun
            ? 'dry run, nothing written'
            : 'nothing to write'}',
      );
    }
    return result.unresolved.isEmpty ? 0 : 1;
  },
);

/// `:spec-rename-id`: a section id renamed in every document of the set.
Future<int> runSpecRenameId(
  List<String> arguments, {
  StringSink? out,
  StringSink? err,
}) => _run(
  'spec-rename-id <file>… --from <id> --to <id>',
  'Rename a section id in every document of the set at once.',
  specRenameIdParser(),
  arguments,
  out,
  err,
  (r, o) {
    final from = r.option('from'), to = r.option('to');
    if (from == null || to == null) {
      throw const _UsageError('--from and --to are required');
    }
    final set = _Set.load(r.rest);
    final List<SpecRenameChange> changes;
    try {
      changes = renameId(set.set, from, to);
    } on SpecRenameError catch (x) {
      throw _Refused({
        'refused': {'code': 'exists', 'documents': x.documents},
      }, x.message);
    }
    final changed = {for (final c in changes) c.document};
    final dryRun = r.flag('dry-run');
    if (!dryRun) {
      for (final name in set.set.names) {
        if (changed.contains(name)) {
          set.write(name, set.set[name]!, null, null);
        }
      }
    }
    if (r.flag('json')) {
      o.writeln(
        jsonEncode({
          'changes': [for (final c in changes) c.toJson()],
        }),
      );
    } else {
      for (final c in changes) {
        o.writeln(
          'CHANGE   ${c.document} ${c.kind} ${c.path}'
          '${c.field == null ? '' : ' ${c.field}'}',
        );
      }
      o.writeln(
        'rename-id: ${changes.length} change(s) in ${changed.length} '
        'document(s); ${dryRun
            ? 'dry run, nothing written'
            : changed.isEmpty
            ? 'nothing to write'
            : 'written'}',
      );
    }
    return 0;
  },
);

// ---------------------------------------------------------------------------
// Shared
// ---------------------------------------------------------------------------

Future<int> _run(
  String usage,
  String what,
  ArgParser parser,
  List<String> arguments,
  StringSink? out,
  StringSink? err,
  int Function(ArgResults, StringSink) body,
) async {
  final o = out ?? stdout;
  final e = err ?? stderr;
  ArgResults? results;
  try {
    try {
      results = parser.parse(arguments);
    } on FormatException catch (x) {
      throw _UsageError(x.message);
    }
    if (results.flag('help')) {
      o
        ..writeln('Usage: tomspecs :$usage [options]')
        ..writeln()
        ..writeln(what)
        ..writeln()
        ..writeln(parser.usage);
      return 0;
    }
    return body(results, o);
  } on _UsageError catch (x) {
    e
      ..writeln('error: ${x.message}')
      ..writeln('Usage: tomspecs :$usage [options]')
      ..writeln(parser.usage);
    return 2;
  } on _Refused catch (x) {
    if (results?.flag('json') ?? false) {
      o.writeln(jsonEncode(x.json));
    }
    e.writeln('refused: ${x.message}');
    return 2;
  } on SpecDocumentSetError catch (x) {
    if (results?.flag('json') ?? false) {
      o.writeln(jsonEncode({'refused': x.toJson()}));
    }
    e.writeln('refused: ${x.message}');
    return 2;
  }
}

Set<String>? _pairs(ArgResults r) {
  final v = r.option('pairs');
  if (v == null) return null;
  return {
    for (final p in v.split(','))
      if (p.trim().isNotEmpty) p.trim(),
  };
}

/// The documents of a run: the set, each document's files, and what a write
/// keeps of each (the YAML's model version and review pass).
class _Set {
  _Set(this.set, this.files, this.decoded);

  final SpecDocumentSet set;

  /// Document name → the files it was read from.
  final Map<String, List<String>> files;

  /// Document name → its YAML contents (null for Markdown).
  final Map<String, SpecYamlContents?> decoded;

  static _Set load(List<String> paths, {bool single = false}) {
    if (paths.isEmpty) throw const _UsageError('give the documents');
    final model = somSpecModel;
    final fragments = <String, SpecDocument>{};
    final byName = <String, String>{};
    final decoded = <String, SpecYamlContents?>{};
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) throw _UsageError('no such file: $path');
      final text = file.readAsStringSync();
      final name = path.split('/').last;
      byName[name] = path;
      if (path.endsWith('.md')) {
        final import = SpecDocument.fromMarkdown(text, model);
        fragments[name] = import.document;
        decoded[name] = null;
        continue;
      }
      final root = _yamlRoot(text);
      if (root == null) {
        throw SpecDocumentSetError(SpecDocumentSetRefusal.noRoot, [
          name,
        ], '$name names no root of the model');
      }
      final contents = SpecDocumentYaml.decode(text, _tree(root.type));
      fragments[name] = contents.document;
      decoded[name] = contents;
    }
    final set = single
        ? SpecDocumentSet(model, fragments)
        : SpecDocumentSet.fromFragments(model, fragments);
    // Each document is named by its first fragment: its files are the
    // fragments of its root, in the order given.
    final files = <String, List<String>>{};
    for (final name in set.names) {
      final root = set.rootOf(name);
      files[name] = [
        for (final e in fragments.entries)
          if (_rootsOf(model, e.value).contains(root)) byName[e.key]!,
      ];
    }
    return _Set(set, files, decoded);
  }

  static SpecRoot? _yamlRoot(String text) => somSpecModel.roots
      .where(
        (r) => RegExp(
          '^\\s*${RegExp.escape(r.sectionId ?? '')} '
          '${RegExp.escape(r.type)}:',
          multiLine: true,
        ).hasMatch(text),
      )
      .firstOrNull;

  static final Map<String, SomMetaTree> _trees = {};
  static SomMetaTree _tree(String rootType) => _trees.putIfAbsent(
    rootType,
    () => buildSomMetaTree(somSpecModel, rootType: rootType),
  );

  static Set<String> _rootsOf(SpecModel model, SpecDocument d) {
    final refl = SpecReflection(model);
    return {
      for (final r in model.roots)
        if ([d.contentPaths, d.formPaths, d.listPaths, d.headlinePaths].any(
          (ps) => ps.any(
            (p) =>
                p == refl.rootSegment(r) ||
                p.startsWith('${refl.rootSegment(r)}/'),
          ),
        ))
          r.type,
    };
  }

  /// The file document [name] is written to.
  String? fileOf(String name) => files[name]?.firstOrNull;

  /// Writes [doc] as document [name] in stages: the YAML and its rendition
  /// staged in [stageFolder] (else beside the document of record), then
  /// copied over the document of record and its rendition. A document read
  /// from Markdown or assembled from fragments is refused.
  void write(
    String name,
    SpecDocument doc,
    String? stageFolder,
    SpecStageHook? onStaged, {
    String? rootType,
  }) {
    final paths = files[name] ?? const [];
    if (paths.length > 1) {
      throw _Refused({
        'refused': {'code': 'fragments', 'files': paths},
      }, '$name is assembled from ${paths.length} files and is not written');
    }
    final record = paths.isEmpty ? name : paths.single;
    if (!record.endsWith('.tomspecs.yaml')) {
      throw _Refused({
        'refused': {'code': 'notYaml', 'file': record},
      }, '$record is no *.tomspecs.yaml and is not written');
    }
    final type = rootType ?? set.rootOf(name)!;
    final root = somSpecModel.roots.firstWhere((r) => r.type == type);
    final contents = decoded[name];
    final yaml = SpecDocumentYaml.encode(
      document: doc,
      tree: _tree(type),
      modelVersion: contents?.modelVersion ?? somSpecModel.modelVersionString,
      review: contents?.review,
    );
    final again = SpecDocumentYaml.decode(yaml, _tree(type));
    if (jsonEncode(again.document.toJson()) != jsonEncode(doc.toJson())) {
      throw _Refused({
        'refused': {'code': 'verification', 'file': record},
      }, 'the YAML written does not decode to the document');
    }
    final fileName = record.split('/').last;
    final rootId = (root.sectionId ?? root.type).toLowerCase();
    final suffix = '.$rootId.tomspecs.yaml';
    final stem = fileName.endsWith(suffix)
        ? fileName.substring(0, fileName.length - suffix.length)
        : null;
    final markdown = SpecDocumentMarkdown(
      somSpecModel,
      doc,
      fileStem: stem,
    ).exportRoot(root);
    final mdName = fileName.replaceFirst(RegExp(r'\.yaml$'), '.md');
    final recordMd = '${File(record).parent.path}/$mdName';

    // 1. The stage, complete before anything of record moves.
    final stageDir = Directory(stageFolder ?? File(record).parent.path)
      ..createSync(recursive: true);
    final stagedYaml = stageFolder == null
        ? '${stageDir.path}/.$fileName.stage'
        : '${stageDir.path}/$fileName';
    final stagedMd = stageFolder == null
        ? '${stageDir.path}/.$mdName.stage'
        : '${stageDir.path}/$mdName';
    _writeAtomic(stagedYaml, yaml);
    _writeAtomic(stagedMd, markdown);
    onStaged?.call(stagedYaml, record);

    // 2. Copied over the document of record and its rendition.
    _writeAtomic(record, File(stagedYaml).readAsStringSync());
    _writeAtomic(recordMd, File(stagedMd).readAsStringSync());
    if (stageFolder == null) {
      File(stagedYaml).deleteSync();
      File(stagedMd).deleteSync();
    }
  }

  /// [text] written to [path] through a temporary file and a rename.
  static void _writeAtomic(String path, String text) {
    final tmp = File('$path.tmp');
    tmp.writeAsStringSync(text, flush: true);
    tmp.renameSync(path);
  }
}

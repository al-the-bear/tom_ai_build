import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The impact walk of the `tom_specs` change mode (Phase 0, step `impact`):
/// every section of every document root of the model for a specification —
/// filled or not, roots the project never created included — with its
/// section-id chain, class, fill state and CodeSpecs routing, and the project's
/// level (documents, extracts, IR, gates, tests, code).
///
/// ```text
///   tomspecs :spec-impact-walk --spec-root <dir> [--out walk/all.md]
///   tomspecs :spec-impact-walk --spec-root <dir> --root SBP --out walk/sbp.md
///   tomspecs :spec-impact-walk --spec-root <dir> --tests <dir> --code <dir> --json
/// ```
///
/// The documents are the `*.docspecs.yaml` files directly in the spec root's
/// `phase*` folders (the step folders below hold round copies), unless `--file`
/// names them. The walk is the runtime's `spec_impact_walk`; this command only
/// finds the files, probes the folders and writes the result.
Future<int> runSpecImpactWalk(List<String> arguments) async {
  try {
    return await _main(arguments);
  } on ToolExit catch (e) {
    return e.code;
  }
}

/// The options of `tomspecs :spec-impact-walk`.
ArgParser specImpactWalkParser() => ArgParser()
  ..addOption(
    'spec-root',
    help:
        'The specification folder: its phase*/ documents are read, its '
        'listing gives the level. Required.',
    valueHelp: 'dir',
  )
  ..addMultiOption(
    'file',
    help:
        'A document to read instead of the discovered ones (repeatable). '
        'Relative to the current directory.',
    valueHelp: 'file',
  )
  ..addMultiOption(
    'root',
    help:
        'Write only these roots\' tables (type or section id; repeatable). The '
        'walk and the level still cover every root.',
    valueHelp: 'root',
  )
  ..addMultiOption(
    'tests',
    help:
        'A folder holding the project\'s tests (repeatable); reported present or absent.',
    valueHelp: 'dir',
  )
  ..addMultiOption(
    'code',
    help:
        'A folder holding the project\'s code (repeatable); reported present or absent.',
    valueHelp: 'dir',
  )
  ..addOption(
    'out',
    help: 'Write the result to this file instead of stdout.',
    valueHelp: 'file',
  )
  ..addFlag(
    'json',
    help: 'Write JSON (walk and level) instead of the Markdown table.',
    negatable: false,
  )
  ..addFlag(
    'help',
    abbr: 'h',
    help: 'Show usage information.',
    negatable: false,
  );

Never _usage(ArgParser parser, String message) {
  stderr.writeln('spec-impact-walk: $message');
  stderr.writeln(
    'Usage: tomspecs :spec-impact-walk --spec-root <dir> [options]',
  );
  stderr.writeln(parser.usage);
  throw ToolExit(2);
}

Future<int> _main(List<String> arguments) async {
  final parser = specImpactWalkParser();
  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    _usage(parser, e.message);
  }
  if (results.flag('help')) {
    stdout.writeln(
      'Usage: tomspecs :spec-impact-walk --spec-root <dir> [options]',
    );
    stdout.writeln(parser.usage);
    return 0;
  }
  final specRoot = results.option('spec-root');
  if (specRoot == null) _usage(parser, '--spec-root is required');
  final rootDir = Directory(specRoot);
  if (!rootDir.existsSync()) _usage(parser, 'no folder $specRoot');

  final model = somSpecModel;
  final listing = _listing(rootDir);
  final files = results.multiOption('file').isNotEmpty
      ? results.multiOption('file')
      : [
          for (final f in specImpactDocumentFiles(listing))
            p.join(rootDir.path, f),
        ];

  final documents = <String, SpecDocument>{};
  final fileOf = <String, String>{};
  for (final file in files) {
    final f = File(file);
    if (!f.existsSync()) _usage(parser, 'no file $file');
    final text = f.readAsStringSync();
    final SpecRoot root;
    try {
      root = resolveSpecDocumentRoot(model, null, text, isMarkdown: false);
    } on ArgumentError catch (e) {
      _usage(parser, '$file: ${e.message}');
    }
    if (fileOf.containsKey(root.type)) {
      _usage(
        parser,
        'two documents of the root ${root.type}: ${fileOf[root.type]} and $file',
      );
    }
    fileOf[root.type] = file;
    documents[root.type] = SpecDocument.fromYaml(
      text,
      buildSomMetaTree(model, rootType: root.type),
    );
  }

  List<SpecImpactFolder>? folders(String name) {
    final given = results.multiOption(name);
    if (given.isEmpty) return null;
    return [
      for (final d in given) SpecImpactFolder(d, Directory(d).existsSync()),
    ];
  }

  final walk = specImpactWalk(model, documents);
  final level = specImpactLevel(
    model,
    walk,
    listing,
    folders('tests'),
    folders('code'),
  );

  final wanted = results.multiOption('root');
  for (final w in wanted) {
    if (walk.every((r) => r.type != w && r.sectionId != w)) {
      _usage(parser, '--root $w names no root of the model');
    }
  }
  final shown = wanted.isEmpty
      ? walk
      : [
          for (final r in walk)
            if (wanted.contains(r.type) || wanted.contains(r.sectionId)) r,
        ];

  final output = results.flag('json')
      ? '${const JsonEncoder.withIndent('  ').convert({
          'documents': fileOf,
          'walk': [for (final r in shown) r.toJson()],
          'level': level.toJson(),
        })}\n'
      : specImpactWalkMarkdown(shown, level);

  final out = results.option('out');
  if (out == null) {
    stdout.write(output);
  } else {
    File(out)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(output);
    final rows = shown.fold<int>(0, (n, r) => n + r.rows.length);
    stdout.writeln(
      'spec-impact-walk: ${shown.length} roots, $rows rows, '
      '${documents.length} documents read; level: phases '
      '${level.phasesReached.join(', ')} reached -> $out',
    );
  }
  return 0;
}

/// Every file under [dir], relative to it with `/` separators (dot-folders
/// and `node_modules` skipped).
List<String> _listing(Directory dir) {
  final out = <String>[];
  void walk(Directory d) {
    for (final e in d.listSync(followLinks: false)) {
      final name = p.basename(e.path);
      if (e is Directory) {
        if (name.startsWith('.') || name == 'node_modules') continue;
        walk(e);
      } else if (e is File) {
        out.add(p.posix.joinAll(p.split(p.relative(e.path, from: dir.path))));
      }
    }
  }

  walk(dir);
  out.sort();
  return out;
}

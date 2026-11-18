/// Reports every doc line newly stated in BOTH spec-tree surfaces, and exits
/// non-zero when there is one.
///
/// The gate over the reviewer/editor documentation fork.
/// `test/spec_tree_duplication_test.dart` runs the same check in the default
/// `dart test` run; this is the command a person runs to see the list, and the
/// only way to re-record the baseline.
///
/// See `lib/src/spec_tree_duplication.dart` for what is measured and why the
/// gate is a ratchet — the shared set may shrink and never grow — rather than a
/// "must be empty" check.
///
/// Exit codes: `0` at or below baseline, `1` new shared lines, `2` the check
/// could not run.
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Runs `tomspecs :gate-spec-tree-duplication` with [arguments] and returns its exit code, without ending
/// the process (the `tomspecs` command calls it).
Future<int> runCheckSpecTreeDuplication(List<String> arguments) async {
  _exitCode = 0;
  try {
    _mainCheckSpecTreeDuplication(arguments);
  } on ToolExit catch (e) {
    return e.code;
  }
  return _exitCode;
}

int _exitCode = 0;

/// The options of `tomspecs :gate-spec-tree-duplication`.
ArgParser checkSpecTreeDuplicationParser() => ArgParser()
  ..addFlag(
    'record',
    negatable: false,
    help:
        'Rewrite the baseline from the current measurement. Use when the '
        'shared set has shrunk, in the same commit that shrank it.',
  )
  ..addOption(
    'baseline',
    help:
        'Path to the baseline. Default: $sharedDocBaselinePath beside this '
        'package.',
  )
  ..addOption(
    'container-root',
    help:
        'Workspace container root holding both spec trees. Default: three '
        'levels above this package.',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.');

void _mainCheckSpecTreeDuplication(List<String> arguments) {
  final parser = checkSpecTreeDuplicationParser();

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}\n');
    stderr.writeln(parser.usage);
    throw ToolExit(2);
  }
  if (results.flag('help')) {
    stdout.writeln('Usage: tomspecs :gate-spec-tree-duplication [options]\n');
    stdout.writeln(parser.usage);
    throw ToolExit(0);
  }

  final packageRoot = p.normalize(Directory.current.path);
  final containerRoot = p.normalize(
    results.option('container-root') ?? p.join(packageRoot, '..', '..', '..'),
  );
  final baselineFile = File(
    results.option('baseline') ?? p.join(packageRoot, sharedDocBaselinePath),
  );

  // Checked explicitly rather than inferred from an empty intersection: two
  // trees, two repos, and a checkout missing either one would otherwise report
  // a clean gate having compared nothing.
  for (final tree in [reviewerTreeRoot, editorTreeRoot]) {
    if (!Directory(p.join(containerRoot, tree)).existsSync()) {
      stderr.writeln(
        'gate-spec-tree-duplication: spec tree not found: '
        '${p.join(containerRoot, tree)}',
      );
      throw ToolExit(2);
    }
  }

  final shared = sharedSpecTreeDocs(containerRoot);

  if (results.flag('record')) {
    writeSharedDocBaseline(baselineFile, shared);
    stdout.writeln(
      'gate-spec-tree-duplication: recorded ${shared.length} shared doc '
      'line(s) to ${baselineFile.path}',
    );
    throw ToolExit(0);
  }

  if (!baselineFile.existsSync()) {
    stderr.writeln(
      'gate-spec-tree-duplication: no baseline at ${baselineFile.path}\n'
      '  record one with --record',
    );
    throw ToolExit(2);
  }

  final baseline = readSharedDocBaseline(baselineFile);
  final added = shared.difference(baseline);
  final removed = baseline.difference(shared);

  if (added.isEmpty) {
    stdout.writeln(
      'gate-spec-tree-duplication: ${shared.length} shared doc line(s), '
      'none new',
    );
    if (removed.isNotEmpty) {
      // Progress, not a failure — but it must be re-recorded, or the baseline
      // goes on permitting duplication that no longer exists and a later fork
      // can reintroduce one of these lines unseen.
      stdout.writeln(
        '  ${removed.length} baseline line(s) no longer shared — re-record '
        'with --record in this commit:',
      );
      for (final line in removed.toList()..sort()) {
        stdout.writeln('    - $line');
      }
    }
    throw ToolExit(0);
  }

  stderr.writeln(
    'gate-spec-tree-duplication: ${added.length} NEW shared doc line(s) '
    'between the two spec trees',
  );
  for (final line in added.toList()..sort()) {
    stderr.writeln('  + $line');
  }
  stderr.writeln(
    '\nEach line above is now stated in both $reviewerTreeRoot and\n'
    '$editorTreeRoot. The reviewer is documentation-gated and the editor is\n'
    'not, so the two copies will drift and nothing will say so. Move the rule\n'
    'it explains to `tom_som_dart_runtime` and have both trees cite it, or —\n'
    'if the shared wording is genuinely the intended end state — re-record the\n'
    'baseline with --record and say why in the commit.',
  );
  throw ToolExit(1);
}

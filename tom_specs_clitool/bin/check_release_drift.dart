import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Reports which release-set packages have moved since their version was set.
///
///   dart run bin/check_release_drift.dart
///
/// Exits 1 when a package has drifted and is not acknowledged in
/// `tool/release_set.yaml`'s `unpublished_drift:` block, or when an
/// acknowledgement names a package the manifest does not release.
void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption(
      'manifest',
      help: 'Release-set manifest. Default: tool/release_set.yaml.',
    )
    ..addOption(
      'container-root',
      help:
          'Workspace root the manifest paths are relative to. Default: three '
          'levels above this package.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'List every changed file rather than the first five.',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show usage information.',
      negatable: false,
    );

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stdout.writeln(parser.usage);
    exit(2);
  }

  if (results.flag('help')) {
    stdout.writeln('Usage: dart run bin/check_release_drift.dart [options]');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final clitoolRoot = p.dirname(p.dirname(p.fromUri(Platform.script)));
  final containerRoot = p.normalize(
    results.option('container-root') ?? p.join(clitoolRoot, '..', '..', '..'),
  );
  final manifest = p.normalize(
    results.option('manifest') ??
        p.join(clitoolRoot, 'tool', 'release_set.yaml'),
  );

  final report = computeReleaseDrift(
    containerRoot: containerRoot,
    manifestPath: manifest,
  );

  stdout.writeln('release-drift: ${report.packages.length} package(s)');
  renderReleaseDrift(report).forEach(stdout.writeln);

  if (report.isClean) {
    stdout.writeln(
      'release-drift: every package is at its published tree, or says why not',
    );
    exit(0);
  }

  final limit = results.flag('verbose') ? 1 << 30 : 5;
  stderr.writeln('');
  stderr.writeln('release-drift: unacknowledged drift');
  for (final v in report.violations) {
    stderr.writeln(
      '  ${v.package} (${v.version}) — '
      '${v.changedFiles.length} file(s) since ${v.versionCommit ?? "?"}',
    );
    for (final f in v.changedFiles.take(limit)) {
      stderr.writeln('      $f');
    }
    if (v.changedFiles.length > limit) {
      stderr.writeln('      … and ${v.changedFiles.length - limit} more');
    }
  }
  stderr.writeln('');
  stderr.writeln(
    'Either publish the package at a new version, or record why it is behind '
    'under `unpublished_drift:` in tool/release_set.yaml.',
  );
  exit(1);
}

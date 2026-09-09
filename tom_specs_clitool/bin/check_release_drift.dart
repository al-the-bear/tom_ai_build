import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Reports which release-set packages have moved since their version was set.
///
///   dart run bin/check_release_drift.dart
///
/// Exits 1 when a package has drifted and is not acknowledged in
/// `tool/release_set.yaml`'s `unpublished_drift:` block, or when an
/// acknowledgement names a package the manifest does not release.
void main() {
  final clitoolRoot = p.dirname(p.dirname(p.fromUri(Platform.script)));
  final containerRoot = p.normalize(p.join(clitoolRoot, '..', '..', '..'));
  final manifest = p.join(clitoolRoot, 'tool', 'release_set.yaml');

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

  stderr.writeln('');
  stderr.writeln('release-drift: unacknowledged drift');
  for (final v in report.violations) {
    stderr.writeln(
      '  ${v.package} (${v.version}) — '
      '${v.changedFiles.length} file(s) since ${v.versionCommit ?? "?"}',
    );
    for (final f in v.changedFiles.take(5)) {
      stderr.writeln('      $f');
    }
    if (v.changedFiles.length > 5) {
      stderr.writeln('      … and ${v.changedFiles.length - 5} more');
    }
  }
  stderr.writeln('');
  stderr.writeln(
    'Either publish the package at a new version, or record why '
    'it is behind under `unpublished_drift:` in tool/release_set.yaml.',
  );
  exit(1);
}

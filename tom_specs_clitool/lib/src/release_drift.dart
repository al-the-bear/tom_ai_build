/// The **release-drift** gate: a release-set package whose tree has moved since
/// the commit that set its current version has unpublished changes, and nothing
/// on pub.dev says so.
///
/// ## The defect
///
/// Measured 2026-09-08 by hand: every one of the eight `ai_build` release-set
/// packages had changed since the 1.1.0 release commit, and only the three the
/// samples force-published had been republished. `tom_specs_clitool` was
/// **+34,604 lines** behind its published version. Nothing reported it — the
/// published set silently under-reported what the repository held, and the only
/// way to see it was to diff by hand against a commit you had to know to pick.
///
/// The drift is not itself a defect; publishing on demand is a legitimate
/// cadence. What is a defect is that *it cannot be seen*: a reader of pub.dev
/// sees a version, a reader of the repository sees the source, and neither sees
/// the gap between them.
///
/// ## What is compared, and against what
///
/// For each Dart member of `tool/release_set.yaml`:
///
/// 1. Find the commit that **introduced the current `version:` line** —
///    `git log -S` over that package's `pubspec.yaml`, taking the *earliest*
///    match so a version reverted and re-applied still anchors to the first
///    time it was set.
/// 2. Diff that commit against `HEAD`, scoped to the package directory.
/// 3. Anything left is drift.
///
/// The anchor is deliberately the version bump and not a release tag. Tags are
/// cut per release and these packages are published one at a time, so a tag
/// would answer "since the last release of everything" where the question is
/// "since this package last claimed a new version".
///
/// **Per-repository, not per-workspace.** `tom_core_codespecs` lives in a
/// different git repository from the other eight, so each package's history is
/// read in the repository that actually holds it. A single
/// `git -C <container-root>` would silently report no history for it.
///
/// ## Why an acknowledgement list rather than a hard failure
///
/// A gate that failed on any drift would be red from the first edit after every
/// publish — which is every working day, and a gate that is always red is a
/// gate that gets switched off. So drift is failed **only when it is not
/// acknowledged**: `unpublished_drift:` in the manifest maps a package to the
/// reason it is knowingly behind. Acknowledging costs one line and is the
/// record that "publish on demand" always needed; forgetting to costs a red
/// test that names the package and the file count.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'release_closure.dart';

/// Paths inside a package that are not part of what it publishes.
///
/// `pubspec.lock` and `tom_build_state.json` move on every local resolve and
/// build, `testlog/` is gitignored test output, and `.dart_tool/` is the pub
/// cache's own. Counting them would report drift on a package nobody edited.
const releaseDriftIgnoredPaths = <String>[
  'pubspec.lock',
  'tom_build_state.json',
  'testlog/',
  '.dart_tool/',
];

/// One package's drift verdict.
class PackageDrift {
  /// Package name, as `release_set:` keys it.
  final String package;

  /// Container-root-relative directory of the package.
  final String directory;

  /// The version its `pubspec.yaml` currently declares.
  final String version;

  /// The commit that introduced [version], or `null` when none was found —
  /// which happens for a version that has never been committed, and is
  /// reported rather than treated as "no drift".
  final String? versionCommit;

  /// Shipped files changed since [versionCommit], sorted.
  final List<String> changedFiles;

  /// The reason this package is knowingly behind, or `null` when it is not
  /// acknowledged in the manifest.
  final String? acknowledgedReason;

  /// All six fields are required; see each for what its absent case means.
  const PackageDrift({
    required this.package,
    required this.directory,
    required this.version,
    required this.versionCommit,
    required this.changedFiles,
    required this.acknowledgedReason,
  });

  /// Whether the package has moved since its version was set.
  bool get hasDrift => changedFiles.isNotEmpty;

  /// Whether this is a finding: drifted, or with no traceable version commit,
  /// and not acknowledged.
  bool get isViolation =>
      (hasDrift || versionCommit == null) && acknowledgedReason == null;
}

/// The whole run's verdict.
class ReleaseDriftReport {
  /// One entry per Dart member of the manifest, in manifest order.
  final List<PackageDrift> packages;

  /// Acknowledgement keys naming a package the manifest does not release —
  /// a stale acknowledgement, which is its own small drift.
  final List<String> unknownAcknowledgements;

  /// Both lists are required, including the empty cases.
  const ReleaseDriftReport({
    required this.packages,
    required this.unknownAcknowledgements,
  });

  /// The packages that fail the gate.
  List<PackageDrift> get violations =>
      packages.where((d) => d.isViolation).toList();

  /// Whether the run passes.
  bool get isClean => violations.isEmpty && unknownAcknowledgements.isEmpty;
}

/// Reads the `unpublished_drift:` block: package name → reason.
///
/// Absent means "nothing is acknowledged", which is the state the gate is
/// designed to be left in — an empty block and a missing one are the same
/// fact here, unlike the manifest's five structural sections.
Map<String, String> loadAcknowledgedDrift(String manifestPath) {
  final doc = loadYaml(File(manifestPath).readAsStringSync());
  if (doc is! YamlMap) return const {};
  final node = doc['unpublished_drift'];
  if (node is! YamlMap) return const {};
  return {
    for (final e in node.entries) e.key as String: (e.value as String).trim(),
  };
}

/// Computes the drift report for every Dart member of the manifest.
ReleaseDriftReport computeReleaseDrift({
  required String containerRoot,
  required String manifestPath,
}) {
  final manifest = ReleaseManifest.load(manifestPath);
  final acknowledged = loadAcknowledgedDrift(manifestPath);
  final out = <PackageDrift>[];

  for (final entry in manifest.releaseSet.entries) {
    final dir = p.join(containerRoot, entry.value);
    final version = _declaredVersion(p.join(dir, 'pubspec.yaml'));
    final repoRoot = _repoRoot(dir);
    String? commit;
    var changed = <String>[];
    if (repoRoot != null && version != null) {
      commit = _versionCommit(repoRoot, dir, version);
      if (commit != null) {
        changed = _changedSince(repoRoot, dir, commit);
      }
    }
    out.add(
      PackageDrift(
        package: entry.key,
        directory: entry.value,
        version: version ?? '<unreadable>',
        versionCommit: commit,
        changedFiles: changed,
        acknowledgedReason: acknowledged[entry.key],
      ),
    );
  }

  final unknown =
      acknowledged.keys
          .where((k) => !manifest.releaseSet.containsKey(k))
          .toList()
        ..sort();
  return ReleaseDriftReport(packages: out, unknownAcknowledgements: unknown);
}

String? _declaredVersion(String pubspecPath) {
  final file = File(pubspecPath);
  if (!file.existsSync()) return null;
  for (final line in file.readAsLinesSync()) {
    final m = RegExp(r'^version:\s*(\S+)\s*$').firstMatch(line);
    if (m != null) return m.group(1);
  }
  return null;
}

String? _repoRoot(String dir) {
  final r = Process.runSync('git', ['-C', dir, 'rev-parse', '--show-toplevel']);
  if (r.exitCode != 0) return null;
  return (r.stdout as String).trim();
}

/// The earliest commit whose diff introduced `version: <version>` in the
/// package's pubspec.
///
/// `-S` counts occurrences of the string, so it matches the commit that added
/// it *and* one that removed it; `--reverse` then `first` takes the earliest,
/// which is the one that set it. A version set, reverted and set again anchors
/// to the first time — deliberately, because that is when the published
/// version's content was decided.
String? _versionCommit(String repoRoot, String dir, String version) {
  final rel = p.relative(dir, from: repoRoot);
  final r = Process.runSync('git', [
    '-C',
    repoRoot,
    'log',
    '--reverse',
    '--format=%H',
    '-S',
    'version: $version',
    '--',
    p.join(rel, 'pubspec.yaml'),
  ]);
  if (r.exitCode != 0) return null;
  final lines = (r.stdout as String)
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  return lines.isEmpty ? null : lines.first;
}

List<String> _changedSince(String repoRoot, String dir, String commit) {
  final rel = p.relative(dir, from: repoRoot);
  final r = Process.runSync('git', [
    '-C',
    repoRoot,
    'diff',
    '--name-only',
    '$commit..HEAD',
    '--',
    rel,
  ]);
  if (r.exitCode != 0) return const [];
  final files =
      (r.stdout as String)
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .where((f) {
            final inPackage = p.relative(f, from: rel);
            return !releaseDriftIgnoredPaths.any(
              (ignored) => ignored.endsWith('/')
                  ? inPackage.startsWith(ignored)
                  : inPackage == ignored,
            );
          })
          .toList()
        ..sort();
  return files;
}

/// Renders [report] as the lines the CLI and the test both print.
List<String> renderReleaseDrift(ReleaseDriftReport report) {
  final lines = <String>[];
  for (final d in report.packages) {
    final state = d.versionCommit == null
        ? 'NO VERSION COMMIT'
        : d.hasDrift
        ? '${d.changedFiles.length} file(s) changed'
        : 'up to date';
    final ack = d.acknowledgedReason == null ? '' : '  [acknowledged]';
    lines.add(
      '  ${d.package.padRight(22)} ${d.version.padRight(9)} '
      '$state$ack',
    );
  }
  for (final name in report.unknownAcknowledgements) {
    lines.add('  unpublished_drift names $name, which is not a release member');
  }
  return lines;
}

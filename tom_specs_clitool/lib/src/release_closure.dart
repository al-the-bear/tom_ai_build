/// Release-set dependency-closure check.
///
/// Release 1 ships a fixed set of packages, and its scope deliberately
/// excludes the editor, the engine and the reviewer — and with the engine the
/// tom_assistant / tom_brain / tom_d4rt integrations. That exclusion is only
/// real if no release package *reaches* an excluded package through its
/// dependency graph: a single `tom_brain_*` edge anywhere in the closure pulls
/// the excluded plane back into the release. Until now that held by
/// inspection; this check makes it hold by construction, in the house style of
/// the citation gates — a committed manifest, a walker, a bin that exits
/// non-zero naming the offending edge, and a test in the default `dart test`
/// run so a dependency added later goes red rather than passing unseen.
///
/// The manifest (`tool/release_set.yaml`) carries four verdict sources:
///
/// - `release_set:` — the Dart members, name → container-root-relative dir.
///   The walk starts here and recurses through members' `dependencies`.
/// - `source_only:` — the non-Dart members (the eight `tom_som_<lang>` pairs
///   and `tom_som_conformance`). They have no Dart dependency graph; the check
///   holds them to existence only, so a renamed or dropped directory is caught
///   by the same gate that guards the graph.
/// - `allow:` — workspace-authored packages that are **already published to
///   pub.dev** and consumed hosted. An edge onto one is an *approved
///   crossing*, not a leak: the consumer resolves the published closure, which
///   pub.dev guarantees is itself hosted-only. The walk still continues
///   through the local pubspec of an allowed package, because approving the
///   crossing must not approve whatever sits behind it.
/// - `forbid:` — names (exact, or `prefix*`) that are red wherever they
///   appear, allowlisted or not. An `allow` or `release_set` entry matching a
///   forbid pattern is a manifest error, so the escape hatch cannot quietly
///   swallow the exclusion it exists to enforce.
///
/// Classification of a dependency name, in order: forbidden → in-set →
/// allowed → workspace-local by prefix (`workspace_prefixes:`) but unapproved
/// → third-party (permitted; pub.dev is the boundary's other side).
///
/// `dev_dependencies` of release members are classified but not recursed —
/// pub does not propagate them to consumers, but a forbidden dev dependency
/// would still break a clean-checkout build of the release set itself.
/// `dependency_overrides` (in the pubspec or `pubspec_overrides.yaml`) are
/// classified too: an override is exactly where a path edge onto an
/// unpublished sibling would hide.
///
/// A `path:` dependency must resolve to the manifest's directory for that
/// name — a path pointing at a stray copy is a distinct violation
/// (`pathMismatch`), because the graph would then be closed over different
/// bytes than the release ships.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// One approved boundary crossing: a workspace-authored package already
/// published to pub.dev.
class ReleaseAllowEntry {
  const ReleaseAllowEntry({required this.name, this.path, required this.reason});

  /// Package name.
  final String name;

  /// Container-root-relative directory of the local source, when present in
  /// the workspace — the walk continues through it. Absent means the package
  /// is consumed purely hosted and the walk stops at the approved edge.
  final String? path;

  /// Why the crossing is approved. Required: an allowlist entry without a
  /// stated reason is an exemption nobody can review.
  final String reason;
}

/// The committed release-set manifest (`tool/release_set.yaml`).
class ReleaseManifest {
  const ReleaseManifest({
    required this.releaseSet,
    required this.sourceOnly,
    required this.allow,
    required this.forbid,
    required this.workspacePrefixes,
  });

  /// Dart members: package name → container-root-relative directory.
  final Map<String, String> releaseSet;

  /// Non-Dart members: container-root-relative directories, existence-checked.
  final List<String> sourceOnly;

  /// Approved published crossings, keyed by package name.
  final Map<String, ReleaseAllowEntry> allow;

  /// Never-reachable names: exact, or `prefix*` for a prefix match.
  final List<String> forbid;

  /// Name prefixes treated as workspace-authored (everything else is
  /// third-party and permitted).
  final List<String> workspacePrefixes;

  /// Whether [name] matches a forbid pattern.
  bool isForbidden(String name) => forbid.any((pattern) =>
      pattern.endsWith('*')
          ? name.startsWith(pattern.substring(0, pattern.length - 1))
          : name == pattern);

  /// Whether [name] looks workspace-authored.
  bool isWorkspaceLocal(String name) =>
      workspacePrefixes.any(name.startsWith);

  /// Loads and shape-checks the manifest at [path].
  static ReleaseManifest load(String path) {
    final doc = loadYaml(File(path).readAsStringSync());
    if (doc is! YamlMap) {
      throw FormatException('release-set manifest is not a map: $path');
    }
    Map<String, String> stringMap(String key) {
      final node = doc[key];
      if (node == null) return const {};
      return {
        for (final entry in (node as YamlMap).entries)
          entry.key as String: entry.value as String,
      };
    }

    List<String> stringList(String key) {
      final node = doc[key];
      if (node == null) return const [];
      return [for (final item in node as YamlList) item as String];
    }

    final allowNode = doc['allow'];
    final allow = <String, ReleaseAllowEntry>{};
    if (allowNode != null) {
      for (final entry in (allowNode as YamlMap).entries) {
        final name = entry.key as String;
        final value = entry.value as YamlMap;
        final reason = value['reason'] as String?;
        if (reason == null || reason.trim().isEmpty) {
          throw FormatException(
              'allow entry "$name" has no reason — an exemption nobody can '
              'review is not an exemption ($path)');
        }
        allow[name] = ReleaseAllowEntry(
          name: name,
          path: value['path'] as String?,
          reason: reason,
        );
      }
    }

    return ReleaseManifest(
      releaseSet: stringMap('release_set'),
      sourceOnly: stringList('source_only'),
      allow: allow,
      forbid: stringList('forbid'),
      workspacePrefixes: stringList('workspace_prefixes'),
    );
  }
}

/// What kind of edge carried the violation.
enum ClosureEdgeKind { dependency, devDependency, override }

/// The distinct ways the closure can fail.
enum ClosureViolationKind {
  /// The edge lands on a name a forbid pattern names. Red regardless of any
  /// allowlist entry.
  forbidden,

  /// The edge leaves the set for a workspace-local package that is neither a
  /// member nor an approved crossing.
  unapprovedWorkspace,

  /// A `path:` dependency resolves somewhere other than the manifest's
  /// directory for that name.
  pathMismatch,

  /// The manifest contradicts itself or the tree: an allow/member entry
  /// matching a forbid pattern, a missing pubspec, a pubspec whose `name:`
  /// disagrees with its manifest key, or a missing source-only directory.
  manifest,
}

/// One violation, naming the offending edge.
class ClosureViolation {
  const ClosureViolation({
    required this.kind,
    required this.from,
    required this.to,
    this.edgeKind,
    required this.detail,
  });

  final ClosureViolationKind kind;

  /// The package (or `manifest`) the edge leaves from.
  final String from;

  /// The dependency name (or path) the edge lands on.
  final String to;

  final ClosureEdgeKind? edgeKind;

  final String detail;

  String describe() {
    final edge = edgeKind == null ? '' : ' [${edgeKind!.name}]';
    return '$from -> $to$edge — ${kind.name}: $detail';
  }
}

/// The result of one closure walk.
class ClosureReport {
  const ClosureReport({
    required this.violations,
    required this.packagesWalked,
    required this.approvedCrossings,
    required this.edgesChecked,
  });

  final List<ClosureViolation> violations;

  /// Release-set members whose pubspec was walked.
  final int packagesWalked;

  /// Distinct allowed packages actually reached.
  final int approvedCrossings;

  /// Dependency edges classified (all kinds).
  final int edgesChecked;

  bool get isClosed => violations.isEmpty;
}

/// Walks the release set's dependency graph under [containerRoot] and reports
/// every edge that breaks the closure.
ClosureReport checkReleaseClosure({
  required ReleaseManifest manifest,
  required String containerRoot,
}) {
  final violations = <ClosureViolation>[];
  var edges = 0;
  final reachedAllowed = <String>{};

  // --- Manifest sanity: forbid beats every other list. ---
  for (final name in manifest.releaseSet.keys) {
    if (manifest.isForbidden(name)) {
      violations.add(ClosureViolation(
        kind: ClosureViolationKind.manifest,
        from: 'manifest',
        to: name,
        detail: 'release_set member matches a forbid pattern',
      ));
    }
  }
  for (final name in manifest.allow.keys) {
    if (manifest.isForbidden(name)) {
      violations.add(ClosureViolation(
        kind: ClosureViolationKind.manifest,
        from: 'manifest',
        to: name,
        detail: 'allow entry matches a forbid pattern — the allowlist cannot '
            'approve an excluded package',
      ));
    }
  }

  // --- Source-only members exist. ---
  for (final dir in manifest.sourceOnly) {
    if (!Directory(p.join(containerRoot, dir)).existsSync()) {
      violations.add(ClosureViolation(
        kind: ClosureViolationKind.manifest,
        from: 'manifest',
        to: dir,
        detail: 'source_only member directory does not exist',
      ));
    }
  }

  String? dirFor(String name) =>
      manifest.releaseSet[name] ?? manifest.allow[name]?.path;

  // Classifies one edge; returns true when the walk should continue into the
  // target (it is in-set or allowed with a local path, seen for the first
  // time by the caller's visited set).
  bool classify({
    required String fromName,
    required String fromDir,
    required String depName,
    required Object? depSpec,
    required ClosureEdgeKind edgeKind,
  }) {
    edges++;
    if (manifest.isForbidden(depName)) {
      violations.add(ClosureViolation(
        kind: ClosureViolationKind.forbidden,
        from: fromName,
        to: depName,
        edgeKind: edgeKind,
        detail: 'reaches an excluded package (release 1 ships without it)',
      ));
      return false;
    }
    final inSet = manifest.releaseSet.containsKey(depName);
    final allowed = manifest.allow.containsKey(depName);
    if (!inSet && !allowed) {
      if (manifest.isWorkspaceLocal(depName)) {
        violations.add(ClosureViolation(
          kind: ClosureViolationKind.unapprovedWorkspace,
          from: fromName,
          to: depName,
          edgeKind: edgeKind,
          detail: 'leaves the release set for a workspace package that is '
              'neither a member nor an approved published crossing',
        ));
      }
      return false; // Third-party: permitted, and nothing local to walk.
    }
    if (allowed) reachedAllowed.add(depName);

    // A path dependency must point at the manifest's directory for the name.
    if (depSpec is YamlMap && depSpec['path'] is String) {
      final resolved = p.normalize(
          p.join(containerRoot, fromDir, depSpec['path'] as String));
      final expected = dirFor(depName);
      if (expected != null &&
          p.normalize(p.join(containerRoot, expected)) != resolved) {
        violations.add(ClosureViolation(
          kind: ClosureViolationKind.pathMismatch,
          from: fromName,
          to: depName,
          edgeKind: edgeKind,
          detail: 'path dependency resolves to '
              '${p.relative(resolved, from: containerRoot)}, but the manifest '
              'places $depName at $expected',
        ));
      }
    }
    return true;
  }

  // --- The walk. Members recurse; allowed packages recurse through their
  // local pubspec when one is manifest-declared; dev/override edges are
  // classified but never recursed (pub does not propagate them). ---
  final visited = <String>{};
  var membersWalked = 0;

  void walk(String name, {required bool isMember}) {
    if (!visited.add(name)) return;
    final dir = dirFor(name);
    if (dir == null) return; // Hosted-only allow entry: the edge was approved.
    final pubspecFile = File(p.join(containerRoot, dir, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      violations.add(ClosureViolation(
        kind: ClosureViolationKind.manifest,
        from: name,
        to: p.join(dir, 'pubspec.yaml'),
        detail: 'manifest names this directory but it holds no pubspec.yaml',
      ));
      return;
    }
    final pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
    if (pubspec['name'] != name) {
      violations.add(ClosureViolation(
        kind: ClosureViolationKind.manifest,
        from: name,
        to: '${pubspec['name']}',
        detail: 'pubspec name disagrees with the manifest key',
      ));
      return;
    }
    if (isMember) membersWalked++;

    Map<String, Object?> section(YamlMap source, String key) {
      final node = source[key];
      if (node is! YamlMap) return const {};
      return {for (final e in node.entries) e.key as String: e.value};
    }

    final toRecurse = <String>[];
    void classifySection(
        Map<String, Object?> deps, ClosureEdgeKind edgeKind, bool recurse) {
      for (final entry in deps.entries) {
        final continueInto = classify(
          fromName: name,
          fromDir: dir,
          depName: entry.key,
          depSpec: entry.value,
          edgeKind: edgeKind,
        );
        if (recurse && continueInto) toRecurse.add(entry.key);
      }
    }

    classifySection(section(pubspec, 'dependencies'),
        ClosureEdgeKind.dependency, true);
    // Dev deps: only release members must build from a clean checkout; an
    // allowed package's dev deps never reach the release.
    if (isMember) {
      classifySection(section(pubspec, 'dev_dependencies'),
          ClosureEdgeKind.devDependency, false);
    }
    classifySection(section(pubspec, 'dependency_overrides'),
        ClosureEdgeKind.override, false);
    final overridesFile =
        File(p.join(containerRoot, dir, 'pubspec_overrides.yaml'));
    if (overridesFile.existsSync()) {
      final overrides = loadYaml(overridesFile.readAsStringSync());
      if (overrides is YamlMap) {
        classifySection(section(overrides, 'dependency_overrides'),
            ClosureEdgeKind.override, false);
      }
    }

    for (final dep in toRecurse) {
      walk(dep, isMember: manifest.releaseSet.containsKey(dep));
    }
  }

  for (final name in manifest.releaseSet.keys) {
    walk(name, isMember: true);
  }

  return ClosureReport(
    violations: violations,
    packagesWalked: membersWalked,
    approvedCrossings: reachedAllowed.length,
    edgesChecked: edges,
  );
}

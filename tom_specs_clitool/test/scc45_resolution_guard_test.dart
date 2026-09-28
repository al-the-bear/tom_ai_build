// REPO-WIDE GUARD (tom_specs_clitool) — no package in tom_ai/ai_build resolves
// a tom_* version behind one already in the pub cache.
//
// This is the ai_build repo's own copy of the d4rt repo's
// `tom_d4rt_ast/test/scc45_resolution_guard_test.dart`, which is the model and
// carries the full history of the defect family. What follows states only what
// this copy needs to be read on its own.
//
// WHY A FROZEN LOCK MATTERS. `dart pub get` is LOCK-PRESERVING: a lower-bound
// constraint admits every newer release without ever selecting one once a lock
// exists. `pubspec.lock` is gitignored, so the staleness is per-machine and
// invisible in any diff — two hosts run the same suite against different
// dependency sets and nothing records which. A suite green against a frozen
// lock certifies a version nobody installs.
//
// WHAT THIS REPO HAD, measured 2026-09-22 and cleared by the sweep that added
// this file: 9 frozen resolutions across 6 packages. Five of the six were
// SAMPLES, which is the case that matters most — a sample is what a new project
// copies — and `tom_spec_engine`, which executes specs through D4rt, was four
// `tom_d4rt_dcli` minors behind. The sweep also found every sample DECLARING a
// floor below the release it runs against; F-SCC45-4 below is what keeps both
// from recurring.
//
// WHY IT LIVES HERE. `tom_specs_clitool`'s default `dart test` is the suite this
// repo runs routinely, and its `test/` folder is excluded from the published
// archive (`.pubignore`), so a guard that walks sibling packages costs a
// consumer nothing. It skips when the repo root is not reachable.
//
// MANY GUARDS, NOT ONE. A single workspace guard would need one exception list
// spanning a dozen repos with no owner; each repo carries its own copy with its
// own owner-named list. `_bin/check_frozen_locks.py <repo>` is the same
// question asked read-only from outside.
//
// ZERO NEW DEPENDENCIES, like the model: the lock is parsed by indentation,
// since it is machine-written and its shape is fixed.
import 'dart:io';

import 'package:test/test.dart';

/// Packages whose presence identifies the ai_build repo root.
const _repoMarkers = [
  'tom_specs_model',
  'tom_specs_clitool',
  'tom_som_conformance',
];

/// Only this workspace's own packages: a third-party dependency cannot suffer
/// an unpropagated publish from here.
const _ownedPrefix = 'tom_';

/// Packages exempted from F-SCC45-2, each naming the todo that owns the
/// unfreeze. AN EXCEPTION WITHOUT AN OWNER IS A LEAK: if you add one and cannot
/// name that todo, file it first.
///
/// EMPTY, and that is the intended resting state — F-SCC45-3 deletes any entry
/// that stops describing a frozen lock. Keep the map rather than removing it:
/// re-deriving the shape under time pressure is how an exemption gets added
/// without an owner.
const Map<String, String> _frozenLockExceptions = <String, String>{};

/// The packages whose floors F-SCC45-4 holds sample and example pubspecs to:
/// the release-1 Dart chain (`tool/release_set.yaml`). Tooling a sample merely
/// happens to use is left out — a sample demonstrates the chain, and chasing
/// every other release through every sample is churn that buys no truth.
const _chainPackages = {
  'tom_specs_core',
  'tom_doc_scanner',
  'tom_doc_specs',
  'tom_code_specs',
  'tom_core_codespecs',
  'tom_som_dart_runtime',
  'tom_som_dart_v0',
  'tom_specs_model',
  'tom_specs_clitool',
};

/// Below this many distinct cached `tom_*` packages, a pass means nothing: the
/// discriminator can only see a freeze whose newer version is cached here.
const int _minimumCachedPackages = 5;

class _Resolution {
  const _Resolution(this.name, this.source, this.version, this.dependency);
  final String name;
  final String source;
  final String version;

  /// The lock's own classification: `direct main`, `direct dev`, `direct
  /// overridden` or `transitive`.
  final String dependency;

  bool get isDirect => dependency.startsWith('direct');
}

Directory? _repoRoot() {
  var dir = Directory.current.absolute;
  for (var i = 0; i < 6; i++) {
    if (_repoMarkers.every((p) => Directory('${dir.path}/$p').existsSync())) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}

bool _pruned(Directory dir) {
  final name = dir.path.split(Platform.pathSeparator).last;
  return name.startsWith('.') || name == 'build' || name == 'node_modules';
}

/// Every directory under [root] with a pubspec (and, when [locked], a lock).
///
/// Walks nested packages too: a fixture or sample under a package carries its
/// own ignored lock, and a guard that inspected only top-level packages would
/// report green through exactly the case that hides.
List<Directory> _packagesUnder(Directory root, {bool locked = true}) {
  final found = <Directory>[];
  void walk(Directory dir, int depth) {
    if (depth > 5 || _pruned(dir)) return;
    if (File('${dir.path}/pubspec.yaml').existsSync() &&
        (!locked || File('${dir.path}/pubspec.lock').existsSync())) {
      found.add(dir);
    }
    for (final child in dir.listSync().whereType<Directory>()) {
      walk(child, depth + 1);
    }
  }

  walk(root, 0);
  return found;
}

List<_Resolution> _lockedTomPackages(Directory package) {
  final lock = File('${package.path}/pubspec.lock');
  if (!lock.existsSync()) return const [];
  final namePattern = RegExp(r'^  ([A-Za-z0-9_]+):\s*$');
  final fieldPattern = RegExp(
    r'^    (dependency|source|version):\s*"?([^"]*)"?\s*$',
  );
  final out = <_Resolution>[];
  String? current, source, version, dependency;
  void flush() {
    if (current != null &&
        current!.startsWith(_ownedPrefix) &&
        source != null &&
        version != null) {
      out.add(_Resolution(current!, source!, version!, dependency ?? ''));
    }
    current = source = version = dependency = null;
  }

  for (final line in lock.readAsLinesSync()) {
    final name = namePattern.firstMatch(line);
    if (name != null) {
      flush();
      current = name.group(1);
      continue;
    }
    final field = fieldPattern.firstMatch(line);
    if (field == null || current == null) continue;
    switch (field.group(1)) {
      case 'source':
        source = field.group(2);
      case 'version':
        version = field.group(2);
      default:
        dependency = field.group(2);
    }
  }
  flush();
  return out;
}

int _compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split(RegExp(r'[-+]'))
      .first
      .split('.')
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

/// Pub's own order: `PUB_CACHE` when set and non-empty, then the platform
/// default. The model found the Windows default the hard way — a guard that
/// looked only at `$HOME/.pub-cache` reported zero on legiondary01.
Directory _pubCacheRoot() {
  final explicit = Platform.environment['PUB_CACHE'];
  if (explicit != null && explicit.trim().isNotEmpty) {
    return Directory(explicit);
  }
  if (Platform.isWindows) {
    final local = Platform.environment['LOCALAPPDATA'];
    if (local != null && local.isNotEmpty) {
      return Directory('$local\\Pub\\Cache');
    }
  }
  return Directory('${Platform.environment['HOME'] ?? ''}/.pub-cache');
}

Directory get _hostedCache =>
    Directory('${_pubCacheRoot().path}/hosted/pub.dev');

String? _newestCachedVersion(String name) {
  final dir = _hostedCache;
  if (!dir.existsSync()) return null;
  final prefix = '$name-';
  final stable = dir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path.split(Platform.pathSeparator).last)
      .where((n) => n.startsWith(prefix))
      .map((n) => n.substring(prefix.length))
      .where((v) => !v.contains('-') && RegExp(r'^\d').hasMatch(v))
      .toList();
  if (stable.isEmpty) return null;
  stable.sort(_compareVersions);
  return stable.last;
}

String _relativeTo(Directory root, Directory dir) =>
    (dir.path.startsWith(root.path)
            ? dir.path.substring(root.path.length + 1)
            : dir.path)
        .replaceAll(r'\', '/');

/// Every lock under [root] resolving a hosted `tom_*` older than the cache
/// holds. THE CACHE IS THE DISCRIMINATOR: comparing against a sibling's pubspec
/// cannot tell a frozen lock from an unpublished sibling, while a newer version
/// sitting in the cache proves pub had it and did not take it.
List<String> _staleLocks(Directory root, Map<String, String> exceptions) {
  final out = <String>[];
  for (final package in _packagesUnder(root)) {
    final rel = _relativeTo(root, package);
    if (exceptions.containsKey(rel.split('/').first)) continue;
    for (final res in _lockedTomPackages(package)) {
      if (res.source != 'hosted') continue;
      final newest = _newestCachedVersion(res.name);
      if (newest != null && _compareVersions(res.version, newest) < 0) {
        out.add(
          '$rel locks ${res.name} ${res.version} while $newest is '
          'already in the pub cache',
        );
      }
    }
  }
  return out;
}

/// Dependency names [package]'s pubspec declares with a `path:` key.
Set<String> _declaredPathDependencies(Directory package) {
  final keyPattern = RegExp(r'^(\s+)([A-Za-z0-9_]+):\s*$');
  final declared = <String>{};
  String? openKey;
  var openIndent = 0;
  for (final raw in File('${package.path}/pubspec.yaml').readAsLinesSync()) {
    final line = raw.split('#').first;
    if (line.trim().isEmpty) continue;
    final indent = line.length - line.trimLeft().length;
    if (openKey != null) {
      if (indent > openIndent) {
        if (line.trimLeft().startsWith('path:')) declared.add(openKey);
        continue;
      }
      openKey = null;
    }
    if (keyPattern.firstMatch(line) case final m?) {
      openKey = m.group(2);
      openIndent = m.group(1)!.length;
    }
  }
  return declared;
}

/// Chain dependencies [package] declares with a version constraint.
Map<String, String> _declaredChainConstraints(Directory package) {
  final sectionPattern = RegExp(r'^([A-Za-z_]+):');
  final depPattern = RegExp(r'^  ([A-Za-z0-9_]+):\s*(.*)$');
  final declared = <String, String>{};
  String? section;
  for (final line in File('${package.path}/pubspec.yaml').readAsLinesSync()) {
    if (sectionPattern.firstMatch(line) case final m?) {
      section = m.group(1);
      continue;
    }
    if (section != 'dependencies' && section != 'dev_dependencies') continue;
    final m = depPattern.firstMatch(line);
    if (m == null || !_chainPackages.contains(m.group(1))) continue;
    final constraint = m
        .group(2)!
        .split('#')
        .first
        .trim()
        .replaceAll('"', '')
        .replaceAll("'", '');
    if (constraint.isEmpty) continue; // a `path:` block follows
    declared[m.group(1)!] = constraint;
  }
  return declared;
}

String? _lowerBound(String constraint) {
  final c = constraint.trim();
  final caret = RegExp(r'^\^(\S+)').firstMatch(c);
  if (caret != null) return caret.group(1);
  final atLeast = RegExp(r'>=?\s*([0-9][^\s<]*)').firstMatch(c);
  if (atLeast != null) return atLeast.group(1);
  if (RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+').hasMatch(c)) return c;
  return null;
}

/// A sample or example — something a user copies — rather than a library.
bool _isCopySurface(String rel) {
  final segments = rel.split('/');
  return segments.first == 'tom_specs_samples' ||
      segments.contains('example') ||
      segments.contains('examples');
}

void main() {
  final root = _repoRoot();

  group('SCC45 (ai_build): resolutions match declarations', () {
    var cachedPackages = 0;

    setUpAll(() {
      final cache = _hostedCache;
      final byPackage = <String, int>{};
      if (cache.existsSync()) {
        for (final entry in cache.listSync().whereType<Directory>()) {
          final dir = entry.path.split(Platform.pathSeparator).last;
          if (!dir.startsWith(_ownedPrefix)) continue;
          final dash = dir.lastIndexOf('-');
          if (dash <= 0) continue;
          byPackage.update(
            dir.substring(0, dash),
            (n) => n + 1,
            ifAbsent: () => 1,
          );
        }
      }
      cachedPackages = byPackage.length;
      // Printed on every run: a pass is a statement about THIS machine's cache,
      // and the number is what makes a green interpretable.
      // ignore: avoid_print
      print(
        '[SCC45] pub-cache sensitivity: '
        '${byPackage.values.fold(0, (a, b) => a + b)} tom_* version '
        'directories across $cachedPackages packages, '
        '${byPackage.values.where((n) => n > 1).length} holding more than '
        'one version.',
      );
    });

    bool canDiscriminate(String caseName) {
      if (cachedPackages >= _minimumCachedPackages) return true;
      markTestSkipped(
        '$caseName cannot answer on this machine: its pub cache '
        'holds $cachedPackages distinct tom_* package(s), below the '
        '$_minimumCachedPackages needed to tell a frozen lock from a current '
        'one. A pass here would be indistinguishable from a clean repo.',
      );
      return false;
    }

    test('F-SCC45-1: no undeclared path resolution', () {
      if (root == null) {
        markTestSkipped('ai_build repo root not reachable — nothing to check');
        return;
      }
      final offenders = <String>[];
      for (final package in _packagesUnder(root)) {
        // An overrides file is a declaration too, and this repo's generated
        // facades carry one by design.
        if (File('${package.path}/pubspec_overrides.yaml').existsSync()) {
          continue;
        }
        final declared = _declaredPathDependencies(package);
        for (final res in _lockedTomPackages(package)) {
          // DIRECT only — a divergence from the d4rt model, forced by this
          // repo's shape. `tom_spec_engine` declares path dependencies on the
          // `tom_brain_*` packages, which themselves path-link three
          // `tom_core_*` packages, so its lock resolves those from path while
          // naming none of them. That is legitimate: a transitive source is
          // decided by the dependency that declares it. DGUC10's defect — a
          // declaration dropped while the lock keeps resolving the path — is
          // always a DIRECT dependency, and that is what this asks.
          if (!res.isDirect) continue;
          if (res.source == 'path' && !declared.contains(res.name)) {
            offenders.add(
              '${_relativeTo(root, package)} resolves ${res.name} '
              'from path (${res.version}) but declares no path dependency',
            );
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'These test against a local working tree while their '
            'pubspec advertises a published version. Run `pub get` in each; '
            'pub discards a path resolution the pubspec no longer declares.\n'
            '${offenders.join('\n')}',
      );
    });

    test('F-SCC45-2: no lock is behind a version already in the pub cache', () {
      if (root == null) {
        markTestSkipped('ai_build repo root not reachable — nothing to check');
        return;
      }
      if (!canDiscriminate('F-SCC45-2')) return;
      final offenders = _staleLocks(root, _frozenLockExceptions);
      expect(
        offenders,
        isEmpty,
        reason:
            '`pub get` is lock-preserving, so these locks were passed '
            'over by a resolution that had the newer version on hand.\n'
            'REMEDY: `dart pub upgrade` (or `flutter pub upgrade`) in each '
            'package, AND in every nested sample or fixture under it; then '
            'run the suite. If an upgrade does NOT move a version, the cause '
            'is the other one — a constraint holding it, or unpublished work '
            'in the sibling working tree — and the fix is to raise or '
            'publish, not to re-resolve.\n${offenders.join('\n')}',
      );
    });

    test('F-SCC45-3: every exception is still load-bearing', () {
      if (root == null) {
        markTestSkipped('ai_build repo root not reachable — nothing to check');
        return;
      }
      // Measured with NO exceptions applied: the question is which packages
      // are still frozen, and the exception list would hide exactly those.
      final stillFrozen = _staleLocks(
        root,
        const {},
      ).map((line) => line.split(' ').first.split('/').first).toSet();
      final obsolete = _frozenLockExceptions.keys.toSet().difference(
        stillFrozen,
      );
      expect(
        obsolete,
        isEmpty,
        reason:
            'Exempted but no longer frozen — the exemption now grants '
            'only the right to freeze again unnoticed. Delete: '
            '${obsolete.join(', ')}',
      );
    });

    test('F-SCC45-4: no sample or example declares a chain floor below a '
        'version already in the pub cache', () {
      if (root == null) {
        markTestSkipped('ai_build repo root not reachable — nothing to check');
        return;
      }
      if (!canDiscriminate('F-SCC45-4')) return;

      final surfaces = _packagesUnder(
        root,
        locked: false,
      ).where((p) => _isCopySurface(_relativeTo(root, p))).toList();
      // Guards the guard: a discovery or parser that silently reads nothing
      // reports every sample clean.
      expect(
        surfaces.length,
        greaterThanOrEqualTo(4),
        reason: 'the sample discovery found too little to be trusted',
      );
      final walkthrough = surfaces.firstWhere(
        (p) => _relativeTo(
          root,
          p,
        ).endsWith('tom_specs_samples/full_lifecycle_walkthrough'),
      );
      expect(
        _declaredChainConstraints(walkthrough),
        contains('tom_specs_model'),
        reason: 'the pubspec scan read no constraint where one is declared',
      );

      final offenders = <String>[];
      for (final package in surfaces) {
        for (final MapEntry(key: name, value: constraint)
            in _declaredChainConstraints(package).entries) {
          final floor = _lowerBound(constraint);
          final newest = _newestCachedVersion(name);
          final rel = _relativeTo(root, package);
          if (floor == null) {
            offenders.add(
              '$rel declares $name "$constraint", which has no '
              'floor at all',
            );
          } else if (newest != null && _compareVersions(floor, newest) < 0) {
            offenders.add(
              '$rel declares $name "$constraint" while $newest is '
              'already in the pub cache',
            );
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'A sample is what a new project copies, so its floor should '
            'name the release it runs against — the current one. REMEDY: '
            'raise the floor, `dart pub upgrade` in the sample, and run it '
            '(`tool/run_all_samples.sh`). If it no longer works on the '
            'current release, that is the bug this guard exists to surface: '
            'fix the sample, do not lower the floor.\n${offenders.join('\n')}',
      );
    });
  });
}

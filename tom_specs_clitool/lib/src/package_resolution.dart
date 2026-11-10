/// Whether a Dart package was resolved (`dart pub get` run) on this host.
///
/// A package that declares dependencies but has no package config resolves
/// none of its imports: an analyser reads every imported type as unresolved, a
/// formatter falls back to the newest language version, documentation links
/// nothing. The gates and the analyzer bootstrap ask this one question so that
/// they agree on the answer; a fresh checkout is where it matters.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// Whether the pubspec at [packageRoot] declares a non-empty `dependencies:`.
/// A folder without a pubspec, or with no dependencies, needs no resolution.
bool declaresDependencies(String packageRoot) {
  final pubspec = File(p.join(packageRoot, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return false;
  return RegExp(
    r'^dependencies:\s*\n\s+\S',
    multiLine: true,
  ).hasMatch(pubspec.readAsStringSync());
}

/// Whether [packageRoot] is resolved: it needs no resolution
/// ([declaresDependencies] is false), or it has a package config in itself or
/// in a folder above it up to [containerRoot] (a pub workspace resolves its
/// members there).
bool isResolvedPackage(String packageRoot, String containerRoot) {
  if (!declaresDependencies(packageRoot)) return true;
  final stop = p.normalize(p.absolute(containerRoot));
  var dir = p.normalize(p.absolute(packageRoot));
  while (true) {
    if (File(p.join(dir, '.dart_tool', 'package_config.json')).existsSync()) {
      return true;
    }
    final parent = p.dirname(dir);
    if (dir == stop || parent == dir) return false;
    dir = parent;
  }
}

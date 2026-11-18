/// Formatting Dart with the `dart_style` linked into this package — the one
/// formatter every part of the clitool uses: the formatting gate, the
/// generators (`:model-spec-ops`, `:codespecs-areas`, the registry tests) and the dart-tom
/// mapper. No part of it runs `dart format` as a process, so a compiled
/// `tomspecs` needs no Dart SDK to format, and every part formats alike.
///
/// The formatter is pinned to the version of the workspace SDK's own
/// (`dart format --version`, [kDartStyleVersion]); `test/dart_style_pin_test.dart`
/// fails when the SDK moves past the pin, so the gate and a developer running
/// `dart format` by hand agree. Each file is formatted in its package's
/// language version, found the way `dart format` finds it
/// ([DartFormat.languageVersionOf]).
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// The `dart_style` version linked into this package. It is pinned in
/// `pubspec.yaml` to the formatter of the workspace SDK, and
/// `test/dart_style_pin_test.dart` holds this constant, the pin, the lock and
/// the SDK to one version.
const String kDartStyleVersion = '3.1.13';

/// A Dart source that does not parse, so it cannot be formatted.
class DartFormatFailure implements Exception {
  /// The file that does not parse.
  final String path;

  /// The formatter's message.
  final String message;

  /// The failure for [path].
  const DartFormatFailure(this.path, this.message);

  @override
  String toString() => 'dart format failed: $path: $message';
}

/// The linked formatter, with the language version of each file worked out
/// once per package.
class DartFormat {
  final Map<String, _PackageConfig?> _configs = {};
  final Map<String, Version> _pubspecVersions = {};
  final Map<Version, DartFormatter> _formatters = {};

  /// [source] as the formatter writes it, in the language version of the
  /// package [path] belongs to ([languageVersionOf]), or in
  /// [languageVersion] when given. Throws [DartFormatFailure] when [source]
  /// does not parse.
  String format(
    String source, {
    required String path,
    Version? languageVersion,
  }) {
    final version = languageVersion ?? languageVersionOf(path);
    final formatter = _formatters.putIfAbsent(
      version,
      () => DartFormatter(languageVersion: version),
    );
    try {
      return formatter.format(source, uri: path);
    } on FormatterException catch (e) {
      throw DartFormatFailure(path, e.message());
    }
  }

  /// Whether the file at [path] is as the formatter writes it.
  bool isFormatted(String path) {
    final text = File(path).readAsStringSync();
    return format(text, path: path) == text;
  }

  /// Formats the file at [path] in place; returns whether it changed.
  bool formatFile(String path, {Version? languageVersion}) {
    final file = File(path);
    final text = file.readAsStringSync();
    final formatted = format(
      text,
      path: path,
      languageVersion: languageVersion,
    );
    if (formatted == text) return false;
    file.writeAsStringSync(formatted);
    return true;
  }

  /// The language version `dart format` formats [path] in: the
  /// `languageVersion` of the package that holds it in the nearest
  /// `.dart_tool/package_config.json` above it (the latest version for a file
  /// that config gives no package); with no config above it, the lower bound
  /// of the SDK constraint of the nearest `pubspec.yaml` (a package not
  /// resolved yet, or generated output); else
  /// [DartFormatter.latestLanguageVersion].
  Version languageVersionOf(String path) {
    final file = p.normalize(p.absolute(path));
    for (var dir = p.dirname(file); ; dir = p.dirname(dir)) {
      final config = _configs.putIfAbsent(dir, () => _PackageConfig.read(dir));
      if (config != null) {
        // The nearest config decides, as for `dart format`: the package that
        // holds the file, or the latest version for a file of no package.
        return config.languageVersionOf(file) ??
            DartFormatter.latestLanguageVersion;
      }
      final parent = p.dirname(dir);
      if (parent == dir) break;
    }
    // No package config above the file (a package not resolved yet, or
    // generated output): the nearest pubspec's SDK lower bound.
    for (var dir = p.dirname(file); ; dir = p.dirname(dir)) {
      if (File(p.join(dir, 'pubspec.yaml')).existsSync()) {
        return _pubspecVersions.putIfAbsent(
          dir,
          () => pubspecLanguageVersion(dir),
        );
      }
      final parent = p.dirname(dir);
      if (parent == dir) break;
    }
    return DartFormatter.latestLanguageVersion;
  }
}

/// The language version of the package in [packageDir]: the lower bound of
/// the SDK constraint in its `pubspec.yaml` (major.minor), as pub writes it
/// into the package config; [DartFormatter.latestLanguageVersion] when there
/// is no pubspec or it states no lower bound. Only [packageDir] itself is
/// read.
Version pubspecLanguageVersion(String packageDir) {
  final pubspec = File(p.join(packageDir, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return DartFormatter.latestLanguageVersion;
  try {
    final doc = loadYaml(pubspec.readAsStringSync());
    final sdk = doc is YamlMap && doc['environment'] is YamlMap
        ? (doc['environment'] as YamlMap)['sdk']
        : null;
    if (sdk is! String) return DartFormatter.latestLanguageVersion;
    final constraint = VersionConstraint.parse(sdk);
    if (constraint is VersionRange && constraint.min != null) {
      final min = constraint.min!;
      return Version(min.major, min.minor, 0);
    }
  } on FormatException {
    // An unreadable pubspec (YAML or the constraint) is no reason to refuse
    // formatting: `dart format` falls back to the latest version too.
  }
  return DartFormatter.latestLanguageVersion;
}

/// One `.dart_tool/package_config.json`: each package's root folder and
/// language version.
class _PackageConfig {
  final List<(String root, Version? version)> _packages;

  _PackageConfig(this._packages);

  /// The config in [dir]/.dart_tool, or null when there is none or it does
  /// not read.
  static _PackageConfig? read(String dir) {
    final file = File(p.join(dir, '.dart_tool', 'package_config.json'));
    if (!file.existsSync()) return null;
    try {
      final json = jsonDecode(file.readAsStringSync());
      final packages = <(String, Version?)>[];
      for (final entry in (json['packages'] as List? ?? const [])) {
        if (entry is! Map) continue;
        final rootUri = entry['rootUri'];
        if (rootUri is! String) continue;
        final base = Uri.directory(p.join(dir, '.dart_tool'));
        final root = p.normalize(p.fromUri(base.resolve(rootUri)));
        final lv = entry['languageVersion'];
        Version? version;
        if (lv is String) {
          final parts = lv.split('.');
          if (parts.length == 2) {
            version = Version(int.parse(parts[0]), int.parse(parts[1]), 0);
          }
        }
        packages.add((root, version));
      }
      return _PackageConfig(packages);
    } on Object {
      return null;
    }
  }

  /// The language version of the package whose root holds [file] (the
  /// deepest such root), or null when no package holds it.
  Version? languageVersionOf(String file) {
    String? best;
    Version? version;
    for (final (root, v) in _packages) {
      if (!p.isWithin(root, file)) continue;
      if (best == null || root.length > best.length) {
        best = root;
        version = v;
      }
    }
    return best == null
        ? null
        : (version ?? DartFormatter.latestLanguageVersion);
  }
}

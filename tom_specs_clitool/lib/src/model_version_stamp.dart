import 'dart:io';

import 'package:path/path.dart' as p;

/// The model version stamp generated into `tom_specs_model` by
/// `buildkit :versioner`.
///
/// Every artifact the build stamps with a model version — the two committed
/// `spec_model.json` assets, the nine `spec_model.meta.json` files, the DocSpecs
/// schema version — derives it from this one file, so they cannot disagree
/// about which model they were generated against.
class ModelVersionStamp {
  /// Records one parsed stamp.
  ///
  /// [buildTime] alone defaults to empty: a stamp always has a version, a
  /// build number and a commit, but the timestamp is absent from stamps
  /// produced where the build environment does not supply one.
  const ModelVersionStamp({
    required this.version,
    required this.buildNumber,
    required this.gitCommit,
    this.buildTime = '',
  });

  /// The semantic version (e.g. `1.0.0`).
  final String version;

  /// The monotonically increasing build counter.
  final int buildNumber;

  /// The short git commit the build ran against; empty when unavailable.
  final String gitCommit;

  /// The ISO-8601 build timestamp; empty when the stamp does not carry one.
  final String buildTime;

  /// The integer model version counter (S2): the major component of [version].
  int get majorVersion => int.tryParse(version.split('.').first.trim()) ?? 1;

  /// A human-readable build label (e.g. `1.0.0+3.abc1234`).
  String get label {
    final commit = gitCommit.isEmpty ? '' : '.$gitCommit';
    return '$version+$buildNumber$commit';
  }
}

/// Thrown when the version stamp is missing or unparseable.
class ModelVersionStampException implements Exception {
  /// Reports a missing or unparseable stamp, described by [message].
  ModelVersionStampException(this.message);

  /// What went wrong, phrased so the reader knows whether to re-run
  /// `buildkit :versioner` or to look at a corrupted generated file.
  ///
  /// Surfaced verbatim by `toString`, with no exception-class prefix: this
  /// reaches a build log, where the class name adds nothing.
  final String message;
  @override
  String toString() => message;
}

/// The model version `tom_specs_model/pubspec.yaml` commits: the version every
/// host agrees on.
///
/// The versioner's stamp is generated per host and is not committed (its build
/// number churns every run), so a check of committed artefacts on a host that
/// did not generate them reads the version from here, never from the stamp.
/// Throws a [ModelVersionStampException] when the pubspec has no `version:`.
String readCommittedModelVersion(String modelDir) {
  final pubspec = File(p.join(modelDir, 'pubspec.yaml'));
  final match = pubspec.existsSync()
      ? RegExp(
          r'^version:\s*(\S+)\s*$',
          multiLine: true,
        ).firstMatch(pubspec.readAsStringSync())
      : null;
  if (match == null) {
    throw ModelVersionStampException('No `version:` in ${pubspec.path}.');
  }
  return match.group(1)!;
}

/// The path of the generated stamp source inside [modelDir].
String modelVersionStampPath(String modelDir) =>
    p.join(modelDir, 'lib', 'src', 'version.versioner.dart');

/// Parses the stamp produced by `buildkit :versioner` in [modelDir].
///
/// Throws a [ModelVersionStampException] when the file is absent (the versioner
/// step has not run), carries no `version` field, or names another version
/// than the committed pubspec (a stamp left from an earlier build on this
/// host, which would stamp the generated artefacts with the wrong model).
ModelVersionStamp readModelVersionStamp(String modelDir) {
  final file = File(modelVersionStampPath(modelDir));
  if (!file.existsSync()) {
    throw ModelVersionStampException(
      'Version stamp not found at ${file.path} '
      '(run `buildkit :versioner` in the model package first).',
    );
  }
  final src = file.readAsStringSync();
  String str(String field) =>
      RegExp("$field\\s*=\\s*'([^']*)'").firstMatch(src)?.group(1) ?? '';
  int num(String field) =>
      int.tryParse(
        RegExp('$field\\s*=\\s*(\\d+)').firstMatch(src)?.group(1) ?? '',
      ) ??
      0;
  final version = str('version');
  if (version.isEmpty) {
    throw ModelVersionStampException(
      'Could not parse `version` from ${file.path}.',
    );
  }
  final committed = readCommittedModelVersion(modelDir);
  if (version != committed) {
    throw ModelVersionStampException(
      'The version stamp at ${file.path} is $version but '
      '${p.join(modelDir, 'pubspec.yaml')} is $committed: the stamp is left '
      'from an earlier build (run `buildkit :versioner` in the model package).',
    );
  }
  return ModelVersionStamp(
    version: version,
    buildNumber: num('buildNumber'),
    gitCommit: str('gitCommit'),
    buildTime: str('buildTime'),
  );
}

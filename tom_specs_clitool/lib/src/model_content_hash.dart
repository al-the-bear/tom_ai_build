/// The content identity of a spec-model meta-data file (`modelHash`).
///
/// Two copies of a model can carry the same package version and the same
/// `generatedAt` and still differ: both are taken from the model's version
/// stamp, which a model edit does not move until somebody bumps it. A consumer
/// that holds a packaged copy (the VS Code extension's vendored facade, a CLI's
/// bundled meta) therefore cannot tell from either stamp that its model is
/// stale. `modelHash` is the one stamp derived from the content itself, so two
/// metas carry the same hash exactly when they describe the same model.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The meta keys that say *which build* a file came from rather than *what
/// model* it describes. They are left out of [specModelContentHash] so a
/// version bump with no model change keeps the hash, and a model change with no
/// version bump changes it — which is what lets the two be told apart.
const Set<String> specModelHashExcludedKeys = {
  'generatedAt',
  'modelVersion',
  'modelVersionLabel',
  'modelHash',
};

/// The sha256 (lowercase hex) of [meta]'s canonical JSON, without the keys in
/// [specModelHashExcludedKeys].
///
/// Canonical means every map's keys are sorted at every depth, so the hash is a
/// property of the content and not of the order a generator happened to write
/// it in; list order is kept, because in the meta it is meaningful (roots in
/// document order, fields in serialization order).
String specModelContentHash(Map<dynamic, dynamic> meta) {
  final content = <String, Object?>{
    for (final e in meta.entries)
      if (!specModelHashExcludedKeys.contains(e.key)) e.key as String: e.value,
  };
  return sha256
      .convert(utf8.encode(jsonEncode(_canonical(content))))
      .toString();
}

Object? _canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k as String).toList()..sort();
    return {for (final k in keys) k: _canonical(value[k])};
  }
  if (value is List) return [for (final v in value) _canonical(v)];
  return value;
}

/// The warning `generate_som` prints when the model's content changed since the
/// last canonical run but its version did not, or `null` when there is nothing
/// to say.
///
/// A model change is expected to come with at least a patch bump of
/// `tom_specs_model` (`buildkit -p . :bumpversion`): consumers that receive the
/// model through local paths rather than a publish compare versions, and a
/// change under an unchanged version is invisible to them. [previousHash] /
/// [previousVersion] come from the committed stamp; either being `null` (a
/// stamp written before the hash existed) means there is no baseline yet.
String? modelChangeWithoutVersionBump({
  required String? previousHash,
  required String? previousVersion,
  required String modelHash,
  required String version,
}) {
  if (previousHash == null || previousVersion == null) return null;
  if (previousHash == modelHash || previousVersion != version) return null;
  return 'the model changed (modelHash ${previousHash.substring(0, 12)}… → '
      '${modelHash.substring(0, 12)}…) but tom_specs_model is still $version. '
      'A consumer holding a $version copy cannot tell it is stale: bump the '
      'model (`buildkit -p . :bumpversion` in tom_specs_model, at least a '
      'patch) and regenerate.';
}

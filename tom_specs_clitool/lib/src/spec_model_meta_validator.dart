/// On-disk schema for the lossless spec-model meta-data file (the
/// `spec_model.json` successor) and a validator that rejects malformed files.
///
/// The meta-data file is the resolved class graph emitted by
/// `ModelJsonExporter`; the generic runtime's meta-model loader reads it to
/// describe and traverse any document by path. Two independent version stamps
/// live in the file and must not be conflated:
///
/// * **[specModelMetaSchemaVersion]** — the *file format's* own version
///   (`metaSchemaVersion`). It changes only when the on-disk shape changes, and
///   lets a reader refuse a file produced by a newer, unknown format.
/// * **`modelVersion` / `modelVersionLabel`** — *which model version* the
///   meta-data was generated against (the `tom_specs_model` version stamp).
///   It changes every time the object model changes, independent of the format.
library;

/// The on-disk meta-data schema version this build understands. Bump only when
/// the file's structure changes in a way older readers cannot parse.
const int specModelMetaSchemaVersion = 1;

/// Top-level keys every meta-data file must carry. `modelVersionLabel` and
/// `containerRoot` are intentionally absent: the label is optional and the
/// container root is legitimately `null` for a container-less model.
const Set<String> requiredSpecModelMetaKeys = {
  'metaSchemaVersion',
  'modelVersion',
  'generatedAt',
  'classCount',
  'rootCount',
  'roots',
  'classes',
};

/// Validates a decoded meta-data map against schema version
/// [specModelMetaSchemaVersion]. Returns a list of human-readable error
/// strings; an empty list means the meta-data conforms and is safe to load.
///
/// The checks, in order: the root is a JSON object; every key in
/// [requiredSpecModelMetaKeys] is present; the required values carry the
/// expected JSON types; and the file's `metaSchemaVersion` is not newer than
/// this build supports (a newer format is unreadable, so it is rejected).
List<String> validateSpecModelMeta(Object? meta) {
  final errors = <String>[];

  if (meta is! Map) {
    return [
      'meta-data root must be a JSON object, got ${meta.runtimeType}',
    ];
  }

  for (final key in requiredSpecModelMetaKeys) {
    if (!meta.containsKey(key)) {
      errors.add('missing required key "$key"');
    }
  }

  _expectType<int>(meta, 'metaSchemaVersion', errors);
  _expectType<int>(meta, 'modelVersion', errors);
  _expectType<int>(meta, 'classCount', errors);
  _expectType<int>(meta, 'rootCount', errors);
  _expectType<String>(meta, 'generatedAt', errors);
  _expectType<List>(meta, 'roots', errors);
  _expectType<Map>(meta, 'classes', errors);

  final schemaVersion = meta['metaSchemaVersion'];
  if (schemaVersion is int && schemaVersion > specModelMetaSchemaVersion) {
    errors.add(
      'metaSchemaVersion $schemaVersion is newer than the supported '
      'version $specModelMetaSchemaVersion — this build cannot read it',
    );
  }

  return errors;
}

/// Adds a type error when [key] is present but not a [T]. A missing key is
/// already reported by the required-key pass, so it is skipped here.
void _expectType<T>(Map meta, String key, List<String> errors) {
  if (!meta.containsKey(key)) return;
  final value = meta[key];
  if (value is! T) {
    errors.add('key "$key" must be a $T, got ${value.runtimeType}');
  }
}

import 'dart:convert';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show SpecDocumentYaml;

/// Generates a standalone JSON Schema (Draft-07) for the on-disk
/// `*.docspecs.yaml` **document wire format** (followup item 12, D20).
///
/// This is deliberately *not* a per-root DocSpecs schema (those are produced by
/// [DocSpecsSchemaGenerator] and describe the section grammar of one document
/// root). This schema describes the **generic file shape** every
/// `*.docspecs.yaml` shares regardless of which model root it carries — the
/// passes written by `SpecDocumentYaml.encode`:
///
/// ```yaml
/// version: 1                 # on-disk format version (required)
/// modelVersion: "1.0"        # authoring object-model major.minor (optional)
/// document:                  # the live object-model values (optional pass)
///   content:                 #   section path -> text value
///   forms:                   #   section path -> (field name -> value)
///   lists:                   #   list path -> { seq, items }
/// review:                    # editor structural-review pass (optional, opaque)
/// ```
///
/// It validates the structural envelope (key shapes and value types), not the
/// section ids themselves: a `*.docspecs.yaml` can be schema-validated as a
/// well-formed document file independently of the DocSpecs per-root schemas, so
/// a saved file is checkable without resolving its model.
///
/// **Tolerance matches the codec, not stricter.** `SpecDocumentYaml.decode`
/// loads a partial/hand-written file by treating any missing pass as empty, so
/// only `version` is required here; `document` and its three sub-passes are all
/// optional. The schema rejects what the format genuinely cannot represent —
/// unknown top-level/pass keys, a non-integer `version`, non-string content or
/// form values, a malformed list entry (missing `seq`/`items`, wrong types).
class DocspecsYamlSchemaGenerator {
  /// The JSON Schema `$id` for the emitted document-format schema.
  static const String schemaId =
      'https://tom.ai/schemas/yaml/docspecs-document.schema.json';

  /// The default on-disk filename for the emitted schema.
  static const String fileName = 'docspecs-document.schema.json';

  /// The on-disk format version the schema targets. Sourced from the codec so
  /// the schema and the writer stay in lockstep.
  final int formatVersion;

  DocspecsYamlSchemaGenerator({int? formatVersion})
      : formatVersion = formatVersion ?? SpecDocumentYaml.formatVersion;

  /// Builds the Draft-07 JSON Schema as a plain JSON-encodable map.
  Map<String, Object?> generate() {
    return {
      r'$schema': 'http://json-schema.org/draft-07/schema#',
      r'$id': schemaId,
      'title': 'TomSpecs Document (*.docspecs.yaml)',
      'description': 'Structural schema for the generic on-disk TomSpecs '
          'document wire format written by SpecDocumentYaml.encode '
          '(format version $formatVersion). Validates the file envelope and '
          'pass value-types, independently of any per-root DocSpecs schema.',
      'type': 'object',
      'required': <String>['version'],
      'additionalProperties': false,
      'properties': <String, Object?>{
        'version': {
          'const': formatVersion,
          'description':
              'On-disk format version (independent of the model stamp).',
        },
        'modelVersion': {
          'type': 'string',
          'pattern': r'^[0-9]+\.[0-9]+$',
          'description': 'Authoring object-model version (major.minor) the '
              'content was last written against.',
        },
        'document': {r'$ref': r'#/$defs/document'},
        'review': {
          'type': 'object',
          'description': 'Optional editor structural-review pass; opaque to the '
              'runtime, so its inner shape is unconstrained.',
          'additionalProperties': true,
        },
      },
      r'$defs': <String, Object?>{
        'document': {
          'type': 'object',
          'description': 'The live object-model values, keyed by full section '
              'path. Any missing pass decodes as empty.',
          'additionalProperties': false,
          'properties': <String, Object?>{
            'content': {r'$ref': r'#/$defs/contentMap'},
            'forms': {r'$ref': r'#/$defs/formsMap'},
            'lists': {r'$ref': r'#/$defs/listsMap'},
          },
        },
        'contentMap': {
          'type': 'object',
          'description':
              'Content/scalar leaves: section path -> text value.',
          'additionalProperties': {'type': 'string'},
        },
        'formsMap': {
          'type': 'object',
          'description': '@Form sections: section path -> (field name -> '
              'text value).',
          'additionalProperties': {
            'type': 'object',
            'additionalProperties': {'type': 'string'},
          },
        },
        'listsMap': {
          'type': 'object',
          'description': 'Lists: list path -> ordered item entry.',
          'additionalProperties': {r'$ref': r'#/$defs/listEntry'},
        },
        'listEntry': {
          'type': 'object',
          'description': 'A list pass entry: a monotonic sequence counter and '
              'the ordered item paths.',
          'required': <String>['seq', 'items'],
          'additionalProperties': false,
          'properties': <String, Object?>{
            'seq': {
              'type': 'integer',
              'minimum': 0,
              'description':
                  'Per-list monotonic counter; never reused (item paths are '
                      '<listPath>-<seq>).',
            },
            'items': {
              'type': 'array',
              'description': 'Ordered item paths in the list.',
              'items': {'type': 'string'},
            },
          },
        },
      },
    };
  }

  /// The emitted schema as pretty-printed, newline-terminated JSON text.
  String toJsonString() =>
      '${const JsonEncoder.withIndent('  ').convert(generate())}\n';
}

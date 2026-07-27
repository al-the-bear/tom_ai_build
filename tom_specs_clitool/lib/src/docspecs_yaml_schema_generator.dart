import 'dart:convert';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show SpecDocumentYaml;

/// Generates a standalone JSON Schema (Draft-07) for the on-disk
/// `*.docspecs.yaml` **document wire format**.
///
/// This is deliberately *not* a per-root DocSpecs schema (those are produced by
/// [DocSpecsSchemaGenerator] and describe the section grammar of one document
/// root). This schema describes the **generic file shape** every
/// `*.docspecs.yaml` shares regardless of which model root it carries — the
/// hierarchical v2 envelope written by `SpecDocumentYaml.encode` (DR1 §2):
///
/// ```yaml
/// version: 2                 # on-disk format version (required)
/// modelVersion: "1.0"        # authoring object-model major.minor (optional)
/// document:                  # the live object-model values (optional pass)
///   DEMO Demo:               #   exactly one root key; nested section tree
///     TTL title: |2-         #   scalar leaves (content/scalar/enum/form
///       Hello                #   fields) or nested mappings (sections, form
///     DET details:           #   blocks, list containers, list items)
///       owner: Bob
/// review:                    # editor structural-review pass (optional, opaque)
/// ```
///
/// It validates the structural envelope (key shapes and value nesting), not
/// the section ids themselves: a `*.docspecs.yaml` can be schema-validated as
/// a well-formed document file independently of the DocSpecs per-root schemas,
/// so a saved file is checkable without resolving its model.
///
/// **Tolerance matches the codec, not stricter.** `SpecDocumentYaml.decode`
/// treats a missing/empty `document:` pass as an empty document, so only
/// `version` is required here. Inside the tree the node *types* are
/// model-dependent (only the codec's metadata walk can tell a form block from
/// a section), so a node is any scalar leaf or a mapping of nodes. The schema
/// rejects what the format genuinely cannot represent — unknown top-level
/// keys, a non-integer `version`, more than one document root key, or a
/// scalar in root position.
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
          '(hierarchical format version $formatVersion). Validates the file '
          'envelope and value nesting, independently of any per-root DocSpecs '
          'schema.',
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
          'description': 'Optional editor structural-review pass; opaque to '
              'the runtime, so its inner shape is unconstrained.',
          'additionalProperties': true,
        },
      },
      r'$defs': <String, Object?>{
        'document': {
          'type': 'object',
          'description': 'The live object-model values as one nested section '
              'tree under a single document-root key ("<SECTION-ID> '
              '<memberName>"). An empty mapping decodes as an empty document.',
          'maxProperties': 1,
          'additionalProperties': {
            'type': 'object',
            'description': 'The root section body — a mapping of child nodes '
                '(a scalar in root position is rejected by the codec).',
            'additionalProperties': {r'$ref': r'#/$defs/node'},
          },
        },
        'node': {
          'description': 'One section-tree node: a scalar leaf '
              '(content/scalar/enum value or form field) or a nested mapping '
              '(section, form block, list container, list item). Which one is '
              'legal at a given position is model-dependent and enforced by '
              'the codec metadata walk, not this envelope schema.',
          'anyOf': <Object?>[
            {
              'type': <String>['string', 'number', 'boolean', 'null'],
            },
            {
              'type': 'object',
              'additionalProperties': {r'$ref': r'#/$defs/node'},
            },
          ],
        },
      },
    };
  }

  /// The emitted schema as pretty-printed, newline-terminated JSON text.
  String toJsonString() =>
      '${const JsonEncoder.withIndent('  ').convert(generate())}\n';
}

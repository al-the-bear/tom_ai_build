import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Tests for [DocspecsYamlSchemaGenerator] (followup item 12, D20): the
/// standalone JSON Schema for the generic on-disk `*.docspecs.yaml` document
/// wire format. The schema must accept a known-good document and reject
/// documents the format genuinely cannot represent.

/// Converts a `loadYaml` result (YamlMap/YamlList) into a plain JSON-compatible
/// structure the validator understands.
Object? _plain(Object? yaml) => json.decode(json.encode(yaml));

/// The compiled Draft-07 schema produced by the generator.
JsonSchema _buildSchema() =>
    JsonSchema.create(DocspecsYamlSchemaGenerator().generate());

/// A minimal, valid in-memory document (plain JSON-compatible maps).
Map<String, Object?> _validDoc() => <String, Object?>{
      'version': DocspecsYamlSchemaGenerator().formatVersion,
      'modelVersion': '1.0',
      'document': <String, Object?>{
        'content': <String, Object?>{'DEMO/title': 'Hello'},
        'forms': <String, Object?>{
          'DEMO/details': <String, Object?>{'owner': 'Bob'},
        },
        'lists': <String, Object?>{
          'DEMO/items': <String, Object?>{
            'seq': 2,
            'items': <Object?>['DEMO/items-1', 'DEMO/items-2'],
          },
        },
      },
    };

void main() {
  group('DocspecsYamlSchemaGenerator metadata', () {
    test('exposes a stable schema id and filename', () {
      expect(DocspecsYamlSchemaGenerator.schemaId,
          'https://tom.ai/schemas/yaml/docspecs-document.schema.json');
      expect(DocspecsYamlSchemaGenerator.fileName,
          'docspecs-document.schema.json');
    });

    test('defaults the format version to the codec constant', () {
      // SpecDocumentYaml.formatVersion is currently 1; the generator must track
      // it so the schema and the writer stay in lockstep.
      expect(DocspecsYamlSchemaGenerator().formatVersion, 1);
    });

    test('honours an explicit format version override', () {
      final gen = DocspecsYamlSchemaGenerator(formatVersion: 7);
      final schema = gen.generate();
      final version =
          (schema['properties'] as Map)['version'] as Map<String, Object?>;
      expect(version['const'], 7);
    });

    test('toJsonString emits parseable, newline-terminated JSON', () {
      final text = DocspecsYamlSchemaGenerator().toJsonString();
      expect(text.endsWith('\n'), isTrue);
      final decoded = json.decode(text) as Map<String, Object?>;
      expect(decoded[r'$schema'], 'http://json-schema.org/draft-07/schema#');
      expect(decoded[r'$id'], DocspecsYamlSchemaGenerator.schemaId);
    });
  });

  group('schema accepts well-formed documents', () {
    test('validates a full in-memory document', () {
      expect(_buildSchema().validate(_validDoc()).isValid, isTrue);
    });

    test('validates a partial document (only version)', () {
      // The codec decodes a missing pass as empty, so a bare `version` is a
      // legitimate, schema-valid file.
      expect(
        _buildSchema().validate(<String, Object?>{'version': 1}).isValid,
        isTrue,
      );
    });

    test('validates the known-good corpus expected.docspecs.yaml', () {
      final corpus = File(p.join(
        Directory.current.path,
        '..',
        'tom_som_conformance',
        'corpus',
        'expected.docspecs.yaml',
      ));
      expect(corpus.existsSync(), isTrue,
          reason: 'corpus fixture missing: ${corpus.path}');
      final doc = _plain(loadYaml(corpus.readAsStringSync()));
      final results = _buildSchema().validate(doc);
      expect(results.isValid, isTrue,
          reason: 'corpus rejected: ${results.errors}');
    });

    test('accepts an optional opaque review pass', () {
      final doc = _validDoc()
        ..['review'] = <String, Object?>{'anything': <String, Object?>{}};
      expect(_buildSchema().validate(doc).isValid, isTrue);
    });
  });

  group('schema rejects malformed documents', () {
    late JsonSchema schema;
    setUp(() => schema = _buildSchema());

    test('rejects a document missing version', () {
      final doc = _validDoc()..remove('version');
      expect(schema.validate(doc).isValid, isFalse);
    });

    test('rejects a non-integer version', () {
      final doc = _validDoc()..['version'] = '1';
      expect(schema.validate(doc).isValid, isFalse);
    });

    test('rejects a wrong format version', () {
      final doc = _validDoc()..['version'] = 99;
      expect(schema.validate(doc).isValid, isFalse);
    });

    test('rejects a malformed modelVersion', () {
      final doc = _validDoc()..['modelVersion'] = '1';
      expect(schema.validate(doc).isValid, isFalse);
    });

    test('rejects an unknown top-level key', () {
      final doc = _validDoc()..['stray'] = true;
      expect(schema.validate(doc).isValid, isFalse);
    });

    test('rejects an unknown document pass key', () {
      final doc = _validDoc();
      (doc['document'] as Map)['extra'] = <String, Object?>{};
      expect(schema.validate(doc).isValid, isFalse);
    });

    test('rejects a non-string content value', () {
      final doc = _validDoc();
      ((doc['document'] as Map)['content'] as Map)['DEMO/count'] = 3;
      expect(schema.validate(doc).isValid, isFalse);
    });

    test('rejects a non-string form field value', () {
      final doc = _validDoc();
      (((doc['document'] as Map)['forms'] as Map)['DEMO/details'] as Map)['owner'] =
          42;
      expect(schema.validate(doc).isValid, isFalse);
    });

    test('rejects a list entry missing seq', () {
      final doc = _validDoc();
      (doc['document'] as Map)['lists'] = <String, Object?>{
        'DEMO/items': <String, Object?>{
          'items': <Object?>['DEMO/items-1'],
        },
      };
      expect(schema.validate(doc).isValid, isFalse);
    });

    test('rejects a list entry with non-array items', () {
      final doc = _validDoc();
      (doc['document'] as Map)['lists'] = <String, Object?>{
        'DEMO/items': <String, Object?>{'seq': 1, 'items': 'nope'},
      };
      expect(schema.validate(doc).isValid, isFalse);
    });

    test('rejects a list entry with an unknown key', () {
      final doc = _validDoc();
      (doc['document'] as Map)['lists'] = <String, Object?>{
        'DEMO/items': <String, Object?>{
          'seq': 1,
          'items': <Object?>[],
          'oops': true,
        },
      };
      expect(schema.validate(doc).isValid, isFalse);
    });
  });
}

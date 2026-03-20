import 'package:test/test.dart';
import 'package:tom_doc_specs/src/schema/schema_loader.dart';

void main() {
  group('SchemaFilenameParser', () {
    group('isSchemaFile', () {
      test('accepts .docspecs-schema.yaml', () {
        expect(SchemaFilenameParser.isSchemaFile('spec.docspecs-schema.yaml'), isTrue);
      });

      test('accepts .docspecs-schema.yml', () {
        expect(SchemaFilenameParser.isSchemaFile('spec.docspecs-schema.yml'), isTrue);
      });

      test('rejects non-schema files', () {
        expect(SchemaFilenameParser.isSchemaFile('spec.yaml'), isFalse);
        expect(SchemaFilenameParser.isSchemaFile('spec.json'), isFalse);
      });
    });

    group('parse', () {
      test('parses dash-separated name-version', () {
        final result = SchemaFilenameParser.parse('spec-1.0.docspecs-schema.yaml');
        expect(result, isNotNull);
        expect(result!.id, 'spec');
        expect(result.version, '1.0');
      });

      test('parses dot-separated name.version', () {
        final result = SchemaFilenameParser.parse('specification.1.0.docspecs-schema.yaml');
        expect(result, isNotNull);
        expect(result!.id, 'specification');
        expect(result.version, '1.0');
      });

      test('parses major.minor.patch with dash separator', () {
        final result = SchemaFilenameParser.parse('spec-1.2.3.docspecs-schema.yaml');
        expect(result, isNotNull);
        expect(result!.id, 'spec');
        expect(result.version, '1.2.3');
      });

      test('parses major.minor.patch with dot separator', () {
        final result = SchemaFilenameParser.parse('specification.1.2.3.docspecs-schema.yaml');
        expect(result, isNotNull);
        expect(result!.id, 'specification');
        expect(result.version, '1.2.3');
      });

      test('parses hyphenated name with dash-separated version', () {
        final result = SchemaFilenameParser.parse('quest-overview-1.0.docspecs-schema.yaml');
        expect(result, isNotNull);
        expect(result!.id, 'quest-overview');
        expect(result.version, '1.0');
      });

      test('parses hyphenated name with dot-separated version', () {
        final result = SchemaFilenameParser.parse('quest-overview.1.0.docspecs-schema.yaml');
        expect(result, isNotNull);
        expect(result!.id, 'quest-overview');
        expect(result.version, '1.0');
      });

      test('defaults version to 1.0 when no version present', () {
        final result = SchemaFilenameParser.parse('specification.docspecs-schema.yaml');
        expect(result, isNotNull);
        expect(result!.id, 'specification');
        expect(result.version, '1.0');
      });

      test('returns null for non-schema file', () {
        final result = SchemaFilenameParser.parse('readme.md');
        expect(result, isNull);
      });

      test('parses .yml extension', () {
        final result = SchemaFilenameParser.parse('spec-2.1.docspecs-schema.yml');
        expect(result, isNotNull);
        expect(result!.id, 'spec');
        expect(result.version, '2.1');
      });
    });
  });
}

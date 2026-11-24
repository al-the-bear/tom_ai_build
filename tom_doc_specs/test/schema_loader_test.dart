import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_doc_specs/tom_doc_specs.dart';

const _schemaYaml = '''
section-types:
  note:
    prefix: note
document:
  sections:
    overview:
      section-type: note
''';

const _document = '''<!-- docspec: probe/1.0 -->
# <!--[doc]--> Probe

## <!--[note-1]--> Overview

Some text.
''';

void main() {
  group('SchemaFilenameParser', () {
    group('isSchemaFile', () {
      test('accepts .docspecs-schema.yaml', () {
        expect(
          SchemaFilenameParser.isSchemaFile('spec.docspecs-schema.yaml'),
          isTrue,
        );
      });

      test('accepts .docspecs-schema.yml', () {
        expect(
          SchemaFilenameParser.isSchemaFile('spec.docspecs-schema.yml'),
          isTrue,
        );
      });

      test('rejects non-schema files', () {
        expect(SchemaFilenameParser.isSchemaFile('spec.yaml'), isFalse);
        expect(SchemaFilenameParser.isSchemaFile('spec.json'), isFalse);
      });
    });

    group('parse', () {
      test('parses dash-separated name-version', () {
        final result = SchemaFilenameParser.parse(
          'spec-1.0.docspecs-schema.yaml',
        );
        expect(result, isNotNull);
        expect(result!.id, 'spec');
        expect(result.version, '1.0');
      });

      test('parses dot-separated name.version', () {
        final result = SchemaFilenameParser.parse(
          'specification.1.0.docspecs-schema.yaml',
        );
        expect(result, isNotNull);
        expect(result!.id, 'specification');
        expect(result.version, '1.0');
      });

      test('parses major.minor.patch with dash separator', () {
        final result = SchemaFilenameParser.parse(
          'spec-1.2.3.docspecs-schema.yaml',
        );
        expect(result, isNotNull);
        expect(result!.id, 'spec');
        expect(result.version, '1.2.3');
      });

      test('parses major.minor.patch with dot separator', () {
        final result = SchemaFilenameParser.parse(
          'specification.1.2.3.docspecs-schema.yaml',
        );
        expect(result, isNotNull);
        expect(result!.id, 'specification');
        expect(result.version, '1.2.3');
      });

      test('parses hyphenated name with dash-separated version', () {
        final result = SchemaFilenameParser.parse(
          'quest-overview-1.0.docspecs-schema.yaml',
        );
        expect(result, isNotNull);
        expect(result!.id, 'quest-overview');
        expect(result.version, '1.0');
      });

      test('parses hyphenated name with dot-separated version', () {
        final result = SchemaFilenameParser.parse(
          'quest-overview.1.0.docspecs-schema.yaml',
        );
        expect(result, isNotNull);
        expect(result!.id, 'quest-overview');
        expect(result.version, '1.0');
      });

      test('defaults version to 1.0 when no version present', () {
        final result = SchemaFilenameParser.parse(
          'specification.docspecs-schema.yaml',
        );
        expect(result, isNotNull);
        expect(result!.id, 'specification');
        expect(result.version, '1.0');
      });

      test('returns null for non-schema file', () {
        final result = SchemaFilenameParser.parse('readme.md');
        expect(result, isNull);
      });

      test('parses .yml extension', () {
        final result = SchemaFilenameParser.parse(
          'spec-2.1.docspecs-schema.yml',
        );
        expect(result, isNotNull);
        expect(result!.id, 'spec');
        expect(result.version, '2.1');
      });
    });
  });

  group('SchemaResolver from the Tom root', () {
    late Directory tree;
    late String root; // <tree>/root, holding .tom/tom_root.yaml
    late String docPath; // <root>/ws/project/docs/probe.md

    String schemaFolderOf(String folder) =>
        p.join(folder, '.tom', 'docspecs-schema');

    void writeSchema(String folder) {
      final dir = Directory(p.join(schemaFolderOf(folder), 'probe'))
        ..createSync(recursive: true);
      File(
        p.join(dir.path, 'probe.1.0.docspecs-schema.yaml'),
      ).writeAsStringSync(_schemaYaml);
    }

    setUp(() {
      tree = Directory.systemTemp.createTempSync('schema_root');
      root = p.join(p.canonicalize(tree.path), 'root');
      File(p.join(root, '.tom', 'tom_root.yaml'))
        ..createSync(recursive: true)
        ..writeAsStringSync('root: true\n');
      final docs = Directory(p.join(root, 'ws', 'project', 'docs'))
        ..createSync(recursive: true);
      docPath = p.join(docs.path, 'probe.md');
      File(docPath).writeAsStringSync(_document);
    });

    tearDown(() => tree.deleteSync(recursive: true));

    test('findTomRoot finds the folder holding .tom/tom_root.yaml', () {
      expect(SchemaResolver.findTomRoot(p.dirname(docPath)), root);
      expect(SchemaResolver.findTomRoot(root), root);
    });

    test('the local folders climb to the Tom root, past a workspace root '
        'below it, and no further', () {
      final ws = p.join(root, 'ws');
      expect(SchemaResolver.localSchemaFolders(docPath, ws), [
        schemaFolderOf(p.join(ws, 'project', 'docs')),
        schemaFolderOf(p.join(ws, 'project')),
        schemaFolderOf(ws),
        schemaFolderOf(root),
      ]);
    });

    test('without a Tom root they stop at the workspace root', () {
      File(p.join(root, '.tom', 'tom_root.yaml')).deleteSync();
      final ws = p.join(root, 'ws');
      expect(
        SchemaResolver.localSchemaFolders(docPath, ws).last,
        schemaFolderOf(ws),
      );
    });

    test('a workspace root above the Tom root is still searched', () {
      expect(
        SchemaResolver.localSchemaFolders(
          docPath,
          p.canonicalize(tree.path),
        ).last,
        schemaFolderOf(p.canonicalize(tree.path)),
      );
    });

    test("the root's schema is found whatever the workspace root is", () {
      writeSchema(root);
      for (final ws in [
        p.join(root, 'ws', 'project'),
        Directory.current.path,
      ]) {
        final doc = DocSpecs.scanDocumentSync(
          filePath: docPath,
          workspaceRoot: ws,
        );
        expect(doc.wasValidated, isTrue, reason: 'workspace root $ws');
        expect(doc.missingSchemaId, isNull);
        expect(doc.schemaSearchFolders, isEmpty);
      }
    });

    test('a declared schema that is not found is reported with the folders '
        'searched', () async {
      final ws = p.join(root, 'ws');
      final doc = await DocSpecs.scanDocument(
        filePath: docPath,
        workspaceRoot: ws,
      );
      expect(doc.wasValidated, isFalse);
      expect(doc.missingSchemaId, 'probe/1.0');
      expect(
        doc.schemaSearchFolders,
        SchemaResolver.searchFolders(documentPath: docPath, workspaceRoot: ws),
      );
      expect(doc.schemaSearchFolders, contains(schemaFolderOf(root)));

      final back = SpecDoc.fromJson(doc.toJson());
      expect(back.missingSchemaId, 'probe/1.0');
      expect(back.schemaSearchFolders, doc.schemaSearchFolders);
    });

    test('a document declaring no schema has no missing schema', () {
      File(docPath).writeAsStringSync('# Plain\n\nNo declaration.\n');
      final doc = DocSpecs.scanDocumentSync(filePath: docPath);
      expect(doc.wasValidated, isFalse);
      expect(doc.missingSchemaId, isNull);
      expect(doc.schemaSearchFolders, isEmpty);
    });
  });
}

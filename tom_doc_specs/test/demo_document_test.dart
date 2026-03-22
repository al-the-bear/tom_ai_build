import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_doc_scanner/tom_doc_scanner.dart';
import 'package:tom_doc_specs/src/doc_specs_factory.dart';
import 'package:tom_doc_specs/src/models/spec_doc.dart';
import 'package:tom_doc_specs/src/schema/schema_loader.dart';
import 'package:tom_doc_specs/src/validation/validator.dart';

String _fixturesPath() {
  final candidates = [
    p.join(Directory.current.path, 'test', 'fixtures'),
    p.join(Directory.current.path, 'tom_doc_specs', 'test', 'fixtures'),
  ];
  for (final c in candidates) {
    if (Directory(c).existsSync()) return c;
  }
  throw StateError(
      'Cannot find test/fixtures directory from ${Directory.current.path}');
}

void main() {
  late String fixturesPath;

  setUpAll(() {
    fixturesPath = _fixturesPath();
  });

  test('demo document (docspecs_test_document) validates without errors', () {
    final schemaPath =
        p.join(fixturesPath, 'schemas', 'specification.1.0.docspecs-schema.yaml');
    final docPath =
        p.join(fixturesPath, 'documents', 'docspecs-test-document.md');

    final schema = SchemaLoader.loadSync(schemaPath);
    final factory = DocSpecsFactory(schema: schema);

    final doc = DocScanner.scanDocumentSync(
      filepath: docPath,
      workspaceRoot: Directory.current.path,
      factory: factory,
    );

    final specDoc = doc as SpecDoc;
    final errors = DocSpecsValidator(schema: schema).validate(specDoc);

    // Print errors for debugging
    if (errors.isNotEmpty) {
      print('--- ${errors.length} validation errors ---');
      for (final e in errors) {
        print('  [${e.category}] ${e.message} (line ${e.lineNumber}, section: ${e.sectionId})');
      }
    }

    expect(errors, isEmpty,
        reason: 'Demo document should validate without errors');
  });
}

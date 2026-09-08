// The generate → scan → validate round trip.
//
// `DocSpecsSkeletonGenerator` emits `<!-- docspec: id/version -->` and
// `DocSpecs.scanDocument` has to read it back. Before this suite existed the
// two never met: a freshly generated skeleton scanned as schemaless, and a
// schemaless scan reports no errors — a vacuous pass on a document nothing
// checked.
//
// The round trip is the test that closes it, so the two ends cannot drift
// apart again without a red test.
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_doc_specs/tom_doc_specs.dart';

/// A schema with one required section, so an empty-but-generated document has
/// something concrete to be missing.
const String _schemaYaml = '''
title-format: "# {title}"
document:
  sections:
    overview:
      section-type: note
section-types:
  note:
    prefix: note
    required: true
    min-count: 1
''';

/// A document that satisfies [_schemaYaml] — a title, then the required `note`
/// section carrying its id in the heading.
const String _conformingDocument = '''
<!-- docspec: round-trip/1.0 -->
# Round Trip

## <!--[note-overview] --> Overview

Body.
''';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('docspecs_round_trip_');
    // `.tom/docspecs-schema/` is the folder `SchemaResolver` walks up to find
    // (schema_loader.dart, search order step 2).
    Directory('${dir.path}/.tom/docspecs-schema').createSync(recursive: true);
    File(
      '${dir.path}/.tom/docspecs-schema/round-trip-1.0.docspecs-schema.yaml',
    ).writeAsStringSync(_schemaYaml);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  DocSpecSchema loadSchema() => DocSpecs.loadSchemaSync(
    schemaId: 'round-trip/1.0',
    documentPath: '${dir.path}/doc.md',
    workspaceRoot: dir.path,
  );

  SpecDoc scan(String markdown, {String? schemaId}) {
    final path = '${dir.path}/doc.md';
    File(path).writeAsStringSync(markdown);
    return DocSpecs.scanDocumentSync(
      filePath: path,
      schemaId: schemaId,
      workspaceRoot: dir.path,
    );
  }

  group('the generator and the scanner agree about the schema header', () {
    test('a generated skeleton scans back with its own schema id', () {
      final skeleton = DocSpecsSkeletonGenerator.generate(loadSchema());
      expect(skeleton, contains('<!-- docspec: round-trip/1.0 -->'));

      final doc = scan(skeleton);
      expect(
        doc.schemaId,
        'round-trip/1.0',
        reason:
            'the header the generator wrote must be the header the '
            'scanner reads',
      );
    });

    test('the round trip validates, and validates clean', () {
      // `wasValidated`, not `isValid`, is what distinguishes "checked and
      // clean" from "never checked" — so both are asserted. A skeleton is
      // generated FROM a schema, so the one document it produces must be one
      // that schema accepts; anything less means the generator's only job is
      // not done.
      final doc = scan(DocSpecsSkeletonGenerator.generate(loadSchema()));
      expect(doc.wasValidated, isTrue, reason: 'a vacuous pass is not a pass');
      expect(doc.validationErrors, isEmpty);
    });

    test(
      'a document missing a required section is now caught without help',
      () {
        final doc = scan(
          '<!-- docspec: round-trip/1.0 -->\n\n# Title\n\nBody.\n',
        );
        expect(doc.wasValidated, isTrue);
        expect(
          doc.isValid,
          isFalse,
          reason: 'the required `note` section is missing',
        );
      },
    );
  });

  group('both declaration forms are read', () {
    test('the comment form BEFORE the first headline', () {
      final doc = scan('<!-- docspec: round-trip/1.0 -->\n# Title\n');
      expect(doc.schemaId, 'round-trip/1.0');
    });

    test('the comment form AFTER the first headline', () {
      // `test/fixtures/documents/valid-minimal.md` is written this way, so it
      // is a real placement and not a hypothetical one.
      final doc = scan('# Title\n\n<!-- docspec: round-trip/1.0 -->\n');
      expect(doc.schemaId, 'round-trip/1.0');
    });

    test('the in-headline form the DocSpecs specification documents', () {
      final doc = scan('# <!-- schema=round-trip/1.0 --> Title\n');
      expect(
        doc.schemaId,
        'round-trip/1.0',
        reason: 'the older form keeps working — the fix is additive',
      );
    });

    test('a declaration quoted in the body is not the document\'s own', () {
      // Not hypothetical: `test/fixtures/documents/docspecs-test-document.md`
      // declares its schema on line 1 and quotes the syntax again on line 190.
      // The preamble bound — everything above the SECOND heading — is what
      // keeps the second one out of reach.
      final doc = scan(
        '<!-- docspec: round-trip/1.0 -->\n'
        '# Title\n\n'
        '## Section\n\n'
        'Quoting the syntax: `<!-- docspec: wrong/9.9 -->`.\n',
      );
      expect(doc.schemaId, 'round-trip/1.0');
    });

    test('a document that declares nothing before its second heading', () {
      final doc = scan(
        '# Title\n\n## Section\n\n'
        '<!-- docspec: round-trip/1.0 -->\n',
      );
      expect(
        doc.schemaId,
        isEmpty,
        reason: 'past the preamble it is body content, not a declaration',
      );
    });

    test('an explicit schemaId still wins over the document declaration', () {
      final doc = scan(
        '<!-- docspec: no-such-schema/9.9 -->\n# Title\n',
        schemaId: 'round-trip/1.0',
      );
      expect(doc.schemaId, 'round-trip/1.0');
    });
  });

  group('a schemaless scan is not a passing scan', () {
    test('wasValidated is false when no schema could be resolved', () {
      final doc = scan('# Title\n\nNo declaration anywhere.\n');
      expect(doc.schemaId, isEmpty);
      expect(
        doc.wasValidated,
        isFalse,
        reason: 'nothing was checked, so nothing passed',
      );
    });

    test('isValid alone cannot tell the two apart, which is why both exist', () {
      final unchecked = scan('# Title\n');
      final checked = scan(_conformingDocument);
      // Both report `isValid: true` and an empty error list. Only one of them
      // was checked against anything, and no amount of reading `isValid` tells
      // you which.
      expect(unchecked.isValid, isTrue);
      expect(checked.isValid, isTrue);
      expect(unchecked.wasValidated, isFalse);
      expect(checked.wasValidated, isTrue);
    });
  });
}

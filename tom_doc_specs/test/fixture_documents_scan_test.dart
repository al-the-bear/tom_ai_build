/// Every fixture document, scanned from disk exactly as a consumer would.
///
/// The suite beside this one builds `SpecSection` objects in memory and
/// validates those. That is a fine unit test of the validator, but it never
/// exercises the *scanner*, so every divergence between what this package
/// writes and what it reads was invisible to it: three `valid-*` fixtures
/// reported `Unknown section type` the first time they were scanned in place,
/// and nothing had ever noticed.
///
/// The fixtures are named for their verdict, so the name is the assertion: a
/// `valid-*` document must validate clean and an `error-*` document must report
/// the errors its name promises. Scanning them in place needs
/// `DocSpecs.scanDocumentSync(schemaFolder:)` — without it the schemas here are
/// unreachable, the resolve returns null, and a schemaless scan reports no
/// errors, which reads exactly like a pass.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_doc_specs/tom_doc_specs.dart';

String _fixtures() {
  for (final c in [
    p.join(Directory.current.path, 'test', 'fixtures'),
    p.join(Directory.current.path, 'tom_doc_specs', 'test', 'fixtures'),
  ]) {
    if (Directory(c).existsSync()) return c;
  }
  throw StateError('cannot find test/fixtures from ${Directory.current.path}');
}

void main() {
  final fixtures = _fixtures();
  final schemas = p.join(fixtures, 'schemas');

  SpecDoc scan(String name) => DocSpecs.scanDocumentSync(
    filePath: p.join(fixtures, 'documents', name),
    schemaFolder: schemas,
  );

  /// Guards every case below: a document that resolved no schema was never
  /// checked, and an empty error list from an unchecked document is not a pass.
  void expectChecked(SpecDoc doc, String name) {
    expect(
      doc.wasValidated,
      isTrue,
      reason: '$name resolved no schema, so its verdict means nothing',
    );
  }

  group('FDS1: a valid-* fixture validates clean', () {
    for (final name in ['valid-minimal.md', 'valid-multi-section.md']) {
      test(name, () {
        final doc = scan(name);
        expectChecked(doc, name);
        expect(doc.validationErrors, isEmpty);
      });
    }

    test('both use the following-line id form, which is the point', () {
      // If the scanner ever stops reading that placement these go red here
      // rather than in a downstream document nobody is watching.
      final md = File(
        p.join(fixtures, 'documents', 'valid-minimal.md'),
      ).readAsStringSync();
      expect(md, contains('## Overview\n<!--[note-001] -->'));
    });
  });

  group('FDS2: an error-* fixture reports what its name promises', () {
    test('error-missing-sections.md names the missing sections', () {
      final doc = scan('error-missing-sections.md');
      expectChecked(doc, 'error-missing-sections.md');
      expect(doc.validationErrors, hasLength(2));
      expect(doc.validationErrors.join('\n'), contains("'overview'"));
      expect(doc.validationErrors.join('\n'), contains("'requirements'"));
      expect(
        doc.validationErrors.every((e) => e.contains('is missing')),
        isTrue,
      );
    });

    test('error-wrong-order.md reports order, and nothing else', () {
      final doc = scan('error-wrong-order.md');
      expectChecked(doc, 'error-wrong-order.md');
      expect(doc.validationErrors, isNotEmpty);
      expect(
        doc.validationErrors.every((e) => e.contains('out of order')),
        isTrue,
        reason: 'the fixture is well-formed apart from its ordering',
      );
    });

    test('error-multiple-issues.md reports more than one kind', () {
      final doc = scan('error-multiple-issues.md');
      expectChecked(doc, 'error-multiple-issues.md');
      final joined = doc.validationErrors.join('\n');
      expect(joined, contains('Unknown section type'));
      expect(joined, contains('is missing'));
    });
  });

  group('FDS3: the remaining fixtures scan clean', () {
    // Neither is named for a verdict, but both are hand-written examples of
    // the in-heading id form and should stay loadable.
    for (final name in [
      'docspecs-test-document.md',
      'schema-test-document.md',
    ]) {
      test(name, () {
        final doc = scan(name);
        expectChecked(doc, name);
        expect(doc.validationErrors, isEmpty);
      });
    }
  });

  test('FDS4: every fixture document is covered by a case above', () {
    // A fixture added later must be given a verdict rather than silently
    // sitting unscanned, which is the state all of them were in.
    final onDisk = Directory(p.join(fixtures, 'documents'))
        .listSync()
        .whereType<File>()
        .map((f) => p.basename(f.path))
        .where((n) => n.endsWith('.md'))
        .toSet();
    const covered = {
      'valid-minimal.md',
      'valid-multi-section.md',
      'error-missing-sections.md',
      'error-wrong-order.md',
      'error-multiple-issues.md',
      'docspecs-test-document.md',
      'schema-test-document.md',
    };
    expect(onDisk, covered);
  });
}

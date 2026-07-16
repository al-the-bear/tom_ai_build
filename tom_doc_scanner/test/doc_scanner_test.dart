import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tom_doc_scanner/tom_doc_scanner.dart';

void main() {
  final fixturesPath = path.join(
    Directory.current.path,
    'test',
    'fixtures',
  );

  group('DocScanner', () {
    group('scanDocument', () {
      test('scans a simple document', () async {
        final doc = await DocScanner.scanDocument(
          filepath: path.join(fixturesPath, 'simple.md'),
          workspaceRoot: Directory.current.path,
        );

        expect(doc.name, equals('Simple Document'));
        expect(doc.filename, equals('simple.md'));
        expect(doc.text, contains('Just some text'));
      });

      test('extracts explicit IDs', () async {
        final doc = await DocScanner.scanDocument(
          filepath: path.join(fixturesPath, 'test_document.md'),
          workspaceRoot: Directory.current.path,
        );

        expect(doc.sections, isNotNull);

        // Find the intro section
        final intro = doc.sections!.firstWhere((s) => s.id == 'intro');
        expect(intro.name, equals('Introduction'));

        // Find the features section (HTML comment ID)
        final features = doc.sections!.firstWhere((s) => s.id == 'features');
        expect(features.name, equals('Features'));

        // Check nested sections
        expect(features.sections, isNotNull);
        final feature1 =
            features.sections!.firstWhere((s) => s.id == 'feature1');
        expect(feature1.name, equals('Feature One'));
      });

      test('calculates hierarchy depth (uncapped, beyond 6 levels)', () async {
        final doc = await DocScanner.scanDocument(
          filepath: path.join(fixturesPath, 'nested.md'),
          workspaceRoot: Directory.current.path,
        );

        expect(doc.hierarchyDepth, equals(9));
      });

      test('builds section hierarchy through levels 7-9', () async {
        final doc = await DocScanner.scanDocument(
          filepath: path.join(fixturesPath, 'nested.md'),
          workspaceRoot: Directory.current.path,
        );

        // Walk the single chain Level 2 -> ... -> Level 9.
        var section = doc.sections!.single;
        expect(section.name, equals('Level 2'));
        for (final name in [
          'Level 3',
          'Level 4',
          'Level 5',
          'Level 6',
          'Level 7',
          'Level 8',
          'Level 9',
        ]) {
          section = section.sections!.single;
          expect(section.name, equals(name));
          if (name == 'Level 8') {
            // Explicit id on a level-8 heading is extracted.
            expect(section.id, equals('deep8'));
          }
        }
        expect(section.sections, anyOf(isNull, isEmpty));
      });

      test('parses SOM shared sample end-to-end (nests to level 12)', () async {
        // Regression fixture: snapshot of
        // tom_som_conformance/samples/meridian_order_management.md, the SOM
        // shared conformance sample. SOM documents nest far past CommonMark's
        // 6 heading levels; DocScanner must be a conforming reader (YRD2).
        final doc = await DocScanner.scanDocument(
          filepath: path.join(fixturesPath, 'som_meridian_order_management.md'),
          workspaceRoot: Directory.current.path,
        );

        expect(doc.hierarchyDepth, equals(12));
        expect(doc.id, equals('SBP'));

        // Every heading in the file must have been picked up as a section.
        var sectionCount = 0;
        String? deepId;
        void walk(Section s) {
          sectionCount++;
          if (s.id == 'EXTST-STEP-1') deepId = s.id; // a level-12 section
          for (final child in s.sections ?? const <Section>[]) {
            walk(child);
          }
        }

        for (final s in doc.sections ?? const <Section>[]) {
          walk(s);
        }

        // 331 headings total, minus the level-1 document headline.
        expect(sectionCount, equals(330));
        expect(deepId, equals('EXTST-STEP-1'));
      });

      test('handles document without headlines', () async {
        final doc = await DocScanner.scanDocument(
          filepath: path.join(fixturesPath, 'no_headline.md'),
          workspaceRoot: Directory.current.path,
        );

        expect(doc.name, equals('no_headline'));
        expect(doc.text, contains('No headline in this document'));
      });

      test('sets correct path information', () async {
        final doc = await DocScanner.scanDocument(
          filepath: path.join(fixturesPath, 'simple.md'),
          workspaceRoot: Directory.current.path,
        );

        expect(doc.filename, equals('simple.md'));
        expect(doc.filenameWithPath, endsWith('simple.md'));
        expect(doc.workspacePath, contains('simple.md'));
      });

      test('throws for non-existent file', () async {
        expect(
          () => DocScanner.scanDocument(
            filepath: '/nonexistent/file.md',
          ),
          throwsArgumentError,
        );
      });
    });

    group('scanDocuments', () {
      test('scans multiple documents', () async {
        final docs = await DocScanner.scanDocuments(
          filepaths: [
            path.join(fixturesPath, 'simple.md'),
            path.join(fixturesPath, 'nested.md'),
          ],
          workspaceRoot: Directory.current.path,
        );

        expect(docs.length, equals(2));
        expect(docs.map((d) => d.filename), containsAll(['simple.md', 'nested.md']));
      });
    });

    group('scanTree', () {
      test('scans directory tree', () async {
        final folder = await DocScanner.scanTree(
          path: fixturesPath,
          workspaceRoot: Directory.current.path,
        );

        expect(folder.foldername, equals('fixtures'));
        expect(folder.documents.length, greaterThanOrEqualTo(4));
      });

      test('includes subfolders', () async {
        final folder = await DocScanner.scanTree(
          path: fixturesPath,
          workspaceRoot: Directory.current.path,
        );

        expect(folder.folders, isNotEmpty);
        final subfolder = folder.folders.firstWhere(
          (f) => f.foldername == 'subfolder',
        );
        expect(subfolder.documents.length, equals(1));
      });

      test('allDocuments returns flattened list', () async {
        final folder = await DocScanner.scanTree(
          path: fixturesPath,
          workspaceRoot: Directory.current.path,
        );

        final allDocs = folder.allDocuments;
        expect(allDocs.length, greaterThan(folder.documents.length));
      });

      test('throws for non-existent directory', () async {
        expect(
          () => DocScanner.scanTree(path: '/nonexistent/dir'),
          throwsArgumentError,
        );
      });
    });

    group('scanDocumentSync', () {
      test('scans a simple document synchronously', () {
        final doc = DocScanner.scanDocumentSync(
          filepath: path.join(fixturesPath, 'simple.md'),
          workspaceRoot: Directory.current.path,
        );

        expect(doc.name, equals('Simple Document'));
        expect(doc.filename, equals('simple.md'));
        expect(doc.text, contains('Just some text'));
      });

      test('throws for non-existent file', () {
        expect(
          () => DocScanner.scanDocumentSync(filepath: '/nonexistent/file.md'),
          throwsArgumentError,
        );
      });
    });

    group('scanDocumentsSync', () {
      test('scans multiple documents synchronously', () {
        final docs = DocScanner.scanDocumentsSync(
          filepaths: [
            path.join(fixturesPath, 'simple.md'),
            path.join(fixturesPath, 'nested.md'),
          ],
          workspaceRoot: Directory.current.path,
        );

        expect(docs.length, equals(2));
        expect(
          docs.map((d) => d.filename),
          containsAll(['simple.md', 'nested.md']),
        );
      });
    });

    group('scanTreeSync', () {
      test('scans directory tree synchronously', () {
        final folder = DocScanner.scanTreeSync(
          path: fixturesPath,
          workspaceRoot: Directory.current.path,
        );

        expect(folder.foldername, equals('fixtures'));
        expect(folder.documents.length, greaterThanOrEqualTo(4));
      });

      test('includes subfolders synchronously', () {
        final folder = DocScanner.scanTreeSync(
          path: fixturesPath,
          workspaceRoot: Directory.current.path,
        );

        expect(folder.folders, isNotEmpty);
        final subfolder = folder.folders.firstWhere(
          (f) => f.foldername == 'subfolder',
        );
        expect(subfolder.documents.length, equals(1));
      });

      test('throws for non-existent directory', () {
        expect(
          () => DocScanner.scanTreeSync(path: '/nonexistent/dir'),
          throwsArgumentError,
        );
      });
    });
  });
}

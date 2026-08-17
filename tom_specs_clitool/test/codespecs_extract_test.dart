/// The per-area extract reader — the validator's second input.
///
/// Tested as its own unit rather than only through the comment checks, because
/// `codespecs_mapping.md` §1.1.1 makes the extract the artifact of record for
/// everything Phase 4 was given, and the coverage questions read the same tree.
/// One parser read by two consumers has to agree with itself about what a
/// malformed extract is.
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

String _yaml({
  int version = kCsExtractFormat,
  String areaCode = 'CE-DB',
  String root = 'IMO',
  List<(String section, String value)> entries = const [],
}) {
  final buffer = StringBuffer()
    ..writeln('extract:')
    ..writeln('  formatVersion: $version')
    ..writeln('  area:')
    ..writeln('    code: ${jsonEncode(areaCode)}')
    ..writeln('    canonicalId: "DataAccess"')
    ..writeln('    part: "dataAccess"')
    ..writeln('  document:')
    ..writeln('    root: ${jsonEncode(root)}')
    ..writeln('  entries:');
  for (final (section, value) in entries) {
    buffer
      ..writeln('    - sectionId: ${jsonEncode(section)}')
      ..writeln('      className: "DataEntityEntry"')
      ..writeln('      fieldName: "description"')
      ..writeln('      value: ${jsonEncode(value)}');
  }
  return '$buffer';
}

void main() {
  group('readCsExtracts', () {
    test('reads an area, its document root and its entries', () {
      final set = readCsExtracts({
        'CE-DB.extract.yaml': _yaml(
          entries: [('IMO-014', 'A person or organisation.')],
        ),
      });
      expect(set.isEmpty, isFalse);
      expect(set.extracts.single.areaCode, 'CE-DB');
      expect(set.extracts.single.canonicalId, 'DataAccess');
      expect(set.extracts.single.part, 'dataAccess');
      expect(set.extracts.single.source, 'CE-DB.extract.yaml');
      expect(set.documentRoots, {'IMO'});
      expect(set.entries.single.value, 'A person or organisation.');
    });

    test('indexes by section id across every area, in read order', () {
      final set = readCsExtracts({
        'CE-DB.extract.yaml': _yaml(entries: [('IMO-014', 'from the entity')]),
        'CE-AZ.extract.yaml': _yaml(
          areaCode: 'CE-AZ',
          entries: [('IMO-014', 'from the access key')],
        ),
      });
      expect(set.knowsSection('IMO-014'), isTrue);
      expect(set.knowsSection('IMO-015'), isFalse);
      expect(
        set.entriesFor('IMO-014').map((e) => e.areaCode),
        ['CE-DB', 'CE-AZ'],
      );
      expect(set.entriesForAll(['IMO-015', 'IMO-014']), hasLength(2));
      expect(set.entriesFor('IMO-015'), isEmpty);
    });

    test('no sources at all is the empty set, not an error', () {
      expect(readCsExtracts(const {}).isEmpty, isTrue);
      expect(CsExtractSet.empty.entries, isEmpty);
      expect(CsExtractSet.empty.knowsSection('IMO-014'), isFalse);
    });

    test('a future format is refused rather than read as empty', () {
      // Reading it would drop every entry a moved key holds, and a check with
      // no input passes — which is the one failure mode a validator may not
      // have.
      expect(
        () => readCsExtracts({'x.extract.yaml': _yaml(version: 2)}),
        throwsA(
          isA<CsExtractException>().having(
            (e) => e.message,
            'message',
            contains('silently drop entries'),
          ),
        ),
      );
    });

    test('a document with no `extract:` mapping is refused', () {
      expect(
        () => readCsExtracts({'x.extract.yaml': 'areas: []\n'}),
        throwsA(
          isA<CsExtractException>().having(
            (e) => e.message,
            'message',
            contains('no top-level `extract:` mapping'),
          ),
        ),
      );
    });

    test('an extract that names no area code is refused', () {
      expect(
        () => readCsExtracts({'x.extract.yaml': _yaml(areaCode: '')}),
        throwsA(
          isA<CsExtractException>().having(
            (e) => e.message,
            'message',
            contains('names no area code'),
          ),
        ),
      );
    });

    test('invalid YAML names the file it came from', () {
      expect(
        () => readCsExtracts({'broken.extract.yaml': 'extract: [\n'}),
        throwsA(
          isA<CsExtractException>().having(
            (e) => e.message,
            'message',
            contains('broken.extract.yaml'),
          ),
        ),
      );
    });
  });

  group('CsExtractEntry', () {
    test('splits a value into the lines the specification authored', () {
      const entry = CsExtractEntry(
        areaCode: 'CE-DB',
        sectionId: 'IMO-014',
        value: 'one\ntwo\nthree',
      );
      expect(entry.rawLines, ['one', 'two', 'three']);
    });

    test('names where a value came from, and a form field by its label', () {
      const plain = CsExtractEntry(
        areaCode: 'CE-DB',
        sectionId: 'IMO-014',
        className: 'DataEntityEntry',
        fieldName: 'description',
        value: 'x',
      );
      const formed = CsExtractEntry(
        areaCode: 'CE-DB',
        sectionId: 'IMO-014',
        className: 'DataEntityEntry',
        fieldName: 'fields',
        formField: 'Table name',
        value: 'x',
      );
      expect(plain.origin, 'DataEntityEntry.description');
      expect(formed.origin, 'DataEntityEntry.Table name');
    });
  });

  group('csEscapedLines (§2.8 C4.4)', () {
    test('escapes the three characters dartdoc would otherwise eat', () {
      // `>` is deliberately not among them: it closes nothing dartdoc opened, so
      // escaping it would show the escape.
      expect(
        csEscapeCommentLine('A [ref] to List<int>.'),
        r'A \[ref\] to List&lt;int>.',
      );
    });

    test('a fenced code block is copied through unescaped', () {
      expect(
        csEscapedLines('A [ref].\n```\norder[0] = Order<int>();\n```\nAfter [x].'),
        [
          r'A \[ref\].',
          '```',
          'order[0] = Order<int>();',
          '```',
          r'After \[x\].',
        ],
      );
    });
  });
}

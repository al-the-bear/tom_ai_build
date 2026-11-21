// The merge back (SOM §11.10): properties over the strip corpus, beside the
// cases of tom_som_conformance/corpus/strip_merge_cases.json.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import 'strip_case_runner.dart';

void main() {
  // The shared corpus, from components like conformance_test.dart: this test
  // is not shipped (.pubignore), its subject being the corpus itself.
  final corpus = [
    Directory.current.path,
    '..',
    'tom_som_conformance',
    'corpus',
    'strip_cases.json',
  ].join(Platform.pathSeparator);
  final cases =
      ((jsonDecode(File(corpus).readAsStringSync())
                  as Map<String, dynamic>)['cases']
              as List)
          .cast<Map<String, dynamic>>();

  group('mergeStrippedValue over every strip case', () {
    for (final c in cases) {
      final o = c['text'] as String;
      final s = stripNotationText(o, stripCaseOptions(c));
      if (s.refused) continue;
      test('unchanged gives the original back: ${c['name']}', () {
        final r = mergeStrippedValue(o, s.text, s.text, s.pieces);
        expect(r.text, o);
        expect(r.restored, s.pieces.length);
        expect(r.placed, isEmpty);
      });
      test('a paragraph added strips back to the edit: ${c['name']}', () {
        final e = s.text.isEmpty
            ? 'An added paragraph.'
            : '${s.text}\n\nAn added paragraph.';
        final r = mergeStrippedValue(o, s.text, e, s.pieces);
        expect(r.conflicts, isEmpty);
        expect(stripNotationText(r.text!, stripCaseOptions(c)).text, e);
      });
    }
  });

  group('mergeStrippedValue', () {
    final trace = SpecStripOptions.fromNames(drop: ['trace']);
    test('a conflict carries the three excerpts and the piece', () {
      const o = 'Keep this. Gone here (-> C1). Tail.';
      final s = stripNotationText(o, trace);
      final r = mergeStrippedValue(o, s.text, 'Keep this. Tail.', s.pieces);
      expect(r.ok, isFalse);
      expect(r.text, isNull);
      final c = r.conflicts.single.about(const SpecStripValueRef('DEMO/SUM'));
      expect(c.reportLines, [
        'CONFLICT DEMO/SUM — the edit removed the whole sentence holding the '
            'piece',
        '  O: «Keep this. Gone here (-> C1). Tail.»',
        '  B: «Keep this. Gone here. Tail.»',
        '  E: «Keep this. Tail.»',
        '  piece: « (-> C1)»',
      ]);
    });

    test('several pieces in one value go back independently', () {
      const o = 'Alpha (-> A1). Beta [aside]{.aside} gamma (-> B2).';
      final opts = SpecStripOptions.fromNames(drop: ['trace', 'aside']);
      final s = stripNotationText(o, opts);
      final e = s.text.replaceFirst('Alpha', 'First');
      final r = mergeStrippedValue(o, s.text, e, s.pieces);
      expect(r.text, 'First (-> A1). Beta [aside]{.aside} gamma (-> B2).');
      expect(r.restored, 3);
      expect(stripNotationText(r.text!, opts).text, e);
    });
  });

  group('SpecStripMerge', () {
    test('the labels of the report', () {
      expect(specStripMergeLabel(const SpecStripValueRef('A/B')), 'A/B');
      expect(
        specStripMergeLabel(const SpecStripValueRef('A/B', field: 'f')),
        'A/B / f',
      );
      expect(
        specStripMergeLabel(const SpecStripValueRef('A/B', headline: true)),
        'A/B (headline)',
      );
    });

    test('gitShowFile reads a committed file and refuses an unknown one', () {
      final self = File('pubspec.yaml').absolute.path;
      final text = SpecStripMerge.gitShowFile('HEAD', self);
      expect(text, contains('name: tom_som_dart_runtime'));
      expect(SpecStripMerge.gitShowFile('HEAD', '${self}x'), isNull);
    });
  });
}

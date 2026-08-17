import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The gate over the Phase-4 **area catalogue** — the input all nine runtimes'
/// `spec_codespecs_extract` reads.
///
/// The catalogue is a transcription of `codespecs_mapping.md` §4.1 + §4.4.3 +
/// §4.4.6, so the tests that matter are the ones that would catch it having
/// stopped being one: the committed file must equal a fresh build (drift), and
/// the transcribed kind values must be exactly the `CodeSpecPart` enum's active
/// members (agreement with the code the mapping document says it generates).
void main() {
  final mapping =
      File('../tom_specs_model/doc/codespecs_mapping.md').readAsStringSync();

  group('codespecs_areas.json', () {
    test('the committed catalogue equals a fresh transcription', () {
      final committed = File(
          '../tom_specs_model/generated-doc/codespecs/codespecs_areas.json');
      expect(committed.existsSync(), isTrue,
          reason: 'run `dart run bin/codespecs_areas.dart`');
      expect(
        committed.readAsStringSync(),
        buildAreasCatalog(mapping).toJsonText(),
        reason: 'codespecs_areas.json is stale — regenerate it and commit the '
            'diff. The mapping document is the authority; this file is only '
            'its machine-readable form.',
      );
    });

    test('every kind value is a CodeSpecPart the annotation package declares',
        () {
      final source = File(
              '../tom_specs_core/lib/src/annotations/code_spec_kind.dart')
          .readAsStringSync();
      final body = RegExp(r'enum CodeSpecPart\s*\{([\s\S]*?)\n\}')
          .firstMatch(source)
          ?.group(1);
      expect(body, isNotNull, reason: 'CodeSpecPart enum not found');

      // Enum members are the identifiers at the start of a declaration line;
      // doc comments and trailing commentary are skipped by the anchor.
      final declared = {
        for (final m
            in RegExp(r'^\s{2}([a-z]\w*)\s*,', multiLine: true).allMatches(body!))
          m.group(1)!,
      };
      expect(declared, isNotEmpty);

      final catalog = buildAreasCatalog(mapping);
      final transcribed = {for (final a in catalog.areas) a['part'] as String};

      expect(transcribed.difference(declared), isEmpty,
          reason: '§4.1 names a kind value the CodeSpecPart enum does not '
              'declare — the enum is generated from that table, so one of the '
              'two has moved without the other.');

      // The other direction is not equality: §4.3 reserves a value for the
      // deferred part and §4.1 rules `domainEnum` a member kind rather than a
      // part, so the enum is legitimately larger. What must hold is that the
      // surplus is exactly those two classes, which §4.1 fixes at 28 - 26.
      expect(declared.difference(transcribed).length, 2,
          reason: 'the enum should hold exactly two non-part values — the §4.3 '
              'deferred candidate and the `domainEnum` member kind. Surplus: '
              '${(declared.difference(transcribed).toList()..sort()).join(", ")}');
      expect(declared.difference(transcribed), contains('domainEnum'));
    });

    test('the slice relation is acyclic and the authoring order respects it',
        () {
      // buildAreasCatalog runs the structural guard over kSliceCites; this
      // test states the property the guard exists for, so a future edit that
      // drops the call fails here rather than passing silently.
      for (final entry in kSliceCites.entries) {
        for (final cited in entry.value) {
          expect(cited, lessThan(entry.key),
              reason: '§4.4.2 forbids forward references between slices');
        }
      }
      final authored = <int>{};
      for (final slice in kAuthoringSliceOrder) {
        expect(authored.containsAll(kSliceCites[slice]!), isTrue,
            reason: 'slice $slice is authored before a slice it cites');
        authored.add(slice);
      }
      expect(authored.length, kSliceCites.length);
    });

    test('every area places itself in the slices its authoring steps sit in',
        () {
      final catalog = buildAreasCatalog(mapping);
      final sliceOf = {
        for (final s in catalog.slices) s['number'] as int: s,
      };
      for (final area in catalog.areas) {
        final slices = (area['slices'] as List).cast<int>();
        expect(slices, isNotEmpty, reason: '${area['code']} sits in no slice');
        for (final n in slices) {
          expect(sliceOf.containsKey(n), isTrue,
              reason: '${area['code']} names slice $n, which §4.4.3 has not');
        }
        expect((area['authoringSteps'] as List), isNotEmpty,
            reason: '${area['code']} has no authoring step');
      }
    });

    test('a mapping document missing a table fails loudly', () {
      // The transcription's one real hazard is silence: a §4.1 restructure that
      // moves the table would otherwise produce an empty catalogue and an
      // extract run over nothing.
      final broken = const LineSplitter()
          .convert(mapping)
          .where((l) => !l.startsWith('#### 4.4.6 '))
          .join('\n');
      expect(() => buildAreasCatalog(broken), throwsA(isA<AreasCatalogException>()));
    });
  });
}

/// The coverage-gap record (`codespecs_derivation_contract.md` §2.11): its
/// reader and writer, what it refuses, and how check 35 reads it — a token a
/// `leaveAsIs` gap names is not held against the trio, an `open` one still is.
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

const _record = '''
coverageGaps:
  formatVersion: 1
  gaps:
    - id: GAP-1
      sectionId: "DATAA"
      path: "IMO/x/DATAA"
      field: "retention"
      valueKind: string
      area: CE-DB
      needs: markerArgument
      foundBy: authoring
      step: 9
      note: "@CsTable has no argument for how long a row is kept"
      resolution: open
    - id: GAP-3
      sectionId: "IMO-014"
      path: "IMO/x"
      area: CE-DB
      needs: unknown
      foundBy: mechanical
      note: "check 35: reached no code"
      resolution: leaveAsIs
      reason: "kept in the documentation only"
''';

String _extract(List<(String, String, String)> entries) {
  final b = StringBuffer()
    ..writeln('extract:')
    ..writeln('  formatVersion: $kCsExtractFormat')
    ..writeln('  area:')
    ..writeln('    code: "CE-DB"')
    ..writeln('  document:')
    ..writeln('    root: "IMO"')
    ..writeln('  entries:');
  for (final (section, field, value) in entries) {
    b
      ..writeln('    - sectionId: ${jsonEncode(section)}')
      ..writeln('      className: "DataEntityEntry"')
      ..writeln('      fieldName: ${jsonEncode(field)}')
      ..writeln('      value: ${jsonEncode(value)}');
  }
  return '$b';
}

CodeSpecsValidationInput _input(CsExtractSet extracts) =>
    CodeSpecsValidationInput(
      shared: readCsLocusProject(
        locus: CsLocus.shared,
        packageName: 'x_codespec_shared',
        sources: const {},
      ),
      client: readCsLocusProject(
        locus: CsLocus.client,
        packageName: 'x_codespec_client',
        sources: const {},
      ),
      server: readCsLocusProject(
        locus: CsLocus.server,
        packageName: 'x_codespec_server',
        sources: const {'lib/a.dart': 'class Customer {}'},
      ),
      extracts: extracts,
    );

void main() {
  group('the record', () {
    test('reads every key and writes back what it read', () {
      final record = readCsCoverageGaps(_record);
      expect(record.gaps, hasLength(2));
      final first = record.gaps.first;
      expect(first.id, 'GAP-1');
      expect(first.field, 'retention');
      expect(first.valueKind, 'string');
      expect(first.needs, CsGapNeed.markerArgument);
      expect(first.foundBy, CsGapFinder.authoring);
      expect(first.step, 9);
      expect(first.resolution, CsGapResolution.open);
      expect(record.gaps.last.reason, 'kept in the documentation only');
      expect(record.nextNumber, 4, reason: 'an id is never reused');
      final again = readCsCoverageGaps(writeCsCoverageGaps(record));
      expect(writeCsCoverageGaps(again), writeCsCoverageGaps(record));
    });

    test('open and leaveAsIs gaps stop a finder; added and fixed do not', () {
      final record = readCsCoverageGaps(_record);
      expect(record.alreadyRecorded('DATAA', 'CE-DB'), isTrue);
      expect(record.alreadyRecorded('IMO-014', 'CE-DB'), isTrue);
      expect(record.alreadyRecorded('IMO-014', 'CE-API'), isFalse);
      expect(record.isLeftAsIs('IMO-014', 'CE-DB'), isTrue);
      expect(record.isLeftAsIs('DATAA', 'CE-DB'), isFalse);
      final added = readCsCoverageGaps(
        _record.replaceFirst(
          'resolution: open',
          'resolution: added\n      todo: "tom_specs cs1"',
        ),
      );
      expect(added.alreadyRecorded('DATAA', 'CE-DB'), isFalse);
    });

    for (final (what, edit) in <(String, String Function(String))>[
      ('an id that is not GAP-<n>', (s) => s.replaceFirst('GAP-1', 'G1')),
      ('an id twice', (s) => s.replaceFirst('GAP-3', 'GAP-1')),
      (
        'an unknown needs word',
        (s) => s.replaceFirst('needs: markerArgument', 'needs: something'),
      ),
      (
        'step on a gap no authoring step found',
        (s) => s.replaceFirst('foundBy: authoring', 'foundBy: stageB'),
      ),
      (
        'an added gap without todo',
        (s) => s.replaceFirst('resolution: open', 'resolution: added'),
      ),
      (
        'a leaveAsIs gap without reason',
        (s) => s.replaceFirst(
          '      reason: "kept in the documentation only"\n',
          '',
        ),
      ),
      (
        'a missing note',
        (s) => s.replaceFirst(RegExp(r'      note: "@.*\n'), ''),
      ),
      (
        'another formatVersion',
        (s) => s.replaceFirst('formatVersion: 1', 'formatVersion: 2'),
      ),
    ]) {
      test('refuses $what', () {
        expect(
          () => readCsCoverageGaps(edit(_record)),
          throwsA(isA<CsCoverageGapException>()),
        );
      });
    }

    test('an empty record writes `gaps: []` and reads back empty', () {
      final text = writeCsCoverageGaps(CsCoverageGapRecord.empty);
      expect(text, contains('gaps: []'));
      expect(readCsCoverageGaps(text).gaps, isEmpty);
    });
  });

  group('read with the extracts', () {
    test('the record is kept beside the set and scopes nothing else', () {
      final set = readCsExtracts({
        'CE-DB.extract.yaml': _extract([('IMO-014', 'content', 'x')]),
        kCsCoverageGapFile: _record,
      });
      expect(set.extracts, hasLength(1));
      expect(set.coverageGaps.gaps, hasLength(2));
    });

    test('a malformed record is refused like a malformed extract', () {
      expect(
        () => readCsExtracts({
          'CE-DB.extract.yaml': _extract([('IMO-014', 'content', 'x')]),
          kCsCoverageGapFile: 'coverageGaps: 3',
        }),
        throwsA(isA<CsExtractException>()),
      );
    });
  });

  group('check 35 and the record', () {
    test('a token a leaveAsIs gap names for its area is not reported', () {
      final input = _input(
        readCsExtracts({
          'CE-DB.extract.yaml': _extract([
            ('IMO-014', 'content', 'x'),
            ('DATAA', 'maxLength', '80'),
          ]),
          kCsCoverageGapFile: _record,
        }),
      );
      final raised = const CsExtractCoverageCheck().run(input);
      expect(raised.map((v) => v.token), [
        'DATAA',
      ], reason: 'IMO-014 is left as is; DATAA is only open');
      final tokens = csUncitedTokens(input);
      expect(
        {for (final t in tokens) t.sectionId: t.leftAsIs},
        {'IMO-014': true, 'DATAA': false},
      );
    });

    test('without a record every uncited token is reported', () {
      final input = _input(
        readCsExtracts({
          'CE-DB.extract.yaml': _extract([
            ('IMO-014', 'content', 'x'),
            ('DATAA', 'maxLength', '80'),
          ]),
        }),
      );
      expect(const CsExtractCoverageCheck().run(input).map((v) => v.token), [
        'IMO-014',
        'DATAA',
      ]);
    });
  });
}

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_specs_clitool/src/som_parity.dart';

/// The nine-plane parity check — a capability the contract names that a plane
/// does not carry.
///
/// Two cases decide the design and are worth reading before changing it:
///
///   * `containment folds a plane's naming convention` — C spells a method
///     `som_doc_add_list_item`, so an exact match reports 26 missing
///     capabilities that are all C being C. Containment is what makes the check
///     usable, and it is a deliberate trade: it can miss, and a miss leaves the
///     check no worse than the nothing it replaced, while a false alarm gets it
///     switched off.
///   * `an exception covers only the planes it measured` — an acknowledgement
///     is of a measured state, not of a name, so the same token spreading to one
///     more plane must go red rather than being absorbed by the old entry.
void main() {
  Map<String, Set<String>> planes(Map<String, List<String>> raw) => {
    for (final plane in somPlanes) plane: {...?raw[plane]?.map(normaliseToken)},
  };

  group('checkParity', () {
    test('a capability every plane carries is silent', () {
      final findings = checkParity(
        {'enumValueUnknown'},
        planes({
          for (final plane in somPlanes) plane: ['enumValueUnknown'],
        }),
      );

      expect(findings, isEmpty);
    });

    test('casing and underscores are not a difference', () {
      // The same capability as each plane really spells it.
      final findings = checkParity(
        {'enumValueUnknown'},
        planes({
          'dart': ['enumValueUnknown'],
          'python': ['ENUM_VALUE_UNKNOWN'],
          'javascript': ['ENUM_VALUE_UNKNOWN'],
          'typescript': ['ENUM_VALUE_UNKNOWN'],
          'java': ['ENUM_VALUE_UNKNOWN'],
          'go': ['EnumValueUnknown'],
          'rust': ['ENUM_VALUE_UNKNOWN'],
          'c': ['ENUM_VALUE_UNKNOWN'],
          'cpp': ['EnumValueUnknown'],
        }),
      );

      expect(findings, isEmpty);
    });

    test('containment folds a plane\'s naming convention', () {
      final findings = checkParity(
        {'addListItem'},
        planes({
          for (final plane in somPlanes) plane: ['addListItem'],
        })..['c'] = {normaliseToken('som_doc_add_list_item')},
      );

      expect(
        findings,
        isEmpty,
        reason: 'C prefixes its functions; that is not a missing capability',
      );
    });

    test('a capability only the reference plane has is reported', () {
      final findings = checkParity(
        {'discriminatorField'},
        planes({
          'dart': ['discriminatorField'],
        }),
      );

      expect(findings, hasLength(1));
      expect(findings.single.token, 'discriminatorField');
      expect(findings.single.absentFrom, hasLength(8));
      expect(findings.single.absentFrom, isNot(contains('dart')));
    });

    test('a corpus word no plane implements is not a capability', () {
      // Sample documents are full of camelCase content words. Filtering the
      // vocabulary to what the reference plane implements is what keeps them
      // out; without it the first run reported 185 of these.
      final findings = checkParity(
        {'someFieldInASampleDocument'},
        planes({
          for (final plane in somPlanes) plane: ['unrelated'],
        }),
      );

      expect(findings, isEmpty);
    });
  });

  group('exceptions', () {
    final finding = ParityFinding('dateTime', ['rust', 'java']);

    test('an entry naming the measured planes covers the finding', () {
      final entry = ParityException('dateTime', 'type systems differ', [
        'rust',
        'java',
      ]);

      expect(unacknowledged([finding], [entry]), isEmpty);
    });

    test('an entry covers only the planes it measured', () {
      final entry = ParityException('dateTime', 'type systems differ', [
        'rust',
      ]);

      expect(
        unacknowledged([finding], [entry]),
        hasLength(1),
        reason: 'spreading to a second plane is new information',
      );
    });

    test('an entry with no planes covers the token everywhere', () {
      final entry = ParityException('dateTime', 'everywhere', const []);

      expect(unacknowledged([finding], [entry]), isEmpty);
    });

    test('an exception that outlived its gap is reported', () {
      final entry = ParityException(
        'portedSince',
        'was missing once',
        const [],
      );

      expect(staleExceptions([finding], [entry]).single.token, 'portedSince');
    });
  });

  group('the real tree', () {
    // Anti-vacuity: every case above would pass just as happily if the scanner
    // were never pointed at the nine runtimes.
    final root = Directory.current.path.endsWith('tom_specs_clitool')
        ? Directory(Directory.current.path).parent.path
        : null;

    test('every plane\'s sources are readable and non-trivial', () {
      if (root == null) return;
      for (final plane in somPlanes) {
        final tokens = planeTokens('$root/tom_som_${plane}_runtime', plane);
        expect(
          tokens.length,
          greaterThan(500),
          reason:
              '$plane read as ${tokens.length} tokens; a plane that '
              'reads as empty would report every capability missing',
        );
      }
    });

    test('the contract vocabulary is read from the corpus', () {
      if (root == null) return;
      final vocabulary = contractVocabulary('$root/tom_som_conformance');
      expect(vocabulary.length, greaterThan(100));
      expect(vocabulary, contains('enumValueUnknown'));
    });

    test('the gate is green: every gap is acknowledged, every entry live', () {
      // The gate itself, in the default `dart test` run — the same walk
      // `bin/check_som_parity.dart` performs, over the real nine planes and the
      // committed manifest. Without this the check would only run when somebody
      // remembered to, which is the state this todo existed to end.
      if (root == null) return;
      final vocabulary = contractVocabulary('$root/tom_som_conformance');
      final tokenSets = <String, Set<String>>{
        for (final plane in somPlanes)
          plane: planeTokens('$root/tom_som_${plane}_runtime', plane),
      };
      final findings = checkParity(vocabulary, tokenSets);
      final exceptions = readParityExceptions(
        '${Directory.current.path}/tool/som_parity_exceptions.yaml',
      );

      expect(
        unacknowledged(findings, exceptions),
        isEmpty,
        reason:
            'a capability the contract names has not reached every '
            'plane, and no committed exception accounts for it',
      );
      expect(
        staleExceptions(findings, exceptions),
        isEmpty,
        reason: 'an acknowledged gap is gone; delete its entry',
      );
    });
  });
}

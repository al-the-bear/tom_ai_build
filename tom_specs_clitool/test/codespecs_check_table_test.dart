import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The gate that keeps `codespecs_derivation_contract.md` §6's table and
/// `codeSpecsChecks` the same list.
///
/// The live case runs against the real pair, so a check added to the registry
/// with no row — or a row whose class was renamed or dropped — fails here. The
/// synthetic cases pin each failure mode independently of the real document, so
/// they keep testing the same thing after the contract moves on. They take their
/// two checks from the head of the registry rather than naming classes, because
/// the failure modes are about the *correspondence* and not about which checks
/// happen to be first.
void main() {
  final first = codeSpecsChecks[0];
  final second = codeSpecsChecks[1];

  group('§6 ↔ codeSpecsChecks correspondence', () {
    test('the real table and the real registry name the same checks', () {
      final contract = File(
        '${Directory.current.path}/../tom_specs_model/doc/'
        'codespecs_derivation_contract.md',
      );
      final report = compareCsCheckTable(
        markdown: contract.readAsStringSync(),
      );

      expect(report.rows, hasLength(codeSpecsChecks.length));
      expect(report.problems, isEmpty, reason: report.problems.join('\n'));
    });

    test('a check with no row is reported', () {
      final report = compareCsCheckTable(
        markdown: _tableOf([(1, '${first.runtimeType}')]),
        checks: [first, second],
      );

      expect(report.isConsistent, isFalse);
      expect(report.problems.single, contains('§6 has no row for it'));
    });

    test('a row with no check is reported', () {
      final report = compareCsCheckTable(
        markdown: _tableOf([
          (1, '${first.runtimeType}'),
          (2, '${second.runtimeType}'),
        ]),
        checks: [first],
      );

      expect(report.isConsistent, isFalse);
      expect(
        report.problems.single,
        contains('codeSpecsChecks has no check with that number'),
      );
    });

    test('a row naming the wrong class is reported', () {
      final report = compareCsCheckTable(
        markdown: _tableOf(const [(1, 'CsSomethingElseCheck')]),
        checks: [first],
      );

      expect(report.isConsistent, isFalse);
      expect(
        report.problems.single,
        contains('${first.runtimeType} as check 1 in the registry'),
      );
    });

    test('a table that does not run 1..n is rejected', () {
      final report = compareCsCheckTable(
        markdown: _tableOf([
          (1, '${first.runtimeType}'),
          (3, '${second.runtimeType}'),
        ]),
        checks: [first, second],
      );

      expect(report.isConsistent, isFalse);
      expect(report.problems.first, contains('must run 1..n'));
    });

    test('a contract with no §6 says so rather than passing empty', () {
      final report = compareCsCheckTable(markdown: '## 5. Something else\n');

      expect(report.isConsistent, isFalse);
      expect(report.problems.single, contains('declared no check rows'));
    });

    test('the header row and its separator are not read as checks', () {
      final rows = parseCsCheckRows(_tableOf(const [(1, 'CsSomeCheck')]));

      expect(rows, hasLength(1));
      expect(rows.single.number, 1);
      expect(rows.single.implementedBy, 'CsSomeCheck');
    });
  });
}

/// A §6 stand-in carrying [entries] as its table.
String _tableOf(List<(int, String)> entries) => [
      '## 6. Validator checks this contract creates',
      '',
      '| # | Check | Defined in | Implemented by |',
      '|---|-------|------------|----------------|',
      for (final (number, className) in entries)
        '| $number | A rule | §2.1 | `$className` |',
      '',
    ].join('\n');

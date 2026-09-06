/// Keeps `codespecs_derivation_contract.md` §6's table and [codeSpecsChecks]
/// the same list in both directions.
///
/// `codespecs_derivation_contract.md` §6 says of itself that "a check numbered
/// below with no class, or a class in the registry with no row, is a defect in
/// one of the two". That sentence is only worth writing if something reads it:
/// a table maintained by hand beside a registry maintained by hand drifts on
/// the first check anyone adds in a hurry, and the drift is invisible — the
/// validator still runs, the document still reads plausibly, and the two stop
/// describing the same thing.
library;

import 'cs_checks.dart';

/// One row of `codespecs_derivation_contract.md` §6's table.
class CsCheckRow {
  /// The check number in the first column.
  final int number;

  /// The class named in the last column, stripped of its backticks.
  final String implementedBy;

  /// Creates a row.
  const CsCheckRow({required this.number, required this.implementedBy});

  @override
  String toString() => 'check $number → $implementedBy';
}

/// The outcome of one comparison.
class CsCheckTableCorrespondence {
  /// The rows `codespecs_derivation_contract.md` §6 declares, in table order.
  final List<CsCheckRow> rows;

  /// Everything wrong, one line each; empty when the two agree.
  final List<String> problems;

  /// Creates the outcome.
  const CsCheckTableCorrespondence({required this.rows, required this.problems});

  /// Whether the table and the registry are the same list.
  bool get isConsistent => problems.isEmpty;
}

/// The `| # | Check | Defined in | Implemented by |` rows of
/// `codespecs_derivation_contract.md` §6.
///
/// The parse is anchored on the `## 6. ` heading rather than on the table
/// shape, so a table elsewhere in the contract is not mistaken for this one.
List<CsCheckRow> parseCsCheckRows(String markdown) {
  final lines = markdown.split('\n');
  final start = lines.indexWhere((l) => l.startsWith('## 6. '));
  if (start < 0) return const [];

  final rows = <CsCheckRow>[];
  for (var i = start + 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.startsWith('## ')) break;
    if (!line.startsWith('|')) continue;
    final cells = line.split('|').map((c) => c.trim()).toList();
    // A row is `` | 1 | … | … | `Class` | `` — six cells: the four written
    // ones plus the two empty ones the split adds at the ends. The header and
    // its separator have no numeric first cell, so they fall out here.
    if (cells.length < 6) continue;
    final number = int.tryParse(cells[1]);
    if (number == null) continue;
    rows.add(
      CsCheckRow(
        number: number,
        implementedBy: cells[4].replaceAll('`', '').trim(),
      ),
    );
  }
  return rows;
}

/// Compares `codespecs_derivation_contract.md` §6's table in [markdown] against
/// [checks].
CsCheckTableCorrespondence compareCsCheckTable({
  required String markdown,
  List<CodeSpecsCheck> checks = codeSpecsChecks,
}) {
  final rows = parseCsCheckRows(markdown);
  final problems = <String>[];

  if (rows.isEmpty) {
    problems.add(
      '§6 declared no check rows — the parser looks for a `| <n> | … |` table '
      'under the "## 6. " heading',
    );
    return CsCheckTableCorrespondence(rows: rows, problems: problems);
  }

  final byNumber = {for (final check in checks) check.number: check};

  for (var i = 0; i < rows.length; i++) {
    if (rows[i].number != i + 1) {
      problems.add(
        '§6 row ${i + 1} is numbered ${rows[i].number} — the table must run '
        '1..n so a citation of a check number is unambiguous',
      );
    }
    final check = byNumber[rows[i].number];
    if (check == null) {
      problems.add(
        '§6 numbers check ${rows[i].number} (${rows[i].implementedBy}) but '
        'codeSpecsChecks has no check with that number — a documented rule '
        'nothing runs is a rule the generator can quietly break',
      );
      continue;
    }
    final actual = check.runtimeType.toString();
    if (rows[i].implementedBy != actual) {
      problems.add(
        '§6 names $actual as check ${rows[i].number} in the registry but '
        '${rows[i].implementedBy} in the table',
      );
    }
  }

  final documented = rows.map((r) => r.number).toSet();
  for (final check in checks) {
    if (documented.contains(check.number)) continue;
    problems.add(
      'check ${check.number} (${check.runtimeType}) runs but §6 has no row for '
      'it — a check with no write-up is a constraint authors meet by accident',
    );
  }

  return CsCheckTableCorrespondence(rows: rows, problems: problems);
}

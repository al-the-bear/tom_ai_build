import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The gate that keeps `tom_specs_model_rules.md` §10.2 and `validator.dart`
/// the same set of invariants in both directions.
///
/// The live check runs against the real pair, so a new validator check with no
/// write-up — or a documented rule whose check was dropped — fails here. The
/// synthetic cases below pin each failure mode independently of the real
/// documents, so they keep testing the same thing after the model moves on.
void main() {
  group('§10.2 ↔ validator.dart correspondence', () {
    test('the real list and the real checks name the same invariants', () {
      final report = checkInvariantCorrespondence(Directory.current.path);

      expect(report.entries, isNotEmpty,
          reason: '§10.2 numbered list was not found — the parser is looking '
              'for the block under the "### 10.2 " heading');
      expect(report.problems, isEmpty,
          reason: report.problems.join('\n'));
    });

    test('a check with no write-up is reported as undocumented', () {
      final report = compareInvariants(
        rulesMarkdown: _rulesWith(2),
        validatorSource: '''
  // --- Step 1 — §10.2 invariant 1: first ---
  // --- Step 2 — §10.2 invariant 2: second ---
  // --- Step 3 — §10.2 invariant 3: third ---
''',
      );

      expect(report.isConsistent, isFalse);
      expect(report.undocumented.single.invariant, 3);
      expect(report.problems.single, contains('the numbered list does not'));
    });

    test('a documented rule with no check is reported as unimplemented', () {
      final report = compareInvariants(
        rulesMarkdown: _rulesWith(3),
        validatorSource: '''
  // --- Step 1 — §10.2 invariant 1: first ---
  // --- Step 2 — §10.2 invariant 2: second ---
''',
      );

      expect(report.isConsistent, isFalse);
      expect(report.unimplemented.single.number, 3);
      expect(report.problems.single, contains('documented but no'));
    });

    test('one comment may cite several invariants', () {
      final report = compareInvariants(
        rulesMarkdown: _rulesWith(2),
        validatorSource:
            '  // --- Step 1 — §10.2 invariants 1 + 2: the routing pair ---\n',
      );

      expect(report.tags.map((t) => t.invariant), [1, 2]);
      expect(report.isConsistent, isTrue);
    });

    test('a list that does not run 1..n is rejected', () {
      final report = compareInvariants(
        rulesMarkdown: '''
### 10.2 The mechanical structural invariants

1. **First** — a rule.
3. **Third** — a rule whose predecessor was deleted without renumbering.
''',
        validatorSource: '''
  // --- Step 1 — §10.2 invariant 1: first ---
  // --- Step 2 — §10.2 invariant 3: third ---
''',
      );

      expect(report.isConsistent, isFalse);
      expect(report.misnumbered.single, contains('must run 1..n'));
    });

    test('the list ends at the closing prose, not at the next number', () {
      final entries = parseInvariantEntries('''
### 10.2 The mechanical structural invariants

1. **First** — a rule.
   A continuation line, indented.
2. **Second** — another rule.

**Deliberately not an invariant:** something that reads like prose.

1. A numbered list belonging to a later paragraph.
''');

      expect(entries.map((e) => e.number), [1, 2]);
      expect(entries.last.title, 'Second');
    });
  });
}

/// A minimal §10.2 section carrying [count] numbered entries.
String _rulesWith(int count) {
  final buffer = StringBuffer('### 10.2 The mechanical structural invariants\n\n');
  for (var i = 1; i <= count; i++) {
    buffer.writeln('$i. **Rule $i** — a structural rule.');
  }
  return buffer.toString();
}

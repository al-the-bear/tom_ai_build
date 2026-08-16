import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The gate over `tom_specs_model_rules.md` §10.2 and everything that cites it.
///
/// Two properties, both checked against the real documents by the first test:
/// §10.2 and `validator.dart` name the same set of invariants in both
/// directions, and every `§10.2 invariant <ID>` citation in the corpus resolves
/// to an id §10.2 defines. The synthetic cases below pin each failure mode
/// independently of the real documents, so they keep testing the same thing
/// after the model moves on.
///
/// The corpus scan is what makes §10.2's ordinals free to move: a citation names
/// an id, an id outlives a reordering, and a citation of an id that was never
/// allocated (or has been retired) fails here rather than pointing at whatever
/// now occupies that list position.
void main() {
  group('§10.2 ↔ validator.dart correspondence', () {
    test('the real list and the real checks name the same invariants', () {
      final report = checkInvariantCorrespondence(Directory.current.path);

      expect(
        report.entries,
        isNotEmpty,
        reason:
            '§10.2 numbered list was not found — the parser is looking '
            'for the block under the "### 10.2 " heading',
      );
      expect(report.problems, isEmpty, reason: report.problems.join('\n'));
    });

    test('the corpus reaches the documents and packages that cite §10.2', () {
      // Without this the gate could pass vacuously: a mistyped path in
      // [defaultCitingPaths] silently scans nothing, and "no undefined
      // citation" then means "no citation was looked at". The named sources are
      // the ones that carried the eleven citations a renumbering broke, so if
      // any of them stops being scanned the reason has to be a deliberate one.
      final report = checkInvariantCorrespondence(Directory.current.path);
      final sources = report.citations.map((c) => c.source).toSet();

      expect(sources, contains('validator.dart'));
      expect(sources, contains('pubspec.yaml'));
      expect(sources, contains('../tom_specs_model/doc/codespecs_mapping.md'));
      expect(
        sources,
        contains('../tom_specs_model/doc/tom_specs_model_rules.md'),
      );
      expect(
        sources,
        contains(
          '../tom_specs_model/lib/src/codespecs_projection/'
          'codespecs_projection.dart',
        ),
      );
      expect(
        sources,
        contains('../tom_specs_core/lib/src/annotations/code_spec_kind.dart'),
      );
    });

    test('a check with no write-up is reported as undocumented', () {
      final report = compareInvariants(
        rulesMarkdown: _rulesWith(['ALPHA-ONE', 'BETA-TWO']),
        validatorSource: '''
  // --- Step 1 — §10.2 invariant ALPHA-ONE: first ---
  // --- Step 2 — §10.2 invariant BETA-TWO: second ---
  // --- Step 3 — §10.2 invariant GAMMA-THREE: third ---
''',
      );

      expect(report.isConsistent, isFalse);
      expect(report.undocumented.single.id, 'GAMMA-THREE');
      expect(report.problems.single, contains('which §10.2 does not define'));
    });

    test('a documented rule with no check is reported as unimplemented', () {
      final report = compareInvariants(
        rulesMarkdown: _rulesWith(['ALPHA-ONE', 'BETA-TWO', 'GAMMA-THREE']),
        validatorSource: '''
  // --- Step 1 — §10.2 invariant ALPHA-ONE: first ---
  // --- Step 2 — §10.2 invariant BETA-TWO: second ---
''',
      );

      expect(report.isConsistent, isFalse);
      expect(report.unimplemented.single.id, 'GAMMA-THREE');
      expect(report.problems.single, contains('documented but no check'));
    });

    test('one comment may cite several invariants', () {
      final report = compareInvariants(
        rulesMarkdown: _rulesWith(['ALPHA-ONE', 'BETA-TWO']),
        validatorSource:
            '  // --- Step 1 — §10.2 invariants ALPHA-ONE + BETA-TWO: pair ---\n',
      );

      expect(report.tags.map((t) => t.id), ['ALPHA-ONE', 'BETA-TWO']);
      expect(report.isConsistent, isTrue);
    });

    test('an entry that defines no id is rejected', () {
      final report = compareInvariants(
        rulesMarkdown: '''
### 10.2 The mechanical structural invariants

1. **`ALPHA-ONE`** — a rule.
2. **Second** — a rule that never allocated an id.
''',
        validatorSource:
            '  // --- Step 1 — §10.2 invariant ALPHA-ONE: first ---\n',
      );

      expect(report.isConsistent, isFalse);
      expect(
        report.malformed.single,
        contains('does not open with an invariant id'),
      );
    });

    test('an id defined twice is rejected', () {
      final report = compareInvariants(
        rulesMarkdown: _rulesWith(['ALPHA-ONE', 'ALPHA-ONE']),
        validatorSource:
            '  // --- Step 1 — §10.2 invariant ALPHA-ONE: first ---\n',
      );

      expect(report.isConsistent, isFalse);
      expect(report.malformed.single, contains('twice'));
    });

    test('the list ends at the closing prose, not at the next number', () {
      final entries = parseInvariantEntries('''
### 10.2 The mechanical structural invariants

1. **`ALPHA-ONE`** — a rule.
   A continuation line, indented.
2. **`BETA-TWO`** — another rule.

**Deliberately not an invariant:** something that reads like prose.

1. A numbered list belonging to a later paragraph.
''');

      expect(entries.map((e) => e.id), ['ALPHA-ONE', 'BETA-TWO']);
      expect(entries.last.title, 'another rule.');
    });
  });

  group('§10.2 citation resolution', () {
    test('a corpus citation of an undefined id fails', () {
      final report = compareInvariants(
        rulesMarkdown: _rulesWith(['ALPHA-ONE']),
        validatorSource:
            '  // --- Step 1 — §10.2 invariant ALPHA-ONE: first ---\n',
        corpus: {
          'doc/some_document.md':
              'The rule (`tom_specs_model_rules.md` §10.2, invariant\n'
              '`DELTA-FOUR`) requires it.\n',
        },
      );

      expect(report.isConsistent, isFalse);
      expect(report.undocumented.single.id, 'DELTA-FOUR');
      expect(report.undocumented.single.source, 'doc/some_document.md');
    });

    test('a citation wrapping across lines still resolves both ids', () {
      final citations = parseInvariantCitations(
        'the pair (`tom_specs_model_rules.md` §10.2, invariants `ALPHA-ONE`\n'
        'and `BETA-TWO`): both hold.\n',
      );

      expect(citations.map((c) => c.id), ['ALPHA-ONE', 'BETA-TWO']);
    });

    test('the scan stops at the prose that follows a citation', () {
      // The tail after the id is a colon and a lowercase sentence; neither is a
      // joiner, so nothing beyond the id is read as a second citation.
      final citations = parseInvariantCitations(
        '// --- Step 4 — §10.2 invariant DETAIL-PRESENT: per-@Document ---\n'
        'The §10.2 rule enforced here rather than in the structural pass.\n',
      );

      expect(citations.map((c) => c.id), ['DETAIL-PRESENT']);
    });

    test('a citation written as an ordinal is reported as such', () {
      // The pre-`tscompc9` form. It is named specifically rather than treated as
      // an unknown id, because the remedy is different: an ordinal citation is
      // not a typo, it is the habit §10.2's third meta-rule retired.
      final report = compareInvariants(
        rulesMarkdown: _rulesWith(['ALPHA-ONE']),
        validatorSource:
            '  // --- Step 1 — §10.2 invariant ALPHA-ONE: first ---\n',
        corpus: {'doc/legacy.md': 'see `…` §10.2 invariant 6 for the rule.\n'},
      );

      expect(report.isConsistent, isFalse);
      expect(report.undocumented.single.isOrdinal, isTrue);
      expect(report.problems.single, contains('by list position'));
    });

    test('reordering the list cannot invalidate a citation', () {
      // The regression this whole mechanism exists for. Deleting §10.2's first
      // entry used to shift every later ordinal and silently re-point eleven
      // citations; with ids, the surviving citation still resolves and the only
      // failure reported is the one that is actually true — the deleted rule.
      const validator = '''
  // --- Step 1 — §10.2 invariant ALPHA-ONE: first ---
  // --- Step 2 — §10.2 invariant BETA-TWO: second ---
''';
      const corpus = {'doc/cite.md': 'per §10.2 invariant `BETA-TWO`.\n'};

      final before = compareInvariants(
        rulesMarkdown: _rulesWith(['ALPHA-ONE', 'BETA-TWO']),
        validatorSource: validator,
        corpus: corpus,
      );
      expect(before.isConsistent, isTrue);

      // Reordered: `BETA-TWO` is now entry 1 and `ALPHA-ONE` entry 2.
      final reordered = compareInvariants(
        rulesMarkdown: _rulesWith(['BETA-TWO', 'ALPHA-ONE']),
        validatorSource: validator,
        corpus: corpus,
      );
      expect(
        reordered.isConsistent,
        isTrue,
        reason:
            'a pure reordering must change nothing: '
            '${reordered.problems.join('\n')}',
      );

      // Deleted: the citation of the surviving rule is untouched, and the only
      // complaint is the tag left pointing at the rule that is gone.
      final deleted = compareInvariants(
        rulesMarkdown: _rulesWith(['BETA-TWO']),
        validatorSource: validator,
        corpus: corpus,
      );
      expect(deleted.undocumented.map((c) => c.id), ['ALPHA-ONE']);
    });
  });
}

/// A minimal §10.2 section defining [ids], in order.
String _rulesWith(List<String> ids) {
  final buffer = StringBuffer(
    '### 10.2 The mechanical structural invariants\n\n',
  );
  for (var i = 0; i < ids.length; i++) {
    buffer.writeln('${i + 1}. **`${ids[i]}`** — a structural rule.');
  }
  return buffer.toString();
}

// Tests of the marker tool (tom_som_dart_runtime/lib/src/spec_checks/
// mark_secondary.dart) and its check `mark-secondary`
// (lib/src/spec_checks_cli.dart): each pattern (P1, T1, E1, R1), each false
// positive of the working document's part *Marking secondary prose*,
// idempotence, the reflow, a value becoming a block scalar, and a bad rewrite
// refused.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/spec_checks.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';
import 'package:tom_specs_clitool/src/spec_checks_cli.dart';

final SomMetaTree _tree = d00SolutionBlueprintMetaTree;

/// A Solution Blueprint holding every shape the marker reads.
const String _fixture = r'''
# TomSpecs document (*.tomspecs.yaml). Hierarchical format v2.
version: 2
modelVersion: "1.4"
document:
  SBP D00SolutionBlueprint:
    content: |2-
      **The provenance notes.** The notes `_Extrapolated — see iterations/<name>_notes.md._` are the Blueprint's (DQ-73).

      **Design vision.** A bold-led paragraph that is content.
    DOCTL documentControl:
      content: |2-
        Rights scoped to a node apply to its subtree (C2.1).

        Two runs side by side (FR-54) (C16.3), and a list (FR-07, BQ-405).

        _Extrapolated — see iterations/sbpa21_notes.md._

        _Extrapolated — see 03_01_01_Questions Round/group_notes.md (p2s3r1ss1-18)._

        _Extrapolated — see iterations/sbpa22_notes.md._ And more text.

        - [ ] _Extrapolated_ in a checklist line.

        Keys are hashed (SHA-256) and signed (RS256, ES256); denials carry (UAM-403-SIGN-IN-DENIED).

        The rule is kept per (FR-97), and see (BQ-1).

        Worded (Project Idea 1.1, C1.2) and (from RC-4) and (FR-51, BQ-557, `SCJOB-X`).

        Decided as asked (DQ-115 (b)), merged (RC-176, DQ-186 (a)) (FR-60), unspaced (DQ-157(a)) and two letters (DQ-1 (ab)).

        In code `(FR-1)` stays.

        ```mermaid
        graph TD; A(FR-2) --> B
        ```

        > ⬆️ **C-1** (reviewer): a comment citing (FR-3).

        Already (-> FR-4) and [an aside (FR-5)]{.aside}.

        A mark {++holding a run (FR-6)++} is fine.

        See (`tom_uam.ifm.md`, `BIRU-BUSI-LST > BIRU-BUSI-X`) and `INSC > SYDSC` and `NOPE > XX`.

        | Rule | Backing |
        | --- | --- |
        | Scoped rights | (FR-8) |
        | A rule backed | by this (FR-9) |
    INSC introductionAndScope:
      SYDSC systemDescription:
        content: |2-
          A soft-wrapped value
          on three lines
          with no blank line.
        SYPUP systemPurpose:
          SCBND scopeBoundaries:
            SIE-INSC-LST inScopeItems:
              SIE-INSC-TEST-CLIENT:
                headline: |2-
                  Test client (FR-10)
                content:
                  itemDescription: A test client (FR-11).
                  category: |2-
                    (FR-12)
''';

MarkSecondaryResult _run({
  String yaml = _fixture,
  Set<SecondaryKind>? kinds,
  bool reflow = false,
  String? under,
}) => markSecondaryInPlace(
  yaml,
  _tree,
  kinds: kinds ?? SecondaryKind.values.toSet(),
  reflow: reflow,
  under: under,
);

/// The new text of the value whose label ends with [label].
String _value(MarkSecondaryResult r, String label) =>
    r.rewrites.singleWhere((w) => w.label.endsWith(label)).newValue;

void main() {
  late MarkSecondaryResult r;
  setUpAll(() => r = _run());

  test('MS-0 the rewrite is verified and decodes', () {
    expect(r.failures, isEmpty);
    SpecDocumentYaml.decode(r.text, _tree);
  });

  group('MS-1 the patterns', () {
    test('P1: a whole-paragraph note, with a file or a round', () {
      final v = _value(r, 'DOCTL');
      expect(v, contains('\n\n(<~ iterations/sbpa21_notes.md)\n\n'));
      expect(
        v,
        contains('(<~ 03_01_01_Questions Round/group_notes.md (p2s3r1ss1-18))'),
      );
      expect(r.changesOf(SecondaryKind.provenance), hasLength(2));
    });

    test('T1: a run after text, adjacent runs merged, a list kept', () {
      final v = _value(r, 'DOCTL');
      expect(v, contains('apply to its subtree (-> C2.1).'));
      expect(v, contains('side by side (-> FR-54, C16.3), and'));
      expect(v, contains('a list (-> FR-07, BQ-405).'));
    });

    test('T1: a decision cited with the option taken', () {
      final v = _value(r, 'DOCTL');
      expect(v, contains('Decided as asked (-> DQ-115 (b)), merged'));
      expect(v, contains('merged (-> RC-176, DQ-186 (a), FR-60), unspaced'));
      expect(v, contains('unspaced (DQ-157(a)) and two letters (DQ-1 (ab)).'));
    });

    test('T1: in a table cell beside text, and inside a review mark', () {
      final v = _value(r, 'DOCTL');
      expect(v, contains('| by this (-> FR-9) |'));
      expect(v, contains('{++holding a run (-> FR-6)++}'));
    });

    test('T1: a run in a field line; the value becomes a block scalar', () {
      expect(_value(r, '/ itemDescription'), 'A test client (-> FR-11).');
      expect(
        r.text,
        contains('itemDescription: |2-\n                    A test client'),
      );
    });

    test('E1: the provenance-notes preamble becomes an editorial div', () {
      final v = _value(r, 'SBP');
      expect(
        v,
        startsWith('::: {.editorial}\n**The provenance notes.** The notes'),
      );
      expect(v, contains("are the Blueprint's (-> DQ-73).\n:::\n\n"));
      expect(r.changesOf(SecondaryKind.editorial), hasLength(1));
    });

    test('R1: a cross-document reference and a same-document path', () {
      final v = _value(r, 'DOCTL');
      expect(
        v,
        contains('See [BIRU-BUSI-X](tom_uam.ifm.tomspecs.md#BIRU-BUSI-X) '),
      );
      expect(v, contains('and [SYDSC](#SYDSC) and'));
    });
  });

  group('MS-2 the false positives', () {
    String doctl() => _value(r, 'DOCTL');

    test('a whole value, a whole table cell, a headline', () {
      expect(r.skips[SecondaryKind.trace]!['wholeValue'], 1);
      expect(r.skips[SecondaryKind.trace]!['wholeCell'], 1);
      expect(doctl(), contains('| Scoped rights | (FR-8) |'));
      expect(r.text, contains('Test client (FR-10)'));
      expect(r.text, contains('category: |2-\n                    (FR-12)'));
    });

    test('unknown families and error codes; the families are counted', () {
      expect(doctl(), contains('hashed (SHA-256) and signed (RS256, ES256)'));
      expect(doctl(), contains('(UAM-403-SIGN-IN-DENIED)'));
      expect(r.unknownFamilies, {'SHA': 1, 'RS': 1, 'ES': 1});
    });

    test('after see / per: a candidate', () {
      expect(doctl(), contains('kept per (FR-97), and see (BQ-1).'));
      final c = r.candidatesOf(SecondaryKind.trace);
      expect(
        [
          for (final x in c.where((x) => x.reason == 'afterPreposition'))
            x.text,
        ],
        ['(FR-97)', '(BQ-1)'],
      );
    });

    test('worded runs and runs holding a code span: candidates', () {
      final c = r.candidatesOf(SecondaryKind.trace);
      expect(
        [for (final x in c.where((x) => x.reason == 'worded')) x.text],
        [
          '(Project Idea 1.1, C1.2)',
          '(from RC-4)',
          '(DQ-157(a))',
          '(DQ-1 (ab))',
        ],
      );
      expect(
        [for (final x in c.where((x) => x.reason == 'codeSpanInRun')) x.text],
        ['(FR-51, BQ-557, `SCJOB-X`)'],
      );
    });

    test('code spans, fenced code, comment blocks, the notation', () {
      final v = doctl();
      expect(v, contains('In code `(FR-1)` stays.'));
      expect(v, contains('A(FR-2) --> B'));
      expect(v, contains('a comment citing (FR-3).'));
      expect(v, contains('Already (-> FR-4) and [an aside (FR-5)]{.aside}.'));
    });

    test('P1: quoted in a code span, a checklist line, more text', () {
      expect(_value(r, 'SBP'), contains('`_Extrapolated — see iterations/'));
      expect(doctl(), contains('- [ ] _Extrapolated_ in a checklist line.'));
      expect(
        doctl(),
        contains('_Extrapolated — see iterations/sbpa22_notes.md._ And more'),
      );
      expect(
        [for (final c in r.candidatesOf(SecondaryKind.provenance)) c.reason],
        ['moreText'],
      );
    });

    test('E1: another bold-led paragraph is a candidate', () {
      final c = r.candidatesOf(SecondaryKind.editorial).single;
      expect(c.reason, 'boldLed');
      expect(c.text, startsWith('**Design vision.**'));
    });

    test('R1: a path naming no section is a candidate', () {
      expect(_value(r, 'DOCTL'), contains('`NOPE > XX`'));
      final c = r.candidatesOf(SecondaryKind.references).single;
      expect(c.reason, 'noSuchSection');
      expect(c.text, '`NOPE > XX`');
    });
  });

  group('MS-3 runs', () {
    test('idempotent: a second run marks nothing new', () {
      final again = _run(yaml: r.text);
      expect(again.changes, isEmpty);
      expect(again.changedValues, 0);
      expect(again.text, r.text);
    });

    test('the rest of the file is byte-identical', () {
      final a = _fixture.split('\n'), b = r.text.split('\n');
      // The one-line itemDescription became a header and a body line, and
      // the editorial div added its two fence lines.
      expect(b.length, a.length + 3);
      final changed = [
        for (var i = 0; i < a.length; i++)
          if (!b.contains(a[i])) a[i].trim(),
      ];
      expect(changed.every((l) => l.isNotEmpty), isTrue);
      expect(changed.length, lessThan(15));
    });

    test('--kinds limits the patterns, --under the values', () {
      final t = _run(kinds: {SecondaryKind.trace});
      expect(t.changes.every((c) => c.kind == SecondaryKind.trace), isTrue);
      final u = _run(under: 'INSC');
      expect(u.rewrites.every((w) => w.label.contains('INSC')), isTrue);
      expect(u.changedValues, 1);
      expect(
        () => _run(under: 'NOPE'),
        throwsA(isA<SecondarySectionNotFound>()),
      );
    });

    test('reflow joins one-paragraph values only', () {
      final f = _run(kinds: {}, reflow: true);
      expect(f.changes, isEmpty);
      expect(f.reflows, hasLength(1));
      expect(f.reflows.single.lines, 3);
      expect(
        _value(f, 'SYDSC'),
        'A soft-wrapped value on three lines with no blank line.',
      );
      expect(f.failures, isEmpty);
      expect(reflowText('a\n- b'), 'a\n- b');
      expect(reflowText('a  \nb'), 'a  \nb');
      expect(reflowText('a\n\nb'), 'a\n\nb');
    });
  });

  group('MS-4 a bad rewrite is refused', () {
    test('a value that is not its edits applied', () {
      final w = r.rewrites.firstWhere((w) => w.label.endsWith('DOCTL'));
      final bad = SecondaryValueRewrite(
        location: w.location,
        field: w.field,
        label: w.label,
        oldValue: w.oldValue,
        reflowed: w.reflowed,
        newValue: w.newValue.replaceFirst('Rights', 'Rites'),
        changes: w.changes,
      );
      final failures = verifyMarkSecondary(
        _fixture,
        rewriteSecondaryValues(_fixture, [bad]),
        _tree,
        [bad],
      );
      expect(failures.join('\n'), contains('not the edits applied'));
    });

    test('an edit that is not its pattern', () {
      final w = r.rewrites.firstWhere((w) => w.label.endsWith('DOCTL'));
      final c = w.changes.firstWhere((c) => c.kind == SecondaryKind.trace);
      final wrong = SecondaryChange(
        kind: c.kind,
        value: c.value,
        line: c.line,
        original: c.original,
        edits: [
          SecondaryEdit(c.edits.single.start, c.edits.single.end, '(-> C9.9)'),
        ],
        before: c.before,
        after: c.after,
      );
      final changes = [for (final x in w.changes) x == c ? wrong : x];
      final bad = SecondaryValueRewrite(
        location: w.location,
        field: w.field,
        label: w.label,
        oldValue: w.oldValue,
        reflowed: w.reflowed,
        newValue: applySecondaryEdits(w.reflowed, [
          for (final x in changes) ...x.edits,
        ]),
        changes: changes,
      );
      final failures = verifyMarkSecondary(
        _fixture,
        rewriteSecondaryValues(_fixture, [bad]),
        _tree,
        [bad],
      );
      expect(failures.join('\n'), contains('is not the pattern'));
    });

    test('a YAML holding another value elsewhere', () {
      final tampered = r.text.replaceFirst(
        'with no blank line.',
        'with no blank lines.',
      );
      final failures = verifyMarkSecondary(
        _fixture,
        tampered,
        _tree,
        r.rewrites,
      );
      expect(failures.join('\n'), contains('holds another value'));
    });

    test('a notation finding the run would introduce', () {
      final w = r.rewrites.firstWhere((w) => w.label.endsWith('SBP'));
      final bad = SecondaryValueRewrite(
        location: w.location,
        field: w.field,
        label: w.label,
        oldValue: w.oldValue,
        reflowed: w.reflowed,
        newValue: w.newValue.replaceFirst('\n:::', ''),
        changes: w.changes,
      );
      final failures = verifyMarkSecondary(
        _fixture,
        rewriteSecondaryValues(_fixture, [bad]),
        _tree,
        [bad],
      );
      expect(failures.join('\n'), contains('new notation finding'));
    });
  });

  group('MS-5 the check', () {
    late Directory dir;
    late String doc;
    setUp(() {
      final scratch = Directory('../../../ztmp')..createSync(recursive: true);
      dir = scratch.createTempSync('tom_specs_clitool_mark_secondary_');
      doc = '${dir.path}/sbp.tomspecs.yaml';
      File(doc).writeAsStringSync(_fixture);
    });
    tearDown(() => dir.deleteSync(recursive: true));

    (int, String, String) check(List<String> args) {
      final out = _Sink(), err = _Sink();
      final code = runSpecChecks(
        ['mark-secondary', ...args],
        out: out,
        err: err,
      );
      return (code, out.text, err.text);
    }

    test('a dry run reports and writes nothing (exit 1)', () {
      final (code, out, _) = check([doc]);
      expect(code, 1);
      expect(out, contains('provenance  2 marked, 1 candidate(s)'));
      expect(out, contains('trace       '));
      expect(out, contains('CHANGE    trace '));
      expect(out, contains('  before  '));
      expect(out, contains('CANDIDATE trace afterPreposition '));
      expect(out, contains('families  not in the list: '));
      expect(out, contains('dry run   nothing written'));
      expect(File(doc).readAsStringSync(), _fixture);
    });

    test('--write writes (exit 0); a second run has nothing to mark', () {
      final (code, out, _) = check([doc, '--write']);
      expect(code, 0);
      expect(out, contains('written   $doc'));
      expect(out, contains('tomspecs :spec-render'));
      expect(File('$doc.mark-secondary.stage').existsSync(), isFalse);
      final (again, out2, _) = check([doc]);
      expect(again, 0);
      expect(out2, contains('nothing   to mark'));
    });

    test('usage errors (exit 2)', () {
      expect(check([doc, '--kinds', 'nonsense']).$1, 2);
      expect(check([doc, '--under', 'NOPE']).$1, 2);
      expect(check([doc, '--nonsense']).$1, 2);
      expect(check([]).$1, 2);
    });
  });
}

class _Sink implements IOSink {
  final _buffer = StringBuffer();
  String get text => _buffer.toString();
  @override
  Encoding encoding = utf8;
  @override
  void write(Object? object) => _buffer.write(object);
  @override
  void writeln([Object? object = '']) => _buffer.writeln(object);
  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) =>
      _buffer.writeAll(objects, separator);
  @override
  void writeCharCode(int charCode) => _buffer.writeCharCode(charCode);
  @override
  void add(List<int> data) => _buffer.write(utf8.decode(data));
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<void> addStream(Stream<List<int>> stream) async {}
  @override
  Future<void> close() async {}
  @override
  Future<void> get done async {}
  @override
  Future<void> flush() async {}
}

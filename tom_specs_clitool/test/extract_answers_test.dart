import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// `extract_answers` (annot6): a review round's answers as `answers.md`.
void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('extract_answers'));
  tearDown(() => tmp.deleteSync(recursive: true));

  // A minimal Solution Blueprint rendition with one answered and one open
  // question, and a comment without an id.
  const sbp = '''
<!-- docspec: solution-blueprint/1.6 -->
# <!--[SBP]--> Solution Blueprint

## <!--[INSC]--> Introduction And Scope

The scope.

> ⬆️ (Alexis): Name the tenants.

> **❓ BQ-1 — Scope:** one installation per customer?
>
> **Answer:** yes

> **❓ BQ-2 — Hosting:** cloud or on premises?
>
> **Answer:**
''';

  Future<(int, String, String)> run(List<String> args) async {
    final out = StringBuffer(), err = StringBuffer();
    final code = await runExtractAnswers(args, out: out, err: err);
    return (code, out.toString(), err.toString());
  }

  test('EXA-1: writes answers.md and prints the counts', () async {
    final doc = File('${tmp.path}/demo.sbp.md')..writeAsStringSync(sbp);
    final target = '${tmp.path}/step/answers.md';
    final (code, out, err) = await run([
      doc.path,
      '-o',
      target,
      '--open',
      '--counts',
    ]);
    expect(code, 0, reason: err);
    expect(out, contains('answered 1, open 1, comments 1, marks 0'));
    final md = File(target).readAsStringSync();
    expect(md, startsWith('# Answers\n\n1 answered question, 1 open question'));
    expect(md, contains('## demo.sbp'));
    expect(md, contains('#### BQ-1 — Scope'));
    expect(md, contains('- **Answer:** yes'));
    expect(md, contains('### Open questions'));
    expect(md, contains('#### BQ-2 — Hosting'));
    expect(md, contains('Comment without id'));
  });

  test(
    'EXA-2: two runs over an unchanged document are byte-identical',
    () async {
      final doc = File('${tmp.path}/demo.sbp.md')..writeAsStringSync(sbp);
      final (_, first, _) = await run([doc.path]);
      final (_, second, _) = await run([doc.path]);
      expect(first, second);
      expect(first, isNot(contains('Open questions')));
    },
  );

  test('EXA-3: a malformed annotation fails the run', () async {
    final doc = File('${tmp.path}/bad.sbp.md')
      ..writeAsStringSync(
        sbp.replaceFirst('The scope.', 'The {++ unclosed scope.'),
      );
    final (code, _, err) = await run([doc.path]);
    expect(code, 1);
    expect(err, contains('annotationMalformed'));
  });

  test('EXA-4: a missing document and missing arguments', () async {
    expect((await run(['${tmp.path}/nope.md'])).$1, 1);
    expect((await run([])).$1, 2);
  });
}

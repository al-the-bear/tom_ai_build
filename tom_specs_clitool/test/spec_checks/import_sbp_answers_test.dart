// Tests for the Blueprint answer import (tom_som_dart_runtime/lib/src/spec_checks/sbp_answer_import.dart).
//
// Group IMP-4 runs the import on the real Blueprint, IMP-4.1 on a copy in
// ztmp/sbpb1/e2e_test/ (about 30 s each). The Blueprint's questions are all
// answered and removed, so the group first writes the questions it answers into
// the text (withTestQuestions, through the tool's own in-place writer); it is
// skipped when the Blueprint is not found next to this tool.
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/spec_checks.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show SpecQuestionDraft, formatQuestionBlock;
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_schemas.dart';

import 'sbp_fixture.dart';

/// The Solution Blueprint's model, tree and schema, from the facade.
final _sbp = SpecRootDefinition(
  model: somSpecModel,
  tree: d00SolutionBlueprintMetaTree,
  rootType: 'D00SolutionBlueprint',
  schema: somDocSpecsSchema('solution-blueprint'),
);

/// [yaml] with an open question block appended to each value named in
/// [questions] (section-id path → question id), written in place by the
/// tool's own writer so every other line stays as it is.
String withTestQuestions(String yaml, Map<String, String> questions) {
  final locations = locateValues(yaml, _sbp.tree);
  return rewriteValues(yaml, [
    for (final MapEntry(key: idPath, value: id) in questions.entries)
      () {
        final loc = locations.values.firstWhere(
          (l) => l.idPath == idPath,
          orElse: () => throw StateError('no value at $idPath'),
        );
        final block = formatQuestionBlock(
          SpecQuestionDraft(
            id: id,
            topic: 'Test question',
            text: 'Which option applies?',
            options: const ['(a) the first', '(b) the second'],
            recommended: 'b',
          ),
        );
        return ValueEdit(loc, '${loc.value}\n\n${block.join('\n')}');
      }(),
  ]);
}

/// [markdown] with [answer] written as the answer of [questionId]: the first
/// line after `**Answer:**`, every further line as a `> ` continuation.
String answerIn(String markdown, String questionId, List<String> answer) =>
    withAnswer(markdown, questionId, answer.join('\n'));

/// The 1-based numbers of the lines in which [a] and [b] differ, when they
/// have the same line count; `null` otherwise.
List<int>? changedLines(String a, String b) {
  final x = a.split('\n');
  final y = b.split('\n');
  if (x.length != y.length) return null;
  return [
    for (var i = 0; i < x.length; i++)
      if (x[i] != y[i]) i + 1,
  ];
}

/// The lines of [b] that are not in [a] at the same position, after
/// aligning their common prefix and suffix.
List<String> insertedRegion(String a, String b) {
  final x = a.split('\n');
  final y = b.split('\n');
  var start = 0;
  while (start < x.length && start < y.length && x[start] == y[start]) {
    start++;
  }
  var end = 0;
  while (end < x.length - start &&
      end < y.length - start &&
      x[x.length - 1 - end] == y[y.length - 1 - end]) {
    end++;
  }
  return y.sublist(start, y.length - end);
}

void main() {
  late AnswerImporter importer;
  late String rendition;

  setUp(() {
    importer = AnswerImporter.forYaml(_sbp, fixtureYaml);
    rendition = importer.rendition;
  });

  group('IMP-1: answers in the fixture', () {
    test('IMP-1.1: a narrative question\'s answer reaches the YAML', () {
      final plan = importer.plan(answerIn(rendition, 'BQ-901', ['b']));

      expect(plan.isRefused, isFalse, reason: plan.refusals.join('\n'));
      expect(plan.answers.map((a) => a.reportLine), [
        'BQ-901  SBP > INSC > SYDSC > content  "b"',
      ]);
      expect(
        plan.newDocument!.content(plan.answers.single.location.path),
        contains('> **Answer:** b\n'),
      );
    });

    test('IMP-1.2: form-preamble answers reach the form preamble', () {
      var edited = answerIn(rendition, 'BQ-902', ['rec']);
      edited = answerIn(edited, 'BQ-903', ['b']);
      final plan = importer.plan(edited);

      expect(plan.isRefused, isFalse, reason: plan.refusals.join('\n'));
      expect(plan.answers.map((a) => a.questionId), ['BQ-902', 'BQ-903']);
      expect(
        plan.answers.first.location.idPath,
        'SBP > INSC > SYDSC > SYPUP > SCBND > SIE-INSC-LST > '
        'SIE-INSC-TEST-CLIENT > content > content',
      );
      final preamble = plan.newDocument!.content(
        plan.answers.first.location.path,
      )!;
      expect(preamble, contains('> **Answer:** rec\n>\n> **❓ BQ-903'));
      expect(
        preamble,
        endsWith('> **Answer:** b\n\n_Extrapolated — see the notes._'),
      );
    });

    test('IMP-1.3: a multi-line answer is kept as typed', () {
      final answer = [
        'b, with one change:',
        'the external user is a persona,',
        'not a role.',
      ];
      final plan = importer.plan(answerIn(rendition, 'BQ-901', answer));

      expect(plan.isRefused, isFalse, reason: plan.refusals.join('\n'));
      expect(plan.answers.single.reportLine, endsWith('"b, with one change:"'));
      expect(insertedRegion(fixtureYaml, plan.newYaml!), [
        '          > **Answer:** b, with one change:',
        '          > the external user is a persona,',
        '          > not a role.',
      ]);
    });

    test('IMP-1.4: the YAML changes only in the answered lines', () {
      var edited = answerIn(rendition, 'BQ-901', ['a']);
      edited = answerIn(edited, 'BQ-903', ['rec']);
      final newYaml = importer.plan(edited).newYaml!;

      final changed = changedLines(fixtureYaml, newYaml)!;
      final lines = newYaml.split('\n');
      expect(changed, hasLength(2));
      expect(changed.map((n) => lines[n - 1].trim()), [
        '> **Answer:** a',
        '> **Answer:** rec',
      ]);
    });

    test('IMP-1.5: importing twice imports nothing the second time', () {
      final edited = answerIn(rendition, 'BQ-902', ['a', 'and keep it small.']);
      final first = importer.plan(edited);
      final again = AnswerImporter.forYaml(_sbp, first.newYaml!);

      expect(again.rendition, edited);
      final second = again.plan(edited);
      expect(second.isRefused, isFalse);
      expect(second.hasChanges, isFalse);
      expect(second.answers, isEmpty);
    });

    test('IMP-1.6: an unchanged markdown imports nothing', () {
      final plan = importer.plan(rendition);

      expect(plan.isRefused, isFalse);
      expect(plan.hasChanges, isFalse);
    });

    test('IMP-1.7: a changed answer replaces the earlier one', () {
      final first = importer.plan(answerIn(rendition, 'BQ-901', ['a']));
      final next = AnswerImporter.forYaml(_sbp, first.newYaml!);
      final edited = next.rendition.replaceFirst(
        '> **Answer:** a',
        '> **Answer:** b',
      );
      final plan = next.plan(edited);

      expect(plan.answers.single.reportLine, endsWith('"b"'));
      expect(changedLines(first.newYaml!, plan.newYaml!), hasLength(1));
    });

    test('IMP-1.8: a proposal\'s answer reaches the YAML by its PR id', () {
      var edited = answerIn(rendition, 'PR-901', ['b']);
      edited = answerIn(edited, 'BQ-901', ['a']);
      final plan = importer.plan(edited);

      expect(plan.isRefused, isFalse, reason: plan.refusals.join('\n'));
      expect(plan.answers.map((a) => a.reportLine), [
        'PR-901  SBP > DOCTL > content  "b"',
        'BQ-901  SBP > INSC > SYDSC > content  "a"',
      ]);
      final lines = plan.newYaml!.split('\n');
      expect(
        changedLines(
          fixtureYaml,
          plan.newYaml!,
        )!.map((n) => lines[n - 1].trim()),
        ['> **Answer:** b', '> **Answer:** a'],
      );
    });
  });

  group('IMP-6: change times (SOM §11.9.10)', () {
    test('IMP-6.1: an untimed answer stays untimed, a timed one keeps its '
        'time', () {
      final untimed = importer.plan(answerIn(rendition, 'BQ-901', ['b']));
      expect(
        untimed.newDocument!.content(untimed.answers.single.location.path),
        isNot(contains('**Answer (')),
      );
      final timed = importer.plan(
        answerIn(rendition, 'BQ-901', ['b']).replaceFirst(
          '> **Answer:** b',
          '> **Answer (2026-11-09T10:00+01:00):** b',
        ),
      );
      expect(timed.isRefused, isFalse, reason: timed.refusals.join('\n'));
      expect(
        timed.newDocument!.content(timed.answers.single.location.path),
        contains('> **Answer (2026-11-09T10:00+01:00):** b\n'),
      );
    });
  });

  group('IMP-2: refusals', () {
    test('IMP-2.1: a non-answer edit is refused with its line', () {
      final edited = answerIn(rendition, 'BQ-901', [
        'b',
      ]).replaceFirst('identity layer of a tenant', 'identity layer');
      final plan = importer.plan(edited);

      expect(plan.isRefused, isTrue);
      expect(plan.hasChanges, isFalse);
      expect(plan.refusals.join('\n'), contains('identity layer'));
      expect(plan.refusals.join('\n'), matches(RegExp(r'markdown  line \d+:')));
    });

    test('IMP-2.2: an answer continuation line without `>` is refused', () {
      final edited = answerIn(rendition, 'BQ-901', [
        'b',
      ]).replaceFirst('> **Answer:** b\n', '> **Answer:** b\nand more\n');

      expect(importer.plan(edited).isRefused, isTrue);
    });

    test('IMP-2.3: an edited question text is refused', () {
      final edited = answerIn(rendition, 'BQ-901', [
        'b',
      ]).replaceFirst('only the human roles', 'only human roles');

      expect(importer.plan(edited).isRefused, isTrue);
    });

    test('IMP-2.4: a value the rendition cannot hold is reported, not '
        'thrown as an error', () {
      final broken = fixtureYaml.replaceFirst(
        '          Tom UAM is the identity layer of a tenant.\n',
        '          ```text\n          Tom UAM is the identity layer of a tenant.\n',
      );

      expect(
        () => AnswerImporter.forYaml(_sbp, broken),
        throwsA(
          isA<SbpRenderException>().having(
            (e) => e.message,
            'message',
            contains('unterminated fenced code block'),
          ),
        ),
      );
    });
  });

  group('IMP-3: --allow-other-edits', () {
    setUp(() {
      importer = AnswerImporter.forYaml(
        _sbp,
        fixtureYaml,
        allowOtherEdits: true,
      );
    });

    test('IMP-3.1: a narrative edit is imported as a whole value', () {
      final edited = answerIn(rendition, 'BQ-902', [
        'a',
      ]).replaceFirst('identity layer of a tenant', 'identity layer');
      final plan = importer.plan(edited);

      expect(plan.isRefused, isFalse, reason: plan.refusals.join('\n'));
      expect(plan.values.map((v) => v.reportLine), [
        'VALUE  SBP > INSC > SYDSC > content',
      ]);
      expect(plan.answers.map((a) => a.questionId), ['BQ-902']);
      expect(changedLines(fixtureYaml, plan.newYaml!), hasLength(2));
    });

    test('IMP-3.2: a form-field edit is still refused', () {
      final edited = rendition.replaceFirst(
        'Category: Functional',
        'Category: Non-functional',
      );
      final plan = importer.plan(edited);

      expect(plan.isRefused, isTrue);
      expect(plan.refusals.single, startsWith('form field changed'));
    });
  });

  group('IMP-4: the real Blueprint (copy)', () {
    final blueprint = Directory(
      '../../../tom_uam/tom_specs/phase2_solution_blueprint',
    );
    final yamlFile = File('${blueprint.path}/tom_uam.sbp.docspecs.yaml');
    final scratch = Directory(
      '../../../ztmp/tom_specs_clitool_spec_checks_imp4',
    );

    test(
      'IMP-4.1: a narrative and a form-preamble answer change only their lines',
      () {
        scratch.createSync(recursive: true);
        final yaml = withTestQuestions(yamlFile.readAsStringSync(), {
          'SBP > INSC > SYDSC > SYPUP > content': 'BQ-125',
          'SBP > INSC > SYBO > EXIN > EIE-INTE-LST > EIE-INTE-OIDC-PROVIDER '
                  '> IS > content > content':
              'BQ-78',
        });
        File(
          '${scratch.path}/tom_uam.sbp.docspecs.yaml',
        ).writeAsStringSync(yaml);
        final real = AnswerImporter.forYaml(_sbp, yaml);
        var edited = answerIn(real.rendition, 'BQ-125', ['b']);
        edited = answerIn(edited, 'BQ-78', [
          'rec',
          'and publish it as the sample.',
        ]);
        File('${scratch.path}/tom_uam.sbp.md').writeAsStringSync(edited);

        final plan = real.plan(edited);
        expect(plan.isRefused, isFalse, reason: plan.refusals.join('\n'));
        expect(plan.answers.map((a) => a.questionId), ['BQ-125', 'BQ-78']);
        // Take the one added continuation line out again; then both texts
        // have the same line count and differ in the two answer lines only.
        final continuation = RegExp(r'\n *> and publish it as the sample\.');
        expect(continuation.allMatches(plan.newYaml!), hasLength(1));
        final withoutContinuation = plan.newYaml!.replaceFirst(
          continuation,
          '',
        );
        final changed = changedLines(yaml, withoutContinuation)!;
        final lines = withoutContinuation.split('\n');
        expect(changed.map((n) => lines[n - 1].trim()), [
          '> **Answer:** b',
          '> **Answer:** rec',
        ]);
        expect(
          plan.newYaml!,
          contains(
            '> **Answer:** rec\n${' ' * 20}> and publish it as the sample.\n',
          ),
        );
        File(
          '${scratch.path}/tom_uam.sbp.docspecs.yaml.imported',
        ).writeAsStringSync(plan.newYaml!);
        expect(_sbp.render(plan.newDocument!), edited);
        expect(_sbp.validate(plan.newDocument!).isClean, isTrue);
      },
      skip: yamlFile.existsSync() ? false : 'Blueprint not found',
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test(
      'IMP-4.2: answers in an id-less text section and in a class-level '
      'form\'s preamble change only their lines',
      () {
        final yaml = withTestQuestions(yamlFile.readAsStringSync(), {
          'SBP > INSC > SYBO > EXIN > governanceModel > content': 'BQ-146',
          'SBP > INSC > SYDSC > UIM > UIMS > content > content': 'BQ-283',
        });
        final real = AnswerImporter.forYaml(_sbp, yaml);
        var edited = answerIn(real.rendition, 'BQ-146', ['a']);
        edited = answerIn(edited, 'BQ-283', ['rec']);

        final plan = real.plan(edited);
        expect(plan.isRefused, isFalse, reason: plan.refusals.join('\n'));
        expect(plan.answers.map((a) => a.location.idPath), [
          'SBP > INSC > SYDSC > UIM > UIMS > content > content',
          'SBP > INSC > SYBO > EXIN > governanceModel > content',
        ]);
        final changed = changedLines(yaml, plan.newYaml!)!;
        final lines = plan.newYaml!.split('\n');
        expect(changed.map((n) => lines[n - 1].trim()), [
          '> **Answer:** rec',
          '> **Answer:** a',
        ]);
        expect(_sbp.render(plan.newDocument!), edited);
      },
      skip: yamlFile.existsSync() ? false : 'Blueprint not found',
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });

  group('IMP-5: answers in the shapes of the current model', () {
    test('IMP-5.1: an answer in an id-less text section reaches its value', () {
      final plan = importer.plan(answerIn(rendition, 'BQ-904', ['a']));

      expect(plan.isRefused, isFalse, reason: plan.refusals.join('\n'));
      expect(plan.answers.map((a) => a.reportLine), [
        'BQ-904  SBP > STKG > PRPO > TOENV > TOOLI > strategyNarrative > '
            'content  "a"',
      ]);
      final lines = plan.newYaml!.split('\n');
      expect(
        changedLines(
          fixtureYaml,
          plan.newYaml!,
        )!.map((n) => lines[n - 1].trim()),
        ['> **Answer:** a'],
      );
    });

    test('IMP-5.2: an answer in a class-level form\'s preamble reaches the '
        'preamble', () {
      final plan = importer.plan(answerIn(rendition, 'BQ-905', ['rec']));

      expect(plan.isRefused, isFalse, reason: plan.refusals.join('\n'));
      expect(plan.answers.map((a) => a.reportLine), [
        'BQ-905  SBP > SAAM > ACCM > USAU > ROHI > ROHIPO > content > '
            'content  "rec"',
      ]);
      final lines = plan.newYaml!.split('\n');
      expect(
        changedLines(
          fixtureYaml,
          plan.newYaml!,
        )!.map((n) => lines[n - 1].trim()),
        ['> **Answer:** rec'],
      );
      expect(_sbp.render(plan.newDocument!), contains('> **Answer:** rec'));
    });

    test('IMP-5.3: an answer in an id-less text section after a form with '
        'fields reaches the section\'s own value', () {
      // The section's text renders without a heading, after the owner's form
      // fields. The codec reads it back into the section's own value (tom_specs
      // uamtc5), so the answer is imported there rather than refused as a
      // form-field change.
      final yaml = fixtureYaml.replaceFirst(
        '          TOOLI tooling:\n',
        '          TOOLI tooling:\n'
            '            content:\n'
            '              toolStrategyOverview: |2-\n'
            '                Framework tools first.\n',
      );
      final withForm = AnswerImporter.forYaml(_sbp, yaml);
      final edited = answerIn(withForm.rendition, 'BQ-904', ['a']);
      final plan = withForm.plan(edited);

      expect(plan.isRefused, isFalse, reason: plan.refusals.join('\n'));
      expect(plan.answers.map((a) => a.reportLine), [
        'BQ-904  SBP > STKG > PRPO > TOENV > TOOLI > strategyNarrative > '
            'content  "a"',
      ]);
      final lines = plan.newYaml!.split('\n');
      expect(
        changedLines(yaml, plan.newYaml!)!.map((n) => lines[n - 1].trim()),
        ['> **Answer:** a'],
      );
      expect(_sbp.render(plan.newDocument!), edited);
    });
  });
}

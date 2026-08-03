import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Covers the doc-folder gate over inline quest-todo citations
/// (`lib/src/todo_citations.dart`).
///
/// The three fixtures the gate was specified against are the three failure modes
/// a human sweep caught by hand: a citation of an **archived** id, a citation of
/// a **deleted** id, and a **provenance-marked** citation of an archived id that
/// must pass. They are built from purpose-written todo files rather than from
/// the live corpus, so the fixtures keep testing the same thing after the real
/// todos move on.
void main() {
  final clitoolRoot = Directory.current.path;
  final containerRoot = p.normalize(p.join(clitoolRoot, '..', '..', '..'));

  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('todo_citations'));
  tearDown(() => temp.deleteSync(recursive: true));

  /// Writes a quest folder with the three todo files and returns its corpus.
  TodoCorpus corpusWith({
    List<(String id, String status)> active = const [],
    List<(String id, String status)> archived = const [],
    List<(String id, String status)> deleted = const [],
  }) {
    final questDir = Directory(p.join(temp.path, 'demo'))..createSync();

    void write(String file, List<(String, String)> todos) {
      final buffer = StringBuffer('todos:\n');
      for (final (id, status) in todos) {
        buffer.writeln('  - id: $id');
        buffer.writeln('    title: "todo $id"');
        buffer.writeln('    status: $status');
      }
      File(p.join(questDir.path, file)).writeAsStringSync(buffer.toString());
    }

    write('todos.demo.todo.yaml', active);
    write('todos-archived.demo.todo.yaml', archived);
    write('todos-deleted.demo.todo.yaml', deleted);
    return TodoCorpus.load(TodoCorpus.questTodoFiles(questDir.path));
  }

  List<TodoCitation> classify(String markdown, TodoCorpus corpus) =>
      classifyMarkdown(markdown, path: 'doc.md', corpus: corpus);

  group('TCC1: the three failure modes the gate was specified against', () {
    test('a citation of an archived id is a violation', () {
      final corpus = corpusWith(
        active: [('abc2_x-open', 'not-started')],
        archived: [('abc1_x-done', 'completed')],
      );

      final citations = classify('The rule is stated in `abc1`.', corpus);

      expect(citations, hasLength(1));
      expect(citations.single.verdict, CitationVerdict.closed);
      expect(citations.single.isViolation, isTrue);
    });

    test('a citation of a deleted id is a violation', () {
      final corpus = corpusWith(
        active: [('abc2_x-open', 'not-started')],
        deleted: [('abc3_x-dropped', 'not-started')],
      );

      final citations = classify('Superseded by `abc3`.', corpus);

      expect(citations.single.verdict, CitationVerdict.closed);
      expect(citations.single.isViolation, isTrue,
          reason: 'a deleted todo is closed even though its status never '
              'reached completed');
    });

    test('a provenance-marked citation of an archived id passes', () {
      final corpus = corpusWith(
        active: [('abc2_x-open', 'not-started')],
        archived: [('abc1_x-done', 'completed')],
      );

      final citations = classify(
        '| `abc2` | Raised by `abc1`. | <!-- todo-cite: provenance -->',
        corpus,
      );

      final closed =
          citations.singleWhere((c) => c.verdict == CitationVerdict.closed);
      expect(closed.token, 'abc1');
      expect(closed.exemption, CitationExemption.provenance);
      expect(closed.isViolation, isFalse);
      expect(citations.where((c) => c.isViolation), isEmpty);
    });
  });

  group('TCC2: the provenance marker has to point somewhere live', () {
    TodoCorpus corpus() => corpusWith(
          active: [('abc2_x-open', 'not-started')],
          archived: [('abc1_x-done', 'completed')],
        );

    test('a marked line with no open citation is still a violation', () {
      final citations = classify(
        'Tracked at `abc1`. <!-- todo-cite: provenance -->',
        corpus(),
      );

      expect(citations.single.exemption, isNull,
          reason: 'without an open todo on the line the marker would be a '
              'blanket "ignore me"');
      expect(citations.single.isViolation, isTrue);
    });

    test('a document-level history marker exempts unconditionally', () {
      final citations = classify(
        '<!-- todo-cite: history -->\n\n2026-08-03 — closed `abc1`.',
        corpus(),
      );

      final closed =
          citations.singleWhere((c) => c.verdict == CitationVerdict.closed);
      expect(closed.exemption, CitationExemption.history);
      expect(closed.isViolation, isFalse);
    });

    test('an inline history marker does not exempt the document', () {
      final citations = classify(
        'A note about `abc1` <!-- todo-cite: history --> mid-sentence.',
        corpus(),
      );

      expect(citations.single.isViolation, isTrue,
          reason: 'the document-level marker must stand alone on its line, so '
              'a passing mention cannot silence a whole file');
    });
  });

  group('TCC3: recognising a citation', () {
    test('an id whose series exists but whose number does not is unresolved',
        () {
      final citations =
          classify('See `abc7`.', corpusWith(active: [('abc2_x', 'not-started')]));

      expect(citations.single.verdict, CitationVerdict.unresolved);
      expect(citations.single.isViolation, isTrue);
    });

    test('an id from a series no todo file uses is unresolved too', () {
      final citations = classify(
          'See `csex7`.', corpusWith(active: [('abc2_x', 'not-started')]));

      expect(citations.single.verdict, CitationVerdict.unknownSeries,
          reason: 'the eight citations that motivated the gate were of a series '
              'no enumeration contained — the shape has to be the trigger');
      expect(citations.single.isViolation, isTrue);
    });

    test('a full on-disk id resolves through its stem', () {
      final corpus = corpusWith(active: [('abc2_ahci-do-the-thing', 'blocked')]);

      final citations = classify('See `abc2_ahci-do-the-thing`.', corpus);

      expect(citations.single.stem, 'abc2');
      expect(citations.single.verdict, CitationVerdict.open);
    });

    test('a completed todo in the active file is closed', () {
      final corpus = corpusWith(active: [('abc2_x', 'completed')]);

      expect(classify('See `abc2`.', corpus).single.verdict,
          CitationVerdict.closed,
          reason: 'keying only on the file would let a document cite finished '
              'work until someone ran an archive pass');
    });

    test('one open todo among several records is enough', () {
      final corpus = corpusWith(
        active: [('abc2_reopened', 'in-progress')],
        archived: [('abc2_first-attempt', 'completed')],
      );

      expect(classify('See `abc2`.', corpus).single.verdict,
          CitationVerdict.open);
    });

    test('vocabulary tokens are not citations at all', () {
      final corpus = corpusWith(active: [('abc2_x', 'not-started')]);

      final citations = classifyMarkdown(
        'The `vec0` extension and `abc2`.',
        path: 'doc.md',
        corpus: corpus,
        vocabulary: const TodoCitationVocabulary({'vec0'}),
      );

      expect(citations.map((c) => c.token), ['abc2']);
    });

    test('prose, fenced code and non-id tokens are skipped', () {
      final corpus = corpusWith(active: [('abc2_x', 'not-started')]);

      final citations = classify(
        'Plain abc2 is not backticked.\n'
        '`TomFormField`, `D13`, `v0` and `tom_som_dart_v0` are not ids.\n'
        '```\n`abc9`\n```\n'
        'But `abc2` is.',
        corpus,
      );

      expect(citations.map((c) => c.token), ['abc2']);
    });
  });

  group('TCC4: the live doc folder', () {
    test('every todo id cited in tom_specs_model/doc resolves to open work', () {
      final docDir = p.join(
          containerRoot, 'tom_ai', 'ai_build', 'tom_specs_model', 'doc');
      if (!Directory(docDir).existsSync()) {
        markTestSkipped('tom_specs_model is not checked out beside the clitool');
        return;
      }
      final questDirs = [
        for (final quest in defaultCitedQuests)
          p.join(containerRoot, '_ai', 'quests', quest),
      ];
      if (questDirs.any((d) => !Directory(d).existsSync())) {
        markTestSkipped('the _ai quest state is not mounted');
        return;
      }

      final report = checkDocFolder(
        docDir: docDir,
        corpus: TodoCorpus.load([
          for (final dir in questDirs) ...TodoCorpus.questTodoFiles(dir),
        ]),
        vocabulary: TodoCitationVocabulary.load(
            p.join(clitoolRoot, 'tool', 'todo_citation_vocabulary.txt')),
      );

      expect(
        report.violations.map((v) => v.describe(relativeTo: containerRoot)),
        isEmpty,
      );

      // The anti-vacuity guard is on the *scan*, not on the citations. A doc
      // folder that cites no todo at all is the intended steady state — every
      // document states the current design, and a citation only appears while
      // work is open against it. What must never pass silently is a gate that
      // scanned nothing: a moved doc folder or an unmounted quest tree. That
      // the scanner recognises and classifies a citation is TCC1–TCC3's job,
      // against fixtures that do not move when the live todos do.
      expect(report.documentCount, greaterThan(0),
          reason: 'a gate that scanned no document would pass vacuously');
      expect(report.corpus.stemCount, greaterThan(0),
          reason: 'a gate with an empty corpus would resolve nothing to check '
              'against');
    });
  });
}

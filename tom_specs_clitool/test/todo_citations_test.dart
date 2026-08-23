import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Covers the documentation gate over inline quest-todo citations
/// (`lib/src/todo_citations.dart`).
///
/// The three fixtures the gate was specified against are the three failure modes
/// a human sweep caught by hand: a citation of an **archived** id, a citation of
/// a **deleted** id, and a **provenance-marked** citation of an archived id that
/// must pass. They are built from purpose-written todo files rather than from
/// the live corpus, so the fixtures keep testing the same thing after the real
/// todos move on.
///
/// TCC5's fourth mode — a bare stem naming **several** todos — carries more
/// weight than the others, because the live corpus currently cites no todo at
/// all. Nothing on disk exercises the `ambiguous` verdict, so these fixtures are
/// the whole of its assurance.
///
/// The fixture groups run first and TCC4 — the live gate — stays last, so the
/// group numbers follow when each mode was specified rather than file order.
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

    test('a resolved citation names the id it resolved to', () {
      final corpus = corpusWith(active: [('abc2_ahci-do-the-thing', 'blocked')]);

      expect(classify('See `abc2`.', corpus).single.matchedIds,
          ['abc2_ahci-do-the-thing'],
          reason: 'the ids are carried for every verdict, not only the '
              'ambiguous one, so a report can always show what was hit');
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

  group('TCC5: a stem does not always name one todo', () {
    /// Two todos under one stem, the shape a per-prompt renumbering produces:
    /// an older attempt that finished and a newer one that has not.
    TodoCorpus corpus() => corpusWith(
          active: [('abc2_ahpu-second-attempt', 'not-started')],
          archived: [('abc2_ahjt-first-attempt', 'completed')],
        );

    test('a bare stem naming two todos is ambiguous, not open', () {
      final citation = classify('Tracked at `abc2`.', corpus()).single;

      expect(citation.verdict, CitationVerdict.ambiguous,
          reason: 'answering with the open record would let the citation read '
              'as healthy while pointing at two different things — and the '
              'closed one is the older, so a reader following it lands on '
              'finished work');
      expect(citation.isViolation, isTrue);
      expect(
          citation.matchedIds,
          unorderedEquals(
              ['abc2_ahpu-second-attempt', 'abc2_ahjt-first-attempt']));
    });

    test('the report names every id the stem matched', () {
      final citation = classify('Tracked at `abc2`.', corpus()).single;

      final described = citation.describe(relativeTo: '.');
      expect(described, contains('AMBIGUOUS'));
      expect(described, contains('abc2_ahpu-second-attempt'));
      expect(described, contains('abc2_ahjt-first-attempt'),
          reason: 'the fix is to write whichever id was meant, so the message '
              'has to hand the reader the candidates');
    });

    test('the date code disambiguates and resolves exactly', () {
      final open = classify('Tracked at `abc2_ahpu`.', corpus()).single;
      expect(open.verdict, CitationVerdict.open);
      expect(open.matchedIds, ['abc2_ahpu-second-attempt']);

      final closed = classify('Raised by `abc2_ahjt`.', corpus()).single;
      expect(closed.verdict, CitationVerdict.closed,
          reason: 'qualifying a citation narrows it; it does not excuse it');
      expect(closed.isViolation, isTrue);
    });

    test('a citation qualified past the date code resolves too', () {
      final citation =
          classify('Tracked at `abc2_ahpu-second-attempt`.', corpus()).single;

      expect(citation.verdict, CitationVerdict.open);
    });

    test('a slug appended with an underscore is matched at that boundary', () {
      final corpus = corpusWith(active: [
        ('abc2_ahpu_second_attempt', 'not-started'),
        ('abc2_ahjt-first-attempt', 'completed'),
      ]);

      expect(classify('Tracked at `abc2_ahpu`.', corpus).single.verdict,
          CitationVerdict.open,
          reason: 'ids append the slug with either separator, so anchoring on '
              'only one of them would leave half the corpus uncitable');
    });

    test('a truncated date code is unresolved, not a prefix match', () {
      final citation = classify('Tracked at `abc2_ahp`.', corpus()).single;

      expect(citation.verdict, CitationVerdict.unresolved,
          reason: 'a half-written date code is a typo and has to read as one — '
              'matching it to abc2_ahpu would resurrect the guessing the '
              'ambiguous verdict exists to stop');
      expect(citation.matchedIds, isEmpty);
    });

    test('neither marker exempts an ambiguous citation', () {
      final provenance = classify(
        '| `abc3` | Raised by `abc2`. | <!-- todo-cite: provenance -->',
        corpusWith(
          active: [
            ('abc3_ahpu-live', 'not-started'),
            ('abc2_ahpu-second-attempt', 'not-started'),
          ],
          archived: [('abc2_ahjt-first-attempt', 'completed')],
        ),
      ).singleWhere((c) => c.token == 'abc2');

      expect(provenance.exemption, isNull);
      expect(provenance.isViolation, isTrue);

      final history = classify(
        '<!-- todo-cite: history -->\n\n2026-08-03 — closed `abc2`.',
        corpus(),
      ).single;

      expect(history.isViolation, isTrue,
          reason: 'both markers excuse a citation of finished work; ambiguity '
              'is a different question, and a changelog entry naming two todos '
              'strands its reader just as badly');
    });
  });

  group('TCC4: the live documentation', () {
    test('every todo id cited in the doc set resolves to one open todo', () {
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
        // The same closed set the section gate holds: a README that points at
        // finished work strands its reader exactly as a doc-folder page does,
        // and the command scans these by default, so the gate and the test have
        // to see the same files.
        extraFiles: [
          for (final readme in defaultCitedReadmes)
            p.normalize(p.join(containerRoot, readme)),
        ],
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

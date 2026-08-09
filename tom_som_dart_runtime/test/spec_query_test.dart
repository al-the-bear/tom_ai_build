import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:test/test.dart';

/// `llm_and_d4rt_tools.md` §6 — the
/// lexical/structural query + lazy cursor facility. Embedding-free —
/// exact substring/regex + structural filters over a live [SpecDocument],
/// returning a cursor the caller iterates.
///
/// A self-contained model exercises every query dimension (text/regex/case,
/// kind, class, id/path, `@MapsTo`/`@DetailedIn`, state), AND-composition, and
/// cursor laziness/stability — independent of the shared `fixture.dart` so the
/// `@MapsTo`/`@DetailedIn`/glob cases can be controlled here.
SpecModel _model() => SpecModel.fromJson({
      'modelVersion': 1,
      'roots': [
        {'type': 'ProjectDefinition', 'title': 'Project Definition', 'sectionId': 'PD00'},
      ],
      'classes': {
        'ProjectDefinition': {
          'name': 'ProjectDefinition',
          'sectionId': 'PD00',
          'doc': 'Root of a project definition document.',
          'fields': [
            {
              'name': 'vision',
              'kind': 'content',
              'sectionId': 'PD00-VIS',
              'contentType': 'text',
              'doc': 'Why the system exists.',
            },
            {
              'name': 'owner',
              'kind': 'form',
              'sectionId': 'PD00-OWN',
              'formFields': [
                {'name': 'name', 'label': 'Name', 'type': 'String'},
                {'name': 'role', 'label': 'Role', 'type': 'String'},
              ],
            },
            {
              'name': 'risks',
              'kind': 'list',
              'sectionId': 'PD00-RSK',
              'elementType': 'Risk',
              'elementIsComplex': true,
            },
            {
              'name': 'tags',
              'kind': 'list',
              'sectionId': 'PD00-TAG',
              'elementType': 'String',
              'elementIsComplex': false,
            },
            {
              'name': 'situation',
              'kind': 'complex',
              'sectionId': 'PD00-SIT',
              'type': 'CurrentSituation',
            },
          ],
        },
        'Risk': {
          'name': 'Risk',
          'sectionId': 'RISK',
          // Risk details are mapped from a CS section and detailed in BP.
          'mapsTo': 'CS00-RSK',
          'detailedIn': 'BP00',
          'fields': [
            {
              'name': 'title',
              'kind': 'content',
              'sectionId': 'title',
              'contentType': 'text',
            },
            {
              'name': 'probability',
              'kind': 'enum',
              'sectionId': 'prob',
              'enumType': 'Probability',
              'enumValues': ['low', 'medium', 'high'],
            },
          ],
        },
        'CurrentSituation': {
          'name': 'CurrentSituation',
          'sectionId': 'CS00',
          'fields': [
            {
              'name': 'summary',
              'kind': 'content',
              'sectionId': 'summary',
              'contentType': 'text',
            },
          ],
        },
      },
    });

/// A document with two risks, a vision, a form, and tags populated.
SpecDocument _document() {
  final doc = SpecDocument();
  doc.setContent('PD00/PD00-VIS', 'Deliver a resilient rollout platform.');
  doc.setFormField('PD00/PD00-OWN', 'name', 'Ada Lovelace');
  doc.setFormField('PD00/PD00-OWN', 'role', 'Product Owner');

  final r1 = doc.addListItem('PD00/PD00-RSK'); // PD00/PD00-RSK-1
  doc.setContent('$r1/title', 'Vendor lock-in risk');
  doc.setContent('$r1/prob', 'high');

  final r2 = doc.addListItem('PD00/PD00-RSK'); // PD00/PD00-RSK-2
  doc.setContent('$r2/title', 'Schedule slippage');
  doc.setContent('$r2/prob', 'medium');

  final t1 = doc.addListItem('PD00/PD00-TAG');
  doc.setContent(t1, 'rollout');
  // situation (PD00/PD00-SIT) left empty.
  return doc;
}

void main() {
  late SpecModel model;
  late SpecDocument doc;
  late SpecQueryEngine engine;

  setUp(() {
    model = _model();
    doc = _document();
    engine = SpecQueryEngine(model: model, document: doc);
  });

  List<String> paths(SpecQueryCursor c) => c.toList().map((m) => m.path).toList();

  group('text dimension', () {
    test('substring over content matches the vision leaf', () {
      final hits = paths(engine.query(const SpecQuery(text: 'resilient')));
      expect(hits, contains('PD00/PD00-VIS'));
      expect(hits, isNot(contains('PD00/PD00-RSK-1/title')));
    });

    test('regex over content', () {
      final hits = paths(
          engine.query(const SpecQuery(text: 'slip[a-z]+', regex: true)));
      expect(hits, contains('PD00/PD00-RSK-2/title'));
    });

    test('a pattern outside the portable subset is refused, not guessed', () {
      // `regex: true` compiles with [SomTextPattern], which has no `\w`; the
      // caller hears about it instead of silently matching nothing.
      expect(
          () => engine.query(const SpecQuery(text: r'slip\w+', regex: true)),
          throwsA(isA<SomPatternError>()));
    });

    test('case-insensitive substring', () {
      final sensitive =
          paths(engine.query(const SpecQuery(text: 'ADA')));
      expect(sensitive, isEmpty);
      final insensitive = paths(
          engine.query(const SpecQuery(text: 'ADA', caseInsensitive: true)));
      expect(insensitive, contains('PD00/PD00-OWN'));
    });

    test('matches form-field values', () {
      final hits = paths(engine.query(const SpecQuery(text: 'Lovelace')));
      expect(hits, contains('PD00/PD00-OWN'));
    });

    test('matches doc-comment headlines', () {
      final hits =
          paths(engine.query(const SpecQuery(text: 'Why the system exists')));
      expect(hits, contains('PD00/PD00-VIS'));
    });

    test('a match carries a snippet and non-empty spans', () {
      final m = engine.query(const SpecQuery(text: 'resilient')).next()!;
      expect(m.snippet, isNotNull);
      expect(m.matchSpans, isNotEmpty);
      final span = m.matchSpans.first;
      expect(m.snippet!.substring(span.start, span.end).toLowerCase(),
          'resilient');
    });
  });

  group('kind / class dimension', () {
    test('kind filter selects only content leaves', () {
      final hits = engine
          .query(const SpecQuery(kinds: {SpecNodeKind.content}))
          .toList();
      expect(hits, isNotEmpty);
      expect(hits.every((m) => m.kind == SpecNodeKind.content), isTrue);
      expect(hits.map((m) => m.path), contains('PD00/PD00-VIS'));
    });

    test('class-name filter selects nodes that are Risk items', () {
      final hits =
          paths(engine.query(const SpecQuery(className: 'Risk')));
      expect(hits, containsAll(['PD00/PD00-RSK-1', 'PD00/PD00-RSK-2']));
      expect(hits, isNot(contains('PD00/PD00-VIS')));
    });
  });

  group('id / path dimension', () {
    test('exact section id', () {
      final hits =
          paths(engine.query(const SpecQuery(sectionIdExact: 'PD00-VIS')));
      expect(hits, ['PD00/PD00-VIS']);
    });

    test('section-id prefix', () {
      final hits =
          paths(engine.query(const SpecQuery(sectionIdPrefix: 'PD00-')));
      expect(hits, containsAll(['PD00/PD00-VIS', 'PD00/PD00-OWN', 'PD00/PD00-RSK', 'PD00/PD00-TAG']));
    });

    test('path glob', () {
      final hits = paths(
          engine.query(const SpecQuery(pathGlob: 'PD00/PD00-RSK-*/title')));
      expect(hits,
          containsAll(['PD00/PD00-RSK-1/title', 'PD00/PD00-RSK-2/title']));
      expect(hits, isNot(contains('PD00/PD00-RSK-1/prob')));
    });

    test('@MapsTo target', () {
      final hits =
          paths(engine.query(const SpecQuery(mapsTo: 'CS00-RSK')));
      expect(hits, containsAll(['PD00/PD00-RSK-1', 'PD00/PD00-RSK-2']));
    });

    test('@DetailedIn target', () {
      final hits =
          paths(engine.query(const SpecQuery(detailedIn: 'BP00')));
      expect(hits, containsAll(['PD00/PD00-RSK-1', 'PD00/PD00-RSK-2']));
    });
  });

  group('state dimension', () {
    test('empty selects the untouched situation section', () {
      final hits =
          paths(engine.query(const SpecQuery(state: SpecStateFilter.empty)));
      expect(hits, contains('PD00/PD00-SIT'));
      expect(hits, isNot(contains('PD00/PD00-VIS')));
    });

    test('non-empty excludes the untouched situation section', () {
      final hits = paths(
          engine.query(const SpecQuery(state: SpecStateFilter.nonEmpty)));
      expect(hits, contains('PD00/PD00-VIS'));
      expect(hits, isNot(contains('PD00/PD00-SIT')));
    });
  });

  group('AND-composition', () {
    test('text AND kind narrows the result', () {
      final hits = paths(engine.query(const SpecQuery(
        text: 'risk',
        caseInsensitive: true,
        kinds: {SpecNodeKind.content},
      )));
      expect(hits, contains('PD00/PD00-RSK-1/title'));
      // The form owner also contains no 'risk'; the list container is not a content leaf.
      expect(hits, isNot(contains('PD00/PD00-OWN')));
    });

    test('class AND state', () {
      final hits = paths(engine.query(const SpecQuery(
        className: 'Risk',
        state: SpecStateFilter.nonEmpty,
      )));
      expect(hits, containsAll(['PD00/PD00-RSK-1', 'PD00/PD00-RSK-2']));
    });
  });

  group('cursor laziness & iteration', () {
    test('count reports remaining matches and next/take advance it', () {
      final cursor = engine.query(const SpecQuery(kinds: {SpecNodeKind.content}));
      final total = cursor.count;
      expect(total, greaterThanOrEqualTo(4));

      final first = cursor.next();
      expect(first, isNotNull);
      expect(cursor.count, total - 1);

      final batch = cursor.take(2);
      expect(batch, hasLength(2));
      expect(cursor.count, total - 3);
    });

    test('take(n) never exceeds the available matches', () {
      final cursor = engine.query(const SpecQuery(sectionIdExact: 'PD00-VIS'));
      final batch = cursor.take(10);
      expect(batch, hasLength(1));
      expect(cursor.next(), isNull);
    });

    test('cursor is stable against concurrent edits (path re-validation)', () {
      final cursor =
          engine.query(const SpecQuery(kinds: {SpecNodeKind.content}));
      // Remove a value that an as-yet-unread candidate points at.
      doc.removeListItem('PD00/PD00-RSK-2');
      final remaining = cursor.toList().map((m) => m.path).toList();
      // The deleted item's leaves must not surface.
      expect(remaining, isNot(contains('PD00/PD00-RSK-2/title')));
      // Surviving content is still found.
      expect(remaining, contains('PD00/PD00-VIS'));
    });
  });
}
